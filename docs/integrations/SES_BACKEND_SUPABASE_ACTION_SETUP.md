# FECH.AI — SES Backend Supabase Read-Only Action Setup

**Status:** CANDIDATE / PROJECT-LOCAL TOOL BINDING  
**Target specialist:** `backend-data-platform-specialist`  
**Target project:** `fechai`  
**Supabase project ref:** `uobxxgzshrmbtjfdolxd`  
**OpenAPI:** `docs/integrations/ses-backend-supabase-readonly-action.openapi.yaml`

## Purpose

Give the SES Backend & Data Platform Specialist a project-bounded live database evidence channel so requests for a live database audit do not silently degrade into repository-only analysis.

This is a FECH.AI project-local binding. It is not a universal SES endpoint and must not be copied to other projects with the same project ref or credentials.

## Authentication

The Action calls the Supabase Management API over HTTPS using bearer authentication.

Do not commit a token to GitHub, Builder Instructions, Knowledge, screenshots, comments or normal chat text.

Supabase Management API requires a Management API access token in the `Authorization: Bearer ...` header. Use a Personal Access Token (PAT) generated from the Supabase account-level Access Tokens page, not a project API key from Project Settings > API Keys.

Do NOT use `sb_secret_...`, `sb_publishable_...`, legacy `anon`, or legacy `service_role` as the Management API bearer credential. `sb_secret_...` is a project API key for project APIs and is not a Management API PAT; sending it as the bearer credential to `api.supabase.com` can fail with token/JWT decoding errors.

PATs carry the privileges of the Supabase user account, so protect the token as a secret and use the shortest practical expiry. The intended SQL operation remains read-only because the OpenAPI request fixes `read_only=true`.

## Builder configuration

1. Open the custom GPT `SES — Backend & Data Platform Specialist` in Edit mode.
2. Add a new Action.
3. Paste the full contents of `docs/integrations/ses-backend-supabase-readonly-action.openapi.yaml`.
4. Configure Action authentication as bearer/API-token authentication.
5. Paste a Supabase **Management API Personal Access Token (PAT)** generated at the account level into the Builder secret field only. Do not paste a project `sb_secret_...` key.
6. Never paste the token into the OpenAPI YAML.
7. Save/update the GPT.
8. Start a new conversation for runtime testing.

Exact Builder labels may vary. The invariant is:

```text
Authorization: Bearer <SUPABASE_MANAGEMENT_PAT>
```

## Required live-audit preflight

For a request requiring current database state, the specialist must first call a minimal read-only operation and report:

```text
REQUESTED_PROOF_LEVEL: LIVE_DATABASE_AUDIT
REQUIRED_CAPABILITY: FECHAI_SUPABASE_LIVE_READ
CAPABILITY_STATUS: AVAILABLE / UNAVAILABLE / ERROR
TARGET: uobxxgzshrmbtjfdolxd
TASK_ADMISSION: ADMITTED / BLOCKED
```

A suitable probe is a bounded catalog query such as PostgreSQL version/current database identity or a small `pg_catalog` query.

## Action surface

The Builder Action intentionally exposes only one operation:

```text
runFechaiReadOnlyDatabaseQuery
POST /v1/projects/uobxxgzshrmbtjfdolxd/database/query
read_only = true
```

The previous `security advisors` and `database OpenAPI` operations were removed after runtime testing produced `ResponseTooLargeError`. Their removal reduces payload risk without removing the core live-audit capability because the database query operation can inspect the required catalog state in bounded slices.

## Allowed evidence class

Default live audit scope:
- schemas/tables/columns;
- constraints/indexes;
- RLS enable/force state;
- policies;
- privileges;
- roles/memberships where available;
- functions/procedures, owners, security mode, search_path and ACLs;
- triggers;
- extensions/configuration material to the audit;
- applied/live state needed to compare against migrations.

## Data minimization

The SQL operation is technically capable of reading database rows. This does not authorize broad data extraction.

```text
CATALOG / METADATA = ALLOWED FOR AUDIT
BUSINESS ROWS = DO NOT READ UNLESS MATERIAL + EXPLICITLY AUTHORIZED
AUTH USER DATA = DO NOT READ UNLESS MATERIAL + EXPLICITLY AUTHORIZED
SECRETS = NEVER RETURN
```

## Mutation boundary

```text
ACTION READ CAPABILITY != WRITE AUTHORIZATION
LIVE DATABASE AUDIT != MIGRATION APPLY
```

The Action schema intentionally exposes no write endpoint and forces `read_only=true` on SQL query execution.

Any future mutation Action must be a separate project-local contract and lifecycle.

## Runtime acceptance test

### A — capability probe

Ask:

> Faça somente o capability preflight para uma auditoria LIVE do banco FECH.AI. Não faça a auditoria completa.

Expected: the Action is actually invoked and the response identifies live access.

### B — unavailable-action behavior

Temporarily test with the Action unavailable in a separate controlled Builder/runtime if practical.

Expected: the specialist blocks the live audit before substantive static analysis and offers static fallback.

### C — exact live audit

Ask for live RLS/functions/triggers/roles and require exact operations invoked.

Expected: claims are sourced from a sequence of bounded `runFechaiReadOnlyDatabaseQuery` calls, each scoped to one evidence class (for example tables/RLS, policies, functions, triggers, grants/roles), with GitHub used only as complementary/versioned evidence.

Avoid giant all-in-one snapshots. Prefer multiple small catalog queries with explicit result bounds.

## Proof boundary

Adding this Action changes the runtime tool surface. Existing Backend/Data v0.1 fingerprint PASS does not prove this new runtime configuration.

Builder application + runtime delta tests are required before the new configuration is treated as certified.
