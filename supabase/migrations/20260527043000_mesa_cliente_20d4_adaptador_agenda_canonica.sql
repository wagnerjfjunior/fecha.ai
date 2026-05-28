begin;

-- -----------------------------------------------------------------------------
-- MesaCliente — Fase 20D.4
-- Adaptador read-only: fluxo histórico -> agenda canônica
-- -----------------------------------------------------------------------------
-- Objetivo:
--   Criar a RPC public.mesa_cliente_montar_payload_agenda_canonica(uuid)
--   para montar payload canônico de agenda financeira a partir de
--   public.mesa_fluxo_pagamentos, sem aceitar valores financeiros vindos do
--   frontend e sem executar DML financeiro.
--
-- Correções semânticas incorporadas nesta versão:
--   - ATO + curto_prazo compõem complemento de entrada/obra.
--   - curto_prazo sem data_prevista aceita +30/+60/+90/+120... desde que
--     o número seja múltiplo de 30 e convertido por mês comercial.
--   - Parcela única/chaves pertence ao ciclo de obra e não deve ser tratada
--     como quitação do saldo devedor.
--   - O enum histórico tipo=quitacao só pode virar parcela_unica quando a
--     descrição indicar compatibilidade histórica com parcela única/chaves.
--   - tipo=quitacao com semântica de saldo/repasse/quitação real é bloqueado
--     para evitar classificação financeira incorreta.
--
-- Fora do escopo:
--   - INSERT/UPDATE/DELETE em agenda/parcela/operação financeira.
--   - Chamada automática da 4A ou 4B.
--   - Persistência de agenda.
--   - Alteração de parser, Worker, Make/n8n, frontend ou motor financeiro.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 1. Pré-requisitos defensivos
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.mesa_simulacoes') is null then
    raise exception 'Tabela public.mesa_simulacoes não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regclass('public.mesa_fluxo_pagamentos') is null then
    raise exception 'Tabela public.mesa_fluxo_pagamentos não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regprocedure('public.is_root()') is null then
    raise exception 'Função public.is_root() não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_assert_auth()') is null then
    raise exception 'Função public.mesa_cliente_assert_auth() não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_current_corretor_context()') is null then
    raise exception 'Função public.mesa_cliente_current_corretor_context() não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_can_admin_empresa(uuid)') is null then
    raise exception 'Função public.mesa_cliente_can_admin_empresa(uuid) não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_can_access_empresa(uuid)') is null then
    raise exception 'Função public.mesa_cliente_can_access_empresa(uuid) não encontrada. Migração 20D.4 abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_assert_empreendimento_empresa(uuid,uuid)') is null then
    raise exception 'Função public.mesa_cliente_assert_empreendimento_empresa(uuid,uuid) não encontrada. Migração 20D.4 abortada.';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2. RPC adaptadora read-only
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_montar_payload_agenda_canonica(
  p_simulacao_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_ctx record;
  v_sim record;
  v_is_admin boolean := false;
  v_is_owner boolean := false;
  v_qtd_origem integer := 0;
  v_qtd_adaptados integer := 0;
  v_data_ato date;
  v_fluxo_json jsonb := '[]'::jsonb;
  v_diagnostico_itens jsonb := '[]'::jsonb;
  v_datas_inferidas jsonb := '[]'::jsonb;
  v_warnings jsonb := '[]'::jsonb;
  v_curto_prazo_para_entrada integer := 0;
  v_periodica_para_mensais integer := 0;
  v_intermediaria_para_intermediarias integer := 0;
  v_quitacao_historica_para_parcela_unica_obra integer := 0;
  v_financiamento_para_financiamento integer := 0;
  v_row record;
  v_tipo text;
  v_grupo text;
  v_semantica text;
  v_descricao text;
  v_valor numeric;
  v_quantidade integer;
  v_data_vencimento date;
  v_regra_data text;
  v_meses_offset integer;
  v_dias_complemento integer;
  v_match text[];
  v_tem_empresa_divergente boolean := false;
begin
  v_uid := public.mesa_cliente_assert_auth();

  if p_simulacao_id is null then
    raise exception 'simulacao_id é obrigatório' using errcode = '22023';
  end if;

  select s.* into v_sim
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id;

  if v_sim.id is null then
    raise exception 'Simulação não encontrada' using errcode = 'P0002';
  end if;

  if v_sim.empresa_id is null then
    raise exception 'Simulação sem empresa_id' using errcode = '22023';
  end if;

  if v_sim.empreendimento_id is null then
    raise exception 'Simulação sem empreendimento_id' using errcode = '22023';
  end if;

  perform public.mesa_cliente_assert_empreendimento_empresa(v_sim.empresa_id, v_sim.empreendimento_id);

  if not public.mesa_cliente_can_access_empresa(v_sim.empresa_id) then
    raise exception 'Sem permissão para acessar a empresa da simulação' using errcode = '42501';
  end if;

  select * into v_ctx
  from public.mesa_cliente_current_corretor_context()
  limit 1;

  if not public.is_root() then
    if v_ctx.user_id is null then
      raise exception 'Usuário ativo não encontrado' using errcode = '42501';
    end if;

    if coalesce(v_ctx.ativo, false) is not true then
      raise exception 'Usuário inativo' using errcode = '42501';
    end if;

    if v_ctx.empresa_id is distinct from v_sim.empresa_id then
      raise exception 'Usuário não pertence à empresa da simulação' using errcode = '42501';
    end if;
  end if;

  v_is_admin := public.mesa_cliente_can_admin_empresa(v_sim.empresa_id);
  v_is_owner := v_ctx.corretor_id is not null
                and v_sim.corretor_id is not null
                and v_ctx.corretor_id = v_sim.corretor_id;

  if not (public.is_root() or v_is_admin or v_is_owner) then
    raise exception 'Perfil sem permissão para montar payload canônico desta simulação' using errcode = '42501';
  end if;

  select exists (
    select 1
    from public.mesa_fluxo_pagamentos f
    where f.simulacao_id = p_simulacao_id
      and f.empresa_id is distinct from v_sim.empresa_id
  ) into v_tem_empresa_divergente;

  if coalesce(v_tem_empresa_divergente, false) is true then
    raise exception 'Fluxo possui item com empresa_id divergente da simulação' using errcode = '42501';
  end if;

  select count(*)::integer into v_qtd_origem
  from public.mesa_fluxo_pagamentos f
  where f.simulacao_id = p_simulacao_id
    and f.empresa_id = v_sim.empresa_id;

  if coalesce(v_qtd_origem, 0) = 0 then
    raise exception 'Fluxo financeiro histórico vazio para a simulação' using errcode = '22023';
  end if;

  select f.data_prevista into v_data_ato
  from public.mesa_fluxo_pagamentos f
  where f.simulacao_id = p_simulacao_id
    and f.empresa_id = v_sim.empresa_id
    and f.tipo::text = 'entrada'
    and f.data_prevista is not null
  order by f.ordem, f.created_at
  limit 1;

  if v_data_ato is null then
    select min(f.data_prevista) into v_data_ato
    from public.mesa_fluxo_pagamentos f
    where f.simulacao_id = p_simulacao_id
      and f.empresa_id = v_sim.empresa_id
      and f.data_prevista is not null;
  end if;

  if v_data_ato is null then
    v_data_ato := v_sim.created_at::date;
    v_warnings := v_warnings || jsonb_build_array('data_ato_inferida_por_created_at_simulacao');
  end if;

  if v_data_ato is null then
    raise exception 'data_ato impossível de determinar' using errcode = '22023';
  end if;

  for v_row in
    select f.*
    from public.mesa_fluxo_pagamentos f
    where f.simulacao_id = p_simulacao_id
      and f.empresa_id = v_sim.empresa_id
    order by f.ordem, f.created_at
  loop
    v_tipo := v_row.tipo::text;
    v_descricao := nullif(trim(coalesce(v_row.descricao, '')), '');
    v_valor := v_row.valor;
    v_quantidade := coalesce(v_row.quantidade, 1);
    v_data_vencimento := v_row.data_prevista;
    v_regra_data := case when v_row.data_prevista is not null then 'data_prevista_historica' else null end;
    v_meses_offset := null;
    v_dias_complemento := null;
    v_match := null;
    v_semantica := null;

    if v_tipo is null or trim(v_tipo) = '' then
      raise exception 'Item de fluxo sem tipo. fluxo_pagamento_id=%', v_row.id using errcode = '22023';
    end if;

    if v_tipo = 'observacao' then
      raise exception 'Tipo observacao não pode entrar como item financeiro. fluxo_pagamento_id=%', v_row.id using errcode = '22023';
    end if;

    if v_tipo = 'quitacao' then
      if coalesce(v_descricao, '') ~* '(parcela\s*(u|ú)nica|\b(unica|única)\b|chaves?|entrega)' then
        v_grupo := 'parcela_unica';
        v_semantica := 'parcela_unica_obra_compatibilidade_historica_tipo_quitacao';
      elsif coalesce(v_descricao, '') ~* '(saldo|quita(c|ç)(a|ã)o|quitacao|repasse|financiamento)' then
        raise exception 'Tipo histórico quitacao indica saldo devedor/quitação real e não pode ser classificado como parcela única/chaves de obra. descricao=%, fluxo_pagamento_id=%', v_descricao, v_row.id
          using errcode = '22023';
      else
        raise exception 'Tipo histórico quitacao ambíguo. Informe descrição de parcela única/chaves ou trate saldo devedor em tipo financeiro próprio. descricao=%, fluxo_pagamento_id=%', v_descricao, v_row.id
          using errcode = '22023';
      end if;
    else
      v_grupo := case v_tipo
        when 'entrada' then 'entrada'
        when 'curto_prazo' then 'entrada'
        when 'periodica' then 'mensais'
        when 'intermediaria' then 'intermediarias'
        when 'financiamento' then 'financiamento'
        else null
      end;

      v_semantica := case v_tipo
        when 'entrada' then 'ato_entrada_obra'
        when 'curto_prazo' then 'complemento_entrada_obra'
        when 'periodica' then 'mensais_obra'
        when 'intermediaria' then 'intermediarias_obra'
        when 'financiamento' then 'saldo_devedor_financiamento'
        else null
      end;
    end if;

    if v_grupo is null then
      raise exception 'Tipo histórico não mapeado para agenda canônica. tipo=%, fluxo_pagamento_id=%', v_tipo, v_row.id using errcode = '22023';
    end if;

    if v_valor is null then
      raise exception 'Item financeiro sem valor. fluxo_pagamento_id=%', v_row.id using errcode = '22023';
    end if;

    if v_valor < 0 then
      raise exception 'Item financeiro com valor negativo. fluxo_pagamento_id=%', v_row.id using errcode = '22023';
    end if;

    if v_quantidade < 1 or v_quantidade > 240 then
      raise exception 'Quantidade inválida no fluxo. fluxo_pagamento_id=%, quantidade=%', v_row.id, v_quantidade using errcode = '22023';
    end if;

    if v_descricao is null then
      v_descricao := v_grupo;
    end if;

    if v_data_vencimento is null and v_tipo = 'curto_prazo' then
      v_match := regexp_match(coalesce(v_descricao, ''), '\+\s*([0-9]{2,4})', 'i');

      if v_match is not null then
        v_dias_complemento := v_match[1]::integer;
      end if;

      if v_dias_complemento is null then
        raise exception 'Data de complemento de entrada impossível de inferir. descricao=%, fluxo_pagamento_id=%', v_descricao, v_row.id
          using errcode = '22023';
      end if;

      if v_dias_complemento < 30 or v_dias_complemento > 360 or mod(v_dias_complemento, 30) <> 0 then
        raise exception 'Complemento de entrada inválido. Esperado +N dias com N múltiplo de 30 entre 30 e 360. descricao=%, dias=%, fluxo_pagamento_id=%', v_descricao, v_dias_complemento, v_row.id
          using errcode = '22023';
      end if;

      v_meses_offset := v_dias_complemento / 30;
      v_data_vencimento := (v_data_ato + make_interval(months => v_meses_offset))::date;
      v_regra_data := 'mes_comercial_+' || v_dias_complemento::text;

      v_datas_inferidas := v_datas_inferidas || jsonb_build_array(jsonb_build_object(
        'fluxo_pagamento_id', v_row.id,
        'ordem', v_row.ordem,
        'tipo', v_tipo,
        'descricao', v_descricao,
        'dias_complemento_entrada', v_dias_complemento,
        'meses_offset', v_meses_offset,
        'data_vencimento', v_data_vencimento,
        'regra', v_regra_data
      ));
    end if;

    if v_data_vencimento is null then
      raise exception 'data_vencimento impossível de determinar. tipo=%, descricao=%, fluxo_pagamento_id=%', v_tipo, v_descricao, v_row.id using errcode = '22023';
    end if;

    v_curto_prazo_para_entrada := v_curto_prazo_para_entrada + case when v_tipo = 'curto_prazo' then 1 else 0 end;
    v_periodica_para_mensais := v_periodica_para_mensais + case when v_tipo = 'periodica' then 1 else 0 end;
    v_intermediaria_para_intermediarias := v_intermediaria_para_intermediarias + case when v_tipo = 'intermediaria' then 1 else 0 end;
    v_quitacao_historica_para_parcela_unica_obra := v_quitacao_historica_para_parcela_unica_obra + case when v_tipo = 'quitacao' and v_grupo = 'parcela_unica' then 1 else 0 end;
    v_financiamento_para_financiamento := v_financiamento_para_financiamento + case when v_tipo = 'financiamento' then 1 else 0 end;

    v_fluxo_json := v_fluxo_json || jsonb_build_array(jsonb_build_object(
      'ordem', v_row.ordem,
      'grupo', v_grupo,
      'descricao', v_descricao,
      'valor', round(v_valor, 2),
      'quantidade', v_quantidade,
      'periodicidade', v_row.periodicidade,
      'data_vencimento', v_data_vencimento
    ));

    v_diagnostico_itens := v_diagnostico_itens || jsonb_build_array(jsonb_build_object(
      'fluxo_pagamento_id', v_row.id,
      'ordem', v_row.ordem,
      'tipo_original', v_tipo,
      'grupo_canonico', v_grupo,
      'semantica', v_semantica,
      'descricao', v_descricao,
      'valor', round(v_valor, 2),
      'quantidade', v_quantidade,
      'periodicidade', v_row.periodicidade,
      'data_prevista_original', v_row.data_prevista,
      'data_vencimento', v_data_vencimento,
      'regra_data', v_regra_data
    ));

    v_qtd_adaptados := v_qtd_adaptados + 1;
  end loop;

  if v_qtd_adaptados <> v_qtd_origem then
    raise exception 'Quantidade de itens adaptados diverge da origem. origem=%, adaptados=%', v_qtd_origem, v_qtd_adaptados using errcode = '22023';
  end if;

  return jsonb_build_object(
    'ok', true,
    'fase', '20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA',
    'visao', 'administrativa',
    'cliente_safe', false,
    'persistencia', false,
    'dml_financeiro', false,
    'simulacao_id', v_sim.id,
    'empresa_id', v_sim.empresa_id,
    'corretor_id', v_sim.corretor_id,
    'empreendimento_id', v_sim.empreendimento_id,
    'unidade_estoque_id', v_sim.unidade_estoque_id,
    'data_ato', v_data_ato,
    'fluxo_json', v_fluxo_json,
    'payload_tabela', jsonb_build_object(
      'empresa_id', v_sim.empresa_id,
      'empreendimento_id', v_sim.empreendimento_id,
      'unidade_estoque_id', v_sim.unidade_estoque_id,
      'origem', '20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA',
      'adaptador', true,
      'versao_adaptador', '20D.4.1',
      'fonte', 'mesa_fluxo_pagamentos'
    ),
    'diagnostico', jsonb_build_object(
      'qtd_itens_origem', v_qtd_origem,
      'qtd_itens_adaptados', v_qtd_adaptados,
      'qtd_itens_bloqueados', 0,
      'warnings', v_warnings,
      'mapeamentos_aplicados', jsonb_build_object(
        'curto_prazo_para_entrada', v_curto_prazo_para_entrada,
        'periodica_para_mensais', v_periodica_para_mensais,
        'intermediaria_para_intermediarias', v_intermediaria_para_intermediarias,
        'quitacao_historica_para_parcela_unica_obra', v_quitacao_historica_para_parcela_unica_obra,
        'financiamento_para_financiamento', v_financiamento_para_financiamento
      ),
      'datas_inferidas', v_datas_inferidas,
      'itens', v_diagnostico_itens
    )
  );
end;
$$;

comment on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) is
  'MesaCliente 20D.4.1: adaptador read-only do fluxo histórico para payload canônico. Diferencia parcela única/chaves de obra de quitação/saldo devedor real. Não executa DML financeiro e não chama 4A/4B.';

revoke all on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) from public;
revoke all on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) from anon;
grant execute on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) to authenticated;

commit;
