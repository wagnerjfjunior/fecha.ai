-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- 13E — Filtros, paginação e ordenação da listagem administrativa de operações financeiras.
--
-- Princípio deste teste:
--   - não hardcodar tenant/empresa/usuário;
--   - não usar datas mágicas de calendário para a massa financeira;
--   - derivar datas de teste a partir de current_date e da própria parcela criada;
--   - respeitar as regras soberanas das RPCs 4B/5B/5C;
--   - encerrar tudo com ROLLBACK.
--
-- O que este teste valida na RPC 5D:
--   - filtro por agenda_id;
--   - filtro por status_operacao;
--   - filtro por tipo_operacao;
--   - filtro por visivel_cliente;
--   - filtro por data_de/data_ate;
--   - paginação limit/offset;
--   - order_by allowlist;
--   - order_dir allowlist;
--   - retorno canônico dos metadados da listagem.

begin;

select set_config('app.mc13e.results', '[]', true);
select set_config('app.mc13e.user_id', '', true);
select set_config('app.mc13e.simulacao_id', '', true);
select set_config('app.mc13e.empresa_id', '', true);
select set_config('app.mc13e.empreendimento_id', '', true);
select set_config('app.mc13e.politica_id', '', true);
select set_config('app.mc13e.agenda_id', '', true);
select set_config('app.mc13e.parcela_1_id', '', true);
select set_config('app.mc13e.parcela_2_id', '', true);
select set_config('app.mc13e.parcela_3_id', '', true);
select set_config('app.mc13e.parcela_4_id', '', true);
select set_config('app.mc13e.parcela_3_data_atual', '', true);
select set_config('app.mc13e.parcela_3_data_destino', '', true);
select set_config('app.mc13e.op1_id', '', true);
select set_config('app.mc13e.op2_id', '', true);
select set_config('app.mc13e.op3_id', '', true);
select set_config('app.mc13e.op4_id', '', true);
select set_config('app.mc13e.payload_4b', 'null', true);
select set_config('app.mc13e.payload_5b_op1', 'null', true);
select set_config('app.mc13e.payload_5b_op2', 'null', true);
select set_config('app.mc13e.payload_5b_op3', 'null', true);
select set_config('app.mc13e.payload_5b_op4', 'null', true);
select set_config('app.mc13e.payload_5c_confirmar_op1', 'null', true);
select set_config('app.mc13e.payload_5c_cancelar_op2', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

-- Datas dinâmicas da fixture. Nada de ano fixo/mágico.
select set_config('app.mc13e.data_referencia', current_date::text, true);
select set_config('app.mc13e.data_ato', (current_date + interval '730 days')::date::text, true);
select set_config('app.mc13e.mes_mensais', to_char((current_date + interval '760 days')::date, 'MM/YYYY'), true);
select set_config('app.mc13e.mes_intermediarias', to_char((current_date + interval '820 days')::date, 'MM/YYYY'), true);
select set_config('app.mc13e.politica_mes_referencia', date_trunc('month', current_date + interval '20 years')::date::text, true);
select set_config('app.mc13e.politica_vigencia_inicio', (current_date - interval '1 year')::date::text, true);
select set_config('app.mc13e.politica_vigencia_fim', (current_date + interval '20 years')::date::text, true);
select set_config('app.mc13e.data_sem_resultado_de', (current_date + interval '1 day')::date::text, true);
select set_config('app.mc13e.data_sem_resultado_ate', (current_date + interval '2 days')::date::text, true);

create or replace function pg_temp.mc13e_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc13e.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc13e.results',
    (v_atual || jsonb_build_array(jsonb_build_object(
      'bloco', p_bloco,
      'status', p_status,
      'detalhe', coalesce(p_detalhe, '{}'::jsonb)
    )))::text,
    true
  );
end;
$$;

create or replace function pg_temp.mc13e_expect_error(
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

  perform pg_temp.mc13e_add_result(
    p_bloco,
    'FAIL',
    jsonb_build_object('erro', p_fail_message)
  );
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;

  perform pg_temp.mc13e_add_result(
    p_bloco,
    case when v_state = p_expected_sqlstate then 'PASS' else 'FAIL' end,
    jsonb_build_object('sqlstate', v_state, 'message', v_msg)
  );
end;
$$;

create or replace function pg_temp.mc13e_list_statuses(p_payload jsonb)
returns text[]
language sql
stable
as $$
  select coalesce(array_agg(item->>'status_operacao' order by ord), array[]::text[])
  from jsonb_array_elements(coalesce(p_payload->'operacoes', '[]'::jsonb)) with ordinality as t(item, ord);
$$;

create or replace function pg_temp.mc13e_list_tipos(p_payload jsonb)
returns text[]
language sql
stable
as $$
  select coalesce(array_agg(item->>'tipo_operacao' order by ord), array[]::text[])
  from jsonb_array_elements(coalesce(p_payload->'operacoes', '[]'::jsonb)) with ordinality as t(item, ord);
$$;

create or replace function pg_temp.mc13e_list_ids(p_payload jsonb)
returns uuid[]
language sql
stable
as $$
  select coalesce(array_agg((item->>'id')::uuid order by ord), array[]::uuid[])
  from jsonb_array_elements(coalesce(p_payload->'operacoes', '[]'::jsonb)) with ordinality as t(item, ord);
$$;

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    e.id as empreendimento_id
  from public.corretores c
  join public.empreendimentos e on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor', 'coordenador')
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
    'Teste rollback 13E filtros paginação ordenação 5D',
    78000.00,
    18000.00,
    0,
    78000.00,
    jsonb_build_object('origem_teste', '13e_5d_rollback', 'fixture_transacional', true),
    'Fixture transacional 13E. Deve sumir no ROLLBACK.'
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
    current_setting('app.mc13e.politica_mes_referencia', true)::date,
    current_setting('app.mc13e.politica_vigencia_inicio', true)::date,
    current_setting('app.mc13e.politica_vigencia_fim', true)::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture transacional 13E para filtros, paginação e ordenação 5D.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 13E — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 13E — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 13E — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc13e.user_id', c.user_id::text, true),
    set_config('app.mc13e.simulacao_id', s.id::text, true),
    set_config('app.mc13e.empresa_id', s.empresa_id::text, true),
    set_config('app.mc13e.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc13e.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select pg_temp.mc13e_add_result(
  '00_setup_fixture_13e',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc13e.simulacao_id', true),
    'politica_id', current_setting('app.mc13e.politica_id', true),
    'data_referencia', current_setting('app.mc13e.data_referencia', true),
    'data_ato', current_setting('app.mc13e.data_ato', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc13e.simulacao_id', true)::uuid as simulacao_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    current_setting('app.mc13e.data_ato', true)::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo','entrada',
        'descricao','Sinal ato 13E',
        'valor','18000.00',
        'data', current_setting('app.mc13e.data_ato', true)
      ),
      jsonb_build_object(
        'grupo','mensais',
        'descricao','Mensais 13E',
        'valor','3000.00',
        'quantidade',6,
        'mes_ano', current_setting('app.mc13e.mes_mensais', true)
      ),
      jsonb_build_object(
        'grupo','intermediarias',
        'descricao','Intermediária 13E',
        'valor','10000.00',
        'quantidade',2,
        'mes_ano', current_setting('app.mc13e.mes_intermediarias', true)
      ),
      jsonb_build_object(
        'grupo','periodicidade',
        'descricao','Periodicidade simbólica 13E',
        'valor',0,
        'mes_ano', current_setting('app.mc13e.mes_mensais', true)
      )
    ),
    jsonb_build_object('origem_teste', '13e')
  ) as payload
  from ctx
)
select set_config('app.mc13e.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc13e.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcelas_ranked as (
  select
    fp.id,
    fp.data_atual,
    row_number() over (order by fp.data_atual asc, fp.valor_atual desc, fp.id asc) as rn
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > current_setting('app.mc13e.data_referencia', true)::date
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
    and coalesce(fp.pode_receber_postergacao, false) = true
    and coalesce(fp.pode_receber_vpl, false) = true
),
setups as (
  select
    set_config('app.mc13e.agenda_id', (select id::text from agenda), true),
    set_config('app.mc13e.parcela_1_id', (select id::text from parcelas_ranked where rn = 1), true),
    set_config('app.mc13e.parcela_2_id', (select id::text from parcelas_ranked where rn = 2), true),
    set_config('app.mc13e.parcela_3_id', (select id::text from parcelas_ranked where rn = 3), true),
    set_config('app.mc13e.parcela_4_id', (select id::text from parcelas_ranked where rn = 4), true),
    set_config('app.mc13e.parcela_3_data_atual', (select data_atual::text from parcelas_ranked where rn = 3), true),
    set_config('app.mc13e.parcela_3_data_destino', (select (data_atual + interval '60 days')::date::text from parcelas_ranked where rn = 3), true)
)
select pg_temp.mc13e_add_result(
  '00b_agenda_parcelas_fixture_13e',
  case
    when current_setting('app.mc13e.agenda_id', true) <> ''
     and current_setting('app.mc13e.parcela_1_id', true) <> ''
     and current_setting('app.mc13e.parcela_2_id', true) <> ''
     and current_setting('app.mc13e.parcela_3_id', true) <> ''
     and current_setting('app.mc13e.parcela_4_id', true) <> ''
     and current_setting('app.mc13e.parcela_3_data_destino', true)::date > current_setting('app.mc13e.parcela_3_data_atual', true)::date
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc13e.agenda_id', true),
    'parcela_1_id', current_setting('app.mc13e.parcela_1_id', true),
    'parcela_2_id', current_setting('app.mc13e.parcela_2_id', true),
    'parcela_3_id', current_setting('app.mc13e.parcela_3_id', true),
    'parcela_4_id', current_setting('app.mc13e.parcela_4_id', true),
    'parcela_3_data_atual', current_setting('app.mc13e.parcela_3_data_atual', true),
    'parcela_3_data_destino', current_setting('app.mc13e.parcela_3_data_destino', true),
    'qtd_parcelas_elegiveis', (select count(*) from parcelas_ranked)
  )
)
from setups;

set local role authenticated;

with chamada_5b_op1 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13e.simulacao_id', true)::uuid,
    current_setting('app.mc13e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13e.parcela_1_id', true)::uuid,
    current_setting('app.mc13e.data_referencia', true)::date,
    null,
    null,
    jsonb_build_object('origem_teste', '13e', 'op', 'op1_antecipacao_confirmada')
  ) as payload
)
select
  set_config('app.mc13e.payload_5b_op1', coalesce((select payload::text from chamada_5b_op1), 'null'), true),
  set_config('app.mc13e.op1_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op1), ''), true);

with chamada_5b_op2 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13e.simulacao_id', true)::uuid,
    current_setting('app.mc13e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13e.parcela_2_id', true)::uuid,
    current_setting('app.mc13e.data_referencia', true)::date,
    null,
    null,
    jsonb_build_object('origem_teste', '13e', 'op', 'op2_antecipacao_cancelada')
  ) as payload
)
select
  set_config('app.mc13e.payload_5b_op2', coalesce((select payload::text from chamada_5b_op2), 'null'), true),
  set_config('app.mc13e.op2_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op2), ''), true);

with chamada_5b_op3 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13e.simulacao_id', true)::uuid,
    current_setting('app.mc13e.agenda_id', true)::uuid,
    'postergacao',
    current_setting('app.mc13e.parcela_3_id', true)::uuid,
    current_setting('app.mc13e.data_referencia', true)::date,
    current_setting('app.mc13e.parcela_3_data_destino', true)::date,
    null,
    jsonb_build_object(
      'origem_teste', '13e',
      'op', 'op3_postergacao_simulada',
      'data_atual_parcela', current_setting('app.mc13e.parcela_3_data_atual', true),
      'data_destino_calculada', current_setting('app.mc13e.parcela_3_data_destino', true)
    )
  ) as payload
)
select
  set_config('app.mc13e.payload_5b_op3', coalesce((select payload::text from chamada_5b_op3), 'null'), true),
  set_config('app.mc13e.op3_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op3), ''), true);

with chamada_5b_op4 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13e.simulacao_id', true)::uuid,
    current_setting('app.mc13e.agenda_id', true)::uuid,
    'vpl',
    current_setting('app.mc13e.parcela_4_id', true)::uuid,
    current_setting('app.mc13e.data_referencia', true)::date,
    null,
    null,
    jsonb_build_object('origem_teste', '13e', 'op', 'op4_vpl_simulada', 'vpl_aplicado_pct', 3.00)
  ) as payload
)
select
  set_config('app.mc13e.payload_5b_op4', coalesce((select payload::text from chamada_5b_op4), 'null'), true),
  set_config('app.mc13e.op4_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op4), ''), true);

with chamada_5c_confirmar_op1 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    current_setting('app.mc13e.op1_id', true)::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '13e', 'observacao', 'confirmação fixture para filtro status')
  ) as payload
)
select set_config('app.mc13e.payload_5c_confirmar_op1', coalesce((select payload::text from chamada_5c_confirmar_op1), 'null'), true);

with chamada_5c_cancelar_op2 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    current_setting('app.mc13e.op2_id', true)::uuid,
    'cancelar',
    'Cancelamento fixture 13E para filtro status',
    jsonb_build_object('origem_teste', '13e', 'observacao', 'cancelamento fixture para filtro status')
  ) as payload
)
select set_config('app.mc13e.payload_5c_cancelar_op2', coalesce((select payload::text from chamada_5c_cancelar_op2), 'null'), true);

reset role;

select pg_temp.mc13e_add_result(
  '01_fixture_5b_5c_preparada_para_filtros',
  case
    when current_setting('app.mc13e.payload_5b_op1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.payload_5b_op2', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.payload_5b_op3', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.payload_5b_op4', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.payload_5c_confirmar_op1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.payload_5c_confirmar_op1', true)::jsonb->'operacao'->>'status_operacao' = 'confirmada'
     and current_setting('app.mc13e.payload_5c_cancelar_op2', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.payload_5c_cancelar_op2', true)::jsonb->'operacao'->>'status_operacao' = 'cancelada'
     and current_setting('app.mc13e.op1_id', true) <> ''
     and current_setting('app.mc13e.op2_id', true) <> ''
     and current_setting('app.mc13e.op3_id', true) <> ''
     and current_setting('app.mc13e.op4_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'op1_antecipacao_confirmada', current_setting('app.mc13e.op1_id', true),
    'op2_antecipacao_cancelada', current_setting('app.mc13e.op2_id', true),
    'op3_postergacao_simulada', current_setting('app.mc13e.op3_id', true),
    'op4_vpl_simulada', current_setting('app.mc13e.op4_id', true),
    'postergacao_data_atual', current_setting('app.mc13e.parcela_3_data_atual', true),
    'postergacao_data_destino', current_setting('app.mc13e.parcela_3_data_destino', true)
  )
);

set local role authenticated;

select set_config('app.mc13e.list_all', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  null,
  jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.list_agenda', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_status_confirmada', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('status_operacao', 'confirmada', 'limit', 50, 'offset', 0, 'order_by', 'status_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_status_cancelada', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('status_operacao', 'cancelada', 'limit', 50, 'offset', 0, 'order_by', 'status_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_status_simulada', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('status_operacao', 'simulada', 'limit', 50, 'offset', 0, 'order_by', 'tipo_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_tipo_antecipacao', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('tipo_operacao', 'antecipacao', 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_tipo_postergacao', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('tipo_operacao', 'postergacao', 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_tipo_vpl', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('tipo_operacao', 'vpl', 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_visivel_false', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('visivel_cliente', false, 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_data_hoje', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('data_de', current_date::text, 'data_ate', current_date::text, 'limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.filter_data_futura_sem_resultado', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object(
    'data_de', current_setting('app.mc13e.data_sem_resultado_de', true),
    'data_ate', current_setting('app.mc13e.data_sem_resultado_ate', true),
    'limit', 50,
    'offset', 0,
    'order_by', 'created_at',
    'order_dir', 'asc'
  )
)::text, true);

select set_config('app.mc13e.page_1', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 2, 'offset', 0, 'order_by', 'tipo_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.page_2', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 2, 'offset', 2, 'order_by', 'tipo_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.order_status_asc', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'status_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.order_status_desc', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'status_operacao', 'order_dir', 'desc')
)::text, true);

select set_config('app.mc13e.order_tipo_asc', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'tipo_operacao', 'order_dir', 'asc')
)::text, true);

select set_config('app.mc13e.order_tipo_desc', public.mesa_cliente_listar_operacoes_financeiras_admin(
  current_setting('app.mc13e.simulacao_id', true)::uuid,
  current_setting('app.mc13e.agenda_id', true)::uuid,
  jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'tipo_operacao', 'order_dir', 'desc')
)::text, true);

reset role;

select pg_temp.mc13e_add_result(
  '02_listagem_base_e_agenda_id',
  case
    when current_setting('app.mc13e.list_all', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13e.list_all', true)::jsonb->>'fase' = '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN'
     and current_setting('app.mc13e.list_all', true)::jsonb->>'readonly' = 'true'
     and (current_setting('app.mc13e.list_all', true)::jsonb->>'total')::integer = 4
     and jsonb_array_length(current_setting('app.mc13e.list_all', true)::jsonb->'operacoes') = 4
     and (current_setting('app.mc13e.list_agenda', true)::jsonb->>'total')::integer = 4
     and current_setting('app.mc13e.list_agenda', true)::jsonb->>'agenda_id' = current_setting('app.mc13e.agenda_id', true)
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'total_sem_agenda', current_setting('app.mc13e.list_all', true)::jsonb->>'total',
    'total_com_agenda', current_setting('app.mc13e.list_agenda', true)::jsonb->>'total',
    'agenda_id_retorno', current_setting('app.mc13e.list_agenda', true)::jsonb->>'agenda_id'
  )
);

select pg_temp.mc13e_add_result(
  '03_filtro_status_operacao',
  case
    when (current_setting('app.mc13e.filter_status_confirmada', true)::jsonb->>'total')::integer = 1
     and pg_temp.mc13e_list_ids(current_setting('app.mc13e.filter_status_confirmada', true)::jsonb) = array[current_setting('app.mc13e.op1_id', true)::uuid]
     and pg_temp.mc13e_list_statuses(current_setting('app.mc13e.filter_status_confirmada', true)::jsonb) = array['confirmada']::text[]
     and (current_setting('app.mc13e.filter_status_cancelada', true)::jsonb->>'total')::integer = 1
     and pg_temp.mc13e_list_ids(current_setting('app.mc13e.filter_status_cancelada', true)::jsonb) = array[current_setting('app.mc13e.op2_id', true)::uuid]
     and pg_temp.mc13e_list_statuses(current_setting('app.mc13e.filter_status_cancelada', true)::jsonb) = array['cancelada']::text[]
     and (current_setting('app.mc13e.filter_status_simulada', true)::jsonb->>'total')::integer = 2
     and pg_temp.mc13e_list_statuses(current_setting('app.mc13e.filter_status_simulada', true)::jsonb) = array['simulada', 'simulada']::text[]
     and current_setting('app.mc13e.filter_status_confirmada', true)::jsonb->'filtros_aplicados'->>'status_operacao' = 'confirmada'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'confirmada_ids', pg_temp.mc13e_list_ids(current_setting('app.mc13e.filter_status_confirmada', true)::jsonb),
    'cancelada_ids', pg_temp.mc13e_list_ids(current_setting('app.mc13e.filter_status_cancelada', true)::jsonb),
    'simulada_statuses', pg_temp.mc13e_list_statuses(current_setting('app.mc13e.filter_status_simulada', true)::jsonb)
  )
);

select pg_temp.mc13e_add_result(
  '04_filtro_tipo_operacao',
  case
    when (current_setting('app.mc13e.filter_tipo_antecipacao', true)::jsonb->>'total')::integer = 2
     and pg_temp.mc13e_list_tipos(current_setting('app.mc13e.filter_tipo_antecipacao', true)::jsonb) = array['antecipacao', 'antecipacao']::text[]
     and (current_setting('app.mc13e.filter_tipo_postergacao', true)::jsonb->>'total')::integer = 1
     and pg_temp.mc13e_list_tipos(current_setting('app.mc13e.filter_tipo_postergacao', true)::jsonb) = array['postergacao']::text[]
     and (current_setting('app.mc13e.filter_tipo_vpl', true)::jsonb->>'total')::integer = 1
     and pg_temp.mc13e_list_tipos(current_setting('app.mc13e.filter_tipo_vpl', true)::jsonb) = array['vpl']::text[]
     and current_setting('app.mc13e.filter_tipo_vpl', true)::jsonb->'filtros_aplicados'->>'tipo_operacao' = 'vpl'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'antecipacao_tipos', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.filter_tipo_antecipacao', true)::jsonb),
    'postergacao_tipos', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.filter_tipo_postergacao', true)::jsonb),
    'vpl_tipos', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.filter_tipo_vpl', true)::jsonb)
  )
);

select pg_temp.mc13e_add_result(
  '05_filtros_visibilidade_e_data',
  case
    when (current_setting('app.mc13e.filter_visivel_false', true)::jsonb->>'total')::integer = 4
     and current_setting('app.mc13e.filter_visivel_false', true)::jsonb->'filtros_aplicados'->>'visivel_cliente' = 'false'
     and (current_setting('app.mc13e.filter_data_hoje', true)::jsonb->>'total')::integer = 4
     and (current_setting('app.mc13e.filter_data_futura_sem_resultado', true)::jsonb->>'total')::integer = 0
     and jsonb_array_length(current_setting('app.mc13e.filter_data_futura_sem_resultado', true)::jsonb->'operacoes') = 0
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'visivel_false_total', current_setting('app.mc13e.filter_visivel_false', true)::jsonb->>'total',
    'data_hoje_total', current_setting('app.mc13e.filter_data_hoje', true)::jsonb->>'total',
    'data_futura_total', current_setting('app.mc13e.filter_data_futura_sem_resultado', true)::jsonb->>'total',
    'data_futura_de', current_setting('app.mc13e.data_sem_resultado_de', true),
    'data_futura_ate', current_setting('app.mc13e.data_sem_resultado_ate', true)
  )
);

select pg_temp.mc13e_add_result(
  '06_paginacao_limit_offset',
  case
    when current_setting('app.mc13e.page_1', true)::jsonb->>'limit' = '2'
     and current_setting('app.mc13e.page_1', true)::jsonb->>'offset' = '0'
     and current_setting('app.mc13e.page_2', true)::jsonb->>'limit' = '2'
     and current_setting('app.mc13e.page_2', true)::jsonb->>'offset' = '2'
     and (current_setting('app.mc13e.page_1', true)::jsonb->>'total')::integer = 4
     and (current_setting('app.mc13e.page_2', true)::jsonb->>'total')::integer = 4
     and jsonb_array_length(current_setting('app.mc13e.page_1', true)::jsonb->'operacoes') = 2
     and jsonb_array_length(current_setting('app.mc13e.page_2', true)::jsonb->'operacoes') = 2
     and not (pg_temp.mc13e_list_ids(current_setting('app.mc13e.page_1', true)::jsonb) && pg_temp.mc13e_list_ids(current_setting('app.mc13e.page_2', true)::jsonb))
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'page_1_ids', pg_temp.mc13e_list_ids(current_setting('app.mc13e.page_1', true)::jsonb),
    'page_2_ids', pg_temp.mc13e_list_ids(current_setting('app.mc13e.page_2', true)::jsonb),
    'page_1_tipos', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.page_1', true)::jsonb),
    'page_2_tipos', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.page_2', true)::jsonb)
  )
);

select pg_temp.mc13e_add_result(
  '07_order_by_status_operacao_asc_desc',
  case
    when current_setting('app.mc13e.order_status_asc', true)::jsonb->>'order_by' = 'status_operacao'
     and current_setting('app.mc13e.order_status_asc', true)::jsonb->>'order_dir' = 'asc'
     and current_setting('app.mc13e.order_status_desc', true)::jsonb->>'order_by' = 'status_operacao'
     and current_setting('app.mc13e.order_status_desc', true)::jsonb->>'order_dir' = 'desc'
     and pg_temp.mc13e_list_statuses(current_setting('app.mc13e.order_status_asc', true)::jsonb) = array['cancelada', 'confirmada', 'simulada', 'simulada']::text[]
     and pg_temp.mc13e_list_statuses(current_setting('app.mc13e.order_status_desc', true)::jsonb) = array['simulada', 'simulada', 'confirmada', 'cancelada']::text[]
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'status_asc', pg_temp.mc13e_list_statuses(current_setting('app.mc13e.order_status_asc', true)::jsonb),
    'status_desc', pg_temp.mc13e_list_statuses(current_setting('app.mc13e.order_status_desc', true)::jsonb)
  )
);

select pg_temp.mc13e_add_result(
  '08_order_by_tipo_operacao_asc_desc',
  case
    when current_setting('app.mc13e.order_tipo_asc', true)::jsonb->>'order_by' = 'tipo_operacao'
     and current_setting('app.mc13e.order_tipo_asc', true)::jsonb->>'order_dir' = 'asc'
     and current_setting('app.mc13e.order_tipo_desc', true)::jsonb->>'order_by' = 'tipo_operacao'
     and current_setting('app.mc13e.order_tipo_desc', true)::jsonb->>'order_dir' = 'desc'
     and pg_temp.mc13e_list_tipos(current_setting('app.mc13e.order_tipo_asc', true)::jsonb) = array['antecipacao', 'antecipacao', 'postergacao', 'vpl']::text[]
     and pg_temp.mc13e_list_tipos(current_setting('app.mc13e.order_tipo_desc', true)::jsonb) = array['vpl', 'postergacao', 'antecipacao', 'antecipacao']::text[]
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'tipo_asc', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.order_tipo_asc', true)::jsonb),
    'tipo_desc', pg_temp.mc13e_list_tipos(current_setting('app.mc13e.order_tipo_desc', true)::jsonb)
  )
);

set local role authenticated;

select pg_temp.mc13e_expect_error(
  '09a_order_by_invalido_bloqueado',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('order_by', 'empresa_id'))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true)
  ),
  'order_by inválido foi aceito'
);

select pg_temp.mc13e_expect_error(
  '09b_order_dir_invalido_bloqueado',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('order_dir', 'sideways'))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true)
  ),
  'order_dir inválido foi aceito'
);

select pg_temp.mc13e_expect_error(
  '09c_offset_negativo_bloqueado',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('offset', -1))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true)
  ),
  'offset negativo foi aceito'
);

select pg_temp.mc13e_expect_error(
  '09d_data_de_formato_invalido_bloqueada',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('data_de', '31/10/2099'))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true)
  ),
  'data_de inválida foi aceita'
);

select pg_temp.mc13e_expect_error(
  '09e_data_ate_formato_invalido_bloqueada',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('data_ate', '31/10/2099'))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true)
  ),
  'data_ate inválida foi aceita'
);

select pg_temp.mc13e_expect_error(
  '09f_data_de_maior_que_data_ate_bloqueada',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('data_de', %L, 'data_ate', %L))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true),
    current_setting('app.mc13e.data_sem_resultado_ate', true),
    current_setting('app.mc13e.data_sem_resultado_de', true)
  ),
  'range de data invertido foi aceito'
);

select pg_temp.mc13e_expect_error(
  '09g_visivel_cliente_nao_booleano_bloqueado',
  '22023',
  format(
    $sql$select public.mesa_cliente_listar_operacoes_financeiras_admin(%L::uuid, %L::uuid, jsonb_build_object('visivel_cliente', 'false'))$sql$,
    current_setting('app.mc13e.simulacao_id', true),
    current_setting('app.mc13e.agenda_id', true)
  ),
  'visivel_cliente string foi aceito'
);

reset role;

select pg_temp.mc13e_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Teste 13E encerra com ROLLBACK. A fixture 4B/5B/5C não deve permanecer no banco.',
    'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
    'validacao', 'filtros, paginação, ordenação e allowlists'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc13e.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
