# FECH.AI / MesaCliente — Root Positive RPC Tests

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Positive functional validation for root-only SECURITY DEFINER RPCs after EXECUTE hardening.

---

## 1. Root identity used

```text
email: [REDACTED_ROOT_IDENTITY]
user_id: [REDACTED_ROOT_USER_ID]
role: admin_global
ativo: true
empresa_id: null
```

---

## 2. Root role validation

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
APPROVED — [REDACTED_ROOT_IDENTITY] is recognized by public.is_root() as a root/admin_global identity.
```

---

## 3. Positive test — listar_empresas_root()

Actual result:

```json
[
  {
    "total_empresas_visiveis_root": 1
  }
]
```

Interpretation:

```text
APPROVED — root can execute listar_empresas_root() successfully.
The function returned visible company rows for the root context.
```

---

## 4. Positive test — registrar_root_audit(text, uuid, jsonb)

Actual result:

```json
[
  {
    "audit_result": "[REDACTED_AUDIT_ID]"
  }
]
```

Interpretation:

```text
APPROVED — root can execute registrar_root_audit(...) successfully.
The function returned an audit identifier without raising access-denied errors.
```

Note:

```text
The test was run in a rollback transaction according to the validation plan, so it was intended not to leave permanent test audit data.
```

---

## 5. Combined root-positive test status

```text
APPROVED — root identity validated.
APPROVED — listar_empresas_root() positive test passed.
APPROVED — registrar_root_audit(...) positive test passed.
```
