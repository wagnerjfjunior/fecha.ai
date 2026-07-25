# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / F1_02_REMEDIATION / FAIL_CLOSED`  
**Observed on:** 2026-07-24

The following actions remain blocked until exact evidence, audit and authorization remove the relevant block.

## 1. Product and delivery blocks

- declare MVP 1 — Família ready;
- treat F1-01 documentation as accepted product behavior;
- advance F1-03 or F1-04 before F1-02 acceptance;
- start the family pilot while BLOCKING security findings remain;
- count planning, commits, PRs or merges as WDP without an accepted checkpoint;
- grant F1-01 acceptance, F1-02 acceptance or any WDP from PR-00 alone.

## 2. Security blocks

- grant Security Go;
- treat authenticated session as sufficient authorization;
- treat the read-only finding record as executed negative-test evidence;
- use production as the negative-test laboratory;
- create real test users or mutate real companies, brokers, teams, leads or customers;
- rely on the audit trigger as prevention of privilege escalation;
- revoke current broker update access before the password-flow dependency is replaced and tested;
- approve any M1 path without current Auth, tenant/company, permission, grant/RLS/RPC and negative-test evidence.

## 3. Confirmed blockers to remediate

### B1 — broker self privilege escalation

Direct `corretores` update exposure must be removed after a narrow password-state RPC and frontend cutover are proven.

### B2 — direct CRM structural writes

Direct write exposure on `leads` and `lotes` must be restricted only after current RPC coverage is confirmed and tested.

### B3 — forgeable funnel history

Direct insert into `funil_movimentacoes` must be removed and history must be produced atomically by controlled backend paths.

### B4 — list ACL tenant integrity

Visibility targets and access helpers must prove same-company relationships server-side.

## 4. PR-00 lifecycle blocks

Until independent audit passes at the exact final head:

- do not mark PR-00 Ready;
- do not merge PR-00;
- do not treat the plan or findings as accepted canonical evidence;
- do not create the Supabase security lab;
- do not begin PR-01.

After Draft creation, no additional commit is authorized merely to restate that creation or its future merge.

## 5. Runtime and environment blocks

Without separate scope and authorization, do not change:

- frontend or runtime;
- Supabase schema, data, migrations, RLS, grants, policies, functions/RPCs or Auth;
- Edge Functions;
- Vercel configuration or production deployment;
- GitHub Actions;
- MesaCliente, PME, ADS/CAPI, Make/n8n or integrations.

## 6. Laboratory blocks

The isolated Supabase Branch is blocked until:

- PR-00 is accepted and merged;
- exact project and branch purpose are reconfirmed;
- cost confirmation is presented and explicitly approved;
- synthetic-data-only rules are accepted;
- branch destruction/containment is defined.

If the lab is unavailable, technical negative testing stops. Production is not the fallback.

## 7. Audit and merge blocks

- no audit without exact PR/head/diff/changed files;
- no merge recommendation after a head change without re-audit;
- no executor self-approval;
- no migration approval without rollback and lab test evidence;
- no production operation under a GitHub merge authorization;
- no production change without a separate `PRODUCTION_CHANGE` authorization.

## 8. Continuity blocks

- do not reconstruct FECH.AI from memory when GitHub/live evidence is available;
- do not open a reconciliation PR after every technical merge;
- do not create a PR solely to record the squash merge of a bounded closure/gate PR;
- do not expand a narrow PR to absorb future-window risks;
- do not reopen settled PR #94–#100 history without new evidence.

## 9. Removal rule

A block may be removed only when the record identifies:

- canonical evidence;
- exact repository/commit/environment;
- responsible validator;
- exact authorization;
- scope newly permitted;
- residual risk;
- rollback/containment;
- expiration condition;
- next safe action.
