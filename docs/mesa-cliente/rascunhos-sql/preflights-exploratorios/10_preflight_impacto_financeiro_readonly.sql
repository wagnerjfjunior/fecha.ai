-- RASCUNHO EXPLORATÓRIO — NÃO USAR COMO PREFLIGHT CANÔNICO DA 5A.1
--
-- Este arquivo foi preservado como inventário estrutural amplo.
-- Ele não governa a trilha oficial da Fase 5A agenda-first.
--
-- Preflight canônico da 5A.1:
--   supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql
--
-- Motivo do arquivamento:
--   Este script nasceu como preflight genérico/payload-first de impacto financeiro,
--   com referência histórica à Fase 5A.2. Após fechamento do contrato atual,
--   a Fase 5A passou a ser agenda-first, usando agenda persistida como fonte soberana.
--
-- Uso permitido:
--   Consulta histórica, inventário complementar e referência de ideias técnicas.
--
-- Uso proibido:
--   Rodar como gate oficial da 5A.1 ou usá-lo para autorizar migration/RPC 5A.

-- FECH.AI / MesaCliente
-- Fase 5A.2 - Preflight read-only de impacto financeiro
--
-- Objetivo:
--   Inventariar o banco real antes de qualquer SQL de cálculo financeiro.
--
-- Regras deste arquivo:
--   - READ-ONLY.
--   - Não cria tabela temporária.
--   - Não faz INSERT/UPDATE/DELETE.
--   - Não chama RPC de cálculo.
--   - Não presume colunas de negócio.
--   - Retorna um único resultset gerencial.
--
-- Frase de parada:
--   Preflight 10 read-only concluído. Envie todos os resultsets antes de criar qualquer migration 5A.2.

with
target_tables(table_name, required, finalidade) as (
  values
    ('mesa_simulacoes', true, 'simulação base do MesaCliente'),
    ('mesa_cliente_agendas_financeiras', true, 'agenda financeira ativa persistida pela 4B'),
    ('mesa_cliente_fluxo_parcelas', true, 'parcelas financeiras vinculadas à agenda'),
    ('mesa_cliente_fluxo_operacoes', true, 'operações financeiras futuras da 5B/5C; 5A deve apenas ler para bloqueios'),
    ('corretores', true, 'validação de usuário, tenant e perfil'),
    ('empreendimentos', true, 'validação de empreendimento e tenant'),
    ('empresas', true, 'validação de tenant'),
    ('unidades_estoque', false, 'vínculo opcional da simulação/agenda/unidade'),
    ('leads', false, 'vínculo opcional da simulação')
),
existing_tables as (
  select
    tt.table_name,
    tt.required,
    tt.finalidade,
    (c.oid is not null) as exists_in_database,
    pg_get_userbyid(c.relowner) as owner_name,
    coalesce(c.relrowsecurity, false) as rls_enabled,
    coalesce(c.relforcerowsecurity, false) as rls_forced,
    c.relkind
  from target_tables tt
  left join pg_class c
    on c.relname = tt.table_name
   and c.relnamespace = 'public'::regnamespace
   and c.relkind in ('r', 'p')
),
target_functions(label, function_name, expected_identity_arguments, required_now, finalidade) as (
  values
    ('auth_helper_assert', 'mesa_cliente_assert_auth', '', true, 'auth.uid obrigatório e usuário autenticado'),
    ('auth_helper_empresa', 'my_empresa_id', '', true, 'empresa/tenant resolvido pelo banco'),
    ('auth_helper_root', 'is_root', '', true, 'bypass controlado para root/admin global'),
    ('4b_persistencia_agenda', 'mesa_cliente_persistir_agenda_financeira_admin', 'p_simulacao_id uuid, p_data_ato date, p_fluxo_json jsonb, p_payload_tabela jsonb', true, 'agenda persistida aprovada na 4B'),
    ('4c_cliente_safe', 'mesa_cliente_obter_agenda_financeira_cliente_safe', 'p_simulacao_id uuid', true, 'leitura cliente-safe aprovada na 4C'),
    ('5a_candidata', 'mesa_cliente_simular_impacto_financeiro_admin', 'p_simulacao_id uuid, p_agenda_id uuid, p_operacao_json jsonb, p_parametros_json jsonb', false, 'RPC futura; não deve existir antes da migration 5A.2')
),
function_inventory as (
  select
    tf.label,
    tf.function_name,
    tf.expected_identity_arguments,
    tf.required_now,
    tf.finalidade,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'exists_in_database', true,
          'schema_name', n.nspname,
          'identity_arguments', pg_get_function_identity_arguments(p.oid),
          'return_type', pg_get_function_result(p.oid),
          'security_definer', p.prosecdef,
          'volatility', case p.provolatile when 'i' then 'immutable' when 's' then 'stable' when 'v' then 'volatile' else p.provolatile::text end,
          'owner_name', pg_get_userbyid(p.proowner),
          'function_config', p.proconfig,
          'anon_can_execute', has_function_privilege('anon', p.oid, 'EXECUTE'),
          'authenticated_can_execute', has_function_privilege('authenticated', p.oid, 'EXECUTE')
        )
        order by n.nspname, pg_get_function_identity_arguments(p.oid)
      ) filter (where p.oid is not null),
      '[]'::jsonb
    ) as matches,
    count(p.oid)::bigint as qtd_matches
  from target_functions tf
  left join pg_proc p
    on p.proname = tf.function_name
  left join pg_namespace n
    on n.oid = p.pronamespace
   and n.nspname = 'public'
  group by tf.label, tf.function_name, tf.expected_identity_arguments, tf.required_now, tf.finalidade
),
columns_inventory as (
  select
    c.table_name,
    jsonb_agg(
      jsonb_build_object(
        'ordinal_position', c.ordinal_position,
        'column_name', c.column_name,
        'data_type', c.data_type,
        'udt_schema', c.udt_schema,
        'udt_name', c.udt_name,
        'is_nullable', c.is_nullable,
        'column_default', c.column_default,
        'is_identity', c.is_identity
      )
      order by c.ordinal_position
    ) as detalhe
  from information_schema.columns c
  join target_tables tt
    on tt.table_name = c.table_name
  where c.table_schema = 'public'
  group by c.table_name
),
constraints_inventory as (
  select
    rel.relname as table_name,
    jsonb_agg(
      jsonb_build_object(
        'constraint_name', con.conname,
        'constraint_type', con.contype,
        'constraint_definition', pg_get_constraintdef(con.oid, true)
      )
      order by rel.relname, con.conname
    ) as detalhe
  from pg_constraint con
  join pg_class rel
    on rel.oid = con.conrelid
  join pg_namespace ns
    on ns.oid = rel.relnamespace
  join target_tables tt
    on tt.table_name = rel.relname
  where ns.nspname = 'public'
  group by rel.relname
),
indexes_inventory as (
  select
    i.tablename as table_name,
    jsonb_agg(
      jsonb_build_object(
        'indexname', i.indexname,
        'indexdef', i.indexdef
      )
      order by i.tablename, i.indexname
    ) as detalhe
  from pg_indexes i
  join target_tables tt
    on tt.table_name = i.tablename
  where i.schemaname = 'public'
  group by i.tablename
),
policies_inventory as (
  select
    p.tablename as table_name,
    jsonb_agg(
      jsonb_build_object(
        'policyname', p.policyname,
        'cmd', p.cmd,
        'roles', p.roles,
        'qual', p.qual,
        'with_check', p.with_check
      )
      order by p.tablename, p.policyname
    ) as detalhe
  from pg_policies p
  join target_tables tt
    on tt.table_name = p.tablename
  where p.schemaname = 'public'
  group by p.tablename
),
grants_inventory as (
  select
    g.table_name,
    jsonb_agg(
      jsonb_build_object(
        'grantee', g.grantee,
        'privilege_type', g.privilege_type,
        'is_grantable', g.is_grantable
      )
      order by g.table_name, g.grantee, g.privilege_type
    ) as detalhe
  from information_schema.role_table_grants g
  join target_tables tt
    on tt.table_name = g.table_name
  where g.table_schema = 'public'
  group by g.table_name
),
rls_inventory as (
  select
    jsonb_agg(
      jsonb_build_object(
        'table_name', table_name,
        'exists_in_database', exists_in_database,
        'owner_name', owner_name,
        'rls_enabled', rls_enabled,
        'rls_forced', rls_forced,
        'required', required,
        'finalidade', finalidade
      )
      order by required desc, table_name
    ) as detalhe
  from existing_tables
),
table_stats as (
  select
    tt.table_name,
    jsonb_build_object(
      'table_name', tt.table_name,
      'exists_in_database', et.exists_in_database,
      'required', tt.required,
      'estimated_live_rows', coalesce(s.n_live_tup, 0),
      'estimated_dead_rows', coalesce(s.n_dead_tup, 0),
      'last_analyze', s.last_analyze,
      'last_autoanalyze', s.last_autoanalyze,
      'last_vacuum', s.last_vacuum,
      'last_autovacuum', s.last_autovacuum
    ) as detalhe
  from target_tables tt
  left join existing_tables et
    on et.table_name = tt.table_name
  left join pg_stat_user_tables s
    on s.schemaname = 'public'
   and s.relname = tt.table_name
),
column_udts as (
  select distinct
    c.udt_schema,
    c.udt_name
  from information_schema.columns c
  join target_tables tt
    on tt.table_name = c.table_name
  where c.table_schema = 'public'
    and c.udt_schema = 'public'
),
custom_types_inventory as (
  select
    jsonb_agg(
      jsonb_build_object(
        'schema_name', n.nspname,
        'type_name', t.typname,
        'type_kind', case t.typtype
          when 'b' then 'base'
          when 'c' then 'composite'
          when 'd' then 'domain'
          when 'e' then 'enum'
          when 'p' then 'pseudo'
          when 'r' then 'range'
          when 'm' then 'multirange'
          else t.typtype::text
        end,
        'domain_base_type', bt.typname,
        'enum_labels', coalesce(enum_labels.labels, '[]'::jsonb)
      )
      order by n.nspname, t.typname
    ) as detalhe
  from column_udts cu
  join pg_type t
    on t.typname = cu.udt_name
  join pg_namespace n
    on n.oid = t.typnamespace
   and n.nspname = cu.udt_schema
  left join pg_type bt
    on bt.oid = t.typbasetype
  left join lateral (
    select jsonb_agg(e.enumlabel order by e.enumsortorder) as labels
    from pg_enum e
    where e.enumtypid = t.oid
  ) enum_labels on true
),
finance_policy_candidate_tables as (
  select
    rel.relname as table_name,
    rel.relkind,
    obj_description(rel.oid, 'pg_class') as description
  from pg_class rel
  join pg_namespace ns
    on ns.oid = rel.relnamespace
  where ns.nspname = 'public'
    and rel.relkind in ('r', 'p', 'v', 'm')
    and (
      rel.relname ilike any (array['%politic%', '%política%', '%taxa%', '%vpl%', '%juros%', '%financeir%', '%premio%', '%prêmio%', '%comissao%', '%comissão%'])
    )
),
finance_policy_candidate_functions as (
  select
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_arguments,
    pg_get_function_result(p.oid) as return_type,
    p.prosecdef as security_definer,
    case p.provolatile when 'i' then 'immutable' when 's' then 'stable' when 'v' then 'volatile' else p.provolatile::text end as volatility,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute
  from pg_proc p
  join pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and (
      p.proname ilike any (array['%politic%', '%política%', '%taxa%', '%vpl%', '%juros%', '%financeir%', '%impacto%', '%operacao%', '%operação%', '%premio%', '%prêmio%', '%comissao%', '%comissão%', '%mesa_cliente%'])
    )
),
sensitive_columns_inventory as (
  select
    c.table_name,
    c.column_name,
    c.data_type,
    case
      when c.column_name ilike any (array['%metadata%', '%payload%', '%snapshot%']) then 'payload_ou_metadata_bruto'
      when c.column_name ilike any (array['%criado_por%', '%atualizado_por%', '%confirmado_por%', '%cancelado_por%', '%created_by%', '%updated_by%']) then 'auditoria_usuario'
      when c.column_name ilike any (array['%vpl%']) then 'vpl'
      when c.column_name ilike any (array['%premio%', '%prêmio%', '%comissao%', '%comissão%']) then 'premio_ou_comissao'
      when c.column_name ilike any (array['%politica%', '%política%']) then 'politica_interna'
      when c.column_name ilike any (array['%taxa%', '%juros%']) then 'taxa_ou_juros_interno'
      when c.column_name ilike any (array['%desconto%', '%acrescimo%', '%acréscimo%', '%economia%']) then 'calculo_interno'
      else 'revisar'
    end as risco
  from information_schema.columns c
  join target_tables tt
    on tt.table_name = c.table_name
  where c.table_schema = 'public'
    and c.column_name ilike any (
      array[
        '%metadata%', '%payload%', '%snapshot%',
        '%criado_por%', '%atualizado_por%', '%confirmado_por%', '%cancelado_por%', '%created_by%', '%updated_by%',
        '%vpl%', '%premio%', '%prêmio%', '%comissao%', '%comissão%',
        '%politica%', '%política%', '%taxa%', '%juros%',
        '%desconto%', '%acrescimo%', '%acréscimo%', '%economia%'
      ]
    )
),
risk_flags as (
  select
    (select count(*) from existing_tables where required and not exists_in_database)::bigint as required_tables_missing,
    (select count(*) from function_inventory where required_now and qtd_matches = 0)::bigint as required_functions_missing,
    (select count(*) from finance_policy_candidate_tables)::bigint as candidate_policy_tables,
    (select count(*) from finance_policy_candidate_functions where function_name not in ('mesa_cliente_persistir_agenda_financeira_admin', 'mesa_cliente_obter_agenda_financeira_cliente_safe'))::bigint as candidate_financial_functions,
    (select count(*) from sensitive_columns_inventory)::bigint as sensitive_columns_found,
    (select count(*) from information_schema.role_table_grants g join target_tables tt on tt.table_name = g.table_name where g.table_schema = 'public' and g.grantee = 'anon')::bigint as anon_direct_table_grants,
    (select count(*) from information_schema.role_table_grants g join target_tables tt on tt.table_name = g.table_name where g.table_schema = 'public' and g.grantee = 'authenticated' and g.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE'))::bigint as authenticated_direct_dml_grants_on_target_tables
),
sections as (
  select
    1 as ordem,
    '01_tables_inventory' as section,
    'tabelas necessárias e opcionais da Fase 5A' as item,
    case
      when exists (select 1 from existing_tables where required and not exists_in_database) then 'FAIL'
      else 'PASS'
    end as status,
    (
      select jsonb_agg(to_jsonb(et) order by et.required desc, et.table_name)
      from existing_tables et
    ) as detalhe

  union all

  select
    2,
    '02_rpc_and_helpers_inventory',
    'RPCs e helpers relevantes antes da 5A.2',
    case
      when exists (select 1 from function_inventory where required_now and qtd_matches = 0) then 'FAIL'
      else 'PASS'
    end,
    (
      select jsonb_agg(to_jsonb(fi) order by fi.required_now desc, fi.label)
      from function_inventory fi
    )

  union all

  select
    3,
    '03_operacoes_columns_inventory',
    'colunas reais de mesa_cliente_fluxo_operacoes; não deduzir nada fora deste inventário',
    case
      when exists (select 1 from existing_tables where table_name = 'mesa_cliente_fluxo_operacoes' and exists_in_database) then 'INFO'
      else 'FAIL'
    end,
    coalesce((select detalhe from columns_inventory where table_name = 'mesa_cliente_fluxo_operacoes'), '[]'::jsonb)

  union all

  select
    4,
    '04_financial_tables_columns_inventory',
    'colunas reais das tabelas financeiras usadas como base para a 5A',
    'INFO',
    (
      select coalesce(jsonb_object_agg(table_name, detalhe order by table_name), '{}'::jsonb)
      from columns_inventory
      where table_name in ('mesa_cliente_agendas_financeiras', 'mesa_cliente_fluxo_parcelas', 'mesa_cliente_fluxo_operacoes')
    )

  union all

  select
    5,
    '05_simulacao_context_columns_inventory',
    'colunas reais das tabelas de contexto de tenant/perfil/simulação',
    'INFO',
    (
      select coalesce(jsonb_object_agg(table_name, detalhe order by table_name), '{}'::jsonb)
      from columns_inventory
      where table_name in ('mesa_simulacoes', 'corretores', 'empreendimentos', 'empresas')
    )

  union all

  select
    6,
    '06_constraints_inventory',
    'constraints relevantes para cálculo, bloqueios, status e integridade',
    'INFO',
    (
      select coalesce(jsonb_object_agg(table_name, detalhe order by table_name), '{}'::jsonb)
      from constraints_inventory
    )

  union all

  select
    7,
    '07_custom_types_inventory',
    'enums/domínios USER-DEFINED usados pelas tabelas-alvo',
    'INFO',
    coalesce((select detalhe from custom_types_inventory), '[]'::jsonb)

  union all

  select
    8,
    '08_policies_grants_rls_inventory',
    'RLS, policies e grants das tabelas que a 5A poderá ler ou deverá proteger',
    case
      when (select anon_direct_table_grants from risk_flags) > 0 then 'WARN'
      else 'INFO'
    end,
    jsonb_build_object(
      'rls', coalesce((select detalhe from rls_inventory), '[]'::jsonb),
      'policies', coalesce((select jsonb_object_agg(table_name, detalhe order by table_name) from policies_inventory), '{}'::jsonb),
      'grants', coalesce((select jsonb_object_agg(table_name, detalhe order by table_name) from grants_inventory), '{}'::jsonb),
      'risk_flags', jsonb_build_object(
        'anon_direct_table_grants', (select anon_direct_table_grants from risk_flags),
        'authenticated_direct_dml_grants_on_target_tables', (select authenticated_direct_dml_grants_on_target_tables from risk_flags)
      )
    )

  union all

  select
    9,
    '09_indexes_inventory',
    'índices existentes que podem afetar agenda, parcelas, operações e simulação',
    'INFO',
    (
      select coalesce(jsonb_object_agg(table_name, detalhe order by table_name), '{}'::jsonb)
      from indexes_inventory
    )

  union all

  select
    10,
    '10_table_stats_readonly',
    'estimativas de linhas existentes sem executar count(*) nas tabelas de produção',
    'INFO',
    (
      select jsonb_agg(detalhe order by table_name)
      from table_stats
    )

  union all

  select
    11,
    '11_policy_and_formula_candidates',
    'candidatos de fonte oficial para política/taxa/fórmula; não inventar cálculo sem fonte',
    case
      when (select candidate_policy_tables + candidate_financial_functions from risk_flags) = 0 then 'WARN'
      else 'INFO'
    end,
    jsonb_build_object(
      'candidate_tables', coalesce((select jsonb_agg(to_jsonb(t) order by t.table_name) from finance_policy_candidate_tables t), '[]'::jsonb),
      'candidate_functions', coalesce((select jsonb_agg(to_jsonb(f) order by f.function_name, f.identity_arguments) from finance_policy_candidate_functions f), '[]'::jsonb),
      'observacao', 'A presença de candidato não autoriza fórmula. A fórmula precisa ser validada por contrato antes da migration 5A.2.'
    )

  union all

  select
    12,
    '12_sensitive_columns_inventory',
    'campos internos/sensíveis que não podem virar payload cliente-safe e devem ser tratados no admin',
    'INFO',
    coalesce((select jsonb_agg(to_jsonb(s) order by s.table_name, s.column_name) from sensitive_columns_inventory s), '[]'::jsonb)

  union all

  select
    13,
    '13_dml_guardrail_for_5a',
    'trava conceitual: 5A é dry-run e deve provar count_before = count_after',
    'INFO',
    jsonb_build_object(
      'dml_proibido_na_5a', jsonb_build_array(
        'INSERT em mesa_cliente_agendas_financeiras',
        'UPDATE em mesa_cliente_agendas_financeiras',
        'DELETE em mesa_cliente_agendas_financeiras',
        'INSERT em mesa_cliente_fluxo_parcelas',
        'UPDATE em mesa_cliente_fluxo_parcelas',
        'DELETE em mesa_cliente_fluxo_parcelas',
        'INSERT em mesa_cliente_fluxo_operacoes',
        'UPDATE em mesa_cliente_fluxo_operacoes',
        'DELETE em mesa_cliente_fluxo_operacoes'
      ),
      'tests_obrigatorios', jsonb_build_array(
        '10a_validacao_impacto_financeiro_admin_dry_run_rollback.sql',
        '10b_validacao_impacto_financeiro_admin_negativos_rollback.sql'
      ),
      'criterio', 'count_before = count_after em agendas, parcelas e operações'
    )

  union all

  select
    14,
    '14_operational_interpretation',
    'interpretação operacional para decidir se pode desenhar a migration 5A.2',
    case
      when (select required_tables_missing from risk_flags) > 0 then 'FAIL'
      when (select required_functions_missing from risk_flags) > 0 then 'FAIL'
      else 'INFO'
    end,
    jsonb_build_object(
      'required_tables_missing', (select required_tables_missing from risk_flags),
      'required_functions_missing', (select required_functions_missing from risk_flags),
      'candidate_policy_tables', (select candidate_policy_tables from risk_flags),
      'candidate_financial_functions', (select candidate_financial_functions from risk_flags),
      'sensitive_columns_found', (select sensitive_columns_found from risk_flags),
      'anon_direct_table_grants', (select anon_direct_table_grants from risk_flags),
      'authenticated_direct_dml_grants_on_target_tables', (select authenticated_direct_dml_grants_on_target_tables from risk_flags),
      'recommended_next_step', case
        when (select required_tables_missing from risk_flags) > 0 then 'BLOQUEAR: tabela obrigatória ausente.'
        when (select required_functions_missing from risk_flags) > 0 then 'BLOQUEAR: helper/RPC base obrigatória ausente.'
        else 'Preflight estrutural concluído. Antes da migration 5A.2, validar fórmula oficial, escopo do primeiro tipo de operação e gabaritos numéricos.'
      end,
      'formula_guardrail', 'Sem fonte oficial da fórmula, não implementar cálculo financeiro definitivo.'
    )

  union all

  select
    99,
    '99_end',
    'fim do preflight 5A',
    'INFO',
    jsonb_build_object(
      'instruction', 'Preflight 10 read-only concluído. Envie este resultset único completo antes de criar qualquer migration 5A.2.'
    )
)
select
  ordem,
  section,
  item,
  status,
  detalhe
from sections
order by ordem;
