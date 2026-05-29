# FECH.AI / MesaCliente — Active Root Identity Candidate

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Identify an active root-capable identity for positive RPC tests.

---

## Supabase admins result

```json
[
  {
    "id": "c773c6c4-f9dd-47a3-8f7c-78e68b0ebd2f",
    "user_id": "82373656-1f76-4411-a78a-3588531163e7",
    "email": "root@fech.ai",
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
Candidate root identity found: root@fech.ai.
Role value is admin_global, not literal root; public.is_root() must be validated with the candidate user_id before running positive root RPC tests.
```

---

## Next validation

```text
Simulate authenticated JWT subject 82373656-1f76-4411-a78a-3588531163e7 and confirm public.is_root() returns true.
If true, run positive tests for listar_empresas_root() and registrar_root_audit(...).
```
