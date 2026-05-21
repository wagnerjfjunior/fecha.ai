-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 7
-- 15 — Preflight estrutural para aplicação controlada de operação financeira.
--
-- Objetivo:
--   Validar, antes de qualquer migration de DML financeiro, se o banco possui
--   as tabelas, colunas, funções, RLS e policies necessárias para iniciar a Fase 7.
--
-- Regras deste preflight:
--   - read-only;
--   - sem DDL;
--   - sem DML;
--   - sem fixture;
--   - sem alteração de agenda, parcelas ou operações;
--   - SKIP/INFO não aprova nem reprova por si só; PASS/FAIL indicam readiness.
--
-- Próxima RPC esperada pela Fase 7:
--   public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)

start transaction read only;

with
tabelas_obrigatorias(nome) as (
  values
    ('mesa_cliente_fluxo_operacoes'),
    ('mesa_cliente_fluxo_parcelas'),
    ('mesa_cliente_agendas_financeiras'),
    ('mesa_simulacoes'),
    ('corretores')
),
tabelas_existentes as (
  select t.nome, to_regclass('public.' || t.nome) is not null as existe
  from tabelas_obrigatorias t
),
colunas_obrigatorias(table_name, column_name) as (
  values
    -- operacoes
    ('mesa_cliente_fluxo_operacoes','id'),
    ('mesa_cliente_fluxo_operacoes','empresa_id'),
    ('mesa_cliente_fluxo_operacoes','simulacao_id'),
    ('mesa_cliente_fluxo_operacoes','empreendimento_id'),
    ('mesa_cliente_fluxo_operacoes','tipo_operacao'),
    ('mesa_cliente_fluxo_operacoes','grupo_origem'),
    ('mesa_cliente_fluxo_operacoes','grupo_destino'),
    ('mesa_cliente_fluxo_operacoes','parcela_origem_id'),
    ('mesa_cliente_fluxo_operacoes','parcela_destino_id'),
    ('mesa_cliente_fluxo_operacoes','valor_base'),
    ('mesa_cliente_fluxo_operacoes','valor_movido'),
    ('mesa_cliente_fluxo_operacoes','data_origem'),
    ('mesa_cliente_fluxo_operacoes','data_destino'),
    ('mesa_cliente_fluxo_operacoes','taxa_ano_pct'),
    ('mesa_cliente_fluxo_operacoes','vpl_aplicado_pct'),
    ('mesa_cliente_fluxo_operacoes','desconto_calculado'),
    ('mesa_cliente_fluxo_operacoes','acrescimo_calculado'),
    ('mesa_cliente_fluxo_operacoes','economia_liquida'),
    ('mesa_cliente_fluxo_operacoes','premio_corretor_pct'),
    ('mesa_cliente_fluxo_operacoes','status_premio'),
    ('mesa_cliente_fluxo_operacoes','visivel_cliente'),
    ('mesa_cliente_fluxo_operacoes','confirmado'),
    ('mesa_cliente_fluxo_operacoes','confirmado_por'),
    ('mesa_cliente_fluxo_operacoes','confirmado_em'),
    ('mesa_cliente_fluxo_operacoes','status_operacao'),
    ('mesa_cliente_fluxo_operacoes','agenda_id'),
    ('mesa_cliente_fluxo_operacoes','checksum_operacao'),
    ('mesa_cliente_fluxo_operacoes','cancelado_por'),
    ('mesa_cliente_fluxo_operacoes','cancelado_em'),
    ('mesa_cliente_fluxo_operacoes','motivo_cancelamento'),
    ('mesa_cliente_fluxo_operacoes','metadata'),
    ('mesa_cliente_fluxo_operacoes','updated_at'),

    -- parcelas
    ('mesa_cliente_fluxo_parcelas','id'),
    ('mesa_cliente_fluxo_parcelas','empresa_id'),
    ('mesa_cliente_fluxo_parcelas','simulacao_id'),
    ('mesa_cliente_fluxo_parcelas','empreendimento_id'),
    ('mesa_cliente_fluxo_parcelas','agenda_id'),
    ('mesa_cliente_fluxo_parcelas','grupo'),
    ('mesa_cliente_fluxo_parcelas','descricao'),
    ('mesa_cliente_fluxo_parcelas','valor_original'),
    ('mesa_cliente_fluxo_parcelas','valor_atual'),
    ('mesa_cliente_fluxo_parcelas','data_original'),
    ('mesa_cliente_fluxo_parcelas','data_atual'),
    ('mesa_cliente_fluxo_parcelas','origem_data'),
    ('mesa_cliente_fluxo_parcelas','regra_data'),
    ('mesa_cliente_fluxo_parcelas','ordem'),
    ('mesa_cliente_fluxo_parcelas','eh_periodicidade_simbolica'),
    ('mesa_cliente_fluxo_parcelas','pode_receber_vpl'),
    ('mesa_cliente_fluxo_parcelas','pode_receber_antecipacao'),
    ('mesa_cliente_fluxo_parcelas','pode_receber_postergacao'),
    ('mesa_cliente_fluxo_parcelas','metadata'),
    ('mesa_cliente_fluxo_parcelas','atualizado_por'),
    ('mesa_cliente_fluxo_parcelas','updated_at'),

    -- agenda
    ('mesa_cliente_agendas_financeiras','id'),
    ('mesa_cliente_agendas_financeiras','empresa_id'),
    ('mesa_cliente_agendas_financeiras','simulacao_id'),
    ('mesa_cliente_agendas_financeiras','empreendimento_id'),
    ('mesa_cliente_agendas_financeiras','versao'),
    ('mesa_cliente_agendas_financeiras','status'),
    ('mesa_cliente_agendas_financeiras','checksum'),
    ('mesa_cliente_agendas_financeiras','totais'),
    ('mesa_cliente_agendas_financeiras','metadata'),
    ('mesa_cliente_agendas_financeiras','updated_at'),

    -- simulacoes/corretores
    ('mesa_simulacoes','id'),
    ('mesa_simulacoes','empresa_id'),
    ('mesa_simulacoes','corretor_id'),
    ('mesa_simulacoes','empreendimento_id'),
    ('mesa_simulacoes','status'),
    ('mesa_simulacoes','oficial'),
    ('corretores','id'),
    ('corretores','user_id'),
    ('corretores','empresa_id'),
    ('corretores','ativo'),
    ('corretores','role'),
    ('corretores','is_admin_local'),
    ('corretores','is_gestor')
),
colunas_status as (
  select
    co.table_name,
    co.column_name,
    c.data_type,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.column_name is not null as existe
  from colunas_obrigatorias co
  left join information_schema.columns c
    on c.table_schema = 'public'
   and c.table_name = co.table_name
   and c.column_name = co.column_name
),
funcoes_dependencia(nome) as (
  values
    ('mesa_cliente_persistir_agenda_financeira_admin'),
    ('mesa_cliente_registrar_operacao_financeira_admin'),
    ('mesa_cliente_resumir_operacao_financeira_admin'),
    ('mesa_cliente_obter_resumo_operacao_cliente_safe')
),
funcoes_existentes as (
  select
    f.nome,
    p.proname,
    p.prosecdef,
    p.provolatile,
    p.proconfig,
    p.proacl::text as proacl,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    obj_description(p.oid, 'pg_proc') as comentario
  from funcoes_dependencia f
  left join pg_proc p on p.proname = f.nome
  left join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
  where p.oid is null or n.nspname = 'public'
),
rls as (
  select schemaname, tablename, rowsecurity
  from pg_tables
  where schemaname = 'public'
    and tablename in (select nome from tabelas_obrigatorias)
),
policies as (
  select schemaname, tablename, policyname, roles, cmd, permissive, qual, with_check
  from pg_policies
  where schemaname = 'public'
    and tablename in (select nome from tabelas_obrigatorias)
),
policy_bloqueios as (
  select
    bool_or(tablename = 'mesa_cliente_fluxo_operacoes' and policyname = 'mcfo_no_direct_insert' and cmd = 'INSERT' and with_check = 'false') as mcfo_insert_block,
    bool_or(tablename = 'mesa_cliente_fluxo_operacoes' and policyname = 'mcfo_no_direct_update' and cmd = 'UPDATE' and qual = 'false' and with_check = 'false') as mcfo_update_block,
    bool_or(tablename = 'mesa_cliente_fluxo_operacoes' and policyname = 'mcfo_no_direct_delete' and cmd = 'DELETE' and qual = 'false') as mcfo_delete_block,
    bool_or(tablename = 'mesa_cliente_fluxo_parcelas' and policyname = 'mcfp_no_direct_insert' and cmd = 'INSERT' and with_check = 'false') as mcfp_insert_block,
    bool_or(tablename = 'mesa_cliente_fluxo_parcelas' and policyname = 'mcfp_no_direct_update' and cmd = 'UPDATE' and qual = 'false' and with_check = 'false') as mcfp_update_block,
    bool_or(tablename = 'mesa_cliente_fluxo_parcelas' and policyname = 'mcfp_no_direct_delete' and cmd = 'DELETE' and qual = 'false') as mcfp_delete_block
  from policies
),
status_operacao_distintos as (
  select status_operacao, count(*) as qtd
  from public.mesa_cliente_fluxo_operacoes
  group by status_operacao
),
tipos_operacao_distintos as (
  select tipo_operacao::text as tipo_operacao, count(*) as qtd
  from public.mesa_cliente_fluxo_operacoes
  group by tipo_operacao::text
),
operacao_candidata as (
  select
    o.id as operacao_id,
    o.status_operacao,
    o.confirmado,
    o.visivel_cliente,
    o.agenda_id,
    o.simulacao_id,
    o.empresa_id,
    o.tipo_operacao::text as tipo_operacao,
    o.parcela_origem_id,
    o.parcela_destino_id,
    o.valor_movido,
    o.created_at
  from public.mesa_cliente_fluxo_operacoes o
  where o.agenda_id is not null
    and coalesce(o.cancelado_em is null, true)
  order by o.created_at desc nulls last, o.id desc
  limit 1
),
resultado as (
  select
    1 as ord,
    '01_tabelas_obrigatorias' as bloco,
    case when bool_and(existe) then 'PASS' else 'FAIL' end as status,
    jsonb_agg(jsonb_build_object('tabela', nome, 'existe', existe) order by nome) as detalhe
  from tabelas_existentes

  union all

  select
    2,
    '02_colunas_obrigatorias_fase_7',
    case when bool_and(existe) then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'faltantes', coalesce(jsonb_agg(jsonb_build_object('table_name', table_name, 'column_name', column_name) order by table_name, column_name) filter (where not existe), '[]'::jsonb),
      'qtd_total', count(*),
      'qtd_ok', count(*) filter (where existe)
    )
  from colunas_status

  union all

  select
    3,
    '03_funcoes_dependencia',
    case when count(*) filter (where proname is not null) = 4 then 'PASS' else 'FAIL' end,
    jsonb_agg(jsonb_build_object(
      'nome', nome,
      'existe', proname is not null,
      'security_definer', prosecdef,
      'volatility', provolatile,
      'search_path', proconfig,
      'authenticated_execute', authenticated_execute,
      'anon_execute', anon_execute,
      'proacl', proacl,
      'comentario_presente', coalesce(comentario, '') <> ''
    ) order by nome)
  from funcoes_existentes

  union all

  select
    4,
    '04_rls_ativo_tabelas_alvo',
    case when count(*) = 5 and bool_and(rowsecurity) then 'PASS' else 'FAIL' end,
    jsonb_agg(to_jsonb(rls) order by tablename)
  from rls

  union all

  select
    5,
    '05_bloqueios_dml_direto_financeiro',
    case
      when mcfo_insert_block and mcfo_update_block and mcfo_delete_block
       and mcfp_insert_block and mcfp_update_block and mcfp_delete_block
      then 'PASS' else 'FAIL'
    end,
    to_jsonb(policy_bloqueios)
  from policy_bloqueios

  union all

  select
    6,
    '06_status_operacao_existentes',
    'INFO',
    coalesce(jsonb_agg(jsonb_build_object('status_operacao', status_operacao, 'qtd', qtd) order by status_operacao), '[]'::jsonb)
  from status_operacao_distintos

  union all

  select
    7,
    '07_tipos_operacao_existentes',
    'INFO',
    coalesce(jsonb_agg(jsonb_build_object('tipo_operacao', tipo_operacao, 'qtd', qtd) order by tipo_operacao), '[]'::jsonb)
  from tipos_operacao_distintos

  union all

  select
    8,
    '08_probe_operacao_candidata_fase_7',
    case when exists(select 1 from operacao_candidata) then 'INFO' else 'SKIP' end,
    case
      when exists(select 1 from operacao_candidata)
      then (select to_jsonb(operacao_candidata) from operacao_candidata)
      else jsonb_build_object('mensagem', 'Sem operacao candidata real com agenda_id para probe. Isto nao bloqueia preflight; testes positivos devem usar fixture transacional.')
    end

  union all

  select
    9,
    '09_readiness_fase_7',
    case
      when (select bool_and(existe) from tabelas_existentes)
       and (select bool_and(existe) from colunas_status)
       and (select count(*) filter (where proname is not null) from funcoes_existentes) = 4
       and (select count(*) = 5 and bool_and(rowsecurity) from rls)
       and (select mcfo_insert_block and mcfo_update_block and mcfo_delete_block and mcfp_insert_block and mcfp_update_block and mcfp_delete_block from policy_bloqueios)
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
      'readiness_tecnico',
        (select bool_and(existe) from tabelas_existentes)
        and (select bool_and(existe) from colunas_status)
        and (select count(*) filter (where proname is not null) from funcoes_existentes) = 4
        and (select count(*) = 5 and bool_and(rowsecurity) from rls)
        and (select mcfo_insert_block and mcfo_update_block and mcfo_delete_block and mcfp_insert_block and mcfp_update_block and mcfp_delete_block from policy_bloqueios),
      'proxima_rpc_esperada', 'public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)',
      'observacao', 'Preflight read-only. Nenhuma aplicacao financeira foi executada.'
    )

  union all

  select
    99,
    '99_interpretacao_operacional',
    'INFO',
    jsonb_build_object(
      'tipo', 'preflight_fase_7_readonly',
      'ddl', false,
      'dml', false,
      'fixture', false,
      'rollback', true,
      'mensagem', 'Se 09_readiness_fase_7=PASS, a migration da RPC de aplicacao pode ser desenhada. Se FAIL, corrigir contrato/schema antes de qualquer DML financeiro.'
    )
)
select bloco, status, detalhe
from resultado
order by ord;

rollback;
