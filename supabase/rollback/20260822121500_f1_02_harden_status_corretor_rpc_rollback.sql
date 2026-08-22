-- FECH.AI / F1-02 / T1
-- CANONICAL EXECUTABLE ROLLBACK
-- Supersedes every earlier rollback draft for this T1.
--
-- T1 OBJECT-SET CONTRACT v1 (FROZEN)
-- FUNCTION UNIVERSE:
--   exact public.atualizar_status_corretor(uuid,boolean,boolean)
--   UNION every public function whose name starts t1_
--   UNION every public function carrying marker F1-02-T1-v3|...
-- EXPECTED PRE-ROLLBACK FUNCTION SET: exactly 5 objects.
-- TRIGGER UNIVERSE:
--   every non-internal trigger in schema public whose name starts trg_t1_
--   UNION every such trigger carrying marker F1-02-T1-v3|...
--   UNION every such trigger bound to a T1 trigger function.
-- EXPECTED PRE-ROLLBACK TRIGGER SET: exactly 2 objects.
-- EXPECTED POST-ROLLBACK T1 SET: empty.
--
-- NOT AUTOMATIC. Production execution requires a separate explicit authorization.
-- One transaction: preflight -> mutations -> postflight -> COMMIT.

begin;

do $pre$
declare
  v_postgres oid:=pg_catalog.to_regrole('postgres');
  v_auth oid:=pg_catalog.to_regrole('authenticated');
  v_status oid:=pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  v_root oid:=pg_catalog.to_regprocedure('public.t1_is_root_strict()');
  v_row oid:=pg_catalog.to_regprocedure(
    'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'
  );
  v_authority oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_authority_update()'
  );
  v_compat oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );
  v_actual text;
  v_marker text;
  v_policy_roles oid[];
  v_policy_permissive boolean;
  v_policy_cmd "char";
  v_audit_fn oid;
  v_audit_enabled "char";
  v_audit_def text;
  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_acl text;
  r record;
begin
  if v_postgres is null or v_auth is null then
    raise exception 'T1_RB_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null
     or pg_catalog.to_regclass('public.admins') is null then
    raise exception 'T1_RB_REQUIRED_TABLE_MISSING';
  end if;

  if v_status is null
     or v_root is null
     or v_row is null
     or v_authority is null
     or v_compat is null then
    raise exception 'T1_RB_EXPECTED_FUNCTION_MISSING';
  end if;

  -- EXACT FUNCTION SET: actual = expected.
  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and (
        p.oid=v_status
        or p.proname ~ '^t1_'
        or coalesce(pg_catalog.obj_description(p.oid,'pg_proc'),'')
             like 'F1-02-T1-v3|%'
      )
      and not (
        p.oid = any(array[v_status,v_root,v_row,v_authority,v_compat]::oid[])
      )
  ) then
    raise exception 'T1_RB_UNEXPECTED_T1_FUNCTION';
  end if;

  if (
    select count(*)
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and (
        p.oid=v_status
        or p.proname ~ '^t1_'
        or coalesce(pg_catalog.obj_description(p.oid,'pg_proc'),'')
             like 'F1-02-T1-v3|%'
      )
  ) <> 5 then
    raise exception 'T1_RB_FUNCTION_SET_NOT_EXACT';
  end if;

  -- Every expected function must also match its security fingerprint.
  for r in
    select p.oid,
           p.proowner,
           p.prosecdef,
           p.proconfig,
           p.proacl::text as acl_text,
           pg_catalog.obj_description(p.oid,'pg_proc') as marker,
           pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) as body_md5
    from pg_catalog.pg_proc p
    where p.oid=any(array[v_status,v_root,v_row,v_authority,v_compat]::oid[])
  loop
    if r.proowner is distinct from v_postgres
       or r.proconfig is distinct from array['search_path=pg_catalog']::text[]
       or r.marker not like 'F1-02-T1-v3|%'
       or r.body_md5 is distinct from pg_catalog.split_part(r.marker,'|',2) then
      raise exception 'T1_RB_FUNCTION_METADATA_OR_BODY_DRIFT';
    end if;

    if r.oid=any(array[v_status,v_root,v_row]::oid[]) then
      if r.prosecdef is distinct from true
         or r.acl_text is distinct from
           '{postgres=X/postgres,authenticated=X/postgres}' then
        raise exception 'T1_RB_CALLABLE_FUNCTION_ACL_DRIFT';
      end if;
    else
      if r.prosecdef is distinct from false
         or r.acl_text is distinct from '{postgres=X/postgres}' then
        raise exception 'T1_RB_TRIGGER_FUNCTION_ACL_DRIFT';
      end if;
    end if;
  end loop;

  -- EXACT TRIGGER SET: actual = expected across the public schema.
  if exists (
    select 1
    from pg_catalog.pg_trigger tg
    join pg_catalog.pg_class c on c.oid=tg.tgrelid
    join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and not tg.tgisinternal
      and (
        tg.tgname ~ '^trg_t1_'
        or coalesce(pg_catalog.obj_description(tg.oid,'pg_trigger'),'')
             like 'F1-02-T1-v3|%'
        or tg.tgfoid in (v_authority,v_compat)
      )
      and not (
        tg.tgrelid='public.corretores'::regclass
        and (
          (tg.tgname='trg_t1_guard_corretores_authority_update'
           and tg.tgfoid=v_authority)
          or
          (tg.tgname='trg_t1_guard_corretores_direct_compat_update'
           and tg.tgfoid=v_compat)
        )
      )
  ) then
    raise exception 'T1_RB_UNEXPECTED_T1_TRIGGER';
  end if;

  if (
    select count(*)
    from pg_catalog.pg_trigger tg
    join pg_catalog.pg_class c on c.oid=tg.tgrelid
    join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and not tg.tgisinternal
      and (
        tg.tgname ~ '^trg_t1_'
        or coalesce(pg_catalog.obj_description(tg.oid,'pg_trigger'),'')
             like 'F1-02-T1-v3|%'
        or tg.tgfoid in (v_authority,v_compat)
      )
  ) <> 2 then
    raise exception 'T1_RB_TRIGGER_SET_NOT_EXACT';
  end if;

  for r in
    select tg.tgname,
           tg.tgfoid,
           tg.tgenabled,
           pg_catalog.obj_description(tg.oid,'pg_trigger') as marker,
           pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true)) as def_md5
    from pg_catalog.pg_trigger tg
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
      raise exception 'T1_RB_TRIGGER_METADATA_OR_BODY_DRIFT';
    end if;

    if r.tgname='trg_t1_guard_corretores_authority_update'
       and r.tgfoid is distinct from v_authority then
      raise exception 'T1_RB_AUTHORITY_TRIGGER_BINDING_DRIFT';
    end if;

    if r.tgname='trg_t1_guard_corretores_direct_compat_update'
       and r.tgfoid is distinct from v_compat then
      raise exception 'T1_RB_COMPAT_TRIGGER_BINDING_DRIFT';
    end if;
  end loop;

  -- T1 policy exact metadata + expression marker/hash.
  select pg_catalog.obj_description(p.oid,'pg_policy'),
         pg_catalog.md5(
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
           || '|'
           || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
         ),
         p.polroles,p.polpermissive,p.polcmd
    into strict v_marker,v_actual,
                v_policy_roles,v_policy_permissive,v_policy_cmd
  from pg_catalog.pg_policy p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update';

  if v_policy_cmd is distinct from 'w'
     or v_policy_permissive is distinct from true
     or v_policy_roles is distinct from array[0::oid]::oid[]
     or v_marker not like 'F1-02-T1-v3|%'
     or v_actual is distinct from pg_catalog.split_part(v_marker,'|',2) then
    raise exception 'T1_RB_POLICY_DRIFT';
  end if;

  -- T1 target grants.
  select c.relacl::text
    into strict v_actual
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='corretores';

  if v_actual is distinct from
     '{postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres,authenticated=r/postgres}' then
    raise exception 'T1_RB_TABLE_ACL_DRIFT';
  end if;

  if (
    select count(*)
    from pg_catalog.pg_attribute a
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and a.attacl is not null
  ) <> 3 then
    raise exception 'T1_RB_COLUMN_ACL_COUNT_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute a
    cross join lateral pg_catalog.aclexplode(a.attacl) x
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and (
        a.attname not in ('ativo','apto_para_receber','must_change_password')
        or x.grantor is distinct from v_postgres
        or x.grantee is distinct from v_auth
        or x.privilege_type is distinct from 'UPDATE'
        or x.is_grantable is distinct from false
      )
  ) then
    raise exception 'T1_RB_COLUMN_ACL_DRIFT';
  end if;

  if (
    select count(*)
    from pg_catalog.pg_attribute a
    cross join lateral pg_catalog.aclexplode(a.attacl) x
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and a.attacl is not null
  ) <> 3 then
    raise exception 'T1_RB_COLUMN_ACL_ENTRY_DRIFT';
  end if;

  -- Critical audit surface exact baseline.
  select tg.tgenabled,tg.tgfoid,pg_catalog.pg_get_triggerdef(tg.oid,true)
    into strict v_audit_enabled,v_audit_fn,v_audit_def
  from pg_catalog.pg_trigger tg
  where tg.tgrelid='public.corretores'::regclass
    and tg.tgname='trg_audit_trail_corretores_critical_update'
    and not tg.tgisinternal;

  if v_audit_enabled is distinct from 'O'
     or v_audit_def is distinct from
       'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()' then
    raise exception 'T1_RB_AUDIT_TRIGGER_DRIFT';
  end if;

  select p.proowner,p.prosecdef,p.proconfig,p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
    into strict v_owner,v_definer,v_config,v_acl,v_actual
  from pg_catalog.pg_proc p
  where p.oid=v_audit_fn;

  if v_owner is distinct from v_postgres
     or v_definer is distinct from true
     or v_config is distinct from array['search_path=public']::text[]
     or v_acl is distinct from
       '{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}'
     or v_actual is distinct from '3fdaca39d55f348ca36f796023f3260b' then
    raise exception 'T1_RB_AUDIT_FUNCTION_DRIFT';
  end if;
end;
$pre$;

-- Restore pre-T1 surface.
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
as $restore$
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
$restore$;

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

do $post$
declare
  v_postgres oid:=pg_catalog.to_regrole('postgres');
  v_auth oid:=pg_catalog.to_regrole('authenticated');
  v_service oid:=pg_catalog.to_regrole('service_role');
  v_status oid:=pg_catalog.to_regprocedure(
    'public.atualizar_status_corretor(uuid,boolean,boolean)'
  );
  v_actual text;
  v_comment text;
  v_policy_roles oid[];
  v_policy_permissive boolean;
  v_policy_cmd "char";
  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_acl text;
  v_audit_fn oid;
  v_audit_enabled "char";
  v_audit_def text;
begin
  if v_status is null then
    raise exception 'T1_RB_POST_STATUS_MISSING';
  end if;

  select p.proowner,p.prosecdef,p.proconfig,p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
         pg_catalog.obj_description(p.oid,'pg_proc')
    into strict v_owner,v_definer,v_config,v_acl,v_actual,v_comment
  from pg_catalog.pg_proc p
  where p.oid=v_status;

  if v_owner is distinct from v_postgres
     or v_definer is distinct from true
     or v_config is distinct from array['search_path=public']::text[]
     or v_acl is distinct from '{postgres=X/postgres,service_role=X/postgres}'
     or v_actual is distinct from 'ef89d686ebb3230ae4bef1b71d4860fd'
     or v_comment is not null
     or not pg_catalog.has_function_privilege(v_service,v_status,'EXECUTE')
     or pg_catalog.has_function_privilege(v_auth,v_status,'EXECUTE') then
    raise exception 'T1_RB_POST_STATUS_BASELINE_DRIFT';
  end if;

  select pg_catalog.md5(coalesce(c.relacl::text,''))
    into strict v_actual
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='corretores';

  if v_actual is distinct from 'afa3a93809a23f744356971cbc461855' then
    raise exception 'T1_RB_POST_TABLE_ACL_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid='public.corretores'::regclass
      and a.attnum>0
      and not a.attisdropped
      and a.attacl is not null
  ) then
    raise exception 'T1_RB_POST_COLUMN_ACL_PRESENT';
  end if;

  select p.polroles,p.polpermissive,p.polcmd,
         pg_catalog.obj_description(p.oid,'pg_policy'),
         pg_catalog.md5(
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'')
           || '|'
           || coalesce(pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),'')
         )
    into strict v_policy_roles,v_policy_permissive,v_policy_cmd,
                v_comment,v_actual
  from pg_catalog.pg_policy p
  where p.polrelid='public.corretores'::regclass
    and p.polname='corretores_update';

  if v_policy_cmd is distinct from 'w'
     or v_policy_permissive is distinct from true
     or v_policy_roles is distinct from array[0::oid]::oid[]
     or v_comment is not null
     or v_actual is distinct from 'a3b9b4a44e859728ca9c69f6e6b2a842' then
    raise exception 'T1_RB_POST_POLICY_DRIFT';
  end if;

  -- Frozen contract: T1 function namespace must be empty.
  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and (
        p.proname ~ '^t1_'
        or coalesce(pg_catalog.obj_description(p.oid,'pg_proc'),'')
             like 'F1-02-T1-v3|%'
      )
  ) then
    raise exception 'T1_RB_POST_T1_FUNCTION_SET_NOT_EMPTY';
  end if;

  -- Frozen contract: T1 trigger namespace must be empty.
  if exists (
    select 1
    from pg_catalog.pg_trigger tg
    join pg_catalog.pg_class c on c.oid=tg.tgrelid
    join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    join pg_catalog.pg_proc p on p.oid=tg.tgfoid
    where n.nspname='public'
      and not tg.tgisinternal
      and (
        tg.tgname ~ '^trg_t1_'
        or coalesce(pg_catalog.obj_description(tg.oid,'pg_trigger'),'')
             like 'F1-02-T1-v3|%'
        or p.proname ~ '^t1_'
        or coalesce(pg_catalog.obj_description(p.oid,'pg_proc'),'')
             like 'F1-02-T1-v3|%'
      )
  ) then
    raise exception 'T1_RB_POST_T1_TRIGGER_SET_NOT_EMPTY';
  end if;

  -- Critical audit surface must still equal baseline.
  select tg.tgenabled,tg.tgfoid,pg_catalog.pg_get_triggerdef(tg.oid,true)
    into strict v_audit_enabled,v_audit_fn,v_audit_def
  from pg_catalog.pg_trigger tg
  where tg.tgrelid='public.corretores'::regclass
    and tg.tgname='trg_audit_trail_corretores_critical_update'
    and not tg.tgisinternal;

  if v_audit_enabled is distinct from 'O'
     or v_audit_def is distinct from
       'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()' then
    raise exception 'T1_RB_POST_AUDIT_TRIGGER_DRIFT';
  end if;

  select p.proowner,p.prosecdef,p.proconfig,p.proacl::text,
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
    into strict v_owner,v_definer,v_config,v_acl,v_actual
  from pg_catalog.pg_proc p
  where p.oid=v_audit_fn;

  if v_owner is distinct from v_postgres
     or v_definer is distinct from true
     or v_config is distinct from array['search_path=public']::text[]
     or v_acl is distinct from
       '{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}'
     or v_actual is distinct from '3fdaca39d55f348ca36f796023f3260b' then
    raise exception 'T1_RB_POST_AUDIT_FUNCTION_DRIFT';
  end if;
end;
$post$;

commit;
