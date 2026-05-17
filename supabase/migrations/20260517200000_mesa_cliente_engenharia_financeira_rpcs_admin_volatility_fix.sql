-- MesaCliente Engenharia Financeira — Fix de volatilidade das RPCs administrativas
--
-- Problema:
--   As RPCs de leitura administrativa foram criadas como STABLE.
--   Quando chamadas logo após um upsert na mesma execução/transação, o PostgreSQL
--   pode usar snapshot anterior e não enxergar a política recém-criada.
--
-- Correção:
--   Marcar as RPCs de leitura administrativa como VOLATILE.
--   Isso não muda permissões, RLS, tabelas, parser, Worker, Make ou front.

begin;

alter function public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer) volatile;
alter function public.mesa_cliente_obter_politica_financeira(uuid, uuid) volatile;

comment on function public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer) is
'MesaCliente Engenharia Financeira: lista políticas financeiras internas para admin/gestor. VOLATILE para enxergar writes recentes em validações/RPCs transacionais.';

comment on function public.mesa_cliente_obter_politica_financeira(uuid, uuid) is
'MesaCliente Engenharia Financeira: obtém política completa com faixas internas para admin/gestor. VOLATILE para enxergar writes recentes após upserts transacionais.';

commit;
