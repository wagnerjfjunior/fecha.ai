# FECH.AI — F1-02 Security Remediation Master Plan

**Status:** `PROGRAM_BASELINE / J0_STRATEGY_AMENDMENT_IN_DRAFT / SECURITY_GO_DENIED`  
**Original baseline date:** `2026-07-24`  
**Strategy amendment date:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Canonical main before PR #102:** `affbae1a598928010b0fa7db967734de522c13b4`  
**Supabase project:** `Discador-MesaCliente`  
**Project ref:** `uobxxgzshrmbtjfdolxd`  
**Region:** `sa-east-1`  
**Product phase:** `MVP 1 — Família`

## 1. Purpose

This document defines the planning, implementation, validation, release, rollback and evidence program for F1-02 — Security Go for the FECH.AI M1 paths actually used.

It is not a Security Go decision and does not itself authorize runtime, frontend, Supabase, migration, RLS, grant, policy, RPC, Auth, Vercel, GitHub Actions or data changes.

## 2. J0 strategy amendment and precedence

The product authority decided to operate the current MVP as a controlled free beta on the primary Supabase project, accepting availability and beta-data-loss risk while preserving all security and tenant-isolation requirements.

The strategy artifact is:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
```

Until PR #102 is independently audited and merged, the amendment is `PR_DRAFT / NOT_YET_CANONICAL`.

After merge, when this master plan conflicts with the strategy artifact solely about the mandatory use of an isolated environment, the strategy artifact prevails. No other security, evidence, rollback, authorization or separation-of-duties requirement is silently removed.

The following original rules are superseded or reinterpreted:

| Original rule | Controlled Beta Primary interpretation |
|---|---|
| One isolated Supabase Branch is mandatory before every technical PR | An isolated environment is optional for low-blast-radius work and mandatory only for tests or rollback exercises that cannot be safely contained on the live primary project |
| `STOP — LAB ENVIRONMENT UNAVAILABLE` blocks all remediation | Remediation may continue with static proof, read-only evidence, bounded migration and safe-live validation; unsafe tests remain deferred or require isolation |
| `LAB_VALIDATION_PASSED` is a universal lifecycle state | Replaced by `CONTROLLED_VALIDATION_PASSED`, with each test classified as `SAFE_LIVE`, `ISOLATED`, `DEFERRED` or `PROHIBITED` |
| Every migration must be applied, rolled back and reapplied in an isolated lab | Rollback must always be designed and reviewed; live rollback is executed only when explicitly authorized and operationally required; destructive rollback/reapply exercises require isolation |
| Production is never an alternative laboratory | Preserved. The primary project is a live Pilot Production environment and may receive bounded remediation, but never offensive or destructive experimentation |
| PR-01 cannot start until a Supabase Branch exists | PR-01 remains blocked until this amendment is canonical and receives a separate implementation authority; a branch is not a universal prerequisite |

## 3. Operating principles

```text
Frontend requests and displays.
Backend / RPC / Supabase validates and decides.
AI assists, but is not authority.

One PR = one primary risk = one simple rollback.
No evidence = no approval.
No authorization = no operation.
The executor does not approve its own work.
The primary project is live; it is not an unrestricted laboratory.
```

## 4. Environment classification

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Broad paid commercialization: BLOCKED
Paid SLA: NO
Real users: YES
Multiple companies: YES
Sensitive lead/customer data: YES
Security Go: DENIED
```

The absence of paid commercialization or SLA does not downgrade Auth, tenant isolation, privilege, confidentiality, integrity, LGPD or evidence obligations.

## 5. Accepted and non-accepted risk

### 5.1 Accepted operating risk for the controlled beta

- planned or unplanned downtime;
- maintenance windows;
- temporary feature unavailability;
- manual support and recovery;
- possible loss of beta data;
- rollback to a prior application/schema state;
- absence of a paid SLA.

### 5.2 Not accepted

- privilege escalation;
- cross-tenant access or mutation;
- disclosure of leads, contacts, credentials, tokens or real payloads;
- unauthorized change of company, role, team, user or authority;
- forged real CRM history;
- use of real users or data as security-test fixtures;
- destructive or offensive testing in the primary project;
- unbounded migrations or silent database changes;
- Security Go without current evidence;
- broad paid commercialization before Security Go.

Acceptance of possible data loss is not a security waiver and is not evidence of legal consent for privacy or cross-company exposure.

## 6. Confirmed findings

### BLOCKING

#### B1 — broker self privilege escalation

Authenticated direct update exposure on `public.corretores` includes authority-bearing fields. A self-update that changes role or administrative fields can potentially create global authority.

#### B2 — excessive direct CRM writes

Authenticated direct structural write exposure remains on `public.leads` and `public.lotes`, while used flows are intended to be controlled by backend/RPC validation.

#### B3 — forgeable funnel history

Authenticated direct insert into `public.funil_movimentacoes` can bypass one authorized atomic transition.

#### B4 — list ACL tenant integrity

List-visibility targets and helpers do not yet prove every target relationship is same-company server-side.

### REQUIRED

- tenant-safe `listar_funil_estagios`;
- company-scoped import-session idempotency;
- strict feedback allowlist before the first write;
- explicit disposition for direct writes on `times`;
- leaked-password-protection decision;
- current object inventories;
- repeatable validation evidence;
- rollback and containment evidence;
- independent final Security Go gate.

## 7. Roles and separation of duties

| Role | Responsibility |
|---|---|
| Wagner | Product authority; authorizes scope, lifecycle and live operations |
| GPT0 | Documentation, evidence, consistency, overclaim and handoff audit |
| GPT1 | SaaS architecture, sequencing, boundaries and rollback audit |
| GPT3 | Supabase Auth/RLS/grants/policies/RPC/security contract audit |
| GPT4 | GitHub/Vercel lifecycle, exact head, checks, merge and rollback evidence |
| GPT7 | LeadOps/CRM/Discador operational behavior |
| GPT2 | User-facing password-flow UX when affected |
| GPT5 | Monitoring, incident, recovery and operational evidence |
| Codex | Bounded implementation only; never final authority |

## 8. Authorization model

Each technical change uses separate authority envelopes.

### 8.1 `WINDOW_IMPLEMENTATION`

Authorizes an exact GitHub branch, files, objective, tests and rollback for one primary risk. It does not authorize Ready, merge or Supabase application.

### 8.2 `TECHNICAL_PR_LIFECYCLE`

Authorizes Ready and/or exact-head merge after independent audit and live GitHub validation. It must identify PR, base, head, checks, method, expected-head protection and expiration. It does not authorize Supabase application.

### 8.3 `CONTROLLED_BETA_PRIMARY_CHANGE`

Authorizes one exact live Supabase operation. It must identify:

- project and ref;
- migration/config identity;
- affected objects;
- preflight;
- data and availability impact;
- backup/recovery/containment;
- application order;
- smoke tests;
- monitoring and stop conditions;
- rollback authority and sequence;
- evidence capture;
- responsible operator;
- expiration.

### 8.4 `SECURITY_GATE`

Authorizes only the final decision based on current evidence. It does not retroactively authorize missing tests or operations.

No alias or generic phrase expands authority.

## 9. Controlled validation model

Every validation item must be classified before execution.

### 9.1 `SAFE_LIVE`

Permitted only under exact authority when a success or failure cannot escape the synthetic graph or affect real authority/data.

Examples:

- read-only introspection of grants, policies, functions and owners;
- positive smoke of a narrow RPC using exact synthetic objects;
- no-session rejection before DML;
- invalid-token rejection without real credentials;
- exact-ID DML against synthetic, non-authority-bearing records;
- B2, B3 and B4 tests where unexpected success is contained to synthetic objects.

### 9.2 `ISOLATED`

Required when unexpected success can create real authority, expose real data, affect global controls, require reset, fuzzing, broad discovery or destructive rollback/reapply.

Mandatory isolated examples:

- actual self-promotion to `admin_global` or root;
- mutation of authority-bearing `corretores` fields as an adversarial test;
- broad cross-tenant discovery queries;
- mixed-tenant offensive arrays;
- fuzzing, load or volume tests;
- disabling RLS, grants, policies or Auth to test behavior;
- destructive rollback/reapply exercises;
- full negative matrix whose blast radius cannot be bounded.

An isolated environment may be a Supabase Branch, disposable project, local Supabase with proven relevant parity or another contained harness. It must contain no real data or credentials.

### 9.3 `DEFERRED`

A required test that cannot currently be executed safely. It remains `NOT_VERIFIED`, keeps the relevant finding open and may block final Security Go.

### 9.4 `PROHIBITED`

Never execute:

- tests with real users, companies, brokers, leads, customers or identifiers;
- `service_role` in browser/frontend/untrusted client;
- reuse of real JWTs, passwords or payloads;
- deliberate corruption or deletion of real data;
- broad cross-tenant queries to discover whether real records appear;
- unbounded or exploratory SQL in the primary project.

## 10. B1 special rule: intentional admin assignment is not a test

A future intentional designation of an `admin_global` may be considered only as a separate administrative-governance operation with:

- exact named user and verified identity;
- documented business necessity;
- least-privilege analysis;
- product-authority approval;
- server-side controlled operation;
- audit trail;
- revocation/deactivation procedure;
- post-operation verification.

That operation cannot be used as evidence that self-escalation is blocked and does not authorize any user to promote themselves.

On the primary project, B1 may be validated by structural proof and positive controlled smoke. The actual adversarial attempt to self-promote to `admin_global` remains `NOT_VERIFIED` until executed in an isolated environment.

## 11. Synthetic fixture contract

A safe-live test requires an integral synthetic graph:

- synthetic company A and company B;
- synthetic users/profiles/brokers;
- synthetic teams, lists, lots, leads and stages;
- identifiers clearly marked and versioned;
- deterministic manifest and seed procedure;
- pre/post counts;
- cleanup or deactivation procedure;
- owner and expiration;
- sanitized evidence.

Invariants:

1. No synthetic object may reference a real company, user, broker, team, list, lead or customer.
2. Real brokers must never receive synthetic leads, lots, lists or tasks.
3. Synthetic users must not receive global authority capable of reaching real objects.
4. Unexpected success must remain inside the synthetic graph.
5. Cleanup failure stops further testing and triggers containment.
6. Fixture cleanup is not schema/configuration rollback.

Fixture creation requires separate live-operation authority.

## 12. Mandatory inventories before each implementation

For affected objects, record current and target state for:

- table and column grants;
- RLS and FORCE RLS;
- policy identity, `USING` and `WITH CHECK`;
- function/RPC signature, owner, security mode and `search_path`;
- execute grants;
- triggers and constraints;
- server-side actor and tenant derivation;
- frontend/runtime call sites;
- data impact;
- tests and rollback.

At minimum, inventory:

```text
public.corretores
public.leads
public.lotes
public.times
public.funil_movimentacoes
public.lista_visibilidade
public.listas
public.funil_estagios
```

## 13. Program windows and PR sequence

```text
J0 — baseline, evidence and environment strategy
J1 — password dependency and broker authority
J2 — CRM direct writes and funnel-history integrity
J3 — ACL, tenant visibility and payload integrity
J4 — consolidated validation and final gate
```

Planned PRs remain a sequencing ceiling, not a productivity target:

| PR | Primary risk |
|---|---|
| PR-00 / #101 | Canonical findings and remediation baseline — merged |
| Strategy / #102 | Controlled Beta Primary amendment — Draft |
| PR-01 | Narrow password-state RPC and frontend cutover |
| PR-02 | Restrict broker authority-bearing direct updates |
| PR-03 | Restrict direct writes on leads |
| PR-04 | Restrict/directly disposition lotes and times writes |
| PR-05 | Funnel-history atomicity and direct-insert restriction |
| PR-06 | List ACL same-company validation |
| PR-07 | Funnel stages, import idempotency and feedback validation |
| PR-08 | Controlled validation matrix and evidence consolidation |
| PR-09 | Final F1-02 gate and bounded handoff |

A PR may be split if one rollback cannot safely cover its primary risk.

## 14. Technical PR lifecycle

```text
PLANNED
→ IMPLEMENTATION_AUTHORIZED
→ DRAFT_OPEN
→ EXACT_HEAD_AUDITED
→ CONTROLLED_VALIDATION_PASSED
→ READY_AUTHORIZED
→ READY
→ MERGE_AUTHORIZED
→ MERGED
→ LIVE_CHANGE_AUTHORIZED
→ APPLIED
→ SMOKE_PASSED or ROLLED_BACK
→ EVIDENCE_RECORDED
```

`CONTROLLED_VALIDATION_PASSED` must state which items are `SAFE_LIVE`, `ISOLATED`, `DEFERRED` and `PROHIBITED`. Deferred material evidence remains a blocker when required for the final gate.

## 15. Rollback model

### 15.1 Documentation rollback

One revert of the documentation PR.

### 15.2 Fixture cleanup

Deletes or deactivates synthetic objects according to the manifest. It is not a migration rollback.

### 15.3 Schema/configuration rollback

Reverses one exact migration or configuration change. It affects the live environment and requires separate authority, impact analysis, ordering, monitoring and stop conditions.

Rollback must be designed before merge. Destructive rollback/reapply rehearsal is not performed in the primary project merely to prove reversibility.

## 16. Primary-project change protocol

Before application:

1. validate canonical main and exact technical PR head;
2. validate current Supabase project/ref;
3. refresh affected-object evidence;
4. verify migration checksum and rollback;
5. declare data/availability impact;
6. confirm recovery/containment;
7. define smoke, monitoring and stop conditions;
8. obtain `CONTROLLED_BETA_PRIMARY_CHANGE` authority.

During application:

1. apply only the exact authorized operation;
2. stop on unexpected object, error, row count or dependency;
3. capture sanitized evidence;
4. do not improvise follow-up SQL.

After application:

1. verify objects, grants, policies and functions;
2. run only permitted smoke/validation;
3. monitor;
4. rollback only under the authorized condition;
5. record residual risks and evidence freshness.

## 17. Final Security Go gate

Security Go remains denied until evidence proves, for used M1 paths:

- no self-escalation path;
- tenant isolation and same-company validation;
- controlled CRM writes and history integrity;
- current Auth, grants, RLS, policies and RPC contracts;
- permitted negative evidence;
- isolated or equivalent evidence for high-blast-radius cases, especially B1;
- tested operational rollback/containment appropriate to each change;
- runtime smoke;
- independent GPT0/GPT1/GPT3/GPT4 review;
- explicit product-authority decision.

If B1 adversarial evidence remains `NOT_VERIFIED`, final Security Go remains blocked unless a later independent gate formally accepts an equivalent proof with explicit residual risk. No such acceptance exists now.

## 18. Current governance state

```text
PR #102: OPEN / DRAFT
Pre-correction head: fc83ed752217bfc39810dfba38e93405bc7382b8
Final corrective head: authoritative in live GitHub PR metadata and PR description
Changed files after correction: 8 documentation files
Strategy canonicality: NOT_YET_CANONICAL
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
PR-01: NOT AUTHORIZED
Supabase mutation: NOT AUTHORIZED
WDP: 0
```

A commit cannot contain its own SHA without creating a recursive hash change. Therefore the final corrective head is recorded in live PR metadata and the PR description; this document records the pre-correction head and the rule for resolving the final head.

## 19. Next safe action

Validate the single corrective commit and exact eight-file diff, then repeat independent GPT0/GPT1/GPT3 audits at the new live head.

Do not mark Ready, merge, start PR-01 or access Supabase under this document.
