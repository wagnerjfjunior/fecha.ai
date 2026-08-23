# FECH.AI — SFJM Current Material State

**Status:** `MATERIAL_RECORDED_STATE / T3A_ACTIVE_CORRECTION / SECURITY_GO_DENIED / DOCUMENTATION_ONLY`  
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

A T3A candidate is versioned in the active security change set. The initial candidate contains:

```text
versioned criar-usuario Edge baseline + hardened reset path
public.t3_prepare_admin_password_reset(uuid) migration
revocation of authenticated UPDATE(must_change_password)
executable rollback
evidence document
```

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
  target ACTIVE managed team
  team.empresa_id = actor.empresa_id
  team.gestor_id = actor.id
```

Same-company membership alone is insufficient for gestor authority.

## 6. T3A current blockers — REQUIRED IN THIS PR

The initial T3A candidate received `REQUEST CHANGES`. Do not open a second T3A PR merely to resolve these findings. Correct the existing T3A change set and then re-run exact-head validation.

### B1 — safe rollout ordering

Unsafe initial ordering:

```text
migration/revoke must_change_password grant
→ then hardened Edge
```

This could leave the still-live v17 Edge able to change Auth password while the stale frontend can no longer correct state, producing an administrative password without mandatory-change enforcement.

Required fail-closed rollout semantics:

```text
1. deploy reviewed hardened Edge first
2. before RPC exists, reset_password fails closed and does not mutate Auth
3. apply reviewed T3A migration
4. validate catalog/ACL/fingerprints
5. controlled positive + negative + cross-tenant smoke
```

The temporary loss of administrative reset availability is preferable to an insecure password transition.

### B2 — trust-anchor preflight

The T3A RPC trusts server-side authority data in `admins`, `corretores` and `times`. The migration must fail closed against material drift in the grants/policies/helpers that protect those fields.

At minimum the corrected preflight must prove the expected contract for:

```text
admins authority columns and authenticated DML absence
corretores authority-bearing columns and exact authenticated UPDATE surface
RLS/FORCE on required tables
relevant times UPDATE policy/grants used by gestor authority
required helper/function fingerprints when they are part of the trust chain
T1 guards/triggers that materially interact with the password-state update
```

`RLS ENABLED != POLICY CORRECT`.

### B3 — drift-safe rollback

The rollback must not blindly drop whatever function currently has the T3A name or restore grants after material drift.

Before destructive rollback operations it must validate the exact reviewed T3A object/ACL/fingerprint and the expected current grant state. If the object changed, rollback must stop fail-closed.

Rollback must also restore any T1 guard body changed by T3A to its exact pre-T3A fingerprint/semantics.

Rollback does not rewrite user password-state data merely to recreate an earlier visual state.

### B4 — T1 guard interoperability

Live production evidence shows that the T1 direct-compatibility guard currently rejects gestor changes to `must_change_password`.

The corrected T3A design must preserve T1 and introduce only a narrowly provable server-internal path for an already-authorized T3 administrative reset. Prohibited solutions include:

```text
disabling the T1 trigger
broadening authenticated UPDATE
granting service_role/public execution to the T3 RPC
trusting client role/empresa/time
using frontend state as authority
allowing arbitrary postgres writes to masquerade as T3
```

The final implementation must prove that ordinary direct client writes remain denied while the strict server-authorized T3 path works for root/admin_local/gestor according to contract.

## 7. Material blockers

Until B1-B4 are corrected and independently revalidated on one exact final head:

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
Continue the existing T3A change set and correct B1-B4 without opening another T3A PR.
```

Required sequence for the next conversation:

```text
1. resolve FECH.AI main live
2. bootstrap normally
3. resolve active T3A PR live and exact current head
4. read SFJM from that PR head because this transition is PR_HEAD_ONLY until merge
5. revalidate the material live anchors used by B1-B4
6. correct Edge/migration/rollback/evidence in the same T3A change set
7. update the PR description so it matches the final corrected scope/head
8. read final material files integral to EOF
9. run Backend/Data exact-head review
10. run independent AppSec exact-head review
11. stop before Ready unless Product Authority separately authorizes Ready
```

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
