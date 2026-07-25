# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / CONTROLLED_BETA_PRIMARY_STRATEGY / FAIL_CLOSED`  
**Observed on:** `2026-07-25`

The following actions remain blocked until exact evidence, audit and authorization remove the relevant block.

## 1. Product and commercialization blocks

- declare Security Go;
- describe the MVP as generally production-ready;
- open broad paid commercialization;
- promise a paid availability/recovery SLA;
- treat accepted beta data-loss risk as acceptance of security defects;
- award F1-02 acceptance or WDP without the formal gate.

The MVP Família may continue only as an informed, controlled beta.

## 2. Confirmed security blockers

### B1 — broker self privilege escalation

Direct `corretores` update exposure must be replaced/restricted so a broker cannot alter authority-bearing fields.

### B2 — direct CRM structural writes

Direct structural writes to `leads` and `lotes` must be constrained to approved backend/RPC paths.

### B3 — forgeable funnel history

Direct insertion into `funil_movimentacoes` must be removed or constrained so history is generated atomically by an authorized operation.

### B4 — list ACL tenant integrity

List visibility targets and helpers must prove same-company relationships server-side.

### Required supporting controls

- tenant-safe funnel-stage visibility;
- company-scoped import-session idempotency;
- strict feedback validation;
- current disposition of `times` writes;
- Auth leaked-password decision;
- repeatable evidence, rollback and final independent gate.

## 3. Strategy-PR lifecycle blocks

Until the Controlled Beta Primary documentation PR is independently audited and merged:

- do not begin PR-01;
- do not create migrations or SQL;
- do not alter frontend/runtime;
- do not access or mutate Supabase/Auth;
- do not create synthetic fixtures;
- do not run negative tests;
- do not mark the strategy canonical;
- do not mark Ready or merge without separate authority.

## 4. Primary-environment mutation blocks

Even after the strategy PR is merged, no primary-environment change is allowed without a separate exact authorization.

Blocked without that authorization:

- apply a migration;
- revoke or grant privileges;
- create, alter or drop policies;
- alter RLS/FORCE RLS;
- create or replace functions/RPCs;
- change Auth configuration;
- change frontend call sites;
- create test actors or fixtures;
- execute cleanup/rollback SQL;
- run manual production commands.

A GitHub PR merge does not authorize a Supabase operation.

## 5. Test blocks

Always prohibited:

- tests targeting real company, broker, team, lead or customer identifiers;
- privilege-escalation attempts using a real account;
- reading or writing another real company's records;
- destructive volume, load or fuzz tests in the primary project;
- deliberate corruption of real data;
- use of real JWTs, passwords, payloads or customer contact data in evidence;
- tests without a manifest, cleanup, stop condition and separate authority.

Potentially permitted only after separate authorization:

- synthetic positive flows;
- synthetic denial tests;
- synthetic cross-company isolation tests;
- rollback/reapply against synthetic records;
- bounded smoke tests after one exact change.

## 6. Runtime and integration blocks

Without explicit scope, do not alter:

- MesaCliente;
- PME;
- ADS/CAPI/SEO;
- Make/n8n;
- external messaging/portal integrations;
- Edge Functions;
- Vercel configuration;
- GitHub Actions.

## 7. Governance blocks

- no technical approval without exact branch/head/diff/files;
- no merge after a head change without revalidation;
- no executor self-approval;
- no multi-risk technical PR;
- no untested or undefined rollback;
- no generic authorization such as "continue" for a live mutation;
- no documentation-only PR after every technical merge;
- no overclaim that beta consent removes LGPD, tenant-isolation or privilege obligations.

## 8. Removal rule

A block may be removed only when the record identifies:

- exact repository/base/head;
- exact environment/project;
- exact objects and operations;
- current evidence;
- responsible validator;
- acceptance criteria;
- rollback/containment;
- residual risk;
- explicit authority and expiration;
- next safe action.