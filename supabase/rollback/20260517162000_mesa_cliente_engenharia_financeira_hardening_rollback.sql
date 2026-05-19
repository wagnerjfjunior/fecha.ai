-- Rollback — MesaCliente Engenharia Financeira Hardening
-- Migration relacionada:
-- supabase/migrations/20260517162000_mesa_cliente_engenharia_financeira_hardening.sql
--
-- Objetivo:
--   Reverter alterações estruturais de hardening caso o postcheck falhe em produção única.
--
-- O que este rollback faz:
--   - Remove triggers de integridade criadas pela migration.
--   - Remove a função de integridade criada pela migration.
--   - Remove policies canônicas criadas/recriadas pela migration.
--   - Recria policies legadas duplicadas que existiam antes do hardening.
--   - Recria índices legados duplicados removidos pela migration.
--
-- O que este rollback NÃO faz:
--   - Não restaura dados de negócio apagados manualmente.
--   - Não altera parser, Worker, Make, front ou motor financeiro atual.
--   - Não remove as tabelas da Engenharia Financeira.

begin;

-- -----------------------------------------------------------------------------
-- 1. Remover triggers/função de integridade do hardening
-- -----------------------------------------------------------------------------

drop trigger if exists trg_mcpf_assert_integridade on public.mesa_cliente_politicas_financeiras;
drop trigger if exists trg_mcppf_assert_integridade on public.mesa_cliente_politica_premio_faixas;
drop trigger if exists trg_mcfp_assert_integridade on public.mesa_cliente_fluxo_parcelas;
drop trigger if exists trg_mcfo_assert_integridade on public.mesa_cliente_fluxo_operacoes;

drop function if exists public.mesa_cliente_financeiro_assert_integridade();

-- -----------------------------------------------------------------------------
-- 2. Remover policies canônicas para recriação controlada
-- -----------------------------------------------------------------------------

drop policy if exists mcpf_select_tenant on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_no_direct_insert on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_no_direct_update on public.mesa_cliente_politicas_financeiras;
drop policy if exists mcpf_no_direct_delete on public.mesa_cliente_politicas_financeiras;

drop policy if exists mcppf_select_tenant on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_no_direct_insert on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_no_direct_update on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mcppf_no_direct_delete on public.mesa_cliente_politica_premio_faixas;

drop policy if exists mcfp_select_tenant on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_no_direct_insert on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_no_direct_update on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mcfp_no_direct_delete on public.mesa_cliente_fluxo_parcelas;

drop policy if exists mcfo_select_tenant on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_no_direct_insert on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_no_direct_update on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mcfo_no_direct_delete on public.mesa_cliente_fluxo_operacoes;

-- Remover legadas se existirem, para recriar estado pré-hardening sem duplicar mais ainda.
drop policy if exists mesa_politicas_financeiras_select_tenant on public.mesa_cliente_politicas_financeiras;
drop policy if exists mesa_politicas_financeiras_no_direct_insert on public.mesa_cliente_politicas_financeiras;
drop policy if exists mesa_politicas_financeiras_no_direct_update on public.mesa_cliente_politicas_financeiras;
drop policy if exists mesa_politicas_financeiras_no_direct_delete on public.mesa_cliente_politicas_financeiras;

drop policy if exists mesa_premio_faixas_select_tenant on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mesa_premio_faixas_no_direct_insert on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mesa_premio_faixas_no_direct_update on public.mesa_cliente_politica_premio_faixas;
drop policy if exists mesa_premio_faixas_no_direct_delete on public.mesa_cliente_politica_premio_faixas;

drop policy if exists mesa_fluxo_parcelas_select_tenant on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mesa_fluxo_parcelas_no_direct_insert on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mesa_fluxo_parcelas_no_direct_update on public.mesa_cliente_fluxo_parcelas;
drop policy if exists mesa_fluxo_parcelas_no_direct_delete on public.mesa_cliente_fluxo_parcelas;

drop policy if exists mesa_fluxo_operacoes_select_tenant on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mesa_fluxo_operacoes_no_direct_insert on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mesa_fluxo_operacoes_no_direct_update on public.mesa_cliente_fluxo_operacoes;
drop policy if exists mesa_fluxo_operacoes_no_direct_delete on public.mesa_cliente_fluxo_operacoes;

-- -----------------------------------------------------------------------------
-- 3. Recriar policies canônicas existentes no pré-hardening
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
-- 4. Recriar policies legadas duplicadas existentes antes do hardening
-- -----------------------------------------------------------------------------

create policy mesa_politicas_financeiras_select_tenant
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

create policy mesa_politicas_financeiras_no_direct_insert
on public.mesa_cliente_politicas_financeiras
for insert
to authenticated
with check (false);

create policy mesa_politicas_financeiras_no_direct_update
on public.mesa_cliente_politicas_financeiras
for update
to authenticated
using (false)
with check (false);

create policy mesa_politicas_financeiras_no_direct_delete
on public.mesa_cliente_politicas_financeiras
for delete
to authenticated
using (false);

create policy mesa_premio_faixas_select_tenant
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

create policy mesa_premio_faixas_no_direct_insert
on public.mesa_cliente_politica_premio_faixas
for insert
to authenticated
with check (false);

create policy mesa_premio_faixas_no_direct_update
on public.mesa_cliente_politica_premio_faixas
for update
to authenticated
using (false)
with check (false);

create policy mesa_premio_faixas_no_direct_delete
on public.mesa_cliente_politica_premio_faixas
for delete
to authenticated
using (false);

create policy mesa_fluxo_parcelas_select_tenant
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

create policy mesa_fluxo_parcelas_no_direct_insert
on public.mesa_cliente_fluxo_parcelas
for insert
to authenticated
with check (false);

create policy mesa_fluxo_parcelas_no_direct_update
on public.mesa_cliente_fluxo_parcelas
for update
to authenticated
using (false)
with check (false);

create policy mesa_fluxo_parcelas_no_direct_delete
on public.mesa_cliente_fluxo_parcelas
for delete
to authenticated
using (false);

create policy mesa_fluxo_operacoes_select_tenant
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

create policy mesa_fluxo_operacoes_no_direct_insert
on public.mesa_cliente_fluxo_operacoes
for insert
to authenticated
with check (false);

create policy mesa_fluxo_operacoes_no_direct_update
on public.mesa_cliente_fluxo_operacoes
for update
to authenticated
using (false)
with check (false);

create policy mesa_fluxo_operacoes_no_direct_delete
on public.mesa_cliente_fluxo_operacoes
for delete
to authenticated
using (false);

-- -----------------------------------------------------------------------------
-- 5. Recriar índices legados duplicados que existiam antes do hardening
-- -----------------------------------------------------------------------------

create index if not exists idx_mesa_politicas_financeiras_tenant_vigencia
on public.mesa_cliente_politicas_financeiras (empresa_id, empreendimento_id, ativo, vigencia_inicio, vigencia_fim);

create index if not exists idx_mesa_premio_faixas_politica_ordem
on public.mesa_cliente_politica_premio_faixas (politica_id, ativo, ordem, vpl_de_pct, vpl_ate_pct);

create index if not exists idx_mesa_fluxo_parcelas_simulacao_ordem
on public.mesa_cliente_fluxo_parcelas (simulacao_id, ordem);

create index if not exists idx_mesa_fluxo_operacoes_tenant
on public.mesa_cliente_fluxo_operacoes (empresa_id, empreendimento_id, simulacao_id);

-- -----------------------------------------------------------------------------
-- 6. Manter grants conservadores do estado seguro observado
-- -----------------------------------------------------------------------------

alter table public.mesa_cliente_politicas_financeiras enable row level security;
alter table public.mesa_cliente_politica_premio_faixas enable row level security;
alter table public.mesa_cliente_fluxo_parcelas enable row level security;
alter table public.mesa_cliente_fluxo_operacoes enable row level security;

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

commit;
