-- FECH.AI — F1-02 / B3 read-only proof
-- Proves catalog state only. It performs no DDL or DML and does not establish a
-- runtime-negative PASS. Production adversarial testing remains unauthorized.

begin read only;

set local statement_timeout = '60s';
set local search_path = 'pg_catalog', 'public';

do $f1_02_b3_readonly_proof$
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
  v_signature text;
  v_definition_md5 text;
  v_acl_md5 text;
  v_expected_definition_md5 text;
  v_expected_acl_md5 text;
  v_role text;
  v_privilege text;
begin
  if pg_catalog.to_regclass('public.funil_movimentacoes') is null then
    raise exception 'F1_02_B3_PROOF_TABLE_MISSING';
  end if;

  select c.relrowsecurity, c.relforcerowsecurity
    into v_rls, v_force_rls
  from pg_catalog.pg_class c
  where c.oid = 'public.funil_movimentacoes'::pg_catalog.regclass;
  if v_rls is distinct from true or v_force_rls is distinct from true then
    raise exception 'F1_02_B3_PROOF_RLS_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     ) then
    raise exception 'F1_02_B3_PROOF_AUTHENTICATED_INSERT_PRESENT';
  end if;

  if pg_catalog.has_any_column_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     ) then
    raise exception 'F1_02_B3_PROOF_AUTHENTICATED_COLUMN_INSERT_PRESENT';
  end if;

  if not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'SELECT'
     ) then
    raise exception 'F1_02_B3_PROOF_AUTHENTICATED_SELECT_MISSING';
  end if;

  foreach v_role in array array['service_role', 'postgres']
  loop
    foreach v_privilege in array array[
      'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE',
      'REFERENCES', 'TRIGGER', 'MAINTAIN'
    ]
    loop
      if not pg_catalog.has_table_privilege(
           v_role, 'public.funil_movimentacoes', v_privilege
         ) then
        raise exception 'F1_02_B3_PROOF_PRIVILEGED_ROLE_ACL_DRIFT role=% privilege=%',
          v_role, v_privilege;
      end if;
    end loop;
  end loop;

  if exists (
    select 1 from pg_catalog.pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'funil_movimentacoes'
      and p.policyname = 'funil_mov_insert'
  ) then
    raise exception 'F1_02_B3_PROOF_INSERT_POLICY_PRESENT';
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
    raise exception 'F1_02_B3_PROOF_COMPOSITE_FK_DRIFT count=%', v_count;
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
    raise exception 'F1_02_B3_PROOF_ORIGINAL_FK_DRIFT count=%', v_count;
  end if;

  select count(*) into v_count
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and not t.tgisinternal;
  if v_count <> 0 then
    raise exception 'F1_02_B3_PROOF_UNEXPECTED_TRIGGER count=%', v_count;
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
      raise exception 'F1_02_B3_PROOF_WRITER_DRIFT signature=%', v_signature;
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
    raise exception 'F1_02_B3_PROOF_WRITER_EXECUTE_DRIFT';
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
      'F1_02_B3_PROOF_TENANT_INTEGRITY rows=% null=% lead=% broker=% stage=% previous=%',
      v_rows, v_null, v_lead, v_broker, v_stage, v_previous_stage;
  end if;
end;
$f1_02_b3_readonly_proof$;

rollback;

-- ESTABLISHES: static/catalog boundary and preserved relationship integrity.
-- DOES NOT ESTABLISH: runtime-negative PASS, Security Go, or production apply.
