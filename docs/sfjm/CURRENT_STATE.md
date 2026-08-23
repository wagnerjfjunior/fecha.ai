# FECH.AI — SFJM Current Material State

**Status:** `MATERIAL_RECORDED_STATE / T3A_CORRECTED_AFTER_SECOND_BACKEND_REQUEST_CHANGES / REPEAT_BACKEND_EXACT_HEAD_REVIEW_PENDING / SECURITY_GO_DENIED / DOCUMENTATION_ONLY`
**Updated:** `2026-08-23`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority rule

This file is the principal authority for durable product/security operational meaning.

It intentionally does not freeze volatile GitHub lifecycle facts such as current `main`, PR Draft/Ready, current head, checks, reviews, threads, mergeability or deployment state. Resolve those live before acting.

This transition is being written on the active T3A change set. Until that change set is merged, this updated SFJM content is `PR_HEAD_ONLY`; a new conversation must bootstrap from live `main`, then resolve the active T3A PR/head live and read the SFJM files from that exact head before continuing T3A work.

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

The initial candidate at PR head
`45ad27668835b6458b52d2fb592cfa36b5589726` received material B1-B4
findings. A later exact-head Backend/Data review of
`bf8fb1f4ab043226de3c77763b9b425a13b0261e` was validly relayed manually and
returned `REQUEST_CHANGES`: its HIGH-1 identified the DB-commit-to-Auth race;
HIGH-2 rejected the direct `prosrc` writer regex as non-transitive. The next v3
head `4631325827a76152ba554bece2a59da9eb1bb662` received a second integral
manual Backend/Data review: B1/B4 passed statically and HIGH-1 closed, but B2/B3
failed because the role-membership check was unilateral, the routine inventory
omitted aggregates, and the `public` schema ACL was not complete. The same T3A
change set now contains the correction for those three findings:

```text
versioned criar-usuario Edge baseline + hardened leased reset path
caller-bound public.t3_prepare_admin_password_reset(uuid)
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
exact drift-aware rollback requiring an empty locked lease table
B1-B4 evidence and coverage matrix
```

Corrected candidate fingerprints:

```text
T3 prepare prosrc: 91fc82deadc0d18e871e43a812c8d6dd
T3 release prosrc: a51c5b360c5d8a3684a97271460ec249
T3 fence guard prosrc: bd611e591aa2d951b178853f78caaa65
T3-aware direct guard prosrc: 951da8a6ac6e934828f06ab1513778fa
rollback-restored pre-T3A pg_get_functiondef: 99477024e337de5645dd042a30f8cf78
```

These are candidate facts, not exact-head specialist PASS or runtime proof. The
final corrective commit/head must be resolved live before review.

The production Edge remains the pre-T3A `criar-usuario` v17 at this transition point. T3A RPC is absent in production. No T3A migration has been applied and no T3A Edge has been deployed.

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

## 6. T3A B1-B4 corrective candidate state

The findings remain historical invalidation anchors for the initial head. They
are addressed in the same PR candidate as follows:

### B1 — safe rollout ordering: CANDIDATE ADDRESSED

```text
reviewed hardened Edge first
-> RPC absent: reset_password fails closed before Auth mutation
-> reviewed migration
-> catalog/ACL/fingerprint validation
-> separately-authorized bounded smoke
```

### B2 — trust-anchor preflight: CANDIDATE ADDRESSED

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

### B3 — drift-safe rollback: CANDIDATE ADDRESSED

Before any replacement, drop or grant, rollback locks the three authority tables
and the lease table in SHARE mode. An active/unresolved lease stops rollback. It
verifies the exact lease table, prepare/release/fence functions, three fencing
triggers, T3-aware guard, client/authenticator roles, the complete membership
graph, database/schema ownership, complete `public` ACL and all-kind positive
routine inventory including the zero-aggregate assertion, T1/audit objects,
policies and grants. It restores guard MD5
`99477024e337de5645dd042a30f8cf78`, drops only proven T3 objects without
`IF EXISTS`, restores only the prior column grant and never rewrites user/Auth
state.

### B4 — T1 guard interoperability: CANDIDATE ADDRESSED

Both existing T1 triggers remain enabled. The RPC serializes `admins`,
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

The Backend/Data `REQUEST_CHANGES` results on `bf8fb1f...` and `46313258...` are
historical material inputs, not closure for the changed head. The second review
response is anchored by SHA-256
`1ab2b39d52536b0ba92cd25df4d91b808f25abd08be0c5de72146113c7cda544`.
No B1-B4 candidate statement is a specialist PASS. The next gate is a repeated
Backend/Data review of one new resolved exact head; AppSec follows only after
Backend/Data closure.

## 7. Material blockers

Until Backend/Data and independent AppSec both pass on one exact final head and
the later lifecycle/runtime authorities are separately granted:

```text
T3A Ready: BLOCKED
T3A merge: BLOCKED
T3A Supabase application: BLOCKED
T3A Edge deployment: BLOCKED
T3A production smoke: BLOCKED without separate exact runtime authority
T3B frontend password cutover: BLOCKED on T3A backend deployment/validation
Security Go: DENIED
Broad paid commercialization: BLOCKED
```

A green Vercel build does not satisfy these gates.

## 8. Current Product Authority and limits

Product Authority has authorized continued corrective work on the existing T3A branch/PR to resolve the identified security/backend blockers under FECH.AI governance, without workarounds or scope-evasive fixes.

That authority covers GitHub-side corrective implementation/evidence necessary to produce a reviewable T3A candidate on the existing change set.

It does **not** collapse the separate gates for:

```text
Ready
merge
Supabase production migration/application
Edge production deployment
production data mutation
production adversarial testing
Security Go
```

Those remain separate lifecycle/runtime decisions and require their applicable exact authorization and evidence.

## 9. Semantic next action

```text
Publish and reconcile the v3 correction in the existing T3A change set, repeat
Backend/Data on the new live-resolved exact head, then run independent AppSec
only after Backend/Data closure.
```

Required sequence for the next conversation:

```text
1. resolve FECH.AI main live
2. bootstrap normally
3. resolve active T3A PR live and exact current head
4. read SFJM from that PR head because this transition is PR_HEAD_ONLY until merge
5. confirm the corrective commit is the resolved PR head
6. update the existing PR description/evidence for that exact head
7. read final material files integral to EOF
8. reconcile the B1-B4 coverage matrix
9. run Backend/Data exact-head review
10. run independent AppSec exact-head review without inheriting the first review
11. stop before Ready unless Product Authority separately authorizes Ready
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
create another PR for the same T3A blocker set
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
