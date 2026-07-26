# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / FINAL_RQ02_DELTA / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch, base, head, object set and lifecycle state observed. Versioned code is not live evidence. Designed tests are not executed tests.

A change invalidates only conclusions materially dependent on the changed area. A localized Edge validator change does not automatically invalidate prior documentary or architectural findings when their inputs remain unchanged and the Product Authority explicitly limits the re-audit scope.

## 2. Canonical anchors

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #103 head: abf6b4026343eae437283280269ed2997911dcec
PR #103 state: OPEN / DRAFT / FROZEN
PR #104 base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #104 branch: security/gpt3-supabase-catalog-gateway
PR #104 final head: resolve live
```

## 3. Parent-head audits

At parent `134e0a8717a5cbd67e490af4c1bcd2fd2e3c8cd6`:

| Specialist | Result | Freshness after final correction |
|---|---|---|
| GPT0 | PASS WITH RESIDUAL RISK | retained for unchanged documentary and scope conclusions |
| GPT1 | PASS WITH RESIDUAL RISK | retained because architecture, migration, OpenAPI and primary risk are unchanged |
| GPT3 | FAIL; RQ-01 resolved; RQ-02 partial | superseded only for RQ-02 Edge output validation |
| GPT4 | not executed | pending on final head |

The Product Authority prohibited repeating GPT0 and GPT1.

## 4. Final corrective delta

Authorized parent:

```text
134e0a8717a5cbd67e490af4c1bcd2fd2e3c8cd6
```

Expected changed paths in the final commit:

```text
supabase/functions/gpt-especialista/index.ts
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

Unchanged technical objects:

```text
supabase/migrations/20260726180000_gpt_security_metadata_snapshot.sql
docs/integrations/gpt3-supabase-action.openapi.yaml
docs/sfjm/BLOCKED_ACTIONS.md
PR #103 migration and metadata
```

## 5. Historical Supabase evidence

Previously executed:

```text
BEGIN
SET LOCAL ROLE service_role
fixed catalog SELECT
ROLLBACK
```

Verified historically:

- query parsed;
- service_role could read the fixed catalog;
- persistent writes were zero;
- business-row reads were zero;
- `auth.users` reads were zero.

This remains historical query-contract evidence only.

## 6. Current evidence state

```text
RQ-01 code review: FRESH / RESOLVED
RQ-02 parent finding: SUPERSEDED BY FINAL EDGE DELTA
GPT0 repeat: PROHIBITED
GPT1 repeat: PROHIBITED
GPT3 targeted final-delta review: MISSING
GPT4 final-head gate: MISSING
Live gateway application: NOT AUTHORIZED / NOT EXECUTED
PR #103 re-audit through live gateway: MISSING
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

## 7. Invalidation events

Revalidate the narrow affected evidence after:

- any change to the final Edge validator;
- any change to migration or OpenAPI;
- any additional PR #104 path;
- any PR #103 head change;
- any live RPC, grant, Edge, Action or secret-name change;
- any material security finding.

## 8. Next evidence refresh

1. Resolve final PR #104 head and compare it to parent `134e0a...`.
2. Verify one commit and exactly seven changed files in the final delta.
3. GPT3 reviews only RQ-02 and unchanged technical-boundary assumptions.
4. GPT4 validates the complete final head, checks, threads, scope and lifecycle.
5. No Ready/merge/application conclusion is valid before those two gates.
