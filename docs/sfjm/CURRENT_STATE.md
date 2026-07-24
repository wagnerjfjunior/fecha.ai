# FECH.AI — SFJM Current State

**Lifecycle state:** `F1_01_MAP_MERGED / POST_PR94_RECONCILIATION_PENDING`  
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
Canonical main: 1caf90c60681771af6609b96ee840b190668fa0f
Commit: docs(m1): add F1-01 acceptance evidence map (#94)

PR #94: CLOSED / MERGED
PR #94 final head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
PR #94 squash commit: 1caf90c60681771af6609b96ee840b190668fa0f
PR #94 independent reaudit: PASS WITH RESIDUAL RISK
PR #94 review threads: 6 RESOLVED / 0 OPEN
```

PRs #95, #96 and #97 established and reconciled the SFJM continuity layer. PR #94 then merged the corrected F1-01 M1 acceptance evidence map into canonical `main`.

All SHA values are historical anchors after a newer commit lands. Live GitHub state must be resolved before any later decision.

## 4. F1-01 product-governance state

```text
F1-01 evidence map: MERGED INTO MAIN
Map completeness review: PASSED WITH RESIDUAL RISK
F1-01 checkpoint acceptance: NOT GRANTED
Accepted WDP: 0
Security Go: NOT GRANTED
```

The merged evidence map establishes the known M1 source paths and explicit evidence gaps. It does not prove runtime correctness, Supabase security, tenant isolation, MVP readiness or accepted product value.

## 5. Authorization state

The following authorities are `CONSUMED`:

- PR #94 bounded documentation correction;
- resolution of the six materially addressed review threads;
- PR #94 independent reaudit;
- PR #94 pre-merge verification;
- PR #94 squash merge with exact-head protection.

The current authorization is limited to a documentation-only post-PR #94 reconciliation branch and Draft PR. It does not authorize merge of that reconciliation PR or any F1-02 execution.

No standing authority exists for:

- runtime or frontend implementation;
- Supabase, migrations, RLS, grants, policies or RPC changes;
- Edge Functions, Vercel, GitHub Actions or production changes;
- Security Go;
- F1-01 acceptance;
- WDP assignment;
- changes in `wagnerjfjunior/sfjm-workspace`.

## 6. Current conclusions

```text
SFJM continuity layer: MERGED
F1-01 evidence map: MERGED
F1-01 map reaudit: PASS WITH RESIDUAL RISK
F1-01 checkpoint acceptance: NOT GRANTED
Security Go: NOT GRANTED
MVP Família readiness: NOT CONFIRMED
Runtime validation: NOT CONFIRMED
Current live Supabase security state: NOT CONFIRMED
WDP: 0 / NOT AWARDED
```

## 7. Evidence available

- PR #94 final head, diff, reviews and merge metadata;
- six resolved review threads with material corrections;
- corrected M1 used-path inventory;
- canonical FECH.AI bootstrap, B0, F1-01 and SFJM files;
- explicit non-claims and evidence gaps recorded in the merged map.

## 8. Evidence missing or requiring refresh

- current live Supabase grants, RLS policies and relevant RPC bodies;
- correct project/environment confirmation for the read-only security review;
- negative no-session, invalid-token, manipulated-ID and cross-tenant test design/results;
- persistent next-action/follow-up authority and storage path;
- weekend/scheduled-visit dashboard semantics and zero-versus-unknown behavior;
- deduplication, import audit, authenticated runtime smoke and rollback evidence.

## 9. Main risks

- treating the merged F1-01 map as F1-01 acceptance or Security Go;
- modifying Supabase while evidence collection is still incomplete;
- omitting direct `corretores` DML or direct Discador paths from F1-02;
- treating frontend token use as authorization proof;
- converting planned negative tests into claims of executed validation;
- reusing consumed authorization as standing authority.

## 10. What must not be altered without separate scope

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

## 11. Next safe action

See `docs/sfjm/NEXT_SAFE_ACTION.md`.
