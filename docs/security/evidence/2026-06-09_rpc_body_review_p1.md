# FECH.AI / Supabase - P1 RPC Function Body Review

Date: 2026-06-09
Status: READ-ONLY BODY REVIEW / NO PRODUCTION CHANGE
Encoding note: UTF-8 plain text, LF line endings, no intentional hidden or bidirectional Unicode characters.
Related checkpoints:
- PR #67 - authenticated write-surface P1 inventory
- PR #68 - frontend direct-DML P1 inventory
- PR #69 - RPC/grants P1 inventory
Current PR: PR #70 - RPC/function body review P1
Recommended next phase: PR #71 - first technical hardening candidate, only after validation and negative tests

---

## 1. Summary

This document starts the P1 RPC/function body review track after the #67/#68/#69 inventory sequence.

This is a read-only documentation artifact. It does not change runtime behavior.

This PR does not change:

- database grants;
- RLS policies;
- FORCE RLS state;
- RPC/function definitions;
- migrations;
- frontend code;
- MesaCliente parser;
- MesaCliente financial engine;
- Worker;
- Make;
- n8n;
- Vercel;
- production infrastructure;
- business rules.

Important limitation:

This review is repository/documentation based. It does not execute live Supabase catalog reconciliation and does not prove production security. Any live grant, function owner, SECURITY DEFINER/INVOKER, search_path, ACL/default ACL or function body status not proven from the live catalog remains `PENDING_SUPABASE_REAL_RECONCILIATION`.

Security principle:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists analysis, classification and productivity, but is not authority for tenant, permission, ownership, role, eligibility, distribution, billing or commercial state.
```

---

## 2. Review scope

The #70 body review inherits the P1 paths from #69 and classifies each item for body-level review.

| Area | Objects |
|---|---|
| CRM / Discador | `proximo_lead`, `registrar_feedback`, `atualizar_feedback`, `mover_funil`, `mover_funil_lote`, `registrar_mensagem`, `solicitar_lote`, `avaliar_lista` |
| Lists / visibility / import | `criar_lista`, `gerenciar_lista`, `excluir_lista`, `gerenciar_visibilidade_lista`, `importar_leads_batch`, `distribuir_lotes` |
| Teams / brokers | `get_meus_times`, `get_corretores_time`, `atualizar_time_corretor`, `atualizar_status_corretor`, `criar_time`, `atualizar_perfil_corretor`, `alterar_role_corretor` |
| MesaCliente | `salvar_mesa_cliente_enriquecimento`, plus MesaCliente RPCs referenced by wrapper and already tracked in earlier MesaCliente audit PRs |
| Root / tenancy | `criar_empresa_root`, `alterar_plano_empresa_root`, `atualizar_status_empresa_root`, `simular_troca_plano_empresa_root`, `criar-usuario`, `reset_password` |
| Direct DML candidate | `src/App.jsx -> sb.patch("corretores", ...)` for `must_change_password`, `ativo`, `apto_para_receber` |

---

## 3. Body-review checklist

For each RPC/function, PR #70 requires answering:

1. Does it validate `auth.uid()`?
2. Does it validate active user status?
3. Does it derive company/tenant from trusted backend state?
4. Does it avoid trusting frontend-provided `empresa_id`, `tenant_id`, `corretor_id`, `time_id`, role/profile or ownership?
5. Does it validate actor role/profile?
6. Does it validate target object belongs to the same company/tenant?
7. Does it use safe `search_path` when SECURITY DEFINER or privileged context is present?
8. Does it use dynamic SQL? If yes, is it safe?
9. What tables can it write?
10. What fields can it modify?
11. Are payload fields allowlisted?
12. Is audit logging present or required?
13. What positive and negative tests are required?
14. What rollback plan is required before future grant hardening?

---

## 4. Current body review status matrix

Legend:

- `BODY_FOUND_REVIEW_REQUIRED`: function body exists or is referenced enough for body review, but full safe/unsafe verdict still requires exact body plus live metadata.
- `PENDING_BODY_SOURCE`: referenced path exists, but body/source must be fetched from the correct migration, Edge Function or Supabase live catalog.
- `DIRECT_DML_REPLACEMENT_CANDIDATE`: frontend direct table DML that should be replaced only after RPC design and tests.
- `PENDING_SUPABASE_REAL_RECONCILIATION`: live catalog/grants/body metadata not proven in this PR.

| Object/path | Type | Body status | Minimum #70 classification | Notes |
|---|---|---|---|---|
| `proximo_lead` | RPC | `PENDING_BODY_SOURCE` | P1 / CRM distribution | Must prove actor/lead/list/company scope and side effects on lot progression. |
| `registrar_feedback` | RPC | `PENDING_BODY_SOURCE` | P1 / CRM lifecycle | Must validate lead ownership, feedback allowlist and cross-tenant block. |
| `atualizar_feedback` | RPC | `PENDING_BODY_SOURCE` | P1 / CRM lifecycle | Must confirm whether active body exists and whether it overlaps with `registrar_feedback`. |
| `mover_funil` | RPC | `PENDING_BODY_SOURCE` | P1 / funnel mutation | Must validate stage/company scope and allowed transition. |
| `mover_funil_lote` | RPC | `PENDING_BODY_SOURCE` | P1 / batch funnel mutation | Must validate every lead in array; mixed-company arrays must fail. |
| `registrar_mensagem` | RPC | `PENDING_BODY_SOURCE` | P1 / communication trail | Must validate lead access and channel/sequence allowlist. |
| `solicitar_lote` | RPC | `PENDING_BODY_SOURCE` | P1 / lot assignment | Must validate broker eligibility and active/current lot constraints. |
| `avaliar_lista` | RPC | `PENDING_BODY_SOURCE` | P1 / list rating | Must validate actor touched or can rate target list/lot. |
| `criar_lista` | RPC | `PENDING_BODY_SOURCE` | P1 / list creation/import staging | Must derive company server-side and validate source/provider fields. |
| `gerenciar_lista` | RPC | `PENDING_BODY_SOURCE` | P1 / list lifecycle | Must validate list company, actor permission and soft/hard delete behavior. |
| `excluir_lista` | RPC | `PENDING_BODY_SOURCE` | P1 / list lifecycle | Must validate dependencies and prevent cross-company deletion. |
| `gerenciar_visibilidade_lista` | RPC | `PENDING_BODY_SOURCE` | P1 high / ACL-like visibility | Must validate target user/team/company and prevent cross-company grants. |
| `importar_leads_batch` | RPC | `PENDING_BODY_SOURCE` | P1 high / bulk lead import | Must validate list/company binding, payload allowlist and no cross-company insert. |
| `distribuir_lotes` | RPC | `PENDING_BODY_SOURCE` | P1 high / lot distribution | Must validate eligible brokers, lot size and company/team scope. |
| `get_meus_times` | RPC | `PENDING_BODY_SOURCE` | P1 support / sensitive read scope | Read/supporting path; must still avoid cross-tenant team enumeration. |
| `get_corretores_time` | RPC | `PENDING_BODY_SOURCE` | P1 support / sensitive read scope | Previously touched by grant-hardening track; live grants/body must be reconciled. |
| `atualizar_time_corretor` | RPC | `PENDING_BODY_SOURCE` | P1 / broker-team assignment | Must validate actor and target broker/team company. |
| `atualizar_status_corretor` | RPC | `PENDING_BODY_SOURCE` | P1 / broker eligibility | Must allowlist status fields and validate target broker company. |
| `atualizar_perfil_corretor` | RPC | `PENDING_BODY_SOURCE` | P1 / broker profile | Must prevent privileged field mutation and scope by actor/target. |
| `alterar_role_corretor` | RPC | `PENDING_BODY_SOURCE` | P1 high / role authority | Must prevent privilege escalation and cross-company role mutation. |
| `criar_time` | RPC | `PENDING_BODY_SOURCE` | P1 / team governance | Must derive company server-side and validate gestor target. |
| `salvar_mesa_cliente_enriquecimento` | RPC | `PENDING_BODY_SOURCE` | P1 / MesaCliente-sensitive write | Must validate company/project/unit scope and client-safe boundaries. |
| `criar_empresa_root` | RPC | `PENDING_BODY_SOURCE` | P1 / root tenancy | Must validate root authority server-side and audit. |
| `atualizar_status_empresa_root` | RPC | `PENDING_BODY_SOURCE` | P1 / root tenant status | Must validate root authority and target company. |
| `simular_troca_plano_empresa_root` | RPC | `PENDING_BODY_SOURCE` | P1 / billing simulation | Should be read/simulation only; must prove no mutation or side effects. |
| `alterar_plano_empresa_root` | RPC | `PENDING_BODY_SOURCE` | P1 / billing mutation | Must validate root authority, plan allowlist and audit. |
| `criar-usuario` | Edge/API function | `PENDING_BODY_SOURCE` | P1 / identity authority | Must review server-side source, credential handling and tenant binding. |
| `reset_password` action | Edge/API function action | `PENDING_BODY_SOURCE` | P1 / identity authority | Must validate actor authority and target user/company. |
| `sb.patch("corretores", ...)` | direct DML | `DIRECT_DML_REPLACEMENT_CANDIDATE` | P1 / direct table DML | Not fixed here; future narrow RPC(s) required before grant reduction. |

---

## 5. Required live Supabase reconciliation before hardening

Before PR #71 or any grant/body hardening, run read-only reconciliation against the live Supabase catalog.

Required evidence categories:

- function name and identity arguments;
- owner;
- SECURITY DEFINER / SECURITY INVOKER;
- function_config / search_path;
- expanded ACL/default ACL;
- `anon` EXECUTE;
- `authenticated` EXECUTE;
- `PUBLIC` EXECUTE via ACL/default ACL, not only effective privilege;
- sanitized function source/body excerpts or body classification;
- tables written by body;
- privileged fields written by body;
- dynamic SQL presence;
- auth/tenant/role validation evidence.

Suggested read-only query basis:

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
    p.proconfig as function_config,
    coalesce(p.proacl, acldefault('f', p.proowner)) as effective_acl
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join target_functions tf on tf.proname = p.proname
  where n.nspname = 'public'
), acl_expanded as (
  select
    fb.oid,
    array_agg(distinct coalesce(nullif(a.grantee::regrole::text, '-'), 'PUBLIC')) filter (where a.privilege_type = 'EXECUTE') as execute_grantees
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
  fb.function_config,
  has_function_privilege('anon', fb.oid, 'EXECUTE') as anon_execute,
  has_function_privilege('authenticated', fb.oid, 'EXECUTE') as authenticated_execute,
  ae.execute_grantees
from function_base fb
left join acl_expanded ae on ae.oid = fb.oid
order by fb.function_name, fb.identity_args;
```

Do not commit raw unsanitized live output. Sanitize identifiers, emails, UUIDs, tokens, secrets, production payloads and any customer/broker data.

---

## 6. Direct DML replacement candidates

The confirmed direct DML class from PR #68/#69 is:

```text
src/App.jsx
sb.patch("corretores", ...)
```

Observed fields:

- `must_change_password`;
- `ativo`;
- `apto_para_receber`.

Future hardening must not replace only one flow. It must cover all three direct DML paths:

| Future RPC candidate | Existing direct write | Required validation |
|---|---|---|
| password onboarding completion RPC | `must_change_password: false` | derive current actor from `auth.uid()`; no arbitrary `corretorId`; own user only or authorized admin path |
| broker operational status RPC | `ativo`, `apto_para_receber` | admin/manager authority; target broker company; field allowlist |
| admin reset completion RPC | `must_change_password: false` after reset | admin authority; target user/company; audit trail |

Do not reduce `authenticated UPDATE` on `public.corretores` before replacement RPCs and negative tests are in place.

---

## 7. Negative test requirements by class

### 7.1 CRM / Discador

- unauthenticated call blocked;
- authenticated user without broker profile blocked;
- inactive broker blocked;
- cross-company lead/list/lot blocked;
- mixed-company batch array blocked;
- unauthorized funnel stage blocked;
- payload field outside allowlist blocked.

### 7.2 Lists / visibility / import

- non-manager cannot create/manage/delete restricted list;
- target list from another company blocked;
- visibility grant to user/team from another company blocked;
- oversized or malformed import payload blocked;
- distribution to ineligible broker blocked;
- partial distribution failure handling verified.

### 7.3 Teams / brokers

- non-admin/manager cannot move broker/team;
- target broker from another company blocked;
- target team from another company blocked;
- role escalation blocked;
- direct operational status mutation outside allowlist blocked.

### 7.4 MesaCliente

- unauthorized actor blocked;
- cross-company/project/unit enrichment blocked;
- client-unsafe field mutation blocked;
- parser and financial engine regression verified unchanged.

### 7.5 Root / tenancy / identity

- non-root actor blocked;
- root claim from frontend ignored;
- target company validation enforced;
- reset_password cannot target another tenant without explicit root/admin authority;
- all identity-changing actions audited.

---

## 8. PR #70 non-claims

This document does not claim the platform is production-secure.

This document does not prove that grants are safe.

This document does not prove that all function bodies are safe.

This document does not prove that live Supabase matches repository evidence.

This document does not authorize grant revocation or grant creation.

This document does not authorize migration execution.

This document does not authorize frontend or MesaCliente changes.

This document is a body-review planning/checkpoint document only.

---

## 9. Acceptance criteria for PR #70

This PR is acceptable only if:

- it is documentation-only;
- it changes only Markdown evidence under `docs/security/evidence/`;
- it does not change application code;
- it does not change migrations;
- it does not change Supabase objects;
- it does not change RLS, grants, policies or RPC bodies;
- it does not change frontend behavior;
- it does not change MesaCliente parser or financial engine;
- it contains no raw production data;
- it contains no secrets or credentials;
- it marks live grant/body status as pending where not proven;
- it does not attempt hardening before negative-test design and explicit approval.

---

## 10. Final conclusion

PR #70 should be treated as the controlled body-review checkpoint for the P1 write paths inventoried in PR #69.

The highest priority follow-up remains:

```text
#71 - technical hardening candidate for direct corretores patches and/or highest-risk RPCs
```

No technical hardening should be merged until the live Supabase reconciliation and negative-test matrix are complete.
