# FECH.AI — SFJM Blocked Actions

**Status:** `MATERIAL_BLOCKER_VIEW / FAIL_CLOSED / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-08`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This file is a thin material-blocker view. The principal durable operational state is:

```text
docs/sfjm/CURRENT_STATE.md
```

Do not use this file as a frozen GitHub lifecycle snapshot.

## 2. Product and security blocks

The following remain blocked unless exact material evidence and authority change their state:

```text
Security Go
F1-02 acceptance
broad paid commercialization
WDP increase without verified governance acceptance
PR-03 implementation before material eligibility
administrative password-state redesign without separate server-side contract
```

Controlled beta does not waive security, isolation, privacy or LGPD requirements.

## 3. PR-03 material predicates

PR-03 remains blocked while one or more of these predicates is true:

```text
post-deploy functional proof is incomplete
post-deploy runtime fail-closed proof is incomplete
current direct-write/call-site inventory is not refreshed for the revocation candidate
EditarCorretorModal lacks a safe server-side disposition
```

Do not require legacy direct UPDATE denial as a circular precondition for creating the PR whose purpose is to revoke that direct UPDATE. Denial is acceptance evidence after the revocation change exists and is applied under separate authority.

## 4. Closed-cycle protection

Without a new material invalidation event, do not:

```text
reopen completed PR-01 work
reopen PR-02 / PR #108 merely to recover historical paperwork
repeat exact-head gates merely for unanimity
reapply or modify the narrow password-state RPC as part of continuity work
create a closure PR solely to record another closure merge
```

Historical missing provenance must be handled under `NO_RETROACTIVE_GATE_REPLAY`.

## 5. Scope blocks for SFJM continuity work

SFJM documentation work does not authorize changes to:

```text
frontend/runtime
Supabase
migrations
RPC bodies
Auth
RLS
policies
grants
roles
data
Edge Functions
Vercel configuration
GitHub Actions
Builders
production
PR-03 implementation
EditarCorretorModal implementation
```

## 6. Live lifecycle is not a material blocker by itself

Do not persist blockers such as:

```text
PR is Draft
main SHA is X
head is Y
mergeability is Z
```

as durable blocker truth.

Resolve lifecycle live. Record only the semantic consequence when it changes a material decision.

## 7. Removal rule

Remove a material blocker only when evidence identifies, as applicable:

```text
claim resolved
object/environment validated
material authority
validator/evidence
residual risk
rollback or containment
new semantic next action
```

A lifecycle transition alone does not remove a semantic security blocker unless it actually satisfies the blocker condition.
