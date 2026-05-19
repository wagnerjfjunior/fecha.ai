-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5A.1
-- Correção pós-execução: remover dependência indevida de mesa_cliente_fluxo_operacoes.agenda_id.
--
-- Motivo:
--   O schema real de public.mesa_cliente_fluxo_operacoes não possui coluna agenda_id.
--   O preflight 10 classificava agenda_id em operações como opcional, não obrigatório.
--
-- Decisão técnica:
--   Para a Fase 5A.1, o bloqueio de operação confirmada passa a ser por:
--     empresa_id + simulacao_id + status_operacao = 'confirmada'
--   Isso é mais conservador e compatível com o schema atual.
--
-- Mantém o contrato:
--   - agenda-first;
--   - administrativo;
--   - cliente_safe=false;
--   - persistencia=false;
--   - dml_financeiro=false;
--   - sem INSERT/UPDATE/DELETE em agenda, parcelas ou operações.

create or replace function public.mesa_cliente_simular_impacto_agenda_persistida_admin(
  p_simulacao_id uuid,
  p_data_referencia date default current_date,
  p_modo text default 'melhor_aplicacao',
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_auth_uid uuid;
  v_corretor record;
  v_simulacao record;
  v_agenda record;
  v_politica record;
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_modo text := lower(coalesce(nullif(trim(p_modo), ''), 'melhor_aplicacao'));
  v_valor_disponivel numeric := 0;
  v_valor_movido numeric := 0;
  v_vpl_aplicado_pct numeric := null;
  v_data_destino date := null;
  v_qtd_confirmadas integer := 0;
  v_alternativas jsonb := '[]'::jsonb;
  v_recomendacao jsonb := '{}'::jsonb;
  v_qtd_alternativas integer := 0;
  v_maior_economia numeric := 0;
  v_maior_acrescimo numeric := 0;
  v_maior_impacto_pct numeric := 0;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: usuário autenticado obrigatório para simular impacto financeiro.';
  end if;

  if p_simulacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_simulacao_id é obrigatório.';
  end if;

  if p_data_referencia is null then
    raise exception using
      errcode = '22023',
      message = 'p_data_referencia é obrigatório.';
  end if;

  if v_modo not in ('melhor_aplicacao', 'antecipacao', 'postergacao', 'vpl', 'comparativo') then
    raise exception using
      errcode = '22023',
      message = 'Modo inválido para simulação de impacto financeiro.';
  end if;

  if v_params ? 'empresa_id' then
    raise exception using
      errcode = '42501',
      message = 'empresa_id não pode ser enviado como autoridade pelo frontend.';
  end if;

  v_valor_disponivel := coalesce(
    nullif(v_params->>'valor_disponivel', '')::numeric,
    nullif(v_params->>'valor', '')::numeric,
    0
  );

  v_valor_movido := coalesce(
    nullif(v_params->>'valor_movido', '')::numeric,
    nullif(v_params->>'valor', '')::numeric,
    v_valor_disponivel,
    0
  );

  v_vpl_aplicado_pct := nullif(v_params->>'vpl_aplicado_pct', '')::numeric;
  v_data_destino := nullif(v_params->>'data_destino', '')::date;

  if v_valor_disponivel < 0 or v_valor_movido < 0 then
    raise exception using
      errcode = '22023',
      message = 'Valores financeiros não podem ser negativos.';
  end if;

  select c.*
    into v_corretor
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
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
  limit 1;

  if v_corretor.id is null then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: corretor ativo não encontrado para auth.uid().' ;
  end if;

  select s.*
    into v_simulacao
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id
  limit 1;

  if v_simulacao.id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Simulação não encontrada.';
  end if;

  if coalesce(v_corretor.role, '') <> 'admin_global'
     and v_corretor.empresa_id is distinct from v_simulacao.empresa_id then
    raise exception using
      errcode = '42501',
      message = 'Acesso negado: simulação pertence a outro tenant.';
  end if;

  if not (
    coalesce(v_corretor.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
    or coalesce(v_corretor.is_admin_local, false)
    or coalesce(v_corretor.is_gestor, false)
    or v_simulacao.corretor_id = v_corretor.id
  ) then
    raise exception using
      errcode = '42501',
      message = 'Acesso negado: perfil sem permissão para simular impacto financeiro administrativo.';
  end if;

  select a.*
    into v_agenda
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = v_simulacao.id
    and a.empresa_id = v_simulacao.empresa_id
    and a.empreendimento_id = v_simulacao.empreendimento_id
    and a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1;

  if v_agenda.id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Agenda financeira ativa não encontrada para a simulação.';
  end if;

  -- Não filtrar por agenda_id: a tabela mesa_cliente_fluxo_operacoes não possui essa coluna no schema atual.
  -- O bloqueio da 5A.1 é conservador por simulação/empresa/status confirmado.
  select count(*)::integer
    into v_qtd_confirmadas
  from public.mesa_cliente_fluxo_operacoes o
  where o.simulacao_id = v_simulacao.id
    and o.empresa_id = v_simulacao.empresa_id
    and o.status_operacao = 'confirmada';

  if v_qtd_confirmadas > 0 then
    raise exception using
      errcode = '55000',
      message = 'Simulação bloqueada: já existe operação financeira confirmada para esta simulação.';
  end if;

  select p.*
    into v_politica
  from public.mesa_cliente_politicas_financeiras p
  where p.empresa_id = v_simulacao.empresa_id
    and coalesce(p.ativo, false) = true
    and (p.empreendimento_id = v_simulacao.empreendimento_id or p.empreendimento_id is null)
    and p.vigencia_inicio <= p_data_referencia
    and coalesce(p.vigencia_fim, date '9999-12-31') >= p_data_referencia
  order by
    case when p.empreendimento_id = v_simulacao.empreendimento_id then 1 else 2 end,
    p.mes_referencia desc nulls last,
    p.vigencia_inicio desc,
    p.id desc
  limit 1;

  if v_politica.id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Política financeira ativa/vigente não encontrada para a simulação.';
  end if;

  if v_politica.metodo_calculo::text <> 'composto' then
    raise exception using
      errcode = '22023',
      message = 'Política financeira inválida: metodo_calculo deve ser composto.';
  end if;

  if v_politica.base_tempo::text <> 'dias_365' then
    raise exception using
      errcode = '22023',
      message = 'Política financeira inválida: base_tempo deve ser dias_365.';
  end if;

  if v_vpl_aplicado_pct is null then
    v_vpl_aplicado_pct := coalesce(v_politica.vpl_max_pct, 0);
  end if;

  if v_vpl_aplicado_pct < 0 then
    raise exception using
      errcode = '22023',
      message = 'VPL aplicado não pode ser negativo.';
  end if;

  if v_vpl_aplicado_pct > coalesce(v_politica.vpl_max_pct, 0) then
    raise exception using
      errcode = '22023',
      message = 'VPL aplicado ultrapassa o limite máximo da política financeira.';
  end if;

  if v_modo in ('melhor_aplicacao', 'antecipacao', 'comparativo') and v_valor_disponivel <= 0 then
    raise exception using
      errcode = '22023',
      message = 'valor_disponivel deve ser maior que zero para melhor_aplicacao, antecipacao ou comparativo.';
  end if;

  if v_modo = 'postergacao' and v_valor_movido <= 0 then
    raise exception using
      errcode = '22023',
      message = 'valor_movido deve ser maior que zero para postergacao.';
  end if;

  if v_modo = 'postergacao' and v_data_destino is null then
    v_data_destino := p_data_referencia + 180;
  end if;

  with parcelas_base as materialized (
    select
      fp.id as parcela_id,
      fp.grupo::text as grupo,
      fp.descricao,
      fp.ordem,
      fp.valor_atual::numeric as valor_atual,
      fp.data_atual::date as data_atual,
      coalesce(fp.eh_periodicidade_simbolica, false) as eh_periodicidade_simbolica,
      coalesce(fp.pode_receber_antecipacao, false) as pode_receber_antecipacao,
      coalesce(fp.pode_receber_postergacao, false) as pode_receber_postergacao,
      coalesce(fp.pode_receber_vpl, false) as pode_receber_vpl,
      case
        when lower(fp.grupo::text) in ('financiamento', 'financiamento_bancario', 'financiamento bancário') then 'financiamento'
        when lower(fp.grupo::text) in ('chaves', 'chave') then 'chaves'
        when lower(fp.grupo::text) in ('anual', 'anuais', 'intermediaria', 'intermediarias', 'intermediária', 'intermediárias') then 'anuais'
        when lower(fp.grupo::text) in ('mensal', 'mensais') then 'mensais'
        else lower(fp.grupo::text)
      end as grupo_norm
    from public.mesa_cliente_fluxo_parcelas fp
    where fp.agenda_id = v_agenda.id
      and fp.simulacao_id = v_simulacao.id
      and fp.empresa_id = v_simulacao.empresa_id
      and fp.valor_atual > 0
      and fp.data_atual is not null
      and coalesce(fp.eh_periodicidade_simbolica, false) = false
  ),
antecipacao as (
    select
      'antecipacao'::text as tipo_operacao,
      pb.parcela_id,
      pb.grupo,
      pb.grupo_norm,
      pb.descricao,
      pb.ordem,
      pb.valor_atual,
      least(pb.valor_atual, v_valor_disponivel) as valor_operacao,
      p_data_referencia as data_nova,
      pb.data_atual as data_original,
      greatest((pb.data_atual - p_data_referencia), 0)::integer as dias_impacto,
      public.mesa_cliente_financeiro_valor_presente_composto(
        least(pb.valor_atual, v_valor_disponivel),
        v_politica.taxa_antecipacao_ano_pct,
        greatest((pb.data_atual - p_data_referencia), 0)::integer,
        v_politica.base_tempo::text
      ) as valor_calculado,
      greatest(
        least(pb.valor_atual, v_valor_disponivel) - public.mesa_cliente_financeiro_valor_presente_composto(
          least(pb.valor_atual, v_valor_disponivel),
          v_politica.taxa_antecipacao_ano_pct,
          greatest((pb.data_atual - p_data_referencia), 0)::integer,
          v_politica.base_tempo::text
        ),
        0
      ) as economia_liquida,
      0::numeric as acrescimo,
      public.mesa_cliente_financeiro_calcular_antecipacao_composta(
        least(pb.valor_atual, v_valor_disponivel),
        pb.data_atual,
        p_data_referencia,
        v_politica.taxa_antecipacao_ano_pct,
        v_politica.base_tempo::text
      ) as calculo_motor
    from parcelas_base pb
    where v_modo in ('melhor_aplicacao', 'antecipacao', 'comparativo')
      and pb.pode_receber_antecipacao
      and pb.data_atual > p_data_referencia
      and (
        (pb.grupo_norm = 'financiamento' and coalesce(v_politica.permite_antecipacao_financiamento, false))
        or (pb.grupo_norm = 'chaves' and coalesce(v_politica.permite_antecipacao_chaves, false))
        or (pb.grupo_norm = 'anuais' and coalesce(v_politica.permite_antecipacao_anuais, false))
        or (pb.grupo_norm = 'mensais' and coalesce(v_politica.permite_antecipacao_mensais, false))
      )
  ),
postergacao as (
    select
      'postergacao'::text as tipo_operacao,
      pb.parcela_id,
      pb.grupo,
      pb.grupo_norm,
      pb.descricao,
      pb.ordem,
      pb.valor_atual,
      least(pb.valor_atual, v_valor_movido) as valor_operacao,
      v_data_destino as data_nova,
      pb.data_atual as data_original,
      greatest((v_data_destino - pb.data_atual), 0)::integer as dias_impacto,
      public.mesa_cliente_financeiro_valor_futuro_composto(
        least(pb.valor_atual, v_valor_movido),
        v_politica.taxa_postergacao_ano_pct,
        greatest((v_data_destino - pb.data_atual), 0)::integer,
        v_politica.base_tempo::text
      ) as valor_calculado,
      0::numeric as economia_liquida,
      greatest(
        public.mesa_cliente_financeiro_valor_futuro_composto(
          least(pb.valor_atual, v_valor_movido),
          v_politica.taxa_postergacao_ano_pct,
          greatest((v_data_destino - pb.data_atual), 0)::integer,
          v_politica.base_tempo::text
        ) - least(pb.valor_atual, v_valor_movido),
        0
      ) as acrescimo,
      public.mesa_cliente_financeiro_calcular_postergacao_composta(
        least(pb.valor_atual, v_valor_movido),
        pb.data_atual,
        v_data_destino,
        v_politica.taxa_postergacao_ano_pct,
        v_politica.base_tempo::text
      ) as calculo_motor
    from parcelas_base pb
    where v_modo in ('postergacao', 'comparativo')
      and pb.pode_receber_postergacao
      and v_data_destino > pb.data_atual
      and (
        (pb.grupo_norm = 'financiamento' and coalesce(v_politica.permite_postergacao_financiamento, false))
        or (pb.grupo_norm = 'chaves' and coalesce(v_politica.permite_postergacao_chaves, false))
        or (pb.grupo_norm = 'anuais' and coalesce(v_politica.permite_postergacao_anuais, false))
        or (pb.grupo_norm = 'mensais' and coalesce(v_politica.permite_postergacao_mensais, false))
      )
  ),
vpl as (
    select
      'vpl'::text as tipo_operacao,
      pb.parcela_id,
      pb.grupo,
      pb.grupo_norm,
      pb.descricao,
      pb.ordem,
      pb.valor_atual,
      case when v_valor_disponivel > 0 then least(pb.valor_atual, v_valor_disponivel) else pb.valor_atual end as valor_operacao,
      p_data_referencia as data_nova,
      pb.data_atual as data_original,
      greatest((pb.data_atual - p_data_referencia), 0)::integer as dias_impacto,
      greatest((case when v_valor_disponivel > 0 then least(pb.valor_atual, v_valor_disponivel) else pb.valor_atual end) * (v_vpl_aplicado_pct / 100.0), 0) as valor_calculado,
      greatest((case when v_valor_disponivel > 0 then least(pb.valor_atual, v_valor_disponivel) else pb.valor_atual end) * (v_vpl_aplicado_pct / 100.0), 0) as economia_liquida,
      0::numeric as acrescimo,
      public.mesa_cliente_financeiro_calcular_vpl_parcela(
        case when v_valor_disponivel > 0 then least(pb.valor_atual, v_valor_disponivel) else pb.valor_atual end,
        pb.data_atual,
        p_data_referencia,
        v_vpl_aplicado_pct,
        v_politica.base_tempo::text
      ) as calculo_motor
    from parcelas_base pb
    where v_modo in ('melhor_aplicacao', 'vpl', 'comparativo')
      and pb.pode_receber_vpl
      and (
        (pb.grupo_norm = 'financiamento' and coalesce(v_politica.permite_vpl_financiamento, false))
        or (pb.grupo_norm = 'chaves' and coalesce(v_politica.permite_vpl_chaves, false))
        or (pb.grupo_norm = 'anuais' and coalesce(v_politica.permite_vpl_anuais, false))
        or (pb.grupo_norm = 'mensais' and coalesce(v_politica.permite_vpl_mensais, false))
      )
  ),
alt as (
    select * from antecipacao
    union all
    select * from postergacao
    union all
    select * from vpl
  ),
alt_json as (
    select
      jsonb_build_object(
        'tipo_operacao', tipo_operacao,
        'parcela_id', parcela_id,
        'grupo', grupo,
        'grupo_norm', grupo_norm,
        'descricao', descricao,
        'ordem', ordem,
        'valor_atual', round(valor_atual, 2),
        'valor_operacao', round(valor_operacao, 2),
        'data_original', data_original,
        'data_nova', data_nova,
        'dias_impacto', dias_impacto,
        'valor_calculado', round(valor_calculado, 2),
        'economia_liquida', round(economia_liquida, 2),
        'acrescimo', round(acrescimo, 2),
        'impacto_pct', case when valor_operacao > 0 then round(((economia_liquida + acrescimo) / valor_operacao) * 100, 4) else 0 end,
        'score_recomendacao', case when tipo_operacao = 'postergacao' then -acrescimo else economia_liquida end,
        'calculo_motor', to_jsonb(calculo_motor)
      ) as item
    from alt
  )
  select coalesce(jsonb_agg(item order by (item->>'score_recomendacao')::numeric desc, (item->>'dias_impacto')::integer desc), '[]'::jsonb)
    into v_alternativas
  from alt_json;

  v_qtd_alternativas := jsonb_array_length(v_alternativas);

  if v_qtd_alternativas = 0 then
    raise exception using
      errcode = 'P0002',
      message = 'Nenhuma parcela elegível encontrada para a simulação de impacto solicitada.';
  end if;

  select coalesce(value, '{}'::jsonb)
    into v_recomendacao
  from jsonb_array_elements(v_alternativas) value
  order by coalesce((value->>'score_recomendacao')::numeric, 0) desc
  limit 1;

  select
    coalesce(max((value->>'economia_liquida')::numeric), 0),
    coalesce(max((value->>'acrescimo')::numeric), 0),
    coalesce(max((value->>'impacto_pct')::numeric), 0)
    into v_maior_economia, v_maior_acrescimo, v_maior_impacto_pct
  from jsonb_array_elements(v_alternativas) value;

  return jsonb_build_object(
    'ok', true,
    'fase', '5A_SIMULACAO_IMPACTO_AGENDA_PERSISTIDA',
    'visao', 'administrativa',
    'cliente_safe', false,
    'persistencia', false,
    'dml_financeiro', false,
    'simulacao_id', v_simulacao.id,
    'agenda_id', v_agenda.id,
    'empresa_id', v_simulacao.empresa_id,
    'empreendimento_id', v_simulacao.empreendimento_id,
    'data_referencia', p_data_referencia,
    'modo', v_modo,
    'politica', jsonb_build_object(
      'id', v_politica.id,
      'vpl_max_pct', v_politica.vpl_max_pct,
      'taxa_antecipacao_ano_pct', v_politica.taxa_antecipacao_ano_pct,
      'taxa_postergacao_ano_pct', v_politica.taxa_postergacao_ano_pct,
      'metodo_calculo', v_politica.metodo_calculo::text,
      'base_tempo', v_politica.base_tempo::text,
      'vigencia_inicio', v_politica.vigencia_inicio,
      'vigencia_fim', v_politica.vigencia_fim
    ),
    'parametros', v_params,
    'resumo', jsonb_build_object(
      'qtd_alternativas', v_qtd_alternativas,
      'melhor_tipo_operacao', v_recomendacao->>'tipo_operacao',
      'maior_economia_liquida', round(v_maior_economia, 2),
      'maior_acrescimo', round(v_maior_acrescimo, 2),
      'maior_impacto_pct', round(v_maior_impacto_pct, 4),
      'operacoes_confirmadas_bloqueantes', v_qtd_confirmadas
    ),
    'recomendacao', v_recomendacao,
    'alternativas', v_alternativas,
    'rejeicoes', '[]'::jsonb
  );
end;
$$;

revoke all on function public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb) from public;
revoke all on function public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb) from anon;
grant execute on function public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb) to authenticated;

comment on function public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)
is 'FECH.AI MesaCliente Fase 5A.1: simulação administrativa agenda-first de impacto financeiro sobre agenda persistida, sem DML financeiro e sem cliente_safe. Correção: não depende de mesa_cliente_fluxo_operacoes.agenda_id inexistente.';
