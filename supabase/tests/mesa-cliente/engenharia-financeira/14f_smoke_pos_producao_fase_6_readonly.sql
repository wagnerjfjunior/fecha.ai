-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- 14F — Smoke pós-produção read-only.
--
-- Objetivo:
--   Validar, em ambiente pós-merge/produção, que as RPCs da Fase 6 estão presentes,
--   com contrato de catálogo correto e, quando houver operação real elegível,
--   executar as duas RPCs em modo somente leitura.
--
-- RPCs validadas:
--   public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
--   public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
--
-- Regras obrigatórias deste smoke:
--   - não criar fixture;
--   - não executar DDL;
--   - não executar DML;
--   - usar START TRANSACTION READ ONLY;
--   - encerrar com ROLLBACK;
--   - SKIP por ausência de operação real elegível não reprova deployment.
--
-- Critério de operação real elegível:
--   - operação existente em mesa_cliente_fluxo_operacoes;
--   - operação vinculada a simulação/corretor ativo;
--   - operação com visivel_cliente=true;
--   - user_id de execução elegível encontrado por admin/gestão ou corretor dono.

start transaction read only;

with
rpc_catalogo as (
  select
    p.proname,
    p.prosecdef,
    p.provolatile,
    p.proconfig,
    p.proacl::text as proacl,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    obj_description(p.oid, 'pg_proc') as comentario
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'mesa_cliente_resumir_operacao_financeira_admin',
      'mesa_cliente_obter_resumo_operacao_cliente_safe'
    )
),
operacao_candidata as (
  select
    o.id as operacao_id,
    o.simulacao_id,
    o.agenda_id,
    o.visivel_cliente,
    o.created_at,
    s.empresa_id,
    s.corretor_id,
    c.user_id,
    c.role,
    coalesce(c.is_admin_local, false) as is_admin_local,
    coalesce(c.is_gestor, false) as is_gestor
  from public.mesa_cliente_fluxo_operacoes o
  join public.mesa_simulacoes s on s.id = o.simulacao_id
  join public.corretores c on c.id = s.corretor_id
  where coalesce(o.visivel_cliente, false) = true
    and c.user_id is not null
    and coalesce(c.ativo, true) = true
  order by o.created_at desc nulls last, o.id desc
  limit 1
),
admin_exec_context as (
  select
    coalesce(
      (
        select c.user_id
        from public.corretores c
        where c.user_id is not null
          and coalesce(c.ativo, true) = true
          and (
            c.role in ('admin_global', 'admin_local', 'gestor', 'coordenador')
            or coalesce(c.is_admin_local, false)
            or coalesce(c.is_gestor, false)
          )
          and (
            c.role = 'admin_global'
            or c.empresa_id = (select empresa_id from operacao_candidata)
          )
        order by
          case
            when c.role = 'admin_global' then 1
            when c.role = 'admin_local' then 2
            when c.role = 'gestor' then 3
            when c.role = 'coordenador' then 4
            else 5
          end,
          c.created_at desc nulls last,
          c.id
        limit 1
      ),
      (select user_id from operacao_candidata)
    ) as user_id
),
set_auth as (
  select
    case
      when (select user_id from admin_exec_context) is not null
      then set_config('request.jwt.claim.sub', (select user_id::text from admin_exec_context), true)
      else null
    end as configured_user
),
admin_payload as (
  select public.mesa_cliente_resumir_operacao_financeira_admin(
    (select operacao_id from operacao_candidata),
    jsonb_build_object('origem_smoke', 'fase_6_pos_producao_readonly')
  ) as payload
  from set_auth
  where (select operacao_id from operacao_candidata) is not null
    and (select user_id from admin_exec_context) is not null
),
cliente_payload as (
  select public.mesa_cliente_obter_resumo_operacao_cliente_safe(
    (select operacao_id from operacao_candidata),
    jsonb_build_object('origem_smoke', 'fase_6_pos_producao_readonly')
  ) as payload
  from set_auth
  where (select operacao_id from operacao_candidata) is not null
    and (select user_id from admin_exec_context) is not null
),
resultado as (
  select
    0 as ord,
    '00_contrato_rpc_catalogo' as bloco,
    case
      when (select count(*) from rpc_catalogo) = 2
       and (select bool_and(prosecdef) from rpc_catalogo)
       and (select bool_and(provolatile = 's') from rpc_catalogo)
       and (select bool_and(proconfig::text[] @> array['search_path=public, pg_temp']) from rpc_catalogo)
       and (select bool_and(authenticated_execute) from rpc_catalogo)
       and (select bool_and(not anon_execute) from rpc_catalogo)
       and (select bool_and(coalesce(comentario, '') <> '') from rpc_catalogo)
       and (select bool_and(coalesce(proacl, '') !~ '(^|,)=[^,]*X') from rpc_catalogo)
      then 'PASS' else 'FAIL'
    end as status,
    jsonb_build_object(
      'funcoes', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'proname', proname,
            'security_definer', prosecdef,
            'volatility', provolatile,
            'search_path', proconfig,
            'authenticated_execute', authenticated_execute,
            'anon_execute', anon_execute,
            'proacl', proacl,
            'comentario_presente', coalesce(comentario, '') <> ''
          )
          order by proname
        )
        from rpc_catalogo
      ), '[]'::jsonb)
    ) as detalhe

  union all

  select
    1,
    '01_operacao_real_visivel_disponivel',
    case when exists(select 1 from operacao_candidata) then 'PASS' else 'SKIP' end,
    case
      when exists(select 1 from operacao_candidata)
      then (
        select jsonb_build_object(
          'operacao_id', operacao_id,
          'simulacao_id', simulacao_id,
          'agenda_id', agenda_id,
          'empresa_id', empresa_id,
          'corretor_id', corretor_id,
          'user_id_execucao', (select user_id from admin_exec_context),
          'visivel_cliente', visivel_cliente,
          'created_at', created_at
        )
        from operacao_candidata
      )
      else jsonb_build_object(
        'mensagem', 'Sem operacao real visivel_cliente=true. Smoke mantido valido para catalogo; execucao das RPCs deve ser repetida quando houver operacao real liberada ao cliente.'
      )
    end

  union all

  select
    2,
    '02_execucao_rpc_admin_readonly_real',
    case
      when not exists(select 1 from operacao_candidata) then 'SKIP'
      when exists(select 1 from admin_payload)
       and (select payload->>'ok' from admin_payload) = 'true'
       and (select payload->>'fase' from admin_payload) = '6_RESUMOS_OPERACAO_FINANCEIRA'
       and (select payload->>'visao' from admin_payload) = 'administrativa'
       and (select payload->>'readonly' from admin_payload) = 'true'
       and (select payload->>'dml_financeiro' from admin_payload) = 'false'
       and (select payload from admin_payload) ? 'resumo_financeiro_admin'
      then 'PASS' else 'FAIL'
    end,
    case
      when exists(select 1 from admin_payload)
      then jsonb_build_object(
        'ok', (select payload->>'ok' from admin_payload),
        'fase', (select payload->>'fase' from admin_payload),
        'visao', (select payload->>'visao' from admin_payload),
        'readonly', (select payload->>'readonly' from admin_payload),
        'dml_financeiro', (select payload->>'dml_financeiro' from admin_payload),
        'top_level_keys', (select jsonb_agg(k order by k) from jsonb_object_keys((select payload from admin_payload)) as t(k))
      )
      else jsonb_build_object('mensagem', 'Execucao admin ignorada por ausencia de operacao real elegivel ou contexto auth elegivel.')
    end

  union all

  select
    3,
    '03_execucao_rpc_cliente_safe_readonly_real',
    case
      when not exists(select 1 from operacao_candidata) then 'SKIP'
      when exists(select 1 from cliente_payload)
       and (select payload->>'ok' from cliente_payload) = 'true'
       and (select payload->>'fase' from cliente_payload) = '6_RESUMOS_OPERACAO_FINANCEIRA'
       and (select payload->>'visao' from cliente_payload) = 'cliente_safe'
       and (select payload->>'cliente_safe' from cliente_payload) = 'true'
       and (select payload->>'readonly' from cliente_payload) = 'true'
       and (select payload->>'dml_financeiro' from cliente_payload) = 'false'
       and (select payload from cliente_payload) ? 'resumo_condicao'
       and (select payload from cliente_payload) ? 'status_comercial'
      then 'PASS' else 'FAIL'
    end,
    case
      when exists(select 1 from cliente_payload)
      then jsonb_build_object(
        'ok', (select payload->>'ok' from cliente_payload),
        'fase', (select payload->>'fase' from cliente_payload),
        'visao', (select payload->>'visao' from cliente_payload),
        'cliente_safe', (select payload->>'cliente_safe' from cliente_payload),
        'readonly', (select payload->>'readonly' from cliente_payload),
        'dml_financeiro', (select payload->>'dml_financeiro' from cliente_payload),
        'status_comercial', (select payload->>'status_comercial' from cliente_payload),
        'top_level_keys', (select jsonb_agg(k order by k) from jsonb_object_keys((select payload from cliente_payload)) as t(k))
      )
      else jsonb_build_object('mensagem', 'Execucao cliente-safe ignorada por ausencia de operacao real elegivel ou contexto auth elegivel.')
    end

  union all

  select
    4,
    '04_cliente_safe_sem_vazamento_real',
    case
      when not exists(select 1 from cliente_payload) then 'SKIP'
      when not (
        (select payload from cliente_payload) ?| array[
          'empresa_id',
          'tenant_id',
          'politica_id',
          'checksum_operacao',
          'metadata',
          'resumo_financeiro_admin',
          'taxa_ano_pct',
          'vpl_aplicado_pct',
          'premio_corretor_pct',
          'status_premio',
          'confirmado_por',
          'cancelado_por'
        ]
      )
      and (select payload::text from cliente_payload) !~* '(empresa_id|tenant_id|politica_id|checksum_operacao|metadata|resumo_financeiro_admin|taxa_ano_pct|vpl_aplicado_pct|premio_corretor_pct|status_premio|confirmado_por|cancelado_por|vpl|taxa|prêmio|premio|comissao|comissão)'
      then 'PASS' else 'FAIL'
    end,
    case
      when exists(select 1 from cliente_payload)
      then jsonb_build_object(
        'top_level_keys_cliente', (select jsonb_agg(k order by k) from jsonb_object_keys((select payload from cliente_payload)) as t(k)),
        'avisos_cliente', (select payload->'avisos' from cliente_payload)
      )
      else jsonb_build_object('mensagem', 'Inspecao de vazamento ignorada por ausencia de payload cliente-safe real.')
    end

  union all

  select
    99,
    '99_interpretacao_operacional',
    'INFO',
    jsonb_build_object(
      'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
      'tipo', 'smoke_pos_producao_readonly',
      'ddl', false,
      'dml', false,
      'fixture', false,
      'observacao', 'Smoke executado em transaction read only. SKIP por ausencia de operacao real elegivel nao reprova catalogo nem deployment.'
    )
)
select bloco, status, detalhe
from resultado
order by ord;

rollback;
