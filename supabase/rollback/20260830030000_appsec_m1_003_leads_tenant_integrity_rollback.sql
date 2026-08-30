-- FECH.AI
-- APPSEC-M1-003 rollback
-- Atomic slice: public.leads tenant-aware relationship integrity.
--
-- Drops only constraints introduced by the APPSEC-M1-003 candidate.
-- Business data, original single-column foreign keys, RLS/FORCE RLS,
-- policies, grants and triggers are intentionally untouched.

begin;

-- Refuse to remove an identically-named object if its definition no longer
-- matches the APPSEC-M1-003 contract.

do $appsec_rollback_preflight$
declare
  v_def text;
begin
  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_corretor_empresa';

  if found
     and v_def not in (
       'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id)',
       'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id) NOT VALID'
     ) then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: fk_appsec_m1_003_leads_corretor_empresa = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_time_empresa';

  if found
     and v_def not in (
       'FOREIGN KEY (time_id, empresa_id) REFERENCES times(id, empresa_id)',
       'FOREIGN KEY (time_id, empresa_id) REFERENCES times(id, empresa_id) NOT VALID'
     ) then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: fk_appsec_m1_003_leads_time_empresa = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_lista_empresa';

  if found
     and v_def not in (
       'FOREIGN KEY (lista_id, empresa_id) REFERENCES listas(id, empresa_id)',
       'FOREIGN KEY (lista_id, empresa_id) REFERENCES listas(id, empresa_id) NOT VALID'
     ) then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: fk_appsec_m1_003_leads_lista_empresa = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_lote_empresa';

  if found
     and v_def not in (
       'FOREIGN KEY (lote_id, empresa_id) REFERENCES lotes(id, empresa_id)',
       'FOREIGN KEY (lote_id, empresa_id) REFERENCES lotes(id, empresa_id) NOT VALID'
     ) then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: fk_appsec_m1_003_leads_lote_empresa = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.corretores'::regclass
    and c.conname = 'uq_appsec_m1_003_corretores_id_empresa_id';

  if found and v_def <> 'UNIQUE (id, empresa_id)' then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: uq_appsec_m1_003_corretores_id_empresa_id = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.times'::regclass
    and c.conname = 'uq_appsec_m1_003_times_id_empresa_id';

  if found and v_def <> 'UNIQUE (id, empresa_id)' then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: uq_appsec_m1_003_times_id_empresa_id = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.listas'::regclass
    and c.conname = 'uq_appsec_m1_003_listas_id_empresa_id';

  if found and v_def <> 'UNIQUE (id, empresa_id)' then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: uq_appsec_m1_003_listas_id_empresa_id = %',
      v_def;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true)
    into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.lotes'::regclass
    and c.conname = 'uq_appsec_m1_003_lotes_id_empresa_id';

  if found and v_def <> 'UNIQUE (id, empresa_id)' then
    raise exception
      'APPSEC_M1_003_ROLLBACK_DEFINITION_MISMATCH: uq_appsec_m1_003_lotes_id_empresa_id = %',
      v_def;
  end if;
end;
$appsec_rollback_preflight$;

alter table public.leads
  drop constraint if exists fk_appsec_m1_003_leads_corretor_empresa;

alter table public.leads
  drop constraint if exists fk_appsec_m1_003_leads_time_empresa;

alter table public.leads
  drop constraint if exists fk_appsec_m1_003_leads_lista_empresa;

alter table public.leads
  drop constraint if exists fk_appsec_m1_003_leads_lote_empresa;

alter table public.corretores
  drop constraint if exists uq_appsec_m1_003_corretores_id_empresa_id;

alter table public.times
  drop constraint if exists uq_appsec_m1_003_times_id_empresa_id;

alter table public.listas
  drop constraint if exists uq_appsec_m1_003_listas_id_empresa_id;

alter table public.lotes
  drop constraint if exists uq_appsec_m1_003_lotes_id_empresa_id;

commit;
