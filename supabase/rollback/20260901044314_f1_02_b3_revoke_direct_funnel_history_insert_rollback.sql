-- FECH.AI — F1-02 / B3 rollback
-- Restores only the authenticated INSERT grant and the exact removed policy.
-- SECURITY WARNING: successful rollback REOPENS F1-02/B3. SECURITY_GO remains
-- DENIED and the pilot must remain contained pending a remediation decision.
--
-- VERSIONED ARTIFACT ONLY. This file is not authorization to apply to Supabase.

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';
set local idle_in_transaction_session_timeout = '60s';
set local search_path = 'pg_catalog', 'public';

lock table public.funil_movimentacoes in access exclusive mode;

do $f1_02_b3_rollback_preflight$
declare
  v_rls boolean;
  v_force_rls boolean;
  v_count integer;
  v_rows bigint;
begin
  if pg_catalog.to_regrole('authenticated') is null
     or pg_catalog.to_regclass('public.funil_movimentacoes') is null then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_REQUIRED_OBJECT_OR_ROLE_MISSING';
  end if;

  if pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     ) then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_INSERT_ALREADY_PRESENT';
  end if;

  if not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'SELECT'
     ) then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_SELECT_MISSING';
  end if;

  select count(*) into v_count
  from pg_catalog.pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'funil_movimentacoes'
    and p.policyname = 'funil_mov_insert';
  if v_count <> 0 then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_POLICY_COLLISION count=%', v_count;
  end if;

  select c.relrowsecurity, c.relforcerowsecurity
    into v_rls, v_force_rls
  from pg_catalog.pg_class c
  where c.oid = 'public.funil_movimentacoes'::pg_catalog.regclass;
  if v_rls is distinct from true or v_force_rls is distinct from true then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_RLS_DRIFT';
  end if;

  select count(*) into v_count
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and c.convalidated
    and c.conname in (
      'fk_m1_c_f01_funil_mov_lead_empresa',
      'fk_m1_c_f01_funil_mov_corretor_empresa',
      'fk_m1_c_f01_funil_mov_estagio_empresa',
      'fk_m1_c_f01_funil_mov_estagio_anterior_empresa'
    );
  if v_count <> 4 then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_COMPOSITE_FK_DRIFT count=%', v_count;
  end if;

  select count(*) into v_count
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'public.funil_movimentacoes'::pg_catalog.regclass
    and not t.tgisinternal;
  if v_count <> 0 then
    raise exception 'F1_02_B3_ROLLBACK_PREFLIGHT_UNEXPECTED_TRIGGER count=%', v_count;
  end if;

  select count(*) into v_rows from public.funil_movimentacoes;
  perform pg_catalog.set_config('fechai.f1_02_b3_rollback_row_count', v_rows::text, true);
end;
$f1_02_b3_rollback_preflight$;

create policy funil_mov_insert
on public.funil_movimentacoes
as permissive
for insert
to public
with check (
  is_root()
  or corretor_id = my_corretor_id()
);

grant insert on table public.funil_movimentacoes to authenticated;

do $f1_02_b3_rollback_postflight$
declare
  v_count integer;
  v_rows_before bigint;
  v_rows_after bigint;
begin
  if not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     )
     or not pg_catalog.has_any_column_privilege(
       'authenticated', 'public.funil_movimentacoes', 'INSERT'
     )
     or not pg_catalog.has_table_privilege(
       'authenticated', 'public.funil_movimentacoes', 'SELECT'
     ) then
    raise exception 'F1_02_B3_ROLLBACK_POSTFLIGHT_AUTHENTICATED_ACL_FAILURE';
  end if;

  select count(*) into v_count
  from pg_catalog.pg_policies p
  where p.schemaname = 'public'
    and p.tablename = 'funil_movimentacoes'
    and p.policyname = 'funil_mov_insert'
    and p.permissive = 'PERMISSIVE'
    and p.roles = '{public}'::name[]
    and p.cmd = 'INSERT'
    and p.qual is null
    and p.with_check = '(is_root() OR (corretor_id = my_corretor_id()))';
  if v_count <> 1 then
    raise exception 'F1_02_B3_ROLLBACK_POSTFLIGHT_POLICY_FAILURE matches=%', v_count;
  end if;

  v_rows_before :=
    pg_catalog.current_setting('fechai.f1_02_b3_rollback_row_count')::bigint;
  select count(*) into v_rows_after from public.funil_movimentacoes;
  if v_rows_after <> v_rows_before then
    raise exception 'F1_02_B3_ROLLBACK_POSTFLIGHT_DATA_MUTATION before=% after=%',
      v_rows_before, v_rows_after;
  end if;
end;
$f1_02_b3_rollback_postflight$;

commit;

-- STOP CONDITION AFTER ROLLBACK:
-- F1-02/B3 = OPEN
-- SECURITY_GO = DENIED
-- PILOT = CONTAINED
