# FECH.AI — SFJM Program Task Graph

## 0.0000000000000000038 CURRENT POST-MERGE OVERLAY — PR #213 / DEFERRED FINAL OFFENSIVE LAB AUTHORIZATION — 2026-09-09

~~~text
canonical main = dbc1e246b66d9726e7d3831085e62d27cab6908d
PR #213 = MERGED / CLOSED
exact merged head = 3119515faa7a20d3cb43e11431bf2de6e3d87cc3

STS-M3-06 =
AUTHORIZED_DEFERRED / NOT_CURRENT_ACTION

STS-M5-01 =
AUTHORIZED_DEFERRED_FINAL_TEST / NOT_CURRENT_ACTION

STS-M5-02 =
AUTHORIZED_DEFERRED_FINAL_TEST / NOT_CURRENT_ACTION

cost-bearing lab creation now =
NOT_AUTHORIZED

real-data offensive lab =
FORBIDDEN

destructive production attack =
FORBIDDEN

CURRENT_IMMEDIATE_AUTHORIZED_TECHNICAL_EXECUTION =
NONE

Security Go =
NOT_GRANTED
~~~

PR #213 is now canonical lifecycle/provenance evidence for the deferred final offensive-test path. It changes no runtime or database object and does not promote the deferred tasks into current execution.


## 0.00 HISTORICAL / SUPERSEDED POST-MERGE OVERLAY — PR #211 / ZERO-MATERIAL-RESIDUAL WBS — 2026-09-09

~~~text
canonical main = 719f0e98b58c7bf4d39485020d4389f8654da659
PR #211 = MERGED / CLOSED
exact merged head = 64db0b4bbb374991505af4f8be5c0722a6b11be7

M3-M6 mapping parity at merged head =
51 / 51 expected IDs present in WBS + task graph + relationship catalog

M4 security non-regression mapping =
6 / 6 subtasks

M5 structure =
STS-M5-00..STS-M5-07

M6 structure =
STS-M6-01..STS-M6-05

CURRENT_AUTHORIZED_TECHNICAL_EXECUTION = NONE
Security Go = NOT_GRANTED
~~~

The zero-material-residual finish line is canonical planning/closure authority after PR #211. It changes no runtime or database object and grants no future task execution automatically.

## 0.0 CANONICAL SECURITY ASSURANCE CATALOG RELATION

Security/test artifacts are related to this graph through the canonical machine-readable catalog:

~~~text
docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json
~~~

Join contract:

~~~text
PROGRAM_TASK_GRAPH.Qualified ID
=
SECURITY_ASSURANCE_CATALOG.entries[].parent_qualified_id
~~~

Dashboard display contract:

~~~text
<parent_qualified_id> — <test / runner / workflow / evidence name>
~~~

Examples:

~~~text
STS-M1 — leads tenant integrity
STS-M3-04 — PME usage tracking scope RLS cross tenant rollback
STS-M4-04 — MesaCliente security / rollback / smoke artifact
~~~

The catalog assigns each artifact a stable `catalog_id` while preserving its original GitHub path and blob SHA.

~~~text
TASK DEFINITION AUTHORITY =
this task graph + canonical WBS

TEST / EVIDENCE RELATIONSHIP AUTHORITY =
docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json

VERSIONED TEST != EXECUTED TEST
EVIDENCE FILE != CURRENT PASS
CATALOGED != SECURITY GO
~~~

`STS-SEC-UNMAPPED`, if it ever appears in the catalog, is a quarantine state and must be reconciled to a canonical STS parent before Security Go.

## 0.01 HISTORICAL / SUPERSEDED EXECUTION OVERLAY — STS-M3-03 ACCEPTED / STS-M3-04 AUTHORIZED NOT INITIATED — 2026-09-08

~~~text
decision base main = ec42e7b087dd1bf9b7ddc0cf05316e9d3e7979be
STS-M2 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M3 = ACTIVE
STS-M3-01 = COMPLETE / ACCEPTED / FROZEN
STS-M3-02 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M3-03 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M3-04 = AUTHORIZED / NOT_INITIATED
STS-M3-05 = PLANNED / NOT_AUTHORIZED
STS-M3-06 = PLANNED / NOT_AUTHORIZED
Security Go = NOT_GRANTED
~~~

This historical overlay is retained for provenance only. It is superseded by the 2026-09-09 PR #211 post-merge overlay and does not define current operational meaning.


## 0.02 HISTORICAL / SUPERSEDED POST-MERGE EXECUTION OVERLAY — PR #202 MERGED / STS-M3-03 NEXT — 2026-09-08

~~~text
canonical main =
665e3920b17849f45d8b3fcea015b1492219f115

PR #202 =
MERGED / CLOSED

merge commit =
665e3920b17849f45d8b3fcea015b1492219f115

STS-M2 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED / FROZEN

STS-M3-02 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3-03 =
ELIGIBLE_NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

This override is the current operational meaning for continuity consumers and SFJM Workspace. Structural WBS IDs, labels, order and hours remain unchanged. PR #202 lifecycle is closed/merged; M3-03 is next eligible only and no execution authority is granted.

## 0.1 HISTORICAL / SUPERSEDED PRE-MERGE EXECUTION OVERLAY — STS-M3-02 ACCEPTED WITH RESIDUALS / STS-M3-03 NEXT — 2026-09-08

~~~text
publication base main =
c075a751c70ae24b5db8fcfc924c46fba6b10e3e

STS-M2 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED / FROZEN

STS-M3-02 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3-03 =
ELIGIBLE_NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

This historical pre-merge overlay is retained for provenance only and does not define current operational meaning for continuity consumers or SFJM Workspace. Structural WBS IDs, labels, order and hours remain unchanged.


## 0.2 HISTORICAL / SUPERSEDED EXECUTION OVERLAY — STS-M3-01 ACCEPTED / STS-M3-02 NEXT — 2026-09-07

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

This historical overlay is retained for provenance only and does not define current operational meaning for continuity consumers or SFJM Workspace. Structural WBS IDs, labels, order and hours remain unchanged.


## 0.3 HISTORICAL / SUPERSEDED ARCHITECTURE OVERRIDE — STS-M2-06 / STS-M2 CLOSURE — 2026-09-07

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

This historical architecture overlay is retained for provenance only and does not define current operational meaning for the task graph. The structural WBS IDs, hours, labels and order remain unchanged.


**Status:** `CURRENT / MATERIAL_EXECUTION_OVERLAY / WBS_DERIVED_STRUCTURE / WORKSPACE_CONSUMABLE`  
**Updated:** 2026-09-08  
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

This graph records program state only. Product Authority has accepted STS-M2-06 with `V2_STRANGLER / SAME_DATABASE_FIRST`. STS-M2 is complete with preserved residuals. STS-M3 is ACTIVE. STS-M3-01 is accepted/frozen and STS-M3-02 is complete/accepted with residuals. STS-M3-03 is next eligible but remains not authorized. No implementation, deploy or Security Go follows from these acceptances.

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

AUTHORIZED_DEFERRED
= Product Authority has authorized the bounded task scope, but execution is intentionally not the current action and remains gated by named sequencing/environment/cost conditions

AUTHORIZED_DEFERRED_FINAL_TEST
= authorized offensive/adversarial test scope reserved for the final technical test window; no execution before the declared lab admission conditions

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

STS-M2 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED

STS-M3-02 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3-03 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3-04 =
ACTIVE / SCOPE_EXPANDED / REBASELINE_REQUIRED

STS-M3-04-01 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3-04-02 =
COMPLETE_WITH_RESIDUALS / ACCEPTED

STS-M3-04-03..STS-M3-04-10 =
DEFINED_NOT_AUTHORIZED

STS-M3-05 =
PLANNED_NOT_AUTHORIZED

STS-M3-06 =
AUTHORIZED_DEFERRED / NOT_STARTED / NOT_CURRENT_ACTION

STS-M5-01 + STS-M5-02 =
AUTHORIZED_DEFERRED_FINAL_TEST / NOT_STARTED / NOT_CURRENT_ACTION

STS-M4 + STS-M5-00 + STS-M5-03..07 + STS-M6 =
PLANNED_NOT_AUTHORIZED unless separately authorized

CURRENT_IMMEDIATE_AUTHORIZED_TECHNICAL_EXECUTION =
NONE

DEFERRED_FUTURE_AUTHORITY_DOES_NOT_AUTO_EXECUTE =
YES

Security Go =
NOT_GRANTED
~~~

Current M3-04 closure condition:

~~~text
NO MATERIAL STRUCTURAL CROSS-TENANT GAP
+ NO UNJUSTIFIED SENSITIVE DIRECT-DML GAP
+ ZERO MATERIAL NOT_DETERMINED ROWS
+ INDEPENDENT APPSEC CLOSURE REVIEW
~~~

## 4.1 Program relationship join

~~~text
WBS qualified task
<-> PROGRAM_TASK_GRAPH.Qualified ID
<-> STS_WBS_PR_RELATIONSHIP_CATALOG.task_relations[].qualified_id
<-> STS_WBS_PR_RELATIONSHIP_CATALOG.pull_request_relations[].primary_qualified_id / related_qualified_ids
<-> SECURITY_ASSURANCE_CATALOG.entries[].parent_qualified_id
~~~

Canonical machine-readable PR/task relation:

~~~text
docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json
~~~

Historical PRs may be related to the current WBS as `HISTORICAL_CONTRIBUTION_TO_CURRENT_WBS`; that relation does not retroactively claim that the historical PR executed or completed the later WBS task.

## 5. WBS-derived task graph

| Parent qualified | Qualified ID | WBS ID | Label | Hours | Operational state |
|---|---|---|---|---:|---|
| STS-M0 | STS-M0-01 | M0-01 | Inventário de PRs e continuidade | 8 | COMPLETE |
| STS-M0 | STS-M0-02 | M0-02 | Pacotes de especialistas e dependências | 8 | COMPLETE |
| STS-M0 | STS-M0-03 | M0-03 | SFJM / Workspace baseline | 10 | COMPLETE |
| STS-M0 | STS-M0-04 | M0-04 | Roadmap / governança única | 10 | COMPLETE |
| PROGRAM | STS-M1 | M1 | Security Truth Baseline / F1-02 | 168 | COMPLETE_WITH_DEFERRED_SECURITY_ASSURANCE |
| PROGRAM | STS-M2 | M2 | Database Simplification & Optimization Plan | 116 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-01 | M2-01 | Matriz de 43 tabelas | 20 | COMPLETE |
| STS-M2 | STS-M2-02 | M2-02 | Mapa routines / policies / triggers / grants | 24 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-03 | M2-03 | Índices / ACL contraditórias | 16 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-04 | M2-04 | Política target de DEFINER / RLS / DML | 20 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-05 | M2-05 | Database Contract Map | 20 | COMPLETE_WITH_RESIDUALS |
| STS-M2 | STS-M2-06 | M2-06 | Decisão arquitetural do banco | 16 | COMPLETE |
| STS-M3 | STS-M3-01 | M3-01 | Identity / membership / team / role model | 24 | COMPLETE |
| STS-M3 | STS-M3-02 | M3-02 | Authority contract por contexto | 28 | COMPLETE_WITH_RESIDUALS |
| STS-M3 | STS-M3-03 | M3-03 | Privileged RPC Allowlist + Implementation Convergence | REBASELINE | COMPLETE_WITH_RESIDUALS / FINAL_CLOSURE_PENDING |
| STS-M3-03 | STS-M3-03-01 | M3-03-01 | Accepted privileged RPC allowlist baseline | historical | HISTORICAL_ACCEPTED_EVIDENCE |
| STS-M3-03 | STS-M3-03-02 | M3-03-02 | Resource-Bound Privileged RPC Remediation | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-03 | STS-M3-03-03 | M3-03-03 | Tenant-Scoped Analytics RPC Remediation | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-03 | STS-M3-03-04 | M3-03-04 | Internal-Helper Reachability Convergence | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-03 | STS-M3-03-05 | M3-03-05 | RPC EXECUTE Principal Convergence | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-03 | STS-M3-03-06 | M3-03-06 | Independent RPC Authority Closure Review | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3 | STS-M3-04 | M3-04 | Redução de DML sensível direto + Integridade Estrutural Multi-Tenant | REBASELINE | ACTIVE_REBASELINE_REQUIRED |
| STS-M3-04 | STS-M3-04-01 | M3-04-01 | PME message usage RPC-only write boundary | historical | COMPLETE_WITH_RESIDUALS |
| STS-M3-04 | STS-M3-04-02 | M3-04-02 | PME lead message state direct-write reduction | historical | COMPLETE_WITH_RESIDUALS |
| STS-M3-04 | STS-M3-04-03 | M3-04-03 | Global Tenant Surface & Relationship Inventory | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-04 | M3-04-04 | lista_avaliacoes Tenant-Relationship Hardening | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-05 | M3-04-05 | PME Catalog Tenant-Relationship Hardening | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-06 | M3-04-06 | Remaining Sensitive Direct-DML Adjudication & Remediation | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-07 | M3-04-07 | Tenant-Bound Database Invariant Verification | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-08 | M3-04-08 | Direct-Write / Bypass Call-Site Sweep | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-09 | M3-04-09 | Structural Cross-Tenant Negative Proofs | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-04 | STS-M3-04-10 | M3-04-10 | Independent AppSec Closure Review | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3 | STS-M3-05 | M3-05 | Auth / Admin Final Closure | REBASELINE | PLANNED_NOT_AUTHORIZED |
| STS-M3-05 | STS-M3-05-01 | M3-05-01 | Create-user canonical authority convergence | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-05 | STS-M3-05-02 | M3-05-02 | Password-reset / admin authority closure | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-05 | STS-M3-05-03 | M3-05-03 | Root / admin-local / gestor compatibility cleanup | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-05 | STS-M3-05-04 | M3-05-04 | Auth/Admin negative proofs | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3-05 | STS-M3-05-05 | M3-05-05 | Independent Auth/Admin closure review | TBD | DEFINED_NOT_AUTHORIZED |
| STS-M3 | STS-M3-06 | M3-06 | Security Staging + Service Boundary Hardening | REBASELINE | AUTHORIZED_DEFERRED / NOT_CURRENT_ACTION |
| STS-M3-06 | STS-M3-06-01 | M3-06-01 | Isolated security staging topology + fixtures | TBD | AUTHORIZED_DEFERRED / COST_GATED |
| STS-M3-06 | STS-M3-06-02 | M3-06-02 | mesa-worker-proxy auth/authorization disposition | TBD | AUTHORIZED_DEFERRED / DO_NOT_EXECUTE_NOW |
| STS-M3-06 | STS-M3-06-03 | M3-06-03 | Service-to-service credential / payload / rate boundary | TBD | AUTHORIZED_DEFERRED / DO_NOT_EXECUTE_NOW |
| STS-M3-06 | STS-M3-06-04 | M3-06-04 | Hostile-client / cross-tenant harness readiness | TBD | AUTHORIZED_DEFERRED / COST_GATED |
| STS-M3-06 | STS-M3-06-05 | M3-06-05 | M3 Final Security Implementation Closure | TBD | AUTHORIZED_DEFERRED / FINAL_CLOSURE_HELD |
| STS-M4 | STS-M4-01 | M4-01 | AppShell / Shared Frontend Boundary | 20 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-02 | M4-02 | CRM + Funil Core Slice | 40 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-03 | M4-03 | LeadOps Execution Slice — Leads / Listas / Distribuição / Discador / Power Message Engine | 32 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-04 | M4-04 | MesaCliente Core Slice | 32 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-05 | M4-05 | Feature Gateways / API Boundaries | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M4 | STS-M4-06 | M4-06 | Core Functional Equivalence & Regression | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-00 | M5-00 | Global Security Assurance Coverage Reconciliation | REBASELINE | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-01 | M5-01 | Hostile-client suite isolada | 28 | AUTHORIZED_DEFERRED_FINAL_TEST / LAB_REQUIRED |
| STS-M5 | STS-M5-02 | M5-02 | Regressão tenant / role / auth / storage | 28 | AUTHORIZED_DEFERRED_FINAL_TEST / LAB_REQUIRED |
| STS-M5 | STS-M5-03 | M5-03 | Dependency / CVE gate | 12 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-04 | M5-04 | Secrets / config / deploy gate | 16 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-05 | M5-05 | Observabilidade / rollback / incidente | 24 | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-06 | M5-06 | Material Residual Elimination Gate | REBASELINE | PLANNED_NOT_AUTHORIZED |
| STS-M5 | STS-M5-07 | M5-07 | Independent Integrated AppSec Final Review | REBASELINE | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-01 | M6-01 | Security Evidence + Final AS-BUILT Package | 14 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-02 | M6-02 | Blocker closeout | 8 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-03 | M6-03 | Onboarding / support / operational runbooks | 18 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-04 | M6-04 | Decisão comercial controlada | 8 | PLANNED_NOT_AUTHORIZED |
| STS-M6 | STS-M6-05 | M6-05 | Launch readiness + AS-BUILT acceptance review | 12 | PLANNED_NOT_AUTHORIZED |

Milestone states:

~~~text
STS-M2 = COMPLETE_WITH_RESIDUALS / ACCEPTED
STS-M3 = ACTIVE
STS-M4 = PLANNED_NOT_AUTHORIZED
STS-M5 = PLANNED_NOT_AUTHORIZED
STS-M6 = PLANNED_NOT_AUTHORIZED
~~~

Deferred offensive-lab execution overlay:

~~~text
AUTHORIZATION_SOURCE = Product Authority / 2026-09-09
STS-M3-06 = AUTHORIZED_DEFERRED
STS-M5-01 = AUTHORIZED_DEFERRED_FINAL_TEST
STS-M5-02 = AUTHORIZED_DEFERRED_FINAL_TEST

CURRENT_ACTION = NO
EXECUTE_NOW = NO
REAL_DATA = FORBIDDEN
DESTRUCTIVE_PRODUCTION_ATTACK = FORBIDDEN
PAID_ENVIRONMENT_CREATION_NOW = NOT_AUTHORIZED

FINAL_TEST_SEQUENCE =
all applicable non-offensive tests
→ explicit cost confirmation + isolated Supabase lab admission
→ STS-M3-06 lab/harness readiness
→ STS-M5-01 hostile-client
→ STS-M5-02 cross-tenant/role/auth/storage adversarial regression
→ STS-M5-06 residual elimination
→ STS-M5-07 independent AppSec review
→ M6
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

## 6.2 Adopted zero-material-residual security closure map — M3 through M6

The 2026-09-09 Product Authority direction materially adopts the following decomposition and non-regression obligations. These are now explicit WBS/task-graph nodes or closure contracts; they are not execution authorization.

### M3

~~~text
STS-M3-03
├── 03-01 accepted allowlist baseline
├── 03-02 resource-bound RPC remediation
├── 03-03 tenant-scoped analytics remediation
├── 03-04 internal-helper reachability convergence
├── 03-05 EXECUTE principal convergence
└── 03-06 independent RPC authority closure

STS-M3-04
├── 04-01..02 accepted historical slices
├── 04-03 global tenant surface inventory
├── 04-04 lista_avaliacoes hardening
├── 04-05 PME catalog hardening
├── 04-06 remaining DML/default-privilege remediation
├── 04-07 invariant verification
├── 04-08 bypass/call-site sweep
├── 04-09 structural negative proofs
└── 04-10 independent AppSec closure

STS-M3-05
├── 05-01 create-user authority
├── 05-02 password-reset/admin authority
├── 05-03 legacy role/root compatibility cleanup
├── 05-04 negative proofs
└── 05-05 independent closure

STS-M3-06
├── 06-01 isolated staging/fixtures
├── 06-02 mesa-worker-proxy disposition
├── 06-03 service credential/payload/rate boundary
├── 06-04 hostile-client harness readiness
└── 06-05 final M3 implementation closure
~~~

### M4 — all six structural subtasks carry security non-regression obligations

| Qualified ID | Security obligation |
|---|---|
| STS-M4-01 | no business/tenant/role/ownership authority in AppShell |
| STS-M4-02 | CRM/Funil consume hardened server contracts; no direct-write/tenant regression |
| STS-M4-03 | LeadOps/PME preserve tenant, distribution and sensitive-DML boundaries |
| STS-M4-04 | MesaCliente preserves resource/tenant/service authorization boundaries |
| STS-M4-05 | privileged feature gateways enforce server-side authority |
| STS-M4-06 | functional equivalence plus changed-boundary security regression |

### M5 — all assurance subtasks

~~~text
STS-M5-00 coverage reconciliation
STS-M5-01 isolated hostile-client suite
STS-M5-02 tenant/role/auth/storage regression
STS-M5-03 dependency/CVE gate
STS-M5-04 secrets/config/deploy/migration gate
STS-M5-05 observability/rollback/incident readiness
STS-M5-06 material residual elimination gate
STS-M5-07 independent integrated AppSec final review
~~~

### M6 — all launch/security-candidate subtasks

~~~text
STS-M6-01 current Security Evidence + AS-BUILT
STS-M6-02 zero-material blocker/finding closeout
STS-M6-03 secure onboarding/support/runbooks
STS-M6-04 controlled commercial decision after technical closure
STS-M6-05 launch readiness / Product Authority Security Go consideration
~~~

Program finish-line invariant:

~~~text
MATERIAL SECURITY FINDING OPEN
=> OWNING TASK NOT FINAL-CLOSED
=> M5 NOT PASS
=> M6 NOT SECURITY-GO ELIGIBLE

ZERO MATERIAL OPEN SECURITY FINDINGS
+ ZERO MATERIAL NOT_DETERMINED
+ CURRENT PROOF
+ INDEPENDENT APPSEC PASS
= REQUIRED BEFORE M6 SECURITY-GO CANDIDACY
~~~

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
