# FECH.AI / MesaCliente — Supabase Security Snapshot Results

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Source query file:** `docs/security/evidence/2026-05-29_supabase_security_snapshot.sql`  
**Status:** Sanitized public evidence

---

## Instructions

This file stores sanitized structural/security evidence only.

Do not paste passwords, tokens, service role keys, secrets, raw credentials, real emails, real user ids, real broker ids, real company ids, real team ids, audit ids, or customer data into this file.

---

## A. Table/view grants for anon, authenticated, service_role, public

Summary of relevant validated state:

```text
public.vw_lotes_estado_oficial             authenticated SELECT
public.vw_lotes_pendentes_avaliacao        authenticated SELECT
public.audit_trail                         authenticated SELECT
public.root_audit_logs                     authenticated SELECT
public.mesa_cliente_desconto_politicas     authenticated SELECT
```

Interpretation:

```text
APPROVED — no anon grants detected on the validated sensitive public tables/views after hardening.
SERVICE_ROLE NOTE — service_role retains broad Supabase backend/service privileges and is outside client-role hardening scope.
```

---

## B. Direct writes still open for authenticated

Latest sanitized result summary:

```text
public.audit_logs                          INSERT
public.corretores                          UPDATE
public.funil_movimentacoes                 INSERT
public.leads                               INSERT, UPDATE
public.lista_avaliacoes                    INSERT, UPDATE
public.lista_visibilidade                  DELETE, INSERT, UPDATE
public.logs                                INSERT
public.lotes                               UPDATE
public.mesa_cliente_unidade_enriquecimentos DELETE, INSERT, UPDATE
public.pme_cadence_steps                   INSERT, UPDATE
public.pme_cadences                        INSERT, UPDATE
public.pme_call_scripts                    INSERT, UPDATE
public.pme_lead_message_state              INSERT, UPDATE
public.pme_message_templates               INSERT, UPDATE
public.pme_message_usage                   INSERT
public.times                               UPDATE
```

Expected read grants remain present for normal authenticated application reads, including selected operational, MesaCliente, PME, and lot-view objects.

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
Views show rls_enabled=false and rls_forced=false, which is expected for views; view safety must be handled via grants and security_invoker.
```

Objects still RLS-enabled but not FORCE RLS-enabled are listed in section F.

---

## F. Tables with RLS enabled but FORCE RLS disabled

Actual sanitized list:

```text
public.mesa_cliente_desconto_politicas
public.mesa_cliente_fluxo_operacoes
public.mesa_cliente_fluxo_parcelas
public.mesa_cliente_politica_premio_faixas
public.mesa_cliente_politicas_financeiras
public.mesa_cliente_unidade_enriquecimentos
public.mesa_fluxo_pagamentos_canonico
public.pme_cadence_steps
public.pme_cadences
public.pme_call_scripts
public.pme_lead_message_state
public.pme_message_templates
public.pme_message_usage
public.root_audit_logs
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

Actual:

```text
Success. No rows returned.
```

Interpretation:

```text
ATTENTION — the policy query returned no rows in the supplied run. This must be treated as a signal to re-check query scope, permissions, or whether policies are represented differently than expected.
Do not infer that RLS is safe only from this result. RLS enabled/forced and functional isolation tests remain the controlling evidence for this phase.
```

---

## H. Views and security_invoker configuration

Actual sanitized result:

```text
public.vw_lotes_estado_oficial       relkind=v owner=postgres reloptions=[security_invoker=true]
public.vw_lotes_pendentes_avaliacao  relkind=v owner=postgres reloptions=[security_invoker=true]
```

Interpretation:

```text
APPROVED — both validated lot views are configured with security_invoker=true.
```

---

## H.1 Lot views grants validation

Actual sanitized result:

```text
public.vw_lotes_estado_oficial       authenticated SELECT
public.vw_lotes_pendentes_avaliacao  authenticated SELECT
```

Interpretation:

```text
APPROVED — validated lot views expose SELECT only to authenticated and no anon grant was returned.
```

---

## I. Public functions/RPC touching password/auth/vault/service-role patterns

Actual:

```text
public.get_corretores_time           SECURITY DEFINER = true
public.importar_leads_batch          SECURITY DEFINER = true
public.listar_empresas_root          SECURITY DEFINER = true
public.redefinir_senha_corretor      SECURITY DEFINER = true
public.registrar_root_audit          SECURITY DEFINER = true
```

Interpretation:

```text
OPEN — five SECURITY DEFINER functions matched sensitive patterns. This is not automatically a vulnerability, but it requires source review, execution grants review, fixed search_path validation, and role/tenant guard validation.
```

Priority classification:

```text
P0/P1 — public.redefinir_senha_corretor: must not expose or process plaintext password through client SQL RPC flow.
P1 — public.importar_leads_batch: must validate tenant/company ownership, import boundaries, deduplication semantics, and no service-role exposure.
P1 — public.listar_empresas_root: must validate root-only access.
P1 — public.registrar_root_audit: must validate audit integrity and root-only semantics.
P2 — public.get_corretores_time: validate tenant/team boundary and role guard.
```

---

## J. Routine privileges for public functions/RPCs

Latest validated sensitive-RPC execution-grant summary is documented in:

```text
docs/security/evidence/2026-05-29_sensitive_rpc_execution_grants_review.md
```

Sanitized phase-1 conclusion:

```text
APPROVED — anon/PUBLIC EXECUTE removed from the sensitive RPC set covered by the migration.
APPROVED — authenticated EXECUTE remains only where required for logged-in flows and protected by function-level guards.
APPROVED — password-like RPC remains unavailable to client roles in the validated output.
```

---

## K. Critical operational table columns for next phase

```text
PENDING — column-level review remains required for corretores, leads, lotes, times, lista_visibilidade, mesa_cliente_unidade_enriquecimentos, and PME tables.
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

### Common broker context

```text
Identity values redacted.
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

Interpretation:

```text
APPROVED — no company/broker leakage detected in the validated view and audit/policy visibility checks.
```
