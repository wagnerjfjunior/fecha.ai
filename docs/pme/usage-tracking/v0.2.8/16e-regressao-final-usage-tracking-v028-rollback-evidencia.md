# FECH.AI — PME Usage Tracking v0.2.8

## Evidência 16E — Regressão final Usage Tracking DB/RLS/RPC com rollback

**Branch:** `feature/pme-usage-tracking-db-v0.2.8`  
**Teste:** `16E`  
**Arquivo executado:** `supabase/tests/pme/usage-tracking/16e_regressao_final_usage_tracking_v028_rollback.sql`  
**Tipo:** regressão final com fixture transacional  
**DDL persistente:** não  
**DML:** sim, apenas fixture transacional  
**Persistência esperada:** nenhuma, por `ROLLBACK`  
**Status final:** `PASS`

---

## Objetivo

Validar, em uma única regressão consolidada, a entrega da v0.2.8 para a RPC:

```sql
public.pme_registrar_message_usage(uuid, jsonb)
```

A evidência consolida:

1. contrato/catálogo da RPC;
2. RLS e hardening mínimo das tabelas PME;
3. fixture operacional com empresa, usuário, corretor, lead e templates;
4. execução positiva append-only;
5. persistência transacional da linha positiva;
6. segurança negativa essencial;
7. isolamento cross-tenant essencial;
8. cardinalidade final sem mutação indevida;
9. readiness para PR/merge;
10. rollback obrigatório.

---

## Resultado objetivo

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_contrato_rpc_catalogo` | PASS | RPC `pme_registrar_message_usage(uuid,jsonb)` existe, com `SECURITY DEFINER`, `search_path=public, pg_temp`, sem grant para `anon`, com grants para `authenticated` e `service_role`, e comentário presente. |
| `01_rls_schema_hardening_pme` | PASS | RLS ativo em `pme_message_templates` e `pme_message_usage`; colunas obrigatórias presentes; ausência de policies `UPDATE/DELETE` em `pme_message_usage`. |
| `02_setup_fixture_regressao` | PASS | Fixture transacional criada com empresa A, empresa B, usuário/corretor owner, usuário/corretor cross-tenant, lead e templates. |
| `03_execucao_positiva_append_only` | PASS | RPC executou fluxo positivo com `append_only=true`, `dml=true`, canal `whatsapp`, lead type `lista_fria` e phase `primeira_mensagem`. |
| `04_linha_usage_positiva_persistida_na_transacao` | PASS | Linha `pme_message_usage` criada corretamente dentro da transação, com metadata de fixture e `created_at` presente. |
| `05_seguranca_negativa_essencial` | PASS | 4 cenários negativos bloqueados: sem auth, autoridade frontend sobre empresa, payload não objeto e status inválido. |
| `06_escopo_cross_tenant_essencial` | PASS | Cross-tenant bloqueado para usuário de outra empresa e template de outra empresa. |
| `07_cardinalidade_final_sem_mutacao_indevida` | PASS | `usage_count_before=0`, `usage_count_after=1`; somente o fluxo positivo gerou usage. |
| `08_readiness_pr_merge` | PASS | `fail_count=0` e `readiness_pr_merge=true`. |
| `99_rollback_notice` | INFO | Teste encerra com rollback; fixture e uso PME não devem permanecer no banco. |

---

## Detalhes críticos validados

### Contrato da RPC

```json
{
  "proname": "pme_registrar_message_usage",
  "args": "uuid, jsonb",
  "volatility": "v",
  "search_path": ["search_path=public, pg_temp"],
  "anon_execute": false,
  "security_definer": true,
  "comentario_presente": true,
  "authenticated_execute": true,
  "service_role_execute": true
}
```

Leitura técnica: o contrato da RPC está presente e endurecido contra execução anônima.

---

### RLS/schema/hardening

```json
{
  "tabelas": [
    { "relname": "pme_message_templates", "rls_ativo": true },
    { "relname": "pme_message_usage", "rls_ativo": true }
  ],
  "politicas_update_delete_usage": 0
}
```

Leitura técnica: as duas tabelas PME têm RLS ativo e a tabela de usage permanece sem policies mutacionais de `UPDATE/DELETE`, preservando o desenho append-only.

---

### Fixture usada

```json
{
  "lead_a": "b51862d6-19fe-4a4e-8e90-eba8774734cf",
  "empresa_a": "[REDACTED_EMPRESA_ID]",
  "empresa_b": "1ed25526-7924-40e2-8a20-44dc4b9a25c0",
  "owner_user": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
  "owner_corretor": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "cross_user": "a263f320-b61a-4866-80bc-d4882b3723c9",
  "cross_corretor": "84dfdc4c-9d5e-4658-9e8e-447b21b86762",
  "template_a": "166c69ac-0995-487f-b600-0ee7085c97e7",
  "template_b": "5c255ddd-4a46-47ec-a502-c2c29d47a6fc",
  "usage_count_before": 0
}
```

---

### Execução positiva append-only

```json
{
  "ok": true,
  "dml": true,
  "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
  "visao": "operacional",
  "status": "copied",
  "channel": "whatsapp",
  "lead_type": "lista_fria",
  "phase": "primeira_mensagem",
  "append_only": true,
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "lead_id": "b51862d6-19fe-4a4e-8e90-eba8774734cf",
  "usage_id": "444a1d53-05b3-4e5b-bd69-8a79f66391f5"
}
```

---

### Linha transacional persistida

```json
{
  "usage_id": "444a1d53-05b3-4e5b-bd69-8a79f66391f5",
  "lead_id": "b51862d6-19fe-4a4e-8e90-eba8774734cf",
  "template_id": "166c69ac-0995-487f-b600-0ee7085c97e7",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "channel": "whatsapp",
  "lead_type": "lista_fria",
  "phase": "primeira_mensagem",
  "status": "copied",
  "selection_mode": "suggested",
  "feedback_key": "teste_16e_positive",
  "metadata": {
    "origem": "teste_16e_regressao_final",
    "fixture_transacional": true
  },
  "created_at_presente": true
}
```

---

### Segurança negativa essencial

```json
{
  "pass_count": 4,
  "fail_count": 0,
  "detalhes": [
    {
      "cenario": "sem_auth",
      "status": "PASS",
      "message": "auth_required",
      "sqlstate": "28000"
    },
    {
      "cenario": "empresa_id_frontend",
      "status": "PASS",
      "message": "frontend_authority_forbidden",
      "sqlstate": "42501"
    },
    {
      "cenario": "payload_nao_objeto",
      "status": "PASS",
      "message": "p_payload_must_be_object",
      "sqlstate": "22023"
    },
    {
      "cenario": "status_invalido",
      "status": "PASS",
      "message": "invalid_status",
      "sqlstate": "22023"
    }
  ]
}
```

Leitura técnica: a RPC bloqueou ausência de autenticação, tentativa de autoridade soberana pelo frontend, payload estruturalmente inválido e domínio inválido de status.

---

### Escopo cross-tenant essencial

```json
{
  "pass_count": 2,
  "fail_count": 0,
  "detalhes": [
    {
      "cenario": "cross_user_lead_a",
      "status": "PASS",
      "message": "pme_scope_denied",
      "sqlstate": "42501"
    },
    {
      "cenario": "template_b_lead_a",
      "status": "PASS",
      "message": "template_scope_denied_or_not_found",
      "sqlstate": "42501"
    }
  ]
}
```

Leitura técnica: usuário cross-tenant e template cross-tenant foram bloqueados corretamente.

---

### Cardinalidade final

```json
{
  "lead_a": "b51862d6-19fe-4a4e-8e90-eba8774734cf",
  "usage_count_before": 0,
  "usage_count_after": 1,
  "usage_id_positive": "444a1d53-05b3-4e5b-bd69-8a79f66391f5",
  "positivos_esperados": 1,
  "negativos_essenciais_bloqueados_esperados": 6
}
```

Interpretação:

- apenas 1 linha positiva foi criada;
- 6 cenários negativos essenciais foram bloqueados;
- não houve mutação indevida por tentativa negativa;
- a criação positiva ocorreu somente dentro da transação.

---

## Readiness para PR/merge

```json
{
  "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
  "falhas": [],
  "fail_count": 0,
  "readiness_pr_merge": true,
  "cobertura_consolidada": [
    "contrato_rpc_catalogo",
    "rls_schema_hardening",
    "execucao_positiva_append_only",
    "persistencia_transacional",
    "seguranca_negativa_essencial",
    "escopo_cross_tenant_essencial",
    "cardinalidade_sem_mutacao_indevida",
    "rollback"
  ]
}
```

---

## Conclusão

O **16E está aprovado**.

A v0.2.8 do PME Usage Tracking demonstrou:

- contrato da RPC válido;
- RPC protegida contra execução anônima;
- RLS ativo nas tabelas PME;
- schema mínimo presente;
- modelo append-only preservado;
- execução positiva funcional;
- segurança negativa essencial funcionando;
- bloqueio cross-tenant funcionando;
- ausência de mutação indevida nas tentativas negativas;
- `readiness_pr_merge=true`;
- rollback validado.

---

## Status após 16E

| Teste | Status |
|---|---:|
| 16A | PASS |
| 16B | PASS |
| 16C | PASS |
| 16D | PASS |
| 16E | PASS |
| 16F | Pendente após PR/merge/deploy |

---

## Próximo passo recomendado

Preparar o fechamento técnico da v0.2.8 e abrir PR para merge na `main`.

Após merge/deploy, executar o **16F — smoke pós-produção read-only/operacional**, conforme protocolo da fase.
