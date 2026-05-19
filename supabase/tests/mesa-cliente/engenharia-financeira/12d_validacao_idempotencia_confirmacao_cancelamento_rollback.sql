-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- 12D — Validação de idempotência da confirmação e do cancelamento.
--
-- Objetivo:
--   Validar que repetir a mesma transição finalizada é idempotente:
--     - confirmar operação já confirmada retorna idempotente=true;
--     - cancelar operação já cancelada retorna idempotente=true;
--     - segunda chamada não altera agenda;
--     - segunda chamada não altera parcelas;
--     - segunda chamada não altera estado/auditoria da operação;
--     - rollback final.

begin;

select set_config('app.mc12d.user_id', '', true);
select set_config('app.mc12d.simulacao_id', '', true);
select set_config('app.mc12d.empresa_id', '', true);
select set_config('app.mc12d.empreendimento_id', '', true);
select set_config('app.mc12d.politica_id', '', true);
select set_config('app.mc12d.agenda_id', '', true);
select set_config('app.mc12d.parcela_confirmar_id', '', true);
select set_config('app.mc12d.parcela_cancelar_id', '', true);
select set_config('app.mc12d.payload_op_confirmar_5b', 'null', true);
select set_config('app.mc12d.payload_op_cancelar_5b', 'null', true);
select set_config('app.mc12d.payload_confirmacao_1', 'null', true);
select set_config('app.mc12d.payload_confirmacao_2', 'null', true);
select set_config('app.mc12d.payload_cancelamento_1', 'null', true);
select set_config('app.mc12d.payload_cancelamento_2', 'null', true);
select set_config('app.mc12d.snapshot_before_ops', 'null', true);
select set_config('app.mc12d.snapshot_after_primeiras', 'null', true);
select set_config('app.mc12d.snapshot_after_idempotentes', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    e.id as empreendimento_id
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
    'Teste rollback 12D idempotência operação financeira 5C',
    41500.50,
    10000.50,
    0,
    41500.50,
    jsonb_build_object('origem', 'teste_12d_5c_rollback', 'fixture_transacional', true),
    'Fixture transacional 12D. Deve sumir no ROLLBACK.'
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
    date '2099-08-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 12D para validação de idempotência da RPC 5C.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 12D — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 12D — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 12D — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc12d.user_id', c.user_id::text, true),
    set_config('app.mc12d.simulacao_id', s.id::text, true),
    set_config('app.mc12d.empresa_id', s.empresa_id::text, true),
    set_config('app.mc12d.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc12d.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_12d' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc12d.simulacao_id', true),
    'politica_id', current_setting('app.mc12d.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc12d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12d.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc12d.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-08-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-08-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',4,'mes_ano','09/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','10/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_12d')
  ) as payload
  from ctx
)
select set_config('app.mc12d.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc12d.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcelas_elegiveis as (
  select
    fp.id,
    row_number() over (order by fp.valor_atual desc, fp.data_atual desc, fp.id) as rn
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > date '2099-08-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
),
snapshot_before_ops as (
  select jsonb_build_object(
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id)
  ) as payload
),
setups as (
  select
    set_config('app.mc12d.agenda_id', (select id::text from agenda), true),
    set_config('app.mc12d.parcela_confirmar_id', (select id::text from parcelas_elegiveis where rn = 1), true),
    set_config('app.mc12d.parcela_cancelar_id', (select id::text from parcelas_elegiveis where rn = 2), true),
    set_config('app.mc12d.snapshot_before_ops', (select payload::text from snapshot_before_ops), true)
)
select
  '00b_agenda_parcelas_fixture_12d' as bloco,
  case
    when current_setting('app.mc12d.agenda_id', true) <> ''
     and current_setting('app.mc12d.parcela_confirmar_id', true) <> ''
     and current_setting('app.mc12d.parcela_cancelar_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc12d.agenda_id', true),
    'parcela_confirmar_id', current_setting('app.mc12d.parcela_confirmar_id', true),
    'parcela_cancelar_id', current_setting('app.mc12d.parcela_cancelar_id', true),
    'before_ops', current_setting('app.mc12d.snapshot_before_ops', true)::jsonb
  ) as detalhe
from setups;

set local role authenticated;

with op_confirmar as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12d.simulacao_id', true)::uuid,
    current_setting('app.mc12d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12d.parcela_confirmar_id', true)::uuid,
    date '2099-08-31',
    null,
    4000.00,
    jsonb_build_object('origem_teste', '12d', 'cenario', 'idempotencia_confirmacao')
  ) as payload
),
op_cancelar as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12d.simulacao_id', true)::uuid,
    current_setting('app.mc12d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12d.parcela_cancelar_id', true)::uuid,
    date '2099-08-31',
    null,
    2000.00,
    jsonb_build_object('origem_teste', '12d', 'cenario', 'idempotencia_cancelamento')
  ) as payload
),
setups as (
  select
    set_config('app.mc12d.payload_op_confirmar_5b', (select payload::text from op_confirmar), true),
    set_config('app.mc12d.payload_op_cancelar_5b', (select payload::text from op_cancelar), true)
)
select count(*) from setups;

with confirmacao_1 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12d.payload_op_confirmar_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '12d', 'rodada', 1, 'cenario', 'confirmacao')
  ) as payload
),
cancelamento_1 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12d.payload_op_cancelar_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Cancelamento inicial para idempotência 12D',
    jsonb_build_object('origem_teste', '12d', 'rodada', 1, 'cenario', 'cancelamento')
  ) as payload
),
setups as (
  select
    set_config('app.mc12d.payload_confirmacao_1', (select payload::text from confirmacao_1), true),
    set_config('app.mc12d.payload_cancelamento_1', (select payload::text from cancelamento_1), true)
)
select count(*) from setups;

reset role;

with ctx as (
  select
    current_setting('app.mc12d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12d.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after_primeiras as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_canceladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'confirmado_por', o.confirmado_por, 'confirmado_em', o.confirmado_em, 'cancelado_por', o.cancelado_por, 'cancelado_em', o.cancelado_em, 'motivo_cancelamento', o.motivo_cancelamento, 'updated_at', o.updated_at, 'visivel_cliente', o.visivel_cliente) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12d.snapshot_after_primeiras', coalesce((select payload::text from snapshot_after_primeiras), 'null'), true);

set local role authenticated;

with confirmacao_2 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12d.payload_op_confirmar_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '12d', 'rodada', 2, 'cenario', 'confirmacao_idempotente')
  ) as payload
),
cancelamento_2 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12d.payload_op_cancelar_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Tentativa idempotente 12D não deve alterar motivo original',
    jsonb_build_object('origem_teste', '12d', 'rodada', 2, 'cenario', 'cancelamento_idempotente')
  ) as payload
),
setups as (
  select
    set_config('app.mc12d.payload_confirmacao_2', (select payload::text from confirmacao_2), true),
    set_config('app.mc12d.payload_cancelamento_2', (select payload::text from cancelamento_2), true)
)
select count(*) from setups;

reset role;

with ctx as (
  select
    current_setting('app.mc12d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12d.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after_idempotentes as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_canceladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'confirmado_por', o.confirmado_por, 'confirmado_em', o.confirmado_em, 'cancelado_por', o.cancelado_por, 'cancelado_em', o.cancelado_em, 'motivo_cancelamento', o.motivo_cancelamento, 'updated_at', o.updated_at, 'visivel_cliente', o.visivel_cliente) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12d.snapshot_after_idempotentes', coalesce((select payload::text from snapshot_after_idempotentes), 'null'), true);

with dados as (
  select
    current_setting('app.mc12d.snapshot_before_ops', true)::jsonb as before_ops,
    current_setting('app.mc12d.snapshot_after_primeiras', true)::jsonb as primeiras,
    current_setting('app.mc12d.snapshot_after_idempotentes', true)::jsonb as final,
    current_setting('app.mc12d.payload_confirmacao_1', true)::jsonb as confirmacao_1,
    current_setting('app.mc12d.payload_confirmacao_2', true)::jsonb as confirmacao_2,
    current_setting('app.mc12d.payload_cancelamento_1', true)::jsonb as cancelamento_1,
    current_setting('app.mc12d.payload_cancelamento_2', true)::jsonb as cancelamento_2
)
select bloco, status, detalhe
from (
  select
    '01_primeiras_transicoes_preparadas' as bloco,
    case
      when confirmacao_1->>'ok' = 'true'
       and confirmacao_1->>'idempotente' = 'false'
       and confirmacao_1->'operacao'->>'status_operacao' = 'confirmada'
       and cancelamento_1->>'ok' = 'true'
       and cancelamento_1->>'idempotente' = 'false'
       and cancelamento_1->'operacao'->>'status_operacao' = 'cancelada'
       and (primeiras->>'operacoes')::integer = 2
       and (primeiras->>'operacoes_confirmadas')::integer = 1
       and (primeiras->>'operacoes_canceladas')::integer = 1
       and (primeiras->>'operacoes_visiveis_cliente')::integer = 0
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object('confirmacao_1', confirmacao_1, 'cancelamento_1', cancelamento_1, 'snapshot_primeiras', primeiras) as detalhe
  from dados

  union all

  select
    '02_confirmacao_idempotente',
    case
      when confirmacao_2->>'ok' = 'true'
       and confirmacao_2->>'acao' = 'confirmar'
       and confirmacao_2->>'idempotente' = 'true'
       and confirmacao_2->'operacao'->>'id' = confirmacao_1->'operacao'->>'id'
       and confirmacao_2->'operacao'->>'status_operacao' = 'confirmada'
       and confirmacao_2->'operacao'->>'confirmado' = 'true'
       and confirmacao_2->'operacao'->>'confirmado_por' = confirmacao_1->'operacao'->>'confirmado_por'
       and confirmacao_2->'operacao'->>'confirmado_em' = confirmacao_1->'operacao'->>'confirmado_em'
       and confirmacao_2->'operacao'->>'updated_at' = confirmacao_1->'operacao'->>'updated_at'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('confirmacao_1', confirmacao_1->'operacao', 'confirmacao_2', confirmacao_2->'operacao')
  from dados

  union all

  select
    '03_cancelamento_idempotente',
    case
      when cancelamento_2->>'ok' = 'true'
       and cancelamento_2->>'acao' = 'cancelar'
       and cancelamento_2->>'idempotente' = 'true'
       and cancelamento_2->'operacao'->>'id' = cancelamento_1->'operacao'->>'id'
       and cancelamento_2->'operacao'->>'status_operacao' = 'cancelada'
       and cancelamento_2->'operacao'->>'confirmado' = 'false'
       and cancelamento_2->'operacao'->>'cancelado_por' = cancelamento_1->'operacao'->>'cancelado_por'
       and cancelamento_2->'operacao'->>'cancelado_em' = cancelamento_1->'operacao'->>'cancelado_em'
       and cancelamento_2->'operacao'->>'motivo_cancelamento' = cancelamento_1->'operacao'->>'motivo_cancelamento'
       and cancelamento_2->'operacao'->>'updated_at' = cancelamento_1->'operacao'->>'updated_at'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('cancelamento_1', cancelamento_1->'operacao', 'cancelamento_2', cancelamento_2->'operacao')
  from dados

  union all

  select
    '04_segundas_chamadas_nao_mutaram_operacoes',
    case
      when primeiras->>'operacoes' = final->>'operacoes'
       and primeiras->>'operacoes_confirmadas' = final->>'operacoes_confirmadas'
       and primeiras->>'operacoes_canceladas' = final->>'operacoes_canceladas'
       and primeiras->>'operacoes_visiveis_cliente' = final->>'operacoes_visiveis_cliente'
       and primeiras->>'operacoes_full_hash' = final->>'operacoes_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('primeiras', primeiras, 'final', final)
  from dados

  union all

  select
    '05_agenda_parcelas_nao_mutadas',
    case
      when before_ops->>'agenda_id' = final->>'agenda_id'
       and before_ops->>'agenda_checksum' = final->>'agenda_checksum'
       and before_ops->'agenda_tots' = final->'agenda_tots'
       and before_ops->>'agenda_full_hash' = final->>'agenda_full_hash'
       and before_ops->>'parcelas' = final->>'parcelas'
       and before_ops->>'valor_total_parcelas' = final->>'valor_total_parcelas'
       and before_ops->>'parcelas_ids' = final->>'parcelas_ids'
       and before_ops->>'parcelas_full_hash' = final->>'parcelas_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('before_ops', before_ops, 'final', final)
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 12D encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
