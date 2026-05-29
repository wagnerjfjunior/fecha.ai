-- FECH.AI / MesaCliente
-- Supabase Security Snapshot Queries
-- Date: 2026-05-29
-- Branch: security/supabase-rls-grants-hardening
--
-- Purpose:
-- Read-only snapshot of the real Supabase security state after manual hardening.
-- Run these queries in Supabase SQL Editor and paste the outputs into:
-- docs/security/evidence/2026-05-29_supabase_security_snapshot_results.md
--
-- WARNING:
-- These queries are read-only. Do not add REVOKE/GRANT/ALTER statements here.

-- -----------------------------------------------------------------------------
-- A. Table/view grants for anon, authenticated, service_role, public
-- -----------------------------------------------------------------------------

select
  table_schema,
  table_name,
  grantee,
  string_agg(privilege_type, ', ' order by privilege_type) as privileges
from information_schema.role_table_grants
where table_schema not in ('pg_catalog', 'information_schema')
  and grantee in ('anon', 'authenticated', 'service_role', 'public')
group by table_schema, table_name, grantee
order by table_schema, table_name, grantee;

-- -----------------------------------------------------------------------------
-- B. Direct writes still open for authenticated
-- -----------------------------------------------------------------------------

select
  table_schema,
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee = 'authenticated'
  and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
order by table_name, privilege_type;

-- -----------------------------------------------------------------------------
-- C. Dangerous structural privileges for anon/authenticated
-- Expected result: No rows returned
-- -----------------------------------------------------------------------------

select
  table_schema,
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon', 'authenticated')
  and privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')
order by grantee, table_name, privilege_type;

-- -----------------------------------------------------------------------------
-- D. Grants in sensitive auth/vault schemas
-- Expected result: No rows returned for anon/authenticated/public
-- -----------------------------------------------------------------------------

select
  grantee,
  table_schema,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema in ('auth', 'vault')
  and grantee in ('anon', 'authenticated', 'public')
order by table_schema, table_name, grantee, privilege_type;

-- -----------------------------------------------------------------------------
-- E. RLS enabled/forced overview
-- -----------------------------------------------------------------------------

select
  n.nspname as schema_name,
  c.relname as table_name,
  case c.relkind
    when 'r' then 'table'
    when 'v' then 'view'
    when 'm' then 'materialized_view'
    else c.relkind::text
  end as object_type,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'v', 'm')
order by c.relkind, c.relname;

-- -----------------------------------------------------------------------------
-- F. Tables with RLS enabled but FORCE RLS disabled
-- -----------------------------------------------------------------------------

select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind = 'r'
  and n.nspname = 'public'
  and c.relrowsecurity = true
  and c.relforcerowsecurity = false
order by c.relname;

-- -----------------------------------------------------------------------------
-- G. RLS policies
-- -----------------------------------------------------------------------------

select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- -----------------------------------------------------------------------------
-- H. Views and security_invoker configuration
-- -----------------------------------------------------------------------------

select
  n.nspname as schema_name,
  c.relname as view_name,
  c.relkind,
  pg_get_userbyid(c.relowner) as owner,
  c.reloptions
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('v', 'm')
order by c.relname;

-- -----------------------------------------------------------------------------
-- I. Public functions/RPC touching password/auth/vault/service role patterns
-- Expected ideal result: No rows returned
-- -----------------------------------------------------------------------------

with funcs as materialized (
  select
    n.nspname as schema_name,
    p.proname as function_name,
    p.prosecdef as security_definer,
    pg_get_functiondef(p.oid) as function_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prokind = 'f'
)
select
  schema_name,
  function_name,
  security_definer
from funcs
where function_definition ~* '(senha|password|passwd|auth\.users|encrypted_password|service_role|decrypted_secret|vault)'
order by schema_name, function_name;

-- -----------------------------------------------------------------------------
-- J. Routine privileges for public functions/RPCs
-- -----------------------------------------------------------------------------

select
  routine_schema,
  routine_name,
  grantee,
  privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and grantee in ('anon', 'authenticated', 'public')
order by routine_name, grantee, privilege_type;

-- -----------------------------------------------------------------------------
-- K. Critical operational table columns for next phase
-- -----------------------------------------------------------------------------

select
  table_name,
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'corretores',
    'leads',
    'lotes',
    'times',
    'lista_visibilidade'
  )
order by table_name, ordinal_position;
