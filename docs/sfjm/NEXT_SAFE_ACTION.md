# FECH.AI — SFJM Next Safe Action

## 0.00000 Current semantic next action override — PR-07 implementation — 2026-09-02

Older B2/B4-next sections below are superseded and remain historical lineage only.

\`\`\`text
repository:
  wagnerjfjunior/fecha.ai

authoritative main at authorization:
  020594a2bb66fed5b6ab38f2d015878a7ef54d71

current active bounded task:
  F1-02 / J3 / PR-07
  security: harden funnel reads and CRM payloads

gates:
  LeadOps PASS
  Backend/Data PASS
  AppSec PASS WITH RESIDUAL RISK
  implementation design approved
  bounded implementation authorized by Product Authority

technical branch:
  security/f1-02-input-and-read-integrity

state at this reconciliation:
  branch created from exact authorized main
  no technical file published yet
  Draft PR not yet opened
\`\`\`

Single next safe action:

\`\`\`text
Implement ONLY:

1. supabase/migrations/20260902091600_f1_02_pr07_funnel_reads_crm_payloads.sql
2. supabase/rollback/20260902091600_f1_02_pr07_funnel_reads_crm_payloads_rollback.sql
3. supabase/tests/f1-02-pr07/funnel_reads_crm_payloads.sql

then:
  validate exact branch state
  open one Draft PR
  obtain Backend/Data exact-head review
  obtain independent AppSec exact-head review
  STOP before Ready
\`\`\`

Do not change:

\`\`\`text
src/App.jsx
Auth
Edge Functions
Vercel
Issue #133 implementation
Issue #135 implementation
Supabase live
production data
other migrations/files
\`\`\`

Not authorized:

\`\`\`text
Ready
merge
deploy
production migration application
rollback execution
hostile production testing
Security Go
broad paid commercialization
\`\`\`

Critical path after PR-07:

\`\`\`text
PR-08 -> PR-09 -> M2 -> M3 -> M4 -> M5 -> M6
\`\`\`

Bounded pre-Security-Go and planned backlogs remain parked in
\`docs/sfjm/CURRENT_STATE.md\`; they do not interrupt PR-07 unless a new material
finding proves they are class A / BLOCKS CURRENT TASK.

\`\`\`text
RUNTIME_NEGATIVE_PASS=NOT ESTABLISHED
SECURITY_GO=DENIED
\`\`\`


## 0.000 Current semantic next action override — 2026-09-01

The previously recorded "B2 next" action is consumed and superseded.

```text
repository: wagnerjfjunior/fecha.ai
post-merge main: fe83383971fe852e1fc91eada824253c818ef3e7
PR #159: CLOSED / MERGED
F1-02/B2: REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN

Supabase project:
  uobxxgzshrmbtjfdolxd / Discador-MesaCliente

migration:
  f1_02_b2_revoke_direct_crm_writes
  applied exactly once
  artifact blob: 1feea4ae8c2d368092331f217f8a8ba10d82cbcc

rollback:
  NOT EXECUTED
  artifact blob: 7ae92125c780276933a0bc091a6982c95c21b9ee

read-only proof:
  PASS
  artifact blob: 0f7e94ca9cde77868197c23950cc3f5c85fcbea9

post-application direct-write boundary:
  leads authenticated INSERT=false
  leads authenticated UPDATE=false
  lotes authenticated UPDATE=false
  times direct authenticated write remains absent

compatibility writers:
  11 reviewed writers preserved

gerenciar_lista:
  remains unavailable to authenticated / anon / PUBLIC

RUNTIME_NEGATIVE_PASS:
  NOT ESTABLISHED

SECURITY_GO:
  DENIED
```

The single current next action is:

```text
F1-02/B4 — LIST ACL CROSS-TENANT TARGET RISK / PR-06

TARGET DESIGN + AUTHORIZATION MATRIX FIRST

Architecture + AppSec + LeadOps
BEFORE ANY IMPLEMENTATION
```

No implementation, Supabase mutation, Ready, merge, deploy, runtime-negative
test or Security Go is authorized by this continuation record.


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
