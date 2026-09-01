-- FECH.AI — M1-C-F01 / Anomaly B / Packet B1
-- POST-APPLICATION COMPLETION PROOF — STRICTLY READ ONLY
--
-- This artifact never repairs state.
-- It can only prove B1 completion or declare completion NOT established.
--
-- API non-exposure is a mandatory completion condition. If authoritative
-- configuration evidence is unavailable, the final receipt MUST be:
--   DISPOSITION_COMPLETION_NOT_ESTABLISHED
-- with:
--   API_NON_EXPOSURE_NOT_ESTABLISHED

begin read only;

set local statement_timeout = '60s';

do $b1_proof_structure$
declare
  v_schema_owner text;
  v_table_owner text;
  v_events_owner text;
  v_rls boolean;
  v_force_rls boolean;
  v_events_rls boolean;
  v_events_force_rls boolean;
  v_policy_count integer;
  v_events_policy_count integer;
  v_trigger_count integer;
  v_function_owner text;
  v_role text;
  v_priv text;
begin
  if pg_catalog.to_regnamespace('forensic_evidence') is null then
    raise exception 'B1_PROOF_FORENSIC_SCHEMA_MISSING';
  end if;

  if pg_catalog.to_regclass(
       'forensic_evidence.movement_disposition_evidence'
     ) is null
     or pg_catalog.to_regclass(
       'forensic_evidence.movement_disposition_events'
     ) is null
     or pg_catalog.to_regprocedure(
       'forensic_evidence.reject_immutable_mutation()'
     ) is null then
    raise exception 'B1_PROOF_EVIDENCE_BOUNDARY_OBJECT_MISSING';
  end if;

  select r.rolname
  into v_schema_owner
  from pg_catalog.pg_namespace n
  join pg_catalog.pg_roles r on r.oid = n.nspowner
  where n.nspname = 'forensic_evidence';

  if v_schema_owner is distinct from 'postgres' then
    raise exception 'B1_PROOF_SCHEMA_OWNER_DRIFT';
  end if;

  -- PUBLIC must have no explicit schema ACL.
  if exists (
    select 1
    from pg_catalog.pg_namespace n
    cross join lateral
      pg_catalog.aclexplode(
        coalesce(
          n.nspacl,
          pg_catalog.acldefault('n', n.nspowner)
        )
      ) x
    where n.nspname = 'forensic_evidence'
      and x.grantee = 0
  ) then
    raise exception 'B1_PROOF_PUBLIC_SCHEMA_ACCESS_PRESENT';
  end if;

  foreach v_role in array array['anon','authenticated','service_role']
  loop
    if pg_catalog.to_regrole(v_role) is null then
      raise exception 'B1_PROOF_REQUIRED_ROLE_MISSING:%', v_role;
    end if;

    if pg_catalog.has_schema_privilege(
         v_role,
         'forensic_evidence',
         'USAGE'
       )
       or pg_catalog.has_schema_privilege(
         v_role,
         'forensic_evidence',
         'CREATE'
       ) then
      raise exception 'B1_PROOF_SCHEMA_PRIVILEGE_PRESENT:%', v_role;
    end if;
  end loop;

  select
    r.rolname,
    c.relrowsecurity,
    c.relforcerowsecurity
  into
    v_table_owner,
    v_rls,
    v_force_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  join pg_catalog.pg_roles r on r.oid = c.relowner
  where n.nspname = 'forensic_evidence'
    and c.relname = 'movement_disposition_evidence'
    and c.relkind = 'r';

  if v_table_owner is distinct from 'postgres'
     or v_rls is distinct from true
     or v_force_rls is distinct from true then
    raise exception 'B1_PROOF_EVIDENCE_TABLE_SECURITY_DRIFT';
  end if;

  select
    r.rolname,
    c.relrowsecurity,
    c.relforcerowsecurity
  into
    v_events_owner,
    v_events_rls,
    v_events_force_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  join pg_catalog.pg_roles r on r.oid = c.relowner
  where n.nspname = 'forensic_evidence'
    and c.relname = 'movement_disposition_events'
    and c.relkind = 'r';

  if v_events_owner is distinct from 'postgres'
     or v_events_rls is distinct from true
     or v_events_force_rls is distinct from true then
    raise exception 'B1_PROOF_EVENTS_TABLE_SECURITY_DRIFT';
  end if;

  select count(*)
  into v_policy_count
  from pg_catalog.pg_policy p
  where p.polrelid =
    'forensic_evidence.movement_disposition_evidence'::pg_catalog.regclass;

  select count(*)
  into v_events_policy_count
  from pg_catalog.pg_policy p
  where p.polrelid =
    'forensic_evidence.movement_disposition_events'::pg_catalog.regclass;

  if v_policy_count <> 0 or v_events_policy_count <> 0 then
    raise exception 'B1_PROOF_UNEXPECTED_RLS_POLICY_PRESENT';
  end if;

  -- No PUBLIC/anon/authenticated/service_role direct table ACL entries.
  if exists (
    select 1
    from (
      values
        ('forensic_evidence.movement_disposition_evidence'::pg_catalog.regclass),
        ('forensic_evidence.movement_disposition_events'::pg_catalog.regclass)
    ) t(relid)
    join pg_catalog.pg_class c on c.oid = t.relid
    cross join lateral
      pg_catalog.aclexplode(
        coalesce(
          c.relacl,
          pg_catalog.acldefault('r', c.relowner)
        )
      ) x
    left join pg_catalog.pg_roles r on r.oid = x.grantee
    where x.grantee = 0
       or r.rolname in ('anon','authenticated','service_role')
  ) then
    raise exception 'B1_PROOF_FORBIDDEN_DIRECT_TABLE_ACL_PRESENT';
  end if;

  foreach v_role in array array['anon','authenticated','service_role']
  loop
    foreach v_priv in array array[
      'SELECT',
      'INSERT',
      'UPDATE',
      'DELETE',
      'TRUNCATE',
      'REFERENCES',
      'TRIGGER',
      'MAINTAIN'
    ]
    loop
      if pg_catalog.has_table_privilege(
           v_role,
           'forensic_evidence.movement_disposition_evidence',
           v_priv
         )
         or pg_catalog.has_table_privilege(
           v_role,
           'forensic_evidence.movement_disposition_events',
           v_priv
         ) then
        raise exception
          'B1_PROOF_FORBIDDEN_EFFECTIVE_TABLE_PRIVILEGE:%:%',
          v_role,
          v_priv;
      end if;
    end loop;
  end loop;

  -- No non-owner grant option survives on either evidence relation.
  if exists (
    select 1
    from (
      values
        ('forensic_evidence.movement_disposition_evidence'::pg_catalog.regclass),
        ('forensic_evidence.movement_disposition_events'::pg_catalog.regclass)
    ) t(relid)
    join pg_catalog.pg_class c on c.oid = t.relid
    cross join lateral
      pg_catalog.aclexplode(
        coalesce(
          c.relacl,
          pg_catalog.acldefault('r', c.relowner)
        )
      ) x
    where x.grantee <> c.relowner
      and x.is_grantable
  ) then
    raise exception 'B1_PROOF_NONOWNER_GRANT_OPTION_PRESENT';
  end if;

  select r.rolname
  into v_function_owner
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  join pg_catalog.pg_roles r on r.oid = p.proowner
  where n.nspname = 'forensic_evidence'
    and p.proname = 'reject_immutable_mutation'
    and pg_catalog.pg_get_function_identity_arguments(p.oid) = '';

  if v_function_owner is distinct from 'postgres' then
    raise exception 'B1_PROOF_IMMUTABILITY_FUNCTION_OWNER_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    cross join lateral
      pg_catalog.aclexplode(
        coalesce(
          p.proacl,
          pg_catalog.acldefault('f', p.proowner)
        )
      ) x
    left join pg_catalog.pg_roles r on r.oid = x.grantee
    where n.nspname = 'forensic_evidence'
      and p.proname = 'reject_immutable_mutation'
      and pg_catalog.pg_get_function_identity_arguments(p.oid) = ''
      and (
        x.grantee = 0
        or r.rolname in ('anon','authenticated','service_role')
      )
  ) then
    raise exception 'B1_PROOF_FORBIDDEN_TRIGGER_FUNCTION_EXECUTE_PRESENT';
  end if;

  select count(*)
  into v_trigger_count
  from pg_catalog.pg_trigger t
  where not t.tgisinternal
    and t.tgenabled <> 'D'
    and (
      (
        t.tgrelid =
          'forensic_evidence.movement_disposition_evidence'::pg_catalog.regclass
        and t.tgname = 'trg_b1_evidence_immutable'
      )
      or
      (
        t.tgrelid =
          'forensic_evidence.movement_disposition_events'::pg_catalog.regclass
        and t.tgname = 'trg_b1_events_immutable'
      )
    );

  if v_trigger_count <> 2 then
    raise exception 'B1_PROOF_IMMUTABILITY_TRIGGER_DRIFT';
  end if;
end;
$b1_proof_structure$;

do $b1_proof_evidence_and_domain$
declare
  v_evidence forensic_evidence.movement_disposition_evidence%rowtype;
  v_digest_input jsonb;
  v_recomputed_digest bytea;
  v_current_lead_digest bytea;
  v_current_anomaly_a_digest bytea;
  v_unrelated_count_now bigint;
  v_unrelated_digest_now bytea;
  v_total_now bigint;
  v_evidence_count bigint;
  v_committed_event_count bigint;
  v_rollback_event_count bigint;
  v_active_b_count bigint;
begin
  select count(*)
  into v_evidence_count
  from forensic_evidence.movement_disposition_evidence e
  where e.source_movement_id =
    '4908c70c-f0b2-423c-8d18-4bc36eaac93a'::uuid;

  if v_evidence_count <> 1 then
    raise exception 'B1_PROOF_EVIDENCE_CARDINALITY_FAILURE';
  end if;

  select *
  into strict v_evidence
  from forensic_evidence.movement_disposition_evidence e
  where e.source_movement_id =
    '4908c70c-f0b2-423c-8d18-4bc36eaac93a'::uuid;

  if v_evidence.finding_id is distinct from 'M1-C-F01/ANOMALY-B'
     or v_evidence.source_lead_id is distinct from
        'b2b17060-c739-4af3-9ffe-bb39e5a98b1d'::uuid
     or v_evidence.source_corretor_id is distinct from
        '9be9dae0-1699-49a2-a7ab-beeef274f22b'::uuid
     or v_evidence.source_current_stage_id is distinct from
        'bc23dcc9-b4a2-4d3f-aeef-c0695845649a'::uuid
     or v_evidence.source_previous_stage_id is not null
     or v_evidence.movement_empresa_id is distinct from
        '651fa3b8-28b2-41bd-a3b4-35502c24925f'::uuid
     or v_evidence.lead_empresa_id is distinct from
        v_evidence.movement_empresa_id
     or v_evidence.corretor_empresa_id is distinct from
        'a0000000-0000-0000-0000-000000000001'::uuid
     or v_evidence.current_stage_empresa_id is distinct from
        v_evidence.corretor_empresa_id
     or v_evidence.previous_stage_empresa_id is not null
     or v_evidence.source_created_at is distinct from
        '2026-04-30 19:15:40.939754+00'::timestamptz
     or v_evidence.source_origem_evento is distinct from 'manual'
     or v_evidence.historical_truth_status is distinct from 'NOT_ESTABLISHED'
     or v_evidence.disposition_authority_ref is distinct from
        'PA-FECHAI-M1-C-F01-B1-20260901-01'
     or v_evidence.retention_state is distinct from
        'INDEFINITE_PENDING_SEPARATE_RETENTION_POLICY' then
    raise exception 'B1_PROOF_EVIDENCE_CONTRACT_DRIFT';
  end if;

  v_digest_input := pg_catalog.jsonb_build_array(
    v_evidence.snapshot_format_version,
    v_evidence.source_snapshot->>'id',
    v_evidence.source_snapshot->>'lead_id',
    v_evidence.source_snapshot->>'corretor_id',
    v_evidence.source_snapshot->>'estagio_id',
    case
      when v_evidence.source_snapshot->'estagio_anterior_id' = 'null'::jsonb
        then null
      else v_evidence.source_snapshot->>'estagio_anterior_id'
    end,
    v_evidence.source_snapshot->>'observacao',
    pg_catalog.to_char(
      (v_evidence.source_snapshot->>'created_at')::timestamptz
        at time zone 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
    ),
    v_evidence.source_snapshot->>'empresa_id',
    v_evidence.source_snapshot->>'origem_evento',
    v_evidence.source_snapshot->>'motivo',
    v_evidence.source_snapshot->'payload'
  );

  v_recomputed_digest :=
    extensions.digest(
      pg_catalog.convert_to(v_digest_input::text, 'UTF8'),
      'sha256'
    );

  if v_recomputed_digest is distinct from v_evidence.snapshot_digest then
    raise exception 'B1_PROOF_SNAPSHOT_DIGEST_FIDELITY_FAILURE';
  end if;

  select count(*)
  into v_committed_event_count
  from forensic_evidence.movement_disposition_events ev
  where ev.evidence_id = v_evidence.evidence_id
    and ev.event_type = 'B1_DISPOSITION_COMMITTED'
    and ev.result = 'COMMITTED';

  select count(*)
  into v_rollback_event_count
  from forensic_evidence.movement_disposition_events ev
  where ev.evidence_id = v_evidence.evidence_id
    and ev.event_type = 'B1_ROLLBACK_RESTORED_PRE_M1';

  if v_committed_event_count <> 1 or v_rollback_event_count <> 0 then
    raise exception 'B1_PROOF_EVENT_LIFECYCLE_DRIFT';
  end if;

  select count(*)
  into v_active_b_count
  from public.funil_movimentacoes fm
  where fm.id = v_evidence.source_movement_id;

  if v_active_b_count <> 0 then
    raise exception 'B1_PROOF_ACTIVE_B_MOVEMENT_PRESENT';
  end if;

  select
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.to_jsonb(l)::text, 'UTF8'),
      'sha256'
    )
  into strict v_current_lead_digest
  from public.leads l
  where l.id = v_evidence.source_lead_id;

  if v_current_lead_digest is distinct from v_evidence.lead_row_digest then
    raise exception 'B1_PROOF_LEAD_CHANGED_SINCE_DISPOSITION';
  end if;

  select
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.to_jsonb(fm)::text, 'UTF8'),
      'sha256'
    )
  into strict v_current_anomaly_a_digest
  from public.funil_movimentacoes fm
  where fm.id = '20150d61-3e10-43c8-8dd4-39f1374765b8'::uuid;

  if v_current_anomaly_a_digest is distinct from v_evidence.anomaly_a_row_digest then
    raise exception 'B1_PROOF_ANOMALY_A_CHANGED_SINCE_DISPOSITION';
  end if;

  select count(*)
  into v_total_now
  from public.funil_movimentacoes fm
  where fm.created_at <= v_evidence.disposition_at;

  select
    count(*),
    extensions.digest(
      pg_catalog.convert_to(
        coalesce(
          pg_catalog.jsonb_agg(pg_catalog.to_jsonb(fm) order by fm.id)::text,
          '[]'
        ),
        'UTF8'
      ),
      'sha256'
    )
  into v_unrelated_count_now, v_unrelated_digest_now
  from public.funil_movimentacoes fm
  where fm.id <> v_evidence.source_movement_id
    and fm.created_at <= v_evidence.disposition_at;

  if v_total_now <> v_evidence.movement_total_before - 1
     or v_unrelated_count_now <> v_evidence.unrelated_movements_count_before
     or v_unrelated_digest_now is distinct from
        v_evidence.unrelated_movements_digest_before then
    raise exception 'B1_PROOF_UNRELATED_MOVEMENT_FIDELITY_FAILURE';
  end if;
end;
$b1_proof_evidence_and_domain$;

do $b1_proof_m1_boundary$
declare
  v_m1_recorded boolean;
  v_target_fk_count integer;
begin
  if pg_catalog.to_regclass('supabase_migrations.schema_migrations') is null then
    raise exception 'B1_PROOF_MIGRATION_LEDGER_UNAVAILABLE';
  end if;

  select exists(
    select 1
    from supabase_migrations.schema_migrations sm
    where sm.version::text = '20260831120000'
  )
  into v_m1_recorded;

  select count(*)
  into v_target_fk_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and c.conname in (
      'fk_m1_c_f01_funil_mov_lead_empresa',
      'fk_m1_c_f01_funil_mov_corretor_empresa',
      'fk_m1_c_f01_funil_mov_estagio_empresa',
      'fk_m1_c_f01_funil_mov_estagio_anterior_empresa'
    );

  if v_m1_recorded or v_target_fk_count <> 0 then
    raise exception 'B1_PROOF_EXPECTED_PRE_M1_COMPLETION_WINDOW_CLOSED';
  end if;
end;
$b1_proof_m1_boundary$;

-- Data API exposure cannot be inferred from schema naming. We accept a PASS only
-- when an observed PostgREST schema setting exists and excludes forensic_evidence.
-- If no authoritative setting is visible in this database session/catalog, the
-- completion receipt remains NOT_ESTABLISHED.
do $b1_proof_known_api_exposure$
declare
  v_db_schemas text;
  v_extra_search_path text;
  v_role_setting text;
begin
  v_db_schemas :=
    pg_catalog.current_setting('pgrst.db_schemas', true);

  v_extra_search_path :=
    pg_catalog.current_setting('pgrst.db_extra_search_path', true);

  if v_db_schemas is not null
     and 'forensic_evidence' = any(
       pg_catalog.regexp_split_to_array(
         pg_catalog.replace(v_db_schemas, '"', ''),
         '\s*,\s*'
       )
     ) then
    raise exception 'B1_PROOF_API_EXPOSURE_DETECTED_DB_SCHEMAS';
  end if;

  if v_extra_search_path is not null
     and 'forensic_evidence' = any(
       pg_catalog.regexp_split_to_array(
         pg_catalog.replace(v_extra_search_path, '"', ''),
         '\s*,\s*'
       )
     ) then
    raise exception 'B1_PROOF_API_EXPOSURE_DETECTED_EXTRA_SEARCH_PATH';
  end if;

  for v_role_setting in
    select unnest(s.setconfig)
    from pg_catalog.pg_db_role_setting s
    where s.setconfig is not null
  loop
    if v_role_setting like 'pgrst.db_schemas=%forensic_evidence%'
       or v_role_setting like 'pgrst.db_extra_search_path=%forensic_evidence%' then
      raise exception 'B1_PROOF_API_EXPOSURE_DETECTED_ROLE_SETTING';
    end if;
  end loop;
end;
$b1_proof_known_api_exposure$;

with api_observation as (
  select
    pg_catalog.current_setting('pgrst.db_schemas', true) as db_schemas,
    pg_catalog.current_setting('pgrst.db_extra_search_path', true)
      as extra_search_path,
    exists (
      select 1
      from pg_catalog.pg_db_role_setting s
      cross join lateral unnest(s.setconfig) cfg(value)
      where cfg.value like 'pgrst.db_schemas=%'
         or cfg.value like 'pgrst.db_extra_search_path=%'
    ) as catalog_config_observed
),
api_status as (
  select
    case
      when db_schemas is not null
        or extra_search_path is not null
        or catalog_config_observed
      then 'API_NON_EXPOSURE_ESTABLISHED_FOR_OBSERVED_DB_CONFIG'
      else 'API_NON_EXPOSURE_NOT_ESTABLISHED'
    end as api_non_exposure_status
  from api_observation
)
select
  api_non_exposure_status,
  case
    when api_non_exposure_status =
      'API_NON_EXPOSURE_ESTABLISHED_FOR_OBSERVED_DB_CONFIG'
    then 'B1_DISPOSITION_COMPLETION_ESTABLISHED'
    else 'DISPOSITION_COMPLETION_NOT_ESTABLISHED'
  end as completion_receipt
from api_status;

rollback;
