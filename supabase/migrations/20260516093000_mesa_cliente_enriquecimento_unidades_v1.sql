-- Mesa Cliente — Enriquecimento manual de unidades por empreendimento/final

create table if not exists public.mesa_cliente_unidade_enriquecimentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null,
  empreendimento_id uuid not null references public.empreendimentos(id) on delete cascade,
  final text not null,
  dormitorios integer,
  suites integer,
  vagas_quantidade integer,
  orientacao_solar text,
  face text,
  vista text,
  observacoes text,
  criado_por uuid default auth.uid(),
  atualizado_por uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mesa_cliente_enriq_final_not_blank check (length(trim(final)) > 0),
  constraint mesa_cliente_enriq_orientacao_check check (
    orientacao_solar is null or orientacao_solar in ('manha','tarde','nascente','poente','norte','sul','leste','oeste','misto')
  ),
  unique (empreendimento_id, final)
);

create index if not exists idx_mesa_cliente_enriq_empresa_emp on public.mesa_cliente_unidade_enriquecimentos(empresa_id, empreendimento_id);
alter table public.mesa_cliente_unidade_enriquecimentos enable row level security;

create or replace function public.salvar_mesa_cliente_enriquecimento(
  p_empreendimento_id uuid,
  p_final text,
  p_dormitorios integer default null,
  p_suites integer default null,
  p_vagas_quantidade integer default null,
  p_orientacao_solar text default null,
  p_face text default null,
  p_vista text default null,
  p_observacoes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_user_empresa_id uuid;
  v_target_empresa_id uuid;
  v_final text := nullif(trim(coalesce(p_final, '')), '');
  v_orientacao text := nullif(trim(lower(coalesce(p_orientacao_solar, ''))), '');
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_empreendimento_id is null or v_final is null then
    raise exception 'empreendimento_id e final são obrigatórios';
  end if;

  select c.empresa_id
    into v_user_empresa_id
  from public.corretores c
  where c.user_id = v_uid
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

  if not public.is_root() and v_user_empresa_id is distinct from v_target_empresa_id then
    raise exception 'Acesso negado ao empreendimento informado';
  end if;

  if v_orientacao is not null and v_orientacao not in ('manha','tarde','nascente','poente','norte','sul','leste','oeste','misto') then
    raise exception 'orientacao_solar inválida: %', v_orientacao;
  end if;

  insert into public.mesa_cliente_unidade_enriquecimentos (
    empresa_id, empreendimento_id, final, dormitorios, suites, vagas_quantidade,
    orientacao_solar, face, vista, observacoes, criado_por, atualizado_por
  ) values (
    v_target_empresa_id, p_empreendimento_id, v_final, p_dormitorios, p_suites, p_vagas_quantidade,
    v_orientacao, nullif(trim(coalesce(p_face, '')), ''), nullif(trim(coalesce(p_vista, '')), ''),
    nullif(trim(coalesce(p_observacoes, '')), ''), v_uid, v_uid
  )
  on conflict (empreendimento_id, final) do update set
    dormitorios = excluded.dormitorios,
    suites = excluded.suites,
    vagas_quantidade = excluded.vagas_quantidade,
    orientacao_solar = excluded.orientacao_solar,
    face = excluded.face,
    vista = excluded.vista,
    observacoes = excluded.observacoes,
    atualizado_por = v_uid,
    updated_at = now()
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'empreendimento_id', p_empreendimento_id, 'final', v_final);
end;
$$;

revoke all on function public.salvar_mesa_cliente_enriquecimento(uuid, text, integer, integer, integer, text, text, text, text) from public;
grant execute on function public.salvar_mesa_cliente_enriquecimento(uuid, text, integer, integer, integer, text, text, text, text) to authenticated;

create or replace function public.get_unidades_mesa(p_empreendimento_id uuid)
returns table (
  id uuid, snapshot_id uuid, empreendimento_id uuid, torre text, unidade text, final text,
  andar integer, metragem numeric, dormitorios integer, suites integer, vagas_quantidade integer,
  valor_tabela numeric, status_comercial text, planta_tipo text, observacoes text,
  orientacao_solar text, face text, vista text, enriquecimento_id uuid, aviso text, extraido_em timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_empresa_id uuid;
  v_target_empresa_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.empresa_id into v_user_empresa_id
  from public.corretores c
  where c.user_id = auth.uid() and coalesce(c.ativo, true) = true
  limit 1;

  select e.empresa_id into v_target_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id and e.status = 'ativo'
  limit 1;

  if v_target_empresa_id is null then
    raise exception 'Empreendimento não encontrado ou inativo';
  end if;

  if not public.is_root() and v_user_empresa_id is distinct from v_target_empresa_id then
    raise exception 'Acesso negado ao empreendimento informado';
  end if;

  return query
  with latest_snapshot as (
    select es.id
    from public.estoque_snapshots es
    where es.empreendimento_id = p_empreendimento_id
      and es.empresa_id = v_target_empresa_id
      and coalesce(es.ativo, true) = true
      and es.status_processamento = 'processado'
    order by es.data_referencia desc nulls last, es.data_processamento desc nulls last, es.created_at desc
    limit 1
  )
  select
    ue.id, ue.snapshot_id, ue.empreendimento_id, ue.torre, ue.unidade, ue.final, ue.andar, ue.metragem,
    coalesce(ue.dormitorios, enr.dormitorios) as dormitorios,
    coalesce(ue.suites, enr.suites) as suites,
    coalesce(ue.vagas_quantidade, enr.vagas_quantidade) as vagas_quantidade,
    ue.valor_tabela, ue.status_comercial::text, ue.planta_tipo, ue.observacoes,
    enr.orientacao_solar, enr.face, enr.vista, enr.id as enriquecimento_id,
    case
      when ue.status_comercial::text = 'vendida' then 'Unidade marcada como vendida no último snapshot. Nesta preview ela ainda pode aparecer para conferência, mas não deve ser usada sem validação do espelho.'
      when ue.status_comercial::text in ('reservada','proposta','bloqueada','indisponivel') then 'Disponibilidade exige validação pelo espelho de vendas antes da proposta.'
      else 'Disponibilidade ainda não validada pelo espelho de vendas.'
    end as aviso,
    ue.extraido_em
  from public.unidades_estoque ue
  join latest_snapshot ls on ls.id = ue.snapshot_id
  left join public.mesa_cliente_unidade_enriquecimentos enr
    on enr.empreendimento_id = ue.empreendimento_id
   and enr.empresa_id = ue.empresa_id
   and enr.final = ue.final
  where ue.empreendimento_id = p_empreendimento_id
    and ue.empresa_id = v_target_empresa_id
  order by ue.torre nulls last, ue.andar nulls last, ue.unidade;
end;
$$;

revoke all on function public.get_unidades_mesa(uuid) from public;
grant execute on function public.get_unidades_mesa(uuid) to authenticated;
