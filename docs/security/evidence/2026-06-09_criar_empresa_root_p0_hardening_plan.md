# FECH.AI / Supabase - criar_empresa_root P0 Hardening Plan

Date: 2026-06-09
Status: DOCUMENTATION-ONLY HARDENING PLAN / NO PRODUCTION CHANGE
Encoding note: UTF-8 plain text, LF line endings, ASCII-safe wording, no intentional hidden or bidirectional Unicode characters.
Related checkpoints:
- PR #67 - authenticated write-surface P1 inventory
- PR #68 - frontend direct-DML P1 inventory
- PR #69 - RPC/grants P1 inventory
- PR #70 - RPC/function body review P1
- PR #71 - Supabase live reconciliation runbook P1
- PR #72 - Supabase live reconciliation results P1
Current PR: PR #73 - criar_empresa_root P0 hardening plan
Recommended next phase: technical hardening only after validation and explicit approval

---

## 1. Summary

This document prepares a focused hardening plan for the `public.criar_empresa_root` RPC.

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

Security principle:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists analysis, classification and productivity, but is not authority for tenant, permission, ownership, role, eligibility, distribution, billing or commercial state.
```

---

## 2. Scope

In scope:

```text
public.criar_empresa_root
```

Out of scope:

- MesaCliente;
- `salvar_mesa_cliente_enriquecimento`;
- direct frontend DML in `corretores`;
- `src/App.jsx -> sb.patch("corretores", ...)`;
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

Reason for narrow scope:

The live reconciliation in PR #72 identified multiple high-priority findings. This plan intentionally isolates the highest blast-radius candidate to avoid mixing unrelated surfaces.

---

## 3. Evidence inherited from PR #72

Sanitized live metadata for `criar_empresa_root`:

| attribute | value |
|---|---|
| function | `criar_empresa_root` |
| classification | `P0_CANDIDATE_PUBLIC_AND_ANON_EXECUTE` |
| surface | root / tenant creation |
| security mode | `SECURITY DEFINER` |
| function config | `search_path=public` |
| volatility | volatile |
| anon execute | true |
| authenticated execute | true |
| PUBLIC execute ACL | true |
| body indicators | root/tenant + insert indicators |
| raw body committed | no |

Interpretation:

This evidence does not prove active exploitation and does not prove the function body is unsafe. It proves that a root tenant creation RPC has broad execute exposure and requires focused body review, negative tests, rollback design and hardening validation.

---

## 4. Risk hypothesis

`criar_empresa_root` is a high-blast-radius RPC because it is associated with tenant/company creation and root provisioning behavior.

The combination of the following attributes makes it the first hardening candidate:

- root/tenant creation surface;
- `SECURITY DEFINER`;
- `search_path=public`;
- `anon_execute=true`;
- `PUBLIC` EXECUTE ACL;
- insert/body indicators;
- potential cross-tenant and governance impact if callable by unintended actors.

Non-claims:

- This document does not claim exploitation occurred.
- This document does not claim the whole platform is production-insecure.
- This document does not claim all root/billing RPCs are unsafe.
- This document does not authorize grant/revoke.
- This document does not authorize migration execution.
- This document does not authorize frontend changes.
- This document does not authorize MesaCliente changes.

---

## 5. Expected contract

The intended contract for `criar_empresa_root` must be validated before hardening.

Authority definition:

```text
Only a root actor with is_root = true may create companies through this RPC.
The term admin must not be interpreted as a local tenant admin or company admin.
If a future global-admin role exists, it must be explicitly proven equivalent to is_root = true before being accepted.
```

Expected behavior:

1. Unauthenticated users must not create companies.
2. `anon` must not create companies.
3. Authenticated non-root users must not create companies.
4. Inactive root actors must not create companies.
5. Invalid plan references must be rejected safely.
6. Duplicate slugs must be handled safely.
7. Malformed slugs must be rejected.
8. Missing required fields must be rejected.
9. A valid root actor path must remain functional.
10. Audit trail must be preserved.
11. No customer, broker, tenant or billing state may be derived from frontend authority alone.

Expected authority model:

```text
Caller identity must be derived server-side.
Root eligibility must be validated server-side with is_root = true.
Tenant/company creation must be decided by database/RPC rules.
Frontend input is request data, not authority.
```

---

## 6. Body review requirements before technical change

Before any technical hardening PR, the function body must be reviewed with sanitized excerpts only.

Required checks:

- whether `auth.uid()` is used;
- whether actor lookup is server-side;
- whether actor active status is checked;
- whether root eligibility is checked with `is_root = true`;
- whether no local tenant admin can satisfy root eligibility;
- whether plan existence is checked;
- whether slug uniqueness is checked;
- whether slug normalization/validation exists;
- whether audit logging exists;
- whether inserts touch only expected tables;
- whether payload fields are allowlisted;
- whether errors fail closed;
- whether SECURITY DEFINER is necessary;
- whether `search_path=public` should be replaced by a safer explicit path.

Do not commit raw function body output.

Allowed evidence:

- short sanitized excerpts;
- boolean indicators;
- table names;
- field categories;
- control-flow summaries;
- test outcomes.

Forbidden evidence:

- tokens;
- secrets;
- passwords;
- raw customer data;
- raw broker data;
- production UUIDs;
- private URLs;
- raw payloads;
- raw full function body.

---

## 7. Technical hardening options for next PR

This document does not apply these options. It only prepares decision criteria.

### Option A - Grant hardening only

Potential future action:

- remove `PUBLIC` EXECUTE from `criar_empresa_root`;
- remove `anon` EXECUTE from `criar_empresa_root`;
- preserve `authenticated` EXECUTE only if the body correctly validates root authority internally with `is_root = true`.

When acceptable:

- body review confirms authenticated root guard is correct;
- negative tests prove anon and non-root cannot create tenant;
- valid root path is preserved;
- rollback is explicit.

### Option B - Body guard hardening plus grant hardening

Potential future action:

- strengthen body guards;
- set or confirm safe search_path;
- remove `PUBLIC` EXECUTE;
- remove `anon` EXECUTE;
- preserve only intended role execution.

When required:

- body review finds missing or insufficient `auth.uid()`/root/active/plan/slug validation;
- current behavior cannot be safely narrowed by grants alone.

### Option C - Deferred technical hardening

Potential future action:

- keep grants unchanged temporarily;
- add tests and body evidence first;
- defer grant migration to the next PR.

When required:

- unknown provisioning dependency exists;
- frontend provisioning flow depends unexpectedly on current execution path;
- audit path is not yet verified.

---

## 8. Negative test matrix

Minimum required tests before or with technical hardening:

| test | expected result | required before merge of technical PR |
|---|---|---:|
| unauthenticated call | blocked | yes |
| anon call | blocked | yes |
| authenticated non-root call | blocked | yes |
| inactive root actor call | blocked | yes |
| authenticated local tenant admin call | blocked | yes |
| invalid plan id | blocked | yes |
| duplicate slug | safe failure | yes |
| malformed slug | blocked | yes |
| missing required fields | blocked | yes |
| valid root actor request | succeeds | yes |
| audit record/path | preserved | yes |
| no unintended MesaCliente impact | unchanged | yes |
| no direct DML corretores impact | unchanged | yes |

Cross-tenant misuse test:

If the body accepts or derives company/tenant context from input, include a negative test proving that cross-tenant misuse is blocked. If the function creates a new tenant without existing target tenant, document why cross-tenant test is not applicable and which governance test replaces it.

---

## 9. Rollback plan for future technical PR

Any future technical PR must include an explicit rollback.

If the next PR changes grants only:

```sql
-- rollback template only; do not execute in this PR
-- restore prior EXECUTE exposure exactly as recorded in PR #72 if production breakage is detected
```

Rollback must document:

- previous `PUBLIC` EXECUTE state;
- previous `anon` EXECUTE state;
- previous `authenticated` EXECUTE state;
- validation query after rollback;
- user-facing impact check;
- audit-path check.

If the next PR changes function body:

- preserve previous function definition in migration rollback notes;
- include body checksum or sanitized body version reference;
- include tests proving valid root creation still works after rollback.

No rollback needed for this PR because it is documentation-only.

---

## 10. Acceptance criteria for this PR

This PR is acceptable only if:

- it is documentation-only;
- it changes only Markdown under `docs/security/evidence/`;
- it does not alter migrations;
- it does not alter Supabase objects;
- it does not alter grants;
- it does not alter RLS or FORCE RLS;
- it does not alter RPC/function bodies;
- it does not alter frontend behavior;
- it does not alter Edge Functions;
- it does not alter MesaCliente parser or financial engine;
- it does not mix MesaCliente with root provisioning hardening;
- it does not mix direct DML `corretores` with root provisioning hardening;
- it contains no secrets, tokens, raw payloads, production UUIDs, customer data or broker data;
- it does not authorize hardening without validation;
- it does not allow local tenant admin authority to be treated as root authority.

---

## 11. Recommended next PR

If this plan is validated and merged, the next PR should be one of:

### Preferred next PR

```text
#74 - technical hardening for criar_empresa_root EXECUTE exposure
```

Minimum scope:

- one migration focused on `criar_empresa_root` grants and/or body guard if justified;
- one evidence document with test results;
- no MesaCliente changes;
- no direct DML changes;
- no broad grant cleanup;
- explicit rollback.

### Alternative next PR

```text
#74 - sanitized body review for criar_empresa_root
```

Use this if body review is still insufficient for a safe migration.

---

## 12. Final conclusion

`criar_empresa_root` is the correct first focused hardening candidate after PR #72 because it combines root/tenant creation, `SECURITY DEFINER`, `search_path=public`, `anon_execute=true`, `PUBLIC` EXECUTE ACL and insert indicators.

This PR does not harden it.

This PR narrows the next technical decision to a single RPC with explicit root-only authority, tests, rollback and non-goals.
