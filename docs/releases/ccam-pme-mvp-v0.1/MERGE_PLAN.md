# Merge Plan — Discador Flow AI / PME Beta v0.2.5

## Branch de origem

`feature/ccam-pme-mvp-v0.1`

## Branch de destino

`main`

## PR

#20

---

## Objetivo

Promover o MVP do Discador Flow AI / PME para a branch principal somente após validação funcional, mobile, IA e segurança.

Esta release transforma o discador em um flow operacional assistido para o corretor, mantendo a operação manual e preservando feedback/RPC/RLS/auth/banco.

---

## Arquivos esperados no merge

### Documentação

- `docs/discador-flow-ai/**`
- `docs/branches/BRANCH_REGISTRY.md`
- `docs/main/**`
- `docs/releases/ccam-pme-mvp-v0.1/**`

### Frontend beta controlado

- `public/pme-call-assistant-beta.js`
- `public/pme-call-assistant-ai-context-patch.js`
- `src/main.jsx`
- `src/features/discador-flow-ai/**`

---

## Classificação de risco

**R2 controlado.**

Justificativa:

- Existe alteração funcional no frontend.
- Existe carregamento de script beta no `main.jsx`.
- Não há alteração em banco, RLS, RPC, auth, feedback ou motor de distribuição de leads.
- Rollback é simples: remover carregamento dos scripts ou redeploy anterior.

---

## Condições obrigatórias antes do merge

### Produto

- [ ] Fluxo visual validado no desktop.
- [ ] Fluxo visual validado no celular.
- [ ] Origem do lead responde com clique único.
- [ ] Canal responde com clique único.
- [ ] Combo de situação funciona sem fechar imediatamente.
- [ ] Execução dinâmica funciona para Ligação, WhatsApp e E-mail.
- [ ] Modal da IA respeita o canal escolhido.
- [ ] Dica para IA influencia a resposta.
- [ ] Respostas da IA reduzem repetição após patch v0.2.5.

### Operação

- [ ] Feedback manual registra normalmente.
- [ ] Próximo lead funciona normalmente.
- [ ] Lead ativo carrega normalmente.
- [ ] A ausência/falha da IA não bloqueia o fluxo manual.

### Segurança

- [ ] Console sem segredo sensível.
- [ ] Network sem `service_role`.
- [ ] Sem envio automático sem ação do corretor.
- [ ] Sem alteração em RPC/RLS/auth/grants.
- [ ] Sem dados soberanos vindos do frontend para decisões críticas.

### Deploy

- [ ] Vercel preview verde.
- [ ] Smoke test manual concluído.
- [ ] Documentação da PR atualizada.
- [ ] PR marcada como ready for review somente após checklist.

---

## Estratégia de merge

Preferência: **squash merge**.

Mensagem recomendada:

`feat: adiciona Discador Flow AI / PME Beta v0.2.5`

Corpo recomendado:

```text
- adiciona fluxo assistido do corretor no discador
- adiciona origem do lead, canal, situação e execução dinâmica
- adiciona modal de IA com dica contextual e regras anti-repetição
- preserva feedback, RPC, RLS, auth e banco
- inclui documentação, plano de validação e rollback
```

---

## Estratégia de rollback

### Rollback rápido de frontend

1. Remover do `src/main.jsx` o carregamento de:
   - `/pme-call-assistant-beta.js`;
   - `/pme-call-assistant-ai-context-patch.js`.
2. Redeploy na Vercel.
3. Confirmar que a tela original do discador permanece funcional.

### Rollback por deploy

1. Vercel Dashboard → Deployments.
2. Selecionar deployment anterior estável.
3. Redeploy.

### Rollback por Git

1. Reverter o squash commit da PR #20.
2. Abrir PR de rollback.
3. Fazer merge após validação rápida.

---

## Critérios de rollback imediato

- Feedback não registra.
- Próximo lead falha.
- Lead não carrega.
- Layout mobile fica inutilizável.
- IA trava a operação manual.
- Algum segredo aparece no frontend.
- Algum comportamento automático envia mensagem sem revisão do corretor.

---

## Decisão atual

**Não fazer merge automático.**

A branch deve permanecer em validação controlada até o checklist final no preview. Após validação, marcar PR como ready for review e executar squash merge na `main`.
