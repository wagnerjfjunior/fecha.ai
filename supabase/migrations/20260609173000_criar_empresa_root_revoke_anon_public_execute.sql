-- FECH.AI / Supabase
-- Purpose: narrow EXECUTE exposure for public.criar_empresa_root only.
-- Scope: public.criar_empresa_root(text, text, uuid, integer)
-- No data changes. No RLS/policy changes. No function body changes.

-- Safety guard:
-- If the live-only RPC is absent in a clean replay database, this migration is a no-op.
-- If the RPC exists, the migration only runs when the reviewed function body still
-- matches the sanitized body fingerprint recorded in PR #74.
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

-- Remove broad and unauthenticated EXECUTE exposure.
revoke execute on function public.criar_empresa_root(text, text, uuid, integer) from PUBLIC;
revoke execute on function public.criar_empresa_root(text, text, uuid, integer) from anon;

-- Preserve authenticated caller path. The function body must still enforce root-only
-- authority through server-side is_root validation.
grant execute on function public.criar_empresa_root(text, text, uuid, integer) to authenticated;

-- Preserve backend service_role execution path.
grant execute on function public.criar_empresa_root(text, text, uuid, integer) to service_role;
end $$;

-- Rollback reference, do not run automatically:
-- grant execute on function public.criar_empresa_root(text, text, uuid, integer) to PUBLIC;
-- grant execute on function public.criar_empresa_root(text, text, uuid, integer) to anon;
-- grant execute on function public.criar_empresa_root(text, text, uuid, integer) to authenticated;
-- grant execute on function public.criar_empresa_root(text, text, uuid, integer) to service_role;
