-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4C
-- 09 Validação rollback — Agenda financeira cliente-safe.
--
-- Objetivo:
--   Validar a RPC public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
--   usando fixture transacional e ROLLBACK.
--
-- Correção operacional importante:
--   Este teste NÃO usa tabela temporária.
--   Este teste NÃO usa CTE recursiva.
--   Este teste NÃO chama a RPC no mesmo statement que cria fixture via data-modifying CTE.
--
-- Motivo:
--   No PostgreSQL, data-modifying CTEs de um mesmo statement compartilham snapshot.
--   A RPC chamada no mesmo statement pode não enxergar as linhas recém-inseridas nas tabelas base,
--   mesmo que os RETURNING das CTEs estejam disponíveis para o próprio statement.
--   Isso gerava falso erro P0002: Simulação não encontrada.
--
-- Estratégia atual:
--   - BEGIN;
--   - guardar contexto/IDs em settings transacionais via set_config(..., true);
--   - inserir simulação em statement separado;
--   - inserir agenda em statement separado;
--   - inserir parcelas em statement separado;
--   - chamar a RPC apenas depois, em SELECT separado;
--   - ROLLBACK.
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

-- 01. Captura contagens antes da fixture.
select
  set_config('mc09.agendas_before', (select count(*)::text from public.mesa_cliente_agendas_financeiras), true) as agendas_before,
  set_config('mc09.parcelas_before', (select count(*)::text from public.mesa_cliente_fluxo_parcelas), true) as parcelas_before,
  set_config('mc09.operacoes_before', (select count(*)::text from public.mesa_cliente_fluxo_operacoes), true) as operacoes_before;

-- 02. Resolve candidato real e guarda contexto em settings transacionais.
with candidate as (
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
)
select
  set_config('mc09.has_candidate', 'true', true) as has_candidate,
  set_config('request.jwt.claim.sub', c.user_id::text, true) as jwt_sub,
  set_config('request.jwt.claim.role', 'authenticated', true) as jwt_role,
  set_config('mc09.user_id', c.user_id::text, true) as user_id,
  set_config('mc09.empresa_id', c.empresa_id::text, true) as empresa_id,
  set_config('mc09.corretor_id', c.corretor_id::text, true) as corretor_id,
  set_config('mc09.role', c.role, true) as role,
  set_config('mc09.ativo', c.ativo::text, true) as ativo,
  set_config('mc09.is_gestor', c.is_gestor::text, true) as is_gestor,
  set_config('mc09.is_admin_local', c.is_admin_local::text, true) as is_admin_local,
  set_config('mc09.empreendimento_id', c.empreendimento_id::text, true) as empreendimento_id,
  set_config('mc09.empreendimento_nome', coalesce(c.empreendimento_nome, ''), true) as empreendimento_nome,
  set_config('mc09.simulacao_id', gen_random_uuid()::text, true) as simulacao_id,
  set_config('mc09.agenda_id', gen_random_uuid()::text, true) as agenda_id
from candidate c;

-- 03. Cria simulação fixture em statement separado para a RPC enxergar depois.
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
  current_setting('mc09.simulacao_id', true)::uuid,
  current_setting('mc09.empresa_id', true)::uuid,
  current_setting('mc09.corretor_id', true)::uuid,
  current_setting('mc09.empreendimento_id', true)::uuid,
  'Fixture 09 - Cliente Safe',
  1000000,
  100000,
  900000,
  1000000,
  'rascunho',
  now(),
  now()
where current_setting('mc09.has_candidate', true) = 'true';

-- 04. Cria agenda financeira ativa fixture em statement separado.
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
  current_setting('mc09.agenda_id', true)::uuid,
  current_setting('mc09.empresa_id', true)::uuid,
  current_setting('mc09.simulacao_id', true)::uuid,
  current_setting('mc09.empreendimento_id', true)::uuid,
  1,
  'ativa',
  'fixture_09_cliente_safe',
  md5(current_setting('mc09.simulacao_id', true) || ':fixture_09'),
  jsonb_build_object('nao_expor', 'payload_origem_sensivel'),
  jsonb_build_object('qtd_parcelas', 3, 'valor_total', 17500.50),
  jsonb_build_object('nao_expor', 'metadata_sensivel'),
  current_setting('mc09.user_id', true)::uuid,
  now(),
  now()
where current_setting('mc09.has_candidate', true) = 'true'
  and exists (
    select 1
    from public.mesa_simulacoes s
    where s.id = current_setting('mc09.simulacao_id', true)::uuid
  );

-- 05. Cria parcelas fixture em statement separado.
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
  current_setting('mc09.empresa_id', true)::uuid,
  current_setting('mc09.simulacao_id', true)::uuid,
  current_setting('mc09.empreendimento_id', true)::uuid,
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
  current_setting('mc09.user_id', true)::uuid,
  current_setting('mc09.user_id', true)::uuid,
  current_setting('mc09.agenda_id', true)::uuid,
  now(),
  now()
from (values
  (1, 'entrada'::text, 'Entrada'::text, 10000::numeric, date '2099-05-31', false, true, true, true, 'metadata_parcela_entrada'::text),
  (2, 'mensal'::text, 'Mensais'::text, 7500.50::numeric, date '2099-06-30', false, true, true, true, 'metadata_parcela_mensal'::text),
  (3, 'periodicidade'::text, 'Periodicidade simbólica'::text, 0::numeric, date '2099-07-31', true, false, false, false, 'metadata_parcela_periodicidade'::text)
) as pf(
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
where current_setting('mc09.has_candidate', true) = 'true'
  and exists (
    select 1
    from public.mesa_cliente_agendas_financeiras a
    where a.id = current_setting('mc09.agenda_id', true)::uuid
      and a.status = 'ativa'
  );

-- 06. Chama a RPC em statement separado, após a fixture existir nas tabelas base.
with
ctx as (
  select
    (current_setting('mc09.has_candidate', true) = 'true') as has_candidate,
    current_setting('mc09.user_id', true)::uuid as user_id,
    current_setting('mc09.empresa_id', true)::uuid as empresa_id,
    current_setting('mc09.corretor_id', true)::uuid as corretor_id,
    current_setting('mc09.role', true) as role,
    current_setting('mc09.ativo', true)::boolean as ativo,
    current_setting('mc09.is_gestor', true)::boolean as is_gestor,
    current_setting('mc09.is_admin_local', true)::boolean as is_admin_local,
    current_setting('mc09.empreendimento_id', true)::uuid as empreendimento_id,
    current_setting('mc09.empreendimento_nome', true) as empreendimento_nome,
    current_setting('mc09.simulacao_id', true)::uuid as simulacao_id,
    current_setting('mc09.agenda_id', true)::uuid as agenda_id,
    current_setting('mc09.agendas_before', true)::bigint as agendas_before,
    current_setting('mc09.parcelas_before', true)::bigint as parcelas_before,
    current_setting('mc09.operacoes_before', true)::bigint as operacoes_before
),
rpc_result as (
  select public.mesa_cliente_obter_agenda_financeira_cliente_safe(ctx.simulacao_id) as result
  from ctx
  where ctx.has_candidate
    and exists (
      select 1
      from public.mesa_simulacoes s
      where s.id = ctx.simulacao_id
    )
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
sensitive_found as (
  select coalesce(jsonb_agg(k.key order by k.key), '[]'::jsonb) as paths
  from forbidden_keys fk
  cross join lateral unnest(fk.keys) as k(key)
  cross join r
  where r.result is not null
    and r.result::text like '%"' || k.key || '"%'
),
resultados as (
  select
    '01_fixture_transacional_contexto'::text as bloco,
    case
      when (select has_candidate from ctx)
       and exists (select 1 from public.mesa_simulacoes s where s.id = (select simulacao_id from ctx))
       and exists (select 1 from public.mesa_cliente_agendas_financeiras a where a.id = (select agenda_id from ctx))
       and (select count(*) from public.mesa_cliente_fluxo_parcelas p where p.agenda_id = (select agenda_id from ctx)) = 3
      then 'PASS' else 'FAIL'
    end::text as status,
    jsonb_build_object(
      'user_id', (select user_id from ctx),
      'empresa_id', (select empresa_id from ctx),
      'corretor_id', (select corretor_id from ctx),
      'role', (select role from ctx),
      'ativo', (select ativo from ctx),
      'is_gestor', (select is_gestor from ctx),
      'is_admin_local', (select is_admin_local from ctx),
      'empreendimento_id', (select empreendimento_id from ctx),
      'empreendimento_nome', (select empreendimento_nome from ctx),
      'simulacao_id_fixture', (select simulacao_id from ctx),
      'agenda_id_fixture', (select agenda_id from ctx),
      'qtd_parcelas_fixture', (
        select count(*)
        from public.mesa_cliente_fluxo_parcelas p
        where p.agenda_id = (select agenda_id from ctx)
      )
    ) as detalhe

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
    case when (select result #>> '{agenda,id}' from r) = (select agenda_id::text from ctx)
       and (select result #>> '{agenda,status}' from r) = 'ativa'
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_payload', (select result #>> '{agenda,id}' from r),
      'agenda_id_fixture', (select agenda_id from ctx),
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
      'sensitive_keys_found', (select paths from sensitive_found)
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
    case when (select agendas_after from after_counts) = (select agendas_before from ctx) + 1
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agendas_before', (select agendas_before from ctx),
      'agendas_after', (select agendas_after from after_counts),
      'observacao', 'Apenas a fixture transacional da agenda deve existir antes do rollback.'
    )

  union all

  select
    '10_read_only_sem_dml_adicional_parcelas',
    case when (select parcelas_after from after_counts) = (select parcelas_before from ctx) + 3
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'parcelas_before', (select parcelas_before from ctx),
      'parcelas_after', (select parcelas_after from after_counts),
      'observacao', 'Apenas as 3 parcelas fixture devem existir antes do rollback.'
    )

  union all

  select
    '11_zero_dml_operacoes',
    case when (select operacoes_after from after_counts) = (select operacoes_before from ctx)
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'operacoes_before', (select operacoes_before from ctx),
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
