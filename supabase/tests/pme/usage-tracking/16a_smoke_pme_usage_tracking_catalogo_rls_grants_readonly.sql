-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- Teste 16A — Smoke de catálogo, RLS, grants e append-only
--
-- Objetivo:
-- - validar tabelas PME criadas;
-- - validar RLS ativo;
-- - validar funções SECURITY DEFINER com search_path fixo;
-- - validar ausência de EXECUTE para anon/public nas funções PME;
-- - validar policies mínimas;
-- - validar grants de tabela sem anon/public;
-- - validar pme_message_usage como append-only: SELECT/INSERT apenas para authenticated;
-- - não executar DDL/DML;
-- - encerrar com ROLLBACK.
--
-- Execução esperada: Supabase SQL Editor.

begin transaction read only;

with expected_tables as (
  select *
  from (values
    ('pme_message_templates', array['SELECT','INSERT','UPDATE']::text[]),
    ('pme_call_scripts', array['SELECT','INSERT','UPDATE']::text[]),
    ('pme_cadences', array['SELECT','INSERT','UPDATE']::text[]),
    ('pme_cadence_steps', array['SELECT','INSERT','UPDATE']::text[]),
    ('pme_lead_message_state', array['SELECT','INSERT','UPDATE']::text[]),
    ('pme_message_usage', array['SELECT','INSERT']::text[])
  ) v(table_name, expected_authenticated_privileges)
),

expected_functions as (
  select *
  from (values
    ('pme_can_access_empresa', 'p_empresa_id uuid', true),
    ('pme_is_empresa_admin', 'p_empresa_id uuid', true),
    ('pme_can_consume_empresa', 'p_empresa_id uuid', true),
    ('pme_set_updated_at', '', false),
    ('pme_registrar_message_usage', 'p_lead_id uuid, p_payload jsonb', true)
  ) v(proname, expected_args, should_authenticated_execute)
),

table_catalog as (
  select
    et.table_name,
    et.expected_authenticated_privileges,
    c.oid,
    (c.oid is not null) as existe,
    coalesce(c.relrowsecurity, false) as rls_ativo,
    coalesce(c.relforcerowsecurity, false) as rls_forcado,
    obj_description(c.oid, 'pg_class') as comentario
  from expected_tables et
  left join pg_class c
    on c.relname = et.table_name
   and c.relnamespace = 'public'::regnamespace
),

table_privileges_grouped as (
  select
    et.table_name,
    coalesce(
      array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text)
        filter (where tp.grantee = 'authenticated'),
      array[]::text[]
    ) as authenticated_privileges,
    coalesce(
      array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text)
        filter (where tp.grantee = 'anon'),
      array[]::text[]
    ) as anon_privileges,
    coalesce(
      array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text)
        filter (where tp.grantee = 'PUBLIC'),
      array[]::text[]
    ) as public_privileges
  from expected_tables et
  left join information_schema.table_privileges tp
    on tp.table_schema = 'public'
   and tp.table_name = et.table_name
   and tp.grantee in ('authenticated', 'anon', 'PUBLIC')
  group by et.table_name
),

func_catalog as (
  select
    ef.proname as expected_proname,
    ef.expected_args,
    ef.should_authenticated_execute,
    p.oid,
    p.proname,
    pg_get_function_identity_arguments(p.oid) as args,
    pg_get_function_result(p.oid) as result_type,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    p.proconfig as config,
    p.proacl::text as proacl,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('public', p.oid, 'EXECUTE') as public_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_execute,
    obj_description(p.oid, 'pg_proc') as comentario
  from expected_functions ef
  left join pg_proc p
    on p.proname = ef.proname
   and p.pronamespace = 'public'::regnamespace
),

policies as (
  select
    tablename,
    policyname,
    cmd,
    roles,
    qual,
    with_check
  from pg_policies
  where schemaname = 'public'
    and tablename in (select table_name from expected_tables)
),

constraints_catalog as (
  select
    conrelid::regclass::text as tabela,
    conname,
    pg_get_constraintdef(oid) as constraint_def
  from pg_constraint
  where connamespace = 'public'::regnamespace
    and conrelid in (
      'public.pme_message_templates'::regclass,
      'public.pme_call_scripts'::regclass,
      'public.pme_cadences'::regclass,
      'public.pme_cadence_steps'::regclass,
      'public.pme_lead_message_state'::regclass,
      'public.pme_message_usage'::regclass
    )
),

blocks as (
  select jsonb_build_object(
    'bloco', '00_tabelas_pme_catalogo_rls',
    'status',
      case
        when bool_and(existe = true and rls_ativo = true)
        then 'PASS'
        else 'FAIL'
      end,
    'detalhe',
      jsonb_agg(
        jsonb_build_object(
          'table_name', tc.table_name,
          'existe', tc.existe,
          'rls_ativo', tc.rls_ativo,
          'rls_forcado', tc.rls_forcado,
          'comentario_presente', tc.comentario is not null and length(trim(tc.comentario)) > 0
        )
        order by tc.table_name
      )
  ) as item
  from table_catalog tc

  union all

  select jsonb_build_object(
    'bloco', '01_funcoes_pme_catalogo_grants',
    'status',
      case
        when count(*) = 5
         and bool_and(oid is not null)
         and bool_and(security_definer = true)
         and bool_and(coalesce(config::text, '') like '%search_path=public%')
         and bool_and(anon_execute = false)
         and bool_and(public_execute = false)
         and bool_and(
           case
             when should_authenticated_execute = true
             then authenticated_execute = true
             else authenticated_execute = false
           end
         )
        then 'PASS'
        else 'FAIL'
      end,
    'detalhe',
      jsonb_agg(
        jsonb_build_object(
          'proname', expected_proname,
          'existe', oid is not null,
          'args', args,
          'expected_args', expected_args,
          'result_type', result_type,
          'security_definer', security_definer,
          'volatility', volatility,
          'config', config,
          'proacl', proacl,
          'anon_execute', anon_execute,
          'public_execute', public_execute,
          'authenticated_execute', authenticated_execute,
          'service_role_execute', service_role_execute,
          'comentario_presente', comentario is not null and length(trim(comentario)) > 0
        )
        order by expected_proname
      )
  )
  from func_catalog

  union all

  select jsonb_build_object(
    'bloco', '02_policies_pme_catalogo',
    'status',
      case
        when count(*) >= 17
         and exists (select 1 from policies where tablename = 'pme_message_usage' and cmd = 'SELECT')
         and exists (select 1 from policies where tablename = 'pme_message_usage' and cmd = 'INSERT')
         and not exists (select 1 from policies where tablename = 'pme_message_usage' and cmd in ('UPDATE', 'DELETE'))
        then 'PASS'
        else 'FAIL'
      end,
    'detalhe',
      coalesce(
        jsonb_agg(
          jsonb_build_object(
            'tablename', tablename,
            'policyname', policyname,
            'cmd', cmd,
            'roles', roles,
            'qual', qual,
            'with_check', with_check
          )
          order by tablename, policyname
        ),
        '[]'::jsonb
      )
  )
  from policies

  union all

  select jsonb_build_object(
    'bloco', '03_grants_tabelas_sem_anon_public',
    'status',
      case
        when bool_and(cardinality(anon_privileges) = 0)
         and bool_and(cardinality(public_privileges) = 0)
        then 'PASS'
        else 'FAIL'
      end,
    'detalhe',
      jsonb_agg(
        jsonb_build_object(
          'table_name', table_name,
          'anon_privileges', anon_privileges,
          'public_privileges', public_privileges
        )
        order by table_name
      )
  )
  from table_privileges_grouped

  union all

  select jsonb_build_object(
    'bloco', '04_grants_authenticated_exatos',
    'status',
      case
        when bool_and(
          authenticated_privileges <@ expected_authenticated_privileges
          and expected_authenticated_privileges <@ authenticated_privileges
        )
        then 'PASS'
        else 'FAIL'
      end,
    'detalhe',
      jsonb_agg(
        jsonb_build_object(
          'table_name', tpg.table_name,
          'expected_authenticated_privileges', et.expected_authenticated_privileges,
          'actual_authenticated_privileges', tpg.authenticated_privileges,
          'ok',
            (
              tpg.authenticated_privileges <@ et.expected_authenticated_privileges
              and et.expected_authenticated_privileges <@ tpg.authenticated_privileges
            )
        )
        order by tpg.table_name
      )
  )
  from table_privileges_grouped tpg
  join expected_tables et on et.table_name = tpg.table_name

  union all

  select jsonb_build_object(
    'bloco', '05_append_only_pme_message_usage',
    'status',
      case
        when exists (
          select 1
          from table_privileges_grouped
          where table_name = 'pme_message_usage'
            and authenticated_privileges <@ array['SELECT','INSERT']::text[]
            and array['SELECT','INSERT']::text[] <@ authenticated_privileges
        )
        and not exists (
          select 1
          from policies
          where tablename = 'pme_message_usage'
            and cmd in ('UPDATE', 'DELETE')
        )
        then 'PASS'
        else 'FAIL'
      end,
    'detalhe',
      jsonb_build_object(
        'authenticated_privileges',
          (
            select authenticated_privileges
            from table_privileges_grouped
            where table_name = 'pme_message_usage'
          ),
        'usage_policies',
          coalesce(
            (
              select jsonb_agg(
                jsonb_build_object(
                  'policyname', policyname,
                  'cmd', cmd
                )
                order by policyname
              )
              from policies
              where tablename = 'pme_message_usage'
            ),
            '[]'::jsonb
          ),
        'regra', 'pme_message_usage deve ser append-only: SELECT/INSERT apenas; sem UPDATE/DELETE.'
      )
  )

  union all

  select jsonb_build_object(
    'bloco', '06_constraints_minimas',
    'status',
      case
        when count(*) >= 20 then 'PASS'
        else 'INFO'
      end,
    'detalhe',
      coalesce(
        jsonb_agg(
          jsonb_build_object(
            'tabela', tabela,
            'conname', conname,
            'constraint_def', constraint_def
          )
          order by tabela, conname
        ),
        '[]'::jsonb
      )
  )
  from constraints_catalog

  union all

  select jsonb_build_object(
    'bloco', '99_interpretacao_operacional',
    'status', 'INFO',
    'detalhe',
      jsonb_build_object(
        'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
        'tipo', 'smoke_catalogo_rls_grants_readonly',
        'ddl', false,
        'dml', false,
        'fixture', false,
        'rollback', true,
        'mensagem', 'Smoke read-only. Nenhum dado deve ser criado, alterado ou removido.'
      )
  )
)

select jsonb_pretty(jsonb_agg(item order by item->>'bloco')) as resultado_16a_smoke_pme_usage_tracking
from blocks;

rollback;
