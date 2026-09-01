-- FECH.AI
-- M1-C-F01 / FUNIL TENANT INTEGRITY
-- READ-ONLY proof artifact.
--
-- AUTHORITY BOUNDARY:
--   * VERSIONED ARTIFACT ONLY. NOT AUTHORIZED FOR PRODUCTION EXECUTION.
--   * This proof performs no INSERT/UPDATE/DELETE/DDL.
--   * No transactional fixture or adversarial production write is used.
--   * RUNTIME_NEGATIVE_PROOF = NOT_ESTABLISHED.
--   * STATIC_SOURCE_PROOF + LIVE_READ_ONLY_CATALOG_PROOF +
--     DATA_COMPATIBILITY_PROOF are the intended evidence classes.
--
-- Expected use only after a separately authorized migration application.

begin read only;

-- ---------------------------------------------------------------------------
-- 1. Structural catalog proof.
-- ---------------------------------------------------------------------------

do $m1_c_f01_catalog_proof$
declare
  v_count integer;
  v_bool boolean;
  v_text text;
  v_cfg text[];
begin
  -- Parent candidate keys.
  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where (
    c.conrelid='public.leads'::regclass
    and c.conname='uq_m1_c_f01_leads_id_empresa_id'
    and c.contype='u'
    and c.convalidated
    and pg_catalog.pg_get_constraintdef(c.oid,true)=
        'UNIQUE (id, empresa_id)'
  ) or (
    c.conrelid='public.funil_estagios'::regclass
    and c.conname='uq_m1_c_f01_funil_estagios_id_empresa_id'
    and c.contype='u'
    and c.convalidated
    and pg_catalog.pg_get_constraintdef(c.oid,true)=
        'UNIQUE (id, empresa_id)'
  );

  if v_count <> 2 then
    raise exception
      'M1_C_F01_PROOF_PARENT_KEYS expected=2 found=%',
      v_count;
  end if;

  -- Existing corretores tenant key must remain valid and unchanged.
  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_text
  from pg_catalog.pg_constraint c
  where c.conrelid='public.corretores'::regclass
    and c.conname='uq_appsec_m1_003_corretores_id_empresa_id'
    and c.contype='u'
    and c.convalidated;

  if v_text is distinct from 'UNIQUE (id, empresa_id)' then
    raise exception
      'M1_C_F01_PROOF_CORRETORES_PARENT_KEY def=%',
      v_text;
  end if;

  -- Four exact validated tenant-aware child FKs.
  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.contype='f'
    and c.convalidated
    and (
      (
        c.conname='fk_m1_c_f01_funil_mov_lead_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid,true)=
          'FOREIGN KEY (lead_id, empresa_id) REFERENCES leads(id, empresa_id) ON DELETE CASCADE'
      )
      or
      (
        c.conname='fk_m1_c_f01_funil_mov_corretor_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid,true)=
          'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id)'
      )
      or
      (
        c.conname='fk_m1_c_f01_funil_mov_estagio_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid,true)=
          'FOREIGN KEY (estagio_id, empresa_id) REFERENCES funil_estagios(id, empresa_id)'
      )
      or
      (
        c.conname='fk_m1_c_f01_funil_mov_estagio_anterior_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid,true)=
          'FOREIGN KEY (estagio_anterior_id, empresa_id) REFERENCES funil_estagios(id, empresa_id)'
      )
    );

  if v_count <> 4 then
    raise exception
      'M1_C_F01_PROOF_COMPOSITE_FKS expected=4 found=%',
      v_count;
  end if;

  -- Tenant columns must be non-nullable.
  select a.attnotnull
    into v_bool
  from pg_catalog.pg_attribute a
  where a.attrelid='public.funil_movimentacoes'::regclass
    and a.attname='empresa_id'
    and a.attnum>0
    and not a.attisdropped;

  if v_bool is distinct from true then
    raise exception
      'M1_C_F01_PROOF_MOVEMENT_EMPRESA_NOT_NULL';
  end if;

  select a.attnotnull
    into v_bool
  from pg_catalog.pg_attribute a
  where a.attrelid='public.funil_estagios'::regclass
    and a.attname='empresa_id'
    and a.attnum>0
    and not a.attisdropped;

  if v_bool is distinct from true then
    raise exception
      'M1_C_F01_PROOF_STAGE_EMPRESA_NOT_NULL';
  end if;

  -- Existing single-column FKs must still exist; the P0 does not rewrite
  -- historical relation semantics unnecessarily.
  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.convalidated
    and c.conname in (
      'funil_movimentacoes_lead_id_fkey',
      'funil_movimentacoes_corretor_id_fkey',
      'funil_movimentacoes_estagio_id_fkey',
      'funil_movimentacoes_estagio_anterior_id_fkey',
      'funil_movimentacoes_empresa_id_fkey'
    );

  if v_count <> 5 then
    raise exception
      'M1_C_F01_PROOF_ORIGINAL_FKS_PRESERVED expected=5 found=%',
      v_count;
  end if;

  -- No trigger was introduced for an invariant expressible declaratively.
  select count(*)
    into v_count
  from pg_catalog.pg_trigger t
  where t.tgrelid='public.funil_movimentacoes'::regclass
    and not t.tgisinternal;

  if v_count <> 0 then
    raise exception
      'M1_C_F01_PROOF_UNEXPECTED_TRIGGER count=%',
      v_count;
  end if;
end;
$m1_c_f01_catalog_proof$;

-- ---------------------------------------------------------------------------
-- 2. RLS / ACL / policy proof.
-- ---------------------------------------------------------------------------

do $m1_c_f01_authz_proof$
declare
  v_rls boolean;
  v_force boolean;
  v_count integer;
  v_policy_total integer;
begin
  select c.relrowsecurity, c.relforcerowsecurity
    into v_rls, v_force
  from pg_catalog.pg_class c
  where c.oid='public.funil_movimentacoes'::regclass;

  if v_rls is distinct from true
     or v_force is distinct from true then
    raise exception
      'M1_C_F01_PROOF_RLS_REGRESSION rls=% force=%',
      v_rls, v_force;
  end if;

  -- Exact semantic table ACL set, independent of aclitem[] ordering.
  if exists (
    with expected(grantee, privilege_type, is_grantable) as (
      values
        ('postgres','INSERT',false),
        ('postgres','SELECT',false),
        ('postgres','UPDATE',false),
        ('postgres','DELETE',false),
        ('postgres','TRUNCATE',false),
        ('postgres','REFERENCES',false),
        ('postgres','TRIGGER',false),
        ('postgres','MAINTAIN',false),
        ('service_role','INSERT',false),
        ('service_role','SELECT',false),
        ('service_role','UPDATE',false),
        ('service_role','DELETE',false),
        ('service_role','TRUNCATE',false),
        ('service_role','REFERENCES',false),
        ('service_role','TRIGGER',false),
        ('service_role','MAINTAIN',false),
        ('authenticated','INSERT',false),
        ('authenticated','SELECT',false)
    ),
    actual as (
      select
        case when x.grantee=0 then 'PUBLIC' else r.rolname::text end as grantee,
        x.privilege_type,
        x.is_grantable
      from pg_catalog.pg_class c
      cross join lateral pg_catalog.aclexplode(c.relacl) x
      left join pg_catalog.pg_roles r on r.oid=x.grantee
      where c.oid='public.funil_movimentacoes'::regclass
    )
    (
      select grantee, privilege_type, is_grantable from actual
      except
      select grantee, privilege_type, is_grantable from expected
    )
    union all
    (
      select grantee, privilege_type, is_grantable from expected
      except
      select grantee, privilege_type, is_grantable from actual
    )
  ) then
    raise exception
      'M1_C_F01_PROOF_TABLE_ACL_SEMANTIC_DRIFT';
  end if;

  select count(*)
    into v_policy_total
  from pg_catalog.pg_policies p
  where p.schemaname='public'
    and p.tablename='funil_movimentacoes';

  if v_policy_total <> 2 then
    raise exception
      'M1_C_F01_PROOF_POLICY_SET_DRIFT expected_total=2 found=%',
      v_policy_total;
  end if;

  select count(*)
    into v_count
  from pg_catalog.pg_policies p
  where p.schemaname='public'
    and p.tablename='funil_movimentacoes'
    and p.roles = '{public}'::name[]
    and (
      (
        p.policyname='funil_mov_insert'
        and p.permissive='PERMISSIVE'
        and p.cmd='INSERT'
        and p.qual is null
        and p.with_check='(is_root() OR (corretor_id = my_corretor_id()))'
      )
      or
      (
        p.policyname='funil_mov_select'
        and p.permissive='PERMISSIVE'
        and p.cmd='SELECT'
        and p.qual='(is_root() OR (corretor_id = my_corretor_id()))'
        and p.with_check is null
      )
    );

  if v_count <> 2 then
    raise exception
      'M1_C_F01_PROOF_POLICY_DEFINITION_DRIFT expected_matches=2 found=%',
      v_count;
  end if;

  -- This P0 does not claim the policy is complete same-tenant authorization.
  -- It proves only that the approved policy set was not widened or changed.
end;
$m1_c_f01_authz_proof$;

-- ---------------------------------------------------------------------------
-- 3. Writer proof.
-- ---------------------------------------------------------------------------

do $m1_c_f01_writer_proof$
declare
  v_def text;
  v_cfg text[];
  v_owner text;
  v_definer boolean;
begin
  select
    pg_catalog.pg_get_functiondef(p.oid),
    p.proconfig,
    pg_get_userbyid(p.proowner),
    p.prosecdef
  into v_def, v_cfg, v_owner, v_definer
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_estagio_id uuid, p_observacao text';

  if v_def is null
     or v_owner is distinct from 'postgres'
     or v_definer is distinct from true
     or v_cfg is distinct from array['search_path=pg_catalog, public']::text[] then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_SECURITY_BOUNDARY owner=% definer=% config=%',
      v_owner, v_definer, v_cfg;
  end if;

  if position('for update of l' in lower(v_def))=0 then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_LOCK_MISSING';
  end if;

  if position('v_lead_empresa_id' in lower(v_def))=0
     or position('insert into public.funil_movimentacoes' in lower(v_def))=0
     or position('empresa_id' in lower(v_def))=0 then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_TENANT_WRITE_CONTRACT';
  end if;

  if not has_function_privilege(
       'authenticated',
       'public.mover_funil(uuid,uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_AUTH_EXECUTE_MISSING';
  end if;

  if has_function_privilege(
       'anon',
       'public.mover_funil(uuid,uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_ANON_EXECUTE_PRESENT';
  end if;

  if not has_function_privilege(
       'service_role',
       'public.mover_funil(uuid,uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_SERVICE_EXECUTE_MISSING';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.mover_funil_batch(uuid[],uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_PROOF_LEGACY_BATCH_AUTH_EXECUTE_PRESENT';
  end if;

  if not has_function_privilege(
       'service_role',
       'public.mover_funil_batch(uuid[],uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_PROOF_LEGACY_BATCH_SERVICE_EXECUTE_UNEXPECTEDLY_REMOVED';
  end if;

  -- Exact semantic function ACL sets: reject unexpected grantees/privileges.
  if exists (
    with expected(grantee, privilege_type, is_grantable) as (
      values
        ('postgres','EXECUTE',false),
        ('service_role','EXECUTE',false),
        ('authenticated','EXECUTE',false)
    ),
    actual as (
      select
        case when x.grantee=0 then 'PUBLIC' else r.rolname::text end as grantee,
        x.privilege_type,
        x.is_grantable
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      cross join lateral pg_catalog.aclexplode(p.proacl) x
      left join pg_catalog.pg_roles r on r.oid=x.grantee
      where n.nspname='public'
        and p.proname='mover_funil'
        and pg_catalog.pg_get_function_identity_arguments(p.oid)=
            'p_lead_id uuid, p_estagio_id uuid, p_observacao text'
    )
    (
      select grantee, privilege_type, is_grantable from actual
      except
      select grantee, privilege_type, is_grantable from expected
    )
    union all
    (
      select grantee, privilege_type, is_grantable from expected
      except
      select grantee, privilege_type, is_grantable from actual
    )
  ) then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_ACL_SEMANTIC_DRIFT';
  end if;

  if exists (
    with expected(grantee, privilege_type, is_grantable) as (
      values
        ('postgres','EXECUTE',false),
        ('service_role','EXECUTE',false)
    ),
    actual as (
      select
        case when x.grantee=0 then 'PUBLIC' else r.rolname::text end as grantee,
        x.privilege_type,
        x.is_grantable
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      cross join lateral pg_catalog.aclexplode(p.proacl) x
      left join pg_catalog.pg_roles r on r.oid=x.grantee
      where n.nspname='public'
        and p.proname='mover_funil_batch'
        and pg_catalog.pg_get_function_identity_arguments(p.oid)=
            'p_lead_ids uuid[], p_estagio_id uuid, p_observacao text'
    )
    (
      select grantee, privilege_type, is_grantable from actual
      except
      select grantee, privilege_type, is_grantable from expected
    )
    union all
    (
      select grantee, privilege_type, is_grantable from expected
      except
      select grantee, privilege_type, is_grantable from actual
    )
  ) then
    raise exception
      'M1_C_F01_PROOF_MOVER_FUNIL_BATCH_ACL_SEMANTIC_DRIFT';
  end if;
end;
$m1_c_f01_writer_proof$;

-- ---------------------------------------------------------------------------
-- 4. Read-only data-compatibility proof.
-- ---------------------------------------------------------------------------

do $m1_c_f01_data_proof$
declare
  v_total bigint;
  v_null bigint;
  v_lead bigint;
  v_corretor bigint;
  v_stage bigint;
  v_prev bigint;
begin
  with a as (
    select
      fm.estagio_anterior_id,
      fm.empresa_id,
      l.empresa_id as lead_empresa,
      c.empresa_id as corretor_empresa,
      fe.empresa_id as stage_empresa,
      fp.id as previous_stage_id,
      fp.empresa_id as previous_stage_empresa
    from public.funil_movimentacoes fm
    join public.leads l on l.id=fm.lead_id
    join public.corretores c on c.id=fm.corretor_id
    join public.funil_estagios fe on fe.id=fm.estagio_id
    left join public.funil_estagios fp on fp.id=fm.estagio_anterior_id
  )
  select
    count(*),
    count(*) filter (where empresa_id is null),
    count(*) filter (
      where empresa_id is not null
        and empresa_id is distinct from lead_empresa
    ),
    count(*) filter (
      where empresa_id is not null
        and empresa_id is distinct from corretor_empresa
    ),
    count(*) filter (
      where empresa_id is not null
        and empresa_id is distinct from stage_empresa
    ),
    count(*) filter (
      where estagio_anterior_id is not null
        and (
          previous_stage_id is null
          or previous_stage_empresa is null
          or empresa_id is distinct from previous_stage_empresa
        )
    )
  into v_total, v_null, v_lead, v_corretor, v_stage, v_prev
  from a;

  if v_null <> 0
     or v_lead <> 0
     or v_corretor <> 0
     or v_stage <> 0
     or v_prev <> 0 then
    raise exception
      'M1_C_F01_PROOF_DATA_INVARIANT total=% null=% lead=% corretor=% stage=% previous=%',
      v_total, v_null, v_lead, v_corretor, v_stage, v_prev;
  end if;

  if exists (
    select 1
    from public.funil_estagios fe
    where fe.empresa_id is null
  ) then
    raise exception
      'M1_C_F01_PROOF_NULL_STAGE_DOMAIN_REGRESSION';
  end if;
end;
$m1_c_f01_data_proof$;

-- ---------------------------------------------------------------------------
-- 5. Evidence boundary.
-- ---------------------------------------------------------------------------
--
-- PASSING THIS FILE MAY ESTABLISH:
--   * catalog structure at execution time;
--   * validated composite relationship constraints;
--   * RLS/FORCE/policy/ACL preservation;
--   * writer security-definition markers;
--   * zero observed tenant-relationship mismatches.
--
-- PASSING THIS FILE DOES NOT ESTABLISH:
--   * adversarial runtime-negative PASS;
--   * complete same-tenant movement authorization;
--   * absence of every external/non-versioned writer;
--   * Security Go.
--
-- SAME_TENANT_MOVEMENT_FORGERY_RISK remains a separate residual finding while
-- authenticated direct INSERT is intentionally retained.

rollback;
