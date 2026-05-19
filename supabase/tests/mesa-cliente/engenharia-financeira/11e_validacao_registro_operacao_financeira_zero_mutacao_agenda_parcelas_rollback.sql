-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5B
-- 11E — Validação rígida de zero mutação em agenda e parcelas pela RPC 5B.
--
-- Pré-requisito:
--   Migration 5B aplicada:
--   supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, registrar operação via 5B
--   e validar de forma rígida:
--     - a RPC 5B altera somente public.mesa_cliente_fluxo_operacoes;
--     - não altera linha da agenda financeira;
--     - não altera, recria ou remove parcelas;
--     - não altera checksum/totais/updated_at da agenda;
--     - não altera valor total das parcelas;
--     - cria exatamente 1 operação financeira simulada;
--     - operação nasce invisível ao cliente e não confirmada;
--     - rollback final.
--
-- Observação:
--   Não usa temp table. Usa set_config(...) transacional para evitar fragilidade com SET LOCAL ROLE.

begin;

select set_config('app.mc11e.user_id', '', true);
select set_config('app.mc11e.simulacao_id', '', true);
select set_config('app.mc11e.empresa_id', '', true);
select set_config('app.mc11e.empreendimento_id', '', true);
select set_config('app.mc11e.politica_id', '', true);
select set_config('app.mc11e.agenda_id', '', true);
select set_config('app.mc11e.parcela_id', '', true);
select set_config('app.mc11e.payload_4b', 'null', true);
select set_config('app.mc11e.payload_5b', 'null', true);
select set_config('app.mc11e.snapshot_before', 'null', true);
select set_config('app.mc11e.snapshot_after', 'null', true);
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
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_global' then 1
      when c.role = 'admin_local' then 2
      when c.role = 'gestor' then 3
      else 4
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
    'Teste rollback 11E zero mutação agenda parcelas registro 5B',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object('origem', 'teste_11e_5b_rollback', 'fixture_transacional', true),
    'Fixture transacional 11E. Deve sumir no ROLLBACK.'
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
    date '2099-05-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 11E para validação rígida de zero mutação em agenda e parcelas pela RPC 5B.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 11E — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 11E — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 11E — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc11e.user_id', c.user_id::text, true),
    set_config('app.mc11e.simulacao_id', s.id::text, true),
    set_config('app.mc11e.empresa_id', s.empresa_id::text, true),
    set_config('app.mc11e.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc11e.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_11e' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc11e.simulacao_id', true),
    'politica_id', current_setting('app.mc11e.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc11e.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11e.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc11e.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-05-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-05-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',3,'mes_ano','06/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','07/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_11e')
  ) as payload
  from ctx
)
select set_config('app.mc11e.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc11e.simulacao_id', true)::uuid as simulacao_id
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
    and fp.data_atual > date '2099-05-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
  order by fp.valor_atual desc, fp.data_atual desc, fp.id
  limit 1
),
snapshot_before as (
  select jsonb_build_object(
    'simulacao_id', (select simulacao_id from ctx),
    'agenda_id', (select id from agenda),
    'agenda_status', (select status from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'agendas_total_simulacao', (select count(*) from public.mesa_cliente_agendas_financeiras a join ctx on ctx.simulacao_id = a.simulacao_id),
    'agendas_ativas_simulacao', (select count(*) from public.mesa_cliente_agendas_financeiras a join ctx on ctx.simulacao_id = a.simulacao_id where a.status = 'ativa'),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id where o.status_operacao = 'confirmada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id where coalesce(o.visivel_cliente, false) = true)
  ) as payload
),
setups as (
  select
    set_config('app.mc11e.agenda_id', (select id::text from agenda), true),
    set_config('app.mc11e.parcela_id', (select id::text from parcela), true),
    set_config('app.mc11e.snapshot_before', (select payload::text from snapshot_before), true)
)
select
  '00b_agenda_parcela_fixture_11e' as bloco,
  case
    when current_setting('app.mc11e.agenda_id', true) <> ''
     and current_setting('app.mc11e.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc11e.agenda_id', true),
    'parcela_id', current_setting('app.mc11e.parcela_id', true),
    'before', current_setting('app.mc11e.snapshot_before', true)::jsonb
  ) as detalhe
from setups;

set local role authenticated;

with chamada_5b as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11e.simulacao_id', true)::uuid,
    current_setting('app.mc11e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11e.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    5000.00,
    jsonb_build_object('origem_teste', '11e', 'observacao', 'zero mutacao agenda parcelas rollback')
  ) as payload
)
select set_config('app.mc11e.payload_5b', coalesce((select payload::text from chamada_5b), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc11e.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11e.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after as (
  select jsonb_build_object(
    'simulacao_id', (select simulacao_id from ctx),
    'agenda_id', (select id from agenda),
    'agenda_status', (select status from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'agendas_total_simulacao', (select count(*) from public.mesa_cliente_agendas_financeiras a join ctx on ctx.simulacao_id = a.simulacao_id),
    'agendas_ativas_simulacao', (select count(*) from public.mesa_cliente_agendas_financeiras a join ctx on ctx.simulacao_id = a.simulacao_id where a.status = 'ativa'),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join ctx on ctx.agenda_id = fp.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp join ctx on ctx.agenda_id = fp.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp join ctx on ctx.agenda_id = fp.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp join ctx on ctx.agenda_id = fp.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id where o.status_operacao = 'confirmada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id where coalesce(o.visivel_cliente, false) = true),
    'operacoes_lista', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'id', o.id,
            'agenda_id', o.agenda_id,
            'parcela_origem_id', o.parcela_origem_id,
            'parcela_destino_id', o.parcela_destino_id,
            'tipo_operacao', o.tipo_operacao,
            'status_operacao', o.status_operacao,
            'confirmado', o.confirmado,
            'visivel_cliente', o.visivel_cliente,
            'valor_movido', o.valor_movido,
            'valor_base', o.valor_base,
            'checksum_operacao', o.checksum_operacao,
            'criado_por', o.criado_por
          )
          order by o.created_at, o.id
        ),
        '[]'::jsonb
      )
      from public.mesa_cliente_fluxo_operacoes o
      join ctx on ctx.simulacao_id = o.simulacao_id
    )
  ) as payload
  from ctx
)
select set_config('app.mc11e.snapshot_after', coalesce((select payload::text from snapshot_after), 'null'), true);

with dados as (
  select
    current_setting('app.mc11e.snapshot_before', true)::jsonb as b,
    current_setting('app.mc11e.snapshot_after', true)::jsonb as a,
    current_setting('app.mc11e.payload_5b', true)::jsonb as p
)
select
  bloco,
  status,
  detalhe
from (
  select
    '01_retorno_5b_escopo_operacao_financeira' as bloco,
    case
      when p->>'ok' = 'true'
       and p->>'fase' = '5B_REGISTRO_OPERACAO_FINANCEIRA'
       and p->>'cliente_safe' = 'false'
       and p->>'persistencia' = 'true'
       and p->>'dml_financeiro' = 'true'
       and p->>'escopo_dml' = 'operacao_financeira'
       and p->>'altera_agenda' = 'false'
       and p->>'altera_parcelas' = 'false'
       and p->'operacao'->>'status_operacao' = 'simulada'
       and p->'operacao'->>'confirmado' = 'false'
       and p->'operacao'->>'visivel_cliente' = 'false'
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object(
      'fase', p->>'fase',
      'cliente_safe', p->>'cliente_safe',
      'persistencia', p->>'persistencia',
      'dml_financeiro', p->>'dml_financeiro',
      'escopo_dml', p->>'escopo_dml',
      'altera_agenda', p->>'altera_agenda',
      'altera_parcelas', p->>'altera_parcelas',
      'operacao', p->'operacao'
    ) as detalhe
  from dados

  union all

  select
    '02_agenda_nao_mutada_hash_linha_completa',
    case
      when b->>'agenda_id' = a->>'agenda_id'
       and b->>'agenda_status' = a->>'agenda_status'
       and b->>'agenda_checksum' = a->>'agenda_checksum'
       and b->'agenda_tots' = a->'agenda_tots'
       and b->>'agenda_updated_at' = a->>'agenda_updated_at'
       and b->>'agenda_full_hash' = a->>'agenda_full_hash'
       and b->>'agendas_total_simulacao' = a->>'agendas_total_simulacao'
       and b->>'agendas_ativas_simulacao' = a->>'agendas_ativas_simulacao'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_before', b->>'agenda_id',
      'agenda_id_after', a->>'agenda_id',
      'status_before', b->>'agenda_status',
      'status_after', a->>'agenda_status',
      'checksum_before', b->>'agenda_checksum',
      'checksum_after', a->>'agenda_checksum',
      'updated_at_before', b->>'agenda_updated_at',
      'updated_at_after', a->>'agenda_updated_at',
      'full_hash_before', b->>'agenda_full_hash',
      'full_hash_after', a->>'agenda_full_hash',
      'totais_iguais', b->'agenda_tots' = a->'agenda_tots',
      'agendas_total_before', b->>'agendas_total_simulacao',
      'agendas_total_after', a->>'agendas_total_simulacao',
      'agendas_ativas_before', b->>'agendas_ativas_simulacao',
      'agendas_ativas_after', a->>'agendas_ativas_simulacao'
    )
  from dados

  union all

  select
    '03_parcelas_nao_mutadas_hash_linha_completa',
    case
      when b->>'parcelas' = a->>'parcelas'
       and b->'parcelas_ids' = a->'parcelas_ids'
       and b->>'parcelas_full_hash' = a->>'parcelas_full_hash'
       and b->>'valor_total_parcelas' = a->>'valor_total_parcelas'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'parcelas_before', b->>'parcelas',
      'parcelas_after', a->>'parcelas',
      'parcelas_ids_iguais', b->'parcelas_ids' = a->'parcelas_ids',
      'parcelas_full_hash_before', b->>'parcelas_full_hash',
      'parcelas_full_hash_after', a->>'parcelas_full_hash',
      'valor_total_parcelas_before', b->>'valor_total_parcelas',
      'valor_total_parcelas_after', a->>'valor_total_parcelas'
    )
  from dados

  union all

  select
    '04_somente_operacoes_incrementou_uma',
    case
      when (b->>'operacoes')::integer = 0
       and (a->>'operacoes')::integer = 1
       and (a->>'operacoes')::integer - (b->>'operacoes')::integer = 1
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'operacoes_before', b->>'operacoes',
      'operacoes_after', a->>'operacoes',
      'delta_operacoes', (a->>'operacoes')::integer - (b->>'operacoes')::integer,
      'operacoes_lista', a->'operacoes_lista'
    )
  from dados

  union all

  select
    '05_operacao_nasceu_simulada_nao_cliente_safe',
    case
      when (a->>'operacoes_confirmadas')::integer = 0
       and (a->>'operacoes_visiveis_cliente')::integer = 0
       and a->'operacoes_lista'->0->>'id' = p->'operacao'->>'id'
       and a->'operacoes_lista'->0->>'status_operacao' = 'simulada'
       and a->'operacoes_lista'->0->>'confirmado' = 'false'
       and a->'operacoes_lista'->0->>'visivel_cliente' = 'false'
       and a->'operacoes_lista'->0->>'agenda_id' = b->>'agenda_id'
       and a->'operacoes_lista'->0->>'parcela_origem_id' = current_setting('app.mc11e.parcela_id', true)
       and coalesce(a->'operacoes_lista'->0->>'checksum_operacao', '') <> ''
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'operacoes_confirmadas_after', a->>'operacoes_confirmadas',
      'operacoes_visiveis_cliente_after', a->>'operacoes_visiveis_cliente',
      'operacao_banco', a->'operacoes_lista'->0,
      'operacao_retorno', p->'operacao'
    )
  from dados

  union all

  select
    '06_checksum_totais_agenda_preservados',
    case
      when b->>'agenda_checksum' = a->>'agenda_checksum'
       and b->'agenda_tots' = a->'agenda_tots'
       and b->>'valor_total_parcelas' = a->>'valor_total_parcelas'
       and (a->'agenda_tots'->>'valor_total')::numeric = (a->>'valor_total_parcelas')::numeric
       and (a->'agenda_tots'->>'qtd_parcelas')::integer = (a->>'parcelas')::integer
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_checksum_before', b->>'agenda_checksum',
      'agenda_checksum_after', a->>'agenda_checksum',
      'agenda_tots_before', b->'agenda_tots',
      'agenda_tots_after', a->'agenda_tots',
      'valor_total_parcelas_before', b->>'valor_total_parcelas',
      'valor_total_parcelas_after', a->>'valor_total_parcelas'
    )
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 11E encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
