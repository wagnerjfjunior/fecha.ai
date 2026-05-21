-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 7
-- 15A — Validação read-only da constraint status_operacao incluindo 'aplicada'.
--
-- Objetivo:
--   Validar que a migration da Fase 7 permitiu o estado canônico
--   status_operacao='aplicada' em mesa_cliente_fluxo_operacoes.
--
-- Regras deste teste:
--   - não cria fixture;
--   - não executa DDL;
--   - não executa DML;
--   - usa transaction read only;
--   - encerra com rollback;
--   - valida catálogo, comentário e compatibilidade dos dados existentes.

start transaction read only;

with
constraint_status as (
  select
    c.conname,
    pg_get_constraintdef(c.oid) as constraint_def,
    obj_description(c.oid, 'pg_constraint') as comentario
  from pg_constraint c
  where c.connamespace = 'public'::regnamespace
    and c.conrelid = 'public.mesa_cliente_fluxo_operacoes'::regclass
    and c.conname = 'mesa_cliente_fluxo_operacoes_status_operacao_check'
),
status_esperados(status_operacao) as (
  values
    ('simulada'),
    ('confirmada'),
    ('aplicada'),
    ('cancelada'),
    ('bloqueada')
),
status_constraint as (
  select
    s.status_operacao,
    exists (
      select 1
      from constraint_status cs
      where cs.constraint_def ilike '%' || quote_literal(s.status_operacao) || '%'
    ) as presente_na_constraint
  from status_esperados s
),
dados_incompativeis as (
  select
    o.status_operacao,
    count(*) as qtd
  from public.mesa_cliente_fluxo_operacoes o
  where o.status_operacao is not null
    and o.status_operacao not in (
      'simulada',
      'confirmada',
      'aplicada',
      'cancelada',
      'bloqueada'
    )
  group by o.status_operacao
),
resultado as (
  select
    0 as ord,
    '00_constraint_status_operacao_existe' as bloco,
    case when exists (select 1 from constraint_status) then 'PASS' else 'FAIL' end as status,
    coalesce(
      (select to_jsonb(cs) from constraint_status cs limit 1),
      jsonb_build_object('mensagem', 'Constraint mesa_cliente_fluxo_operacoes_status_operacao_check nao encontrada')
    ) as detalhe

  union all

  select
    1,
    '01_status_aplicada_presente',
    case
      when exists (
        select 1
        from status_constraint
        where status_operacao = 'aplicada'
          and presente_na_constraint
      )
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'status_operacao', 'aplicada',
      'presente_na_constraint', coalesce((
        select presente_na_constraint
        from status_constraint
        where status_operacao = 'aplicada'
      ), false)
    )

  union all

  select
    2,
    '02_status_legados_preservados',
    case
      when bool_and(presente_na_constraint)
      then 'PASS' else 'FAIL'
    end,
    jsonb_agg(
      jsonb_build_object(
        'status_operacao', status_operacao,
        'presente_na_constraint', presente_na_constraint
      )
      order by status_operacao
    )
  from status_constraint
  where status_operacao <> 'aplicada'

  union all

  select
    3,
    '03_comentario_constraint_presente',
    case
      when exists (
        select 1
        from constraint_status
        where coalesce(comentario, '') ilike '%Fase 7%'
          and coalesce(comentario, '') ilike '%aplicada%'
      )
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'comentario', (select comentario from constraint_status limit 1)
    )

  union all

  select
    4,
    '04_dados_existentes_compativeis',
    case when not exists (select 1 from dados_incompativeis) then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'incompativeis', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'status_operacao', status_operacao,
            'qtd', qtd
          )
          order by status_operacao
        )
        from dados_incompativeis
      ), '[]'::jsonb)
    )

  union all

  select
    5,
    '05_readiness_rpc_aplicacao_status',
    case
      when exists (select 1 from constraint_status)
       and exists (
         select 1
         from status_constraint
         where status_operacao = 'aplicada'
           and presente_na_constraint
       )
       and not exists (select 1 from dados_incompativeis)
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
      'status_aplicada_liberado', exists (
        select 1
        from status_constraint
        where status_operacao = 'aplicada'
          and presente_na_constraint
      ),
      'proxima_rpc_esperada', 'public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)'
    )

  union all

  select
    99,
    '99_interpretacao_operacional',
    'INFO',
    jsonb_build_object(
      'tipo', 'validacao_constraint_status_operacao_readonly',
      'ddl', false,
      'dml', false,
      'fixture', false,
      'rollback', true,
      'mensagem', '15A valida a constraint aplicada antes da RPC de aplicacao financeira. Nenhuma operacao financeira foi aplicada.'
    )
)
select bloco, status, detalhe
from resultado
order by ord;

rollback;
