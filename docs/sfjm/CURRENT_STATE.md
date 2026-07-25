# FECH.AI — SFJM Current State

**Lifecycle state:** `F1_02_CONTROLLED_BETA_PRIMARY_STRATEGY_IN_DRAFT / DETAILED_BASELINE_RESTORED / SECURITY_GO_DENIED`  
**Record type:** `OPERATIONAL_STATE / DOCUMENTATION_ONLY`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Context understood

FECH.AI is:

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users: YES
Multiple companies: YES
Sensitive lead/customer data: YES
Paid SLA: NO
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Accepted operating risk is limited to downtime, maintenance, manual recovery and possible beta-data loss. It is not a waiver for privilege escalation, cross-tenant access, confidentiality, integrity, privacy or authorization failures.

Frontend requests and displays. Backend/RPC/Supabase validates and decides. AI assists, but is not authority.

## 2. Canonical main

```text
Branch: main
SHA: affbae1a598928010b0fa7db967734de522c13b4
Source PR: #101
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
```

PR #101 made the detailed F1-02 findings and remediation baseline canonical. It did not authorize technical execution.

## 3. Active strategy PR

```text
PR: #102
Title: docs(security): adopt controlled beta primary remediation strategy
State: OPEN / DRAFT
Merged: false
Base: main
Base SHA: affbae1a598928010b0fa7db967734de522c13b4
Branch: docs/f1-02-controlled-beta-primary-strategy
Pre-restoration head: 6b7d96fb26d6589641bc079146db9c3f429b9bd2
Final restoration head: resolve from live PR metadata and PR description
Expected commits after restoration: 9
Strategy canonicality: NOT_YET_CANONICAL
```

The restoration commit changes six authorized documents. Because the master plan is restored to the exact blob already present on `main`, it must no longer appear as a net changed file in the PR diff.

Expected final PR changed-file set:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

Expected final PR changed-file count:

```text
7
```

## 4. Documentary architecture

The detailed master plan is preserved at its exact canonical baseline blob:

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
blob: ea161050c535b848ff927133830984f543c1104d
```

The separate strategy amendment remains the only artifact that supersedes lab-only requirements:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
```

After PR #102 is merged, the amendment prevails only when the baseline requires an isolated environment universally. It does not remove or condense:

- table/RLS/grant matrices;
- RPC contract cards;
- call-site maps;
- migration and rollback contracts;
- the original PR-01 → PR-02 → PR-03 compatibility sequence;
- positive and negative test matrices;
- evidence schema;
- independent audit;
- final gates;
- one PR / one risk / one rollback.

## 5. Controlled validation decision

The amendment classifies validation as:

```text
SAFE_LIVE
ISOLATED
DEFERRED
PROHIBITED
```

The primary project is live and is not an unrestricted laboratory.

Actual B1 self-promotion to `admin_global`, root or equivalent authority remains `ISOLATED` and `NOT_VERIFIED` without isolation. An intentional named admin assignment is a separate administrative operation and is not a test.

## 6. Current blockers

### Documentation lifecycle

- final restoration head requires independent GPT0 reauditing;
- GPT1 and GPT3 must be repeated only after documentary consistency passes;
- Ready and merge remain separately authorized lifecycle steps.

### F1-02 technical blockers

- B1 — broker self privilege escalation;
- B2 — excessive direct CRM writes;
- B3 — forgeable funnel history;
- B4 — incomplete same-company list ACL proof;
- tenant-safe funnel stages;
- company-scoped import idempotency;
- strict feedback allowlist;
- explicit `times` disposition;
- leaked-password-protection decision;
- executed tests, rollback/reapply and final gate.

## 7. Current authorities

```text
Additional commits: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase read/mutation: NOT AUTHORIZED
Runtime/frontend: NOT AUTHORIZED
Fixtures/tests: NOT AUTHORIZED
Admin_global assignment: NOT AUTHORIZED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 8. Evidence available

- live PR #102 metadata before restoration;
- canonical main and PR #101 lifecycle;
- exact detailed baseline blob;
- strategy amendment;
- GPT0, GPT1 and GPT3 reaudits at head `6b7d96fb...`;
- bounded restoration authority;
- final restoration commit and PR-description update, once validated.

## 9. Evidence absent

- independent audit of the final restoration head;
- Ready and merge authority;
- any PR-01 implementation;
- current Supabase preflight for a technical change;
- fixtures;
- executed security tests;
- migration, rollback or reapply evidence;
- runtime smoke;
- final Security Go decision.

## 10. Single next safe action

Reaudit the final PR #102 head with GPT0, validating that:

1. the master plan blob is exactly `ea161050c535b848ff927133830984f543c1104d`;
2. the original detailed technical contracts and PR sequence are restored;
3. the strategy amendment is the only lab-only supersession artifact;
4. the PR has exactly 9 commits and 7 net changed files;
5. no unauthorized path entered the corrective commit or PR diff;
6. the PR remains OPEN / DRAFT.

Do not mark Ready, merge, begin PR-01 or access Supabase.
