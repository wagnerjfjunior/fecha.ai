-- Rollback — MesaCliente Engenharia Financeira RPCs Administrativas
-- Migration relacionada:
-- supabase/migrations/20260517193000_mesa_cliente_engenharia_financeira_rpcs_admin.sql
--
-- Objetivo:
--   Remover as RPCs administrativas e helpers criados na Fase 2 da Engenharia Financeira.
--
-- O que este rollback faz:
--   - Revoga EXECUTE das RPCs administrativas.
--   - Remove RPCs de listagem/obtenção/upsert de políticas/faixas.
--   - Remove helpers de autorização criados especificamente para o módulo.
--
-- O que este rollback NÃO faz:
--   - Não remove tabelas financeiras.
--   - Não remove policies/triggers da migration de hardening.
--   - Não altera parser, Worker, Make, front ou motor financeiro atual.
--   - Não apaga dados de políticas/faixas já gravados.

begin;

-- -----------------------------------------------------------------------------
-- 1. Revogar permissões de execução
-- -----------------------------------------------------------------------------

revoke all on function public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer) from public;
revoke all on function public.mesa_cliente_obter_politica_financeira(uuid, uuid) from public;
revoke all on function public.mesa_cliente_upsert_politica_financeira(uuid, uuid, date, date, date, numeric, numeric, numeric, text, text, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, text) from public;
revoke all on function public.mesa_cliente_upsert_faixas_premio(uuid, uuid, jsonb) from public;

revoke all on function public.mesa_cliente_current_corretor_context() from public;
revoke all on function public.mesa_cliente_assert_auth() from public;
revoke all on function public.mesa_cliente_can_access_empresa(uuid) from public;
revoke all on function public.mesa_cliente_can_admin_empresa(uuid) from public;
revoke all on function public.mesa_cliente_assert_empreendimento_empresa(uuid, uuid) from public;

-- -----------------------------------------------------------------------------
-- 2. Remover RPCs administrativas
-- -----------------------------------------------------------------------------

drop function if exists public.mesa_cliente_upsert_faixas_premio(uuid, uuid, jsonb);
drop function if exists public.mesa_cliente_upsert_politica_financeira(uuid, uuid, date, date, date, numeric, numeric, numeric, text, text, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, text);
drop function if exists public.mesa_cliente_obter_politica_financeira(uuid, uuid);
drop function if exists public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer);

-- -----------------------------------------------------------------------------
-- 3. Remover helpers criados na Fase 2
-- -----------------------------------------------------------------------------

drop function if exists public.mesa_cliente_assert_empreendimento_empresa(uuid, uuid);
drop function if exists public.mesa_cliente_can_admin_empresa(uuid);
drop function if exists public.mesa_cliente_can_access_empresa(uuid);
drop function if exists public.mesa_cliente_assert_auth();
drop function if exists public.mesa_cliente_current_corretor_context();

commit;
