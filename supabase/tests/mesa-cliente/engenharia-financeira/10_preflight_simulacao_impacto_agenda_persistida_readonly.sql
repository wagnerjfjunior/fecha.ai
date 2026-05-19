-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5A
-- 10 Preflight Read-only — Simulação de impacto com agenda persistida.
--
-- Objetivo:
--   Mapear o schema real antes de criar qualquer migration/RPC da Fase 5A.
--
-- Contrato vigente:
--   docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md
--
-- Regra desta versão:
--   Este preflight é catalog-first e read-only.
--   Ele não cria fixture, não chama RPC de persistência, não chama futura RPC 5A,
--   não insere, não atualiza, não apaga e não altera schema.
--
-- Escopo da 5A:
--   Ler agenda ativa persistida, parcelas, política financeira e faixas de prêmio
--   para simular impacto administrativo sem gravar operação financeira.
--
-- Uso:
--   Rodar o arquivo inteiro no Supabase SQL Editor como role postgres.
--   Enviar o resultset único completo, principalmente a seção 13_operational_interpretation.

with
target_tables as (
  select * from (
    values
      ('mesa_simulacoes', true, 'simulação soberana e vínculo empresa/empreendimento/corretor'),
      ('corretores', true, 'contexto de auth/perfil/dono da simulação'),
      ('empresas', true, 'tenant/empresa'),
      ('empreendimentos', true, 'empreendimento vinculado à simulação'),
      ('mesa_cliente_agendas_financeiras', true, 'agenda ativa persistida pela 4B'),
      ('mesa_cliente_fluxo_parcelas', true, 'parcelas persistidas da agenda'),
      ('mesa_cliente_fluxo_operacoes', true, 'verificação de operações confirmadas/status'),
      ('mesa_cliente_politicas_financeiras', true, 'política financeira vigente'),
      ('mesa_cliente_politica_premio_faixas', false, 'faixas de prêmio administrativas, quando aplicável')
  ) as t(table_name, required_for_5a, purpose)
),
tables_inventory as (
  select
    t.table_name,
    t.required_for_5a,
    t.purpose,
    to_regclass('public.' || t.table_name) is not null as exists_in_database,
    coalesce(c.relrowsecurity, false) as rls_enabled,
    coalesce(c.relforcerowsecurity, false) as rls_forced,
    pg_get_userbyid(c.relowner) as owner_name,
    c.reltuples::bigint as estimated_rows
  from target_tables t
  left join pg_class c
    on c.oid = to_regclass('public.' || t.table_name)
),
function_targets as (
  select * from (
    values
      ('calc_assert_input', 'public.mesa_cliente_financeiro_assert_calculo_input(numeric,numeric,text)', true, 'função pura base de validação'),
      ('calc_dias_entre', 'public.mesa_cliente_financeiro_dias_entre(date,date)', true, 'função pura para diferença de dias'),
      ('calc_fator_composto', 'public.mesa_cliente_financeiro_fator_composto(numeric,integer,text)', true, 'função pura fator composto'),
      ('calc_valor_presente', 'public.mesa_cliente_financeiro_valor_presente_composto(numeric,numeric,integer,text)', true, 'função pura valor presente'),
      ('calc_valor_futuro', 'public.mesa_cliente_financeiro_valor_futuro_composto(numeric,numeric,integer,text)', true, 'função pura valor futuro'),
      ('calc_antecipacao', 'public.mesa_cliente_financeiro_calcular_antecipacao_composta(numeric,date,date,numeric,text)', true, 'cálculo composto de antecipação'),
      ('calc_postergacao', 'public.mesa_cliente_financeiro_calcular_postergacao_composta(numeric,date,date,numeric,text)', true, 'cálculo composto de postergação'),
      ('calc_vpl_parcela', 'public.mesa_cliente_financeiro_calcular_vpl_parcela(numeric,date,date,numeric,text)', true, 'cálculo composto de VPL de parcela'),
      ('rpc_4b_persistencia_agenda', 'public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)', true, 'RPC 4B já aprovada'),
      ('rpc_4c_cliente_safe', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', true, 'RPC 4C já aprovada'),
      ('rpc_admin_payload_first_existente', 'public.mesa_cliente_simular_impacto_financeiro_admin(uuid,uuid,date,jsonb,uuid)', false, 'RPC administrativa anterior, payload-first'),
      ('rpc_5a_candidata', 'public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)', false, 'RPC futura da 5A, agenda-first')
  ) as f(function_label, signature, required_for_5a, purpose)
),
function_inventory as (
  select
    f.function_label,
    f.signature,
    f.required_for_5a,
    f.purpose,
    r.oid is not null as exists_in_database,
    coalesce(p.prosecdef, false) as security_definer,
    case p.provolatile
      when 'i' then 'immutable'
      when 's' then 'stable'
      when 'v' then 'volatile'
      else null
    end as volatility_label,
    pg_get_userbyid(p.proowner) as owner_name,
    p.proconfig as function_config,
    pg_get_function_identity_arguments(r.oid) as identity_arguments,
    coalesce(has_function_privilege('anon', r.oid, 'EXECUTE'), false) as anon_can_execute,
    coalesce(has_function_privilege('authenticated', r.oid, 'EXECUTE'), false) as authenticated_can_execute
  from function_targets f
  cross join lateral (select to_regprocedure(f.signature) as oid) r
  left join pg_proc p on p.oid = r.oid
),
cols as (
  select
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.numeric_precision,
    c.numeric_scale,
    c.character_maximum_length
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name in (select table_name from target_tables)
),
expected_cols as (
  select * from (
    values
      ('simulacao', 'mesa_simulacoes', 'id', true, 'identificar simulação'),
      ('simulacao', 'mesa_simulacoes', 'empresa_id', true, 'validar tenant'),
      ('simulacao', 'mesa_simulacoes', 'empreendimento_id', true, 'validar empreendimento'),
      ('simulacao', 'mesa_simulacoes', 'corretor_id', false, 'validar dono/perfil quando aplicável'),

      ('corretor', 'corretores', 'id', true, 'identificar corretor'),
      ('corretor', 'corretores', 'empresa_id', true, 'validar tenant do corretor'),
      ('corretor', 'corretores', 'user_id', false, 'vincular auth.uid quando existir'),
      ('corretor', 'corretores', 'perfil', false, 'validar perfil autorizado quando existir'),
      ('corretor', 'corretores', 'ativo', false, 'validar usuário ativo quando existir'),

      ('agenda', 'mesa_cliente_agendas_financeiras', 'id', true, 'identificar agenda'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'empresa_id', true, 'tenant da agenda'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'simulacao_id', true, 'vínculo com simulação'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'empreendimento_id', true, 'vínculo com empreendimento'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'status', true, 'selecionar agenda ativa'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'checksum', false, 'controle interno/idempotência'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'totais', false, 'resumo da agenda'),
      ('agenda', 'mesa_cliente_agendas_financeiras', 'metadata', false, 'metadata administrativa'),

      ('parcela', 'mesa_cliente_fluxo_parcelas', 'id', true, 'identificar parcela'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'agenda_id', true, 'vínculo com agenda'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'empresa_id', true, 'tenant da parcela'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'simulacao_id', true, 'vínculo com simulação'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'empreendimento_id', true, 'vínculo com empreendimento'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'grupo', true, 'grupo financeiro'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'descricao', false, 'descrição administrativa/comercial'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'ordem', false, 'ordenação'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'valor_atual', true, 'valor base para cálculo'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'data_atual', true, 'data base da parcela'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'eh_periodicidade_simbolica', true, 'excluir periodicidade simbólica'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'pode_receber_antecipacao', true, 'elegibilidade antecipação'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'pode_receber_postergacao', true, 'elegibilidade postergação'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'pode_receber_vpl', true, 'elegibilidade VPL'),
      ('parcela', 'mesa_cliente_fluxo_parcelas', 'metadata', false, 'metadata administrativa'),

      ('operacao', 'mesa_cliente_fluxo_operacoes', 'id', true, 'identificar operação'),
      ('operacao', 'mesa_cliente_fluxo_operacoes', 'empresa_id', true, 'tenant da operação'),
      ('operacao', 'mesa_cliente_fluxo_operacoes', 'simulacao_id', true, 'vínculo com simulação'),
      ('operacao', 'mesa_cliente_fluxo_operacoes', 'agenda_id', false, 'vínculo com agenda quando existir'),
      ('operacao', 'mesa_cliente_fluxo_operacoes', 'status_operacao', true, 'bloqueios/status confirmada'),

      ('politica', 'mesa_cliente_politicas_financeiras', 'id', true, 'identificar política'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'empresa_id', true, 'tenant da política'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'empreendimento_id', false, 'política por empreendimento quando existir'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'ativo', true, 'vigência ativa'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'vigencia_inicio', true, 'início da vigência'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'vigencia_fim', false, 'fim da vigência'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'metodo_calculo', true, 'deve ser composto'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'base_tempo', true, 'deve ser dias_365'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'taxa_antecipacao_ano_pct', true, 'taxa anual de antecipação'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'taxa_postergacao_ano_pct', true, 'taxa anual de postergação'),
      ('politica', 'mesa_cliente_politicas_financeiras', 'vpl_max_pct', true, 'limite máximo de VPL'),

      ('faixa_premio', 'mesa_cliente_politica_premio_faixas', 'id', false, 'identificar faixa'),
      ('faixa_premio', 'mesa_cliente_politica_premio_faixas', 'politica_id', false, 'vínculo com política'),
      ('faixa_premio', 'mesa_cliente_politica_premio_faixas', 'premio_pct', false, 'percentual de prêmio quando existir'),
      ('faixa_premio', 'mesa_cliente_politica_premio_faixas', 'vpl_de_pct', false, 'faixa inicial de VPL'),
      ('faixa_premio', 'mesa_cliente_politica_premio_faixas', 'vpl_ate_pct', false, 'faixa final de VPL')
  ) as e(area, table_name, column_name, required_for_5a, purpose)
),
expected_cols_status as (
  select
    e.area,
    e.table_name,
    e.column_name,
    e.required_for_5a,
    e.purpose,
    c.column_name is not null as exists_in_database,
    c.data_type,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.numeric_precision,
    c.numeric_scale
  from expected_cols e
  left join cols c
    on c.table_name = e.table_name
   and c.column_name = e.column_name
),
constraints_inventory as (
  select
    rel.relname as table_name,
    con.conname as constraint_name,
    con.contype as constraint_type,
    pg_get_constraintdef(con.oid) as constraint_definition
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  where nsp.nspname = 'public'
    and rel.relname in (select table_name from target_tables)
),
indexes_inventory as (
  select
    i.tablename as table_name,
    i.indexname,
    i.indexdef
  from pg_indexes i
  where i.schemaname = 'public'
    and i.tablename in (select table_name from target_tables)
),
policies_inventory as (
  select
    p.tablename,
    p.policyname,
    p.cmd,
    p.roles,
    p.qual,
    p.with_check
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename in (select table_name from target_tables)
),
grants_inventory as (
  select
    g.table_name,
    g.grantee,
    g.privilege_type,
    g.is_grantable
  from information_schema.role_table_grants g
  where g.table_schema = 'public'
    and g.table_name in (select table_name from target_tables)
),
finance_column_candidates as (
  select
    c.table_name,
    c.column_name,
    c.data_type,
    c.udt_name,
    case
      when c.column_name ilike '%taxa%' then 'taxa'
      when c.column_name ilike '%vpl%' then 'vpl'
      when c.column_name ilike '%premio%' or c.column_name ilike '%prêmio%' then 'premio'
      when c.column_name ilike '%comissao%' or c.column_name ilike '%comissão%' then 'comissao'
      when c.column_name ilike '%desconto%' then 'desconto'
      when c.column_name ilike '%acrescimo%' or c.column_name ilike '%acréscimo%' then 'acrescimo'
      when c.column_name ilike '%economia%' then 'economia'
      when c.column_name ilike '%metodo%' then 'metodo'
      when c.column_name ilike '%base%' then 'base'
      when c.column_name ilike '%vigencia%' or c.column_name ilike '%vigência%' then 'vigencia'
      else 'revisar'
    end as categoria
  from cols c
  where c.table_name in ('mesa_cliente_politicas_financeiras', 'mesa_cliente_politica_premio_faixas', 'mesa_cliente_fluxo_parcelas', 'mesa_cliente_fluxo_operacoes')
    and (
      c.column_name ilike '%taxa%'
      or c.column_name ilike '%vpl%'
      or c.column_name ilike '%premio%'
      or c.column_name ilike '%prêmio%'
      or c.column_name ilike '%comissao%'
      or c.column_name ilike '%comissão%'
      or c.column_name ilike '%desconto%'
      or c.column_name ilike '%acrescimo%'
      or c.column_name ilike '%acréscimo%'
      or c.column_name ilike '%economia%'
      or c.column_name ilike '%metodo%'
      or c.column_name ilike '%base%'
      or c.column_name ilike '%vigencia%'
      or c.column_name ilike '%vigência%'
    )
),
counts_exact as (
  select 'mesa_simulacoes' as table_name, count(*)::bigint as total_rows from public.mesa_simulacoes
  union all
  select 'mesa_cliente_agendas_financeiras', count(*)::bigint from public.mesa_cliente_agendas_financeiras
  union all
  select 'mesa_cliente_fluxo_parcelas', count(*)::bigint from public.mesa_cliente_fluxo_parcelas
  union all
  select 'mesa_cliente_fluxo_operacoes', count(*)::bigint from public.mesa_cliente_fluxo_operacoes
  union all
  select 'mesa_cliente_politicas_financeiras', count(*)::bigint from public.mesa_cliente_politicas_financeiras
  union all
  select 'mesa_cliente_politica_premio_faixas', count(*)::bigint from public.mesa_cliente_politica_premio_faixas
),
active_agenda_summary as (
  select
    count(*)::bigint as total_agendas,
    count(*) filter (where to_jsonb(a)->>'status' = 'ativa')::bigint as agendas_ativas,
    count(distinct nullif(to_jsonb(a)->>'simulacao_id', '')) filter (where to_jsonb(a)->>'status' = 'ativa')::bigint as simulacoes_com_agenda_ativa,
    count(*) filter (
      where to_jsonb(a)->>'status' = 'ativa'
        and exists (
          select 1
          from public.mesa_cliente_fluxo_parcelas p
          where nullif(to_jsonb(p)->>'agenda_id', '') = nullif(to_jsonb(a)->>'id', '')
        )
    )::bigint as agendas_ativas_com_parcelas
  from public.mesa_cliente_agendas_financeiras a
),
parcelas_summary as (
  select
    count(*)::bigint as total_parcelas,
    count(*) filter (where nullif(to_jsonb(p)->>'agenda_id', '') is not null)::bigint as parcelas_com_agenda_id,
    count(*) filter (where nullif(to_jsonb(p)->>'valor_atual', '') is not null)::bigint as parcelas_com_valor_atual,
    count(*) filter (where nullif(to_jsonb(p)->>'data_atual', '') is not null)::bigint as parcelas_com_data_atual,
    count(*) filter (where lower(coalesce(to_jsonb(p)->>'eh_periodicidade_simbolica', 'false')) = 'true')::bigint as parcelas_periodicidade_simbolica,
    count(*) filter (where lower(coalesce(to_jsonb(p)->>'pode_receber_antecipacao', 'false')) = 'true')::bigint as parcelas_podem_antecipacao,
    count(*) filter (where lower(coalesce(to_jsonb(p)->>'pode_receber_postergacao', 'false')) = 'true')::bigint as parcelas_podem_postergacao,
    count(*) filter (where lower(coalesce(to_jsonb(p)->>'pode_receber_vpl', 'false')) = 'true')::bigint as parcelas_podem_vpl
  from public.mesa_cliente_fluxo_parcelas p
),
politicas_summary as (
  select
    count(*)::bigint as total_politicas,
    count(*) filter (where lower(coalesce(to_jsonb(p)->>'ativo', 'false')) = 'true')::bigint as politicas_ativas,
    count(*) filter (where coalesce(to_jsonb(p)->>'metodo_calculo', '') = 'composto')::bigint as politicas_metodo_composto,
    count(*) filter (where coalesce(to_jsonb(p)->>'base_tempo', '') = 'dias_365')::bigint as politicas_base_dias_365,
    count(*) filter (
      where lower(coalesce(to_jsonb(p)->>'ativo', 'false')) = 'true'
        and coalesce(to_jsonb(p)->>'metodo_calculo', '') = 'composto'
        and coalesce(to_jsonb(p)->>'base_tempo', '') = 'dias_365'
    )::bigint as politicas_ativas_compostas_dias_365
  from public.mesa_cliente_politicas_financeiras p
),
operacoes_summary as (
  select
    count(*)::bigint as total_operacoes,
    count(*) filter (where coalesce(to_jsonb(o)->>'status_operacao', '') = 'confirmada')::bigint as operacoes_confirmadas,
    count(distinct nullif(to_jsonb(o)->>'simulacao_id', '')) filter (where coalesce(to_jsonb(o)->>'status_operacao', '') = 'confirmada')::bigint as simulacoes_com_operacao_confirmada
  from public.mesa_cliente_fluxo_operacoes o
),
fixture_candidate_summary as (
  select
    count(*)::bigint as total_candidatos_5a
  from public.mesa_cliente_agendas_financeiras a
  where to_jsonb(a)->>'status' = 'ativa'
    and exists (
      select 1
      from public.mesa_cliente_fluxo_parcelas p
      where nullif(to_jsonb(p)->>'agenda_id', '') = nullif(to_jsonb(a)->>'id', '')
        and nullif(to_jsonb(p)->>'valor_atual', '') is not null
        and nullif(to_jsonb(p)->>'data_atual', '') is not null
        and lower(coalesce(to_jsonb(p)->>'eh_periodicidade_simbolica', 'false')) <> 'true'
    )
),
missing_required_tables as (
  select count(*)::integer as qtd
  from tables_inventory
  where required_for_5a and not exists_in_database
),
missing_required_functions as (
  select count(*)::integer as qtd
  from function_inventory
  where required_for_5a and not exists_in_database
),
missing_required_columns as (
  select count(*)::integer as qtd
  from expected_cols_status
  where required_for_5a and not exists_in_database
),
function_security_findings as (
  select
    count(*) filter (where function_label = 'rpc_5a_candidata' and exists_in_database and anon_can_execute)::integer as rpc_5a_anon_execute_if_exists,
    count(*) filter (where function_label in ('rpc_4b_persistencia_agenda', 'rpc_4c_cliente_safe') and required_for_5a and not exists_in_database)::integer as missing_prior_phase_rpc,
    count(*) filter (where function_label like 'calc_%' and required_for_5a and not exists_in_database)::integer as missing_calc_functions
  from function_inventory
),
table_security_findings as (
  select
    count(*) filter (where required_for_5a and exists_in_database and not rls_enabled)::integer as required_tables_without_rls,
    count(*) filter (where required_for_5a and exists_in_database)::integer as required_tables_found
  from tables_inventory
),
interpretation as (
  select
    (select qtd from missing_required_tables) as missing_required_tables,
    (select qtd from missing_required_functions) as missing_required_functions,
    (select qtd from missing_required_columns) as missing_required_columns,
    (select rpc_5a_anon_execute_if_exists from function_security_findings) as rpc_5a_anon_execute_if_exists,
    (select required_tables_without_rls from table_security_findings) as required_tables_without_rls,
    (select total_candidatos_5a from fixture_candidate_summary) as total_fixture_candidates_5a,
    (select politicas_ativas_compostas_dias_365 from politicas_summary) as politicas_ativas_compostas_dias_365,
    (select agendas_ativas_com_parcelas from active_agenda_summary) as agendas_ativas_com_parcelas,
    case
      when (select qtd from missing_required_tables) > 0
        then 'BLOQUEAR: há tabela obrigatória ausente. Corrigir schema/branch antes de migration 5A.'
      when (select missing_calc_functions from function_security_findings) > 0
        then 'BLOQUEAR: funções puras de cálculo composto ausentes. A 5A deve reutilizar o motor já validado.'
      when (select missing_prior_phase_rpc from function_security_findings) > 0
        then 'BLOQUEAR: RPCs 4B/4C ausentes. A 5A depende de agenda persistida e leitura 4C fechada.'
      when (select rpc_5a_anon_execute_if_exists from function_security_findings) > 0
        then 'BLOQUEAR: RPC 5A já existe com EXECUTE para anon. Harden/revoke antes de continuar.'
      when (select qtd from missing_required_columns) > 0
        then 'BLOQUEAR: há colunas obrigatórias ausentes para a 5A. Revisar seção 04_expected_required_columns_status e ajustar contrato/migration aos nomes reais.'
      when (select politicas_ativas_compostas_dias_365 from politicas_summary) = 0
        then 'BLOQUEAR: não há política ativa com metodo_calculo=composto e base_tempo=dias_365. Criar/validar política antes da RPC 5A.'
      else 'OK_PARA_CRIAR_MIGRATION_5A_SIMULACAO_IMPACTO: schema mínimo, funções de cálculo, agenda persistida e política base mapeados. Criar RPC 5A read-only, agenda-first, sem DML financeiro e sem cliente_safe.'
    end as recommended_next_step
),
section_rows as (
  select
    1 as ordem,
    '01_tables_inventory' as section,
    'tabelas necessárias para simulação de impacto 5A' as item,
    case when (select qtd from missing_required_tables) = 0 then 'PASS' else 'FAIL' end as status,
    jsonb_agg(to_jsonb(tables_inventory) order by required_for_5a desc, table_name) as detalhe
  from tables_inventory

  union all
  select
    2,
    '02_function_inventory',
    'funções puras, RPCs 4B/4C e RPCs administrativas relacionadas',
    case when (select qtd from missing_required_functions) = 0 then 'PASS' else 'FAIL' end,
    jsonb_agg(to_jsonb(function_inventory) order by required_for_5a desc, function_label)
  from function_inventory

  union all
  select
    3,
    '03_columns_inventory',
    'colunas reais das tabelas-alvo',
    'INFO',
    jsonb_agg(to_jsonb(cols) order by table_name, ordinal_position)
  from cols

  union all
  select
    4,
    '04_expected_required_columns_status',
    'status das colunas esperadas pelo contrato 5A',
    case when (select qtd from missing_required_columns) = 0 then 'PASS' else 'FAIL' end,
    jsonb_agg(to_jsonb(expected_cols_status) order by area, table_name, required_for_5a desc, column_name)
  from expected_cols_status

  union all
  select
    5,
    '05_finance_column_candidates',
    'colunas financeiras candidatas encontradas por nome',
    'INFO',
    coalesce(jsonb_agg(to_jsonb(finance_column_candidates) order by table_name, categoria, column_name), '[]'::jsonb)
  from finance_column_candidates

  union all
  select
    6,
    '06_constraints_inventory',
    'constraints das tabelas relevantes',
    'INFO',
    coalesce(jsonb_agg(to_jsonb(constraints_inventory) order by table_name, constraint_type, constraint_name), '[]'::jsonb)
  from constraints_inventory

  union all
  select
    7,
    '07_indexes_inventory',
    'índices das tabelas relevantes',
    'INFO',
    coalesce(jsonb_agg(to_jsonb(indexes_inventory) order by table_name, indexname), '[]'::jsonb)
  from indexes_inventory

  union all
  select
    8,
    '08_rls_policies_and_table_grants',
    'RLS, policies e grants das tabelas-alvo',
    case when (select required_tables_without_rls from table_security_findings) = 0 then 'PASS' else 'WARN' end,
    jsonb_build_object(
      'tables_rls', (select jsonb_agg(to_jsonb(tables_inventory) order by table_name) from tables_inventory),
      'policies', coalesce((select jsonb_agg(to_jsonb(policies_inventory) order by tablename, policyname) from policies_inventory), '[]'::jsonb),
      'grants', coalesce((select jsonb_agg(to_jsonb(grants_inventory) order by table_name, grantee, privilege_type) from grants_inventory), '[]'::jsonb)
    )

  union all
  select
    9,
    '09_counts_and_data_readiness',
    'contagens e sinais de dados para fixture/teste 5A',
    'INFO',
    jsonb_build_object(
      'counts_exact', (select jsonb_agg(to_jsonb(counts_exact) order by table_name) from counts_exact),
      'active_agenda_summary', (select to_jsonb(active_agenda_summary) from active_agenda_summary),
      'parcelas_summary', (select to_jsonb(parcelas_summary) from parcelas_summary),
      'politicas_summary', (select to_jsonb(politicas_summary) from politicas_summary),
      'operacoes_summary', (select to_jsonb(operacoes_summary) from operacoes_summary),
      'fixture_candidate_summary', (select to_jsonb(fixture_candidate_summary) from fixture_candidate_summary)
    )

  union all
  select
    10,
    '10_security_findings',
    'achados de segurança antes da RPC 5A',
    case
      when (select rpc_5a_anon_execute_if_exists from function_security_findings) = 0 then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'function_security_findings', (select to_jsonb(function_security_findings) from function_security_findings),
      'table_security_findings', (select to_jsonb(table_security_findings) from table_security_findings)
    )

  union all
  select
    11,
    '11_migration_5a_contract_reminder',
    'lembrete de contrato para futura migration 5A',
    'INFO',
    jsonb_build_object(
      'rpc_candidata', 'public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)',
      'visao', 'administrativa',
      'cliente_safe', false,
      'persistencia', false,
      'dml_financeiro', false,
      'modo_base', array['melhor_aplicacao','antecipacao','postergacao','vpl','comparativo'],
      'proibido', array['INSERT/UPDATE/DELETE em operacoes','INSERT/UPDATE/DELETE em parcelas','INSERT/UPDATE/DELETE em agendas','frontend soberano','payload cliente-safe como fonte de cálculo','EXECUTE para anon']
    )

  union all
  select
    13,
    '13_operational_interpretation',
    'interpretação operacional final para iniciar ou bloquear a migration 5A',
    case when recommended_next_step like 'OK_PARA_CRIAR_MIGRATION_5A_SIMULACAO_IMPACTO:%' then 'PASS' else 'FAIL' end,
    to_jsonb(interpretation)
  from interpretation

  union all
  select
    99,
    '99_end',
    'fim do preflight 5A',
    'INFO',
    jsonb_build_object(
      'instruction', 'Preflight read-only 5A concluído. Envie este resultset único completo antes de criar qualquer migration/RPC 5A.',
      'next_expected_file_if_pass', 'supabase/migrations/<timestamp>_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql'
    )
)
select
  ordem,
  section,
  item,
  status,
  detalhe
from section_rows
order by ordem;
