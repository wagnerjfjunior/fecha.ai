-- FECH.AI / MesaCliente — Fase 20A
-- Hardening de grant da RPC de leitura do fluxo histórico.
-- Remove execução implícita via PUBLIC/anon e mantém somente authenticated/service_role/postgres.

revoke execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) from public;
revoke execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) from anon;
grant execute on function public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb) to authenticated;
