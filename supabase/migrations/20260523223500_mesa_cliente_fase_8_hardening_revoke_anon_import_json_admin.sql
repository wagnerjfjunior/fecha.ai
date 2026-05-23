-- FECH.AI / MesaCliente
-- Fase 8 — Chateau Jardin
-- Hardening de RPCs administrativas de importacao JSON.
--
-- Objetivo:
--   Remover EXECUTE do role anon/public nas RPCs administrativas de importacao.
--   Manter EXECUTE apenas para authenticated e service_role.
--
-- Observacao:
--   Esta migration nao altera dados comerciais, unidades, tabelas de preco,
--   simulacoes ou motor financeiro. Apenas ajusta grants e comentarios.
--
-- Nota operacional:
--   Esta migration foi aplicada no Supabase antes do versionamento deste arquivo
--   para fechamento da Fase 8. O conteudo e idempotente quanto ao estado final
--   esperado dos grants.

revoke execute on function public.importar_mesa_cliente_json_admin(
  uuid, text, text, text, text, text, text, jsonb
) from anon;

revoke execute on function public.importar_mesa_cliente_json_admin(
  uuid, text, text, text, text, text, text, jsonb
) from public;

grant execute on function public.importar_mesa_cliente_json_admin(
  uuid, text, text, text, text, text, text, jsonb
) to authenticated;

grant execute on function public.importar_mesa_cliente_json_admin(
  uuid, text, text, text, text, text, text, jsonb
) to service_role;

comment on function public.importar_mesa_cliente_json_admin(
  uuid, text, text, text, text, text, text, jsonb
) is 'MesaCliente Fase 8: importacao JSON administrativa restrita a authenticated/service_role; anon sem EXECUTE.';

revoke execute on function public.importar_mesa_cliente_parser_resultado(
  uuid, text, text, text, text, text, text, jsonb
) from anon;

revoke execute on function public.importar_mesa_cliente_parser_resultado(
  uuid, text, text, text, text, text, text, jsonb
) from public;

grant execute on function public.importar_mesa_cliente_parser_resultado(
  uuid, text, text, text, text, text, text, jsonb
) to authenticated;

grant execute on function public.importar_mesa_cliente_parser_resultado(
  uuid, text, text, text, text, text, text, jsonb
) to service_role;

comment on function public.importar_mesa_cliente_parser_resultado(
  uuid, text, text, text, text, text, text, jsonb
) is 'MesaCliente Fase 8: parser administrativo de importacao JSON restrito a authenticated/service_role; anon sem EXECUTE.';

revoke execute on function public.usuario_pode_importar_mesa_json_admin(uuid) from anon;
revoke execute on function public.usuario_pode_importar_mesa_json_admin(uuid) from public;

grant execute on function public.usuario_pode_importar_mesa_json_admin(uuid) to authenticated;
grant execute on function public.usuario_pode_importar_mesa_json_admin(uuid) to service_role;

comment on function public.usuario_pode_importar_mesa_json_admin(uuid) is 'MesaCliente Fase 8: helper de autorizacao para importacao JSON administrativa; anon sem EXECUTE.';
