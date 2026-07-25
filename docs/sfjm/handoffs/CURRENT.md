# FECH.AI — SFJM Current Handoff

**Status:** `CURRENT_HANDOFF / PR_102_DETAILED_BASELINE_RESTORED / REAUDIT_REQUIRED`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

The Product Authority decided that MVP 1 — Família remains a live controlled free beta.

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Paid SLA: NO
Real users/data: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Downtime and possible beta-data loss are accepted operating risks. Privilege escalation, cross-tenant access, sensitive-data disclosure, unauthorized authority changes and destructive testing are not accepted.

## 2. Canonical anchors

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
Detailed master-plan blob:
ea161050c535b848ff927133830984f543c1104d
```

Canonical F1-02 baseline:

```text
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

## 3. Active PR

```text
PR: #102
Title: docs(security): adopt controlled beta primary remediation strategy
State: OPEN / DRAFT
Base: affbae1a598928010b0fa7db967734de522c13b4
Branch: docs/f1-02-controlled-beta-primary-strategy
Pre-restoration head:
6b7d96fb26d6589641bc079146db9c3f429b9bd2
Final restoration head:
resolve from live PR metadata and PR description
Expected commits: 9
Expected net changed files: 7
```

The strategy artifact is:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
```

It is `PR_DRAFT / NOT_YET_CANONICAL`.

## 4. Why the latest correction was required

At head `6b7d96fb...`:

```text
GPT0: FAIL
GPT1: PASS WITH RESIDUAL RISK
GPT3: PASS WITH RESIDUAL RISK
```

GPT0 correctly identified that the master plan had been condensed beyond the authorized lab-only supersession. Detailed RPC, RLS/grant, call-site, migration, rollback, test, evidence and PR sequencing contracts were removed or reduced.

No majority rule applies. Ready remained blocked.

## 5. Restoration performed

The corrective strategy is deliberately conservative:

- restore the master plan to the exact detailed baseline blob;
- do not rewrite or condense it;
- leave the strategy amendment as the sole lab-only supersession artifact;
- preserve all detailed non-lab contracts;
- preserve the original PR-01 → PR-02 → PR-03 sequence;
- update only authorized SFJM state;
- keep PR #102 Draft.

Because the restored master plan equals the file on `main`, it no longer belongs in the final PR net diff.

## 6. Controlled Beta Primary boundary

The primary project may receive a future bounded remediation only after separate authorities.

```text
WINDOW_IMPLEMENTATION
→ creates one technical PR

TECHNICAL_PR_LIFECYCLE
→ authorizes Ready and/or exact-head merge

CONTROLLED_BETA_PRIMARY_CHANGE
→ authorizes one exact live Supabase operation

ADMINISTRATIVE_ROLE_CHANGE
→ authorizes one named role assignment; not a security test

SECURITY_GATE
→ authorizes only a final evidence-based decision
```

A merged technical PR does not authorize Supabase application.

## 7. B1 boundary

Allowed on the primary project under future exact authority:

- read-only structural proof;
- grants/policies/RPC contract review;
- positive controlled smoke;
- rejection paths that cannot create real authority.

Requires isolation:

- actual self-promotion to `admin_global`, root or equivalent;
- adversarial mutation of authority-bearing broker fields;
- any test whose unexpected success reaches real data or global controls.

An intentional named `admin_global` assignment is not a B1 test and is not authorized now.

## 8. Current blockers

### PR #102 lifecycle

- GPT0 reauditing at final restoration head;
- GPT1/GPT3 reaudits only after GPT0 passes;
- separate Ready authority;
- separate merge authority.

### F1-02

- B1–B4 remain open;
- technical PRs remain unimplemented;
- no fixtures or tests;
- no migration/rollback/reapply evidence;
- no runtime smoke;
- no final Security Go gate.

## 9. Current prohibitions

```text
Additional commits: NOT AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase/Auth: NOT AUTHORIZED
Runtime/frontend: NOT AUTHORIZED
Fixtures/tests: NOT AUTHORIZED
Admin_global assignment: NOT AUTHORIZED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 10. Evidence available

- live main/PR #101 anchors;
- exact baseline master-plan blob;
- PR #102 history;
- authenticated GPT0/GPT1/GPT3 audits at `6b7d96fb...`;
- bounded restoration authority;
- final commit and PR-description state after live validation.

## 11. Evidence missing

- independent GPT0 audit of final restoration head;
- final-head GPT1/GPT3 reaudits;
- Ready and merge gates;
- PR-01 scope and implementation;
- Supabase preflight and application authority;
- executed validation and rollback evidence;
- final Security Go decision.

## 12. Single next safe action

Run GPT0 against the exact final PR #102 head and verify:

```text
master-plan blob:
ea161050c535b848ff927133830984f543c1104d

corrective parent:
6b7d96fb26d6589641bc079146db9c3f429b9bd2

expected commits:
9

expected net changed files:
7
```

Do not mark Ready, merge, start PR-01 or access Supabase.

## 13. What must not be redone

- do not reconstruct F1-02 from zero;
- do not condense the detailed master plan again;
- do not reopen PR #101 without new evidence;
- do not treat beta consent as a security waiver;
- do not create an isolated branch merely because the old baseline required it universally;
- do not use an intentional administrator assignment as B1 evidence;
- do not create recursive documentation PRs solely to record their own merge.

## 14. New-conversation startup

A receiving conversation must:

1. read bootstrap, governance and SFJM indexes;
2. validate live `main`, PR #102 and the exact head;
3. read the detailed master plan and strategy amendment together;
4. treat the amendment as lab-only supersession, not a replacement for the technical program;
5. preserve Security Go denied, F1-02 blocked and WDP 0;
6. require exact authority for every GitHub and Supabase transition;
7. stop fail-closed when evidence is incomplete.
