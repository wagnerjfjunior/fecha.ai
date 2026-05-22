/*
 * FECH.AI — Discador Flow AI / PME AI Context Patch
 * Version: 0.2.5
 * Purpose: reforçar contexto da dica do corretor e reduzir respostas repetitivas sem alterar feedback/RPC/RLS.
 * Safety: intercepta somente chamadas do módulo discador_flow_ai para assistente-ai; sem envio automático.
 */
(function () {
  'use strict';

  const PATCH_VERSION = '0.2.5';
  const MODULE_NAME = 'discador_flow_ai';
  const TARGET_PATH = '/functions/v1/assistente-ai';
  const MODAL_ID = 'fechai-pme-flow-modal';

  if (window.__FECHAI_PME_AI_CONTEXT_PATCH__) return;
  window.__FECHAI_PME_AI_CONTEXT_PATCH__ = { version: PATCH_VERSION, installedAt: new Date().toISOString() };

  const originalFetch = window.fetch ? window.fetch.bind(window) : null;
  if (!originalFetch) return;

  const STYLE_STRATEGIES = [
    'abertura consultiva com pergunta curta de avanço',
    'tom mais humano e menos formal, parecendo mensagem real de corretor experiente',
    'condução objetiva com validação de interesse antes de oferecer próximo passo',
    'contorno de objeção com empatia, sem parecer insistente',
    'fechamento leve com alternativa clara: seguir, pausar ou agendar',
    'estrutura diferente da anterior, evitando repetir a mesma frase de entrada',
  ];

  function readModalText(selector) {
    try {
      const modal = document.getElementById(MODAL_ID);
      const el = modal ? modal.querySelector(selector) : null;
      return el && typeof el.value === 'string' ? el.value.trim() : '';
    } catch (_) {
      return '';
    }
  }

  function getAttemptKey(context) {
    const situacao = context?.situacao || 'na';
    const canal = context?.canal || 'na';
    const abordagem = context?.abordagem || 'na';
    return `fechai_pme_ai_attempt_${situacao}_${canal}_${abordagem}`;
  }

  function nextAttempt(context) {
    const key = getAttemptKey(context);
    try {
      const current = Number(sessionStorage.getItem(key) || '0') || 0;
      const next = current + 1;
      sessionStorage.setItem(key, String(next));
      return next;
    } catch (_) {
      return Math.floor(Math.random() * 999) + 1;
    }
  }

  function parseLine(prompt, label) {
    const escaped = String(label).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = new RegExp(`${escaped}:\\s*([^\\n]+)`, 'i');
    const match = String(prompt || '').match(re);
    return match && match[1] ? match[1].trim().replace(/\.$/, '') : '';
  }

  function inferChannelRules(canal) {
    const normalized = String(canal || '').toLowerCase();
    if (normalized.includes('whatsapp') || normalized.includes('zap')) {
      return [
        'Formato do WhatsApp: mensagem curta, natural, com no máximo 4 blocos pequenos.',
        'Não use texto com cara de e-mail, não use excesso de vírgulas e não faça discurso longo.',
        'Termine com uma pergunta simples para aumentar resposta do cliente.',
      ];
    }
    if (normalized.includes('email')) {
      return [
        'Formato de e-mail: comece com "Assunto:" e depois corpo objetivo.',
        'Use parágrafos curtos e um próximo passo claro.',
        'Não escreva e-mail genérico; adapte à situação e à dica do corretor.',
      ];
    }
    return [
      'Formato de ligação: crie uma fala que o corretor consiga dizer naturalmente em voz alta.',
      'Use frases curtas, uma pergunta de diagnóstico e um próximo passo.',
      'Não escreva como mensagem de WhatsApp; escreva como roteiro falado.',
    ];
  }

  function buildStrongerPrompt(originalPrompt, context) {
    const liveText = readModalText('[data-modal="text"]');
    const liveTip = readModalText('[data-modal="tip"]');
    const attempt = nextAttempt(context);
    const strategy = STYLE_STRATEGIES[(attempt - 1) % STYLE_STRATEGIES.length];

    const origem = parseLine(originalPrompt, 'Origem do lead') || context?.situacao || 'não informada';
    const canal = parseLine(originalPrompt, 'Canal') || context?.canal || 'não informado';
    const situacao = parseLine(originalPrompt, 'Situação') || context?.abordagem || 'não informada';
    const originalTip = parseLine(originalPrompt, 'Dica do corretor');
    const finalTip = liveTip || (originalTip && !/sem dica/i.test(originalTip) ? originalTip : '');
    const baseText = liveText || String(originalPrompt || '').split('Texto base:').pop() || '';

    const rules = [
      'Você é o copiloto comercial do FECH.AI para corretores imobiliários.',
      'Reescreva o texto para o corretor usar agora, no contexto real do atendimento.',
      '',
      'REGRA CRÍTICA SOBRE A DICA DO CORRETOR:',
      finalTip
        ? `A dica abaixo é o principal direcionador da resposta. Adapte a mensagem especificamente a ela, usando a dica como contexto operacional, não como detalhe opcional: "${finalTip}".`
        : 'Não há dica adicional. Mesmo assim, use origem, canal e situação para não gerar texto genérico.',
      '',
      'CONTEXTO DO FLUXO:',
      `Origem do lead: ${origem}.`,
      `Canal escolhido: ${canal}.`,
      `Situação comercial: ${situacao}.`,
      `Tentativa de IA no modal: ${attempt}.`,
      `Estratégia desta variação: ${strategy}.`,
      '',
      'REGRAS DO CANAL:',
      ...inferChannelRules(canal),
      '',
      'ANTI-REPETIÇÃO:',
      'Não repita a mesma abertura, o mesmo fechamento ou a mesma estrutura do texto base.',
      'Evite frases genéricas como "passando para retomar", "de forma objetiva" e "sem pressão" quando elas já aparecerem no texto base.',
      'Crie uma versão realmente diferente, mas sem inventar dados comerciais.',
      '',
      'SEGURANÇA COMERCIAL:',
      'Não invente preço, desconto, unidade, disponibilidade, prazo, condição, aprovação ou promessa.',
      'Não diga que enviou algo automaticamente. O corretor sempre revisa antes.',
      'Não mencione que é IA e não explique o raciocínio.',
      '',
      'TEXTO BASE/ANTERIOR A EVITAR:',
      baseText,
      '',
      'RETORNO:',
      'Retorne somente o texto final pronto para uso, sem comentários, sem markdown e sem opções numeradas.',
    ];

    return rules.join('\n');
  }

  function shouldPatchFetch(url, init, payload) {
    const targetUrl = typeof url === 'string' ? url : (url && url.url) || '';
    if (!String(targetUrl).includes(TARGET_PATH)) return false;
    if (!payload || payload?.context?.module !== MODULE_NAME) return false;
    if (!Array.isArray(payload.messages) || !payload.messages[0]) return false;
    return typeof payload.messages[0].content === 'string';
  }

  function cloneInitWithBody(init, payload) {
    const nextPayload = {
      ...payload,
      messages: [{ ...payload.messages[0], content: buildStrongerPrompt(payload.messages[0].content, payload.context || {}) }],
      context: { ...(payload.context || {}), prompt_patch_version: PATCH_VERSION, prompt_profile: 'context_first_anti_repetition' },
    };
    return { ...(init || {}), body: JSON.stringify(nextPayload) };
  }

  window.fetch = async function patchedFetch(input, init) {
    try {
      const body = init && typeof init.body === 'string' ? init.body : '';
      if (!body) return originalFetch(input, init);
      const payload = JSON.parse(body);
      if (!shouldPatchFetch(input, init, payload)) return originalFetch(input, init);
      return originalFetch(input, cloneInitWithBody(init, payload));
    } catch (_) {
      return originalFetch(input, init);
    }
  };

  function refreshModalHints() {
    try {
      const modal = document.getElementById(MODAL_ID);
      if (!modal) return;
      const tip = modal.querySelector('[data-modal="tip"]');
      const aiButton = modal.querySelector('[data-modal-action="ai"]');
      if (tip && aiButton) {
        aiButton.textContent = tip.value.trim() ? 'Gerar com esta dica' : 'Gerar nova versão';
      }
      if (tip && !tip.__pmeTipBound) {
        tip.__pmeTipBound = true;
        tip.addEventListener('input', refreshModalHints);
      }
    } catch (_) {}
  }

  const observer = new MutationObserver(refreshModalHints);
  observer.observe(document.body, { childList: true, subtree: true });
  document.addEventListener('input', function (e) {
    if (e.target && e.target.matches && e.target.matches(`#${MODAL_ID} [data-modal="tip"]`)) refreshModalHints();
  }, true);
  refreshModalHints();
})();
