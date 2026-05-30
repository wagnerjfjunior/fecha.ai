/*
 * FECH.AI — PME Empreendimentos Inline Flow
 * Version: 0.1.2
 * Scope: frontend-only enhancer for the existing PME atendimento flow.
 * Safety: no automatic sending, no Supabase/RPC/RLS/Auth/DB changes.
 */
(function () {
  'use strict';

  const ROOT_ID = 'fechai-pme-call-assistant';
  const STYLE_ID = 'fechai-pme-empreendimentos-inline-style';
  const MODE_KEY = 'fechai_pme_flow_mode';
  const DEVELOPMENT_KEY = 'fechai_pme_development';
  const SITUATION_KEY = 'fechai_pme_development_situation';
  const VARIANT_KEY = 'fechai_pme_development_variant';

  let runtimeMode = safeGet(MODE_KEY, 'origem');
  let runtimeDevelopment = safeGet(DEVELOPMENT_KEY, 'chateau_jardin');
  let runtimeSituation = safeGet(SITUATION_KEY, 'convite_lancamento');
  let runtimeVariant = Number(safeGet(VARIANT_KEY, '0')) || 0;
  let lastInlineHandledAt = 0;

  const BLOCKED_TERMS = [
    'últimas unidades',
    'condição exclusiva',
    'desconto de lançamento',
    'tabela especial garantida',
    'diretoria liberou',
    'reserva garantida',
    'preço fechado',
    'melhor condição só amanhã'
  ];

  const DEVELOPMENTS = {
    chateau_jardin: {
      label: 'Château Jardin',
      icon: '🏛️',
      address: 'Rua Ministro Nelson Hungria, 400',
      hint: 'Alto padrão no novo eixo Cidade Jardim, inspirado nos jardins franceses.'
    }
  };

  const SITUATIONS = {
    convite_lancamento: 'Convite para lançamento',
    primeiro_contato: 'Primeiro contato',
    pediu_plantas: 'Pediu plantas',
    pediu_valores: 'Pediu valores',
    pediu_material: 'Pediu material',
    ja_conhece_projeto: 'Já conhece o projeto',
    visitou_plantao: 'Visitou plantão',
    pos_visita: 'Pós-visita',
    quer_levar_familia: 'Quer levar família',
    comparando: 'Está comparando',
    sem_resposta: 'Sem resposta'
  };

  const signature = '\n\n{{corretor}} — {{telefone_corretor}}\nWhatsApp: {{link_whatsapp_corretor}}\n\nAo chegar, por gentileza, solicite por {{corretor}} na recepção para que eu possa te receber pessoalmente.';
  const callClose = '\n\nO evento será na Rua Ministro Nelson Hungria, 400. Quando chegar, por gentileza, solicite por {{corretor}} na recepção para que eu possa te receber pessoalmente e apresentar o projeto com calma.';

  const WHATSAPP = [
    'Olá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado na elegância dos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar o material com plantas e detalhes do evento?',
    '{{nome}}, tudo bem?\n\nAmanhã acontece o lançamento do Château Jardin, um projeto de alto padrão no novo eixo Cidade Jardim.\n\nO empreendimento une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e metragens amplas de 185 m² a 355 m².\n\nQuer que eu te envie as plantas para avaliar com calma?',
    'Olá, {{nome}}.\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. 📍\n\nÉ um projeto Tegra e Exto, com inspiração nos jardins franceses, lazer de alto padrão e opções de 185 m², 215 m², 248 m² e 355 m². 📐\n\nPosso te mandar um resumo com as plantas?',
    '{{nome}}, amanhã teremos o lançamento do Château Jardin.\n\nÉ um projeto inspirado no clássico, nos jardins franceses e em uma forma mais elegante de viver, no novo eixo Cidade Jardim.\n\nAs opções contemplam 185 m², 215 m², 248 m² e 355 m².\n\nFaz sentido eu te enviar o material agora?',
    'Olá, {{nome}}, tudo bem?\n\nAmanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.\n\nO projeto reúne arquitetura clássica, paisagismo internacional EDSA, lazer de perfil private club e plantas generosas de 185 m² a 355 m².\n\nQuer receber as informações iniciais?',
    '{{nome}}, estou organizando os atendimentos do lançamento do Château Jardin, que acontece amanhã na Rua Ministro Nelson Hungria, 400. 🗓️\n\nO empreendimento tem inspiração na elegância dos jardins franceses e plantas de 185 m², 215 m², 248 m² e 355 m². 🌿\n\nPosso te mandar as opções?',
    'Olá, {{nome}}.\n\nAmanhã é o lançamento do Château Jardin, projeto Tegra e Exto no novo eixo Cidade Jardim.\n\nUm refúgio urbano com arquitetura clássica, paisagismo internacional EDSA, quadra de tênis de saibro, padel, piscina coberta e metragens de 185 m² a 355 m².\n\nPosso te enviar o material?',
    '{{nome}}, tudo bem?\n\nAmanhã teremos o evento de lançamento do Château Jardin.\n\nO projeto foi pensado para quem busca alto padrão, elegância atemporal e plantas amplas, com opções de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nQuer que eu te envie os detalhes?',
    'Olá, {{nome}}.\n\nO Château Jardin será lançado amanhã no novo eixo Cidade Jardim.\n\nÉ um projeto com inspiração clássica, atmosfera de jardins franceses, lazer sofisticado e assinatura Tegra e Exto. 🏛️\n\nAs plantas contemplam 185 m², 215 m², 248 m² e 355 m². 📐\n\nPosso te mandar o material?',
    '{{nome}}, passando rapidamente para te apresentar o Château Jardin, que terá evento de lançamento amanhã.\n\nÉ um projeto de alto padrão na Rua Ministro Nelson Hungria, 400, com arquitetura clássica, paisagismo internacional e metragens amplas de 185 m² a 355 m².\n\nPosso te enviar as plantas?',
    'Olá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, um projeto que une o clássico e o contemporâneo no novo eixo Cidade Jardim.\n\nInspirado na elegância dos jardins franceses, traz plantas de 185 m², 215 m², 248 m² e 355 m².\n\nQuer conhecer o material?',
    '{{nome}}, amanhã teremos a apresentação do Château Jardin, empreendimento Tegra e Exto com projeto internacional EDSA.\n\nA proposta combina jardins, lazer de alto padrão, arquitetura clássica e unidades amplas de 185 m² a 355 m². 🌿\n\nPosso te enviar as informações pelo WhatsApp?',
    'Olá, {{nome}}.\n\nO lançamento do Château Jardin será amanhã, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto no novo eixo Cidade Jardim, com inspiração clássica, paisagismo sofisticado e opções de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te mandar as plantas e diferenciais?',
    '{{nome}}, tudo bem?\n\nEstou te chamando porque amanhã será o lançamento do Château Jardin.\n\nO projeto tem uma proposta elegante, inspirada no clássico e nos jardins franceses, com lazer completo e metragens de 185 m² a 355 m².\n\nFaz sentido eu te enviar o material?',
    'Olá, {{nome}}.\n\nAmanhã acontece o evento de lançamento do Château Jardin, realização Tegra e Exto.\n\nO empreendimento fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².\n\nQuer que eu te envie os detalhes?',
    '{{nome}}, amanhã será o lançamento do Château Jardin, um projeto residencial de alto padrão na Rua Ministro Nelson Hungria, 400. 📍\n\nEle combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e lazer com tênis, padel, piscina coberta e wellness.\n\nPosso te mandar o material?',
    'Olá, {{nome}}, tudo bem?\n\nO Château Jardin será lançado amanhã e estou organizando os atendimentos por horário.\n\nO projeto tem plantas de 185 m², 215 m², 248 m² e 355 m², com lazer sofisticado e proposta de refúgio urbano no novo eixo Cidade Jardim.\n\nPosso te enviar as plantas?',
    '{{nome}}, passando para te avisar sobre o lançamento do Château Jardin amanhã.\n\nÉ um projeto Tegra e Exto, com paisagismo internacional EDSA, inspiração nos jardins franceses e uma estrutura de lazer diferenciada: tênis de saibro, padel, piscina coberta e wellness. 🌿\n\nPosso te enviar um resumo?',
    'Olá, {{nome}}.\n\nAmanhã teremos o lançamento do Château Jardin, um projeto que nasce como um novo marco residencial no eixo Cidade Jardim.\n\nSão plantas amplas de 185 m², 215 m², 248 m² e 355 m², com arquitetura clássica e lazer de alto padrão.\n\nQuer receber o material?',
    '{{nome}}, tudo bem?\n\nAmanhã será o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nUm projeto de alto padrão inspirado no clássico, nos jardins franceses e em uma experiência residencial mais reservada.\n\nTemos opções de 185 m² a 355 m².\n\nPosso te mandar as informações?'
  ].map((text) => text + signature);

  const LIGACAO = [
    'Oi, {{nome}}, tudo bem? Aqui é {{corretor}}. Estou te ligando rapidamente porque amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado no clássico e nos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m². Faz sentido eu te enviar o material e verificar um horário para você conhecer?',
    '{{nome}}, tudo bem? Aqui é {{corretor}}. Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão no novo eixo Cidade Jardim. O projeto une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e lazer com tênis de saibro, padel, piscina coberta e wellness. Posso te mandar as plantas e entender se alguma metragem faz sentido para você?',
    'Oi, {{nome}}, aqui é {{corretor}}. Vou ser breve: amanhã acontece o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto sofisticado, com inspiração nos jardins franceses, plantas amplas de 185 m² a 355 m² e uma proposta residencial reservada. Você busca algo nesse perfil ou prefere apenas receber o material para avaliar?',
    '{{nome}}, tudo bem? Estou entrando em contato porque amanhã será o evento de lançamento do Château Jardin. O projeto tem realização Tegra e Exto, fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m². Posso te enviar um resumo com plantas e principais diferenciais?',
    'Oi, {{nome}}, tudo bem? Aqui é {{corretor}}. Amanhã vamos apresentar o Château Jardin, um projeto com arquitetura clássica, inspiração nos jardins franceses e paisagismo internacional. É um produto para quem busca alto padrão, conforto e plantas generosas. Você gostaria de conhecer as opções ou prefere que eu envie primeiro pelo WhatsApp?',
    '{{nome}}, tudo bem? Estou te ligando porque amanhã teremos o lançamento do Château Jardin, um projeto no novo eixo Cidade Jardim com lazer de perfil private club: tênis de saibro, padel, piscina coberta, wellness e áreas sociais completas. As metragens vão de 185 m² a 355 m². Posso te passar o material?',
    'Oi, {{nome}}, aqui é {{corretor}}. Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. O projeto tem uma proposta elegante: arquitetura clássica, jardins, serviços de alto padrão e plantas amplas. Queria entender se você está buscando imóvel para morar, investir ou apenas avaliando oportunidades nesse perfil.',
    '{{nome}}, tudo bem? Vou falar rapidinho. Amanhã teremos o lançamento do Château Jardin, realização Tegra e Exto. O empreendimento foi pensado como um refúgio urbano no novo eixo Cidade Jardim, com metragens de 185 m², 215 m², 248 m² e 355 m². Posso te enviar as plantas para você avaliar com calma?',
    'Oi, {{nome}}, aqui é {{corretor}}. Amanhã acontece o evento de lançamento do Château Jardin. É um projeto com inspiração clássica, atmosfera de jardins franceses, paisagismo EDSA e uma estrutura de lazer diferenciada. Se fizer sentido para você, posso te mandar o material e verificar um horário de apresentação.',
    '{{nome}}, tudo bem? Estou te ligando sobre o Château Jardin, empreendimento de alto padrão que será apresentado amanhã na Rua Ministro Nelson Hungria, 400. As opções são de 185 m², 215 m², 248 m² e 355 m². Posso te enviar o material e depois conversamos com mais calma?'
  ].map((text) => text + callClose);

  const EMAIL = [
    { subject: 'Château Jardin | Lançamento amanhã', body: 'Olá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, projeto de alto padrão no novo eixo Cidade Jardim, com realização Tegra e Exto.\n\nInspirado na arquitetura clássica e na elegância dos jardins franceses, o empreendimento reúne paisagismo internacional EDSA, lazer sofisticado e plantas amplas de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar as plantas e verificar um horário de apresentação?\n\nO evento será na Rua Ministro Nelson Hungria, 400.' },
    { subject: 'Convite para conhecer o Château Jardin', body: '{{nome}},\n\nEstou passando para te apresentar o Château Jardin, lançamento Tegra e Exto no novo eixo Cidade Jardim.\n\nO projeto combina inspiração clássica, jardins franceses, lazer de perfil private club e metragens generosas de 185 m² a 355 m².\n\nO evento acontece amanhã, na Rua Ministro Nelson Hungria, 400.\n\nPosso te encaminhar o material completo?' },
    { subject: 'Château Jardin — plantas de 185 m² a 355 m²', body: 'Olá, {{nome}}.\n\nO Château Jardin será apresentado amanhã e traz uma proposta residencial de alto padrão, com arquitetura clássica, paisagismo internacional e plantas de 185 m², 215 m², 248 m² e 355 m².\n\nÉ um projeto para quem valoriza amplitude, privacidade, lazer sofisticado e localização estratégica no eixo Cidade Jardim.\n\nQuer que eu te envie as plantas?' },
    { subject: 'Amanhã: apresentação do Château Jardin', body: '{{nome}}, tudo bem?\n\nAmanhã acontece a apresentação do Château Jardin, projeto Tegra e Exto inspirado na elegância dos jardins franceses.\n\nO empreendimento reúne áreas de lazer sofisticadas, paisagismo EDSA, tênis, padel, piscina coberta e opções amplas de 185 m² a 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nPosso verificar um horário para você?' },
    { subject: 'Château Jardin | Novo eixo Cidade Jardim', body: 'Olá, {{nome}}.\n\nEstou organizando os atendimentos do Château Jardin, lançamento no novo eixo Cidade Jardim.\n\nO projeto tem inspiração clássica, atmosfera de jardins franceses e plantas de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar os detalhes e entender qual metragem faz mais sentido para você?' },
    { subject: 'Conheça o Château Jardin', body: '{{nome}},\n\nO Château Jardin será lançado amanhã na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto de alto padrão, com proposta elegante, lazer completo e plantas amplas de 185 m² a 355 m².\n\nPosso te mandar as plantas e um resumo dos principais diferenciais?' },
    { subject: 'Château Jardin — convite de apresentação', body: 'Olá, {{nome}}, tudo bem?\n\nQuero te convidar para conhecer o Château Jardin, lançamento de alto padrão com inspiração nos jardins franceses, paisagismo internacional e metragens de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será amanhã, na Rua Ministro Nelson Hungria, 400.\n\nFaz sentido eu te enviar o material?' },
    { subject: 'Um novo projeto no eixo Cidade Jardim', body: '{{nome}},\n\nAmanhã será apresentado o Château Jardin, um projeto residencial de alto padrão no eixo Cidade Jardim.\n\nCom realização Tegra e Exto, o empreendimento traz arquitetura clássica, jardins, lazer sofisticado e plantas de 185 m² a 355 m².\n\nPosso te enviar mais detalhes?' },
    { subject: 'Château Jardin | Plantas amplas e lazer sofisticado', body: 'Olá, {{nome}}.\n\nO Château Jardin foi pensado para um público que busca amplitude, privacidade e sofisticação.\n\nAs plantas contemplam 185 m², 215 m², 248 m² e 355 m², com lazer de alto padrão e inspiração nos jardins franceses.\n\nO evento de apresentação será amanhã, na Rua Ministro Nelson Hungria, 400.\n\nQuer receber as plantas?' },
    { subject: 'Apresentação Château Jardin', body: '{{nome}}, tudo bem?\n\nAmanhã teremos a apresentação do Château Jardin, projeto Tegra e Exto com plantas de 185 m² a 355 m², arquitetura clássica e paisagismo internacional.\n\nPosso te enviar o material e verificar o melhor horário para você conhecer?' }
  ].map((item) => ({ subject: item.subject, body: item.body + signature }));

  const TEMPLATES = { whatsapp: WHATSAPP, ligacao: LIGACAO, email: EMAIL.map((e) => `Assunto: ${e.subject}\n\n${e.body}`) };

  function safeGet(key, fallback) { try { const value = localStorage.getItem(key); return value == null || value === '' ? fallback : value; } catch (_) { return fallback; } }
  function safeSet(key, value) { try { localStorage.setItem(key, String(value)); } catch (_) {} }
  function bodyText() { return document.body ? document.body.innerText || '' : ''; }
  function firstWord(value) { return String(value || '').trim().split(/\s+/)[0] || ''; }
  function normalizePhone(value) { const d = String(value || '').replace(/\D/g, ''); if (!d) return ''; if (d.length === 10 || d.length === 11) return `55${d}`; return d; }
  function getVariant() { return Number(runtimeVariant || safeGet(VARIANT_KEY, '0')) || 0; }
  function currentChannel() {
    const t = bodyText().toLowerCase();
    if (t.includes('whatsapp')) return 'whatsapp';
    if (t.includes('e-mail') || t.includes('email')) return 'email';
    return 'ligacao';
  }
  function getLeadName() {
    const tel = document.querySelector('a[href^="tel:"]');
    const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null;
    const title = card ? card.querySelector('h1,h2,h3,[class*="text-xl"],[class*="text-lg"],[class*="font-bold"]') : null;
    if (title && title.textContent.trim()) return firstWord(title.textContent.trim());
    const match = bodyText().match(/Mensagem sugerida\s+Oi,\s*([^,\n]+),/i);
    return firstWord(match ? match[1] : 'Cliente');
  }
  function getPhone() {
    const tel = document.querySelector('a[href^="tel:"]');
    if (tel) return normalizePhone(tel.getAttribute('href'));
    const m = bodyText().match(/(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?9?\d{4}[-\s]?\d{4}/);
    return m ? normalizePhone(m[0]) : '';
  }
  function getEmail() {
    const mail = document.querySelector('a[href^="mailto:"]');
    if (mail) return String(mail.getAttribute('href') || '').replace(/^mailto:/, '').trim();
    const m = bodyText().match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
    return m ? m[0] : '';
  }
  function getProfileFromBridge() {
    if (window.FECHAI_PME_CORRETOR_PROFILE) return window.FECHAI_PME_CORRETOR_PROFILE;
    try {
      const stored = JSON.parse(safeGet('fechai_pme_corretor_profile', 'null'));
      if (stored) return stored;
    } catch (_) {}
    return {};
  }
  function getCorretor() {
    const p = getProfileFromBridge();
    return p.nome || safeGet('fechai_corretor_nome', safeGet('fechai_pme_corretor_nome', 'Corretor responsável'));
  }
  function getCorretorPhone() {
    const p = getProfileFromBridge();
    return p.telefone || safeGet('fechai_corretor_telefone', safeGet('fechai_pme_corretor_telefone', 'telefone não configurado'));
  }
  function getCorretorWhatsapp() {
    const p = getProfileFromBridge();
    if (p.whatsapp) return p.whatsapp;
    const stored = safeGet('fechai_corretor_whatsapp', safeGet('fechai_pme_link_whatsapp_corretor', ''));
    if (stored) return stored;
    const phone = normalizePhone(getCorretorPhone());
    return phone ? `https://wa.me/${phone}` : 'WhatsApp não configurado';
  }

  function fill(text) {
    return String(text || '')
      .replaceAll('{{nome}}', getLeadName())
      .replaceAll('{{corretor}}', getCorretor())
      .replaceAll('{{telefone_corretor}}', getCorretorPhone())
      .replaceAll('{{link_whatsapp_corretor}}', getCorretorWhatsapp());
  }
  function pool() { return TEMPLATES[currentChannel()] || TEMPLATES.ligacao; }
  function currentText() {
    const list = pool();
    const index = ((getVariant() % list.length) + list.length) % list.length;
    return fill(list[index]);
  }
  function parseEmail(text) {
    const match = String(text || '').match(/^\s*Assunto:\s*([^\n]+)\n+/i);
    if (!match) return { subject: 'Château Jardin', body: String(text || '') };
    return { subject: match[1].trim(), body: String(text || '').slice(match[0].length).trim() };
  }
  async function copy(text) { try { await navigator.clipboard.writeText(text); return true; } catch (_) { window.prompt('Copie o texto:', text); return false; } }
  async function execute(text) {
    await copy(text);
    const channel = currentChannel();
    if (channel === 'whatsapp') {
      const phone = getPhone();
      window.open(phone ? `https://wa.me/${phone}?text=${encodeURIComponent(text)}` : `https://wa.me/?text=${encodeURIComponent(text)}`, '_blank', 'noopener,noreferrer');
      return;
    }
    if (channel === 'email') {
      const parts = parseEmail(text);
      window.location.href = `mailto:${encodeURIComponent(getEmail())}?subject=${encodeURIComponent(parts.subject)}&body=${encodeURIComponent(parts.body)}`;
      return;
    }
    const phone = getPhone();
    if (phone) window.location.href = `tel:${phone}`;
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `
      #${ROOT_ID} .pme-text{max-height:calc(1.55em * 3);overflow-y:auto;padding-right:6px;scrollbar-width:thin;}
      #${ROOT_ID} .pme-inline-mode-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;align-items:stretch;margin:10px auto 8px;max-width:620px;}
      #${ROOT_ID} .pme-inline-hidden{display:none!important;}
      #${ROOT_ID} .pme-inline-dev-note{grid-column:1/-1;font-size:12px;color:#64748b;font-weight:800;text-align:center;margin:0 auto;line-height:1.35;max-width:680px;}
      #${ROOT_ID} [data-pme-inline-mode],#${ROOT_ID} [data-pme-inline-development]{touch-action:manipulation;}
      @media(max-width:700px){#${ROOT_ID} .pme-text{max-height:calc(1.55em * 5);}#${ROOT_ID} .pme-inline-mode-grid{grid-template-columns:1fr 1fr;gap:8px;}}
    `;
    document.head.appendChild(style);
  }

  function findAssistantRoot() {
    return document.getElementById(ROOT_ID) || Array.from(document.querySelectorAll('div')).find((el) => /Mensagem sugerida|Executar contato|Origem do lead/i.test(el.innerText || ''));
  }

  function validateNoBlockedTerms(text) {
    const low = String(text || '').toLowerCase();
    const found = BLOCKED_TERMS.filter((term) => low.includes(term));
    return found;
  }

  function render() {
    ensureStyle();
    const root = findAssistantRoot();
    if (!root) return;
    root.id = ROOT_ID;

    let box = root.querySelector('[data-pme-empreendimentos-inline="1"]');
    if (!box) {
      box = document.createElement('div');
      box.setAttribute('data-pme-empreendimentos-inline', '1');
      root.insertBefore(box, root.firstChild);
    }

    const dev = DEVELOPMENTS[runtimeDevelopment] || DEVELOPMENTS.chateau_jardin;
    const text = currentText();
    const blocked = validateNoBlockedTerms(text);

    box.innerHTML = `
      <div class="pme-inline-mode-grid">
        <button type="button" data-pme-inline-mode="origem" class="${runtimeMode === 'origem' ? '' : 'pme-inline-hidden'}" style="padding:10px 12px;border-radius:14px;border:1px solid #dbeafe;background:#eff6ff;color:#1d4ed8;font-weight:800;">Origem do lead</button>
        <button type="button" data-pme-inline-mode="empreendimento" style="padding:10px 12px;border-radius:14px;border:1px solid ${runtimeMode === 'empreendimento' ? '#7c3aed' : '#e5e7eb'};background:${runtimeMode === 'empreendimento' ? '#f5f3ff' : '#fff'};color:${runtimeMode === 'empreendimento' ? '#6d28d9' : '#374151'};font-weight:800;">Empreendimentos</button>
        ${runtimeMode === 'empreendimento' ? `<button type="button" data-pme-inline-development="chateau_jardin" style="padding:10px 12px;border-radius:14px;border:1px solid #c4b5fd;background:#f5f3ff;color:#5b21b6;font-weight:900;">${dev.icon} ${dev.label}</button><div class="pme-inline-dev-note">${SITUATIONS[runtimeSituation]} · ${dev.hint}</div>` : ''}
      </div>
      ${runtimeMode === 'empreendimento' ? `<div style="margin:8px 0 12px;padding:12px;border:1px solid #e9d5ff;background:#faf5ff;border-radius:14px;">
        <div style="font-size:12px;color:#7e22ce;font-weight:900;margin-bottom:4px;">Mensagem sugerida — ${dev.label}</div>
        <div class="pme-text" style="font-size:13px;color:#374151;white-space:pre-line;line-height:1.55;">${escapeHtml(text)}</div>
        ${blocked.length ? `<div style="margin-top:8px;color:#b91c1c;font-size:12px;font-weight:800;">⚠ Termos bloqueados detectados: ${blocked.map(escapeHtml).join(', ')}</div>` : ''}
        <button type="button" data-pme-execute-empreendimento="1" style="margin-top:10px;width:100%;padding:11px 12px;border-radius:14px;border:none;background:#7c3aed;color:#fff;font-weight:900;">Executar contato</button>
      </div>` : ''}
    `;

    root.querySelectorAll('[data-pme-inline-mode]').forEach((btn) => {
      btn.onclick = () => {
        runtimeMode = btn.getAttribute('data-pme-inline-mode');
        safeSet(MODE_KEY, runtimeMode);
        render();
      };
    });
    root.querySelectorAll('[data-pme-inline-development]').forEach((btn) => {
      btn.onclick = () => {
        runtimeMode = 'empreendimento';
        runtimeDevelopment = btn.getAttribute('data-pme-inline-development') || 'chateau_jardin';
        safeSet(MODE_KEY, runtimeMode);
        safeSet(DEVELOPMENT_KEY, runtimeDevelopment);
        render();
      };
    });
    const executeBtn = root.querySelector('[data-pme-execute-empreendimento]');
    if (executeBtn) executeBtn.onclick = () => execute(currentText());
  }

  function escapeHtml(value) {
    return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function boot() {
    const now = Date.now();
    if (now - lastInlineHandledAt < 150) return;
    lastInlineHandledAt = now;
    render();
  }

  window.addEventListener('fechai:pme-corretor-profile-ready', boot);
  setInterval(boot, 1000);
  setTimeout(boot, 250);
  setTimeout(boot, 1000);
})();
