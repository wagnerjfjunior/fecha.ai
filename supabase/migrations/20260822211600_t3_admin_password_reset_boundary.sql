-- FECH.AI — T3A-v2
-- Administrative Password Reset Multi-Tenant Authority Boundary
--
-- Safe rollout after a separate production authorization:
--   1. deploy the reviewed hardened Edge first;
--   2. prove reset_password fails closed while this RPC is absent;
--   3. apply this migration;
--   4. validate catalog/ACL/fingerprints;
--   5. run the separately-authorized bounded smoke matrix.
--
-- This migration never changes an Auth password. It authorizes one target and
-- prepares must_change_password=true before the versioned Edge performs the
-- Auth mutation. Company, role, flags and team are derived server-side.

begin;

-- =============================================================================
-- 1. EXACT FAIL-CLOSED TRUST-ANCHOR PREFLIGHT
-- =============================================================================
do $preflight$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_oid oid;
  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_md5 text;
  v_comment text;
  v_public_execute boolean;
  v_update_columns text[];
  r record;
begin
  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null then
    raise exception 'T3A_PREFLIGHT_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null
     or pg_catalog.to_regclass('public.admins') is null
     or pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null then
    raise exception 'T3A_PREFLIGHT_REQUIRED_OBJECT_MISSING';
  end if;

  v_oid:=pg_catalog.to_regprocedure('auth.uid()');
  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_oid
      and pg_catalog.pg_get_userbyid(p.proowner)='supabase_auth_admin'
      and p.prosecdef is false
      and p.provolatile='s'
      and p.prorettype='uuid'::regtype
      and p.pronargs=0
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        'ea3b41bf29e2ad573067939329aa088e'
      and pg_catalog.has_function_privilege(
            v_authenticated_oid,p.oid,'EXECUTE'
          )
      and pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and pg_catalog.has_function_privilege(
            v_service_role_oid,p.oid,'EXECUTE'
          )
  ) then
    raise exception 'T3A_PREFLIGHT_AUTH_UID_DRIFT';
  end if;

  if pg_catalog.to_regprocedure(
       'public.t3_prepare_admin_password_reset(uuid)'
     ) is not null then
    raise exception 'T3A_PREFLIGHT_FUNCTION_ALREADY_EXISTS';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    where lower(p.prosrc) like '%fechai.t3_admin_password_reset_context%'
  ) then
    raise exception 'T3A_PREFLIGHT_CONTEXT_KEY_COLLISION';
  end if;

  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='role' and data_type='text')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='time_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='role' and data_type='text')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='apto_para_receber' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_admin_local' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_gestor' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='must_change_password' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='gestor_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='ativo' and data_type='boolean') then
    raise exception 'T3A_PREFLIGHT_REQUIRED_COLUMN_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_RLS_FORCE_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_CORRETORES_USER_ID_UNIQUE_MISSING';
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
    raise exception 'T3A_PREFLIGHT_ADMINS_USER_ID_UNIQUE_MISSING';
  end if;

  -- public.admins is an authority source, never an authenticated write surface.
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
    raise exception 'T3A_PREFLIGHT_ADMINS_AUTHENTICATED_PRIVILEGE_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(v_anon_oid,'public.admins','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','TRIGGER') then
    raise exception 'T3A_PREFLIGHT_ADMINS_ANON_PRIVILEGE_DRIFT';
  end if;

  if exists (
    select 1
    from information_schema.column_privileges as cp
    where cp.table_schema='public'
      and cp.table_name in ('admins','corretores','times')
      and cp.grantee in ('anon','PUBLIC')
      and cp.privilege_type in ('SELECT','INSERT','UPDATE')
  ) then
    raise exception 'T3A_PREFLIGHT_ANON_OR_PUBLIC_COLUMN_PRIVILEGE_DRIFT';
  end if;

  -- Exact temporary T1 direct-compatibility surface before T3A.
  if not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','SELECT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','UPDATE'
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
    raise exception 'T3A_PREFLIGHT_CORRETORES_TABLE_PRIVILEGE_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_CORRETORES_UPDATE_COLUMNS_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','TRIGGER') then
    raise exception 'T3A_PREFLIGHT_CORRETORES_ANON_PRIVILEGE_DRIFT';
  end if;

  -- Gestor authority depends on exact times integrity and update semantics.
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
     )
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','TRIGGER') then
    raise exception 'T3A_PREFLIGHT_TIMES_PRIVILEGE_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_CORRETORES_UPDATE_POLICY_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_TIMES_UPDATE_POLICY_DRIFT';
  end if;

  -- Exact helper/RPC bodies that are part of the authority and compatibility chain.
  for r in
    select *
    from (
      values
        ('public.is_root()',
         '465c04885d729e63f1a1d4458fc2a1b0','search_path=public',true,true),
        ('public.is_admin_local()',
         '64b982da412f62c324aa2dde210eea0c','search_path=public',true,true),
        ('public.my_empresa_id()',
         '7d7a73d22953d547a103f89c7b676906','search_path=public',true,true),
        ('public.my_corretor_id()',
         'c8f243d33d42837c46236625a74c3fb7','search_path=public',true,true),
        ('public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)',
         '3cc5c9279ed4a2f40acc6c3750fc7cc4','search_path=pg_catalog',true,false),
        ('public.atualizar_status_corretor(uuid,boolean,boolean)',
         '563dc0b60766bda1aaf5ed9814a1c8cd','search_path=pg_catalog',true,false),
        ('public.marcar_senha_inicial_definida()',
         '2a7b28d4bb6342a99d075c4d3c49af4d','search_path=pg_catalog',true,false),
        ('public.audit_trail_log_corretores_critical_update()',
         '3fdaca39d55f348ca36f796023f3260b','search_path=public',true,true)
    ) as expected(signature,body_md5,config_entry,authenticated_execute,service_execute)
  loop
    v_oid:=pg_catalog.to_regprocedure(r.signature);
    if v_oid is null then
      raise exception 'T3A_PREFLIGHT_REQUIRED_FUNCTION_MISSING: %',r.signature;
    end if;

    select p.proowner,
           p.prosecdef,
           p.proconfig,
           pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
           exists (
             select 1
             from pg_catalog.aclexplode(
               coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
             ) as acl
             where acl.grantee=0 and acl.privilege_type='EXECUTE'
           )
      into strict v_owner,v_definer,v_config,v_md5,v_public_execute
    from pg_catalog.pg_proc as p
    where p.oid=v_oid;

    if v_owner is distinct from v_postgres_oid
       or v_definer is distinct from true
       or v_config is distinct from array[r.config_entry]::text[]
       or v_md5 is distinct from r.body_md5
       or pg_catalog.has_function_privilege(
            v_authenticated_oid,v_oid,'EXECUTE'
          ) is distinct from r.authenticated_execute
       or pg_catalog.has_function_privilege(
            v_service_role_oid,v_oid,'EXECUTE'
          ) is distinct from r.service_execute
       or pg_catalog.has_function_privilege(v_anon_oid,v_oid,'EXECUTE')
       or v_public_execute
       or exists (
         select 1
         from pg_catalog.pg_proc as p2
         cross join lateral pg_catalog.aclexplode(
           coalesce(p2.proacl,pg_catalog.acldefault('f',p2.proowner))
         ) as acl
         where p2.oid=v_oid
           and acl.privilege_type='EXECUTE'
           and acl.grantee not in (
             v_postgres_oid,v_authenticated_oid,v_service_role_oid
           )
       ) then
      raise exception 'T3A_PREFLIGHT_REQUIRED_FUNCTION_DRIFT: %',r.signature;
    end if;
  end loop;

  -- T1 guards are preserved exactly; only the direct guard body is replaced below.
  for r in
    select *
    from (
      values
        ('public.t1_guard_corretores_authority_update()',
         '5e69ae5cb6717f634d758cfd5c1cd7a6',
         'F1-02-T1-v3|5e69ae5cb6717f634d758cfd5c1cd7a6'),
        ('public.t1_guard_corretores_direct_compat_update()',
         '99477024e337de5645dd042a30f8cf78',
         'F1-02-T1-v3|99477024e337de5645dd042a30f8cf78')
    ) as expected(signature,body_md5,expected_comment)
  loop
    v_oid:=pg_catalog.to_regprocedure(r.signature);
    if v_oid is null then
      raise exception 'T3A_PREFLIGHT_T1_GUARD_MISSING: %',r.signature;
    end if;

    select p.proowner,p.prosecdef,p.proconfig,
           pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
           pg_catalog.obj_description(p.oid,'pg_proc'),
           exists (
             select 1
             from pg_catalog.aclexplode(
               coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
             ) as acl
             where acl.grantee=0 and acl.privilege_type='EXECUTE'
           )
      into strict v_owner,v_definer,v_config,v_md5,v_comment,v_public_execute
    from pg_catalog.pg_proc as p
    where p.oid=v_oid;

    if v_owner is distinct from v_postgres_oid
       or v_definer is distinct from false
       or v_config is distinct from array['search_path=pg_catalog']::text[]
       or v_md5 is distinct from r.body_md5
       or v_comment is distinct from r.expected_comment
       or pg_catalog.has_function_privilege(v_authenticated_oid,v_oid,'EXECUTE')
       or pg_catalog.has_function_privilege(v_anon_oid,v_oid,'EXECUTE')
       or pg_catalog.has_function_privilege(v_service_role_oid,v_oid,'EXECUTE')
       or v_public_execute
       or exists (
         select 1
         from pg_catalog.pg_proc as p2
         cross join lateral pg_catalog.aclexplode(
           coalesce(p2.proacl,pg_catalog.acldefault('f',p2.proowner))
         ) as acl
         where p2.oid=v_oid
           and acl.privilege_type='EXECUTE'
           and acl.grantee<>v_postgres_oid
       ) then
      raise exception 'T3A_PREFLIGHT_T1_GUARD_DRIFT: %',r.signature;
    end if;
  end loop;

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
    raise exception 'T3A_PREFLIGHT_T1_AUTHORITY_TRIGGER_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_T1_DIRECT_TRIGGER_DRIFT';
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
    raise exception 'T3A_PREFLIGHT_CRITICAL_AUDIT_DRIFT';
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
      and p.oid <> 'public.marcar_senha_inicial_definida()'::regprocedure
  ) then
    raise exception 'T3A_PREFLIGHT_UNEXPECTED_AUTH_PASSWORD_WRITER';
  end if;
end;
$preflight$;

-- =============================================================================
-- 2. NARROW T1 GUARD INTEROPERABILITY
-- =============================================================================
-- The existing trigger remains enabled and bound to the same three columns.
-- A T3 transition is admitted only when all of these are true:
--   * SECURITY DEFINER effective user is postgres;
--   * auth.uid() is still the authenticated actor;
--   * a transaction-local marker binds actor + target + txid;
--   * only must_change_password moves from not-true to true.
-- Ordinary client writes and arbitrary postgres writes without the marker keep
-- the exact pre-T3A T1 behavior below.
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
  v_t3_context text;
begin
  if new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber
     and new.must_change_password is not distinct from old.must_change_password then
    return new;
  end if;

  v_t3_context:=pg_catalog.current_setting(
    'fechai.t3_admin_password_reset_context',true
  );

  if current_user='postgres'
     and v_uid is not null
     and v_t3_context=pg_catalog.format(
       '%s:%s:%s',v_uid,old.user_id,pg_catalog.txid_current()
     )
     and old.must_change_password is distinct from true
     and new.must_change_password is true
     and new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber then
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
'T3A-v2|f2cbf4762b5f5b2d6c6eb56fcf0edc2b|pre_t3a=99477024e337de5645dd042a30f8cf78';

-- =============================================================================
-- 3. ADMINISTRATIVE PASSWORD-RESET AUTHORITY BOUNDARY
-- =============================================================================
create function public.t3_prepare_admin_password_reset(p_target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=pg_catalog
as $function$
declare
  v_actor_user_id uuid:=auth.uid();
  v_actor_id uuid;
  v_actor_empresa_id uuid;
  v_actor_role text;
  v_actor_ativo boolean;
  v_actor_is_admin_local boolean;
  v_actor_is_gestor boolean;
  v_is_root boolean:=false;

  v_target_id uuid;
  v_target_user_id uuid;
  v_target_empresa_id uuid;
  v_target_time_id uuid;
  v_target_role text;
  v_target_is_admin_local boolean;
  v_target_is_gestor boolean;
  v_rows integer;
begin
  if v_actor_user_id is null then
    raise exception using errcode='42501',message='AUTH_REQUIRED';
  end if;

  if p_target_user_id is null then
    raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
  end if;

  -- Root authority is derived only from public.admins.
  perform 1
  from public.admins as a
  where a.user_id=v_actor_user_id
    and a.ativo is true
    and a.role='admin_global'
  for share;
  if found then v_is_root:=true; end if;

  if not v_is_root then
    begin
      select c.id,
             c.empresa_id,
             c.role,
             c.ativo,
             coalesce(c.is_admin_local,false),
             coalesce(c.is_gestor,false)
        into strict v_actor_id,
                    v_actor_empresa_id,
                    v_actor_role,
                    v_actor_ativo,
                    v_actor_is_admin_local,
                    v_actor_is_gestor
      from public.corretores as c
      where c.user_id=v_actor_user_id
      for share;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501',message='AUTHORITY_DENIED';
    end;

    if v_actor_ativo is distinct from true then
      raise exception using errcode='42501',message='AUTHORITY_DENIED';
    end if;
  end if;

  if v_is_root then
    begin
      select c.id,
             c.user_id,
             c.empresa_id,
             c.time_id,
             c.role,
             coalesce(c.is_admin_local,false),
             coalesce(c.is_gestor,false)
        into strict v_target_id,
                    v_target_user_id,
                    v_target_empresa_id,
                    v_target_time_id,
                    v_target_role,
                    v_target_is_admin_local,
                    v_target_is_gestor
      from public.corretores as c
      where c.user_id=p_target_user_id
      for update;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end;

  elsif v_actor_role='admin_local'
    and v_actor_is_admin_local is true
  then
    begin
      select c.id,
             c.user_id,
             c.empresa_id,
             c.time_id,
             c.role,
             coalesce(c.is_admin_local,false),
             coalesce(c.is_gestor,false)
        into strict v_target_id,
                    v_target_user_id,
                    v_target_empresa_id,
                    v_target_time_id,
                    v_target_role,
                    v_target_is_admin_local,
                    v_target_is_gestor
      from public.corretores as c
      where c.user_id=p_target_user_id
        and c.empresa_id=v_actor_empresa_id
        and c.role<>'admin_global'
        and not exists (
          select 1
          from public.admins as protected_admin
          where protected_admin.user_id=c.user_id
        )
      for update;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end;

  elsif v_actor_role='gestor'
    and v_actor_is_gestor is true
    and v_actor_is_admin_local is false
  then
    begin
      select c.id,
             c.user_id,
             c.empresa_id,
             c.time_id,
             c.role,
             coalesce(c.is_admin_local,false),
             coalesce(c.is_gestor,false)
        into strict v_target_id,
                    v_target_user_id,
                    v_target_empresa_id,
                    v_target_time_id,
                    v_target_role,
                    v_target_is_admin_local,
                    v_target_is_gestor
      from public.corretores as c
      where c.user_id=p_target_user_id
        and c.empresa_id=v_actor_empresa_id
        and c.role='corretor'
        and coalesce(c.is_admin_local,false) is false
        and coalesce(c.is_gestor,false) is false
      for update;
    exception
      when no_data_found or too_many_rows then
        raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end;

    if v_target_time_id is null then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    perform 1
    from public.times as t
    where t.id=v_target_time_id
      and t.empresa_id=v_actor_empresa_id
      and t.gestor_id=v_actor_id
      and t.ativo is true
    for share;

    if not found then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;
  else
    raise exception using errcode='42501',message='AUTHORITY_DENIED';
  end if;

  perform pg_catalog.set_config(
    'fechai.t3_admin_password_reset_context',
    pg_catalog.format(
      '%s:%s:%s',v_actor_user_id,v_target_user_id,pg_catalog.txid_current()
    ),
    true
  );

  update public.corretores as c
     set must_change_password=true
   where c.id=v_target_id
     and c.user_id=v_target_user_id;

  get diagnostics v_rows=row_count;
  if v_rows<>1 then
    raise exception using errcode='P0001',message='PASSWORD_STATE_PREPARE_FAILED';
  end if;

  perform pg_catalog.set_config(
    'fechai.t3_admin_password_reset_context','',true
  );

  return pg_catalog.jsonb_build_object(
    'ok',true,
    'user_id',v_target_user_id
  );
end;
$function$;

alter function public.t3_prepare_admin_password_reset(uuid)
  owner to postgres;
revoke all on function public.t3_prepare_admin_password_reset(uuid)
  from public;
revoke all on function public.t3_prepare_admin_password_reset(uuid)
  from anon;
revoke all on function public.t3_prepare_admin_password_reset(uuid)
  from service_role;
grant execute on function public.t3_prepare_admin_password_reset(uuid)
  to authenticated;

comment on function public.t3_prepare_admin_password_reset(uuid) is
'T3A-v2|90c537dd4c2c7ae6fb7ae93373c4cc77|auth.uid actor; authority and tenant derived server-side; transaction-bound T1 interoperability';

-- App.jsx remains unchanged in T3A. Its stale direct PATCH cannot undo the
-- server-authoritative state after this narrow grant is revoked.
revoke update (must_change_password)
  on table public.corretores from authenticated;

-- =============================================================================
-- 4. EXACT POSTFLIGHT
-- =============================================================================
do $postflight$
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
  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'auth.uid()'::regprocedure
     )) is distinct from 'ea3b41bf29e2ad573067939329aa088e' then
    raise exception 'T3A_POSTFLIGHT_AUTH_UID_DRIFT';
  end if;

  if v_t3_oid is null or v_guard_oid is null then
    raise exception 'T3A_POSTFLIGHT_REQUIRED_FUNCTION_MISSING';
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
    raise exception 'T3A_POSTFLIGHT_FUNCTION_SECURITY_ACL_OR_BODY_DRIFT';
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
    raise exception 'T3A_POSTFLIGHT_T1_DIRECT_GUARD_DRIFT';
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
    raise exception 'T3A_POSTFLIGHT_T1_AUTHORITY_GUARD_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_authority_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        '68ec30b4d5014867c6db837d7d9db136'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|68ec30b4d5014867c6db837d7d9db136'
  )
     or not exists (
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
    raise exception 'T3A_POSTFLIGHT_T1_TRIGGER_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_proc as p
    where lower(p.prosrc) like '%fechai.t3_admin_password_reset_context%'
      and p.oid not in (v_t3_oid,v_guard_oid)
  ) <> 0 then
    raise exception 'T3A_POSTFLIGHT_CONTEXT_KEY_COLLISION';
  end if;

  if pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','UPDATE'
     ) then
    raise exception 'T3A_POSTFLIGHT_BROAD_UPDATE_PRESENT';
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
    raise exception 'T3A_POSTFLIGHT_CORRETORES_UPDATE_COLUMNS_DRIFT';
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
         and p.polpermissive is true
         and p.polroles=array[0::oid]
         and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
           't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
         and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)=
           't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
     ) then
    raise exception 'T3A_POSTFLIGHT_CORRETORES_POLICY_DRIFT';
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
         and p.polpermissive is true
         and p.polroles=array[0::oid]
         and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
           '(is_root() OR (is_admin_local() AND (empresa_id = my_empresa_id())) OR (gestor_id = my_corretor_id()))'
         and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid) is null
     ) then
    raise exception 'T3A_POSTFLIGHT_TIMES_POLICY_DRIFT';
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
    raise exception 'T3A_POSTFLIGHT_UNEXPECTED_AUTH_PASSWORD_WRITER';
  end if;
end;
$postflight$;

commit;
