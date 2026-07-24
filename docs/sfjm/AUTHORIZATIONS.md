# FECH.AI — SFJM Authorizations

**Status:** AUTHORIZATION_REGISTER / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Interpretation rule

An authorization is valid only within its declared repository, target, environment, file scope, acceptance criteria and expiration condition.

General phrases such as `continue`, `proceed`, `next step` or `ótimo` must not be expanded into authority for runtime, security, Supabase, Vercel, production, Ready-for-review or merge actions.

When authorization is ambiguous, the posture is fail-closed.

## 2. Consumed authorization — SFJM documentation v1

**Lifecycle state:** `CONSUMED`  
**Target repository:** `wagnerjfjunior/fecha.ai`  
**Result:** PR #95 — `docs(sfjm): add FECH.AI operational continuity layer v1`  
**Merged head:** `611faa5d7275d8f40386c41b2687fb5ef6f7b5b6`  
**Squash merge commit:** `4293f383e1e93f0cfd4a63f793024eb239bfafbb`

The original creation authority and all bounded corrective authorities used during PR #95 are consumed.

They no longer authorize:

- additional commits on the former PR #95 branch;
- reopening or modifying PR #95;
- scope expansion;
- runtime or environment implementation;
- Security Go, F1-01 acceptance or WDP assignment.

## 3. Consumed authorization — Ready, thread resolution and merge

The following separately granted actions were completed and are `CONSUMED`:

- transition of PR #95 from Draft to Ready for review;
- correction of the two Codex findings in `CURRENT_STATE.md` and `NEXT_SAFE_ACTION.md`;
- exact-head reaudits and pre-merge verifications;
- resolution of the two outdated and materially satisfied Codex threads;
- squash merge of PR #95 with expected-head protection.

None of these completed actions creates standing authority for another PR, merge or implementation.

## 4. Consumed authorization — post-merge reconciliation publication

**Lifecycle state:** `CONSUMED`  
**Source:** explicit user instruction to perform FECH.AI post-merge documentation reconciliation in a separate PR.  
**Base:** canonical `main` at `4293f383e1e93f0cfd4a63f793024eb239bfafbb`  
**Branch:** `docs/sfjm-post-merge-reconciliation-95`  
**Resulting pull request:** PR #96 — `docs(sfjm): reconcile state after PR 95 merge`  
**State when consumed:** `OPEN / DRAFT / NOT_MERGED`  
**Primary risk:** stale SFJM state continuing to describe PR #95 as open, under audit or awaiting merge.

### Permitted files

```text
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

### Completed outcome

- recorded PR #95 as merged;
- recorded the new canonical `main` anchor;
- closed PR #95 creation, correction, Ready, thread-resolution and merge lifecycle states;
- replaced the obsolete PR #95 reaudit action;
- recorded the future FECH.AI external-project context contract for `sfjm-workspace` as planned but not authorized;
- opened Draft PR #96 with the four-file documentation-only scope.

### Explicit prohibitions that remain

- modify any file outside the four-file reconciliation scope;
- modify PR #94;
- modify runtime, frontend, Supabase, migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel, GitHub Actions, MesaCliente, PME, ADS/CAPI, Make/n8n, integrations or production;
- make any change in `wagnerjfjunior/sfjm-workspace`;
- grant Security Go;
- accept F1-01 or WDP;
- mark PR #96 Ready or merge it without separate authorization.

This publication authority is consumed. It does not remain active merely because PR #96 is open.

Any correction required by audit needs a new explicit, file-bounded authorization.

## 5. Active read-only boundary — exact-head audit of PR #96

**Lifecycle state:** `ACTIVE_READ_ONLY`

The only current operation authorized by this record is an independent read-only audit of the exact live head of Draft PR #96.

The auditor must:

- resolve the live PR #96 head from GitHub;
- verify exactly four changed files;
- verify cross-document consistency for merged state, consumed authorization and next action;
- verify that no runtime, PR #94 or `sfjm-workspace` change occurred;
- perform no GitHub mutation.

A PASS does not authorize Ready or merge.

## 6. Planned action — FECH.AI external-project contract in SFJM Workspace

**Lifecycle state:** `PLANNED / NOT_AUTHORIZED`

A future documentation-only task may register FECH.AI as an external project context in `wagnerjfjunior/sfjm-workspace` only after PR #96 is independently audited, separately authorized and merged.

That future task requires separate authorization and must begin with live bootstrap of both repositories.

It must not include automatic synchronization, backend integration, database integration, write-back, verified live-state claims without evidence, or automatic governance decisions.

## 7. Separate product-governance action — PR #94

The independent current-head audit of PR #94 remains separate F1-01 governance work.

This register does not modify, approve, merge or infer acceptance from PR #94.

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