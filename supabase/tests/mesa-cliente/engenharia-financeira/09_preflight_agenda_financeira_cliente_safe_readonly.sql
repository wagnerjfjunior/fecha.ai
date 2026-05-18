-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4C
-- 09 Preflight Read-only — Agenda financeira cliente-safe.
--
-- Objetivo:
--   Mapear o schema real e os riscos de exposição antes de criar a RPC cliente-safe.
--
-- Este arquivo é read-only:
--   - não cria fixture
--   - não chama RPC de persistência
--   - não faz INSERT/UPDATE/DELETE
--   - não faz DDL
--
-- Uso:
--   Rodar o arquivo inteiro no Supabase SQL Editor como role postgres.
--   Enviar o resultset único completo.

with
rpc_4b as (
  select to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)') as oid
),
rpc_4c as (
  select to_regprocedure('public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)') as oid
),
rpc_status as (
  select
    '4B_persistencia_agenda' as rpc_label,
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
    coalesce(has_function_privilege('anon', r.oid, 'EXECUTE'), false) as anon_can_execute,
    coalesce(has_function_privilege('authenticated', r.oid, 'EXECUTE'), false) as authenticated_can_execute,
    pg_get_function_identity_arguments(r.oid) as identity_arguments
  from rpc_4b r
  left join pg_proc p on p.oid = r.oid

  union all

  select
    '4C_cliente_safe_candidata' as rpc_label,
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
    coalesce(has_function_privilege('anon', r.oid, 'EXECUTE'), false) as anon_can_execute,
    coalesce(has_function_privilege('authenticated', r.oid, 'EXECUTE'), false) as authenticated_can_execute,
    pg_get_function_identity_arguments(r.oid) as identity_arguments
  from rpc_4c r
  left join pg_proc p on p.oid = r.oid
),
tables_inventory as (
  select
    x.table_name,
    to_regclass('public.' || x.table_name) is not null as exists_in_database,
    coalesce(c.relrowsecurity, false) as rls_enabled,
    coalesce(c.relforcerowsecurity, false) as rls_forced,
    pg_get_userbyid(c.relowner) as owner_name
  from (
    values
      ('mesa_simulacoes'),
      ('mesa_cliente_agendas_financeiras'),
      ('mesa_cliente_fluxo_parcelas'),
      ('mesa_cliente_fluxo_operacoes'),
      ('corretores'),
      ('empreendimentos')
  ) as x(table_name)
  left join pg_class c
    on c.oid = to_regclass('public.' || x.table_name)
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
    c.is_identity
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name in (
      'mesa_simulacoes',
      'mesa_cliente_agendas_financeiras',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes',
      'corretores',
      'empreendimentos'
    )
),
agendas_cols as (
  select * from cols where table_name = 'mesa_cliente_agendas_financeiras'
),
parcelas_cols as (
  select * from cols where table_name = 'mesa_cliente_fluxo_parcelas'
),
simulacoes_cols as (
  select * from cols where table_name = 'mesa_simulacoes'
),
expected_agenda_cols as (
  select * from (
    values
      ('id', true),
      ('empresa_id', true),
      ('simulacao_id', true),
      ('empreendimento_id', true),
      ('status', true),
      ('versao', false),
      ('checksum', false),
      ('totais', true),
      ('created_at', false),
      ('updated_at', false)
  ) as e(column_name, required_for_4c)
),
expected_parcela_cols as (
  select * from (
    values
      ('id', true),
      ('agenda_id', true),
      ('empresa_id', true),
      ('simulacao_id', true),
      ('empreendimento_id', true),
      ('grupo', true),
      ('descricao', false),
      ('ordem', false),
      ('parcela_numero', false),
      ('parcelas_total_item', false),
      ('data_vencimento', true),
      ('valor_atual', true),
      ('negociavel', true),
      ('motivos_bloqueio', false),
      ('metadata', false),
      ('created_at', false),
      ('updated_at', false)
  ) as e(column_name, required_for_4c)
),
expected_simulacao_cols as (
  select * from (
    values
      ('id', true),
      ('empresa_id', true),
      ('corretor_id', true),
      ('empreendimento_id', true),
      ('cliente_nome', false),
      ('snapshot_payload', false),
      ('metadata', false),
      ('created_at', false),
      ('updated_at', false)
  ) as e(column_name, required_for_4c)
),
agenda_expected_status as (
  select
    e.column_name,
    e.required_for_4c,
    c.column_name is not null as exists_in_database,
    c.data_type,
    c.udt_name,
    c.is_nullable
  from expected_agenda_cols e
  left join agendas_cols c on c.column_name = e.column_name
),
parcela_expected_status as (
  select
    e.column_name,
    e.required_for_4c,
    c.column_name is not null as exists_in_database,
    c.data_type,
    c.udt_name,
    c.is_nullable
  from expected_parcela_cols e
  left join parcelas_cols c on c.column_name = e.column_name
),
simulacao_expected_status as (
  select
    e.column_name,
    e.required_for_4c,
    c.column_name is not null as exists_in_database,
    c.data_type,
    c.udt_name,
    c.is_nullable
  from expected_simulacao_cols e
  left join simulacoes_cols c on c.column_name = e.column_name
),
sensitive_cols as (
  select
    table_name,
    column_name,
    case
      when column_name in ('metadata', 'snapshot_payload') then 'payload_ou_metadata_bruto'
      when column_name in ('checksum', 'versao') then 'controle_interno'
      when column_name in ('created_by', 'updated_by', 'criado_por', 'atualizado_por', 'confirmado_por', 'cancelado_por') then 'auditoria_usuario'
      when column_name ilike '%vpl%' then 'vpl'
      when column_name ilike '%premio%' or column_name ilike '%prêmio%' then 'premio'
      when column_name ilike '%comissao%' or column_name ilike '%comissão%' then 'comissao'
      when column_name ilike '%politica%' or column_name ilike '%política%' then 'politica_interna'
      when column_name ilike '%taxa%' then 'taxa_interna_ou_calculo'
      when column_name ilike '%desconto%' then 'calculo_interno'
      when column_name ilike '%acrescimo%' or column_name ilike '%acréscimo%' then 'calculo_interno'
      when column_name ilike '%economia%' then 'calculo_interno'
      else 'revisar'
    end as risco_cliente_safe
  from cols
  where column_name in (
      'metadata', 'snapshot_payload', 'checksum', 'versao',
      'created_by', 'updated_by', 'criado_por', 'atualizado_por',
      'confirmado_por', 'cancelado_por'
    )
     or column_name ilike '%vpl%'
     or column_name ilike '%premio%'
     or column_name ilike '%prêmio%'
     or column_name ilike '%comissao%'
     or column_name ilike '%comissão%'
     or column_name ilike '%politica%'
     or column_name ilike '%política%'
     or column_name ilike '%taxa%'
     or column_name ilike '%desconto%'
     or column_name ilike '%acrescimo%'
     or column_name ilike '%acréscimo%'
     or column_name ilike '%economia%'
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
    and rel.relname in ('mesa_simulacoes', 'mesa_cliente_agendas_financeiras', 'mesa_cliente_fluxo_parcelas')
),
indexes_inventory as (
  select
    i.tablename as table_name,
    i.indexname,
    i.indexdef
  from pg_indexes i
  where i.schemaname = 'public'
    and i.tablename in ('mesa_simulacoes', 'mesa_cliente_agendas_financeiras', 'mesa_cliente_fluxo_parcelas')
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
    and p.tablename in ('mesa_simulacoes', 'mesa_cliente_agendas_financeiras', 'mesa_cliente_fluxo_parcelas')
),
grants_inventory as (
  select
    g.table_name,
    g.grantee,
    g.privilege_type,
    g.is_grantable
  from information_schema.role_table_grants g
  where g.table_schema = 'public'
    and g.table_name in ('mesa_simulacoes', 'mesa_cliente_agendas_financeiras', 'mesa_cliente_fluxo_parcelas')
),
counts as (
  select 'mesa_cliente_agendas_financeiras' as table_name, count(*)::bigint as total_rows from public.mesa_cliente_agendas_financeiras
  union all
  select 'mesa_cliente_fluxo_parcelas', count(*)::bigint from public.mesa_cliente_fluxo_parcelas
  union all
  select 'mesa_simulacoes', count(*)::bigint from public.mesa_simulacoes
),
active_agendas_summary as (
  select
    count(*)::bigint as total_agendas,
    count(*) filter (where status = 'ativa')::bigint as agendas_ativas,
    count(distinct simulacao_id)::bigint as simulacoes_com_agenda,
    count(*) filter (where status = 'ativa' and totals is not null)::bigint as ativas_com_totais
  from public.mesa_cliente_agendas_financeiras
),
active_parcelas_summary as (
  select
    count(*)::bigint as total_parcelas,
    count(*) filter (where agenda_id is not null)::bigint as parcelas_com_agenda_id,
    count(*) filter (where data_vencimento is not null)::bigint as parcelas_com_data,
    count(*) filter (where valor_atual is not null)::bigint as parcelas_com_valor_atual,
    count(*) filter (where negociavel is not null)::bigint as parcelas_com_negociavel
  from public.mesa_cliente_fluxo_parcelas
),
fixture_candidate_summary as (
  select
    count(*)::bigint as total_candidatos
  from public.mesa_cliente_agendas_financeiras a
  join public.mesa_cliente_fluxo_parcelas p
    on p.agenda_id = a.id
   and p.simulacao_id = a.simulacao_id
   and p.empresa_id = a.empresa_id
  join public.mesa_simulacoes s
    on s.id = a.simulacao_id
   and s.empresa_id = a.empresa_id
  where a.status = 'ativa'
),
auth_helpers as (
  select
    x.function_name,
    to_regprocedure(x.signature) is not null as exists_in_database,
    x.signature
  from (
    values
      ('mesa_cliente_assert_auth', 'public.mesa_cliente_assert_auth()'),
      ('my_empresa_id', 'public.my_empresa_id()'),
      ('is_root', 'public.is_root()')
  ) as x(function_name, signature)
),
required_missing as (
  select 'agenda' as area, count(*)::integer as qtd
  from agenda_expected_status
  where required_for_4c and not exists_in_database

  union all

  select 'parcelas', count(*)::integer
  from parcela_expected_status
  where required_for_4c and not exists_in_database

  union all

  select 'simulacao', count(*)::integer
  from simulacao_expected_status
  where required_for_4c and not exists_in_database
),
interpretation as (
  select
    (select bool_and(exists_in_database) from tables_inventory where table_name in ('mesa_simulacoes','mesa_cliente_agendas_financeiras','mesa_cliente_fluxo_parcelas','corretores','empreendimentos')) as required_tables_exist,
    (select exists_in_database from rpc_status where rpc_label = '4B_persistencia_agenda') as rpc_4b_exists,
    (select coalesce(anon_can_execute, false) from rpc_status where rpc_label = '4C_cliente_safe_candidata') as rpc_4c_anon_can_execute_if_exists,
    (select coalesce(exists_in_database, false) from rpc_status where rpc_label = '4C_cliente_safe_candidata') as rpc_4c_already_exists,
    (select sum(qtd) from required_missing)::integer as total_required_missing,
    (select count(*) from sensitive_cols)::integer as total_sensitive_columns_to_filter,
    (select total_candidatos from fixture_candidate_summary)::bigint as total_fixture_candidates_existing,
    case
      when not (select bool_and(exists_in_database) from tables_inventory where table_name in ('mesa_simulacoes','mesa_cliente_agendas_financeiras','mesa_cliente_fluxo_parcelas','corretores','empreendimentos'))
        then 'BLOQUEAR: tabela obrigatória ausente.'
      when not (select exists_in_database from rpc_status where rpc_label = '4B_persistencia_agenda')
        then 'BLOQUEAR: RPC 4B não existe; 4C depende da agenda persistida.'
      when (select coalesce(anon_can_execute, false) from rpc_status where rpc_label = '4C_cliente_safe_candidata')
        then 'BLOQUEAR: RPC 4C existente com EXECUTE para anon.'
      when (select sum(qtd) from required_missing) > 0
        then 'BLOQUEAR: há colunas obrigatórias ausentes para leitura cliente-safe.'
      else 'OK_PARA_CRIAR_MIGRATION_4C_CLIENTE_SAFE: schema mínimo mapeado; criar RPC sem expor campos sensíveis listados.'
    end as recommended_next_step
),
section_rows as (
  select
    1 as ordem,
    '01_tables_inventory' as section,
    'tabelas necessárias para 4C' as item,
    case when bool_and(exists_in_database) then 'PASS' else 'FAIL' end as status,
    jsonb_agg(to_jsonb(tables_inventory) order by table_name) as detalhe
  from tables_inventory

  union all
  select
    2,
    '02_rpc_status',
    'RPCs 4B e 4C candidata',
    case
      when (select exists_in_database from rpc_status where rpc_label = '4B_persistencia_agenda')
       and not (select coalesce(anon_can_execute, false) from rpc_status where rpc_label = '4C_cliente_safe_candidata')
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_agg(to_jsonb(rpc_status) order by rpc_label)
  from rpc_status

  union all
  select
    3,
    '03_agendas_columns_inventory',
    'colunas reais de agendas financeiras',
    case when count(*) > 0 then 'INFO' else 'FAIL' end,
    jsonb_agg(to_jsonb(agendas_cols) order by ordinal_position)
  from agendas_cols

  union all
  select
    4,
    '04_parcelas_columns_inventory',
    'colunas reais de parcelas financeiras',
    case when count(*) > 0 then 'INFO' else 'FAIL' end,
    jsonb_agg(to_jsonb(parcelas_cols) order by ordinal_position)
  from parcelas_cols

  union all
  select
    5,
    '05_simulacoes_columns_inventory',
    'colunas reais de mesa_simulacoes',
    case when count(*) > 0 then 'INFO' else 'FAIL' end,
    jsonb_agg(to_jsonb(simulacoes_cols) order by ordinal_position)
  from simulacoes_cols

  union all
  select
    6,
    '06_expected_required_columns_status',
    'status das colunas mínimas 4C',
    case when (select sum(qtd) from required_missing) = 0 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda', (select jsonb_agg(to_jsonb(agenda_expected_status) order by column_name) from agenda_expected_status),
      'parcelas', (select jsonb_agg(to_jsonb(parcela_expected_status) order by column_name) from parcela_expected_status),
      'simulacao', (select jsonb_agg(to_jsonb(simulacao_expected_status) order by column_name) from simulacao_expected_status),
      'missing_summary', (select jsonb_agg(to_jsonb(required_missing) order by area) from required_missing)
    )

  union all
  select
    7,
    '07_sensitive_columns_to_filter',
    'campos sensíveis que não podem sair no cliente-safe',
    case when count(*) >= 0 then 'INFO' else 'INFO' end,
    coalesce(jsonb_agg(to_jsonb(sensitive_cols) order by table_name, column_name), '[]'::jsonb)
  from sensitive_cols

  union all
  select
    8,
    '08_constraints_inventory',
    'constraints relevantes',
    'INFO',
    coalesce(jsonb_agg(to_jsonb(constraints_inventory) order by table_name, constraint_type, constraint_name), '[]'::jsonb)
  from constraints_inventory

  union all
  select
    9,
    '09_indexes_inventory',
    'índices relevantes',
    'INFO',
    coalesce(jsonb_agg(to_jsonb(indexes_inventory) order by table_name, indexname), '[]'::jsonb)
  from indexes_inventory

  union all
  select
    10,
    '10_policies_and_grants',
    'RLS, policies e grants das tabelas 4C',
    'INFO',
    jsonb_build_object(
      'policies', coalesce((select jsonb_agg(to_jsonb(policies_inventory) order by tablename, policyname) from policies_inventory), '[]'::jsonb),
      'grants', coalesce((select jsonb_agg(to_jsonb(grants_inventory) order by table_name, grantee, privilege_type) from grants_inventory), '[]'::jsonb)
    )

  union all
  select
    11,
    '11_counts_and_fixture_candidates',
    'contagens e candidatos existentes para validação 4C',
    'INFO',
    jsonb_build_object(
      'counts', (select jsonb_agg(to_jsonb(counts) order by table_name) from counts),
      'active_agendas_summary', (select to_jsonb(active_agendas_summary) from active_agendas_summary),
      'active_parcelas_summary', (select to_jsonb(active_parcelas_summary) from active_parcelas_summary),
      'fixture_candidate_summary', (select to_jsonb(fixture_candidate_summary) from fixture_candidate_summary)
    )

  union all
  select
    12,
    '12_auth_helpers',
    'funções auxiliares de auth/perfil esperadas',
    case when bool_and(exists_in_database) then 'PASS' else 'WARN' end,
    jsonb_agg(to_jsonb(auth_helpers) order by function_name)
  from auth_helpers

  union all
  select
    13,
    '13_operational_interpretation',
    'interpretação operacional final',
    case when recommended_next_step like 'OK_PARA_CRIAR_MIGRATION_4C_CLIENTE_SAFE:%' then 'PASS' else 'FAIL' end,
    to_jsonb(interpretation)
  from interpretation

  union all
  select
    99,
    '99_end',
    'fim do preflight 4C',
    'INFO',
    jsonb_build_object(
      'instruction', 'Preflight read-only 4C concluído. Envie este resultset único completo antes de criar a migration cliente-safe.'
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
