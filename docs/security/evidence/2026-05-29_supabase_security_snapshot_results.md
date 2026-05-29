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

Actual:

```json
[
  { "table_schema": "public", "table_name": "audit_logs", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "corretores", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "funil_movimentacoes", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "leads", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "leads", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "lista_avaliacoes", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "lista_avaliacoes", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "lista_visibilidade", "grantee": "authenticated", "privilege_type": "DELETE" },
  { "table_schema": "public", "table_name": "lista_visibilidade", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "lista_visibilidade", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "logs", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "lotes", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "mesa_cliente_unidade_enriquecimentos", "grantee": "authenticated", "privilege_type": "DELETE" },
  { "table_schema": "public", "table_name": "mesa_cliente_unidade_enriquecimentos", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "mesa_cliente_unidade_enriquecimentos", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "pme_cadence_steps", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "pme_cadence_steps", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "pme_cadences", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "pme_cadences", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "pme_call_scripts", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "pme_call_scripts", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "pme_lead_message_state", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "pme_lead_message_state", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "pme_message_templates", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "pme_message_templates", "grantee": "authenticated", "privilege_type": "UPDATE" },
  { "table_schema": "public", "table_name": "pme_message_usage", "grantee": "authenticated", "privilege_type": "INSERT" },
  { "table_schema": "public", "table_name": "times", "grantee": "authenticated", "privilege_type": "UPDATE" }
]
```

Interpretation:

```text
OPEN — direct write surface still exists and must be reviewed in the next hardening phase.
```

Priority classification:

```text
P1 — public.corretores UPDATE
P1 — public.leads INSERT, UPDATE
P1 — public.lotes UPDATE
P1 — public.times UPDATE
P1 — public.lista_visibilidade DELETE, INSERT, UPDATE
P1 — public.mesa_cliente_unidade_enriquecimentos DELETE, INSERT, UPDATE
P2 — public.audit_logs INSERT
P2 — public.logs INSERT
P2 — public.funil_movimentacoes INSERT
P2 — public.lista_avaliacoes INSERT, UPDATE
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

Summary:

```text
Most core operational public tables are RLS enabled and FORCE RLS enabled.
The uploaded full overview confirms FORCE RLS true for critical operational tables such as admins, audit_logs, audit_trail, corretores, empresas, leads, lista_avaliacoes, lista_visibilidade, listas, logs, lotes, times, and multiple MesaCliente operational tables.
Views show rls_enabled=false and rls_forced=false, which is expected for views; view safety must be handled via grants and security_invoker.
```

Objects still RLS-enabled but not FORCE RLS-enabled are listed in section F.

---

## F. Tables with RLS enabled but FORCE RLS disabled

Actual:

```json
[
  { "schema_name": "public", "table_name": "mesa_cliente_desconto_politicas", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "mesa_cliente_fluxo_operacoes", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "mesa_cliente_fluxo_parcelas", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "mesa_cliente_politica_premio_faixas", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "mesa_cliente_politicas_financeiras", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "mesa_cliente_unidade_enriquecimentos", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "mesa_fluxo_pagamentos_canonico", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "pme_cadence_steps", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "pme_cadences", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "pme_call_scripts", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "pme_lead_message_state", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "pme_message_templates", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "pme_message_usage", "rls_enabled": true, "rls_forced": false },
  { "schema_name": "public", "table_name": "root_audit_logs", "rls_enabled": true, "rls_forced": false }
]
```

Interpretation:

```text
OPEN — these tables remain candidates for FORCE RLS after reviewing SECURITY DEFINER functions, service flows, and MesaCliente/PME write paths.
```

Recommended next action:

```text
Do not enable FORCE RLS in bulk yet.
Review policies and functions first, then apply FORCE RLS in small validated batches.
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
