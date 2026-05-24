# FECH.AI — Fechamento técnico PME Usage Tracking DB/RLS/RPC v0.2.8

## Identificação

**Fase:** `v0.2.8 — Banco/RPC/RLS do PME Usage Tracking`  
**Branch de implementação:** `feature/pme-usage-tracking-db-v0.2.8`  
**Base:** `main`  
**PR:** `#24 — PME Usage Tracking DB/RLS/RPC v0.2.8`  
**Status técnico:** `ENCERRADA`  
**Smoke pós-produção:** `16F PASS`

---

## Objetivo da fase

Implementar a base de banco, RLS, hardening e RPC operacional para rastreamento de uso de mensagens PME no FECH.AI, com desenho append-only e derivação soberana de escopo pelo backend/banco.

A fase entrega a RPC:

```sql
public.pme_registrar_message_usage(uuid, jsonb)
```

E a estrutura necessária para registrar uso de mensagens PME por lead/corretor/empresa, preservando isolamento multiempresa, segurança de tenant e ausência de autoridade soberana no frontend.

---

## Entregas implementadas

### 1. Estrutura de banco

Foram adicionadas migrations para:

- criação/ajuste da estrutura PME Usage Tracking;
- tabelas de templates e usage;
- RLS nas tabelas PME;
- função/RPC operacional;
- hardening de grants e função trigger auxiliar;
- preservação do modelo append-only para `pme_message_usage`.

Arquivos principais:

```text
supabase/migrations/20260523173000_pme_usage_tracking_db_v028.sql
supabase/migrations/20260523202000_pme_usage_tracking_v028_hardening_trigger_function_grants.sql
```

---

### 2. RPC operacional

RPC entregue:

```sql
public.pme_registrar_message_usage(uuid, jsonb)
```

Garantias validadas:

- `SECURITY DEFINER`;
- `search_path=public, pg_temp`;
- sem execução por `anon`;
- execução por `authenticated` e `service_role`;
- comentário presente no catálogo;
- validação de autenticação;
- validação de payload `jsonb` como objeto;
- bloqueio de campos soberanos enviados pelo frontend;
- validação de referência PME (`template_id`, `call_script_id` ou `cadence_step_id`);
- validação de domínio para `channel`, `lead_type` e `status`;
- derivação de `empresa_id` e `corretor_id` pelo banco;
- bloqueio cross-tenant;
- append-only.

---

### 3. Segurança multiempresa

A fase validou que:

- o frontend não tem autoridade para enviar `empresa_id`, `tenant_id`, `corretor_id`, `user_id`, `created_by` ou `updated_by`;
- `empresa_id` e `corretor_id` são derivados do contexto real/autenticado;
- usuário de outra empresa não registra usage em lead de empresa alheia;
- template de outra empresa não pode ser usado com lead da empresa atual;
- RLS está ativo em `pme_message_templates` e `pme_message_usage`;
- `pme_message_usage` não possui policies mutacionais de `UPDATE/DELETE`, preservando a semântica append-only.

---

## Testes executados

| Teste | Arquivo | Status | Leitura técnica |
|---|---|---:|---|
| 16A | `16a_smoke_pme_usage_tracking_catalogo_rls_grants_readonly.sql` | PASS | Smoke read-only de catálogo, RLS e grants. |
| 16B | `16b_rpc_registrar_message_usage_positive_rollback.sql` | PASS | Execução positiva da RPC com fixture transacional e append-only. |
| 16C | `16c_rpc_registrar_message_usage_security_negative_rollback.sql` | PASS | Segurança negativa: auth, soberania frontend, payload e domínios inválidos. |
| 16D | `16d_rpc_registrar_message_usage_scope_rls_cross_tenant_rollback.sql` | PASS | Escopo/RLS/cross-tenant: usuário/template fora da empresa bloqueados. |
| 16E | `16e_regressao_final_usage_tracking_v028_rollback.sql` | PASS | Regressão final consolidada com readiness para PR/merge. |
| 16F | `16f_smoke_pos_producao_usage_tracking_v028.sql` | PASS | Smoke pós-produção read-only validado após repair do inventário de migrations. |

---

## Evidências registradas

```text
docs/pme/usage-tracking/v0.2.8/16a-smoke-catalogo-rls-grants-readonly-evidencia.md
docs/pme/usage-tracking/v0.2.8/16b-rpc-registrar-message-usage-positive-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16c-rpc-registrar-message-usage-security-negative-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16d-rpc-registrar-message-usage-scope-rls-cross-tenant-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16e-regressao-final-usage-tracking-v028-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16f-smoke-pos-producao-usage-tracking-v028-evidencia.md
```

---

## Resultado consolidado da regressão final 16E

O teste final `16E` validou:

```text
fail_count = 0
readiness_pr_merge = true
```

Cobertura consolidada:

```text
contrato_rpc_catalogo
rls_schema_hardening
execucao_positiva_append_only
persistencia_transacional
seguranca_negativa_essencial
escopo_cross_tenant_essencial
cardinalidade_sem_mutacao_indevida
rollback
```

---

## Resultado pós-produção 16F

O smoke pós-produção `16F` validou:

```text
16F PASS
readiness_pos_producao = true
DDL = false
DML = false
fixture = false
transaction = read only
```

Também confirmou o inventário das migrations v0.2.8:

```text
20260523173000 aplicada = true
20260523202000 aplicada = true
```

Leitura: a divergência anterior de rastreabilidade no `supabase_migrations.schema_migrations` foi sanada. Os objetos já estavam presentes no catálogo e o histórico de migrations agora reflete as duas versões como aplicadas.

---

## Arquivos adicionados na fase

```text
docs/pme/usage-tracking/v0.2.8/16a-smoke-catalogo-rls-grants-readonly-evidencia.md
docs/pme/usage-tracking/v0.2.8/16b-rpc-registrar-message-usage-positive-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16c-rpc-registrar-message-usage-security-negative-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16d-rpc-registrar-message-usage-scope-rls-cross-tenant-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16e-regressao-final-usage-tracking-v028-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16f-smoke-pos-producao-usage-tracking-v028-evidencia.md
docs/pme/usage-tracking/v0.2.8/FECHAMENTO_TECNICO.md
docs/releases/pme-usage-tracking-db-v0.2.8/SHARED_SCRIPT_LIBRARY_STRATEGY.md
docs/releases/pme-usage-tracking-db-v0.2.8/TENANCY_RBAC_TREE.md
supabase/migrations/20260523173000_pme_usage_tracking_db_v028.sql
supabase/migrations/20260523202000_pme_usage_tracking_v028_hardening_trigger_function_grants.sql
supabase/tests/pme/usage-tracking/16a_smoke_pme_usage_tracking_catalogo_rls_grants_readonly.sql
supabase/tests/pme/usage-tracking/16b_rpc_registrar_message_usage_positive_rollback.sql
supabase/tests/pme/usage-tracking/16c_rpc_registrar_message_usage_security_negative_rollback.sql
supabase/tests/pme/usage-tracking/16d_rpc_registrar_message_usage_scope_rls_cross_tenant_rollback.sql
supabase/tests/pme/usage-tracking/16e_regressao_final_usage_tracking_v028_rollback.sql
supabase/tests/pme/usage-tracking/16f_smoke_pos_producao_usage_tracking_v028.sql
```

---

## Decisão técnica

A fase `v0.2.8 — Banco/RPC/RLS do PME Usage Tracking` está tecnicamente encerrada.

Condição final de aprovação:

```text
16A PASS
16B PASS
16C PASS
16D PASS
16E PASS
16F PASS
readiness_pr_merge true
readiness_pos_producao true
```

---

## Conclusão

A v0.2.8 está encerrada na `main`.

O núcleo entregue é seguro para o próximo estágio do FECH.AI, com rastreabilidade operacional de uso de mensagens PME, isolamento multiempresa, RLS ativo, política append-only documentada e testada, e smoke pós-produção aprovado sem pendências remanescentes.
