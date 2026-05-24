# FECH.AI — Fechamento técnico PME Usage Tracking DB/RLS/RPC v0.2.8

## Identificação

**Fase:** `v0.2.8 — Banco/RPC/RLS do PME Usage Tracking`  
**Branch:** `feature/pme-usage-tracking-db-v0.2.8`  
**Base:** `main`  
**Base commit no início da comparação:** `4165660579031f9ce2b723d3ecf66840187de4de`  
**Status técnico:** `APROVADO PARA PR/MERGE`  
**Smoke pós-produção:** pendente após merge/deploy (`16F`)

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
| 16F | a criar após merge/deploy | PENDENTE | Smoke pós-produção. |

---

## Evidências registradas

```text
docs/pme/usage-tracking/v0.2.8/16a-smoke-catalogo-rls-grants-readonly-evidencia.md
docs/pme/usage-tracking/v0.2.8/16b-rpc-registrar-message-usage-positive-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16c-rpc-registrar-message-usage-security-negative-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16d-rpc-registrar-message-usage-scope-rls-cross-tenant-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16e-regressao-final-usage-tracking-v028-rollback-evidencia.md
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

## Comparação com a main antes do fechamento

No momento de fechamento antes da criação deste documento:

```text
base: main
head: feature/pme-usage-tracking-db-v0.2.8
status: ahead
ahead_by: 16
behind_by: 0
total_commits: 16
base_commit: 4165660579031f9ce2b723d3ecf66840187de4de
```

Leitura: branch sem atraso em relação à `main` no ponto de comparação, contendo apenas os commits da fase v0.2.8.

Este documento de fechamento adiciona um commit documental adicional antes da abertura da PR.

---

## Arquivos adicionados na fase

```text
docs/pme/usage-tracking/v0.2.8/16a-smoke-catalogo-rls-grants-readonly-evidencia.md
docs/pme/usage-tracking/v0.2.8/16b-rpc-registrar-message-usage-positive-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16c-rpc-registrar-message-usage-security-negative-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16d-rpc-registrar-message-usage-scope-rls-cross-tenant-rollback-evidencia.md
docs/pme/usage-tracking/v0.2.8/16e-regressao-final-usage-tracking-v028-rollback-evidencia.md
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
```

---

## Decisão técnica

A fase `v0.2.8 — Banco/RPC/RLS do PME Usage Tracking` está tecnicamente encerrada para PR.

Condição de aprovação:

```text
16A PASS
16B PASS
16C PASS
16D PASS
16E PASS
readiness_pr_merge true
```

Pendência controlada:

```text
16F — smoke pós-produção após merge/deploy
```

---

## Próximo passo após merge/deploy

Criar e executar o teste:

```text
supabase/tests/pme/usage-tracking/16f_smoke_pos_producao_usage_tracking_v028.sql
```

Escopo esperado do 16F:

- confirmar catálogo da RPC em produção;
- confirmar RLS ativo em tabelas PME;
- confirmar grants pós-deploy;
- preferencialmente executar smoke controlado se houver fixture/lead operacional elegível;
- se não houver dado real elegível, registrar `SKIP` operacional sem reprovar catálogo/deploy;
- não executar DDL persistente;
- evitar mutação fora de cenário explicitamente controlado.

---

## Conclusão

A v0.2.8 está aprovada para abertura de PR contra a `main`.

O núcleo entregue é seguro para o próximo estágio do FECH.AI, com rastreabilidade operacional de uso de mensagens PME, isolamento multiempresa, RLS ativo e política append-only documentada e testada.
