-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5D
-- Leitura/consulta administrativa read-only de operações financeiras.
--
-- Contrato canônico:
--   docs/mesa-cliente/fase-5d-contrato-leitura-operacoes-admin.md
--
-- Preflight:
--   docs/mesa-cliente/fase-5d-validacao-preflight-13.md
--
-- Escopo da 5D:
--   - cria RPC administrativa para listar operações financeiras;
--   - cria RPC administrativa para obter detalhe de uma operação financeira;
--   - mantém read-only absoluto;
--   - não altera agenda;
--   - não altera parcelas;
--   - não recalcula operação;
--   - não confirma/cancela operação;
--   - não expõe automaticamente ao cliente;
--   - bloqueia autoridade soberana vinda do frontend;
--   - valida auth.uid(), corretor ativo, tenant/empresa e perfil administrativo.

create or replace function public.mesa_cliente_listar_operacoes_financeiras_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid default null,
  p_filtros jsonb default '{}'::jsonb
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

  v_filtros jsonb := coalesce(p_filtros, '{}'::jsonb);
  v_forbidden_keys text[] := array[
    'empresa_id',
    'tenant_id',
    'corretor_id',
    'user_id',
    'auth_uid',
    'role',
    'perfil',
    'is_admin',
    'is_gestor',
    'is_admin_local',
    'criado_por',
    'confirmado_por',
    'cancelado_por',
    'politica_id',
    'empreendimento_id',
    'checksum_operacao',
    'metadata',
    'status_forcado',
    'cliente_safe'
  ];
  v_forbidden_key text;

  v_status_operacao text := nullif(trim(coalesce(v_filtros->>'status_operacao', '')), '');
  v_tipo_operacao text := nullif(trim(coalesce(v_filtros->>'tipo_operacao', '')), '');
  v_visivel_cliente boolean := null;
  v_data_de date := null;
  v_data_ate date := null;
  v_limit integer := 50;
  v_offset integer := 0;
  v_order_by text := lower(coalesce(nullif(trim(v_filtros->>'order_by'), ''), 'created_at'));
  v_order_dir text := lower(coalesce(nullif(trim(v_filtros->>'order_dir'), ''), 'desc'));

  v_total integer := 0;
  v_operacoes jsonb := '[]'::jsonb;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: usuário autenticado obrigatório para listar operações financeiras.';
  end if;

  if p_simulacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_simulacao_id é obrigatório.';
  end if;

  if jsonb_typeof(v_filtros) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'p_filtros deve ser um objeto JSON.';
  end if;

  foreach v_forbidden_key in array v_forbidden_keys loop
    if v_filtros ? v_forbidden_key then
      raise exception using
        errcode = '42501',
        message = format('%s não pode ser enviado como autoridade pelo frontend.', v_forbidden_key);
    end if;
  end loop;

  if v_status_operacao is not null and v_status_operacao not in ('simulada', 'confirmada', 'cancelada', 'bloqueada') then
    raise exception using
      errcode = '22023',
      message = 'status_operacao inválido para listagem administrativa 5D.';
  end if;

  if v_tipo_operacao is not null and lower(v_tipo_operacao) not in ('antecipacao', 'postergacao', 'vpl') then
    raise exception using
      errcode = '22023',
      message = 'tipo_operacao inválido para listagem administrativa 5D.';
  end if;

  if v_filtros ? 'visivel_cliente' then
    if jsonb_typeof(v_filtros->'visivel_cliente') <> 'boolean' then
      raise exception using
        errcode = '22023',
        message = 'visivel_cliente deve ser booleano.';
    end if;

    v_visivel_cliente := (v_filtros->>'visivel_cliente')::boolean;
  end if;

  if v_filtros ? 'data_de' then
    if jsonb_typeof(v_filtros->'data_de') <> 'string'
       or not ((v_filtros->>'data_de') ~ '^\d{4}-\d{2}-\d{2}$') then
      raise exception using
        errcode = '22023',
        message = 'data_de deve estar no formato YYYY-MM-DD.';
    end if;

    v_data_de := (v_filtros->>'data_de')::date;
  end if;

  if v_filtros ? 'data_ate' then
    if jsonb_typeof(v_filtros->'data_ate') <> 'string'
       or not ((v_filtros->>'data_ate') ~ '^\d{4}-\d{2}-\d{2}$') then
      raise exception using
        errcode = '22023',
        message = 'data_ate deve estar no formato YYYY-MM-DD.';
    end if;

    v_data_ate := (v_filtros->>'data_ate')::date;
  end if;

  if v_data_de is not null and v_data_ate is not null and v_data_de > v_data_ate then
    raise exception using
      errcode = '22023',
      message = 'data_de não pode ser maior que data_ate.';
  end if;

  if v_filtros ? 'limit' then
    if jsonb_typeof(v_filtros->'limit') <> 'number' then
      raise exception using
        errcode = '22023',
        message = 'limit deve ser numérico.';
    end if;

    v_limit := (v_filtros->>'limit')::integer;
  end if;

  if v_limit < 1 or v_limit > 200 then
    raise exception using
      errcode = '22023',
      message = 'limit deve estar entre 1 e 200.';
  end if;

  if v_filtros ? 'offset' then
    if jsonb_typeof(v_filtros->'offset') <> 'number' then
      raise exception using
        errcode = '22023',
        message = 'offset deve ser numérico.';
    end if;

    v_offset := (v_filtros->>'offset')::integer;
  end if;

  if v_offset < 0 then
    raise exception using
      errcode = '22023',
      message = 'offset deve ser maior ou igual a zero.';
  end if;

  if v_order_by not in ('created_at', 'updated_at', 'status_operacao', 'tipo_operacao') then
    raise exception using
      errcode = '22023',
      message = 'order_by inválido para listagem administrativa 5D.';
  end if;

  if v_order_dir not in ('asc', 'desc') then
    raise exception using
      errcode = '22023',
      message = 'order_dir inválido para listagem administrativa 5D.';
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
      message = 'Acesso negado: corretor ativo não encontrado para auth.uid().';
  end if;

  if not (
    coalesce(v_corretor.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
    or coalesce(v_corretor.is_admin_local, false)
    or coalesce(v_corretor.is_gestor, false)
  ) then
    raise exception using
      errcode = '42501',
      message = 'Acesso negado: perfil sem permissão administrativa para listar operações financeiras.';
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

  if p_agenda_id is not null then
    select a.*
      into v_agenda
    from public.mesa_cliente_agendas_financeiras a
    where a.id = p_agenda_id
      and a.simulacao_id = v_simulacao.id
      and a.empresa_id = v_simulacao.empresa_id
    limit 1;

    if not found then
      raise exception using
        errcode = 'P0002',
        message = 'Agenda financeira não encontrada para a simulação informada.';
    end if;
  end if;

  with base as (
    select
      o.*,
      count(*) over()::integer as total_count
    from public.mesa_cliente_fluxo_operacoes o
    where o.simulacao_id = v_simulacao.id
      and o.empresa_id = v_simulacao.empresa_id
      and (p_agenda_id is null or o.agenda_id = p_agenda_id)
      and (v_status_operacao is null or o.status_operacao = v_status_operacao)
      and (v_tipo_operacao is null or o.tipo_operacao::text = lower(v_tipo_operacao))
      and (v_visivel_cliente is null or coalesce(o.visivel_cliente, false) = v_visivel_cliente)
      and (v_data_de is null or o.created_at::date >= v_data_de)
      and (v_data_ate is null or o.created_at::date <= v_data_ate)
  ), ordered as (
    select
      b.*,
      row_number() over (
        order by
          case when v_order_by = 'created_at' and v_order_dir = 'asc' then b.created_at end asc nulls last,
          case when v_order_by = 'created_at' and v_order_dir = 'desc' then b.created_at end desc nulls last,
          case when v_order_by = 'updated_at' and v_order_dir = 'asc' then b.updated_at end asc nulls last,
          case when v_order_by = 'updated_at' and v_order_dir = 'desc' then b.updated_at end desc nulls last,
          case when v_order_by = 'status_operacao' and v_order_dir = 'asc' then b.status_operacao end asc nulls last,
          case when v_order_by = 'status_operacao' and v_order_dir = 'desc' then b.status_operacao end desc nulls last,
          case when v_order_by = 'tipo_operacao' and v_order_dir = 'asc' then b.tipo_operacao::text end asc nulls last,
          case when v_order_by = 'tipo_operacao' and v_order_dir = 'desc' then b.tipo_operacao::text end desc nulls last,
          b.id asc
      ) as rn
    from base b
    limit v_limit
    offset v_offset
  )
  select
    coalesce(max(o.total_count), 0),
    coalesce(jsonb_agg(jsonb_build_object(
      'id', o.id,
      'empresa_id', o.empresa_id,
      'simulacao_id', o.simulacao_id,
      'agenda_id', o.agenda_id,
      'empreendimento_id', o.empreendimento_id,
      'politica_id', o.politica_id,
      'tipo_operacao', o.tipo_operacao::text,
      'status_operacao', o.status_operacao,
      'confirmado', o.confirmado,
      'confirmado_por', o.confirmado_por,
      'confirmado_em', o.confirmado_em,
      'cancelado_por', o.cancelado_por,
      'cancelado_em', o.cancelado_em,
      'motivo_cancelamento', o.motivo_cancelamento,
      'visivel_cliente', o.visivel_cliente,
      'checksum_operacao', o.checksum_operacao,
      'grupo_origem', o.grupo_origem,
      'grupo_destino', o.grupo_destino,
      'parcela_origem_id', o.parcela_origem_id,
      'parcela_destino_id', o.parcela_destino_id,
      'valor_movido', o.valor_movido,
      'valor_base', o.valor_base,
      'data_origem', o.data_origem,
      'data_destino', o.data_destino,
      'taxa_ano_pct', o.taxa_ano_pct,
      'vpl_aplicado_pct', o.vpl_aplicado_pct,
      'desconto_calculado', o.desconto_calculado,
      'acrescimo_calculado', o.acrescimo_calculado,
      'economia_liquida', o.economia_liquida,
      'dias_calculo', o.dias_calculo,
      'premio_corretor_pct', o.premio_corretor_pct,
      'status_premio', o.status_premio,
      'criado_por', o.criado_por,
      'created_at', o.created_at,
      'updated_at', o.updated_at,
      'resumo_financeiro', jsonb_build_object(
        'valor_movido', o.valor_movido,
        'valor_base', o.valor_base,
        'desconto_calculado', o.desconto_calculado,
        'acrescimo_calculado', o.acrescimo_calculado,
        'economia_liquida', o.economia_liquida,
        'premio_corretor_pct', o.premio_corretor_pct,
        'status_premio', o.status_premio
      )
    ) order by o.rn), '[]'::jsonb)
  into v_total, v_operacoes
  from ordered o;

  return jsonb_build_object(
    'ok', true,
    'fase', '5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN',
    'visao', 'administrativa',
    'cliente_safe', false,
    'readonly', true,
    'persistencia', true,
    'dml_financeiro', false,
    'escopo_dml', 'nenhum',
    'altera_agenda', false,
    'altera_parcelas', false,
    'recalcula_operacao', false,
    'simulacao_id', v_simulacao.id,
    'agenda_id', p_agenda_id,
    'empresa_id', v_simulacao.empresa_id,
    'empreendimento_id', v_simulacao.empreendimento_id,
    'total', v_total,
    'limit', v_limit,
    'offset', v_offset,
    'order_by', v_order_by,
    'order_dir', v_order_dir,
    'filtros_aplicados', jsonb_build_object(
      'status_operacao', v_status_operacao,
      'tipo_operacao', v_tipo_operacao,
      'visivel_cliente', v_visivel_cliente,
      'data_de', v_data_de,
      'data_ate', v_data_ate
    ),
    'operacoes', v_operacoes
  );
end;
$$;

revoke all on function public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb) from public;
revoke all on function public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb) from anon;
grant execute on function public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb) to authenticated;

comment on function public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)
is 'FECH.AI MesaCliente Fase 5D: lista operações financeiras administrativas de forma read-only, tenant-safe, sem DML, sem recalcular e sem mutar agenda/parcelas.';

create or replace function public.mesa_cliente_obter_operacao_financeira_admin(
  p_operacao_id uuid,
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
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;
  v_simulacao public.mesa_simulacoes%rowtype;
  v_agenda public.mesa_cliente_agendas_financeiras%rowtype;
  v_parcela public.mesa_cliente_fluxo_parcelas%rowtype;

  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_forbidden_keys text[] := array[
    'empresa_id',
    'tenant_id',
    'simulacao_id',
    'agenda_id',
    'corretor_id',
    'user_id',
    'auth_uid',
    'role',
    'perfil',
    'is_admin',
    'is_gestor',
    'is_admin_local',
    'criado_por',
    'confirmado_por',
    'cancelado_por',
    'politica_id',
    'empreendimento_id',
    'status_operacao',
    'tipo_operacao',
    'checksum_operacao',
    'metadata',
    'cliente_safe'
  ];
  v_forbidden_key text;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: usuário autenticado obrigatório para obter operação financeira.';
  end if;

  if p_operacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_operacao_id é obrigatório.';
  end if;

  if jsonb_typeof(v_params) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'p_parametros deve ser um objeto JSON.';
  end if;

  foreach v_forbidden_key in array v_forbidden_keys loop
    if v_params ? v_forbidden_key then
      raise exception using
        errcode = '42501',
        message = format('%s não pode ser enviado como autoridade pelo frontend.', v_forbidden_key);
    end if;
  end loop;

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
      message = 'Acesso negado: corretor ativo não encontrado para auth.uid().';
  end if;

  if not (
    coalesce(v_corretor.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
    or coalesce(v_corretor.is_admin_local, false)
    or coalesce(v_corretor.is_gestor, false)
  ) then
    raise exception using
      errcode = '42501',
      message = 'Acesso negado: perfil sem permissão administrativa para obter operação financeira.';
  end if;

  select o.*
    into v_operacao
  from public.mesa_cliente_fluxo_operacoes o
  where o.id = p_operacao_id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Operação financeira não encontrada.';
  end if;

  if coalesce(v_corretor.role, '') <> 'admin_global'
     and v_corretor.empresa_id is distinct from v_operacao.empresa_id then
    raise exception using
      errcode = '42501',
      message = 'Acesso negado: operação financeira pertence a outro tenant.';
  end if;

  select s.*
    into v_simulacao
  from public.mesa_simulacoes s
  where s.id = v_operacao.simulacao_id
    and s.empresa_id = v_operacao.empresa_id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Simulação vinculada à operação financeira não encontrada.';
  end if;

  if v_operacao.agenda_id is not null then
    select a.*
      into v_agenda
    from public.mesa_cliente_agendas_financeiras a
    where a.id = v_operacao.agenda_id
      and a.simulacao_id = v_operacao.simulacao_id
      and a.empresa_id = v_operacao.empresa_id
    limit 1;

    if not found then
      raise exception using
        errcode = 'P0002',
        message = 'Agenda vinculada à operação financeira não encontrada.';
    end if;
  end if;

  if v_operacao.parcela_origem_id is not null then
    select fp.*
      into v_parcela
    from public.mesa_cliente_fluxo_parcelas fp
    where fp.id = v_operacao.parcela_origem_id
      and fp.simulacao_id = v_operacao.simulacao_id
      and fp.empresa_id = v_operacao.empresa_id
      and (v_operacao.agenda_id is null or fp.agenda_id = v_operacao.agenda_id)
    limit 1;

    if not found then
      raise exception using
        errcode = 'P0002',
        message = 'Parcela vinculada à operação financeira não encontrada.';
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'fase', '5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN',
    'visao', 'administrativa',
    'cliente_safe', false,
    'readonly', true,
    'persistencia', true,
    'dml_financeiro', false,
    'escopo_dml', 'nenhum',
    'altera_agenda', false,
    'altera_parcelas', false,
    'recalcula_operacao', false,
    'simulacao_id', v_simulacao.id,
    'agenda_id', v_operacao.agenda_id,
    'empresa_id', v_operacao.empresa_id,
    'empreendimento_id', v_operacao.empreendimento_id,
    'operacao', jsonb_build_object(
      'id', v_operacao.id,
      'empresa_id', v_operacao.empresa_id,
      'simulacao_id', v_operacao.simulacao_id,
      'agenda_id', v_operacao.agenda_id,
      'empreendimento_id', v_operacao.empreendimento_id,
      'politica_id', v_operacao.politica_id,
      'tipo_operacao', v_operacao.tipo_operacao::text,
      'status_operacao', v_operacao.status_operacao,
      'confirmado', v_operacao.confirmado,
      'confirmado_por', v_operacao.confirmado_por,
      'confirmado_em', v_operacao.confirmado_em,
      'cancelado_por', v_operacao.cancelado_por,
      'cancelado_em', v_operacao.cancelado_em,
      'motivo_cancelamento', v_operacao.motivo_cancelamento,
      'visivel_cliente', v_operacao.visivel_cliente,
      'checksum_operacao', v_operacao.checksum_operacao,
      'grupo_origem', v_operacao.grupo_origem,
      'grupo_destino', v_operacao.grupo_destino,
      'parcela_origem_id', v_operacao.parcela_origem_id,
      'parcela_destino_id', v_operacao.parcela_destino_id,
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
      'created_at', v_operacao.created_at,
      'updated_at', v_operacao.updated_at,
      'metadata', v_operacao.metadata,
      'resumo_financeiro', jsonb_build_object(
        'valor_movido', v_operacao.valor_movido,
        'valor_base', v_operacao.valor_base,
        'desconto_calculado', v_operacao.desconto_calculado,
        'acrescimo_calculado', v_operacao.acrescimo_calculado,
        'economia_liquida', v_operacao.economia_liquida,
        'premio_corretor_pct', v_operacao.premio_corretor_pct,
        'status_premio', v_operacao.status_premio
      ),
      'auditoria_5c', jsonb_build_object(
        'confirmado', v_operacao.confirmado,
        'confirmado_por', v_operacao.confirmado_por,
        'confirmado_em', v_operacao.confirmado_em,
        'cancelado_por', v_operacao.cancelado_por,
        'cancelado_em', v_operacao.cancelado_em,
        'motivo_cancelamento', v_operacao.motivo_cancelamento
      ),
      'vinculos', jsonb_build_object(
        'simulacao_id', v_operacao.simulacao_id,
        'agenda_id', v_operacao.agenda_id,
        'parcela_origem_id', v_operacao.parcela_origem_id,
        'parcela_destino_id', v_operacao.parcela_destino_id
      )
    )
  );
end;
$$;

revoke all on function public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb) from public;
revoke all on function public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb) from anon;
grant execute on function public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb) to authenticated;

comment on function public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)
is 'FECH.AI MesaCliente Fase 5D: obtém detalhe administrativo read-only de operação financeira, tenant-safe, sem DML, sem recalcular e sem mutar agenda/parcelas.';
