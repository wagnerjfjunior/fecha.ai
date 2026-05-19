-- MesaCliente Engenharia Financeira — 07A validação positiva da agenda financeira JSON-first
--
-- Objetivo:
--   Validar a RPC oficial da Fase 4A:
--     public.mesa_cliente_gerar_agenda_financeira_admin(uuid,date,jsonb,jsonb)
--
-- Correção de governança:
--   Este teste NÃO depende mais de existir uma linha real em mesa_simulacoes.
--   Como o banco pode estar sem simulações, o teste cria uma fixture mínima
--   dentro de BEGIN + ROLLBACK, usando corretor/empresa/empreendimento reais.
--
-- Critérios obrigatórios:
--   - RPC retorna JSON administrativo.
--   - cliente_safe=false.
--   - persistencia=false.
--   - dml_financeiro=false.
--   - agenda normalizada com datas resolvidas.
--   - periodicidade simbólica fica não negociável.
--   - empresa_id do payload não é soberano, mas pode ser aceito se bater com a simulação.
--   - count_before = count_after em mesa_cliente_fluxo_parcelas.
--   - count_before = count_after em mesa_cliente_fluxo_operacoes.
--
-- Segurança:
--   - Teste com BEGIN + ROLLBACK.
--   - Cria apenas fixture transacional em mesa_simulacoes.
--   - Não grava agenda.
--   - Não executa DML em mesa_cliente_fluxo_parcelas.
--   - Não executa DML em mesa_cliente_fluxo_operacoes.

begin;

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
), fixture as materialized (
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
    'Teste rollback 07A JSON-first',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object(
      'origem', 'teste_07a_json_first_rollback',
      'fixture_transacional', true
    ),
    'Fixture transacional do teste 07A. Deve sumir no ROLLBACK.'
  from candidato
  returning id as simulacao_id, empresa_id, corretor_id, empreendimento_id
), setup as (
  select
    set_config('request.jwt.claim.sub', coalesce(c.user_id::text, '00000000-0000-0000-0000-000000000000'), true),
    set_config('app.mc07a.user_id', coalesce(c.user_id::text, ''), true),
    set_config('app.mc07a.corretor_id', coalesce(c.corretor_id::text, ''), true),
    set_config('app.mc07a.empresa_id', coalesce(f.empresa_id::text, ''), true),
    set_config('app.mc07a.role', coalesce(c.role::text, ''), true),
    set_config('app.mc07a.ativo', coalesce(c.ativo::text, 'false'), true),
    set_config('app.mc07a.is_admin_local', coalesce(c.is_admin_local::text, 'false'), true),
    set_config('app.mc07a.is_gestor', coalesce(c.is_gestor::text, 'false'), true),
    set_config('app.mc07a.simulacao_id', coalesce(f.simulacao_id::text, ''), true),
    set_config('app.mc07a.empreendimento_id', coalesce(f.empreendimento_id::text, ''), true),
    set_config('app.mc07a.empreendimento_nome', coalesce(c.empreendimento_nome::text, ''), true),
    set_config('app.mc07a.qtd_ctx', case when f.simulacao_id is null then '0' else '1' end, true)
  from candidato c
  join fixture f on true
)
select * from setup;

select set_config('request.jwt.claim.sub', coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''), '00000000-0000-0000-0000-000000000000'), true);
select set_config('app.mc07a.qtd_ctx', coalesce(nullif(current_setting('app.mc07a.qtd_ctx', true), ''), '0'), true);

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc07a.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc07a.corretor_id', true), '')::uuid as corretor_id,
    nullif(current_setting('app.mc07a.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc07a.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc07a.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc07a.role', true), '') as role,
    coalesce(nullif(current_setting('app.mc07a.ativo', true), '')::boolean, false) as ativo,
    coalesce(nullif(current_setting('app.mc07a.is_admin_local', true), '')::boolean, false) as is_admin_local,
    coalesce(nullif(current_setting('app.mc07a.is_gestor', true), '')::boolean, false) as is_gestor,
    nullif(current_setting('app.mc07a.empreendimento_nome', true), '') as empreendimento_nome,
    coalesce(nullif(current_setting('app.mc07a.qtd_ctx', true), '')::integer, 0) as qtd_ctx
), before_counts as materialized (
  select
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas) as parcelas_before,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes) as operacoes_before
), chamada as materialized (
  select
    case
      when ctx.qtd_ctx = 1 and ctx.simulacao_id is not null then
        public.mesa_cliente_gerar_agenda_financeira_admin(
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
            'origem', 'teste_07a_json_first'
          )
        )
      else null::jsonb
    end as payload
  from ctx
), after_counts as materialized (
  select
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas) as parcelas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes) as operacoes_after
), p as materialized (
  select
    c.*,
    b.parcelas_before,
    b.operacoes_before,
    a.parcelas_after,
    a.operacoes_after,
    ch.payload,
    (ch.payload->>'ok')::boolean as ok,
    ch.payload->>'fase' as fase,
    ch.payload->>'visao' as visao,
    (ch.payload->>'cliente_safe')::boolean as cliente_safe,
    (ch.payload->>'persistencia')::boolean as persistencia,
    (ch.payload->>'dml_financeiro')::boolean as dml_financeiro,
    jsonb_array_length(coalesce(ch.payload->'agenda', '[]'::jsonb)) as qtd_agenda,
    (ch.payload->'totais'->>'qtd_itens_origem')::integer as qtd_itens_origem,
    (ch.payload->'totais'->>'qtd_parcelas_normalizadas')::integer as qtd_parcelas_normalizadas,
    (ch.payload->'totais'->>'valor_total_agenda')::numeric as valor_total_agenda,
    ch.payload->'agenda' as agenda
  from ctx c
  cross join before_counts b
  cross join chamada ch
  cross join after_counts a
)
select '01_fixture_transacional_contexto' as bloco,
  case when qtd_ctx = 1 and user_id is not null and empresa_id is not null and empreendimento_id is not null and simulacao_id is not null then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'user_id', user_id,
    'corretor_id', corretor_id,
    'empresa_id', empresa_id,
    'empreendimento_id', empreendimento_id,
    'empreendimento_nome', empreendimento_nome,
    'simulacao_id_fixture', simulacao_id,
    'role', role,
    'ativo', ativo,
    'is_admin_local', is_admin_local,
    'is_gestor', is_gestor
  ) as detalhe
from p
union all
select '02_rpc_executou_json_first',
  case when ok is true and fase = '4A_JSON_FIRST' then 'PASS' else 'FAIL' end,
  jsonb_build_object('ok', ok, 'fase', fase, 'payload_existe', payload is not null)
from p
union all
select '03_payload_admin_nao_cliente_safe',
  case when visao = 'administrativa' and cliente_safe is false then 'PASS' else 'FAIL' end,
  jsonb_build_object('visao', visao, 'cliente_safe', cliente_safe)
from p
union all
select '04_zero_persistencia_declarada',
  case when persistencia is false and dml_financeiro is false then 'PASS' else 'FAIL' end,
  jsonb_build_object('persistencia', persistencia, 'dml_financeiro', dml_financeiro)
from p
union all
select '05_agenda_normalizada',
  case when qtd_itens_origem = 4 and qtd_agenda = 6 and qtd_parcelas_normalizadas = 6 and valor_total_agenda = 29500.50 then 'PASS' else 'FAIL' end,
  jsonb_build_object('qtd_itens_origem', qtd_itens_origem, 'qtd_agenda', qtd_agenda, 'qtd_parcelas_normalizadas', qtd_parcelas_normalizadas, 'valor_total_agenda', valor_total_agenda)
from p
union all
select '06_periodicidade_nao_negociavel',
  case when exists (
    select 1
    from jsonb_array_elements(coalesce(agenda, '[]'::jsonb)) a
    where a.value->>'grupo' = 'periodicidade'
      and (a.value->>'eh_periodicidade_simbolica')::boolean is true
      and (a.value->>'negociavel')::boolean is false
  ) then 'PASS' else 'FAIL' end,
  jsonb_build_object('periodicidade', (
    select a.value
    from jsonb_array_elements(coalesce(agenda, '[]'::jsonb)) a
    where a.value->>'grupo' = 'periodicidade'
    limit 1
  ))
from p
union all
select '07_datas_resolvidas',
  case when exists (
    select 1
    from jsonb_array_elements(coalesce(agenda, '[]'::jsonb)) a
    where a.value->>'grupo' = 'mensais'
      and a.value->>'origem_data' = 'tabela_comercial_mes'
      and a.value->>'data_vencimento' = '2099-06-30'
  ) then 'PASS' else 'FAIL' end,
  jsonb_build_object('mensais_primeira_data', (
    select a.value
    from jsonb_array_elements(coalesce(agenda, '[]'::jsonb)) a
    where a.value->>'grupo' = 'mensais'
    order by (a.value->>'ordem')::integer
    limit 1
  ))
from p
union all
select '08_zero_dml_fluxo_parcelas',
  case when parcelas_before = parcelas_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('parcelas_before', parcelas_before, 'parcelas_after', parcelas_after)
from p
union all
select '09_zero_dml_fluxo_operacoes',
  case when operacoes_before = operacoes_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('operacoes_before', operacoes_before, 'operacoes_after', operacoes_after)
from p
union all
select '10_rollback_notice', 'INFO', jsonb_build_object('mensagem', 'Fixture e qualquer efeito transacional serão encerrados com ROLLBACK.')
from p;

rollback;
