# Merge Plan — Discador Flow AI / PME MVP v0.1

## Branch de origem

`feature/ccam-pme-mvp-v0.1`

## Branch de destino

`main`

## Objetivo

Promover o MVP do Discador Flow AI / PME para a branch principal somente após validação documental, funcional, mobile e de segurança.

## Arquivos esperados no merge

### Documentação

- `docs/discador-flow-ai/**`
- `docs/branches/BRANCH_REGISTRY.md`
- `docs/main/**`
- `docs/releases/ccam-pme-mvp-v0.1/**`

### Frontend isolado

- `src/features/discador-flow-ai/**`
- `public/pme-call-assistant-beta.js`, se a alteração visual/IA beta for aprovada.

## Condição de merge

- Contrato aprovado.
- Caderno de testes preenchido.
- HAR/console analisado.
- JWT expirado tratado ou documentado.
- IA com fallback funcional.
- Sem regressão no discador.
- Sem alteração em feedback/RPC/RLS não aprovada.

## Estratégia de merge

Preferência: squash merge, com mensagem clara:

`feat: adiciona MVP Discador Flow AI / PME v0.1`

## Estratégia de rollback

- Reverter merge commit ou redeploy anterior.
- Desativar script beta.
- Manter feedback e lead flow originais.
