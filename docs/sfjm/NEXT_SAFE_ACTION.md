# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / PR127_MERGED / AUDIT_SCHEMA_V5_CORRECTION / PUBLISH_DRAFT_AND_REPEAT_EXACT_HEAD_REVIEWS`
**Updated:** `2026-08-24`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This file is a thin semantic view. Principal material state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve GitHub/Supabase lifecycle live before acting.

Because this 2026-08-24 transition is on the post-merge v5 corrective change
set, a new conversation must bootstrap from live `main`, then resolve the active
v5 corrective PR/head and read this file from that exact head until merge.

## 2. Single current semantic next action

```text
Publish/reconcile the T3A-v5 audit-schema compatibility correction in one new
Draft PR from merged main `610bdd3c...`, resolve its live exact head, and obtain
Backend/Data exact-head review. Only after Backend/Data closure, obtain the
independent AppSec exact-head review. Stop in Draft.
```

Changed domains to reconcile on that exact head:

```text
Edge dual modern/legacy audit insert for reset and creation paths
audit insert must succeed before proof/prepare/Auth
conservative inet normalization plus legacy text IP
complete live audit relation fingerprint in migration pre/postflight
authenticated audit INSERT revoked while authenticated SELECT remains
rollback proof→authority→lease→audit order
rollback exact post-T3 fingerprint + exact legacy INSERT restoration
unchanged v4 B1-B4/actor/tenant/proof/lease/T1 contracts
```

PR #127 is merged. The one new Draft PR is justified by the post-merge runtime
finding and is not a duplicate/workaround PR for B1-B4.

## 3. Exact-head closure sequence

The next conversation should:

```text
1. resolve FECH.AI main live
2. execute canonical bootstrap and specialist resolution
3. resolve the active v5 corrective PR live: base/head/state/changed files/checks/reviews/threads
4. read CURRENT_STATE + this file from the exact corrective head
5. confirm the v5 Edge/migration/rollback/evidence/SFJM artifacts are that head
6. preserve T1/T2 contracts and confirm App.jsx has no T3A diff
7. update the corrective PR description so it matches that final head
8. read every final material artifact to EOF and reconcile the coverage matrix
9. prepare an exact-head Backend/Data prompt that includes the approved v4
   lineage, v18 fail-before-Auth PASS, audit POST 400 and v5 correction; Product
   Authority submits it manually and returns the integral response
10. after Backend/Data closure, repeat independently with application-security-assurance-specialist
11. record the manual exact-head outcomes without inventing a Gateway receipt or carrying a prior-head PASS
12. stop in Draft before Ready
```

Head changes invalidate prior exact-head gates. Do not carry a PASS across a corrective commit.

The SES Router is temporarily frozen for this workstream because its Action is
not available from inside the project. Use the manual copy/paste channel recorded
in `AUTHORIZATIONS.md` until Product Authority restores the Router.

## 4. Required safe deployment semantics after later approval

This section is a proof obligation, not deployment authorization.

The intended fail-closed rollout is:

```text
reviewed v5 Edge deployed while proof issuer remains absent
→ audit row is created with modern + legacy fields
→ proof issuer absent: audit status is updated and reset fails before Auth
→ apply reviewed migration
→ validate function/ACL/grants/triggers/audit fingerprints, empty proof/lease tables,
  complete role/schema anchors and all-kind positive routine inventory
→ controlled positive/negative/cross-tenant smoke
→ confirm direct must_change_password client write cannot bypass boundary
```

Do not use the inverse order while the audit-incompatible v18 remains live.

## 5. Required rollback semantics

This section is a proof obligation, not rollback authorization.

Rollback must be executable and drift-aware:

```text
validate exact T3A proof issuer/prepare/release/fence functions, proof/lease
tables/triggers and fixed proof→authority→lease→audit rollback lock order,
complete role/schema anchors, all-kind positive routine inventory and expected
grant state plus complete post-T3 audit relation fingerprint
validate exact T3A-modified T1 guard fingerprint when applicable
require the locked lease table and all unexpired proofs to be empty; otherwise STOP
if drift: STOP
after the complete exact preflight, delete only expired inert proofs and prove
  the locked proof table is empty
otherwise restore database boundary and authenticated audit INSERT to the
  reviewed pre-T3A contract and verify the exact baseline audit fingerprint
while hardened Edge remains deployed and proof issuer is absent: reset fails closed
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
granting prepare EXECUTE to anon/PUBLIC/service_role
continuing to proof/Auth after an audit INSERT error
weakening audit NOT NULL/RLS/ACL contracts instead of matching them
changing user-creation authority/tenant semantics beyond shared audit compatibility
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
