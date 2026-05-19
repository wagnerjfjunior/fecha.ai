-- MesaCliente Engenharia Financeira — 07 preflight read-only para Fase 3C
-- Objetivo:
--   Auditar o schema real antes de criar RPC que grava em mesa_cliente_fluxo_operacoes.
--
-- Segurança:
--   - Somente SELECT.
--   - Não cria dados.
--   - Não altera schema.
--   - Seguro para SQL Editor da produção.
--
-- Tabelas auditadas:
--   - mesa_simulacoes
--   - mesa_cliente_fluxo_parcelas
--   - mesa_cliente_fluxo_operacoes
--   - mesa_cliente_politicas_financeiras
--   - mesa_cliente_politica_premio_faixas
--
-- Envie o resultado completo deste script antes da migration 3C.

with required_tables as (
  select * from (values
    ('mesa_simulacoes'),
    ('mesa_cliente_fluxo_parcelas'),
    ('mesa_cliente_fluxo_operacoes'),
    ('mesa_cliente_politicas_financeiras'),
    ('mesa_cliente_politica_premio_faixas')
  ) as t(table_name)
), table_check as (
  select
    rt.table_name,
    to_regclass('public.' || rt.table_name) is not null as exists
  from required_tables rt
), columns_check as (
  select
    c.table_name,
    jsonb_agg(
      jsonb_build_object(
        'column', c.column_name,
        'data_type', c.data_type,
        'udt_name', c.udt_name,
        'nullable', c.is_nullable,
        'default', c.column_default,
        'ordinal', c.ordinal_position
      ) order by c.ordinal_position
    ) as columns_json
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name in (select table_name from required_tables)
  group by c.table_name
), constraints_check as (
  select
    tc.table_name,
    jsonb_agg(
      jsonb_build_object(
        'constraint_name', tc.constraint_name,
        'constraint_type', tc.constraint_type,
        'column_name', kcu.column_name,
        'foreign_table', ccu.table_name,
        'foreign_column', ccu.column_name
      ) order by tc.constraint_type, tc.constraint_name, kcu.ordinal_position
    ) as constraints_json
  from information_schema.table_constraints tc
  left join information_schema.key_column_usage kcu
    on tc.constraint_schema = kcu.constraint_schema
   and tc.constraint_name = kcu.constraint_name
   and tc.table_name = kcu.table_name
  left join information_schema.constraint_column_usage ccu
    on tc.constraint_schema = ccu.constraint_schema
   and tc.constraint_name = ccu.constraint_name
  where tc.table_schema = 'public'
    and tc.table_name in (select table_name from required_tables)
  group by tc.table_name
), rls_check as (
  select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as rls_forced
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (select table_name from required_tables)
), policies_check as (
  select
    p.tablename as table_name,
    jsonb_agg(
      jsonb_build_object(
        'policyname', p.policyname,
        'cmd', p.cmd,
        'roles', p.roles,
        'qual', p.qual,
        'with_check', p.with_check
      ) order by p.policyname
    ) as policies_json
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename in (select table_name from required_tables)
  group by p.tablename
), triggers_check as (
  select
    event_object_table as table_name,
    jsonb_agg(
      jsonb_build_object(
        'trigger_name', trigger_name,
        'event_manipulation', event_manipulation,
        'action_timing', action_timing,
        'action_statement', action_statement
      ) order by trigger_name, event_manipulation
    ) as triggers_json
  from information_schema.triggers
  where trigger_schema = 'public'
    and event_object_table in (select table_name from required_tables)
  group by event_object_table
), required_functions as (
  select * from (values
    ('mesa_cliente_assert_auth', 'mesa_cliente_assert_auth()'),
    ('mesa_cliente_current_corretor_context', 'mesa_cliente_current_corretor_context()'),
    ('mesa_cliente_can_access_empresa', 'mesa_cliente_can_access_empresa(uuid)'),
    ('mesa_cliente_can_admin_empresa', 'mesa_cliente_can_admin_empresa(uuid)'),
    ('mesa_cliente_assert_empreendimento_empresa', 'mesa_cliente_assert_empreendimento_empresa(uuid,uuid)'),
    ('mesa_cliente_simular_impacto_financeiro_admin', 'mesa_cliente_simular_impacto_financeiro_admin(uuid,uuid,date,jsonb,uuid)'),
    ('mesa_cliente_financeiro_calcular_vpl_parcela', 'mesa_cliente_financeiro_calcular_vpl_parcela(numeric,date,date,numeric,text)'),
    ('mesa_cliente_financeiro_calcular_antecipacao_composta', 'mesa_cliente_financeiro_calcular_antecipacao_composta(numeric,date,date,numeric,text)'),
    ('mesa_cliente_financeiro_calcular_postergacao_composta', 'mesa_cliente_financeiro_calcular_postergacao_composta(numeric,date,date,numeric,text)')
  ) as f(function_name, signature)
), functions_check as (
  select
    rf.function_name,
    rf.signature,
    to_regprocedure('public.' || rf.signature) is not null as exists
  from required_functions rf
), operation_column_flags as (
  select
    jsonb_object_agg(column_name, true order by column_name) as existing_columns
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'mesa_cliente_fluxo_operacoes'
), expected_operation_columns as (
  select * from (values
    ('id'),
    ('empresa_id'),
    ('empreendimento_id'),
    ('simulacao_id'),
    ('parcela_id'),
    ('politica_id'),
    ('tipo_operacao'),
    ('grupo'),
    ('valor_movido'),
    ('valor_original'),
    ('valor_calculado'),
    ('data_origem'),
    ('data_destino'),
    ('taxa_ano_pct'),
    ('vpl_aplicado_pct'),
    ('desconto_calculado'),
    ('acrescimo_calculado'),
    ('economia_liquida'),
    ('premio_corretor_pct'),
    ('status_operacao'),
    ('created_by'),
    ('created_at'),
    ('updated_at')
  ) as c(column_name)
), operation_missing_expected_columns as (
  select
    coalesce(jsonb_agg(eoc.column_name order by eoc.column_name), '[]'::jsonb) as missing_columns
  from expected_operation_columns eoc
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'mesa_cliente_fluxo_operacoes'
      and c.column_name = eoc.column_name
  )
), sample_counts as (
  select jsonb_build_object(
    'mesa_simulacoes', (select count(*) from public.mesa_simulacoes),
    'mesa_cliente_fluxo_parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas),
    'mesa_cliente_fluxo_operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes),
    'mesa_cliente_politicas_financeiras', (select count(*) from public.mesa_cliente_politicas_financeiras),
    'mesa_cliente_politica_premio_faixas', (select count(*) from public.mesa_cliente_politica_premio_faixas)
  ) as counts_json
)
select
  '01_required_tables' as bloco,
  case when count(*) = 5 and bool_and(exists) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'exists', exists) order by table_name) as detalhe
from table_check

union all

select
  '02_columns_by_table' as bloco,
  'INFO' as status,
  jsonb_object_agg(table_name, columns_json order by table_name) as detalhe
from columns_check

union all

select
  '03_constraints_by_table' as bloco,
  'INFO' as status,
  coalesce(jsonb_object_agg(table_name, constraints_json order by table_name), '{}'::jsonb) as detalhe
from constraints_check

union all

select
  '04_rls_status' as bloco,
  case when count(*) = 5 and bool_and(rls_enabled) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'rls_enabled', rls_enabled, 'rls_forced', rls_forced) order by table_name) as detalhe
from rls_check

union all

select
  '05_policies_by_table' as bloco,
  'INFO' as status,
  coalesce(jsonb_object_agg(table_name, policies_json order by table_name), '{}'::jsonb) as detalhe
from policies_check

union all

select
  '06_triggers_by_table' as bloco,
  'INFO' as status,
  coalesce(jsonb_object_agg(table_name, triggers_json order by table_name), '{}'::jsonb) as detalhe
from triggers_check

union all

select
  '07_required_functions' as bloco,
  case when count(*) = 9 and bool_and(exists) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('function', function_name, 'signature', signature, 'exists', exists) order by function_name) as detalhe
from functions_check

union all

select
  '08_operacao_columns_presence' as bloco,
  case when jsonb_array_length(missing_columns) = 0 then 'PASS' else 'REVIEW' end as status,
  jsonb_build_object(
    'existing_columns', (select existing_columns from operation_column_flags),
    'missing_expected_columns', missing_columns,
    'observacao', 'REVIEW não significa erro. Indica que a migration 3C deve adaptar inserts ao schema real.'
  ) as detalhe
from operation_missing_expected_columns

union all

select
  '09_table_counts' as bloco,
  'INFO' as status,
  counts_json as detalhe
from sample_counts;
