-- FECH.AI / MesaCliente
-- Security hardening: sensitive SECURITY DEFINER RPC execution grants
-- Date: 2026-05-29
--
-- Purpose:
-- - Remove anonymous/public execution from sensitive SECURITY DEFINER functions.
-- - Keep only the minimum required authenticated execution surface.
-- - Keep password reset SQL RPC locked down. Password reset/change must remain in
--   Supabase Auth / server-side Edge Function flow, never as plaintext public SQL API.
--
-- Notes:
-- - This migration intentionally does not change function bodies.
-- - Functional tests must be executed after applying it.

begin;

-- -----------------------------------------------------------------------------
-- Root-only RPCs: callable only by authenticated sessions; function body must
-- enforce public.is_root(). Anonymous execution is unnecessary attack surface.
-- -----------------------------------------------------------------------------

revoke execute on function public.listar_empresas_root() from anon;
revoke execute on function public.listar_empresas_root() from public;
grant execute on function public.listar_empresas_root() to authenticated;

revoke execute on function public.registrar_root_audit(text, uuid, jsonb) from anon;
revoke execute on function public.registrar_root_audit(text, uuid, jsonb) from public;
grant execute on function public.registrar_root_audit(text, uuid, jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- Authenticated operational RPCs: keep authenticated only, no anon/public.
-- -----------------------------------------------------------------------------

revoke execute on function public.get_corretores_time(uuid) from anon;
revoke execute on function public.get_corretores_time(uuid) from public;
grant execute on function public.get_corretores_time(uuid) to authenticated;

revoke execute on function public.importar_leads_batch(uuid, jsonb, text) from anon;
revoke execute on function public.importar_leads_batch(uuid, jsonb, text) from public;
grant execute on function public.importar_leads_batch(uuid, jsonb, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Password-like RPC: keep unavailable to client roles.
--
-- Current function accepts p_nova_senha text but does not use/store it. Even so,
-- plaintext password-shaped inputs must not be exposed as a public SQL RPC API.
-- -----------------------------------------------------------------------------

revoke execute on function public.redefinir_senha_corretor(uuid, text) from anon;
revoke execute on function public.redefinir_senha_corretor(uuid, text) from authenticated;
revoke execute on function public.redefinir_senha_corretor(uuid, text) from public;

commit;
