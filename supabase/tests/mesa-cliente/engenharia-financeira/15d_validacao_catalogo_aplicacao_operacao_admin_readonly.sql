-- FECH.AI — MesaCliente
-- Fase 7 — Aplicacao de operacao financeira
-- Teste 15D — Validacao de catalogo/contrato da RPC de aplicacao admin
--
-- Objetivo:
--   Validar, de forma read-only, o contrato tecnico da RPC:
--     public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
--
-- Escopo validado:
--   - existencia da RPC no catalogo
--   - assinatura esperada
--   - retorno jsonb
--   - SECURITY DEFINER
--   - search_path fixado em public, pg_temp
--   - volatility esperada para RPC com DML controlado
--   - grants para authenticated/service_role
--   - ausencia de execute para anon/public
--   - comentario de catalogo
--   - constraint status_operacao contendo aplicada
--   - dependencias das fases anteriores
--
-- Garantias do teste:
--   - Sem fixture
--   - Sem DML
--   - Sem DDL
--   - Sem aplicacao financeira real
--   - Transaction read only + rollback

start transaction read only;

with rpc_catalogo as (
  select
    p.oid,
    n.nspname as schema_name,
    p.proname,
    pg_get_function_identity_arguments(p.oid) as identity_args,
    pg_get_function_arguments(p.oid) as full_args,
    pg_get_function_result(p.oid) as result_type,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    p.proconfig,
    p.proacl::text as proacl,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('public', p.oid, 'EXECUTE') as public_execute,
    obj_description(p.oid, 'pg_proc') as comentario
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'mesa_cliente_aplicar_operacao_financeira_admin'
),
dependencias as (
  select
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'mesa_cliente_persistir_agenda_financeira_admin'
    ) as rpc_4b_existe,
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'mesa_cliente_registrar_operacao_financeira_admin'
    ) as rpc_5b_existe,
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'mesa_cliente_atualizar_status_operacao_financeira_admin'
    ) as rpc_5c_existe,
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'mesa_cliente_resumir_operacao_financeira_admin'
    ) as rpc_6_admin_existe,
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'mesa_cliente_obter_resumo_operacao_cliente_safe'
    ) as rpc_6_cliente_safe_existe
),
constraint_status as (
  select
    c.conname,
    pg_get_constraintdef(c.oid) as constraint_def,
    obj_description(c.oid, 'pg_constraint') as comentario
  from pg_constraint c
  where c.connamespace = 'public'::regnamespace
    and c.conrelid = 'public.mesa_cliente_fluxo_operacoes'::regclass
    and c.conname = 'mesa_cliente_fluxo_operacoes_status_operacao_check'
),
resultado as (
  select
    0 as ord,
    '00_rpc_fase_7_catalogo_existe' as bloco,
    case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
    coalesce(jsonb_agg(jsonb_build_object(
      'schema', schema_name,
      'proname', proname,
      'identity_args', identity_args,
      'full_args', full_args,
      'result_type', result_type
    )), '[]'::jsonb) as detalhe
  from rpc_catalogo

  union all

  select
    1,
    '01_assinatura_rpc_fase_7',
    case
      when count(*) = 1
       and bool_and(identity_args = 'p_operacao_id uuid, p_parametros jsonb')
       and bool_and(full_args ilike '%p_parametros jsonb DEFAULT%')
       and bool_and(result_type = 'jsonb')
      then 'PASS' else 'FAIL'
    end,
    coalesce(jsonb_agg(jsonb_build_object(
      'identity_args', identity_args,
      'full_args', full_args,
      'result_type', result_type,
      'assinatura_esperada', 'public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb) returns jsonb'
    )), '[]'::jsonb)
  from rpc_catalogo

  union all

  select
    2,
    '02_security_definer_search_path_volatility',
    case
      when count(*) = 1
       and bool_and(security_definer)
       and bool_and(volatility = 'v')
       and bool_and(coalesce(proconfig, array[]::text[]) @> array['search_path=public, pg_temp'])
      then 'PASS' else 'FAIL'
    end,
    coalesce(jsonb_agg(jsonb_build_object(
      'security_definer', security_definer,
      'volatility', volatility,
      'volatility_esperada', 'v',
      'search_path', proconfig,
      'search_path_esperado', 'public, pg_temp'
    )), '[]'::jsonb)
  from rpc_catalogo

  union all

  select
    3,
    '03_grants_execucao',
    case
      when count(*) = 1
       and bool_and(authenticated_execute)
       and bool_and(service_role_execute)
       and bool_and(not anon_execute)
       and bool_and(not public_execute)
      then 'PASS' else 'FAIL'
    end,
    coalesce(jsonb_agg(jsonb_build_object(
      'proacl', proacl,
      'authenticated_execute', authenticated_execute,
      'service_role_execute', service_role_execute,
      'anon_execute', anon_execute,
      'public_execute', public_execute
    )), '[]'::jsonb)
  from rpc_catalogo

  union all

  select
    4,
    '04_comentario_catalogo',
    case
      when count(*) = 1
       and bool_and(coalesce(comentario, '') ilike '%Fase 7%')
       and bool_and(coalesce(comentario, '') ilike '%DML controlado%')
       and bool_and(coalesce(comentario, '') ilike '%tenant-safe%')
      then 'PASS' else 'FAIL'
    end,
    coalesce(jsonb_agg(jsonb_build_object(
      'comentario_presente', coalesce(comentario, '') <> '',
      'comentario', comentario
    )), '[]'::jsonb)
  from rpc_catalogo

  union all

  select
    5,
    '05_constraint_status_aplicada',
    case
      when exists (
        select 1
        from constraint_status
        where constraint_def ilike '%''aplicada''%'
      )
      then 'PASS' else 'FAIL'
    end,
    coalesce(
      (select to_jsonb(cs) from constraint_status cs limit 1),
      jsonb_build_object('mensagem', 'constraint nao encontrada')
    )

  union all

  select
    6,
    '06_dependencias_fases_anteriores',
    case
      when rpc_4b_existe
       and rpc_5b_existe
       and rpc_5c_existe
       and rpc_6_admin_existe
       and rpc_6_cliente_safe_existe
      then 'PASS' else 'FAIL'
    end,
    to_jsonb(dependencias)
  from dependencias

  union all

  select
    7,
    '07_readiness_15e_regressao_final',
    case
      when exists (select 1 from rpc_catalogo)
       and exists (select 1 from constraint_status where constraint_def ilike '%''aplicada''%')
       and exists (
         select 1
         from dependencias
         where rpc_4b_existe
           and rpc_5b_existe
           and rpc_5c_existe
           and rpc_6_admin_existe
           and rpc_6_cliente_safe_existe
       )
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
      'proximo_teste', '15E_regressao_final_aplicacao_operacao_financeira_admin_rollback',
      'rpc_validada', 'public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)',
      'sem_fixture', true,
      'read_only', true
    )

  union all

  select
    99,
    '99_interpretacao_operacional',
    'INFO',
    jsonb_build_object(
      'ddl', false,
      'dml', false,
      'fixture', false,
      'rollback', true,
      'tipo', 'validacao_catalogo_rpc_fase_7_readonly',
      'mensagem', '15D valida catalogo/contrato/grants/security/search_path/comentario/dependencias. Nenhuma operacao financeira foi aplicada.'
    )
)
select bloco, status, detalhe
from resultado
order by ord;

rollback;
