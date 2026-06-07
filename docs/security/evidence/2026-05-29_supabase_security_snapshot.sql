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
-- For PUBLIC diagnostics, use ACL inspection through aclexplode(...)
-- and grantee = 0. Table-level ACLs are stored in pg_class.relacl.
-- Column-level ACLs are stored in pg_attribute.attacl and must be checked
-- separately for SELECT, INSERT, UPDATE, and REFERENCES.

-- -----------------------------------------------------------------------------
-- A. Table/view grants visible through information_schema for ordinary roles
-- PUBLIC effective coverage is handled by A.1 using ACL diagnostics.
-- -----------------------------------------------------------------------------

select
  table_schema,
  table_name,
  grantee,
  lower(grantee) as grantee_normalized,
  string_agg(privilege_type, ', ' order by privilege_type) as privileges
from information_schema.role_table_grants
where table_schema not in ('pg_catalog', 'information_schema')
  and lower(grantee) in ('anon', 'authenticated', 'service_role')
group by table_schema, table_name, grantee, lower(grantee)
order by table_schema, table_name, grantee_normalized;

-- -----------------------------------------------------------------------------
-- A.1 PUBLIC effective privilege diagnostic for sensitive public tables/views.
-- Expected result after hardening: all public_* columns false and
-- public_column_acl_details empty.
-- PUBLIC is detected through aclexplode(...), where grantee = 0.
-- This diagnostic checks both table ACLs and column ACLs.
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
),
table_acl as (
  select
    r.oid,
    a.privilege_type
  from resolved r
  left join lateral aclexplode(coalesce(r.relacl, acldefault('r', r.relowner))) a
    on r.oid is not null
  where a.grantee = 0
),
column_acl as (
  select
    r.oid,
    att.attname,
    a.privilege_type
  from resolved r
  join pg_attribute att
    on att.attrelid = r.oid
   and att.attnum > 0
   and att.attisdropped = false
  join lateral aclexplode(att.attacl) a
    on att.attacl is not null
  where a.grantee = 0
)
select
  r.schema_name,
  r.object_name,
  r.oid is not null as object_exists,
  (
    exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'SELECT')
    or exists (select 1 from column_acl ca where ca.oid = r.oid and ca.privilege_type = 'SELECT')
  ) as public_select,
  (
    exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'INSERT')
    or exists (select 1 from column_acl ca where ca.oid = r.oid and ca.privilege_type = 'INSERT')
  ) as public_insert,
  (
    exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'UPDATE')
    or exists (select 1 from column_acl ca where ca.oid = r.oid and ca.privilege_type = 'UPDATE')
  ) as public_update,
  exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'DELETE') as public_delete,
  exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'TRUNCATE') as public_truncate,
  (
    exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'REFERENCES')
    or exists (select 1 from column_acl ca where ca.oid = r.oid and ca.privilege_type = 'REFERENCES')
  ) as public_references,
  exists (select 1 from table_acl ta where ta.oid = r.oid and ta.privilege_type = 'TRIGGER') as public_trigger,
  exists (select 1 from column_acl ca where ca.oid = r.oid) as public_column_acl_detected,
  coalesce((
    select string_agg(detail, ', ' order by detail)
    from (
      select distinct ca.attname || ':' || ca.privilege_type as detail
      from column_acl ca
      where ca.oid = r.oid
    ) d
  ), '') as public_column_acl_details
from resolved r
order by r.schema_name, r.object_name;

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
-- C. Dangerous structural privileges for anon/authenticated/PUBLIC.
-- Expected result: No rows returned.
-- This diagnostic is ACL-based so it can report PUBLIC pseudo-role grants.
-- It checks table-level TRUNCATE/TRIGGER/REFERENCES and column-level REFERENCES.
-- -----------------------------------------------------------------------------

with public_relations as (
  select
    n.nspname as table_schema,
    c.relname as table_name,
    c.oid,
    c.relowner,
    c.relacl
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p', 'v', 'm')
),
table_acl as (
  select
    r.table_schema,
    r.table_name,
    null::text as column_name,
    case when a.grantee = 0 then 'PUBLIC' else gr.rolname end as grantee,
    a.privilege_type
  from public_relations r
  join lateral aclexplode(coalesce(r.relacl, acldefault('r', r.relowner))) a on true
  left join pg_roles gr on gr.oid = a.grantee
  where (a.grantee = 0 or gr.rolname in ('anon', 'authenticated'))
    and a.privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')
),
column_acl as (
  select
    r.table_schema,
    r.table_name,
    att.attname as column_name,
    case when a.grantee = 0 then 'PUBLIC' else gr.rolname end as grantee,
    a.privilege_type
  from public_relations r
  join pg_attribute att
    on att.attrelid = r.oid
   and att.attnum > 0
   and att.attisdropped = false
  join lateral aclexplode(att.attacl) a
    on att.attacl is not null
  left join pg_roles gr on gr.oid = a.grantee
  where (a.grantee = 0 or gr.rolname in ('anon', 'authenticated'))
    and a.privilege_type = 'REFERENCES'
)
select
  table_schema,
  table_name,
  column_name,
  grantee,
  privilege_type
from table_acl
union all
select
  table_schema,
  table_name,
  column_name,
  grantee,
  privilege_type
from column_acl
order by grantee, table_name, column_name nulls first, privilege_type;

-- -----------------------------------------------------------------------------
-- D. Grants in sensitive auth/vault schemas for anon/authenticated/PUBLIC.
-- Expected result: No rows returned.
-- This diagnostic is ACL-based so it can report PUBLIC pseudo-role grants.
-- -----------------------------------------------------------------------------

with sensitive_relations as (
  select
    n.nspname as table_schema,
    c.relname as table_name,
    c.oid,
    c.relowner,
    c.relacl
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname in ('auth', 'vault')
    and c.relkind in ('r', 'p', 'v', 'm')
),
table_acl as (
  select
    r.table_schema,
    r.table_name,
    null::text as column_name,
    case when a.grantee = 0 then 'PUBLIC' else gr.rolname end as grantee,
    a.privilege_type
  from sensitive_relations r
  join lateral aclexplode(coalesce(r.relacl, acldefault('r', r.relowner))) a on true
  left join pg_roles gr on gr.oid = a.grantee
  where a.grantee = 0 or gr.rolname in ('anon', 'authenticated')
),
column_acl as (
  select
    r.table_schema,
    r.table_name,
    att.attname as column_name,
    case when a.grantee = 0 then 'PUBLIC' else gr.rolname end as grantee,
    a.privilege_type
  from sensitive_relations r
  join pg_attribute att
    on att.attrelid = r.oid
   and att.attnum > 0
   and att.attisdropped = false
  join lateral aclexplode(att.attacl) a
    on att.attacl is not null
  left join pg_roles gr on gr.oid = a.grantee
  where a.grantee = 0 or gr.rolname in ('anon', 'authenticated')
)
select
  table_schema,
  table_name,
  column_name,
  grantee,
  privilege_type
from table_acl
union all
select
  table_schema,
  table_name,
  column_name,
  grantee,
  privilege_type
from column_acl
order by table_schema, table_name, column_name nulls first, grantee, privilege_type;

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
-- J. Routine privileges for public functions/RPCs.
-- This diagnostic is ACL-based so it can report PUBLIC pseudo-role grants.
-- -----------------------------------------------------------------------------

select
  n.nspname as routine_schema,
  p.proname as routine_name,
  pg_get_function_identity_arguments(p.oid) as routine_args,
  case when a.grantee = 0 then 'PUBLIC' else gr.rolname end as grantee,
  a.privilege_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a on true
left join pg_roles gr on gr.oid = a.grantee
where n.nspname = 'public'
  and (a.grantee = 0 or gr.rolname in ('anon', 'authenticated'))
order by routine_name, routine_args, grantee, privilege_type;

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
  n.nspname as routine_schema,
  p.proname as routine_name,
  pg_get_function_identity_arguments(p.oid) as routine_args,
  case when a.grantee = 0 then 'PUBLIC' else gr.rolname end as grantee,
  a.privilege_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a on true
left join pg_roles gr on gr.oid = a.grantee
where n.nspname = 'public'
  and p.proname in (
    'get_corretores_time',
    'importar_leads_batch',
    'listar_empresas_root',
    'redefinir_senha_corretor',
    'registrar_root_audit'
  )
  and (a.grantee = 0 or gr.rolname in ('anon', 'authenticated'))
order by routine_name, routine_args, grantee, privilege_type;

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
