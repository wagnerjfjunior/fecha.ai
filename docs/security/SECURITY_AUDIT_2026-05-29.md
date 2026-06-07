# FECH.AI / MesaCliente - Security Audit

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: Supabase Auth, RLS, grants, views, audit tables, sensitive RPCs, operational write surface
Status: In progress - hardening phase 1 documented with sanitized public evidence

---

## 1. Executive summary

This audit documents the first validated Supabase security hardening block for FECH.AI / MesaCliente.

The focus of this phase was:

- Password storage posture.
- Auth/Vault direct grant review.
- Removal of anon and PUBLIC access from validated sensitive public tables/views.
- Removal of dangerous structural privileges from authenticated.
- View safety for lot-related views using security_invoker=true.
- Read-only protection for audit/root/policy tables.
- Sensitive SECURITY DEFINER RPC execution-grant review.
- Functional negative/positive checks using redacted authenticated contexts.
- Full encrypted Supabase/PostgreSQL backup checkpoint before continuing the next hardening phase.

This audit does not approve the entire platform for production security. The next phase must review the remaining direct write surface on operational tables and MesaCliente/PME flows.

---

## 2. Security principles applied

The platform is multi-tenant and multi-company. Therefore:

- The frontend must never be treated as the source of truth.
- Tenant, company, role, and ownership validation must happen in database/RPC/backend layers.
- Passwords must never be stored in public operational tables, logs, analytics, console output, custom payloads, screenshots, or external tooling.
- Critical changes must be protected by RLS, auth.uid(), tenant/company validation, role checks, and preferably secure RPCs.
- A common authenticated user must not be able to see or mutate data belonging to another company, tenant, broker, or administrative scope.
- Backup files containing Auth, Storage metadata, Vault data, leads, logs, sessions, or operational data must never be committed to GitHub.
- Public audit evidence must be sanitized: no raw emails, real user_id, corretor_id, empresa_id, time_id, audit ids, tokens, passwords, secrets, or service-role material.

---

## 3. Validated results

### 3.1 Password posture

Validated:

- No password-like operational column was found in public except corretores.must_change_password.
- public.corretores.must_change_password is boolean.
- Supabase Auth internal fields such as auth.users.encrypted_password are expected provider-managed fields.

Status:

```text
APPROVED - no evidence of plaintext password storage in public operational tables.
```

Operational rule:

```text
If a password appears in a screenshot, log, analytics event, console output, external tool, or GitHub artifact, treat it as exposed and rotate it immediately.
```

---

### 3.2 Auth/Vault direct grants

Validated result:

```text
Success. No rows returned.
```

Meaning:

```text
APPROVED - anon/authenticated/PUBLIC did not have direct table grants on sensitive auth/vault objects in the tested scope.
```

---

### 3.3 Sensitive table/view hardening

Validated objects:

- public.audit_trail
- public.lista_visibilidade
- public.mesa_cliente_desconto_politicas
- public.mesa_cliente_unidade_enriquecimentos
- public.root_audit_logs
- public.corretores
- public.vw_lotes_estado_oficial
- public.vw_lotes_pendentes_avaliacao

Validated state:

```text
APPROVED - anon grants were removed from the validated sensitive public tables/views.
APPROVED - PUBLIC has no effective SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, or TRIGGER on these validated objects.
```

PUBLIC diagnostic method:

```text
PUBLIC is a PostgreSQL pseudo-role. It was validated with aclexplode(...), using grantee = 0.
```

---

### 3.4 Structural privileges removed from anon/authenticated/PUBLIC

Validated result:

```text
Success. No rows returned.
```

Meaning:

```text
APPROVED - anon/authenticated/PUBLIC do not have TRUNCATE, TRIGGER, or REFERENCES on public objects covered by the diagnostic.
```

---

### 3.5 Lot views hardening

Validated views:

- public.vw_lotes_estado_oficial
- public.vw_lotes_pendentes_avaliacao

Confirmed:

- relkind = v
- owner = postgres
- reloptions = security_invoker=true
- authenticated has only SELECT
- no anon grant returned in the validated output
- no PUBLIC effective privilege detected by aclexplode/grantee=0

Status:

```text
APPROVED.
```

---

### 3.6 Common broker functional isolation test

A common broker authenticated context was used with all identity values redacted in public evidence.

Validated role state:

```text
is_root = false
is_admin_local = false
is_gestor = false
```

Validated vw_lotes_pendentes_avaliacao:

```text
total_linhas = 8
linhas_de_outra_empresa = 0
linhas_de_outro_corretor = 0
```

Validated vw_lotes_estado_oficial:

```text
total_linhas = 16
linhas_de_outra_empresa = 0
linhas_de_outro_corretor = 0
```

Status:

```text
APPROVED - no company or broker leakage detected in the tested lot views.
```

---

### 3.7 Audit/root/policy tables read-only for authenticated

Tables hardened:

- public.audit_trail
- public.root_audit_logs
- public.mesa_cliente_desconto_politicas

Current validated grants for authenticated:

```text
audit_trail                       SELECT
mesa_cliente_desconto_politicas   SELECT
root_audit_logs                   SELECT
```

Functional tests with a common broker context:

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

### 3.8 Sensitive SECURITY DEFINER functions

The following public functions matched sensitive patterns and remain under explicit review:

```text
public.get_corretores_time
public.importar_leads_batch
public.listar_empresas_root
public.redefinir_senha_corretor
public.registrar_root_audit
```

Validated controls for this phase:

```text
APPROVED - PUBLIC and anon EXECUTE are false for all five sensitive functions covered by this phase.
APPROVED - authenticated EXECUTE remains only for the four expected logged-in RPC flows.
APPROVED - public.redefinir_senha_corretor(uuid, text) remains unavailable to client roles.
```

Residual review:

```text
OPEN - matching a sensitive pattern is not automatically a vulnerability, but these functions still require ongoing body, role, tenant, and operation-specific review as the platform evolves.
```

---

### 3.9 Direct write surface still open for authenticated

The latest grant snapshot still shows direct write surface for authenticated on operational tables.

P1:

```text
public.corretores UPDATE
public.leads INSERT, UPDATE
public.lotes UPDATE
public.times UPDATE
public.lista_visibilidade DELETE, INSERT, UPDATE
public.mesa_cliente_unidade_enriquecimentos DELETE, INSERT, UPDATE
```

P2:

```text
public.audit_logs INSERT
public.logs INSERT
public.funil_movimentacoes INSERT
public.lista_avaliacoes INSERT, UPDATE
public.pme_cadence_steps INSERT, UPDATE
public.pme_cadences INSERT, UPDATE
public.pme_call_scripts INSERT, UPDATE
public.pme_lead_message_state INSERT, UPDATE
public.pme_message_templates INSERT, UPDATE
public.pme_message_usage INSERT
```

Status:

```text
OPEN - this is intentionally not solved by phase 1 and must be handled in the next hardening phase.
```

---

### 3.10 RLS enabled but FORCE RLS disabled

The latest snapshot confirms that some RLS-enabled tables still have rls_forced=false, including selected MesaCliente and PME tables plus root_audit_logs.

Status:

```text
OPEN - candidates for FORCE RLS after reviewing SECURITY DEFINER functions, service flows, policies, and write paths.
```

Recommendation:

```text
Do not enable FORCE RLS in bulk. Apply in small validated batches after policy/function review.
```

---

## 4. Backup checkpoint before continuing hardening

A full logical Supabase/PostgreSQL backup was created before continuing with the next security hardening phase.

Checkpoint:

```text
Backup type: full logical PostgreSQL dump
Tooling: DBeaver + pg_dump 18.4 from Postgres.app
Source database version: PostgreSQL 17.6
Original format: TAR
Original size: 14 MB
TOC entries: 1577
Validation: pg_restore -l executed successfully
Compression: gzip
Encryption: OpenSSL AES-256-CBC + PBKDF2 + 200000 iterations
Decryption test: approved
Gzip integrity test: approved
Plaintext TAR/TAR.GZ copies: removed after encryption validation
```

Security handling:

```text
Backup storage path is local and outside the repository.
The backup file contains sensitive operational data and must not be committed to GitHub.
The encryption password must be stored only in an approved password vault or equivalent secure location.
```

Status:

```text
APPROVED - encrypted backup checkpoint completed before proceeding.
```

---

## 5. Migration files

Phase 1 migration files:

```text
supabase/migrations/20260529160000_security_rls_grants_hardening.sql
supabase/migrations/20260529163000_security_rpc_execute_hardening.sql
```

Related single-RPC hardening already merged separately in PR #63:

```text
supabase/migrations/20260605150000_mesacliente_revoke_anon_public_aprovar_rejeitar_mesa.sql
```

Purpose:

- Record and reapply validated hardening actions.
- Keep Git history aligned with manual Supabase changes already applied.
- Avoid undocumented production drift.

Operational note:

```text
Because these 20260529 migrations are being versioned after a later 20260605 migration was already merged, any deployment must use a controlled migration-history strategy and dry-run/backfill validation. This PR records the files; it does not authorize an uncontrolled db push.
```

---

## 6. Required evidence files

```text
docs/security/evidence/2026-05-29_supabase_security_snapshot.sql
docs/security/evidence/2026-05-29_supabase_security_snapshot_results.md
docs/security/evidence/2026-05-29_sensitive_rpc_execution_grants_review.md
docs/security/evidence/2026-05-29_rpc_functional_tests.md
docs/security/evidence/2026-05-29_get_corretores_time_negative_test.md
docs/security/evidence/2026-05-29_rpc_client_role_denied_test.md
docs/security/evidence/2026-05-29_root_identity_candidate.md
docs/security/evidence/2026-05-29_root_positive_rpc_tests.md
```

All public evidence must remain sanitized.

---

## 7. Production approval status

Current status:

```text
PARTIALLY APPROVED - phase 1 hardening completed, documented, backed up, and sanitized for the validated scope.
```

Not yet approved:

```text
Full production security approval is pending operational write-surface review and FORCE RLS review.
```

Next focus:

```text
corretores, leads, lotes, times, lista_visibilidade, mesa_cliente_unidade_enriquecimentos, pme_*, broad RPC EXECUTE review, FORCE RLS candidates.
```
