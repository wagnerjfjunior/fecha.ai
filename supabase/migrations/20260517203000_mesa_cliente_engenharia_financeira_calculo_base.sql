-- MesaCliente Engenharia Financeira — Fase 3A: Funções base de cálculo composto
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Criar funções puras, determinísticas e testáveis para cálculo financeiro composto.
--
-- Escopo:
--   - Não grava dados.
--   - Não lê tabelas de negócio.
--   - Não altera parser, motor financeiro atual, Worker, Make ou front.
--   - Não expõe regra interna para cliente.
--   - Não usa desconto simples global.
--
-- Premissas implementadas:
--   - Cálculo composto.
--   - Base de tempo inicialmente suportada: dias_365.
--   - Taxas vêm como parâmetro das futuras políticas financeiras, nunca hardcoded no front.
--   - Dias <= 0 não geram benefício financeiro.
--   - Taxa zero não gera desconto/acréscimo.
--   - Valores monetários finais arredondados em 2 casas.
--   - Percentuais de impacto arredondados em 6 casas.
--
-- Segurança:
--   As funções são SECURITY INVOKER, IMMUTABLE e sem acesso a tabelas.
--   Mesmo assim, EXECUTE é revogado de PUBLIC para evitar exposição direta desnecessária.
--   As futuras RPCs SECURITY DEFINER chamarão estas funções internamente.

begin;

-- -----------------------------------------------------------------------------
-- 1. Validador interno de parâmetros de cálculo
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_assert_calculo_input(
  p_valor numeric,
  p_taxa_ano_pct numeric,
  p_base_tempo text default 'dias_365'
)
returns void
language plpgsql
immutable
security invoker
set search_path = public
as $$
begin
  if p_valor is null then
    raise exception 'valor é obrigatório'
      using errcode = '22023';
  end if;

  if p_valor < 0 then
    raise exception 'valor não pode ser negativo'
      using errcode = '22023';
  end if;

  if p_taxa_ano_pct is null then
    raise exception 'taxa_ano_pct é obrigatória'
      using errcode = '22023';
  end if;

  if p_taxa_ano_pct < 0 or p_taxa_ano_pct > 100 then
    raise exception 'taxa_ano_pct deve estar entre 0 e 100'
      using errcode = '22023';
  end if;

  if coalesce(p_base_tempo, '') <> 'dias_365' then
    raise exception 'base_tempo inválida. Valor suportado nesta fase: dias_365'
      using errcode = '22023';
  end if;
end;
$$;

comment on function public.mesa_cliente_financeiro_assert_calculo_input(numeric, numeric, text) is
'MesaCliente Engenharia Financeira: valida parâmetros básicos de cálculo composto. Função interna, sem acesso direto pelo front.';

-- -----------------------------------------------------------------------------
-- 2. Dias entre datas
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_dias_entre(
  p_data_base date,
  p_data_alvo date
)
returns integer
language plpgsql
immutable
security invoker
set search_path = public
as $$
begin
  if p_data_base is null then
    raise exception 'data_base é obrigatória'
      using errcode = '22023';
  end if;

  if p_data_alvo is null then
    raise exception 'data_alvo é obrigatória'
      using errcode = '22023';
  end if;

  return (p_data_alvo - p_data_base)::integer;
end;
$$;

comment on function public.mesa_cliente_financeiro_dias_entre(date, date) is
'MesaCliente Engenharia Financeira: calcula diferença de dias entre duas datas. Resultado positivo quando data_alvo é posterior à data_base.';

-- -----------------------------------------------------------------------------
-- 3. Fator composto
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_fator_composto(
  p_taxa_ano_pct numeric,
  p_dias integer,
  p_base_tempo text default 'dias_365'
)
returns numeric
language plpgsql
immutable
security invoker
set search_path = public
as $$
declare
  v_dias integer;
begin
  perform public.mesa_cliente_financeiro_assert_calculo_input(0, p_taxa_ano_pct, p_base_tempo);

  v_dias := greatest(coalesce(p_dias, 0), 0);

  if v_dias <= 0 or p_taxa_ano_pct = 0 then
    return 1.000000000000;
  end if;

  return power((1 + (p_taxa_ano_pct / 100.0))::numeric, (v_dias::numeric / 365.0));
end;
$$;

comment on function public.mesa_cliente_financeiro_fator_composto(numeric, integer, text) is
'MesaCliente Engenharia Financeira: calcula fator composto (1 + taxa_ano) ^ (dias / 365). Dias <= 0 retornam 1.';

-- -----------------------------------------------------------------------------
-- 4. Valor presente composto
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_valor_presente_composto(
  p_valor_futuro numeric,
  p_taxa_ano_pct numeric,
  p_dias integer,
  p_base_tempo text default 'dias_365'
)
returns numeric
language plpgsql
immutable
security invoker
set search_path = public
as $$
declare
  v_fator numeric;
begin
  perform public.mesa_cliente_financeiro_assert_calculo_input(p_valor_futuro, p_taxa_ano_pct, p_base_tempo);

  v_fator := public.mesa_cliente_financeiro_fator_composto(p_taxa_ano_pct, p_dias, p_base_tempo);

  if v_fator = 0 then
    raise exception 'fator composto inválido'
      using errcode = '22012';
  end if;

  return round((p_valor_futuro / v_fator)::numeric, 2);
end;
$$;

comment on function public.mesa_cliente_financeiro_valor_presente_composto(numeric, numeric, integer, text) is
'MesaCliente Engenharia Financeira: calcula valor presente composto. valor_presente = valor_futuro / fator_composto.';

-- -----------------------------------------------------------------------------
-- 5. Valor futuro composto
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_valor_futuro_composto(
  p_valor_presente numeric,
  p_taxa_ano_pct numeric,
  p_dias integer,
  p_base_tempo text default 'dias_365'
)
returns numeric
language plpgsql
immutable
security invoker
set search_path = public
as $$
declare
  v_fator numeric;
begin
  perform public.mesa_cliente_financeiro_assert_calculo_input(p_valor_presente, p_taxa_ano_pct, p_base_tempo);

  v_fator := public.mesa_cliente_financeiro_fator_composto(p_taxa_ano_pct, p_dias, p_base_tempo);

  return round((p_valor_presente * v_fator)::numeric, 2);
end;
$$;

comment on function public.mesa_cliente_financeiro_valor_futuro_composto(numeric, numeric, integer, text) is
'MesaCliente Engenharia Financeira: calcula valor futuro composto. valor_futuro = valor_presente * fator_composto.';

-- -----------------------------------------------------------------------------
-- 6. Antecipação composta
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_calcular_antecipacao_composta(
  p_valor_original numeric,
  p_data_original date,
  p_data_nova date,
  p_taxa_ano_pct numeric,
  p_base_tempo text default 'dias_365'
)
returns jsonb
language plpgsql
immutable
security invoker
set search_path = public
as $$
declare
  v_dias integer;
  v_valor_calculado numeric;
  v_desconto numeric;
  v_impacto_pct numeric;
  v_aplicavel boolean;
begin
  perform public.mesa_cliente_financeiro_assert_calculo_input(p_valor_original, p_taxa_ano_pct, p_base_tempo);

  if p_data_original is null then
    raise exception 'data_original é obrigatória'
      using errcode = '22023';
  end if;

  if p_data_nova is null then
    raise exception 'data_nova é obrigatória'
      using errcode = '22023';
  end if;

  v_dias := public.mesa_cliente_financeiro_dias_entre(p_data_nova, p_data_original);
  v_aplicavel := v_dias > 0 and p_taxa_ano_pct > 0 and p_valor_original > 0;

  if not v_aplicavel then
    v_valor_calculado := round(p_valor_original, 2);
    v_desconto := 0;
    v_impacto_pct := 0;
  else
    v_valor_calculado := public.mesa_cliente_financeiro_valor_presente_composto(
      p_valor_original,
      p_taxa_ano_pct,
      v_dias,
      p_base_tempo
    );
    v_desconto := round((p_valor_original - v_valor_calculado)::numeric, 2);
    v_impacto_pct := round(((v_desconto / nullif(p_valor_original, 0)) * 100)::numeric, 6);
  end if;

  return jsonb_build_object(
    'tipo_operacao', 'antecipacao',
    'metodo_calculo', 'composto',
    'base_tempo', p_base_tempo,
    'aplicavel', v_aplicavel,
    'valor_original', round(p_valor_original, 2),
    'valor_calculado', v_valor_calculado,
    'desconto_calculado', v_desconto,
    'acrescimo_calculado', 0,
    'economia_liquida', v_desconto,
    'impacto_pct', v_impacto_pct,
    'dias_calculo', greatest(v_dias, 0),
    'taxa_ano_pct', p_taxa_ano_pct,
    'data_original', p_data_original,
    'data_nova', p_data_nova
  );
end;
$$;

comment on function public.mesa_cliente_financeiro_calcular_antecipacao_composta(numeric, date, date, numeric, text) is
'MesaCliente Engenharia Financeira: calcula antecipação composta. Se data_nova não antecede data_original, não há benefício financeiro.';

-- -----------------------------------------------------------------------------
-- 7. Postergação composta
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_calcular_postergacao_composta(
  p_valor_original numeric,
  p_data_original date,
  p_data_nova date,
  p_taxa_ano_pct numeric,
  p_base_tempo text default 'dias_365'
)
returns jsonb
language plpgsql
immutable
security invoker
set search_path = public
as $$
declare
  v_dias integer;
  v_valor_calculado numeric;
  v_acrescimo numeric;
  v_impacto_pct numeric;
  v_aplicavel boolean;
begin
  perform public.mesa_cliente_financeiro_assert_calculo_input(p_valor_original, p_taxa_ano_pct, p_base_tempo);

  if p_data_original is null then
    raise exception 'data_original é obrigatória'
      using errcode = '22023';
  end if;

  if p_data_nova is null then
    raise exception 'data_nova é obrigatória'
      using errcode = '22023';
  end if;

  v_dias := public.mesa_cliente_financeiro_dias_entre(p_data_original, p_data_nova);
  v_aplicavel := v_dias > 0 and p_taxa_ano_pct > 0 and p_valor_original > 0;

  if not v_aplicavel then
    v_valor_calculado := round(p_valor_original, 2);
    v_acrescimo := 0;
    v_impacto_pct := 0;
  else
    v_valor_calculado := public.mesa_cliente_financeiro_valor_futuro_composto(
      p_valor_original,
      p_taxa_ano_pct,
      v_dias,
      p_base_tempo
    );
    v_acrescimo := round((v_valor_calculado - p_valor_original)::numeric, 2);
    v_impacto_pct := round(((v_acrescimo / nullif(p_valor_original, 0)) * 100)::numeric, 6);
  end if;

  return jsonb_build_object(
    'tipo_operacao', 'postergacao',
    'metodo_calculo', 'composto',
    'base_tempo', p_base_tempo,
    'aplicavel', v_aplicavel,
    'valor_original', round(p_valor_original, 2),
    'valor_calculado', v_valor_calculado,
    'desconto_calculado', 0,
    'acrescimo_calculado', v_acrescimo,
    'economia_liquida', 0,
    'impacto_pct', v_impacto_pct,
    'dias_calculo', greatest(v_dias, 0),
    'taxa_ano_pct', p_taxa_ano_pct,
    'data_original', p_data_original,
    'data_nova', p_data_nova
  );
end;
$$;

comment on function public.mesa_cliente_financeiro_calcular_postergacao_composta(numeric, date, date, numeric, text) is
'MesaCliente Engenharia Financeira: calcula postergação composta. Se data_nova não é posterior à data_original, não há acréscimo financeiro.';

-- -----------------------------------------------------------------------------
-- 8. VPL de parcela futura pela data-base
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_calcular_vpl_parcela(
  p_valor_nominal numeric,
  p_data_base date,
  p_data_parcela date,
  p_taxa_ano_pct numeric,
  p_base_tempo text default 'dias_365'
)
returns jsonb
language plpgsql
immutable
security invoker
set search_path = public
as $$
declare
  v_dias integer;
  v_valor_presente numeric;
  v_desconto numeric;
  v_vpl_pct numeric;
  v_aplicavel boolean;
begin
  perform public.mesa_cliente_financeiro_assert_calculo_input(p_valor_nominal, p_taxa_ano_pct, p_base_tempo);

  if p_data_base is null then
    raise exception 'data_base é obrigatória'
      using errcode = '22023';
  end if;

  if p_data_parcela is null then
    raise exception 'data_parcela é obrigatória'
      using errcode = '22023';
  end if;

  v_dias := public.mesa_cliente_financeiro_dias_entre(p_data_base, p_data_parcela);
  v_aplicavel := v_dias > 0 and p_taxa_ano_pct > 0 and p_valor_nominal > 0;

  if not v_aplicavel then
    v_valor_presente := round(p_valor_nominal, 2);
    v_desconto := 0;
    v_vpl_pct := 0;
  else
    v_valor_presente := public.mesa_cliente_financeiro_valor_presente_composto(
      p_valor_nominal,
      p_taxa_ano_pct,
      v_dias,
      p_base_tempo
    );
    v_desconto := round((p_valor_nominal - v_valor_presente)::numeric, 2);
    v_vpl_pct := round(((v_desconto / nullif(p_valor_nominal, 0)) * 100)::numeric, 6);
  end if;

  return jsonb_build_object(
    'tipo_operacao', 'vpl_parcela',
    'metodo_calculo', 'composto',
    'base_tempo', p_base_tempo,
    'aplicavel', v_aplicavel,
    'valor_nominal', round(p_valor_nominal, 2),
    'valor_presente', v_valor_presente,
    'desconto_calculado', v_desconto,
    'vpl_pct', v_vpl_pct,
    'dias_calculo', greatest(v_dias, 0),
    'taxa_ano_pct', p_taxa_ano_pct,
    'data_base', p_data_base,
    'data_parcela', p_data_parcela
  );
end;
$$;

comment on function public.mesa_cliente_financeiro_calcular_vpl_parcela(numeric, date, date, numeric, text) is
'MesaCliente Engenharia Financeira: calcula VPL composto de uma parcela futura em relação à data-base. Cliente não deve receber este payload técnico.';

-- -----------------------------------------------------------------------------
-- 9. Revogar execução direta pública
-- -----------------------------------------------------------------------------

revoke all on function public.mesa_cliente_financeiro_assert_calculo_input(numeric, numeric, text) from public;
revoke all on function public.mesa_cliente_financeiro_dias_entre(date, date) from public;
revoke all on function public.mesa_cliente_financeiro_fator_composto(numeric, integer, text) from public;
revoke all on function public.mesa_cliente_financeiro_valor_presente_composto(numeric, numeric, integer, text) from public;
revoke all on function public.mesa_cliente_financeiro_valor_futuro_composto(numeric, numeric, integer, text) from public;
revoke all on function public.mesa_cliente_financeiro_calcular_antecipacao_composta(numeric, date, date, numeric, text) from public;
revoke all on function public.mesa_cliente_financeiro_calcular_postergacao_composta(numeric, date, date, numeric, text) from public;
revoke all on function public.mesa_cliente_financeiro_calcular_vpl_parcela(numeric, date, date, numeric, text) from public;

commit;
