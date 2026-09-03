-- FECH.AI — F1-02 / J4 / PR-08
-- VERSIONED EXECUTABLE SQL CASES.
-- NOT EXECUTED by this implementation/correction.
\set ON_ERROR_STOP on

\if :{?PR08_SQL_CASE}
\else
  \echo 'PR08_SQL_CASE is required'
  \quit 3
\endif

SELECT :'PR08_SQL_CASE' = 'PRD-001' AS pr08_run_prd_001 \gset
SELECT :'PR08_SQL_CASE' = 'IMP-CLAIMANT-ROLLBACK' AS pr08_run_claimant \gset
SELECT :'PR08_SQL_CASE' = 'SERVER-EVIDENCE-PREFLIGHT' AS pr08_run_server_evidence_preflight \gset

\if :pr08_run_prd_001
  \echo 'FECH.AI PR-08 PRD-001 read-only catalog/static preflight'
  \ir ../f1-02-b2/direct_crm_write_boundary.sql
  \ir ../f1-02-b3/direct_funnel_history_insert_boundary.sql
  \ir ../f1-02-b4/list_acl_tenant_integrity.sql
  \ir ../f1-02-pr07/funnel_reads_crm_payloads.sql

\elif :pr08_run_server_evidence_preflight
  \if :{?PR08_TARGET_PROJECT_REF}
  \else
    \echo 'PR08_TARGET_PROJECT_REF is required'
    \quit 3
  \endif

  SELECT :'PR08_TARGET_PROJECT_REF' = 'uobxxgzshrmbtjfdolxd' AS pr08_is_production \gset
  \if :pr08_is_production
    \echo 'server evidence channel hard-denies production'
    \quit 3
  \endif

  BEGIN READ ONLY;

  SELECT 1 / CASE WHEN pg_catalog.current_user = 'postgres' THEN 1 ELSE 0 END
    AS server_evidence_owner_role_is_postgres;

  SELECT 1 / CASE WHEN EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'importar_leads_batch_idempotency'
      AND c.relkind = 'r'
      AND pg_catalog.pg_get_userbyid(c.relowner) = 'postgres'
      AND c.relrowsecurity = true
      AND c.relforcerowsecurity = true
  ) THEN 1 ELSE 0 END AS idempotency_owner_rls_force_boundary;

  SELECT 1 / CASE WHEN (
    SELECT pg_catalog.count(*)
    FROM pg_catalog.pg_policy p
    WHERE p.polrelid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass
  ) = 0 THEN 1 ELSE 0 END AS idempotency_zero_client_policies;

  SELECT 1 / CASE WHEN NOT (
       pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','SELECT')
    OR pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','INSERT')
    OR pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','UPDATE')
    OR pg_catalog.has_table_privilege('anon','public.importar_leads_batch_idempotency','DELETE')
    OR pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','SELECT')
    OR pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','INSERT')
    OR pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','UPDATE')
    OR pg_catalog.has_table_privilege('authenticated','public.importar_leads_batch_idempotency','DELETE')
    OR pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','SELECT')
    OR pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','INSERT')
    OR pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','UPDATE')
    OR pg_catalog.has_table_privilege('service_role','public.importar_leads_batch_idempotency','DELETE')
  ) THEN 1 ELSE 0 END AS idempotency_no_client_direct_dml;

  ROLLBACK;

\elif :pr08_run_claimant
  \if :{?PR08_SQL_RUNTIME_AUTHORIZED}
  \else
    \echo 'PR08_SQL_RUNTIME_AUTHORIZED is required'
    \quit 3
  \endif
  \if :{?PR08_TARGET_PROJECT_REF}
  \else
    \echo 'PR08_TARGET_PROJECT_REF is required'
    \quit 3
  \endif

  SELECT :'PR08_TARGET_PROJECT_REF' = 'uobxxgzshrmbtjfdolxd' AS pr08_is_production \gset
  \if :pr08_is_production
    \if :{?PR08_PRODUCTION_EXECUTION_AUTHORIZED}
    \else
      \echo 'production SQL runtime is not authorized'
      \quit 3
    \endif
  \endif

  \if :{?PR08_ACTOR_JWT_CLAIMS}
  \else
    \echo 'PR08_ACTOR_JWT_CLAIMS is required'
    \quit 3
  \endif
  \if :{?PR08_LISTA_ID}
  \else
    \echo 'PR08_LISTA_ID is required'
    \quit 3
  \endif
  \if :{?PR08_LEADS_JSON}
  \else
    \echo 'PR08_LEADS_JSON is required'
    \quit 3
  \endif
  \if :{?PR08_SESSION_ID}
  \else
    \echo 'PR08_SESSION_ID is required'
    \quit 3
  \endif
  \if :{?PR08_PROBE_PHONE}
  \else
    \echo 'PR08_PROBE_PHONE is required'
    \quit 3
  \endif

  BEGIN;
  SET LOCAL statement_timeout = '60s';
  SELECT pg_catalog.set_config('request.jwt.claims', :'PR08_ACTOR_JWT_CLAIMS', true);
  SELECT public.importar_leads_batch(
    :'PR08_LISTA_ID'::uuid,
    :'PR08_LEADS_JSON'::jsonb,
    :'PR08_SESSION_ID'
  );
  ROLLBACK;

  BEGIN READ ONLY;

  SELECT 1 / CASE WHEN NOT EXISTS (
    SELECT 1
    FROM public.leads
    WHERE lista_id = :'PR08_LISTA_ID'::uuid
      AND telefone_e164 = :'PR08_PROBE_PHONE'
  ) THEN 1 ELSE 0 END AS no_claimant_lead_residue;

  SELECT 1 / CASE WHEN NOT EXISTS (
    SELECT 1
    FROM public.importar_leads_batch_idempotency
    WHERE lista_id = :'PR08_LISTA_ID'::uuid
      AND sessao_id = :'PR08_SESSION_ID'
  ) THEN 1 ELSE 0 END AS no_claimant_marker_residue;

  SELECT 1 / CASE WHEN NOT EXISTS (
    SELECT 1
    FROM public.logs
    WHERE detalhes->>'sessao_id' = :'PR08_SESSION_ID'
  ) THEN 1 ELSE 0 END AS no_claimant_log_residue;

  ROLLBACK;

\else
  \echo 'Unknown PR08_SQL_CASE'
  \quit 3
\endif
