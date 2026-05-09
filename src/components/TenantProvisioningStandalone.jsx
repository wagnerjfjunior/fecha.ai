import { useMemo, useState } from 'react'
import TenantProvisioningRoot from './TenantProvisioningRoot'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://uobxxgzshrmbtjfdolxd.supabase.co'
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w'

const C = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#f1f5f9',
  muted: '#94a3b8', accent: '#2563eb', red: '#ef4444', green: '#10b981',
}

function createSB(url, key) {
  const hd = (t) => ({ apikey: key, Authorization: 'Bearer ' + (t || key), 'Content-Type': 'application/json' })
  return {
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

function BlockedStandalone({ onVoltar }) {
  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ width: '100%', maxWidth: 560, background: C.card, border: '1px solid ' + C.border, borderRadius: 20, padding: 24 }}>
        <button onClick={onVoltar} style={{ background: 'none', border: 'none', color: C.muted, fontSize: 14, cursor: 'pointer', marginBottom: 16 }}>← Voltar</button>
        <p style={{ color: C.muted, fontSize: 12, fontWeight: 800, letterSpacing: 0.8, textTransform: 'uppercase', margin: 0 }}>Root Admin · Segurança</p>
        <h1 style={{ margin: '4px 0 14px', fontSize: 22, fontWeight: 800 }}>Login standalone bloqueado</h1>
        <div style={{ color: C.red, background: C.red + '18', borderRadius: 12, padding: 14, fontSize: 14, lineHeight: 1.5, marginBottom: 14 }}>
          Por segurança, esta tela não solicita mais a senha do root no navegador. O provisionamento deve ser aberto a partir da sessão já autenticada no FECH.AI.
        </div>
        <p style={{ color: C.muted, fontSize: 14, lineHeight: 1.6, margin: '0 0 16px' }}>
          A próxima etapa é integrar o formulário diretamente no App.jsx com a sessão já existente. Até lá, não use password grant para root nesta rota.
        </p>
        <button onClick={onVoltar} style={{ width: '100%', padding: 14, border: 'none', borderRadius: 12, background: C.accent, color: 'white', fontWeight: 800, cursor: 'pointer' }}>
          Voltar ao FECH.AI
        </button>
      </div>
    </div>
  )
}

export default function TenantProvisioningStandalone() {
  const sb = useMemo(() => createSB(SUPABASE_URL, SUPABASE_KEY), [])
  const [ctx] = useState(null)

  if (!ctx) {
    return <BlockedStandalone onVoltar={() => { window.location.hash = ''; window.location.reload() }} />
  }

  return (
    <TenantProvisioningRoot
      session={ctx.session}
      sb={sb}
      token={ctx.token}
      onCancelar={() => { window.location.hash = ''; window.location.reload() }}
    />
  )
}
