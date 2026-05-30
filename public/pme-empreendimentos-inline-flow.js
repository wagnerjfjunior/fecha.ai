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

  const WA_BASES = [
    ['Olá, {{nome_lead}}, tudo bem?', 'Amanhã será o lançamento do Château Jardin.', 'O projeto fica no novo eixo Cidade Jardim e foi inspirado na elegância dos jardins franceses.', 'Tem plantas de 185 m², 215 m², 248 m² e 355 m².', 'Posso te enviar o material com plantas e detalhes do evento?'],
    ['{{nome_lead}}, tudo bem?', 'Amanhã acontece o lançamento do Château Jardin.', 'É um projeto Tegra e Exto com arquitetura clássica, leitura contemporânea e paisagismo internacional EDSA.', 'As metragens vão de 185 m² a 355 m².', 'Quer que eu te envie as plantas para avaliar com calma?'],
    ['Olá, {{nome_lead}}.', 'Amanhã será apresentado o Château Jardin na Rua Ministro Nelson Hungria, 400.', 'O projeto combina inspiração nos jardins franceses, lazer de alto padrão e plantas generosas.', 'As opções são 185 m², 215 m², 248 m² e 355 m².', 'Posso te mandar um resumo com as plantas?'],
    ['{{nome_lead}}, amanhã teremos o lançamento do Château Jardin.', 'É um projeto pensado para quem busca alto padrão, elegância atemporal e uma experiência residencial mais reservada.', 'As plantas contemplam 185 m², 215 m², 248 m² e 355 m².', 'Faz sentido eu te enviar o material agora?'],
    ['Olá, {{nome_lead}}, tudo bem?', 'Amanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.', 'O projeto reúne arquitetura clássica, paisagismo internacional EDSA, lazer de perfil private club e plantas de 185 m² a 355 m².', 'Quer receber as informações iniciais?'],
    ['{{nome_lead}}, estou organizando os atendimentos do lançamento do Château Jardin.', 'O evento será amanhã, na Rua Ministro Nelson Hungria, 400.', 'O empreendimento tem inspiração nos jardins franceses e metragens de 185 m², 215 m², 248 m² e 355 m².', 'Posso te mandar as opções?'],
    ['Olá, {{nome_lead}}.', 'Amanhã é o lançamento do Château Jardin, projeto Tegra e Exto no novo eixo Cidade Jardim.', 'É um refúgio urbano com arquitetura clássica, paisagismo internacional EDSA, quadra de tênis de saibro, padel, piscina coberta e wellness.', 'Posso te enviar o material?'],
    ['{{nome_lead}}, tudo bem?', 'Amanhã teremos o evento de lançamento do Château Jardin.', 'O projeto foi pensado para quem busca alto padrão, elegância e plantas amplas.', 'O evento será na Rua Ministro Nelson Hungria, 400.', 'Quer que eu te envie os detalhes?'],
    ['Olá, {{nome_lead}}.', 'O Château Jardin será lançado amanhã no novo eixo Cidade Jardim.', 'É um projeto com inspiração clássica, atmosfera de jardins franceses, lazer sofisticado e assinatura Tegra e Exto.', 'As plantas contemplam 185 m², 215 m², 248 m² e 355 m².', 'Posso te mandar o material?'],
    ['{{nome_lead}}, passando rapidamente para te apresentar o Château Jardin.', 'O lançamento será amanhã.', 'É um projeto de alto padrão com arquitetura clássica, paisagismo internacional e metragens amplas de 185 m² a 355 m².', 'Posso te enviar as plantas?'],
    ['Olá, {{nome_lead}}, tudo bem?', 'Amanhã será o lançamento do Château Jardin, um projeto que une o clássico e o contemporâneo no novo eixo Cidade Jardim.', 'Inspirado na elegância dos jardins franceses, traz plantas de 185 m², 215 m², 248 m² e 355 m².', 'Quer conhecer o material?'],
    ['{{nome_lead}}, amanhã teremos a apresentação do Château Jardin.', 'A proposta combina jardins, lazer de alto padrão, arquitetura clássica e unidades amplas de 185 m² a 355 m².', 'Posso te enviar as informações pelo WhatsApp?'],
    ['Olá, {{nome_lead}}.', 'O lançamento do Château Jardin será amanhã, na Rua Ministro Nelson Hungria, 400.', 'É um projeto no novo eixo Cidade Jardim, com inspiração clássica, paisagismo sofisticado e opções de 185 m² a 355 m².', 'Posso te mandar as plantas e diferenciais?'],
    ['{{nome_lead}}, tudo bem?', 'Estou te chamando porque amanhã será o lançamento do Château Jardin.', 'O projeto tem uma proposta elegante, inspirada no clássico e nos jardins franceses, com lazer completo e metragens de 185 m² a 355 m².', 'Faz sentido eu te enviar o material?'],
    ['Olá, {{nome_lead}}.', 'Amanhã acontece o evento de lançamento do Château Jardin, realização Tegra e Exto.', 'O empreendimento fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².', 'Quer que eu te envie os detalhes?'],
    ['{{nome_lead}}, amanhã será o lançamento do Château Jardin.', 'É um projeto residencial de alto padrão na Rua Ministro Nelson Hungria, 400.', 'Ele combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional, tênis, padel, piscina coberta e wellness.', 'Posso te mandar o material?'],
    ['Olá, {{nome_lead}}, tudo bem?', 'O Château Jardin será lançado amanhã e estou organizando os atendimentos por horário.', 'O projeto tem plantas de 185 m², 215 m², 248 m² e 355 m², com lazer sofisticado e proposta de refúgio urbano.', 'Posso te enviar as plantas?'],
    ['{{nome_lead}}, passando para te avisar sobre o lançamento do Château Jardin amanhã.', 'É um projeto Tegra e Exto, com paisagismo internacional EDSA, inspiração nos jardins franceses e uma estrutura de lazer diferenciada.', 'Posso te enviar um resumo?'],
    ['Olá, {{nome_lead}}.', 'Amanhã teremos o lançamento do Château Jardin, um projeto que nasce como um novo marco residencial no eixo Cidade Jardim.', 'São plantas amplas de 185 m², 215 m², 248 m² e 355 m², com arquitetura clássica e lazer de alto padrão.', 'Quer receber o material?'],
    ['{{nome_lead}}, tudo bem?', 'Amanhã será o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.', 'É um projeto de alto padrão inspirado no clássico, nos jardins franceses e em uma experiência residencial mais reservada.', 'Temos opções de 185 m² a 355 m².', 'Posso te mandar as informações?']
  ];

  const CALL_BASES = [
    ['Oi, {{nome_lead}}, tudo bem?', 'Aqui é {{nome_corretor}} da Tegra.', 'Estou te ligando rapidamente porque amanhã será o lançamento do Château Jardin.', 'É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado no clássico e nos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².', 'Faz sentido eu te enviar o material e verificar um horário para você conhecer?'],
    ['{{nome_lead}}, tudo bem?', 'Aqui é {{nome_corretor}} da Tegra.', 'Amanhã teremos o lançamento do Château Jardin.', 'O projeto une arquitetura clássica, olhar contemporâneo, paisagismo internacional EDSA, tênis de saibro, padel, piscina coberta e wellness.', 'Posso te mandar as plantas e entender se alguma metragem faz sentido para você?'],
    ['Oi, {{nome_lead}}, aqui é {{nome_corretor}} da Tegra.', 'Vou ser breve.', 'Amanhã acontece o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.', 'É um projeto sofisticado, com inspiração nos jardins franceses, plantas amplas de 185 m² a 355 m² e uma proposta residencial reservada.', 'Você busca algo nesse perfil ou prefere apenas receber o material para avaliar?'],
    ['{{nome_lead}}, tudo bem?', 'Estou entrando em contato pela Tegra porque amanhã será o evento de lançamento do Château Jardin.', 'O projeto fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².', 'Posso te enviar um resumo com plantas e principais diferenciais?'],
    ['Oi, {{nome_lead}}, tudo bem?', 'Aqui é {{nome_corretor}} da Tegra.', 'Amanhã vamos apresentar o Château Jardin.', 'É um produto para quem busca alto padrão, conforto, arquitetura clássica e plantas generosas.', 'Você gostaria de conhecer as opções ou prefere que eu envie primeiro pelo WhatsApp?'],
    ['{{nome_lead}}, tudo bem?', 'Estou te ligando porque amanhã teremos o lançamento do Château Jardin.', 'O projeto tem lazer de perfil private club, com tênis de saibro, padel, piscina coberta, wellness e áreas sociais completas.', 'As metragens vão de 185 m² a 355 m².', 'Posso te passar o material?'],
    ['Oi, {{nome_lead}}, aqui é {{nome_corretor}} da Tegra.', 'Amanhã será o lançamento do Château Jardin.', 'O projeto tem uma proposta elegante: arquitetura clássica, jardins, serviços de alto padrão e plantas amplas.', 'Você está buscando imóvel para morar, investir ou apenas avaliando oportunidades nesse perfil?'],
    ['{{nome_lead}}, tudo bem?', 'Vou falar rapidinho.', 'Amanhã teremos o lançamento do Château Jardin, realização Tegra e Exto.', 'O empreendimento foi pensado como um refúgio urbano no novo eixo Cidade Jardim, com metragens de 185 m² a 355 m².', 'Posso te enviar as plantas para você avaliar com calma?'],
    ['Oi, {{nome_lead}}, aqui é {{nome_corretor}} da Tegra.', 'Amanhã acontece o evento de lançamento do Château Jardin.', 'É um projeto com inspiração clássica, atmosfera de jardins franceses, paisagismo EDSA e uma estrutura de lazer diferenciada.', 'Se fizer sentido para você, posso te mandar o material e verificar um horário de apresentação.'],
    ['{{nome_lead}}, tudo bem?', 'Estou te ligando sobre o Château Jardin, que será lançado amanhã.', 'É um projeto de alto padrão com opções de 185 m² a 355 m², lazer completo e proposta residencial sofisticada.', 'Você teria interesse em receber as informações iniciais ou prefere agendar para conhecer presencialmente?']
  ];

  const EMAIL_BASES = [
    ['Château Jardin | Lançamento amanhã', ['Olá, {{nome_lead}}, tudo bem?', 'Amanhã será o lançamento do Château Jardin, projeto de alto padrão no novo eixo Cidade Jardim, com realização Tegra e Exto.', 'Inspirado na arquitetura clássica e na elegância dos jardins franceses, o empreendimento reúne paisagismo internacional EDSA, lazer sofisticado e plantas amplas de 185 m², 215 m², 248 m² e 355 m².', 'Posso te enviar as plantas e verificar um horário de apresentação?']],
    ['Château Jardin | Novo marco no eixo Cidade Jardim', ['Olá, {{nome_lead}}.', 'Estou compartilhando o Château Jardin, lançamento que será apresentado amanhã.', 'O projeto une arquitetura clássica, olhar contemporâneo, inspiração nos jardins franceses e paisagismo internacional assinado pela EDSA.', 'As opções contemplam plantas de 185 m², 215 m², 248 m² e 355 m².', 'Caso faça sentido para você, posso encaminhar o material completo e organizar uma visita.']],
    ['Amanhã | Evento de lançamento Château Jardin', ['Olá, {{nome_lead}}, tudo bem?', 'Amanhã acontece o evento de lançamento do Château Jardin, empreendimento Tegra e Exto no novo eixo Cidade Jardim.', 'O projeto foi pensado como um refúgio urbano sofisticado, com inspiração clássica, atmosfera de jardins franceses, lazer de alto padrão, quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.', 'Posso te enviar plantas e detalhes do evento?']],
    ['Château Jardin | Plantas de 185 m² a 355 m²', ['Olá, {{nome_lead}}.', 'Amanhã será o lançamento do Château Jardin.', 'O empreendimento traz uma proposta residencial elegante, com arquitetura clássica, paisagismo internacional EDSA e inspiração nos jardins franceses.', 'As plantas incluem opções de 185 m², 215 m², 248 m² e 355 m².', 'Posso te enviar o material?']],
    ['Convite | Château Jardin', ['Olá, {{nome_lead}}, tudo bem?', 'Gostaria de te apresentar o Château Jardin, lançamento de alto padrão que será apresentado amanhã no novo eixo Cidade Jardim.', 'Com realização Tegra e Exto, o projeto combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e uma estrutura de lazer com perfil de private club.', 'Se fizer sentido, posso te enviar as plantas e detalhes das metragens.']],
    ['Château Jardin | Alto padrão no Cidade Jardim', ['Olá, {{nome_lead}}.', 'Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão.', 'O projeto reúne a assinatura Tegra e Exto, paisagismo internacional EDSA, inspiração clássica e metragens amplas de 185 m² a 355 m².', 'A proposta é oferecer uma experiência residencial sofisticada, com lazer completo e serviços pensados para o dia a dia.', 'Posso te enviar o material?']],
    ['Château Jardin | Alto padrão no novo eixo Cidade Jardim', ['Olá, {{nome_lead}}, tudo bem?', 'O Château Jardin será lançado amanhã e nasce como uma proposta residencial sofisticada no novo eixo Cidade Jardim.', 'Inspirado no clássico e na elegância dos jardins franceses, o projeto conta com paisagismo internacional, quadra de tênis de saibro, padel, piscina coberta, wellness e plantas de 185 m², 215 m², 248 m² e 355 m².', 'Caso queira, posso encaminhar as plantas e principais diferenciais.']],
    ['Conheça o Château Jardin', ['Olá, {{nome_lead}}.', 'Amanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.', 'O empreendimento foi concebido com arquitetura clássica, leitura contemporânea e inspiração nos jardins franceses, trazendo metragens amplas e lazer completo para uma experiência residencial reservada.', 'Posso te enviar o material completo com plantas e diferenciais?']],
    ['Château Jardin | Lançamento de alto padrão', ['Olá, {{nome_lead}}, tudo bem?', 'Estou te enviando o Château Jardin, lançamento que será apresentado amanhã.', 'O projeto une sofisticação, inspiração clássica, paisagismo internacional EDSA e lazer de alto padrão, com quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.', 'As plantas contemplam metragens de 185 m², 215 m², 248 m² e 355 m².', 'Fico à disposição para te enviar o material e organizar uma apresentação.']],
    ['Château Jardin | Apresentação amanhã', ['Olá, {{nome_lead}}.', 'Amanhã teremos o evento de lançamento do Château Jardin.', 'É um projeto Tegra e Exto, no novo eixo Cidade Jardim, inspirado na elegância clássica e nos jardins franceses, com paisagismo internacional e plantas amplas de 185 m² a 355 m².', 'Se fizer sentido para você, posso enviar o material com plantas, metragens e detalhes do empreendimento.']]
  ];

  const WHATSAPP = WA_BASES.map((parts) => composeWhatsApp(parts));
  const LIGACAO = CALL_BASES.map((parts) => composeCallScript(parts));
  const EMAIL = EMAIL_BASES.map(([subject, parts]) => composeEmail(subject, parts));
  const TEMPLATES = { whatsapp: WHATSAPP, ligacao: LIGACAO, email: EMAIL };

  function composeWhatsApp(parts) {
    return [...parts, receptionBlock()].join('\n\n');
  }
  function composeEmail(subject, parts) {
    return `Assunto: ${subject}\n\n${[...parts, 'O evento será na Rua Ministro Nelson Hungria, 400.', receptionBlock(), contactBlock()].join('\n\n')}`;
  }
  function composeCallScript(parts) {
    const [opening, identification, context, value, question] = parts;
    return [
      'SCRIPT DE LIGAÇÃO — Château Jardin',
      'Objetivo: abrir conversa, apresentar o lançamento e conduzir para envio de material ou visita presencial.',
      `Abertura: ${opening || ''}`,
      `Identificação: ${identification || 'Aqui é {{nome_corretor}} da Tegra.'}`,
      `Contexto: ${context || ''}`,
      `Valor percebido: ${value || ''}`,
      `Pergunta de avanço: ${question || 'Posso te enviar o material e verificar o melhor horário para apresentação?'}`,
      `Fechamento: O evento será na Rua Ministro Nelson Hungria, 400. Ao chegar, solicite por {{nome_corretor}} na recepção.`
    ].join('\n\n');
  }
  function receptionBlock() {
    return 'Ao chegar, solicite por {{nome_corretor}} da Tegra na recepção.';
  }
  function contactBlock() {
    return 'Contato: {{telefone_corretor}}\nWhatsApp: {{link_whatsapp}}';
  }

  function safeGet(key, fallback) { try { return localStorage.getItem(key) || fallback; } catch (_) { return fallback; } }
  function safeSet(key, value) { try { localStorage.setItem(key, String(value)); } catch (_) {} }
  function getMode() { return runtimeMode === 'empreendimentos' ? 'empreendimentos' : 'origem'; }
  function setMode(mode) { runtimeMode = mode === 'empreendimentos' ? 'empreendimentos' : 'origem'; safeSet(MODE_KEY, runtimeMode); runtimeVariant = 0; safeSet(VARIANT_KEY, '0'); }
  function getSituation() { return SITUATIONS[runtimeSituation] ? runtimeSituation : 'convite_lancamento'; }
  function setSituation(value) { runtimeSituation = SITUATIONS[value] ? value : 'convite_lancamento'; safeSet(SITUATION_KEY, runtimeSituation); runtimeVariant = 0; safeSet(VARIANT_KEY, '0'); }
  function getVariant() { return Number(runtimeVariant) || 0; }
  function setVariant(value) { runtimeVariant = Number(value) || 0; safeSet(VARIANT_KEY, String(runtimeVariant)); }
  function getDevelopment() { return DEVELOPMENTS[runtimeDevelopment] ? runtimeDevelopment : 'chateau_jardin'; }
  function setDevelopment(value) { runtimeDevelopment = DEVELOPMENTS[value] ? value : 'chateau_jardin'; safeSet(DEVELOPMENT_KEY, runtimeDevelopment); runtimeVariant = 0; safeSet(VARIANT_KEY, '0'); }
  function escapeHtml(text) { return String(text || '').replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#039;'); }
  function normalizePhone(value) { return String(value || '').replace(/\D/g, ''); }
  function firstWord(text) { return String(text || 'Cliente').trim().split(/\s+/)[0] || 'Cliente'; }
  function bodyText() { return String(document.body?.innerText || ''); }
  function root() { return document.getElementById(ROOT_ID); }
  function targetClosest(event, selector) { const target = event && event.target; return target && typeof target.closest === 'function' ? target.closest(selector) : null; }
  function currentChannel() { return root()?.querySelector('[data-pme-channel].active')?.getAttribute('data-pme-channel') || safeGet('fechai_pme_channel', 'ligacao'); }

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
  function getHeaderUserName() {
    const names = Array.from(document.querySelectorAll('h1,h2,h3,strong,[class*="font-bold"]')).map((el) => String(el.textContent || '').trim()).filter(Boolean);
    const candidate = names.find((text) => /\bCorretor\b/i.test(text)) || names.find((text) => /^Wagner\b/i.test(text));
    return candidate ? candidate.replace(/\bCorretor\b/ig, '').trim() : '';
  }
  function getCorretor() {
    return safeGet('fechai_corretor_nome',
      safeGet('fechai_pme_corretor_nome',
        safeGet('nome_corretor',
          safeGet('corretor_nome', getHeaderUserName() || 'Corretor responsável'))));
  }
  function getCorretorPhone() {
    return safeGet('fechai_corretor_telefone',
      safeGet('fechai_pme_corretor_telefone',
        safeGet('telefone_corretor',
          safeGet('corretor_telefone', 'telefone não configurado'))));
  }
  function getCorretorWhatsapp() {
    const stored = safeGet('fechai_corretor_whatsapp', safeGet('fechai_pme_link_whatsapp_corretor', safeGet('link_whatsapp', '')));
    if (stored) return stored;
    const phone = normalizePhone(getCorretorPhone());
    return phone ? `https://wa.me/${phone}` : 'WhatsApp não configurado';
  }

  function fill(text) {
    const data = {
      nome_lead: getLeadName(),
      nome_corretor: getCorretor(),
      corretor: getCorretor(),
      telefone_corretor: getCorretorPhone(),
      link_whatsapp: getCorretorWhatsapp(),
      link_whatsapp_corretor: getCorretorWhatsapp(),
      empreendimento: DEVELOPMENTS[getDevelopment()]?.label || 'Château Jardin'
    };
    return formatReadable(String(text || '').replace(/{{\s*([^}]+)\s*}}/g, (_, key) => data[String(key).trim()] || ''));
  }
  function formatReadable(text) {
    const lines = String(text || '').split('\n');
    const out = [];
    lines.forEach((line) => {
      const trimmed = line.trim();
      if (!trimmed) return;
      if (/^(Assunto:|SCRIPT DE LIGAÇÃO|Objetivo:|Abertura:|Identificação:|Contexto:|Valor percebido:|Pergunta de avanço:|Fechamento:|Contato:|WhatsApp:)/i.test(trimmed)) {
        out.push(trimmed);
        return;
      }
      trimmed.split(/(?<=[.!?])\s+(?=[A-ZÀ-Ú0-9])/g).forEach((part) => {
        const p = part.trim();
        if (p) out.push(p);
      });
    });
    return out.join('\n\n').replace(/\n{3,}/g, '\n\n').trim();
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
  async function copy(text) {
    try { await navigator.clipboard.writeText(text); return true; }
    catch (_) { window.prompt('Copie o texto:', text); return false; }
  }
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
      #${ROOT_ID} .pme-text{max-height:calc(1.55em * 3);overflow-y:auto;padding-right:6px;scrollbar-width:thin;white-space:pre-line;}
      #${ROOT_ID} .pme-inline-mode-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;align-items:stretch;margin:10px auto 8px;max-width:620px;}
      #${ROOT_ID} .pme-inline-hidden{display:none!important;}
      #${ROOT_ID} .pme-inline-dev-note{grid-column:1/-1;font-size:12px;color:#64748b;font-weight:800;text-align:center;margin:0 auto;line-height:1.35;max-width:680px;}
      #${ROOT_ID} [data-pme-inline-mode],#${ROOT_ID} [data-pme-inline-development]{touch-action:manipulation;}
      @media(max-width:700px){#${ROOT_ID} .pme-text{max-height:calc(1.55em * 5);}#${ROOT_ID} .pme-inline-mode-grid{grid-template-columns:1fr 1fr;gap:8px;}}
    `;
    document.head.appendChild(style);
  }

  function findStepTitleContaining(text) {
    const r = root();
    if (!r) return null;
    return Array.from(r.querySelectorAll('.pme-step-title')).find((el) => String(el.textContent || '').includes(text)) || null;
  }
  function sectionBetween(startTitle, endTitle) {
    if (!startTitle) return [];
    const out = [];
    let node = startTitle.nextElementSibling;
    while (node && node !== endTitle) { out.push(node); node = node.nextElementSibling; }
    return out;
  }
  function createModeGrid(mode) {
    const div = document.createElement('div');
    div.className = 'pme-inline-mode-grid';
    div.setAttribute('data-pme-inline-mode-grid', '1');
    div.innerHTML = `<button type="button" class="pme-pill ${mode === 'origem' ? 'active' : ''}" data-pme-inline-mode="origem">🎯 Origem do lead</button><button type="button" class="pme-pill ${mode === 'empreendimentos' ? 'active' : ''}" data-pme-inline-mode="empreendimentos">🏛️ Empreendimentos</button>`;
    return div;
  }
  function createDevelopmentGrid() {
    const active = getDevelopment();
    const div = document.createElement('div');
    div.className = 'pme-origin-grid';
    div.setAttribute('data-pme-inline-development-grid', '1');
    div.innerHTML = Object.entries(DEVELOPMENTS).map(([key, item]) => `<button type="button" class="pme-pill ${key === active ? 'active' : ''}" data-pme-inline-development="${escapeHtml(key)}">${escapeHtml(item.icon + ' ' + item.label)}</button>`).join('') + `<div class="pme-inline-dev-note">${escapeHtml(DEVELOPMENTS[active]?.hint || '')} Endereço: ${escapeHtml(DEVELOPMENTS[active]?.address || '')}</div>`;
    return div;
  }
  function createSituationSelect() {
    const wrap = document.createElement('div');
    wrap.className = 'pme-select-wrap';
    wrap.setAttribute('data-pme-inline-situation-wrap', '1');
    wrap.innerHTML = `<select class="pme-select" data-pme-inline-situation aria-label="Escolha em qual situação o cliente está">${Object.entries(SITUATIONS).map(([key, label]) => `<option value="${escapeHtml(key)}" ${key === getSituation() ? 'selected' : ''}>${escapeHtml(label)}</option>`).join('')}</select>`;
    return wrap;
  }

  function renderReplacementRows(r, originTitle, channelTitle, mode) {
    const existingDev = r.querySelector('[data-pme-inline-development-grid]');
    if (existingDev) existingDev.remove();
    const sectionNodes = sectionBetween(originTitle, channelTitle);
    sectionNodes.forEach((el) => {
      if (el.matches('[data-pme-inline-mode-grid]')) return;
      if (el.classList.contains('pme-step-help')) return;
      if (mode === 'empreendimentos') el.classList.add('pme-inline-hidden');
      else el.classList.remove('pme-inline-hidden');
    });
    if (mode === 'empreendimentos') channelTitle.insertAdjacentElement('beforebegin', createDevelopmentGrid());
  }

  function patch() {
    const r = root();
    if (!r) return;
    ensureStyle();
    const mode = getMode();
    const originTitle = findStepTitleContaining('Escolha a origem');
    const channelTitle = findStepTitleContaining('Escolha o canal');
    const situationTitle = findStepTitleContaining('Escolha em qual situação');
    if (!originTitle || !channelTitle || !situationTitle) return;
    const headerTitle = r.querySelector('.pme-title');
    const headerSub = r.querySelector('.pme-sub');
    const chip = r.querySelector('.pme-chip');
    if (headerTitle) headerTitle.textContent = 'Fluxo de atendimento';
    if (headerSub) headerSub.textContent = 'Siga os passos abaixo. Primeiro escolha a origem ou empreendimento, depois o canal, a situação e por fim execute o contato.';
    originTitle.textContent = '1. Escolha a origem ou empreendimento';
    let modeGrid = r.querySelector('[data-pme-inline-mode-grid]');
    if (modeGrid) modeGrid.remove();
    originTitle.insertAdjacentElement('afterend', createModeGrid(mode));
    const originHelp = sectionBetween(originTitle, channelTitle).find((el) => el.classList && el.classList.contains('pme-step-help'));
    if (originHelp) originHelp.textContent = mode === 'empreendimentos' ? 'Escolha qual empreendimento será trabalhado neste atendimento.' : 'Use Origem do lead para o fluxo padrão ou Empreendimentos para mensagens por projeto.';
    renderReplacementRows(r, originTitle, channelTitle, mode);
    channelTitle.textContent = '2. Escolha o canal para contato com o cliente';
    situationTitle.textContent = '3. Escolha em qual situação o cliente está';
    const oldSituation = r.querySelector('[data-pme="approach"]')?.closest('.pme-select-wrap');
    const inlineSituation = r.querySelector('[data-pme-inline-situation-wrap]');
    if (mode === 'empreendimentos') {
      if (oldSituation) oldSituation.classList.add('pme-inline-hidden');
      if (!inlineSituation && oldSituation) oldSituation.insertAdjacentElement('afterend', createSituationSelect());
    } else {
      if (oldSituation) oldSituation.classList.remove('pme-inline-hidden');
      if (inlineSituation) inlineSituation.remove();
    }
    const boxTitle = r.querySelector('.pme-box-title');
    const textEl = r.querySelector('.pme-text');
    if (boxTitle) boxTitle.textContent = 'Mensagem sugerida';
    if (mode === 'empreendimentos' && textEl) textEl.textContent = currentText();
    const channelLabel = r.querySelector('[data-pme-channel].active')?.textContent?.replace(/^[^A-Za-zÀ-ÿ0-9]+\s*/u, '').trim() || 'Canal';
    if (chip && mode === 'empreendimentos') chip.textContent = `${DEVELOPMENTS[getDevelopment()]?.label || 'Empreendimento'} · ${channelLabel}`;
    const status = r.querySelector('[data-pme-status]');
    if (status && mode === 'empreendimentos') {
      const blocked = BLOCKED_TERMS.some((term) => currentText().toLowerCase().includes(term.toLowerCase()));
      status.textContent = blocked ? 'Atenção: termo bloqueado detectado na mensagem. Revise antes de usar.' : 'Mensagem de empreendimento carregada. A PME não envia mensagem sozinha e não registra feedback automaticamente.';
    }
  }

  function stop(event) { event.preventDefault(); event.stopPropagation(); if (typeof event.stopImmediatePropagation === 'function') event.stopImmediatePropagation(); }
  function schedulePatch() { window.requestAnimationFrame(patch); window.setTimeout(patch, 30); window.setTimeout(patch, 150); }
  function handleInlineModeEvent(event) {
    const modeBtn = targetClosest(event, '[data-pme-inline-mode]');
    const devBtn = targetClosest(event, '[data-pme-inline-development]');
    if (!modeBtn && !devBtn) return false;
    stop(event);
    if (Date.now() - lastInlineHandledAt < 80 && event.type === 'click') return true;
    lastInlineHandledAt = Date.now();
    if (modeBtn) setMode(modeBtn.getAttribute('data-pme-inline-mode'));
    if (devBtn) setDevelopment(devBtn.getAttribute('data-pme-inline-development'));
    schedulePatch();
    return true;
  }
  function handleInlineActionEvent(event) {
    if (getMode() !== 'empreendimentos') return false;
    const actionBtn = targetClosest(event, '[data-pme-action]');
    if (!actionBtn || !root()?.contains(actionBtn)) return false;
    if (event.type === 'pointerdown') { stop(event); return true; }
    stop(event);
    const type = actionBtn.getAttribute('data-pme-action');
    if (type === 'next') setVariant(getVariant() + 1);
    if (type === 'prev') setVariant(getVariant() - 1);
    if (type === 'use') execute(currentText());
    if (type === 'ai') copy(currentText());
    schedulePatch();
    return true;
  }
  function bind() {
    ['pointerdown', 'pointerup', 'click'].forEach((eventName) => {
      document.addEventListener(eventName, function (event) {
        if (handleInlineModeEvent(event)) return;
        if (eventName !== 'pointerdown') handleInlineActionEvent(event);
        else if (getMode() === 'empreendimentos' && targetClosest(event, '[data-pme-action]')) handleInlineActionEvent(event);
      }, true);
    });
    document.addEventListener('change', function (event) {
      const select = targetClosest(event, '[data-pme-inline-situation]');
      if (!select) return;
      stop(event);
      setSituation(select.value);
      schedulePatch();
    }, true);
  }

  function start() {
    bind();
    patch();
    const observer = new MutationObserver(() => window.requestAnimationFrame(patch));
    observer.observe(document.body, { childList: true, subtree: true });
    window.setInterval(patch, 1000);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
