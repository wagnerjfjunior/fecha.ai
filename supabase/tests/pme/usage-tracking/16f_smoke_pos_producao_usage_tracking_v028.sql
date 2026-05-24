-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- 16F — Smoke pós-produção read-only
--
-- Objetivo:
--   Validar em produção, sem fixture e sem mutação, que a entrega mergeada da v0.2.8
--   está disponível no catálogo do banco com RLS/hardening mínimos preservados.
--
-- Escopo validado:
--   1. inventário das migrations v0.2.8 no catálogo Supabase;
--   2. contrato/catálogo da RPC public.pme_registrar_message_usage(uuid,jsonb);
--   3. RLS/schema mínimo das tabelas PME;
--   4. ausência de policies UPDATE/DELETE em pme_message_usage;
--   5. inventário operacional read-only de templates/usages/leads;
--   6. readiness pós-produção sem DDL/DML.
--
-- Segurança do teste:
--   - transaction read only;
--   - sem DDL;
--   - sem DML;
--   - sem fixture;
--   - sem chamada mutacional à RPC, pois a RPC registra usage de forma append-only.

begin transaction read only;

with migrations_v028 as materialized (
  select
    v.version,
    exists (
      select 1
      from supabase_migrations.schema_migrations sm
      where sm.version = v.version
    ) as aplicada
  from (values
    ('20260523173000'),
    ('20260523202000')
  ) as v(version)
), fn as materialized (
  select
    p.oid,
    p.proname,
    oidvectortypes(p.proargtypes) as args,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    coalesce(p.proconfig, '{}'::text[]) as proconfig,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_execute,
    obj_description(p.oid, 'pg_proc') is not null as comentario_presente
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'pme_registrar_message_usage'
    and oidvectortypes(p.proargtypes) = 'uuid, jsonb'
), rpc_check as materialized (
  select
    case
      when count(*) = 1
       and bool_and(security_definer)
       and bool_and(proconfig @> array['search_path=public, pg_temp'])
       and bool_and(not anon_execute)
       and bool_and(authenticated_execute)
       and bool_and(service_role_execute)
       and bool_and(comentario_presente)
      then true
      else false
    end as pass,
    coalesce(jsonb_agg(jsonb_build_object(
      'proname', proname,
      'args', args,
      'security_definer', security_definer,
      'volatility', volatility,
      'search_path', proconfig,
      'anon_execute', anon_execute,
      'authenticated_execute', authenticated_execute,
      'service_role_execute', service_role_execute,
      'comentario_presente', comentario_presente
    )), '[]'::jsonb) as detalhe
  from fn
), tabelas as materialized (
  select
    c.relname,
    c.relrowsecurity as rls_ativo,
    c.relforcerowsecurity as force_rls
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('pme_message_templates', 'pme_message_usage')
), colunas_obrigatorias as materialized (
  select *
  from (values
    ('pme_message_usage','id'),
    ('pme_message_usage','empresa_id'),
    ('pme_message_usage','lead_id'),
    ('pme_message_usage','corretor_id'),
    ('pme_message_usage','template_id'),
    ('pme_message_usage','channel'),
    ('pme_message_usage','lead_type'),
    ('pme_message_usage','phase'),
    ('pme_message_usage','selection_mode'),
    ('pme_message_usage','status'),
    ('pme_message_usage','metadata'),
    ('pme_message_usage','created_at'),
    ('pme_message_templates','id'),
    ('pme_message_templates','empresa_id'),
    ('pme_message_templates','channel'),
    ('pme_message_templates','lead_type'),
    ('pme_message_templates','phase'),
    ('pme_message_templates','is_active')
  ) as v(table_name, column_name)
), colunas_status as materialized (
  select
    co.table_name,
    co.column_name,
    exists (
      select 1
      from information_schema.columns ic
      where ic.table_schema = 'public'
        and ic.table_name = co.table_name
        and ic.column_name = co.column_name
    ) as existe
  from colunas_obrigatorias co
), rls_schema_check as materialized (
  select
    case
      when (select count(*) from tabelas) = 2
       and coalesce((select bool_and(rls_ativo) from tabelas), false)
       and coalesce((select bool_and(existe) from colunas_status), false)
      then true
      else false
    end as pass,
    jsonb_build_object(
      'tabelas', coalesce((select jsonb_agg(jsonb_build_object(
        'relname', relname,
        'rls_ativo', rls_ativo,
        'force_rls', force_rls
      ) order by relname) from tabelas), '[]'::jsonb),
      'colunas', coalesce((select jsonb_agg(jsonb_build_object(
        'table_name', table_name,
        'column_name', column_name,
        'existe', existe
      ) order by table_name, column_name) from colunas_status), '[]'::jsonb)
    ) as detalhe
), policies_usage as materialized (
  select
    pp.tablename,
    pp.policyname,
    pp.cmd,
    pp.roles,
    pp.qual,
    pp.with_check
  from pg_policies pp
  where pp.schemaname = 'public'
    and pp.tablename in ('pme_message_templates', 'pme_message_usage')
), append_only_check as materialized (
  select
    case
      when not exists (
        select 1
        from policies_usage p
        where p.tablename = 'pme_message_usage'
          and p.cmd in ('UPDATE', 'DELETE')
      )
      then true
      else false
    end as pass,
    jsonb_build_object(
      'policies_update_delete_usage', (
        select count(*)
        from policies_usage p
        where p.tablename = 'pme_message_usage'
          and p.cmd in ('UPDATE', 'DELETE')
      ),
      'policies_inventario', coalesce((
        select jsonb_agg(jsonb_build_object(
          'tablename', tablename,
          'policyname', policyname,
          'cmd', cmd,
          'roles', roles
        ) order by tablename, policyname)
        from policies_usage
      ), '[]'::jsonb)
    ) as detalhe
), inventario_operacional as materialized (
  select jsonb_build_object(
    'pme_message_templates_total', (select count(*) from public.pme_message_templates),
    'pme_message_templates_ativos', (select count(*) from public.pme_message_templates where is_active = true),
    'pme_message_usage_total', (select count(*) from public.pme_message_usage),
    'leads_total', (select count(*) from public.leads),
    'observacao', 'inventario_readonly_sem_fixture_sem_execucao_mutacional_da_rpc'
  ) as detalhe
), readiness as materialized (
  select
    (select pass from rpc_check)
    and (select pass from rls_schema_check)
    and (select pass from append_only_check) as pass
)
select jsonb_pretty(jsonb_build_array(
  jsonb_build_object(
    'bloco', '00_migrations_v028_inventario',
    'status', 'INFO',
    'detalhe', coalesce((
      select jsonb_agg(jsonb_build_object('version', version, 'aplicada', aplicada) order by version)
      from migrations_v028
    ), '[]'::jsonb)
  ),
  jsonb_build_object(
    'bloco', '01_contrato_rpc_catalogo_pos_producao',
    'status', case when (select pass from rpc_check) then 'PASS' else 'FAIL' end,
    'detalhe', (select detalhe from rpc_check)
  ),
  jsonb_build_object(
    'bloco', '02_rls_schema_pme_pos_producao',
    'status', case when (select pass from rls_schema_check) then 'PASS' else 'FAIL' end,
    'detalhe', (select detalhe from rls_schema_check)
  ),
  jsonb_build_object(
    'bloco', '03_append_only_hardening_usage',
    'status', case when (select pass from append_only_check) then 'PASS' else 'FAIL' end,
    'detalhe', (select detalhe from append_only_check)
  ),
  jsonb_build_object(
    'bloco', '04_inventario_operacional_readonly',
    'status', 'INFO',
    'detalhe', (select detalhe from inventario_operacional)
  ),
  jsonb_build_object(
    'bloco', '05_execucao_rpc_mutacional',
    'status', 'SKIP',
    'detalhe', jsonb_build_object(
      'motivo', 'RPC pme_registrar_message_usage e append-only e grava uso; smoke 16F e transaction read only e nao executa DML em producao sem fixture controlada',
      'execucao_positiva_coberta_por', jsonb_build_array('16B', '16E'),
      'seguranca_cross_tenant_coberta_por', jsonb_build_array('16C', '16D', '16E')
    )
  ),
  jsonb_build_object(
    'bloco', '06_readiness_pos_producao',
    'status', case when (select pass from readiness) then 'PASS' else 'FAIL' end,
    'detalhe', jsonb_build_object(
      'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
      'readiness_pos_producao', (select pass from readiness),
      'ddl', false,
      'dml', false,
      'fixture', false,
      'transaction', 'read only'
    )
  ),
  jsonb_build_object(
    'bloco', '99_interpretacao_operacional',
    'status', 'INFO',
    'detalhe', jsonb_build_object(
      'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
      'teste', '16F',
      'tipo', 'smoke_pos_producao_readonly',
      'ddl', false,
      'dml', false,
      'fixture', false,
      'mensagem', 'Smoke pos-producao executado em transaction read only; sem fixture e sem chamada mutacional a RPC append-only.'
    )
  )
)) as resultado_16f;

rollback;
