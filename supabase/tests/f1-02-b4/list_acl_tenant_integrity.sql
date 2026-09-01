-- FECH.AI — F1-02/B4 / PR-06
-- READ_ONLY post-application catalog proof.
-- This performs no mutation and does NOT establish runtime-negative PASS.
-- Baseline ACL count: 12
-- Baseline ACL fingerprint (excluding created_at):
-- fdaa58d43a6a1d3ab93cd9a5f1f058ca
-- Controlled caller baselines:
-- listar_listas_corretor() = ccfe069e7ffe96e520521298c26d995d
-- solicitar_lote(uuid)    = f0adebaa3878c7f4c841c19ca5bd4743
-- Managed-team authority baseline:
-- my_times_como_gestor()    = b87d8181b65043ff169ef3ba9e4dd118
-- Contract encoded by that baseline:
-- gestor_id=my_corretor_id(), empresa_id=my_empresa_id(), active team only.
-- public/authenticated/anon have no CREATE privilege on schema public.

BEGIN READ ONLY;

WITH acl_state AS (
  SELECT
    count(*) AS row_count,
    md5(coalesce(string_agg(
      concat_ws('|',id::text,lista_id::text,target_type,target_id::text,
        coalesce(adicionado_por::text,''),empresa_id::text),
      E'\n' ORDER BY id
    ),'')) AS fingerprint,
    count(*) FILTER (WHERE target_type='empresa') AS empresa_targets,
    count(*) FILTER (WHERE target_type NOT IN ('corretor','time')) AS unsupported_targets
  FROM public.lista_visibilidade
),
integrity AS (
  SELECT
    count(*) FILTER (WHERE li.id IS NULL OR li.empresa_id IS DISTINCT FROM lv.empresa_id)
      AS list_company_mismatch,
    count(*) FILTER (
      WHERE lv.target_type='corretor'
        AND (c.id IS NULL OR c.empresa_id IS DISTINCT FROM lv.empresa_id
             OR coalesce(c.ativo,true) IS DISTINCT FROM true)
    ) AS invalid_broker_targets,
    count(*) FILTER (
      WHERE lv.target_type='time'
        AND (t.id IS NULL OR t.empresa_id IS DISTINCT FROM lv.empresa_id
             OR coalesce(t.ativo,true) IS DISTINCT FROM true)
    ) AS invalid_team_targets
  FROM public.lista_visibilidade lv
  LEFT JOIN public.listas li ON li.id=lv.lista_id
  LEFT JOIN public.corretores c ON lv.target_type='corretor' AND c.id=lv.target_id
  LEFT JOIN public.times t ON lv.target_type='time' AND t.id=lv.target_id
),
policy_state AS (
  SELECT jsonb_agg(jsonb_build_object(
    'policyname',policyname,'cmd',cmd,'roles',roles,'qual',qual,'with_check',with_check
  ) ORDER BY policyname) AS policies
  FROM pg_policies
  WHERE schemaname='public' AND tablename='lista_visibilidade'
),
constraint_state AS (
  SELECT jsonb_agg(jsonb_build_object(
    'name',conname,'type',contype,'definition',pg_get_constraintdef(oid,true)
  ) ORDER BY conname) AS constraints
  FROM pg_constraint
  WHERE conrelid='public.lista_visibilidade'::regclass
),
trigger_state AS (
  SELECT jsonb_agg(jsonb_build_object(
    'name',tgname,'definition',pg_get_triggerdef(oid,true)
  ) ORDER BY tgname) AS triggers
  FROM pg_trigger
  WHERE tgrelid='public.lista_visibilidade'::regclass AND NOT tgisinternal
),
function_state AS (
  SELECT jsonb_agg(jsonb_build_object(
    'signature',p.oid::regprocedure::text,
    'owner',pg_get_userbyid(p.proowner),
    'security_definer',p.prosecdef,
    'config',p.proconfig,
    'acl',p.proacl::text,
    'definition_md5',md5(pg_get_functiondef(p.oid)),
    'definition',pg_get_functiondef(p.oid)
  ) ORDER BY p.oid::regprocedure::text) AS functions
  FROM pg_proc p
  WHERE p.oid IN (
    'public.corretor_tem_acesso_lista(uuid,uuid,uuid,uuid)'::regprocedure,
    'public.gerenciar_visibilidade_lista(uuid,jsonb)'::regprocedure,
    'public.listar_membros_visibilidade()'::regprocedure,
    'public.listar_listas_corretor()'::regprocedure,
    'public.solicitar_lote(uuid)'::regprocedure,
    'public.my_times_como_gestor()'::regprocedure,
    'public.f1_02_b4_validate_lista_visibilidade_target()'::regprocedure
  )
)
SELECT jsonb_build_object(
  'proof_id','F1-02/B4/PR-06',
  'rls_enabled',cls.relrowsecurity,
  'force_rls',cls.relforcerowsecurity,
  'authenticated_select',has_table_privilege('authenticated','public.lista_visibilidade','SELECT'),
  'authenticated_insert',has_table_privilege('authenticated','public.lista_visibilidade','INSERT'),
  'authenticated_update',has_table_privilege('authenticated','public.lista_visibilidade','UPDATE'),
  'authenticated_delete',has_table_privilege('authenticated','public.lista_visibilidade','DELETE'),
  'helper_authenticated_execute',
    has_function_privilege('authenticated','public.corretor_tem_acesso_lista(uuid,uuid,uuid,uuid)','EXECUTE'),
  'helper_anon_execute',
    has_function_privilege('anon','public.corretor_tem_acesso_lista(uuid,uuid,uuid,uuid)','EXECUTE'),
  'helper_public_execute',
    has_function_privilege('public','public.corretor_tem_acesso_lista(uuid,uuid,uuid,uuid)','EXECUTE'),
  'management_authenticated_execute',
    has_function_privilege('authenticated','public.gerenciar_visibilidade_lista(uuid,jsonb)','EXECUTE'),
  'acl_rows',a.row_count,
  'acl_rows_equal_pre_b4',a.row_count=12,
  'acl_fingerprint',a.fingerprint,
  'acl_fingerprint_equal_pre_b4',a.fingerprint='fdaa58d43a6a1d3ab93cd9a5f1f058ca',
  'empresa_targets',a.empresa_targets,
  'unsupported_targets',a.unsupported_targets,
  'list_company_mismatch',i.list_company_mismatch,
  'invalid_broker_targets',i.invalid_broker_targets,
  'invalid_team_targets',i.invalid_team_targets,
  'listar_listas_corretor_definition_preserved',
    md5(pg_get_functiondef('public.listar_listas_corretor()'::regprocedure))
      ='ccfe069e7ffe96e520521298c26d995d',
  'solicitar_lote_definition_preserved',
    md5(pg_get_functiondef('public.solicitar_lote(uuid)'::regprocedure))
      ='f0adebaa3878c7f4c841c19ca5bd4743',

  'my_times_como_gestor_definition_preserved',
    md5(pg_get_functiondef('public.my_times_como_gestor()'::regprocedure))
      ='b87d8181b65043ff169ef3ba9e4dd118',
  'my_times_como_gestor_owner',
    (SELECT pg_get_userbyid(p.proowner)
     FROM pg_proc p
     WHERE p.oid='public.my_times_como_gestor()'::regprocedure),
  'my_times_como_gestor_security_definer',
    (SELECT p.prosecdef
     FROM pg_proc p
     WHERE p.oid='public.my_times_como_gestor()'::regprocedure),
  'my_times_como_gestor_search_path',
    (SELECT p.proconfig
     FROM pg_proc p
     WHERE p.oid='public.my_times_como_gestor()'::regprocedure),

  'public_schema_create_public',
    has_schema_privilege('public','public','CREATE'),
  'public_schema_create_authenticated',
    has_schema_privilege('authenticated','public','CREATE'),
  'public_schema_create_anon',
    has_schema_privilege('anon','public','CREATE'),

  'policies',ps.policies,
  'constraints',cs.constraints,
  'triggers',ts.triggers,
  'functions',fs.functions,
  'runtime_negative_pass','NOT_ESTABLISHED',
  'security_go','DENIED'
)
FROM pg_class cls
JOIN pg_namespace ns ON ns.oid=cls.relnamespace
CROSS JOIN acl_state a
CROSS JOIN integrity i
CROSS JOIN policy_state ps
CROSS JOIN constraint_state cs
CROSS JOIN trigger_state ts
CROSS JOIN function_state fs
WHERE ns.nspname='public' AND cls.relname='lista_visibilidade';

ROLLBACK;
