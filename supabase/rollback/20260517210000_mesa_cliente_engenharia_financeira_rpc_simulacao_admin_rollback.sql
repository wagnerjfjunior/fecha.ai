-- Rollback — MesaCliente Engenharia Financeira Fase 3B: RPC de simulação administrativa
-- Migration relacionada:
-- supabase/migrations/20260517210000_mesa_cliente_engenharia_financeira_rpc_simulacao_admin.sql
--
-- Objetivo:
--   Remover a RPC de simulação administrativa financeira.
--
-- O que este rollback NÃO faz:
--   - Não remove funções base de cálculo.
--   - Não remove tabelas financeiras.
--   - Não altera RLS.
--   - Não altera parser, motor financeiro atual, Worker, Make ou front.

begin;

drop function if exists public.mesa_cliente_simular_impacto_financeiro_admin(uuid, uuid, date, jsonb, uuid);

commit;
