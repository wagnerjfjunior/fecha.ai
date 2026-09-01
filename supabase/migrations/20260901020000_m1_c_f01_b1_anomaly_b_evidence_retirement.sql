-- FECH.AI — M1-C-F01 / Anomaly B / Packet B1
-- One-risk data-disposition artifact:
--   preserve exact contradictory movement as private immutable evidence,
--   then retire exactly that movement from the active relational domain.
--
-- IMPORTANT:
--   VERSIONED ARTIFACT ONLY until separately authorized for database application.
--   This migration MUST NOT mutate the affected lead or Anomaly A.
--   Historical truth remains NOT_ESTABLISHED.
--
-- Product Authority reference:
--   PA-FECHAI-M1-C-F01-B1-20260901-01
--
-- Retention:
--   INDEFINITE_PENDING_SEPARATE_RETENTION_POLICY
--
-- API exposure:
--   schema naming is NOT proof of Data API non-exposure.
--   Post-commit proof must establish API non-exposure or return
--   API_NON_EXPOSURE_NOT_ESTABLISHED.

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';
set local idle_in_transaction_session_timeout = '60s';

do $b1_static_preflight$
declare
  v_m1_recorded boolean;
  v_target_fk_count integer;
begin
  if pg_catalog.to_regrole('postgres') is null
     or pg_catalog.to_regrole('anon') is null
     or pg_catalog.to_regrole('authenticated') is null
     or pg_catalog.to_regrole('service_role') is null then
    raise exception 'B1_PREFLIGHT_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regclass('public.funil_movimentacoes') is null
     or pg_catalog.to_regclass('public.leads') is null
     or pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.funil_estagios') is null then
    raise exception 'B1_PREFLIGHT_REQUIRED_SOURCE_OBJECT_MISSING';
  end if;

  if pg_catalog.to_regnamespace('forensic_evidence') is not null then
    raise exception 'B1_PREFLIGHT_FORENSIC_SCHEMA_ALREADY_EXISTS';
  end if;

  if pg_catalog.to_regclass('supabase_migrations.schema_migrations') is null then
    raise exception 'B1_PREFLIGHT_MIGRATION_LEDGER_UNAVAILABLE';
  end if;

  select exists(
    select 1
    from supabase_migrations.schema_migrations sm
    where sm.version::text = '20260831120000'
  )
  into v_m1_recorded;

  if v_m1_recorded then
    raise exception 'B1_PREFLIGHT_M1_C_F01_ALREADY_RECORDED';
  end if;

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

  if v_target_fk_count <> 0 then
    raise exception 'B1_PREFLIGHT_M1_C_F01_TARGET_CONSTRAINT_ALREADY_PRESENT';
  end if;

  if pg_catalog.to_regprocedure('extensions.digest(bytea,text)') is null then
    raise exception 'B1_PREFLIGHT_PGCRYPTO_DIGEST_UNAVAILABLE';
  end if;
end;
$b1_static_preflight$;

-- Existing movement writers are not proven to honor a lead-scoped advisory lock.
-- This bounded lock serializes movement-table writes during the one-row disposition
-- so the unrelated-row before/after invariants are meaningful.
lock table public.funil_movimentacoes in share row exclusive mode;

do $b1_live_shape_preflight$
declare
  v_movement public.funil_movimentacoes%rowtype;
  v_lead public.leads%rowtype;
  v_corretor public.corretores%rowtype;
  v_stage public.funil_estagios%rowtype;
  v_history_count bigint;
begin
  select *
  into strict v_movement
  from public.funil_movimentacoes fm
  where fm.id = '4908c70c-f0b2-423c-8d18-4bc36eaac93a'::uuid
  for update;

  if v_movement.lead_id is distinct from 'b2b17060-c739-4af3-9ffe-bb39e5a98b1d'::uuid
     or v_movement.corretor_id is distinct from '9be9dae0-1699-49a2-a7ab-beeef274f22b'::uuid
     or v_movement.estagio_id is distinct from 'bc23dcc9-b4a2-4d3f-aeef-c0695845649a'::uuid
     or v_movement.estagio_anterior_id is not null
     or v_movement.created_at is distinct from '2026-04-30 19:15:40.939754+00'::timestamptz
     or v_movement.empresa_id is distinct from '651fa3b8-28b2-41bd-a3b4-35502c24925f'::uuid
     or v_movement.origem_evento::text is distinct from 'manual'
     or v_movement.motivo is not null then
    raise exception 'B1_PREFLIGHT_EXACT_MOVEMENT_SHAPE_DRIFT';
  end if;

  select *
  into strict v_lead
  from public.leads l
  where l.id = v_movement.lead_id
  for update;

  select *
  into strict v_corretor
  from public.corretores c
  where c.id = v_movement.corretor_id
  for share;

  select *
  into strict v_stage
  from public.funil_estagios fe
  where fe.id = v_movement.estagio_id
  for share;

  if v_lead.empresa_id is distinct from '651fa3b8-28b2-41bd-a3b4-35502c24925f'::uuid
     or v_corretor.empresa_id is distinct from 'a0000000-0000-0000-0000-000000000001'::uuid
     or v_stage.empresa_id is distinct from 'a0000000-0000-0000-0000-000000000001'::uuid
     or v_movement.empresa_id is distinct from v_lead.empresa_id
     or v_movement.empresa_id is not distinct from v_corretor.empresa_id
     or v_movement.empresa_id is not distinct from v_stage.empresa_id
     or v_corretor.empresa_id is distinct from v_stage.empresa_id then
    raise exception 'B1_PREFLIGHT_PARENT_TENANT_SHAPE_DRIFT';
  end if;

  select count(*)
  into v_history_count
  from public.funil_movimentacoes fm
  where fm.lead_id = v_movement.lead_id;

  if v_history_count <> 1 then
    raise exception 'B1_PREFLIGHT_MOVEMENT_HISTORY_CARDINALITY_DRIFT';
  end if;
end;
$b1_live_shape_preflight$;

create schema forensic_evidence authorization postgres;

revoke all on schema forensic_evidence from public;
revoke all on schema forensic_evidence from anon, authenticated, service_role;

create table forensic_evidence.movement_disposition_evidence (
  evidence_id uuid not null default pg_catalog.gen_random_uuid(),
  finding_id text not null,
  source_movement_id uuid not null,
  source_lead_id uuid not null,
  source_corretor_id uuid not null,
  source_current_stage_id uuid not null,
  source_previous_stage_id uuid null,
  movement_empresa_id uuid not null,
  lead_empresa_id uuid not null,
  corretor_empresa_id uuid not null,
  current_stage_empresa_id uuid not null,
  previous_stage_empresa_id uuid null,
  source_created_at timestamptz not null,
  source_origem_evento text not null,
  source_snapshot jsonb not null,
  snapshot_format_version text not null,
  digest_algorithm text not null,
  snapshot_digest bytea not null,
  lead_row_digest bytea not null,
  anomaly_a_row_digest bytea not null,
  unrelated_movements_count_before bigint not null,
  unrelated_movements_digest_before bytea not null,
  movement_total_before bigint not null,
  disposition_classification text not null,
  historical_truth_status text not null,
  disposition_authority_ref text not null,
  disposition_at timestamptz not null default pg_catalog.transaction_timestamp(),
  implementation_ref text not null,
  actor_identity text not null,
  purpose text not null,
  retention_state text not null,

  constraint movement_disposition_evidence_pkey
    primary key (evidence_id),

  constraint movement_disposition_evidence_source_movement_key
    unique (source_movement_id),

  constraint movement_disposition_evidence_finding_check
    check (finding_id = 'M1-C-F01/ANOMALY-B'),

  constraint movement_disposition_evidence_exact_source_check
    check (
      source_movement_id = '4908c70c-f0b2-423c-8d18-4bc36eaac93a'::uuid
      and source_lead_id = 'b2b17060-c739-4af3-9ffe-bb39e5a98b1d'::uuid
      and source_corretor_id = '9be9dae0-1699-49a2-a7ab-beeef274f22b'::uuid
      and source_current_stage_id = 'bc23dcc9-b4a2-4d3f-aeef-c0695845649a'::uuid
      and source_previous_stage_id is null
      and source_created_at = '2026-04-30 19:15:40.939754+00'::timestamptz
      and source_origem_evento = 'manual'
    ),

  constraint movement_disposition_evidence_tenant_shape_check
    check (
      movement_empresa_id = '651fa3b8-28b2-41bd-a3b4-35502c24925f'::uuid
      and lead_empresa_id = movement_empresa_id
      and corretor_empresa_id = 'a0000000-0000-0000-0000-000000000001'::uuid
      and current_stage_empresa_id = corretor_empresa_id
      and movement_empresa_id <> corretor_empresa_id
      and movement_empresa_id <> current_stage_empresa_id
      and previous_stage_empresa_id is null
    ),

  constraint movement_disposition_evidence_snapshot_format_check
    check (snapshot_format_version = 'fechai.funil_movimentacoes.b1.v1'),

  constraint movement_disposition_evidence_digest_algorithm_check
    check (digest_algorithm = 'SHA-256'),

  constraint movement_disposition_evidence_digest_length_check
    check (
      pg_catalog.octet_length(snapshot_digest) = 32
      and pg_catalog.octet_length(lead_row_digest) = 32
      and pg_catalog.octet_length(anomaly_a_row_digest) = 32
      and pg_catalog.octet_length(unrelated_movements_digest_before) = 32
    ),

  constraint movement_disposition_evidence_classification_check
    check (
      disposition_classification =
      'ACTIVE_INVALID_MOVEMENT_RETIRED_AFTER_IMMUTABLE_EVIDENCE_PRESERVATION'
    ),

  constraint movement_disposition_evidence_truth_check
    check (historical_truth_status = 'NOT_ESTABLISHED'),

  constraint movement_disposition_evidence_authority_check
    check (disposition_authority_ref = 'PA-FECHAI-M1-C-F01-B1-20260901-01'),

  constraint movement_disposition_evidence_implementation_check
    check (
      implementation_ref =
      'migration:20260901020000_m1_c_f01_b1_anomaly_b_evidence_retirement'
    ),

  constraint movement_disposition_evidence_actor_check
    check (actor_identity like 'db_role:%' and pg_catalog.length(actor_identity) > 8),

  constraint movement_disposition_evidence_purpose_check
    check (
      purpose =
      'M1-C-F01 B1 preserve contradictory movement evidence and retire exact active relation'
    ),

  constraint movement_disposition_evidence_retention_check
    check (retention_state = 'INDEFINITE_PENDING_SEPARATE_RETENTION_POLICY'),

  constraint movement_disposition_evidence_snapshot_shape_check
    check (
      pg_catalog.jsonb_typeof(source_snapshot) = 'object'
      and source_snapshot ?& array[
        'id',
        'lead_id',
        'corretor_id',
        'estagio_id',
        'estagio_anterior_id',
        'observacao',
        'created_at',
        'empresa_id',
        'origem_evento',
        'motivo',
        'payload'
      ]::text[]
    )
);

alter table forensic_evidence.movement_disposition_evidence owner to postgres;
alter table forensic_evidence.movement_disposition_evidence enable row level security;
alter table forensic_evidence.movement_disposition_evidence force row level security;

revoke all on table forensic_evidence.movement_disposition_evidence from public;
revoke all on table forensic_evidence.movement_disposition_evidence
  from anon, authenticated, service_role;

create table forensic_evidence.movement_disposition_events (
  event_id uuid not null default pg_catalog.gen_random_uuid(),
  evidence_id uuid not null,
  event_type text not null,
  actor_identity text not null,
  authority_ref text not null,
  event_at timestamptz not null default pg_catalog.transaction_timestamp(),
  result text not null,
  details jsonb not null default '{}'::jsonb,

  constraint movement_disposition_events_pkey
    primary key (event_id),

  constraint movement_disposition_events_evidence_fkey
    foreign key (evidence_id)
    references forensic_evidence.movement_disposition_evidence(evidence_id)
    on delete restrict,

  constraint movement_disposition_events_type_check
    check (
      event_type in (
        'B1_DISPOSITION_COMMITTED',
        'B1_ROLLBACK_RESTORED_PRE_M1'
      )
    ),

  constraint movement_disposition_events_actor_check
    check (actor_identity like 'db_role:%' and pg_catalog.length(actor_identity) > 8),

  constraint movement_disposition_events_result_check
    check (result in ('COMMITTED', 'RESTORED_PRE_M1'))
);

alter table forensic_evidence.movement_disposition_events owner to postgres;
alter table forensic_evidence.movement_disposition_events enable row level security;
alter table forensic_evidence.movement_disposition_events force row level security;

revoke all on table forensic_evidence.movement_disposition_events from public;
revoke all on table forensic_evidence.movement_disposition_events
  from anon, authenticated, service_role;

create function forensic_evidence.reject_immutable_mutation()
returns trigger
language plpgsql
set search_path = 'pg_catalog'
as $b1_immutable$
begin
  raise exception 'B1_FORENSIC_EVIDENCE_IMMUTABLE';
end;
$b1_immutable$;

alter function forensic_evidence.reject_immutable_mutation() owner to postgres;
revoke all on function forensic_evidence.reject_immutable_mutation()
  from public, anon, authenticated, service_role;

create trigger trg_b1_evidence_immutable
before update or delete
on forensic_evidence.movement_disposition_evidence
for each row
execute function forensic_evidence.reject_immutable_mutation();

create trigger trg_b1_events_immutable
before update or delete
on forensic_evidence.movement_disposition_events
for each row
execute function forensic_evidence.reject_immutable_mutation();

-- Defense-in-depth for future objects created by postgres in this private schema.
alter default privileges for role postgres in schema forensic_evidence
  revoke all on tables from public, anon, authenticated, service_role;

alter default privileges for role postgres in schema forensic_evidence
  revoke all on sequences from public, anon, authenticated, service_role;

alter default privileges for role postgres in schema forensic_evidence
  revoke all on functions from public, anon, authenticated, service_role;

do $b1_preserve_and_retire$
declare
  v_movement public.funil_movimentacoes%rowtype;
  v_lead public.leads%rowtype;
  v_lead_after public.leads%rowtype;
  v_corretor public.corretores%rowtype;
  v_stage public.funil_estagios%rowtype;
  v_anomaly_a public.funil_movimentacoes%rowtype;
  v_anomaly_a_after public.funil_movimentacoes%rowtype;

  v_source_snapshot jsonb;
  v_digest_input jsonb;
  v_snapshot_digest bytea;
  v_lead_digest bytea;
  v_lead_after_digest bytea;
  v_anomaly_a_digest bytea;
  v_anomaly_a_after_digest bytea;

  v_unrelated_count_before bigint;
  v_unrelated_count_after bigint;
  v_unrelated_digest_before bytea;
  v_unrelated_digest_after bytea;
  v_total_before bigint;
  v_total_after bigint;
  v_history_count bigint;

  v_evidence_id uuid;
  v_deleted_id uuid;
  v_inserted integer;
  v_deleted integer;
  v_actor_identity text;
  v_disposition_at timestamptz := pg_catalog.transaction_timestamp();
begin
  -- Re-lock/revalidate exact source row after evidence boundary creation.
  select *
  into strict v_movement
  from public.funil_movimentacoes fm
  where fm.id = '4908c70c-f0b2-423c-8d18-4bc36eaac93a'::uuid
  for update;

  if v_movement.lead_id is distinct from 'b2b17060-c739-4af3-9ffe-bb39e5a98b1d'::uuid
     or v_movement.corretor_id is distinct from '9be9dae0-1699-49a2-a7ab-beeef274f22b'::uuid
     or v_movement.estagio_id is distinct from 'bc23dcc9-b4a2-4d3f-aeef-c0695845649a'::uuid
     or v_movement.estagio_anterior_id is not null
     or v_movement.created_at is distinct from '2026-04-30 19:15:40.939754+00'::timestamptz
     or v_movement.empresa_id is distinct from '651fa3b8-28b2-41bd-a3b4-35502c24925f'::uuid
     or v_movement.origem_evento::text is distinct from 'manual'
     or v_movement.motivo is not null then
    raise exception 'B1_EXEC_EXACT_MOVEMENT_SHAPE_DRIFT';
  end if;

  select *
  into strict v_lead
  from public.leads l
  where l.id = v_movement.lead_id
  for update;

  select *
  into strict v_corretor
  from public.corretores c
  where c.id = v_movement.corretor_id
  for share;

  select *
  into strict v_stage
  from public.funil_estagios fe
  where fe.id = v_movement.estagio_id
  for share;

  if v_lead.empresa_id is distinct from '651fa3b8-28b2-41bd-a3b4-35502c24925f'::uuid
     or v_corretor.empresa_id is distinct from 'a0000000-0000-0000-0000-000000000001'::uuid
     or v_stage.empresa_id is distinct from 'a0000000-0000-0000-0000-000000000001'::uuid
     or v_movement.empresa_id is distinct from v_lead.empresa_id
     or v_movement.empresa_id is not distinct from v_corretor.empresa_id
     or v_movement.empresa_id is not distinct from v_stage.empresa_id
     or v_corretor.empresa_id is distinct from v_stage.empresa_id then
    raise exception 'B1_EXEC_PARENT_TENANT_SHAPE_DRIFT';
  end if;

  select count(*)
  into v_history_count
  from public.funil_movimentacoes fm
  where fm.lead_id = v_movement.lead_id;

  if v_history_count <> 1 then
    raise exception 'B1_EXEC_MOVEMENT_HISTORY_CARDINALITY_DRIFT';
  end if;

  if exists (
    select 1
    from forensic_evidence.movement_disposition_evidence e
    where e.source_movement_id = v_movement.id
  ) then
    raise exception 'B1_EXEC_UNEXPECTED_EVIDENCE_IDENTITY_COLLISION';
  end if;

  -- Exact lead fingerprint is stored only as a digest; no lead PII is copied
  -- into the forensic evidence envelope.
  v_lead_digest :=
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.to_jsonb(v_lead)::text, 'UTF8'),
      'sha256'
    );

  select *
  into strict v_anomaly_a
  from public.funil_movimentacoes fm
  where fm.id = '20150d61-3e10-43c8-8dd4-39f1374765b8'::uuid
  for share;

  v_anomaly_a_digest :=
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.to_jsonb(v_anomaly_a)::text, 'UTF8'),
      'sha256'
    );

  select count(*)
  into v_total_before
  from public.funil_movimentacoes fm
  where fm.created_at <= v_disposition_at;

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
  into v_unrelated_count_before, v_unrelated_digest_before
  from public.funil_movimentacoes fm
  where fm.id <> v_movement.id
    and fm.created_at <= v_disposition_at;

  v_source_snapshot := pg_catalog.jsonb_build_object(
    'id', v_movement.id,
    'lead_id', v_movement.lead_id,
    'corretor_id', v_movement.corretor_id,
    'estagio_id', v_movement.estagio_id,
    'estagio_anterior_id', v_movement.estagio_anterior_id,
    'observacao', v_movement.observacao,
    'created_at', v_movement.created_at,
    'empresa_id', v_movement.empresa_id,
    'origem_evento', v_movement.origem_evento::text,
    'motivo', v_movement.motivo,
    'payload', v_movement.payload
  );

  -- v1 digest contract:
  -- fixed positional JSON array, normalized UUID text and UTC timestamp.
  v_digest_input := pg_catalog.jsonb_build_array(
    'fechai.funil_movimentacoes.b1.v1',
    v_movement.id::text,
    v_movement.lead_id::text,
    v_movement.corretor_id::text,
    v_movement.estagio_id::text,
    case
      when v_movement.estagio_anterior_id is null then null
      else v_movement.estagio_anterior_id::text
    end,
    v_movement.observacao,
    pg_catalog.to_char(
      v_movement.created_at at time zone 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
    ),
    v_movement.empresa_id::text,
    v_movement.origem_evento::text,
    v_movement.motivo,
    v_movement.payload
  );

  v_snapshot_digest :=
    extensions.digest(
      pg_catalog.convert_to(v_digest_input::text, 'UTF8'),
      'sha256'
    );

  v_actor_identity := 'db_role:' || session_user::text;

  insert into forensic_evidence.movement_disposition_evidence (
    finding_id,
    source_movement_id,
    source_lead_id,
    source_corretor_id,
    source_current_stage_id,
    source_previous_stage_id,
    movement_empresa_id,
    lead_empresa_id,
    corretor_empresa_id,
    current_stage_empresa_id,
    previous_stage_empresa_id,
    source_created_at,
    source_origem_evento,
    source_snapshot,
    snapshot_format_version,
    digest_algorithm,
    snapshot_digest,
    lead_row_digest,
    anomaly_a_row_digest,
    unrelated_movements_count_before,
    unrelated_movements_digest_before,
    movement_total_before,
    disposition_classification,
    historical_truth_status,
    disposition_authority_ref,
    disposition_at,
    implementation_ref,
    actor_identity,
    purpose,
    retention_state
  )
  values (
    'M1-C-F01/ANOMALY-B',
    v_movement.id,
    v_movement.lead_id,
    v_movement.corretor_id,
    v_movement.estagio_id,
    v_movement.estagio_anterior_id,
    v_movement.empresa_id,
    v_lead.empresa_id,
    v_corretor.empresa_id,
    v_stage.empresa_id,
    null,
    v_movement.created_at,
    v_movement.origem_evento::text,
    v_source_snapshot,
    'fechai.funil_movimentacoes.b1.v1',
    'SHA-256',
    v_snapshot_digest,
    v_lead_digest,
    v_anomaly_a_digest,
    v_unrelated_count_before,
    v_unrelated_digest_before,
    v_total_before,
    'ACTIVE_INVALID_MOVEMENT_RETIRED_AFTER_IMMUTABLE_EVIDENCE_PRESERVATION',
    'NOT_ESTABLISHED',
    'PA-FECHAI-M1-C-F01-B1-20260901-01',
    v_disposition_at,
    'migration:20260901020000_m1_c_f01_b1_anomaly_b_evidence_retirement',
    v_actor_identity,
    'M1-C-F01 B1 preserve contradictory movement evidence and retire exact active relation',
    'INDEFINITE_PENDING_SEPARATE_RETENTION_POLICY'
  )
  returning evidence_id into v_evidence_id;

  get diagnostics v_inserted = row_count;

  if v_inserted <> 1 or v_evidence_id is null then
    raise exception 'B1_EXEC_EVIDENCE_INSERT_CARDINALITY_FAILURE';
  end if;

  delete from public.funil_movimentacoes fm
  where fm.id = v_movement.id
    and fm.lead_id = v_movement.lead_id
    and fm.corretor_id = v_movement.corretor_id
    and fm.estagio_id = v_movement.estagio_id
    and fm.estagio_anterior_id is not distinct from v_movement.estagio_anterior_id
    and fm.observacao is not distinct from v_movement.observacao
    and fm.created_at = v_movement.created_at
    and fm.empresa_id = v_movement.empresa_id
    and fm.origem_evento is not distinct from v_movement.origem_evento
    and fm.motivo is not distinct from v_movement.motivo
    and fm.payload is not distinct from v_movement.payload
  returning fm.id into v_deleted_id;

  get diagnostics v_deleted = row_count;

  if v_deleted <> 1 or v_deleted_id is distinct from v_movement.id then
    raise exception 'B1_EXEC_ACTIVE_RETIREMENT_CARDINALITY_FAILURE';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    where fm.id = v_movement.id
  ) then
    raise exception 'B1_EXEC_ACTIVE_MOVEMENT_STILL_PRESENT';
  end if;

  -- Explicitly prove zero lead mutation inside the same serialized transaction.
  select *
  into strict v_lead_after
  from public.leads l
  where l.id = v_lead.id;

  v_lead_after_digest :=
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.to_jsonb(v_lead_after)::text, 'UTF8'),
      'sha256'
    );

  if v_lead_after_digest is distinct from v_lead_digest then
    raise exception 'B1_EXEC_LEAD_MUTATION_DETECTED';
  end if;

  select *
  into strict v_anomaly_a_after
  from public.funil_movimentacoes fm
  where fm.id = v_anomaly_a.id;

  v_anomaly_a_after_digest :=
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.to_jsonb(v_anomaly_a_after)::text, 'UTF8'),
      'sha256'
    );

  if v_anomaly_a_after_digest is distinct from v_anomaly_a_digest then
    raise exception 'B1_EXEC_ANOMALY_A_MUTATION_DETECTED';
  end if;

  select count(*)
  into v_total_after
  from public.funil_movimentacoes fm
  where fm.created_at <= v_disposition_at;

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
  into v_unrelated_count_after, v_unrelated_digest_after
  from public.funil_movimentacoes fm
  where fm.id <> v_movement.id
    and fm.created_at <= v_disposition_at;

  if v_total_after <> v_total_before - 1
     or v_unrelated_count_after <> v_unrelated_count_before
     or v_unrelated_digest_after is distinct from v_unrelated_digest_before then
    raise exception 'B1_EXEC_UNRELATED_MOVEMENT_MUTATION_DETECTED';
  end if;

  insert into forensic_evidence.movement_disposition_events (
    evidence_id,
    event_type,
    actor_identity,
    authority_ref,
    result,
    details
  )
  values (
    v_evidence_id,
    'B1_DISPOSITION_COMMITTED',
    v_actor_identity,
    'PA-FECHAI-M1-C-F01-B1-20260901-01',
    'COMMITTED',
    pg_catalog.jsonb_build_object(
      'source_movement_id', v_movement.id,
      'snapshot_digest_hex', pg_catalog.encode(v_snapshot_digest, 'hex'),
      'implementation_ref',
        'migration:20260901020000_m1_c_f01_b1_anomaly_b_evidence_retirement'
    )
  );
end;
$b1_preserve_and_retire$;

commit;
