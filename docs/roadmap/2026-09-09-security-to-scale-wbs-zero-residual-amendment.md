# FECH.AI — Security-to-Scale 2026 — Zero Material Residual Security Amendment

**Status:** `PRODUCT_AUTHORITY_DIRECTION / CANDIDATE_WBS_AMENDMENT / DOCUMENTATION_ONLY`  
**Date:** 2026-09-09  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Decision base main:** `ac20a30fea9095f036d8d466e83794432d58ca89`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`

## 1. Product Authority decision

The FECH.AI Security-to-Scale program is rebaselined so that historical/intermediate `ACCEPTED_WITH_RESIDUALS` states may remain as provenance, but no material security residual may survive the final closure of the implementation and assurance chain.

```text
HISTORICAL_ACCEPTED_WITH_RESIDUALS = PRESERVED AS PROVENANCE

FINAL_M3_SECURITY_IMPLEMENTATION_CLOSURE =
ZERO MATERIAL OPEN IMPLEMENTATION FINDINGS

FINAL_M5_INTEGRATED_SECURITY_CLOSURE =
ZERO MATERIAL OPEN SECURITY FINDINGS
+ ZERO MATERIAL NOT_DETERMINED SECURITY ROWS
+ CURRENT RUNTIME / HOSTILE-CLIENT PROOF
+ INDEPENDENT APPSEC PASS

STS-M6 SECURITY_GO_CANDIDATE =
ONLY IF M5 FINAL SECURITY CLOSURE = PASS

ACCEPTED_WITH_RESIDUALS != FINAL SECURITY CLOSURE
```

A finding is material when it can affect tenant isolation, authorization, authentication, privileged mutation, secrets, deploy/runtime boundaries, data integrity, cross-tenant confidentiality/integrity/availability, or another Security Go attack class.

## 2. Audit input frozen into the WBS

The 2026-09-09 live audit established ten actionable findings. They become tracked WBS inputs rather than advisory notes.

| Finding | Severity | Material subject | Required WBS destination |
|---|---|---|---|
| F-01 | HIGH | `aprovar_rejeitar_mesa` resource/tenant binding | STS-M3-03 remediation wave |
| F-02 | HIGH | `relatorio_fornecedor` cross-tenant read | STS-M3-03 remediation wave |
| F-03 | HIGH | global manager analytics RPCs | STS-M3-03 remediation wave |
| F-04 | HIGH | `lista_avaliacoes` tenant relationship integrity | STS-M3-04-04 / 07 / 09 |
| F-05 | HIGH | PME catalog tenant relationship integrity | STS-M3-04-05 / 07 / 09 |
| F-06 | MEDIUM | `lead_tem_acao_real` direct client reachability | STS-M3-03 remediation wave |
| F-07 | LOW | `acquire_lote_lock` anonymous/internal-helper reachability | STS-M3-03 remediation wave |
| F-08 | MEDIUM | unauthenticated `mesa-worker-proxy` service boundary | STS-M3-06 service boundary hardening |
| F-09 | MEDIUM | fail-open future default privileges | STS-M3-04-06 / 07 + M5 migration gate |
| F-10 | LOW | broad anon-executable RPC surface | STS-M3-03 remediation wave |

No listed material finding may disappear from continuity without one of:

```text
REMEDIATED + VERIFIED
REFUTED BY FRESH EVIDENCE
DUPLICATE OF A STRONGER TRACKED FINDING
NOT MATERIAL, WITH EXPLICIT APPSEC JUSTIFICATION
```

## 3. New M3 structure — implementation closure, not only classification

### 3.1 STS-M3-03 — Privileged RPC Allowlist + Implementation Convergence

The accepted allowlist remains frozen evidence, but STS-M3-03 receives an implementation-convergence execution graph.

| Qualified ID | Task | Exit requirement |
|---|---|---|
| STS-M3-03-01 | Accepted privileged RPC allowlist baseline | historical accepted evidence preserved |
| STS-M3-03-02 | Resource-bound privileged RPC remediation | F-01 and F-02 remediated; supplied UUIDs tenant/object-bound server-side |
| STS-M3-03-03 | Tenant-scoped analytics RPC remediation | F-03 remediated; non-root manager analytics tenant/time scoped |
| STS-M3-03-04 | Internal-helper reachability convergence | F-06/F-07 remediated or refuted; INTERNAL helpers not client-reachable |
| STS-M3-03-05 | RPC EXECUTE principal convergence | F-10; client/anon ACLs converge to accepted allowlist |
| STS-M3-03-06 | Independent RPC authority closure review | zero material RPC authority gaps and zero material NOT_DETERMINED rows |

Closure rule:

```text
STS-M3-03 FINAL IMPLEMENTATION CLOSURE
=
ALLOWLIST COMPLETE
+ IMPLEMENTATION TARGET-COMPLIANT
+ RESOURCE/TENANT BINDING PROVEN
+ EXECUTE PRINCIPALS CONVERGED
+ ZERO MATERIAL RPC AUTHORITY FINDINGS
+ INDEPENDENT REVIEW
```

Historical `STS-M3-03 = COMPLETE / ACCEPTED WITH RESIDUALS` remains provenance only and is not sufficient for final M3 security closure.

### 3.2 STS-M3-04 — Direct DML + Structural Multi-Tenant Integrity

Existing expanded graph is preserved and strengthened:

| Qualified ID | Task | Audit binding |
|---|---|---|
| STS-M3-04-01 | PME message usage RPC-only write boundary | historical slice |
| STS-M3-04-02 | PME lead message state direct-write reduction | historical slice |
| STS-M3-04-03 | Global Tenant Surface & Relationship Inventory | close the full live tenant-relation universe |
| STS-M3-04-04 | `lista_avaliacoes` Tenant-Relationship Hardening | F-04 |
| STS-M3-04-05 | PME Catalog Tenant-Relationship Hardening | F-05 |
| STS-M3-04-06 | Remaining Sensitive Direct-DML + Default-Privilege Remediation | F-09 + any newly discovered direct-write gap |
| STS-M3-04-07 | Tenant-Bound Database Invariant Verification | prove composite/trigger/invariant enforcement live |
| STS-M3-04-08 | Direct-Write / Bypass Call-Site Sweep | prove no frontend/backend bypass path remains |
| STS-M3-04-09 | Structural Cross-Tenant Negative Proofs | isolated Tenant-A -> Tenant-B negative suite |
| STS-M3-04-10 | Independent AppSec Closure Review | zero material structural gaps |

Strengthened closure rule:

```text
STS-M3-04 CANNOT CLOSE WITH A MATERIAL RESIDUAL

NO MATERIAL CROSS-TENANT STRUCTURAL GAP
+ NO UNJUSTIFIED SENSITIVE DIRECT-DML GAP
+ FAIL-CLOSED FUTURE OBJECT DEFAULTS OR EQUIVALENT PROVEN GATE
+ ZERO MATERIAL NOT_DETERMINED ROWS
+ NEGATIVE PROOFS PASS
+ INDEPENDENT APPSEC CLOSURE REVIEW
= PASS
```

### 3.3 STS-M3-05 — Auth / Admin Flow Closure

Expand final acceptance so no material Auth/Admin residual is merely carried forward.

| Qualified ID | Task | Exit requirement |
|---|---|---|
| STS-M3-05-01 | Create-user canonical authority convergence | server-derived actor/tenant/role |
| STS-M3-05-02 | Password reset/admin authority closure | target user + tenant + privileged actor binding |
| STS-M3-05-03 | Root/admin-local/gestor compatibility cleanup | no legacy authority path contradicts canonical model |
| STS-M3-05-04 | Auth/Admin negative proofs | unauthorized/cross-tenant/role-escalation tests |
| STS-M3-05-05 | Independent Auth/Admin closure review | zero material Auth/Admin residual |

### 3.4 STS-M3-06 — Security Staging + Service Boundary Hardening

| Qualified ID | Task | Exit requirement |
|---|---|---|
| STS-M3-06-01 | Isolated security staging topology and fixtures | no production offensive testing required |
| STS-M3-06-02 | `mesa-worker-proxy` authentication/authorization disposition | F-08 remediated, removed, or proved unreachable |
| STS-M3-06-03 | Service-to-service credential / payload / rate boundary | bounded secrets, body size, rate and owner |
| STS-M3-06-04 | Hostile-client / cross-tenant test harness readiness | deterministic test identities and rollback |
| STS-M3-06-05 | M3 final security implementation closure | all M3 material findings resolved before M4/M5 assurance consumption |

## 4. M4 — frontend modularization with security non-regression

M4 remains primarily architectural/product work, but **all six structural subtasks now carry an explicit security non-regression obligation**.

| Qualified ID | Structural task | Security/non-regression obligation |
|---|---|---|
| STS-M4-01 | AppShell / Shared Frontend Boundary | AppShell owns navigation/session presentation only; no tenant/role/ownership/financial/privileged authority is decided client-side |
| STS-M4-02 | CRM + Funil Core Slice | consume hardened Lead/Funil server contracts; preserve tenant/ownership/history boundaries and prevent sensitive direct-write regression |
| STS-M4-03 | LeadOps Execution Slice | preserve Leads/Listas/Distribuição/Discador/PME tenant invariants; no reintroduction of direct sensitive DML or browser authority |
| STS-M4-04 | MesaCliente Core Slice | preserve resource/tenant binding; no UI-only approval/admin boundary; service calls remain authenticated and authorized |
| STS-M4-05 | Feature Gateways / API Boundaries | every privileged gateway consumes hardened M3 APIs/RPCs and keeps auth/tenant/role checks server-side |
| STS-M4-06 | Core Functional Equivalence & Regression | prove product equivalence plus changed-boundary security regression across CRM, Funil, LeadOps/PME and MesaCliente |

```text
FRONTEND EXTRACTION MUST NOT
MOVE TENANT / ROLE / OWNERSHIP / FINANCIAL / PRIVILEGED AUTHORITY TO CLIENT

M4 PASS REQUIRES =
FUNCTIONAL EQUIVALENCE
+ ALL SIX M4 SECURITY NON-REGRESSION OBLIGATIONS PASS
+ ZERO NEW MATERIAL CLIENT-AUTHORITY REGRESSION
+ ZERO NEW MATERIAL TENANT/OWNERSHIP BYPASS
```

Any newly discovered material authorization or tenant-isolation regression during M4 reopens the owning M3 closure item or creates a bounded remediation child before M4 can close.

## 5. New M5 structure — proof and zero-material-open gate

`STS-M5-06` is no longer interpreted as permission to carry material residuals into launch.

| Qualified ID | Task | Required outcome |
|---|---|---|
| STS-M5-00 | Global Security Assurance Coverage Reconciliation | every material attack class/finding mapped to current proof |
| STS-M5-01 | Isolated hostile-client suite | current exploit attempts fail as designed |
| STS-M5-02 | Tenant / role / auth / storage regression | cross-tenant and privilege boundaries pass |
| STS-M5-03 | Dependency / CVE gate | no unaccepted material dependency vulnerability |
| STS-M5-04 | Secrets / config / deploy / migration gate | no material secret/config/default-ACL/deploy exposure |
| STS-M5-05 | Observability / rollback / incident readiness | detection + rollback + incident path proven |
| STS-M5-06 | **Material Residual Elimination Gate** | **ZERO MATERIAL OPEN SECURITY FINDINGS** |
| STS-M5-07 | Independent Integrated AppSec Final Review | PASS required to nominate M6 |

M5 closure rule:

```text
NO CRITICAL OPEN
+ NO HIGH OPEN
+ NO MATERIAL MEDIUM OPEN
+ NO MATERIAL LOW OPEN THAT INVALIDATES A SECURITY INVARIANT
+ ZERO MATERIAL NOT_DETERMINED
+ CURRENT TEST EVIDENCE
+ INDEPENDENT APPSEC PASS
= STS-M5 PASS
```

A non-material low/informational item may remain only when AppSec explicitly proves that it does not violate a Security Go invariant and records a bounded post-launch owner. It must not be used to hide tenant isolation, authorization, Auth, privileged DML, secret/config, runtime or deployment risk.

## 6. New M6 structure — Security Go candidate, not residual adjudication

| Qualified ID | Task | Security-specific exit requirement |
|---|---|---|
| STS-M6-01 | Security Evidence + Final AS-BUILT Package | all M3/M5 evidence indexed and current |
| STS-M6-02 | Blocker closeout | zero material security blocker/open finding |
| STS-M6-03 | Onboarding / support / operational runbooks | support cannot bypass tenant/authority controls |
| STS-M6-04 | Controlled commercial decision | only after technical/security closure |
| STS-M6-05 | Launch readiness + AS-BUILT acceptance | Product Authority may consider Security Go only after independent PASS |

```text
M6 CANDIDATE PRECONDITION =
M3 FINAL SECURITY IMPLEMENTATION CLOSURE PASS
+ M4 SECURITY NON-REGRESSION PASS
+ M5 INTEGRATED SECURITY PASS
+ SECURITY_ASSURANCE_CATALOG COMPLETE FOR MATERIAL CLASSES
+ CURRENT MAIN / DEPLOY / RUNTIME PROVENANCE

M6 DOES NOT WAIVE OPEN MATERIAL SECURITY FINDINGS
```

## 7. Security Go interpretation

The program goal is not to claim mathematical impossibility of all future vulnerabilities. The enforceable target is:

```text
ALL MATERIAL ATTACK CLASSES DISCOVERED BY THE PROGRAM
+ ALL MATERIAL FINDINGS DISCOVERED BY AUDITS
+ ALL MATERIAL TENANT / AUTH / AUTHORITY / DATA-INTEGRITY / CONFIG / DEPLOY RISKS
ARE EITHER REMEDIATED AND VERIFIED OR REFUTED BY FRESH EVIDENCE
BEFORE SECURITY GO.
```

This amendment therefore prohibits a final "approved with material reservations" security posture while preserving honest historical provenance.

## 8. Authorization boundary

This document changes planning/closure semantics only. It does not automatically authorize SQL, migrations, Supabase/Auth/data mutation, runtime changes, deploy, hostile-client production tests, Ready, merge, or Security Go.

Each implementation slice remains separately bounded by Product Authority authorization, exact environment, rollback and validation contract.
