-- FECH.AI / MesaCliente / PR #63
-- Classe A: grant-hardening single-rpc para public.aprovar_rejeitar_mesa.
--
-- Objetivo:
--   Remover EXECUTE indevido de PUBLIC e anon somente da RPC
--   public.aprovar_rejeitar_mesa, preservando EXECUTE para authenticated.
--
-- Escopo negativo:
--   Esta migration nao altera body de function, owner, SECURITY DEFINER,
--   search_path, tabelas, dados, RLS, FORCE RLS, policies, grants de tabelas,
--   frontend ou qualquer outra RPC.
--
-- Assinatura:
--   A assinatura exata nao esta versionada no repo. Por isso, o bloco abaixo
--   resolve a function por schema + proname em pg_proc e aborta se houver 0
--   ou mais de 1 overload, evitando chutar tipos.
--
-- Rollback manual, se esta migration for aplicada indevidamente e houver GO
-- operacional explicito para restaurar a exposicao anterior:
--   begin;
--   do $$
--   declare
--     v_count integer;
--     v_oid oid;
--     v_function regprocedure;
--   begin
--     select count(*), min(p.oid)
--       into v_count, v_oid
--       from pg_proc p
--       join pg_namespace n on n.oid = p.pronamespace
--      where n.nspname = 'public'
--        and p.proname = 'aprovar_rejeitar_mesa';
--
--     if v_count <> 1 then
--       raise exception 'Rollback abortado: esperado 1 overload public.aprovar_rejeitar_mesa, encontrado %', v_count;
--     end if;
--
--     v_function := v_oid::regprocedure;
--     execute format('grant execute on function %s to public', v_function);
--     execute format('grant execute on function %s to anon', v_function);
--     execute format('grant execute on function %s to authenticated', v_function);
--   end $$;
--   commit;

begin;

do $$
declare
  v_count integer;
  v_oid oid;
  v_function regprocedure;
begin
  select count(*), min(p.oid)
    into v_count, v_oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'aprovar_rejeitar_mesa';

  if v_count <> 1 then
    raise exception 'Abortado: esperado 1 overload public.aprovar_rejeitar_mesa, encontrado %', v_count;
  end if;

  v_function := v_oid::regprocedure;

  execute format('revoke execute on function %s from public', v_function);
  execute format('revoke execute on function %s from anon', v_function);
  execute format('grant execute on function %s to authenticated', v_function);
end $$;

commit;
