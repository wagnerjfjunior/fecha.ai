-- MesaCliente Engenharia Financeira — hardening estrutural
-- Branch alvo: feature/mesa-cliente-engenharia-financeira
-- Objetivo:
--   - Não recriar tabelas já existentes.
--   - Consolidar RLS/policies duplicadas.
--   - Bloquear escrita direta pelo front/authenticated.
--   - Validar integridade multiempresa/multitenant no banco.
--   - Preparar o caminho para RPCs soberanas nas próximas fases.
--
-- Regras preservadas:
--   - Nada hardcoded.
--   - Banco/RPC é soberano.
--   - Front é apenas consultivo.
--   - RLS obrigatória.
--   - auth.uid() obrigatório nas policies.
--   - Validar empresa, empreendimento, tenant e perfil nas futuras RPCs.
--   - Cliente não vê VPL, prêmio, comissão ou regra interna.
--   - Escrita direta fica bloqueada; operações futuras devem ocorrer por RPC controlada.

begin;

-- -----------------------------------------------------------------------------
-- 1. Pré-requisitos defensivos
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.empresas') is null then
    raise exception 'Tabela public.empresas não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.empreendimentos') is null then
    raise exception 'Tabela public.empreendimentos não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.corretores') is null then
    raise exception 'Tabela public.corretores não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_simulacoes') is null then
    raise exception 'Tabela public.mesa_simulacoes não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_cliente_politicas_financeiras') is null then
    raise exception 'Tabela public.mesa_cliente_politicas_financeiras não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_cliente_politica_premio_faixas') is null then
    raise exception 'Tabela public.mesa_cliente_politica_premio_faixas não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_cliente_fluxo_parcelas') is null then
    raise exception 'Tabela public.mesa_cliente_fluxo_parcelas não encontrada. Migração abortada.';
  end if;

  if to_regclass('public.mesa_cliente_fluxo_operacoes') is null then
    raise exception 'Tabela public.mesa_cliente_fluxo_operacoes não encontrada. Migração abortada.';
  end if;

  if to_regprocedure('public.is_root()') is null then
    raise exception 'Função public.is_root() não encontrada. Migração abortada.';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2. RLS obrigatório
-- -----------------------------------------------------------------------------

alter table public.mesa_cliente_politicas_financeiras enable row level security;
alter table public.mesa_cliente_politica_premio_faixas enable row level security;
alter table public.mesa_cliente_fluxo_parcelas enable row level security;
alter table public.mesa_cliente_fluxo_operacoes enable row level security;

-- Observação técnica:
-- Não usamos FORCE ROW LEVEL SECURITY aqui para não bloquear futuras RPCs
-- SECURITY DEFINER controladas pelo banco. A escrita direta pelo usuário autenticado
-- permanece bloqueada pelas policies abaixo.

-- -----------------------------------------------------------------------------
-- 3. Limpeza de policies duplicadas/legadas
-- -----------------------------------------------------------------------------

-- Políticas financeiras
drop policy if exists mesa_politicas_financeiras_select_tenant on public.mesa_cliente_politicas_financeiras;
drop policy if exists mesa_politicas_financeiras_no_direct_insert on public.mesa_cliente_politicas_financeiras;
drop policy if exists mesa_politicas_financeiras_no_direct_update on public.mesa_cliente_politicas_financeiras;
drop policy if exists mesa_politicas_financeiras_no_direct_delete on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_select_tenant on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_no_direct_insert on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_no_direct_update on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_no_direct_delete on public.mesa_cliente_politicas_financeiras;

-- Faixas de prêmio
drop policy if exists mesa_premio_faixas_select_tenant on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mesa_premio_faixas_no_direct_insert on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mesa_premio_faixas_no_direct_update on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mesa_premio_faixas_no_direct_delete on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_select_tenant on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_no_direct_insert on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_no_direct_update on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_no_direct_delete on public.mesa_cliente_politica_premio_faixas;

-- Fluxo de parcelas
drop policy if exists mesa_fluxo_parcelas_select_tenant on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mesa_fluxo_parcelas_no_direct_insert on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mesa_fluxo_parcelas_no_direct_update on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mesa_fluxo_parcelas_no_direct_delete on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_select_tenant on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_no_direct_insert on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_no_direct_update on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_no_direct_delete on public.mesa_cliente_fluxo_parcelas;

-- Operações financeiras
drop policy if exists mesa_fluxo_operacoes_select_tenant on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mesa_fluxo_operacoes_no_direct_insert on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mesa_fluxo_operacoes_no_direct_update on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mesa_fluxo_operacoes_no_direct_delete on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_select_tenant on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_no_direct_insert on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_no_direct_update on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_no_direct_delete on public.mesa_cliente_fluxo_operacoes;

-- -----------------------------------------------------------------------------
-- 4. Policies canônicas
-- -----------------------------------------------------------------------------

create policy mcpf_select_tenant
on public.mesa_cliente_politicas_financeiras
for select
to authenticated
using (
  public.is_root()
  or exists (
    select 1
    from public.corretores c
    where c.user_id = auth.uid()
      and c.empresa_id = mesa_cliente_politicas_financeiras.empresa_id
      and coalesce(c.ativo, true) = true
  )
);

create policy mcpf_no_direct_insert
on public.mesa_cliente_politicas_financeiras
for insert
to authenticated
with check (false);

create policy mcpf_no_direct_update
on public.mesa_cliente_politicas_financeiras
for update
to authenticated
using (false)
with check (false);

create policy mcpf_no_direct_delete
on public.mesa_cliente_politicas_financeiras
for delete
to authenticated
using (false);

create policy mcppf_select_tenant
on public.mesa_cliente_politica_premio_faixas
for select
to authenticated
using (
  public.is_root()
  or exists (
    select 1
    from public.corretores c
    where c.user_id = auth.uid()
      and c.empresa_id = mesa_cliente_politica_premio_faixas.empresa_id
      and coalesce(c.ativo, true) = true
  )
);

create policy mcppf_no_direct_insert
on public.mesa_cliente_politica_premio_faixas
for insert
to authenticated
with check (false);

create policy mcppf_no_direct_update
on public.mesa_cliente_politica_premio_faixas
for update
to authenticated
using (false)
with check (false);

create policy mcppf_no_direct_delete
on public.mesa_cliente_politica_premio_faixas
for delete
to authenticated
using (false);

create policy mcfp_select_tenant
on public.mesa_cliente_fluxo_parcelas
for select
to authenticated
using (
  public.is_root()
  or exists (
    select 1
    from public.corretores c
    where c.user_id = auth.uid()
      and c.empresa_id = mesa_cliente_fluxo_parcelas.empresa_id
      and coalesce(c.ativo, true) = true
  )
);

create policy mcfp_no_direct_insert
on public.mesa_cliente_fluxo_parcelas
for insert
to authenticated
with check (false);

create policy mcfp_no_direct_update
on public.mesa_cliente_fluxo_parcelas
for update
to authenticated
using (false)
with check (false);

create policy mcfp_no_direct_delete
on public.mesa_cliente_fluxo_parcelas
for delete
to authenticated
using (false);

create policy mcfo_select_tenant
on public.mesa_cliente_fluxo_operacoes
for select
to authenticated
using (
  public.is_root()
  or exists (
    select 1
    from public.corretores c
    where c.user_id = auth.uid()
      and c.empresa_id = mesa_cliente_fluxo_operacoes.empresa_id
      and coalesce(c.ativo, true) = true
  )
);

create policy mcfo_no_direct_insert
on public.mesa_cliente_fluxo_operacoes
for insert
to authenticated
with check (false);

create policy mcfo_no_direct_update
on public.mesa_cliente_fluxo_operacoes
for update
to authenticated
using (false)
with check (false);

create policy mcfo_no_direct_delete
on public.mesa_cliente_fluxo_operacoes
for delete
to authenticated
using (false);

-- -----------------------------------------------------------------------------
-- 5. Grants mínimos
-- -----------------------------------------------------------------------------

revoke all on table public.mesa_cliente_politicas_financeiras from anon;
revoke all on table public.mesa_cliente_politica_premio_faixas from anon;
revoke all on table public.mesa_cliente_fluxo_parcelas from anon;
revoke all on table public.mesa_cliente_fluxo_operacoes from anon;

revoke insert, update, delete on table public.mesa_cliente_politicas_financeiras from authenticated;
revoke insert, update, delete on table public.mesa_cliente_politica_premio_faixas from authenticated;
revoke insert, update, delete on table public.mesa_cliente_fluxo_parcelas from authenticated;
revoke insert, update, delete on table public.mesa_cliente_fluxo_operacoes from authenticated;

grant select on table public.mesa_cliente_politicas_financeiras to authenticated;
grant select on table public.mesa_cliente_politica_premio_faixas to authenticated;
grant select on table public.mesa_cliente_fluxo_parcelas to authenticated;
grant select on table public.mesa_cliente_fluxo_operacoes to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Índices canônicos e limpeza de duplicidade nominal
-- -----------------------------------------------------------------------------

-- Remover duplicatas antigas que têm mesma função semântica dos índices canônicos.
drop index if exists public.idx_mesa_politicas_financeiras_tenant_vigencia;
drop index if exists public.idx_mesa_premio_faixas_politica_ordem;
drop index if exists public.idx_mesa_fluxo_parcelas_simulacao_ordem;
drop index if exists public.idx_mesa_fluxo_operacoes_tenant;

create index if not exists idx_mcpf_empresa_empreendimento_ativo
on public.mesa_cliente_politicas_financeiras (empresa_id, empreendimento_id, ativo, vigencia_inicio, vigencia_fim);

create index if not exists idx_mcpf_vigencia_ativa
on public.mesa_cliente_politicas_financeiras (empreendimento_id, vigencia_inicio, vigencia_fim)
where ativo is true;

create index if not exists idx_mesa_politicas_financeiras_mes
on public.mesa_cliente_politicas_financeiras (empresa_id, empreendimento_id, mes_referencia desc);

create index if not exists idx_mcppf_politica_ordem
on public.mesa_cliente_politica_premio_faixas (politica_id, ativo, ordem, vpl_de_pct, vpl_ate_pct);

create index if not exists idx_mesa_premio_faixas_empresa
on public.mesa_cliente_politica_premio_faixas (empresa_id, ativo);

create index if not exists idx_mcfp_empresa_empreendimento
on public.mesa_cliente_fluxo_parcelas (empresa_id, empreendimento_id);

create index if not exists idx_mcfp_simulacao_ordem
on public.mesa_cliente_fluxo_parcelas (simulacao_id, ordem);

create index if not exists idx_mesa_fluxo_parcelas_elegiveis
on public.mesa_cliente_fluxo_parcelas (simulacao_id, grupo, data_atual)
where eh_periodicidade_simbolica is false;

create index if not exists idx_mcfo_empresa_empreendimento
on public.mesa_cliente_fluxo_operacoes (empresa_id, empreendimento_id, created_at desc);

create index if not exists idx_mcfo_simulacao_confirmado
on public.mesa_cliente_fluxo_operacoes (simulacao_id, confirmado, created_at desc);

create index if not exists idx_mcfo_simulacao_status
on public.mesa_cliente_fluxo_operacoes (simulacao_id, status_operacao, created_at desc);

create index if not exists idx_mesa_fluxo_operacoes_confirmado
on public.mesa_cliente_fluxo_operacoes (empresa_id, confirmado, created_at desc);

create index if not exists idx_mesa_fluxo_operacoes_simulacao
on public.mesa_cliente_fluxo_operacoes (simulacao_id, tipo_operacao, created_at desc);

-- -----------------------------------------------------------------------------
-- 7. Trigger soberana de integridade multiempresa/multitenant
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_financeiro_assert_integridade()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_empreendimento_id uuid;
  v_sim_empresa_id uuid;
  v_sim_empreendimento_id uuid;
  v_politica_empresa_id uuid;
  v_parcela_empresa_id uuid;
  v_parcela_simulacao_id uuid;
  v_parcela_empreendimento_id uuid;
begin
  -- Todas as tabelas financeiras precisam de empresa_id.
  if new.empresa_id is null then
    raise exception 'empresa_id é obrigatório para %', tg_table_name;
  end if;

  -- Atualização defensiva de auditoria local.
  if tg_op = 'UPDATE' then
    new.updated_at := now();

    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = tg_table_name
        and column_name = 'atualizado_por'
    ) then
      new.atualizado_por := auth.uid();
    end if;
  end if;

  -- Política financeira: empresa/empreendimento devem ser coerentes.
  if tg_table_name = 'mesa_cliente_politicas_financeiras' then
    select e.empresa_id
      into v_empresa_id
    from public.empreendimentos e
    where e.id = new.empreendimento_id;

    if v_empresa_id is null or v_empresa_id <> new.empresa_id then
      raise exception 'empreendimento_id não pertence à empresa_id informada';
    end if;

    return new;
  end if;

  -- Faixas de prêmio: faixa deve pertencer à mesma empresa da política.
  if tg_table_name = 'mesa_cliente_politica_premio_faixas' then
    select p.empresa_id
      into v_politica_empresa_id
    from public.mesa_cliente_politicas_financeiras p
    where p.id = new.politica_id;

    if v_politica_empresa_id is null or v_politica_empresa_id <> new.empresa_id then
      raise exception 'politica_id não pertence à empresa_id informada';
    end if;

    return new;
  end if;

  -- Fluxo de parcelas: simulação e empreendimento precisam bater com a empresa.
  if tg_table_name = 'mesa_cliente_fluxo_parcelas' then
    select s.empresa_id, s.empreendimento_id
      into v_sim_empresa_id, v_sim_empreendimento_id
    from public.mesa_simulacoes s
    where s.id = new.simulacao_id;

    if v_sim_empresa_id is null or v_sim_empresa_id <> new.empresa_id then
      raise exception 'simulacao_id não pertence à empresa_id informada';
    end if;

    if v_sim_empreendimento_id is not null and v_sim_empreendimento_id <> new.empreendimento_id then
      raise exception 'empreendimento_id diverge da simulação informada';
    end if;

    select e.empresa_id
      into v_empresa_id
    from public.empreendimentos e
    where e.id = new.empreendimento_id;

    if v_empresa_id is null or v_empresa_id <> new.empresa_id then
      raise exception 'empreendimento_id não pertence à empresa_id informada';
    end if;

    if new.eh_periodicidade_simbolica is true then
      new.pode_receber_vpl := false;
      new.pode_receber_antecipacao := false;
      new.pode_receber_postergacao := false;
    end if;

    return new;
  end if;

  -- Operações: simulação, empreendimento, política e parcelas precisam ser do mesmo tenant.
  if tg_table_name = 'mesa_cliente_fluxo_operacoes' then
    select s.empresa_id, s.empreendimento_id
      into v_sim_empresa_id, v_sim_empreendimento_id
    from public.mesa_simulacoes s
    where s.id = new.simulacao_id;

    if v_sim_empresa_id is null or v_sim_empresa_id <> new.empresa_id then
      raise exception 'simulacao_id não pertence à empresa_id informada';
    end if;

    if v_sim_empreendimento_id is not null and v_sim_empreendimento_id <> new.empreendimento_id then
      raise exception 'empreendimento_id diverge da simulação informada';
    end if;

    select e.empresa_id
      into v_empresa_id
    from public.empreendimentos e
    where e.id = new.empreendimento_id;

    if v_empresa_id is null or v_empresa_id <> new.empresa_id then
      raise exception 'empreendimento_id não pertence à empresa_id informada';
    end if;

    if new.politica_id is not null then
      select p.empresa_id
        into v_politica_empresa_id
      from public.mesa_cliente_politicas_financeiras p
      where p.id = new.politica_id;

      if v_politica_empresa_id is null or v_politica_empresa_id <> new.empresa_id then
        raise exception 'politica_id não pertence à empresa_id informada';
      end if;
    end if;

    if new.parcela_origem_id is not null then
      select fp.empresa_id, fp.simulacao_id, fp.empreendimento_id
        into v_parcela_empresa_id, v_parcela_simulacao_id, v_parcela_empreendimento_id
      from public.mesa_cliente_fluxo_parcelas fp
      where fp.id = new.parcela_origem_id;

      if v_parcela_empresa_id is null
         or v_parcela_empresa_id <> new.empresa_id
         or v_parcela_simulacao_id <> new.simulacao_id
         or v_parcela_empreendimento_id <> new.empreendimento_id then
        raise exception 'parcela_origem_id diverge do tenant/simulação/empreendimento da operação';
      end if;
    end if;

    if new.parcela_destino_id is not null then
      select fp.empresa_id, fp.simulacao_id, fp.empreendimento_id
        into v_parcela_empresa_id, v_parcela_simulacao_id, v_parcela_empreendimento_id
      from public.mesa_cliente_fluxo_parcelas fp
      where fp.id = new.parcela_destino_id;

      if v_parcela_empresa_id is null
         or v_parcela_empresa_id <> new.empresa_id
         or v_parcela_simulacao_id <> new.simulacao_id
         or v_parcela_empreendimento_id <> new.empreendimento_id then
        raise exception 'parcela_destino_id diverge do tenant/simulação/empreendimento da operação';
      end if;
    end if;

    -- Garantia adicional: prêmio interno nunca deve ser tratado como item visível ao cliente.
    if new.premio_corretor_pct is not null then
      new.visivel_cliente := false;
    end if;

    return new;
  end if;

  return new;
end;
$$;

revoke all on function public.mesa_cliente_financeiro_assert_integridade() from public;

-- Recriar triggers de forma idempotente.
drop trigger if exists trg_mcpf_assert_integridade on public.mesa_cliente_politicas_financeiras;
create trigger trg_mcpf_assert_integridade
before insert or update on public.mesa_cliente_politicas_financeiras
for each row execute function public.mesa_cliente_financeiro_assert_integridade();

drop trigger if exists trg_mcppf_assert_integridade on public.mesa_cliente_politica_premio_faixas;
create trigger trg_mcppf_assert_integridade
before insert or update on public.mesa_cliente_politica_premio_faixas
for each row execute function public.mesa_cliente_financeiro_assert_integridade();

drop trigger if exists trg_mcfp_assert_integridade on public.mesa_cliente_fluxo_parcelas;
create trigger trg_mcfp_assert_integridade
before insert or update on public.mesa_cliente_fluxo_parcelas
for each row execute function public.mesa_cliente_financeiro_assert_integridade();

drop trigger if exists trg_mcfo_assert_integridade on public.mesa_cliente_fluxo_operacoes;
create trigger trg_mcfo_assert_integridade
before insert or update on public.mesa_cliente_fluxo_operacoes
for each row execute function public.mesa_cliente_financeiro_assert_integridade();

-- -----------------------------------------------------------------------------
-- 8. Comentários de governança
-- -----------------------------------------------------------------------------

comment on table public.mesa_cliente_politicas_financeiras is
'MesaCliente Engenharia Financeira: política mensal/vigente por empresa e empreendimento. Banco/RPC é soberano; front é consultivo; sem hardcoded.';

comment on table public.mesa_cliente_politica_premio_faixas is
'MesaCliente Engenharia Financeira: faixas administrativas de prêmio por VPL. Informação interna; não expor ao cliente.';

comment on table public.mesa_cliente_fluxo_parcelas is
'MesaCliente Engenharia Financeira: agenda datada das parcelas. Periodicidade simbólica não é parcela negociável.';

comment on table public.mesa_cliente_fluxo_operacoes is
'MesaCliente Engenharia Financeira: operações de VPL, antecipação e postergação. Cliente não vê VPL, prêmio, comissão ou regra interna.';

comment on function public.mesa_cliente_financeiro_assert_integridade() is
'Valida integridade multitenant da Engenharia Financeira do MesaCliente antes de inserts/updates feitos por RPCs soberanas.';

commit;
