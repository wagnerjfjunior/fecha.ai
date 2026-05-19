-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5C
-- Confirmação/cancelamento administrativo de operação financeira registrada pela 5B.
--
-- Contrato canônico:
--   docs/mesa-cliente/fase-5c-contrato-confirmacao-cancelamento-operacao-financeira.md
--
-- Preflight:
--   docs/mesa-cliente/fase-5c-validacao-preflight-12.md
--
-- Escopo da 5C:
--   - adiciona colunas explícitas de auditoria de cancelamento;
--   - cria RPC administrativa para transição de status da operação financeira;
--   - confirma operação simulada;
--   - cancela operação simulada;
--   - mantém idempotência por estado;
--   - não altera agenda;
--   - não altera parcelas;
--   - não recalcula operação;
--   - mantém visivel_cliente=false.

alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists cancelado_por uuid null;

alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists cancelado_em timestamptz null;

alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists motivo_cancelamento text null;

comment on column public.mesa_cliente_fluxo_operacoes.cancelado_por
is 'FECH.AI MesaCliente 5C: auth.uid() do usuário administrativo que cancelou a operação financeira.';

comment on column public.mesa_cliente_fluxo_operacoes.cancelado_em
is 'FECH.AI MesaCliente 5C: timestamp de cancelamento administrativo da operação financeira.';

comment on column public.mesa_cliente_fluxo_operacoes.motivo_cancelamento
is 'FECH.AI MesaCliente 5C: motivo administrativo explícito do cancelamento da operação financeira.';

create or replace function public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  p_operacao_id uuid,
  p_acao text,
  p_motivo text default null,
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
  v_operacao_atualizada public.mesa_cliente_fluxo_operacoes%rowtype;
  v_simulacao public.mesa_simulacoes%rowtype;
  v_agenda public.mesa_cliente_agendas_financeiras%rowtype;
  v_parcela public.mesa_cliente_fluxo_parcelas%rowtype;

  v_acao text := lower(coalesce(nullif(trim(p_acao), ''), ''));
  v_motivo text := nullif(trim(coalesce(p_motivo, '')), '');
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_forbidden_keys text[] := array[
    'empresa_id',
    'simulacao_id',
    'agenda_id',
    'parcela_id',
    'parcela_origem_id',
    'parcela_destino_id',
    'corretor_id',
    'politica_id',
    'valor_movido',
    'valor_base',
    'desconto_calculado',
    'acrescimo_calculado',
    'economia_liquida',
    'taxa_ano_pct',
    'taxa_antecipacao_ano_pct',
    'taxa_postergacao_ano_pct',
    'status_operacao',
    'confirmado',
    'confirmado_por',
    'confirmado_em',
    'cancelado_por',
    'cancelado_em',
    'motivo_cancelamento',
    'visivel_cliente',
    'checksum_operacao',
    'idempotency_key',
    'created_at',
    'updated_at'
  ];
  v_forbidden_key text;
  v_idempotente boolean := false;
  v_status_anterior text;
  v_now timestamptz := now();
  v_metadata_5c jsonb;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'Acesso negado: usuário autenticado obrigatório para atualizar operação financeira.';
  end if;

  if p_operacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_operacao_id é obrigatório.';
  end if;

  if v_acao not in ('confirmar', 'cancelar') then
    raise exception using
      errcode = '22023',
      message = 'Ação inválida para operação financeira 5C. Use confirmar ou cancelar.';
  end if;

  if jsonb_typeof(v_params) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'p_parametros deve ser um objeto JSON.';
  end if;

  if v_acao = 'cancelar' and v_motivo is null then
    raise exception using
      errcode = '22023',
      message = 'p_motivo é obrigatório para cancelamento de operação financeira.';
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
      message = 'Acesso negado: perfil sem permissão administrativa para confirmar/cancelar operação financeira.';
  end if;

  select o.*
    into v_operacao
  from public.mesa_cliente_fluxo_operacoes o
  where o.id = p_operacao_id
  limit 1
  for update;

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

  v_status_anterior := v_operacao.status_operacao;

  if v_acao = 'confirmar' then
    if v_operacao.status_operacao = 'confirmada' and coalesce(v_operacao.confirmado, false) = true then
      v_idempotente := true;
      v_operacao_atualizada := v_operacao;

    elsif v_operacao.status_operacao = 'cancelada' then
      raise exception using
        errcode = '55000',
        message = 'Operação financeira cancelada não pode ser confirmada.';

    elsif v_operacao.status_operacao <> 'simulada' or coalesce(v_operacao.confirmado, false) = true then
      raise exception using
        errcode = '55000',
        message = 'Somente operação financeira simulada pode ser confirmada.';

    else
      if exists (
        select 1
        from public.mesa_cliente_fluxo_operacoes o
        where o.id <> v_operacao.id
          and o.empresa_id = v_operacao.empresa_id
          and o.simulacao_id = v_operacao.simulacao_id
          and o.status_operacao = 'confirmada'
          and (o.agenda_id = v_operacao.agenda_id or o.agenda_id is null or v_operacao.agenda_id is null)
          and (o.parcela_origem_id = v_operacao.parcela_origem_id or o.parcela_origem_id is null or v_operacao.parcela_origem_id is null)
          and coalesce(o.checksum_operacao, '') <> coalesce(v_operacao.checksum_operacao, '')
      ) then
        raise exception using
          errcode = '55000',
          message = 'Operação financeira bloqueada: já existe operação confirmada conflitante para esta parcela/simulação.';
      end if;

      v_metadata_5c := jsonb_build_object(
        'fase_5c', jsonb_build_object(
          'acao', 'confirmar',
          'status_anterior', v_status_anterior,
          'status_final', 'confirmada',
          'executado_por', v_auth_uid,
          'executado_em', v_now,
          'cliente_safe', false,
          'altera_agenda', false,
          'altera_parcelas', false,
          'recalcula_operacao', false,
          'parametros_nao_soberanos', v_params
        )
      );

      update public.mesa_cliente_fluxo_operacoes
      set status_operacao = 'confirmada',
          confirmado = true,
          confirmado_por = v_auth_uid,
          confirmado_em = coalesce(confirmado_em, v_now),
          cancelado_por = null,
          cancelado_em = null,
          motivo_cancelamento = null,
          visivel_cliente = false,
          metadata = coalesce(metadata, '{}'::jsonb) || v_metadata_5c,
          updated_at = v_now
      where id = v_operacao.id
      returning * into v_operacao_atualizada;
    end if;

  else
    if v_operacao.status_operacao = 'cancelada' then
      v_idempotente := true;
      v_operacao_atualizada := v_operacao;

    elsif v_operacao.status_operacao = 'confirmada' or coalesce(v_operacao.confirmado, false) = true then
      raise exception using
        errcode = '55000',
        message = 'Cancelamento de operação financeira confirmada está bloqueado nesta versão da 5C.';

    elsif v_operacao.status_operacao <> 'simulada' then
      raise exception using
        errcode = '55000',
        message = 'Somente operação financeira simulada pode ser cancelada.';

    else
      v_metadata_5c := jsonb_build_object(
        'fase_5c', jsonb_build_object(
          'acao', 'cancelar',
          'status_anterior', v_status_anterior,
          'status_final', 'cancelada',
          'executado_por', v_auth_uid,
          'executado_em', v_now,
          'motivo', v_motivo,
          'cliente_safe', false,
          'altera_agenda', false,
          'altera_parcelas', false,
          'recalcula_operacao', false,
          'parametros_nao_soberanos', v_params
        )
      );

      update public.mesa_cliente_fluxo_operacoes
      set status_operacao = 'cancelada',
          confirmado = false,
          cancelado_por = v_auth_uid,
          cancelado_em = coalesce(cancelado_em, v_now),
          motivo_cancelamento = v_motivo,
          visivel_cliente = false,
          metadata = coalesce(metadata, '{}'::jsonb) || v_metadata_5c,
          updated_at = v_now
      where id = v_operacao.id
      returning * into v_operacao_atualizada;
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'fase', '5C_CONFIRMACAO_CANCELAMENTO_OPERACAO_FINANCEIRA',
    'visao', 'administrativa',
    'cliente_safe', false,
    'persistencia', true,
    'dml_financeiro', true,
    'escopo_dml', 'status_operacao_financeira',
    'altera_agenda', false,
    'altera_parcelas', false,
    'recalcula_operacao', false,
    'idempotente', v_idempotente,
    'acao', v_acao,
    'operacao', jsonb_build_object(
      'id', v_operacao_atualizada.id,
      'empresa_id', v_operacao_atualizada.empresa_id,
      'simulacao_id', v_operacao_atualizada.simulacao_id,
      'agenda_id', v_operacao_atualizada.agenda_id,
      'parcela_origem_id', v_operacao_atualizada.parcela_origem_id,
      'tipo_operacao', v_operacao_atualizada.tipo_operacao::text,
      'status_operacao_anterior', v_status_anterior,
      'status_operacao', v_operacao_atualizada.status_operacao,
      'confirmado', v_operacao_atualizada.confirmado,
      'confirmado_por', v_operacao_atualizada.confirmado_por,
      'confirmado_em', v_operacao_atualizada.confirmado_em,
      'cancelado_por', v_operacao_atualizada.cancelado_por,
      'cancelado_em', v_operacao_atualizada.cancelado_em,
      'motivo_cancelamento', v_operacao_atualizada.motivo_cancelamento,
      'visivel_cliente', v_operacao_atualizada.visivel_cliente,
      'checksum_operacao', v_operacao_atualizada.checksum_operacao,
      'updated_at', v_operacao_atualizada.updated_at
    )
  );
end;
$$;

revoke all on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb) from public;
revoke all on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb) from anon;
grant execute on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb) to authenticated;

comment on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)
is 'FECH.AI MesaCliente Fase 5C: confirma ou cancela operação financeira administrativa registrada pela 5B, sem recalcular operação e sem mutar agenda/parcelas.';
