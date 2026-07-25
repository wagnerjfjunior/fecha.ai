# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

An authority is valid only for its exact repository, target, environment, files or objects, operations, acceptance criteria, prohibitions and expiration condition.

General language such as `continue`, `implement`, `use the primary database`, `approve` or `go ahead` never silently authorizes:

- additional commits;
- Ready;
- merge;
- Supabase reads or mutations;
- runtime or frontend changes;
- tests or fixtures;
- administrative role assignment;
- Security Go;
- F1-02 acceptance;
- WDP.

When scope, head or evidence is inconsistent, stop fail-closed.

## 2. PR #101 lifecycle

```text
PR: #101
State: CLOSED / MERGED
Final head: 003850d012a299a947452fa5a8135cd454998f15
Squash: affbae1a598928010b0fa7db967734de522c13b4
Authority: CONSUMED
```

PR #101 made the F1-02 findings and detailed remediation master plan canonical. It did not authorize implementation, Supabase mutation, Security Go, F1-02 acceptance or WDP.

## 3. PR #102 Draft-creation authority

```text
PR: #102
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Initial final head: fc83ed752217bfc39810dfba38e93405bc7382b8
State: CONSUMED AT DRAFT CREATION
```

The authority to create the branch, initial documentation commits and one Draft PR expired when PR #102 was created.

## 4. First corrective authority

The first corrective authority produced:

```text
Parent: fc83ed752217bfc39810dfba38e93405bc7382b8
Corrective head: 6b7d96fb26d6589641bc079146db9c3f429b9bd2
Commit message: docs(security): correct controlled beta primary strategy
State: CONSUMED
```

That correction resolved the environment model, B1 containment, synthetic-graph rules, rollback distinction and lifecycle separation. Independent reaudits then produced:

```text
GPT0: FAIL — master-plan normative regression
GPT1: PASS WITH RESIDUAL RISK
GPT3: PASS WITH RESIDUAL RISK
Ready recommendation aggregate: NO
```

No majority rule applies. The documentary blocker controls the next action.

## 5. Detailed-master-plan restoration authority

The Product Authority authorized exactly one additional documentation commit.

### Required parent

```text
6b7d96fb26d6589641bc079146db9c3f429b9bd2
```

### Primary risk

```text
Restore the complete normative F1-02 master plan
without reversing the Controlled Beta Primary decision.
```

### Authorized files

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

### Authorized operations

- create one commit on the existing branch;
- restore `F1-02_REMEDIATION_MASTER_PLAN.md` to the exact detailed baseline blob:
  `ea161050c535b848ff927133830984f543c1104d`;
- preserve the existing strategy amendment as the sole lab-only supersession artifact;
- preserve the original detailed technical contracts, matrices, PR sequence, tests, rollback, evidence and gates;
- update the five SFJM records listed above;
- update only the PR #102 description;
- validate parent, final head, commit count and changed-file scope.

### Explicitly prohibited

- new condensation or broad rewrite of the master plan;
- removal of any non-lab requirement;
- changing the original PR-01 → PR-02 → PR-03 compatibility sequence;
- files outside the six-path corrective scope;
- runtime or frontend;
- SQL, migrations, RLS, grants, policies, RPCs, functions or Auth;
- Supabase access or mutation;
- data, users, fixtures or tests;
- Vercel or GitHub Actions;
- comments, reviews or reviewer requests;
- Ready or merge;
- PR-01;
- `admin_global` assignment;
- Security Go, F1-02 acceptance or WDP.

### Lifecycle state

```text
Detailed-master-plan restoration authority:
CONSUMED BY THE COMMIT CONTAINING THIS RECORD

PR-description update authority:
CONSUMED AFTER THE FINAL HEAD IS RECORDED IN PR METADATA

Further commits:
NOT AUTHORIZED
```

The final commit cannot contain its own SHA without creating a recursive hash change. Live PR metadata and the updated PR description are authoritative for the final head.

## 6. Future authority types

### `WINDOW_IMPLEMENTATION`

Authorizes one bounded technical PR with exact repo, base, branch, files, objective, tests and rollback. It does not authorize Ready, merge or live application.

### `TECHNICAL_PR_LIFECYCLE`

Authorizes Ready and/or exact-head merge after independent audit and fresh GitHub validation. It does not authorize Supabase application.

### `CONTROLLED_BETA_PRIMARY_CHANGE`

Authorizes one exact live Supabase operation with project/ref, affected objects, preflight, impact, application order, smoke, monitoring, stop conditions, rollback, evidence and expiration.

### `ADMINISTRATIVE_ROLE_CHANGE`

Authorizes one intentional named role assignment under server-side control, audit and revocation. It is not a security test and does not prove B1 remediation.

### `SECURITY_GATE`

Authorizes only a final evidence-based decision. It cannot retroactively authorize missing evidence.

## 7. Current authority state

```text
PR #102: OPEN / DRAFT
Detailed restoration correction: CONSUMED
Additional commits: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase read/mutation: NOT AUTHORIZED
Fixtures/tests: NOT AUTHORIZED
Intentional admin_global assignment: NOT AUTHORIZED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```
