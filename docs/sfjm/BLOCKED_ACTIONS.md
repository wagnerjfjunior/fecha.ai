# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / PR108_DRAFT / PR02_NOT_DEPLOYED / PR03_BLOCKED`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product blocks

Do not:

- declare MVP 1 — Família security-ready;
- grant Security Go or F1-02 acceptance;
- award WDP from PR count, documentation, CI or one smoke alone;
- authorize broad paid commercialization;
- represent controlled-beta risk acceptance as a security waiver.

## 2. Closed-cycle blocks

Without new material evidence and exact authority, do not:

- reopen PR #103 or PR #107 lifecycle;
- reapply or modify migration `20260727080929_f1_02_password_state_rpc`;
- alter or drop `public.marcar_senha_inicial_definida()`;
- repeat the completed PR-01 smoke merely for additional unanimity;
- create a recursive PR solely to record PR #107 or PR #108 lifecycle state.

## 3. PR #108 current blocks

```text
PR: #108
State: OPEN / DRAFT / NOT MERGED
Base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
Live branch: security/f1-02-password-flow-cutover-1
Initial implementation commit: c458461e810e24adb7d71f7d155be06e9cf54eac
```

Blocked:

- any ninth changed file;
- unrelated `src/App.jsx` refactor;
- change to Supabase, migration, RPC body, Auth, RLS, policy, grant or data;
- change to Edge Functions, Vercel configuration or GitHub Actions;
- alteration of the preserved `EditarCorretorModal` administrative patch in this PR;
- claim that all direct `corretores` updates were removed;
- Ready, approval, merge, auto-merge or deployment without separate authority;
- production smoke without separate deployment and smoke authority.

## 4. PR-03 dependency block

```text
PR-03: BLOCKED
```

PR-03 may not begin until canonical evidence establishes at least:

1. PR #108 merged under separate authority;
2. deployed frontend uses the RPC in the intended mandatory-password flow;
3. controlled success and fail-closed behavior are proven;
4. repository-wide call-site search is refreshed at the deployed head;
5. no legitimate required password-state direct update would be broken by revocation;
6. the administrative direct patch has an explicit safe disposition.

## 5. Runtime and data blocks

Do not alter real users, companies, teams, leads, clients, passwords, Auth records or commercial data. Production is not an exploratory test environment.

## 6. Evidence-overclaim blocks

PR #108 does not establish:

- interactive UI success;
- RPC-unavailable runtime behavior;
- deployed frontend proof;
- production cutover;
- denial of legacy direct UPDATE;
- resolution of the administrative password-reset path;
- F1-02 completion;
- Security Go;
- WDP.

A successful build and Preview are static/release signals, not production behavior proof.

## 7. Removal rule

A block is removed only by exact canonical evidence identifying scope, authority, validator, residual risk, rollback or containment, expiration and next safe action.
