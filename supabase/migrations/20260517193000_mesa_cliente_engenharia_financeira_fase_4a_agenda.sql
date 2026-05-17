-- FECH.AI — MesaCliente — Engenharia Financeira
-- Fase 4A: RPC segura para gerar agenda financeira de parcelas
--
-- Escopo estrito desta migration:
--   - Não altera frontend.
--   - Não altera parser.
--   - Não altera Worker/Make/n8n.
--   - Não altera motor financeiro/simulação/confirmacão fora da agenda.
--   - Não cria regra hardcoded no client.
--   - Não confia em empresa_id soberano vindo do frontend.
--   - Não expõe VPL, prêmio, comissão ou política para cliente-safe.
--   - Não concede EXECUTE para anon.
--
-- Contrato DevSecOps:
--   - SECURITY DEFINER.
--   - search_path fixo em public.
--   - auth.uid() obrigatório.
--   - valida usuário ativo.
--   - valida empresa/tenant.
--   - valida empreendimento.
--   - valida simulação.
--   - valida perfil.
--   - grants restritos para authenticated.

begin;

create or replace function public.mesa_cliente_resolver_data_parcela(
  p_data_ato date,
  p_item jsonb,
  p_payload_tabela jsonb default '{}'::jsonb,
  p_grupo text default null,
  p_indice integer default 1
)
returns table(
  data_resolvida date,
  origem_data mesa_financeira_origem_data,
  regra_data text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_txt text;
  v_mes integer;
  v_ano integer;
  v_dia integer;
  v_ultimo_dia integer;
  v_data_financiamento date;
  v_chaves_dias integer;
  v_grupo text := lower(coalesce(p_grupo, p_item->>'grupo', p_item->>'tipo', ''));
begin
  if p_data_ato is null then
    raise exception 'DATA_ATO_REQUIRED' using errcode = '22023';
  end if;

  -- 1) Data oficial completa prevalece.
  v_txt := nullif(trim(coalesce(
    p_item->>'data_oficial',
    p_item->>'data_original',
    p_item->>'data_vencimento',
    p_item->>'data',
    p_item->>'vencimento'
  )), '');

  if v_txt is not null then
    if v_txt ~ '^\d{4}-\d{2}-\d{2}$' then
      data_resolvida := v_txt::date;
      origem_data := 'tabela_oficial'::mesa_financeira_origem_data;
      regra_data := 'data completa informada na tabela';
      return next;
      return;
    elsif v_txt ~ '^\d{2}/\d{2}/\d{4}$' then
      data_resolvida := to_date(v_txt, 'DD/MM/YYYY');
      origem_data := 'tabela_oficial'::mesa_financeira_origem_data;
      regra_data := 'data completa informada na tabela em DD/MM/YYYY';
      return next;
      return;
    elsif v_txt ~ '^\d{2}/\d{4}$' then
      v_mes := split_part(v_txt, '/', 1)::integer;
      v_ano := split_part(v_txt, '/', 2)::integer;
      v_dia := extract(day from p_data_ato)::integer;
      v_ultimo_dia := extract(day from (date_trunc('month', make_date(v_ano, v_mes, 1)) + interval '1 month - 1 day'))::integer;
      data_resolvida := make_date(v_ano, v_mes, least(v_dia, v_ultimo_dia));
      origem_data := 'tabela_comercial_mes'::mesa_financeira_origem_data;
      regra_data := 'mês/ano da tabela com dia do ato; se inválido, último dia do mês';
      return next;
      return;
    elsif v_txt ~ '^\d{4}-\d{2}$' then
      v_ano := split_part(v_txt, '-', 1)::integer;
      v_mes := split_part(v_txt, '-', 2)::integer;
      v_dia := extract(day from p_data_ato)::integer;
      v_ultimo_dia := extract(day from (date_trunc('month', make_date(v_ano, v_mes, 1)) + interval '1 month - 1 day'))::integer;
      data_resolvida := make_date(v_ano, v_mes, least(v_dia, v_ultimo_dia));
      origem_data := 'tabela_comercial_mes'::mesa_financeira_origem_data;
      regra_data := 'ano/mês da tabela com dia do ato; se inválido, último dia do mês';
      return next;
      return;
    end if;
  end if;

  -- 2) Campo específico mês/ano, quando separado da data.
  v_txt := nullif(trim(coalesce(p_item->>'mes_ano', p_item->>'mes_referencia', p_item->>'competencia')), '');
  if v_txt is not null then
    if v_txt ~ '^\d{2}/\d{4}$' then
      v_mes := split_part(v_txt, '/', 1)::integer;
      v_ano := split_part(v_txt, '/', 2)::integer;
    elsif v_txt ~ '^\d{4}-\d{2}$' then
      v_ano := split_part(v_txt, '-', 1)::integer;
      v_mes := split_part(v_txt, '-', 2)::integer;
    else
      raise exception 'MES_ANO_INVALIDO: %', v_txt using errcode = '22023';
    end if;

    v_dia := extract(day from p_data_ato)::integer;
    v_ultimo_dia := extract(day from (date_trunc('month', make_date(v_ano, v_mes, 1)) + interval '1 month - 1 day'))::integer;
    data_resolvida := make_date(v_ano, v_mes, least(v_dia, v_ultimo_dia));
    origem_data := 'tabela_comercial_mes'::mesa_financeira_origem_data;
    regra_data := 'mês/ano comercial com dia do ato; se inválido, último dia do mês';
    return next;
    return;
  end if;

  -- 3) Chaves/parcela única por cabeçalho: 30/60 dias antes do financiamento, quando houver base.
  if v_grupo in ('chaves', 'parcela_unica', 'parcela única') then
    v_txt := nullif(trim(coalesce(
      p_payload_tabela->>'data_financiamento',
      p_payload_tabela->>'financiamento_data',
      p_payload_tabela->'cabecalho'->>'data_financiamento',
      p_payload_tabela->'header'->>'data_financiamento'
    )), '');

    if v_txt is not null and v_txt ~ '^\d{4}-\d{2}-\d{2}$' then
      v_data_financiamento := v_txt::date;
    elsif v_txt is not null and v_txt ~ '^\d{2}/\d{2}/\d{4}$' then
      v_data_financiamento := to_date(v_txt, 'DD/MM/YYYY');
    end if;

    v_chaves_dias := coalesce(
      nullif(p_payload_tabela->>'chaves_dias_antes_financiamento', '')::integer,
      nullif(p_payload_tabela->'cabecalho'->>'chaves_dias_antes_financiamento', '')::integer,
      nullif(p_payload_tabela->'header'->>'chaves_dias_antes_financiamento', '')::integer,
      nullif(p_item->>'dias_antes_financiamento', '')::integer
    );

    if v_data_financiamento is not null and v_chaves_dias in (30, 60) then
      data_resolvida := v_data_financiamento - v_chaves_dias;
      origem_data := case when v_chaves_dias = 60 then 'cabecalho_60_dias' else 'cabecalho_30_dias' end::mesa_financeira_origem_data;
      regra_data := concat('chaves calculada ', v_chaves_dias, ' dias antes do financiamento informado no cabeçalho');
      return next;
      return;
    end if;
  end if;

  -- 4) Estimativa conservadora pela data do ato, apenas para montar a espinha dorsal da agenda.
  data_resolvida := (p_data_ato + make_interval(months => greatest(coalesce(p_indice, 1), 1) - 1))::date;
  origem_data := 'estimada'::mesa_financeira_origem_data;
  regra_data := 'estimada pela data do ato e ordem da parcela; deve ser revisada quando a tabela trouxer data oficial';
  return next;
end;
$$;

comment on function public.mesa_cliente_resolver_data_parcela(date, jsonb, jsonb, text, integer)
is 'Resolve data da parcela para Engenharia Financeira do MesaCliente. Ordem: data oficial > mês/ano com dia do ato > cabeçalho chaves > estimada.';

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
  v_ctx record;
  v_sim record;
  v_items jsonb;
  v_item jsonb;
  v_idx integer := 0;
  v_i integer;
  v_qtd integer;
  v_grupo_raw text;
  v_grupo text;
  v_descricao text;
  v_valor_total numeric;
  v_valor_parcela numeric;
  v_data_base date;
  v_origem mesa_financeira_origem_data;
  v_regra text;
  v_interval_months integer;
  v_eh_periodicidade boolean;
  v_pode_vpl boolean;
  v_pode_antecipacao boolean;
  v_pode_postergacao boolean;
  v_inseridos integer := 0;
  v_can_operate boolean := false;
begin
  v_uid := public.mesa_cliente_assert_auth();

  if p_simulacao_id is null then
    raise exception 'SIMULACAO_REQUIRED' using errcode = '22023';
  end if;

  if p_data_ato is null then
    raise exception 'DATA_ATO_REQUIRED' using errcode = '22023';
  end if;

  if p_fluxo_json is null then
    raise exception 'FLUXO_JSON_REQUIRED' using errcode = '22023';
  end if;

  if p_payload_tabela is null then
    p_payload_tabela := '{}'::jsonb;
  end if;

  select * into v_ctx
  from public.mesa_cliente_current_corretor_context()
  limit 1;

  if not coalesce(public.is_root(), false) and (v_ctx.user_id is null or coalesce(v_ctx.ativo, false) = false) then
    raise exception 'CORRETOR_ATIVO_REQUIRED' using errcode = '42501';
  end if;

  select s.id, s.empresa_id, s.empreendimento_id, s.corretor_id, s.unidade_estoque_id, s.status
    into v_sim
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id
  limit 1;

  if v_sim.id is null then
    raise exception 'SIMULACAO_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_sim.empreendimento_id is null then
    raise exception 'SIMULACAO_SEM_EMPREENDIMENTO' using errcode = '22023';
  end if;

  perform public.mesa_cliente_assert_empreendimento_empresa(v_sim.empresa_id, v_sim.empreendimento_id);

  if not public.mesa_cliente_can_access_empresa(v_sim.empresa_id) then
    raise exception 'TENANT_FORBIDDEN' using errcode = '42501';
  end if;

  v_can_operate := coalesce(public.is_root(), false)
    or coalesce(v_ctx.is_admin_local, false)
    or coalesce(v_ctx.is_gestor, false)
    or coalesce(v_ctx.role, '') in ('admin_global', 'admin', 'admin_local', 'gestor', 'coordenador')
    or (v_sim.corretor_id is not null and v_sim.corretor_id = v_ctx.corretor_id);

  if not coalesce(v_can_operate, false) then
    raise exception 'PERFIL_SEM_PERMISSAO_AGENDA' using errcode = '42501';
  end if;

  v_items := case
    when jsonb_typeof(p_fluxo_json) = 'array' then p_fluxo_json
    when jsonb_typeof(p_fluxo_json) = 'object' and jsonb_typeof(p_fluxo_json->'parcelas') = 'array' then p_fluxo_json->'parcelas'
    when jsonb_typeof(p_fluxo_json) = 'object' and jsonb_typeof(p_fluxo_json->'fluxo') = 'array' then p_fluxo_json->'fluxo'
    when jsonb_typeof(p_fluxo_json) = 'object' and jsonb_typeof(p_fluxo_json->'cards') = 'array' then p_fluxo_json->'cards'
    else null
  end;

  if v_items is null or jsonb_array_length(v_items) = 0 then
    raise exception 'FLUXO_ARRAY_EMPTY_OR_INVALID' using errcode = '22023';
  end if;

  delete from public.mesa_cliente_fluxo_parcelas
  where empresa_id = v_sim.empresa_id
    and simulacao_id = p_simulacao_id;

  for v_item in select value from jsonb_array_elements(v_items) loop
    v_idx := v_idx + 1;

    v_grupo_raw := lower(trim(coalesce(v_item->>'grupo', v_item->>'tipo', v_item->>'categoria', 'outro')));
    v_grupo := case
      when v_grupo_raw in ('entrada', 'sinal', 'ato') then 'ato'
      when v_grupo_raw in ('complemento', 'complementos', 'curto_prazo', '30_60_90') then 'complemento'
      when v_grupo_raw in ('mensal', 'mensais', 'mensal(is)') then 'mensal'
      when v_grupo_raw in ('anual', 'anuais', 'intermediaria', 'intermediarias', 'intermediária', 'intermediárias') then 'anual'
      when v_grupo_raw in ('chaves', 'parcela_unica', 'parcela única', 'unica', 'única') then 'chaves'
      when v_grupo_raw in ('financiamento', 'financiamento_bancario', 'financiamento bancário') then 'financiamento'
      when v_grupo_raw in ('periodicidade', 'periodicidade_simbolica', 'periodicidade simbólica') then 'periodicidade'
      else 'outro'
    end;

    v_eh_periodicidade := v_grupo = 'periodicidade'
      or coalesce((v_item->>'eh_periodicidade_simbolica')::boolean, false);

    v_qtd := greatest(coalesce(
      nullif(v_item->>'quantidade', '')::integer,
      nullif(v_item->>'qtd', '')::integer,
      nullif(v_item->>'parcelas', '')::integer,
      1
    ), 1);

    v_valor_total := greatest(coalesce(
      nullif(v_item->>'valor_original', '')::numeric,
      nullif(v_item->>'valor_atual', '')::numeric,
      nullif(v_item->>'valor_total', '')::numeric,
      nullif(v_item->>'total', '')::numeric,
      nullif(v_item->>'valor', '')::numeric,
      0
    ), 0);

    v_valor_parcela := greatest(coalesce(
      nullif(v_item->>'valor_parcela', '')::numeric,
      nullif(v_item->>'valor_each', '')::numeric,
      nullif(v_item->>'each', '')::numeric,
      case when v_qtd > 0 then round(v_valor_total / v_qtd, 2) else v_valor_total end
    ), 0);

    v_descricao := left(coalesce(nullif(trim(v_item->>'descricao'), ''), initcap(v_grupo)), 160);

    select r.data_resolvida, r.origem_data, r.regra_data
      into v_data_base, v_origem, v_regra
    from public.mesa_cliente_resolver_data_parcela(p_data_ato, v_item, p_payload_tabela, v_grupo, v_idx) r
    limit 1;

    v_interval_months := case when v_grupo = 'anual' then 12 else 1 end;

    for v_i in 1..v_qtd loop
      v_pode_vpl := not v_eh_periodicidade and v_grupo in ('mensal', 'anual', 'chaves', 'financiamento');
      v_pode_antecipacao := not v_eh_periodicidade and v_grupo in ('mensal', 'anual', 'chaves', 'financiamento');
      v_pode_postergacao := not v_eh_periodicidade and v_grupo in ('ato', 'complemento', 'mensal', 'anual', 'chaves');

      insert into public.mesa_cliente_fluxo_parcelas (
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
        v_sim.empresa_id,
        p_simulacao_id,
        v_sim.empreendimento_id,
        v_sim.unidade_estoque_id,
        v_grupo,
        case when v_qtd > 1 then left(v_descricao || ' ' || v_i::text || '/' || v_qtd::text, 160) else v_descricao end,
        v_valor_parcela,
        v_valor_parcela,
        (v_data_base + make_interval(months => ((v_i - 1) * v_interval_months)))::date,
        (v_data_base + make_interval(months => ((v_i - 1) * v_interval_months)))::date,
        v_origem,
        v_regra,
        (v_idx * 1000) + v_i,
        v_eh_periodicidade,
        v_pode_vpl,
        v_pode_antecipacao,
        v_pode_postergacao,
        jsonb_build_object(
          'fase', '4A',
          'source_index', v_idx,
          'parcela_numero', v_i,
          'quantidade_origem', v_qtd,
          'cliente_safe', false
        ),
        v_uid,
        v_uid
      );

      v_inseridos := v_inseridos + 1;
    end loop;
  end loop;

  return jsonb_build_object(
    'ok', true,
    'fase', '4A',
    'simulacao_id', p_simulacao_id,
    'empresa_id', v_sim.empresa_id,
    'empreendimento_id', v_sim.empreendimento_id,
    'data_ato', p_data_ato,
    'parcelas_geradas', v_inseridos,
    'cliente_safe', false,
    'mensagem', 'Agenda financeira gerada com validação de auth, tenant, empreendimento, simulação e perfil.'
  );
end;
$$;

comment on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb)
is 'Fase 4A Engenharia Financeira: gera agenda financeira datada por simulação. RPC interna/admin/corretor dono, não cliente-safe.';

revoke all on function public.mesa_cliente_resolver_data_parcela(date, jsonb, jsonb, text, integer) from public;
revoke all on function public.mesa_cliente_resolver_data_parcela(date, jsonb, jsonb, text, integer) from anon;
revoke all on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) from public;
revoke all on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) from anon;

grant execute on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) to authenticated;

commit;
