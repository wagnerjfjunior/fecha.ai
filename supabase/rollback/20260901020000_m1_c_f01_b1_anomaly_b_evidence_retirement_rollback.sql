-- FECH.AI — M1-C-F01 / Anomaly B / Packet B1 rollback
--
-- SECURITY-SAFE CONDITIONAL ROLLBACK.
--
-- This artifact NEVER deletes or rewrites forensic evidence.
-- It may restore the exact retired movement only BEFORE M1-C-F01 structural
-- enforcement, only under a separate explicit rollback authority, and only if
-- the preserved snapshot/digest and current parent context still match.
--
-- If M1-C-F01 is recorded/applied, or exact restoration would require bypassing
-- integrity controls, this artifact MUST fail closed.
--
-- VERSIONED ARTIFACT ONLY until separately authorized for rollback execution.

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';
set local idle_in_transaction_session_timeout = '60s';

do $b1_rollback_preflight$
declare
  v_m1_recorded boolean;
  v_target_fk_count integer;
  v_authority_ref text;
begin
  if pg_catalog.to_regclass('public.funil_movimentacoes') is null
     or pg_catalog.to_regclass('public.leads') is null
     or pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.funil_estagios') is null then
    raise exception 'B1_ROLLBACK_REQUIRED_SOURCE_OBJECT_MISSING';
  end if;

  if pg_catalog.to_regclass(
       'forensic_evidence.movement_disposition_evidence'
     ) is null
     or pg_catalog.to_regclass(
       'forensic_evidence.movement_disposition_events'
     ) is null then
    raise exception 'B1_ROLLBACK_EVIDENCE_BOUNDARY_MISSING';
  end if;

  if pg_catalog.to_regprocedure('extensions.digest(bytea,text)') is null then
    raise exception 'B1_ROLLBACK_PGCRYPTO_DIGEST_UNAVAILABLE';
  end if;

  if pg_catalog.to_regclass('supabase_migrations.schema_migrations') is null then
    raise exception 'B1_ROLLBACK_MIGRATION_LEDGER_UNAVAILABLE';
  end if;

  select exists(
    select 1
    from supabase_migrations.schema_migrations sm
    where sm.version::text = '20260831120000'
  )
  into v_m1_recorded;

  if v_m1_recorded then
    raise exception
      'B1_ROLLBACK_RESTORATION_PROHIBITED_AFTER_M1_C_F01_RECORDING';
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
    raise exception
      'B1_ROLLBACK_RESTORATION_PROHIBITED_BY_M1_C_F01_TARGET_CONSTRAINT';
  end if;

  v_authority_ref :=
    nullif(
      pg_catalog.current_setting(
        'fechai.b1_rollback_authority_ref',
        true
      ),
      ''
    );

  if v_authority_ref is null then
    raise exception 'B1_ROLLBACK_SEPARATE_PRODUCT_AUTHORITY_REQUIRED';
  end if;
end;
$b1_rollback_preflight$;

-- Serialize movement writes while exact restoration is adjudicated and applied.
lock table public.funil_movimentacoes in share row exclusive mode;

do $b1_restore_exact_movement$
declare
  v_evidence forensic_evidence.movement_disposition_evidence%rowtype;
  v_lead public.leads%rowtype;
  v_corretor public.corretores%rowtype;
  v_stage public.funil_estagios%rowtype;
  v_restored public.funil_movimentacoes%rowtype;

  v_digest_input jsonb;
  v_recomputed_digest bytea;
  v_restored_digest_input jsonb;
  v_restored_digest bytea;

  v_inserted integer;
  v_restored_id uuid;
  v_actor_identity text;
  v_rollback_authority_ref text;
begin
  v_rollback_authority_ref :=
    nullif(
      pg_catalog.current_setting(
        'fechai.b1_rollback_authority_ref',
        true
      ),
      ''
    );

  if v_rollback_authority_ref is null then
    raise exception 'B1_ROLLBACK_SEPARATE_PRODUCT_AUTHORITY_REQUIRED';
  end if;

  select *
  into strict v_evidence
  from forensic_evidence.movement_disposition_evidence e
  where e.source_movement_id =
    '4908c70c-f0b2-423c-8d18-4bc36eaac93a'::uuid
  for share;

  if v_evidence.finding_id is distinct from 'M1-C-F01/ANOMALY-B'
     or v_evidence.source_lead_id is distinct from
        'b2b17060-c739-4af3-9ffe-bb39e5a98b1d'::uuid
     or v_evidence.source_corretor_id is distinct from
        '9be9dae0-1699-49a2-a7ab-beeef274f22b'::uuid
     or v_evidence.source_current_stage_id is distinct from
        'bc23dcc9-b4a2-4d3f-aeef-c0695845649a'::uuid
     or v_evidence.source_previous_stage_id is not null
     or v_evidence.historical_truth_status is distinct from 'NOT_ESTABLISHED'
     or v_evidence.disposition_authority_ref is distinct from
        'PA-FECHAI-M1-C-F01-B1-20260901-01'
     or v_evidence.snapshot_format_version is distinct from
        'fechai.funil_movimentacoes.b1.v1'
     or v_evidence.digest_algorithm is distinct from 'SHA-256' then
    raise exception 'B1_ROLLBACK_EVIDENCE_CONTRACT_DRIFT';
  end if;

  -- Recompute the v1 source-snapshot digest from immutable evidence.
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
    raise exception 'B1_ROLLBACK_EVIDENCE_DIGEST_MISMATCH';
  end if;

  if exists (
    select 1
    from public.funil_movimentacoes fm
    where fm.id = v_evidence.source_movement_id
  ) then
    raise exception 'B1_ROLLBACK_SOURCE_MOVEMENT_ID_ALREADY_PRESENT';
  end if;

  select *
  into strict v_lead
  from public.leads l
  where l.id = v_evidence.source_lead_id
  for update;

  select *
  into strict v_corretor
  from public.corretores c
  where c.id = v_evidence.source_corretor_id
  for share;

  select *
  into strict v_stage
  from public.funil_estagios fe
  where fe.id = v_evidence.source_current_stage_id
  for share;

  if v_lead.empresa_id is distinct from v_evidence.lead_empresa_id
     or v_corretor.empresa_id is distinct from v_evidence.corretor_empresa_id
     or v_stage.empresa_id is distinct from v_evidence.current_stage_empresa_id
     or v_evidence.source_previous_stage_id is not null
     or v_evidence.previous_stage_empresa_id is not null then
    raise exception 'B1_ROLLBACK_PARENT_CONTEXT_DRIFT';
  end if;

  -- Restore ONLY the exact original active movement. The affected lead is never
  -- mutated by this rollback.
  insert into public.funil_movimentacoes (
    id,
    lead_id,
    corretor_id,
    estagio_id,
    estagio_anterior_id,
    observacao,
    created_at,
    empresa_id,
    origem_evento,
    motivo,
    payload
  )
  values (
    (v_evidence.source_snapshot->>'id')::uuid,
    (v_evidence.source_snapshot->>'lead_id')::uuid,
    (v_evidence.source_snapshot->>'corretor_id')::uuid,
    (v_evidence.source_snapshot->>'estagio_id')::uuid,
    case
      when v_evidence.source_snapshot->'estagio_anterior_id' = 'null'::jsonb
        then null
      else
        (v_evidence.source_snapshot->>'estagio_anterior_id')::uuid
    end,
    v_evidence.source_snapshot->>'observacao',
    (v_evidence.source_snapshot->>'created_at')::timestamptz,
    (v_evidence.source_snapshot->>'empresa_id')::uuid,
    (v_evidence.source_snapshot->>'origem_evento')::public.funil_origem_evento,
    v_evidence.source_snapshot->>'motivo',
    case
      when v_evidence.source_snapshot->'payload' = 'null'::jsonb then null
      else v_evidence.source_snapshot->'payload'
    end
  )
  returning id into v_restored_id;

  get diagnostics v_inserted = row_count;

  if v_inserted <> 1
     or v_restored_id is distinct from v_evidence.source_movement_id then
    raise exception 'B1_ROLLBACK_RESTORE_CARDINALITY_FAILURE';
  end if;

  select *
  into strict v_restored
  from public.funil_movimentacoes fm
  where fm.id = v_evidence.source_movement_id;

  v_restored_digest_input := pg_catalog.jsonb_build_array(
    v_evidence.snapshot_format_version,
    v_restored.id::text,
    v_restored.lead_id::text,
    v_restored.corretor_id::text,
    v_restored.estagio_id::text,
    case
      when v_restored.estagio_anterior_id is null then null
      else v_restored.estagio_anterior_id::text
    end,
    v_restored.observacao,
    pg_catalog.to_char(
      v_restored.created_at at time zone 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
    ),
    v_restored.empresa_id::text,
    v_restored.origem_evento::text,
    v_restored.motivo,
    v_restored.payload
  );

  v_restored_digest :=
    extensions.digest(
      pg_catalog.convert_to(v_restored_digest_input::text, 'UTF8'),
      'sha256'
    );

  if v_restored_digest is distinct from v_evidence.snapshot_digest then
    raise exception 'B1_ROLLBACK_RESTORED_ROW_FIDELITY_FAILURE';
  end if;

  v_actor_identity := 'db_role:' || session_user::text;

  insert into forensic_evidence.movement_disposition_events (
    evidence_id,
    event_type,
    actor_identity,
    authority_ref,
    result,
    details
  )
  values (
    v_evidence.evidence_id,
    'B1_ROLLBACK_RESTORED_PRE_M1',
    v_actor_identity,
    v_rollback_authority_ref,
    'RESTORED_PRE_M1',
    pg_catalog.jsonb_build_object(
      'source_movement_id', v_evidence.source_movement_id,
      'snapshot_digest_hex',
        pg_catalog.encode(v_evidence.snapshot_digest, 'hex'),
      'historical_truth_status', 'NOT_ESTABLISHED'
    )
  );
end;
$b1_restore_exact_movement$;

commit;
