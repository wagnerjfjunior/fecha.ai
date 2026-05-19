-- MesaCliente Engenharia Financeira — Fase 3B: RPC de simulação administrativa
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Criar uma RPC soberana para simular impacto financeiro administrativo
--   de operações de VPL, antecipação e postergação, sem gravar dados.
--
-- Escopo:
--   - Não grava em mesa_cliente_fluxo_operacoes.
--   - Não altera parcelas.
--   - Não altera simulação.
--   - Não mexe no parser, motor financeiro atual, Worker, Make ou front.
--   - Não retorna payload para cliente.
--   - Retorna visão administrativa para corretor/coordenador/gestor autorizado.
--
-- Segurança:
--   - SECURITY DEFINER.
--   - Exige auth.uid() via mesa_cliente_assert_auth().
--   - Valida acesso à empresa via mesa_cliente_can_access_empresa().
--   - Valida empreendimento pertence à empresa.
--   - Política sempre vem do banco.
--   - Taxas e limites nunca vêm do front.
--   - Periodicidade simbólica não é negociável.
--
-- Payload esperado em p_operacoes:
-- [
--   {
--     "tipo_operacao": "antecipacao" | "postergacao" | "vpl",
--     "grupo": "entrada" | "mensais" | "intermediarias" | "anuais" | "chaves" | "financiamento" | "parcela_unica",
--     "valor": 100000,
--     "data_original": "2027-01-01",
--     "data_nova": "2026-01-01",              -- usado em antecipacao/postergacao
--     "data_parcela": "2027-01-01",          -- opcional para vpl; se ausente usa data_original
--     "parcela_id": "uuid-opcional",
--     "descricao": "opcional",
--     "eh_periodicidade_simbolica": false
--   }
-- ]

begin;

create or replace function public.mesa_cliente_simular_impacto_financeiro_admin(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_data_ato date,
  p_operacoes jsonb,
  p_politica_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_politica record;
  v_ops jsonb;
  v_op jsonb;
  v_result_calc jsonb;
  v_resultados jsonb := '[]'::jsonb;
  v_erros jsonb := '[]'::jsonb;
  v_total_valor_original numeric := 0;
  v_total_valor_calculado numeric := 0;
  v_total_desconto numeric := 0;
  v_total_acrescimo numeric := 0;
  v_total_economia numeric := 0;
  v_maior_impacto_pct numeric := 0;
  v_maior_premio_pct numeric := null;
  v_status_premio text := null;
  v_faixa record;
  v_idx integer := 0;
  v_tipo text;
  v_grupo text;
  v_valor numeric;
  v_data_original date;
  v_data_nova date;
  v_data_parcela date;
  v_parcela_id uuid;
  v_descricao text;
  v_periodicidade_simbolica boolean;
  v_permitido boolean;
  v_impacto_pct numeric;
  v_valor_calculado numeric;
  v_desconto numeric;
  v_acrescimo numeric;
  v_economia numeric;
  v_dias integer;
  v_taxa numeric;
  v_msg text;
begin
  perform public.mesa_cliente_assert_auth();

  if p_empresa_id is null then
    raise exception 'empresa_id é obrigatório'
      using errcode = '22023';
  end if;

  if p_empreendimento_id is null then
    raise exception 'empreendimento_id é obrigatório'
      using errcode = '22023';
  end if;

  if p_data_ato is null then
    raise exception 'data_ato é obrigatória'
      using errcode = '22023';
  end if;

  if p_operacoes is null or jsonb_typeof(p_operacoes) <> 'array' then
    raise exception 'operacoes deve ser um array jsonb'
      using errcode = '22023';
  end if;

  if jsonb_array_length(p_operacoes) = 0 then
    raise exception 'operacoes não pode ser vazio'
      using errcode = '22023';
  end if;

  if jsonb_array_length(p_operacoes) > 200 then
    raise exception 'limite máximo de 200 operações por simulação'
      using errcode = '22023';
  end if;

  if not public.mesa_cliente_can_access_empresa(p_empresa_id) then
    raise exception 'Sem permissão para simular impacto financeiro desta empresa'
      using errcode = '42501';
  end if;

  perform public.mesa_cliente_assert_empreendimento_empresa(p_empresa_id, p_empreendimento_id);

  if p_politica_id is not null then
    select p.*
      into v_politica
    from public.mesa_cliente_politicas_financeiras p
    where p.id = p_politica_id
      and p.empresa_id = p_empresa_id
      and p.empreendimento_id = p_empreendimento_id
      and p.ativo is true;
  else
    select p.*
      into v_politica
    from public.mesa_cliente_politicas_financeiras p
    where p.empresa_id = p_empresa_id
      and p.empreendimento_id = p_empreendimento_id
      and p.ativo is true
      and p_data_ato between p.vigencia_inicio and p.vigencia_fim
    order by p.mes_referencia desc, p.vigencia_inicio desc, p.created_at desc
    limit 1;
  end if;

  if v_politica.id is null then
    raise exception 'Política financeira vigente não encontrada para o empreendimento e data do ato'
      using errcode = 'P0002';
  end if;

  if v_politica.metodo_calculo::text <> 'composto' then
    raise exception 'Método de cálculo não suportado nesta fase: %', v_politica.metodo_calculo::text
      using errcode = '22023';
  end if;

  if v_politica.base_tempo::text <> 'dias_365' then
    raise exception 'Base de tempo não suportada nesta fase: %', v_politica.base_tempo::text
      using errcode = '22023';
  end if;

  v_ops := p_operacoes;

  for v_op in select value from jsonb_array_elements(v_ops)
  loop
    v_idx := v_idx + 1;
    v_tipo := lower(nullif(v_op->>'tipo_operacao', ''));
    v_grupo := lower(nullif(v_op->>'grupo', ''));
    v_valor := nullif(v_op->>'valor', '')::numeric;
    v_data_original := nullif(v_op->>'data_original', '')::date;
    v_data_nova := nullif(v_op->>'data_nova', '')::date;
    v_data_parcela := coalesce(nullif(v_op->>'data_parcela', '')::date, v_data_original);
    v_parcela_id := nullif(v_op->>'parcela_id', '')::uuid;
    v_descricao := nullif(v_op->>'descricao', '');
    v_periodicidade_simbolica := coalesce((v_op->>'eh_periodicidade_simbolica')::boolean, false);
    v_result_calc := null;
    v_permitido := false;
    v_impacto_pct := 0;
    v_valor_calculado := round(coalesce(v_valor, 0), 2);
    v_desconto := 0;
    v_acrescimo := 0;
    v_economia := 0;
    v_dias := 0;
    v_taxa := 0;
    v_status_premio := null;
    v_maior_premio_pct := v_maior_premio_pct;

    if v_tipo not in ('vpl', 'antecipacao', 'postergacao') then
      raise exception 'tipo_operacao inválido no item %: %', v_idx, coalesce(v_tipo, '<nulo>')
        using errcode = '22023';
    end if;

    if v_grupo not in ('entrada', 'mensais', 'intermediarias', 'anuais', 'chaves', 'financiamento', 'parcela_unica') then
      raise exception 'grupo inválido no item %: %', v_idx, coalesce(v_grupo, '<nulo>')
        using errcode = '22023';
    end if;

    if v_valor is null or v_valor < 0 then
      raise exception 'valor inválido no item %', v_idx
        using errcode = '22023';
    end if;

    if v_periodicidade_simbolica then
      v_msg := 'Periodicidade simbólica não entra como parcela negociável';
      v_erros := v_erros || jsonb_build_array(jsonb_build_object(
        'index', v_idx,
        'tipo_operacao', v_tipo,
        'grupo', v_grupo,
        'motivo', v_msg
      ));
      continue;
    end if;

    if v_tipo = 'vpl' then
      v_permitido := case
        when v_grupo = 'financiamento' then v_politica.permite_vpl_financiamento
        when v_grupo in ('chaves', 'parcela_unica') then v_politica.permite_vpl_chaves
        when v_grupo in ('anuais', 'intermediarias') then v_politica.permite_vpl_anuais
        when v_grupo in ('mensais', 'entrada') then v_politica.permite_vpl_mensais
        else false
      end;

      if not v_permitido then
        v_erros := v_erros || jsonb_build_array(jsonb_build_object(
          'index', v_idx,
          'tipo_operacao', v_tipo,
          'grupo', v_grupo,
          'motivo', 'Política não permite VPL para este grupo'
        ));
        continue;
      end if;

      v_result_calc := public.mesa_cliente_financeiro_calcular_vpl_parcela(
        v_valor,
        p_data_ato,
        v_data_parcela,
        v_politica.taxa_antecipacao_ano_pct,
        v_politica.base_tempo::text
      );

      v_impacto_pct := coalesce((v_result_calc->>'vpl_pct')::numeric, 0);
      v_valor_calculado := coalesce((v_result_calc->>'valor_presente')::numeric, v_valor);
      v_desconto := coalesce((v_result_calc->>'desconto_calculado')::numeric, 0);
      v_acrescimo := 0;
      v_economia := v_desconto;
      v_dias := coalesce((v_result_calc->>'dias_calculo')::integer, 0);
      v_taxa := v_politica.taxa_antecipacao_ano_pct;

    elsif v_tipo = 'antecipacao' then
      v_permitido := case
        when v_grupo = 'financiamento' then v_politica.permite_antecipacao_financiamento
        when v_grupo in ('chaves', 'parcela_unica') then v_politica.permite_antecipacao_chaves
        when v_grupo in ('anuais', 'intermediarias') then v_politica.permite_antecipacao_anuais
        when v_grupo in ('mensais', 'entrada') then v_politica.permite_antecipacao_mensais
        else false
      end;

      if not v_permitido then
        v_erros := v_erros || jsonb_build_array(jsonb_build_object(
          'index', v_idx,
          'tipo_operacao', v_tipo,
          'grupo', v_grupo,
          'motivo', 'Política não permite antecipação para este grupo'
        ));
        continue;
      end if;

      v_result_calc := public.mesa_cliente_financeiro_calcular_antecipacao_composta(
        v_valor,
        v_data_original,
        v_data_nova,
        v_politica.taxa_antecipacao_ano_pct,
        v_politica.base_tempo::text
      );

      v_impacto_pct := coalesce((v_result_calc->>'impacto_pct')::numeric, 0);
      v_valor_calculado := coalesce((v_result_calc->>'valor_calculado')::numeric, v_valor);
      v_desconto := coalesce((v_result_calc->>'desconto_calculado')::numeric, 0);
      v_acrescimo := 0;
      v_economia := coalesce((v_result_calc->>'economia_liquida')::numeric, 0);
      v_dias := coalesce((v_result_calc->>'dias_calculo')::integer, 0);
      v_taxa := v_politica.taxa_antecipacao_ano_pct;

    elsif v_tipo = 'postergacao' then
      v_permitido := case
        when v_grupo = 'financiamento' then v_politica.permite_postergacao_financiamento
        when v_grupo in ('chaves', 'parcela_unica') then v_politica.permite_postergacao_chaves
        when v_grupo in ('anuais', 'intermediarias') then v_politica.permite_postergacao_anuais
        when v_grupo in ('mensais', 'entrada') then v_politica.permite_postergacao_mensais
        else false
      end;

      if not v_permitido then
        v_erros := v_erros || jsonb_build_array(jsonb_build_object(
          'index', v_idx,
          'tipo_operacao', v_tipo,
          'grupo', v_grupo,
          'motivo', 'Política não permite postergação para este grupo'
        ));
        continue;
      end if;

      v_result_calc := public.mesa_cliente_financeiro_calcular_postergacao_composta(
        v_valor,
        v_data_original,
        v_data_nova,
        v_politica.taxa_postergacao_ano_pct,
        v_politica.base_tempo::text
      );

      v_impacto_pct := coalesce((v_result_calc->>'impacto_pct')::numeric, 0);
      v_valor_calculado := coalesce((v_result_calc->>'valor_calculado')::numeric, v_valor);
      v_desconto := 0;
      v_acrescimo := coalesce((v_result_calc->>'acrescimo_calculado')::numeric, 0);
      v_economia := 0;
      v_dias := coalesce((v_result_calc->>'dias_calculo')::integer, 0);
      v_taxa := v_politica.taxa_postergacao_ano_pct;
    end if;

    if v_impacto_pct > v_politica.vpl_max_pct then
      v_erros := v_erros || jsonb_build_array(jsonb_build_object(
        'index', v_idx,
        'tipo_operacao', v_tipo,
        'grupo', v_grupo,
        'impacto_pct', v_impacto_pct,
        'vpl_max_pct', v_politica.vpl_max_pct,
        'motivo', 'Impacto excede limite máximo da política'
      ));
      continue;
    end if;

    select f.*
      into v_faixa
    from public.mesa_cliente_politica_premio_faixas f
    where f.empresa_id = p_empresa_id
      and f.politica_id = v_politica.id
      and f.ativo is true
      and v_impacto_pct >= f.vpl_de_pct
      and v_impacto_pct <= f.vpl_ate_pct
    order by f.ordem, f.vpl_de_pct, f.vpl_ate_pct
    limit 1;

    v_status_premio := coalesce(v_faixa.status, 'sem_faixa');

    if v_faixa.id is not null then
      if v_maior_premio_pct is null or v_faixa.premio_corretor_pct < v_maior_premio_pct then
        v_maior_premio_pct := v_faixa.premio_corretor_pct;
      end if;
    else
      v_maior_premio_pct := 0;
    end if;

    v_maior_impacto_pct := greatest(v_maior_impacto_pct, coalesce(v_impacto_pct, 0));
    v_total_valor_original := v_total_valor_original + round(v_valor, 2);
    v_total_valor_calculado := v_total_valor_calculado + round(v_valor_calculado, 2);
    v_total_desconto := v_total_desconto + round(v_desconto, 2);
    v_total_acrescimo := v_total_acrescimo + round(v_acrescimo, 2);
    v_total_economia := v_total_economia + round(v_economia, 2);

    v_resultados := v_resultados || jsonb_build_array(jsonb_build_object(
      'index', v_idx,
      'parcela_id', v_parcela_id,
      'descricao', v_descricao,
      'tipo_operacao', v_tipo,
      'grupo', v_grupo,
      'valor_original', round(v_valor, 2),
      'valor_calculado', round(v_valor_calculado, 2),
      'desconto_calculado', round(v_desconto, 2),
      'acrescimo_calculado', round(v_acrescimo, 2),
      'economia_liquida', round(v_economia, 2),
      'impacto_pct', round(v_impacto_pct, 6),
      'dias_calculo', v_dias,
      'taxa_ano_pct', v_taxa,
      'status_premio', v_status_premio,
      'premio_corretor_pct', case when v_faixa.id is null then null else v_faixa.premio_corretor_pct end,
      'politica_id', v_politica.id,
      'data_ato', p_data_ato,
      'data_original', v_data_original,
      'data_nova', v_data_nova,
      'data_parcela', v_data_parcela,
      'calculo', v_result_calc
    ));
  end loop;

  return jsonb_build_object(
    'ok', jsonb_array_length(v_erros) = 0,
    'visao', 'administrativa',
    'cliente_safe', false,
    'empresa_id', p_empresa_id,
    'empreendimento_id', p_empreendimento_id,
    'data_ato', p_data_ato,
    'politica', jsonb_build_object(
      'id', v_politica.id,
      'mes_referencia', v_politica.mes_referencia,
      'vigencia_inicio', v_politica.vigencia_inicio,
      'vigencia_fim', v_politica.vigencia_fim,
      'vpl_max_pct', v_politica.vpl_max_pct,
      'taxa_antecipacao_ano_pct', v_politica.taxa_antecipacao_ano_pct,
      'taxa_postergacao_ano_pct', v_politica.taxa_postergacao_ano_pct,
      'metodo_calculo', v_politica.metodo_calculo::text,
      'base_tempo', v_politica.base_tempo::text
    ),
    'totais', jsonb_build_object(
      'qtd_operacoes_validas', jsonb_array_length(v_resultados),
      'qtd_operacoes_rejeitadas', jsonb_array_length(v_erros),
      'valor_original_total', round(v_total_valor_original, 2),
      'valor_calculado_total', round(v_total_valor_calculado, 2),
      'desconto_total', round(v_total_desconto, 2),
      'acrescimo_total', round(v_total_acrescimo, 2),
      'economia_liquida_total', round(v_total_economia, 2),
      'maior_impacto_pct', round(v_maior_impacto_pct, 6),
      'premio_corretor_pct_mais_restritivo', v_maior_premio_pct
    ),
    'operacoes', v_resultados,
    'rejeicoes', v_erros
  );
end;
$$;

comment on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) is
'MesaCliente Engenharia Financeira: simula impacto financeiro administrativo com cálculo composto, política soberana em banco e sem gravação de operação. Não é payload cliente-safe.';

revoke all on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) from public;
grant execute on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) to authenticated;

commit;
