/*
 * FECH.AI — PME inline flow layout fix
 * Version: 0.3.1
 * Purpose: ajustar o fluxo visual do assistente PME sem alterar engine, RPC, banco ou envio.
 */
(function () {
  'use strict';

  const ROOT_ID = 'fechai-pme-call-assistant';
  const STYLE_ID = 'fechai-pme-inline-layout-fix-style';

  function stripIcon(text) {
    return String(text || '').replace(/^[^A-Za-zÀ-ÿ0-9]+\s*/u, '').trim();
  }

  function activeLabel(root, selector, fallback) {
    const el = root.querySelector(selector);
    return el ? stripIcon(el.textContent) : fallback;
  }

  function setText(el, text) {
    if (el && el.textContent !== text) el.textContent = text;
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `
      #${ROOT_ID} .pme-text{
        max-height:calc(1.55em * 3);
        overflow-y:auto;
        padding-right:6px;
        scrollbar-width:thin;
      }
      #${ROOT_ID} .pme-inline-hidden-title{
        display:none !important;
      }
      #${ROOT_ID} .pme-group-grid{
        max-width:620px;
      }
      #${ROOT_ID} .pme-origin-grid{
        margin-top:8px;
      }
      #${ROOT_ID} .pme-box-title{
        display:flex;
        align-items:center;
        gap:8px;
      }
      @media(max-width:700px){
        #${ROOT_ID} .pme-text{
          max-height:calc(1.55em * 5);
        }
      }
    `;
    document.head.appendChild(style);
  }

  function patchFlowLabels() {
    ensureStyle();
    const root = document.getElementById(ROOT_ID);
    if (!root) return;

    const title = root.querySelector('.pme-header .pme-title');
    const sub = root.querySelector('.pme-header .pme-sub');
    setText(title, 'Fluxo de atendimento');
    setText(sub, 'Siga os passos abaixo. Primeiro escolha a origem ou empreendimento, depois o canal, a situação e por fim execute o contato.');

    const groupGeral = root.querySelector('[data-group="geral"]');
    const groupEmpreendimentos = root.querySelector('[data-group="empreendimentos"]');
    if (groupGeral) groupGeral.innerHTML = '🎯 Origem do lead';
    if (groupEmpreendimentos) groupEmpreendimentos.innerHTML = '🏛️ Empreendimentos';

    const activeGroup = root.querySelector('[data-group].active')?.getAttribute('data-group') || 'geral';
    const activeChannel = activeLabel(root, '[data-channel].active', 'Canal');
    const activeContext = activeGroup === 'empreendimentos'
      ? activeLabel(root, '[data-development].active', 'Château Jardin')
      : activeLabel(root, '[data-context].active', 'Origem do lead');
    const chip = root.querySelector('.pme-header .pme-chip');
    if (chip) chip.textContent = `${activeContext} · ${activeChannel}`;

    const titles = Array.from(root.querySelectorAll('.pme-step-title'));
    titles.forEach((el) => {
      const txt = String(el.textContent || '').trim();
      el.classList.remove('pme-inline-hidden-title');
      if (txt === '1. Grupo de mensagens') setText(el, '1. Escolha a origem ou empreendimento');
      if (txt === '2. Empreendimento' || txt === '2. Origem do lead') el.classList.add('pme-inline-hidden-title');
      if (txt === '3. Canal') setText(el, '2. Escolha o canal para contato com o cliente');
      if (txt === '4. Situação do lead') setText(el, '3. Escolha em qual situação o cliente está');
    });

    const helps = Array.from(root.querySelectorAll('.pme-step-help'));
    helps.forEach((el) => {
      const txt = String(el.textContent || '').trim();
      if (txt.includes('Use "Geral"')) setText(el, 'Selecione Origem do lead para o fluxo padrão ou Empreendimentos para trabalhar mensagens por projeto.');
      if (txt.includes('A execução continua manual')) setText(el, 'Defina se vai ligar, chamar no WhatsApp ou preparar um e-mail.');
      if (txt.includes('Situações específicas') || txt.includes('Escolha a melhor abordagem')) setText(el, 'Isso muda a mensagem sugerida para o corretor usar agora.');
    });

    const boxTitle = root.querySelector('.pme-box-title');
    if (boxTitle && !boxTitle.textContent.startsWith('Mensagem sugerida')) {
      boxTitle.textContent = boxTitle.textContent.replace(/^.*?Variação/i, 'Mensagem sugerida • Variação');
    }

    const execTitle = root.querySelector('.pme-exec-title');
    setText(execTitle, '4. Executar contato');
  }

  function start() {
    patchFlowLabels();
    const observer = new MutationObserver(() => window.requestAnimationFrame(patchFlowLabels));
    observer.observe(document.body, { childList: true, subtree: true });
    window.setInterval(patchFlowLabels, 1500);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
