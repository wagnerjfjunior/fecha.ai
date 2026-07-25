# FECH.AI — SFJM Current Handoff

**Status:** `CURRENT_HANDOFF / CONTROLLED_BETA_PRIMARY_STRATEGY_IN_DRAFT`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

PR #101 merged the canonical F1-02 findings and remediation program.

Wagner then made a material product-risk decision:

- MVP 1 — Família remains a free, informed controlled beta;
- downtime, maintenance and possible beta data loss are accepted operating risks;
- there is no paid SLA;
- the primary Supabase project may be used for future bounded remediation windows;
- an isolated Supabase Branch is no longer a mandatory prerequisite for every technical step.

This decision does not accept privilege escalation, cross-tenant access, sensitive-data disclosure or destructive testing against real records.

```text
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
Broad paid commercialization: BLOCKED
WDP: 0
```

## 2. Canonical anchors

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
```

Canonical F1-02 baseline:

```text
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

## 3. Active strategy branch

```text
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Title: docs(security): adopt controlled beta primary remediation strategy
Type: documentation-only Draft PR
Primary risk: environment/remediation strategy
Rollback: one revert
```

New strategy artifact:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
```

The document supersedes only the mandatory isolated-lab prerequisite. It preserves all substantive security, rollback, evidence and approval controls.

## 4. Environment classification

```text
Supabase project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Classification: CONTROLLED BETA PRIMARY
Commercial production: NO
Paid SLA: NO
Real users: YES
Real multi-company data: YES
Sensitive data: YES
```

The primary project is a live beta environment, not an unrestricted laboratory.

## 5. Accepted and unaccepted risk

### Accepted for informed beta participants

- downtime and maintenance;
- temporary feature unavailability;
- manual support/recovery;
- possible loss of beta data;
- no paid SLA.

### Not accepted

- unauthorized admin/global authority;
- company A reading/modifying company B;
- disclosure of leads, contact data, tokens or credentials;
- forged real CRM history;
- offensive/destructive tests against real users or records;
- unbounded migrations;
- broad commercialization before Security Go.

## 6. Confirmed blockers still open

1. broker self privilege escalation through `corretores`;
2. direct structural writes on `leads` and `lotes`;
3. forgeable direct insertion into `funil_movimentacoes`;
4. incomplete same-company validation for list ACL targets;
5. tenant-safe funnel stages, import-session idempotency, feedback validation, `times` disposition and Auth control evidence.

The strategy amendment does not remediate any blocker.

## 7. Future primary-environment rule

Every future primary-environment operation requires two separate authorities:

```text
1. WINDOW_IMPLEMENTATION
   exact GitHub branch/files/change/tests/rollback

2. CONTROLLED_BETA_PRIMARY_CHANGE
   exact Supabase project/operation/preflight/smoke/rollback/expiration
```

A merged technical PR alone does not authorize applying SQL or configuration.

## 8. Test rule

Only synthetic, clearly identified fixtures may be used for security validation.

Required before testing:

- two synthetic companies and actors;
- exact manifest;
- no real identifiers or payloads;
- pre/post counts;
- deterministic cleanup or deactivation;
- stop conditions;
- separate authorization.

Never test cross-tenant access or privilege escalation with real accounts/data.

## 9. Current authority and prohibitions

Authorized now:

- exact documentation branch;
- seven documentation files;
- one Draft PR.

Not authorized now:

- Ready or merge of the strategy PR;
- PR-01 implementation;
- runtime/frontend change;
- migrations/SQL/RLS/grants/policies/RPCs/Auth;
- Supabase access or mutation;
- synthetic fixture creation;
- negative tests;
- Security Go, F1-02 acceptance or WDP.

## 10. Evidence available

- canonical PR #101 lifecycle and commit;
- canonical live read-only F1-02 findings;
- canonical remediation master plan;
- explicit user beta-risk decision;
- exact strategy amendment contract;
- exact branch/base/files authorization.

## 11. Evidence missing

- final strategy-PR head/diff audit;
- strategy Ready/merge lifecycle;
- exact PR-01 scope;
- current Supabase preflight for affected objects;
- synthetic fixture manifest;
- executed migration/rollback/smoke evidence;
- final F1-02 Security Go gate.

## 12. What must not be redone

- do not reopen PR #101 without new evidence;
- do not repeat broad read-only discovery unless an invalidating change requires a narrow refresh;
- do not create an isolated Supabase Branch merely because the old plan required it;
- do not interpret beta consent as a security waiver;
- do not open a reconciliation PR after every technical merge;
- do not treat PR count as product progress.

## 13. Single next safe action

Complete the documentation-only Draft PR, validate exact head/files/diff and send it to independent GPT0/GPT1/GPT3 audit.

After that PR is merged under separate authority, define PR-01 as one bounded risk. Do not touch Supabase or runtime before both implementation and primary-environment authorities exist.

## 14. New-conversation startup

A receiving conversation must:

1. read bootstrap, governance and SFJM indexes;
2. validate live `main` and active strategy PR/head;
3. read the strategy amendment and canonical F1-02 baseline;
4. preserve Security Go denied and WDP 0;
5. distinguish accepted availability risk from unaccepted security risk;
6. require exact authority for every GitHub and Supabase transition;
7. stop fail-closed when evidence is missing.