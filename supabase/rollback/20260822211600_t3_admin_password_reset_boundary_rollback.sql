-- FECH.AI — T3A-v5 exact drift-aware rollback
--
-- Execute only under a separate rollback authority. Required order:
--   1. run this database rollback after its exact preflight passes;
--   2. keep the hardened Edge deployed: with the RPC absent it fails closed;
--   3. only then, under explicit Edge rollback authority, restore the reviewed
--      criar-usuario v17 baseline and verify its exact runtime fingerprint.
--
-- This rollback restores the exact pre-T3A T1 guard and compatibility grant.
-- It refuses to proceed while any durable reset lease or unexpired one-time
-- Edge proof exists. After the complete exact preflight succeeds, it removes
-- only expired inert proof rows before dropping the proven proof/fencing
-- objects. It does not rewrite business rows or Auth passwords.

begin;

-- Serialize the exact rollback boundary against ordinary writes and table DDL.
-- Follow the complete in-transaction writer direction: prepare consumes proof,
-- then reaches authority/lease and finally audit through the existing
-- corretores audit trigger. Other authority writers likewise reach audit last.
-- Edge audit and proof calls are separate committed HTTP transactions. This
-- proof -> authority -> lease -> audit order therefore avoids a reciprocal
-- relation-lock cycle. SHARE is held through post-rollback verification.
lock table public.t3_admin_password_reset_edge_proofs,
           public.admins,
           public.corretores,
           public.times,
           public.t3_admin_password_reset_leases,
           public.audit_logs in share mode;

-- =============================================================================
-- 1. FAIL-CLOSED ROLLBACK PREFLIGHT — NO DESTRUCTIVE STEP BEFORE THIS PASSES
-- =============================================================================
do $rollback_preflight$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_authenticator_oid oid:=pg_catalog.to_regrole('authenticator');
  v_database_owner_oid oid:=pg_catalog.to_regrole('pg_database_owner');
  v_t3_oid oid:=pg_catalog.to_regprocedure(
    'public.t3_prepare_admin_password_reset(uuid,uuid)'
  );
  v_issue_oid oid:=pg_catalog.to_regprocedure(
    'public.t3_issue_admin_password_reset_edge_proof(uuid,uuid)'
  );
  v_release_oid oid:=pg_catalog.to_regprocedure(
    'public.t3_release_admin_password_reset_lease(uuid,uuid,uuid)'
  );
  v_fence_oid oid:=pg_catalog.to_regprocedure(
    'public.t3_guard_admin_password_reset_lease()'
  );
  v_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );
  v_lease_rel_oid oid:=pg_catalog.to_regclass(
    'public.t3_admin_password_reset_leases'
  );
  v_proof_rel_oid oid:=pg_catalog.to_regclass(
    'public.t3_admin_password_reset_edge_proofs'
  );
  v_owner oid;
  v_definer boolean;
  v_config text[];
  v_md5 text;
  v_public_execute boolean;
  v_update_columns text[];
  v_routine_count bigint;
  v_routine_md5 text;
  v_authenticated_definer_count bigint;
  v_authenticated_definer_md5 text;
  v_aggregate_count bigint;
  v_membership_count bigint;
  v_membership_md5 text;
  v_schema_acl_count bigint;
  v_schema_acl_md5 text;
  v_column_acl_count bigint;
  v_column_acl_md5 text;
  v_policy_count bigint;
  v_policy_md5 text;
  r record;
begin
  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null
     or v_authenticator_oid is null
     or v_database_owner_oid is null
     or v_t3_oid is null
     or v_issue_oid is null
     or v_release_oid is null
     or v_fence_oid is null
     or v_guard_oid is null
     or v_lease_rel_oid is null
     or v_proof_rel_oid is null
     or pg_catalog.to_regprocedure(
          'public.t3_prepare_admin_password_reset(uuid)'
        ) is not null
     or pg_catalog.to_regclass('public.admins') is null
     or pg_catalog.to_regclass('public.corretores') is null
     or pg_catalog.to_regclass('public.times') is null
     or pg_catalog.to_regclass('public.audit_logs') is null then
    raise exception 'T3A_ROLLBACK_REQUIRED_OBJECT_MISSING';
  end if;

  if not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_postgres_oid
         and not role_row.rolsuper and role_row.rolinherit and role_row.rolcreaterole
         and role_row.rolcreatedb and role_row.rolcanlogin and role_row.rolreplication
         and role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_authenticated_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_anon_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_service_role_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_authenticator_oid
         and not role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_database_owner_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or pg_catalog.has_schema_privilege(
          v_authenticated_oid,'public','CREATE'
        )
     or pg_catalog.has_schema_privilege(v_anon_oid,'public','CREATE')
     or pg_catalog.has_schema_privilege(
          v_service_role_oid,'public','CREATE'
        )
     or not pg_catalog.has_schema_privilege(
              v_authenticated_oid,'public','USAGE'
            )
     or not pg_catalog.has_schema_privilege(v_anon_oid,'public','USAGE')
     or not pg_catalog.has_schema_privilege(
              v_service_role_oid,'public','USAGE'
            ) then
    raise exception 'T3A_ROLLBACK_CLIENT_ROLE_DRIFT';
  end if;

  with membership_items as (
    select pg_catalog.concat_ws(
             '|',granted.rolname,member_role.rolname,grantor.rolname,
             m.admin_option::text,m.inherit_option::text,m.set_option::text
           ) as item
    from pg_catalog.pg_auth_members as m
    join pg_catalog.pg_roles as granted on granted.oid=m.roleid
    join pg_catalog.pg_roles as member_role on member_role.oid=m.member
    join pg_catalog.pg_roles as grantor on grantor.oid=m.grantor
  )
  select pg_catalog.count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           item,E'\n' order by item
         ),''))
    into v_membership_count,v_membership_md5
  from membership_items;

  if v_membership_count is distinct from 21
     or v_membership_md5 is distinct from
          'fb803a204209bc71074a1eee7b57944e' then
    raise exception 'T3A_ROLLBACK_ROLE_MEMBERSHIP_GRAPH_DRIFT';
  end if;

  if not exists (
       select 1
       from pg_catalog.pg_database as d
       where d.datname=pg_catalog.current_database()
         and d.datdba=v_postgres_oid
     )
     or not exists (
       select 1
       from pg_catalog.pg_namespace as n
       where n.nspname='public'
         and n.nspowner=v_database_owner_oid
     ) then
    raise exception 'T3A_ROLLBACK_PUBLIC_SCHEMA_OWNER_DRIFT';
  end if;

  with schema_acl_items as (
    select pg_catalog.format(
             '%s>%s:%s:%s',
             case when acl.grantee=0 then 'PUBLIC'
                  else pg_catalog.pg_get_userbyid(acl.grantee) end,
             pg_catalog.pg_get_userbyid(acl.grantor),
             acl.privilege_type,
             acl.is_grantable
           ) as item
    from pg_catalog.pg_namespace as n
    cross join lateral pg_catalog.aclexplode(
      coalesce(n.nspacl,pg_catalog.acldefault('n',n.nspowner))
    ) as acl
    where n.nspname='public'
  )
  select pg_catalog.count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           item,E'\n' order by item
         ),''))
    into v_schema_acl_count,v_schema_acl_md5
  from schema_acl_items;

  if v_schema_acl_count is distinct from 7
     or v_schema_acl_md5 is distinct from
          'e2ad94b6bfb9b0cb8c4980459fd55a6e' then
    raise exception 'T3A_ROLLBACK_PUBLIC_SCHEMA_ACL_DRIFT';
  end if;

  if pg_catalog.to_regprocedure('auth.uid()') is null
     or not exists (
       select 1
       from pg_catalog.pg_proc as p
       where p.oid='auth.uid()'::regprocedure
         and pg_catalog.pg_get_userbyid(p.proowner)='supabase_auth_admin'
         and p.prosecdef is false
         and p.provolatile='s'
         and p.prorettype='uuid'::regtype
         and p.pronargs=0
         and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
           'ea3b41bf29e2ad573067939329aa088e'
         and pg_catalog.has_function_privilege(
               v_authenticated_oid,p.oid,'EXECUTE'
             )
         and pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
         and pg_catalog.has_function_privilege(
               v_service_role_oid,p.oid,'EXECUTE'
             )
     ) then
    raise exception 'T3A_ROLLBACK_AUTH_UID_DRIFT';
  end if;

  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='role' and data_type='text')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='admins' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='user_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='time_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='role' and data_type='text')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='ativo' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='apto_para_receber' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_admin_local' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='is_gestor' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='corretores' and column_name='must_change_password' and data_type='boolean')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='gestor_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='empresa_id' and data_type='uuid')
     or not exists (select 1 from information_schema.columns where table_schema='public' and table_name='times' and column_name='ativo' and data_type='boolean') then
    raise exception 'T3A_ROLLBACK_REQUIRED_COLUMN_DRIFT';
  end if;

  if not exists (
       select 1
       from pg_catalog.pg_class as c
       where c.oid=v_proof_rel_oid
         and c.relkind='r'
         and c.relpersistence='p'
         and c.relowner=v_postgres_oid
         and c.relrowsecurity
         and c.relforcerowsecurity
         and not exists (
           select 1
           from pg_catalog.aclexplode(
             coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
           ) as acl
           where acl.grantee<>v_postgres_oid
         )
         and pg_catalog.md5(coalesce((
           select pg_catalog.string_agg(
             pg_catalog.format(
               '%s>%s:%s:%s',
               case when acl.grantee=0 then 'PUBLIC'
                    else pg_catalog.pg_get_userbyid(acl.grantee) end,
               pg_catalog.pg_get_userbyid(acl.grantor),
               acl.privilege_type,
               acl.is_grantable
             ),
             ',' order by acl.grantee,acl.grantor,
                          acl.privilege_type,acl.is_grantable
           )
           from pg_catalog.aclexplode(
             coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
           ) as acl
         ),''))='df15c22895181b78b4b8c47092a334a0'
     )
     or (
       select pg_catalog.count(*)
       from pg_catalog.pg_attribute as a
       where a.attrelid=v_proof_rel_oid
         and a.attnum>0 and not a.attisdropped
     )<>4
     or exists (
       select 1
       from pg_catalog.pg_attribute as a
       cross join lateral pg_catalog.aclexplode(a.attacl) as acl
       where a.attrelid=v_proof_rel_oid
         and a.attnum>0 and not a.attisdropped
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_proof_rel_oid and a.attname='proof_id'
         and a.atttypid='uuid'::regtype and a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_proof_rel_oid and a.attname='actor_user_id'
         and a.atttypid='uuid'::regtype and a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_proof_rel_oid and a.attname='target_user_id'
         and a.atttypid='uuid'::regtype and a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1
       from pg_catalog.pg_attribute as a
       join pg_catalog.pg_attrdef as d
         on d.adrelid=a.attrelid and d.adnum=a.attnum
       where a.attrelid=v_proof_rel_oid and a.attname='created_at'
         and a.atttypid='timestamp with time zone'::regtype
         and a.attnotnull
         and pg_catalog.pg_get_expr(d.adbin,d.adrelid)=
             'statement_timestamp()'
     )
     or (
       select pg_catalog.count(*)
       from pg_catalog.pg_constraint as c
       where c.conrelid=v_proof_rel_oid
     )<>2
     or (
       select pg_catalog.count(*)
       from pg_catalog.pg_index as i
       where i.indrelid=v_proof_rel_oid
     )<>2
     or exists (
       select 1
       from pg_catalog.pg_constraint as c
       join pg_catalog.pg_index as i on i.indexrelid=c.conindid
       where c.conrelid=v_proof_rel_oid
         and c.contype in ('p','u')
         and (
           not i.indisunique or not i.indisvalid or not i.indisready
           or not i.indimmediate or i.indpred is not null
           or i.indexprs is not null or i.indnullsnotdistinct
           or i.indnkeyatts<>1 or i.indnatts<>1
         )
     )
     or not exists (
       select 1 from pg_catalog.pg_constraint as c
       where c.conrelid=v_proof_rel_oid
         and c.conname='t3_admin_password_reset_edge_proofs_pkey'
         and c.contype='p' and c.convalidated
         and not c.condeferrable and not c.condeferred
         and c.conkey=array[(
           select a.attnum from pg_catalog.pg_attribute as a
           where a.attrelid=v_proof_rel_oid and a.attname='proof_id'
         )]::smallint[]
     )
     or not exists (
       select 1 from pg_catalog.pg_constraint as c
       where c.conrelid=v_proof_rel_oid
         and c.conname='t3_admin_password_reset_edge_proofs_actor_user_id_key'
         and c.contype='u' and c.convalidated
         and not c.condeferrable and not c.condeferred
         and c.conkey=array[(
           select a.attnum from pg_catalog.pg_attribute as a
           where a.attrelid=v_proof_rel_oid and a.attname='actor_user_id'
         )]::smallint[]
     )
     or exists (
       select 1 from pg_catalog.pg_policy as p
       where p.polrelid=v_proof_rel_oid
     )
     or exists (
       select 1 from pg_catalog.pg_trigger as tg
       where tg.tgrelid=v_proof_rel_oid and not tg.tgisinternal
     )
     or exists (
       select 1 from pg_catalog.pg_rewrite as rw
       where rw.ev_class=v_proof_rel_oid
     )
     or pg_catalog.obj_description(v_proof_rel_oid,'pg_class') is distinct from
          'T3A-v4 inert one-time Edge-presence proof; PostgreSQL time; no actor authority' then
    raise exception 'T3A_ROLLBACK_EDGE_PROOF_TABLE_DRIFT';
  end if;

  if exists (
    select 1
    from public.t3_admin_password_reset_edge_proofs as p
    where p.created_at>=
          pg_catalog.statement_timestamp()-interval '2 minutes'
  ) then
    raise exception 'T3A_ROLLBACK_ACTIVE_EDGE_PROOF';
  end if;

  -- The SHARE locks above block new proof/lease INSERT/DELETE operations
  -- throughout preflight and reversal. Expired proofs are inert and are
  -- removed only after this full preflight succeeds. Any existing lease means
  -- an Auth side effect may be in flight or unresolved, so rollback must stop
  -- before removing its fence.
  if not exists (
       select 1
       from pg_catalog.pg_class as c
       where c.oid=v_lease_rel_oid
         and c.relkind='r'
         and c.relpersistence='p'
         and c.relowner=v_postgres_oid
         and c.relrowsecurity
         and c.relforcerowsecurity
         and not exists (
           select 1
           from pg_catalog.aclexplode(
             coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
           ) as acl
           where acl.grantee<>v_postgres_oid
         )
         and pg_catalog.md5(coalesce((
           select pg_catalog.string_agg(
             pg_catalog.format(
               '%s>%s:%s:%s',
               case when acl.grantee=0 then 'PUBLIC'
                    else pg_catalog.pg_get_userbyid(acl.grantee) end,
               pg_catalog.pg_get_userbyid(acl.grantor),
               acl.privilege_type,
               acl.is_grantable
             ),
             ',' order by acl.grantee,acl.grantor,
                          acl.privilege_type,acl.is_grantable
           )
           from pg_catalog.aclexplode(
             coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
           ) as acl
         ),''))='df15c22895181b78b4b8c47092a334a0'
     )
     or (
       select pg_catalog.count(*)
       from pg_catalog.pg_attribute as a
       where a.attrelid=v_lease_rel_oid
         and a.attnum>0 and not a.attisdropped
     )<>5
     or exists (
       select 1
       from pg_catalog.pg_attribute as a
       cross join lateral pg_catalog.aclexplode(a.attacl) as acl
       where a.attrelid=v_lease_rel_oid
         and a.attnum>0 and not a.attisdropped
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_lease_rel_oid and a.attname='lease_id'
         and a.atttypid='uuid'::regtype and a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_lease_rel_oid and a.attname='actor_user_id'
         and a.atttypid='uuid'::regtype and a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_lease_rel_oid and a.attname='target_user_id'
         and a.atttypid='uuid'::regtype and a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1 from pg_catalog.pg_attribute as a
       where a.attrelid=v_lease_rel_oid and a.attname='authority_time_id'
         and a.atttypid='uuid'::regtype and not a.attnotnull
         and not a.atthasdef
     )
     or not exists (
       select 1
       from pg_catalog.pg_attribute as a
       join pg_catalog.pg_attrdef as d
         on d.adrelid=a.attrelid and d.adnum=a.attnum
       where a.attrelid=v_lease_rel_oid and a.attname='created_at'
         and a.atttypid='timestamp with time zone'::regtype
         and a.attnotnull
         and pg_catalog.pg_get_expr(d.adbin,d.adrelid)=
             'statement_timestamp()'
     )
     or (
       select pg_catalog.count(*)
       from pg_catalog.pg_constraint as c
       where c.conrelid=v_lease_rel_oid
     )<>4
     or (
       select pg_catalog.count(*)
       from pg_catalog.pg_index as i
       where i.indrelid=v_lease_rel_oid
     )<>4
     or exists (
       select 1
       from pg_catalog.pg_constraint as c
       join pg_catalog.pg_index as i on i.indexrelid=c.conindid
       where c.conrelid=v_lease_rel_oid
         and c.contype in ('p','u')
         and (
           not i.indisunique or not i.indisvalid or not i.indisready
           or not i.indimmediate or i.indpred is not null
           or i.indexprs is not null or i.indnullsnotdistinct
           or i.indnkeyatts<>1 or i.indnatts<>1
         )
     )
     or not exists (
       select 1 from pg_catalog.pg_constraint as c
       where c.conrelid=v_lease_rel_oid
         and c.conname='t3_admin_password_reset_leases_pkey'
         and c.contype='p' and c.convalidated
         and not c.condeferrable and not c.condeferred
         and c.conkey=array[(
           select a.attnum from pg_catalog.pg_attribute as a
           where a.attrelid=v_lease_rel_oid and a.attname='lease_id'
         )]::smallint[]
     )
     or not exists (
       select 1 from pg_catalog.pg_constraint as c
       where c.conrelid=v_lease_rel_oid
         and c.conname='t3_admin_password_reset_leases_actor_user_id_key'
         and c.contype='u' and c.convalidated
         and not c.condeferrable and not c.condeferred
         and c.conkey=array[(
           select a.attnum from pg_catalog.pg_attribute as a
           where a.attrelid=v_lease_rel_oid and a.attname='actor_user_id'
         )]::smallint[]
     )
     or not exists (
       select 1 from pg_catalog.pg_constraint as c
       where c.conrelid=v_lease_rel_oid
         and c.conname='t3_admin_password_reset_leases_target_user_id_key'
         and c.contype='u' and c.convalidated
         and not c.condeferrable and not c.condeferred
         and c.conkey=array[(
           select a.attnum from pg_catalog.pg_attribute as a
           where a.attrelid=v_lease_rel_oid and a.attname='target_user_id'
         )]::smallint[]
     )
     or not exists (
       select 1 from pg_catalog.pg_constraint as c
       where c.conrelid=v_lease_rel_oid
         and c.conname='t3_admin_password_reset_leases_authority_time_id_key'
         and c.contype='u' and c.convalidated
         and not c.condeferrable and not c.condeferred
         and c.conkey=array[(
           select a.attnum from pg_catalog.pg_attribute as a
           where a.attrelid=v_lease_rel_oid and a.attname='authority_time_id'
         )]::smallint[]
     )
     or exists (
       select 1 from pg_catalog.pg_policy as p
       where p.polrelid=v_lease_rel_oid
     )
     or exists (
       select 1 from pg_catalog.pg_trigger as tg
       where tg.tgrelid=v_lease_rel_oid and not tg.tgisinternal
     )
     or exists (
       select 1 from pg_catalog.pg_rewrite as rw
       where rw.ev_class=v_lease_rel_oid
     )
     or pg_catalog.obj_description(v_lease_rel_oid,'pg_class') is distinct from
          'T3A-v3 durable authority fence; no time-based authorization or expiry' then
    raise exception 'T3A_ROLLBACK_LEASE_TABLE_DRIFT';
  end if;

  if exists (
    select 1 from public.t3_admin_password_reset_leases
  ) then
    raise exception 'T3A_ROLLBACK_ACTIVE_OR_UNRESOLVED_LEASE';
  end if;

  -- T3A pins the full authority-table ACLs. In this state the only baseline
  -- table privilege removed from service_role is TRUNCATE, because it bypasses
  -- row-level fencing triggers.
  for r in
    select *
    from (
      values
        ('admins','f680b340dd9a87a76fea61b681bf6f1e'),
        ('corretores','4cce675b8126424e9a455ee4c0569dde'),
        ('times','abbf21bbb402467692ba198f40d2026a')
    ) as expected(table_name,acl_md5)
  loop
    select pg_catalog.md5(coalesce(pg_catalog.string_agg(
             pg_catalog.format(
               '%s>%s:%s:%s',
               case when acl.grantee=0 then 'PUBLIC'
                    else pg_catalog.pg_get_userbyid(acl.grantee) end,
               pg_catalog.pg_get_userbyid(acl.grantor),
               acl.privilege_type,
               acl.is_grantable
             ),
             ',' order by acl.grantee,acl.grantor,
                          acl.privilege_type,acl.is_grantable
           ),''))
      into v_md5
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    cross join lateral pg_catalog.aclexplode(
      coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
    ) as acl
    where n.nspname='public' and c.relname=r.table_name;

    if v_md5 is distinct from r.acl_md5 then
      raise exception 'T3A_ROLLBACK_AUTHORITY_TABLE_ACL_DRIFT: %',
        r.table_name;
    end if;
  end loop;

  with column_acl_items as (
    select
      c.relname,
      a.attnum,
      a.attname,
      coalesce((
        select pg_catalog.string_agg(
          pg_catalog.format(
            '%s>%s:%s:%s',
            case when acl.grantee=0 then 'PUBLIC'
                 else pg_catalog.pg_get_userbyid(acl.grantee) end,
            pg_catalog.pg_get_userbyid(acl.grantor),
            acl.privilege_type,
            acl.is_grantable
          ),
          ',' order by acl.grantee,acl.grantor,
                       acl.privilege_type,acl.is_grantable
        )
        from pg_catalog.aclexplode(a.attacl) as acl
      ),'') as acl_text
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
  )
  select pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format(
             '%s.%s.%s|%s',relname,attnum,attname,acl_text
           ),
           E'\n' order by relname,attnum
         ))
    into v_column_acl_count,v_column_acl_md5
  from column_acl_items;

  if v_column_acl_count is distinct from 33
     or v_column_acl_md5 is distinct from
          'd475edbb63410c2ab4b4c2be55ac270c' then
    raise exception 'T3A_ROLLBACK_AUTHORITY_COLUMN_ACL_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_index as i
    join pg_catalog.pg_class as t on t.oid=i.indrelid
    join pg_catalog.pg_namespace as n on n.oid=t.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=t.oid
     and a.attname='user_id'
     and a.attnum>0
     and not a.attisdropped
    where n.nspname='public'
      and t.relname='corretores'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_USER_ID_UNIQUE_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_index as i
    join pg_catalog.pg_class as t on t.oid=i.indrelid
    join pg_catalog.pg_namespace as n on n.oid=t.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=t.oid
     and a.attname='user_id'
     and a.attnum>0
     and not a.attisdropped
    where n.nspname='public'
      and t.relname='admins'
      and i.indisunique and i.indisvalid and i.indisready
      and i.indimmediate and i.indpred is null and i.indexprs is null
      and i.indnkeyatts=1 and i.indnatts=1 and i.indkey[0]=a.attnum
  ) then
    raise exception 'T3A_ROLLBACK_ADMINS_USER_ID_UNIQUE_MISSING';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
      and (c.relkind is distinct from 'r'
           or c.relpersistence is distinct from 'p'
           or c.relowner is distinct from v_postgres_oid
           or c.relrowsecurity is distinct from true
           or c.relforcerowsecurity is distinct from true)
  ) then
    raise exception 'T3A_ROLLBACK_RLS_FORCE_DRIFT';
  end if;

  with audit_meta as (
    select c.relkind::text as relkind,
           c.relpersistence::text as relpersistence,
           pg_catalog.pg_get_userbyid(c.relowner) as owner_name,
           c.relrowsecurity,
           c.relforcerowsecurity
    from pg_catalog.pg_class as c
    where c.oid='public.audit_logs'::regclass
  ),
  audit_acl_items as (
    select
      case when acl.grantee=0 then 'PUBLIC'
           else pg_catalog.pg_get_userbyid(acl.grantee) end as grantee,
      pg_catalog.pg_get_userbyid(acl.grantor) as grantor,
      acl.privilege_type,
      acl.is_grantable
    from pg_catalog.pg_class as c
    cross join lateral pg_catalog.aclexplode(
      coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
    ) as acl
    where c.oid='public.audit_logs'::regclass
  ),
  audit_columns as (
    select a.attnum,
           a.attname,
           pg_catalog.format_type(a.atttypid,a.atttypmod) as data_type,
           a.attnotnull,
           coalesce(pg_catalog.pg_get_expr(d.adbin,d.adrelid),'') as default_expr,
           coalesce((
             select pg_catalog.string_agg(
               pg_catalog.format(
                 '%s>%s:%s:%s',
                 case when acl.grantee=0 then 'PUBLIC'
                      else pg_catalog.pg_get_userbyid(acl.grantee) end,
                 pg_catalog.pg_get_userbyid(acl.grantor),
                 acl.privilege_type,
                 acl.is_grantable
               ),
               ',' order by acl.grantee,acl.grantor,
                            acl.privilege_type,acl.is_grantable
             )
             from pg_catalog.aclexplode(a.attacl) as acl
           ),'') as acl_text
    from pg_catalog.pg_attribute as a
    left join pg_catalog.pg_attrdef as d
      on d.adrelid=a.attrelid and d.adnum=a.attnum
    where a.attrelid='public.audit_logs'::regclass
      and a.attnum>0 and not a.attisdropped
  ),
  audit_constraints as (
    select c.conname,
           c.contype::text as contype,
           pg_catalog.pg_get_constraintdef(c.oid,true) as definition
    from pg_catalog.pg_constraint as c
    where c.conrelid='public.audit_logs'::regclass
  ),
  audit_indexes as (
    select i.indexrelid::regclass::text as index_name,
           pg_catalog.pg_get_indexdef(i.indexrelid) as definition
    from pg_catalog.pg_index as i
    where i.indrelid='public.audit_logs'::regclass
  ),
  audit_policies as (
    select p.polname,
           p.polcmd,
           p.polpermissive,
           coalesce((
             select pg_catalog.string_agg(
               case when role_item.role_oid=0 then 'PUBLIC'
                    else pg_catalog.pg_get_userbyid(role_item.role_oid) end,
               ',' order by role_item.role_oid
             )
             from pg_catalog.unnest(p.polroles) as role_item(role_oid)
           ),'') as roles,
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'') as using_expr,
           coalesce(
             pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),''
           ) as check_expr
    from pg_catalog.pg_policy as p
    where p.polrelid='public.audit_logs'::regclass
  ),
  audit_parts as (
    select
      (select pg_catalog.concat_ws(
         '|','metadata',relkind,relpersistence,owner_name,
         relrowsecurity,relforcerowsecurity
       ) from audit_meta) as metadata_part,
      (select pg_catalog.concat_ws(
         '|','acl',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format(
             '%s>%s:%s:%s',grantee,grantor,privilege_type,is_grantable
           ),
           ',' order by grantee,grantor,privilege_type,is_grantable
         ))
       ) from audit_acl_items) as acl_part,
      (select pg_catalog.concat_ws(
         '|','columns',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format(
             '%s|%s|%s|%s|%s',
             attnum,attname,data_type,attnotnull,default_expr
           ),
           E'\n' order by attnum
         ))
       ) from audit_columns) as columns_part,
      (select pg_catalog.concat_ws(
         '|','column_acl',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format('%s.%s|%s',attnum,attname,acl_text),
           E'\n' order by attnum
         ))
       ) from audit_columns) as column_acl_part,
      (select pg_catalog.concat_ws(
         '|','constraints',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format('%s|%s|%s',conname,contype,definition),
           E'\n' order by conname
         ))
       ) from audit_constraints) as constraints_part,
      (select pg_catalog.concat_ws(
         '|','indexes',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format('%s|%s',index_name,definition),
           E'\n' order by index_name
         ))
       ) from audit_indexes) as indexes_part,
      (select pg_catalog.concat_ws(
         '|','policies',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.concat_ws(
             '|',polname,polcmd,polpermissive,roles,using_expr,check_expr
           ),
           E'\n' order by polname
         ))
       ) from audit_policies) as policies_part
  )
  select pg_catalog.md5(pg_catalog.concat_ws(
           E'\n',metadata_part,acl_part,columns_part,column_acl_part,
           constraints_part,indexes_part,policies_part
         ))
    into v_md5
  from audit_parts;

  if v_md5 is distinct from '1b1a381796f273b503cd4c41d34a3688' then
    raise exception 'T3A_ROLLBACK_AUDIT_RELATION_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
       v_service_role_oid,'public.audit_logs','SELECT'
     )
     or not pg_catalog.has_table_privilege(
       v_service_role_oid,'public.audit_logs','INSERT'
     )
     or not pg_catalog.has_table_privilege(
       v_service_role_oid,'public.audit_logs','UPDATE'
     )
     or not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','SELECT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','DELETE'
     )
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','DELETE') then
    raise exception 'T3A_ROLLBACK_AUDIT_EFFECTIVE_PRIVILEGE_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_issue_oid
      and p.proowner=v_postgres_oid
      and p.prokind='f'
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and p.prolang=(
        select l.oid from pg_catalog.pg_language as l
        where l.lanname='plpgsql'
      )
      and p.prorettype='uuid'::regtype
      and p.provolatile='v'
      and p.proparallel='u'
      and not p.proisstrict and not p.proleakproof and not p.proretset
      and p.procost=100 and p.prorows=0
      and p.pronargs=2 and p.pronargdefaults=0
      and p.proargdefaults is null and p.proallargtypes is null
      and p.proargmodes is null
      and p.proargnames=array[
        'p_actor_user_id','p_target_user_id'
      ]::text[]
      and p.provariadic=0::oid and p.prosupport=0::oid
      and pg_catalog.md5(p.prosrc)='87f8d7f0c96ce4ae52fed9e2bc4bdcdd'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v4 service-role Edge-presence proof only; never actor authority'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and pg_catalog.has_function_privilege(
            v_service_role_oid,p.oid,'EXECUTE'
          )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.grantee=0 and acl.privilege_type='EXECUTE'
      )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and (
            acl.grantee not in (v_postgres_oid,v_service_role_oid)
            or (acl.grantee=v_service_role_oid and acl.is_grantable)
          )
      )
  ) then
    raise exception 'T3A_ROLLBACK_EDGE_PROOF_FUNCTION_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_t3_oid
      and p.proowner=v_postgres_oid
      and p.prokind='f'
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and p.prolang=(
        select l.oid from pg_catalog.pg_language as l
        where l.lanname='plpgsql'
      )
      and p.prorettype='jsonb'::regtype
      and p.provolatile='v'
      and p.proparallel='u'
      and not p.proisstrict and not p.proleakproof and not p.proretset
      and p.procost=100 and p.prorows=0
      and p.pronargs=2 and p.pronargdefaults=0
      and p.proargdefaults is null and p.proallargtypes is null
      and p.proargmodes is null
      and p.proargnames=array[
        'p_target_user_id','p_edge_proof_id'
      ]::text[]
      and p.provariadic=0::oid and p.prosupport=0::oid
      and pg_catalog.md5(p.prosrc)='f9bd114c7eb77313e22861816b8a88f5'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v4 one-time Edge proof; auth.uid actor; durable fenced lease before Auth'
      and pg_catalog.has_function_privilege(
            v_authenticated_oid,p.oid,'EXECUTE'
          )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.grantee=0 and acl.privilege_type='EXECUTE'
      )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and (
            acl.grantee not in (v_postgres_oid,v_authenticated_oid)
            or (acl.grantee=v_authenticated_oid and acl.is_grantable)
          )
      )
  ) then
    raise exception 'T3A_ROLLBACK_T3_FUNCTION_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_release_oid
      and p.proowner=v_postgres_oid
      and p.prokind='f'
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and p.prolang=(
        select l.oid from pg_catalog.pg_language as l
        where l.lanname='plpgsql'
      )
      and p.prorettype='boolean'::regtype
      and p.provolatile='v'
      and p.proparallel='u'
      and not p.proisstrict and not p.proleakproof and not p.proretset
      and p.procost=100 and p.prorows=0
      and p.pronargs=3 and p.pronargdefaults=0
      and p.proargdefaults is null and p.proallargtypes is null
      and p.proargmodes is null
      and p.proargnames=array[
        'p_lease_id','p_actor_user_id','p_target_user_id'
      ]::text[]
      and p.provariadic=0::oid and p.prosupport=0::oid
      and pg_catalog.md5(p.prosrc)='a51c5b360c5d8a3684a97271460ec249'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v3 service-role operational release only; exact lease+actor+target required'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and pg_catalog.has_function_privilege(
            v_service_role_oid,p.oid,'EXECUTE'
          )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.grantee=0 and acl.privilege_type='EXECUTE'
      )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and (
            acl.grantee not in (v_postgres_oid,v_service_role_oid)
            or (acl.grantee=v_service_role_oid and acl.is_grantable)
          )
      )
  ) then
    raise exception 'T3A_ROLLBACK_RELEASE_FUNCTION_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_fence_oid
      and p.proowner=v_postgres_oid
      and p.prokind='f'
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and p.prolang=(
        select l.oid from pg_catalog.pg_language as l
        where l.lanname='plpgsql'
      )
      and p.prorettype='trigger'::regtype
      and p.provolatile='v'
      and p.proparallel='u'
      and not p.proisstrict and not p.proleakproof and not p.proretset
      and p.procost=100 and p.prorows=0
      and p.pronargs=0 and p.pronargdefaults=0
      and p.proargdefaults is null and p.proallargtypes is null
      and p.proargmodes is null and p.proargnames is null
      and p.provariadic=0::oid and p.prosupport=0::oid
      and pg_catalog.md5(p.prosrc)='bd611e591aa2d951b178853f78caaa65'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v3 durable actor/target/protected-admin/authority-team fencing'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and acl.grantee<>v_postgres_oid
      )
  ) then
    raise exception 'T3A_ROLLBACK_FENCE_FUNCTION_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=v_guard_oid
      and p.proowner=v_postgres_oid
      and p.prokind='f'
      and p.prosecdef is false
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and p.prolang=(
        select l.oid from pg_catalog.pg_language as l
        where l.lanname='plpgsql'
      )
      and p.prorettype='trigger'::regtype
      and p.provolatile='v'
      and p.proparallel='u'
      and not p.proisstrict and not p.proleakproof and not p.proretset
      and p.procost=100 and p.prorows=0
      and p.pronargs=0 and p.pronargdefaults=0
      and p.proargdefaults is null and p.proallargtypes is null
      and p.proargmodes is null and p.proargnames is null
      and p.provariadic=0::oid and p.prosupport=0::oid
      and pg_catalog.md5(p.prosrc)='951da8a6ac6e934828f06ab1513778fa'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'T3A-v3 exact leased password-state writer boundary; pre_t3a=99477024e337de5645dd042a30f8cf78'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.grantee=0 and acl.privilege_type='EXECUTE'
      )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and acl.grantee<>v_postgres_oid
      )
  ) then
    raise exception 'T3A_ROLLBACK_T1_DIRECT_GUARD_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid='public.t1_guard_corretores_authority_update()'::regprocedure
      and p.proowner=v_postgres_oid
      and p.prosecdef is false
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '5e69ae5cb6717f634d758cfd5c1cd7a6'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'F1-02-T1-v3|5e69ae5cb6717f634d758cfd5c1cd7a6'
      and not pg_catalog.has_function_privilege(
                v_authenticated_oid,p.oid,'EXECUTE'
              )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
      and not exists (
        select 1
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
        where acl.privilege_type='EXECUTE'
          and acl.grantee<>v_postgres_oid
      )
  ) then
    raise exception 'T3A_ROLLBACK_T1_AUTHORITY_GUARD_DRIFT';
  end if;

  -- Revalidate every unchanged helper/RPC that the restored pre-T3A boundary
  -- relies on. A body hash alone is not enough: owner, security mode, config and
  -- effective EXECUTE surface are part of the reviewed state.
  for r in
    select *
    from (
      values
        ('public.is_root()',
         '465c04885d729e63f1a1d4458fc2a1b0','search_path=public',true,true),
        ('public.is_admin_local()',
         '64b982da412f62c324aa2dde210eea0c','search_path=public',true,true),
        ('public.my_empresa_id()',
         '7d7a73d22953d547a103f89c7b676906','search_path=public',true,true),
        ('public.my_corretor_id()',
         'c8f243d33d42837c46236625a74c3fb7','search_path=public',true,true),
        ('public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)',
         '3cc5c9279ed4a2f40acc6c3750fc7cc4','search_path=pg_catalog',true,false),
        ('public.atualizar_status_corretor(uuid,boolean,boolean)',
         '563dc0b60766bda1aaf5ed9814a1c8cd','search_path=pg_catalog',true,false),
        ('public.marcar_senha_inicial_definida()',
         '2a7b28d4bb6342a99d075c4d3c49af4d','search_path=pg_catalog',true,false),
        ('public.redefinir_senha_corretor(uuid,text)',
         '2f1ff707c6ea94e0abf4ede0f2ec3835','search_path=public',false,true),
        ('public.audit_trail_log_corretores_critical_update()',
         '3fdaca39d55f348ca36f796023f3260b','search_path=public',true,true)
    ) as expected(signature,body_md5,config_entry,authenticated_execute,service_execute)
  loop
    if pg_catalog.to_regprocedure(r.signature) is null then
      raise exception 'T3A_ROLLBACK_REQUIRED_FUNCTION_MISSING: %',r.signature;
    end if;

    select p.proowner,
           p.prosecdef,
           p.proconfig,
           pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
           exists (
             select 1
             from pg_catalog.aclexplode(
               coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
             ) as acl
             where acl.grantee=0 and acl.privilege_type='EXECUTE'
           )
      into strict v_owner,v_definer,v_config,v_md5,v_public_execute
    from pg_catalog.pg_proc as p
    where p.oid=pg_catalog.to_regprocedure(r.signature);

    if v_owner is distinct from v_postgres_oid
       or v_definer is distinct from true
       or v_config is distinct from array[r.config_entry]::text[]
       or v_md5 is distinct from r.body_md5
       or pg_catalog.has_function_privilege(
            v_authenticated_oid,pg_catalog.to_regprocedure(r.signature),'EXECUTE'
          ) is distinct from r.authenticated_execute
       or pg_catalog.has_function_privilege(
            v_service_role_oid,pg_catalog.to_regprocedure(r.signature),'EXECUTE'
          ) is distinct from r.service_execute
       or pg_catalog.has_function_privilege(
            v_anon_oid,pg_catalog.to_regprocedure(r.signature),'EXECUTE'
          )
       or v_public_execute
       or exists (
         select 1
         from pg_catalog.pg_proc as p2
         cross join lateral pg_catalog.aclexplode(
           coalesce(p2.proacl,pg_catalog.acldefault('f',p2.proowner))
         ) as acl
         where p2.oid=pg_catalog.to_regprocedure(r.signature)
           and acl.privilege_type='EXECUTE'
           and acl.grantee not in (
             v_postgres_oid,v_authenticated_oid,v_service_role_oid
           )
       ) then
      raise exception 'T3A_ROLLBACK_REQUIRED_FUNCTION_DRIFT: %',r.signature;
    end if;
  end loop;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_authority_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.pg_get_triggerdef(tg.oid,true)=
        'CREATE TRIGGER trg_t1_guard_corretores_authority_update BEFORE UPDATE OF role, is_admin_local, is_gestor, empresa_id, time_id, user_id ON corretores FOR EACH ROW EXECUTE FUNCTION t1_guard_corretores_authority_update()'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        '68ec30b4d5014867c6db837d7d9db136'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|68ec30b4d5014867c6db837d7d9db136'
  ) then
    raise exception 'T3A_ROLLBACK_T1_AUTHORITY_TRIGGER_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.pg_get_triggerdef(tg.oid,true)=
        'CREATE TRIGGER trg_t1_guard_corretores_direct_compat_update BEFORE UPDATE OF ativo, apto_para_receber, must_change_password ON corretores FOR EACH ROW EXECUTE FUNCTION t1_guard_corretores_direct_compat_update()'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        'faf7f23f5e7c246a4500a7db9e518bc5'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|faf7f23f5e7c246a4500a7db9e518bc5'
  ) then
    raise exception 'T3A_ROLLBACK_T1_DIRECT_TRIGGER_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    join pg_catalog.pg_proc as p on p.oid=tg.tgfoid
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_audit_trail_corretores_critical_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.pg_get_triggerdef(tg.oid,true)=
        'CREATE TRIGGER trg_audit_trail_corretores_critical_update AFTER UPDATE ON corretores FOR EACH ROW EXECUTE FUNCTION audit_trail_log_corretores_critical_update()'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        '60e6c615f59d9196e0979d6e93d2ad94'
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '3fdaca39d55f348ca36f796023f3260b'
  ) then
    raise exception 'T3A_ROLLBACK_CRITICAL_AUDIT_DRIFT';
  end if;

  if (
       select pg_catalog.count(*)
       from pg_catalog.pg_trigger as tg
       join pg_catalog.pg_class as c on c.oid=tg.tgrelid
       join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
       where n.nspname='public'
         and c.relname in ('admins','corretores','times')
         and not tg.tgisinternal
     )<>7
     or not exists (
       select 1
       from pg_catalog.pg_trigger as tg
       join pg_catalog.pg_proc as p on p.oid=tg.tgfoid
       where tg.tgrelid='public.times'::regclass
         and tg.tgname='trg_audit_trail_times_governance'
         and not tg.tgisinternal and tg.tgenabled='O'
         and pg_catalog.pg_get_triggerdef(tg.oid,true)=
           'CREATE TRIGGER trg_audit_trail_times_governance AFTER INSERT OR DELETE OR UPDATE ON times FOR EACH ROW EXECUTE FUNCTION audit_trail_log_times_governance()'
         and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
           'dab63f610ccad2d8b947706603023793'
         and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
           'e6974ffdf3f9fe3187318a688a3b067e'
         and pg_catalog.obj_description(tg.oid,'pg_trigger') is null
     ) then
    raise exception 'T3A_ROLLBACK_AUTHORITY_TRIGGER_INVENTORY_DRIFT';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_rewrite as rw
    join pg_catalog.pg_class as c on c.oid=rw.ev_class
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
  ) then
    raise exception 'T3A_ROLLBACK_AUTHORITY_REWRITE_RULE_DRIFT';
  end if;

  if (
       select pg_catalog.count(*)
       from pg_catalog.pg_trigger as tg
       where tg.tgfoid=v_fence_oid and not tg.tgisinternal
     )<>3
     or not exists (
       select 1 from pg_catalog.pg_trigger as tg
       where tg.tgrelid='public.admins'::regclass
         and tg.tgname='trg_t3_fence_admin_password_reset_admins'
         and tg.tgfoid=v_fence_oid and not tg.tgisinternal
         and tg.tgenabled='O' and tg.tgtype=31 and tg.tgnargs=0
         and tg.tgqual is null
         and pg_catalog.obj_description(tg.oid,'pg_trigger')=
             'T3A-v3 durable authority fence'
     )
     or not exists (
       select 1 from pg_catalog.pg_trigger as tg
       where tg.tgrelid='public.corretores'::regclass
         and tg.tgname='trg_t3_fence_admin_password_reset_corretores'
         and tg.tgfoid=v_fence_oid and not tg.tgisinternal
         and tg.tgenabled='O' and tg.tgtype=31 and tg.tgnargs=0
         and tg.tgqual is null
         and pg_catalog.obj_description(tg.oid,'pg_trigger')=
             'T3A-v3 durable authority fence'
     )
     or not exists (
       select 1 from pg_catalog.pg_trigger as tg
       where tg.tgrelid='public.times'::regclass
         and tg.tgname='trg_t3_fence_admin_password_reset_times'
         and tg.tgfoid=v_fence_oid and not tg.tgisinternal
         and tg.tgenabled='O' and tg.tgtype=31 and tg.tgnargs=0
         and tg.tgqual is null
         and pg_catalog.obj_description(tg.oid,'pg_trigger')=
             'T3A-v3 durable authority fence'
     ) then
    raise exception 'T3A_ROLLBACK_FENCE_TRIGGER_DRIFT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    where p.oid=
      'public.t1_can_update_corretor_row_strict(uuid,uuid,text,boolean,boolean)'::regprocedure
      and p.proowner=v_postgres_oid
      and p.prosecdef is true
      and p.proconfig=array['search_path=pg_catalog']::text[]
      and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
        '3cc5c9279ed4a2f40acc6c3750fc7cc4'
      and pg_catalog.obj_description(p.oid,'pg_proc')=
        'F1-02-T1-v3|3cc5c9279ed4a2f40acc6c3750fc7cc4'
      and pg_catalog.has_function_privilege(
            v_authenticated_oid,p.oid,'EXECUTE'
          )
      and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
      and not pg_catalog.has_function_privilege(
                v_service_role_oid,p.oid,'EXECUTE'
              )
  ) then
    raise exception 'T3A_ROLLBACK_T1_POLICY_HELPER_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_policy as p
    where p.polrelid='public.corretores'::regclass and p.polcmd='w'
  ) <> 1
     or not exists (
       select 1
       from pg_catalog.pg_policy as p
       where p.polrelid='public.corretores'::regclass
         and p.polname='corretores_update'
         and p.polcmd='w'
         and p.polpermissive is true
         and p.polroles=array[0::oid]
         and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
           't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
         and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)=
           't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
     ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_POLICY_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_policy as p
    where p.polrelid='public.times'::regclass and p.polcmd='w'
  ) <> 1
     or not exists (
       select 1
       from pg_catalog.pg_policy as p
       where p.polrelid='public.times'::regclass
         and p.polname='times_update'
         and p.polcmd='w'
         and p.polpermissive is true
         and p.polroles=array[0::oid]
         and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
           '(is_root() OR (is_admin_local() AND (empresa_id = my_empresa_id())) OR (gestor_id = my_corretor_id()))'
         and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid) is null
     ) then
    raise exception 'T3A_ROLLBACK_TIMES_POLICY_DRIFT';
  end if;

  with policy_items as (
    select
      c.relname,
      p.polname,
      p.polcmd,
      p.polpermissive,
      coalesce((
        select pg_catalog.string_agg(
          case when role_item.role_oid=0 then 'PUBLIC'
               else pg_catalog.pg_get_userbyid(role_item.role_oid) end,
          ',' order by role_item.role_oid
        )
        from pg_catalog.unnest(p.polroles) as role_item(role_oid)
      ),'') as roles,
      coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'') as using_expr,
      coalesce(
        pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),''
      ) as check_expr
    from pg_catalog.pg_policy as p
    join pg_catalog.pg_class as c on c.oid=p.polrelid
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
  )
  select pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.concat_ws(
             '|',relname,polname,polcmd,polpermissive,roles,
             using_expr,check_expr
           ),
           E'\n' order by relname,polname
         ))
    into v_policy_count,v_policy_md5
  from policy_items;

  if v_policy_count is distinct from 7
     or v_policy_md5 is distinct from
          '1cb8f611f86778af0f60c78f2ffc70b0' then
    raise exception 'T3A_ROLLBACK_AUTHORITY_POLICY_INVENTORY_DRIFT';
  end if;

  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.is_root()'::regprocedure
     )) is distinct from '465c04885d729e63f1a1d4458fc2a1b0'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
          'public.is_admin_local()'::regprocedure
        )) is distinct from '64b982da412f62c324aa2dde210eea0c'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
          'public.my_empresa_id()'::regprocedure
        )) is distinct from '7d7a73d22953d547a103f89c7b676906'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
          'public.my_corretor_id()'::regprocedure
        )) is distinct from 'c8f243d33d42837c46236625a74c3fb7' then
    raise exception 'T3A_ROLLBACK_TIMES_HELPER_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','SELECT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','DELETE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','TRUNCATE')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','REFERENCES')
     or pg_catalog.has_table_privilege(v_authenticated_oid,'public.admins','TRIGGER')
     or exists (
       select 1
       from information_schema.column_privileges as cp
       where cp.table_schema='public'
         and cp.table_name='admins'
         and cp.grantee='authenticated'
         and cp.privilege_type in ('SELECT','INSERT','UPDATE')
     ) then
    raise exception 'T3A_ROLLBACK_ADMINS_PRIVILEGE_DRIFT';
  end if;

  if pg_catalog.has_table_privilege(v_anon_oid,'public.admins','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.admins','TRIGGER')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.corretores','TRIGGER')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','DELETE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','TRUNCATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','REFERENCES')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.times','TRIGGER') then
    raise exception 'T3A_ROLLBACK_ANON_TABLE_PRIVILEGE_DRIFT';
  end if;

  if exists (
    select 1
    from information_schema.column_privileges as cp
    where cp.table_schema='public'
      and cp.table_name in ('admins','corretores','times')
      and cp.grantee in ('anon','PUBLIC')
      and cp.privilege_type in ('SELECT','INSERT','UPDATE')
  ) then
    raise exception 'T3A_ROLLBACK_ANON_OR_PUBLIC_COLUMN_PRIVILEGE_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','SELECT'
     )
     or not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','DELETE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','TRUNCATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','REFERENCES'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.times','TRIGGER'
     ) then
    raise exception 'T3A_ROLLBACK_TIMES_PRIVILEGE_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','SELECT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','DELETE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','TRUNCATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','REFERENCES'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','TRIGGER'
     ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_TABLE_PRIVILEGE_DRIFT';
  end if;

  select pg_catalog.array_agg(a.attname::text order by a.attname::text)
    into v_update_columns
  from pg_catalog.pg_attribute as a
  where a.attrelid='public.corretores'::regclass
    and a.attnum>0
    and not a.attisdropped
    and pg_catalog.has_column_privilege(
          v_authenticated_oid,'public.corretores',a.attnum,'UPDATE'
        );

  if v_update_columns is distinct from
       array['apto_para_receber','ativo']::text[] then
    raise exception 'T3A_ROLLBACK_CORRETORES_GRANT_DRIFT';
  end if;

  if (
    select pg_catalog.count(*)
    from pg_catalog.pg_proc as p
    where lower(
      coalesce(p.prosrc,'') || E'\n' || coalesce(p.prosqlbody::text,'')
    ) like '%fechai.t3_admin_password_reset_context%'
      and p.oid in (v_t3_oid,v_guard_oid,v_fence_oid)
  ) <> 3
     or exists (
       select 1
       from pg_catalog.pg_proc as p
       where lower(
         coalesce(p.prosrc,'') || E'\n' || coalesce(p.prosqlbody::text,'')
       ) like '%fechai.t3_admin_password_reset_context%'
         and p.oid not in (v_t3_oid,v_guard_oid,v_fence_oid)
     ) then
    raise exception 'T3A_ROLLBACK_CONTEXT_KEY_COLLISION';
  end if;

  with routine_inventory as (
    select
      p.oid,
      pg_catalog.format(
        '%I.%I(%s)',n.nspname,p.proname,
        p.proargtypes::text
      ) as signature_key,
      pg_catalog.pg_get_userbyid(p.proowner) as owner_name,
      l.lanname as language_name,
      p.prokind,
      p.prosecdef,
      p.provolatile,
      p.proparallel,
      p.proleakproof,
      p.proisstrict,
      p.proretset,
      p.prorettype::text as return_type_oid,
      p.provariadic::text as variadic_type_oid,
      p.proargtypes::text as input_arg_type_oids,
      coalesce(p.proallargtypes::text,'') as all_arg_type_oids,
      coalesce(p.proargmodes::text,'') as arg_modes,
      coalesce(p.proargnames::text,'') as arg_names,
      p.pronargdefaults,
      coalesce(p.proargdefaults::text,'') as arg_defaults,
      p.prosupport::text as support_oid,
      p.procost::text as procost,
      p.prorows::text as prorows,
      coalesce(p.proconfig::text,'') as config_text,
      pg_catalog.md5(
        coalesce(p.prosrc,'') || E'\n' ||
        coalesce(p.probin,'') || E'\n' ||
        coalesce(p.prosqlbody::text,'')
      ) as implementation_md5,
      coalesce(
        pg_catalog.obj_description(p.oid,'pg_proc'),''
      ) as comment_text,
      coalesce((
        select pg_catalog.string_agg(
          pg_catalog.format(
            '%s>%s:%s:%s',
            case when acl.grantee=0 then 'PUBLIC'
                 else pg_catalog.pg_get_userbyid(acl.grantee) end,
            pg_catalog.pg_get_userbyid(acl.grantor),
            acl.privilege_type,
            acl.is_grantable
          ),
          ',' order by acl.grantee,acl.grantor,
                       acl.privilege_type,acl.is_grantable
        )
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
      ),'') as acl_text
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid=p.pronamespace
    join pg_catalog.pg_language as l on l.oid=p.prolang
    where p.prokind in ('f','p','a','w')
      and n.nspname not in ('pg_catalog','information_schema')
      and n.nspname not like 'pg_toast%'
      and n.nspname not like 'pg_temp_%'
      and n.nspname not like 'pg_toast_temp_%'
      and p.oid not in (
        v_guard_oid,v_t3_oid,v_issue_oid,v_release_oid,v_fence_oid
      )
  ), serialized as (
    select
      oid,
      signature_key,
      prokind,
      prosecdef,
      pg_catalog.concat_ws(
        '|',signature_key,owner_name,language_name,prokind,prosecdef,
        provolatile,proparallel,proleakproof,proisstrict,proretset,
        return_type_oid,variadic_type_oid,input_arg_type_oids,
        all_arg_type_oids,arg_modes,arg_names,pronargdefaults,arg_defaults,
        support_oid,procost,prorows,config_text,implementation_md5,
        comment_text,acl_text
      ) as item
    from routine_inventory
  )
  select
    pg_catalog.count(*),
    pg_catalog.md5(
      pg_catalog.string_agg(item,E'\n' order by signature_key)
    ),
    pg_catalog.count(*) filter (
      where prosecdef
        and pg_catalog.has_function_privilege(
          v_authenticated_oid,oid,'EXECUTE'
        )
    ),
    pg_catalog.md5(
      pg_catalog.string_agg(item,E'\n' order by signature_key)
        filter (
          where prosecdef
            and pg_catalog.has_function_privilege(
              v_authenticated_oid,oid,'EXECUTE'
            )
        )
    ),
    pg_catalog.count(*) filter (where prokind='a')
    into v_routine_count,
         v_routine_md5,
         v_authenticated_definer_count,
         v_authenticated_definer_md5,
         v_aggregate_count
  from serialized;

  if v_routine_count is distinct from 264
     or v_routine_md5 is distinct from
          'b1f0919df8a0acaca7bbea2b928b0ffe'
     or v_authenticated_definer_count is distinct from 122
     or v_authenticated_definer_md5 is distinct from
          '7faa376a403c69239d9606559cf9c2db'
     or v_aggregate_count is distinct from 0 then
    raise exception 'T3A_ROLLBACK_POSITIVE_ROUTINE_INVENTORY_DRIFT';
  end if;
end;
$rollback_preflight$;

-- The complete rollback preflight above proved the exact proof table, issuer,
-- consumer, ACL, TTL semantics and every other protected anchor. With all
-- writers blocked by the held SHARE lock, remove only proofs that the reviewed
-- prepare function can no longer consume. This makes abandoned proof cleanup
-- deterministic without touching any business row or weakening a live proof.
delete from public.t3_admin_password_reset_edge_proofs as p
 where p.created_at<
       pg_catalog.statement_timestamp()-interval '2 minutes';

do $rollback_proof_cleanup$
begin
  if exists (
    select 1 from public.t3_admin_password_reset_edge_proofs
  ) then
    raise exception 'T3A_ROLLBACK_EDGE_PROOF_NOT_EMPTY';
  end if;
end;
$rollback_proof_cleanup$;

-- =============================================================================
-- 2. RESTORE THE EXACT PRE-T3A T1 DIRECT-COMPATIBILITY GUARD
-- =============================================================================
create or replace function public.t1_guard_corretores_direct_compat_update()
returns trigger
language plpgsql
security invoker
set search_path=pg_catalog
as $function$
declare
  v_uid uuid:=auth.uid();
  v_actor_id uuid;
  v_empresa_id uuid;
  v_role text;
  v_ativo boolean;
  v_admin boolean;
  v_gestor boolean;
  v_root boolean:=false;
begin
  if new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber
     and new.must_change_password is not distinct from old.must_change_password then
    return new;
  end if;

  if v_uid is null then
    if current_user in ('postgres','service_role') then
      return new;
    end if;
    raise exception using errcode='42501',message='AUTH_REQUIRED';
  end if;

  perform 1
  from public.admins as a
  where a.user_id=v_uid
    and a.ativo is true
    and a.role='admin_global'
  for share;
  if found then v_root:=true; end if;

  begin
    select c.id,
           c.empresa_id,
           c.role,
           c.ativo,
           coalesce(c.is_admin_local,false),
           coalesce(c.is_gestor,false)
      into strict v_actor_id,
                  v_empresa_id,
                  v_role,
                  v_ativo,
                  v_admin,
                  v_gestor
    from public.corretores as c
    where c.user_id=v_uid
    for share;
  exception
    when no_data_found then
      if not v_root then
        raise exception using errcode='42501',message='ACTOR_PROFILE_NOT_FOUND';
      end if;
      v_actor_id:=null;
      v_empresa_id:=null;
      v_role:=null;
      v_ativo:=null;
      v_admin:=false;
      v_gestor:=false;
    when too_many_rows then
      raise exception using errcode='21000',message='ACTOR_PROFILE_AMBIGUOUS';
  end;

  if v_actor_id is not null and v_ativo is distinct from true then
    raise exception using errcode='42501',message='PROFILE_INACTIVE';
  end if;

  if old.user_id=v_uid
     and current_user='postgres'
     and old.must_change_password is true
     and new.must_change_password is false
     and new.ativo is not distinct from old.ativo
     and new.apto_para_receber is not distinct from old.apto_para_receber then
    return new;
  end if;

  if old.user_id=v_uid and new.ativo is distinct from old.ativo then
    raise exception using errcode='42501',message='SELF_ACTIVE_CHANGE_DENIED';
  end if;

  if old.user_id=v_uid
     and new.must_change_password is distinct from old.must_change_password then
    raise exception using
      errcode='42501',message='SELF_PASSWORD_STATE_CHANGE_DENIED';
  end if;

  if v_root then
    return new;
  end if;

  if v_role='admin_local'
     and v_admin is true
     and v_empresa_id is not null
     and old.empresa_id=v_empresa_id then
    return new;
  end if;

  if v_role='gestor'
     and v_gestor is true
     and v_admin is false then

    if new.ativo is distinct from old.ativo then
      raise exception using
        errcode='42501',message='ACTIVE_CHANGE_DENIED_FOR_MANAGER';
    end if;

    if new.must_change_password is distinct from old.must_change_password then
      raise exception using
        errcode='42501',message='PASSWORD_STATE_CHANGE_DENIED_FOR_MANAGER';
    end if;

    if v_empresa_id is null
       or old.empresa_id is distinct from v_empresa_id
       or old.role is distinct from 'corretor'
       or coalesce(old.is_admin_local,false) is true
       or coalesce(old.is_gestor,false) is true
       or old.time_id is null then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    perform 1
    from public.times as t
    where t.id=old.time_id
      and t.empresa_id=v_empresa_id
      and t.gestor_id=v_actor_id
      and t.ativo is true
    for share;

    if not found then
      raise exception using errcode='42501',message='TARGET_NOT_AUTHORIZED';
    end if;

    return new;
  end if;

  raise exception using errcode='42501',message='ACCESS_DENIED';
end;
$function$;

alter function public.t1_guard_corretores_direct_compat_update()
  owner to postgres;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from public;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from anon;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from authenticated;
revoke all on function public.t1_guard_corretores_direct_compat_update()
  from service_role;

comment on function public.t1_guard_corretores_direct_compat_update() is
'F1-02-T1-v3|99477024e337de5645dd042a30f8cf78';

-- The preflight proved the exact reviewed T3 objects and empty locked proof and
-- lease tables. Do not use IF EXISTS: absence or drift is a blocker to surface.
drop trigger trg_t3_fence_admin_password_reset_admins on public.admins;
drop trigger trg_t3_fence_admin_password_reset_corretores on public.corretores;
drop trigger trg_t3_fence_admin_password_reset_times on public.times;

drop function public.t3_guard_admin_password_reset_lease();
drop function public.t3_prepare_admin_password_reset(uuid,uuid);
drop function public.t3_issue_admin_password_reset_edge_proof(uuid,uuid);
drop function public.t3_release_admin_password_reset_lease(uuid,uuid,uuid);
drop table public.t3_admin_password_reset_edge_proofs;
drop table public.t3_admin_password_reset_leases;

grant update (must_change_password)
  on table public.corretores to authenticated;

grant insert on table public.audit_logs to authenticated;

grant truncate on table public.admins, public.corretores, public.times
  to service_role;

-- =============================================================================
-- 3. EXACT POST-ROLLBACK VERIFICATION
-- =============================================================================
do $postrollback$
declare
  v_postgres_oid oid:=pg_catalog.to_regrole('postgres');
  v_authenticated_oid oid:=pg_catalog.to_regrole('authenticated');
  v_anon_oid oid:=pg_catalog.to_regrole('anon');
  v_service_role_oid oid:=pg_catalog.to_regrole('service_role');
  v_authenticator_oid oid:=pg_catalog.to_regrole('authenticator');
  v_database_owner_oid oid:=pg_catalog.to_regrole('pg_database_owner');
  v_guard_oid oid:=pg_catalog.to_regprocedure(
    'public.t1_guard_corretores_direct_compat_update()'
  );
  v_update_columns text[];
  v_routine_count bigint;
  v_routine_md5 text;
  v_authenticated_definer_count bigint;
  v_authenticated_definer_md5 text;
  v_aggregate_count bigint;
  v_membership_count bigint;
  v_membership_md5 text;
  v_schema_acl_count bigint;
  v_schema_acl_md5 text;
  v_table_acl_md5 text;
  v_column_acl_count bigint;
  v_column_acl_md5 text;
  v_policy_count bigint;
  v_policy_md5 text;
  r record;
begin
  if v_postgres_oid is null
     or v_authenticated_oid is null
     or v_anon_oid is null
     or v_service_role_oid is null
     or v_authenticator_oid is null
     or v_database_owner_oid is null
     or pg_catalog.to_regclass('public.audit_logs') is null then
    raise exception 'T3A_ROLLBACK_POST_REQUIRED_ROLE_MISSING';
  end if;

  if pg_catalog.to_regprocedure(
       'public.t3_prepare_admin_password_reset(uuid)'
     ) is not null
     or pg_catalog.to_regprocedure(
          'public.t3_prepare_admin_password_reset(uuid,uuid)'
        ) is not null
     or pg_catalog.to_regprocedure(
          'public.t3_issue_admin_password_reset_edge_proof(uuid,uuid)'
        ) is not null
     or pg_catalog.to_regprocedure(
          'public.t3_release_admin_password_reset_lease(uuid,uuid,uuid)'
        ) is not null
     or pg_catalog.to_regprocedure(
          'public.t3_guard_admin_password_reset_lease()'
        ) is not null
     or pg_catalog.to_regclass(
          'public.t3_admin_password_reset_leases'
        ) is not null
     or pg_catalog.to_regclass(
          'public.t3_admin_password_reset_edge_proofs'
        ) is not null
     or exists (
       select 1
       from pg_catalog.pg_trigger as tg
       where not tg.tgisinternal
         and tg.tgname in (
           'trg_t3_fence_admin_password_reset_admins',
           'trg_t3_fence_admin_password_reset_corretores',
           'trg_t3_fence_admin_password_reset_times'
         )
  ) then
    raise exception 'T3A_ROLLBACK_T3_OBJECT_STILL_PRESENT';
  end if;

  if not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_postgres_oid
         and not role_row.rolsuper and role_row.rolinherit and role_row.rolcreaterole
         and role_row.rolcreatedb and role_row.rolcanlogin and role_row.rolreplication
         and role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_authenticated_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_anon_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_service_role_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_authenticator_oid
         and not role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or not exists (
       select 1 from pg_catalog.pg_roles as role_row
       where role_row.oid=v_database_owner_oid
         and role_row.rolinherit and not role_row.rolsuper and not role_row.rolcreaterole
         and not role_row.rolcreatedb and not role_row.rolcanlogin
         and not role_row.rolreplication and not role_row.rolbypassrls
     )
     or pg_catalog.has_schema_privilege(
          v_authenticated_oid,'public','CREATE'
        )
     or pg_catalog.has_schema_privilege(v_anon_oid,'public','CREATE')
     or pg_catalog.has_schema_privilege(
          v_service_role_oid,'public','CREATE'
        )
     or not pg_catalog.has_schema_privilege(
              v_authenticated_oid,'public','USAGE'
            )
     or not pg_catalog.has_schema_privilege(v_anon_oid,'public','USAGE')
     or not pg_catalog.has_schema_privilege(
              v_service_role_oid,'public','USAGE'
            ) then
    raise exception 'T3A_ROLLBACK_BASELINE_ROLE_OR_SCHEMA_DRIFT';
  end if;

  with membership_items as (
    select pg_catalog.concat_ws(
             '|',granted.rolname,member_role.rolname,grantor.rolname,
             m.admin_option::text,m.inherit_option::text,m.set_option::text
           ) as item
    from pg_catalog.pg_auth_members as m
    join pg_catalog.pg_roles as granted on granted.oid=m.roleid
    join pg_catalog.pg_roles as member_role on member_role.oid=m.member
    join pg_catalog.pg_roles as grantor on grantor.oid=m.grantor
  )
  select pg_catalog.count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           item,E'\n' order by item
         ),''))
    into v_membership_count,v_membership_md5
  from membership_items;

  if v_membership_count is distinct from 21
     or v_membership_md5 is distinct from
          'fb803a204209bc71074a1eee7b57944e' then
    raise exception 'T3A_ROLLBACK_POST_ROLE_MEMBERSHIP_GRAPH_DRIFT';
  end if;

  if not exists (
       select 1
       from pg_catalog.pg_database as d
       where d.datname=pg_catalog.current_database()
         and d.datdba=v_postgres_oid
     )
     or not exists (
       select 1
       from pg_catalog.pg_namespace as n
       where n.nspname='public'
         and n.nspowner=v_database_owner_oid
     ) then
    raise exception 'T3A_ROLLBACK_POST_PUBLIC_SCHEMA_OWNER_DRIFT';
  end if;

  with schema_acl_items as (
    select pg_catalog.format(
             '%s>%s:%s:%s',
             case when acl.grantee=0 then 'PUBLIC'
                  else pg_catalog.pg_get_userbyid(acl.grantee) end,
             pg_catalog.pg_get_userbyid(acl.grantor),
             acl.privilege_type,
             acl.is_grantable
           ) as item
    from pg_catalog.pg_namespace as n
    cross join lateral pg_catalog.aclexplode(
      coalesce(n.nspacl,pg_catalog.acldefault('n',n.nspowner))
    ) as acl
    where n.nspname='public'
  )
  select pg_catalog.count(*),
         pg_catalog.md5(coalesce(pg_catalog.string_agg(
           item,E'\n' order by item
         ),''))
    into v_schema_acl_count,v_schema_acl_md5
  from schema_acl_items;

  if v_schema_acl_count is distinct from 7
     or v_schema_acl_md5 is distinct from
          'e2ad94b6bfb9b0cb8c4980459fd55a6e' then
    raise exception 'T3A_ROLLBACK_POST_PUBLIC_SCHEMA_ACL_DRIFT';
  end if;

  if v_guard_oid is null
     or not exists (
       select 1
       from pg_catalog.pg_proc as p
       where p.oid=v_guard_oid
         and p.proowner=v_postgres_oid
         and p.prokind='f'
         and p.prosecdef is false
         and p.proconfig=array['search_path=pg_catalog']::text[]
         and p.prorettype='trigger'::regtype
         and p.provolatile='v' and p.proparallel='u'
         and not p.proisstrict and not p.proleakproof and not p.proretset
         and p.procost=100 and p.prorows=0
         and p.pronargs=0 and p.pronargdefaults=0
         and p.proargdefaults is null and p.proallargtypes is null
         and p.proargmodes is null and p.proargnames is null
         and p.provariadic=0::oid and p.prosupport=0::oid
         and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
           '99477024e337de5645dd042a30f8cf78'
         and pg_catalog.obj_description(p.oid,'pg_proc')=
           'F1-02-T1-v3|99477024e337de5645dd042a30f8cf78'
         and not pg_catalog.has_function_privilege(
                   v_authenticated_oid,p.oid,'EXECUTE'
                 )
         and not pg_catalog.has_function_privilege(v_anon_oid,p.oid,'EXECUTE')
         and not pg_catalog.has_function_privilege(
                   v_service_role_oid,p.oid,'EXECUTE'
                 )
         and not exists (
           select 1
           from pg_catalog.aclexplode(
             coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
           ) as acl
           where acl.privilege_type='EXECUTE'
             and acl.grantee<>v_postgres_oid
         )
     ) then
    raise exception 'T3A_ROLLBACK_PRE_T3_GUARD_NOT_RESTORED';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as tg
    where tg.tgrelid='public.corretores'::regclass
      and tg.tgname='trg_t1_guard_corretores_direct_compat_update'
      and not tg.tgisinternal
      and tg.tgenabled='O'
      and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
        'faf7f23f5e7c246a4500a7db9e518bc5'
      and pg_catalog.obj_description(tg.oid,'pg_trigger')=
        'F1-02-T1-v3|faf7f23f5e7c246a4500a7db9e518bc5'
  ) then
    raise exception 'T3A_ROLLBACK_T1_TRIGGER_DRIFT';
  end if;

  if (
       select pg_catalog.count(*)
       from pg_catalog.pg_trigger as tg
       join pg_catalog.pg_class as c on c.oid=tg.tgrelid
       join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
       where n.nspname='public'
         and c.relname in ('admins','corretores','times')
         and not tg.tgisinternal
     )<>4
     or not exists (
       select 1
       from pg_catalog.pg_trigger as tg
       where tg.tgrelid='public.corretores'::regclass
         and tg.tgname='trg_t1_guard_corretores_authority_update'
         and not tg.tgisinternal and tg.tgenabled='O'
         and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
           '68ec30b4d5014867c6db837d7d9db136'
     )
     or not exists (
       select 1
       from pg_catalog.pg_trigger as tg
       join pg_catalog.pg_proc as p on p.oid=tg.tgfoid
       where tg.tgrelid='public.corretores'::regclass
         and tg.tgname='trg_audit_trail_corretores_critical_update'
         and not tg.tgisinternal and tg.tgenabled='O'
         and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
           '60e6c615f59d9196e0979d6e93d2ad94'
         and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
           '3fdaca39d55f348ca36f796023f3260b'
     )
     or not exists (
       select 1
       from pg_catalog.pg_trigger as tg
       join pg_catalog.pg_proc as p on p.oid=tg.tgfoid
       where tg.tgrelid='public.times'::regclass
         and tg.tgname='trg_audit_trail_times_governance'
         and not tg.tgisinternal and tg.tgenabled='O'
         and pg_catalog.md5(pg_catalog.pg_get_triggerdef(tg.oid,true))=
           'dab63f610ccad2d8b947706603023793'
         and pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))=
           'e6974ffdf3f9fe3187318a688a3b067e'
     ) then
    raise exception 'T3A_ROLLBACK_BASELINE_TRIGGER_INVENTORY_NOT_RESTORED';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_rewrite as rw
    join pg_catalog.pg_class as c on c.oid=rw.ev_class
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
  ) then
    raise exception 'T3A_ROLLBACK_BASELINE_REWRITE_RULE_DRIFT';
  end if;

  if not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','SELECT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','DELETE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','TRUNCATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','REFERENCES'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.corretores','TRIGGER'
     ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_TABLE_PRIVILEGE_DRIFT';
  end if;

  select pg_catalog.array_agg(a.attname::text order by a.attname::text)
    into v_update_columns
  from pg_catalog.pg_attribute as a
  where a.attrelid='public.corretores'::regclass
    and a.attnum>0
    and not a.attisdropped
    and pg_catalog.has_column_privilege(
          v_authenticated_oid,'public.corretores',a.attnum,'UPDATE'
        );

  if v_update_columns is distinct from
       array['apto_para_receber','ativo','must_change_password']::text[] then
    raise exception 'T3A_ROLLBACK_COMPAT_GRANT_NOT_RESTORED_EXACTLY';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
      and (c.relkind is distinct from 'r'
           or c.relpersistence is distinct from 'p'
           or c.relowner is distinct from v_postgres_oid
           or c.relrowsecurity is distinct from true
           or c.relforcerowsecurity is distinct from true)
  ) then
    raise exception 'T3A_ROLLBACK_AUTHORITY_TABLE_METADATA_NOT_RESTORED';
  end if;

  with audit_meta as (
    select c.relkind::text as relkind,
           c.relpersistence::text as relpersistence,
           pg_catalog.pg_get_userbyid(c.relowner) as owner_name,
           c.relrowsecurity,
           c.relforcerowsecurity
    from pg_catalog.pg_class as c
    where c.oid='public.audit_logs'::regclass
  ),
  audit_acl_items as (
    select
      case when acl.grantee=0 then 'PUBLIC'
           else pg_catalog.pg_get_userbyid(acl.grantee) end as grantee,
      pg_catalog.pg_get_userbyid(acl.grantor) as grantor,
      acl.privilege_type,
      acl.is_grantable
    from pg_catalog.pg_class as c
    cross join lateral pg_catalog.aclexplode(
      coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
    ) as acl
    where c.oid='public.audit_logs'::regclass
  ),
  audit_columns as (
    select a.attnum,
           a.attname,
           pg_catalog.format_type(a.atttypid,a.atttypmod) as data_type,
           a.attnotnull,
           coalesce(pg_catalog.pg_get_expr(d.adbin,d.adrelid),'') as default_expr,
           coalesce((
             select pg_catalog.string_agg(
               pg_catalog.format(
                 '%s>%s:%s:%s',
                 case when acl.grantee=0 then 'PUBLIC'
                      else pg_catalog.pg_get_userbyid(acl.grantee) end,
                 pg_catalog.pg_get_userbyid(acl.grantor),
                 acl.privilege_type,
                 acl.is_grantable
               ),
               ',' order by acl.grantee,acl.grantor,
                            acl.privilege_type,acl.is_grantable
             )
             from pg_catalog.aclexplode(a.attacl) as acl
           ),'') as acl_text
    from pg_catalog.pg_attribute as a
    left join pg_catalog.pg_attrdef as d
      on d.adrelid=a.attrelid and d.adnum=a.attnum
    where a.attrelid='public.audit_logs'::regclass
      and a.attnum>0 and not a.attisdropped
  ),
  audit_constraints as (
    select c.conname,
           c.contype::text as contype,
           pg_catalog.pg_get_constraintdef(c.oid,true) as definition
    from pg_catalog.pg_constraint as c
    where c.conrelid='public.audit_logs'::regclass
  ),
  audit_indexes as (
    select i.indexrelid::regclass::text as index_name,
           pg_catalog.pg_get_indexdef(i.indexrelid) as definition
    from pg_catalog.pg_index as i
    where i.indrelid='public.audit_logs'::regclass
  ),
  audit_policies as (
    select p.polname,
           p.polcmd,
           p.polpermissive,
           coalesce((
             select pg_catalog.string_agg(
               case when role_item.role_oid=0 then 'PUBLIC'
                    else pg_catalog.pg_get_userbyid(role_item.role_oid) end,
               ',' order by role_item.role_oid
             )
             from pg_catalog.unnest(p.polroles) as role_item(role_oid)
           ),'') as roles,
           coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'') as using_expr,
           coalesce(
             pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),''
           ) as check_expr
    from pg_catalog.pg_policy as p
    where p.polrelid='public.audit_logs'::regclass
  ),
  audit_parts as (
    select
      (select pg_catalog.concat_ws(
         '|','metadata',relkind,relpersistence,owner_name,
         relrowsecurity,relforcerowsecurity
       ) from audit_meta) as metadata_part,
      (select pg_catalog.concat_ws(
         '|','acl',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format(
             '%s>%s:%s:%s',grantee,grantor,privilege_type,is_grantable
           ),
           ',' order by grantee,grantor,privilege_type,is_grantable
         ))
       ) from audit_acl_items) as acl_part,
      (select pg_catalog.concat_ws(
         '|','columns',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format(
             '%s|%s|%s|%s|%s',
             attnum,attname,data_type,attnotnull,default_expr
           ),
           E'\n' order by attnum
         ))
       ) from audit_columns) as columns_part,
      (select pg_catalog.concat_ws(
         '|','column_acl',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format('%s.%s|%s',attnum,attname,acl_text),
           E'\n' order by attnum
         ))
       ) from audit_columns) as column_acl_part,
      (select pg_catalog.concat_ws(
         '|','constraints',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format('%s|%s|%s',conname,contype,definition),
           E'\n' order by conname
         ))
       ) from audit_constraints) as constraints_part,
      (select pg_catalog.concat_ws(
         '|','indexes',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format('%s|%s',index_name,definition),
           E'\n' order by index_name
         ))
       ) from audit_indexes) as indexes_part,
      (select pg_catalog.concat_ws(
         '|','policies',pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.concat_ws(
             '|',polname,polcmd,polpermissive,roles,using_expr,check_expr
           ),
           E'\n' order by polname
         ))
       ) from audit_policies) as policies_part
  )
  select pg_catalog.md5(pg_catalog.concat_ws(
           E'\n',metadata_part,acl_part,columns_part,column_acl_part,
           constraints_part,indexes_part,policies_part
         ))
    into v_table_acl_md5
  from audit_parts;

  if v_table_acl_md5 is distinct from
       '5d3b70257c57f5956032e83131effabb' then
    raise exception 'T3A_ROLLBACK_AUDIT_BASELINE_NOT_RESTORED';
  end if;

  if not pg_catalog.has_table_privilege(
       v_service_role_oid,'public.audit_logs','SELECT'
     )
     or not pg_catalog.has_table_privilege(
       v_service_role_oid,'public.audit_logs','INSERT'
     )
     or not pg_catalog.has_table_privilege(
       v_service_role_oid,'public.audit_logs','UPDATE'
     )
     or not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','SELECT'
     )
     or not pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','INSERT'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','UPDATE'
     )
     or pg_catalog.has_table_privilege(
       v_authenticated_oid,'public.audit_logs','DELETE'
     )
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','SELECT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','INSERT')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','UPDATE')
     or pg_catalog.has_table_privilege(v_anon_oid,'public.audit_logs','DELETE') then
    raise exception 'T3A_ROLLBACK_AUDIT_BASELINE_PRIVILEGE_DRIFT';
  end if;

  for r in
    select *
    from (
      values
        ('admins','b0e2ac3625f075350c4b2621a8429dd7'),
        ('corretores','c05095bb90a0c041ba5bbe82cea27702'),
        ('times','82f04ab162741d5ab0e8cd323f083ec8')
    ) as expected(table_name,acl_md5)
  loop
    select pg_catalog.md5(coalesce(pg_catalog.string_agg(
             pg_catalog.format(
               '%s>%s:%s:%s',
               case when acl.grantee=0 then 'PUBLIC'
                    else pg_catalog.pg_get_userbyid(acl.grantee) end,
               pg_catalog.pg_get_userbyid(acl.grantor),
               acl.privilege_type,
               acl.is_grantable
             ),
             ',' order by acl.grantee,acl.grantor,
                          acl.privilege_type,acl.is_grantable
           ),''))
      into v_table_acl_md5
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    cross join lateral pg_catalog.aclexplode(
      coalesce(c.relacl,pg_catalog.acldefault('r',c.relowner))
    ) as acl
    where n.nspname='public' and c.relname=r.table_name;

    if v_table_acl_md5 is distinct from r.acl_md5 then
      raise exception 'T3A_ROLLBACK_BASELINE_TABLE_ACL_NOT_RESTORED: %',
        r.table_name;
    end if;
  end loop;

  with column_acl_items as (
    select
      c.relname,
      a.attnum,
      a.attname,
      coalesce((
        select pg_catalog.string_agg(
          pg_catalog.format(
            '%s>%s:%s:%s',
            case when acl.grantee=0 then 'PUBLIC'
                 else pg_catalog.pg_get_userbyid(acl.grantee) end,
            pg_catalog.pg_get_userbyid(acl.grantor),
            acl.privilege_type,
            acl.is_grantable
          ),
          ',' order by acl.grantee,acl.grantor,
                       acl.privilege_type,acl.is_grantable
        )
        from pg_catalog.aclexplode(a.attacl) as acl
      ),'') as acl_text
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    join pg_catalog.pg_attribute as a
      on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
  )
  select pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.format(
             '%s.%s.%s|%s',relname,attnum,attname,acl_text
           ),
           E'\n' order by relname,attnum
         ))
    into v_column_acl_count,v_column_acl_md5
  from column_acl_items;

  if v_column_acl_count is distinct from 33
     or v_column_acl_md5 is distinct from
          '3fa731261b3d39ca5d046fd548c1bf53' then
    raise exception 'T3A_ROLLBACK_BASELINE_COLUMN_ACL_NOT_RESTORED';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    where lower(
      coalesce(p.prosrc,'') || E'\n' || coalesce(p.prosqlbody::text,'')
    ) like '%fechai.t3_admin_password_reset_context%'
  ) then
    raise exception 'T3A_ROLLBACK_CONTEXT_KEY_STILL_PRESENT';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_policy as p
    where p.polrelid='public.corretores'::regclass
      and p.polname='corretores_update'
      and p.polcmd='w'
      and p.polpermissive is true
      and p.polroles=array[0::oid]
      and pg_catalog.pg_get_expr(p.polqual,p.polrelid)=
        't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
      and pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid)=
        't1_can_update_corretor_row_strict(empresa_id, time_id, role, is_admin_local, is_gestor)'
  ) then
    raise exception 'T3A_ROLLBACK_CORRETORES_POLICY_DRIFT';
  end if;

  with policy_items as (
    select
      c.relname,
      p.polname,
      p.polcmd,
      p.polpermissive,
      coalesce((
        select pg_catalog.string_agg(
          case when role_item.role_oid=0 then 'PUBLIC'
               else pg_catalog.pg_get_userbyid(role_item.role_oid) end,
          ',' order by role_item.role_oid
        )
        from pg_catalog.unnest(p.polroles) as role_item(role_oid)
      ),'') as roles,
      coalesce(pg_catalog.pg_get_expr(p.polqual,p.polrelid),'') as using_expr,
      coalesce(
        pg_catalog.pg_get_expr(p.polwithcheck,p.polrelid),''
      ) as check_expr
    from pg_catalog.pg_policy as p
    join pg_catalog.pg_class as c on c.oid=p.polrelid
    join pg_catalog.pg_namespace as n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname in ('admins','corretores','times')
  )
  select pg_catalog.count(*),
         pg_catalog.md5(pg_catalog.string_agg(
           pg_catalog.concat_ws(
             '|',relname,polname,polcmd,polpermissive,roles,
             using_expr,check_expr
           ),
           E'\n' order by relname,polname
         ))
    into v_policy_count,v_policy_md5
  from policy_items;

  if v_policy_count is distinct from 7
     or v_policy_md5 is distinct from
          '1cb8f611f86778af0f60c78f2ffc70b0' then
    raise exception 'T3A_ROLLBACK_BASELINE_POLICY_INVENTORY_DRIFT';
  end if;

  with routine_inventory as (
    select
      p.oid,
      pg_catalog.format(
        '%I.%I(%s)',n.nspname,p.proname,
        p.proargtypes::text
      ) as signature_key,
      pg_catalog.pg_get_userbyid(p.proowner) as owner_name,
      l.lanname as language_name,
      p.prokind,
      p.prosecdef,
      p.provolatile,
      p.proparallel,
      p.proleakproof,
      p.proisstrict,
      p.proretset,
      p.prorettype::text as return_type_oid,
      p.provariadic::text as variadic_type_oid,
      p.proargtypes::text as input_arg_type_oids,
      coalesce(p.proallargtypes::text,'') as all_arg_type_oids,
      coalesce(p.proargmodes::text,'') as arg_modes,
      coalesce(p.proargnames::text,'') as arg_names,
      p.pronargdefaults,
      coalesce(p.proargdefaults::text,'') as arg_defaults,
      p.prosupport::text as support_oid,
      p.procost::text as procost,
      p.prorows::text as prorows,
      coalesce(p.proconfig::text,'') as config_text,
      pg_catalog.md5(
        coalesce(p.prosrc,'') || E'\n' ||
        coalesce(p.probin,'') || E'\n' ||
        coalesce(p.prosqlbody::text,'')
      ) as implementation_md5,
      coalesce(
        pg_catalog.obj_description(p.oid,'pg_proc'),''
      ) as comment_text,
      coalesce((
        select pg_catalog.string_agg(
          pg_catalog.format(
            '%s>%s:%s:%s',
            case when acl.grantee=0 then 'PUBLIC'
                 else pg_catalog.pg_get_userbyid(acl.grantee) end,
            pg_catalog.pg_get_userbyid(acl.grantor),
            acl.privilege_type,
            acl.is_grantable
          ),
          ',' order by acl.grantee,acl.grantor,
                       acl.privilege_type,acl.is_grantable
        )
        from pg_catalog.aclexplode(
          coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))
        ) as acl
      ),'') as acl_text
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid=p.pronamespace
    join pg_catalog.pg_language as l on l.oid=p.prolang
    where p.prokind in ('f','p','a','w')
      and n.nspname not in ('pg_catalog','information_schema')
      and n.nspname not like 'pg_toast%'
      and n.nspname not like 'pg_temp_%'
      and n.nspname not like 'pg_toast_temp_%'
      and p.oid<>v_guard_oid
  ), serialized as (
    select
      oid,
      signature_key,
      prokind,
      prosecdef,
      pg_catalog.concat_ws(
        '|',signature_key,owner_name,language_name,prokind,prosecdef,
        provolatile,proparallel,proleakproof,proisstrict,proretset,
        return_type_oid,variadic_type_oid,input_arg_type_oids,
        all_arg_type_oids,arg_modes,arg_names,pronargdefaults,arg_defaults,
        support_oid,procost,prorows,config_text,implementation_md5,
        comment_text,acl_text
      ) as item
    from routine_inventory
  )
  select
    pg_catalog.count(*),
    pg_catalog.md5(
      pg_catalog.string_agg(item,E'\n' order by signature_key)
    ),
    pg_catalog.count(*) filter (
      where prosecdef
        and pg_catalog.has_function_privilege(
          v_authenticated_oid,oid,'EXECUTE'
        )
    ),
    pg_catalog.md5(
      pg_catalog.string_agg(item,E'\n' order by signature_key)
        filter (
          where prosecdef
            and pg_catalog.has_function_privilege(
              v_authenticated_oid,oid,'EXECUTE'
            )
        )
    ),
    pg_catalog.count(*) filter (where prokind='a')
    into v_routine_count,
         v_routine_md5,
         v_authenticated_definer_count,
         v_authenticated_definer_md5,
         v_aggregate_count
  from serialized;

  if v_routine_count is distinct from 264
     or v_routine_md5 is distinct from
          'b1f0919df8a0acaca7bbea2b928b0ffe'
     or v_authenticated_definer_count is distinct from 122
     or v_authenticated_definer_md5 is distinct from
          '7faa376a403c69239d9606559cf9c2db'
     or v_aggregate_count is distinct from 0 then
    raise exception 'T3A_ROLLBACK_POST_POSITIVE_ROUTINE_INVENTORY_DRIFT';
  end if;
end;
$postrollback$;

commit;
