# FECH.AI / MesaCliente — Security Audit

**Date:** 2026-05-29  
**Branch:** `security/supabase-rls-grants-hardening`  
**Scope:** Supabase Auth, RLS, grants, views, audit tables, operational write surface  
**Status:** In progress — hardening phase 1 documented

---

## 1. Executive Summary

This audit documents the Supabase security hardening performed for FECH.AI / MesaCliente, focused on multi-tenant isolation, anonymous access removal, authenticated role privilege reduction, audit table protection, and view safety.

The first validated block addressed:

- Password storage posture.
- Auth/Vault public grants.
- `anon` grants on sensitive public tables/views.
- Dangerous structural privileges for `authenticated`.
- View access model for lot-related views.
- Read-only protection for audit/root/policy tables.
- Functional tests using a real common broker user.

This document intentionally does **not** claim that the entire platform is production-approved yet. The next critical phase is to review direct write permissions on operational tables such as `corretores`, `leads`, `lotes`, `times`, `lista_visibilidade`, `pme_*`, and selected MesaCliente tables.

---

## 2. Security Principles Applied

The platform is multi-tenant and multi-company. Therefore:

- The frontend must never be treated as the source of truth.
- Tenant, company, role, and ownership validation must happen in database/RPC/backend layers.
- Passwords must never be stored in public operational tables, logs, analytics, console output, or custom payloads.
- Critical changes must be protected by RLS, `auth.uid()`, tenant/company validation, role checks, and preferably secure RPCs.
- A common authenticated user must not be able to see or mutate data belonging to another company, tenant, broker, or administrative scope.

---

## 3. Validated Results

### 3.1 Password posture

Validated:

- No password-like operational column was found in `public` except `corretores.must_change_password`.
- `public.corretores.must_change_password` is `boolean`.
- Supabase Auth internal fields such as `auth.users.encrypted_password` are expected provider-managed fields.

Status:

```text
APPROVED — no evidence of plaintext password storage in public operational tables.
```

Important operational rule:

```text
If a password appears in a screenshot, log, analytics event, console output, or external tool, treat it as exposed and rotate it immediately.
```

---

### 3.2 Auth/Vault direct grants

Validated query result:

```text
No rows returned.
```

Meaning:

- `anon`, `authenticated`, and `public` did not have direct table grants on sensitive `auth`/`vault` tables in the tested query scope.

Status:

```text
APPROVED.
```

---

### 3.3 Anonymous access hardening

Anonymous access was removed from sensitive operational tables/views, including:

- `public.audit_trail`
- `public.lista_visibilidade`
- `public.mesa_cliente_desconto_politicas`
- `public.mesa_cliente_unidade_enriquecimentos`
- `public.root_audit_logs`
- `public.corretores`
- `public.vw_lotes_estado_oficial`
- `public.vw_lotes_pendentes_avaliacao`

Validated:

```text
anon no longer has grants on the tested sensitive tables/views.
```

Status:

```text
APPROVED.
```

---

### 3.4 Structural privileges removed from authenticated

Removed from `authenticated`:

- `TRUNCATE`
- `TRIGGER`
- `REFERENCES`

Validated result:

```text
Success. No rows returned.
```

Status:

```text
APPROVED.
```

---

### 3.5 Lot views hardening

Validated views:

- `public.vw_lotes_estado_oficial`
- `public.vw_lotes_pendentes_avaliacao`

Confirmed:

- `relkind = 'v'`
- `owner = postgres`
- `reloptions = {security_invoker=true}`
- `anon` removed
- `authenticated` has only `SELECT`

Status:

```text
APPROVED.
```

---

### 3.6 Common broker functional isolation test

Test user:

```text
email: laura@tegravendas.com.br
user_id: 33e16aef-74a2-4a91-86cd-d61f3963b62d
corretor_id: daae345c-d6bd-4115-a81f-804444463198
empresa_id: a0000000-0000-0000-0000-000000000001
time_id: 15d262e2-3b0f-4d58-813d-1c1f98db70e7
```

Validated role state:

```text
is_root = false
is_admin_local = false
is_gestor = false
```

Validated `vw_lotes_pendentes_avaliacao`:

```text
total_linhas = 8
linhas_de_outra_empresa = 0
linhas_de_outro_corretor = 0
```

Validated `vw_lotes_estado_oficial`:

```text
total_linhas = 16
linhas_de_outra_empresa = 0
linhas_de_outro_corretor = 0
```

Status:

```text
APPROVED — no company or broker leakage detected in tested lot views.
```

---

### 3.7 Audit/root/policy tables read-only for authenticated

Tables hardened:

- `public.audit_trail`
- `public.root_audit_logs`
- `public.mesa_cliente_desconto_politicas`

Current grants for `authenticated`:

```text
audit_trail                     SELECT
mesa_cliente_desconto_politicas SELECT
root_audit_logs                 SELECT
```

Functional tests with common broker user:

```text
root_audit_logs visible rows = 0
audit_trail visible rows = 0
mesa_cliente_desconto_politicas linhas_de_outra_empresa = 0
```

Status:

```text
APPROVED.
```

---

## 4. Migration Created

Migration file:

```text
supabase/migrations/20260529160000_security_rls_grants_hardening.sql
```

Purpose:

- Record and reapply the validated hardening actions.
- Keep Git history aligned with manual Supabase changes already applied.
- Avoid undocumented production drift.

---

## 5. Current Known Pending Items

The following are intentionally not solved by the current migration and must be handled in the next hardening phase:

```text
P1 — Review UPDATE on public.corretores.
P1 — Review INSERT/UPDATE on public.leads.
P1 — Review UPDATE on public.lotes.
P1 — Review UPDATE on public.times.
P1 — Review DELETE/INSERT/UPDATE on public.lista_visibilidade.
P1 — Review DELETE/INSERT/UPDATE on public.mesa_cliente_unidade_enriquecimentos.
P2 — Review INSERT/UPDATE on pme_cadence_steps.
P2 — Review INSERT/UPDATE on pme_cadences.
P2 — Review INSERT/UPDATE on pme_call_scripts.
P2 — Review INSERT/UPDATE on pme_lead_message_state.
P2 — Review INSERT/UPDATE on pme_message_templates.
P2 — Review INSERT on pme_message_usage.
P2 — Evaluate FORCE RLS on tables where rls_enabled = true and rls_forced = false.
P2 — Review routine privileges for anon/authenticated/public.
```

---

## 6. Required Read-Only Snapshot Queries

The current repository also contains:

```text
docs/security/evidence/2026-05-29_supabase_security_snapshot.sql
```

This file contains read-only SQL queries to capture the current Supabase security state.

The expected evidence output should be stored in:

```text
docs/security/evidence/2026-05-29_supabase_security_snapshot_results.md
```

---

## 7. Production Approval Status

Current status:

```text
PARTIALLY APPROVED — phase 1 hardening completed and documented.
```

Not yet approved:

```text
Full production security approval is pending operational write-surface review.
```

Next focus:

```text
corretores, leads, lotes, times, lista_visibilidade, pme_*, mesa_cliente_unidade_enriquecimentos.
```
