-- Mesa Cliente — Preview segura de unidades extraídas pelo parser
-- Objetivo:
--   Expor para a UI todas as unidades do último snapshot processado da tabela comercial.
--   O espelho de vendas ainda não filtra unidades vendidas nesta etapa.
-- Segurança:
--   - SECURITY DEFINER com search_path fixo.
--   - Exige auth.uid().
--   - Valida empresa do usuário contra empresa do empreendimento.
--   - Root admin pode consultar entre tenants; corretor/gestor/admin local não.
--   - Não concede acesso direto às tabelas; ponto de entrada é RPC.

create or replace function public.get_unidades_mesa(p_empreendimento_id uuid)
returns table (
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
  aviso text,
  extraido_em timestamptz
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
    order by es.data_referencia desc nulls last,
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
    ue.dormitorios,
    ue.suites,
    ue.vagas_quantidade,
    ue.valor_tabela,
    ue.status_comercial::text,
    ue.planta_tipo,
    ue.observacoes,
    case
      when ue.status_comercial::text = 'vendida' then 'Unidade marcada como vendida no último snapshot. Nesta preview ela ainda pode aparecer para conferência, mas não deve ser usada sem validação do espelho.'
      when ue.status_comercial::text in ('reservada','proposta','bloqueada','indisponivel') then 'Disponibilidade exige validação pelo espelho de vendas antes da proposta.'
      else 'Disponibilidade ainda não validada pelo espelho de vendas.'
    end as aviso,
    ue.extraido_em
  from public.unidades_estoque ue
  join latest_snapshot ls on ls.id = ue.snapshot_id
  where ue.empreendimento_id = p_empreendimento_id
    and ue.empresa_id = v_target_empresa_id
  order by
    ue.torre nulls last,
    ue.andar nulls last,
    ue.unidade;
end;
$$;

revoke all on function public.get_unidades_mesa(uuid) from public;
grant execute on function public.get_unidades_mesa(uuid) to authenticated;
