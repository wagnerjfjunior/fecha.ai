# BRANCH REGISTRY — FECH.AI

Registro oficial das branches de trabalho do projeto.

---

## baseline/discador-flow-ai-pme-v0.2.6-stable

**Status:** baseline estável  
**Criada em:** 2026-05-23  
**Commit base:** `b35c30bafdfc9e65a468e5bd688679d8c08932dd`  
**PR de origem:** #21 — `feat: PME AI prompt inline v0.2.6`  
**Release package:** `docs/releases/discador-flow-ai-pme-v0.2.6-stable/`  
**Objetivo:** marcar a versão estável do Discador Flow AI / PME com IA contextual inline, sem patch global e com login/snapshot validados.

### Estado validado

- Login funcionando.
- Snapshot funcionando.
- Discador Flow AI funcionando.
- IA contextual funcionando.
- Feedback preservado.
- Próximo lead preservado.
- Sem `window.fetch` global.
- Sem patch externo carregado.
- Sem alteração em RPC/RLS/auth/banco.

### Regra técnica registrada

Não usar monkey patch global em `window.fetch` no FECH.AI. Melhorias futuras da IA devem ser locais, explícitas e testadas em preview.

---

## feature/pme-ai-prompt-inline-v0.2.6

**Status:** mergeada em `main`  
**Criada em:** 2026-05-23  
**PR:** #21  
**Merge commit:** `b35c30bafdfc9e65a468e5bd688679d8c08932dd`  
**Objetivo:** corrigir a IA contextual diretamente em `public/pme-call-assistant-beta.js`, sem usar `pme-call-assistant-ai-context-patch.js` e sem interceptar `window.fetch`.

### Escopo entregue

- Versão do módulo atualizada para `0.2.6`.
- Prompt contextual inline no `buildAiPrompt()`.
- Dica do corretor como diretriz principal.
- Regras anti-repetição.
- Regras por canal: Ligação, WhatsApp e E-mail.
- Regras por situação comercial.
- Variação por tentativa da IA.
- Sem alteração em `src/main.jsx`.
- Sem alteração em auth, snapshot, RPC, RLS, feedback ou banco.

### Resultado

- Validado em preview.
- Squash merge efetuado na PR #21.
- Produção/main validada como funcionando.

---

## feature/ccam-pme-mvp-v0.1

**Status:** mergeada parcialmente / substituída por baseline v0.2.6  
**Criada em:** 2026-05-22  
**PR:** #20  
**Objetivo:** Implementar o MVP do Discador Flow AI / PME como fluxo operacional do corretor.  
**Diretório de protocolo:** `docs/discador-flow-ai/`  
**Release package:** `docs/releases/ccam-pme-mvp-v0.1/`  
**Branch alvo:** `main`, após validação controlada.  

### Escopo entregue

- Organização documental do MVP.
- Correção visual mobile do assistente PME no discador.
- Badges de situação do lead.
- Canal WhatsApp/Ligação/E-mail.
- Modal de mensagem/script.
- Fluxo assistido do corretor.
- Execução dinâmica por canal.
- Registro conceitual de eventos, score, feedback e base reutilizável.

### Observação técnica

A tentativa de carregar `pme-call-assistant-ai-context-patch.js` foi removida da produção porque interceptava `window.fetch` globalmente e causou impacto em login/snapshot. A correção definitiva foi feita posteriormente na PR #21, com IA contextual inline no script principal.

### Fora de escopo sem contrato novo

- Alterar motor de feedback.
- Alterar `proximo_lead`, `solicitar_lote` ou `registrar_feedback`.
- Alterar RLS, grants ou policies em produção.
- Envio automático de WhatsApp/e-mail.
- Billing definitivo do módulo IA.

### Rollback

- Desativar script `pme-call-assistant-beta.js`.
- Manter discador/feedback original intacto.
- Desativar botão de IA se a Edge Function falhar.

### Condição para merge em main

- Caderno de testes PASS.
- Validação mobile PASS.
- IA com CORS/JWT corrigidos.
- Sem exposição de chave sensível.
- Aprovação explícita do dono do projeto.
