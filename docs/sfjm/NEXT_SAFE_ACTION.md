# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / PR128_MERGED / EDGE_V19_B1_PASS / PLPGSQL_ALIAS_CORRECTION / EXACT_HEAD_REVIEWS_REQUIRED`
**Updated:** `2026-08-25`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This file is a thin semantic view. Principal material state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve GitHub/Supabase lifecycle live before acting. The alias-correction
transition is `PR_HEAD_ONLY` until merge; use the exact corrective PR head.

## 2. Single current semantic next action

```text
Create/reconcile one Draft PR from main 3c9daf6c... that renames only the
conflicting pg_roles alias in forward and rollback pre/postflight, updates the
material evidence/SFJM, and obtains Backend/Data exact-head review. Only after
Backend/Data closure, obtain independent AppSec exact-head review. Stop in Draft.
```

The production migration invocation already occurred once and aborted before
DDL. A second application is not part of this action.

## 3. Exact-head closure sequence

```text
1. resolve main 3c9daf6c... live and create the narrow corrective branch
2. verify SQL sources match live reviewed blobs before editing
3. change only pg_roles alias r -> role_row and its role-field qualifiers
4. update evidence/SFJM for PR128 merge, Edge v19 PASS and failed application
5. resolve the Draft PR exact head and changed-file set
6. read every changed material artifact through EOF
7. obtain manual Backend/Data exact-head review
8. only after Backend/Data closure, obtain independent AppSec review
9. stop in Draft before Ready
```

Head changes invalidate the two new reviews. The prior v5 approvals remain
lineage for unchanged domains, not approval of the corrected bytes.

## 4. Required safe deployment semantics after later approval

This section is a proof obligation, not deployment or migration authority.

```text
corrected exact head reviewed by Backend/Data + AppSec
-> separately authorize Ready and merge
-> resolve merged main and authenticate exact SQL bytes
-> separately authorize one new migration application
-> require complete migration postflight/catalog validation
-> separately authorize bounded smoke
```

Production Edge v19 is already active and the audit-first fail-before-Auth
proof is PASS. No Edge redeploy is part of the alias correction.

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
