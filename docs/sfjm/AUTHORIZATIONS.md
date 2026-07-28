# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / PR103_SMOKE_DOC_PR_PUBLICATION_CONSUMED / FAIL_CLOSED`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, environment, object, operation, prohibitions and expiration stated by the Product Authority. Recording a past authorization does not reactivate it.

## 2. Previously consumed authorities

```text
PR #103 Ready/merge/application authority: CONSUMED
PR #103 controlled production smoke authority: CONSUMED
Synthetic fixture cleanup authority: CONSUMED
PR #104 lifecycle/application authority: CONSUMED
PR #105 documentation closure authority: CONSUMED
PR #106 documentation lifecycle authority: CONSUMED
```

Results relevant to this record:

```text
PR #103: CLOSED / MERGED
Migration 20260727080929_f1_02_password_state_rpc: APPLIED
RPC catalog contract: VALIDATED
Authenticated positive smoke: PASS
Immediate runtime idempotency: PASS
Synthetic Auth/profile/team cleanup: COMPLETE
```

No consumed authority authorizes repetition or expansion.

## 3. Current Product Authority instruction

On `2026-07-28`, Product Authority authorized only the documentation PR that records the completed smoke and expressly required PR-02 to remain unauthorized until this documentation PR is closed.

### 3.1 Authorized repository and base

```text
Repository: wagnerjfjunior/fecha.ai
Canonical main at authorization preflight: 9624900ada5d29e24476ab6a0a0907cb4854e509
Branch: docs/pr103-authenticated-smoke-evidence
PR title: docs(security): record PR103 authenticated smoke
PR mode: Draft
```

### 3.2 Authorized paths

Exactly:

```text
docs/security/evidence/2026-07-28-pr103-authenticated-smoke-and-idempotency.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

### 3.3 Authorized operations

Only:

- create the dedicated branch from the confirmed `main`;
- create the seven-file documentation delta;
- publish the initial commits to that branch;
- open one Draft pull request;
- perform read-only post-publication metadata and changed-file verification;
- report branch, commits, head, files and PR URL.

### 3.4 Expiration and consumption

```text
Branch/file/PR publication authority:
CONSUMED when the initial Draft PR is created.

It expires immediately if:
- an eighth path appears;
- runtime, frontend or Supabase content appears;
- the operation is stopped;
- the confirmed base changes before branch creation.
```

After initial publication, no additional commit is authorized without a material documented finding and a new exact Product Authority instruction.

## 4. Explicit non-authorizations

```text
Ready
merge
GitHub comment or review
additional commit
runtime
frontend
Supabase
SQL
migration
RPC or RPC-body change
Auth
RLS
policies
grants
Edge Functions
Vercel
GitHub Actions
production mutation
PR-02 branch or implementation
PR-03
Security Go
F1-02 acceptance
WDP change
```

## 5. Future authorities required

A new explicit authority is required for:

- a corrective commit;
- GPT4 lifecycle handling that mutates metadata;
- marking the documentation PR Ready;
- merging the documentation PR;
- any rollback;
- starting or implementing PR-02;
- deploying PR-02;
- any new runtime or Supabase test;
- F1-02 acceptance;
- Security Go.

PR-02 may be authorized only after this documentation PR is closed and the resulting canonical `main` is confirmed.

## 6. Audit-finality rule

The authenticated runtime smoke is a material new evidence event. It permits revalidation only of claims affected by that evidence and of the current seven-file documentation delta.

```text
NO OTHER INVALIDATION EVENT
→ NO OTHER REAUDIT
```

Historical unknown gate verdicts must not be invented merely to complete a record.
