-- MesaCliente Engenharia Financeira — Fase 4A: agenda financeira JSON-first
--
-- Protocolo obrigatório:
--   docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
--
-- Documento operacional:
--   docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md
--
-- Contrato canônico:
--   docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md
--
-- Decisão arquitetural:
--   docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md
--
-- Objetivo:
--   Criar a RPC oficial da Fase 4A para gerar agenda financeira normalizada
--   em JSON, sem persistir parcelas e sem criar operação financeira.
--
-- Escopo:
--   - Valida auth.uid().
--   - Valida usuário ativo, empresa/tenant, empreendimento, simulação e perfil.
--   - Resolve datas e normaliza parcelas em JSON.
--   - Classifica periodicidade simbólica como não negociável.
--   - Ignora/rejeita empresa_id soberano vindo do payload.
--   - Retorna payload administrativo, cliente_safe=false.
--
-- Fora do escopo:
--   - INSERT/UPDATE/DELETE em mesa_cliente_fluxo_parcelas.
--   - INSERT/UPDATE/DELETE em mesa_cliente_fluxo_operacoes.
--   - VPL, prêmio, comissão ou política interna.
--   - Frontend, parser, Worker, Make/n8n.
--
-- Regra de ouro:
--   4A pensa. 4B grava. 4C mostra para o cliente.

begin;

-- -----------------------------------------------------------------------------
-- 1. Pré-requisitos defensivos
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.corretores') is null then
    raise exception 'Tabela public.corretores não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.empreendimentos') is null then
    raise exception 'Tabela public.empreendimentos não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_simulacoes') is null then
    raise exception 'Tabela public.mesa_simulacoes não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_cliente_fluxo_parcelas') is null then
    raise exception 'Tabela public.mesa_cliente_fluxo_parcelas não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_cliente_fluxo_operacoes') is null then
    raise exception 'Tabela public.mesa_cliente_fluxo_operacoes não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.is_root()') is null then
    raise exception 'Função public.is_root() não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_assert_auth()') is null then
    raise exception 'Função public.mesa_cliente_assert_auth() não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_current_corretor_context()') is null then
    raise exception 'Função public.mesa_cliente_current_corretor_context() não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_can_admin_empresa(uuid)') is null then
    raise exception 'Função public.mesa_cliente_can_admin_empresa(uuid) não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_can_access_empresa(uuid)') is null then
    raise exception 'Função public.mesa_cliente_can_access_empresa(uuid) não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.mesa_cliente_assert_empreendimento_empresa(uuid,uuid)') is null then
    raise exception 'Função public.mesa_cliente_assert_empreendimento_empresa(uuid,uuid) não encontrada. Migração abortada.';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Helpers internos de normalização JSON-first
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_agenda_json_first_parse_numeric(
  p_value text
)
returns numeric
language plpgsql
immutable
set search_path = public
as $$
declare
  v text;
begin
  v := trim(coalesce(p_value, ''));

  if v = '' then
    return null;
  end if;

  if v ~ '^[-+]?[0-9]{1,3}(\.[0-9]{3})+(,[0-9]+)?$' then
    return replace(replace(v, '.', ''), ',', '.')::numeric;
  end if;

  if v ~ '^[-+]?[0-9]+,[0-9]+$' then
    return replace(v, ',', '.')::numeric;
  end if;

  if v ~ '^[-+]?[0-9]+(\.[0-9]+)?$' then
    return v::numeric;
  end if;

  raise exception 'Valor numérico inválido: %', p_value
    using errcode = '22023';
end;
$$;

comment on function public.mesa_cliente_agenda_json_first_parse_numeric(text) is
'MesaCliente Fase 4A: helper interno para normalizar valores numéricos do payload JSON-first.';

create or replace function public.mesa_cliente_agenda_json_first_parse_date(
  p_value text
)
returns date
language plpgsql
immutable
set search_path = public
as $$
declare
  v text;
  d date;
begin
  v := trim(coalesce(p_value, ''));

  if v = '' then
    return null;
  end if;

  if v ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    d := to_date(v, 'YYYY-MM-DD');
    if to_char(d, 'YYYY-MM-DD') = v then
      return d;
    end if;
  end if;

  if v ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' then
    d := to_date(v, 'DD/MM/YYYY');
    if to_char(d, 'DD/MM/YYYY') = v then
      return d;
    end if;
  end if;

  raise exception 'Data inválida: %', p_value
    using errcode = '22023';
end;
$$;

comment on function public.mesa_cliente_agenda_json_first_parse_date(text) is
'MesaCliente Fase 4A: helper interno para normalizar datas ISO ou DD/MM/YYYY do payload JSON-first.';

create or replace function public.mesa_cliente_agenda_json_first_last_day(
  p_year integer,
  p_month integer
)
returns integer
language sql
immutable
set search_path = public
as $$
  select extract(day from (date_trunc('month', make_date(p_year, p_month, 1)) + interval '1 month - 1 day'))::integer
$$;

comment on function public.mesa_cliente_agenda_json_first_last_day(integer, integer) is
'MesaCliente Fase 4A: helper interno para obter último dia válido de um mês.';

create or replace function public.mesa_cliente_agenda_json_first_grupo(
  p_grupo text
)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  v text;
begin
  v := lower(trim(coalesce(p_grupo, '')));
  v := translate(v, 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc');
  v := replace(replace(v, '-', '_'), ' ', '_');

  if v in ('entrada', 'sinal', 'ato', 'sinal_ato') then
    return 'entrada';
  elsif v in ('mensal', 'mensais', 'mensalidade', 'mensalidades') then
    return 'mensais';
  elsif v in ('intermediaria', 'intermediarias', 'intermediaria_anual', 'intermediarias_anuais') then
    return 'intermediarias';
  elsif v in ('anual', 'anuais') then
    return 'anuais';
  elsif v in ('chave', 'chaves') then
    return 'chaves';
  elsif v in ('financiamento', 'financiamento_bancario', 'saldo_financiamento') then
    return 'financiamento';
  elsif v in ('parcela_unica', 'unica', 'parcelaunica') then
    return 'parcela_unica';
  elsif v in ('periodicidade', 'periodicidade_simbolica', 'periodicidade_simbólica') then
    return 'periodicidade';
  end if;

  return null;
end;
$$;

comment on function public.mesa_cliente_agenda_json_first_grupo(text) is
'MesaCliente Fase 4A: helper interno para normalizar grupos financeiros do payload JSON-first.';

-- -----------------------------------------------------------------------------
-- 3. RPC oficial da Fase 4A JSON-first
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
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
  v_items jsonb;
  v_item jsonb;
  v_item_index integer := 0;
  v_seq integer;
  v_qtd integer;
  v_total_parcelas integer := 0;
  v_grupo text;
  v_grupo_raw text;
  v_descricao text;
  v_valor numeric;
  v_data_base date;
  v_data_final date;
  v_origem_data text;
  v_mes_ano text;
  v_mes integer;
  v_ano integer;
  v_day integer;
  v_last_day integer;
  v_flag_periodicidade text;
  v_flag_negociavel text;
  v_periodicidade boolean;
  v_negociavel boolean;
  v_motivos jsonb;
  v_agenda jsonb := '[]'::jsonb;
  v_warnings jsonb := '[]'::jsonb;
begin
  v_uid := public.mesa_cliente_assert_auth();

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

  if p_payload_tabela is null then
    p_payload_tabela := '{}'::jsonb;
  end if;

  if jsonb_typeof(p_payload_tabela) <> 'object' then
    raise exception 'payload_tabela deve ser um objeto JSON'
      using errcode = '22023';
  end if;

  select s.*
    into v_sim
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id;

  if v_sim.id is null then
    raise exception 'Simulação não encontrada'
      using errcode = 'P0002';
  end if;

  if v_sim.empresa_id is null then
    raise exception 'Simulação sem empresa_id'
      using errcode = '22023';
  end if;

  if v_sim.empreendimento_id is null then
    raise exception 'Simulação sem empreendimento_id'
      using errcode = '22023';
  end if;

  perform public.mesa_cliente_assert_empreendimento_empresa(v_sim.empresa_id, v_sim.empreendimento_id);

  if not public.mesa_cliente_can_access_empresa(v_sim.empresa_id) then
    raise exception 'Sem permissão para acessar a empresa da simulação'
      using errcode = '42501';
  end if;

  select *
    into v_ctx
  from public.mesa_cliente_current_corretor_context()
  limit 1;

  if not public.is_root() then
    if v_ctx.user_id is null then
      raise exception 'Usuário ativo não encontrado'
        using errcode = '42501';
    end if;

    if coalesce(v_ctx.ativo, false) is not true then
      raise exception 'Usuário inativo'
        using errcode = '42501';
    end if;

    if v_ctx.empresa_id is distinct from v_sim.empresa_id then
      raise exception 'Usuário não pertence à empresa da simulação'
        using errcode = '42501';
    end if;
  end if;

  v_is_admin := public.mesa_cliente_can_admin_empresa(v_sim.empresa_id);
  v_is_owner := v_ctx.corretor_id is not null and v_sim.corretor_id is not null and v_ctx.corretor_id = v_sim.corretor_id;

  if not (public.is_root() or v_is_admin or v_is_owner) then
    raise exception 'Perfil sem permissão para gerar agenda financeira desta simulação'
      using errcode = '42501';
  end if;

  if p_payload_tabela ? 'empresa_id'
     and nullif(p_payload_tabela->>'empresa_id', '') is not null
     and nullif(p_payload_tabela->>'empresa_id', '') <> v_sim.empresa_id::text then
    raise exception 'empresa_id do payload_tabela diverge da simulação e não é autoridade'
      using errcode = '42501';
  end if;

  if p_payload_tabela ? 'empreendimento_id'
     and nullif(p_payload_tabela->>'empreendimento_id', '') is not null
     and nullif(p_payload_tabela->>'empreendimento_id', '') <> v_sim.empreendimento_id::text then
    raise exception 'empreendimento_id do payload_tabela diverge da simulação e não é autoridade'
      using errcode = '42501';
  end if;

  v_items := case jsonb_typeof(p_fluxo_json)
    when 'array' then p_fluxo_json
    when 'object' then coalesce(
      p_fluxo_json->'parcelas',
      p_fluxo_json->'agenda',
      p_fluxo_json->'fluxo',
      p_fluxo_json->'itens',
      p_fluxo_json->'pagamentos'
    )
    else null
  end;

  if v_items is null or jsonb_typeof(v_items) <> 'array' then
    raise exception 'fluxo_json deve ser um array ou objeto contendo parcelas/agenda/fluxo/itens/pagamentos'
      using errcode = '22023';
  end if;

  if jsonb_array_length(v_items) = 0 then
    raise exception 'fluxo_json não pode ser vazio'
      using errcode = '22023';
  end if;

  if jsonb_array_length(v_items) > 500 then
    raise exception 'Limite máximo de 500 itens de fluxo por chamada'
      using errcode = '22023';
  end if;

  for v_item in select value from jsonb_array_elements(v_items)
  loop
    v_item_index := v_item_index + 1;

    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'Item % do fluxo_json deve ser um objeto JSON', v_item_index
        using errcode = '22023';
    end if;

    if v_item ? 'empresa_id'
       and nullif(v_item->>'empresa_id', '') is not null
       and nullif(v_item->>'empresa_id', '') <> v_sim.empresa_id::text then
      raise exception 'empresa_id do item % diverge da simulação e não é autoridade', v_item_index
        using errcode = '42501';
    end if;

    v_grupo_raw := coalesce(v_item->>'grupo', v_item->>'tipo', v_item->>'categoria');
    v_grupo := public.mesa_cliente_agenda_json_first_grupo(v_grupo_raw);

    if v_grupo is null then
      raise exception 'grupo inválido no item %: %', v_item_index, coalesce(v_grupo_raw, '<nulo>')
        using errcode = '22023';
    end if;

    v_qtd := coalesce(
      nullif(v_item->>'quantidade', '')::integer,
      nullif(v_item->>'qtd', '')::integer,
      nullif(v_item->>'parcelas', '')::integer,
      nullif(v_item->>'numero_parcelas', '')::integer,
      1
    );

    if v_qtd < 1 or v_qtd > 240 then
      raise exception 'quantidade inválida no item %', v_item_index
        using errcode = '22023';
    end if;

    v_total_parcelas := v_total_parcelas + v_qtd;

    if v_total_parcelas > 1000 then
      raise exception 'Limite máximo de 1000 parcelas normalizadas por chamada'
        using errcode = '22023';
    end if;

    v_valor := public.mesa_cliente_agenda_json_first_parse_numeric(
      coalesce(
        v_item->>'valor',
        v_item->>'valor_parcela',
        v_item->>'valor_total',
        v_item->>'amount',
        case when v_grupo = 'periodicidade' then '0' else null end
      )
    );

    if v_valor is null then
      raise exception 'valor é obrigatório no item %', v_item_index
        using errcode = '22023';
    end if;

    if v_valor < 0 then
      raise exception 'valor negativo no item %', v_item_index
        using errcode = '22023';
    end if;

    v_descricao := coalesce(nullif(v_item->>'descricao', ''), nullif(v_item->>'label', ''), v_grupo);
    v_flag_periodicidade := lower(trim(coalesce(v_item->>'eh_periodicidade_simbolica', v_item->>'periodicidade_simbolica', '')));
    v_flag_negociavel := lower(trim(coalesce(v_item->>'negociavel', '')));

    if v_grupo = 'periodicidade'
       and v_flag_periodicidade in ('false', 'f', '0', 'nao', 'não', 'no') then
      raise exception 'periodicidade simbólica fraudada no item %', v_item_index
        using errcode = '22023';
    end if;

    if v_grupo = 'periodicidade'
       and v_flag_negociavel in ('true', 't', '1', 'sim', 'yes') then
      raise exception 'periodicidade simbólica não pode ser marcada como negociável no item %', v_item_index
        using errcode = '22023';
    end if;

    v_periodicidade :=
      v_grupo = 'periodicidade'
      or v_flag_periodicidade in ('true', 't', '1', 'sim', 'yes');

    v_negociavel := not v_periodicidade;
    v_motivos := case
      when v_periodicidade then jsonb_build_array('periodicidade_simbolica_nao_negociavel')
      else '[]'::jsonb
    end;

    v_data_base := public.mesa_cliente_agenda_json_first_parse_date(
      coalesce(
        v_item->>'data',
        v_item->>'data_vencimento',
        v_item->>'vencimento',
        v_item->>'data_original',
        v_item->>'data_parcela',
        v_item->>'dt_vencimento'
      )
    );

    if v_data_base is not null then
      v_origem_data := 'data_oficial';
    else
      v_origem_data := null;
      v_mes_ano := nullif(coalesce(v_item->>'mes_ano', v_item->>'mesAno', v_item->>'competencia'), '');
      v_mes := null;
      v_ano := null;

      if v_mes_ano is not null and v_mes_ano ~ '^[0-9]{2}/[0-9]{4}$' then
        v_mes := substring(v_mes_ano from 1 for 2)::integer;
        v_ano := substring(v_mes_ano from 4 for 4)::integer;
      elsif v_mes_ano is not null and v_mes_ano ~ '^[0-9]{4}-[0-9]{2}$' then
        v_ano := substring(v_mes_ano from 1 for 4)::integer;
        v_mes := substring(v_mes_ano from 6 for 2)::integer;
      else
        v_mes := nullif(coalesce(v_item->>'mes', v_item->>'month'), '')::integer;
        v_ano := nullif(coalesce(v_item->>'ano', v_item->>'year'), '')::integer;
      end if;

      if v_mes is not null or v_ano is not null then
        if v_mes is null or v_ano is null or v_mes < 1 or v_mes > 12 or v_ano < 1900 or v_ano > 2200 then
          raise exception 'mês/ano inválido no item %', v_item_index
            using errcode = '22023';
        end if;

        v_day := extract(day from p_data_ato)::integer;
        v_last_day := public.mesa_cliente_agenda_json_first_last_day(v_ano, v_mes);
        v_data_base := make_date(v_ano, v_mes, least(v_day, v_last_day));
        v_origem_data := 'tabela_comercial_mes';
      elsif nullif(v_item->>'dias_offset', '') is not null or nullif(v_item->>'offset_dias', '') is not null then
        v_data_base := p_data_ato + coalesce(nullif(v_item->>'dias_offset', '')::integer, nullif(v_item->>'offset_dias', '')::integer);
        v_origem_data := 'offset_data_ato';
      else
        v_data_base := p_data_ato + ((v_item_index - 1) || ' months')::interval;
        v_origem_data := 'fallback_data_ato';
      end if;
    end if;

    for v_seq in 1..v_qtd loop
      v_data_final := (v_data_base + ((v_seq - 1) || ' months')::interval)::date;

      v_agenda := v_agenda || jsonb_build_array(jsonb_build_object(
        'ordem', jsonb_array_length(v_agenda) + 1,
        'item_origem_index', v_item_index,
        'parcela_numero', v_seq,
        'parcelas_total_item', v_qtd,
        'grupo', v_grupo,
        'descricao', v_descricao,
        'valor', round(v_valor, 2),
        'data_vencimento', v_data_final,
        'origem_data', v_origem_data,
        'eh_periodicidade_simbolica', v_periodicidade,
        'negociavel', v_negociavel,
        'motivos_bloqueio', v_motivos
      ));
    end loop;
  end loop;

  if p_payload_tabela ? 'empresa_id' then
    v_warnings := v_warnings || jsonb_build_array('empresa_id_payload_nao_soberano_validado_contra_simulacao');
  end if;

  return jsonb_build_object(
    'ok', true,
    'fase', '4A_JSON_FIRST',
    'visao', 'administrativa',
    'cliente_safe', false,
    'persistencia', false,
    'dml_financeiro', false,
    'simulacao_id', v_sim.id,
    'empresa_id', v_sim.empresa_id,
    'empreendimento_id', v_sim.empreendimento_id,
    'corretor_id', v_sim.corretor_id,
    'data_ato', p_data_ato,
    'totais', jsonb_build_object(
      'qtd_itens_origem', jsonb_array_length(v_items),
      'qtd_parcelas_normalizadas', jsonb_array_length(v_agenda),
      'valor_total_agenda', coalesce((select sum((x.value->>'valor')::numeric) from jsonb_array_elements(v_agenda) x), 0)
    ),
    'agenda', v_agenda,
    'warnings', v_warnings
  );
end;
$$;

comment on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) is
'MesaCliente Fase 4A: gera agenda financeira administrativa em JSON, sem persistir parcelas/operações e sem expor VPL, prêmio, comissão ou política interna.';

-- -----------------------------------------------------------------------------
-- 4. Grants restritos
-- -----------------------------------------------------------------------------

revoke all on function public.mesa_cliente_agenda_json_first_parse_numeric(text) from public;
revoke all on function public.mesa_cliente_agenda_json_first_parse_numeric(text) from anon;
revoke all on function public.mesa_cliente_agenda_json_first_parse_numeric(text) from authenticated;

revoke all on function public.mesa_cliente_agenda_json_first_parse_date(text) from public;
revoke all on function public.mesa_cliente_agenda_json_first_parse_date(text) from anon;
revoke all on function public.mesa_cliente_agenda_json_first_parse_date(text) from authenticated;

revoke all on function public.mesa_cliente_agenda_json_first_last_day(integer, integer) from public;
revoke all on function public.mesa_cliente_agenda_json_first_last_day(integer, integer) from anon;
revoke all on function public.mesa_cliente_agenda_json_first_last_day(integer, integer) from authenticated;

revoke all on function public.mesa_cliente_agenda_json_first_grupo(text) from public;
revoke all on function public.mesa_cliente_agenda_json_first_grupo(text) from anon;
revoke all on function public.mesa_cliente_agenda_json_first_grupo(text) from authenticated;

revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) from public;
revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) from anon;
grant execute on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) to authenticated;

commit;
