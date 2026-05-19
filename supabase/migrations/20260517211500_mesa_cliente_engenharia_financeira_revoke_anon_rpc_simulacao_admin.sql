-- MesaCliente Engenharia Financeira — Fix de grants da RPC de simulação administrativa
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Problema:
--   O postcheck identificou EXECUTE explícito para role anon na RPC administrativa:
--   public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid)
--
-- Correção:
--   Revogar EXECUTE de anon e public.
--   Garantir EXECUTE apenas para authenticated.
--
-- Observação:
--   Mesmo que a RPC valide auth.uid() internamente, anon não deve ter permissão
--   formal de execução em RPC administrativa financeira.
--
-- Escopo:
--   - Não altera tabelas.
--   - Não altera RLS.
--   - Não altera parser, motor financeiro atual, Worker, Make ou front.
--   - Não altera lógica de cálculo.

begin;

revoke all on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) from public;
revoke all on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) from anon;
revoke all on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) from authenticated;

grant execute on function public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid) to authenticated;

commit;
