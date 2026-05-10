// Aceleracao Operacional — Service Bridge
// Objetivo:
// Centralizar integração do cockpit operacional
// com as RPCs soberanas do FECH.AI.

import { supabase } from '../lib/supabase'

export async function buscarProximoLeadOperacional(payload = {}) {
  try {
    const { data, error } = await supabase.rpc('proximo_lead', payload)

    if (error) {
      console.error('[AceleracaoOperacional] erro ao buscar próximo lead', error)
      throw error
    }

    return {
      ok: true,
      lead: data || null,
    }
  } catch (err) {
    console.error('[AceleracaoOperacional] falha operacional', err)

    return {
      ok: false,
      error: err,
      lead: null,
    }
  }
}

export async function registrarFeedbackOperacional(payload = {}) {
  try {
    const { data, error } = await supabase.rpc('registrar_feedback', payload)

    if (error) {
      console.error('[AceleracaoOperacional] erro ao registrar feedback', error)
      throw error
    }

    return {
      ok: true,
      result: data,
    }
  } catch (err) {
    console.error('[AceleracaoOperacional] falha ao registrar feedback', err)

    return {
      ok: false,
      error: err,
    }
  }
}

export function gerarContextoOperacional({
  canalAtual,
  contexto,
  feedback,
}) {
  return {
    canalAtual,
    contexto,
    feedback,
    timestamp: new Date().toISOString(),
  }
}

export function calcularPressaoOperacional({
  visitasAgendadas = 0,
  metaVisitas = 10,
  mediaConversao = 18,
}) {
  const faltam = Math.max(metaVisitas - visitasAgendadas, 0)

  return {
    faltam,
    leadsNecessarios: faltam * mediaConversao,
    risco:
      faltam >= 7
        ? 'alto'
        : faltam >= 3
          ? 'medio'
          : 'baixo',
  }
}
