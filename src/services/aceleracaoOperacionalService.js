// Aceleracao Operacional - Service Bridge
// Usa o mesmo padrao REST/RPC do createSB() existente no App.jsx.
// Nao depende de @supabase/supabase-js nem de client paralelo.

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY

const SESSION_REQUIRED_MESSAGE = 'Sessao expirada ou nao encontrada. Faca login novamente.'
const SENSITIVE_M1_RPCS = new Set(['proximo_lead', 'registrar_feedback'])

function createSessionRequiredError(functionName) {
  const error = new Error(SESSION_REQUIRED_MESSAGE)
  error.code = 'SESSION_REQUIRED'
  error.rpc = functionName
  return error
}

function decodeBase64Url(value) {
  const normalized = String(value || '').replace(/-/g, '+').replace(/_/g, '/')
  const padded = normalized.padEnd(normalized.length + ((4 - (normalized.length % 4)) % 4), '=')
  return atob(padded)
}

function parseJwtPayload(token) {
  const parts = String(token || '').split('.')
  if (parts.length !== 3 || parts.some(part => !part)) return null

  try {
    return JSON.parse(decodeBase64Url(parts[1]))
  } catch (_) {
    return null
  }
}

function isUsableAccessToken(token) {
  const payload = parseJwtPayload(token)
  if (!payload) return false

  if (typeof payload.exp === 'number' && payload.exp * 1000 <= Date.now()) {
    return false
  }

  return true
}

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
    throw new Error('Variaveis VITE_SUPABASE_URL/VITE_SUPABASE_ANON_KEY ausentes no ambiente.')
  }

  const token = findAccessToken()

  if (SENSITIVE_M1_RPCS.has(functionName) && !isUsableAccessToken(token)) {
    throw createSessionRequiredError(functionName)
  }

  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${functionName}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: 'Bearer ' + token,
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
    console.error('[AceleracaoOperacional] erro ao buscar proximo lead', err)
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
