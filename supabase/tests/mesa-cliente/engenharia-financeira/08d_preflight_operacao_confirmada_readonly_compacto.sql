-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4B
-- 08D Preflight Read-only Compacto — Operação confirmada bloqueia substituição de agenda.
--
-- Objetivo:
--   Retornar UM ÚNICO resultset consolidado para evitar que o Supabase SQL Editor
--   mostre apenas o último SELECT do preflight detalhado.
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
rpc as (
  select
    to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)') as oid
),
rpc_status as (
  select
    r.oid is not null as rpc_exists,
    case when p.prosecdef then true else false end as security_definer,
    p.provolatile as volatility_code,
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
  from rpc r
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
      ('mesa_cliente_fluxo_operacoes')
  ) as x(table_name)
  left join pg_class c
    on c.oid = to_regclass('public.' || x.table_name)
),
operacoes_cols as (
  select
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.is_identity,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
),
expected_cols as (
  select * from (
    values
      ('id', 'identificador da operação'),
      ('empresa_id', 'tenant/empresa da operação'),
      ('simulacao_id', 'simulação ligada à agenda'),
      ('empreendimento_id', 'empreendimento da simulação'),
      ('tipo_operacao', 'tipo financeiro da operação'),
      ('grupo_origem', 'grupo financeiro de origem'),
      ('grupo_destino', 'grupo financeiro de destino'),
      ('valor_movido', 'valor movimentado'),
      ('data_origem', 'data financeira de origem'),
      ('data_destino', 'data financeira de destino'),
      ('taxa_ano_pct', 'taxa usada no cálculo'),
      ('valor_base', 'base de cálculo'),
      ('desconto_calculado', 'desconto calculado'),
      ('acrescimo_calculado', 'acréscimo calculado'),
      ('economia_liquida', 'economia líquida'),
      ('visivel_cliente', 'flag cliente-safe'),
      ('confirmado', 'flag de confirmação'),
      ('confirmado_por', 'usuário que confirmou'),
      ('confirmado_em', 'timestamp de confirmação'),
      ('status_operacao', 'status textual/enum da operação'),
      ('metadata', 'metadados da fixture/teste')
  ) as e(column_name, expected_use)
),
expected_cols_status as (
  select
    e.column_name,
    e.expected_use,
    c.column_name is not null as exists_in_database,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.is_identity,
    case
      when c.column_name is null then 'AUSENTE'
      when c.is_nullable = 'NO' and c.column_default is null and coalesce(c.is_identity, 'NO') = 'NO' then 'OBRIGATORIA_SEM_DEFAULT'
      when c.is_nullable = 'NO' then 'OBRIGATORIA_COM_DEFAULT_OU_IDENTITY'
      else 'OPCIONAL'
    end as fixture_mapping_pressure
  from expected_cols e
  left join operacoes_cols c on c.column_name = e.column_name
),
required_without_default as (
  select
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.is_identity,
    case
      when c.column_name in (
        'empresa_id', 'simulacao_id', 'empreendimento_id', 'tipo_operacao',
        'grupo_origem', 'grupo_destino', 'valor_movido', 'data_origem',
        'data_destino', 'taxa_ano_pct', 'valor_base', 'desconto_calculado',
        'acrescimo_calculado', 'economia_liquida', 'visivel_cliente',
        'confirmado', 'confirmado_por', 'confirmado_em', 'status_operacao',
        'metadata', 'created_at', 'updated_at', 'criado_por', 'atualizado_por'
      ) then true
      else false
    end as mapped_by_fixture_model
  from operacoes_cols c
  where c.is_nullable = 'NO'
    and c.column_default is null
    and coalesce(c.is_identity, 'NO') = 'NO'
),
required_unmapped as (
  select count(*)::integer as qtd
  from required_without_default
  where mapped_by_fixture_model is false
),
enum_tipo as (
  select
    e.enumsortorder,
    e.enumlabel
  from pg_enum e
  where e.enumtypid = 'public.mesa_financeira_operacao_tipo'::regtype
),
status_operacao_col as (
  select
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    case
      when c.data_type = 'USER-DEFINED' then to_regtype(format('%I.%I', c.udt_schema, c.udt_name))
      else null::regtype
    end as type_oid
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
    and c.column_name = 'status_operacao'
),
status_operacao_values as (
  select
    col.column_name,
    col.data_type,
    col.udt_schema,
    col.udt_name,
    col.type_oid is not null as is_user_defined_type,
    e.enumsortorder,
    e.enumlabel
  from status_operacao_col col
  left join pg_enum e on e.enumtypid = col.type_oid
),
constraints_operacoes as (
  select
    con.conname as constraint_name,
    con.contype as constraint_type,
    pg_get_constraintdef(con.oid) as constraint_definition
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  where nsp.nspname = 'public'
    and rel.relname = 'mesa_cliente_fluxo_operacoes'
),
indexes_operacoes as (
  select
    i.indexname,
    i.indexdef
  from pg_indexes i
  where i.schemaname = 'public'
    and i.tablename = 'mesa_cliente_fluxo_operacoes'
),
rls_operacoes as (
  select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as rls_forced
  from pg_class c
  where c.oid = to_regclass('public.mesa_cliente_fluxo_operacoes')
),
policies_operacoes as (
  select
    p.policyname,
    p.cmd,
    p.roles,
    p.qual,
    p.with_check
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'mesa_cliente_fluxo_operacoes'
),
grants_operacoes as (
  select
    g.grantee,
    g.privilege_type,
    g.is_grantable
  from information_schema.role_table_grants g
  where g.table_schema = 'public'
    and g.table_name = 'mesa_cliente_fluxo_operacoes'
),
guard_cols as (
  select
    bool_or(column_name = 'empresa_id') as has_empresa_id,
    bool_or(column_name = 'simulacao_id') as has_simulacao_id,
    bool_or(column_name = 'confirmado') as has_confirmado,
    bool_or(column_name = 'status_operacao') as has_status_operacao
  from operacoes_cols
),
agendas_cols as (
  select
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_agendas_financeiras'
    and c.column_name in ('id', 'empresa_id', 'simulacao_id', 'empreendimento_id', 'status', 'versao', 'checksum', 'totais', 'created_at', 'updated_at')
),
parcelas_cols as (
  select
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_parcelas'
    and c.column_name in ('id', 'agenda_id', 'empresa_id', 'simulacao_id', 'empreendimento_id', 'grupo', 'valor_atual', 'data_vencimento', 'negociavel', 'motivos_bloqueio', 'created_at', 'updated_at')
),
counts as (
  select 'mesa_cliente_agendas_financeiras' as table_name, count(*)::bigint as total_rows from public.mesa_cliente_agendas_financeiras
  union all
  select 'mesa_cliente_fluxo_parcelas', count(*)::bigint from public.mesa_cliente_fluxo_parcelas
  union all
  select 'mesa_cliente_fluxo_operacoes', count(*)::bigint from public.mesa_cliente_fluxo_operacoes
),
confirmed_summary as (
  select
    count(*)::bigint as total_operacoes,
    count(*) filter (where coalesce(confirmado, false) is true)::bigint as confirmadas_por_flag,
    count(*) filter (where status_operacao::text = 'confirmada')::bigint as confirmadas_por_status,
    count(*) filter (where coalesce(confirmado, false) is true or status_operacao::text = 'confirmada')::bigint as confirmadas_total_criterio_rpc
  from public.mesa_cliente_fluxo_operacoes
),
interpretation as (
  select
    (select exists_in_database from tables_inventory where table_name = 'mesa_cliente_fluxo_operacoes') as operacoes_table_exists,
    (select exists_in_database from tables_inventory where table_name = 'mesa_cliente_agendas_financeiras') as agendas_table_exists,
    (select exists_in_database from tables_inventory where table_name = 'mesa_cliente_fluxo_parcelas') as parcelas_table_exists,
    rs.rpc_exists,
    rs.anon_can_execute,
    rs.authenticated_can_execute,
    gc.has_empresa_id,
    gc.has_simulacao_id,
    gc.has_confirmado,
    gc.has_status_operacao,
    ru.qtd as required_columns_not_mapped_by_preflight_model,
    case
      when not (select exists_in_database from tables_inventory where table_name = 'mesa_cliente_fluxo_operacoes') then 'BLOQUEAR: tabela mesa_cliente_fluxo_operacoes não existe.'
      when not (select exists_in_database from tables_inventory where table_name = 'mesa_cliente_agendas_financeiras') then 'BLOQUEAR: tabela mesa_cliente_agendas_financeiras não existe.'
      when not (select exists_in_database from tables_inventory where table_name = 'mesa_cliente_fluxo_parcelas') then 'BLOQUEAR: tabela mesa_cliente_fluxo_parcelas não existe.'
      when not rs.rpc_exists then 'BLOQUEAR: RPC 4B não existe.'
      when rs.anon_can_execute then 'BLOQUEAR: anon possui EXECUTE na RPC 4B.'
      when not rs.authenticated_can_execute then 'BLOQUEAR: authenticated não possui EXECUTE na RPC 4B.'
      when not gc.has_empresa_id or not gc.has_simulacao_id then 'BLOQUEAR: operação financeira não possui colunas mínimas de escopo tenant/simulação.'
      when not gc.has_confirmado and not gc.has_status_operacao then 'BLOQUEAR: operação financeira não possui confirmado nem status_operacao.'
      when ru.qtd > 0 then 'BLOQUEAR: há colunas obrigatórias sem default que o modelo de fixture ainda não mapeou.'
      else 'OK_PARA_CRIAR_08D_CANONICO: schema mínimo mapeado; enviar este resultset antes de criar o teste.'
    end as recommended_next_step
  from rpc_status rs, guard_cols gc, required_unmapped ru
)
select
  1 as ordem,
  '01_tables_inventory' as section,
  'tabelas envolvidas' as item,
  case when bool_and(exists_in_database) then 'PASS' else 'FAIL' end as status,
  jsonb_agg(to_jsonb(tables_inventory) order by table_name) as detalhe
from tables_inventory

union all
select
  2,
  '02_rpc_4b_status',
  'RPC 4B canônica',
  case when rpc_exists and security_definer and not anon_can_execute and authenticated_can_execute then 'PASS' else 'FAIL' end,
  to_jsonb(rpc_status)
from rpc_status

union all
select
  3,
  '03_operacoes_columns_inventory',
  'colunas reais de mesa_cliente_fluxo_operacoes',
  case when count(*) > 0 then 'INFO' else 'FAIL' end,
  jsonb_agg(to_jsonb(operacoes_cols) order by ordinal_position)
from operacoes_cols

union all
select
  4,
  '04_operacoes_expected_columns',
  'colunas esperadas para fixture 08D',
  case when bool_and(exists_in_database) then 'PASS' else 'WARN' end,
  jsonb_agg(to_jsonb(expected_cols_status) order by column_name)
from expected_cols_status

union all
select
  5,
  '05_operacoes_required_columns_without_default',
  'colunas obrigatórias sem default',
  case when count(*) filter (where mapped_by_fixture_model is false) = 0 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'qtd_required_without_default', count(*),
    'qtd_unmapped_by_fixture_model', count(*) filter (where mapped_by_fixture_model is false),
    'columns', coalesce(jsonb_agg(to_jsonb(required_without_default) order by column_name), '[]'::jsonb)
  )
from required_without_default

union all
select
  6,
  '06_enum_mesa_financeira_operacao_tipo',
  'valores do enum de tipo de operação',
  case when count(*) > 0 then 'PASS' else 'FAIL' end,
  coalesce(jsonb_agg(to_jsonb(enum_tipo) order by enumsortorder), '[]'::jsonb)
from enum_tipo

union all
select
  7,
  '07_status_operacao_type_values',
  'tipo e valores de status_operacao',
  case when count(*) > 0 then 'INFO' else 'WARN' end,
  coalesce(jsonb_agg(to_jsonb(status_operacao_values) order by enumsortorder nulls last), '[]'::jsonb)
from status_operacao_values

union all
select
  8,
  '08_operacoes_constraints',
  'constraints da tabela de operações',
  'INFO',
  coalesce(jsonb_agg(to_jsonb(constraints_operacoes) order by constraint_type, constraint_name), '[]'::jsonb)
from constraints_operacoes

union all
select
  9,
  '09_operacoes_indexes',
  'índices da tabela de operações',
  'INFO',
  coalesce(jsonb_agg(to_jsonb(indexes_operacoes) order by indexname), '[]'::jsonb)
from indexes_operacoes

union all
select
  10,
  '10_operacoes_rls_policies_grants',
  'RLS, policies e grants da tabela de operações',
  'INFO',
  jsonb_build_object(
    'rls', (select to_jsonb(rls_operacoes) from rls_operacoes limit 1),
    'policies', coalesce((select jsonb_agg(to_jsonb(policies_operacoes) order by policyname) from policies_operacoes), '[]'::jsonb),
    'grants', coalesce((select jsonb_agg(to_jsonb(grants_operacoes) order by grantee, privilege_type) from grants_operacoes), '[]'::jsonb)
  )

union all
select
  11,
  '11_columns_for_confirmed_operation_guard',
  'colunas mínimas para bloqueio por operação confirmada',
  case when has_empresa_id and has_simulacao_id and (has_confirmado or has_status_operacao) then 'PASS' else 'FAIL' end,
  to_jsonb(guard_cols)
from guard_cols

union all
select
  12,
  '12_agenda_parcelas_relevant_columns',
  'colunas relevantes para validar integridade pós-bloqueio',
  'INFO',
  jsonb_build_object(
    'agendas', coalesce((select jsonb_agg(to_jsonb(agendas_cols) order by ordinal_position) from agendas_cols), '[]'::jsonb),
    'parcelas', coalesce((select jsonb_agg(to_jsonb(parcelas_cols) order by ordinal_position) from parcelas_cols), '[]'::jsonb)
  )

union all
select
  13,
  '13_financial_tables_counts',
  'contagens atuais das tabelas financeiras',
  'INFO',
  jsonb_agg(to_jsonb(counts) order by table_name)
from counts

union all
select
  14,
  '14_existing_confirmed_operations_summary',
  'operações confirmadas já existentes',
  'INFO',
  to_jsonb(confirmed_summary)
from confirmed_summary

union all
select
  15,
  '15_operational_interpretation',
  'interpretação operacional final',
  case when recommended_next_step like 'OK_PARA_CRIAR_08D_CANONICO:%' then 'PASS' else 'FAIL' end,
  to_jsonb(interpretation)
from interpretation

union all
select
  99,
  '99_end',
  'fim do preflight compacto',
  'INFO',
  jsonb_build_object(
    'instruction', 'Preflight compacto 08D concluído. Envie este resultset único completo antes de criar/substituir o teste canônico de operação confirmada.'
  )
order by ordem;
