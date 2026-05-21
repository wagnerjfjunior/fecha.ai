-- FECH.AI — MesaCliente
-- Engenharia Financeira — Fase 7
-- Versionamento canônico da RPC de aplicação de operação financeira admin.
--
-- Origem:
--   Função encontrada no Supabase antes de estar versionada no GitHub.
--   Esta migration elimina drift banco > repositório para a Fase 7.
--
-- Garantias:
--   - SECURITY DEFINER com search_path controlado.
--   - Bloqueia autoridade soberana do frontend.
--   - Exige auth.uid(), perfil administrativo, tenant/empresa e status confirmada.
--   - Aplica DML financeiro controlado em operação, parcela e agenda.
--   - Não expõe visão cliente-safe.

create or replace function public.mesa_cliente_aplicar_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_auth_uid uuid := auth.uid();
  v_corretor public.corretores%rowtype;
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;
  v_operacao_atualizada public.mesa_cliente_fluxo_operacoes%rowtype;
  v_simulacao public.mesa_simulacoes%rowtype;
  v_agenda public.mesa_cliente_agendas_financeiras%rowtype;
  v_parcela_origem public.mesa_cliente_fluxo_parcelas%rowtype;
  v_parcela_origem_atualizada public.mesa_cliente_fluxo_parcelas%rowtype;
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_bad_key text;
  v_admin boolean := false;
  v_now timestamptz := now();
  v_status_anterior text;
  v_valor_movido numeric;
  v_valor_base numeric;
  v_desconto numeric;
  v_acrescimo numeric;
  v_valor_atual_anterior numeric;
  v_valor_atual_final numeric;
  v_data_atual_anterior date;
  v_data_atual_final date;
  v_delta_valor numeric := 0;
  v_metadata_operacao jsonb;
  v_metadata_parcela jsonb;
  v_metadata_agenda jsonb;
  v_auditoria jsonb;
  v_forbidden text[] := array[
    'empresa_id','tenant_id','simulacao_id','agenda_id','empreendimento_id','politica_id',
    'parcela_origem_id','parcela_destino_id','corretor_id','user_id','auth_uid','role','perfil',
    'is_admin','is_gestor','is_admin_local','tipo_operacao','valor_base','valor_movido',
    'taxa_ano_pct','vpl_aplicado_pct','desconto_calculado','acrescimo_calculado',
    'economia_liquida','premio_corretor_pct','status_premio','status_operacao','confirmado',
    'confirmado_por','confirmado_em','cancelado_por','cancelado_em','motivo_cancelamento',
    'visivel_cliente','checksum_operacao','metadata','created_at','updated_at','cliente_safe','visao'
  ];
begin
  if v_auth_uid is null then
    raise exception using errcode = '28000', message = 'auth_required';
  end if;

  if p_operacao_id is null then
    raise exception using errcode = '22023', message = 'p_operacao_id_required';
  end if;

  if jsonb_typeof(v_params) <> 'object' then
    raise exception using errcode = '22023', message = 'p_parametros_must_be_object';
  end if;

  select k into v_bad_key
  from jsonb_object_keys(v_params) as t(k)
  where k = any(v_forbidden)
  limit 1;

  if v_bad_key is not null then
    raise exception using errcode = '42501', message = 'frontend_authority_forbidden:' || v_bad_key;
  end if;

  select c.* into v_corretor
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
    raise exception using errcode = '28000', message = 'active_corretor_not_found';
  end if;

  v_admin :=
    coalesce(v_corretor.role, '') in ('admin_global','admin_local','gestor','coordenador')
    or coalesce(v_corretor.is_admin_local, false)
    or coalesce(v_corretor.is_gestor, false);

  if not v_admin then
    raise exception using errcode = '42501', message = 'profile_not_allowed';
  end if;

  select o.* into v_operacao
  from public.mesa_cliente_fluxo_operacoes o
  where o.id = p_operacao_id
  limit 1
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'operacao_not_found';
  end if;

  v_status_anterior := v_operacao.status_operacao;

  if coalesce(v_corretor.role, '') <> 'admin_global'
     and v_corretor.empresa_id is distinct from v_operacao.empresa_id then
    raise exception using errcode = '42501', message = 'cross_tenant_denied';
  end if;

  if v_operacao.status_operacao = 'aplicada' then
    raise exception using errcode = '55000', message = 'operacao_already_applied';
  end if;

  if v_operacao.status_operacao = 'cancelada' then
    raise exception using errcode = '55000', message = 'operacao_cancelada';
  end if;

  if v_operacao.status_operacao <> 'confirmada'
     or coalesce(v_operacao.confirmado, false) is false then
    raise exception using errcode = '55000', message = 'operacao_not_applicable_status';
  end if;

  if v_operacao.agenda_id is null then
    raise exception using errcode = '22023', message = 'operacao_without_agenda';
  end if;

  if v_operacao.simulacao_id is null then
    raise exception using errcode = '22023', message = 'operacao_without_simulacao';
  end if;

  if v_operacao.parcela_origem_id is null then
    raise exception using errcode = '22023', message = 'parcela_origem_required';
  end if;

  select s.* into v_simulacao
  from public.mesa_simulacoes s
  where s.id = v_operacao.simulacao_id
    and s.empresa_id = v_operacao.empresa_id
  limit 1;

  if not found then
    raise exception using errcode = 'P0002', message = 'simulacao_not_found';
  end if;

  if v_simulacao.empreendimento_id is distinct from v_operacao.empreendimento_id then
    raise exception using errcode = '42501', message = 'empreendimento_scope_mismatch';
  end if;

  select a.* into v_agenda
  from public.mesa_cliente_agendas_financeiras a
  where a.id = v_operacao.agenda_id
    and a.simulacao_id = v_operacao.simulacao_id
    and a.empresa_id = v_operacao.empresa_id
    and a.empreendimento_id = v_operacao.empreendimento_id
  limit 1
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'agenda_not_found';
  end if;

  if coalesce(v_agenda.status, '') <> 'ativa' then
    raise exception using errcode = '55000', message = 'agenda_not_active';
  end if;

  select p.* into v_parcela_origem
  from public.mesa_cliente_fluxo_parcelas p
  where p.id = v_operacao.parcela_origem_id
    and p.agenda_id = v_operacao.agenda_id
    and p.simulacao_id = v_operacao.simulacao_id
    and p.empresa_id = v_operacao.empresa_id
    and p.empreendimento_id = v_operacao.empreendimento_id
  limit 1
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'parcela_origem_not_found';
  end if;

  if coalesce(v_parcela_origem.eh_periodicidade_simbolica, false) then
    raise exception using errcode = '22023', message = 'parcela_simbolica_not_applicable';
  end if;

  v_valor_movido := round(coalesce(v_operacao.valor_movido, 0), 2);
  v_valor_base := round(coalesce(v_operacao.valor_base, v_operacao.valor_movido, 0), 2);
  v_desconto := round(coalesce(v_operacao.desconto_calculado, 0), 2);
  v_acrescimo := round(coalesce(v_operacao.acrescimo_calculado, 0), 2);
  v_valor_atual_anterior := round(coalesce(v_parcela_origem.valor_atual, 0), 2);
  v_data_atual_anterior := v_parcela_origem.data_atual;

  if v_valor_movido <= 0 then
    raise exception using errcode = '22023', message = 'valor_movido_invalid';
  end if;

  if v_operacao.tipo_operacao::text = 'antecipacao' then
    if not coalesce(v_parcela_origem.pode_receber_antecipacao, false) then
      raise exception using errcode = '22023', message = 'parcela_flag_denied';
    end if;
    if v_valor_atual_anterior < v_valor_movido then
      raise exception using errcode = '55000', message = 'saldo_parcela_insuficiente';
    end if;
    v_delta_valor := -1 * v_valor_movido;
    v_valor_atual_final := round(v_valor_atual_anterior + v_delta_valor, 2);
    v_data_atual_final := v_data_atual_anterior;

  elsif v_operacao.tipo_operacao::text = 'vpl' then
    if not coalesce(v_parcela_origem.pode_receber_vpl, false) then
      raise exception using errcode = '22023', message = 'parcela_flag_denied';
    end if;
    if v_desconto < 0 then
      raise exception using errcode = '22023', message = 'desconto_calculado_invalid';
    end if;
    if v_valor_atual_anterior < v_desconto then
      raise exception using errcode = '55000', message = 'saldo_parcela_insuficiente';
    end if;
    v_delta_valor := -1 * v_desconto;
    v_valor_atual_final := round(v_valor_atual_anterior + v_delta_valor, 2);
    v_data_atual_final := v_data_atual_anterior;

  elsif v_operacao.tipo_operacao::text = 'postergacao' then
    if not coalesce(v_parcela_origem.pode_receber_postergacao, false) then
      raise exception using errcode = '22023', message = 'parcela_flag_denied';
    end if;
    if v_operacao.data_destino is null then
      raise exception using errcode = '22023', message = 'data_destino_required';
    end if;
    if v_operacao.data_destino <= coalesce(v_parcela_origem.data_atual, v_operacao.data_origem) then
      raise exception using errcode = '22023', message = 'data_destino_invalid';
    end if;
    v_delta_valor := v_acrescimo;
    v_valor_atual_final := round(v_valor_atual_anterior + v_delta_valor, 2);
    v_data_atual_final := v_operacao.data_destino;

  else
    raise exception using errcode = '22023', message = 'tipo_operacao_not_supported';
  end if;

  if v_valor_atual_final < 0 then
    raise exception using errcode = '55000', message = 'valor_final_parcela_negativo';
  end if;

  v_auditoria := jsonb_build_object(
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'operacao_id', v_operacao.id,
    'agenda_id', v_operacao.agenda_id,
    'simulacao_id', v_operacao.simulacao_id,
    'empresa_id', v_operacao.empresa_id,
    'tipo_operacao', v_operacao.tipo_operacao::text,
    'status_anterior', v_status_anterior,
    'status_final', 'aplicada',
    'executado_por', v_auth_uid,
    'executado_em', v_now,
    'readonly', false,
    'dml_financeiro', true,
    'altera_operacao', true,
    'altera_agenda', true,
    'altera_parcelas', true,
    'parcela_origem_id', v_parcela_origem.id,
    'valor_atual_anterior', v_valor_atual_anterior,
    'valor_atual_final', v_valor_atual_final,
    'delta_valor', v_delta_valor,
    'data_atual_anterior', v_data_atual_anterior,
    'data_atual_final', v_data_atual_final,
    'parametros_nao_soberanos', v_params
  );

  v_metadata_parcela := jsonb_build_object(
    'fase_7_aplicacao', v_auditoria,
    'operacoes_aplicadas', coalesce(v_parcela_origem.metadata->'operacoes_aplicadas', '[]'::jsonb) || jsonb_build_array(v_auditoria)
  );

  v_metadata_operacao := jsonb_build_object('fase_7_aplicacao', v_auditoria);
  v_metadata_agenda := jsonb_build_object('fase_7_ultima_aplicacao', v_auditoria);

  update public.mesa_cliente_fluxo_parcelas
  set valor_atual = v_valor_atual_final,
      data_atual = v_data_atual_final,
      atualizado_por = v_auth_uid,
      metadata = coalesce(metadata, '{}'::jsonb) || v_metadata_parcela,
      updated_at = v_now
  where id = v_parcela_origem.id
  returning * into v_parcela_origem_atualizada;

  update public.mesa_cliente_fluxo_operacoes
  set status_operacao = 'aplicada',
      confirmado = true,
      confirmado_por = coalesce(confirmado_por, v_auth_uid),
      confirmado_em = coalesce(confirmado_em, v_now),
      visivel_cliente = false,
      metadata = coalesce(metadata, '{}'::jsonb) || v_metadata_operacao,
      updated_at = v_now
  where id = v_operacao.id
  returning * into v_operacao_atualizada;

  update public.mesa_cliente_agendas_financeiras
  set metadata = coalesce(metadata, '{}'::jsonb) || v_metadata_agenda,
      totais = coalesce(totais, '{}'::jsonb) || jsonb_build_object(
        'fase_7_ultima_delta_valor', v_delta_valor,
        'fase_7_ultima_aplicacao_em', v_now,
        'fase_7_ultima_operacao_id', v_operacao.id
      ),
      updated_at = v_now
  where id = v_agenda.id;

  return jsonb_build_object(
    'ok', true,
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'visao', 'administrativa',
    'cliente_safe', false,
    'readonly', false,
    'dml_financeiro', true,
    'altera_operacao', true,
    'altera_agenda', true,
    'altera_parcelas', true,
    'recalcula_operacao', false,
    'operacao_id', v_operacao_atualizada.id,
    'agenda_id', v_operacao_atualizada.agenda_id,
    'simulacao_id', v_operacao_atualizada.simulacao_id,
    'empresa_id', v_operacao_atualizada.empresa_id,
    'status_operacao_anterior', v_status_anterior,
    'status_operacao_final', v_operacao_atualizada.status_operacao,
    'parcelas_afetadas', jsonb_build_array(
      jsonb_build_object(
        'id', v_parcela_origem_atualizada.id,
        'papel', 'origem',
        'grupo', v_parcela_origem_atualizada.grupo,
        'descricao', v_parcela_origem_atualizada.descricao,
        'valor_atual_anterior', v_valor_atual_anterior,
        'valor_atual_final', v_parcela_origem_atualizada.valor_atual,
        'delta_valor', v_delta_valor,
        'data_atual_anterior', v_data_atual_anterior,
        'data_atual_final', v_parcela_origem_atualizada.data_atual
      )
    ),
    'resumo_aplicacao', jsonb_build_object(
      'tipo_operacao', v_operacao_atualizada.tipo_operacao::text,
      'valor_base', v_valor_base,
      'valor_movido', v_valor_movido,
      'desconto_calculado', v_desconto,
      'acrescimo_calculado', v_acrescimo,
      'economia_liquida', v_operacao_atualizada.economia_liquida,
      'delta_valor_parcela_origem', v_delta_valor
    ),
    'auditoria', jsonb_build_object(
      'executado_por', v_auth_uid,
      'executado_em', v_now,
      'metadata_key', 'fase_7_aplicacao'
    )
  );
end;
$function$;

comment on function public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
is 'FECH.AI MesaCliente Fase 7: aplica operacao financeira confirmada sobre agenda/parcela com DML controlado, tenant-safe, locks transacionais, auditoria e bloqueio de autoridade soberana do frontend.';

revoke all on function public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb) from public;
revoke all on function public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb) from anon;
grant execute on function public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb) to authenticated;
grant execute on function public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb) to service_role;
