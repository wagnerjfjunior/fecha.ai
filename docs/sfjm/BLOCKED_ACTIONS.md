# FECH.AI — SFJM Blocked Actions

**Status:** `SECURITY_TO_SCALE_2026 / M1_ACTIVE / READ_ONLY_BASELINE / FAIL_CLOSED`
**Updated:** `2026-08-28`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin blocker view. Principal state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve volatile GitHub/environment facts live before acting.

## 2. Product/security blocks

The following remain blocked:

```text
Security Go
broad paid commercialization
F1-02 final acceptance
WDP increase without governance acceptance
any claim that M1 static evidence equals current live DB/runtime proof
any unbounded production/security testing
```

## 3. M1 mutation blocks

M1 evidence acquisition is READ_ONLY FIRST. Until a later explicitly authorized implementation wave:

```text
DDL / DML
migration application
Supabase mutation
Auth/user/business-data mutation
Edge/Vercel deploy
production offensive/adversarial mutation tests
database simplification implementation
privilege/RLS/policy/grant changes
secret/config mutation
Security Go
```

## 4. Active PR workstreams

```text
#139 ACTIVE
  resolve current head/reviews/threads/checks live
  material findings affecting the current head must be closed/revalidated
  M1 does not authorize #139 lifecycle advancement

#140 ACTIVE
  static versioned config does not prove runtime Action/Builder state
  M1 may use independently proven read-only capability evidence
  M1 does not authorize #140 lifecycle advancement
```

Legacy continuity classification remains:

```text
#131 STALE_CONTINUITY
#124 STALE_CONTINUITY
#120 SUPERSEDED
```

Their classification does not authorize closure, merge, rebase or deletion.

## 5. Evidence/lifecycle separation

```text
STATIC != LIVE != RUNTIME
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
MERGEABLE != APPROVED
LIVE_DATABASE_VALIDATED != SECURITY_GO
```

## 6. Removal rule

Remove a blocker only when the record identifies the exact object/ref, material evidence, validator/gate, residual risk, rollback/containment where relevant and the new semantic next action.
