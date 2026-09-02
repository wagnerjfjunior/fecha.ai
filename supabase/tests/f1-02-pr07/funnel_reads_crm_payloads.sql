-- FECH.AI — F1-02 / PR-07
-- READ_ONLY post-application catalog/static-contract proof.
-- This file performs no mutation.
-- It does NOT establish hostile/runtime-negative PASS.
-- Runtime/concurrency cases listed below remain NOT_EXECUTED until separately authorized.

BEGIN READ ONLY;

WITH table_state AS (
  SELECT
    c.oid,
    pg_catalog.pg_get_userbyid(c.relowner) AS owner_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS force_rls,
    EXISTS (
      SELECT 1
      FROM pg_catalog.aclexplode(
        coalesce(c.relacl, pg_catalog.acldefault('r', c.relowner))
      ) e
      WHERE e.grantee = 0
        AND e.privilege_type IN ('SELECT','INSERT','UPDATE','DELETE')
    ) AS public_client_dml
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'importar_leads_batch_idempotency'
    AND c.relkind = 'r'
),
policy_state AS (
  SELECT pg_catalog.count(*) AS policy_count
  FROM pg_catalog.pg_policy p
  WHERE p.polrelid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass
),
constraint_state AS (
  SELECT pg_catalog.jsonb_agg(
    pg_catalog.jsonb_build_object(
      'name', c.conname,
      'type', c.contype,
      'definition', pg_catalog.pg_get_constraintdef(c.oid, true)
    )
    ORDER BY c.conname
  ) AS constraints
  FROM pg_catalog.pg_constraint c
  WHERE c.conrelid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass
),
function_state AS (
  SELECT pg_catalog.jsonb_agg(
    pg_catalog.jsonb_build_object(
      'signature', p.oid::pg_catalog.regprocedure::text,
      'owner', pg_catalog.pg_get_userbyid(p.proowner),
      'security_definer', p.prosecdef,
      'config', p.proconfig,
      'acl', p.proacl::text,
      'definition_md5', pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
      'definition', pg_catalog.pg_get_functiondef(p.oid)
    )
    ORDER BY p.oid::pg_catalog.regprocedure::text
  ) AS functions
  FROM pg_catalog.pg_proc p
  WHERE p.oid IN (
    'public.listar_funil_estagios()'::pg_catalog.regprocedure,
    'public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure,
    'public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
  )
),
definition_signals AS (
  SELECT
    pg_catalog.pg_get_functiondef('public.listar_funil_estagios()'::pg_catalog.regprocedure) AS stage_def,
    pg_catalog.pg_get_functiondef('public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure) AS import_def,
    pg_catalog.pg_get_functiondef('public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure) AS feedback_def
),
parent_state AS (
  SELECT
    EXISTS (
      SELECT 1
      FROM pg_catalog.pg_constraint c
      WHERE c.conrelid = 'public.listas'::pg_catalog.regclass
        AND c.contype = 'u'
        AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (id, empresa_id)'
    ) AS listas_composite_key_preserved,
    EXISTS (
      SELECT 1
      FROM pg_catalog.pg_constraint c
      WHERE c.conrelid = 'public.logs'::pg_catalog.regclass
        AND c.conname = 'logs_sessao_id_unique'
        AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (sessao_id)'
    ) AS logs_session_uuid_unique_preserved
),
runtime_plan AS (
  SELECT pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('test_id','STG-001','case','no session denied/type-stable []','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','STG-002','case','no/inactive profile denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','STG-003','case','own-company stages returned','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','STG-004','case','other-company stages excluded','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','STG-005','case','deterministic ordem,id ordering','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','STG-006','case','tenant with zero stages returns []','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','STG-007','case','ROOT with empresa_id denied','status','NOT_EXECUTED'),

    pg_catalog.jsonb_build_object('test_id','IMP-001','case','same tenant/list/session/payload replay returns identical counters','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-002','case','different tenants same textual session do not collide','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-003','case','genuine concurrent same-key requests produce one logical import','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-004','case','cross-tenant list denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-005','case','non-array payload denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-006','case','batch >100 denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-007','case','unexpected/authority field denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-008','case','malformed member/type denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-009','case','invalid final member proves zero earlier writes','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-010','case','positive <=100 bounded import','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-011','case','canonical deterministic replay result','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-012','case','ROOT ordinary import denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-SESSION-LIST-MISMATCH','case','same tenant/session different lista_id fails closed with zero mutation','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-SESSION-PAYLOAD-MISMATCH','case','same tenant/session/list changed payload digest fails closed','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-CLAIMANT-ROLLBACK','case','aborted claimant leaves no marker/business mutation','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IMP-INCOMPLETE-STATE','case','committed incomplete idempotency row fails closed','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','IDEMPOTENCY-TABLE-DIRECT-DML','case','PUBLIC/anon/authenticated/service_role direct DML absent','status','CATALOG_PROOF_ONLY'),
    pg_catalog.jsonb_build_object('test_id','IDEMPOTENCY-TENANT-FK','case','mismatched lista/empresa structurally impossible','status','CATALOG_PROOF_ONLY'),

    pg_catalog.jsonb_build_object('test_id','FDB-001','case','null feedback denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-002','case','empty feedback denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-003','case','unknown feedback denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-004','case','malformed feedback denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-005','case','wrong-owner lead denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-006','case','cross-tenant lead denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-007','case','inactive/no profile denied','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-008','case','valid feedback succeeds','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-009','case','valid stage/history/status effects preserved','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-010','case','invalid feedback leaves lead/history/lot/log fingerprints unchanged','status','NOT_EXECUTED'),
    pg_catalog.jsonb_build_object('test_id','FDB-011','case','ROOT ordinary feedback denied','status','NOT_EXECUTED'),

    pg_catalog.jsonb_build_object('test_id','ROL-PR07','case','rollback exact hashes/grants/schema cleanup/data preservation then reapply','status','NOT_EXECUTED')
  ) AS tests
)
SELECT pg_catalog.jsonb_build_object(
  'proof_id', 'F1-02/PR-07',
  'idempotency_table_exists', ts.oid IS NOT NULL,
  'idempotency_owner', ts.owner_name,
  'idempotency_rls_enabled', ts.rls_enabled,
  'idempotency_force_rls', ts.force_rls,
  'idempotency_policy_count', ps.policy_count,
  'idempotency_public_client_dml', ts.public_client_dml,

  'idempotency_anon_select',
    pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','SELECT'),
  'idempotency_anon_insert',
    pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','INSERT'),
  'idempotency_anon_update',
    pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','UPDATE'),
  'idempotency_anon_delete',
    pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','DELETE'),

  'idempotency_authenticated_select',
    pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','SELECT'),
  'idempotency_authenticated_insert',
    pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','INSERT'),
  'idempotency_authenticated_update',
    pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','UPDATE'),
  'idempotency_authenticated_delete',
    pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','DELETE'),

  'idempotency_service_role_select',
    pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','SELECT'),
  'idempotency_service_role_insert',
    pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','INSERT'),
  'idempotency_service_role_update',
    pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','UPDATE'),
  'idempotency_service_role_delete',
    pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','DELETE'),

  'constraints', cs.constraints,
  'listas_composite_key_preserved', parent.listas_composite_key_preserved,
  'logs_session_uuid_unique_preserved', parent.logs_session_uuid_unique_preserved,

  'stage_owner', (
    SELECT pg_catalog.pg_get_userbyid(p.proowner)
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.listar_funil_estagios()'::pg_catalog.regprocedure
  ),
  'stage_security_definer', (
    SELECT p.prosecdef
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.listar_funil_estagios()'::pg_catalog.regprocedure
  ),
  'stage_search_path', (
    SELECT p.proconfig
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.listar_funil_estagios()'::pg_catalog.regprocedure
  ),
  'stage_authenticated_execute',
    pg_catalog.has_function_privilege('authenticated','public.listar_funil_estagios()','EXECUTE'),
  'stage_anon_execute',
    pg_catalog.has_function_privilege('anon','public.listar_funil_estagios()','EXECUTE'),
  'stage_service_role_execute',
    pg_catalog.has_function_privilege('service_role','public.listar_funil_estagios()','EXECUTE'),

  'import_owner', (
    SELECT pg_catalog.pg_get_userbyid(p.proowner)
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure
  ),
  'import_security_definer', (
    SELECT p.prosecdef
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure
  ),
  'import_search_path', (
    SELECT p.proconfig
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure
  ),
  'import_authenticated_execute',
    pg_catalog.has_function_privilege('authenticated','public.importar_leads_batch(uuid,jsonb,text)','EXECUTE'),
  'import_anon_execute',
    pg_catalog.has_function_privilege('anon','public.importar_leads_batch(uuid,jsonb,text)','EXECUTE'),
  'import_service_role_execute',
    pg_catalog.has_function_privilege('service_role','public.importar_leads_batch(uuid,jsonb,text)','EXECUTE'),

  'feedback_owner', (
    SELECT pg_catalog.pg_get_userbyid(p.proowner)
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
  ),
  'feedback_security_definer', (
    SELECT p.prosecdef
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
  ),
  'feedback_search_path', (
    SELECT p.proconfig
    FROM pg_catalog.pg_proc p
    WHERE p.oid='public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
  ),
  'feedback_authenticated_execute',
    pg_catalog.has_function_privilege('authenticated','public.registrar_feedback(uuid,text,text)','EXECUTE'),
  'feedback_anon_execute',
    pg_catalog.has_function_privilege('anon','public.registrar_feedback(uuid,text,text)','EXECUTE'),
  'feedback_service_role_execute',
    pg_catalog.has_function_privilege('service_role','public.registrar_feedback(uuid,text,text)','EXECUTE'),

  'stage_contract_signals', pg_catalog.jsonb_build_object(
    'explicit_root_denial', pg_catalog.strpos(defs.stage_def, 'public.is_root()') > 0,
    'tenant_filter', pg_catalog.strpos(defs.stage_def, 'fe.empresa_id = v_empresa_id') > 0,
    'no_global_branch', pg_catalog.strpos(defs.stage_def, 'empresa_id IS NULL') = 0,
    'deterministic_order', pg_catalog.strpos(defs.stage_def, 'ORDER BY fe.ordem ASC, fe.id ASC') > 0
  ),

  'import_contract_signals', pg_catalog.jsonb_build_object(
    'explicit_root_denial', pg_catalog.strpos(defs.import_def, 'public.is_root()') > 0,
    'idempotency_table', pg_catalog.strpos(defs.import_def, 'public.importar_leads_batch_idempotency') > 0,
    'sha256_digest', pg_catalog.strpos(defs.import_def, 'extensions.digest') > 0
                     AND pg_catalog.strpos(defs.import_def, 'sha256') > 0,
    'session_list_mismatch', pg_catalog.strpos(defs.import_def, 'SESSION_LIST_MISMATCH') > 0,
    'session_payload_mismatch', pg_catalog.strpos(defs.import_def, 'SESSION_PAYLOAD_MISMATCH') > 0,
    'incomplete_state_denial', pg_catalog.strpos(defs.import_def, 'IDEMPOTENCY_INCOMPLETE') > 0,
    'server_batch_limit_100', pg_catalog.strpos(defs.import_def, 'jsonb_array_length(p_leads) > 100') > 0,
    'generic_sqlerrm_not_returned', pg_catalog.strpos(defs.import_def, 'SQLERRM') = 0
  ),

  'feedback_contract_signals', pg_catalog.jsonb_build_object(
    'explicit_root_denial', pg_catalog.strpos(defs.feedback_def, 'public.is_root()') > 0,
    'strict_enum_cast', pg_catalog.strpos(defs.feedback_def, 'v_feedback_text::public.lead_feedback_tipo') > 0,
    'no_invalid_cast_null_continue', pg_catalog.strpos(pg_catalog.lower(defs.feedback_def), 'v_feedback_tipo := null') = 0,
    'trusted_text_branching', pg_catalog.strpos(defs.feedback_def, 'v_feedback_text := v_feedback_tipo::text') > 0
  ),

  'functions', fs.functions,
  'test_plan', rp.tests,
  'runtime_negative_pass', 'NOT_ESTABLISHED',
  'security_go', 'DENIED'
)
FROM table_state ts
CROSS JOIN policy_state ps
CROSS JOIN constraint_state cs
CROSS JOIN function_state fs
CROSS JOIN definition_signals defs
CROSS JOIN parent_state parent
CROSS JOIN runtime_plan rp;

ROLLBACK;
