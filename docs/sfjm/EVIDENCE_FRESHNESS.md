# FECH.AI — SFJM Evidence Freshness

**Status:** `ACTIVE_FRESHNESS_RULES / F1_02_READ_ONLY_CAPTURED / FAIL_CLOSED`  
**Observed on:** 2026-07-24

## 1. Purpose

Freshness determines whether an observation may support a current decision. Fresh evidence is not automatically correct or sufficient.

## 2. Classes

```text
CURRENT
STALE
SUPERSEDED
NOT_VERIFIED
NOT_APPLICABLE
```

## 3. General invalidation rules

| Evidence | CURRENT condition | Invalidating event |
|---|---|---|
| PR head/diff | exact head validated | commit, rebase, force-push or branch change |
| Mergeability/reviews/checks | live state at exact head | base/head/review/check change |
| Canonical `main` | exact current tip | new commit on `main` |
| Source file | exact blob/commit | relevant file change |
| Supabase project identity | exact live project/ref | environment ambiguity or project replacement |
| Grants/RLS/policies/functions | read from exact project | migration, manual change or unreconciled drift |
| Negative tests | exact backend state and fixtures | backend/security/environment change |
| Runtime smoke | exact build/config/backend | deploy, code, config or backend change |
| Authorization | exact scope still active | completion, revocation, expiration or scope change |
| Handoff | agrees with live evidence | material PR, evidence, authority, blocker, decision or next-action change |

## 4. Canonical GitHub record

```text
Canonical main validated live: 0555bad889c6ab85970ee242a0e35ac6873508e8
Commit: docs(sfjm): close PR99 cycle and prevent recursive reconciliation (#100)
PR #100: CLOSED / MERGED
PR #100 final head: defeda035c5e7f709e31707a84c9edd488c99799
PR #100 squash commit: 0555bad889c6ab85970ee242a0e35ac6873508e8
Classification: CURRENT at PR-00 branch creation
```

A newer `main` commit invalidates the exact tip for later sensitive work. The squash merge of a bounded self-closing documentation PR does not by itself require another reconciliation PR; live validation before the next sensitive action is sufficient when no material state changed.

## 5. F1-01 source-path evidence

```text
Artifact: docs/audits/mvp/2026-07-05-f1-01-m1-acceptance-evidence-map.md
PR #94 final head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
PR #94 squash: 1caf90c60681771af6609b96ee840b190668fa0f
Source-path classification: CURRENT at source commit 0555bad889c6ab85970ee242a0e35ac6873508e8
Product/runtime acceptance: NOT_VERIFIED
```

Any change to M1 call sites invalidates affected map rows.

## 6. F1-02 live Supabase evidence

```text
Project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Status observed: ACTIVE_HEALTHY
Observation date: 2026-07-24
Method: read-only metadata and definition queries
Mutations: ZERO
Lead/customer row reads: ZERO
```

Evidence classes:

| Evidence | Classification at capture |
|---|---|
| project provenance/status | CURRENT |
| grants and column/table privileges | CURRENT |
| RLS/force-RLS and policies | CURRENT |
| relevant RPC/function definitions and execute exposure | CURRENT |
| relevant constraints and triggers | CURRENT |
| security advisors | CURRENT |
| exploitability through executed negative tests | NOT_VERIFIED |
| post-remediation state | NOT_VERIFIED |
| runtime smoke | NOT_VERIFIED |
| Security Go | DENIED, not an evidence class |

Canonical Draft evidence:

```text
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

Until PR-00 is independently audited and merged, these documents are `DRAFT / NOT YET CANONICAL` even though their underlying live observations were performed.

## 7. Invalidating events for F1-02 evidence

Refresh relevant evidence after:

- any migration or manual database change;
- RLS, grant, policy, trigger, constraint or function change;
- Auth configuration change;
- project/environment replacement or ambiguity;
- source call-site change for a used M1 path;
- deployment/config change affecting tested paths;
- lab recreation or fixture-contract change;
- production rollback.

A database change may invalidate only affected objects, but a gate decision must explicitly show which evidence remains current.

## 8. Negative-test freshness

Designed tests are not executed evidence.

A negative-test record is current only when it includes:

- exact repository commit;
- exact project ref and environment;
- synthetic fixture version;
- test ID and actor role;
- expected and actual result;
- timestamp;
- sanitized error/result;
- no intervening relevant backend/security change.

Tests from the isolated lab do not prove production application. Production still requires object verification and controlled smoke.

## 9. PR-00 freshness

```text
Branch: docs/f1-02-security-remediation-program
Base: 0555bad889c6ab85970ee242a0e35ac6873508e8
Required freshness target: exact final PR head
```

PR-00 audit becomes stale after any head change. Ready and merge decisions require revalidation of final head, changed files, diff, reviews and checks.

## 10. Fail-closed rule

When freshness cannot be established:

```text
classification = NOT_VERIFIED or STALE
security/merge/deploy conclusion = BLOCKED
next action = refresh only the narrow evidence required
```

Do not replace missing freshness with memory, conversation continuity, preview success or confidence.
