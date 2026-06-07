# FECH.AI / MesaCliente - Security Phase 1 Post-Merge Checkpoint

Date: 2026-06-07
Status: MERGED / DOCUMENTED / VERSIONED
Related PR: #65
Merge commit: 10cefb0fc49df515a47caf66823d4a512d2c43d9

---

## Summary

PR #65 was merged into `main` to document and version Supabase/RLS/grants hardening phase 1 for FECH.AI / MesaCliente.

This checkpoint records the post-merge state and the operational limits that remain after the merge.

---

## Completed in phase 1

- PR #64 was superseded and closed without merge.
- PR #65 was merged successfully.
- Repository history was sanitized with `git-filter-repo` before final merge.
- Sensitive public evidence was normalized with placeholders.
- Supabase security documentation was versioned under `docs/security/`.
- Supabase evidence files were versioned under `docs/security/evidence/`.
- Hardening migrations were versioned under `supabase/migrations/`.

---

## Scope covered by PR #65

- Removal of `anon` and `PUBLIC` grants from validated sensitive tables/views.
- PUBLIC pseudo-role diagnostics through ACL inspection with `aclexplode(...)` and `grantee = 0`.
- Table/view ACL diagnostics through `pg_class.relacl`.
- Column ACL diagnostics through `pg_attribute.attacl`.
- `security_invoker=true` on validated lot views.
- Lot views restricted to authenticated SELECT.
- Removal of structural privileges such as TRUNCATE, TRIGGER and REFERENCES from authenticated where covered.
- Removal of INSERT, UPDATE and DELETE from selected sensitive tables for authenticated where covered.
- Sensitive RPC EXECUTE hardening for:
  - `get_corretores_time(uuid)`
  - `importar_leads_batch(uuid,jsonb,text)`
  - `listar_empresas_root()`
  - `registrar_root_audit(text,uuid,jsonb)`
  - `redefinir_senha_corretor(uuid,text)`

---

## Explicit operational limits

This merge does not approve the whole platform as production-secure.

This merge does not authorize uncontrolled Supabase migration execution.

The migrations with timestamp `20260529...` were versioned after the `20260605...` migration already merged in PR #63. Any Supabase deployment must use a controlled migration-history, dry-run/backfill and validation process.

---

## Not covered yet

The following items remain OPEN for the next security phase:

- authenticated direct write surface
- `corretores`
- `leads`
- `lotes`
- `times`
- `lista_visibilidade`
- `mesa_cliente_unidade_enriquecimentos`
- `pme_*`
- broad public RPC EXECUTE surface outside the five functions covered in phase 1
- FORCE RLS candidates

---

## Recommended next PR

Next recommended PR:

`docs(security): map authenticated write-surface P1`

Recommended type:

Read-only inventory and risk mapping.

No production change.
No db push.
No parser change.
No MesaCliente engine change.
No Worker/Make/n8n change.
No frontend change.
