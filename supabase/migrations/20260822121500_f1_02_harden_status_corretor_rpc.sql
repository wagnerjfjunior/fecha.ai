-- FECH.AI / F1-02 / T1
-- Status authority hardening for Pilot Production.
--
-- Product contract
--   root        -> ativo/apto on authorized target
--   admin_local -> same company, ativo/apto; admin authority does NOT require is_gestor=true
--   gestor      -> ordinary brokers in own ACTIVE managed teams, apto only
--   corretor / no auth / inactive actor -> deny
--   root source -> ONLY public.admins(role='admin_global', ativo=true)
--
-- Temporary compatibility window
--   authenticated direct UPDATE remains only on:
--     ativo, apto_para_receber, must_change_password
--   and every user-scoped transition is re-authorized in BEFORE triggers
--   using auth.uid(), regardless of SECURITY DEFINER effective current_user.
--
-- GitHub versioning != Supabase application.
-- Production application requires a separate Product Authority gate.

-- =============================================================================
-- 1. EXACT PRE-FLIGHT
-- =============================================================================
do $preflight$
declare
  v_postgres_oid oid := pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid := pg_catalog.to_regrole('authenticated');
  v_anon_oid oid := pg_catalog.to_regrole('anon');
  v_service_role_oid oid := pg_catalog.to_regrole('service_role');

  v_status_oid oid;
  v_mark_password_oid oid;
  v_role_rpc_oid oid;
  v_time_rpc_oid oid;
  v_redef_password_oid oid;

  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_acl text;
  v_md5 text;
  v_table_acl_md5 text;
  v_policy_md5 text;

  v_audit_trigger_oid oid;
  v_audit_fn_oid oid;
  v_audit_trigger_enabled "char";
  v_audit_trigger_def text;
begin
  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null then
    raise exception 'T1_PREFLIGHT_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null
     or pg_catalog.to_regclass('public.admins') is null then
    raise exception 'T1_PREFLIGHT_REQUIRED_TABLE_MISSING';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null then
    raise exception 'T1_PREFLIGHT_AUTH_UID_MISSING';
  end if;

  v_status_oid := pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  if v_status_oid is null then
    raise exception 'T1_PREFLIGHT_STATUS_FUNCTION_MISSING';
  end if;

  select p.proowner,
         p.prosecdef,
         p.proconfig,
         p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
    into strict v_owner, v_definer, v_config, v_acl, v_md5
  from pg_catalog.pg_proc as p
  where p.oid=v_status_oid;

  if v_owner is distinct from v_postgres_oid
     or v_definer is distinct from true
     or not coalesce(v_config @> array['search_path=public']::text[],false)
     or v_acl is distinct from '{postgres=X/postgres,service_role=X/postgres}'
     or v_md5 is distinct from 'ef89d686ebb3230ae4bef1b71d4860fd' then
    raise exception 'T1_PREFLIGHT_STATUS_RPC_DRIFT';
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
      and a.attnum>0
      and not a.attisdropped
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
          'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'
        ) is not null
     or pg_catalog.to_regprocedure(
          'public.t1_guard_corretores_authority_update()'
        ) is not null
     or pg_catalog.to_regprocedure(
          'public.t1_guard_corretores_direct_compat_update()'
        ) is not null
     or exists (
       select 1
       from pg_catalog.pg_trigger as tg
       where tg.tgrelid='public.corretores'::regclass
         and tg.tgname in (
           'trg_t1_guard_corretores_authority_update',
           'trg_t1_guard_corretores_direct_compat_update'
         )
         and not tg.tgisinternal
     ) then
    raise exception 'T1_PREFLIGHT_T1_OBJECT_ALREADY_EXISTS';
  end if;

  if pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','DELETE') then
    raise exception 'T1_PREFLIGHT_ADMINS_AUTHENTICATED_DML_PRESENT';
  end if;

  if not exists (
    select 1
    from public.admins as a
    where a.ativo is true and a.role='admin_global'
  ) then
    raise exception 'T1_PREFLIGHT_ACTIVE_ROOT_MISSING';
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
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='gestor_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='role' and data_type='text') then
    raise exception 'T1_PREFLIGHT_REQUIRED_COLUMN_DRIFT';
  end if;

  if exists (
    select 1
    from public.corretores as c
    where c.role in ('corretor','gestor','admin_local')
      and (
        coalesce(c.is_admin_local,false) is distinct from (c.role='admin_local')
        or (c.role='corretor' and coalesce(c.is_gestor,false) is true)
        or (c.role='gestor' and coalesce(c.is_gestor,false) is distinct from true)
      )
  ) then
    raise exception 'T1_PREFLIGHT_ROLE_FLAG_INCONSISTENCY';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_index as i
    join pg_catalog.pg_class as t on t.oid=i.indrelid
    join pg_catalog.pg_namespace as n on n.oid=t.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=t.oid
     and a.attname='user_id'
     and a.attnum>0
     and not a.attisdropped
    where n.nspname='public'
      and t.relname='corretores'
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
      on a.attrelid=t.oid
     and a.attname='user_id'
     and a.attnum>0
     and not a.attisdropped
    where n.nspname='public'
      and t.relname='admins'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T1_PREFLIGHT_ADMINS_USER_ID_UNIQUE_MISSING';
  end if;

  select tg.oid, tg.tgenabled, tg.tgfoid, pg_catalog.pg_get_triggerdef(tg.oid,true)
    into strict v_audit_trigger_oid,
                v_audit_trigger_enabled,
                v_audit_fn_oid,
                v_audit_trigger_def
  from pg_catalog.pg_trigger as tg
  where tg.tgrelid='public.corretores'::regclass
    and tg.tgname='trg_audit_trail_corretores_critical_update'
    and not tg.tgisinternal;

  if v_audit_trigger_enabled is distinct from 'O'
     or v_audit_trigger_def is distinct from
       'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()' then
    raise exception 'T1_PREFLIGHT_CRITICAL_AUDIT_TRIGGER_DRIFT';
  end if;

  select p.proowner,
         p.prosecdef,
         p.proconfig,
         p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
    into strict v_owner, v_definer, v_config, v_acl, v_md5
  from pg_catalog.pg_proc as p
  where p.oid=v_audit_fn_oid;

  if v_owner is distinct from v_postgres_oid
     or v_definer is distinct from true
     or not coalesce(v_config @> array['search_path=public']::text[],false)
     or v_acl is distinct from
       '{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}'
     or v_md5 is distinct from '3fdaca39d55f348ca36f796023f3260b' then
    raise exception 'T1_PREFLIGHT_CRITICAL_AUDIT_FUNCTION_DRIFT';
  end if;

  v_role_rpc_oid := pg_catalog.to_regprocedure(
    'public.alterar_role_corretor(uuid,text)'
  );
  v_time_rpc_oid := pg_catalog.to_regprocedure(
    'public.atualizar_time_corretor(uuid,uuid)'
  );
  v_mark_password_oid := pg_catalog.to_regprocedure(
    'public.marcar_senha_inicial_definida()'
  );
  v_redef_password_oid := pg_catalog.to_regprocedure(
    'public.redefinir_senha_corretor(uuid,text)'
  );

  if v_role_rpc_oid is null
     or v_time_rpc_oid is null
     or v_mark_password_oid is null
     or v_redef_password_oid is null then
    raise exception 'T1_PREFLIGHT_REQUIRED_LEGACY_RPC_MISSING';
  end if;

  if pg_catalog.md5(pg_catalog.pg_get_functiondef(v_role_rpc_oid))
       is distinct from 'edde7ac084d416171a334d783cdcad3e'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(v_time_rpc_oid))
       is distinct from '74965d3c682a3ae4a3c69bf6a7524b93'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(v_mark_password_oid))
       is distinct from '2a7b28d4bb6342a99d075c4d3c49af4d'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(v_redef_password_oid))
       is distinct from '2f1ff707c6ea94e0abf4ede0f2ec3835' then
    raise exception 'T1_PREFLIGHT_REQUIRED_LEGACY_RPC_DRIFT';
  end if;

  if not pg_catalog.has_function_privilege(
       v_authenticated_oid,v_role_rpc_oid,'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       v_authenticated_oid,v_time_rpc_oid,'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       v_authenticated_oid,v_mark_password_oid,'EXECUTE'
     )
     or pg_catalog.has_function_privilege(
       v_authenticated_oid,v_redef_password_oid,'EXECUTE'
     ) then
    raise exception 'T1_PREFLIGHT_LEGACY_RPC_EXECUTE_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.prosecdef
      and pg_catalog.has_function_privilege(
            v_authenticated_oid,p.oid,'EXECUTE'
          )
      and lower(p.prosrc) ~ 'update[[:space:]]+(public\.)?corretores'
      and lower(p.prosrc) like '%must_change_password%'
      and p.oid <> v_mark_password_oid
  ) then
    raise exception 'T1_PREFLIGHT_UNEXPECTED_AUTH_PASSWORD_WRITER';
  end if;
end;
$preflight$;

-- =============================================================================
-- 2. STRICT ROOT HELPER
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
-- 3. STRICT RLS PREFILTER
-- =============================================================================
create function public.t1_can_update_corretor_row_strict(
  p_target_empresa_id uuid,
  p_target_time_id uuid,
  p_target_role text,
  p_target_is_admin_local boolean,
  p_target_is_gestor boolean
)
returns boolean
language plpgsql
stable
security definer
set search_path=pg_catalog
as $fn$
declare
  v_uid uuid:=auth.uid();
  v_actor_id uuid;
  v_actor_empresa uuid;
  v_actor_role text;
  v_actor_active boolean;
  v_actor_admin boolean;
  v_actor_gestor boolean;
begin
  if v_uid is null then
    return false;
  end if;

  if exists (
    select 1
    from public.admins as a
    where a.user_id=v_uid
      and a.ativo is true
      and a.role='admin_global'
  ) then
    return true;
  end if;

  begin
    select c.id,
           c.empresa_id,
           c.role,
           c.ativo,
           coalesce(c.is_admin_local,false),
           coalesce(c.is_gestor,false)
      into strict v_actor_id,
                  v_actor_empresa,
                  v_actor_role,
                  v_actor_active,
                  v_actor_admin,
                  v_actor_gestor
    from public.corretores as c
    where c.user_id=v_uid;
  exception
    when no_data_found or too_many_rows then
      return false;
  end;

  if v_actor_active is distinct from true then
    return false;
  end if;

  if v_actor_role='admin_local'
     and v_actor_admin is true
     and v_actor_empresa is not null
     and p_target_empresa_id=v_actor_empresa then
    return true;
  end if;

  if v_actor_role='gestor'
     and v_actor_gestor is true
     and v_actor_admin is false
     and v_actor_empresa is not null
     and p_target_empresa_id=v_actor_empresa
     and p_target_role='corretor'
     and coalesce(p_target_is_admin_local,false) is false
     and coalesce(p_target_is_gestor,false) is false
     and p_target_time_id is not null
     and exists (
       select 1
       from public.times as t
       where t.id=p_target_time_id
         and t.empresa_id=v_actor_empresa
         and t.gestor_id=v_actor_id
         and t.ativo is true
     ) then
    return true;
  end if;

  return false;
end;
$fn$;

alter function public.t1_can_update_corretor_row_strict(
  uuid,uuid,text,boolean,boolean
) owner to postgres;
revoke all on function public.t1_can_update_corretor_row_strict(
  uuid,uuid,text,boolean,boolean
) from public;
revoke all on function public.t1_can_update_corretor_row_strict(
  uuid,uuid,text,boolean,boolean
) from anon;
revoke all on function public.t1_can_update_corretor_row_strict(
  uuid,uuid,text,boolean,boolean
) from service_role;
grant execute on function public.t1_can_update_corretor_row_strict(
  uuid,uuid,text,boolean,boolean
) to authenticated;

-- =============================================================================
-- 4. AUTHORITY UPDATE GUARD
-- =============================================================================
create function public.t1_guard_corretores_authority_update()
returns trigger
language plpgsql
security invoker
set search_path=pg_catalog
as $fn$
declare
  v_uid uuid:=auth.uid();
  v_actor_id uuid;
  v_actor_empresa uuid;
  v_actor_role text;
  v_actor_active boolean;
  v_actor_admin boolean;
  v_actor_gestor boolean;
  v_root boolean:=false;
  v_authority_changed boolean;
  v_protected_side_effect boolean;
begin
  v_authority_changed :=
       new.role is distinct from old.role
    or new.is_admin_local is distinct from old.is_admin_local
    or new.is_gestor is distinct from old.is_gestor
    or new.empresa_id is distinct from old.empresa_id
    or new.time_id is distinct from old.time_id
    or new.user_id is distinct from old.user_id;

  v_protected_side_effect :=
       new.ativo is distinct from old.ativo
    or new.apto_para_receber is distinct from old.apto_para_receber
    or new.must_change_password is distinct from old.must_change_password;

  if not v_authority_changed and not v_protected_side_effect then
    return new;
  end if;

  if v_uid is null then
    if current_user in ('postgres','service_role') then
      return new;
    end if;
    raise exception using errcode='42501',message='AUTH_REQUIRED';
  end if;

  perform 1
  from public.admins as a
  where a.user_id=v_uid
    and a.ativo is true
    and a.role='admin_global'
  for share;
  if found then v_root:=true; end if;

  begin
    select c.id,
           c.empresa_id,
           c.role,
           c.ativo,
           coalesce(c.is_admin_local,false),
           coalesce(c.is_gestor,false)
      into strict v_actor_id,
                  v_actor_empresa,
                  v_actor_role,
                  v_actor_active,
                  v_actor_admin,
                  v_actor_gestor
    from public.corretores as c
    where c.user_id=v_uid
    for share;
  exception
    when no_data_found then
      if not v_root then
        raise exception using errcode='42501',message='ACTOR_PROFILE_NOT_FOUND';
      end if;
      v_actor_id:=null;
      v_actor_empresa:=null;
      v_actor_role:=null;
      v_actor_active:=null;
      v_actor_admin:=false;
      v_actor_gestor:=false;
    when too_many_rows then
      raise exception using errcode='21000',message='ACTOR_PROFILE_AMBIGUOUS';
  end;

  if v_actor_id is not null and v_actor_active is distinct from true then
    raise exception using errcode='42501',message='PROFILE_INACTIVE';
  end if;

  if v_authority_changed and old.user_id=v_uid then
    raise exception using errcode='42501',message='SELF_AUTHORITY_CHANGE_DENIED';
  end if;

  if new.user_id is distinct from old.user_id
     or new.empresa_id is distinct from old.empresa_id then
    raise exception using
      errcode='42501',message='IDENTITY_OR_TENANT_CHANGE_DENIED';
  end if;

  if new.role is distinct from old.role
     or new.is_admin_local is distinct from old.is_admin_local
     or new.is_gestor is distinct from old.is_gestor then

    if new.role not in ('corretor','gestor','admin_local')
       or coalesce(new.is_admin_local,false)
          is distinct from (new.role='admin_local')
       or (new.role='corretor' and coalesce(new.is_gestor,false) is true)
       or (new.role='gestor' and coalesce(new.is_gestor,false) is distinct from true) then
      raise exception using
        errcode='42501',message='ROLE_FLAG_TRANSITION_INVALID';
    end if;

    if v_root then
      null;
    elsif v_actor_role='admin_local'
          and v_actor_admin is true
          and v_actor_empresa is not null
          and old.empresa_id=v_actor_empresa
          and old.role is distinct from 'admin_local' then
      null;
    else
      raise exception using errcode='42501',message='ROLE_CHANGE_DENIED';
    end if;
  end if;

  if new.time_id is distinct from old.time_id then
    if new.time_id is not null and not exists (
      select 1
      from public.times as t
      where t.id=new.time_id
        and t.empresa_id=new.empresa_id
    ) then
      raise exception using errcode='42501',message='TARGET_TEAM_INVALID';
    end if;

    if v_root then
      null;
    elsif v_actor_role='admin_local'
          and v_actor_admin is true
          and v_actor_empresa is not null
          and old.empresa_id=v_actor_empresa then
      null;
    elsif v_actor_role='gestor'
          and v_actor_gestor is true
          and v_actor_admin is false
          and v_actor_empresa is not null
          and old.empresa_id=v_actor_empresa
          and old.role='corretor'
          and coalesce(old.is_admin_local,false) is false
          and coalesce(old.is_gestor,false) is false
          and old.time_id is null
          and new.time_id is not null then

      perform 1
      from public.times as t
      where t.id=new.time_id
        and t.empresa_id=v_actor_empresa
        and t.gestor_id=v_actor_id
        and t.ativo is true
      for share;

      if not found then
        raise exception using errcode='42501',message='TEAM_CHANGE_DENIED';
      end if;
    else
      raise exception using errcode='42501',message='TEAM_CHANGE_DENIED';
    end if;
  end if;

  if not v_authority_changed and v_protected_side_effect then
    if v_root then
      return new;
    end if;

    if v_actor_role='admin_local'
       and v_actor_admin is true
       and v_actor_empresa is not null
       and old.empresa_id=v_actor_empresa
       and old.user_id is distinct from v_uid then
      return new;
    end if;

    raise exception using
      errcode='42501',message='PROTECTED_SIDE_EFFECT_DENIED';
  end if;

  return new;
end;
$fn$;

alter function public.t1_guard_corretores_authority_update()
  owner to postgres;
revoke all on function public.t1_guard_corretores_authority_update()
  from public;
revoke all on function public.t1_guard_corretores_authority_update()
  from anon;
revoke all on function public.t1_guard_corretores_authority_update()
  from authenticated;
revoke all on function public.t1_guard_corretores_authority_update()
  from service_role;

create trigger trg_t1_guard_corretores_authority_update
before update of role,is_admin_local,is_gestor,empresa_id,time_id,user_id
on public.corretores
for each row
execute function public.t1_guard_corretores_authority_update();

-- =============================================================================
-- 5. NARROW AUTHENTICATED DIRECT UPDATE + STRICT UPDATE POLICY
-- =============================================================================
revoke update on table public.corretores from authenticated;
grant update (ativo,apto_para_receber,must_change_password)
  on public.corretores to authenticated;

drop policy corretores_update on public.corretores;
create policy corretores_update
on public.corretores
for update
using (
  public.t1_can_update_corretor_row_strict(
    empresa_id,time_id,role,is_admin_local,is_gestor
  )
)
with check (
  public.t1_can_update_corretor_row_strict(
    empresa_id,time_id,role,is_admin_local,is_gestor
  )
);

-- =============================================================================
-- 6. TEMPORARY DIRECT-COMPATIBILITY GUARD
-- =============================================================================
create function public.t1_guard_corretores_direct_compat_update()
returns trigger
language plpgsql
security invoker
set search_path=pg_catalog
as $fn$
declare
  v_uid uuid:=auth.uid();
  v_actor_id uuid;
  v_empresa_id uuid;
  v_role text;
  v_ativo boolean;
  v_admin boolean;
  v_gestor boolean;
  v_root boolean:=false;
begin
  if new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber
     and new.must_change_password is not distinct from old.must_change_password then
    return new;
  end if;

  if v_uid is null then
    if current_user in ('postgres','service_role') then
      return new;
    end if;
    raise exception using errcode='42501',message='AUTH_REQUIRED';
  end if;

  perform 1
  from public.admins as a
  where a.user_id=v_uid
    and a.ativo is true
    and a.role='admin_global'
  for share;
  if found then v_root:=true; end if;

  begin
    select c.id,
           c.empresa_id,
           c.role,
           c.ativo,
           coalesce(c.is_admin_local,false),
           coalesce(c.is_gestor,false)
      into strict v_actor_id,
                  v_empresa_id,
                  v_role,
                  v_ativo,
                  v_admin,
                  v_gestor
    from public.corretores as c
    where c.user_id=v_uid
    for share;
  exception
    when no_data_found then
      if not v_root then
        raise exception using errcode='42501',message='ACTOR_PROFILE_NOT_FOUND';
      end if;
      v_actor_id:=null;
      v_empresa_id:=null;
      v_role:=null;
      v_ativo:=null;
      v_admin:=false;
      v_gestor:=false;
    when too_many_rows then
      raise exception using errcode='21000',message='ACTOR_PROFILE_AMBIGUOUS';
  end;

  if v_actor_id is not null and v_ativo is distinct from true then
    raise exception using errcode='42501',message='PROFILE_INACTIVE';
  end if;

  if old.user_id=v_uid
     and current_user='postgres'
     and old.must_change_password is true
     and new.must_change_password is false
     and new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber then
    return new;
  end if;

  if old.user_id=v_uid and new.ativo is distinct from old.ativo then
    raise exception using errcode='42501',message='SELF_ACTIVE_CHANGE_DENIED';
  end if;

  if old.user_id=v_uid
     and new.must_change_password is distinct from old.must_change_password then
    raise exception using
      errcode='42501',message='SELF_PASSWORD_STATE_CHANGE_DENIED';
  end if;

  if v_root then
    return new;
  end if;

  if v_role='admin_local'
     and v_admin is true
     and v_empresa_id is not null
     and old.empresa_id=v_empresa_id then
    return new;
  end if;

  if v_role='gestor'
     and v_gestor is true
     and v_admin is false then

    if new.ativo is distinct from old.ativo then
      raise exception using
        errcode='42501',message='ACTIVE_CHANGE_DENIED_FOR_MANAGER';
    end if;

    if new.must_change_password is distinct from old.must_change_password then
      raise exception using
        errcode='42501',message='PASSWORD_STATE_CHANGE_DENIED_FOR_MANAGER';
    end if;

    if v_empresa_id is null
       or old.empresa_id is distinct from v_empresa_id
       or old.role is distinct from 'corretor'
       or coalesce(old.is_admin_local,false) is true
       or coalesce(old.is_gestor,false) is true
       or old.time_id is null then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    perform 1
    from public.times as t
    where t.id=old.time_id
      and t.empresa_id=v_empresa_id
      and t.gestor_id=v_actor_id
      and t.ativo is true
    for share;

    if not found then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    return new;
  end if;

  raise exception using errcode='42501',message='ACCESS_DENIED';
end;
$fn$;

alter function public.t1_guard_corretores_direct_compat_update()
  owner to postgres;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from public;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from anon;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from authenticated;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from service_role;

create trigger trg_t1_guard_corretores_direct_compat_update
before update of ativo,apto_para_receber,must_change_password
on public.corretores
for each row
execute function public.t1_guard_corretores_direct_compat_update();

-- =============================================================================
-- 7. HARDENED STATUS RPC
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
  v_uid uuid:=auth.uid();
  v_actor_id uuid;
  v_empresa_id uuid;
  v_role text;
  v_ativo boolean;
  v_admin boolean;
  v_gestor boolean;
  v_root boolean:=false;
  v_profile_found boolean:=false;
  v_authorized_time_id uuid;
  v_updated_id uuid;
  v_updated_ativo boolean;
  v_updated_apto boolean;
begin
  if v_uid is null then
    return jsonb_build_object(
      'ok',false,'code','AUTH_REQUIRED','error','Usuário não autenticado'
    );
  end if;

  perform 1
  from public.admins as a
  where a.user_id=v_uid
    and a.ativo is true
    and a.role='admin_global'
  for share;
  if found then v_root:=true; end if;

  begin
    select c.id,
           c.empresa_id,
           c.role,
           c.ativo,
           coalesce(c.is_admin_local,false),
           coalesce(c.is_gestor,false)
      into strict v_actor_id,
                  v_empresa_id,
                  v_role,
                  v_ativo,
                  v_admin,
                  v_gestor
    from public.corretores as c
    where c.user_id=v_uid
    for share;
    v_profile_found:=true;
  exception
    when no_data_found then
      v_profile_found:=false;
    when too_many_rows then
      return jsonb_build_object(
        'ok',false,
        'code','ACTOR_PROFILE_AMBIGUOUS',
        'error','Perfil autenticado ambíguo'
      );
  end;

  if v_profile_found and v_ativo is distinct from true then
    return jsonb_build_object(
      'ok',false,'code','PROFILE_INACTIVE','error','Perfil autenticado inativo'
    );
  end if;

  if not v_root and not v_profile_found then
    return jsonb_build_object(
      'ok',false,
      'code','ACTOR_PROFILE_NOT_FOUND',
      'error','Perfil autenticado não encontrado'
    );
  end if;

  if p_ativo is null and p_apto_para_receber is null then
    return jsonb_build_object(
      'ok',false,
      'code','NO_CHANGE_REQUESTED',
      'error','Nenhuma alteração solicitada'
    );
  end if;

  if v_root then
    update public.corretores as target
       set ativo=coalesce(p_ativo,target.ativo),
           apto_para_receber=coalesce(
             p_apto_para_receber,target.apto_para_receber
           )
     where target.id=p_corretor_id
     returning target.id,target.ativo,target.apto_para_receber
      into v_updated_id,v_updated_ativo,v_updated_apto;

  elsif v_role='admin_local'
        and v_admin is true then

    update public.corretores as target
       set ativo=coalesce(p_ativo,target.ativo),
           apto_para_receber=coalesce(
             p_apto_para_receber,target.apto_para_receber
           )
     where target.id=p_corretor_id
       and v_empresa_id is not null
       and target.empresa_id=v_empresa_id
     returning target.id,target.ativo,target.apto_para_receber
      into v_updated_id,v_updated_ativo,v_updated_apto;

  elsif v_role='gestor'
        and v_gestor is true
        and v_admin is false then

    if p_ativo is not null then
      return jsonb_build_object(
        'ok',false,
        'code','ACTIVE_CHANGE_DENIED_FOR_MANAGER',
        'error','Gestor não pode alterar o estado ativo do corretor'
      );
    end if;

    select t.id
      into v_authorized_time_id
    from public.times as t
    join public.corretores as target
      on target.time_id=t.id
    where target.id=p_corretor_id
      and v_empresa_id is not null
      and target.empresa_id=v_empresa_id
      and target.role='corretor'
      and coalesce(target.is_admin_local,false) is false
      and coalesce(target.is_gestor,false) is false
      and t.empresa_id=v_empresa_id
      and t.gestor_id=v_actor_id
      and t.ativo is true
    for share of t;

    if v_authorized_time_id is null then
      return jsonb_build_object(
        'ok',false,
        'code','TARGET_NOT_AUTHORIZED',
        'error','Corretor não encontrado ou não autorizado'
      );
    end if;

    update public.corretores as target
       set apto_para_receber=coalesce(
         p_apto_para_receber,target.apto_para_receber
       )
     where target.id=p_corretor_id
       and target.empresa_id=v_empresa_id
       and target.role='corretor'
       and coalesce(target.is_admin_local,false) is false
       and coalesce(target.is_gestor,false) is false
       and target.time_id=v_authorized_time_id
       and exists (
         select 1
         from public.times as t
         where t.id=v_authorized_time_id
           and t.empresa_id=v_empresa_id
           and t.gestor_id=v_actor_id
           and t.ativo is true
       )
     returning target.id,target.ativo,target.apto_para_receber
      into v_updated_id,v_updated_ativo,v_updated_apto;

  else
    return jsonb_build_object(
      'ok',false,
      'code','ACCESS_DENIED',
      'error','Sem permissão para alterar status de corretor'
    );
  end if;

  if v_updated_id is null then
    return jsonb_build_object(
      'ok',false,
      'code','TARGET_NOT_AUTHORIZED',
      'error','Corretor não encontrado ou não autorizado'
    );
  end if;

  return jsonb_build_object(
    'ok',true,
    'corretor_id',v_updated_id,
    'ativo',v_updated_ativo,
    'apto_para_receber',v_updated_apto
  );
end;
$fn$;

alter function public.atualizar_status_corretor(uuid,boolean,boolean)
  owner to postgres;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from public;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from anon;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from service_role;
grant execute on function public.atualizar_status_corretor(uuid,boolean,boolean)
  to authenticated;

-- =============================================================================
-- 8. SELF-FINGERPRINT THE APPLIED T1 SURFACE FOR FAIL-CLOSED ROLLBACK
-- =============================================================================
do $fingerprint$
declare
  r record;
  v_hash text;
begin
  for r in
    select p.oid,
           n.nspname,
           p.proname,
           pg_catalog.pg_get_function_identity_arguments(p.oid) as identity_args
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid=p.pronamespace
    where p.oid in (
      'public.atualizar_status_corretor(uuid,boolean,boolean)'::regprocedure,
      'public.t1_is_root_strict()'::regprocedure,
      'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'::regprocedure,
      'public.t1_guard_corretores_authority_update()'::regprocedure,
      'public.t1_guard_corretores_direct_compat_update()'::regprocedure
    )
  loop
    v_hash:=pg_catalog.md5(pg_catalog.pg_get_functiondef(r.oid));
    execute pg_catalog.format(
      'comment on function %I.%I(%s) is %L',
      r.nspname,
      r.proname,
      r.identity_args,
      'F1-02-T1-v3|'||v_hash
    );
  end loop;

  select pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))
    into strict v_hash
  from pg_catalog.pg_trigger as tg
  where tg.tgrelid='public.corretores'::regclass
    and tg.tgname='trg_t1_guard_corretores_authority_update'
    and not tg.tgisinternal;

  execute pg_catalog.format(
    'comment on trigger %I on public.corretores is %L',
    'trg_t1_guard_corretores_authority_update',
    'F1-02-T1-v3|'||v_hash
  );

  select pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))
    into strict v_hash
  from pg_catalog.pg_trigger as tg
  where tg.tgrelid='public.corretores'::regclass
    and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
    and not tg.tgisinternal;

  execute pg_catalog.format(
    'comment on trigger %I on public.corretores is %L',
    'trg_t1_guard_corretores_direct_compat_update',
    'F1-02-T1-v3|'||v_hash
  );

  select pg_catalog.md5(
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
           || '|'
           || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
         )
    into strict v_hash
  from pg_catalog.pg_policy as p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update'
    and p.polcmd='w';

  execute pg_catalog.format(
    'comment on policy %I on public.corretores is %L',
    'corretores_update',
    'F1-02-T1-v3|'||v_hash
  );
end;
$fingerprint$;

-- =============================================================================
-- 9. POST-FLIGHT
-- =============================================================================
do $postflight$
declare
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_status_oid oid:=pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  v_using text;
  v_check text;
  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_comment text;
begin
  if v_status_oid is null then
    raise exception 'T1_POSTFLIGHT_STATUS_MISSING';
  end if;

  select p.proowner,p.prosecdef,p.proconfig,
         pg_catalog.obj_description(p.oid,'pg_proc')
    into strict v_owner,v_definer,v_config,v_comment
  from pg_catalog.pg_proc as p
  where p.oid=v_status_oid;

  if v_owner is distinct from v_postgres_oid
     or v_definer is distinct from true
     or not coalesce(v_config @> array['search_path=pg_catalog']::text[],false)
     or v_comment not like 'F1-02-T1-v3|%' then
    raise exception 'T1_POSTFLIGHT_STATUS_SECURITY_OR_FINGERPRINT_INVALID';
  end if;

  if not pg_catalog.has_function_privilege(
       v_authenticated_oid,v_status_oid,'EXECUTE'
     )
     or pg_catalog.has_function_privilege(v_anon_oid,v_status_oid,'EXECUTE')
     or pg_catalog.has_function_privilege(
       v_service_role_oid,v_status_oid,'EXECUTE'
     ) then
    raise exception 'T1_POSTFLIGHT_STATUS_ACL_INVALID';
  end if;

  if pg_catalog.has_table_privilege(
    v_authenticated_oid,'public.corretores','UPDATE'
  ) then
    raise exception 'T1_POSTFLIGHT_BROAD_UPDATE_PRESENT';
  end if;

  if not pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','ativo','UPDATE'
     )
     or not pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','apto_para_receber','UPDATE'
     )
     or not pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','must_change_password','UPDATE'
     ) then
    raise exception 'T1_POSTFLIGHT_COMPAT_COLUMN_UPDATE_MISSING';
  end if;

  if exists (
    select 1
    from information_schema.column_privileges as cp
    where cp.table_schema='public'
      and cp.table_name='corretores'
      and cp.grantee='authenticated'
      and cp.privilege_type='UPDATE'
      and cp.column_name not in (
        'ativo','apto_para_receber','must_change_password'
      )
  ) then
    raise exception 'T1_POSTFLIGHT_UNEXPECTED_UPDATE_COLUMN';
  end if;

  select pg_catalog.pg_get_expr(p.polqual,p.polrelid),
         pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)
    into strict v_using,v_check
  from pg_catalog.pg_policy as p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update'
    and p.polcmd='w';

  if v_using is null
     or v_check is null
     or position('t1_can_update_corretor_row_strict' in v_using)=0
     or position('t1_can_update_corretor_row_strict' in v_check)=0
     or position('is_root(' in v_using)>0
     or position('is_admin_local(' in v_using)>0
     or position('is_gestor(' in v_using)>0
     or position('user_id = auth.uid()' in v_using)>0 then
    raise exception 'T1_POSTFLIGHT_UPDATE_POLICY_INVALID';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname in (
        'trg_t1_guard_corretores_authority_update',
        'trg_t1_guard_corretores_direct_compat_update'
      )
      and (tg.tgenabled is distinct from 'O' or tg.tgisinternal)
  ) then
    raise exception 'T1_POSTFLIGHT_T1_TRIGGER_DISABLED';
  end if;

  if (
    select count(*)
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname in (
        'trg_t1_guard_corretores_authority_update',
        'trg_t1_guard_corretores_direct_compat_update'
      )
      and not tg.tgisinternal
  ) <> 2 then
    raise exception 'T1_POSTFLIGHT_T1_TRIGGER_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    join pg_catalog.pg_proc as p on p.oid=tg.tgfoid
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_audit_trail_corretores_critical_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.pg_get_triggerdef(tg.oid,true)=
        'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()'
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '3fdaca39d55f348ca36f796023f3260b'
  ) then
    raise exception 'T1_POSTFLIGHT_CRITICAL_AUDIT_DRIFT';
  end if;
end;
$postflight$;

-- =============================================================================
-- 10. EXACT ROLLBACK RUNBOOK
-- =============================================================================
-- NOT EXECUTED BY THIS MIGRATION.
-- Separate Product Authority authorization is required.
--
-- do $rollback_preflight$
-- declare
--   r record;
--   v_expected text;
--   v_actual text;
--   v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
-- begin
--   for r in
--     select p.oid,
--            pg_catalog.obj_description(p.oid,'pg_proc') as marker
--     from pg_catalog.pg_proc as p
--     where p.oid in (
--       'public.atualizar_status_corretor(uuid,boolean,boolean)'::regprocedure,
--       'public.t1_is_root_strict()'::regprocedure,
--       'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'::regprocedure,
--       'public.t1_guard_corretores_authority_update()'::regprocedure,
--       'public.t1_guard_corretores_direct_compat_update()'::regprocedure
--     )
--   loop
--     if r.marker not like 'F1-02-T1-v3|%' then
--       raise exception 'T1_ROLLBACK_FUNCTION_MARKER_DRIFT';
--     end if;
--     v_expected:=split_part(r.marker,'|',2);
--     v_actual:=pg_catalog.md5(pg_catalog.pg_get_functiondef(r.oid));
--     if v_actual is distinct from v_expected then
--       raise exception 'T1_ROLLBACK_FUNCTION_BODY_DRIFT';
--     end if;
--   end loop;
--
--   for r in
--     select tg.oid,
--            pg_catalog.obj_description(tg.oid,'pg_trigger') as marker,
--            tg.tgenabled
--     from pg_catalog.pg_trigger as tg
--     where tg.tgrelid='public.corretores'::regclass
--       and tg.tgname in (
--         'trg_t1_guard_corretores_authority_update',
--         'trg_t1_guard_corretores_direct_compat_update'
--       )
--       and not tg.tgisinternal
--   loop
--     if r.tgenabled is distinct from 'O'
--        or r.marker not like 'F1-02-T1-v3|%' then
--       raise exception 'T1_ROLLBACK_TRIGGER_MARKER_DRIFT';
--     end if;
--     v_expected:=split_part(r.marker,'|',2);
--     v_actual:=pg_catalog.md5(pg_catalog.pg_get_triggerdef(r.oid,true));
--     if v_actual is distinct from v_expected then
--       raise exception 'T1_ROLLBACK_TRIGGER_DEF_DRIFT';
--     end if;
--   end loop;
--
--   select pg_catalog.obj_description(p.oid,'pg_policy'),
--          pg_catalog.md5(
--            coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
--            || '|'
--            || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
--          )
--     into strict v_expected,v_actual
--   from pg_catalog.pg_policy as p
--   where p.polrelid='public.corretores'::regclass
--     and p.polname='corretores_update'
--     and p.polcmd='w';
--
--   if v_expected not like 'F1-02-T1-v3|%'
--      or v_actual is distinct from split_part(v_expected,'|',2) then
--     raise exception 'T1_ROLLBACK_POLICY_DRIFT';
--   end if;
--
--   if pg_catalog.has_table_privilege(
--        v_authenticated_oid,'public.corretores','UPDATE'
--      )
--      or not pg_catalog.has_column_privilege(
--        v_authenticated_oid,'public.corretores','ativo','UPDATE'
--      )
--      or not pg_catalog.has_column_privilege(
--        v_authenticated_oid,'public.corretores','apto_para_receber','UPDATE'
--      )
--      or not pg_catalog.has_column_privilege(
--        v_authenticated_oid,'public.corretores','must_change_password','UPDATE'
--      )
--      or exists (
--        select 1
--        from information_schema.column_privileges as cp
--        where cp.table_schema='public'
--          and cp.table_name='corretores'
--          and cp.grantee='authenticated'
--          and cp.privilege_type='UPDATE'
--          and cp.column_name not in (
--            'ativo','apto_para_receber','must_change_password'
--          )
--      ) then
--     raise exception 'T1_ROLLBACK_GRANT_DRIFT';
--   end if;
--
--   if not exists (
--     select 1
--     from pg_catalog.pg_trigger as tg
--     join pg_catalog.pg_proc as p on p.oid=tg.tgfoid
--     where tg.tgrelid='public.corretores'::regclass
--       and tg.tgname='trg_audit_trail_corretores_critical_update'
--       and not tg.tgisinternal
--       and tg.tgenabled='O'
--       and pg_catalog.pg_get_triggerdef(tg.oid,true)=
--         'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()'
--       and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
--         '3fdaca39d55f348ca36f796023f3260b'
--   ) then
--     raise exception 'T1_ROLLBACK_AUDIT_DRIFT';
--   end if;
-- end;
-- $rollback_preflight$;
--
-- drop trigger trg_t1_guard_corretores_direct_compat_update
--   on public.corretores;
-- drop function public.t1_guard_corretores_direct_compat_update();
--
-- drop trigger trg_t1_guard_corretores_authority_update
--   on public.corretores;
-- drop function public.t1_guard_corretores_authority_update();
--
-- drop policy corretores_update on public.corretores;
-- create policy corretores_update
-- on public.corretores
-- for update
-- using (
--   public.is_root()
--   or (public.is_admin_local() and empresa_id=public.my_empresa_id())
--   or (public.is_gestor() and time_id=any(public.my_times_como_gestor()))
--   or (user_id=auth.uid())
-- );
--
-- revoke update (ativo,apto_para_receber,must_change_password)
--   on public.corretores from authenticated;
-- grant update on table public.corretores to authenticated;
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
--
-- alter function public.atualizar_status_corretor(uuid,boolean,boolean)
--   owner to postgres;
-- revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
--   from public;
-- revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
--   from anon;
-- revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
--   from authenticated;
-- grant execute on function public.atualizar_status_corretor(uuid,boolean,boolean)
--   to service_role;
-- comment on function public.atualizar_status_corretor(uuid,boolean,boolean)
--   is null;
--
-- drop function public.t1_can_update_corretor_row_strict(
--   uuid,uuid,text,boolean,boolean
-- );
-- drop function public.t1_is_root_strict();
--
-- do $rollback_postflight$
-- declare
--   v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
-- begin
--   if pg_catalog.md5(
--        pg_catalog.pg_get_functiondef(
--          'public.atualizar_status_corretor(uuid,boolean,boolean)'::regprocedure
--        )
--      ) is distinct from 'ef89d686ebb3230ae4bef1b71d4860fd'
--      or pg_catalog.has_function_privilege(
--        v_authenticated_oid,
--        'public.atualizar_status_corretor(uuid,boolean,boolean)'::regprocedure,
--        'EXECUTE'
--      )
--      or not pg_catalog.has_table_privilege(
--        v_authenticated_oid,'public.corretores','UPDATE'
--      )
--      or pg_catalog.to_regprocedure('public.t1_is_root_strict()') is not null
--      or pg_catalog.to_regprocedure(
--           'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'
--         ) is not null
--      or pg_catalog.to_regprocedure(
--           'public.t1_guard_corretores_authority_update()'
--         ) is not null
--      or pg_catalog.to_regprocedure(
--           'public.t1_guard_corretores_direct_compat_update()'
--         ) is not null then
--     raise exception 'T1_ROLLBACK_POSTFLIGHT_FAILED';
--   end if;
-- end;
-- $rollback_postflight$;
