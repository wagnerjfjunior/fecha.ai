# FECH.AI — GPT3 Supabase Catalog Gateway Evidence

**Status:** `DRAFT_PR / FINAL_RQ02_CORRECTION_VERSIONED / LIVE_APPLICATION_NOT_AUTHORIZED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**PR:** `#104`  
**Base:** `main@b685b360404bbfd0a84a4b755b3092ee35a20e5e`  
**Branch:** `security/gpt3-supabase-catalog-gateway`  
**Final head:** resolve from live PR metadata after this commit.

## 1. Purpose

Provide one bounded server-to-server path for GPT3 to inspect only the PostgreSQL catalog evidence required to re-audit PR #103.

```text
GPT3 Action
→ Edge gpt-especialista
→ fixed operation security_metadata_snapshot
→ public.gpt_security_metadata_snapshot()
→ fixed allowlisted catalog snapshot
```

This file is evidence documentation. It does not authorize Ready, merge, SQL application, RPC creation, Edge deployment, GPT Action update, PR #103 application, F1-02 acceptance or Security Go.

## 2. Product and authority context

```text
FECH.AI: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
MVP: MVP 1 — Família
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

PR #103 remains frozen at:

```text
Head: abf6b4026343eae437283280269ed2997911dcec
State: OPEN / DRAFT
Commits: 5
Changed files: 1
```

PR #104 does not modify PR #103.

## 3. Versioned technical contract

The migration versions exactly one no-argument RPC:

```text
Function: public.gpt_security_metadata_snapshot()
Return: jsonb
Language: sql
Volatility: STABLE
Security: INVOKER
search_path: pg_catalog
Owner intended: postgres
EXECUTE intended: service_role only
```

The RPC accepts no caller-provided schema, table, function, role, ID, filter or SQL.

The snapshot is fixed to:

```text
snapshot_version: pr103_preflight_v1
project_ref: uobxxgzshrmbtjfdolxd
access_mode: read_only
schema: public
target_table: corretores
```

Explicit exclusions:

```text
business rows: NONE
auth.users rows: NONE
lead/customer data: NONE
message payloads: NONE
arbitrary SQL: NONE
caller-selected objects: NONE
intentional secret-store reads: NONE
```

## 4. RQ-01 status

`RQ-01: RESOLVED` at parent head `134e0a8717a5cbd67e490af4c1bcd2fd2e3c8cd6`.

The migration preflight fails closed unless it proves:

- `public.corretores` is relkind `r` or `p`;
- `user_id` is `uuid`;
- `ativo` is `boolean`;
- `must_change_password` is `boolean`;
- `auth.uid()` exists;
- required roles exist;
- `sql` and `plpgsql` exist;
- no pre-existing `public.gpt_security_metadata_snapshot` overload exists.

The migration was not applied live.

## 5. RQ-02 final correction

GPT3 found that the OpenAPI contract was stricter than the Edge response validator. The final authorized correction changes only the Edge implementation and rejects malformed snapshots before HTTP 200.

`validateSnapshot()` now requires:

- `generated_at` to be a parseable RFC 3339 timestamp;
- exact top-level and scope keys;
- `table.owner` as string;
- `table.rls_enabled` and `table.rls_forced` as booleans;
- exactly three column objects;
- integer `ordinal_position`;
- string `udt_schema`, `udt_name`, `is_nullable` and `is_identity`;
- `column_default` and `identity_generation` as string or `null`;
- every element of every catalog metadata array to be a JSON object;
- required roles, `auth.uid()` and `plpgsql`;
- the existing fixed values and negative data-scope flags.

Malformed output follows the existing fail-closed path:

```text
HTTP 502
error: security_metadata_contract_invalid
```

No migration or OpenAPI change was required for this correction.

## 6. Historical read-only evidence

A fixed query equivalent to the RPC body was previously executed under:

```text
BEGIN
SET LOCAL ROLE service_role
SELECT fixed catalog snapshot
ROLLBACK
```

Recorded result:

```text
query parsed: YES
service_role execution: YES
business-row reads: ZERO
auth.users reads: ZERO
persistent mutations: ZERO
```

This historical query predates the final correction. It proves neither migration application nor the final Edge runtime.

## 7. Audit history

```text
GPT0 at 134e0a...:
PASS WITH RESIDUAL RISK
BLOCKING: NONE
REQUIRED IN THIS PR: NONE

GPT1 at 134e0a...:
PASS WITH RESIDUAL RISK
BLOCKING: NONE
REQUIRED IN THIS PR: NONE

GPT3 at 134e0a...:
FAIL
RQ-01: RESOLVED
RQ-02: PARTIALLY RESOLVED
Required correction: Edge output validation only
```

The Product Authority explicitly prohibited repeating GPT0 or GPT1 after this localized correction.

Required remaining gates:

```text
GPT3 targeted re-audit of the final RQ-02 delta
→ GPT4 final lifecycle gate on the complete final head
```

## 8. Live state and evidence boundary

Previously observed live state:

```text
Edge gpt-especialista: ACTIVE / version 7
health_check: WORKING
security_metadata_snapshot operation in Edge/Action: PRESENT
public.gpt_security_metadata_snapshot(): ABSENT
```

The versioned final correction has not been deployed.

Still absent:

- migration application;
- live RPC owner/search_path/ACL evidence;
- final Edge deployment;
- GPT Action reconciliation;
- positive and negative runtime tests;
- response-size measurement;
- renewed GPT3 audit of PR #103.

## 9. Rollback

Database rollback remains limited to revoking execution grants and dropping only `public.gpt_security_metadata_snapshot()`.

Edge rollback is redeployment of the previously preserved version. GPT Action rollback is restoration of the prior OpenAPI contract.

The final corrective commit is reversible by Git revert. Git revert is not database, Edge or Action rollback.

## 10. Next safe action

Resolve the new head from live GitHub metadata, verify the corrective delta is exactly the seven authorized files, and run:

```text
GPT3 targeted RQ-02 re-audit
→ GPT4 final gate
```

Do not repeat GPT0 or GPT1. Do not mark Ready, merge, apply SQL, deploy Edge, update the GPT Action, alter PR #103 or claim Security Go.
