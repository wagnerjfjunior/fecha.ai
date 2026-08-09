# FECH.AI — SFJM Authorizations

**Status:** `AUTHORITY_PROVENANCE_LEDGER / FAIL_CLOSED / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-08`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, object, operation, scope, prohibitions and lifecycle transition granted by Product Authority.

Tool capability is not authorization.

This ledger does not use stale GitHub lifecycle as proof that an action was or was not authorized.

## 2. Authority classes

Use only these durable classes:

```text
ACTIVE_AUTHORITY
CONSUMED_AUTHORITY
AUTHORITY_PROVENANCE_NOT_RECORDED
```

Interpretation:

```text
ACTIVE_AUTHORITY
→ explicit authority exists and remains available for its exact bounded operation.

CONSUMED_AUTHORITY
→ explicit authority was used for its bounded operation; recording it does not reactivate it.

AUTHORITY_PROVENANCE_NOT_RECORDED
→ later state exists, but the exact historical authority artifact was not recovered in canonical evidence.
```

`AUTHORITY_PROVENANCE_NOT_RECORDED` must not be rewritten as `UNAUTHORIZED` without affirmative evidence.

## 3. Current bounded SFJM structural authority

Product Authority explicitly authorized on `2026-08-08` one bounded documentation-only structural remediation with primary risk:

```text
eliminate recursive lifecycle reconciliation
```

Exact authorized files:

```text
docs/sfjm/INDEX.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/handoffs/CURRENT.md
```

Authorized operations:

```text
revalidate main live
create one dedicated branch
edit only the seven approved files
create the necessary bounded documentation commit(s)
perform applicable read-only validation
publish one Draft PR
record objective, risk, refs, scope, acceptance criteria, evidence, residual risk, rollback and next gate in that PR
```

Explicitly not authorized by that grant:

```text
Ready
merge
auto-merge
deploy
Supabase mutation
runtime smoke
production mutation
Builder mutation
PR-03
changes outside the seven files
Security Go
F1-02 acceptance
WDP change
```

The authority becomes `CONSUMED_AUTHORITY` when the one authorized Draft PR is successfully published. That consumption is resolved from the live execution record and must not trigger a follow-up documentation PR solely to rewrite this paragraph.

## 4. Historical F1-02 authority provenance

Where later lifecycle is established but exact historical authority evidence for a prior transition is not canonically recovered, classify the gap as:

```text
AUTHORITY_PROVENANCE_NOT_RECORDED
```

This applies only as a provenance classification. It does not reopen completed work and does not imply that the transition was unauthorized.

## 5. No retrospective gate replay

```text
UNKNOWN != REEXECUTE
AUTHORITY_PROVENANCE_NOT_RECORDED != UNAUTHORIZED
GATE_PROVENANCE_NOT_RECORDED != GATE_FAILED
```

Before recovering or replaying historical authority/gate evidence, determine whether the provenance gap affects a current safety decision.

If not material now, preserve the gap as historical and continue.

If material now, recover only the minimum evidence required for the present decision.

## 6. Future mutation rule

Any new mutation requires exact current Product Authority for the operation unless an already recorded `ACTIVE_AUTHORITY` unambiguously covers it.

Authority for one lifecycle transition does not authorize the next.

Examples that require separate authority when applicable:

```text
Ready
merge
deploy
production smoke
Supabase change
administrative password-flow replacement
PR-03
Security Go
F1-02 acceptance
WDP change
```

## 7. Update rule

Update this ledger when durable authority meaning changes materially.

Do not update merely because:

```text
main SHA changed
a PR changed Draft/Ready/Open/Closed
a documentation-only closure merged
an unrelated Builder document merged
```

Resolve those lifecycle facts live.
