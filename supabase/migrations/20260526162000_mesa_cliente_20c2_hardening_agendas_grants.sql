-- FECH.AI / MesaCliente
-- Fase 20C.2 — Hardening de grants da agenda financeira canônica
--
-- Objetivo:
--   Versionar no GitHub o hardening já aplicado manualmente no Supabase real,
--   removendo privilégios globais desnecessários da role authenticated na tabela
--   public.mesa_cliente_agendas_financeiras.
--
-- Escopo:
--   - Remove REFERENCES/TRIGGER/TRUNCATE de authenticated.
--   - Mantém SELECT para authenticated, sujeito às policies/RLS existentes.
--   - Não altera RLS.
--   - Não altera policies.
--   - Não altera RPCs.
--   - Não altera frontend.
--   - Não altera motor financeiro.
--
-- Justificativa:
--   A role authenticated deve acessar a agenda financeira canônica por leitura
--   controlada/RLS e por RPCs autorizadas. Privilégios globais de tabela como
--   TRUNCATE e TRIGGER não devem ficar concedidos diretamente a authenticated.
--
-- Segurança:
--   REVOKE é idempotente: se o privilégio já não existir, o comando não falha.

revoke references on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke trigger on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke truncate on table public.mesa_cliente_agendas_financeiras from authenticated;

-- Mantém leitura direta condicionada por RLS/policies.
grant select on table public.mesa_cliente_agendas_financeiras to authenticated;
