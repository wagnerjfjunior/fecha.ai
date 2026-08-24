# FECH.AI — SFJM Current Material State

**Status:** `MATERIAL_RECORDED_STATE / PR127_MERGED / EDGE_V18_DEPLOYED / B1_RUNTIME_PASS / AUDIT_SCHEMA_DRIFT_OPEN / V5_REVIEWS_PENDING / SECURITY_GO_DENIED`
**Updated:** `2026-08-24`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority rule

This file is the principal authority for durable product/security operational meaning.

It intentionally does not freeze volatile GitHub lifecycle facts such as current `main`, PR Draft/Ready, current head, checks, reviews, threads, mergeability or deployment state. Resolve those live before acting.

This transition is being written on the post-merge T3A-v5 audit-compatibility
change set. Until that corrective change set is merged, this updated SFJM
content is `PR_HEAD_ONLY`; a new conversation must bootstrap from live `main`,
then resolve the active corrective PR/head live and read the SFJM files from
that exact head before continuing.

## 2. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION
WDP: unchanged
```

Architecture rule:

```text
Frontend requests/displays.
Backend/RPC/Supabase validates and decides.
Client-provided tenant/company/role/flags/ownership are not authority.
Fail closed on missing or inconsistent identity/tenant/permission evidence.
```

No Supabase test database/branch is part of the current operating model. Production remains the only database environment; this increases rollout discipline requirements and does not relax authorization, isolation, rollback or evidence gates.

## 3. T1 — corretor status authority boundary

Material state:

```text
GitHub: MERGED
Supabase production: APPLIED
Production migration record:
  version: 20260822192552
  name: f1_02_harden_status_corretor_rpc
Post-application catalog validation: ESTABLISHED
```

Current production read-only revalidation on 2026-08-23 established:

```text
public.t3_prepare_admin_password_reset(uuid): ABSENT
public.t3_prepare_admin_password_reset(uuid,uuid): ABSENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): ABSENT
public.t3_admin_password_reset_edge_proofs: ABSENT
T1 triggers on public.corretores: PRESENT / ENABLED
authenticated UPDATE columns on public.corretores exactly:
  apto_para_receber
  ativo
  must_change_password
public.marcar_senha_inicial_definida() md5:
  2a7b28d4bb6342a99d075c4d3c49af4d
```

The T1 strict authority model remains material and must not be weakened by T3A.

Important T1 interaction discovered during T3A red-team review:

```text
trg_t1_guard_corretores_direct_compat_update
→ protects ativo / apto_para_receber / must_change_password
→ currently denies gestor-originated must_change_password changes
```

Therefore the first T3A candidate cannot simply execute `UPDATE must_change_password=true` and expect strict gestor resets to work. T3A must interoperate with the existing T1 guard without disabling it, bypassing tenant checks, granting broad UPDATE, trusting the client or weakening existing status protections.

Any T1 guard correction inside T3A must be narrowly bound to the server-authorized T3 password-reset transition, permit only the intended protected transition, and have an exact rollback to the pre-T3A T1 guard contract.

## 4. T2 — frontend status cutover

Material code state:

```text
main code anchor at transition time:
  commit: 037232fe3da37a749ab980f783af92ff15e2baf2
  src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

The frontend status path was cut over from direct `PATCH public.corretores` for `ativo/apto_para_receber` to `public.atualizar_status_corretor(...)`.

Controlled positive production smoke was executed in the app and captured through HAR evidence in the operating session for:

```text
apto isolated true -> false -> true: PASS
ativo isolated true -> false -> true: PASS
ativo + apto combined false -> true restoration: PASS
unchanged field sent as null in isolated calls: PASS
status RPC returned ok=true: PASS
direct status PATCH observed in the captured flows: ZERO
```

This is bounded positive-flow evidence. It is not a broad adversarial certification of every role/tenant combination and does not grant Security Go.

The administrative password flow remains separate. The current App.jsx still contains the stale post-reset direct write:

```text
must_change_password=false
```

That path is intentionally not T2 and remains part of T3A/T3B closure.

## 5. T3A — Administrative Password Reset Multi-Tenant Authority Boundary

### Objective

Establish a non-bypassable server-side administrative password-reset boundary with:

```text
actor derived from auth.uid()
company/tenant derived server-side
strict root/admin_local/gestor authority
cross-company denial
gestor limited to ordinary broker in own ACTIVE managed team
target-existence leakage resistance
must_change_password=true before Auth password mutation
no authority from client-provided empresa/role/flags/team/ownership
rollback that restores the exact prior boundary
```

### Current implementation lineage

The initial candidate at PR head `45ad2766...` received material B1-B4
findings. Backend/Data review of `bf8fb1f...` then identified the
DB-commit-to-Auth authority race and rejected the non-transitive writer regex.
The v3 lease/fence head `46313258...` closed that race and passed B1/B4
statically, but still lacked complete membership/options, aggregate and
`public` ACL closure. The corrected exact head
`fcb7dfc2f5f2259926556652fa9cfd3443d0c214` / tree
`4dcaf2d4b6aa1248801e455def811e50ff04e414` received integral manual
Backend/Data `APPROVE` and independent AppSec `APPROVE`.

After Product Authority separately authorized Ready, the GitHub Codex review
opened material P2 `DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`. An authorized
authenticated user could call the preparation RPC directly through PostgREST,
commit a non-expiring lease and `must_change_password=true`, skip the Edge Auth
password mutation, and lack access to the service-role-only release. The T1/T3
fence would then also block ordinary self-service completion. The PR was
returned to Draft at that point, and the same T3A change set added the v4
correction:

```text
versioned criar-usuario Edge baseline + hardened leased reset path
service-role-only public.t3_issue_admin_password_reset_edge_proof(uuid,uuid)
caller-bound public.t3_prepare_admin_password_reset(uuid,uuid)
opaque one-time actor+target proof consumed before locks/lease/password state
PostgreSQL-only two-minute proof freshness; no frontend time or authority input
durable reset lease + snapshot-independent unique-index probes + three authority-table fencing triggers
service-role-only exact lease release after proven Auth success
exact authority-table ACL pinning + service_role TRUNCATE revocation
positive full non-system routine inventory instead of writer regex
full role-membership graph/options + authenticator role anchor
database/public-schema owner + complete public ACL anchor
all pg_proc routine kinds + explicit zero non-system aggregate assertion
exact fail-closed trust-anchor preflight/postflight
lease-bound T1 direct-guard interoperability
revocation of authenticated UPDATE(must_change_password)
exact drift-aware rollback blocking live proofs/leases and cleaning only expired inert proofs after full preflight
B1-B4 evidence and coverage matrix
```

Fresh integral Backend/Data and independent AppSec reviews approved exact head
`a5c92617f372599a234c0147aad13a90649348d7` / tree
`87872aac22b36437b7fb66f3614905e8df94f5ee` with no findings. PR #127 then
merged as main commit `610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87`.

Merged v4 fingerprints:

```text
T3 proof issuer prosrc: 87f8d7f0c96ce4ae52fed9e2bc4bdcdd
T3 prepare prosrc: f9bd114c7eb77313e22861816b8a88f5
T3 release prosrc: a51c5b360c5d8a3684a97271460ec249
T3 fence guard prosrc: bd611e591aa2d951b178853f78caaa65
T3-aware direct guard prosrc: 951da8a6ac6e934828f06ab1513778fa
rollback-restored pre-T3A pg_get_functiondef: 99477024e337de5645dd042a30f8cf78
```

These are approved static v4 facts, not proof that the migration is applied.

The separately-authorized Edge-first rollout deployed the exact merged source
as production `criar-usuario` v18 (`verify_jwt=false`, Git blob
`ec62997bc357b550feda5027051fe507fe9184fa`, SHA-256
`11719575bce92c85422eb5d3a78ad26a5d683c47202e6db8032f3e13d5a254a7`).
T3A issuer/prepare/release/proof/lease objects remain absent and the migration
has not been applied.

The bounded fail-before-Auth UI exercise emitted three submissions while the
browser appeared frozen. All three followed the same platform sequence:

```text
caller Auth GET 200
caller profile GET 200
audit_logs INSERT 400
proof issuer RPC 404
audit_logs PATCH 204 with no matching row
Edge response 500
no admin Auth update; target password fingerprint and updated_at unchanged
```

B1 is runtime PASS. The audit INSERT 400 is a new material blocker: live
`audit_logs` requires `acao` and `entidade`, and `ip_address` is `inet`.
T3A-v5 corrects only that audit-compatibility/integrity domain while preserving
the approved v4 authority boundary:

```text
Edge supplies modern + legacy audit columns in reset and creation paths
Edge requires the audit insert before proof/prepare/Auth
client IP is conservative for inet; raw value is stored only in legacy text ip
migration pins complete audit metadata/ACL/columns/constraints/indexes/policies
baseline audit fingerprint 5d3b70257c57f5956032e83131effabb
post-revoke fingerprint 1b1a381796f273b503cd4c41d34a3688
authenticated audit INSERT revoked; authenticated SELECT preserved
rollback locks audit after proof/authority/lease and restores/verifies the exact legacy INSERT grant
```

The v5 exact head has no Backend/Data or AppSec verdict yet. No v5 Edge deploy,
migration, additional runtime call or rollback has been authorized or executed.

### Static authority contract preserved

```text
ROOT
  public.admins
  role='admin_global'
  ativo=true

ADMIN_LOCAL
  corretores.role='admin_local'
  is_admin_local=true
  ativo=true
  target same empresa
  target not protected root/admin identity
  is_gestor is not an admin-local authority prerequisite

GESTOR
  corretores.role='gestor'
  is_gestor=true
  is_admin_local=false
  ativo=true
  target same empresa
  target role='corretor'
  target not admin/gestor
  target has no public.admins identity
  target ACTIVE managed team
  team.empresa_id = actor.empresa_id
  team.gestor_id = actor.id
```

Same-company membership alone is insufficient for gestor authority.

## 6. T3A B1-B4 state and v5 audit correction

The findings remain historical invalidation anchors for the initial heads.
Exact v4 head `a5c92617...` closed them and merged. The v5 audit change does not
reopen T1/T2 or alter the actor/tenant/lease contract, but its changed material
bytes require exact-head review of affected dependencies.

### B1 — safe rollout ordering: V18 RUNTIME PASS / V5 RETEST PENDING

```text
v18 reviewed hardened Edge deployed first: DONE
-> proof issuer absent: reset_password failed closed before Auth: PASS
-> audit insert returned 400: NEW BLOCKER
reviewed v5 Edge next under separate authority
-> audit insert must succeed, issuer remain absent, no Auth mutation
-> reviewed migration
-> catalog/ACL/fingerprint validation
-> separately-authorized bounded smoke
```

### B2 — trust-anchor preflight: V4 APPROVED / V5 AUDIT ANCHOR PENDING REVIEW

The migration holds the three authority-bearing tables in SHARE mode and
requires exact postgres/client/authenticator/pg_database_owner attributes; the complete
21-edge role-membership graph with grantor/admin/inherit/set options
(`fb803a204209bc71074a1eee7b57944e`); exact database and `public` schema
owners; the complete seven-entry effective `public` ACL
(`e2ad94b6bfb9b0cb8c4980459fd55a6e`); authority-column types,
immediate unique identity indexes, RLS/FORCE, grant/policy surfaces,
authority/helper/legacy-writer fingerprints, exact complete authority-trigger
inventory, the exact seven-policy inventory
`1cb8f611f86778af0f60c78f2ffc70b0` and absence of authority-table rewrite
rules. It
replaces the negative writer regex with an exact positive inventory of every
non-system function, procedure, aggregate and window function except the
separately-pinned direct T1 guard: 264 routines /
`b1f0919df8a0acaca7bbea2b928b0ffe`, including 122 authenticated-effective
SECURITY DEFINER routines / `7faa376a403c69239d9606559cf9c2db`, with an
explicit positive non-system aggregate count of zero.

The proof issuer/table and two-argument prepare signature are absent before the
migration and are pinned after it by exact owner, SECURITY DEFINER/search path,
signature, source, comment, ACL, table shape, constraints, RLS/FORCE, empty
policy/trigger/rewrite inventory and empty postflight state. Only service_role
can execute the issuer; this is a server-credential handshake, not exact binary
attestation. Only authenticated can execute prepare. Prepare still
derives its actor exclusively from `auth.uid()` and consumes the exact
actor+target proof using PostgreSQL time before any durable state.

V5 additionally locks `audit_logs` after the authority relations and pins the complete live relation
under baseline fingerprint `5d3b70257c57f5956032e83131effabb`, then verifies
post-revoke fingerprint `1b1a381796f273b503cd4c41d34a3688` and exact
effective privileges. This audit delta is not specialist-approved yet.

### B3 — drift-safe rollback: V4 APPROVED / V5 AUDIT REVERSAL PENDING REVIEW

Before any replacement, drop or grant, rollback locks the proof table, three
authority tables, lease table and audit table in fixed
proof→authority→lease→audit writer
order and in SHARE mode. An unexpired proof or any active/unresolved lease stops
rollback. It verifies the exact proof/lease
tables, issuer/prepare/release/fence functions, three fencing
triggers, T3-aware guard, client/authenticator roles, the complete membership
graph, database/schema ownership, complete `public` ACL and all-kind positive
routine inventory including the zero-aggregate assertion, T1/audit objects,
policies and grants. Only after the complete exact preflight does it delete
expired inert proofs, prove the locked proof table empty, restore guard MD5
`99477024e337de5645dd042a30f8cf78`, drop only proven T3 objects without
`IF EXISTS`, restore only the prior column grant and leave user/Auth state
untouched.

V5 also requires the exact post-T3A audit fingerprint/privileges before any
cleanup, restores authenticated INSERT only after the full preflight, and
verifies the exact baseline fingerprint afterward.

### B4 — T1 guard interoperability: V4 APPROVED / UNCHANGED

Both existing T1 triggers remain enabled. Before the durable path begins, the
caller-JWT RPC must consume an unexpired opaque proof whose actor equals
`auth.uid()` and whose target equals the requested target. A direct caller
without that service-role-issued Edge-presence proof fails before locks, lease
creation or password-state mutation. The RPC then serializes `admins`,
`corretores` and `times` with one fixed-order SHARE ROW EXCLUSIVE acquisition,
creates a random durable lease with unique actor/target/team keys, and binds
the T1 transition to
`lease_id:auth.uid():target.user_id:txid_current()`. Three enabled T3 triggers
use short insert/delete uniqueness probes so even a pre-lease MVCC snapshot
cannot miss a conflicting actor/target/team fence. They keep those authority
rows stable until the Auth call succeeds and the exact service-role release
commits. Prepare uses the same probes to reject cross-role lease overlap.
Because TRUNCATE bypasses row triggers, its exact authority-table
privilege is removed from service_role while T3A is active. The direct guard denies every other
password-state writer except the established active self-service true-to-false
completion. Non-password T1 behavior remains established.

The prior Backend/Data `REQUEST_CHANGES` results remain historical inputs. The
later Backend/Data and AppSec approvals on `fcb7dfc2...` are anchored by
SHA-256 `8b6bf96691b7337df95f0350ac5028a4aeb85e6cab917ec56383fc8e083ac0dc`
and `1df5df13786f7ba767340cca2ca546aeddbf92e81a307a48aef3107fc0cf64ca`.
They remain evidence about v3 but were invalidated by the direct-RPC finding.
The later exact-head v4 reviews on `a5c92617...` are the valid merged anchor.
The next gate is Backend/Data review of one resolved v5 exact head; independent
AppSec follows only after Backend/Data closure.

## 7. Material blockers

Until Backend/Data and independent AppSec both pass on one exact v5 corrective
head and the later lifecycle/runtime authorities are separately granted:

```text
v5 corrective PR Ready: BLOCKED
v5 corrective PR merge: BLOCKED
T3A Supabase application: BLOCKED
further T3A Edge deployment: BLOCKED
T3A production smoke: BLOCKED without separate exact runtime authority
T3B frontend password cutover: BLOCKED on T3A backend deployment/validation
Security Go: DENIED
Broad paid commercialization: BLOCKED
```

A green Vercel build does not satisfy these gates.

## 8. Current Product Authority and limits

Product Authority has authorized GitHub-side correction of the post-merge audit
compatibility finding, directly-related SFJM/evidence, creation of one Draft PR
from merged main and preparation of the manual exact-head review bundles. PR
#127 merge, Edge v18 deployment and the bounded fail-before-Auth call are
consumed authorities; they do not carry forward to v5 runtime.

It does **not** collapse the separate gates for:

```text
v5 Ready
v5 merge
Supabase production migration/application
Edge production deployment
production data mutation
production adversarial testing
Security Go
```

Those remain separate lifecycle/runtime decisions and require their applicable exact authorization and evidence.

## 9. Semantic next action

```text
Publish and reconcile the v5 audit-compatibility correction in one new Draft PR
from merged main, repeat Backend/Data on its live-resolved exact head, then run
independent AppSec only after Backend/Data closure.
```

Required sequence for the next conversation:

```text
1. resolve FECH.AI main live
2. bootstrap normally
3. resolve active v5 corrective PR live and exact current head
4. read SFJM from that PR head because this transition is PR_HEAD_ONLY until merge
5. confirm the corrective commit is the resolved PR head
6. update the corrective PR description/evidence for that exact head
7. read final material files integral to EOF
8. reconcile the B1-B4 coverage matrix
9. run Backend/Data exact-head review
10. run independent AppSec exact-head review without inheriting the first review
11. stop in Draft before a new Ready/merge transition
```

Temporary specialist-channel fact:

```text
SES Router/Action from inside the project: FROZEN / NOT RELIABLY AVAILABLE
Backend/Data review channel: exact-head manual prompt/response via Product Authority
AppSec review channel: separate exact-head manual prompt/response via Product Authority
fabricated Gateway receipt: PROHIBITED
```

This temporary channel changes neither adopted specialist identity nor mutation
authority.

Do not reopen T1/T2 absent a new material invalidation event. T1/T2 are dependencies/anchors for T3A, not new audit programs.

## 10. Handoff prohibitions

Do not:

```text
create a workaround that weakens T1
create another duplicate PR to relitigate B1-B4; the single post-merge v5 audit
  PR is justified only by the new runtime finding
apply SQL merely to see whether it works
use production as an offensive laboratory
normalize real users/data as part of T3A
alter App.jsx in T3A
change criar-usuario user-creation semantics outside what is strictly necessary for reset boundary compatibility
claim production PASS from static code
mark Security Go
```

## 11. Material update triggers

Update this file when durable meaning changes, including:

```text
B1-B4 corrected or materially changed
new exact-head specialist gate outcome
T3A application/deployment/runtime validation
T3B eligibility change
rollback evidence materially changes
Security Go/F1-02 acceptance changes
```

Do not update solely because a SHA advanced, a Draft became Ready, or a documentation-only lifecycle event occurred without semantic effect.
