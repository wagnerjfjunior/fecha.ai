# Baseline — Discador Flow AI / PME v0.2.6 Stable

**Status:** stable  
**Data:** 2026-05-23  
**Branch baseline:** `baseline/discador-flow-ai-pme-v0.2.6-stable`  
**Main commit:** `b35c30bafdfc9e65a468e5bd688679d8c08932dd`  
**PR:** #21 — `feat: PME AI prompt inline v0.2.6`  
**Arquivo funcional principal:** `public/pme-call-assistant-beta.js`

---

## Resumo executivo

Esta baseline marca a primeira versão estável do **Discador Flow AI / PME** com IA contextual inline funcionando em produção/main, sem uso de patch externo e sem interceptação global de rede.

A versão anterior com `pme-call-assistant-ai-context-patch.js` foi descartada para produção porque interceptava `window.fetch` globalmente e causou impacto em login/snapshot. A v0.2.6 corrige o problema incorporando a melhoria diretamente no script principal `pme-call-assistant-beta.js`.

---

## Validação confirmada

Validação manual reportada como positiva:

- login funcionando;
- snapshot funcionando;
- Discador Flow AI carregando;
- fluxo visual funcionando;
- badges funcionando;
- combo funcionando;
- modal de IA funcionando;
- dica da IA influenciando o contexto;
- execução por canal preservada;
- feedback preservado;
- próximo lead preservado.

---

## Escopo funcional congelado

### Discador Flow AI

- Header `Discador Flow AI`.
- Card `Fluxo de atendimento`.
- Origem do lead:
  - Carteira;
  - Lista fria;
  - Já visitou;
  - Redes Sociais;
  - Problemas;
  - Argumentações.
- Canal:
  - Ligação;
  - WhatsApp;
  - E-mail.
- Situação comercial:
  - Primeira abordagem;
  - Retorno;
  - Pós-ligação;
  - Convite para visita;
  - Objeção de preço;
  - Objeção de entrada;
  - Cliente sem resposta;
  - Fim de contato.
- Execução dinâmica:
  - Ligação → `Efetuar ligação`;
  - WhatsApp → `Abrir WhatsApp`;
  - E-mail → `Preparar e-mail`.

### IA inline

- Prompt contextual dentro de `buildAiPrompt()`.
- Dica do corretor tratada como diretriz principal.
- Regras por canal:
  - ligação;
  - WhatsApp;
  - e-mail.
- Regras por situação:
  - objeção de entrada;
  - objeção de preço;
  - sem resposta;
  - convite;
  - retorno;
  - fim de contato.
- Estratégias de variação por tentativa.
- Regras anti-repetição.
- Regras de segurança comercial.

---

## Limites de segurança preservados

Esta baseline não altera:

- `window.fetch` global;
- `src/main.jsx` após o hotfix estável;
- Supabase migrations;
- RPCs;
- RLS;
- grants;
- auth;
- feedback;
- motor de distribuição de lead;
- banco de dados;
- Worker;
- Make/n8n;
- envio automático de mensagem;
- billing real.

A IA permanece assistiva: o corretor revisa antes de executar ligação, WhatsApp ou e-mail.

---

## Decisão técnica registrada

Regra permanente para este módulo:

> Não usar monkey patch global em `window.fetch` no FECH.AI.

Qualquer melhoria futura da IA deve ser implementada de forma explícita e local no módulo responsável, preferencialmente dentro do próprio fluxo do Discador Flow AI ou via função dedicada controlada.

---

## Rollback

Rollback rápido:

1. Reverter o commit `b35c30bafdfc9e65a468e5bd688679d8c08932dd`; ou
2. Restaurar `public/pme-call-assistant-beta.js` para a versão anterior estável da `main`; ou
3. Desativar o carregamento do script `pme-call-assistant-beta.js` no `src/main.jsx`, em último caso.

Critérios de rollback imediato:

- login falha;
- snapshot falha;
- discador não abre;
- lead não carrega;
- feedback não registra;
- próximo lead falha;
- IA trava o fluxo manual;
- qualquer segredo aparece no frontend;
- qualquer envio automático ocorre sem revisão do corretor.

---

## Próxima evolução recomendada

Próxima versão sugerida:

`v0.2.7 — PME Usage Tracking & Script Utility`

Objetivo:

- registrar qual mensagem/script foi utilizado;
- registrar se foi texto base ou IA;
- registrar canal, origem e situação;
- permitir nota/utilidade do script;
- criar base reutilizável para reduzir chamadas futuras de IA;
- preparar o módulo pagável de IA por empresa/tenant.

Importante: a próxima versão deve seguir o mesmo padrão de branch → preview → validação → PR → squash merge.
