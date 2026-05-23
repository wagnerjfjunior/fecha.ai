# ROLLBACK_PLAN — PME Usage Tracking & Script Utility v0.2.7

## 1. Objetivo

Garantir que qualquer problema no tracking de uso dos scripts possa ser revertido sem afetar:

- login;
- snapshot;
- discador;
- IA;
- feedback;
- próximo lead;
- auth;
- RPCs críticas existentes;
- operação comercial do corretor.

---

## 2. Princípio de rollback

O tracking é secundário. O atendimento é principal.

Se tracking falhar, o corretor deve continuar usando o fluxo normalmente.

---

## 3. Rollback de frontend

Se a função de tracking no `pme-call-assistant-beta.js` causar erro:

1. Desativar chamadas de tracking.
2. Manter Discador Flow AI ativo.
3. Manter IA ativa.
4. Manter execução por canal.
5. Validar feedback e próximo lead.

Estratégia recomendada no código:

- função `trackPmeUsage()` deve ter feature flag local;
- erro deve ser capturado por `try/catch`;
- não lançar exceção para a UI.

Pseudo-regra:

```js
try {
  trackPmeUsage(eventPayload)
} catch (_) {
  // Nunca bloquear atendimento
}
```

---

## 4. Rollback de backend/RPC

Se a RPC falhar ou causar lentidão:

1. Revogar temporariamente execução da RPC, se necessário.
2. Desativar feature flag do frontend.
3. Manter app funcional sem tracking.
4. Investigar logs.

A falha da RPC não deve quebrar o discador.

---

## 5. Rollback de migration

Se a tabela/policy causar problema:

### Caso simples

- Reverter PR/migration.
- Remover ou desativar função RPC.
- Manter frontend sem tracking.

### Caso com dados já gravados

- Não dropar dados imediatamente sem análise.
- Revogar acesso.
- Corrigir policy/RPC.
- Preservar trilha para auditoria.

---

## 6. Critérios de rollback imediato

Executar rollback se ocorrer qualquer item abaixo:

- login falha;
- snapshot falha;
- discador não abre;
- lead não carrega;
- feedback não registra;
- próximo lead falha;
- IA deixa de funcionar por causa do tracking;
- erro global de JavaScript;
- console/network expõe token ou segredo;
- tracking envia texto completo sem aprovação;
- evento aparece em tenant/empresa errada;
- RLS permite acesso cruzado;
- envio de WhatsApp/e-mail é disparado automaticamente sem revisão.

---

## 7. Rollback por Git

Se a v0.2.7 for mergeada:

```bash
git checkout main
git pull origin main
git checkout -b rollback/pme-usage-tracking-v0.2.7
git revert <sha-do-squash-commit>
```

Depois:

1. abrir PR de rollback;
2. validar preview;
3. fazer merge;
4. confirmar produção.

---

## 8. Rollback por Vercel

1. Acessar Vercel Dashboard.
2. Abrir projeto `fecha.ai`.
3. Ir em Deployments.
4. Selecionar deployment estável anterior à v0.2.7.
5. Redeploy.
6. Validar login, snapshot, discador, feedback e próximo lead.

---

## 9. Baseline segura

Baseline de referência:

`baseline/discador-flow-ai-pme-v0.2.6-stable`

Commit:

`b35c30bafdfc9e65a468e5bd688679d8c08932dd`

Se houver dúvida, voltar para a v0.2.6 stable.

---

## 10. Critério de sucesso do rollback

Rollback considerado bem-sucedido quando:

- login funciona;
- snapshot funciona;
- Discador Flow AI aparece;
- IA contextual funciona ou ao menos não bloqueia;
- execução por canal funciona;
- feedback registra;
- próximo lead funciona;
- console sem erro global;
- sem exposição de dados sensíveis.
