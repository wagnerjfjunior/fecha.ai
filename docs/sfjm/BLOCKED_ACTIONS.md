# FECH.AI — SFJM Blocked Actions

**Status:** `MATERIAL_BLOCKER_VIEW / T3A_V3_REPEAT_BACKEND_REVIEW_PENDING / FAIL_CLOSED / DOCUMENTATION_ONLY`
**Updated:** `2026-08-23`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin blocker view. Principal durable operational state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve live lifecycle before acting.

## 2. Product/security blocks

The following remain blocked unless material evidence and applicable Product Authority change their state:

```text
Security Go
broad paid commercialization
F1-02 final acceptance
T3A Ready
T3A merge
T3A Supabase production application
T3A Edge production deployment
T3A production adversarial/cross-tenant execution without exact runtime authority
T3B frontend password cutover before T3A backend is safely applied/deployed/validated
WDP increase without governance acceptance
```

## 3. Initial T3A blocker lineage and current gate

Do not create another T3A PR merely to address these blockers.

```text
B1 — unsafe rollout order in the initial candidate
B2 — incomplete trust-anchor preflight
B3 — rollback not sufficiently drift-safe
B4 — incompatibility with the live T1 direct-compatibility guard for gestor password-state transition
```

The Backend/Data exact-head review of `bf8fb1f...` returned `REQUEST_CHANGES`:
the DB lock did not span the later Auth side effect and the writer regex was not
transitive. The v3 candidate in the same PR replaces those mechanisms with a
durable authority lease/fence with snapshot-independent unique-index probes,
success-only exact release and a positive full
routine inventory used by migration and rollback. This changed head still has
no exact-head specialist PASS.

Current blocking gate:

```text
publish/resolve the new v3 corrective PR head
-> integral material-file read + coverage reconciliation
-> repeat Backend/Data exact-head review and obtain PASS
-> independent AppSec exact-head PASS
-> STOP before Ready pending separate Product Authority
```

Any material correction after either review invalidates both head-bound results
as applicable; do not open another T3A PR merely because the head advances.

## 4. Explicitly prohibited workaround classes

Do not resolve T3A by:

```text
disabling or bypassing T1 triggers
broadening authenticated UPDATE on public.corretores
restoring client authority over must_change_password
trusting client-provided empresa_id/role/flags/time/ownership
using service_role identity as a substitute for auth.uid() authorization
exposing T3 RPC to anon/PUBLIC/service_role
normalizing production users to fit the code
trial-and-error SQL in production
mixing unrelated user-creation redesign into password-reset hardening
using a frontend/server timeout as lease authority or automatic expiry
releasing an unresolved lease after an ambiguous Auth result
```

Any correction that makes the immediate test pass while weakening tenant isolation, authority derivation or rollback is `BLOCKING`, not an acceptable shortcut.

## 5. T1/T2 closed-cycle protection

Do not reopen T1/T2 as independent programs without a new material invalidation event.

Current T3A work may inspect/revalidate the minimum T1/T2 objects necessary for compatibility, including the live T1 guards and the current App password-reset callsite.

Do not:

```text
redo T2 status smoke merely for repetition
rewrite T1 status authority rules to make T3 easier
change App.jsx inside T3A
```

## 6. Lifecycle separation

The following remain distinct decisions:

```text
corrective GitHub commit
exact-head specialist PASS
Ready
merge
Supabase migration application
Edge deployment
runtime smoke
rollback execution
Security Go
```

One does not imply the next.

## 7. Removal rule

Remove a blocker only when the record identifies:

```text
exact corrected object/ref
material evidence
validator/gate
residual risk
rollback/containment
new semantic next action
```

A green build or mergeability result alone does not remove a security blocker.
