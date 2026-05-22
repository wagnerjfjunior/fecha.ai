# MAIN UPDATE REGISTRY — FECH.AI

Registro oficial de alterações planejadas, aprovadas e promovidas para `main`.

---

## [PENDENTE] Discador Flow AI / PME MVP v0.1

**Branch de origem:** `feature/ccam-pme-mvp-v0.1`  
**PR:** #20  
**Diretório de protocolo:** `docs/discador-flow-ai/`  
**Release package:** `docs/releases/ccam-pme-mvp-v0.1/`  
**Tipo:** feature/documentação/estrutura/MVP frontend  
**Impacto esperado:** Discador, PME, IA assistida, UX mobile.  
**Status:** em especificação e implementação controlada.

### Escopo que poderá subir para main

- Nova organização do Discador como Flow operacional do corretor.
- Badges de situação.
- Canal: WhatsApp, Ligações e E-mail.
- Tipos de abordagem.
- Modal de mensagem/script.
- Botão `Melhorar com IA` com fallback.
- Correção da Edge Function `assistente-ai`, se houver arquivo versionado.
- Caderno de testes e validação.

### Fora do merge para main

- Envio automático de WhatsApp.
- WABA oficial.
- SMTP real.
- Automação de e-mail.
- IA registrando feedback automaticamente.
- IA movendo lead no funil.
- Alteração em RLS/RPC sem contrato novo.

### Pré-condições para merge

- Contrato revisado.
- Dry-run executado.
- Teste mobile aprovado.
- JWT expirado tratado.
- IA não quebra fluxo manual.
- Rollback validado.

### Plano de rollback

- Remover ou desativar carregamento do script PME beta.
- Manter discador atual intacto.
- Desativar botão IA.
- Manter feedback funcionando.

### Status pós-merge

Pendente.
