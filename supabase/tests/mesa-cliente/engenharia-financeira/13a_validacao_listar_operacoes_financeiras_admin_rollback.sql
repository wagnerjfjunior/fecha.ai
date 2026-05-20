-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- 13A — Validação positiva da RPC de listagem administrativa de operações financeiras.
--
-- Pré-requisitos:
--   - Fase 5B aplicada;
--   - Fase 5C aplicada;
--   - Migration 5D aplicada:
--     supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, registrar operações via 5B,
--   confirmar/cancelar algumas operações via 5C e validar a RPC 5D de listagem:
--     - retorno canônico administrativo;
--     - cliente_safe=false;
--     - readonly=true;
--     - sem DML financeiro;
--     - sem recalcular operação;
--     - sem alterar agenda;
--     - sem alterar parcelas;
--     - listagem geral por simulação;
--     - listagem por agenda;
--     - filtros por status_operacao;
--     - paginação básica;
--     - campos mínimos administrativos;
--     - rollback final.
--
-- Segurança:
--   O teste cria fixture dentro de transação e encerra com ROLLBACK.
--   A única mutação intencional é a preparação da fixture 4B/5B/5C.
--   A etapa 5D validada é somente leitura.

begin;

select set_config('app.mc13a.user_id', '', true);
select set_config('app.mc13a.simulacao_id', '', true);
select set_config('app.mc13a.empresa_id', '', true);
select set_config('app.mc13a.empreendimento_id', '', true);
select set_config('app.mc13a.politica_id', '', true);
select set_config('app.mc13a.agenda_id', '', true);
select set_config('app.mc13a.parcela_1_id', '', true);
select set_config('app.mc13a.parcela_2_id', '', true);
select set_config('app.mc13a.parcela_3_id', '', true);
select set_config('app.mc13a.payload_4b', 'null', true);
select set_config('app.mc13a.payload_5b_op1', 'null', true);
select set_config('app.mc13a.payload_5b_op2', 'null', true);
select set_config('app.mc13a.payload_5b_op3', 'null', true);
select set_config('app.mc13a.payload_5c_confirmar_op1', 'null', true);
select set_config('app.mc13a.payload_5c_cancelar_op2', 'null', true);
select set_config('app.mc13a.snapshot_before_5d', 'null', true);
select set_config('app.mc13a.snapshot_after_5d', 'null', true);
select set_config('app.mc13a.payload_5d_list_all', 'null', true);
select set_config('app.mc13a.payload_5d_list_agenda', 'null', true);
select set_config('app.mc13a.payload_5d_filter_confirmada', 'null', true);
select set_config('app.mc13a.payload_5d_filter_cancelada', 'null', true);
select set_config('app.mc13a.payload_5d_filter_simulada', 'null', true);
select set_config('app.mc13a.payload_5d_limit_2', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    e.id as empreendimento_id,
    e.nome as empreendimento_nome
  from public.corretores c
  join public.empreendimentos e on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_global' then 1
      when c.role = 'admin_local' then 2
      when c.role = 'gestor' then 3
      when c.role = 'coordenador' then 4
      else 5
    end,
    c.created_at desc nulls last,
    c.id
  limit 1
),
simulacao as materialized (
  insert into public.mesa_simulacoes (
    empresa_id,
    corretor_id,
    empreendimento_id,
    cliente_nome,
    valor_total,
    entrada,
    financiamento,
    valor_final,
    snapshot_payload,
    observacoes
  )
  select
    empresa_id,
    corretor_id,
    empreendimento_id,
    'Teste rollback 13A listagem operações financeiras 5D',
    48000.00,
    12000.00,
    0,
    48000.00,
    jsonb_build_object('origem', 'teste_13a_5d_rollback', 'fixture_transacional', true),
    'Fixture transacional 13A. Deve sumir no ROLLBACK.'
  from candidato
  returning id, empresa_id, corretor_id, empreendimento_id
),
politica as materialized (
  insert into public.mesa_cliente_politicas_financeiras (
    empresa_id,
    empreendimento_id,
    mes_referencia,
    vigencia_inicio,
    vigencia_fim,
    vpl_max_pct,
    taxa_antecipacao_ano_pct,
    taxa_postergacao_ano_pct,
    metodo_calculo,
    base_tempo,
    permite_vpl_financiamento,
    permite_vpl_chaves,
    permite_vpl_anuais,
    permite_vpl_mensais,
    permite_antecipacao_financiamento,
    permite_antecipacao_chaves,
    permite_antecipacao_anuais,
    permite_antecipacao_mensais,
    permite_postergacao_financiamento,
    permite_postergacao_chaves,
    permite_postergacao_anuais,
    permite_postergacao_mensais,
    ativo,
    observacoes
  )
  select
    empresa_id,
    empreendimento_id,
    date '2099-06-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 13A para validação positiva da listagem administrativa pela RPC 5D.'
  from simulacao
  on conflict (empresa_id, empreendimento_id, mes_referencia)
  do update set
    vigencia_inicio = excluded.vigencia_inicio,
    vigencia_fim = excluded.vigencia_fim,
    vpl_max_pct = excluded.vpl_max_pct,
    taxa_antecipacao_ano_pct = excluded.taxa_antecipacao_ano_pct,
    taxa_postergacao_ano_pct = excluded.taxa_postergacao_ano_pct,
    metodo_calculo = excluded.metodo_calculo,
    base_tempo = excluded.base_tempo,
    permite_vpl_financiamento = excluded.permite_vpl_financiamento,
    permite_vpl_chaves = excluded.permite_vpl_chaves,
    permite_vpl_anuais = excluded.permite_vpl_anuais,
    permite_vpl_mensais = excluded.permite_vpl_mensais,
    permite_antecipacao_financiamento = excluded.permite_antecipacao_financiamento,
    permite_antecipacao_chaves = excluded.permite_antecipacao_chaves,
    permite_antecipacao_anuais = excluded.permite_antecipacao_anuais,
    permite_antecipacao_mensais = excluded.permite_antecipacao_mensais,
    permite_postergacao_financiamento = excluded.permite_postergacao_financiamento,
    permite_postergacao_chaves = excluded.permite_postergacao_chaves,
    permite_postergacao_anuais = excluded.permite_postergacao_anuais,
    permite_postergacao_mensais = excluded.permite_postergacao_mensais,
    ativo = excluded.ativo,
    observacoes = excluded.observacoes,
    updated_at = now()
  returning id, empresa_id, empreendimento_id
),
faixas as materialized (
  insert into public.mesa_cliente_politica_premio_faixas (
    empresa_id,
    politica_id,
    vpl_de_pct,
    vpl_ate_pct,
    premio_corretor_pct,
    status,
    descricao,
    ordem,
    ativo
  )
  select p.empresa_id, p.id, v.vpl_de_pct, v.vpl_ate_pct, v.premio_corretor_pct, v.status, v.descricao, v.ordem, true
  from politica p
  cross join (
    values
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 13A — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 13A — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 13A — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc13a.user_id', c.user_id::text, true),
    set_config('app.mc13a.simulacao_id', s.id::text, true),
    set_config('app.mc13a.empresa_id', s.empresa_id::text, true),
    set_config('app.mc13a.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc13a.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_13a' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc13a.simulacao_id', true),
    'politica_id', current_setting('app.mc13a.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc13a.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13a.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc13a.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-06-30',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','12000.00','data','2099-06-30'),
      jsonb_build_object('grupo','mensais','descricao','Mensais 13A','valor','2500.00','quantidade',4,'mes_ano','07/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária 13A','valor','9000.00','quantidade',2,'mes_ano','12/2099'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','08/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_13a')
  ) as payload
  from ctx
)
select set_config('app.mc13a.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc13a.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcelas_ranked as (
  select
    fp.id,
    row_number() over (order by fp.valor_atual desc, fp.data_atual desc, fp.id) as rn
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual >= 1000.00
    and fp.data_atual > date '2099-06-30'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
),
setups as (
  select
    set_config('app.mc13a.agenda_id', (select id::text from agenda), true),
    set_config('app.mc13a.parcela_1_id', (select id::text from parcelas_ranked where rn = 1), true),
    set_config('app.mc13a.parcela_2_id', (select id::text from parcelas_ranked where rn = 2), true),
    set_config('app.mc13a.parcela_3_id', (select id::text from parcelas_ranked where rn = 3), true)
)
select
  '00b_agenda_parcelas_fixture_13a' as bloco,
  case
    when current_setting('app.mc13a.agenda_id', true) <> ''
     and current_setting('app.mc13a.parcela_1_id', true) <> ''
     and current_setting('app.mc13a.parcela_2_id', true) <> ''
     and current_setting('app.mc13a.parcela_3_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc13a.agenda_id', true),
    'parcela_1_id', current_setting('app.mc13a.parcela_1_id', true),
    'parcela_2_id', current_setting('app.mc13a.parcela_2_id', true),
    'parcela_3_id', current_setting('app.mc13a.parcela_3_id', true),
    'qtd_parcelas_elegiveis', (select count(*) from parcelas_ranked)
  ) as detalhe
from setups;

set local role authenticated;

with chamada_5b_op1 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13a.parcela_1_id', true)::uuid,
    date '2099-06-30',
    null,
    1000.00,
    jsonb_build_object('origem_teste', '13a', 'op', 'op1_confirmada', 'observacao', 'operacao para listagem 5D')
  ) as payload
)
select set_config('app.mc13a.payload_5b_op1', coalesce((select payload::text from chamada_5b_op1), 'null'), true);

with chamada_5b_op2 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13a.parcela_2_id', true)::uuid,
    date '2099-06-30',
    null,
    1200.00,
    jsonb_build_object('origem_teste', '13a', 'op', 'op2_cancelada', 'observacao', 'operacao para listagem 5D')
  ) as payload
)
select set_config('app.mc13a.payload_5b_op2', coalesce((select payload::text from chamada_5b_op2), 'null'), true);

with chamada_5b_op3 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13a.parcela_3_id', true)::uuid,
    date '2099-06-30',
    null,
    900.00,
    jsonb_build_object('origem_teste', '13a', 'op', 'op3_simulada', 'observacao', 'operacao para listagem 5D')
  ) as payload
)
select set_config('app.mc13a.payload_5b_op3', coalesce((select payload::text from chamada_5b_op3), 'null'), true);

with chamada_5c_confirmar_op1 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc13a.payload_5b_op1', true)::jsonb->'operacao'->>'id')::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '13a', 'observacao', 'confirmacao para validar filtro 5D')
  ) as payload
)
select set_config('app.mc13a.payload_5c_confirmar_op1', coalesce((select payload::text from chamada_5c_confirmar_op1), 'null'), true);

with chamada_5c_cancelar_op2 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc13a.payload_5b_op2', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Cancelamento fixture 13A para validar filtro 5D',
    jsonb_build_object('origem_teste', '13a', 'observacao', 'cancelamento para validar filtro 5D')
  ) as payload
)
select set_config('app.mc13a.payload_5c_cancelar_op2', coalesce((select payload::text from chamada_5c_cancelar_op2), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc13a.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13a.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.* from public.mesa_cliente_agendas_financeiras a join ctx on ctx.agenda_id = a.id limit 1
),
snapshot_before_5d as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_confirmada', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'qtd_cancelada', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'qtd_simulada', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'simulada'),
    'qtd_visivel_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true)
  ) as payload
  from ctx
)
select set_config('app.mc13a.snapshot_before_5d', coalesce((select payload::text from snapshot_before_5d), 'null'), true);

set local role authenticated;

with chamada_5d_list_all as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    null,
    jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13a.payload_5d_list_all', coalesce((select payload::text from chamada_5d_list_all), 'null'), true);

with chamada_5d_list_agenda as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13a.payload_5d_list_agenda', coalesce((select payload::text from chamada_5d_list_agenda), 'null'), true);

with chamada_5d_filter_confirmada as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    jsonb_build_object('status_operacao', 'confirmada', 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13a.payload_5d_filter_confirmada', coalesce((select payload::text from chamada_5d_filter_confirmada), 'null'), true);

with chamada_5d_filter_cancelada as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    jsonb_build_object('status_operacao', 'cancelada', 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13a.payload_5d_filter_cancelada', coalesce((select payload::text from chamada_5d_filter_cancelada), 'null'), true);

with chamada_5d_filter_simulada as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    jsonb_build_object('status_operacao', 'simulada', 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13a.payload_5d_filter_simulada', coalesce((select payload::text from chamada_5d_filter_simulada), 'null'), true);

with chamada_5d_limit_2 as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13a.simulacao_id', true)::uuid,
    current_setting('app.mc13a.agenda_id', true)::uuid,
    jsonb_build_object('limit', 2, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13a.payload_5d_limit_2', coalesce((select payload::text from chamada_5d_limit_2), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc13a.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13a.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.* from public.mesa_cliente_agendas_financeiras a join ctx on ctx.agenda_id = a.id limit 1
),
snapshot_after_5d as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_confirmada', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'qtd_cancelada', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'qtd_simulada', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'simulada'),
    'qtd_visivel_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true)
  ) as payload
  from ctx
)
select set_config('app.mc13a.snapshot_after_5d', coalesce((select payload::text from snapshot_after_5d), 'null'), true);

with dados as (
  select
    current_setting('app.mc13a.payload_5b_op1', true)::jsonb as p5b1,
    current_setting('app.mc13a.payload_5b_op2', true)::jsonb as p5b2,
    current_setting('app.mc13a.payload_5b_op3', true)::jsonb as p5b3,
    current_setting('app.mc13a.payload_5c_confirmar_op1', true)::jsonb as p5c1,
    current_setting('app.mc13a.payload_5c_cancelar_op2', true)::jsonb as p5c2,
    current_setting('app.mc13a.payload_5d_list_all', true)::jsonb as l_all,
    current_setting('app.mc13a.payload_5d_list_agenda', true)::jsonb as l_agenda,
    current_setting('app.mc13a.payload_5d_filter_confirmada', true)::jsonb as l_confirmada,
    current_setting('app.mc13a.payload_5d_filter_cancelada', true)::jsonb as l_cancelada,
    current_setting('app.mc13a.payload_5d_filter_simulada', true)::jsonb as l_simulada,
    current_setting('app.mc13a.payload_5d_limit_2', true)::jsonb as l_limit_2,
    current_setting('app.mc13a.snapshot_before_5d', true)::jsonb as before_5d,
    current_setting('app.mc13a.snapshot_after_5d', true)::jsonb as after_5d,
    current_setting('app.mc13a.user_id', true) as user_id,
    current_setting('app.mc13a.simulacao_id', true) as simulacao_id,
    current_setting('app.mc13a.agenda_id', true) as agenda_id
),
ids as (
  select
    p5b1->'operacao'->>'id' as op1_id,
    p5b2->'operacao'->>'id' as op2_id,
    p5b3->'operacao'->>'id' as op3_id
  from dados
),
ops_all as (
  select elem
  from dados d,
  lateral jsonb_array_elements(d.l_all->'operacoes') elem
),
ops_agenda as (
  select elem
  from dados d,
  lateral jsonb_array_elements(d.l_agenda->'operacoes') elem
)
select bloco, status, detalhe
from (
  select
    '01_operacoes_fixture_5b_5c_preparadas' as bloco,
    case
      when p5b1->>'ok' = 'true'
       and p5b2->>'ok' = 'true'
       and p5b3->>'ok' = 'true'
       and p5b1->'operacao'->>'status_operacao' = 'simulada'
       and p5b2->'operacao'->>'status_operacao' = 'simulada'
       and p5b3->'operacao'->>'status_operacao' = 'simulada'
       and p5c1->>'ok' = 'true'
       and p5c1->'operacao'->>'status_operacao' = 'confirmada'
       and p5c1->'operacao'->>'confirmado' = 'true'
       and p5c2->>'ok' = 'true'
       and p5c2->'operacao'->>'status_operacao' = 'cancelada'
       and (before_5d->>'qtd_operacoes')::integer = 3
       and (before_5d->>'qtd_confirmada')::integer = 1
       and (before_5d->>'qtd_cancelada')::integer = 1
       and (before_5d->>'qtd_simulada')::integer = 1
       and (before_5d->>'qtd_visivel_cliente')::integer = 0
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object(
      'op1_confirmada', p5c1->'operacao',
      'op2_cancelada', p5c2->'operacao',
      'op3_simulada', p5b3->'operacao',
      'snapshot_before_5d', before_5d
    ) as detalhe
  from dados

  union all

  select
    '02_listagem_geral_retorno_canonico_5d',
    case
      when l_all->>'ok' = 'true'
       and l_all->>'fase' = '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN'
       and l_all->>'visao' = 'administrativa'
       and l_all->>'cliente_safe' = 'false'
       and l_all->>'readonly' = 'true'
       and l_all->>'persistencia' = 'true'
       and l_all->>'dml_financeiro' = 'false'
       and l_all->>'escopo_dml' = 'nenhum'
       and l_all->>'altera_agenda' = 'false'
       and l_all->>'altera_parcelas' = 'false'
       and l_all->>'recalcula_operacao' = 'false'
       and l_all->>'simulacao_id' = simulacao_id
       and (l_all->>'total')::integer = 3
       and jsonb_array_length(l_all->'operacoes') = 3
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'payload_flags', jsonb_build_object(
        'fase', l_all->>'fase',
        'visao', l_all->>'visao',
        'cliente_safe', l_all->>'cliente_safe',
        'readonly', l_all->>'readonly',
        'dml_financeiro', l_all->>'dml_financeiro',
        'escopo_dml', l_all->>'escopo_dml',
        'altera_agenda', l_all->>'altera_agenda',
        'altera_parcelas', l_all->>'altera_parcelas',
        'recalcula_operacao', l_all->>'recalcula_operacao',
        'total', l_all->>'total',
        'qtd_operacoes_payload', jsonb_array_length(l_all->'operacoes')
      )
    )
  from dados

  union all

  select
    '03_listagem_por_agenda_retorna_mesmas_operacoes',
    case
      when l_agenda->>'ok' = 'true'
       and l_agenda->>'agenda_id' = agenda_id
       and (l_agenda->>'total')::integer = 3
       and jsonb_array_length(l_agenda->'operacoes') = 3
       and exists(select 1 from ops_agenda, ids where elem->>'id' = ids.op1_id and elem->>'status_operacao' = 'confirmada')
       and exists(select 1 from ops_agenda, ids where elem->>'id' = ids.op2_id and elem->>'status_operacao' = 'cancelada')
       and exists(select 1 from ops_agenda, ids where elem->>'id' = ids.op3_id and elem->>'status_operacao' = 'simulada')
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id', agenda_id,
      'total', l_agenda->>'total',
      'operacoes', l_agenda->'operacoes'
    )
  from dados

  union all

  select
    '04_campos_minimos_administrativos_presentes',
    case
      when not exists (
        select 1
        from ops_all oa
        where not (
          oa.elem ? 'id'
          and oa.elem ? 'empresa_id'
          and oa.elem ? 'simulacao_id'
          and oa.elem ? 'agenda_id'
          and oa.elem ? 'tipo_operacao'
          and oa.elem ? 'status_operacao'
          and oa.elem ? 'confirmado'
          and oa.elem ? 'confirmado_por'
          and oa.elem ? 'confirmado_em'
          and oa.elem ? 'cancelado_por'
          and oa.elem ? 'cancelado_em'
          and oa.elem ? 'motivo_cancelamento'
          and oa.elem ? 'visivel_cliente'
          and oa.elem ? 'checksum_operacao'
          and oa.elem ? 'valor_movido'
          and oa.elem ? 'valor_base'
          and oa.elem ? 'desconto_calculado'
          and oa.elem ? 'acrescimo_calculado'
          and oa.elem ? 'economia_liquida'
          and oa.elem ? 'status_premio'
          and oa.elem ? 'resumo_financeiro'
          and oa.elem ? 'created_at'
          and oa.elem ? 'updated_at'
        )
      )
      and exists(select 1 from ops_all, ids where elem->>'id' = ids.op1_id and elem->>'confirmado' = 'true' and elem->>'confirmado_por' = user_id)
      and exists(select 1 from ops_all, ids where elem->>'id' = ids.op2_id and elem->>'cancelado_por' = user_id and elem->>'motivo_cancelamento' = 'Cancelamento fixture 13A para validar filtro 5D')
      and exists(select 1 from ops_all, ids where elem->>'id' = ids.op3_id and elem->>'status_operacao' = 'simulada' and elem->>'confirmado' = 'false')
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'ids_esperados', (select to_jsonb(ids.*) from ids),
      'operacoes', l_all->'operacoes'
    )
  from dados

  union all

  select
    '05_filtro_status_confirmada',
    case
      when l_confirmada->>'ok' = 'true'
       and (l_confirmada->>'total')::integer = 1
       and jsonb_array_length(l_confirmada->'operacoes') = 1
       and l_confirmada->'operacoes'->0->>'id' = (select op1_id from ids)
       and l_confirmada->'operacoes'->0->>'status_operacao' = 'confirmada'
       and l_confirmada->'filtros_aplicados'->>'status_operacao' = 'confirmada'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload', l_confirmada)
  from dados

  union all

  select
    '06_filtro_status_cancelada',
    case
      when l_cancelada->>'ok' = 'true'
       and (l_cancelada->>'total')::integer = 1
       and jsonb_array_length(l_cancelada->'operacoes') = 1
       and l_cancelada->'operacoes'->0->>'id' = (select op2_id from ids)
       and l_cancelada->'operacoes'->0->>'status_operacao' = 'cancelada'
       and l_cancelada->'filtros_aplicados'->>'status_operacao' = 'cancelada'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload', l_cancelada)
  from dados

  union all

  select
    '07_filtro_status_simulada',
    case
      when l_simulada->>'ok' = 'true'
       and (l_simulada->>'total')::integer = 1
       and jsonb_array_length(l_simulada->'operacoes') = 1
       and l_simulada->'operacoes'->0->>'id' = (select op3_id from ids)
       and l_simulada->'operacoes'->0->>'status_operacao' = 'simulada'
       and l_simulada->'filtros_aplicados'->>'status_operacao' = 'simulada'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload', l_simulada)
  from dados

  union all

  select
    '08_paginacao_limit_2_preserva_total',
    case
      when l_limit_2->>'ok' = 'true'
       and (l_limit_2->>'total')::integer = 3
       and (l_limit_2->>'limit')::integer = 2
       and (l_limit_2->>'offset')::integer = 0
       and jsonb_array_length(l_limit_2->'operacoes') = 2
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'total', l_limit_2->>'total',
      'limit', l_limit_2->>'limit',
      'offset', l_limit_2->>'offset',
      'qtd_operacoes_payload', jsonb_array_length(l_limit_2->'operacoes'),
      'operacoes', l_limit_2->'operacoes'
    )
  from dados

  union all

  select
    '09_5d_readonly_nao_mutou_agenda_parcelas_operacoes',
    case
      when before_5d->>'agenda_full_hash' = after_5d->>'agenda_full_hash'
       and before_5d->>'parcelas_full_hash' = after_5d->>'parcelas_full_hash'
       and before_5d->>'operacoes_full_hash' = after_5d->>'operacoes_full_hash'
       and before_5d->>'qtd_operacoes' = after_5d->>'qtd_operacoes'
       and before_5d->>'qtd_confirmada' = after_5d->>'qtd_confirmada'
       and before_5d->>'qtd_cancelada' = after_5d->>'qtd_cancelada'
       and before_5d->>'qtd_simulada' = after_5d->>'qtd_simulada'
       and before_5d->>'qtd_visivel_cliente' = after_5d->>'qtd_visivel_cliente'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'before_5d', before_5d,
      'after_5d', after_5d,
      'hash_agenda_igual', before_5d->>'agenda_full_hash' = after_5d->>'agenda_full_hash',
      'hash_parcelas_igual', before_5d->>'parcelas_full_hash' = after_5d->>'parcelas_full_hash',
      'hash_operacoes_igual', before_5d->>'operacoes_full_hash' = after_5d->>'operacoes_full_hash'
    )
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object(
      'mensagem', 'Teste 13A encerra com ROLLBACK. A fixture 4B/5B/5C não deve permanecer no banco.',
      'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
      'validacao', 'listagem positiva administrativa read-only'
    )
) r
order by bloco;

rollback;
