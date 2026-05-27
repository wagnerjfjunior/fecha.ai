begin;

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
  v_quitacao_para_parcela_unica integer := 0;
  v_financiamento_para_financiamento integer := 0;
  v_row record;
  v_tipo text;
  v_grupo text;
  v_descricao text;
  v_valor numeric;
  v_quantidade integer;
  v_data_vencimento date;
  v_regra_data text;
  v_meses_offset integer;
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

    if v_tipo is null or trim(v_tipo) = '' then
      raise exception 'Item de fluxo sem tipo. fluxo_pagamento_id=%', v_row.id using errcode = '22023';
    end if;

    v_grupo := case v_tipo
      when 'entrada' then 'entrada'
      when 'curto_prazo' then 'entrada'
      when 'periodica' then 'mensais'
      when 'intermediaria' then 'intermediarias'
      when 'quitacao' then 'parcela_unica'
      when 'financiamento' then 'financiamento'
      when 'observacao' then null
      else null
    end;

    if v_tipo = 'observacao' then
      raise exception 'Tipo observacao não pode entrar como item financeiro. fluxo_pagamento_id=%', v_row.id using errcode = '22023';
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
      v_meses_offset := case
        when coalesce(v_descricao, '') ~* '\+\s*30' then 1
        when coalesce(v_descricao, '') ~* '\+\s*60' then 2
        when coalesce(v_descricao, '') ~* '\+\s*90' then 3
        else null
      end;

      if v_meses_offset is null then
        raise exception 'Data de curto_prazo impossível de inferir. descricao=%, fluxo_pagamento_id=%', v_descricao, v_row.id using errcode = '22023';
      end if;

      v_data_vencimento := (v_data_ato + make_interval(months => v_meses_offset))::date;
      v_regra_data := 'mes_comercial_' || v_meses_offset::text;

      v_datas_inferidas := v_datas_inferidas || jsonb_build_array(jsonb_build_object(
        'fluxo_pagamento_id', v_row.id,
        'ordem', v_row.ordem,
        'tipo', v_tipo,
        'descricao', v_descricao,
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
    v_quitacao_para_parcela_unica := v_quitacao_para_parcela_unica + case when v_tipo = 'quitacao' then 1 else 0 end;
    v_financiamento_para_financiamento := v_financiamento_para_financiamento + case when v_tipo = 'financiamento' then 1 else 0 end;

    v_fluxo_json := v_fluxo_json || jsonb_build_array(jsonb_build_object(
      'ordem', v_row.ordem,
      'tipo', v_tipo,
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
      'versao_adaptador', '20D.4',
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
        'quitacao_para_parcela_unica', v_quitacao_para_parcela_unica,
        'financiamento_para_financiamento', v_financiamento_para_financiamento
      ),
      'datas_inferidas', v_datas_inferidas,
      'itens', v_diagnostico_itens
    )
  );
end;
$$;

comment on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) is
  'MesaCliente 20D: adaptador read-only do fluxo histórico para payload canônico de agenda financeira.';

revoke all on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) from public;
revoke all on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) from anon;
grant execute on function public.mesa_cliente_montar_payload_agenda_canonica(uuid) to authenticated;

commit;
