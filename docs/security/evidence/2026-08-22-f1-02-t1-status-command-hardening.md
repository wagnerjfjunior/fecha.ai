# FECH.AI — F1-02 T1 Status Command Hardening

**Status:** `DRAFT_REVISED_AFTER_APPSEC_REQUEST_CHANGES / GITHUB_ONLY / NOT_APPLIED / REAUDIT_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Primary risk:** trusted server-side authority for `ativo` / `apto_para_receber` while preserving the temporary production compatibility window.  
**Environment:** Supabase production `uobxxgzshrmbtjfdolxd`; no separate test database/branch is adopted at this stage.

## 1. Exact base and branch

```text
Base:
main

Base SHA:
827f8591bfe4eee595a1aa22e169dcf6465f7fa3

Branch:
security/f1-02-status-command-hardening

Migration:
supabase/migrations/20260822121500_f1_02_harden_status_corretor_rpc.sql
```

Resolve the live PR head before every gate. Any new commit invalidates an earlier exact-head review.

## 2. Product Authority contract

```text
ROOT
- may change ativo and/or apto_para_receber on an authorized target.
- root authority for T1 must come from the trusted admins boundary.

ADMIN_LOCAL
- active, strict admin-local profile.
- same company only.
- may change ativo and/or apto_para_receber.

GESTOR
- active, strict gestor profile.
- same company.
- target must be ordinary role=corretor.
- target must be in an ACTIVE team actually managed by the actor.
- may change apto_para_receber only.
- any ativo transition is denied.

CORRETOR / NO AUTH / INACTIVE ACTOR
- denied fail-closed.
```

Frontend-supplied company, tenant, role, team or privilege values are never authority.

## 3. Live AS-IS evidence before T1

Read-only production catalog inspection established:

```text
public.corretores
RLS = true
FORCE RLS = true
owner = postgres

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

authenticated table privileges
SELECT + broad UPDATE

corretores_update policy md5
a3b9b4a44e859728ca9c69f6e6b2a842

historical ordinary self-row UPDATE branch
user_id = auth.uid()
```

The critical audit trigger is present:

```text
trg_audit_trail_corretores_critical_update
```

The T1 helper/guard objects are absent from production before application.

## 4. First independent Application Security Assurance gate

The first exact-head AppSec audit on the earlier T1 head returned:

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

The result is preserved as historical evidence. It is not retroactively rewritten.

Material findings:

```text
F1 BLOCKING
T1 trusted role/is_admin_local/is_gestor/empresa_id and related actor state
from public.corretores while authenticated broad direct UPDATE remained.
The authority source was therefore self-escalatable.

F2 REQUIRED
An active admins/root path could bypass the generic inactive-profile rule.

F3 REQUIRED
Actor authority was read before target mutation without stabilizing the actor
state, leaving a revocation/authorization race.

F4 REQUIRED
coalesce(times.ativo,true) failed open for NULL/unknown team state.

F5 REQUIRED
The rollback was described as exact, but preflight did not bind to the exact
pre-apply function body/ACL strongly enough.
```

The review also confirmed that the prior pre-authorization target `FOR UPDATE`
had already been removed and that target-side conditional predicates were a
material improvement.

## 5. Revised T1 strategy

The revised migration keeps the PR at one principal risk but expands the DB-side
hardening necessary for the status RPC to have a trustworthy authority source.

### 5.1 Exact preflight

Before any mutation, the migration requires the exact observed pre-T1 state:

```text
status function body md5
= ef89d686ebb3230ae4bef1b71d4860fd

status function ACL
= {postgres=X/postgres,service_role=X/postgres}

corretores table ACL md5
= afa3a93809a23f744356971cbc461855

corretores_update policy md5
= a3b9b4a44e859728ca9c69f6e6b2a842

T1 helper/guard objects
= absent

authenticated DML on admins
= absent

RLS/FORCE RLS on corretores/times/admins
= present

required columns/types/unique user mappings/audit trigger
= present
```

A read-only production query on 2026-08-22 revalidated all of those preflight
anchors as true. This does not apply the migration.

### 5.2 Authority-field integrity

T1 no longer leaves broad authenticated table UPDATE in place.

Target direct-DML state after T1:

```text
authenticated table-level UPDATE public.corretores
= absent

authenticated column UPDATE
= ativo
  apto_para_receber
  must_change_password

no authenticated UPDATE on:
role
is_admin_local
is_gestor
empresa_id
time_id
user_id
or any other corretores column
```

This is intentionally narrower than the old exposure but is not the final PR-03
revocation. The three columns remain only because the current frontend/password
paths still require a compatibility window before their separate cutovers.

### 5.3 Direct UPDATE policy

The old ordinary self-row direct update path is removed from
`corretores_update`.

The replacement policy retains only:

```text
strict T1 root
or admin_local same company
or gestor rows in managed teams
```

Root for this policy uses `public.t1_is_root_strict()` and therefore does not use
`corretores.role='admin_global'`.

### 5.4 Temporary direct-compatibility guard

A T1-only BEFORE trigger protects the three remaining direct compatibility
columns.

For direct authenticated Data API DML it revalidates:

```text
auth.uid()
actor profile
actor active state
strict admin_local / gestor role+flag consistency
strict root through admins only
tenant/company
gestor target role
gestor managed ACTIVE team
field transition
```

Direct clients cannot change their own `ativo` or `must_change_password` state.
The existing self-service password RPC remains a SECURITY DEFINER command and is
not converted back to direct table authority.

Gestor direct compatibility behavior is restricted to:

```text
ordinary broker
same company
own active managed team
apto_para_receber only
```

This prevents the legacy frontend PATCH path from bypassing the T1 server-side
business rule while the frontend cutover remains pending.

### 5.5 Strict root

T1 root authority is now:

```text
public.admins
user_id = auth.uid()
ativo IS TRUE
role = admin_global
```

`corretores.role='admin_global'` does not establish root for T1.

Production metadata confirms authenticated users do not have INSERT/UPDATE/DELETE
on `public.admins`.

### 5.6 Inactive actor

For the RPC:

```text
non-root requires an active corretores profile.
root with an existing corretores profile is denied if that profile is inactive.
root without a corretores profile remains supported through the trusted admins row.
```

For temporary direct DML, an existing actor profile must be active; a strict root
without a corretores profile remains supported.

### 5.7 Concurrency

The revised RPC stabilizes authority before target mutation:

```text
active admins/root row -> FOR SHARE
actor corretores profile -> FOR SHARE
then operation-specific target UPDATE
```

A concurrent role/company/active-state mutation of the actor cannot commit
through the authorization-to-mutation window without waiting for the actor lock.

The target is not pre-read or pre-locked. Authorization and target mutation remain
bound inside operation-specific conditional UPDATE statements.

### 5.8 Team state

All gestor checks now require:

```text
times.ativo IS TRUE
```

NULL/unknown team state is denied.

### 5.9 ACL target

After T1:

```text
public.atualizar_status_corretor
owner = postgres
SECURITY DEFINER
search_path = pg_catalog
EXECUTE authenticated = yes
EXECUTE anon/PUBLIC/service_role = no

public.t1_is_root_strict
owner = postgres
SECURITY DEFINER
search_path = pg_catalog
EXECUTE authenticated = yes
EXECUTE anon/service_role = no

public.t1_guard_corretores_direct_compat_update
owner = postgres
SECURITY INVOKER
search_path = pg_catalog
trigger-only use
```

### 5.10 Rollback coupling

The preflight now binds to the exact pre-T1 function definition and ACL, plus the
exact table ACL and UPDATE policy baseline.

The embedded rollback restores:

```text
pre-T1 status function body
search_path = public
service_role-only EXECUTE
broad authenticated table UPDATE
original self-row UPDATE policy
removal of T1 trigger/helper objects
```

Rollback is itself a separate production mutation and must first prove that the
currently applied state is still this exact T1 version. It must not overwrite
later drift.

## 6. Static compatibility evidence

Known current consumers remain:

```text
TimesTab.jsx
-> authenticated RPC call
-> p_corretor_id
-> p_apto_para_receber
-> p_ativo omitted

EditarCorretorModal.salvar()
-> current direct PATCH ativo/apto
-> remains temporarily compatible through narrowed column grants + guard

EditarCorretorModal.redefinirSenha()
-> current direct PATCH must_change_password
-> remains temporarily compatible until the password-reset slice
```

No frontend code is changed by T1.

The known controlled profile/time/role/password RPCs are `SECURITY DEFINER`, so
removing broad authenticated table UPDATE does not make those RPCs depend on the
removed caller table grant.

## 7. Scope exclusions

T1 still does not change:

```text
src/App.jsx
src/components/TimesTab.jsx
criar-usuario Edge Function
password-reset target semantics
final must_change_password flow
Vercel/deploy
real rows/data
PR #124
final PR-03 full direct-update revocation
Security Go
```

## 8. Validation status

```text
GitHub migration versioned: YES
migration applied to Supabase: NO
runtime tested: NO
production smoke: NO
lab/test DB: NOT ADOPTED
read-only live preflight anchors: REVALIDATED
first AppSec audit: REQUEST CHANGES / HISTORICAL
revised exact-head AppSec audit: REQUIRED
```

During static self-review, invalid schema-qualified uses of SQL special forms
`COALESCE`/`POSITION` were detected in an intermediate Draft head and corrected
before any production application or new AppSec gate.

## 9. Current verdict

```text
TARGET CONTRACT DESIGN: REVISED
AUTHORITY SOURCE INTEGRITY: ADDRESSED IN VERSIONED MIGRATION
T1 IMPLEMENTATION: GITHUB DRAFT ONLY
SUPABASE APPLIED: NO
PRODUCTION VALIDATED: NO
PR-03 ELIGIBILITY: UNCHANGED / NOT_YET_MATERIALLY_ELIGIBLE
SECURITY GO: DENIED / UNCHANGED
```

## 10. Next safe gate

```text
Repeat independent Application Security Assurance on the new exact PR #125 head.
```

No Ready, merge, Supabase application, deploy or Security Go is authorized by
this document.