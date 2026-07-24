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

## 4. Consumed-by-publication authorization — post-merge reconciliation

**Lifecycle state:** `CONSUMED_BY_PUBLICATION`  
**Source:** explicit user instruction to perform FECH.AI post-merge documentation reconciliation in a separate PR.  
**Base:** canonical `main` at `4293f383e1e93f0cfd4a63f793024eb239bfafbb`  
**Branch:** `docs/sfjm-post-merge-reconciliation-95`  
**Primary risk:** stale SFJM state continuing to describe PR #95 as open, under audit or awaiting merge.

### Permitted files

```text
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

### Permitted outcome

- record PR #95 as merged;
- record the new canonical `main` anchor;
- close all PR #95 authorization lifecycle states;
- replace the obsolete PR #95 reaudit action;
- record the separately gated future FECH.AI registration contract for `sfjm-workspace`;
- open a Draft documentation-only reconciliation PR.

### Explicit prohibitions

- modify any other file;
- modify PR #94;
- modify runtime, frontend, Supabase, migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel, GitHub Actions, MesaCliente, PME, ADS/CAPI, Make/n8n, integrations or production;
- make any change in `wagnerjfjunior/sfjm-workspace`;
- grant Security Go;
- accept F1-01 or WDP;
- mark the reconciliation PR Ready or merge it without separate authorization.

This authority is consumed by publication of the bounded reconciliation content. It does not remain active merely because the Draft PR is still open.

## 5. Planned action — FECH.AI external-project contract in SFJM Workspace

**Lifecycle state:** `PLANNED / NOT_AUTHORIZED`

A future documentation-only task may register FECH.AI as an external project context in `wagnerjfjunior/sfjm-workspace` after this reconciliation is independently audited and merged.

That future task requires separate authorization and must begin with live bootstrap of both repositories.

It must not include automatic synchronization, backend integration, database integration, write-back, verified live-state claims without evidence, or automatic governance decisions.

## 6. Separate product-governance action — PR #94

The independent current-head audit of PR #94 remains separate F1-01 governance work.

This register does not modify, approve, merge or infer acceptance from PR #94.

## 7. Authorization evidence requirements

Future authorizations must record:

- source and date;
- repository and environment;
- target PR, branch, commit or component;
- exact allowed files or areas;
- exact prohibited areas;
- acceptance criteria;
- rollback expectation;
- expiration condition;
- lifecycle state: `PLANNED`, `ACTIVE`, `ACTIVE_READ_ONLY`, `CONSUMED`, `CONSUMED_BY_PUBLICATION`, `EXPIRED`, `REVOKED` or `SUPERSEDED`.