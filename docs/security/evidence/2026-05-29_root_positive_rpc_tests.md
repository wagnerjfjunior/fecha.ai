# FECH.AI / MesaCliente - Root Positive RPC Tests

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: Positive functional validation for root-only SECURITY DEFINER RPCs after EXECUTE hardening.
Status: SANITIZED PUBLIC EVIDENCE

---

## Sanitization rule

This public evidence file intentionally does not expose raw email, user_id, admin id, company id, team id, broker id, audit id, token, password, secret, or customer data.

---

## 1. Root identity used

```text
root_identity = [REDACTED_ROOT_IDENTITY]
user_id = [REDACTED_ROOT_USER_ID]
role = admin_global
ativo = true
empresa_id = null
```

---

## 2. Root role validation

Actual sanitized result:

```text
uid_simulado = [REDACTED_ROOT_USER_ID]
is_root = true
is_admin_local = true
is_gestor = true
```

Interpretation:

```text
APPROVED - the redacted root identity is recognized by public.is_root() as a root/admin_global context.
```

---

## 3. Positive test - listar_empresas_root()

Actual sanitized result:

```text
total_empresas_visiveis_root = 1
```

Interpretation:

```text
APPROVED - root can execute listar_empresas_root() successfully.
```

---

## 4. Positive test - registrar_root_audit(text, uuid, jsonb)

Actual sanitized result:

```text
audit_result = [REDACTED_AUDIT_ID]
```

Interpretation:

```text
APPROVED - root can execute registrar_root_audit(...) successfully without access-denied errors.
```

Note:

```text
The test was run in a rollback transaction according to the validation plan, so it was intended not to leave permanent test audit data.
```

---

## 5. Combined root-positive test status

```text
APPROVED - root identity validated.
APPROVED - listar_empresas_root() positive test passed.
APPROVED - registrar_root_audit(...) positive test passed.
```
