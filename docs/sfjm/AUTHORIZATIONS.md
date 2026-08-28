# FECH.AI — SFJM Authorizations

**Status:** `AUTHORITY_PROVENANCE_LEDGER / PR130_MERGE_CONSUMED / T3A_PRODUCTION_APPLY_CONSUMED / BOUNDED_RUNTIME_SMOKE_PARTIALLY_CONSUMED / ROLLBACK_NOT_EXECUTED / SECURITY_GO_NOT_EXERCISABLE`
**Updated:** `2026-08-26`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, object, operation, scope, prohibitions and lifecycle transition granted by Product Authority.

```text
TOOL_CAPABILITY != AUTHORIZATION
ONE TRANSITION AUTHORITY != NEXT TRANSITION AUTHORITY
CONDITIONAL AUTHORITY != AUTOMATIC EXECUTION
```

Use durable classes:

```text
ACTIVE_AUTHORITY
CONSUMED_AUTHORITY
NOT_EXERCISED
AUTHORITY_PROVENANCE_NOT_RECORDED
```

## 2. Current Product Authority context re-supplied on 2026-08-26

The Product Authority re-supplied the prior instruction in the current conversation:

```text
merge authorized if everything is correct
Supabase production authorized if everything is correct
Edge deploy authorized if everything is correct
runtime smoke authorized if everything is correct
rollback authorized if everything is correct
Security Go authorized if everything is correct
```

This is conditional authority. Every gate remains fail-closed and transition-specific.

## 3. CONSUMED_AUTHORITY — PR #130 merge

PR #130:

```text
head: fd997b6fa552f9423f7a019af58483b2b1a837f1
merge commit: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
```

The merge authority is consumed by the completed merge. It does not authorize a new T3B merge or any unrelated PR.

## 4. CONSUMED_AUTHORITY — T3A Supabase production application

The exact reviewed migration was applied successfully once to production.

```text
project: uobxxgzshrmbtjfdolxd
migration history: 20260826021346_t3_admin_password_reset_boundary
result: COMMITTED
```

This application authority is consumed.

```text
NO AUTOMATIC REAPPLY
```

A later migration or rollback is a distinct production operation even if it belongs to the same broader program.

## 5. NOT_EXERCISED — Edge redeploy after PR #130

Production `criar-usuario` is already:

```text
version: 19
status: ACTIVE
ezbr_sha256: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
```

No Edge byte changed in PR #130 and no redeploy was required after the successful T3A migration.

The conditional Edge-deploy authority was therefore not exercised. It must not be used to redeploy identical bytes merely for repetition.

## 6. BOUNDED runtime-smoke authority and consumption

Runtime evidence now includes:

```text
one controlled nonexistent-target denial
one authorized same-company positive reset lineage
one separate clean same-company positive reset with one client POST / HTTP 200
```

The clean second target receipt supplied by Product Authority explicitly records:

```text
CALL_COUNT=1
RETRY_AUTOMATICO=DESABILITADO
TOKEN_OUTPUT=NAO
LOGIN_PASSWORD_OUTPUT=NAO
NEW_PASSWORD_OUTPUT=NAO
```

No further automatic reset or retry is authorized by the existence of these prior smoke permissions.

A new cross-company adversarial production smoke must still be target-bound, non-destructive and independently safe before execution.

## 7. NOT_EXERCISED — rollback

Rollback authority was stated conditionally, but rollback was not executed because T3A reached a successful committed production state with zero residual proof/lease rows at reconciliation.

Do not execute rollback merely to demonstrate that a rollback file exists.

Any production rollback test must first establish:

```text
exact current production anchor
safe rollback target
expected user/runtime impact
reapply/forward recovery path
zero active leases/unexpired proofs
post-rollback validation
explicit decision that the proof value justifies the production disruption
```

Until then:

```text
ROLLBACK_AUTHORITY: NOT EXERCISABLE FOR A DEMONSTRATION-ONLY RUN
```

## 8. Security Go authority is conditional and currently non-exercisable

Product Authority stated that Security Go is authorized if everything is correct.

The condition is not yet satisfied.

Missing material proof includes:

```text
T3B frontend cutover deployed/runtime-proven
cross-company adversarial runtime denial
rollback/recovery proof acceptable to the final F1-02 gate
final F1-02 acceptance decision
```

Therefore:

```text
SECURITY_GO_AUTHORITY: CONDITIONAL
SECURITY_GO_EXECUTION: BLOCKED BY PRECONDITIONS
SECURITY_GO: DENIED
```

## 9. Current documentation-only reconciliation authority

The current conversation explicitly states that the previous session stopped before SFJM was updated and requests continuation with the supplied final context.

Durable bounded interpretation:

```text
Repository: wagnerjfjunior/fecha.ai
Base: live main 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
Authorized now:
  reconcile the material T3A runtime state in SFJM/evidence
  create a documentation-only branch
  create one Draft PR
Not implied:
  T3B implementation
  Ready
  merge of the new documentation PR
  production mutation
  new runtime reset
  rollback
  Security Go
```

## 10. Stale PR #124

PR #124 remains open/draft on a superseded base and overlaps SFJM files.

No current authority was supplied to close, rebase, rewrite or merge PR #124.

Therefore:

```text
PR124_LIFECYCLE_MUTATION: NOT_AUTHORIZED
```

Treat it as stale continuity and leave it untouched until Product Authority decides its lifecycle.

## 11. Update rule

Update this ledger only when durable authority meaning changes.

Do not update merely because a SHA, Draft/Ready state, check or mergeability value changes.
