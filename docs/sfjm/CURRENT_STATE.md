# FECH.AI — SFJM Current State

**Lifecycle state:** `PR107_CLOSED_MERGED / F1_02_ACTIVE / PR02_NOT_AUTHORIZED`  
**Record type:** `OPERATIONAL_STATE / DOCUMENTATION_ONLY`  
**Observed on:** `2026-07-29`  
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

## 2. Canonical GitHub state

```text
main: cec1b22430adf1a002b172992cf6c5ea5bb427de
main commit: docs(security): record PR103 authenticated smoke (#107)

PR #107: CLOSED / MERGED
PR #107 base: main@9624900ada5d29e24476ab6a0a0907cb4854e509
PR #107 final head: 62346a8976d3489dff9b84dcf7bab40a2b43e685
PR #107 squash / current main: cec1b22430adf1a002b172992cf6c5ea5bb427de
PR #107 changed-file contract: exactly 7 documentation files
Runtime/frontend/Supabase change in PR #107: NONE
```

The prior records that described PR #107 as open, Ready, pending corrective audit or not merged are stale and must not be used as current truth.

## 3. PR #103 catalog and runtime evidence

Last versioned catalog evidence records:

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

Evidence source:

```text
docs/security/evidence/2026-07-27-pr103-operational-closure-with-residual-risk.md
```

Controlled runtime evidence records:

```text
Authenticated positive smoke: PASS
must_change_password: true → false
Immediate repeated-call idempotency: PASS
Second-call xmin unchanged: 6999 → 6999
Unexpected captured profile-field changes: NONE
Synthetic Auth/profile/team cleanup: COMPLETE
```

Evidence source:

```text
docs/security/evidence/2026-07-28-pr103-authenticated-smoke-and-idempotency.md
```

These records do not replace fresh live catalog or runtime validation when a later material change affects the same objects.

## 4. Evidence boundary and residual risk

Established:

- authenticated positive execution of the narrow password-state RPC;
- target transition `must_change_password = true → false`;
- immediate repeated-call idempotency;
- no second row version on the repeated call;
- no unexpected change in the captured profile fields;
- synthetic-fixture cleanup.

Not established:

- controlled concurrency;
- missing-profile execution;
- inactive-profile execution;
- rollback execution;
- reapply after rollback;
- frontend cutover;
- deployed frontend proof;
- denial of legacy direct `corretores` update;
- Security Go;
- F1-02 acceptance;
- WDP.

## 5. F1-02 program state

```text
Canonical source: docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
PR-00: completed
PR-01: completed with residual risk
PR-02: next technical workstream / implementation not authorized
PR-03: blocked until PR-02 is deployed and proven
PR-04 through PR-09: planned / not started unless newer canonical evidence proves otherwise
```

The PR-02 precondition that the PR-01 RPC be applied and positively verified is documented as satisfied. This does not authorize PR-02 implementation, branch creation, commit, PR, deploy or production smoke.

## 6. Authority state

```text
PR #107 lifecycle: CLOSED / MERGED
Additional PR #107 work: NOT AUTHORIZED / NOT REQUIRED WITHOUT NEW MATERIAL EVIDENCE
PR-02 read-only scope reconstruction: PERMITTED AS PLANNING
PR-02 branch or implementation: NOT AUTHORIZED
PR-03: BLOCKED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

No historical gate is reopened merely because this continuity record is updated.

## 7. Exact next safe action

Run one GPT1 architectural scope reconstruction, strictly `READ_ONLY`, for F1-02 PR-02 against the current live `main`.

The reconstruction must:

1. locate the exact current frontend call site that directly updates the password-completion state;
2. confirm the narrow RPC contract and current consumer dependencies;
3. define the smallest allowed file scope;
4. identify prohibited areas;
5. define build, call-site search, success/fail-closed UI, preview, smoke and rollback criteria;
6. produce a bounded implementation proposal only.

Do not create a branch, commit, PR or implementation in that step. Implementation requires separate Product Authority.

## 8. Current non-actions

```text
No runtime or frontend change
No Supabase change
No SQL or migration
No RPC-body, Auth, RLS, policy or grant change
No Edge Function, Vercel or GitHub Actions change
No PR-02 branch, commit, PR or implementation
No PR-03
No Security Go
No F1-02 acceptance
No WDP change
```

## 9. Anti-loop

PR #107 is closed. Do not open another PR solely to record the reconciliation PR's future squash SHA.

A later SFJM update is required only when material evidence, authority, blocker, decision, active head or next safe action changes.