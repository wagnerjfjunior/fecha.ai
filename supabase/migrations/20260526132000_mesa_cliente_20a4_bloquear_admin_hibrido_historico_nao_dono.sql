-- FECH.AI / MesaCliente — Fase 20A.4
-- Hardening do histórico de propostas.
-- Regra: dono acessa; gestor puro do mesmo time acessa; admin/root/admin_local não donos não ampliam escopo.
-- Observação: usuário híbrido admin_local + gestor não herda visão de gestor para proposta comercial de terceiros.

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
  v_admin_like boolean := false;
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

  v_admin_like := v_user_is_admin_local = true or v_user_role in ('admin_local', 'admin_global', 'root');

  if p_corretor_id is not null then
    if p_corretor_id = v_user_corretor_id then
      null;
    elsif v_admin_like then
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
        v_admin_like = false
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

revoke execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) from public;
revoke execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) from anon;
grant execute on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer) to authenticated;
comment on function public.get_historico_mesas(uuid, uuid, uuid, text, text, integer, integer)
is 'Fase 20A.4: histórico tenant-safe. Dono acessa; admin/root/admin_local não donos bloqueados mesmo se tiverem flag de gestor; gestor puro do mesmo time acessa.';
