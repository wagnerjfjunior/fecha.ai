# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch, base, head, object set and lifecycle state observed.

A new commit invalidates prior exact-head conclusions for Ready. Prior findings remain historical input, not approval of a later head.

No designed test is treated as executed. No documentation-only change is treated as Supabase or runtime evidence.

## 2. Canonical anchors

```text
main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
Master-plan blob: ea161050c535b848ff927133830984f543c1104d
```

## 3. PR #102 history

```text
Initial Draft:
fc83ed752217bfc39810dfba38e93405bc7382b8
7 commits / 7 net files / FAIL

First correction:
6b7d96fb26d6589641bc079146db9c3f429b9bd2
8 commits / 8 net files
GPT0 FAIL; GPT1/GPT3 PASS WITH RESIDUAL RISK

Master-plan restoration:
7b8c23bd375d750e73d888f140c8c44a840280a5
9 commits / 7 net files
Master-plan blob restored: ea161050c535b848ff927133830984f543c1104d
GPT0 FAIL only for stale lifecycle and authority-name mapping

Final lifecycle-and-alias correction:
parent 7b8c23bd375d750e73d888f140c8c44a840280a5
final head resolved live
expected 10 commits / 7 net files / 6 final-commit paths
```

## 4. Final corrective scope

Exactly these six paths may change:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

These must remain unchanged:

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
docs/sfjm/BLOCKED_ACTIONS.md
```

Any additional path blocks Ready.

## 5. Evidence state

| Evidence | Target | State |
|---|---|---|
| F1-02 findings/master plan | `main@affbae1a...` | CANONICAL BASELINE |
| Strategy amendment | final PR #102 head | DRAFT / NOT_YET_CANONICAL |
| Master-plan restoration | blob `ea161050...` | MUST REMAIN UNCHANGED |
| GPT0/GPT1/GPT3 at `6b7d96fb...` | historical head | FINDING INPUT / NOT READY EVIDENCE |
| GPT0 at `7b8c23bd...` | pre-final head | HISTORICAL REQUIRED FINDINGS |
| GPT0 at final head | final head | MISSING |
| GPT1/GPT3 at final head | final head | MISSING |

## 6. Authority-name freshness

```text
PR_LIFECYCLE = TECHNICAL_PR_LIFECYCLE
PRODUCTION_CHANGE = CONTROLLED_BETA_PRIMARY_CHANGE
```

These are strict aliases only. They create no authority and cannot be used without a new exact authorization.

## 7. Supabase and runtime evidence

```text
Supabase read under this correction: NONE
Supabase mutation: NONE
SQL/migration: NONE
Fixture creation: NONE
Negative tests: NONE
Rollback/reapply: NONE
Runtime/frontend change: NONE
Production smoke: NONE
Security Go: DENIED
```

Historical read-only evidence remains valid only for the objects and date observed and must be refreshed narrowly before a future technical change.

## 8. Invalidation events

Revalidate after:

- any PR #102 head change;
- a `main` change before Ready or merge;
- master-plan or `BLOCKED_ACTIONS.md` drift;
- changed-file scope drift;
- amendment or alias-map changes;
- any migration, RLS, grant, policy, RPC, Auth or runtime change;
- a material audit finding.

## 9. Current conclusion

```text
PR #102: OPEN / DRAFT
Final head: REQUIRES LIVE RESOLUTION
Expected commits: 10
Expected net changed files: 7
Independent final-head GPT0 audit: MISSING
Ready evidence: INCOMPLETE
Merge evidence: INCOMPLETE
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

When freshness cannot be established, classify as `NOT_VERIFIED` or `STALE`, block the decision and refresh only the narrow required evidence.
