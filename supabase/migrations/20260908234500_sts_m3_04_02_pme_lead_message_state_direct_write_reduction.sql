-- FECH.AI — STS-M3-04-02
-- PME lead message state direct-write reduction
-- Scope: public.pme_lead_message_state only
-- Authorization: versioned GitHub implementation only; DO NOT apply to Supabase under this authorization.
--
-- Security objective:
-- - remove authenticated direct INSERT/UPDATE authority;
-- - preserve authenticated SELECT;
-- - preserve service_role privileges by not modifying them;
-- - preserve RLS, schema, data, constraints, indexes, triggers and functions/RPCs;
-- - remove only the INSERT/UPDATE policies named below.
--
-- No new write boundary is introduced by this migration.

begin;

-- Fail-closed preflight: the migration is valid only against the exact expected
-- repository-era authorization surface. Any drift aborts before the authorized
-- revoke/drop statements execute.
do $$
declare
  v_rls_enabled boolean;
  v_authenticated_privileges text[];
  v_anon_privileges text[];
  v_select_policies integer;
  v_insert_policies integer;
  v_update_policies integer;
  v_delete_policies integer;
  v_all_policies integer;
begin
  select c.relrowsecurity
    into v_rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'pme_lead_message_state'
    and c.relkind in ('r', 'p');

  if not found then
    raise exception 'STS-M3-04-02 preflight failed: public.pme_lead_message_state missing';
  end if;

  if v_rls_enabled is distinct from true then
    raise exception 'STS-M3-04-02 preflight failed: RLS must be enabled';
  end if;

  select coalesce(
           array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text),
           array[]::text[]
         )
    into v_authenticated_privileges
  from information_schema.table_privileges tp
  where tp.table_schema = 'public'
    and tp.table_name = 'pme_lead_message_state'
    and tp.grantee = 'authenticated';

  if v_authenticated_privileges <> array['INSERT','SELECT','UPDATE']::text[] then
    raise exception
      'STS-M3-04-02 preflight failed: authenticated privileges drifted (observed=%)',
      v_authenticated_privileges;
  end if;

  select coalesce(
           array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text),
           array[]::text[]
         )
    into v_anon_privileges
  from information_schema.table_privileges tp
  where tp.table_schema = 'public'
    and tp.table_name = 'pme_lead_message_state'
    and tp.grantee = 'anon';

  if cardinality(v_anon_privileges) <> 0 then
    raise exception
      'STS-M3-04-02 preflight failed: anon privileges must be absent (observed=%)',
      v_anon_privileges;
  end if;

  select
    count(*) filter (where p.cmd = 'SELECT'),
    count(*) filter (where p.cmd = 'INSERT'),
    count(*) filter (where p.cmd = 'UPDATE'),
    count(*) filter (where p.cmd = 'DELETE'),
    count(*) filter (where p.cmd = 'ALL')
  into
    v_select_policies,
    v_insert_policies,
    v_update_policies,
    v_delete_policies,
    v_all_policies
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'pme_lead_message_state';

  if v_select_policies <> 1
     or v_insert_policies <> 1
     or v_update_policies <> 1
     or v_delete_policies <> 0
     or v_all_policies <> 0 then
    raise exception
      'STS-M3-04-02 preflight failed: policy command surface drifted (select=%, insert=%, update=%, delete=%, all=%)',
      v_select_policies,
      v_insert_policies,
      v_update_policies,
      v_delete_policies,
      v_all_policies;
  end if;

  if not exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'pme_lead_message_state'
      and p.policyname = 'pme_lead_message_state_select'
      and p.cmd = 'SELECT'
  ) then
    raise exception 'STS-M3-04-02 preflight failed: expected SELECT policy missing';
  end if;

  if not exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'pme_lead_message_state'
      and p.policyname = 'pme_lead_message_state_insert'
      and p.cmd = 'INSERT'
  ) then
    raise exception 'STS-M3-04-02 preflight failed: expected INSERT policy missing';
  end if;

  if not exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'pme_lead_message_state'
      and p.policyname = 'pme_lead_message_state_update'
      and p.cmd = 'UPDATE'
  ) then
    raise exception 'STS-M3-04-02 preflight failed: expected UPDATE policy missing';
  end if;
end;
$$;

revoke insert on public.pme_lead_message_state from authenticated;
revoke update on public.pme_lead_message_state from authenticated;

drop policy pme_lead_message_state_insert
on public.pme_lead_message_state;

drop policy pme_lead_message_state_update
on public.pme_lead_message_state;

-- Fail-closed postflight for the intended resulting authority surface.
do $$
declare
  v_rls_enabled boolean;
  v_authenticated_privileges text[];
  v_anon_privileges text[];
  v_select_policies integer;
  v_insert_policies integer;
  v_update_policies integer;
  v_delete_policies integer;
  v_all_policies integer;
begin
  select c.relrowsecurity
    into v_rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'pme_lead_message_state'
    and c.relkind in ('r', 'p');

  if v_rls_enabled is distinct from true then
    raise exception 'STS-M3-04-02 postflight failed: RLS must remain enabled';
  end if;

  select coalesce(
           array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text),
           array[]::text[]
         )
    into v_authenticated_privileges
  from information_schema.table_privileges tp
  where tp.table_schema = 'public'
    and tp.table_name = 'pme_lead_message_state'
    and tp.grantee = 'authenticated';

  if v_authenticated_privileges <> array['SELECT']::text[] then
    raise exception
      'STS-M3-04-02 postflight failed: authenticated privileges must be SELECT-only (observed=%)',
      v_authenticated_privileges;
  end if;

  select coalesce(
           array_agg(distinct tp.privilege_type::text order by tp.privilege_type::text),
           array[]::text[]
         )
    into v_anon_privileges
  from information_schema.table_privileges tp
  where tp.table_schema = 'public'
    and tp.table_name = 'pme_lead_message_state'
    and tp.grantee = 'anon';

  if cardinality(v_anon_privileges) <> 0 then
    raise exception
      'STS-M3-04-02 postflight failed: anon privileges must remain absent (observed=%)',
      v_anon_privileges;
  end if;

  select
    count(*) filter (where p.cmd = 'SELECT'),
    count(*) filter (where p.cmd = 'INSERT'),
    count(*) filter (where p.cmd = 'UPDATE'),
    count(*) filter (where p.cmd = 'DELETE'),
    count(*) filter (where p.cmd = 'ALL')
  into
    v_select_policies,
    v_insert_policies,
    v_update_policies,
    v_delete_policies,
    v_all_policies
  from pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'pme_lead_message_state';

  if v_select_policies <> 1
     or v_insert_policies <> 0
     or v_update_policies <> 0
     or v_delete_policies <> 0
     or v_all_policies <> 0 then
    raise exception
      'STS-M3-04-02 postflight failed: unexpected policy command surface (select=%, insert=%, update=%, delete=%, all=%)',
      v_select_policies,
      v_insert_policies,
      v_update_policies,
      v_delete_policies,
      v_all_policies;
  end if;

  if not exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'pme_lead_message_state'
      and p.policyname = 'pme_lead_message_state_select'
      and p.cmd = 'SELECT'
  ) then
    raise exception 'STS-M3-04-02 postflight failed: SELECT policy was not preserved';
  end if;
end;
$$;

commit;

-- ROLLBACK CONTRACT — DOCUMENTATION ONLY; DO NOT EXECUTE UNDER STS-M3-04-02.
-- Executing this rollback reopens the accepted direct-write risk and therefore
-- does not preserve any later security acceptance.
--
-- begin;
-- grant insert, update on public.pme_lead_message_state to authenticated;
--
-- create policy pme_lead_message_state_insert
-- on public.pme_lead_message_state
-- for insert
-- with check (public.pme_can_access_empresa(empresa_id));
--
-- create policy pme_lead_message_state_update
-- on public.pme_lead_message_state
-- for update
-- using (public.pme_can_access_empresa(empresa_id))
-- with check (public.pme_can_access_empresa(empresa_id));
-- commit;
