# FECH.AI — SFJM Current Handoff

**Status:** CURRENT_HANDOFF / DOCUMENTATION_ONLY  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

Apply SFJM to FECH.AI as a transversal operational-continuity and state-control layer.

SFJM is not a CRM module, product feature or business/security authority.

## 2. Completed in this transition

- the conceptual boundary between SFJM, FECH.AI bootstrap and B0 governance was defined;
- the current GitHub `main` was checked;
- PR #94 was identified as the active F1-01 evidence artifact;
- the distinction between canonical `main` and PR #94 head was established;
- the SFJM documentation v1 scope was authorized;
- a separate branch from canonical `main` was selected;
- runtime and PR #94 were explicitly excluded from the SFJM change.

## 3. Current canonical anchors observed

```text
Repository: wagnerjfjunior/fecha.ai
Canonical main: e7584b6ce2a53a88fca9974bcc448ebe9aea83ab
Active F1-01 PR: #94
PR #94 head: 140e92dd12c72eae5f90fa55b5b125bbedf6fbaa
SFJM branch: docs/sfjm-fechai-operational-continuity-v1
```

The PR #94 head is not the SFJM base. It remains an observed target-specific evidence anchor only.

## 4. Active work

```text
F1-01 — Final M1 evidence and acceptance map
Artifact: PR #94
Operational state: EVIDENCE_INCOMPLETE
```

## 5. Not completed

- independent current-head audit of PR #94;
- F1-01 checkpoint acceptance;
- WDP decision through the authorized B0 process;
- Security Go;
- MVP Família readiness confirmation;
- current live Supabase security reconciliation;
- required negative tenant/company isolation tests;
- current authenticated runtime smoke validation;
- resolution of remaining M1 evidence gaps.

## 6. Risks retained

- source presence being mistaken for readiness;
- PR merge being mistaken for accepted delivery value;
- stale evidence being treated as current;
- frontend behavior being mistaken for backend authorization;
- a new conversation using memory instead of canonical evidence;
- SFJM being expanded into product runtime without a separate decision;
- PR #94 being modified or merged without a current-head independent audit.

## 7. What must not be redone

Do not reopen the decision to position SFJM as a CRM/product module unless new canonical product evidence and an explicit product decision require it.

Do not reconstruct the FECH.AI project from zero when the bootstrap, B0 and SFJM records are available.

Do not repeat broad repository discovery when the current index, active PR metadata, exact diff or named evidence can answer the question.

## 8. What must not be altered from this handoff

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
- PR #94 content, metadata, state or head.

## 9. Next safe action

Perform a read-only independent audit of PR #94 against its exact current head and current canonical `main`.

See `docs/sfjm/NEXT_SAFE_ACTION.md` for the completion contract.

## 10. Retirement rule

The prior conversation may be retired only after the receiving conversation:

1. reads the mandatory bootstrap, governance and SFJM records;
2. validates current GitHub state;
3. declares evidence available and missing;
4. confirms the next safe action;
5. does not silently broaden the authorization.