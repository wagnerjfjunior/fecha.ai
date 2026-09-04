# FECH.AI — Security-to-Scale 2026 — Canonical Program WBS

**Status:** `CANONICAL_ON_MAIN / CANDIDATE_WHILE_ON_PR_HEAD / DOCUMENTATION_ONLY`  
**Program:** Issue #141 — `PROGRAM: FECH.AI Security-to-Scale 2026`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Program authority:** FECH.AI canonical project state + Product Authority  
**Planning baseline canonicalization date:** 2026-09-04

## 1. Purpose

This document is the FECH.AI-owned granular Work Breakdown Structure for the current Security-to-Scale 2026 program.

It exists to prevent roadmap identity drift across conversations, specialists and derived workspaces.

It does not replace Issue #141, SFJM, live GitHub lifecycle, runtime evidence, specialist routing or Product Authority.

## 2. Authority and precedence

```text
Issue #141
= program objective + M0–M6 milestone contract + owners + exit criteria

this file
= FECH.AI-owned granular WBS IDs + planning hours + package boundaries

docs/sfjm/*
= current operational/material state + continuity + evidence/authority boundaries

sfjm-workspace
= derived visualization / continuity representation
```

If this file exists only on a PR head, it is candidate documentation and does not override `main`.
Once merged to FECH.AI `main`, this file is the FECH.AI-owned granular WBS reference for Security-to-Scale 2026.

Preserve:

```text
WBS_TASK_DEFINED != TASK_STARTED
PLANNED != AUTHORIZED
WBS_HOURS != CLOCKED_TIMESHEET
MILESTONE_COMPLETE != SECURITY_GO
WORKSPACE_REPRESENTATION != FECHAI_AUTHORITY
```

## 3. Planning totals

```text
CRITICAL_PATH_TOTAL = 832h
M0 = 36h
M1 = 168h
M2 = 116h
M3 = 152h
M4 = 172h
M5 = 128h
M6 = 60h

CURRENT_ACCEPTED_COMPLETE = 204h
  M0 = 36h
  M1 = 168h

REMAINING_CRITICAL_PATH = 628h

PRE_SECURITY_GO_BACKLOG = 116h
PLANNED_FUTURE_BACKLOG = 104h
```

Backlog hours are separate from the 832h critical path.

Hours are planning estimates for sequencing/capacity visibility, not timesheet evidence and not automatic progress.

## 4. M0 — Program Control / Truth Reconciliation — 36h

**Issue #141 window:** 28 Aug–4 Sep  
**State at canonicalization:** COMPLETE

| ID | Task | Hours |
|---|---|---:|
| M0-01 | Inventário de PRs e continuidade | 8h |
| M0-02 | Pacotes de especialistas e dependências | 8h |
| M0-03 | SFJM / Workspace baseline | 10h |
| M0-04 | Roadmap / governança única | 10h |

Issue #141 exit remains authoritative for M0.

## 5. M1 — Security Truth Baseline / F1-02 — 168h

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

**Issue #141 owners:** Backend/Data + Architecture  
**Issue #141 window:** 18 Sep–9 Oct  
**Current state:** ELIGIBLE / NOT STARTED

| ID | Task | Hours |
|---|---|---:|
| M2-01 | Matriz de 43 tabelas | 20h |
| M2-02 | Mapa routines / policies / triggers / grants | 24h |
| M2-03 | Índices / ACL contraditórias | 16h |
| M2-04 | Política target de DEFINER / RLS / DML | 20h |
| M2-05 | Database Contract Map | 20h |
| M2-06 | Decisão arquitetural do banco | 16h |

Issue #141 exit contract remains authoritative:

- 43-table canonicality matrix: `KEEP / CONSOLIDATE / RETIRE / REMODEL / INTERNAL`;
- routine/policy/trigger/grant map with owner/caller/tenant/write authority;
- redundant index and contradictory ACL candidates using live statistics where required;
- target policy for SECURITY DEFINER, triggers, RLS and direct DML;
- Database Contract Map;
- decision `EVOLVE_IN_PLACE vs V2_STRANGLER vs NEW_DATABASE`, with evidence.

## 7. M3 — Backend Authority Contract Freeze — 152h

**Issue #141 owners:** Backend/Data + AppSec + Architecture  
**Issue #141 window:** 9–30 Oct  
**State:** PLANNED

| ID | Task | Hours |
|---|---|---:|
| M3-01 | Identity / membership / team / role model | 24h |
| M3-02 | Authority contract por contexto | 28h |
| M3-03 | Allowlist de RPCs privilegiadas | 24h |
| M3-04 | Redução de DML sensível direto | 24h |
| M3-05 | Fechamento Auth / Admin flows | 24h |
| M3-06 | Staging / test plan de segurança | 28h |

Issue #141 exit remains authoritative for M3.

## 8. M4 — Frontend Modularization / App.jsx Extraction — 172h

**Issue #141 owners:** Architecture + UX/UI + domain specialists  
**Issue #141 window:** 30 Oct–27 Nov  
**State:** PLANNED

| ID | Task | Hours |
|---|---|---:|
| M4-01 | AppShell boundary | 20h |
| M4-02 | Slice Leads / Funil | 40h |
| M4-03 | Slice Listas / Distribuição | 32h |
| M4-04 | Slice MesaCliente | 32h |
| M4-05 | Gateways / API por feature | 24h |
| M4-06 | Equivalence / regressão | 24h |

Issue #141 acceptance remains semantic: AppShell must not own business authority; line count alone is not acceptance.

## 9. M5 — Integrated Security / Reliability Validation — 128h

**Issue #141 owners:** AppSec + Platform/CI-CD + SRE/Observability + Backend/Data  
**Issue #141 window:** 27 Nov–11 Dec  
**State:** PLANNED

| ID | Task | Hours |
|---|---|---:|
| M5-01 | Hostile-client suite isolada | 28h |
| M5-02 | Regressão tenant / role / auth / storage | 28h |
| M5-03 | Dependency / CVE gate | 12h |
| M5-04 | Secrets / config / deploy gate | 16h |
| M5-05 | Observabilidade / rollback / incidente | 24h |
| M5-06 | Adjudicação de residual risk | 20h |

Issue #141 exit remains authoritative for M5.

## 10. M6 — Security Go Candidate / Commercial Readiness — 60h

**Issue #141 owners:** Product Authority + AppSec + Backend/Data + Architecture + SRE  
**Issue #141 window:** 11–18 Dec  
**State:** PLANNED

| ID | Task | Hours |
|---|---|---:|
| M6-01 | Evidence packet | 14h |
| M6-02 | Blocker closeout | 8h |
| M6-03 | Onboarding / support / runbooks | 18h |
| M6-04 | Decisão comercial controlada | 8h |
| M6-05 | Launch readiness review | 12h |

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

At this canonicalization:

```text
M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
M2 = ELIGIBLE / NOT STARTED
M2-01 = MATRIZ DE 43 TABELAS / 20h
M2-01 execution = NOT_AUTHORIZED
```

The next semantic action is bounded M2-01 scope/evidence reconstruction under FECH.AI bootstrap and current specialist routing. It is preparation/read-only unless separate Product Authority authority explicitly permits mutation.

## 14. Provenance

Program milestone contract:
- FECH.AI Issue #141 — Security-to-Scale 2026.

Granular planning baseline canonicalized here:
- Product Authority-approved WBS represented in `wagnerjfjunior/sfjm-workspace` PR #27;
- exact evidence head at canonicalization: `d13ee49ae86225db89c6f81c015051be2f90334e`;
- exact WBS file: `data/workspace-demo.ts`;
- exact WBS blob: `980549bb35c429be89ef22f6ce1dd0e52f9a2190`.

After this file is merged into FECH.AI `main`, the Workspace remains a derived representation and must not become authority for FECH.AI roadmap/state.
