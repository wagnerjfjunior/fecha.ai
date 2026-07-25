# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FAIL_CLOSED`  
**Observed on:** 2026-07-24

## 1. Interpretation rule

An authorization is valid only within its declared repository, target, environment, files/areas, acceptance criteria, prohibitions and expiration condition.

General phrases must be interpreted with the immediately preceding approved plan and next safe action. They never silently authorize runtime, Supabase, production, Ready or merge outside that exact context.

When material scope remains ambiguous, stop fail-closed.

## 2. Historical consumed authorities

### PR #95 — SFJM documentation v1

```text
State: CONSUMED
Head: 611faa5d7275d8f40386c41b2687fb5ef6f7b5b6
Squash: 4293f383e1e93f0cfd4a63f793024eb239bfafbb
```

### PR #96 — post-PR #95 reconciliation

```text
State: CONSUMED
Head: 91d27a4aa676f3e174ab000ca23992b69fc90a90
Squash: 4668cc1dde4b990791583c85f5b36a5d4b55d6a8
```

### PR #94 — F1-01 evidence map correction, audit and merge

```text
State: CONSUMED
Final head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
Squash: 1caf90c60681771af6609b96ee840b190668fa0f
```

This authority did not accept F1-01, grant Security Go or award WDP.

### PR #98 — post-PR #94 reconciliation

```text
State: CONSUMED
Branch: agent/reconcile-f1-01-post-pr94
Final head: e7e52ed9762ab92fd14f82e2437845421693ec81
Squash: 8a2eb00a9dcd46d7ee346741ca27c6081af52124
Audit: PASS WITH RESIDUAL RISK
```

### PR #99 — post-PR #98 reconciliation

```text
State: CONSUMED
Branch: docs/reconcile-post-pr98
Final head: 754e35406971e72ce29763bf145060868914b4d7
Squash: 573ecebbafc2fb0ea4a065905e0f592b9db2a308
Audit: PASS WITH RESIDUAL RISK
Threads: 2 RESOLVED / 0 OPEN
```

### PR #100 — close PR #99 cycle and prevent recursive reconciliation

```text
State: CONSUMED
Branch: docs/close-pr99-reconciliation-loop
Final head: defeda035c5e7f709e31707a84c9edd488c99799
Squash: 0555bad889c6ab85970ee242a0e35ac6873508e8
PR state: CLOSED / MERGED
```

PR #100 established that a bounded documentation-only closure merge does not require another PR solely to record its own squash commit.

## 3. Consumed F1-02 read-only authority

**Lifecycle state:** `CONSUMED`  
**Source/date:** explicit user authorization and project identification, 2026-07-24  
**Repository commit:** `0555bad889c6ab85970ee242a0e35ac6873508e8`  
**Supabase project:** `uobxxgzshrmbtjfdolxd` (`Discador-MesaCliente`)  
**Environment:** live project, read-only metadata/definition inspection

Authorized actions executed:

- identify and confirm exact project provenance;
- read metadata, RLS/force-RLS state, policies and grants;
- read relevant function/RPC signatures and bodies;
- read constraints, triggers and security advisors;
- correlate current GitHub source paths;
- design but not execute negative tests;
- produce sanitized findings and a remediation recommendation.

Execution result:

```text
Read-only inspection: COMPLETED
Mutations: ZERO
Lead/customer row reads: ZERO
Negative production tests: ZERO
Security Go: DENIED
```

The read-only authority is consumed. It does not authorize further Supabase reads, writes, lab creation, migrations, negative tests or production actions.

## 4. PR-00 Draft-creation authority

**Lifecycle state:** `CONSUMED AT DRAFT CREATION`  
**Source/date:** Wagner approved the detailed F1-02 master plan and instructed the project to begin, 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `0555bad889c6ab85970ee242a0e35ac6873508e8`  
**Branch:** `docs/f1-02-security-remediation-program`  
**Environment:** GitHub documentation only

### Files authorized

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/handoffs/CURRENT.md
```

### Authorized actions

- create the exact branch from the exact base;
- create/update only the eight listed documentation files;
- version the complete remediation master plan;
- version the sanitized live read-only findings;
- reconcile material SFJM state, blockers, evidence, authority and handoff;
- create one Draft PR titled `docs(security): establish F1-02 remediation program`.

### Acceptance constraints

- documentation only;
- no PII, credentials, JWTs, real passwords, customer payloads or raw production UUIDs;
- Security Go remains denied;
- F1-01 remains unaccepted;
- F1-02 remains blocked pending remediation;
- WDP remains 0;
- no product/runtime claim;
- no Supabase lab or production authority;
- no recursive merge-record PR.

### Prohibited

- files outside the exact list;
- additional commits after Draft creation without a new bounded correction authority;
- Ready or merge;
- Supabase Branch creation or cost confirmation;
- runtime or frontend changes;
- migrations, RLS, grants, policies, functions/RPCs or Auth changes;
- negative tests;
- Edge Functions, Vercel, GitHub Actions or production;
- Security Go, F1-01/F1-02 acceptance or WDP.

Rollback is one revert of the documentation-only PR if later merged.

## 5. Planned future authorization types

### `WINDOW_IMPLEMENTATION`

May authorize exact branches, files, commits and Draft PRs for one approved operational window. Does not authorize Ready, merge or production.

### `PR_LIFECYCLE`

May conditionally authorize Ready and exact-head squash merge after audit and premerge gates. Does not authorize production application.

### `PRODUCTION_CHANGE`

May authorize one exact Supabase/Vercel/Auth production operation with project, migration/config identity, preflight, smoke, monitoring and rollback.

### `LAB_CREATE`

Required before creating `f1-02-security-lab`. Must include exact project, cost confirmation, synthetic-data-only restriction, permitted operations and destruction/containment condition.

## 6. Current authority state after PR-00 Draft creation

```text
PR-00 Draft creation authority: CONSUMED
No authority for additional commits
No authority for Ready
No authority for merge
No authority for Supabase lab creation
No authority for PR-01 implementation
No authority for runtime/frontend/Supabase/Auth/production
No authority for Security Go or WDP
```

## 7. Evidence required for future authorities

Every future authorization must identify:

- source/date;
- repository, base, branch and expected head when applicable;
- exact environment/project;
- exact files/objects/operations;
- prohibited areas;
- acceptance criteria;
- test and audit requirements;
- rollback/containment;
- cost confirmation when applicable;
- expiration condition;
- lifecycle state.
