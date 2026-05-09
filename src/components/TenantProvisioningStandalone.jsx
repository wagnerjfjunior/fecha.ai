import { useMemo, useState } from 'react'
import TenantProvisioningRoot from './TenantProvisioningRoot'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://uobxxgzshrmbtjfdolxd.supabase.co'
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w'

const C = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#f1f5f9',
  muted: '#94a3b8', accent: '#2563eb', red: '#ef4444',
}

function createSB(url, key) {
  const hd = (t) => ({ apikey: key, Authorization: 'Bearer ' + (t || key), 'Content-Type': 'application/json' })
  return {
    async signIn(email, password) {
      const r = await fetch(url + '/auth/v1/token?grant_type=password', {
        method: 'POST',
        headers: { apikey: key, 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })
      const data = await r.json()
      if (!r.ok) throw new Error(data.error_description || data.msg || data.message || 'Erro no login')
      return data
    },
    async query(table, params, token) {
      const r = await fetch(url + '/rest/v1/' + table + '?' + (params || ''), { headers: hd(token) })
      const data = await r.json()
      if (!r.ok) throw new Error(data.message || 'Erro ao consultar ' + table)
      return data
    },
    async rpc(fn, args, token) {
      const r = await fetch(url + '/rest/v1/rpc/' + fn, {
        method: 'POST',
        headers: hd(token),
        body: JSON.stringify(args || {}),
      })
      const data = await r.json()
      if (!r.ok) throw new Error(data.message || data.error || 'Erro RPC ' + fn)
      return data
    },
  }
}

function LoginRoot({ onLogin }) {
  const [email, setEmail] = useState('root@fech.ai')
  const [senha, setSenha] = useState('')
  const [erro, setErro] = useState('')
  const [loading, setLoading] = useState(false)
  const sb = useMemo(() => createSB(SUPABASE_URL, SUPABASE_KEY), [])

  async function entrar() {
    setErro('')
    setLoading(true)
    try {
      const session = await sb.signIn(email.trim().toLowerCase(), senha)
      const isRoot = await sb.rpc('is_root', {}, session.access_token)
      if (isRoot !== true) throw new Error('Usuário autenticado, mas não é root.')
      onLogin({ session, sb, token: session.access_token })
    } catch (e) {
      setErro(e.message || String(e))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ width: '100%', maxWidth: 420, background: C.card, border: '1px solid ' + C.border, borderRadius: 20, padding: 24 }}>
        <button onClick={() => { window.location.hash = ''; window.location.reload() }} style={{ background: 'none', border: 'none', color: C.muted, fontSize: 14, cursor: 'pointer', marginBottom: 16 }}>← Voltar</button>
        <p style={{ color: C.muted, fontSize: 12, fontWeight: 800, letterSpacing: 0.8, textTransform: 'uppercase', margin: 0 }}>Root Admin</p>
        <h1 style={{ margin: '4px 0 20px', fontSize: 22, fontWeight: 800 }}>Provisionar empresa</h1>

        <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6 }}>E-mail root</label>
        <input value={email} onChange={e => setEmail(e.target.value)} disabled={loading} style={{ width: '100%', boxSizing: 'border-box', padding: 12, borderRadius: 10, border: '1px solid ' + C.border, background: C.bg, color: C.text, marginBottom: 14 }} />

        <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6 }}>Senha</label>
        <input type="password" value={senha} onChange={e => setSenha(e.target.value)} onKeyDown={e => e.key === 'Enter' && entrar()} disabled={loading} style={{ width: '100%', boxSizing: 'border-box', padding: 12, borderRadius: 10, border: '1px solid ' + C.border, background: C.bg, color: C.text, marginBottom: 14 }} />

        {erro && <div style={{ color: C.red, background: C.red + '18', borderRadius: 10, padding: 10, fontSize: 13, marginBottom: 14 }}>{erro}</div>}

        <button onClick={entrar} disabled={loading || !email || !senha} style={{ width: '100%', padding: 14, border: 'none', borderRadius: 12, background: loading ? C.border : C.accent, color: 'white', fontWeight: 800, cursor: loading ? 'not-allowed' : 'pointer' }}>
          {loading ? 'Validando root...' : 'Entrar no provisionamento'}
        </button>
      </div>
    </div>
  )
}

export default function TenantProvisioningStandalone() {
  const [ctx, setCtx] = useState(null)

  if (!ctx) return <LoginRoot onLogin={setCtx} />

  return (
    <TenantProvisioningRoot
      session={ctx.session}
      sb={ctx.sb}
      token={ctx.token}
      onCancelar={() => { window.location.hash = ''; window.location.reload() }}
    />
  )
}
