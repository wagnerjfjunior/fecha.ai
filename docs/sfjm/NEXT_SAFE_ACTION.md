# FECH.AI — SFJM Next Safe Action

**Status:** `SECURITY_TO_SCALE_2026 / M1_ACTIVE / READ_ONLY_SECURITY_TRUTH_BASELINE`
**Updated:** `2026-08-28`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is the thin semantic continuation view. Principal state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve GitHub and environment state live before acting. Tool capability is not authorization.

## 2. Single current semantic next action

```text
Execute M1-A READ_ONLY Security Truth Baseline:
LIVE DB x GitHub main x applied migration ledger cross-check,
including the current privileged-surface inventory required to establish
what is actually applied before any simplification or new implementation decision.
```

Primary specialist sequence:

```text
1. backend_data -> backend-data-platform-specialist
   establish current live data/platform truth read-only
2. application_security -> application-security-assurance-specialist
   independently assess the proven privileged/tenant/security surface
3. documentation_audit -> documentation-auditor
   reconcile evidence classes, gaps and final M1 current-state map
```

Manual specialist transport remains acceptable when the SES runtime path is unavailable. Never invent a Gateway receipt.

## 3. M1 scope boundaries

Required M1 outputs are tracked by Issue #150:

```text
LIVE DB x GitHub main x applied migration ledger cross-check
privileged-surface inventory
tenant-isolation proof plan / staging-runtime requirements
dependency / known-vulnerability inventory
secrets / infrastructure attack-surface inventory
one final M1 verdict + one NEXT_SAFE_ACTION
```

Explicitly prohibited during M1 evidence acquisition:

```text
DDL/DML
migration application
Supabase mutation
production offensive testing
Auth/business-data mutation
deploy
Security Go claim
database simplification implementation
automatic merge/closure of #139 or #140
```

## 4. Anti-loop

M0 is closed. Do not reopen M0 without a material invalidation event.

Within M1, re-query evidence only when required to close a defined gap or after an invalidation event.

```text
unchanged evidence + repeated broad audit = AUDIT_LOOP_BLOCKED
```

## 5. Update rule

Update this file only when the unique safe continuation changes materially.
