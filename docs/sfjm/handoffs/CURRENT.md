# FECH.AI — SFJM Current Handoff

**Status:** CURRENT_HANDOFF / PR_98_MERGED / F1_02_PLANNED  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

SFJM remains the FECH.AI transversal operational-continuity and state-control layer. It is not a CRM feature, business authority or security boundary.

The F1-01 evidence map is merged into canonical `main`. PR #98 reconciled the post-PR #94 documentation state. Neither merge accepts F1-01, grants Security Go, validates runtime/Supabase or awards WDP.

## 2. Completed cycles

- PR #95 created the FECH.AI SFJM documentation layer;
- PR #96 reconciled the post-PR #95 state;
- PR #97 closed that continuity cycle;
- PR #94 created and corrected the F1-01 M1 acceptance evidence map;
- six PR #94 review findings were corrected and resolved;
- PR #94 passed independent reaudit and was squash-merged;
- PR #98 reconciled the post-PR #94 state;
- PR #98 passed audit and pre-merge verification with `PASS WITH RESIDUAL RISK`;
- PR #98 was squash-merged with exact-head protection;
- resulting `main` tip was confirmed.

## 3. Canonical anchors

```text
Repository: wagnerjfjunior/fecha.ai
Canonical main after PR #98: 8a2eb00a9dcd46d7ee346741ca27c6081af52124

PR #98: CLOSED / MERGED
PR #98 final head: e7e52ed9762ab92fd14f82e2437845421693ec81
PR #98 squash commit: 8a2eb00a9dcd46d7ee346741ca27c6081af52124
PR #98 audit: PASS WITH RESIDUAL RISK
PR #98 pre-merge verification: PASS WITH RESIDUAL RISK
PR #98 threads: 0 OPEN
```

These are historical anchors after a newer commit lands. Resolve live GitHub state before any later decision.

## 4. Product-governance state

```text
MVP phase: MVP 1 — Família
F1-01 evidence map: MERGED
F1-01 checkpoint acceptance: NOT GRANTED
Security Go: NOT GRANTED
Accepted WDP: 0
Runtime validation: NOT CONFIRMED
Supabase live security state: NOT CONFIRMED
```

## 5. Selected next workstream

```text
F1-02 — read-only Supabase security evidence refresh and negative-test design
```

F1-02 is selected but remains `PLANNED / NOT_AUTHORIZED`. A separate authorization must identify the exact Supabase project/environment and preserve read-only scope.

The first phase must map current grants, RLS policies, RPC bodies/signatures and direct `corretores` DML exposure for all M1 paths recorded by F1-01. It must design, but not silently execute against production, the negative-test matrix.

## 6. Authorization state

Consumed:

- PR #95, #96 and #97 continuity actions;
- PR #94 correction, thread resolution, reaudit, pre-merge verification and squash merge;
- PR #98 creation, bounded corrections, Ready transition, pre-merge verification and squash merge;
- post-PR #98 documentation reconciliation branch and Draft PR creation authority.

The Draft PR containing this handoff consumes the post-PR #98 reconciliation authority at creation. No subsequent commit, Ready transition or merge is authorized by this record.

```text
PR #98 lifecycle authority: CONSUMED
POST-PR #98 DRAFT CREATION AUTHORITY: CONSUMED AT DRAFT CREATION
NO ACTIVE WRITE AUTHORIZATION
NO ACTIVE F1-02 AUTHORIZATION
NO AUTHORITY FOR RUNTIME OR SUPABASE
NO AUTHORITY FOR READY OR MERGE OF THE NEW RECONCILIATION PR
F1-02: PLANNED / NOT_AUTHORIZED
```

## 7. Evidence available

- merged PR #94 metadata and exact final head;
- independent PR #94 reaudit result;
- six resolved PR #94 review threads;
- corrected current M1 used-path inventory;
- merged PR #98 metadata and exact final head;
- PR #98 audit and pre-merge verification;
- canonical bootstrap, B0 and SFJM records.

## 8. Evidence absent or requiring refresh

- exact live Supabase project/environment confirmation;
- current grants and RLS policies for affected tables/functions;
- current used RPC bodies/signatures and server-side tenant derivation;
- current direct `corretores` DML protections;
- negative no-session, invalid-token, manipulated-ID and cross-tenant evidence;
- persistent next-action/follow-up path;
- weekend dashboard semantics;
- deduplication, import audit, runtime smoke and rollback evidence.

## 9. Risks retained

- mistaking the F1-01 map or PR #98 merge for product acceptance;
- beginning F1-02 without exact project/environment provenance;
- mutating Supabase during an evidence-only phase;
- omitting direct Discador or direct `corretores` paths;
- treating frontend containment as backend authorization;
- presenting designed tests as executed tests;
- reusing consumed authorization.

## 10. What must not be redone

- do not reconstruct FECH.AI from zero;
- do not reopen PR #94 findings without new evidence;
- do not reclassify the map as Security Go or F1-01 acceptance;
- do not silently move `próxima ação` out of MVP1;
- do not omit paths already made explicit by the corrected map;
- do not begin automatic synchronization with SFJM Workspace.

## 11. What must not be altered without separate authorization

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
- `wagnerjfjunior/sfjm-workspace`.

## 12. Single next safe action

Obtain a separate read-only audit authorization for the exact head of the new post-PR #98 reconciliation Draft PR. A PASS does not authorize Ready or merge.

After that PR is independently validated and separately merged, request a narrowly scoped `ACTIVE_READ_ONLY` authorization for F1-02 with:

- exact canonical FECH.AI commit;
- exact Supabase project/environment;
- allowed read-only metadata and definitions;
- prohibited mutations;
- evidence sanitization rules;
- negative-test design scope;
- acceptance criteria;
- expiration condition.

Until then, do not access or alter Supabase.

## 13. New-conversation startup

A receiving conversation must:

1. read `docs/bootstrap/INDEX.md`;
2. read `docs/governance/INDEX.md`;
3. read `docs/sfjm/INDEX.md` and this handoff;
4. confirm live `main`, the post-PR #98 reconciliation PR, branch and head;
5. preserve F1-01 as unaccepted, WDP at zero and Security Go ungranted;
6. treat F1-02 as planned but not authorized;
7. avoid runtime or Supabase action without separate explicit authority.