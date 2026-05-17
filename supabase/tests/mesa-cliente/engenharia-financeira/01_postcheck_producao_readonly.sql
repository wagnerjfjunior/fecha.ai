-- MesaCliente Engenharia Financeira — 01 Postcheck Produção Read-only
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar o estado do banco de PRODUÇÃO depois da migration de hardening.
--
-- Segurança:
--   - Somente SELECT.
--   - Não cria dados.
--   - Não altera schema.
--   - Não executa DDL/DML.
--   - Seguro para rodar no SQL Editor do Supabase produção.
--
-- Resultado esperado:
--   Todos os blocos críticos devem retornar PASS.

with finance_tables as (
  select unnest(array[
    'mesa_cliente_politicas_financeiras',
    'mesa_cliente_politica_premio_faixas',
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes'
  ]) as table_name
), rls_check as (
  select
    ft.table_name,
    coalesce(c.relrowsecurity, false) as rls_enabled
  from finance_tables ft
  left join pg_class c on c.oid = to_regclass('public.' || ft.table_name)
), canonical_policies as (
  select * from (values
    ('mesa_cliente_politicas_financeiras', 'mcpf_select_tenant'),
    ('mesa_cliente_politicas_financeiras', 'mcpf_no_direct_insert'),
    ('mesa_cliente_politicas_financeiras', 'mcpf_no_direct_update'),
    ('mesa_cliente_politicas_financeiras', 'mcpf_no_direct_delete'),
    ('mesa_cliente_politica_premio_faixas', 'mcppf_select_tenant'),
    ('mesa_cliente_politica_premio_faixas', 'mcppf_no_direct_insert'),
    ('mesa_cliente_politica_premio_faixas', 'mcppf_no_direct_update'),
    ('mesa_cliente_politica_premio_faixas', 'mcppf_no_direct_delete'),
    ('mesa_cliente_fluxo_parcelas', 'mcfp_select_tenant'),
    ('mesa_cliente_fluxo_parcelas', 'mcfp_no_direct_insert'),
    ('mesa_cliente_fluxo_parcelas', 'mcfp_no_direct_update'),
    ('mesa_cliente_fluxo_parcelas', 'mcfp_no_direct_delete'),
    ('mesa_cliente_fluxo_operacoes', 'mcfo_select_tenant'),
    ('mesa_cliente_fluxo_operacoes', 'mcfo_no_direct_insert'),
    ('mesa_cliente_fluxo_operacoes', 'mcfo_no_direct_update'),
    ('mesa_cliente_fluxo_operacoes', 'mcfo_no_direct_delete')
  ) as p(table_name, policy_name)
), canonical_policy_check as (
  select
    cp.table_name,
    cp.policy_name,
    exists (
      select 1
      from pg_policies pp
      where pp.schemaname = 'public'
        and pp.tablename = cp.table_name
        and pp.policyname = cp.policy_name
    ) as exists_ok
  from canonical_policies cp
), legacy_policy_check as (
  select
    p.tablename,
    p.policyname
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename in (select table_name from finance_tables)
    and p.policyname in (
      'mesa_politicas_financeiras_select_tenant',
      'mesa_politicas_financeiras_no_direct_insert',
      'mesa_politicas_financeiras_no_direct_update',
      'mesa_politicas_financeiras_no_direct_delete',
      'mesa_premio_faixas_select_tenant',
      'mesa_premio_faixas_no_direct_insert',
      'mesa_premio_faixas_no_direct_update',
      'mesa_premio_faixas_no_direct_delete',
      'mesa_fluxo_parcelas_select_tenant',
      'mesa_fluxo_parcelas_no_direct_insert',
      'mesa_fluxo_parcelas_no_direct_update',
      'mesa_fluxo_parcelas_no_direct_delete',
      'mesa_fluxo_operacoes_select_tenant',
      'mesa_fluxo_operacoes_no_direct_insert',
      'mesa_fluxo_operacoes_no_direct_update',
      'mesa_fluxo_operacoes_no_direct_delete'
    )
), trigger_check as (
  select
    ft.table_name,
    case ft.table_name
      when 'mesa_cliente_politicas_financeiras' then 'trg_mcpf_assert_integridade'
      when 'mesa_cliente_politica_premio_faixas' then 'trg_mcppf_assert_integridade'
      when 'mesa_cliente_fluxo_parcelas' then 'trg_mcfp_assert_integridade'
      when 'mesa_cliente_fluxo_operacoes' then 'trg_mcfo_assert_integridade'
    end as expected_trigger,
    exists (
      select 1
      from pg_trigger t
      where t.tgrelid = to_regclass('public.' || ft.table_name)
        and not t.tgisinternal
        and t.tgname = case ft.table_name
          when 'mesa_cliente_politicas_financeiras' then 'trg_mcpf_assert_integridade'
          when 'mesa_cliente_politica_premio_faixas' then 'trg_mcppf_assert_integridade'
          when 'mesa_cliente_fluxo_parcelas' then 'trg_mcfp_assert_integridade'
          when 'mesa_cliente_fluxo_operacoes' then 'trg_mcfo_assert_integridade'
        end
    ) as exists_ok
  from finance_tables ft
), anon_grants as (
  select
    table_name,
    privilege_type
  from information_schema.role_table_grants
  where table_schema = 'public'
    and grantee = 'anon'
    and table_name in (select table_name from finance_tables)
), auth_write_grants as (
  select
    table_name,
    privilege_type
  from information_schema.role_table_grants
  where table_schema = 'public'
    and grantee = 'authenticated'
    and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
    and table_name in (select table_name from finance_tables)
), function_check as (
  select
    'mesa_cliente_financeiro_assert_integridade()' as signature,
    to_regprocedure('public.mesa_cliente_financeiro_assert_integridade()') is not null as exists_ok
)
select
  '01_rls_enabled' as bloco,
  case when count(*) = 4 and bool_and(rls_enabled) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'rls_enabled', rls_enabled) order by table_name) as detalhe
from rls_check

union all

select
  '02_canonical_policies' as bloco,
  case when count(*) = 16 and bool_and(exists_ok) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'policy', policy_name, 'exists', exists_ok) order by table_name, policy_name) as detalhe
from canonical_policy_check

union all

select
  '03_legacy_policies_removed' as bloco,
  case when count(*) = 0 then 'PASS' else 'FAIL' end as status,
  coalesce(jsonb_agg(jsonb_build_object('table', tablename, 'policy', policyname) order by tablename, policyname), '[]'::jsonb) as detalhe
from legacy_policy_check

union all

select
  '04_integrity_triggers' as bloco,
  case when count(*) = 4 and bool_and(exists_ok) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('table', table_name, 'trigger', expected_trigger, 'exists', exists_ok) order by table_name) as detalhe
from trigger_check

union all

select
  '05_integrity_function' as bloco,
  case when bool_and(exists_ok) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('function', signature, 'exists', exists_ok)) as detalhe
from function_check

union all

select
  '06_anon_has_no_privileges' as bloco,
  case when count(*) = 0 then 'PASS' else 'FAIL' end as status,
  coalesce(jsonb_agg(jsonb_build_object('table', table_name, 'privilege', privilege_type) order by table_name, privilege_type), '[]'::jsonb) as detalhe
from anon_grants

union all

select
  '07_authenticated_has_no_direct_write_grants' as bloco,
  case when count(*) = 0 then 'PASS' else 'FAIL' end as status,
  coalesce(jsonb_agg(jsonb_build_object('table', table_name, 'privilege', privilege_type) order by table_name, privilege_type), '[]'::jsonb) as detalhe
from auth_write_grants;
