# FECH.AI — F1-02 Controlled Beta Primary Strategy Amendment

**Status:** `PRODUCT_AUTHORITY_DECISION_RECORDED / PR_DRAFT / NOT_YET_CANONICAL / DOCUMENTATION_ONLY / SECURITY_GO_DENIED`  
**Date:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**PR:** `#102`  
**Base:** `main@affbae1a598928010b0fa7db967734de522c13b4`  
**Branch:** `docs/f1-02-controlled-beta-primary-strategy`  
**Pre-final correction head:** `7b8c23bd375d750e73d888f140c8c44a840280a5`

## 1. Decision

The Product Authority decided that MVP 1 — Família continues on the primary Supabase project under:

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Broad paid commercialization: BLOCKED
Paid SLA: NO
Real users and data: YES
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Accepted operating risk is limited to downtime, maintenance, manual recovery and possible beta-data loss. It is not a waiver for privilege escalation, cross-tenant access, confidentiality, integrity, privacy or authorization failures.

## 2. Supersession and precedence

This amendment is the sole artifact that supersedes the original F1-02 master plan where that plan makes an isolated Supabase environment a universal prerequisite.

The detailed master plan was restored unchanged to the canonical `main` blob:

```text
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
blob: ea161050c535b848ff927133830984f543c1104d
```

Because the restored blob is identical to `main`, the master plan does not appear in the final net PR diff.

After PR #102 is audited and merged, this amendment prevails only for these lab-only conflicts:

- mandatory isolated branch before every implementation;
- absolute stop when a laboratory is unavailable;
- universal `LAB_VALIDATION_PASSED`;
- mandatory isolated rollback/reapply rehearsal for every migration;
- universal “apply only in lab” language;
- lab-cost confirmation as the universal prerequisite for PR-01.

All other detailed master-plan requirements remain binding, including:

- one PR / one risk / one rollback;
- table/RLS/grant matrices;
- RPC contract cards;
- call-site maps;
- migration and rollback contracts;
- the original PR-01 → PR-02 → PR-03 sequence;
- positive and negative test contracts;
- evidence, freshness, independent audits and final gates;
- fail-closed behavior and separation of duties.

## 3. Controlled validation model

Every validation item must be classified before execution.

### `SAFE_LIVE`

Permitted only under exact authority when unexpected success or failure cannot escape a wholly synthetic graph, create real authority, expose real data or modify global controls.

### `ISOLATED`

Required when unexpected success can create admin/root authority, expose real data, affect global controls, require reset, fuzzing, broad discovery or destructive rollback/reapply.

### `DEFERRED`

Required evidence that cannot currently be executed safely. It remains `NOT_VERIFIED`, keeps the finding open and may block final Security Go.

### `PROHIBITED`

Never execute against real actors, companies, identifiers, credentials or data, or through unbounded discovery, deliberate corruption or disabled controls.

The universal lifecycle gate is interpreted as:

```text
CONTROLLED_VALIDATION_PASSED
```

## 4. B1 and intentional administration

The primary project must not be used to attempt actual self-promotion to `admin_global`, root or equivalent authority.

A synthetic account is not sufficient containment when unexpected success grants authority over a live project containing real companies and data.

Allowed under future exact authority:

- read-only grants, policies and function inspection;
- structural proof that authority-bearing direct update exposure was removed;
- review of the narrow RPC contract;
- positive controlled smoke;
- rejection paths that cannot create authority or access real data.

```text
B1 GLOBAL SELF-ESCALATION NEGATIVE TEST:
ISOLATED / NOT_VERIFIED WITHOUT ISOLATION
```

An intentional named `admin_global` assignment is a separate administrative-governance operation. It is not a test and does not prove B1 remediation. It requires separate `ADMINISTRATIVE_ROLE_CHANGE` authority with verified identity, business need, least privilege, server-side execution, audit and revocation. PR #102 authorizes no assignment.

## 5. Synthetic graph and prohibited operations

Any future `SAFE_LIVE` fixture must form a wholly synthetic graph. No synthetic object may reference a real company, user, broker, team, list, lead or customer. Real brokers must not receive synthetic records. Synthetic users must not receive global authority. Unexpected success must remain contained. Fixture cleanup is not schema/configuration rollback.

Explicitly prohibited on the primary project:

- actual self-elevation to `admin_global` or root;
- adversarial mutation of authority-bearing broker fields;
- broad cross-company discovery;
- use of real IDs or credentials;
- fuzzing, load, volume or mixed-tenant offensive batches;
- disabling RLS, policies, grants or Auth;
- `service_role` in browser/frontend/untrusted client;
- deliberate corruption or deletion of real data;
- experimental destructive rollback/reapply.

## 6. Authority model and legacy aliases

```text
WINDOW_IMPLEMENTATION
→ one bounded technical PR

TECHNICAL_PR_LIFECYCLE
→ Ready and/or exact-head merge

CONTROLLED_BETA_PRIMARY_CHANGE
→ one exact live Supabase operation

ADMINISTRATIVE_ROLE_CHANGE
→ one intentional named administrative-role assignment

SECURITY_GATE
→ final evidence-based security decision only
```

Legacy-name mapping from the restored master plan:

```text
PR_LIFECYCLE
= legacy name for TECHNICAL_PR_LIFECYCLE

PRODUCTION_CHANGE
= legacy name for CONTROLLED_BETA_PRIMARY_CHANGE
```

The legacy names are strict aliases only. They create no additional authority, expand no scope and cannot be used without a new, exact and unexpired authorization.

Implementation, Ready, merge, Supabase application, administrative role assignment and Security Go remain separate decisions. A merged PR does not authorize SQL or configuration application.

## 7. Current lifecycle

Immediately before this final correction:

```text
Head: 7b8c23bd375d750e73d888f140c8c44a840280a5
Commits: 9
Net changed files: 7
Master-plan blob: ea161050c535b848ff927133830984f543c1104d
GPT0: FAIL
Required findings: stale lifecycle and authority-name mapping
```

The final correction:

- has parent `7b8c23bd375d750e73d888f140c8c44a840280a5`;
- changes exactly six authorized documentation paths;
- leaves the master plan and `BLOCKED_ACTIONS.md` unchanged;
- results in 10 commits and 7 net changed files;
- externalizes its final SHA to live PR metadata and the PR description.

```text
PR #102: OPEN / DRAFT
Strategy canonicality: NOT_YET_CANONICAL
Additional commits: NOT AUTHORIZED after this correction
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase: NOT AUTHORIZED
Admin_global assignment: NOT AUTHORIZED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

## 8. Rollback and next action

One revert of PR #102 restores the prior universal isolated-lab strategy. That documentation revert does not revert any later technical or Supabase operation.

Resolve the final head from live PR metadata and the updated PR description. Run GPT0 against that exact head. GPT0 must validate the parent, the six-path final commit, 10 total commits, 7 net changed files, unchanged master plan and `BLOCKED_ACTIONS.md`, current lifecycle and strict alias mapping.

Only after GPT0 recommends Ready may GPT1 and GPT3 be repeated on the same exact head.

No technical or Supabase action is authorized.
