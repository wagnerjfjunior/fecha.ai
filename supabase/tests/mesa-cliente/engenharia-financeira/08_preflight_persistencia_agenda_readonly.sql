-- MesaCliente Engenharia Financeira — 08 Preflight read-only da Fase 4B
--
-- Objetivo:
--   Radiografar o schema real antes de qualquer migration da Fase 4B.
--
-- Fase 4B:
--   Persistência segura da agenda financeira em mesa_cliente_fluxo_parcelas.
--
-- Segurança:
--   - READ-ONLY.
--   - Não cria tabela.
--   - Não altera função.
--   - Não insere, atualiza ou apaga registros.
--   - Não concede grants.
--   - Não altera policies.
--   - Não executa RPC de persistência.
--
-- Como usar:
--   Rodar no Supabase SQL Editor e enviar todos os resultsets antes de qualquer migration 4B.
--
-- Resultado esperado:
--   Este preflight deve permitir decidir:
--     1. se o schema atual suporta append-only/versionamento;
--     2. se será necessário replace_draft;
--     3. se há colunas de auditoria/idempotência;
--     4. quais locks, constraints, índices e testes serão necessários.

-- 01 — Existência das tabelas financeiras centrais.
select
  '01_financial_tables_existence' as section,
  t.table_schema,
  t.table_name,
  t.table_type
from information_schema.tables t
where t.table_schema = 'public'
  and t.table_name in (
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes',
    'mesa_simulacoes',
    'corretores',
    'empresas',
    'empreendimentos'
  )
order by t.table_name;

-- 02 — Contagem atual das tabelas que serão avaliadas.
select
  '02_financial_tables_counts' as section,
  'mesa_cliente_fluxo_parcelas' as table_name,
  count(*)::bigint as total_rows
from public.mesa_cliente_fluxo_parcelas
union all
select
  '02_financial_tables_counts',
  'mesa_cliente_fluxo_operacoes',
  count(*)::bigint
from public.mesa_cliente_fluxo_operacoes
union all
select
  '02_financial_tables_counts',
  'mesa_simulacoes',
  count(*)::bigint
from public.mesa_simulacoes
order by table_name;

-- 03 — Colunas de mesa_cliente_fluxo_parcelas.
select
  '03_parcelas_columns' as section,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  c.character_maximum_length,
  c.numeric_precision,
  c.numeric_scale
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name = 'mesa_cliente_fluxo_parcelas'
order by c.ordinal_position;

-- 04 — Colunas de mesa_cliente_fluxo_operacoes.
select
  '04_operacoes_columns' as section,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  c.character_maximum_length,
  c.numeric_precision,
  c.numeric_scale
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name = 'mesa_cliente_fluxo_operacoes'
order by c.ordinal_position;

-- 05 — Colunas de mesa_simulacoes relevantes para lock e validação.
select
  '05_mesa_simulacoes_columns' as section,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name = 'mesa_simulacoes'
order by c.ordinal_position;

-- 06 — Constraints de mesa_cliente_fluxo_parcelas.
select
  '06_parcelas_constraints' as section,
  con.conname as constraint_name,
  con.contype as constraint_type,
  pg_get_constraintdef(con.oid) as constraint_definition
from pg_constraint con
join pg_class rel
  on rel.oid = con.conrelid
join pg_namespace nsp
  on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname = 'mesa_cliente_fluxo_parcelas'
order by con.contype, con.conname;

-- 07 — Constraints de mesa_cliente_fluxo_operacoes.
select
  '07_operacoes_constraints' as section,
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

-- 08 — Índices de mesa_cliente_fluxo_parcelas.
select
  '08_parcelas_indexes' as section,
  i.indexname,
  i.indexdef
from pg_indexes i
where i.schemaname = 'public'
  and i.tablename = 'mesa_cliente_fluxo_parcelas'
order by i.indexname;

-- 09 — Índices de mesa_cliente_fluxo_operacoes.
select
  '09_operacoes_indexes' as section,
  i.indexname,
  i.indexdef
from pg_indexes i
where i.schemaname = 'public'
  and i.tablename = 'mesa_cliente_fluxo_operacoes'
order by i.indexname;

-- 10 — Triggers de mesa_cliente_fluxo_parcelas.
select
  '10_parcelas_triggers' as section,
  tg.tgname as trigger_name,
  pg_get_triggerdef(tg.oid) as trigger_definition
from pg_trigger tg
join pg_class rel
  on rel.oid = tg.tgrelid
join pg_namespace nsp
  on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname = 'mesa_cliente_fluxo_parcelas'
  and not tg.tgisinternal
order by tg.tgname;

-- 11 — Triggers de mesa_cliente_fluxo_operacoes.
select
  '11_operacoes_triggers' as section,
  tg.tgname as trigger_name,
  pg_get_triggerdef(tg.oid) as trigger_definition
from pg_trigger tg
join pg_class rel
  on rel.oid = tg.tgrelid
join pg_namespace nsp
  on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname = 'mesa_cliente_fluxo_operacoes'
  and not tg.tgisinternal
order by tg.tgname;

-- 12 — RLS nas tabelas financeiras e mesa_simulacoes.
select
  '12_rls_status' as section,
  n.nspname as table_schema,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n
  on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes',
    'mesa_simulacoes'
  )
order by c.relname;

-- 13 — Policies das tabelas financeiras e mesa_simulacoes.
select
  '13_policies' as section,
  p.schemaname,
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
    'mesa_cliente_fluxo_operacoes',
    'mesa_simulacoes'
  )
order by p.tablename, p.policyname;

-- 14 — Grants das tabelas financeiras e mesa_simulacoes.
select
  '14_table_grants' as section,
  tp.table_schema,
  tp.table_name,
  tp.grantee,
  tp.privilege_type,
  tp.is_grantable
from information_schema.table_privileges tp
where tp.table_schema = 'public'
  and tp.table_name in (
    'mesa_cliente_fluxo_parcelas',
    'mesa_cliente_fluxo_operacoes',
    'mesa_simulacoes'
  )
  and tp.grantee in ('anon', 'authenticated', 'public', 'service_role', 'postgres')
order by tp.table_name, tp.grantee, tp.privilege_type;

-- 15 — Funções existentes relacionadas a mesa/agenda/fluxo/operação.
select
  '15_related_functions_inventory' as section,
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  pg_get_function_result(p.oid) as function_result,
  p.prosecdef as security_definer,
  case p.provolatile
    when 'i' then 'immutable'
    when 's' then 'stable'
    when 'v' then 'volatile'
    else p.provolatile::text
  end as volatility_label,
  r.rolname as owner_name,
  p.proconfig as function_config,
  has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute
from pg_proc p
join pg_namespace n
  on n.oid = p.pronamespace
join pg_roles r
  on r.oid = p.proowner
where n.nspname = 'public'
  and (
    p.proname ilike '%mesa_cliente%'
    or p.proname ilike '%agenda%'
    or p.proname ilike '%fluxo%'
    or p.proname ilike '%parcela%'
    or p.proname ilike '%operacao%'
    or p.proname ilike '%operação%'
  )
order by p.proname, identity_arguments;

-- 16 — Migrations aplicadas relacionadas a MesaCliente/engenharia financeira.
select
  '16_related_migrations_applied' as section,
  version,
  name,
  inserted_at
from supabase_migrations.schema_migrations
where version::text ilike '%mesa%'
   or name ilike '%mesa%'
   or name ilike '%cliente%'
   or name ilike '%agenda%'
   or name ilike '%fluxo%'
   or name ilike '%financeira%'
   or version::text in ('20260517193000', '20260517223000', '20260518120000')
order by inserted_at desc nulls last, version desc;

-- 17 — Status reais existentes em operações, sem assumir nomes.
-- Se a coluna status não existir, retornar aviso em vez de erro.
select
  '17_operacoes_status_inventory' as section,
  case
    when exists (
      select 1
      from information_schema.columns c
      where c.table_schema = 'public'
        and c.table_name = 'mesa_cliente_fluxo_operacoes'
        and c.column_name = 'status'
    ) then 'status_column_exists'
    else 'status_column_missing'
  end as status_column_check,
  null::text as status,
  null::bigint as total
where not exists (
  select 1
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
    and c.column_name = 'status'
)
union all
select
  '17_operacoes_status_inventory' as section,
  'status_column_exists' as status_column_check,
  x.status::text,
  x.total
from (
  select status, count(*)::bigint as total
  from public.mesa_cliente_fluxo_operacoes
  group by status
) x
where exists (
  select 1
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
    and c.column_name = 'status'
)
order by status_column_check, status;

-- 18 — Possíveis colunas de versionamento/idempotência/auditoria em parcelas.
select
  '18_parcelas_idempotency_audit_candidates' as section,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  case
    when c.column_name ilike '%hash%' then 'hash_candidate'
    when c.column_name ilike '%vers%' then 'version_candidate'
    when c.column_name ilike '%idempot%' then 'idempotency_candidate'
    when c.column_name ilike '%audit%' then 'audit_candidate'
    when c.column_name ilike '%created%' then 'created_audit_candidate'
    when c.column_name ilike '%updated%' then 'updated_audit_candidate'
    when c.column_name ilike '%ativo%' then 'active_flag_candidate'
    when c.column_name ilike '%status%' then 'status_candidate'
    when c.column_name ilike '%origem%' then 'origin_candidate'
    else 'other'
  end as candidate_type
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name = 'mesa_cliente_fluxo_parcelas'
  and (
    c.column_name ilike '%hash%'
    or c.column_name ilike '%vers%'
    or c.column_name ilike '%idempot%'
    or c.column_name ilike '%audit%'
    or c.column_name ilike '%created%'
    or c.column_name ilike '%updated%'
    or c.column_name ilike '%ativo%'
    or c.column_name ilike '%status%'
    or c.column_name ilike '%origem%'
  )
order by candidate_type, c.column_name;

-- 19 — Possíveis tabelas de auditoria existentes.
select
  '19_existing_audit_tables_candidates' as section,
  t.table_schema,
  t.table_name,
  t.table_type
from information_schema.tables t
where t.table_schema = 'public'
  and (
    t.table_name ilike '%audit%'
    or t.table_name ilike '%auditoria%'
    or t.table_name ilike '%log%'
    or t.table_name ilike '%historico%'
    or t.table_name ilike '%histórico%'
    or t.table_name ilike '%evento%'
  )
order by t.table_name;

-- 20 — FK de parcelas e operações apontando para simulação/empresa/empreendimento.
select
  '20_fk_relationships_financial_tables' as section,
  rel.relname as table_name,
  con.conname as constraint_name,
  pg_get_constraintdef(con.oid) as constraint_definition
from pg_constraint con
join pg_class rel
  on rel.oid = con.conrelid
join pg_namespace nsp
  on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname in ('mesa_cliente_fluxo_parcelas', 'mesa_cliente_fluxo_operacoes')
  and con.contype = 'f'
order by rel.relname, con.conname;

-- 21 — Colunas comuns necessárias para a 4B por presença/ausência.
with required_cols as (
  select 'mesa_cliente_fluxo_parcelas'::text as table_name, unnest(array[
    'id',
    'simulacao_id',
    'empresa_id',
    'empreendimento_id',
    'grupo',
    'descricao',
    'valor',
    'data_vencimento',
    'parcela_numero',
    'parcelas_total_item',
    'ordem',
    'negociavel',
    'motivos_bloqueio',
    'created_at',
    'updated_at'
  ]) as column_name
  union all
  select 'mesa_cliente_fluxo_operacoes'::text as table_name, unnest(array[
    'id',
    'simulacao_id',
    'empresa_id',
    'status',
    'created_at',
    'updated_at'
  ]) as column_name
)
select
  '21_required_columns_presence' as section,
  r.table_name,
  r.column_name,
  case when c.column_name is not null then true else false end as exists_in_schema,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default
from required_cols r
left join information_schema.columns c
  on c.table_schema = 'public'
 and c.table_name = r.table_name
 and c.column_name = r.column_name
order by r.table_name, r.column_name;

-- 22 — Amostra segura de parcelas existentes, se houver, sem expor dados sensíveis extensos.
select
  '22_parcelas_sample_safe' as section,
  p.id,
  p.simulacao_id,
  p.empresa_id,
  p.empreendimento_id,
  p.grupo,
  p.valor,
  p.data_vencimento,
  p.created_at
from public.mesa_cliente_fluxo_parcelas p
order by p.created_at desc nulls last, p.id
limit 10;

-- 23 — Amostra segura de operações existentes, se houver, sem expor payloads extensos.
select
  '23_operacoes_sample_safe' as section,
  o.id,
  o.simulacao_id,
  o.empresa_id,
  case
    when exists (
      select 1
      from information_schema.columns c
      where c.table_schema = 'public'
        and c.table_name = 'mesa_cliente_fluxo_operacoes'
        and c.column_name = 'status'
    ) then o.status::text
    else null::text
  end as status,
  o.created_at
from public.mesa_cliente_fluxo_operacoes o
order by o.created_at desc nulls last, o.id
limit 10;

-- 24 — Interpretação operacional preliminar.
with rls as (
  select
    c.relname,
    c.relrowsecurity,
    c.relforcerowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('mesa_cliente_fluxo_parcelas', 'mesa_cliente_fluxo_operacoes')
), grants as (
  select
    table_name,
    bool_or(grantee = 'anon') as anon_has_any_grant,
    bool_or(grantee = 'authenticated' and privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')) as authenticated_has_write_grant
  from information_schema.table_privileges
  where table_schema = 'public'
    and table_name in ('mesa_cliente_fluxo_parcelas', 'mesa_cliente_fluxo_operacoes')
    and grantee in ('anon', 'authenticated')
  group by table_name
), cols as (
  select
    table_name,
    bool_or(column_name = 'simulacao_id') as has_simulacao_id,
    bool_or(column_name = 'empresa_id') as has_empresa_id,
    bool_or(column_name = 'empreendimento_id') as has_empreendimento_id,
    bool_or(column_name ilike '%hash%') as has_hash_candidate,
    bool_or(column_name ilike '%vers%') as has_version_candidate,
    bool_or(column_name ilike '%status%') as has_status_candidate,
    bool_or(column_name ilike '%ativo%') as has_active_candidate
  from information_schema.columns
  where table_schema = 'public'
    and table_name in ('mesa_cliente_fluxo_parcelas', 'mesa_cliente_fluxo_operacoes')
  group by table_name
), ops_status as (
  select exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'mesa_cliente_fluxo_operacoes'
      and c.column_name = 'status'
  ) as operacoes_has_status
)
select
  '24_operational_interpretation' as section,
  jsonb_build_object(
    'parcelas_rls_enabled', coalesce((select relrowsecurity from rls where relname = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_rls_forced', coalesce((select relforcerowsecurity from rls where relname = 'mesa_cliente_fluxo_parcelas'), false),
    'operacoes_rls_enabled', coalesce((select relrowsecurity from rls where relname = 'mesa_cliente_fluxo_operacoes'), false),
    'operacoes_rls_forced', coalesce((select relforcerowsecurity from rls where relname = 'mesa_cliente_fluxo_operacoes'), false),
    'parcelas_anon_has_any_grant', coalesce((select anon_has_any_grant from grants where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'operacoes_anon_has_any_grant', coalesce((select anon_has_any_grant from grants where table_name = 'mesa_cliente_fluxo_operacoes'), false),
    'parcelas_authenticated_has_write_grant', coalesce((select authenticated_has_write_grant from grants where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'operacoes_authenticated_has_write_grant', coalesce((select authenticated_has_write_grant from grants where table_name = 'mesa_cliente_fluxo_operacoes'), false),
    'parcelas_has_simulacao_id', coalesce((select has_simulacao_id from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_has_empresa_id', coalesce((select has_empresa_id from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_has_empreendimento_id', coalesce((select has_empreendimento_id from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_has_hash_candidate', coalesce((select has_hash_candidate from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_has_version_candidate', coalesce((select has_version_candidate from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_has_status_candidate', coalesce((select has_status_candidate from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'parcelas_has_active_candidate', coalesce((select has_active_candidate from cols where table_name = 'mesa_cliente_fluxo_parcelas'), false),
    'operacoes_has_status', (select operacoes_has_status from ops_status),
    'recommended_next_step', 'Enviar todos os resultsets deste preflight antes de qualquer migration 4B. A estratégia append-only vs replace_draft depende das colunas/constraints retornadas.'
  ) as interpretation;

-- 99 — Fim do preflight.
select
  '99_end' as section,
  'Preflight read-only 4B concluído. Envie todos os resultsets antes de criar qualquer migration de persistência.' as instruction;
