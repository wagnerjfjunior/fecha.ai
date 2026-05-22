# Rollback Plan — Discador Flow AI / PME Beta v0.2.5

## Objetivo

Garantir que o MVP possa ser desativado sem afetar discador, leads, feedbacks, RPCs, RLS, auth ou operação comercial.

---

## Escopo do rollback

Arquivos funcionais envolvidos:

- `src/main.jsx`
- `public/pme-call-assistant-beta.js`
- `public/pme-call-assistant-ai-context-patch.js`

Documentações podem permanecer no repositório mesmo em caso de rollback funcional.

---

## Rollback rápido — desativar Discador Flow AI

1. Remover do `src/main.jsx` o carregamento do script:

```js
loadPmeScript('fechai-pme-call-assistant-beta-loader', '/pme-call-assistant-beta.js')
```

2. Remover também o carregamento do patch:

```js
loadPmeScript('fechai-pme-call-assistant-ai-context-patch-loader', '/pme-call-assistant-ai-context-patch.js')
```

3. Fazer deploy.
4. Validar:
   - login;
   - discador original;
   - feedback;
   - próximo lead.

---

## Rollback parcial — desativar somente IA contextual

Usar quando o fluxo visual estiver bom, mas a IA estiver ruim/repetitiva/instável.

1. Manter `pme-call-assistant-beta.js`.
2. Remover apenas o carregamento de:

```js
/pme-call-assistant-ai-context-patch.js
```

3. Fazer deploy.
4. Validar que o fluxo manual continua ativo.

---

## Rollback de IA por falha de sessão ou Edge Function

Se a Edge Function falhar, a operação manual deve continuar.

Comportamento esperado:

- Exibir mensagem amigável de IA indisponível.
- Manter texto base disponível.
- Não bloquear ligação, WhatsApp, e-mail ou feedback.

Mensagem recomendada:

`IA indisponível no momento. Use o texto base e siga o atendimento normalmente.`

---

## Rollback de banco

Não aplicável nesta etapa.

Esta release não aplica migration, não altera RLS, não altera RPC, não altera grants e não cria tabelas novas.

---

## Rollback por Vercel

1. Acessar Vercel Dashboard.
2. Abrir projeto `fecha.ai`.
3. Ir em Deployments.
4. Selecionar último deployment estável anterior ao merge.
5. Executar Redeploy.
6. Validar discador e feedback.

---

## Rollback por Git

1. Identificar o squash commit da PR #20 na `main`.
2. Criar branch de rollback:

```bash
git checkout main
git pull origin main
git checkout -b rollback/discador-flow-ai-v0.2.5
```

3. Reverter o commit:

```bash
git revert <sha-do-squash-commit>
```

4. Abrir PR de rollback.
5. Fazer validação rápida e merge.

---

## Condição de rollback imediato

Executar rollback se ocorrer qualquer item abaixo:

- Feedback não registra.
- Próximo lead não funciona.
- Lead ativo não carrega.
- Layout mobile fica inutilizável.
- IA trava o atendimento manual.
- Algum segredo aparece no frontend.
- Alguma chamada usa `service_role` no navegador.
- Alguma ação envia mensagem sem revisão do corretor.
- O script causa erro global que afeta outras telas.

---

## Critério de sucesso do rollback

- Tela original do discador carrega.
- Corretor consegue ligar/chamar manualmente.
- Feedback registra.
- Próximo lead funciona.
- Console sem erro bloqueante.
- Sem regressão em autenticação.
