# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / PR107_READY / PM107_CORRECTION_PENDING_AUDIT / PR02_BLOCKED_PENDING_CLOSURE`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product blocks

- declare MVP 1 — Família security-ready;
- grant Security Go or F1-02 acceptance;
- award WDP from PR count, documentation or one smoke alone;
- broad paid commercialization;
- represent controlled-beta risk acceptance as a security waiver.

## 2. Closed-cycle blocks

Without new material evidence and explicit authority, do not:

- reopen PR #103 Ready, merge or migration-application lifecycle;
- reapply migration `20260727080929_f1_02_password_state_rpc`;
- alter or drop `public.marcar_senha_inicial_definida()`;
- repeat the completed positive smoke merely for additional unanimity;
- reopen PR #104, #105 or #106 lifecycle;
- create a recursive PR solely to record PR #107's future squash SHA.

## 3. PR #107 current blocks

```text
PR: #107
Branch: docs/pr103-authenticated-smoke-evidence
State: OPEN / READY FOR REVIEW
Original audited head: 51105692b0957454bd3d83f70e6591472fcf10dc
Pre-merge result: FAIL — PM-107-GATE-01
```

Block:

- any eighth changed file;
- any change outside the six authorized SFJM files;
- runtime, frontend, SQL, migration, RPC-body, Auth, RLS, policy, grant, Edge, Vercel or production change;
- any commit after the single PM-107-GATE-01 corrective commit;
- any new comment or review;
- metadata change or Draft conversion;
- merge until the corrective head passes the bounded validation sequence;
- representing branch content as canonical `main`.

The previously executed Ready transition is not blocked or reverted.

## 4. Required corrective validation sequence

```text
1. GPT0 delta-only audit of the six-file correction.
2. If PASS, GPT4 lifecycle/scope validation on the same head.
3. If PASS, pre-merge READ_ONLY validation.
4. Separate Product Authority for squash merge.
```

No step authorizes the next step automatically.

## 5. Program dependency blocks

```text
PR-02: implementation and PR creation blocked until PR #107 is closed
       and the resulting canonical main is confirmed
PR-03: blocked until PR-02 is deployed and proven
PR-04 through PR-09: do not advance out of canonical order
```

## 6. Runtime and data blocks

Without a new exact authority, do not alter:

- runtime or frontend;
- Supabase schema, data, Auth, RLS, policies, grants or RPC bodies;
- Edge Functions, Vercel, GitHub Actions or GPT Actions;
- real users, companies, teams, leads, clients or commercial data;
- MesaCliente, PME, LeadOps, B0, WDP or Security Go.

Do not execute concurrency, missing-profile, inactive-profile, rollback or reapply tests in production.

## 7. Evidence-overclaim blocks

Do not claim that the completed smoke establishes:

- controlled concurrency;
- missing-profile denial;
- inactive-profile denial;
- rollback;
- reapply;
- frontend cutover;
- deployed frontend proof;
- denial of legacy direct `corretores` update;
- F1-02 completion;
- Security Go.

## 8. Procedural deviation

The accidental `noop` issue comment is accepted as non-material. It does not authorize any further comment and does not alter the branch, diff, head, mergeability or evidence boundary.

## 9. Removal rule

A block is removed only by exact canonical evidence identifying scope, authority, validator, residual risk, rollback or containment, expiration and next safe action.
