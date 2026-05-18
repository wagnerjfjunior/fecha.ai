-- MesaCliente Engenharia Financeira — 07 preflight read-only da agenda legada
--
-- Status: Oficial para o Passo 0 da transição Fase 4A JSON-first
-- Protocolo: docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
-- Documento operacional:
--   docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md
--
-- Objetivo:
--   Validar o estado real do Supabase antes de mover, arquivar, depreciar
--   ou substituir as migrations legadas da agenda persistente.
--
-- Contexto:
--   Os arquivos legados abaixo são coerentes com o desenho antigo persistente,
--   mas não são mais canônicos para a Fase 4A atual:
--
--   supabase/migrations/20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql
--   supabase/migrations/20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql
--   supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql
--   supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_parcelas_negativos_rollback.sql
--
-- Regra atual:
--   4A = JSON-first, sem persistência.
--   4B = persistência segura com lock, idempotência e auditoria.
--   4C = leitura cliente-safe.
--
-- Segurança deste script:
--   - Somente SELECT.
--   - Não cria dados.
--   - Não altera schema.
--   - Não executa RPC financeira.
--   - Não chama a função legada.
--   - Não faz INSERT, UPDATE ou DELETE.
--   - Seguro para SQL Editor da produção.
--
-- Como interpretar:
--   - Se as migrations legadas NÃO foram aplicadas:
--       arquivar/mover arquivos legados fora de supabase/migrations.
--   - Se as migrations legadas JÁ foram aplicadas:
--       não apagar histórico; criar migration corretiva/depreciação/revoke.
--   - Se a função legada existir com EXECUTE para anon:
--       criar correção urgente de REVOKE.

-- ============================================================
-- 1. Controle de execução do preflight
-- ============================================================

select
  '00_preflight_agenda_legada_readonly' as section,
  now() as executed_at,
  current_database() as database_name,
  current_user as current_user_name,
  current_schema() as current_schema_name,
  'READ_ONLY_NO_DML' as safety_mode,
  'NÃO executar migration nova antes de interpretar este resultado' as instruction;

-- ============================================================
-- 2. A tabela de controle de migrations do Supabase existe?
-- ============================================================

select
  '01_supabase_migrations_table' as section,
  to_regclass('supabase_migrations.schema_migrations') is not null as schema_migrations_exists;

-- ============================================================
-- 3. As migrations legadas aparecem como aplicadas?
--
-- Observação:
--   Supabase normalmente registra o timestamp da migration em
--   supabase_migrations.schema_migrations.version.
-- ============================================================

with target_migrations as (
  select * from (values
    (
      '20260517193000',
      '20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql',
      'legado_4a_persistente_primeira_versao'
    ),
    (
      '20260517223000',
      '20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql',
      'legado_4a_persistente_rpc_gerar_agenda_parcelas'
    )
  ) as t(version_prefix, migration_file, classification)
)
select
  '02_legacy_migration_applied_status' as section,
  tm.version_prefix,
  tm.migration_file,
  tm.classification,
  exists (
    select 1
    from supabase_migrations.schema_migrations sm
    where sm.version::text = tm.version_prefix
  ) as applied_exact_version,
  exists (
    select 1
    from supabase_migrations.schema_migrations sm
    where sm.version::text like tm.version_prefix || '%'
  ) as applied_like_prefix
from target_migrations tm
order by tm.version_prefix;

-- ============================================================
-- 4. Funções de agenda: legada x oficial JSON-first
-- ============================================================

with target_functions as (
  select * from (values
    (
      'gerar_mesa_cliente_agenda_parcelas',
      'gerar_mesa_cliente_agenda_parcelas(uuid,date,jsonb,jsonb)',
      'RPC legada persistente — não canônica para 4A atual'
    ),
    (
      'mesa_cliente_resolver_data_parcela',
      'mesa_cliente_resolver_data_parcela(date,jsonb,jsonb,text,integer)',
      'Helper legado da agenda persistente — validar se foi aplicado junto com migration antiga'
    ),
    (
      'mesa_cliente_gerar_agenda_financeira_admin',
      'mesa_cliente_gerar_agenda_financeira_admin(uuid,date,jsonb,jsonb)',
      'RPC oficial esperada da 4A JSON-first — pode ainda não existir antes da nova migration'
    )
  ) as f(function_name, expected_signature, classification)
), functions_found as (
  select
    n.nspname as schema_name,
    p.oid,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_arguments,
    p.prosecdef as security_definer,
    p.provolatile as volatility_code,
    case p.provolatile
      when 'i' then 'immutable'
      when 's' then 'stable'
      when 'v' then 'volatile'
      else p.provolatile::text
    end as volatility_label,
    pg_get_userbyid(p.proowner) as owner_name,
    p.proconfig as function_config
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (select function_name from target_functions)
)
select
  '03_agenda_functions_inventory' as section,
  tf.function_name,
  tf.expected_signature,
  tf.classification,
  ff.oid is not null as exists_in_database,
  ff.identity_arguments,
  ff.security_definer,
  ff.volatility_label,
  ff.owner_name,
  ff.function_config
from target_functions tf
left join functions_found ff on ff.function_name = tf.function_name
order by tf.function_name, ff.identity_arguments;

-- ============================================================
-- 5. Grants das funções de agenda
--
-- Atenção:
--   A função legada não deve ter EXECUTE para anon.
-- ============================================================

with functions_found as (
  select
    p.oid,
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_arguments
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'gerar_mesa_cliente_agenda_parcelas',
      'mesa_cliente_resolver_data_parcela',
      'mesa_cliente_gerar_agenda_financeira_admin'
    )
), roles_to_check as (
  select * from (values
    ('public'),
    ('anon'),
    ('authenticated'),
    ('service_role'),
    ('postgres')
  ) as r(role_name)
)
select
  '04_agenda_function_grants' as section,
  ff.function_name,
  ff.identity_arguments,
  rtc.role_name,
  has_function_privilege(rtc.role_name, ff.oid, 'EXECUTE') as can_execute
from functions_found ff
cross join roles_to_check rtc
order by ff.function_name, ff.identity_arguments, rtc.role_name;

-- ============================================================
-- 6. Dependências cadastradas no catálogo para a função legada
--
-- Objetivo:
--   Detectar objetos do banco que dependem formalmente da RPC legada.
--   Isso não detecta uso por frontend/API fora do banco.
-- ============================================================

with legacy_functions as (
  select
    p.oid,
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_arguments
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gerar_mesa_cliente_agenda_parcelas'
)
select
  '05_legacy_function_catalog_dependencies' as section,
  lf.function_name,
  lf.identity_arguments,
  d.deptype,
  pg_describe_object(d.classid, d.objid, d.objsubid) as dependent_object,
  pg_describe_object(d.refclassid, d.refobjid, d.refobjsubid) as referenced_object
from legacy_functions lf
join pg_depend d on d.refobjid = lf.oid
where d.deptype <> 'i'
order by d.deptype, dependent_object;

-- ============================================================
-- 7. Tabelas financeiras existem?
-- ============================================================

with required_tables as (
  select * from (values
    ('mesa_simulacoes'),
    ('mesa_cliente_fluxo_parcelas'),
    ('mesa_cliente_fluxo_operacoes')
  ) as t(table_name)
)
select
  '06_required_tables' as section,
  rt.table_name,
  to_regclass('public.' || rt.table_name) is not null as exists_in_database
from required_tables rt
order by rt.table_name;

-- ============================================================
-- 8. Colunas das tabelas financeiras críticas
--
-- Objetivo:
--   Ajudar a decidir se existe campo de metadata/origem capaz de indicar
--   que linhas foram geradas pela RPC legada.
-- ============================================================

select
  '07_financial_tables_columns' as section,
  c.table_name,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name in (
    'mesa_simulacoes',
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes'
  )
order by c.table_name, c.ordinal_position;

-- ============================================================
-- 9. Baseline de contagem das tabelas financeiras
--
-- Observação:
--   Este script não altera dados; portanto este baseline serve como
--   fotografia do estado atual antes de qualquer correção/depreciação.
-- ============================================================

select
  '08_financial_tables_counts' as section,
  'mesa_cliente_fluxo_parcelas' as table_name,
  count(*)::bigint as total_rows
from public.mesa_cliente_fluxo_parcelas
union all
select
  '08_financial_tables_counts' as section,
  'mesa_cliente_fluxo_operacoes' as table_name,
  count(*)::bigint as total_rows
from public.mesa_cliente_fluxo_operacoes
order by table_name;

-- ============================================================
-- 10. Distribuição de parcelas por simulação
--
-- Objetivo:
--   Verificar se já existe agenda persistida. Este resultado sozinho
--   NÃO prova que foi a RPC legada que gerou os dados.
-- ============================================================

select
  '09_fluxo_parcelas_distribution_by_simulacao' as section,
  simulacao_id,
  count(*)::bigint as qtd_parcelas,
  min(created_at) as primeira_parcela_em,
  max(created_at) as ultima_parcela_em
from public.mesa_cliente_fluxo_parcelas
where simulacao_id is not null
group by simulacao_id
order by qtd_parcelas desc, ultima_parcela_em desc
limit 30;

-- ============================================================
-- 11. Distribuição de operações por simulação
-- ============================================================

select
  '10_fluxo_operacoes_distribution_by_simulacao' as section,
  simulacao_id,
  count(*)::bigint as qtd_operacoes,
  min(created_at) as primeira_operacao_em,
  max(created_at) as ultima_operacao_em
from public.mesa_cliente_fluxo_operacoes
where simulacao_id is not null
group by simulacao_id
order by qtd_operacoes desc, ultima_operacao_em desc
limit 30;

-- ============================================================
-- 12. Policies/RLS das tabelas financeiras
-- ============================================================

select
  '11_rls_status' as section,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes'
  )
order by c.relname;

select
  '12_policies' as section,
  p.tablename,
  p.policyname,
  p.cmd,
  p.roles,
  p.qual,
  p.with_check
from pg_policies p
where p.schemaname = 'public'
  and p.tablename in (
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes'
  )
order by p.tablename, p.policyname;

-- ============================================================
-- 13. Grants diretos nas tabelas financeiras
-- ============================================================

select
  '13_table_grants' as section,
  table_schema,
  table_name,
  grantee,
  privilege_type,
  is_grantable
from information_schema.table_privileges
where table_schema = 'public'
  and table_name in (
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes'
  )
  and grantee in ('anon', 'authenticated', 'public', 'service_role', 'postgres')
order by table_name, grantee, privilege_type;

-- ============================================================
-- 14. Interpretação operacional automática
--
-- Este bloco não decide sozinho. Ele apenas sinaliza o caminho provável.
-- ============================================================

with legacy_migration_status as (
  select
    exists (
      select 1
      from supabase_migrations.schema_migrations sm
      where sm.version::text = '20260517193000'
         or sm.version::text like '20260517193000%'
    ) as migration_20260517193000_applied,
    exists (
      select 1
      from supabase_migrations.schema_migrations sm
      where sm.version::text = '20260517223000'
         or sm.version::text like '20260517223000%'
    ) as migration_20260517223000_applied
), legacy_function_status as (
  select
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'gerar_mesa_cliente_agenda_parcelas'
    ) as legacy_function_exists
), legacy_function_grants as (
  select
    coalesce(bool_or(has_function_privilege('anon', p.oid, 'EXECUTE')), false) as legacy_function_anon_can_execute,
    coalesce(bool_or(has_function_privilege('authenticated', p.oid, 'EXECUTE')), false) as legacy_function_authenticated_can_execute
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'gerar_mesa_cliente_agenda_parcelas'
), financial_counts as (
  select
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas) as parcelas_count,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes) as operacoes_count
)
select
  '14_operational_interpretation' as section,
  lms.migration_20260517193000_applied,
  lms.migration_20260517223000_applied,
  lfs.legacy_function_exists,
  lfg.legacy_function_anon_can_execute,
  lfg.legacy_function_authenticated_can_execute,
  fc.parcelas_count,
  fc.operacoes_count,
  case
    when lfg.legacy_function_anon_can_execute then
      'AÇÃO URGENTE: função legada existe com EXECUTE para anon; criar migration corretiva de REVOKE.'
    when lms.migration_20260517193000_applied or lms.migration_20260517223000_applied or lfs.legacy_function_exists then
      'Migrations/função legadas existem no banco; não remover histórico. Criar migration corretiva/depreciação antes de arquivar no GitHub.'
    else
      'Migrations/função legadas não aparecem aplicadas no banco; provável caminho: arquivar arquivos legados fora de supabase/migrations antes da nova 4A JSON-first.'
  end as recommended_next_step
from legacy_migration_status lms
cross join legacy_function_status lfs
cross join legacy_function_grants lfg
cross join financial_counts fc;

-- ============================================================
-- Fim do preflight
-- ============================================================

select
  '99_end' as section,
  'Preflight read-only concluído. Envie todos os resultsets antes de mover arquivos legados ou criar a nova migration JSON-first.' as instruction;
