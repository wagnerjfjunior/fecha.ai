# FECH.AI — SFJM Next Safe Action

**Status:** `SECURITY_TO_SCALE_2026 / F1_02_B3_REMEDIATED / B2_DIRECT_CRM_WRITES_NEXT`
**Updated:** `2026-09-01`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is the thin semantic continuation view. Principal durable state remains:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve live GitHub and environment state again before any sensitive action.

## 2. Current closed slice

```text
F1-02/B3:
  REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN

PR #157:
  CLOSED / MERGED

merge/main anchor:
  035f57e29d64c0cca26048a925a790459bd9976c

Supabase application:
  SUCCESS / one authorized invocation

post-application AppSec:
  PASS

RUNTIME_NEGATIVE_PASS:
  NOT ESTABLISHED

Security Go:
  DENIED
```

Do not reopen B3 merely because runtime-negative testing remains unexecuted.
That residual is explicitly preserved and is not a prerequisite for the bounded
catalog-remediation PASS.

## 3. Single current semantic next action

```text
F1-02/B2 — EXCESSIVE DIRECT CRM WRITES

TARGET DESIGN / CALL-SITE + LIVE CONTRACT RECONSTRUCTION FIRST
```

Fresh bounded live evidence established that the exposure still exists:

```text
public.leads:
  authenticated INSERT=true
  authenticated UPDATE=true
  authenticated DELETE=false

public.lotes:
  authenticated INSERT=false
  authenticated UPDATE=true
  authenticated DELETE=false
```

Before any revoke or migration proposal:

1. resolve live `main`;
2. reconstruct exact frontend/backend/RPC callers for `public.leads` and
   `public.lotes`;
3. reconstruct the current table/RLS/grant/policy/column-ACL contract;
4. identify which direct writes are actually required by live product flows;
5. map controlled RPC alternatives and tenant/ownership invariants;
6. obtain Backend/Data target-design review;
7. obtain independent AppSec review;
8. only then request a separate exact Product Authority implementation grant.

## 4. Explicit prohibitions under this continuity action

```text
NO DDL/DML
NO migration application
NO Supabase mutation
NO Auth mutation
NO runtime-negative production test
NO rollback
NO Security Go
NO broad paid commercialization
NO reopening F1-02/B3
NO closing Issue #141
```

## 5. Issue state

```text
Issue #141 — Security-to-Scale 2026: OPEN
Issue #150 — Security Truth Baseline: CLOSED / completed
```

F1-02 final acceptance remains separate and is not granted by B3 closure.
