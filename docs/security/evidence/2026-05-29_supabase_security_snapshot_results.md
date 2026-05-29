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

Status captured during audit.

Summary of relevant validated state:

```text
public.vw_lotes_estado_oficial      authenticated SELECT
public.vw_lotes_pendentes_avaliacao authenticated SELECT
public.audit_trail                  authenticated SELECT
public.root_audit_logs              authenticated SELECT
public.mesa_cliente_desconto_politicas authenticated SELECT

No anon grants detected on the validated sensitive public tables/views after hardening.
service_role retains broad privileges, as expected for Supabase backend/service context.
```

Notes:

```text
Full raw output was collected during the audit session. Storage/realtime managed schemas showed broad Supabase-managed grants and must be reviewed separately under storage/realtime policy audit. They are intentionally outside the current public-table hardening scope.
```

---

## B. Direct writes still open for authenticated

```text
PENDING — paste result here from query B.
```

Known from prior diagnostic and still pending detailed review:

```text
P1 — public.corretores UPDATE
P1 — public.leads INSERT, UPDATE
P1 — public.lotes UPDATE
P1 — public.times UPDATE
P1 — public.lista_visibilidade DELETE, INSERT, UPDATE
P1 — public.mesa_cliente_unidade_enriquecimentos DELETE, INSERT, UPDATE
P2 — pme_* INSERT/UPDATE review
```

---

## C. Dangerous structural privileges for anon/authenticated

Expected:

```text
No rows returned.
```

Actual:

```text
Success. No rows returned.
```

Interpretation:

```text
APPROVED — anon/authenticated do not have TRUNCATE, TRIGGER, or REFERENCES on public objects covered by this diagnostic.
```

---

## D. Grants in sensitive auth/vault schemas

Expected:

```text
No rows returned.
```

Actual:

```text
Success. No rows returned.
```

Interpretation:

```text
APPROVED — anon/authenticated/public do not have direct table grants on auth/vault in the tested scope.
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

Actual:

```json
[
  {
    "schema_name": "public",
    "view_name": "vw_lotes_estado_oficial",
    "relkind": "v",
    "owner": "postgres",
    "reloptions": [
      "security_invoker=true"
    ]
  },
  {
    "schema_name": "public",
    "view_name": "vw_lotes_pendentes_avaliacao",
    "relkind": "v",
    "owner": "postgres",
    "reloptions": [
      "security_invoker=true"
    ]
  }
]
```

Interpretation:

```text
APPROVED — both validated lot views are configured with security_invoker=true.
```

---

## H.1 Lot views grants validation

Actual:

```json
[
  {
    "table_schema": "public",
    "table_name": "vw_lotes_estado_oficial",
    "grantee": "authenticated",
    "privilege_type": "SELECT"
  },
  {
    "table_schema": "public",
    "table_name": "vw_lotes_pendentes_avaliacao",
    "grantee": "authenticated",
    "privilege_type": "SELECT"
  }
]
```

Interpretation:

```text
APPROVED — validated lot views expose SELECT only to authenticated and no anon grant was returned.
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

## Migration / Hardening Block Reapplied Manually

The migration-equivalent hardening block was reapplied manually in the Supabase SQL Editor.

Result:

```text
Success. No rows returned.
```

Interpretation:

```text
The DCL/DDL hardening block executed successfully. Because it contains REVOKE, ALTER VIEW, GRANT, and COMMIT statements, no tabular result was expected.
```

Scope executed:

```text
- Revoked anon access from sensitive operational tables/views.
- Ensured lot views use security_invoker=true.
- Restricted lot views for authenticated to SELECT only.
- Removed REFERENCES, TRIGGER, and TRUNCATE from authenticated.
- Removed INSERT, UPDATE, and DELETE from audit_trail, root_audit_logs, and mesa_cliente_desconto_politicas.
```

---

## Manual Functional Test Evidence Already Collected

### Common broker tested

```text
email: laura@tegravendas.com.br
user_id: 33e16aef-74a2-4a91-86cd-d61f3963b62d
corretor_id: daae345c-d6bd-4115-a81f-804444463198
empresa_id: a0000000-0000-0000-0000-000000000001
time_id: 15d262e2-3b0f-4d58-813d-1c1f98db70e7
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
