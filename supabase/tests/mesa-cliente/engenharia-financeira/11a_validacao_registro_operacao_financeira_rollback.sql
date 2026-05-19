-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5B
-- 11A — Validação positiva da RPC de registro de operação financeira.
--
-- Pré-requisito:
--   Aplicar a migration:
--   supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, registrar uma operação via 5B e validar:
--     - RPC 5B retorna contrato administrativo correto;
--     - persiste exatamente 1 operação financeira simulada;
--     - operação fica cliente_safe=false / visivel_cliente=false;
--     - operação não confirma automaticamente;
--     - operação possui agenda_id e checksum_operacao;
--     - agenda e parcelas não são mutadas pela 5B;
--     - rollback final.

begin;

select set_config('app.mc11a.user_id', '', true);
select set_config('app.mc11a.simulacao_id', '', true);
select set_config('app.mc11a.empresa_id', '', true);
select set_config('app.mc11a.empreendimento_id', '', true);
select set_config('app.mc11a.politica_id', '', true);
select set_config('app.mc11a.agenda_id', '', true);
select set_config('app.mc11a.parcela_id', '', true);
select set_config('app.mc11a.payload_4b', 'null', true);
select set_config('app.mc11a.payload_5b', 'null', true);
select set_config('app.mc11a.agenda_before', 'null', true);
select set_config('app.mc11a.agenda_after', 'null', true);

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
    case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 else 4 end,
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
    'Teste rollback 11A registro operação financeira 5B',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object('origem', 'teste_11a_5b_rollback', 'fixture_transacional', true),
    'Fixture transacional 11A. Deve sumir no ROLLBACK.'
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
    'Fixture 11A para validação positiva da RPC 5B.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 11A — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 11A — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 11A — sem prêmio', 3),
      (6.01::numeric, 999.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 11A — acima do limite operacional', 4)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc11a.user_id', c.user_id::text, true),
    set_config('app.mc11a.simulacao_id', s.id::text, true),
    set_config('app.mc11a.empresa_id', s.empresa_id::text, true),
    set_config('app.mc11a.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc11a.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_11a' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc11a.simulacao_id', true),
    'politica_id', current_setting('app.mc11a.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc11a.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11a.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc11a.empreendimento_id', true)::uuid as empreendimento_id
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
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_11a')
  ) as payload
  from ctx
)
select set_config('app.mc11a.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc11a.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.id, a.checksum, a.totais, a.metadata, a.updated_at
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
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id)
  ) as payload
),
setups as (
  select
    set_config('app.mc11a.agenda_id', (select id::text from agenda), true),
    set_config('app.mc11a.parcela_id', (select id::text from parcela), true),
    set_config('app.mc11a.agenda_before', (select payload::text from snapshot_before), true)
)
select
  '00b_agenda_parcela_fixture_11a' as bloco,
  case
    when current_setting('app.mc11a.agenda_id', true) <> ''
     and current_setting('app.mc11a.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc11a.agenda_id', true),
    'parcela_id', current_setting('app.mc11a.parcela_id', true),
    'before', current_setting('app.mc11a.agenda_before', true)::jsonb
  ) as detalhe
from setups;

set local role authenticated;

with chamada_5b as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11a.simulacao_id', true)::uuid,
    current_setting('app.mc11a.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11a.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    5000.00,
    jsonb_build_object('origem_teste', '11a', 'observacao', 'registro positivo rollback')
  ) as payload
)
select set_config('app.mc11a.payload_5b', coalesce((select payload::text from chamada_5b), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc11a.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11a.agenda_id', true)::uuid as agenda_id,
    current_setting('app.mc11a.parcela_id', true)::uuid as parcela_id
),
payload as (
  select current_setting('app.mc11a.payload_5b', true)::jsonb as p
),
operacao as (
  select o.*
  from public.mesa_cliente_fluxo_operacoes o
  join ctx on ctx.simulacao_id = o.simulacao_id
  where o.agenda_id = ctx.agenda_id
    and o.parcela_origem_id = ctx.parcela_id
  order by o.created_at desc, o.id desc
  limit 1
),
snapshot_after as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select a.checksum from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_tots', (select a.totais from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_updated_at', (select a.updated_at from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id),
    'operacao_id', (select id from operacao),
    'checksum_operacao', (select checksum_operacao from operacao)
  ) as payload
  from ctx
),
store_after as (
  select set_config('app.mc11a.agenda_after', (select payload::text from snapshot_after), true)
),
comparativo as (
  select
    current_setting('app.mc11a.agenda_before', true)::jsonb as b,
    current_setting('app.mc11a.agenda_after', true)::jsonb as a,
    (select p from payload) as p
  from store_after
)
select
  bloco,
  status,
  detalhe
from (
  select
    '01_retorno_basico_5b' as bloco,
    case
      when p->>'ok' = 'true'
       and p->>'fase' = '5B_REGISTRO_OPERACAO_FINANCEIRA'
       and p->>'visao' = 'administrativa'
       and p->>'cliente_safe' = 'false'
       and p->>'persistencia' = 'true'
       and p->>'dml_financeiro' = 'true'
       and p->>'escopo_dml' = 'operacao_financeira'
       and p->>'altera_agenda' = 'false'
       and p->>'altera_parcelas' = 'false'
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object(
      'fase', p->>'fase',
      'visao', p->>'visao',
      'cliente_safe', p->>'cliente_safe',
      'persistencia', p->>'persistencia',
      'dml_financeiro', p->>'dml_financeiro',
      'escopo_dml', p->>'escopo_dml',
      'altera_agenda', p->>'altera_agenda',
      'altera_parcelas', p->>'altera_parcelas'
    ) as detalhe
  from comparativo

  union all

  select
    '02_operacao_registrada_simulada',
    case
      when p->'operacao'->>'id' is not null
       and p->'operacao'->>'status_operacao' = 'simulada'
       and p->'operacao'->>'confirmado' = 'false'
       and p->'operacao'->>'visivel_cliente' = 'false'
       and p->'operacao'->>'tipo_operacao' = 'antecipacao'
       and p->'operacao'->>'agenda_id' = current_setting('app.mc11a.agenda_id', true)
       and p->'operacao'->>'parcela_origem_id' = current_setting('app.mc11a.parcela_id', true)
       and coalesce(p->'operacao'->>'checksum_operacao', '') <> ''
    then 'PASS' else 'FAIL' end,
    p->'operacao'
  from comparativo

  union all

  select
    '03_contagem_operacoes_incrementou_uma',
    case
      when (b->>'operacoes')::integer = 0
       and (a->>'operacoes')::integer = 1
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('before', b, 'after', a)
  from comparativo

  union all

  select
    '04_agenda_parcelas_nao_mutadas',
    case
      when b->>'agenda_id' = a->>'agenda_id'
       and b->>'agenda_checksum' = a->>'agenda_checksum'
       and b->'agenda_tots' = a->'agenda_tots'
       and b->>'parcelas' = a->>'parcelas'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_before', b->>'agenda_id',
      'agenda_id_after', a->>'agenda_id',
      'checksum_before', b->>'agenda_checksum',
      'checksum_after', a->>'agenda_checksum',
      'totais_iguais', b->'agenda_tots' = a->'agenda_tots',
      'parcelas_before', b->>'parcelas',
      'parcelas_after', a->>'parcelas'
    )
  from comparativo

  union all

  select
    '05_calculo_e_politica_presentes',
    case
      when (p->'calculo'->>'valor_calculado')::numeric > 0
       and (p->'calculo'->>'impacto_pct')::numeric >= 0
       and p->'politica'->>'metodo_calculo' = 'composto'
       and p->'politica'->>'base_tempo' = 'dias_365'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('calculo', p->'calculo', 'politica', p->'politica')
  from comparativo

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 11A encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
