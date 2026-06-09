# FECH.AI / Supabase - P1 Live Reconciliation Results

Date: 2026-06-09
Status: SANITIZED LIVE RECONCILIATION RESULTS / NO PRODUCTION CHANGE
Encoding note: UTF-8 plain text, LF line endings, ASCII-safe wording, no intentional hidden or bidirectional Unicode characters.
Related checkpoints:
- PR #67 - authenticated write-surface P1 inventory
- PR #68 - frontend direct-DML P1 inventory
- PR #69 - RPC/grants P1 inventory
- PR #70 - RPC/function body review P1
- PR #71 - Supabase live reconciliation runbook P1
Current PR: PR #72 - sanitized Supabase live reconciliation results P1
Recommended next phase: first technical hardening candidate only after validation and explicit approval

---

## 1. Summary

This document records sanitized results from the read-only Supabase live reconciliation runbook created in PR #71.

This PR does not change runtime behavior.

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

This document records metadata and boolean indicators only. It does not commit raw function bodies, raw customer data, raw broker data, raw production payloads, tokens, secrets, private URLs, emails, phone numbers or production UUIDs.

Security principle:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists analysis, classification and productivity, but is not authority for tenant, permission, ownership, role, eligibility, distribution, billing or commercial state.
```

---

## 2. Execution context

Execution mode: read-only SQL against live Supabase PostgreSQL catalogs.

Project label used for internal context: Discador-MesaCliente.

Sanitization applied:

- project identifiers omitted from evidence body;
- owner names normalized to role category when needed;
- privileged backend role names normalized to `privileged_backend_role` in summary tables;
- no raw `pg_get_functiondef` output committed;
- no user/customer/broker payload committed;
- no production UUID committed;
- no e-mail/phone/token/password committed.

Queries executed:

- Query A - function metadata and EXECUTE exposure;
- Query B - target functions missing from live catalog;
- Query C - sanitized body indicators;
- Query D - RLS/FORCE RLS metadata for touched surfaces;
- Query E - policy count by touched table.

---

## 3. High-level findings

### 3.1 Function catalog coverage

All target PostgreSQL RPC/function names from the PR #71 target list were found in live `public.pg_proc`.

One overloaded function was found:

```text
avaliar_lista
```

Therefore, the target list produced 28 live function rows because `avaliar_lista` has two signatures.

Missing function result from Query B:

```text
none
```

### 3.2 Universal function metadata pattern

For all 28 live function rows reviewed:

```text
schema: public
owner category: postgres_owner
security mode: SECURITY DEFINER
volatility: volatile
function_config: search_path=public
```

This does not prove unsafe behavior by itself, but it is material for hardening because P1 RPCs with writes and `SECURITY DEFINER` require strict validation of actor, tenant/company, ownership, payload allowlist and search_path safety.

### 3.3 EXECUTE exposure summary

The following functions have `anon_execute = true`:

```text
alterar_plano_empresa_root
atualizar_status_empresa_root
criar_empresa_root
salvar_mesa_cliente_enriquecimento
simular_troca_plano_empresa_root
```

The following function has `PUBLIC` EXECUTE exposure through ACL classification:

```text
criar_empresa_root
```

The following live rows have `authenticated_execute = false`:

```text
atualizar_status_corretor(p_corretor_id uuid, p_ativo boolean, p_apto_para_receber boolean)
avaliar_lista(p_lista_id uuid, p_nota integer, p_comentario text)
criar_time(p_nome text, p_gestor_id uuid)
gerenciar_lista(p_lista_id uuid, p_acao text, p_motivo text)
```

All other reviewed live rows have `authenticated_execute = true`.

### 3.4 Table RLS/FORCE RLS summary

Live table metadata for current known P1 surfaces:

| table | rls_enabled | force_rls_enabled | status |
|---|---:|---:|---|
| `corretores` | true | true | OK_FOR_REVIEW |
| `leads` | true | true | OK_FOR_REVIEW |
| `lista_visibilidade` | true | true | OK_FOR_REVIEW |
| `listas` | true | true | OK_FOR_REVIEW |
| `lotes` | true | true | OK_FOR_REVIEW |
| `mesa_cliente_unidade_enriquecimentos` | true | false | FORCE_RLS_REVIEW_REQUIRED |
| `times` | true | true | OK_FOR_REVIEW |

### 3.5 Policy count summary

Live policy counts for current known P1 surfaces:

| table | policy_count | policy_names_sanitized | status |
|---|---:|---|---|
| `corretores` | 3 | `corretores_insert`, `corretores_select`, `corretores_update` | OK_FOR_REVIEW |
| `leads` | 3 | `leads_insert`, `leads_select`, `leads_update` | OK_FOR_REVIEW |
| `lista_visibilidade` | 3 | `lv_delete`, `lv_insert`, `lv_select` | REVIEW_NO_UPDATE_POLICY |
| `listas` | 2 | `listas_insert`, `listas_select` | REVIEW_NO_UPDATE_DELETE_POLICY |
| `lotes` | 2 | `lotes_select`, `lotes_update` | REVIEW_NO_INSERT_DELETE_POLICY |
| `times` | 3 | `times_insert`, `times_select`, `times_update` | OK_FOR_REVIEW |
| `mesa_cliente_unidade_enriquecimentos` | 0 | none returned by policy-count query | POLICY_REVIEW_REQUIRED |

---

## 4. Function EXECUTE exposure matrix

Legend:

- `owner_category`: sanitized owner classification.
- `backend_role`: privileged backend role grantee normalized from live ACL summary.
- `PUBLIC_ACL`: ACL grantee zero classification.
- This matrix is evidence for review, not a hardening instruction.

| function | signature class | anon_execute | authenticated_execute | public_execute_acl | security_mode | function_config | status |
|---|---|---:|---:|---:|---|---|---|
| `alterar_plano_empresa_root` | root billing mutation | true | true | false | SECURITY DEFINER | search_path=public | P1_ANON_EXECUTE_REVIEW_REQUIRED |
| `alterar_role_corretor` | broker role mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `atualizar_feedback` | lead feedback mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `atualizar_perfil_corretor` | broker profile mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `atualizar_status_corretor` | broker status mutation | false | false | false | SECURITY DEFINER | search_path=public | P1_NO_CLIENT_EXECUTE_CURRENTLY |
| `atualizar_status_empresa_root` | root tenant status mutation | true | true | false | SECURITY DEFINER | search_path=public | P1_ANON_EXECUTE_REVIEW_REQUIRED |
| `atualizar_time_corretor` | broker team assignment | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `avaliar_lista` | list rating, 3-arg overload | false | false | false | SECURITY DEFINER | search_path=public | P1_NO_CLIENT_EXECUTE_CURRENTLY |
| `avaliar_lista` | list rating, 4-arg overload | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `criar_empresa_root` | root tenant creation | true | true | true | SECURITY DEFINER | search_path=public | P0_CANDIDATE_PUBLIC_AND_ANON_EXECUTE |
| `criar_lista` | list creation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `criar_time` | team creation | false | false | false | SECURITY DEFINER | search_path=public | P1_NO_CLIENT_EXECUTE_CURRENTLY |
| `distribuir_lotes` | lot distribution | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `excluir_lista` | list lifecycle | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `gerenciar_lista` | list lifecycle | false | false | false | SECURITY DEFINER | search_path=public | P1_NO_CLIENT_EXECUTE_CURRENTLY |
| `gerenciar_visibilidade_lista` | list visibility ACL-like mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `get_corretores_time` | team/broker read scope | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `get_meus_times` | own teams read scope | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `importar_leads_batch` | bulk lead import | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `mover_funil` | funnel mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `mover_funil_lote` | batch funnel mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `proximo_lead` | lead distribution/progression | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `registrar_feedback` | lead feedback mutation | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `registrar_mensagem` | communication trail | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |
| `salvar_mesa_cliente_enriquecimento` | MesaCliente-sensitive write | true | true | false | SECURITY DEFINER | search_path=public | P1_ANON_EXECUTE_REVIEW_REQUIRED |
| `simular_troca_plano_empresa_root` | root billing simulation | true | true | false | SECURITY DEFINER | search_path=public | P1_ANON_EXECUTE_REVIEW_REQUIRED |
| `solicitar_lote` | lot assignment | false | true | false | SECURITY DEFINER | search_path=public | P1_AUTHENTICATED_REVIEW_REQUIRED |

---

## 5. Sanitized body indicator matrix

These indicators are boolean text scans. They are not proof of safety.

Important interpretation rules:

- `has_auth_uid = true` indicates body text mentions `auth.uid`, not that validation is correct.
- `has_auth_uid = false` is a review signal, not a final vulnerability proof.
- `has_insert`, `has_update`, `has_delete` are write indicators, not exhaustive write analysis.
- `body_mentions_search_path = true` must be cross-checked against `function_config` from Query A.

| function | signature class | has_auth_uid | has_is_root | has_is_gestor | mentions_empresa_id | has_insert | has_update | has_delete | dynamic_sql | body_signal_status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `alterar_plano_empresa_root` | root billing mutation | false | true | false | true | false | true | false | false | REVIEW_AUTH_UID_ABSENT |
| `alterar_role_corretor` | broker role mutation | true | true | true | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `atualizar_feedback` | lead feedback mutation | true | false | false | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `atualizar_perfil_corretor` | broker profile mutation | true | false | true | true | false | true | false | false | WRITE_REVIEW_REQUIRED |
| `atualizar_status_corretor` | broker status mutation | true | true | true | true | false | true | false | false | WRITE_REVIEW_REQUIRED |
| `atualizar_status_empresa_root` | root tenant status mutation | false | true | false | true | false | true | false | false | REVIEW_AUTH_UID_ABSENT |
| `atualizar_time_corretor` | broker team assignment | true | true | true | true | false | true | false | false | WRITE_REVIEW_REQUIRED |
| `avaliar_lista` | list rating, 3-arg overload | true | false | false | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `avaliar_lista` | list rating, 4-arg overload | false | false | false | false | false | false | false | false | REVIEW_BODY_GUARD_ABSENT_OR_WRAPPER |
| `criar_empresa_root` | root tenant creation | true | true | false | true | true | false | false | false | P0_CANDIDATE_REVIEW_REQUIRED |
| `criar_lista` | list creation | true | true | true | true | true | false | false | false | WRITE_REVIEW_REQUIRED |
| `criar_time` | team creation | true | true | true | true | true | false | false | false | WRITE_REVIEW_REQUIRED |
| `distribuir_lotes` | lot distribution | true | true | false | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `excluir_lista` | list lifecycle | true | true | true | true | true | true | true | false | DELETE_REVIEW_REQUIRED |
| `gerenciar_lista` | list lifecycle | false | false | true | false | true | true | false | false | REVIEW_AUTH_UID_ABSENT |
| `gerenciar_visibilidade_lista` | list visibility ACL-like mutation | true | true | true | true | true | true | true | false | DELETE_REVIEW_REQUIRED |
| `get_corretores_time` | team/broker read scope | true | true | true | true | false | false | false | false | READ_SCOPE_REVIEW_REQUIRED |
| `get_meus_times` | own teams read scope | true | true | false | true | false | false | false | false | READ_SCOPE_REVIEW_REQUIRED |
| `importar_leads_batch` | bulk lead import | true | false | false | true | true | true | false | false | BULK_WRITE_REVIEW_REQUIRED |
| `mover_funil` | funnel mutation | true | true | true | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `mover_funil_lote` | batch funnel mutation | true | false | false | true | true | true | false | false | BATCH_WRITE_REVIEW_REQUIRED |
| `proximo_lead` | lead distribution/progression | true | false | false | true | false | true | false | false | WRITE_REVIEW_REQUIRED |
| `registrar_feedback` | lead feedback mutation | true | false | false | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `registrar_mensagem` | communication trail | true | false | false | true | true | true | false | false | WRITE_REVIEW_REQUIRED |
| `salvar_mesa_cliente_enriquecimento` | MesaCliente-sensitive write | true | true | false | true | true | true | false | false | MESA_CLIENTE_WRITE_REVIEW_REQUIRED |
| `simular_troca_plano_empresa_root` | root billing simulation | false | true | false | true | false | false | false | false | REVIEW_AUTH_UID_ABSENT_SIMULATION_PATH |
| `solicitar_lote` | lot assignment | true | false | false | true | true | true | false | false | WRITE_REVIEW_REQUIRED |

No reviewed body indicator row returned `has_dynamic_execute = true`.

---

## 6. Blocking findings for hardening

These findings block direct technical hardening until reviewed and tested. They do not require code change in this evidence PR.

### B1 - Root tenant creation exposed to PUBLIC and anon

```text
criar_empresa_root
```

Observed live metadata:

- `SECURITY DEFINER`;
- `search_path=public`;
- `anon_execute=true`;
- `authenticated_execute=true`;
- `public_execute_acl=true`;
- body indicators include root/tenant and insert indicators.

Classification:

```text
P0_CANDIDATE_PUBLIC_AND_ANON_EXECUTE
```

Required next step:

- body review with sanitized excerpts;
- negative tests: unauthenticated, anon, authenticated non-root, cross-tenant target, invalid plan, duplicate slug;
- then narrow hardening PR if confirmed.

### B2 - Root/billing/status functions with anon EXECUTE

```text
alterar_plano_empresa_root
atualizar_status_empresa_root
simular_troca_plano_empresa_root
```

Observed live metadata:

- `SECURITY DEFINER`;
- `search_path=public`;
- `anon_execute=true`;
- `authenticated_execute=true`;
- body indicators mention root/company/billing or status paths.

Classification:

```text
P1_ANON_EXECUTE_REVIEW_REQUIRED
```

Required next step:

- confirm intended caller;
- confirm body guards;
- negative tests for anon/non-root;
- decide whether hardening can be grouped with `criar_empresa_root` or isolated.

### B3 - MesaCliente-sensitive enrichment RPC with anon EXECUTE

```text
salvar_mesa_cliente_enriquecimento
```

Observed live metadata:

- `SECURITY DEFINER`;
- `search_path=public`;
- `anon_execute=true`;
- `authenticated_execute=true`;
- body indicators include insert/update;
- table `mesa_cliente_unidade_enriquecimentos` has RLS enabled but FORCE RLS disabled;
- policy count query returned no policy row for this table.

Classification:

```text
P1_MESA_CLIENTE_GRANT_AND_POLICY_REVIEW_REQUIRED
```

Required next step:

- do not change MesaCliente yet;
- classify exact customer-safe impact;
- review whether anon execution is intentional;
- review policy/FORCE RLS posture;
- run MesaCliente parser/financial-engine regression before any future change.

### B4 - Functions without client EXECUTE but still SECURITY DEFINER write bodies

```text
atualizar_status_corretor
avaliar_lista(p_lista_id uuid, p_nota integer, p_comentario text)
criar_time
gerenciar_lista
```

Observed live metadata:

- `anon_execute=false`;
- `authenticated_execute=false`;
- no PUBLIC ACL;
- backend privileged role and owner still have EXECUTE;
- body indicators show write behavior for several of these paths.

Classification:

```text
NO_CLIENT_EXECUTE_CURRENTLY_BUT_BODY_REVIEW_REQUIRED
```

Required next step:

- verify whether frontend references these directly or via backend flows;
- avoid adding authenticated grant without tests;
- keep in body review queue.

### B5 - Direct frontend DML remains outside pg_proc

```text
src/App.jsx -> sb.patch("corretores", ...)
```

Observed fields from prior checkpoints:

```text
must_change_password
ativo
apto_para_receber
```

Classification:

```text
DIRECT_DML_REPLACEMENT_CANDIDATE
```

Required next step:

- design narrow replacement RPCs;
- prove own-user vs admin paths;
- do not reduce `authenticated UPDATE` on `public.corretores` until replacement RPCs and negative tests exist.

---

## 7. Edge/API review queue

Out-of-pg_proc paths remain separate:

```text
criar-usuario
reset_password
```

Required review categories:

- source location;
- privileged backend credential usage only server-side;
- secret absence from frontend/logs;
- actor validation;
- target company/tenant validation;
- role/profile validation;
- audit logging;
- negative tests for non-root/non-admin, inactive actor, cross-company target.

Status:

```text
PENDING_EDGE_API_SOURCE_REVIEW
```

---

## 8. Recommended first hardening candidate

Recommended first technical hardening candidate:

```text
criar_empresa_root
```

Reason:

- root/tenant creation surface;
- `SECURITY DEFINER`;
- `search_path=public`;
- `anon_execute=true`;
- `PUBLIC` EXECUTE ACL present;
- insert/body indicators present;
- high blast radius if callable by unintended actors.

Do not harden directly from this document alone. The next PR should either:

1. create a focused test-and-hardening plan for `criar_empresa_root`; or
2. add a narrow technical change with rollback and negative tests, if body review confirms the exact guard model.

Minimum negative tests before/with hardening:

- anon call blocked;
- unauthenticated call blocked;
- authenticated non-root call blocked;
- inactive actor blocked;
- invalid plan blocked;
- duplicate slug handled safely;
- valid root path preserved;
- audit path preserved.

Rollback requirement:

- explicit restoration of prior EXECUTE grants if production breakage is detected;
- validation that no frontend or provisioning flow depends on anon/PUBLIC execution.

---

## 9. Non-claims

This document does not claim the platform is production-secure.

This document does not prove all RPC bodies are safe.

This document does not authorize grant/revoke.

This document does not authorize migration execution.

This document does not authorize frontend changes.

This document does not authorize MesaCliente changes.

This document does not authorize Edge Function changes.

This document is sanitized live evidence for decision-making only.

---

## 10. Final conclusion

The live read-only reconciliation confirms that the FECH.AI P1 RPC surface has several high-priority review items before technical hardening.

Most authenticated operational RPCs are exposed to `authenticated` only, but all reviewed functions are `SECURITY DEFINER` with `search_path=public`, requiring body-level validation before any grant or body change.

The strongest first hardening candidate is `criar_empresa_root`, because it is a root tenant creation RPC with both `anon_execute=true` and `PUBLIC` EXECUTE ACL.

MesaCliente-sensitive enrichment remains a separate high-care path and should not be mixed with root provisioning hardening.

No runtime change is made by this PR.
