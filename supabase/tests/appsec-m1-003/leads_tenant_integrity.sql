-- FECH.AI
-- APPSEC-M1-003
-- Tests: public.leads tenant-aware relationship integrity.
--
-- IMPORTANT:
--   * This artifact does not authorize production execution.
--   * All write-based checks execute inside this explicit transaction.
--   * The transaction always rolls back.
--   * No auth.users query is performed.
--   * Existing business rows are used only as transactional fixtures and are
--     restored by ROLLBACK.
--
-- Expected execution context:
--   migration/test runner with sufficient test-environment privileges to
--   inspect catalog metadata, SET LOCAL ROLE authenticated and issue the
--   transactional UPDATE statements below.

begin;

create or replace function pg_temp.appsec_assert(
  p_condition boolean,
  p_message text
)
returns void
language plpgsql
as $$
begin
  if coalesce(p_condition, false) is not true then
    raise exception 'APPSEC-M1-003 ASSERT FAILED: %', p_message;
  end if;
end;
$$;

create or replace function pg_temp.appsec_expect_fk_violation(
  p_sql text,
  p_context text
)
returns void
language plpgsql
security invoker
as $$
declare
  v_denied boolean := false;
begin
  begin
    execute p_sql;
  exception
    when foreign_key_violation then
      v_denied := true;
  end;

  if not v_denied then
    raise exception
      'APPSEC-M1-003 ASSERT FAILED: expected foreign_key_violation for [%]. SQL: %',
      p_context,
      p_sql;
  end if;
end;
$$;

create or replace function pg_temp.appsec_expect_denied(
  p_sql text,
  p_context text
)
returns void
language plpgsql
security invoker
as $$
declare
  v_denied boolean := false;
begin
  begin
    execute p_sql;
  exception
    when foreign_key_violation then
      v_denied := true;
    when insufficient_privilege then
      v_denied := true;
    when check_violation then
      v_denied := true;
    when with_check_option_violation then
      v_denied := true;
  end;

  if not v_denied then
    raise exception
      'APPSEC-M1-003 ASSERT FAILED: expected denial for [%]. SQL: %',
      p_context,
      p_sql;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Catalog verification.
-- ---------------------------------------------------------------------------

do $appsec_catalog$
declare
  v_count integer;
  v_bool boolean;
begin
  -- Four supporting UNIQUE constraints.
  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where (
      c.conrelid = 'public.corretores'::regclass
      and c.conname = 'uq_appsec_m1_003_corretores_id_empresa_id'
      and c.contype = 'u'
      and pg_catalog.pg_get_constraintdef(c.oid, true) =
          'UNIQUE (id, empresa_id)'
    )
    or (
      c.conrelid = 'public.times'::regclass
      and c.conname = 'uq_appsec_m1_003_times_id_empresa_id'
      and c.contype = 'u'
      and pg_catalog.pg_get_constraintdef(c.oid, true) =
          'UNIQUE (id, empresa_id)'
    )
    or (
      c.conrelid = 'public.listas'::regclass
      and c.conname = 'uq_appsec_m1_003_listas_id_empresa_id'
      and c.contype = 'u'
      and pg_catalog.pg_get_constraintdef(c.oid, true) =
          'UNIQUE (id, empresa_id)'
    )
    or (
      c.conrelid = 'public.lotes'::regclass
      and c.conname = 'uq_appsec_m1_003_lotes_id_empresa_id'
      and c.contype = 'u'
      and pg_catalog.pg_get_constraintdef(c.oid, true) =
          'UNIQUE (id, empresa_id)'
    );

  perform pg_temp.appsec_assert(
    v_count = 4,
    format('expected 4 APPSEC supporting UNIQUE constraints; found %s', v_count)
  );

  -- Four tenant-aware composite foreign keys.
  select count(*)
    into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.leads'::regclass
    and c.contype = 'f'
    and (
      (
        c.conname = 'fk_appsec_m1_003_leads_corretor_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid, true) =
            'FOREIGN KEY (corretor_id, empresa_id) REFERENCES corretores(id, empresa_id)'
      )
      or
      (
        c.conname = 'fk_appsec_m1_003_leads_time_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid, true) =
            'FOREIGN KEY (time_id, empresa_id) REFERENCES times(id, empresa_id)'
      )
      or
      (
        c.conname = 'fk_appsec_m1_003_leads_lista_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid, true) =
            'FOREIGN KEY (lista_id, empresa_id) REFERENCES listas(id, empresa_id)'
      )
      or
      (
        c.conname = 'fk_appsec_m1_003_leads_lote_empresa'
        and pg_catalog.pg_get_constraintdef(c.oid, true) =
            'FOREIGN KEY (lote_id, empresa_id) REFERENCES lotes(id, empresa_id)'
      )
    );

  perform pg_temp.appsec_assert(
    v_count = 4,
    format('expected 4 APPSEC composite foreign keys; found %s', v_count)
  );

  -- All four foreign keys must be validated.
  select count(*)
    into v_count
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

  perform pg_temp.appsec_assert(
    v_count = 4,
    format('expected 4 validated APPSEC composite foreign keys; found %s', v_count)
  );

  -- RLS enabled.
  select c.relrowsecurity
    into v_bool
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'leads'
    and c.relkind in ('r', 'p');

  perform pg_temp.appsec_assert(
    v_bool is true,
    'public.leads must retain RLS ENABLED'
  );

  -- FORCE RLS enabled.
  select c.relforcerowsecurity
    into v_bool
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'leads'
    and c.relkind in ('r', 'p');

  perform pg_temp.appsec_assert(
    v_bool is true,
    'public.leads must retain FORCE ROW LEVEL SECURITY'
  );

  -- Existing policy surface must remain present.
  -- This slice creates/drops no policy. Absence of every leads policy is
  -- therefore treated as a regression/error rather than silently accepted.
  select count(*)
    into v_count
  from pg_catalog.pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'leads';

  perform pg_temp.appsec_assert(
    v_count > 0,
    'public.leads must retain its existing RLS policies'
  );
end;
$appsec_catalog$;

-- ---------------------------------------------------------------------------
-- Authenticated direct-DML relationship tests.
--
-- Select one existing lead whose current corretor belongs to the same tenant
-- and exposes a non-null public.corretores.user_id usable as the authenticated
-- JWT subject. No auth.users access is required.
--
-- Cross-tenant IDs are selected from each referenced public table.
-- Failure to obtain suitable fixtures fails the test rather than silently
-- skipping a required negative-control family.
-- ---------------------------------------------------------------------------

do $appsec_transactional$
declare
  v_lead_id public.leads.id%type;
  v_empresa_a public.leads.empresa_id%type;
  v_actor_user_id public.corretores.user_id%type;

  v_same_corretor public.corretores.id%type;

  v_foreign_corretor public.corretores.id%type;
  v_foreign_corretor_empresa public.corretores.empresa_id%type;

  v_foreign_time public.times.id%type;
  v_foreign_lista public.listas.id%type;
  v_foreign_lote public.lotes.id%type;

  v_count integer;
begin
  select
    l.id,
    l.empresa_id,
    c.user_id,
    c.id
  into
    v_lead_id,
    v_empresa_a,
    v_actor_user_id,
    v_same_corretor
  from public.leads l
  join public.corretores c
    on c.id = l.corretor_id
   and c.empresa_id = l.empresa_id
  where c.user_id is not null
  limit 1;

  perform pg_temp.appsec_assert(
    v_lead_id is not null,
    'missing transactional fixture: same-tenant lead/corretor with non-null corretores.user_id'
  );

  select c.id, c.empresa_id
    into v_foreign_corretor, v_foreign_corretor_empresa
  from public.corretores c
  where c.empresa_id is distinct from v_empresa_a
  limit 1;

  perform pg_temp.appsec_assert(
    v_foreign_corretor is not null,
    'missing transactional fixture: cross-tenant corretor'
  );

  select t.id
    into v_foreign_time
  from public.times t
  where t.empresa_id is distinct from v_empresa_a
  limit 1;

  perform pg_temp.appsec_assert(
    v_foreign_time is not null,
    'missing transactional fixture: cross-tenant time'
  );

  select li.id
    into v_foreign_lista
  from public.listas li
  where li.empresa_id is distinct from v_empresa_a
  limit 1;

  perform pg_temp.appsec_assert(
    v_foreign_lista is not null,
    'missing transactional fixture: cross-tenant lista'
  );

  select lo.id
    into v_foreign_lote
  from public.lotes lo
  where lo.empresa_id is distinct from v_empresa_a
  limit 1;

  perform pg_temp.appsec_assert(
    v_foreign_lote is not null,
    'missing transactional fixture: cross-tenant lote'
  );

  -- Supabase-compatible authenticated subject context.
  perform set_config(
    'request.jwt.claim.sub',
    v_actor_user_id::text,
    true
  );

  perform set_config(
    'request.jwt.claim.role',
    'authenticated',
    true
  );

  begin
    execute 'set local role authenticated';

    -- Sanity check: the selected lead must actually be addressable by this
    -- authenticated actor. Zero visible rows would make the negative tests
    -- non-probative.
    execute format(
      'select count(*) from public.leads where id = %L',
      v_lead_id
    )
    into v_count;

    perform pg_temp.appsec_assert(
      v_count = 1,
      'authenticated actor cannot address the selected lead; direct-DML fixture is non-probative'
    );

    -- Valid control:
    -- a same-tenant relationship remains accepted.
    execute format(
      'update public.leads set corretor_id = %L where id = %L',
      v_same_corretor,
      v_lead_id
    );

    get diagnostics v_count = row_count;

    perform pg_temp.appsec_assert(
      v_count = 1,
      'same-tenant authenticated relationship update must remain accepted'
    );

    -- Negative 1: cross-tenant corretor_id.
    perform pg_temp.appsec_expect_fk_violation(
      format(
        'update public.leads set corretor_id = %L where id = %L',
        v_foreign_corretor,
        v_lead_id
      ),
      'authenticated cross-tenant corretor_id rewrite'
    );

    -- Negative 2: cross-tenant time_id.
    perform pg_temp.appsec_expect_fk_violation(
      format(
        'update public.leads set time_id = %L where id = %L',
        v_foreign_time,
        v_lead_id
      ),
      'authenticated cross-tenant time_id rewrite'
    );

    -- Negative 3: cross-tenant lista_id.
    perform pg_temp.appsec_expect_fk_violation(
      format(
        'update public.leads set lista_id = %L where id = %L',
        v_foreign_lista,
        v_lead_id
      ),
      'authenticated cross-tenant lista_id rewrite'
    );

    -- Negative 4: cross-tenant lote_id.
    perform pg_temp.appsec_expect_fk_violation(
      format(
        'update public.leads set lote_id = %L where id = %L',
        v_foreign_lote,
        v_lead_id
      ),
      'authenticated cross-tenant lote_id rewrite'
    );

    -- Negative 5:
    -- simultaneous empresa_id + foreign relationship rewrite.
    --
    -- The composite FK for corretor alone could become internally consistent
    -- if both values move together; the authenticated tenant boundary and/or
    -- the remaining tenant-aware relationships must still deny the tenant
    -- rewrite. Either authorization denial or an integrity constraint denial
    -- is acceptable, but silent success is not.
    perform pg_temp.appsec_expect_denied(
      format(
        'update public.leads
            set empresa_id = %L,
                corretor_id = %L
          where id = %L',
        v_foreign_corretor_empresa,
        v_foreign_corretor,
        v_lead_id
      ),
      'authenticated simultaneous empresa_id + foreign corretor_id rewrite'
    );

    execute 'reset role';
  exception
    when others then
      execute 'reset role';
      raise;
  end;
end;
$appsec_transactional$;

-- Every write performed above is transactional test activity only.
rollback;
