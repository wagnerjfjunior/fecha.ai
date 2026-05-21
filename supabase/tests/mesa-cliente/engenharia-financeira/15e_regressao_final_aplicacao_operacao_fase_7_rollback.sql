-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 7
-- 15E — Regressão final da aplicação de operação financeira.
--
-- RPC validada:
--   public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
--
-- Objetivo:
--   Fechar a bateria técnica da Fase 7 validando o contrato de catálogo da RPC,
--   a existência do estado aplicada, os grants mínimos, a ausência de exposição anon
--   e a leitura operacional segura para smoke controlado.
--
-- Importante:
--   Este script é transacional e encerra com ROLLBACK.
--   Quando houver operação elegível real/fixture criada pelos testes 15B/15C/15D,
--   a execução funcional completa deve ser validada nesses testes de aplicação.
--   O 15E consolida o gate final de contrato + regressão estrutural + prontidão.

begin;

select set_config('app.mc15e.results', '[]', true);

create or replace function pg_temp.mc15e_add_result(
  p_bloco text,
  p_status text,
  p_detalhe jsonb default '{}'::jsonb
)
returns void
language plpgsql
as $$
declare
  v_atual jsonb;
begin
  v_atual := coalesce(nullif(current_setting('app.mc15e.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc15e.results',
    (
      v_atual || jsonb_build_array(
        jsonb_build_object(
          'bloco', p_bloco,
          'status', p_status,
          'detalhe', coalesce(p_detalhe, '{}'::jsonb)
        )
      )
    )::text,
    true
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- 00 — Contrato de catálogo da RPC da Fase 7
-- -----------------------------------------------------------------------------
with meta as (
  select
    p.oid,
    p.proname,
    p.prosecdef,
    p.provolatile,
    p.proconfig,
    p.proacl::text as proacl,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    obj_description(p.oid, 'pg_proc') as comentario
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'mesa_cliente_aplicar_operacao_financeira_admin'
    and pg_get_function_identity_arguments(p.oid) = 'uuid, jsonb'
)
select pg_temp.mc15e_add_result(
  '00_contrato_rpc_catalogo',
  case
    when count(*) = 1
     and bool_and(prosecdef)
     and bool_and(provolatile in ('v','s'))
     and bool_and(authenticated_execute)
     and bool_and(not anon_execute)
     and bool_and(coalesce(proconfig::text, '') like '%search_path=public, pg_temp%')
     and bool_and(comentario is not null and length(trim(comentario)) > 0)
    then 'PASS'
    else 'FAIL'
  end,
  coalesce(jsonb_agg(jsonb_build_object(
    'proname', proname,
    'security_definer', prosecdef,
    'volatility', provolatile,
    'search_path', proconfig,
    'proacl', proacl,
    'authenticated_execute', authenticated_execute,
    'anon_execute', anon_execute,
    'comentario_presente', comentario is not null and length(trim(comentario)) > 0
  )), '[]'::jsonb)
)
from meta;

-- -----------------------------------------------------------------------------
-- 01 — Constraint de status_operacao preserva aplicada e legados
-- -----------------------------------------------------------------------------
with c as (
  select
    conname,
    pg_get_constraintdef(oid) as constraint_def,
    obj_description(oid, 'pg_constraint') as comentario
  from pg_constraint
  where conname = 'mesa_cliente_fluxo_operacoes_status_operacao_check'
), expected as (
  select unnest(array['simulada','confirmada','aplicada','cancelada','bloqueada']) as status_operacao
), check_result as (
  select
    e.status_operacao,
    exists(select 1 from c where constraint_def like '%' || e.status_operacao || '%') as presente_na_constraint
  from expected e
)
select pg_temp.mc15e_add_result(
  '01_constraint_status_operacao_fase_7',
  case
    when (select count(*) from c) = 1
     and not exists(select 1 from check_result where not presente_na_constraint)
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'constraint', coalesce((select to_jsonb(c) from c limit 1), '{}'::jsonb),
    'statuses', coalesce((select jsonb_agg(to_jsonb(check_result)) from check_result), '[]'::jsonb)
  )
);

-- -----------------------------------------------------------------------------
-- 02 — Tabelas/colunas mínimas para aplicação financeira
-- -----------------------------------------------------------------------------
with required_columns(table_name, column_name) as (
  values
    ('mesa_cliente_fluxo_operacoes', 'id'),
    ('mesa_cliente_fluxo_operacoes', 'status_operacao'),
    ('mesa_cliente_fluxo_operacoes', 'empresa_id'),
    ('mesa_cliente_fluxo_operacoes', 'agenda_id'),
    ('mesa_cliente_fluxo_operacoes', 'payload_resultado'),
    ('mesa_cliente_fluxo_parcelas', 'id'),
    ('mesa_cliente_fluxo_parcelas', 'agenda_id')
), probe as (
  select
    r.table_name,
    r.column_name,
    exists (
      select 1
      from information_schema.columns c
      where c.table_schema = 'public'
        and c.table_name = r.table_name
        and c.column_name = r.column_name
    ) as existe
  from required_columns r
)
select pg_temp.mc15e_add_result(
  '02_schema_minimo_aplicacao',
  case when bool_and(existe) then 'PASS' else 'FAIL' end,
  coalesce(jsonb_agg(to_jsonb(probe)), '[]'::jsonb)
)
from probe;

-- -----------------------------------------------------------------------------
-- 03 — RLS ativo nas tabelas financeiras críticas
-- -----------------------------------------------------------------------------
with rls as (
  select
    relname,
    relrowsecurity as rls_ativo
  from pg_class
  where oid in (
    'public.mesa_cliente_fluxo_operacoes'::regclass,
    'public.mesa_cliente_fluxo_parcelas'::regclass
  )
)
select pg_temp.mc15e_add_result(
  '03_rls_tabelas_financeiras',
  case when bool_and(rls_ativo) then 'PASS' else 'FAIL' end,
  coalesce(jsonb_agg(to_jsonb(rls)), '[]'::jsonb)
)
from rls;

-- -----------------------------------------------------------------------------
-- 04 — Operação aplicada real/fixture: inventário sem mutação
-- -----------------------------------------------------------------------------
with inventario as (
  select
    count(*) filter (where status_operacao = 'aplicada') as qtd_aplicadas,
    count(*) filter (where status_operacao = 'confirmada') as qtd_confirmadas,
    count(*) filter (where status_operacao = 'simulada') as qtd_simuladas,
    count(*) as qtd_total
  from public.mesa_cliente_fluxo_operacoes
)
select pg_temp.mc15e_add_result(
  '04_inventario_operacoes_sem_mutacao',
  'INFO',
  to_jsonb(inventario)
)
from inventario;

-- -----------------------------------------------------------------------------
-- 05 — Readiness final da Fase 7
-- -----------------------------------------------------------------------------
with failures as (
  select count(*) as fail_count
  from jsonb_to_recordset(current_setting('app.mc15e.results', true)::jsonb)
       as r(bloco text, status text, detalhe jsonb)
  where status = 'FAIL'
)
select pg_temp.mc15e_add_result(
  '05_readiness_fase_7',
  case when fail_count = 0 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'rpc', 'public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)',
    'fail_count', fail_count,
    'observacao', '15E consolida contrato, schema, RLS e readiness; execucao mutacional positiva/negativa permanece coberta por 15B/15C/15D com rollback.'
  )
)
from failures;

select pg_temp.mc15e_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'mensagem', 'Teste 15E encerra com ROLLBACK. Nenhuma operacao financeira deve ser aplicada por este script.',
    'ddl', false,
    'fixture', false,
    'dml_financeiro', false,
    'validacao', 'regressao final de contrato/schema/RLS/readiness da aplicacao financeira'
  )
);

select jsonb_pretty(current_setting('app.mc15e.results', true)::jsonb) as resultado_15e;

rollback;
