# FECH.AI — SFJM Current Handoff

**Status:** `CURRENT_HANDOFF / PR_102_CORRECTED_DRAFT / REAUDIT_REQUIRED`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

The product authority chose a Controlled Beta Primary strategy for MVP 1 — Família.

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Paid SLA: NO
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Availability and possible beta-data-loss risk are accepted. Privilege escalation, cross-tenant exposure, privacy failure and destructive testing are not accepted.

## 2. Canonical anchors

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
```

Canonical baseline:

```text
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

## 3. Active PR #102

```text
PR: #102
State: OPEN / DRAFT
Base: affbae1a598928010b0fa7db967734de522c13b4
Branch: docs/f1-02-controlled-beta-primary-strategy
Pre-correction head: fc83ed752217bfc39810dfba38e93405bc7382b8
Final corrective head: live GitHub PR metadata and updated description
Changed files after correction: 8 documentation files
Canonical status: NOT_YET_CANONICAL
```

The final head is not embedded in the same commit because that would create a recursive hash change. GitHub metadata is authoritative.

## 4. Corrected strategy

- isolated environment is no longer universally mandatory;
- primary project may receive future bounded remediation under separate authority;
- primary remains live Pilot Production, not a sandbox;
- validation is classified as safe-live, isolated, deferred or prohibited;
- B1 actual self-promotion to `admin_global` is prohibited on primary and remains not verified without isolation;
- intentional named administrator assignment is a separate governance operation, not a test;
- fixtures must form a wholly synthetic graph with no real links;
- fixture cleanup is not migration rollback;
- implementation, PR lifecycle and live application use separate authorities.

## 5. Confirmed security blockers

1. broker self privilege escalation;
2. direct writes on leads/lotes and times disposition;
3. forgeable funnel history;
4. incomplete list ACL tenant validation;
5. funnel-stage, import, feedback and Auth evidence gaps.

No blocker is remediated by this documentation PR.

## 6. Audit history

At pre-correction head `fc83ed...`, authenticated GPT0/GPT1/GPT3 audits returned `FAIL` and required the current corrections.

The Project-session `TOOL STALE STATE` was a connector limitation only.

The final corrective head has not yet been approved and must be independently re-audited.

## 7. Current authority

```text
Draft creation: CONSUMED
Single correction: CONSUMED
Additional commits: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase: NOT AUTHORIZED
Fixtures/tests: NOT AUTHORIZED
Admin role assignment: NOT AUTHORIZED
Security Go: DENIED
```

## 8. Evidence available

- PR #101 lifecycle and canonical baseline;
- product-authority risk decision;
- authenticated audit findings at pre-correction head;
- corrected master plan, amendment and SFJM set;
- live final-head metadata.

## 9. Evidence missing

- final-head GPT0/GPT1/GPT3 re-audit;
- Ready and merge lifecycle;
- PR-01 envelope;
- current Supabase preflight;
- fixtures and tests;
- migration/rollback/smoke evidence;
- isolated B1 adversarial evidence;
- final Security Go gate.

## 10. What must not be redone

- do not reopen PR #101 without new evidence;
- do not restart broad discovery unless a narrow invalidating event requires refresh;
- do not create a lab solely because the pre-amendment plan required one;
- do not treat participant beta acceptance as security consent;
- do not attempt B1 self-elevation on primary;
- do not create a recursive commit solely to record the final head;
- do not count PRs as product value.

## 11. What must not be altered

Runtime, frontend, Supabase, data, migrations, RLS, grants, policies, RPCs, Auth, Vercel, Actions, integrations, PR-01, Security Go, F1-02 acceptance and WDP remain outside current authority.

## 12. Single next safe action

Validate the exact final corrective head and eight-file diff, then send the PR to independent GPT0/GPT1/GPT3 re-audit.

No write follows without a new explicit authority.
