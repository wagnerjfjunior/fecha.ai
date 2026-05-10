// Aceleracao Operacional — Service Bridge
// Integração desacoplada do core do FECH.AI.
// IMPORTANTE:
// O projeto utiliza createSB() soberano dentro do App.jsx.
// Não utilizar imports inexistentes de supabase.

export async function buscarProximoLeadOperacional(payload = {}) {
  console.warn('[AceleracaoOperacional] integração RPC ainda em preparação', payload)

  return {
    ok: true,
    lead: null,
  }
}

export async function registrarFeedbackOperacional(payload = {}) {
  console.warn('[AceleracaoOperacional] registrar feedback aguardando integração real', payload)

  return {
    ok: true,
    result: null,
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
