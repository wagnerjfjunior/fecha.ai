# FECH.AI — F1-02 T1 Status Command Hardening

**Status:** `DRAFT_IMPLEMENTED / GITHUB_ONLY / NOT_APPLIED / PRODUCTION_GATE_PENDING`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Risk:** one narrow server-side authority boundary for `ativo` / `apto_para_receber`  
**Environment:** Supabase `uobxxgzshrmbtjfdolxd` is the only active database environment; no test branch is adopted at this stage.

## 1. Exact anchors

```text
Base branch:
main

Base SHA at T1 branch creation:
827f8591bfe4eee595a1aa22e169dcf6465f7fa3

Branch:
security/f1-02-status-command-hardening

Migration:
supabase/migrations/20260822121500_f1_02_harden_status_corretor_rpc.sql
```

The active documentation reconciliation PR #124 remains separate and is not modified by T1. Its SFJM state is `PR_HEAD_ONLY` until independently authorized lifecycle changes occur.

## 2. Product Authority decisions used by T1

The following target rules were explicitly approved before implementation:

```text
1. Gestor may change apto_para_receber only for ordinary brokers in teams the gestor manages.
2. Gestor does not change ativo.
3. Root may change operational status on an authorized target.
4. Admin local may change ativo/apto_para_receber only inside its own company.
5. Frontend is not authority for tenant/company/team/role.
6. Direct frontend writes will be removed in a later cutover, not in T1.
```

Password-reset decisions are intentionally deferred to their own backend/frontend risk slices and are not implemented by this PR.

## 3. Live AS-IS evidence observed before implementation

Read-only Supabase catalog inspection established:

```text
public.corretores:
RLS enabled = true
FORCE RLS = true
owner = postgres

authenticated table privileges:
SELECT = present
UPDATE = present

public.atualizar_status_corretor(uuid, boolean, boolean):
owner = postgres
SECURITY DEFINER = true
search_path = public
EXECUTE authenticated = false
EXECUTE anon = false
EXECUTE service_role = true
```

The pre-T1 function authorizes root/admin_local/gestor but allows a gestor to reach any target in the same company and does not express the approved field-level rule that `ativo` is forbidden to gestor.

Repository source evidence also establishes:

```text
src/components/TimesTab.jsx
→ authenticated frontend caller of atualizar_status_corretor
→ used for apto_para_receber

src/App.jsx / EditarCorretorModal.salvar()
→ atualizar_perfil_corretor
→ direct PATCH public.corretores for ativo/apto_para_receber
```

Therefore:

```text
CALL SITE EXISTS != CURRENT RPC EXECUTABLE BY AUTHENTICATED
```

and the current direct PATCH remains a compatibility dependency until the separately scoped frontend cutover.

## 4. T1 target contract

T1 changes only `public.atualizar_status_corretor(uuid, boolean, boolean)` and its EXECUTE ACL.

### Actor

```text
auth.uid()
→ resolved server-side
```

No caller-supplied tenant, company, team, role or privilege flag is accepted.

### Root

Platform root is resolved from the server-side `public.admins` relationship. The historical active `admin_global` compatibility rule remains temporarily recognized because removing that broader authority model belongs to the later PR-03/direct-update closure.

### Admin local

```text
active profile
+ admin-local authority
+ target empresa_id == actor empresa_id
→ may change ativo and/or apto_para_receber
```

### Gestor

```text
active profile
+ gestor authority
+ same empresa
+ target is ordinary role=corretor
+ target is not admin_local/gestor
+ target time belongs to actor as gestor
→ may change apto_para_receber only
```

Any non-null `p_ativo` from a gestor is denied.

### Corretor / missing / inactive actor

Denied fail-closed.

### Target, authorization and concurrency

The first draft selected the target `FOR UPDATE` before the final authorization decision. That was corrected before independent review because an authenticated unauthorized caller should not be able to lock a foreign target row merely by knowing its ID.

The current T1 contract uses operation-specific conditional `UPDATE` predicates:

```text
root:
UPDATE by target id

admin_local:
UPDATE where target id + actor empresa_id

gestor:
UPDATE apto only where target id + actor empresa_id
+ ordinary broker role/flags
+ target time belongs to actor as gestor
```

The authorization predicate and mutation are therefore evaluated in the same database statement. A target that does not satisfy the operation-specific authority predicate is not updated, and the function returns the same bounded `TARGET_NOT_AUTHORIZED` result without distinguishing nonexistence from cross-tenant/unauthorized membership.

This avoids a pre-authorization row lock and avoids target-existence disclosure through differentiated error codes.

### Audit

The existing `trg_audit_trail_corretores_critical_update` trigger remains responsible for successful critical-state change logging. T1 does not create a second audit subsystem.

## 5. ACL target

After T1:

```text
EXECUTE postgres/owner = present
EXECUTE authenticated = present
EXECUTE anon = absent
EXECUTE PUBLIC = absent
EXECUTE service_role = absent
```

The function uses:

```text
SECURITY DEFINER
search_path = pg_catalog
fully qualified application objects
```

`authenticated UPDATE public.corretores` is intentionally preserved during T1 because removing it before frontend cutover would create an incompatible runtime state. Revocation remains a separate PR-03 action.

## 6. Production-only operating constraint

Product Authority explicitly decided not to create or maintain a Supabase test database/branch at the current stage.

This changes the validation strategy but does not relax correctness requirements.

Before any production application, T1 therefore requires:

```text
1. exact-head review of the migration;
2. independent Application Security Assurance review;
3. re-resolution of production catalog immediately before application;
4. explicit production-change authorization;
5. migration preflight must pass before mutation;
6. migration postflight must prove owner/security mode/search_path/ACL;
7. no destructive/offensive production testing;
8. controlled positive smoke only after separate authorization;
9. rollback remains immediately available.
```

No claim is made that absence of a test environment is equivalent to lab validation. It is an accepted operating constraint with additional production risk.

## 7. Fail-closed migration design

The migration aborts before replacing the function when material catalog prerequisites drift, including:

```text
missing tables/function/auth.uid
required role missing
unexpected owner/security mode/search_path
unexpected current ACL state
direct UPDATE already revoked
RLS/FORCE RLS drift
required corretores/admins/times columns or types missing
user_id uniqueness missing
```

The postflight aborts the transaction if the resulting contract does not prove:

```text
function exists
owner = postgres
SECURITY DEFINER
search_path = pg_catalog
authenticated EXECUTE present
anon/PUBLIC/service_role EXECUTE absent
no unexpected executor
direct UPDATE compatibility window still present
```

## 8. Exact rollback

The migration contains a version-coupled commented rollback that restores the pre-T1 live function body and ACL:

```text
authenticated EXECUTE → revoked
service_role EXECUTE → restored
search_path → public
pre-T1 same-company authorization body → restored
```

Rollback execution is a separate production mutation and requires explicit authorization.

## 9. Scope exclusions

T1 does not alter:

```text
src/App.jsx
src/components/TimesTab.jsx
criar-usuario Edge Function
password reset
must_change_password
corretores table UPDATE grant/policy
other RPC bodies
RLS policies
real users or data
Vercel/deploy
PR #124
Security Go
```

## 10. Residual risk

### ACTIVE_RESIDUAL_RISK — authority-bearing fields still directly writable

Until PR-03 revokes the broad `authenticated UPDATE` path, authority-bearing fields on `public.corretores` remain part of the known F1-02 exposure. T1 does not claim to close self-escalation by itself.

### ACTIVE_RESIDUAL_RISK — no separate database test environment

T1 has not been applied or exercised in an isolated Supabase environment. This is explicit and must not be converted into a test PASS.

### PLANNED FUTURE PR — frontend cutover

After T1 is independently accepted/applied, `EditarCorretorModal` and `TimesTab` must converge on the controlled RPC with fail-closed UI handling. The direct `ativo/apto_para_receber` PATCH is then removed.

## 11. Current verdict

```text
TARGET CONTRACT: ESTABLISHED
MIGRATION: VERSIONED ON DRAFT BRANCH
SUPABASE APPLIED: NO
PRODUCTION TESTED: NO
FRONTEND CUTOVER: NO
DIRECT UPDATE REVOKED: NO
PR-03 ELIGIBILITY: UNCHANGED / NOT_YET_MATERIALLY_ELIGIBLE
SECURITY GO: DENIED / UNCHANGED
```

## 12. Next safe gate

```text
Independent exact-head Backend/Data + Application Security Assurance review
of the Draft T1 migration and rollback.
```

No Supabase application, Ready, merge, frontend deployment or production mutation is authorized by this evidence file.
