# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR104_LIVE_GATEWAY_VALIDATED / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch, head, object set, configuration and lifecycle state observed. Versioned code is not live evidence; deployed state and executed tests must be identified separately.

## 2. GitHub evidence

Observed before this documentation-only closure PR:

```text
main: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
PR #104: CLOSED / MERGED
PR #104 audited head: dc75198dd8d14fc2856890964771f3434942dd7a
PR #104 squash commit: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
PR #103: OPEN / DRAFT
PR #103 head: abf6b4026343eae437283280269ed2997911dcec
PR #103 commits/files: 5 / 1
```

The closure PR merge may advance main. Per the SFJM self-closing rule, that documentation-only merge does not require another reconciliation PR unless it introduces new material state.

## 3. PR #104 audit evidence

```text
GPT0: PASS WITH RESIDUAL RISK
GPT1: PASS WITH RESIDUAL RISK
GPT3 final: PASS
GPT4 final: PASS WITH RESIDUAL RISK
BLOCKING: NONE
REQUIRED BEFORE READY: NONE
```

These conclusions remain fresh for the merged PR #104 scope. They are invalidated by a material change to the migration, OpenAPI, Edge source, RPC contract/ACL, authentication boundary or exposed snapshot scope.

## 4. Live Supabase evidence

Project:

```text
uobxxgzshrmbtjfdolxd / production
```

Verified live:

```text
Migration version: 20260726224527
Migration name: gpt_security_metadata_snapshot
RPC: public.gpt_security_metadata_snapshot()
Arguments: none
Return: jsonb
Owner: postgres
Language: sql
Volatility: STABLE
Security: SECURITY INVOKER
search_path: pg_catalog
service_role EXECUTE: true
PUBLIC EXECUTE: false
anon EXECUTE: false
authenticated EXECUTE: false
unexpected direct executors: false
```

The fixed RPC executed successfully under `service_role` and returned:

```text
snapshot_version: pr103_preflight_v1
project_ref: uobxxgzshrmbtjfdolxd
access_mode: read_only
includes_row_data: false
includes_auth_users: false
includes_secrets: false
includes_business_payload: false
table: public.corretores
RLS enabled: true
RLS forced: true
columns: 3
roles: 4
policies: 3
indexes: 8
constraints: 8
triggers: 1
```

No application row, `auth.users`, lead, customer, message, credential or secret payload was read.

## 5. Live Edge evidence

```text
Function: gpt-especialista
Status: ACTIVE
Version: 8
verify_jwt: false
Bundle SHA-256: cb850eac4475d65ba8db9f1cf2d03a26abb3d4964b742d97b4e01c6552eabeeb
Authentication: custom x-gpt-action-key
```

The retrieved live source matched the versioned final validator, including semantic RFC 3339 checks and the fail-closed invalid-contract path.

## 6. GPT Action evidence

Evidence supplied by GPT3 and independently corroborated through direct Supabase connector validation:

```text
health_check: OK
security_metadata_snapshot: OK
environment: production
access_mode: read_only
database_access: true
row_data_access: false
secrets included: false
auth.users included: false
writes: NONE
```

No GPT Action configuration mutation was performed during the live application. The existing Action configuration successfully reached the deployed Edge and RPC.

## 7. Migration-history incident evidence

Two unintended history-only records were created during validation and immediately removed:

```text
gpt_security_metadata_snapshot_marker_check
noop_should_not_exist
```

Final verification:

```text
unauthorized marker records: 0
authorized migration retained: gpt_security_metadata_snapshot
schema/function/policy/RLS/grant residual from markers: NONE
```

This incident is closed but remains part of the operational evidence trail.

## 8. PR #103 evidence state

The gateway dependency is operational. PR #103 itself remains a separate, unresolved workstream.

```text
PR #103 exact-head audit against current main: REQUIRED IN SEPARATE CONVERSATION
PR #103 Ready authority: NOT ESTABLISHED HERE
PR #103 merge authority: NOT ESTABLISHED HERE
PR #103 live application: NOT EXECUTED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

## 9. Invalidation events

Revalidate the narrow affected evidence after any:

- change to `public.gpt_security_metadata_snapshot()`;
- grant, owner, volatility, language or search-path change;
- change to Edge source, version, `verify_jwt` or custom authentication;
- secret rotation affecting the Action/Edge path;
- OpenAPI or allowed-operation change;
- expansion of snapshot scope or inclusion of row data;
- PR #103 head or base reconciliation change;
- new security finding.

## 10. Closed-loop rule

Do not rerun PR #104 gates or open a new closure-only reconciliation PR solely because this documentation PR advances main. Use live validation before the next substantive action and update SFJM within that later bounded change.
