# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR104_GATEWAY / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch, base, head, object set and lifecycle state observed.

A new commit invalidates prior exact-head Ready conclusions. A migration, deploy, Action update or live object change invalidates pre-application catalog evidence for the affected objects.

Designed tests are not executed tests. Versioned code is not live-application evidence.

## 2. Canonical anchors

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
PR #102: CLOSED / MERGED
PR #102 final head: 26395a5751ded7f3bc6908f36615f761d709199c
PR #102 squash: b685b360404bbfd0a84a4b755b3092ee35a20e5e
Master-plan blob: ea161050c535b848ff927133830984f543c1104d
```

## 3. PR #103 evidence target

```text
PR: #103
Base: b685b360404bbfd0a84a4b755b3092ee35a20e5e
Head: abf6b4026343eae437283280269ed2997911dcec
State: OPEN / DRAFT / FROZEN
Commits: 5
Changed files: 1
```

GPT3 exact-head result:

```text
Static migration contract: ACCEPTABLE
New concrete code defect: NONE
Catalog evidence: INCONCLUSIVE
Ready recommendation: NO
Reason: gateway database_access was false
```

This verdict is valid only for head `abf6b402...`. It does not authorize a new PR #103 commit.

## 4. PR #104 evidence target

```text
PR: #104
Base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
Branch: security/gpt3-supabase-catalog-gateway
State: OPEN / DRAFT
Final head: resolve live after declared scope is complete
Expected net changed files: 10
```

Expected paths:

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

Any extra path invalidates the expected scope.

## 5. Live Supabase evidence

Observed project:

```text
Project name: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Status: ACTIVE_HEALTHY
PostgreSQL: 17.6.1
```

Observed gateway state:

```text
Edge Function: gpt-especialista
Version: 7
Status: ACTIVE
verify_jwt: false
health_check: WORKING
security_metadata_snapshot in Edge/Action: YES
public.gpt_security_metadata_snapshot(): ABSENT
```

The user declared the integration secret rotated. The value was not read, recorded or independently compared.

## 6. Fixed SELECT contract evidence

Executed on `2026-07-26`:

```text
BEGIN
SET LOCAL ROLE service_role
fixed catalog SELECT
ROLLBACK
```

Evidence state:

| Evidence | Target | State |
|---|---|---|
| Query parses | fixed snapshot SELECT | VERIFIED |
| Execution as `service_role` | fixed snapshot SELECT | VERIFIED |
| Persistent mutation | transaction | ZERO |
| Business-row reads | application tables | ZERO |
| `auth.users` row reads | Auth | ZERO |
| Secret reads | environment/database | ZERO |
| Snapshot version | `pr103_preflight_v1` | VERIFIED |
| Table/RLS metadata | `public.corretores` | VERIFIED |
| Required columns/types | PR #103 preflight | VERIFIED |
| UNIQUE index on `user_id` | `corretores_user_id_key` | VERIFIED |
| Roles/memberships | required roles | VERIFIED |
| Schema/table/column privileges | required roles | VERIFIED |
| Default function ACL | owner `postgres` | VERIFIED |
| Trigger and trigger function | `public.corretores` | VERIFIED |
| `auth.uid()` | required function | VERIFIED |
| `plpgsql` | required language | VERIFIED |

This evidence validates the query body and required catalog visibility. It does not prove that the PR #104 function, grants or Edge version exist live.

## 7. Versioned implementation evidence

```text
Migration: VERSIONED IN PR #104
Edge Function source: VERSIONED IN PR #104
OpenAPI contract: VERSIONED IN PR #104
Evidence/SFJM: VERSIONED IN PR #104
Live migration application: NOT EXECUTED
Live Edge deploy from PR #104: NOT EXECUTED
Live Action reconciliation: NOT EXECUTED
```

## 8. Missing evidence

- final PR #104 head and complete diff validation;
- GPT0/GPT1/GPT3/GPT4 exact-head audits;
- checks and review-thread state at final head;
- Ready and merge authority;
- merge/squash commit;
- live migration application;
- final RPC owner, `search_path` and effective ACL after application;
- live Edge deployment from versioned source;
- live Action update from versioned OpenAPI;
- `health_check` and `security_metadata_snapshot` after application;
- invalid key, forbidden operation, extra field, wrong content type and oversized-body tests;
- GPT3 PR #103 re-audit using the Action;
- PR #103 Ready/merge/application gates.

## 9. Invalidation events

Revalidate after:

- any PR #104 head or changed-file change;
- any PR #103 head change;
- any `main` change before PR #104 lifecycle gates;
- any live RPC, grant, Edge Function, secret-name or Action-contract change;
- any change to `public.corretores`, its triggers, policies, grants or indexes;
- any material audit finding;
- any secret exposure or authentication uncertainty.

## 10. Current conclusion

```text
PR #103: FROZEN / EVIDENCE BLOCKER OPEN
PR #104: OPEN / DRAFT
PR #104 final-head audits: MISSING
Live gateway application: NOT AUTHORIZED / NOT EXECUTED
GPT3 PR103 re-audit: MISSING
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

When freshness cannot be established, classify as `NOT_VERIFIED` or `STALE`, block the decision and refresh only the narrow required evidence.
