# PME — Mobile Touch / DOM Loop Hotfix R3

## Contexto

R3 criada após fechamento sem merge da PR #39.

A PR #39 corrigiu parcialmente a sensibilidade dos botões, mas apresentou regressões durante validação mobile:

- botão Empreendimentos ausente em uma versão;
- sensação de refresh/reprocessamento visual ao clicar em alguns botões;
- diff maior do que o aceitável para hotfix.

## Decisão

A PR #39 foi fechada sem merge.

A R3 parte limpa da `main`, que já contém a PR #38 válida.

A PR #37 permanece descartada.

## Escopo autorizado

Alterado:

```txt
public/pme-empreendimentos-inline-flow.js
docs/power-message-engine/pme-mobile-touch-domloop-r3.md
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

## Correção aplicada

A R3 é um hotfix conservador sobre a base da PR #38/main.

Mudanças principais:

- Remove o `setInterval(patch, 1000)`.
- Troca `schedulePatch()` por fila única via `requestAnimationFrame`.
- Evita remover/recriar o grid `data-pme-inline-mode-grid` a cada patch.
- Evita remover/recriar o grid `data-pme-inline-development-grid` a cada patch.
- Atualiza classes `active` e textos somente quando necessário.
- Não intercepta `pointerdown` de `[data-pme-action]`.
- Restringe interceptação de `[data-pme-action]` no modo Empreendimentos às ações `next`, `prev`, `use` e `ai`.
- Mantém observer em `document.body`, porém coalescido por `schedulePatch()` para preservar bootstrap do botão Empreendimentos sem recriar DOM em cascata.

## Preservado

- Botão Empreendimentos.
- Ramificação Château Jardin.
- WhatsApp em formato compatível.
- Gmail Compose.
- Assinatura: `Na recepção, solicite por {{corretor}} da {{empresa}}.`
- Variáveis do corretor via retorno existente de `/rest/v1/corretores`.

## Checklist de validação

Mobile:

```txt
[ ] Botão Empreendimentos aparece.
[ ] Clique em Empreendimentos abre a ramificação sem refresh visual estranho.
[ ] Château Jardin aparece.
[ ] Botões de classificação da ligação respondem com 1 toque.
[ ] Botão Ligar responde com 1 toque.
[ ] Botão WhatsApp/Mensagem responde com 1 toque.
[ ] Botão E-mail responde com 1 toque.
[ ] Botão Voltar para início responde com 1 toque.
[ ] Botão próxima variação funciona.
[ ] Botão copiar/usar funciona.
[ ] WhatsApp abre corretamente.
[ ] Gmail Compose abre corretamente.
```

Desktop:

```txt
[ ] Fluxo origem continua funcionando.
[ ] Fluxo Empreendimentos continua funcionando.
[ ] Sem erro novo em console.
[ ] Sem erro novo relevante em network.
```

## Observação arquitetural

A solução definitiva de arquitetura continua sendo migrar Empreendimentos para dentro do motor/state machine principal do PME, eliminando enhancer baseado em DOM. Essa refatoração não faz parte deste hotfix.
