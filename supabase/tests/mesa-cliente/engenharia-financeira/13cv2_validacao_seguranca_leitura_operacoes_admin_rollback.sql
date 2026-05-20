-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- 13C — Segurança negativa das RPCs administrativas de leitura de operações financeiras.
--
-- Objetivo:
--   Validar grants, autenticação, tenant-safe, bloqueio de payload soberano,
--   parâmetros inválidos e garantia read-only das RPCs 5D:
--     public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
--     public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
--
-- Nota de implementação do teste:
--   Este script NÃO usa SET ROLE para gravar resultados, evitando falso negativo com
--   temp table em pg_temp quando o SQL Editor alterna contexto de role. Os grants são
--   validados por has_function_privilege(), e as regras internas das RPCs são validadas
--   por auth.uid() via request.jwt.claim.sub.
--
-- Correção de robustez 13C:
--   A tabela temporária de resultados é criada ANTES do BEGIN principal, com
--   ON COMMIT PRESERVE ROWS, e referenciada por pg_temp.tmp_13c_resultados.
--   Isso evita erro 42P01 quando o SQL Editor/Supabase quebra o contexto
--   transacional ou executa commit implícito antes do SELECT final.
--
-- Segurança do teste:
--   - cria fixture transacional mínima via 4B/5B;
--   - executa somente negativos contra 5D;
--   - compara hashes antes/depois;
--   - encerra com ROLLBACK.

-- Harness fora da transação principal para sobreviver ao contexto do SQL Editor.
drop table if exists pg_temp.tmp_13c_resultados;

create temp table tmp_13c_resultados (
  ordem integer generated always as identity,
  bloco text not null,
  status text not null,
  detalhe jsonb not null default '{}'::jsonb
) on commit preserve rows;

begin;

select set_config('app.mc13c.user_id', '', true);
select set_config('app.mc13c.other_user_id', '', true);
select set_config('app.mc13c.simulacao_id', '', true);
select set_config('app.mc13c.empresa_id', '', true);
select set_config('app.mc13c.empreendimento_id', '', true);
select set_config('app.mc13c.politica_id', '', true);
select set_config('app.mc13c.agenda_id', '', true);
select set_config('app.mc13c.parcela_id', '', true);
select set_config('app.mc13c.operacao_id', '', true);
select set_config('app.mc13c.payload_4b', 'null', true);
select set_config('app.mc13c.payload_5b', 'null', true);
select set_config('app.mc13c.snapshot_before', 'null', true);
select set_config('app.mc13c.snapshot_after', 'null', true);
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
outro_tenant as materialized (
  select c.user_id, c.empresa_id, c.role
  from public.corretores c
  join candidato base on c.empresa_id is distinct from base.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and coalesce(c.role, '') <> 'admin_global'
    and (
      c.role in ('admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_local' then 1
      when c.role = 'gestor' then 2
      when c.role = 'coordenador' then 3
      else 4
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
    'Teste rollback 13C segurança leitura operação financeira 5D',
    43000.00,
    12000.00,
    0,
    43000.00,
    jsonb_build_object('origem', 'teste_13c_5d_rollback', 'fixture_transacional', true),
    'Fixture transacional 13C. Deve sumir no ROLLBACK.'
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
    date '2099-08-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 13C para segurança negativa das RPCs de leitura 5D.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 13C — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 13C — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 13C — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc13c.user_id', c.user_id::text, true),
    set_config('app.mc13c.other_user_id', coalesce((select user_id::text from outro_tenant), ''), true),
    set_config('app.mc13c.simulacao_id', s.id::text, true),
    set_config('app.mc13c.empresa_id', s.empresa_id::text, true),
    set_config('app.mc13c.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc13c.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
select
  '00_setup_fixture_13c',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc13c.simulacao_id', true),
    'politica_id', current_setting('app.mc13c.politica_id', true),
    'qtd_faixas', (select count(*) from faixas),
    'tem_outro_tenant_para_teste', nullif(current_setting('app.mc13c.other_user_id', true), '') is not null
  )
from setup;

with ctx as (
  select
    current_setting('app.mc13c.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13c.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc13c.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-08-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','12000.00','data','2099-08-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais 13C','valor','2500.00','quantidade',4,'mes_ano','09/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária 13C','valor','7000.00','quantidade',2,'mes_ano','12/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_13c')
  ) as payload
  from ctx
)
select set_config('app.mc13c.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

with ctx as (
  select current_setting('app.mc13c.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcela as (
  select fp.id
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual >= 1000.00
    and fp.data_atual > date '2099-08-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
  order by fp.valor_atual desc, fp.data_atual desc, fp.id
  limit 1
),
setups as (
  select
    set_config('app.mc13c.agenda_id', (select id::text from agenda), true),
    set_config('app.mc13c.parcela_id', (select id::text from parcela), true)
)
insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
select
  '00b_agenda_parcela_fixture_13c',
  case
    when current_setting('app.mc13c.agenda_id', true) <> ''
     and current_setting('app.mc13c.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc13c.agenda_id', true),
    'parcela_id', current_setting('app.mc13c.parcela_id', true)
  )
from setups;

with chamada_5b as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc13c.simulacao_id', true)::uuid,
    current_setting('app.mc13c.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc13c.parcela_id', true)::uuid,
    date '2099-08-31',
    null,
    1000.00,
    jsonb_build_object('origem_teste', '13c', 'observacao', 'operação fixture para negativos 5D')
  ) as payload
)
select
  set_config('app.mc13c.payload_5b', coalesce((select payload::text from chamada_5b), 'null'), true),
  set_config('app.mc13c.operacao_id', coalesce((select payload->'operacao'->>'id' from chamada_5b), ''), true);

with ctx as (
  select
    current_setting('app.mc13c.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13c.agenda_id', true)::uuid as agenda_id,
    current_setting('app.mc13c.operacao_id', true)::uuid as operacao_id
),
snapshot_before as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'operacao_id', ctx.operacao_id,
    'agenda_full_hash', (select md5(to_jsonb(a.*)::text) from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_visivel_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true)
  ) as payload
  from ctx
)
select set_config('app.mc13c.snapshot_before', coalesce((select payload::text from snapshot_before), 'null'), true);

insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
select
  '01_operacao_fixture_5b_preparada',
  case
    when current_setting('app.mc13c.payload_5b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc13c.operacao_id', true) <> ''
     and (current_setting('app.mc13c.snapshot_before', true)::jsonb->>'qtd_operacoes')::integer = 1
     and (current_setting('app.mc13c.snapshot_before', true)::jsonb->>'qtd_visivel_cliente')::integer = 0
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacao', current_setting('app.mc13c.payload_5b', true)::jsonb->'operacao',
    'snapshot_before', current_setting('app.mc13c.snapshot_before', true)::jsonb
  );

insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
select
  '02_grants_5d_anon_bloqueado_authenticated_liberado',
  case
    when has_function_privilege('anon', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'execute') = false
     and has_function_privilege('anon', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'execute') = false
     and has_function_privilege('public', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'execute') = false
     and has_function_privilege('public', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'execute') = false
     and has_function_privilege('authenticated', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'execute') = true
     and has_function_privilege('authenticated', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'execute') = true
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'listar_anon_execute', has_function_privilege('anon', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'execute'),
    'obter_anon_execute', has_function_privilege('anon', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'execute'),
    'listar_public_execute', has_function_privilege('public', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'execute'),
    'obter_public_execute', has_function_privilege('public', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'execute'),
    'listar_authenticated_execute', has_function_privilege('authenticated', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'execute'),
    'obter_authenticated_execute', has_function_privilege('authenticated', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'execute')
  );

-- 03A: sem auth.uid() na listagem
select set_config('request.jwt.claim.sub', '', true);
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin(current_setting('app.mc13c.simulacao_id', true)::uuid, null, '{}'::jsonb);
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('03a_listar_sem_auth_bloqueado', 'FAIL', jsonb_build_object('erro', 'chamada sem auth.uid() foi aceita'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('03a_listar_sem_auth_bloqueado', case when v_state = '28000' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 03B: sem auth.uid() no detalhe
select set_config('request.jwt.claim.sub', '', true);
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_obter_operacao_financeira_admin(current_setting('app.mc13c.operacao_id', true)::uuid, '{}'::jsonb);
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('03b_obter_sem_auth_bloqueado', 'FAIL', jsonb_build_object('erro', 'chamada sem auth.uid() foi aceita'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('03b_obter_sem_auth_bloqueado', case when v_state = '28000' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

select set_config('request.jwt.claim.sub', current_setting('app.mc13c.user_id', true), true);

-- 04A: simulação inexistente na listagem
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin('00000000-0000-0000-0000-000000000001'::uuid, null, '{}'::jsonb);
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('04a_listar_simulacao_inexistente_bloqueada', 'FAIL', jsonb_build_object('erro', 'simulação inexistente foi aceita'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('04a_listar_simulacao_inexistente_bloqueada', case when v_state = 'P0002' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 04B: operação inexistente no detalhe
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_obter_operacao_financeira_admin('00000000-0000-0000-0000-000000000001'::uuid, '{}'::jsonb);
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('04b_obter_operacao_inexistente_bloqueada', 'FAIL', jsonb_build_object('erro', 'operação inexistente foi aceita'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('04b_obter_operacao_inexistente_bloqueada', case when v_state = 'P0002' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 05A: p_filtros não objeto
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin(current_setting('app.mc13c.simulacao_id', true)::uuid, null, '[]'::jsonb);
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('05a_listar_filtros_nao_objeto_bloqueado', 'FAIL', jsonb_build_object('erro', 'p_filtros array foi aceito'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('05a_listar_filtros_nao_objeto_bloqueado', case when v_state = '22023' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 05B: p_parametros não objeto
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_obter_operacao_financeira_admin(current_setting('app.mc13c.operacao_id', true)::uuid, '[]'::jsonb);
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('05b_obter_parametros_nao_objeto_bloqueado', 'FAIL', jsonb_build_object('erro', 'p_parametros array foi aceito'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('05b_obter_parametros_nao_objeto_bloqueado', case when v_state = '22023' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 06A: payload soberano em filtros da listagem
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13c.simulacao_id', true)::uuid,
    null,
    jsonb_build_object('empresa_id', current_setting('app.mc13c.empresa_id', true))
  );
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('06a_listar_payload_soberano_bloqueado', 'FAIL', jsonb_build_object('erro', 'empresa_id em p_filtros foi aceito'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('06a_listar_payload_soberano_bloqueado', case when v_state = '42501' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 06B: payload soberano em parametros do detalhe
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_obter_operacao_financeira_admin(
    current_setting('app.mc13c.operacao_id', true)::uuid,
    jsonb_build_object('simulacao_id', current_setting('app.mc13c.simulacao_id', true))
  );
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('06b_obter_payload_soberano_bloqueado', 'FAIL', jsonb_build_object('erro', 'simulacao_id em p_parametros foi aceito'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('06b_obter_payload_soberano_bloqueado', case when v_state = '42501' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 07A: filtro status inválido
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13c.simulacao_id', true)::uuid,
    null,
    jsonb_build_object('status_operacao', 'hack')
  );
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('07a_listar_status_invalido_bloqueado', 'FAIL', jsonb_build_object('erro', 'status inválido foi aceito'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('07a_listar_status_invalido_bloqueado', case when v_state = '22023' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 07B: limit fora da faixa
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13c.simulacao_id', true)::uuid,
    null,
    jsonb_build_object('limit', 201)
  );
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('07b_listar_limit_invalido_bloqueado', 'FAIL', jsonb_build_object('erro', 'limit inválido foi aceito'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('07b_listar_limit_invalido_bloqueado', case when v_state = '22023' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 07C: agenda incompatível com a simulação não deve vazar dados
do $$
declare v_state text; v_msg text;
begin
  perform public.mesa_cliente_listar_operacoes_financeiras_admin(
    current_setting('app.mc13c.simulacao_id', true)::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '{}'::jsonb
  );
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('07c_listar_agenda_incompativel_bloqueada', 'FAIL', jsonb_build_object('erro', 'agenda incompatível/inexistente foi aceita'));
exception when others then
  get stacked diagnostics v_msg = message_text;
  v_state := sqlstate;
  insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
  values ('07c_listar_agenda_incompativel_bloqueada', case when v_state = 'P0002' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
end $$;

-- 08: outro tenant, quando houver candidato administrativo não global disponível.
do $$
declare v_state text; v_msg text; v_other text;
begin
  v_other := nullif(current_setting('app.mc13c.other_user_id', true), '');

  if v_other is null then
    insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
    values (
      '08_tenant_cross_empresa_bloqueado',
      'INFO',
      jsonb_build_object('mensagem', 'Sem usuário administrativo não global de outro tenant disponível na base para exercitar o bloqueio cross-tenant.')
    );
    return;
  end if;

  perform set_config('request.jwt.claim.sub', v_other, true);

  begin
    perform public.mesa_cliente_listar_operacoes_financeiras_admin(current_setting('app.mc13c.simulacao_id', true)::uuid, null, '{}'::jsonb);
    insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
    values ('08a_listar_cross_tenant_bloqueado', 'FAIL', jsonb_build_object('erro', 'usuário de outro tenant listou simulação fixture'));
  exception when others then
    get stacked diagnostics v_msg = message_text;
    v_state := sqlstate;
    insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
    values ('08a_listar_cross_tenant_bloqueado', case when v_state = '42501' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
  end;

  begin
    perform public.mesa_cliente_obter_operacao_financeira_admin(current_setting('app.mc13c.operacao_id', true)::uuid, '{}'::jsonb);
    insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
    values ('08b_obter_cross_tenant_bloqueado', 'FAIL', jsonb_build_object('erro', 'usuário de outro tenant obteve operação fixture'));
  exception when others then
    get stacked diagnostics v_msg = message_text;
    v_state := sqlstate;
    insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
    values ('08b_obter_cross_tenant_bloqueado', case when v_state = '42501' then 'PASS' else 'FAIL' end, jsonb_build_object('sqlstate', v_state, 'message', v_msg));
  end;

  perform set_config('request.jwt.claim.sub', current_setting('app.mc13c.user_id', true), true);
end $$;

select set_config('request.jwt.claim.sub', current_setting('app.mc13c.user_id', true), true);

with ctx as (
  select
    current_setting('app.mc13c.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc13c.agenda_id', true)::uuid as agenda_id,
    current_setting('app.mc13c.operacao_id', true)::uuid as operacao_id
),
snapshot_after as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'operacao_id', ctx.operacao_id,
    'agenda_full_hash', (select md5(to_jsonb(a.*)::text) from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(fp.*) order by fp.id)::text, '[]')) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes_full_hash', (select md5(coalesce(jsonb_agg(to_jsonb(o.*) order by o.id)::text, '[]')) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'qtd_visivel_cliente', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and coalesce(o.visivel_cliente, false) = true)
  ) as payload
  from ctx
)
select set_config('app.mc13c.snapshot_after', coalesce((select payload::text from snapshot_after), 'null'), true);

insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
select
  '09_negativos_readonly_nao_mutaram_agenda_parcelas_operacoes',
  case
    when b->>'agenda_full_hash' = a->>'agenda_full_hash'
     and b->>'parcelas_full_hash' = a->>'parcelas_full_hash'
     and b->>'operacoes_full_hash' = a->>'operacoes_full_hash'
     and b->>'qtd_operacoes' = a->>'qtd_operacoes'
     and b->>'qtd_visivel_cliente' = a->>'qtd_visivel_cliente'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'before', b,
    'after', a,
    'hash_agenda_igual', b->>'agenda_full_hash' = a->>'agenda_full_hash',
    'hash_parcelas_igual', b->>'parcelas_full_hash' = a->>'parcelas_full_hash',
    'hash_operacoes_igual', b->>'operacoes_full_hash' = a->>'operacoes_full_hash'
  )
from
  (select current_setting('app.mc13c.snapshot_before', true)::jsonb as b) before_data,
  (select current_setting('app.mc13c.snapshot_after', true)::jsonb as a) after_data;

insert into pg_temp.tmp_13c_resultados (bloco, status, detalhe)
values (
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Teste 13C encerra com ROLLBACK. A fixture 4B/5B e os negativos 5D não devem permanecer no banco.',
    'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
    'validacao', 'segurança negativa, tenant-safe e read-only'
  )
);

select bloco, status, detalhe
from pg_temp.tmp_13c_resultados
order by ordem;

rollback;
