-- FECH.AI — MesaCliente
-- Fase 8H — Correção cirúrgica da RPC criar_mesa_simulacao
-- Objetivo: corrigir FK de corretor_id e alinhar audit_logs ao schema real.
-- Escopo: somente CREATE OR REPLACE FUNCTION public.criar_mesa_simulacao.
-- Não altera tabelas, enums, RLS, policies, grants, parser, Worker, Make/n8n, frontend ou motor financeiro.

create or replace function public.criar_mesa_simulacao(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_unidade_id uuid default null::uuid,
  p_lead_id uuid default null::uuid,
  p_cliente_nome text default null::text,
  p_valor_total numeric default 0,
  p_meta_obra_pct integer default 30,
  p_tabela_provisoria boolean default false,
  p_fluxo_json jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_id uuid;
  v_auth_uid uuid;
  v_corretor_id uuid;
  v_user_empresa_id uuid;
  v_target_empresa_id uuid;
  v_item jsonb;
  v_ordem int := 0;
  v_obra_total numeric := 0;
  v_fin_total numeric := 0;
  v_tipo_fluxo mesa_fluxo_tipo;
  v_valor_tabela numeric := 0;
  v_desconto_valor numeric := 0;
  v_desconto_validacao jsonb := '{}'::jsonb;
  v_audit_payload jsonb := '{}'::jsonb;
  v_is_root boolean := false;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_empresa_id is null then
    raise exception 'Empresa obrigatória para criar mesa';
  end if;

  if p_empreendimento_id is null then
    raise exception 'Empreendimento obrigatório para criar mesa';
  end if;

  if p_valor_total is null or p_valor_total <= 0 then
    raise exception 'Valor total inválido para criar mesa';
  end if;

  if p_fluxo_json is null or jsonb_typeof(p_fluxo_json) <> 'array' then
    raise exception 'Fluxo de pagamento inválido';
  end if;

  v_is_root := coalesce(public.is_root(), false);

  select c.id, c.empresa_id
    into v_corretor_id, v_user_empresa_id
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
  limit 1;

  select e.empresa_id
    into v_target_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id
    and e.status = 'ativo'
  limit 1;

  if v_target_empresa_id is null then
    raise exception 'Empreendimento não encontrado ou inativo';
  end if;

  if v_target_empresa_id is distinct from p_empresa_id then
    raise exception 'Empresa informada não pertence ao empreendimento';
  end if;

  if v_corretor_id is null then
    raise exception 'Usuário sem corretor ativo vinculado';
  end if;

  if not v_is_root and v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado para criar mesa nesta empresa';
  end if;

  if p_unidade_id is not null then
    select ue.valor_tabela
      into v_valor_tabela
    from public.unidades_estoque ue
    where ue.id = p_unidade_id
      and ue.empresa_id = p_empresa_id
      and ue.empreendimento_id = p_empreendimento_id
    limit 1;

    if v_valor_tabela is null then
      raise exception 'Unidade não encontrada para a empresa/empreendimento informado';
    end if;

    v_desconto_valor := greatest(0, v_valor_tabela - p_valor_total);
    v_desconto_validacao := public.validar_mesa_cliente_desconto(
      p_empreendimento_id,
      v_valor_tabela,
      v_desconto_valor
    );

    if coalesce((v_desconto_validacao->>'bloqueado')::boolean, false) then
      raise exception 'Desconto proibido pela política comercial configurada. Reduza o desconto ou solicite aprovação gerencial.';
    end if;
  end if;

  for v_item in select * from jsonb_array_elements(p_fluxo_json) loop
    if (v_item->>'grupo') in ('e','c','m','a','u') then
      v_obra_total := v_obra_total + coalesce((v_item->>'total')::numeric, 0);
    else
      v_fin_total := v_fin_total + coalesce((v_item->>'total')::numeric, 0);
    end if;
  end loop;

  insert into public.mesa_simulacoes (
    empresa_id,
    corretor_id,
    lead_id,
    empreendimento_id,
    unidade_estoque_id,
    cliente_nome,
    status,
    valor_total,
    entrada,
    financiamento,
    snapshot_payload
  ) values (
    p_empresa_id,
    v_corretor_id,
    p_lead_id,
    p_empreendimento_id,
    p_unidade_id,
    p_cliente_nome,
    case
      when coalesce((v_desconto_validacao->>'requer_aprovacao')::boolean, false)
        then 'em_analise'::public.mesa_simulacao_status
      else 'rascunho'::public.mesa_simulacao_status
    end,
    p_valor_total,
    v_obra_total,
    v_fin_total,
    jsonb_build_object(
      'meta_obra_pct', p_meta_obra_pct,
      'tabela_provisoria', p_tabela_provisoria,
      'criado_por', v_corretor_id,
      'criado_por_user_id', v_auth_uid,
      'valor_tabela', nullif(v_valor_tabela, 0),
      'valor_negociado', p_valor_total,
      'desconto_valor', v_desconto_valor,
      'desconto_validacao', v_desconto_validacao
    )
  ) returning id into v_id;

  for v_item in select * from jsonb_array_elements(p_fluxo_json) loop
    v_tipo_fluxo := case (v_item->>'grupo')
      when 'e' then 'entrada'::mesa_fluxo_tipo
      when 'c' then 'entrada'::mesa_fluxo_tipo
      when 'm' then 'periodica'::mesa_fluxo_tipo
      when 'a' then 'periodica'::mesa_fluxo_tipo
      when 'u' then 'unica'::mesa_fluxo_tipo
      else 'financiamento'::mesa_fluxo_tipo
    end;

    insert into public.mesa_fluxo_pagamentos (
      empresa_id,
      simulacao_id,
      tipo,
      descricao,
      valor,
      quantidade,
      periodicidade,
      data_prevista,
      ordem
    ) values (
      p_empresa_id,
      v_id,
      v_tipo_fluxo,
      v_item->>'label',
      coalesce((v_item->>'valor')::numeric, 0),
      coalesce((v_item->>'qty')::int, 1),
      v_item->>'periodicidade',
      nullif(v_item->>'date', '')::date,
      v_ordem
    );

    v_ordem := v_ordem + 1;
  end loop;

  v_audit_payload := jsonb_build_object(
    'cliente_nome', p_cliente_nome,
    'valor_total', p_valor_total,
    'valor_tabela', nullif(v_valor_tabela, 0),
    'desconto_valor', v_desconto_valor,
    'desconto_validacao', v_desconto_validacao,
    'tabela_provisoria', p_tabela_provisoria,
    'num_parcelas', jsonb_array_length(p_fluxo_json),
    'simulacao_id', v_id,
    'corretor_id', v_corretor_id,
    'auth_uid', v_auth_uid
  );

  insert into public.audit_logs (
    empresa_id,
    action,
    actor_id,
    payload,
    ator_user_id,
    ator_corretor_id,
    acao,
    entidade,
    entidade_id,
    depois
  ) values (
    p_empresa_id,
    'criar_mesa_simulacao',
    v_auth_uid,
    v_audit_payload,
    v_auth_uid,
    v_corretor_id,
    'criar_mesa_simulacao',
    'mesa_simulacoes',
    v_id,
    v_audit_payload
  );

  return v_id;
end;
$function$;
