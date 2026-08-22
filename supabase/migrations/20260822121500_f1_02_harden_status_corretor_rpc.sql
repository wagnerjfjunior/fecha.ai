-- FECH.AI / F1-02 / T1
-- Purpose: harden public.atualizar_status_corretor as the narrow server-side
-- authority boundary for administrative broker operational-state changes.
--
-- Product Authority decision captured for this target contract:
-- - root: may change ativo/apto_para_receber on an authorized target;
-- - admin_local: same-company only; may change ativo/apto_para_receber;
-- - gestor: own managed teams only; may change apto_para_receber only;
-- - corretor: denied;
-- - no client-supplied tenant/company/team/role authority;
-- - no frontend cutover and no direct-UPDATE revocation in this migration.
--
-- Production is the only Supabase environment currently in use. This migration
-- is intentionally fail-closed: catalog drift must stop execution before the
-- function body or grants are replaced.

-- PRE-FLIGHT — prove the exact prerequisite surface before any mutation.
do $preflight$
declare
  v_function_oid oid;
  v_owner_oid oid;
  v_postgres_oid oid;
  v_authenticated_oid oid;
  v_anon_oid oid;
  v_service_role_oid oid;
  v_security_definer boolean;
  v_proconfig text[];
  v_rls_enabled boolean;
  v_force_rls boolean;
begin
  if pg_catalog.to_regclass('public.corretores') is null then
    raise exception 'T1_PREFLIGHT_CORRETORES_TABLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.times') is null then
    raise exception 'T1_PREFLIGHT_TIMES_TABLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.admins') is null then
    raise exception 'T1_PREFLIGHT_ADMINS_TABLE_MISSING';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null then
    raise exception 'T1_PREFLIGHT_AUTH_UID_MISSING';
  end if;

  v_function_oid := pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );

  if v_function_oid is null then
    raise exception 'T1_PREFLIGHT_STATUS_FUNCTION_MISSING';
  end if;

  v_postgres_oid := pg_catalog.to_regrole('postgres');
  v_authenticated_oid := pg_catalog.to_regrole('authenticated');
  v_anon_oid := pg_catalog.to_regrole('anon');
  v_service_role_oid := pg_catalog.to_regrole('service_role');

  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null then
    raise exception 'T1_PREFLIGHT_REQUIRED_ROLE_MISSING';
  end if;

  select p.proowner, p.prosecdef, p.proconfig
    into strict v_owner_oid, v_security_definer, v_proconfig
    from pg_catalog.pg_proc as p
   where p.oid = v_function_oid;

  if v_owner_oid is distinct from v_postgres_oid then
    raise exception 'T1_PREFLIGHT_OWNER_DRIFT';
  end if;

  if v_security_definer is distinct from true then
    raise exception 'T1_PREFLIGHT_SECURITY_MODE_DRIFT';
  end if;

  if not coalesce(v_proconfig @> array['search_path=public']::text[], false) then
    raise exception 'T1_PREFLIGHT_SEARCH_PATH_DRIFT';
  end if;

  -- Current live baseline: the RPC is not executable by authenticated and is
  -- executable by service_role. Any drift means this exact migration must be
  -- reviewed again before application.
  if pg_catalog.has_function_privilege(
    v_authenticated_oid, v_function_oid, 'EXECUTE'
  ) then
    raise exception 'T1_PREFLIGHT_AUTHENTICATED_EXECUTE_ALREADY_PRESENT';
  end if;

  if not pg_catalog.has_function_privilege(
    v_service_role_oid, v_function_oid, 'EXECUTE'
  ) then
    raise exception 'T1_PREFLIGHT_SERVICE_ROLE_EXECUTE_DRIFT';
  end if;

  -- Compatibility window remains open until the later frontend cutover and
  -- separately authorized PR-03. T1 must not silently run after direct UPDATE
  -- has already been revoked by another change.
  if not pg_catalog.has_table_privilege(
    v_authenticated_oid, 'public.corretores', 'UPDATE'
  ) then
    raise exception 'T1_PREFLIGHT_DIRECT_UPDATE_ALREADY_REVOKED';
  end if;

  select c.relrowsecurity, c.relforcerowsecurity
    into strict v_rls_enabled, v_force_rls
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n
      on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relname = 'corretores';

  if v_rls_enabled is distinct from true then
    raise exception 'T1_PREFLIGHT_CORRETORES_RLS_DISABLED';
  end if;

  if v_force_rls is distinct from true then
    raise exception 'T1_PREFLIGHT_CORRETORES_FORCE_RLS_DISABLED';
  end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='user_id' and data_type='uuid'
  ) then raise exception 'T1_PREFLIGHT_USER_ID_UUID_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='empresa_id' and data_type='uuid'
  ) then raise exception 'T1_PREFLIGHT_EMPRESA_ID_UUID_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='time_id' and data_type='uuid'
  ) then raise exception 'T1_PREFLIGHT_TIME_ID_UUID_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='role' and data_type='text'
  ) then raise exception 'T1_PREFLIGHT_ROLE_TEXT_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='is_admin_local' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_ADMIN_FLAG_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='is_gestor' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_GESTOR_FLAG_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='ativo' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_ATIVO_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='corretores'
       and column_name='apto_para_receber' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_APTO_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='admins'
       and column_name='user_id' and data_type='uuid'
  ) or not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='admins'
       and column_name='ativo' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_ADMINS_CONTRACT_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='times'
       and column_name='id' and data_type='uuid'
  ) or not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='times'
       and column_name='empresa_id' and data_type='uuid'
  ) or not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='times'
       and column_name='gestor_id' and data_type='uuid'
  ) or not exists (
    select 1 from information_schema.columns
     where table_schema='public' and table_name='times'
       and column_name='ativo' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_TIMES_CONTRACT_MISSING'; end if;

  -- Actor mapping must remain unambiguous.
  if not exists (
    select 1
      from pg_catalog.pg_index as i
      join pg_catalog.pg_class as t on t.oid = i.indrelid
      join pg_catalog.pg_namespace as n on n.oid = t.relnamespace
      join pg_catalog.pg_attribute as a
        on a.attrelid = t.oid
       and a.attname = 'user_id'
       and a.attnum > 0
       and not a.attisdropped
     where n.nspname = 'public'
       and t.relname = 'corretores'
       and i.indisunique
       and i.indisvalid
       and i.indisready
       and i.indimmediate
       and i.indpred is null
       and i.indexprs is null
       and i.indnkeyatts = 1
       and i.indnatts = 1
       and i.indkey[0] = a.attnum
  ) then
    raise exception 'T1_PREFLIGHT_USER_ID_UNIQUENESS_MISSING';
  end if;
end;
$preflight$;

create or replace function public.atualizar_status_corretor(
  p_corretor_id uuid,
  p_ativo boolean default null,
  p_apto_para_receber boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog
as $function$
declare
  v_actor_user_id uuid;
  v_actor_id uuid;
  v_actor_empresa_id uuid;
  v_actor_active boolean;
  v_actor_is_admin_local boolean := false;
  v_actor_is_gestor boolean := false;
  v_actor_is_admin_global boolean := false;
  v_root boolean := false;
  v_final_ativo boolean;
  v_final_apto boolean;
begin
  v_actor_user_id := auth.uid();

  if v_actor_user_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'AUTH_REQUIRED',
      'error', 'Usuário não autenticado'
    );
  end if;

  -- Platform root is derived server-side from public.admins. The historical
  -- active admin_global compatibility path is retained until PR-03 closes
  -- direct authority-field mutation.
  select exists (
    select 1
      from public.admins as a
     where a.user_id = v_actor_user_id
       and a.ativo is true
  ) into v_root;

  begin
    select
      c.id,
      c.empresa_id,
      c.ativo,
      (coalesce(c.is_admin_local, false) or c.role = 'admin_local'),
      (coalesce(c.is_gestor, false) or c.role = 'gestor'),
      (c.role = 'admin_global')
    into strict
      v_actor_id,
      v_actor_empresa_id,
      v_actor_active,
      v_actor_is_admin_local,
      v_actor_is_gestor,
      v_actor_is_admin_global
    from public.corretores as c
    where c.user_id = v_actor_user_id;
  exception
    when no_data_found then
      if not v_root then
        return jsonb_build_object(
          'ok', false,
          'code', 'ACTOR_NOT_FOUND',
          'error', 'Perfil do usuário autenticado não encontrado'
        );
      end if;
    when too_many_rows then
      return jsonb_build_object(
        'ok', false,
        'code', 'ACTOR_AMBIGUOUS',
        'error', 'Perfil autenticado ambíguo'
      );
  end;

  if v_actor_is_admin_global and v_actor_active is true then
    v_root := true;
  end if;

  if not v_root and v_actor_active is distinct from true then
    return jsonb_build_object(
      'ok', false,
      'code', 'PROFILE_INACTIVE',
      'error', 'Perfil autenticado inativo'
    );
  end if;

  if p_ativo is null and p_apto_para_receber is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'NO_CHANGE_REQUESTED',
      'error', 'Nenhuma alteração solicitada'
    );
  end if;

  if v_root then
    update public.corretores as c
       set ativo = coalesce(p_ativo, c.ativo),
           apto_para_receber = coalesce(p_apto_para_receber, c.apto_para_receber)
     where c.id = p_corretor_id
     returning c.ativo, c.apto_para_receber
      into v_final_ativo, v_final_apto;

  elsif v_actor_is_admin_local then
    update public.corretores as c
       set ativo = coalesce(p_ativo, c.ativo),
           apto_para_receber = coalesce(p_apto_para_receber, c.apto_para_receber)
     where c.id = p_corretor_id
       and c.empresa_id = v_actor_empresa_id
     returning c.ativo, c.apto_para_receber
      into v_final_ativo, v_final_apto;

  elsif v_actor_is_gestor then
    if p_ativo is not null then
      return jsonb_build_object(
        'ok', false,
        'code', 'ACTIVE_CHANGE_DENIED_FOR_MANAGER',
        'error', 'Gestor não pode alterar o estado ativo do corretor'
      );
    end if;

    update public.corretores as c
       set apto_para_receber = coalesce(p_apto_para_receber, c.apto_para_receber)
     where c.id = p_corretor_id
       and c.empresa_id = v_actor_empresa_id
       and c.role = 'corretor'
       and coalesce(c.is_admin_local, false) = false
       and coalesce(c.is_gestor, false) = false
       and exists (
         select 1
           from public.times as t
          where t.id = c.time_id
            and t.empresa_id = v_actor_empresa_id
            and t.gestor_id = v_actor_id
            and coalesce(t.ativo, true) = true
       )
     returning c.ativo, c.apto_para_receber
      into v_final_ativo, v_final_apto;

  else
    return jsonb_build_object(
      'ok', false,
      'code', 'ACCESS_DENIED',
      'error', 'Sem permissão para alterar status de corretor'
    );
  end if;

  -- Do not leak target existence or tenant membership to an unauthorized caller.
  if not found then
    return jsonb_build_object(
      'ok', false,
      'code', 'TARGET_NOT_AUTHORIZED',
      'error', 'Corretor alvo indisponível para esta operação'
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'corretor_id', p_corretor_id,
    'ativo', v_final_ativo,
    'apto_para_receber', v_final_apto
  );
end;
$function$;

alter function public.atualizar_status_corretor(uuid, boolean, boolean)
  owner to postgres;

revoke all on function public.atualizar_status_corretor(uuid, boolean, boolean)
  from public;
revoke all on function public.atualizar_status_corretor(uuid, boolean, boolean)
  from anon;
revoke all on function public.atualizar_status_corretor(uuid, boolean, boolean)
  from service_role;
grant execute on function public.atualizar_status_corretor(uuid, boolean, boolean)
  to authenticated;

comment on function public.atualizar_status_corretor(uuid, boolean, boolean) is
  'F1-02 T1: server-authoritative operational broker status command. Root may change ativo/apto; admin_local same tenant; gestor own managed ordinary brokers and apto only.';

-- POST-FLIGHT — prove the resulting authority contract while preserving the
-- direct-UPDATE compatibility window for the later frontend cutover.
do $postflight$
declare
  v_function_oid oid;
  v_owner_oid oid;
  v_postgres_oid oid;
  v_authenticated_oid oid;
  v_anon_oid oid;
  v_service_role_oid oid;
  v_security_definer boolean;
  v_proconfig text[];
begin
  v_function_oid := pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  v_postgres_oid := pg_catalog.to_regrole('postgres');
  v_authenticated_oid := pg_catalog.to_regrole('authenticated');
  v_anon_oid := pg_catalog.to_regrole('anon');
  v_service_role_oid := pg_catalog.to_regrole('service_role');

  if v_function_oid is null then
    raise exception 'T1_POSTFLIGHT_FUNCTION_MISSING';
  end if;

  select p.proowner, p.prosecdef, p.proconfig
    into strict v_owner_oid, v_security_definer, v_proconfig
    from pg_catalog.pg_proc as p
   where p.oid = v_function_oid;

  if v_owner_oid is distinct from v_postgres_oid then
    raise exception 'T1_POSTFLIGHT_OWNER_NOT_POSTGRES';
  end if;

  if v_security_definer is distinct from true then
    raise exception 'T1_POSTFLIGHT_SECURITY_DEFINER_MISSING';
  end if;

  if not coalesce(v_proconfig @> array['search_path=pg_catalog']::text[], false) then
    raise exception 'T1_POSTFLIGHT_SEARCH_PATH_NOT_FIXED';
  end if;

  if not pg_catalog.has_function_privilege(
    v_authenticated_oid, v_function_oid, 'EXECUTE'
  ) then
    raise exception 'T1_POSTFLIGHT_AUTHENTICATED_EXECUTE_MISSING';
  end if;

  if pg_catalog.has_function_privilege(
    v_anon_oid, v_function_oid, 'EXECUTE'
  ) then
    raise exception 'T1_POSTFLIGHT_ANON_EXECUTE_PRESENT';
  end if;

  if pg_catalog.has_function_privilege(
    v_service_role_oid, v_function_oid, 'EXECUTE'
  ) then
    raise exception 'T1_POSTFLIGHT_SERVICE_ROLE_EXECUTE_PRESENT';
  end if;

  if exists (
    select 1
      from pg_catalog.pg_proc as p
      cross join lateral pg_catalog.aclexplode(
        coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))
      ) as acl
     where p.oid = v_function_oid
       and acl.privilege_type = 'EXECUTE'
       and acl.grantee = 0
  ) then
    raise exception 'T1_POSTFLIGHT_PUBLIC_EXECUTE_PRESENT';
  end if;

  if exists (
    select 1
      from pg_catalog.pg_proc as p
      cross join lateral pg_catalog.aclexplode(
        coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))
      ) as acl
     where p.oid = v_function_oid
       and acl.privilege_type = 'EXECUTE'
       and acl.grantee not in (v_owner_oid, v_authenticated_oid)
  ) then
    raise exception 'T1_POSTFLIGHT_UNEXPECTED_EXECUTOR';
  end if;

  if not pg_catalog.has_table_privilege(
    v_authenticated_oid, 'public.corretores', 'UPDATE'
  ) then
    raise exception 'T1_POSTFLIGHT_COMPATIBILITY_UPDATE_NOT_PRESERVED';
  end if;
end;
$postflight$;

-- EXACT ROLLBACK — execute only under a separately authorized production
-- rollback operation. This restores the exact live function contract observed
-- before T1 and restores its pre-T1 execution grants.
--
-- create or replace function public.atualizar_status_corretor(
--   p_corretor_id uuid,
--   p_ativo boolean default null,
--   p_apto_para_receber boolean default null
-- )
-- returns jsonb
-- language plpgsql
-- security definer
-- set search_path = public
-- as $rollback$
-- declare
--   v_empresa_id uuid;
--   v_root boolean := false;
-- begin
--   v_root := public.is_root();
--
--   select empresa_id into v_empresa_id
--   from public.corretores
--   where user_id = auth.uid()
--   limit 1;
--
--   if not (public.is_admin_local() or public.is_gestor() or v_root) then
--     return jsonb_build_object('error', 'forbidden');
--   end if;
--
--   if not exists (
--     select 1
--     from public.corretores
--     where id = p_corretor_id
--       and (v_root or empresa_id = v_empresa_id)
--   ) then
--     return jsonb_build_object('error', 'not_found');
--   end if;
--
--   update public.corretores
--   set ativo = coalesce(p_ativo, ativo),
--       apto_para_receber = coalesce(p_apto_para_receber, apto_para_receber)
--   where id = p_corretor_id
--     and (v_root or empresa_id = v_empresa_id);
--
--   return jsonb_build_object('ok', true);
-- end;
-- $rollback$;
--
-- alter function public.atualizar_status_corretor(uuid, boolean, boolean)
--   owner to postgres;
-- revoke all on function public.atualizar_status_corretor(uuid, boolean, boolean)
--   from public;
-- revoke all on function public.atualizar_status_corretor(uuid, boolean, boolean)
--   from anon;
-- revoke all on function public.atualizar_status_corretor(uuid, boolean, boolean)
--   from authenticated;
-- grant execute on function public.atualizar_status_corretor(uuid, boolean, boolean)
--   to service_role;
