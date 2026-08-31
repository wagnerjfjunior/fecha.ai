-- FECH.AI
-- M1-C-F01 / FUNIL TENANT INTEGRITY
-- Target-design implementation candidate.
--
-- AUTHORITY BOUNDARY:
--   * VERSIONED ARTIFACT ONLY. NOT AUTHORIZED FOR APPLICATION.
--   * No cleanup DML is performed.
--   * Existing anomalous history must be resolved under separate Product
--     Authority before this migration can pass its fail-before-DDL preflight.
--   * RUNTIME_NEGATIVE_PROOF = NOT_ESTABLISHED.
--
-- Principal risk:
--   public.funil_movimentacoes must not contain tenant-inconsistent
--   lead/corretor/current-stage/previous-stage relationships.
--
-- Target invariant:
--   movement.empresa_id IS NOT NULL
--   movement.empresa_id = lead.empresa_id
--   movement.empresa_id = corretor.empresa_id
--   movement.empresa_id = current_stage.empresa_id
--   and, when previous_stage exists,
--   movement.empresa_id = previous_stage.empresa_id
--
-- No ROOT relational bypass.
-- No trigger.
-- Existing RLS/FORCE RLS and policies are intentionally preserved.
-- Existing single-column FKs are intentionally preserved.
-- authenticated direct INSERT remains a separate authorization-hardening risk;
-- this migration makes cross-tenant relationship combinations structurally
-- invalid but does not claim complete same-tenant authorization closure.

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- 1. Exact live-baseline preflight.
-- ---------------------------------------------------------------------------

do $m1_c_f01_baseline$
declare
  v_count integer;
  v_policy_total integer;
  v_md5 text;
  v_owner text;
  v_prosecdef boolean;
  v_proconfig text[];
  v_rls boolean;
  v_force boolean;
begin
  if to_regclass('public.funil_movimentacoes') is null
     or to_regclass('public.funil_estagios') is null
     or to_regclass('public.leads') is null
     or to_regclass('public.corretores') is null then
    raise exception 'M1_C_F01_PREFLIGHT_MISSING_REQUIRED_RELATION';
  end if;

  select pg_get_userbyid(c.relowner), c.relrowsecurity, c.relforcerowsecurity
    into v_owner, v_rls, v_force
  from pg_catalog.pg_class c
  where c.oid = 'public.funil_movimentacoes'::regclass;

  if v_owner is distinct from 'postgres'
     or v_rls is distinct from true
     or v_force is distinct from true then
    raise exception
      'M1_C_F01_PREFLIGHT_FUNIL_MOV_BOUNDARY_DRIFT owner=% rls=% force=%',
      v_owner, v_rls, v_force;
  end if;

  -- Compare ACLs as unordered semantic grantee/privilege sets.
  if exists (
    with expected(grantee, privilege_type) as (
      values
        ('postgres','INSERT'),
        ('postgres','SELECT'),
        ('postgres','UPDATE'),
        ('postgres','DELETE'),
        ('postgres','TRUNCATE'),
        ('postgres','REFERENCES'),
        ('postgres','TRIGGER'),
        ('postgres','MAINTAIN'),
        ('service_role','INSERT'),
        ('service_role','SELECT'),
        ('service_role','UPDATE'),
        ('service_role','DELETE'),
        ('service_role','REFERENCES'),
        ('service_role','TRIGGER'),
        ('service_role','MAINTAIN'),
        ('authenticated','INSERT'),
        ('authenticated','SELECT')
    ),
    actual as (
      select
        case when x.grantee=0 then 'PUBLIC' else r.rolname::text end as grantee,
        x.privilege_type
      from pg_catalog.pg_class c
      cross join lateral pg_catalog.aclexplode(c.relacl) x
      left join pg_catalog.pg_roles r on r.oid=x.grantee
      where c.oid='public.funil_movimentacoes'::regclass
    )
    (
      select grantee, privilege_type from actual
      except
      select grantee, privilege_type from expected
    )
    union all
    (
      select grantee, privilege_type from expected
      except
      select grantee, privilege_type from actual
    )
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_FUNIL_MOV_ACL_SEMANTIC_DRIFT';
  end if;

  select count(*)
    into v_policy_total
  from pg_catalog.pg_policies p
  where p.schemaname='public'
    and p.tablename='funil_movimentacoes';

  if v_policy_total <> 2 then
    raise exception
      'M1_C_F01_PREFLIGHT_POLICY_SET_DRIFT expected_total=2 found=%',
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
      'M1_C_F01_PREFLIGHT_POLICY_DEFINITION_DRIFT expected_matches=2 found=%',
      v_count;
  end if;

  select
    md5(pg_catalog.pg_get_functiondef(p.oid)),
    pg_get_userbyid(p.proowner),
    p.prosecdef,
    p.proconfig
  into v_md5, v_owner, v_prosecdef, v_proconfig
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_estagio_id uuid, p_observacao text';

  if v_md5 is distinct from 'eaf0a69a4f85b3c8268c6c4d2d370111'
     or v_owner is distinct from 'postgres'
     or v_prosecdef is distinct from true
     or v_proconfig is distinct from array['search_path=public']::text[] then
    raise exception
      'M1_C_F01_PREFLIGHT_MOVER_FUNIL_DRIFT md5=% owner=% definer=% config=%',
      v_md5, v_owner, v_prosecdef, v_proconfig;
  end if;

  if exists (
    with expected(grantee, privilege_type) as (
      values
        ('postgres','EXECUTE'),
        ('service_role','EXECUTE'),
        ('authenticated','EXECUTE')
    ),
    actual as (
      select
        case when x.grantee=0 then 'PUBLIC' else r.rolname::text end as grantee,
        x.privilege_type
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
      select grantee, privilege_type from actual
      except
      select grantee, privilege_type from expected
    )
    union all
    (
      select grantee, privilege_type from expected
      except
      select grantee, privilege_type from actual
    )
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_MOVER_FUNIL_ACL_SEMANTIC_DRIFT';
  end if;

  select
    md5(pg_catalog.pg_get_functiondef(p.oid)),
    pg_get_userbyid(p.proowner),
    p.prosecdef,
    p.proconfig
  into v_md5, v_owner, v_prosecdef, v_proconfig
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil_batch'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_ids uuid[], p_estagio_id uuid, p_observacao text';

  if v_md5 is distinct from '5ffe44e37519a624db32ee6789193700'
     or v_owner is distinct from 'postgres'
     or v_prosecdef is distinct from true
     or v_proconfig is distinct from array['search_path=public']::text[] then
    raise exception
      'M1_C_F01_PREFLIGHT_MOVER_FUNIL_BATCH_DRIFT md5=% owner=% definer=% config=%',
      v_md5, v_owner, v_prosecdef, v_proconfig;
  end if;

  if exists (
    with expected(grantee, privilege_type) as (
      values
        ('postgres','EXECUTE'),
        ('service_role','EXECUTE'),
        ('authenticated','EXECUTE')
    ),
    actual as (
      select
        case when x.grantee=0 then 'PUBLIC' else r.rolname::text end as grantee,
        x.privilege_type
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
      select grantee, privilege_type from actual
      except
      select grantee, privilege_type from expected
    )
    union all
    (
      select grantee, privilege_type from expected
      except
      select grantee, privilege_type from actual
    )
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_MOVER_FUNIL_BATCH_ACL_SEMANTIC_DRIFT';
  end if;

  select md5(pg_catalog.pg_get_functiondef(p.oid))
    into v_md5
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil_lote'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_ids uuid[], p_estagio_id uuid, p_observacao text';

  if v_md5 is distinct from '0d91aba2b42839a6f970a6b00da260d7' then
    raise exception
      'M1_C_F01_PREFLIGHT_MOVER_FUNIL_LOTE_DRIFT md5=%',
      v_md5;
  end if;

  select md5(pg_catalog.pg_get_functiondef(p.oid))
    into v_md5
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='registrar_feedback'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_feedback text, p_observacao text';

  if v_md5 is distinct from '3a6282c898199abc6c497a8cdfb5d16f' then
    raise exception
      'M1_C_F01_PREFLIGHT_REGISTRAR_FEEDBACK_DRIFT md5=%',
      v_md5;
  end if;

  if has_schema_privilege('authenticated','public','CREATE')
     or has_schema_privilege('anon','public','CREATE')
     or has_schema_privilege('public','public','CREATE') then
    raise exception
      'M1_C_F01_PREFLIGHT_PUBLIC_SCHEMA_CREATE_DRIFT';
  end if;
end;
$m1_c_f01_baseline$;

-- ---------------------------------------------------------------------------
-- 2. Acquire bounded write locks before compatibility checks so the
--    application-time invariant cannot drift between preflight and DDL.
--    lock_timeout makes contention fail closed instead of waiting indefinitely.
-- ---------------------------------------------------------------------------

lock table public.corretores in share row exclusive mode;
lock table public.leads in share row exclusive mode;
lock table public.funil_estagios in share row exclusive mode;
lock table public.funil_movimentacoes in share row exclusive mode;

-- ---------------------------------------------------------------------------
-- 3. Data-compatibility preflight.
--    NO repair is performed. Current design-time evidence contains known
--    incompatible historical rows, so an application today MUST stop here.
-- ---------------------------------------------------------------------------

do $m1_c_f01_data$
begin
  if exists (
    select 1
    from public.funil_estagios fe
    where fe.empresa_id is null
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_GLOBAL_OR_NULL_STAGE_REQUIRES_AUTHORITY';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    where fm.empresa_id is null
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_UNRESOLVED_NULL_MOVEMENT_EMPRESA';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    join public.leads l on l.id=fm.lead_id
    where fm.empresa_id is distinct from l.empresa_id
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_LEAD_TENANT_MISMATCH';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    join public.corretores c on c.id=fm.corretor_id
    where fm.empresa_id is distinct from c.empresa_id
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_CORRETOR_TENANT_MISMATCH';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    join public.funil_estagios fe on fe.id=fm.estagio_id
    where fm.empresa_id is distinct from fe.empresa_id
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_CURRENT_STAGE_TENANT_MISMATCH';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    left join public.funil_estagios fe on fe.id=fm.estagio_anterior_id
    where fm.estagio_anterior_id is not null
      and (
        fe.id is null
        or fe.empresa_id is null
        or fm.empresa_id is distinct from fe.empresa_id
      )
  ) then
    raise exception
      'M1_C_F01_PREFLIGHT_PREVIOUS_STAGE_TENANT_MISMATCH';
  end if;
end;
$m1_c_f01_data$;

-- ---------------------------------------------------------------------------
-- 4. Parent candidate keys.
-- ---------------------------------------------------------------------------

do $m1_c_f01_parent_keys$
declare
  v_def text;
begin
  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.corretores'::regclass
    and c.conname='uq_appsec_m1_003_corretores_id_empresa_id';

  if v_def is distinct from 'UNIQUE (id, empresa_id)' then
    raise exception
      'M1_C_F01_REQUIRED_CORRETORES_KEY_DRIFT def=%',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.leads'::regclass
    and c.conname='uq_m1_c_f01_leads_id_empresa_id';

  if found then
    if v_def <> 'UNIQUE (id, empresa_id)' then
      raise exception
        'M1_C_F01_CONSTRAINT_NAME_COLLISION uq_m1_c_f01_leads_id_empresa_id=%',
        v_def;
    end if;
  else
    alter table public.leads
      add constraint uq_m1_c_f01_leads_id_empresa_id
      unique (id,empresa_id);
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_estagios'::regclass
    and c.conname='uq_m1_c_f01_funil_estagios_id_empresa_id';

  if found then
    if v_def <> 'UNIQUE (id, empresa_id)' then
      raise exception
        'M1_C_F01_CONSTRAINT_NAME_COLLISION uq_m1_c_f01_funil_estagios_id_empresa_id=%',
        v_def;
    end if;
  else
    alter table public.funil_estagios
      add constraint uq_m1_c_f01_funil_estagios_id_empresa_id
      unique (id,empresa_id);
  end if;
end;
$m1_c_f01_parent_keys$;

-- Target domain rejects NULL/global stages and tenantless movements.
alter table public.funil_estagios
  alter column empresa_id set not null;

alter table public.funil_movimentacoes
  alter column empresa_id set not null;

-- ---------------------------------------------------------------------------
-- 5. Canonical writer: lead-derived tenant, lead-row serialization,
--    no ROOT relational bypass.
-- ---------------------------------------------------------------------------

create or replace function public.mover_funil(
  p_lead_id uuid,
  p_estagio_id uuid,
  p_observacao text default ''::text
)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_actor_user_id uuid;
  v_corretor_id uuid;
  v_lead_empresa_id uuid;
  v_estagio_atual_id uuid;
  v_nome_estagio text;
begin
  v_actor_user_id := auth.uid();

  if v_actor_user_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'AUTH_REQUIRED',
      'error', 'Usuário não autenticado'
    );
  end if;

  -- One query establishes actor-in-tenant authority and locks the target lead
  -- before deriving security-relevant previous-stage state.
  select l.empresa_id, l.funil_estagio_id, c.id
    into v_lead_empresa_id, v_estagio_atual_id, v_corretor_id
  from public.leads l
  join public.corretores c
    on c.user_id = v_actor_user_id
   and c.empresa_id = l.empresa_id
   and coalesce(c.ativo,true) = true
  where l.id = p_lead_id
    and (
      l.corretor_id = c.id
      or public.is_gestor()
      or public.is_admin_local()
      or public.is_root()
    )
  for update of l;

  if v_lead_empresa_id is null or v_corretor_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'SEM_PERMISSAO_LEAD',
      'error', 'Lead não encontrado ou sem permissão'
    );
  end if;

  if v_estagio_atual_id is not null
     and not exists (
       select 1
       from public.funil_estagios fe
       where fe.id = v_estagio_atual_id
         and fe.empresa_id = v_lead_empresa_id
     ) then
    return jsonb_build_object(
      'ok', false,
      'code', 'ESTAGIO_ANTERIOR_INCONSISTENTE',
      'error', 'Estágio anterior incompatível com a empresa do lead'
    );
  end if;

  select fe.nome
    into v_nome_estagio
  from public.funil_estagios fe
  where fe.id = p_estagio_id
    and fe.empresa_id = v_lead_empresa_id
  limit 1;

  if v_nome_estagio is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'ESTAGIO_TENANT_FORBIDDEN',
      'error', 'Estágio não encontrado para a empresa do lead'
    );
  end if;

  update public.leads
  set funil_estagio_id = p_estagio_id,
      funil_atualizado_em = now(),
      updated_at = now()
  where id = p_lead_id
    and empresa_id = v_lead_empresa_id;

  if not found then
    return jsonb_build_object(
      'ok', false,
      'code', 'UPDATE_BLOQUEADO',
      'error', 'Atualização bloqueada por isolamento de empresa'
    );
  end if;

  insert into public.funil_movimentacoes (
    lead_id,
    corretor_id,
    estagio_id,
    estagio_anterior_id,
    observacao,
    empresa_id
  )
  values (
    p_lead_id,
    v_corretor_id,
    p_estagio_id,
    v_estagio_atual_id,
    p_observacao,
    v_lead_empresa_id
  );

  return jsonb_build_object('ok',true,'estagio',v_nome_estagio);
end;
$function$;

-- Preserve owner and existing intended principals; no privilege widening.
alter function public.mover_funil(uuid,uuid,text) owner to postgres;
revoke all on function public.mover_funil(uuid,uuid,text) from public, anon;
grant execute on function public.mover_funil(uuid,uuid,text)
  to authenticated, service_role;

-- Legacy/superseded authenticated writer: preserve object for traceability,
-- but remove authenticated execution. No DROP and no invented new behavior.
revoke execute on function
  public.mover_funil_batch(uuid[],uuid,text)
  from authenticated;

-- ---------------------------------------------------------------------------
-- 6. Tenant-aware child constraints.
-- ---------------------------------------------------------------------------

do $m1_c_f01_child_fks$
declare
  v_def text;
begin
  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.conname='fk_m1_c_f01_funil_mov_lead_empresa';

  if found then
    if v_def not in (
      'FOREIGN KEY (lead_id, empresa_id) REFERENCES leads(id, empresa_id) ON DELETE CASCADE',
      'FOREIGN KEY (lead_id, empresa_id) REFERENCES leads(id, empresa_id) ON DELETE CASCADE NOT VALID'
    ) then
      raise exception
        'M1_C_F01_CONSTRAINT_NAME_COLLISION fk_m1_c_f01_funil_mov_lead_empresa=%',
        v_def;
    end if;
  else
    alter table public.funil_movimentacoes
      add constraint fk_m1_c_f01_funil_mov_lead_empresa
      foreign key (lead_id,empresa_id)
      references public.leads(id,empresa_id)
      on delete cascade
      not valid;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.conname='fk_m1_c_f01_funil_mov_corretor_empresa';

  if found then
    if v_def not in (
      'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id)',
      'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id) NOT VALID'
    ) then
      raise exception
        'M1_C_F01_CONSTRAINT_NAME_COLLISION fk_m1_c_f01_funil_mov_corretor_empresa=%',
        v_def;
    end if;
  else
    alter table public.funil_movimentacoes
      add constraint fk_m1_c_f01_funil_mov_corretor_empresa
      foreign key (corretor_id,empresa_id)
      references public.corretores(id,empresa_id)
      not valid;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.conname='fk_m1_c_f01_funil_mov_estagio_empresa';

  if found then
    if v_def not in (
      'FOREIGN KEY (estagio_id, empresa_id) REFERENCES funil_estagios(id, empresa_id)',
      'FOREIGN KEY (estagio_id, empresa_id) REFERENCES funil_estagios(id, empresa_id) NOT VALID'
    ) then
      raise exception
        'M1_C_F01_CONSTRAINT_NAME_COLLISION fk_m1_c_f01_funil_mov_estagio_empresa=%',
        v_def;
    end if;
  else
    alter table public.funil_movimentacoes
      add constraint fk_m1_c_f01_funil_mov_estagio_empresa
      foreign key (estagio_id,empresa_id)
      references public.funil_estagios(id,empresa_id)
      not valid;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid,true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.conname='fk_m1_c_f01_funil_mov_estagio_anterior_empresa';

  if found then
    if v_def not in (
      'FOREIGN KEY (estagio_anterior_id, empresa_id) REFERENCES funil_estagios(id, empresa_id)',
      'FOREIGN KEY (estagio_anterior_id, empresa_id) REFERENCES funil_estagios(id, empresa_id) NOT VALID'
    ) then
      raise exception
        'M1_C_F01_CONSTRAINT_NAME_COLLISION fk_m1_c_f01_funil_mov_estagio_anterior_empresa=%',
        v_def;
    end if;
  else
    alter table public.funil_movimentacoes
      add constraint fk_m1_c_f01_funil_mov_estagio_anterior_empresa
      foreign key (estagio_anterior_id,empresa_id)
      references public.funil_estagios(id,empresa_id)
      not valid;
  end if;
end;
$m1_c_f01_child_fks$;

alter table public.funil_movimentacoes
  validate constraint fk_m1_c_f01_funil_mov_lead_empresa;
alter table public.funil_movimentacoes
  validate constraint fk_m1_c_f01_funil_mov_corretor_empresa;
alter table public.funil_movimentacoes
  validate constraint fk_m1_c_f01_funil_mov_estagio_empresa;
alter table public.funil_movimentacoes
  validate constraint fk_m1_c_f01_funil_mov_estagio_anterior_empresa;

-- ---------------------------------------------------------------------------
-- 7. Postflight: catalog/data proof only. No runtime-negative claim.
-- ---------------------------------------------------------------------------

do $m1_c_f01_postflight$
declare
  v_count integer;
  v_bool boolean;
  v_def text;
  v_cfg text[];
begin
  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where (
    c.conrelid='public.leads'::regclass
    and c.conname='uq_m1_c_f01_leads_id_empresa_id'
    and c.contype='u'
    and c.convalidated
    and pg_catalog.pg_get_constraintdef(c.oid,true)='UNIQUE (id, empresa_id)'
  ) or (
    c.conrelid='public.funil_estagios'::regclass
    and c.conname='uq_m1_c_f01_funil_estagios_id_empresa_id'
    and c.contype='u'
    and c.convalidated
    and pg_catalog.pg_get_constraintdef(c.oid,true)='UNIQUE (id, empresa_id)'
  );

  if v_count <> 2 then
    raise exception
      'M1_C_F01_POSTFLIGHT_PARENT_KEY_COUNT expected=2 found=%',
      v_count;
  end if;

  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid='public.funil_movimentacoes'::regclass
    and c.contype='f'
    and c.convalidated
    and c.conname in (
      'fk_m1_c_f01_funil_mov_lead_empresa',
      'fk_m1_c_f01_funil_mov_corretor_empresa',
      'fk_m1_c_f01_funil_mov_estagio_empresa',
      'fk_m1_c_f01_funil_mov_estagio_anterior_empresa'
    );

  if v_count <> 4 then
    raise exception
      'M1_C_F01_POSTFLIGHT_FK_COUNT expected=4 found=%',
      v_count;
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid='public.funil_movimentacoes'::regclass
      and a.attname='empresa_id'
      and a.attnotnull is false
      and a.attnum>0
      and not a.attisdropped
  ) then
    raise exception 'M1_C_F01_POSTFLIGHT_MOVEMENT_EMPRESA_STILL_NULLABLE';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid='public.funil_estagios'::regclass
      and a.attname='empresa_id'
      and a.attnotnull is false
      and a.attnum>0
      and not a.attisdropped
  ) then
    raise exception 'M1_C_F01_POSTFLIGHT_STAGE_EMPRESA_STILL_NULLABLE';
  end if;

  select c.relrowsecurity
    into v_bool
  from pg_catalog.pg_class c
  where c.oid='public.funil_movimentacoes'::regclass;
  if v_bool is distinct from true then
    raise exception 'M1_C_F01_POSTFLIGHT_RLS_DISABLED';
  end if;

  select c.relforcerowsecurity
    into v_bool
  from pg_catalog.pg_class c
  where c.oid='public.funil_movimentacoes'::regclass;
  if v_bool is distinct from true then
    raise exception 'M1_C_F01_POSTFLIGHT_FORCE_RLS_DISABLED';
  end if;

  select p.proconfig
    into v_cfg
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_estagio_id uuid, p_observacao text';

  if v_cfg is distinct from array['search_path=pg_catalog, public']::text[] then
    raise exception
      'M1_C_F01_POSTFLIGHT_MOVER_FUNIL_SEARCH_PATH config=%',
      v_cfg;
  end if;

  select pg_catalog.pg_get_functiondef(p.oid)
    into v_def
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_estagio_id uuid, p_observacao text';

  if position('for update of l' in lower(v_def))=0
     or position('empresa_id' in lower(v_def))=0
     or position('v_lead_empresa_id' in lower(v_def))=0 then
    raise exception 'M1_C_F01_POSTFLIGHT_MOVER_FUNIL_BODY_CONTRACT';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.mover_funil_batch(uuid[],uuid,text)',
       'EXECUTE'
     ) then
    raise exception 'M1_C_F01_POSTFLIGHT_BATCH_AUTH_EXECUTE_STILL_PRESENT';
  end if;

  if not has_function_privilege(
       'authenticated',
       'public.mover_funil(uuid,uuid,text)',
       'EXECUTE'
     ) then
    raise exception 'M1_C_F01_POSTFLIGHT_MOVER_FUNIL_AUTH_EXECUTE_MISSING';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    join public.leads l on l.id=fm.lead_id
    join public.corretores c on c.id=fm.corretor_id
    join public.funil_estagios fe on fe.id=fm.estagio_id
    left join public.funil_estagios fp on fp.id=fm.estagio_anterior_id
    where fm.empresa_id is null
       or fm.empresa_id is distinct from l.empresa_id
       or fm.empresa_id is distinct from c.empresa_id
       or fm.empresa_id is distinct from fe.empresa_id
       or (
         fm.estagio_anterior_id is not null
         and (
           fp.id is null
           or fp.empresa_id is null
           or fm.empresa_id is distinct from fp.empresa_id
         )
       )
  ) then
    raise exception 'M1_C_F01_POSTFLIGHT_DATA_INVARIANT_FAILED';
  end if;
end;
$m1_c_f01_postflight$;

commit;
