-- FECH.AI / F1-02 / T1
-- Purpose: establish a server-authoritative status command for broker operational
-- state while closing the authenticated self-escalation path that would make
-- the command's actor authority untrustworthy.
--
-- Product Authority contract:
-- - root: may change ativo/apto_para_receber on an authorized target;
-- - admin_local: same company only; may change ativo/apto_para_receber;
-- - gestor: own active managed teams, ordinary broker targets only;
--           may change apto_para_receber only; ativo change denied;
-- - ordinary broker/no auth/inactive actor: denied;
-- - root authority is derived only from public.admins(role='admin_global', ativo=true);
-- - tenant/company/team/role are never accepted as client authority inputs.
--
-- Compatibility window:
-- - current frontend direct PATCH paths must keep working until their own cutover;
-- - authenticated table-level UPDATE is therefore narrowed, not fully removed;
-- - only ativo, apto_para_receber and must_change_password remain direct-update
--   compatible for authenticated callers;
-- - authority-bearing columns become non-writable through authenticated direct DML;
-- - a BEFORE trigger enforces the same authority/tenant/team restrictions on the
--   temporary direct compatibility surface, so it cannot bypass the RPC contract.
--
-- Production is the only Supabase environment currently adopted. This migration
-- is designed fail-closed and is NOT applied by being committed to GitHub.

-- =============================================================================
-- 1. PRE-FLIGHT — exact pre-T1 object/grant/policy surface
-- =============================================================================
do $preflight$
declare
  v_function_oid oid;
  v_function_md5 text;
  v_table_acl_md5 text;
  v_policy_md5 text;
  v_owner_oid oid;
  v_postgres_oid oid;
  v_authenticated_oid oid;
  v_anon_oid oid;
  v_service_role_oid oid;
  v_security_definer boolean;
  v_proconfig text[];
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

  -- Exact pre-T1 status function identity/body/ACL.
  v_function_oid := pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );

  if v_function_oid is null then
    raise exception 'T1_PREFLIGHT_STATUS_FUNCTION_MISSING';
  end if;

  select
    p.proowner,
    p.prosecdef,
    p.proconfig,
    pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
  into strict
    v_owner_oid,
    v_security_definer,
    v_proconfig,
    v_function_md5
  from pg_catalog.pg_proc as p
  where p.oid = v_function_oid;

  if v_owner_oid is distinct from v_postgres_oid then
    raise exception 'T1_PREFLIGHT_OWNER_DRIFT';
  end if;

  if v_security_definer is distinct from true then
    raise exception 'T1_PREFLIGHT_SECURITY_MODE_DRIFT';
  end if;

  if not pg_catalog.coalesce(
    v_proconfig @> array['search_path=public']::text[],
    false
  ) then
    raise exception 'T1_PREFLIGHT_SEARCH_PATH_DRIFT';
  end if;

  if v_function_md5 is distinct from 'ef89d686ebb3230ae4bef1b71d4860fd' then
    raise exception 'T1_PREFLIGHT_STATUS_FUNCTION_BODY_DRIFT';
  end if;

  if not pg_catalog.has_function_privilege(
    v_service_role_oid,
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception 'T1_PREFLIGHT_SERVICE_ROLE_EXECUTE_MISSING';
  end if;

  if pg_catalog.has_function_privilege(
    v_authenticated_oid,
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception 'T1_PREFLIGHT_AUTHENTICATED_EXECUTE_ALREADY_PRESENT';
  end if;

  if pg_catalog.has_function_privilege(v_anon_oid, v_function_oid, 'EXECUTE') then
    raise exception 'T1_PREFLIGHT_ANON_EXECUTE_PRESENT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      pg_catalog.coalesce(
        p.proacl,
        pg_catalog.acldefault('f', p.proowner)
      )
    ) as acl
    where p.oid = v_function_oid
      and acl.privilege_type = 'EXECUTE'
      and acl.grantee not in (v_owner_oid, v_service_role_oid)
  ) then
    raise exception 'T1_PREFLIGHT_STATUS_FUNCTION_UNEXPECTED_EXECUTOR';
  end if;

  -- Exact table ACL observed before T1. This intentionally fails on any grant
  -- drift instead of silently translating a different production state.
  select pg_catalog.md5(pg_catalog.coalesce(c.relacl::text, ''))
    into strict v_table_acl_md5
  from pg_catalog.pg_class as c
  join pg_catalog.pg_namespace as n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'corretores';

  if v_table_acl_md5 is distinct from 'afa3a93809a23f744356971cbc461855' then
    raise exception 'T1_PREFLIGHT_CORRETORES_TABLE_ACL_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
    v_authenticated_oid,
    'public.corretores',
    'UPDATE'
  ) then
    raise exception 'T1_PREFLIGHT_AUTHENTICATED_TABLE_UPDATE_MISSING';
  end if;

  -- No pre-existing authenticated column-level UPDATE ACL is expected.
  if exists (
    select 1
    from pg_catalog.pg_attribute as a
    cross join lateral pg_catalog.aclexplode(a.attacl) as acl
    where a.attrelid = 'public.corretores'::regclass
      and a.attnum > 0
      and not a.attisdropped
      and acl.grantee = v_authenticated_oid
      and acl.privilege_type = 'UPDATE'
  ) then
    raise exception 'T1_PREFLIGHT_AUTHENTICATED_COLUMN_UPDATE_DRIFT';
  end if;

  -- Exact current UPDATE policy. T1 will remove the ordinary self-row branch.
  select pg_catalog.md5(
           pg_catalog.coalesce(
             pg_catalog.pg_get_expr(pol.polqual, pol.polrelid),
             ''
           )
           || '|'
           || pg_catalog.coalesce(
             pg_catalog.pg_get_expr(pol.polwithcheck, pol.polrelid),
             ''
           )
         )
    into strict v_policy_md5
  from pg_catalog.pg_policy as pol
  where pol.polrelid = 'public.corretores'::regclass
    and pol.polname = 'corretores_update'
    and pol.polcmd = 'w';

  if v_policy_md5 is distinct from 'a3b9b4a44e859728ca9c69f6e6b2a842' then
    raise exception 'T1_PREFLIGHT_CORRETORES_UPDATE_POLICY_DRIFT';
  end if;

  -- T1-only objects must not pre-exist.
  if pg_catalog.to_regprocedure('public.t1_is_root_strict()') is not null then
    raise exception 'T1_PREFLIGHT_STRICT_ROOT_HELPER_ALREADY_EXISTS';
  end if;

  if pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  ) is not null then
    raise exception 'T1_PREFLIGHT_DIRECT_GUARD_FUNCTION_ALREADY_EXISTS';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid = 'public.corretores'::regclass
      and tg.tgname = 'trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
  ) then
    raise exception 'T1_PREFLIGHT_DIRECT_GUARD_TRIGGER_ALREADY_EXISTS';
  end if;

  -- Root source must not be client-writable.
  if pg_catalog.has_table_privilege(
       v_authenticated_oid,
       'public.admins',
       'INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,
       'public.admins',
       'UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,
       'public.admins',
       'DELETE'
     ) then
    raise exception 'T1_PREFLIGHT_ADMINS_AUTHENTICATED_DML_PRESENT';
  end if;

  -- RLS/FORCE RLS are expected on all authority/target tables used here.
  if exists (
    select 1
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in ('corretores', 'times', 'admins')
      and (
        c.relrowsecurity is distinct from true
        or c.relforcerowsecurity is distinct from true
      )
  ) then
    raise exception 'T1_PREFLIGHT_RLS_OR_FORCE_RLS_DRIFT';
  end if;

  -- Required schema surface.
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
  ) then raise exception 'T1_PREFLIGHT_IS_ADMIN_LOCAL_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='corretores'
      and column_name='is_gestor' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_IS_GESTOR_BOOLEAN_MISSING'; end if;

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
    where table_schema='public' and table_name='corretores'
      and column_name='must_change_password' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_PASSWORD_STATE_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='times'
      and column_name='gestor_id' and data_type='uuid'
  ) then raise exception 'T1_PREFLIGHT_TIMES_GESTOR_ID_UUID_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='times'
      and column_name='empresa_id' and data_type='uuid'
  ) then raise exception 'T1_PREFLIGHT_TIMES_EMPRESA_ID_UUID_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='times'
      and column_name='ativo' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_TIMES_ATIVO_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='admins'
      and column_name='user_id' and data_type='uuid'
  ) then raise exception 'T1_PREFLIGHT_ADMINS_USER_ID_UUID_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='admins'
      and column_name='ativo' and data_type='boolean'
  ) then raise exception 'T1_PREFLIGHT_ADMINS_ATIVO_BOOLEAN_MISSING'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='admins'
      and column_name='role' and data_type='text'
  ) then raise exception 'T1_PREFLIGHT_ADMINS_ROLE_TEXT_MISSING'; end if;

  -- Unique identity mapping is required for both actor sources.
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
    where n.nspname='public'
      and t.relname='corretores'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T1_PREFLIGHT_CORRETORES_USER_ID_UNIQUENESS_MISSING';
  end if;

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
    where n.nspname='public'
      and t.relname='admins'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T1_PREFLIGHT_ADMINS_USER_ID_UNIQUENESS_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_audit_trail_corretores_critical_update'
      and not tg.tgisinternal
  ) then
    raise exception 'T1_PREFLIGHT_CRITICAL_AUDIT_TRIGGER_MISSING';
  end if;
end;
$preflight$;

-- =============================================================================
-- 2. AUTHENTICATED DIRECT-DML AUTHORITY INTEGRITY
-- =============================================================================
-- Remove broad table UPDATE and keep only the three temporary compatibility
-- fields still used by the current UI. This is intentionally not PR-03's final
-- direct-UPDATE revocation.
revoke update on table public.corretores from authenticated;

grant update (
  ativo,
  apto_para_receber,
  must_change_password
) on public.corretores to authenticated;

-- Remove the ordinary self-row branch from direct UPDATE RLS. Controlled
-- self-service transitions (e.g. password completion) already use SECURITY
-- DEFINER RPCs and therefore do not need direct table UPDATE.
drop policy corretores_update on public.corretores;

create policy corretores_update
on public.corretores
for update
using (
  public.is_root()
  or (
    public.is_admin_local()
    and empresa_id = public.my_empresa_id()
  )
  or (
    public.is_gestor()
    and time_id = any(public.my_times_como_gestor())
  )
)
with check (
  public.is_root()
  or (
    public.is_admin_local()
    and empresa_id = public.my_empresa_id()
  )
  or (
    public.is_gestor()
    and time_id = any(public.my_times_como_gestor())
  )
);

-- Strict root helper for the temporary direct-compatibility trigger. It never
-- treats corretores.role='admin_global' as root authority.
create function public.t1_is_root_strict()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $function$
  select exists (
    select 1
    from public.admins as a
    where a.user_id = auth.uid()
      and a.ativo is true
      and a.role = 'admin_global'
  );
$function$;

alter function public.t1_is_root_strict() owner to postgres;
revoke all on function public.t1_is_root_strict() from public;
revoke all on function public.t1_is_root_strict() from anon;
revoke all on function public.t1_is_root_strict() from service_role;
grant execute on function public.t1_is_root_strict() to authenticated;

-- The guard is SECURITY INVOKER on purpose: direct authenticated Data API
-- updates run with current_user='authenticated', while the existing controlled
-- SECURITY DEFINER RPCs execute their DML as their owner and are not mistaken
-- for legacy direct DML. The guard protects only the compatibility fields.
create function public.t1_guard_corretores_direct_compat_update()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $function$
declare
  v_actor_user_id uuid;
  v_actor_id uuid;
  v_actor_empresa_id uuid;
  v_actor_role text;
  v_actor_active boolean;
  v_actor_is_admin_local boolean;
  v_actor_is_gestor boolean;
  v_root boolean := false;
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber
     and new.must_change_password is not distinct from old.must_change_password then
    return new;
  end if;

  v_actor_user_id := auth.uid();
  if v_actor_user_id is null then
    raise exception using
      errcode='42501',
      message='AUTH_REQUIRED';
  end if;

  v_root := public.t1_is_root_strict();

  begin
    select
      c.id,
      c.empresa_id,
      c.role,
      c.ativo,
      coalesce(c.is_admin_local, false),
      coalesce(c.is_gestor, false)
    into strict
      v_actor_id,
      v_actor_empresa_id,
      v_actor_role,
      v_actor_active,
      v_actor_is_admin_local,
      v_actor_is_gestor
    from public.corretores as c
    where c.user_id = v_actor_user_id;
  exception
    when no_data_found then
      if v_root then
        return new;
      end if;
      raise exception using
        errcode='42501',
        message='ACTOR_PROFILE_NOT_FOUND';
    when too_many_rows then
      raise exception using
        errcode='21000',
        message='ACTOR_PROFILE_AMBIGUOUS';
  end;

  -- If a root identity also has a corretores profile, an inactive profile is
  -- fail-closed. Root identities without a corretores profile remain supported.
  if v_actor_active is distinct from true then
    raise exception using
      errcode='42501',
      message='PROFILE_INACTIVE';
  end if;

  -- Direct clients may never toggle their own active/password-state flags.
  -- The self-service password flow remains available through its controlled RPC.
  if old.user_id = v_actor_user_id
     and new.ativo is distinct from old.ativo then
    raise exception using
      errcode='42501',
      message='SELF_ACTIVE_CHANGE_DENIED';
  end if;

  if old.user_id = v_actor_user_id
     and new.must_change_password is distinct from old.must_change_password then
    raise exception using
      errcode='42501',
      message='SELF_PASSWORD_STATE_CHANGE_DENIED';
  end if;

  if v_root then
    return new;
  end if;

  if v_actor_role = 'admin_local'
     and v_actor_is_admin_local is true
     and v_actor_is_gestor is false then
    if v_actor_empresa_id is null
       or old.empresa_id is distinct from v_actor_empresa_id then
      raise exception using
        errcode='42501',
        message='CROSS_TENANT_DENIED';
    end if;
    return new;
  end if;

  if v_actor_role = 'gestor'
     and v_actor_is_gestor is true
     and v_actor_is_admin_local is false then

    if new.ativo is distinct from old.ativo then
      raise exception using
        errcode='42501',
        message='ACTIVE_CHANGE_DENIED_FOR_MANAGER';
    end if;

    if v_actor_empresa_id is null
       or old.empresa_id is distinct from v_actor_empresa_id
       or old.role is distinct from 'corretor'
       or coalesce(old.is_admin_local, false) is true
       or coalesce(old.is_gestor, false) is true
       or old.time_id is null then
      raise exception using
        errcode='42501',
        message='TARGET_NOT_AUTHORIZED';
    end if;

    if not exists (
      select 1
      from public.times as t
      where t.id = old.time_id
        and t.empresa_id = v_actor_empresa_id
        and t.gestor_id = v_actor_id
        and t.ativo is true
    ) then
      raise exception using
        errcode='42501',
        message='TARGET_NOT_AUTHORIZED';
    end if;

    return new;
  end if;

  raise exception using
    errcode='42501',
    message='ACCESS_DENIED';
end;
$function$;

alter function public.t1_guard_corretores_direct_compat_update() owner to postgres;
revoke all on function public.t1_guard_corretores_direct_compat_update() from public;
revoke all on function public.t1_guard_corretores_direct_compat_update() from anon;
revoke all on function public.t1_guard_corretores_direct_compat_update() from authenticated;
revoke all on function public.t1_guard_corretores_direct_compat_update() from service_role;

create trigger trg_t1_guard_corretores_direct_compat_update
before update of ativo, apto_para_receber, must_change_password
on public.corretores
for each row
execute function public.t1_guard_corretores_direct_compat_update();

-- =============================================================================
-- 3. HARDENED SERVER-SIDE STATUS COMMAND
-- =============================================================================
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
  v_actor_role text;
  v_actor_active boolean;
  v_actor_is_admin_local boolean;
  v_actor_is_gestor boolean;
  v_root boolean := false;
  v_root_row_found boolean := false;
  v_profile_found boolean := false;
  v_updated_id uuid;
  v_updated_ativo boolean;
  v_updated_apto boolean;
begin
  v_actor_user_id := auth.uid();

  if v_actor_user_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'AUTH_REQUIRED',
      'error', 'Usuário não autenticado'
    );
  end if;

  -- Stabilize the trusted root source for this transaction. Root is ONLY an
  -- active admin_global row in public.admins; corretores.role never grants root.
  begin
    perform 1
    from public.admins as a
    where a.user_id = v_actor_user_id
      and a.ativo is true
      and a.role = 'admin_global'
    for share;

    if found then
      v_root := true;
      v_root_row_found := true;
    end if;
  exception
    when others then
      raise;
  end;

  -- Stabilize the actor profile across the target mutation. This prevents an
  -- authority/active-state update from racing between authorization and UPDATE.
  begin
    select
      c.id,
      c.empresa_id,
      c.role,
      c.ativo,
      coalesce(c.is_admin_local, false),
      coalesce(c.is_gestor, false)
    into strict
      v_actor_id,
      v_actor_empresa_id,
      v_actor_role,
      v_actor_active,
      v_actor_is_admin_local,
      v_actor_is_gestor
    from public.corretores as c
    where c.user_id = v_actor_user_id
    for share;

    v_profile_found := true;
  exception
    when no_data_found then
      v_profile_found := false;
    when too_many_rows then
      return jsonb_build_object(
        'ok', false,
        'code', 'ACTOR_PROFILE_AMBIGUOUS',
        'error', 'Perfil autenticado ambíguo'
      );
  end;

  if v_profile_found and v_actor_active is distinct from true then
    return jsonb_build_object(
      'ok', false,
      'code', 'PROFILE_INACTIVE',
      'error', 'Perfil autenticado inativo'
    );
  end if;

  if not v_root and not v_profile_found then
    return jsonb_build_object(
      'ok', false,
      'code', 'ACTOR_PROFILE_NOT_FOUND',
      'error', 'Perfil autenticado não encontrado'
    );
  end if;

  if p_ativo is null and p_apto_para_receber is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'NO_CHANGE_REQUESTED',
      'error', 'Nenhuma alteração solicitada'
    );
  end if;

  -- ROOT: trusted admins row already locked. Existing active corretores profile,
  -- when present, was also locked and validated above.
  if v_root then
    update public.corretores as target
       set ativo = coalesce(p_ativo, target.ativo),
           apto_para_receber = coalesce(
             p_apto_para_receber,
             target.apto_para_receber
           )
     where target.id = p_corretor_id
     returning target.id, target.ativo, target.apto_para_receber
          into v_updated_id, v_updated_ativo, v_updated_apto;

  -- ADMIN LOCAL: strict role+flag consistency, active profile, same company.
  elsif v_actor_role = 'admin_local'
        and v_actor_is_admin_local is true
        and v_actor_is_gestor is false then

    update public.corretores as target
       set ativo = coalesce(p_ativo, target.ativo),
           apto_para_receber = coalesce(
             p_apto_para_receber,
             target.apto_para_receber
           )
     where target.id = p_corretor_id
       and v_actor_empresa_id is not null
       and target.empresa_id = v_actor_empresa_id
     returning target.id, target.ativo, target.apto_para_receber
          into v_updated_id, v_updated_ativo, v_updated_apto;

  -- GESTOR: apto only, ordinary broker, same company, own active managed team.
  elsif v_actor_role = 'gestor'
        and v_actor_is_gestor is true
        and v_actor_is_admin_local is false then

    if p_ativo is not null then
      return jsonb_build_object(
        'ok', false,
        'code', 'ACTIVE_CHANGE_DENIED_FOR_MANAGER',
        'error', 'Gestor não pode alterar o estado ativo do corretor'
      );
    end if;

    update public.corretores as target
       set apto_para_receber = coalesce(
         p_apto_para_receber,
         target.apto_para_receber
       )
     where target.id = p_corretor_id
       and v_actor_empresa_id is not null
       and target.empresa_id = v_actor_empresa_id
       and target.role = 'corretor'
       and coalesce(target.is_admin_local, false) is false
       and coalesce(target.is_gestor, false) is false
       and target.time_id is not null
       and exists (
         select 1
         from public.times as t
         where t.id = target.time_id
           and t.empresa_id = v_actor_empresa_id
           and t.gestor_id = v_actor_id
           and t.ativo is true
       )
     returning target.id, target.ativo, target.apto_para_receber
          into v_updated_id, v_updated_ativo, v_updated_apto;

  else
    return jsonb_build_object(
      'ok', false,
      'code', 'ACCESS_DENIED',
      'error', 'Sem permissão para alterar status de corretor'
    );
  end if;

  if v_updated_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'TARGET_NOT_AUTHORIZED',
      'error', 'Corretor não encontrado ou não autorizado'
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'corretor_id', v_updated_id,
    'ativo', v_updated_ativo,
    'apto_para_receber', v_updated_apto
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
  'F1-02 T1: strict server-authoritative status command. Root derives only from active admins/admin_global; admin_local same tenant; gestor own active managed ordinary brokers and apto only.';

-- =============================================================================
-- 4. POST-FLIGHT — prove resulting authority surface
-- =============================================================================
do $postflight$
declare
  v_function_oid oid;
  v_guard_oid oid;
  v_root_helper_oid oid;
  v_owner_oid oid;
  v_postgres_oid oid;
  v_authenticated_oid oid;
  v_anon_oid oid;
  v_service_role_oid oid;
  v_security_definer boolean;
  v_proconfig text[];
  v_using_expr text;
  v_with_check_expr text;
begin
  v_postgres_oid := pg_catalog.to_regrole('postgres');
  v_authenticated_oid := pg_catalog.to_regrole('authenticated');
  v_anon_oid := pg_catalog.to_regrole('anon');
  v_service_role_oid := pg_catalog.to_regrole('service_role');

  v_function_oid := pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  v_guard_oid := pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );
  v_root_helper_oid := pg_catalog.to_regprocedure(
    'public.t1_is_root_strict()'
  );

  if v_function_oid is null
     or v_guard_oid is null
     or v_root_helper_oid is null then
    raise exception 'T1_POSTFLIGHT_REQUIRED_FUNCTION_MISSING';
  end if;

  select p.proowner, p.prosecdef, p.proconfig
    into strict v_owner_oid, v_security_definer, v_proconfig
  from pg_catalog.pg_proc as p
  where p.oid = v_function_oid;

  if v_owner_oid is distinct from v_postgres_oid then
    raise exception 'T1_POSTFLIGHT_STATUS_OWNER_NOT_POSTGRES';
  end if;

  if v_security_definer is distinct from true then
    raise exception 'T1_POSTFLIGHT_STATUS_SECURITY_DEFINER_MISSING';
  end if;

  if not pg_catalog.coalesce(
    v_proconfig @> array['search_path=pg_catalog']::text[],
    false
  ) then
    raise exception 'T1_POSTFLIGHT_STATUS_SEARCH_PATH_NOT_FIXED';
  end if;

  if not pg_catalog.has_function_privilege(
    v_authenticated_oid, v_function_oid, 'EXECUTE'
  ) then
    raise exception 'T1_POSTFLIGHT_AUTHENTICATED_EXECUTE_MISSING';
  end if;

  if pg_catalog.has_function_privilege(v_anon_oid, v_function_oid, 'EXECUTE')
     or pg_catalog.has_function_privilege(
       v_service_role_oid, v_function_oid, 'EXECUTE'
     ) then
    raise exception 'T1_POSTFLIGHT_UNEXPECTED_STATUS_EXECUTOR';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      pg_catalog.coalesce(
        p.proacl,
        pg_catalog.acldefault('f', p.proowner)
      )
    ) as acl
    where p.oid = v_function_oid
      and acl.privilege_type='EXECUTE'
      and acl.grantee not in (v_owner_oid, v_authenticated_oid)
  ) then
    raise exception 'T1_POSTFLIGHT_STATUS_UNEXPECTED_EXECUTOR';
  end if;

  -- Broad authenticated table UPDATE must be gone.
  if pg_catalog.has_table_privilege(
    v_authenticated_oid,
    'public.corretores',
    'UPDATE'
  ) then
    raise exception 'T1_POSTFLIGHT_BROAD_TABLE_UPDATE_STILL_PRESENT';
  end if;

  -- Exactly the temporary compatibility columns retain authenticated UPDATE.
  if not pg_catalog.has_column_privilege(
       v_authenticated_oid,
       'public.corretores',
       'ativo',
       'UPDATE'
     )
     or not pg_catalog.has_column_privilege(
       v_authenticated_oid,
       'public.corretores',
       'apto_para_receber',
       'UPDATE'
     )
     or not pg_catalog.has_column_privilege(
       v_authenticated_oid,
       'public.corretores',
       'must_change_password',
       'UPDATE'
     ) then
    raise exception 'T1_POSTFLIGHT_COMPATIBILITY_COLUMN_UPDATE_MISSING';
  end if;

  if pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','role','UPDATE'
     )
     or pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','is_admin_local','UPDATE'
     )
     or pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','is_gestor','UPDATE'
     )
     or pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','empresa_id','UPDATE'
     )
     or pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','time_id','UPDATE'
     )
     or pg_catalog.has_column_privilege(
       v_authenticated_oid,'public.corretores','user_id','UPDATE'
     ) then
    raise exception 'T1_POSTFLIGHT_AUTHORITY_COLUMN_UPDATE_PRESENT';
  end if;

  -- No authenticated UPDATE may exist on any column except the 3 compatibility
  -- columns above.
  if exists (
    select 1
    from information_schema.column_privileges as cp
    where cp.table_schema='public'
      and cp.table_name='corretores'
      and cp.grantee='authenticated'
      and cp.privilege_type='UPDATE'
      and cp.column_name not in (
        'ativo',
        'apto_para_receber',
        'must_change_password'
      )
  ) then
    raise exception 'T1_POSTFLIGHT_UNEXPECTED_COLUMN_UPDATE_PRESENT';
  end if;

  -- The ordinary self-row branch must be gone from direct UPDATE policy.
  select
    pg_catalog.pg_get_expr(pol.polqual, pol.polrelid),
    pg_catalog.pg_get_expr(pol.polwithcheck, pol.polrelid)
  into strict v_using_expr, v_with_check_expr
  from pg_catalog.pg_policy as pol
  where pol.polrelid='public.corretores'::regclass
    and pol.polname='corretores_update'
    and pol.polcmd='w';

  if v_with_check_expr is null then
    raise exception 'T1_POSTFLIGHT_UPDATE_POLICY_WITH_CHECK_MISSING';
  end if;

  if pg_catalog.position('user_id = auth.uid()' in v_using_expr) > 0
     or pg_catalog.position('user_id = auth.uid()' in v_with_check_expr) > 0 then
    raise exception 'T1_POSTFLIGHT_SELF_UPDATE_POLICY_BRANCH_PRESENT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
  ) then
    raise exception 'T1_POSTFLIGHT_DIRECT_GUARD_TRIGGER_MISSING';
  end if;

  -- Root source remains non-client-writable.
  if pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.admins','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.admins','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.admins','DELETE'
     ) then
    raise exception 'T1_POSTFLIGHT_ADMINS_AUTHENTICATED_DML_PRESENT';
  end if;
end;
$postflight$;

-- =============================================================================
-- 5. EXACT ROLLBACK — execute only as a separately authorized production action
-- =============================================================================
-- Before rollback, revalidate that the T1 function/helper/trigger/grants still
-- match this migration. Do not apply this rollback blindly after later drift.
--
-- drop trigger if exists trg_t1_guard_corretores_direct_compat_update
--   on public.corretores;
-- drop function if exists public.t1_guard_corretores_direct_compat_update();
-- revoke all on function public.t1_is_root_strict() from authenticated;
-- drop function if exists public.t1_is_root_strict();
--
-- drop policy if exists corretores_update on public.corretores;
-- create policy corretores_update
-- on public.corretores
-- for update
-- using (
--   public.is_root()
--   or (public.is_admin_local() and empresa_id = public.my_empresa_id())
--   or (public.is_gestor() and time_id = any(public.my_times_como_gestor()))
--   or (user_id = auth.uid())
-- );
--
-- revoke update (ativo, apto_para_receber, must_change_password)
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
