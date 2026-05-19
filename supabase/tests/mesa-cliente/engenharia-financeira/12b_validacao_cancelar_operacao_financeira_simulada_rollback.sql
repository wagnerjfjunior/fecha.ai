-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- 12B — Validação positiva de cancelamento de operação financeira simulada.
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, registrar operação via 5B,
--   cancelar via RPC 5C e validar:
--     - operação simulada vira cancelada;
--     - confirmado permanece false;
--     - cancelado_por, cancelado_em e motivo_cancelamento são preenchidos;
--     - confirmado_por/confirmado_em permanecem nulos;
--     - visivel_cliente permanece false;
--     - resposta declara não alterar agenda/parcelas e não recalcular operação;
--     - agenda e parcelas não são mutadas;
--     - rollback final.

begin;

select set_config('app.mc12b.user_id', '', true);
select set_config('app.mc12b.simulacao_id', '', true);
select set_config('app.mc12b.empresa_id', '', true);
select set_config('app.mc12b.empreendimento_id', '', true);
select set_config('app.mc12b.politica_id', '', true);
select set_config('app.mc12b.agenda_id', '', true);
select set_config('app.mc12b.parcela_id', '', true);
select set_config('app.mc12b.payload_5b', 'null', true);
select set_config('app.mc12b.payload_5c_cancelamento', 'null', true);
select set_config('app.mc12b.snapshot_before_5b', 'null', true);
select set_config('app.mc12b.snapshot_after_5b', 'null', true);
select set_config('app.mc12b.snapshot_after_5c', 'null', true);
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
    'Teste rollback 12B cancelamento operação financeira 5C',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object('origem', 'teste_12b_5c_rollback', 'fixture_transacional', true),
    'Fixture transacional 12B. Deve sumir no ROLLBACK.'
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
    'Fixture 12B para validação positiva de cancelamento pela RPC 5C.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 12B — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 12B — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 12B — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc12b.user_id', c.user_id::text, true),
    set_config('app.mc12b.simulacao_id', s.id::text, true),
    set_config('app.mc12b.empresa_id', s.empresa_id::text, true),
    set_config('app.mc12b.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc12b.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_12b' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc12b.simulacao_id', true),
    'politica_id', current_setting('app.mc12b.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc12b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12b.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc12b.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-06-30',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-06-30'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',3,'mes_ano','07/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','08/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_12b')
  ) as payload
  from ctx
)
select set_config('app.mc12b.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc12b.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcela as (
  select fp.id
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > date '2099-06-30'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
  order by fp.valor_atual desc, fp.data_atual desc, fp.id
  limit 1
),
snapshot_before_5b as (
  select jsonb_build_object(
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id)
  ) as payload
),
setups as (
  select
    set_config('app.mc12b.agenda_id', (select id::text from agenda), true),
    set_config('app.mc12b.parcela_id', (select id::text from parcela), true),
    set_config('app.mc12b.snapshot_before_5b', (select payload::text from snapshot_before_5b), true)
)
select
  '00b_agenda_parcela_fixture_12b' as bloco,
  case
    when current_setting('app.mc12b.agenda_id', true) <> ''
     and current_setting('app.mc12b.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc12b.agenda_id', true),
    'parcela_id', current_setting('app.mc12b.parcela_id', true),
    'before_5b', current_setting('app.mc12b.snapshot_before_5b', true)::jsonb
  ) as detalhe
from setups;

set local role authenticated;

with chamada_5b as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12b.simulacao_id', true)::uuid,
    current_setting('app.mc12b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12b.parcela_id', true)::uuid,
    date '2099-06-30',
    null,
    5000.00,
    jsonb_build_object('origem_teste', '12b', 'observacao', 'operacao simulada para cancelamento 5C')
  ) as payload
)
select set_config('app.mc12b.payload_5b', coalesce((select payload::text from chamada_5b), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc12b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12b.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after_5b as (
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
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12b.snapshot_after_5b', coalesce((select payload::text from snapshot_after_5b), 'null'), true);

set local role authenticated;

with chamada_5c as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12b.payload_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Cancelamento transacional positivo do teste 12B',
    jsonb_build_object('origem_teste', '12b', 'observacao', 'cancelamento positivo 5C')
  ) as payload
)
select set_config('app.mc12b.payload_5c_cancelamento', coalesce((select payload::text from chamada_5c), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc12b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12b.agenda_id', true)::uuid as agenda_id
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
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_canceladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object(
      'id', o.id,
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
      'metadata_5c', o.metadata->'fase_5c'
    ) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12b.snapshot_after_5c', coalesce((select payload::text from snapshot_after_5c), 'null'), true);

with dados as (
  select
    current_setting('app.mc12b.snapshot_before_5b', true)::jsonb as b,
    current_setting('app.mc12b.snapshot_after_5b', true)::jsonb as s5b,
    current_setting('app.mc12b.snapshot_after_5c', true)::jsonb as s5c,
    current_setting('app.mc12b.payload_5b', true)::jsonb as p5b,
    current_setting('app.mc12b.payload_5c_cancelamento', true)::jsonb as p5c,
    current_setting('app.mc12b.user_id', true) as user_id
)
select bloco, status, detalhe
from (
  select
    '01_operacao_5b_criada_simulada' as bloco,
    case
      when p5b->>'ok' = 'true'
       and p5b->>'fase' = '5B_REGISTRO_OPERACAO_FINANCEIRA'
       and p5b->>'idempotente' = 'false'
       and p5b->'operacao'->>'status_operacao' = 'simulada'
       and p5b->'operacao'->>'confirmado' = 'false'
       and p5b->'operacao'->>'visivel_cliente' = 'false'
       and (s5b->>'operacoes')::integer = 1
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object('payload_5b', p5b, 'snapshot_after_5b', s5b) as detalhe
  from dados

  union all

  select
    '02_cancelamento_5c_retorno_canonico',
    case
      when p5c->>'ok' = 'true'
       and p5c->>'fase' = '5C_CONFIRMACAO_CANCELAMENTO_OPERACAO_FINANCEIRA'
       and p5c->>'acao' = 'cancelar'
       and p5c->>'cliente_safe' = 'false'
       and p5c->>'persistencia' = 'true'
       and p5c->>'dml_financeiro' = 'true'
       and p5c->>'escopo_dml' = 'status_operacao_financeira'
       and p5c->>'altera_agenda' = 'false'
       and p5c->>'altera_parcelas' = 'false'
       and p5c->>'recalcula_operacao' = 'false'
       and p5c->>'idempotente' = 'false'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('payload_5c_flags', p5c - 'operacao')
  from dados

  union all

  select
    '03_operacao_cancelada_campos_auditoria',
    case
      when p5c->'operacao'->>'id' = p5b->'operacao'->>'id'
       and p5c->'operacao'->>'status_operacao_anterior' = 'simulada'
       and p5c->'operacao'->>'status_operacao' = 'cancelada'
       and p5c->'operacao'->>'confirmado' = 'false'
       and p5c->'operacao'->>'confirmado_por' is null
       and p5c->'operacao'->>'confirmado_em' is null
       and p5c->'operacao'->>'cancelado_por' = user_id
       and p5c->'operacao'->>'cancelado_em' is not null
       and p5c->'operacao'->>'motivo_cancelamento' = 'Cancelamento transacional positivo do teste 12B'
       and p5c->'operacao'->>'visivel_cliente' = 'false'
       and p5c->'operacao'->>'checksum_operacao' = p5b->'operacao'->>'checksum_operacao'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('operacao_5b', p5b->'operacao', 'operacao_5c', p5c->'operacao', 'user_id_esperado', user_id)
  from dados

  union all

  select
    '04_estado_banco_cancelado_sem_exposicao_cliente',
    case
      when (s5c->>'operacoes')::integer = 1
       and (s5c->>'operacoes_confirmadas')::integer = 0
       and (s5c->>'operacoes_canceladas')::integer = 1
       and (s5c->>'operacoes_visiveis_cliente')::integer = 0
       and s5c->'operacoes_lista'->0->>'id' = p5b->'operacao'->>'id'
       and s5c->'operacoes_lista'->0->>'status_operacao' = 'cancelada'
       and s5c->'operacoes_lista'->0->>'confirmado' = 'false'
       and s5c->'operacoes_lista'->0->>'confirmado_por' is null
       and s5c->'operacoes_lista'->0->>'confirmado_em' is null
       and s5c->'operacoes_lista'->0->>'cancelado_por' = user_id
       and s5c->'operacoes_lista'->0->>'cancelado_em' is not null
       and s5c->'operacoes_lista'->0->>'motivo_cancelamento' = 'Cancelamento transacional positivo do teste 12B'
       and s5c->'operacoes_lista'->0->>'visivel_cliente' = 'false'
       and s5c->'operacoes_lista'->0->'metadata_5c'->>'acao' = 'cancelar'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('snapshot_after_5c', s5c)
  from dados

  union all

  select
    '05_agenda_parcelas_nao_mutadas',
    case
      when b->>'agenda_id' = s5c->>'agenda_id'
       and b->>'agenda_checksum' = s5c->>'agenda_checksum'
       and b->'agenda_tots' = s5c->'agenda_tots'
       and b->>'agenda_full_hash' = s5c->>'agenda_full_hash'
       and b->>'parcelas' = s5c->>'parcelas'
       and b->>'valor_total_parcelas' = s5c->>'valor_total_parcelas'
       and b->>'parcelas_ids' = s5c->>'parcelas_ids'
       and b->>'parcelas_full_hash' = s5c->>'parcelas_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_before', b->>'agenda_id',
      'agenda_id_after', s5c->>'agenda_id',
      'checksum_before', b->>'agenda_checksum',
      'checksum_after', s5c->>'agenda_checksum',
      'agenda_full_hash_before', b->>'agenda_full_hash',
      'agenda_full_hash_after', s5c->>'agenda_full_hash',
      'parcelas_ids_before', b->>'parcelas_ids',
      'parcelas_ids_after', s5c->>'parcelas_ids',
      'parcelas_full_hash_before', b->>'parcelas_full_hash',
      'parcelas_full_hash_after', s5c->>'parcelas_full_hash'
    )
  from dados

  union all

  select
    '06_updated_at_operacao_setado_explicitamente',
    case
      when p5c->'operacao'->>'updated_at' is not null
       and s5c->'operacoes_lista'->0->>'updated_at' = p5c->'operacao'->>'updated_at'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('updated_at_retorno', p5c->'operacao'->>'updated_at', 'updated_at_banco', s5c->'operacoes_lista'->0->>'updated_at')
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 12B encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
