-- FECH.AI / MesaCliente — Fase 20A.2
-- Ajuste de precedência da regra comercial.
-- Corretor dono da simulação acessa por ownership mesmo se também possuir flags administrativas.
-- Admin/root não donos continuam bloqueados pela RPC comum.

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
  v_user_is_admin_local boolean := false;
  v_user_role text;
  v_owner_empresa_id uuid;
  v_owner_time_id uuid;
  v_ms public.mesa_simulacoes%rowtype;
  v_payload jsonb;
  v_acesso_por text;
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
         coalesce(c.is_admin_local, false),
         c.role
    into v_user_empresa_id,
         v_user_corretor_id,
         v_user_time_id,
         v_user_is_gestor,
         v_user_is_admin_local,
         v_user_role
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
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

  if v_ms.corretor_id = v_user_corretor_id then
    v_acesso_por := 'corretor_dono';
  elsif v_user_role in ('admin_global', 'root')
        or v_user_is_admin_local = true then
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
    'corretor', (
      select jsonb_build_object(
        'id', c.id,
        'nome', c.nome,
        'email', c.email,
        'user_id', c.user_id,
        'empresa_id', c.empresa_id,
        'time_id', c.time_id,
        'role', c.role,
        'is_gestor', coalesce(c.is_gestor, false),
        'is_admin_local', coalesce(c.is_admin_local, false)
      )
      from public.corretores c
      where c.id = v_ms.corretor_id
    ),
    'empreendimento', (
      select jsonb_build_object(
        'id', e.id,
        'empresa_id', e.empresa_id,
        'nome', e.nome,
        'incorporadora', e.incorporadora,
        'bairro', e.bairro,
        'cidade', e.cidade
      )
      from public.empreendimentos e
      where e.id = v_ms.empreendimento_id
    ),
    'unidade', (
      select jsonb_build_object(
        'id', ue.id,
        'empresa_id', ue.empresa_id,
        'empreendimento_id', ue.empreendimento_id,
        'torre', ue.torre,
        'unidade', ue.unidade,
        'final', ue.final,
        'andar', ue.andar,
        'metragem', ue.metragem,
        'dormitorios', ue.dormitorios,
        'suites', ue.suites,
        'vagas_quantidade', ue.vagas_quantidade,
        'valor_tabela', ue.valor_tabela,
        'planta_tipo', ue.planta_tipo,
        'status_comercial', ue.status_comercial::text
      )
      from public.unidades_estoque ue
      where ue.id = v_ms.unidade_estoque_id
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
      'is_admin_local', v_user_is_admin_local,
      'role', v_user_role,
      'acesso_por', v_acesso_por,
      'payload_soberano_frontend', false
    )
  ) into v_payload;

  return v_payload;
end;
$$;

revoke execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) from public;
revoke execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) from anon;
grant execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) to authenticated;
comment on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb)
is 'Fase 20A.2: leitura tenant-safe/read-only de fluxo histórico. Corretor dono tem precedência; demais acessos restritos a gestor do mesmo time. Admin/root não acessam por esta RPC comum quando não são donos.';
