-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5B
-- 11B — Validações negativas e segurança da RPC de registro de operação financeira.
--
-- Pré-requisito:
--   Migration 5B aplicada:
--   supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
--
-- Objetivo:
--   Validar bloqueios principais da RPC 5B:
--     - anon sem EXECUTE;
--     - chamada sem auth;
--     - simulação inexistente;
--     - agenda inexistente;
--     - parcela inexistente na agenda;
--     - empresa_id/taxa/status/checksum/idempotency_key no payload;
--     - valor negativo;
--     - tipo de operação inválido;
--     - p_parametros não objeto;
--     - postergação sem data destino;
--     - parcela simbólica;
--     - rollback final.
--
-- Nota técnica:
--   Não usa temp table para armazenar resultados, porque temp table + SET LOCAL ROLE
--   pode gerar erro de permissão ou resolução de schema no SQL Editor.
--   Os resultados são acumulados em variável transacional via set_config(...).

begin;

select set_config('app.mc11b.results', '[]', true);
select set_config('app.mc11b.user_id', '', true);
select set_config('app.mc11b.simulacao_id', '', true);
select set_config('app.mc11b.empresa_id', '', true);
select set_config('app.mc11b.empreendimento_id', '', true);
select set_config('app.mc11b.politica_id', '', true);
select set_config('app.mc11b.agenda_id', '', true);
select set_config('app.mc11b.parcela_id', '', true);
select set_config('app.mc11b.parcela_simbolica_id', '', true);
select set_config('app.mc11b.payload_4b', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

-- 01: anon não pode executar a RPC 5B.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  if has_function_privilege(
    'anon',
    'public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)'::regprocedure,
    'EXECUTE'
  ) then
    v_item := jsonb_build_object('bloco', '01_grant_anon_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('anon_can_execute', true));
  else
    v_item := jsonb_build_object('bloco', '01_grant_anon_bloqueado', 'status', 'PASS', 'detalhe', jsonb_build_object('anon_can_execute', false));
  end if;

  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 02: chamada sem auth deve bloquear antes de qualquer leitura soberana.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    gen_random_uuid(),
    gen_random_uuid(),
    'antecipacao',
    gen_random_uuid(),
    current_date,
    null,
    1000,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '02_sem_auth_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'chamada sem auth não bloqueou'));
exception when others then
  v_item := jsonb_build_object(
    'bloco', '02_sem_auth_bloqueado',
    'status', case when sqlstate = '28000' then 'PASS' else 'FAIL' end,
    'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
  );
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- Fixture transacional: usuário admin/gestor, simulação, política, faixas, agenda e parcelas via 4B.
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
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 else 4 end,
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
    'Teste rollback 11B negativos registro operação financeira 5B',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object('origem', 'teste_11b_5b_rollback', 'fixture_transacional', true),
    'Fixture transacional 11B. Deve sumir no ROLLBACK.'
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
    date '2099-05-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 11B para validações negativas da RPC 5B.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 11B — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 11B — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 11B — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc11b.user_id', c.user_id::text, true),
    set_config('app.mc11b.simulacao_id', s.id::text, true),
    set_config('app.mc11b.empresa_id', s.empresa_id::text, true),
    set_config('app.mc11b.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc11b.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select count(*) from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc11b.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11b.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc11b.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-05-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-05-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',3,'mes_ano','06/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','07/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_11b')
  ) as payload
  from ctx
)
select set_config('app.mc11b.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc11b.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.id
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
  where fp.valor_atual > 0
    and fp.data_atual > date '2099-05-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
  order by fp.valor_atual desc, fp.data_atual desc, fp.id
  limit 1
),
parcela_simbolica as (
  select fp.id
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where coalesce(fp.eh_periodicidade_simbolica, false) = true
  order by fp.id
  limit 1
),
setup_ids as (
  select
    set_config('app.mc11b.agenda_id', (select id::text from agenda), true),
    set_config('app.mc11b.parcela_id', (select id::text from parcela), true),
    set_config('app.mc11b.parcela_simbolica_id', coalesce((select id::text from parcela_simbolica), ''), true)
)
select count(*) from setup_ids;

-- 03 em diante: usuário autenticado real.
set local role authenticated;

-- 03: simulação inexistente deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    gen_random_uuid(),
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '03_simulacao_inexistente_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'simulação inexistente não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '03_simulacao_inexistente_bloqueada', 'status', case when sqlstate = 'P0002' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 04: agenda inexistente deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    gen_random_uuid(),
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '04_agenda_inexistente_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'agenda inexistente não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '04_agenda_inexistente_bloqueada', 'status', case when sqlstate = 'P0002' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 05: parcela inexistente na agenda deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    gen_random_uuid(),
    date '2099-05-31',
    null,
    1000,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '05_parcela_inexistente_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'parcela inexistente não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '05_parcela_inexistente_bloqueada', 'status', case when sqlstate = 'P0002' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 06: empresa_id no payload deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    jsonb_build_object('empresa_id', gen_random_uuid())
  );
  v_item := jsonb_build_object('bloco', '06_empresa_id_payload_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'empresa_id no payload não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '06_empresa_id_payload_bloqueado', 'status', case when sqlstate = '42501' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 07: taxa_ano_pct no payload deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    jsonb_build_object('taxa_ano_pct', 1)
  );
  v_item := jsonb_build_object('bloco', '07_taxa_payload_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'taxa_ano_pct no payload não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '07_taxa_payload_bloqueada', 'status', case when sqlstate = '42501' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 08: status_operacao no payload deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    jsonb_build_object('status_operacao', 'confirmada')
  );
  v_item := jsonb_build_object('bloco', '08_status_payload_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'status_operacao no payload não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '08_status_payload_bloqueado', 'status', case when sqlstate = '42501' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 09: checksum_operacao/idempotency_key no payload devem bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    jsonb_build_object('checksum_operacao', 'frontend-nao-manda', 'idempotency_key', 'frontend-nao-manda')
  );
  v_item := jsonb_build_object('bloco', '09_checksum_payload_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'checksum/idempotency no payload não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '09_checksum_payload_bloqueado', 'status', case when sqlstate = '42501' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 10: valor negativo deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    -100,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '10_valor_negativo_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'valor negativo não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '10_valor_negativo_bloqueado', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 11: tipo de operação inválido deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'troca_milagrosa',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '11_tipo_operacao_invalido_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'tipo inválido não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '11_tipo_operacao_invalido_bloqueado', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 12: p_parametros precisa ser objeto JSON.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    '["nao_objeto"]'::jsonb
  );
  v_item := jsonb_build_object('bloco', '12_parametros_nao_objeto_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'p_parametros array não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '12_parametros_nao_objeto_bloqueado', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 13: postergação sem data destino deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11b.simulacao_id', true)::uuid,
    current_setting('app.mc11b.agenda_id', true)::uuid,
    'postergacao',
    current_setting('app.mc11b.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    1000,
    '{}'::jsonb
  );
  v_item := jsonb_build_object('bloco', '13_postergacao_sem_data_destino_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'postergação sem data destino não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '13_postergacao_sem_data_destino_bloqueada', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 14: parcela simbólica não pode receber operação financeira.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
  v_parcela_simbolica uuid := nullif(current_setting('app.mc11b.parcela_simbolica_id', true), '')::uuid;
begin
  if v_parcela_simbolica is null then
    v_item := jsonb_build_object('bloco', '14_parcela_simbolica_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'fixture não encontrou parcela simbólica para validar bloqueio'));
  else
    perform public.mesa_cliente_registrar_operacao_financeira_admin(
      current_setting('app.mc11b.simulacao_id', true)::uuid,
      current_setting('app.mc11b.agenda_id', true)::uuid,
      'antecipacao',
      v_parcela_simbolica,
      date '2099-05-31',
      null,
      1000,
      '{}'::jsonb
    );
    v_item := jsonb_build_object('bloco', '14_parcela_simbolica_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'parcela simbólica não bloqueou'));
  end if;
exception when others then
  v_item := jsonb_build_object('bloco', '14_parcela_simbolica_bloqueada', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
ensure
  -- PL/pgSQL não possui ensure; mantido intencionalmente fora de uso.
end $$;

reset role;

-- 15: confirma que os negativos não criaram operação financeira.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
  v_total integer;
begin
  select count(*)::integer
    into v_total
  from public.mesa_cliente_fluxo_operacoes o
  where o.simulacao_id = current_setting('app.mc11b.simulacao_id', true)::uuid;

  v_item := jsonb_build_object(
    'bloco', '15_zero_operacoes_criadas_pelos_negativos',
    'status', case when v_total = 0 then 'PASS' else 'FAIL' end,
    'detalhe', jsonb_build_object('total_operacoes', v_total)
  );

  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 99: aviso de rollback.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc11b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  v_item := jsonb_build_object('bloco', '99_rollback_notice', 'status', 'INFO', 'detalhe', jsonb_build_object('mensagem', 'Teste 11B encerra com ROLLBACK. Nada deve permanecer no banco.'));
  perform set_config('app.mc11b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

select
  item->>'bloco' as bloco,
  item->>'status' as status,
  item->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc11b.results', true)::jsonb) with ordinality as r(item, ord)
order by ord;

rollback;
