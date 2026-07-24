# FECH.AI — SFJM Current State

**Lifecycle state:** `EVIDENCE_INCOMPLETE`  
**Record type:** OPERATIONAL_STATE / DOCUMENTATION_ONLY  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Context understood

FECH.AI is a Pilot Production multi-tenant / multi-company platform with real users, sensitive lead/client data, active modules and security hardening in progress.

SFJM is applied as a transversal continuity and operational-state layer. It is not a CRM module or product runtime component.

## 2. Active product phase

```text
MVP 1 — Família
```

The family pilot remains the controlled first validation phase before broader client or market exposure.

## 3. Active governance activity

```text
F1-01 — Final M1 evidence and acceptance map
```

## 4. Active artifact observed

```text
PR: #94
Title: docs(m1): add F1-01 acceptance evidence map
State observed: OPEN / NOT DRAFT / NOT MERGED / MERGEABLE
Base branch: main
Base SHA observed: e7584b6ce2a53a88fca9974bcc448ebe9aea83ab
Head branch: docs/f1-01-m1-evidence-map-20260705
Head SHA observed: 140e92dd12c72eae5f90fa55b5b125bbedf6fbaa
```

The head SHA above belongs to PR #94. It is not the canonical `main` commit and must not be used as the base of unrelated SFJM work.

## 5. Canonical main observed

```text
e7584b6ce2a53a88fca9974bcc448ebe9aea83ab
```

Commit message observed:

```text
revert: remove accidental F1-01 placeholder from main
```

This state confirms that the incomplete placeholder was removed from canonical `main`.

## 6. Current authorization

Authorized at this state:

- GitHub read and versioned-document inspection;
- documentary SFJM implementation in a separate branch and Draft PR;
- independent audit of PR #94;
- evidence freshness classification;
- documentation-only handoff updates through reviewed PRs.

Not authorized by this record:

- runtime implementation;
- frontend changes;
- Supabase changes;
- migrations, RLS, grants, policies or RPC body changes;
- Edge Functions or Vercel changes;
- GitHub Actions changes;
- MesaCliente, PME, ADS/CAPI, Make/n8n or integration changes;
- production changes;
- merge of PR #94;
- Security Go declaration;
- WDP acceptance.

## 7. Current conclusions

```text
Security Go: NOT GRANTED
MVP Família readiness: NOT CONFIRMED
F1-01 checkpoint acceptance: NOT CONFIRMED
Runtime validation: NOT CONFIRMED
Current live Supabase security state: NOT CONFIRMED
```

No WDP may be inferred from the existence, review or merge of PR #94 or from the SFJM documentation layer alone.

## 8. Evidence available

- current GitHub repository metadata;
- canonical `main` commit observed above;
- PR #94 metadata and current head observed above;
- versioned FECH.AI bootstrap and B0 governance documents;
- versioned source and historical evidence referenced by PR #94.

## 9. Evidence missing or requiring refresh

- independent audit decision for PR #94 at its current head;
- current live Supabase metadata, grants, policies and relevant RPC body validation;
- negative tenant/company isolation tests for used M1 paths;
- current authenticated runtime smoke evidence;
- confirmed import persistence and duplicate-detection path;
- confirmed persistent next-action/follow-up path;
- confirmed persisted weekend-dashboard data path;
- current import/error audit evidence;
- current rollback validation for applicable runtime/deployment flows.

## 10. Main risks

- confusing source presence with product readiness;
- treating PR creation or merge as accepted delivery value;
- using stale live evidence as current authorization proof;
- treating frontend token use as backend authorization proof;
- mixing SFJM continuity work with LeadOps, MesaCliente or runtime implementation;
- using PR #94 head as the base for unrelated work;
- carrying an obsolete handoff into a new conversation without live reconciliation.

## 11. What must not change in the current SFJM PR

- runtime;
- frontend;
- Supabase;
- migrations;
- RLS;
- grants;
- policies;
- RPC bodies;
- Edge Functions;
- Vercel;
- GitHub Actions;
- MesaCliente;
- PME;
- ADS/CAPI;
- Make/n8n;
- integrations;
- production;
- PR #94 content, metadata or state.

## 12. Next safe action

See `docs/sfjm/NEXT_SAFE_ACTION.md`.