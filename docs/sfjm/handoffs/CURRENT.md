# FECH.AI — SFJM Current Handoff

**Status:** CURRENT_HANDOFF / DOCUMENTATION_ONLY  
**Observed on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

Apply SFJM to FECH.AI as a transversal operational-continuity and state-control layer.

SFJM is not a CRM module, product feature or business/security authority.

## 2. Completed in this transition

- the conceptual boundary between SFJM, FECH.AI bootstrap and B0 governance was defined;
- canonical `main` was checked before branch creation;
- PR #94 was identified as the active F1-01 evidence artifact;
- the distinction between canonical `main` and PR #94 head was established;
- the SFJM documentation v1 scope was explicitly authorized;
- branch `docs/sfjm-fechai-operational-continuity-v1` was created from the confirmed `main`;
- the seven SFJM files were created and `docs/bootstrap/INDEX.md` was minimally updated;
- Draft PR #95 was opened without altering PR #94 or runtime;
- the original implementation authorization was consumed when PR #95 and its publication head were reported;
- an independent read-only audit of PR #95 at head `6ba8c487e6f251d48d54c365e11b2e851777a782` returned `FAIL` with exactly two `REQUIRED IN THIS PR` findings;
- the correction scope was restricted to `docs/sfjm/AUTHORIZATIONS.md` and this handoff.

## 3. Current GitHub anchors and lifecycle

```text
Repository: wagnerjfjunior/fecha.ai
Canonical main used as PR #95 base: e7584b6ce2a53a88fca9974bcc448ebe9aea83ab

SFJM pull request: #95
PR #95 title: docs(sfjm): add FECH.AI operational continuity layer v1
PR #95 state at last verification: OPEN / DRAFT / NOT_MERGED
PR #95 base: main
PR #95 base SHA: e7584b6ce2a53a88fca9974bcc448ebe9aea83ab
PR #95 head branch: docs/sfjm-fechai-operational-continuity-v1
PR #95 independently audited head: 6ba8c487e6f251d48d54c365e11b2e851777a782
First corrective commit: 914bbd2b688fd0bb5d00a22a0117a99fd5505b76

Active F1-01 pull request: #94
PR #94 observed head: 140e92dd12c72eae5f90fa55b5b125bbedf6fbaa
```

### Freshness warning

The PR #95 head cannot be treated as permanently current inside this file. Publishing this handoff creates a newer commit after the first corrective commit listed above.

Therefore, every receiving conversation or auditor must read the **live PR #95 head from GitHub** before acting. Any head different from the independently audited head invalidates the prior audit and requires exact-head re-audit.

The PR #94 head remains an observed target-specific evidence anchor only. It is not the SFJM base or the PR #95 head.

## 4. Authorization state

### Consumed

The authorization to:

- create the SFJM branch;
- write the eight-file documentation scope;
- commit it;
- open Draft PR #95;
- report its publication head;

is `CONSUMED` and no longer authorizes new branch creation, scope expansion, Ready-for-review transition, merge or implementation.

### Current correction authorization

Only the two audit findings may be corrected, in exactly:

```text
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/handoffs/CURRENT.md
```

This authorization expires when the new live PR #95 correction head is published and reported.

After that, only a separate read-only exact-head re-audit is the next permitted operation.

## 5. Active product-governance work

```text
F1-01 — Final M1 evidence and acceptance map
Artifact: PR #94
Operational state: EVIDENCE_INCOMPLETE
```

PR #94 was not modified, approved, marked Ready or merged by the SFJM PR flow.

## 6. PR #95 audit findings being closed

### Finding 1 — authorization lifecycle

The original authorization was incorrectly still labeled active after its expiration condition had occurred.

Correction applied:

- original authorization classified as `CONSUMED`;
- PR #95 and audited publication head recorded;
- correction authorization separately bounded and time-limited;
- re-audit identified as read-only and non-authorizing.

### Finding 2 — incomplete handoff anchors

The prior handoff omitted PR #95 number, state, base, head branch, audited head and consumed authorization state.

Correction applied in this file:

- PR #95 identity and state recorded;
- base and branch recorded;
- independently audited head recorded;
- correction sequence recorded;
- consumed and current limited authorization states separated;
- live-head verification made mandatory to avoid a false self-referential SHA claim.

## 7. Not completed

- exact-head independent re-audit of the corrected PR #95;
- authorization to mark PR #95 Ready for review;
- fresh state verification immediately before any Ready transition;
- authorization to merge PR #95;
- post-merge reconciliation of FECH.AI `main`;
- independent current-head audit of PR #94;
- F1-01 checkpoint acceptance;
- WDP decision through the authorized B0 process;
- Security Go;
- MVP Família readiness confirmation;
- current live Supabase security reconciliation;
- required negative tenant/company isolation tests;
- current authenticated runtime smoke validation;
- resolution of remaining M1 evidence gaps;
- registration of FECH.AI as an external project context in `wagnerjfjunior/sfjm-workspace`.

## 8. Risks retained

- source presence being mistaken for readiness;
- PR merge being mistaken for accepted delivery value;
- stale evidence being treated as current;
- frontend behavior being mistaken for backend authorization;
- a new conversation using memory instead of canonical evidence;
- SFJM being expanded into product runtime without a separate decision;
- Vercel preview readiness being mistaken for runtime, security or production validation;
- a historical head embedded in documentation being mistaken for the live PR head;
- FECH.AI being registered in SFJM Workspace before PR #95 is merged and reconciled.

## 9. What must not be redone

Do not reopen the decision to position SFJM as a CRM/product module unless new canonical product evidence and an explicit product decision require it.

Do not reconstruct FECH.AI from zero when the bootstrap, B0 and SFJM records are available.

Do not repeat broad repository discovery when the current index, active PR metadata, exact diff or named evidence can answer the question.

Do not restart the already consumed branch-creation authorization.

## 10. What must not be altered from this handoff

- any file outside the two-file correction scope before re-audit;
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
- PR #94 content, metadata, state or head;
- PR #95 Draft state before re-audit and separate authorization.

## 11. Single next safe action

Read the new live head of Draft PR #95 from GitHub and submit that exact head to an independent read-only re-audit limited to:

- confirming the two `REQUIRED IN THIS PR` findings are closed;
- confirming no scope broadening;
- reconfirming the complete eight-file PR boundary and non-claims.

Do not mark Ready for review as part of the re-audit.

## 12. Retirement rule

The prior conversation may be retired only after the receiving conversation:

1. reads the mandatory bootstrap, governance and SFJM records;
2. validates live GitHub state, including the current PR #95 head;
3. declares available and missing evidence;
4. confirms the consumed authorization and the current read-only re-audit boundary;
5. confirms the single next safe action;
6. does not silently broaden authorization.

## 13. Future SFJM Workspace registration

Registering FECH.AI in `wagnerjfjunior/sfjm-workspace` is a separate future task and separate PR.

It must not begin until:

1. PR #95 passes exact-head re-audit;
2. PR #95 is separately authorized for Ready and merge;
3. PR #95 is merged;
4. FECH.AI `main` is reconciled after merge;
5. the canonical SFJM file paths are confirmed in `main`.

The first SFJM Workspace task should define a read-only external-project context contract. It must not implement automatic synchronization, backend integration or verified operational claims in the same change.
