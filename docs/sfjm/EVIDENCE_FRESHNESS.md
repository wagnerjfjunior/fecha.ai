# FECH.AI — SFJM Evidence Freshness

**Status:** `CLAIM_ANCHOR_INVALIDATION_LEDGER / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-21`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness model

Evidence freshness is evaluated by:

```text
claim
object
anchor
environment
invalidation event
```

Do not infer freshness or staleness from `main` movement alone.

Versioned, merged, deployed, applied and runtime-tested states are distinct evidence classes.

## 2. Durable claims and anchors

### PR-01 narrow RPC

Claim:

```text
public.marcar_senha_inicial_definida() exists as the F1-02 narrow self-service password-state RPC contract.
```

Environment and migration anchor:

```text
Supabase project: uobxxgzshrmbtjfdolxd
Environment: production
Migration: 20260727080929 / f1_02_password_state_rpc / APPLIED
Evidence source: docs/security/evidence/2026-07-27-pr103-operational-closure-with-residual-risk.md
```

Durable evidence boundary recorded by the completed PR-01 cycle for that exact project/environment includes:

```text
no caller-selected target identifier
auth.uid() actor derivation
authenticated positive smoke established
immediate repeated-call idempotency established
```

This PR-01 evidence is scoped to `uobxxgzshrmbtjfdolxd / production`. It must not be carried to another Supabase project or environment without fresh validation of the applicable catalog/runtime claim.

Invalidate/revalidate the affected claim after a material RPC signature/body/owner/search_path/grant change, relevant Auth/RLS/policy/role change, project/environment replacement, contradictory runtime evidence or other security finding.

### PR-02 frontend cutover

Claim:

```text
the mandatory-password frontend cutover was implemented and merged with a static fail-closed contract.
```

Code anchor:

```text
src/App.jsx blob:
2541813e6af44f4e8112296b7d9666df9320db5d
```

Merge anchor:

```text
f4f77e2a159ec190173dc771b189909f589e9f91
```

Production deployment record:

```text
GitHub deployment id: 5701587582
environment: Production
status: success
```

Evidence boundary:

```text
IMPLEMENTED / MERGED / PRODUCTION DEPLOYMENT RECORDED
!=
POST-DEPLOY FUNCTIONAL PROOF COMPLETE
```

The deployment record proves a Production deployment event for the merge anchor. It does not prove the mandatory-password flow succeeded interactively or that runtime failure behavior was exercised.

Invalidate/revalidate the affected frontend claim after relevant code/dependency/workflow change, deployment of a different code object for the decision being made, contradictory runtime evidence or a new material security finding.

### PR-03 App.jsx bounded direct-write / call-site inventory

Claim:

```text
the current protected App.jsx source was freshly read in full and its direct-write call sites were inventoried as one bounded evidence component of the PR-03 eligibility question.
```

Code anchor:

```text
repository: wagnerjfjunior/fecha.ai
ref used for the audit: 51a15d5abdfb8ce62d5903272eb2855917a8d456
path: src/App.jsx
blob: 2541813e6af44f4e8112296b7d9666df9320db5d
size: 327255 bytes
lines: 5902
```

Retrieval/coverage anchor:

```text
fresh GitHub bounded line retrieval
continuous coverage: 1–5902
stable blob across accepted ranges: YES
post-EOF probe from line 5903: EMPTY
coverage: INTEGRAL_READ
```

Durable bounded result:

```text
App.jsx direct-write/call-site inventory: ESTABLISHED

active App.jsx direct PATCH paths confirmed in EditarCorretorModal:
1. public.corretores -> ativo, apto_para_receber
2. public.corretores -> must_change_password=false after administrative reset_password

repository-wide direct-write/call-site inventory:
NOT YET ESTABLISHED
```

Evidence record:

```text
docs/audits/architecture/2026-08-21-a1-a2-as-is-callsite-and-app-integral-read-baseline.md
```

This result is static/versioned and bounded to the recovered App.jsx plus the other explicitly inspected A1/A2 sources. It does not prove exhaustive repository-wide direct-write absence, current production grants/RLS behavior or implementation authority.

Invalidate/revalidate the App.jsx claim after a material `src/App.jsx` blob change, relevant administrative component/data-access path change, contradictory repository evidence or other material source change affecting the bounded inventory.

## 3. Remaining unestablished material claims

```text
post-deploy functional smoke: NOT ESTABLISHED
post-deploy runtime fail-closed evidence: NOT ESTABLISHED
refreshed repository-wide direct-write/call-site inventory confirming no required direct update remains: NOT ESTABLISHED
safe server-side disposition for EditarCorretorModal: NOT ESTABLISHED
cutover observation confirming no legitimate flow depends on direct UPDATE: NOT ESTABLISHED
controlled RPC inventory and individual continuity testing for direct-UPDATE revocation: NOT ESTABLISHED
```

The App.jsx inventory is no longer an evidence gap. The broader repository-wide predicate remains open until its source universe, enumeration/search method, coverage and limitations are explicitly established.

These remaining items are evidence/disposition gaps, not proof of failure beyond the bounded claim stated.

## 4. Historical provenance claims

Missing historical gate/authority provenance must be represented as:

```text
GATE_PROVENANCE_NOT_RECORDED
AUTHORITY_PROVENANCE_NOT_RECORDED
```

unless affirmative canonical evidence supports a stronger classification.

These provenance gaps do not invalidate later independently established lifecycle facts by themselves.

## 5. Invalidation rules

Material invalidation events include, within the affected scope:

```text
code/object change relevant to the claim
dependency or workflow change relevant to the claim
RPC contract/ACL/security-boundary change
environment/deployment change relevant to the claim
contradictory runtime evidence
new material security finding
material product/security decision changing acceptance
```

Not invalidation events by themselves:

```text
main SHA changes only
documentation-only closure merge
unrelated Builder documentation merge
new conversation
specialist change
request to repeat an unchanged gate
```

A documentation-only change that preserves an anchored code/runtime object does not invalidate that object's evidence merely because the repository tip advanced.

## 6. AUDIT_LOOP_BLOCKED

A request to repeat an existing validation must identify:

```text
nominal gate or claim
prior anchor
exact changed evidence
triggered invalidation rule
minimum required revalidation scope
```

Without a material invalidation event:

```text
AUDIT_LOOP_BLOCKED
```

## 7. Update rule

Update this ledger when a durable claim, anchor, environment boundary or invalidation condition changes materially.

Do not update it merely to keep a current `main` SHA, PR state or other volatile lifecycle snapshot synchronized.
