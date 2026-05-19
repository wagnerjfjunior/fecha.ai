-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- 12C — Validação negativa e de segurança da confirmação/cancelamento.
--
-- Objetivo:
--   Validar bloqueios da RPC 5C sem mutação indevida:
--     - anon sem EXECUTE;
--     - authenticated sem auth.uid() bloqueado;
--     - operação inexistente bloqueada;
--     - ação inválida bloqueada;
--     - p_parametros não objeto bloqueado;
--     - payload com autoridade proibida bloqueado;
--     - cancelamento sem motivo bloqueado;
--     - confirmar operação cancelada bloqueado;
--     - cancelar operação confirmada bloqueado;
--     - negativos não mutam operações, agenda ou parcelas;
--     - rollback final.

begin;

select set_config('app.mc12c.user_id', '', true);
select set_config('app.mc12c.simulacao_id', '', true);
select set_config('app.mc12c.empresa_id', '', true);
select set_config('app.mc12c.empreendimento_id', '', true);
select set_config('app.mc12c.politica_id', '', true);
select set_config('app.mc12c.agenda_id', '', true);
select set_config('app.mc12c.parcela_cancelavel_id', '', true);
select set_config('app.mc12c.parcela_confirmavel_id', '', true);
select set_config('app.mc12c.parcela_simulada_id', '', true);
select set_config('app.mc12c.payload_op_cancelada_5b', 'null', true);
select set_config('app.mc12c.payload_op_confirmada_5b', 'null', true);
select set_config('app.mc12c.payload_op_simulada_5b', 'null', true);
select set_config('app.mc12c.payload_cancelamento_setup', 'null', true);
select set_config('app.mc12c.payload_confirmacao_setup', 'null', true);
select set_config('app.mc12c.snapshot_before_ops', 'null', true);
select set_config('app.mc12c.snapshot_after_setup', 'null', true);
select set_config('app.mc12c.snapshot_after_negativos', 'null', true);
select set_config('app.mc12c.neg_anon_grant', 'null', true);
select set_config('app.mc12c.neg_sem_auth', 'null', true);
select set_config('app.mc12c.neg_inexistente', 'null', true);
select set_config('app.mc12c.neg_acao_invalida', 'null', true);
select set_config('app.mc12c.neg_parametros_nao_objeto', 'null', true);
select set_config('app.mc12c.neg_payload_autoritativo', 'null', true);
select set_config('app.mc12c.neg_cancelamento_sem_motivo', 'null', true);
select set_config('app.mc12c.neg_confirmar_cancelada', 'null', true);
select set_config('app.mc12c.neg_cancelar_confirmada', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

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
    'Teste rollback 12C negativos segurança operação financeira 5C',
    48500.50,
    10000.50,
    0,
    48500.50,
    jsonb_build_object('origem', 'teste_12c_5c_rollback', 'fixture_transacional', true),
    'Fixture transacional 12C. Deve sumir no ROLLBACK.'
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
    date '2099-07-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 12C para validação negativa e segurança da RPC 5C.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 12C — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 12C — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 12C — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc12c.user_id', c.user_id::text, true),
    set_config('app.mc12c.simulacao_id', s.id::text, true),
    set_config('app.mc12c.empresa_id', s.empresa_id::text, true),
    set_config('app.mc12c.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc12c.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_12c' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc12c.simulacao_id', true),
    'politica_id', current_setting('app.mc12c.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc12c.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12c.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc12c.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-07-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-07-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',5,'mes_ano','08/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','09/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_12c')
  ) as payload
  from ctx
)
select set_config('app.mc12c.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc12c.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcelas_elegiveis as (
  select
    fp.id,
    row_number() over (order by fp.valor_atual desc, fp.data_atual desc, fp.id) as rn
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > date '2099-07-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
),
snapshot_before_ops as (
  select jsonb_build_object(
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id)
  ) as payload
),
setups as (
  select
    set_config('app.mc12c.agenda_id', (select id::text from agenda), true),
    set_config('app.mc12c.parcela_cancelavel_id', (select id::text from parcelas_elegiveis where rn = 1), true),
    set_config('app.mc12c.parcela_confirmavel_id', (select id::text from parcelas_elegiveis where rn = 2), true),
    set_config('app.mc12c.parcela_simulada_id', (select id::text from parcelas_elegiveis where rn = 3), true),
    set_config('app.mc12c.snapshot_before_ops', (select payload::text from snapshot_before_ops), true)
)
select
  '00b_agenda_parcelas_fixture_12c' as bloco,
  case
    when current_setting('app.mc12c.agenda_id', true) <> ''
     and current_setting('app.mc12c.parcela_cancelavel_id', true) <> ''
     and current_setting('app.mc12c.parcela_confirmavel_id', true) <> ''
     and current_setting('app.mc12c.parcela_simulada_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc12c.agenda_id', true),
    'parcela_cancelavel_id', current_setting('app.mc12c.parcela_cancelavel_id', true),
    'parcela_confirmavel_id', current_setting('app.mc12c.parcela_confirmavel_id', true),
    'parcela_simulada_id', current_setting('app.mc12c.parcela_simulada_id', true),
    'before_ops', current_setting('app.mc12c.snapshot_before_ops', true)::jsonb
  ) as detalhe
from setups;

set local role authenticated;

with op_cancelavel as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12c.simulacao_id', true)::uuid,
    current_setting('app.mc12c.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12c.parcela_cancelavel_id', true)::uuid,
    date '2099-07-31',
    null,
    5000.00,
    jsonb_build_object('origem_teste', '12c', 'cenario', 'op_cancelavel_para_bloquear_confirmar_cancelada')
  ) as payload
),
op_confirmavel as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12c.simulacao_id', true)::uuid,
    current_setting('app.mc12c.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12c.parcela_confirmavel_id', true)::uuid,
    date '2099-07-31',
    null,
    3000.00,
    jsonb_build_object('origem_teste', '12c', 'cenario', 'op_confirmavel_para_bloquear_cancelar_confirmada')
  ) as payload
),
op_simulada as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc12c.simulacao_id', true)::uuid,
    current_setting('app.mc12c.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc12c.parcela_simulada_id', true)::uuid,
    date '2099-07-31',
    null,
    1000.00,
    jsonb_build_object('origem_teste', '12c', 'cenario', 'op_simulada_para_negativos_basicos')
  ) as payload
),
setups as (
  select
    set_config('app.mc12c.payload_op_cancelada_5b', (select payload::text from op_cancelavel), true),
    set_config('app.mc12c.payload_op_confirmada_5b', (select payload::text from op_confirmavel), true),
    set_config('app.mc12c.payload_op_simulada_5b', (select payload::text from op_simulada), true)
)
select count(*) from setups;

with cancelar_setup as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12c.payload_op_cancelada_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'cancelar',
    'Setup 12C: operação cancelada para testar bloqueio de confirmação',
    jsonb_build_object('origem_teste', '12c', 'setup', 'cancelada')
  ) as payload
),
confirmar_setup as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    (current_setting('app.mc12c.payload_op_confirmada_5b', true)::jsonb->'operacao'->>'id')::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '12c', 'setup', 'confirmada')
  ) as payload
),
setups as (
  select
    set_config('app.mc12c.payload_cancelamento_setup', (select payload::text from cancelar_setup), true),
    set_config('app.mc12c.payload_confirmacao_setup', (select payload::text from confirmar_setup), true)
)
select count(*) from setups;

reset role;

with ctx as (
  select
    current_setting('app.mc12c.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12c.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after_setup as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_canceladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'operacoes_simuladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'simulada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'confirmado_por', o.confirmado_por, 'confirmado_em', o.confirmado_em, 'cancelado_por', o.cancelado_por, 'cancelado_em', o.cancelado_em, 'motivo_cancelamento', o.motivo_cancelamento, 'visivel_cliente', o.visivel_cliente) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12c.snapshot_after_setup', coalesce((select payload::text from snapshot_after_setup), 'null'), true);

select set_config(
  'app.mc12c.neg_anon_grant',
  jsonb_build_object(
    'anon_execute', has_function_privilege('anon', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)'::regprocedure, 'EXECUTE'),
    'authenticated_execute', has_function_privilege('authenticated', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)'::regprocedure, 'EXECUTE')
  )::text,
  true
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '', true);

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_simulada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'confirmar',
      null,
      '{}'::jsonb
    );
    perform set_config('app.mc12c.neg_sem_auth', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_sem_auth', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

select set_config('request.jwt.claim.sub', current_setting('app.mc12c.user_id', true), true);

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      '00000000-0000-0000-0000-0000000012c0'::uuid,
      'confirmar',
      null,
      '{}'::jsonb
    );
    perform set_config('app.mc12c.neg_inexistente', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_inexistente', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_simulada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'aprovar',
      null,
      '{}'::jsonb
    );
    perform set_config('app.mc12c.neg_acao_invalida', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_acao_invalida', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_simulada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'confirmar',
      null,
      '[]'::jsonb
    );
    perform set_config('app.mc12c.neg_parametros_nao_objeto', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_parametros_nao_objeto', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_simulada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'confirmar',
      null,
      jsonb_build_object('empresa_id', current_setting('app.mc12c.empresa_id', true)::uuid)
    );
    perform set_config('app.mc12c.neg_payload_autoritativo', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_payload_autoritativo', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_simulada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'cancelar',
      null,
      '{}'::jsonb
    );
    perform set_config('app.mc12c.neg_cancelamento_sem_motivo', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_cancelamento_sem_motivo', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_cancelada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'confirmar',
      null,
      '{}'::jsonb
    );
    perform set_config('app.mc12c.neg_confirmar_cancelada', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_confirmar_cancelada', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

do $$
begin
  begin
    perform public.mesa_cliente_atualizar_status_operacao_financeira_admin(
      (current_setting('app.mc12c.payload_op_confirmada_5b', true)::jsonb->'operacao'->>'id')::uuid,
      'cancelar',
      'Tentativa negativa 12C de cancelar confirmada',
      '{}'::jsonb
    );
    perform set_config('app.mc12c.neg_cancelar_confirmada', jsonb_build_object('caught', false)::text, true);
  exception when others then
    perform set_config('app.mc12c.neg_cancelar_confirmada', jsonb_build_object('caught', true, 'sqlstate', SQLSTATE, 'message', SQLERRM)::text, true);
  end;
end $$;

reset role;

with ctx as (
  select
    current_setting('app.mc12c.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc12c.agenda_id', true)::uuid as agenda_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.agenda_id = a.id
  limit 1
),
snapshot_after_negativos as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'agenda_full_hash', (select md5(to_jsonb(agenda.*)::text) from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_ids', (select coalesce(jsonb_agg(fp.id::text order by fp.id::text), '[]'::jsonb) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_canceladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'cancelada'),
    'operacoes_simuladas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'simulada'),
    'operacoes_visiveis_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'confirmado_por', o.confirmado_por, 'confirmado_em', o.confirmado_em, 'cancelado_por', o.cancelado_por, 'cancelado_em', o.cancelado_em, 'motivo_cancelamento', o.motivo_cancelamento, 'visivel_cliente', o.visivel_cliente) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc12c.snapshot_after_negativos', coalesce((select payload::text from snapshot_after_negativos), 'null'), true);

with dados as (
  select
    current_setting('app.mc12c.snapshot_before_ops', true)::jsonb as b,
    current_setting('app.mc12c.snapshot_after_setup', true)::jsonb as setup,
    current_setting('app.mc12c.snapshot_after_negativos', true)::jsonb as final,
    current_setting('app.mc12c.neg_anon_grant', true)::jsonb as anon_grant,
    current_setting('app.mc12c.neg_sem_auth', true)::jsonb as sem_auth,
    current_setting('app.mc12c.neg_inexistente', true)::jsonb as inexistente,
    current_setting('app.mc12c.neg_acao_invalida', true)::jsonb as acao_invalida,
    current_setting('app.mc12c.neg_parametros_nao_objeto', true)::jsonb as parametros_nao_objeto,
    current_setting('app.mc12c.neg_payload_autoritativo', true)::jsonb as payload_autoritativo,
    current_setting('app.mc12c.neg_cancelamento_sem_motivo', true)::jsonb as cancelamento_sem_motivo,
    current_setting('app.mc12c.neg_confirmar_cancelada', true)::jsonb as confirmar_cancelada,
    current_setting('app.mc12c.neg_cancelar_confirmada', true)::jsonb as cancelar_confirmada,
    current_setting('app.mc12c.payload_cancelamento_setup', true)::jsonb as cancelamento_setup,
    current_setting('app.mc12c.payload_confirmacao_setup', true)::jsonb as confirmacao_setup,
    current_setting('app.mc12c.payload_op_simulada_5b', true)::jsonb as op_simulada_5b
)
select bloco, status, detalhe
from (
  select
    '01_operacoes_base_preparadas' as bloco,
    case
      when cancelamento_setup->>'ok' = 'true'
       and confirmacao_setup->>'ok' = 'true'
       and op_simulada_5b->>'ok' = 'true'
       and (setup->>'operacoes')::integer = 3
       and (setup->>'operacoes_canceladas')::integer = 1
       and (setup->>'operacoes_confirmadas')::integer = 1
       and (setup->>'operacoes_simuladas')::integer = 1
       and (setup->>'operacoes_visiveis_cliente')::integer = 0
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object('setup', setup, 'cancelamento_setup', cancelamento_setup, 'confirmacao_setup', confirmacao_setup, 'op_simulada_5b', op_simulada_5b) as detalhe
  from dados

  union all

  select
    '02_anon_sem_execute',
    case
      when anon_grant->>'anon_execute' = 'false'
       and anon_grant->>'authenticated_execute' = 'true'
    then 'PASS' else 'FAIL' end,
    anon_grant
  from dados

  union all

  select
    '03_sem_auth_bloqueado',
    case when sem_auth->>'caught' = 'true' and sem_auth->>'sqlstate' = '28000' then 'PASS' else 'FAIL' end,
    sem_auth
  from dados

  union all

  select
    '04_operacao_inexistente_bloqueada',
    case when inexistente->>'caught' = 'true' and inexistente->>'sqlstate' = 'P0002' then 'PASS' else 'FAIL' end,
    inexistente
  from dados

  union all

  select
    '05_acao_invalida_bloqueada',
    case when acao_invalida->>'caught' = 'true' and acao_invalida->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
    acao_invalida
  from dados

  union all

  select
    '06_parametros_nao_objeto_bloqueado',
    case when parametros_nao_objeto->>'caught' = 'true' and parametros_nao_objeto->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
    parametros_nao_objeto
  from dados

  union all

  select
    '07_payload_autoritativo_bloqueado',
    case when payload_autoritativo->>'caught' = 'true' and payload_autoritativo->>'sqlstate' = '42501' then 'PASS' else 'FAIL' end,
    payload_autoritativo
  from dados

  union all

  select
    '08_cancelamento_sem_motivo_bloqueado',
    case when cancelamento_sem_motivo->>'caught' = 'true' and cancelamento_sem_motivo->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end,
    cancelamento_sem_motivo
  from dados

  union all

  select
    '09_confirmar_cancelada_bloqueado',
    case when confirmar_cancelada->>'caught' = 'true' and confirmar_cancelada->>'sqlstate' = '55000' then 'PASS' else 'FAIL' end,
    confirmar_cancelada
  from dados

  union all

  select
    '10_cancelar_confirmada_bloqueado',
    case when cancelar_confirmada->>'caught' = 'true' and cancelar_confirmada->>'sqlstate' = '55000' then 'PASS' else 'FAIL' end,
    cancelar_confirmada
  from dados

  union all

  select
    '11_negativos_nao_mutaram_operacoes',
    case
      when setup->>'operacoes' = final->>'operacoes'
       and setup->>'operacoes_confirmadas' = final->>'operacoes_confirmadas'
       and setup->>'operacoes_canceladas' = final->>'operacoes_canceladas'
       and setup->>'operacoes_simuladas' = final->>'operacoes_simuladas'
       and setup->>'operacoes_visiveis_cliente' = final->>'operacoes_visiveis_cliente'
       and setup->>'operacoes_full_hash' = final->>'operacoes_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('setup', setup, 'final', final)
  from dados

  union all

  select
    '12_agenda_parcelas_nao_mutadas',
    case
      when b->>'agenda_id' = final->>'agenda_id'
       and b->>'agenda_checksum' = final->>'agenda_checksum'
       and b->'agenda_tots' = final->'agenda_tots'
       and b->>'agenda_full_hash' = final->>'agenda_full_hash'
       and b->>'parcelas' = final->>'parcelas'
       and b->>'valor_total_parcelas' = final->>'valor_total_parcelas'
       and b->>'parcelas_ids' = final->>'parcelas_ids'
       and b->>'parcelas_full_hash' = final->>'parcelas_full_hash'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object('before', b, 'final', final)
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 12C encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
