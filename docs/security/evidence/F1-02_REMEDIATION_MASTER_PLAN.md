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
- `leads`, `lotes`, `times` and `funil_movimentacoes` write surfaces;
- list visibility and tenant-safe ACL behavior;
- funnel stage visibility;
- lead import session deduplication and concurrency;
- feedback payload validation and transactionality;
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
- company-scoped import session deduplication with concurrency-safe idempotency;
- strict feedback allowlist/enumeration before the first write;
- current disposition of the `times` write surface;
- leaked-password protection decision;
- repeatable positive and negative tests;
- tested rollback and reapply per migration;
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

Production must not be used for exploratory, destructive or offensive negative testing.

### Isolated security lab

Create one Supabase Branch only after explicit cost confirmation.

```text
Suggested name: f1-02-security-lab
```

Use only synthetic, versioned fixtures:

- company A and company B;
- admin-global synthetic actor;
- admin-local actor for company A;
- manager actor for company A;
- broker A bound to company A and team A;
- broker B bound to company B and team B;
- inactive actor;
- authenticated actor without a broker/profile row;
- synthetic teams A and B;
- synthetic lists A and B;
- synthetic lots A and B;
- synthetic leads A and B;
- global funnel stages and company-specific stages A and B;
- valid, nonexistent, forged and mixed-tenant IDs.

The lab contract must include:

1. a versioned fixture manifest with synthetic identifiers and expected relationships;
2. a deterministic seed procedure;
3. a deterministic reset procedure;
4. one reset before each migration test cycle;
5. rollback and reapply execution for each migration;
6. sanitized evidence capture;
7. confirmation that no production dump, production JWT, production password or production secret is reused;
8. an owner role and deadline for branch destruction or deactivation after F1-02 closure;
9. proof that branch/project isolation matches the intended environment before tests start.

Never copy real production data, JWTs, passwords, customer names, phone numbers, e-mails or raw payloads into the lab or evidence.

If the lab cannot be created or reliably reset:

```text
STOP — LAB ENVIRONMENT UNAVAILABLE
```

Production is not an alternative laboratory.

## 8. Mandatory security inventories before implementation

The following inventories are mandatory deliverables. They are not optional narrative notes.

### 8.1 Table/RLS/grant matrix

The current live state must be revalidated at the exact implementation head for:

```text
public.corretores
public.leads
public.lotes
public.funil_movimentacoes
public.lista_visibilidade
public.listas
public.times
public.funil_estagios
```

For each table and each operation, the audit artifact must record:

| Required field | Required content |
|---|---|
| Table | Fully qualified identity |
| RLS | enabled/disabled |
| FORCE RLS | enabled/disabled/not applicable with rationale |
| Operation | SELECT / INSERT / UPDATE / DELETE |
| `anon` grant | current and target state |
| `authenticated` grant | current and target state |
| `service_role` grant | current and target state |
| Other role grants | owner, custom roles and bypass roles |
| Policy | exact policy identity |
| `USING` | exact predicate or `NONE` |
| `WITH CHECK` | exact predicate or `NONE` |
| Helpers | functions invoked by policy |
| Tenant derivation | server-side source of company/tenant |
| Actor derivation | server-side source of user/broker/role |
| Payload authority | fields that must never be trusted from frontend |
| Call-site dependency | exact UI/service/job/integration dependency |
| Target disposition | retain, restrict, revoke or replace |
| Tests | positive and negative test IDs |
| Rollback impact | security state restored by rollback |

The matrix must not infer `UPDATE` safety from a `USING` predicate alone. It must inspect column authority, `WITH CHECK`, table grants and all direct call sites.

### 8.2 Mandatory disposition for `times`

Historical evidence identified `times` as part of an authenticated write surface. Before any Security Go decision, the current live state must be revalidated and one explicit disposition recorded:

```text
NO DIRECT WRITE PRESENT
or
DIRECT WRITE REQUIRED AND SAFELY CONSTRAINED
or
DIRECT WRITE REVOKED AND REPLACED BY CONTROLLED RPC
```

No historical finding may be treated as current without refresh. No `times` risk may be silently omitted.

### 8.3 RPC contract inventory

The following used M1 RPCs require an individual contract card:

```text
atualizar_perfil_corretor
atualizar_status_corretor
atualizar_time_corretor
proximo_lead
registrar_feedback
atualizar_feedback
mover_funil
mover_funil_lote
registrar_mensagem
criar_lista
gerenciar_visibilidade_lista
importar_leads_batch
distribuir_lotes
get_dashboard_stats
minha_producao
listar_funil_estagios
```

Each card must record:

| Required field | Required content |
|---|---|
| Function identity | schema, name and full signature |
| Owner | exact database role |
| Language | SQL, PL/pgSQL or other |
| Execution mode | SECURITY INVOKER or SECURITY DEFINER |
| Definer rationale | required only when definer is used |
| `search_path` | fixed and non-user-controlled |
| Dynamic SQL | absent, or bounded and justified |
| `EXECUTE PUBLIC` | granted/revoked |
| `EXECUTE anon` | granted/revoked |
| `EXECUTE authenticated` | granted/revoked |
| `EXECUTE service_role` | granted/revoked |
| Authentication | `auth.uid()` handling |
| Actor state | profile existence, uniqueness and active-state checks |
| Tenant derivation | company derived server-side |
| Authorization | role, team and ownership checks |
| Payload contract | allowlisted arguments and rejected fields |
| Tables touched | reads and writes |
| Side effects | triggers, logs, history and dependent writes |
| Transaction behavior | atomicity and failure behavior |
| Return contract | exact shape without sensitive fields |
| Positive tests | exact test IDs |
| Negative tests | exact test IDs |
| Rollback dependency | function/grant state restored |

`SECURITY DEFINER` is not automatically a vulnerability, but it is never accepted without a fixed `search_path`, minimal grants, server-side identity/tenant checks and a documented owner.

Any write RPC confirmed executable by `anon` is `BLOCKING` unless a separately approved public-use contract proves that the behavior is intentional and safe.

## 9. PR lifecycle

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

## 10. Windows and PRs

| Window | Objective | Planned items |
|---|---|---|
| J0 | Planning, evidence and lab strategy | PR-00 |
| J1 | Identity and self-escalation | PR-01, PR-02, PR-03 |
| J2 | CRM direct writes and history integrity | PR-04, PR-05 |
| J3 | Tenant-safe ACL and payload integrity | PR-06, PR-07 |
| J4 | Consolidated negative tests and gate | PR-08, operational Auth control, PR-09 |

## 11. PR-00 — program baseline

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

## 12. J1 — identity and self-escalation

### 12.1 Mandatory compatibility sequence

The operational sequence is mandatory and cannot be compressed:

```text
1. Implement PR-01.
2. Apply PR-01 migration in the isolated lab.
3. Pass positive, negative, rollback and reapply tests in the lab.
4. Complete GPT3/GPT1/GPT4 audits at the exact PR-01 head.
5. Merge PR-01 after separate lifecycle authorization.
6. Apply the exact PR-01 migration/RPC to production after separate PRODUCTION_CHANGE authorization.
7. Verify production function signature, owner, execution mode, search_path and grants.
8. Execute a controlled positive production smoke with a synthetic authorized actor.
9. Keep the legacy direct UPDATE temporarily available during the compatibility window.
10. Implement and merge PR-02 frontend cutover.
11. Deploy PR-02 and prove the new frontend uses the RPC.
12. Re-scan all repository call sites and confirm no required direct password-state PATCH remains.
13. Observe the cutover long enough to confirm no legitimate flow depends on direct UPDATE.
14. Only then implement PR-03.
15. Apply PR-03 revoke migration after separate production authorization.
16. Verify direct UPDATE denial and controlled RPC continuity.
```

The following incompatible states are prohibited:

```text
frontend new + RPC absent
frontend old + direct UPDATE revoked
```

### PR-01 — narrow password-state RPC

**Branch:** `security/f1-02-password-state-rpc`  
**Title:** `security: add narrow password-state RPC`

Create `marcar_senha_inicial_definida()` with this deterministic contract:

- requires a valid `auth.uid()`;
- resolves exactly one active broker/profile by authenticated user;
- fails if the profile is absent, inactive, duplicated or ambiguous;
- accepts no broker, company, team, role or user identifiers;
- updates only `must_change_password`;
- is idempotent when the target state is already satisfied;
- returns a minimal documented result shape;
- uses `SECURITY INVOKER` unless a documented privilege requirement proves `SECURITY DEFINER` is necessary;
- if definer is used, has a safe owner, fixed `search_path` and fully qualified object references;
- contains no unbounded dynamic SQL;
- has no undocumented trigger or side effect;
- revokes `EXECUTE` from `PUBLIC` and `anon`;
- grants `EXECUTE` explicitly to `authenticated` only, plus `service_role` only when operationally required and documented;
- returns no PII or authority-bearing profile fields;
- fails closed before any write.

Include one migration and its exact rollback. Do not revoke table update yet.

Tests in lab:

- no session denied;
- invalid token denied;
- expired token denied;
- no profile denied;
- inactive profile denied;
- duplicate/ambiguous profile denied;
- valid broker succeeds;
- repeated valid call remains idempotent;
- only `must_change_password` changes;
- no unrelated trigger or column change occurs;
- grants match the contract;
- rollback passes;
- reapply passes.

### PR-02 — frontend cutover

**Branch:** `security/f1-02-password-flow-cutover`  
**Title:** `security: route password completion through RPC`

Replace the confirmed direct `PATCH corretores` password-completion path with the narrow RPC. Do not refactor unrelated frontend code.

Precondition:

```text
PR-01 RPC is already applied and verified in production.
```

Tests:

- `npm run build`;
- exact direct patch removed from the intended path;
- repository-wide call-site search performed at the exact head;
- success UI behavior;
- fail-closed UI behavior;
- RPC unavailable does not produce false success;
- no token or sensitive payload logging;
- Vercel preview;
- controlled production smoke after merge/deploy authorization;
- evidence confirms the new deployed frontend uses the RPC.

### PR-03 — revoke direct `corretores` update

**Branch:** `security/f1-02-lock-corretores-update`  
**Title:** `security: revoke direct corretor self-update`

Preconditions:

- PR-01 production RPC verified;
- PR-02 deployed and smoke passed;
- repository-wide search confirms no required direct update remains;
- controlled RPCs are individually inventoried and tested.

Required work:

- revoke direct `UPDATE` from `authenticated`;
- remove or replace the permissive self-update policy;
- inspect SELECT, INSERT, UPDATE and DELETE grants/policies for `corretores`;
- revalidate `atualizar_perfil_corretor`;
- revalidate `atualizar_status_corretor`;
- revalidate `atualizar_time_corretor`;
- revalidate `marcar_senha_inicial_definida`;
- review `is_root()` and every function relying on authority-bearing broker fields;
- preserve only controlled profile, status, team and password-state paths;
- verify function owners, definer/invoker mode, fixed `search_path` and execution grants;
- keep the audit trigger as detection, not enforcement;
- include exact rollback and containment.

Mandatory negative tests:

- broker cannot change role;
- broker cannot set admin-local flag;
- broker cannot set manager flag;
- broker cannot change company;
- broker cannot change team;
- broker cannot change user ID;
- broker cannot change active state;
- broker cannot change receive eligibility;
- broker cannot change password state directly;
- `anon` cannot update;
- authenticated user without profile cannot update.

Mandatory positive tests:

- profile RPC works;
- password-state RPC works;
- status RPC works for authorized actor;
- team RPC works for authorized actor;
- unauthorized actors remain denied;
- root behavior remains restricted to the approved server-side contract.

Rollback containment:

If rollback restores the vulnerable direct update grant or policy:

```text
SECURITY GO: DENIED
PILOT: CONTAINED
INCIDENT/ROLLBACK EVIDENCE: REQUIRED
```

### Gate 1

```text
SELF-ESCALATION: BLOCKED
PASSWORD FLOW: FUNCTIONAL
PROFILE/ADMIN RPCS: FUNCTIONAL
RLS/GRANT MATRIX: COMPLETE
RPC CONTRACT CARDS: COMPLETE
ROLLBACK AND REAPPLY: TESTED
PRODUCTION SMOKE: PASS
```

## 13. J2 — CRM direct writes and funnel history

### PR-04 — restrict direct CRM writes

**Branch:** `security/f1-02-lock-crm-direct-writes`  
**Title:** `security: restrict direct CRM table writes`

Before any revoke, create a versioned operation/call-site map covering:

- frontend components;
- frontend services;
- API routes;
- Edge Functions, if any are confirmed in scope;
- scheduled jobs;
- repository scripts;
- external integration call sites referenced by the code, without altering those integrations;
- each direct table operation and its replacement RPC.

The required mapping must distinguish:

```text
leads.INSERT
leads.UPDATE
leads.DELETE
lotes.INSERT
lotes.UPDATE
lotes.DELETE
times.INSERT
times.UPDATE
times.DELETE
```

For every operation record:

- exact call site;
- whether it is used by M1;
- payload fields;
- tenant/actor source;
- approved RPC replacement;
- migration dependency;
- positive test IDs;
- negative test IDs;
- rollback impact.

Restrict direct writes only where RPC coverage is proven. Do not revoke blindly.

Negative tests:

- direct insert/update/delete denied as applicable;
- company forgery denied;
- broker forgery denied;
- list forgery denied;
- lot forgery denied;
- team forgery denied;
- stage/funnel forgery denied;
- status forgery denied;
- wrong-owner attempts denied;
- cross-tenant attempts denied;
- mixed-tenant payload denied atomically.

Positive tests:

- import;
- next lead;
- feedback;
- funnel movement;
- messaging;
- lot allocation/distribution;
- approved team-management path;
- dashboard reads;
- all used flows continue through approved RPCs.

Rollback must identify exactly which direct grants are restored and whether restoring them reopens a blocker.

### PR-05 — enforce funnel history integrity

**Branch:** `security/f1-02-protect-funnel-history`  
**Title:** `security: enforce funnel history integrity`

Required work:

- inspect SELECT, INSERT, UPDATE and DELETE grants/policies for `funil_movimentacoes`;
- revoke direct `INSERT` from untrusted application roles;
- revoke or constrain direct UPDATE/DELETE when present;
- create history only through controlled RPCs;
- derive actor, company, broker, lead, stage and previous stage server-side;
- require an active stage;
- require stage membership in the approved global/company funnel semantics;
- validate transition rules when the product contract defines them;
- ensure lead update and movement record are one atomic operation;
- reject the complete batch if one ID is invalid or cross-tenant;
- prevent history without corresponding state change;
- prevent state change without corresponding history;
- define concurrency behavior for simultaneous movements;
- include exact rollback and reapply.

Mandatory tests:

- direct insert denied;
- direct update denied or safely constrained;
- direct delete denied or safely constrained;
- forged company denied;
- forged broker denied;
- forged lead denied;
- forged stage denied;
- inactive stage denied;
- invalid transition denied when transition rules exist;
- mixed-tenant batch rolls back completely;
- history-only mutation impossible;
- state-only mutation impossible;
- concurrent movement produces one deterministic accepted result or a controlled conflict;
- authorized individual movement succeeds;
- authorized batch movement succeeds;
- rollback passes;
- reapply passes.

J2 exit:

```text
DIRECT CRM MUTATION: DENIED OR EXPLICITLY CONSTRAINED
TIMES DISPOSITION: RECORDED
RPC OPERATIONAL FLOW: PASS
FUNNEL HISTORY: CONSISTENT
CROSS-TENANT TESTS: PASS
ROLLBACK AND REAPPLY: TESTED
```

## 14. J3 — ACL and payload integrity

### PR-06 — tenant-safe list visibility

**Branch:** `security/f1-02-tenant-list-acl`  
**Title:** `security: enforce tenant-safe list visibility`

The authorization matrix must be finalized with GPT1, GPT3 and GPT7 before implementation. The conservative baseline is:

| Actor | Broker target | Team target | Company target |
|---|---|---|---|
| Broker | denied | denied | denied |
| Manager | only brokers within managed scope | only managed teams | denied |
| Admin local | only same-company brokers | only same-company teams | own company only, and only if product explicitly approves company scope |
| Root/admin global | explicit global rule only; never implicit | explicit global rule only; never implicit | explicit global rule only; never implicit |

Universal rules:

- no target may belong to another tenant unless an explicitly approved root-only global rule requires it;
- company supplied by frontend is never authority;
- target type and target ID must be mutually consistent;
- target must exist and be active when the contract requires active state;
- manager scope must be derived server-side;
- admin-local scope must be derived server-side;
- direct DML on `lista_visibilidade` is revoked or narrowly constrained;
- `gerenciar_visibilidade_lista` has `PUBLIC` and `anon` execution revoked;
- `corretor_tem_acesso_lista` is `INTERNAL ONLY`;
- revoke `EXECUTE` on `corretor_tem_acesso_lista` from `PUBLIC`, `anon` and `authenticated`;
- no frontend, browser client, public API route or untrusted application role may invoke `corretor_tem_acesso_lista` directly;
- the helper may be invoked only from an approved backend/RPC path whose contract card documents owner, execution mode, fixed `search_path`, server-side actor/company derivation and sanitized result handling;
- any future need for external execution is a scope change: stop, create a dedicated contract card, obtain GPT1/GPT3/GPT7 approval and add explicit grants/tests before granting access;
- owner, definer/invoker mode and fixed `search_path` are documented;
- incompatible target rows are prevented by constraints or equivalent transaction checks;
- the complete ACL update is atomic;
- audit evidence is sanitized.

Mandatory tests:

- broker cannot manage ACL;
- manager can grant only inside managed scope;
- manager cannot grant company-wide access;
- manager cannot target another company;
- admin local cannot target another company;
- root behavior follows the explicit approved rule;
- nonexistent target denied;
- invalid target type denied;
- type/ID mismatch denied;
- direct ACL DML denied;
- direct execution of `corretor_tem_acesso_lista` by `PUBLIC`, `anon` and `authenticated` is denied;
- approved controlled backend/RPC path can use the internal helper successfully for an authorized same-company case;
- the controlled backend/RPC path using the helper denies cross-tenant access;
- cross-tenant target denied;
- authorized same-company operation succeeds;
- removal succeeds only for authorized actor;
- rollback and reapply pass.

### PR-07 — tenant-safe reads and payload validation

**Branch:** `security/f1-02-input-and-read-integrity`  
**Title:** `security: harden funnel reads and CRM payloads`

#### `listar_funil_estagios`

Before implementation, choose and document one unambiguous global-stage semantic:

```text
OPTION A: empresa_id IS NULL means global
or
OPTION B: explicit scope/is_global field with supporting constraints
```

The selected rule must be backed by constraints and tests. The RPC must:

- require authentication;
- resolve an active actor/profile;
- derive company server-side;
- accept no authoritative company parameter;
- return only approved global stages plus stages belonging to the actor company;
- exclude other-company stages;
- exclude inactive stages when the product contract requires active only;
- use deterministic ordering;
- return a documented minimal shape.

#### `importar_leads_batch`

The contract must:

- derive `empresa_id` server-side;
- scope idempotency by `(empresa_id, sessao_id)`;
- validate that the list exists and belongs to the same company;
- allowlist payload fields and enforce size limits;
- reject mixed-tenant payloads atomically;
- ensure same session in the same company does not duplicate;
- ensure the same session value in different companies does not collide;
- protect concurrent identical submissions with a unique constraint, advisory lock, idempotency table or equivalent transaction-safe mechanism;
- produce a deterministic result for replay;
- write only sanitized audit data;
- avoid partial import on validation failure unless an explicitly approved per-row contract says otherwise.

#### `registrar_feedback`

The contract must:

- validate feedback against an explicit allowlist or enum before the first write;
- reject empty, unknown or malformed feedback;
- validate lead existence, company and ownership;
- derive actor and company server-side;
- define the exact effect on commercial status;
- define the exact effect on funnel stage;
- validate channel and sequence values when those fields are in the used path;
- apply all effects in one transaction;
- leave zero partial mutations on error;
- return a documented minimal result.

Mandatory PR-07 tests:

- no session denied;
- no profile denied;
- inactive profile denied;
- global stage returned according to selected semantics;
- own-company stage returned;
- other-company stage excluded;
- deterministic stage ordering confirmed;
- same company + same session is idempotent;
- different companies + same session do not collide;
- concurrent same-company submission produces one deterministic import result;
- cross-tenant list denied;
- mixed-tenant batch denied atomically;
- feedback empty denied;
- feedback unknown denied;
- valid feedback succeeds;
- invalid channel/sequence denied when applicable;
- no partial status/funnel/history change on failure;
- rollback and reapply pass.

J3 exit:

```text
LIST ACL CROSS-TENANT: BLOCKED
FUNNEL STAGE LEAK: BLOCKED
GLOBAL STAGE SEMANTICS: DOCUMENTED AND TESTED
IMPORT SESSION COLLISION: FIXED
IMPORT CONCURRENCY: TESTED
INVALID FEEDBACK: REJECTED BEFORE WRITE
ROLLBACK AND REAPPLY: TESTED
```

### J3 Product Authority bounded-residual closure exception — 2026-09-02

This section records an explicit Product Authority governance exception. It does
not rewrite the canonical J3 exit criteria above and must not be read as proof
that those original criteria were fully satisfied.

Canonical anchor at the decision:

```text
repository: wagnerjfjunior/fecha.ai
exact main: 1449bee4b708a9211a099c52ff573cf52d44ef1c
this master-plan blob before reconciliation:
  ea161050c535b848ff927133830984f543c1104d

PR #163:
  CLOSED / MERGED
  merge commit: 1449bee4b708a9211a099c52ff573cf52d44ef1c

Supabase project:
  uobxxgzshrmbtjfdolxd / Discador-MesaCliente

PR-07 migration:
  APPLIED
  migration ledger version: 20260902225240
  name: f1_02_pr07_funnel_reads_crm_payloads
```

Evidence state accepted by Product Authority:

```text
evidence reference:
  docs/sfjm/EVIDENCE_FRESHNESS.md
  current J3/PR-07 operating-session runtime evidence override

evidence class:
  OPERATING_SESSION_RUNTIME_EVIDENCE

raw per-case execution receipt:
  NOT_VERSIONED

canonical executable PR-08 receipt:
  NOT_ESTABLISHED

source runtime plan / proof file:
  supabase/tests/f1-02-pr07/funnel_reads_crm_payloads.sql
  blob 55bef23b5a7103e9935ca6eb63a066d3db23dc6e
  remains versioned with runtime cases marked NOT_EXECUTED and is not
  retroactively relabeled as the runtime receipt.

operating-session reported PASS cases:
  STG-001..007
  IMP-001
  IMP-002
  IMP-004..012
  IMP-SESSION-LIST-MISMATCH
  IMP-SESSION-PAYLOAD-MISMATCH
  IMP-CLAIMANT-ROLLBACK
  IMP-INCOMPLETE-STATE
  FDB-001..011

bounded catalog/runtime summaries:
  post-application catalog: OPERATING_SESSION_REPORTED_PASS
  runtime-negative cases above: OPERATING_SESSION_REPORTED_PASS
  sequential idempotency/replay: OPERATING_SESSION_REPORTED_PASS
  claimant rollback: OPERATING_SESSION_REPORTED_PASS
  cross-tenant runtime negatives: OPERATING_SESSION_REPORTED_PASS
  feedback runtime: OPERATING_SESSION_REPORTED_PASS

true-concurrency infrastructure capability:
  PROVEN
  evidence type: operating-session capability probe
  raw probe receipt: NOT_VERSIONED

IMP-003 true-concurrency business-RPC runtime:
  NOT_DETERMINED
  reason: concurrent PostgreSQL sessions were proven, but the concurrent
  business-RPC submission was blocked by the OpenAI tool safety layer before
  SQL reached PostgreSQL.

migration rollback/reapply / ROL-PR07:
  NOT_DETERMINED
  reason: Product Authority decisions prohibit LAB, second Supabase project,
  Preview Branch and production migration rollback testing.

control failure observed:
  NO
```

These operating-session results are accepted only as bounded continuity
evidence. They do not convert the versioned proof file into an executed
artifact, do not satisfy PR-08's future executable-receipt requirement and do
not allow an unversioned raw receipt to be inferred where none exists.

Product Authority decision:

```text
CANONICAL_J3_EXIT_SATISFIED = NO
J3_GOVERNANCE_CLOSURE_BY_PRODUCT_AUTHORITY_EXCEPTION = YES

J3 = CLOSED WITH BOUNDED RESIDUAL EVIDENCE
      — PRODUCT AUTHORITY EXCEPTION

IMP_003_RUNTIME_STATUS = NOT_DETERMINED
ROLLBACK_REAPPLY_STATUS = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
```

This exception:

- does not declare IMP-003 PASS;
- does not declare rollback/reapply PASS;
- does not change either obligation to PROVEN;
- does not establish satisfaction of the original canonical J3 exit contract;
- does not authorize LAB, a second Supabase project, Preview Branch or
  production migration rollback testing;
- does not authorize deploy, new Supabase mutation, Auth changes, broad paid
  commercialization or Security Go;
- preserves both proof obligations as residual evidence items requiring retest
  if a future executable and explicitly authorized path becomes available.

The next phase is J4 / PR-08. Entry into J4 requires its own bounded scope and
authorization gate; this J3 exception does not authorize PR-08 implementation.

## 15. J4 — consolidated testing and gate

### PR-08 — repeatable executable test matrix

**Branch:** `test/f1-02-negative-security-matrix`  
**Title:** `test(security): add F1-02 negative test matrix`

PR-08 must produce executable tests, not only category prose.

Each test record must contain:

```text
test_id
requirement_id
exact application commit
exact migration commit(s)
Supabase project ref
environment
fixture version
synthetic actor
actor role
actor company/team
preconditions
action/request
sanitized payload description
expected authorization result
expected data mutation
actual authorization result
actual data mutation
sanitized error code
pass/fail
timestamp
evidence reference
```

Minimum catalog:

| Test ID | Required coverage |
|---|---|
| AUTH-001..005 | no session, invalid token, expired token, no profile, inactive profile |
| COR-001..009 | role, admin-local, manager, company, team, user ID, active, receive eligibility, direct password-state mutation |
| COR-010..013 | positive profile, password-state, status and team RPCs |
| CRM-001 | direct `leads.INSERT` denied |
| CRM-002 | direct `leads.UPDATE` denied |
| CRM-003 | direct `leads.DELETE` denied |
| CRM-004 | forged `empresa_id` denied |
| CRM-005 | forged `corretor_id` denied |
| CRM-006 | forged `lista_id` denied |
| CRM-007 | forged `lote_id` denied |
| CRM-008 | forged `time_id` denied |
| CRM-009 | forged stage/funnel value denied |
| CRM-010 | forged status denied |
| CRM-011 | wrong-owner lead access/mutation denied |
| CRM-012 | cross-tenant lead access/mutation denied |
| CRM-013 | cross-tenant lot access/mutation denied |
| CRM-014 | mixed-tenant batch rejected atomically |
| CRM-015 | approved positive CRM flow succeeds through controlled RPCs |
| FUN-001..008 | direct history DML, forged stage, inactive stage, invalid transition, history/state consistency, concurrent movement |
| ACL-001..010 | broker denied, manager scope, admin-local scope, root explicit rule, nonexistent target, invalid type, mismatch, direct DML, cross-tenant target, positive same-company operation |
| STG-001..004 | global stage, own-company stage, other-company exclusion, deterministic ordering |
| IMP-001..006 | same-company replay, different-company same session, concurrent replay, cross-tenant list, mixed tenant, positive import |
| FDB-001..006 | empty, unknown, malformed, invalid channel/sequence, atomic failure, positive feedback |
| ROL-001..N | rollback and reapply for every migration |
| PRD-001..N | production metadata verification and separately authorized safe smoke |

The executable suite must prove:

```text
BLOCKING TESTS: 100% PASS
REQUIRED TESTS: 100% PASS
UNEXPECTED MUTATIONS: ZERO
CROSS-TENANT SUCCESSES: ZERO
ROLLBACK TESTS: 100% PASS
REAPPLY TESTS: 100% PASS
```

Never store credentials, JWTs, PII, production UUIDs or real customer payloads.

### Operational Auth control — OC-01

Enable leaked-password protection only with explicit production authorization.

Required contract:

- capture the previous Auth configuration;
- identify the exact project;
- use a synthetic test account;
- test password change separately;
- test password recovery separately;
- test the current `must_change_password` journey;
- verify normal login remains functional;
- verify the expected compromised-password rejection behavior;
- sanitize all evidence;
- disable/delete the synthetic account after validation;
- document the exact reversal procedure;
- record whether this control is:
  - `BLOCKING FOR F1-02 / MVP1`, or
  - `REQUIRED BEFORE EXTERNAL USERS`, with product and GPT3 approval.

Activation alone is not evidence that Auth flows remain operational.

### PR-09 — final F1-02 gate decision

**Branch:** `docs/f1-02-security-go-decision`  
**Title:** `docs(security): record F1-02 gate decision`

Consolidate exact PR heads/squash commits, lab applications, rollback/reapply tests, production applications, smoke evidence, executable matrix and residual risks. Record one decision:

```text
SECURITY GO FOR TESTED M1 PATHS: GRANTED
```

or

```text
SECURITY GO FOR TESTED M1 PATHS: DENIED
```

Any grant applies only to the explicitly tested M1 paths, commit and environment. It does not approve MesaCliente, PME, integrations, broader commercialization or the whole FECH.AI attack surface.

The merge of PR-09 is self-closing. Do not create another PR merely to record its squash merge.

## 16. Mandatory rollback contract per migration

Every migration PR must contain a migration-specific rollback section with:

```text
migration_id
objects changed
forward operation
rollback SQL or exact rollback procedure
rollback order
dependencies
data-preservation statement
destructive-DDL statement
lab test IDs
reapply test IDs
operational impact
security state restored by rollback
stop condition
containment action
owner role
```

Rules:

1. rollback must be tested in the isolated lab;
2. reapply must be tested after rollback;
3. destructive DDL is prohibited unless separately justified and authorized;
4. rollback may not silently discard real data;
5. rollback that restores a vulnerable grant, policy or direct write surface immediately restores the blocker;
6. technical rollback success does not equal risk acceptance;
7. technical rollback success does not preserve Security Go.

```text
ROLLBACK TECHNICAL: PASS
≠ RISK ACCEPTED
≠ SECURITY GO MAINTAINED
```

If rollback restores a vulnerable boundary:

```text
SECURITY GO: DENIED
PILOT: CONTAINED
NEXT ACTION: INCIDENT/REMEDIATION DECISION
```

## 17. Audit contract

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
- missing tenant, Auth, grant, RLS, RPC or rollback evidence blocks;
- narrated tests do not count;
- production application requires separate authorization;
- the table/RLS/grant matrix and RPC cards are mandatory audit inputs;
- a Security Go recommendation cannot rely on frontend containment alone.

## 18. Production process

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
12. verify objects/grants/policies/functions
13. controlled smoke
14. monitor
15. sanitized evidence closure
```

Production preflight must confirm:

- exact project ref;
- project health;
- exact GitHub commit and migration identity;
- current live object definitions;
- migration not already applied;
- rollback available;
- no active incident;
- no parallel change on the same objects;
- synthetic smoke actor and records authorized.

Safe production verification may include, under separate authorization:

- read-only metadata inspection;
- no-session rejection before any DML;
- invalid/expired token rejection by Auth;
- positive smoke with synthetic actor and synthetic records;
- tenant-filtered read with authorized synthetic data.

Do not execute in production:

- fuzzing;
- mixed-tenant offensive batches;
- self-escalation against a real user;
- writes to real leads or lots;
- destructive ACL tests;
- the complete negative matrix.

Stop and rollback on login regression, unauthorized success, cross-tenant behavior, unexpected mutation, RPC-wide failure, material import/funnel regression or live object drift.

## 19. SFJM process

Mandatory SFJM updates:

- PR-00 records the read-only findings, active remediation program, blockers and next action;
- PR-09 records the final gate, residual risk and handoff.

An intermediate SFJM update is justified only by a material new blocker, architecture change, sequence change, incident, rollback, program suspension, gate change or evidence invalidation.

Do not open an SFJM PR after every merge.

Authorization types:

- `WINDOW_IMPLEMENTATION`: bounded branch/commit/Draft PR execution;
- `PR_LIFECYCLE`: conditional Ready and exact-head squash merge;
- `PRODUCTION_CHANGE`: exact Supabase/Vercel/Auth production operation and rollback.

## 20. Junior analyst execution checklist

Before every PR:

1. read bootstrap, governance and SFJM indexes;
2. confirm live `main`;
3. confirm predecessor and active window;
4. confirm authorization, files, prohibitions and rollback;
5. confirm required table/RLS/grant matrix rows;
6. confirm required RPC contract cards;
7. create exact branch from exact base;
8. issue a bounded Codex task envelope;
9. inspect changed files and diff;
10. run `git diff --check` and relevant build/tests;
11. confirm no secret or PII;
12. open Draft PR;
13. apply only in lab when database-related;
14. reset fixtures before the test cycle;
15. run positive, unauthenticated, unauthorized, cross-tenant, invalid-payload and concurrency tests;
16. run rollback;
17. run reapply;
18. confirm expected and actual mutations;
19. request GPT3/GPT7/GPT1/GPT4 audits as applicable;
20. re-audit after any head change;
21. obtain Ready authority;
22. premerge validate exact head;
23. obtain merge authority;
24. squash merge with expected-head protection;
25. obtain separate production authority;
26. preflight, apply, verify, smoke, monitor and close evidence.

The analyst must stop rather than make an architecture, tenant or authorization decision not defined in this plan.

## 21. Final acceptance

F1-02 can be accepted only when:

- self-escalation is blocked;
- direct unauthorized CRM and history writes are blocked or explicitly constrained by an accepted contract;
- the `times` disposition is current and accepted;
- list ACL and stage visibility are tenant-safe;
- global-stage semantics are documented and tested;
- import is tenant-safe, idempotent and concurrency-safe;
- feedback is allowlisted and atomic;
- all used RPCs have complete contract cards;
- all relevant tables have complete RLS/grant matrices;
- all used RPCs validate session and server-side authority;
- grants, RLS and policies are current and documented;
- executable positive and negative tests pass;
- rollback and reapply pass for every migration;
- production smoke passes;
- OC-01 disposition is recorded and its required tests pass;
- no BLOCKING finding remains;
- GPT3 recommends the gate;
- GPT1 agrees with architecture impact;
- GPT0 confirms evidence and no overclaim;
- Wagner records the final decision.

## 22. Checkpoint candidates

```text
CP1: AS-IS, plan and lab strategy accepted — candidate 25%
CP2: self-escalation blocked and password flow preserved — candidate 50%
CP3: CRM/history/ACL/payload remediation accepted — candidate 75%
CP4: final tests, production evidence and gate accepted — candidate 100%
```

No checkpoint or WDP is earned by this plan alone.

## 23. Immediate next safe action

The earlier PR-00 / isolated-lab next action is consumed and superseded by the
2026-09-02 Product Authority J3 bounded-residual exception recorded in this
document.

Standing Product Authority constraints are:

```text
NO LAB
NO SECOND SUPABASE PROJECT
NO PREVIEW BRANCH
NO PRODUCTION MIGRATION ROLLBACK TEST
```

Therefore:

- do not request cost confirmation for a Supabase Branch;
- do not create or propose an isolated LAB as the current next action;
- do not reinterpret IMP-003 or rollback/reapply as PASS;
- preserve both obligations as `NOT_DETERMINED`;
- do not grant Security Go.

The single current next safe action is:

```text
J4 / PR-08 — REPEATABLE EXECUTABLE SECURITY MATRIX
SCOPE / EVIDENCE-COVERAGE / PROHIBITIONS RECONSTRUCTION FIRST
SEPARATE PRODUCT AUTHORITY IMPLEMENTATION GATE REQUIRED
```

Any older lab-oriented planning language in this historical master plan is
superseded where it conflicts with the standing Product Authority constraints
above. This does not silently waive J4 or final F1-02 proof obligations; those
must be explicitly reconciled at the J4 gate before implementation or final
acceptance.
