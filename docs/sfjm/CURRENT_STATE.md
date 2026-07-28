# FECH.AI — SFJM Current State

**Lifecycle state:** `PR103_RUNTIME_SMOKE_PASSED / F1_02_ACTIVE / PR107_READY / PM107_CORRECTION_PENDING_AUDIT / PR02_NOT_AUTHORIZED`  
**Record type:** `OPERATIONAL_STATE / DOCUMENTATION_ONLY`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Frontend or Action requests. Backend, RPC and Supabase validate and decide. AI assists but is not authority.

## 2. Canonical GitHub anchor before PR #107

```text
main observed: 9624900ada5d29e24476ab6a0a0907cb4854e509
PR #103: CLOSED / MERGED
PR #103 final head: abf6b4026343eae437283280269ed2997911dcec
PR #103 squash: 276a3e55155cd0e57b6155dc13b998704bdfd654
PR #106 squash / current main: 9624900ada5d29e24476ab6a0a0907cb4854e509
```

PR #107 remains proposed documentation state until separately authorized and merged.

## 3. PR #103 catalog state

```text
Migration: 20260727080929 / f1_02_password_state_rpc / APPLIED
RPC: public.marcar_senha_inicial_definida() / EXISTS
Owner: postgres
SECURITY DEFINER: true
search_path: pg_catalog
authenticated EXECUTE: true
anon EXECUTE: false
service_role EXECUTE: false
PUBLIC EXECUTE: false
```

## 4. Controlled runtime evidence

```text
First call:
must_change_password: true → false
xmin: 6997 → 6999
RPC return: true
unexpected changed fields: none

Immediate repeated call:
must_change_password: false → false
xmin: 6999 → 6999
RPC return: true
unexpected changed fields: none

Cleanup:
remaining Auth users: 0
remaining synthetic broker profiles: 0
remaining synthetic teams: 0
synthetic company: preserved inactive
```

Evidence path:

```text
docs/security/evidence/2026-07-28-pr103-authenticated-smoke-and-idempotency.md
```

## 5. PR #103 operational state

```text
F1-02 PR-01: COMPLETED WITH RESIDUAL RISK
Authenticated positive smoke: ESTABLISHED / PASS
Immediate runtime idempotency: ESTABLISHED / PASS
Controlled concurrency: NOT ESTABLISHED
Missing-profile execution: NOT ESTABLISHED
Inactive-profile execution: NOT ESTABLISHED
Rollback execution: NOT ESTABLISHED
Reapply after rollback: NOT ESTABLISHED
Frontend cutover: NOT ESTABLISHED
Legacy direct UPDATE denial: NOT ESTABLISHED
```

The runtime evidence narrows the residual-risk set. It does not grant Security Go or F1-02 acceptance.

## 6. F1-02 program anchor

```text
Canonical source: docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
Program structure: 5 operational windows / 10 planned PRs
PR-00: completed
PR-01: completed with residual risk
PR-02: next technical workstream / implementation not authorized
PR-03: blocked until PR-02 is deployed and proven
PR-04 through PR-09: planned / not started unless newer canonical evidence proves otherwise
```

## 7. PR #107 lifecycle

```text
PR: #107 — docs(security): record PR103 authenticated smoke
Branch: docs/pr103-authenticated-smoke-evidence
Base: main@9624900ada5d29e24476ab6a0a0907cb4854e509
Original audited head: 51105692b0957454bd3d83f70e6591472fcf10dc
State: OPEN / READY FOR REVIEW
Changed-file contract: exactly 7 documentation files
GPT0 exact-head audit: PASS
GPT4 exact-head lifecycle/scope validation: PASS
Ready authority: CONSUMED / EXECUTED
Pre-merge validation: FAIL — PM-107-GATE-01
Corrective scope: exactly 6 SFJM files
Corrective head: resolve live after the single commit
Merge: NOT AUTHORIZED
PR-02: NOT AUTHORIZED
```

No runtime, frontend or Supabase change belongs to this workstream.

## 8. Corrective delta effect

The PM-107-GATE-01 commit updates only stale lifecycle records. It does not modify the smoke evidence file and does not invalidate:

- authenticated positive smoke;
- immediate repeated-call idempotency;
- cleanup evidence;
- PR #103 catalog evidence;
- unrelated historical gates.

Prior GPT0/GPT4 PASS results are no longer sufficient for the new head only because the six SFJM files changed.

## 9. Current authority state

```text
PR #107 initial publication: CONSUMED
GPT0 review COMMENT: CONSUMED
GPT4 review COMMENT: CONSUMED
Ready: CONSUMED / EXECUTED
PM-107-GATE-01 single corrective commit: CONSUMED ON PUBLICATION
Additional commit: NOT AUTHORIZED
Comment or review: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-02: NOT AUTHORIZED UNTIL PR #107 IS CLOSED AND MAIN CONFIRMED
PR-03: BLOCKED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

The accidental `noop` comment is accepted as a non-material procedural deviation and grants no authority.

## 10. Next safe action

Run one GPT0 delta-only documentation audit of the six-file PM-107-GATE-01 correction at the exact live corrective head.

Do not merge or start PR-02 in the same step.
