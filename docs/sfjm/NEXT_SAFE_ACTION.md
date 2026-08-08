# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-08`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This file is a thin semantic view. It is not a second current-state authority.

Principal material state:

```text
docs/sfjm/CURRENT_STATE.md
```

Before any sensitive action, resolve GitHub/environment lifecycle live as required by:

```text
docs/sfjm/INDEX.md
```

## 2. Current semantic next action

```text
Resolve the smallest remaining evidence set required to determine PR-03 eligibility.
```

The current material evidence needs are defined in `CURRENT_STATE.md` and include:

```text
post-deploy functional smoke
post-deploy runtime fail-closed evidence
refreshed current call-site inventory
safe server-side disposition for EditarCorretorModal
```

This statement is semantic. It does not authorize any runtime test, Supabase mutation, implementation, Ready, merge, deployment or production action.

## 3. No frozen lifecycle routing

This file must not encode a durable instruction such as:

```text
run GPT-X on PR-Y at head-Z
```

when that instruction depends only on volatile lifecycle state.

Exact PR/head/check/review/deployment facts must be resolved live at execution time.

## 4. No retrospective replay

Historical provenance gaps do not automatically become the next action.

```text
UNKNOWN != REEXECUTE
GATE_PROVENANCE_NOT_RECORDED != GATE_FAILED
AUTHORITY_PROVENANCE_NOT_RECORDED != UNAUTHORIZED
```

Replay a prior gate only when its missing provenance materially affects a current safety decision, and then perform only the minimum present-time validation required.

## 5. Update rule

Update this file only when the semantic next action changes materially.

Do not update it for:

```text
main SHA change only
Draft/Ready transition only
documentation-only closure merge
unrelated Builder documentation merge
new conversation or specialist
```
