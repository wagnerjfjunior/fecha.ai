# Rollback Plan — Discador Flow AI / PME MVP v0.1

## Objetivo

Garantir que o MVP possa ser desativado sem afetar discador, leads, feedbacks ou operação comercial.

---

## Rollback Rápido

1. Remover carregamento do script `pme-call-assistant-beta.js`.
2. Ocultar bloco Discador Flow AI.
3. Manter tela original do discador.
4. Manter feedback manual.
5. Desativar botão IA.

## Rollback de IA

- Se a Edge Function falhar, ocultar ou desabilitar `Melhorar com IA`.
- Exibir mensagem: `IA indisponível no momento. Use o texto base.`
- Não impedir cópia de mensagens/scripts.

## Rollback de banco

Não aplicável nesta etapa enquanto não houver migration aplicada.

## Rollback de produção

- Vercel Dashboard → Deployments → selecionar build anterior → Redeploy.
- Ou revert/squash revert do PR.

## Condição de rollback imediato

- Feedback não registra.
- Lead não carrega.
- Layout mobile fica inutilizável.
- IA trava a operação manual.
- Algum segredo aparece no frontend.
