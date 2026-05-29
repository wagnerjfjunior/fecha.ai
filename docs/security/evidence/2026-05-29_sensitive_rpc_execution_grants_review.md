# FECH.AI / MesaCliente — Sensitive RPC Execution Grants Review

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** public SECURITY DEFINER functions matching sensitive patterns: password/auth/vault/service role/root audit.

---

## 1. Initial routine privileges returned by Supabase

```json
[
  {
    "routine_schema": "public",
    "routine_name": "get_corretores_time",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "importar_leads_batch",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "listar_empresas_root",
    "grantee": "anon",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "listar_empresas_root",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "registrar_root_audit",
    "grantee": "anon",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "registrar_root_audit",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  }
]
```

Initial interpretation:

```text
OPEN — anon had EXECUTE on root/audit SECURITY DEFINER RPCs. This was unnecessary attack surface and required hardening.
```

---

## 2. Classification

### P0/P1 — `public.redefinir_senha_corretor(uuid, text)`

Finding:

```text
The function has a password-like argument (`p_nova_senha text`) but the function body does not update auth.users and does not store the password. It only sets `corretores.must_change_password = true` and returns the target `user_id`.
```

Risk:

```text
Even if the password value is currently unused, accepting a plaintext password into a public RPC is not acceptable. The value may be sent through client payloads, network traces, API logs, function observability, browser dev tools, or incident snapshots.
```

Recommended action:

```text
Do not expose this RPC to anon/authenticated.
Move password reset/change flows to Supabase Auth / Edge Function with service role kept server-side only.
Remove the password parameter from any public SQL function API.
Validate tenant/admin/root ownership before any user reset operation.
```

Current execution grant state from the supplied snapshot:

```text
No anon/authenticated EXECUTE row was returned for redefinir_senha_corretor.
Keep it locked down. Do not grant authenticated EXECUTE.
```

### P1 — `public.listar_empresas_root()`

Finding:

```text
The function contains an internal `public.is_root()` guard, but EXECUTE was initially granted to both anon and authenticated.
```

Risk:

```text
The internal guard is good, but anon EXECUTE on a SECURITY DEFINER root-only RPC is unnecessary attack surface.
```

Recommended action:

```text
Revoke EXECUTE from anon and PUBLIC.
Keep authenticated only if the logged root panel calls the RPC through an authenticated user session.
```

### P1 — `public.registrar_root_audit(text, uuid, jsonb)`

Finding:

```text
The function contains an internal `public.is_root()` guard and writes root audit logs server-side, but EXECUTE was initially granted to anon and authenticated.
```

Risk:

```text
The function should not be executable by anon. Even with the root guard, anonymous EXECUTE on a SECURITY DEFINER audit function is not least privilege.
```

Recommended action:

```text
Revoke EXECUTE from anon and PUBLIC.
Keep authenticated only if root actions call this RPC from an authenticated root session.
```

### P1 — `public.importar_leads_batch(uuid, jsonb, text)`

Finding:

```text
The function rejects unauthenticated calls, resolves empresa_id from auth.uid(), verifies that p_lista_id belongs to the resolved tenant, inserts leads using server-resolved empresa_id, and deduplicates by session id.
```

Risk:

```text
The tenant boundary is directionally correct. Remaining review: p_sessao_id deduplication currently checks logs by sessao_id without empresa_id in the EXISTS clause; a global duplicate session id could suppress imports across tenants if session ids collide or are attacker-controlled.
```

Recommended action:

```text
Keep authenticated EXECUTE if this is a normal logged-in import path.
Ensure deduplication includes empresa_id.
Add payload size/rate controls outside SQL or in Edge/API layer.
```

### P2 — `public.get_corretores_time(uuid)`

Finding:

```text
The function requires authenticated user context, blocks users without broker/root context, and then allows only gestor/admin_local/root.
```

Risk:

```text
Authenticated EXECUTE is probably acceptable because the function has role guards. Still validate with negative test using a common broker.
```

Recommended action:

```text
Keep authenticated EXECUTE.
Run functional negative test as common broker: expected `{"error":"forbidden"}`.
```

---

## 3. Migration applied

Migration file:

```text
supabase/migrations/20260529163000_security_rpc_execute_hardening.sql
```

Purpose:

```text
- Remove anon/PUBLIC EXECUTE from sensitive SECURITY DEFINER RPCs.
- Keep authenticated EXECUTE only where needed for logged-in app flows.
- Keep redefinir_senha_corretor unavailable to client roles.
```

---

## 4. Post-migration validation

Validation query:

```sql
select
  routine_schema,
  routine_name,
  grantee,
  privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name in (
    'get_corretores_time',
    'importar_leads_batch',
    'listar_empresas_root',
    'redefinir_senha_corretor',
    'registrar_root_audit'
  )
  and grantee in ('anon', 'authenticated', 'public', 'PUBLIC')
order by routine_name, grantee, privilege_type;
```

Actual post-migration result:

```json
[
  {
    "routine_schema": "public",
    "routine_name": "get_corretores_time",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "importar_leads_batch",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "listar_empresas_root",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  },
  {
    "routine_schema": "public",
    "routine_name": "registrar_root_audit",
    "grantee": "authenticated",
    "privilege_type": "EXECUTE"
  }
]
```

Interpretation:

```text
APPROVED — anon/PUBLIC EXECUTE was removed from the sensitive RPC set.
APPROVED — redefinir_senha_corretor has no anon/authenticated/PUBLIC EXECUTE in the validated output.
APPROVED — only authenticated EXECUTE remains for the four functions required by logged-in flows.
```

---

## 5. Function configuration/search_path validation

Validation query:

```sql
select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_corretores_time',
    'importar_leads_batch',
    'listar_empresas_root',
    'redefinir_senha_corretor',
    'registrar_root_audit'
  )
order by p.proname;
```

Actual result:

```json
[
  {
    "schema_name": "public",
    "function_name": "get_corretores_time",
    "security_definer": true,
    "function_config": ["search_path=public"],
    "args": "p_time_id uuid"
  },
  {
    "schema_name": "public",
    "function_name": "importar_leads_batch",
    "security_definer": true,
    "function_config": ["search_path=public"],
    "args": "p_lista_id uuid, p_leads jsonb, p_sessao_id text"
  },
  {
    "schema_name": "public",
    "function_name": "listar_empresas_root",
    "security_definer": true,
    "function_config": ["search_path=public"],
    "args": ""
  },
  {
    "schema_name": "public",
    "function_name": "redefinir_senha_corretor",
    "security_definer": true,
    "function_config": ["search_path=public"],
    "args": "p_corretor_id uuid, p_nova_senha text"
  },
  {
    "schema_name": "public",
    "function_name": "registrar_root_audit",
    "security_definer": true,
    "function_config": ["search_path=public"],
    "args": "p_action text, p_target_empresa_id uuid, p_payload jsonb"
  }
]
```

Interpretation:

```text
APPROVED — all five sensitive SECURITY DEFINER functions have an explicit search_path instead of NULL.
CONTROLLED RISK — current search_path is `public`, and non-owner client roles do not have CREATE on schema public.
HARDENING NOTE — a stricter pattern remains `public, pg_temp`; consider applying it in a later low-risk migration after validating dependencies.
```

---

## 6. Schema CREATE privilege validation

Validation queries:

```sql
select
  n.nspname as schema_name,
  r.rolname as grantee,
  has_schema_privilege(r.rolname, n.oid, 'USAGE') as has_usage,
  has_schema_privilege(r.rolname, n.oid, 'CREATE') as has_create
from pg_namespace n
cross join pg_roles r
where n.nspname = 'public'
  and r.rolname in ('anon', 'authenticated')
order by r.rolname;
```

```sql
select
  'public' as schema_name,
  'PUBLIC' as grantee,
  has_schema_privilege('public', 'public', 'USAGE') as has_usage,
  has_schema_privilege('public', 'public', 'CREATE') as has_create;
```

Actual result:

```json
[
  {
    "schema_name": "public",
    "grantee": "anon",
    "has_usage": true,
    "has_create": false
  },
  {
    "schema_name": "public",
    "grantee": "authenticated",
    "has_usage": true,
    "has_create": false
  }
]
```

```json
[
  {
    "schema_name": "public",
    "grantee": "PUBLIC",
    "has_usage": true,
    "has_create": false
  }
]
```

Interpretation:

```text
APPROVED — anon, authenticated, and PUBLIC have USAGE but do not have CREATE on schema public.
APPROVED — search_path hijacking risk through client-created objects in public is controlled for these roles.
```

---

## 7. Functional negative tests required

Run as a common broker session:

```text
- listar_empresas_root() must fail with access denied.
- registrar_root_audit(...) must fail with access denied.
- get_corretores_time(...) must return forbidden unless the user is gestor/admin/root.
- redefinir_senha_corretor(...) must not be executable.
```

Run as root session:

```text
- listar_empresas_root() must work.
- registrar_root_audit(...) must work.
```

---

## 8. Final status for RPC EXECUTE hardening

```text
APPROVED — execution grants are hardened and validated.
APPROVED — search_path is explicit on sensitive SECURITY DEFINER functions.
APPROVED — anon/authenticated/PUBLIC do not have CREATE on schema public.
CONTROLLED RISK — search_path is currently `public`; future hardening to `public, pg_temp` is recommended but not blocking.
PENDING — functional negative tests with common broker.
PENDING — root positive tests.
```
