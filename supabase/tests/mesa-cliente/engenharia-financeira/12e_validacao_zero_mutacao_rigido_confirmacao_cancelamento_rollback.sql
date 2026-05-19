-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- 12E — Zero mutação rígido da confirmação/cancelamento.
--
-- Objetivo:
--   Validar que confirmar/cancelar pela RPC 5C altera somente campos de status/auditoria permitidos,
--   preservando campos financeiros e estruturais da operação, agenda e parcelas.
--
-- Campos que podem mudar na operação:
--   - status_operacao;
--   - confirmado;
--   - confirmado_por;
--   - confirmado_em;
--   - cancelado_por;
--   - cancelado_em;
--   - motivo_cancelamento;
--   - updated_at;
--   - metadata.
--
-- Campos que devem permanecer estáveis:
--   - ids e vínculos;
--   - tipo_operacao;
--   - parcela_origem_id;
--   - datas/valores financeiros;
--   - resultado/calculo;
--   - checksum_operacao;
--   - visivel_cliente;
--   - agenda;
--   - parcelas.

begin;

select set_config('app.mc12e.user_id', '', true);
select set_config('app.mc12e.simulacao_id', '', true);
select set_config('app.mc12e.empresa_id', '', true);
select set_config('app.mc12e.empreendimento_id', '', true);
select set_config('app.mc12e.politica_id', '', true);
select set_config('app.mc12e.agenda_id', '', true);
select set_config('app.mc12e.parcela_confirmar_id', '', true);
select set_config('app.mc12e.parcela_cancelar_id', '', true);
select set_config('app.mc12e.payload_op_confirmar_5b', 'null', true);
select set_config('app.mc12e.payload_op_cancelar_5b', 'null', true);
select set_config('app.mc12e.payload_confirmacao_5c', 'null', true);
select set_config('app.mc12e.payload_cancelamento_5c', 'null', true);
select set_config('app.mc12e.snapshot_before_5c', 'null', true);
select set_config('app.mc12e.snapshot_after_5c', 'null', true);
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
    'Teste rollback 12E zero mutação rígido operação financeira 5C',
    41500.50,
    10000.50,
    0,
    41500.50,
    jsonb_build_object('origem', 'teste_12e_5c_rollback', 'fixture_transacional', true),
    'Fixture transacional 12E. Deve sumir no ROLLBACK.'
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
    date '2099-09-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 12E para zero mutação rígido da RPC 5C.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 12E — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 12E — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 12E — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc12e.user_id', c.user_id::text, true),
    set_config('app.mc12e.simulacao_id', s.id::text, true),
    set_config('app.mc12e.empresa_id', s.empresa_id::text, true),
    set_config('app.mc12e.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc12e.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_12e' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc12e.simulacao_id', true),
    'politica_id', current_setting('app.mc12e.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc12e.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12e.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc12e.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-09-30',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-09-30'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',4,'mes_ano','10/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','11/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_12e')
  ) as payload
  from ctx
)
select set_config('app.mc12e.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc12e.simulacao_id', true)::uuid as simulacao_id
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
    and fp.data_atual > date '2099-09-30'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
),
setups as (
  select
    set_config('app.mc12e.agenda_id', (select id::text from agenda), true),
    set_config('app.mc12e.parcela_confirmar_id', (select id::text from parcelas_elegiveis where rn = 1), true),
    set_config('app.mc12e.parcela_cancelar_id', (select id::text from parcelas_elegiveis where rn = 2), true)
)
select
  '00b_agenda_parcelas_fixture_12e' as bloco,
  case
    when current_setting('app.mc12e.agenda_id', true) <> ''
     and current_setting('app.mc12e.parcela_confirmar_id', true) <> ''
     and current_setting('app.mc12e.parcela_cancelar_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc12e.agenda_id', true),
    'parcela_confirmar_id', current_setting('app.mc12e.parcela_confirmar_id', true),
    'parcela_cancelar_id', current_setting('app.mc12e.parcela_cancelar_id', true)
  ) as detalhe
from setups;

set local role authenticated;

with op_confirmar as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12e.simulacao_id', true)::uuid,
    current_setting('app.mc12e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12e.parcela_confirmar_id', true)::uuid,
    date '2099-09-30',
    null,
    4000.00,
    jsonb_build_object('origem_teste', '12e', 'cenario', 'zero_mutacao_confirmacao')
  ) as payload
),
op_cancelar as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12e.simulacao_id', true)::uuid,
    current_setting('app.mc12e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12e.parcela_cancelar_id', true)::uuid,
    date '2099-09-30',
    null,
    2000.00,
    jsonb_build_object('origem_teste', '12e', 'cenario', 'zero_mutacao_cancelamento')
  ) as payload
),
setups as (
  select
    set_config('app.mc12e.payload_op_confirmar_5b', (select payload::text from op_confirmar), true),
    set_config('app.mc12e.payload_op_cancelar_5b', (select payload::text from op_cancelar), true)
)
select count(*) from setups;

reset role;

with ctx as (
  select
    current_setting('app.mc12e.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12e.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_before_5c as (
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
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object(
      'id', o.id,
      'simulacao_id', o.simulacao_id,
      'agenda_id', o.agenda_id,
      'empresa_id', o.empresa_id,
      'tipo_operacao', o.tipo_operacao,
      'parcela_origem_id', o.parcela_origem_id,
      'status_operacao', o.status_operacao,
      'confirmado', o.confirmado,
      'confirmado_por', o.confirmado_por,
      'confirmado_em', o.confirmado_em,
      'cancelado_por', o.cancelado_por,
      'cancelado_em', o.cancelado_em,
      'motivo_cancelamento', o.motivo_cancelamento,
      'visivel_cliente', o.visivel_cliente,
      'checksum_operacao', o.checksum_operacao,
      'updated_at', o.updated_at,
      'full', to_jsonb(o),
      'immutable_hash', md5((to_jsonb(o) - 'status_operacao' - 'confirmado' - 'confirmado_por' - 'confirmado_em' - 'cancelado_por' - 'cancelado_em' - 'motivo_cancelamento' - 'updated_at' - 'metadata')::text)
    ) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12e.snapshot_before_5c', coalesce((select payload::text from snapshot_before_5c), 'null'), true);

set local role authenticated;

with confirmacao_5c as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12e.payload_op_confirmar_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '12e', 'cenario', 'zero_mutacao_confirmacao')
  ) as payload
),
cancelamento_5c as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12e.payload_op_cancelar_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Cancelamento 12E para zero mutação rígido',
    jsonb_build_object('origem_teste', '12e', 'cenario', 'zero_mutacao_cancelamento')
  ) as payload
),
setups as (
  select
    set_config('app.mc12e.payload_confirmacao_5c', (select payload::text from confirmacao_5c), true),
    set_config('app.mc12e.payload_cancelamento_5c', (select payload::text from cancelamento_5c), true)
)
select count(*) from setups;

reset role;

with ctx as (
  select
    current_setting('app.mc12e.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12e.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after_5c as (
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
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object(
      'id', o.id,
      'simulacao_id', o.simulacao_id,
      'agenda_id', o.agenda_id,
      'empresa_id', o.empresa_id,
      'tipo_operacao', o.tipo_operacao,
      'parcela_origem_id', o.parcela_origem_id,
      'status_operacao', o.status_operacao,
      'confirmado', o.confirmado,
      'confirmado_por', o.confirmado_por,
      'confirmado_em', o.confirmado_em,
      'cancelado_por', o.cancelado_por,
      'cancelado_em', o.cancelado_em,
      'motivo_cancelamento', o.motivo_cancelamento,
      'visivel_cliente', o.visivel_cliente,
      'checksum_operacao', o.checksum_operacao,
      'updated_at', o.updated_at,
      'full', to_jsonb(o),
      'immutable_hash', md5((to_jsonb(o) - 'status_operacao' - 'confirmado' - 'confirmado_por' - 'confirmado_em' - 'cancelado_por' - 'cancelado_em' - 'motivo_cancelamento' - 'updated_at' - 'metadata')::text)
    ) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12e.snapshot_after_5c', coalesce((select payload::text from snapshot_after_5c), 'null'), true);

with dados as (
  select
    current_setting('app.mc12e.snapshot_before_5c', true)::jsonb as before_5c,
    current_setting('app.mc12e.snapshot_after_5c', true)::jsonb as after_5c,
    current_setting('app.mc12e.payload_confirmacao_5c', true)::jsonb as confirmacao,
    current_setting('app.mc12e.payload_cancelamento_5c', true)::jsonb as cancelamento,
    (current_setting('app.mc12e.payload_op_confirmar_5b', true)::jsonb->'operacao'->>'id') as op_confirmar_id,
    (current_setting('app.mc12e.payload_op_cancelar_5b', true)::jsonb->'operacao'->>'id') as op_cancelar_id
),
pareado as (
  select
    b.value as antes,
    a.value as depois
  from dados d
  cross join lateral jsonb_array_elements(d.before_5c->'operacoes_lista') b(value)
  join lateral jsonb_array_elements(d.after_5c->'operacoes_lista') a(value)
    on a.value->>'id' = b.value->>'id'
),
checks as (
  select
    count(*) as qtd_pareada,
    bool_and(antes->>'immutable_hash' = depois->>'immutable_hash') as immutable_hash_preservado,
    bool_and(antes->>'checksum_operacao' = depois->>'checksum_operacao') as checksum_preservado,
    bool_and(antes->>'visivel_cliente' = depois->>'visivel_cliente') as visibilidade_preservada,
    jsonb_agg(jsonb_build_object(
      'id', antes->>'id',
      'status_antes', antes->>'status_operacao',
      'status_depois', depois->>'status_operacao',
      'immutable_hash_antes', antes->>'immutable_hash',
      'immutable_hash_depois', depois->>'immutable_hash',
      'checksum_antes', antes->>'checksum_operacao',
      'checksum_depois', depois->>'checksum_operacao',
      'visivel_cliente_antes', antes->>'visivel_cliente',
      'visivel_cliente_depois', depois->>'visivel_cliente'
    ) order by antes->>'id') as comparativo
  from pareado
)
select bloco, status, detalhe
from (
  select
    '01_transicoes_5c_ok' as bloco,
    case
      when confirmacao->>'ok' = 'true'
       and confirmacao->>'acao' = 'confirmar'
       and confirmacao->>'idempotente' = 'false'
       and confirmacao->'operacao'->>'status_operacao' = 'confirmada'
       and confirmacao->'operacao'->>'confirmado' = 'true'
       and confirmacao->'operacao'->>'visivel_cliente' = 'false'
       and cancelamento->>'ok' = 'true'
       and cancelamento->>'acao' = 'cancelar'
       and cancelamento->>'idempotente' = 'false'
       and cancelamento->'operacao'->>'status_operacao' = 'cancelada'
       and cancelamento->'operacao'->>'confirmado' = 'false'
       and cancelamento->'operacao'->>'visivel_cliente' = 'false'
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object('confirmacao', confirmacao, 'cancelamento', cancelamento) as detalhe
  from dados

  union all

  select
    '02_operacoes_campos_imutaveis_preservados',
    case
      when c.qtd_pareada = 2
       and c.immutable_hash_preservado = true
       and c.checksum_preservado = true
       and c.visibilidade_preservada = true
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'qtd_pareada', c.qtd_pareada,
      'immutable_hash_preservado', c.immutable_hash_preservado,
      'checksum_preservado', c.checksum_preservado,
      'visibilidade_preservada', c.visibilidade_preservada,
      'comparativo', c.comparativo
    )
  from checks c

  union all

  select
    '03_status_auditoria_mudaram_somente_como_esperado',
    case
      when exists (
        select 1 from pareado p, dados d
        where p.antes->>'id' = d.op_confirmar_id
          and p.antes->>'status_operacao' = 'simulada'
          and p.depois->>'status_operacao' = 'confirmada'
          and p.antes->>'confirmado' = 'false'
          and p.depois->>'confirmado' = 'true'
          and p.antes->>'confirmado_por' is null
          and p.depois->>'confirmado_por' is not null
          and p.antes->>'confirmado_em' is null
          and p.depois->>'confirmado_em' is not null
          and p.antes->>'cancelado_por' is null
          and p.depois->>'cancelado_por' is null
          and p.antes->>'cancelado_em' is null
          and p.depois->>'cancelado_em' is null
          and p.antes->>'motivo_cancelamento' is null
          and p.depois->>'motivo_cancelamento' is null
      )
      and exists (
        select 1 from pareado p, dados d
        where p.antes->>'id' = d.op_cancelar_id
          and p.antes->>'status_operacao' = 'simulada'
          and p.depois->>'status_operacao' = 'cancelada'
          and p.antes->>'confirmado' = 'false'
          and p.depois->>'confirmado' = 'false'
          and p.antes->>'confirmado_por' is null
          and p.depois->>'confirmado_por' is null
          and p.antes->>'confirmado_em' is null
          and p.depois->>'confirmado_em' is null
          and p.antes->>'cancelado_por' is null
          and p.depois->>'cancelado_por' is not null
          and p.antes->>'cancelado_em' is null
          and p.depois->>'cancelado_em' is not null
          and p.antes->>'motivo_cancelamento' is null
          and p.depois->>'motivo_cancelamento' = 'Cancelamento 12E para zero mutação rígido'
      )
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('before', before_5c->'operacoes_lista', 'after', after_5c->'operacoes_lista')
  from dados

  union all

  select
    '04_agenda_nao_mutada',
    case
      when before_5c->>'agenda_id' = after_5c->>'agenda_id'
       and before_5c->>'agenda_checksum' = after_5c->>'agenda_checksum'
       and before_5c->'agenda_tots' = after_5c->'agenda_tots'
       and before_5c->>'agenda_full_hash' = after_5c->>'agenda_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_before', before_5c->>'agenda_id',
      'agenda_id_after', after_5c->>'agenda_id',
      'checksum_before', before_5c->>'agenda_checksum',
      'checksum_after', after_5c->>'agenda_checksum',
      'agenda_full_hash_before', before_5c->>'agenda_full_hash',
      'agenda_full_hash_after', after_5c->>'agenda_full_hash'
    )
  from dados

  union all

  select
    '05_parcelas_nao_mutadas',
    case
      when before_5c->>'parcelas' = after_5c->>'parcelas'
       and before_5c->>'valor_total_parcelas' = after_5c->>'valor_total_parcelas'
       and before_5c->>'parcelas_ids' = after_5c->>'parcelas_ids'
       and before_5c->>'parcelas_full_hash' = after_5c->>'parcelas_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'parcelas_before', before_5c->>'parcelas',
      'parcelas_after', after_5c->>'parcelas',
      'valor_total_parcelas_before', before_5c->>'valor_total_parcelas',
      'valor_total_parcelas_after', after_5c->>'valor_total_parcelas',
      'parcelas_ids_before', before_5c->>'parcelas_ids',
      'parcelas_ids_after', after_5c->>'parcelas_ids',
      'parcelas_full_hash_before', before_5c->>'parcelas_full_hash',
      'parcelas_full_hash_after', after_5c->>'parcelas_full_hash'
    )
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 12E encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
