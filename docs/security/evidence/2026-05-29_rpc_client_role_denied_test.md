# FECH.AI / MesaCliente - Client Role Denied RPC Test

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: Functional validation of a restricted sensitive RPC after EXECUTE hardening.
Status: SANITIZED PUBLIC EVIDENCE

---

## Sanitization rule

This public evidence file intentionally does not expose raw email, user_id, broker id, company id, team id, audit id, token, password, secret, or customer data.

---

## Test context

A common broker session was simulated using an authenticated client role.

The tested RPC is intentionally unavailable to client roles because it belongs to a restricted account-control flow.

---

## Actual result

```text
Error: Failed to run sql query: ERROR: 42501: permission denied for restricted account-control function
```

---

## Interpretation

```text
APPROVED - authenticated client role cannot execute the restricted account-control RPC.
APPROVED - the sensitive RPC remains blocked from client roles after hardening.
```

---

## Remaining recommendation

```text
Keep account-control flows in Supabase Auth or server-side Edge Function with privileged credentials kept server-side only.
Avoid client-exposed SQL RPCs for account-control operations.
```
