-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4C
-- 09 Validação rollback — Agenda financeira cliente-safe.
--
-- Objetivo:
--   Validar a RPC public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
--   usando fixture transacional e ROLLBACK.
--
-- Correção operacional:
--   Este teste NÃO usa tabela temporária.
--   O Supabase SQL Editor pode perder temp tables entre statements/blocos e gerar 42P01.
--   Para evitar isso, o coletor de resultado foi reescrito em CTE única.
--
-- Este teste cria fixture mínima dentro da transação:
--   - simulação
--   - agenda financeira ativa
--   - parcelas financeiras
--
-- Não valida persistência 4B. Valida somente leitura cliente-safe 4C.
--
-- Critérios:
--   - cliente_safe = true
--   - visao = cliente_safe
--   - sem campos sensíveis no JSON
--   - agenda ativa retornada corretamente
--   - parcelas retornadas da agenda ativa
--   - aliases corretos: data_vencimento=data_atual, valor=valor_atual
--   - negociavel derivado das flags reais
--   - anon bloqueado via grants
--   - authenticated liberado via grants
--   - zero DML em mesa_cliente_fluxo_operacoes
--   - tudo encerrado com ROLLBACK

begin;

with recursive
candidate as (
  select
    c.user_id,
    c.empresa_id,
    c.id as corretor_id,
    coalesce(c.role, '') as role,
    coalesce(c.ativo, true) as ativo,
    coalesce(c.is_gestor, false) as is_gestor,
    coalesce(c.is_admin_local, false) as is_admin_local,
    e.id as empreendimento_id,
    to_jsonb(e)->>'nome' as empreendimento_nome
  from public.corretores c
  join lateral (
    select e1.*
    from public.empreendimentos e1
    where e1.empresa_id = c.empresa_id
    order by e1.created_at asc nulls last, e1.id
    limit 1
  ) e on true
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
  order by
    case when coalesce(c.role, '') = 'admin_global' then 0 else 1 end,
    c.created_at asc nulls last,
    c.id
  limit 1
),
ids as (
  select
    gen_random_uuid() as simulacao_id,
    gen_random_uuid() as agenda_id
),
auth_ctx as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true) as sub_set,
    set_config('request.jwt.claim.role', 'authenticated', true) as role_set
  from candidate c
),
before_counts as (
  select
    (select count(*) from public.mesa_cliente_agendas_financeiras)::bigint as agendas_before,
    (select count(*) from public.mesa_cliente_fluxo_parcelas)::bigint as parcelas_before,
    (select count(*) from public.mesa_cliente_fluxo_operacoes)::bigint as operacoes_before
),
ins_simulacao as (
  insert into public.mesa_simulacoes (
    id,
    empresa_id,
    corretor_id,
    empreendimento_id,
    cliente_nome,
    valor_total,
    entrada,
    financiamento,
    valor_final,
    status,
    created_at,
    updated_at
  )
  select
    i.simulacao_id,
    c.empresa_id,
    c.corretor_id,
    c.empreendimento_id,
    'Fixture 09 - Cliente Safe',
    1000000,
    100000,
    900000,
    1000000,
    'rascunho',
    now(),
    now()
  from candidate c
  cross join ids i
  cross join auth_ctx a
  returning id
),
ins_agenda as (
  insert into public.mesa_cliente_agendas_financeiras (
    id,
    empresa_id,
    simulacao_id,
    empreendimento_id,
    versao,
    status,
    origem,
    checksum,
    payload_origem,
    totais,
    metadata,
    criado_por,
    created_at,
    updated_at
  )
  select
    i.agenda_id,
    c.empresa_id,
    i.simulacao_id,
    c.empreendimento_id,
    1,
    'ativa',
    'fixture_09_cliente_safe',
    md5(i.simulacao_id::text || ':fixture_09'),
    jsonb_build_object('nao_expor', 'payload_origem_sensivel'),
    jsonb_build_object('qtd_parcelas', 3, 'valor_total', 17500.50),
    jsonb_build_object('nao_expor', 'metadata_sensivel'),
    c.user_id,
    now(),
    now()
  from candidate c
  cross join ids i
  join ins_simulacao s on s.id = i.simulacao_id
  returning id
),
parcelas_fixture as (
  select *
  from (values
    (1, 'entrada'::text, 'Entrada'::text, 10000::numeric, date '2099-05-31', false, true, true, true, 'metadata_parcela_entrada'::text),
    (2, 'mensal'::text, 'Mensais'::text, 7500.50::numeric, date '2099-06-30', false, true, true, true, 'metadata_parcela_mensal'::text),
    (3, 'periodicidade'::text, 'Periodicidade simbólica'::text, 0::numeric, date '2099-07-31', true, false, false, false, 'metadata_parcela_periodicidade'::text)
  ) as v(
    ordem,
    grupo,
    descricao,
    valor,
    data_ref,
    eh_periodicidade_simbolica,
    pode_receber_vpl,
    pode_receber_antecipacao,
    pode_receber_postergacao,
    metadata_label
  )
),
ins_parcelas as (
  insert into public.mesa_cliente_fluxo_parcelas (
    empresa_id,
    simulacao_id,
    empreendimento_id,
    grupo,
    descricao,
    valor_original,
    valor_atual,
    data_original,
    data_atual,
    origem_data,
    regra_data,
    ordem,
    eh_periodicidade_simbolica,
    pode_receber_vpl,
    pode_receber_antecipacao,
    pode_receber_postergacao,
    metadata,
    criado_por,
    atualizado_por,
    agenda_id,
    created_at,
    updated_at
  )
  select
    c.empresa_id,
    i.simulacao_id,
    c.empreendimento_id,
    pf.grupo,
    pf.descricao,
    pf.valor,
    pf.valor,
    pf.data_ref,
    pf.data_ref,
    'tabela_comercial_mes'::public.mesa_financeira_origem_data,
    'fixture_09',
    pf.ordem,
    pf.eh_periodicidade_simbolica,
    pf.pode_receber_vpl,
    pf.pode_receber_antecipacao,
    pf.pode_receber_postergacao,
    jsonb_build_object('nao_expor', pf.metadata_label),
    c.user_id,
    c.user_id,
    i.agenda_id,
    now(),
    now()
  from candidate c
  cross join ids i
  join ins_agenda a on a.id = i.agenda_id
  cross join parcelas_fixture pf
  returning id, grupo
),
rpc_result as (
  select public.mesa_cliente_obter_agenda_financeira_cliente_safe(i.simulacao_id) as result
  from ids i
  where exists (select 1 from ins_parcelas)
),
r as (
  select (select result from rpc_result limit 1) as result
),
parcelas_payload as (
  select coalesce((select result->'parcelas' from r), '[]'::jsonb) as parcelas
),
after_counts as (
  select
    (select count(*) from public.mesa_cliente_agendas_financeiras)::bigint as agendas_after,
    (select count(*) from public.mesa_cliente_fluxo_parcelas)::bigint as parcelas_after,
    (select count(*) from public.mesa_cliente_fluxo_operacoes)::bigint as operacoes_after
),
forbidden_keys as (
  select array[
    'checksum',
    'metadata',
    'payload_origem',
    'criado_por',
    'atualizado_por',
    'confirmado_por',
    'cancelado_por',
    'pode_receber_vpl',
    'vpl_aplicado_pct',
    'premio_corretor_pct',
    'status_premio',
    'politica_id',
    'taxa_ano_pct',
    'desconto_calculado',
    'acrescimo_calculado',
    'economia_liquida'
  ]::text[] as keys
),
walk(path, value) as (
  select array[]::text[], (select result from r)
  where (select result from r) is not null

  union all

  select path || e.key, e.value
  from walk
  cross join lateral jsonb_each(walk.value) e(key, value)
  where jsonb_typeof(walk.value) = 'object'

  union all

  select path || a.idx::text, a.value
  from walk
  cross join lateral jsonb_array_elements(walk.value) with ordinality a(value, idx)
  where jsonb_typeof(walk.value) = 'array'
),
sensitive_found as (
  select coalesce(jsonb_agg(array_to_string(path, '.')), '[]'::jsonb) as paths
  from walk
  cross join forbidden_keys fk
  where array_length(path, 1) is not null
    and path[array_length(path, 1)] = any(fk.keys)
),
resultados as (
  select
    '01_fixture_transacional_contexto'::text as bloco,
    case when exists (select 1 from candidate) then 'PASS' else 'FAIL' end::text as status,
    coalesce((
      select jsonb_build_object(
        'user_id', c.user_id,
        'empresa_id', c.empresa_id,
        'corretor_id', c.corretor_id,
        'role', c.role,
        'ativo', c.ativo,
        'is_gestor', c.is_gestor,
        'is_admin_local', c.is_admin_local,
        'empreendimento_id', c.empreendimento_id,
        'empreendimento_nome', c.empreendimento_nome,
        'simulacao_id_fixture', i.simulacao_id,
        'agenda_id_fixture', i.agenda_id,
        'qtd_parcelas_fixture', (select count(*) from ins_parcelas)
      )
      from candidate c cross join ids i
      limit 1
    ), jsonb_build_object(
      'orientacao', 'Sem corretor ativo com user_id ou sem empreendimento da mesma empresa para fixture 4C.'
    )) as detalhe

  union all

  select
    '02_rpc_executou_cliente_safe',
    case when (select result->>'ok' from r) = 'true'
       and (select result->>'fase' from r) = '4C_CLIENTE_SAFE'
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'ok', (select result->>'ok' from r),
      'fase', (select result->>'fase' from r),
      'payload_existe', (select result from r) is not null
    )

  union all

  select
    '03_payload_cliente_safe',
    case when (select result->>'visao' from r) = 'cliente_safe'
       and (select result->>'cliente_safe' from r) = 'true'
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'visao', (select result->>'visao' from r),
      'cliente_safe', (select result->>'cliente_safe' from r),
      'persistencia', (select result->>'persistencia' from r),
      'dml_financeiro', (select result->>'dml_financeiro' from r)
    )

  union all

  select
    '04_agenda_ativa_retornada',
    case when (select result #>> '{agenda,id}' from r) = (select agenda_id::text from ids)
       and (select result #>> '{agenda,status}' from r) = 'ativa'
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_payload', (select result #>> '{agenda,id}' from r),
      'agenda_id_fixture', (select agenda_id from ids),
      'agenda_status_payload', (select result #>> '{agenda,status}' from r)
    )

  union all

  select
    '05_parcelas_cliente_safe',
    case when jsonb_array_length((select parcelas from parcelas_payload)) = 3
       and ((select result #>> '{totais,qtd_parcelas}' from r)::integer = 3)
       and ((select result #>> '{totais,valor_total}' from r)::numeric = 17500.50)
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'qtd_parcelas_payload', jsonb_array_length((select parcelas from parcelas_payload)),
      'qtd_parcelas_totalizador', (select result #>> '{totais,qtd_parcelas}' from r),
      'valor_total_payload', (select result #>> '{totais,valor_total}' from r)
    )

  union all

  select
    '06_aliases_e_derivacoes',
    case
      when exists (
        select 1
        from jsonb_array_elements((select parcelas from parcelas_payload)) p
        where p->>'descricao' = 'Mensais'
          and p->>'data_vencimento' = '2099-06-30'
          and (p->>'valor')::numeric = 7500.50
          and p->>'negociavel' = 'true'
      )
      and exists (
        select 1
        from jsonb_array_elements((select parcelas from parcelas_payload)) p
        where p->>'grupo' = 'periodicidade'
          and p->>'negociavel' = 'false'
          and p->'motivos_bloqueio' ? 'periodicidade_simbolica_nao_negociavel'
      )
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'mensal', (
        select p
        from jsonb_array_elements((select parcelas from parcelas_payload)) p
        where p->>'descricao' = 'Mensais'
        limit 1
      ),
      'periodicidade', (
        select p
        from jsonb_array_elements((select parcelas from parcelas_payload)) p
        where p->>'grupo' = 'periodicidade'
        limit 1
      )
    )

  union all

  select
    '07_sem_campos_sensiveis',
    case when jsonb_array_length((select paths from sensitive_found)) = 0 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'forbidden_keys_checked', to_jsonb((select keys from forbidden_keys)),
      'sensitive_paths_found', (select paths from sensitive_found)
    )

  union all

  select
    '08_grants_rpc_anon_bloqueado_authenticated_liberado',
    case
      when not has_function_privilege('anon', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
       and has_function_privilege('authenticated', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'anon_can_execute', has_function_privilege('anon', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE'),
      'authenticated_can_execute', has_function_privilege('authenticated', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
    )

  union all

  select
    '09_read_only_sem_dml_adicional_agendas',
    case when (select agendas_after from after_counts) = (select agendas_before from before_counts) + 1
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agendas_before', (select agendas_before from before_counts),
      'agendas_after', (select agendas_after from after_counts),
      'observacao', 'Apenas a fixture transacional da agenda deve existir antes do rollback.'
    )

  union all

  select
    '10_read_only_sem_dml_adicional_parcelas',
    case when (select parcelas_after from after_counts) = (select parcelas_before from before_counts) + 3
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'parcelas_before', (select parcelas_before from before_counts),
      'parcelas_after', (select parcelas_after from after_counts),
      'observacao', 'Apenas as 3 parcelas fixture devem existir antes do rollback.'
    )

  union all

  select
    '11_zero_dml_operacoes',
    case when (select operacoes_after from after_counts) = (select operacoes_before from before_counts)
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'operacoes_before', (select operacoes_before from before_counts),
      'operacoes_after', (select operacoes_after from after_counts)
    )

  union all

  select
    '12_rollback_notice',
    'INFO',
    jsonb_build_object(
      'mensagem', 'Simulação, agenda e parcelas fixture foram criadas apenas dentro da transação. Tudo será encerrado com ROLLBACK.'
    )
)
select
  bloco,
  status,
  detalhe
from resultados
order by bloco;

rollback;
