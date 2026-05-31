# PME Empreendimentos — Mobile DOM/Event Hotfix R1

## Contexto

Hotfix criado após validação do módulo PME Empreendimentos em produção/preview. O sintoma observado no mobile foi perda de sensibilidade em botões do Discador/Central de Mensagens: alguns botões precisavam de 2 a 4 toques para responder.

## Escopo autorizado

Alterar somente:

```txt
public/pme-empreendimentos-inline-flow.js
```

Não alterar:

```txt
src/App.jsx
src/main.jsx
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

## Causa técnica

O problema foi localizado no enhancer frontend-only do módulo Empreendimentos. A versão anterior fazia duas coisas ruins para mobile:

1. Reprocessava o DOM de forma recorrente, usando `setInterval(patch, 1000)` combinado com `MutationObserver`.
2. Interceptava eventos globais em capture para `pointerdown`, `pointerup` e `click`, inclusive para botões do fluxo original.

Na prática, o script novo competia com o motor original do PME, especialmente no mobile, onde `pointerup/click` são mais sensíveis a interceptações.

## Estratégia adotada

Esta correção não é workaround visual. É correção estrutural do enhancer:

- remover polling por intervalo;
- tornar o `patch()` idempotente;
- evitar recriar botões já existentes;
- reconectar o `MutationObserver` de forma controlada;
- não interceptar `pointerdown` dos botões originais;
- interceptar somente controles próprios de Empreendimentos e ações `use`, `prev`, `next`, `ai` quando o modo ativo for `empreendimentos`;
- deixar botões de classificação da ligação, voltar início e demais ações do app original passarem limpos para o motor original.

## Critérios de aceite

Checklist obrigatório no mobile:

```txt
1. Botão Voltar para início responde com 1 toque.
2. Botões de classificação da ligação respondem com 1 toque.
3. Origem do lead continua funcionando.
4. Empreendimentos continua funcionando.
5. Château Jardin continua funcionando.
6. WhatsApp continua funcionando.
7. Gmail Compose continua funcionando.
8. Desktop não regride.
```

## Observação

A PR #37 continua descartada e não deve ser usada como base. Esta branch parte do merge da PR #38.
