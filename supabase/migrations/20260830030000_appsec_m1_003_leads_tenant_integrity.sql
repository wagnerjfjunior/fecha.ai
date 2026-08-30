-- FECH.AI
-- APPSEC-M1-003
-- Atomic slice: public.leads tenant-aware relationship integrity.
--
-- NEW CANDIDATE reconstruction from approved design.
-- This is not recovery or transfer of any previous exact local artifact.
--
-- Controls introduced:
--   public.corretores UNIQUE (id, empresa_id)
--   public.times      UNIQUE (id, empresa_id)
--   public.listas     UNIQUE (id, empresa_id)
--   public.lotes      UNIQUE (id, empresa_id)
--
--   public.leads (corretor_id, empresa_id)
--     -> public.corretores(id, empresa_id)
--   public.leads (time_id, empresa_id)
--     -> public.times(id, empresa_id)
--   public.leads (lista_id, empresa_id)
--     -> public.listas(id, empresa_id)
--   public.leads (lote_id, empresa_id)
--     -> public.lotes(id, empresa_id)
--
-- Existing single-column foreign keys, RLS/FORCE RLS, policies, grants and
-- triggers are intentionally untouched.
--
-- No cleanup DML is performed. Pre-existing incompatible rows fail closed.

begin;

-- ---------------------------------------------------------------------------
-- 1. Structural/type preflight.
-- ---------------------------------------------------------------------------

do $appsec_preflight$
declare
  v_missing text[];
  v_left_type oid;
  v_left_typmod integer;
  v_right_type oid;
  v_right_typmod integer;
begin
  if to_regclass('public.leads') is null then
    raise exception 'APPSEC_M1_003_PREFLIGHT_MISSING_TABLE: public.leads';
  end if;

  if to_regclass('public.corretores') is null then
    raise exception 'APPSEC_M1_003_PREFLIGHT_MISSING_TABLE: public.corretores';
  end if;

  if to_regclass('public.times') is null then
    raise exception 'APPSEC_M1_003_PREFLIGHT_MISSING_TABLE: public.times';
  end if;

  if to_regclass('public.listas') is null then
    raise exception 'APPSEC_M1_003_PREFLIGHT_MISSING_TABLE: public.listas';
  end if;

  if to_regclass('public.lotes') is null then
    raise exception 'APPSEC_M1_003_PREFLIGHT_MISSING_TABLE: public.lotes';
  end if;

  select array_agg(required.column_name order by required.column_name)
    into v_missing
  from (
    values
      ('id'),
      ('empresa_id'),
      ('corretor_id'),
      ('time_id'),
      ('lista_id'),
      ('lote_id')
  ) as required(column_name)
  where not exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid = 'public.leads'::regclass
      and a.attname = required.column_name
      and a.attnum > 0
      and not a.attisdropped
  );

  if v_missing is not null then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_MISSING_COLUMNS: public.leads %',
      v_missing;
  end if;

  select array_agg(required.object_name || '.' || required.column_name
                   order by required.object_name, required.column_name)
    into v_missing
  from (
    values
      ('corretores', 'id'),
      ('corretores', 'empresa_id'),
      ('times', 'id'),
      ('times', 'empresa_id'),
      ('listas', 'id'),
      ('listas', 'empresa_id'),
      ('lotes', 'id'),
      ('lotes', 'empresa_id')
  ) as required(object_name, column_name)
  where not exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid =
          to_regclass(format('public.%I', required.object_name))
      and a.attname = required.column_name
      and a.attnum > 0
      and not a.attisdropped
  );

  if v_missing is not null then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_MISSING_PARENT_COLUMNS: %',
      v_missing;
  end if;

  select a.atttypid, a.atttypmod
    into v_left_type, v_left_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.leads'::regclass
    and a.attname = 'corretor_id'
    and a.attnum > 0
    and not a.attisdropped;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.corretores'::regclass
    and a.attname = 'id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.corretor_id <> corretores.id';
  end if;

  select a.atttypid, a.atttypmod
    into v_left_type, v_left_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.leads'::regclass
    and a.attname = 'time_id'
    and a.attnum > 0
    and not a.attisdropped;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.times'::regclass
    and a.attname = 'id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.time_id <> times.id';
  end if;

  select a.atttypid, a.atttypmod
    into v_left_type, v_left_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.leads'::regclass
    and a.attname = 'lista_id'
    and a.attnum > 0
    and not a.attisdropped;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.listas'::regclass
    and a.attname = 'id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.lista_id <> listas.id';
  end if;

  select a.atttypid, a.atttypmod
    into v_left_type, v_left_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.leads'::regclass
    and a.attname = 'lote_id'
    and a.attnum > 0
    and not a.attisdropped;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.lotes'::regclass
    and a.attname = 'id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.lote_id <> lotes.id';
  end if;

  select a.atttypid, a.atttypmod
    into v_left_type, v_left_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.leads'::regclass
    and a.attname = 'empresa_id'
    and a.attnum > 0
    and not a.attisdropped;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.corretores'::regclass
    and a.attname = 'empresa_id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.empresa_id <> corretores.empresa_id';
  end if;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.times'::regclass
    and a.attname = 'empresa_id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.empresa_id <> times.empresa_id';
  end if;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.listas'::regclass
    and a.attname = 'empresa_id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.empresa_id <> listas.empresa_id';
  end if;

  select a.atttypid, a.atttypmod
    into v_right_type, v_right_typmod
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.lotes'::regclass
    and a.attname = 'empresa_id'
    and a.attnum > 0
    and not a.attisdropped;

  if v_left_type is distinct from v_right_type
     or v_left_typmod is distinct from v_right_typmod then
    raise exception
      'APPSEC_M1_003_PREFLIGHT_TYPE_MISMATCH: leads.empresa_id <> lotes.empresa_id';
  end if;
end;
$appsec_preflight$;

do $appsec_compatibility$
begin
  if exists (
    select 1
    from public.leads l
    join public.corretores c on c.id = l.corretor_id
    where l.corretor_id is not null
      and c.empresa_id is distinct from l.empresa_id
  ) then
    raise exception 'APPSEC_M1_003_PREEXISTING_DATA_MISMATCH: leads.corretor_id';
  end if;

  if exists (
    select 1
    from public.leads l
    join public.times t on t.id = l.time_id
    where l.time_id is not null
      and t.empresa_id is distinct from l.empresa_id
  ) then
    raise exception 'APPSEC_M1_003_PREEXISTING_DATA_MISMATCH: leads.time_id';
  end if;

  if exists (
    select 1
    from public.leads l
    join public.listas li on li.id = l.lista_id
    where l.lista_id is not null
      and li.empresa_id is distinct from l.empresa_id
  ) then
    raise exception 'APPSEC_M1_003_PREEXISTING_DATA_MISMATCH: leads.lista_id';
  end if;

  if exists (
    select 1
    from public.leads l
    join public.lotes lo on lo.id = l.lote_id
    where l.lote_id is not null
      and lo.empresa_id is distinct from l.empresa_id
  ) then
    raise exception 'APPSEC_M1_003_PREEXISTING_DATA_MISMATCH: leads.lote_id';
  end if;
end;
$appsec_compatibility$;

do $appsec_unique_constraints$
declare
  v_def text;
begin
  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.corretores'::regclass
    and c.conname = 'uq_appsec_m1_003_corretores_id_empresa_id';
  if found then
    if v_def <> 'UNIQUE (id, empresa_id)' then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: uq_appsec_m1_003_corretores_id_empresa_id = %', v_def;
    end if;
  else
    alter table public.corretores
      add constraint uq_appsec_m1_003_corretores_id_empresa_id
      unique (id, empresa_id);
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.times'::regclass
    and c.conname = 'uq_appsec_m1_003_times_id_empresa_id';
  if found then
    if v_def <> 'UNIQUE (id, empresa_id)' then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: uq_appsec_m1_003_times_id_empresa_id = %', v_def;
    end if;
  else
    alter table public.times
      add constraint uq_appsec_m1_003_times_id_empresa_id
      unique (id, empresa_id);
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.listas'::regclass
    and c.conname = 'uq_appsec_m1_003_listas_id_empresa_id';
  if found then
    if v_def <> 'UNIQUE (id, empresa_id)' then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: uq_appsec_m1_003_listas_id_empresa_id = %', v_def;
    end if;
  else
    alter table public.listas
      add constraint uq_appsec_m1_003_listas_id_empresa_id
      unique (id, empresa_id);
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.lotes'::regclass
    and c.conname = 'uq_appsec_m1_003_lotes_id_empresa_id';
  if found then
    if v_def <> 'UNIQUE (id, empresa_id)' then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: uq_appsec_m1_003_lotes_id_empresa_id = %', v_def;
    end if;
  else
    alter table public.lotes
      add constraint uq_appsec_m1_003_lotes_id_empresa_id
      unique (id, empresa_id);
  end if;
end;
$appsec_unique_constraints$;

do $appsec_foreign_keys$
declare
  v_def text;
begin
  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_corretor_empresa';
  if found then
    if v_def not in (
      'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id)',
      'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id) NOT VALID'
    ) then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: fk_appsec_m1_003_leads_corretor_empresa = %', v_def;
    end if;
  else
    alter table public.leads
      add constraint fk_appsec_m1_003_leads_corretor_empresa
      foreign key (corretor_id, empresa_id)
      references public.corretores (id, empresa_id)
      not valid;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_time_empresa';
  if found then
    if v_def not in (
      'FOREIGN KEY (time_id, empresa_id) REFERENCES times(id, empresa_id)',
      'FOREIGN KEY (time_id, empresa_id) REFERENCES times(id, empresa_id) NOT VALID'
    ) then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: fk_appsec_m1_003_leads_time_empresa = %', v_def;
    end if;
  else
    alter table public.leads
      add constraint fk_appsec_m1_003_leads_time_empresa
      foreign key (time_id, empresa_id)
      references public.times (id, empresa_id)
      not valid;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_lista_empresa';
  if found then
    if v_def not in (
      'FOREIGN KEY (lista_id, empresa_id) REFERENCES listas(id, empresa_id)',
      'FOREIGN KEY (lista_id, empresa_id) REFERENCES listas(id, empresa_id) NOT VALID'
    ) then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: fk_appsec_m1_003_leads_lista_empresa = %', v_def;
    end if;
  else
    alter table public.leads
      add constraint fk_appsec_m1_003_leads_lista_empresa
      foreign key (lista_id, empresa_id)
      references public.listas (id, empresa_id)
      not valid;
  end if;

  select pg_catalog.pg_get_constraintdef(c.oid, true) into v_def
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.conname = 'fk_appsec_m1_003_leads_lote_empresa';
  if found then
    if v_def not in (
      'FOREIGN KEY (lote_id, empresa_id) REFERENCES lotes(id, empresa_id)',
      'FOREIGN KEY (lote_id, empresa_id) REFERENCES lotes(id, empresa_id) NOT VALID'
    ) then
      raise exception 'APPSEC_M1_003_CONSTRAINT_NAME_COLLISION: fk_appsec_m1_003_leads_lote_empresa = %', v_def;
    end if;
  else
    alter table public.leads
      add constraint fk_appsec_m1_003_leads_lote_empresa
      foreign key (lote_id, empresa_id)
      references public.lotes (id, empresa_id)
      not valid;
  end if;
end;
$appsec_foreign_keys$;

alter table public.leads validate constraint fk_appsec_m1_003_leads_corretor_empresa;
alter table public.leads validate constraint fk_appsec_m1_003_leads_time_empresa;
alter table public.leads validate constraint fk_appsec_m1_003_leads_lista_empresa;
alter table public.leads validate constraint fk_appsec_m1_003_leads_lote_empresa;

do $appsec_postflight$
declare
  v_count integer;
begin
  select count(*) into v_count
  from pg_catalog.pg_constraint c
  where (
      c.conrelid = 'public.corretores'::regclass
      and c.conname = 'uq_appsec_m1_003_corretores_id_empresa_id'
      and c.contype = 'u'
    )
    or (
      c.conrelid = 'public.times'::regclass
      and c.conname = 'uq_appsec_m1_003_times_id_empresa_id'
      and c.contype = 'u'
    )
    or (
      c.conrelid = 'public.listas'::regclass
      and c.conname = 'uq_appsec_m1_003_listas_id_empresa_id'
      and c.contype = 'u'
    )
    or (
      c.conrelid = 'public.lotes'::regclass
      and c.conname = 'uq_appsec_m1_003_lotes_id_empresa_id'
      and c.contype = 'u'
    );
  if v_count <> 4 then
    raise exception 'APPSEC_M1_003_POSTFLIGHT_UNIQUE_CONSTRAINT_COUNT: expected 4, found %', v_count;
  end if;

  select count(*) into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.contype = 'f'
    and c.convalidated
    and c.conname in (
      'fk_appsec_m1_003_leads_corretor_empresa',
      'fk_appsec_m1_003_leads_time_empresa',
      'fk_appsec_m1_003_leads_lista_empresa',
      'fk_appsec_m1_003_leads_lote_empresa'
    );
  if v_count <> 4 then
    raise exception 'APPSEC_M1_003_POSTFLIGHT_VALIDATED_FK_COUNT: expected 4, found %', v_count;
  end if;
end;
$appsec_postflight$;

commit;
