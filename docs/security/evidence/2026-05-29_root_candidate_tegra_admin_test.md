# FECH.AI / MesaCliente - Root Candidate Test

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: Identify whether a redacted admin-local candidate can be used for root positive RPC tests.
Status: SANITIZED PUBLIC EVIDENCE

---

## Sanitization rule

This public evidence file intentionally does not expose raw email, user_id, broker id, company id, team id, token, password, secret, or customer data.

---

## Candidate

```text
candidate_identity = [REDACTED_ADMIN_LOCAL_IDENTITY]
user_id = [REDACTED_ADMIN_LOCAL_USER_ID]
corretor_id = [REDACTED_CORRETOR_ID]
empresa_id = [REDACTED_EMPRESA_ID]
ativo = true
```

---

## Actual role validation result

```text
uid_simulado = [REDACTED_ADMIN_LOCAL_USER_ID]
is_root = false
is_admin_local = true
is_gestor = true
```

---

## Interpretation

```text
NOT ROOT - the redacted candidate is admin_local and gestor, but not root.
Do not use this user for root positive tests.
```

---

## Required next action

```text
Use an active user where public.is_root() returns true for positive root-only RPC tests.
Keep raw identity values outside GitHub evidence.
```
