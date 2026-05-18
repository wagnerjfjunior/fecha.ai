-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4B
-- 08A — Validação positiva da persistência da agenda financeira com rollback.
--
-- Objetivo:
--   Validar a RPC:
--     public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)
--
-- Critérios:
--   - Cria fixture transacional em mesa_simulacoes.
--   - Executa a RPC como authenticated.
--   - Valida a persistência física depois de RESET ROLE, para não confundir RLS de leitura com ausência de DML.
--   - Cria 1 cabeçalho em mesa_cliente_agendas_financeiras.
--   - Cria 6 parcelas em mesa_cliente_fluxo_parcelas vinculadas ao agenda_id.
--   - Não cria operação financeira em mesa_cliente_fluxo_operacoes.
--   - Usa status='ativa', totais JSONB e checksum conforme migration 4B real.
--   - Termina com ROLLBACK.
--
-- Observação importante:
--   A RPC é SECURITY DEFINER e insere corretamente. As validações físicas precisam ocorrer fora do role
--   authenticated porque as policies/RLS podem ocultar linhas persistidas no mesmo teste. Banco não sumiu;
--   era só a cortina do RLS fazendo teatro.

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
      c.role in ('admin_global', 'root', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_global' then 1
      when c.role = 'root' then 2
      when c.role = 'admin_local' then 3
      when c.role = 'gestor' then 4
      when c.role = 'coordenador' then 5
      when coalesce(c.is_admin_local, false) then 6
      when coalesce(c.is_gestor, false) then 7
      else 8
    end,
    c.created_at desc nulls last,
    c.id,
    e.nome
  limit 1
),
fixture as materialized (
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
    'Teste rollback 08A persistencia agenda',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object(
      'origem', 'teste_08a_persistencia_agenda_rollback',
      'fixture_transacional', true
    ),
    'Fixture transacional do teste 08A. Deve sumir no ROLLBACK.'
  from candidato
  returning id as simulacao_id, empresa_id, corretor_id, empreendimento_id
),
setup as (
  select
    set_config('request.jwt.claim.sub', coalesce(c.user_id::text, '00000000-0000-0000-0000-000000000000'), true),
    set_config('app.mc08a.user_id', coalesce(c.user_id::text, ''), true),
    set_config('app.mc08a.corretor_id', coalesce(c.corretor_id::text, ''), true),
    set_config('app.mc08a.empresa_id', coalesce(f.empresa_id::text, ''), true),
    set_config('app.mc08a.role', coalesce(c.role::text, ''), true),
    set_config('app.mc08a.ativo', coalesce(c.ativo::text, 'false'), true),
    set_config('app.mc08a.is_admin_local', coalesce(c.is_admin_local::text, 'false'), true),
    set_config('app.mc08a.is_gestor', coalesce(c.is_gestor::text, 'false'), true),
    set_config('app.mc08a.simulacao_id', coalesce(f.simulacao_id::text, ''), true),
    set_config('app.mc08a.empreendimento_id', coalesce(f.empreendimento_id::text, ''), true),
    set_config('app.mc08a.empreendimento_nome', coalesce(c.empreendimento_nome::text, ''), true),
    set_config('app.mc08a.qtd_ctx', case when f.simulacao_id is null then '0' else '1' end, true)
  from candidato c
  join fixture f on true
)
select * from setup;

with ctx as (
  select
    nullif(current_setting('app.mc08a.simulacao_id', true), '')::uuid as simulacao_id
)
select
  set_config('app.mc08a.agendas_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_agendas_financeiras a
    join ctx on ctx.simulacao_id = a.simulacao_id
  ), '0'), true),
  set_config('app.mc08a.parcelas_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas p
    join ctx on ctx.simulacao_id = p.simulacao_id
  ), '0'), true),
  set_config('app.mc08a.operacoes_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes o
    join ctx on ctx.simulacao_id = o.simulacao_id
  ), '0'), true)
from ctx;

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc08a.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc08a.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc08a.simulacao_id', true), '')::uuid as simulacao_id,
    coalesce(nullif(current_setting('app.mc08a.qtd_ctx', true), '')::integer, 0) as qtd_ctx
),
chamada as materialized (
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
            'origem', 'teste_08a_persistencia_agenda'
          )
        )
      else null::jsonb
    end as payload
  from ctx
)
select set_config('app.mc08a.payload', coalesce((select payload::text from chamada), 'null'), true);

reset role;

with ctx as materialized (
  select
    nullif(current_setting('app.mc08a.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc08a.corretor_id', true), '')::uuid as corretor_id,
    nullif(current_setting('app.mc08a.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc08a.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc08a.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc08a.role', true), '') as role,
    coalesce(nullif(current_setting('app.mc08a.ativo', true), '')::boolean, false) as ativo,
    coalesce(nullif(current_setting('app.mc08a.is_admin_local', true), '')::boolean, false) as is_admin_local,
    coalesce(nullif(current_setting('app.mc08a.is_gestor', true), '')::boolean, false) as is_gestor,
    nullif(current_setting('app.mc08a.empreendimento_nome', true), '') as empreendimento_nome,
    coalesce(nullif(current_setting('app.mc08a.qtd_ctx', true), '')::integer, 0) as qtd_ctx,
    coalesce(nullif(current_setting('app.mc08a.agendas_before', true), '')::bigint, 0) as agendas_before,
    coalesce(nullif(current_setting('app.mc08a.parcelas_before', true), '')::bigint, 0) as parcelas_before,
    coalesce(nullif(current_setting('app.mc08a.operacoes_before', true), '')::bigint, 0) as operacoes_before,
    coalesce(nullif(current_setting('app.mc08a.payload', true), '')::jsonb, 'null'::jsonb) as payload
),
after_counts as materialized (
  select
    ctx.simulacao_id,
    (select count(*)::bigint from public.mesa_cliente_agendas_financeiras a where a.simulacao_id = ctx.simulacao_id) as agendas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas p where p.simulacao_id = ctx.simulacao_id) as parcelas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id) as operacoes_after
  from ctx
),
db_agenda as materialized (
  select
    a.id as agenda_id,
    a.simulacao_id,
    a.empresa_id,
    a.empreendimento_id,
    a.status,
    coalesce((a.totais->>'qtd_parcelas')::integer, 0) as qtd_parcelas,
    coalesce((a.totais->>'valor_total')::numeric, 0) as valor_total_agenda,
    a.checksum
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  order by a.created_at desc
  limit 1
),
db_parcelas as materialized (
  select
    count(*)::integer as qtd_parcelas_db,
    coalesce(sum(p.valor_atual), 0)::numeric as valor_total_parcelas_db,
    count(*) filter (
      where p.eh_periodicidade_simbolica is true
        and coalesce(p.pode_receber_vpl, true) is false
        and coalesce(p.pode_receber_antecipacao, true) is false
        and coalesce(p.pode_receber_postergacao, true) is false
    )::integer as qtd_periodicidade_bloqueada,
    count(*) filter (where p.grupo = 'mensal' and p.data_atual = date '2099-06-30')::integer as qtd_mensal_data_resolvida,
    count(*) filter (where p.agenda_id is not null)::integer as qtd_com_agenda_id
  from public.mesa_cliente_fluxo_parcelas p
  join ctx on ctx.simulacao_id = p.simulacao_id
),
p as materialized (
  select
    c.*,
    ac.agendas_after,
    ac.parcelas_after,
    ac.operacoes_after,
    (c.payload->>'ok')::boolean as ok,
    c.payload->>'fase' as fase,
    c.payload->>'visao' as visao,
    (c.payload->>'cliente_safe')::boolean as cliente_safe,
    (c.payload->>'persistencia')::boolean as persistencia,
    (c.payload->>'dml_financeiro')::boolean as dml_financeiro,
    (c.payload->>'idempotente')::boolean as idempotente,
    nullif(c.payload->>'agenda_id', '')::uuid as agenda_id_payload,
    (c.payload->>'qtd_parcelas_persistidas')::integer as qtd_parcelas_payload,
    (c.payload->>'valor_total_agenda')::numeric as valor_total_agenda_payload,
    c.payload->>'checksum' as checksum_payload,
    da.agenda_id as agenda_id_db,
    da.status as agenda_status_db,
    da.qtd_parcelas as qtd_parcelas_agenda_db,
    da.valor_total_agenda as valor_total_agenda_db,
    da.checksum as checksum_db,
    dp.qtd_parcelas_db,
    dp.valor_total_parcelas_db,
    dp.qtd_periodicidade_bloqueada,
    dp.qtd_mensal_data_resolvida,
    dp.qtd_com_agenda_id
  from ctx c
  cross join after_counts ac
  left join db_agenda da on true
  cross join db_parcelas dp
)
select
  '01_fixture_transacional_contexto' as bloco,
  case
    when qtd_ctx = 1
      and user_id is not null
      and empresa_id is not null
      and empreendimento_id is not null
      and simulacao_id is not null
    then 'PASS'
    else 'FAIL'
  end as status,
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

select
  '02_rpc_executou_persistencia_4b',
  case
    when ok is true
      and fase = '4B_PERSISTENCIA_AGENDA'
      and payload is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'ok', ok,
    'fase', fase,
    'payload_existe', payload is not null
  )
from p

union all

select
  '03_payload_admin_nao_cliente_safe',
  case
    when visao = 'administrativa'
      and cliente_safe is false
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'visao', visao,
    'cliente_safe', cliente_safe
  )
from p

union all

select
  '04_persistencia_declarada',
  case
    when persistencia is true
      and dml_financeiro is true
      and idempotente is false
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'persistencia', persistencia,
    'dml_financeiro', dml_financeiro,
    'idempotente', idempotente
  )
from p

union all

select
  '05_agenda_persistida',
  case
    when agendas_before = 0
      and agendas_after = 1
      and agenda_id_payload is not null
      and agenda_id_db = agenda_id_payload
      and agenda_status_db = 'ativa'
      and checksum_db = checksum_payload
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'agendas_before', agendas_before,
    'agendas_after', agendas_after,
    'agenda_id_payload', agenda_id_payload,
    'agenda_id_db', agenda_id_db,
    'agenda_status_db', agenda_status_db,
    'checksum_db', checksum_db,
    'checksum_payload', checksum_payload
  )
from p

union all

select
  '06_parcelas_persistidas',
  case
    when parcelas_before = 0
      and parcelas_after = 6
      and qtd_parcelas_db = 6
      and qtd_com_agenda_id = 6
      and qtd_parcelas_agenda_db = 6
      and valor_total_parcelas_db = 29500.50
      and valor_total_agenda_db = 29500.50
      and qtd_parcelas_payload = 6
      and valor_total_agenda_payload = 29500.50
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'parcelas_before', parcelas_before,
    'parcelas_after', parcelas_after,
    'qtd_parcelas_db', qtd_parcelas_db,
    'qtd_com_agenda_id', qtd_com_agenda_id,
    'qtd_parcelas_agenda_db', qtd_parcelas_agenda_db,
    'valor_total_parcelas_db', valor_total_parcelas_db,
    'valor_total_agenda_db', valor_total_agenda_db,
    'qtd_parcelas_payload', qtd_parcelas_payload,
    'valor_total_agenda_payload', valor_total_agenda_payload
  )
from p

union all

select
  '07_periodicidade_bloqueada',
  case
    when qtd_periodicidade_bloqueada = 1
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'qtd_periodicidade_bloqueada', qtd_periodicidade_bloqueada
  )
from p

union all

select
  '08_datas_resolvidas',
  case
    when qtd_mensal_data_resolvida >= 1
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'qtd_mensal_data_resolvida_2099_06_30', qtd_mensal_data_resolvida
  )
from p

union all

select
  '09_zero_dml_operacoes',
  case
    when operacoes_before = operacoes_after
      and operacoes_after = 0
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'operacoes_before', operacoes_before,
    'operacoes_after', operacoes_after
  )
from p

union all

select
  '10_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Agenda, parcelas e fixture foram criadas apenas dentro da transação. Tudo será encerrado com ROLLBACK.'
  )
from p;

rollback;
