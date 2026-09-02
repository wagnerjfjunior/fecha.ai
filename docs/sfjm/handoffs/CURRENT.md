# FECH.AI — SFJM Current Product/Security Handoff

## 0.00000 Current handoff override — B4 closed / PR-07 implementation active — 2026-09-02

This is the current handoff authority when older B2/B4-next sections below conflict.

\`\`\`text
repository:
  wagnerjfjunior/fecha.ai

main:
  020594a2bb66fed5b6ab38f2d015878a7ef54d71

environment:
  Pilot Production / multi-tenant / multiempresa

Program #141:
  OPEN

Security Go:
  DENIED

broad paid commercialization:
  BLOCKED
\`\`\`

Closed current slice:

\`\`\`text
F1-02/B4 / PR-06:
  REMEDIATED
  MERGED
  APPLIED
  READ_ONLY_CATALOG_PROVEN
  RUNTIME_NEGATIVE_PASS=NOT ESTABLISHED
\`\`\`

Current active slice:

\`\`\`text
F1-02 / J3 / PR-07
security: harden funnel reads and CRM payloads

LeadOps:
  PASS

Backend/Data:
  PASS

AppSec:
  PASS WITH RESIDUAL RISK

bounded implementation:
  AUTHORIZED

technical branch:
  security/f1-02-input-and-read-integrity
  created from exact main 020594a2bb66fed5b6ab38f2d015878a7ef54d71

technical files:
  not yet published at this reconciliation

Draft PR:
  not yet opened
\`\`\`

Exact allowed technical files:

\`\`\`text
supabase/migrations/20260902091600_f1_02_pr07_funnel_reads_crm_payloads.sql
supabase/rollback/20260902091600_f1_02_pr07_funnel_reads_crm_payloads_rollback.sql
supabase/tests/f1-02-pr07/funnel_reads_crm_payloads.sql
\`\`\`

Do not alter App.jsx in the current approved PR-07 design.

Current single handoff:

\`\`\`text
implement exact three-file PR-07 candidate
-> validate
-> open Draft
-> Backend/Data exact-head review
-> independent AppSec exact-head review
-> STOP before Ready
\`\`\`

After PR-07, the finite critical path is:

\`\`\`text
PR-08 -> PR-09 -> M2 -> M3 -> M4 -> M5 -> M6
\`\`\`

Bounded pre-Security-Go backlog remains parked and does not interrupt the current
task without a material class-A finding:

\`\`\`text
OC-01 leaked-password control
Root RPC grant hardening
critical-helper baseline versioning
Issue #133 Root/Admin Global rollout
Issue #135 Team Lifecycle Authority
explicit Root support mode
\`\`\`

Explicit prohibitions:

\`\`\`text
NO Ready
NO merge
NO deploy
NO production Supabase application
NO Auth/data mutation
NO hostile production tests
NO Security Go
NO broad paid commercialization
NO reopening B4 without material invalidation
NO reopening LeadOps/Backend/Data design gates without material invalidation
\`\`\`

Do not use lifecycle movement of the documentation-only SFJM reconciliation as a
reason to create another continuity PR. NO_RECURSIVE_LIFECYCLE_RECONCILIATION
remains in force.


## 0.0000 Current handoff override — B2 closed / B4 next — 2026-09-01

This section is the current handoff authority when older B2-next sections below
conflict. Preserve older material as lineage only.

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

Current handoff:

```text
closed bounded slice:
  F1-02/B2 — EXCESSIVE DIRECT CRM WRITES
  REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN

next bounded risk:
  F1-02/B4 — LIST ACL CROSS-TENANT TARGET RISK / PR-06

next action:
  TARGET DESIGN + AUTHORIZATION MATRIX FIRST

required specialists before implementation:
  Architecture
  AppSec
  LeadOps
```

Do not infer B4 implementation authority, runtime-negative PASS or Security Go
from this handoff.


**Status:** `SECURITY_TO_SCALE_2026 / F1_02_B3_REMEDIATED / B2_NEXT / SECURITY_GO_DENIED`
**Updated:** `2026-09-01`
**Repository:** `wagnerjfjunior/fecha.ai`

## 0.000 Current handoff override — B3 closed / B2 next — 2026-09-01

This section is the current handoff authority when older sections below
conflict. Preserve older material as lineage; do not replay stale lifecycle or
authorization.

```text
Program #141: OPEN
M1 baseline #150: CLOSED / completed
F1-02: ACTIVE REMEDIATION
B3: REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN
post-application AppSec: PASS
RUNTIME_NEGATIVE_PASS: NOT ESTABLISHED
Security Go: DENIED
broad paid commercialization: BLOCKED
```

Current GitHub/database anchors:

```text
FECH.AI main at B3 closure:
  035f57e29d64c0cca26048a925a790459bd9976c
PR #157:
  CLOSED / MERGED
Supabase B3 ledger version:
  20260901074722
```

### Do not reopen

Do not reopen B3 design, PR #157 review, application or catalog proof merely
because runtime-negative testing was not authorized. A material contradictory
event is required to invalidate this closure.

### Single next handoff

```text
F1-02/B2 — EXCESSIVE DIRECT CRM WRITES
TARGET DESIGN / CALL-SITE + LIVE CONTRACT RECONSTRUCTION FIRST
```

Current bounded evidence:

```text
public.leads:
  authenticated INSERT=true
  authenticated UPDATE=true

public.lotes:
  authenticated UPDATE=true
```

The next specialist path is Backend/Data target-design reconstruction followed
by independent AppSec review. No implementation authority exists from this
handoff.

### Explicit boundaries

```text
NO Supabase mutation
NO runtime-negative production test
NO rollback
NO Ready/merge from this handoff
NO Security Go
NO broad paid commercialization
NO Issue #141 closure
```

For unrelated active workstreams and historical decisions, use
`docs/sfjm/CURRENT_STATE.md` plus live evidence; this override changes only
the B3 closure / #150 lifecycle / next-action meaning.


## 1. Purpose

This is the thin current handoff pointer. It does not replace live GitHub,
Supabase/runtime evidence, bootstrap, specialist routing, authority or the
evidence-freshness ledger.

Historical M1 and public.leads lineage remains preserved in
`docs/sfjm/CURRENT_STATE.md` and `docs/sfjm/EVIDENCE_FRESHNESS.md`.

## 2. Reconstruct in this order

```text
1. resolve wagnerjfjunior/fecha.ai main live
2. read docs/bootstrap/INDEX.md
3. read docs/skills/SES_SPECIALIST_ROUTING.md
4. resolve the adopted SES role/archetype/certification/local rule
5. read the common Modus Operandi
6. read governance when applicable
7. read docs/sfjm/INDEX.md and current SFJM views
8. resolve Issues #141 and #150 live
9. resolve any PR/branch/head involved in the next bounded lifecycle
10. do not reopen M1 technical acquisition without a material invalidation event
```

## 3. Current program state

```text
#141 Security-to-Scale 2026:
  OPEN

#150 M1 Security Truth Baseline:
  technical/evidence exit criteria SATISFIED
  OPEN pending separately authorized Issue closure

M1_SECURITY_TRUTH_BASELINE:
  COMPLETE

REMEDIATION_PROGRAM:
  ACTIVE

Security Go:
  DENIED / NOT_GRANTED

broad paid commercialization:
  BLOCKED
```

## 4. Final M1 gates

```text
Backend/Data:
  BACKEND_DATA_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

Application Security:
  APPSEC_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

Documentation Auditor:
  DOCUMENTATION_M1_CLOSURE_PASS_WITH_BOUNDED_RESIDUALS

blockers to M1 baseline closure:
  NONE

additional technical re-audit:
  NO / AUDIT_LOOP_BLOCKED
```

Preserve:

```text
M1_FINDING_DISCOVERED != M1_FINDING_REMEDIATED
M1_BASELINE_COMPLETE != SECURITY_GO
STATIC_IMPLEMENTATION_REVIEW != LIVE_DATABASE_VALIDATED
LIVE_DATABASE_VALIDATED != CONTROLLED_RUNTIME_PASS
```

## 5. Current finding set

```text
M1-B-F01  ANON_PRIVILEGED_RPC_EXECUTION_SURFACE
M1-C-F01  FUNIL_TENANT_RELATIONSHIP_INTEGRITY_GAP  [P0]
           no proven cross-tenant lead leakage claim
MIGRATION_PROVENANCE_GAP
M1-D-F01  DEPENDENCY_REPRODUCIBILITY_GAP
M1-D-F02  VITE_6_4_2_KNOWN_AFFECTED_VERSION
M1-E-F01  LIVE_EDGE_FUNCTION_NOT_VERSIONED
M1-E-F02  BROWSER_SESSION_REFRESH_TOKEN_EXPOSURE_SURFACE
M1-E-F03  EXTERNAL_WORKER_PROXY_AUTHORITY_GAP
M1-E-F04  LEAKED_PASSWORD_PROTECTION_DISABLED
```

All remain unresolved according to their classifications. M1 closure does not
remediate them.

## 6. Evidence limitations

```text
CONTROLLED_RUNTIME_NEGATIVE_PASS = NOT_ESTABLISHED
production negative/offensive testing = PROHIBITED
Vite production exploitability = NOT_ESTABLISHED
Worker runtime abuse / PII leak / tenant crossover = NOT_PROVEN
public.leads controlled runtime negative PASS = NOT_ESTABLISHED
```

## 7. Current lifecycle reconciliation

```text
#140:
  CLOSED / MERGED
  merge commit c0d993ebe574f644af4f83cc25630fb8c1bd41ad

#139:
  OPEN / READY
  head 32003e75a28e235fb454d39e3e4459d0f03acb2b
  STALE_REVALIDATION_REQUIRED
  M1 closure grants NO fresh approval

#131:
  STALE_CONTINUITY

#124:
  STALE_CONTINUITY

#120:
  SUPERSEDED
```

## 8. Single next safe action

```text
P0 — M1-C-F01 / FUNIL TENANT INTEGRITY

DESIGN / PROOF PLAN FIRST
NO IMPLEMENTATION UNDER THIS DOCUMENTATION AUTHORITY
```

The design/proof plan must define:

- the tenant-aware database invariant;
- correct `mover_funil` tenant attribution;
- explicit handling decision for existing anomalous rows without silent cleanup;
- preservation of RLS/FORCE RLS;
- rollback;
- static/live verification obligations;
- runtime-negative proof only if separately authorized and feasible without
  production negative testing.

## 9. Prohibited carry-over

Do not derive authorization from this handoff for:

```text
Ready / merge / deploy
Supabase / Auth / migration / data mutation
cleanup of anomalous funil rows
production negative testing
staging / LAB / second Supabase project / Preview Branch / local isolated env
Security Go
broad paid commercialization
Issue #141 closure
fresh #139 approval
reopening public.leads
```

Issue #150 closure requires a separate explicit Product Authority action after
the bounded M1 documentation reconciliation reaches its own authorized lifecycle
gate.
