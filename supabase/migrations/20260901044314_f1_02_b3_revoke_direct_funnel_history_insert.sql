-- FECH.AI — F1-02 / B3
-- Eliminate authenticated direct funnel-history INSERT while preserving the
-- controlled SECURITY DEFINER writer boundary established by M1-C-F01.
--
-- VERSIONED ARTIFACT ONLY. This file is not authorization to apply to Supabase.

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';
set local idle_in_transaction_session_timeout = '60s';
set local search_path = 'pg_catalog', 'public';

lock table public.funil_movimentacoes in access exclusive mode;

do $f1_02_b3_preflight$
declare
  v_rls boolean;
  v_force_rls boolean;
  v_count integer;
  v_rows bigint;
  v_null bigint;
  v_lead bigint;
  v_broker bigint;
  v_stage bigint;
  v_previous_stage bigint;
begin
  if pg_catalog.to_regrole('authenticated') is null
     or pg_catalog.to_regrole('service_role') is null
     or pg_catalog.to_regclass('public.funil_movimentacoes') is null
     or pg_catalog.to_regclass('public.leads') is null
     or pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.funil_estagios') is null then
    raise exception 'F1_02_B3_PREFLIGHT_REQUIRED_OBJECT_OR_ROLE_MISSING';
  end if;

  select c.relrowsecurity, c.relforcerowsecurity
    into v_rls, v_force_rls
  from pg_catalog.pg_class c
  where c.oid = 'public.funil_movimentacoes'::pg_catalog.regclass;

  if v_rls is distinct from true or v_force_rls is distinct from true then
    raise exception 'F1_02_B3_PREFLIGHT_RLS_DRIFT rls=% force=%',
      v_rls, v_force_rls;
  end if;

  if not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     )
     or not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'SELECT'
     ) then
    raise exception 'F1_02_B3_PREFLIGHT_AUTHENTICATED_ACL_DRIFT';
  end if;

  select count(*)
    into v_count
  from pg_catalog.pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'funil_movimentacoes'
    and p.policyname = 'funil_mov_insert'
    and p.permissive = 'PERMISSIVE'
    and p.roles = '{public}'::name[]
    and p.cmd = 'INSERT'
    and p.qual is null
    and p.with_check = '(is_root() OR (corretor_id = my_corretor_id()))';

  if v_count <> 1 then
    raise exception 'F1_02_B3_PREFLIGHT_INSERT_POLICY_DRIFT matches=%', v_count;
  end if;

  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and c.contype = 'f'
    and c.convalidated
    and (
      (c.conname = 'fk_m1_c_f01_funil_mov_lead_empresa'
       and pg_catalog.pg_get_constraintdef(c.oid, true) =
         'FOREIGN KEY (lead_id, empresa_id) REFERENCES leads(id, empresa_id) ON DELETE CASCADE')
      or (c.conname = 'fk_m1_c_f01_funil_mov_corretor_empresa'
       and pg_catalog.pg_get_constraintdef(c.oid, true) =
         'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id)')
      or (c.conname = 'fk_m1_c_f01_funil_mov_estagio_empresa'
       and pg_catalog.pg_get_constraintdef(c.oid, true) =
         'FOREIGN KEY (estagio_id, empresa_id) REFERENCES funil_estagios(id, empresa_id)')
      or (c.conname = 'fk_m1_c_f01_funil_mov_estagio_anterior_empresa'
       and pg_catalog.pg_get_constraintdef(c.oid, true) =
         'FOREIGN KEY (estagio_anterior_id, empresa_id) REFERENCES funil_estagios(id, empresa_id)')
    );

  if v_count <> 4 then
    raise exception 'F1_02_B3_PREFLIGHT_COMPOSITE_FK_DRIFT matches=%', v_count;
  end if;

  select count(*)
    into v_count
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and not t.tgisinternal;

  if v_count <> 0 then
    raise exception 'F1_02_B3_PREFLIGHT_UNEXPECTED_TRIGGER count=%', v_count;
  end if;

  select
    count(*),
    count(*) filter (where fm.empresa_id is null),
    count(*) filter (where fm.empresa_id is distinct from l.empresa_id),
    count(*) filter (where fm.empresa_id is distinct from c.empresa_id),
    count(*) filter (where fm.empresa_id is distinct from fe.empresa_id),
    count(*) filter (
      where fm.estagio_anterior_id is not null
        and fm.empresa_id is distinct from fp.empresa_id
    )
  into v_rows, v_null, v_lead, v_broker, v_stage, v_previous_stage
  from public.funil_movimentacoes fm
  join public.leads l on l.id = fm.lead_id
  join public.corretores c on c.id = fm.corretor_id
  join public.funil_estagios fe on fe.id = fm.estagio_id
  left join public.funil_estagios fp on fp.id = fm.estagio_anterior_id;

  if v_null <> 0 or v_lead <> 0 or v_broker <> 0
     or v_stage <> 0 or v_previous_stage <> 0 then
    raise exception
      'F1_02_B3_PREFLIGHT_TENANT_INTEGRITY rows=% null=% lead=% broker=% stage=% previous=%',
      v_rows, v_null, v_lead, v_broker, v_stage, v_previous_stage;
  end if;

  perform pg_catalog.set_config('fechai.f1_02_b3_row_count', v_rows::text, true);
end;
$f1_02_b3_preflight$;

revoke insert on table public.funil_movimentacoes from authenticated;
drop policy funil_mov_insert on public.funil_movimentacoes;

do $f1_02_b3_postflight$
declare
  v_rls boolean;
  v_force_rls boolean;
  v_count integer;
  v_rows_before bigint;
  v_rows_after bigint;
  v_signature text;
  v_definition_md5 text;
  v_acl_md5 text;
  v_expected_definition_md5 text;
  v_expected_acl_md5 text;
begin
  if pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     ) then
    raise exception 'F1_02_B3_POSTFLIGHT_AUTHENTICATED_INSERT_PRESENT';
  end if;

  if not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'SELECT'
     ) then
    raise exception 'F1_02_B3_POSTFLIGHT_AUTHENTICATED_SELECT_LOST';
  end if;

  if exists (
    select 1 from pg_catalog.pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'funil_movimentacoes'
      and p.policyname = 'funil_mov_insert'
  ) then
    raise exception 'F1_02_B3_POSTFLIGHT_INSERT_POLICY_PRESENT';
  end if;

  select c.relrowsecurity, c.relforcerowsecurity
    into v_rls, v_force_rls
  from pg_catalog.pg_class c
  where c.oid = 'public.funil_movimentacoes'::pg_catalog.regclass;

  if v_rls is distinct from true or v_force_rls is distinct from true then
    raise exception 'F1_02_B3_POSTFLIGHT_RLS_DRIFT';
  end if;

  select count(*) into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and c.convalidated
    and c.conname in (
      'fk_m1_c_f01_funil_mov_lead_empresa',
      'fk_m1_c_f01_funil_mov_corretor_empresa',
      'fk_m1_c_f01_funil_mov_estagio_empresa',
      'fk_m1_c_f01_funil_mov_estagio_anterior_empresa'
    );
  if v_count <> 4 then
    raise exception 'F1_02_B3_POSTFLIGHT_COMPOSITE_FK_LOST count=%', v_count;
  end if;

  select count(*) into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and c.convalidated
    and c.conname in (
      'funil_movimentacoes_lead_id_fkey',
      'funil_movimentacoes_corretor_id_fkey',
      'funil_movimentacoes_estagio_id_fkey',
      'funil_movimentacoes_estagio_anterior_id_fkey',
      'funil_movimentacoes_empresa_id_fkey'
    );
  if v_count <> 5 then
    raise exception 'F1_02_B3_POSTFLIGHT_ORIGINAL_FK_LOST count=%', v_count;
  end if;

  select count(*) into v_count
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and not t.tgisinternal;
  if v_count <> 0 then
    raise exception 'F1_02_B3_POSTFLIGHT_UNEXPECTED_TRIGGER count=%', v_count;
  end if;

  v_rows_before := pg_catalog.current_setting('fechai.f1_02_b3_row_count')::bigint;
  select count(*) into v_rows_after from public.funil_movimentacoes;
  if v_rows_after <> v_rows_before then
    raise exception 'F1_02_B3_POSTFLIGHT_DATA_MUTATION before=% after=%',
      v_rows_before, v_rows_after;
  end if;

  for v_signature, v_expected_definition_md5, v_expected_acl_md5 in
    select * from (values
      ('mover_funil(uuid,uuid,text)',
       'dab988abbd2d50ae57159cc4110051d8', '06c8bd810f2d9a52a993cd903c13793a'),
      ('mover_funil_lote(uuid[],uuid,text)',
       '0d91aba2b42839a6f970a6b00da260d7', '06c8bd810f2d9a52a993cd903c13793a'),
      ('mover_funil_batch(uuid[],uuid,text)',
       '5ffe44e37519a624db32ee6789193700', 'db23e67d6fad77fdfa003856d807d6af'),
      ('registrar_feedback(uuid,text,text)',
       '3a6282c898199abc6c497a8cdfb5d16f', '06c8bd810f2d9a52a993cd903c13793a')
    ) expected(signature, definition_md5, acl_md5)
  loop
    select
      pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
      pg_catalog.md5(coalesce(p.proacl::text, ''))
    into v_definition_md5, v_acl_md5
    from pg_catalog.pg_proc p
    where p.oid = pg_catalog.to_regprocedure(v_signature);

    if v_definition_md5 is distinct from v_expected_definition_md5
       or v_acl_md5 is distinct from v_expected_acl_md5 then
      raise exception 'F1_02_B3_POSTFLIGHT_WRITER_DRIFT signature=%', v_signature;
    end if;
  end loop;

  if not pg_catalog.has_function_privilege(
       'authenticated', 'public.mover_funil(uuid,uuid,text)', 'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       'authenticated', 'public.mover_funil_lote(uuid[],uuid,text)', 'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       'authenticated', 'public.registrar_feedback(uuid,text,text)', 'EXECUTE'
     )
     or pg_catalog.has_function_privilege(
       'authenticated', 'public.mover_funil_batch(uuid[],uuid,text)', 'EXECUTE'
     ) then
    raise exception 'F1_02_B3_POSTFLIGHT_WRITER_EXECUTE_DRIFT';
  end if;
end;
$f1_02_b3_postflight$;

commit;
