-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- 13B — Validação positiva da RPC de detalhe administrativo de operação financeira.
--
-- Pré-requisitos:
--   - Fase 5B aplicada;
--   - Fase 5C aplicada;
--   - Migration 5D aplicada:
--     supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, registrar operações via 5B,
--   confirmar/cancelar algumas operações via 5C e validar a RPC 5D de detalhe:
--     - obter detalhe de operação confirmada;
--     - obter detalhe de operação cancelada;
--     - obter detalhe de operação simulada;
--     - validar retorno canônico administrativo;
--     - validar auditoria 5C;
--     - validar campos financeiros persistidos pela 5B;
--     - validar vínculos com simulação/agenda/parcela;
--     - validar que a 5D não altera agenda, parcelas nem operações;
--     - rollback final.
--
-- Segurança:
--   O teste cria fixture dentro de transação e encerra com ROLLBACK.
--   A única mutação intencional é a preparação da fixture 4B/5B/5C.
--   A etapa 5D validada é somente leitura.

begin;

select set_config('app.mc13b.user_id', '', true);
select set_config('app.mc13b.simulacao_id', '', true);
select set_config('app.mc13b.empresa_id', '', true);
select set_config('app.mc13b.empreendimento_id', '', true);
select set_config('app.mc13b.politica_id', '', true);
select set_config('app.mc13b.agenda_id', '', true);
select set_config('app.mc13b.parcela_1_id', '', true);
select set_config('app.mc13b.parcela_2_id', '', true);
select set_config('app.mc13b.parcela_3_id', '', true);
select set_config('app.mc13b.payload_4b', 'null', true);
select set_config('app.mc13b.payload_5b_op1', 'null', true);
select set_config('app.mc13b.payload_5b_op2', 'null', true);
select set_config('app.mc13b.payload_5b_op3', 'null', true);
select set_config('app.mc13b.payload_5c_confirmar_op1', 'null', true);
select set_config('app.mc13b.payload_5c_cancelar_op2', 'null', true);
select set_config('app.mc13b.snapshot_before_5d', 'null', true);
select set_config('app.mc13b.snapshot_after_5d', 'null', true);
select set_config('app.mc13b.payload_5d_obter_confirmada', 'null', true);
select set_config('app.mc13b.payload_5d_obter_cancelada', 'null', true);
select set_config('app.mc13b.payload_5d_obter_simulada', 'null', true);
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
    'Teste rollback 13B detalhe operação financeira 5D',
    52000.00,
    14000.00,
    0,
    52000.00,
    jsonb_build_object('origem', 'teste_13b_5d_rollback', 'fixture_transacional', true),
    'Fixture transacional 13B. Deve sumir no ROLLBACK.'
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
    date '2099-07-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 13B para validação positiva do detalhe administrativo pela RPC 5D.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 13B — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 13B — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 13B — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc13b.user_id', c.user_id::text, true),
    set_config('app.mc13b.simulacao_id', s.id::text, true),
    set_config('app.mc13b.empresa_id', s.empresa_id::text, true),
    set_config('app.mc13b.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc13b.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_13b' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc13b.simulacao_id', true),
    'politica_id', current_setting('app.mc13b.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc13b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13b.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc13b.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-07-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','14000.00','data','2099-07-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais 13B','valor','2600.00','quantidade',4,'mes_ano','08/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária 13B','valor','9500.00','quantidade',2,'mes_ano','12/2099'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','09/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_13b')
  ) as payload
  from ctx
)
select set_config('app.mc13b.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc13b.simulacao_id', true)::uuid as simulacao_id
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
    and fp.data_atual > date '2099-07-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
),
setups as (
  select
    set_config('app.mc13b.agenda_id', (select id::text from agenda), true),
    set_config('app.mc13b.parcela_1_id', (select id::text from parcelas_ranked where rn = 1), true),
    set_config('app.mc13b.parcela_2_id', (select id::text from parcelas_ranked where rn = 2), true),
    set_config('app.mc13b.parcela_3_id', (select id::text from parcelas_ranked where rn = 3), true)
)
select
  '00b_agenda_parcelas_fixture_13b' as bloco,
  case
    when current_setting('app.mc13b.agenda_id', true) <> ''
     and current_setting('app.mc13b.parcela_1_id', true) <> ''
     and current_setting('app.mc13b.parcela_2_id', true) <> ''
     and current_setting('app.mc13b.parcela_3_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc13b.agenda_id', true),
    'parcela_1_id', current_setting('app.mc13b.parcela_1_id', true),
    'parcela_2_id', current_setting('app.mc13b.parcela_2_id', true),
    'parcela_3_id', current_setting('app.mc13b.parcela_3_id', true),
    'qtd_parcelas_elegiveis', (select count(*) from parcelas_ranked)
  ) as detalhe
from setups;

set local role authenticated;

with chamada_5b_op1 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13b.simulacao_id', true)::uuid,
    current_setting('app.mc13b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13b.parcela_1_id', true)::uuid,
    date '2099-07-31',
    null,
    1100.00,
    jsonb_build_object('origem_teste', '13b', 'op', 'op1_confirmada', 'observacao', 'operacao para detalhe 5D')
  ) as payload
)
select set_config('app.mc13b.payload_5b_op1', coalesce((select payload::text from chamada_5b_op1), 'null'), true);

with chamada_5b_op2 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13b.simulacao_id', true)::uuid,
    current_setting('app.mc13b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13b.parcela_2_id', true)::uuid,
    date '2099-07-31',
    null,
    1300.00,
    jsonb_build_object('origem_teste', '13b', 'op', 'op2_cancelada', 'observacao', 'operacao para detalhe 5D')
  ) as payload
)
select set_config('app.mc13b.payload_5b_op2', coalesce((select payload::text from chamada_5b_op2), 'null'), true);

with chamada_5b_op3 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13b.simulacao_id', true)::uuid,
    current_setting('app.mc13b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13b.parcela_3_id', true)::uuid,
    date '2099-07-31',
    null,
    950.00,
    jsonb_build_object('origem_teste', '13b', 'op', 'op3_simulada', 'observacao', 'operacao para detalhe 5D')
  ) as payload
)
select set_config('app.mc13b.payload_5b_op3', coalesce((select payload::text from chamada_5b_op3), 'null'), true);

with chamada_5c_confirmar_op1 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc13b.payload_5b_op1', true)::jsonb->'operacao'->>'id')::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '13b', 'observacao', 'confirmacao para validar detalhe 5D')
  ) as payload
)
select set_config('app.mc13b.payload_5c_confirmar_op1', coalesce((select payload::text from chamada_5c_confirmar_op1), 'null'), true);

with chamada_5c_cancelar_op2 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc13b.payload_5b_op2', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Cancelamento fixture 13B para validar detalhe 5D',
    jsonb_build_object('origem_teste', '13b', 'observacao', 'cancelamento para validar detalhe 5D')
  ) as payload
)
select set_config('app.mc13b.payload_5c_cancelar_op2', coalesce((select payload::text from chamada_5c_cancelar_op2), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc13b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13b.agenda_id', true)::uuid as agenda_id
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
select set_config('app.mc13b.snapshot_before_5d', coalesce((select payload::text from snapshot_before_5d), 'null'), true);

set local role authenticated;

with chamada_5d_obter_confirmada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    (current_setting('app.mc13b.payload_5b_op1', true)::jsonb->'operacao'->>'id')::uuid,
    '{}'::jsonb
  ) as payload
)
select set_config('app.mc13b.payload_5d_obter_confirmada', coalesce((select payload::text from chamada_5d_obter_confirmada), 'null'), true);

with chamada_5d_obter_cancelada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    (current_setting('app.mc13b.payload_5b_op2', true)::jsonb->'operacao'->>'id')::uuid,
    '{}'::jsonb
  ) as payload
)
select set_config('app.mc13b.payload_5d_obter_cancelada', coalesce((select payload::text from chamada_5d_obter_cancelada), 'null'), true);

with chamada_5d_obter_simulada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    (current_setting('app.mc13b.payload_5b_op3', true)::jsonb->'operacao'->>'id')::uuid,
    '{}'::jsonb
  ) as payload
)
select set_config('app.mc13b.payload_5d_obter_simulada', coalesce((select payload::text from chamada_5d_obter_simulada), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc13b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13b.agenda_id', true)::uuid as agenda_id
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
select set_config('app.mc13b.snapshot_after_5d', coalesce((select payload::text from snapshot_after_5d), 'null'), true);

with dados as (
  select
    current_setting('app.mc13b.payload_5b_op1', true)::jsonb as p5b1,
    current_setting('app.mc13b.payload_5b_op2', true)::jsonb as p5b2,
    current_setting('app.mc13b.payload_5b_op3', true)::jsonb as p5b3,
    current_setting('app.mc13b.payload_5c_confirmar_op1', true)::jsonb as p5c1,
    current_setting('app.mc13b.payload_5c_cancelar_op2', true)::jsonb as p5c2,
    current_setting('app.mc13b.payload_5d_obter_confirmada', true)::jsonb as d_confirmada,
    current_setting('app.mc13b.payload_5d_obter_cancelada', true)::jsonb as d_cancelada,
    current_setting('app.mc13b.payload_5d_obter_simulada', true)::jsonb as d_simulada,
    current_setting('app.mc13b.snapshot_before_5d', true)::jsonb as before_5d,
    current_setting('app.mc13b.snapshot_after_5d', true)::jsonb as after_5d,
    current_setting('app.mc13b.user_id', true) as user_id,
    current_setting('app.mc13b.simulacao_id', true) as simulacao_id,
    current_setting('app.mc13b.agenda_id', true) as agenda_id,
    current_setting('app.mc13b.parcela_1_id', true) as parcela_1_id,
    current_setting('app.mc13b.parcela_2_id', true) as parcela_2_id,
    current_setting('app.mc13b.parcela_3_id', true) as parcela_3_id
),
ids as (
  select
    p5b1->'operacao'->>'id' as op1_id,
    p5b2->'operacao'->>'id' as op2_id,
    p5b3->'operacao'->>'id' as op3_id
  from dados
),
detalhes as (
  select 'confirmada'::text as alvo, d_confirmada as payload from dados
  union all
  select 'cancelada'::text, d_cancelada from dados
  union all
  select 'simulada'::text, d_simulada from dados
)
select bloco, status, detalhe
from (
  select
    '01_operacoes_fixture_5b_5c_preparadas' as bloco,
    case
      when p5b1->>'ok' = 'true'
       and p5b2->>'ok' = 'true'
       and p5b3->>'ok' = 'true'
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
      'op1_confirmada_5c', p5c1->'operacao',
      'op2_cancelada_5c', p5c2->'operacao',
      'op3_simulada_5b', p5b3->'operacao',
      'snapshot_before_5d', before_5d
    ) as detalhe
  from dados

  union all

  select
    '02_detalhe_confirmada_retorno_canonico_5d',
    case
      when d_confirmada->>'ok' = 'true'
       and d_confirmada->>'fase' = '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN'
       and d_confirmada->>'visao' = 'administrativa'
       and d_confirmada->>'cliente_safe' = 'false'
       and d_confirmada->>'readonly' = 'true'
       and d_confirmada->>'persistencia' = 'true'
       and d_confirmada->>'dml_financeiro' = 'false'
       and d_confirmada->>'escopo_dml' = 'nenhum'
       and d_confirmada->>'altera_agenda' = 'false'
       and d_confirmada->>'altera_parcelas' = 'false'
       and d_confirmada->>'recalcula_operacao' = 'false'
       and d_confirmada->>'simulacao_id' = simulacao_id
       and d_confirmada->>'agenda_id' = agenda_id
       and d_confirmada->'operacao'->>'id' = (select op1_id from ids)
       and d_confirmada->'operacao'->>'status_operacao' = 'confirmada'
       and d_confirmada->'operacao'->>'confirmado' = 'true'
       and d_confirmada->'operacao'->>'confirmado_por' = user_id
       and d_confirmada->'operacao'->>'visivel_cliente' = 'false'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload', d_confirmada)
  from dados

  union all

  select
    '03_detalhe_cancelada_retorno_canonico_5d',
    case
      when d_cancelada->>'ok' = 'true'
       and d_cancelada->>'fase' = '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN'
       and d_cancelada->>'visao' = 'administrativa'
       and d_cancelada->>'cliente_safe' = 'false'
       and d_cancelada->>'readonly' = 'true'
       and d_cancelada->>'dml_financeiro' = 'false'
       and d_cancelada->>'altera_agenda' = 'false'
       and d_cancelada->>'altera_parcelas' = 'false'
       and d_cancelada->>'recalcula_operacao' = 'false'
       and d_cancelada->>'simulacao_id' = simulacao_id
       and d_cancelada->>'agenda_id' = agenda_id
       and d_cancelada->'operacao'->>'id' = (select op2_id from ids)
       and d_cancelada->'operacao'->>'status_operacao' = 'cancelada'
       and d_cancelada->'operacao'->>'confirmado' = 'false'
       and d_cancelada->'operacao'->>'cancelado_por' = user_id
       and d_cancelada->'operacao'->>'motivo_cancelamento' = 'Cancelamento fixture 13B para validar detalhe 5D'
       and d_cancelada->'operacao'->>'visivel_cliente' = 'false'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload', d_cancelada)
  from dados

  union all

  select
    '04_detalhe_simulada_retorno_canonico_5d',
    case
      when d_simulada->>'ok' = 'true'
       and d_simulada->>'fase' = '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN'
       and d_simulada->>'visao' = 'administrativa'
       and d_simulada->>'cliente_safe' = 'false'
       and d_simulada->>'readonly' = 'true'
       and d_simulada->>'dml_financeiro' = 'false'
       and d_simulada->>'altera_agenda' = 'false'
       and d_simulada->>'altera_parcelas' = 'false'
       and d_simulada->>'recalcula_operacao' = 'false'
       and d_simulada->>'simulacao_id' = simulacao_id
       and d_simulada->>'agenda_id' = agenda_id
       and d_simulada->'operacao'->>'id' = (select op3_id from ids)
       and d_simulada->'operacao'->>'status_operacao' = 'simulada'
       and d_simulada->'operacao'->>'confirmado' = 'false'
       and d_simulada->'operacao'->>'confirmado_por' is null
       and d_simulada->'operacao'->>'cancelado_por' is null
       and d_simulada->'operacao'->>'visivel_cliente' = 'false'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload', d_simulada)
  from dados

  union all

  select
    '05_campos_financeiros_completos_5b_presentes',
    case
      when not exists (
        select 1
        from detalhes d
        where not (
          d.payload ? 'operacao'
          and d.payload->'operacao' ? 'id'
          and d.payload->'operacao' ? 'empresa_id'
          and d.payload->'operacao' ? 'simulacao_id'
          and d.payload->'operacao' ? 'agenda_id'
          and d.payload->'operacao' ? 'empreendimento_id'
          and d.payload->'operacao' ? 'politica_id'
          and d.payload->'operacao' ? 'tipo_operacao'
          and d.payload->'operacao' ? 'status_operacao'
          and d.payload->'operacao' ? 'grupo_origem'
          and d.payload->'operacao' ? 'grupo_destino'
          and d.payload->'operacao' ? 'parcela_origem_id'
          and d.payload->'operacao' ? 'parcela_destino_id'
          and d.payload->'operacao' ? 'valor_movido'
          and d.payload->'operacao' ? 'valor_base'
          and d.payload->'operacao' ? 'data_origem'
          and d.payload->'operacao' ? 'data_destino'
          and d.payload->'operacao' ? 'taxa_ano_pct'
          and d.payload->'operacao' ? 'vpl_aplicado_pct'
          and d.payload->'operacao' ? 'desconto_calculado'
          and d.payload->'operacao' ? 'acrescimo_calculado'
          and d.payload->'operacao' ? 'economia_liquida'
          and d.payload->'operacao' ? 'dias_calculo'
          and d.payload->'operacao' ? 'premio_corretor_pct'
          and d.payload->'operacao' ? 'status_premio'
          and d.payload->'operacao' ? 'resumo_financeiro'
          and d.payload->'operacao'->'resumo_financeiro' ? 'valor_movido'
          and d.payload->'operacao'->'resumo_financeiro' ? 'valor_base'
          and d.payload->'operacao'->'resumo_financeiro' ? 'desconto_calculado'
          and d.payload->'operacao'->'resumo_financeiro' ? 'acrescimo_calculado'
          and d.payload->'operacao'->'resumo_financeiro' ? 'economia_liquida'
          and d.payload->'operacao'->'resumo_financeiro' ? 'premio_corretor_pct'
          and d.payload->'operacao'->'resumo_financeiro' ? 'status_premio'
        )
      )
      and (d_confirmada->'operacao'->>'valor_movido')::numeric = 1100.00
      and (d_cancelada->'operacao'->>'valor_movido')::numeric = 1300.00
      and (d_simulada->'operacao'->>'valor_movido')::numeric = 950.00
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'confirmada_resumo', d_confirmada->'operacao'->'resumo_financeiro',
      'cancelada_resumo', d_cancelada->'operacao'->'resumo_financeiro',
      'simulada_resumo', d_simulada->'operacao'->'resumo_financeiro'
    )
  from dados

  union all

  select
    '06_auditoria_5c_completa_no_detalhe',
    case
      when d_confirmada->'operacao' ? 'auditoria_5c'
       and d_cancelada->'operacao' ? 'auditoria_5c'
       and d_simulada->'operacao' ? 'auditoria_5c'
       and d_confirmada->'operacao'->'auditoria_5c'->>'confirmado' = 'true'
       and d_confirmada->'operacao'->'auditoria_5c'->>'confirmado_por' = user_id
       and d_confirmada->'operacao'->'auditoria_5c'->>'confirmado_em' is not null
       and d_cancelada->'operacao'->'auditoria_5c'->>'confirmado' = 'false'
       and d_cancelada->'operacao'->'auditoria_5c'->>'cancelado_por' = user_id
       and d_cancelada->'operacao'->'auditoria_5c'->>'cancelado_em' is not null
       and d_cancelada->'operacao'->'auditoria_5c'->>'motivo_cancelamento' = 'Cancelamento fixture 13B para validar detalhe 5D'
       and d_simulada->'operacao'->'auditoria_5c'->>'confirmado' = 'false'
       and d_simulada->'operacao'->'auditoria_5c'->>'confirmado_por' is null
       and d_simulada->'operacao'->'auditoria_5c'->>'cancelado_por' is null
       and d_simulada->'operacao'->'auditoria_5c'->>'cancelado_em' is null
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'confirmada_auditoria', d_confirmada->'operacao'->'auditoria_5c',
      'cancelada_auditoria', d_cancelada->'operacao'->'auditoria_5c',
      'simulada_auditoria', d_simulada->'operacao'->'auditoria_5c'
    )
  from dados

  union all

  select
    '07_vinculos_simulacao_agenda_parcela_preservados',
    case
      when d_confirmada->'operacao' ? 'vinculos'
       and d_cancelada->'operacao' ? 'vinculos'
       and d_simulada->'operacao' ? 'vinculos'
       and d_confirmada->'operacao'->'vinculos'->>'simulacao_id' = simulacao_id
       and d_confirmada->'operacao'->'vinculos'->>'agenda_id' = agenda_id
       and d_confirmada->'operacao'->'vinculos'->>'parcela_origem_id' = parcela_1_id
       and d_cancelada->'operacao'->'vinculos'->>'simulacao_id' = simulacao_id
       and d_cancelada->'operacao'->'vinculos'->>'agenda_id' = agenda_id
       and d_cancelada->'operacao'->'vinculos'->>'parcela_origem_id' = parcela_2_id
       and d_simulada->'operacao'->'vinculos'->>'simulacao_id' = simulacao_id
       and d_simulada->'operacao'->'vinculos'->>'agenda_id' = agenda_id
       and d_simulada->'operacao'->'vinculos'->>'parcela_origem_id' = parcela_3_id
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'confirmada_vinculos', d_confirmada->'operacao'->'vinculos',
      'cancelada_vinculos', d_cancelada->'operacao'->'vinculos',
      'simulada_vinculos', d_simulada->'operacao'->'vinculos'
    )
  from dados

  union all

  select
    '08_metadata_e_checksum_disponiveis_no_detalhe',
    case
      when d_confirmada->'operacao' ? 'metadata'
       and d_cancelada->'operacao' ? 'metadata'
       and d_simulada->'operacao' ? 'metadata'
       and nullif(d_confirmada->'operacao'->>'checksum_operacao', '') is not null
       and nullif(d_cancelada->'operacao'->>'checksum_operacao', '') is not null
       and nullif(d_simulada->'operacao'->>'checksum_operacao', '') is not null
       and d_confirmada->'operacao'->'metadata'->'parametros_nao_soberanos'->>'origem_teste' = '13b'
       and d_cancelada->'operacao'->'metadata'->'parametros_nao_soberanos'->>'origem_teste' = '13b'
       and d_simulada->'operacao'->'metadata'->'parametros_nao_soberanos'->>'origem_teste' = '13b'
       and d_confirmada->'operacao'->'metadata'->'fase_5c'->'parametros_nao_soberanos'->>'origem_teste' = '13b'
       and d_cancelada->'operacao'->'metadata'->'fase_5c'->'parametros_nao_soberanos'->>'origem_teste' = '13b'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'confirmada_checksum', d_confirmada->'operacao'->>'checksum_operacao',
      'cancelada_checksum', d_cancelada->'operacao'->>'checksum_operacao',
      'simulada_checksum', d_simulada->'operacao'->>'checksum_operacao',
      'confirmada_metadata', d_confirmada->'operacao'->'metadata',
      'cancelada_metadata', d_cancelada->'operacao'->'metadata',
      'simulada_metadata', d_simulada->'operacao'->'metadata'
    )
  from dados

  union all

  select
    '09_5d_obter_readonly_nao_mutou_agenda_parcelas_operacoes',
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
      'mensagem', 'Teste 13B encerra com ROLLBACK. A fixture 4B/5B/5C não deve permanecer no banco.',
      'fase', '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN',
      'validacao', 'detalhe positivo administrativo read-only'
    )
) r
order by bloco;

rollback;
