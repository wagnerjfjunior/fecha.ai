# FECH.AI — T3A-v3 Administrative Password Reset Multi-Tenant Authority Boundary

**Status:** `CORRECTED_AFTER_BACKEND_REQUEST_CHANGES / B1-B4 CANDIDATE_ADDRESSED / EXACT_HEAD_REVIEW_REQUIRED / NOT_APPLIED / NOT_DEPLOYED / NOT_READY / NOT_MERGED`
**Initial evidence date:** `2026-08-22`
**Corrective evidence date:** `2026-08-23`
**Repository:** `wagnerjfjunior/fecha.ai`
**Base main:** `037232fe3da37a749ab980f783af92ff15e2baf2`
**Branch:** `security/t3a-admin-password-reset-boundary`
**Initial blocked PR head:** `45ad27668835b6458b52d2fb592cfa36b5589726`
**Backend/Data reviewed head:** `bf8fb1f4ab043226de3c77763b9b425a13b0261e`

This document records the corrected candidate after the valid manually-relayed
Backend/Data exact-head review returned `REQUEST_CHANGES`. The new final exact
head must be resolved live after commit. No verdict from an earlier head carries
forward.

## 1. Authorized and prohibited scope

T3A changes only the administrative password-reset boundary:

- `auth.uid()` is the actor;
- company, role, flags, team and protected-admin identity come from the server;
- root / admin_local / gestor authority remains strict;
- cross-company and missing-target results fail closed without enumeration;
- a durable database lease fences the authority decision through the external
  Auth password mutation;
- `must_change_password=true` is established before Auth mutation;
- the stale direct authenticated password-state grant is revoked;
- both existing T1 triggers remain enabled;
- the exact pre-T3A T1 direct guard has a drift-aware restoration path;
- the live `criar-usuario` v17 baseline remains the Edge rollback anchor.

This change does not authorize or perform:

- an `App.jsx` change;
- a production migration or runtime mutation;
- an Edge production deployment;
- a smoke or rollback execution;
- Ready, merge or Security Go;
- a broad grant, trigger disablement, data normalization or frontend authority.

## 2. LIVE_RESOLVED_STATE and MATERIAL_RECORDED_STATE

Read-only production state reconciled on `2026-08-23`:

```text
Supabase project: uobxxgzshrmbtjfdolxd / ACTIVE_HEALTHY / PostgreSQL 17
latest material migration: 20260822192552 f1_02_harden_status_corretor_rpc
public.t3_prepare_admin_password_reset(uuid): ABSENT
public.t3_admin_password_reset_leases: ABSENT
criar-usuario: v17 / ACTIVE / verify_jwt=false
live Edge ezbr_sha256: 679643d42dc944cc810580807f4b1a2f5a78ff30a0ce0d67f0713817b2eeb47f
T3A migration applied: NO
T3A hardened Edge deployed: NO
```

The v17 source remains versioned at:

```text
commit: 23ba5d03e146e50cb510c065e70e2c8e5ed9794a
path: supabase/functions/criar-usuario/index.ts
```

No PII was needed or returned by catalog reconciliation.

## 3. Exact-head review lineage

The manual Backend/Data response was integral and bound to:

```text
role: backend_data -> backend-data-platform-specialist
PR: #127 / open / Draft / unmerged
base: 037232fe3da37a749ab980f783af92ff15e2baf2
reviewed head: bf8fb1f4ab043226de3c77763b9b425a13b0261e
tree: 7f5ad06ed27ae1fb724175dd5f30af1e7135010b
files read to EOF: exact 10
verdict: REQUEST_CHANGES
```

No Gateway receipt was claimed because the SES Router/Action was unavailable.
The two material findings were:

1. the SQL transaction ended before the irreversible Auth mutation, leaving
   actor/target/protected identity/company/team authority mutable in the gap;
2. the negative `pg_proc.prosrc` regex did not prove indirect, dynamic or
   transitive password-state writer absence for migration or rollback.

The current candidate changes the design for both findings. That changes the
head and invalidates the reviewed-head verdict as a closure result. Backend/Data
must review the new exact head again before independent AppSec.

## 4. B1 — safe rollout and failure ordering

The required order under separate production authorities remains:

```text
1. deploy the exact reviewed hardened Edge
2. while T3 RPC is absent, prove reset_password fails before Auth mutation
3. apply the exact reviewed T3A migration
4. validate catalog, roles, routine inventory, ACLs, grants, policies,
   lease table, all T1/T3 triggers and body fingerprints
5. run separately-authorized positive/negative/cross-tenant/concurrency smoke
```

The Edge calls the caller-JWT `t3_prepare_admin_password_reset` RPC before
`auth.admin.updateUserById`. Missing RPC, denial, malformed response or absent
lease ID returns a generic denial before Auth.

The requested target UUID and returned lease UUID are canonicalized and
validated before comparison/use, preventing equivalent UUID spellings from
turning a successful preparation into a stranded lease.

If preparation committed but its response is lost, the Edge still performs no
Auth mutation and cannot guess a lease identity; the durable lease remains for
separately-authorized recovery.

After authorization, Auth is called while the durable lease remains committed.
The service-role client releases only the exact lease after a proven successful
Auth response. Any ambiguity in the Auth call or result leaves the lease in place;
the Edge returns a generic failure and does not improvise cleanup. Release
transport ambiguity occurs only after proven Auth success and is reconciled as
described in §8. A stuck lease is an availability incident requiring separate
recovery authority, not an authorization gap.

The inverse migration-first order remains prohibited while v17 is live.

## 5. B2 — exact positive trust-anchor preflight

The migration holds `admins`, `corretores` and `times` in `SHARE` mode
through preflight, DDL and postflight. Before mutation it verifies:

- exact postgres owner/BYPASSRLS attributes, exact client-role attributes,
  absence of client-role memberships and no `public` schema CREATE for
  anon/authenticated/service_role;
- `auth.uid()` owner, security mode, volatility, return/signature, body and
  effective EXECUTE surface;
- authority tables, exact required column types, RLS and FORCE RLS;
- valid, ready, immediate, non-partial, single-column unique identity indexes;
- exact complete table ACLs and authenticated column grants for `admins`,
  `corretores` and `times`, including the established service-role surface;
- exact `corretores_update` / `times_update` semantics plus the complete
  seven-policy authority-table inventory (MD5
  `1cb8f611f86778af0f60c78f2ffc70b0`), preventing an extra permissive `ALL`
  policy from widening either update path;
- exact helper, self-service, legacy password writer, T1 guard and audit
  function bodies, owners, security modes, configs and ACLs;
- exact complete authority-table trigger count/bindings, including both T1
  guards and the corretores/times audit triggers, plus absence of rewrite rules;
- absence of every T3 lease/function/trigger name and context-key collision;
- the exact positive non-system routine inventory described below.

The old direct writer regex is removed. Instead the complete reviewed live
non-system routine catalog is serialized by stable signature plus owner,
language, kind, security mode, volatility/parallel/leak/strict/set-returning
flags, return type, config, implementation hash and normalized ACL:

```text
baseline routines, excluding only the separately-pinned direct T1 guard:
  count = 264
  inventory_md5 = b1f0919df8a0acaca7bbea2b928b0ffe

authenticated-effective SECURITY DEFINER subset:
  count = 122
  inventory_md5 = 7faa376a403c69239d9606559cf9c2db
```

This positive inventory spans all non-system schemas, not just `public`. It
pins wrappers, dynamic-SQL-capable routines and possible transitive callees even
when their source does not contain the target table/column literals. Postflight
and rollback exclude only the exact new T3 functions and separately verify each.

The known legacy service-only writer
`redefinir_senha_corretor(uuid,text)` is also pinned directly:

```text
pg_get_functiondef MD5: 2f1ff707c6ea94e0abf4ede0f2ec3835
authenticated: NO
anon/PUBLIC: NO
service_role: YES
```

Authority-table ACL anchors are also positive and complete:

```text
pre-T3A table ACL MD5s:
  admins=b0e2ac3625f075350c4b2621a8429dd7
  corretores=c05095bb90a0c041ba5bbe82cea27702
  times=82f04ab162741d5ab0e8cd323f083ec8
T3A table ACL MD5s after service_role TRUNCATE revocation:
  admins=f680b340dd9a87a76fea61b681bf6f1e
  corretores=4cce675b8126424e9a455ee4c0569dde
  times=abbf21bbb402467692ba198f40d2026a
all 33 authority-table columns / ACL MD5:
  pre-T3A=3fa731261b3d39ca5d046fd548c1bf53
  T3A=d475edbb63410c2ab4b4c2be55ac270c
```

During T3A the enabled direct guard denies every password-state change except
the two explicit transitions in §7, so legacy/direct/indirect postgres or
service-role writes do not receive password-state authority.

## 6. Server-side actor and tenant contract

### Root

```text
auth.uid()
-> public.admins.user_id
-> role='admin_global'
-> ativo=true
```

A legacy `corretores.role='admin_global'` value is not root authority.

### Admin local

```text
auth.uid()
-> active unique public.corretores profile
-> role='admin_local' and is_admin_local=true
-> target.empresa_id=actor.empresa_id
-> target.role<>'admin_global'
-> target has no public.admins identity
```

### Gestor

```text
auth.uid()
-> active unique public.corretores profile
-> role='gestor', is_gestor=true, is_admin_local=false
-> ordinary broker target in the same empresa
-> target has no public.admins identity
-> target belongs to actor's own active team in the same empresa
```

The RPC accepts only `p_target_user_id`. Frontend company, role, flags, team
and time are not authority inputs.

## 7. B4 and HIGH-1 closure — leased T1 interoperability

At runtime the preparation RPC first obtains one
`SHARE ROW EXCLUSIVE` lock, in fixed order, over:

```text
public.admins -> public.corretores -> public.times
```

This serializes reset decisions against ordinary authority-table relation-lock
acquisition, removes reciprocal reset lock ordering and still permits reads;
the unique-index probes below cover writers whose MVCC snapshot predates it.

After strict authorization and row checks, the RPC creates a random durable row:

```text
public.t3_admin_password_reset_leases
lease_id + actor_user_id + target_user_id + optional gestor authority_time_id
```

The table is owned by postgres, has RLS + FORCE RLS, has no policies and exposes
no table privilege to PUBLIC, anon, authenticated or service_role. Time is
recorded only for diagnostics; there is no time-based authority or expiry.

Three new enabled BEFORE ROW triggers fence:

- actor and target rows in `corretores`;
- actor/target protected identities in `admins`;
- the gestor authority team in `times`.

The lease table has exact unique keys for lease, actor, target and non-null
authority team. Every relevant INSERT/UPDATE/DELETE performs a short
insert/delete uniqueness probe for its old/new protected subject. A live lease
therefore conflicts in the unique index even when a long-running writer has an
MVCC snapshot from before the lease commit. A successful probe remains
transactionally conflicting until that writer commits, so reset preparation
and authority mutation serialize in either arrival order.

Preparation applies the same probes to actor, target and gestor team before
inserting the real lease. Together with the fixed-order table lock, this blocks
cross-role overlap (for example, an active target becoming the actor of a
second reset) even though actor and target use separate unique columns.

Every relevant write is rejected while its lease exists. The only fenced-row
exception is the exact preparation update under a marker bound to:

```text
lease_id : auth.uid() : target.user_id : txid_current()
```

Both original T1 triggers stay enabled. The direct T1 guard accepts only:

1. leased T3 `must_change_password: non-true -> true`, with status fields
   unchanged and an exact matching lease/context/current postgres definer; or
2. the established active self-service
   `must_change_password: true -> false` completion.

If the target flag is already true, T1's established no-change branch plus the
exact leased fence allow the idempotent T3 preparation UPDATE; this adds no
third password-state transition and permits a safe repeated administrative
reset.

Every other password-state change is denied before root/admin/service/internal
compatibility branches. Non-password T1 behavior remains established.

Because PostgreSQL `TRUNCATE` does not run row triggers, T3A revokes only
`TRUNCATE` on these three authority tables from `service_role`; complete ACL
fingerprints prove both the pre-T3A baseline and the narrowed T3A state. All
row-level service-role writes remain subject to the fencing triggers.

The service-role release RPC can only delete one exact
`lease_id + actor_user_id + target_user_id` row. It cannot create a lease,
authorize a target, set password state or substitute for `auth.uid()`.

Exact candidate PL/pgSQL `prosrc` fingerprints:

```text
t3_prepare_admin_password_reset(uuid):            91fc82deadc0d18e871e43a812c8d6dd
t3_release_admin_password_reset_lease(...):        a51c5b360c5d8a3684a97271460ec249
t3_guard_admin_password_reset_lease():             bd611e591aa2d951b178853f78caaa65
T3-aware t1_guard_corretores_direct_compat_update: 951da8a6ac6e934828f06ab1513778fa
```

The pre-T3A guard restoration remains pinned by canonical
`pg_get_functiondef()` MD5:

```text
99477024e337de5645dd042a30f8cf78
```

These source/catalog assertions are not runtime execution evidence.

## 8. Password/Auth sequence

```text
validate caller JWT
-> caller-scoped RPC derives actor/tenant/role/team server-side
-> serialize authority tables
-> create durable exact actor + target + optional authority-team lease
-> set must_change_password=true through both enabled T1/T3 guards
-> commit and return user_id + lease_id
-> service-role Auth client changes that exact user password
-> only proven Auth success permits exact service-role lease release
```

At no point is service_role the actor. Any Auth ambiguity leaves the lease and
all material database authority mutations fenced. Release is attempted only
after proven Auth success; a lost release response may mean either that the
exact safe release committed or that the lease remains. The Edge claims no
success, does not retry blindly and requires state reconciliation.

## 9. B3 — drift-safe rollback

Rollback begins by locking the three authority tables and the lease table in
`SHARE` mode. It stops before destructive work when:

- a lease exists;
- the lease table schema/owner/RLS/FORCE/ACL/constraints/comment differs;
- any T3 function body/owner/security/config/ACL/comment differs;
- the exact seven-trigger T3A authority inventory differs, including any
  absent/changed/disabled fence, T1 or audit trigger, or any rewrite rule;
- the T3-aware direct guard or either original T1 trigger differs;
- roles, `auth.uid()`, helpers, legacy writer, audit objects, policies, grants,
  indexes, context use or positive full routine inventory differs.

Only after exact proof and an empty locked lease table does it atomically:

```text
restore exact pre-T3A direct guard (99477024...)
-> drop the three proven fencing triggers
-> drop exact fence, prepare and service-release functions without IF EXISTS
-> drop exact empty lease table
-> restore only authenticated UPDATE(must_change_password)
-> restore only the pinned service_role TRUNCATE baseline on the three tables
-> verify exact pre-T3A guard/grant/policy/inventory and T3 absence
```

No business row or Auth credential is rewritten. Database rollback remains
first; hardened Edge then fails closed on absent prepare RPC. Restoring Edge v17
is a later separately-authorized step.

## 10. B1-B4 coverage matrix

| Blocker / invariant | Corrective artifact | Candidate result | Runtime result |
|---|---|---|---|
| B1 Edge-first rollout | Edge fail-before-Auth + documented order | addressed | not executed |
| B2 trust-anchor preflight | exact roles/objects + positive routine inventory | addressed after Backend HIGH-2 | not applied |
| B3 drift-safe rollback | same inventory + empty locked lease + exact reversal | addressed after Backend HIGH-2 | not executed |
| B4 T1 interoperability | both T1 triggers + exact leased transitions | addressed | not executed |
| DB→Auth authority continuity | durable lease + snapshot-independent unique-index probes + 3 fencing triggers + service-role TRUNCATE removal + success-only release | addressed after Backend HIGH-1 | not runtime-tested |
| actor=`auth.uid()` | caller JWT prepare RPC | preserved | not runtime-tested |
| tenant/company server-side | strict DB predicates | preserved | not runtime-tested |
| cross-company isolation | strict predicates + generic denial + fence | preserved | not runtime-tested |
| no broad grant | authenticated prepare only; service release only | preserved | not runtime-tested |
| no frontend authority | request supplies target/password only | preserved | not runtime-tested |
| T1/T2 | no T1 disable; no T2 change | preserved | not reopened |
| frontend scope | no `App.jsx` diff | preserved | n/a |

“Addressed” is a candidate statement, not specialist PASS, deployment proof,
Ready authority or Security Go.

## 11. Required later acceptance matrix

```text
Edge-first while RPC absent                         FAIL CLOSED / NO AUTH MUTATION
root -> authorized target                           ALLOW
admin_local -> same-company non-root target         ALLOW
admin_local -> other company/admin identity         DENY
strict gestor -> ordinary broker own active team    ALLOW
gestor -> other team/company/protected target       DENY
ordinary/inactive/missing actor                      DENY
missing/out-of-scope target                          SAME EXTERNAL DENY
frontend empresa/role/flags/time                     IGNORED AS AUTHORITY
direct authenticated password-state PATCH           DENY
legacy/service/internal password-state write         DENY WITHOUT EXACT T3/SELF PATH
concurrent target promotion to admins                DENY WHILE LEASE EXISTS
concurrent actor/target company/role/status change   DENY WHILE LEASE EXISTS
concurrent gestor authority-team change              DENY WHILE LEASE EXISTS
pre-lease REPEATABLE READ authority writer           DENY VIA UNIQUE CONFLICT
actor/target cross-role lease overlap                 DENY
service_role TRUNCATE authority table                 DENY WHILE T3A ACTIVE
ambiguous Auth result                                KEEP LEASE / FAIL CLOSED
definitively rejected/mismatched release             KEEP LEASE / FAIL CLOSED
ambiguous release response                           NO SUCCESS / RECONCILE EXACT STATE
rollback with active/unresolved lease                STOP
rollback after any reviewed routine/object drift     STOP
```

## 12. Validation performed and remaining gates

Performed on the candidate source:

- read-only production catalog inventory and exact baseline digests;
- exact `prosrc` extraction reconciled against live known-function hashing;
- static SQL/catalog/concurrency review;
- SQL dollar-quote/parenthesis/top-level statement balance scan, byte-identical
  policy/column-ACL blocks, structurally identical routine-inventory cores with
  only their intentional exclusion sets differing, and Edge TypeScript syntax
  check;
- source checks for no broad grant, no T1 disable, no `IF EXISTS` rollback
  erasure and no `App.jsx` change.

Not performed:

- local Vite build: dependencies were unavailable and frozen pnpm install
  stopped on the repository's pre-existing `package.json` / `pnpm-lock.yaml`
  specifier mismatch; neither manifest nor lockfile was changed;
- migration or rollback execution on PostgreSQL 17;
- Edge deployment or runtime request;
- production smoke/concurrency test;
- Ready, merge or Security Go.

Required next gates on one new resolved exact head:

```text
1. integral material-file read and coverage reconciliation
2. repeat Backend/Data exact-head review
3. only after Backend/Data closure, independent AppSec exact-head review
4. stop before Ready pending separate Product Authority
```

T3A-v3 grants none of the remaining lifecycle or production authorities.
