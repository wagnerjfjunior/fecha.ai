/*
 * FECH.AI — Discador Flow AI / PME Beta
 * Version: 0.2.3
 * Purpose: fluxo assistido do corretor no discador, mobile-first, com fallback manual e IA opcional.
 * Safety: sem envio automático, sem alteração de feedback/RPC/RLS, sem service_role, sem segredo sensível no frontend.
 */
(function () {
  'use strict';

  const VERSION = '0.2.3';
  const ROOT_ID = 'fechai-pme-call-assistant';
  const TOP_ID = 'fechai-pme-page-title';
  const STYLE_ID = 'fechai-pme-call-assistant-style';
  const MODAL_ID = 'fechai-pme-flow-modal';
  const SUPABASE_URL = 'https://uobxxgzshrmbtjfdolxd.supabase.co';

  let suspendAutoRenderUntil = 0;

  const CONTEXTS = {
    carteira: { label: 'Carteira', icon: '📒', hint: 'Lead inserido ou acompanhado pelo próprio corretor. Use abordagem mais consultiva e com histórico.' },
    lista_fria: { label: 'Lista fria', icon: '🧊', hint: 'Lead frio precisa de permissão, triagem e saída elegante.' },
    visitou: { label: 'Já visitou', icon: '🔥', hint: 'Lead de fundo de funil. Foque em objeção, fluxo e próximo passo.' },
    redes_sociais: { label: 'Redes Sociais', icon: '📲', hint: 'Lead inbound/social precisa de velocidade e contexto.' },
    problemas: { label: 'Problemas', icon: '⚠️', hint: 'Use para objeções, travas e situações delicadas.' },
    argumentacoes: { label: 'Argumentações', icon: '💬', hint: 'Banco rápido de argumentos para sustentar a conversa.' },
  };

  const CHANNELS = {
    ligacao: { label: 'Ligação', icon: '📞', powerKey: 'power_dial', powerLabel: 'Power Dial' },
    whatsapp: { label: 'WhatsApp', icon: '💬', powerKey: 'power_zap', powerLabel: 'Power Zap' },
    email: { label: 'E-mail', icon: '✉️', powerKey: 'power_mail', powerLabel: 'Power Mail' },
  };

  const APPROACHES = {
    primeira_abordagem: 'Primeira abordagem',
    retorno: 'Retorno',
    pos_ligacao: 'Pós-ligação',
    convite: 'Convite para visita',
    objecao_preco: 'Objeção de preço',
    objecao_entrada: 'Objeção de entrada',
    sem_resposta: 'Cliente sem resposta',
    fim_contato: 'Fim de contato',
  };

  const TEMPLATES = {
    carteira: {
      ligacao: {
        primeira_abordagem: ['Oi, {{nome}}, tudo bem? Aqui é {{corretor}}, da {{empresa}}. Estou retomando seu atendimento para entender se ainda faz sentido avaliarmos uma oportunidade com calma e de forma objetiva.'],
        retorno: ['{{nome}}, estou retornando para organizar seu próximo passo. Hoje sua prioridade é preço, localização, planta, entrada ou prazo de decisão?'],
        pos_ligacao: ['{{nome}}, conforme falamos, vou te passar um resumo claro para você decidir sem pressão e sem perder tempo.'],
        convite: ['{{nome}}, podemos marcar uma visita objetiva para comparar unidade, fluxo e oportunidade real. Qual dia fica melhor para você?'],
        objecao_preco: ['Entendo, {{nome}}. Vamos olhar o conjunto: unidade, andar, vaga, posição, fluxo e liquidez. O valor sozinho não conta a história inteira.'],
        objecao_entrada: ['Se a entrada ficou pesada, o caminho é redesenhar o fluxo. Posso avaliar uma composição mais leve para você comparar?'],
        sem_resposta: ['Tentativa curta e educada. Se não houver retorno, registrar corretamente e evitar insistência sem estratégia.'],
        fim_contato: ['Última tentativa elegante: confirmar se ainda existe interesse e deixar o canal aberto sem pressão.'],
      },
      whatsapp: {
        primeira_abordagem: ['Oi, {{nome}}. Sou {{corretor}}, da {{empresa}}. Tudo bem?\n\nEstou retomando seu atendimento de forma bem objetiva. Você ainda está avaliando imóvel ou prefere que eu pause esse contato por enquanto?'],
        retorno: ['{{nome}}, passando para retomar seu atendimento. Quer que eu te mande uma opção mais filtrada ou prefere primeiro ajustar o fluxo de pagamento?'],
        pos_ligacao: ['Oi, {{nome}}. Conforme nossa conversa, deixo aqui um resumo objetivo para você avaliar no seu tempo. Se fizer sentido, sigo com uma simulação mais ajustada.'],
        convite: ['{{nome}}, podemos organizar uma visita rápida e objetiva para olhar unidade, condição e fluxo. Qual melhor dia para você?'],
        objecao_preco: ['{{nome}}, entendo o ponto do valor. Para comparar direito, precisamos olhar produto, andar, vaga, posição, fluxo e liquidez. Às vezes a melhor oportunidade não é só o menor preço.'],
        objecao_entrada: ['{{nome}}, se a entrada pesou, podemos estudar uma composição mais leve. Me diga qual parte apertou mais: sinal, parcelas curtas ou intermediárias.'],
        sem_resposta: ['{{nome}}, só confirmando se imóvel ainda faz sentido para você. Se não for o momento, eu pauso o contato sem problema.'],
        fim_contato: ['{{nome}}, vou pausar meu contato por aqui para não ser inconveniente. Se futuramente fizer sentido, fico à disposição.'],
      },
      email: {
        primeira_abordagem: ['Assunto: {{nome}}, continuidade do seu atendimento\n\nOlá, {{nome}}. Sou {{corretor}}, da {{empresa}}. Estou retomando seu atendimento para entender se a busca por imóvel ainda faz sentido e se posso te ajudar com uma seleção mais objetiva.'],
        retorno: ['Assunto: Retomando seu atendimento\n\nOlá, {{nome}}. Estou retomando nosso contato para entender qual ponto é prioridade agora: planta, valor, entrada, localização ou prazo de decisão.'],
      },
    },
    lista_fria: {
      ligacao: {
        primeira_abordagem: ['Oi, {{nome}}, tudo bem? Aqui é {{corretor}}, da {{empresa}}. Prometo ser breve: imóvel é um assunto aberto para você hoje ou prefere que eu não siga com esse contato?', 'Olá, {{nome}}. Estou falando com algumas pessoas que avaliam imóveis em São Paulo. Posso te fazer uma pergunta rápida para entender se faz sentido te mandar algo ou pausar por aqui?'],
        retorno: ['{{nome}}, combinei de te retornar. Para eu ser objetivo: você está olhando imóvel para morar, investir ou só acompanhando oportunidades?'],
        pos_ligacao: ['{{nome}}, conforme falamos, o ideal é eu te mandar um resumo objetivo e você me diz se faz sentido seguir ou pausar o contato.'],
        convite: ['{{nome}}, se fizer sentido, podemos marcar uma visita rápida para você comparar unidade, fluxo e oportunidade real sem compromisso.'],
        objecao_preco: ['Entendo, {{nome}}. Só separaria preço de oportunidade: menor valor nem sempre significa melhor escolha. O que pesa mais para você hoje: valor total, entrada ou parcela?'],
        objecao_entrada: ['Entrada é engenharia financeira, não só obstáculo. Se o produto fizer sentido, podemos avaliar um fluxo menos pesado no início.'],
        sem_resposta: ['Tentativa curta. Se não atender, não insistir demais. Registrar feedback e tentar outro canal com mensagem objetiva.'],
        fim_contato: ['Última tentativa elegante: confirmar se o tema ainda faz sentido e deixar canal aberto sem pressão.'],
      },
      whatsapp: {
        primeira_abordagem: ['Oi, {{nome}}. Sou {{corretor}}, da {{empresa}}. Tudo bem?\n\nEstou entrando em contato de forma bem objetiva para entender se imóvel ainda é um assunto aberto para você. Se fizer sentido, posso te mandar opções filtradas; se não fizer, eu pauso por aqui sem problema.', 'Oi, {{nome}}. Aqui é {{corretor}}, da {{empresa}}.\n\nVi seu contato na nossa base comercial e queria confirmar se você está avaliando imóvel para morar, investir ou apenas acompanhando o mercado. Me responde com uma dessas opções que eu direciono sem te encher de mensagem.'],
        retorno: ['{{nome}}, passando para retomar seu atendimento. Você ainda está avaliando imóvel ou prefere que eu pause esse contato por enquanto?'],
        pos_ligacao: ['Oi, {{nome}}. Falamos agora há pouco. Conforme combinado, deixo aqui um resumo objetivo para você avaliar no seu tempo. Se fizer sentido, sigo com opções mais aderentes ao seu perfil.'],
        convite: ['{{nome}}, podemos organizar uma visita objetiva para você comparar unidade, localização e fluxo. Qual melhor dia para você?'],
        objecao_preco: ['{{nome}}, entendo sua percepção sobre valor. Para analisarmos corretamente, vale separar valor total, entrada, parcelas e condição real. Às vezes o ajuste está mais no fluxo do que no imóvel.'],
        objecao_entrada: ['{{nome}}, como a entrada ficou pesada, faz sentido avaliarmos uma composição mais leve. Posso simular um fluxo com menor impacto inicial para você comparar com calma.'],
        sem_resposta: ['{{nome}}, só passando uma última vez para não te incomodar. Se imóvel ainda fizer sentido, me chama por aqui. Se não for momento, eu pauso o contato sem problema.'],
        fim_contato: ['{{nome}}, sem problema. Vou pausar o contato por aqui para não te incomodar. Se futuramente fizer sentido falar sobre imóvel, fico à disposição.'],
      },
      email: {
        primeira_abordagem: ['Assunto: {{nome}}, sobre seu interesse em imóveis\n\nOlá, {{nome}}. Sou {{corretor}}, da {{empresa}}. Estou entrando em contato para entender se a busca por imóvel ainda faz sentido para você. Posso te ajudar com uma seleção objetiva conforme perfil, região e momento de compra.'],
        retorno: ['Assunto: Retomando seu atendimento\n\nOlá, {{nome}}. Estou retomando seu atendimento para entender se imóvel ainda está no seu radar e se posso te mandar opções mais filtradas.'],
        fim_contato: ['Assunto: Encerrando meu contato por enquanto\n\nOlá, {{nome}}. Como não consegui retorno, vou pausar meu contato por aqui para não ser inconveniente. Caso volte a fazer sentido, fico à disposição.'],
      },
    },
    visitou: {
      ligacao: {
        retorno: ['Oi, {{nome}}, tudo bem? Aqui é {{corretor}}, da {{empresa}}. Estou retomando seu atendimento depois da visita. O projeto ainda está no seu radar ou perdeu prioridade?'],
        pos_ligacao: ['{{nome}}, como você já conhece o projeto, faz sentido a gente ser objetivo: o que ficou pendente foi preço, fluxo, planta ou decisão familiar?'],
        objecao_preco: ['Entendo, {{nome}}. Só separaria preço de valor: caro é quando não faz sentido. O ponto que pesou mais foi valor total, entrada ou fluxo de pagamento?'],
        objecao_entrada: ['Esse ponto é comum. Então talvez o problema não seja o imóvel, mas a engenharia do fluxo. Posso avaliar uma composição com menor impacto inicial?'],
        convite: ['Como você já conhece o projeto, uma segunda visita pode ser mais estratégica: olhar unidade, fluxo e dúvidas finais. Faz sentido agendarmos?'],
      },
      whatsapp: {
        retorno: ['{{nome}}, retomando sua visita. Para eu ser objetivo: o que ainda está travando sua decisão hoje — valor, entrada, planta, localização ou timing?'],
        pos_ligacao: ['Oi, {{nome}}. Conforme nossa conversa, o próximo passo mais inteligente é validar uma simulação objetiva e tirar as últimas dúvidas. Assim você decide com segurança, sem pressão e sem achismo.'],
        objecao_preco: ['{{nome}}, entendo sua percepção sobre valor. Para analisarmos corretamente, vale separar valor total, entrada, parcelas e condição real. Às vezes o ajuste está mais no fluxo do que no imóvel.'],
        objecao_entrada: ['{{nome}}, como a entrada ficou pesada, faz sentido avaliarmos uma composição mais leve. Posso simular um fluxo com menor impacto inicial para você comparar com calma.'],
        convite: ['{{nome}}, podemos organizar uma nova visita mais focada nos pontos que ficaram em dúvida: planta, unidade, fluxo e condição. Qual melhor dia para você?'],
      },
      email: { retorno: ['Assunto: {{nome}}, continuidade da sua visita\n\nOlá, {{nome}}. Foi um prazer te receber. Estou retomando seu atendimento para entender se ficou alguma dúvida sobre planta, valor, fluxo de pagamento ou disponibilidade. Posso preparar uma simulação mais ajustada ao seu perfil.'] },
    },
    redes_sociais: {
      whatsapp: { primeira_abordagem: ['Oi, {{nome}}. Sou {{corretor}}, da {{empresa}}. Vi seu interesse pelo anúncio e queria te ajudar de forma objetiva: você busca mais informações de valores, plantas ou disponibilidade?'], retorno: ['{{nome}}, passando para retomar seu interesse pelo anúncio. Quer que eu te mande uma opção objetiva ou prefere que eu explique rapidamente por áudio/mensagem?'] },
      ligacao: { primeira_abordagem: ['Oi, {{nome}}, aqui é {{corretor}}, da {{empresa}}. Você demonstrou interesse pelo anúncio e eu queria entender se procura para morar, investir ou comparar oportunidades.'] },
      email: { primeira_abordagem: ['Assunto: Informações do imóvel anunciado\n\nOlá, {{nome}}. Vi seu interesse pelo anúncio e posso te enviar informações objetivas de valores, plantas e disponibilidade conforme seu perfil.'] },
    },
    problemas: {
      ligacao: { objecao_preco: ['Preço isolado engana. Vamos olhar valor por metro, fluxo, entrega, padrão e liquidez. O que realmente pesou na sua análise?'], objecao_entrada: ['Entrada pesada não significa negócio inviável. Pode ser caso de redesenhar o fluxo. Qual parcela inicial ficaria confortável para você avaliar?'], sem_resposta: ['Se não atende, o problema pode ser canal ou timing. Teste WhatsApp curto e registre corretamente para não sujar a análise comercial.'] },
      whatsapp: { objecao_preco: ['Entendo o ponto do valor. Para comparar com justiça, precisamos olhar produto, localização, fluxo, entrega e valor final — não só o preço de chamada.'], objecao_entrada: ['Sobre entrada, dá para avaliar alternativas de composição. Me diga qual ponto apertou mais: sinal, parcelas curtas, intermediárias ou financiamento.'], sem_resposta: ['{{nome}}, só confirmando se posso te ajudar com alguma informação objetiva ou se prefere que eu pause o contato por aqui.'] },
    },
    argumentacoes: {
      ligacao: { primeira_abordagem: ['A melhor oportunidade não é só o menor valor. É a combinação entre unidade, andar, vaga, posição, fluxo e timing. O barato errado vira caro com vista bonita para o problema.'], objecao_preco: ['Às vezes existe preço bom com unidade ruim, vaga ruim ou fluxo ruim. O ponto é comparar o conjunto, não só o metro quadrado.'], objecao_entrada: ['Entrada é parte da estratégia, não o único número. O que importa é entender se o fluxo completo cabe e se o imóvel sustenta valor.'] },
      whatsapp: { primeira_abordagem: ['Um ponto importante: nem sempre o melhor valor é a melhor oportunidade. É preciso olhar unidade, andar, vaga, posição, fluxo e momento de tabela. É aí que uma escolha estratégica faz diferença.'], objecao_preco: ['Preço baixo sozinho não garante bom negócio. Às vezes você ganha no valor e perde na vaga, andar, posição ou liquidez. O conjunto é que decide.'] },
    },
  };

  const state = {
    context: safeGet('fechai_pme_context', 'lista_fria'),
    channel: safeGet('fechai_pme_channel', 'ligacao'),
    approach: safeGet('fechai_pme_approach', 'primeira_abordagem'),
    variant: Number(safeGet('fechai_pme_variant', '0')) || 0,
    power: {
      power_dial: safeGet('fechai_pme_power_dial', 'off'),
      power_zap: safeGet('fechai_pme_power_zap', 'off'),
      power_mail: safeGet('fechai_pme_power_mail', 'off'),
    },
  };

  function safeGet(key, fallback) { try { return localStorage.getItem(key) || fallback; } catch (_) { return fallback; } }
  function safeSet(key, value) { try { localStorage.setItem(key, String(value)); } catch (_) {} }
  function saveState() {
    safeSet('fechai_pme_context', state.context);
    safeSet('fechai_pme_channel', state.channel);
    safeSet('fechai_pme_approach', state.approach);
    safeSet('fechai_pme_variant', state.variant);
    safeSet('fechai_pme_power_dial', state.power.power_dial);
    safeSet('fechai_pme_power_zap', state.power.power_zap);
    safeSet('fechai_pme_power_mail', state.power.power_mail);
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `
      #${TOP_ID}{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:linear-gradient(135deg,#0f172a,#1d4ed8);color:#fff;border-radius:20px;padding:14px 16px;box-shadow:0 10px 28px rgba(15,23,42,.14);margin:0 0 12px;}
      #${TOP_ID} .pme-top-title{font-size:21px;font-weight:950;line-height:1.1;}
      #${TOP_ID} .pme-top-sub{font-size:13px;opacity:.88;margin-top:5px;line-height:1.35;}
      #${ROOT_ID}{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#fff;border:1px solid #e5e7eb;border-radius:22px;padding:18px;box-shadow:0 10px 28px rgba(15,23,42,.08);margin:14px 0;max-width:100%;overflow:hidden;box-sizing:border-box;}
      #${ROOT_ID} *{box-sizing:border-box;}
      #${ROOT_ID} button,#${ROOT_ID} a,#${ROOT_ID} select{touch-action:manipulation;-webkit-tap-highlight-color:transparent;}
      #${ROOT_ID} .pme-header{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;margin-bottom:14px;}
      #${ROOT_ID} .pme-title{font-size:22px;font-weight:950;color:#111827;line-height:1.15;}
      #${ROOT_ID} .pme-sub{font-size:14px;color:#475569;margin-top:5px;line-height:1.4;}
      #${ROOT_ID} .pme-chip{font-size:12px;font-weight:900;color:#1d4ed8;background:#eff6ff;border:1px solid #bfdbfe;padding:7px 10px;border-radius:999px;white-space:nowrap;}
      #${ROOT_ID} .pme-step-title{font-size:17px;color:#0f172a;font-weight:950;margin:18px 0 6px;text-align:center;line-height:1.25;}
      #${ROOT_ID} .pme-step-help{font-size:13px;color:#64748b;font-weight:700;text-align:center;margin:-1px 0 10px;line-height:1.35;}
      #${ROOT_ID} .pme-origin-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(142px,1fr));gap:10px;align-items:stretch;margin:10px auto;max-width:980px;}
      #${ROOT_ID} .pme-channel-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;align-items:stretch;margin:10px auto;max-width:820px;}
      #${ROOT_ID} .pme-channel-card{display:flex;flex-direction:column;gap:8px;align-items:stretch;justify-content:flex-start;min-width:0;}
      #${ROOT_ID} .pme-pill{border:1px solid #dbeafe;background:#f8fafc;color:#334155;border-radius:18px;padding:13px 14px;font-size:15px;font-weight:950;white-space:normal;cursor:pointer;min-height:50px;line-height:1.15;width:100%;}
      #${ROOT_ID} .pme-pill.active{background:#2563eb;color:white;border-color:#2563eb;box-shadow:0 8px 18px rgba(37,99,235,.24);}
      #${ROOT_ID} .pme-power{background:#e5e7eb;color:#374151;border:1px solid #d1d5db;border-radius:999px;padding:9px 8px;font-size:12px;font-weight:950;cursor:pointer;min-height:36px;}
      #${ROOT_ID} .pme-power.on{background:#dcfce7;color:#166534;border-color:#86efac;}
      #${ROOT_ID} .pme-channel{border-radius:18px;padding:14px 8px;font-size:15px;min-height:52px;}
      #${ROOT_ID} .pme-select-wrap{max-width:680px;margin:10px auto 0;background:#f8fafc;border:1px solid #dbeafe;border-radius:18px;padding:10px;}
      #${ROOT_ID} .pme-select{width:100%;display:block;border:1px solid #93c5fd;border-radius:14px;padding:14px 42px 14px 14px;font-size:16px;font-weight:900;background:#fff;color:#0f172a;text-align:center;min-height:54px;appearance:auto;}
      #${ROOT_ID} .pme-box{background:#f8fafc;border:1px solid #e2e8f0;border-radius:18px;padding:14px;margin-top:16px;max-width:100%;overflow:hidden;}
      #${ROOT_ID} .pme-box-title{font-size:15px;color:#0f172a;font-weight:950;margin-bottom:7px;}
      #${ROOT_ID} .pme-text{font-size:16px;line-height:1.55;color:#111827;white-space:pre-line;overflow-wrap:anywhere;word-break:normal;}
      #${ROOT_ID} .pme-exec{background:#f8fafc;border:1px solid #e2e8f0;border-radius:18px;padding:14px;margin-top:14px;}
      #${ROOT_ID} .pme-exec-title{text-align:center;font-size:15px;color:#0f172a;font-weight:950;margin-bottom:10px;}
      #${ROOT_ID} .pme-actions{display:grid;grid-template-columns:1.4fr .8fr .8fr 1.1fr;gap:10px;}
      #${ROOT_ID} .pme-action{border:1px solid #dbeafe;background:#eff6ff;color:#1d4ed8;border-radius:999px;padding:12px 10px;font-size:14px;font-weight:950;text-decoration:none;cursor:pointer;text-align:center;line-height:1.2;min-height:46px;}
      #${ROOT_ID} .pme-action.primary{background:#2563eb;color:#fff;border-color:#2563eb;}
      #${ROOT_ID} .pme-action.ai{background:#fff7ed;color:#9a3412;border-color:#fed7aa;}
      #${ROOT_ID} .pme-status{font-size:13px;color:#64748b;margin-top:10px;line-height:1.4;text-align:center;}
      #${MODAL_ID}{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:99999;display:none;align-items:end;justify-content:center;padding:12px;}
      #${MODAL_ID}.open{display:flex;}
      #${MODAL_ID} .pme-modal-card{background:#fff;border-radius:22px;padding:16px;width:100%;max-width:620px;max-height:86vh;overflow:auto;box-shadow:0 24px 70px rgba(15,23,42,.35);font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;}
      #${MODAL_ID} .pme-modal-head{display:flex;align-items:flex-start;justify-content:space-between;gap:10px;margin-bottom:10px;}
      #${MODAL_ID} .pme-title{font-size:18px;font-weight:950;color:#111827;line-height:1.15;}
      #${MODAL_ID} .pme-sub{font-size:13px;color:#64748b;margin-top:3px;line-height:1.35;}
      #${MODAL_ID} textarea{width:100%;min-height:180px;border:1px solid #cbd5e1;border-radius:16px;padding:12px;font-size:16px;line-height:1.45;resize:vertical;}
      #${MODAL_ID} input{width:100%;border:1px solid #cbd5e1;border-radius:14px;padding:13px;font-size:15px;margin-top:8px;}
      #${MODAL_ID} .pme-modal-actions{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px;}
      #${MODAL_ID} .pme-modal-actions button,#${MODAL_ID} .pme-modal-actions a,#${MODAL_ID} .pme-close{border:0;border-radius:14px;padding:12px 10px;font-size:14px;font-weight:900;text-decoration:none;cursor:pointer;text-align:center;line-height:1.2;}
      #${MODAL_ID} .pme-primary{background:#2563eb;color:#fff;}
      #${MODAL_ID} .pme-green{background:#059669;color:#fff;}
      #${MODAL_ID} .pme-muted{background:#e5e7eb;color:#374151;}
      #${MODAL_ID} .pme-warn{background:#fff7ed;color:#9a3412;border:1px solid #fed7aa;}
      #${MODAL_ID} .pme-note{font-size:13px;color:#64748b;margin-top:8px;line-height:1.35;}
      @media(max-width:700px){#${ROOT_ID} .pme-origin-grid{grid-template-columns:repeat(2,minmax(0,1fr));gap:8px;}#${ROOT_ID} .pme-channel-grid{gap:7px;}#${ROOT_ID} .pme-pill{font-size:13px;padding:12px 8px;}#${ROOT_ID} .pme-power{font-size:10px;padding:8px 4px;}#${ROOT_ID} .pme-channel{font-size:12px;padding:12px 3px;}#${ROOT_ID} .pme-step-title{font-size:16px;}#${ROOT_ID} .pme-step-help{font-size:12px;}#${ROOT_ID} .pme-actions{grid-template-columns:repeat(2,minmax(0,1fr));}#${ROOT_ID} .pme-action.primary{grid-column:1/-1;}#${ROOT_ID} .pme-action{font-size:13px;}#${MODAL_ID}{align-items:end;}#${MODAL_ID} .pme-modal-actions{grid-template-columns:1fr;}}
      @media(max-width:420px){#${TOP_ID}{border-radius:16px;padding:13px 14px;}#${TOP_ID} .pme-top-title{font-size:19px;}#${ROOT_ID}{border-radius:16px;padding:13px;margin:12px 0;}#${ROOT_ID} .pme-header{flex-direction:column;align-items:stretch;}#${ROOT_ID} .pme-chip{text-align:center;white-space:normal;}#${ROOT_ID} .pme-origin-grid{grid-template-columns:1fr 1fr;}#${ROOT_ID} .pme-select{font-size:16px;min-height:56px;}#${ROOT_ID} .pme-text{font-size:15px;} }
    `;
    document.head.appendChild(style);
  }

  function markInteraction(ms) { suspendAutoRenderUntil = Date.now() + (ms || 1200); }
  function firstWord(text) { return String(text || '').trim().split(/\s+/)[0] || 'cliente'; }

  function getLeadName() {
    const tel = document.querySelector('a[href^="tel:"]');
    const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null;
    const title = card ? card.querySelector('h1,h2,h3,[class*="text-xl"],[class*="text-lg"],[class*="font-bold"]') : null;
    return title && title.textContent.trim() ? title.textContent.trim() : 'cliente';
  }
  function getPhoneE164() {
    const tel = document.querySelector('a[href^="tel:"]');
    return tel ? String(tel.getAttribute('href') || '').replace(/^tel:/, '').replace(/\s+/g, '') : '';
  }
  function getEmail() {
    const mail = document.querySelector('a[href^="mailto:"]');
    if (mail) return (mail.textContent || '').trim() || mail.href.replace(/^mailto:/, '');
    const txt = document.body.innerText || '';
    const match = txt.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
    return match ? match[0] : '';
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
    const byChannel = byContext[state.channel] || byContext.ligacao || byContext.whatsapp || byContext.email || {};
    return byChannel[state.approach] || byChannel.primeira_abordagem || byChannel.retorno || ['Conduza a conversa com objetividade, valide interesse e registre o próximo passo.'];
  }
  function getCurrentText() {
    const list = getTemplateList();
    const len = Math.max(list.length, 1);
    const index = ((state.variant % len) + len) % len;
    return renderTemplate(list[index]);
  }
  function getExecuteLabel() {
    if (state.channel === 'ligacao') return 'Efetuar ligação';
    if (state.channel === 'whatsapp') return 'Abrir WhatsApp';
    if (state.channel === 'email') return 'Preparar e-mail';
    return 'Executar';
  }
  function buildWhatsappUrl(text) {
    const phone = getPhoneE164().replace('+', '').replace(/\D/g, '');
    if (!phone) return '';
    return 'https://wa.me/' + phone + '?text=' + encodeURIComponent(text || getCurrentText());
  }
  function parseEmailParts(text) {
    const raw = String(text || '');
    const match = raw.match(/^\s*Assunto:\s*([^\n]+)\n+/i);
    if (!match) return { subject: 'Contato sobre imóvel', body: raw };
    return { subject: match[1].trim(), body: raw.slice(match[0].length).trim() };
  }
  function buildMailtoUrl(text) {
    const email = getEmail();
    if (!email) return '';
    const parts = parseEmailParts(text || getCurrentText());
    return 'mailto:' + encodeURIComponent(email) + '?subject=' + encodeURIComponent(parts.subject) + '&body=' + encodeURIComponent(parts.body);
  }
  async function copyText(text, label) {
    try { await navigator.clipboard.writeText(text); setStatus(label || 'Copiado.'); return true; }
    catch (_) { window.prompt('Copie o texto:', text); setStatus('Copie manualmente pela janela aberta.'); return false; }
  }
  function setStatus(text) {
    const root = document.getElementById(ROOT_ID);
    const el = root ? root.querySelector('[data-pme-status]') : null;
    if (el) el.textContent = text || '';
  }
  function hasDiscadorLead() { return !!document.querySelector('a[href^="tel:"]') && /Feedback/i.test(document.body.innerText || ''); }

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
  function findDiscadorContainer() {
    const tel = document.querySelector('a[href^="tel:"]');
    const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null;
    return card ? card.parentElement : null;
  }
  function ensureTopTitle() {
    const container = findDiscadorContainer();
    if (!container) return;
    let top = document.getElementById(TOP_ID);
    if (!top) { top = document.createElement('div'); top.id = TOP_ID; }
    top.innerHTML = '<div class="pme-top-title">⚡ Discador Flow AI</div><div class="pme-top-sub">Atendimento guiado: lead → origem → canal → abordagem → execução → feedback</div>';
    if (top.parentElement !== container || container.firstElementChild !== top) container.insertBefore(top, container.firstElementChild || null);
  }
  function hideOriginalTopPowerDial() {
    const buttons = Array.from(document.querySelectorAll('button'));
    const btn = buttons.find((b) => !document.getElementById(ROOT_ID)?.contains(b) && /Power\s*Dial/i.test(b.textContent || ''));
    if (!btn) return;
    const row = btn.parentElement;
    if (row && !row.dataset.pmeOriginalPowerHidden) { row.dataset.pmeOriginalPowerHidden = '1'; row.style.display = 'none'; }
  }
  function hideOriginalContactButtons() {
    const tel = document.querySelector('a[href^="tel:"]');
    if (!tel || document.getElementById(ROOT_ID)?.contains(tel)) return;
    const card = tel.closest('.bg-white') || tel.closest('[class*="bg-white"]');
    if (!card) return;
    const rows = Array.from(card.querySelectorAll('div'));
    const row = rows.find((r) => r.querySelector('a[href^="tel:"]') && /Mensagens/i.test(r.textContent || ''));
    if (row && !row.dataset.pmeOriginalContactHidden) { row.dataset.pmeOriginalContactHidden = '1'; row.style.display = 'none'; }
  }
  function getExternalPowerDialButton() {
    const root = document.getElementById(ROOT_ID);
    return Array.from(document.querySelectorAll('button')).find((b) => (!root || !root.contains(b)) && /Power\s*Dial/i.test(b.textContent || '')) || null;
  }
  function syncPowerDialFromApp() {
    const btn = getExternalPowerDialButton();
    const txt = btn ? (btn.textContent || '') : '';
    const byText = /ON/i.test(txt) ? 'on' : (/OFF/i.test(txt) ? 'off' : '');
    const byStorage = safeGet('powerDial', '') === 'true' ? 'on' : 'off';
    state.power.power_dial = byText || byStorage;
    safeSet('fechai_pme_power_dial', state.power.power_dial);
  }
  function togglePower(key) {
    if (key === 'power_dial') {
      const btn = getExternalPowerDialButton();
      if (btn) btn.click();
      else { const next = state.power.power_dial === 'on' ? 'off' : 'on'; state.power.power_dial = next; safeSet('powerDial', next === 'on' ? 'true' : 'false'); }
      setTimeout(() => { syncPowerDialFromApp(); render(true); }, 80);
      return;
    }
    state.power[key] = state.power[key] === 'on' ? 'off' : 'on';
    saveState(); render(true);
    setTimeout(() => setStatus(`${powerLabel(key)} ${state.power[key].toUpperCase()}. No MVP isso não executa automação sozinho.`), 0);
  }
  function renderPills(items, active, attr) {
    return Object.entries(items).map(([key, item]) => {
      const label = typeof item === 'string' ? item : `${item.icon || ''} ${item.label}`;
      return `<button type="button" class="pme-pill ${key === active ? 'active' : ''}" data-pme-${attr}="${escapeHtml(key)}">${escapeHtml(label)}</button>`;
    }).join('');
  }
  function renderChannelGrid() {
    syncPowerDialFromApp();
    return `<div class="pme-channel-grid">${Object.entries(CHANNELS).map(([key, item]) => {
      const currentPower = state.power[item.powerKey] === 'on' ? 'on' : 'off';
      return `<div class="pme-channel-card"><button type="button" class="pme-power ${currentPower === 'on' ? 'on' : ''}" data-pme-power="${escapeHtml(item.powerKey)}">${escapeHtml(item.powerLabel)} ${currentPower === 'on' ? 'ON' : 'OFF'}</button><button type="button" class="pme-pill pme-channel ${key === state.channel ? 'active' : ''}" data-pme-channel="${escapeHtml(key)}">${escapeHtml(item.icon + ' ' + item.label)}</button></div>`;
    }).join('')}</div>`;
  }
  function renderApproachSelect() {
    return `<div class="pme-select-wrap"><select class="pme-select" data-pme="approach" aria-label="Escolha em qual situação o cliente está">${Object.entries(APPROACHES).map(([key, label]) => `<option value="${key}" ${key === state.approach ? 'selected' : ''}>${escapeHtml(label)}</option>`).join('')}</select></div>`;
  }

  function render(force) {
    ensureStyle(); ensureModal();
    if (!hasDiscadorLead()) {
      const old = document.getElementById(ROOT_ID); const top = document.getElementById(TOP_ID);
      if (old) old.remove(); if (top) top.remove(); return;
    }
    if (!force && shouldSkipAutoRender()) return;
    const mount = findMountPoint(); if (!mount) return;
    ensureTopTitle(); hideOriginalTopPowerDial(); hideOriginalContactButtons();

    let root = document.getElementById(ROOT_ID);
    if (!root) { root = document.createElement('div'); root.id = ROOT_ID; mount.parent.insertBefore(root, mount.before || null); bindRootOnce(root); }
    else if (root.parentElement !== mount.parent) { mount.parent.insertBefore(root, mount.before || null); bindRootOnce(root); }

    normalizeState();
    const text = getCurrentText();
    const ctx = CONTEXTS[state.context];
    const channel = CHANNELS[state.channel];

    root.innerHTML = `
      <div class="pme-header">
        <div>
          <div class="pme-title">Fluxo de atendimento</div>
          <div class="pme-sub">Siga os passos abaixo. Primeiro escolha a origem, depois o canal, a situação e por fim execute o contato.</div>
        </div>
        <div class="pme-chip">${escapeHtml(ctx.label)} · ${escapeHtml(channel.label)}</div>
      </div>
      <div class="pme-step-title">1. Escolha a origem do lead</div>
      <div class="pme-step-help">De onde veio esse cliente?</div>
      <div class="pme-origin-grid">${renderPills(CONTEXTS, state.context, 'context')}</div>
      <div class="pme-step-title">2. Escolha o canal para contato com o cliente</div>
      <div class="pme-step-help">Defina se vai ligar, chamar no WhatsApp ou preparar um e-mail.</div>
      ${renderChannelGrid()}
      <div class="pme-step-title">3. Escolha em qual situação o cliente está</div>
      <div class="pme-step-help">Isso muda a mensagem sugerida para o corretor usar agora.</div>
      ${renderApproachSelect()}
      <div class="pme-box"><div class="pme-box-title">Mensagem sugerida</div><div class="pme-text">${escapeHtml(text)}</div></div>
      <div class="pme-exec"><div class="pme-exec-title">4. Executar contato</div><div class="pme-actions"><button class="pme-action primary" data-pme-action="use">${escapeHtml(getExecuteLabel())}</button><button class="pme-action" data-pme-action="prev">Voltar</button><button class="pme-action" data-pme-action="next">Próximo</button><button class="pme-action ai" data-pme-action="ai">Melhorar com IA</button></div></div>
      <div class="pme-status" data-pme-status>${escapeHtml(ctx.hint)} A PME não envia mensagem sozinha e não registra feedback automaticamente.</div>`;
  }

  function normalizeState() {
    if (!CONTEXTS[state.context]) state.context = 'lista_fria';
    if (!CHANNELS[state.channel]) state.channel = 'ligacao';
    if (!APPROACHES[state.approach]) state.approach = 'primeira_abordagem';
    saveState();
  }
  function shouldSkipAutoRender() {
    if (Date.now() < suspendAutoRenderUntil) return true;
    const active = document.activeElement;
    const root = document.getElementById(ROOT_ID);
    const modal = document.getElementById(MODAL_ID);
    if (root && active && root.contains(active) && active.tagName === 'SELECT') return true;
    if (modal && active && modal.contains(active)) return true;
    return false;
  }
  function bindRootOnce(root) {
    if (root.__pmeBound) return;
    root.__pmeBound = true;
    root.addEventListener('pointerdown', handleRootPointerDown, true);
    root.addEventListener('focusin', handleRootFocusIn, true);
    root.addEventListener('click', handleRootClick, true);
    root.addEventListener('change', handleRootChange, true);
  }
  function handleRootPointerDown(e) { if (e.target.closest('[data-pme="approach"]')) markInteraction(2500); }
  function handleRootFocusIn(e) { if (e.target.closest('[data-pme="approach"]')) markInteraction(2500); }
  function handleRootClick(e) {
    const target = e.target.closest('[data-pme-context],[data-pme-channel],[data-pme-power],[data-pme-action]');
    if (!target || !document.getElementById(ROOT_ID)?.contains(target)) return;
    e.preventDefault(); e.stopPropagation();
    const context = target.getAttribute('data-pme-context');
    if (context) { state.context = context; state.variant = 0; saveState(); render(true); return; }
    const channel = target.getAttribute('data-pme-channel');
    if (channel) { state.channel = channel; state.variant = 0; saveState(); render(true); return; }
    const power = target.getAttribute('data-pme-power');
    if (power) { togglePower(power); return; }
    const action = target.getAttribute('data-pme-action');
    if (action === 'next') { state.variant += 1; saveState(); render(true); return; }
    if (action === 'prev') { state.variant -= 1; saveState(); render(true); return; }
    if (action === 'use') { useCurrentText(); return; }
    if (action === 'ai') openModal(getCurrentText(), true);
  }
  function handleRootChange(e) {
    const el = e.target.closest('[data-pme="approach"]');
    if (!el) return;
    suspendAutoRenderUntil = 0;
    state.approach = el.value;
    state.variant = 0;
    saveState();
    render(true);
  }
  function powerLabel(key) { const found = Object.values(CHANNELS).find((c) => c.powerKey === key); return found ? found.powerLabel : key; }
  async function useCurrentText() {
    const text = getCurrentText();
    if (state.channel === 'whatsapp') {
      const url = buildWhatsappUrl(text);
      if (!url) { await copyText(text, 'Telefone não identificado. Texto copiado para uso manual.'); return; }
      window.open(url, '_blank', 'noopener,noreferrer'); setStatus('WhatsApp aberto com texto pronto. Confirme manualmente antes de enviar.'); return;
    }
    if (state.channel === 'email') {
      const mailto = buildMailtoUrl(text);
      if (mailto) { window.location.href = mailto; setStatus('E-mail preparado no cliente de e-mail. Revise antes de enviar.'); return; }
      await copyText(text, 'E-mail não identificado. Texto copiado para uso manual.'); return;
    }
    await copyText(text, 'Fala de ligação copiada. A ligação será iniciada se o dispositivo permitir.');
    const phone = getPhoneE164();
    if (phone) { window.location.href = 'tel:' + phone; setStatus('Ligação acionada e fala copiada como apoio.'); }
  }

  function ensureModal() {
    if (document.getElementById(MODAL_ID)) return;
    const modal = document.createElement('div');
    modal.id = MODAL_ID;
    modal.innerHTML = `<div class="pme-modal-card"><div class="pme-modal-head"><div><div class="pme-title">Melhorar com IA</div><div class="pme-sub">Revise antes de utilizar. Nada será enviado automaticamente.</div></div><button class="pme-close pme-muted" data-modal-action="close">Fechar</button></div><textarea data-modal="text"></textarea><input data-modal="tip" placeholder="Dica para IA: cliente achou caro, quer entrada menor, já visitou..." /><div class="pme-note" data-modal="status"></div><div class="pme-modal-actions"><button class="pme-primary" data-modal-action="use">Utilizar versão</button><button class="pme-warn" data-modal-action="ai">Melhorar novamente</button><button class="pme-muted" data-modal-action="copy">Copiar</button><a class="pme-green" data-modal-action="whatsapp" target="_blank" rel="noopener noreferrer" href="#">Abrir WhatsApp</a></div></div>`;
    document.body.appendChild(modal);
    modal.addEventListener('click', handleModalClick, true);
    modal.addEventListener('input', updateModalWhatsapp, true);
  }
  function handleModalClick(e) {
    const modal = document.getElementById(MODAL_ID); if (!modal) return;
    if (e.target === modal) { closeModal(); return; }
    const target = e.target.closest('[data-modal-action]'); if (!target || !modal.contains(target)) return;
    const action = target.getAttribute('data-modal-action');
    if (action !== 'whatsapp') { e.preventDefault(); e.stopPropagation(); }
    if (action === 'close') closeModal();
    if (action === 'copy') copyText(modal.querySelector('[data-modal="text"]').value, 'Texto copiado.');
    if (action === 'use') useModalText();
    if (action === 'ai') improveModalText(true);
  }
  function openModal(text, runAi) {
    const modal = document.getElementById(MODAL_ID); if (!modal) return;
    modal.querySelector('[data-modal="text"]').value = text || getCurrentText();
    modal.querySelector('[data-modal="tip"]').value = '';
    setModalStatus('Preparando IA. Se falhar, use o texto base.');
    updateModalWhatsapp(); modal.classList.add('open'); if (runAi) improveModalText(false);
  }
  function closeModal() { document.getElementById(MODAL_ID)?.classList.remove('open'); }
  function setModalStatus(text) { const el = document.querySelector(`#${MODAL_ID} [data-modal="status"]`); if (el) el.textContent = text || ''; }
  async function useModalText() {
    const modal = document.getElementById(MODAL_ID); if (!modal) return;
    const text = modal.querySelector('[data-modal="text"]').value;
    if (state.channel === 'whatsapp') { const url = buildWhatsappUrl(text); if (url) { window.open(url, '_blank', 'noopener,noreferrer'); setModalStatus('WhatsApp aberto. Confirme manualmente antes de enviar.'); return; } }
    if (state.channel === 'email') { const mailto = buildMailtoUrl(text); if (mailto) { window.location.href = mailto; setModalStatus('E-mail preparado. Revise antes de enviar.'); return; } }
    await copyText(text, 'Texto copiado.'); setModalStatus('Texto copiado para uso manual.');
  }
  function updateModalWhatsapp() {
    const modal = document.getElementById(MODAL_ID); if (!modal) return;
    const link = modal.querySelector('[data-modal-action="whatsapp"]');
    const text = modal.querySelector('[data-modal="text"]').value;
    const url = buildWhatsappUrl(text);
    if (url && state.channel === 'whatsapp') { link.href = url; link.style.display = 'block'; }
    else { link.href = '#'; link.style.display = 'none'; }
  }
  function getSupabaseAccessToken() {
    const candidates = [];
    try {
      for (let i = 0; i < localStorage.length; i += 1) {
        const key = localStorage.key(i); const raw = localStorage.getItem(key);
        if (!raw) continue;
        if (key && key.includes('auth-token')) candidates.push(raw);
        if (raw.includes('access_token') || raw.includes('currentSession')) candidates.push(raw);
      }
    } catch (_) {}
    for (const raw of candidates) { const token = findTokenInValue(raw); if (token) return { token, expired: isJwtExpired(token) }; }
    return { token: '', expired: false };
  }
  function findTokenInValue(raw) {
    try { return findAccessToken(JSON.parse(raw)); }
    catch (_) { const match = String(raw).match(/eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/); return match ? match[0] : ''; }
  }
  function findAccessToken(value) {
    if (!value) return '';
    if (typeof value === 'string') return value.startsWith('eyJ') && value.split('.').length === 3 ? value : '';
    if (Array.isArray(value)) { for (const item of value) { const found = findAccessToken(item); if (found) return found; } return ''; }
    if (typeof value === 'object') {
      if (typeof value.access_token === 'string') return value.access_token;
      if (value.currentSession) { const found = findAccessToken(value.currentSession); if (found) return found; }
      if (value.session) { const found = findAccessToken(value.session); if (found) return found; }
      for (const key of Object.keys(value)) { const found = findAccessToken(value[key]); if (found) return found; }
    }
    return '';
  }
  function isJwtExpired(token) {
    try { const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'))); return payload.exp ? Date.now() >= payload.exp * 1000 : false; }
    catch (_) { return false; }
  }
  async function improveModalText(forceRetry) {
    const modal = document.getElementById(MODAL_ID); if (!modal) return;
    const textarea = modal.querySelector('[data-modal="text"]');
    const tip = modal.querySelector('[data-modal="tip"]').value.trim();
    const session = getSupabaseAccessToken();
    if (!session.token) { setModalStatus('IA indisponível: token da sessão não encontrado. Faça login novamente e use o texto base por enquanto.'); return; }
    if (session.expired) { setModalStatus('IA indisponível: sessão expirada. Faça login novamente. O texto base continua disponível.'); return; }
    setModalStatus(forceRetry ? 'Tentando nova versão com IA...' : 'Melhorando com IA...');
    try {
      const prompt = buildAiPrompt(textarea.value, tip, forceRetry);
      const res = await fetch(`${SUPABASE_URL}/functions/v1/assistente-ai`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${session.token}` }, body: JSON.stringify({ messages: [{ role: 'user', content: prompt }], context: { module: 'discador_flow_ai', version: VERSION, situacao: state.context, canal: state.channel, abordagem: state.approach } }) });
      const data = await safeJson(res);
      if (!res.ok) throw new Error(data?.error || data?.message || `Erro ${res.status}`);
      const improved = extractAiText(data);
      if (!improved) throw new Error('A IA não retornou texto utilizável.');
      textarea.value = improved; setModalStatus('IA gerou uma versão. Revise antes de utilizar.'); updateModalWhatsapp();
    } catch (err) { setModalStatus(`IA indisponível: ${err.message || 'falha não identificada'}. Use o texto base e registre o feedback normalmente.`); }
  }
  function buildAiPrompt(baseText, tip, forceRetry) {
    return ['Você é o copiloto comercial do FECH.AI para corretores imobiliários.', 'Melhore o texto abaixo mantendo tom humano, direto, elegante e comercial.', 'Não invente preço, desconto, unidade, condição, prazo, disponibilidade ou promessa.', 'Não diga que enviou algo automaticamente. O corretor sempre revisa antes.', `Origem do lead: ${CONTEXTS[state.context]?.label || state.context}.`, `Canal: ${CHANNELS[state.channel]?.label || state.channel}.`, `Situação: ${APPROACHES[state.approach] || state.approach}.`, tip ? `Dica do corretor: ${tip}.` : 'Sem dica adicional do corretor.', forceRetry ? 'Gere uma versão diferente da anterior.' : 'Gere uma versão melhorada.', 'Texto base:', baseText, 'Retorne somente o texto final, sem explicações.'].join('\n');
  }
  async function safeJson(res) { try { return await res.json(); } catch (_) { return null; } }
  function extractAiText(data) {
    if (!data) return ''; if (typeof data === 'string') return data.trim();
    return String(data.text || data.content || data.message || data.answer || data.output_text || data?.resposta || data?.data?.text || data?.data?.content || data?.choices?.[0]?.message?.content || data?.choices?.[0]?.text || '').trim();
  }
  function escapeHtml(text) { return String(text || '').replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#039;'); }
  function debounce(fn, wait) { let t; return function () { clearTimeout(t); t = setTimeout(fn, wait); }; }

  const debouncedRender = debounce(() => render(false), 350);
  window.FECHAI_PME_CALL_ASSISTANT = { version: VERSION, render: () => render(true), data: { CONTEXTS, CHANNELS, APPROACHES, TEMPLATES } };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => render(true)); else render(true);
  const observer = new MutationObserver(debouncedRender);
  observer.observe(document.body, { childList: true, subtree: true });
})();
