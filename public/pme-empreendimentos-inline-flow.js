/*
 * FECH.AI — PME Empreendimentos Inline Flow
 * Version: 0.1.4
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
  const PROFILE_KEY = 'fechai_pme_corretor_profile';

  let runtimeMode = safeGet(MODE_KEY, 'origem');
  let runtimeDevelopment = safeGet(DEVELOPMENT_KEY, 'chateau_jardin');
  let runtimeSituation = safeGet(SITUATION_KEY, 'convite_lancamento');
  let runtimeVariant = Number(safeGet(VARIANT_KEY, '0')) || 0;
  let lastInlineHandledAt = 0;
  let lastActionHandledAt = 0;
  let patchQueued = false;
  let profileCache = readStoredProfile();

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

  const signature = '\n\n{{corretor}} — {{telefone_corretor}}\nWhatsApp: {{link_whatsapp_corretor}}\n\nNa recepção, solicite por {{corretor}} da {{empresa}}.';
  const callClose = '\n\nO evento será na Rua Ministro Nelson Hungria, 400. Na recepção, solicite por {{corretor}} da {{empresa}} para que eu possa te receber pessoalmente e apresentar o projeto com calma.';

  const WHATSAPP_BASE = [
    `Olá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado na elegância dos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar o material com plantas e detalhes do evento?`,
    `{{nome}}, tudo bem?\n\nAmanhã acontece o lançamento do Château Jardin, um projeto de alto padrão no novo eixo Cidade Jardim.\n\nO empreendimento une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e metragens amplas de 185 m² a 355 m².\n\nQuer que eu te envie as plantas para avaliar com calma?`,
    `Olá, {{nome}}.\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. 📍\n\nÉ um projeto Tegra e Exto, com inspiração nos jardins franceses, lazer de alto padrão e opções de 185 m², 215 m², 248 m² e 355 m². 📐\n\nPosso te mandar um resumo com as plantas?`,
    `{{nome}}, amanhã teremos o lançamento do Château Jardin.\n\nÉ um projeto inspirado no clássico, nos jardins franceses e em uma forma mais elegante de viver, no novo eixo Cidade Jardim.\n\nAs opções contemplam 185 m², 215 m², 248 m² e 355 m².\n\nFaz sentido eu te enviar o material agora?`,
    `Olá, {{nome}}, tudo bem?\n\nAmanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.\n\nO projeto reúne arquitetura clássica, paisagismo internacional EDSA, lazer de perfil private club e plantas generosas de 185 m² a 355 m².\n\nQuer receber as informações iniciais?`,
    `{{nome}}, estou organizando os atendimentos do lançamento do Château Jardin, que acontece amanhã na Rua Ministro Nelson Hungria, 400. 🗓️\n\nO empreendimento tem inspiração na elegância dos jardins franceses e plantas de 185 m², 215 m², 248 m² e 355 m². 🌿\n\nPosso te mandar as opções?`,
    `Olá, {{nome}}.\n\nAmanhã é o lançamento do Château Jardin, projeto Tegra e Exto no novo eixo Cidade Jardim.\n\nUm refúgio urbano com arquitetura clássica, paisagismo internacional EDSA, quadra de tênis de saibro, padel, piscina coberta e metragens de 185 m² a 355 m².\n\nPosso te enviar o material?`,
    `{{nome}}, tudo bem?\n\nAmanhã teremos o evento de lançamento do Château Jardin.\n\nO projeto foi pensado para quem busca alto padrão, elegância atemporal e plantas amplas, com opções de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nQuer que eu te envie os detalhes?`,
    `Olá, {{nome}}.\n\nO Château Jardin será lançado amanhã no novo eixo Cidade Jardim.\n\nÉ um projeto com inspiração clássica, atmosfera de jardins franceses, lazer sofisticado e assinatura Tegra e Exto. 🏛️\n\nAs plantas contemplam 185 m², 215 m², 248 m² e 355 m². 📐\n\nPosso te mandar o material?`,
    `{{nome}}, passando rapidamente para te apresentar o Château Jardin, que terá evento de lançamento amanhã.\n\nÉ um projeto de alto padrão na Rua Ministro Nelson Hungria, 400, com arquitetura clássica, paisagismo internacional e metragens amplas de 185 m² a 355 m².\n\nPosso te enviar as plantas?`,
    `Olá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, um projeto que une o clássico e o contemporâneo no novo eixo Cidade Jardim.\n\nInspirado na elegância dos jardins franceses, traz plantas de 185 m², 215 m², 248 m² e 355 m².\n\nQuer conhecer o material?`,
    `{{nome}}, amanhã teremos a apresentação do Château Jardin, empreendimento Tegra e Exto com projeto internacional EDSA.\n\nA proposta combina jardins, lazer de alto padrão, arquitetura clássica e unidades amplas de 185 m² a 355 m². 🌿\n\nPosso te enviar as informações pelo WhatsApp?`,
    `Olá, {{nome}}.\n\nO lançamento do Château Jardin será amanhã, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto no novo eixo Cidade Jardim, com inspiração clássica, paisagismo sofisticado e opções de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te mandar as plantas e diferenciais?`,
    `{{nome}}, tudo bem?\n\nEstou te chamando porque amanhã será o lançamento do Château Jardin.\n\nO projeto tem uma proposta elegante, inspirada no clássico e nos jardins franceses, com lazer completo e metragens de 185 m² a 355 m².\n\nFaz sentido eu te enviar o material?`,
    `Olá, {{nome}}.\n\nAmanhã acontece o evento de lançamento do Château Jardin, realização Tegra e Exto.\n\nO empreendimento fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².\n\nQuer que eu te envie os detalhes?`,
    `{{nome}}, amanhã será o lançamento do Château Jardin, um projeto residencial de alto padrão na Rua Ministro Nelson Hungria, 400. 📍\n\nEle combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e lazer com tênis, padel, piscina coberta e wellness.\n\nPosso te mandar o material?`,
    `Olá, {{nome}}, tudo bem?\n\nO Château Jardin será lançado amanhã e estou organizando os atendimentos por horário.\n\nO projeto tem plantas de 185 m², 215 m², 248 m² e 355 m², com lazer sofisticado e proposta de refúgio urbano no novo eixo Cidade Jardim.\n\nPosso te enviar as plantas?`,
    `{{nome}}, passando para te avisar sobre o lançamento do Château Jardin amanhã.\n\nÉ um projeto Tegra e Exto, com paisagismo internacional EDSA, inspiração nos jardins franceses e uma estrutura de lazer diferenciada: tênis de saibro, padel, piscina coberta e wellness. 🌿\n\nPosso te enviar um resumo?`,
    `Olá, {{nome}}.\n\nAmanhã teremos o lançamento do Château Jardin, um projeto que nasce como um novo marco residencial no eixo Cidade Jardim.\n\nSão plantas amplas de 185 m², 215 m², 248 m² e 355 m², com arquitetura clássica e lazer de alto padrão.\n\nQuer receber o material?`,
    `{{nome}}, tudo bem?\n\nAmanhã será o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nUm projeto de alto padrão inspirado no clássico, nos jardins franceses e em uma experiência residencial mais reservada.\n\nTemos opções de 185 m² a 355 m².\n\nPosso te mandar as informações?`
  ];

  const LIGACAO_BASE = [
    `Oi, {{nome}}, tudo bem? Aqui é {{corretor}}. Estou te ligando rapidamente porque amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado no clássico e nos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m². Faz sentido eu te enviar o material e verificar um horário para você conhecer?`,
    `{{nome}}, tudo bem? Aqui é {{corretor}}. Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão no novo eixo Cidade Jardim. O projeto une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e lazer com tênis de saibro, padel, piscina coberta e wellness. Posso te mandar as plantas e entender se alguma metragem faz sentido para você?`,
    `Oi, {{nome}}, aqui é {{corretor}}. Vou ser breve: amanhã acontece o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto sofisticado, com inspiração nos jardins franceses, plantas amplas de 185 m² a 355 m² e uma proposta residencial reservada. Você busca algo nesse perfil ou prefere apenas receber o material para avaliar?`,
    `{{nome}}, tudo bem? Estou entrando em contato porque amanhã será o evento de lançamento do Château Jardin. O projeto tem realização Tegra e Exto, fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m². Posso te enviar um resumo com plantas e principais diferenciais?`,
    `Oi, {{nome}}, tudo bem? Aqui é {{corretor}}. Amanhã vamos apresentar o Château Jardin, um projeto com arquitetura clássica, inspiração nos jardins franceses e paisagismo internacional. É um produto para quem busca alto padrão, conforto e plantas generosas. Você gostaria de conhecer as opções ou prefere que eu envie primeiro pelo WhatsApp?`,
    `{{nome}}, tudo bem? Estou te ligando porque amanhã teremos o lançamento do Château Jardin, um projeto no novo eixo Cidade Jardim com lazer de perfil private club: tênis de saibro, padel, piscina coberta, wellness e áreas sociais completas. As metragens vão de 185 m² a 355 m². Posso te passar o material?`,
    `Oi, {{nome}}, aqui é {{corretor}}. Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. O projeto tem uma proposta elegante: arquitetura clássica, jardins, serviços de alto padrão e plantas amplas. Queria entender se você está buscando imóvel para morar, investir ou apenas avaliando oportunidades nesse perfil.`,
    `{{nome}}, tudo bem? Vou falar rapidinho. Amanhã teremos o lançamento do Château Jardin, realização Tegra e Exto. O empreendimento foi pensado como um refúgio urbano no novo eixo Cidade Jardim, com metragens de 185 m², 215 m², 248 m² e 355 m². Posso te enviar as plantas para você avaliar com calma?`,
    `Oi, {{nome}}, aqui é {{corretor}}. Amanhã acontece o evento de lançamento do Château Jardin. É um projeto com inspiração clássica, atmosfera de jardins franceses, paisagismo EDSA e uma estrutura de lazer diferenciada. Se fizer sentido para você, posso te mandar o material e verificar um horário de apresentação.`,
    `{{nome}}, tudo bem? Estou te ligando sobre o Château Jardin, que será lançado amanhã na Rua Ministro Nelson Hungria, 400. É um projeto de alto padrão com opções de 185 m² a 355 m², lazer completo e proposta residencial sofisticada. Você teria interesse em receber as informações iniciais ou prefere agendar para conhecer presencialmente?`
  ];

  const EMAIL_BASE = [
    `Assunto: Château Jardin | Lançamento amanhã\n\nOlá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, projeto de alto padrão no novo eixo Cidade Jardim, com realização Tegra e Exto.\n\nInspirado na arquitetura clássica e na elegância dos jardins franceses, o empreendimento reúne paisagismo internacional EDSA, lazer sofisticado e plantas amplas de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nPosso te enviar as plantas e verificar um horário de apresentação?`,
    `Assunto: Château Jardin | Novo marco no eixo Cidade Jardim\n\nOlá, {{nome}}.\n\nEstou compartilhando o Château Jardin, lançamento que será apresentado amanhã na Rua Ministro Nelson Hungria, 400.\n\nO projeto une arquitetura clássica, olhar contemporâneo, inspiração nos jardins franceses e paisagismo internacional assinado pela EDSA.\n\nAs opções contemplam plantas de 185 m², 215 m², 248 m² e 355 m².\n\nCaso faça sentido para você, posso encaminhar o material completo e organizar uma visita.`,
    `Assunto: Amanhã | Evento de lançamento Château Jardin\n\nOlá, {{nome}}, tudo bem?\n\nAmanhã acontece o evento de lançamento do Château Jardin, empreendimento Tegra e Exto no novo eixo Cidade Jardim.\n\nO projeto foi pensado como um refúgio urbano sofisticado, com inspiração clássica, atmosfera de jardins franceses, lazer de alto padrão, quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.\n\nHá opções de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar plantas e detalhes do evento?`,
    `Assunto: Château Jardin | Plantas de 185 m² a 355 m²\n\nOlá, {{nome}}.\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nO empreendimento traz uma proposta residencial elegante, com arquitetura clássica, paisagismo internacional EDSA e inspiração nos jardins franceses.\n\nAs plantas incluem opções de 185 m², 215 m², 248 m² e 355 m², voltadas a quem busca alto padrão, conforto e localização estratégica no eixo Cidade Jardim.\n\nPosso te enviar o material?`,
    `Assunto: Convite | Château Jardin\n\nOlá, {{nome}}, tudo bem?\n\nGostaria de te apresentar o Château Jardin, lançamento de alto padrão que será apresentado amanhã no novo eixo Cidade Jardim.\n\nCom realização Tegra e Exto, o projeto combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e uma estrutura de lazer com perfil de private club.\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nSe fizer sentido, posso te enviar as plantas e detalhes das metragens.`,
    `Assunto: Château Jardin | Evento na Rua Ministro Nelson Hungria, 400\n\nOlá, {{nome}}.\n\nAmanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão na Rua Ministro Nelson Hungria, 400.\n\nO projeto reúne a assinatura Tegra e Exto, paisagismo internacional EDSA, inspiração clássica e metragens amplas de 185 m² a 355 m².\n\nA proposta é oferecer uma experiência residencial sofisticada, com lazer completo e serviços pensados para o dia a dia.\n\nPosso te enviar o material?`,
    `Assunto: Château Jardin | Alto padrão no novo eixo Cidade Jardim\n\nOlá, {{nome}}, tudo bem?\n\nO Château Jardin será lançado amanhã e nasce como uma proposta residencial sofisticada no novo eixo Cidade Jardim.\n\nInspirado no clássico e na elegância dos jardins franceses, o projeto conta com paisagismo internacional, quadra de tênis de saibro, padel, piscina coberta, wellness e plantas de 185 m², 215 m², 248 m² e 355 m².\n\nCaso queira, posso encaminhar as plantas e principais diferenciais.`,
    `Assunto: Conheça o Château Jardin\n\nOlá, {{nome}}.\n\nAmanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.\n\nO empreendimento foi concebido com arquitetura clássica, leitura contemporânea e inspiração nos jardins franceses, trazendo metragens amplas e lazer completo para uma experiência residencial reservada.\n\nO evento ocorrerá na Rua Ministro Nelson Hungria, 400.\n\nPosso te enviar o material completo com plantas e diferenciais?`,
    `Assunto: Château Jardin | Lançamento de alto padrão\n\nOlá, {{nome}}, tudo bem?\n\nEstou te enviando o Château Jardin, lançamento que será apresentado amanhã.\n\nO projeto une sofisticação, inspiração clássica, paisagismo internacional EDSA e lazer de alto padrão, com quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.\n\nAs plantas contemplam metragens de 185 m², 215 m², 248 m² e 355 m².\n\nFico à disposição para te enviar o material e organizar uma apresentação.`,
    `Assunto: Château Jardin | Apresentação amanhã\n\nOlá, {{nome}}.\n\nAmanhã teremos o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto, no novo eixo Cidade Jardim, inspirado na elegância clássica e nos jardins franceses, com paisagismo internacional e plantas amplas de 185 m² a 355 m².\n\nSe fizer sentido para você, posso enviar o material com plantas, metragens e detalhes do empreendimento.`
  ];

  const TEMPLATES = {
    whatsapp: WHATSAPP_BASE.map((t) => t + signature),
    ligacao: LIGACAO_BASE.map((t) => t + callClose),
    email: EMAIL_BASE.map((t) => t + signature)
  };

  function safeGet(key, fallback) { try { return localStorage.getItem(key) || fallback; } catch (_) { return fallback; } }
  function safeSet(key, value) { try { localStorage.setItem(key, String(value)); } catch (_) {} }
  function clean(value) { return String(value || '').trim(); }
  function normalizePhone(value) { const d = String(value || '').replace(/\D/g, ''); if (!d) return ''; return d.length === 10 || d.length === 11 ? `55${d}` : d; }
  function formatPhone(value) { const d = normalizePhone(value); const br = d.startsWith('55') ? d.slice(2) : d; if (br.length === 11) return `(${br.slice(0,2)}) ${br.slice(2,7)}-${br.slice(7)}`; if (br.length === 10) return `(${br.slice(0,2)}) ${br.slice(2,6)}-${br.slice(6)}`; return clean(value); }
  function firstWord(text) { return String(text || 'Cliente').trim().split(/\s+/)[0] || 'Cliente'; }
  function bodyText() { return String(document.body?.innerText || ''); }
  function root() { return document.getElementById(ROOT_ID); }
  function targetClosest(event, selector) { const target = event && event.target; return target && typeof target.closest === 'function' ? target.closest(selector) : null; }
  function currentChannel() { return root()?.querySelector('[data-pme-channel].active')?.getAttribute('data-pme-channel') || safeGet('fechai_pme_channel', 'ligacao'); }
  function getMode() { return runtimeMode === 'empreendimentos' ? 'empreendimentos' : 'origem'; }
  function setMode(mode) { runtimeMode = mode === 'empreendimentos' ? 'empreendimentos' : 'origem'; safeSet(MODE_KEY, runtimeMode); setVariant(0); }
  function getSituation() { return SITUATIONS[runtimeSituation] ? runtimeSituation : 'convite_lancamento'; }
  function setSituation(value) { runtimeSituation = SITUATIONS[value] ? value : 'convite_lancamento'; safeSet(SITUATION_KEY, runtimeSituation); setVariant(0); }
  function getVariant() { return Number(runtimeVariant) || 0; }
  function setVariant(value) { runtimeVariant = Number(value) || 0; safeSet(VARIANT_KEY, String(runtimeVariant)); }
  function getDevelopment() { return DEVELOPMENTS[runtimeDevelopment] ? runtimeDevelopment : 'chateau_jardin'; }
  function setDevelopment(value) { runtimeDevelopment = DEVELOPMENTS[value] ? value : 'chateau_jardin'; safeSet(DEVELOPMENT_KEY, runtimeDevelopment); setVariant(0); }
  function escapeHtml(text) { return String(text || '').replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#039;'); }
  function setText(el, value) { if (!el) return; const next = String(value || ''); if (el.textContent !== next) el.textContent = next; }

  function readStoredProfile() { try { return JSON.parse(localStorage.getItem(PROFILE_KEY) || 'null') || null; } catch (_) { return null; } }
  function buildWhatsappProfileLink(phone) { const digits = normalizePhone(phone); return digits ? `https://api.whatsapp.com/send?phone=${digits}` : ''; }
  function extractProfileEmail(row) { return clean(row?.email_prof || row?.email_profissional || row?.email_corretor || row?.email || row?.login_email); }
  function inferGmailAuthUser() { const explicit = clean(profileCache?.email) || safeGet('fechai_corretor_email', safeGet('fechai_pme_corretor_email', safeGet('fechai_pme_gmail_authuser', ''))); if (explicit) return explicit; const corretor = getCorretor().toLowerCase(); const empresa = getEmpresa().toLowerCase(); if (corretor.includes('wagner') && empresa.includes('tegra')) return 'wagner@tegravendas.com.br'; return ''; }

  function publishProfile(row) { const nome = clean(row?.apelido || row?.nome); const telefoneSource = row?.telefone_prof || row?.telefone; const telefone = formatPhone(telefoneSource); const whatsapp = buildWhatsappProfileLink(telefoneSource); const empresa = clean(row?.empresa || row?.empresa_nome || row?.imobiliaria || 'Tegra Incorporadora'); const email = extractProfileEmail(row); const profile = { nome, telefone, whatsapp, empresa, email }; profileCache = profile; safeSet(PROFILE_KEY, JSON.stringify(profile)); if (nome) { safeSet('fechai_corretor_nome', nome); safeSet('fechai_pme_corretor_nome', nome); } if (telefone) { safeSet('fechai_corretor_telefone', telefone); safeSet('fechai_pme_corretor_telefone', telefone); } if (whatsapp) { safeSet('fechai_corretor_whatsapp', whatsapp); safeSet('fechai_pme_link_whatsapp_corretor', whatsapp); } if (empresa) { safeSet('fechai_corretor_empresa', empresa); safeSet('fechai_pme_corretor_empresa', empresa); } if (email) { safeSet('fechai_corretor_email', email); safeSet('fechai_pme_corretor_email', email); safeSet('fechai_pme_gmail_authuser', email); } return profile; }
  function installProfileFetchBridge() { if (window.__fechaiPmeProfileFetchBridgeInstalled) return; window.__fechaiPmeProfileFetchBridgeInstalled = true; const originalFetch = window.fetch; if (typeof originalFetch !== 'function') return; window.fetch = function () { const args = arguments; return originalFetch.apply(this, args).then((response) => { try { const url = String(args[0]?.url || args[0] || ''); if (url.includes('/rest/v1/corretores')) { response.clone().json().then((rows) => { const row = Array.isArray(rows) ? rows[0] : rows; if (row && (row.apelido || row.nome || row.telefone_prof || row.email)) { publishProfile(row); schedulePatch(); } }).catch(() => {}); } } catch (_) {} return response; }); }; }
  function getLeadName() { const tel = document.querySelector('a[href^="tel:"]'); const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null; const title = card ? card.querySelector('h1,h2,h3,[class*="text-xl"],[class*="text-lg"],[class*="font-bold"]') : null; if (title && title.textContent.trim()) return firstWord(title.textContent.trim()); const match = bodyText().match(/Mensagem sugerida\s+Oi,\s*([^,\n]+),/i); return firstWord(match ? match[1] : 'Cliente'); }
  function getPhone() { const tel = document.querySelector('a[href^="tel:"]'); if (tel) return normalizePhone(tel.getAttribute('href')); const m = bodyText().match(/(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?9?\d{4}[-\s]?\d{4}/); return m ? normalizePhone(m[0]) : ''; }
  function getEmail() { const mail = document.querySelector('a[href^="mailto:"]'); if (mail) return String(mail.getAttribute('href') || '').replace(/^mailto:/, '').trim(); const m = bodyText().match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i); return m ? m[0] : ''; }
  function getCorretor() { return clean(profileCache?.nome) || safeGet('fechai_corretor_nome', safeGet('fechai_pme_corretor_nome', 'Corretor responsável')); }
  function getEmpresa() { return clean(profileCache?.empresa) || safeGet('fechai_corretor_empresa', safeGet('fechai_pme_corretor_empresa', 'empresa')); }
  function getCorretorPhone() { return clean(profileCache?.telefone) || safeGet('fechai_corretor_telefone', safeGet('fechai_pme_corretor_telefone', 'telefone não configurado')); }
  function getCorretorWhatsapp() { const stored = clean(profileCache?.whatsapp) || safeGet('fechai_corretor_whatsapp', safeGet('fechai_pme_link_whatsapp_corretor', '')); if (stored) return stored; const link = buildWhatsappProfileLink(getCorretorPhone()); return link || 'WhatsApp não configurado'; }
  function fill(text) { return String(text || '').replaceAll('{{nome}}', getLeadName()).replaceAll('{{corretor}}', getCorretor()).replaceAll('{{telefone_corretor}}', getCorretorPhone()).replaceAll('{{link_whatsapp_corretor}}', getCorretorWhatsapp()).replaceAll('{{empresa}}', getEmpresa()); }
  function pool() { return TEMPLATES[currentChannel()] || TEMPLATES.ligacao; }
  function currentText() { const list = pool(); const index = ((getVariant() % list.length) + list.length) % list.length; return fill(list[index]); }
  function parseEmail(text) { const match = String(text || '').match(/^\s*Assunto:\s*([^\n]+)\n+/i); if (!match) return { subject: 'Château Jardin', body: String(text || '') }; return { subject: match[1].trim(), body: String(text || '').slice(match[0].length).trim() }; }
  function gmailLink(to, subject, body) { const authUser = inferGmailAuthUser(); const auth = authUser ? `authuser=${encodeURIComponent(authUser)}&` : ''; return `https://mail.google.com/mail/?${auth}view=cm&fs=1&to=${encodeURIComponent(to || '')}&su=${encodeURIComponent(subject || '')}&body=${encodeURIComponent(body || '')}`; }
  async function copy(text) { try { await navigator.clipboard.writeText(text); return true; } catch (_) { window.prompt('Copie o texto:', text); return false; } }
  async function execute(text) { await copy(text); const channel = currentChannel(); if (channel === 'whatsapp') { const phone = getPhone(); window.open(phone ? `https://api.whatsapp.com/send?phone=${phone}&text=${encodeURIComponent(text)}` : `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`, '_blank', 'noopener,noreferrer'); return; } if (channel === 'email') { const parts = parseEmail(text); window.open(gmailLink(getEmail(), parts.subject, parts.body), '_blank', 'noopener,noreferrer'); return; } const phone = getPhone(); if (phone) window.location.href = `tel:${phone}`; }
  function ensureStyle() { if (document.getElementById(STYLE_ID)) return; const style = document.createElement('style'); style.id = STYLE_ID; style.textContent = `#${ROOT_ID} .pme-text{max-height:calc(1.55em * 3);overflow-y:auto;padding-right:6px;scrollbar-width:thin;}#${ROOT_ID} .pme-inline-mode-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;align-items:stretch;margin:10px auto 8px;max-width:620px;}#${ROOT_ID} .pme-inline-hidden{display:none!important;}#${ROOT_ID} .pme-inline-dev-note{grid-column:1/-1;font-size:12px;color:#64748b;font-weight:800;text-align:center;margin:0 auto;line-height:1.35;max-width:680px;}#${ROOT_ID} [data-pme-inline-mode],#${ROOT_ID} [data-pme-inline-development]{touch-action:manipulation;}@media(max-width:700px){#${ROOT_ID} .pme-text{max-height:calc(1.55em * 5);}#${ROOT_ID} .pme-inline-mode-grid{grid-template-columns:1fr 1fr;gap:8px;}}`; document.head.appendChild(style); }
  function findStepTitleContaining(text) { const r = root(); if (!r) return null; return Array.from(r.querySelectorAll('.pme-step-title')).find((el) => String(el.textContent || '').includes(text)) || null; }
  function sectionBetween(startTitle, endTitle) { if (!startTitle) return []; const out = []; let node = startTitle.nextElementSibling; while (node && node !== endTitle) { out.push(node); node = node.nextElementSibling; } return out; }
  function createModeGrid(mode) { const div = document.createElement('div'); div.className = 'pme-inline-mode-grid'; div.setAttribute('data-pme-inline-mode-grid', '1'); div.innerHTML = `<button type="button" class="pme-pill ${mode === 'origem' ? 'active' : ''}" data-pme-inline-mode="origem">🎯 Origem do lead</button><button type="button" class="pme-pill ${mode === 'empreendimentos' ? 'active' : ''}" data-pme-inline-mode="empreendimentos">🏛️ Empreendimentos</button>`; return div; }
  function updateModeGrid(grid, mode) { grid.querySelectorAll('[data-pme-inline-mode]').forEach((btn) => { btn.classList.toggle('active', btn.getAttribute('data-pme-inline-mode') === mode); }); }
  function createDevelopmentGrid() { const active = getDevelopment(); const div = document.createElement('div'); div.className = 'pme-origin-grid'; div.setAttribute('data-pme-inline-development-grid', '1'); div.innerHTML = Object.entries(DEVELOPMENTS).map(([key, item]) => `<button type="button" class="pme-pill ${key === active ? 'active' : ''}" data-pme-inline-development="${escapeHtml(key)}">${escapeHtml(item.icon + ' ' + item.label)}</button>`).join('') + `<div class="pme-inline-dev-note">${escapeHtml(DEVELOPMENTS[active]?.hint || '')} Endereço: ${escapeHtml(DEVELOPMENTS[active]?.address || '')}</div>`; return div; }
  function updateDevelopmentGrid(grid) { const active = getDevelopment(); grid.querySelectorAll('[data-pme-inline-development]').forEach((btn) => { btn.classList.toggle('active', btn.getAttribute('data-pme-inline-development') === active); }); setText(grid.querySelector('.pme-inline-dev-note'), `${DEVELOPMENTS[active]?.hint || ''} Endereço: ${DEVELOPMENTS[active]?.address || ''}`); }
  function createSituationSelect() { const wrap = document.createElement('div'); wrap.className = 'pme-select-wrap'; wrap.setAttribute('data-pme-inline-situation-wrap', '1'); wrap.innerHTML = `<select class="pme-select" data-pme-inline-situation aria-label="Escolha em qual situação o cliente está">${Object.entries(SITUATIONS).map(([key, label]) => `<option value="${escapeHtml(key)}" ${key === getSituation() ? 'selected' : ''}>${escapeHtml(label)}</option>`).join('')}</select>`; return wrap; }
  function updateSituationSelect(wrap) { const select = wrap?.querySelector('[data-pme-inline-situation]'); if (select && select.value !== getSituation()) select.value = getSituation(); }
  function renderReplacementRows(r, originTitle, channelTitle, mode) { const sectionNodes = sectionBetween(originTitle, channelTitle); sectionNodes.forEach((el) => { if (el.matches('[data-pme-inline-mode-grid]')) return; if (el.classList.contains('pme-step-help')) return; el.classList.toggle('pme-inline-hidden', mode === 'empreendimentos'); }); const existingDev = r.querySelector('[data-pme-inline-development-grid]'); if (mode === 'empreendimentos') { if (existingDev) updateDevelopmentGrid(existingDev); else channelTitle.insertAdjacentElement('beforebegin', createDevelopmentGrid()); return; } if (existingDev) existingDev.remove(); }
  function patch() { const r = root(); if (!r) return; ensureStyle(); const mode = getMode(); const originTitle = findStepTitleContaining('Escolha a origem'); const channelTitle = findStepTitleContaining('Escolha o canal'); const situationTitle = findStepTitleContaining('Escolha em qual situação'); if (!originTitle || !channelTitle || !situationTitle) return; const headerTitle = r.querySelector('.pme-title'); const headerSub = r.querySelector('.pme-sub'); const chip = r.querySelector('.pme-chip'); setText(headerTitle, 'Fluxo de atendimento'); setText(headerSub, 'Siga os passos abaixo. Primeiro escolha a origem ou empreendimento, depois o canal, a situação e por fim execute o contato.'); setText(originTitle, '1. Escolha a origem ou empreendimento'); let modeGrid = r.querySelector('[data-pme-inline-mode-grid]'); if (!modeGrid) originTitle.insertAdjacentElement('afterend', createModeGrid(mode)); else updateModeGrid(modeGrid, mode); const originHelp = sectionBetween(originTitle, channelTitle).find((el) => el.classList && el.classList.contains('pme-step-help')); setText(originHelp, mode === 'empreendimentos' ? 'Escolha qual empreendimento será trabalhado neste atendimento.' : 'Use Origem do lead para o fluxo padrão ou Empreendimentos para mensagens por projeto.'); renderReplacementRows(r, originTitle, channelTitle, mode); setText(channelTitle, '2. Escolha o canal para contato com o cliente'); setText(situationTitle, '3. Escolha em qual situação o cliente está'); const oldSituation = r.querySelector('[data-pme="approach"]')?.closest('.pme-select-wrap'); const inlineSituation = r.querySelector('[data-pme-inline-situation-wrap]'); if (mode === 'empreendimentos') { if (oldSituation) oldSituation.classList.add('pme-inline-hidden'); if (!inlineSituation && oldSituation) oldSituation.insertAdjacentElement('afterend', createSituationSelect()); else updateSituationSelect(inlineSituation); } else { if (oldSituation) oldSituation.classList.remove('pme-inline-hidden'); if (inlineSituation) inlineSituation.remove(); } const boxTitle = r.querySelector('.pme-box-title'); const textEl = r.querySelector('.pme-text'); setText(boxTitle, 'Mensagem sugerida'); if (mode === 'empreendimentos' && textEl) setText(textEl, currentText()); const channelLabel = r.querySelector('[data-pme-channel].active')?.textContent?.replace(/^[^A-Za-zÀ-ÿ0-9]+\s*/u, '').trim() || 'Canal'; if (chip && mode === 'empreendimentos') setText(chip, `${DEVELOPMENTS[getDevelopment()]?.label || 'Empreendimento'} · ${channelLabel}`); const status = r.querySelector('[data-pme-status]'); if (status && mode === 'empreendimentos') { const blocked = BLOCKED_TERMS.some((term) => currentText().toLowerCase().includes(term.toLowerCase())); setText(status, blocked ? 'Atenção: termo bloqueado detectado na mensagem. Revise antes de usar.' : 'Mensagem de empreendimento carregada. A PME não envia mensagem sozinha e não registra feedback automaticamente.'); } }
  function stop(event) { event.preventDefault(); event.stopPropagation(); if (typeof event.stopImmediatePropagation === 'function') event.stopImmediatePropagation(); }
  function schedulePatch() { if (patchQueued) return; patchQueued = true; window.requestAnimationFrame(() => { patchQueued = false; patch(); }); }
  function handleInlineModeEvent(event) { const modeBtn = targetClosest(event, '[data-pme-inline-mode]'); const devBtn = targetClosest(event, '[data-pme-inline-development]'); if (!modeBtn && !devBtn) return false; stop(event); if (Date.now() - lastInlineHandledAt < 80 && event.type === 'click') return true; lastInlineHandledAt = Date.now(); if (modeBtn) setMode(modeBtn.getAttribute('data-pme-inline-mode')); if (devBtn) setDevelopment(devBtn.getAttribute('data-pme-inline-development')); schedulePatch(); return true; }
  function handleInlineActionEvent(event) { if (getMode() !== 'empreendimentos') return false; if (event.type === 'pointerdown') return false; const actionBtn = targetClosest(event, '[data-pme-action]'); if (!actionBtn || !root()?.contains(actionBtn)) return false; const type = actionBtn.getAttribute('data-pme-action'); if (!['next', 'prev', 'use', 'ai'].includes(type)) return false; stop(event); if (event.type === 'click' && Date.now() - lastActionHandledAt < 180) return true; lastActionHandledAt = Date.now(); if (type === 'next') setVariant(getVariant() + 1); if (type === 'prev') setVariant(getVariant() - 1); if (type === 'use') execute(currentText()); if (type === 'ai') copy(currentText()); schedulePatch(); return true; }
  function bind() { if (window.__fechaiPmeEmpreendimentosInlineBound) return; window.__fechaiPmeEmpreendimentosInlineBound = true; ['pointerdown', 'pointerup', 'click'].forEach((eventName) => { document.addEventListener(eventName, function (event) { if (handleInlineModeEvent(event)) return; if (eventName !== 'pointerdown') handleInlineActionEvent(event); }, true); }); document.addEventListener('change', function (event) { const select = targetClosest(event, '[data-pme-inline-situation]'); if (!select) return; stop(event); setSituation(select.value); schedulePatch(); }, true); }
  function start() { installProfileFetchBridge(); bind(); patch(); const observer = new MutationObserver(() => schedulePatch()); observer.observe(document.body, { childList: true, subtree: true }); }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
