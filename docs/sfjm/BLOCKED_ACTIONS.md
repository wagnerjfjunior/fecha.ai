# FECH.AI — SFJM Blocked Actions

**Status:** `MATERIAL_BLOCKER_VIEW / T3A_APPLIED / BOUNDED_RUNTIME_PASS / T3B_REQUIRED / SECURITY_GO_DENIED`
**Updated:** `2026-08-26`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin blocker view. Principal durable operational state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve live lifecycle before acting.

## 2. Closed T3A blockers

The following prior blockers are closed for the reviewed/applied T3A bytes:

```text
PR #130 exact-head Backend/Data review
PR #130 independent AppSec review
PR #130 merge
routine-anchor drift correction
T3A production migration application
post-application catalog existence/postflight
bounded nonexistent-target denial
bounded same-company authorized positive reset
second clean same-company positive reset
```

These closures do not imply Security Go.

## 3. Current product/security blocks

```text
Security Go
F1-02 final acceptance
broad paid commercialization
T3B frontend password-reset cutover Ready/merge/deploy until implemented and reviewed
cross-company adversarial runtime claim until actually executed with a safe bounded target
rollback-runtime claim until actually proven in an appropriate safe environment/plan
recovery-path claim for ambiguous Auth/release outcomes until tested/validated
WDP increase without governance acceptance
```

## 4. Explicitly blocked redundant actions

```text
reapply T3A migration merely to reconfirm success
redeploy Edge v19 when bytes/runtime are unchanged
repeat password resets on already-proven targets merely for reassurance
restore authenticated UPDATE(must_change_password)
weaken T1/T3 guards to make the frontend PATCH succeed
run production rollback merely as a demonstration without a safe rollback/reapply plan
```

The current UI error must be fixed by removing the stale frontend protected-field write, not by restoring client authority.

## 5. T3B current blocker

Current App flow after successful Edge reset:

```text
HTTP 200 / ok=true
-> stale direct PATCH corretores.must_change_password=false
-> authenticated UPDATE privilege on must_change_password = false
-> PATCH fails
-> UI reports error after successful Auth mutation
```

Required correction class:

```text
frontend-only T3B cutover
```

No Supabase migration or Edge change belongs to this correction unless a new material finding proves otherwise.

## 6. Stale continuity blocker — PR #124

PR #124 remains `OPEN / DRAFT`, is based on old main `827f8591...`, is `mergeable=false`, and edits overlapping SFJM files for an earlier PR-03 state.

```text
PR #124 merge: BLOCKED AS STALE_CONTINUITY
PR #124 reuse for T3B: BLOCKED
```

Do not close, rebase or rewrite it without separate lifecycle authority. Its historical evidence remains historical.

## 7. Lifecycle separation

The following remain distinct decisions:

```text
T3B implementation
T3B exact-head review
T3B Ready
T3B merge
T3B deploy
T3B runtime smoke
cross-company adversarial smoke
rollback/recovery proof
F1-02 final acceptance
Security Go
```

One does not imply the next.

## 8. Removal rule

Remove a blocker only when the record identifies:

```text
exact corrected object/ref
material evidence
validator/gate
residual risk
rollback/containment
new semantic next action
```

A successful build, mergeability result or same-company positive reset alone does not remove the remaining Security Go blockers.
