# FECH.AI / Supabase - criar_empresa_root Sanitized Body Review

Date: 2026-06-09
Status: SANITIZED BODY REVIEW / NO PRODUCTION CHANGE
Encoding note: UTF-8 plain text, LF line endings, ASCII-safe wording, no intentional hidden or bidirectional Unicode characters.
Related checkpoints:
- PR #72 - Supabase live reconciliation results P1
- PR #73 - criar_empresa_root P0 hardening plan
Current PR: PR #74 - criar_empresa_root sanitized body review
Recommended next phase: narrow technical hardening only after validation and explicit approval

---

## 1. Summary

This document records sanitized body-review evidence for `public.criar_empresa_root`.

This PR is documentation-only. It does not change runtime behavior and does not apply hardening.

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

No raw full function body is committed in this document.

---

## 2. Scope

In scope:

```text
public.criar_empresa_root(p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer)
```

Out of scope:

- MesaCliente;
- `salvar_mesa_cliente_enriquecimento`;
- direct frontend DML in `corretores`;
- broad grant cleanup;
- broad RLS changes;
- broad FORCE RLS changes;
- root/billing functions other than `criar_empresa_root`;
- frontend changes;
- Edge Function changes;
- parser changes;
- financial engine changes;
- Worker/Make/n8n changes;
- Vercel changes.

---

## 3. Sanitized live metadata

Read-only catalog review returned the following sanitized metadata:

| attribute | value |
|---|---|
| function | `criar_empresa_root` |
| schema | `public` |
| identity args | `p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer` |
| owner category | postgres owner |
| security mode | `SECURITY DEFINER` |
| volatility | volatile |
| function config | `search_path=public` |
| anon execute | true |
| authenticated execute | true |
| PUBLIC execute ACL | true |
| execute grantees | `anon`, `authenticated`, `postgres`, `PUBLIC`, `service_role` |
| body fingerprint | md5 fingerprint recorded, raw body not committed |

Interpretation:

The function remains a P0 hardening candidate because a tenant/root creation RPC still has `anon` and `PUBLIC` EXECUTE exposure. This document does not change that exposure.

---

## 4. Sanitized body indicators

Boolean indicators from sanitized read-only review:

| indicator | result | interpretation |
|---|---:|---|
| mentions `auth.uid()` | true | actor identity is referenced |
| mentions root check | true | body references root authorization |
| mentions active status | true | body references actor/status validation |
| mentions plan | true | plan validation signal exists |
| mentions slug | true | slug handling signal exists |
| mentions company/tenant | true | tenant creation surface confirmed |
| mentions audit | true | audit trail signal exists |
| has insert | true | write surface confirmed |
| has update | false | no update indicator in body scan |
| has delete | false | no delete indicator in body scan |
| has dynamic EXECUTE | false | no dynamic SQL EXECUTE indicator found |
| mentions exception | true | fail-closed/error handling signal exists |
| mentions search_path | true | body/config search_path signal exists |
| touches empresas | true | expected tenant/company insert surface |
| touches planos | true | expected plan validation surface |
| touches corretores | false | no broker table touch indicator found |

Interpretation rules:

- Boolean scan is not proof of full safety.
- `has_auth_uid = true` does not prove actor validation is complete.
- `has_is_root = true` does not prove the root guard is sufficient until tested.
- `has_dynamic_execute = false` is a useful signal, not a formal proof for every runtime path.
- The next technical PR must include negative tests and rollback.

---

## 5. Sanitized control-flow evidence

The body review found sanitized evidence of these control-flow regions:

1. Root gate before tenant creation.
2. Required company name validation.
3. Required slug validation.
4. Slug normalization/sanitization.
5. Duplicate slug check against company records.
6. Active plan lookup/check.
7. Trial-days normalization for negative values.
8. Insert into company/tenant table.
9. Audit logging call/path.
10. JSON-style success response containing sanitized company metadata.

No raw full function body is committed.

---

## 6. Sanitized excerpts allowed for review

The following short excerpts are intentionally limited and sanitized. They are included only to support body-review decisions.

### 6.1 Root gate signal

```text
if not public.is_root() then
  raise exception 'access denied; only root may create companies';
end if;
```

Interpretation:

The function appears to enforce a root-only gate through `public.is_root()` before company creation. The next technical PR must test this behavior for unauthenticated, anon, authenticated non-root, local tenant admin and valid root actor cases.

### 6.2 Required input and slug handling signal

```text
required company name check
required slug check
slug lower/trim normalization
slug character sanitization
slug duplicate check
```

Interpretation:

The body shows input validation and slug handling signals. The next technical PR must still test malformed slug, duplicate slug and missing required fields.

### 6.3 Plan validation signal

```text
active plan lookup by plan id
raise exception when plan is invalid or inactive
```

Interpretation:

The body shows a plan validation signal. The next technical PR must test invalid plan id and inactive plan behavior if applicable.

### 6.4 Company insert signal

```text
insert into company table with name, slug, plan id, active flag, creator and trial date
```

Interpretation:

The function writes to the company/tenant surface. This confirms high blast radius and supports keeping `criar_empresa_root` isolated from MesaCliente and direct DML work.

### 6.5 Audit signal

```text
audit event for tenant_created with actor identity and sanitized creation metadata
```

Interpretation:

The body shows an audit path signal. The next technical PR must prove audit record/path is preserved.

---

## 7. Authorization conclusion

The current body review supports the following provisional conclusion:

```text
The function appears designed as root-only through public.is_root().
The term admin must not be interpreted as local tenant admin or company admin.
A local tenant admin must remain blocked.
Only a root actor validated server-side as is_root = true may create companies.
```

Required before any technical hardening merge:

- prove unauthenticated calls are blocked;
- prove anon calls are blocked;
- prove authenticated non-root calls are blocked;
- prove authenticated local tenant admin calls are blocked;
- prove inactive root actor calls are blocked if inactive-root state exists;
- prove valid root actor calls still work;
- prove audit path is preserved.

---

## 8. Technical hardening readiness

Based on the sanitized evidence, the likely next technical PR can be narrow and focused on `criar_empresa_root` only.

Candidate technical scope for next PR:

- remove `PUBLIC` EXECUTE for `criar_empresa_root` if tests prove valid root flow remains intact;
- remove `anon` EXECUTE for `criar_empresa_root` if tests prove no legitimate unauthenticated path is required;
- preserve `authenticated` EXECUTE only if the body continues to validate `is_root = true` internally;
- consider safer explicit `search_path` handling for SECURITY DEFINER if needed;
- include rollback restoring previous EXECUTE exposure exactly as recorded.

This PR does not apply any of those actions.

---

## 9. Required negative test matrix for next PR

| test | expected result | required |
|---|---|---:|
| unauthenticated call | blocked | yes |
| anon call | blocked | yes |
| authenticated non-root call | blocked | yes |
| authenticated local tenant admin call | blocked | yes |
| inactive root actor call | blocked if applicable | yes |
| invalid plan id | blocked | yes |
| inactive plan id | blocked if applicable | yes |
| duplicate slug | safe failure | yes |
| malformed slug | blocked or normalized safely | yes |
| missing company name | blocked | yes |
| missing slug | blocked | yes |
| valid root actor request | succeeds | yes |
| audit record/path | preserved | yes |
| no unintended MesaCliente impact | unchanged | yes |
| no direct DML corretores impact | unchanged | yes |

---

## 10. Rollback requirements for next PR

The next technical PR must document rollback for any migration.

Rollback must include:

- previous `PUBLIC` EXECUTE state;
- previous `anon` EXECUTE state;
- previous `authenticated` EXECUTE state;
- validation query after rollback;
- valid root actor smoke test after rollback;
- audit-path check after rollback.

If the next PR changes the function body, rollback must also include:

- previous function definition reference or checksum;
- sanitized body version reference;
- proof that valid root creation still works after rollback.

---

## 11. Non-goals for next PR

The next technical PR must not include:

- MesaCliente changes;
- `salvar_mesa_cliente_enriquecimento` changes;
- direct DML replacement for `corretores`;
- broad grants cleanup;
- broad RLS changes;
- broad FORCE RLS changes;
- unrelated root/billing functions;
- frontend changes unless a verified caller contract requires it;
- Edge Function changes;
- parser or financial engine changes.

---

## 12. Final conclusion

`criar_empresa_root` appears to contain root-only body guard signals through `public.is_root()`, input validation signals, slug handling, plan validation, tenant insert and audit path signals.

However, the RPC still has `anon` EXECUTE and `PUBLIC` EXECUTE exposure according to live metadata.

Therefore, the next step should be a narrow technical hardening PR for `criar_empresa_root` only, with negative tests and rollback. This document is not that hardening PR.
