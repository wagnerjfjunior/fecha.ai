-- FECH.AI / MesaCliente
-- Supabase Security Snapshot Queries
-- Date: 2026-05-29
-- Branch: security/supabase-rls-grants-hardening
--
-- Purpose:
-- Read-only snapshot of the real Supabase security state after manual hardening.
-- Run these queries in Supabase SQL Editor and paste sanitized outputs into:
-- docs/security/evidence/2026-05-29_supabase_security_snapshot_results.md
--
-- WARNING:
-- These queries are read-only. Do not add REVOKE/GRANT/ALTER statements here.
-- Do not paste raw passwords, tokens, service role keys, secrets, real emails,
-- user ids, broker ids, company ids, team ids, audit ids, or customer data.
--
-- NOTE ABOUT PUBLIC:
-- PostgreSQL PUBLIC is a pseudo-role, not a normal role. Do not use
-- has_table_privilege('PUBLIC', ...) or has_function_privilege('PUBLIC', ...)
-- in this project because the hosted environment may raise role-not-found.
-- For PUBLIC diagnostics, use aclexplode(...) and grantee = 0.

-- -----------------------------------------------------------------------------
-- A. Table/view grants for anon, authenticated, service_role, PUBLIC/public
-- -----------------------------------------------------------------------------

select
  table_schema,
  table_name,
  grantee,
  lower(grantee) as grantee_normalized,
  string_agg(privilege_type, ', ' order by privilege_type) as privileges
from information_schema.role_table_grants
where table_schema not in ('pg_catalog', 'information_schema')
  and lower(grantee) in ('anon', 'authenticated', 'service_role', 'public')
group by table_schema, table_name, grantee, lower(grantee)
order by table_schema, table_name, grantee_normalized;

-- -----------------------------------------------------------------------------
-- A.1 PUBLIC effective privilege diagnostic for sensitive public tables/views.
-- Expected result after hardening: all public_* columns false.
-- PUBLIC is detected through aclexplode(...), where grantee = 0.
-- -----------------------------------------------------------------------------

with sensitive_objects(schema_name, object_name) as (
  values
    ('public', 'audit_trail'),
    ('public', 'lista_visibilidade'),
    ('public', 'mesa_cliente_desconto_politicas'),
    ('public', 'mesa_cliente_unidade_enriquecimentos'),
    ('public', 'root_audit_logs'),
    ('public', 'corretores'),
    ('public', 'vw_lotes_estado_oficial'),
    ('public', 'vw_lotes_pendentes_avaliacao')
),
resolved as (
  select
    s.schema_name,
    s.object_name,
    c.oid,
    c.relowner,
    c.relacl,
    c.relkind
  from sensitive_objects s
  left join pg_namespace n
    on n.nspname = s.schema_name
  left join pg_class c
    on c.relnamespace = n.oid
   and c.relname = s.object_name
)
select
  schema_name,
  object_name,
  oid is not null as object_exists,
  coalesce(bool_or(a.privilege_type = 'SELECT')     filter (where a.grantee = 0), false) as public_select,
  coalesce(bool_or(a.privilege_type = 'INSERT')     filter (where a.grantee = 0), false) as public_insert,
  coalesce(bool_or(a.privilege_type = 'UPDATE')     filter (where a.grantee = 0), false) as public_update,
  coalesce(bool_or(a.privilege_type = 'DELETE')     filter (where a.grantee = 0), false) as public_delete,
  coalesce(bool_or(a.privilege_type = 'TRUNCATE')   filter (where a.grantee = 0), false) as public_truncate,
  coalesce(bool_or(a.privilege_type = 'REFERENCES') filter (where a.grantee = 0), false) as public_references,
  coalesce(bool_or(a.privilege_type = 'TRIGGER')    filter (where a.grantee = 0), false) as public_trigger
from resolved r
left join lateral aclexplode(coalesce(r.relacl, acldefault('r', r.relowner))) a
  on r.oid is not null
group by schema_name, object_name, oid
order by schema_name, object_name;

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
-- C. Dangerous structural privileges for anon/authenticated/PUBLIC
-- Expected result: No rows returned.
-- -----------------------------------------------------------------------------

select
  table_schema,
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and lower(grantee) in ('anon', 'authenticated', 'public')
  and privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')
order by lower(grantee), table_name, privilege_type;

-- -----------------------------------------------------------------------------
-- D. Grants in sensitive auth/vault schemas
-- Expected result: No rows returned for anon/authenticated/PUBLIC/public.
-- -----------------------------------------------------------------------------

select
  grantee,
  lower(grantee) as grantee_normalized,
  table_schema,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema in ('auth', 'vault')
  and lower(grantee) in ('anon', 'authenticated', 'public')
order by table_schema, table_name, grantee_normalized, privilege_type;

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
-- I. Public functions/RPC touching password/auth/vault/service-role patterns
-- Expected ideal result: No rows returned.
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
  lower(grantee) as grantee_normalized,
  privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and lower(grantee) in ('anon', 'authenticated', 'public')
order by routine_name, grantee_normalized, privilege_type;

-- -----------------------------------------------------------------------------
-- J.1 PUBLIC effective EXECUTE diagnostic for sensitive functions.
-- PUBLIC is detected through aclexplode(...), where grantee = 0.
-- -----------------------------------------------------------------------------

with sensitive_functions(schema_name, function_signature) as (
  values
    ('public', 'listar_empresas_root()'),
    ('public', 'registrar_root_audit(text,uuid,jsonb)'),
    ('public', 'get_corretores_time(uuid)'),
    ('public', 'importar_leads_batch(uuid,jsonb,text)'),
    ('public', 'redefinir_senha_corretor(uuid,text)')
),
resolved as (
  select
    schema_name,
    function_signature,
    to_regprocedure(format('%I.%s', schema_name, function_signature)) as function_regprocedure
  from sensitive_functions
),
acl as (
  select
    r.schema_name,
    r.function_signature,
    r.function_regprocedure,
    p.proowner,
    p.proacl,
    a.grantee,
    a.privilege_type
  from resolved r
  left join pg_proc p
    on p.oid = r.function_regprocedure::oid
  left join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    on p.oid is not null
)
select
  schema_name,
  function_signature,
  function_regprocedure is not null as function_exists,
  coalesce(bool_or(privilege_type = 'EXECUTE') filter (where grantee = 0), false) as public_execute,
  case
    when function_regprocedure is null then null
    else has_function_privilege('anon', function_regprocedure, 'EXECUTE')
  end as anon_execute,
  case
    when function_regprocedure is null then null
    else has_function_privilege('authenticated', function_regprocedure, 'EXECUTE')
  end as authenticated_execute
from acl
group by schema_name, function_signature, function_regprocedure
order by schema_name, function_signature;

-- -----------------------------------------------------------------------------
-- J.2 Routine privileges for the five sensitive functions covered by this phase
-- -----------------------------------------------------------------------------

select
  routine_schema,
  routine_name,
  grantee,
  lower(grantee) as grantee_normalized,
  privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name in (
    'get_corretores_time',
    'importar_leads_batch',
    'listar_empresas_root',
    'redefinir_senha_corretor',
    'registrar_root_audit'
  )
  and lower(grantee) in ('anon', 'authenticated', 'public')
order by routine_name, grantee_normalized, privilege_type;

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
