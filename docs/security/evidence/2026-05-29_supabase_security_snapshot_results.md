# FECH.AI / MesaCliente — Supabase Security Snapshot Results

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Source query file:** `docs/security/evidence/2026-05-29_supabase_security_snapshot.sql`

---

## Instructions

Paste the output of each read-only snapshot query below.

Do not paste passwords, tokens, service role keys, secrets, or raw credentials into this file.

If any query returns sensitive values, redact the values and keep only the structural/security-relevant fields.

---

## A. Table/view grants for anon, authenticated, service_role, public

```text
PENDING — paste result here.
```

---

## B. Direct writes still open for authenticated

```text
PENDING — paste result here.
```

---

## C. Dangerous structural privileges for anon/authenticated

Expected:

```text
No rows returned.
```

Actual:

```text
PENDING — paste result here.
```

---

## D. Grants in sensitive auth/vault schemas

Expected:

```text
No rows returned.
```

Actual:

```text
PENDING — paste result here.
```

---

## E. RLS enabled/forced overview

```text
PENDING — paste result here.
```

---

## F. Tables with RLS enabled but FORCE RLS disabled

```text
PENDING — paste result here.
```

---

## G. RLS policies

```text
PENDING — paste result here.
```

---

## H. Views and security_invoker configuration

```text
PENDING — paste result here.
```

---

## I. Public functions/RPC touching password/auth/vault/service role patterns

Expected ideal:

```text
No rows returned.
```

Actual:

```text
PENDING — paste result here.
```

---

## J. Routine privileges for public functions/RPCs

```text
PENDING — paste result here.
```

---

## K. Critical operational table columns for next phase

```text
PENDING — paste result here.
```

---

## Manual Functional Test Evidence Already Collected

### Common broker tested

```text
email: [REDACTED_BROKER_IDENTITY]
user_id: [REDACTED_COMMON_BROKER_USER_ID]
corretor_id: [REDACTED_COMMON_BROKER_ID]
empresa_id: [REDACTED_EMPRESA_ID]
time_id: [REDACTED_TIME_ID]
```

### Role validation

```text
is_root = false
is_admin_local = false
is_gestor = false
```

### vw_lotes_pendentes_avaliacao

```text
total_linhas = 8
linhas_de_outra_empresa = 0
linhas_de_outro_corretor = 0
```

### vw_lotes_estado_oficial

```text
total_linhas = 16
linhas_de_outra_empresa = 0
linhas_de_outro_corretor = 0
```

### Audit/root/policy visibility for common broker

```text
root_audit_logs visible rows = 0
audit_trail visible rows = 0
mesa_cliente_desconto_politicas linhas_de_outra_empresa = 0
```
