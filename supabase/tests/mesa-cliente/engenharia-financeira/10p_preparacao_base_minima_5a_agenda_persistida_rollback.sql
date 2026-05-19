-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5A.1
-- 10P — Preparação/validação transacional da base mínima para simulação de impacto com agenda persistida.
--
-- Objetivo:
--   Preparar e validar, dentro de BEGIN + ROLLBACK, uma base mínima para a futura 5A.1:
--     - simulação fixture;
--     - política financeira ativa com metodo_calculo=composto e base_tempo=dias_365;
--     - faixas administrativas de prêmio;
--     - agenda ativa persistida via RPC 4B;
--     - parcelas vinculadas à agenda.
--
-- Por que este arquivo existe:
--   O preflight 10 canônico é read-only e confirmou que o schema está saudável,
--   mas o ambiente não possui dados mínimos permanentes para a 5A.1.
--   Como o banco é tratado como produção única, este script NÃO cria seed permanente.
--   Ele prova a base mínima em transação e encerra com ROLLBACK.
--
-- Regras:
--   - Não cria migration.
--   - Não cria RPC 5A.
--   - Não altera frontend/parser/Worker/Make/n8n.
--   - Usa a RPC 4B já aprovada para persistir agenda dentro da transação.
--   - Cria política/agenda/parcelas apenas como fixture transacional.
--   - Termina obrigatoriamente com ROLLBACK.
--
-- Próxima decisão:
--   Se este script retornar PASS nos blocos principais, a próxima etapa segura é
--   criar a migration da RPC 5A.1 com testes 10A/10B/10C transacionais.

begin;

select set_config('app.mc10p.user_id', '', true);
select set_config('app.mc10p.corretor_id', '', true);
select set_config('app.mc10p.empresa_id', '', true);
select set_config('app.mc10p.empreendimento_id', '', true);
select set_config('app.mc10p.empreendimento_nome', '', true);
select set_config('app.mc10p.simulacao_id', '', true);
select set_config('app.mc10p.politica_id', '', true);
select set_config('app.mc10p.role', '', true);
select set_config('app.mc10p.qtd_ctx', '0', true);
select set_config('app.mc10p.qtd_faixas', '0', true);
select set_config('app.mc10p.payload_4b', 'null', true);

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    coalesce(c.ativo, true) as ativo,
    coalesce(c.is_admin_local, false) as is_admin_local,
    coalesce(c.is_gestor, false) as is_gestor,
    e.id as empreendimento_id,
    e.nome as empreendimento_nome
  from public.corretores c
  join public.empreendimentos e
    on e.empresa_id = c.empresa_id
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
      when coalesce(c.is_admin_local, false) then 4
      when coalesce(c.is_gestor, false) then 5
      else 6
    end,
    c.created_at desc nulls last,
    c.id,
    e.nome
  limit 1
),
fixture_simulacao as materialized (
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
    'Teste rollback 10P base minima 5A',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object(
      'origem', 'teste_10p_base_minima_5a_rollback',
      'fixture_transacional', true,
      'fase_alvo', '5A.1'
    ),
    'Fixture transacional do teste 10P. Deve sumir no ROLLBACK.'
  from candidato
  returning id as simulacao_id, empresa_id, corretor_id, empreendimento_id
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
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    'Fixture transacional 10P para validar base mínima da Fase 5A.1. Deve sumir no ROLLBACK.'
  from fixture_simulacao
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
  returning id as politica_id, empresa_id, empreendimento_id
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
  select
    p.empresa_id,
    p.politica_id,
    v.vpl_de_pct,
    v.vpl_ate_pct,
    v.premio_corretor_pct,
    v.status,
    v.descricao,
    v.ordem,
    true
  from politica p
  cross join (
    values
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 10P — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 10P — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 10P — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', coalesce(c.user_id::text, '00000000-0000-0000-0000-000000000000'), true) as set_auth_sub,
    set_config('app.mc10p.user_id', coalesce(c.user_id::text, ''), true) as set_user_id,
    set_config('app.mc10p.corretor_id', coalesce(c.corretor_id::text, ''), true) as set_corretor_id,
    set_config('app.mc10p.empresa_id', coalesce(f.empresa_id::text, ''), true) as set_empresa_id,
    set_config('app.mc10p.empreendimento_id', coalesce(f.empreendimento_id::text, ''), true) as set_empreendimento_id,
    set_config('app.mc10p.empreendimento_nome', coalesce(c.empreendimento_nome::text, ''), true) as set_empreendimento_nome,
    set_config('app.mc10p.simulacao_id', coalesce(f.simulacao_id::text, ''), true) as set_simulacao_id,
    set_config('app.mc10p.politica_id', coalesce(p.politica_id::text, ''), true) as set_politica_id,
    set_config('app.mc10p.role', coalesce(c.role::text, ''), true) as set_role,
    set_config('app.mc10p.qtd_ctx', '1', true) as set_qtd_ctx,
    set_config('app.mc10p.qtd_faixas', coalesce((select count(*)::text from faixas), '0'), true) as set_qtd_faixas
  from candidato c
  join fixture_simulacao f on true
  join politica p on true
)
select
  '00_setup_fixture_transacional_10p' as bloco,
  case when coalesce((select count(*) from setup), 0) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'qtd_setup', coalesce((select count(*) from setup), 0),
    'qtd_ctx', current_setting('app.mc10p.qtd_ctx', true),
    'qtd_faixas', current_setting('app.mc10p.qtd_faixas', true),
    'simulacao_id', nullif(current_setting('app.mc10p.simulacao_id', true), ''),
    'politica_id', nullif(current_setting('app.mc10p.politica_id', true), '')
  ) as detalhe;

select set_config('request.jwt.claim.sub', coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''), '00000000-0000-0000-0000-000000000000'), true);
select set_config('app.mc10p.qtd_ctx', coalesce(nullif(current_setting('app.mc10p.qtd_ctx', true), ''), '0'), true);
select set_config('app.mc10p.qtd_faixas', coalesce(nullif(current_setting('app.mc10p.qtd_faixas', true), ''), '0'), true);

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc10p.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc10p.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc10p.simulacao_id', true), '')::uuid as simulacao_id,
    coalesce(nullif(current_setting('app.mc10p.qtd_ctx', true), '')::integer, 0) as qtd_ctx
),
chamada_4b as materialized (
  select
    case
      when ctx.qtd_ctx = 1 and ctx.simulacao_id is not null then
        public.mesa_cliente_persistir_agenda_financeira_admin(
          ctx.simulacao_id,
          date '2099-05-31',
          jsonb_build_array(
            jsonb_build_object(
              'grupo', 'entrada',
              'descricao', 'Sinal ato',
              'valor', '10000,50',
              'data', '2099-05-31'
            ),
            jsonb_build_object(
              'grupo', 'mensais',
              'descricao', 'Mensais',
              'valor', '2500.00',
              'quantidade', 3,
              'mes_ano', '06/2099'
            ),
            jsonb_build_object(
              'grupo', 'intermediarias',
              'descricao', 'Intermediária anual',
              'valor', '12000',
              'mes_ano', '2099-12'
            ),
            jsonb_build_object(
              'grupo', 'periodicidade',
              'descricao', 'Periodicidade simbólica',
              'valor', 0,
              'mes_ano', '07/2099'
            )
          ),
          jsonb_build_object(
            'empresa_id', ctx.empresa_id,
            'empreendimento_id', ctx.empreendimento_id,
            'origem', 'teste_10p_base_minima_5a'
          )
        )
      else null::jsonb
    end as payload
  from ctx
)
select set_config('app.mc10p.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as materialized (
  select
    nullif(current_setting('app.mc10p.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc10p.corretor_id', true), '')::uuid as corretor_id,
    nullif(current_setting('app.mc10p.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc10p.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc10p.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc10p.politica_id', true), '')::uuid as politica_id,
    nullif(current_setting('app.mc10p.role', true), '') as role,
    nullif(current_setting('app.mc10p.empreendimento_nome', true), '') as empreendimento_nome,
    coalesce(nullif(current_setting('app.mc10p.qtd_ctx', true), '')::integer, 0) as qtd_ctx,
    coalesce(nullif(current_setting('app.mc10p.qtd_faixas', true), '')::integer, 0) as qtd_faixas,
    coalesce(nullif(current_setting('app.mc10p.payload_4b', true), '')::jsonb, 'null'::jsonb) as payload_4b
),
agendas as materialized (
  select
    a.id as agenda_id,
    a.status,
    a.simulacao_id,
    a.empresa_id,
    a.empreendimento_id,
    coalesce((a.totais->>'qtd_parcelas')::integer, 0) as qtd_parcelas_agenda,
    coalesce((a.totais->>'valor_total')::numeric, 0) as valor_total_agenda,
    a.checksum
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc
  limit 1
),
parcelas as materialized (
  select
    count(*)::integer as total_parcelas,
    count(*) filter (where p.agenda_id is not null)::integer as parcelas_com_agenda_id,
    count(*) filter (where coalesce(p.eh_periodicidade_simbolica, false) is false)::integer as parcelas_nao_simbolicas,
    count(*) filter (where coalesce(p.pode_receber_antecipacao, false) is true)::integer as parcelas_podem_antecipacao,
    count(*) filter (where coalesce(p.pode_receber_postergacao, false) is true)::integer as parcelas_podem_postergacao,
    count(*) filter (where coalesce(p.pode_receber_vpl, false) is true)::integer as parcelas_podem_vpl,
    count(*) filter (where coalesce(p.eh_periodicidade_simbolica, false) is true)::integer as parcelas_periodicidade_simbolica,
    coalesce(sum(p.valor_atual), 0)::numeric as valor_total_parcelas
  from public.mesa_cliente_fluxo_parcelas p
  join ctx on ctx.simulacao_id = p.simulacao_id
),
politica as materialized (
  select
    p.id as politica_id,
    p.ativo,
    p.metodo_calculo::text as metodo_calculo,
    p.base_tempo::text as base_tempo,
    p.vigencia_inicio,
    p.vigencia_fim,
    p.vpl_max_pct,
    p.taxa_antecipacao_ano_pct,
    p.taxa_postergacao_ano_pct,
    p.permite_vpl_mensais,
    p.permite_antecipacao_mensais,
    p.permite_postergacao_mensais
  from public.mesa_cliente_politicas_financeiras p
  join ctx on ctx.politica_id = p.id
),
faixas as materialized (
  select count(*)::integer as qtd_faixas_db
  from public.mesa_cliente_politica_premio_faixas f
  join ctx on ctx.politica_id = f.politica_id
),
operacoes as materialized (
  select count(*)::integer as total_operacoes
  from public.mesa_cliente_fluxo_operacoes o
  join ctx on ctx.simulacao_id = o.simulacao_id
),
p as materialized (
  select
    ctx.*,
    (ctx.payload_4b->>'ok')::boolean as ok_4b,
    ctx.payload_4b->>'fase' as fase_4b,
    (ctx.payload_4b->>'persistencia')::boolean as persistencia_4b,
    (ctx.payload_4b->>'dml_financeiro')::boolean as dml_financeiro_4b,
    nullif(ctx.payload_4b->>'agenda_id', '')::uuid as agenda_id_payload,
    a.agenda_id,
    a.status as agenda_status,
    a.qtd_parcelas_agenda,
    a.valor_total_agenda,
    pr.total_parcelas,
    pr.parcelas_com_agenda_id,
    pr.parcelas_nao_simbolicas,
    pr.parcelas_podem_antecipacao,
    pr.parcelas_podem_postergacao,
    pr.parcelas_podem_vpl,
    pr.parcelas_periodicidade_simbolica,
    pr.valor_total_parcelas,
    pol.ativo as politica_ativa,
    pol.metodo_calculo,
    pol.base_tempo,
    pol.vigencia_inicio,
    pol.vigencia_fim,
    pol.vpl_max_pct,
    pol.taxa_antecipacao_ano_pct,
    pol.taxa_postergacao_ano_pct,
    f.qtd_faixas_db,
    o.total_operacoes,
    case
      when pol.ativo is true
       and pol.metodo_calculo = 'composto'
       and pol.base_tempo = 'dias_365'
       and date '2099-05-31' between pol.vigencia_inicio and pol.vigencia_fim
      then true else false
    end as politica_valida_5a,
    case
      when a.agenda_id is not null
       and a.status = 'ativa'
       and pr.total_parcelas > 0
       and pr.parcelas_com_agenda_id = pr.total_parcelas
      then true else false
    end as agenda_valida_5a
  from ctx
  left join agendas a on true
  cross join parcelas pr
  left join politica pol on true
  cross join faixas f
  cross join operacoes o
)
select
  '01_contexto_transacional' as bloco,
  case
    when qtd_ctx = 1
      and user_id is not null
      and corretor_id is not null
      and empresa_id is not null
      and empreendimento_id is not null
      and simulacao_id is not null
      and politica_id is not null
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'user_id', user_id,
    'corretor_id', corretor_id,
    'empresa_id', empresa_id,
    'empreendimento_id', empreendimento_id,
    'empreendimento_nome', empreendimento_nome,
    'simulacao_id', simulacao_id,
    'politica_id', politica_id,
    'role', role,
    'qtd_ctx', qtd_ctx
  ) as detalhe
from p

union all

select
  '02_politica_financeira_ativa_composta_dias_365',
  case when politica_valida_5a then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'politica_id', politica_id,
    'ativo', politica_ativa,
    'metodo_calculo', metodo_calculo,
    'base_tempo', base_tempo,
    'vigencia_inicio', vigencia_inicio,
    'vigencia_fim', vigencia_fim,
    'vpl_max_pct', vpl_max_pct,
    'taxa_antecipacao_ano_pct', taxa_antecipacao_ano_pct,
    'taxa_postergacao_ano_pct', taxa_postergacao_ano_pct,
    'politica_valida_5a', politica_valida_5a
  )
from p

union all

select
  '03_faixas_premio_administrativas',
  case when qtd_faixas_db >= 3 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'qtd_faixas_configuradas_setting', qtd_faixas,
    'qtd_faixas_db', qtd_faixas_db
  )
from p

union all

select
  '04_rpc_4b_persistiu_agenda_fixture',
  case
    when ok_4b is true
      and fase_4b = '4B_PERSISTENCIA_AGENDA'
      and persistencia_4b is true
      and dml_financeiro_4b is true
      and agenda_id_payload is not null
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'ok_4b', ok_4b,
    'fase_4b', fase_4b,
    'persistencia_4b', persistencia_4b,
    'dml_financeiro_4b', dml_financeiro_4b,
    'agenda_id_payload', agenda_id_payload
  )
from p

union all

select
  '05_agenda_ativa_com_parcelas',
  case when agenda_valida_5a then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'agenda_id', agenda_id,
    'agenda_status', agenda_status,
    'agenda_valida_5a', agenda_valida_5a,
    'qtd_parcelas_agenda', qtd_parcelas_agenda,
    'total_parcelas', total_parcelas,
    'parcelas_com_agenda_id', parcelas_com_agenda_id,
    'valor_total_agenda', valor_total_agenda,
    'valor_total_parcelas', valor_total_parcelas
  )
from p

union all

select
  '06_parcelas_elegiveis_para_5a',
  case
    when parcelas_nao_simbolicas > 0
      and (parcelas_podem_antecipacao > 0 or parcelas_podem_postergacao > 0 or parcelas_podem_vpl > 0)
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'parcelas_nao_simbolicas', parcelas_nao_simbolicas,
    'parcelas_podem_antecipacao', parcelas_podem_antecipacao,
    'parcelas_podem_postergacao', parcelas_podem_postergacao,
    'parcelas_podem_vpl', parcelas_podem_vpl,
    'parcelas_periodicidade_simbolica', parcelas_periodicidade_simbolica
  )
from p

union all

select
  '07_zero_operacoes_financeiras_confirmadas',
  case when total_operacoes = 0 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'total_operacoes', total_operacoes,
    'observacao', '10P prepara base mínima; não registra operação financeira.'
  )
from p

union all

select
  '08_readiness_para_migration_5a',
  case
    when politica_valida_5a
      and agenda_valida_5a
      and total_parcelas > 0
      and qtd_faixas_db >= 3
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'politica_valida_5a', politica_valida_5a,
    'agenda_valida_5a', agenda_valida_5a,
    'total_parcelas', total_parcelas,
    'qtd_faixas_db', qtd_faixas_db,
    'recommended_next_step_if_pass', 'Criar migration/RPC 5A.1 e testes 10A/10B/10C transacionais. Não criar seed permanente.'
  )
from p

union all

select
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Todos os dados criados pelo 10P são fixture transacional. O script termina com ROLLBACK.',
    'arquivos_posteriores_se_passar', jsonb_build_array(
      'supabase/migrations/<timestamp>_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql'
    )
  )
from p
order by bloco;

rollback;
