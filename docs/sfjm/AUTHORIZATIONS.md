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

## 3. Consumed authorization — correct first audit findings in PR #95

**Lifecycle state:** `CONSUMED`  
**Source:** user supplied the first independent audit result and continued the governed correction flow.  
**Target:** Draft PR #95 only.  
**Permitted files:**

```text
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

**Permitted actions completed:**

- corrected only the two findings classified `REQUIRED IN THIS PR`;
- published the correction commits to the existing PR #95 branch;
- inspected and reported the new live head;
- prepared the exact-head re-audit handoff.

**Completion evidence:**

- first corrective commit: `914bbd2b688fd0bb5d00a22a0117a99fd5505b76`;
- second corrective commit and reported correction head: `06d530b185558025eca4173a574b588729866941`;
- re-audit confirmed the correction scope remained limited to the two authorized files.

### Expiration record

This authorization expired when the corrected PR #95 head was published and reported.

It no longer authorizes:

- any further modification of the two files;
- any additional correction commit;
- scope broadening;
- Ready-for-review transition;
- merge;
- runtime, environment or product implementation.

## 4. Active read-only authorization — exact-head re-audit of PR #95

**Lifecycle state:** `ACTIVE_READ_ONLY`  
**Source:** the governed flow requires independent verification after each corrective head.  
**Target:** current live head of Draft PR #95.  
**Permitted operation:** independent read-only re-audit only.

The re-audit must:

- resolve the exact live PR #95 head from GitHub before analysis;
- verify the complete eight-file PR scope;
- confirm that the prior authorization lifecycle inconsistency is closed;
- confirm that no new scope broadening, overclaim or authorization ambiguity was introduced;
- perform no GitHub mutation.

This authorization does not permit:

- editing files;
- publishing commits;
- modifying PR metadata;
- marking Ready for review;
- merge;
- changing PR #94;
- modifying runtime, frontend, Supabase, Vercel, production or integrations;
- granting Security Go;
- accepting F1-01 or WDP.

### Expiration

This read-only authorization expires when:

- the independent audit result for the exact live head is produced; or
- the PR #95 head changes before the audit result; or
- the user explicitly revokes or replaces it.

A `PASS` result does not itself authorize Ready-for-review transition or merge.

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
- lifecycle state: `PLANNED`, `ACTIVE`, `ACTIVE_READ_ONLY`, `CONSUMED`, `EXPIRED`, `REVOKED` or `SUPERSEDED`.
