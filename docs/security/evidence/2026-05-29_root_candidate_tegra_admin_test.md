# FECH.AI / MesaCliente — Root Candidate Test: tegra@admin.fech.ai

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Identify whether `tegra@admin.fech.ai` can be used for root positive RPC tests.

---

## Candidate

```text
email: tegra@admin.fech.ai
user_id: 9ccdc029-cf46-40c1-acba-3daac989f5a5
corretor_id: 4108a65c-341f-4880-b500-b84524752efd
empresa_id: a0000000-0000-0000-0000-000000000001
ativo: true
```

---

## Actual role validation result

```json
[
  {
    "uid_simulado": "9ccdc029-cf46-40c1-acba-3daac989f5a5",
    "is_root": false,
    "is_admin_local": true,
    "is_gestor": true
  }
]
```

---

## Interpretation

```text
NOT ROOT — tegra@admin.fech.ai is admin_local and gestor, but not root.
Do not use this user for root positive tests.
```

---

## Required next action

```text
Find an active user where public.is_root() returns true, most likely by inspecting public.admins role values or the function definition for public.is_root().
Then run positive tests for listar_empresas_root() and registrar_root_audit(...).
```
