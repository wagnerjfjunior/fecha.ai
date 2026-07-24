# FECH.AI — SFJM Authorizations

**Status:** AUTHORIZATION_REGISTER / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Interpretation rule

An authorization is valid only within its declared scope, target, environment and expiration condition.

General phrases such as `continue`, `proceed` or `next step` must not be expanded into authorization for sensitive runtime, security, Supabase, Vercel, production, Ready-for-review or merge actions.

When authorization is ambiguous, the operational posture is fail-closed.

## 2. Consumed authorization — SFJM documentation v1

**Lifecycle state:** `CONSUMED`  
**Source:** explicit user instruction in the active conversation.  
**Target repository:** `wagnerjfjunior/fecha.ai`  
**Base authorized:** canonical `main` observed at `e7584b6ce2a53a88fca9974bcc448ebe9aea83ab`  
**Authorized branch:** `docs/sfjm-fechai-operational-continuity-v1`  
**Authorized outcome:** create the complete SFJM documentation layer v1 and open a Draft PR.  
**Resulting pull request:** PR #95 — `docs(sfjm): add FECH.AI operational continuity layer v1`  
**State when consumed:** `OPEN / DRAFT / NOT_MERGED`  
**Head observed when the authorization was consumed:** `6ba8c487e6f251d48d54c365e11b2e851777a782`

The recorded head above is the publication head that completed the original creation authorization. It is not a permanently current head. Any later correction commit makes that anchor stale and requires live GitHub verification.

### Files covered by the consumed authorization

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

### Actions completed under that authorization

- created the named branch from the confirmed `main` commit;
- created the seven complete SFJM files;
- minimally updated `docs/bootstrap/INDEX.md` to reference SFJM;
- committed the documentation changes on the named branch;
- opened Draft PR #95 to `main`;
- inspected and reported the resulting PR metadata and publication head.

### Expiration record

The authorization expired when Draft PR #95 was opened and its resulting head was reported.

It no longer authorizes:

- creation of another branch;
- broadening the eight-file scope;
- additional discretionary documentation work;
- Ready-for-review transition;
- merge;
- runtime or environment implementation.

## 3. Current limited authorization — correct audit findings in PR #95

**Lifecycle state:** `ACTIVE_UNTIL_CORRECTION_HEAD_IS_PUBLISHED`  
**Source:** user supplied the independent audit result and instructed continuation of the governed flow.  
**Target:** Draft PR #95 only.  
**Permitted files:**

```text
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

**Permitted actions:**

- correct only the two findings classified `REQUIRED IN THIS PR`;
- publish the resulting correction commit or commits to the existing PR #95 branch;
- inspect and report the new live head and exact changed-file scope;
- prepare the exact-head re-audit handoff.

**Explicitly prohibited:**

- modify any other file;
- modify PR #94;
- mark PR #95 Ready for review;
- merge PR #95 or PR #94;
- modify runtime, frontend, Supabase, migrations, RLS, grants, policies or RPC bodies;
- modify Edge Functions, Vercel, GitHub Actions, MesaCliente, PME, ADS/CAPI, Make/n8n, integrations or production;
- grant Security Go;
- accept F1-01 or WDP.

### Expiration

This correction authorization expires when:

- the correction is published and its new live PR #95 head is reported; or
- either permitted file scope is broadened; or
- the user explicitly revokes or replaces the authorization.

After expiration, the only next permitted operation is a separate read-only independent re-audit of the exact new head, unless the user grants another explicit authorization.

## 4. Planned read-only authorization — PR #95 re-audit

A separate read-only independent re-audit of PR #95 is the next safe action after the correction head is published.

The re-audit must:

- use the exact new live head;
- verify only the current PR state and complete diff;
- confirm that the two required findings were corrected without scope broadening;
- perform no GitHub mutation.

This record does not authorize Ready-for-review transition, merge or any modification.

## 5. Separate planned action — PR #94 audit

A read-only independent audit of PR #94 remains the product-governance next action recorded by the SFJM layer.

It is not part of the PR #95 correction and this authorization register does not modify or approve PR #94.

## 6. Authorization evidence requirements

Future authorizations must record:

- source and date;
- repository and environment;
- target PR, branch, commit or component;
- exact allowed files or areas;
- exact prohibited areas;
- acceptance criteria;
- rollback expectation;
- expiration condition;
- lifecycle state: `PLANNED`, `ACTIVE`, `CONSUMED`, `EXPIRED`, `REVOKED` or `SUPERSEDED`.
