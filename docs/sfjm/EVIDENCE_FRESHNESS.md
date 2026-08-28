# FECH.AI — SFJM Evidence Freshness

**Status:** `SECURITY_TO_SCALE_2026 / M0_EVIDENCE_RECONCILED / HISTORICAL_LEDGER_PRESERVED`
**Updated:** `2026-08-28`
**Repository:** `wagnerjfjunior/fecha.ai`

## 0. M0 current evidence map — 2026-08-28

This section is the current evidence-class reconciliation. The older sections below are preserved as historical claim/anchor lineage. They do not become current merely because they remain versioned.

Current GitHub anchors observed:

```text
main: 8ad6b7ec493b363922168e22afd188577bdfa5c9
Issue #141: OPEN
Issue #142: OPEN
#139: 32003e75a28e235fb454d39e3e4459d0f03acb2b / ACTIVE
#140: 3aed206883d7aa7ac76c8d48ffb09d677c848bba / ACTIVE
#149: resolve live / ACTIVE / DOCUMENTATION_ONLY_READY / self-referential publication PR; Ready authorized/executed, merge separate
#131: b9cb671e6fae8125a12b31454395b2a418e7cd17 / STALE_CONTINUITY
#124: 5e5cc76dae2da93472643e585d3311c92e79e4e6 / STALE_CONTINUITY
#120: 2b3ea57583f1fa54930191f02dc18c60997b9794 / SUPERSEDED
```

PR #139 review-thread evidence:

```text
source: live GitHub review-thread metadata
threads observed: 6
isResolved=false: 6
severity: 3 P1 + 3 P2
class: LIVE_GITHUB_METADATA
```

M0 specialist evidence — pre-publication analytical reconciliation:

```text
consultation channel: MANUAL_COPY_PASTE
specialist role: documentation_audit -> documentation-auditor
specialist response class: INFORMATION_SUPPLIED / MANUAL_SPECIALIST_OUTPUT
response artifact SHA-256:
  a866de230f09dd6c8ca90005f848d0febe40e0eb70fa8af0863902306512866c

reviewed project anchor:
  repository: wagnerjfjunior/fecha.ai
  main: 8ad6b7ec493b363922168e22afd188577bdfa5c9
  Issues: #141 / #142

reviewed open-PR universe at that time:
  #139 / #140 / #131 / #124 / #120

reviewed continuity scope:
  docs/sfjm/INDEX.md
  docs/sfjm/CURRENT_STATE.md
  docs/sfjm/NEXT_SAFE_ACTION.md
  docs/sfjm/AUTHORIZATIONS.md
  plus the material SFJM continuity evidence needed for the M0 reconciliation

specialist effective-scope result:
  M0 analytical reconciliation: SUFFICIENT
  Supabase: NOT_ACCESSED
  SQL: NOT_EXECUTED
  runtime: NOT_ACCESSED_OR_MUTATED

specialist limitation:
  its available GitHub REST evidence surface did not expose authoritative
  review-thread resolved/unresolved flags for PR #139

independent gap closure after the specialist response:
  live GitHub review-thread metadata on 2026-08-28 established
  #139 head 32003e75a28e235fb454d39e3e4459d0f03acb2b
  6 threads / 6 isResolved=false / 3 P1 + 3 P2
```

This manual specialist artifact validates the **M0 analytical reconciliation**, not the later exact-head contents of PR #149. PR #149 receives its own independent exact-head read/diff/review validation and must not inherit specialist PASS by implication.

Evidence semantics:

| Class | Required basis | Does not prove |
|---|---|---|
| `STATIC_IMPLEMENTATION_REVIEW` | exact-head source/diff/final-file review | applied DB, deployment or runtime |
| `LIVE_DATABASE_VALIDATED` | direct bounded live DB/catalog observation | runtime paths or future state |
| `CONTROLLED_RUNTIME_PASS` | actually executed bounded behavior | untested paths or Security Go |
| `NOT_EXECUTED` | planned/versioned without execution proof | behavioral PASS |
| `PR_HEAD_ONLY` | evidence only on an unmerged PR head | current canonical main/live truth |

```text
STATIC != LIVE
LIVE != RUNTIME
RUNTIME_BOUNDED != SECURITY_GO
PR_BODY_CLAIM != INDEPENDENT_PROOF
```

No Supabase or runtime operation was executed as part of M0. Historical production/catalog evidence below is therefore `LIVE_AT_CAPTURE`, not a fresh 2026-08-28 live-database validation.

## 1. Freshness model

Evaluate each material claim by:

```text
claim
object
anchor
environment
invalidation event
```

Do not infer freshness from `main` movement alone.

```text
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
```

## 2. T1 status-boundary production anchor

Claim:

```text
T1 corretor status authority boundary is applied in Supabase production and remains a material dependency for T3A.
```

Environment:

```text
Supabase project: uobxxgzshrmbtjfdolxd
Environment: production
Migration record:
  version: 20260822192552
  name: f1_02_harden_status_corretor_rpc
```

Fresh read-only production revalidation on 2026-08-23 established:

```text
public.t3_prepare_admin_password_reset(uuid): ABSENT
public.t3_prepare_admin_password_reset(uuid,uuid): ABSENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): ABSENT
public.t3_admin_password_reset_edge_proofs: ABSENT
public.marcar_senha_inicial_definida() md5:
  2a7b28d4bb6342a99d075c4d3c49af4d
authenticated UPDATE columns on public.corretores:
  apto_para_receber
  ativo
  must_change_password
T1 triggers:
  trg_t1_guard_corretores_authority_update: PRESENT / ENABLED
  trg_t1_guard_corretores_direct_compat_update: PRESENT / ENABLED
```

Additional live function anchors observed during T3A red-team:

```text
t1_guard_corretores_authority_update() md5:
  5e69ae5cb6717f634d758cfd5c1cd7a6

t1_guard_corretores_direct_compat_update() md5:
  99477024e337de5645dd042a30f8cf78

audit_trail_log_corretores_critical_update() md5:
  3fdaca39d55f348ca36f796023f3260b
```

Material T3A interaction:

```text
t1_guard_corretores_direct_compat_update()
currently denies gestor-originated must_change_password transitions.
```

Invalidate/revalidate the affected T3A compatibility claim if either T1 guard body, trigger binding/enabled state, corretores ACL/policy, relevant role contract or T3A design changes.

## 3. T2 frontend status-cutover anchor

Claim:

```text
the active App.jsx status-edit flow routes ativo/apto_para_receber through atualizar_status_corretor rather than the prior direct status PATCH.
```

GitHub code anchor at transition time:

```text
main commit: 037232fe3da37a749ab980f783af92ff15e2baf2
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

Controlled positive runtime smoke evidence from the current operating session established:

```text
apto isolated toggle + restoration: PASS
ativo isolated toggle + restoration: PASS
combined ativo/apto toggle + restoration: PASS
unchanged field represented as null in isolated RPC calls: PASS
RPC responses: ok=true
captured direct status PATCH: ZERO
```

Evidence limitation:

```text
HAR/runtime evidence was inspected in the operating conversation and is not yet a canonical repository artifact.
This proves the bounded positive flows observed, not an exhaustive role/cross-tenant adversarial matrix.
```

Invalidate/revalidate after material `src/App.jsx` blob change in the status flow, status RPC contract/ACL change, contradictory runtime evidence or relevant deployment replacement.

## 4. Administrative password residual anchor

Claim:

```text
the current App.jsx still contains a stale administrative post-reset direct write of must_change_password=false.
```

Anchor:

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
callsite: EditarCorretorModal.redefinirSenha()
```

This remains a T3A/T3B dependency. It must not be interpreted as legitimate authority merely because the code exists.

Invalidate after that callsite/blob changes.

## 5. T3A blocked-head lineage and corrective invalidation

Initial reviewed candidate object anchors:

```text
supabase/functions/criar-usuario/index.ts
  blob: 84c6f23d115cdae966b377f76289a03e5940b45c

supabase/migrations/20260822211600_t3_admin_password_reset_boundary.sql
  blob: 6ab6b94433032d594236257c456a196fd2935b44

supabase/rollback/20260822211600_t3_admin_password_reset_boundary_rollback.sql
  blob: 25723b9d13af9d9a0df82772ca2c8c9cd8ab771c

initial exact PR head reviewed:
  d51340766c3eb8bc3fa0977d327ce229218aaaa3

PR_HEAD_ONLY SFJM transition head before corrective implementation:
  45ad27668835b6458b52d2fb592cfa36b5589726
```

Review result on that initial candidate:

```text
REQUEST CHANGES

B1 safe rollout ordering: FAIL
B2 trust-anchor preflight: FAIL
B3 drift-safe rollback: FAIL
B4 T1 guard interoperability: newly discovered BLOCKING
```

Any corrective change to a material T3A artifact invalidates the prior exact-head gate by design. The next gate must resolve the new live head and read the final material files again.

Do not preserve a partial PASS across head movement.

The next corrected exact head reached
`bf8fb1f4ab043226de3c77763b9b425a13b0261e` (tree
`7f5ad06ed27ae1fb724175dd5f30af1e7135010b`). A manually relayed integral
Backend/Data review bound to that exact head read all ten files and returned:

```text
REQUEST_CHANGES
B1: PASS
B2: FAIL — direct prosrc writer regex is not transitive/authoritative
B3: FAIL — rollback repeats the non-transitive writer check
B4: PASS for the static DB transaction
HIGH-1: DB locks end before external Auth mutation
HIGH-2: positive exact routine/writer inventory required
```

This response is fresh evidence about `bf8fb1f...`, but every corrective code
change after it invalidates the response as a final-head gate. It is not an
AppSec result and authorizes no lifecycle transition.

The next v3 exact head reached
`4631325827a76152ba554bece2a59da9eb1bb662` (tree
`843bbc9c9f32f07e97713368e7e472fca9e650cd`). A second manually relayed integral
Backend/Data review read the exact ten blobs / 6744 lines to EOF and returned:

```text
REQUEST_CHANGES
B1: PASS
B2: FAIL — membership, aggregate and public-schema closure incomplete
B3: FAIL — rollback repeats those incomplete trust anchors
B4: PASS (static)
HIGH-1: CLOSED
HIGH-2: OPEN
manual response SHA-256:
  1ab2b39d52536b0ba92cd25df4d91b808f25abd08be0c5de72146113c7cda544
```

This is fresh evidence about `46313258...` and materially accepts the v3
lease/fence concurrency analysis. The membership/aggregate/schema correction
then reached exact head `fcb7dfc2f5f2259926556652fa9cfd3443d0c214` / tree
`4dcaf2d4b6aa1248801e455def811e50ff04e414`. Integral Backend/Data and
independent AppSec review both returned `APPROVE`:

```text
Backend/Data response SHA-256:
  8b6bf96691b7337df95f0350ac5028a4aeb85e6cab917ec56383fc8e083ac0dc
AppSec response SHA-256:
  1df5df13786f7ba767340cca2ca546aeddbf92e81a307a48aef3107fc0cf64ca
```

After separately-authorized Ready, the GitHub Codex review opened material P2
`DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`. Source validation confirmed that the
authenticated one-argument prepare RPC was directly callable through
PostgREST, could commit the durable lease and `must_change_password=true`
without an Auth mutation, and exposed no release path to that caller. The PR
was returned to Draft without merge. This finding invalidates both `fcb7dfc2...`
approvals as final-head gates in the affected domain.

T3A-v4 changes Edge, migration, rollback and evidence so the service-role-only
issuer mints an opaque actor+target Edge-presence proof and the caller-JWT
two-argument prepare consumes that exact unexpired proof before any locks,
lease or password-state write. The changed head requires a fresh Backend/Data
review and, only after closure, independent AppSec.

Corrected v4 candidate body/inventory anchors now recorded in this change set:

```text
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid):
  prosrc md5 87f8d7f0c96ce4ae52fed9e2bc4bdcdd

public.t3_prepare_admin_password_reset(uuid,uuid):
  prosrc md5 f9bd114c7eb77313e22861816b8a88f5

public.t3_release_admin_password_reset_lease(uuid,uuid,uuid):
  prosrc md5 a51c5b360c5d8a3684a97271460ec249

public.t3_guard_admin_password_reset_lease():
  prosrc md5 bd611e591aa2d951b178853f78caaa65

T3-aware t1_guard_corretores_direct_compat_update():
  prosrc md5 951da8a6ac6e934828f06ab1513778fa

exact pre-T3A guard restored by rollback:
  pg_get_functiondef md5 99477024e337de5645dd042a30f8cf78

historical reviewed non-system routine baseline excluding the direct guard:
  count 264 / inventory md5 b1f0919df8a0acaca7bbea2b928b0ffe

authenticated-effective SECURITY DEFINER subset:
  count 122 / inventory md5 7faa376a403c69239d9606559cf9c2db

non-system aggregates included by prokind='a':
  count 0

full pg_auth_members graph (role/member/grantor + admin/inherit/set options):
  count 21 / inventory md5 fb803a204209bc71074a1eee7b57944e

database/public schema:
  current database postgres / owner postgres
  public owner pg_database_owner
  complete effective ACL count 7 / md5 e2ad94b6bfb9b0cb8c4980459fd55a6e

lease-table constraint shape:
  unique lease_id, actor_user_id and target_user_id; authority_time_id unique when non-null
  fencing check uses transactional unique-index probes, not snapshot-only SELECT
  prepare probes actor/target/team and rejects cross-role subject overlap

Edge-proof boundary:
  issuer EXECUTE: service_role only
  trust claim: server-credential handshake, not exact Edge-binary attestation
  prepare EXECUTE: authenticated only
  proof table: postgres-owned / RLS + FORCE / no client table grants or policies
  unique proof + actor; exact target bound in row; no target-wide reservation
  prior same-actor proof rotated; PostgreSQL statement time; two-minute validity
  prepare atomically consumes exact proof before any durable state
  random/missing/expired/wrong-actor/wrong-target proof fails closed

rollback proof handling:
  SHARE-lock in fixed proof -> authority -> lease writer order
  any unexpired proof or any lease: STOP
  only after complete exact preflight: delete expired inert proofs
  prove locked proof table empty before exact object removal

authority-table ACL transition:
  complete ACL fingerprints pinned before/after
  service_role TRUNCATE removed only while T3A row fences are active
  33-column ACL md5 pre-T3A 3fa731261b3d39ca5d046fd548c1bf53
  33-column ACL md5 T3A d475edbb63410c2ab4b4c2be55ac270c

complete authority-table RLS policy inventory:
  count 7 / md5 1cb8f611f86778af0f60c78f2ffc70b0

authority-table non-internal trigger inventory:
  pre-T3A count 4 / T3A count 7
  includes corretores critical audit + both T1 guards + times governance audit
  authority-table rewrite rules count 0
```

Those were v4 candidate anchors. They were later resolved and reviewed as
recorded below.

### Post-merge v4 approval and runtime anchors

```text
repository: wagnerjfjunior/fecha.ai
PR: #127
final reviewed source head: a5c92617f372599a234c0147aad13a90649348d7
final reviewed source tree: 87872aac22b36437b7fb66f3614905e8df94f5ee
Backend/Data: APPROVE / findings none / static exact-head only
Backend/Data bundle: 95463 bytes / SHA-256 0b22d6e9f9f1f8e3d184254876a25ed985e8f054423a44acf3dd5b5f9f9570a6
AppSec: APPROVE / findings none / independent static exact-head only
AppSec bundle: 95986 bytes / SHA-256 7bde681c36639ee332e6e527c53c1b76fbfccaa7d74d090b2c64a64eea08da8f
merge commit / main: 610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87
```

The reviews authenticated byte-preserving exact-head bundles and read all 12
required PR/T1 payloads through EOF. They authorize no runtime by themselves.

Separate rollout evidence:

```text
criar-usuario production: v18 / ACTIVE / verify_jwt=false
Git blob: ec62997bc357b550feda5027051fe507fe9184fa
SHA-256: 11719575bce92c85422eb5d3a78ad26a5d683c47202e6db8032f3e13d5a254a7
T3A migration: NOT APPLIED
issuer/prepare/release/proof/lease objects: ABSENT
bounded fail-before-Auth calls: 3 UI submissions / each Edge 500
Auth admin update calls: 0
target password fingerprint / updated_at: unchanged
B1 fail-before-Auth: PASS
```

Each runtime submission showed `audit_logs POST 400` before the absent issuer
RPC 404. Live read-only catalog evidence established:

```text
audit_logs columns: 20
required no-default legacy columns: acao, entidade
ip_address: inet
owner: postgres
RLS / FORCE RLS: true / true
complete baseline relation fingerprint: 5d3b70257c57f5956032e83131effabb
hypothetical exact post-authenticated-INSERT-revoke fingerprint:
  1b1a381796f273b503cd4c41d34a3688
authenticated effective privileges: SELECT + INSERT baseline
service_role effective privileges: SELECT + INSERT + UPDATE
```

This is a material invalidation only for the Edge audit compatibility and the
new audit ACL/preflight/rollback domain. It does not reopen unchanged T1/T2 or
the approved v4 actor/tenant/proof/lease design. The v5 Edge, migration,
rollback and related evidence must receive new exact-head Backend/Data then
independent AppSec review. The v5 commit/head/blob anchors must be resolved live
after publication.

V5 relation-lock ordering follows established in-transaction writers:
`authority -> audit` for migration and
`proof -> authority -> lease -> audit` for rollback. Edge audit and proof calls
are separate committed HTTP transactions, so they do not introduce the reverse
held-lock pair.

### 5.1 PR #128 merge, Edge v19 proof and migration-abort anchor

```text
PR #128 reviewed head: b594218dabd9a7beaea3158bb143f5dd2fd71386
PR #128 reviewed tree: e36a00e671e8c8bce52b2e35f12beed165fad927
PR #128 merge commit / main: 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
criar-usuario production: v19 / ACTIVE / verify_jwt=false
deployment digest: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
single controlled POST: 2026-08-25T17:29:25.608Z / HTTP 500
audit committed: action=password_reset_attempt / status=edge_proof_unavailable
target UUID remained absent from auth.users and public.corretores
Auth logs in the window: caller login/getUser only; no admin password update
```

Exact SQL application anchor:

```text
main migration blob: f4413fddd145679077ae68b28b85c98ce439e74e
migration SHA-256: 9cef9dadae10b1262d78f01fbf30b490342b5cc228fc866c48ace5799777fced
migration bytes/lines: 134244 / 3550
main rollback blob: 36513bce970f66e023a50b16148a97bad76e17d7
rollback SHA-256: 7a8377f7ea4ecff5c36bb665a5e9bcb734b48015792310668d7ff328e81dbba4
rollback bytes/lines: 106631 / 2785
application invocations: 1
result: SQLSTATE 55000 / record "r" is not assigned yet
migration history entry after failure: ABSENT
T3 routines/relations after failure: ABSENT
Edge v19 after failure: ACTIVE
```

Invalidated claim:

```text
The reviewed forward/rollback SQL is executable on production PostgreSQL 17.
```

Bounded cause and correction:

```text
r record (later FOR-loop target)
+ pg_roles AS r (earlier catalog alias)
-> r.oid / r.rol* resolves to unassigned record
-> rename only catalog alias and role-field qualifiers to role_row
```

This finding does not invalidate B1 v19 runtime ordering, audit compatibility,
actor/tenant/proof/lease/T1 semantics, or the absence of partial production
state. It invalidates the final-head executability gate for B2/B3 and requires
fresh exact-head reviews of both SQL artifacts and related evidence.

### 5.2 PR #129 merge and live routine-inventory drift anchor

PR #129 closed the collision above and reached:

```text
final reviewed head: 6f6092aa66352cda3d617897895b0f09019adeea
final reviewed tree: bb13c051b57d1b04a1926cbe886b190cfa89ba37
Backend/Data: APPROVE / findings none / static exact-head only
Backend/Data response SHA-256:
  8d76512eadcaf54085e6109c83eb4a4e3b9499160537c85e741f7113d2b39b0f
AppSec: APPROVE / findings none / independent static exact-head only
AppSec response SHA-256:
  d096c474128e5099a16a90b5c4afc9922ffc4ff593b08680a8990b42177aa1ea
merge commit / main: 69f4cfa1bdee331826953b492f25c12b4defc030
```

Exact merged source anchors:

```text
migration blob: 6cc9a1f4419de5e0355954f2cbc6f503f5eb8157
migration SHA-256: f7d36c397decdc14675b29060f26ca462dae07c62576ab1ccb43c77e7e372181
migration lines / bytes: 3550 / 135000
rollback blob: afce77ab693a1fbbac10fdd70bd87032a7c8f0b2
rollback SHA-256: 4271782a67961705098cb1cb932799d5e7b19855678612ff2ac6845e8770164b
rollback lines / bytes: 2785 / 107387
Edge source blob: 866257371dcc85d22ae54cae3593b3e49a132d8e
```

The exact migration was applied once after that merge. It passed the corrected
role predicates and stopped before DDL:

```text
SQLSTATE P0001
T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT
PL/pgSQL function inline_code_block line 386 at RAISE
migration history entry after failure: ABSENT
T3 routines/relations after failure: ABSENT
Edge v19 after failure: ACTIVE
```

Fresh read-only recomputation on `2026-08-25`:

```text
complete non-system routine inventory excluding direct T1 guard:
  count 264 / md5 c299bf087df69f960dd0c611d1486675
authenticated-effective SECURITY DEFINER subset:
  count 122 / md5 7faa376a403c69239d9606559cf9c2db
non-system aggregate count: 0
```

The count, definer subset and aggregate count are unchanged. The only
non-system routine with tuple version newer than the established T1 anchor is:

```text
extensions.grant_pg_graphql_access()
owner: supabase_admin
security mode: SECURITY INVOKER
config: search_path=""
event trigger: issue_pg_graphql_access / ddl_command_end / enabled O
xmin: 7208
implementation md5: 2f3fa32125a4cd4e597bc8b3c7b55218
prosrc md5: e2ca36b1a39e090c101c6d0f009b5d20
normalized ACL:
  PUBLIC>supabase_admin:EXECUTE:f,
  supabase_admin>supabase_admin:EXECUTE:f,
  postgres>supabase_admin:EXECUTE:t
```

The anchor refresh includes this exact helper inside the complete inventory;
it does not add an exclusion. Change all four full-inventory digest literals
from historical `b1f0919d...` to current `c299bf08...`. Any later routine
body/owner/language/kind/config/comment/ACL drift still changes the digest and
stops migration or rollback.

Candidate SQL blob anchors after that four-literal substitution:

```text
migration: 1b938b95107bd4f6ab1d14d914438e654fcc1011
  SHA-256 b9f55d58ea73c723a04075ab639bf1f6910b07d77774dfd5b593010d8de56d77
rollback: a9457bc48724cc8406bcec9348a14cbc8b868be3
  SHA-256 bc8ea4aaca436aa78a25de29b8511d4d15b36a15ece32cc8a85b164153251ba7
```

## 6. Live trust-anchor observations used by T3A review

Read-only production evidence on 2026-08-23 established, without PII:

```text
admins authenticated SELECT/INSERT/UPDATE/DELETE: absent
corretores authenticated broad UPDATE: absent
corretores authority-bearing columns role/empresa_id/user_id/time_id/is_admin_local/is_gestor: not directly authenticated-updatable
times authenticated table UPDATE: present and therefore materially dependent on RLS/policy semantics
times_update policy: exactly one permissive UPDATE policy with the recorded expression
corretores_update policy: exactly one permissive UPDATE policy with identical strict USING/WITH CHECK helper
RLS/FORCE on admins/corretores/times: present / enabled
direct literal authenticated password writer besides self-service: absent
T3 context-key collision: absent
authenticator: NOINHERIT / LOGIN / no superuser-create-replication-bypass
pg_database_owner: INHERIT / NOLOGIN / no superuser-create-replication-bypass
full pg_auth_members graph: count 21 / md5 fb803a204209bc71074a1eee7b57944e
non-system aggregates: count 0
database owner: postgres
public schema owner: pg_database_owner
only public ACL CREATE grantee: pg_database_owner -> database owner postgres
complete public schema ACL: count 7 / md5 e2ad94b6bfb9b0cb8c4980459fd55a6e
```

Observed helper fingerprints relevant to the current `times` policy trust chain:

```text
auth.uid() md5: ea3b41bf29e2ad573067939329aa088e
is_root() md5: 465c04885d729e63f1a1d4458fc2a1b0
is_admin_local() md5: 64b982da412f62c324aa2dde210eea0c
my_corretor_id() md5: c8f243d33d42837c46236625a74c3fb7
my_empresa_id() md5: 7d7a73d22953d547a103f89c7b676906
```

The old direct-literal result is not proof against wrappers, dynamic SQL or
transitive callees. The v4 migration therefore pins the full positive routine
inventory and enforces the password-state transition at the enabled T1/T3
guards. These remain review anchors, not runtime proof.

## 7. Production Edge baseline

Current production Edge:

```text
slug: criar-usuario
version: 19
status: ACTIVE
verify_jwt: false
deployment digest: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
source merge commit: 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
```

The controlled call established audit-first fail-before-Auth while the issuer
remains absent. Invalidate after any Edge version/runtime change.

## 8. Unestablished claims

```text
anchor-refresh final PR head: MUST BE RESOLVED AFTER COMMIT
Backend/Data exact-head PASS on refreshed anchor: NOT ESTABLISHED
independent AppSec exact-head PASS on refreshed anchor: NOT ESTABLISHED
T3A applied to Supabase production: NO
positive/negative/cross-tenant production smoke: NOT EXECUTED
rollback runtime-tested: NOT EXECUTED
T3B frontend password cutover: NOT IMPLEMENTED
Security Go: DENIED
```

Established:

```text
PR #128 merged
PR #129 merged
Edge v19 deployed and active
single v19 fail-before-Auth call PASS
audit row committed
no Auth mutation
first migration invocation aborted on alias collision before DDL
PR #129 exact-head Backend/Data + AppSec approvals
second migration invocation aborted on positive routine inventory drift before DDL
current live routine inventory 264 / c299bf087df69f960dd0c611d1486675
authenticated definer subset and aggregate count unchanged
no migration history entry or T3 objects after either abort
```

## 9. Invalidation rules

Material invalidation events include:

```text
material code/object change
RPC/ACL/policy/grant/trigger change
Edge runtime/version change
relevant App frontend change
contradictory runtime evidence
new security finding
change in product authority contract
```

Not invalidation events by themselves:

```text
main SHA movement only
documentation-only lifecycle movement
new conversation
specialist change
request to repeat an unchanged exact-head gate
```

## 10. AUDIT_LOOP_BLOCKED

A repeated audit must identify the prior anchor, exact changed evidence and affected proof obligation.

Without a material invalidation event:

```text
AUDIT_LOOP_BLOCKED
```

After a material T3A corrective commit, revalidate only the affected exact-head T3A gate and its dependencies; do not reopen unrelated completed work.
