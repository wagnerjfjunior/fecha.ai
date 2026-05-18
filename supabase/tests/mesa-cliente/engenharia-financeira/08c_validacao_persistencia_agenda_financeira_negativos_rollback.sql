-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4B
-- 08C — Validação de cenários negativos da persistência da agenda financeira com rollback.
--
-- Objetivo:
--   Validar bloqueios da RPC:
--     public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)
--
-- Cobre:
--   - anon sem EXECUTE por grant.
--   - authenticated com EXECUTE.
--   - simulação inexistente.
--   - payload_tabela com empresa_id fake.
--   - item com empresa_id fake.
--   - valor negativo.
--   - grupo desconhecido.
--   - periodicidade simbólica fraudada.
--   - periodicidade simbólica marcada como negociável.
--   - zero DML em mesa_cliente_agendas_financeiras.
--   - zero DML em mesa_cliente_fluxo_parcelas.
--   - zero DML em mesa_cliente_fluxo_operacoes.
--
-- Segurança:
--   - BEGIN + ROLLBACK.
--   - Cria apenas fixture transacional em mesa_simulacoes.
--   - Valida contagens físicas fora do role authenticated, para não confundir RLS com ausência de DML.

begin;

create or replace function pg_temp.capture_error(p_sql text)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_sqlstate text;
  v_message text;
begin
  begin
    execute p_sql;
    return jsonb_build_object('erro_capturado', false, 'sqlstate', null, 'message', null);
  exception when others then
    get stacked diagnostics v_sqlstate = returned_sqlstate, v_message = message_text;
    return jsonb_build_object('erro_capturado', true, 'sqlstate', v_sqlstate, 'message', v_message);
  end;
end;
$$;

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
    'Teste rollback 08C negativos agenda',
    41500.50,
    10000.50,
    0,
    41500.50,
    jsonb_build_object(
      'origem', 'teste_08c_negativos_agenda_rollback',
      'fixture_transacional', true
    ),
    'Fixture transacional do teste 08C. Deve sumir no ROLLBACK.'
  from candidato
  returning id as simulacao_id, empresa_id, corretor_id, empreendimento_id
),
setup as (
  select
    set_config('request.jwt.claim.sub', coalesce(c.user_id::text, '00000000-0000-0000-0000-000000000000'), true),
    set_config('app.mc08c.user_id', coalesce(c.user_id::text, ''), true),
    set_config('app.mc08c.corretor_id', coalesce(c.corretor_id::text, ''), true),
    set_config('app.mc08c.empresa_id', coalesce(f.empresa_id::text, ''), true),
    set_config('app.mc08c.role', coalesce(c.role::text, ''), true),
    set_config('app.mc08c.ativo', coalesce(c.ativo::text, 'false'), true),
    set_config('app.mc08c.is_admin_local', coalesce(c.is_admin_local::text, 'false'), true),
    set_config('app.mc08c.is_gestor', coalesce(c.is_gestor::text, 'false'), true),
    set_config('app.mc08c.simulacao_id', coalesce(f.simulacao_id::text, ''), true),
    set_config('app.mc08c.empreendimento_id', coalesce(f.empreendimento_id::text, ''), true),
    set_config('app.mc08c.empreendimento_nome', coalesce(c.empreendimento_nome::text, ''), true),
    set_config('app.mc08c.qtd_ctx', case when f.simulacao_id is null then '0' else '1' end, true)
  from candidato c
  join fixture f on true
)
select * from setup;

with ctx as (
  select nullif(current_setting('app.mc08c.simulacao_id', true), '')::uuid as simulacao_id
)
select
  set_config('app.mc08c.agendas_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_agendas_financeiras a
    join ctx on ctx.simulacao_id = a.simulacao_id
  ), '0'), true),
  set_config('app.mc08c.parcelas_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas p
    join ctx on ctx.simulacao_id = p.simulacao_id
  ), '0'), true),
  set_config('app.mc08c.operacoes_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes o
    join ctx on ctx.simulacao_id = o.simulacao_id
  ), '0'), true)
from ctx;

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc08c.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc08c.corretor_id', true), '')::uuid as corretor_id,
    nullif(current_setting('app.mc08c.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc08c.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc08c.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc08c.role', true), '') as role,
    coalesce(nullif(current_setting('app.mc08c.ativo', true), '')::boolean, false) as ativo,
    coalesce(nullif(current_setting('app.mc08c.is_admin_local', true), '')::boolean, false) as is_admin_local,
    coalesce(nullif(current_setting('app.mc08c.is_gestor', true), '')::boolean, false) as is_gestor,
    nullif(current_setting('app.mc08c.empreendimento_nome', true), '') as empreendimento_nome,
    coalesce(nullif(current_setting('app.mc08c.qtd_ctx', true), '')::integer, 0) as qtd_ctx
),
checks as materialized (
  select
    ctx.*,
    has_function_privilege(
      'anon',
      'public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'::regprocedure,
      'EXECUTE'
    ) as anon_can_execute,
    has_function_privilege(
      'authenticated',
      'public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'::regprocedure,
      'EXECUTE'
    ) as authenticated_can_execute,
    pg_temp.capture_error(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin('00000000-0000-0000-0000-000000000000'::uuid, date '2099-05-31', '[{"grupo":"entrada","valor":1000,"data":"2099-05-31"}]'::jsonb, '{}'::jsonb)$q$
    ) as simulacao_inexistente,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, %L::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":1000,"data":"2099-05-31"}]',
      '{"empresa_id":"00000000-0000-0000-0000-000000000000"}'
    )) as payload_empresa_fake,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":1000,"data":"2099-05-31","empresa_id":"00000000-0000-0000-0000-000000000000"}]'
    )) as item_empresa_fake,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":-1,"data":"2099-05-31"}]'
    )) as valor_negativo,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"grupo_inexistente","valor":1000,"data":"2099-05-31"}]'
    )) as grupo_desconhecido,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"periodicidade","valor":0,"mes_ano":"05/2099","eh_periodicidade_simbolica":false}]'
    )) as periodicidade_fraudada,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_persistir_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"periodicidade","valor":0,"mes_ano":"05/2099","negociavel":true}]'
    )) as periodicidade_negociavel
  from ctx
)
select
  set_config('app.mc08c.checks', coalesce((select row_to_json(checks)::jsonb::text from checks), '{}'::text), true);

reset role;

with ctx as materialized (
  select
    coalesce(nullif(current_setting('app.mc08c.checks', true), '')::jsonb, '{}'::jsonb) as checks,
    coalesce(nullif(current_setting('app.mc08c.agendas_before', true), '')::bigint, 0) as agendas_before,
    coalesce(nullif(current_setting('app.mc08c.parcelas_before', true), '')::bigint, 0) as parcelas_before,
    coalesce(nullif(current_setting('app.mc08c.operacoes_before', true), '')::bigint, 0) as operacoes_before,
    nullif(current_setting('app.mc08c.simulacao_id', true), '')::uuid as simulacao_id
),
after_counts as materialized (
  select
    ctx.*,
    (select count(*)::bigint from public.mesa_cliente_agendas_financeiras a where a.simulacao_id = ctx.simulacao_id) as agendas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas p where p.simulacao_id = ctx.simulacao_id) as parcelas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id) as operacoes_after
  from ctx
),
p as materialized (
  select
    checks,
    (checks->>'user_id')::uuid as user_id,
    (checks->>'corretor_id')::uuid as corretor_id,
    (checks->>'empresa_id')::uuid as empresa_id,
    (checks->>'empreendimento_id')::uuid as empreendimento_id,
    (checks->>'simulacao_id')::uuid as simulacao_id,
    checks->>'role' as role,
    coalesce((checks->>'ativo')::boolean, false) as ativo,
    coalesce((checks->>'is_admin_local')::boolean, false) as is_admin_local,
    coalesce((checks->>'is_gestor')::boolean, false) as is_gestor,
    checks->>'empreendimento_nome' as empreendimento_nome,
    coalesce((checks->>'qtd_ctx')::integer, 0) as qtd_ctx,
    coalesce((checks->>'anon_can_execute')::boolean, true) as anon_can_execute,
    coalesce((checks->>'authenticated_can_execute')::boolean, false) as authenticated_can_execute,
    checks->'simulacao_inexistente' as simulacao_inexistente,
    checks->'payload_empresa_fake' as payload_empresa_fake,
    checks->'item_empresa_fake' as item_empresa_fake,
    checks->'valor_negativo' as valor_negativo,
    checks->'grupo_desconhecido' as grupo_desconhecido,
    checks->'periodicidade_fraudada' as periodicidade_fraudada,
    checks->'periodicidade_negociavel' as periodicidade_negociavel,
    agendas_before,
    parcelas_before,
    operacoes_before,
    agendas_after,
    parcelas_after,
    operacoes_after
  from after_counts
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
  '02_grants_rpc_anon_bloqueado_authenticated_liberado',
  case when anon_can_execute is false and authenticated_can_execute is true then 'PASS' else 'FAIL' end,
  jsonb_build_object('anon_can_execute', anon_can_execute, 'authenticated_can_execute', authenticated_can_execute)
from p

union all

select
  '03_simulacao_inexistente_bloqueada',
  case when (simulacao_inexistente->>'erro_capturado')::boolean is true and simulacao_inexistente->>'sqlstate' = 'P0002' then 'PASS' else 'FAIL' end,
  simulacao_inexistente
from p

union all

select
  '04_payload_empresa_fake_bloqueado',
  case when (payload_empresa_fake->>'erro_capturado')::boolean is true and payload_empresa_fake->>'sqlstate' = '42501' then 'PASS' else 'FAIL' end,
  payload_empresa_fake
from p

union all

select
  '05_item_empresa_fake_bloqueado',
  case when (item_empresa_fake->>'erro_capturado')::boolean is true and item_empresa_fake->>'sqlstate' = '42501' then 'PASS' else 'FAIL' end,
  item_empresa_fake
from p

union all

select
  '06_valor_negativo_bloqueado',
  case when (valor_negativo->>'erro_capturado')::boolean is true and valor_negativo->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  valor_negativo
from p

union all

select
  '07_grupo_desconhecido_bloqueado',
  case when (grupo_desconhecido->>'erro_capturado')::boolean is true and grupo_desconhecido->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  grupo_desconhecido
from p

union all

select
  '08_periodicidade_fraudada_bloqueada',
  case when (periodicidade_fraudada->>'erro_capturado')::boolean is true and periodicidade_fraudada->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  periodicidade_fraudada
from p

union all

select
  '09_periodicidade_negociavel_bloqueada',
  case when (periodicidade_negociavel->>'erro_capturado')::boolean is true and periodicidade_negociavel->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  periodicidade_negociavel
from p

union all

select
  '10_zero_dml_agendas',
  case when agendas_before = agendas_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('agendas_before', agendas_before, 'agendas_after', agendas_after)
from p

union all

select
  '11_zero_dml_fluxo_parcelas',
  case when parcelas_before = parcelas_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('parcelas_before', parcelas_before, 'parcelas_after', parcelas_after)
from p

union all

select
  '12_zero_dml_fluxo_operacoes',
  case when operacoes_before = operacoes_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('operacoes_before', operacoes_before, 'operacoes_after', operacoes_after)
from p

union all

select
  '13_rollback_notice',
  'INFO',
  jsonb_build_object('mensagem', 'Fixture e qualquer efeito transacional serão encerrados com ROLLBACK.')
from p;

rollback;
