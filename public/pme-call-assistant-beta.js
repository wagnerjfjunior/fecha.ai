/*
 * FECH.AI — Discador Flow AI / PME Beta
 * Version: 0.2.0
 * Purpose: fluxo assistido do corretor no discador, mobile-first, com fallback manual e IA opcional.
 * Safety: sem envio automático, sem alteração de feedback/RPC/RLS, sem service_role, sem segredo no frontend.
 */
(function () {
  'use strict';

  const VERSION = '0.2.0';
  const ROOT_ID = 'fechai-pme-call-assistant';
  const STYLE_ID = 'fechai-pme-call-assistant-style';
  const MODAL_ID = 'fechai-pme-flow-modal';
  const SUPABASE_URL = 'https://uobxxgzshrmbtjfdolxd.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w';

  const CONTEXTS = {
    lista_fria: { label: 'Lista fria', icon: '🧊', hint: 'Lead frio precisa de permissão, triagem e saída elegante.' },
    visitou: { label: 'Já visitou', icon: '🔥', hint: 'Lead de fundo de funil. Foque em objeção, fluxo e próximo passo.' },
    redes_sociais: { label: 'Redes Sociais', icon: '📲', hint: 'Lead inbound/social precisa de velocidade e contexto.' },
    problemas: { label: 'Problemas', icon: '⚠️', hint: 'Use para objeções, travas e situações delicadas.' },
    argumentacoes: { label: 'Argumentações', icon: '💬', hint: 'Banco rápido de argumentos para sustentar a conversa.' },
  };

  const CHANNELS = {
    ligacao: { label: 'Ligação', icon: '📞' },
    whatsapp: { label: 'WhatsApp', icon: '💬' },
    email: { label: 'E-mail', icon: '✉️' },
  };

  const APPROACHES = {
    primeira_abordagem: 'Primeira abordagem',
    retorno: 'Retorno',
    pos_ligacao: 'Pós-ligação',
    convite: 'Convite',
    objecao_preco: 'Objeção de preço',
    objecao_entrada: 'Objeção de entrada',
    sem_resposta: 'Sem resposta',
    fim_contato: 'Fim de contato',
  };

  const TEMPLATES = {
    lista_fria: {
      ligacao: {
        primeira_abordagem: [
          'Oi, {{nome}}, tudo bem? Aqui é {{corretor}}, da {{empresa}}. Prometo ser breve: imóvel é um assunto aberto para você hoje ou prefere que eu não siga com esse contato?',
          'Olá, {{nome}}. Estou falando com algumas pessoas que avaliam imóveis em São Paulo. Posso te fazer uma pergunta rápida para entender se faz sentido te mandar algo ou pausar por aqui?',
        ],
        retorno: ['{{nome}}, combinei de te retornar. Para eu ser objetivo: você está olhando imóvel para morar, investir ou só acompanhando oportunidades?'],
        sem_resposta: ['Não insistir em excesso. Deixe uma última tentativa elegante e registre feedback se não houver contato.'],
      },
      whatsapp: {
        primeira_abordagem: [
          'Oi, {{nome}}. Sou {{corretor}}, da {{empresa}}. Tudo bem?\n\nEstou entrando em contato de forma bem objetiva para entender se imóvel ainda é um assunto aberto para você. Se fizer sentido, posso te mandar opções filtradas; se não fizer, eu pauso por aqui sem problema.',
          'Oi, {{nome}}. Aqui é {{corretor}}, da {{empresa}}.\n\nVi seu contato na nossa base comercial e queria confirmar se você está avaliando imóvel para morar, investir ou apenas acompanhando o mercado. Me responde com uma dessas opções que eu direciono sem te encher de mensagem.',
        ],
        pos_ligacao: ['Oi, {{nome}}. Falamos agora há pouco. Conforme combinado, deixo aqui um resumo objetivo para você avaliar no seu tempo. Se fizer sentido, sigo com opções mais aderentes ao seu perfil.'],
        fim_contato: ['{{nome}}, sem problema. Vou pausar o contato por aqui para não te incomodar. Se futuramente fizer sentido falar sobre imóvel, fico à disposição.'],
      },
      email: {
        primeira_abordagem: ['Assunto: {{nome}}, sobre seu interesse em imóveis\n\nOlá, {{nome}}. Sou {{corretor}}, da {{empresa}}. Estou entrando em contato para entender se a busca por imóvel ainda faz sentido para você. Posso te ajudar com uma seleção objetiva conforme perfil, região e momento de compra.'],
      },
    },
    visitou: {
      ligacao: {
        retorno: ['Oi, {{nome}}, tudo bem? Aqui é {{corretor}}, da {{empresa}}. Estou retomando seu atendimento depois da visita. O projeto ainda está no seu radar ou perdeu prioridade?'],
        objecao_preco: ['Entendo, {{nome}}. Só separaria preço de valor: caro é quando não faz sentido. O ponto que pesou mais foi valor total, entrada ou fluxo de pagamento?'],
        objecao_entrada: ['Esse ponto é comum. Então talvez o problema não seja o imóvel, mas a engenharia do fluxo. Posso avaliar uma composição com menor impacto inicial?'],
        convite: ['Como você já conhece o projeto, uma segunda visita pode ser mais estratégica: olhar unidade, fluxo e dúvidas finais. Faz sentido agendarmos?'],
      },
      whatsapp: {
        pos_ligacao: ['Oi, {{nome}}. Conforme nossa conversa, o próximo passo mais inteligente é validar uma simulação objetiva e tirar as últimas dúvidas. Assim você decide com segurança, sem pressão e sem achismo.'],
        objecao_preco: ['{{nome}}, entendo sua percepção sobre valor. Para analisarmos corretamente, vale separar valor total, entrada, parcelas e condição real. Às vezes o ajuste está mais no fluxo do que no imóvel.'],
        objecao_entrada: ['{{nome}}, como a entrada ficou pesada, faz sentido avaliarmos uma composição mais leve. Posso simular um fluxo com menor impacto inicial para você comparar com calma.'],
        convite: ['{{nome}}, podemos organizar uma nova visita mais focada nos pontos que ficaram em dúvida: planta, unidade, fluxo e condição. Qual melhor dia para você?'],
      },
      email: {
        retorno: ['Assunto: {{nome}}, continuidade da sua visita\n\nOlá, {{nome}}. Foi um prazer te receber. Estou retomando seu atendimento para entender se ficou alguma dúvida sobre planta, valor, fluxo de pagamento ou disponibilidade. Posso preparar uma simulação mais ajustada ao seu perfil.'],
      },
    },
    redes_sociais: {
      whatsapp: {
        primeira_abordagem: ['Oi, {{nome}}. Sou {{corretor}}, da {{empresa}}. Vi seu interesse pelo anúncio e queria te ajudar de forma objetiva: você busca mais informações de valores, plantas ou disponibilidade?'],
        retorno: ['{{nome}}, passando para retomar seu interesse pelo anúncio. Quer que eu te mande uma opção objetiva ou prefere que eu explique rapidamente por áudio/mensagem?'],
      },
      ligacao: { primeira_abordagem: ['Oi, {{nome}}, aqui é {{corretor}}, da {{empresa}}. Você demonstrou interesse pelo anúncio e eu queria entender se procura para morar, investir ou comparar oportunidades.'] },
    },
    problemas: {
      ligacao: {
        objecao_preco: ['Preço isolado engana. Vamos olhar valor por metro, fluxo, entrega, padrão e liquidez. O que realmente pesou na sua análise?'],
        objecao_entrada: ['Entrada pesada não significa negócio inviável. Pode ser caso de redesenhar o fluxo. Qual parcela inicial ficaria confortável para você avaliar?'],
      },
      whatsapp: {
        objecao_preco: ['Entendo o ponto do valor. Para comparar com justiça, precisamos olhar produto, localização, fluxo, entrega e valor final — não só o preço de chamada.'],
        objecao_entrada: ['Sobre entrada, dá para avaliar alternativas de composição. Me diga qual ponto apertou mais: sinal, parcelas curtas, intermediárias ou financiamento.'],
      },
    },
    argumentacoes: {
      ligacao: {
        primeira_abordagem: ['A melhor oportunidade não é só o menor valor. É a combinação entre unidade, andar, vaga, posição, fluxo e timing. O barato errado vira caro com vista bonita para o problema.'],
        objecao_preco: ['Às vezes existe preço bom com unidade ruim, vaga ruim ou fluxo ruim. O ponto é comparar o conjunto, não só o metro quadrado.'],
      },
      whatsapp: {
        primeira_abordagem: ['Um ponto importante: nem sempre o melhor valor é a melhor oportunidade. É preciso olhar unidade, andar, vaga, posição, fluxo e momento de tabela. É aí que uma escolha estratégica faz diferença.'],
      },
    },
  };

  const state = {
    context: safeGet('fechai_pme_context', 'lista_fria'),
    channel: safeGet('fechai_pme_channel', 'ligacao'),
    approach: safeGet('fechai_pme_approach', 'primeira_abordagem'),
    variant: Number(safeGet('fechai_pme_variant', '0')) || 0,
    aiText: '',
    aiStatus: 'idle',
    aiError: '',
    score: safeGet('fechai_pme_score', ''),
  };

  function safeGet(key, fallback) {
    try { return localStorage.getItem(key) || fallback; } catch (_) { return fallback; }
  }

  function safeSet(key, value) {
    try { localStorage.setItem(key, String(value)); } catch (_) {}
  }

  function saveState() {
    safeSet('fechai_pme_context', state.context);
    safeSet('fechai_pme_channel', state.channel);
    safeSet('fechai_pme_approach', state.approach);
    safeSet('fechai_pme_variant', state.variant);
    safeSet('fechai_pme_score', state.score);
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `
      #${ROOT_ID}{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#fff;border:1px solid #e5e7eb;border-radius:20px;padding:14px;box-shadow:0 10px 28px rgba(15,23,42,.08);margin:14px 0;max-width:100%;overflow:hidden;box-sizing:border-box;}
      #${ROOT_ID} *{box-sizing:border-box;}
      #${ROOT_ID} .pme-head{display:flex;justify-content:space-between;gap:10px;align-items:flex-start;margin-bottom:12px;}
      #${ROOT_ID} .pme-title{font-size:15px;font-weight:900;color:#111827;line-height:1.2;}
      #${ROOT_ID} .pme-sub{font-size:11px;color:#64748b;margin-top:3px;line-height:1.35;}
      #${ROOT_ID} .pme-chip{font-size:10px;font-weight:900;color:#1d4ed8;background:#eff6ff;border:1px solid #bfdbfe;padding:5px 8px;border-radius:999px;white-space:nowrap;}
      #${ROOT_ID} .pme-row{display:flex;gap:8px;overflow-x:auto;padding-bottom:3px;margin:8px 0;scrollbar-width:none;}
      #${ROOT_ID} .pme-row::-webkit-scrollbar{display:none;}
      #${ROOT_ID} .pme-pill{border:1px solid #dbeafe;background:#f8fafc;color:#334155;border-radius:999px;padding:9px 11px;font-size:12px;font-weight:900;white-space:nowrap;cursor:pointer;}
      #${ROOT_ID} .pme-pill.active{background:#2563eb;color:white;border-color:#2563eb;}
      #${ROOT_ID} .pme-select{width:100%;border:1px solid #d1d5db;border-radius:14px;padding:10px;font-size:13px;background:#fff;color:#111827;margin:8px 0;}
      #${ROOT_ID} .pme-box{background:#f8fafc;border:1px solid #e2e8f0;border-radius:16px;padding:12px;margin-top:10px;max-width:100%;overflow:hidden;}
      #${ROOT_ID} .pme-label{font-size:10px;color:#64748b;font-weight:900;text-transform:uppercase;letter-spacing:.04em;margin-bottom:6px;}
      #${ROOT_ID} .pme-text{font-size:14px;line-height:1.48;color:#111827;white-space:pre-line;overflow-wrap:anywhere;word-break:normal;}
      #${ROOT_ID} .pme-actions{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px;}
      #${ROOT_ID} button,#${ROOT_ID} a{border:0;border-radius:14px;padding:11px 10px;font-size:12px;font-weight:900;text-decoration:none;cursor:pointer;text-align:center;line-height:1.2;}
      #${ROOT_ID} .pme-primary{background:#2563eb;color:#fff;}
      #${ROOT_ID} .pme-green{background:#059669;color:#fff;}
      #${ROOT_ID} .pme-muted{background:#e5e7eb;color:#374151;}
      #${ROOT_ID} .pme-warn{background:#fff7ed;color:#9a3412;border:1px solid #fed7aa;}
      #${ROOT_ID} .pme-wide{grid-column:1/-1;}
      #${ROOT_ID} .pme-note{font-size:11px;color:#64748b;margin-top:8px;line-height:1.35;}
      #${ROOT_ID} .pme-score{display:flex;gap:6px;flex-wrap:wrap;margin-top:8px;}
      #${ROOT_ID} .pme-score button{width:34px;height:34px;padding:0;border-radius:999px;background:#f1f5f9;color:#334155;}
      #${ROOT_ID} .pme-score button.active{background:#0f172a;color:#fff;}
      #${MODAL_ID}{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:99999;display:none;align-items:end;justify-content:center;padding:12px;}
      #${MODAL_ID}.open{display:flex;}
      #${MODAL_ID} .pme-modal-card{background:#fff;border-radius:22px;padding:16px;width:100%;max-width:620px;max-height:86vh;overflow:auto;box-shadow:0 24px 70px rgba(15,23,42,.35);}
      #${MODAL_ID} textarea{width:100%;min-height:160px;border:1px solid #cbd5e1;border-radius:16px;padding:12px;font-size:14px;line-height:1.45;resize:vertical;}
      #${MODAL_ID} input{width:100%;border:1px solid #cbd5e1;border-radius:14px;padding:11px;font-size:13px;margin-top:8px;}
      #${MODAL_ID} .pme-modal-actions{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px;}
      @media(max-width:480px){#${ROOT_ID}{border-radius:16px;padding:12px;margin:12px 0;}#${ROOT_ID} .pme-head{flex-direction:column;}#${ROOT_ID} .pme-chip{white-space:normal;}#${ROOT_ID} .pme-actions{grid-template-columns:1fr;}#${MODAL_ID}{align-items:end;}#${MODAL_ID} .pme-modal-actions{grid-template-columns:1fr;}}
    `;
    document.head.appendChild(style);
  }

  function firstWord(text) { return String(text || '').trim().split(/\s+/)[0] || 'cliente'; }
  function getLeadName() {
    const tel = document.querySelector('a[href^="tel:"]');
    const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null;
    const title = card ? card.querySelector('h1,h2,h3,[class*="text-xl"],[class*="font-bold"]') : null;
    return title && title.textContent.trim() ? title.textContent.trim() : 'cliente';
  }
  function getPhoneE164() {
    const tel = document.querySelector('a[href^="tel:"]');
    return tel ? String(tel.getAttribute('href') || '').replace(/^tel:/, '').replace(/\s+/g, '') : '';
  }
  function getBairro() {
    const body = document.body.innerText || '';
    const match = body.match(/Bairro:\s*([^\n]+)/i) || body.match(/📍\s*([^\n]+)/i);
    return match && match[1] ? match[1].trim() : 'região';
  }
  function getCorretor() {
    const header = document.querySelector('header, [style*="position: sticky"]');
    const raw = header ? header.textContent.replace(/Gestor|Corretor|v\d+(\.\d+)*/g, '').trim() : '';
    const nome = raw.split(/\s{2,}|Sair|Início|Dashboard/)[0]?.trim();
    return nome || 'consultor';
  }
  function getEmpresa() { return 'Tegra Incorporadora'; }

  function renderTemplate(text) {
    const leadName = getLeadName();
    return String(text || '')
      .replaceAll('{{nome}}', firstWord(leadName))
      .replaceAll('{{nome_completo}}', leadName)
      .replaceAll('{{bairro}}', getBairro())
      .replaceAll('{{corretor}}', getCorretor())
      .replaceAll('{{empresa}}', getEmpresa());
  }

  function getTemplateList() {
    const byContext = TEMPLATES[state.context] || TEMPLATES.lista_fria;
    const byChannel = byContext[state.channel] || byContext.ligacao || byContext.whatsapp || {};
    return byChannel[state.approach] || byChannel.primeira_abordagem || ['Conduza a conversa com objetividade, valide interesse e registre o próximo passo.'];
  }

  function getCurrentText() {
    const list = getTemplateList();
    const index = Math.abs(state.variant) % Math.max(list.length, 1);
    return renderTemplate(list[index]);
  }

  function buildWhatsappUrl(text) {
    const phone = getPhoneE164().replace('+', '').replace(/\D/g, '');
    if (!phone) return '';
    return 'https://wa.me/' + phone + '?text=' + encodeURIComponent(text || getCurrentText());
  }

  async function copyText(text, btn) {
    try {
      await navigator.clipboard.writeText(text);
      flashButton(btn, 'Copiado ✓');
    } catch (_) {
      window.prompt('Copie o texto:', text);
    }
  }

  function flashButton(btn, label) {
    if (!btn) return;
    const old = btn.textContent;
    btn.textContent = label;
    setTimeout(() => { btn.textContent = old; }, 1400);
  }

  function hasDiscadorLead() {
    return !!document.querySelector('a[href^="tel:"]') && /Feedback/i.test(document.body.innerText || '');
  }

  function findMountPoint() {
    const feedbackLabel = Array.from(document.querySelectorAll('p,div,h2,h3')).find((el) => el.textContent && el.textContent.trim() === 'Feedback');
    if (feedbackLabel) {
      const feedbackBlock = feedbackLabel.closest('div');
      const parent = feedbackBlock && feedbackBlock.parentElement;
      if (parent) return { parent, before: feedbackBlock };
    }
    const tel = document.querySelector('a[href^="tel:"]');
    const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null;
    if (card && card.parentElement) return { parent: card.parentElement, before: card.nextSibling };
    return null;
  }

  function renderPills(items, active, attr) {
    return Object.entries(items).map(([key, item]) => {
      const label = typeof item === 'string' ? item : `${item.icon || ''} ${item.label}`;
      return `<button type="button" class="pme-pill ${key === active ? 'active' : ''}" data-pme-${attr}="${escapeHtml(key)}">${escapeHtml(label)}</button>`;
    }).join('');
  }

  function renderApproachSelect() {
    return `<select class="pme-select" data-pme="approach">${Object.entries(APPROACHES).map(([key, label]) => `<option value="${key}" ${key === state.approach ? 'selected' : ''}>${escapeHtml(label)}</option>`).join('')}</select>`;
  }

  function render() {
    ensureStyle();
    ensureModal();
    if (!hasDiscadorLead()) {
      const old = document.getElementById(ROOT_ID);
      if (old) old.remove();
      return;
    }
    const mount = findMountPoint();
    if (!mount) return;
    let root = document.getElementById(ROOT_ID);
    if (!root) {
      root = document.createElement('div');
      root.id = ROOT_ID;
      mount.parent.insertBefore(root, mount.before || null);
    } else if (root.parentElement !== mount.parent) {
      mount.parent.insertBefore(root, mount.before || null);
    }

    normalizeState();
    const text = getCurrentText();
    const waUrl = buildWhatsappUrl(text);
    const ctx = CONTEXTS[state.context];
    const channel = CHANNELS[state.channel];

    root.innerHTML = `
      <div class="pme-head">
        <div>
          <div class="pme-title">⚡ Discador Flow AI</div>
          <div class="pme-sub">Beta ${VERSION} · PME guiada para ligação, WhatsApp e e-mail</div>
        </div>
        <div class="pme-chip">${escapeHtml(ctx.label)} · ${escapeHtml(channel.label)}</div>
      </div>
      <div class="pme-label">1. Situação do lead</div>
      <div class="pme-row">${renderPills(CONTEXTS, state.context, 'context')}</div>
      <div class="pme-label">2. Canal</div>
      <div class="pme-row">${renderPills(CHANNELS, state.channel, 'channel')}</div>
      <div class="pme-label">3. Tipo de abordagem</div>
      ${renderApproachSelect()}
      <div class="pme-box">
        <div class="pme-label">Sugestão pronta para usar</div>
        <div class="pme-text">${escapeHtml(text)}</div>
      </div>
      <div class="pme-actions">
        <button class="pme-primary" data-pme-action="open-modal">Abrir / editar</button>
        <button class="pme-muted" data-pme-action="next">Trocar opção</button>
        <button class="pme-muted" data-pme-action="copy">Copiar texto</button>
        ${state.channel === 'whatsapp' && waUrl ? `<a class="pme-green" target="_blank" rel="noopener noreferrer" href="${waUrl}">Abrir WhatsApp</a>` : ''}
        ${state.channel === 'ligacao' ? '<button class="pme-green" data-pme-action="copy-call">Copiar fala</button>' : ''}
        ${state.channel === 'email' ? '<button class="pme-green" data-pme-action="copy-email">Copiar e-mail</button>' : ''}
        <button class="pme-warn pme-wide" data-pme-action="ai">Melhorar com IA</button>
      </div>
      <div class="pme-box">
        <div class="pme-label">Score da utilidade do script</div>
        <div class="pme-score">${[0,1,2,3,4,5].map((n) => `<button type="button" class="${String(n) === String(state.score) ? 'active' : ''}" data-pme-score="${n}">${n}</button>`).join('')}</div>
      </div>
      <div class="pme-note">${escapeHtml(ctx.hint)} A PME não envia mensagem sozinha e não registra feedback automaticamente.</div>
    `;

    bindRoot(root);
  }

  function normalizeState() {
    if (!CONTEXTS[state.context]) state.context = 'lista_fria';
    if (!CHANNELS[state.channel]) state.channel = 'ligacao';
    if (!APPROACHES[state.approach]) state.approach = 'primeira_abordagem';
    saveState();
  }

  function bindRoot(root) {
    root.querySelectorAll('[data-pme-context]').forEach((btn) => btn.addEventListener('click', () => {
      state.context = btn.getAttribute('data-pme-context');
      state.variant = 0;
      saveState();
      render();
    }));
    root.querySelectorAll('[data-pme-channel]').forEach((btn) => btn.addEventListener('click', () => {
      state.channel = btn.getAttribute('data-pme-channel');
      state.variant = 0;
      saveState();
      render();
    }));
    const approach = root.querySelector('[data-pme="approach"]');
    if (approach) approach.addEventListener('change', (e) => { state.approach = e.target.value; state.variant = 0; saveState(); render(); });
    root.querySelector('[data-pme-action="next"]')?.addEventListener('click', () => { state.variant += 1; saveState(); render(); });
    root.querySelector('[data-pme-action="copy"]')?.addEventListener('click', (e) => copyText(getCurrentText(), e.currentTarget));
    root.querySelector('[data-pme-action="copy-call"]')?.addEventListener('click', (e) => copyText(getCurrentText(), e.currentTarget));
    root.querySelector('[data-pme-action="copy-email"]')?.addEventListener('click', (e) => copyText(getCurrentText(), e.currentTarget));
    root.querySelector('[data-pme-action="open-modal"]')?.addEventListener('click', () => openModal(getCurrentText()));
    root.querySelector('[data-pme-action="ai"]')?.addEventListener('click', () => openModal(getCurrentText(), true));
    root.querySelectorAll('[data-pme-score]').forEach((btn) => btn.addEventListener('click', () => { state.score = btn.getAttribute('data-pme-score'); saveState(); render(); }));
  }

  function ensureModal() {
    if (document.getElementById(MODAL_ID)) return;
    const modal = document.createElement('div');
    modal.id = MODAL_ID;
    modal.innerHTML = `
      <div class="pme-modal-card">
        <div class="pme-head">
          <div>
            <div class="pme-title">Editar mensagem / script</div>
            <div class="pme-sub">Você pode ajustar manualmente ou pedir uma melhoria para IA.</div>
          </div>
          <button class="pme-muted" data-modal-action="close">Fechar</button>
        </div>
        <textarea data-modal="text"></textarea>
        <input data-modal="tip" placeholder="Dica para IA: ex. cliente achou caro, quer entrada menor, já visitou..." />
        <div class="pme-note" data-modal="status"></div>
        <div class="pme-modal-actions">
          <button class="pme-primary" data-modal-action="copy">Copiar</button>
          <button class="pme-warn" data-modal-action="ai">Melhorar com IA</button>
          <button class="pme-muted" data-modal-action="retry">Tentar novamente</button>
          <a class="pme-green" data-modal-action="whatsapp" target="_blank" rel="noopener noreferrer" href="#">Abrir WhatsApp</a>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
    modal.addEventListener('click', (e) => { if (e.target === modal) closeModal(); });
    modal.querySelector('[data-modal-action="close"]').addEventListener('click', closeModal);
    modal.querySelector('[data-modal-action="copy"]').addEventListener('click', (e) => copyText(modal.querySelector('[data-modal="text"]').value, e.currentTarget));
    modal.querySelector('[data-modal-action="ai"]').addEventListener('click', () => improveModalText(false));
    modal.querySelector('[data-modal-action="retry"]').addEventListener('click', () => improveModalText(true));
  }

  function openModal(text, runAi) {
    const modal = document.getElementById(MODAL_ID);
    if (!modal) return;
    modal.querySelector('[data-modal="text"]').value = text || getCurrentText();
    modal.querySelector('[data-modal="tip"]').value = '';
    setModalStatus('Pronto para uso. Nada será enviado automaticamente.');
    updateModalWhatsapp();
    modal.classList.add('open');
    if (runAi) improveModalText(false);
  }

  function closeModal() { document.getElementById(MODAL_ID)?.classList.remove('open'); }
  function setModalStatus(text) { const el = document.querySelector(`#${MODAL_ID} [data-modal="status"]`); if (el) el.textContent = text || ''; }
  function updateModalWhatsapp() {
    const modal = document.getElementById(MODAL_ID);
    if (!modal) return;
    const link = modal.querySelector('[data-modal-action="whatsapp"]');
    const text = modal.querySelector('[data-modal="text"]').value;
    const url = buildWhatsappUrl(text);
    if (url) {
      link.href = url;
      link.style.display = state.channel === 'whatsapp' ? 'block' : 'none';
    } else {
      link.href = '#';
      link.style.display = 'none';
    }
  }

  function getSupabaseAccessToken() {
    try {
      for (let i = 0; i < localStorage.length; i += 1) {
        const key = localStorage.key(i);
        if (!key || !key.includes('auth-token')) continue;
        const raw = localStorage.getItem(key);
        if (!raw) continue;
        const parsed = JSON.parse(raw);
        const token = parsed?.access_token || parsed?.currentSession?.access_token;
        if (token) return token;
      }
    } catch (_) {}
    return '';
  }

  async function improveModalText(forceRetry) {
    const modal = document.getElementById(MODAL_ID);
    if (!modal) return;
    const textarea = modal.querySelector('[data-modal="text"]');
    const tip = modal.querySelector('[data-modal="tip"]').value.trim();
    const token = getSupabaseAccessToken();
    if (!token) {
      setModalStatus('IA indisponível: sessão expirada ou token não encontrado. Faça login novamente e use o texto base por enquanto.');
      return;
    }
    setModalStatus(forceRetry ? 'Tentando nova versão com IA...' : 'Melhorando com IA...');
    try {
      const prompt = buildAiPrompt(textarea.value, tip, forceRetry);
      const res = await fetch(`${SUPABASE_URL}/functions/v1/assistente-ai`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          messages: [{ role: 'user', content: prompt }],
          context: {
            module: 'discador_flow_ai',
            version: VERSION,
            situacao: state.context,
            canal: state.channel,
            abordagem: state.approach,
          },
        }),
      });
      const data = await safeJson(res);
      if (!res.ok) {
        const msg = data?.error || data?.message || `Erro ${res.status}`;
        throw new Error(msg);
      }
      const improved = extractAiText(data);
      if (!improved) throw new Error('A IA não retornou texto utilizável.');
      textarea.value = improved;
      setModalStatus('IA gerou uma versão. Revise antes de copiar ou abrir WhatsApp.');
      updateModalWhatsapp();
    } catch (err) {
      setModalStatus(`IA indisponível: ${err.message || 'falha não identificada'}. Use o texto base e registre o feedback normalmente.`);
    }
  }

  function buildAiPrompt(baseText, tip, forceRetry) {
    return [
      'Você é o copiloto comercial do FECH.AI para corretores imobiliários.',
      'Melhore o texto abaixo mantendo tom humano, direto, elegante e comercial.',
      'Não invente preço, desconto, unidade, condição, prazo, disponibilidade ou promessa.',
      'Não diga que enviou algo automaticamente. O corretor sempre revisa antes.',
      `Situação do lead: ${CONTEXTS[state.context]?.label || state.context}.`,
      `Canal: ${CHANNELS[state.channel]?.label || state.channel}.`,
      `Abordagem: ${APPROACHES[state.approach] || state.approach}.`,
      tip ? `Dica do corretor: ${tip}.` : 'Sem dica adicional do corretor.',
      forceRetry ? 'Gere uma versão diferente da anterior.' : 'Gere uma versão melhorada.',
      'Texto base:',
      baseText,
      'Retorne somente o texto final, sem explicações.',
    ].join('\n');
  }

  async function safeJson(res) { try { return await res.json(); } catch (_) { return null; } }
  function extractAiText(data) {
    if (!data) return '';
    if (typeof data === 'string') return data.trim();
    return String(
      data.text ||
      data.content ||
      data.message ||
      data.answer ||
      data.output_text ||
      data?.choices?.[0]?.message?.content ||
      data?.choices?.[0]?.text ||
      ''
    ).trim();
  }

  function escapeHtml(text) {
    return String(text || '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  function debounce(fn, wait) {
    let t;
    return function () { clearTimeout(t); t = setTimeout(fn, wait); };
  }

  const debouncedRender = debounce(render, 250);

  window.FECHAI_PME_CALL_ASSISTANT = { version: VERSION, render, data: { CONTEXTS, CHANNELS, APPROACHES, TEMPLATES } };

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', render);
  else render();

  const observer = new MutationObserver(debouncedRender);
  observer.observe(document.body, { childList: true, subtree: true });
})();
