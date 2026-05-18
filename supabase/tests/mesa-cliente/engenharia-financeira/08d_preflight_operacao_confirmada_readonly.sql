-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4B
-- 08D Preflight Read-only — Operação confirmada bloqueia substituição de agenda.
--
-- Objetivo:
--   Mapear o schema real necessário para reescrever o teste 08D canônico sem premissas.
--
-- Este arquivo NÃO valida a regra de negócio ainda.
-- Este arquivo NÃO cria fixture.
-- Este arquivo NÃO chama RPC de persistência.
-- Este arquivo NÃO faz INSERT, UPDATE, DELETE ou DDL.
--
-- Regra de uso:
--   1. Rodar este SQL inteiro no Supabase SQL Editor, role postgres.
--   2. Enviar todos os resultsets.
--   3. Só depois criar/substituir o teste 08D canônico.
--
-- Critério:
--   Se qualquer seção indicar ausência de tabela, função, coluna obrigatória,
--   enum incompatível ou grant inseguro, o 08D canônico NÃO deve ser criado ainda.

-- 01) Inventário das tabelas envolvidas na regra do 08D.
select
  '01_tables_inventory' as section,
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
order by x.table_name;

-- 02) Status da RPC 4B canônica.
with p as (
  select to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)') as oid
)
select
  '02_rpc_4b_status' as section,
  'mesa_cliente_persistir_agenda_financeira_admin' as function_name,
  'mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)' as expected_signature,
  p.oid is not null as exists_in_database,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  case when pr.prosecdef then true else false end as security_definer,
  pr.provolatile as volatility_code,
  case pr.provolatile
    when 'i' then 'immutable'
    when 's' then 'stable'
    when 'v' then 'volatile'
    else null
  end as volatility_label,
  pg_get_userbyid(pr.proowner) as owner_name,
  pr.proconfig as function_config,
  coalesce(has_function_privilege('anon', p.oid, 'EXECUTE'), false) as anon_can_execute,
  coalesce(has_function_privilege('authenticated', p.oid, 'EXECUTE'), false) as authenticated_can_execute
from p
left join pg_proc pr
  on pr.oid = p.oid;

-- 03) Inventário completo de colunas da tabela de operações financeiras.
select
  '03_operacoes_columns_inventory' as section,
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
order by c.ordinal_position;

-- 04) Colunas que o 08D provavelmente precisa preencher para criar operação confirmada.
-- Esta seção não afirma obrigatoriedade funcional; ela mostra se o schema suporta a fixture.
with expected(column_name, expected_use) as (
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
), cols as (
  select
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.is_identity
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
)
select
  '04_operacoes_expected_columns' as section,
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
from expected e
left join cols c
  on c.column_name = e.column_name
order by e.column_name;

-- 05) Colunas obrigatórias sem default na tabela de operações.
-- O novo 08D deve mapear todas elas ou não será confiável.
select
  '05_operacoes_required_columns_without_default' as section,
  c.column_name,
  c.data_type,
  c.udt_schema,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  c.is_identity
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name = 'mesa_cliente_fluxo_operacoes'
  and c.is_nullable = 'NO'
  and c.column_default is null
  and coalesce(c.is_identity, 'NO') = 'NO'
order by c.ordinal_position;

-- 06) Enum de tipo de operação financeira.
with t as (
  select to_regtype('public.mesa_financeira_operacao_tipo') as oid
)
select
  '06_enum_mesa_financeira_operacao_tipo' as section,
  t.oid is not null as enum_exists,
  e.enumsortorder,
  e.enumlabel
from t
left join pg_enum e
  on e.enumtypid = t.oid
order by e.enumsortorder nulls last;

-- 07) Enum/tipo da coluna status_operacao, quando existir.
with col as (
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
)
select
  '07_status_operacao_type_values' as section,
  col.column_name,
  col.data_type,
  col.udt_schema,
  col.udt_name,
  col.type_oid is not null as is_user_defined_type,
  e.enumsortorder,
  e.enumlabel
from col
left join pg_enum e
  on e.enumtypid = col.type_oid
order by e.enumsortorder nulls last;

-- 08) Constraints da tabela de operações financeiras.
select
  '08_operacoes_constraints' as section,
  con.conname as constraint_name,
  con.contype as constraint_type,
  pg_get_constraintdef(con.oid) as constraint_definition
from pg_constraint con
join pg_class rel
  on rel.oid = con.conrelid
join pg_namespace nsp
  on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname = 'mesa_cliente_fluxo_operacoes'
order by con.contype, con.conname;

-- 09) Índices da tabela de operações financeiras.
select
  '09_operacoes_indexes' as section,
  i.indexname,
  i.indexdef
from pg_indexes i
where i.schemaname = 'public'
  and i.tablename = 'mesa_cliente_fluxo_operacoes'
order by i.indexname;

-- 10) RLS/policies/grants da tabela de operações financeiras.
select
  '10a_operacoes_rls' as section,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
where c.oid = to_regclass('public.mesa_cliente_fluxo_operacoes');

select
  '10b_operacoes_policies' as section,
  p.schemaname,
  p.tablename,
  p.policyname,
  p.cmd,
  p.roles,
  p.qual,
  p.with_check
from pg_policies p
where p.schemaname = 'public'
  and p.tablename = 'mesa_cliente_fluxo_operacoes'
order by p.policyname;

select
  '10c_operacoes_grants' as section,
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type,
  g.is_grantable
from information_schema.role_table_grants g
where g.table_schema = 'public'
  and g.table_name = 'mesa_cliente_fluxo_operacoes'
order by g.grantee, g.privilege_type;

-- 11) Colunas mínimas para a validação de bloqueio dentro da RPC 4B.
-- Se alguma estiver ausente, o bloqueio por operação confirmada precisa ser revisto na migration.
with expected(column_name, reason) as (
  values
    ('empresa_id', 'escopo tenant'),
    ('simulacao_id', 'escopo da simulação'),
    ('confirmado', 'identificar operação confirmada por flag'),
    ('status_operacao', 'identificar operação confirmada por status')
), cols as (
  select c.column_name, c.data_type, c.udt_schema, c.udt_name
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
)
select
  '11_columns_for_confirmed_operation_guard' as section,
  e.column_name,
  e.reason,
  c.column_name is not null as exists_in_database,
  c.data_type,
  c.udt_schema,
  c.udt_name
from expected e
left join cols c
  on c.column_name = e.column_name
order by e.column_name;

-- 12) Inventário das colunas relevantes de agenda e parcelas para validar integridade pós-bloqueio.
select
  '12a_agendas_relevant_columns' as section,
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
order by c.ordinal_position;

select
  '12b_parcelas_relevant_columns' as section,
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
order by c.ordinal_position;

-- 13) Contagens atuais das tabelas financeiras.
-- Read-only: apenas mede o estado atual antes do 08D canônico.
select
  '13_financial_tables_counts' as section,
  'mesa_cliente_agendas_financeiras' as table_name,
  count(*)::bigint as total_rows
from public.mesa_cliente_agendas_financeiras
union all
select
  '13_financial_tables_counts',
  'mesa_cliente_fluxo_parcelas',
  count(*)::bigint
from public.mesa_cliente_fluxo_parcelas
union all
select
  '13_financial_tables_counts',
  'mesa_cliente_fluxo_operacoes',
  count(*)::bigint
from public.mesa_cliente_fluxo_operacoes
order by table_name;

-- 14) Operações já confirmadas existentes no banco.
-- Não deve bloquear o teste, mas ajuda a entender se há dados reais em produção.
select
  '14_existing_confirmed_operations_summary' as section,
  count(*)::bigint as total_operacoes,
  count(*) filter (where coalesce(confirmado, false) is true)::bigint as confirmadas_por_flag,
  count(*) filter (where status_operacao::text = 'confirmada')::bigint as confirmadas_por_status,
  count(*) filter (where coalesce(confirmado, false) is true or status_operacao::text = 'confirmada')::bigint as confirmadas_total_criterio_rpc
from public.mesa_cliente_fluxo_operacoes;

-- 15) Interpretação operacional read-only.
with tables as (
  select
    to_regclass('public.mesa_cliente_fluxo_operacoes') is not null as operacoes_table_exists,
    to_regclass('public.mesa_cliente_agendas_financeiras') is not null as agendas_table_exists,
    to_regclass('public.mesa_cliente_fluxo_parcelas') is not null as parcelas_table_exists
), rpc as (
  select
    to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)') is not null as rpc_exists,
    coalesce(has_function_privilege('anon', to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'), 'EXECUTE'), false) as anon_can_execute,
    coalesce(has_function_privilege('authenticated', to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'), 'EXECUTE'), false) as authenticated_can_execute
), cols as (
  select
    bool_or(column_name = 'empresa_id') as has_empresa_id,
    bool_or(column_name = 'simulacao_id') as has_simulacao_id,
    bool_or(column_name = 'confirmado') as has_confirmado,
    bool_or(column_name = 'status_operacao') as has_status_operacao
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'mesa_cliente_fluxo_operacoes'
), required_unmapped as (
  select count(*)::integer as qtd_required_without_default
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
    and c.is_nullable = 'NO'
    and c.column_default is null
    and coalesce(c.is_identity, 'NO') = 'NO'
    and c.column_name not in (
      'empresa_id', 'simulacao_id', 'empreendimento_id', 'tipo_operacao',
      'grupo_origem', 'grupo_destino', 'valor_movido', 'data_origem',
      'data_destino', 'taxa_ano_pct', 'valor_base', 'desconto_calculado',
      'acrescimo_calculado', 'economia_liquida', 'visivel_cliente',
      'confirmado', 'confirmado_por', 'confirmado_em', 'status_operacao',
      'metadata', 'created_at', 'updated_at', 'criado_por', 'atualizado_por'
    )
)
select
  '15_operational_interpretation' as section,
  tables.operacoes_table_exists,
  tables.agendas_table_exists,
  tables.parcelas_table_exists,
  rpc.rpc_exists,
  rpc.anon_can_execute,
  rpc.authenticated_can_execute,
  cols.has_empresa_id,
  cols.has_simulacao_id,
  cols.has_confirmado,
  cols.has_status_operacao,
  required_unmapped.qtd_required_without_default as required_columns_not_mapped_by_preflight_model,
  case
    when not tables.operacoes_table_exists then 'BLOQUEAR: tabela mesa_cliente_fluxo_operacoes não existe.'
    when not tables.agendas_table_exists then 'BLOQUEAR: tabela mesa_cliente_agendas_financeiras não existe.'
    when not tables.parcelas_table_exists then 'BLOQUEAR: tabela mesa_cliente_fluxo_parcelas não existe.'
    when not rpc.rpc_exists then 'BLOQUEAR: RPC 4B não existe.'
    when rpc.anon_can_execute then 'BLOQUEAR: anon possui EXECUTE na RPC 4B.'
    when not rpc.authenticated_can_execute then 'BLOQUEAR: authenticated não possui EXECUTE na RPC 4B.'
    when not cols.has_empresa_id or not cols.has_simulacao_id then 'BLOQUEAR: operação financeira não possui colunas mínimas de escopo tenant/simulação.'
    when not cols.has_confirmado and not cols.has_status_operacao then 'BLOQUEAR: operação financeira não possui confirmado nem status_operacao.'
    when required_unmapped.qtd_required_without_default > 0 then 'BLOQUEAR: há colunas obrigatórias sem default que o modelo de fixture ainda não mapeou.'
    else 'OK_PARA_CRIAR_08D_CANONICO: schema mínimo mapeado; enviar resultsets antes de criar o teste.'
  end as recommended_next_step
from tables, rpc, cols, required_unmapped;

-- 99) Fim do preflight.
select
  '99_end' as section,
  'Preflight read-only 08D concluído. Envie todos os resultsets antes de criar/substituir o teste canônico de operação confirmada.' as instruction;
