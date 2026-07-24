# FECH.AI — SFJM Current State

**Lifecycle state:** `SFJM_V1_MERGED / POST_MERGE_RECONCILIATION_IN_PROGRESS`  
**Record type:** OPERATIONAL_STATE / DOCUMENTATION_ONLY  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Context understood

FECH.AI is a Pilot Production multi-tenant / multi-company platform with real users, sensitive lead/client data, active modules and security hardening in progress.

SFJM is a transversal continuity and operational-state layer. It is not a CRM module, product runtime component, business authority or security boundary.

## 2. Active product phase

```text
MVP 1 — Família
```

The family pilot remains the controlled first validation phase before broader client or market exposure.

## 3. Canonical GitHub state

```text
Canonical main: 4293f383e1e93f0cfd4a63f793024eb239bfafbb
Commit: docs(sfjm): add FECH.AI operational continuity layer v1 (#95)
PR #95: MERGED
Merge method: SQUASH
Merged head: 611faa5d7275d8f40386c41b2687fb5ef6f7b5b6
```

PR #95 is no longer an active continuity artifact. Its eight documentation files are part of canonical `main`.

Any future decision must resolve live `main` rather than treating the SHA above as permanently current.

## 4. Active post-merge reconciliation artifact

```text
PR: #96
Title: docs(sfjm): reconcile state after PR 95 merge
State observed: OPEN / DRAFT / NOT_MERGED / MERGEABLE
Base branch: main
Base SHA observed: 4293f383e1e93f0cfd4a63f793024eb239bfafbb
Head branch: docs/sfjm-post-merge-reconciliation-95
```

PR #96 proposes the post-merge documentation reconciliation. Until PR #96 passes exact-head audit, receives separate Ready and merge authorizations, and is merged, this reconciliation is not canonical in `main`.

The exact live PR #96 head must be resolved from GitHub before every audit, Ready or merge decision.

## 5. Active product-governance artifact

```text
PR: #94
Title: docs(m1): add F1-01 acceptance evidence map
Last observed head: 140e92dd12c72eae5f90fa55b5b125bbedf6fbaa
Operational state: EVIDENCE_INCOMPLETE / REQUIRES LIVE REVALIDATION
```

PR #94 was not modified, approved or merged by the PR #95 continuity flow or by PR #96.

Its recorded head is target-specific evidence only. It is not canonical `main` and does not authorize unrelated work.

## 6. Authorization state

The following PR #95 authorities are `CONSUMED`:

- creation of the SFJM documentation branch and files;
- corrective commits made during PR #95 review;
- transition of PR #95 to Ready for review;
- resolution of the two outdated Codex threads;
- squash merge of PR #95 at the expected head.

The bounded write authority used to create and update Draft PR #96 is consumed by publication of the current reconciliation proposal. It does not remain as standing authority for additional discretionary commits.

The only current permitted operation recorded by this state is:

```text
EXACT-HEAD INDEPENDENT READ-ONLY AUDIT OF DRAFT PR #96
```

No standing authority exists for:

- new FECH.AI documentation commits outside a separately authorized correction;
- Ready or merge of PR #96;
- runtime or frontend implementation;
- Supabase, migrations, RLS, grants, policies or RPC changes;
- Vercel, GitHub Actions or production changes;
- modification or merge of PR #94;
- registration of FECH.AI in `sfjm-workspace`;
- Security Go, F1-01 acceptance or WDP assignment.

Any next write action requires a separate explicit authorization, exact repository/branch/file scope and simple rollback.

## 7. Current conclusions

```text
SFJM documentation v1: MERGED INTO MAIN THROUGH PR #95
Post-merge SFJM reconciliation: PROPOSED IN DRAFT PR #96 / NOT YET CANONICAL
PR #96 exact-head audit: REQUIRED
PR #96 Ready authorization: NOT GRANTED
PR #96 merge authorization: NOT GRANTED
Security Go: NOT GRANTED
MVP Família readiness: NOT CONFIRMED
F1-01 checkpoint acceptance: NOT CONFIRMED
Runtime validation: NOT CONFIRMED
Current live Supabase security state: NOT CONFIRMED
WDP: NOT AWARDED
```

Merge of PR #95 confirms only that the SFJM documentation layer entered `main`. It does not prove product readiness, security, tenant isolation, runtime correctness or accepted delivery value.

PR #96 does not become canonical merely because its branch or Draft PR exists.

## 8. Evidence available

- merged PR #95 metadata and squash commit;
- canonical SFJM files present in `main` through PR #95;
- the exact eight-file documentation boundary of PR #95;
- independent exact-head audits and final pre-merge verification of PR #95;
- resolved Codex threads from the PR #95 Ready review cycle;
- Draft PR #96 metadata and its four-file proposed reconciliation scope;
- FECH.AI bootstrap and B0 governance documents;
- PR #94 as the active F1-01 evidence artifact, subject to live revalidation.

## 9. Evidence missing or requiring refresh

- independent audit of the exact current PR #96 head;
- confirmation that no `BLOCKING` or `REQUIRED IN THIS PR` finding remains in PR #96;
- separate Ready authorization for PR #96;
- fresh pre-merge verification and separate merge authorization for PR #96;
- canonical `main` confirmation after any future PR #96 merge;
- independent current-head audit of PR #94;
- F1-01 checkpoint decision through the authorized B0 process;
- current live Supabase metadata, grants, policies and relevant RPC validation;
- required negative tenant/company isolation tests;
- current authenticated runtime smoke evidence;
- remaining M1 persistence, duplicate-detection, follow-up, dashboard and audit evidence;
- a separately authorized and versioned FECH.AI external-project context contract in `wagnerjfjunior/sfjm-workspace`.

## 10. Main risks

- mistaking merged PR #95 documentation for product readiness;
- mistaking the Draft PR #96 proposal for canonical reconciled state;
- skipping PR #96 audit and prematurely starting work in `sfjm-workspace`;
- treating stale PR #94 evidence as current;
- treating Vercel preview success as runtime, security or production validation;
- using consumed authorization as standing authority;
- reopening completed PR #95 decisions without new canonical evidence.

## 11. What must not be altered without separate scope

- runtime;
- frontend;
- Supabase;
- migrations;
- RLS;
- grants;
- policies;
- RPC bodies;
- Edge Functions;
- Vercel configuration;
- GitHub Actions;
- MesaCliente;
- PME;
- ADS/CAPI;
- Make/n8n;
- integrations;
- production;
- PR #94 content, metadata, state or head;
- `wagnerjfjunior/sfjm-workspace`.

## 12. Next safe action

See `docs/sfjm/NEXT_SAFE_ACTION.md`.