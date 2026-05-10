import { useEffect, useMemo, useState } from 'react'

const EDGE_URL = '/api/criar-usuario'
const C = {
  bg: '#0f172a',
  card: '#1e293b',
  card2: '#111827',
  border: '#334155',
  text: '#f1f5f9',
  muted: '#94a3b8',
  accent: '#2563eb',
  green: '#10b981',
  red: '#ef4444',
  amber: '#f59e0b',
}

function Campo({ label, type = 'text', value, onChange, placeholder, disabled }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6, fontWeight: 600 }}>
        {label}
      </label>
      <input
        type={type}
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        disabled={disabled}
        style={{
          width: '100%',
          padding: '12px 14px',
          borderRadius: 10,
          fontSize: 15,
          background: C.bg,
          border: '1px solid ' + C.border,
          color: C.text,
          outline: 'none',
          boxSizing: 'border-box',
          opacity: disabled ? 0.55 : 1,
        }}
      />
    </div>
  )
}

function slugify(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

export default function TenantProvisioningRoot({ session, sb, token, onCancelar, onProvisionado }) {
  const [planos, setPlanos] = useState([])
  const [carregandoPlanos, setCarregandoPlanos] = useState(false)

  const [empresaNome, setEmpresaNome] = useState('')
  const [empresaSlug, setEmpresaSlug] = useState('')
  const [slugManual, setSlugManual] = useState(false)
  const [planoId, setPlanoId] = useState('')
  const [trialDias, setTrialDias] = useState('7')

  const [adminNome, setAdminNome] = useState('')
  const [adminEmail, setAdminEmail] = useState('')
  const [adminSenha, setAdminSenha] = useState('')
  const [adminConfirma, setAdminConfirma] = useState('')

  const [carregando, setCarregando] = useState(false)
  const [erro, setErro] = useState('')
  const [sucesso, setSucesso] = useState('')
  const [resultado, setResultado] = useState(null)

  useEffect(() => {
    if (slugManual) return
    setEmpresaSlug(slugify(empresaNome))
  }, [empresaNome, slugManual])

  useEffect(() => {
    let ativo = true
    ;(async () => {
      setCarregandoPlanos(true)
      try {
        const lista = await sb.query(
          'planos',
          'select=id,nome,slug,max_corretores,max_times,max_leads_mes,ativo&ativo=eq.true&order=created_at.asc',
          token
        )
        if (!ativo) return
        setPlanos(lista || [])
        const enterprise = (lista || []).find(p => p.slug === 'enterprise')
        const primeiro = (lista || [])[0]
        setPlanoId((enterprise || primeiro)?.id || '')
      } catch (e) {
        if (ativo) setErro('Erro ao carregar planos: ' + e.message)
      } finally {
        if (ativo) setCarregandoPlanos(false)
      }
    })()
    return () => { ativo = false }
  }, [sb, token])

  const planoSelecionado = useMemo(
    () => planos.find(p => p.id === planoId),
    [planos, planoId]
  )

  function validar() {
    if (!empresaNome.trim()) return 'Informe o nome da empresa.'
    if (!empresaSlug.trim()) return 'Informe o slug da empresa.'
    if (!/^[a-z0-9-]+$/.test(empresaSlug.trim())) return 'Slug deve conter apenas letras minúsculas, números e hífen.'
    if (!planoId) return 'Selecione um plano.'
    if (!adminNome.trim()) return 'Informe o nome do admin local.'
    if (!/^\S+@\S+\.\S+$/.test(adminEmail.trim())) return 'Informe um e-mail válido para o admin local.'
    if (!adminSenha || adminSenha.length < 8) return 'Senha provisória deve ter no mínimo 8 caracteres.'
    if (adminSenha !== adminConfirma) return 'As senhas do admin local não coincidem.'
    const trial = Number(trialDias)
    if (!Number.isFinite(trial) || trial < 0) return 'Trial deve ser um número maior ou igual a zero.'
    return ''
  }

  async function handleProvisionar() {
    setErro('')
    setSucesso('')
    setResultado(null)

    const erroValidacao = validar()
    if (erroValidacao) {
      setErro(erroValidacao)
      return
    }

    setCarregando(true)

    try {
      // 1) Cria tenant pelo Control Plane no Postgres.
      const tenant = await sb.rpc('criar_empresa_root', {
        p_nome: empresaNome.trim(),
        p_slug: empresaSlug.trim().toLowerCase(),
        p_plano_id: planoId,
        p_trial_dias: Number(trialDias),
      }, token)

      const empresaId = tenant?.empresa_id
      if (!empresaId) {
        throw new Error('RPC criar_empresa_root não retornou empresa_id.')
      }

      // 2) Cria admin local pela Edge Function oficial criar-usuario.
      const r = await fetch(EDGE_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer ' + session.access_token,
        },
        body: JSON.stringify({
          nome: adminNome.trim(),
          email: adminEmail.trim().toLowerCase(),
          password: adminSenha,
          empresa_id: empresaId,
          is_admin_local_novo: true,
          is_gestor_novo: false,
          time_id: null,
        }),
      })

      const usuario = await r.json()
      if (!r.ok || usuario.error) {
        throw new Error(usuario.error || 'Empresa criada, mas falhou ao criar admin local.')
      }

      const payload = { tenant, usuario }
      setResultado(payload)
      setSucesso('✅ Empresa criada e admin local provisionado com sucesso.')

      setEmpresaNome('')
      setEmpresaSlug('')
      setSlugManual(false)
      setTrialDias('7')
      setAdminNome('')
      setAdminEmail('')
      setAdminSenha('')
      setAdminConfirma('')

      if (onProvisionado) onProvisionado(payload)
    } catch (e) {
      setErro(e.message || String(e))
    } finally {
      setCarregando(false)
    }
  }

  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, padding: 16 }}>
      <div style={{ maxWidth: 920, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 18 }}>
          <div>
            <p style={{ color: C.muted, fontSize: 12, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase', margin: 0 }}>
              Root Admin · Tenant Provisioning
            </p>
            <h1 style={{ margin: '4px 0 0', fontSize: 24, fontWeight: 800 }}>
              Criar nova empresa
            </h1>
          </div>
          <button
            onClick={onCancelar}
            style={{ background: C.card, border: '1px solid ' + C.border, color: C.text, borderRadius: 10, padding: '10px 14px', cursor: 'pointer', fontWeight: 700 }}
          >
            ← Voltar
          </button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 16 }}>
          <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 20 }}>
            <h2 style={{ margin: '0 0 14px', fontSize: 17, fontWeight: 800 }}>1. Dados da empresa</h2>

            <Campo label="Nome da empresa" value={empresaNome} onChange={setEmpresaNome} placeholder="Ex: Helbor Prime" disabled={carregando} />

            <div style={{ marginBottom: 14 }}>
              <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6, fontWeight: 600 }}>
                Slug do tenant
              </label>
              <input
                value={empresaSlug}
                onChange={e => { setSlugManual(true); setEmpresaSlug(slugify(e.target.value)) }}
                placeholder="helbor-prime"
                disabled={carregando}
                style={{ width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 15, background: C.bg, border: '1px solid ' + C.border, color: C.text, outline: 'none', boxSizing: 'border-box' }}
              />
              <p style={{ color: C.muted, fontSize: 11, margin: '6px 0 0' }}>Usado como identificador único do tenant.</p>
            </div>

            <div style={{ marginBottom: 14 }}>
              <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6, fontWeight: 600 }}>
                Plano
              </label>
              <select
                value={planoId}
                onChange={e => setPlanoId(e.target.value)}
                disabled={carregando || carregandoPlanos}
                style={{ width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 15, background: C.bg, border: '1px solid ' + C.border, color: C.text, outline: 'none', boxSizing: 'border-box' }}
              >
                <option value="">Selecione...</option>
                {planos.map(p => <option key={p.id} value={p.id}>{p.nome}</option>)}
              </select>
              {planoSelecionado && (
                <p style={{ color: C.muted, fontSize: 11, margin: '6px 0 0' }}>
                  Limites: {planoSelecionado.max_corretores} usuários · {planoSelecionado.max_times} times · {planoSelecionado.max_leads_mes} leads/mês
                </p>
              )}
            </div>

            <Campo label="Trial em dias" type="number" value={trialDias} onChange={setTrialDias} placeholder="7" disabled={carregando} />
          </section>

          <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 20 }}>
            <h2 style={{ margin: '0 0 14px', fontSize: 17, fontWeight: 800 }}>2. Admin local inicial</h2>

            <Campo label="Nome completo" value={adminNome} onChange={setAdminNome} placeholder="Ex: Maria Silva" disabled={carregando} />
            <Campo label="E-mail" type="email" value={adminEmail} onChange={setAdminEmail} placeholder="admin@empresa.com.br" disabled={carregando} />
            <Campo label="Senha provisória" type="password" value={adminSenha} onChange={setAdminSenha} placeholder="Mínimo 8 caracteres" disabled={carregando} />
            <Campo label="Confirmar senha" type="password" value={adminConfirma} onChange={setAdminConfirma} placeholder="Repita a senha" disabled={carregando} />

            <div style={{ background: C.card2, border: '1px solid ' + C.border, borderRadius: 12, padding: 12, marginBottom: 14 }}>
              <p style={{ color: C.amber, margin: '0 0 6px', fontSize: 13, fontWeight: 800 }}>Fluxo seguro</p>
              <p style={{ color: C.muted, margin: 0, fontSize: 12, lineHeight: 1.5 }}>
                A empresa será criada via RPC root. O admin local será criado pela Edge Function oficial criar-usuario, sem insert direto em corretores.
              </p>
            </div>

            {erro && <div style={{ color: C.red, background: C.red + '18', padding: 12, borderRadius: 10, fontSize: 13, marginBottom: 12 }}>{erro}</div>}
            {sucesso && <div style={{ color: C.green, background: C.green + '18', padding: 12, borderRadius: 10, fontSize: 13, marginBottom: 12 }}>{sucesso}</div>}

            <button
              onClick={handleProvisionar}
              disabled={carregando || carregandoPlanos}
              style={{ width: '100%', padding: 14, borderRadius: 12, border: 'none', background: carregando ? C.border : C.accent, color: 'white', fontWeight: 800, cursor: carregando ? 'not-allowed' : 'pointer', fontSize: 15 }}
            >
              {carregando ? 'Provisionando tenant...' : 'Criar empresa e admin local'}
            </button>
          </section>
        </div>

        {resultado && (
          <section style={{ marginTop: 16, background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18 }}>
            <h2 style={{ margin: '0 0 10px', fontSize: 16, fontWeight: 800 }}>Resultado</h2>
            <pre style={{ overflowX: 'auto', background: C.bg, color: C.text, padding: 12, borderRadius: 10, fontSize: 12 }}>
              {JSON.stringify(resultado, null, 2)}
            </pre>
          </section>
        )}
      </div>
    </div>
  )
}
