# FECH.AI / Supabase - criar_empresa_root Execute Hardening

Date: 2026-06-09
Status: TECHNICAL HARDENING / NARROW RPC GRANT CHANGE
Related PRs:

* PR #73 - criar_empresa_root P0 hardening plan
* PR #74 - criar_empresa_root sanitized body review
  Current PR: PR #75 - criar_empresa_root execute hardening

---

## 1. Summary

This document records the technical hardening for `public.criar_empresa_root(text, text, uuid, integer)`.

The change is intentionally narrow:

* one Supabase migration;
* one RPC signature;
* no function body change;
* no RLS change;
* no policy change;
* no frontend change;
* no Edge Function change;
* no MesaCliente change;
* no data migration.

The goal is to remove broad and unauthenticated EXECUTE exposure from a P0 tenant/root creation RPC while preserving the authenticated caller path guarded by server-side `is_root` validation.

---

## 2. Files changed

Expected files:

```text
supabase/migrations/20260609173000_criar_empresa_root_revoke_anon_public_execute.sql
docs/security/evidence/2026-06-09_criar_empresa_root_execute_hardening.md
```

No other files should change.

---

## 3. Pre-change evidence

Read-only live catalog check before creating this PR returned:

| attribute             | value                                                             |
| --------------------- | ----------------------------------------------------------------- |
| function              | `criar_empresa_root`                                              |
| identity args         | `p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer` |
| sanitized body digest | `b94e9ff1a640af22768ccdc9ba34f84f`                                |
| security definer      | true                                                              |
| function config       | `search_path=public`                                              |
| volatility            | volatile                                                          |
| anon execute          | true                                                              |
| authenticated execute | true                                                              |
| service_role execute  | true                                                              |
| PUBLIC execute ACL    | true                                                              |
| execute grantees      | `anon`, `authenticated`, `postgres`, `PUBLIC`, `service_role`     |

This matches the body-review fingerprint recorded in PR #74.

---

## 4. Migration behavior

The migration performs a safety guard before changing grants:

1. locates only `public.criar_empresa_root(text, text, uuid, integer)`;
2. computes `md5(lower(pg_get_functiondef(oid)))`;
3. aborts if the digest is not `b94e9ff1a640af22768ccdc9ba34f84f`;
4. revokes EXECUTE from `PUBLIC`;
5. revokes EXECUTE from `anon`;
6. grants/preserves EXECUTE for `authenticated`;
7. grants/preserves EXECUTE for `service_role`.

The migration does not change the function body.

---

## 5. Expected post-change state

Expected catalog result after applying the migration:

| check                 |                           expected |
| --------------------- | ---------------------------------: |
| body digest           | `b94e9ff1a640af22768ccdc9ba34f84f` |
| SECURITY DEFINER      |                               true |
| `search_path=public`  |                               true |
| anon execute          |                              false |
| authenticated execute |                               true |
| service_role execute  |                               true |
| PUBLIC execute ACL    |                              false |

Expected behavior:

* unauthenticated calls cannot execute the RPC;
* `anon` cannot execute the RPC;
* authenticated callers can reach the RPC only if the body permits them;
* non-root authenticated users remain blocked by server-side `is_root` validation;
* local tenant/company admin must not be treated as root;
* valid root actor path remains functional;
* audit path remains preserved.

---

## 6. Required validation queries

Post-migration validation query:

```sql
with f as (
  select
    p.oid,
    lower(pg_get_functiondef(p.oid)) as body_lower,
    coalesce(p.proacl, acldefault('f', p.proowner)) as effective_acl,
    p.proconfig,
    p.prosecdef,
    p.provolatile
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'criar_empresa_root'
    and pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer'
), acl_expanded as (
  select
    f.oid,
    bool_or(a.privilege_type = 'EXECUTE' and a.grantee = 0) as public_execute_acl,
    array_agg(distinct case when a.grantee = 0 then 'PUBLIC' else a.grantee::regrole::text end)
      filter (where a.privilege_type = 'EXECUTE') as execute_grantees
  from f
  left join lateral aclexplode(f.effective_acl) a on true
  group by f.oid
)
select
  md5(f.body_lower) as body_md5_sanitized_fingerprint,
  f.prosecdef as security_definer,
  f.proconfig as function_config,
  f.provolatile as volatility,
  has_function_privilege('anon', f.oid, 'EXECUTE') as anon_execute,
  has_function_privilege('authenticated', f.oid, 'EXECUTE') as authenticated_execute,
  has_function_privilege('service_role', f.oid, 'EXECUTE') as service_role_execute,
  coalesce(ae.public_execute_acl, false) as public_execute_acl,
  coalesce(ae.execute_grantees, array[]::text[]) as execute_grantees
from f
left join acl_expanded ae on ae.oid = f.oid;
```

Expected output:

```text
body_md5_sanitized_fingerprint = b94e9ff1a640af22768ccdc9ba34f84f
security_definer = true
anon_execute = false
authenticated_execute = true
service_role_execute = true
public_execute_acl = false
```

---

## 7. Negative tests required before merge

Required tests for validation reviewers:

| test                                          | expected                                        |
| --------------------------------------------- | ----------------------------------------------- |
| unauthenticated client call                   | blocked before function body                    |
| anon client call                              | blocked before function body                    |
| authenticated non-root call                   | reaches function but blocked by `is_root` guard |
| authenticated local tenant/company admin call | blocked by `is_root` guard                      |
| valid root actor call                         | still succeeds                                  |
| invalid plan id                               | blocked                                         |
| duplicate slug                                | safe failure                                    |
| malformed slug                                | blocked or normalized safely                    |
| missing company name                          | blocked                                         |
| missing slug                                  | blocked                                         |
| audit path                                    | preserved                                       |
| MesaCliente                                   | unchanged                                       |
| direct DML in corretores                      | unchanged                                       |

If a test cannot be executed safely in production, it must be executed in a staging/dev branch or documented as pending before merge.

---

## 8. Rollback

Rollback SQL:

```sql
grant execute on function public.criar_empresa_root(text, text, uuid, integer) to public;
grant execute on function public.criar_empresa_root(text, text, uuid, integer) to anon;
grant execute on function public.criar_empresa_root(text, text, uuid, integer) to authenticated;
grant execute on function public.criar_empresa_root(text, text, uuid, integer) to service_role;
```

Rollback validation:

* re-run the validation query;
* confirm `anon_execute=true` if rollback intentionally restores previous exposure;
* confirm `PUBLIC execute ACL=true` if rollback intentionally restores previous exposure;
* confirm valid root actor path still works;
* confirm audit path still works.

---

## 9. Non-goals

This PR must not include:

* MesaCliente changes;
* `salvar_mesa_cliente_enriquecimento` changes;
* direct DML replacement for `corretores`;
* broad grants cleanup;
* broad RLS changes;
* broad FORCE RLS changes;
* unrelated root/billing functions;
* frontend changes;
* Edge Function changes;
* parser changes;
* financial engine changes;
* Worker/Make/n8n changes;
* Vercel changes.

---

## 10. Final conclusion

This PR is the first narrow technical hardening step after the documented body review for `criar_empresa_root`.

It removes unauthenticated and broad PUBLIC EXECUTE exposure while preserving the authenticated path protected by the server-side root-only body guard.

It should be validated as a narrow grant-hardening PR, not as a broad platform security completion claim.
