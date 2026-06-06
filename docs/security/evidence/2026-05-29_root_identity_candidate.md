# FECH.AI / MesaCliente - Active Root Identity Candidate

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: Identify an active root-capable identity for positive RPC tests.
Status: SANITIZED PUBLIC EVIDENCE

---

## Sanitization rule

This public evidence file intentionally does not expose raw email, user_id, admin id, company id, team id, broker id, audit id, token, password, secret, or customer data.

---

## Supabase admins result

Sanitized result:

```text
root_candidate = [REDACTED_ROOT_IDENTITY]
role = admin_global
ativo = true
empresa_id = null
```

---

## Root validation result

A simulated authenticated session was configured using a redacted root-capable auth subject.

Actual sanitized result:

```text
uid_simulado = [REDACTED_ROOT_USER_ID]
is_root = true
is_admin_local = true
is_gestor = true
```

Interpretation:

```text
APPROVED - the redacted candidate identity is valid for root/admin_global positive RPC tests according to public.is_root().
```

---

## Remaining validation

```text
Use the same redacted root-capable context for positive tests of listar_empresas_root() and registrar_root_audit(...).
Do not commit raw identifiers or emails to GitHub.
```
