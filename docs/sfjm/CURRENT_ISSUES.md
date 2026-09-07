# FECH.AI — SFJM Current Issues / Risks / Gates

**Status:** `CURRENT / TYPED CONTINUITY VIEW / DERIVED FROM CURRENT_STATE + MATERIAL EVIDENCE`  
**Updated:** 2026-09-07  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Validation anchor:** `0cb993a1eb86433975429da4a07a13fd3f373e16`

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
= known implementation/lifecycle/runtime/evidence debt preserved for later treatment

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

At validation anchor `0cb993a1eb86433975429da4a07a13fd3f373e16`:

~~~text
CURRENT_TASK = STS-M2-06
CURRENT_TASK_STATE = AUTHORIZED_READ_ONLY / READY_TO_EXECUTE

BLOCKING = 0
REQUIRED_CURRENT = 0
RESIDUAL = 3
DEFERRED_EVIDENCE = 3
SECURITY_GATE = 3
FUTURE_GATE = 1

CURRENT_BLOCKER_COUNT = 0
~~~

These counts are semantic classes, not a count of every non-PASS program fact.

## 4. Current typed items

| ID | Class | Scope | State | Blocking for current task? | Blocking for / relevance | Source @ 0cb993a1eb86 | Resolution / transition condition | Display policy |
|---|---|---|---|---|---|---|---|---|
| STS-GATE-SECURITY-GO | SECURITY_GATE | PROGRAM | OPEN / NOT_GRANTED | NO | Security Go / launch | `docs/sfjm/CURRENT_STATE.md` + `BLOCKED_ACTIONS.md` | explicit Product Authority Security Go after required evidence/assurance | PROGRAM_SECURITY_GATES |
| STS-GATE-COMMERCIALIZATION | SECURITY_GATE | COMMERCIALIZATION | BLOCKED | NO | broad paid commercialization | `docs/sfjm/BLOCKED_ACTIONS.md` | separate Product Authority commercial decision when launch/security conditions permit | PROGRAM_SECURITY_GATES |
| STS-DEFER-J4 | DEFERRED_EVIDENCE | STS-M1 / F1-02 | DEFERRED | NO | deferred security assurance | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | Supabase Pro + isolated non-production environment + explicit Product Authority execution authorization | DEFERRED_EVIDENCE |
| STS-DEFER-IMP-003 | DEFERRED_EVIDENCE | STS-M1 / F1-02 | NOT_DETERMINED | NO | deferred security assurance | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | bounded evidence run after the deferred-evidence reopen gate | DEFERRED_EVIDENCE |
| STS-DEFER-ROLLBACK-REAPPLY | DEFERRED_EVIDENCE | STS-M1 / F1-02 | NOT_DETERMINED | NO | rollback/reapply assurance | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | bounded evidence run after the deferred-evidence reopen gate | DEFERRED_EVIDENCE |
| STS-GATE-OC-01 | SECURITY_GATE | EXTERNAL_USERS | REQUIRED_BEFORE_EXTERNAL_USERS | NO | external-user admission / launch | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | satisfy/adjudicate OC-01 before external users as required by current contract | PROGRAM_SECURITY_GATES |
| STS-RESIDUAL-M2-TARGET-COMPLIANCE | RESIDUAL | STS-M2-04 / STS-M2-05 | OPEN / NOT_PROVEN | NO | implementation assurance | `docs/sfjm/CURRENT_STATE.md` | implementation + independent validation sufficient to establish target compliance | RESIDUAL_RISKS |
| STS-RESIDUAL-M2-04-E | RESIDUAL | STS-M2-04 | OPEN | NO | later implementation/lifecycle/runtime assurance | `docs/sfjm/BLOCKED_ACTIONS.md` | close exact residuals 004, 031, 036, 047, 119, 127 under separately authorized implementation/lifecycle/runtime work | RESIDUAL_RISKS |
| STS-RESIDUAL-M2-04D | RESIDUAL | STS-M2-04D | OPEN / NOT_IMPLEMENTED | NO | trigger remediation assurance | `docs/sfjm/BLOCKED_ACTIONS.md` | implement/adjudicate D-01..D-08 under separately authorized remediation | RESIDUAL_RISKS |
| STS-GATE-M3-M6 | FUTURE_GATE | STS-M3..STS-M6 | NOT_AUTHORIZED | NO | future milestones | `docs/sfjm/PROGRAM_TASK_GRAPH.md` | sequential Product Authority authorization when each future milestone becomes eligible | ROADMAP_GATES |

## 5. Current task authorization boundary — not a blocker count

STS-M2-06 is currently:

~~~text
AUTHORIZED_READ_ONLY / READY_TO_EXECUTE
~~~

The following remain prohibited without additional authority:

~~~text
STS-M2-06 implementation
runtime/frontend mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grant / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
STS-M3 execution
deploy / production mutation
Security Go
commercialization authorization
~~~

These are authorization boundaries. They are not automatically counted as current blockers.

## 6. Explicitly superseded / non-current dashboard items

Do not render the following as current problems:

| Former item | Current disposition |
|---|---|
| `STS-M2-05 execution = NOT_AUTHORIZED` | SUPERSEDED — STS-M2-05 is COMPLETE / ACCEPTED WITH RESIDUALS |
| `STS-M2-06 execution = NOT_AUTHORIZED` | SUPERSEDED — STS-M2-06 is AUTHORIZED_READ_ONLY / READY_TO_EXECUTE |
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
