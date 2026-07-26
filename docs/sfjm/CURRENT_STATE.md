# FECH.AI — SFJM Current State

**Lifecycle state:** `PR104_CLOSED / LIVE_GATEWAY_OPERATIONAL / PR103_SEPARATE_CONTINUATION`  
**Record type:** `OPERATIONAL_STATE / SECURITY_ENABLEMENT_CLOSURE`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Frontend/Action requests. Edge/RPC/Supabase validates and decides. AI assists but is not authority.

## 2. Canonical GitHub state before this closure PR

```text
main: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
Source PR: #104
PR #104: CLOSED / MERGED
Merge method: squash
PR #104 audited head: dc75198dd8d14fc2856890964771f3434942dd7a
PR #104 squash commit: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
```

This documentation-only closure PR may advance `main`. Under `docs/sfjm/INDEX.md`, that self-closing merge must not trigger another recursive reconciliation PR unless new material evidence appears.

## 3. PR #104 — closed subject

PR #104 completed the bounded GPT3 catalog gateway lifecycle:

```text
GPT0: PASS WITH RESIDUAL RISK
GPT1: PASS WITH RESIDUAL RISK
GPT3 final: PASS
GPT4 final: PASS WITH RESIDUAL RISK
BLOCKING: NONE
REQUIRED BEFORE READY: NONE
READY: COMPLETED
SQUASH MERGE: COMPLETED
```

Do not repeat GPT0, GPT1, GPT3 or GPT4 for PR #104 without a new material change to its code, migration, OpenAPI, deployed Edge, RPC contract or authorization boundary.

## 4. Live Supabase gateway state

```text
Project ref: uobxxgzshrmbtjfdolxd
Environment: production
Migration record: 20260726224527 / gpt_security_metadata_snapshot
RPC: public.gpt_security_metadata_snapshot()
RPC arguments: none
RPC return: jsonb
RPC owner: postgres
RPC language: sql
RPC volatility: STABLE
RPC security: SECURITY INVOKER
RPC search_path: pg_catalog
```

Live ACL validation:

```text
service_role EXECUTE: YES
PUBLIC EXECUTE: NO
anon EXECUTE: NO
authenticated EXECUTE: NO
Unexpected direct executors: NONE
```

The RPC returned the fixed catalog snapshot under `service_role` with:

```text
snapshot_version: pr103_preflight_v1
access_mode: read_only
includes_row_data: false
includes_auth_users: false
includes_secrets: false
includes_business_payload: false
target: public.corretores
RLS enabled: true
RLS forced: true
expected catalog columns: 3
```

## 5. Live Edge and GPT Action state

```text
Edge function: gpt-especialista
Status: ACTIVE
Version: 8
verify_jwt: false
Authentication boundary: x-gpt-action-key custom server-to-server authentication
Bundle SHA-256: cb850eac4475d65ba8db9f1cf2d03a26abb3d4964b742d97b4e01c6552eabeeb
```

The deployed Edge contains the final request allowlist, body-size limit, deep snapshot validation, semantic RFC 3339 validation and fail-closed `502 security_metadata_contract_invalid` path.

GPT3 independently repeated the Action path successfully:

```text
health_check: OK
security_metadata_snapshot: OK
database_access: true
row_data_access: false
secrets included: false
auth.users included: false
writes: NONE
```

No GPT Action configuration mutation was performed during the live application operation. The already configured Action successfully called the deployed gateway.

## 6. Migration-history correction incident

Two validation calls were accidentally sent through the migration endpoint and created history-only markers:

```text
gpt_security_metadata_snapshot_marker_check
noop_should_not_exist
```

Both records were removed immediately. Final verification showed zero unauthorized marker records and only the authorized `gpt_security_metadata_snapshot` migration remained. No table, function, policy, RLS or grant residual was created by those markers.

## 7. PR #103 — separate continuation

```text
PR: #103
State: OPEN / DRAFT
Branch: security/f1-02-password-state-rpc
Head: abf6b4026343eae437283280269ed2997911dcec
Commits: 5
Changed files: 1
Current live mergeability observation: true
```

PR #103 was not changed, marked Ready, merged or applied by the PR #104 lifecycle or gateway application.

The evidence blocker that required the catalog gateway has been removed. PR #103 must now continue in its existing separate conversation with fresh bootstrap, exact-head validation against the current `main`, gateway-backed evidence and separate authority for any Ready, merge or Supabase application.

## 8. Current authority state

```text
PR #104 correction authority: CONSUMED
PR #104 TECHNICAL_PR_LIFECYCLE: CONSUMED
Gateway CONTROLLED_BETA_PRIMARY_CHANGE: CONSUMED
Additional PR #104 commits or live changes: NOT AUTHORIZED
PR #103 lifecycle/application: NOT AUTHORIZED BY THIS CLOSURE
Gateway rollback: NOT AUTHORIZED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 9. Residual risk

- GitHub Actions remain absent for the PR #104 head; Vercel status did not prove SQL or Edge runtime.
- The Edge uses `verify_jwt=false` by design and therefore depends on correct preservation of custom `x-gpt-action-key` authentication.
- The gateway intentionally exposes bounded catalog metadata and limited trigger-function source, not application rows.
- PR #103 still requires its own exact-head revalidation and controlled lifecycle.
- Security Go remains denied.

## 10. Next safe action

Close the PR #104 topic. Continue only PR #103 in the already active separate conversation.

Do not reopen PR #104 audits, redeploy the gateway, alter its RPC, rotate/read secrets, or create another closure-only reconciliation loop without new material evidence and explicit authority.
