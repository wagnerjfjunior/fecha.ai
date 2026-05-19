-- MesaCliente Engenharia Financeira — 00 Preflight Produção Read-only
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar o estado atual do banco de PRODUÇÃO antes de aplicar qualquer migration.
--
-- Segurança:
--   - Somente SELECT.
--   - Não cria dados.
--   - Não altera schema.
--   - Não executa DDL/DML.
--   - Seguro para rodar no SQL Editor do Supabase produção.
--
-- Uso:
--   1. Rodar antes da migration de hardening.
--   2. Salvar o resultado como evidência.
--   3. Se qualquer bloco retornar FAIL, não aplicar a migration.

with required_tables as (
  select unnest(array[
    'empresas',
    'empreendimentos',
    'corretores',
    'mesa_simulacoes',
    'mesa_cliente_politicas_financeiras',
    'mesa_cliente_politica_premio_faixas',
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes'
  ]) as table_name
), table_check as (
  select
    rt.table_name,
    to_regclass('public.' || rt.table_name) is not null as exists_ok
  from required_tables rt
), function_check as (
  select
    f.function_name,
    to_regprocedure('public.' || f.signature) is not null as exists_ok
  from (values
    ('is_root', 'is_root()'),
    ('my_empresa_id', 'my_empresa_id()'),
    ('my_corretor_id', 'my_corretor_id()')
  ) as f(function_name, signature)
), rls_check as (
  select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
), policy_count as (
  select
    tablename,
    count(*) as qtd_policies
  from pg_policies
  where schemaname = 'public'
    and tablename in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
  group by tablename
), duplicate_policy_check as (
  select
    tablename,
    count(*) filter (where policyname like 'mesa_%') as qtd_policies_legadas,
    count(*) filter (where policyname in (
      'mcpf_select_tenant',
      'mcpf_no_direct_insert',
      'mcpf_no_direct_update',
      'mcpf_no_direct_delete',
      'mcppf_select_tenant',
      'mcppf_no_direct_insert',
      'mcppf_no_direct_update',
      'mcppf_no_direct_delete',
      'mcfp_select_tenant',
      'mcfp_no_direct_insert',
      'mcfp_no_direct_update',
      'mcfp_no_direct_delete',
      'mcfo_select_tenant',
      'mcfo_no_direct_insert',
      'mcfo_no_direct_update',
      'mcfo_no_direct_delete'
    )) as qtd_policies_canonicas
  from pg_policies
  where schemaname = 'public'
    and tablename in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
  group by tablename
), trigger_check as (
  select
    c.relname as table_name,
    count(*) filter (where t.tgname in (
      'trg_mcpf_assert_integridade',
      'trg_mcppf_assert_integridade',
      'trg_mcfp_assert_integridade',
      'trg_mcfo_assert_integridade'
    )) as qtd_triggers_hardening
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  left join pg_trigger t on t.tgrelid = c.oid and not t.tgisinternal
  where n.nspname = 'public'
    and c.relname in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
  group by c.relname
), anon_grants as (
  select
    table_name,
    string_agg(privilege_type, ', ' order by privilege_type) as anon_privileges
  from information_schema.role_table_grants
  where table_schema = 'public'
    and grantee = 'anon'
    and table_name in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
  group by table_name
), auth_write_grants as (
  select
    table_name,
    string_agg(privilege_type, ', ' order by privilege_type) as authenticated_write_privileges
  from information_schema.role_table_grants
  where table_schema = 'public'
    and grantee = 'authenticated'
    and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
    and table_name in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
  group by table_name
)
select
  '01_required_tables' as bloco,
  case when bool_and(exists_ok) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'exists', exists_ok) order by table_name) as detalhe
from table_check

union all

select
  '02_required_functions' as bloco,
  case when bool_and(exists_ok) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('function', function_name, 'exists', exists_ok) order by function_name) as detalhe
from function_check

union all

select
  '03_rls_status' as bloco,
  case when count(*) = 4 and bool_and(rls_enabled) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'rls_enabled', rls_enabled) order by table_name) as detalhe
from rls_check

union all

select
  '04_current_policy_count' as bloco,
  'INFO' as status,
  coalesce(jsonb_agg(jsonb_build_object('table', tablename, 'qtd_policies', qtd_policies) order by tablename), '[]'::jsonb) as detalhe
from policy_count

union all

select
  '05_duplicate_policy_signal' as bloco,
  'INFO' as status,
  coalesce(jsonb_agg(jsonb_build_object(
    'table', tablename,
    'qtd_policies_legadas', qtd_policies_legadas,
    'qtd_policies_canonicas', qtd_policies_canonicas
  ) order by tablename), '[]'::jsonb) as detalhe
from duplicate_policy_check

union all

select
  '06_hardening_triggers_before_migration' as bloco,
  'INFO' as status,
  coalesce(jsonb_agg(jsonb_build_object('table', table_name, 'qtd_triggers_hardening', qtd_triggers_hardening) order by table_name), '[]'::jsonb) as detalhe
from trigger_check

union all

select
  '07_anon_privileges_should_be_empty_after_migration' as bloco,
  'INFO' as status,
  coalesce(jsonb_agg(jsonb_build_object('table', table_name, 'anon_privileges', anon_privileges) order by table_name), '[]'::jsonb) as detalhe
from anon_grants

union all

select
  '08_authenticated_write_privileges_should_be_empty_after_migration' as bloco,
  'INFO' as status,
  coalesce(jsonb_agg(jsonb_build_object('table', table_name, 'authenticated_write_privileges', authenticated_write_privileges) order by table_name), '[]'::jsonb) as detalhe
from auth_write_grants;
