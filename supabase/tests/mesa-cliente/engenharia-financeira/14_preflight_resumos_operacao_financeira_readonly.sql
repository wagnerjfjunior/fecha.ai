-- FECH.AI / MesaCliente
-- Fase 6 — Preflight read-only para resumos administrativos e cliente-safe de operação financeira
-- Arquivo: supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
--
-- Objetivo:
--   Validar o schema real e os riscos antes de qualquer migration/RPC da Fase 6.
--
-- Regras:
--   - Somente SELECT.
--   - Sem DDL.
--   - Sem DML.
--   - Sem fixture.
--   - Seguro para Supabase SQL Editor em produção única.
--   - Não cria função temporária.
--   - Não usa DO block.
--
-- Observação técnica:
--   Este preflight deve validar o contrato REAL pós-5D, não nomes conceituais.
--   Portanto, não espera colunas inexistentes como resultado, valor_operacao,
--   valor, numero_parcela ou total_parcelas. Os campos canônicos atuais são:
--   - operações: valor_movido, valor_base, desconto_calculado, acrescimo_calculado,
--     economia_liquida, dias_calculo, checksum_operacao, metadata etc.
--   - parcelas: valor_original, valor_atual, ordem e metadados com parcela_numero /
--     parcelas_total_item quando aplicável.

set transaction read only;

with
expected_tables as (
  select * from (values
    ('public'::text, 'mesa_cliente_agendas_financeiras'::text),
    ('public'::text, 'mesa_cliente_fluxo_parcelas'::text),
    ('public'::text, 'mesa_cliente_fluxo_operacoes'::text),
    ('public'::text, 'mesa_simulacoes'::text),
    ('public'::text, 'corretores'::text)
  ) as t(table_schema, table_name)
),
actual_tables as (
  select table_schema, table_name
  from information_schema.tables
  where table_schema = 'public'
),
table_check as (
  select
    e.table_schema,
    e.table_name,
    (a.table_name is not null) as existe
  from expected_tables e
  left join actual_tables a
    on a.table_schema = e.table_schema
   and a.table_name = e.table_name
),
expected_functions as (
  select * from (values
    ('mesa_cliente_obter_agenda_financeira_cliente_safe'::text),
    ('mesa_cliente_listar_operacoes_financeiras_admin'::text),
    ('mesa_cliente_obter_operacao_financeira_admin'::text),
    ('mesa_cliente_registrar_operacao_financeira_admin'::text),
    ('mesa_cliente_atualizar_status_operacao_financeira_admin'::text)
  ) as f(function_name)
),
actual_functions as (
  select
    p.proname,
    p.oid::regprocedure::text as regprocedure
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
),
function_check as (
  select
    e.function_name,
    bool_or(a.proname is not null) as existe,
    jsonb_agg(a.regprocedure order by a.regprocedure) filter (where a.regprocedure is not null) as assinaturas
  from expected_functions e
  left join actual_functions a on a.proname = e.function_name
  group by e.function_name
),
expected_operacoes_cols as (
  select * from (values
    ('core'::text, 'id'::text),
    ('core', 'empresa_id'),
    ('core', 'simulacao_id'),
    ('core', 'empreendimento_id'),
    ('core', 'agenda_id'),
    ('core', 'politica_id'),
    ('core', 'tipo_operacao'),
    ('core', 'status_operacao'),
    ('core', 'confirmado'),
    ('core', 'confirmado_por'),
    ('core', 'confirmado_em'),
    ('core', 'cancelado_por'),
    ('core', 'cancelado_em'),
    ('core', 'motivo_cancelamento'),
    ('core', 'parcela_origem_id'),
    ('core', 'parcela_destino_id'),
    ('calculo', 'grupo_origem'),
    ('calculo', 'grupo_destino'),
    ('calculo', 'valor_movido'),
    ('calculo', 'valor_base'),
    ('calculo', 'data_origem'),
    ('calculo', 'data_destino'),
    ('calculo', 'dias_calculo'),
    ('calculo', 'taxa_ano_pct'),
    ('calculo', 'vpl_aplicado_pct'),
    ('calculo', 'desconto_calculado'),
    ('calculo', 'acrescimo_calculado'),
    ('calculo', 'economia_liquida'),
    ('interno', 'premio_corretor_pct'),
    ('interno', 'status_premio'),
    ('seguranca', 'metadata'),
    ('seguranca', 'checksum_operacao'),
    ('seguranca', 'visivel_cliente'),
    ('auditoria', 'criado_por'),
    ('auditoria', 'created_at'),
    ('auditoria', 'updated_at')
  ) as c(grupo, column_name)
),
actual_operacoes_cols as (
  select column_name, ordinal_position, data_type, udt_name, is_nullable, column_default
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'mesa_cliente_fluxo_operacoes'
),
operacoes_col_check as (
  select
    e.grupo,
    e.column_name,
    (a.column_name is not null) as existe,
    a.ordinal_position,
    a.data_type,
    a.udt_name,
    a.is_nullable,
    a.column_default
  from expected_operacoes_cols e
  left join actual_operacoes_cols a on a.column_name = e.column_name
),
expected_parcelas_cols as (
  select * from (values
    ('core'::text, 'id'::text),
    ('core', 'agenda_id'),
    ('core', 'empresa_id'),
    ('core', 'simulacao_id'),
    ('core', 'empreendimento_id'),
    ('core', 'unidade_estoque_id'),
    ('core', 'grupo'),
    ('core', 'descricao'),
    ('calculo', 'valor_original'),
    ('calculo', 'valor_atual'),
    ('calculo', 'data_original'),
    ('calculo', 'data_atual'),
    ('calculo', 'origem_data'),
    ('calculo', 'regra_data'),
    ('calculo', 'ordem'),
    ('seguranca', 'eh_periodicidade_simbolica'),
    ('seguranca', 'pode_receber_vpl'),
    ('seguranca', 'pode_receber_antecipacao'),
    ('seguranca', 'pode_receber_postergacao'),
    ('seguranca', 'metadata'),
    ('auditoria', 'created_at'),
    ('auditoria', 'updated_at')
  ) as c(grupo, column_name)
),
actual_parcelas_cols as (
  select column_name, ordinal_position, data_type, udt_name, is_nullable, column_default
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'mesa_cliente_fluxo_parcelas'
),
parcelas_col_check as (
  select
    e.grupo,
    e.column_name,
    (a.column_name is not null) as existe,
    a.ordinal_position,
    a.data_type,
    a.udt_name,
    a.is_nullable,
    a.column_default
  from expected_parcelas_cols e
  left join actual_parcelas_cols a on a.column_name = e.column_name
),
rls_check as (
  select
    c.relname as tabela,
    c.relrowsecurity as rls_ativo,
    c.relforcerowsecurity as force_rls
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (
      'mesa_cliente_agendas_financeiras',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes',
      'mesa_simulacoes',
      'corretores'
    )
),
policy_check as (
  select
    schemaname,
    tablename,
    count(*) as qtd_policies,
    jsonb_agg(policyname order by policyname) as policies
  from pg_policies
  where schemaname = 'public'
    and tablename in (
      'mesa_cliente_agendas_financeiras',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes',
      'mesa_simulacoes',
      'corretores'
    )
  group by schemaname, tablename
),
grants_functions as (
  select
    routine_name,
    grantee,
    privilege_type
  from information_schema.routine_privileges
  where routine_schema = 'public'
    and routine_name in (
      'mesa_cliente_obter_agenda_financeira_cliente_safe',
      'mesa_cliente_listar_operacoes_financeiras_admin',
      'mesa_cliente_obter_operacao_financeira_admin',
      'mesa_cliente_registrar_operacao_financeira_admin',
      'mesa_cliente_atualizar_status_operacao_financeira_admin'
    )
),
sensitive_words as (
  select * from (values
    ('vpl'::text),
    ('premio'),
    ('comissao'),
    ('politica'),
    ('taxa'),
    ('checksum'),
    ('metadata'),
    ('payload'),
    ('impacto'),
    ('score')
  ) as s(word)
),
sensitive_columns as (
  select
    table_name,
    column_name
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name in (
      'mesa_cliente_agendas_financeiras',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
    and exists (
      select 1
      from sensitive_words s
      where lower(c.column_name) like '%' || s.word || '%'
    )
),
real_operacao_probe as (
  select
    o.id as operacao_id,
    o.simulacao_id,
    o.agenda_id,
    o.empresa_id,
    o.status_operacao,
    o.confirmado,
    o.visivel_cliente,
    o.created_at
  from public.mesa_cliente_fluxo_operacoes o
  order by o.created_at desc nulls last, o.id
  limit 1
),
counts as (
  select
    (select count(*) from public.mesa_cliente_agendas_financeiras) as qtd_agendas,
    (select count(*) from public.mesa_cliente_fluxo_parcelas) as qtd_parcelas,
    (select count(*) from public.mesa_cliente_fluxo_operacoes) as qtd_operacoes,
    (select count(*) from real_operacao_probe) as qtd_operacoes_probe
),
readiness as (
  select
    (select bool_and(existe) from table_check) as tabelas_ok,
    (select bool_and(existe) from function_check) as funcoes_dependencia_ok,
    (select bool_and(existe) from operacoes_col_check) as operacoes_cols_ok,
    (select bool_and(existe) from parcelas_col_check) as parcelas_cols_ok,
    (select bool_and(rls_ativo) from rls_check where tabela in ('mesa_cliente_agendas_financeiras','mesa_cliente_fluxo_parcelas','mesa_cliente_fluxo_operacoes')) as rls_financeiro_ok,
    (select qtd_operacoes_probe > 0 from counts) as existe_operacao_real_para_probe
)
select
  bloco,
  case
    when bloco in ('01_tabelas_obrigatorias','02_funcoes_dependencia','03_colunas_operacoes','04_colunas_parcelas')
      and detalhe->>'ok' = 'true' then 'PASS'
    when bloco in ('01_tabelas_obrigatorias','02_funcoes_dependencia','03_colunas_operacoes','04_colunas_parcelas')
      then 'FAIL'
    when bloco = '09_readiness_fase_6'
      and detalhe->>'readiness_tecnico' = 'true' then 'PASS'
    when bloco = '09_readiness_fase_6'
      then 'WARN'
    else 'INFO'
  end as status,
  detalhe
from (
  select
    '01_tabelas_obrigatorias' as bloco,
    jsonb_build_object(
      'ok', (select bool_and(existe) from table_check),
      'itens', (select jsonb_agg(to_jsonb(t) order by table_name) from table_check t)
    ) as detalhe

  union all

  select
    '02_funcoes_dependencia' as bloco,
    jsonb_build_object(
      'ok', (select bool_and(existe) from function_check),
      'itens', (select jsonb_agg(to_jsonb(f) order by function_name) from function_check f)
    ) as detalhe

  union all

  select
    '03_colunas_operacoes' as bloco,
    jsonb_build_object(
      'ok', (select bool_and(existe) from operacoes_col_check),
      'itens', (select jsonb_agg(to_jsonb(c) order by grupo, column_name) from operacoes_col_check c),
      'inventario_real', (select jsonb_agg(to_jsonb(a) order by ordinal_position) from actual_operacoes_cols a),
      'observacao', 'Contrato alinhado ao schema real pós-5D: valor_movido/valor_base/calculados no lugar de nomes conceituais como valor_operacao/resultado.'
    ) as detalhe

  union all

  select
    '04_colunas_parcelas' as bloco,
    jsonb_build_object(
      'ok', (select bool_and(existe) from parcelas_col_check),
      'itens', (select jsonb_agg(to_jsonb(c) order by grupo, column_name) from parcelas_col_check c),
      'inventario_real', (select jsonb_agg(to_jsonb(a) order by ordinal_position) from actual_parcelas_cols a),
      'observacao', 'Contrato alinhado ao schema real pós-4B/5D: valor_original/valor_atual/ordem; numeração agregada permanece em metadata quando aplicável.'
    ) as detalhe

  union all

  select
    '05_rls_financeiro' as bloco,
    jsonb_build_object(
      'itens', (select jsonb_agg(to_jsonb(r) order by tabela) from rls_check r)
    ) as detalhe

  union all

  select
    '06_policies_existentes' as bloco,
    jsonb_build_object(
      'itens', coalesce((select jsonb_agg(to_jsonb(p) order by tablename) from policy_check p), '[]'::jsonb)
    ) as detalhe

  union all

  select
    '07_grants_funcoes_dependencia' as bloco,
    jsonb_build_object(
      'itens', coalesce((select jsonb_agg(to_jsonb(g) order by routine_name, grantee) from grants_functions g), '[]'::jsonb)
    ) as detalhe

  union all

  select
    '08_campos_sensiveis_para_cliente_safe' as bloco,
    jsonb_build_object(
      'observacao', 'Campos listados aqui não devem vazar na visão cliente-safe da Fase 6.',
      'itens', coalesce((select jsonb_agg(to_jsonb(s) order by table_name, column_name) from sensitive_columns s), '[]'::jsonb)
    ) as detalhe

  union all

  select
    '09_readiness_fase_6' as bloco,
    jsonb_build_object(
      'readiness_tecnico', (
        select tabelas_ok
           and funcoes_dependencia_ok
           and operacoes_cols_ok
           and parcelas_cols_ok
           and coalesce(rls_financeiro_ok, false)
        from readiness
      ),
      'existe_operacao_real_para_probe', (select existe_operacao_real_para_probe from readiness),
      'observacao_operacao_real', case
        when (select existe_operacao_real_para_probe from readiness)
        then 'Existe ao menos uma operação financeira real para probe estrutural. Testes funcionais ainda devem criar fixtures transacionais controladas quando necessário.'
        else 'Nenhuma operação financeira real encontrada. Isso não bloqueia contrato/migration, mas smoke funcional futuro dependerá de massa real ou fixture transacional em teste.'
      end,
      'counts', (select to_jsonb(c) from counts c),
      'resumo', (select to_jsonb(r) from readiness r)
    ) as detalhe

  union all

  select
    '10_probe_operacao_real_mais_recente' as bloco,
    jsonb_build_object(
      'itens', coalesce((select jsonb_agg(to_jsonb(p)) from real_operacao_probe p), '[]'::jsonb),
      'nota', 'Probe somente leitura. Não comprova autorização por perfil; isso deve ser validado nos testes 14A+ com SET LOCAL ROLE/auth context apropriado.'
    ) as detalhe

  union all

  select
    '99_interpretacao_operacional' as bloco,
    jsonb_build_object(
      'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
      'acao_recomendada', 'Validar este resultset completo antes de criar qualquer migration/RPC da Fase 6.',
      'read_only', true,
      'ddl', false,
      'dml', false,
      'fixture', false,
      'proxima_etapa_se_pass', 'Criar migration/RPCs da Fase 6 conforme contrato aprovado.',
      'proxima_etapa_se_warn_ou_fail', 'Corrigir contrato ou dependência antes de migration. Não fazer tentativa e erro.'
    ) as detalhe
) x
order by bloco;
