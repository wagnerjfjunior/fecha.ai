# FECH.AI — PME Usage Tracking v0.2.8

## Evidência 16F — Smoke pós-produção Usage Tracking DB/RLS/RPC

**Branch:** `main`  
**Teste:** `16F`  
**Arquivo executado:** `supabase/tests/pme/usage-tracking/16f_smoke_pos_producao_usage_tracking_v028.sql`  
**Tipo:** smoke pós-produção read-only  
**DDL:** não  
**DML:** não  
**Fixture:** não  
**Transação:** `read only`  
**Status final:** `PASS COM OBSERVAÇÃO DE INVENTÁRIO DE MIGRATIONS`

---

## Objetivo

Validar pós-merge/deploy da v0.2.8 que a entrega PME Usage Tracking está presente e operacionalmente segura no banco, sem executar mutação em produção.

O smoke 16F valida:

1. inventário das migrations v0.2.8;
2. contrato/catálogo da RPC `public.pme_registrar_message_usage(uuid,jsonb)`;
3. RLS/schema mínimo das tabelas PME;
4. hardening append-only de `pme_message_usage`;
5. inventário operacional read-only;
6. readiness pós-produção;
7. ausência de DDL/DML/fixture.

---

## Resultado objetivo

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_migrations_v028_inventario` | INFO | As versões `20260523173000` e `20260523202000` aparecem como não registradas em `supabase_migrations.schema_migrations`. Não reprova o smoke porque o bloco é informativo, mas fica documentado como observação de rastreabilidade. |
| `01_contrato_rpc_catalogo_pos_producao` | PASS | RPC `pme_registrar_message_usage(uuid,jsonb)` presente, `SECURITY DEFINER`, `search_path=public, pg_temp`, sem `anon`, com `authenticated/service_role` e comentário presente. |
| `02_rls_schema_pme_pos_producao` | PASS | RLS ativo em `pme_message_templates` e `pme_message_usage`; schema mínimo presente. |
| `03_append_only_hardening_usage` | PASS | `pme_message_usage` sem policies `UPDATE/DELETE`; append-only preservado. |
| `04_inventario_operacional_readonly` | INFO | Inventário read-only: `leads_total=5258`, `pme_message_usage_total=0`, `pme_message_templates_total=0`, `pme_message_templates_ativos=0`. |
| `05_execucao_rpc_mutacional` | SKIP | Skip proposital; a RPC é append-only e grava usage, portanto não foi chamada em produção sem fixture controlada. |
| `06_readiness_pos_producao` | PASS | `readiness_pos_producao=true`, com `ddl=false`, `dml=false`, `fixture=false`, transação read-only. |
| `99_interpretacao_operacional` | INFO | Smoke executado sem DDL, sem DML, sem fixture e sem chamada mutacional à RPC. |

---

## Contrato da RPC em produção

```json
{
  "args": "uuid, jsonb",
  "proname": "pme_registrar_message_usage",
  "volatility": "v",
  "search_path": ["search_path=public, pg_temp"],
  "anon_execute": false,
  "security_definer": true,
  "comentario_presente": true,
  "service_role_execute": true,
  "authenticated_execute": true
}
```

Leitura técnica: o contrato esperado da RPC está presente em produção e endurecido contra execução anônima.

---

## RLS/schema em produção

```json
{
  "tabelas": [
    { "relname": "pme_message_templates", "force_rls": false, "rls_ativo": true },
    { "relname": "pme_message_usage", "force_rls": false, "rls_ativo": true }
  ]
}
```

Todas as colunas mínimas exigidas pelo smoke 16F foram identificadas com `existe=true`.

---

## Hardening append-only

```json
{
  "policies_update_delete_usage": 0,
  "policies_inventario": [
    {
      "cmd": "INSERT",
      "roles": ["public"],
      "tablename": "pme_message_usage",
      "policyname": "pme_message_usage_insert"
    },
    {
      "cmd": "SELECT",
      "roles": ["public"],
      "tablename": "pme_message_usage",
      "policyname": "pme_message_usage_select"
    }
  ]
}
```

Leitura técnica: `pme_message_usage` permanece append-only do ponto de vista das policies RLS, sem abertura de `UPDATE` ou `DELETE`.

---

## Inventário operacional read-only

```json
{
  "leads_total": 5258,
  "pme_message_usage_total": 0,
  "pme_message_templates_total": 0,
  "pme_message_templates_ativos": 0,
  "observacao": "inventario_readonly_sem_fixture_sem_execucao_mutacional_da_rpc"
}
```

Leitura técnica: não há templates nem usages PME reais cadastrados no momento do smoke. Isso não reprova a fase, porque os testes positivos de execução foram cobertos por fixture transacional em `16B` e `16E`, e o smoke pós-produção foi desenhado para não gerar DML em produção.

---

## Observação sobre inventário de migrations

O bloco `00_migrations_v028_inventario` retornou:

```json
[
  { "version": "20260523173000", "aplicada": false },
  { "version": "20260523202000", "aplicada": false }
]
```

Interpretação controlada:

- o catálogo real do banco contém a RPC, tabelas, RLS, grants e policies esperadas;
- portanto, a entrega funcional está presente;
- porém, o histórico `supabase_migrations.schema_migrations` não acusa essas duas versões como aplicadas;
- isso indica possível diferença entre o mecanismo usado para aplicar SQL e o mecanismo de registro de migrations do Supabase;
- não bloqueia o 16F, mas deve permanecer documentado como ponto de rastreabilidade para futura auditoria de deployment/migrations.

---

## Readiness pós-produção

```json
{
  "ddl": false,
  "dml": false,
  "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
  "fixture": false,
  "transaction": "read only",
  "readiness_pos_producao": true
}
```

---

## Conclusão

O **16F está aprovado** para o objetivo do smoke pós-produção.

A v0.2.8 está tecnicamente encerrada com:

```text
16A PASS
16B PASS
16C PASS
16D PASS
16E PASS
16F PASS COM OBSERVAÇÃO
```

Observação remanescente: investigar futuramente a divergência de inventário em `supabase_migrations.schema_migrations`, pois os objetos existem no catálogo, mas as versões de migration aparecem como `aplicada=false`.
