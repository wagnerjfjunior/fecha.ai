# FECH.AI / MesaCliente — Active Root Identity Candidate

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Identify an active root-capable identity for positive RPC tests.

---

## Supabase admins result

```json
[
  {
    "id": "[REDACTED_ADMIN_ID]",
    "user_id": "[REDACTED_ROOT_USER_ID]",
    "email": "[REDACTED_ROOT_IDENTITY]",
    "nome": "root",
    "empresa_id": null,
    "role": "admin_global",
    "ativo": true
  }
]
```

---

## Interpretation

```text
Candidate root identity found: [REDACTED_ROOT_IDENTITY].
Role value is admin_global, not literal root; public.is_root() must be validated with the candidate user_id before running positive root RPC tests.
```

---

## Next validation

```text
Simulate authenticated JWT subject [REDACTED_ROOT_USER_ID] and confirm public.is_root() returns true.
If true, run positive tests for listar_empresas_root() and registrar_root_audit(...).
```
