-- Mesa Cliente — Correção de RPCs geradas com tabela inexistente `perfis`
--
-- Problema observado na preview:
--   relation "perfis" does not exist
--
-- Causa:
--   Algumas RPCs da Mesa Cliente foram criadas assumindo uma tabela `perfis`,
--   mas o schema real do FECH.AI usa `corretores`.
--
-- Correção:
--   - get_empreendimentos_mesa passa a fazer join com corretores.
--   - get_historico_mesas passa a fazer join com corretores.
--   - registrar_upload_arquivo_mesa passa a buscar nome/empresa em corretores.
--   - Mantém validação por auth.uid(), tenant e root/admin.

create or replace function public.get_empreendimentos_mesa(p_empresa_id uuid)
returns table(
  id uuid,
  nome text,
  incorporadora text,
  bairro text,
  cidade text,
  tabela_status text,
  tabela_data timestamptz,
  tabela_tipo text,
  tabela_enviado_por text,
  tabela_dias_atras integer,
  espelho_status text,
  espelho_data timestamptz,
  espelho_enviado_por text,
  espelho_dias_atras integer,
  pode_abrir_mesa boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_empresa_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.empresa_id
    into v_user_empresa_id
  from public.corretores c
  where c.user_id = auth.uid()
    and coalesce(c.ativo, true) = true
  limit 1;

  if not public.is_root() and v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado à empresa informada';
  end if;

  return query
  with tabelas as (
    select distinct on (ea.empreendimento_id)
      ea.empreendimento_id,
      ea.data_referencia,
      ea.tipo_arquivo,
      c.nome as enviado_por_nome,
      extract(day from now() - ea.data_referencia)::int as dias_atras
    from public.estoque_arquivos ea
    left join public.corretores c on c.user_id = ea.enviado_por
    where ea.empresa_id = p_empresa_id
      and ea.tipo_arquivo in ('tabela_trabalho','tabela_oficial')
      and ea.status_processamento = 'processado'
    order by ea.empreendimento_id, ea.data_referencia desc nulls last, ea.created_at desc
  ),
  espelhos as (
    select distinct on (ea.empreendimento_id)
      ea.empreendimento_id,
      ea.data_referencia,
      c.nome as enviado_por_nome,
      extract(day from now() - ea.data_referencia)::int as dias_atras
    from public.estoque_arquivos ea
    left join public.corretores c on c.user_id = ea.enviado_por
    where ea.empresa_id = p_empresa_id
      and ea.tipo_arquivo = 'espelho'
      and ea.status_processamento = 'processado'
    order by ea.empreendimento_id, ea.data_referencia desc nulls last, ea.created_at desc
  )
  select
    e.id,
    e.nome,
    e.incorporadora,
    e.bairro,
    e.cidade,
    case when t.dias_atras is null then 'red' when t.dias_atras > 45 then 'red' when t.dias_atras > 35 then 'yellow' else 'ok' end as tabela_status,
    t.data_referencia as tabela_data,
    case t.tipo_arquivo when 'tabela_oficial' then 'oficial' when 'tabela_trabalho' then 'trabalho' else null end as tabela_tipo,
    t.enviado_por_nome as tabela_enviado_por,
    t.dias_atras as tabela_dias_atras,
    case when es.dias_atras is null then 'red' when es.dias_atras > 2 then 'red' when es.dias_atras = 1 then 'yellow' else 'ok' end as espelho_status,
    es.data_referencia as espelho_data,
    es.enviado_por_nome as espelho_enviado_por,
    es.dias_atras as espelho_dias_atras,
    (t.dias_atras is not null and t.dias_atras <= 45) as pode_abrir_mesa
  from public.empreendimentos e
  inner join tabelas t on t.empreendimento_id = e.id
  left join espelhos es on es.empreendimento_id = e.id
  where e.empresa_id = p_empresa_id
    and e.status = 'ativo'
  order by e.nome;
end;
$$;

revoke all on function public.get_empreendimentos_mesa(uuid) from public;
grant execute on function public.get_empreendimentos_mesa(uuid) to authenticated;

create or replace function public.get_historico_mesas(
  p_empresa_id uuid,
  p_corretor_id uuid default null,
  p_emp_id uuid default null,
  p_status text default null,
  p_busca text default null,
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
  v_user_empresa_id uuid;
  v_corretor_uuid uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.empresa_id, c.id
    into v_user_empresa_id, v_corretor_uuid
  from public.corretores c
  where c.user_id = auth.uid()
    and coalesce(c.ativo, true) = true
  limit 1;

  if not public.is_root() and v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado à empresa informada';
  end if;

  if p_corretor_id is not null
     and not public.is_root()
     and p_corretor_id is distinct from v_corretor_uuid
     and not (public.is_gestor() or public.is_admin_local()) then
    raise exception 'Acesso negado ao histórico do corretor informado';
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
    and (p_corretor_id is null or ms.corretor_id = p_corretor_id)
    and (p_emp_id is null or ms.empreendimento_id = p_emp_id)
    and (p_status is null or ms.status::text = p_status)
    and (p_busca is null or ms.cliente_nome ilike '%'||p_busca||'%' or ue.unidade ilike '%'||p_busca||'%')
  order by ms.updated_at desc
  limit p_limit offset p_offset;
end;
$$;

revoke all on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) from public;
grant execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) to authenticated;

create or replace function public.registrar_upload_arquivo_mesa(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_tipo_arquivo text,
  p_nome_arquivo text,
  p_storage_path text default null,
  p_observacoes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_usuario_id uuid := auth.uid();
  v_usuario_nome text;
  v_user_empresa_id uuid;
  v_emp_empresa_id uuid;
begin
  if v_usuario_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.nome, c.empresa_id
    into v_usuario_nome, v_user_empresa_id
  from public.corretores c
  where c.user_id = v_usuario_id
    and coalesce(c.ativo, true) = true
  limit 1;

  select e.empresa_id
    into v_emp_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id
    and e.status = 'ativo'
  limit 1;

  if v_emp_empresa_id is null then
    raise exception 'Empreendimento não encontrado ou inativo';
  end if;

  if not public.is_root() and (v_user_empresa_id is distinct from p_empresa_id or v_emp_empresa_id is distinct from p_empresa_id) then
    raise exception 'Acesso negado à empresa/empreendimento informado';
  end if;

  insert into public.estoque_arquivos (
    empresa_id,
    empreendimento_id,
    enviado_por,
    nome_arquivo,
    tipo_arquivo,
    storage_path,
    status_processamento,
    data_referencia,
    observacoes
  ) values (
    p_empresa_id,
    p_empreendimento_id,
    v_usuario_id,
    p_nome_arquivo,
    p_tipo_arquivo,
    p_storage_path,
    'pendente',
    now(),
    p_observacoes
  ) returning id into v_id;

  insert into public.audit_logs (empresa_id, usuario_id, acao, tabela_afetada, registro_id, detalhes)
  values (
    p_empresa_id,
    v_usuario_id,
    'upload_arquivo_mesa',
    'estoque_arquivos',
    v_id,
    jsonb_build_object(
      'tipo_arquivo', p_tipo_arquivo,
      'nome_arquivo', p_nome_arquivo,
      'empreendimento_id', p_empreendimento_id,
      'enviado_por', v_usuario_nome,
      'enviado_em', now()
    )
  );

  return v_id;
end;
$$;

revoke all on function public.registrar_upload_arquivo_mesa(uuid, uuid, text, text, text, text) from public;
grant execute on function public.registrar_upload_arquivo_mesa(uuid, uuid, text, text, text, text) to authenticated;
