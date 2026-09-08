# FECH.AI — SFJM Program Task Graph

## 0. CURRENT EXECUTION OVERLAY — STS-M3-01 ACCEPTED / STS-M3-02 NEXT — 2026-09-07

~~~text
publication base main =
661ef0014576d473088add0052d751e0a47d306e

STS-M2 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED

STS-M3-02 =
ELIGIBLE_NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

This override is the current operational meaning for continuity consumers and SFJM Workspace. Structural WBS IDs, labels, order and hours remain unchanged.


## 0.1 HISTORICAL / SUPERSEDED ARCHITECTURE OVERRIDE — STS-M2-06 / STS-M2 CLOSURE — 2026-09-07

~~~text
publication base main =
83186f5775e563e150329fa0b95dd1d7f3f3a516

STS-M2-06 =
COMPLETE / ACCEPTED

DATABASE STRATEGY =
V2_STRANGLER / SAME_DATABASE_FIRST

STS-M2 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3 =
ELIGIBLE_NOT_AUTHORIZED

STS-M3-01 =
ELIGIBLE_NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

This override is the current operational meaning for the task graph. The structural WBS IDs, hours, labels and order remain unchanged.


**Status:** `CURRENT / MATERIAL_EXECUTION_OVERLAY / WBS_DERIVED_STRUCTURE / WORKSPACE_CONSUMABLE`  
**Updated:** 2026-09-07  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Purpose

This file publishes the FECH.AI program task graph for continuity consumers such as SFJM Workspace.

It does not replace the WBS.

Canonical separation:

~~~text
WBS STRUCTURE
docs/roadmap/fechai-security-to-scale-2026-wbs.md
= authority for planned milestone/task IDs, labels, order, hours and exit contracts

PROGRAM TASK GRAPH
docs/sfjm/PROGRAM_TASK_GRAPH.md
= operational overlay for state, parent/children edges, execution-discovered decomposition,
  residual continuity and next-task relationship

CURRENT_STATE
docs/sfjm/CURRENT_STATE.md
= principal authority for current material product/security meaning

NEXT_SAFE_ACTION
docs/sfjm/NEXT_SAFE_ACTION.md
= current semantic action/gate
~~~

A consumer must not silently turn `PLANNED` or `ELIGIBLE` into execution authority.

Qualified identity contract outside the WBS:

~~~text
qualified milestone id = STS-Mx
qualified task id = STS-Mx-yy
compact WBS id = Mx-yy

example:
qualified_id = STS-M2-06
wbs_id = M2-06
parent_id = STS-M2
~~~

The compact WBS ID is preserved for exact parity with the WBS, but it is not the primary cross-program identity outside the WBS document.

## 2. Source anchors at publication

~~~text
publication base main =
f7a6c69b8440b60181c7a4a9956c0f3c4268e9f6

WBS =
docs/roadmap/fechai-security-to-scale-2026-wbs.md
blob c6fe2e339c4de33dfb8265912ba6b63380270c4e
= INTEGRAL_READ

CURRENT_STATE =
docs/sfjm/CURRENT_STATE.md
blob 7a2c6f236f75993d0b02e27f6a0864ca15cb0c83
= INTEGRAL_READ

NEXT_SAFE_ACTION =
docs/sfjm/NEXT_SAFE_ACTION.md
blob f0217fdbdf6f9eff5243b3b60f9c87d35c269e1e
= INTEGRAL_READ
~~~

## 2.1 STS-M2-05 acceptance reconciliation anchor

~~~text
acceptance/publication base main =
e07254ef6b2d7184e749463727df2e6d404226a7

STS-M2-05 durable evidence on canonical main =
docs/security/evidence/2026-09-07-sts-m2-05-database-contract-map.md
blob 8b2875e1bc095329482de095028ed31b37091d63
PR #195 = MERGED / CLOSED
merge commit = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
canonical main = d6953ea3071ada55fbcd97f21c848f5c6424ca3f

STS-M2-05 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M2-06 =
COMPLETE / ACCEPTED

STS-M2 =
COMPLETE_WITH_RESIDUALS / ACCEPTED
~~~

The historical WBS label `Matriz de 43 tabelas` is preserved. The accepted/live canonical database universe for STS-M2-05 is 44 tables.

This graph records program state only. Product Authority has accepted STS-M2-06 with `V2_STRANGLER / SAME_DATABASE_FIRST`. STS-M2 is complete with preserved residuals. STS-M3 is ACTIVE after accepted STS-M3-01 closure. STS-M3-02 is next eligible but remains not authorized. No implementation, deploy or Security Go follows from this acceptance.

## 3. Consumer state vocabulary

~~~text
COMPLETE
= accepted/closed material task; residuals may remain if explicitly preserved

COMPLETE_WITH_RESIDUALS
= accepted/closed task with preserved residual implementation/evidence/runtime/lifecycle work

ACTIVE
= current milestone or explicitly active authorized execution

AUTHORIZED_READ_ONLY
= execution is explicitly authorized for bounded READ_ONLY evidence/reasoning only; no mutation authority

ELIGIBLE_NOT_AUTHORIZED
= next structurally eligible task; execution authority has not been granted

PLANNED_NOT_AUTHORIZED
= future WBS task; no execution authority

BLOCKED
= cannot proceed until named condition/authority/evidence is satisfied

SUPERSEDED
= historical execution node retained only for continuity
~~~

## 4. Current program position

~~~text
program = FECH.AI Security-to-Scale 2026
completed milestone = STS-M2 — Database Simplification & Optimization Plan
current milestone = STS-M3 — Backend Authority Contract Freeze
current next task = STS-M3-02 — Authority contract por contexto
STS-M2-05 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M2-06 = COMPLETE / ACCEPTED
STS-M2 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M3 = ACTIVE
STS-M3-01 = COMPLETE / ACCEPTED
STS-M3-02 = ELIGIBLE_NOT_AUTHORIZED
STS-M3-02..STS-M6 execution = NOT_AUTHORIZED
Security Go = NOT_GRANTED
~~~

## 5. WBS-derived task graph

| Parent qualified | Qualified ID | WBS ID | Label | Hours | Operational state |
|---|---|---|---|---:|---|
| STS-M2 | STS-M2-01 | M2-01 | Matriz de 43 tabelas | 20 | COMPLETE |
| STS-M2 | STS-M2-02 | M2-02 | Mapa routines / policies / triggers / grants | 24 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-03 | M2-03 | Índices / ACL contraditórias | 16 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-04 | M2-04 | Política target de DEFINER / RLS / DML | 20 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-05 | M2-05 | Database Contract Map | 20 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-06 | M2-06 | Decisão arquitetural do banco | 16 | COMPLETE |
| STS-M3 | STS-M3-01 | M3-01 | Identity / membership / team / role model | 24 | COMPLETE |
| STS-M3 | STS-M3-02 | M3-02 | Authority contract por contexto | 28 | ELIGIBLE_NOT_AUTHORIZED |
| STS-M3 | STS-M3-03 | M3-03 | Allowlist de RPCs privilegiadas | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M3 | STS-M3-04 | M3-04 | Redução de DML sensível direto | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M3 | STS-M3-05 | M3-05 | Fechamento Auth / Admin flows | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M3 | STS-M3-06 | M3-06 | Staging / test plan de segurança | 28 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-01 | M4-01 | AppShell / Shared Frontend Boundary | 20 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-02 | M4-02 | CRM + Funil Core Slice | 40 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-03 | M4-03 | LeadOps Execution Slice — Leads / Listas / Distribuição / Discador / Power Message Engine | 32 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-04 | M4-04 | MesaCliente Core Slice | 32 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-05 | M4-05 | Feature Gateways / API Boundaries | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-06 | M4-06 | Core Functional Equivalence & Regression | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-01 | M5-01 | Hostile-client suite isolada | 28 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-02 | M5-02 | Regressão tenant / role / auth / storage | 28 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-03 | M5-03 | Dependency / CVE gate | 12 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-04 | M5-04 | Secrets / config / deploy gate | 16 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-05 | M5-05 | Observabilidade / rollback / incidente | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-06 | M5-06 | Adjudicação de residual risk | 20 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-01 | M6-01 | Security Evidence + Final AS-BUILT Package | 14 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-02 | M6-02 | Blocker closeout | 8 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-03 | M6-03 | Onboarding / support / operational runbooks | 18 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-04 | M6-04 | Decisão comercial controlada | 8 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-05 | M6-05 | Launch readiness + AS-BUILT acceptance review | 12 | PLANNED_NOT_AUTHORIZED |

Milestone states:

~~~text
STS-M2 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M3 = ELIGIBLE_NOT_AUTHORIZED
STS-M4 = PLANNED_NOT_AUTHORIZED
STS-M5 = PLANNED_NOT_AUTHORIZED
STS-M6 = PLANNED_NOT_AUTHORIZED
~~~

## 6. Execution-discovered decomposition — STS-M2-04

The following nodes are not new WBS milestones. They are execution-discovered continuity children of STS-M2-04.

~~~text
STS-M2-04 = COMPLETE_WITH_RESIDUALS
├── STS-M2-04B = COMPLETE_WITH_RESIDUALS
│   ├── STS-M2-04B1 = COMPLETE_WITH_RESIDUALS / ACCEPTED
│   ├── STS-M2-04B2 = COMPLETE_WITH_RESIDUALS / ACCEPTED
│   └── STS-M2-04B3 = COMPLETE / ACCEPTED
├── STS-M2-04C = COMPLETE_WITH_RESIDUALS / ACCEPTED
│   ├── STS-M2-04C1 = COMPLETE
│   ├── STS-M2-04C2 = COMPLETE_WITH_RESIDUALS / ACCEPTED
│   ├── STS-M2-04C3 = COMPLETE / ACCEPTED; historical NOT_DETERMINED resolved downstream by E
│   └── STS-M2-04C4 = COMPLETE / ACCEPTED; design/evidence residuals preserved
├── STS-M2-04D = COMPLETE / ACCEPTED
└── STS-M2-04E = COMPLETE_WITH_RESIDUALS / ACCEPTED
~~~

No `STS-M2-04F` node is canonical or created by this graph.

Current STS-M2-04 residual boundary remains:

~~~text
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
C4 design/evidence residuals = PRESERVED
AppSec PASS = NOT_PERFORMED
runtime assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

These residuals do not reopen STS-M2-04 unless a material invalidator changes the accepted decision.

## 6.1 Accepted STS-M2-05 contract overlay

~~~text
STS-M2-05 = COMPLETE_WITH_RESIDUALS / ACCEPTED
44 / 44 tables
160 / 160 public routines
23 / 23 non-DEFINER delta
31 / 31 non-internal trigger instances
10 / 10 bounded contexts
STS-M2-06 = COMPLETE / ACCEPTED
~~~

STS-M2-05 residual implementation/lifecycle/callsite-evidence/runtime/AppSec work is preserved and does not reopen the accepted Database Contract Map unless a material invalidator changes the decision.

## 7. Future decomposition rule

Future WBS tasks start as one node only.

Example:

~~~text
STS-MX-YY = PLANNED_NOT_AUTHORIZED
children = NONE YET
~~~

If execution later requires a bounded split:

~~~text
STS-MX-YY
├── STS-MX-YY-A
├── STS-MX-YY-B
└── STS-MX-YY-C
~~~

the children may be added here only when the decomposition is materially adopted.

Do not pre-invent child tasks.

A decomposition update must preserve:

~~~text
parent task
child IDs
reason for split
state
dependencies
residuals
evidence
authorization boundary
next safe action
~~~

## 8. Workspace consumption contract

A Workspace/dashboard consumer should reconstruct in this order:

~~~text
1. resolve FECH.AI main live
2. read WBS structural source
3. read PROGRAM_TASK_GRAPH
4. read CURRENT_STATE
5. read NEXT_SAFE_ACTION
6. overlay LIVE_RESOLVED_STATE where required
~~~

Rendering rules:

~~~text
WBS task exists + no operational override
→ render WBS task with structural state only

task graph state exists
→ render operational state from task graph

execution-discovered children exist
→ allow progressive expand/collapse

ELIGIBLE_NOT_AUTHORIZED
→ display as NEXT/ELIGIBLE, never ACTIVE

COMPLETE_WITH_RESIDUALS
→ display closed/accepted plus residual indicator; do not reopen parent

unknown child decomposition
→ show no children; do not infer

main/source mismatch
→ mark snapshot stale; do not silently claim current
~~~

The Workspace remains a consumer. It must not become authority for FECH.AI task state.

## 9. Material update rule

Update this graph only when one of these changes materially:

~~~text
a WBS task is accepted/closed
a new WBS task becomes eligible/active
an execution split is adopted
a child task is completed/blocked/superseded
a residual changes the task's operational meaning
the next-task relationship changes
a material invalidator reopens a previously accepted task
~~~

Do not update this graph merely because:

~~~text
a PR becomes Draft/Ready/merged
main SHA changes with no semantic change
a conversation changes
a documentation-only lifecycle event occurs
~~~

This preserves the SFJM anti-loop rule.
