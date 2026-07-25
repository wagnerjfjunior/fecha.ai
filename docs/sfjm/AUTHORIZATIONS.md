# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-25`

## 1. Interpretation rule

An authority is valid only for its exact repository, target, environment, files, operations, acceptance criteria, prohibitions and expiration condition.

General language never silently authorizes runtime, Supabase, Ready, merge, Security Go or data access.

## 2. PR #101 lifecycle

```text
PR #101: CLOSED / MERGED
Final head: 003850d012a299a947452fa5a8135cd454998f15
Squash: affbae1a598928010b0fa7db967734de522c13b4
Authority: CONSUMED
```

The merge made the F1-02 finding record and master plan canonical. It did not authorize implementation or Security Go.

## 3. PR #102 Draft-creation authority

```text
Repository: wagnerjfjunior/fecha.ai
PR: #102
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Pre-correction head: fc83ed752217bfc39810dfba38e93405bc7382b8
Lifecycle state: CONSUMED AT DRAFT CREATION
```

The authority to create the branch, seven initial documentation commits and one Draft PR expired when PR #102 was created.

```text
Additional commits under Draft-creation authority: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Supabase: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
```

## 4. Independent audit result at the pre-correction head

GPT0, GPT1 and GPT3 independently validated the live GitHub target and returned `FAIL` for Ready at:

```text
Head: fc83ed752217bfc39810dfba38e93405bc7382b8
State: OPEN / DRAFT
Commits: 7
Changed files: 7
```

Required corrections included master-plan supersession, B1 containment, lifecycle authority, environment classification, fixture invariants, rollback distinction and SFJM freshness.

## 5. Single corrective-commit authority

The product authority authorized one corrective commit on the existing branch plus one PR-description update.

### Authorized files

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

### Authorized operations

- create exactly one corrective commit whose parent is `fc83ed752217bfc39810dfba38e93405bc7382b8`;
- modify only the eight documents above;
- update only the PR #102 description;
- validate the new head and exact eight-file diff.

### Prohibited

- runtime/frontend;
- migrations, SQL, RLS, grants, policies, RPCs, Auth or Supabase;
- data, users, fixtures or tests;
- Vercel or Actions;
- comments, reviews or reviewers;
- Ready or merge;
- PR-01;
- Security Go, F1-02 acceptance or WDP.

### Lifecycle state

```text
Single corrective-commit authority: CONSUMED BY THE COMMIT CONTAINING THIS RECORD
PR-description update authority: CONSUMED AFTER FINAL HEAD IS RECORDED IN PR METADATA
Post-correction commits: NOT AUTHORIZED
```

The exact final corrective head is authoritative in live PR metadata and the updated PR description. Embedding a commit's own SHA in that same commit would be self-referential and require an unauthorized recursive commit.

## 6. Future authority types

### `WINDOW_IMPLEMENTATION`

One bounded technical PR. No Ready, merge or live application.

### `TECHNICAL_PR_LIFECYCLE`

Ready and/or exact-head merge after audit. No Supabase application.

### `CONTROLLED_BETA_PRIMARY_CHANGE`

One exact live operation with project/ref, preflight, impact, smoke, monitoring, rollback and expiration.

### `ADMINISTRATIVE_ROLE_CHANGE`

One intentional role assignment, including a possible named `admin_global`, with verified identity, business necessity, least privilege, server-side operation, audit trail and revocation plan. It is not a security test and does not prove self-escalation prevention.

### `SECURITY_GATE`

Final evidence-based decision only.

## 7. Current authority state after correction

```text
PR #102 correction: CONSUMED
Additional commits: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01 implementation: NOT AUTHORIZED
Supabase read/mutation: NOT AUTHORIZED
Negative tests: NOT AUTHORIZED
Intentional admin_global assignment: NOT AUTHORIZED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```
