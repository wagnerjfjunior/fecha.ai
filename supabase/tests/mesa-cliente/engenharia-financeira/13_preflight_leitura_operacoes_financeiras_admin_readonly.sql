-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- 13 — Preflight read-only para leitura/consulta administrativa de operações financeiras.
--
-- Objetivo:
--   Mapear o schema real antes de qualquer migration/RPC da 5D.
--   Validar se a base 5B/5C está pronta para receber RPCs administrativas read-only.
--
-- Regras:
--   - Somente SELECT.
--   - Seguro para SQL Editor do Supabase.
--   - Não cria fixture.
--   - Não altera schema.
--   - Não chama RPC de escrita.
--   - Não chama RPC 5D.
--
-- Resultado esperado antes da migration 5D:
--   - Base 5B/5C presente.
--   - RPCs 5D ainda ausentes.
--   - RLS ativo.
--   - Grants sem exposição indevida.
--   - Readiness PASS ou WARN controlado, nunca FAIL.

with
required_tables as (
  select * from (values
    ('public', 'mesa_cliente_fluxo_operacoes', 'operação financeira registrada pela 5B, administrada pela 5C e consultada pela 5D'),
    ('public', 'mesa_cliente_agendas_financeiras', 'agenda persistida que deve ser apenas consultada pela 5D'),
    ('public', 'mesa_cliente_fluxo_parcelas', 'parcelas persistidas que não devem ser mutadas pela 5D'),
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
    ('core_read_5d', 'id', 'identificador da operação'),
    ('core_read_5d', 'empresa_id', 'tenant soberano vindo do banco'),
    ('core_read_5d', 'simulacao_id', 'vínculo com simulação'),
    ('core_read_5d', 'agenda_id', 'vínculo com agenda persistida'),
    ('core_read_5d', 'parcela_origem_id', 'parcela de origem da operação'),
    ('core_read_5d', 'tipo_operacao', 'tipo da operação financeira'),
    ('core_read_5d', 'status_operacao', 'estado administrativo da operação'),
    ('core_read_5d', 'visivel_cliente', 'controle de exposição ao cliente'),
    ('core_read_5d', 'checksum_operacao', 'idempotência canônica da operação'),
    ('core_read_5d', 'metadata', 'metadados técnicos/controlados'),
    ('core_read_5d', 'created_at', 'timestamp de criação'),
    ('core_read_5d', 'updated_at', 'timestamp de atualização'),

    ('financeiro_5b', 'empreendimento_id', 'empreendimento soberano'),
    ('financeiro_5b', 'politica_id', 'política financeira usada no cálculo'),
    ('financeiro_5b', 'grupo_origem', 'grupo de origem financeiro'),
    ('financeiro_5b', 'grupo_destino', 'grupo de destino financeiro'),
    ('financeiro_5b', 'parcela_destino_id', 'parcela de destino quando aplicável'),
    ('financeiro_5b', 'valor_movido', 'valor financeiro movimentado'),
    ('financeiro_5b', 'valor_base', 'valor-base de cálculo'),
    ('financeiro_5b', 'data_origem', 'data original da parcela/operação'),
    ('financeiro_5b', 'data_destino', 'data destino da operação'),
    ('financeiro_5b', 'taxa_ano_pct', 'taxa anual aplicada'),
    ('financeiro_5b', 'vpl_aplicado_pct', 'VPL aplicado'),
    ('financeiro_5b', 'desconto_calculado', 'desconto calculado'),
    ('financeiro_5b', 'acrescimo_calculado', 'acréscimo calculado'),
    ('financeiro_5b', 'economia_liquida', 'economia líquida calculada'),
    ('financeiro_5b', 'premio_corretor_pct', 'percentual de prêmio do corretor'),
    ('financeiro_5b', 'dias_calculo', 'dias usados no cálculo'),
    ('financeiro_5b', 'status_premio', 'status do prêmio calculado'),

    ('auditoria_5c', 'confirmado', 'flag de confirmação'),
    ('auditoria_5c', 'confirmado_por', 'auth.uid() do usuário que confirmou'),
    ('auditoria_5c', 'confirmado_em', 'timestamp de confirmação'),
    ('auditoria_5c', 'cancelado_por', 'auth.uid() do usuário que cancelou'),
    ('auditoria_5c', 'cancelado_em', 'timestamp de cancelamento'),
    ('auditoria_5c', 'motivo_cancelamento', 'motivo administrativo do cancelamento'),

    ('autoria', 'criado_por', 'usuário que registrou a operação')
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
visibility_distribution as (
  select coalesce(o.visivel_cliente, false) as visivel_cliente, count(*)::integer as qtd
  from public.mesa_cliente_fluxo_operacoes o
  group by 1
),
function_signatures as (
  select * from (values
    ('5B', 'public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)', 'dependência: registro administrativo de operação financeira'),
    ('5C', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)', 'dependência: confirmação/cancelamento administrativo'),
    ('5D_LISTAR_CANDIDATA', 'public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)', 'candidata 5D: listagem administrativa read-only'),
    ('5D_OBTER_CANDIDATA', 'public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)', 'candidata 5D: detalhe administrativo read-only')
  ) as t(fase, function_signature, finalidade)
),
function_inventory as (
  select
    fs.fase,
    fs.function_signature,
    fs.finalidade,
    to_regprocedure(fs.function_signature) as function_oid,
    to_regprocedure(fs.function_signature) is not null as existe,
    coalesce(has_function_privilege('anon', to_regprocedure(fs.function_signature), 'EXECUTE'), false) as anon_execute,
    coalesce(has_function_privilege('public', to_regprocedure(fs.function_signature), 'EXECUTE'), false) as public_execute,
    coalesce(has_function_privilege('authenticated', to_regprocedure(fs.function_signature), 'EXECUTE'), false) as authenticated_execute
  from function_signatures fs
),
function_metadata as (
  select
    fi.fase,
    fi.function_signature,
    fi.finalidade,
    fi.existe,
    fi.anon_execute,
    fi.public_execute,
    fi.authenticated_execute,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    p.proconfig as function_config,
    pg_get_function_result(p.oid) as function_result,
    obj_description(p.oid, 'pg_proc') as function_comment
  from function_inventory fi
  left join pg_proc p on p.oid = fi.function_oid
),
comentarios_colunas as (
  select
    jsonb_object_agg(a.attname, col_description(a.attrelid, a.attnum) order by a.attname) as comentarios
  from pg_attribute a
  where a.attrelid = 'public.mesa_cliente_fluxo_operacoes'::regclass
    and a.attnum > 0
    and not a.attisdropped
    and a.attname in (
      'agenda_id', 'checksum_operacao',
      'confirmado', 'confirmado_por', 'confirmado_em',
      'cancelado_por', 'cancelado_em', 'motivo_cancelamento'
    )
),
readiness as (
  select
    (select bool_and(existe) from table_status) as required_tables_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'core_read_5d'), false) as core_read_cols_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'financeiro_5b'), false) as financeiro_cols_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'auditoria_5c'), false) as auditoria_5c_cols_ok,
    coalesce((select bool_and(existe) from column_presence where grupo = 'autoria'), false) as autoria_cols_ok,
    coalesce((select suporta_simulada from status_support), false) as suporta_simulada,
    coalesce((select suporta_confirmada from status_support), false) as suporta_confirmada,
    coalesce((select suporta_cancelada from status_support), false) as suporta_cancelada,
    coalesce((select suporta_bloqueada from status_support), false) as suporta_bloqueada,
    exists(select 1 from indexes_inventory where indexdef ilike '%empresa_id%' and indexdef ilike '%simulacao_id%' and indexdef ilike '%agenda_id%') as has_listagem_index,
    exists(select 1 from indexes_inventory where indexdef ilike '%status_operacao%') as has_status_index,
    exists(select 1 from indexes_inventory where indexdef ilike '%checksum_operacao%' or indexdef ilike '%checksum%') as has_checksum_index,
    exists(select 1 from rls_inventory where rls_enabled) as rls_enabled,
    exists(select 1 from function_inventory where fase = '5B' and existe) as rpc_5b_exists,
    exists(select 1 from function_inventory where fase = '5C' and existe) as rpc_5c_exists,
    exists(select 1 from function_inventory where fase = '5D_LISTAR_CANDIDATA' and existe) as rpc_5d_listar_exists,
    exists(select 1 from function_inventory where fase = '5D_OBTER_CANDIDATA' and existe) as rpc_5d_obter_exists
)
select bloco, status, detalhe
from (
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
    '02_colunas_base_leitura_5d'::text,
    case
      when bool_and(existe) filter (where grupo = 'core_read_5d')
       and bool_and(existe) filter (where grupo = 'financeiro_5b')
       and bool_and(existe) filter (where grupo = 'auditoria_5c')
      then 'PASS'
      when bool_and(existe) filter (where grupo = 'core_read_5d')
       and bool_and(existe) filter (where grupo = 'auditoria_5c')
      then 'WARN'
      else 'FAIL'
    end,
    jsonb_build_object(
      'core_read_5d_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'core_read_5d' and not existe), '[]'::jsonb),
      'financeiro_5b_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'financeiro_5b' and not existe), '[]'::jsonb),
      'auditoria_5c_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'auditoria_5c' and not existe), '[]'::jsonb),
      'autoria_missing', coalesce(jsonb_agg(column_name order by column_name) filter (where grupo = 'autoria' and not existe), '[]'::jsonb),
      'colunas', jsonb_agg(jsonb_build_object(
        'grupo', grupo,
        'column_name', column_name,
        'existe', existe,
        'data_type', data_type,
        'udt_name', udt_name,
        'is_nullable', is_nullable,
        'column_default', column_default,
        'finalidade', finalidade
      ) order by grupo, column_name)
    )
  from column_presence

  union all

  select
    '03_status_operacao_suporte_5d'::text,
    case
      when suporta_simulada and suporta_confirmada and suporta_cancelada and suporta_bloqueada then 'PASS'
      when suporta_simulada and suporta_confirmada and suporta_cancelada then 'WARN'
      else 'FAIL'
    end,
    jsonb_build_object(
      'suporta_simulada', suporta_simulada,
      'suporta_confirmada', suporta_confirmada,
      'suporta_cancelada', suporta_cancelada,
      'suporta_bloqueada', suporta_bloqueada,
      'constraints', coalesce((select jsonb_agg(jsonb_build_object('conname', conname, 'contype', contype, 'definition', definition) order by conname) from constraints_inventory), '[]'::jsonb)
    )
  from status_support

  union all

  select
    '04_status_operacao_distribuicao_atual'::text,
    'INFO'::text,
    jsonb_build_object(
      'status_distribution', coalesce(jsonb_agg(jsonb_build_object('status_operacao', status_operacao, 'qtd', qtd) order by status_operacao), '[]'::jsonb),
      'observacao', 'Leitura informativa. Não cria, não confirma, não cancela e não consulta RPC 5D.'
    )
  from status_distribution

  union all

  select
    '05_visibilidade_cliente_distribuicao_atual'::text,
    case when coalesce(sum(qtd) filter (where visivel_cliente = true), 0) = 0 then 'PASS' else 'WARN' end,
    jsonb_build_object(
      'visibilidade_distribution', coalesce(jsonb_agg(jsonb_build_object('visivel_cliente', visivel_cliente, 'qtd', qtd) order by visivel_cliente), '[]'::jsonb),
      'qtd_visivel_cliente', coalesce(sum(qtd) filter (where visivel_cliente = true), 0),
      'observacao', 'A 5D é administrativa e cliente_safe=false; operações visíveis ao cliente exigem fase própria.'
    )
  from visibility_distribution

  union all

  select
    '06_indices_para_listagem_5d'::text,
    case
      when exists(select 1 from indexes_inventory where indexdef ilike '%empresa_id%' and indexdef ilike '%simulacao_id%' and indexdef ilike '%agenda_id%') then 'PASS'
      else 'WARN'
    end,
    jsonb_build_object(
      'tem_indice_empresa_simulacao_agenda', exists(select 1 from indexes_inventory where indexdef ilike '%empresa_id%' and indexdef ilike '%simulacao_id%' and indexdef ilike '%agenda_id%'),
      'tem_indice_status_operacao', exists(select 1 from indexes_inventory where indexdef ilike '%status_operacao%'),
      'tem_indice_checksum', exists(select 1 from indexes_inventory where indexdef ilike '%checksum_operacao%' or indexdef ilike '%checksum%'),
      'indices', coalesce(jsonb_agg(jsonb_build_object('indexname', indexname, 'indexdef', indexdef) order by indexname), '[]'::jsonb)
    )
  from indexes_inventory

  union all

  select
    '07_rls_policies_operacoes'::text,
    case when exists(select 1 from rls_inventory where rls_enabled) then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'rls', coalesce((select jsonb_agg(jsonb_build_object('schemaname', schemaname, 'tablename', tablename, 'rls_enabled', rls_enabled, 'rls_forced', rls_forced)) from rls_inventory), '[]'::jsonb),
      'qtd_policies', (select count(*) from policies_inventory),
      'policies', coalesce((select jsonb_agg(jsonb_build_object('policyname', policyname, 'permissive', permissive, 'roles', roles, 'cmd', cmd, 'qual', qual, 'with_check', with_check) order by policyname) from policies_inventory), '[]'::jsonb)
    )

  union all

  select
    '08_grants_tabela_operacoes'::text,
    case
      when exists(select 1 from grants_inventory where grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')) then 'FAIL'
      when exists(select 1 from grants_inventory where grantee = 'authenticated' and privilege_type = 'SELECT') then 'PASS'
      else 'WARN'
    end,
    jsonb_build_object(
      'anon_tem_dml', exists(select 1 from grants_inventory where grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')),
      'authenticated_tem_select', exists(select 1 from grants_inventory where grantee = 'authenticated' and privilege_type = 'SELECT'),
      'authenticated_tem_dml_direto', exists(select 1 from grants_inventory where grantee = 'authenticated' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')),
      'grants', coalesce(jsonb_agg(jsonb_build_object('grantee', grantee, 'privilege_type', privilege_type, 'is_grantable', is_grantable) order by grantee, privilege_type), '[]'::jsonb)
    )
  from grants_inventory

  union all

  select
    '09_funcoes_dependencias_e_ausencia_5d'::text,
    case
      when not exists(select 1 from function_inventory where fase = '5B' and existe) then 'FAIL'
      when not exists(select 1 from function_inventory where fase = '5C' and existe) then 'FAIL'
      when exists(select 1 from function_inventory where fase like '5D_%' and existe) then 'WARN'
      else 'PASS'
    end,
    jsonb_build_object(
      'rpc_5b_existe', exists(select 1 from function_inventory where fase = '5B' and existe),
      'rpc_5c_existe', exists(select 1 from function_inventory where fase = '5C' and existe),
      'rpc_5d_listar_ja_existe', exists(select 1 from function_inventory where fase = '5D_LISTAR_CANDIDATA' and existe),
      'rpc_5d_obter_ja_existe', exists(select 1 from function_inventory where fase = '5D_OBTER_CANDIDATA' and existe),
      'funcoes', coalesce(jsonb_agg(to_jsonb(function_metadata.*) order by fase, function_signature), '[]'::jsonb)
    )
  from function_metadata

  union all

  select
    '10_comentarios_rastreabilidade_5b_5c'::text,
    case
      when comentarios is not null then 'PASS'
      else 'WARN'
    end,
    jsonb_build_object('comentarios', comentarios)
  from comentarios_colunas

  union all

  select
    '11_readiness_para_migration_5d'::text,
    case
      when not required_tables_ok
        or not core_read_cols_ok
        or not auditoria_5c_cols_ok
        or not rpc_5b_exists
        or not rpc_5c_exists
        or not rls_enabled
        or not (suporta_simulada and suporta_confirmada and suporta_cancelada)
      then 'FAIL'
      when rpc_5d_listar_exists or rpc_5d_obter_exists then 'WARN'
      when not financeiro_cols_ok or not has_listagem_index then 'WARN'
      else 'PASS'
    end,
    jsonb_build_object(
      'required_tables_ok', required_tables_ok,
      'core_read_cols_ok', core_read_cols_ok,
      'financeiro_cols_ok', financeiro_cols_ok,
      'auditoria_5c_cols_ok', auditoria_5c_cols_ok,
      'autoria_cols_ok', autoria_cols_ok,
      'suporta_simulada', suporta_simulada,
      'suporta_confirmada', suporta_confirmada,
      'suporta_cancelada', suporta_cancelada,
      'suporta_bloqueada', suporta_bloqueada,
      'has_listagem_index', has_listagem_index,
      'has_status_index', has_status_index,
      'has_checksum_index', has_checksum_index,
      'rls_enabled', rls_enabled,
      'rpc_5b_exists', rpc_5b_exists,
      'rpc_5c_exists', rpc_5c_exists,
      'rpc_5d_listar_exists', rpc_5d_listar_exists,
      'rpc_5d_obter_exists', rpc_5d_obter_exists,
      'interpretacao', case
        when not required_tables_ok then 'Faltam tabelas obrigatórias. Não criar migration 5D ainda.'
        when not core_read_cols_ok then 'Faltam colunas core para leitura administrativa. Corrigir antes da 5D.'
        when not auditoria_5c_cols_ok then 'Faltam colunas de auditoria 5C. A 5D depende da 5C fechada.'
        when not rpc_5b_exists then 'RPC 5B não encontrada. A 5D depende do registro de operação financeira.'
        when not rpc_5c_exists then 'RPC 5C não encontrada. A 5D depende da confirmação/cancelamento administrativo.'
        when not rls_enabled then 'RLS não está ativo em operações. Bloquear avanço da 5D.'
        when not (suporta_simulada and suporta_confirmada and suporta_cancelada) then 'Constraint de status não suporta estados mínimos da 5D.'
        when rpc_5d_listar_exists or rpc_5d_obter_exists then 'RPC 5D já existe antes da migration canônica. Investigar/alinhar antes de seguir.'
        when not financeiro_cols_ok then 'Campos financeiros persistidos estão incompletos; avaliar payload mínimo da 5D antes da migration.'
        when not has_listagem_index then 'Base funcional, mas índice de listagem pode ser recomendado para performance da 5D.'
        else 'Base pronta para desenhar migration/RPCs 5D read-only.'
      end,
      'recommended_next_step_if_pass_or_warn', 'Documentar resultado do Preflight 13 e criar migration/RPCs 5D somente leitura.'
    )
  from readiness

  union all

  select
    '99_readonly_notice'::text,
    'INFO'::text,
    jsonb_build_object(
      'mensagem', 'Preflight 13 é somente leitura. Não cria fixture, não chama RPC de escrita, não chama RPC 5D e não altera schema.',
      'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
      'readonly', true,
      'proximos_arquivos_esperados_se_aprovado', jsonb_build_array(
        'docs/mesa-cliente/fase-5d-validacao-preflight-13.md',
        'supabase/migrations/<timestamp>_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql',
        'supabase/tests/mesa-cliente/engenharia-financeira/13a_validacao_listar_operacoes_financeiras_admin_rollback.sql',
        'supabase/tests/mesa-cliente/engenharia-financeira/13b_validacao_obter_operacao_financeira_admin_rollback.sql',
        'supabase/tests/mesa-cliente/engenharia-financeira/13c_validacao_negativos_seguranca_leitura_operacoes_admin_rollback.sql',
        'supabase/tests/mesa-cliente/engenharia-financeira/13d_validacao_zero_dml_readonly_operacoes_admin_rollback.sql',
        'supabase/tests/mesa-cliente/engenharia-financeira/13e_validacao_filtros_paginacao_ordenacao_operacoes_admin_rollback.sql'
      )
    )
) r
order by bloco;
