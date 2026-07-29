# FECH.AI — SFJM Current State

**Lifecycle state:** `F1_02_ACTIVE / PR02_DRAFT_IMPLEMENTED / STATIC_VALIDATION_PASSED / NOT_DEPLOYED`  
**Record type:** `OPERATIONAL_STATE / CODE_AND_DOCUMENTATION`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Frontend requests and displays. Backend, RPC and Supabase validate and decide. AI assists but is not authority.

## 2. Canonical GitHub anchor

```text
Current canonical main:
cec1b22430adf1a002b172992cf6c5ea5bb427de

PR #107:
CLOSED / MERGED
Squash: cec1b22430adf1a002b172992cf6c5ea5bb427de

PR #108:
OPEN / DRAFT / NOT MERGED
Base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
Live branch: security/f1-02-password-flow-cutover-1
Initial implementation commit: c458461e810e24adb7d71f7d155be06e9cf54eac
Current head after documentation reconciliation: resolve live
```

Branch content is proposed state and is not canonical `main`.

## 3. PR-01 prerequisite state

```text
Migration: 20260727080929 / f1_02_password_state_rpc / APPLIED
RPC: public.marcar_senha_inicial_definida() / EXISTS
Arguments: none
SECURITY DEFINER: true
search_path: pg_catalog
authenticated EXECUTE: true
anon EXECUTE: false
service_role EXECUTE: false
PUBLIC EXECUTE: false
Authenticated positive smoke: PASS
Immediate repeated-call idempotency: PASS
```

Residual PR-01 runtime risks remain as previously recorded. They are not reopened by PR #108.

## 4. PR-02 implementation state

PR #108 changes the mandatory password-completion path only:

```text
src/App.jsx
changePassword(token, nova)
→ marcar_senha_inicial_definida({}, token)
→ require return === true
→ onConcluido()
```

The direct patch is removed from `TrocarSenhaObrigatoria`, and `corretorId` is removed from that component contract and call.

Implementation commit scope:

```text
1 commit
1 file
6 additions
3 deletions
```

## 5. Static validation

```text
npm run build: PASS
Workflow run: 30411229438
Job: 90447536855
Build exit code: 0
Vercel Preview status: success
```

This establishes static buildability of the implementation commit. It does not establish deployed production behavior.

## 6. Current changed-file contract

After the bounded documentation reconciliation, PR #108 must contain exactly:

```text
src/App.jsx
docs/security/evidence/2026-07-28-pr02-password-flow-cutover.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

No database, migration, RPC-body, RLS, Auth, Edge, Vercel configuration or production-data change belongs to the PR.

## 7. Residual risk

```text
Mandatory-password direct patch: REMOVED IN PROPOSED PR
Administrative EditarCorretorModal direct patch: PRESERVED
Interactive UI success: NOT EXECUTED
RPC-unavailable UI test: NOT EXECUTED
Deployed frontend proof: NOT ESTABLISHED
Production smoke: NOT EXECUTED
Legacy direct UPDATE denial: NOT ESTABLISHED
PR-03: BLOCKED
```

The administrative path cannot be redirected to the self-service RPC without a separate server-side authorization design.

## 8. Current authority state

```text
PR-02 bounded implementation: CONSUMED
Draft PR creation: CONSUMED
Documentation reconciliation: CONSUMED ON PUBLICATION
Additional commit: NOT AUTHORIZED
Review/comment: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Deployment: NOT AUTHORIZED
Production smoke: NOT AUTHORIZED
PR-03: BLOCKED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 9. Next safe action

Run one independent GPT3 security/code-contract audit of PR #108 at the exact live head. Do not mutate GitHub, Supabase, runtime or production in the audit step.
