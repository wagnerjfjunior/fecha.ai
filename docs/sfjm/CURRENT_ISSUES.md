# FECH.AI — SFJM Current Issues / Risks / Gates

**Status:** `CURRENT / TYPED CONTINUITY VIEW / DERIVED FROM CURRENT_STATE + MATERIAL EVIDENCE`  
**Updated:** 2026-09-09  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Decision anchor:** `ec42e7b087dd1bf9b7ddc0cf05316e9d3e7979be` (Product Authority M3-03 acceptance / M3-04 authorization; future refs must be resolved live)

## 1. Authority boundary

This file is the typed current issue/risk/gate view for continuity consumers.

It does not replace:

~~~text
docs/sfjm/CURRENT_STATE.md
= principal material-state authority

docs/sfjm/NEXT_SAFE_ACTION.md
= current semantic action/gate

docs/sfjm/BLOCKED_ACTIONS.md
= prohibited-action / fail-closed boundary

docs/roadmap/fechai-security-to-scale-2026-wbs.md
= structural plan authority
~~~

A dashboard may consume this file to avoid treating every non-PASS fact as a current blocker.

## 2. Classification contract

~~~text
BLOCKING
= prevents the current authorized task from proceeding

REQUIRED_CURRENT
= must be resolved inside the current task/PR

RESIDUAL
= known historical/intermediate implementation/lifecycle/runtime/evidence debt preserved for explicit downstream treatment; not an acceptable final M3/M5/M6/Security Go terminal state

SECURITY_REMEDIATION
= actionable security finding that must reach REMEDIATED_VERIFIED or FALSE_POSITIVE_PROVEN / NOT_APPLICABLE_PROVEN before its owning milestone may close

DEFERRED_EVIDENCE
= evidence intentionally deferred until an explicit reopen condition

FUTURE_GATE
= expected future authorization/program gate; not a current blocker merely because it is not yet authorized

SECURITY_GATE
= launch/security/commercial boundary; may constrain launch without blocking the current engineering task

RESOLVED
= closed; not counted as current

SUPERSEDED
= historical state retained for provenance; not counted as current
~~~

## 3. Current counts

At Product Authority decision anchor `ec42e7b087dd1bf9b7ddc0cf05316e9d3e7979be`:

~~~text
CURRENT_TASK = STS-M3-04
CURRENT_TASK_STATE = ACTIVE / SCOPE_EXPANDED / REBASELINE_REQUIRED
CURRENT_AUTHORIZED_TECHNICAL_EXECUTION = NONE

BLOCKING = 0
REQUIRED_CURRENT = 0
SECURITY_REMEDIATION = 10
RESIDUAL = 12
DEFERRED_EVIDENCE = 3
SECURITY_GATE = 3
FUTURE_GATE = 1

CURRENT_BLOCKER_COUNT = 0
FINAL_SECURITY_CLOSURE_FINDINGS_OPEN = 10
~~~

These counts are semantic classes, not a count of every non-PASS program fact.

## 4. Current typed items

| ID | Class | Scope | State | Blocking for current task? | Blocking for / relevance | Source | Resolution / transition condition | Display policy |
|---|---|---|---|---|---|---|---|---|
| STS-AUDIT-20260909-F01 | SECURITY_REMEDIATION | STS-M3-07-01 | OPEN_REMEDIATION_REQUIRED | NO | M3 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | resource-bind Mesa approval; negative proof + AppSec | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F02 | SECURITY_REMEDIATION | STS-M3-07-01 | OPEN_REMEDIATION_REQUIRED | NO | M3 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | resource-bind supplier report; negative proof + AppSec | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F03 | SECURITY_REMEDIATION | STS-M3-07-02 | OPEN_REMEDIATION_REQUIRED | NO | M3 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | tenant-scope global analytics RPCs | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F04 | SECURITY_REMEDIATION | STS-M3-04-04 | OPEN_REMEDIATION_REQUIRED | NO | M3-04 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | tenant-bound lista_avaliacoes invariants + proof | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F05 | SECURITY_REMEDIATION | STS-M3-04-05 | OPEN_REMEDIATION_REQUIRED | NO | M3-04 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | tenant-bound PME relationship invariants + proof | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F06 | SECURITY_REMEDIATION | STS-M3-07-03 | OPEN_REMEDIATION_REQUIRED | NO | M3 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | remove/bind lead oracle reachability | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F07 | SECURITY_REMEDIATION | STS-M3-07-03 | OPEN_REMEDIATION_REQUIRED | NO | M3 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | remove client reachability from lock helper | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F08 | SECURITY_REMEDIATION | STS-M3-06-02 | OPEN_REMEDIATION_REQUIRED / DEPLOYMENT_REACHABILITY_TO_VERIFY | NO | M3-06 / M5 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | authenticate/limit or retire proxy after live proof | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F09 | SECURITY_REMEDIATION | STS-M3-04-11 | OPEN_REMEDIATION_REQUIRED | NO | M3-04 / M5-04 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | fail-closed default ACL + fitness proof | PROGRAM_SECURITY_GATES |
| STS-AUDIT-20260909-F10 | SECURITY_REMEDIATION | STS-M3-07-04 | OPEN_REMEDIATION_REQUIRED | NO | M3 / Security Go | `docs/security/audits/2026-09-09-live-fullstack-security-audit.md` | anon EXECUTE allowlist convergence + negative proof | PROGRAM_SECURITY_GATES |
| STS-GATE-SECURITY-GO | SECURITY_GATE | PROGRAM | OPEN / NOT_GRANTED | NO | Security Go / launch | `docs/sfjm/CURRENT_STATE.md` + `BLOCKED_ACTIONS.md` | explicit Product Authority Security Go after required evidence/assurance | PROGRAM_SECURITY_GATES |
| STS-GATE-COMMERCIALIZATION | SECURITY_GATE | COMMERCIALIZATION | BLOCKED | NO | broad paid commercialization | `docs/sfjm/BLOCKED_ACTIONS.md` | separate Product Authority commercial decision when launch/security conditions permit | PROGRAM_SECURITY_GATES |
| STS-DEFER-J4 | DEFERRED_EVIDENCE | STS-M1 / F1-02 | DEFERRED | NO | deferred security assurance | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | Supabase Pro + isolated non-production environment + explicit Product Authority execution authorization | DEFERRED_EVIDENCE |
| STS-DEFER-IMP-003 | DEFERRED_EVIDENCE | STS-M1 / F1-02 | NOT_DETERMINED | NO | deferred security assurance | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | bounded evidence run after the deferred-evidence reopen gate | DEFERRED_EVIDENCE |
| STS-DEFER-ROLLBACK-REAPPLY | DEFERRED_EVIDENCE | STS-M1 / F1-02 | NOT_DETERMINED | NO | rollback/reapply assurance | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | bounded evidence run after the deferred-evidence reopen gate | DEFERRED_EVIDENCE |
| STS-GATE-OC-01 | SECURITY_GATE | EXTERNAL_USERS | REQUIRED_BEFORE_EXTERNAL_USERS | NO | external-user admission / launch | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | satisfy/adjudicate OC-01 before external users as required by current contract | PROGRAM_SECURITY_GATES |
| STS-RESIDUAL-M2-TARGET-COMPLIANCE | RESIDUAL | STS-M2-04 / STS-M2-05 | OPEN / NOT_PROVEN | NO | implementation assurance | `docs/sfjm/CURRENT_STATE.md` | implementation + independent validation sufficient to establish target compliance | RESIDUAL_RISKS |
| STS-RESIDUAL-M2-04-E | RESIDUAL | STS-M2-04 | OPEN | NO | later implementation/lifecycle/runtime assurance | `docs/sfjm/BLOCKED_ACTIONS.md` | close exact residuals 004, 031, 036, 047, 119, 127 under separately authorized implementation/lifecycle/runtime work | RESIDUAL_RISKS |
| STS-RESIDUAL-M2-04D | RESIDUAL | STS-M2-04D | OPEN / NOT_IMPLEMENTED | NO | trigger remediation assurance | `docs/sfjm/BLOCKED_ACTIONS.md` | implement/adjudicate D-01..D-08 under separately authorized remediation | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-01-ROOT-DUAL | RESIDUAL | STS-M3-01 | PROVEN LIVE / NOT_REMEDIATED | NO | platform-root canonicalization | `docs/security/evidence/2026-09-07-sts-m3-01-identity-membership-team-role-model.md` | migrate callers to canonical public.admins root authority, prove zero legacy dependency, then separately authorize retirement | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-01-TEAM-LIFECYCLE | RESIDUAL | STS-M3-01 / Issue #135 | PROVEN LIVE / NOT_REMEDIATED | NO | team lifecycle authority | `docs/security/evidence/2026-09-07-sts-m3-01-identity-membership-team-role-model.md` | separately governed lifecycle remediation with same-tenant/role/state invariants and rollback | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-01-CREATE-USER | RESIDUAL | STS-M3-01 / STS-M3-05 | PROVEN LIVE / NOT_REMEDIATED | NO | Auth/Admin authority alignment | `docs/security/evidence/2026-09-07-sts-m3-01-identity-membership-team-role-model.md` | close under STS-M3-05 with server-derived canonical authority and independent validation | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-02-LEGACY-AUTHORITY | RESIDUAL | STS-M3-02 / STS-M3-03 / STS-M3-05 | OPEN / TARGET_ACCEPTED_NOT_CONVERGED | NO | legacy authority convergence | `docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md` | map/migrate privileged callers and Auth/Admin compatibility surfaces under separately authorized downstream work | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-02-SUPPORT | RESIDUAL | STS-M3-02 / BG-06 / STS-M3-06 | NOT_IMPLEMENTED / BG-06_PARKED_NOT_AUTHORIZED | NO | exceptional root tenant support | `docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md` | separately authorize BG-06 before support-mode design/implementation, then independently validate under the security test plan | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-02-SERVICE-ONLY | RESIDUAL | STS-M3-02 / STS-M3-03 / STS-M3-06 | TARGET_CONTEXT_CLARIFIED / RUNTIME_PROOF_PRESERVED | NO | trusted service-only authority mapping and assurance | `docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md` | map every SERVICE_ONLY_COMMAND under M3-03 and prove trusted runtime, service owner, business/tenant binding, bounded side-effect/secret scope, runtime proof and revoke/kill path before runtime-compliance claims | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-03-RPC-COMPLIANCE | RESIDUAL | STS-M3-03 | ALLOWLIST_COMPLETE / IMPLEMENTATION_TARGET_COMPLIANCE_NOT_PROVEN | NO | privileged RPC implementation/ACL convergence | `docs/security/evidence/2026-09-08-sts-m3-03-privileged-rpc-allowlist.md` | separately authorized bounded remediation + M3-06 assurance sufficient to prove implementation/runtime compliance | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-04-DML-COMPLIANCE | RESIDUAL | STS-M3-04 | NOT_PROVEN | NO | sensitive direct-DML authority compliance | `docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md` | reconcile direct DML, RLS, grants and RPC-only boundaries | RESIDUAL_RISKS |
| STS-RESIDUAL-M3-06-AUTHORITY-ASSURANCE | RESIDUAL | STS-M3-06 | NOT_PROVEN / APPSEC_NOT_PERFORMED | NO | hostile-client / cross-tenant / AppSec authority assurance | `docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md` | execute separately authorized isolated negative assurance plan and AppSec review | RESIDUAL_RISKS |
| STS-GATE-M3-M6 | FUTURE_GATE | STS-M3..STS-M6 | STS-M3 ACTIVE / STS-M3-03 ACCEPTED_WITH_RESIDUALS / STS-M3-04 AUTHORIZED_NOT_INITIATED | NO | future milestones | `docs/sfjm/PROGRAM_TASK_GRAPH.md` | initiate STS-M3-04 after fresh bootstrap; later tasks remain separately gated | ROADMAP_GATES |

## 5. Current task authorization boundary — not a blocker count

STS-M3-03 is now:

~~~text
COMPLETE / ACCEPTED WITH RESIDUALS
ALLOWLIST = 49 / 49 DISPOSED
SERVICE_ONLY = 2 / 2 MAPPED
~~~

The next program task is:

~~~text
STS-M3-04 = AUTHORIZED / NOT_INITIATED
~~~

The task may be initiated after fresh live bootstrap. This status does not itself authorize blanket mutation. The following remain separately gated:

~~~text
runtime/frontend mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grant / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
BG-06 support-mode implementation
STS-M3-05 substantive execution
STS-M3-06 substantive execution
active hostile-client/cross-tenant production testing
deploy / production mutation
Security Go
commercialization authorization
~~~

These are authorization boundaries, not automatically current blockers.

## 6. Explicitly superseded / non-current dashboard items

Do not render the following as current problems:

| Former item | Current disposition |
|---|---|
| `STS-M2-05 execution = NOT_AUTHORIZED` | SUPERSEDED — STS-M2-05 is COMPLETE / ACCEPTED WITH RESIDUALS |
| `STS-M2-06 execution = NOT_AUTHORIZED` | SUPERSEDED — STS-M2-06 was authorized, executed READ_ONLY, and is now COMPLETE / ACCEPTED |
| `STS-M2-06 = AUTHORIZED_READ_ONLY / READY_TO_EXECUTE` | SUPERSEDED — Product Authority accepted V2_STRANGLER / SAME_DATABASE_FIRST and closed STS-M2-06 |
| `STS-M3-01 = ELIGIBLE_NOT_AUTHORIZED` | SUPERSEDED — STS-M3-01 is COMPLETE / ACCEPTED |
| `STS-M3-02 = ELIGIBLE_NOT_AUTHORIZED` | SUPERSEDED — STS-M3-02 is COMPLETE / ACCEPTED WITH RESIDUALS |
| `STS-M3-03 = ELIGIBLE_NOT_AUTHORIZED` | SUPERSEDED — STS-M3-03 is COMPLETE / ACCEPTED WITH RESIDUALS and STS-M3-04 is AUTHORIZED / NOT_INITIATED |
| `next STS-M2-04 action = NOT_SELECTED` | SUPERSEDED — STS-M2-04 is COMPLETE / ACCEPTED WITH RESIDUALS |
| `STS-M2-04F execution` | NOT_CURRENT / NONCANONICAL — no canonical STS-M2-04F task exists |

Historical records may preserve those statements in their original lifecycle context.

## 7. Consumer / freshness contract

A consumer must preserve at minimum:

~~~text
source_repository
source_main_sha
source_file/ref
observed_at
last_validated_at
~~~

If the consumer's observed FECH.AI SHA differs from canonical FECH.AI main, it must show a stale/unverified freshness state rather than silently claiming current truth.

Rendering rules:

~~~text
BLOCKING + REQUIRED_CURRENT
→ current blocker count/panel

RESIDUAL
→ residual-risk panel

DEFERRED_EVIDENCE
→ deferred-evidence panel

FUTURE_GATE + SECURITY_GATE
→ program/security gate panel

RESOLVED + SUPERSEDED
→ hidden from current blocker count
~~~

## 8. Material update rule

Update this file when a material event changes:

~~~text
current task
current task blocker
residual state
deferred-evidence state or reopen condition
future/security gate state
Product Authority authorization
resolution/supersession
source/ref freshness
~~~

Do not update solely because a PR lifecycle or main SHA changes without semantic effect.
