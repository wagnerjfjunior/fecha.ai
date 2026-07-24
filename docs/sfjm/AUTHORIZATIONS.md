# FECH.AI — SFJM Authorizations

**Status:** AUTHORIZATION_REGISTER / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Interpretation rule

An authorization is valid only within its declared repository, target, environment, file scope, acceptance criteria and expiration condition.

General phrases such as `continue`, `proceed`, `next step` or `ótimo` must not be expanded into authority for runtime, security, Supabase, Vercel, production, Ready-for-review or merge actions.

When authorization is ambiguous, the posture is fail-closed.

## 2. Consumed authorization — SFJM documentation v1 / PR #95

**Lifecycle state:** `CONSUMED`  
**Result:** PR #95 — `docs(sfjm): add FECH.AI operational continuity layer v1`  
**Merged head:** `611faa5d7275d8f40386c41b2687fb5ef6f7b5b6`  
**Squash commit:** `4293f383e1e93f0cfd4a63f793024eb239bfafbb`

No PR #95 authority remains active.

## 3. Consumed authorization — post-PR #95 reconciliation / PR #96

**Lifecycle state:** `CONSUMED`  
**Result:** PR #96 — `docs(sfjm): reconcile state after PR 95 merge`  
**Merged head:** `91d27a4aa676f3e174ab000ca23992b69fc90a90`  
**Squash commit:** `4668cc1dde4b990791583c85f5b36a5d4b55d6a8`

No PR #96 authority remains active.

## 4. Consumed authorization — PR #94 correction, reaudit and merge

**Lifecycle state:** `CONSUMED`  
**Result:** PR #94 — `docs(m1): add F1-01 acceptance evidence map`  
**Final head:** `a7e64c6ed817c03c4dbce7e1b9642e20360b3010`  
**Squash commit:** `1caf90c60681771af6609b96ee840b190668fa0f`

Consumed actions include bounded correction, six review-thread resolutions, independent reaudit, pre-merge verification, squash merge with expected-head protection and post-merge confirmation.

This authorization did not accept F1-01, grant Security Go or award WDP.

## 5. Consumed authorization — post-PR #94 documentation reconciliation / PR #98

**Lifecycle state:** `CONSUMED`  
**Source/date:** explicit user authorizations, 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `1caf90c60681771af6609b96ee840b190668fa0f`  
**Branch:** `agent/reconcile-f1-01-post-pr94`  
**Result:** PR #98 — `docs(sfjm): reconcile F1-01 state after PR 94 merge`  
**Final head:** `e7e52ed9762ab92fd14f82e2437845421693ec81`  
**Squash commit:** `8a2eb00a9dcd46d7ee346741ca27c6081af52124`  
**Audit:** `PASS WITH RESIDUAL RISK`  
**Pre-merge verification:** `PASS WITH RESIDUAL RISK`

Consumed actions include:

- creation of Draft PR #98 in exactly six authorized documentation files;
- bounded authorization-state corrections;
- transition to Ready after exact-head verification;
- pre-merge verification;
- squash merge with expected-head protection;
- post-merge confirmation.

The PR #98 authority is fully consumed. No authority remains for additional commits, Ready, merge, runtime, Supabase, Security Go, F1-01, F1-02 or WDP.

## 6. Consumed authorization — post-PR #98 reconciliation / PR #99

**Lifecycle state:** `CONSUMED`  
**Source/date:** explicit user authorizations, 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `8a2eb00a9dcd46d7ee346741ca27c6081af52124`  
**Branch:** `docs/reconcile-post-pr98`  
**Result:** PR #99 — `docs(sfjm): reconcile state after PR 98 merge`  
**Final head:** `754e35406971e72ce29763bf145060868914b4d7`  
**Squash commit:** `573ecebbafc2fb0ea4a065905e0f592b9db2a308`  
**Independent audit:** `PASS WITH RESIDUAL RISK`  
**Pre-merge verification:** `PASS WITH RESIDUAL RISK`  
**Review threads:** `2 RESOLVED / 0 OPEN`

Consumed actions include:

- creation of Draft PR #99 in exactly five authorized documentation files;
- transition to Ready after exact-head verification;
- read-only review of the exact head;
- response to and resolution of the two review threads without changing the head;
- final pre-merge verification;
- squash merge with expected-head protection;
- post-merge confirmation.

The PR #99 authority is fully consumed. No authority remains for additional commits, Ready, merge, runtime, Supabase, Security Go, F1-01, F1-02 or WDP.

## 7. Consumed at Draft creation — post-PR #99 closure reconciliation

**Lifecycle state:** `CONSUMED AT DRAFT CREATION`  
**Source/date:** explicit user authorization, 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `573ecebbafc2fb0ea4a065905e0f592b9db2a308`  
**Branch:** `docs/close-pr99-reconciliation-loop`  
**Environment:** GitHub documentation only

### Files covered

```text
docs/sfjm/INDEX.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

### Authorized actions

- create the exact branch from the exact base;
- update only the six authorized SFJM documents;
- create no more than six commits;
- record PR #99 as closed and merged;
- record its final head, squash commit, audit, pre-merge verification and resolved threads;
- remove obsolete PR #99 Draft, audit, Ready and merge next actions;
- preserve all existing product and security gates;
- prevent recursive documentation-only closure reconciliation;
- define separate `ACTIVE_READ_ONLY` authorization as the prerequisite for F1-02;
- create one Draft PR titled `docs(sfjm): close PR99 cycle and prevent recursive reconciliation`.

The creation of the Draft PR containing this record consumes the authorization. No subsequent commit is authorized merely to restate that consumption.

### Prohibited

- any other file;
- additional commits after Draft creation;
- Ready or merge of the closure PR;
- rebase or force-push;
- runtime or frontend changes;
- Supabase access or modification;
- migrations, RLS, grants, policies or RPC-body changes;
- Edge Functions, Vercel, GitHub Actions or production changes;
- Security Go;
- F1-01 acceptance;
- F1-02 execution;
- WDP assignment.

Rollback remains one revert of the closure documentation PR if it is later merged.

## 8. Planned but not authorized — F1-02 execution

F1-02 is selected as the next workstream but remains `PLANNED / NOT_AUTHORIZED`.

A future authorization must identify the exact Supabase project/environment and canonical repository commit and must be read-only. A PASS from any documentation review does not authorize Supabase access, negative-test execution, remediation or Security Go.

## 9. Explicit prohibitions that remain

No standing authority exists to:

- modify runtime or frontend;
- access or modify Supabase;
- modify migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel, GitHub Actions or production;
- modify MesaCliente, PME, ADS/CAPI, Make/n8n or integrations;
- modify `wagnerjfjunior/sfjm-workspace`;
- grant Security Go;
- accept F1-01;
- award WDP;
- execute F1-02;
- mark the closure PR Ready or merge it;
- create another documentation-only reconciliation solely to record the closure PR's own merge.

## 10. Authorization evidence requirements

Future authorizations must record:

- source and date;
- repository and environment;
- target PR, branch, commit or component;
- exact allowed files or areas;
- exact prohibited areas;
- acceptance criteria;
- rollback expectation;
- expiration condition;
- lifecycle state: `PLANNED`, `ACTIVE`, `ACTIVE_READ_ONLY`, `CONSUMED`, `EXPIRED`, `REVOKED` or `SUPERSEDED`.