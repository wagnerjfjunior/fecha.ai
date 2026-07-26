-- FECH.AI / GPT3 / bounded Supabase catalog gateway
-- Purpose: expose one fixed, read-only metadata snapshot required to
-- independently revalidate PR #103 without reading business rows, auth.users,
-- secrets or arbitrary tables.
--
-- This migration does not alter PR #103, public.corretores, RLS, policies,
-- business grants, Auth configuration or application data.
--
-- Exact rollback:
--   revoke all on function public.gpt_security_metadata_snapshot() from public;
--   revoke all on function public.gpt_security_metadata_snapshot() from anon;
--   revoke all on function public.gpt_security_metadata_snapshot() from authenticated;
--   revoke all on function public.gpt_security_metadata_snapshot() from service_role;
--   drop function if exists public.gpt_security_metadata_snapshot();

begin;

do $preflight$
begin
  if not exists (
    select 1
    from pg_catalog.pg_class c
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'corretores'
      and c.relkind in ('r', 'p')
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_CORRETORES_TABLE_MISSING';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corretores'
      and column_name = 'user_id'
      and data_type = 'uuid'
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_USER_ID_UUID_MISSING';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corretores'
      and column_name = 'ativo'
      and data_type = 'boolean'
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_ATIVO_BOOLEAN_MISSING';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corretores'
      and column_name = 'must_change_password'
      and data_type = 'boolean'
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_PASSWORD_STATE_BOOLEAN_MISSING';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_AUTH_UID_MISSING';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'gpt_security_metadata_snapshot'
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_FUNCTION_NAME_ALREADY_EXISTS';
  end if;

  if pg_catalog.to_regrole('postgres') is null
     or pg_catalog.to_regrole('service_role') is null
     or pg_catalog.to_regrole('authenticated') is null
     or pg_catalog.to_regrole('anon') is null then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_REQUIRED_ROLE_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_language
    where lanname = 'sql'
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_SQL_LANGUAGE_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_language
    where lanname = 'plpgsql'
  ) then
    raise exception 'GPT3_GATEWAY_PREFLIGHT_PLPGSQL_LANGUAGE_MISSING';
  end if;
end;
$preflight$;

create function public.gpt_security_metadata_snapshot()
returns jsonb
language sql
stable
security invoker
set search_path = pg_catalog
as $function$
with required_roles(role_name) as (
  values ('postgres'::text), ('authenticated'::text), ('anon'::text), ('service_role'::text)
),
target_relation as (
  select c.oid, c.relname, c.relrowsecurity, c.relforcerowsecurity,
         c.relkind, c.relowner, c.relacl, n.nspname
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'corretores'
    and c.relkind in ('r','p')
),
target_functions as (
  select p.oid, n.nspname, p.proname, p.proowner, p.prosecdef, p.provolatile,
         p.proparallel, p.proconfig, p.proacl, l.lanname,
         pg_catalog.pg_get_function_identity_arguments(p.oid) as identity_arguments,
         pg_catalog.pg_get_function_result(p.oid) as result_type
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  join pg_catalog.pg_language l on l.oid = p.prolang
  where p.oid in (
    pg_catalog.to_regprocedure('auth.uid()'),
    pg_catalog.to_regprocedure('public.marcar_senha_inicial_definida()')
  )
),
trigger_functions as (
  select distinct p.oid, n.nspname, p.proname, p.proowner, p.prosecdef,
         p.provolatile, p.proparallel, p.proconfig, p.proacl, l.lanname,
         pg_catalog.pg_get_function_identity_arguments(p.oid) as identity_arguments,
         pg_catalog.pg_get_function_result(p.oid) as result_type,
         pg_catalog.pg_get_functiondef(p.oid) as function_definition
  from target_relation tr
  join pg_catalog.pg_trigger tg on tg.tgrelid = tr.oid and not tg.tgisinternal
  join pg_catalog.pg_proc p on p.oid = tg.tgfoid
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  join pg_catalog.pg_language l on l.oid = p.prolang
)
select pg_catalog.jsonb_build_object(
  'snapshot_version', 'pr103_preflight_v1',
  'generated_at', pg_catalog.statement_timestamp(),
  'scope', pg_catalog.jsonb_build_object(
    'project_ref', 'uobxxgzshrmbtjfdolxd',
    'access_mode', 'read_only',
    'schema', 'public',
    'target_table', 'corretores',
    'includes_row_data', false,
    'includes_auth_users', false,
    'includes_secrets', false,
    'includes_business_payload', false,
    'includes_function_source', true,
    'function_source_scope', 'trigger functions attached to public.corretores only'
  ),
  'table', coalesce((
    select pg_catalog.jsonb_build_object(
      'exists', true,
      'schema', tr.nspname,
      'name', tr.relname,
      'relkind', tr.relkind,
      'owner', pg_catalog.pg_get_userbyid(tr.relowner),
      'rls_enabled', tr.relrowsecurity,
      'rls_forced', tr.relforcerowsecurity
    )
    from target_relation tr
  ), pg_catalog.jsonb_build_object('exists', false)),
  'columns', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'name', c.column_name,
        'ordinal_position', c.ordinal_position,
        'data_type', c.data_type,
        'udt_schema', c.udt_schema,
        'udt_name', c.udt_name,
        'is_nullable', c.is_nullable,
        'column_default', c.column_default,
        'is_identity', c.is_identity,
        'identity_generation', c.identity_generation
      )
      order by c.ordinal_position
    )
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'corretores'
      and c.column_name in ('user_id','ativo','must_change_password')
  ), '[]'::pg_catalog.jsonb),
  'indexes', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'name', idx.relname,
        'owner', pg_catalog.pg_get_userbyid(idx.relowner),
        'is_unique', i.indisunique,
        'is_primary', i.indisprimary,
        'is_valid', i.indisvalid,
        'is_ready', i.indisready,
        'is_immediate', i.indimmediate,
        'is_partial', i.indpred is not null,
        'has_expressions', i.indexprs is not null,
        'key_attribute_count', i.indnkeyatts,
        'total_attribute_count', i.indnatts,
        'key_columns', coalesce((
          select pg_catalog.jsonb_agg(a.attname order by k.ordinality)
          from pg_catalog.unnest(i.indkey::pg_catalog.int2[]) with ordinality as k(attnum, ordinality)
          left join pg_catalog.pg_attribute a
            on a.attrelid = i.indrelid
           and a.attnum = k.attnum
          where k.ordinality <= i.indnkeyatts
        ), '[]'::pg_catalog.jsonb),
        'definition', pg_catalog.pg_get_indexdef(i.indexrelid)
      )
      order by idx.relname
    )
    from target_relation tr
    join pg_catalog.pg_index i on i.indrelid = tr.oid
    join pg_catalog.pg_class idx on idx.oid = i.indexrelid
  ), '[]'::pg_catalog.jsonb),
  'constraints', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'name', con.conname,
        'type', con.contype,
        'validated', con.convalidated,
        'deferrable', con.condeferrable,
        'initially_deferred', con.condeferred,
        'definition', pg_catalog.pg_get_constraintdef(con.oid, true)
      )
      order by con.conname
    )
    from target_relation tr
    join pg_catalog.pg_constraint con on con.conrelid = tr.oid
  ), '[]'::pg_catalog.jsonb),
  'triggers', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'name', tg.tgname,
        'enabled', tg.tgenabled,
        'is_internal', tg.tgisinternal,
        'definition', pg_catalog.pg_get_triggerdef(tg.oid, true),
        'function_schema', fn_ns.nspname,
        'function_name', fn.proname,
        'function_identity_arguments', pg_catalog.pg_get_function_identity_arguments(fn.oid)
      )
      order by tg.tgname
    )
    from target_relation tr
    join pg_catalog.pg_trigger tg on tg.tgrelid = tr.oid
    join pg_catalog.pg_proc fn on fn.oid = tg.tgfoid
    join pg_catalog.pg_namespace fn_ns on fn_ns.oid = fn.pronamespace
    where not tg.tgisinternal
  ), '[]'::pg_catalog.jsonb),
  'trigger_functions', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'schema', tf.nspname,
        'name', tf.proname,
        'identity_arguments', tf.identity_arguments,
        'result_type', tf.result_type,
        'owner', pg_catalog.pg_get_userbyid(tf.proowner),
        'language', tf.lanname,
        'security_definer', tf.prosecdef,
        'volatility', tf.provolatile,
        'parallel', tf.proparallel,
        'config', coalesce(pg_catalog.to_jsonb(tf.proconfig), '[]'::pg_catalog.jsonb),
        'definition', tf.function_definition
      )
      order by tf.nspname, tf.proname, tf.identity_arguments
    )
    from trigger_functions tf
  ), '[]'::pg_catalog.jsonb),
  'required_functions', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'schema', tf.nspname,
        'name', tf.proname,
        'identity_arguments', tf.identity_arguments,
        'result_type', tf.result_type,
        'owner', pg_catalog.pg_get_userbyid(tf.proowner),
        'language', tf.lanname,
        'security_definer', tf.prosecdef,
        'volatility', tf.provolatile,
        'parallel', tf.proparallel,
        'config', coalesce(pg_catalog.to_jsonb(tf.proconfig), '[]'::pg_catalog.jsonb),
        'acl', coalesce((
          select pg_catalog.jsonb_agg(
            pg_catalog.jsonb_build_object(
              'grantee', case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
              'grantor', pg_catalog.pg_get_userbyid(x.grantor),
              'privilege', x.privilege_type,
              'grantable', x.is_grantable
            )
            order by case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
                     x.privilege_type
          )
          from pg_catalog.aclexplode(coalesce(tf.proacl, pg_catalog.acldefault('f', tf.proowner))) x
        ), '[]'::pg_catalog.jsonb)
      )
      order by tf.nspname, tf.proname, tf.identity_arguments
    )
    from target_functions tf
  ), '[]'::pg_catalog.jsonb),
  'required_function_existence', pg_catalog.jsonb_build_object(
    'auth_uid', pg_catalog.to_regprocedure('auth.uid()') is not null,
    'password_state_rpc', pg_catalog.to_regprocedure('public.marcar_senha_inicial_definida()') is not null
  ),
  'roles', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'name', rr.role_name,
        'exists', r.oid is not null,
        'can_login', r.rolcanlogin,
        'superuser', r.rolsuper,
        'inherit', r.rolinherit,
        'bypass_rls', r.rolbypassrls
      )
      order by rr.role_name
    )
    from required_roles rr
    left join pg_catalog.pg_roles r on r.rolname = rr.role_name
  ), '[]'::pg_catalog.jsonb),
  'role_memberships', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'role', parent.rolname,
        'member', member.rolname,
        'grantor', grantor.rolname,
        'admin_option', m.admin_option,
        'inherit_option', m.inherit_option,
        'set_option', m.set_option
      )
      order by parent.rolname, member.rolname
    )
    from pg_catalog.pg_auth_members m
    join pg_catalog.pg_roles parent on parent.oid = m.roleid
    join pg_catalog.pg_roles member on member.oid = m.member
    left join pg_catalog.pg_roles grantor on grantor.oid = m.grantor
    where parent.rolname in (select role_name from required_roles)
       or member.rolname in (select role_name from required_roles)
  ), '[]'::pg_catalog.jsonb),
  'schema_effective_privileges', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'role', rr.role_name,
        'privilege', p.privilege,
        'allowed', case
          when pg_catalog.to_regrole(rr.role_name) is null then null
          else pg_catalog.has_schema_privilege(rr.role_name, 'public', p.privilege)
        end
      )
      order by rr.role_name, p.privilege
    )
    from required_roles rr
    cross join (values ('USAGE'::text), ('CREATE'::text)) p(privilege)
  ), '[]'::pg_catalog.jsonb),
  'table_direct_acl', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'grantee', case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
        'grantor', pg_catalog.pg_get_userbyid(x.grantor),
        'privilege', x.privilege_type,
        'grantable', x.is_grantable
      )
      order by case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
               x.privilege_type
    )
    from target_relation tr
    cross join lateral pg_catalog.aclexplode(coalesce(tr.relacl, pg_catalog.acldefault('r', tr.relowner))) x
  ), '[]'::pg_catalog.jsonb),
  'table_effective_privileges', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'role', rr.role_name,
        'privilege', p.privilege,
        'allowed', case
          when pg_catalog.to_regrole(rr.role_name) is null
            or pg_catalog.to_regclass('public.corretores') is null then null
          else pg_catalog.has_table_privilege(rr.role_name, 'public.corretores', p.privilege)
        end
      )
      order by rr.role_name, p.privilege
    )
    from required_roles rr
    cross join (
      values ('SELECT'::text), ('INSERT'::text), ('UPDATE'::text),
             ('DELETE'::text), ('TRUNCATE'::text), ('REFERENCES'::text), ('TRIGGER'::text)
    ) p(privilege)
  ), '[]'::pg_catalog.jsonb),
  'column_direct_acl', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'column', a.attname,
        'grantee', case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
        'grantor', pg_catalog.pg_get_userbyid(x.grantor),
        'privilege', x.privilege_type,
        'grantable', x.is_grantable
      )
      order by a.attname,
               case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
               x.privilege_type
    )
    from target_relation tr
    join pg_catalog.pg_attribute a
      on a.attrelid = tr.oid
     and a.attname in ('user_id','ativo','must_change_password')
     and a.attnum > 0
     and not a.attisdropped
    cross join lateral pg_catalog.aclexplode(a.attacl) x
    where a.attacl is not null
  ), '[]'::pg_catalog.jsonb),
  'column_effective_privileges', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'role', rr.role_name,
        'column', c.column_name,
        'privilege', p.privilege,
        'allowed', case
          when pg_catalog.to_regrole(rr.role_name) is null
            or pg_catalog.to_regclass('public.corretores') is null then null
          else pg_catalog.has_column_privilege(
            rr.role_name,
            'public.corretores',
            c.column_name,
            p.privilege
          )
        end
      )
      order by rr.role_name, c.column_name, p.privilege
    )
    from required_roles rr
    cross join (values ('user_id'::text), ('ativo'::text), ('must_change_password'::text)) c(column_name)
    cross join (values ('SELECT'::text), ('INSERT'::text), ('UPDATE'::text), ('REFERENCES'::text)) p(privilege)
  ), '[]'::pg_catalog.jsonb),
  'default_function_acl', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'owner', owner_role.rolname,
        'schema', ns.nspname,
        'object_type', d.defaclobjtype,
        'acl', coalesce((
          select pg_catalog.jsonb_agg(
            pg_catalog.jsonb_build_object(
              'grantee', case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
              'grantor', pg_catalog.pg_get_userbyid(x.grantor),
              'privilege', x.privilege_type,
              'grantable', x.is_grantable
            )
            order by case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
                     x.privilege_type
          )
          from pg_catalog.aclexplode(d.defaclacl) x
        ), '[]'::pg_catalog.jsonb)
      )
      order by owner_role.rolname, ns.nspname nulls first
    )
    from pg_catalog.pg_default_acl d
    join pg_catalog.pg_roles owner_role on owner_role.oid = d.defaclrole
    left join pg_catalog.pg_namespace ns on ns.oid = d.defaclnamespace
    where d.defaclobjtype = 'f'
      and owner_role.rolname in (select role_name from required_roles)
  ), '[]'::pg_catalog.jsonb),
  'builtin_function_acl_for_postgres', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'grantee', case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
        'grantor', pg_catalog.pg_get_userbyid(x.grantor),
        'privilege', x.privilege_type,
        'grantable', x.is_grantable
      )
      order by case when x.grantee = 0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(x.grantee) end,
               x.privilege_type
    )
    from pg_catalog.pg_roles r
    cross join lateral pg_catalog.aclexplode(pg_catalog.acldefault('f', r.oid)) x
    where r.rolname = 'postgres'
  ), '[]'::pg_catalog.jsonb),
  'languages', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'name', l.lanname,
        'owner', pg_catalog.pg_get_userbyid(l.lanowner),
        'trusted', l.lanpltrusted
      )
      order by l.lanname
    )
    from pg_catalog.pg_language l
    where l.lanname = 'plpgsql'
  ), '[]'::pg_catalog.jsonb),
  'policies', coalesce((
    select pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'schema', p.schemaname,
        'table', p.tablename,
        'name', p.policyname,
        'permissive', p.permissive,
        'roles', pg_catalog.to_jsonb(p.roles),
        'command', p.cmd,
        'using_expression', p.qual,
        'with_check_expression', p.with_check
      )
      order by p.policyname
    )
    from pg_catalog.pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'corretores'
  ), '[]'::pg_catalog.jsonb)
) as snapshot;
$function$;

alter function public.gpt_security_metadata_snapshot() owner to postgres;

comment on function public.gpt_security_metadata_snapshot()
is 'Returns the fixed PR103 security-catalog snapshot for the FECH.AI GPT3 gateway. No row data, auth.users, secrets, arbitrary SQL or caller-supplied object names.';

revoke all on function public.gpt_security_metadata_snapshot() from public;
revoke all on function public.gpt_security_metadata_snapshot() from anon;
revoke all on function public.gpt_security_metadata_snapshot() from authenticated;
revoke all on function public.gpt_security_metadata_snapshot() from service_role;
grant execute on function public.gpt_security_metadata_snapshot() to service_role;

do $postflight$
declare
  v_oid oid;
  v_owner oid;
begin
  v_oid := pg_catalog.to_regprocedure('public.gpt_security_metadata_snapshot()');

  if v_oid is null then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_FUNCTION_MISSING';
  end if;

  select p.proowner
    into v_owner
    from pg_catalog.pg_proc p
   where p.oid = v_oid
     and p.prosecdef is false
     and p.provolatile = 's'
     and pg_catalog.pg_get_function_identity_arguments(p.oid) = ''
     and pg_catalog.pg_get_function_result(p.oid) = 'jsonb'
     and p.proconfig @> array['search_path=pg_catalog']::text[];

  if not found then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_CONTRACT_MISMATCH';
  end if;

  if pg_catalog.pg_get_userbyid(v_owner) <> 'postgres' then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_OWNER_MISMATCH';
  end if;

  if not pg_catalog.has_function_privilege(
    'service_role',
    'public.gpt_security_metadata_snapshot()',
    'EXECUTE'
  ) then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_SERVICE_ROLE_MISSING';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.gpt_security_metadata_snapshot()',
    'EXECUTE'
  ) then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_ANON_EXECUTE_PRESENT';
  end if;

  if pg_catalog.has_function_privilege(
    'authenticated',
    'public.gpt_security_metadata_snapshot()',
    'EXECUTE'
  ) then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_AUTHENTICATED_EXECUTE_PRESENT';
  end if;

  if exists (
    select 1
      from pg_catalog.pg_proc p
      cross join lateral pg_catalog.aclexplode(
        coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))
      ) x
     where p.oid = v_oid
       and x.privilege_type = 'EXECUTE'
       and x.grantee = 0
  ) then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_PUBLIC_EXECUTE_PRESENT';
  end if;

  if exists (
    select 1
      from pg_catalog.pg_proc p
      cross join lateral pg_catalog.aclexplode(
        coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))
      ) x
     where p.oid = v_oid
       and x.privilege_type = 'EXECUTE'
       and x.grantee not in (
         p.proowner,
         pg_catalog.to_regrole('service_role')
       )
  ) then
    raise exception 'GPT3_GATEWAY_POSTFLIGHT_UNEXPECTED_EXECUTOR';
  end if;
end;
$postflight$;

commit;
