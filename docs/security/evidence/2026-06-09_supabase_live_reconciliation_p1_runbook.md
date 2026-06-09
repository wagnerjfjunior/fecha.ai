# FECH.AI / Supabase - P1 Live Reconciliation Runbook

Date: 2026-06-09
Status: READ-ONLY LIVE RECONCILIATION RUNBOOK / NO PRODUCTION CHANGE
Encoding note: UTF-8 plain text, LF line endings, ASCII-safe wording, no intentional hidden or bidirectional Unicode characters.
Related checkpoints:
- PR #67 - authenticated write-surface P1 inventory
- PR #68 - frontend direct-DML P1 inventory
- PR #69 - RPC/grants P1 inventory
- PR #70 - RPC/function body review P1
Current PR: PR #71 - live Supabase reconciliation runbook before hardening
Recommended next phase: first technical hardening candidate only after sanitized live evidence and negative-test approval

---

## 1. Summary

This document defines the controlled read-only Supabase reconciliation step required before any P1 technical hardening.

This PR does not execute reconciliation. It provides the runbook, SQL templates, sanitization rules and acceptance criteria for producing safe evidence from the live Supabase catalog.

This PR does not change:

- database grants;
- RLS policies;
- FORCE RLS state;
- RPC/function definitions;
- migrations;
- frontend code;
- Edge Functions;
- MesaCliente parser;
- MesaCliente financial engine;
- Worker;
- Make;
- n8n;
- Vercel;
- production infrastructure;
- business rules.

Important limitation:

Until the SQL in this runbook is executed against the live Supabase project and the output is sanitized, all live status remains `PENDING_SUPABASE_REAL_RECONCILIATION`.

Security principle:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists analysis, classification and productivity, but is not authority for tenant, permission, ownership, role, eligibility, distribution, billing or commercial state.
```

---

## 2. Objective

Before the first technical hardening PR, confirm live PostgreSQL/Supabase reality for the P1 RPC/function paths inventoried in #69 and scoped for body review in #70.

The goal is to reconcile:

- which target functions exist in `public`;
- each function signature;
- owner;
- SECURITY DEFINER / SECURITY INVOKER;
- function `search_path` / `proconfig`;
- effective function ACL/default ACL;
- EXECUTE exposure to `anon`, `authenticated` and `PUBLIC`;
- whether the body contains write indicators;
- whether the body contains auth/tenant/role indicators;
- whether there is dynamic SQL;
- which functions require body review before grant hardening;
- which paths are not PostgreSQL RPCs and must be reviewed separately, such as Edge/API and direct DML.

---

## 3. Strict execution rules

Run only read-only SQL.

Do not run:

```sql
ALTER
CREATE
DROP
GRANT
REVOKE
INSERT
UPDATE
DELETE
TRUNCATE
MERGE
CALL
SELECT function_that_mutates_state(...)
```

Allowed query classes:

- `select` from PostgreSQL catalogs;
- `select` from `pg_proc`, `pg_namespace`, `pg_roles`, `pg_policies`, `pg_class`, `pg_attribute`;
- `pg_get_function_identity_arguments`;
- `pg_get_functiondef` for source inspection only;
- `has_function_privilege` for real roles such as `anon` and `authenticated`;
- `aclexplode` and `acldefault` for ACL/default ACL expansion;
- metadata-only RLS and table privilege checks.

Do not commit raw output. Sanitize before committing any evidence.

---

## 4. Target PostgreSQL RPC/function list

These are PostgreSQL RPC candidates for live catalog reconciliation:

```text
proximo_lead
registrar_feedback
atualizar_feedback
mover_funil
mover_funil_lote
registrar_mensagem
solicitar_lote
avaliar_lista
criar_lista
gerenciar_lista
excluir_lista
gerenciar_visibilidade_lista
importar_leads_batch
distribuir_lotes
get_meus_times
get_corretores_time
atualizar_time_corretor
atualizar_status_corretor
atualizar_perfil_corretor
alterar_role_corretor
criar_time
salvar_mesa_cliente_enriquecimento
criar_empresa_root
atualizar_status_empresa_root
simular_troca_plano_empresa_root
alterar_plano_empresa_root
```

Out-of-pg_proc paths requiring separate review:

```text
criar-usuario
reset_password
src/App.jsx -> sb.patch("corretores", ...)
```

---

## 5. Query A - function metadata and EXECUTE exposure

Purpose:

- enumerate target functions that exist in live Supabase;
- capture signature, owner, security mode and function config;
- expand ACL/default ACL;
- check `anon` and `authenticated` EXECUTE;
- identify PUBLIC exposure through ACL grantee zero, not by treating PUBLIC as a normal role.

```sql
with target_functions as (
  select unnest(array[
    'proximo_lead',
    'registrar_feedback',
    'atualizar_feedback',
    'mover_funil',
    'mover_funil_lote',
    'registrar_mensagem',
    'solicitar_lote',
    'avaliar_lista',
    'criar_lista',
    'gerenciar_lista',
    'excluir_lista',
    'gerenciar_visibilidade_lista',
    'importar_leads_batch',
    'distribuir_lotes',
    'get_meus_times',
    'get_corretores_time',
    'atualizar_time_corretor',
    'atualizar_status_corretor',
    'atualizar_perfil_corretor',
    'alterar_role_corretor',
    'criar_time',
    'salvar_mesa_cliente_enriquecimento',
    'criar_empresa_root',
    'atualizar_status_empresa_root',
    'simular_troca_plano_empresa_root',
    'alterar_plano_empresa_root'
  ]) as proname
), function_base as (
  select
    n.nspname as schema_name,
    p.oid,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_args,
    pg_get_userbyid(p.proowner) as owner_name,
    case p.prosecdef when true then 'SECURITY DEFINER' else 'SECURITY INVOKER' end as security_mode,
    p.provolatile as volatility,
    p.proconfig as function_config,
    coalesce(p.proacl, acldefault('f', p.proowner)) as effective_acl
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join target_functions tf on tf.proname = p.proname
  where n.nspname = 'public'
), acl_expanded as (
  select
    fb.oid,
    bool_or(a.privilege_type = 'EXECUTE' and a.grantee = 0) as public_execute_acl,
    array_agg(distinct case when a.grantee = 0 then 'PUBLIC' else a.grantee::regrole::text end)
      filter (where a.privilege_type = 'EXECUTE') as execute_grantees
  from function_base fb
  left join lateral aclexplode(fb.effective_acl) a on true
  group by fb.oid
)
select
  fb.schema_name,
  fb.function_name,
  fb.identity_args,
  fb.owner_name,
  fb.security_mode,
  fb.volatility,
  fb.function_config,
  has_function_privilege('anon', fb.oid, 'EXECUTE') as anon_execute,
  has_function_privilege('authenticated', fb.oid, 'EXECUTE') as authenticated_execute,
  coalesce(ae.public_execute_acl, false) as public_execute_acl,
  coalesce(ae.execute_grantees, array[]::text[]) as execute_grantees
from function_base fb
left join acl_expanded ae on ae.oid = fb.oid
order by fb.function_name, fb.identity_args;
```

Expected sanitized evidence table:

| function_name | identity_args | owner_name | security_mode | function_config | anon_execute | authenticated_execute | public_execute_acl | execute_grantees | status |
|---|---|---|---|---|---:|---:|---:|---|---|
| TBD | TBD | sanitized | TBD | sanitized | TBD | TBD | TBD | sanitized | PENDING_REVIEW |

---

## 6. Query B - target functions missing from live catalog

Purpose:

- identify inventoried functions that are not present in live `public.pg_proc`;
- distinguish real absence from renamed functions, Edge/API paths or stale frontend references.

```sql
with target_functions as (
  select unnest(array[
    'proximo_lead',
    'registrar_feedback',
    'atualizar_feedback',
    'mover_funil',
    'mover_funil_lote',
    'registrar_mensagem',
    'solicitar_lote',
    'avaliar_lista',
    'criar_lista',
    'gerenciar_lista',
    'excluir_lista',
    'gerenciar_visibilidade_lista',
    'importar_leads_batch',
    'distribuir_lotes',
    'get_meus_times',
    'get_corretores_time',
    'atualizar_time_corretor',
    'atualizar_status_corretor',
    'atualizar_perfil_corretor',
    'alterar_role_corretor',
    'criar_time',
    'salvar_mesa_cliente_enriquecimento',
    'criar_empresa_root',
    'atualizar_status_empresa_root',
    'simular_troca_plano_empresa_root',
    'alterar_plano_empresa_root'
  ]) as function_name
), live_functions as (
  select p.proname as function_name
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
)
select tf.function_name
from target_functions tf
left join live_functions lf on lf.function_name = tf.function_name
where lf.function_name is null
order by tf.function_name;
```

Any missing item must be classified as one of:

- `NOT_FOUND_LIVE_REVIEW_REQUIRED`;
- `EDGE_OR_API_PATH_NOT_PG_PROC`;
- `STALE_FRONTEND_REFERENCE_REVIEW_REQUIRED`;
- `RENAMED_FUNCTION_REVIEW_REQUIRED`.

---

## 7. Query C - sanitized body indicators

Purpose:

- classify body risk without committing raw function source;
- identify auth/tenant/role/search_path/write/dynamic SQL indicators.

```sql
with target_functions as (
  select unnest(array[
    'proximo_lead',
    'registrar_feedback',
    'atualizar_feedback',
    'mover_funil',
    'mover_funil_lote',
    'registrar_mensagem',
    'solicitar_lote',
    'avaliar_lista',
    'criar_lista',
    'gerenciar_lista',
    'excluir_lista',
    'gerenciar_visibilidade_lista',
    'importar_leads_batch',
    'distribuir_lotes',
    'get_meus_times',
    'get_corretores_time',
    'atualizar_time_corretor',
    'atualizar_status_corretor',
    'atualizar_perfil_corretor',
    'alterar_role_corretor',
    'criar_time',
    'salvar_mesa_cliente_enriquecimento',
    'criar_empresa_root',
    'atualizar_status_empresa_root',
    'simular_troca_plano_empresa_root',
    'alterar_plano_empresa_root'
  ]) as proname
), body_text as (
  select
    p.oid,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_args,
    lower(pg_get_functiondef(p.oid)) as body_lower
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join target_functions tf on tf.proname = p.proname
  where n.nspname = 'public'
)
select
  function_name,
  identity_args,
  body_lower like '%auth.uid%' as has_auth_uid,
  body_lower like '%is_root%' as has_is_root,
  body_lower like '%is_gestor%' as has_is_gestor,
  body_lower like '%empresa_id%' as mentions_empresa_id,
  body_lower like '%tenant%' as mentions_tenant,
  body_lower like '%corretor_id%' as mentions_corretor_id,
  body_lower like '%time_id%' as mentions_time_id,
  body_lower like '%insert into%' as has_insert,
  body_lower like '% update %' or body_lower like '%update public.%' as has_update,
  body_lower like '% delete %' or body_lower like '%delete from%' as has_delete,
  body_lower like '%execute %' as has_dynamic_execute,
  body_lower like '%set search_path%' as body_mentions_search_path
from body_text
order by function_name, identity_args;
```

Do not commit raw `pg_get_functiondef` output unless explicitly reviewed and sanitized. Prefer committing only boolean indicators and short sanitized excerpts.

---

## 8. Query D - table RLS/FORCE RLS metadata for touched surfaces

Purpose:

- prepare future hardening context for P1 tables;
- include the current known P1 table surfaces and the likely base lists table name if present;
- expand the list after body indicators identify additional touched tables;
- avoid changing RLS in this PR.

```sql
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
  and c.relname in (
    'corretores',
    'leads',
    'lotes',
    'listas',
    'times',
    'lista_visibilidade',
    'mesa_cliente_unidade_enriquecimentos'
  )
order by c.relname;
```

If the live project uses another base table name for lists, record the actual name in the sanitized results and expand this query in the results artifact.

---

## 9. Query E - policy count by touched table

Purpose:

- identify whether P1 touched tables have visible policies;
- include the likely base lists table name if present;
- support future negative-test planning.

```sql
select
  schemaname,
  tablename,
  count(*) as policy_count,
  array_agg(policyname order by policyname) as policy_names
from pg_policies
where schemaname = 'public'
  and tablename in (
    'corretores',
    'leads',
    'lotes',
    'listas',
    'times',
    'lista_visibilidade',
    'mesa_cliente_unidade_enriquecimentos'
  )
group by schemaname, tablename
order by tablename;
```

Policy names may be committed if non-sensitive. Do not commit policy expressions if they include sensitive business data without review.

---

## 10. Out-of-pg_proc review requirements

### 10.1 Edge/API identity paths

Paths:

```text
criar-usuario
reset_password
```

Required evidence before hardening:

- source location;
- whether privileged server-side credentials are used server-side only;
- whether secrets are excluded from frontend and logs;
- actor validation;
- target company/tenant validation;
- role/profile validation;
- audit logging;
- negative tests for non-root/non-admin, cross-company target and inactive actor.

### 10.2 Direct DML paths

Path class:

```text
src/App.jsx -> sb.patch("corretores", ...)
```

Fields:

```text
must_change_password
ativo
apto_para_receber
```

Required evidence before hardening:

- every caller and branch condition;
- actor and target identity model;
- replacement RPC design;
- allowlisted fields;
- positive tests;
- negative tests;
- rollback plan;
- no reduction of `authenticated UPDATE` before replacement RPCs are deployed and verified.

---

## 11. Sanitization rules for committed evidence

Never commit:

- privileged server-side keys;
- JWTs;
- access tokens;
- passwords;
- raw customer data;
- raw broker data;
- phone numbers;
- emails;
- production UUIDs;
- private URLs with tokens;
- raw payloads from imports or CRM events.

Allowed after review:

- function names;
- sanitized signatures;
- boolean privilege flags;
- role names `anon` and `authenticated`;
- pseudo-role `PUBLIC` as ACL classification;
- SECURITY DEFINER/INVOKER state;
- sanitized owner category if needed;
- sanitized search_path/function_config;
- policy counts;
- boolean body indicators;
- short sanitized excerpts with no production identifiers.

Suggested replacement markers:

```text
<redacted-email>
<redacted-uuid>
<redacted-token>
<redacted-phone>
<redacted-customer>
<redacted-broker>
<redacted-payload>
```

---

## 12. Expected output artifact after running live reconciliation

The next evidence document should be created only after live read-only queries are executed and sanitized.

Suggested file:

```text
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
```

Minimum sections:

1. Execution context.
2. Query set used.
3. Sanitization statement.
4. Functions found.
5. Functions missing.
6. EXECUTE exposure matrix.
7. SECURITY DEFINER/INVOKER and search_path matrix.
8. Body indicator matrix.
9. Table RLS/FORCE RLS metadata.
10. Policy count matrix.
11. Edge/API review queue.
12. Direct DML replacement queue.
13. Negative-test queue.
14. Blocking findings for hardening.
15. Recommended first hardening PR.

---

## 13. Acceptance criteria for this PR

This PR is acceptable only if:

- it is documentation-only;
- it changes only Markdown evidence under `docs/security/evidence/`;
- it does not execute live queries;
- it does not commit live output;
- it does not alter application code;
- it does not alter migrations;
- it does not alter Supabase objects;
- it does not alter RLS, grants, policies or RPC bodies;
- it does not alter frontend behavior;
- it does not alter MesaCliente parser or financial engine;
- it contains no raw production data;
- it contains no secrets or credentials;
- it does not authorize hardening before sanitized live evidence and explicit approval.

---

## 14. Final conclusion

PR #71 establishes the read-only live reconciliation runbook required before the first P1 hardening PR.

It does not prove live Supabase safety yet.

It does not authorize technical changes.

It blocks premature hardening until sanitized evidence confirms actual live grants, function metadata, body indicators, RLS metadata and negative-test requirements.
