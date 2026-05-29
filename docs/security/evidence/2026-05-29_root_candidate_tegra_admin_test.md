# FECH.AI / MesaCliente — Root Candidate Test: [REDACTED_ADMIN_LOCAL_IDENTITY]

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Identify whether `[REDACTED_ADMIN_LOCAL_IDENTITY]` can be used for root positive RPC tests.

---

## Candidate

```text
email: [REDACTED_ADMIN_LOCAL_IDENTITY]
user_id: [REDACTED_ADMIN_LOCAL_USER_ID]
corretor_id: [REDACTED_CORRETOR_ID]
empresa_id: [REDACTED_EMPRESA_ID]
ativo: true
```

---

## Actual role validation result

```json
[
  {
    "uid_simulado": "[REDACTED_ADMIN_LOCAL_USER_ID]",
    "is_root": false,
    "is_admin_local": true,
    "is_gestor": true
  }
]
```

---

## Interpretation

```text
NOT ROOT — [REDACTED_ADMIN_LOCAL_IDENTITY] is admin_local and gestor, but not root.
Do not use this user for root positive tests.
```

---

## Required next action

```text
Find an active user where public.is_root() returns true, most likely by inspecting public.admins role values or the function definition for public.is_root().
Then run positive tests for listar_empresas_root() and registrar_root_audit(...).
```
