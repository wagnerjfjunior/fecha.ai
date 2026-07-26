# FECH.AI — SFJM Current State

**Lifecycle state:** `F1_02_CONTROLLED_BETA_PRIMARY_STRATEGY_IN_DRAFT / FINAL_DOCUMENTARY_CORRECTION_APPLIED / SECURITY_GO_DENIED`  
**Record type:** `OPERATIONAL_STATE / DOCUMENTATION_ONLY`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Context

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

Accepted operating risk is limited to downtime, maintenance, manual recovery and possible beta-data loss. It is not a security, privacy or tenant-isolation waiver.

Frontend requests and displays. Backend/RPC/Supabase validates and decides. AI assists, but is not authority.

## 2. Canonical main

```text
main: affbae1a598928010b0fa7db967734de522c13b4
Source PR: #101
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
```

## 3. Active strategy PR

```text
PR: #102
State: OPEN / DRAFT
Merged: false
Base: main@affbae1a598928010b0fa7db967734de522c13b4
Branch: docs/f1-02-controlled-beta-primary-strategy
Pre-final correction head: 7b8c23bd375d750e73d888f140c8c44a840280a5
Final head: resolve from live PR metadata and PR description
Expected commits: 10
Expected net changed files: 7
Strategy canonicality: NOT_YET_CANONICAL
```

The final correction changes exactly six authorized documents and leaves the master plan and `BLOCKED_ACTIONS.md` unchanged.

## 4. Documentary architecture

```text
Detailed master plan:
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
blob: ea161050c535b848ff927133830984f543c1104d
net PR diff: ABSENT

Lab-only amendment:
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
```

The amendment changes only universal laboratory requirements. It does not remove detailed matrices, RPC cards, call-site maps, migration/rollback contracts, the PR-01 → PR-02 → PR-03 sequence, tests, evidence, audits or gates.

## 5. Validation and B1

```text
SAFE_LIVE
ISOLATED
DEFERRED
PROHIBITED
```

Actual B1 self-promotion to `admin_global`, root or equivalent remains `ISOLATED / NOT_VERIFIED` without isolation. A named admin assignment is a separate `ADMINISTRATIVE_ROLE_CHANGE`, not a test and not authorized now.

## 6. Authority vocabulary

```text
WINDOW_IMPLEMENTATION
TECHNICAL_PR_LIFECYCLE
CONTROLLED_BETA_PRIMARY_CHANGE
ADMINISTRATIVE_ROLE_CHANGE
SECURITY_GATE
```

Legacy aliases:

```text
PR_LIFECYCLE = TECHNICAL_PR_LIFECYCLE
PRODUCTION_CHANGE = CONTROLLED_BETA_PRIMARY_CHANGE
```

Aliases create no additional authority and cannot be used without a new exact authorization.

## 7. Blockers

Documentation lifecycle:

- GPT0 must audit the exact final head;
- GPT1 and GPT3 repeat only after GPT0 recommends Ready;
- Ready and merge require separate authority;
- a new head invalidates prior exact-head conclusions.

F1-02 technical blockers:

- B1 — self privilege escalation;
- B2 — excessive direct CRM writes;
- B3 — forgeable funnel history;
- B4 — incomplete same-company ACL proof;
- funnel-stage, import, feedback, `times` and leaked-password requirements;
- executed tests, rollback/reapply and final gate.

## 8. Current authorities

```text
Final correction authority: CONSUMED
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

## 9. Evidence

Available:

- live `main` and PR #101 anchors;
- exact master-plan blob;
- PR #102 history through `7b8c23bd...`;
- authenticated GPT0/GPT1/GPT3 audits;
- bounded final correction authority;
- final commit and PR-description state after live validation.

Absent:

- GPT0 audit of final head;
- final-head GPT1/GPT3 reaudits;
- Ready and merge authority;
- PR-01 implementation;
- Supabase preflight, fixtures, tests, rollback/reapply and smoke;
- final Security Go decision.

## 10. Next safe action

Run GPT0 against the exact final PR #102 head and validate:

1. parent `7b8c23bd375d750e73d888f140c8c44a840280a5`;
2. one final correction commit;
3. exactly six paths in that commit;
4. 10 total commits and 7 net changed files;
5. unchanged master-plan blob `ea161050c535b848ff927133830984f543c1104d`;
6. unchanged `BLOCKED_ACTIONS.md`;
7. current lifecycle and strict alias mapping;
8. PR remains OPEN / DRAFT;
9. no active authority for additional commits, Ready, merge, PR-01 or Supabase.

Do not mark Ready, merge, begin PR-01 or access Supabase.
