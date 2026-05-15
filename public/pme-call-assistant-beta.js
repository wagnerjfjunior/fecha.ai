/*
 * FECH.AI — PME Call Assistant Beta
 * Version: 0.1.0
 * Purpose: ativar scripts de ligação da Power Message Engine no Discador sem alterar o motor React/App.jsx.
 * Safety: sem envio automático, sem gravação no Supabase, sem service role, sem alteração de feedback.
 */
(function () {
  'use strict';

  const VERSION = '0.1.0';
  const ROOT_ID = 'fechai-pme-call-assistant';
  const STYLE_ID = 'fechai-pme-call-assistant-style';

  const DATA = {
    lista_fria: {
      label: 'Lista Fria',
      badge: '🧊',
      escapes: {
        pode_mandar_whatsapp: {
          label: 'Pode mandar no WhatsApp',
          feedback: 'enviado_informacoes',
          voice: [
            'Te mando sim, {{nome}}. Só para eu ser objetivo e não te enviar coisa solta: você quer receber algo sobre valores, plantas ou opções na região do {{bairro}}?',
            'Claro. Antes de eu te mandar, só me confirma uma coisa: você está olhando imóvel mais para morar, investir ou só pesquisando por enquanto?',
            'Combinado. Eu te mando uma mensagem curta no WhatsApp. Para eu não errar no conteúdo, faz sentido falar de apartamento no {{bairro}} ou sua busca está em outra região?',
            'Perfeito, te mando sim. Você prefere que eu envie um resumo bem direto ou quer que eu mande uma opção específica para você avaliar?',
            'Claro, {{nome}}. Só para eu respeitar seu tempo: você quer que eu mande agora e você vê depois, ou prefere que eu retorne em outro horário para explicar melhor?',
            'Te mando. E para ser bem objetivo: hoje você quer entender oportunidade, valor de referência ou só acompanhar o mercado da região?',
            'Sem problema, mando pelo WhatsApp. Só me ajuda com uma direção: você busca algo para curto prazo ou é uma pesquisa mais para frente?',
            'Claro. Eu te envio algo bem resumido. Se depois fizer sentido, seguimos a conversa; se não fizer, você me avisa e eu pauso por aqui.',
            'Te envio sim. Só para eu não te mandar material fora do seu perfil: você tem alguma metragem ou faixa de valor em mente, ou prefere primeiro ver um resumo da região?',
            'Combinado. Eu mando uma mensagem objetiva no WhatsApp e deixo você à vontade. Posso te enviar com foco em moradia, investimento ou comparação de opções?'
          ],
          whatsapp: [
            'Oi, {{nome}}. Sou {{corretor}}, da {{empresa}}.\n\nFalamos agora há pouco por telefone. Estou te enviando um resumo objetivo sobre opções de imóveis na região do {{bairro}}.\n\nDá uma olhada no seu tempo. Se fizer sentido para o seu momento, me chama por aqui que eu te explico melhor.',
            'Oi, {{nome}}, aqui é {{corretor}}, da {{empresa}}.\n\nConforme combinamos, estou deixando aqui as informações para você avaliar com calma.\n\nDepois, se quiser, posso te ajudar a comparar valores, plantas e formas de pagamento sem pressa.'
          ]
        },
        estou_sem_tempo: {
          label: 'Estou sem tempo',
          feedback: 'retornar_depois',
          voice: [
            'Perfeito, {{nome}}, eu vou ser bem breve: é só para entender se faz sentido te retornar em outro horário ou se posso te mandar um resumo objetivo agora.',
            'Tranquilo. Em dez segundos: você está pesquisando para morar, investir ou só acompanhando o mercado? Assim eu não te incomodo com coisa fora do seu momento.',
            'Sem problema. Para eu respeitar seu tempo, me diga só uma coisa: posso te chamar mais tarde ou prefere receber um resumo curto no WhatsApp?',
            'Claro, entendo. Então faço diferente: eu te mando algo bem objetivo e, se fizer sentido, você me responde no melhor horário.',
            'Perfeito. Antes de desligar, só para eu não te perder no vazio: qual horário costuma ser melhor para eu te retornar?',
            'Tudo bem, {{nome}}. Eu não quero tomar seu tempo. Só confirma se a busca é para agora ou mais para frente, e eu ajusto meu contato.',
            'Combinado. Vou ser elegante e rápido: posso deixar registrado para retornar depois, ou você prefere que eu mande o resumo e pare por aqui?',
            'Sem problema. Eu trabalho com retorno organizado, não com insistência. Qual melhor período para eu te procurar: manhã, tarde ou noite?',
            'Entendi. Vou respeitar. Só me ajuda com uma direção: sua busca é por {{bairro}} mesmo ou essa região não faz sentido?',
            'Claro. Vou encerrar por aqui. Posso te mandar uma mensagem curta para você me responder quando tiver dois minutos?'
          ],
          whatsapp: [
            'Oi, {{nome}}. Aqui é {{corretor}}, da {{empresa}}.\n\nVocê estava sem tempo quando falei com você, então vou deixar uma mensagem curta por aqui.\n\nQuando puder, me diga se faz sentido falarmos sobre opções na região do {{bairro}} ou se prefere que eu pause o contato.',
            'Oi, {{nome}}. Prometi ser breve e vou cumprir.\n\nQuando tiver um momento, me responde só com uma destas opções: morar, investir, pesquisar ou pausar. Assim eu te direciono sem ficar insistindo.'
          ]
        }
      }
    },
    visitou_plantao: {
      label: 'Visitou Plantão',
      badge: '🔥',
      escapes: {
        achei_caro: {
          label: 'Achei caro',
          feedback: 'retornar_depois',
          voice: [
            'Eu entendo, {{nome}}. Só separaria preço de valor: caro é quando não faz sentido. Posso te mostrar onde está o peso real da proposta?',
            'Faz sentido você sentir isso de primeira. Normalmente o ponto não é só o preço, é o fluxo. Quer que eu veja uma composição mais confortável?',
            'Perfeito. Me deixa olhar com você sem compromisso: às vezes o incômodo está na entrada, não no valor total.'
          ],
          whatsapp: ['{{nome}}, entendo sua percepção sobre valor. Vou te mandar uma visão mais objetiva do fluxo para separarmos preço, entrada e condição real. Às vezes o ajuste está mais na forma de pagamento do que no imóvel em si.']
        },
        falar_com_familia: {
          label: 'Vou falar com família',
          feedback: 'retornar_depois',
          voice: [
            'Claro, decisão de imóvel precisa alinhar a família. Quer que eu te mande um resumo simples para você não ter que explicar tudo de cabeça?',
            'Perfeito. Para a conversa em casa ficar mais fácil, eu posso te mandar os pontos principais: valor, planta e condição.',
            'Ótimo. Só me diga quem mais participa da decisão para eu te ajudar com os argumentos certos.'
          ],
          whatsapp: ['{{nome}}, como você comentou que vai conversar com a família, deixo aqui um resumo objetivo para facilitar: planta, condição e próximos passos. Se quiser, eu também posso montar uma simulação mais didática para vocês avaliarem juntos.']
        },
        comparando_outro: {
          label: 'Estou comparando com outro projeto',
          feedback: 'retornar_depois',
          voice: [
            'Ótimo, comparar é saudável. O cuidado é comparar coisa equivalente: metragem, entrega, fluxo, localização e padrão. Quer que eu te ajude a montar essa comparação?',
            'Perfeito. Só não compara só pelo valor de chamada, porque às vezes a diferença aparece no fluxo e no produto entregue.',
            'Faz todo sentido. Posso te ajudar a comparar com critério para não virar aquela planilha que parece um labirinto com ar-condicionado.'
          ],
          whatsapp: ['{{nome}}, para comparar bem, o ideal é olhar localização, metragem, padrão, prazo de entrega, fluxo e valor final. Se você me passar o outro projeto, te ajudo a comparar de forma limpa e sem pressão.']
        },
        nao_momento: {
          label: 'Gostei, mas não é o momento',
          feedback: 'retornar_depois',
          voice: [
            'Entendo. Só preciso separar uma coisa: não é o momento financeiro, familiar ou de decisão? Cada caso pede um caminho diferente.',
            'Perfeito. Se você gostou do projeto, talvez o papel agora seja acompanhar condição e timing, não forçar decisão.',
            'Claro. Quer que eu deixe você em acompanhamento e te avise só se surgir uma condição realmente relevante?'
          ],
          whatsapp: ['{{nome}}, como você gostou mas sente que talvez não seja o momento, posso acompanhar por aqui de forma leve. Se surgir uma condição ou unidade que realmente valha análise, eu te aviso sem ficar insistindo.']
        },
        preciso_pensar: {
          label: 'Preciso pensar',
          feedback: 'retornar_depois',
          voice: [
            'Justo. Só cuidado para o “pensar” não virar dúvida sem resposta. O que ficou mais pesado para você: valor, planta, prazo ou segurança da decisão?',
            'Claro. Pensar é importante. Meu papel é só organizar os pontos para você pensar com clareza, não no escuro.',
            'Perfeito. Me fala qual ponto você quer amadurecer e eu te mando uma análise objetiva.'
          ],
          whatsapp: ['{{nome}}, para te ajudar a pensar com clareza, me diga qual ponto ficou mais sensível: valor, entrada, planta, localização ou momento de compra. Assim eu respondo com precisão, sem te mandar material genérico.']
        },
        condicao_melhor: {
          label: 'Quero uma condição melhor',
          feedback: 'retornar_depois',
          voice: [
            'Perfeito, dá para trabalhar condição, mas com critério. O que você precisa melhorar: entrada, mensais, intermediárias ou valor final?',
            'Entendi. Para buscar uma condição melhor, preciso saber onde o fluxo apertou. Assim a negociação fica real, não chute.',
            'Claro. Se fizer sentido, eu levanto uma alternativa com foco no ponto que mais pesou para você.'
          ],
          whatsapp: ['{{nome}}, para tentarmos uma condição melhor de forma séria, preciso entender onde pesou mais: entrada, parcelas mensais, intermediárias ou valor final. Com isso eu consigo direcionar melhor a análise.']
        },
        nao_gostei_planta: {
          label: 'Não gostei da planta',
          feedback: 'retornar_depois',
          voice: [
            'Entendo. Foi distribuição, tamanho dos ambientes ou posição da unidade? Às vezes outra final resolve melhor que trocar de projeto.',
            'Perfeito. Planta é pessoal mesmo. Posso ver uma opção com layout mais adequado ao seu uso.',
            'Faz sentido. Me fala o que incomodou e eu filtro melhor, porque mandar mais do mesmo é perda de tempo para nós dois.'
          ],
          whatsapp: ['{{nome}}, sobre a planta, me diga o que não encaixou: distribuição, metragem, varanda, dormitórios ou posição da unidade. Com isso eu consigo filtrar uma opção mais próxima do que você busca.']
        },
        entrada_pesada: {
          label: 'A entrada ficou pesada',
          feedback: 'retornar_depois',
          voice: [
            'Esse é um ponto bem comum. Então a questão não é necessariamente o imóvel, é a engenharia do fluxo. Posso simular uma composição mais leve?',
            'Entendi. Vamos olhar entrada separada do valor total. Às vezes redistribuir o fluxo muda completamente a leitura.',
            'Perfeito. Se a entrada ficou pesada, eu vejo uma alternativa com menor impacto inicial para você avaliar.'
          ],
          whatsapp: ['{{nome}}, como a entrada ficou pesada, faz sentido analisarmos o fluxo e não só o preço. Posso simular uma composição com menor impacto inicial para você comparar com calma.']
        },
        mandar_whatsapp: {
          label: 'Me manda por WhatsApp',
          feedback: 'enviado_informacoes',
          voice: [
            'Mando sim. Para eu não te mandar um pacote genérico, quer que eu envie foco em valores, planta ou condição?',
            'Claro. Eu te mando de forma objetiva. Só confirma: o ponto principal agora é valor, fluxo ou comparar com outra opção?',
            'Perfeito. Eu mando pelo WhatsApp e deixo você à vontade. Depois, se fizer sentido, eu explico em dois minutos.'
          ],
          whatsapp: ['Oi, {{nome}}. Conforme combinamos, deixo aqui um resumo objetivo para você avaliar no seu tempo. Se fizer sentido, me chama por aqui que eu te explico valor, planta e condição sem complicar.']
        },
        visitar_de_novo: {
          label: 'Quero visitar de novo',
          feedback: 'agendado_visita',
          voice: [
            'Ótimo, revisitar costuma ajudar muito na decisão. Quer olhar com foco em planta, condição ou comparação com outra opção?',
            'Perfeito. A segunda visita é mais estratégica: vamos olhar os pontos que ficaram em dúvida e sair com clareza.',
            'Excelente. Me diga melhor dia e horário, e eu organizo para você ser atendido com calma.'
          ],
          whatsapp: ['{{nome}}, excelente. Vamos organizar sua nova visita com foco nos pontos que ficaram em dúvida. Me diga o melhor dia e horário para eu verificar a agenda.']
        },
        fechamento_elegante: {
          label: 'Fechamento elegante',
          feedback: 'retornar_depois',
          voice: [
            'Pelo que você me trouxe, o próximo passo mais inteligente não é decidir no impulso; é validar a condição certa e tirar as últimas dúvidas.',
            'Se o projeto fez sentido, eu sugiro fazermos uma simulação bem objetiva e você decide com segurança, não no achismo.',
            'Meu papel aqui é simples: te dar clareza. Se fizer sentido, avançamos; se não fizer, encerramos com respeito e você fica bem orientado.'
          ],
          whatsapp: ['{{nome}}, pelo que conversamos, o próximo passo mais inteligente é validar uma simulação objetiva e tirar as últimas dúvidas. Assim você decide com segurança, sem pressão e sem achismo.']
        }
      }
    }
  };

  const state = {
    context: localStorage.getItem('fechai_pme_context') || 'lista_fria',
    escape: localStorage.getItem('fechai_pme_escape') || 'pode_mandar_whatsapp',
    variant: Number(localStorage.getItem('fechai_pme_variant') || 0)
  };

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `
      #${ROOT_ID}{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#fff;border:1px solid #e5e7eb;border-radius:18px;padding:14px;box-shadow:0 10px 28px rgba(15,23,42,.08);margin:14px 0;}
      #${ROOT_ID} .pme-head{display:flex;justify-content:space-between;gap:10px;align-items:flex-start;margin-bottom:10px;}
      #${ROOT_ID} .pme-title{font-size:15px;font-weight:800;color:#111827;line-height:1.2;}
      #${ROOT_ID} .pme-sub{font-size:11px;color:#6b7280;margin-top:2px;}
      #${ROOT_ID} .pme-chip{font-size:10px;font-weight:800;color:#1d4ed8;background:#eff6ff;border:1px solid #bfdbfe;padding:4px 8px;border-radius:999px;white-space:nowrap;}
      #${ROOT_ID} .pme-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:8px 0 10px;}
      #${ROOT_ID} select{width:100%;border:1px solid #d1d5db;border-radius:12px;padding:9px 10px;font-size:13px;background:#fff;color:#111827;}
      #${ROOT_ID} .pme-box{background:#f8fafc;border:1px solid #e2e8f0;border-radius:14px;padding:12px;margin-top:10px;}
      #${ROOT_ID} .pme-label{font-size:10px;color:#64748b;font-weight:800;text-transform:uppercase;letter-spacing:.04em;margin-bottom:6px;}
      #${ROOT_ID} .pme-text{font-size:15px;line-height:1.45;color:#111827;white-space:pre-line;}
      #${ROOT_ID} .pme-actions{display:flex;gap:8px;margin-top:10px;flex-wrap:wrap;}
      #${ROOT_ID} button,#${ROOT_ID} a{border:0;border-radius:12px;padding:10px 12px;font-size:13px;font-weight:800;text-decoration:none;cursor:pointer;text-align:center;}
      #${ROOT_ID} .pme-primary{background:#2563eb;color:#fff;}
      #${ROOT_ID} .pme-green{background:#059669;color:#fff;}
      #${ROOT_ID} .pme-muted{background:#e5e7eb;color:#374151;}
      #${ROOT_ID} .pme-note{font-size:11px;color:#64748b;margin-top:8px;line-height:1.35;}
      @media(max-width:640px){#${ROOT_ID}{border-radius:16px;padding:12px;}#${ROOT_ID} .pme-grid{grid-template-columns:1fr;}#${ROOT_ID} .pme-actions{display:grid;grid-template-columns:1fr 1fr;}#${ROOT_ID} .pme-actions .pme-wide{grid-column:1/-1;}}
    `;
    document.head.appendChild(style);
  }

  function firstWord(text) {
    return String(text || '').trim().split(/\s+/)[0] || 'você';
  }

  function getLeadName() {
    const tel = document.querySelector('a[href^="tel:"]');
    const card = tel ? tel.closest('.bg-white') : null;
    const h2 = card ? card.querySelector('h2') : null;
    return h2 && h2.textContent.trim() ? h2.textContent.trim() : 'cliente';
  }

  function getPhoneE164() {
    const tel = document.querySelector('a[href^="tel:"]');
    if (!tel) return '';
    return String(tel.getAttribute('href') || '').replace(/^tel:/, '').replace(/\s+/g, '');
  }

  function getBairro() {
    const body = document.body.innerText || '';
    const match = body.match(/Bairro:\s*([^\n]+)/i);
    if (match && match[1]) return match[1].trim();
    const zona = body.match(/📍\s*([^\n]+)/i);
    if (zona && zona[1]) return zona[1].trim();
    return 'região';
  }

  function getCorretor() {
    const header = document.querySelector('header, [style*="position: sticky"]');
    const raw = header ? header.textContent.replace(/Gestor|Corretor|v\d+(\.\d+)*/g, '').trim() : '';
    const nome = raw.split(/\s{2,}|Sair|Início/)[0]?.trim();
    return nome || 'consultor';
  }

  function currentPack() {
    const ctx = DATA[state.context] ? state.context : 'lista_fria';
    const escapes = DATA[ctx].escapes;
    const esc = escapes[state.escape] ? state.escape : Object.keys(escapes)[0];
    state.context = ctx;
    state.escape = esc;
    return { ctx, esc, pack: escapes[esc] };
  }

  function renderTemplate(text) {
    const leadName = getLeadName();
    return String(text || '')
      .replaceAll('{{nome}}', firstWord(leadName))
      .replaceAll('{{nome_completo}}', leadName)
      .replaceAll('{{bairro}}', getBairro())
      .replaceAll('{{corretor}}', getCorretor())
      .replaceAll('{{empresa}}', 'Tegra Incorporadora');
  }

  function getVoiceText() {
    const { pack } = currentPack();
    const list = pack.voice || [];
    const index = Math.abs(state.variant) % Math.max(list.length, 1);
    return renderTemplate(list[index] || 'Conduza a conversa com objetividade e registre o próximo passo.');
  }

  function getWhatsText() {
    const { pack } = currentPack();
    const list = pack.whatsapp || [];
    const index = Math.abs(state.variant) % Math.max(list.length, 1);
    return renderTemplate(list[index] || getVoiceText());
  }

  function saveState() {
    localStorage.setItem('fechai_pme_context', state.context);
    localStorage.setItem('fechai_pme_escape', state.escape);
    localStorage.setItem('fechai_pme_variant', String(state.variant));
  }

  async function copyText(text, btn) {
    try {
      await navigator.clipboard.writeText(text);
      const old = btn.textContent;
      btn.textContent = 'Copiado ✓';
      setTimeout(() => { btn.textContent = old; }, 1200);
    } catch (e) {
      window.prompt('Copie o texto:', text);
    }
  }

  function buildWhatsappUrl() {
    const phone = getPhoneE164().replace('+', '').replace(/\D/g, '');
    if (!phone) return '';
    return 'https://wa.me/' + phone + '?text=' + encodeURIComponent(getWhatsText());
  }

  function optionsHtml(obj, selected) {
    return Object.entries(obj).map(([id, item]) => `<option value="${id}" ${id === selected ? 'selected' : ''}>${item.badge ? item.badge + ' ' : ''}${item.label}</option>`).join('');
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
    const card = tel ? tel.closest('.bg-white') : null;
    if (card && card.parentElement) return { parent: card.parentElement, before: card.nextSibling };
    return null;
  }

  function render() {
    ensureStyle();
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

    const { ctx, pack } = currentPack();
    const ctxData = DATA[ctx];
    const voiceText = getVoiceText();
    const whatsText = getWhatsText();
    const waUrl = buildWhatsappUrl();

    root.innerHTML = `
      <div class="pme-head">
        <div>
          <div class="pme-title">⚡ PME — Script de Ligação</div>
          <div class="pme-sub">Beta ${VERSION} · fala curta para o corretor não travar na ligação</div>
        </div>
        <div class="pme-chip">Feedback sugerido: ${pack.feedback || 'avaliar'}</div>
      </div>
      <div class="pme-grid">
        <select data-pme="context">${optionsHtml(DATA, state.context)}</select>
        <select data-pme="escape">${optionsHtml(ctxData.escapes, state.escape)}</select>
      </div>
      <div class="pme-box">
        <div class="pme-label">Fala sugerida — voz</div>
        <div class="pme-text" data-pme-text="voice">${escapeHtml(voiceText)}</div>
      </div>
      <div class="pme-actions">
        <button class="pme-primary" data-pme-action="copy-voice">Copiar fala</button>
        <button class="pme-muted" data-pme-action="next">Trocar opção</button>
        <button class="pme-muted" data-pme-action="copy-wpp">Copiar WhatsApp</button>
        ${waUrl ? `<a class="pme-green pme-wide" target="_blank" rel="noopener noreferrer" href="${waUrl}">Abrir WhatsApp</a>` : '<button class="pme-muted pme-wide" disabled>Sem telefone para WhatsApp</button>'}
      </div>
      <div class="pme-note">Não registra feedback sozinho. Depois da ligação, o corretor ainda deve clicar no feedback correto do FECH.AI.</div>
    `;

    root.querySelector('[data-pme="context"]').addEventListener('change', (e) => {
      state.context = e.target.value;
      state.escape = Object.keys(DATA[state.context].escapes)[0];
      state.variant = 0;
      saveState();
      render();
    });

    root.querySelector('[data-pme="escape"]').addEventListener('change', (e) => {
      state.escape = e.target.value;
      state.variant = 0;
      saveState();
      render();
    });

    root.querySelector('[data-pme-action="copy-voice"]').addEventListener('click', (e) => copyText(getVoiceText(), e.currentTarget));
    root.querySelector('[data-pme-action="copy-wpp"]').addEventListener('click', (e) => copyText(getWhatsText(), e.currentTarget));
    root.querySelector('[data-pme-action="next"]').addEventListener('click', () => {
      state.variant += 1;
      saveState();
      render();
    });
  }

  function escapeHtml(text) {
    return String(text || '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  const debouncedRender = debounce(render, 250);

  function debounce(fn, wait) {
    let t;
    return function () {
      clearTimeout(t);
      t = setTimeout(fn, wait);
    };
  }

  window.FECHAI_PME_CALL_ASSISTANT = {
    version: VERSION,
    render,
    data: DATA
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', render);
  } else {
    render();
  }

  const observer = new MutationObserver(debouncedRender);
  observer.observe(document.body, { childList: true, subtree: true });
})();
