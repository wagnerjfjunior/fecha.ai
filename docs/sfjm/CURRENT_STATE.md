# FECH.AI — SFJM Current State

**Lifecycle state:** `PR103_RUNTIME_SMOKE_PASSED / F1_02_ACTIVE / SMOKE_DOC_PR_DRAFT / PR02_NOT_AUTHORIZED`  
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

## 2. Canonical GitHub anchor before this PR

```text
main observed: 9624900ada5d29e24476ab6a0a0907cb4854e509
PR #103: CLOSED / MERGED
PR #103 final head: abf6b4026343eae437283280269ed2997911dcec
PR #103 squash commit: 276a3e55155cd0e57b6155dc13b998704bdfd654
PR #106 squash / current main: 9624900ada5d29e24476ab6a0a0907cb4854e509
```

This branch is a proposed documentation reconciliation. Its contents are not canonical `main` until independently reviewed, separately authorized and merged.

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

## 4. New controlled runtime evidence

Canonical candidate:

```text
docs/security/evidence/2026-07-28-pr103-authenticated-smoke-and-idempotency.md
```

Observed:

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
```

Final cleanup verification:

```text
remaining Auth users: 0
remaining synthetic broker profiles: 0
remaining synthetic teams: 0
synthetic company: preserved inactive
```

## 5. PR #103 operational state after the smoke

```text
F1-02 PR-01: COMPLETED WITH RESIDUAL RISK
Authenticated positive smoke: ESTABLISHED / PASS
Immediate runtime idempotency: ESTABLISHED / PASS
Controlled concurrency: NOT ESTABLISHED
Missing-profile execution: NOT ESTABLISHED
Inactive-profile execution: NOT ESTABLISHED
Rollback execution: NOT ESTABLISHED
Reapply after rollback: NOT ESTABLISHED
```

The new runtime evidence narrows the residual-risk set. It does not grant Security Go or F1-02 acceptance.

## 6. F1-02 program anchor

Canonical source:

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

```text
Program structure: 5 operational windows / 10 planned PRs
PR-00: completed
PR-01: completed with residual risk; positive smoke and immediate idempotency now established
PR-02: next technical workstream / implementation not authorized
PR-03: blocked until PR-02 is deployed and proven
PR-04 through PR-09: planned / not started unless newer canonical evidence proves otherwise
```

## 7. Current documentation workstream

```text
Branch: docs/pr103-authenticated-smoke-evidence
Title: docs(security): record PR103 authenticated smoke
Mode: documentation-only / Draft
Allowed paths: exactly 7
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-02 implementation: NOT AUTHORIZED
```

No runtime, frontend or Supabase change belongs to this workstream.

## 8. Current authority state

```text
PR #103 lifecycle/application authority: CONSUMED
PR #103 controlled smoke authority: CONSUMED / EXPIRED AFTER CLEANUP
Current smoke-documentation PR creation authority: CONSUMED BY INITIAL PUBLICATION
Additional commits: NOT AUTHORIZED WITHOUT A MATERIAL FINDING AND NEW EXACT AUTHORITY
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-02: NOT AUTHORIZED UNTIL THIS DOCUMENTATION PR IS CLOSED
PR-03: BLOCKED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 9. Next safe action

Run one independent GPT0 documentation audit at the exact current head of the Draft smoke-evidence PR.

Do not mark Ready, merge or start PR-02 in the same step.
