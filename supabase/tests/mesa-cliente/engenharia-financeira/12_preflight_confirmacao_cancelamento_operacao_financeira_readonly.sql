-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- 12 — Preflight read-only para confirmação/cancelamento de operação financeira.
--
-- Objetivo:
--   Mapear o schema real antes de qualquer migration da 5C.
--
-- Regras:
--   - Somente SELECT.
--   - Seguro para SQL Editor do Supabase.
--   - Não cria fixture.
--   - Não altera schema.
--   - Não chama RPC de escrita.

with
required_tables as (
  select * from (values
    ('public', 'mesa_cliente_fluxo_operacoes', 'operação financeira registrada pela 5B e alvo da 5C'),
    ('public', 'mesa_cliente_agendas_financeiras', 'agenda persistida que não deve ser mutada pela 5C'),
    ('public', 'mesa_cliente_fluxo_parcelas', 'parcelas persistidas que não devem ser mutadas pela 5C'),
    ('public', 'mesa_simulacoes', 'simulação soberana vinculada à operação'),
    ('public', 'corretores', 'identidade, tenant e autorização do usuário')
  ) as t(table_schema, table_name, finalidade)
),
table_status as (
  select rt.*, to_regclass(format('%I.%I', rt.table_schema, rt.table_name)) is not null as existe
  from required_tables rt
),
operacoes_columns as (
  select
    c.column_name,
    c.ordinal_position,
    c.data_type,
    c.udt_name,
    c.is_nullable,
    c.column_default
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
),
required_columns as (
  select * from (values
    ('core_5b', 'id', 'identificador da operação'),
    ('core_5b', 'empresa_id', 'tenant soberano vindo do banco'),
    ('core_5b', 'simulacao_id', 'vínculo com simulação'),
    ('core_5b', 'agenda_id', 'vínculo com agenda persistida'),
    ('core_5b', 'parcela_origem_id', 'parcela de origem da operação'),
    ('core_5b', 'tipo_operacao', 'tipo da operação financeira'),
    ('core_5b', 'status_operacao', 'estado da operação financeira'),
    ('core_5b', 'valor_movido', 'valor financeiro movimentado'),
    ('core_5b', 'valor_base', 'valor-base de cálculo'),
    ('core_5b', 'checksum_operacao', 'idempotência canônica da operação'),
    ('core_5b', 'metadata', 'dados administrativos complementares'),
    ('core_5b', 'visivel_cliente', 'controle de exposição ao cliente'),
    ('confirmacao_5c', 'confirmado', 'flag de confirmação'),
    ('confirmacao_5c', 'confirmado_por', 'usuário que confirmou'),
    ('confirmacao_5c', 'confirmado_em', 'timestamp de confirmação'),
    ('confirmacao_5c', 'updated_at', 'timestamp de atualização'),
    ('cancelamento_5c', 'cancelado_por', 'usuário que cancelou'),
    ('cancelamento_5c', 'cancelado_em', 'timestamp de cancelamento'),
    ('cancelamento_5c', 'motivo_cancelamento', 'motivo explícito do cancelamento')
  ) as t(grupo, column_name, finalidade)
),
column_presence as (
  select
    rc.grupo,
    rc.column_name,
    rc.finalidade,
    oc.column_name is not null as existe,
    oc.data_type,
    oc.udt_name,
    oc.is_nullable,
    oc.column_default
  from required_columns rc
  left join operacoes_columns oc on oc.column_name = rc.column_name
),
constraints_inventory as (
  select con.conname, con.contype, pg_get_constraintdef(con.oid, true) as definition
  from pg_constraint con
  join pg_class cls on cls.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = cls.relnamespace
  where nsp.nspname = 'public'
    and cls.relname = 'mesa_cliente_fluxo_operacoes'
),
indexes_inventory as (
  select i.indexname, i.indexdef
  from pg_indexes i
  where i.schemaname = 'public'
    and i.tablename = 'mesa_cliente_fluxo_operacoes'
),
triggers_inventory as (
  select tg.tgname, not tg.tgisinternal as user_trigger, pg_get_triggerdef(tg.oid, true) as definition
  from pg_trigger tg
  join pg_class cls on cls.oid = tg.tgrelid
  join pg_namespace nsp on nsp.oid = cls.relnamespace
  where nsp.nspname = 'public'
    and cls.relname = 'mesa_cliente_fluxo_operacoes'
),
rls_inventory as (
  select n.nspname as schemaname, c.relname as tablename, c.relrowsecurity as rls_enabled, c.relforcerowsecurity as rls_forced
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'mesa_cliente_fluxo_operacoes'
),
policies_inventory as (
  select p.policyname, p.permissive, p.roles, p.cmd, p.qual, p.with_check
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'mesa_cliente_fluxo_operacoes'
),
grants_inventory as (
  select tp.grantee, tp.privilege_type, tp.is_grantable
  from information_schema.table_privileges tp
  where tp.table_schema = 'public'
    and tp.table_name = 'mesa_cliente_fluxo_operacoes'
    and tp.grantee in ('anon', 'authenticated', 'service_role', 'postgres')
),
status_support as (
  select
    exists(select 1 from constraints_inventory where definition ilike '%simulada%') as suporta_simulada,
    exists(select 1 from constraints_inventory where definition ilike '%confirmada%') as suporta_confirmada,
    exists(select 1 from constraints_inventory where definition ilike '%cancelada%') as suporta_cancelada,
    exists(select 1 from constraints_inventory where definition ilike '%bloqueada%') as suporta_bloqueada
),
status_distribution as (
  select coalesce(to_jsonb(o)->>'status_operacao', '__sem_status__') as status_operacao, count(*)::integer as qtd
  from public.mesa_cliente_fluxo_operacoes o
  group by 1
),
function_inventory as (
  select
    fase,
    function_signature,
    to_regprocedure(function_signature) is not null as existe,
    coalesce(has_function_privilege('anon', to_regprocedure(function_signature), 'EXECUTE'), false) as anon_execute,
    coalesce(has_function_privilege('authenticated', to_regprocedure(function_signature), 'EXECUTE'), false) as authenticated_execute
  from (values
    ('5B', 'public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)'),
    ('5C_CANDIDATA', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)')
  ) as t(fase, function_signature)
),
readiness as (
  select
    (select bool_and(existe) from table_status) as required_tables_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'core_5b'), false) as core_5b_cols_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'confirmacao_5c'), false) as confirmacao_cols_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'cancelamento_5c'), false) as cancelamento_cols_ok,
    coalesce((select suporta_simulada from status_support), false) as suporta_simulada,
    coalesce((select suporta_confirmada from status_support), false) as suporta_confirmada,
    coalesce((select suporta_cancelada from status_support), false) as suporta_cancelada,
    exists(select 1 from indexes_inventory where indexdef ilike '%checksum_operacao%' or indexdef ilike '%checksum%') as has_checksum_index,
    exists(select 1 from indexes_inventory where indexdef ilike '%agenda_id%' and indexdef ilike '%parcela%') as has_agenda_parcela_index,
    exists(select 1 from rls_inventory where rls_enabled) as rls_enabled,
    exists(select 1 from function_inventory where fase = '5B' and existe) as rpc_5b_exists,
    exists(select 1 from function_inventory where fase = '5C_CANDIDATA' and existe) as rpc_5c_candidate_exists
)
select '01_tabelas_obrigatorias'::text as bloco,
       case when bool_and(existe) then 'PASS' else 'FAIL' end as status,
       jsonb_build_object('tabelas', jsonb_agg(jsonb_build_object('schema', table_schema, 'tabela', table_name, 'existe', existe, 'finalidade', finalidade) order by table_name)) as detalhe
from table_status

union all
select '02_colunas_operacoes_confirmacao_cancelamento'::text,
       case
         when bool_and(existe) filter (where grupo in ('core_5b', 'confirmacao_5c')) then case when bool_and(existe) filter (where grupo = 'cancelamento_5c') then 'PASS' else 'WARN' end
         else 'FAIL'
       end,
       jsonb_build_object(
         'core_5b_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'core_5b' and not existe), '[]'::jsonb),
         'confirmacao_5c_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'confirmacao_5c' and not existe), '[]'::jsonb),
         'cancelamento_5c_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'cancelamento_5c' and not existe), '[]'::jsonb),
         'colunas', jsonb_agg(jsonb_build_object('grupo', grupo, 'column_name', column_name, 'existe', existe, 'data_type', data_type, 'udt_name', udt_name, 'is_nullable', is_nullable, 'column_default', column_default, 'finalidade', finalidade) order by grupo, column_name)
       )
from column_presence

union all
select '03_status_operacao_suporte'::text,
       case when suporta_simulada and suporta_confirmada and suporta_cancelada then 'PASS' when suporta_simulada and suporta_confirmada then 'WARN' else 'FAIL' end,
       jsonb_build_object(
         'suporta_simulada', suporta_simulada,
         'suporta_confirmada', suporta_confirmada,
         'suporta_cancelada', suporta_cancelada,
         'suporta_bloqueada', suporta_bloqueada,
         'constraints', coalesce((select jsonb_agg(jsonb_build_object('conname', conname, 'contype', contype, 'definition', definition) order by conname) from constraints_inventory), '[]'::jsonb)
       )
from status_support

union all
select '04_status_operacao_distribuicao_atual'::text,
       'INFO'::text,
       jsonb_build_object('status_distribution', coalesce(jsonb_agg(jsonb_build_object('status_operacao', status_operacao, 'qtd', qtd) order by status_operacao), '[]'::jsonb), 'observacao', 'Leitura informativa. Não cria, não confirma e não cancela operações.')
from status_distribution

union all
select '05_indices_operacoes_para_5c'::text,
       case when exists(select 1 from indexes_inventory where indexdef ilike '%agenda_id%' and indexdef ilike '%parcela%') then 'PASS' else 'WARN' end,
       jsonb_build_object(
         'tem_indice_checksum', exists(select 1 from indexes_inventory where indexdef ilike '%checksum_operacao%' or indexdef ilike '%checksum%'),
         'tem_indice_agenda_parcela', exists(select 1 from indexes_inventory where indexdef ilike '%agenda_id%' and indexdef ilike '%parcela%'),
         'tem_indice_status_operacao', exists(select 1 from indexes_inventory where indexdef ilike '%status_operacao%'),
         'indices', coalesce(jsonb_agg(jsonb_build_object('indexname', indexname, 'indexdef', indexdef) order by indexname), '[]'::jsonb)
       )
from indexes_inventory

union all
select '06_triggers_operacoes_updated_at'::text,
       case when exists(select 1 from triggers_inventory where definition ilike '%updated_at%') then 'PASS' else 'WARN' end,
       jsonb_build_object('tem_trigger_updated_at', exists(select 1 from triggers_inventory where definition ilike '%updated_at%'), 'qtd_triggers', count(*), 'triggers', coalesce(jsonb_agg(jsonb_build_object('tgname', tgname, 'user_trigger', user_trigger, 'definition', definition) order by tgname), '[]'::jsonb))
from triggers_inventory

union all
select '07_rls_policies_operacoes'::text,
       case when exists(select 1 from rls_inventory where rls_enabled) then 'PASS' else 'WARN' end,
       jsonb_build_object(
         'rls', coalesce((select jsonb_agg(jsonb_build_object('schemaname', schemaname, 'tablename', tablename, 'rls_enabled', rls_enabled, 'rls_forced', rls_forced)) from rls_inventory), '[]'::jsonb),
         'qtd_policies', (select count(*) from policies_inventory),
         'policies', coalesce((select jsonb_agg(jsonb_build_object('policyname', policyname, 'permissive', permissive, 'roles', roles, 'cmd', cmd, 'qual', qual, 'with_check', with_check) order by policyname) from policies_inventory), '[]'::jsonb)
       )

union all
select '08_grants_tabela_operacoes'::text,
       case when exists(select 1 from grants_inventory where grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')) then 'FAIL' when exists(select 1 from grants_inventory where grantee = 'authenticated') then 'PASS' else 'WARN' end,
       jsonb_build_object('anon_tem_dml', exists(select 1 from grants_inventory where grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')), 'authenticated_tem_algum_grant', exists(select 1 from grants_inventory where grantee = 'authenticated'), 'grants', coalesce(jsonb_agg(jsonb_build_object('grantee', grantee, 'privilege_type', privilege_type, 'is_grantable', is_grantable) order by grantee, privilege_type), '[]'::jsonb))
from grants_inventory

union all
select '09_funcoes_dependencias_e_ausencia_5c'::text,
       case when not exists(select 1 from function_inventory where fase = '5B' and existe) then 'FAIL' when exists(select 1 from function_inventory where fase = '5C_CANDIDATA' and existe) then 'WARN' else 'PASS' end,
       jsonb_build_object('rpc_5b_existe', exists(select 1 from function_inventory where fase = '5B' and existe), 'rpc_5c_candidata_ja_existe', exists(select 1 from function_inventory where fase = '5C_CANDIDATA' and existe), 'funcoes', jsonb_agg(jsonb_build_object('fase', fase, 'function_signature', function_signature, 'existe', existe, 'anon_execute', anon_execute, 'authenticated_execute', authenticated_execute) order by fase, function_signature))
from function_inventory

union all
select '10_readiness_para_migration_5c'::text,
       case
         when not required_tables_ok or not core_5b_cols_ok or not confirmacao_cols_ok or not rpc_5b_exists then 'FAIL'
         when rpc_5c_candidate_exists then 'WARN'
         when not cancelamento_cols_ok or not suporta_cancelada or not has_agenda_parcela_index then 'WARN'
         else 'PASS'
       end,
       jsonb_build_object(
         'required_tables_ok', required_tables_ok,
         'core_5b_cols_ok', core_5b_cols_ok,
         'confirmacao_cols_ok', confirmacao_cols_ok,
         'cancelamento_cols_ok', cancelamento_cols_ok,
         'suporta_simulada', suporta_simulada,
         'suporta_confirmada', suporta_confirmada,
         'suporta_cancelada', suporta_cancelada,
         'has_checksum_index', has_checksum_index,
         'has_agenda_parcela_index', has_agenda_parcela_index,
         'rls_enabled', rls_enabled,
         'rpc_5b_exists', rpc_5b_exists,
         'rpc_5c_candidate_exists', rpc_5c_candidate_exists,
         'interpretacao', case
           when not required_tables_ok then 'Faltam tabelas obrigatórias. Não criar migration 5C ainda.'
           when not core_5b_cols_ok then 'Faltam colunas core herdadas da 5B. Corrigir antes da 5C.'
           when not confirmacao_cols_ok then 'Faltam colunas mínimas de confirmação. Migration 5C deve corrigir antes da RPC.'
           when not rpc_5b_exists then 'RPC 5B não encontrada. A 5C depende da 5B aprovada.'
           when rpc_5c_candidate_exists then 'RPC 5C já existe antes da migration canônica. Investigar/alinhar antes de seguir.'
           when not cancelamento_cols_ok or not suporta_cancelada then 'Base parece pronta para confirmação, mas cancelamento exige migration/decisão explícita.'
           when not has_agenda_parcela_index then 'Base parece funcional, mas índice agenda/parcela/status pode ser recomendado para bloqueios de conflito.'
           else 'Base parece pronta para desenhar migration/RPC 5C.'
         end,
         'recommended_next_step_if_pass_or_warn', 'Analisar este resultset, decidir colunas de cancelamento e fechar migration/RPC 5C.'
       )
from readiness

union all
select '99_readonly_notice'::text,
       'INFO'::text,
       jsonb_build_object(
         'mensagem', 'Preflight 12 é somente leitura. Não cria fixture, não chama RPC de escrita e não altera schema.',
         'proximos_arquivos_esperados_se_aprovado', jsonb_build_array(
           'docs/mesa-cliente/fase-5c-validacao-preflight-12.md',
           'supabase/migrations/<timestamp>_mesa_cliente_fase_5c_confirmacao_cancelamento_operacao_financeira.sql',
           'supabase/tests/mesa-cliente/engenharia-financeira/12a_validacao_confirmar_operacao_financeira_rollback.sql',
           'supabase/tests/mesa-cliente/engenharia-financeira/12b_validacao_cancelar_operacao_financeira_rollback.sql',
           'supabase/tests/mesa-cliente/engenharia-financeira/12c_validacao_confirmacao_cancelamento_negativos_rollback.sql',
           'supabase/tests/mesa-cliente/engenharia-financeira/12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql',
           'supabase/tests/mesa-cliente/engenharia-financeira/12e_validacao_zero_mutacao_agenda_parcelas_confirmacao_cancelamento_rollback.sql'
         )
       )
order by bloco;
