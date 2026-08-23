# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / T3A_V3_AFTER_BACKEND_REQUEST_CHANGES / REPEAT_BACKEND_EXACT_HEAD_REVIEW_PENDING / DOCUMENTATION_ONLY`
**Updated:** `2026-08-23`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This file is a thin semantic view. Principal material state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve GitHub/Supabase lifecycle live before acting.

Because the 2026-08-23 transition update is currently on the active T3A change set, a new conversation must bootstrap from live `main`, then resolve the active T3A PR/head and read this file from that exact head until the change set is merged.

## 2. Single current semantic next action

```text
Publish/reconcile the v3 correction for the valid Backend/Data `REQUEST_CHANGES`
on `bf8fb1f...`, resolve the new live final head, and repeat Backend/Data. Only
after Backend/Data closure, obtain the independent AppSec exact-head review.
```

Corrected candidate domains to reconcile on that exact head:

```text
B1 safe rollout order
B2 trust-anchor preflight
B3 drift-safe rollback
B4 T1 guard interoperability
DB-commit-to-Auth authority continuity through a durable lease/fence whose
unique-index probes remain effective across pre-lease MVCC snapshots
exact authority-table ACL transition with service_role TRUNCATE removed
positive non-system routine inventory replacing the rejected writer regex
```

## 3. Exact-head closure sequence

The next conversation should:

```text
1. resolve FECH.AI main live
2. execute canonical bootstrap and specialist resolution
3. resolve the active T3A PR live: base/head/state/changed files/checks/reviews/threads
4. read CURRENT_STATE + this file from the exact active T3A head
5. confirm the corrected Edge/migration/rollback/evidence/SFJM artifacts are the resolved PR head
6. preserve T1/T2 contracts and confirm App.jsx has no T3A diff
7. update the existing PR description so it matches that final head
8. read every final material artifact to EOF and reconcile the coverage matrix
9. prepare a new exact-head Backend/Data prompt that includes the prior HIGH-1/HIGH-2 corrections; Product Authority submits it manually to backend-data-platform-specialist and returns the integral response
10. after Backend/Data closure, repeat independently with application-security-assurance-specialist
11. record the manual exact-head outcomes without inventing a Gateway receipt or carrying a prior-head PASS
12. stop before Ready unless Product Authority separately authorizes Ready
```

Head changes invalidate prior exact-head gates. Do not carry a PASS across a corrective commit.

The SES Router is temporarily frozen for this workstream because its Action is
not available from inside the project. Use the manual copy/paste channel recorded
in `AUTHORIZATIONS.md` until Product Authority restores the Router.

## 4. Required safe deployment semantics after later approval

This section is a proof obligation, not deployment authorization.

The intended fail-closed rollout is:

```text
reviewed hardened Edge deployed first
→ T3 RPC absent: administrative reset fails closed without Auth mutation
→ apply reviewed migration
→ validate function/ACL/grants/triggers/fingerprints, the empty lease table and positive routine inventory
→ controlled positive/negative/cross-tenant smoke
→ confirm direct must_change_password client write cannot bypass boundary
```

Do not use the inverse order while the v17 reset behavior remains live.

## 5. Required rollback semantics

This section is a proof obligation, not rollback authorization.

Rollback must be executable and drift-aware:

```text
validate exact T3A prepare/release/fence functions, lease table/triggers, positive routine inventory and expected grant state
validate exact T3A-modified T1 guard fingerprint when applicable
require the locked lease table to be empty; otherwise STOP
if drift: STOP
otherwise restore database boundary to reviewed pre-T3A contract
while hardened Edge remains deployed and T3 RPC is absent: reset fails closed
then restore the versioned v17 Edge baseline only under explicit rollback authority
verify runtime/catalog after rollback
```

Rollback must not rewrite real user password-state data merely to recreate old presentation state.

## 6. Anti-workaround requirements

The correction must not solve T3A by:

```text
disabling T1 triggers
broadening authenticated UPDATE
trusting empresa/role/flags/time from client
making service_role the caller identity for the T3 authorization RPC
granting T3 EXECUTE to anon/PUBLIC/service_role
silently changing user-creation semantics
using production trial-and-error as implementation validation
```

## 7. No audit loop

Do not reopen T1/T2 as independent workstreams absent new material evidence that invalidates their established scope.

Use their current live contracts only as dependencies to prove T3A compatibility.

A repeated audit on unchanged evidence is:

```text
AUDIT_LOOP_BLOCKED
```

## 8. Update rule

Update this file when the semantic next action changes materially, for example
after an exact-head gate result, application/deployment validation or a new
material blocker.

Do not update merely for SHA movement or lifecycle-only transitions.
