-- MesaCliente Engenharia Financeira — 06 Postcheck da RPC de simulação administrativa
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar instalação, grants e comportamento básico da RPC
--   mesa_cliente_simular_impacto_financeiro_admin().
--
-- Observação:
--   Este postcheck não cria política nem dados.
--   Para validação funcional completa, use o script 06B com transação e rollback.

with function_check as (
  select
    to_regprocedure('public.mesa_cliente_simular_impacto_financeiro_admin(uuid,uuid,date,jsonb,uuid)') is not null as exists_ok
), security_check as (
  select
    p.proname,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    coalesce(array_to_string(p.proconfig, ', '), '') as config
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'mesa_cliente_simular_impacto_financeiro_admin'
), grant_check as (
  select
    r.grantee,
    r.privilege_type
  from information_schema.routine_privileges r
  where r.routine_schema = 'public'
    and r.routine_name = 'mesa_cliente_simular_impacto_financeiro_admin'
    and r.privilege_type = 'EXECUTE'
), deps as (
  select
    jsonb_build_array(
      jsonb_build_object('function', 'mesa_cliente_assert_auth', 'exists', to_regprocedure('public.mesa_cliente_assert_auth()') is not null),
      jsonb_build_object('function', 'mesa_cliente_can_access_empresa', 'exists', to_regprocedure('public.mesa_cliente_can_access_empresa(uuid)') is not null),
      jsonb_build_object('function', 'mesa_cliente_assert_empreendimento_empresa', 'exists', to_regprocedure('public.mesa_cliente_assert_empreendimento_empresa(uuid,uuid)') is not null),
      jsonb_build_object('function', 'mesa_cliente_financeiro_calcular_vpl_parcela', 'exists', to_regprocedure('public.mesa_cliente_financeiro_calcular_vpl_parcela(numeric,date,date,numeric,text)') is not null),
      jsonb_build_object('function', 'mesa_cliente_financeiro_calcular_antecipacao_composta', 'exists', to_regprocedure('public.mesa_cliente_financeiro_calcular_antecipacao_composta(numeric,date,date,numeric,text)') is not null),
      jsonb_build_object('function', 'mesa_cliente_financeiro_calcular_postergacao_composta', 'exists', to_regprocedure('public.mesa_cliente_financeiro_calcular_postergacao_composta(numeric,date,date,numeric,text)') is not null)
    ) as deps_json
)
select
  '01_function_exists' as bloco,
  case when exists_ok then 'PASS' else 'FAIL' end as status,
  jsonb_build_object('exists', exists_ok) as detalhe
from function_check

union all

select
  '02_security_definer_volatile' as bloco,
  case when count(*) = 1 and bool_and(security_definer is true) and bool_and(volatility = 'v') then 'PASS' else 'FAIL' end as status,
  jsonb_agg(jsonb_build_object('proname', proname, 'security_definer', security_definer, 'volatility', volatility, 'config', config)) as detalhe
from security_check

union all

select
  '03_execute_grants' as bloco,
  case
    when count(*) filter (where grantee = 'authenticated') >= 1
     and count(*) filter (where grantee = 'PUBLIC') = 0
    then 'PASS' else 'FAIL'
  end as status,
  coalesce(jsonb_agg(jsonb_build_object('grantee', grantee, 'privilege', privilege_type) order by grantee), '[]'::jsonb) as detalhe
from grant_check

union all

select
  '04_dependencies_exist' as bloco,
  case when not exists (
    select 1
    from jsonb_array_elements(deps_json) d
    where coalesce((d->>'exists')::boolean, false) is false
  ) then 'PASS' else 'FAIL' end as status,
  deps_json as detalhe
from deps;
