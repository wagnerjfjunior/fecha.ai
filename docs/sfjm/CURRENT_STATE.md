# FECH.AI — SFJM Current Material State

**Status:** `MATERIAL_RECORDED_STATE / PR129_MERGED / EDGE_V19_DEPLOYED / B1_V19_RUNTIME_PASS / TWO_T3A_MIGRATION_ATTEMPTS_FAIL_CLOSED / LIVE_ROUTINE_ANCHOR_DRIFT / ANCHOR_REFRESH_REVIEWS_REQUIRED / SECURITY_GO_DENIED`
**Updated:** `2026-08-25`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority rule

This file is the principal authority for durable product/security operational meaning.

It intentionally does not freeze volatile GitHub lifecycle facts such as current `main`, PR Draft/Ready, current head, checks, reviews, threads, mergeability or deployment state. Resolve those live before acting.

This transition records the second distinct production preflight event. PR #129
corrected the prior PL/pgSQL alias collision, passed fresh exact-head reviews and
merged. The next exact migration invocation advanced beyond that defect and the
positive routine inventory detected a new live catalog digest. PostgreSQL again
aborted before any T3 object was created. The routine-anchor refresh is
`PR_HEAD_ONLY` until merged; resolve its live PR/head and read these files from
that exact head before continuing.

### 1.1 Latest production transition — 2026-08-25

```text
PR #128: MERGED
PR #128 reviewed head: b594218dabd9a7beaea3158bb143f5dd2fd71386
PR #128 merge commit / main: 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
criar-usuario production: v19 / ACTIVE / verify_jwt=false
Edge deployment digest: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
single controlled v19 fail-before-Auth call: HTTP 500 / EXPECTED_FAIL_CLOSED
audit row: COMMITTED / status=edge_proof_unavailable
target Auth mutation: NONE
first T3A migration application: ABORTED / PLPGSQL ROLE-ALIAS COLLISION
PR #129: MERGED
PR #129 reviewed head: 6f6092aa66352cda3d617897895b0f09019adeea
PR #129 merge commit / main: 69f4cfa1bdee331826953b492f25c12b4defc030
second T3A migration application: ABORTED / POSITIVE ROUTINE INVENTORY DRIFT
T3A migration history entry: ABSENT
T3A routines/relations after abort: ABSENT
```

The first application error was:

```text
SQLSTATE 55000
record "r" is not assigned yet
```

PR #129 renamed only those aliases/references to `role_row` in forward and
rollback pre/postflight. The second application then stopped at:

```text
SQLSTATE P0001
T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT
PL/pgSQL function inline_code_block line 386 at RAISE
```

Fresh live recomputation established:

```text
complete non-system routine inventory excluding the separately-pinned T1 guard:
  reviewed baseline: count 264 / md5 b1f0919df8a0acaca7bbea2b928b0ffe
  current live:      count 264 / md5 c299bf087df69f960dd0c611d1486675
authenticated-effective SECURITY DEFINER subset:
  count 122 / md5 7faa376a403c69239d9606559cf9c2db / UNCHANGED
non-system aggregates: count 0 / UNCHANGED
```

The only non-system routine newer than the established T1 anchor is
`extensions.grant_pg_graphql_access()`, owned by `supabase_admin`,
`SECURITY INVOKER`, bound to enabled event trigger `issue_pg_graphql_access`,
with implementation MD5 `2f3fa32125a4cd4e597bc8b3c7b55218`. The narrow
correction changes only the four complete routine-inventory digest literals in
forward and rollback. It does not exclude the helper or relax the inventory,
and it does not change counts, the authenticated definer subset, grants,
authority predicates, T1/T2, Edge code, App.jsx, business data or Auth state.

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

The v5 audit correction received Backend/Data and independent AppSec exact-head
approval at `b594218dabd9a7beaea3158bb143f5dd2fd71386`, merged through PR #128 as
`3c9daf6c49eb937824c2c2b40aba198e2727c4bb`, and its exact Edge was deployed
as production v19. One controlled call proved the corrected audit-first
fail-before-Auth path. The later separately-authorized migration invocation
then exposed the PL/pgSQL alias collision recorded in §1.1; it aborted before
DDL and created no migration-history entry.

PR #129 corrected only that collision, received both exact-head approvals and
merged as `69f4cfa1bdee331826953b492f25c12b4defc030`. The exact merged migration
was then invoked once and advanced to the positive routine inventory, which
detected live digest `c299bf087df69f960dd0c611d1486675` instead of the
historical reviewed `b1f0919df8a0acaca7bbea2b928b0ffe`. It again aborted
before DDL with no history entry or T3 object. The current digest-only refresh
is the new bounded review domain.

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

## 6. T3A B1-B4 state after the live routine-anchor finding

The alias defect is closed by PR #129. The new finding is a genuine positive
inventory mismatch in the exact trust-anchor preflight. It does not reopen the
already established actor, tenant, proof, lease, audit or T1 logic.

| Domain | Current result | Effect of anchor refresh |
|---|---|---|
| B1 safe rollout ordering | v19 runtime PASS: one POST 500, audit committed, no Auth mutation | unchanged |
| B2 trust-anchor preflight | alias correction passed; the positive routine inventory then detected current live drift and stopped before DDL | refresh the exact full-inventory digest in forward pre/postflight; preserve count, definer subset and aggregate anchors |
| B3 drift-safe rollback | not executed; rollback must recognize the same exact live baseline before and after reversal | apply the identical full-inventory digest refresh in rollback pre/postflight |
| B4 T1 interoperability | approved static contract; migration never reached DDL | unchanged |
| Multi-tenant / actor boundary | server-derived company/role/team and `auth.uid()` actor | unchanged |
| Edge / frontend | production Edge v19; no App.jsx change | unchanged |

The second failed application is evidence that B2 failed closed on a new live
event, not an authority bypass, not a repeat of the alias defect and not a
partial deployment. Exact-head Backend/Data review must precede independent
AppSec review on the corrected Draft PR.

## 7. Material blockers

Until the digest-only correction receives Backend/Data and independent AppSec
approval on one exact head and later lifecycle/runtime authorities are granted:

```text
corrective PR Ready: BLOCKED
corrective PR merge: BLOCKED
new T3A Supabase application: AUTHORIZED ONCE AFTER REVIEWS / CURRENTLY BLOCKED BY PRECONDITIONS
T3A runtime smoke: BLOCKED
rollback execution: BLOCKED
T3B frontend password cutover: BLOCKED
Security Go: DENIED
Broad paid commercialization: BLOCKED
```

Production remains in the intended Edge-first fail-closed state: v19 can record
the attempt and fails before Auth while the issuer/prepare RPCs are absent.

## 8. Current Product Authority and limits

Product Authority separately authorized the first production migration
application after the v19 fail-before-Auth proof. That authority was consumed
by the alias-collision abort. After PR #129 review/merge, the later conditional
production authority was consumed by the second fail-closed invocation. No
automatic retry occurred after either event.

After the routine inventory mismatch and intact-production verification were
reported, Product Authority authorized:

```text
create one narrow corrective Draft PR from live main 69f4cfa1...
refresh only the four complete non-system routine inventory digest literals
  from b1f0919d... to current live c299bf08...
update directly-related evidence/SFJM
perform read-only validation
prepare exact-head specialist review material
obtain Backend/Data exact-head review, then independent AppSec exact-head review
after those reviews and resolution of the separate GitHub lifecycle
  prerequisites, apply the authenticated final migration exactly once
```

The one production retry is not exercisable during this Draft/review action.
Ready and merge remain separate unresolved lifecycle gates. Edge deploy,
runtime/Auth smoke, rollback and Security Go are not included.

## 9. Semantic next action

```text
Publish the four-literal forward/rollback routine-anchor refresh in one Draft
PR from live main, resolve its exact head, read all changed material through
EOF, obtain Backend/Data exact-head review and then independent AppSec
exact-head review. Stop in Draft before Ready.
```

No T1/T2 review is reopened. The one later production retry is already bounded
by Product Authority but may use only the authenticated final reviewed/merged
SQL after the separate GitHub lifecycle gates are resolved.

## 10. Handoff prohibitions

Do not:

```text
create a workaround that weakens T1
create another duplicate PR to relitigate B1-B4; this one post-PR129 anchor
  refresh is justified only by the newly observed live routine digest
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
