# FECH.AI — Security-to-Scale 2026 — Current Execution WBS

**Status:** `CURRENT_EXECUTION_BASELINE_ON_MAIN / CANDIDATE_WHILE_ON_PR_HEAD / DOCUMENTATION_ONLY`  
**Program:** Issue #141 — `PROGRAM: FECH.AI Security-to-Scale 2026`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Program authority:** FECH.AI canonical project state + Product Authority  
**Governance adjudication:** `docs/governance/2026-09-04-fechai-bcr-security-to-scale-program-hierarchy-core-dod.md`  
**Planning baseline canonicalization date:** 2026-09-04

## 0. Canonical security / continuity navigation

```text
Security Go methodology / proof contract
→ docs/security/assurance/SECURITY_GO_PROGRAM.md

Structural WBS
→ this file

Operational task/decomposition overlay
→ docs/sfjm/PROGRAM_TASK_GRAPH.md

FECH.AI SFJM continuity protocol/application
→ docs/sfjm/INDEX.md

WBS / STS / PR relationship
→ docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json

Test / evidence relationship
→ docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json

Specialist routing
→ docs/skills/SES_SPECIALIST_ROUTING.md
```

External relationship:

```text
SFJM protocol research/governance
→ wagnerjfjunior/StopJuniorMode

SFJM Workspace / dashboard product
→ wagnerjfjunior/sfjm-workspace

SES specialist system
→ wagnerjfjunior/Specialist-Engineering-System
```

Authority invariant:

```text
WBS = structural planning authority
SFJM = project continuity/material-state layer
Workspace/dashboard = derived visualization
SES = specialist identity/contract/certification layer
GitHub/Supabase/runtime = live evidence authorities within scope
Product Authority = material decision / lifecycle / Security Go authority
```

## 1. Purpose

This document is the FECH.AI-owned granular Work Breakdown Structure for the current Security-to-Scale 2026 program.

It exists to provide the granular execution baseline for the current FECH.AI core-completion/hardening program while preventing roadmap identity drift across conversations, specialists and derived workspaces.

It does not replace Issue #141, the program-hierarchy BCR, SFJM, live GitHub lifecycle, runtime evidence, specialist routing or Product Authority.

The program is primarily organized by shared architectural layers. CRM, Funil, Discador, Power Message Engine and MesaCliente are core bounded product contexts/features of the same FECH.AI platform and inherit common database, backend-authority, Auth, tenant/company, deploy and observability foundations.

## 2. Authority and precedence

```text
program hierarchy BCR
= current precedence + namespace + core finish line + M4/AS-BUILT adjudication

Issue #141
= program objective + M0–M6 milestone contract + owners + exit criteria

this file
= FECH.AI-owned granular execution WBS IDs + planning hours + package boundaries

docs/sfjm/*
= current operational/material state + continuity + evidence/authority boundaries

sfjm-workspace
= derived visualization / continuity representation
```

If this file exists only on a PR head, it is candidate documentation and does not override `main`.
Once merged to FECH.AI `main`, this file is the FECH.AI-owned granular execution baseline for Security-to-Scale 2026.

Historical product-module, Roadmap Mestre and B0 labels remain preserved in their own source documents. They do not control current Security-to-Scale progress.

Qualified naming outside this WBS:

```text
PRODUCT_MODULE_M1..M6
B0-M1..M6
STS-M0..M6
STS-M2-01 etc.
```

Inside this file, short IDs such as `M2-01` are unambiguous and remain the compact WBS labels.

Preserve:

```text
WBS_TASK_DEFINED != TASK_STARTED
PLANNED != AUTHORIZED
WBS_HOURS != CLOCKED_TIMESHEET
MILESTONE_COMPLETE != SECURITY_GO
WORKSPACE_REPRESENTATION != FECHAI_AUTHORITY
```

## 2.1 Core finish line

Security-to-Scale finishes the FECH.AI **core**, not every future capability.

Core launch-scope flows that must remain operational and regression-proven:

```text
CRM
Funil
Discador
Power Message Engine / Aceleração Operacional
MesaCliente
```

Shared LeadOps dependencies include Leads, Listas, Distribuição, responsible broker, feedback, next action/follow-up and history where used.

Advanced ADS/CAPI/tracking, broader portal integrations, advanced campaign/message automation and full monetization/GTM expansion remain product capabilities/future work unless separately brought into launch scope.

```text
CORE_COMPLETE != EVERY_FUTURE_FEATURE_COMPLETE
OUTSIDE_CORE_FINISH_LINE != RETIRED_CAPABILITY
```

The final M6 gate also requires a professional indexed AS-BUILT package as defined by the program-hierarchy BCR.

## 3. Planning totals

The original 2026 planning baseline remains preserved for provenance, but Product Authority expanded the material scope of `STS-M3-04` on 2026-09-08 to include structural multi-tenant integrity and added `STS-M5-00` as a global security-assurance reconciliation gate.

Therefore the old aggregate hours are no longer a reliable current forecast until a bounded rebaseline is approved.

```text
HISTORICAL_CRITICAL_PATH_TOTAL = 832h

M0 = 36h
M1 = 168h
M2 = 116h
M3 = REBASELINE_REQUIRED
M4 = 172h
M5 = REBASELINE_REQUIRED
M6 = 60h

STS-M3-04 historical estimate = 24h
STS-M3-04 current estimate = REBASELINE_REQUIRED

STS-M5-00 = NEW / HOURS_NOT_YET_BASELINED

CURRENT_ACCEPTED_COMPLETE =
PRESERVE VERIFIED ACCEPTED TASK STATES;
DO NOT RECOMPUTE FROM STALE AGGREGATE HOURS

REMAINING_CRITICAL_PATH =
REBASELINE_REQUIRED

PRE_SECURITY_GO_BACKLOG = 116h
PLANNED_FUTURE_BACKLOG = 104h
```

Backlog hours remain separate from the historical 832h baseline.

Hours are planning estimates for sequencing/capacity visibility, not timesheet evidence and not automatic progress.

## 4. M0 — Program Control / Truth Reconciliation — 36h

**Qualified milestone:** `STS-M0`  
**Issue #141 window:** 28 Aug–4 Sep  
**State at canonicalization:** COMPLETE

| ID | Qualified ID | Task | Hours |
|---|---|---|---:|
| M0-01 | STS-M0-01 | Inventário de PRs e continuidade | 8h |
| M0-02 | STS-M0-02 | Pacotes de especialistas e dependências | 8h |
| M0-03 | STS-M0-03 | SFJM / Workspace baseline | 10h |
| M0-04 | STS-M0-04 | Roadmap / governança única | 10h |

Issue #141 exit remains authoritative for M0.

## 5. M1 — Security Truth Baseline / F1-02 — 168h

**Qualified milestone:** `STS-M1`  
**Issue #141 owners:** Backend/Data + AppSec + Documentation  
**Issue #141 window:** 4–18 Sep  
**Current state:** COMPLETE WITH DEFERRED SECURITY ASSURANCE

| ID | Task | Hours | State |
|---|---|---:|---|
| B1 | Baseline de evidências | 18h | COMPLETE |
| B2 | Direct CRM writes | 28h | COMPLETE |
| B3 | Funnel history boundary | 24h | COMPLETE |
| B4 | List ACL tenant integrity | 34h | COMPLETE |
| PR-07 | Tenant-safe reads + payload validation | 36h | COMPLETE |
| PR-08 | Proof matrix / negative tests | 22h | COMPLETE |
| PR-09 | Close-out & adjudicação final | 6h | COMPLETE |

M1 closure does not alter the deferred evidence boundary:

```text
J4 environment-dependent evidence = DEFERRED
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
```

## 6. M2 — Database Simplification & Optimization Plan — 116h

**Qualified milestone:** `STS-M2`  
**Issue #141 owners:** Backend/Data + Architecture  
**Issue #141 window:** 18 Sep–9 Oct  
**Current state:** ELIGIBLE / NOT STARTED

| ID | Qualified ID | Task | Hours |
|---|---|---|---:|
| M2-01 | STS-M2-01 | Matriz de 43 tabelas | 20h |
| M2-02 | STS-M2-02 | Mapa routines / policies / triggers / grants | 24h |
| M2-03 | STS-M2-03 | Índices / ACL contraditórias | 16h |
| M2-04 | STS-M2-04 | Política target de DEFINER / RLS / DML | 20h |
| M2-05 | STS-M2-05 | Database Contract Map | 20h |
| M2-06 | STS-M2-06 | Decisão arquitetural do banco | 16h |

Issue #141 exit contract remains authoritative:

- 43-table canonicality matrix: `KEEP / CONSOLIDATE / RETIRE / REMODEL / INTERNAL`;
- routine/policy/trigger/grant map with owner/caller/tenant/write authority;
- redundant index and contradictory ACL candidates using live statistics where required;
- target policy for SECURITY DEFINER, triggers, RLS and direct DML;
- Database Contract Map;
- decision `EVOLVE_IN_PLACE vs V2_STRANGLER vs NEW_DATABASE`, with evidence.

## 7. M3 — Backend Authority Contract Freeze — REBASELINE_REQUIRED

**Issue #141 owners:** Backend/Data + AppSec + Architecture  
**Issue #141 original window:** 9–30 Oct  
**Current state:** ACTIVE  
**Historical M3 planning total:** 152h  
**Current planning status:** `REBASELINE_REQUIRED`

| ID | Qualified ID | Task | Hours / planning state |
|---|---|---|---:|
| M3-01 | STS-M3-01 | Identity / membership / team / role model | 24h |
| M3-02 | STS-M3-02 | Authority contract por contexto | 28h |
| M3-03 | STS-M3-03 | Privileged RPC Allowlist + Implementation Convergence | REBASELINE_REQUIRED |
| M3-04 | STS-M3-04 | Redução de DML sensível direto + Integridade Estrutural Multi-Tenant | REBASELINE_REQUIRED |
| M3-05 | STS-M3-05 | Auth / Admin Final Closure | REBASELINE_REQUIRED |
| M3-06 | STS-M3-06 | Security Staging + Service Boundary Hardening | REBASELINE_REQUIRED |

### 7.1 STS-M3-03 implementation-convergence graph

The previously accepted privileged-RPC allowlist remains durable historical evidence, but it is not sufficient for final M3 security closure while implementation/ACL/resource-binding residuals remain open.

| Qualified ID | Task | Operational state | Exit requirement |
|---|---|---|---|
| STS-M3-03-01 | Accepted privileged RPC allowlist baseline | HISTORICAL_ACCEPTED_EVIDENCE | preserve accepted classification universe; no re-audit loop absent invalidator |
| STS-M3-03-02 | Resource-Bound Privileged RPC Remediation | DEFINED_NOT_AUTHORIZED | F-01/F-02 closed; supplied resource UUIDs bound server-side to actor/tenant/object authority |
| STS-M3-03-03 | Tenant-Scoped Analytics RPC Remediation | DEFINED_NOT_AUTHORIZED | F-03 closed; non-root analytics scoped to canonical empresa/time |
| STS-M3-03-04 | Internal-Helper Reachability Convergence | DEFINED_NOT_AUTHORIZED | F-06/F-07 closed/refuted; internal helpers not directly client-reachable |
| STS-M3-03-05 | RPC EXECUTE Principal Convergence | DEFINED_NOT_AUTHORIZED | F-10 closed; anon/authenticated/PUBLIC EXECUTE converges to explicit allowlist |
| STS-M3-03-06 | Independent RPC Authority Closure Review | DEFINED_NOT_AUTHORIZED | zero material RPC authority gaps + zero material NOT_DETERMINED |

Closure rule:

```text
STS-M3-03 FINAL IMPLEMENTATION CLOSURE =
ALLOWLIST COMPLETE
+ IMPLEMENTATION TARGET-COMPLIANT
+ RESOURCE/TENANT BINDING PROVEN
+ EXECUTE PRINCIPALS CONVERGED
+ ZERO MATERIAL RPC AUTHORITY FINDINGS
+ ZERO MATERIAL NOT_DETERMINED
+ INDEPENDENT REVIEW PASS
```

Historical `STS-M3-03 = COMPLETE / ACCEPTED WITH RESIDUALS` remains provenance only and cannot satisfy final M3 closure by itself.

### 7.2 STS-M3-04 expanded execution graph

Product Authority expands `STS-M3-04` from direct-DML reduction alone to a preventive structural multi-tenant safety gate.

```text
STS-M3-04 CANNOT CLOSE
WHILE ANY MATERIAL STRUCTURAL TENANT-A -> TENANT-B PATH REMAINS POSSIBLE
```

The previous 24h estimate is preserved only as historical planning provenance and is no longer controlling.

| Qualified ID | Task | Operational state | Hours |
|---|---|---|---:|
| STS-M3-04-01 | PME message usage RPC-only write boundary | COMPLETE_WITH_RESIDUALS | historical slice |
| STS-M3-04-02 | PME lead message state direct-write reduction | COMPLETE_WITH_RESIDUALS | historical slice |
| STS-M3-04-03 | Global Tenant Surface & Relationship Inventory | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-04 | `lista_avaliacoes` Tenant-Relationship Hardening | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-05 | PME Catalog Tenant-Relationship Hardening | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-06 | Remaining Sensitive Direct-DML Adjudication & Remediation | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-07 | Tenant-Bound Database Invariant Verification | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-08 | Direct-Write / Bypass Call-Site Sweep | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-09 | Structural Cross-Tenant Negative Proofs | DEFINED_NOT_AUTHORIZED | TBD |
| STS-M3-04-10 | Independent AppSec Closure Review | DEFINED_NOT_AUTHORIZED | TBD |

Closure rule:

```text
NO MATERIAL CROSS-TENANT STRUCTURAL GAP
+ NO UNJUSTIFIED SENSITIVE DIRECT-DML GAP
+ ZERO MATERIAL NOT_DETERMINED ROWS
+ INDEPENDENT APPSEC CLOSURE REVIEW
-> STS-M3-04 MAY BE RECOMMENDED FOR PRODUCT AUTHORITY ACCEPTANCE
```

Issue #141 remains the parent program contract; this Product Authority scope amendment is the current FECH.AI granular WBS authority for M3-04.

### 7.3 STS-M3-05 Auth / Admin final closure graph

| Qualified ID | Task | Operational state | Exit requirement |
|---|---|---|---|
| STS-M3-05-01 | Create-user canonical authority convergence | DEFINED_NOT_AUTHORIZED | actor/tenant/role derived server-side; no client authority |
| STS-M3-05-02 | Password-reset / admin authority closure | DEFINED_NOT_AUTHORIZED | target user + tenant + privileged actor bound fail-closed |
| STS-M3-05-03 | Root / admin-local / gestor compatibility cleanup | DEFINED_NOT_AUTHORIZED | no legacy authority path contradicts canonical authority model |
| STS-M3-05-04 | Auth/Admin negative proofs | DEFINED_NOT_AUTHORIZED | unauthorized, cross-tenant and role-escalation attempts denied |
| STS-M3-05-05 | Independent Auth/Admin closure review | DEFINED_NOT_AUTHORIZED | zero material Auth/Admin residual + zero material NOT_DETERMINED |

### 7.4 STS-M3-06 Security staging + service-boundary graph

| Qualified ID | Task | Operational state | Exit requirement |
|---|---|---|---|
| STS-M3-06-01 | Isolated security staging topology + fixtures | AUTHORIZED_DEFERRED / COST_GATED | deterministic non-production hostile-client environment and rollback |
| STS-M3-06-02 | `mesa-worker-proxy` auth/authorization disposition | AUTHORIZED_DEFERRED / DO_NOT_EXECUTE_NOW | F-08 remediated, removed or proven unreachable |
| STS-M3-06-03 | Service-to-service credential / payload / rate boundary | AUTHORIZED_DEFERRED / DO_NOT_EXECUTE_NOW | secret ownership, request-size and abuse/rate boundaries proven |
| STS-M3-06-04 | Hostile-client / cross-tenant harness readiness | AUTHORIZED_DEFERRED / COST_GATED | deterministic identities, fixtures and evidence capture ready |
| STS-M3-06-05 | M3 Final Security Implementation Closure | AUTHORIZED_DEFERRED / FINAL_CLOSURE_HELD | all M3 material findings remediated/refuted + independent closure evidence |

Product Authority deferred-execution decision — 2026-09-09:

```text
STS-M3-06 =
AUTHORIZED_DEFERRED / NOT_STARTED / NOT_CURRENT_ACTION

STS-M5-01 + STS-M5-02 =
AUTHORIZED_DEFERRED_FINAL_TEST / NOT_STARTED / NOT_CURRENT_ACTION

OFFENSIVE LAB =
SYNTHETIC DATA ONLY
NO REAL CUSTOMER/LEAD DATA
NO DESTRUCTIVE ATTACKS IN PRODUCTION

PAID / PRO / CLONED SECURITY ENVIRONMENT =
DO NOT CREATE NOW
EXPLICIT COST CONFIRMATION REQUIRED AT EXECUTION TIME

AUTHORIZATION IS DURABLE
BUT EXECUTION ADMISSION STILL REQUIRES:
fresh bootstrap + exact live refs + isolated environment ready + rollback
+ synthetic identities/fixtures + no production-destructive scope
+ explicit cost confirmation if the environment incurs cost
```

This authorization removes the future need to re-authorize the same bounded task scope solely because time passed. It does **not** make the lab the current action, does not authorize cost incurrence now, and is invalidated/re-scoped if the material target/environment/scope changes.

Final M3 invariant:

```text
FINAL_M3_SECURITY_IMPLEMENTATION_CLOSURE =
STS-M3-03 FINAL IMPLEMENTATION CLOSURE PASS
+ STS-M3-04 PASS
+ STS-M3-05 PASS
+ STS-M3-06 IMPLEMENTATION/BOUNDARY PASS
+ ZERO MATERIAL OPEN IMPLEMENTATION FINDINGS
+ ZERO MATERIAL NOT_DETERMINED
```

`ACCEPTED_WITH_RESIDUALS` remains permitted as historical/intermediate provenance only; it is not a valid final M3 security closure state.

## 8. M4 — Frontend Modularization / App.jsx Extraction — 172h

**Qualified milestone:** `STS-M4`  
**Issue #141 owners:** Architecture + UX/UI + domain specialists  
**Issue #141 window:** 30 Oct–27 Nov  
**State:** PLANNED

| ID | Qualified ID | Task | Hours |
|---|---|---|---:|
| M4-01 | STS-M4-01 | AppShell / Shared Frontend Boundary | 20h |
| M4-02 | STS-M4-02 | CRM + Funil Core Slice | 40h |
| M4-03 | STS-M4-03 | LeadOps Execution Slice — Leads / Listas / Distribuição / Discador / Power Message Engine | 32h |
| M4-04 | STS-M4-04 | MesaCliente Core Slice | 32h |
| M4-05 | STS-M4-05 | Feature Gateways / API Boundaries | 24h |
| M4-06 | STS-M4-06 | Core Functional Equivalence & Regression | 24h |

Issue #141 acceptance remains semantic: AppShell must not own business authority; line count alone is not acceptance.

M4 acceptance preserves:

```text
APP.JSX_SMALLER != M4_PASS
MODULE_EXTRACTED != FUNCTIONAL_PASS
FUNCTIONAL_PASS != SECURITY_GO
```

M4-06 cannot close without accepted functional-equivalence evidence for CRM, Funil, Discador, Power Message Engine and MesaCliente, including their material shared Leads/Listas/Distribuição dependencies. No tenant, role, ownership or sensitive business authority may be moved to the frontend during extraction.

### 8.1 M4 security non-regression map — all subtasks

M4 remains architecture/product modularization. Every M4 child has an explicit security contract so frontend extraction cannot reintroduce authority or tenant-boundary defects already closed in M3.

| Qualified ID | Structural task | Security/non-regression obligation |
|---|---|---|
| STS-M4-01 | AppShell / Shared Frontend Boundary | AppShell owns navigation/session presentation only; no tenant/role/ownership/financial/privileged authority is decided client-side |
| STS-M4-02 | CRM + Funil Core Slice | consume hardened Lead/Funil server contracts; preserve tenant/ownership/history boundaries and no direct-write regression |
| STS-M4-03 | LeadOps Execution Slice | preserve Leads/Listas/Distribuição/Discador/PME tenant invariants; no reintroduction of sensitive direct DML or client authority |
| STS-M4-04 | MesaCliente Core Slice | preserve MesaCliente tenant/resource binding; no UI-only approval/admin boundary; service calls remain authenticated/authorized |
| STS-M4-05 | Feature Gateways / API Boundaries | all privileged gateways consume M3 hardened APIs/RPCs; auth/tenant/role checks remain server-side |
| STS-M4-06 | Core Functional Equivalence & Regression | prove product equivalence plus changed-boundary security regression across CRM, Funil, LeadOps/PME and MesaCliente |

M4 closure rule:

```text
M4 FUNCTIONAL EQUIVALENCE PASS
+ ALL SIX M4 SECURITY NON-REGRESSION OBLIGATIONS PASS
+ ZERO NEW MATERIAL CLIENT-AUTHORITY REGRESSION
+ ZERO NEW MATERIAL TENANT/OWNERSHIP BYPASS
= STS-M4 PASS
```

Any material M4 security regression reopens the owning M3 control or creates a bounded remediation child before M4 may close.

## 9. M5 — Integrated Security / Reliability Validation — REBASELINE_REQUIRED

**Issue #141 owners:** AppSec + Platform/CI-CD + SRE/Observability + Backend/Data  
**Issue #141 original window:** 27 Nov–11 Dec  
**State:** PLANNED / NOT_AUTHORIZED  
**Historical M5 planning total:** 128h  
**Current planning status:** `REBASELINE_REQUIRED`

| ID | Qualified ID | Task | Hours / planning state |
|---|---|---|---:|
| M5-00 | STS-M5-00 | Global Security Assurance Coverage Reconciliation | REBASELINE_REQUIRED |
| M5-01 | STS-M5-01 | Hostile-client suite isolada | 28h / AUTHORIZED_DEFERRED_FINAL_TEST |
| M5-02 | STS-M5-02 | Regressão tenant / role / auth / storage | 28h / AUTHORIZED_DEFERRED_FINAL_TEST |
| M5-03 | STS-M5-03 | Dependency / CVE gate | 12h |
| M5-04 | STS-M5-04 | Secrets / config / deploy gate | 16h |
| M5-05 | STS-M5-05 | Observabilidade / rollback / incidente | 24h |
| M5-06 | STS-M5-06 | Material Residual Elimination Gate | REBASELINE_REQUIRED |
| M5-07 | STS-M5-07 | Independent Integrated AppSec Final Review | REBASELINE_REQUIRED |

`STS-M5-00` is the mandatory cross-program reconciliation gate that maps all prior accepted work and all material attack classes into current assurance coverage before integrated hostile-client validation can be considered complete.

The early catalog/documentation foundation created before M5 does not start M5 and does not count as runtime assurance.

Issue #141 exit remains authoritative for M5.

### 9.1 M5 integrated assurance map — all subtasks

| Qualified ID | Task | Mandatory outcome |
|---|---|---|
| STS-M5-00 | Global Security Assurance Coverage Reconciliation | every material attack class/finding mapped to current proof; no unmapped material artifact/finding |
| STS-M5-01 | Isolated hostile-client suite | current tenant/auth/authority/service exploit attempts fail as designed |
| STS-M5-02 | Tenant / role / auth / storage regression | cross-tenant, ownership, role and storage boundaries pass current runtime regression |
| STS-M5-03 | Dependency / CVE gate | no unremediated material dependency vulnerability in launch scope |
| STS-M5-04 | Secrets / config / deploy / migration gate | no material secret/config/default-ACL/deploy/migration exposure; includes F-09 proof |
| STS-M5-05 | Observability / rollback / incident readiness | detection, auditability, rollback and incident response paths proven |
| STS-M5-06 | Material Residual Elimination Gate | ZERO MATERIAL OPEN SECURITY FINDINGS and ZERO MATERIAL NOT_DETERMINED |
| STS-M5-07 | Independent Integrated AppSec Final Review | independent PASS required before M6 nomination |

### 9.2 Deferred final offensive-test sequencing

Product Authority intentionally defers the **active offensive laboratory execution** until the end of the technical test sequence so FECH.AI can continue task-by-task without incurring the isolated-environment cost now.

```text
NORMAL WORK CONTINUES TASK-BY-TASK
→ complete M3/M4 implementation and non-offensive proof obligations
→ STS-M5-00 coverage reconciliation
→ STS-M5-03 dependency/CVE gate
→ STS-M5-04 secrets/config/deploy/migration gate
→ STS-M5-05 observability/rollback/incident evidence
→ all other applicable non-offensive technical test suites complete
→ FINAL LAB ECONOMIC/ENVIRONMENT GATE
   - Supabase isolated clone/branch capability available
   - explicit cost confirmation by Product Authority
   - synthetic-only fixtures
   - rollback/teardown ready
→ STS-M3-06-01 / STS-M3-06-04 lab + harness readiness
→ close any remaining STS-M3-06-02 / 03 service-boundary prerequisites
→ STS-M5-01 isolated hostile-client offensive suite
→ STS-M5-02 tenant / role / auth / storage adversarial regression
→ STS-M5-06 material residual elimination/adjudication
→ STS-M5-07 independent integrated AppSec final review
→ M6 candidate gates
```

Therefore STS-M5-01 and STS-M5-02 are the **last active technical attack/test execution**, while STS-M5-06, STS-M5-07 and M6 remain mandatory post-test closure/adjudication gates. No attack is authorized against production beyond non-destructive production-safe checks separately admitted by the applicable gate.

The existing isolated-lab concept is reused; do not create a parallel lab track. Historical security planning already requires a separate Supabase security lab/branch only after cost confirmation.

M5 closure rule:

```text
NO CRITICAL OPEN
+ NO HIGH OPEN
+ NO MATERIAL MEDIUM OPEN
+ NO MATERIAL LOW OPEN THAT INVALIDATES A SECURITY INVARIANT
+ ZERO MATERIAL NOT_DETERMINED
+ CURRENT MAIN/DEPLOY/RUNTIME TEST EVIDENCE
+ INDEPENDENT APPSEC PASS
= STS-M5 PASS
```

A non-material low/informational item may remain only with explicit AppSec proof that it violates no Security Go invariant and with a bounded post-launch owner. It cannot hide tenant isolation, authorization, authentication, privileged DML, secrets/config, runtime or deployment risk.

## 10. M6 — Security Go Candidate / Commercial Readiness — 60h

**Qualified milestone:** `STS-M6`  
**Issue #141 owners:** Product Authority + AppSec + Backend/Data + Architecture + SRE  
**Issue #141 window:** 11–18 Dec  
**State:** PLANNED

| ID | Qualified ID | Task | Hours |
|---|---|---|---:|
| M6-01 | STS-M6-01 | Security Evidence + Final AS-BUILT Package | 14h |
| M6-02 | STS-M6-02 | Blocker closeout | 8h |
| M6-03 | STS-M6-03 | Onboarding / support / operational runbooks | 18h |
| M6-04 | STS-M6-04 | Decisão comercial controlada | 8h |
| M6-05 | STS-M6-05 | Launch readiness + AS-BUILT acceptance review | 12h |

### 10.1 M6 Security Go candidate map — all subtasks

| Qualified ID | Task | Security-specific exit requirement |
|---|---|---|
| STS-M6-01 | Security Evidence + Final AS-BUILT Package | all material M3/M4/M5 evidence indexed, immutable-provenanced and current |
| STS-M6-02 | Blocker closeout | zero material security blocker, zero material open finding, zero material NOT_DETERMINED |
| STS-M6-03 | Onboarding / support / operational runbooks | support/admin operations cannot bypass tenant/authority/security controls |
| STS-M6-04 | Controlled commercial decision | commercial expansion only after technical/security closure evidence |
| STS-M6-05 | Launch readiness + AS-BUILT acceptance review | Product Authority may consider Security Go only after independent integrated PASS |

```text
M6 CANDIDATE PRECONDITION =
FINAL_M3_SECURITY_IMPLEMENTATION_CLOSURE PASS
+ M4 SECURITY NON-REGRESSION PASS
+ STS-M5 PASS
+ SECURITY ASSURANCE COVERAGE COMPLETE FOR MATERIAL CLASSES
+ CURRENT MAIN / DEPLOY / RUNTIME PROVENANCE
+ ZERO MATERIAL OPEN SECURITY FINDINGS

M6 DOES NOT WAIVE OPEN MATERIAL SECURITY FINDINGS
M6 DOES NOT CONVERT NOT_DETERMINED INTO PASS
```


The professional AS-BUILT package must provide an indexed launch-scope view of system context, tenant/identity/authority, database contract, API/RPC/Edge boundaries, frontend/core slices, deployment topology, observability, backup/restore understanding, rollback, incident response, residual risks and specialist/operational ownership.

Security Go and controlled commercialization remain separate Product Authority decisions.

## 11. Separate pre-Security-Go backlog — 116h

These items remain separate from the 832h critical path.

| ID | Task | Hours | State |
|---|---|---:|---|
| BG-01 | OC-01 leaked-password control | 14h | PARKED |
| BG-02 | Harden three Root RPC grants | 10h | PARKED |
| BG-03 | Version baseline of critical helpers | 18h | PARKED |
| BG-04 | Root/Admin Global contract rollout / Issue #133 | 32h | PARKED |
| BG-05 | Team Lifecycle Authority / Issue #135 | 24h | PARKED |
| BG-06 | Explicit audited Root support mode by tenant | 18h | PARKED |

A parked item is not waived, passed or authorized.

## 12. Separate planned/future backlog — 104h

| ID | Task | Hours | State |
|---|---|---:|---|
| PL-01 | Global funnel-stage capability, se o produto exigir | 20h | PARKED |
| PL-02 | Import / UX enhancements além do security scope | 16h | PARKED |
| PL-03 | App.jsx cleanup além dos vertical slices aprovados | 24h | PARKED |
| PL-04 | Observability / dashboard polish | 16h | PARKED |
| PL-05 | CRM productivity / UX improvements | 28h | PARKED |

## 13. Current continuation boundary

Current Product Authority / SFJM program position at this WBS amendment:

```text
STS-M1 =
COMPLETE WITH DEFERRED SECURITY ASSURANCE

STS-M2 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED

STS-M3-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-03 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-04 =
ACTIVE / SCOPE_EXPANDED / REBASELINE_REQUIRED

STS-M3-04-01 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-04-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-04-03..10 =
DEFINED / NOT_AUTHORIZED

STS-M3-05 =
PLANNED / NOT_AUTHORIZED

STS-M3-06 =
PLANNED / NOT_AUTHORIZED

STS-M4..STS-M6 =
PLANNED / NOT_AUTHORIZED

Security Go =
NOT_GRANTED
```

The canonical dashboard relationship layer is:

```text
WBS task / Qualified ID
<-> docs/sfjm/PROGRAM_TASK_GRAPH.md
<-> docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json
<-> docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json
```

No future task execution, implementation, test run, deploy or Security Go is authorized by this WBS amendment.

## 14. Provenance

Program milestone contract:
- FECH.AI Issue #141 — Security-to-Scale 2026.

Granular planning source used before FECH.AI canonicalization:
- Product Authority-approved WBS represented in `wagnerjfjunior/sfjm-workspace` PR #27;
- exact evidence head at canonicalization: `d13ee49ae86225db89c6f81c015051be2f90334e`;
- exact WBS file: `data/workspace-demo.ts`;
- exact WBS blob: `980549bb35c429be89ef22f6ce1dd0e52f9a2190`.

After this file is merged into FECH.AI `main`, the Workspace remains a derived representation and must not become authority for FECH.AI roadmap/state.
