# FECH.AI — F1-02 T1 Status Command Hardening

**Status:** `DRAFT_REVISED_AFTER_APPSEC_REQUEST_CHANGES / GITHUB_ONLY / NOT_APPLIED / REAUDIT_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Primary risk:** establish trustworthy server-side authority for `ativo` / `apto_para_receber` while preserving only the minimum temporary compatibility surface required before frontend/password cutover.  
**Environment:** Supabase production `uobxxgzshrmbtjfdolxd`; no separate test database/branch is adopted.

## 1. Base / branch / files

```text
Base:
main

Base SHA:
827f8591bfe4eee595a1aa22e169dcf6465f7fa3

Branch:
security/f1-02-status-command-hardening

Changed files:
1. supabase/migrations/20260822121500_f1_02_harden_status_corretor_rpc.sql
2. docs/security/evidence/2026-08-22-f1-02-t1-status-command-hardening.md
```

Resolve the live PR head before every gate. Any head movement invalidates an earlier exact-head review.

## 2. Product Authority contract

```text
ROOT
- authority source: ONLY public.admins.
- admins.user_id = auth.uid().
- admins.ativo IS TRUE.
- admins.role = admin_global.
- may change ativo/apto on an authorized target.

ADMIN_LOCAL
- active corretores profile.
- role = admin_local.
- is_admin_local = true.
- is_gestor = true, matching the current role/flag contract used by alterar_role_corretor.
- same empresa only.
- may change ativo/apto.

GESTOR
- active corretores profile.
- role = gestor.
- is_gestor = true.
- is_admin_local = false.
- same empresa.
- target = ordinary role=corretor.
- target team must be ACTIVE and actually managed by the actor.
- may change apto only.
- ativo transition denied.

CORRETOR / NO AUTH / INACTIVE ACTOR
- denied fail-closed.
```

Frontend-supplied tenant/company/role/team/privilege values are never accepted as authority inputs.

## 3. Live AS-IS evidence before T1

Read-only production catalog inspection established:

```text
public.corretores
RLS = true
FORCE RLS = true
owner = postgres
authenticated = SELECT + broad table UPDATE

public.times
RLS = true
FORCE RLS = true

public.admins
RLS = true
FORCE RLS = true
authenticated INSERT/UPDATE/DELETE = absent

public.atualizar_status_corretor(uuid,boolean,boolean)
owner = postgres
SECURITY DEFINER = true
search_path = public
function definition md5 = ef89d686ebb3230ae4bef1b71d4860fd
ACL = {postgres=X/postgres,service_role=X/postgres}
authenticated EXECUTE = false
service_role EXECUTE = true

public.corretores table ACL md5
afa3a93809a23f744356971cbc461855

corretores_update policy md5
a3b9b4a44e859728ca9c69f6e6b2a842

historical ordinary self-row UPDATE branch
user_id = auth.uid()

critical audit trigger
trg_audit_trail_corretores_critical_update = present

T1 helper/guard objects
= absent before application
```

A read-only preflight query on 2026-08-22 confirmed the exact function body/ACL, table ACL, update policy, RLS/FORCE RLS, audit trigger, absence of T1 objects and absence of authenticated DML on `admins`.

## 4. Material live authority findings

Aggregate/invariant queries were used; no user identifiers, email addresses, names or raw PII were returned.

Observed before T1:

```text
active admins.role=admin_global rows:
1

corretores.role=admin_global rows:
2

corretores.admin_global backed by active admins root:
1

corretores.admin_global NOT backed by active admins root:
1

non-admin_global role/flag mismatches:
0

ordinary rows carrying privilege flags:
0

null corretores.user_id rows:
0
```

Material interpretation:

```text
corretores.role='admin_global'
!= trusted root identity
```

At least one legacy `corretores.admin_global` row is not backed by the trusted `admins` root boundary. T1 therefore must not accept `corretores.role='admin_global'` directly or indirectly as root authority.

The live helper definitions confirmed the legacy compatibility risk:

```text
public.is_root()
- accepts active public.admins
  OR corretores.role='admin_global'

public.is_admin_local()
- treats role admin_global as admin-local compatible

public.is_gestor()
- treats role admin_global as gestor compatible
```

Those helpers remain legacy project behavior but are not sufficient as T1 authority proof by themselves.

## 5. First independent Application Security Assurance gate

The first exact-head AppSec audit returned:

```text
REQUEST CHANGES
T1 TARGET CONTRACT = FAIL
MULTI-TENANT = FAIL
AUTHORIZATION = FAIL
ACL = PASS
CONCURRENCY = FAIL
ROLLBACK = FAIL
READY = NO
SECURITY GO = DENIED / UNCHANGED
```

Historical findings preserved:

```text
F1 BLOCKING
Authority consumed by T1 was self-escalatable while authenticated broad direct UPDATE remained.

F2 REQUIRED
Inactive root/profile semantics were not consistently fail-closed.

F3 REQUIRED
Actor authority was read before mutation without stabilization.

F4 REQUIRED
coalesce(times.ativo,true) failed open.

F5 REQUIRED
The claimed exact rollback was insufficiently coupled to the exact pre-apply function/ACL state.
```

The prior AppSec verdict applies only to its earlier exact head and is invalidated by subsequent commits.

## 6. Revised T1 — exact preflight

Before any mutation the migration requires the exact observed baseline:

```text
status RPC body md5
= ef89d686ebb3230ae4bef1b71d4860fd

status RPC ACL
= {postgres=X/postgres,service_role=X/postgres}

corretores table ACL md5
= afa3a93809a23f744356971cbc461855

corretores_update policy md5
= a3b9b4a44e859728ca9c69f6e6b2a842

authenticated broad table UPDATE
= present before T1

authenticated pre-existing column UPDATE grants
= absent

authenticated DML on admins
= absent

active admins/admin_global root
= at least one

RLS/FORCE RLS on corretores/times/admins
= present

required columns/types
= present

unique user_id mappings required for corretores/admins
= present

non-admin_global role/flag inconsistencies
= absent

critical audit trigger
= present

T1 helper/guard functions/triggers
= absent
```

Any material drift causes the migration to abort before applying T1.

## 7. Revised T1 — direct DML integrity

T1 removes broad authenticated table UPDATE and keeps only the three temporary compatibility columns:

```text
authenticated table UPDATE public.corretores
= revoked

authenticated column UPDATE
= ativo
= apto_para_receber
= must_change_password

NO authenticated direct UPDATE on:
role
is_admin_local
is_gestor
empresa_id
time_id
user_id
or any other corretores column
```

This is not the final PR-03 revocation. These three fields remain temporarily because the current frontend/password paths have not yet been cut over.

The ordinary self-row branch is removed from the UPDATE policy.

## 8. Revised T1 — strict root

T1 introduces `public.t1_is_root_strict()`:

```text
public.admins
user_id = auth.uid()
ativo IS TRUE
role = admin_global
```

`corretores.role='admin_global'` is not a root source for T1.

The strict root helper is `SECURITY DEFINER`, owned by `postgres`, fixed to `search_path=pg_catalog`, executable by `authenticated`, and not executable by `anon` or `service_role` under the T1 target ACL.

## 9. Revised T1 — authority-update guard

A new T1-only BEFORE trigger protects every authority-bearing `corretores` transition:

```text
trg_t1_guard_corretores_authority_update

BEFORE UPDATE OF:
role
is_admin_local
is_gestor
empresa_id
time_id
user_id
```

Its function is `SECURITY INVOKER` with fixed `search_path=pg_catalog`.

The guard is intentionally required even after direct column grants are removed because current authenticated `SECURITY DEFINER` RPCs still update role/time authority fields. `auth.uid()` remains the request actor inside those calls.

Live inventory confirmed the material existing RPCs:

```text
alterar_role_corretor
- SECURITY DEFINER
- authenticated executable
- updates role / is_admin_local / is_gestor
- also updates apto_para_receber
- legacy authorization currently references public.is_root()

atualizar_time_corretor
- SECURITY DEFINER
- authenticated executable
- updates time_id
- legacy authorization currently references public.is_root()/is_admin_local()/is_gestor()

atualizar_perfil_corretor
- SECURITY DEFINER
- does not update T1 authority fields

marcar_senha_inicial_definida
- SECURITY DEFINER
- updates must_change_password only
```

The T1 authority guard therefore enforces the final transition independently of those legacy helper decisions.

Authority guard contract:

```text
SELF authority/identity change
= denied for user-scoped requests

user_id change
= denied

empresa_id change
= denied

role/flag transition
= strict root OR strict same-company admin_local
= role limited to corretor/gestor/admin_local
= role/flag pair must be internally coherent
= same actor cannot alter own authority

admin_local transition
role=admin_local
is_admin_local=true
is_gestor=true

manager transition
role=gestor
is_admin_local=false
is_gestor=true

ordinary broker
role=corretor
is_admin_local=false
is_gestor=false

time transition
= strict root
  OR strict same-company admin_local
  OR strict gestor assuming an unassigned ordinary broker into one of the gestor's own ACTIVE teams

legacy corretores.admin_global without trusted admins root
= denied by strict transition rules
```

Privileged platform operations without a user subject remain outside this user-scoped boundary and require `current_user` to be `postgres` or `service_role` in the guard.

## 10. Revised T1 — direct compatibility guard

A separate T1 BEFORE trigger protects the three remaining direct compatibility fields:

```text
ativo
apto_para_receber
must_change_password
```

For direct authenticated Data API DML it revalidates:

```text
auth.uid()
strict root through admins only
active actor profile when present
strict admin_local/gestor role+flag consistency
tenant/company
gestor target role
gestor own ACTIVE team
field transition
```

Direct user-scoped DML cannot change the actor's own `ativo` or `must_change_password` state.

Gestor compatibility behavior remains:

```text
ordinary broker
same company
own ACTIVE managed team
apto_para_receber only
ativo denied
```

`SECURITY DEFINER` controlled commands such as the self-service password RPC are not reclassified as direct Data API authority.

## 11. Revised T1 — status RPC authorization

The replacement `public.atualizar_status_corretor(uuid,boolean,boolean)` is:

```text
owner = postgres
SECURITY DEFINER
search_path = pg_catalog
EXECUTE authenticated = yes
EXECUTE anon/PUBLIC/service_role = no
```

Actor/root authority is stabilized before target mutation:

```text
trusted admins/root row -> FOR SHARE
actor corretores profile -> FOR SHARE
then conditional target UPDATE
```

Root with an existing inactive `corretores` profile is denied. A strict root with no `corretores` profile remains supported by the trusted `admins` row.

Target behavior:

```text
ROOT
- target id must exist.
- may change ativo/apto.

ADMIN_LOCAL
- same company only.
- may change ativo/apto.

GESTOR
- p_ativo must be NULL.
- same company.
- target role=corretor.
- target admin/gestor flags false.
- target has a team.
- team belongs to same company.
- team.gestor_id = actor corretor id.
- team.ativo IS TRUE.
- may change apto only.

CORRETOR / unauthorized role/flag combination
- denied.

Unknown/cross-tenant/not-authorized target
- converges on TARGET_NOT_AUTHORIZED.
```

No pre-authorization target row lock is used.

## 12. Concurrency / fail-closed

```text
actor authority/root state
= stabilized with FOR SHARE before target mutation

target authorization + mutation
= bound in operation-specific conditional UPDATE

gestor team state
= must satisfy ativo IS TRUE

NULL/unknown team state
= denied
```

The authority guard also locks the user-scoped actor/root source before permitting role/time authority transitions.

## 13. Rollback coupling

The preflight binds to the exact pre-T1 status function body/ACL, table ACL and UPDATE policy observed live.

The embedded rollback restores the documented pre-T1 surface:

```text
pre-T1 status RPC body
search_path=public
service_role-only EXECUTE
broad authenticated table UPDATE
original self-row UPDATE policy
removal of T1 direct-compat guard
removal of T1 authority guard
removal of T1 strict-root helper
```

Rollback is a separate production mutation. Before rollback, the currently applied state must be proven to still be this exact T1 version; rollback must not overwrite later drift.

## 14. Static compatibility

Known current callers remain:

```text
TimesTab.jsx
-> authenticated atualizar_status_corretor
-> p_apto_para_receber supplied
-> p_ativo omitted

EditarCorretorModal.salvar()
-> current direct PATCH ativo/apto
-> temporary narrowed columns + compat guard

EditarCorretorModal.redefinirSenha()
-> current direct PATCH must_change_password
-> temporary narrowed column + compat guard until password reset slice
```

No frontend code changes in T1.

The known profile/time/role/password RPCs are `SECURITY DEFINER`, so removal of broad caller table UPDATE does not make their internal DML depend on the removed authenticated table grant.

## 15. Scope exclusions

T1 does not change:

```text
src/App.jsx
src/components/TimesTab.jsx
criar-usuario Edge Function
password-reset target semantics
final must_change_password workflow
Vercel/deploy
real rows/data
PR #124
final PR-03 full direct-update revocation
Security Go
```

## 16. Validation status

```text
GitHub migration versioned: YES
migration applied to Supabase: NO
runtime tested: NO
production smoke: NO
lab/test DB: NOT ADOPTED
read-only live preflight anchors: REVALIDATED
live aggregate authority invariants: REVALIDATED
first AppSec audit: REQUEST CHANGES / HISTORICAL
revised exact-head AppSec audit: REQUIRED
```

During static self-review, invalid schema-qualified uses of SQL special forms `COALESCE`/`POSITION` were found in an intermediate Draft head and corrected before production application or the next AppSec gate.

## 17. Current verdict

```text
TARGET CONTRACT DESIGN: REVISED
AUTHORITY SOURCE INTEGRITY: ADDRESSED IN VERSIONED MIGRATION
LEGACY ADMIN_GLOBAL ROOT BYPASS: ADDRESSED FOR T1
AUTHORITY-WRITING RPC BYPASS: GUARDED IN VERSIONED MIGRATION
T1 IMPLEMENTATION: GITHUB DRAFT ONLY
SUPABASE APPLIED: NO
PRODUCTION VALIDATED: NO
PR-03 ELIGIBILITY: UNCHANGED / NOT_YET_MATERIALLY_ELIGIBLE
SECURITY GO: DENIED / UNCHANGED
```

## 18. Next safe gate

```text
Repeat independent Application Security Assurance on the new exact PR #125 head.
```

No Ready, merge, Supabase application, deploy or Security Go is authorized by this document.
