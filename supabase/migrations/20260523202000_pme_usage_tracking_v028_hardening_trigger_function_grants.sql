-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- Hardening pós-smoke 16A — grants da trigger function pme_set_updated_at()
--
-- Motivo:
-- - O smoke 16A validou catálogo/RLS/policies/grants das tabelas.
-- - Único FAIL: public.pme_set_updated_at() estava com EXECUTE para authenticated.
-- - Esta função é trigger helper interna e não deve ser invocável diretamente por cliente autenticado.
--
-- Segurança:
-- - Não altera tabelas.
-- - Não altera dados.
-- - Não altera policies.
-- - Não altera RPC pública pme_registrar_message_usage(uuid,jsonb).
-- - Triggers existentes continuam funcionando; privilégio direto de EXECUTE por authenticated/service_role não é necessário para disparo do trigger.

begin;

revoke all on function public.pme_set_updated_at() from public;
revoke all on function public.pme_set_updated_at() from anon;
revoke all on function public.pme_set_updated_at() from authenticated;
revoke all on function public.pme_set_updated_at() from service_role;

comment on function public.pme_set_updated_at()
is 'PME v0.2.8: trigger helper interna para updated_at. Sem EXECUTE direto para anon/public/authenticated/service_role.';

commit;
