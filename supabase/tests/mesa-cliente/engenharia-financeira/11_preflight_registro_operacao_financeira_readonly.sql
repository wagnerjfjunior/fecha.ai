-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5B
-- 11 — Preflight read-only para registro de operação financeira administrativa.
--
-- Objetivo:
--   Mapear o schema real antes de qualquer migration da 5B.
--   A 5B será a primeira etapa que registra operação financeira; portanto, este arquivo
--   NÃO cria dados, NÃO altera schema e NÃO chama RPC de escrita.
--
-- Regras:
--   - Somente SELECT.
--   - Seguro para SQL Editor do Supabase.
--   - Não depende de seed permanente.
--   - Não presume agenda_id em mesa_cliente_fluxo_operacoes.
--   - Não libera migration automaticamente; o resultset deve ser analisado.
--
-- Próximo passo após executar:
--   Enviar o resultset completo para fechar a assinatura real da RPC 5B e decidir se
--   mesa_cliente_fluxo_operacoes será suficiente ou se precisará de colunas/tabela auxiliar.

with
required_tables as (
  select * from (values
    ('public', 'mesa_cliente_fluxo_operacoes', 'tabela principal candidata para registro de operações 5B'),
    ('public', 'mesa_cliente_agendas_financeiras', 'agenda persistida fonte soberana'),
    ('public', 'mesa_cliente_fluxo_parcelas', 'parcelas persistidas vinculadas à agenda'),
    ('public', 'mesa_simulacoes', 'simulação comercial/financeira'),
    ('public', 'mesa_cliente_politicas_financeiras', 'política financeira soberana'),
    ('public', 'corretores', 'identidade, tenant e autorização do usuário'),
    ('public', 'empreendimentos', 'escopo do empreendimento')
  ) as t(table_schema, table_name, finalidade)
),
table_status as (
  select
    rt.*,
    to_regclass(format('%I.%I', rt.table_schema, rt.table_name)) is not null as existe
  from required_tables rt
),
operacoes_columns as (
  select
    c.column_name,
    c.ordinal_position,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable,
    c.column_default,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'mesa_cliente_fluxo_operacoes'
),
required_columns as (
  select * from (values
    ('core', 'id', 'identificador da operação'),
    ('core', 'empresa_id', 'tenant soberano vindo do banco'),
    ('core', 'simulacao_id', 'vínculo com simulação'),
    ('core', 'empreendimento_id', 'vínculo com empreendimento'),
    ('core', 'tipo_operacao', 'tipo: antecipacao/postergacao/vpl ou enum equivalente'),
    ('core', 'status_operacao', 'status da operação'),
    ('core', 'valor_movido', 'valor da operação'),
    ('core', 'metadata', 'payload auditável para dados complementares'),
    ('core', 'confirmado', 'flag de confirmação'),
    ('core', 'confirmado_por', 'usuário que confirmou'),
    ('core', 'confirmado_em', 'data/hora de confirmação'),
    ('calculo', 'grupo_origem', 'grupo financeiro de origem'),
    ('calculo', 'grupo_destino', 'grupo financeiro de destino'),
    ('calculo', 'data_origem', 'data original da parcela/operação'),
    ('calculo', 'data_destino', 'data destino da operação'),
    ('calculo', 'taxa_ano_pct', 'taxa anual aplicada'),
    ('calculo', 'valor_base', 'valor-base usado no cálculo'),
    ('calculo', 'desconto_calculado', 'desconto calculado'),
    ('calculo', 'acrescimo_calculado', 'acréscimo calculado'),
    ('calculo', 'economia_liquida', 'economia líquida calculada'),
    ('seguranca', 'visivel_cliente', 'controle de exposição cliente-safe'),
    ('5b_recomendado', 'agenda_id', 'vínculo direto com agenda persistida; se ausente, avaliar adicionar'),
    ('5b_recomendado', 'parcela_id', 'vínculo direto com parcela; se ausente, avaliar adicionar'),
    ('5b_recomendado', 'politica_id', 'política financeira usada; se ausente, avaliar adicionar'),
    ('5b_recomendado', 'checksum_operacao', 'idempotência canônica; se ausente, avaliar adicionar'),
    ('5b_recomendado', 'idempotency_key', 'idempotência alternativa; se ausente, checksum canônico deve ser criado'),
    ('5b_recomendado', 'criado_por', 'usuário registrador; se ausente, avaliar campo/auditoria'),
    ('5b_recomendado', 'created_by', 'usuário registrador alternativo; se ausente, avaliar campo/auditoria'),
    ('5b_recomendado', 'created_at', 'timestamp de criação'),
    ('5b_recomendado', 'updated_at', 'timestamp de atualização')
  ) as t(grupo, column_name, finalidade)
),
column_presence as (
  select
    rc.grupo,
    rc.column_name,
    rc.finalidade,
    oc.column_name is not null as existe,
    oc.data_type,
    oc.udt_schema,
    oc.udt_name,
    oc.is_nullable,
    oc.column_default
  from required_columns rc
  left join operacoes_columns oc
    on oc.column_name = rc.column_name
),
constraints_inventory as (
  select
    con.conname,
    con.contype,
    pg_get_constraintdef(con.oid, true) as definition
  from pg_constraint con
  join pg_class cls on cls.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = cls.relnamespace
  where nsp.nspname = 'public'
    and cls.relname = 'mesa_cliente_fluxo_operacoes'
),
indexes_inventory as (
  select
    i.indexname,
    i.indexdef
  from pg_indexes i
  where i.schemaname = 'public'
    and i.tablename = 'mesa_cliente_fluxo_operacoes'
),
rls_inventory as (
  select
    n.nspname as schemaname,
    c.relname as tablename,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as rls_forced
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'mesa_cliente_fluxo_operacoes'
),
policies_inventory as (
  select
    p.policyname,
    p.permissive,
    p.roles,
    p.cmd,
    p.qual,
    p.with_check
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'mesa_cliente_fluxo_operacoes'
),
grants_inventory as (
  select
    tp.grantee,
    tp.privilege_type,
    tp.is_grantable
  from information_schema.table_privileges tp
  where tp.table_schema = 'public'
    and tp.table_name = 'mesa_cliente_fluxo_operacoes'
    and tp.grantee in ('anon', 'authenticated', 'service_role', 'postgres')
),
enum_inventory as (
  select
    format('%I.%I', n.nspname, t.typname) as enum_type,
    jsonb_agg(e.enumlabel order by e.enumsortorder) as labels
  from pg_type t
  join pg_namespace n on n.oid = t.typnamespace
  join pg_enum e on e.enumtypid = t.oid
  where n.nspname = 'public'
    and (
      t.typname ilike '%operacao%'
      or t.typname ilike '%finance%'
      or t.typname ilike '%mesa%'
    )
  group by n.nspname, t.typname
),
status_distribution as (
  select
    coalesce(to_jsonb(o)->>'status_operacao', '__sem_status__') as status_operacao,
    count(*)::integer as qtd
  from public.mesa_cliente_fluxo_operacoes o
  group by 1
),
confirmed_count as (
  select count(*)::integer as qtd
  from public.mesa_cliente_fluxo_operacoes o
  where lower(coalesce(to_jsonb(o)->>'status_operacao', '')) = 'confirmada'
     or lower(coalesce(to_jsonb(o)->>'confirmado', '')) in ('true', 't', '1')
),
function_inventory as (
  select
    'public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'::text as function_signature,
    to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)') is not null as existe,
    coalesce(has_function_privilege('anon', to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'), 'EXECUTE'), false) as anon_execute,
    coalesce(has_function_privilege('authenticated', to_regprocedure('public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)'), 'EXECUTE'), false) as authenticated_execute
  union all
  select
    'public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)'::text as function_signature,
    to_regprocedure('public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)') is not null as existe,
    coalesce(has_function_privilege('anon', to_regprocedure('public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)'), 'EXECUTE'), false) as anon_execute,
    coalesce(has_function_privilege('authenticated', to_regprocedure('public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)'), 'EXECUTE'), false) as authenticated_execute
  union all
  select
    'public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,jsonb,jsonb)'::text as function_signature,
    to_regprocedure('public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,jsonb,jsonb)') is not null as existe,
    coalesce(has_function_privilege('anon', to_regprocedure('public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,jsonb,jsonb)'), 'EXECUTE'), false) as anon_execute,
    coalesce(has_function_privilege('authenticated', to_regprocedure('public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,jsonb,jsonb)'), 'EXECUTE'), false) as authenticated_execute
),
core_summary as (
  select
    bool_and(existe) filter (where grupo = 'core') as core_cols_ok,
    count(*) filter (where grupo = 'core' and not existe) as core_cols_missing,
    count(*) filter (where grupo = '5b_recomendado' and not existe) as recommended_cols_missing,
    count(*) filter (where grupo = '5b_recomendado' and column_name in ('checksum_operacao', 'idempotency_key') and existe) as idempotency_cols_found,
    count(*) filter (where grupo = '5b_recomendado' and column_name in ('agenda_id') and existe) as agenda_id_cols_found,
    count(*) filter (where grupo = '5b_recomendado' and column_name in ('parcela_id') and existe) as parcela_id_cols_found
  from column_presence
),
readiness as (
  select
    (select bool_and(existe) from table_status) as required_tables_ok,
    coalesce((select core_cols_ok from core_summary), false) as core_cols_ok,
    coalesce((select idempotency_cols_found from core_summary), 0) > 0 as has_idempotency_col,
    coalesce((select agenda_id_cols_found from core_summary), 0) > 0 as has_agenda_id_col,
    coalesce((select parcela_id_cols_found from core_summary), 0) > 0 as has_parcela_id_col,
    exists(select 1 from enum_inventory where enum_type = 'public.mesa_financeira_operacao_tipo') as has_tipo_operacao_enum,
    exists(select 1 from constraints_inventory where definition ilike '%status_operacao%') as has_status_constraint,
    exists(select 1 from indexes_inventory where indexdef ilike '%checksum%' or indexdef ilike '%idempot%') as has_idempotency_index,
    exists(select 1 from policies_inventory) as has_policies,
    exists(select 1 from grants_inventory where grantee = 'authenticated') as has_authenticated_table_grant
)
select
  '01_tabelas_obrigatorias'::text as bloco,
  case when bool_and(existe) then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'tabelas', jsonb_agg(jsonb_build_object(
      'schema', table_schema,
      'tabela', table_name,
      'existe', existe,
      'finalidade', finalidade
    ) order by table_name)
  ) as detalhe
from table_status

union all

select
  '02_colunas_mesa_cliente_fluxo_operacoes'::text as bloco,
  case when count(*) > 0 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'qtd_colunas', count(*),
    'colunas', coalesce(jsonb_agg(jsonb_build_object(
      'ordinal_position', ordinal_position,
      'column_name', column_name,
      'data_type', data_type,
      'udt_schema', udt_schema,
      'udt_name', udt_name,
      'is_nullable', is_nullable,
      'column_default', column_default,
      'character_maximum_length', character_maximum_length,
      'numeric_precision', numeric_precision,
      'numeric_scale', numeric_scale
    ) order by ordinal_position), '[]'::jsonb)
  ) as detalhe
from operacoes_columns

union all

select
  '03_presenca_colunas_core_e_recomendadas_5b'::text as bloco,
  case
    when bool_and(existe) filter (where grupo = 'core') then
      case when count(*) filter (where grupo = '5b_recomendado' and not existe) > 0 then 'WARN' else 'PASS' end
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'core_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'core' and not existe), '[]'::jsonb),
    'recomendadas_5b_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = '5b_recomendado' and not existe), '[]'::jsonb),
    'colunas', jsonb_agg(jsonb_build_object(
      'grupo', grupo,
      'column_name', column_name,
      'existe', existe,
      'data_type', data_type,
      'udt_schema', udt_schema,
      'udt_name', udt_name,
      'is_nullable', is_nullable,
      'column_default', column_default,
      'finalidade', finalidade
    ) order by grupo, column_name)
  ) as detalhe
from column_presence

union all

select
  '04_constraints_operacoes'::text as bloco,
  case when count(*) > 0 then 'PASS' else 'WARN' end as status,
  jsonb_build_object(
    'qtd_constraints', count(*),
    'constraints', coalesce(jsonb_agg(jsonb_build_object(
      'conname', conname,
      'contype', contype,
      'definition', definition
    ) order by conname), '[]'::jsonb)
  ) as detalhe
from constraints_inventory

union all

select
  '05_indices_operacoes'::text as bloco,
  case
    when exists(select 1 from indexes_inventory where indexdef ilike '%simulacao_id%' and indexdef ilike '%empresa_id%') then 'PASS'
    else 'WARN'
  end as status,
  jsonb_build_object(
    'qtd_indices', count(*),
    'tem_indice_empresa_simulacao', exists(select 1 from indexes_inventory where indexdef ilike '%simulacao_id%' and indexdef ilike '%empresa_id%'),
    'tem_indice_idempotencia', exists(select 1 from indexes_inventory where indexdef ilike '%checksum%' or indexdef ilike '%idempot%'),
    'indices', coalesce(jsonb_agg(jsonb_build_object(
      'indexname', indexname,
      'indexdef', indexdef
    ) order by indexname), '[]'::jsonb)
  ) as detalhe
from indexes_inventory

union all

select
  '06_rls_policies_operacoes'::text as bloco,
  case
    when exists(select 1 from rls_inventory where rls_enabled) then 'PASS'
    else 'WARN'
  end as status,
  jsonb_build_object(
    'rls', coalesce((select jsonb_agg(jsonb_build_object(
      'schemaname', schemaname,
      'tablename', tablename,
      'rls_enabled', rls_enabled,
      'rls_forced', rls_forced
    )) from rls_inventory), '[]'::jsonb),
    'qtd_policies', (select count(*) from policies_inventory),
    'policies', coalesce((select jsonb_agg(jsonb_build_object(
      'policyname', policyname,
      'permissive', permissive,
      'roles', roles,
      'cmd', cmd,
      'qual', qual,
      'with_check', with_check
    ) order by policyname) from policies_inventory), '[]'::jsonb)
  ) as detalhe

union all

select
  '07_grants_tabela_operacoes'::text as bloco,
  case
    when exists(select 1 from grants_inventory where grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')) then 'FAIL'
    when exists(select 1 from grants_inventory where grantee = 'authenticated') then 'PASS'
    else 'WARN'
  end as status,
  jsonb_build_object(
    'anon_tem_dml', exists(select 1 from grants_inventory where grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')),
    'authenticated_tem_algum_grant', exists(select 1 from grants_inventory where grantee = 'authenticated'),
    'grants', coalesce(jsonb_agg(jsonb_build_object(
      'grantee', grantee,
      'privilege_type', privilege_type,
      'is_grantable', is_grantable
    ) order by grantee, privilege_type), '[]'::jsonb)
  ) as detalhe
from grants_inventory

union all

select
  '08_enums_financeiros'::text as bloco,
  case when exists(select 1 from enum_inventory where enum_type = 'public.mesa_financeira_operacao_tipo') then 'PASS' else 'WARN' end as status,
  jsonb_build_object(
    'tem_enum_mesa_financeira_operacao_tipo', exists(select 1 from enum_inventory where enum_type = 'public.mesa_financeira_operacao_tipo'),
    'enums', coalesce(jsonb_agg(jsonb_build_object(
      'enum_type', enum_type,
      'labels', labels
    ) order by enum_type), '[]'::jsonb)
  ) as detalhe
from enum_inventory

union all

select
  '09_status_operacao_distribuicao_atual'::text as bloco,
  'INFO'::text as status,
  jsonb_build_object(
    'qtd_operacoes_confirmadas_ou_flag_confirmado', (select qtd from confirmed_count),
    'status_distribution', coalesce(jsonb_agg(jsonb_build_object(
      'status_operacao', status_operacao,
      'qtd', qtd
    ) order by status_operacao), '[]'::jsonb),
    'observacao', 'Leitura informativa. Não cria, não altera e não remove operações.'
  ) as detalhe
from status_distribution

union all

select
  '10_funcoes_dependencias_4b_5a_e_candidata_5b'::text as bloco,
  case
    when bool_and(existe) filter (where function_signature like '%persistir_agenda%' or function_signature like '%simular_impacto%') then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'funcoes', jsonb_agg(jsonb_build_object(
      'function_signature', function_signature,
      'existe', existe,
      'anon_execute', anon_execute,
      'authenticated_execute', authenticated_execute
    ) order by function_signature),
    'observacao', 'A função 5B candidata ainda pode não existir neste momento; isso é esperado antes da migration.'
  ) as detalhe
from function_inventory

union all

select
  '11_readiness_para_contrato_5b'::text as bloco,
  case
    when not required_tables_ok or not core_cols_ok then 'FAIL'
    when not has_idempotency_col or not has_idempotency_index or not has_agenda_id_col or not has_parcela_id_col then 'WARN'
    else 'PASS'
  end as status,
  jsonb_build_object(
    'required_tables_ok', required_tables_ok,
    'core_cols_ok', core_cols_ok,
    'has_tipo_operacao_enum', has_tipo_operacao_enum,
    'has_status_constraint', has_status_constraint,
    'has_idempotency_col', has_idempotency_col,
    'has_idempotency_index', has_idempotency_index,
    'has_agenda_id_col', has_agenda_id_col,
    'has_parcela_id_col', has_parcela_id_col,
    'has_policies', has_policies,
    'has_authenticated_table_grant', has_authenticated_table_grant,
    'interpretacao', case
      when not required_tables_ok then 'Faltam tabelas obrigatórias. Não criar migration 5B ainda.'
      when not core_cols_ok then 'Faltam colunas core em mesa_cliente_fluxo_operacoes. Fechar adaptação de schema antes da RPC 5B.'
      when not has_idempotency_col or not has_idempotency_index or not has_agenda_id_col or not has_parcela_id_col then 'Schema parece usável como base, mas exige decisão de migration para vínculo agenda/parcela e idempotência forte.'
      else 'Schema parece pronto para desenhar a migration/RPC 5B com segurança.'
    end,
    'recommended_next_step_if_pass_or_warn', 'Analisar este resultset e fechar assinatura real da RPC 5B antes de criar qualquer migration.'
  ) as detalhe
from readiness

union all

select
  '99_readonly_notice'::text as bloco,
  'INFO'::text as status,
  jsonb_build_object(
    'mensagem', 'Preflight 11 é somente leitura. Não cria fixture, não chama RPC de escrita e não altera schema.',
    'proximos_arquivos_esperados_se_aprovado', jsonb_build_array(
      'docs/mesa-cliente/fase-5b-validacao-preflight-11.md',
      'supabase/migrations/<timestamp>_mesa_cliente_fase_5b_registro_operacao_financeira.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/11a_validacao_registro_operacao_financeira_rollback.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/11b_validacao_registro_operacao_financeira_negativos_rollback.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/11d_validacao_registro_operacao_financeira_confirmada_rollback.sql',
      'supabase/tests/mesa-cliente/engenharia-financeira/11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql'
    )
  ) as detalhe

order by bloco;
