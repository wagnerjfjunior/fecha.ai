-- FECH.AI / MesaCliente — Fase 20A.5
-- Matriz final de visibilidade comercial para histórico e reabertura de fluxo.
-- Regra normativa:
--   1. Corretor dono acessa.
--   2. Gestor do mesmo time do corretor dono acessa, inclusive se também for admin_local.
--   3. Admin local puro não amplia acesso a propostas de terceiros.
--   4. Admin global/root não acessam proposta comercial pela RPC comum.
--   5. Outro tenant/empresa nunca acessa.
--   6. Frontend não envia payload soberano de empresa/time/corretor; a resolução é feita por auth.uid().

create or replace function public.get_historico_mesas(
  p_empresa_id uuid,
  p_corretor_id uuid default null::uuid,
  p_emp_id uuid default null::uuid,
  p_status text default null::text,
  p_busca text default null::text,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  id uuid,
  cliente_nome text,
  corretor_nome text,
  empreendimento text,
  incorporadora text,
  unidade text,
  valor_total numeric,
  status text,
  tabela_provisoria boolean,
  criado_em timestamptz,
  atualizado_em timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_user_empresa_id uuid;
  v_user_corretor_id uuid;
  v_user_time_id uuid;
  v_user_is_gestor boolean := false;
  v_user_is_admin_local boolean := false;
  v_user_role text;
  v_admin_global_like boolean := false;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.empresa_id,
         c.id,
         c.time_id,
         coalesce(c.is_gestor, false),
         coalesce(c.is_admin_local, false),
         coalesce(c.role, '')
    into v_user_empresa_id,
         v_user_corretor_id,
         v_user_time_id,
         v_user_is_gestor,
         v_user_is_admin_local,
         v_user_role
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

  if v_user_corretor_id is null then
    raise exception 'Usuário sem corretor ativo vinculado';
  end if;

  if v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado à empresa informada';
  end if;

  v_admin_global_like := v_user_role in ('admin_global', 'root');

  if p_corretor_id is not null then
    if p_corretor_id = v_user_corretor_id then
      null;
    elsif v_admin_global_like then
      raise exception 'Acesso negado ao histórico do corretor informado';
    elsif v_user_is_gestor = true and exists (
      select 1
      from public.corretores c_alvo
      where c_alvo.id = p_corretor_id
        and c_alvo.empresa_id = v_user_empresa_id
        and c_alvo.time_id is not null
        and v_user_time_id is not null
        and c_alvo.time_id = v_user_time_id
    ) then
      null;
    else
      raise exception 'Acesso negado ao histórico do corretor informado';
    end if;
  end if;

  return query
  select
    ms.id,
    ms.cliente_nome,
    c.nome as corretor_nome,
    e.nome as empreendimento,
    e.incorporadora,
    ue.unidade,
    ms.valor_total,
    ms.status::text,
    coalesce((ms.snapshot_payload->>'tabela_provisoria')::boolean, false) as tabela_provisoria,
    ms.created_at,
    ms.updated_at
  from public.mesa_simulacoes ms
  left join public.corretores c on c.id = ms.corretor_id
  left join public.empreendimentos e on e.id = ms.empreendimento_id
  left join public.unidades_estoque ue on ue.id = ms.unidade_estoque_id
  where ms.empresa_id = p_empresa_id
    and (
      ms.corretor_id = v_user_corretor_id
      or (
        v_admin_global_like = false
        and v_user_is_gestor = true
        and c.empresa_id = v_user_empresa_id
        and c.time_id is not null
        and v_user_time_id is not null
        and c.time_id = v_user_time_id
      )
    )
    and (p_corretor_id is null or ms.corretor_id = p_corretor_id)
    and (p_emp_id is null or ms.empreendimento_id = p_emp_id)
    and (p_status is null or ms.status::text = p_status)
    and (p_busca is null or ms.cliente_nome ilike '%'||p_busca||'%' or ue.unidade ilike '%'||p_busca||'%')
  order by ms.updated_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 200))
  offset greatest(0, coalesce(p_offset, 0));
end;
$$;

create or replace function public.mesa_cliente_obter_simulacao_fluxo_historico(
  p_simulacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_user_empresa_id uuid;
  v_user_corretor_id uuid;
  v_user_time_id uuid;
  v_user_is_gestor boolean := false;
  v_user_role text;
  v_owner_empresa_id uuid;
  v_owner_time_id uuid;
  v_ms public.mesa_simulacoes%rowtype;
  v_payload jsonb;
  v_acesso_por text;
  v_admin_global_like boolean := false;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_simulacao_id is null then
    raise exception 'Simulação obrigatória';
  end if;

  select c.empresa_id,
         c.id,
         c.time_id,
         coalesce(c.is_gestor, false),
         coalesce(c.role, '')
    into v_user_empresa_id,
         v_user_corretor_id,
         v_user_time_id,
         v_user_is_gestor,
         v_user_role
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

  if v_user_corretor_id is null then
    raise exception 'Usuário sem corretor ativo vinculado';
  end if;

  select ms.*
    into v_ms
  from public.mesa_simulacoes ms
  where ms.id = p_simulacao_id
  limit 1;

  if v_ms.id is null then
    raise exception 'Simulação não encontrada';
  end if;

  select c.empresa_id, c.time_id
    into v_owner_empresa_id, v_owner_time_id
  from public.corretores c
  where c.id = v_ms.corretor_id
  limit 1;

  if v_owner_empresa_id is null then
    raise exception 'Corretor dono da simulação não encontrado';
  end if;

  if v_user_empresa_id is distinct from v_ms.empresa_id
     or v_owner_empresa_id is distinct from v_ms.empresa_id then
    raise exception 'Acesso negado à simulação informada';
  end if;

  v_admin_global_like := v_user_role in ('admin_global', 'root');

  if v_ms.corretor_id = v_user_corretor_id then
    v_acesso_por := 'corretor_dono';
  elsif v_admin_global_like then
    raise exception 'Acesso negado ao fluxo da simulação';
  elsif v_user_is_gestor = true
        and v_user_time_id is not null
        and v_owner_time_id is not null
        and v_user_time_id = v_owner_time_id then
    v_acesso_por := 'gestor_mesmo_time';
  else
    raise exception 'Acesso negado ao fluxo da simulação';
  end if;

  select jsonb_build_object(
    'ok', true,
    'readonly', true,
    'cliente_safe', false,
    'source', 'historico',
    'simulacao', jsonb_build_object(
      'id', v_ms.id,
      'empresa_id', v_ms.empresa_id,
      'corretor_id', v_ms.corretor_id,
      'lead_id', v_ms.lead_id,
      'empreendimento_id', v_ms.empreendimento_id,
      'unidade_estoque_id', v_ms.unidade_estoque_id,
      'cliente_nome', v_ms.cliente_nome,
      'status', v_ms.status::text,
      'oficial', v_ms.oficial,
      'valor_total', v_ms.valor_total,
      'entrada', v_ms.entrada,
      'financiamento', v_ms.financiamento,
      'valor_final', v_ms.valor_final,
      'versao', v_ms.versao,
      'simulacao_origem_id', v_ms.simulacao_origem_id,
      'snapshot_payload', v_ms.snapshot_payload,
      'created_at', v_ms.created_at,
      'updated_at', v_ms.updated_at
    ),
    'fluxo', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', mfp.id,
          'ordem', mfp.ordem,
          'tipo', mfp.tipo::text,
          'grupo', case mfp.tipo::text
            when 'entrada' then 'e'
            when 'curto_prazo' then 'c'
            when 'periodica' then 'm'
            when 'intermediaria' then 'a'
            when 'quitacao' then 'u'
            when 'financiamento' then 'f'
            else null
          end,
          'descricao', mfp.descricao,
          'label', mfp.descricao,
          'valor', mfp.valor,
          'quantidade', mfp.quantidade,
          'qty', mfp.quantidade,
          'total', coalesce(mfp.valor, 0) * coalesce(mfp.quantidade, 1),
          'periodicidade', mfp.periodicidade,
          'data_prevista', mfp.data_prevista,
          'date', coalesce(mfp.data_prevista::text, ''),
          'source', 'historico'
        )
        order by mfp.ordem
      )
      from public.mesa_fluxo_pagamentos mfp
      where mfp.simulacao_id = v_ms.id
        and mfp.empresa_id = v_ms.empresa_id
    ), '[]'::jsonb),
    'ui_flags', jsonb_build_object(
      'pode_visualizar_fluxo', true,
      'pode_duplicar', true,
      'pode_editar_original', false,
      'motivo_edicao_original_bloqueada', 'Edição direta de histórico fora do escopo da Fase 20A.'
    ),
    'security', jsonb_build_object(
      'auth_uid', v_auth_uid,
      'resolved_corretor_id', v_user_corretor_id,
      'resolved_empresa_id', v_user_empresa_id,
      'resolved_time_id', v_user_time_id,
      'owner_corretor_id', v_ms.corretor_id,
      'owner_empresa_id', v_owner_empresa_id,
      'owner_time_id', v_owner_time_id,
      'is_gestor', v_user_is_gestor,
      'role', v_user_role,
      'acesso_por', v_acesso_por,
      'payload_soberano_frontend', false
    )
  ) into v_payload;

  return v_payload;
end;
$$;

revoke execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) from public;
revoke execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) from anon;
grant execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) to authenticated;

revoke execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) from public;
revoke execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) from anon;
grant execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) to authenticated;

comment on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer)
is 'Fase 20A.5: matriz final de visibilidade comercial. Dono acessa; gestor do mesmo time acessa; admin_global/root não acessam pela RPC comum; outro tenant bloqueado.';

comment on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb)
is 'Fase 20A.5: reabertura read-only de fluxo histórico com a mesma matriz final de visibilidade comercial do histórico.';
