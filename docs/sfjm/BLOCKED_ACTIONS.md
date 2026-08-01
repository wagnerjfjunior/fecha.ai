# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / PR108_DRAFT / PR02_NOT_DEPLOYED / PR03_BLOCKED`  
**Observed on:** `2026-07-31`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product and security blocks

Do not:

- declare MVP 1 — Família security-ready;
- grant Security Go or F1-02 acceptance;
- award WDP from PR count, documentation, CI or one smoke alone;
- authorize broad paid commercialization;
- represent controlled-beta risk acceptance as a security waiver.

## 2. Closed and superseded cycles

Without new material evidence and exact authority, do not:

- reopen PR #103 or PR #107;
- reopen the completed Group A reconciliation from PR #111;
- reopen the Builders continuity publication from PR #110;
- merge, update or reuse PR #109, which is `CLOSED / NOT MERGED / SUPERSEDED_BY_PR_108`;
- reapply or modify migration `20260727080929_f1_02_password_state_rpc`;
- alter or drop `public.marcar_senha_inicial_definida()`;
- repeat completed gates merely for additional unanimity;
- create a recursive PR solely to record the merge of a documentation-only closure PR.

## 3. PR #108 current anchors

```text
PR: #108 — security: route password completion through RPC
State: OPEN / DRAFT / NOT MERGED
Recorded base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
Current canonical main: a909679143ec2e9a53f0a3108e5240a91a138fc1
Live branch: security/f1-02-password-flow-cutover-1
Prior head before this reconciliation: bec8b2531486e76c546ddee1d3e2d8b419e220be
Current head: resolve live from PR metadata
```

The main drift consists of documentation-only closures from PR #111 and PR #110 and was classified as non-material to the unchanged PR-02 code contract. Do not rebase or rewrite the branch without a separate material reason and authorization.

## 4. PR #108 scope blocks

Blocked:

- any ninth changed file;
- any further `src/App.jsx` change without a new bounded finding and authority;
- any change to `docs/security/evidence/2026-07-28-pr02-password-flow-cutover.md` in this reconciliation;
- unrelated frontend refactor;
- change to Supabase, migration, RPC body, Auth, RLS, policy, grant, role or data;
- change to Edge Functions, Vercel configuration, GitHub Actions or external Builders;
- alteration of the preserved `EditarCorretorModal` administrative patch in this PR;
- claim that all direct `corretores` updates were removed;
- rebase, Ready, approval, merge, auto-merge or deployment without separate authority;
- production smoke without separate deployment and smoke authority.

## 5. PR-03 dependency block

```text
PR-03: BLOCKED
```

PR-03 may not begin until canonical evidence establishes at least:

1. PR #108 merged under separate authority;
2. the exact frontend build is deployed under separate authority;
3. the deployed mandatory-password flow uses the RPC;
4. controlled success and fail-closed behavior are proven;
5. repository-wide call-site search is refreshed at the deployment candidate;
6. no legitimate required password-state direct update would be broken by revocation;
7. the administrative direct patch has an explicit safe server-side disposition.

## 6. Runtime and data blocks

Do not alter real users, companies, teams, leads, clients, passwords, Auth records or commercial data. Production is not an exploratory test environment.

## 7. Evidence-overclaim blocks

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

A successful build and Preview are static/release signals, not production behavior proof. Canonical Builder documentation is not product/runtime/security evidence.

## 8. Removal rule

A block is removed only by exact canonical evidence identifying scope, authority, validator, residual risk, rollback or containment, expiration and next safe action.
