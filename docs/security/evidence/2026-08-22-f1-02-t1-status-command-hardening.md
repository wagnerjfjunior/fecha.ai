# FECH.AI — F1-02 T1 Status Command Hardening

**Status:** `DRAFT_REVISED_AFTER_APPSEC_GATE_2_REQUEST_CHANGES / GITHUB_ONLY / NOT_APPLIED / REAUDIT_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  

## 1. Objective

Establish a safe server-side authority boundary for operational broker status while preserving the minimum temporary compatibility window required before frontend/password cutover and before final PR-03 direct-UPDATE revocation.

This T1 scope remains one principal risk:

```text
operational broker status authority
→ ativo
→ apto_para_receber
```

This record does not authorize production application, Ready, merge, frontend cutover, password-flow implementation, PR-03 final revocation or Security Go.

## 2. Live context used

```text
FECH.AI main at T1 branch creation:
827f8591bfe4eee595a1aa22e169dcf6465f7fa3

PR:
#125

branch:
security/f1-02-status-command-hardening

Supabase project:
uobxxgzshrmbtjfdolxd

environment:
Pilot Production / production
```

The migration is versioned only. It has not been applied to Supabase.

## 3. Product authority contract

Approved target semantics:

```text
ROOT
→ may alter ativo/apto on authorized target

ADMIN_LOCAL
→ same company only
→ may alter ativo/apto

GESTOR
→ ordinary broker only
→ own managed ACTIVE teams only
→ may alter apto_para_receber only
→ may NOT alter ativo

CORRETOR
→ denied

NO AUTH
→ denied

INACTIVE PROFILE
→ denied

CROSS-TENANT TARGET
→ denied
```

Root authority in T1 is sourced only from:

```text
public.admins
user_id = auth.uid()
ativo IS TRUE
role = 'admin_global'
```

A `corretores.role='admin_global'` row by itself is not root authority for T1.

## 4. Material live findings before T1

READ_ONLY catalog inspection established:

- `public.corretores` has RLS enabled and FORCE RLS enabled;
- `authenticated` has broad table `UPDATE` on `public.corretores`;
- current `corretores_update` policy includes the self-row branch `user_id=auth.uid()`;
- authority-bearing fields are therefore directly mutable through the legacy surface;
- `public.admins` is not writable by `authenticated`;
- one active root exists in `public.admins`;
- current non-`admin_global` role/flag rows are internally coherent;
- `corretores.user_id` and `admins.user_id` have immediate unique mappings;
- the critical audit trigger exists and is enabled;
- the audit trigger function is `SECURITY DEFINER`, owner `postgres`, `search_path=public`, with body MD5 `3fdaca39d55f348ca36f796023f3260b` and ACL `{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}`.

A material legacy condition was also observed without PII exposure:

```text
corretores.role='admin_global' rows: 2
backed by active public.admins root: 1
not backed by active public.admins root: 1
```

T1 explicitly excludes the unbacked legacy `corretores.admin_global` row from root authority.

## 5. Current legacy RPCs fingerprinted by preflight

The migration binds current live definitions before changing the authority surface:

```text
public.alterar_role_corretor(uuid,text)
MD5 edde7ac084d416171a334d783cdcad3e

public.atualizar_time_corretor(uuid,uuid)
MD5 74965d3c682a3ae4a3c69bf6a7524b93

public.marcar_senha_inicial_definida()
MD5 2a7b28d4bb6342a99d075c4d3c49af4d

public.redefinir_senha_corretor(uuid,text)
MD5 2f1ff707c6ea94e0abf4ede0f2ec3835
```

Expected execution boundary at the pre-T1 live state:

```text
alterar_role_corretor:
authenticated EXECUTE = YES

atualizar_time_corretor:
authenticated EXECUTE = YES

marcar_senha_inicial_definida:
authenticated EXECUTE = YES

redefinir_senha_corretor:
authenticated EXECUTE = NO
```

Preflight also rejects any unexpected authenticated `SECURITY DEFINER` writer of `must_change_password` besides the approved self-service password completion RPC.

## 6. T1 implementation surface

Versioned migration:

```text
supabase/migrations/20260822121500_f1_02_harden_status_corretor_rpc.sql
```

The migration:

1. performs exact preflight against the current live baseline;
2. introduces `t1_is_root_strict()`;
3. introduces strict row-level RLS prefilter `t1_can_update_corretor_row_strict(...)`;
4. introduces an authority-update guard for `role`, `is_admin_local`, `is_gestor`, `empresa_id`, `time_id`, `user_id`;
5. removes broad authenticated table UPDATE from `corretores`;
6. temporarily retains authenticated column UPDATE only for:
   - `ativo`;
   - `apto_para_receber`;
   - `must_change_password`;
7. replaces the legacy update policy with a strict T1 prefilter;
8. guards the temporary direct-write compatibility surface;
9. hardens `atualizar_status_corretor` and grants authenticated EXECUTE;
10. fingerprints the applied T1 functions/triggers/policy for rollback coupling;
11. performs postflight verification;
12. embeds a rollback runbook requiring a separate pre-rollback proof.

## 7. First AppSec exact-head gate

The first independent Application Security Assurance review returned:

```text
VERDICT: REQUEST CHANGES
```

The prior exact head is historical evidence only and does not apply to the current head.

Material findings were:

```text
F1
server-side authority still depended on caller-mutable corretores fields

F2
inactive actor/root semantics insufficiently fail-closed

F3
actor authority race between authorization and mutation

F4
times.ativo not required fail-closed

F5
preflight / rollback coupling insufficiently exact
```

## 8. First-gate corrections

### F1 — authority integrity

Broad authenticated table UPDATE is removed.

Direct authenticated authority-field mutation is removed for:

```text
role
is_admin_local
is_gestor
empresa_id
time_id
user_id
```

The ordinary self-row branch is removed from the T1 UPDATE policy.

Root source is restricted to active `public.admins(role='admin_global')` for the authenticated subject.

A BEFORE authority trigger protects authority-field transitions even when reached through existing `SECURITY DEFINER` role/time RPCs.

### F2 — inactive actor/root

T1 user-scoped paths reject an existing inactive actor profile even when a root row exists.

### F3 — actor/root race

The authenticated actor profile and active root row are stabilized with `FOR SHARE` before mutation.

### F4 — active team

Manager authorization requires:

```text
times.ativo IS TRUE
```

### F5 — preflight / rollback coupling

Preflight binds:

- current status RPC owner/security/search_path/body/ACL;
- current `corretores` table ACL;
- current update policy expression;
- absence of pre-existing T1 objects;
- trusted-root DML boundary;
- RLS/FORCE RLS;
- required columns;
- role/flag coherence;
- unique actor mappings;
- critical audit trigger enabled state, exact trigger definition and audit function owner/security/search_path/body/ACL;
- current legacy RPC fingerprints and expected authenticated execution grants.

Applied T1 functions/triggers/policy receive self-fingerprints used by the rollback preflight.

## 9. Second AppSec exact-head gate

The second independent Application Security Assurance review audited exact head:

```text
0e8fefe297c15bb11b3a495bd3da639052961617
```

and returned:

```text
VERDICT: REQUEST CHANGES
T1 TARGET CONTRACT: FAIL
MULTI-TENANT: NOT FULLY PROVEN
AUTHORIZATION: FAIL
ACL: PASS
CONCURRENCY: FAIL
ROLLBACK: FAIL
READY: NO
PRODUCTION APPLICATION: NOT AUTHORIZED
SECURITY GO: DENIED / UNCHANGED
```

This verdict is historical after the current head changes. It is not silently converted to PASS.

## 10. Gate 2 findings and current corrections

### G2-F1 — manager password-state bypass

Gate 2 found that the temporary direct compatibility surface allowed a strict manager to change `must_change_password` for an ordinary broker in the manager's own team.

Current correction:

```text
GESTOR
→ ativo change: DENIED
→ must_change_password change: DENIED
→ apto_para_receber only
```

Admin-local temporary compatibility for `must_change_password` is explicit and remains same-tenant only until the password reset cutover.

### G2-F2 — SECURITY DEFINER effective-user bypass / no-op authority RPC side effect

Gate 2 correctly noted that a trigger cannot treat `current_user='authenticated'` as the only signal of a user-scoped request because a `SECURITY DEFINER` RPC executes effectively as its owner.

Current correction:

- when `auth.uid()` is present, T1 user-subject authorization runs regardless of effective `current_user`;
- the authority trigger distinguishes actual authority-field transitions from protected side effects;
- a no-op authority transition that still changes `ativo`, `apto_para_receber` or `must_change_password` must pass strict user-subject authorization;
- `alterar_role_corretor` and `atualizar_time_corretor` are preflight-fingerprinted so the guard is bound to the exact legacy definitions reviewed;
- the strict UPDATE policy no longer delegates candidate-row authority to legacy `is_root()`, `is_admin_local()` or `is_gestor()`.

The self-service password RPC remains a narrow explicit exception:

```text
old.user_id = auth.uid()
current_user = postgres
must_change_password true → false
ativo unchanged
apto unchanged
```

This preserves the already-completed mandatory-password self-service seam without converting it into an administrative password boundary.

### G2-F3 — manager team-authority revocation race

Gate 2 identified that the manager status RPC checked the authorizing `times` row but did not lock it.

Current correction:

```text
manager status operation
→ resolve exact own same-tenant ACTIVE team row
→ FOR SHARE OF times row
→ conditional target UPDATE
→ recheck target.time_id + times.gestor_id + times.ativo in final mutation
```

Concurrent revocation of `times.ativo` or reassignment of `gestor_id` must wait for the locked authority row before committing around the status mutation.

### G2-F4 — audit/preflight + rollback coupling

Current correction:

- preflight anchors critical audit trigger enabled state and exact trigger definition;
- preflight anchors audit function owner, SECURITY DEFINER, exact search path, body MD5 and ACL;
- T1 self-records function, trigger and policy fingerprints after apply;
- rollback begins with a mechanical verifier and aborts before mutating when T1 fingerprints/grants/audit surface do not match.

## 11. Current strict policy boundary

The temporary `corretores_update` policy no longer uses:

```text
public.is_root()
public.is_admin_local()
public.is_gestor()
user_id = auth.uid()
```

as candidate-row authority predicates.

It calls:

```text
public.t1_can_update_corretor_row_strict(
  empresa_id,
  time_id,
  role,
  is_admin_local,
  is_gestor
)
```

Strict behavior:

```text
root:
active public.admins/admin_global only

admin_local:
active coherent admin_local profile
same tenant

gestor:
active coherent gestor profile
same tenant
ordinary broker target only
own ACTIVE managed team only

corretor:
denied

legacy unbacked corretores.admin_global:
denied
```

The BEFORE triggers still enforce operation/field-specific authorization after this strict row prefilter.

## 12. Critical audit boundary

The existing critical audit trigger remains detection, not authorization.

Preflight now requires the exact live surface observed before T1:

```text
trigger:
trg_audit_trail_corretores_critical_update

enabled:
O

definition:
CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()

function body MD5:
3fdaca39d55f348ca36f796023f3260b

owner:
postgres

SECURITY DEFINER:
true

search_path:
public

ACL:
{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

If this material audit surface drifts before application, T1 preflight aborts.

## 13. Direct-write compatibility after current T1

The current T1 does not claim PR-03 final revocation.

Temporary authenticated direct column grants remain only for:

```text
ativo
apto_para_receber
must_change_password
```

But candidate rows are constrained by strict T1 RLS and transitions are constrained by T1 BEFORE guards.

This is a compatibility window only.

Planned follow-on cutovers remain:

```text
T2
frontend status cutover
→ remove direct ativo/apto dependency

T3/T4
administrative password reset cutover
→ server-side must_change_password semantics
→ remove direct must_change_password dependency

PR-03
→ final direct UPDATE revocation
```

## 14. Expected positive continuity

Static expected compatibility after T1:

```text
TimesTab handleToggleApto
→ authenticated atualizar_status_corretor
→ gestor own active managed team
→ apto update
```

`EditarCorretorModal` direct status/password writes remain temporary residual dependencies until their dedicated cutovers.

No runtime smoke has been executed for the new T1 because the migration is not applied.

## 15. Rollback

The migration contains an exact documented rollback recipe.

It restores:

- pre-T1 `corretores_update` policy;
- pre-T1 broad authenticated table UPDATE;
- pre-T1 status RPC body;
- pre-T1 status RPC ACL;
- removal of T1 helpers/triggers;
- removal of T1 self-fingerprint comments.

Before any rollback mutation, the documented rollback verifier checks:

- applied T1 function fingerprints;
- applied T1 trigger fingerprints and enabled state;
- applied T1 policy fingerprint;
- exact temporary authenticated column grants;
- critical audit trigger/function surface.

If the applied state has drifted from the recorded T1 fingerprint, the rollback must abort rather than overwrite unknown later changes.

Rollback is not executed by the migration and requires separate Product Authority authorization.

## 16. Evidence coverage

| Source | Ref / object | Coverage | Limitation |
|---|---|---|---|
| T1 migration | current PR #125 head | `INTEGRAL_READ` at implementer internal gate before the latest documentation-only evidence commit | static/versioned only; not applied |
| this evidence record | current PR #125 head | `INTEGRAL_READ` after update | documentation only |
| Supabase `corretores` ACL/policy/columns/indexes | `uobxxgzshrmbtjfdolxd / production` | `SUPABASE_CATALOG_OBSERVED` | read-only; no mutation |
| critical audit trigger/function | production | `SUPABASE_CATALOG_OBSERVED` | no runtime audit-event test |
| legacy role/time/password RPC definitions | production | `SUPABASE_CATALOG_OBSERVED` | exact current definitions used for preflight fingerprinting |
| `src/App.jsx` | blob `2541813e6af44f4e8112296b7d9666df9320db5d` | prior `INTEGRAL_READ`; unchanged blob revalidated | not re-read because unchanged |
| `src/components/TimesTab.jsx` | current main blob | `PARTIAL_READ` relevant call sites | static compatibility only |

## 17. Implementation / runtime boundary

```text
GitHub migration:
VERSIONED IN DRAFT PR

Supabase applied:
NO

T1 runtime test:
NO

Application Security independent PASS:
NO — Gate 2 requested changes; current head requires re-audit

Ready:
NO

Merge:
NO

Deploy:
NO

Security Go:
DENIED / UNCHANGED
```

## 18. Current gate

Current implementation-side assessment:

```text
T1 TARGET CONTRACT:
REVISED AFTER APPSEC GATE 2

MULTI-TENANT:
REVISED / REQUIRES INDEPENDENT RETEST

AUTHORIZATION:
REVISED / REQUIRES INDEPENDENT RETEST

ACL:
STATICALLY HARDENED / REQUIRES INDEPENDENT RETEST

CONCURRENCY:
REVISED / REQUIRES INDEPENDENT RETEST

ROLLBACK:
MECHANICAL PREFLIGHT ADDED / REQUIRES INDEPENDENT RETEST
```

Backend/Data implementation review does not self-grant an AppSec PASS.

## 19. Next gate

Repeat independent Application Security Assurance on the exact current head.

The reviewer must specifically re-test:

- manager password-state field restriction;
- `SECURITY DEFINER` interaction with `auth.uid()` and effective `current_user`;
- no-op authority RPC side effects;
- strict RLS prefilter and legacy-root containment;
- manager `times` row locking and final recheck;
- critical audit trigger/function preflight;
- applied T1 fingerprints;
- rollback preflight fail-closed behavior;
- target existence leakage;
- exact grants and RPC ACLs.

No Ready, merge, Supabase application, deployment or Security Go is authorized by this record.