-- FECH.AI / F1-02 / T1
-- Server-authoritative status command + minimum direct-DML integrity required
-- for that command to trust actor authority.
--
-- Product contract:
-- root       -> ativo/apto on authorized target
-- admin_local-> same company, ativo/apto
-- gestor     -> ordinary brokers in own ACTIVE managed teams, apto only
-- corretor / no auth / inactive actor -> deny
-- root source -> ONLY public.admins(role='admin_global', ativo=true)
--
-- Compatibility window:
-- authenticated direct UPDATE is NOT fully revoked yet. It is narrowed to the
-- three legacy fields still required before frontend/password cutovers:
-- ativo, apto_para_receber, must_change_password.
-- Authority-bearing columns are removed from authenticated direct DML and a
-- trigger prevents the legacy PATCH path from bypassing the same actor/tenant/
-- team/field restrictions.
--
-- GitHub versioning != Supabase application. Production application remains a
-- separate authorized gate.

-- =============================================================================
-- 1. EXACT PRE-FLIGHT
-- =============================================================================
do $preflight$
declare
  v_status_oid oid;
  v_owner_oid oid;
  v_postgres_oid oid;
  v_authenticated_oid oid;
  v_anon_oid oid;
  v_service_role_oid oid;
  v_function_md5 text;
  v_function_acl text;
  v_table_acl_md5 text;
  v_policy_md5 text;
  v_security_definer boolean;
  v_proconfig text[];
begin
  if pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null
     or pg_catalog.to_regclass('public.admins') is null then
    raise exception 'T1_PREFLIGHT_REQUIRED_TABLE_MISSING';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null then
    raise exception 'T1_PREFLIGHT_AUTH_UID_MISSING';
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

  v_status_oid := pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  if v_status_oid is null then
    raise exception 'T1_PREFLIGHT_STATUS_FUNCTION_MISSING';
  end if;

  select
    p.proowner,
    p.prosecdef,
    p.proconfig,
    pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
    p.proacl::text
  into strict
    v_owner_oid,
    v_security_definer,
    v_proconfig,
    v_function_md5,
    v_function_acl
  from pg_catalog.pg_proc as p
  where p.oid = v_status_oid;

  if v_owner_oid is distinct from v_postgres_oid then
    raise exception 'T1_PREFLIGHT_STATUS_OWNER_DRIFT';
  end if;
  if v_security_definer is distinct from true then
    raise exception 'T1_PREFLIGHT_STATUS_SECURITY_MODE_DRIFT';
  end if;
  if not coalesce(
    v_proconfig @> array['search_path=public']::text[], false
  ) then
    raise exception 'T1_PREFLIGHT_STATUS_SEARCH_PATH_DRIFT';
  end if;
  if v_function_md5 is distinct from 'ef89d686ebb3230ae4bef1b71d4860fd' then
    raise exception 'T1_PREFLIGHT_STATUS_BODY_DRIFT';
  end if;
  if v_function_acl is distinct from
     '{postgres=X/postgres,service_role=X/postgres}' then
    raise exception 'T1_PREFLIGHT_STATUS_ACL_DRIFT';
  end if;

  select pg_catalog.md5(coalesce(c.relacl::text,''))
    into strict v_table_acl_md5
  from pg_catalog.pg_class as c
  join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='corretores';

  if v_table_acl_md5 is distinct from 'afa3a93809a23f744356971cbc461855' then
    raise exception 'T1_PREFLIGHT_CORRETORES_TABLE_ACL_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
    v_authenticated_oid,'public.corretores','UPDATE'
  ) then
    raise exception 'T1_PREFLIGHT_AUTHENTICATED_TABLE_UPDATE_MISSING';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute as a
    cross join lateral pg_catalog.aclexplode(a.attacl) as acl
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0 and not a.attisdropped
      and acl.grantee=v_authenticated_oid
      and acl.privilege_type='UPDATE'
  ) then
    raise exception 'T1_PREFLIGHT_COLUMN_UPDATE_ACL_DRIFT';
  end if;

  select pg_catalog.md5(
    coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
    || '|'
    || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
  )
  into strict v_policy_md5
  from pg_catalog.pg_policy as p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update'
    and p.polcmd='w';

  if v_policy_md5 is distinct from 'a3b9b4a44e859728ca9c69f6e6b2a842' then
    raise exception 'T1_PREFLIGHT_UPDATE_POLICY_DRIFT';
  end if;

  if pg_catalog.to_regprocedure('public.t1_is_root_strict()') is not null
     or pg_catalog.to_regprocedure(
       'public.t1_guard_corretores_direct_compat_update()'
     ) is not null
     or exists (
       select 1 from pg_catalog.pg_trigger as tg
       where tg.tgrelid='public.corretores'::regclass
         and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
         and not tg.tgisinternal
     ) then
    raise exception 'T1_PREFLIGHT_T1_OBJECT_ALREADY_EXISTS';
  end if;

  if pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','DELETE') then
    raise exception 'T1_PREFLIGHT_ADMINS_AUTHENTICATED_DML_PRESENT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('corretores','times','admins')
      and (c.relrowsecurity is distinct from true
           or c.relforcerowsecurity is distinct from true)
  ) then
    raise exception 'T1_PREFLIGHT_RLS_DRIFT';
  end if;

  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='time_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='role' and data_type='text')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_admin_local' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_gestor' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='apto_para_receber' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='must_change_password' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='gestor_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='role' and data_type='text') then
    raise exception 'T1_PREFLIGHT_REQUIRED_COLUMN_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_index as i
    join pg_catalog.pg_class as t on t.oid=i.indrelid
    join pg_catalog.pg_namespace as n on n.oid=t.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=t.oid and a.attname='user_id'
      and a.attnum>0 and not a.attisdropped
    where n.nspname='public' and t.relname='corretores'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T1_PREFLIGHT_CORRETORES_USER_ID_UNIQUE_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_index as i
    join pg_catalog.pg_class as t on t.oid=i.indrelid
    join pg_catalog.pg_namespace as n on n.oid=t.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=t.oid and a.attname='user_id'
      and a.attnum>0 and not a.attisdropped
    where n.nspname='public' and t.relname='admins'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T1_PREFLIGHT_ADMINS_USER_ID_UNIQUE_MISSING';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_audit_trail_corretores_critical_update'
      and not tg.tgisinternal
  ) then
    raise exception 'T1_PREFLIGHT_CRITICAL_AUDIT_TRIGGER_MISSING';
  end if;
end;
$preflight$;

-- =============================================================================
-- 2. STRICT ROOT SOURCE USED BY T1 + LEGACY DIRECT COMPATIBILITY
-- =============================================================================
create function public.t1_is_root_strict()
returns boolean
language sql
stable
security definer
set search_path=pg_catalog
as $fn$
  select exists (
    select 1
    from public.admins as a
    where a.user_id=auth.uid()
      and a.ativo is true
      and a.role='admin_global'
  );
$fn$;

alter function public.t1_is_root_strict() owner to postgres;
revoke all on function public.t1_is_root_strict() from public;
revoke all on function public.t1_is_root_strict() from anon;
revoke all on function public.t1_is_root_strict() from service_role;
grant execute on function public.t1_is_root_strict() to authenticated;

-- =============================================================================
-- 3. NARROW AUTHENTICATED DIRECT UPDATE — NOT FINAL PR-03 REVOCATION
-- =============================================================================
revoke update on table public.corretores from authenticated;
grant update (ativo,apto_para_receber,must_change_password)
  on public.corretores to authenticated;

drop policy corretores_update on public.corretores;
create policy corretores_update
on public.corretores
for update
using (
  public.t1_is_root_strict()
  or (public.is_admin_local() and empresa_id=public.my_empresa_id())
  or (public.is_gestor() and time_id=any(public.my_times_como_gestor()))
)
with check (
  public.t1_is_root_strict()
  or (public.is_admin_local() and empresa_id=public.my_empresa_id())
  or (public.is_gestor() and time_id=any(public.my_times_como_gestor()))
);

create function public.t1_guard_corretores_direct_compat_update()
returns trigger
language plpgsql
security invoker
set search_path=pg_catalog
as $fn$
declare
  v_uid uuid;
  v_actor_id uuid;
  v_empresa_id uuid;
  v_role text;
  v_ativo boolean;
  v_admin boolean;
  v_gestor boolean;
  v_root boolean;
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber
     and new.must_change_password is not distinct from old.must_change_password then
    return new;
  end if;

  v_uid := auth.uid();
  if v_uid is null then
    raise exception using errcode='42501',message='AUTH_REQUIRED';
  end if;

  v_root := public.t1_is_root_strict();

  begin
    select c.id,c.empresa_id,c.role,c.ativo,
           coalesce(c.is_admin_local,false),coalesce(c.is_gestor,false)
      into strict v_actor_id,v_empresa_id,v_role,v_ativo,v_admin,v_gestor
    from public.corretores as c
    where c.user_id=v_uid;
  exception
    when no_data_found then
      if v_root then return new; end if;
      raise exception using errcode='42501',message='ACTOR_PROFILE_NOT_FOUND';
    when too_many_rows then
      raise exception using errcode='21000',message='ACTOR_PROFILE_AMBIGUOUS';
  end;

  if v_ativo is distinct from true then
    raise exception using errcode='42501',message='PROFILE_INACTIVE';
  end if;

  if old.user_id=v_uid and new.ativo is distinct from old.ativo then
    raise exception using errcode='42501',message='SELF_ACTIVE_CHANGE_DENIED';
  end if;
  if old.user_id=v_uid
     and new.must_change_password is distinct from old.must_change_password then
    raise exception using errcode='42501',message='SELF_PASSWORD_STATE_CHANGE_DENIED';
  end if;

  if v_root then
    return new;
  end if;

  if v_role='admin_local' and v_admin is true and v_gestor is false then
    if v_empresa_id is null or old.empresa_id is distinct from v_empresa_id then
      raise exception using errcode='42501',message='CROSS_TENANT_DENIED';
    end if;
    return new;
  end if;

  if v_role='gestor' and v_gestor is true and v_admin is false then
    if new.ativo is distinct from old.ativo then
      raise exception using errcode='42501',message='ACTIVE_CHANGE_DENIED_FOR_MANAGER';
    end if;

    if v_empresa_id is null
       or old.empresa_id is distinct from v_empresa_id
       or old.role is distinct from 'corretor'
       or coalesce(old.is_admin_local,false) is true
       or coalesce(old.is_gestor,false) is true
       or old.time_id is null then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    if not exists (
      select 1 from public.times as t
      where t.id=old.time_id
        and t.empresa_id=v_empresa_id
        and t.gestor_id=v_actor_id
        and t.ativo is true
    ) then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    return new;
  end if;

  raise exception using errcode='42501',message='ACCESS_DENIED';
end;
$fn$;

alter function public.t1_guard_corretores_direct_compat_update() owner to postgres;
revoke all on function public.t1_guard_corretores_direct_compat_update() from public;
revoke all on function public.t1_guard_corretores_direct_compat_update() from anon;
revoke all on function public.t1_guard_corretores_direct_compat_update() from authenticated;
revoke all on function public.t1_guard_corretores_direct_compat_update() from service_role;

create trigger trg_t1_guard_corretores_direct_compat_update
before update of ativo,apto_para_receber,must_change_password
on public.corretores
for each row execute function public.t1_guard_corretores_direct_compat_update();

-- =============================================================================
-- 4. HARDENED STATUS RPC
-- =============================================================================
create or replace function public.atualizar_status_corretor(
  p_corretor_id uuid,
  p_ativo boolean default null,
  p_apto_para_receber boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path=pg_catalog
as $fn$
declare
  v_uid uuid;
  v_actor_id uuid;
  v_empresa_id uuid;
  v_role text;
  v_ativo boolean;
  v_admin boolean;
  v_gestor boolean;
  v_root boolean:=false;
  v_profile_found boolean:=false;
  v_updated_id uuid;
  v_updated_ativo boolean;
  v_updated_apto boolean;
begin
  v_uid:=auth.uid();
  if v_uid is null then
    return jsonb_build_object('ok',false,'code','AUTH_REQUIRED','error','Usuário não autenticado');
  end if;

  perform 1
  from public.admins as a
  where a.user_id=v_uid and a.ativo is true and a.role='admin_global'
  for share;
  if found then v_root:=true; end if;

  begin
    select c.id,c.empresa_id,c.role,c.ativo,
           coalesce(c.is_admin_local,false),coalesce(c.is_gestor,false)
      into strict v_actor_id,v_empresa_id,v_role,v_ativo,v_admin,v_gestor
    from public.corretores as c
    where c.user_id=v_uid
    for share;
    v_profile_found:=true;
  exception
    when no_data_found then v_profile_found:=false;
    when too_many_rows then
      return jsonb_build_object('ok',false,'code','ACTOR_PROFILE_AMBIGUOUS','error','Perfil autenticado ambíguo');
  end;

  if v_profile_found and v_ativo is distinct from true then
    return jsonb_build_object('ok',false,'code','PROFILE_INACTIVE','error','Perfil autenticado inativo');
  end if;
  if not v_root and not v_profile_found then
    return jsonb_build_object('ok',false,'code','ACTOR_PROFILE_NOT_FOUND','error','Perfil autenticado não encontrado');
  end if;
  if p_ativo is null and p_apto_para_receber is null then
    return jsonb_build_object('ok',false,'code','NO_CHANGE_REQUESTED','error','Nenhuma alteração solicitada');
  end if;

  if v_root then
    update public.corretores as target
       set ativo=coalesce(p_ativo,target.ativo),
           apto_para_receber=coalesce(p_apto_para_receber,target.apto_para_receber)
     where target.id=p_corretor_id
     returning target.id,target.ativo,target.apto_para_receber
      into v_updated_id,v_updated_ativo,v_updated_apto;

  elsif v_role='admin_local' and v_admin is true and v_gestor is false then
    update public.corretores as target
       set ativo=coalesce(p_ativo,target.ativo),
           apto_para_receber=coalesce(p_apto_para_receber,target.apto_para_receber)
     where target.id=p_corretor_id
       and v_empresa_id is not null
       and target.empresa_id=v_empresa_id
     returning target.id,target.ativo,target.apto_para_receber
      into v_updated_id,v_updated_ativo,v_updated_apto;

  elsif v_role='gestor' and v_gestor is true and v_admin is false then
    if p_ativo is not null then
      return jsonb_build_object('ok',false,'code','ACTIVE_CHANGE_DENIED_FOR_MANAGER','error','Gestor não pode alterar o estado ativo do corretor');
    end if;

    update public.corretores as target
       set apto_para_receber=coalesce(p_apto_para_receber,target.apto_para_receber)
     where target.id=p_corretor_id
       and v_empresa_id is not null
       and target.empresa_id=v_empresa_id
       and target.role='corretor'
       and coalesce(target.is_admin_local,false) is false
       and coalesce(target.is_gestor,false) is false
       and target.time_id is not null
       and exists (
         select 1 from public.times as t
         where t.id=target.time_id
           and t.empresa_id=v_empresa_id
           and t.gestor_id=v_actor_id
           and t.ativo is true
       )
     returning target.id,target.ativo,target.apto_para_receber
      into v_updated_id,v_updated_ativo,v_updated_apto;

  else
    return jsonb_build_object('ok',false,'code','ACCESS_DENIED','error','Sem permissão para alterar status de corretor');
  end if;

  if v_updated_id is null then
    return jsonb_build_object('ok',false,'code','TARGET_NOT_AUTHORIZED','error','Corretor não encontrado ou não autorizado');
  end if;

  return jsonb_build_object(
    'ok',true,'corretor_id',v_updated_id,
    'ativo',v_updated_ativo,'apto_para_receber',v_updated_apto
  );
end;
$fn$;

alter function public.atualizar_status_corretor(uuid,boolean,boolean) owner to postgres;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean) from public;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean) from anon;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean) from service_role;
grant execute on function public.atualizar_status_corretor(uuid,boolean,boolean) to authenticated;

comment on function public.atualizar_status_corretor(uuid,boolean,boolean) is
  'F1-02 T1 strict status command: root only from active admins/admin_global; admin_local same tenant; gestor own active managed ordinary brokers, apto only.';

-- =============================================================================
-- 5. POST-FLIGHT
-- =============================================================================
do $postflight$
declare
  v_status_oid oid;
  v_root_oid oid;
  v_guard_oid oid;
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_using text;
  v_check text;
  v_owner oid;
  v_definer boolean;
  v_config text[];
begin
  v_status_oid:=pg_catalog.to_regprocedure('public.atualizar_status_corretor(uuid,boolean,boolean)');
  v_root_oid:=pg_catalog.to_regprocedure('public.t1_is_root_strict()');
  v_guard_oid:=pg_catalog.to_regprocedure('public.t1_guard_corretores_direct_compat_update()');
  if v_status_oid is null or v_root_oid is null or v_guard_oid is null then
    raise exception 'T1_POSTFLIGHT_REQUIRED_FUNCTION_MISSING';
  end if;

  select p.proowner,p.prosecdef,p.proconfig into strict v_owner,v_definer,v_config
  from pg_catalog.pg_proc as p where p.oid=v_status_oid;
  if v_owner is distinct from v_postgres_oid or v_definer is distinct from true
     or not coalesce(v_config @> array['search_path=pg_catalog']::text[],false) then
    raise exception 'T1_POSTFLIGHT_STATUS_SECURITY_CONTRACT_INVALID';
  end if;
  if not pg_catalog.has_function_privilege(v_authenticated_oid,v_status_oid,'EXECUTE')
     or pg_catalog.has_function_privilege(v_anon_oid,v_status_oid,'EXECUTE')
     or pg_catalog.has_function_privilege(v_service_role_oid,v_status_oid,'EXECUTE') then
    raise exception 'T1_POSTFLIGHT_STATUS_ACL_INVALID';
  end if;
  if exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))) as acl
    where p.oid=v_status_oid and acl.privilege_type='EXECUTE'
      and acl.grantee not in (p.proowner,v_authenticated_oid)
  ) then
    raise exception 'T1_POSTFLIGHT_STATUS_UNEXPECTED_EXECUTOR';
  end if;

  select p.proowner,p.prosecdef,p.proconfig into strict v_owner,v_definer,v_config
  from pg_catalog.pg_proc as p where p.oid=v_root_oid;
  if v_owner is distinct from v_postgres_oid or v_definer is distinct from true
     or not coalesce(v_config @> array['search_path=pg_catalog']::text[],false) then
    raise exception 'T1_POSTFLIGHT_ROOT_HELPER_SECURITY_INVALID';
  end if;
  if not pg_catalog.has_function_privilege(v_authenticated_oid,v_root_oid,'EXECUTE')
     or pg_catalog.has_function_privilege(v_anon_oid,v_root_oid,'EXECUTE')
     or pg_catalog.has_function_privilege(v_service_role_oid,v_root_oid,'EXECUTE') then
    raise exception 'T1_POSTFLIGHT_ROOT_HELPER_ACL_INVALID';
  end if;

  select p.proowner,p.prosecdef,p.proconfig into strict v_owner,v_definer,v_config
  from pg_catalog.pg_proc as p where p.oid=v_guard_oid;
  if v_owner is distinct from v_postgres_oid or v_definer is distinct from false
     or not coalesce(v_config @> array['search_path=pg_catalog']::text[],false) then
    raise exception 'T1_POSTFLIGHT_GUARD_SECURITY_INVALID';
  end if;

  if pg_catalog.has_table_privilege(v_authenticated_oid,'public.corretores','UPDATE') then
    raise exception 'T1_POSTFLIGHT_BROAD_UPDATE_PRESENT';
  end if;

  if not pg_catalog.has_column_privilege(v_authenticated_oid,'public.corretores','ativo','UPDATE')
     or not pg_catalog.has_column_privilege(v_authenticated_oid,'public.corretores','apto_para_receber','UPDATE')
     or not pg_catalog.has_column_privilege(v_authenticated_oid,'public.corretores','must_change_password','UPDATE') then
    raise exception 'T1_POSTFLIGHT_COMPAT_COLUMN_UPDATE_MISSING';
  end if;

  if exists (
    select 1 from information_schema.column_privileges as cp
    where cp.table_schema='public' and cp.table_name='corretores'
      and cp.grantee='authenticated' and cp.privilege_type='UPDATE'
      and cp.column_name not in ('ativo','apto_para_receber','must_change_password')
  ) then
    raise exception 'T1_POSTFLIGHT_UNEXPECTED_UPDATE_COLUMN';
  end if;

  select pg_catalog.pg_get_expr(p.polqual,p.polrelid),
         pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)
    into strict v_using,v_check
  from pg_catalog.pg_policy as p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update' and p.polcmd='w';

  if v_check is null
     or position('user_id = auth.uid()' in v_using)>0
     or position('user_id = auth.uid()' in v_check)>0
     or position('t1_is_root_strict' in v_using)=0
     or position('t1_is_root_strict' in v_check)=0 then
    raise exception 'T1_POSTFLIGHT_UPDATE_POLICY_INVALID';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
  ) then
    raise exception 'T1_POSTFLIGHT_GUARD_TRIGGER_MISSING';
  end if;

  if pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','DELETE') then
    raise exception 'T1_POSTFLIGHT_ADMINS_DML_PRESENT';
  end if;
end;
$postflight$;

-- =============================================================================
-- 6. EXACT ROLLBACK — separate production authorization required
-- =============================================================================
-- Before rollback, first prove the currently applied surface is still exactly
-- this T1 version. Do not overwrite later drift.
--
-- drop trigger if exists trg_t1_guard_corretores_direct_compat_update on public.corretores;
-- drop function if exists public.t1_guard_corretores_direct_compat_update();
-- drop policy if exists corretores_update on public.corretores;
-- create policy corretores_update
-- on public.corretores
-- for update
-- using (
--   public.is_root()
--   or (public.is_admin_local() and empresa_id=public.my_empresa_id())
--   or (public.is_gestor() and time_id=any(public.my_times_como_gestor()))
--   or (user_id=auth.uid())
-- );
-- revoke update (ativo,apto_para_receber,must_change_password) on public.corretores from authenticated;
-- grant update on table public.corretores to authenticated;
-- revoke all on function public.t1_is_root_strict() from authenticated;
-- drop function if exists public.t1_is_root_strict();
--
-- create or replace function public.atualizar_status_corretor(
--   p_corretor_id uuid,
--   p_ativo boolean default null,
--   p_apto_para_receber boolean default null
-- )
-- returns jsonb
-- language plpgsql
-- security definer
-- set search_path=public
-- as $rollback$
-- DECLARE
--   v_empresa_id uuid;
--   v_root boolean := false;
-- BEGIN
--   v_root := public.is_root();
--
--   SELECT empresa_id INTO v_empresa_id
--   FROM public.corretores
--   WHERE user_id = auth.uid()
--   LIMIT 1;
--
--   IF NOT (public.is_admin_local() OR public.is_gestor() OR v_root) THEN
--     RETURN jsonb_build_object('error', 'forbidden');
--   END IF;
--
--   IF NOT EXISTS (
--     SELECT 1
--     FROM public.corretores
--     WHERE id = p_corretor_id
--       AND (v_root OR empresa_id = v_empresa_id)
--   ) THEN
--     RETURN jsonb_build_object('error', 'not_found');
--   END IF;
--
--   UPDATE public.corretores
--   SET ativo = COALESCE(p_ativo, ativo),
--       apto_para_receber = COALESCE(p_apto_para_receber, apto_para_receber)
--   WHERE id = p_corretor_id
--     AND (v_root OR empresa_id = v_empresa_id);
--
--   RETURN jsonb_build_object('ok', true);
-- END;
-- $rollback$;
-- alter function public.atualizar_status_corretor(uuid,boolean,boolean) owner to postgres;
-- revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean) from public;
-- revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean) from anon;
-- revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean) from authenticated;
-- grant execute on function public.atualizar_status_corretor(uuid,boolean,boolean) to service_role;
