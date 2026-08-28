# FECH.AI — SFJM Blocked Actions

**Status:** `SECURITY_TO_SCALE_2026 / M0_RECONCILED / CURRENT_BLOCKERS / FAIL_CLOSED`
**Updated:** `2026-08-28`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is the thin blocker view. Principal state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve live lifecycle and exact heads before acting.

## 2. Product/security blocks

The following remain blocked:

```text
Security Go
broad paid commercialization
any claim that M0 equals live-database or runtime validation
any unbounded production/security testing
```

## 3. PR #139 — active implementation blocker

Observed exact head:

```text
32003e75a28e235fb454d39e3e4459d0f03acb2b
```

Live GitHub review-thread metadata establishes:

```text
6 review threads
6 isResolved=false
3 P1
3 P2
```

Therefore no approval, merge, deployment or Supabase-application conclusion may be inferred from `draft=false`, `mergeable=true`, preview/build success or historical specialist approvals on other heads.

A head change requires bounded revalidation of materially affected findings; it does not authorize a broad audit loop.

## 4. PR #140 — evidence provenance boundary

PR #140 remains `ACTIVE / DRAFT`.

```text
versioned OpenAPI/config/docs = STATIC / PR_HEAD_ONLY
runtime Action execution = must be independently evidenced
Builder application = separate state
```

Do not promote the PR description alone into current runtime proof.

## 5. Legacy continuity PRs

```text
#131 = STALE_CONTINUITY
#124 = STALE_CONTINUITY
#120 = SUPERSEDED
```

Their classification does not authorize closure, merge, rebase or deletion. Preserve historical evidence provenance until a separately authorized hygiene action.

## 6. PR #149 — M0 documentation publication

PR #149 is `ACTIVE / DOCUMENTATION_ONLY_DRAFT` and must remain Draft after exact-head validation.

Blocked without separate Product Authority authorization:

```text
Ready
merge
deploy
Supabase
runtime
closing old PRs
starting implementation work merely because the documentation PR exists
```

## 7. Lifecycle separation

```text
documentation reconciliation
!= exact-head validation
!= Ready
!= merge
!= deploy
!= Supabase application
!= runtime validation
!= Security Go
```

## 8. Removal rule

Remove a blocker only when the exact object/ref, material evidence, validator/gate, residual risk and next safe action are recorded. Mergeability or a green build alone never removes a security blocker.
