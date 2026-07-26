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
  if to_regclass('public.corretores') is null then
    raise exception 'PR01_PREFLIGHT_CORRETORES_TABLE_MISSING';
  end if;

  if to_regprocedure('auth.uid()') is null then
    raise exception 'PR01_PREFLIGHT_AUTH_UID_MISSING';
  end if;

  if to_regprocedure('public.marcar_senha_inicial_definida()') is not null then
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

  if to_regrole('postgres') is null then
    raise exception 'PR01_PREFLIGHT_POSTGRES_ROLE_MISSING';
  end if;

  if to_regrole('authenticated') is null then
    raise exception 'PR01_PREFLIGHT_AUTHENTICATED_ROLE_MISSING';
  end if;

  if to_regrole('anon') is null then
    raise exception 'PR01_PREFLIGHT_ANON_ROLE_MISSING';
  end if;

  if to_regrole('service_role') is null then
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
  begin
    select c.ativo
      into strict v_profile_active
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

  -- TRUE means the authenticated active profile is in the completed state.
  -- Repeated calls are successful and do not issue another UPDATE.
  return true;
end;
$function$;

alter function public.marcar_senha_inicial_definida() owner to postgres;

revoke all on function public.marcar_senha_inicial_definida() from public;
revoke all on function public.marcar_senha_inicial_definida() from anon;
revoke all on function public.marcar_senha_inicial_definida() from service_role;
grant execute on function public.marcar_senha_inicial_definida() to authenticated;

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
