# FECH.AI — SFJM Current Handoff

**Status:** `CURRENT_HANDOFF / F1_02_REMEDIATION_PROGRAM_IN_DRAFT`  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

F1-02 read-only discovery is complete. Security Go is denied because live evidence confirmed material authorization and tenant-isolation blockers. The project is entering a planned remediation program, not implementation-by-improvisation.

```text
MVP phase: MVP 1 — Família
F1-01 acceptance: NOT GRANTED
F1-02: ACTIVE REMEDIATION / BLOCKED
Security Go: DENIED
WDP: 0
```

## 2. Canonical anchors

```text
Canonical main: 0555bad889c6ab85970ee242a0e35ac6873508e8
Commit: docs(sfjm): close PR99 cycle and prevent recursive reconciliation (#100)

PR #100: CLOSED / MERGED
PR #100 final head: defeda035c5e7f709e31707a84c9edd488c99799
PR #100 squash: 0555bad889c6ab85970ee242a0e35ac6873508e8
```

Resolve live `main` again before any later sensitive action.

## 3. Live environment evidence

```text
Supabase project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Status observed: ACTIVE_HEALTHY
Inspection type: read-only metadata/definition review
Mutations: ZERO
Negative production tests: ZERO
```

No real lead/customer rows or production credentials were included in the evidence.

## 4. Confirmed blockers

### B1 — self privilege escalation

A broker's direct self-row update surface in `corretores` includes authority-bearing columns. `is_root()` can recognize an `admin_global` broker. The critical-change trigger is monitoring, not enforcement.

### B2 — direct CRM structural writes

Direct `authenticated` write surface remains on `leads` and `lotes`, while used paths are expected to be RPC-controlled.

### B3 — funnel history integrity

Direct insertion into `funil_movimentacoes` can bypass one authorized atomic transition.

### B4 — list ACL tenant validation

Visibility targets and the access helper do not yet prove every relevant same-company relationship server-side.

Required additional hardening includes funnel-stage filtering, company-scoped import sessions, strict feedback validation and leaked-password protection decision.

## 5. Selected program

```text
Program: F1-02 Security Remediation
Windows: 5
Planned PRs: 10
Security lab: one isolated Supabase Branch after explicit cost confirmation
Formal gates: 2
```

Canonical Draft artifacts:

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
```

Window sequence:

```text
J0 — program/evidence/lab strategy
J1 — password dependency and self-escalation
J2 — CRM direct writes and funnel history
J3 — ACL, tenant reads and payload integrity
J4 — repeatable negative tests and final gate
```

## 6. Active PR-00

```text
Branch: docs/f1-02-security-remediation-program
Base: 0555bad889c6ab85970ee242a0e35ac6873508e8
Title: docs(security): establish F1-02 remediation program
Type: documentation-only Draft
```

Expected changed files, exactly:

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

The authority covers branch/commits/Draft creation only and is consumed at Draft creation. It does not cover corrections, Ready, merge or technical execution.

## 7. Specialist routing

```text
GPT0: evidence and documentation audit
GPT1: architecture and sequencing audit
GPT3: security finding and remediation-contract audit
GPT4: PR/head/diff/check/merge lifecycle when later authorized
GPT7: CRM/Discador behavior for technical PRs
GPT2: password-flow UX only if user-facing states change
GPT5: production monitoring/rollback/incident
Codex: bounded implementation only after approved envelopes
```

The executor must not be the final auditor.

## 8. Evidence available

- exact GitHub main and PR #100 closure;
- F1-01 current path inventory;
- exact live Supabase project provenance;
- current grants, RLS/policies, functions, triggers, constraints and advisors;
- direct frontend password-state patch dependency;
- complete remediation program Draft;
- sanitized finding record Draft.

## 9. Evidence missing

- independent PR-00 audit at final head;
- PR-00 Ready/merge lifecycle;
- isolated lab and explicit cost confirmation;
- synthetic two-company fixtures;
- executed negative tests;
- migration and rollback tests;
- production application/smoke;
- final F1-02 gate.

## 10. What must not be redone

- do not reconstruct the project from zero;
- do not reopen PR #94–#100 without new evidence;
- do not repeat the read-only discovery unless an invalidating event requires narrow refresh;
- do not create an SFJM PR after every technical merge;
- do not create a PR solely to record PR-00 or PR-09 squash merge;
- do not count PRs as product value;
- do not treat production as the lab.

## 11. What must not be altered without separate authorization

- any file after PR-00 Draft creation;
- PR-00 Ready or merge;
- Supabase Branch/cost;
- frontend/runtime;
- migrations, RLS, grants, policies, RPCs/functions or Auth;
- Edge Functions, Vercel, Actions or production;
- MesaCliente, PME, ADS/CAPI, Make/n8n and integrations;
- real users or data;
- Security Go, F1-01/F1-02 acceptance or WDP.

## 12. Single next safe action

Validate PR-00 exact final head, changed files and diff, then send it to independent GPT0/GPT1/GPT3 audit.

After PR-00 is independently accepted and later merged under separate authority, request explicit cost confirmation and authorization for one isolated branch:

```text
f1-02-security-lab
```

Do not begin PR-01 before those gates.

## 13. New-conversation startup

A receiving conversation must:

1. read bootstrap, governance and SFJM indexes;
2. validate live `main` and the active PR/head;
3. read the two PR-00 evidence artifacts;
4. preserve Security Go denied and WDP 0;
5. preserve the five-window/ten-PR sequence unless new evidence justifies change;
6. keep production out of exploratory testing;
7. require exact authority for every lifecycle and production transition.
