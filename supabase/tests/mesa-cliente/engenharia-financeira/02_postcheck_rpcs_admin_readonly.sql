-- MesaCliente Engenharia Financeira — 02 Postcheck RPCs Administrativas Read-only
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar instalação estrutural das RPCs administrativas da Engenharia Financeira.
--
-- Segurança:
--   - Somente SELECT.
--   - Não cria dados.
--   - Não altera schema.
--   - Seguro para SQL Editor da produção.

with expected_functions as (
  select * from (values
    ('mesa_cliente_current_corretor_context', 'mesa_cliente_current_corretor_context()'),
    ('mesa_cliente_assert_auth', 'mesa_cliente_assert_auth()'),
    ('mesa_cliente_can_access_empresa', 'mesa_cliente_can_access_empresa(uuid)'),
    ('mesa_cliente_can_admin_empresa', 'mesa_cliente_can_admin_empresa(uuid)'),
    ('mesa_cliente_assert_empreendimento_empresa', 'mesa_cliente_assert_empreendimento_empresa(uuid,uuid)'),
    ('mesa_cliente_listar_politicas_financeiras', 'mesa_cliente_listar_politicas_financeiras(uuid,uuid,boolean,integer,integer)'),
    ('mesa_cliente_obter_politica_financeira', 'mesa_cliente_obter_politica_financeira(uuid,uuid)'),
    ('mesa_cliente_upsert_politica_financeira', 'mesa_cliente_upsert_politica_financeira(uuid,uuid,date,date,date,numeric,numeric,numeric,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,text)'),
    ('mesa_cliente_upsert_faixas_premio', 'mesa_cliente_upsert_faixas_premio(uuid,uuid,jsonb)')
  ) as f(function_name, signature)
), function_check as (
  select
    ef.function_name,
    ef.signature,
    to_regprocedure('public.' || ef.signature) is not null as exists_ok
  from expected_functions ef
), security_check as (
  select
    p.proname as function_name,
    p.prosecdef as security_definer,
    coalesce(array_to_string(p.proconfig, ', '), '') as config
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (select function_name from expected_functions)
), execute_grants as (
  select
    r.routine_name as function_name,
    r.privilege_type,
    r.grantee
  from information_schema.routine_privileges r
  where r.routine_schema = 'public'
    and r.routine_name in (
      'mesa_cliente_listar_politicas_financeiras',
      'mesa_cliente_obter_politica_financeira',
      'mesa_cliente_upsert_politica_financeira',
      'mesa_cliente_upsert_faixas_premio'
    )
    and r.privilege_type = 'EXECUTE'
), public_execute_grants as (
  select *
  from execute_grants
  where grantee = 'PUBLIC'
), authenticated_rpc_grants as (
  select *
  from execute_grants
  where grantee = 'authenticated'
)
select
  '01_expected_functions_exist' as bloco,
  case when count(*) = 9 and bool_and(exists_ok) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('function', function_name, 'signature', signature, 'exists', exists_ok) order by function_name) as detalhe
from function_check

union all

select
  '02_functions_are_security_definer' as bloco,
  case when count(*) = 9 and bool_and(security_definer) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('function', function_name, 'security_definer', security_definer, 'config', config) order by function_name) as detalhe
from security_check

union all

select
  '03_no_public_execute_on_admin_rpcs' as bloco,
  case when count(*) = 0 then 'PASS' else 'FAIL' end as status,
  coalesce(jsonb_agg(jsonb_build_object('function', function_name, 'grantee', grantee) order by function_name), '[]'::jsonb) as detalhe
from public_execute_grants

union all

select
  '04_authenticated_execute_on_admin_rpcs' as bloco,
  case when count(distinct function_name) = 4 then 'PASS' else 'FAIL' end as status,
  coalesce(jsonb_agg(jsonb_build_object('function', function_name, 'grantee', grantee) order by function_name), '[]'::jsonb) as detalhe
from authenticated_rpc_grants;
