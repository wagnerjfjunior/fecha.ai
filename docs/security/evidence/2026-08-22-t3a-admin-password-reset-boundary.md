# FECH.AI — T3A-v2 Administrative Password Reset Multi-Tenant Authority Boundary

**Status:** `CORRECTED_CANDIDATE / B1-B4 ADDRESSED / EXACT_HEAD_REVIEWS_PENDING / NOT_APPLIED / NOT_DEPLOYED / NOT_READY / NOT_MERGED`
**Initial evidence date:** `2026-08-22`
**Corrective evidence date:** `2026-08-23`
**Repository:** `wagnerjfjunior/fecha.ai`
**Base main:** `037232fe3da37a749ab980f783af92ff15e2baf2`
**Branch:** `security/t3a-admin-password-reset-boundary`
**Initial blocked PR head:** `45ad27668835b6458b52d2fb592cfa36b5589726`

This document records the corrected candidate. The final exact head must be
resolved live after the corrective commit; no review result may be carried from
the initial blocked head.

## 1. Authorized and prohibited scope

T3A changes only the administrative password-reset boundary:

- `auth.uid()` is the actor;
- company, role, authority flags and team ownership are derived server-side;
- root / admin_local / gestor authority is strict;
- cross-company access fails closed;
- `must_change_password=true` is established before any Auth password mutation;
- the stale direct authenticated write to `must_change_password` is revoked;
- the existing T1 triggers remain enabled;
- the pre-T3A T1 direct guard has an exact, drift-aware restoration path;
- the live `criar-usuario` v17 baseline remains the Edge rollback anchor.

This change does not authorize or perform:

- an `App.jsx` change;
- a production migration or other runtime mutation;
- an Edge production deployment;
- Ready, merge or Security Go;
- a broad grant, trigger disablement, data normalization or frontend authority.

## 2. LIVE_RESOLVED_STATE and MATERIAL_RECORDED_STATE

Read-only production state revalidated on `2026-08-23`:

```text
Supabase project: uobxxgzshrmbtjfdolxd / ACTIVE_HEALTHY / PostgreSQL 17
latest material migration: 20260822192552 f1_02_harden_status_corretor_rpc
public.t3_prepare_admin_password_reset(uuid): ABSENT
criar-usuario: v17 / ACTIVE / verify_jwt=false
live Edge ezbr_sha256: 679643d42dc944cc810580807f4b1a2f5a78ff30a0ce0d67f0713817b2eeb47f
T3A migration applied: NO
T3A hardened Edge deployed: NO
```

The v17 source was captured unchanged before hardening:

```text
commit: 23ba5d03e146e50cb510c065e70e2c8e5ed9794a
path: supabase/functions/criar-usuario/index.ts
message: chore(edge): version criar-usuario v17 live baseline
```

No PII was needed or returned by the catalog revalidation.

## 3. B1 — safe rollout ordering

The initial candidate documented the inverse order. T3A-v2 requires this exact
fail-closed rollout after all separate lifecycle authorities are granted:

```text
1. deploy the exact reviewed hardened Edge first
2. while the RPC is absent, prove reset_password returns denial/error
   and does not call auth.admin.updateUserById
3. apply the exact reviewed T3A migration
4. validate function bodies, comments, ACLs, grants, policies and triggers
5. run the separately-authorized bounded positive/negative/cross-tenant smoke
6. prove the stale direct client PATCH cannot change must_change_password
```

The hardened Edge calls `t3_prepare_admin_password_reset` before the Auth admin
API. A missing RPC, RPC error, generic denial or malformed response returns
before `updateUserById`. Therefore Edge-first intentionally creates a temporary
loss of administrative reset availability, not an insecure password transition.

The prohibited inverse order is:

```text
migration/revoke first -> still-live v17 Edge -> insecure state window
```

## 4. B2 — exact trust-anchor preflight

The migration now stops before DDL if any material authority anchor differs.

| Anchor | Exact pre-T3A expectation |
|---|---|
| Required roles | `postgres`, `authenticated`, `anon`, `service_role` |
| Authority tables | `admins`, `corretores`, `times` present with RLS and FORCE RLS |
| Authority columns | exact required UUID/text/boolean types |
| Identity uniqueness | valid, ready, immediate, non-partial, single-key unique `user_id` indexes on `admins` and `corretores` |
| `admins` authenticated/anon surface | no SELECT/INSERT/UPDATE/DELETE authority, including column grants |
| `corretores` authenticated UPDATE | no broad UPDATE; exactly `ativo`, `apto_para_receber`, `must_change_password` before T3A |
| `times` authenticated DML | SELECT + UPDATE only; exact single `times_update` policy |
| `corretores_update` | exact single permissive UPDATE policy with identical strict helper in USING and WITH CHECK |
| unexpected writer scan | only existing authenticated self-service password-state writer before T3A |
| context-key collision | no existing function contains `fechai.t3_admin_password_reset_context` |

Live fingerprints embedded in the preflight:

| Object | Expected MD5 / exact state |
|---|---|
| `auth.uid()` | `ea3b41bf29e2ad573067939329aa088e` |
| `t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)` | `3cc5c9279ed4a2f40acc6c3750fc7cc4` |
| `t1_guard_corretores_authority_update()` | `5e69ae5cb6717f634d758cfd5c1cd7a6` |
| pre-T3A `t1_guard_corretores_direct_compat_update()` | `99477024e337de5645dd042a30f8cf78` |
| authority trigger | enabled; `68ec30b4d5014867c6db837d7d9db136` |
| direct-compat trigger | enabled; `faf7f23f5e7c246a4500a7db9e518bc5` |
| critical audit trigger | enabled; `60e6c615f59d9196e0979d6e93d2ad94` |
| critical audit function | `3fdaca39d55f348ca36f796023f3260b` |
| `atualizar_status_corretor(uuid,boolean,boolean)` | `563dc0b60766bda1aaf5ed9814a1c8cd` |
| `marcar_senha_inicial_definida()` | `2a7b28d4bb6342a99d075c4d3c49af4d` |
| `is_root()` | `465c04885d729e63f1a1d4458fc2a1b0` |
| `is_admin_local()` | `64b982da412f62c324aa2dde210eea0c` |
| `my_empresa_id()` | `7d7a73d22953d547a103f89c7b676906` |
| `my_corretor_id()` | `c8f243d33d42837c46236625a74c3fb7` |

Policy correctness is asserted by exact command, permissiveness, role set,
USING and WITH CHECK expressions, plus the absence of additional UPDATE
policies. Merely observing `RLS enabled` is not accepted as proof.

## 5. Server-side authority contract

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

`is_gestor` remains intentionally irrelevant to admin-local authority, matching
the established T1 contract.

### Gestor

```text
auth.uid()
-> active unique public.corretores profile
-> role='gestor', is_gestor=true, is_admin_local=false
-> target is an ordinary broker in the same empresa
-> target.time_id identifies an active team in that empresa
-> team.gestor_id=actor.id
```

Same-company membership alone is insufficient.

The RPC accepts only `p_target_user_id`. Missing, unauthorized and out-of-scope
targets converge to a denial that the Edge exposes as the same generic `403`.

## 6. B4 — narrow T1 guard interoperability

The T1 authority guard and both T1 triggers are not dropped, disabled or
rebound. Only the direct-compatibility guard body changes.

After the RPC has completed strict server-side authorization and locked the
target row, it sets a transaction-local marker:

```text
fechai.t3_admin_password_reset_context
= auth.uid() : target.user_id : txid_current()
```

The enabled T1 direct guard admits the protected transition only when:

```text
current_user='postgres'                  -- SECURITY DEFINER execution only
auth.uid() is not null                   -- real authenticated actor preserved
marker actor=auth.uid()
marker target=OLD.user_id
marker transaction=txid_current()
must_change_password moves not-true -> true
ativo is unchanged
apto_para_receber is unchanged
```

The marker is local to the transaction and is cleared after the exact one-row
update. An error aborts that transaction. A context-key collision scan prevents
another reviewed-unrelated function from masquerading as T3. Ordinary direct
clients cannot satisfy both `current_user='postgres'` and the bound marker.

All remaining T1 guard branches are byte-for-byte the pre-T3A body. This keeps:

- self active-state denial;
- self password-state denial except the established self-service true-to-false path;
- root/admin_local T1 compatibility;
- gestor direct password-state denial;
- service/internal behavior already established by T1.

Reviewed candidate fingerprints:

```text
T3 RPC: 90c537dd4c2c7ae6fb7ae93373c4cc77
T3-aware direct guard: f2cbf4762b5f5b2d6c6eb56fcf0edc2b
pre-T3A direct guard restored by rollback: 99477024e337de5645dd042a30f8cf78
```

## 7. Password-state and Auth ordering

```text
authorize from server-side rows
-> lock the actor authority row FOR SHARE
-> lock exact target profile FOR UPDATE
-> for gestor, lock the active managed team FOR SHARE
-> bind T3 context to actor/target/transaction
-> set must_change_password=true through the enabled T1 guard
-> clear context and return authorized user_id
-> Edge calls auth.admin.updateUserById for that returned user_id
```

If the Auth call fails, `must_change_password=true` remains while the previous
Auth password remains active. This is recoverable and preserves the stronger
state. Auth-first is prohibited.

The RPC is executable only by `authenticated`; PUBLIC, `anon` and
`service_role` execution are explicitly revoked. The Edge uses the caller JWT
for the RPC. Its service-role client performs the Auth mutation only after the
caller-bound RPC succeeds; service_role is never treated as actor authority.

## 8. Direct-write bypass closure

`App.jsx` is unchanged. The known stale direct write to
`must_change_password=false` therefore remains code but loses database
authority. T3A revokes only that authenticated column grant and preserves the
temporary `ativo` / `apto_para_receber` grants.

Postflight requires the exact authenticated UPDATE surface to be:

```text
apto_para_receber
ativo
```

Any broad table UPDATE, unexpected column UPDATE or T3 RPC ACL drift aborts the
migration transaction.

## 9. B3 — executable, drift-safe rollback

The rollback begins with exact validation before any destructive statement:

- T3 RPC body `90c537dd...`, owner, SECURITY DEFINER config, marker and ACL;
- T3-aware guard body `f2cbf476...`, owner, SECURITY INVOKER config, marker and ACL;
- unchanged T1 authority guard, both enabled trigger definitions/comments and audit trigger;
- exact `corretores_update` and `times_update` policy semantics;
- exact policy-helper fingerprints and required grants;
- exact post-T3A `corretores` UPDATE columns (`ativo`, `apto_para_receber`);
- no unexpected context-key user.

If any check differs, the rollback stops. It never uses
`DROP FUNCTION IF EXISTS` and never grants after an unproven object state.

After preflight it atomically:

```text
recreates exact pre-T3A direct guard (MD5 99477024...)
-> restores its F1-02-T1-v3 self-fingerprint comment
-> drops the exact reviewed T3 RPC
-> restores only UPDATE(must_change_password) to authenticated
-> verifies the old guard/trigger/grant surface and absence of the context key
```

It does not rewrite any `must_change_password` row or Auth credential.

Operational rollback order remains database first. With the hardened Edge still
deployed and the RPC absent, administrative reset fails closed. Restoring the
v17 Edge is a later, separately-authorized operation against commit
`23ba5d03e146e50cb510c065e70e2c8e5ed9794a`.

## 10. B1-B4 coverage matrix

| Blocker / invariant | Corrective artifact | Candidate result | Runtime result |
|---|---|---|---|
| B1 Edge-first rollout | migration header, Edge branch, §§3/11 | addressed | not executed / separate gate |
| B2 trust-anchor preflight | migration exact preflight/postflight | addressed | live anchors read-only revalidated; migration not applied |
| B3 drift-safe rollback | exact rollback preflight/body/postflight | addressed | not executed / separate gate |
| B4 gestor/T1 interoperability | transaction-bound marker + enabled direct guard | addressed | not executed / separate gate |
| tenant from server | T3 RPC queries actor/target/company | preserved | not runtime-tested |
| actor=`auth.uid()` | Edge caller JWT + RPC | preserved | not runtime-tested |
| cross-company isolation | admin/gestor predicates + generic denial | preserved | not runtime-tested |
| strict root/admin_local/gestor | exact authority branches | preserved | not runtime-tested |
| no direct bypass | revoke only `UPDATE(must_change_password)` | preserved | not runtime-tested |
| T1/T2 closed-cycle protection | no T1 trigger disable; no T2 change | preserved | T1/T2 not reopened |
| frontend scope | no `App.jsx` diff | preserved | n/a |

“Addressed” is a candidate statement, not a specialist PASS, deployment proof
or Security Go.

## 11. Required acceptance matrix after later runtime authorization

```text
Edge-first with RPC absent                           FAIL CLOSED / NO AUTH MUTATION
root -> authorized target                           ALLOW
admin_local -> same-company non-root target         ALLOW
admin_local -> other company                        DENY
admin_local -> public.admins identity               DENY
admin_local -> missing target                       SAME EXTERNAL DENY
strict gestor -> ordinary broker own active team    ALLOW
gestor -> broker other/inactive team                DENY
gestor -> other company                             DENY
gestor -> admin_local/gestor target                  DENY
ordinary corretor -> any target                     DENY
inactive actor -> any target                        DENY
missing/invalid session                             DENY
client empresa/role/flags/time inputs                IGNORED AS AUTHORITY
must_change_password before Auth update              REQUIRED
direct authenticated PATCH must_change_password      DENY
arbitrary postgres write without exact marker        DOES NOT RECEIVE T3 EXCEPTION
rollback after any reviewed-object drift             STOP
```

## 12. Versioned artifacts and remaining gates

```text
supabase/functions/criar-usuario/index.ts
supabase/migrations/20260822211600_t3_admin_password_reset_boundary.sql
supabase/rollback/20260822211600_t3_admin_password_reset_boundary_rollback.sql
docs/security/evidence/2026-08-22-t3a-admin-password-reset-boundary.md
```

Required next gates on one resolved final head:

```text
1. integral material-file read
2. coverage-matrix reconciliation
3. Backend/Data exact-head review
4. independent AppSec exact-head review
5. stop before Ready pending new Product Authority
```

T3A-v2 does not grant Ready, merge, production application, Edge deployment,
runtime smoke, rollback execution or Security Go. T3B remains separate.
