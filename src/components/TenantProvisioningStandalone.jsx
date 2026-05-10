import { useEffect, useMemo, useState } from 'react'
import RootPanel from './RootPanel'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY

const C = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#f1f5f9',
  muted: '#94a3b8', accent: '#2563eb', red: '#ef4444', green: '#10b981',
}

function createSB(url, key) {
  if (!url || !key) throw new Error('Configuração Supabase ausente no ambiente Vercel.')

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

function MensagemSeguranca({ titulo, mensagem, detalhe, onVoltar }) {
  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ width: '100%', maxWidth: 560, background: C.card, border: '1px solid ' + C.border, borderRadius: 20, padding: 24 }}>
        <button onClick={onVoltar} style={{ background: 'none', border: 'none', color: C.muted, fontSize: 14, cursor: 'pointer', marginBottom: 16 }}>← Voltar</button>
        <p style={{ color: C.muted, fontSize: 12, fontWeight: 800, letterSpacing: 0.8, textTransform: 'uppercase', margin: 0 }}>Root Admin · Segurança</p>
        <h1 style={{ margin: '4px 0 14px', fontSize: 22, fontWeight: 800 }}>{titulo}</h1>
        <div style={{ color: C.red, background: C.red + '18', borderRadius: 12, padding: 14, fontSize: 14, lineHeight: 1.5, marginBottom: 14 }}>
          {mensagem}
        </div>
        {detalhe && (
          <p style={{ color: C.muted, fontSize: 14, lineHeight: 1.6, margin: '0 0 16px' }}>
            {detalhe}
          </p>
        )}
        <button onClick={onVoltar} style={{ width: '100%', padding: 14, border: 'none', borderRadius: 12, background: C.accent, color: 'white', fontWeight: 800, cursor: 'pointer' }}>
          Voltar ao FECH.AI
        </button>
      </div>
    </div>
  )
}

function carregarSessaoFechai() {
  try {
    const raw = localStorage.getItem('fechai_session')
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed?.access_token || !parsed?.user?.id) return null
    return parsed
  } catch (_) {
    return null
  }
}

export default function TenantProvisioningStandalone() {
  const [ctx, setCtx] = useState(null)
  const [loading, setLoading] = useState(true)
  const [erro, setErro] = useState('')

  const sb = useMemo(() => {
    try {
      return createSB(SUPABASE_URL, SUPABASE_KEY)
    } catch (e) {
      setErro(e.message || String(e))
      return null
    }
  }, [])

  useEffect(() => {
    if (!sb) {
      setLoading(false)
      return
    }

    let ativo = true
    ;(async () => {
      setLoading(true)
      setErro('')
      try {
        const session = carregarSessaoFechai()
        if (!session) {
          throw new Error('Sessão FECH.AI não encontrada. Entre primeiro no sistema como root e depois clique em Painel Root.')
        }

        const isRoot = await sb.rpc('is_root', {}, session.access_token)
        if (isRoot !== true) {
          throw new Error('Sessão encontrada, mas o usuário autenticado não é root.')
        }

        if (ativo) setCtx({ session, token: session.access_token })
      } catch (e) {
        if (ativo) setErro(e.message || String(e))
      } finally {
        if (ativo) setLoading(false)
      }
    })()

    return () => { ativo = false }
  }, [sb])

  const voltar = () => {
    window.location.hash = ''
    window.location.reload()
  }

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', background: C.bg, color: C.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        Validando sessão root...
      </div>
    )
  }

  if (erro || !ctx || !sb) {
    return (
      <MensagemSeguranca
        titulo="Provisionamento bloqueado"
        mensagem={erro || 'Não foi possível validar a sessão root.'}
        detalhe="Esta rota não solicita senha do root. Ela reutiliza somente a sessão autenticada existente do FECH.AI."
        onVoltar={voltar}
      />
    )
  }

  return (
    <RootPanel
      session={ctx.session}
      sb={sb}
      token={ctx.token}
      onProvisionado={() => {}}
      onCancelar={voltar}
    />
  )
}
