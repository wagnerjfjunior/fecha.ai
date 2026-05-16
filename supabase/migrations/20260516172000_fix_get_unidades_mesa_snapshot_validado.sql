-- FECH.AI — Mesa Cliente
-- Correção: get_unidades_mesa deve carregar snapshots processados ou validados.
--
-- Contexto:
--   Após importar a tabela oficial de disponibilidade, o snapshot comercial passa de
--   status_processamento = 'processado' para 'validado'.
--   A versão anterior da RPC buscava apenas 'processado', deixando a tela sem unidades.
--
-- Segurança mantida:
--   - auth.uid() obrigatório.
--   - Tenant resolvido pelo banco.
--   - Usuário não-root precisa pertencer à empresa do empreendimento.
--   - Root continua permitido via public.is_root().
--   - SECURITY DEFINER com search_path fixo.

begin;

create or replace function public.get_unidades_mesa(p_empreendimento_id uuid)
returns table(
  id uuid,
  snapshot_id uuid,
  empreendimento_id uuid,
  torre text,
  unidade text,
  final text,
  andar integer,
  metragem numeric,
  dormitorios integer,
  suites integer,
  vagas_quantidade integer,
  valor_tabela numeric,
  status_comercial text,
  planta_tipo text,
  observacoes text,
  orientacao_solar text,
  face text,
  vista text,
  enriquecimento_id uuid,
  aviso text,
  extraido_em timestamp with time zone
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_empresa_id uuid;
  v_target_empresa_id uuid;
  v_is_root boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  v_is_root := coalesce(public.is_root(), false);

  select c.empresa_id
    into v_user_empresa_id
  from public.corretores c
  where c.user_id = auth.uid()
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

  if not v_is_root and v_user_empresa_id is null then
    raise exception 'Usuário sem corretor ativo vinculado';
  end if;

  if not v_is_root and v_user_empresa_id is distinct from v_target_empresa_id then
    raise exception 'Acesso negado ao empreendimento informado';
  end if;

  return query
  with latest_snapshot as (
    select es.id
    from public.estoque_snapshots es
    where es.empreendimento_id = p_empreendimento_id
      and es.empresa_id = v_target_empresa_id
      and coalesce(es.ativo, true) = true
      and es.status_processamento in ('processado','validado')
    order by
      case when es.status_processamento = 'validado' then 0 else 1 end,
      es.data_referencia desc nulls last,
      es.data_processamento desc nulls last,
      es.created_at desc
    limit 1
  )
  select
    ue.id,
    ue.snapshot_id,
    ue.empreendimento_id,
    ue.torre,
    ue.unidade,
    ue.final,
    ue.andar,
    ue.metragem,
    coalesce(ue.dormitorios, enr.dormitorios) as dormitorios,
    coalesce(ue.suites, enr.suites) as suites,
    coalesce(ue.vagas_quantidade, enr.vagas_quantidade) as vagas_quantidade,
    ue.valor_tabela,
    ue.status_comercial::text,
    ue.planta_tipo,
    ue.observacoes,
    enr.orientacao_solar,
    enr.face,
    enr.vista,
    enr.id as enriquecimento_id,
    case
      when ue.status_comercial::text = 'vendida' then
        'Unidade marcada como vendida. Não apresentar ao cliente sem nova conferência oficial.'
      when ue.status_comercial::text = 'indisponivel' then
        'Unidade fora da tabela oficial de disponibilidade. Conferir antes de apresentar ao cliente.'
      when ue.status_comercial::text in ('reservada','proposta','bloqueada') then
        'Unidade com restrição comercial. Confirme a disponibilidade antes da proposta.'
      when ue.status_comercial::text = 'disponivel' then
        'Disponibilidade confirmada pela tabela oficial Tegra.'
      else
        'Confirme a disponibilidade atualizando a tabela oficial Tegra.'
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

comment on function public.get_unidades_mesa(uuid) is
'Mesa Cliente: retorna unidades do snapshot comercial mais recente processado ou validado, com isolamento por tenant e enriquecimento por final/prumada.';

commit;
