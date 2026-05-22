# MAIN ROLLBACK LOG — FECH.AI

Registro de rollback ou desativação de features promovidas ou candidatas a `main`.

---

## Discador Flow AI / PME MVP v0.1

**Status:** não aplicado em main  
**Branch:** `feature/ccam-pme-mvp-v0.1`  
**PR:** #20  
**Feature flag futura sugerida:** `discador_flow_ai_enabled`

### Rollback visual

- Remover/desativar carregamento do script `public/pme-call-assistant-beta.js`.
- Retornar ao Discador atual sem bloco PME beta.

### Rollback IA

- Ocultar botão `Melhorar com IA`.
- Manter templates/scripts locais funcionando.
- Exibir estado: `IA indisponível no momento`.

### Rollback backend

- Não aplicável enquanto não houver migration/RPC/Edge versionada no repo.
- Se houver Edge Function futura, manter versão anterior ou desabilitar rota.

### Rollback crítico

- Reverter merge commit ou redeploy anterior no Vercel.

### Observação

O feedback e o motor de leads não devem depender do Discador Flow AI no MVP. O assistente deve ser sempre removível sem derrubar operação.
