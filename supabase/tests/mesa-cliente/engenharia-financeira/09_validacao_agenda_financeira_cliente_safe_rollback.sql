-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4C
-- 09 Validação rollback — Agenda financeira cliente-safe.
--
-- Objetivo:
--   Validar a RPC public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
--   usando fixture transacional e ROLLBACK.
--
-- Este teste cria fixture mínima dentro da transação:
--   - simulação
--   - agenda financeira ativa
--   - parcelas financeiras
--
-- Não valida persistência 4B. Valida somente leitura cliente-safe 4C.
--
-- Correção operacional importante:
--   A tabela temporária de resultados é criada antes do BEGIN e sem ON COMMIT DROP.
--   Isso evita erro 42P01 no Supabase SQL Editor quando o editor trata blocos/commits
--   de forma diferente do psql tradicional.
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

-- Mantém o coletor de resultados fora da transação de fixture.
-- Não usar ON COMMIT DROP aqui: no SQL Editor isso pode derrubar a temp table antes do SELECT final.
drop table if exists pg_temp._mc_09_resultados;

create temp table _mc_09_resultados (
  bloco text not null,
  status text not null,
  detalhe jsonb not null default '{}'::jsonb
);

begin;

do $$
declare
  v_user_id uuid;
  v_empresa_id uuid;
  v_corretor_id uuid;
  v_role text;
  v_ativo boolean;
  v_is_gestor boolean;
  v_is_admin_local boolean;

  v_empreendimento_id uuid;
  v_empreendimento_nome text;

  v_simulacao_id uuid := gen_random_uuid();
  v_agenda_id uuid := gen_random_uuid();
  v_parcela_periodicidade_id uuid := gen_random_uuid();

  v_before_agendas bigint;
  v_after_agendas bigint;
  v_before_parcelas bigint;
  v_after_parcelas bigint;
  v_before_operacoes bigint;
  v_after_operacoes bigint;

  v_result jsonb;
  v_parcelas jsonb;
  v_sensitive_found jsonb;
  v_forbidden_keys text[] := array[
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
  ];
begin
  select
    c.user_id,
    c.empresa_id,
    c.id,
    coalesce(c.role, ''),
    coalesce(c.ativo, true),
    coalesce(c.is_gestor, false),
    coalesce(c.is_admin_local, false)
  into
    v_user_id,
    v_empresa_id,
    v_corretor_id,
    v_role,
    v_ativo,
    v_is_gestor,
    v_is_admin_local
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
  order by
    case when coalesce(c.role, '') = 'admin_global' then 0 else 1 end,
    c.created_at asc nulls last,
    c.id
  limit 1;

  select
    e.id,
    to_jsonb(e)->>'nome'
  into
    v_empreendimento_id,
    v_empreendimento_nome
  from public.empreendimentos e
  where e.empresa_id = v_empresa_id
  order by e.created_at asc nulls last, e.id
  limit 1;

  if v_user_id is null or v_empresa_id is null or v_corretor_id is null or v_empreendimento_id is null then
    insert into _mc_09_resultados values (
      '01_fixture_transacional_contexto',
      'FAIL',
      jsonb_build_object(
        'user_id', v_user_id,
        'empresa_id', v_empresa_id,
        'corretor_id', v_corretor_id,
        'empreendimento_id', v_empreendimento_id,
        'orientacao', 'Sem corretor ativo com user_id ou sem empreendimento da mesma empresa para fixture 4C.'
      )
    );
    return;
  end if;

  perform set_config('request.jwt.claim.sub', v_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  select count(*) into v_before_agendas
  from public.mesa_cliente_agendas_financeiras;

  select count(*) into v_before_parcelas
  from public.mesa_cliente_fluxo_parcelas;

  select count(*) into v_before_operacoes
  from public.mesa_cliente_fluxo_operacoes;

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
  ) values (
    v_simulacao_id,
    v_empresa_id,
    v_corretor_id,
    v_empreendimento_id,
    'Fixture 09 - Cliente Safe',
    1000000,
    100000,
    900000,
    1000000,
    'rascunho',
    now(),
    now()
  );

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
  ) values (
    v_agenda_id,
    v_empresa_id,
    v_simulacao_id,
    v_empreendimento_id,
    1,
    'ativa',
    'fixture_09_cliente_safe',
    md5(v_simulacao_id::text || ':fixture_09'),
    jsonb_build_object('nao_expor', 'payload_origem_sensivel'),
    jsonb_build_object('qtd_parcelas', 3, 'valor_total', 17500.50),
    jsonb_build_object('nao_expor', 'metadata_sensivel'),
    v_user_id,
    now(),
    now()
  );

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
  ) values
  (
    v_empresa_id,
    v_simulacao_id,
    v_empreendimento_id,
    'entrada',
    'Entrada',
    10000,
    10000,
    date '2099-05-31',
    date '2099-05-31',
    'tabela_comercial_mes',
    'fixture_09',
    1,
    false,
    true,
    true,
    true,
    jsonb_build_object('nao_expor', 'metadata_parcela_entrada'),
    v_user_id,
    v_user_id,
    v_agenda_id,
    now(),
    now()
  ),
  (
    v_empresa_id,
    v_simulacao_id,
    v_empreendimento_id,
    'mensal',
    'Mensais',
    7500.50,
    7500.50,
    date '2099-06-30',
    date '2099-06-30',
    'tabela_comercial_mes',
    'fixture_09',
    2,
    false,
    true,
    true,
    true,
    jsonb_build_object('nao_expor', 'metadata_parcela_mensal'),
    v_user_id,
    v_user_id,
    v_agenda_id,
    now(),
    now()
  ),
  (
    v_empresa_id,
    v_simulacao_id,
    v_empreendimento_id,
    'periodicidade',
    'Periodicidade simbólica',
    0,
    0,
    date '2099-07-31',
    date '2099-07-31',
    'tabela_comercial_mes',
    'fixture_09',
    3,
    true,
    false,
    false,
    false,
    jsonb_build_object('nao_expor', 'metadata_parcela_periodicidade'),
    v_user_id,
    v_user_id,
    v_agenda_id,
    now(),
    now()
  );

  select p.id
    into v_parcela_periodicidade_id
  from public.mesa_cliente_fluxo_parcelas p
  where p.agenda_id = v_agenda_id
    and p.grupo = 'periodicidade'
  limit 1;

  insert into _mc_09_resultados values (
    '01_fixture_transacional_contexto',
    'PASS',
    jsonb_build_object(
      'user_id', v_user_id,
      'empresa_id', v_empresa_id,
      'corretor_id', v_corretor_id,
      'role', v_role,
      'ativo', v_ativo,
      'is_gestor', v_is_gestor,
      'is_admin_local', v_is_admin_local,
      'empreendimento_id', v_empreendimento_id,
      'empreendimento_nome', v_empreendimento_nome,
      'simulacao_id_fixture', v_simulacao_id,
      'agenda_id_fixture', v_agenda_id,
      'parcela_periodicidade_id', v_parcela_periodicidade_id
    )
  );

  select public.mesa_cliente_obter_agenda_financeira_cliente_safe(v_simulacao_id)
    into v_result;

  v_parcelas := coalesce(v_result->'parcelas', '[]'::jsonb);

  insert into _mc_09_resultados values (
    '02_rpc_executou_cliente_safe',
    case when v_result->>'ok' = 'true' and v_result->>'fase' = '4C_CLIENTE_SAFE' then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'ok', v_result->>'ok',
      'fase', v_result->>'fase',
      'payload_existe', v_result is not null
    )
  );

  insert into _mc_09_resultados values (
    '03_payload_cliente_safe',
    case when v_result->>'visao' = 'cliente_safe' and v_result->>'cliente_safe' = 'true' then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'visao', v_result->>'visao',
      'cliente_safe', v_result->>'cliente_safe',
      'persistencia', v_result->>'persistencia',
      'dml_financeiro', v_result->>'dml_financeiro'
    )
  );

  insert into _mc_09_resultados values (
    '04_agenda_ativa_retornada',
    case when v_result #>> '{agenda,id}' = v_agenda_id::text and v_result #>> '{agenda,status}' = 'ativa' then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_payload', v_result #>> '{agenda,id}',
      'agenda_id_fixture', v_agenda_id,
      'agenda_status_payload', v_result #>> '{agenda,status}'
    )
  );

  insert into _mc_09_resultados values (
    '05_parcelas_cliente_safe',
    case
      when jsonb_array_length(v_parcelas) = 3
       and (v_result #>> '{totais,qtd_parcelas}')::integer = 3
       and (v_result #>> '{totais,valor_total}')::numeric = 17500.50
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'qtd_parcelas_payload', jsonb_array_length(v_parcelas),
      'qtd_parcelas_totalizador', v_result #>> '{totais,qtd_parcelas}',
      'valor_total_payload', v_result #>> '{totais,valor_total}'
    )
  );

  insert into _mc_09_resultados values (
    '06_aliases_e_derivacoes',
    case
      when exists (
        select 1
        from jsonb_array_elements(v_parcelas) p
        where p->>'descricao' = 'Mensais'
          and p->>'data_vencimento' = '2099-06-30'
          and (p->>'valor')::numeric = 7500.50
          and p->>'negociavel' = 'true'
      )
      and exists (
        select 1
        from jsonb_array_elements(v_parcelas) p
        where p->>'grupo' = 'periodicidade'
          and p->>'negociavel' = 'false'
          and p->'motivos_bloqueio' ? 'periodicidade_simbolica_nao_negociavel'
      )
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'mensal', (
        select p
        from jsonb_array_elements(v_parcelas) p
        where p->>'descricao' = 'Mensais'
        limit 1
      ),
      'periodicidade', (
        select p
        from jsonb_array_elements(v_parcelas) p
        where p->>'grupo' = 'periodicidade'
        limit 1
      )
    )
  );

  with recursive walk(path, value) as (
    select array[]::text[], v_result
    union all
    select path || key, val
    from walk,
    lateral jsonb_each(walk.value) e(key, val)
    where jsonb_typeof(walk.value) = 'object'
    union all
    select path || idx::text, val
    from walk,
    lateral jsonb_array_elements(walk.value) with ordinality a(val, idx)
    where jsonb_typeof(walk.value) = 'array'
  )
  select coalesce(jsonb_agg(array_to_string(path, '.')), '[]'::jsonb)
    into v_sensitive_found
  from walk
  where array_length(path, 1) is not null
    and path[array_length(path, 1)] = any(v_forbidden_keys);

  insert into _mc_09_resultados values (
    '07_sem_campos_sensiveis',
    case when jsonb_array_length(v_sensitive_found) = 0 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'forbidden_keys_checked', to_jsonb(v_forbidden_keys),
      'sensitive_paths_found', v_sensitive_found
    )
  );

  insert into _mc_09_resultados values (
    '08_grants_rpc_anon_bloqueado_authenticated_liberado',
    case
      when not has_function_privilege('anon', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
       and has_function_privilege('authenticated', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'anon_can_execute', has_function_privilege('anon', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE'),
      'authenticated_can_execute', has_function_privilege('authenticated', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
    )
  );

  select count(*) into v_after_agendas
  from public.mesa_cliente_agendas_financeiras;

  select count(*) into v_after_parcelas
  from public.mesa_cliente_fluxo_parcelas;

  select count(*) into v_after_operacoes
  from public.mesa_cliente_fluxo_operacoes;

  insert into _mc_09_resultados values (
    '09_read_only_sem_dml_adicional_agendas',
    case when v_after_agendas = v_before_agendas + 1 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agendas_before', v_before_agendas,
      'agendas_after', v_after_agendas,
      'observacao', 'Apenas a fixture transacional da agenda deve existir antes do rollback.'
    )
  );

  insert into _mc_09_resultados values (
    '10_read_only_sem_dml_adicional_parcelas',
    case when v_after_parcelas = v_before_parcelas + 3 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'parcelas_before', v_before_parcelas,
      'parcelas_after', v_after_parcelas,
      'observacao', 'Apenas as 3 parcelas fixture devem existir antes do rollback.'
    )
  );

  insert into _mc_09_resultados values (
    '11_zero_dml_operacoes',
    case when v_after_operacoes = v_before_operacoes then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'operacoes_before', v_before_operacoes,
      'operacoes_after', v_after_operacoes
    )
  );

  insert into _mc_09_resultados values (
    '12_rollback_notice',
    'INFO',
    jsonb_build_object(
      'mensagem', 'Simulação, agenda e parcelas fixture foram criadas apenas dentro da transação. Tudo será encerrado com ROLLBACK.'
    )
  );
exception when others then
  insert into _mc_09_resultados values (
    '00_falha_nao_tratada',
    'FAIL',
    jsonb_build_object(
      'message', sqlerrm,
      'sqlstate', sqlstate,
      'orientacao', 'Falha não tratada no teste 09 cliente-safe. Não avançar sem corrigir.'
    )
  );
end $$;

select
  bloco,
  status,
  detalhe
from _mc_09_resultados
order by bloco;

rollback;
