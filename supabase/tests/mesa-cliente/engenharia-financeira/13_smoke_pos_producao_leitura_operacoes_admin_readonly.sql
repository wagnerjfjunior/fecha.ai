-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- Smoke pós-merge / pós-produção — leitura administrativa de operações financeiras.
--
-- Objetivo:
--   Validar sanidade operacional das RPCs 5D em ambiente real sem criar fixture.
--
-- Escopo:
--   - read-only;
--   - sem INSERT;
--   - sem UPDATE;
--   - sem DELETE;
--   - sem criação de massa;
--   - sem alteração de operação;
--   - sem alteração de agenda;
--   - sem alteração de parcela.
--
-- Resultado esperado:
--   bloco | status | detalhe
--
-- Observação:
--   Se não existir operação financeira real acessível por admin, o teste retorna SKIP_DATA.
--   Isso não autoriza criar fixture em produção.

begin;
set transaction read only;
set local statement_timeout = '15s';
set local lock_timeout = '3s';

select set_config('app.mc5d_smoke.results', '[]', true);
select set_config('app.mc5d_smoke.user_id', '', true);
select set_config('app.mc5d_smoke.simulacao_id', '', true);
select set_config('app.mc5d_smoke.agenda_id', '', true);
select set_config('app.mc5d_smoke.operacao_id', '', true);
select set_config('app.mc5d_smoke.list_payload', 'null', true);
select set_config('app.mc5d_smoke.detail_payload', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.mc5d_smoke_add_result(
  p_bloco text,
  p_status text,
  p_detalhe jsonb default '{}'::jsonb
)
returns void
language plpgsql
as $$
declare
  v_atual jsonb;
begin
  v_atual := coalesce(nullif(current_setting('app.mc5d_smoke.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc5d_smoke.results',
    (v_atual || jsonb_build_array(jsonb_build_object(
      'bloco', p_bloco,
      'status', p_status,
      'detalhe', coalesce(p_detalhe, '{}'::jsonb)
    )))::text,
    true
  );
end;
$$;

create or replace function pg_temp.mc5d_smoke_expect_error(
  p_bloco text,
  p_expected_sqlstate text,
  p_sql text,
  p_fail_message text
)
returns void
language plpgsql
as $$
declare
  v_state text;
  v_msg text;
begin
  execute p_sql;

  perform pg_temp.mc5d_smoke_add_result(
    p_bloco,
    'FAIL',
    jsonb_build_object('erro', p_fail_message)
  );
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;

  perform pg_temp.mc5d_smoke_add_result(
    p_bloco,
    case when v_state = p_expected_sqlstate then 'PASS' else 'FAIL' end,
    jsonb_build_object('sqlstate', v_state, 'message', v_msg)
  );
end;
$$;

with funcoes as (
  select
    to_regprocedure('public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)') is not null as listar_existe,
    to_regprocedure('public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)') is not null as obter_existe
)
select pg_temp.mc5d_smoke_add_result(
  '00_funcoes_5d_existentes',
  case when listar_existe and obter_existe then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'listar_existe', listar_existe,
    'obter_existe', obter_existe,
    'listar_regprocedure', to_regprocedure('public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)')::text,
    'obter_regprocedure', to_regprocedure('public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)')::text
  )
)
from funcoes;

with alvo as materialized (
  select
    c.user_id,
    c.empresa_id as corretor_empresa_id,
    c.role,
    o.id as operacao_id,
    o.simulacao_id,
    o.agenda_id,
    o.empresa_id as operacao_empresa_id,
    o.status_operacao,
    o.tipo_operacao::text as tipo_operacao
  from public.corretores c
  join public.mesa_cliente_fluxo_operacoes o
    on (
      coalesce(c.role, '') = 'admin_global'
      or c.empresa_id = o.empresa_id
    )
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
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
    o.created_at desc nulls last,
    o.id
  limit 1
), setup as (
  select
    set_config('request.jwt.claim.sub', user_id::text, true) as jwt_sub,
    set_config('app.mc5d_smoke.user_id', user_id::text, true) as cfg_user,
    set_config('app.mc5d_smoke.simulacao_id', simulacao_id::text, true) as cfg_simulacao,
    set_config('app.mc5d_smoke.agenda_id', coalesce(agenda_id::text, ''), true) as cfg_agenda,
    set_config('app.mc5d_smoke.operacao_id', operacao_id::text, true) as cfg_operacao,
    *
  from alvo
)
select pg_temp.mc5d_smoke_add_result(
  '01_alvo_admin_operacao_real',
  case when exists(select 1 from setup) then 'PASS' else 'SKIP_DATA' end,
  coalesce(
    (
      select jsonb_build_object(
        'user_id', user_id,
        'role', role,
        'corretor_empresa_id', corretor_empresa_id,
        'operacao_id', operacao_id,
        'simulacao_id', simulacao_id,
        'agenda_id', agenda_id,
        'operacao_empresa_id', operacao_empresa_id,
        'status_operacao', status_operacao,
        'tipo_operacao', tipo_operacao
      )
      from setup
    ),
    jsonb_build_object(
      'mensagem', 'Nenhuma operação financeira real acessível por perfil administrativo ativo foi encontrada. Smoke não cria fixture em produção.'
    )
  )
);

set local role authenticated;

with target as (
  select
    nullif(current_setting('app.mc5d_smoke.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc5d_smoke.agenda_id', true), '')::uuid as agenda_id,
    nullif(current_setting('app.mc5d_smoke.operacao_id', true), '')::uuid as operacao_id
), listagem as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    t.simulacao_id,
    t.agenda_id,
    jsonb_build_object('limit', 5, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'desc')
  ) as payload
  from target t
  where t.simulacao_id is not null
    and t.operacao_id is not null
)
select set_config('app.mc5d_smoke.list_payload', coalesce((select payload::text from listagem), 'null'), true);

with target as (
  select nullif(current_setting('app.mc5d_smoke.operacao_id', true), '')::uuid as operacao_id
), detalhe as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    t.operacao_id,
    '{}'::jsonb
  ) as payload
  from target t
  where t.operacao_id is not null
)
select set_config('app.mc5d_smoke.detail_payload', coalesce((select payload::text from detalhe), 'null'), true);

reset role;

select pg_temp.mc5d_smoke_add_result(
  '02_listagem_admin_readonly_smoke',
  case
    when current_setting('app.mc5d_smoke.operacao_id', true) = '' then 'SKIP_DATA'
    when current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'fase' = '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN'
     and current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'dml_financeiro' = 'false'
     and (current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'total')::integer >= 1
     and jsonb_array_length(current_setting('app.mc5d_smoke.list_payload', true)::jsonb->'operacoes') >= 1
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'payload_ok', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'ok',
    'fase', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'fase',
    'readonly', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'readonly',
    'dml_financeiro', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'dml_financeiro',
    'total', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'total',
    'qtd_operacoes_retorno', case
      when current_setting('app.mc5d_smoke.list_payload', true)::jsonb ? 'operacoes'
      then jsonb_array_length(current_setting('app.mc5d_smoke.list_payload', true)::jsonb->'operacoes')
      else null
    end
  )
);

select pg_temp.mc5d_smoke_add_result(
  '03_detalhe_admin_readonly_smoke',
  case
    when current_setting('app.mc5d_smoke.operacao_id', true) = '' then 'SKIP_DATA'
    when current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'fase' = '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'dml_financeiro' = 'false'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->'operacao'->>'id' = current_setting('app.mc5d_smoke.operacao_id', true)
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'payload_ok', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'ok',
    'fase', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'fase',
    'readonly', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'readonly',
    'dml_financeiro', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'dml_financeiro',
    'operacao_id_retorno', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->'operacao'->>'id'
  )
);

select pg_temp.mc5d_smoke_add_result(
  '04_contrato_readonly_minimo',
  case
    when current_setting('app.mc5d_smoke.operacao_id', true) = '' then 'SKIP_DATA'
    when current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'altera_agenda' = 'false'
     and current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'altera_parcelas' = 'false'
     and current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'recalcula_operacao' = 'false'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'altera_agenda' = 'false'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'altera_parcelas' = 'false'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'recalcula_operacao' = 'false'
     and current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'cliente_safe' = 'false'
     and current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'cliente_safe' = 'false'
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'list_flags', jsonb_build_object(
      'altera_agenda', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'altera_agenda',
      'altera_parcelas', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'altera_parcelas',
      'recalcula_operacao', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'recalcula_operacao',
      'cliente_safe', current_setting('app.mc5d_smoke.list_payload', true)::jsonb->>'cliente_safe'
    ),
    'detail_flags', jsonb_build_object(
      'altera_agenda', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'altera_agenda',
      'altera_parcelas', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'altera_parcelas',
      'recalcula_operacao', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'recalcula_operacao',
      'cliente_safe', current_setting('app.mc5d_smoke.detail_payload', true)::jsonb->>'cliente_safe'
    )
  )
);

set local role authenticated;

select pg_temp.mc5d_smoke_expect_error(
  '05_order_by_invalido_bloqueado',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, null::uuid, jsonb_build_object('order_by', 'empresa_id'))$sql$,
    nullif(current_setting('app.mc5d_smoke.simulacao_id', true), '')
  ),
  'order_by inválido foi aceito no smoke pós-produção'
)
where nullif(current_setting('app.mc5d_smoke.simulacao_id', true), '') is not null;

reset role;

select pg_temp.mc5d_smoke_add_result(
  '99_smoke_readonly_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Smoke pós-produção 5D executado em transação READ ONLY. Não cria fixture e não executa DML financeiro.',
    'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
    'operacao_id', nullif(current_setting('app.mc5d_smoke.operacao_id', true), ''),
    'simulacao_id', nullif(current_setting('app.mc5d_smoke.simulacao_id', true), '')
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc5d_smoke.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
