-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5B
-- Registro administrativo de operação financeira sobre agenda persistida.
--
-- Contrato canônico:
--   docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md
--
-- Escopo da 5B:
--   - adiciona vínculo forte da operação com a agenda persistida;
--   - adiciona checksum canônico para idempotência calculada no banco;
--   - cria RPC administrativa para registrar operação financeira simulada;
--   - permite INSERT somente em mesa_cliente_fluxo_operacoes;
--   - não altera agenda;
--   - não altera parcelas;
--   - não confirma/cancela operação final.

alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists agenda_id uuid null references public.mesa_cliente_agendas_financeiras(id) on delete set null;

alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists checksum_operacao text null;

create index if not exists idx_mcfo_empresa_simulacao_agenda_status
on public.mesa_cliente_fluxo_operacoes (empresa_id, simulacao_id, agenda_id, status_operacao, created_at desc);

create index if not exists idx_mcfo_agenda_parcela_status
on public.mesa_cliente_fluxo_operacoes (agenda_id, parcela_origem_id, status_operacao, created_at desc);

create unique index if not exists uq_mcfo_checksum_operacao_ativo
on public.mesa_cliente_fluxo_operacoes (empresa_id, checksum_operacao)
where checksum_operacao is not null
  and status_operacao in ('simulada', 'confirmada');

comment on column public.mesa_cliente_fluxo_operacoes.agenda_id
is 'FECH.AI MesaCliente 5B: vínculo direto da operação financeira com a agenda persistida de origem.';

comment on column public.mesa_cliente_fluxo_operacoes.checksum_operacao
is 'FECH.AI MesaCliente 5B: checksum canônico calculado no banco para idempotência da operação financeira ativa.';

create or replace function public.mesa_cliente_registrar_operacao_financeira_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid,
  p_tipo_operacao text,
  p_parcela_id uuid,
  p_data_referencia date default current_date,
  p_data_destino date default null,
  p_valor_operacao numeric default null,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_auth_uid uuid;
  v_corretor public.corretores%rowtype;
  v_simulacao public.mesa_simulacoes%rowtype;
  v_agenda public.mesa_cliente_agendas_financeiras%rowtype;
  v_parcela public.mesa_cliente_fluxo_parcelas%rowtype;
  v_politica public.mesa_cliente_politicas_financeiras%rowtype;
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;
  v_existente public.mesa_cliente_fluxo_operacoes%rowtype;
  v_premio record;

  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_tipo_operacao text := lower(coalesce(nullif(trim(p_tipo_operacao), ''), ''));
  v_grupo_raw text;
  v_grupo_norm text;
  v_grupo_db text;
  v_forbidden_keys text[] := array[
    'empresa_id',
    'empreendimento_id',
    'corretor_id',
    'politica_id',
    'taxa_ano_pct',
    'taxa_antecipacao_ano_pct',
    'taxa_postergacao_ano_pct',
    'base_tempo',
    'metodo_calculo',
    'status_operacao',
    'confirmado',
    'confirmado_por',
    'confirmado_em',
    'visivel_cliente',
    'checksum_operacao',
    'idempotency_key'
  ];
  v_forbidden_key text;

  v_valor_solicitado numeric;
  v_valor_operacao_validado numeric;
  v_vpl_aplicado_pct numeric;
  v_data_operacao date;
  v_data_origem date;
  v_dias_calculo integer;
  v_taxa_ano_pct numeric := 0;
  v_valor_calculado numeric := 0;
  v_desconto_calculado numeric := 0;
  v_acrescimo_calculado numeric := 0;
  v_economia_liquida numeric := 0;
  v_impacto_pct numeric := 0;
  v_status_premio text := null;
  v_premio_corretor_pct numeric := null;
  v_calculo_motor jsonb := '{}'::jsonb;
  v_metadata jsonb := '{}'::jsonb;
  v_checksum text;
  v_idempotente boolean := false;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: usuário autenticado obrigatório para registrar operação financeira.';
  end if;

  if p_simulacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_simulacao_id é obrigatório.';
  end if;

  if p_agenda_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_agenda_id é obrigatório.';
  end if;

  if p_parcela_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_parcela_id é obrigatório.';
  end if;

  if p_data_referencia is null then
    raise exception using
      errcode = '22023',
      message = 'p_data_referencia é obrigatório.';
  end if;

  if jsonb_typeof(v_params) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'p_parametros deve ser um objeto JSON.';
  end if;

  if v_tipo_operacao not in ('antecipacao', 'postergacao', 'vpl') then
    raise exception using
      errcode = '22023',
      message = 'Tipo de operação inválido para registro financeiro 5B.';
  end if;

  foreach v_forbidden_key in array v_forbidden_keys loop
    if v_params ? v_forbidden_key then
      raise exception using
        errcode = '42501',
        message = format('%s não pode ser enviado como autoridade pelo frontend.', v_forbidden_key);
    end if;
  end loop;

  v_valor_solicitado := p_valor_operacao;

  if v_valor_solicitado is not null and v_valor_solicitado < 0 then
    raise exception using
      errcode = '22023',
      message = 'Valor da operação financeira não pode ser negativo.';
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

  if not found then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: corretor ativo não encontrado para auth.uid().' ;
  end if;

  select s.*
    into v_simulacao
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id
  limit 1;

  if not found then
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
      message = 'Acesso negado: perfil sem permissão para registrar operação financeira administrativa.';
  end if;

  select a.*
    into v_agenda
  from public.mesa_cliente_agendas_financeiras a
  where a.id = p_agenda_id
    and a.simulacao_id = v_simulacao.id
    and a.empresa_id = v_simulacao.empresa_id
    and a.empreendimento_id = v_simulacao.empreendimento_id
    and a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
  for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Agenda financeira ativa não encontrada para a simulação.';
  end if;

  select fp.*
    into v_parcela
  from public.mesa_cliente_fluxo_parcelas fp
  where fp.id = p_parcela_id
    and fp.agenda_id = v_agenda.id
    and fp.simulacao_id = v_simulacao.id
    and fp.empresa_id = v_simulacao.empresa_id
  limit 1
  for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Parcela financeira não encontrada na agenda informada.';
  end if;

  if coalesce(v_parcela.eh_periodicidade_simbolica, false) then
    raise exception using
      errcode = '22023',
      message = 'Parcela de periodicidade simbólica não pode receber operação financeira.';
  end if;

  if coalesce(v_parcela.valor_atual, 0) <= 0 then
    raise exception using
      errcode = '22023',
      message = 'Parcela sem valor financeiro positivo não pode receber operação.';
  end if;

  if v_parcela.data_atual is null then
    raise exception using
      errcode = '22023',
      message = 'Parcela sem data financeira não pode receber operação.';
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

  if not found then
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

  v_grupo_raw := lower(coalesce(v_parcela.grupo::text, ''));

  v_grupo_norm := case
    when v_grupo_raw in ('financiamento', 'financiamento_bancario', 'financiamento bancário') then 'financiamento'
    when v_grupo_raw in ('chaves', 'chave') then 'chaves'
    when v_grupo_raw in ('anual', 'anuais', 'intermediaria', 'intermediarias', 'intermediária', 'intermediárias') then 'anuais'
    when v_grupo_raw in ('mensal', 'mensais') then 'mensais'
    else v_grupo_raw
  end;

  v_grupo_db := case
    when v_grupo_norm = 'anuais' then 'anual'
    when v_grupo_norm = 'mensais' then 'mensal'
    when v_grupo_norm in ('financiamento', 'chaves', 'entrada', 'ato', 'complemento', 'unica', 'periodicidade', 'outros') then v_grupo_norm
    else 'outros'
  end;

  if v_tipo_operacao = 'antecipacao' then
    if not coalesce(v_parcela.pode_receber_antecipacao, false) then
      raise exception using errcode = '22023', message = 'Parcela não é elegível para antecipação.';
    end if;

    if v_parcela.data_atual <= p_data_referencia then
      raise exception using errcode = '22023', message = 'Antecipação exige parcela futura em relação à data de referência.';
    end if;

    if not (
      (v_grupo_norm = 'financiamento' and coalesce(v_politica.permite_antecipacao_financiamento, false))
      or (v_grupo_norm = 'chaves' and coalesce(v_politica.permite_antecipacao_chaves, false))
      or (v_grupo_norm = 'anuais' and coalesce(v_politica.permite_antecipacao_anuais, false))
      or (v_grupo_norm = 'mensais' and coalesce(v_politica.permite_antecipacao_mensais, false))
    ) then
      raise exception using errcode = '22023', message = 'Política financeira não permite antecipação para o grupo da parcela.';
    end if;

    v_data_origem := v_parcela.data_atual;
    v_data_operacao := p_data_referencia;
    v_dias_calculo := greatest((v_data_origem - v_data_operacao), 0)::integer;
    v_taxa_ano_pct := coalesce(v_politica.taxa_antecipacao_ano_pct, 0);
    v_valor_operacao_validado := least(coalesce(v_valor_solicitado, v_parcela.valor_atual), v_parcela.valor_atual);

    if v_valor_operacao_validado <= 0 then
      raise exception using errcode = '22023', message = 'Valor de antecipação deve ser maior que zero.';
    end if;

    v_valor_calculado := public.mesa_cliente_financeiro_valor_presente_composto(
      v_valor_operacao_validado,
      v_taxa_ano_pct,
      v_dias_calculo,
      v_politica.base_tempo::text
    );
    v_desconto_calculado := greatest(v_valor_operacao_validado - v_valor_calculado, 0);
    v_acrescimo_calculado := 0;
    v_economia_liquida := v_desconto_calculado;
    v_vpl_aplicado_pct := null;
    v_calculo_motor := to_jsonb(public.mesa_cliente_financeiro_calcular_antecipacao_composta(
      v_valor_operacao_validado,
      v_data_origem,
      v_data_operacao,
      v_taxa_ano_pct,
      v_politica.base_tempo::text
    ));

  elsif v_tipo_operacao = 'postergacao' then
    if p_data_destino is null then
      raise exception using errcode = '22023', message = 'p_data_destino é obrigatório para postergação.';
    end if;

    if not coalesce(v_parcela.pode_receber_postergacao, false) then
      raise exception using errcode = '22023', message = 'Parcela não é elegível para postergação.';
    end if;

    if p_data_destino <= v_parcela.data_atual then
      raise exception using errcode = '22023', message = 'Postergação exige data destino posterior à data atual da parcela.';
    end if;

    if not (
      (v_grupo_norm = 'financiamento' and coalesce(v_politica.permite_postergacao_financiamento, false))
      or (v_grupo_norm = 'chaves' and coalesce(v_politica.permite_postergacao_chaves, false))
      or (v_grupo_norm = 'anuais' and coalesce(v_politica.permite_postergacao_anuais, false))
      or (v_grupo_norm = 'mensais' and coalesce(v_politica.permite_postergacao_mensais, false))
    ) then
      raise exception using errcode = '22023', message = 'Política financeira não permite postergação para o grupo da parcela.';
    end if;

    v_data_origem := v_parcela.data_atual;
    v_data_operacao := p_data_destino;
    v_dias_calculo := greatest((v_data_operacao - v_data_origem), 0)::integer;
    v_taxa_ano_pct := coalesce(v_politica.taxa_postergacao_ano_pct, 0);
    v_valor_operacao_validado := least(coalesce(v_valor_solicitado, v_parcela.valor_atual), v_parcela.valor_atual);

    if v_valor_operacao_validado <= 0 then
      raise exception using errcode = '22023', message = 'Valor de postergação deve ser maior que zero.';
    end if;

    v_valor_calculado := public.mesa_cliente_financeiro_valor_futuro_composto(
      v_valor_operacao_validado,
      v_taxa_ano_pct,
      v_dias_calculo,
      v_politica.base_tempo::text
    );
    v_desconto_calculado := 0;
    v_acrescimo_calculado := greatest(v_valor_calculado - v_valor_operacao_validado, 0);
    v_economia_liquida := 0;
    v_vpl_aplicado_pct := null;
    v_calculo_motor := to_jsonb(public.mesa_cliente_financeiro_calcular_postergacao_composta(
      v_valor_operacao_validado,
      v_data_origem,
      v_data_operacao,
      v_taxa_ano_pct,
      v_politica.base_tempo::text
    ));

  else
    if not coalesce(v_parcela.pode_receber_vpl, false) then
      raise exception using errcode = '22023', message = 'Parcela não é elegível para VPL.';
    end if;

    if not (
      (v_grupo_norm = 'financiamento' and coalesce(v_politica.permite_vpl_financiamento, false))
      or (v_grupo_norm = 'chaves' and coalesce(v_politica.permite_vpl_chaves, false))
      or (v_grupo_norm = 'anuais' and coalesce(v_politica.permite_vpl_anuais, false))
      or (v_grupo_norm = 'mensais' and coalesce(v_politica.permite_vpl_mensais, false))
    ) then
      raise exception using errcode = '22023', message = 'Política financeira não permite VPL para o grupo da parcela.';
    end if;

    v_data_origem := v_parcela.data_atual;
    v_data_operacao := p_data_referencia;
    v_dias_calculo := greatest((v_data_origem - v_data_operacao), 0)::integer;
    v_taxa_ano_pct := 0;
    v_vpl_aplicado_pct := coalesce(nullif(v_params->>'vpl_aplicado_pct', '')::numeric, v_politica.vpl_max_pct, 0);

    if v_vpl_aplicado_pct < 0 then
      raise exception using errcode = '22023', message = 'VPL aplicado não pode ser negativo.';
    end if;

    if v_vpl_aplicado_pct > coalesce(v_politica.vpl_max_pct, 0) then
      raise exception using errcode = '22023', message = 'VPL aplicado ultrapassa o limite máximo da política financeira.';
    end if;

    v_valor_operacao_validado := least(coalesce(v_valor_solicitado, v_parcela.valor_atual), v_parcela.valor_atual);

    if v_valor_operacao_validado <= 0 then
      raise exception using errcode = '22023', message = 'Valor de VPL deve ser maior que zero.';
    end if;

    v_valor_calculado := greatest(v_valor_operacao_validado * (v_vpl_aplicado_pct / 100.0), 0);
    v_desconto_calculado := v_valor_calculado;
    v_acrescimo_calculado := 0;
    v_economia_liquida := v_desconto_calculado;
    v_calculo_motor := to_jsonb(public.mesa_cliente_financeiro_calcular_vpl_parcela(
      v_valor_operacao_validado,
      v_data_origem,
      v_data_operacao,
      v_vpl_aplicado_pct,
      v_politica.base_tempo::text
    ));
  end if;

  v_valor_operacao_validado := round(v_valor_operacao_validado, 2);
  v_valor_calculado := round(v_valor_calculado, 2);
  v_desconto_calculado := round(v_desconto_calculado, 2);
  v_acrescimo_calculado := round(v_acrescimo_calculado, 2);
  v_economia_liquida := round(v_economia_liquida, 2);
  v_impacto_pct := case
    when v_valor_operacao_validado > 0 then round(((v_economia_liquida + v_acrescimo_calculado) / v_valor_operacao_validado) * 100.0, 4)
    else 0
  end;

  select f.premio_corretor_pct, f.status
    into v_premio
  from public.mesa_cliente_politica_premio_faixas f
  where f.empresa_id = v_simulacao.empresa_id
    and f.politica_id = v_politica.id
    and coalesce(f.ativo, true) = true
    and v_impacto_pct between f.vpl_de_pct and f.vpl_ate_pct
  order by f.ordem nulls last, f.id
  limit 1;

  if found then
    v_premio_corretor_pct := v_premio.premio_corretor_pct;
    v_status_premio := v_premio.status;
  end if;

  v_checksum := md5(concat_ws('|',
    '5B.1',
    v_simulacao.empresa_id::text,
    v_simulacao.id::text,
    v_agenda.id::text,
    v_parcela.id::text,
    v_tipo_operacao,
    v_valor_operacao_validado::text,
    p_data_referencia::text,
    coalesce(v_data_operacao::text, ''),
    v_politica.id::text
  ));

  select o.*
    into v_existente
  from public.mesa_cliente_fluxo_operacoes o
  where o.empresa_id = v_simulacao.empresa_id
    and o.checksum_operacao = v_checksum
    and o.status_operacao in ('simulada', 'confirmada')
  order by o.created_at desc, o.id desc
  limit 1
  for update;

  if found then
    v_operacao := v_existente;
    v_idempotente := true;
  else
    if exists (
      select 1
      from public.mesa_cliente_fluxo_operacoes o
      where o.empresa_id = v_simulacao.empresa_id
        and o.simulacao_id = v_simulacao.id
        and o.status_operacao = 'confirmada'
        and (o.agenda_id = v_agenda.id or o.agenda_id is null)
        and (o.parcela_origem_id = v_parcela.id or o.parcela_origem_id is null)
        and coalesce(o.checksum_operacao, '') <> v_checksum
    ) then
      raise exception using
        errcode = '55000',
        message = 'Operação financeira bloqueada: já existe operação confirmada conflitante para esta parcela/simulação.';
    end if;

    if exists (
      select 1
      from public.mesa_cliente_fluxo_operacoes o
      where o.empresa_id = v_simulacao.empresa_id
        and o.simulacao_id = v_simulacao.id
        and o.status_operacao = 'simulada'
        and (o.agenda_id = v_agenda.id or o.agenda_id is null)
        and o.parcela_origem_id = v_parcela.id
        and o.tipo_operacao::text = v_tipo_operacao
        and coalesce(o.checksum_operacao, '') <> v_checksum
    ) then
      raise exception using
        errcode = '55000',
        message = 'Operação financeira conflitante já registrada para esta parcela. Reaproveite a operação existente ou cancele antes de registrar nova intenção.';
    end if;

    v_metadata := jsonb_build_object(
      'fase_origem', '5B_REGISTRO_OPERACAO_FINANCEIRA',
      'versao_motor', '5B.1',
      'cliente_safe', false,
      'persistencia', true,
      'dml_financeiro', true,
      'altera_agenda', false,
      'altera_parcelas', false,
      'agenda_id', v_agenda.id,
      'parcela_id', v_parcela.id,
      'grupo_original', v_parcela.grupo::text,
      'grupo_norm', v_grupo_norm,
      'tipo_operacao', v_tipo_operacao,
      'valor_solicitado', v_valor_solicitado,
      'valor_operacao_validado', v_valor_operacao_validado,
      'valor_atual_parcela', v_parcela.valor_atual,
      'data_referencia', p_data_referencia,
      'data_origem', v_data_origem,
      'data_destino', v_data_operacao,
      'dias_calculo', v_dias_calculo,
      'valor_calculado', v_valor_calculado,
      'impacto_pct', v_impacto_pct,
      'calculo_motor', v_calculo_motor,
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
      'parametros_nao_soberanos', v_params,
      'registrado_por', v_auth_uid,
      'checksum_operacao', v_checksum
    );

    begin
      insert into public.mesa_cliente_fluxo_operacoes (
        empresa_id,
        simulacao_id,
        empreendimento_id,
        politica_id,
        tipo_operacao,
        grupo_origem,
        grupo_destino,
        parcela_origem_id,
        parcela_destino_id,
        valor_movido,
        data_origem,
        data_destino,
        taxa_ano_pct,
        vpl_aplicado_pct,
        desconto_calculado,
        acrescimo_calculado,
        economia_liquida,
        premio_corretor_pct,
        visivel_cliente,
        confirmado,
        confirmado_por,
        confirmado_em,
        metadata,
        criado_por,
        valor_base,
        dias_calculo,
        status_premio,
        status_operacao,
        updated_at,
        agenda_id,
        checksum_operacao
      ) values (
        v_simulacao.empresa_id,
        v_simulacao.id,
        v_simulacao.empreendimento_id,
        v_politica.id,
        v_tipo_operacao::public.mesa_financeira_operacao_tipo,
        v_grupo_db,
        case when v_tipo_operacao = 'antecipacao' then 'entrada' else v_grupo_db end,
        v_parcela.id,
        null,
        v_valor_operacao_validado,
        v_data_origem,
        v_data_operacao,
        v_taxa_ano_pct,
        v_vpl_aplicado_pct,
        v_desconto_calculado,
        v_acrescimo_calculado,
        v_economia_liquida,
        v_premio_corretor_pct,
        false,
        false,
        null,
        null,
        v_metadata,
        v_auth_uid,
        v_valor_operacao_validado,
        v_dias_calculo,
        v_status_premio,
        'simulada',
        now(),
        v_agenda.id,
        v_checksum
      )
      returning * into v_operacao;

      v_idempotente := false;

    exception when unique_violation then
      select o.*
        into v_operacao
      from public.mesa_cliente_fluxo_operacoes o
      where o.empresa_id = v_simulacao.empresa_id
        and o.checksum_operacao = v_checksum
        and o.status_operacao in ('simulada', 'confirmada')
      order by o.created_at desc, o.id desc
      limit 1;

      if not found then
        raise;
      end if;

      v_idempotente := true;
    end;
  end if;

  return jsonb_build_object(
    'ok', true,
    'fase', '5B_REGISTRO_OPERACAO_FINANCEIRA',
    'visao', 'administrativa',
    'cliente_safe', false,
    'persistencia', true,
    'dml_financeiro', true,
    'escopo_dml', 'operacao_financeira',
    'altera_agenda', false,
    'altera_parcelas', false,
    'idempotente', v_idempotente,
    'simulacao_id', v_simulacao.id,
    'agenda_id', v_agenda.id,
    'empresa_id', v_simulacao.empresa_id,
    'empreendimento_id', v_simulacao.empreendimento_id,
    'operacao', jsonb_build_object(
      'id', v_operacao.id,
      'checksum_operacao', v_operacao.checksum_operacao,
      'status_operacao', v_operacao.status_operacao,
      'confirmado', v_operacao.confirmado,
      'visivel_cliente', v_operacao.visivel_cliente,
      'tipo_operacao', v_operacao.tipo_operacao::text,
      'agenda_id', v_operacao.agenda_id,
      'parcela_origem_id', v_operacao.parcela_origem_id,
      'parcela_destino_id', v_operacao.parcela_destino_id,
      'grupo_origem', v_operacao.grupo_origem,
      'grupo_destino', v_operacao.grupo_destino,
      'valor_movido', v_operacao.valor_movido,
      'valor_base', v_operacao.valor_base,
      'data_origem', v_operacao.data_origem,
      'data_destino', v_operacao.data_destino,
      'taxa_ano_pct', v_operacao.taxa_ano_pct,
      'vpl_aplicado_pct', v_operacao.vpl_aplicado_pct,
      'desconto_calculado', v_operacao.desconto_calculado,
      'acrescimo_calculado', v_operacao.acrescimo_calculado,
      'economia_liquida', v_operacao.economia_liquida,
      'dias_calculo', v_operacao.dias_calculo,
      'premio_corretor_pct', v_operacao.premio_corretor_pct,
      'status_premio', v_operacao.status_premio,
      'criado_por', v_operacao.criado_por,
      'created_at', v_operacao.created_at
    ),
    'calculo', jsonb_build_object(
      'valor_calculado', v_valor_calculado,
      'impacto_pct', v_impacto_pct,
      'calculo_motor', v_calculo_motor
    ),
    'politica', jsonb_build_object(
      'id', v_politica.id,
      'vpl_max_pct', v_politica.vpl_max_pct,
      'taxa_antecipacao_ano_pct', v_politica.taxa_antecipacao_ano_pct,
      'taxa_postergacao_ano_pct', v_politica.taxa_postergacao_ano_pct,
      'metodo_calculo', v_politica.metodo_calculo::text,
      'base_tempo', v_politica.base_tempo::text
    )
  );
end;
$$;

revoke all on function public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb) from public;
revoke all on function public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb) from anon;
grant execute on function public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb) to authenticated;

comment on function public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)
is 'FECH.AI MesaCliente Fase 5B: registra operação financeira administrativa simulada sobre agenda persistida, com lock, idempotência por checksum calculado no banco e sem mutar agenda/parcelas.';
