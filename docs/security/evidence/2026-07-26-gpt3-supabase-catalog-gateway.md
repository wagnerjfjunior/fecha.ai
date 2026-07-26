# FECH.AI — GPT3 Supabase Catalog Gateway Evidence

**Status:** `DRAFT_PR / IMPLEMENTATION_VERSIONED / LIVE_APPLICATION_NOT_AUTHORIZED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**PR:** `#104`  
**Base:** `main@b685b360404bbfd0a84a4b755b3092ee35a20e5e`  
**Branch:** `security/gpt3-supabase-catalog-gateway`  
**Initial technical head:** `66e548f18ec1982c77a27a33353cc36beea1d408`

## 1. Purpose

Provide one bounded server-to-server path for GPT3 to independently revalidate the live PostgreSQL catalog premises of PR #103.

```text
GPT3 Action
→ Edge Function gpt-especialista
→ fixed operation security_metadata_snapshot
→ public.gpt_security_metadata_snapshot()
→ allowlisted pg_catalog / information_schema metadata
```

This artifact does not authorize Ready, merge, deploy, migration application, PR #103 application or Security Go.

## 2. Parallel PR boundary

PR #103 remains frozen:

```text
PR: #103
State: OPEN / DRAFT
Base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
Head: abf6b4026343eae437283280269ed2997911dcec
Changed files: 1
Additional commits: NOT AUTHORIZED by PR #104
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Supabase application: NOT AUTHORIZED
```

PR #104 must not modify the PR #103 branch, migration, description or metadata.

## 3. Versioned objects

```text
supabase/migrations/20260726180000_gpt_security_metadata_snapshot.sql
supabase/functions/gpt-especialista/index.ts
docs/integrations/gpt3-supabase-action.openapi.yaml
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

## 4. RPC contract

```text
Function: public.gpt_security_metadata_snapshot()
Arguments: NONE
Return: jsonb
Language: sql
Volatility: STABLE
Security: INVOKER
search_path: pg_catalog
Owner intended: postgres
EXECUTE intended: service_role only
```

The RPC accepts no table name, schema, ID, filter, SQL fragment or payload.

The snapshot is fixed to:

```text
snapshot_version: pr103_preflight_v1
project_ref: uobxxgzshrmbtjfdolxd
schema: public
target_table: corretores
```

Returned categories:

- target table metadata and RLS state;
- `user_id`, `ativo` and `must_change_password` column metadata;
- indexes and constraints;
- non-internal triggers;
- definitions only for trigger functions attached to `public.corretores`;
- `auth.uid()` and target password-RPC existence/metadata;
- required roles and memberships;
- schema, table and column privileges;
- default function ACL;
- `plpgsql` availability;
- policies on `public.corretores`.

Explicit exclusions:

```text
business rows: NONE
auth.users rows: NONE
lead/customer data: NONE
message payloads: NONE
secrets/tokens: NONE
arbitrary SQL: NONE
caller-selected objects: NONE
```

## 5. Edge gateway hardening

The versioned Edge Function:

- requires `POST`;
- requires `application/json`;
- limits the body to 2 KiB;
- authenticates through `x-gpt-action-key`;
- compares the secret using SHA-256 digest comparison;
- accepts exactly one request property: `operation`;
- allows only `health_check` and `security_metadata_snapshot`;
- rejects extra fields server-side;
- calls one fixed RPC;
- validates snapshot version, project ref and negative data-scope flags;
- never logs the snapshot or supplied secret;
- returns `Cache-Control: no-store`.

`verify_jwt = false` remains a deployment requirement because authentication is custom server-to-server. This setting is not authorized for deployment by the Draft PR itself.

## 6. Read-only validation executed

A query equivalent to the RPC body was executed on project `uobxxgzshrmbtjfdolxd` under:

```text
BEGIN
SET LOCAL ROLE service_role
SELECT fixed catalog snapshot
ROLLBACK
```

Result:

```text
query parsed: YES
service_role execution: YES
snapshot_version: pr103_preflight_v1
business-row reads: ZERO
auth.users reads: ZERO
persistent mutations: ZERO
```

Material categories returned included:

- `public.corretores` with RLS enabled and forced;
- required columns and types;
- valid immediate UNIQUE index `corretores_user_id_key` on `user_id`;
- roles `postgres`, `authenticated`, `anon`, `service_role`;
- role memberships;
- table and column effective privileges;
- default function ACL;
- `auth.uid()` existence;
- `plpgsql`;
- `trg_audit_trail_corretores_critical_update`;
- definition of `audit_trail_log_corretores_critical_update`;
- current policies.

This validates the SELECT contract only. It is not evidence that the migration has been applied.

## 7. Live drift observed

Before PR #104:

```text
Edge Function gpt-especialista: ACTIVE / version 7
Action health_check: working
Action security_metadata_snapshot: configured
public.gpt_security_metadata_snapshot(): ABSENT
```

The active Edge Function therefore exposes a capability that returns a controlled error until the RPC exists.

The user declared that the exposed integration secret was rotated. No secret value is stored in this repository.

## 8. Acceptance criteria

PR #104 may be recommended Ready only if:

1. exact head and changed files are validated;
2. GPT0 confirms documentation and no overclaim;
3. GPT1 confirms separation from PR #103 and rollback;
4. GPT3 validates RPC, ACL, catalog scope and Edge boundary;
5. GPT4 validates PR lifecycle and release contract;
6. no secret or PII appears in the diff;
7. no arbitrary SQL or object-selection path exists;
8. no BLOCKING remains.

## 9. Future live application

A merged PR does not authorize production application.

A separate `CONTROLLED_BETA_PRIMARY_CHANGE` must identify:

- exact project ref;
- exact squash commit;
- exact migration;
- exact Edge Function source;
- exact OpenAPI version;
- operator;
- preflight;
- order;
- smoke tests;
- stop conditions;
- rollback;
- evidence and expiration.

Required order:

```text
migration
→ RPC ACL/contract verification
→ PostgREST schema reload if needed
→ Edge Function deploy
→ Action contract update
→ health_check
→ security_metadata_snapshot
→ negative request tests
→ sanitized evidence
```

## 10. Rollback

Database:

```sql
revoke all on function public.gpt_security_metadata_snapshot() from public;
revoke all on function public.gpt_security_metadata_snapshot() from anon;
revoke all on function public.gpt_security_metadata_snapshot() from authenticated;
revoke all on function public.gpt_security_metadata_snapshot() from service_role;
drop function if exists public.gpt_security_metadata_snapshot();
```

Edge:

```text
Redeploy the previously validated version.
```

Action:

```text
Restore the prior OpenAPI contract.
```

Secret:

```text
Rotate again if exposure or authentication uncertainty occurs.
```

Rollback of PR #104 does not alter PR #103 or `public.corretores`.

## 11. Current conclusion

```text
PR #104: OPEN / DRAFT
Implementation: VERSIONED
Live application: NOT AUTHORIZED / NOT EXECUTED
PR #103: FROZEN
GPT3 PR103 re-audit: PENDING GATEWAY AVAILABILITY
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```
