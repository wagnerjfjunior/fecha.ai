# FECH.AI — F1-02 Security Remediation Master Plan

**Status:** `PROGRAM_BASELINE / DOCUMENTATION_ONLY / SECURITY_GO_DENIED`  
**Date:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Canonical base at program start:** `0555bad889c6ab85970ee242a0e35ac6873508e8`  
**Supabase project:** `Discador-MesaCliente`  
**Project ref:** `uobxxgzshrmbtjfdolxd`  
**Region:** `sa-east-1`  
**Product phase:** `MVP 1 — Família`

## 1. Purpose

This document defines the complete planning, execution, testing, audit, release, rollback and SFJM process for F1-02 — Security Go for the M1 paths actually used by FECH.AI.

It is an execution program, not a Security Go decision. It does not authorize runtime, frontend, Supabase, migration, RLS, policy, grant, RPC, Auth, Vercel or production changes.

## 2. Operating principles

```text
80% planning and strategy
20% execution and tactics

Frontend requests and displays.
Backend / RPC / Supabase validates and decides.
AI assists, but is not authority.

One PR = one primary risk = one simple rollback.
Production is not a laboratory.
No evidence = no approval.
```

Pull requests are traceability and evidence. Opening or merging a PR does not earn product value or automatically satisfy F1-02.

## 3. Program size

```text
Operational windows: 5
Planned PRs: 10
Isolated Supabase security lab: 1
Operational Auth change outside a code PR: 1
Formal gates: 2
Recursive closure PRs: 0
```

A new PR may be added only when new evidence reveals a technically independent risk that cannot safely fit an existing PR. PR count is a ceiling and sequencing device, not a productivity target.

## 4. Scope

### In scope

- Supabase Auth controls used by M1;
- PostgreSQL grants and RLS for used M1 tables;
- `corretores` authority and profile writes;
- `leads`, `lotes` and `funil_movimentacoes` writes;
- list visibility and tenant-safe ACL behavior;
- funnel stage visibility;
- lead import session deduplication;
- feedback payload validation;
- used M1 RPC signatures, bodies and execution grants;
- negative security test design and execution in an isolated environment;
- production preflight, controlled application, smoke and rollback evidence;
- final F1-02 gate decision.

### Out of scope

- MesaCliente, parser, financial engine, proposals or simulations;
- PME;
- ADS, Pixel, CAPI and SEO;
- Make, n8n and external integrations;
- broad `App.jsx` refactoring;
- product redesign;
- data cleanup or migration of real lead/customer records;
- changing real user, company, broker, team or role data;
- Security Go for modules or paths not explicitly tested;
- broad commercial release.

## 5. Initial evidence and findings

The read-only live inspection confirmed the exact project and reviewed live metadata, grants, RLS policies, function definitions, constraints, triggers and security advisors without reading lead/customer rows or performing mutations.

### BLOCKING

#### B1 — self privilege escalation through `corretores`

`authenticated` can update `public.corretores`, and the self-row policy does not restrict columns. Authority-bearing fields include `role`, `is_admin_local`, `is_gestor`, `empresa_id`, `time_id`, `user_id`, `ativo` and `apto_para_receber`. `is_root()` recognizes an active `admin_global` row. The audit trigger records critical changes but explicitly does not enforce denial.

#### B2 — excessive direct CRM writes

`authenticated` has direct write surface on `leads` and `lotes`. The used application flows are intended to be RPC-driven, so direct writes can bypass backend business and tenant checks.

#### B3 — forgeable funnel history

`authenticated` can insert directly into `funil_movimentacoes` without proving that the lead, stage, company and movement correspond to one authorized atomic operation.

#### B4 — list ACL cross-tenant target risk

`gerenciar_visibilidade_lista` validates target type but does not fully prove that every target ID belongs to the list company. The access helper also needs explicit company consistency.

### REQUIRED

- tenant-safe `listar_funil_estagios`;
- company-scoped import session deduplication;
- strict feedback allowlist/enumeration;
- leaked-password protection decision;
- repeatable negative tests;
- tested rollback;
- independent final gate decision.

## 6. Roles and specialists

| Role | Responsibility |
|---|---|
| Wagner | Product authority; authorizes implementation windows, Ready, merge and production changes |
| GPT0 — Documentation Auditor | Reconciles evidence, prevents overclaim, audits documentation and handoff |
| GPT1 — SaaS Architect | Owns architecture, sequencing, dependencies, risk, rollback and specialist coordination |
| GPT3 — Supabase Security | Owns Auth/RLS/policies/grants/RPC/migration review and security test acceptance |
| GPT4 — GitHub/Vercel CI-CD | Validates branch, base, head, diff, checks, mergeability, release and rollback |
| GPT7 — LeadOps/CRM/Discador | Confirms CRM and Discador business flows remain operational |
| GPT2 — UX/UI | Participates only when user-facing password-flow messages or states change |
| GPT5 — SRE/DevSecOps | Participates in production monitoring, rollback, incident and operational evidence |
| Codex | Implements bounded repository tasks only after scope, files, acceptance and rollback are approved |

The executor does not approve its own work.

```text
GPT0 confirms evidence state
→ GPT1 approves architecture and PR boundary
→ GPT3 defines security contract
→ Codex executes bounded changes
→ GPT3 independently audits security
→ GPT7 validates operational behavior
→ GPT4 validates PR/release state
→ Wagner authorizes Ready, merge and production
```

## 7. Environments

### Production

```text
Project ref: uobxxgzshrmbtjfdolxd
Name: Discador-MesaCliente
Region: sa-east-1
Classification: Pilot Production
```

Production must not be used for exploratory or offensive negative testing.

### Isolated security lab

Create one Supabase Branch only after explicit cost confirmation.

```text
Suggested name: f1-02-security-lab
```

Use only synthetic data:

- company A and company B;
- admin global, admin local, manager and broker test actors;
- inactive user and authenticated user without profile;
- synthetic teams, lists, lots, leads and funnel stages;
- valid, forged and mixed-tenant IDs.

Never copy real production data, JWTs, passwords, customer names, phone numbers, e-mails or raw payloads into the lab or evidence.

If the lab cannot be created:

```text
STOP — LAB ENVIRONMENT UNAVAILABLE
```

## 8. PR lifecycle

Every technical PR follows:

```text
PLANNED
→ AUTHORIZED_FOR_IMPLEMENTATION
→ DRAFT
→ IMPLEMENTED
→ STATIC_VALIDATION_PASSED
→ LAB_VALIDATION_PASSED
→ DOMAIN_AUDIT_PASSED
→ READY
→ PREMERGE_VALIDATION_PASSED
→ MERGED
→ PRODUCTION_APPLIED
→ SMOKE_PASSED
→ EVIDENCE_CLOSED
```

A database PR is not operationally complete merely because GitHub shows it merged.

## 9. Windows and PRs

| Window | Objective | Planned items |
|---|---|---|
| J0 | Planning, evidence and lab strategy | PR-00 |
| J1 | Identity and self-escalation | PR-01, PR-02, PR-03 |
| J2 | CRM direct writes and history integrity | PR-04, PR-05 |
| J3 | Tenant-safe ACL and payload integrity | PR-06, PR-07 |
| J4 | Consolidated negative tests and gate | PR-08, operational Auth control, PR-09 |

## 10. PR-00 — program baseline

**Branch:** `docs/f1-02-security-remediation-program`  
**Title:** `docs(security): establish F1-02 remediation program`

Primary risk: live findings and the selected remediation sequence are not yet versioned, so later execution could regress, overclaim or fragment.

Deliverables:

- this master plan;
- sanitized live read-only finding record;
- current SFJM state, blockers, evidence freshness, authorization register and handoff;
- explicit Security Go denial;
- F1-02 state set to active remediation with 0 WDP;
- explicit rule against recursive merge-record PRs.

No runtime, frontend or Supabase change is permitted.

Audit: GPT0 primary; GPT1 architecture; GPT3 security accuracy.  
Rollback: one revert of the documentation-only PR.

## 11. J1 — identity and self-escalation

### PR-01 — narrow password-state RPC

**Branch:** `security/f1-02-password-state-rpc`  
**Title:** `security: add narrow password-state RPC`

Create `marcar_senha_inicial_definida()`:

- requires `auth.uid()`;
- resolves the active broker by authenticated user;
- accepts no broker/company/role IDs;
- updates only `must_change_password`;
- fails closed;
- fixed `search_path`;
- no PII return;
- `EXECUTE` denied to `PUBLIC` and `anon`, allowed only to required roles.

Include a migration and explicit rollback. Do not revoke table update yet.

Tests in lab:

- no session, invalid token, no profile and inactive profile denied;
- valid broker succeeds;
- only `must_change_password` changes;
- grants match contract;
- rollback and reapply pass.

### PR-02 — frontend cutover

**Branch:** `security/f1-02-password-flow-cutover`  
**Title:** `security: route password completion through RPC`

Replace the confirmed direct `PATCH corretores` password-completion path with the narrow RPC. Do not refactor unrelated frontend code.

Tests:

- `npm run build`;
- exact direct patch removed;
- success and fail-closed UI behavior;
- no token or sensitive payload logging;
- Vercel preview;
- controlled production smoke after merge/deploy authorization.

### PR-03 — revoke direct `corretores` update

**Branch:** `security/f1-02-lock-corretores-update`  
**Title:** `security: revoke direct corretor self-update`

- revoke direct `UPDATE` from `authenticated`;
- remove/replace permissive self-update policy;
- preserve controlled RPCs for profile, status, team and password state;
- verify execution grants;
- keep audit trigger as detection, not enforcement;
- include rollback.

Mandatory negative tests:

- broker cannot change role, admin/manager flags, company, team, user ID, active state, receive eligibility or password state directly.

Mandatory positive tests:

- profile RPC works;
- password-state RPC works;
- authorized admin/manager RPCs continue working;
- unauthorized actors remain denied.

### Gate 1

```text
SELF-ESCALATION: BLOCKED
PASSWORD FLOW: FUNCTIONAL
PROFILE/ADMIN RPCS: FUNCTIONAL
ROLLBACK: TESTED
PRODUCTION SMOKE: PASS
```

## 12. J2 — CRM direct writes and funnel history

### PR-04 — restrict direct CRM writes

**Branch:** `security/f1-02-lock-crm-direct-writes`  
**Title:** `security: restrict direct CRM table writes`

Reconfirm current call sites at the PR head, then restrict direct writes on `leads` and `lotes` only where RPC coverage is proven.

Negative tests:

- direct insert/update denied;
- company, broker, list, lot, team and status forgery denied;
- wrong-owner and cross-tenant attempts denied.

Positive tests:

- import, next lead, feedback, funnel movement, messaging, lot allocation/distribution and dashboard paths continue through approved RPCs.

### PR-05 — enforce funnel history integrity

**Branch:** `security/f1-02-protect-funnel-history`  
**Title:** `security: enforce funnel history integrity`

- revoke direct `INSERT` into `funil_movimentacoes`;
- history created only by controlled RPCs;
- derive actor/company/broker/lead/stage server-side;
- ensure lead and stage tenant consistency;
- ensure lead update and movement record are one atomic operation;
- reject mixed-tenant batches and forged IDs.

J2 exit:

```text
DIRECT CRM MUTATION: DENIED
RPC OPERATIONAL FLOW: PASS
FUNNEL HISTORY: CONSISTENT
CROSS-TENANT TESTS: PASS
ROLLBACK: TESTED
```

## 13. J3 — ACL and payload integrity

### PR-06 — tenant-safe list visibility

**Branch:** `security/f1-02-tenant-list-acl`  
**Title:** `security: enforce tenant-safe list visibility`

- restrict direct ACL table DML;
- validate target type, existence and company for every target;
- validate executor role and managed-team boundary;
- prevent manager company-wide or cross-tenant grants;
- harden access helper to derive/verify company server-side;
- use an atomic transaction;
- preserve sanitized auditability.

### PR-07 — tenant-safe reads and payload validation

**Branch:** `security/f1-02-input-and-read-integrity`  
**Title:** `security: harden funnel reads and CRM payloads`

- authenticate and tenant-filter `listar_funil_estagios`;
- scope import session deduplication by company and session;
- validate list ownership;
- reject unknown feedback values before any write;
- avoid partial state changes;
- validate other used channel/sequence payloads if confirmed at the PR head.

J3 exit:

```text
LIST ACL CROSS-TENANT: BLOCKED
FUNNEL STAGE LEAK: BLOCKED
IMPORT SESSION COLLISION: FIXED
INVALID FEEDBACK: REJECTED
ROLLBACK: TESTED
```

## 14. J4 — consolidated testing and gate

### PR-08 — repeatable negative test matrix

**Branch:** `test/f1-02-negative-security-matrix`  
**Title:** `test(security): add F1-02 negative test matrix`

Test categories:

- missing/invalid/expired session;
- no profile and inactive profile;
- self privilege escalation;
- wrong company/tenant;
- forged broker, lead, list, lot and stage IDs;
- mixed-tenant arrays;
- direct table mutations;
- unauthorized visibility targets;
- invalid feedback, channel and sequence payloads;
- rollback and reapply.

Every record must contain test ID, exact commit, project ref, environment, synthetic actor role, expected result, actual result, pass/fail and sanitized error code. Never store credentials, JWTs, PII or production UUIDs.

Acceptance:

```text
BLOCKING TESTS: 100% PASS
REQUIRED TESTS: 100% PASS
UNEXPECTED MUTATIONS: ZERO
CROSS-TENANT SUCCESSES: ZERO
```

### Operational Auth control

Enable leaked-password protection only with explicit production authorization, previous-state capture, synthetic test account, smoke and reversal procedure.

### PR-09 — final F1-02 gate decision

**Branch:** `docs/f1-02-security-go-decision`  
**Title:** `docs(security): record F1-02 gate decision`

Consolidate exact PR heads/squash commits, lab applications, rollback tests, production applications, smoke evidence, negative matrix and residual risks. Record one decision:

```text
SECURITY GO FOR TESTED M1 PATHS: GRANTED
```

or

```text
SECURITY GO FOR TESTED M1 PATHS: DENIED
```

Any grant applies only to the explicitly tested M1 paths, commit and environment. It does not approve MesaCliente, PME, integrations, broader commercialization or the whole FECH.AI attack surface.

The merge of PR-09 is self-closing. Do not create another PR merely to record its squash merge.

## 15. Audit contract

Before Ready, an independent audit must output:

```text
VERDICT: PASS | PASS WITH RESIDUAL RISK | FAIL
PR:
BASE VALIDATED:
HEAD VALIDATED:
CHANGED FILES:
BLOCKING:
REQUIRED IN THIS PR:
ACCEPTABLE WITH RESIDUAL RISK:
PLANNED FUTURE PR:
TEST EVIDENCE:
ROLLBACK:
READY RECOMMENDATION: YES | NO
MERGE AUTHORITY: NOT GRANTED
WRITES PERFORMED BY AUDITOR: NONE
```

Rules:

- audit exact head;
- any head change invalidates the audit;
- executor is not final auditor;
- missing tenant, Auth, grant, RLS or rollback evidence blocks;
- narrated tests do not count;
- production application requires separate authorization.

## 16. Production process

For each migration:

```text
1. PR audited
2. apply in security lab
3. positive and negative tests
4. rollback tested
5. reapply in lab
6. Ready authorization
7. exact-head premerge validation
8. squash merge
9. separate production authorization
10. production preflight
11. apply exact migration
12. verify objects/grants/policies
13. controlled smoke
14. monitor
15. sanitized evidence closure
```

Stop and rollback on login regression, unauthorized success, cross-tenant behavior, unexpected mutation, RPC-wide failure, material import/funnel regression or live object drift.

## 17. SFJM process

Mandatory SFJM updates:

- PR-00 records the read-only findings, active remediation program, blockers and next action;
- PR-09 records the final gate, residual risk and handoff.

An intermediate SFJM update is justified only by a material new blocker, architecture change, sequence change, incident, rollback, program suspension, gate change or evidence invalidation.

Do not open an SFJM PR after every merge.

Authorization types:

- `WINDOW_IMPLEMENTATION`: bounded branch/commit/Draft PR execution;
- `PR_LIFECYCLE`: conditional Ready and exact-head squash merge;
- `PRODUCTION_CHANGE`: exact Supabase/Vercel/Auth production operation and rollback.

## 18. Junior analyst execution checklist

Before every PR:

1. read bootstrap, governance and SFJM indexes;
2. confirm live `main`;
3. confirm predecessor and active window;
4. confirm authorization, files, prohibitions and rollback;
5. create exact branch from exact base;
6. issue a bounded Codex task envelope;
7. inspect changed files and diff;
8. run `git diff --check` and relevant build/tests;
9. confirm no secret or PII;
10. open Draft PR;
11. apply only in lab when database-related;
12. run positive, unauthenticated, unauthorized, cross-tenant, invalid-payload and rollback tests;
13. request GPT3/GPT7/GPT1/GPT4 audits as applicable;
14. re-audit after any head change;
15. obtain Ready authority;
16. premerge validate exact head;
17. obtain merge authority;
18. squash merge with expected-head protection;
19. obtain separate production authority;
20. preflight, apply, smoke, monitor and close evidence.

## 19. Final acceptance

F1-02 can be accepted only when:

- self-escalation is blocked;
- direct unauthorized CRM and history writes are blocked;
- list ACL and stage visibility are tenant-safe;
- import and feedback contracts are hardened;
- all used RPCs validate session and server-side authority;
- grants, RLS and policies are current and documented;
- negative tests and rollback pass;
- production smoke passes;
- no BLOCKING finding remains;
- GPT3 recommends the gate;
- GPT1 agrees with architecture impact;
- GPT0 confirms evidence and no overclaim;
- Wagner records the final decision.

## 20. Checkpoint candidates

```text
CP1: AS-IS, plan and lab strategy accepted — candidate 25%
CP2: self-escalation blocked and password flow preserved — candidate 50%
CP3: CRM/history/ACL/payload remediation accepted — candidate 75%
CP4: final tests, production evidence and gate accepted — candidate 100%
```

No checkpoint or WDP is earned by this plan alone.

## 21. Immediate next safe action

Audit this PR-00 documentation baseline at its exact final head. After it passes and is merged, request cost confirmation for the single isolated Supabase Branch. Do not begin PR-01 or any Supabase mutation before the plan and lab strategy are accepted.
