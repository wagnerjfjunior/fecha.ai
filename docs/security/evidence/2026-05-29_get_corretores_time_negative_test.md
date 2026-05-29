# FECH.AI / MesaCliente — get_corretores_time Negative Test

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Functional validation of `public.get_corretores_time(uuid)` with a common broker session.

---

## Test context

A common broker session was simulated using an authenticated user that is not root, not local admin, and not gestor.

Expected role state:

```text
is_root = false
is_admin_local = false
is_gestor = false
```

---

## RPC tested

```sql
select *
from public.get_corretores_time(
  '[REDACTED_TIME_ID]'::uuid
);
```

---

## Actual result

```json
[
  {
    "get_corretores_time": {
      "error": "forbidden"
    }
  }
]
```

---

## Interpretation

```text
APPROVED — common broker cannot list team brokers through get_corretores_time.
The function returned forbidden as expected for non-gestor/non-admin/non-root.
```
