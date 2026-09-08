-- FECH.AI — STS-M3-04-01
-- pme_message_usage authenticated write boundary: RPC-only
--
-- Objective:
-- - remove direct INSERT authority for role authenticated on public.pme_message_usage;
-- - remove the direct INSERT RLS policy;
-- - preserve authenticated SELECT;
-- - preserve public.pme_registrar_message_usage(uuid, jsonb) unchanged and callable by authenticated.
--
-- Principal risk addressed:
-- forged direct usage/telemetry DML bypassing the controlled RPC boundary.
--
-- Scope:
-- public.pme_message_usage INSERT grant + INSERT policy only.
-- No RPC body change. No frontend change. No data mutation.
--
-- Application to any environment requires a separate Product Authority authorization.

begin;

do $preflight$
declare
  v_policy_count integer;
begin
  if to_regclass('public.pme_message_usage') is null then
    raise exception 'STS-M3-04-01 preflight: public.pme_message_usage not found';
  end if;

  if to_regprocedure('public.pme_registrar_message_usage(uuid,jsonb)') is null then
    raise exception 'STS-M3-04-01 preflight: pme_registrar_message_usage(uuid,jsonb) not found';
  end if;

  if not has_table_privilege('authenticated', 'public.pme_message_usage', 'SELECT') then
    raise exception 'STS-M3-04-01 preflight: authenticated SELECT on pme_message_usage is missing';
  end if;

  if not has_table_privilege('authenticated', 'public.pme_message_usage', 'INSERT') then
    raise exception 'STS-M3-04-01 preflight: expected authenticated INSERT grant is already absent';
  end if;

  if has_table_privilege('authenticated', 'public.pme_message_usage', 'UPDATE')
     or has_table_privilege('authenticated', 'public.pme_message_usage', 'DELETE') then
    raise exception 'STS-M3-04-01 preflight: unexpected authenticated UPDATE/DELETE privilege';
  end if;

  select count(*)
    into v_policy_count
  from pg_policies
  where schemaname = 'public'
    and tablename = 'pme_message_usage'
    and policyname = 'pme_message_usage_insert'
    and cmd = 'INSERT';

  if v_policy_count <> 1 then
    raise exception 'STS-M3-04-01 preflight: expected exactly one pme_message_usage_insert INSERT policy, found %', v_policy_count;
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.pme_registrar_message_usage(uuid,jsonb)',
    'EXECUTE'
  ) then
    raise exception 'STS-M3-04-01 preflight: authenticated EXECUTE on pme_registrar_message_usage is missing';
  end if;

  if has_function_privilege(
    'anon',
    'public.pme_registrar_message_usage(uuid,jsonb)',
    'EXECUTE'
  ) then
    raise exception 'STS-M3-04-01 preflight: anon unexpectedly has EXECUTE on pme_registrar_message_usage';
  end if;
end
$preflight$;

revoke insert on table public.pme_message_usage from authenticated;

drop policy pme_message_usage_insert on public.pme_message_usage;

do $postflight$
declare
  v_direct_write_policy_count integer;
begin
  if not has_table_privilege('authenticated', 'public.pme_message_usage', 'SELECT') then
    raise exception 'STS-M3-04-01 postflight: authenticated SELECT was not preserved';
  end if;

  if has_table_privilege('authenticated', 'public.pme_message_usage', 'INSERT')
     or has_table_privilege('authenticated', 'public.pme_message_usage', 'UPDATE')
     or has_table_privilege('authenticated', 'public.pme_message_usage', 'DELETE') then
    raise exception 'STS-M3-04-01 postflight: authenticated direct write privilege remains';
  end if;

  if has_table_privilege('anon', 'public.pme_message_usage', 'INSERT')
     or has_table_privilege('anon', 'public.pme_message_usage', 'UPDATE')
     or has_table_privilege('anon', 'public.pme_message_usage', 'DELETE') then
    raise exception 'STS-M3-04-01 postflight: anon direct write privilege detected';
  end if;

  select count(*)
    into v_direct_write_policy_count
  from pg_policies
  where schemaname = 'public'
    and tablename = 'pme_message_usage'
    and cmd in ('INSERT', 'UPDATE', 'DELETE');

  if v_direct_write_policy_count <> 0 then
    raise exception 'STS-M3-04-01 postflight: direct write policy remains on pme_message_usage';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.pme_registrar_message_usage(uuid,jsonb)',
    'EXECUTE'
  ) then
    raise exception 'STS-M3-04-01 postflight: authenticated RPC EXECUTE was not preserved';
  end if;

  if has_function_privilege(
    'anon',
    'public.pme_registrar_message_usage(uuid,jsonb)',
    'EXECUTE'
  ) then
    raise exception 'STS-M3-04-01 postflight: anon unexpectedly has RPC EXECUTE';
  end if;
end
$postflight$;

commit;

-- Rollback (manual; requires separate authorization before execution):
--
-- begin;
--
-- create policy pme_message_usage_insert
-- on public.pme_message_usage
-- for insert
-- with check (public.pme_can_consume_empresa(empresa_id));
--
-- grant insert on table public.pme_message_usage to authenticated;
--
-- commit;
