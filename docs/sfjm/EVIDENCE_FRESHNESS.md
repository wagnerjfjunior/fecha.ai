# FECH.AI — SFJM Evidence Freshness

**Status:** `ACTIVE_FRESHNESS_RULES / PR_102_CORRECTED_DRAFT / FAIL_CLOSED`  
**Observed on:** `2026-07-25`

## 1. Purpose

Freshness determines whether evidence may support a current decision. Fresh evidence is not automatically sufficient.

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
| PR head/diff | exact live head and final files validated | commit, rebase, force-push or scope change |
| Mergeability/reviews/checks | live at exact head | base/head/review/check change |
| Canonical main | exact current tip | new main commit |
| Source file | exact blob/commit | file change |
| Supabase object state | read from exact project | migration/manual drift/config change |
| Negative test | exact backend/fixtures | relevant change or fixture drift |
| Runtime smoke | exact build/config/backend | deploy or backend/config change |
| Authorization | exact scope active | completion, expiration, revocation or scope change |
| Handoff | agrees with live evidence | material state/authority/decision change |

## 4. Canonical GitHub evidence

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
Classification: CURRENT at PR #102 correction preflight
```

## 5. PR #102 evidence

```text
PR: #102
State expected: OPEN / DRAFT
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Pre-correction head: fc83ed752217bfc39810dfba38e93405bc7382b8
Final corrective head: live PR metadata and updated PR description
Expected changed files after correction: 8 documentation files
Strategy canonicality: NOT_YET_CANONICAL
```

The final corrective commit cannot embed its own SHA. Freshness is established by live GitHub validation, not a recursive follow-up commit.

Any head or scope change invalidates the GPT0/GPT1/GPT3 re-audits.

## 6. Audit evidence

Authenticated independent audits at `fc83ed752217bfc39810dfba38e93405bc7382b8` are `CURRENT` only as evidence of findings against that pre-correction head.

They are not approval of the corrective head.

```text
GPT0: FAIL / correction required
GPT1: FAIL / correction required
GPT3: FAIL / correction required
```

The in-Project `TOOL STALE STATE` result is evidence of tool limitation only and has no content verdict.

## 7. Supabase evidence

The 2026-07-24 read-only inspection remains the last recorded database evidence.

```text
Project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Method: read-only metadata/definitions
Mutations: ZERO
Negative tests: ZERO
Post-remediation state: NOT_VERIFIED
```

Refresh affected objects after any migration, manual change, Auth/config change or source call-site change.

## 8. Validation evidence classes

- structural proof may be `CURRENT` for exact grants/policies/functions;
- designed tests are `NOT_VERIFIED` until executed;
- safe-live tests require exact synthetic manifest and authority;
- isolated tests require isolated-environment identity and parity evidence;
- deferred tests remain `NOT_VERIFIED`;
- prohibited tests never become evidence by execution on the primary project.

B1 actual global self-escalation denial remains `NOT_VERIFIED` without isolation.

## 9. Fixture freshness

A fixture record is current only with:

- versioned manifest;
- exact synthetic IDs and relations;
- proof of no links to real objects;
- pre/post counts;
- cleanup/deactivation result;
- owner and timestamp;
- no intervening relevant change.

No fixture evidence currently exists.

## 10. Authorization freshness

```text
Draft creation authority: CONSUMED
Correction authority: CONSUMED
Additional commit authority: NONE
Ready authority: NONE
Merge authority: NONE
PR-01 authority: NONE
Supabase authority: NONE
Admin-role-change authority: NONE
```

## 11. Fail-closed rule

When freshness cannot be established:

```text
classification = STALE or NOT_VERIFIED
approval/merge/deploy/security conclusion = BLOCKED
next action = refresh only the narrow evidence required
```
