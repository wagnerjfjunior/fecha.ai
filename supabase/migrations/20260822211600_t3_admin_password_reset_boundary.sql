-- FECH.AI — T3A-v1
-- Administrative Password Reset Multi-Tenant Authority Boundary
-- Scope: server-side authorization + must_change_password preparation only.
-- No Auth password change occurs in PostgreSQL; the versioned Edge Function
-- consumes this RPC before calling auth.admin.updateUserById().

begin;

-- ---------------------------------------------------------------------------
-- 1. FAIL-CLOSED PREFLIGHT
-- ---------------------------------------------------------------------------
do $preflight$
declare
  v_missing text[];
  v_existing regprocedure;
  v_bad_rls text[];
begin
  select array_agg(req.object_name order by req.object_name)
    into v_missing
  from (
    values
      ('public.corretores.id',              to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='id')),
      ('public.corretores.user_id',         to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='user_id')),
      ('public.corretores.empresa_id',      to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='empresa_id')),
      ('public.corretores.time_id',         to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='time_id')),
      ('public.corretores.role',            to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='role')),
      ('public.corretores.ativo',           to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='ativo')),
      ('public.corretores.is_admin_local',  to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_admin_local')),
      ('public.corretores.is_gestor',       to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_gestor')),
      ('public.corretores.must_change_password', to_regclass('public.corretores') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='must_change_password')),
      ('public.admins.user_id',             to_regclass('public.admins') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='user_id')),
      ('public.admins.role',                to_regclass('public.admins') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='role')),
      ('public.admins.ativo',               to_regclass('public.admins') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='ativo')),
      ('public.times.id',                   to_regclass('public.times') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='id')),
      ('public.times.gestor_id',            to_regclass('public.times') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='gestor_id')),
      ('public.times.empresa_id',           to_regclass('public.times') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='empresa_id')),
      ('public.times.ativo',                to_regclass('public.times') is not null and exists(select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='ativo'))
  ) as req(object_name, present)
  where req.present is not true;

  if v_missing is not null then
    raise exception 'T3A_PREFLIGHT_REQUIRED_OBJECTS_MISSING: %', array_to_string(v_missing, ', ');
  end if;

  select to_regprocedure('public.t3_prepare_admin_password_reset(uuid)') into v_existing;
  if v_existing is not null then
    raise exception 'T3A_PREFLIGHT_FUNCTION_ALREADY_EXISTS';
  end if;

  if to_regprocedure('public.marcar_senha_inicial_definida()') is null then
    raise exception 'T3A_PREFLIGHT_SELF_PASSWORD_RPC_MISSING';
  end if;

  if md5(pg_get_functiondef(to_regprocedure('public.marcar_senha_inicial_definida()'))) <> '2a7b28d4bb6342a99d075c4d3c49af4d' then
    raise exception 'T3A_PREFLIGHT_SELF_PASSWORD_RPC_DRIFT';
  end if;

  if not has_function_privilege('authenticated', to_regprocedure('public.marcar_senha_inicial_definida()'), 'EXECUTE') then
    raise exception 'T3A_PREFLIGHT_SELF_PASSWORD_RPC_NOT_EXECUTABLE';
  end if;

  if has_table_privilege('authenticated', 'public.corretores', 'UPDATE') then
    raise exception 'T3A_PREFLIGHT_BROAD_UPDATE_UNEXPECTED';
  end if;

  if not has_column_privilege('authenticated', 'public.corretores', 'ativo', 'UPDATE')
     or not has_column_privilege('authenticated', 'public.corretores', 'apto_para_receber', 'UPDATE')
     or not has_column_privilege('authenticated', 'public.corretores', 'must_change_password', 'UPDATE')
  then
    raise exception 'T3A_PREFLIGHT_COMPAT_COLUMN_GRANTS_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_index i
    join pg_class c on c.oid=i.indrelid
    join pg_namespace n on n.oid=c.relnamespace
    join lateral unnest(i.indkey) with ordinality x(attnum, ord) on true
    join pg_attribute a on a.attrelid=c.oid and a.attnum=x.attnum
    where n.nspname='public' and c.relname='corretores' and i.indisunique
    group by i.indexrelid
    having array_agg(a.attname order by x.ord)=array['user_id']::name[]
  ) then
    raise exception 'T3A_PREFLIGHT_CORRETORES_USER_ID_NOT_UNIQUE';
  end if;

  if not exists (
    select 1
    from pg_index i
    join pg_class c on c.oid=i.indrelid
    join pg_namespace n on n.oid=c.relnamespace
    join lateral unnest(i.indkey) with ordinality x(attnum, ord) on true
    join pg_attribute a on a.attrelid=c.oid and a.attnum=x.attnum
    where n.nspname='public' and c.relname='admins' and i.indisunique
    group by i.indexrelid
    having array_agg(a.attname order by x.ord)=array['user_id']::name[]
  ) then
    raise exception 'T3A_PREFLIGHT_ADMINS_USER_ID_NOT_UNIQUE';
  end if;

  select array_agg(c.relname order by c.relname)
    into v_bad_rls
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public'
    and c.relname in ('corretores','admins','times')
    and (c.relrowsecurity is not true or c.relforcerowsecurity is not true);

  if v_bad_rls is not null then
    raise exception 'T3A_PREFLIGHT_RLS_FORCE_MISMATCH: %', array_to_string(v_bad_rls, ', ');
  end if;
end
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. AUTHORITY BOUNDARY
-- ---------------------------------------------------------------------------
create function public.t3_prepare_admin_password_reset(p_target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog
as $function$
declare
  v_actor_user_id uuid;
  v_actor_id uuid;
  v_actor_empresa_id uuid;
  v_actor_role text;
  v_actor_ativo boolean;
  v_actor_is_admin_local boolean;
  v_actor_is_gestor boolean;
  v_is_root boolean := false;

  v_target_id uuid;
  v_target_user_id uuid;
  v_target_empresa_id uuid;
  v_target_time_id uuid;
  v_target_role text;
  v_target_is_admin_local boolean;
  v_target_is_gestor boolean;
  v_rows integer;
begin
  v_actor_user_id := auth.uid();

  if v_actor_user_id is null then
    raise exception using errcode='42501', message='AUTH_REQUIRED';
  end if;

  if p_target_user_id is null then
    raise exception using errcode='42501', message='TARGET_NOT_AUTHORIZED';
  end if;

  -- Strict root authority comes only from public.admins.
  select exists (
    select 1
    from public.admins a
    where a.user_id = v_actor_user_id
      and a.ativo is true
      and a.role = 'admin_global'
  ) into v_is_root;

  if not v_is_root then
    begin
      select
        c.id,
        c.empresa_id,
        c.role,
        c.ativo,
        c.is_admin_local,
        c.is_gestor
      into strict
        v_actor_id,
        v_actor_empresa_id,
        v_actor_role,
        v_actor_ativo,
        v_actor_is_admin_local,
        v_actor_is_gestor
      from public.corretores c
      where c.user_id = v_actor_user_id;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501', message='AUTHORITY_DENIED';
    end;

    if v_actor_ativo is distinct from true then
      raise exception using errcode='42501', message='AUTHORITY_DENIED';
    end if;
  end if;

  if v_is_root then
    begin
      select
        c.id, c.user_id, c.empresa_id, c.time_id,
        c.role, c.is_admin_local, c.is_gestor
      into strict
        v_target_id, v_target_user_id, v_target_empresa_id, v_target_time_id,
        v_target_role, v_target_is_admin_local, v_target_is_gestor
      from public.corretores c
      where c.user_id = p_target_user_id
      for update;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501', message='TARGET_NOT_AUTHORIZED';
    end;

  elsif v_actor_role = 'admin_local'
    and v_actor_is_admin_local is true
  then
    begin
      select
        c.id, c.user_id, c.empresa_id, c.time_id,
        c.role, c.is_admin_local, c.is_gestor
      into strict
        v_target_id, v_target_user_id, v_target_empresa_id, v_target_time_id,
        v_target_role, v_target_is_admin_local, v_target_is_gestor
      from public.corretores c
      where c.user_id = p_target_user_id
        and c.empresa_id = v_actor_empresa_id
        and c.role <> 'admin_global'
        and not exists (
          select 1
          from public.admins protected_admin
          where protected_admin.user_id = c.user_id
        )
      for update;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501', message='TARGET_NOT_AUTHORIZED';
    end;

  elsif v_actor_role = 'gestor'
    and v_actor_is_gestor is true
    and v_actor_is_admin_local is false
  then
    begin
      select
        c.id, c.user_id, c.empresa_id, c.time_id,
        c.role, c.is_admin_local, c.is_gestor
      into strict
        v_target_id, v_target_user_id, v_target_empresa_id, v_target_time_id,
        v_target_role, v_target_is_admin_local, v_target_is_gestor
      from public.corretores c
      where c.user_id = p_target_user_id
        and c.empresa_id = v_actor_empresa_id
        and c.role = 'corretor'
        and c.is_admin_local is false
        and c.is_gestor is false
      for update;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501', message='TARGET_NOT_AUTHORIZED';
    end;

    if v_target_time_id is null or not exists (
      select 1
      from public.times t
      where t.id = v_target_time_id
        and t.empresa_id = v_actor_empresa_id
        and t.gestor_id = v_actor_id
        and t.ativo is true
    ) then
      raise exception using errcode='42501', message='TARGET_NOT_AUTHORIZED';
    end if;

  else
    raise exception using errcode='42501', message='AUTHORITY_DENIED';
  end if;

  update public.corretores c
     set must_change_password = true
   where c.id = v_target_id
     and c.user_id = v_target_user_id;

  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception using errcode='P0001', message='PASSWORD_STATE_PREPARE_FAILED';
  end if;

  return jsonb_build_object(
    'ok', true,
    'user_id', v_target_user_id
  );
end
$function$;

alter function public.t3_prepare_admin_password_reset(uuid) owner to postgres;
revoke all on function public.t3_prepare_admin_password_reset(uuid) from public;
revoke all on function public.t3_prepare_admin_password_reset(uuid) from anon;
revoke all on function public.t3_prepare_admin_password_reset(uuid) from service_role;
grant execute on function public.t3_prepare_admin_password_reset(uuid) to authenticated;

-- The old App.jsx still attempts a direct PATCH to false after a successful
-- reset. Leaving this grant in place would allow the client to undo the
-- server-side mandatory-password state. T3B will remove the stale request;
-- T3A revokes its authority now so the new boundary is non-bypassable.
revoke update (must_change_password) on table public.corretores from authenticated;

comment on function public.t3_prepare_admin_password_reset(uuid) is
'T3A-v1 | administrative password reset multi-tenant authority boundary | caller/tenant/role/team derived server-side | prepares must_change_password=true before Auth reset';

-- ---------------------------------------------------------------------------
-- 3. POSTFLIGHT
-- ---------------------------------------------------------------------------
do $postflight$
declare
  v_oid oid;
  v_acl_ok boolean;
  v_security_ok boolean;
begin
  select to_regprocedure('public.t3_prepare_admin_password_reset(uuid)')::oid
    into v_oid;

  if v_oid is null then
    raise exception 'T3A_POSTFLIGHT_FUNCTION_MISSING';
  end if;

  select
    p.prosecdef is true
    and coalesce(array_to_string(p.proconfig, ','),'') = 'search_path=pg_catalog'
  into v_security_ok
  from pg_proc p
  where p.oid=v_oid;

  if v_security_ok is not true then
    raise exception 'T3A_POSTFLIGHT_FUNCTION_SECURITY_MISMATCH';
  end if;

  select
    has_function_privilege('authenticated', v_oid, 'EXECUTE')
    and not has_function_privilege('anon', v_oid, 'EXECUTE')
    and not has_function_privilege('service_role', v_oid, 'EXECUTE')
    and not exists (
      select 1
      from pg_proc p
      cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) acl
      where p.oid = v_oid
        and acl.grantee = 0
        and acl.privilege_type = 'EXECUTE'
    )
  into v_acl_ok;

  if v_acl_ok is not true then
    raise exception 'T3A_POSTFLIGHT_FUNCTION_ACL_MISMATCH';
  end if;

  if has_table_privilege('authenticated', 'public.corretores', 'UPDATE')
     or not has_column_privilege('authenticated', 'public.corretores', 'ativo', 'UPDATE')
     or not has_column_privilege('authenticated', 'public.corretores', 'apto_para_receber', 'UPDATE')
     or has_column_privilege('authenticated', 'public.corretores', 'must_change_password', 'UPDATE')
  then
    raise exception 'T3A_POSTFLIGHT_CORRETORES_ACL_MISMATCH';
  end if;
end
$postflight$;

commit;
