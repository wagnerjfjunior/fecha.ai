-- 08D - Fase 4B - Validação de bloqueio de substituição de agenda com operação confirmada
--
-- Objetivo:
--   Provar que a RPC canônica da Fase 4B não substitui uma agenda financeira ativa
--   quando já existe operação financeira confirmada para a mesma simulação.
--
-- Contrato validado:
--   - primeira chamada cria agenda e parcelas;
--   - fixture cria operação financeira confirmada dentro da mesma transação;
--   - segunda chamada, com payload diferente, deve ser bloqueada;
--   - agenda ativa original permanece intacta;
--   - parcelas originais não são recriadas/substituídas;
--   - nenhuma operação financeira adicional é criada pela RPC;
--   - tudo encerra com ROLLBACK.
--
-- Importante:
--   Este teste é transacional e deve ser executado manualmente no Supabase SQL Editor.
--   Não remova o ROLLBACK final.

begin;

create temp table if not exists _mc_08d_resultados (
  bloco text,
  status text,
  detalhe jsonb
) on commit drop;

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
  v_operacao_id uuid;
  v_tipo_operacao text;

  v_agendas_before integer;
  v_agendas_after integer;
  v_parcelas_before integer;
  v_parcelas_after integer;
  v_operacoes_before integer;
  v_operacoes_after integer;

  v_payload_1 jsonb;
  v_payload_2 jsonb;
  v_tabela_payload jsonb;
  v_resultado_1 jsonb;
  v_resultado_2 jsonb;

  v_agenda_id_1 uuid;
  v_agenda_id_db uuid;
  v_checksum_1 text;
  v_checksum_db text;
  v_qtd_parcelas_payload_1 integer;
  v_qtd_parcelas_db integer;
  v_valor_total_payload_1 numeric;
  v_valor_total_db numeric;
  v_agenda_status_db text;
  v_versao_db integer;

  v_error_message text;
  v_error_sqlstate text;
  v_erro_capturado boolean := false;
  v_qtd_operacoes_confirmadas integer;
  v_qtd_agendas_ativas integer;
  v_qtd_parcelas_agenda_ativa integer;
begin
  -- 1) Escolhe um contexto real ativo e autorizado.
  select
    c.user_id,
    c.empresa_id,
    c.id,
    c.role,
    coalesce(c.ativo, false),
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
    and coalesce(c.ativo, false) = true
    and (
      c.role = 'admin_global'
      or coalesce(c.is_admin_local, false) = true
      or coalesce(c.is_gestor, false) = true
      or c.role in ('gestor', 'coordenador')
    )
  order by
    case when c.role = 'admin_global' then 0 else 1 end,
    c.created_at nulls last,
    c.id
  limit 1;

  if v_user_id is null then
    insert into _mc_08d_resultados values (
      '01_fixture_transacional_contexto',
      'FAIL',
      jsonb_build_object(
        'motivo', 'Nenhum corretor ativo com perfil administrativo/gestor foi encontrado para executar o teste.',
        'orientacao', 'Crie ou identifique um usuário authenticated ativo com perfil permitido antes de rodar o 08D.'
      )
    );
    return;
  end if;

  select e.id, e.nome
    into v_empreendimento_id, v_empreendimento_nome
  from public.empreendimentos e
  where e.empresa_id = v_empresa_id
  order by e.created_at nulls last, e.id
  limit 1;

  if v_empreendimento_id is null then
    insert into _mc_08d_resultados values (
      '01_fixture_transacional_contexto',
      'FAIL',
      jsonb_build_object(
        'user_id', v_user_id,
        'empresa_id', v_empresa_id,
        'corretor_id', v_corretor_id,
        'motivo', 'Empresa do usuário não possui empreendimento compatível para fixture transacional.'
      )
    );
    return;
  end if;

  insert into public.mesa_simulacoes (
    id,
    empresa_id,
    corretor_id,
    empreendimento_id,
    cliente_nome,
    cliente_email,
    cliente_telefone,
    valor_total,
    valor_entrada,
    valor_financiamento,
    status,
    created_at,
    updated_at
  ) values (
    v_simulacao_id,
    v_empresa_id,
    v_corretor_id,
    v_empreendimento_id,
    'Fixture 08D - Operação Confirmada',
    'fixture.08d@example.invalid',
    '+5511999990008',
    1000000,
    100000,
    900000,
    'rascunho',
    now(),
    now()
  );

  perform set_config('request.jwt.claim.sub', v_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('role', 'authenticated', true);

  select count(*) into v_agendas_before
  from public.mesa_cliente_agendas_financeiras
  where simulacao_id = v_simulacao_id;

  select count(*) into v_parcelas_before
  from public.mesa_cliente_fluxo_parcelas
  where simulacao_id = v_simulacao_id;

  select count(*) into v_operacoes_before
  from public.mesa_cliente_fluxo_operacoes
  where simulacao_id = v_simulacao_id;

  insert into _mc_08d_resultados values (
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
      'simulacao_id_fixture', v_simulacao_id
    )
  );

  v_payload_1 := jsonb_build_object(
    'itens', jsonb_build_array(
      jsonb_build_object('grupo', 'entrada', 'descricao', 'Sinal ato', 'valor', 12000.50, 'parcelas', 1, 'data', '2099-05-18'),
      jsonb_build_object('grupo', 'mensais', 'descricao', 'Mensais', 'valor', 2500, 'parcelas', 3, 'mes_ano', '06/2099'),
      jsonb_build_object('grupo', 'intermediarias', 'descricao', 'Intermediária anual', 'valor', 10000, 'parcelas', 1, 'data', '2099-12-20'),
      jsonb_build_object('grupo', 'periodicidade', 'descricao', 'Periodicidade simbólica', 'valor', 0, 'parcelas', 1, 'mes_ano', '07/2099')
    )
  );

  -- Payload diferente para forçar tentativa de substituição por checksum diferente.
  v_payload_2 := jsonb_build_object(
    'itens', jsonb_build_array(
      jsonb_build_object('grupo', 'entrada', 'descricao', 'Sinal ato alterado', 'valor', 13000.50, 'parcelas', 1, 'data', '2099-05-18'),
      jsonb_build_object('grupo', 'mensais', 'descricao', 'Mensais alteradas', 'valor', 2600, 'parcelas', 3, 'mes_ano', '06/2099'),
      jsonb_build_object('grupo', 'intermediarias', 'descricao', 'Intermediária anual alterada', 'valor', 11000, 'parcelas', 1, 'data', '2099-12-20'),
      jsonb_build_object('grupo', 'periodicidade', 'descricao', 'Periodicidade simbólica', 'valor', 0, 'parcelas', 1, 'mes_ano', '07/2099')
    )
  );

  v_tabela_payload := jsonb_build_object(
    'origem', 'teste_rollback_08d',
    'observacao', 'Fixture transacional para validar bloqueio por operação confirmada'
  );

  -- 2) Primeira chamada cria a agenda ativa.
  set local role authenticated;

  v_resultado_1 := public.mesa_cliente_persistir_agenda_financeira_admin(
    v_simulacao_id,
    date '2099-05-18',
    v_payload_1,
    v_tabela_payload
  );

  reset role;

  v_agenda_id_1 := nullif(v_resultado_1 #>> '{payload,agenda_id}', '')::uuid;
  v_checksum_1 := v_resultado_1 #>> '{payload,checksum}';
  v_qtd_parcelas_payload_1 := coalesce((v_resultado_1 #>> '{payload,qtd_parcelas}')::integer, 0);
  v_valor_total_payload_1 := coalesce((v_resultado_1 #>> '{payload,valor_total_agenda}')::numeric, 0);

  insert into _mc_08d_resultados values (
    '02_primeira_chamada_criou_agenda',
    case
      when (v_resultado_1 ->> 'ok')::boolean = true
       and v_resultado_1 ->> 'fase' = '4B_PERSISTENCIA_AGENDA'
       and v_agenda_id_1 is not null
       and v_qtd_parcelas_payload_1 > 0
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'ok1', v_resultado_1 ->> 'ok',
      'fase1', v_resultado_1 ->> 'fase',
      'idempotente1', v_resultado_1 #>> '{payload,idempotente}',
      'agenda_id_payload1', v_agenda_id_1,
      'checksum_payload1', v_checksum_1,
      'qtd_parcelas_payload1', v_qtd_parcelas_payload_1,
      'valor_total_payload1', v_valor_total_payload_1
    )
  );

  -- 3) Cria uma operação financeira confirmada para a mesma simulação.
  select e.enumlabel
    into v_tipo_operacao
  from pg_enum e
  where e.enumtypid = 'public.mesa_financeira_operacao_tipo'::regtype
  order by
    case
      when e.enumlabel = 'antecipacao' then 0
      when e.enumlabel = 'postergacao' then 1
      else 2
    end,
    e.enumsortorder
  limit 1;

  if v_tipo_operacao is null then
    raise exception 'Enum public.mesa_financeira_operacao_tipo sem valores disponíveis para fixture 08D'
      using errcode = '22023';
  end if;

  execute format(
    'insert into public.mesa_cliente_fluxo_operacoes (
       empresa_id,
       simulacao_id,
       empreendimento_id,
       tipo_operacao,
       grupo_origem,
       grupo_destino,
       valor_movido,
       data_origem,
       data_destino,
       taxa_ano_pct,
       valor_base,
       desconto_calculado,
       acrescimo_calculado,
       economia_liquida,
       visivel_cliente,
       confirmado,
       confirmado_por,
       confirmado_em,
       status_operacao,
       metadata
     ) values (
       %L::uuid,
       %L::uuid,
       %L::uuid,
       %L::public.mesa_financeira_operacao_tipo,
       %L,
       %L,
       %s,
       %L::date,
       %L::date,
       %s,
       %s,
       %s,
       %s,
       %s,
       false,
       true,
       %L::uuid,
       now(),
       %L,
       %L::jsonb
     ) returning id',
    v_empresa_id,
    v_simulacao_id,
    v_empreendimento_id,
    v_tipo_operacao,
    'mensais',
    'entrada',
    '1000.00',
    '2099-06-30',
    '2099-05-18',
    '8.00',
    '1000.00',
    '10.00',
    '0.00',
    '10.00',
    v_user_id,
    'confirmada',
    jsonb_build_object(
      'fixture', '08d_operacao_confirmada_bloqueia_substituicao_agenda',
      'agenda_id', v_agenda_id_1,
      'origem', 'teste_rollback'
    )::text
  ) into v_operacao_id;

  select count(*)
    into v_qtd_operacoes_confirmadas
  from public.mesa_cliente_fluxo_operacoes o
  where o.simulacao_id = v_simulacao_id
    and o.empresa_id = v_empresa_id
    and (o.confirmado = true or o.status_operacao = 'confirmada');

  insert into _mc_08d_resultados values (
    '03_fixture_operacao_confirmada_criada',
    case
      when v_operacao_id is not null
       and v_qtd_operacoes_confirmadas = 1
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'operacao_id_fixture', v_operacao_id,
      'tipo_operacao', v_tipo_operacao,
      'qtd_operacoes_confirmadas', v_qtd_operacoes_confirmadas,
      'confirmado', true,
      'status_operacao', 'confirmada'
    )
  );

  -- 4) Segunda chamada tenta substituir agenda com checksum diferente; deve bloquear.
  begin
    set local role authenticated;

    v_resultado_2 := public.mesa_cliente_persistir_agenda_financeira_admin(
      v_simulacao_id,
      date '2099-05-18',
      v_payload_2,
      v_tabela_payload
    );

    reset role;
  exception
    when others then
      reset role;
      v_erro_capturado := true;
      v_error_message := sqlerrm;
      v_error_sqlstate := sqlstate;
  end;

  insert into _mc_08d_resultados values (
    '04_substituicao_bloqueada_por_operacao_confirmada',
    case
      when v_erro_capturado = true
       and v_error_sqlstate = '55000'
       and v_error_message ilike '%operação financeira confirmada%'
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'erro_capturado', v_erro_capturado,
      'sqlstate', v_error_sqlstate,
      'message', v_error_message,
      'resultado2_se_nao_bloqueou', v_resultado_2
    )
  );

  -- 5) Confirma que a agenda original permaneceu ativa e não foi substituída.
  select
    a.id,
    a.checksum_origem,
    a.status,
    a.versao,
    a.qtd_parcelas,
    a.valor_total_agenda
  into
    v_agenda_id_db,
    v_checksum_db,
    v_agenda_status_db,
    v_versao_db,
    v_qtd_parcelas_db,
    v_valor_total_db
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = v_simulacao_id
    and a.status = 'ativa'
  order by a.created_at desc, a.id
  limit 1;

  select count(*)
    into v_qtd_agendas_ativas
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = v_simulacao_id
    and a.status = 'ativa';

  insert into _mc_08d_resultados values (
    '05_agenda_original_permaneceu_intacta',
    case
      when v_qtd_agendas_ativas = 1
       and v_agenda_id_db = v_agenda_id_1
       and v_checksum_db = v_checksum_1
       and v_agenda_status_db = 'ativa'
       and v_versao_db = 1
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'qtd_agendas_ativas', v_qtd_agendas_ativas,
      'agenda_id_payload1', v_agenda_id_1,
      'agenda_id_db', v_agenda_id_db,
      'checksum_payload1', v_checksum_1,
      'checksum_db', v_checksum_db,
      'agenda_status_db', v_agenda_status_db,
      'versao_db', v_versao_db,
      'qtd_parcelas_db', v_qtd_parcelas_db,
      'valor_total_db', v_valor_total_db
    )
  );

  select count(*)
    into v_qtd_parcelas_agenda_ativa
  from public.mesa_cliente_fluxo_parcelas p
  where p.simulacao_id = v_simulacao_id
    and p.agenda_id = v_agenda_id_1;

  select count(*) into v_agendas_after
  from public.mesa_cliente_agendas_financeiras
  where simulacao_id = v_simulacao_id;

  select count(*) into v_parcelas_after
  from public.mesa_cliente_fluxo_parcelas
  where simulacao_id = v_simulacao_id;

  select count(*) into v_operacoes_after
  from public.mesa_cliente_fluxo_operacoes
  where simulacao_id = v_simulacao_id;

  insert into _mc_08d_resultados values (
    '06_parcelas_originais_nao_recriadas',
    case
      when v_parcelas_after = v_parcelas_before + v_qtd_parcelas_payload_1
       and v_qtd_parcelas_agenda_ativa = v_qtd_parcelas_payload_1
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'parcelas_before', v_parcelas_before,
      'parcelas_after', v_parcelas_after,
      'qtd_parcelas_payload1', v_qtd_parcelas_payload_1,
      'qtd_parcelas_agenda_ativa', v_qtd_parcelas_agenda_ativa,
      'agenda_id_ativa', v_agenda_id_1
    )
  );

  insert into _mc_08d_resultados values (
    '07_nao_criou_operacao_extra',
    case
      when v_operacoes_after = v_operacoes_before + 1
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'operacoes_before', v_operacoes_before,
      'operacoes_after', v_operacoes_after,
      'operacao_fixture_id', v_operacao_id,
      'esperado', 'apenas a operação confirmada fixture deve existir dentro da transação'
    )
  );

  insert into _mc_08d_resultados values (
    '08_contagem_final_agendas',
    case
      when v_agendas_after = v_agendas_before + 1
      then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'agendas_before', v_agendas_before,
      'agendas_after', v_agendas_after,
      'esperado', 'uma única agenda ativa criada pela primeira chamada; nenhuma substituição após operação confirmada'
    )
  );

  insert into _mc_08d_resultados values (
    '09_rollback_notice',
    'INFO',
    jsonb_build_object(
      'mensagem', 'Agenda, parcelas, operação confirmada fixture e simulação fixture foram criadas apenas dentro da transação. Tudo será encerrado com ROLLBACK.'
    )
  );
end $$;

select
  bloco,
  status,
  detalhe
from _mc_08d_resultados
order by bloco;

rollback;
