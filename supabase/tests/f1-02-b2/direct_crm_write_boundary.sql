-- FECH.AI — F1-02 / B2 read-only catalog proof
-- Catalog/static assurance only.
--
-- Performs no DDL and no business DML.
-- RUNTIME_NEGATIVE_PASS remains NOT ESTABLISHED.
-- SECURITY_GO remains DENIED.

begin read only;

set local statement_timeout = '60s';
set local search_path = 'pg_catalog', 'public';

do $f1_02_b2_readonly_proof$
declare
  v_count integer;
  v_hash text;
  v_owner text;
  v_rls boolean;
  v_force_rls boolean;
  v_sig text;
  v_expected_def text;
  v_expected_acl text;
  v_oid oid;
  v_secdef boolean;
  v_actual_def text;
  v_actual_acl text;
begin
  if pg_catalog.to_regrole('authenticated') is null
     or pg_catalog.to_regrole('anon') is null
     or pg_catalog.to_regrole('service_role') is null
     or pg_catalog.to_regrole('postgres') is null then
    raise exception 'F1_02_B2_PROOF_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.leads') is null
     or pg_catalog.to_regclass('public.lotes') is null
     or pg_catalog.to_regclass('public.times') is null then
    raise exception 'F1_02_B2_PROOF_REQUIRED_TABLE_MISSING';
  end if;

  for v_sig in
    select unnest(array['public.leads','public.lotes','public.times'])
  loop
    select pg_catalog.pg_get_userbyid(c.relowner),
           c.relrowsecurity,
           c.relforcerowsecurity
      into v_owner,v_rls,v_force_rls
    from pg_catalog.pg_class c
    where c.oid=pg_catalog.to_regclass(v_sig);

    if v_owner is distinct from 'postgres'
       or v_rls is distinct from true
       or v_force_rls is distinct from true then
      raise exception
        'F1_02_B2_PROOF_TABLE_INVARIANT_DRIFT table=% owner=% rls=% force_rls=%',
        v_sig,v_owner,v_rls,v_force_rls;
    end if;
  end loop;

  -- Hardened authenticated direct-write boundary.
  if not pg_catalog.has_table_privilege('authenticated','public.leads','SELECT')
     or pg_catalog.has_table_privilege('authenticated','public.leads','INSERT')
     or pg_catalog.has_table_privilege('authenticated','public.leads','UPDATE')
     or pg_catalog.has_table_privilege('authenticated','public.leads','DELETE')
     or pg_catalog.has_any_column_privilege('authenticated','public.leads','INSERT')
     or pg_catalog.has_any_column_privilege('authenticated','public.leads','UPDATE') then
    raise exception 'F1_02_B2_PROOF_LEADS_DIRECT_WRITE_PRESENT';
  end if;

  if not pg_catalog.has_table_privilege('authenticated','public.lotes','SELECT')
     or pg_catalog.has_table_privilege('authenticated','public.lotes','INSERT')
     or pg_catalog.has_table_privilege('authenticated','public.lotes','UPDATE')
     or pg_catalog.has_table_privilege('authenticated','public.lotes','DELETE')
     or pg_catalog.has_any_column_privilege('authenticated','public.lotes','INSERT')
     or pg_catalog.has_any_column_privilege('authenticated','public.lotes','UPDATE') then
    raise exception 'F1_02_B2_PROOF_LOTES_DIRECT_WRITE_PRESENT';
  end if;

  if not pg_catalog.has_table_privilege('authenticated','public.times','SELECT')
     or pg_catalog.has_table_privilege('authenticated','public.times','INSERT')
     or pg_catalog.has_table_privilege('authenticated','public.times','UPDATE')
     or pg_catalog.has_table_privilege('authenticated','public.times','DELETE')
     or pg_catalog.has_any_column_privilege('authenticated','public.times','INSERT')
     or pg_catalog.has_any_column_privilege('authenticated','public.times','UPDATE') then
    raise exception 'F1_02_B2_PROOF_TIMES_DIRECT_WRITE_PRESENT';
  end if;

  -- Exact post-hardening ACL drift guards, in addition to semantic assertions.
  select pg_catalog.md5(coalesce(c.relacl::text,''))
    into v_hash from pg_catalog.pg_class c
  where c.oid='public.leads'::pg_catalog.regclass;
  if v_hash is distinct from '0382c9d760805ac4a3cfd8d6ca8a6951' then
    raise exception 'F1_02_B2_PROOF_LEADS_RELACL_DRIFT hash=%',v_hash;
  end if;

  select pg_catalog.md5(coalesce(c.relacl::text,''))
    into v_hash from pg_catalog.pg_class c
  where c.oid='public.lotes'::pg_catalog.regclass;
  if v_hash is distinct from '0382c9d760805ac4a3cfd8d6ca8a6951' then
    raise exception 'F1_02_B2_PROOF_LOTES_RELACL_DRIFT hash=%',v_hash;
  end if;

  select pg_catalog.md5(coalesce(c.relacl::text,''))
    into v_hash from pg_catalog.pg_class c
  where c.oid='public.times'::pg_catalog.regclass;
  if v_hash is distinct from 'b737d3eae6acb29657f866f2f8993734' then
    raise exception 'F1_02_B2_PROOF_TIMES_RELACL_DRIFT hash=%',v_hash;
  end if;

  select count(*)
    into v_count
  from pg_catalog.pg_attribute a
  cross join lateral pg_catalog.aclexplode(a.attacl) x
  where a.attrelid in (
          'public.leads'::pg_catalog.regclass,
          'public.lotes'::pg_catalog.regclass,
          'public.times'::pg_catalog.regclass
        )
    and a.attnum>0
    and not a.attisdropped
    and a.attacl is not null;
  if v_count<>0 then
    raise exception 'F1_02_B2_PROOF_COLUMN_ACL_PRESENT count=%',v_count;
  end if;

  if pg_catalog.has_table_privilege('anon','public.leads','INSERT')
     or pg_catalog.has_table_privilege('anon','public.leads','UPDATE')
     or pg_catalog.has_table_privilege('anon','public.leads','DELETE')
     or pg_catalog.has_table_privilege('anon','public.lotes','INSERT')
     or pg_catalog.has_table_privilege('anon','public.lotes','UPDATE')
     or pg_catalog.has_table_privilege('anon','public.lotes','DELETE')
     or pg_catalog.has_table_privilege('anon','public.times','INSERT')
     or pg_catalog.has_table_privilege('anon','public.times','UPDATE')
     or pg_catalog.has_table_privilege('anon','public.times','DELETE') then
    raise exception 'F1_02_B2_PROOF_ANON_WRITE_PRESENT';
  end if;

  for v_sig in
    select unnest(array['public.leads','public.lotes','public.times'])
  loop
    if not pg_catalog.has_table_privilege('service_role',v_sig,'SELECT')
       or not pg_catalog.has_table_privilege('service_role',v_sig,'INSERT')
       or not pg_catalog.has_table_privilege('service_role',v_sig,'UPDATE')
       or not pg_catalog.has_table_privilege('service_role',v_sig,'DELETE')
       or not pg_catalog.has_table_privilege('postgres',v_sig,'SELECT')
       or not pg_catalog.has_table_privilege('postgres',v_sig,'INSERT')
       or not pg_catalog.has_table_privilege('postgres',v_sig,'UPDATE')
       or not pg_catalog.has_table_privilege('postgres',v_sig,'DELETE') then
      raise exception 'F1_02_B2_PROOF_PRIVILEGED_ROLE_DRIFT table=%',v_sig;
    end if;
  end loop;

  -- Policies are intentionally unchanged/dormant.
  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           p.policyname || '|' || p.cmd || '|' || p.permissive::text || '|' ||
           coalesce(pg_catalog.array_to_string(p.roles,','),'') || '|' ||
           coalesce(p.qual,'') || '|' || coalesce(p.with_check,''),
           E'\n' order by p.policyname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_policies p
  where p.schemaname='public' and p.tablename='leads';
  if v_count<>3 or v_hash is distinct from '360bc33f4dd17937172e98da5203a220' then
    raise exception 'F1_02_B2_PROOF_LEADS_POLICY_DRIFT';
  end if;

  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           p.policyname || '|' || p.cmd || '|' || p.permissive::text || '|' ||
           coalesce(pg_catalog.array_to_string(p.roles,','),'') || '|' ||
           coalesce(p.qual,'') || '|' || coalesce(p.with_check,''),
           E'\n' order by p.policyname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_policies p
  where p.schemaname='public' and p.tablename='lotes';
  if v_count<>2 or v_hash is distinct from 'ac27dc669f8136de8004e03ff3ba2276' then
    raise exception 'F1_02_B2_PROOF_LOTES_POLICY_DRIFT';
  end if;

  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           p.policyname || '|' || p.cmd || '|' || p.permissive::text || '|' ||
           coalesce(pg_catalog.array_to_string(p.roles,','),'') || '|' ||
           coalesce(p.qual,'') || '|' || coalesce(p.with_check,''),
           E'\n' order by p.policyname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_policies p
  where p.schemaname='public' and p.tablename='times';
  if v_count<>3 or v_hash is distinct from '20cd727acb7a0b9475e0689949e26f84' then
    raise exception 'F1_02_B2_PROOF_TIMES_POLICY_DRIFT';
  end if;

  -- Trigger fingerprints.
  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           t.tgname || '|' || t.tgenabled::text || '|' ||
           t.tgfoid::pg_catalog.regprocedure::text,
           E'\n' order by t.tgname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_trigger t
  where t.tgrelid='public.leads'::pg_catalog.regclass and not t.tgisinternal;
  if v_count<>2 or v_hash is distinct from 'f1461871ed8742cda6091953c42159e7' then
    raise exception 'F1_02_B2_PROOF_LEADS_TRIGGER_DRIFT';
  end if;

  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           t.tgname || '|' || t.tgenabled::text || '|' ||
           t.tgfoid::pg_catalog.regprocedure::text,
           E'\n' order by t.tgname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_trigger t
  where t.tgrelid='public.lotes'::pg_catalog.regclass and not t.tgisinternal;
  if v_count<>0 or v_hash is distinct from 'd41d8cd98f00b204e9800998ecf8427e' then
    raise exception 'F1_02_B2_PROOF_LOTES_TRIGGER_DRIFT';
  end if;

  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           t.tgname || '|' || t.tgenabled::text || '|' ||
           t.tgfoid::pg_catalog.regprocedure::text,
           E'\n' order by t.tgname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_trigger t
  where t.tgrelid='public.times'::pg_catalog.regclass and not t.tgisinternal;
  if v_count<>2 or v_hash is distinct from '3b96724deabeb92d0eedd53e617d5625' then
    raise exception 'F1_02_B2_PROOF_TIMES_TRIGGER_DRIFT';
  end if;

  -- FK fingerprints.
  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           co.conname || '|' || co.convalidated::text || '|' ||
           pg_catalog.pg_get_constraintdef(co.oid,true),
           E'\n' order by co.conname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_constraint co
  where co.conrelid='public.leads'::pg_catalog.regclass and co.contype='f';
  if v_count<>13 or v_hash is distinct from '3fc58a96da3b1235dc5af1cbb5f49a57' then
    raise exception 'F1_02_B2_PROOF_LEADS_FK_DRIFT';
  end if;

  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           co.conname || '|' || co.convalidated::text || '|' ||
           pg_catalog.pg_get_constraintdef(co.oid,true),
           E'\n' order by co.conname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_constraint co
  where co.conrelid='public.lotes'::pg_catalog.regclass and co.contype='f';
  if v_count<>4 or v_hash is distinct from '69573308b1550d317555724642bb6365' then
    raise exception 'F1_02_B2_PROOF_LOTES_FK_DRIFT';
  end if;

  select count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           co.conname || '|' || co.convalidated::text || '|' ||
           pg_catalog.pg_get_constraintdef(co.oid,true),
           E'\n' order by co.conname
         ),''))
    into v_count,v_hash
  from pg_catalog.pg_constraint co
  where co.conrelid='public.times'::pg_catalog.regclass and co.contype='f';
  if v_count<>2 or v_hash is distinct from 'ff8a1effa1eb4df4f52361ab3dc3d651' then
    raise exception 'F1_02_B2_PROOF_TIMES_FK_DRIFT';
  end if;

  -- Required compatibility writer definitions and EXECUTE boundaries.
  for v_sig,v_expected_def,v_expected_acl in
    select *
    from (values
      ('public.atualizar_feedback(uuid,text,text)','57ba2f5d9cbc65cbbd9ed213265b184c','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.distribuir_lotes()','0132905fc1942b219b0e96d82e6407d6','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.excluir_lista(uuid)','80ef746e48f99479367049e687e78119','d1707186c8e5f1577bde2338d7541aec'),
      ('public.importar_leads_batch(uuid,jsonb,text)','8f8f2c8b8593a54068783c7ddd4a84ee','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.mover_funil(uuid,uuid,text)','dab988abbd2d50ae57159cc4110051d8','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.mover_funil_lote(uuid[],uuid,text)','0d91aba2b42839a6f970a6b00da260d7','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.proximo_lead()','d0d185f14f3be1ee7d550bff5991613f','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.registrar_feedback(uuid,text,text)','3a6282c898199abc6c497a8cdfb5d16f','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.registrar_mensagem(uuid,text,integer)','6649911ef54c546dab9207206a650c31','06c8bd810f2d9a52a993cd903c13793a'),
      ('public.solicitar_lote(uuid)','f0adebaa3878c7f4c841c19ca5bd4743','d1707186c8e5f1577bde2338d7541aec'),
      ('public.trocar_lista(uuid,integer)','715dc6724fd73e94e7414cb67707c80c','d1707186c8e5f1577bde2338d7541aec')
    ) as x(signature,expected_def,expected_acl)
  loop
    v_oid:=pg_catalog.to_regprocedure(v_sig);
    if v_oid is null then
      raise exception 'F1_02_B2_PROOF_WRITER_MISSING signature=%',v_sig;
    end if;

    select p.prosecdef,
           pg_catalog.pg_get_userbyid(p.proowner),
           pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
           pg_catalog.md5(coalesce(p.proacl::text,''))
      into v_secdef,v_owner,v_actual_def,v_actual_acl
    from pg_catalog.pg_proc p where p.oid=v_oid;

    if v_owner is distinct from 'postgres'
       or v_secdef is distinct from true
       or v_actual_def is distinct from v_expected_def
       or v_actual_acl is distinct from v_expected_acl
       or not pg_catalog.has_function_privilege('authenticated',v_oid,'EXECUTE')
       or pg_catalog.has_function_privilege('anon',v_oid,'EXECUTE')
       or pg_catalog.has_function_privilege('public',v_oid,'EXECUTE') then
      raise exception 'F1_02_B2_PROOF_WRITER_DRIFT signature=%',v_sig;
    end if;
  end loop;

  -- gerenciar_lista remains deliberately unavailable.
  v_oid:=pg_catalog.to_regprocedure('public.gerenciar_lista(uuid,text,text)');
  if v_oid is null then
    raise exception 'F1_02_B2_PROOF_GERENCIAR_LISTA_MISSING';
  end if;

  select p.prosecdef,
         pg_catalog.pg_get_userbyid(p.proowner),
         pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
         pg_catalog.md5(coalesce(p.proacl::text,''))
    into v_secdef,v_owner,v_actual_def,v_actual_acl
  from pg_catalog.pg_proc p where p.oid=v_oid;

  if v_owner is distinct from 'postgres'
     or v_secdef is distinct from true
     or v_actual_def is distinct from '831308e58497d8b9149a1edc593c6640'
     or v_actual_acl is distinct from 'db23e67d6fad77fdfa003856d807d6af'
     or pg_catalog.has_function_privilege('authenticated',v_oid,'EXECUTE')
     or pg_catalog.has_function_privilege('anon',v_oid,'EXECUTE')
     or pg_catalog.has_function_privilege('public',v_oid,'EXECUTE') then
    raise exception 'F1_02_B2_PROOF_GERENCIAR_LISTA_DRIFT';
  end if;
end;
$f1_02_b2_readonly_proof$;

rollback;

-- ESTABLISHES:
--   static/catalog direct-write boundary and reviewed collateral invariants.
--
-- DOES NOT ESTABLISH:
--   runtime-negative PASS
--   RPC functional continuity
--   end-to-end product PASS
--   successful production application by itself
--   Security Go
