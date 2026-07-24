# FECH.AI — SFJM Authorizations

**Status:** ACTIVE_AUTHORIZATION_REGISTER / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Interpretation rule

An authorization is valid only within its declared scope, target, environment and expiration condition.

General phrases such as `continue`, `proceed` or `next step` must not be expanded into authorization for sensitive runtime, security, Supabase, Vercel, production or merge actions.

When authorization is ambiguous, the operational posture is fail-closed.

## 2. Active authorization — SFJM documentation v1

**Source:** explicit user instruction in the active conversation.  
**Target repository:** `wagnerjfjunior/fecha.ai`  
**Base authorized:** canonical `main` observed at `e7584b6ce2a53a88fca9974bcc448ebe9aea83ab`  
**Authorized branch:** `docs/sfjm-fechai-operational-continuity-v1`  
**Authorized outcome:** create the complete SFJM documentation layer v1 and open a Draft PR.

### Authorized files

```text
docs/sfjm/INDEX.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/handoffs/CURRENT.md
docs/bootstrap/INDEX.md
```

### Authorized actions

- create the named branch from the confirmed `main` commit;
- create the seven complete SFJM files;
- minimally update `docs/bootstrap/INDEX.md` to reference SFJM;
- commit the documentation changes on the named branch;
- open a Draft pull request to `main`;
- inspect and report the resulting PR metadata and head.

### Explicitly prohibited

- modify PR #94;
- merge PR #94 or the SFJM PR;
- mark either PR ready for review;
- modify runtime or frontend;
- modify Supabase, migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel or GitHub Actions;
- modify MesaCliente, PME, ADS/CAPI, Make/n8n or integrations;
- modify production;
- grant Security Go;
- accept WDP.

### Expiration

This authorization expires when:

- the Draft SFJM PR is opened and its resulting head is reported; or
- the authorized base becomes invalid before branch creation; or
- the user explicitly revokes or replaces the authorization.

Opening the Draft PR does not authorize review-state transition, merge or implementation.

## 3. Active authorization — PR #94 audit

A separate read-only independent audit of PR #94 is identified as the next safe action.

This record does not itself execute that audit and does not authorize any modification of PR #94.

## 4. Authorization evidence requirements

Future authorizations should record:

- source and date;
- repository and environment;
- target PR, branch, commit or component;
- exact allowed files or areas;
- exact prohibited areas;
- acceptance criteria;
- rollback expectation;
- expiration condition.