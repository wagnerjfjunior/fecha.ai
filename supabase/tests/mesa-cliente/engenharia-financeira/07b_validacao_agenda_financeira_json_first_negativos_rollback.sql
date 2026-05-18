-- MesaCliente Engenharia Financeira — 07B cenários negativos da agenda financeira JSON-first
--
-- Objetivo:
--   Validar bloqueios da RPC oficial da Fase 4A JSON-first.
--
-- Cobre:
--   - anon sem execute.
--   - simulação inexistente.
--   - payload_tabela com empresa_id fake.
--   - item com empresa_id fake.
--   - valor negativo.
--   - grupo desconhecido.
--   - periodicidade simbólica fraudada.
--   - periodicidade simbólica marcada como negociável.
--   - zero DML em tabelas financeiras.
--
-- Segurança:
--   - BEGIN + ROLLBACK.
--   - Não cria massa.
--   - Não grava agenda.

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
    s.id as simulacao_id,
    s.empreendimento_id
  from public.mesa_simulacoes s
  join public.corretores c
    on c.empresa_id = s.empresa_id
   and coalesce(c.ativo, true) = true
   and c.user_id is not null
  where s.empresa_id is not null
    and s.empreendimento_id is not null
    and (
      s.corretor_id is null
      or s.corretor_id = c.id
      or c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when s.corretor_id = c.id then 1
      when c.role in ('admin_global', 'admin_local', 'gestor') then 2
      else 3
    end,
    s.created_at desc nulls last,
    s.id
  limit 1
), setup as (
  select
    set_config('request.jwt.claim.sub', coalesce(user_id::text, '00000000-0000-0000-0000-000000000000'), true),
    set_config('app.mc07b.user_id', coalesce(user_id::text, ''), true),
    set_config('app.mc07b.empresa_id', coalesce(empresa_id::text, ''), true),
    set_config('app.mc07b.empreendimento_id', coalesce(empreendimento_id::text, ''), true),
    set_config('app.mc07b.simulacao_id', coalesce(simulacao_id::text, ''), true),
    set_config('app.mc07b.role', coalesce(role::text, ''), true),
    set_config('app.mc07b.ativo', coalesce(ativo::text, 'false'), true),
    set_config('app.mc07b.qtd_ctx', case when user_id is null then '0' else '1' end, true)
  from candidato
)
select * from setup;

select set_config('request.jwt.claim.sub', coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''), '00000000-0000-0000-0000-000000000000'), true);
select set_config('app.mc07b.qtd_ctx', coalesce(nullif(current_setting('app.mc07b.qtd_ctx', true), ''), '0'), true);

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc07b.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc07b.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc07b.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc07b.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc07b.role', true), '') as role,
    coalesce(nullif(current_setting('app.mc07b.ativo', true), '')::boolean, false) as ativo,
    coalesce(nullif(current_setting('app.mc07b.qtd_ctx', true), '')::integer, 0) as qtd_ctx
), before_counts as materialized (
  select
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas) as parcelas_before,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes) as operacoes_before
), checks as materialized (
  select
    ctx.*,
    pg_temp.capture_error(format(
      $q$set local role anon; select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb); reset role$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":1000,"data":"2099-05-31"}]'
    )) as anon_sem_execute,
    pg_temp.capture_error(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin('00000000-0000-0000-0000-000000000000'::uuid, date '2099-05-31', '[{"grupo":"entrada","valor":1000,"data":"2099-05-31"}]'::jsonb, '{}'::jsonb)$q$
    ) as simulacao_inexistente,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, %L::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":1000,"data":"2099-05-31"}]',
      '{"empresa_id":"00000000-0000-0000-0000-000000000000"}'
    )) as payload_empresa_fake,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":1000,"data":"2099-05-31","empresa_id":"00000000-0000-0000-0000-000000000000"}]'
    )) as item_empresa_fake,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"entrada","valor":-1,"data":"2099-05-31"}]'
    )) as valor_negativo,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"grupo_inexistente","valor":1000,"data":"2099-05-31"}]'
    )) as grupo_desconhecido,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"periodicidade","valor":0,"mes_ano":"05/2099","eh_periodicidade_simbolica":false}]'
    )) as periodicidade_fraudada,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_gerar_agenda_financeira_admin(%L::uuid, date '2099-05-31', %L::jsonb, '{}'::jsonb)$q$,
      ctx.simulacao_id,
      '[{"grupo":"periodicidade","valor":0,"mes_ano":"05/2099","negociavel":true}]'
    )) as periodicidade_negociavel
  from ctx
), after_counts as materialized (
  select
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas) as parcelas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes) as operacoes_after
), p as materialized (
  select
    checks.*,
    b.parcelas_before,
    b.operacoes_before,
    a.parcelas_after,
    a.operacoes_after
  from checks
  cross join before_counts b
  cross join after_counts a
)
select '01_candidato_contexto' as bloco,
  case when qtd_ctx = 1 and user_id is not null and empresa_id is not null and empreendimento_id is not null and simulacao_id is not null then 'PASS' else 'FAIL' end as status,
  jsonb_build_object('user_id', user_id, 'empresa_id', empresa_id, 'empreendimento_id', empreendimento_id, 'simulacao_id', simulacao_id, 'role', role, 'ativo', ativo) as detalhe
from p
union all
select '02_anon_sem_execute',
  case when (anon_sem_execute->>'erro_capturado')::boolean is true then 'PASS' else 'FAIL' end,
  anon_sem_execute
from p
union all
select '03_simulacao_inexistente_bloqueada',
  case when (simulacao_inexistente->>'erro_capturado')::boolean is true and simulacao_inexistente->>'sqlstate' = 'P0002' then 'PASS' else 'FAIL' end,
  simulacao_inexistente
from p
union all
select '04_payload_empresa_fake_bloqueado',
  case when (payload_empresa_fake->>'erro_capturado')::boolean is true and payload_empresa_fake->>'sqlstate' = '42501' then 'PASS' else 'FAIL' end,
  payload_empresa_fake
from p
union all
select '05_item_empresa_fake_bloqueado',
  case when (item_empresa_fake->>'erro_capturado')::boolean is true and item_empresa_fake->>'sqlstate' = '42501' then 'PASS' else 'FAIL' end,
  item_empresa_fake
from p
union all
select '06_valor_negativo_bloqueado',
  case when (valor_negativo->>'erro_capturado')::boolean is true and valor_negativo->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  valor_negativo
from p
union all
select '07_grupo_desconhecido_bloqueado',
  case when (grupo_desconhecido->>'erro_capturado')::boolean is true and grupo_desconhecido->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  grupo_desconhecido
from p
union all
select '08_periodicidade_fraudada_bloqueada',
  case when (periodicidade_fraudada->>'erro_capturado')::boolean is true and periodicidade_fraudada->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  periodicidade_fraudada
from p
union all
select '09_periodicidade_negociavel_bloqueada',
  case when (periodicidade_negociavel->>'erro_capturado')::boolean is true and periodicidade_negociavel->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
  periodicidade_negociavel
from p
union all
select '10_zero_dml_fluxo_parcelas',
  case when parcelas_before = parcelas_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('parcelas_before', parcelas_before, 'parcelas_after', parcelas_after)
from p
union all
select '11_zero_dml_fluxo_operacoes',
  case when operacoes_before = operacoes_after then 'PASS' else 'FAIL' end,
  jsonb_build_object('operacoes_before', operacoes_before, 'operacoes_after', operacoes_after)
from p
union all
select '12_rollback_notice', 'INFO', jsonb_build_object('mensagem', 'Nada foi persistido. Transação será encerrada com ROLLBACK.')
from p;

rollback;
