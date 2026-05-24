# FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8

## Evidência — Smoke 16A catálogo/RLS/grants/read-only

**Branch:** `feature/pme-usage-tracking-db-v0.2.8`  
**Escopo:** PME Usage Tracking — banco/RLS/RPC  
**Teste:** `supabase/tests/pme/usage-tracking/16a_smoke_pme_usage_tracking_catalogo_rls_grants_readonly.sql`  
**Tipo:** smoke read-only de catálogo, RLS, grants, policies, constraints e append-only  
**DDL:** não  
**DML:** não  
**Fixture:** não  
**Rollback:** sim

---

## Resultado final

**Status final do 16A:** `PASS`

O primeiro smoke 16A identificou um hardening necessário em `public.pme_set_updated_at()`: a trigger helper interna ainda possuía `EXECUTE` direto para `authenticated`.

Foi aplicada migration de hardening para revogar execução direta de `public.pme_set_updated_at()` de `public`, `anon`, `authenticated` e `service_role`, mantendo a função apenas como helper interna de trigger.

Após o hardening, o smoke 16A foi reexecutado e retornou `PASS` nos blocos obrigatórios.

---

## Leitura técnica por bloco

| Bloco | Status | Interpretação |
|---|---:|---|
| `00_tabelas_pme_catalogo_rls` | PASS | Todas as tabelas PME esperadas existem, com RLS ativo e comentários presentes. |
| `01_funcoes_pme_catalogo_grants` | PASS | Funções PME existem, usam `SECURITY DEFINER`, `search_path=public, pg_temp`, sem execução para `anon/public` e com grants conforme contrato. |
| `02_policies_pme_catalogo` | PASS | Policies mínimas inventariadas; `pme_message_usage` possui SELECT/INSERT e não possui UPDATE/DELETE. |
| `03_grants_tabelas_sem_anon_public` | PASS | Tabelas PME sem privilégios diretos para `anon`/`PUBLIC`. |
| `04_grants_authenticated_exatos` | PASS | Grants para `authenticated` batem com o contrato: tabelas operacionais com SELECT/INSERT/UPDATE e `pme_message_usage` somente SELECT/INSERT. |
| `05_append_only_pme_message_usage` | PASS | `pme_message_usage` validada como append-only: SELECT/INSERT apenas; sem UPDATE/DELETE. |
| `06_constraints_minimas` | PASS | Constraints mínimas de integridade presentes. |
| `99_interpretacao_operacional` | INFO | Smoke read-only, sem DDL/DML/fixture, com rollback. |

---

## Decisão técnica

O smoke 16A está aprovado para a camada estrutural da v0.2.8.

Isso libera a próxima validação controlada: **16B — teste funcional positivo da RPC `public.pme_registrar_message_usage(uuid,jsonb)` com fixture transacional e rollback**.

---

## Pontos preservados

- Sem `anon_key` no repositório.
- Sem exposição de credenciais.
- Sem DML persistente no smoke 16A.
- Sem mutação de dados reais.
- `pme_message_usage` permanece append-only.
- `empresa_id` e escopo continuam derivados do banco/RLS/RPC, não do frontend.

---

## Próximo passo recomendado

Criar e executar:

`supabase/tests/pme/usage-tracking/16b_rpc_registrar_message_usage_positive_rollback.sql`

Objetivo do 16B:

1. Criar fixture transacional de empresa/corretor/lead/template/script/cadência quando necessário.
2. Simular contexto autenticado elegível.
3. Executar `public.pme_registrar_message_usage(uuid,jsonb)`.
4. Validar retorno `ok=true`, `append_only=true`, `dml=true`.
5. Validar que o registro foi inserido apenas dentro da transação.
6. Validar derivação segura de `empresa_id` a partir do lead.
7. Encerrar com `ROLLBACK`.
