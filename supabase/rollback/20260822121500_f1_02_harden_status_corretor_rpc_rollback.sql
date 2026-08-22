-- FECH.AI / F1-02 / T1
-- CANONICAL EXECUTABLE ROLLBACK for:
--   supabase/migrations/20260822121500_f1_02_harden_status_corretor_rpc.sql
--
-- IMPORTANT
-- - This file is NOT a forward migration.
-- - It MUST NOT be executed automatically.
-- - It requires separate Product Authority authorization for production rollback.
-- - It is fail-closed: preflight runs before any mutation, all mutations and
--   postflight run in one transaction, and any failure aborts the transaction.
-- - The commented rollback runbook embedded in the forward migration is
--   superseded by this canonical executable rollback artifact.
--
-- Baseline restored by this rollback:
--   atualizar_status_corretor body MD5:
--     ef89d686ebb3230ae4bef1b71d4860fd
--   corretores table ACL MD5:
--     afa3a93809a23f744356971cbc461855
--   corretores_update expression MD5:
--     a3b9b4a44e859728ca9c69f6e6b2a842
--   critical audit function body MD5:
--     3fdaca39d55f348ca36f796023f3260b

begin;

-- =============================================================================
-- 1. FAIL-CLOSED PRE-ROLLBACK VERIFIER
-- =============================================================================
do $rollback_preflight$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');

  v_status_oid oid:=pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  v_root_oid oid:=pg_catalog.to_regprocedure('public.t1_is_root_strict()');
  v_row_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'
  );
  v_authority_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_authority_update()'
  );
  v_compat_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );

  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_acl text;
  v_marker text;
  v_actual text;

  v_policy_marker text;
  v_policy_actual text;
  v_policy_roles oid[];
  v_policy_permissive boolean;
  v_policy_cmd "char";

  v_audit_trigger_oid oid;
  v_audit_fn_oid oid;
  v_audit_trigger_enabled "char";
  v_audit_trigger_def text;

  r record;
begin
  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null then
    raise exception 'T1_ROLLBACK_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null
     or pg_catalog.to_regclass('public.admins') is null then
    raise exception 'T1_ROLLBACK_REQUIRED_TABLE_MISSING';
  end if;

  -- G3-F1: exact function set must exist before any mutation.
  if v_status_oid is null
     or v_root_oid is null
     or v_row_guard_oid is null
     or v_authority_guard_oid is null
     or v_compat_guard_oid is null then
    raise exception 'T1_ROLLBACK_T1_FUNCTION_SET_INCOMPLETE';
  end if;

  -- G3-F2: bind body marker + owner + security mode + exact search_path + ACL.
  for r in
    select p.oid,
           p.proowner,
           p.prosecdef,
           p.proconfig,
           p.proacl::text as acl_text,
           pg_catalog.obj_description(p.oid,'pg_proc') as marker,
           pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) as body_md5
    from pg_catalog.pg_proc as p
    where p.oid in (
      v_status_oid,
      v_root_oid,
      v_row_guard_oid,
      v_authority_guard_oid,
      v_compat_guard_oid
    )
  loop
    if r.proowner is distinct from v_postgres_oid then
      raise exception 'T1_ROLLBACK_FUNCTION_OWNER_DRIFT';
    end if;

    if r.proconfig is distinct from array['search_path=pg_catalog']::text[] then
      raise exception 'T1_ROLLBACK_FUNCTION_SEARCH_PATH_DRIFT';
    end if;

    if r.oid in (v_status_oid,v_root_oid,v_row_guard_oid) then
      if r.prosecdef is distinct from true
         or r.acl_text is distinct from
           '{postgres=X/postgres,authenticated=X/postgres}' then
        raise exception 'T1_ROLLBACK_CALLABLE_FUNCTION_SECURITY_DRIFT';
      end if;
    else
      if r.prosecdef is distinct from false
         or r.acl_text is distinct from '{postgres=X/postgres}' then
        raise exception 'T1_ROLLBACK_TRIGGER_FUNCTION_SECURITY_DRIFT';
      end if;
    end if;

    if r.marker not like 'F1-02-T1-v3|%'
       or r.body_md5 is distinct from pg_catalog.split_part(r.marker,'|',2) then
      raise exception 'T1_ROLLBACK_FUNCTION_FINGERPRINT_DRIFT';
    end if;
  end loop;

  if (
    select count(*)
    from pg_catalog.pg_proc as p
    where p.oid in (
      v_status_oid,
      v_root_oid,
      v_row_guard_oid,
      v_authority_guard_oid,
      v_compat_guard_oid
    )
  ) <> 5 then
    raise exception 'T1_ROLLBACK_T1_FUNCTION_CARDINALITY_DRIFT';
  end if;

  -- G3-F1: prove exactly both expected T1 triggers are present before mutation.
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
    raise exception 'T1_ROLLBACK_T1_TRIGGER_SET_INCOMPLETE';
  end if;

  for r in
    select tg.oid,
           tg.tgname,
           tg.tgfoid,
           tg.tgenabled,
           pg_catalog.obj_description(tg.oid,'pg_trigger') as marker,
           pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true)) as def_md5
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname in (
        'trg_t1_guard_corretores_authority_update',
        'trg_t1_guard_corretores_direct_compat_update'
      )
      and not tg.tgisinternal
  loop
    if r.tgenabled is distinct from 'O'
       or r.marker not like 'F1-02-T1-v3|%'
       or r.def_md5 is distinct from pg_catalog.split_part(r.marker,'|',2) then
      raise exception 'T1_ROLLBACK_T1_TRIGGER_FINGERPRINT_DRIFT';
    end if;

    if r.tgname='trg_t1_guard_corretores_authority_update'
       and r.tgfoid is distinct from v_authority_guard_oid then
      raise exception 'T1_ROLLBACK_AUTHORITY_TRIGGER_FUNCTION_DRIFT';
    end if;

    if r.tgname='trg_t1_guard_corretores_direct_compat_update'
       and r.tgfoid is distinct from v_compat_guard_oid then
      raise exception 'T1_ROLLBACK_COMPAT_TRIGGER_FUNCTION_DRIFT';
    end if;
  end loop;

  -- G3-F4: policy fingerprint includes expression + permissive + roles + command.
  select pg_catalog.obj_description(p.oid,'pg_policy'),
         pg_catalog.md5(
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
           || '|'
           || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
         ),
         p.polroles,
         p.polpermissive,
         p.polcmd
    into strict v_policy_marker,
                v_policy_actual,
                v_policy_roles,
                v_policy_permissive,
                v_policy_cmd
  from pg_catalog.pg_policy as p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update';

  if v_policy_cmd is distinct from 'w'
     or v_policy_permissive is distinct from true
     or v_policy_roles is distinct from array[0::oid]::oid[]
     or v_policy_marker not like 'F1-02-T1-v3|%'
     or v_policy_actual is distinct from
        pg_catalog.split_part(v_policy_marker,'|',2) then
    raise exception 'T1_ROLLBACK_POLICY_DRIFT';
  end if;

  -- Exact T1 target table ACL: baseline table UPDATE removed from authenticated.
  select c.relacl::text
    into strict v_actual
  from pg_catalog.pg_class as c
  join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='corretores';

  if v_actual is distinct from
     '{postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres,authenticated=r/postgres}' then
    raise exception 'T1_ROLLBACK_TABLE_ACL_DRIFT';
  end if;

  -- Exact T1 column ACL: only 3 temporary authenticated UPDATE grants exist.
  if (
    select count(*)
    from pg_catalog.pg_attribute as a
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and a.attacl is not null
  ) <> 3 then
    raise exception 'T1_ROLLBACK_COLUMN_ACL_CARDINALITY_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute as a
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and a.attacl is not null
      and a.attname not in (
        'ativo','apto_para_receber','must_change_password'
      )
  ) then
    raise exception 'T1_ROLLBACK_UNEXPECTED_COLUMN_ACL';
  end if;

  for r in
    select a.attname,
           acl.grantor,
           acl.grantee,
           acl.privilege_type,
           acl.is_grantable
    from pg_catalog.pg_attribute as a
    cross join lateral pg_catalog.aclexplode(a.attacl) as acl
    where a.attrelid='public.corretores'::regclass
      and a.attname in ('ativo','apto_para_receber','must_change_password')
      and a.attnum>0
      and not a.attisdropped
  loop
    if r.grantor is distinct from v_postgres_oid
       or r.grantee is distinct from v_authenticated_oid
       or r.privilege_type is distinct from 'UPDATE'
       or r.is_grantable is distinct from false then
      raise exception 'T1_ROLLBACK_COLUMN_ACL_DRIFT';
    end if;
  end loop;

  if (
    select count(*)
    from pg_catalog.pg_attribute as a
    cross join lateral pg_catalog.aclexplode(a.attacl) as acl
    where a.attrelid='public.corretores'::regclass
      and a.attname in ('ativo','apto_para_receber','must_change_password')
      and a.attnum>0
      and not a.attisdropped
  ) <> 3 then
    raise exception 'T1_ROLLBACK_COLUMN_ACL_ENTRY_DRIFT';
  end if;

  -- G3-F3: revalidate the complete critical audit surface.
  select tg.oid,
         tg.tgenabled,
         tg.tgfoid,
         pg_catalog.pg_get_triggerdef(tg.oid,true)
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
    raise exception 'T1_ROLLBACK_CRITICAL_AUDIT_TRIGGER_DRIFT';
  end if;

  select p.proowner,
         p.prosecdef,
         p.proconfig,
         p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
    into strict v_owner,v_definer,v_config,v_acl,v_actual
  from pg_catalog.pg_proc as p
  where p.oid=v_audit_fn_oid;

  if v_owner is distinct from v_postgres_oid
     or v_definer is distinct from true
     or v_config is distinct from array['search_path=public']::text[]
     or v_acl is distinct from
       '{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}'
     or v_actual is distinct from '3fdaca39d55f348ca36f796023f3260b' then
    raise exception 'T1_ROLLBACK_CRITICAL_AUDIT_FUNCTION_DRIFT';
  end if;
end;
$rollback_preflight$;

-- =============================================================================
-- 2. ROLLBACK MUTATIONS
-- =============================================================================
drop trigger trg_t1_guard_corretores_direct_compat_update
  on public.corretores;
drop function public.t1_guard_corretores_direct_compat_update();

drop trigger trg_t1_guard_corretores_authority_update
  on public.corretores;
drop function public.t1_guard_corretores_authority_update();

drop policy corretores_update on public.corretores;
create policy corretores_update
on public.corretores
for update
using (
  public.is_root()
  or (public.is_admin_local() and empresa_id=public.my_empresa_id())
  or (public.is_gestor() and time_id=any(public.my_times_como_gestor()))
  or (user_id=auth.uid())
);

revoke update (ativo,apto_para_receber,must_change_password)
  on public.corretores from authenticated;
grant update on table public.corretores to authenticated;

create or replace function public.atualizar_status_corretor(
  p_corretor_id uuid,
  p_ativo boolean default null,
  p_apto_para_receber boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $rollback$
DECLARE
  v_empresa_id uuid;
  v_root boolean := false;
BEGIN
  v_root := public.is_root();

  SELECT empresa_id INTO v_empresa_id
  FROM public.corretores
  WHERE user_id = auth.uid()
  LIMIT 1;

  IF NOT (public.is_admin_local() OR public.is_gestor() OR v_root) THEN
    RETURN jsonb_build_object('error', 'forbidden');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.corretores
    WHERE id = p_corretor_id
      AND (v_root OR empresa_id = v_empresa_id)
  ) THEN
    RETURN jsonb_build_object('error', 'not_found');
  END IF;

  UPDATE public.corretores
  SET ativo = COALESCE(p_ativo, ativo),
      apto_para_receber = COALESCE(p_apto_para_receber, apto_para_receber)
  WHERE id = p_corretor_id
    AND (v_root OR empresa_id = v_empresa_id);

  RETURN jsonb_build_object('ok', true);
END;
$rollback$;

alter function public.atualizar_status_corretor(uuid,boolean,boolean)
  owner to postgres;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from public;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from anon;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from authenticated;
revoke all on function public.atualizar_status_corretor(uuid,boolean,boolean)
  from service_role;
grant execute on function public.atualizar_status_corretor(uuid,boolean,boolean)
  to service_role;
comment on function public.atualizar_status_corretor(uuid,boolean,boolean)
  is null;

drop function public.t1_can_update_corretor_row_strict(
  uuid,uuid,text,boolean,boolean
);
drop function public.t1_is_root_strict();

-- =============================================================================
-- 3. EXACT POST-ROLLBACK VERIFIER
-- =============================================================================
do $rollback_postflight$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');

  v_status_oid oid:=pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );

  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_acl text;
  v_actual text;
  v_policy_roles oid[];
  v_policy_permissive boolean;
  v_policy_cmd "char";
  v_policy_comment text;
  v_audit_trigger_oid oid;
  v_audit_fn_oid oid;
  v_audit_enabled "char";
  v_audit_def text;
begin
  if v_status_oid is null then
    raise exception 'T1_ROLLBACK_POST_STATUS_MISSING';
  end if;

  select p.proowner,
         p.prosecdef,
         p.proconfig,
         p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
         pg_catalog.obj_description(p.oid,'pg_proc')
    into strict v_owner,v_definer,v_config,v_acl,v_actual,v_policy_comment
  from pg_catalog.pg_proc as p
  where p.oid=v_status_oid;

  if v_owner is distinct from v_postgres_oid
     or v_definer is distinct from true
     or v_config is distinct from array['search_path=public']::text[]
     or v_acl is distinct from '{postgres=X/postgres,service_role=X/postgres}'
     or v_actual is distinct from 'ef89d686ebb3230ae4bef1b71d4860fd'
     or v_policy_comment is not null then
    raise exception 'T1_ROLLBACK_POST_STATUS_NOT_EXACT_BASELINE';
  end if;

  if not pg_catalog.has_function_privilege(
       v_service_role_oid,v_status_oid,'EXECUTE'
     )
     or pg_catalog.has_function_privilege(
       v_authenticated_oid,v_status_oid,'EXECUTE'
     ) then
    raise exception 'T1_ROLLBACK_POST_STATUS_EXECUTE_DRIFT';
  end if;

  select pg_catalog.md5(coalesce(c.relacl::text,''))
    into strict v_actual
  from pg_catalog.pg_class as c
  join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='corretores';

  if v_actual is distinct from 'afa3a93809a23f744356971cbc461855' then
    raise exception 'T1_ROLLBACK_POST_TABLE_ACL_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute as a
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and a.attacl is not null
  ) then
    raise exception 'T1_ROLLBACK_POST_COLUMN_ACL_PRESENT';
  end if;

  select p.polroles,
         p.polpermissive,
         p.polcmd,
         pg_catalog.obj_description(p.oid,'pg_policy'),
         pg_catalog.md5(
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
           || '|'
           || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
         )
    into strict v_policy_roles,
                v_policy_permissive,
                v_policy_cmd,
                v_policy_comment,
                v_actual
  from pg_catalog.pg_policy as p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update';

  if v_policy_cmd is distinct from 'w'
     or v_policy_permissive is distinct from true
     or v_policy_roles is distinct from array[0::oid]::oid[]
     or v_policy_comment is not null
     or v_actual is distinct from 'a3b9b4a44e859728ca9c69f6e6b2a842' then
    raise exception 'T1_ROLLBACK_POST_POLICY_DRIFT';
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
  ) <> 0 then
    raise exception 'T1_ROLLBACK_POST_T1_TRIGGER_PRESENT';
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
        ) is not null then
    raise exception 'T1_ROLLBACK_POST_T1_FUNCTION_PRESENT';
  end if;

  -- Critical audit surface must remain exactly at the baseline.
  select tg.oid,tg.tgenabled,tg.tgfoid,pg_catalog.pg_get_triggerdef(tg.oid,true)
    into strict v_audit_trigger_oid,v_audit_enabled,v_audit_fn_oid,v_audit_def
  from pg_catalog.pg_trigger as tg
  where tg.tgrelid='public.corretores'::regclass
    and tg.tgname='trg_audit_trail_corretores_critical_update'
    and not tg.tgisinternal;

  if v_audit_enabled is distinct from 'O'
     or v_audit_def is distinct from
       'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()' then
    raise exception 'T1_ROLLBACK_POST_CRITICAL_AUDIT_TRIGGER_DRIFT';
  end if;

  select p.proowner,
         p.prosecdef,
         p.proconfig,
         p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
    into strict v_owner,v_definer,v_config,v_acl,v_actual
  from pg_catalog.pg_proc as p
  where p.oid=v_audit_fn_oid;

  if v_owner is distinct from v_postgres_oid
     or v_definer is distinct from true
     or v_config is distinct from array['search_path=public']::text[]
     or v_acl is distinct from
       '{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}'
     or v_actual is distinct from '3fdaca39d55f348ca36f796023f3260b' then
    raise exception 'T1_ROLLBACK_POST_CRITICAL_AUDIT_FUNCTION_DRIFT';
  end if;
end;
$rollback_postflight$;

commit;
