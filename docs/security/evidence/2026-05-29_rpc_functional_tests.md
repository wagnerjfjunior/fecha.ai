# FECH.AI / MesaCliente - RPC Functional Test Evidence

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: Functional validation for sensitive SECURITY DEFINER RPCs after EXECUTE hardening.
Status: SANITIZED PUBLIC EVIDENCE

---

## Sanitization rule

This public evidence file intentionally does not expose raw email, user_id, broker id, company id, team id, audit id, token, password, secret, or customer data.

---

## 1. Common broker negative test - listar_empresas_root()

### Test context

A common broker session was simulated using an authenticated non-root user.

Expected role state:

```text
is_root = false
is_admin_local = false
is_gestor = false
```

### RPC tested

```sql
select *
from public.listar_empresas_root();
```

### Actual result

```text
ERROR: P0001: access denied - only root can list companies.
```

### Interpretation

```text
APPROVED - common broker cannot execute root-only company listing successfully.
The function internal root guard blocked the call as expected.
```

---

## 2. Common broker negative test - registrar_root_audit(text, uuid, jsonb)

### Test context

A common broker session was simulated using an authenticated non-root user.

Expected role state:

```text
is_root = false
is_admin_local = false
is_gestor = false
```

### RPC tested

```sql
select public.registrar_root_audit(
  'TESTE_NEGATIVO_CORRETOR_COMUM',
  '[REDACTED_EMPRESA_ID]'::uuid,
  '{"origem":"security_negative_test"}'::jsonb
);
```

### Actual result

```text
ERROR: P0001: access denied - only root can register root audit entries.
```

### Interpretation

```text
APPROVED - common broker cannot register root audit entries.
The function internal root guard blocked the call as expected.
```

---

## 3. get_corretores_time(...) negative test

Detailed evidence is stored in:

```text
docs/security/evidence/2026-05-29_get_corretores_time_negative_test.md
```

Summary:

```text
APPROVED - common broker receives forbidden for get_corretores_time(...).
```

---

## 4. Restricted account-control RPC client-role denied test

Detailed evidence is stored in:

```text
docs/security/evidence/2026-05-29_rpc_client_role_denied_test.md
```

Summary:

```text
APPROVED - authenticated client role cannot execute the restricted account-control RPC.
```

---

## 5. Root positive tests

Detailed evidence is stored in:

```text
docs/security/evidence/2026-05-29_root_positive_rpc_tests.md
```

Summary:

```text
APPROVED - root identity validated.
APPROVED - listar_empresas_root() positive test passed.
APPROVED - registrar_root_audit(...) positive test passed.
```
