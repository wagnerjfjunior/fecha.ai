-- FECH.AI — T3A-v2 exact drift-aware rollback
--
-- Execute only under a separate rollback authority. Required order:
--   1. run this database rollback after its exact preflight passes;
--   2. keep the hardened Edge deployed: with the RPC absent it fails closed;
--   3. only then, under explicit Edge rollback authority, restore the reviewed
--      criar-usuario v17 baseline and verify its exact runtime fingerprint.
--
-- This rollback restores the exact pre-T3A T1 guard and compatibility grant.
-- It does not rewrite business rows or change any Auth password.

begin;

-- =============================================================================
-- 1. FAIL-CLOSED ROLLBACK PREFLIGHT — NO DESTRUCTIVE STEP BEFORE THIS PASSES
-- =============================================================================
do $rollback_preflight$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_t3_oid oid:=pg_catalog.to_regprocedure(
    'public.t3_prepare_admin_password_reset(uuid)'
  );
  v_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );
  v_update_columns text[];
begin
  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null
     or v_t3_oid is null
     or v_guard_oid is null
     or pg_catalog.to_regclass('public.admins') is null
     or pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null then
    raise exception 'T3A_ROLLBACK_REQUIRED_OBJECT_MISSING';
  end if;

  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'auth.uid()'::regprocedure
     )) is distinct from 'ea3b41bf29e2ad573067939329aa088e' then
    raise exception 'T3A_ROLLBACK_AUTH_UID_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
      and (c.relrowsecurity is distinct from true
           or c.relforcerowsecurity is distinct from true)
  ) then
    raise exception 'T3A_ROLLBACK_RLS_FORCE_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_t3_oid
      and p.proowner=v_postgres_oid
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '90c537dd4c2c7ae6fb7ae93373c4cc77'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v2|90c537dd4c2c7ae6fb7ae93373c4cc77|auth.uid actor; authority and tenant derived server-side; transaction-bound T1 interoperability'
      and pg_catalog.has_function_privilege(
            v_authenticated_oid,p.oid,'EXECUTE'
          )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.grantee=0 and acl.privilege_type='EXECUTE'
      )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and acl.grantee not in (v_postgres_oid,v_authenticated_oid)
      )
  ) then
    raise exception 'T3A_ROLLBACK_T3_FUNCTION_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_guard_oid
      and p.proowner=v_postgres_oid
      and p.prosecdef is false
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        'f2cbf4762b5f5b2d6c6eb56fcf0edc2b'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v2|f2cbf4762b5f5b2d6c6eb56fcf0edc2b|pre_t3a=99477024e337de5645dd042a30f8cf78'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.grantee=0 and acl.privilege_type='EXECUTE'
      )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and acl.grantee<>v_postgres_oid
      )
  ) then
    raise exception 'T3A_ROLLBACK_T1_DIRECT_GUARD_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid='public.t1_guard_corretores_authority_update()'::regprocedure
      and p.proowner=v_postgres_oid
      and p.prosecdef is false
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '5e69ae5cb6717f634d758cfd5c1cd7a6'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'F1-02-T1-v3|5e69ae5cb6717f634d758cfd5c1cd7a6'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and acl.grantee<>v_postgres_oid
      )
  ) then
    raise exception 'T3A_ROLLBACK_T1_AUTHORITY_GUARD_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_authority_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.pg_get_triggerdef(tg.oid,true)=
        'CREATE TRIGGER trg_t1_guard_corretores_authority_update BEFORE UPDATE OF role, is_admin_local, is_gestor, empresa_id, time_id, user_id ON corretores FOR EACH ROW EXECUTE FUNCTION t1_guard_corretores_authority_update()'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        '68ec30b4d5014867c6db837d7d9db136'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|68ec30b4d5014867c6db837d7d9db136'
  ) then
    raise exception 'T3A_ROLLBACK_T1_AUTHORITY_TRIGGER_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.pg_get_triggerdef(tg.oid,true)=
        'CREATE TRIGGER trg_t1_guard_corretores_direct_compat_update BEFORE UPDATE OF ativo, apto_para_receber, must_change_password ON corretores FOR EACH ROW EXECUTE FUNCTION t1_guard_corretores_direct_compat_update()'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        'faf7f23f5e7c246a4500a7db9e518bc5'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|faf7f23f5e7c246a4500a7db9e518bc5'
  ) then
    raise exception 'T3A_ROLLBACK_T1_DIRECT_TRIGGER_DRIFT';
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
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        '60e6c615f59d9196e0979d6e93d2ad94'
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '3fdaca39d55f348ca36f796023f3260b'
  ) then
    raise exception 'T3A_ROLLBACK_CRITICAL_AUDIT_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=
      'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'::regprocedure
      and p.proowner=v_postgres_oid
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '3cc5c9279ed4a2f40acc6c3750fc7cc4'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'F1-02-T1-v3|3cc5c9279ed4a2f40acc6c3750fc7cc4'
      and pg_catalog.has_function_privilege(
            v_authenticated_oid,p.oid,'EXECUTE'
          )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
  ) then
    raise exception 'T3A_ROLLBACK_T1_POLICY_HELPER_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_policy as p
    where p.polrelid='public.corretores'::regclass and p.polcmd='w'
  ) <> 1
     or not exists (
       select 1
       from pg_catalog.pg_policy as p
       where p.polrelid='public.corretores'::regclass
         and p.polname='corretores_update'
         and p.polcmd='w'
         and p.polpermissive is true
         and p.polroles=array[0::oid]
         and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
           't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
         and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)=
           't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
     ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_POLICY_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_policy as p
    where p.polrelid='public.times'::regclass and p.polcmd='w'
  ) <> 1
     or not exists (
       select 1
       from pg_catalog.pg_policy as p
       where p.polrelid='public.times'::regclass
         and p.polname='times_update'
         and p.polcmd='w'
         and p.polpermissive is true
         and p.polroles=array[0::oid]
         and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
           '(is_root() OR (is_admin_local() AND (empresa_id = my_empresa_id())) OR (gestor_id = my_corretor_id()))'
         and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid) is null
     ) then
    raise exception 'T3A_ROLLBACK_TIMES_POLICY_DRIFT';
  end if;

  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.is_root()'::regprocedure
     )) is distinct from '465c04885d729e63f1a1d4458fc2a1b0'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
          'public.is_admin_local()'::regprocedure
        )) is distinct from '64b982da412f62c324aa2dde210eea0c'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
          'public.my_empresa_id()'::regprocedure
        )) is distinct from '7d7a73d22953d547a103f89c7b676906'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
          'public.my_corretor_id()'::regprocedure
        )) is distinct from 'c8f243d33d42837c46236625a74c3fb7' then
    raise exception 'T3A_ROLLBACK_TIMES_HELPER_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','SELECT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','DELETE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','TRUNCATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','REFERENCES')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','TRIGGER')
     or exists (
       select 1
       from information_schema.column_privileges as cp
       where cp.table_schema='public'
         and cp.table_name='admins'
         and cp.grantee='authenticated'
         and cp.privilege_type in ('SELECT','INSERT','UPDATE')
     ) then
    raise exception 'T3A_ROLLBACK_ADMINS_PRIVILEGE_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(v_anon_oid,'public.admins','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','TRIGGER')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','TRIGGER')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','TRIGGER') then
    raise exception 'T3A_ROLLBACK_ANON_TABLE_PRIVILEGE_DRIFT';
  end if;

  if exists (
    select 1
    from information_schema.column_privileges as cp
    where cp.table_schema='public'
      and cp.table_name in ('admins','corretores','times')
      and cp.grantee in ('anon','PUBLIC')
      and cp.privilege_type in ('SELECT','INSERT','UPDATE')
  ) then
    raise exception 'T3A_ROLLBACK_ANON_OR_PUBLIC_COLUMN_PRIVILEGE_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','SELECT'
     )
     or not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','DELETE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','TRUNCATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','REFERENCES'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','TRIGGER'
     ) then
    raise exception 'T3A_ROLLBACK_TIMES_PRIVILEGE_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','DELETE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','TRUNCATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','REFERENCES'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','TRIGGER'
     ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_TABLE_PRIVILEGE_DRIFT';
  end if;

  select pg_catalog.array_agg(a.attname::text order by a.attname::text)
    into v_update_columns
  from pg_catalog.pg_attribute as a
  where a.attrelid='public.corretores'::regclass
    and a.attnum>0
    and not a.attisdropped
    and pg_catalog.has_column_privilege(
          v_authenticated_oid,'public.corretores',a.attnum,'UPDATE'
        );

  if v_update_columns is distinct from
       array['apto_para_receber','ativo']::text[] then
    raise exception 'T3A_ROLLBACK_CORRETORES_GRANT_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_proc as p
    where lower(p.prosrc) like '%fechai.t3_admin_password_reset_context%'
      and p.oid not in (v_t3_oid,v_guard_oid)
  ) <> 0 then
    raise exception 'T3A_ROLLBACK_CONTEXT_KEY_COLLISION';
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
      and p.oid not in (
        'public.marcar_senha_inicial_definida()'::regprocedure,
        v_t3_oid
      )
  ) then
    raise exception 'T3A_ROLLBACK_UNEXPECTED_AUTH_PASSWORD_WRITER';
  end if;
end;
$rollback_preflight$;

-- =============================================================================
-- 2. RESTORE THE EXACT PRE-T3A T1 DIRECT-COMPATIBILITY GUARD
-- =============================================================================
create or replace function public.t1_guard_corretores_direct_compat_update()
returns trigger
language plpgsql
security invoker
set search_path=pg_catalog
as $function$
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
$function$;

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

comment on function public.t1_guard_corretores_direct_compat_update() is
'F1-02-T1-v3|99477024e337de5645dd042a30f8cf78';

-- The preflight proved the exact reviewed T3 function. Do not use IF EXISTS:
-- absence or drift is a blocker, not a condition to ignore.
drop function public.t3_prepare_admin_password_reset(uuid);

grant update (must_change_password)
  on table public.corretores to authenticated;

-- =============================================================================
-- 3. EXACT POST-ROLLBACK VERIFICATION
-- =============================================================================
do $postrollback$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );
  v_update_columns text[];
begin
  if pg_catalog.to_regprocedure(
       'public.t3_prepare_admin_password_reset(uuid)'
     ) is not null then
    raise exception 'T3A_ROLLBACK_FUNCTION_STILL_PRESENT';
  end if;

  if v_guard_oid is null
     or not exists (
       select 1
       from pg_catalog.pg_proc as p
       where p.oid=v_guard_oid
         and p.prosecdef is false
         and p.proconfig=array['search_path=pg_catalog']::text[]
         and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
           '99477024e337de5645dd042a30f8cf78'
         and pg_catalog.obj_description(p.oid,'pg_proc')=
           'F1-02-T1-v3|99477024e337de5645dd042a30f8cf78'
         and not pg_catalog.has_function_privilege(
                   v_authenticated_oid,p.oid,'EXECUTE'
                 )
         and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
         and not pg_catalog.has_function_privilege(
                   v_service_role_oid,p.oid,'EXECUTE'
                 )
         and not exists (
           select 1
           from pg_catalog.aclexplode(
             coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
           ) as acl
           where acl.privilege_type='EXECUTE'
             and acl.grantee<>v_postgres_oid
         )
     ) then
    raise exception 'T3A_ROLLBACK_PRE_T3_GUARD_NOT_RESTORED';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        'faf7f23f5e7c246a4500a7db9e518bc5'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|faf7f23f5e7c246a4500a7db9e518bc5'
  ) then
    raise exception 'T3A_ROLLBACK_T1_TRIGGER_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','UPDATE'
     ) then
    raise exception 'T3A_ROLLBACK_BROAD_UPDATE_PRESENT';
  end if;

  select pg_catalog.array_agg(a.attname::text order by a.attname::text)
    into v_update_columns
  from pg_catalog.pg_attribute as a
  where a.attrelid='public.corretores'::regclass
    and a.attnum>0
    and not a.attisdropped
    and pg_catalog.has_column_privilege(
          v_authenticated_oid,'public.corretores',a.attnum,'UPDATE'
        );

  if v_update_columns is distinct from
       array['apto_para_receber','ativo','must_change_password']::text[] then
    raise exception 'T3A_ROLLBACK_COMPAT_GRANT_NOT_RESTORED_EXACTLY';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    where lower(p.prosrc) like '%fechai.t3_admin_password_reset_context%'
  ) then
    raise exception 'T3A_ROLLBACK_CONTEXT_KEY_STILL_PRESENT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_policy as p
    where p.polrelid='public.corretores'::regclass
      and p.polname='corretores_update'
      and p.polcmd='w'
      and p.polpermissive is true
      and p.polroles=array[0::oid]
      and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
        't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
      and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)=
        't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
  ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_POLICY_DRIFT';
  end if;
end;
$postrollback$;

commit;
