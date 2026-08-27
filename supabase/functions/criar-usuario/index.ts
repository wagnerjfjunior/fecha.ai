import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// FECH.AI — T3A-v5
// reset_password authority is derived server-side by public.t3_prepare_admin_password_reset().
// Before that caller-JWT RPC can mint a durable lease, the Edge must obtain an
// opaque, one-time proof from a service-role-only issuer. The proof establishes
// only that the trusted server-only handshake was traversed; it is not binary
// attestation or actor authority. auth.uid() and server-side database state
// remain the exclusive actor/tenant/role authority. The durable lease then
// fences the reviewed authority rows until the Auth mutation has
// completed and the service-role client releases that exact lease.
// The user-creation path below preserves the v17 authority semantics. Its audit
// insert shares the same live legacy/modern audit_logs compatibility contract.

// ─── CORS restrito ao domínio da app ─────────────────────────────────────────
const ALLOWED_ORIGINS = [
  'https://fecha-ai.vercel.app',
  'https://fech-ai.vercel.app',
  'http://localhost:5173',
  'http://localhost:3000',
]

function getCorsHeaders(req: Request) {
  const origin = req.headers.get('origin') ?? ''
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0]
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  }
}

// ─── Rate limiting simples por IP ────────────────────────────────────────────
const rateMap = new Map<string, { count: number; reset: number }>()

function checkRateLimit(ip: string, maxPerMinute = 5): boolean {
  const now = Date.now()
  const entry = rateMap.get(ip)
  if (!entry || now > entry.reset) {
    rateMap.set(ip, { count: 1, reset: now + 60_000 })
    return true
  }
  if (entry.count >= maxPerMinute) return false
  entry.count++
  return true
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function json(data: unknown, status = 200, cors: Record<string, string>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}

function normalizeUuid(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const normalized = value.toLowerCase()
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(normalized)
    ? normalized
    : null
}

function normalizeInet(value: string | null): string | null {
  const candidate = value?.trim() ?? ''
  if (!candidate) return null

  const ipv4Parts = candidate.split('.')
  if (
    ipv4Parts.length === 4 &&
    ipv4Parts.every((part) => /^\d{1,3}$/.test(part) && Number(part) <= 255)
  ) {
    return ipv4Parts.map((part) => String(Number(part))).join('.')
  }

  // URL parsing gives a conservative IPv6 syntax check without accepting a
  // hostname. Preserve the original address string for PostgreSQL inet.
  if (candidate.includes(':') && /^[0-9a-f:.]+$/i.test(candidate)) {
    try {
      new URL(`http://[${candidate}]`)
      return candidate
    } catch {
      return null
    }
  }

  return null
}

Deno.serve(async (req: Request) => {
  const cors = getCorsHeaders(req)

  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  // ─── Rate limiting ────────────────────────────────────────────────────────
  const forwardedFor = req.headers.get('x-forwarded-for')
  const rawClientIp = (
    forwardedFor?.split(',')[0] ?? req.headers.get('x-real-ip') ?? ''
  ).trim() || null
  const clientIp = normalizeInet(rawClientIp)
  if (!checkRateLimit(rawClientIp ?? 'unknown')) {
    return json({ error: 'Muitas requisições. Aguarde 1 minuto.' }, 429, cors)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

  // ─── Cliente admin (service_role) ────────────────────────────────────────
  const admin = createClient(
    supabaseUrl,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )

  try {
    // ─── Extrair e validar JWT do usuário logado ──────────────────────────
    const authHeader = req.headers.get('authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return json({ error: 'Token de autenticação obrigatório.' }, 401, cors)
    }

    const token = authHeader.slice(7)
    const { data: { user: caller }, error: callerErr } = await admin.auth.getUser(token)
    if (callerErr || !caller) {
      return json({ error: 'Token inválido ou expirado.' }, 401, cors)
    }

    const body = await req.json()

    // ─── Carregar perfil para auditoria e para o fluxo legado de criação ──
    // Estes valores NÃO são a authority boundary do reset_password T3A.
    const { data: callerProfile } = await admin
      .from('corretores')
      .select('id, empresa_id, role, ativo, is_admin_local, is_gestor, nome, email')
      .eq('user_id', caller.id)
      .single()

    const { data: adminData } = await admin
      .from('admins')
      .select('id, nome, email, ativo, role')
      .eq('user_id', caller.id)
      .single()

    // ═══════════════════════════════════════════════════════════════════════
    // AÇÃO: RESET DE SENHA — T3A-v5 / MULTI-TENANT AUTHORITY BOUNDARY
    // ═══════════════════════════════════════════════════════════════════════
    if (body.action === 'reset_password') {
      const logId = `audit-${Date.now()}-${Math.random().toString(36).slice(2)}`
      const { user_id: requestedUserId, password } = body
      const userId = normalizeUuid(requestedUserId)
      const auditAttempt = { status: 'attempt', action: 'reset_password' }
      const { error: auditInsertError } = await admin.from('audit_logs').insert({
        id: logId,
        empresa_id: callerProfile?.empresa_id ?? null,
        action: 'password_reset_attempt',
        actor_id: caller.id,
        actor_email: caller.email,
        target_user_id: userId,
        target_email: null,
        ip_address: clientIp,
        payload: auditAttempt,
        ator_user_id: caller.id,
        ator_corretor_id: callerProfile?.id ?? null,
        acao: 'password_reset_attempt',
        entidade: 'auth.users',
        entidade_id: userId,
        depois: auditAttempt,
        ip: rawClientIp,
      })

      // A reset without its server-authored audit anchor is not allowed to
      // reach proof issuance, caller preparation or the external Auth write.
      if (auditInsertError) {
        return json({ error: 'Não foi possível concluir a redefinição de senha.' }, 500, cors)
      }

      if (!userId || typeof password !== 'string' || password.length < 8) {
        return json({ error: 'user_id e senha temporária de no mínimo 8 caracteres são obrigatórios.' }, 400, cors)
      }

      // Mint an opaque one-time proof through the service-role-only issuer.
      // This proof is not actor authority and does not authorize the target.
      // The caller-JWT prepare RPC below consumes it and still derives the
      // actor exclusively from auth.uid() plus server-side database state.
      // A direct PostgREST caller cannot mint a durable lease without first
      // crossing the service-role-only server handshake used by this Edge.
      let edgeProofId: string | null = null
      let edgeProofError: unknown = null

      try {
        const result = await admin.rpc(
          't3_issue_admin_password_reset_edge_proof',
          {
            p_actor_user_id: caller.id,
            p_target_user_id: userId,
          }
        )
        edgeProofId = normalizeUuid(result.data)
        edgeProofError = result.error
      } catch (caught: unknown) {
        edgeProofError = caught
      }

      if (edgeProofError || !edgeProofId) {
        await admin.from('audit_logs')
          .update({
            payload: { status: 'edge_proof_unavailable', action: 'reset_password' },
            depois: { status: 'edge_proof_unavailable', action: 'reset_password' },
          })
          .eq('id', logId)

        // The rollout is Edge-first. While the proof issuer is absent, or if
        // proof issuance is ambiguous, fail before any caller preparation or
        // Auth mutation.
        return json({ error: 'Não foi possível concluir a redefinição de senha.' }, 500, cors)
      }

      // Use the caller JWT (not service_role) so auth.uid() inside the
      // SECURITY DEFINER RPC is the real authenticated actor. empresa/role/
      // flags/time/ownership from the request are ignored as authority inputs.
      const callerDb = createClient(
        supabaseUrl,
        anonKey,
        {
          global: { headers: { Authorization: authHeader } },
          auth: { autoRefreshToken: false, persistSession: false },
        }
      )

      let authorization: { ok?: boolean; user_id?: string; lease_id?: string } | null = null
      let authorizationError: unknown = null

      try {
        const result = await callerDb.rpc(
          't3_prepare_admin_password_reset',
          {
            p_target_user_id: userId,
            p_edge_proof_id: edgeProofId,
          }
        )
        authorization = result.data
        authorizationError = result.error
      } catch (caught: unknown) {
        authorizationError = caught
      }

      const leaseId = normalizeUuid(authorization?.lease_id)

      if (
        authorizationError ||
        authorization?.ok !== true ||
        authorization?.user_id !== userId ||
        !leaseId
      ) {
        await admin.from('audit_logs')
          .update({
            payload: { status: 'denied', action: 'reset_password' },
            depois: { status: 'denied', action: 'reset_password' },
          })
          .eq('id', logId)

        // Deliberately generic: do not reveal whether a target exists in
        // another tenant/company or merely falls outside the actor's scope.
        return json({ error: 'Usuário não encontrado ou não autorizado.' }, 403, cors)
      }

      // The RPC has already set must_change_password=true and committed a
      // durable lease. T3 fencing triggers now reject any relevant actor,
      // target, protected-admin or gestor-team authority mutation until this
      // exact lease is released after the external Auth call completes.
      let authData: { user: { id: string } } | null = null
      let authError: unknown = null

      try {
        const result = await admin.auth.admin.updateUserById(
          userId,
          { password }
        )
        authData = result.data
        authError = result.error
      } catch (caught: unknown) {
        authError = caught
      }

      if (
        authError ||
        !authData?.user?.id ||
        authData.user.id !== userId
      ) {
        await admin.from('audit_logs')
          .update({
            payload: { status: 'auth_result_unresolved', action: 'reset_password' },
            depois: { status: 'auth_result_unresolved', action: 'reset_password' },
          })
          .eq('id', logId)

        // A transport/runtime/Auth error can be ambiguous. Keep the durable
        // lease instead of guessing that no side effect occurred. Recovery is
        // a separate, explicitly authorized operation.
        return json({ error: 'Não foi possível concluir a redefinição de senha.' }, 500, cors)
      }

      // service_role is only the operational releaser of the exact lease after
      // a proven successful Auth mutation. It is not actor authority and cannot
      // create or authorize a reset lease.
      let released: unknown = null
      let releaseError: unknown = null

      try {
        const result = await admin.rpc(
          't3_release_admin_password_reset_lease',
          {
            p_lease_id: leaseId,
            p_actor_user_id: caller.id,
            p_target_user_id: userId,
          }
        )
        released = result.data
        releaseError = result.error
      } catch (caught: unknown) {
        releaseError = caught
      }

      if (releaseError || released !== true) {
        await admin.from('audit_logs')
          .update({
            payload: { status: 'lease_release_unresolved', action: 'reset_password' },
            depois: { status: 'lease_release_unresolved', action: 'reset_password' },
          })
          .eq('id', logId)

        // Auth success was proven before release was attempted. A lost release
        // response can mean either the exact safe release committed or the
        // lease remains. Do not claim success, retry or improvise cleanup.
        return json({ error: 'Não foi possível concluir a redefinição de senha.' }, 500, cors)
      }

      await admin.from('audit_logs')
        .update({
          payload: { status: 'success', user_id: authData.user.id },
          depois: { status: 'success', user_id: authData.user.id },
        })
        .eq('id', logId)

      return json({ ok: true, user_id: authData.user.id }, 200, cors)
    }

    // ═══════════════════════════════════════════════════════════════════════
    // AÇÃO: CRIAR NOVO USUÁRIO — G1E0-A2.1
    // Organizational authority is finalized by a caller-JWT RPC. service_role
    // remains operational only for Auth administration and server-authored audit.
    // ═══════════════════════════════════════════════════════════════════════
    const isRoot = !!adminData && adminData.ativo === true && adminData.role === 'admin_global'
    const isAdminLocal = callerProfile?.is_admin_local === true
    const isGestor = callerProfile?.is_gestor === true

    if (!isRoot && !isAdminLocal && !isGestor) {
      return json({ error: 'Sem permissão. Apenas admin ou gestor podem criar usuários.' }, 403, cors)
    }

    // Fail closed on caller state used by this creation path. Historical
    // admin_local rows may also carry is_gestor=true; role=admin_local plus the
    // explicit admin-local flag remains unambiguous and takes precedence.
    if (!isRoot) {
      if (!callerProfile?.id || !callerProfile?.empresa_id) {
        return json({ error: 'Não foi possível validar sua autorização.' }, 403, cors)
      }

      const callerRole = callerProfile.role
      if (callerProfile.ativo !== true) {
        return json({ error: 'Não foi possível validar sua autorização.' }, 403, cors)
      }
      if (
        (isAdminLocal && callerRole !== 'admin_local') ||
        (!isAdminLocal && isGestor && callerRole !== 'gestor')
      ) {
        return json({ error: 'Não foi possível validar sua autorização.' }, 403, cors)
      }
    }

    const logId = `audit-${Date.now()}-${Math.random().toString(36).slice(2)}`
    const userCreationAuditAttempt = {
      status: 'attempt',
      action: body.action ?? 'create',
    }
    const { error: auditInsertError } = await admin.from('audit_logs').insert({
      id: logId,
      empresa_id: callerProfile?.empresa_id ?? null,
      action: 'user_creation_attempt',
      actor_id: caller.id,
      actor_email: caller.email,
      target_email: body.email ?? null,
      ip_address: clientIp,
      payload: userCreationAuditAttempt,
      ator_user_id: caller.id,
      ator_corretor_id: callerProfile?.id ?? null,
      acao: 'user_creation_attempt',
      entidade: 'auth.users',
      depois: userCreationAuditAttempt,
      ip: rawClientIp,
    })

    if (auditInsertError) {
      return json({ error: 'Não foi possível iniciar a criação do usuário.' }, 500, cors)
    }

    const { nome, email, is_admin_local_novo, is_gestor_novo } = body
    const password = body.password ?? body.senha
    const empresaIdIntent = normalizeUuid(body.empresa_id)
    const timeId = body.time_id == null ? null : normalizeUuid(body.time_id)

    if (
      typeof email !== 'string' ||
      typeof password !== 'string' ||
      typeof nome !== 'string' ||
      !email.trim() ||
      !nome.trim() ||
      password.length < 8
    ) {
      return json({ error: 'email, senha e nome são obrigatórios; senha deve ter no mínimo 8 caracteres.' }, 400, cors)
    }

    if (
      (body.empresa_id != null && !empresaIdIntent) ||
      (body.time_id != null && !timeId) ||
      (is_admin_local_novo != null && typeof is_admin_local_novo !== 'boolean') ||
      (is_gestor_novo != null && typeof is_gestor_novo !== 'boolean')
    ) {
      return json({ error: 'Dados de criação inválidos.' }, 400, cors)
    }

    if (is_admin_local_novo === true && is_gestor_novo === true) {
      return json({ error: 'Dados de criação inválidos.' }, 400, cors)
    }

    const targetRole =
      is_admin_local_novo === true ? 'admin_local'
        : is_gestor_novo === true ? 'gestor'
          : 'corretor'

    // Non-ROOT tenant is server-owned. A supplied empresa_id is only an equality
    // assertion and can never override the caller tenant.
    if (!isRoot && empresaIdIntent && empresaIdIntent !== callerProfile!.empresa_id) {
      return json({ error: 'Não foi possível concluir a criação do usuário.' }, 403, cors)
    }

    const empresaIdTarget = isRoot ? empresaIdIntent : callerProfile!.empresa_id
    if (!empresaIdTarget) {
      return json({ error: 'Não foi possível concluir a criação do usuário.' }, 403, cors)
    }

    // Canonical role/time shape is rejected before the external Auth mutation.
    if (targetRole === 'corretor' && !timeId) {
      return json({ error: 'Time obrigatório para corretor.' }, 400, cors)
    }
    if (targetRole !== 'corretor' && timeId) {
      return json({ error: 'Gestor e admin local não podem possuir time de membro na criação.' }, 400, cors)
    }

    // Pure Gestor may create only an ordinary Corretor.
    if (!isRoot && !isAdminLocal && isGestor && targetRole !== 'corretor') {
      return json({ error: 'Não foi possível concluir a criação do usuário.' }, 403, cors)
    }

    // Preliminary Time authorization reduces avoidable Auth writes. This is not
    // final authority; the caller-JWT RPC revalidates and locks the same state.
    if (targetRole === 'corretor') {
      let timeQuery = admin
        .from('times')
        .select('id')
        .eq('id', timeId!)
        .eq('empresa_id', empresaIdTarget)
        .eq('ativo', true)

      if (!isRoot && !isAdminLocal && isGestor) {
        timeQuery = timeQuery.eq('gestor_id', callerProfile!.id)
      }

      const { data: eligibleTime, error: eligibleTimeError } = await timeQuery.maybeSingle()
      if (eligibleTimeError || !eligibleTime) {
        return json({ error: 'Destino não disponível.' }, 403, cors)
      }
    }

    // ─── Verificar limites do plano ────────────────────────────────────────
    if (!isRoot) {
      const { data: empresa } = await admin
        .from('empresas')
        .select('plano_id, planos(max_corretores)')
        .eq('id', empresaIdTarget)
        .single() as { data: { plano_id: string; planos: { max_corretores: number } } | null }

      if (empresa) {
        const { count } = await admin
          .from('corretores')
          .select('*', { count: 'exact', head: true })
          .eq('empresa_id', empresaIdTarget)

        const maxCorretores = empresa.planos?.max_corretores ?? 999
        if ((count ?? 0) >= maxCorretores) {
          return json({ error: `Limite de ${maxCorretores} usuários atingido para o plano atual.` }, 403, cors)
        }
      }
    }

    // ─── Criar usuário no Supabase Auth ───────────────────────────────────
    const { data: authData, error: authError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })
    if (authError || !authData.user?.id) {
      await admin.from('audit_logs')
        .update({
          payload: { status: 'failed', stage: 'auth_create' },
          depois: { status: 'failed', stage: 'auth_create' },
        })
        .eq('id', logId)
      return json({ error: 'Não foi possível concluir a criação do usuário.' }, 400, cors)
    }

    // Final organizational authority is caller-bound. This client carries the
    // real caller JWT so auth.uid() inside the SECURITY DEFINER RPC is decisive.
    const callerDb = createClient(
      supabaseUrl,
      anonKey,
      {
        global: { headers: { Authorization: authHeader } },
        auth: { autoRefreshToken: false, persistSession: false },
      }
    )

    let profileResult: { ok?: boolean; corretor_id?: string } | null = null
    let profileError: unknown = null

    try {
      const result = await callerDb.rpc(
        'a2_1_create_corretor_profile',
        {
          p_new_user_id: authData.user.id,
          p_nome: nome.trim(),
          p_email: email.trim(),
          p_target_role: targetRole,
          p_time_id: timeId,
          p_empresa_id_intent: empresaIdTarget,
        }
      )
      profileResult = result.data
      profileError = result.error
    } catch (caught: unknown) {
      profileError = caught
    }

    if (profileError || profileResult?.ok !== true) {
      let compensationConfirmed = false
      let compensationError: unknown = null

      try {
        const deletion = await admin.auth.admin.deleteUser(authData.user.id)
        compensationConfirmed = !deletion.error
        compensationError = deletion.error
      } catch (caught: unknown) {
        compensationError = caught
      }

      const compensationStatus = compensationConfirmed
        ? 'compensation_confirmed'
        : 'auth_compensation_unresolved'

      const compensationAuditPayload = {
        status: compensationStatus,
        stage: 'profile_create',
        recovery_user_id: compensationConfirmed ? null : authData.user.id,
      }

      const { error: compensationAuditError } = await admin.from('audit_logs')
        .update({
          target_user_id: authData.user.id,
          payload: compensationAuditPayload,
          depois: compensationAuditPayload,
        })
        .eq('id', logId)

      if (compensationAuditError) {
        const fallbackAuditId = `audit-${Date.now()}-${Math.random().toString(36).slice(2)}`
        const { error: fallbackAuditError } = await admin.from('audit_logs').insert({
          id: fallbackAuditId,
          empresa_id: callerProfile?.empresa_id ?? null,
          action: 'user_creation_compensation_unresolved',
          actor_id: caller.id,
          actor_email: caller.email,
          target_user_id: authData.user.id,
          target_email: email.trim(),
          ip_address: clientIp,
          payload: {
            ...compensationAuditPayload,
            audit_anchor_recovery: true,
          },
          ator_user_id: caller.id,
          ator_corretor_id: callerProfile?.id ?? null,
          acao: 'user_creation_compensation_unresolved',
          entidade: 'auth.users',
          entidade_id: authData.user.id,
          depois: {
            ...compensationAuditPayload,
            audit_anchor_recovery: true,
          },
          ip: rawClientIp,
        })

        if (fallbackAuditError) {
          console.error('AUTH_COMPENSATION_AUDIT_UNRESOLVED', {
            audit_id: logId,
            user_id: authData.user.id,
          })
        }
      }

      if (!compensationConfirmed) {
        console.error('AUTH_COMPENSATION_UNRESOLVED', {
          audit_id: logId,
          user_id: authData.user.id,
          compensation_error: compensationError ? 'present' : 'ambiguous',
        })
      }

      return json({ error: 'Não foi possível concluir a criação do usuário.' }, 500, cors)
    }

    await admin.from('audit_logs')
      .update({
        target_user_id: authData.user.id,
        payload: { status: 'success', user_id: authData.user.id },
        depois: { status: 'success', user_id: authData.user.id },
      })
      .eq('id', logId)

    return json({ ok: true, user_id: authData.user.id }, 200, cors)

  } catch (err: unknown) {
    console.error('criar-usuario error', err instanceof Error ? err.name : 'unknown')
    return json({ error: 'Não foi possível concluir a solicitação.' }, 400, cors)
  }
})
