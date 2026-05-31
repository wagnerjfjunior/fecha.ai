/*
 * FECH.AI — PME Empreendimentos Inline Flow
 * Version: 0.1.5
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
  let profileCache = readStoredProfile();
  let observer = null;
  let observedTarget = null;
  let isPatching = false;
  let patchQueued = false;
  let lastInlineHandledAt = 0;
  let lastActionHandledAt = 0;

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

  const TEMPLATES = {
    whatsapp: [
      `Olá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.\n\nÉ um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado na elegância dos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².\n\nPosso te enviar o material com plantas e detalhes do evento?${signature}`,
      `{{nome}}, tudo bem?\n\nAmanhã acontece o lançamento do Château Jardin, um projeto de alto padrão no novo eixo Cidade Jardim.\n\nO empreendimento une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e metragens amplas de 185 m² a 355 m².\n\nQuer que eu te envie as plantas para avaliar com calma?${signature}`
    ],
    ligacao: [
      `Oi, {{nome}}, tudo bem? Aqui é {{corretor}}. Estou te ligando rapidamente porque amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado no clássico e nos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m². Faz sentido eu te enviar o material e verificar um horário para você conhecer?${callClose}`,
      `{{nome}}, tudo bem? Aqui é {{corretor}}. Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão no novo eixo Cidade Jardim. O projeto une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e lazer com tênis de saibro, padel, piscina coberta e wellness. Posso te mandar as plantas e entender se alguma metragem faz sentido para você?${callClose}`
    ],
    email: [
      `Assunto: Château Jardin | Lançamento amanhã\n\nOlá, {{nome}}, tudo bem?\n\nAmanhã será o lançamento do Château Jardin, projeto de alto padrão no novo eixo Cidade Jardim, com realização Tegra e Exto.\n\nInspirado na arquitetura clássica e na elegância dos jardins franceses, o empreendimento reúne paisagismo internacional EDSA, lazer sofisticado e plantas amplas de 185 m², 215 m², 248 m² e 355 m².\n\nO evento será na Rua Ministro Nelson Hungria, 400.\n\nPosso te enviar as plantas e verificar um horário de apresentação?${signature}`,
      `Assunto: Château Jardin | Novo marco no eixo Cidade Jardim\n\nOlá, {{nome}}.\n\nEstou compartilhando o Château Jardin, lançamento que será apresentado amanhã na Rua Ministro Nelson Hungria, 400.\n\nO projeto une arquitetura clássica, olhar contemporâneo, inspiração nos jardins franceses e paisagismo internacional assinado pela EDSA.\n\nAs opções contemplam plantas de 185 m², 215 m², 248 m² e 355 m².\n\nCaso faça sentido para você, posso encaminhar o material completo e organizar uma visita.${signature}`
    ]
  };

  function safeGet(key, fallback) { try { return localStorage.getItem(key) || fallback; } catch (_) { return fallback; } }
  function safeSet(key, value) { try { localStorage.setItem(key, String(value)); } catch (_) {} }
  function clean(value) { return String(value || '').trim(); }
  function root() { return document.getElementById(ROOT_ID); }
  function targetClosest(event, selector) { return event?.target?.closest ? event.target.closest(selector) : null; }
  function firstWord(text) { return String(text || 'Cliente').trim().split(/\s+/)[0] || 'Cliente'; }
  function bodyText() { return String(document.body?.innerText || ''); }
  function escapeHtml(text) { return String(text || '').replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#039;'); }
  function setText(el, text) { const next = String(text || ''); if (el && el.textContent !== next) el.textContent = next; }
  function normalizePhone(value) { const d = String(value || '').replace(/\D/g, ''); if (!d) return ''; return d.length === 10 || d.length === 11 ? `55${d}` : d; }
  function formatPhone(value) { const d = normalizePhone(value); const br = d.startsWith('55') ? d.slice(2) : d; if (br.length === 11) return `(${br.slice(0,2)}) ${br.slice(2,7)}-${br.slice(7)}`; if (br.length === 10) return `(${br.slice(0,2)}) ${br.slice(2,6)}-${br.slice(6)}`; return clean(value); }

  function getMode() { return runtimeMode === 'empreendimentos' ? 'empreendimentos' : 'origem'; }
  function setMode(mode) { runtimeMode = mode === 'empreendimentos' ? 'empreendimentos' : 'origem'; safeSet(MODE_KEY, runtimeMode); setVariant(0); }
  function getDevelopment() { return DEVELOPMENTS[runtimeDevelopment] ? runtimeDevelopment : 'chateau_jardin'; }
  function setDevelopment(value) { runtimeDevelopment = DEVELOPMENTS[value] ? value : 'chateau_jardin'; safeSet(DEVELOPMENT_KEY, runtimeDevelopment); setVariant(0); }
  function getSituation() { return SITUATIONS[runtimeSituation] ? runtimeSituation : 'convite_lancamento'; }
  function setSituation(value) { runtimeSituation = SITUATIONS[value] ? value : 'convite_lancamento'; safeSet(SITUATION_KEY, runtimeSituation); setVariant(0); }
  function getVariant() { return Number(runtimeVariant) || 0; }
  function setVariant(value) { runtimeVariant = Number(value) || 0; safeSet(VARIANT_KEY, String(runtimeVariant)); }
  function currentChannel() { return root()?.querySelector('[data-pme-channel].active')?.getAttribute('data-pme-channel') || safeGet('fechai_pme_channel', 'ligacao'); }

  function readStoredProfile() { try { return JSON.parse(localStorage.getItem(PROFILE_KEY) || 'null') || null; } catch (_) { return null; } }
  function buildWhatsappProfileLink(phone) { const digits = normalizePhone(phone); return digits ? `https://api.whatsapp.com/send?phone=${digits}` : ''; }
  function extractProfileEmail(row) { return clean(row?.email_prof || row?.email_profissional || row?.email_corretor || row?.email || row?.login_email); }
  function getCorretor() { return clean(profileCache?.nome) || safeGet('fechai_corretor_nome', safeGet('fechai_pme_corretor_nome', 'Corretor responsável')); }
  function getEmpresa() { return clean(profileCache?.empresa) || safeGet('fechai_corretor_empresa', safeGet('fechai_pme_corretor_empresa', 'empresa')); }
  function getCorretorPhone() { return clean(profileCache?.telefone) || safeGet('fechai_corretor_telefone', safeGet('fechai_pme_corretor_telefone', 'telefone não configurado')); }
  function getCorretorWhatsapp() { const stored = clean(profileCache?.whatsapp) || safeGet('fechai_corretor_whatsapp', safeGet('fechai_pme_link_whatsapp_corretor', '')); return stored || buildWhatsappProfileLink(getCorretorPhone()) || 'WhatsApp não configurado'; }
  function inferGmailAuthUser() { const explicit = clean(profileCache?.email) || safeGet('fechai_corretor_email', safeGet('fechai_pme_corretor_email', safeGet('fechai_pme_gmail_authuser', ''))); if (explicit) return explicit; const corretor = getCorretor().toLowerCase(); const empresa = getEmpresa().toLowerCase(); if (corretor.includes('wagner') && empresa.includes('tegra')) return 'wagner@tegravendas.com.br'; return ''; }
  function publishProfile(row) { const nome = clean(row?.apelido || row?.nome); const telefoneSource = row?.telefone_prof || row?.telefone; const profile = { nome, telefone: formatPhone(telefoneSource), whatsapp: buildWhatsappProfileLink(telefoneSource), empresa: clean(row?.empresa || row?.empresa_nome || row?.imobiliaria || 'Tegra Incorporadora'), email: extractProfileEmail(row) }; profileCache = profile; safeSet(PROFILE_KEY, JSON.stringify(profile)); if (profile.nome) { safeSet('fechai_corretor_nome', profile.nome); safeSet('fechai_pme_corretor_nome', profile.nome); } if (profile.telefone) { safeSet('fechai_corretor_telefone', profile.telefone); safeSet('fechai_pme_corretor_telefone', profile.telefone); } if (profile.whatsapp) { safeSet('fechai_corretor_whatsapp', profile.whatsapp); safeSet('fechai_pme_link_whatsapp_corretor', profile.whatsapp); } if (profile.empresa) { safeSet('fechai_corretor_empresa', profile.empresa); safeSet('fechai_pme_corretor_empresa', profile.empresa); } if (profile.email) { safeSet('fechai_corretor_email', profile.email); safeSet('fechai_pme_corretor_email', profile.email); safeSet('fechai_pme_gmail_authuser', profile.email); } }
  function installProfileFetchBridge() { if (window.__fechaiPmeProfileFetchBridgeInstalled) return; window.__fechaiPmeProfileFetchBridgeInstalled = true; const originalFetch = window.fetch; if (typeof originalFetch !== 'function') return; window.fetch = function () { const args = arguments; return originalFetch.apply(this, args).then((response) => { try { const url = String(args[0]?.url || args[0] || ''); if (url.includes('/rest/v1/corretores')) { response.clone().json().then((rows) => { const row = Array.isArray(rows) ? rows[0] : rows; if (row && (row.apelido || row.nome || row.telefone_prof || row.email)) { publishProfile(row); schedulePatch(); } }).catch(() => {}); } } catch (_) {} return response; }); }; }

  function getLeadName() { const tel = document.querySelector('a[href^="tel:"]'); const card = tel ? tel.closest('.bg-white') || tel.closest('[class*="bg-white"]') : null; const title = card ? card.querySelector('h1,h2,h3,[class*="text-xl"],[class*="text-lg"],[class*="font-bold"]') : null; if (title && title.textContent.trim()) return firstWord(title.textContent.trim()); const match = bodyText().match(/Mensagem sugerida\s+Oi,\s*([^,\n]+),/i); return firstWord(match ? match[1] : 'Cliente'); }
  function getPhone() { const tel = document.querySelector('a[href^="tel:"]'); if (tel) return normalizePhone(tel.getAttribute('href')); const m = bodyText().match(/(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?9?\d{4}[-\s]?\d{4}/); return m ? normalizePhone(m[0]) : ''; }
  function getEmail() { const mail = document.querySelector('a[href^="mailto:"]'); if (mail) return String(mail.getAttribute('href') || '').replace(/^mailto:/, '').trim(); const m = bodyText().match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i); return m ? m[0] : ''; }
  function fill(text) { return String(text || '').replaceAll('{{nome}}', getLeadName()).replaceAll('{{corretor}}', getCorretor()).replaceAll('{{telefone_corretor}}', getCorretorPhone()).replaceAll('{{link_whatsapp_corretor}}', getCorretorWhatsapp()).replaceAll('{{empresa}}', getEmpresa()); }
  function currentText() { const list = TEMPLATES[currentChannel()] || TEMPLATES.ligacao; const index = ((getVariant() % list.length) + list.length) % list.length; return fill(list[index]); }
  function parseEmail(text) { const match = String(text || '').match(/^\s*Assunto:\s*([^\n]+)\n+/i); if (!match) return { subject: 'Château Jardin', body: String(text || '') }; return { subject: match[1].trim(), body: String(text || '').slice(match[0].length).trim() }; }
  function gmailLink(to, subject, body) { const authUser = inferGmailAuthUser(); const auth = authUser ? `authuser=${encodeURIComponent(authUser)}&` : ''; return `https://mail.google.com/mail/?${auth}view=cm&fs=1&to=${encodeURIComponent(to || '')}&su=${encodeURIComponent(subject || '')}&body=${encodeURIComponent(body || '')}`; }
  async function copy(text) { try { await navigator.clipboard.writeText(text); } catch (_) { window.prompt('Copie o texto:', text); } }
  async function execute(text) { await copy(text); const channel = currentChannel(); if (channel === 'whatsapp') { const phone = getPhone(); window.open(phone ? `https://api.whatsapp.com/send?phone=${phone}&text=${encodeURIComponent(text)}` : `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`, '_blank', 'noopener,noreferrer'); return; } if (channel === 'email') { const parts = parseEmail(text); window.open(gmailLink(getEmail(), parts.subject, parts.body), '_blank', 'noopener,noreferrer'); return; } const phone = getPhone(); if (phone) window.location.href = `tel:${phone}`; }

  function ensureStyle() { if (document.getElementById(STYLE_ID)) return; const style = document.createElement('style'); style.id = STYLE_ID; style.textContent = `#${ROOT_ID} .pme-text{max-height:calc(1.55em * 3);overflow-y:auto;padding-right:6px;scrollbar-width:thin;}#${ROOT_ID} .pme-inline-mode-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;align-items:stretch;margin:10px auto 8px;max-width:620px;}#${ROOT_ID} .pme-inline-hidden{display:none!important;}#${ROOT_ID} .pme-inline-dev-note{grid-column:1/-1;font-size:12px;color:#64748b;font-weight:800;text-align:center;margin:0 auto;line-height:1.35;max-width:680px;}#${ROOT_ID} [data-pme-inline-mode],#${ROOT_ID} [data-pme-inline-development]{touch-action:manipulation;}@media(max-width:700px){#${ROOT_ID} .pme-text{max-height:calc(1.55em * 5);}#${ROOT_ID} .pme-inline-mode-grid{grid-template-columns:1fr 1fr;gap:8px;}}`; document.head.appendChild(style); }
  function findStepTitleContaining(text) { const r = root(); if (!r) return null; return Array.from(r.querySelectorAll('.pme-step-title')).find((el) => String(el.textContent || '').includes(text)) || null; }
  function sectionBetween(startTitle, endTitle) { if (!startTitle) return []; const out = []; let node = startTitle.nextElementSibling; while (node && node !== endTitle) { out.push(node); node = node.nextElementSibling; } return out; }
  function createModeGrid(mode) { const div = document.createElement('div'); div.className = 'pme-inline-mode-grid'; div.setAttribute('data-pme-inline-mode-grid', '1'); div.innerHTML = `<button type="button" class="pme-pill ${mode === 'origem' ? 'active' : ''}" data-pme-inline-mode="origem">🎯 Origem do lead</button><button type="button" class="pme-pill ${mode === 'empreendimentos' ? 'active' : ''}" data-pme-inline-mode="empreendimentos">🏛️ Empreendimentos</button>`; return div; }
  function updateModeGrid(grid, mode) { grid.querySelectorAll('[data-pme-inline-mode]').forEach((btn) => btn.classList.toggle('active', btn.getAttribute('data-pme-inline-mode') === mode)); }
  function createDevelopmentGrid() { const active = getDevelopment(); const div = document.createElement('div'); div.className = 'pme-origin-grid'; div.setAttribute('data-pme-inline-development-grid', '1'); div.innerHTML = Object.entries(DEVELOPMENTS).map(([key, item]) => `<button type="button" class="pme-pill ${key === active ? 'active' : ''}" data-pme-inline-development="${escapeHtml(key)}">${escapeHtml(item.icon + ' ' + item.label)}</button>`).join('') + `<div class="pme-inline-dev-note">${escapeHtml(DEVELOPMENTS[active]?.hint || '')} Endereço: ${escapeHtml(DEVELOPMENTS[active]?.address || '')}</div>`; return div; }
  function updateDevelopmentGrid(grid) { const active = getDevelopment(); grid.querySelectorAll('[data-pme-inline-development]').forEach((btn) => btn.classList.toggle('active', btn.getAttribute('data-pme-inline-development') === active)); setText(grid.querySelector('.pme-inline-dev-note'), `${DEVELOPMENTS[active]?.hint || ''} Endereço: ${DEVELOPMENTS[active]?.address || ''}`); }
  function createSituationSelect() { const wrap = document.createElement('div'); wrap.className = 'pme-select-wrap'; wrap.setAttribute('data-pme-inline-situation-wrap', '1'); wrap.innerHTML = `<select class="pme-select" data-pme-inline-situation aria-label="Escolha em qual situação o cliente está">${Object.entries(SITUATIONS).map(([key, label]) => `<option value="${escapeHtml(key)}" ${key === getSituation() ? 'selected' : ''}>${escapeHtml(label)}</option>`).join('')}</select>`; return wrap; }
  function updateSituationSelect(wrap) { const select = wrap?.querySelector('[data-pme-inline-situation]'); if (select && select.value !== getSituation()) select.value = getSituation(); }
  function renderReplacementRows(r, originTitle, channelTitle, mode) { sectionBetween(originTitle, channelTitle).forEach((el) => { if (el.matches('[data-pme-inline-mode-grid]')) return; if (el.classList.contains('pme-step-help')) return; el.classList.toggle('pme-inline-hidden', mode === 'empreendimentos'); }); const grid = r.querySelector('[data-pme-inline-development-grid]'); if (mode === 'empreendimentos') { if (grid) updateDevelopmentGrid(grid); else channelTitle.insertAdjacentElement('beforebegin', createDevelopmentGrid()); return; } if (grid) grid.remove(); }

  function observe(target) { if (!observer || !target) return; if (observedTarget === target) return; observer.disconnect(); observedTarget = target; observer.observe(target, { childList: true, subtree: true }); }
  function schedulePatch() { if (patchQueued || isPatching) return; patchQueued = true; window.requestAnimationFrame(() => { patchQueued = false; patch(); }); }
  function patch() { if (isPatching) return; const r = root(); if (!r) { observe(document.body); return; } isPatching = true; if (observer) { observer.disconnect(); observedTarget = null; } try { ensureStyle(); const originTitle = findStepTitleContaining('Escolha a origem'); const channelTitle = findStepTitleContaining('Escolha o canal'); const situationTitle = findStepTitleContaining('Escolha em qual situação'); if (!originTitle || !channelTitle || !situationTitle) return; const mode = getMode(); setText(r.querySelector('.pme-title'), 'Fluxo de atendimento'); setText(r.querySelector('.pme-sub'), 'Siga os passos abaixo. Primeiro escolha a origem ou empreendimento, depois o canal, a situação e por fim execute o contato.'); setText(originTitle, '1. Escolha a origem ou empreendimento'); let modeGrid = r.querySelector('[data-pme-inline-mode-grid]'); if (!modeGrid) { modeGrid = createModeGrid(mode); originTitle.insertAdjacentElement('afterend', modeGrid); } else updateModeGrid(modeGrid, mode); const originHelp = sectionBetween(originTitle, channelTitle).find((el) => el.classList && el.classList.contains('pme-step-help')); setText(originHelp, mode === 'empreendimentos' ? 'Escolha qual empreendimento será trabalhado neste atendimento.' : 'Use Origem do lead para o fluxo padrão ou Empreendimentos para mensagens por projeto.'); renderReplacementRows(r, originTitle, channelTitle, mode); setText(channelTitle, '2. Escolha o canal para contato com o cliente'); setText(situationTitle, '3. Escolha em qual situação o cliente está'); const oldSituation = r.querySelector('[data-pme="approach"]')?.closest('.pme-select-wrap'); const inlineSituation = r.querySelector('[data-pme-inline-situation-wrap]'); if (mode === 'empreendimentos') { if (oldSituation) oldSituation.classList.add('pme-inline-hidden'); if (!inlineSituation && oldSituation) oldSituation.insertAdjacentElement('afterend', createSituationSelect()); else updateSituationSelect(inlineSituation); } else { if (oldSituation) oldSituation.classList.remove('pme-inline-hidden'); if (inlineSituation) inlineSituation.remove(); } setText(r.querySelector('.pme-box-title'), 'Mensagem sugerida'); const textEl = r.querySelector('.pme-text'); if (mode === 'empreendimentos' && textEl) setText(textEl, currentText()); const channelLabel = r.querySelector('[data-pme-channel].active')?.textContent?.replace(/^[^A-Za-zÀ-ÿ0-9]+\s*/u, '').trim() || 'Canal'; const chip = r.querySelector('.pme-chip'); if (chip && mode === 'empreendimentos') setText(chip, `${DEVELOPMENTS[getDevelopment()]?.label || 'Empreendimento'} · ${channelLabel}`); const status = r.querySelector('[data-pme-status]'); if (status && mode === 'empreendimentos') { const blocked = BLOCKED_TERMS.some((term) => currentText().toLowerCase().includes(term.toLowerCase())); setText(status, blocked ? 'Atenção: termo bloqueado detectado na mensagem. Revise antes de usar.' : 'Mensagem de empreendimento carregada. A PME não envia mensagem sozinha e não registra feedback automaticamente.'); } } finally { isPatching = false; observe(root() || document.body); } }

  function stop(event) { event.preventDefault(); event.stopPropagation(); if (typeof event.stopImmediatePropagation === 'function') event.stopImmediatePropagation(); }
  function handleInlineModeEvent(event) { const modeBtn = targetClosest(event, '[data-pme-inline-mode]'); const devBtn = targetClosest(event, '[data-pme-inline-development]'); if (!modeBtn && !devBtn) return false; stop(event); if (Date.now() - lastInlineHandledAt < 80 && event.type === 'click') return true; lastInlineHandledAt = Date.now(); if (modeBtn) setMode(modeBtn.getAttribute('data-pme-inline-mode')); if (devBtn) setDevelopment(devBtn.getAttribute('data-pme-inline-development')); schedulePatch(); return true; }
  function handleInlineActionEvent(event) { if (getMode() !== 'empreendimentos') return false; if (event.type === 'pointerdown') return false; const actionBtn = targetClosest(event, '[data-pme-action]'); if (!actionBtn || !root()?.contains(actionBtn)) return false; const type = actionBtn.getAttribute('data-pme-action'); if (!['next', 'prev', 'use', 'ai'].includes(type)) return false; stop(event); if (event.type === 'click' && Date.now() - lastActionHandledAt < 180) return true; lastActionHandledAt = Date.now(); if (type === 'next') setVariant(getVariant() + 1); if (type === 'prev') setVariant(getVariant() - 1); if (type === 'use') execute(currentText()); if (type === 'ai') copy(currentText()); schedulePatch(); return true; }
  function bind() { if (window.__fechaiPmeEmpreendimentosInlineBound) return; window.__fechaiPmeEmpreendimentosInlineBound = true; ['pointerdown', 'pointerup', 'click'].forEach((eventName) => { document.addEventListener(eventName, function (event) { if (handleInlineModeEvent(event)) return; if (targetClosest(event, '[data-pme-channel]')) schedulePatch(); if (eventName !== 'pointerdown') handleInlineActionEvent(event); }, true); }); document.addEventListener('change', function (event) { const select = targetClosest(event, '[data-pme-inline-situation]'); if (!select) return; stop(event); setSituation(select.value); schedulePatch(); }, true); }
  function start() { installProfileFetchBridge(); bind(); observer = new MutationObserver(() => { if (!isPatching) schedulePatch(); }); observe(document.body); patch(); }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
