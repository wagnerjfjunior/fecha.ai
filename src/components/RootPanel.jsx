import { useEffect, useMemo, useState } from 'react'
import TenantProvisioningRoot from './TenantProvisioningRoot'

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
  emerald: '#047857',
}

function statusStyle(status) {
  if (status === 'ACTIVE') return { label: 'Ativo', color: C.green, bg: C.green + '18' }
  if (status === 'PENDING_ADMIN') return { label: 'Sem admin', color: C.amber, bg: C.amber + '18' }
  if (status === 'INCOMPLETE') return { label: 'Incompleto', color: C.amber, bg: C.amber + '18' }
  if (status === 'SUSPENDED') return { label: 'Suspenso', color: C.red, bg: C.red + '18' }
  return { label: status || 'Indefinido', color: C.muted, bg: C.border }
}

function formatDate(value) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
  } catch (_) {
    return value
  }
}

function TabButton({ active, children, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '10px 14px',
        borderRadius: 999,
        border: '1px solid ' + (active ? C.accent : C.border),
        background: active ? C.accent : C.card,
        color: active ? 'white' : C.text,
        fontWeight: 800,
        cursor: 'pointer',
      }}
    >
      {children}
    </button>
  )
}

function StatCard({ label, value }) {
  return (
    <div style={{ background: C.card2, border: '1px solid ' + C.border, borderRadius: 14, padding: 14 }}>
      <p style={{ margin: 0, color: C.muted, fontSize: 12, fontWeight: 700 }}>{label}</p>
      <p style={{ margin: '4px 0 0', color: C.text, fontSize: 22, fontWeight: 900 }}>{value}</p>
    </div>
  )
}

function EmpresasTab({ empresas, loading, erro, onReload }) {
  const total = empresas.length
  const ativos = empresas.filter(e => e.provisioning_status === 'ACTIVE').length
  const pendentes = empresas.filter(e => e.provisioning_status === 'PENDING_ADMIN').length
  const usuarios = empresas.reduce((acc, e) => acc + Number(e?.totais?.usuarios || 0), 0)

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 12, marginBottom: 16 }}>
        <StatCard label="Tenants" value={total} />
        <StatCard label="Ativos" value={ativos} />
        <StatCard label="Sem admin" value={pendentes} />
        <StatCard label="Usuários" value={usuarios} />
      </div>

      <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h2 style={{ margin: 0, fontSize: 18, fontWeight: 900 }}>Empresas / Tenants</h2>
          <button onClick={onReload} disabled={loading} style={{ border: '1px solid ' + C.border, background: C.card2, color: C.text, borderRadius: 10, padding: '9px 12px', cursor: 'pointer', fontWeight: 800 }}>
            {loading ? 'Atualizando...' : 'Atualizar'}
          </button>
        </div>

        {erro && <div style={{ color: C.red, background: C.red + '18', padding: 12, borderRadius: 10, marginBottom: 12 }}>{erro}</div>}

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead>
              <tr style={{ color: C.muted, textAlign: 'left', borderBottom: '1px solid ' + C.border }}>
                <th style={{ padding: 10 }}>Empresa</th>
                <th style={{ padding: 10 }}>Status</th>
                <th style={{ padding: 10 }}>Plano</th>
                <th style={{ padding: 10 }}>Usuários</th>
                <th style={{ padding: 10 }}>Admins</th>
                <th style={{ padding: 10 }}>Trial</th>
              </tr>
            </thead>
            <tbody>
              {empresas.map(e => {
                const s = statusStyle(e.provisioning_status)
                return (
                  <tr key={e.empresa_id} style={{ borderBottom: '1px solid ' + C.border }}>
                    <td style={{ padding: 10 }}>
                      <strong>{e.nome}</strong>
                      <div style={{ color: C.muted, fontSize: 12 }}>{e.slug}</div>
                    </td>
                    <td style={{ padding: 10 }}>
                      <span style={{ color: s.color, background: s.bg, padding: '5px 8px', borderRadius: 999, fontWeight: 800, fontSize: 12 }}>
                        {s.label}
                      </span>
                    </td>
                    <td style={{ padding: 10 }}>{e?.plano?.nome || '—'}</td>
                    <td style={{ padding: 10 }}>{e?.totais?.usuarios || 0}</td>
                    <td style={{ padding: 10 }}>{e?.totais?.admins_locais || 0}</td>
                    <td style={{ padding: 10 }}>{formatDate(e.trial_ate)}</td>
                  </tr>
                )
              })}
              {!loading && empresas.length === 0 && (
                <tr><td colSpan={6} style={{ padding: 18, color: C.muted, textAlign: 'center' }}>Nenhuma empresa encontrada.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  )
}

function AdminsTab({ empresas }) {
  const admins = empresas.flatMap(e => (e.admins_locais || []).map(a => ({ ...a, empresa_nome: e.nome, empresa_slug: e.slug })))

  return (
    <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18 }}>
      <h2 style={{ margin: '0 0 12px', fontSize: 18, fontWeight: 900 }}>Admins locais</h2>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
          <thead>
            <tr style={{ color: C.muted, textAlign: 'left', borderBottom: '1px solid ' + C.border }}>
              <th style={{ padding: 10 }}>Nome</th>
              <th style={{ padding: 10 }}>Email</th>
              <th style={{ padding: 10 }}>Empresa</th>
              <th style={{ padding: 10 }}>Ativo</th>
              <th style={{ padding: 10 }}>Trocar senha</th>
              <th style={{ padding: 10 }}>Criado em</th>
            </tr>
          </thead>
          <tbody>
            {admins.map(a => (
              <tr key={a.corretor_id} style={{ borderBottom: '1px solid ' + C.border }}>
                <td style={{ padding: 10 }}>{a.nome || '—'}</td>
                <td style={{ padding: 10 }}>{a.email || '—'}</td>
                <td style={{ padding: 10 }}>{a.empresa_nome}</td>
                <td style={{ padding: 10 }}>{a.ativo ? 'Sim' : 'Não'}</td>
                <td style={{ padding: 10 }}>{a.must_change_password ? 'Sim' : 'Não'}</td>
                <td style={{ padding: 10 }}>{formatDate(a.created_at)}</td>
              </tr>
            ))}
            {admins.length === 0 && (
              <tr><td colSpan={6} style={{ padding: 18, color: C.muted, textAlign: 'center' }}>Nenhum admin local encontrado.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}

export default function RootPanel({ session, sb, token, onCancelar, onProvisionado }) {
  const [aba, setAba] = useState('empresas')
  const [empresas, setEmpresas] = useState([])
  const [loading, setLoading] = useState(false)
  const [erro, setErro] = useState('')

  async function carregarEmpresas() {
    setLoading(true)
    setErro('')
    try {
      const data = await sb.rpc('listar_empresas_root', {}, token)
      setEmpresas(Array.isArray(data) ? data : [])
    } catch (e) {
      setErro(e.message || String(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    carregarEmpresas()
  }, [])

  const handleProvisionado = async (payload) => {
    await carregarEmpresas()
    if (onProvisionado) onProvisionado(payload)
  }

  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, padding: 16 }}>
      <div style={{ maxWidth: 1180, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 16 }}>
          <div>
            <p style={{ color: C.muted, fontSize: 12, fontWeight: 800, letterSpacing: 0.8, textTransform: 'uppercase', margin: 0 }}>Root Admin · Control Plane</p>
            <h1 style={{ margin: '4px 0 0', fontSize: 26, fontWeight: 900 }}>Painel Root</h1>
          </div>
          <button onClick={onCancelar} style={{ background: C.card, border: '1px solid ' + C.border, color: C.text, borderRadius: 10, padding: '10px 14px', cursor: 'pointer', fontWeight: 800 }}>
            ← Voltar
          </button>
        </div>

        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 16 }}>
          <TabButton active={aba === 'empresas'} onClick={() => setAba('empresas')}>Empresas</TabButton>
          <TabButton active={aba === 'admins'} onClick={() => setAba('admins')}>Admins Locais</TabButton>
          <TabButton active={aba === 'provisionamento'} onClick={() => setAba('provisionamento')}>Provisionamento</TabButton>
        </div>

        {aba === 'empresas' && <EmpresasTab empresas={empresas} loading={loading} erro={erro} onReload={carregarEmpresas} />}
        {aba === 'admins' && <AdminsTab empresas={empresas} />}
        {aba === 'provisionamento' && (
          <TenantProvisioningRoot
            session={session}
            sb={sb}
            token={token}
            onProvisionado={handleProvisionado}
            onCancelar={() => setAba('empresas')}
          />
        )}
      </div>
    </div>
  )
}
