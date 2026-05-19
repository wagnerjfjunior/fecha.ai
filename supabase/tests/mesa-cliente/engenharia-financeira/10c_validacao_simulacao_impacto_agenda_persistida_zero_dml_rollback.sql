-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5A.1
-- 10C — Validação de zero DML financeiro permanente da RPC 5A.1.
--
-- Objetivo:
--   Provar que chamar a RPC 5A.1 não altera agendas, parcelas ou operações.
--   A fixture usa 4B dentro da transação, captura contagens/checksums antes da 5A,
--   chama a 5A e compara depois.

begin;

select set_config('app.mc10c.user_id', '', true);
select set_config('app.mc10c.simulacao_id', '', true);
select set_config('app.mc10c.empresa_id', '', true);
select set_config('app.mc10c.empreendimento_id', '', true);
select set_config('app.mc10c.payload_4b', 'null', true);
select set_config('app.mc10c.payload_5a', 'null', true);
select set_config('app.mc10c.counts_before', 'null', true);
select set_config('app.mc10c.counts_after', 'null', true);

with candidato as materialized (
  select c.user_id, c.id as corretor_id, c.empresa_id, c.role, e.id as empreendimento_id
  from public.corretores c
  join public.empreendimentos e on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 else 4 end,
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
  select empresa_id, corretor_id, empreendimento_id, 'Teste rollback 10C zero DML 5A', 29500.50, 10000.50, 0, 29500.50, jsonb_build_object('origem','teste_10c'), 'Fixture 10C.'
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
  select empresa_id, empreendimento_id, date '2099-05-01', date '2099-01-01', date '2099-12-31', 6.00, 12.00, 12.00,
         'composto'::public.mesa_financeira_metodo_calculo,
         'dias_365'::public.mesa_financeira_base_tempo,
         true,true,true,true,true,true,true,true,true,true,true,true,
         true,
         'Fixture 10C para zero DML da RPC 5A.1.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 10C — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 10C — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 10C — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc10c.user_id', c.user_id::text, true),
    set_config('app.mc10c.simulacao_id', s.id::text, true),
    set_config('app.mc10c.empresa_id', s.empresa_id::text, true),
    set_config('app.mc10c.empreendimento_id', s.empreendimento_id::text, true)
  from candidato c
  join simulacao s on true
)
select
  '00_setup_fixture_10c' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object('simulacao_id', current_setting('app.mc10c.simulacao_id', true), 'qtd_faixas', (select count(*) from faixas)) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select current_setting('app.mc10c.simulacao_id', true)::uuid as simulacao_id,
         current_setting('app.mc10c.empresa_id', true)::uuid as empresa_id,
         current_setting('app.mc10c.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-05-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-05-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',3,'mes_ano','06/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','07/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_10c')
  ) as payload
  from ctx
)
select set_config('app.mc10c.payload_4b', (select payload::text from chamada_4b), true);

reset role;

with ctx as (
  select current_setting('app.mc10c.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.id, a.checksum, a.totais, a.metadata, a.updated_at
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last
  limit 1
),
counts_before as (
  select jsonb_build_object(
    'agendas', (select count(*) from public.mesa_cliente_agendas_financeiras a join ctx on ctx.simulacao_id = a.simulacao_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas p join ctx on ctx.simulacao_id = p.simulacao_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id),
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda)
  ) as payload
)
select set_config('app.mc10c.counts_before', (select payload::text from counts_before), true);

set local role authenticated;

with ctx as (
  select current_setting('app.mc10c.simulacao_id', true)::uuid as simulacao_id
),
chamada_5a as (
  select public.mesa_cliente_simular_impacto_agenda_persistida_admin(
    ctx.simulacao_id,
    date '2099-05-31',
    'comparativo',
    jsonb_build_object('valor_disponivel', 5000, 'valor_movido', 3000, 'data_destino', '2100-01-31', 'vpl_aplicado_pct', 3.5)
  ) as payload
  from ctx
)
select set_config('app.mc10c.payload_5a', (select payload::text from chamada_5a), true);

reset role;

with ctx as (
  select current_setting('app.mc10c.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.id, a.checksum, a.totais, a.metadata, a.updated_at
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last
  limit 1
),
counts_after as (
  select jsonb_build_object(
    'agendas', (select count(*) from public.mesa_cliente_agendas_financeiras a join ctx on ctx.simulacao_id = a.simulacao_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas p join ctx on ctx.simulacao_id = p.simulacao_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id),
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda)
  ) as payload
)
select set_config('app.mc10c.counts_after', (select payload::text from counts_after), true);

with before_after as (
  select
    current_setting('app.mc10c.counts_before', true)::jsonb as b,
    current_setting('app.mc10c.counts_after', true)::jsonb as a,
    current_setting('app.mc10c.payload_5a', true)::jsonb as p5a
)
select
  bloco,
  status,
  detalhe
from (
  select
    '01_retorno_5a_zero_dml_flags' as bloco,
    case when p5a->>'ok' = 'true' and p5a->>'persistencia' = 'false' and p5a->>'dml_financeiro' = 'false' then 'PASS' else 'FAIL' end as status,
    jsonb_build_object('fase', p5a->>'fase', 'persistencia', p5a->>'persistencia', 'dml_financeiro', p5a->>'dml_financeiro') as detalhe
  from before_after

  union all

  select
    '02_contagens_inalteradas',
    case
      when b->>'agendas' = a->>'agendas'
       and b->>'parcelas' = a->>'parcelas'
       and b->>'operacoes' = a->>'operacoes'
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object('before', b, 'after', a)
  from before_after

  union all

  select
    '03_agenda_checksum_totais_inalterados',
    case
      when b->>'agenda_id' = a->>'agenda_id'
       and b->>'agenda_checksum' = a->>'agenda_checksum'
       and b->'agenda_tots' = a->'agenda_tots'
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'agenda_id_before', b->>'agenda_id',
      'agenda_id_after', a->>'agenda_id',
      'checksum_before', b->>'agenda_checksum',
      'checksum_after', a->>'agenda_checksum',
      'totais_iguais', b->'agenda_tots' = a->'agenda_tots'
    )
  from before_after

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 10C encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
