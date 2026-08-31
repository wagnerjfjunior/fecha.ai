# FECH.AI — SFJM Next Safe Action

**Status:** `SECURITY_TO_SCALE_2026 / M1_BASELINE_COMPLETE / P0_FUNIL_TENANT_INTEGRITY_DESIGN_PROOF_PLAN`
**Updated:** `2026-08-31`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is the thin semantic continuation view. Principal state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve GitHub and environment state live before acting.

```text
TOOL_CAPABILITY != AUTHORIZATION
M1_BASELINE_COMPLETE != SECURITY_GO
DESIGN_APPROVED != IMPLEMENTATION_AUTHORIZED
```

## 2. Single current semantic next action

```text
P0 — M1-C-F01 / FUNIL TENANT INTEGRITY

DESIGN / PROOF PLAN FIRST
```

Do not implement or mutate production under this action.

The bounded design/proof plan must define:

1. tenant-aware database invariants for `funil_movimentacoes` relationships;
2. the correct server/data-side source of `empresa_id`;
3. correction of `mover_funil` tenant attribution;
4. treatment options for the currently observed anomalous rows, with
   NO silent cleanup;
5. preservation of RLS and FORCE RLS;
6. required UNIQUE/FK/trigger/RPC interactions, if any, without assuming a
   preferred mechanism before design review;
7. migration/application preflight and postflight requirements;
8. simple rollback and rollback stop conditions;
9. static and live read-only proof obligations;
10. controlled runtime-negative proof only when separately authorized and
    feasible under the production-safety model.

## 3. Known defect boundary

Current M1 evidence establishes:

```text
public.funil_movimentacoes:
  rows observed = 611
  empresa_id NULL = 1
  non-null movement-vs-lead tenant mismatch = 0
  non-null movement-vs-corretor tenant mismatch = 1
  non-null movement-vs-current-stage tenant mismatch = 1

mover_funil(uuid,uuid,text):
  SECURITY DEFINER
  authenticated EXECUTE = true
  anon EXECUTE = false
  validates several tenant conditions
  currently omits empresa_id from funil_movimentacoes INSERT

funil_mov_insert policy:
  is_root() OR corretor_id = my_corretor_id()

tenant-aware relationship invariant:
  NOT ESTABLISHED
```

Do not overstate this as proven cross-tenant lead leakage.

## 4. Required specialist sequence for this new risk

```text
1. backend_data -> backend-data-platform-specialist
   bounded target design / invariant / rollback / proof obligations

2. application_security -> application-security-assurance-specialist
   independent target-security review before implementation authority

3. implementation
   only after a separate exact Product Authority authorization

4. post-fix AppSec retest
   only against the implemented exact ref/evidence
```

This is a new remediation lifecycle. It is not a continuation of M1 technical
acquisition.

## 5. Explicit prohibitions

Under the current documentation/continuity authority:

```text
NO DDL/DML
NO migration application
NO Supabase mutation
NO Auth mutation
NO anomalous-row cleanup
NO runtime/frontend code change
NO deploy
NO production negative/offensive testing
NO staging/LAB
NO second Supabase project
NO Preview Branch
NO local isolated environment
NO Security Go
NO broad paid commercialization
NO fresh #139 approval
NO reopening public.leads
```

## 6. M1 anti-loop

M1 technical adjudication is complete:

```text
Backend/Data = PASS_WITH_RESIDUAL_RISKS
AppSec = PASS_WITH_RESIDUAL_RISKS
Documentation = PASS_WITH_BOUNDED_RESIDUALS
additional technical re-audit = AUDIT_LOOP_BLOCKED
```

Reopen M1 acquisition only after a material invalidation event affecting a
specific proof obligation.

## 7. Issue lifecycle boundary

Issue #150 is eligible for closure as the completed Security Truth Baseline only
after the bounded canonical reconciliation is accepted through its separately
authorized lifecycle.

Issue #141 remains OPEN.

Security Go remains DENIED.
