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

Consumed actions include:

- bounded correction of the F1-01 evidence map;
- resolution of six materially addressed review threads;
- independent exact-head reaudit;
- pre-merge verification;
- squash merge with expected-head protection;
- post-merge confirmation.

This authorization did not accept F1-01, grant Security Go or award WDP.

## 5. Consumed authorization — post-PR #94 documentation reconciliation / PR #98

**Lifecycle state:** `CONSUMED`  
**Source/date:** explicit user authorization, 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `1caf90c60681771af6609b96ee840b190668fa0f`  
**Branch:** `agent/reconcile-f1-01-post-pr94`  
**Result:** Draft PR #98 — `docs(sfjm): reconcile F1-01 state after PR 94 merge`  
**Head at Draft creation:** `3b16c2d00ca23a6faf27df63af3ea3bf8c4b9f01`  
**Environment:** GitHub documentation only

Consumed actions include:

- reconciliation of F1-01/SFJM state after PR #94;
- recording of PR #94 final head, squash commit and reaudit result;
- removal of obsolete PR #94 audit/merge next actions;
- definition of F1-02 as the next planned read-only workstream;
- creation of Draft PR #98 in exactly six authorized documentation files;
- one bounded correction in this authorization register to mark the lifecycle as consumed after Draft creation.

### Files covered

```text
docs/audits/mvp/2026-07-05-f1-01-m1-acceptance-evidence-map.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

### Result and remaining boundary

The Draft PR was created, so the original write authority expired and is consumed. No standing authority remains to modify other files, change PR metadata, mark Ready or merge PR #98.

The reconciliation does not:

- change runtime or frontend;
- access or modify Supabase;
- change migrations, RLS, grants, policies or RPC bodies;
- change Edge Functions, Vercel, GitHub Actions or production;
- grant Security Go;
- accept F1-01;
- award WDP;
- authorize F1-02 execution;
- authorize merge of PR #98;
- authorize changes in `wagnerjfjunior/sfjm-workspace`.

Rollback remains one revert of the documentation-only reconciliation PR if it is later merged.

## 6. Planned but not authorized — F1-02 execution

F1-02 is selected as the next workstream but remains `PLANNED / NOT_AUTHORIZED`.

A future authorization must identify the exact Supabase project/environment and must be read-only. A PASS from any documentation review does not authorize Supabase access, negative-test execution, remediation or Security Go.

## 7. Explicit prohibitions that remain

No standing authority exists to:

- modify PR #98 files or metadata beyond the consumed bounded correction recorded above;
- mark PR #98 Ready or merge it;
- modify runtime or frontend;
- modify Supabase, migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel, GitHub Actions or production;
- modify MesaCliente, PME, ADS/CAPI, Make/n8n or integrations;
- modify `wagnerjfjunior/sfjm-workspace`;
- grant Security Go;
- accept F1-01;
- award WDP;
- execute F1-02.

## 8. Authorization evidence requirements

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
