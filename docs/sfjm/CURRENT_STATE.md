# FECH.AI — SFJM Current State

**Lifecycle state:** `F1_02_READ_ONLY_COMPLETED / SECURITY_GO_DENIED / REMEDIATION_PROGRAM_IN_DRAFT`  
**Record type:** `OPERATIONAL_STATE / DOCUMENTATION_ONLY`  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Context understood

FECH.AI remains Pilot Production, multi-tenant / multi-company, with real users, sensitive lead/customer data, active modules and security hardening in progress.

```text
Product phase: MVP 1 — Família
Frontend requests and displays.
Backend / RPC / Supabase validates and decides.
AI assists, but is not authority.
```

## 2. Canonical GitHub state

```text
Canonical main validated live: 0555bad889c6ab85970ee242a0e35ac6873508e8
Commit: docs(sfjm): close PR99 cycle and prevent recursive reconciliation (#100)

PR #100: CLOSED / MERGED
PR #100 final head: defeda035c5e7f709e31707a84c9edd488c99799
PR #100 squash commit: 0555bad889c6ab85970ee242a0e35ac6873508e8
Open PRs observed before PR-00 creation: NONE
```

PR #100 closed the recursive documentation-only reconciliation loop. A later material operational change may still require one substantive update, but a documentation closure merge does not generate another PR solely to record itself.

## 3. F1-01 state

```text
F1-01 evidence map: MERGED
F1-01 map review: PASS WITH RESIDUAL RISK
F1-01 checkpoint acceptance: NOT GRANTED
Accepted WDP: 0
```

The evidence map remains a source-path and gap artifact. It does not prove runtime correctness, tenant isolation or Security Go.

## 4. F1-02 read-only execution

The separately authorized read-only inspection was executed against:

```text
Supabase project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Status observed: ACTIVE_HEALTHY
Repository commit correlated: 0555bad889c6ab85970ee242a0e35ac6873508e8
```

Read-only targets included project provenance, grants, RLS/force-RLS, policies, function signatures and bodies, triggers, constraints, execution exposure, advisors and current source call-site evidence.

```text
Supabase mutations: ZERO
Lead/customer row reads: ZERO
Negative tests in production: NOT EXECUTED
```

## 5. Security decision

```text
Security Go: DENIED
F1-02 status: ACTIVE REMEDIATION / BLOCKED BY CONFIRMED SECURITY FINDINGS
MVP Família readiness: NOT CONFIRMED
Runtime validation: NOT CONFIRMED
WDP: 0 / NOT AWARDED
```

### BLOCKING

1. authenticated broker self-update can alter authority-bearing `corretores` fields and potentially obtain root/global authority;
2. direct structural write exposure remains on CRM tables including `leads` and `lotes`;
3. direct insertion can forge `funil_movimentacoes` history;
4. list-visibility targets are not fully proven tenant-safe.

### REQUIRED

- tenant-safe funnel-stage listing;
- company-scoped import-session deduplication;
- strict feedback validation;
- leaked-password protection decision;
- isolated negative tests and rollback evidence;
- final independent gate record.

Canonical evidence candidates in the PR-00 branch:

```text
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

These remain Draft evidence until independently audited at the exact PR head and merged.

## 6. Program structure

```text
Windows: 5
Planned PRs: 10
Isolated Supabase security lab: 1, subject to explicit cost confirmation
Formal gates: 2
Recursive closure PRs: 0
```

Sequence:

```text
J0 — plan, evidence and lab strategy
J1 — identity and self-escalation
J2 — CRM direct writes and history
J3 — ACL, tenant and payload integrity
J4 — consolidated negative tests and final gate
```

## 7. Current PR-00 state

```text
Branch: docs/f1-02-security-remediation-program
Base: 0555bad889c6ab85970ee242a0e35ac6873508e8
Purpose: version the material F1-02 findings and remediation program
Type: documentation-only
```

The user's instruction to begin the approved program authorizes creation of this bounded documentation branch, commits and one Draft PR. The authority is consumed when the Draft PR is created.

It does not authorize:

- additional commits after Draft creation;
- Ready or merge;
- Supabase Branch creation or cost;
- runtime/frontend changes;
- migrations, RLS, grants, policies, RPC or Auth changes;
- negative tests;
- production;
- Security Go or WDP.

## 8. Evidence available

- exact GitHub `main` and PR #100 merge state;
- F1-01 used-path inventory;
- exact Supabase project provenance;
- live read-only grants, RLS, policies, RPC/function definitions, triggers, constraints and advisors;
- confirmed direct frontend password-state patch dependency;
- full remediation-program draft and sanitized finding draft.

## 9. Evidence missing

- independent audit of PR-00 final head;
- accepted isolated-lab strategy and cost confirmation;
- synthetic two-company fixtures and actors;
- executed negative tests;
- migration and rollback evidence;
- post-remediation grants/RLS/RPC evidence;
- production application and smoke evidence;
- final Security Go decision.

## 10. Main risks

- treating read-only discovery as completed Security Go;
- performing security tests or mutations in production;
- revoking grants before replacing the password-flow dependency;
- mixing multiple primary risks in one technical PR;
- using real production data in the lab or evidence;
- counting PRs or planning as WDP;
- creating a documentation PR after every technical merge;
- allowing an executor to approve its own work.

## 11. Areas not to alter without separate scope

- runtime and frontend;
- Supabase, migrations, RLS, grants, policies, RPC bodies and Auth;
- Edge Functions, Vercel, GitHub Actions and production;
- MesaCliente, PME, ADS/CAPI, Make/n8n and integrations;
- real users, companies, teams, brokers, leads or customer data.

## 12. Next safe action

Complete the bounded PR-00 Draft, validate its exact changed files and head, and send it to independent GPT0/GPT1/GPT3 audit. Do not create the Supabase security lab or begin PR-01 before PR-00 is accepted and separately authorized.
