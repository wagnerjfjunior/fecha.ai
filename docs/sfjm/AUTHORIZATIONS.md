# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

An authority is valid only for its exact repository, target, environment, files or objects, operations, acceptance criteria, prohibitions and expiration condition.

General language such as `continue`, `implement`, `approve`, `go ahead` or `use the primary database` never silently authorizes additional commits, Ready, merge, Supabase, runtime/frontend, fixtures/tests, administrative role assignment, Security Go, F1-02 acceptance or WDP.

When scope, head, evidence or terminology is inconsistent, stop fail-closed.

## 2. Canonical baseline

```text
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
Squash on main: affbae1a598928010b0fa7db967734de522c13b4
Authority: CONSUMED
```

PR #101 made the F1-02 findings and detailed remediation master plan canonical. It did not authorize technical execution or Security Go.

## 3. PR #102 authority history

### Draft creation

```text
Initial Draft head: fc83ed752217bfc39810dfba38e93405bc7382b8
State: CONSUMED AT DRAFT CREATION
```

### First correction

```text
Parent: fc83ed752217bfc39810dfba38e93405bc7382b8
Head: 6b7d96fb26d6589641bc079146db9c3f429b9bd2
State: CONSUMED
```

Reaudits produced GPT0 `FAIL`, GPT1 `PASS WITH RESIDUAL RISK` and GPT3 `PASS WITH RESIDUAL RISK`. No majority rule applies.

### Detailed-master-plan restoration

```text
Parent: 6b7d96fb26d6589641bc079146db9c3f429b9bd2
Head: 7b8c23bd375d750e73d888f140c8c44a840280a5
Master-plan blob: ea161050c535b848ff927133830984f543c1104d
State: CONSUMED
```

GPT0 confirmed the normative regression was resolved and required two final documentary corrections: lifecycle metadata and legacy authority-name reconciliation.

### Final lifecycle-and-alias correction

```text
Required parent: 7b8c23bd375d750e73d888f140c8c44a840280a5
Primary risk:
correct stale lifecycle metadata and reconcile authority names
without modifying the detailed master plan
```

Authorized paths:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

Explicitly prohibited:

- `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md`;
- `docs/sfjm/BLOCKED_ACTIONS.md`;
- every other file;
- runtime, frontend, SQL, migrations, RLS, grants, policies, RPCs, Auth or Supabase;
- data, users, fixtures or tests;
- Vercel, GitHub Actions, comments, reviews or reviewers;
- Ready, merge, PR-01, `admin_global` assignment, Security Go, F1-02 acceptance or WDP.

```text
Final lifecycle-and-alias correction authority:
CONSUMED BY THE COMMIT CONTAINING THIS RECORD

PR-description update authority:
CONSUMED AFTER THE FINAL HEAD IS RECORDED

Further commits:
NOT AUTHORIZED
```

The final commit cannot contain its own SHA without creating a recursive hash change. Live PR metadata and the updated PR description are authoritative for the final head.

## 4. Authority vocabulary

### `WINDOW_IMPLEMENTATION`

One bounded technical PR. No Ready, merge or live application.

### `TECHNICAL_PR_LIFECYCLE`

Ready and/or exact-head merge after independent audit and fresh GitHub validation. No Supabase application.

### `CONTROLLED_BETA_PRIMARY_CHANGE`

One exact live Supabase operation with project/ref, objects, preflight, impact, order, smoke, monitoring, stop conditions, rollback, evidence, operator and expiration.

### `ADMINISTRATIVE_ROLE_CHANGE`

One intentional named administrative-role assignment under server-side control, audit and revocation. It is not a security test and does not prove B1 remediation.

### `SECURITY_GATE`

Final evidence-based decision only. It cannot retroactively authorize missing evidence or operations.

## 5. Legacy-name mapping

```text
PR_LIFECYCLE
= TECHNICAL_PR_LIFECYCLE

PRODUCTION_CHANGE
= CONTROLLED_BETA_PRIMARY_CHANGE
```

These are strict aliases only. They create no additional authority, widen no scope, bypass no exact-head gate and cannot combine GitHub lifecycle with Supabase application. They are invalid without a new exact and unexpired authorization.

`WINDOW_IMPLEMENTATION`, `ADMINISTRATIVE_ROLE_CHANGE` and `SECURITY_GATE` remain separate.

## 6. Current authority state

```text
PR #102: OPEN / DRAFT
Final correction authority: CONSUMED
Additional commits: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase read/mutation: NOT AUTHORIZED
Runtime/frontend: NOT AUTHORIZED
Fixtures/tests: NOT AUTHORIZED
Intentional admin_global assignment: NOT AUTHORIZED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```
