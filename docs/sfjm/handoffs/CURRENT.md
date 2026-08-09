# FECH.AI — SFJM Current Product/Security Handoff

**Status:** `THIN_HANDOFF_POINTER / MATERIAL_STATE_FIRST / LIVE_LIFECYCLE_RESOLUTION`  
**Updated:** `2026-08-08`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Purpose

This file is a thin product/security continuity pointer. It must not duplicate the current material state, GitHub lifecycle, authorization ledger or evidence-freshness ledger.

## 2. Read these authorities

Material current state:

```text
docs/sfjm/CURRENT_STATE.md
```

Semantic next action:

```text
docs/sfjm/NEXT_SAFE_ACTION.md
```

Material blockers:

```text
docs/sfjm/BLOCKED_ACTIONS.md
```

Authority/provenance:

```text
docs/sfjm/AUTHORIZATIONS.md
```

Evidence validity/invalidation:

```text
docs/sfjm/EVIDENCE_FRESHNESS.md
```

SFJM protocol and authority map:

```text
docs/sfjm/INDEX.md
```

## 3. Live lifecycle rule

```text
GitHub lifecycle → RESOLVE LIVE BEFORE ACTING
```

Do not rely on this handoff for:

```text
current main SHA
PR Open/Closed
Draft/Ready
current head/base
checks
reviews
threads
mergeability
workflow status
current deployment status
```

Resolve those objects live and combine them with `MATERIAL_RECORDED_STATE` before any sensitive action.

## 4. Builder separation

Specialist Builder continuity remains separate:

```text
docs/sfjm/handoffs/BUILDERS_CURRENT.md
```

This product/security handoff must not silently overwrite Builder continuity, and Builder documentation movement must not force a product/security SFJM update without a material product/security event.

## 5. No recursive closure

A future documentation-only continuity merge that changes no material product/security meaning is self-closing.

```text
merge
→ resolve new main live
→ compare material meaning
→ if unchanged: continue
→ NO follow-up PR merely to record the merge
```

## 6. Handoff acceptance

A new conversation must be able to:

```text
resolve main live
read bootstrap
read SFJM protocol
read CURRENT_STATE
resolve any live object needed for the next decision
continue without stale continuity caused only by a newer SHA
```

If a handoff requires rewriting this file merely because GitHub lifecycle advanced, the handoff design has regressed.
