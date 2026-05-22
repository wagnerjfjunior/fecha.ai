# BRANCH REGISTRY — FECH.AI

Registro oficial das branches de trabalho do projeto.

---

## feature/ccam-pme-mvp-v0.1

**Status:** aberta / PR draft  
**Criada em:** 2026-05-22  
**PR:** #20  
**Objetivo:** Implementar o MVP do Discador Flow AI / PME como fluxo operacional do corretor.  
**Diretório de protocolo:** `docs/discador-flow-ai/`  
**Release package:** `docs/releases/ccam-pme-mvp-v0.1/`  
**Branch alvo:** `main`, somente após validação.  

### Escopo

- Organização documental do MVP.
- Correção visual mobile do assistente PME no discador.
- Badges de situação do lead.
- Canal WhatsApp/Ligação/E-mail.
- Modal de mensagem/script.
- Melhoria com IA via Edge Function segura.
- Registro conceitual de eventos, score, feedback e base reutilizável.

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
