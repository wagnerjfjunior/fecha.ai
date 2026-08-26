# FECH.AI — T3A-v6 Live Routine Inventory Anchor Refresh

**Status:** `PR129_MERGED / EDGE_V19_DEPLOYED / B1_V19_FAIL_BEFORE_AUTH_PASS / TWO_MIGRATION_ATTEMPTS_ABORTED_FAIL_CLOSED / LIVE_ROUTINE_ANCHOR_DRIFT / ANCHOR_REFRESH_EXACT_HEAD_REVIEWS_REQUIRED / SECURITY_GO_DENIED`
**Initial evidence date:** `2026-08-22`
**Corrective evidence dates:** `2026-08-23`, `2026-08-24`, `2026-08-25`
**Repository:** `wagnerjfjunior/fecha.ai`
**Original PR base:** `037232fe3da37a749ab980f783af92ff15e2baf2`
**Merged PR:** `#127`
**Reviewed/merged source head:** `a5c92617f372599a234c0147aad13a90649348d7`
**Reviewed/merged source tree:** `87872aac22b36437b7fb66f3614905e8df94f5ee`
**PR #127 merge commit:** `610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87`
**PR #128 reviewed head:** `b594218dabd9a7beaea3158bb143f5dd2fd71386`
**PR #128 reviewed tree:** `e36a00e671e8c8bce52b2e35f12beed165fad927`
**PR #128 merge commit / corrective base:** `3c9daf6c49eb937824c2c2b40aba198e2727c4bb`
**PR #129 reviewed head:** `6f6092aa66352cda3d617897895b0f09019adeea`
**PR #129 reviewed tree:** `bb13c051b57d1b04a1926cbe886b190cfa89ba37`
**PR #129 merge commit / anchor-refresh base:** `69f4cfa1bdee331826953b492f25c12b4defc030`
**Audit corrective branch:** `security/t3a-audit-schema-compatibility`
**Executability corrective branch:** `security/t3a-plpgsql-role-alias-collision`
**Routine-anchor corrective branch:** `security/t3a-live-routine-anchor-refresh`
**Initial blocked PR head:** `45ad27668835b6458b52d2fb592cfa36b5589726`
**Backend/Data reviewed heads:** `bf8fb1f4ab043226de3c77763b9b425a13b0261e`, `4631325827a76152ba554bece2a59da9eb1bb662`
**Last fully approved head before post-Ready finding:** `fcb7dfc2f5f2259926556652fa9cfd3443d0c214`
**Last fully approved tree before post-Ready finding:** `4dcaf2d4b6aa1248801e455def811e50ff04e414`
**PR #129 initial Backend/Data reviewed head:** `57b6828aee6d5301cf429bee63f6ff2c6a7d1c42`
**PR #129 initial Backend/Data response SHA-256:** `6440dddfa3ebabda877138230aff4ffd72eec98f969e2473db81842fa182efb4`
**PR #129 final Backend/Data response SHA-256:** `8d76512eadcaf54085e6109c83eb4a4e3b9499160537c85e741f7113d2b39b0f`
**PR #129 final AppSec response SHA-256:** `d096c474128e5099a16a90b5c4afc9922ffc4ff593b08680a8990b42177aa1ea`

PR #127 subsequently closed `DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`, received
fresh Backend/Data and independent AppSec approval on exact head `a5c92617...`,
and was merged. The separately-authorized Edge-first rollout deployed that
exact Edge as production version 18 and established fail-before-Auth. The same
runtime calls exposed a new, narrower incompatibility: the versioned audit
insert omitted live legacy NOT NULL columns `acao` and `entidade`.

T3A-v5 was the post-merge correction of that newly observed runtime drift. PR
#128 was necessary because PR #127 was merged; it was not an alternate PR or
workaround for the already closed B1-B4 blockers. The PR #127 approvals remained
valid evidence for the unchanged v4 boundary but did not approve the changed
Edge/audit ACL/fingerprint domain. PR #128 later received the required reviews,
merge and Edge-first validation recorded in §0.

## 0. 2026-08-25 production executability findings

PR #128 closed the audit compatibility blocker, received Backend/Data and
independent AppSec approval, and merged as
`3c9daf6c49eb937824c2c2b40aba198e2727c4bb`. Its exact Edge was deployed as
production v19. One controlled call returned HTTP 500 as expected, committed a
`password_reset_attempt` audit row with `status=edge_proof_unavailable`, and
produced no Auth mutation.

Product Authority then separately authorized one application of the exact
reviewed migration. It was invoked once and PostgreSQL 17 aborted at the first
role-attribute predicate:

```text
SQLSTATE 55000
record "r" is not assigned yet
```

The transaction had only acquired relation locks and entered the first
preflight `DO` block. It had not reached any T3 DDL. Post-failure read-only
verification established:

```text
T3 migration history entry: ABSENT
T3 routines: ABSENT
T3 relations: ABSENT
target auth.users row: ABSENT
production Edge v19: ACTIVE
audit rows for the controlled target: exactly 1
```

Root cause exists in four material blocks:

```text
forward preflight
forward postflight
rollback preflight
rollback postrollback
```

Each block declares `r record` for later `FOR r IN` loops and also aliases
`pg_catalog.pg_roles AS r`. PostgreSQL resolves `r.oid` and `r.rol*` to the
unassigned record. The correction changes only:

```text
pg_roles AS r       -> pg_roles AS role_row
r.oid / r.rol*      -> role_row.oid / role_row.rol*
```

The `r record` loop target and every expected value, digest, DDL statement,
grant, trigger, actor/tenant predicate and rollback operation remain unchanged.
No direct production SQL edit or retry is permitted. The corrected exact head
requires Backend/Data and then independent AppSec review.

The initial Backend/Data review of PR #129 accepted the SQL alias-collision
closure and preservation of B1-B4, but returned `REQUEST CHANGES` because the
current coverage matrix still carried pre-PR128 `v18 / v5 candidate` state.
That evidence contradiction was reconciled without changing either SQL or any
runtime artifact. Fresh Backend/Data and independent AppSec reviews then
approved exact head `6f6092aa66352cda3d617897895b0f09019adeea` / tree
`bb13c051b57d1b04a1926cbe886b190cfa89ba37`, and PR #129 merged as
`69f4cfa1bdee331826953b492f25c12b4defc030`.

The exact merged migration was then reauthenticated before a separately gated
second application:

```text
migration Git blob: 6cc9a1f4419de5e0355954f2cbc6f503f5eb8157
migration SHA-256: f7d36c397decdc14675b29060f26ca462dae07c62576ab1ccb43c77e7e372181
migration lines / bytes: 3550 / 135000
application invocations after PR #129 merge: 1
```

PostgreSQL passed the corrected role predicates and then stopped in the same
first preflight at the positive global routine inventory:

```text
SQLSTATE P0001
T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT
PL/pgSQL function inline_code_block line 386 at RAISE
```

This was not a replay of the alias collision. The preflight detected a new
catalog event and aborted before T3 DDL. Fresh read-only production queries
established:

```text
T3 migration history entry: ABSENT
T3 proof/lease relations: ABSENT
T3 issuer/prepare/release routines: ABSENT
production Edge v19: ACTIVE

reviewed routine baseline:
  count 264 / full inventory md5 b1f0919df8a0acaca7bbea2b928b0ffe
current live routine inventory:
  count 264 / full inventory md5 c299bf087df69f960dd0c611d1486675
authenticated-effective SECURITY DEFINER subset:
  count 122 / inventory md5 7faa376a403c69239d9606559cf9c2db
non-system aggregates:
  count 0
```

The only non-system routine whose tuple version is newer than the established
T1 anchor is the Supabase-owned event-trigger helper:

```text
extensions.grant_pg_graphql_access()
owner: supabase_admin
security mode: SECURITY INVOKER
event trigger: issue_pg_graphql_access / ddl_command_end / enabled O
xmin: 7208
implementation md5: 2f3fa32125a4cd4e597bc8b3c7b55218
prosrc md5: e2ca36b1a39e090c101c6d0f009b5d20
normalized ACL:
  PUBLIC>supabase_admin:EXECUTE:false,
  supabase_admin>supabase_admin:EXECUTE:false,
  postgres>supabase_admin:EXECUTE:true
```

It is not `SECURITY DEFINER`, so the authenticated-effective definer subset
remained byte-identical. The correction does not whitelist or exclude this
helper. It refreshes the complete full-catalog digest in all four places so
the same positive inventory continues to fail closed on any later body,
owner, language, kind, config, comment or ACL drift:

```text
forward preflight
forward postflight
rollback preflight
rollback postrollback

b1f0919df8a0acaca7bbea2b928b0ffe
-> c299bf087df69f960dd0c611d1486675
```

Counts, the authenticated-effective SECURITY DEFINER digest, the zero
aggregate assertion and every T3A authority/tenant/proof/lease/audit/T1
control remain unchanged. No direct production SQL edit or automatic retry
occurred.

## 1. Authorized and prohibited scope

T3A changes only the administrative password-reset boundary:

- `auth.uid()` is the actor;
- company, role, flags, team and protected-admin identity come from the server;
- root / admin_local / gestor authority remains strict;
- cross-company and missing-target results fail closed without enumeration;
- only the service-role-only issuer, called internally by the versioned Edge,
  can mint the opaque proof required before a caller-JWT preparation RPC may
  create durable state;
- the proof does not authorize actor/tenant/role/target; `auth.uid()` and
  server-side database state remain authoritative;
- a durable database lease fences the authority decision through the external
  Auth password mutation;
- `must_change_password=true` is established before Auth mutation;
- the stale direct authenticated password-state grant is revoked;
- the Edge writes both the modern and established legacy audit columns and
  fails before proof/Auth if that server-authored audit anchor cannot be made;
- the migration pins the complete live `audit_logs` relation and removes
  authenticated direct INSERT so client callers cannot forge server audit rows;
- both existing T1 triggers remain enabled;
- the exact pre-T3A T1 direct guard has a drift-aware restoration path;
- the versioned `criar-usuario` v17 source remains the Edge rollback anchor.

This change does not authorize or perform:

- an `App.jsx` change;
- a production migration or runtime mutation during this Draft/review action;
- a further Edge production deployment;
- a smoke or rollback execution;
- Ready, merge or Security Go;
- a broad grant, trigger disablement, data normalization or frontend authority.

Product Authority separately bounded one later migration invocation after the
two new exact-head reviews. That later authority does not make this PR, its
static review or any current GitHub action a production mutation.

## 2. Historical 2026-08-24 pre-PR128 production snapshot

The following read-only production state and bounded runtime evidence were
reconciled on `2026-08-24`, before PR #128 review/merge and the Edge v19
transition. It is retained as historical lineage and is superseded for current
state by §0:

```text
Supabase project: uobxxgzshrmbtjfdolxd / ACTIVE_HEALTHY / PostgreSQL 17
latest material migration: 20260822192552 f1_02_harden_status_corretor_rpc
public.t3_prepare_admin_password_reset(uuid,uuid): ABSENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): ABSENT
public.t3_admin_password_reset_edge_proofs: ABSENT
public.t3_admin_password_reset_leases: ABSENT
criar-usuario: v18 / ACTIVE / verify_jwt=false
live Edge Git blob: ec62997bc357b550feda5027051fe507fe9184fa
live Edge SHA-256: 11719575bce92c85422eb5d3a78ad26a5d683c47202e6db8032f3e13d5a254a7
T3A migration applied: NO
PR #127: MERGED
B1 fail-before-Auth runtime proof: PASS
audit schema compatibility: OPEN
```

The bounded reset attempt against an inactive dedicated test target emitted
three submissions while the browser appeared frozen. Each submission produced
the same fail-closed platform sequence:

```text
GET /auth/v1/user -> 200
GET /rest/v1/corretores -> 200
POST /rest/v1/audit_logs -> 400
POST /rest/v1/rpc/t3_issue_admin_password_reset_edge_proof -> 404
PATCH /rest/v1/audit_logs -> 204 (no row matched)
Edge POST -> 500
```

Auth logs contained only caller validation (`GET /user`), not an admin Auth
update. The target Auth `updated_at` and password fingerprint were unchanged;
there were zero target Auth mutations in the reset window. Therefore B1 is
runtime-proven for v18, while the failed audit anchor remains a material rollout
blocker.

Live `public.audit_logs` has 20 columns. `acao` and `entidade` are NOT NULL with
no default, and `ip_address` is `inet`. Complete relation fingerprints are:

```text
pre-T3A baseline: 5d3b70257c57f5956032e83131effabb
post-T3A after authenticated INSERT revocation: 1b1a381796f273b503cd4c41d34a3688
```

T3A-v5 supplies both modern and legacy audit fields, validates audit insertion
before proof/prepare/Auth, conservatively normalizes the `inet` value, pins the
complete audit relation/ACL/policy/index/constraint surface in migration and
rollback, revokes authenticated INSERT during T3A, and restores that exact
legacy grant on rollback. No SQL, migration, further Edge deploy or runtime
mutation was performed while preparing this candidate. No PII was required.

## 3. Exact-head review lineage

The first manual Backend/Data response was integral and bound to:

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

The lease/fence candidate was then published and a second integral manual
Backend/Data review read the exact ten material blobs to EOF:

```text
reviewed head: 4631325827a76152ba554bece2a59da9eb1bb662
tree: 843bbc9c9f32f07e97713368e7e472fca9e650cd
files / lines: exact 10 / 6744
manual response SHA-256:
  1ab2b39d52536b0ba92cd25df4d91b808f25abd08be0c5de72146113c7cda544
verdict: REQUEST_CHANGES
B1: PASS
B2: FAIL
B3: FAIL
B4: PASS (static)
HIGH-1: CLOSED
HIGH-2: OPEN
```

It accepted the durable lease/fence concurrency design and identified three
remaining positive-closure gaps: unilateral membership checking, omission of
`prokind='a'` aggregates, and incomplete `public` schema ACL checking. The
next candidate corrected those three findings. Backend/Data then read all ten
material files on exact head `fcb7dfc2...` / tree `4dcaf2d4...` and returned
`APPROVE` with B1-B4 PASS and no findings (manual response SHA-256
`8b6bf96691b7337df95f0350ac5028a4aeb85e6cab917ec56383fc8e083ac0dc`).
Independent AppSec authenticated a byte-preserving bundle, read all ten PR
files plus both T1 supplements to EOF and returned exact-head `APPROVE` (manual
response SHA-256
`1df5df13786f7ba767340cca2ca546aeddbf92e81a307a48aef3107fc0cf64ca`).

After Product Authority separately authorized Ready, the GitHub Codex review
opened unresolved P2 `DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE` at the
`authenticated` grant for the preparation RPC. Integral source validation
confirmed the exploit path:

```text
authorized root/admin_local/gestor calls prepare directly through PostgREST
-> durable no-expiry lease commits
-> must_change_password=true commits
-> no Auth password mutation occurs
-> caller cannot execute the service-role-only release
-> T3 fence rejects the target's self-service true->false completion
-> actor/target/team authority rows remain fenced pending privileged recovery
```

The PR was returned to Draft without merge at that point. T3A-v4 closes the direct-call path
with a service-role-only opaque one-time Edge-proof issuer and a caller-JWT
prepare that must atomically consume the matching unexpired proof before any
lock, lease or password-state mutation. The proof is not actor authority; all
root/admin_local/gestor, company, target and team decisions remain inside the
prepare RPC under `auth.uid()`.

Fresh integral Backend/Data and independent AppSec reviews then approved exact
head `a5c92617f372599a234c0147aad13a90649348d7` / tree
`87872aac22b36437b7fb66f3614905e8df94f5ee` with no findings. PR #127 was
merged as `610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87`. Those approvals remain the
unchanged v4 authority-boundary anchor. The audit compatibility code and audit
ACL/fingerprint changes in v5 are a new material review domain.

## 4. B1 — safe rollout and failure ordering

The v4 Edge-first step was separately authorized and completed. Production v18
failed before Auth on absent proof RPCs, but its audit insert returned 400.
PR #128 then closed that audit incompatibility and the first three rollout
transitions completed. The reconciled sequence is:

```text
1. PR #128 Backend/Data + independent AppSec exact-head approval       DONE
2. deploy that exact reviewed Edge while issuer/prepare remain absent  DONE / v19
3. prove audit INSERT + issuer absent/404 + no Auth mutation           PASS
4. invoke PR #128 exact migration under separate authority             ABORTED / ALIAS COLLISION / NO DDL
5. correct alias, review and merge PR #129                             DONE / 69f4cfa1...
6. invoke exact PR #129 migration once                                 ABORTED / ROUTINE DRIFT / NO DDL
7. refresh all four full-routine digests to current live inventory     CURRENT DRAFT PR
8. obtain Backend/Data then independent AppSec exact-head reviews      REQUIRED
9. resolve Ready/merge as separate GitHub lifecycle gates              BLOCKED
10. apply the final exact reviewed/merged migration once               AUTHORIZED LATER / PRECONDITIONS OPEN
11. validate catalog/roles/routines/ACLs/grants/policies/triggers      BLOCKED
12. run separately-authorized cross-tenant/concurrency smoke           BLOCKED
```

The v5 Edge first requires a successful service-role audit insert containing
both modern and legacy fields. Only then does it call the service-role-only
`t3_issue_admin_password_reset_edge_proof` RPC, then passes the normalized proof
only to the caller-JWT `t3_prepare_admin_password_reset` RPC before
`auth.admin.updateUserById`. Missing issuer/prepare RPC, proof mismatch/expiry,
denial, malformed response or absent lease ID returns a generic failure before
Auth. The proof never leaves the Edge-to-database path.

The requested target, returned proof and returned lease UUIDs are canonicalized
and validated before comparison/use, preventing equivalent UUID spellings from
creating an ambiguous proof or stranded lease.

If proof issuance commits but preparation never succeeds, only an inert bounded
proof remains; it fences no business row and later server-side cleanup removes
it after two minutes. If preparation committed but its response is lost, the Edge still performs no
Auth mutation and cannot guess a lease identity; the durable lease remains for
separately-authorized recovery.

After authorization, Auth is called while the durable lease remains committed.
The service-role client releases only the exact lease after a proven successful
Auth response. Any ambiguity in the Auth call or result leaves the lease in place;
the Edge returns a generic failure and does not improvise cleanup. Release
transport ambiguity occurs only after proven Auth success and is reconciled as
described in §8. A stuck lease is an availability incident requiring separate
recovery authority, not an authorization gap.

The inverse migration-first order was prohibited while v18 was live. Production
v19 now preserves the reviewed fail-before-Auth ordering while the corrected
migration, postflight and later runtime gates remain blocked.

## 5. B2 — exact positive trust-anchor preflight

The migration holds `admins`, `corretores`, `times` and then `audit_logs` in
`SHARE` mode through preflight, DDL and postflight. The authority-to-audit order
matches existing audit-trigger writers. Before mutation it verifies:

- exact postgres/client-role attributes plus exact `authenticator`
  NOINHERIT/login and `pg_database_owner` NOLOGIN attributes;
- the complete live `pg_auth_members` graph, including granted role, member,
  grantor, `admin_option`, `inherit_option` and `set_option`;
- exact current-database owner, `public` schema owner and complete effective
  schema ACL, while retaining direct no-CREATE/client-USAGE assertions;
- `auth.uid()` owner, security mode, volatility, return/signature, body and
  effective EXECUTE surface;
- authority tables, exact required column types, RLS and FORCE RLS;
- the complete live `audit_logs` metadata, table/column ACLs, all 20 columns,
  constraints, indexes and policies under baseline fingerprint
  `5d3b70257c57f5956032e83131effabb`, plus exact effective client/service
  privileges;
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
- absence of every T3 proof/lease/function/trigger name and context-key collision;
- the exact positive non-system routine inventory described below.

The old direct writer regex is removed. Instead the complete reviewed live
non-system routine catalog — functions, procedures, aggregates and window
functions — is serialized by stable signature plus owner, language, kind,
security mode, volatility/parallel/leak/strict/set-returning flags, return type,
config, implementation hash and normalized ACL:

```text
baseline routines, excluding only the separately-pinned direct T1 guard:
  count = 264
  inventory_md5 = c299bf087df69f960dd0c611d1486675

authenticated-effective SECURITY DEFINER subset:
  count = 122
  inventory_md5 = 7faa376a403c69239d9606559cf9c2db

non-system aggregates included in that inventory:
  count = 0
```

This positive inventory spans all non-system schemas, not just `public`. It
pins wrappers, dynamic-SQL-capable routines and possible transitive callees even
when their source does not contain the target table/column literals. The
explicit zero-aggregate assertion is positive: a newly introduced non-system
aggregate changes both the routine inventory and aggregate count. Postflight
and rollback exclude only the exact new T3 functions — including the Edge-proof
issuer — and separately verify each body, signature, owner, config, comment and
effective ACL.

The prior reviewed full-inventory digest
`b1f0919df8a0acaca7bbea2b928b0ffe` is retained only as historical evidence.
The current digest `c299bf087df69f960dd0c611d1486675` includes the exact
live `extensions.grant_pg_graphql_access()` fingerprint rather than excluding
or broadly trusting that platform helper.

Role/schema anchors are positive and complete:

```text
full pg_auth_members graph:
  count = 21
  inventory_md5 = fb803a204209bc71074a1eee7b57944e
current database / owner = postgres / postgres
public schema owner = pg_database_owner
only public ACL CREATE grantee = pg_database_owner -> database owner postgres
complete effective public schema ACL:
  count = 7
  inventory_md5 = e2ad94b6bfb9b0cb8c4980459fd55a6e
```

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

The caller-JWT prepare RPC accepts `p_target_user_id` plus the opaque
`p_edge_proof_id` received internally from the Edge. The client/frontend never
supplies the proof. Frontend company, role, flags, team and time are not
authority inputs.

## 7. B4 and HIGH-1 closure — leased T1 interoperability

At runtime the service-role-only issuer first creates an opaque proof bound to
the Edge-verified caller UUID and requested target UUID. The proof table has
RLS + FORCE RLS, no policies or client/service table privileges, unique proof
and actor keys, an exact target binding and PostgreSQL-derived creation time.
Issuance rotates only that same actor's prior proof; there is no target-wide
reservation an unauthorized caller could use against another actor. The proof
grants no role, tenant or target authority. The caller-JWT preparation RPC must delete the
exact matching proof within two server-side minutes before any durable lease or
password-state mutation. A random, missing, expired, wrong-actor or wrong-target
proof fails closed.

After proof consumption, the preparation RPC obtains one
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

The issuer ACL is a trusted server-credential anchor, not cryptographic
attestation of an exact Edge binary. The versioned Edge is its intended runtime
caller; direct anon/authenticated callers have no EXECUTE. The service-role
proof issuer can create only an inert bounded proof; it cannot
call the authenticated prepare RPC, derive authority, create a durable lease or
set password state. The service-role release RPC can only delete one exact
`lease_id + actor_user_id + target_user_id` row. It cannot create a lease,
authorize a target, set password state or substitute for `auth.uid()`.

Exact candidate PL/pgSQL `prosrc` fingerprints:

```text
t3_issue_admin_password_reset_edge_proof(...):    87f8d7f0c96ce4ae52fed9e2bc4bdcdd
t3_prepare_admin_password_reset(uuid,uuid):        f9bd114c7eb77313e22861816b8a88f5
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
-> service-role-only issuer mints opaque caller+target Edge proof
-> caller-scoped RPC consumes proof before durable state
-> caller-scoped RPC derives actor/tenant/role/team server-side from auth.uid()
-> serialize authority tables
-> create durable exact actor + target + optional authority-team lease
-> set must_change_password=true through both enabled T1/T3 guards
-> commit and return user_id + lease_id
-> service-role Auth client changes that exact user password
-> only proven Auth success permits exact service-role lease release
```

At no point is service_role the actor. Proof issuance establishes only that the
server-only issuer ACL was traversed; it does not attest the exact Edge binary.
Prepare still derives and decides all authority using `auth.uid()` and database
state. Any Auth ambiguity leaves the lease and
all material database authority mutations fenced. Release is attempted only
after proven Auth success; a lost release response may mean either that the
exact safe release committed or that the lease remains. The Edge claims no
success, does not retry blindly and requires state reconciliation.

## 9. B3 — drift-safe rollback

Rollback begins by locking the proof table, three authority tables, lease table
and audit table in fixed `proof -> authority -> lease -> audit` order and in
`SHARE` mode. This matches prepare plus existing authority-audit trigger writer
direction and avoids a reciprocal relation-lock cycle. Edge audit and proof
HTTP calls commit separately and do not hold the opposite lock pair.
It stops before destructive work when:

- an unexpired Edge proof exists;
- a lease exists;
- the proof table schema/owner/RLS/FORCE/ACL/constraints/comment differs;
- the lease table schema/owner/RLS/FORCE/ACL/constraints/comment differs;
- any T3 function body/owner/security/config/ACL/comment differs;
- the exact seven-trigger T3A authority inventory differs, including any
  absent/changed/disabled fence, T1 or audit trigger, or any rewrite rule;
- the T3-aware direct guard or either original T1 trigger differs;
- role attributes or the complete membership graph, database/schema ownership,
  complete `public` ACL, `auth.uid()`, helpers, legacy writer, audit objects,
  policies, grants, indexes, context use or positive full routine inventory
  including the zero-aggregate assertion differs.
- the complete post-T3A audit relation differs from fingerprint
  `1b1a381796f273b503cd4c41d34a3688` or authenticated INSERT has reappeared.

Only after the complete exact preflight does it remove proofs older than the
same two-minute validity boundary and prove the locked proof table empty. It
then atomically:

```text
restore exact pre-T3A direct guard (99477024...)
-> drop the three proven fencing triggers
-> drop exact fence, proof-issuer, prepare and service-release functions without IF EXISTS
-> drop exact empty proof table
-> drop exact empty lease table
-> restore only authenticated UPDATE(must_change_password)
-> restore only the pinned legacy authenticated audit INSERT grant
-> restore only the pinned service_role TRUNCATE baseline on the three tables
-> verify exact pre-T3A guard/grant/policy/inventory/audit fingerprint and T3 absence
```

No business row or Auth credential is rewritten. Database rollback remains
first; hardened Edge then fails closed on absent proof issuer before prepare or Auth. Restoring Edge v17
is a later separately-authorized step.

## 10. B1-B4 coverage matrix

| Blocker / invariant | Corrective artifact | Recorded result | Runtime result |
|---|---|---|---|
| B1 Edge-first rollout | v19 audit-first fail-before-Auth on absent issuer/prepare | PR #128 exact-head reviews approved | v19 PASS / audit committed / no Auth mutation |
| B2 trust-anchor preflight | exact full role graph + public schema ACL + all routine kinds + complete audit relation fingerprints | alias fix approved/merged; four full-inventory literals refreshed to the current live digest; exact-head review pending | second application correctly stopped on routine drift / no DDL |
| B3 drift-safe rollback | same exact anchors + proof→authority→lease→audit order + no live proof/lease + exact grant reversal | alias fix approved/merged; the same live digest refresh is applied to rollback pre/postflight; exact-head review pending | not executed |
| B4 T1 interoperability | both T1 triggers + exact leased transitions | approved and unchanged from v4 | not executed |
| DB→Auth authority continuity | durable lease + snapshot-independent unique-index probes + 3 fencing triggers + service-role TRUNCATE removal + success-only release | approved and unchanged from v4 | not runtime-tested |
| direct PostgREST prepare / stranded lease | service-role-only one-time Edge proof consumed before lease/write | approved and unchanged from v4 | issuer absent; no direct runtime bypass tested |
| audit schema compatibility | dual modern/legacy Edge insert + normalized inet + fail-before-proof/Auth + exact audit fingerprints | PR #128 Backend/Data + AppSec exact-head approved and merged | v19 PASS / audit committed / no Auth mutation |
| audit integrity | revoke authenticated INSERT; preserve authenticated SELECT; exact rollback restore | PR #128 exact-head approved; SQL semantics unchanged by PR #129 and the digest-only refresh | migration absent / no DDL applied |
| actor=`auth.uid()` | caller JWT prepare RPC | preserved | not runtime-tested |
| tenant/company server-side | strict DB predicates | preserved | not runtime-tested |
| cross-company isolation | strict predicates + generic denial + fence | preserved | not runtime-tested |
| no broad grant | authenticated prepare requires opaque Edge proof; service issue/release only | preserved | not runtime-tested |
| no frontend authority | request supplies target/password only | preserved | not runtime-tested |
| T1/T2 | no T1 disable; no T2 change | preserved | not reopened |
| frontend scope | no `App.jsx` diff | preserved | n/a |

PR #128 exact-head reviews, merge, Edge v19 deployment and the controlled
fail-before-Auth call close the audit-schema compatibility rollout blocker.
They do not prove execution of the migration or rollback and do not grant the
new anchor-refresh PR Ready, merge, runtime smoke or Security Go. Product
Authority authorized one later migration retry after the two new exact-head
reviews; that authority is not exercisable until the reviewed bytes and the
separate GitHub lifecycle prerequisites are resolved.

## 11. Required later acceptance matrix

```text
Edge-first while proof issuer/prepare absent        PASS / FAIL CLOSED / NO AUTH MUTATION
v19 Edge audit anchor while proof RPCs absent        PASS / INSERT COMMITTED / STATUS RECORDED / NO AUTH MUTATION
malformed/unavailable audit anchor                   FAIL BEFORE PROOF / NO AUTH MUTATION
direct authenticated audit INSERT after migration   DENY
direct prepare without valid Edge proof             DENY / NO LEASE / NO FLAG WRITE
random/expired/wrong-actor/wrong-target proof       DENY / NO LEASE / NO FLAG WRITE
abandoned pre-prepare proof                         INERT / NO FENCE / SERVER CLEANUP
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
rollback with unexpired Edge proof                   STOP
rollback with expired inert Edge proof               CLEAN AFTER EXACT PREFLIGHT
rollback after any reviewed routine/object drift     STOP
```

## 12. Validation performed and remaining gates

Performed across the reviewed lineage and current candidate source:

- read-only production catalog inventory and exact baseline digests;
- full 21-edge membership graph, exact database/schema ownership, complete
  seven-entry `public` ACL and positive zero non-system aggregate observation;
- exact `prosrc` extraction reconciled against live known-function hashing;
- static SQL/catalog/concurrency review;
- SQL dollar-quote/parenthesis/top-level statement balance scan, byte-identical
  policy/column-ACL blocks, structurally identical routine-inventory cores with
  only their intentional exclusion sets differing, and Edge TypeScript syntax
  check;
- source checks for no broad grant, no T1 disable, no `IF EXISTS` rollback
  erasure and no `App.jsx` change.
- read-only live confirmation of all 20 audit columns and types, exact required
  legacy fields, ACL/policy/index/constraint inventories and complete baseline /
  hypothetical post-revoke fingerprints;
- TypeScript syntax, whitespace, SQL lexical/dollar-quote/parenthesis and
  top-level transaction balance for the v5 correction.
- PR #128 exact-head Backend/Data and independent AppSec reviews, merge and
  deployment of its exact Edge as production v19;
- one controlled v19 fail-before-Auth request with committed audit status,
  absent issuer response and no Auth mutation;
- one separately-authorized migration invocation, aborted by PostgreSQL 17 in
  the first preflight before T3 DDL;
- static Backend/Data acceptance of the PR #129 alias correction, followed by
  `REQUEST CHANGES` only for the then-reconciled evidence-state contradiction;
- fresh Backend/Data and independent AppSec approval of PR #129 exact head
  `6f6092aa...`, followed by merge commit `69f4cfa1...`;
- one reauthenticated application of the exact merged PR #129 migration,
  aborted fail-closed at `T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT`
  before DDL;
- fresh read-only production recomputation of the complete routine inventory
  (`264 / c299bf087df69f960dd0c611d1486675`), unchanged authenticated-effective
  SECURITY DEFINER subset (`122 / 7faa376a403c69239d9606559cf9c2db`), zero
  aggregates and exact changed helper fingerprint;
- fresh read-only confirmation that no T3 history entry, routine or relation
  exists and Edge v19 remains active.

Not performed:

- local Vite build: dependencies were unavailable and frozen pnpm install
  stopped on the repository's pre-existing `package.json` / `pnpm-lock.yaml`
  specifier mismatch; neither manifest nor lockfile was changed;
- successful completion/postflight of the corrected migration on PostgreSQL 17;
- rollback execution;
- any Edge deployment or runtime request after the controlled v19 call;
- post-migration production smoke/concurrency testing;
- anchor-refresh PR Ready, merge or Security Go.

Required next gates on the final resolved anchor-refresh PR exact head:

```text
1. integral material-file read and coverage reconciliation
2. repeat Backend/Data exact-head review after this evidence correction
3. only after Backend/Data closure, independent AppSec exact-head review
4. stop before Ready; Ready and merge remain separate GitHub lifecycle gates
```

T3A-v5 grants none of the remaining lifecycle or production authorities.

## 13. Live routine-anchor refresh coverage and remaining gates

Changed material scope:

```text
supabase/migrations/20260822211600_t3_admin_password_reset_boundary.sql
  preflight and postflight full routine inventory md5 only
  candidate Git blob: 1b938b95107bd4f6ab1d14d914438e654fcc1011
  candidate SHA-256: b9f55d58ea73c723a04075ab639bf1f6910b07d77774dfd5b593010d8de56d77
  lines / bytes: 3550 / 135000
supabase/rollback/20260822211600_t3_admin_password_reset_boundary_rollback.sql
  preflight and postrollback full routine inventory md5 only
  candidate Git blob: a9457bc48724cc8406bcec9348a14cbc8b868be3
  candidate SHA-256: bc8ea4aaca436aa78a25de29b8511d4d15b36a15ece32cc8a85b164153251ba7
  lines / bytes: 2785 / 107387
directly-related evidence/SFJM only
```

Mechanical reverse substitution of only
`c299bf087df69f960dd0c611d1486675` back to
`b1f0919df8a0acaca7bbea2b928b0ffe` reproduces the exact PR #129 merged SQL
blobs `6cc9a1f...` and `afce77ab...` respectively.

Explicitly unchanged:

```text
criar-usuario Edge source
App.jsx
T1/T2 migrations
the PR #129 role_row alias correction
function bodies created by T3A
all catalog fingerprints except the one complete full-routine digest
routine count, authenticated-effective SECURITY DEFINER count/digest and
  aggregate count
grants, policies, trigger definitions and lock order
actor=auth.uid()
server-derived tenant/company/role/team
proof/lease/fence design
```

Required next gates:

```text
1. resolve the final corrective Draft PR exact head
2. integral read of all changed final artifacts
3. Backend/Data exact-head review
4. independent AppSec exact-head review only after Backend/Data closure
5. stop before Ready
```

Ready and merge remain separate blocked lifecycle gates. One production
migration retry is authorized only after the two reviews and authentication of
the final reviewed/merged bytes; smoke, rollback and Security Go remain
separately blocked.
