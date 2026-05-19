-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5A.1
-- 10A — Validação positiva da RPC agenda-first de simulação de impacto.
--
-- Pré-requisito:
--   Aplicar a migration:
--   supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, chamar RPC 5A.1 e validar:
--     - cliente_safe=false;
--     - persistencia=false;
--     - dml_financeiro=false;
--     - geração de alternativas;
--     - recomendação administrativa;
--     - zero operação financeira criada;
--     - rollback final.

begin;

select set_config('app.mc10a.user_id', '', true);
select set_config('app.mc10a.simulacao_id', '', true);
select set_config('app.mc10a.empresa_id', '', true);
select set_config('app.mc10a.empreendimento_id', '', true);
select set_config('app.mc10a.politica_id', '', true);
select set_config('app.mc10a.payload_4b', 'null', true);
select set_config('app.mc10a.payload_5a', 'null', true);

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
    'Teste rollback 10A simulacao impacto 5A',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object('origem', 'teste_10a_5a_rollback', 'fixture_transacional', true),
    'Fixture transacional 10A. Deve sumir no ROLLBACK.'
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
    'Fixture 10A para validação positiva da RPC 5A.1.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 10A — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 10A — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 10A — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc10a.user_id', c.user_id::text, true),
    set_config('app.mc10a.simulacao_id', s.id::text, true),
    set_config('app.mc10a.empresa_id', s.empresa_id::text, true),
    set_config('app.mc10a.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc10a.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_10a' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc10a.simulacao_id', true),
    'politica_id', current_setting('app.mc10a.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc10a.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc10a.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc10a.empreendimento_id', true)::uuid as empreendimento_id
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
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_10a')
  ) as payload
  from ctx
),
chamada_5a as (
  select public.mesa_cliente_simular_impacto_agenda_persistida_admin(
    (select simulacao_id from ctx),
    date '2099-05-31',
    'melhor_aplicacao',
    jsonb_build_object('valor_disponivel', 5000, 'vpl_aplicado_pct', 3.5)
  ) as payload
)
select set_config('app.mc10a.payload_4b', (select payload::text from chamada_4b), true);
select set_config('app.mc10a.payload_5a', (select payload::text from chamada_5a), true);

reset role;

with payload as (
  select current_setting('app.mc10a.payload_5a', true)::jsonb as p
),
ctx as (
  select current_setting('app.mc10a.simulacao_id', true)::uuid as simulacao_id
),
counts as (
  select
    (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id) as total_operacoes,
    (select count(*) from public.mesa_cliente_fluxo_parcelas fp join ctx on ctx.simulacao_id = fp.simulacao_id) as total_parcelas
)
select
  bloco,
  status,
  detalhe
from (
  select
    '01_retorno_basico_5a' as bloco,
    case
      when p->>'ok' = 'true'
       and p->>'fase' = '5A_SIMULACAO_IMPACTO_AGENDA_PERSISTIDA'
       and p->>'visao' = 'administrativa'
       and p->>'cliente_safe' = 'false'
       and p->>'persistencia' = 'false'
       and p->>'dml_financeiro' = 'false'
      then 'PASS' else 'FAIL'
    end as status,
    jsonb_build_object(
      'fase', p->>'fase',
      'visao', p->>'visao',
      'cliente_safe', p->>'cliente_safe',
      'persistencia', p->>'persistencia',
      'dml_financeiro', p->>'dml_financeiro'
    ) as detalhe
  from payload

  union all

  select
    '02_alternativas_e_recomendacao',
    case
      when jsonb_array_length(p->'alternativas') > 0
       and coalesce(p->'recomendacao'->>'tipo_operacao', '') <> ''
       and (p->'resumo'->>'qtd_alternativas')::integer = jsonb_array_length(p->'alternativas')
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'qtd_alternativas', p->'resumo'->>'qtd_alternativas',
      'melhor_tipo_operacao', p->'resumo'->>'melhor_tipo_operacao',
      'recomendacao', p->'recomendacao'
    )
  from payload

  union all

  select
    '03_politica_usada',
    case
      when p->'politica'->>'metodo_calculo' = 'composto'
       and p->'politica'->>'base_tempo' = 'dias_365'
      then 'PASS' else 'FAIL'
    end,
    p->'politica'
  from payload

  union all

  select
    '04_zero_operacoes_financeiras',
    case when total_operacoes = 0 then 'PASS' else 'FAIL' end,
    jsonb_build_object('total_operacoes', total_operacoes, 'total_parcelas_fixture', total_parcelas)
  from counts

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 10A encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
