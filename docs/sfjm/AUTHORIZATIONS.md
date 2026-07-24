# FECH.AI — SFJM Authorizations

**Status:** AUTHORIZATION_REGISTER / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Interpretation rule

An authorization is valid only within its declared repository, target, environment, file scope, acceptance criteria and expiration condition.

General phrases such as `continue`, `proceed`, `next step` or `ótimo` must not be expanded into authority for runtime, security, Supabase, Vercel, production, Ready-for-review or merge actions.

When authorization is ambiguous, the posture is fail-closed.

## 2. Consumed authorization — SFJM documentation v1 / PR #95

**Lifecycle state:** `CONSUMED`  
**Target repository:** `wagnerjfjunior/fecha.ai`  
**Result:** PR #95 — `docs(sfjm): add FECH.AI operational continuity layer v1`  
**Merged head:** `611faa5d7275d8f40386c41b2687fb5ef6f7b5b6`  
**Squash merge commit:** `4293f383e1e93f0cfd4a63f793024eb239bfafbb`

Consumed actions include:

- branch and file creation;
- bounded corrective commits;
- Ready transition;
- exact-head audits and pre-merge verification;
- review-thread resolution;
- squash merge with expected-head protection.

No PR #95 authority remains active.

## 3. Consumed authorization — post-merge reconciliation / PR #96

**Lifecycle state:** `CONSUMED`  
**Target repository:** `wagnerjfjunior/fecha.ai`  
**Base used:** `4293f383e1e93f0cfd4a63f793024eb239bfafbb`  
**Branch:** `docs/sfjm-post-merge-reconciliation-95`  
**Result:** PR #96 — `docs(sfjm): reconcile state after PR 95 merge`  
**Merged head:** `91d27a4aa676f3e174ab000ca23992b69fc90a90`  
**Squash merge commit:** `4668cc1dde4b990791583c85f5b36a5d4b55d6a8`

Consumed actions include:

- creation of the four-file reconciliation branch and Draft PR;
- bounded corrections in `CURRENT_STATE.md` and `NEXT_SAFE_ACTION.md`;
- correction of the PR description without changing the head;
- independent exact-head audits;
- Ready transition;
- fresh pre-merge verification;
- squash merge with expected-head protection;
- post-merge confirmation of PR state and new `main` tip.

### Files covered by the PR #96 reconciliation

```text
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

No PR #96 authority remains active merely because its records are present in `main`.

## 4. Current authorization state

**Lifecycle state:** `NO_ACTIVE_AUTHORIZATION`

There is currently no active write authority and no active read-only audit authority recorded by this register.

The following candidates are documented but remain `PLANNED / NOT_AUTHORIZED`:

- independent read-only current-head audit of FECH.AI PR #94;
- documentation-only FECH.AI external-project context contract in `wagnerjfjunior/sfjm-workspace`.

Neither candidate may begin without a separate explicit authorization.

## 5. Candidate boundary — PR #94 audit

If separately authorized, a PR #94 audit must be read-only and must begin by resolving live GitHub evidence.

It must not:

- edit PR #94 files or metadata;
- mark PR #94 Ready;
- merge PR #94;
- accept F1-01;
- grant Security Go;
- award WDP;
- start runtime or Supabase implementation.

A PASS would not itself authorize any write action.

## 6. Candidate boundary — SFJM Workspace contract

If separately authorized, a future documentation-only task may register FECH.AI as an external project context in `wagnerjfjunior/sfjm-workspace`.

It must begin with live bootstrap of both repositories and must not include:

- automatic synchronization;
- GitHub API ingestion presented as operational truth;
- backend or database integration;
- Supabase integration;
- write-back to FECH.AI;
- verified live-state claims without fresh evidence;
- automatic approval, merge, Security Go, F1-01 acceptance or WDP decisions.

## 7. Explicit prohibitions that remain

No standing authority exists to:

- create additional FECH.AI commits;
- modify PR #94;
- modify runtime or frontend;
- modify Supabase, migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel, GitHub Actions or production;
- modify MesaCliente, PME, ADS/CAPI, Make/n8n or integrations;
- change `wagnerjfjunior/sfjm-workspace`;
- grant Security Go;
- accept F1-01;
- award WDP.

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
