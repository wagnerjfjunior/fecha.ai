# FECH.AI — F1-02 / T1 — Gate 4 Exact-Set Closure Contract

**Status:** `PR_HEAD_ONLY / ACCEPTANCE_CONTRACT_FROZEN / G4_1_RETEST_REQUIRED`  
**Date:** `2026-08-22`  
**PR:** `#125 — security: harden corretor status command`  
**Environment:** `Pilot Production`  
**Execution:** `NO SUPABASE WRITE / NO MIGRATION APPLY / NO ROLLBACK / NO READY / NO MERGE / NO DEPLOY`

## 1. Why this contract exists

AppSec Gate 4 preserved `MULTI-TENANT`, `AUTHORIZATION`, `ACL`, `CONCURRENCY` and transactional atomicity as PASS. The only remaining blocker was exhaustive/exact-set proof for T1 rollback objects.

The earlier gate language used the word `exact` without defining an objective membership universe. That allowed the implementation and audit to use different meanings. This document freezes that meaning before the final remediation retest.

No already-passed forward-migration domain is reopened by this contract.

## 2. Live pre-T1 namespace evidence

READ_ONLY production catalog inspection on 2026-08-22 established:

```text
public functions matching:
  proname ^t1_
  OR marker F1-02-T1-v3|...
= 0

public non-internal triggers matching:
  tgname ^trg_t1_
  OR marker F1-02-T1-v3|...
= 0
```

Therefore the `t1_` / `trg_t1_` namespace and `F1-02-T1-v3` marker are available as an objective T1 ownership convention for this PR.

## 3. T1 OBJECT-SET CONTRACT v1 — FROZEN

### Function universe

A function belongs to the Gate 4.1 T1 universe when it is in schema `public` and satisfies at least one condition:

1. it is the exact signature `public.atualizar_status_corretor(uuid,boolean,boolean)` modified by T1; or
2. its function name starts with `t1_`; or
3. its `pg_proc` comment carries marker prefix `F1-02-T1-v3|`.

Expected pre-rollback set: exactly five objects:

```text
public.atualizar_status_corretor(uuid,boolean,boolean)
public.t1_is_root_strict()
public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)
public.t1_guard_corretores_authority_update()
public.t1_guard_corretores_direct_compat_update()
```

Both directions are required:

```text
EXPECTED - ACTUAL = empty
ACTUAL - EXPECTED = empty
```

### Trigger universe

A non-internal trigger belongs to the Gate 4.1 T1 universe when its relation is in schema `public` and at least one condition holds:

1. trigger name starts with `trg_t1_`; or
2. trigger comment carries marker prefix `F1-02-T1-v3|`; or
3. its `tgfoid` is one of the two T1 trigger functions.

Expected pre-rollback trigger set: exactly two objects, both on `public.corretores`:

```text
trg_t1_guard_corretores_authority_update
  -> public.t1_guard_corretores_authority_update()

trg_t1_guard_corretores_direct_compat_update
  -> public.t1_guard_corretores_direct_compat_update()
```

Both directions are required:

```text
EXPECTED - ACTUAL = empty
ACTUAL - EXPECTED = empty
```

### Post-rollback set

After rollback and before `COMMIT`:

```text
public function with name ^t1_ = none
public function with marker F1-02-T1-v3| = none
public trigger with name ^trg_t1_ = none
public trigger with marker F1-02-T1-v3| = none
public trigger bound to a T1 function = none
```

The restored `atualizar_status_corretor` is not a surviving T1 object when and only when the existing baseline checks prove its exact pre-T1 body/security/ACL and its T1 marker/comment is `NULL`.

## 4. Binary acceptance cases

The Gate 4.1 retest is limited to these cases:

```text
FUNCTIONS
5 expected / no extra                     -> PASS
4 expected                                -> FAIL
5 expected + t1_* overload                -> FAIL
5 expected + marker-bearing extra         -> FAIL

TRIGGERS
2 expected / no extra                     -> PASS
1 expected                                -> FAIL
2 expected + trg_t1_* extra               -> FAIL
2 expected + marker-bearing extra         -> FAIL
2 expected + alias trigger bound to T1 fn -> FAIL

POSTFLIGHT
any t1_* function                         -> FAIL
any T1-marker function                    -> FAIL
any trg_t1_* trigger                      -> FAIL
any T1-marker trigger                     -> FAIL
any trigger bound to T1 function          -> FAIL
empty T1 namespace                        -> PASS
```

## 5. Gate immutability rule

Gate 4.1 is a closure retest, not a new design review.

A new acceptance criterion may be introduced only if a new material fact is discovered that is independent of this frozen object-set contract and materially affects rollback safety.

Without such an event:

```text
new interpretation != new finding
broader hypothetical universe != blocker
already-passed forward domain != reopened
```

If the frozen cases pass, `G4-F1/G4-F2` are closed and the rollback static-assurance domain is eligible for PASS. Runtime application remains a separate production gate.

## 6. Current remediation

Canonical rollback path:

```text
supabase/rollback/20260822121500_f1_02_harden_status_corretor_rpc_rollback.sql
```

The current remediation implements the frozen universe symmetrically in preflight and postflight. The forward migration is intentionally unchanged from the Gate 3/Gate 4 audited blob.

## 7. Boundaries

```text
STATIC RETEST PASS != ROLLBACK EXECUTED
APPSEC PASS != READY AUTHORIZED
READY != MERGE
MERGED != SUPABASE APPLIED
SUPABASE APPLIED != RUNTIME VALIDATED
SECURITY GO = DENIED / UNCHANGED
```
