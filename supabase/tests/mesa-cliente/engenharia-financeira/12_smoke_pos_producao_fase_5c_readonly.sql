-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- Smoke pós-produção/read-only da confirmação e cancelamento de operação financeira.
--
-- Objetivo:
--   Validar na main/prod, sem DML e sem fixture, que a 5C está estruturalmente aplicada:
--     - colunas explícitas de cancelamento existem;
--     - RPC 5C existe com assinatura correta;
--     - grants estão restritos: anon=false / authenticated=true;
--     - tabela de operações continua com RLS ativo;
--     - constraint/status suporta simulada, confirmada, cancelada, bloqueada;
--     - documentação/migration canônica está refletida no banco;
--     - não executa confirmação/cancelamento e não altera dados.
--
-- Modo de uso:
--   Rodar no Supabase SQL Editor em produção após merge/deploy da 5C.
--
-- Segurança:
--   Este script é read-only. Não faz INSERT/UPDATE/DELETE.

with
cols_cancelamento as (
  select
    count(*) filter (where column_name = 'cancelado_por' and data_type = 'uuid') as tem_cancelado_por,
    count(*) filter (where column_name = 'cancelado_em' and data_type = 'timestamp with time zone') as tem_cancelado_em,
    count(*) filter (where column_name = 'motivo_cancelamento' and data_type = 'text') as tem_motivo_cancelamento,
    jsonb_agg(jsonb_build_object(
      'column_name', column_name,
      'data_type', data_type,
      'is_nullable', is_nullable
    ) order by column_name) filter (where column_name in ('cancelado_por','cancelado_em','motivo_cancelamento')) as detalhe
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'mesa_cliente_fluxo_operacoes'
),
rpc_5c as (
  select
    p.oid,
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_args,
    pg_get_function_result(p.oid) as function_result,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    p.proconfig as function_config,
    obj_description(p.oid, 'pg_proc') as function_comment
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'mesa_cliente_atualizar_status_operacao_financeira_admin'
    and pg_get_function_identity_arguments(p.oid) = 'p_operacao_id uuid, p_acao text, p_motivo text, p_parametros jsonb'
),
grants as (
  select
    coalesce(has_function_privilege('anon', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)', 'EXECUTE'), false) as anon_execute,
    coalesce(has_function_privilege('authenticated', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)', 'EXECUTE'), false) as authenticated_execute,
    coalesce(has_function_privilege('public', 'public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)', 'EXECUTE'), false) as public_execute
),
rls as (
  select
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as rls_forced
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'mesa_cliente_fluxo_operacoes'
),
status_constraint as (
  select
    conname,
    pg_get_constraintdef(oid) as constraint_def
  from pg_constraint
  where conrelid = 'public.mesa_cliente_fluxo_operacoes'::regclass
    and pg_get_constraintdef(oid) ilike '%status_operacao%'
),
status_suportado as (
  select
    bool_or(constraint_def ilike '%simulada%') as aceita_simulada,
    bool_or(constraint_def ilike '%confirmada%') as aceita_confirmada,
    bool_or(constraint_def ilike '%cancelada%') as aceita_cancelada,
    bool_or(constraint_def ilike '%bloqueada%') as aceita_bloqueada,
    jsonb_agg(jsonb_build_object('conname', conname, 'constraint_def', constraint_def) order by conname) as detalhe
  from status_constraint
),
comentarios_colunas as (
  select
    jsonb_object_agg(a.attname, col_description(a.attrelid, a.attnum) order by a.attname) as comentarios
  from pg_attribute a
  where a.attrelid = 'public.mesa_cliente_fluxo_operacoes'::regclass
    and a.attnum > 0
    and not a.attisdropped
    and a.attname in ('cancelado_por','cancelado_em','motivo_cancelamento')
),
operacoes_snapshot as (
  select
    count(*) as total_operacoes,
    count(*) filter (where status_operacao = 'simulada') as qtd_simulada,
    count(*) filter (where status_operacao = 'confirmada') as qtd_confirmada,
    count(*) filter (where status_operacao = 'cancelada') as qtd_cancelada,
    count(*) filter (where status_operacao = 'bloqueada') as qtd_bloqueada,
    count(*) filter (where coalesce(visivel_cliente, false) = true) as qtd_visivel_cliente,
    md5(coalesce(jsonb_agg(jsonb_build_object(
      'id', id,
      'status_operacao', status_operacao,
      'confirmado', confirmado,
      'confirmado_por', confirmado_por,
      'confirmado_em', confirmado_em,
      'cancelado_por', cancelado_por,
      'cancelado_em', cancelado_em,
      'motivo_cancelamento', motivo_cancelamento,
      'visivel_cliente', visivel_cliente,
      'checksum_operacao', checksum_operacao,
      'updated_at', updated_at
    ) order by id)::text, '[]')) as operacoes_admin_hash
  from public.mesa_cliente_fluxo_operacoes
)
select bloco, status, detalhe
from (
  select
    '01_colunas_cancelamento_existem' as bloco,
    case
      when c.tem_cancelado_por = 1
       and c.tem_cancelado_em = 1
       and c.tem_motivo_cancelamento = 1
      then 'PASS' else 'FAIL' end as status,
    jsonb_build_object(
      'tem_cancelado_por', c.tem_cancelado_por,
      'tem_cancelado_em', c.tem_cancelado_em,
      'tem_motivo_cancelamento', c.tem_motivo_cancelamento,
      'detalhe', c.detalhe
    ) as detalhe
  from cols_cancelamento c

  union all

  select
    '02_rpc_5c_existe_assinatura_correta',
    case
      when count(*) = 1
       and bool_and(function_result = 'jsonb')
       and bool_and(security_definer = true)
       and bool_and(function_config::text ilike '%search_path=public, pg_temp%')
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'qtd_rpc', count(*),
      'detalhe', coalesce(jsonb_agg(to_jsonb(rpc_5c.*)), '[]'::jsonb)
    )
  from rpc_5c

  union all

  select
    '03_grants_restritos',
    case
      when g.anon_execute = false
       and g.authenticated_execute = true
       and g.public_execute = false
      then 'PASS' else 'FAIL' end,
    to_jsonb(g)
  from grants g

  union all

  select
    '04_rls_operacoes_ativo',
    case
      when r.rls_enabled = true
      then 'PASS' else 'FAIL' end,
    to_jsonb(r)
  from rls r

  union all

  select
    '05_status_operacao_suporta_5c',
    case
      when s.aceita_simulada = true
       and s.aceita_confirmada = true
       and s.aceita_cancelada = true
       and s.aceita_bloqueada = true
      then 'PASS' else 'FAIL' end,
    to_jsonb(s)
  from status_suportado s

  union all

  select
    '06_comentarios_colunas_5c_presentes',
    case
      when coalesce(cc.comentarios->>'cancelado_por', '') ilike '%5C%'
       and coalesce(cc.comentarios->>'cancelado_em', '') ilike '%5C%'
       and coalesce(cc.comentarios->>'motivo_cancelamento', '') ilike '%5C%'
      then 'PASS' else 'FAIL' end,
    to_jsonb(cc)
  from comentarios_colunas cc

  union all

  select
    '07_snapshot_readonly_operacoes',
    'INFO',
    to_jsonb(o)
  from operacoes_snapshot o

  union all

  select
    '99_veredito_smoke_pos_producao_5c',
    case
      when (select tem_cancelado_por = 1 and tem_cancelado_em = 1 and tem_motivo_cancelamento = 1 from cols_cancelamento)
       and (select count(*) = 1 from rpc_5c)
       and (select anon_execute = false and authenticated_execute = true and public_execute = false from grants)
       and (select rls_enabled = true from rls)
       and (select aceita_simulada = true and aceita_confirmada = true and aceita_cancelada = true and aceita_bloqueada = true from status_suportado)
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'mensagem', 'Smoke pós-produção 5C read-only. Este script não executa DML nem chama a RPC de confirmação/cancelamento.',
      'fase', '5C_CONFIRMACAO_CANCELAMENTO_OPERACAO_FINANCEIRA',
      'readonly', true
    )
) r
order by bloco;
