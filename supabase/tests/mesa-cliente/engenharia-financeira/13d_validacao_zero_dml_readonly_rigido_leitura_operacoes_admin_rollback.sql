-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- 13D — Zero DML / read-only rígido das RPCs administrativas de leitura de operações financeiras.
--
-- Pré-requisitos:
--   - Fase 5B aplicada;
--   - Fase 5C aplicada;
--   - Migration 5D aplicada:
--     supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
--
-- Objetivo:
--   Criar fixture transacional, preparar operações 5B/5C e validar que as RPCs 5D:
--     - não alteram mesa_simulacoes;
--     - não alteram mesa_cliente_agendas_financeiras;
--     - não alteram mesa_cliente_fluxo_parcelas;
--     - não alteram mesa_cliente_fluxo_operacoes;
--     - não alteram updated_at;
--     - não alteram checksum_operacao;
--     - não executam UPDATE silencioso mesmo sem mudança aparente de valores.
--
-- Critério técnico diferencial:
--   Além de hashes completos dos registros, este teste compara xmin das linhas.
--   Isso detecta UPDATE no PostgreSQL mesmo quando o UPDATE grava o mesmo valor,
--   caso clássico em que hash de conteúdo e updated_at poderiam continuar iguais.
--
-- Segurança:
--   - a fixture 4B/5B/5C é a única mutação intencional;
--   - os snapshots são tirados depois da fixture e antes das chamadas 5D;
--   - a etapa 5D validada é exclusivamente leitura;
--   - encerra com ROLLBACK.

begin;

select set_config('app.mc13d.results', '[]', true);
select set_config('app.mc13d.user_id', '', true);
select set_config('app.mc13d.simulacao_id', '', true);
select set_config('app.mc13d.empresa_id', '', true);
select set_config('app.mc13d.empreendimento_id', '', true);
select set_config('app.mc13d.politica_id', '', true);
select set_config('app.mc13d.agenda_id', '', true);
select set_config('app.mc13d.parcela_1_id', '', true);
select set_config('app.mc13d.parcela_2_id', '', true);
select set_config('app.mc13d.parcela_3_id', '', true);
select set_config('app.mc13d.op1_id', '', true);
select set_config('app.mc13d.op2_id', '', true);
select set_config('app.mc13d.op3_id', '', true);
select set_config('app.mc13d.payload_4b', 'null', true);
select set_config('app.mc13d.payload_5b_op1', 'null', true);
select set_config('app.mc13d.payload_5b_op2', 'null', true);
select set_config('app.mc13d.payload_5b_op3', 'null', true);
select set_config('app.mc13d.payload_5c_confirmar_op1', 'null', true);
select set_config('app.mc13d.payload_5c_cancelar_op2', 'null', true);
select set_config('app.mc13d.snapshot_before_5d', 'null', true);
select set_config('app.mc13d.snapshot_after_5d', 'null', true);
select set_config('app.mc13d.payload_5d_list_all_1', 'null', true);
select set_config('app.mc13d.payload_5d_list_agenda_1', 'null', true);
select set_config('app.mc13d.payload_5d_list_agenda_2', 'null', true);
select set_config('app.mc13d.payload_5d_obter_op1_1', 'null', true);
select set_config('app.mc13d.payload_5d_obter_op1_2', 'null', true);
select set_config('app.mc13d.payload_5d_obter_op2', 'null', true);
select set_config('app.mc13d.payload_5d_obter_op3', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.mc13d_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc13d.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc13d.results',
    (v_atual || jsonb_build_array(jsonb_build_object(
      'bloco', p_bloco,
      'status', p_status,
      'detalhe', coalesce(p_detalhe, '{}'::jsonb)
    )))::text,
    true
  );
end;
$$;

create or replace function pg_temp.mc13d_snapshot(
  p_simulacao_id uuid,
  p_agenda_id uuid
)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'simulacao_id', p_simulacao_id,
    'agenda_id', p_agenda_id,

    'simulacao_full_hash', (
      select md5(coalesce(jsonb_agg(to_jsonb(s.*) order by s.id)::text, '[]'))
      from public.mesa_simulacoes s
      where s.id = p_simulacao_id
    ),
    'agenda_full_hash', (
      select md5(coalesce(jsonb_agg(to_jsonb(a.*) order by a.id)::text, '[]'))
      from public.mesa_cliente_agendas_financeiras a
      where a.id = p_agenda_id
        and a.simulacao_id = p_simulacao_id
    ),
    'parcelas_full_hash', (
      select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]'))
      from public.mesa_cliente_fluxo_parcelas fp
      where fp.agenda_id = p_agenda_id
        and fp.simulacao_id = p_simulacao_id
    ),
    'operacoes_full_hash', (
      select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]'))
      from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id
        and o.simulacao_id = p_simulacao_id
    ),

    'simulacao_versions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', s.id,
        'xmin', s.xmin::text
      ) order by s.id), '[]'::jsonb)
      from public.mesa_simulacoes s
      where s.id = p_simulacao_id
    ),
    'agenda_versions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', a.id,
        'xmin', a.xmin::text,
        'updated_at', a.updated_at
      ) order by a.id), '[]'::jsonb)
      from public.mesa_cliente_agendas_financeiras a
      where a.id = p_agenda_id
        and a.simulacao_id = p_simulacao_id
    ),
    'parcelas_versions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', fp.id,
        'xmin', fp.xmin::text,
        'updated_at', fp.updated_at
      ) order by fp.id), '[]'::jsonb)
      from public.mesa_cliente_fluxo_parcelas fp
      where fp.agenda_id = p_agenda_id
        and fp.simulacao_id = p_simulacao_id
    ),
    'operacoes_versions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', o.id,
        'xmin', o.xmin::text,
        'updated_at', o.updated_at,
        'status_operacao', o.status_operacao,
        'checksum_operacao', o.checksum_operacao
      ) order by o.id), '[]'::jsonb)
      from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id
        and o.simulacao_id = p_simulacao_id
    ),

    'qtd_simulacoes', (
      select count(*) from public.mesa_simulacoes s where s.id = p_simulacao_id
    ),
    'qtd_agendas', (
      select count(*) from public.mesa_cliente_agendas_financeiras a
      where a.id = p_agenda_id and a.simulacao_id = p_simulacao_id
    ),
    'qtd_parcelas', (
      select count(*) from public.mesa_cliente_fluxo_parcelas fp
      where fp.agenda_id = p_agenda_id and fp.simulacao_id = p_simulacao_id
    ),
    'qtd_operacoes', (
      select count(*) from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id and o.simulacao_id = p_simulacao_id
    ),
    'qtd_confirmada', (
      select count(*) from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id
        and o.simulacao_id = p_simulacao_id
        and o.status_operacao = 'confirmada'
    ),
    'qtd_cancelada', (
      select count(*) from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id
        and o.simulacao_id = p_simulacao_id
        and o.status_operacao = 'cancelada'
    ),
    'qtd_simulada', (
      select count(*) from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id
        and o.simulacao_id = p_simulacao_id
        and o.status_operacao = 'simulada'
    ),
    'qtd_visivel_cliente', (
      select count(*) from public.mesa_cliente_fluxo_operacoes o
      where o.agenda_id = p_agenda_id
        and o.simulacao_id = p_simulacao_id
        and coalesce(o.visivel_cliente, false) = true
    )
  );
$$;

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
    'Teste rollback 13D zero DML leitura operações financeiras 5D',
    56000.00,
    16000.00,
    0,
    56000.00,
    jsonb_build_object('origem', 'teste_13d_5d_rollback', 'fixture_transacional', true),
    'Fixture transacional 13D. Deve sumir no ROLLBACK.'
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
    date '2099-09-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 13D para validação zero DML/read-only rígido das RPCs de leitura 5D.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 13D — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 13D — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 13D — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc13d.user_id', c.user_id::text, true),
    set_config('app.mc13d.simulacao_id', s.id::text, true),
    set_config('app.mc13d.empresa_id', s.empresa_id::text, true),
    set_config('app.mc13d.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc13d.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select pg_temp.mc13d_add_result(
  '00_setup_fixture_13d',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc13d.simulacao_id', true),
    'politica_id', current_setting('app.mc13d.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc13d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13d.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc13d.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-09-30',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','16000.00','data','2099-09-30'),
      jsonb_build_object('grupo','mensais','descricao','Mensais 13D','valor','2800.00','quantidade',4,'mes_ano','10/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária 13D','valor','9500.00','quantidade',2,'mes_ano','12/2099'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica 13D','valor',0,'mes_ano','11/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_13d')
  ) as payload
  from ctx
)
select set_config('app.mc13d.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc13d.simulacao_id', true)::uuid as simulacao_id
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
    row_number() over (order by fp.valor_atual desc, fp.data_atual desc, fp.id) as rn
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual >= 1000.00
    and fp.data_atual > date '2099-09-30'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
),
setups as (
  select
    set_config('app.mc13d.agenda_id', (select id::text from agenda), true),
    set_config('app.mc13d.parcela_1_id', (select id::text from parcelas_ranked where rn = 1), true),
    set_config('app.mc13d.parcela_2_id', (select id::text from parcelas_ranked where rn = 2), true),
    set_config('app.mc13d.parcela_3_id', (select id::text from parcelas_ranked where rn = 3), true)
)
select pg_temp.mc13d_add_result(
  '00b_agenda_parcelas_fixture_13d',
  case
    when current_setting('app.mc13d.agenda_id', true) <> ''
     and current_setting('app.mc13d.parcela_1_id', true) <> ''
     and current_setting('app.mc13d.parcela_2_id', true) <> ''
     and current_setting('app.mc13d.parcela_3_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc13d.agenda_id', true),
    'parcela_1_id', current_setting('app.mc13d.parcela_1_id', true),
    'parcela_2_id', current_setting('app.mc13d.parcela_2_id', true),
    'parcela_3_id', current_setting('app.mc13d.parcela_3_id', true),
    'qtd_parcelas_elegiveis', (select count(*) from parcelas_ranked)
  )
)
from setups;

set local role authenticated;

with chamada_5b_op1 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13d.parcela_1_id', true)::uuid,
    date '2099-09-30',
    null,
    1000.00,
    jsonb_build_object('origem_teste', '13d', 'op', 'op1_confirmada', 'observacao', 'operação fixture para zero DML 5D')
  ) as payload
)
select
  set_config('app.mc13d.payload_5b_op1', coalesce((select payload::text from chamada_5b_op1), 'null'), true),
  set_config('app.mc13d.op1_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op1), ''), true);

with chamada_5b_op2 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13d.parcela_2_id', true)::uuid,
    date '2099-09-30',
    null,
    1200.00,
    jsonb_build_object('origem_teste', '13d', 'op', 'op2_cancelada', 'observacao', 'operação fixture para zero DML 5D')
  ) as payload
)
select
  set_config('app.mc13d.payload_5b_op2', coalesce((select payload::text from chamada_5b_op2), 'null'), true),
  set_config('app.mc13d.op2_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op2), ''), true);

with chamada_5b_op3 as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13d.parcela_3_id', true)::uuid,
    date '2099-09-30',
    null,
    900.00,
    jsonb_build_object('origem_teste', '13d', 'op', 'op3_simulada', 'observacao', 'operação fixture para zero DML 5D')
  ) as payload
)
select
  set_config('app.mc13d.payload_5b_op3', coalesce((select payload::text from chamada_5b_op3), 'null'), true),
  set_config('app.mc13d.op3_id', coalesce((select payload->'operacao'->>'id' from chamada_5b_op3), ''), true);

with chamada_5c_confirmar_op1 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    current_setting('app.mc13d.op1_id', true)::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '13d', 'observacao', 'confirmação fixture antes do snapshot 5D')
  ) as payload
)
select set_config('app.mc13d.payload_5c_confirmar_op1', coalesce((select payload::text from chamada_5c_confirmar_op1), 'null'), true);

with chamada_5c_cancelar_op2 as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    current_setting('app.mc13d.op2_id', true)::uuid,
    'cancelar',
    'Cancelamento fixture 13D antes do snapshot read-only',
    jsonb_build_object('origem_teste', '13d', 'observacao', 'cancelamento fixture antes do snapshot 5D')
  ) as payload
)
select set_config('app.mc13d.payload_5c_cancelar_op2', coalesce((select payload::text from chamada_5c_cancelar_op2), 'null'), true);

reset role;

select set_config(
  'app.mc13d.snapshot_before_5d',
  pg_temp.mc13d_snapshot(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid
  )::text,
  true
);

select pg_temp.mc13d_add_result(
  '01_fixture_5b_5c_preparada_para_readonly',
  case
    when current_setting('app.mc13d.payload_5b_op1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5b_op2', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5b_op3', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5c_confirmar_op1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5c_confirmar_op1', true)::jsonb->'operacao'->>'status_operacao' = 'confirmada'
     and current_setting('app.mc13d.payload_5c_cancelar_op2', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5c_cancelar_op2', true)::jsonb->'operacao'->>'status_operacao' = 'cancelada'
     and current_setting('app.mc13d.op1_id', true) <> ''
     and current_setting('app.mc13d.op2_id', true) <> ''
     and current_setting('app.mc13d.op3_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'op1_id', current_setting('app.mc13d.op1_id', true),
    'op2_id', current_setting('app.mc13d.op2_id', true),
    'op3_id', current_setting('app.mc13d.op3_id', true),
    'snapshot_before_5d', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb
  )
);

select pg_temp.mc13d_add_result(
  '02_snapshot_before_tem_base_valida',
  case
    when (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_simulacoes')::integer = 1
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_agendas')::integer = 1
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_parcelas')::integer >= 3
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_operacoes')::integer = 3
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_confirmada')::integer = 1
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_cancelada')::integer = 1
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_simulada')::integer = 1
     and (current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_visivel_cliente')::integer = 0
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'snapshot_before_5d', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb
  )
);

set local role authenticated;

with chamada as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    null,
    jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13d.payload_5d_list_all_1', coalesce((select payload::text from chamada), 'null'), true);

with chamada as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid,
    jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13d.payload_5d_list_agenda_1', coalesce((select payload::text from chamada), 'null'), true);

with chamada as materialized (
  select public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid,
    jsonb_build_object('limit', 50, 'offset', 0, 'order_by', 'created_at', 'order_dir', 'asc')
  ) as payload
)
select set_config('app.mc13d.payload_5d_list_agenda_2', coalesce((select payload::text from chamada), 'null'), true);

with chamada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    current_setting('app.mc13d.op1_id', true)::uuid,
    jsonb_build_object('origem_teste', '13d_readonly_primeira_leitura')
  ) as payload
)
select set_config('app.mc13d.payload_5d_obter_op1_1', coalesce((select payload::text from chamada), 'null'), true);

with chamada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    current_setting('app.mc13d.op1_id', true)::uuid,
    jsonb_build_object('origem_teste', '13d_readonly_segunda_leitura')
  ) as payload
)
select set_config('app.mc13d.payload_5d_obter_op1_2', coalesce((select payload::text from chamada), 'null'), true);

with chamada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    current_setting('app.mc13d.op2_id', true)::uuid,
    jsonb_build_object('origem_teste', '13d_readonly_cancelada')
  ) as payload
)
select set_config('app.mc13d.payload_5d_obter_op2', coalesce((select payload::text from chamada), 'null'), true);

with chamada as materialized (
  select public.mesa_cliente_obter_operacao_financeira_admin(
    current_setting('app.mc13d.op3_id', true)::uuid,
    jsonb_build_object('origem_teste', '13d_readonly_simulada')
  ) as payload
)
select set_config('app.mc13d.payload_5d_obter_op3', coalesce((select payload::text from chamada), 'null'), true);

reset role;

select set_config(
  'app.mc13d.snapshot_after_5d',
  pg_temp.mc13d_snapshot(
    current_setting('app.mc13d.simulacao_id', true)::uuid,
    current_setting('app.mc13d.agenda_id', true)::uuid
  )::text,
  true
);

select pg_temp.mc13d_add_result(
  '03_chamadas_5d_retorno_canonico_readonly',
  case
    when current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'fase' = '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'cliente_safe' = 'false'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'dml_financeiro' = 'false'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'escopo_dml' = 'nenhum'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'altera_agenda' = 'false'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'altera_parcelas' = 'false'
     and current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'recalcula_operacao' = 'false'
     and (current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'total')::integer = 3
     and jsonb_array_length(current_setting('app.mc13d.payload_5d_list_agenda_1', true)::jsonb->'operacoes') = 3
     and current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->>'fase' = '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN'
     and current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc13d.payload_5d_obter_op2', true)::jsonb->'operacao'->>'status_operacao' = 'cancelada'
     and current_setting('app.mc13d.payload_5d_obter_op3', true)::jsonb->'operacao'->>'status_operacao' = 'simulada'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'listagem_flags', jsonb_build_object(
      'fase', current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'fase',
      'readonly', current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'readonly',
      'dml_financeiro', current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'dml_financeiro',
      'escopo_dml', current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'escopo_dml',
      'total', current_setting('app.mc13d.payload_5d_list_all_1', true)::jsonb->>'total'
    ),
    'detalhe_op1_flags', jsonb_build_object(
      'fase', current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->>'fase',
      'readonly', current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->>'readonly',
      'status_operacao', current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->'operacao'->>'status_operacao'
    )
  )
);

select pg_temp.mc13d_add_result(
  '04_hashes_completos_preservados',
  case
    when current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'simulacao_full_hash'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'simulacao_full_hash'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'agenda_full_hash'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'agenda_full_hash'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'parcelas_full_hash'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'parcelas_full_hash'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'operacoes_full_hash'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'operacoes_full_hash'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'before', jsonb_build_object(
      'simulacao_full_hash', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'simulacao_full_hash',
      'agenda_full_hash', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'agenda_full_hash',
      'parcelas_full_hash', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'parcelas_full_hash',
      'operacoes_full_hash', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'operacoes_full_hash'
    ),
    'after', jsonb_build_object(
      'simulacao_full_hash', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'simulacao_full_hash',
      'agenda_full_hash', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'agenda_full_hash',
      'parcelas_full_hash', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'parcelas_full_hash',
      'operacoes_full_hash', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'operacoes_full_hash'
    )
  )
);

select pg_temp.mc13d_add_result(
  '05_xmin_versions_preservados_sem_update_silencioso',
  case
    when current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'simulacao_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'simulacao_versions'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'agenda_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'agenda_versions'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'parcelas_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'parcelas_versions'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'operacoes_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'operacoes_versions'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'criterio', 'xmin igual antes/depois detecta ausência real de UPDATE, inclusive UPDATE de mesmo valor',
    'before_versions', jsonb_build_object(
      'simulacao', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'simulacao_versions',
      'agenda', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'agenda_versions',
      'parcelas', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'parcelas_versions',
      'operacoes', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'operacoes_versions'
    ),
    'after_versions', jsonb_build_object(
      'simulacao', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'simulacao_versions',
      'agenda', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'agenda_versions',
      'parcelas', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'parcelas_versions',
      'operacoes', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'operacoes_versions'
    )
  )
);

select pg_temp.mc13d_add_result(
  '06_contagens_status_updated_at_checksum_preservados',
  case
    when current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_simulacoes'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_simulacoes'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_agendas'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_agendas'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_parcelas'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_parcelas'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_operacoes'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_operacoes'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_confirmada'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_confirmada'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_cancelada'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_cancelada'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_simulada'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_simulada'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_visivel_cliente'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_visivel_cliente'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'agenda_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'agenda_versions'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'parcelas_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'parcelas_versions'
     and current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->'operacoes_versions'
       = current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->'operacoes_versions'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'before_contagens', jsonb_build_object(
      'qtd_simulacoes', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_simulacoes',
      'qtd_agendas', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_agendas',
      'qtd_parcelas', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_parcelas',
      'qtd_operacoes', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_operacoes',
      'qtd_confirmada', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_confirmada',
      'qtd_cancelada', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_cancelada',
      'qtd_simulada', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_simulada',
      'qtd_visivel_cliente', current_setting('app.mc13d.snapshot_before_5d', true)::jsonb->>'qtd_visivel_cliente'
    ),
    'after_contagens', jsonb_build_object(
      'qtd_simulacoes', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_simulacoes',
      'qtd_agendas', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_agendas',
      'qtd_parcelas', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_parcelas',
      'qtd_operacoes', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_operacoes',
      'qtd_confirmada', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_confirmada',
      'qtd_cancelada', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_cancelada',
      'qtd_simulada', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_simulada',
      'qtd_visivel_cliente', current_setting('app.mc13d.snapshot_after_5d', true)::jsonb->>'qtd_visivel_cliente'
    )
  )
);

select pg_temp.mc13d_add_result(
  '07_leituras_repetidas_deterministicas_sem_efeito_colateral',
  case
    when md5(current_setting('app.mc13d.payload_5d_list_agenda_1', true)::jsonb::text)
       = md5(current_setting('app.mc13d.payload_5d_list_agenda_2', true)::jsonb::text)
     and current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->'operacao'
       = current_setting('app.mc13d.payload_5d_obter_op1_2', true)::jsonb->'operacao'
     and current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->'operacao'->>'checksum_operacao'
       = current_setting('app.mc13d.payload_5d_obter_op1_2', true)::jsonb->'operacao'->>'checksum_operacao'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'list_agenda_1_hash', md5(current_setting('app.mc13d.payload_5d_list_agenda_1', true)::jsonb::text),
    'list_agenda_2_hash', md5(current_setting('app.mc13d.payload_5d_list_agenda_2', true)::jsonb::text),
    'op1_primeira_leitura', current_setting('app.mc13d.payload_5d_obter_op1_1', true)::jsonb->'operacao',
    'op1_segunda_leitura', current_setting('app.mc13d.payload_5d_obter_op1_2', true)::jsonb->'operacao'
  )
);

select pg_temp.mc13d_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Teste 13D encerra com ROLLBACK. A fixture 4B/5B/5C não deve permanecer no banco.',
    'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
    'validacao', 'zero DML/read-only rígido',
    'criterio_extra', 'comparação de xmin para detectar UPDATE silencioso'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc13d.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
