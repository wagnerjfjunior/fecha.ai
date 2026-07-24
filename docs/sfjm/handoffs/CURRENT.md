# FECH.AI — SFJM Current Handoff

**Status:** CURRENT_HANDOFF / PR_94_MERGED / F1_02_PLANNED  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

SFJM remains the FECH.AI transversal operational-continuity and state-control layer. It is not a CRM feature, business authority or security boundary.

The F1-01 evidence map is now merged into canonical `main`. Its merge closes the map-correction cycle but does not accept F1-01, grant Security Go, validate runtime/Supabase or award WDP.

## 2. Completed cycles

- PR #95 created the FECH.AI SFJM documentation layer;
- PR #96 reconciled the post-PR #95 state;
- PR #97 closed that continuity cycle;
- PR #94 created and corrected the F1-01 M1 acceptance evidence map;
- six review findings on PR #94 were materially corrected and resolved;
- PR #94 passed independent reaudit with `PASS WITH RESIDUAL RISK`;
- PR #94 passed exact-head pre-merge verification;
- PR #94 was squash-merged with head protection;
- resulting `main` tip was confirmed.

## 3. Canonical anchors

```text
Repository: wagnerjfjunior/fecha.ai
Canonical main after PR #94: 1caf90c60681771af6609b96ee840b190668fa0f

PR #94: CLOSED / MERGED
PR #94 final head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
PR #94 squash commit: 1caf90c60681771af6609b96ee840b190668fa0f
PR #94 reaudit: PASS WITH RESIDUAL RISK
PR #94 threads: 6 RESOLVED / 0 OPEN
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

F1-02 is selected but not yet authorized for execution. A separate authorization must identify the exact Supabase project/environment and preserve read-only scope.

The first phase must map current grants, RLS policies, RPC bodies/signatures and direct `corretores` DML exposure for all M1 paths recorded by F1-01. It must also design, but not silently execute against production, the negative-test matrix.

## 6. Authorization state

Consumed:

- PR #95, #96, #97 continuity actions;
- PR #94 correction, thread resolution, reaudit, pre-merge verification and squash merge.

Active only for the current documentation reconciliation:

- branch `agent/reconcile-f1-01-post-pr94`;
- six authorized documentation files;
- creation of a Draft PR;
- no merge.

Not authorized:

- F1-02 Supabase access;
- negative-test execution;
- runtime/frontend changes;
- migrations, RLS, grants, policies or RPC changes;
- Vercel, GitHub Actions or production changes;
- Security Go;
- F1-01 acceptance;
- WDP assignment;
- changes in `wagnerjfjunior/sfjm-workspace`.

## 7. Evidence available

- merged PR #94 metadata and exact final head;
- independent reaudit result;
- six resolved review threads;
- corrected current M1 used-path inventory;
- merged non-claims and explicit evidence gaps;
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

- mistaking the F1-01 map merge for product acceptance;
- beginning F1-02 without exact project/environment provenance;
- mutating Supabase during an evidence-only phase;
- omitting direct Discador or direct `corretores` paths;
- treating frontend containment as backend authorization;
- presenting designed tests as executed tests;
- reusing consumed authorization.

## 10. What must not be redone

- do not reconstruct FECH.AI from zero;
- do not reopen PR #94 correction findings without new evidence;
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

After this reconciliation PR is independently validated and separately merged, request a narrowly scoped `ACTIVE_READ_ONLY` authorization for F1-02 with:

- exact canonical FECH.AI commit;
- exact Supabase project/environment;
- allowed read-only metadata and definitions;
- prohibited mutations;
- evidence sanitization rules;
- negative-test design scope;
- acceptance criteria;
- expiration condition.

Until then, do not access or alter Supabase.

## 13. Retirement rule

The PR #94 correction/audit/merge conversation may be retired after a receiving conversation:

1. reads the bootstrap, B0 and SFJM indexes;
2. confirms PR #94 is merged at `1caf90c60681771af6609b96ee840b190668fa0f` or later;
3. confirms F1-01 remains unaccepted, WDP remains zero and Security Go remains ungranted;
4. treats F1-02 as planned but not authorized;
5. preserves all fail-closed boundaries;
6. does not infer runtime or Supabase authority.
