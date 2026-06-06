-- FECH.AI / MesaCliente
-- Security hardening for Supabase grants/RLS
-- Migration: 20260529160000_security_rls_grants_hardening.sql
-- Date: 2026-05-29
-- Branch: security/supabase-rls-grants-hardening
--
-- Scope:
-- 1. Remove anonymous and PUBLIC access from sensitive operational tables/views.
-- 2. Ensure lot views use security_invoker.
-- 3. Restrict lot views for authenticated users to SELECT only.
-- 4. Remove structural privileges from authenticated users.
-- 5. Make audit/root/policy tables read-only for authenticated users.
--
-- Notes:
-- - This migration mirrors hardening already applied manually and validated during the security audit.
-- - It intentionally does NOT modify parser, financial engine, Worker/Make/n8n flows, frontend, or business rules.
-- - It intentionally does NOT revoke INSERT/UPDATE from core operational tables such as corretores, leads, lotes, times, pme_* yet.
-- - Next phase must review column-level update permissions and/or replace critical direct writes with secure RPCs.
-- - PUBLIC is the PostgreSQL pseudo-role. Revoking from PUBLIC is intentional and distinct from revoking from anon.

begin;

-- -----------------------------------------------------------------------------
-- 1) Remove anonymous and PUBLIC access from sensitive operational tables/views
-- -----------------------------------------------------------------------------

revoke all privileges on table public.audit_trail from anon;
revoke all privileges on table public.audit_trail from public;

revoke all privileges on table public.lista_visibilidade from anon;
revoke all privileges on table public.lista_visibilidade from public;

revoke all privileges on table public.mesa_cliente_desconto_politicas from anon;
revoke all privileges on table public.mesa_cliente_desconto_politicas from public;

revoke all privileges on table public.mesa_cliente_unidade_enriquecimentos from anon;
revoke all privileges on table public.mesa_cliente_unidade_enriquecimentos from public;

revoke all privileges on table public.root_audit_logs from anon;
revoke all privileges on table public.root_audit_logs from public;

revoke all privileges on table public.corretores from anon;
revoke all privileges on table public.corretores from public;

revoke all privileges on table public.vw_lotes_estado_oficial from anon;
revoke all privileges on table public.vw_lotes_estado_oficial from public;

revoke all privileges on table public.vw_lotes_pendentes_avaliacao from anon;
revoke all privileges on table public.vw_lotes_pendentes_avaliacao from public;

-- -----------------------------------------------------------------------------
-- 2) Ensure lot views are invoker-safe
-- -----------------------------------------------------------------------------

alter view public.vw_lotes_estado_oficial set (security_invoker = true);
alter view public.vw_lotes_pendentes_avaliacao set (security_invoker = true);

-- -----------------------------------------------------------------------------
-- 3) Keep authenticated read-only access to lot views
-- -----------------------------------------------------------------------------

revoke insert, update, delete, truncate, references, trigger
on table public.vw_lotes_estado_oficial
from authenticated;

revoke insert, update, delete, truncate, references, trigger
on table public.vw_lotes_pendentes_avaliacao
from authenticated;

grant select on table public.vw_lotes_estado_oficial to authenticated;
grant select on table public.vw_lotes_pendentes_avaliacao to authenticated;

-- -----------------------------------------------------------------------------
-- 4) Remove structural privileges from authenticated users
-- -----------------------------------------------------------------------------

revoke references, trigger, truncate
on table public.audit_trail
from authenticated;

revoke references, trigger, truncate
on table public.lista_visibilidade
from authenticated;

revoke references, trigger, truncate
on table public.mesa_cliente_desconto_politicas
from authenticated;

revoke references, trigger, truncate
on table public.mesa_cliente_unidade_enriquecimentos
from authenticated;

revoke references, trigger, truncate
on table public.root_audit_logs
from authenticated;

-- -----------------------------------------------------------------------------
-- 5) Make audit/root/policy tables read-only for authenticated users.
-- RLS still decides who can actually SELECT.
-- -----------------------------------------------------------------------------

revoke delete, insert, update
on table public.audit_trail
from authenticated;

revoke delete, insert, update
on table public.root_audit_logs
from authenticated;

revoke delete, insert, update
on table public.mesa_cliente_desconto_politicas
from authenticated;

commit;
