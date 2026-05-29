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

## Initial interpretation

```text
Candidate root identity found: [REDACTED_ROOT_IDENTITY].
Role value is admin_global, not literal root; public.is_root() must be validated with the candidate user_id before running positive root RPC tests.
```

---

## Root validation result

A simulated authenticated session was configured with:

```text
request.jwt.claim.sub = [REDACTED_ROOT_USER_ID]
```

Actual result:

```json
[
  {
    "uid_simulado": "[REDACTED_ROOT_USER_ID]",
    "is_root": true,
    "is_admin_local": true,
    "is_gestor": true
  }
]
```

Interpretation:

```text
APPROVED — [REDACTED_ROOT_IDENTITY] is a valid root/admin_global identity according to public.is_root().
It can be used for positive root RPC tests.
```

---

## Remaining validation

```text
Run positive tests for listar_empresas_root() and registrar_root_audit(...).
Capture total_empresas_visiveis_root and confirm registrar_root_audit executes without error inside a rollback transaction.
```
