import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// FECH.AI — T3A-v4
// reset_password authority is derived server-side by public.t3_prepare_admin_password_reset().
// Before that caller-JWT RPC can mint a durable lease, the Edge must obtain an
// opaque, one-time proof from a service-role-only issuer. The proof establishes
// only that the trusted server-only handshake was traversed; it is not binary
// attestation or actor authority. auth.uid() and server-side database state
// remain the exclusive actor/tenant/role authority. The durable lease then
// fences the reviewed authority rows until the Auth mutation has
// completed and the service-role client releases that exact lease.
// The user-creation path below intentionally preserves the v17 behavior in this change.

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

Deno.serve(async (req: Request) => {
  const cors = getCorsHeaders(req)

  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  // ─── Rate limiting ────────────────────────────────────────────────────────
  const clientIp = req.headers.get('x-forwarded-for') ?? req.headers.get('x-real-ip') ?? 'unknown'
  if (!checkRateLimit(clientIp)) {
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
      .select('id, empresa_id, is_admin_local, is_gestor, nome, email')
      .eq('user_id', caller.id)
      .single()

    const { data: adminData } = await admin
      .from('admins')
      .select('id, nome, email')
      .eq('user_id', caller.id)
      .single()

    // ═══════════════════════════════════════════════════════════════════════
    // AÇÃO: RESET DE SENHA — T3A-v4 / MULTI-TENANT AUTHORITY BOUNDARY
    // ═══════════════════════════════════════════════════════════════════════
    if (body.action === 'reset_password') {
      const logId = `audit-${Date.now()}-${Math.random().toString(36).slice(2)}`
      await admin.from('audit_logs').insert({
        id: logId,
        empresa_id: callerProfile?.empresa_id ?? null,
        action: 'password_reset_attempt',
        actor_id: caller.id,
        actor_email: caller.email,
        target_email: null,
        ip_address: clientIp,
        payload: { status: 'attempt', action: 'reset_password' },
      })

      const { user_id: requestedUserId, password } = body
      const userId = normalizeUuid(requestedUserId)

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
          .update({ payload: { status: 'edge_proof_unavailable', action: 'reset_password' } })
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
          .update({ payload: { status: 'denied', action: 'reset_password' } })
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
          .update({ payload: { status: 'auth_result_unresolved', action: 'reset_password' } })
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
          .update({ payload: { status: 'lease_release_unresolved', action: 'reset_password' } })
          .eq('id', logId)

        // Auth success was proven before release was attempted. A lost release
        // response can mean either the exact safe release committed or the
        // lease remains. Do not claim success, retry or improvise cleanup.
        return json({ error: 'Não foi possível concluir a redefinição de senha.' }, 500, cors)
      }

      await admin.from('audit_logs')
        .update({ payload: { status: 'success', user_id: authData.user.id } })
        .eq('id', logId)

      return json({ ok: true, user_id: authData.user.id }, 200, cors)
    }

    // ═══════════════════════════════════════════════════════════════════════
    // AÇÃO: CRIAR NOVO USUÁRIO — v17 behavior intentionally preserved
    // ═══════════════════════════════════════════════════════════════════════
    const isRoot = !!adminData
    const isAdminLocal = callerProfile?.is_admin_local === true
    const isGestor = callerProfile?.is_gestor === true

    if (!isRoot && !isAdminLocal && !isGestor) {
      return json({ error: 'Sem permissão. Apenas admin ou gestor podem criar usuários.' }, 403, cors)
    }

    const logId = `audit-${Date.now()}-${Math.random().toString(36).slice(2)}`
    await admin.from('audit_logs').insert({
      id: logId,
      empresa_id: callerProfile?.empresa_id ?? null,
      action: 'user_creation_attempt',
      actor_id: caller.id,
      actor_email: caller.email,
      target_email: body.email ?? null,
      ip_address: clientIp,
      payload: { status: 'attempt', action: body.action ?? 'create' },
    })

    const { nome, email, is_admin_local_novo, is_gestor_novo, time_id } = body
    const password = body.password ?? body.senha
    const empresa_id_alvo = body.empresa_id ?? callerProfile?.empresa_id

    if (!email || !password || !nome) {
      return json({ error: 'email, senha e nome são obrigatórios.' }, 400, cors)
    }

    // ─── Validação de tenant ───────────────────────────────────────────────
    // ROOT pode criar em qualquer empresa
    // Admin local e gestor só podem criar na própria empresa
    if (!isRoot && empresa_id_alvo !== callerProfile?.empresa_id) {
      return json({ error: 'Você só pode criar usuários na sua própria empresa.' }, 403, cors)
    }

    // Gestor NÃO pode criar admin_local nem outro gestor de outro time
    if (isGestor && !isAdminLocal && !isRoot) {
      if (is_admin_local_novo) {
        return json({ error: 'Gestores não podem criar admin local.' }, 403, cors)
      }
      // Gestor só pode criar corretor no seu próprio time
      if (time_id) {
        const { data: gestorTimes } = await admin
          .from('times')
          .select('id')
          .eq('gestor_id', callerProfile!.id)
        const gestorTimeIds = gestorTimes?.map((t: { id: string }) => t.id) ?? []
        if (!gestorTimeIds.includes(time_id)) {
          return json({ error: 'Você só pode criar corretores nos seus próprios times.' }, 403, cors)
        }
      }
    }

    // ─── Verificar limites do plano ────────────────────────────────────────
    if (!isRoot) {
      const { data: empresa } = await admin
        .from('empresas')
        .select('plano_id, planos(max_corretores)')
        .eq('id', empresa_id_alvo)
        .single() as { data: { plano_id: string; planos: { max_corretores: number } } | null }

      if (empresa) {
        const { count } = await admin
          .from('corretores')
          .select('*', { count: 'exact', head: true })
          .eq('empresa_id', empresa_id_alvo)

        const maxCorretores = empresa.planos?.max_corretores ?? 999
        if ((count ?? 0) >= maxCorretores) {
          return json({
            error: `Limite de ${maxCorretores} usuários atingido para o plano atual.`
          }, 403, cors)
        }
      }
    }

    // ─── Criar usuário no Supabase Auth ───────────────────────────────────
    const { data: authData, error: authError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })
    if (authError) {
      await admin.from('audit_logs')
        .update({ payload: { status: 'failed', error: authError.message } })
        .eq('id', logId)
      throw authError
    }

    // ─── Inserir na tabela corretores (v1.1.6 — role obrigatório) ─────────
    const { error: dbError } = await admin.from('corretores').insert({
      user_id:             authData.user.id,
      empresa_id:          empresa_id_alvo,
      time_id:             time_id ?? null,
      nome,
      email,
      role:                is_admin_local_novo ? 'admin_local' : (is_gestor_novo ? 'gestor' : 'corretor'),
      ativo:               true,
      apto_para_receber:   !is_admin_local_novo && !is_gestor_novo,
      is_admin_local:      is_admin_local_novo ?? false,
      is_gestor:           is_gestor_novo ?? false,
      must_change_password: true,
      created_by:          callerProfile?.id ?? null,
    })

    if (dbError) {
      // Rollback: remover do auth se o insert no banco falhar
      await admin.auth.admin.deleteUser(authData.user.id)
      await admin.from('audit_logs')
        .update({ payload: { status: 'rollback', error: dbError.message } })
        .eq('id', logId)
      throw dbError
    }

    // ─── Atualizar log com sucesso ─────────────────────────────────────────
    await admin.from('audit_logs')
      .update({ payload: { status: 'success', user_id: authData.user.id } })
      .eq('id', logId)

    return json({ ok: true, user_id: authData.user.id }, 200, cors)

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err)
    return json({ error: message }, 400, cors)
  }
})
