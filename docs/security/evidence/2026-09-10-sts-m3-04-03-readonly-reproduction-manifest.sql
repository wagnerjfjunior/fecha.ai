-- FECH.AI — STS-M3-04-03 — READ_ONLY reproduction manifest
-- Date: 2026-09-10
-- Purpose: reproducible catalog/aggregate queries for the Global Tenant Surface
--          & Relationship Inventory without persisting row-level business data.
--
-- IMPORTANT:
--   VERSIONED QUERY MANIFEST != EXECUTED QUERY
--   This file is documentation/evidence only. PR #215 correction does not
--   execute it and does not authorize Supabase/runtime mutation.
--
-- Safety properties:
--   * SELECT/catalog reads only;
--   * mismatch checks return aggregate counts only;
--   * no customer/lead UUID, name, phone, email or payload is returned;
--   * intended for a separately authorized future live READ_ONLY replay when
--     exact current catalog reproduction is required.

begin transaction read only;

-- Q01 — Public base-table universe + RLS/FORCE RLS + empresa_id presence.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls,
  exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid = c.oid
      and a.attname = 'empresa_id'
      and a.attnum > 0
      and not a.attisdropped
  ) as has_empresa_id
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r','p')
order by c.relname;

-- Q02 — Global object-class cardinalities used by the inventory.
select 'public_base_tables' as metric, count(*)::bigint as value
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind in ('r','p')
union all
select 'public_views', count(*)::bigint
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='v'
union all
select 'public_policies', count(*)::bigint
from pg_catalog.pg_policies p where p.schemaname='public'
union all
select 'public_user_triggers', count(*)::bigint
from pg_catalog.pg_trigger t
join pg_catalog.pg_class c on c.oid=t.tgrelid
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and not t.tgisinternal
union all
select 'public_constraints', count(*)::bigint
from pg_catalog.pg_constraint con
join pg_catalog.pg_class c on c.oid=con.conrelid
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
union all
select 'public_functions', count(*)::bigint
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prokind='f';

-- Q03 — Complete public FK relationship ledger, one row per FK, with exact
-- child/parent column arrays. This is the authoritative reproduction query for
-- the nominal FK rowset; it returns schema metadata only.
with fk as (
  select
    con.oid,
    con.conname,
    con.conrelid,
    con.confrelid,
    con.conkey,
    con.confkey,
    con.confdeltype,
    con.confupdtype,
    con.convalidated
  from pg_catalog.pg_constraint con
  join pg_catalog.pg_class child on child.oid=con.conrelid
  join pg_catalog.pg_namespace ns on ns.oid=child.relnamespace
  where con.contype='f' and ns.nspname='public'
)
select
  f.conname as constraint_name,
  child.relname as child_table,
  array(
    select a.attname::text
    from unnest(f.conkey) with ordinality k(attnum,ord)
    join pg_catalog.pg_attribute a
      on a.attrelid=f.conrelid and a.attnum=k.attnum
    order by k.ord
  ) as child_columns,
  parent_ns.nspname as parent_schema,
  parent.relname as parent_table,
  array(
    select a.attname::text
    from unnest(f.confkey) with ordinality k(attnum,ord)
    join pg_catalog.pg_attribute a
      on a.attrelid=f.confrelid and a.attnum=k.attnum
    order by k.ord
  ) as parent_columns,
  f.convalidated as validated,
  f.confdeltype as delete_action_code,
  f.confupdtype as update_action_code
from fk f
join pg_catalog.pg_class child on child.oid=f.conrelid
join pg_catalog.pg_class parent on parent.oid=f.confrelid
join pg_catalog.pg_namespace parent_ns on parent_ns.oid=parent.relnamespace
order by child.relname, f.conname;

-- Q04 — Composite tenant-bound FKs where both sides include empresa_id.
with fk_cols as (
  select
    con.oid,
    con.conname,
    con.conrelid,
    con.confrelid,
    array(
      select a.attname::text
      from unnest(con.conkey) with ordinality k(attnum,ord)
      join pg_catalog.pg_attribute a
        on a.attrelid=con.conrelid and a.attnum=k.attnum
      order by k.ord
    ) child_cols,
    array(
      select a.attname::text
      from unnest(con.confkey) with ordinality k(attnum,ord)
      join pg_catalog.pg_attribute a
        on a.attrelid=con.confrelid and a.attnum=k.attnum
      order by k.ord
    ) parent_cols
  from pg_catalog.pg_constraint con
  join pg_catalog.pg_class child on child.oid=con.conrelid
  join pg_catalog.pg_namespace ns on ns.oid=child.relnamespace
  where con.contype='f' and ns.nspname='public'
)
select
  child.relname as child_table,
  f.conname as constraint_name,
  f.child_cols as child_columns,
  parent.relname as parent_table,
  f.parent_cols as parent_columns
from fk_cols f
join pg_catalog.pg_class child on child.oid=f.conrelid
join pg_catalog.pg_class parent on parent.oid=f.confrelid
where 'empresa_id'=any(f.child_cols)
  and 'empresa_id'=any(f.parent_cols)
order by child.relname, f.conname;

-- Q05 — Simple FK relationships between tables that both carry empresa_id and
-- that have no composite FK pairing the same child object column with
-- empresa_id. This query reproduces the inventory's nominal 'simple without
-- tenant pair' rowset; its count was 75 during the original READ_ONLY session.
with table_has_empresa as (
  select c.oid
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public'
    and c.relkind in ('r','p')
    and exists (
      select 1 from pg_catalog.pg_attribute a
      where a.attrelid=c.oid and a.attname='empresa_id'
        and a.attnum>0 and not a.attisdropped
    )
), fk as (
  select con.*
  from pg_catalog.pg_constraint con
  where con.contype='f'
    and con.conrelid in (select oid from table_has_empresa)
    and con.confrelid in (select oid from table_has_empresa)
), single_fk as (
  select f.*, f.conkey[1] as child_attnum, f.confkey[1] as parent_attnum
  from fk f
  where cardinality(f.conkey)=1 and cardinality(f.confkey)=1
)
select
  child.relname as child_table,
  child_col.attname as child_column,
  parent.relname as parent_table,
  parent_col.attname as parent_column,
  s.conname as simple_constraint_name,
  exists (
    select 1
    from fk c
    where c.conrelid=s.conrelid
      and c.confrelid=s.confrelid
      and cardinality(c.conkey)>=2
      and s.child_attnum=any(c.conkey)
      and (
        select a.attnum
        from pg_catalog.pg_attribute a
        where a.attrelid=s.conrelid and a.attname='empresa_id'
          and a.attnum>0 and not a.attisdropped
      )=any(c.conkey)
      and (
        select a.attnum
        from pg_catalog.pg_attribute a
        where a.attrelid=s.confrelid and a.attname='empresa_id'
          and a.attnum>0 and not a.attisdropped
      )=any(c.confkey)
  ) as matching_composite_tenant_fk_exists
from single_fk s
join pg_catalog.pg_class child on child.oid=s.conrelid
join pg_catalog.pg_attribute child_col
  on child_col.attrelid=s.conrelid and child_col.attnum=s.child_attnum
join pg_catalog.pg_class parent on parent.oid=s.confrelid
join pg_catalog.pg_attribute parent_col
  on parent_col.attrelid=s.confrelid and parent_col.attnum=s.parent_attnum
where not exists (
  select 1
  from fk c
  where c.conrelid=s.conrelid
    and c.confrelid=s.confrelid
    and cardinality(c.conkey)>=2
    and s.child_attnum=any(c.conkey)
    and (
      select a.attnum
      from pg_catalog.pg_attribute a
      where a.attrelid=s.conrelid and a.attname='empresa_id'
        and a.attnum>0 and not a.attisdropped
    )=any(c.conkey)
    and (
      select a.attnum
      from pg_catalog.pg_attribute a
      where a.attrelid=s.confrelid and a.attname='empresa_id'
        and a.attnum>0 and not a.attisdropped
    )=any(c.confkey)
)
order by child.relname, child_col.attname, parent.relname;

-- Q06 — UUID relation-like columns without a declared FK. This intentionally
-- returns metadata only; it is a discovery queue, not a vulnerability verdict.
with fk_child_columns as (
  select con.conrelid, unnest(con.conkey) as attnum
  from pg_catalog.pg_constraint con
  where con.contype='f'
)
select
  c.relname as table_name,
  a.attname as column_name,
  pg_catalog.format_type(a.atttypid,a.atttypmod) as data_type,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
join pg_catalog.pg_attribute a on a.attrelid=c.oid
where n.nspname='public'
  and c.relkind in ('r','p')
  and a.attnum>0 and not a.attisdropped
  and a.atttypid='uuid'::regtype
  and (a.attname like '%\_id' escape '\' or a.attname='empresa_id')
  and not exists (
    select 1 from fk_child_columns f
    where f.conrelid=c.oid and f.attnum=a.attnum
  )
order by c.relname,a.attname;

-- Q07 — Policies for material tenant-bearing tables.
select schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check
from pg_catalog.pg_policies
where schemaname='public'
order by tablename,policyname;

-- Q08 — Non-internal triggers and trigger functions.
select
  c.relname as table_name,
  t.tgname as trigger_name,
  p.proname as function_name,
  pg_catalog.pg_get_triggerdef(t.oid,true) as trigger_definition
from pg_catalog.pg_trigger t
join pg_catalog.pg_class c on c.oid=t.tgrelid
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
join pg_catalog.pg_proc p on p.oid=t.tgfoid
where n.nspname='public' and not t.tgisinternal
order by c.relname,t.tgname;

-- Q09 — Effective table privileges for anon/authenticated, metadata only.
select
  c.relname as table_name,
  r.rolname as role_name,
  has_table_privilege(r.rolname,c.oid,'SELECT') as can_select,
  has_table_privilege(r.rolname,c.oid,'INSERT') as can_insert,
  has_table_privilege(r.rolname,c.oid,'UPDATE') as can_update,
  has_table_privilege(r.rolname,c.oid,'DELETE') as can_delete
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid=c.relnamespace
cross join pg_catalog.pg_roles r
where n.nspname='public'
  and c.relkind in ('r','p')
  and r.rolname in ('anon','authenticated')
order by c.relname,r.rolname;

-- Q10 — F-04 aggregate consistency only; no identifiers returned.
select
  count(*) filter (
    where la.empresa_id is distinct from l.empresa_id
  ) as lista_tenant_mismatches,
  count(*) filter (
    where la.empresa_id is distinct from lo.empresa_id
  ) as lote_tenant_mismatches,
  count(*) filter (
    where la.empresa_id is distinct from c.empresa_id
  ) as corretor_tenant_mismatches
from public.lista_avaliacoes la
left join public.listas l on l.id=la.lista_id
left join public.lotes lo on lo.id=la.lote_id
left join public.corretores c on c.id=la.corretor_id;

-- Q11 — F-05 PME aggregate consistency. Each result is a count only.
select 'pme_cadence_steps.cadence_id' as relationship, count(*)::bigint as mismatch_count
from public.pme_cadence_steps s
join public.pme_cadences c on c.id=s.cadence_id
where s.empresa_id is distinct from c.empresa_id
union all
select 'pme_cadences.empreendimento_id', count(*)::bigint
from public.pme_cadences x
join public.empreendimentos e on e.id=x.empreendimento_id
where x.empreendimento_id is not null and x.empresa_id is distinct from e.empresa_id
union all
select 'pme_call_scripts.empreendimento_id', count(*)::bigint
from public.pme_call_scripts x
join public.empreendimentos e on e.id=x.empreendimento_id
where x.empreendimento_id is not null and x.empresa_id is distinct from e.empresa_id
union all
select 'pme_message_templates.empreendimento_id', count(*)::bigint
from public.pme_message_templates x
join public.empreendimentos e on e.id=x.empreendimento_id
where x.empreendimento_id is not null and x.empresa_id is distinct from e.empresa_id;

-- Q12 — GTI-01 aggregate proof. Returns count only; no lead/stage identifiers.
select count(*)::bigint as lead_current_stage_cross_tenant_mismatches
from public.leads l
join public.funil_estagios fe on fe.id=l.funil_estagio_id
where l.funil_estagio_id is not null
  and l.empresa_id is distinct from fe.empresa_id;

-- Q13 — Verify parent candidate key for future GTI-01 remediation design.
select
  con.conname,
  pg_catalog.pg_get_constraintdef(con.oid,true) as constraint_definition,
  con.convalidated
from pg_catalog.pg_constraint con
where con.conrelid='public.funil_estagios'::regclass
  and con.contype in ('u','p')
order by con.conname;

-- Q14 — Existing leads FKs involving current stage and tenant columns.
select
  con.conname,
  pg_catalog.pg_get_constraintdef(con.oid,true) as constraint_definition,
  con.convalidated
from pg_catalog.pg_constraint con
where con.conrelid='public.leads'::regclass
  and con.contype='f'
order by con.conname;

rollback;
