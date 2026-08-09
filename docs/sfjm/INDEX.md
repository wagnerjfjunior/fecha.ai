# FECH.AI — SFJM Operational Continuity Index

**Status:** `OPERATIONAL_CONTINUITY_V2 / MATERIAL_STATE_AUTHORITY / LIVE_LIFECYCLE_RESOLUTION / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-08`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Purpose

SFJM is the transversal continuity layer for FECH.AI. It preserves durable operational meaning between conversations, specialists, audits and execution cycles without copying volatile GitHub lifecycle into multiple Markdown authorities.

SFJM is not a product feature, security boundary, business authority or substitute for GitHub, Supabase, Vercel, runtime evidence, the B0 governance baseline or specialist validation.

## 2. Core state separation

The normative model is:

```text
LIVE_RESOLVED_STATE
!=
MATERIAL_RECORDED_STATE
```

### 2.1 LIVE_RESOLVED_STATE

Resolve live before any sensitive action. This class includes facts that can change without a material product/security decision:

```text
current main SHA
PR Open/Closed
Draft/Ready
base/head SHA
checks
reviews
threads
mergeability
workflow state
current deployment state
```

GitHub is authoritative for GitHub lifecycle. Supabase/Vercel/runtime evidence is authoritative for the applied environment within its own scope.

A Markdown snapshot of these facts is never sufficient current truth.

### 2.2 MATERIAL_RECORDED_STATE

`docs/sfjm/CURRENT_STATE.md` is the principal authority for durable product/security operational meaning, including:

```text
current objective
material decisions
active/resolved problems
residual risks
material blockers
conditions to proceed
program state
relevant durable evidence boundaries
semantic next action
architecture/security constraints
```

Material state is expected to remain valid across ordinary commits, merges and lifecycle transitions when those events do not change its meaning.

## 3. Authority map

```text
docs/sfjm/INDEX.md
→ protocol and authority model

docs/sfjm/CURRENT_STATE.md
→ principal MATERIAL_RECORDED_STATE authority

docs/sfjm/AUTHORIZATIONS.md
→ durable authority/provenance ledger

docs/sfjm/EVIDENCE_FRESHNESS.md
→ evidence claim/anchor/invalidation ledger

docs/sfjm/NEXT_SAFE_ACTION.md
→ thin semantic view; must not own volatile lifecycle

docs/sfjm/BLOCKED_ACTIONS.md
→ thin material-blocker view; must not own volatile lifecycle

docs/sfjm/handoffs/CURRENT.md
→ thin product/security handoff pointer

docs/sfjm/handoffs/BUILDERS_CURRENT.md
→ separate specialist-Builder continuity; not modified by product/security reconciliation
```

Consumers must not create a second current-state authority by copying the same lifecycle snapshot into multiple files.

## 4. Mandatory reconstruction order

Before sensitive FECH.AI work:

1. resolve `main` live;
2. read `docs/bootstrap/INDEX.md`;
3. resolve the canonical specialist skill through `docs/skills/fechai-gpt-registry.md` when a specialist is involved;
4. read the common Modus Operandi;
5. read governance when applicable;
6. read this index;
7. read `CURRENT_STATE.md`;
8. read the thin blocker/action/authority/evidence/handoff views required by the decision;
9. resolve every live GitHub/environment object material to the next action;
10. reconcile `LIVE_RESOLVED_STATE + MATERIAL_RECORDED_STATE` before acting.

If live state and recorded material meaning conflict, declare the conflict and preserve the more restrictive safe interpretation until resolved.

## 5. Material update rule

Update product/security SFJM only when evidence or a decision materially changes one or more of:

```text
program/objective state
material risk or blocker
condition to proceed
security/product decision
material authorization
relevant evidence validity
semantic next action
handoff ownership/transition meaning
```

The following are not material-update triggers by themselves:

```text
main SHA changes only
PR Draft/Ready transition only
PR Open/Closed transition only without material effect
documentation-only closure merge
unrelated specialist-Builder documentation merge
new conversation
specialist change
request to repeat an unchanged exact-head gate
```

A lifecycle event can be material when it changes the actual program condition. Example: integration or deployment of a required product change may satisfy a material dependency. Record the semantic consequence, not a frozen lifecycle snapshot.

## 6. NO_RECURSIVE_LIFECYCLE_RECONCILIATION

```text
NO_RECURSIVE_LIFECYCLE_RECONCILIATION
```

A bounded documentation-only closure is self-closing when its merge changes only publication/lifecycle and introduces no new material product/security state.

After such a merge:

```text
resolve new main live
compare material meaning
if no material change:
    no SFJM reconciliation PR
```

Never open another PR solely to record that the previous continuity PR merged, that `main` advanced, or that a Draft became Ready/merged.

## 7. NO_RETROACTIVE_GATE_REPLAY

```text
NO_RETROACTIVE_GATE_REPLAY
```

When later lifecycle is independently established live, missing historical documentation for a prior gate or authority must be classified, as applicable, as:

```text
GATE_PROVENANCE_NOT_RECORDED
AUTHORITY_PROVENANCE_NOT_RECORDED
```

These classifications do not mean:

```text
GATE_FAILED
UNAUTHORIZED
```

Before replaying any historical gate, ask whether the provenance gap changes a current safety decision.

If no, record the historical gap and continue without replay.

If yes, perform only the smallest present-time validation required to restore a safe decision. Do not automatically reconstruct the full historical pipeline.

## 8. Evidence and coverage

All material sources remain subject to the common evidence contract:

```text
NOT_READ
PARTIAL_READ
INTEGRAL_READ
```

Versioned, merged, deployed, applied and runtime-tested states are distinct. Tool capability is not authority.

## 9. Change discipline

```text
one PR = one primary risk = one simple rollback
```

An SFJM documentation change must not silently expand into frontend, Supabase, Auth, RLS, RPC, migration, Vercel, GitHub Actions, Builders, integrations, production or data changes.

## 10. Anti-loop acceptance matrix

```text
main SHA changes only
→ NO SFJM material update

documentation-only closure merge
→ NO SFJM material update

Draft/Ready lifecycle transition only
→ NO SFJM material update

unrelated Builder documentation merge
→ NO product/security SFJM material update

material product/security decision or evidence change
→ SFJM material update
```

Critical acceptance test:

```text
structural continuity PR merges
→ main changes
→ no new material product/security event
→ new conversation resolves main live
→ reads MATERIAL_RECORDED_STATE
→ continues normally
→ NO follow-up reconciliation PR required
```
