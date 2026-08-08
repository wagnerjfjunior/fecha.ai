# FECH.AI — SFJM Evidence Freshness

**Status:** `CLAIM_ANCHOR_INVALIDATION_LEDGER / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-08`  
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

Durable evidence boundary recorded by the completed PR-01 cycle includes:

```text
no caller-selected target identifier
auth.uid() actor derivation
authenticated positive smoke established
immediate repeated-call idempotency established
```

Invalidate/revalidate the affected claim after a material RPC signature/body/owner/search_path/grant change, relevant Auth/RLS/policy/role change, contradictory runtime evidence or other security finding.

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

## 3. Remaining unestablished material claims

```text
post-deploy functional smoke: NOT ESTABLISHED
post-deploy runtime fail-closed evidence: NOT ESTABLISHED
current call-site inventory for PR-03 candidate: NOT CURRENTLY ESTABLISHED
safe server-side disposition for EditarCorretorModal: NOT ESTABLISHED
```

These are evidence gaps, not proof of failure.

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
