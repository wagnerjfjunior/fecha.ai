# FECH.AI — F1-02 T1 Status Command Hardening

**Status:** `DRAFT_REVISED_AFTER_APPSEC_GATE_2_REQUEST_CHANGES / GITHUB_ONLY / NOT_APPLIED / REAUDIT_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Primary risk:** establish trustworthy server-side authority for `ativo` / `apto_para_receber` while preserving only the minimum temporary compatibility surface required before frontend/password cutover.  
**Environment:** Supabase production `uobxxgzshrmbtjfdolxd`; no separate test database/branch is adopted.

## 1. Exact scope

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

Any head movement invalidates an earlier exact-head AppSec verdict.

## 2. Product Authority contract

```text
ROOT
- trusted source ONLY public.admins.
- admins.user_id = auth.uid().
- admins.ativo IS TRUE.
- admins.role = admin_global.
- may change ativo/apto on authorized target.

ADMIN_LOCAL
- active strict admin_local profile.
- same empresa only.
- may change ativo/apto.
- during the temporary compatibility window, may also drive the current
  administrative must_change_password PATCH for same-tenant targets.
- this password-state direct write is temporary and must disappear in T3/T4.

GESTOR
- active strict gestor profile.
- same empresa.
- target must be ordinary role=corretor with no admin/gestor flags.
- target team must be ACTIVE and actually managed by the actor.
- may change apto_para_receber only.
- cannot change ativo.
- cannot change must_change_password.

CORRETOR / NO AUTH / INACTIVE ACTOR
- denied fail-closed.
```

Frontend tenant/company/role/team/privilege values are never authority inputs.

## 3. Live baseline before T1

READ_ONLY production catalog evidence established:

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
body md5 = ef89d686ebb3230ae4bef1b71d4860fd
ACL = {postgres=X/postgres,service_role=X/postgres}

public.corretores table ACL md5
afa3a93809a23f744356971cbc461855

corretores_update policy md5
a3b9b4a44e859728ca9c69f6e6b2a842
```

Aggregate authority invariants observed without PII:

```text
active admins.role=admin_global rows = 1
corretores.role=admin_global rows = 2
corretores.admin_global backed by active admins root = 1
corretores.admin_global NOT backed by active admins root = 1
non-admin_global role/flag mismatches = 0
ordinary rows carrying privilege flags = 0
null corretores.user_id rows = 0
```

Therefore:

```text
corretores.role='admin_global' != trusted root identity
```

## 4. Critical audit baseline now bound exactly

The Gate 2 review correctly identified that existence-by-name was insufficient.
READ_ONLY live evidence now anchors:

```text
trigger:
trg_audit_trail_corretores_critical_update

enabled:
O

exact trigger definition:
CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()

trigger function:
audit_trail_log_corretores_critical_update()
owner = postgres
SECURITY DEFINER = true
search_path = public
body md5 = 3fdaca39d55f348ca36f796023f3260b
ACL = {postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

The revised migration preflight and postflight bind this exact surface.

## 5. Legacy SECURITY DEFINER seams now explicitly fingerprinted

READ_ONLY live definitions relevant to T1:

```text
alterar_role_corretor(uuid,text)
SECURITY DEFINER
authenticated EXECUTE = yes
body md5 = edde7ac084d416171a334d783cdcad3e
writes role/is_admin_local/is_gestor/apto_para_receber
legacy authorization references is_root()

atualizar_time_corretor(uuid,uuid)
SECURITY DEFINER
authenticated EXECUTE = yes
body md5 = 74965d3c682a3ae4a3c69bf6a7524b93
writes time_id
legacy authorization references is_root()/is_admin_local()/is_gestor()

marcar_senha_inicial_definida()
SECURITY DEFINER
authenticated EXECUTE = yes
search_path = pg_catalog
body md5 = 2a7b28d4bb6342a99d075c4d3c49af4d
updates only the authenticated actor's must_change_password true -> false

redefinir_senha_corretor(uuid,text)
SECURITY DEFINER
authenticated EXECUTE = no
service_role EXECUTE = yes
body md5 = 2f1ff707c6ea94e0abf4ede0f2ec3835
```

A targeted catalog inventory established that the only authenticated-executable SECURITY DEFINER function directly writing `corretores.must_change_password` is `marcar_senha_inicial_definida()`.

## 6. AppSec Gate 1 — historical

The first independent exact-head audit returned:

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

Historical F1–F5 were preserved, not rewritten.

## 7. AppSec Gate 2 — historical exact-head result

Gate 2 audited HEAD:

```text
0e8fefe297c15bb11b3a495bd3da639052961617
```

Result:

```text
VERDICT = REQUEST CHANGES
T1 TARGET CONTRACT = FAIL
MULTI-TENANT = NOT FULLY PROVEN
AUTHORIZATION = FAIL
ACL = PASS
CONCURRENCY = FAIL
ROLLBACK = FAIL
READY = NO
PRODUCTION APPLICATION = NOT AUTHORIZED
SECURITY GO = DENIED / UNCHANGED
```

Material Gate 2 findings:

### G2-F1 — gestor could change must_change_password

The prior direct-compatibility guard denied gestor `ativo` changes but did not deny `must_change_password` changes. This violated the explicit `GESTOR -> apto only` contract.

**Revision now versioned:**

```text
manager branch:
ativo change -> deny
must_change_password change -> deny
only apto_para_receber may transition
```

Admin-local temporary password-state compatibility is now explicitly documented instead of implicit.

### G2-F2 — SECURITY DEFINER effective-user bypass

The prior direct-compat guard began with:

```text
current_user <> authenticated -> return NEW
```

That allowed user-subject SECURITY DEFINER calls running as postgres to bypass the compatibility guard.

**Revision now versioned:**

```text
if auth.uid() IS NOT NULL:
  always perform strict user-subject authorization
  regardless of current_user

if auth.uid() IS NULL:
  only postgres/service_role privileged platform operation may pass
```

The authority trigger also detects protected side effects when an authority-writing RPC emits a no-op role/time transition. A no-op `alterar_role_corretor` cannot use legacy helper authority merely to change `apto_para_receber`; strict root/admin authority is required.

The self-service password-completion exception is tightly bounded to:

```text
old.user_id = auth.uid()
current_user = postgres
must_change_password true -> false
ativo unchanged
apto_para_receber unchanged
```

The preflight additionally proves that `marcar_senha_inicial_definida()` is the only authenticated-executable SECURITY DEFINER direct writer of `must_change_password` in the observed live catalog.

### G2-F3 — manager team revocation race

The prior status RPC used the team row only inside an `EXISTS`, without stabilizing it.

**Revision now versioned:**

```text
manager status path:
- resolve authorized target + team relation without pre-locking target;
- lock the exact authorizing public.times row FOR SHARE;
- require same empresa;
- require target ordinary corretor;
- require team.gestor_id = actor id;
- require team.ativo IS TRUE;
- recheck target.time_id and the same team predicates in the final UPDATE.
```

A concurrent revocation of team `ativo` or `gestor_id` cannot commit through the authorization-to-mutation window.

### G2-F4 — rollback/preflight coupling insufficient

Gate 2 correctly found two gaps:

1. critical audit trigger was only checked by name/existence;
2. rollback said to prove exact T1 state but did not contain a mechanical verifier.

**Revision now versioned:**

```text
preflight:
- exact audit trigger enabled state;
- exact pg_get_triggerdef;
- audit function owner/security/search_path/body md5/ACL;
- exact status RPC baseline;
- exact table ACL;
- exact RLS policy hash;
- exact legacy SECURITY DEFINER seam fingerprints.

apply:
- each T1 function is self-fingerprinted at apply time using
  md5(pg_get_functiondef(...)) stored in COMMENT;
- both T1 triggers are fingerprinted using md5(pg_get_triggerdef(...));
- the T1 UPDATE policy is fingerprinted from USING + WITH CHECK expressions.

rollback preflight:
- compares live definitions to the stored T1 fingerprints;
- checks trigger enabled state;
- checks exact temporary grants;
- rechecks the critical audit surface;
- aborts before any DROP/CREATE on drift.

rollback postflight:
- verifies restoration of the exact pre-T1 status RPC md5;
- verifies authenticated status RPC EXECUTE removed;
- verifies broad authenticated UPDATE restored;
- verifies all T1-only functions removed.
```

Rollback remains a separate production mutation and is NOT authorized by this PR.

## 8. Strict RLS prefilter revision

The prior policy still used legacy `is_admin_local()` / `is_gestor()` helpers, creating avoidable row-candidate leakage.

The revised policy uses only:

```text
public.t1_can_update_corretor_row_strict(
  empresa_id,
  time_id,
  role,
  is_admin_local,
  is_gestor
)
```

The helper derives strict root/admin/gestor server-side and, for gestor, requires ordinary target role/flags plus own active managed team. It is only a visibility prefilter; final authority remains enforced in locked triggers/RPC predicates.

Legacy `corretores.role='admin_global'` without trusted `admins` backing does not satisfy this strict helper.

## 9. Direct DML target state after T1

```text
authenticated table-level UPDATE public.corretores = absent

authenticated column UPDATE temporarily retained only for:
- ativo
- apto_para_receber
- must_change_password

NO direct authenticated UPDATE on:
- role
- is_admin_local
- is_gestor
- empresa_id
- time_id
- user_id
- any other corretores column
```

The three temporary columns remain only until the frontend/password cutovers. This is not the final PR-03 revocation.

## 10. Static compatibility

Known callers remain:

```text
TimesTab.jsx
-> authenticated atualizar_status_corretor
-> supplies p_corretor_id + p_apto_para_receber
-> omits p_ativo
-> statically compatible with revised RPC defaults

EditarCorretorModal.salvar()
-> current direct PATCH ativo/apto
-> temporarily protected by strict RLS prefilter + compatibility trigger

EditarCorretorModal.redefinirSenha()
-> current direct PATCH must_change_password
-> temporary root/admin-local compatibility only
-> gestor denied
```

No frontend file changes in T1.

## 11. Validation / environment boundary

```text
GitHub migration versioned = YES
migration applied to Supabase = NO
runtime tested = NO
production smoke = NO
lab/test DB = NOT ADOPTED
live catalog checks = READ_ONLY
Gate 1 = REQUEST CHANGES / historical
Gate 2 = REQUEST CHANGES / historical
Gate 3 exact-head AppSec = REQUIRED
```

No test-offensive activity was performed in production.

## 12. Backend/Data self-review after Gate 2

```text
G2 manager must_change_password bypass: ADDRESSED IN VERSIONED MIGRATION
G2 SECURITY DEFINER effective-user bypass: ADDRESSED IN VERSIONED MIGRATION
G2 no-op authority RPC protected-side-effect bypass: ADDRESSED
G2 manager team revocation race: ADDRESSED WITH FOR SHARE + FINAL RECHECK
G2 audit trigger weak preflight: ADDRESSED WITH EXACT FINGERPRINT
G2 rollback procedural-only coupling: ADDRESSED WITH MECHANICAL PRE-ROLLBACK FINGERPRINT VERIFIER
legacy admin_global root bypass: REMAINS DENIED FOR T1
broad authenticated authority DML: REMAINS REMOVED IN TARGET STATE
```

This is implementer-side review only and does **not** grant an AppSec PASS.

## 13. Current verdict

```text
T1 IMPLEMENTATION = GITHUB DRAFT ONLY
SUPABASE APPLIED = NO
PRODUCTION VALIDATED = NO
READY = NO
MERGE = NO
PRODUCTION APPLICATION = NOT AUTHORIZED
SECURITY GO = DENIED / UNCHANGED
```

## 14. Next safe gate

```text
Repeat independent Application Security Assurance on the new exact PR #125 head.
```

No Ready, merge, Supabase application or deploy is authorized by this evidence file.
