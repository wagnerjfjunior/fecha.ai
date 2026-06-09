do $$
declare
  v_oid oid;
  v_digest text;
begin
  select p.oid
  into v_oid
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'criar_empresa_root'
    and pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer';

  if v_oid is null then
    raise notice 'public.criar_empresa_root(text, text, uuid, integer) not found; skipping live-only grant hardening.';
    return;
  end if;

  select md5(lower(pg_get_functiondef(v_oid)))
  into v_digest;

  if v_digest <> 'b94e9ff1a640af22768ccdc9ba34f84f' then
    raise exception 'public.criar_empresa_root body fingerprint mismatch: expected %, got %',
      'b94e9ff1a640af22768ccdc9ba34f84f',
      v_digest;
  end if;

  execute 'revoke execute on function public.criar_empresa_root(text, text, uuid, integer) from PUBLIC';
  execute 'revoke execute on function public.criar_empresa_root(text, text, uuid, integer) from anon';
  execute 'grant execute on function public.criar_empresa_root(text, text, uuid, integer) to authenticated';
  execute 'grant execute on function public.criar_empresa_root(text, text, uuid, integer) to service_role';
end $$;
