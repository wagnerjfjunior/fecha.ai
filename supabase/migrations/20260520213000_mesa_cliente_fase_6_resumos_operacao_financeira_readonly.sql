-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- Resumos read-only de operação financeira: visão administrativa e visão cliente-safe.

create or replace function public.mesa_cliente_resumir_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_auth_uid uuid := auth.uid();
  v_corretor public.corretores%rowtype;
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;
  v_simulacao public.mesa_simulacoes%rowtype;
  v_bad_key text;
  v_admin boolean := false;
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_forbidden text[] := array[
    'empresa_id','tenant_id','simulacao_id','agenda_id','corretor_id','user_id','auth_uid',
    'role','perfil','is_admin','is_gestor','is_admin_local','criado_por','confirmado_por',
    'cancelado_por','politica_id','empreendimento_id','status_operacao','tipo_operacao',
    'valor_movido','valor_base','taxa_ano_pct','vpl_aplicado_pct','desconto_calculado',
    'acrescimo_calculado','economia_liquida','premio_corretor_pct','status_premio',
    'visivel_cliente','checksum_operacao','metadata','cliente_safe','visao'
  ];
begin
  if v_auth_uid is null then raise exception using errcode = '28000', message = 'auth_required'; end if;
  if p_operacao_id is null then raise exception using errcode = '22023', message = 'p_operacao_id_required'; end if;
  if jsonb_typeof(v_params) <> 'object' then raise exception using errcode = '22023', message = 'p_parametros_must_be_object'; end if;

  select k into v_bad_key from jsonb_object_keys(v_params) as t(k) where k = any(v_forbidden) limit 1;
  if v_bad_key is not null then raise exception using errcode = '42501', message = 'frontend_authority_forbidden:' || v_bad_key; end if;

  select c.* into v_corretor
  from public.corretores c
  where c.user_id = v_auth_uid and coalesce(c.ativo, true) = true
  order by case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 when c.role = 'coordenador' then 4 else 5 end,
           c.created_at desc nulls last, c.id
  limit 1;
  if not found then raise exception using errcode = '28000', message = 'active_corretor_not_found'; end if;

  v_admin := coalesce(v_corretor.role, '') in ('admin_global','admin_local','gestor','coordenador')
             or coalesce(v_corretor.is_admin_local, false)
             or coalesce(v_corretor.is_gestor, false);
  if not v_admin then raise exception using errcode = '42501', message = 'admin_profile_required'; end if;

  select o.* into v_operacao from public.mesa_cliente_fluxo_operacoes o where o.id = p_operacao_id limit 1;
  if not found then raise exception using errcode = 'P0002', message = 'operacao_not_found'; end if;

  if coalesce(v_corretor.role, '') <> 'admin_global' and v_corretor.empresa_id is distinct from v_operacao.empresa_id then
    raise exception using errcode = '42501', message = 'cross_tenant_denied';
  end if;

  select s.* into v_simulacao from public.mesa_simulacoes s where s.id = v_operacao.simulacao_id and s.empresa_id = v_operacao.empresa_id limit 1;
  if not found then raise exception using errcode = 'P0002', message = 'simulacao_not_found'; end if;

  return jsonb_build_object(
    'ok', true,
    'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
    'visao', 'administrativa',
    'cliente_safe', false,
    'readonly', true,
    'dml_financeiro', false,
    'altera_agenda', false,
    'altera_parcelas', false,
    'altera_operacao', false,
    'recalcula_operacao', false,
    'ids', jsonb_strip_nulls(jsonb_build_object('operacao_id', v_operacao.id, 'simulacao_id', v_operacao.simulacao_id, 'agenda_id', v_operacao.agenda_id, 'empresa_id', v_operacao.empresa_id, 'empreendimento_id', v_operacao.empreendimento_id, 'politica_id', v_operacao.politica_id)),
    'operacao', jsonb_strip_nulls(jsonb_build_object('tipo_operacao', v_operacao.tipo_operacao::text, 'status_operacao', v_operacao.status_operacao, 'confirmado', v_operacao.confirmado, 'confirmado_por', v_operacao.confirmado_por, 'confirmado_em', v_operacao.confirmado_em, 'cancelado_por', v_operacao.cancelado_por, 'cancelado_em', v_operacao.cancelado_em, 'motivo_cancelamento', v_operacao.motivo_cancelamento, 'visivel_cliente', v_operacao.visivel_cliente, 'checksum_operacao', v_operacao.checksum_operacao, 'grupo_origem', v_operacao.grupo_origem, 'grupo_destino', v_operacao.grupo_destino, 'parcela_origem_id', v_operacao.parcela_origem_id, 'parcela_destino_id', v_operacao.parcela_destino_id, 'created_at', v_operacao.created_at, 'updated_at', v_operacao.updated_at)),
    'resumo_financeiro_admin', jsonb_build_object('valor_movido', v_operacao.valor_movido, 'valor_base', v_operacao.valor_base, 'data_origem', v_operacao.data_origem, 'data_destino', v_operacao.data_destino, 'taxa_ano_pct', v_operacao.taxa_ano_pct, 'vpl_aplicado_pct', v_operacao.vpl_aplicado_pct, 'desconto_calculado', v_operacao.desconto_calculado, 'acrescimo_calculado', v_operacao.acrescimo_calculado, 'economia_liquida', v_operacao.economia_liquida, 'dias_calculo', v_operacao.dias_calculo, 'premio_corretor_pct', v_operacao.premio_corretor_pct, 'status_premio', v_operacao.status_premio),
    'simulacao', jsonb_strip_nulls(jsonb_build_object('cliente_nome', v_simulacao.cliente_nome, 'status', v_simulacao.status::text, 'corretor_id', v_simulacao.corretor_id, 'valor_total', v_simulacao.valor_total, 'entrada', v_simulacao.entrada, 'financiamento', v_simulacao.financiamento, 'valor_final', v_simulacao.valor_final, 'oficial', v_simulacao.oficial)),
    'flags_integridade', jsonb_build_object('tenant_consistente', v_simulacao.empresa_id = v_operacao.empresa_id, 'visivel_cliente', coalesce(v_operacao.visivel_cliente, false), 'tem_metadata', coalesce(v_operacao.metadata, '{}'::jsonb) <> '{}'::jsonb)
  );
end;
$$;

create or replace function public.mesa_cliente_obter_resumo_operacao_cliente_safe(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_auth_uid uuid := auth.uid();
  v_corretor public.corretores%rowtype;
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;
  v_simulacao public.mesa_simulacoes%rowtype;
  v_origem public.mesa_cliente_fluxo_parcelas%rowtype;
  v_destino public.mesa_cliente_fluxo_parcelas%rowtype;
  v_bad_key text;
  v_admin boolean := false;
  v_status_comercial text;
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);
  v_forbidden text[] := array[
    'empresa_id','tenant_id','simulacao_id','agenda_id','corretor_id','user_id','auth_uid',
    'role','perfil','is_admin','is_gestor','is_admin_local','criado_por','confirmado_por',
    'cancelado_por','politica_id','empreendimento_id','status_operacao','tipo_operacao',
    'valor_movido','valor_base','taxa_ano_pct','vpl_aplicado_pct','desconto_calculado',
    'acrescimo_calculado','economia_liquida','premio_corretor_pct','status_premio',
    'visivel_cliente','checksum_operacao','metadata','cliente_safe','visao'
  ];
begin
  if v_auth_uid is null then raise exception using errcode = '28000', message = 'auth_required'; end if;
  if p_operacao_id is null then raise exception using errcode = '22023', message = 'p_operacao_id_required'; end if;
  if jsonb_typeof(v_params) <> 'object' then raise exception using errcode = '22023', message = 'p_parametros_must_be_object'; end if;

  select k into v_bad_key from jsonb_object_keys(v_params) as t(k) where k = any(v_forbidden) limit 1;
  if v_bad_key is not null then raise exception using errcode = '42501', message = 'frontend_authority_forbidden:' || v_bad_key; end if;

  select c.* into v_corretor
  from public.corretores c
  where c.user_id = v_auth_uid and coalesce(c.ativo, true) = true
  order by case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 when c.role = 'coordenador' then 4 else 5 end,
           c.created_at desc nulls last, c.id
  limit 1;
  if not found then raise exception using errcode = '28000', message = 'active_corretor_not_found'; end if;

  v_admin := coalesce(v_corretor.role, '') in ('admin_global','admin_local','gestor','coordenador')
             or coalesce(v_corretor.is_admin_local, false)
             or coalesce(v_corretor.is_gestor, false);

  select o.* into v_operacao from public.mesa_cliente_fluxo_operacoes o where o.id = p_operacao_id limit 1;
  if not found then raise exception using errcode = 'P0002', message = 'operacao_not_found'; end if;

  if coalesce(v_corretor.role, '') <> 'admin_global' and v_corretor.empresa_id is distinct from v_operacao.empresa_id then
    raise exception using errcode = '42501', message = 'cross_tenant_denied';
  end if;

  select s.* into v_simulacao from public.mesa_simulacoes s where s.id = v_operacao.simulacao_id and s.empresa_id = v_operacao.empresa_id limit 1;
  if not found then raise exception using errcode = 'P0002', message = 'simulacao_not_found'; end if;

  if not v_admin and v_simulacao.corretor_id is distinct from v_corretor.id then
    raise exception using errcode = '42501', message = 'corretor_scope_denied';
  end if;

  if coalesce(v_operacao.visivel_cliente, false) is false then
    raise exception using errcode = '42501', message = 'cliente_safe_not_released';
  end if;

  if v_operacao.parcela_origem_id is not null then
    select p.* into v_origem from public.mesa_cliente_fluxo_parcelas p where p.id = v_operacao.parcela_origem_id and p.simulacao_id = v_operacao.simulacao_id and p.empresa_id = v_operacao.empresa_id limit 1;
  end if;
  if v_operacao.parcela_destino_id is not null then
    select p.* into v_destino from public.mesa_cliente_fluxo_parcelas p where p.id = v_operacao.parcela_destino_id and p.simulacao_id = v_operacao.simulacao_id and p.empresa_id = v_operacao.empresa_id limit 1;
  end if;

  v_status_comercial := case when v_operacao.status_operacao = 'confirmada' and coalesce(v_operacao.confirmado, false) then 'condicao_confirmada' when v_operacao.status_operacao = 'cancelada' then 'condicao_cancelada' else 'condicao_em_analise' end;

  return jsonb_build_object(
    'ok', true,
    'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
    'visao', 'cliente_safe',
    'cliente_safe', true,
    'readonly', true,
    'dml_financeiro', false,
    'altera_agenda', false,
    'altera_parcelas', false,
    'altera_operacao', false,
    'recalcula_operacao', false,
    'status_comercial', v_status_comercial,
    'resumo_condicao', jsonb_strip_nulls(jsonb_build_object('tipo_operacao', v_operacao.tipo_operacao::text, 'status', v_status_comercial, 'valor_negociado', v_operacao.valor_movido, 'valor_referencia', v_operacao.valor_base, 'data_original', v_operacao.data_origem, 'nova_data', v_operacao.data_destino, 'desconto_comercial', nullif(v_operacao.desconto_calculado, 0), 'acrescimo_comercial', nullif(v_operacao.acrescimo_calculado, 0))),
    'cliente', jsonb_strip_nulls(jsonb_build_object('nome', v_simulacao.cliente_nome)),
    'parcelas_impactadas', jsonb_build_object(
      'origem', case when v_operacao.parcela_origem_id is null then null else jsonb_strip_nulls(jsonb_build_object('grupo', v_origem.grupo, 'descricao', v_origem.descricao, 'ordem', v_origem.ordem, 'valor_original', v_origem.valor_original, 'valor_atual', v_origem.valor_atual, 'data_original', v_origem.data_original, 'data_atual', v_origem.data_atual)) end,
      'destino', case when v_operacao.parcela_destino_id is null then null else jsonb_strip_nulls(jsonb_build_object('grupo', v_destino.grupo, 'descricao', v_destino.descricao, 'ordem', v_destino.ordem, 'valor_original', v_destino.valor_original, 'valor_atual', v_destino.valor_atual, 'data_original', v_destino.data_original, 'data_atual', v_destino.data_atual)) end
    ),
    'avisos', jsonb_build_array('cliente_safe_sem_taxa_vpl_premio_politica_checksum_metadata_payload_bruto', 'condicao_sujeita_a_validacao_comercial_conforme_status')
  );
end;
$$;

revoke all on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb) from public;
revoke all on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb) from anon;
grant execute on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb) to authenticated;
comment on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb) is 'FECH.AI MesaCliente Fase 6: resumo administrativo read-only de operacao financeira, tenant-safe, sem DML financeiro.';

revoke all on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb) from public;
revoke all on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb) from anon;
grant execute on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb) to authenticated;
comment on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb) is 'FECH.AI MesaCliente Fase 6: resumo cliente-safe read-only, separado da visao admin, sem VPL/taxa/premio/politica/checksum/metadata.';
