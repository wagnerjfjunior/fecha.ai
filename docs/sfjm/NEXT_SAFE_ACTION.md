# FECH.AI — SFJM Next Safe Action

**Status:** `NEXT_SAFE_ACTION / PR02_SCOPE_RECONSTRUCTION_READ_ONLY`  
**Observed on:** `2026-07-29`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Completed material steps

```text
PR #103 narrow password-state RPC: MERGED
Migration 20260727080929: documented as APPLIED
Authenticated positive smoke: PASS
Immediate repeated-call idempotency: PASS
Synthetic fixture cleanup: COMPLETE
PR #107 evidence/SFJM documentation: CLOSED / MERGED
Canonical main after PR #107: cec1b22430adf1a002b172992cf6c5ea5bb427de
```

The merge of PR #107 closes the evidence-documentation workstream. It does not authorize the next technical PR.

## 2. Exact next safe action

Run one GPT1 architectural scope reconstruction, strictly `READ_ONLY`, for F1-02 PR-02 against the current live `main`.

Canonical PR-02 contract:

```text
Branch target: security/f1-02-password-flow-cutover
Title target: security: route password completion through RPC
Primary objective: replace the confirmed direct PATCH corretores password-completion path with public.marcar_senha_inicial_definida()
```

The reconstruction must not implement or publish anything.

## 3. Required reconstruction output

The GPT1 output must identify:

1. current live `main` and exact files consulted;
2. the exact direct password-state write call site;
3. the current frontend flow and dependencies around success/error state;
4. the narrow RPC invocation contract;
5. the smallest permitted file set;
6. areas explicitly prohibited from change;
7. multi-tenant and security implications;
8. build and repository-wide call-site search requirements;
9. success, fail-closed, preview, production-smoke and evidence criteria;
10. rollback and containment;
11. the specialists required for later independent validation;
12. a bounded implementation task envelope for Codex, without executing it.

## 4. Required safeguards

The proposal must preserve:

- no unrelated frontend refactor;
- no Supabase, migration, RPC-body, RLS, policy or grant change;
- no false-success UI when the RPC fails or is unavailable;
- no token, credential or sensitive payload logging;
- one PR = one primary risk = one simple rollback;
- PR-03 remains blocked until PR-02 is deployed and proven.

## 5. Sequence after the read-only proposal

```text
1. GPT1 produces the bounded PR-02 proposal.
2. Product Authority separately authorizes or rejects implementation.
3. If authorized, Codex implements only the permitted files.
4. Independent specialists validate their exact gates.
5. GPT4 validates lifecycle, checks, preview and rollback.
6. Ready, merge, deploy and production smoke each require their applicable authority.
```

No step automatically authorizes the next step.

## 6. Current non-actions

```text
No branch creation
No commit
No pull request
No frontend or runtime change
No Supabase or SQL operation
No migration, RPC-body, Auth, RLS, policy or grant change
No Vercel or production mutation
No PR-03
No Security Go
No F1-02 acceptance
No WDP change
```

## 7. Anti-loop

Do not reopen PR #107 or repeat its completed smoke merely to obtain additional unanimity.

Do not create a recursive closure PR solely to record the future squash SHA of this documentation reconciliation. The next substantive state change belongs to the PR-02 planning/authorization cycle.