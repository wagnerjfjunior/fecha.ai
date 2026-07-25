# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch, base, head, object set and lifecycle state it observed.

A new commit invalidates prior exact-head audit conclusions for Ready. Prior findings remain useful as historical input, but they are not approval of the new head.

No designed test is treated as executed. No document is treated as live Supabase evidence.

## 2. Canonical repository anchor

```text
main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
```

The detailed F1-02 master plan canonical on `main` has blob:

```text
ea161050c535b848ff927133830984f543c1104d
```

## 3. PR #102 head history

### Initial Draft head

```text
fc83ed752217bfc39810dfba38e93405bc7382b8
Commits: 7
Changed files: 7
Audit result: FAIL
```

### First corrective head

```text
6b7d96fb26d6589641bc079146db9c3f429b9bd2
Commits: 8
Changed files: 8
GPT0: FAIL — master-plan normative regression
GPT1: PASS WITH RESIDUAL RISK
GPT3: PASS WITH RESIDUAL RISK
Ready recommendation: NO
```

GPT1/GPT3 approval at this head does not override the documentary blocker and does not apply to a later head.

### Detailed-baseline restoration head

```text
Parent: 6b7d96fb26d6589641bc079146db9c3f429b9bd2
Commit count after restoration: expected 9
Final head: authoritative in live PR metadata and PR description
Audit state: NOT YET AUDITED
Ready: NOT AUTHORIZED
```

## 4. Corrective scope evidence

The restoration commit is valid only if it changes exactly:

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

The master plan must be restored to the exact baseline blob. Therefore it is changed by the corrective commit but is expected to disappear from the final PR net diff against `main`.

Expected final PR net changed files:

```text
7
```

Any other corrective-commit path is invalidating evidence and blocks Ready.

## 5. Documentary evidence state

| Evidence | Exact target | State |
|---|---|---|
| PR #101 findings/master plan | `main@affbae1a...` | CANONICAL BASELINE |
| Strategy amendment | PR #102 final head | DRAFT / NOT_YET_CANONICAL |
| Detailed master-plan restoration | exact baseline blob | PRESENT ONLY AFTER LIVE VALIDATION |
| GPT0 audit at `6b7d96fb...` | old head | HISTORICAL / FINDING INPUT |
| GPT1 audit at `6b7d96fb...` | old head | INVALIDATED FOR READY BY NEW HEAD |
| GPT3 audit at `6b7d96fb...` | old head | INVALIDATED FOR READY BY NEW HEAD |
| GPT0 audit at restoration head | final head | MISSING |
| GPT1/GPT3 reaudits | final head | MISSING |

## 6. Supabase and runtime evidence

No operation in PR #102 provides evidence that any F1-02 technical blocker is remediated.

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

The historical live read-only inspection remains evidence of the state observed on its date. It must be narrowly refreshed before a technical change affecting those objects.

## 7. Invalidation events

Revalidate narrowly when any of the following occurs:

- PR #102 head changes;
- main changes before Ready or merge;
- the detailed master-plan blob differs from the baseline;
- the strategy amendment changes;
- changed-file scope changes;
- a future migration, RLS, grant, policy, RPC, Auth or runtime change affects relevant evidence;
- a new audit identifies a material inconsistency.

## 8. Current evidence conclusion

```text
PR #102: OPEN / DRAFT
Final restoration head: REQUIRES LIVE RESOLUTION
Detailed baseline restoration: REQUIRES LIVE BLOB CHECK
Independent final-head audit: MISSING
Ready evidence: INCOMPLETE
Merge evidence: INCOMPLETE
Security Go evidence: INCOMPLETE / DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```
