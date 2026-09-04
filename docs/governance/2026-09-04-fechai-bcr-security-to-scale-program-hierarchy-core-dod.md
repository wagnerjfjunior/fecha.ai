# FECH.AI — BCR-2026-09-04 — Program Hierarchy, Core Finish Line and WBS Adjudication

**Status:** `PRODUCT_AUTHORITY_ADJUDICATION / DOCUMENTATION_ONLY / ACTIVE_ON_MAIN_WHEN_MERGED / CANDIDATE_ON_PR_170_BEFORE_MERGE`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Decision base main:** `2bad8e9c3d6d6e091a6416c556e793eb1b24e0ec`  
**PR:** `#170`  
**Decision date:** `2026-09-04`  
**Primary risk:** `PROGRAM_AUTHORITY_AMBIGUITY / CONTEXT_REGRESSION`

## 1. Purpose

This Baseline Change Record resolves the hierarchy among FECH.AI product-capability documents, the July B0 delivery baseline, the Security-to-Scale 2026 program, the granular 832h WBS, SFJM continuity and the SFJM Workspace representation.

It also fixes the current Security-to-Scale core finish line, the final M4 vertical-slice segmentation and the M6 professional AS-BUILT obligation.

This is a governance/continuity decision. It does not start STS-M2, authorize implementation, grant Security Go or mutate runtime, Supabase, Vercel, data, SES or the SFJM protocol.

## 2. Why a BCR is required

The July B0 baseline explicitly requires a Baseline Change Record before changing active scope, weight, dates, dependencies or acceptance semantics, while preserving B0 immutably for comparison.

Current FECH.AI documentation contains several valid historical namespaces that reuse `M1…M6`:

```text
PRODUCT MODULES:
  M1 LeadOps / CRM / Discador
  M2 ADS / Tracking
  M3 MesaCliente
  M4 Integrations
  M5 Observability / Operation
  M6 Monetization / GTM

B0 DELIVERY BASELINE:
  M1 Truth and Security Gate
  M2 Family Core Build
  M3 Family Validation / MVP2 Admission
  M4 Wislane Controlled Pilot
  M5 Caminhos / Market Preparation
  M6 Controlled Market Readiness

SECURITY-TO-SCALE #141:
  M0 Program Control
  M1 Security Truth Baseline
  M2 Database Simplification
  M3 Backend Authority
  M4 Frontend Modularization
  M5 Integrated Security / Reliability
  M6 Security Go Candidate
```

An unqualified `M2`, for example, is therefore ambiguous across canonical documents.

## 3. Adjudicated hierarchy

When this BCR is present on canonical `main`, use the following hierarchy:

```text
FECH.AI canonical project/runtime sources
= product, code, applied/runtime and current-state truth in their respective scopes

docs/product/fechai-modules-map-v1.md
+ docs/roadmap/fechai-roadmap-master-v1.md
= PRODUCT CAPABILITY / PRODUCT VISION REFERENCES
= NOT CURRENT EXECUTION BASELINE

B0 / 300 WDP governance baseline
= IMMUTABLE HISTORICAL DELIVERY BASELINE / COMPARISON RECORD
= NOT CURRENT EXECUTION BASELINE AFTER THIS BCR
= REQUIREMENTS ARE NOT SILENTLY WAIVED

Issue #141 — Security-to-Scale 2026
= CURRENT CORE COMPLETION / HARDENING PROGRAM CONTRACT

docs/roadmap/fechai-security-to-scale-2026-wbs.md
= CURRENT GRANULAR EXECUTION BASELINE ON MAIN
= task IDs / planning weights / execution packages

docs/sfjm/*
= CURRENT MATERIAL OPERATIONAL STATE / CONTINUITY
= DOES NOT DEFINE THE PROGRAM BY ITSELF

sfjm-workspace
= DERIVED VISUALIZATION / CONTINUITY UX
= NOT FECH.AI PRODUCT OR PROGRAM AUTHORITY
```

The WBS does not replace the product vision. The product vision does not control current Security-to-Scale progress.

## 4. Qualified naming rule

Historical source documents retain their original labels. New cross-program references must qualify them:

```text
PRODUCT_MODULE_M1 .. PRODUCT_MODULE_M6
B0-M1 .. B0-M6
STS-M0 .. STS-M6
STS-M2-01, STS-M4-03, etc. for granular WBS tasks outside the WBS document
```

Inside the Security-to-Scale WBS itself, short task IDs such as `M2-01` remain valid because the document already establishes the STS namespace.

Do not use an unqualified `M1…M6` in a new cross-program governance/continuity statement when more than one namespace could reasonably apply.

## 5. B0 disposition

B0 remains immutable and visible as the original 300 WDP execution baseline and comparison record.

This BCR changes its current-role classification:

```text
B0_CURRENT_EXECUTION_BASELINE = NO
B0_HISTORICAL_COMPARISON_BASELINE = YES
B0_RETROACTIVE_ERASURE = NO
```

Uncompleted B0 acceptance requirements are not automatically waived. If a B0 requirement remains material to the current launch/core finish line, it must be mapped into:

- the current Security-to-Scale WBS;
- the explicit pre-Security-Go backlog;
- the planned/future backlog; or
- a separately governed future program.

```text
OLD_SCHEDULE_AUTHORITY_REMOVED != REQUIREMENT_SILENTLY_WAIVED
```

## 6. Security-to-Scale mission

Security-to-Scale exists to take an already functioning FECH.AI — built with substantial rapid/vibe-coded evolution and accumulated architecture/security debt — and turn its core into a sellable, operable, secure, modular, observable and professionally documented SaaS without a big-bang rewrite.

The program is organized primarily by shared architectural layers rather than by independent applications:

```text
STS-M1  security truth / critical remediation
STS-M2  whole-database understanding + simplification + contract
STS-M3  shared backend authority contract
STS-M4  frontend vertical-slice modularization
STS-M5  integrated security / reliability validation
STS-M6  Security Go candidate / operational-commercial readiness
```

Discador, CRM, Funil, Power Message Engine and MesaCliente are bounded product contexts/features of the same FECH.AI platform and share Auth, tenant/company, database, backend authority, frontend composition, deploy and observability foundations.

## 7. Core finish line

The Security-to-Scale critical path finishes the FECH.AI **core**, not every future capability.

Core flows that must be operational and regression-proven in launch scope:

```text
CRM
Funil
Discador
Power Message Engine / Aceleração Operacional
MesaCliente
```

Shared LeadOps dependencies that must remain functional where used:

```text
Leads
Listas
Distribuição
responsável/corretor
feedback
próxima ação/follow-up
histórico
```

Secondary/future capabilities are not deleted or declared obsolete by this finish line. Examples include advanced ADS/CAPI/tracking, broader portal integrations, advanced campaign/message automation and full monetization/GTM expansion.

```text
CORE_COMPLETE != EVERY_FUTURE_FEATURE_COMPLETE
OUTSIDE_CORE_FINISH_LINE != RETIRED_CAPABILITY
```

## 8. STS-M4 final segmentation — 172h unchanged

The M4 total and planning weights remain unchanged. The task semantics are clarified:

| WBS ID | Qualified ID | Task | Hours |
|---|---|---|---:|
| M4-01 | STS-M4-01 | AppShell / Shared Frontend Boundary | 20h |
| M4-02 | STS-M4-02 | CRM + Funil Core Slice | 40h |
| M4-03 | STS-M4-03 | LeadOps Execution Slice — Leads / Listas / Distribuição / Discador / Power Message Engine | 32h |
| M4-04 | STS-M4-04 | MesaCliente Core Slice | 32h |
| M4-05 | STS-M4-05 | Feature Gateways / API Boundaries | 24h |
| M4-06 | STS-M4-06 | Core Functional Equivalence & Regression | 24h |

### 8.1 M4 architectural acceptance

```text
APP.JSX_SMALLER != M4_PASS
MODULE_EXTRACTED != FUNCTIONAL_PASS
FUNCTIONAL_PASS != SECURITY_GO
```

M4 requires:

- AppShell limited to composition/router/providers/session projection;
- no tenant, role, ownership or sensitive business authority moved to frontend;
- explicit feature boundaries;
- feature-specific gateway/API boundaries;
- preserved cross-domain state-transition semantics;
- accepted functional equivalence for the core flows.

### 8.2 M4 core equivalence matrix

M4-06 cannot close without explicit accepted evidence for:

| Core flow | Minimum equivalence boundary |
|---|---|
| CRM | lead/context, responsible owner, status, feedback, next action/follow-up, history |
| Funil | stage reads, permitted individual/batch transitions, history and tenant-safe semantics |
| Discador | correct lead/context, call action, outcome/feedback, next action and controlled progression |
| Power Message Engine | context/template/script flow, messaging attempt/history, opt-out/traceability where applicable, feedback integration |
| MesaCliente | empreendimento/unidade/tabela, fluxo, simulação, proposta and history for the accepted launch flow |

Shared Leads/Listas/Distribuição dependencies must remain functional where these flows depend on them.

## 9. STS-M5 role

M5 validates the integrated system produced by M2–M4. Shared-platform security does not by itself prove a feature journey.

M5 must preserve separate evidence for:

```text
tenant / cross-tenant
role / ownership
Auth / Storage
hostile-client paths where isolated testing is required
dependency/CVE
secrets/config/deploy
observability
rollback
incident readiness
core regression
residual-risk adjudication
```

## 10. Professional AS-BUILT obligation

The program finish line requires a professional, indexed AS-BUILT package sufficient for a qualified engineer/specialist to understand and troubleshoot the production architecture without depending exclusively on informal founder/conversation knowledge.

This obligation is owned across M2–M6 and consolidated in M6.

Minimum coverage:

```text
System Context / Architecture Overview
multi-tenant / company model
identity / membership / role / ownership model
trust boundaries
Database Contract Map
tables / routines / policies / triggers / grants
RPC / API / Edge / external authority boundaries
frontend/AppShell + core feature-slice architecture
CRM / Funil / Discador / Power Message / MesaCliente boundaries
deployment topology
Vercel / Supabase boundaries
configuration/secrets ownership without exposing secrets
observability / alerting
backup / restore understanding and RTO/RPO
rollback
incident response / escalation
known residual risks
specialist / operational ownership map
canonical runbook and evidence index
```

Exact file decomposition may be decided during execution; the coverage requirement may not be dropped merely because information exists across many historical documents.

## 11. STS-M6 Definition of Done

M6 is not complete merely because the evidence packet exists.

M6 closeout requires a launch-scope decision demonstrating, without overclaim:

1. STS-M2 database contract/architecture decision completed;
2. STS-M3 backend authority contract completed;
3. STS-M4 core slices modularized with functional equivalence evidence;
4. STS-M5 integrated security/reliability gate completed with residual risks classified;
5. professional AS-BUILT package indexed and accepted for launch scope;
6. onboarding/support/rollback/incident response documented;
7. no unresolved `BLOCKING` / `REQUIRED` finding in launch scope, unless Product Authority explicitly narrows or defers that scope with recorded residual risk;
8. Security Go remains a distinct decision based on evidence;
9. controlled paid commercialization remains a distinct Product Authority decision.

A completed milestone or green build cannot substitute for this evidence.

## 12. Specialist ownership model

Current routing remains project-owned/SES-mediated.

For the critical path, resolve current canonical routing at execution time. Conceptually:

```text
Architecture      -> current adopted SES architecture role
Backend/Data      -> current adopted SES backend_data role
AppSec            -> current adopted SES application_security role
UX/UI             -> current adopted SES ux_ui role
LeadOps/CRM       -> current adopted SES lead_operations role + FECH.AI local rules
MesaCliente       -> current FECH.AI local MesaCliente specialist until separately adopted in SES
CI/CD             -> current FECH.AI local CI/CD specialist unless later adopted
SRE/Observability -> current FECH.AI local SRE specialist unless later adopted
Documentation     -> current adopted SES documentation_audit role
```

Certification/adoption does not grant mutation authority.

## 13. Planning impact

This adjudication changes semantics/precedence, not the approved planning total:

```text
CRITICAL_PATH_TOTAL = 832h
M4_TOTAL = 172h
CURRENT_ACCEPTED_COMPLETE = 204h
REMAINING_CRITICAL_PATH = 628h
```

No effort is re-earned or erased by this BCR. Any future material weight/scope change requires its own governed decision.

## 14. Current state at this decision

```text
STS-M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
STS-M2 = ELIGIBLE / NOT STARTED
STS-M2-01 = 43-table canonicality matrix / scope reconstruction next
Security Go = NOT_GRANTED
STS-M2 implementation = NOT_AUTHORIZED
PR #170 = DRAFT / candidate documentation until merged
```

M1 deferred evidence remains unchanged:

```text
J4 environment-dependent evidence = DEFERRED
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
```

## 15. Evidence basis

The adjudication is grounded in the exact FECH.AI main and PR #170 source set reconstructed before this correction, including:

- Issue #141 — Security-to-Scale 2026;
- B0 baseline and governance index;
- product module map and Roadmap Mestre;
- A1/A2 AS-IS architecture baseline;
- LeadOps/CRM/Discador MVP evidence;
- Power Message Engine and Discador Flow specifications;
- MesaCliente project-local architecture/specialist evidence;
- SRE/observability/bootstrap requirements;
- current SFJM authority model;
- current SES Project Adapter/adoption/certification/manual-handoff semantics;
- StopJuniorMode/SFJM continuity protocol;
- sfjm-workspace main and PR #27 candidate representation.

## 16. Non-authorizations

This BCR does not authorize:

```text
STS-M2 implementation
runtime/frontend refactor
Supabase/Auth/DDL/DML/migration/RLS/policy/grant/RPC changes
production/data mutation
Vercel/deploy
SES or Project Adapter changes
StopJuniorMode/SFJM protocol changes
sfjm-workspace mutation
Security Go
Ready
merge
```
