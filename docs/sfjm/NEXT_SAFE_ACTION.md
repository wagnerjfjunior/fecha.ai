# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / T3A_CORRECTION / DOCUMENTATION_ONLY`  
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
Correct the existing T3A administrative password-reset boundary change set in place, closing B1-B4 without opening another T3A PR.
```

Required blockers:

```text
B1 safe rollout order
B2 trust-anchor preflight
B3 drift-safe rollback
B4 T1 guard interoperability
```

## 3. Corrective sequence

The next conversation should:

```text
1. resolve FECH.AI main live
2. execute canonical bootstrap and specialist resolution
3. resolve the active T3A PR live: base/head/state/changed files/checks/reviews/threads
4. read CURRENT_STATE + this file from the exact active T3A head
5. revalidate production read-only anchors material to B1-B4
6. correct only the existing T3A Edge/migration/rollback/evidence artifacts required by the blockers
7. preserve T1/T2 contracts and do not alter frontend in T3A
8. update PR description after the final corrective head so description and actual scope cannot diverge
9. read all final material artifacts to EOF and publish a coverage matrix
10. Backend/Data exact-head review
11. independent AppSec exact-head review
12. stop before Ready unless Product Authority separately authorizes Ready
```

Head changes invalidate prior exact-head gates. Do not carry a PASS across a corrective commit.

## 4. Required safe deployment semantics after later approval

This section is a proof obligation, not deployment authorization.

The intended fail-closed rollout is:

```text
reviewed hardened Edge deployed first
→ T3 RPC absent: administrative reset fails closed without Auth mutation
→ apply reviewed migration
→ validate function/ACL/grants/triggers/fingerprints
→ controlled positive/negative/cross-tenant smoke
→ confirm direct must_change_password client write cannot bypass boundary
```

Do not use the inverse order while the v17 reset behavior remains live.

## 5. Required rollback semantics

This section is a proof obligation, not rollback authorization.

Rollback must be executable and drift-aware:

```text
validate exact T3A function/ACL/fingerprint + expected grant state
validate exact T3A-modified T1 guard fingerprint when applicable
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

Update this file when the semantic next action changes materially, for example after B1-B4 closure, an exact-head gate result, application/deployment validation or a new material blocker.

Do not update merely for SHA movement or lifecycle-only transitions.
