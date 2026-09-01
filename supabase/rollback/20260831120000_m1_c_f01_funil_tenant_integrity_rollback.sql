-- FECH.AI
-- M1-C-F01 / FUNIL TENANT INTEGRITY
-- SECURITY-SAFE COMPATIBILITY ROLLBACK.
--
-- AUTHORITY BOUNDARY:
--   * VERSIONED ARTIFACT ONLY. NOT AUTHORIZED FOR EXECUTION.
--   * This rollback intentionally DOES NOT remove tenant-aware constraints,
--     DOES NOT restore nullable tenant columns, and DOES NOT re-grant
--     authenticated EXECUTE on mover_funil_batch.
--   * Full structural rollback would reopen M1-C-F01 unless an equivalent
--     integrity control exists. That path requires a separate Product Authority
--     decision, writer quiescence and a separately reviewed rollback design.
--
-- What this rollback can do safely:
--   restore mover_funil closer to its pre-M1-C-F01 authorization/business flow
--   while preserving explicit empresa_id insertion and the structural tenant
--   invariant.
--
-- ROLLBACK_FEASIBLE = YES_WITH_STOP_CONDITIONS.

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- 1. Stop unless the post-migration structural invariant is still intact.
-- ---------------------------------------------------------------------------

do $m1_c_f01_rollback_preflight$
declare
  v_count integer;
  v_cfg text[];
  v_def text;
begin
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
      'M1_C_F01_ROLLBACK_STOP_STRUCTURAL_FKS_NOT_INTACT expected=4 found=%',
      v_count;
  end if;

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
      'M1_C_F01_ROLLBACK_STOP_PARENT_KEYS_NOT_INTACT expected=2 found=%',
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
    raise exception
      'M1_C_F01_ROLLBACK_STOP_MOVEMENT_EMPRESA_NULLABLE';
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
    raise exception
      'M1_C_F01_ROLLBACK_STOP_STAGE_EMPRESA_NULLABLE';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.mover_funil_batch(uuid[],uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_ROLLBACK_STOP_BATCH_AUTH_EXECUTE_ALREADY_PRESENT';
  end if;

  select p.proconfig, pg_catalog.pg_get_functiondef(p.oid)
    into v_cfg, v_def
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_estagio_id uuid, p_observacao text';

  if v_cfg is distinct from array['search_path=pg_catalog, public']::text[]
     or position('for update of l' in lower(v_def))=0
     or position('v_lead_empresa_id' in lower(v_def))=0 then
    raise exception
      'M1_C_F01_ROLLBACK_STOP_UNEXPECTED_MOVER_FUNIL_STATE config=%',
      v_cfg;
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
    raise exception
      'M1_C_F01_ROLLBACK_STOP_DATA_INVARIANT_NOT_CLEAN';
  end if;
end;
$m1_c_f01_rollback_preflight$;

lock table public.leads in share row exclusive mode;
lock table public.funil_estagios in share row exclusive mode;
lock table public.funil_movimentacoes in share row exclusive mode;

-- ---------------------------------------------------------------------------
-- 2. Compatibility writer rollback.
--
-- Restores the previous high-level flow:
--   actor empresa -> actor corretor -> lead tenant check -> stage check
-- while retaining:
--   * explicit movement empresa_id;
--   * hardened search_path;
--   * structural FK/NOT NULL enforcement;
--   * no batch authenticated execution.
--
-- This intentionally does NOT restore the exact unsafe pre-M1-C-F01 body,
-- because that body omitted empresa_id and would be incompatible with the
-- retained security invariant.
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
  v_corretor_id uuid;
  v_empresa_id uuid;
  v_estagio_atual_id uuid;
  v_nome_estagio text;
  v_lead_empresa_id uuid;
  v_estagio_empresa_id uuid;
begin
  v_empresa_id := public.my_empresa_id();

  if v_empresa_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'EMPRESA_NAO_IDENTIFICADA',
      'error', 'Empresa do usuário não identificada'
    );
  end if;

  select c.id
    into v_corretor_id
  from public.corretores c
  where c.user_id=auth.uid()
    and c.empresa_id=v_empresa_id
    and coalesce(c.ativo,true)=true
  limit 1;

  if v_corretor_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'CORRETOR_NAO_ENCONTRADO',
      'error', 'Corretor não encontrado'
    );
  end if;

  select l.empresa_id, l.funil_estagio_id
    into v_lead_empresa_id, v_estagio_atual_id
  from public.leads l
  where l.id=p_lead_id
  limit 1;

  if v_lead_empresa_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'LEAD_NAO_ENCONTRADO',
      'error', 'Lead não encontrado ou sem permissão'
    );
  end if;

  if v_lead_empresa_id <> v_empresa_id then
    return jsonb_build_object(
      'ok', false,
      'code', 'TENANT_FORBIDDEN',
      'error', 'Lead pertence a outra empresa'
    );
  end if;

  if not exists (
    select 1
    from public.leads l
    where l.id=p_lead_id
      and l.empresa_id=v_empresa_id
      and (
        l.corretor_id=v_corretor_id
        or public.is_gestor()
        or public.is_admin_local()
        or public.is_root()
      )
  ) then
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
       where fe.id=v_estagio_atual_id
         and fe.empresa_id=v_empresa_id
     ) then
    return jsonb_build_object(
      'ok', false,
      'code', 'ESTAGIO_ANTERIOR_INCONSISTENTE',
      'error', 'Estágio anterior incompatível com a empresa do lead'
    );
  end if;

  select fe.nome, fe.empresa_id
    into v_nome_estagio, v_estagio_empresa_id
  from public.funil_estagios fe
  where fe.id=p_estagio_id
  limit 1;

  if v_nome_estagio is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'ESTAGIO_NAO_ENCONTRADO',
      'error', 'Estágio não encontrado'
    );
  end if;

  if v_estagio_empresa_id is distinct from v_empresa_id then
    return jsonb_build_object(
      'ok', false,
      'code', 'ESTAGIO_TENANT_FORBIDDEN',
      'error', 'Estágio pertence a outra empresa'
    );
  end if;

  update public.leads
  set funil_estagio_id=p_estagio_id,
      funil_atualizado_em=now(),
      updated_at=now()
  where id=p_lead_id
    and empresa_id=v_empresa_id;

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
    v_empresa_id
  );

  return jsonb_build_object('ok',true,'estagio',v_nome_estagio);
end;
$function$;

alter function public.mover_funil(uuid,uuid,text) owner to postgres;
revoke all on function public.mover_funil(uuid,uuid,text) from public, anon;
grant execute on function public.mover_funil(uuid,uuid,text)
  to authenticated, service_role;

-- Keep legacy/superseded batch writer unavailable to authenticated callers.
revoke execute on function
  public.mover_funil_batch(uuid[],uuid,text)
  from authenticated;

-- ---------------------------------------------------------------------------
-- 3. Postflight: structural controls MUST remain.
-- ---------------------------------------------------------------------------

do $m1_c_f01_rollback_postflight$
declare
  v_count integer;
  v_cfg text[];
  v_def text;
begin
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
      'M1_C_F01_ROLLBACK_POSTFLIGHT_STRUCTURAL_FKS_LOST expected=4 found=%',
      v_count;
  end if;

  if has_function_privilege(
       'authenticated',
       'public.mover_funil_batch(uuid[],uuid,text)',
       'EXECUTE'
     ) then
    raise exception
      'M1_C_F01_ROLLBACK_POSTFLIGHT_BATCH_EXECUTE_REOPENED';
  end if;

  select p.proconfig, pg_catalog.pg_get_functiondef(p.oid)
    into v_cfg, v_def
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='mover_funil'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)=
        'p_lead_id uuid, p_estagio_id uuid, p_observacao text';

  if v_cfg is distinct from array['search_path=pg_catalog, public']::text[]
     or position('insert into public.funil_movimentacoes' in lower(v_def))=0
     or position('empresa_id' in lower(v_def))=0 then
    raise exception
      'M1_C_F01_ROLLBACK_POSTFLIGHT_WRITER_NOT_INVARIANT_COMPATIBLE config=%',
      v_cfg;
  end if;
end;
$m1_c_f01_rollback_postflight$;

-- Structural rollback intentionally not executed.
-- STOP: dropping the four tenant-aware FKs, restoring NULL tenant columns, or
-- re-granting mover_funil_batch would require a new, separately authorized
-- rollback plan proving an equivalent integrity control.

commit;
