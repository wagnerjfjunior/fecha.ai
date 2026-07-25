# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-25`

## 1. Interpretation rule

An authorization is valid only within its declared repository, base/head, branch, environment, files/objects, operations, acceptance criteria, prohibitions and expiration condition.

General phrases never silently authorize runtime, Supabase, Auth, Ready, merge or production operations. When material scope is ambiguous, stop fail-closed.

## 2. Relevant consumed lifecycle authorities

### PR #94–#100 governance/evidence cycle

```text
State: CONSUMED
Outcome: documentation and governance baselines merged
Security Go/F1-02/WDP authority: NOT GRANTED
```

### F1-02 live read-only inspection

```text
State: CONSUMED
Project: uobxxgzshrmbtjfdolxd / Discador-MesaCliente
Method: read-only metadata and definition inspection
Mutations: ZERO
Negative tests: ZERO
Security Go: DENIED
```

### PR #101 — F1-02 remediation program

```text
State: CONSUMED
Repository: wagnerjfjunior/fecha.ai
Branch: docs/f1-02-security-remediation-program
Final head: 003850d012a299a947452fa5a8135cd454998f15
Squash: affbae1a598928010b0fa7db967734de522c13b4
PR state: CLOSED / MERGED
Type: documentation-only
```

PR #101 made the finding record and remediation baseline canonical. It did not authorize technical implementation, Supabase mutation, Security Go or WDP.

## 3. Product-risk decision

**Source/date:** explicit Wagner instruction, `2026-07-25`

Wagner accepted for informed MVP Família beta participants:

- downtime and maintenance;
- manual recovery/support;
- possible beta data loss;
- absence of a paid SLA.

This decision does not authorize or accept:

- privilege escalation;
- cross-tenant access;
- sensitive-data disclosure;
- destructive tests against real data;
- broad commercialization;
- Security Go.

## 4. Controlled Beta Primary strategy Draft authority

**Lifecycle state:** `ACTIVE UNTIL DRAFT PR CREATION`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `affbae1a598928010b0fa7db967734de522c13b4`  
**Branch:** `docs/f1-02-controlled-beta-primary-strategy`  
**Title:** `docs(security): adopt controlled beta primary remediation strategy`  
**Environment:** GitHub documentation only

### Authorized files

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/handoffs/CURRENT.md
```

### Authorized actions

- create the exact branch from the exact base;
- create/update only the seven listed documentation files;
- record the Controlled Beta Primary strategy;
- record accepted beta availability/data-loss risk;
- preserve security and tenant-isolation boundaries;
- reconcile SFJM state, blocks, evidence, authorization and handoff;
- open one Draft PR with the exact title.

### Mandatory content

- primary Supabase may be used only by future bounded, separately authorized windows;
- real data is never a security-test fixture;
- offensive/destructive tests against real records are prohibited;
- synthetic validation requires exact authority and containment;
- one PR equals one primary risk and rollback;
- Security Go remains denied;
- F1-02 remains in remediation;
- broad paid commercialization remains blocked;
- PR-01 remains separately authorized work.

### Prohibited

- runtime/frontend changes;
- migrations or SQL;
- RLS, grants, policies, functions/RPCs or Auth changes;
- Supabase access or mutation;
- test users/fixtures or negative tests;
- Vercel or GitHub Actions changes;
- Ready or merge;
- PR-01 implementation;
- Security Go, F1-02 acceptance or WDP.

### Expiration

This authority is consumed when the Draft PR is created and its final head/files are reported.

No post-Draft correction commit is authorized without a new bounded correction authority.

## 5. Future authorization types

### `STRATEGY_PR_LIFECYCLE`

May authorize audit corrections, Ready and exact-head squash merge for this documentation PR. It does not authorize technical implementation.

### `WINDOW_IMPLEMENTATION`

May authorize one technical PR for one primary risk, with exact files, Supabase objects, tests and rollback. It does not authorize application to the primary project.

### `CONTROLLED_BETA_PRIMARY_CHANGE`

Required before one exact operation against `uobxxgzshrmbtjfdolxd`. Must declare:

- exact canonical repository commit;
- exact migration/configuration identity;
- exact objects and SQL/operation;
- preflight;
- accepted data/availability impact;
- synthetic fixture/test scope;
- smoke checks and monitoring;
- rollback and stop conditions;
- responsible operator;
- expiration after execution.

### `SECURITY_GATE`

May record F1-02 acceptance or denial after current evidence and independent review. It is not implied by implementation success.

## 6. Current authority state

```text
Strategy documentation branch/commits/Draft creation: AUTHORIZED
Strategy Ready: NOT AUTHORIZED
Strategy merge: NOT AUTHORIZED
PR-01 implementation: NOT AUTHORIZED
Primary Supabase mutation: NOT AUTHORIZED
Runtime/frontend/Auth change: NOT AUTHORIZED
Security Go: DENIED / NOT AUTHORIZED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0 / NOT AUTHORIZED
```

## 7. Evidence required for every future authority

- source/date and product authority;
- exact repository, base, branch and expected head;
- exact environment/project ref;
- exact files/objects/operations;
- evidence available and missing;
- acceptance criteria;
- prohibited areas;
- test plan;
- rollback/containment;
- residual risk;
- expiration condition;
- lifecycle state.