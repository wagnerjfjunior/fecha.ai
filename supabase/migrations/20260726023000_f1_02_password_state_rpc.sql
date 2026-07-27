-- FECH.AI / F1-02 / PR-01
-- Purpose: add one narrow RPC for the authenticated broker to complete
-- the mandatory initial-password state without accepting row, tenant,
-- company, team, role or user identifiers from the client.
--
-- This migration does NOT revoke authenticated UPDATE on public.corretores.
-- The direct grant/policy compatibility window remains until PR-02 is
-- deployed and PR-03 is separately authorized.

-- Fail closed if the versioned contract does not match the target catalog.
do $preflight$
begin
  if pg_catalog.to_regclass('public.corretores') is null then
    raise exception 'PR01_PREFLIGHT_CORRETORES_TABLE_MISSING';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null then
    raise exception 'PR01_PREFLIGHT_AUTH_UID_MISSING';
  end if;

  if pg_catalog.to_regprocedure('public.marcar_senha_inicial_definida()') is not null then
    raise exception 'PR01_PREFLIGHT_FUNCTION_ALREADY_EXISTS';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corretores'
      and column_name = 'user_id'
      and data_type = 'uuid'
  ) then
    raise exception 'PR01_PREFLIGHT_USER_ID_UUID_MISSING';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corretores'
      and column_name = 'ativo'
      and data_type = 'boolean'
  ) then
    raise exception 'PR01_PREFLIGHT_ATIVO_BOOLEAN_MISSING';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corretores'
      and column_name = 'must_change_password'
      and data_type = 'boolean'
  ) then
    raise exception 'PR01_PREFLIGHT_PASSWORD_STATE_BOOLEAN_MISSING';
  end if;

  -- Concurrency contract: exactly one immediate, valid, ready, non-partial,
  -- non-expression UNIQUE index must protect the sole key public.corretores(user_id).
  -- The migration does not create or alter an index/constraint; it stops if the
  -- target catalog cannot prove the prerequisite.
  if not exists (
    select 1
    from pg_catalog.pg_index as i
    join pg_catalog.pg_class as t
      on t.oid = i.indrelid
    join pg_catalog.pg_namespace as n
      on n.oid = t.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid = t.oid
     and a.attname = 'user_id'
     and a.attnum > 0
     and not a.attisdropped
    where n.nspname = 'public'
      and t.relname = 'corretores'
      and t.relkind in ('r', 'p')
      and i.indisunique
      and i.indisvalid
      and i.indisready
      and i.indimmediate
      and i.indpred is null
      and i.indexprs is null
      and i.indnkeyatts = 1
      and i.indnatts = 1
      and i.indkey[0] = a.attnum
  ) then
    raise exception 'PR01_PREFLIGHT_USER_ID_UNIQUENESS_MISSING';
  end if;

  if pg_catalog.to_regrole('postgres') is null then
    raise exception 'PR01_PREFLIGHT_POSTGRES_ROLE_MISSING';
  end if;

  if pg_catalog.to_regrole('authenticated') is null then
    raise exception 'PR01_PREFLIGHT_AUTHENTICATED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regrole('anon') is null then
    raise exception 'PR01_PREFLIGHT_ANON_ROLE_MISSING';
  end if;

  if pg_catalog.to_regrole('service_role') is null then
    raise exception 'PR01_PREFLIGHT_SERVICE_ROLE_MISSING';
  end if;
end;
$preflight$;

create function public.marcar_senha_inicial_definida()
returns boolean
language plpgsql
security definer
set search_path = pg_catalog
as $function$
declare
  v_actor_id uuid;
  v_profile_active boolean;
  v_password_state boolean;
  v_updated_rows integer;
begin
  v_actor_id := auth.uid();

  if v_actor_id is null then
    raise exception using
      errcode = '42501',
      message = 'AUTH_REQUIRED';
  end if;

  -- INTO STRICT rejects both missing and ambiguous profile mappings.
  -- FOR UPDATE keeps the selected profile stable for this transaction.
  -- The migration preflight requires immediate uniqueness on user_id so a
  -- concurrent phantom duplicate cannot commit around this lock.
  begin
    select c.ativo, c.must_change_password
      into strict v_profile_active, v_password_state
      from public.corretores as c
     where c.user_id = v_actor_id
     for update;
  exception
    when no_data_found then
      raise exception using
        errcode = '42501',
        message = 'PROFILE_NOT_FOUND';
    when too_many_rows then
      raise exception using
        errcode = '21000',
        message = 'PROFILE_AMBIGUOUS';
  end;

  if v_profile_active is distinct from true then
    raise exception using
      errcode = '42501',
      message = 'PROFILE_INACTIVE';
  end if;

  -- Strict idempotency: an already-completed profile returns before any
  -- UPDATE statement is emitted, including statement-level trigger effects.
  if v_password_state is false then
    return true;
  end if;

  update public.corretores as c
     set must_change_password = false
   where c.user_id = v_actor_id
     and c.ativo is true
     and c.must_change_password is distinct from false;

  get diagnostics v_updated_rows = row_count;

  if v_updated_rows > 1 then
    raise exception using
      errcode = '21000',
      message = 'PROFILE_AMBIGUOUS';
  end if;

  -- Re-read the authoritative row after UPDATE/trigger execution. A missing,
  -- inactive, ambiguous or non-completed final state aborts the transaction.
  begin
    select c.ativo, c.must_change_password
      into strict v_profile_active, v_password_state
      from public.corretores as c
     where c.user_id = v_actor_id
     for update;
  exception
    when no_data_found then
      raise exception using
        errcode = '42501',
        message = 'PROFILE_NOT_FOUND';
    when too_many_rows then
      raise exception using
        errcode = '21000',
        message = 'PROFILE_AMBIGUOUS';
  end;

  if v_profile_active is distinct from true then
    raise exception using
      errcode = '42501',
      message = 'PROFILE_INACTIVE';
  end if;

  if v_password_state is distinct from false then
    raise exception using
      errcode = 'P0001',
      message = 'PASSWORD_STATE_NOT_COMPLETED';
  end if;

  return true;
end;
$function$;

alter function public.marcar_senha_inicial_definida() owner to postgres;

revoke all on function public.marcar_senha_inicial_definida() from public;
revoke all on function public.marcar_senha_inicial_definida() from anon;
revoke all on function public.marcar_senha_inicial_definida() from service_role;
grant execute on function public.marcar_senha_inicial_definida() to authenticated;

-- Fail closed if effective execution authority is broader than the PR-01
-- contract after owner assignment, default ACL materialization, REVOKE and GRANT.
do $postflight$
declare
  v_function_oid oid;
  v_owner_oid oid;
  v_postgres_oid oid;
  v_authenticated_oid oid;
  v_anon_oid oid;
  v_service_role_oid oid;
begin
  v_function_oid := pg_catalog.to_regprocedure(
    'public.marcar_senha_inicial_definida()'
  );
  v_postgres_oid := pg_catalog.to_regrole('postgres');
  v_authenticated_oid := pg_catalog.to_regrole('authenticated');
  v_anon_oid := pg_catalog.to_regrole('anon');
  v_service_role_oid := pg_catalog.to_regrole('service_role');

  if v_function_oid is null then
    raise exception 'PR01_POSTFLIGHT_FUNCTION_MISSING';
  end if;

  select p.proowner
    into strict v_owner_oid
    from pg_catalog.pg_proc as p
   where p.oid = v_function_oid;

  if v_owner_oid is distinct from v_postgres_oid then
    raise exception 'PR01_POSTFLIGHT_OWNER_NOT_POSTGRES';
  end if;

  if not pg_catalog.has_function_privilege(
    v_postgres_oid,
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception 'PR01_POSTFLIGHT_OWNER_EXECUTE_MISSING';
  end if;

  if not pg_catalog.has_function_privilege(
    v_authenticated_oid,
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception 'PR01_POSTFLIGHT_AUTHENTICATED_EXECUTE_MISSING';
  end if;

  if pg_catalog.has_function_privilege(
    v_anon_oid,
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception 'PR01_POSTFLIGHT_ANON_EXECUTE_PRESENT';
  end if;

  if pg_catalog.has_function_privilege(
    v_service_role_oid,
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception 'PR01_POSTFLIGHT_SERVICE_ROLE_EXECUTE_PRESENT';
  end if;

  if exists (
    select 1
      from pg_catalog.pg_proc as p
      cross join lateral pg_catalog.aclexplode(
        coalesce(
          p.proacl,
          pg_catalog.acldefault('f', p.proowner)
        )
      ) as acl
     where p.oid = v_function_oid
       and acl.privilege_type = 'EXECUTE'
       and acl.grantee = 0
  ) then
    raise exception 'PR01_POSTFLIGHT_PUBLIC_EXECUTE_PRESENT';
  end if;

  if not exists (
    select 1
      from pg_catalog.pg_proc as p
      cross join lateral pg_catalog.aclexplode(
        coalesce(
          p.proacl,
          pg_catalog.acldefault('f', p.proowner)
        )
      ) as acl
     where p.oid = v_function_oid
       and acl.privilege_type = 'EXECUTE'
       and acl.grantee = v_authenticated_oid
  ) then
    raise exception 'PR01_POSTFLIGHT_AUTHENTICATED_DIRECT_GRANT_MISSING';
  end if;

  if exists (
    select 1
      from pg_catalog.pg_proc as p
      cross join lateral pg_catalog.aclexplode(
        coalesce(
          p.proacl,
          pg_catalog.acldefault('f', p.proowner)
        )
      ) as acl
     where p.oid = v_function_oid
       and acl.privilege_type = 'EXECUTE'
       and acl.grantee not in (
         v_owner_oid,
         v_authenticated_oid
       )
  ) then
    raise exception 'PR01_POSTFLIGHT_UNEXPECTED_EXECUTOR';
  end if;
end;
$postflight$;

comment on function public.marcar_senha_inicial_definida() is
  'F1-02 PR-01: authenticated active broker completes only its own initial-password state; no client identifiers accepted.';

-- EXACT ROLLBACK — execute only under a separate authorized rollback operation.
-- The statements are intentionally kept in this migration so the rollback
-- remains version-coupled to the exact function signature introduced above.
--
-- revoke all on function public.marcar_senha_inicial_definida() from authenticated;
-- revoke all on function public.marcar_senha_inicial_definida() from public;
-- revoke all on function public.marcar_senha_inicial_definida() from anon;
-- revoke all on function public.marcar_senha_inicial_definida() from service_role;
-- drop function if exists public.marcar_senha_inicial_definida();
