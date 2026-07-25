# FECH.AI — SFJM Next Safe Action

**Status:** `CONTROLLED_BETA_PRIMARY_STRATEGY_DRAFT_AND_AUDIT`  
**Observed on:** `2026-07-25`

## 1. Current safe state

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
F1-02 evidence/program baseline: CANONICAL
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

The product authority accepted beta availability and possible data-loss risk for informed MVP Família participants. That decision does not accept security-boundary failures.

## 2. Active bounded work

```text
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Title: docs(security): adopt controlled beta primary remediation strategy
Type: documentation-only
Primary risk: replace mandatory isolated-lab prerequisite with Controlled Beta Primary governance
Rollback: one revert of the documentation PR
```

Expected changed files:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/handoffs/CURRENT.md
```

No runtime, frontend, migration, SQL, RLS, grant, policy, RPC, Auth, Vercel, Action or Supabase object belongs to this PR.

## 3. Next single safe action

1. complete the seven-file documentation change;
2. open one Draft PR with the exact authorized title;
3. validate base, branch, head and changed files live;
4. verify that the new strategy supersedes only the mandatory isolated-lab clauses;
5. verify that Security Go remains denied and broad commercialization blocked;
6. confirm no technical or environment authority is implied;
7. send the exact final head to independent GPT0/GPT1/GPT3 audit.

No commit is authorized after Draft creation unless a concrete audit finding receives a new bounded correction authority.

## 4. Acceptance criteria for the strategy PR

The final head must prove:

- Controlled Beta Primary is an environment/risk strategy, not Security Go;
- informed beta participants accept downtime and possible data loss;
- real users and sensitive data still require strict tenant and privilege isolation;
- offensive, destructive or cross-tenant testing against real records is prohibited;
- synthetic validation requires a manifest, cleanup, stop conditions and separate authority;
- each future technical PR has one primary risk and rollback;
- each primary-environment mutation requires a separate environment authorization;
- broad paid commercialization remains blocked;
- PR-01 remains unauthorized;
- no Supabase, runtime or production mutation occurred.

## 5. Actions blocked until this PR lifecycle completes

- start PR-01;
- create or apply migrations;
- alter RLS, grants, policies, functions/RPCs or Auth;
- alter frontend/runtime;
- create synthetic fixtures in the primary project;
- run negative tests;
- access or mutate Supabase;
- grant Security Go or WDP;
- describe FECH.AI as generally production-ready;
- mark this PR Ready or merge without separate authorization.

## 6. Action after strategy lifecycle completion

After independent audit, Ready, merge and post-merge confirmation, the next safe action becomes:

```text
Define PR-01 as one bounded security risk with:
- exact repository base/branch/files;
- exact Supabase objects;
- preflight;
- migration/change;
- rollback;
- synthetic fixtures and tests;
- smoke and monitoring;
- separate GitHub lifecycle authority;
- separate primary-environment mutation authority.
```

The strategy merge alone will not authorize PR-01 or any database operation.

## 7. Stop conditions

Stop fail-closed if:

- `main` differs from the authorized base before branch creation;
- any changed file is outside the exact documentation list;
- the PR implies Security Go or broad commercialization;
- the amendment permits tests against real data;
- the amendment removes rollback, audit or separation-of-duty controls;
- runtime, Supabase or Auth changes appear;
- evidence is missing or the final head cannot be validated.