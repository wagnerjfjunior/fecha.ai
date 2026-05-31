# PME — Mobile Touch / DOM Loop Hotfix R2

## Contexto

Hotfix criado para corrigir perda de sensibilidade em botões antigos do Discador/Central de Mensagens no mobile após a entrada do enhancer PME Empreendimentos.

Sintomas relatados:

```txt
- botões de classificação da ligação exigindo 2 a 4 toques;
- botão Ligar exigindo múltiplos toques;
- botões de Mensagem/WhatsApp/e-mail com baixa responsividade;
- botão Voltar para início com baixa responsividade;
- botões novos de Empreendimentos respondendo melhor.
```

## Base da correção

Esta branch parte da `main` após a PR #38.

A PR #37 permanece descartada e não deve ser usada como referência.

## Escopo autorizado

Alterado:

```txt
public/pme-empreendimentos-inline-flow.js
docs/power-message-engine/pme-mobile-touch-domloop-r2.md
```

Não alterado:

```txt
src/App.jsx
src/main.jsx
public/pme-call-assistant-beta.js
Supabase
RLS
RPC
Auth
MesaCliente
Worker
Make/n8n
motor financeiro
migrations
seed
```

## Causa confirmada

O problema estava no enhancer frontend-only `public/pme-empreendimentos-inline-flow.js`.

O ciclo identificado foi:

```txt
MutationObserver -> patch() -> alteração de DOM -> MutationObserver -> patch()
```

Na versão anterior, o `patch()` removia e recriava blocos de DOM a cada execução, especialmente:

```txt
[data-pme-inline-mode-grid]
[data-pme-inline-development-grid]
```

Além disso, havia `setInterval(patch, 1000)` e interceptação global em capture para `pointerdown`, `pointerup` e `click`.

## Correção aplicada

- Removido `window.setInterval(patch, 1000)`.
- `schedulePatch()` agora usa coalescing real com `requestAnimationFrame` único.
- `patch()` passou a ser controlado por `isPatching` e `patchQueued`.
- `MutationObserver` não observa mais `document.body` inteiro: passa a observar o root do PME quando disponível.
- O observer é desconectado durante o `patch()` e reconectado ao final.
- `modeGrid` deixa de ser removido/recriado a cada patch; se já existe, apenas atualiza classe `active`.
- `developmentGrid` deixa de ser removido/recriado a cada patch; se já existe, apenas atualiza classe `active` e texto de apoio.
- O enhancer deixa de interceptar `pointerdown` de `[data-pme-action]`.
- `data-pme-action` só é tratado pelo enhancer quando o modo atual é `empreendimentos` e a ação é `use`, `prev`, `next` ou `ai`.
- Mantidos WhatsApp, Gmail Compose, assinatura do corretor e orientação de recepção da PR #38.

## Decisão técnica

Esta correção não é workaround visual nem debounce artificial em botão.

O objetivo é eliminar o loop de DOM e reduzir a disputa de eventos com o motor original do PME, mantendo o enhancer dentro da arquitetura atual.

## Risco residual

A solução arquitetural futura recomendada é integrar Empreendimentos diretamente ao motor principal/state machine do PME, removendo a necessidade de enhancer baseado em DOM + MutationObserver.

Essa refatoração fica fora deste hotfix.

## Checklist de validação

Mobile:

```txt
[ ] Botão Voltar para início responde com 1 toque.
[ ] Botões de classificação da ligação respondem com 1 toque.
[ ] Botão Ligar responde com 1 toque.
[ ] Botão WhatsApp/Mensagem responde com 1 toque.
[ ] Botão E-mail responde com 1 toque.
[ ] Origem do lead continua funcionando.
[ ] Empreendimentos continua funcionando.
[ ] Château Jardin continua funcionando.
[ ] WhatsApp abre corretamente.
[ ] Gmail Compose abre corretamente.
[ ] Tela parada não gera loop contínuo de mutações.
[ ] Não ocorre alternância automática de tela.
```

Desktop:

```txt
[ ] Fluxo padrão por origem sem regressão.
[ ] Fluxo Empreendimentos sem regressão.
[ ] WhatsApp funcionando.
[ ] Gmail Compose funcionando.
[ ] Console sem erro novo.
[ ] Network sem erro novo relevante.
```
