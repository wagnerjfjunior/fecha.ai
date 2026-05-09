// CriarUsuario.jsx — compatibility adapter
// Fluxo oficial de criação de usuários: CriarUsuarioForm.jsx -> Edge Function criar-usuario -> Supabase Auth -> corretores
// Mantém compatibilidade com chamadas antigas de <CriarUsuario /> no App.jsx sem duplicar regra de negócio.

import { useEffect, useMemo, useState } from 'react'
import CriarUsuarioForm from './CriarUsuarioForm'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://uobxxgzshrmbtjfdolxd.supabase.co'
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIUzI1NiIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w'

function decodeJwtSub(token) {
  try {
    const payload = token.split('.')[1]
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/')
    const json = JSON.parse(atob(normalized))
    return json.sub || null
  } catch {
    return null
  }
}

function buildMinimalSb() {
  const headers = (token) => ({
    apikey: SUPABASE_KEY,
    Authorization: 'Bearer ' + (token || SUPABASE_KEY),
    'Content-Type': 'application/json',
  })

  return {
    async rpc(fn, args, token) {
      const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
        method: 'POST',
        headers: headers(token),
        body: JSON.stringify(args || {}),
      })
      const data = await res.json().catch(() => ({}))
      if (!res.ok) throw new Error(data.message || data.error || `Erro ${fn}`)
      return data
    },
    async query(table, params, token) {
      const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${params || ''}`, {
        headers: headers(token),
      })
      const data = await res.json().catch(() => [])
      if (!res.ok) throw new Error(data.message || data.error || `Erro ${table}`)
      return data
    },
  }
}

export default function CriarUsuario(props) {
  const { session, token: tokenProp, sb: sbProp, corretor: corretorProp } = props
  const token = tokenProp || session?.access_token || ''
  const sb = useMemo(() => sbProp || buildMinimalSb(), [sbProp])
  const [corretor, setCorretor] = useState(corretorProp || null)
  const [loadingProfile, setLoadingProfile] = useState(!corretorProp)

  useEffect(() => {
    if (corretorProp) {
      setCorretor(corretorProp)
      setLoadingProfile(false)
      return
    }

    const userId = session?.user?.id || decodeJwtSub(token)
    if (!userId || !token) {
      setLoadingProfile(false)
      return
    }

    let cancelled = false
    ;(async () => {
      setLoadingProfile(true)
      try {
        const rows = await sb.query(
          'corretores',
          `select=id,user_id,nome,email,empresa_id,time_id,is_gestor,is_admin_local,role,ativo&user_id=eq.${userId}&limit=1`,
          token,
        )
        if (!cancelled) setCorretor(rows?.[0] || null)
      } catch (err) {
        console.error('Erro ao carregar perfil para criação de usuário:', err)
        if (!cancelled) setCorretor(null)
      } finally {
        if (!cancelled) setLoadingProfile(false)
      }
    })()

    return () => { cancelled = true }
  }, [corretorProp, session?.user?.id, sb, token])

  if (loadingProfile) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#0f172a', color: '#f1f5f9' }}>
        Carregando permissões de administração...
      </div>
    )
  }

  return (
    <CriarUsuarioForm
      {...props}
      session={session}
      corretor={corretor}
      sb={sb}
      token={token}
    />
  )
}
