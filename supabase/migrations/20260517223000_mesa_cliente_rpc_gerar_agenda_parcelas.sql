-- MesaCliente Engenharia Financeira — Fase 4A: RPC gerar agenda de parcelas
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Criar a agenda financeira datada da simulação no banco, de forma soberana,
--   idempotente e segura por tenant/empresa.
--
-- Escopo:
--   - Gera/recria registros em mesa_cliente_fluxo_parcelas.
--   - Não cria operação financeira.
--   - Não confirma/cancela operação.
--   - Não calcula VPL/prêmio/comissão.
--   - Não mexe em frontend, parser, Worker, Make/n8n ou motor financeiro atual.
--
-- Segurança:
--   - SECURITY DEFINER.
--   - search_path fixo.
--   - auth.uid() obrigatório via mesa_cliente_assert_auth().
--   - empresa/tenant resolvido pela simulação e contexto do usuário.
--   - EXECUTE somente para authenticated.
--   - anon bloqueado.
--
-- Payload aceito:
--   Objeto com chave "parcelas" ou array direto.
--
--   {
--     "parcelas": [
--       {
--         "grupo": "entrada" | "ato" | "mensais" | "anuais" |
--                  "intermediarias" | "chaves" | "parcela_unica" |
--                  "financiamento" | "periodicidade",
--         "descricao": "Ato",
--         "valor": 50000,
--         "data_oficial": "2026-05-17",
--         "data_comercial": "2026-05-17",
--         "mes_ano": "2026-06",
--         "data_original": "2026-05-17",
--         "data_atual": "2026-05-17",
--         "eh_periodicidade_simbolica": false,
--         "ordem": 1
--       }
--     ],
--     "regras_cabecalho": {
--       "chaves_dias_antes_financiamento": 60,
--       "data_financiamento": "2028-09-30"
--     }
--   }

begin;

create or replace function public.gerar_mesa_cliente_agenda_parcelas(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_ctx_user_id uuid;
  v_ctx_corretor_id uuid;
  v_ctx_empresa_id uuid;
  v_ctx_role text;
  v_ctx_is_admin_local boolean;
  v_ctx_is_gestor boolean;
  v_ctx_ativo boolean;

  v_empresa_id uuid;
  v_empreendimento_id uuid;
  v_unidade_estoque_id uuid;

  v_sim_sql text;
  v_has_unidade_col boolean;
  v_can_access boolean;
  v_is_root boolean;
  v_has_confirmed_ops boolean := false;
  v_confirmed_sql text;

  v_parcelas jsonb;
  v_regras jsonb;
  v_item jsonb;
  v_idx integer := 0;
  v_qtd_periodicidades integer := 0;
  v_total_original numeric := 0;
  v_total_atual numeric := 0;

  v_grupo_input text;
  v_grupo text;
  v_descricao text;
  v_valor_original numeric;
  v_valor_atual numeric;
  v_data_original date;
  v_data_atual date;
  v_origem_data text;
  v_regra_data text;
  v_ordem integer;
  v_periodicidade boolean;
  v_pode_vpl boolean;
  v_pode_antecipacao boolean;
  v_pode_postergacao boolean;
  v_metadata jsonb;
  v_parcela_id uuid;
  v_insert_sql text;

  v_mes_ano text;
  v_mes_base date;
  v_ultimo_dia_mes date;
  v_dia_ato integer;
  v_dia_aplicado integer;
  v_data_financiamento date;
  v_chaves_dias integer;
  v_sensitive_keys text[] := array['vpl','premio','premio_corretor','comissao','taxa_interna','politica','politica_id'];
begin
  v_uid := public.mesa_cliente_assert_auth();
  v_is_root := public.is_root();

  if p_simulacao_id is null then
    raise exception 'simulacao_id é obrigatório'
      using errcode = '22023';
  end if;

  if p_data_ato is null then
    raise exception 'data_ato é obrigatória'
      using errcode = '22023';
  end if;

  if p_fluxo_json is null then
    raise exception 'fluxo_json é obrigatório'
      using errcode = '22023';
  end if;

  select
    c.user_id,
    c.corretor_id,
    c.empresa_id,
    c.role,
    c.is_admin_local,
    c.is_gestor,
    c.ativo
  into
    v_ctx_user_id,
    v_ctx_corretor_id,
    v_ctx_empresa_id,
    v_ctx_role,
    v_ctx_is_admin_local,
    v_ctx_is_gestor,
    v_ctx_ativo
  from public.mesa_cliente_current_corretor_context() c
  limit 1;

  if not v_is_root then
    if v_ctx_user_id is null then
      raise exception 'Contexto do usuário não encontrado'
        using errcode = '28000';
    end if;

    if coalesce(v_ctx_ativo, false) is false then
      raise exception 'Usuário inativo'
        using errcode = '42501';
    end if;
  end if;

  v_has_unidade_col := exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'mesa_simulacoes'
      and column_name = 'unidade_estoque_id'
  );

  v_sim_sql := format(
    'select s.empresa_id, s.empreendimento_id, %s
       from public.mesa_simulacoes s
      where s.id = $1',
    case
      when v_has_unidade_col then 's.unidade_estoque_id'
      else 'null::uuid'
    end
  );

  execute v_sim_sql
    into v_empresa_id, v_empreendimento_id, v_unidade_estoque_id
    using p_simulacao_id;

  if v_empresa_id is null or v_empreendimento_id is null then
    raise exception 'Simulação não encontrada ou sem vínculo financeiro obrigatório'
      using errcode = 'P0002';
  end if;

  if not v_is_root and v_ctx_empresa_id is distinct from v_empresa_id then
    raise exception 'Simulação não pertence à empresa do usuário'
      using errcode = '42501';
  end if;

  v_can_access := public.mesa_cliente_can_access_empresa(v_empresa_id);

  if not coalesce(v_can_access, false) then
    raise exception 'Sem permissão para gerar agenda desta empresa'
      using errcode = '42501';
  end if;

  perform public.mesa_cliente_assert_empreendimento_empresa(v_empresa_id, v_empreendimento_id);

  if jsonb_typeof(p_fluxo_json) = 'array' then
    v_parcelas := p_fluxo_json;
    v_regras := '{}'::jsonb;
  elsif jsonb_typeof(p_fluxo_json) = 'object'
        and jsonb_typeof(p_fluxo_json->'parcelas') = 'array' then
    v_parcelas := p_fluxo_json->'parcelas';
    v_regras := coalesce(p_fluxo_json->'regras_cabecalho', '{}'::jsonb);
  else
    raise exception 'fluxo_json deve ser array ou objeto com chave parcelas[]'
      using errcode = '22023';
  end if;

  if jsonb_array_length(v_parcelas) = 0 then
    raise exception 'parcelas não pode ser vazio'
      using errcode = '22023';
  end if;

  if jsonb_array_length(v_parcelas) > 500 then
    raise exception 'limite máximo de 500 parcelas por agenda'
      using errcode = '22023';
  end if;

  if to_regclass('public.mesa_cliente_fluxo_operacoes') is not null then
    v_confirmed_sql := 'select exists (
      select 1
        from public.mesa_cliente_fluxo_operacoes o
       where o.empresa_id = $1
         and o.simulacao_id = $2';

    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'mesa_cliente_fluxo_operacoes'
        and column_name = 'confirmado'
    ) then
      v_confirmed_sql := v_confirmed_sql || ' and coalesce(o.confirmado, false) is true';
    elsif exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'mesa_cliente_fluxo_operacoes'
        and column_name = 'status_operacao'
    ) then
      v_confirmed_sql := v_confirmed_sql || ' and o.status_operacao::text in (''confirmado'',''aprovado'',''finalizado'')';
    else
      v_confirmed_sql := v_confirmed_sql || ' and false';
    end if;

    v_confirmed_sql := v_confirmed_sql || ')';

    execute v_confirmed_sql
      into v_has_confirmed_ops
      using v_empresa_id, p_simulacao_id;
  end if;

  if coalesce(v_has_confirmed_ops, false) then
    raise exception 'Agenda não pode ser recriada: existe operação financeira confirmada para a simulação'
      using errcode = '23514';
  end if;

  -- Idempotência da Fase 4A: recria a agenda da mesma simulação/empresa.
  delete from public.mesa_cliente_fluxo_parcelas fp
   where fp.empresa_id = v_empresa_id
     and fp.simulacao_id = p_simulacao_id;

  for v_item in select value from jsonb_array_elements(v_parcelas)
  loop
    v_idx := v_idx + 1;

    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'Parcela % deve ser objeto JSON', v_idx
        using errcode = '22023';
    end if;

    v_grupo_input := lower(nullif(coalesce(v_item->>'grupo', v_item->>'tipo', v_item->>'tipo_parcela'), ''));
    v_grupo := case when v_grupo_input = 'ato' then 'entrada' else v_grupo_input end;
    v_descricao := coalesce(nullif(v_item->>'descricao', ''), format('Parcela %s', v_idx));
    v_ordem := coalesce(nullif(v_item->>'ordem', '')::integer, v_idx);
    v_periodicidade := coalesce((v_item->>'eh_periodicidade_simbolica')::boolean, false)
                       or v_grupo = 'periodicidade';

    if v_grupo is null or v_grupo not in (
      'entrada',
      'mensais',
      'anuais',
      'intermediarias',
      'chaves',
      'parcela_unica',
      'financiamento',
      'periodicidade'
    ) then
      raise exception 'grupo inválido na parcela %: %', v_idx, coalesce(v_grupo_input, '<nulo>')
        using errcode = '22023';
    end if;

    if v_periodicidade and (
      coalesce((v_item->>'pode_receber_vpl')::boolean, false)
      or coalesce((v_item->>'pode_receber_antecipacao')::boolean, false)
      or coalesce((v_item->>'pode_receber_postergacao')::boolean, false)
    ) then
      raise exception 'Periodicidade simbólica não pode ser marcada como negociável na parcela %', v_idx
        using errcode = '22023';
    end if;

    if v_item ? 'valor' then
      v_valor_original := nullif(v_item->>'valor', '')::numeric;
    elsif v_item ? 'valor_original' then
      v_valor_original := nullif(v_item->>'valor_original', '')::numeric;
    else
      v_valor_original := case when v_periodicidade then 0 else null end;
    end if;

    if v_valor_original is null then
      raise exception 'valor é obrigatório na parcela %', v_idx
        using errcode = '22023';
    end if;

    if v_valor_original < 0 then
      raise exception 'valor negativo não permitido na parcela %', v_idx
        using errcode = '22023';
    end if;

    if v_item ? 'valor_atual' then
      v_valor_atual := nullif(v_item->>'valor_atual', '')::numeric;
    else
      v_valor_atual := v_valor_original;
    end if;

    if v_valor_atual < 0 then
      raise exception 'valor_atual negativo não permitido na parcela %', v_idx
        using errcode = '22023';
    end if;

    v_data_original := null;
    v_data_atual := null;
    v_origem_data := null;
    v_regra_data := null;

    if nullif(v_item->>'data_oficial', '') is not null then
      v_data_original := nullif(v_item->>'data_oficial', '')::date;
      v_data_atual := v_data_original;
      v_origem_data := 'tabela_oficial';
      v_regra_data := nullif(v_item->>'regra_data', '');

    elsif nullif(coalesce(v_item->>'data_comercial', v_item->>'data_original'), '') is not null then
      v_data_original := nullif(coalesce(v_item->>'data_comercial', v_item->>'data_original'), '')::date;
      v_data_atual := coalesce(nullif(v_item->>'data_atual', '')::date, v_data_original);
      v_origem_data := 'tabela_comercial_data';
      v_regra_data := nullif(v_item->>'regra_data', '');

    elsif nullif(v_item->>'mes_ano', '') is not null then
      v_mes_ano := nullif(v_item->>'mes_ano', '');
      v_mes_base := make_date(split_part(v_mes_ano, '-', 1)::integer, split_part(v_mes_ano, '-', 2)::integer, 1);
      v_ultimo_dia_mes := (date_trunc('month', v_mes_base)::date + interval '1 month - 1 day')::date;
      v_dia_ato := extract(day from p_data_ato)::integer;
      v_dia_aplicado := least(v_dia_ato, extract(day from v_ultimo_dia_mes)::integer);
      v_data_original := make_date(extract(year from v_mes_base)::integer, extract(month from v_mes_base)::integer, v_dia_aplicado);
      v_data_atual := v_data_original;
      v_origem_data := 'tabela_comercial_mes';
      v_regra_data := case
        when v_dia_aplicado = v_dia_ato then 'usar_dia_do_ato'
        else 'ultimo_dia_valido_mes'
      end;

    elsif v_grupo = 'chaves'
          and (
            nullif(v_item->>'cabecalho_dias_antes_financiamento', '') is not null
            or nullif(v_regras->>'chaves_dias_antes_financiamento', '') is not null
          )
          and (
            nullif(v_item->>'data_financiamento', '') is not null
            or nullif(v_regras->>'data_financiamento', '') is not null
          ) then
      v_chaves_dias := coalesce(
        nullif(v_item->>'cabecalho_dias_antes_financiamento', '')::integer,
        nullif(v_regras->>'chaves_dias_antes_financiamento', '')::integer
      );
      v_data_financiamento := coalesce(
        nullif(v_item->>'data_financiamento', '')::date,
        nullif(v_regras->>'data_financiamento', '')::date
      );

      if v_chaves_dias not in (30, 60) then
        raise exception 'Regra de chaves aceita apenas 30 ou 60 dias na parcela %', v_idx
          using errcode = '22023';
      end if;

      v_data_original := v_data_financiamento - v_chaves_dias;
      v_data_atual := v_data_original;
      v_origem_data := 'cabecalho_regra';
      v_regra_data := format('cabecalho_%s_dias', v_chaves_dias);

    elsif v_grupo in ('entrada', 'periodicidade') then
      v_data_original := p_data_ato;
      v_data_atual := p_data_ato;
      v_origem_data := 'calculada_ato';
      v_regra_data := 'data_ato';

    elsif coalesce((v_item->>'permitir_data_estimada')::boolean, false) is true then
      v_data_original := p_data_ato;
      v_data_atual := p_data_ato;
      v_origem_data := 'estimada';
      v_regra_data := coalesce(nullif(v_item->>'regra_data', ''), 'estimada_por_data_ato');

    else
      raise exception 'data não informada ou não suportada na parcela %', v_idx
        using errcode = '22023';
    end if;

    v_pode_vpl := case
      when v_periodicidade then false
      when v_grupo in ('mensais', 'anuais', 'intermediarias', 'chaves', 'parcela_unica') then true
      else false
    end;

    v_pode_antecipacao := v_pode_vpl;
    v_pode_postergacao := v_pode_vpl;

    if v_grupo = 'financiamento' then
      v_pode_vpl := false;
      v_pode_antecipacao := false;
      v_pode_postergacao := false;
    end if;

    v_metadata := jsonb_strip_nulls(jsonb_build_object(
      'fase', '4A',
      'source_index', v_idx,
      'grupo_original', v_grupo_input,
      'empresa_id_payload_ignorado', v_item ? 'empresa_id',
      'payload_tabela_recebido', coalesce(jsonb_typeof(p_payload_tabela), 'null'),
      'observacao', nullif(v_item->>'observacao', '')
    ));

    if exists (
      select 1
      from unnest(v_sensitive_keys) k
      where v_item ? k
    ) then
      v_metadata := v_metadata || jsonb_build_object('sensivel_descartado', true);
    end if;

    v_insert_sql := format(
      'insert into public.mesa_cliente_fluxo_parcelas (
         empresa_id,
         simulacao_id,
         empreendimento_id,
         unidade_estoque_id,
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
         atualizado_por
       ) values (
         %L, %L, %L, %L, %L, %L, %L, %L, %L, %L,
         %L, %L, %L, %L, %L, %L, %L, %L::jsonb, %L, %L
       ) returning id',
      v_empresa_id,
      p_simulacao_id,
      v_empreendimento_id,
      v_unidade_estoque_id,
      v_grupo,
      v_descricao,
      round(v_valor_original, 2),
      round(v_valor_atual, 2),
      v_data_original,
      v_data_atual,
      v_origem_data,
      v_regra_data,
      v_ordem,
      v_periodicidade,
      v_pode_vpl,
      v_pode_antecipacao,
      v_pode_postergacao,
      v_metadata::text,
      v_uid,
      v_uid
    );

    execute v_insert_sql into v_parcela_id;

    if v_periodicidade then
      v_qtd_periodicidades := v_qtd_periodicidades + 1;
    else
      v_total_original := v_total_original + round(v_valor_original, 2);
      v_total_atual := v_total_atual + round(v_valor_atual, 2);
    end if;
  end loop;

  return jsonb_build_object(
    'ok', true,
    'visao', 'agenda_financeira',
    'cliente_safe', true,
    'simulacao_id', p_simulacao_id,
    'empresa_id', v_empresa_id,
    'empreendimento_id', v_empreendimento_id,
    'qtd_parcelas_criadas', (
      select count(*)::integer
      from public.mesa_cliente_fluxo_parcelas fp
      where fp.empresa_id = v_empresa_id
        and fp.simulacao_id = p_simulacao_id
    ),
    'qtd_periodicidades_simbolicas', v_qtd_periodicidades,
    'total_valor_original', round(v_total_original, 2),
    'total_valor_atual', round(v_total_atual, 2),
    'parcelas', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', fp.id,
          'grupo', fp.grupo::text,
          'descricao', fp.descricao,
          'valor_atual', fp.valor_atual,
          'data_atual', fp.data_atual,
          'origem_data', fp.origem_data::text,
          'regra_data', fp.regra_data,
          'eh_periodicidade_simbolica', fp.eh_periodicidade_simbolica,
          'pode_receber_vpl', fp.pode_receber_vpl,
          'pode_receber_antecipacao', fp.pode_receber_antecipacao,
          'pode_receber_postergacao', fp.pode_receber_postergacao,
          'ordem', fp.ordem
        )
        order by fp.ordem, fp.created_at, fp.id
      )
      from public.mesa_cliente_fluxo_parcelas fp
      where fp.empresa_id = v_empresa_id
        and fp.simulacao_id = p_simulacao_id
    ), '[]'::jsonb)
  );
end;
$$;

comment on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) is
'MesaCliente Engenharia Financeira Fase 4A: gera agenda datada de parcelas por simulação, idempotente, multitenant e sem expor VPL/prêmio/comissão/política.';

revoke all on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) from public;
grant execute on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) to authenticated;

commit;
