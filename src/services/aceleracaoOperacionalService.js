// Aceleracao Operacional — Service Bridge
// Usa o mesmo padrão REST/RPC do createSB() existente no App.jsx.
// Não depende de @supabase/supabase-js nem de client paralelo.

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY

function findAccessToken() {
  try {
    for (let i = 0; i < localStorage.length; i += 1) {
      const key = localStorage.key(i)
      const raw = localStorage.getItem(key)
      if (!raw) continue

      try {
        const parsed = JSON.parse(raw)
        const token = parsed?.access_token || parsed?.session?.access_token || parsed?.currentSession?.access_token
        if (token) return token
      } catch (_) {
        if (raw.startsWith('eyJ')) return raw
      }
    }
  } catch (_) {}

  return ''
}

async function rpc(functionName, payload = {}) {
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    throw new Error('Variáveis VITE_SUPABASE_URL/VITE_SUPABASE_ANON_KEY ausentes no ambiente.')
  }

  const token = findAccessToken()
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${functionName}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: 'Bearer ' + (token || SUPABASE_KEY),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload || {}),
  })

  const data = await response.json().catch(() => null)

  if (!response.ok) {
    const message = data?.message || data?.error || `Erro RPC ${functionName}`
    throw new Error(message)
  }

  return data
}

export async function buscarProximoLeadOperacional(payload = {}) {
  try {
    const data = await rpc('proximo_lead', payload)
    const lead = Array.isArray(data) ? data[0] : data
    return { ok: true, lead: lead || null }
  } catch (err) {
    console.error('[AceleracaoOperacional] erro ao buscar próximo lead', err)
    return { ok: false, error: err, lead: null }
  }
}

export async function registrarFeedbackOperacional(payload = {}) {
  try {
    const data = await rpc('registrar_feedback', payload)
    return { ok: true, result: data }
  } catch (err) {
    console.error('[AceleracaoOperacional] erro ao registrar feedback', err)
    return { ok: false, error: err }
  }
}

export function calcularPressaoOperacional({ visitasAgendadas = 0, metaVisitas = 10, mediaConversao = 18 }) {
  const faltam = Math.max(metaVisitas - visitasAgendadas, 0)
  return {
    faltam,
    leadsNecessarios: faltam * mediaConversao,
    risco: faltam >= 7 ? 'alto' : faltam >= 3 ? 'medio' : 'baixo',
  }
}
