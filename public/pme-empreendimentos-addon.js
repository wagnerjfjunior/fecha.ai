/*
 * FECH.AI — PME Empreendimentos Addon
 * Version: 0.1.1-clean
 * Scope: frontend-only addon loaded after pme-call-assistant-beta.js.
 * Safety: no automatic sending, no Supabase/RPC/RLS/auth changes.
 */
(function () {
  'use strict';

  const ADDON_ID = 'fechai-pme-empreendimentos-addon';
  const STYLE_ID = 'fechai-pme-empreendimentos-addon-style';
  const VERSION = '0.1.1-clean';

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

  const CHANNELS = {
    whatsapp: 'WhatsApp',
    ligacao: 'Ligação',
    email: 'E-mail'
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

  const signature = '\n\n{{nome_corretor}}\n{{telefone_corretor}}\nWhatsApp: {{link_whatsapp_corretor}}\n\nAo chegar, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente.';
  const callClose = '\n\nO evento será na Rua Ministro Nelson Hungria, 400. Quando chegar, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente e apresentar o projeto com calma.';

  const whatsapp = [
    'Olá, {{nome_lead}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado na elegância dos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar o material com plantas e detalhes do evento?',
    '{{nome_lead}}, tudo bem?\n\nAmanhã acontece o lançamento do Château Jardin, um projeto de alto padrão no novo eixo Cidade Jardim.\n\nO empreendimento une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e metragens amplas de 185 m² a 355 m².\n\nQuer que eu te envie as plantas para avaliar com calma?',
    'Olá, {{nome_lead}}.\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. 📍\n\nÉ um projeto Tegra e Exto, com inspiração nos jardins franceses, lazer de alto padrão e opções de 185 m², 215 m², 248 m² e 355 m². 📐\n\nPosso te mandar um resumo com as plantas?',
    '{{nome_lead}}, amanhã teremos o lançamento do Château Jardin.\n\nÉ um projeto inspirado no clássico, nos jardins franceses e em uma forma mais elegante de viver, no novo eixo Cidade Jardim.\n\nAs opções contemplam 185 m², 215 m², 248 m² e 355 m².\n\nFaz sentido eu te enviar o material agora?',
    'Olá, {{nome_lead}}, tudo bem?\n\nAmanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.\n\nO projeto reúne arquitetura clássica, paisagismo internacional EDSA, lazer de perfil private club e plantas generosas de 185 m² a 355 m².\n\nQuer receber as informações iniciais?',
    '{{nome_lead}}, estou organizando os atendimentos do lançamento do Château Jardin, que acontece amanhã na Rua Ministro Nelson Hungria, 400. 🗓️\n\nO empreendimento tem inspiração na elegância dos jardins franceses e plantas de 185 m², 215 m², 248 m² e 355 m². 🌿\n\nPosso te mandar as opções?',
    'Olá, {{nome_lead}}.\n\nAmanhã é o lançamento do Château Jardin, projeto Tegra e Exto no novo eixo Cidade Jardim.\n\nUm refúgio urbano com arquitetura clássica, paisagismo internacional EDSA, quadra de tênis de saibro, padel, piscina coberta e metragens de 185 m² a 355 m².\n\nPosso te enviar o material?',
    '{{nome_lead}}, tudo bem?\n\nAmanhã teremos o evento de lançamento do Château Jardin.\n\nO projeto foi pensado para quem busca alto padrão, elegância atemporal e plantas amplas, com opções de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nQuer que eu te envie os detalhes?',
    'Olá, {{nome_lead}}.\n\nO Château Jardin será lançado amanhã no novo eixo Cidade Jardim.\n\nÉ um projeto com inspiração clássica, atmosfera de jardins franceses, lazer sofisticado e assinatura Tegra e Exto. 🏛️\n\nAs plantas contemplam 185 m², 215 m², 248 m² e 355 m². 📐\n\nPosso te mandar o material?',
    '{{nome_lead}}, passando rapidamente para te apresentar o Château Jardin, que terá evento de lançamento amanhã.\n\nÉ um projeto de alto padrão na Rua Ministro Nelson Hungria, 400, com arquitetura clássica, paisagismo internacional e metragens amplas de 185 m² a 355 m².\n\nPosso te enviar as plantas?',
    'Olá, {{nome_lead}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, um projeto que une o clássico e o contemporâneo no novo eixo Cidade Jardim.\n\nInspirado na elegância dos jardins franceses, traz plantas de 185 m², 215 m², 248 m² e 355 m².\n\nQuer conhecer o material?',
    '{{nome_lead}}, amanhã teremos a apresentação do Château Jardin, empreendimento Tegra e Exto com projeto internacional EDSA.\n\nA proposta combina jardins, lazer de alto padrão, arquitetura clássica e unidades amplas de 185 m² a 355 m². 🌿\n\nPosso te enviar as informações pelo WhatsApp?',
    'Olá, {{nome_lead}}.\n\nO lançamento do Château Jardin será amanhã, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto no novo eixo Cidade Jardim, com inspiração clássica, paisagismo sofisticado e opções de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te mandar as plantas e diferenciais?',
    '{{nome_lead}}, tudo bem?\n\nEstou te chamando porque amanhã será o lançamento do Château Jardin.\n\nO projeto tem uma proposta elegante, inspirada no clássico e nos jardins franceses, com lazer completo e metragens de 185 m² a 355 m².\n\nFaz sentido eu te enviar o material?',
    'Olá, {{nome_lead}}.\n\nAmanhã acontece o evento de lançamento do Château Jardin, realização Tegra e Exto.\n\nO empreendimento fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².\n\nQuer que eu te envie os detalhes?',
    '{{nome_lead}}, amanhã será o lançamento do Château Jardin, um projeto residencial de alto padrão na Rua Ministro Nelson Hungria, 400. 📍\n\nEle combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e lazer com tênis, padel, piscina coberta e wellness.\n\nPosso te mandar o material?',
    'Olá, {{nome_lead}}, tudo bem?\n\nO Château Jardin será lançado amanhã e estou organizando os atendimentos por horário.\n\nO projeto tem plantas de 185 m², 215 m², 248 m² e 355 m², com lazer sofisticado e proposta de refúgio urbano no novo eixo Cidade Jardim.\n\nPosso te enviar as plantas?',
    '{{nome_lead}}, passando para te avisar sobre o lançamento do Château Jardin amanhã.\n\nÉ um projeto Tegra e Exto, com paisagismo internacional EDSA, inspiração nos jardins franceses e uma estrutura de lazer diferenciada: tênis de saibro, padel, piscina coberta e wellness. 🌿\n\nPosso te enviar um resumo?',
    'Olá, {{nome_lead}}.\n\nAmanhã teremos o lançamento do Château Jardin, um projeto que nasce como um novo marco residencial no eixo Cidade Jardim.\n\nSão plantas amplas de 185 m², 215 m², 248 m² e 355 m², com arquitetura clássica e lazer de alto padrão.\n\nQuer receber o material?',
    '{{nome_lead}}, tudo bem?\n\nAmanhã será o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nUm projeto de alto padrão inspirado no clássico, nos jardins franceses e em uma experiência residencial mais reservada.\n\nTemos opções de 185 m² a 355 m².\n\nPosso te mandar as informações?'
  ].map((text) => text + signature);

  const ligacao = [
    'Oi, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}. Estou te ligando rapidamente porque amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado no clássico e nos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m². Faz sentido eu te enviar o material e verificar um horário para você conhecer?',
    '{{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}. Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão no novo eixo Cidade Jardim. O projeto une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e lazer com tênis de saibro, padel, piscina coberta e wellness. Posso te mandar as plantas e entender se alguma metragem faz sentido para você?',
    'Oi, {{nome_lead}}, aqui é {{nome_corretor}}. Vou ser breve: amanhã acontece o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto sofisticado, com inspiração nos jardins franceses, plantas amplas de 185 m² a 355 m² e uma proposta residencial reservada. Você busca algo nesse perfil ou prefere apenas receber o material para avaliar?',
    '{{nome_lead}}, tudo bem? Estou entrando em contato porque amanhã será o evento de lançamento do Château Jardin. O projeto tem realização Tegra e Exto, fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m². Posso te enviar um resumo com plantas e principais diferenciais?',
    'Oi, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}. Amanhã vamos apresentar o Château Jardin, um projeto com arquitetura clássica, inspiração nos jardins franceses e paisagismo internacional. É um produto para quem busca alto padrão, conforto e plantas generosas. Você gostaria de conhecer as opções ou prefere que eu envie primeiro pelo WhatsApp?',
    '{{nome_lead}}, tudo bem? Estou te ligando porque amanhã teremos o lançamento do Château Jardin, um projeto no novo eixo Cidade Jardim com lazer de perfil private club: tênis de saibro, padel, piscina coberta, wellness e áreas sociais completas. As metragens vão de 185 m² a 355 m². Posso te passar o material?',
    'Oi, {{nome_lead}}, aqui é {{nome_corretor}}. Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. O projeto tem uma proposta elegante: arquitetura clássica, jardins, serviços de alto padrão e plantas amplas. Queria entender se você está buscando imóvel para morar, investir ou apenas avaliando oportunidades nesse perfil.',
    '{{nome_lead}}, tudo bem? Vou falar rapidinho. Amanhã teremos o lançamento do Château Jardin, realização Tegra e Exto. O empreendimento foi pensado como um refúgio urbano no novo eixo Cidade Jardim, com metragens de 185 m², 215 m², 248 m² e 355 m². Posso te enviar as plantas para você avaliar com calma?',
    'Oi, {{nome_lead}}, aqui é {{nome_corretor}}. Amanhã acontece o evento de lançamento do Château Jardin. É um projeto com inspiração clássica, atmosfera de jardins franceses, paisagismo EDSA e uma estrutura de lazer diferenciada. Se fizer sentido para você, posso te mandar o material e verificar um horário de apresentação.',
    '{{nome_lead}}, tudo bem? Estou te ligando sobre o Château Jardin, que será lançado amanhã na Rua Ministro Nelson Hungria, 400. É um projeto de alto padrão com opções de 185 m² a 355 m², lazer completo e proposta residencial sofisticada. Você teria interesse em receber as informações iniciais ou prefere agendar para conhecer presencialmente?'
  ].map((text) => text + callClose);

  const email = [
    'Assunto: Château Jardin | Lançamento amanhã\n\nOlá, {{nome_lead}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, projeto de alto padrão no novo eixo Cidade Jardim, com realização Tegra e Exto.\n\nInspirado na arquitetura clássica e na elegância dos jardins franceses, o empreendimento reúne paisagismo internacional EDSA, lazer sofisticado e plantas amplas de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nPosso te enviar as plantas e verificar um horário de apresentação?',
    'Assunto: Château Jardin | Novo marco no eixo Cidade Jardim\n\nOlá, {{nome_lead}}.\n\nEstou compartilhando o Château Jardin, lançamento que será apresentado amanhã na Rua Ministro Nelson Hungria, 400.\n\nO projeto une arquitetura clássica, olhar contemporâneo, inspiração nos jardins franceses e paisagismo internacional assinado pela EDSA.\n\nAs opções contemplam plantas de 185 m², 215 m², 248 m² e 355 m².\n\nCaso faça sentido para você, posso encaminhar o material completo e organizar uma visita.',
    'Assunto: Amanhã | Evento de lançamento Château Jardin\n\nOlá, {{nome_lead}}, tudo bem?\n\nAmanhã acontece o evento de lançamento do Château Jardin, empreendimento Tegra e Exto no novo eixo Cidade Jardim.\n\nO projeto foi pensado como um refúgio urbano sofisticado, com inspiração clássica, atmosfera de jardins franceses, lazer de alto padrão, quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.\n\nHá opções de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar plantas e detalhes do evento?',
    'Assunto: Château Jardin | Plantas de 185 m² a 355 m²\n\nOlá, {{nome_lead}}.\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nO empreendimento traz uma proposta residencial elegante, com arquitetura clássica, paisagismo internacional EDSA e inspiração nos jardins franceses.\n\nAs plantas incluem opções de 185 m², 215 m², 248 m² e 355 m², voltadas a quem busca alto padrão, conforto e localização estratégica no eixo Cidade Jardim.\n\nPosso te enviar o material?',
    'Assunto: Convite | Château Jardin\n\nOlá, {{nome_lead}}, tudo bem?\n\nGostaria de te apresentar o Château Jardin, lançamento de alto padrão que será apresentado amanhã no novo eixo Cidade Jardim.\n\nCom realização Tegra e Exto, o projeto combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e uma estrutura de lazer com perfil de private club.\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nSe fizer sentido, posso te enviar as plantas e detalhes das metragens.',
    'Assunto: Château Jardin | Evento na Rua Ministro Nelson Hungria, 400\n\nOlá, {{nome_lead}}.\n\nAmanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão na Rua Ministro Nelson Hungria, 400.\n\nO projeto reúne a assinatura Tegra e Exto, paisagismo internacional EDSA, inspiração clássica e metragens amplas de 185 m² a 355 m².\n\nA proposta é oferecer uma experiência residencial sofisticada, com lazer completo e serviços pensados para o dia a dia.\n\nPosso te enviar o material?',
    'Assunto: Château Jardin | Alto padrão no novo eixo Cidade Jardim\n\nOlá, {{nome_lead}}, tudo bem?\n\nO Château Jardin será lançado amanhã e nasce como uma proposta residencial sofisticada no novo eixo Cidade Jardim.\n\nInspirado no clássico e na elegância dos jardins franceses, o projeto conta com paisagismo internacional, quadra de tênis de saibro, padel, piscina coberta, wellness e plantas de 185 m², 215 m², 248 m² e 355 m².\n\nCaso queira, posso encaminhar as plantas e principais diferenciais.',
    'Assunto: Conheça o Château Jardin\n\nOlá, {{nome_lead}}.\n\nAmanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.\n\nO empreendimento foi concebido com arquitetura clássica, leitura contemporânea e inspiração nos jardins franceses, trazendo metragens amplas e lazer completo para uma experiência residencial reservada.\n\nO evento ocorrerá na Rua Ministro Nelson Hungria, 400.\n\nPosso te enviar o material completo com plantas e diferenciais?',
    'Assunto: Château Jardin | Lançamento de alto padrão\n\nOlá, {{nome_lead}}, tudo bem?\n\nEstou te enviando o Château Jardin, lançamento que será apresentado amanhã.\n\nO projeto une sofisticação, inspiração clássica, paisagismo internacional EDSA e lazer de alto padrão, com quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.\n\nAs plantas contemplam metragens de 185 m², 215 m², 248 m² e 355 m².\n\nFico à disposição para te enviar o material e organizar uma apresentação.',
    'Assunto: Château Jardin | Apresentação amanhã\n\nOlá, {{nome_lead}}.\n\nAmanhã teremos o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto, no novo eixo Cidade Jardim, inspirado na elegância clássica e nos jardins franceses, com paisagismo internacional e plantas amplas de 185 m² a 355 m².\n\nSe fizer sentido para você, posso enviar o material com plantas, metragens e detalhes do empreendimento.'
  ].map((text) => text + signature);

  const templates = { whatsapp, ligacao, email };
  const state = {
    channel: safeGet('fechai_pme_emp_channel', 'whatsapp'),
    situation: safeGet('fechai_pme_emp_situation', 'convite_lancamento'),
    variant: Number(safeGet('fechai_pme_emp_variant', '0')) || 0
  };

  function safeGet(key, fallback) { try { return localStorage.getItem(key) || fallback; } catch (_) { return fallback; } }
  function safeSet(key, value) { try { localStorage.setItem(key, String(value)); } catch (_) {} }
  function save() { safeSet('fechai_pme_emp_channel', state.channel); safeSet('fechai_pme_emp_situation', state.situation); safeSet('fechai_pme_emp_variant', state.variant); }
  function escapeHtml(value) { return String(value || '').replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[char])); }
  function normalizePhone(value) { return String(value || '').replace(/\D/g, ''); }
  function firstWord(value) { return String(value || 'Cliente').trim().split(/\s+/)[0] || 'Cliente'; }
  function getBodyText() { return String(document.body?.innerText || ''); }
  function isDiscadorContext() { return /Fluxo de atendimento|Escolha a origem do lead|Mensagem sugerida|Discador/i.test(getBodyText()); }
  function getLeadName() {
    const text = getBodyText();
    const fromMessage = text.match(/Mensagem sugerida\s+Oi,\s*([^,\n]+),/i);
    if (fromMessage) return firstWord(fromMessage[1]);
    const lines = text.split('\n').map((s) => s.trim()).filter(Boolean);
    return firstWord(lines.find((line) => /^[A-Za-zÀ-ÿ]+(?:\s+[A-Za-zÀ-ÿ]+){0,3}$/.test(line) && !/whatsapp|telefone|email|lead|status|feedback|fluxo|discador|wagner|corretor/i.test(line)) || 'Cliente');
  }
  function getLeadPhone() {
    const tel = document.querySelector('a[href^="tel:"]');
    if (tel) return normalizePhone(tel.getAttribute('href'));
    const m = getBodyText().match(/(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?9?\d{4}[-\s]?\d{4}/);
    return m ? normalizePhone(m[0]) : '';
  }
  function getLeadEmail() {
    const mail = document.querySelector('a[href^="mailto:"]');
    if (mail) return String(mail.getAttribute('href') || '').replace(/^mailto:/, '').trim();
    const m = getBodyText().match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
    return m ? m[0] : '';
  }
  function getCorretorName() { return safeGet('fechai_pme_corretor_nome', 'Wagner'); }
  function getCorretorPhone() { return safeGet('fechai_pme_corretor_telefone', '{{telefone_corretor}}'); }
  function getWhatsappLinkCorretor() {
    const stored = safeGet('fechai_pme_link_whatsapp_corretor', '');
    if (stored) return stored;
    const normalized = normalizePhone(getCorretorPhone());
    return normalized ? `https://wa.me/${normalized}` : '{{link_whatsapp_corretor}}';
  }
  function fill(text) {
    return String(text || '')
      .replaceAll('{{nome_lead}}', getLeadName())
      .replaceAll('{{nome}}', getLeadName())
      .replaceAll('{{nome_corretor}}', getCorretorName())
      .replaceAll('{{corretor}}', getCorretorName())
      .replaceAll('{{telefone_corretor}}', getCorretorPhone())
      .replaceAll('{{link_whatsapp_corretor}}', getWhatsappLinkCorretor())
      .replaceAll('{{link_whatsapp}}', getWhatsappLinkCorretor());
  }
  function currentPool() { return templates[state.channel] || templates.whatsapp; }
  function currentText() { const pool = currentPool(); return fill(pool[Math.abs(state.variant) % pool.length]); }
  function splitEmailTemplate(text) { const match = String(text || '').match(/^Assunto:\s*(.+?)\n\n([\s\S]*)$/i); return match ? { subject: match[1].trim(), body: match[2].trim() } : { subject: 'Château Jardin', body: String(text || '') }; }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `#${ADDON_ID}{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#fff;border:1px solid #c7d2fe;border-radius:20px;padding:16px;margin:14px 26px;box-shadow:0 10px 26px rgba(30,64,175,.08)}#${ADDON_ID} *{box-sizing:border-box}#${ADDON_ID} .pme-addon-head{display:flex;justify-content:space-between;gap:10px;align-items:flex-start}#${ADDON_ID} .pme-addon-title{font-size:20px;font-weight:950;color:#0f172a}#${ADDON_ID} .pme-addon-sub{font-size:13px;color:#64748b;line-height:1.35;margin-top:4px}#${ADDON_ID} .pme-addon-chip{font-size:11px;font-weight:900;color:#3730a3;background:#eef2ff;border:1px solid #c7d2fe;padding:6px 9px;border-radius:999px;white-space:nowrap}#${ADDON_ID} .pme-addon-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:12px}#${ADDON_ID} select,#${ADDON_ID} button{width:100%;border-radius:14px;padding:11px 10px;font-size:14px;font-weight:850}#${ADDON_ID} select{border:1px solid #bfdbfe;background:#fff;color:#0f172a}#${ADDON_ID} button{border:1px solid #bfdbfe;background:#eff6ff;color:#1d4ed8;cursor:pointer}#${ADDON_ID} button.primary{background:#2563eb;color:#fff;border-color:#2563eb}#${ADDON_ID} .pme-addon-box{background:#f8fafc;border:1px solid #e2e8f0;border-radius:16px;padding:12px;margin-top:12px;white-space:pre-line;line-height:1.5;color:#111827;font-size:14px;max-height:280px;overflow:auto}#${ADDON_ID} .pme-addon-note{font-size:12px;color:#64748b;text-align:center;margin-top:9px;line-height:1.35}@media(max-width:700px){#${ADDON_ID}{margin:10px 8px}#${ADDON_ID} .pme-addon-grid{grid-template-columns:1fr}}`;
    document.head.appendChild(style);
  }

  function findFlowCard() {
    const nodes = Array.from(document.querySelectorAll('#root div, main div, section'));
    const matches = nodes.filter((el) => /Fluxo de atendimento/.test(el.innerText || '') && el.offsetHeight > 120 && el.offsetWidth > 300);
    return matches.sort((a, b) => (a.innerText || '').length - (b.innerText || '').length)[0] || document.querySelector('#root > div') || document.body;
  }

  function mount() {
    if (!isDiscadorContext()) { document.getElementById(ADDON_ID)?.remove(); return; }
    ensureStyle();
    const flowCard = findFlowCard();
    if (!flowCard || !flowCard.parentElement) return;
    let root = document.getElementById(ADDON_ID);
    if (!root) {
      root = document.createElement('div');
      root.id = ADDON_ID;
      flowCard.parentElement.insertBefore(root, flowCard);
    }
    const text = currentText();
    const blocked = BLOCKED_TERMS.some((term) => text.toLowerCase().includes(term.toLowerCase()));
    root.innerHTML = `<div class="pme-addon-head"><div><div class="pme-addon-title">🏛️ PME — Empreendimentos</div><div class="pme-addon-sub">Château Jardin · Rua Ministro Nelson Hungria, 400 · atendimento assistido sem envio automático.</div></div><div class="pme-addon-chip">v${VERSION}</div></div><div class="pme-addon-grid"><select data-addon-channel>${Object.entries(CHANNELS).map(([key,label]) => `<option value="${key}" ${state.channel === key ? 'selected' : ''}>${label}</option>`).join('')}</select><select data-addon-situation>${Object.entries(SITUATIONS).map(([key,label]) => `<option value="${key}" ${state.situation === key ? 'selected' : ''}>${label}</option>`).join('')}</select></div><div class="pme-addon-box">${escapeHtml(text)}</div><div class="pme-addon-grid"><button class="primary" data-addon-execute>Revisar e executar</button><button data-addon-copy>Copiar</button><button data-addon-next>Próxima variação ${Math.abs(state.variant) % currentPool().length + 1}/${currentPool().length}</button><button data-addon-hide>Ocultar módulo</button></div><div class="pme-addon-note">${blocked ? 'Atenção: termo bloqueado detectado. Revise antes de usar.' : 'Nada é enviado automaticamente. O corretor revisa antes de abrir WhatsApp, e-mail ou ligação.'}</div>`;
    root.querySelector('[data-addon-channel]').onchange = (e) => { state.channel = e.target.value; state.variant = 0; save(); mount(); };
    root.querySelector('[data-addon-situation]').onchange = (e) => { state.situation = e.target.value; state.variant = 0; save(); mount(); };
    root.querySelector('[data-addon-next]').onclick = () => { state.variant += 1; save(); mount(); };
    root.querySelector('[data-addon-copy]').onclick = () => copy(text);
    root.querySelector('[data-addon-hide]').onclick = () => root.remove();
    root.querySelector('[data-addon-execute]').onclick = () => execute(text);
  }

  async function copy(text) { try { await navigator.clipboard.writeText(text); } catch (_) { window.prompt('Copie o texto:', text); } }
  async function execute(text) {
    await copy(text);
    if (state.channel === 'whatsapp') {
      const phone = getLeadPhone();
      window.open(phone ? `https://wa.me/${phone}?text=${encodeURIComponent(text)}` : `https://wa.me/?text=${encodeURIComponent(text)}`, '_blank', 'noopener,noreferrer');
      return;
    }
    if (state.channel === 'email') {
      const parsed = splitEmailTemplate(text);
      window.location.href = `mailto:${encodeURIComponent(getLeadEmail())}?subject=${encodeURIComponent(parsed.subject)}&body=${encodeURIComponent(parsed.body)}`;
      return;
    }
    const phone = getLeadPhone();
    if (phone) window.location.href = `tel:${phone}`;
  }

  function boot() { mount(); setInterval(mount, 1500); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
