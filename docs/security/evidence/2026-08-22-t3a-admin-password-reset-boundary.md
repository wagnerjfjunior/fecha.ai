# FECH.AI — T3A-v1 Administrative Password Reset Multi-Tenant Authority Boundary

**Status:** `IMPLEMENTED_ON_BRANCH / NOT_APPLIED / NOT_DEPLOYED / NOT_READY / NOT_MERGED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base main:** `037232fe3da37a749ab980f783af92ff15e2baf2`  
**Branch:** `security/t3a-admin-password-reset-boundary`

## 1. Authorized scope

Implement only the server-side administrative password-reset authority boundary, with:

- actor identity derived from `auth.uid()`;
- company/tenant derived server-side;
- strict root / admin_local / gestor authority;
- cross-company denial;
- gestor limited to ordinary brokers in an active team managed by that gestor;
- target-existence leakage resistance;
- `must_change_password=true` established before Auth password mutation;
- no trust in client-supplied `empresa_id`, role, flags, team or ownership;
- migration, executable rollback and evidence;
- revocation of the direct authenticated `UPDATE(must_change_password)` grant so the current client cannot undo the server-side state;
- versioning of the live `criar-usuario` Edge Function.

Explicitly prohibited in this scope:

- frontend changes;
- production Supabase writes/migrations;
- Edge deployment;
- data normalization;
- Ready;
- merge;
- deploy;
- Security Go change.

## 2. Live baseline captured before implementation

Production project: `uobxxgzshrmbtjfdolxd`.

Live Edge observed read-only:

```text
slug: criar-usuario
version: 17
status: ACTIVE
verify_jwt: false
ezbr_sha256: 679643d42dc944cc810580807f4b1a2f5a78ff30a0ce0d67f0713817b2eeb47f
```

The live v17 source was first committed unchanged to this branch:

```text
commit: 23ba5d03e146e50cb510c065e70e2c8e5ed9794a
path: supabase/functions/criar-usuario/index.ts
message: chore(edge): version criar-usuario v17 live baseline
```

This commit is the code anchor for Edge rollback. The production Edge itself was not modified.

## 3. Read-only production catalog preflight used for implementation

Observed before writing the migration:

```text
required columns found: 17 / 17
corretores.user_id unique: true
admins.user_id unique: true
RLS + FORCE RLS:
  corretores: true / true
  admins: true / true
  times: true / true
t3_prepare_admin_password_reset(uuid) already exists: false
authenticated broad corretores UPDATE: false
authenticated UPDATE(ativo): true
authenticated UPDATE(apto_para_receber): true
authenticated UPDATE(must_change_password): true
marcar_senha_inicial_definida(): exists / authenticated EXECUTE true
marcar_senha_inicial_definida() md5: 2a7b28d4bb6342a99d075c4d3c49af4d
```

No PII was required or returned by this preflight.

## 4. Authority contract

### Root

```text
auth.uid()
→ public.admins.user_id
→ role='admin_global'
→ ativo=true
```

Root may target a `public.corretores` profile across companies. A legacy `corretores.role='admin_global'` row alone is not root authority for T3A.

### Admin local

```text
auth.uid()
→ public.corretores.user_id
→ ativo=true
→ role='admin_local'
→ is_admin_local=true
→ target.empresa_id = actor.empresa_id
→ target.role <> 'admin_global'
→ target has no public.admins identity
```

`is_gestor` is intentionally not an admin-local authority prerequisite.

### Gestor

```text
auth.uid()
→ public.corretores.user_id
→ ativo=true
→ role='gestor'
→ is_gestor=true
→ is_admin_local=false
→ target same empresa
→ target role='corretor'
→ target is_admin_local=false
→ target is_gestor=false
→ target time is active
→ target time.empresa_id = actor.empresa_id
→ target time.gestor_id = actor.id
```

Same-company membership by itself is insufficient for gestor authority.

## 5. Fail-closed and leakage behavior

The RPC accepts only a target `user_id` selector. It does not accept `empresa_id`, role, flags, team or ownership as authority inputs.

For unauthorized/missing/out-of-tenant targets, the Edge does not return the PostgreSQL distinction. It returns the same external response:

```text
HTTP 403
Usuário não encontrado ou não autorizado.
```

This prevents a non-root caller from using reset-password responses to distinguish a missing user from a real user belonging to another tenant/company.

## 6. Direct-write bypass closure

Repository-wide code search on the exact base found the literal direct write `must_change_password:false` only in `src/App.jsx`; `RootPanel` is a read/display consumer. The T3A migration therefore revokes only `authenticated UPDATE(must_change_password)` and preserves the temporary `ativo` / `apto_para_receber` column grants unchanged.

This is required in T3A: otherwise the current App.jsx can successfully call the hardened Edge and then immediately overwrite the server-authoritative `true` with a direct client PATCH to `false`.

Until T3B removes that stale frontend PATCH, it may still be attempted, but it must be denied by PostgreSQL and cannot change the protected field.

## 7. Password-state ordering

T3A deliberately uses:

```text
authorize target server-side
→ lock target profile
→ set must_change_password=true
→ return authorized user_id
→ Edge Auth updateUserById(...temporary password...)
```

If the Auth mutation fails after the RPC succeeds, the residual state is `must_change_password=true` with the previous Auth password. That is operationally recoverable and preserves the stronger security posture.

The inverse ordering is rejected because it could leave a newly assigned administrative password active while `must_change_password=false`.

The existing self-service `public.marcar_senha_inicial_definida()` remains unchanged and is still responsible for the authenticated user's later transition from `true` to `false` after defining the final password.

## 8. Versioned artifacts

```text
supabase/functions/criar-usuario/index.ts
supabase/migrations/20260822211600_t3_admin_password_reset_boundary.sql
supabase/rollback/20260822211600_t3_admin_password_reset_boundary_rollback.sql
docs/security/evidence/2026-08-22-t3a-admin-password-reset-boundary.md
```

## 9. Required application order if later authorized

This branch is not an application authorization.

If separately approved after review:

```text
1. merge exact reviewed head
2. re-resolve main
3. read-only production preflight
4. apply T3A migration (creates RPC + revokes direct UPDATE(must_change_password))
5. validate function/ACL/catalog postflight
6. deploy versioned criar-usuario Edge
7. execute controlled positive + negative + cross-tenant smoke
8. verify stale App.jsx PATCH is denied and cannot revert must_change_password
```

The migration must precede the Edge deployment because the hardened Edge depends on `public.t3_prepare_admin_password_reset(uuid)`.

## 10. Rollback order

```text
1. execute the T3A SQL rollback (drops RPC + restores the temporary direct column grant)
2. while the hardened Edge is still present, reset attempts fail closed because the RPC is absent
3. re-deploy criar-usuario v17 baseline from commit 23ba5d03...
4. verify Edge runtime matches the v17 baseline
```

Rollback does not rewrite existing `must_change_password` values.

## 11. Acceptance tests required before T3A can be considered production-validated

```text
root -> authorized target                         ALLOW
admin_local -> same company                      ALLOW
admin_local -> other company                     DENY
admin_local -> root/admin_global identity        DENY
admin_local -> missing target                    same external DENY
strict gestor -> ordinary broker own active team ALLOW
gestor -> broker other team                      DENY
gestor -> other company                          DENY
gestor -> admin_local/gestor target              DENY
ordinary corretor -> any target                  DENY
inactive actor -> any target                      DENY
missing/invalid session                          DENY
client-supplied empresa/role/flags                ignored as authority
must_change_password before Auth update           REQUIRED
direct authenticated PATCH must_change_password   DENY REQUIRED
```

T3A does not grant Security Go and does not close the later frontend T3B cutover or final direct-update grant revocation.
