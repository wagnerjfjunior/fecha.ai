# FECH.AI / MesaCliente — RPC Functional Test Evidence

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Functional validation for sensitive SECURITY DEFINER RPCs after EXECUTE hardening.

---

## 1. Common broker negative test — `listar_empresas_root()`

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
Failed to run sql query: ERROR: P0001: Acesso negado. Apenas root pode listar empresas.
CONTEXT: PL/pgSQL function listar_empresas_root() line 4 at RAISE
```

### Interpretation

```text
APPROVED — common broker cannot execute root-only company listing successfully.
The function internal root guard blocked the call as expected.
```

---

## 2. Common broker negative test — `registrar_root_audit(text, uuid, jsonb)`

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
Failed to run sql query: ERROR: P0001: Acesso negado. Apenas root pode registrar auditoria root.
CONTEXT: PL/pgSQL function registrar_root_audit(text,uuid,jsonb) line 8 at RAISE
```

### Interpretation

```text
APPROVED — common broker cannot register root audit entries.
The function internal root guard blocked the call as expected.
```

---

## 3. Remaining common broker negative tests

Pending:

```text
get_corretores_time(...) must return forbidden unless the user is gestor/admin/root.
redefinir_senha_corretor(...) must not be executable by authenticated client roles.
```

---

## 4. Remaining root positive tests

Pending:

```text
listar_empresas_root() must work for root.
registrar_root_audit(...) must work for root.
```
