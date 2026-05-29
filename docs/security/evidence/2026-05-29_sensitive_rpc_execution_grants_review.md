# FECH.AI / MesaCliente — Sensitive RPC Execution Grants Review

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** public SECURITY DEFINER functions matching sensitive patterns: password/auth/vault/service role/root audit.

---

## 1. Routine privileges returned by Supabase

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
The function contains an internal `public.is_root()` guard, but EXECUTE is currently granted to both anon and authenticated.
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
The function contains an internal `public.is_root()` guard and writes root audit logs server-side, but EXECUTE is currently granted to anon and authenticated.
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

## 3. Recommended migration candidate

Migration file created:

```text
supabase/migrations/20260529163000_security_rpc_execute_hardening.sql
```

Expected post-migration validation:

```text
listar_empresas_root       => authenticated EXECUTE only
registrar_root_audit       => authenticated EXECUTE only
get_corretores_time        => authenticated EXECUTE only
importar_leads_batch       => authenticated EXECUTE only
redefinir_senha_corretor   => no anon/authenticated/PUBLIC EXECUTE
```

---

## 4. Validation queries after applying migration

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

---

## 5. Functional negative tests required

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
