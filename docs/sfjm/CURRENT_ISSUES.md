# FECH.AI — SFJM Current Issues / Risks / Gates

**Status:** `CURRENT / TYPED CONTINUITY VIEW / ZERO-MATERIAL-RESIDUAL-AWARE`  
**Updated:** 2026-09-10  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Material execution anchor:** `STS-M3-04-03 READ_ONLY execution against main b274adac84f2d4a27a7a5147c551dc23469a610c`  
**Publication:** `PR #215 / PR_HEAD_ONLY until merged`

## 1. Authority boundary

This file is the typed issue/risk/gate view consumed by continuity/dashboard tooling.

It does not replace:

```text
docs/sfjm/CURRENT_STATE.md
= principal material-state authority

docs/sfjm/NEXT_SAFE_ACTION.md
= semantic next gate

docs/sfjm/BLOCKED_ACTIONS.md
= prohibited-action / fail-closed boundary

docs/roadmap/fechai-security-to-scale-2026-wbs.md
= structural planning authority
```

The purpose of this file is to prevent a dashboard from translating every non-PASS fact into a current execution blocker **or**, conversely, displaying `0 blockers` as though FECH.AI had zero open security findings.

## 2. Classification contract

```text
CURRENT_EXECUTION_BLOCKER
= prevents an action that is currently authorized to execute

MATERIAL_SECURITY_FINDING
= open material security/integrity finding that must be closed/refuted before its owning final gate; may exist while no immediate execution is authorized

LEGACY_RESIDUAL
= previously typed implementation/lifecycle/runtime/evidence debt preserved for continuity; may overlap a newer material finding and therefore is not arithmetically added without reconciliation

DEFERRED_EVIDENCE
= evidence intentionally held until an explicit reopen/admission condition

SECURITY_GATE
= Security Go / launch / commercial boundary

FUTURE_GATE
= later program gate or separately authorized future/deferred activity

RESOLVED / SUPERSEDED
= historical or closed; not counted as current
```

## 3. Current headline state

```text
CURRENT_MILESTONE = STS-M3
CURRENT_PARENT_TASK = STS-M3-04
CURRENT_CHILD = STS-M3-04-03
CURRENT_CHILD_STATE = READ_ONLY_EXECUTED / PRODUCT_AUTHORITY_ACCEPTANCE_PENDING
CURRENT_IMMEDIATE_AUTHORIZED_TECHNICAL_EXECUTION = NONE

CURRENT_EXECUTION_BLOCKER_COUNT = 0

MATERIAL_SECURITY_FINDINGS_FROM_2026_09_09_AUDIT = 10
NEW_LOCAL_MATERIAL_FINDINGS_FROM_STS_M3_04_03 = 1
MATERIAL_SECURITY_FINDINGS_VISIBLE_IN_THIS_VIEW = 11

LEGACY_RESIDUAL_ROWS = 12
LEGACY_RESIDUAL_OVERLAP_WITH_NEW_FINDINGS = NOT_DEDUPED
AGGREGATE_TOTAL_OPEN = NOT_COMPUTED

DEFERRED_EVIDENCE = 3
PROGRAM_SECURITY_GATES = 4

Security Go = NOT_GRANTED
```

Interpretation:

```text
CURRENT_EXECUTION_BLOCKER_COUNT = 0
!= ZERO OPEN SECURITY FINDINGS
!= SECURITY GO
!= READY FOR COMMERCIALIZATION
```

The old `BLOCKING=0 / RESIDUAL=12 / DEFERRED=3 / SECURITY+FUTURE_GATE=4` snapshot from 2026-09-08 is superseded as a current dashboard summary. The 12 legacy residual rows remain preserved below, but they are not simply added to F-01..F-10 + GTI-01 because material overlap has not been deduplicated claim-by-claim.

## 4. Material security findings — current visible universe

Canonical 2026-09-09 findings remain open unless separately remediated/refuted with current evidence. `GTI-01` is a local STS-M3-04-03 finding and has not been unilaterally promoted to `F-11`.

| ID | Class | Scope | State | Current execution blocker? | Final-gate impact | Primary source / downstream |
|---|---|---|---|---|---|---|
| F-01 | MATERIAL_SECURITY_FINDING | privileged RPC resource binding / `aprovar_rejeitar_mesa` | OPEN | NO | blocks final RPC/M3 closure while open | `2026-09-09-audit-to-wbs-zero-residual-plan.md` → STS-M3-03-02 → M5-01/02 |
| F-02 | MATERIAL_SECURITY_FINDING | privileged RPC resource binding / `relatorio_fornecedor` | OPEN | NO | blocks final RPC/M3 closure while open | same → STS-M3-03-02 → M5-01/02 |
| F-03 | MATERIAL_SECURITY_FINDING | manager analytics tenant scope | OPEN | NO | blocks final RPC/M3 closure while open | same → STS-M3-03-03 → M5-02 |
| F-04 | MATERIAL_SECURITY_FINDING | `lista_avaliacoes` resulting-row tenant integrity | RECONFIRMED / OPEN | NO | blocks final M3-04 closure | STS-M3-04-03 evidence → STS-M3-04-04 / 07 / 09 |
| F-05 | MATERIAL_SECURITY_FINDING | PME catalog tenant relationships | RECONFIRMED / OPEN | NO | blocks final M3-04 closure | STS-M3-04-03 evidence → STS-M3-04-05 / 07 / 09 |
| F-06 | MATERIAL_SECURITY_FINDING | `lead_tem_acao_real` internal-helper reachability | OPEN | NO | blocks final RPC/M3 closure while open | 2026-09-09 plan → STS-M3-03-04 / M5-01 |
| F-07 | MATERIAL_SECURITY_FINDING | `acquire_lote_lock` direct client reachability | OPEN | NO | blocks final RPC/M3 closure while open | 2026-09-09 plan → STS-M3-03-04 / M5-01/05 |
| F-08 | MATERIAL_SECURITY_FINDING | `mesa-worker-proxy` service boundary | OPEN / DEFERRED REMEDIATION OWNER | NO | blocks final service-boundary/M3 closure | 2026-09-09 plan → STS-M3-06-02/03 → M5-01/04 |
| F-09 | MATERIAL_SECURITY_FINDING | fail-open/default privileges | OPEN | NO | blocks final config/security assurance | 2026-09-09 plan → STS-M3-04-06/07 → M5-04 |
| F-10 | MATERIAL_SECURITY_FINDING | broad RPC EXECUTE principal/anon ACL | OPEN | NO | blocks final RPC/M3 closure | 2026-09-09 plan → STS-M3-03-05 → M5-00/01 |
| GTI-01 | MATERIAL_SECURITY_FINDING | `leads.funil_estagio_id` current-stage tenant invariant | PROVEN_LIVE / OPEN / NOT_REMEDIATED | NO | blocks final M3-04 closure unless adjudicated/remediated/refuted | `2026-09-10-sts-m3-04-03-*` → suggested STS-M3-04-06/07/09 |

### GTI-01 evidence boundary

```text
stored mismatch count = 1
row/PII persisted in documentation = NO
structural child tenant invariant = MISSING / NOT OBSERVED
reviewed canonical authenticated funnel writers = TENANT-GUARDED
ordinary authenticated reproduction through those routines = NOT_PROVEN
severity = TO_BE_ADJUDICATED
canonical F-number = NOT_ASSIGNED
```

## 5. Legacy residual rows — preserved, not double-counted

These rows are historical/current residual obligations that predate the 2026-09-09 finding universe. They remain valid unless superseded, but overlap must be reconciled before any aggregate residual total is presented.

| ID | Class | Scope | State | Transition condition |
|---|---|---|---|---|
| STS-RESIDUAL-M2-TARGET-COMPLIANCE | LEGACY_RESIDUAL | STS-M2-04 / 05 | OPEN / NOT_PROVEN | implementation + independent target-compliance proof |
| STS-RESIDUAL-M2-04-E | LEGACY_RESIDUAL | STS-M2-04 | OPEN | close residuals 004,031,036,047,119,127 under governed downstream work |
| STS-RESIDUAL-M2-04D | LEGACY_RESIDUAL | STS-M2-04D | OPEN / NOT_IMPLEMENTED | implement/adjudicate D-01..D-08 |
| STS-RESIDUAL-M3-01-ROOT-DUAL | LEGACY_RESIDUAL | STS-M3-01 | PROVEN LIVE / NOT_REMEDIATED | canonical root convergence |
| STS-RESIDUAL-M3-01-TEAM-LIFECYCLE | LEGACY_RESIDUAL | STS-M3-01 / Issue #135 | PROVEN LIVE / NOT_REMEDIATED | governed same-tenant team lifecycle remediation |
| STS-RESIDUAL-M3-01-CREATE-USER | LEGACY_RESIDUAL | STS-M3-01 / M3-05 | PROVEN LIVE / NOT_REMEDIATED | M3-05 server-derived authority closure |
| STS-RESIDUAL-M3-02-LEGACY-AUTHORITY | LEGACY_RESIDUAL | STS-M3-02/03/05 | OPEN / TARGET_ACCEPTED_NOT_CONVERGED | legacy authority implementation convergence |
| STS-RESIDUAL-M3-02-SUPPORT | LEGACY_RESIDUAL | STS-M3-02 / BG-06 / M3-06 | NOT_IMPLEMENTED / PARKED | separately governed support-mode implementation |
| STS-RESIDUAL-M3-02-SERVICE-ONLY | LEGACY_RESIDUAL | STS-M3-02/03/06 | TARGET_CONTEXT_CLARIFIED / RUNTIME_PROOF_PRESERVED | trusted runtime/business/tenant/secret/revoke proof |
| STS-RESIDUAL-M3-03-RPC-COMPLIANCE | LEGACY_RESIDUAL | STS-M3-03 | ALLOWLIST_COMPLETE / IMPLEMENTATION_TARGET_COMPLIANCE_NOT_PROVEN | M3-03 implementation convergence + assurance |
| STS-RESIDUAL-M3-04-DML-COMPLIANCE | LEGACY_RESIDUAL | STS-M3-04 | NOT_PROVEN | direct DML/RLS/grant/RPC/invariant convergence |
| STS-RESIDUAL-M3-06-AUTHORITY-ASSURANCE | LEGACY_RESIDUAL | STS-M3-06 | NOT_PROVEN / APPSEC_NOT_PERFORMED | authorized isolated adversarial assurance + independent review |

## 6. Deferred evidence

| ID | Class | Scope | State | Reopen condition |
|---|---|---|---|---|
| STS-DEFER-J4 | DEFERRED_EVIDENCE | STS-M1 / F1-02 | DEFERRED | isolated non-production environment + explicit execution admission/cost rules |
| STS-DEFER-IMP-003 | DEFERRED_EVIDENCE | STS-M1 / F1-02 | NOT_DETERMINED | bounded evidence run after deferred-evidence reopen |
| STS-DEFER-ROLLBACK-REAPPLY | DEFERRED_EVIDENCE | STS-M1 / F1-02 | NOT_DETERMINED | bounded rollback/reapply evidence after reopen |

The later Product Authority authorization of the final synthetic offensive-lab path remains deferred and does not retroactively turn these evidence items into PASS.

## 7. Program / security gates

| ID | Class | State | Meaning / transition |
|---|---|---|---|
| STS-GATE-SECURITY-GO | SECURITY_GATE | OPEN / NOT_GRANTED | explicit Product Authority Security Go only after required current proof and independent assurance |
| STS-GATE-COMMERCIALIZATION | SECURITY_GATE | BLOCKED | broad paid commercialization remains blocked before Security Go contract is satisfied |
| STS-GATE-OC-01 | SECURITY_GATE | REQUIRED_BEFORE_EXTERNAL_USERS | external-user admission control remains required |
| STS-GATE-M3-M6 | FUTURE_GATE | STS-M3 ACTIVE / M3-04-03 READ_ONLY_EXECUTED_ACCEPTANCE_PENDING | continue task-by-task; no automatic next child; M3-06 and M5-01/02 remain deferred future authority |

## 8. STS-M3-04-03 current transition

```text
Product Authority authorization =
READ_ONLY / evidence-first

execution =
PERFORMED

result publication =
PR #215 / PR_HEAD_ONLY

Product Authority acceptance of result =
PENDING

F-04 = RECONFIRMED OPEN
F-05 = RECONFIRMED OPEN
GTI-01 = NEW LOCAL MATERIAL FINDING / OPEN

full nominal 75 simple-FK rowset durably captured =
NO

query/reproduction manifest =
VERSIONED IN PR #215 / NOT EXECUTED BY CORRECTION

current immediate technical execution =
NONE

STS-M3-04-04 =
DEFINED / NOT_AUTHORIZED
```

## 9. Dashboard rendering contract

Render separately:

```text
CURRENT EXECUTION
→ no immediate authorized technical execution

MATERIAL OPEN SECURITY FINDINGS
→ F-01..F-10 + GTI-01

LEGACY RESIDUAL OBLIGATIONS
→ 12 rows, with overlap warning; do not add arithmetically to findings

DEFERRED EVIDENCE
→ 3

PROGRAM / SECURITY GATES
→ 4
```

Do **not** render:

```text
"0 blockers"
```

without the qualifier:

```text
"0 blockers to a currently authorized technical execution; no technical execution is currently authorized"
```

and do not infer that this means zero security findings.

## 10. Freshness / invalidation

Revalidate this view when any of the following materially changes:

- STS-M3-04-03 Product Authority acceptance/rejection;
- PR #215 head changes materially;
- F-01..F-10 remediation/refutation state;
- GTI-01 data/invariant state;
- relevant database/RLS/grant/policy/RPC/trigger state;
- authorization of the next M3 child;
- Security Go/commercialization decision.

Ordinary main movement or PR lifecycle alone does not resolve a material finding.
