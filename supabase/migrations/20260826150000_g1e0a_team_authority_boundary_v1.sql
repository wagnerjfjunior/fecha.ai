-- FECH.AI — G1E0-A1 Team Creation Authority Boundary v1
-- Scope: public.times + public.criar_time(text, uuid)
-- Primary risk: authenticated clients retain direct structural UPDATE on times while criar_time is not executable.
-- Business rule v1: one active gestor -> one active time; admin_local creates teams by selecting an active gestor from the same tenant.
-- Creation-time scope only. Post-creation gestor/time lifecycle is mandatory G1E0-A2 / Issue #135.
-- Root/Admin Global does not receive team-creation authority in this boundary.

BEGIN;

-- Serialize FECH.AI DDL for this exact criar_time boundary through commit.
SELECT pg_advisory_xact_lock(134, 20260826);

-- Match the authority-table order already used by T3A and freeze the relation
-- state that this migration fingerprints before any catalog decision.
LOCK TABLE public.admins, public.corretores, public.times
  IN SHARE ROW EXCLUSIVE MODE;

DO $preflight_static$
DECLARE
  v_functiondef_md5 text;
  v_function_aux_md5 text;
  v_owner text;
  v_security_definer boolean;
  v_function_acl text;
  v_is_root_functiondef_md5 text;
  v_is_root_owner text;
  v_is_root_security_definer boolean;
  v_is_root_search_path text;
  v_is_root_acl text;
  v_corretores_user_indexdef text;
  v_corretores_user_constraintdef text;
  v_corretores_user_constraint_deferrable boolean;
  v_corretores_user_constraint_deferred boolean;
  v_shape_md5 text;
  v_policy_md5 text;
  v_policy_helper_count bigint;
  v_policy_helper_md5 text;
  v_times_relhasrules boolean;
  v_rewrite_count bigint;
  v_index_md5 text;
  v_constraint_md5 text;
  v_trigger_md5 text;
  v_trigger_dependency_md5 text;
  v_table_acl_md5 text;
  v_times_owner text;
  v_times_rls boolean;
  v_times_force_rls boolean;
BEGIN
  SELECT md5(pg_get_functiondef(p.oid)), pg_get_userbyid(p.proowner), p.prosecdef
  INTO v_functiondef_md5, v_owner, v_security_definer
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT md5(
           l.lanname || ':' || p.prokind::text || ':' || p.provolatile::text || ':' ||
           p.proisstrict::text || ':' || p.proleakproof::text || ':' || p.proparallel::text || ':' ||
           p.procost::text || ':' || p.prorows::text || ':' || p.proretset::text || ':' ||
           coalesce(pg_get_expr(p.proargdefaults, 0), '<NULL>') || ':' ||
           p.prorettype::regtype::text
         )
  INTO v_function_aux_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_language l ON l.oid = p.prolang
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT string_agg(
           (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
             e.privilege_type,
             e.is_grantable::text
         )
  INTO v_function_acl
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
  LEFT JOIN pg_roles r ON r.oid = e.grantee
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  IF v_functiondef_md5 IS DISTINCT FROM 'a74a3f995af604cdf32571ff2fdb83ab'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true
     OR v_function_aux_md5 IS DISTINCT FROM 'd32663ba32c7e1fd71487034c4575b07'
     OR v_function_acl IS DISTINCT FROM 'postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_CRIAR_TIME_BASELINE_DRIFT';
  END IF;

  SELECT md5(pg_get_functiondef(p.oid)),
         pg_get_userbyid(p.proowner),
         p.prosecdef,
         array_to_string(p.proconfig, ',')
  INTO v_is_root_functiondef_md5,
       v_is_root_owner,
       v_is_root_security_definer,
       v_is_root_search_path
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'is_root'
    AND pg_get_function_identity_arguments(p.oid) = '';

  SELECT string_agg(
           (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
             e.privilege_type,
             e.is_grantable::text
         )
  INTO v_is_root_acl
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
  LEFT JOIN pg_roles r ON r.oid = e.grantee
  WHERE n.nspname = 'public'
    AND p.proname = 'is_root'
    AND pg_get_function_identity_arguments(p.oid) = '';

  IF v_is_root_functiondef_md5 IS DISTINCT FROM '465c04885d729e63f1a1d4458fc2a1b0'
     OR v_is_root_owner IS DISTINCT FROM 'postgres'
     OR v_is_root_security_definer IS DISTINCT FROM true
     OR v_is_root_search_path IS DISTINCT FROM 'search_path=public'
     OR v_is_root_acl IS DISTINCT FROM 'authenticated:EXECUTE:false,postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_IS_ROOT_DEPENDENCY_DRIFT';
  END IF;

  SELECT pg_get_indexdef(i.indexrelid)
  INTO v_corretores_user_indexdef
  FROM pg_index i
  JOIN pg_class ic ON ic.oid = i.indexrelid
  WHERE i.indrelid = 'public.corretores'::regclass
    AND ic.relname = 'corretores_user_id_key';

  SELECT pg_get_constraintdef(c.oid), c.condeferrable, c.condeferred
  INTO v_corretores_user_constraintdef,
       v_corretores_user_constraint_deferrable,
       v_corretores_user_constraint_deferred
  FROM pg_constraint c
  WHERE c.conrelid = 'public.corretores'::regclass
    AND c.conname = 'corretores_user_id_key'
    AND c.contype = 'u';

  IF v_corretores_user_indexdef IS DISTINCT FROM
        'CREATE UNIQUE INDEX corretores_user_id_key ON public.corretores USING btree (user_id)'
     OR v_corretores_user_constraintdef IS DISTINCT FROM 'UNIQUE (user_id)'
     OR v_corretores_user_constraint_deferrable IS DISTINCT FROM false
     OR v_corretores_user_constraint_deferred IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_CORRETORES_USER_ID_KEY_DRIFT';
  END IF;

  SELECT md5(string_agg(
           a.attnum::text || ':' || a.attname || ':' ||
           pg_catalog.format_type(a.atttypid, a.atttypmod) || ':' ||
           a.attnotnull::text || ':' ||
           coalesce(pg_get_expr(ad.adbin, ad.adrelid), '<NULL>'),
           '|' ORDER BY a.attnum))
  INTO v_shape_md5
  FROM pg_attribute a
  LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
  WHERE a.attrelid = 'public.times'::regclass
    AND a.attnum > 0
    AND NOT a.attisdropped;

  SELECT md5(string_agg(
           policyname || ':' || permissive || ':' || array_to_string(roles, ',') || ':' ||
           cmd || ':' || coalesce(qual, '<NULL>') || ':' || coalesce(with_check, '<NULL>'),
           '|' ORDER BY policyname))
  INTO v_policy_md5
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'times';

  -- Closure set for every project-controlled helper that can change effective
  -- SELECT/UPDATE RLS semantics when authenticated UPDATE is restored.
  WITH helper_rows AS (
    SELECT n.nspname, p.proname,
      pg_get_function_identity_arguments(p.oid) AS args,
      pg_get_userbyid(p.proowner) AS owner_name,
      p.prosecdef,
      coalesce(array_to_string(p.proconfig, ','), '<NULL>') AS proconfig,
      p.provolatile::text AS provolatile, p.proisstrict, p.proleakproof,
      p.proparallel::text AS proparallel, p.procost, p.prorows, p.proretset,
      p.prokind::text AS prokind,
      coalesce(pg_get_expr(p.proargdefaults, 0), '<NULL>') AS argdefaults,
      p.prorettype::regtype::text AS rettype,
      l.lanname AS language_name,
      md5(pg_get_functiondef(p.oid)) AS functiondef_md5,
      (
        SELECT string_agg(
          (CASE WHEN e.grantee = 0 THEN 'PUBLIC'
                ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
          || ':' || e.privilege_type || ':' || e.is_grantable::text,
          ',' ORDER BY
            (CASE WHEN e.grantee = 0 THEN 'PUBLIC'
                  ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
            e.privilege_type, e.is_grantable::text
        )
        FROM aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
        LEFT JOIN pg_roles r ON r.oid = e.grantee
      ) AS acl
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_language l ON l.oid = p.prolang
    WHERE n.nspname = 'public'
      AND pg_get_function_identity_arguments(p.oid) = ''
      AND p.proname IN ('is_root','is_admin_local','my_empresa_id','my_corretor_id','my_time_id')
  )
  SELECT count(*),
         md5(string_agg(
           nspname || '.' || proname || '(' || args || '):' ||
           owner_name || ':' || prosecdef::text || ':' || proconfig || ':' ||
           provolatile || ':' || proisstrict::text || ':' || proleakproof::text || ':' ||
           proparallel || ':' || procost::text || ':' || prorows::text || ':' ||
           proretset::text || ':' || prokind || ':' || argdefaults || ':' || rettype || ':' ||
           language_name || ':' || functiondef_md5 || ':' || coalesce(acl, '<NULL>'),
           '|' ORDER BY proname
         ))
  INTO v_policy_helper_count, v_policy_helper_md5
  FROM helper_rows;

  -- Exact baseline has no table rewrite rules; direct UPDATE must never be
  -- restored over drifted ON UPDATE/INSTEAD semantics.
  SELECT c.relhasrules,
         (SELECT count(*) FROM pg_rewrite r WHERE r.ev_class = c.oid)
  INTO v_times_relhasrules, v_rewrite_count
  FROM pg_class c
  WHERE c.oid = 'public.times'::regclass;

  SELECT md5(string_agg(pg_get_indexdef(i.indexrelid), '|' ORDER BY pg_get_indexdef(i.indexrelid)))
  INTO v_index_md5
  FROM pg_index i
  WHERE i.indrelid = 'public.times'::regclass;

  SELECT md5(string_agg(c.conname || ':' || pg_get_constraintdef(c.oid), '|' ORDER BY c.conname))
  INTO v_constraint_md5
  FROM pg_constraint c
  WHERE c.conrelid = 'public.times'::regclass;

  SELECT md5(string_agg(
           t.tgname || ':' || t.tgisinternal::text || ':' ||
           t.tgenabled::text || ':' || pg_get_triggerdef(t.oid, true),
           '|' ORDER BY t.tgname))
  INTO v_trigger_md5
  FROM pg_trigger t
  WHERE t.tgrelid = 'public.times'::regclass;

  SELECT md5(string_agg(
           t.tgname || ':' ||
           t.tgisinternal::text || ':' ||
           t.tgenabled::text || ':' ||
           pg_get_triggerdef(t.oid, true) || ':' ||
           n.nspname || '.' || p.proname || '(' ||
           pg_get_function_identity_arguments(p.oid) || '):' ||
           pg_get_userbyid(p.proowner) || ':' ||
           p.prosecdef::text || ':' ||
           coalesce(array_to_string(p.proconfig, ','), '<NULL>') || ':' ||
           md5(pg_get_functiondef(p.oid)),
           '|' ORDER BY t.tgname))
  INTO v_trigger_dependency_md5
  FROM pg_trigger t
  JOIN pg_proc p ON p.oid = t.tgfoid
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE t.tgrelid = 'public.times'::regclass;

  SELECT md5(string_agg(
           (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
             e.privilege_type,
             e.is_grantable::text
         ))
  INTO v_table_acl_md5
  FROM pg_class c
  CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) e
  LEFT JOIN pg_roles r ON r.oid = e.grantee
  WHERE c.oid = 'public.times'::regclass;

  SELECT pg_get_userbyid(c.relowner), c.relrowsecurity, c.relforcerowsecurity
  INTO v_times_owner, v_times_rls, v_times_force_rls
  FROM pg_class c
  WHERE c.oid = 'public.times'::regclass;

  IF v_shape_md5 IS DISTINCT FROM '65a2ac1bd4dfe8641179c062545cd61e'
     OR v_policy_md5 IS DISTINCT FROM 'fb7c7a6249e330a0dcd504d77ac59242'
     OR v_policy_helper_count IS DISTINCT FROM 5
     OR v_policy_helper_md5 IS DISTINCT FROM '00084c2cbf8512632939f1bfaaf2ccc6'
     OR v_times_relhasrules IS DISTINCT FROM false
     OR v_rewrite_count IS DISTINCT FROM 0
     OR v_index_md5 IS DISTINCT FROM '8e278c0766eeb17730b02ec43284651a'
     OR v_constraint_md5 IS DISTINCT FROM 'c511b011399f721ea4d5fca492bc3112'
     OR v_trigger_md5 IS DISTINCT FROM 'e9632ab165c31ec53103730b12b971d1'
     OR v_trigger_dependency_md5 IS DISTINCT FROM '51885dbc71117560e94e452ac67a3dce'
     OR v_table_acl_md5 IS DISTINCT FROM 'f8ee719b593f56889e2d3728c4527d27'
     OR v_times_owner IS DISTINCT FROM 'postgres'
     OR v_times_rls IS DISTINCT FROM true
     OR v_times_force_rls IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_TIMES_CATALOG_BASELINE_DRIFT';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_attribute a
    WHERE a.attrelid = 'public.times'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attacl IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_TIMES_COLUMN_ACL_DRIFT';
  END IF;

  IF NOT has_table_privilege('authenticated', 'public.times', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.times', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.times', 'INSERT')
     OR has_table_privilege('authenticated', 'public.times', 'DELETE')
     OR has_table_privilege('authenticated', 'public.times', 'TRUNCATE')
     OR has_table_privilege('anon', 'public.times', 'SELECT')
     OR has_table_privilege('anon', 'public.times', 'INSERT')
     OR has_table_privilege('anon', 'public.times', 'UPDATE')
     OR has_table_privilege('anon', 'public.times', 'DELETE')
     OR has_table_privilege('anon', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_TIMES_EFFECTIVE_PRIVILEGE_DRIFT';
  END IF;

  IF has_function_privilege('authenticated', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_CRIAR_TIME_EXECUTE_BASELINE_DRIFT';
  END IF;

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NOT NULL THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_INDEX_ALREADY_EXISTS';
  END IF;
END
$preflight_static$;

DO $preflight_data$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.times t
    WHERE coalesce(t.ativo, true) = true
    GROUP BY t.gestor_id
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_DUPLICATE_ACTIVE_GESTOR';
  END IF;
END
$preflight_data$;

CREATE UNIQUE INDEX uq_times_one_active_team_per_gestor_v1
  ON public.times (gestor_id)
  WHERE coalesce(ativo, true) = true;

-- Re-check the replace target while the transaction advisory lock is held.
DO $pre_replace$
DECLARE
  v_functiondef_md5 text;
  v_function_aux_md5 text;
  v_owner text;
  v_security_definer boolean;
  v_function_acl text;
BEGIN
  SELECT md5(pg_get_functiondef(p.oid)), pg_get_userbyid(p.proowner), p.prosecdef
  INTO v_functiondef_md5, v_owner, v_security_definer
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT md5(
           l.lanname || ':' || p.prokind::text || ':' || p.provolatile::text || ':' ||
           p.proisstrict::text || ':' || p.proleakproof::text || ':' || p.proparallel::text || ':' ||
           p.procost::text || ':' || p.prorows::text || ':' || p.proretset::text || ':' ||
           coalesce(pg_get_expr(p.proargdefaults, 0), '<NULL>') || ':' ||
           p.prorettype::regtype::text
         )
  INTO v_function_aux_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_language l ON l.oid = p.prolang
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT string_agg(
           (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
             e.privilege_type,
             e.is_grantable::text
         )
  INTO v_function_acl
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
  LEFT JOIN pg_roles r ON r.oid = e.grantee
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  IF v_functiondef_md5 IS DISTINCT FROM 'a74a3f995af604cdf32571ff2fdb83ab'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true
     OR v_function_aux_md5 IS DISTINCT FROM 'd32663ba32c7e1fd71487034c4575b07'
     OR v_function_acl IS DISTINCT FROM 'postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_PRE_REPLACE_CRIAR_TIME_BASELINE_DRIFT';
  END IF;
END
$pre_replace$;

CREATE OR REPLACE FUNCTION public.criar_time(
  p_nome text,
  p_gestor_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
  v_actor_id uuid;
  v_actor_empresa_id uuid;
  v_actor_role text;
  v_actor_is_admin_local boolean;
  v_actor_ativo boolean;
  v_gestor_id uuid;
  v_empresa_id uuid;
  v_time_id uuid;
  v_nome text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('error', 'auth_required');
  END IF;

  -- Fail closed for fixed transaction snapshots. G1E0-A1's ROOT denial
  -- relies on READ COMMITTED statement visibility after authority-lock waits.
  IF current_setting('transaction_isolation') IS DISTINCT FROM 'read committed' THEN
    RETURN jsonb_build_object('error', 'unsupported_transaction_isolation');
  END IF;

  -- Serialize denial against INSERT/UPDATE/DELETE of the ROOT authority table.
  -- SHARE is compatible with another team-creation call but conflicts with
  -- ordinary writes, so a ROOT grant cannot commit between the denial check
  -- and this transaction's team INSERT.
  LOCK TABLE public.admins IN SHARE MODE;

  -- Lock the unique caller profile before evaluating is_root(). This serializes
  -- role/status/admin_global changes on the corretores-based ROOT source.
  SELECT
    c.id,
    c.empresa_id,
    c.role,
    c.is_admin_local,
    c.ativo
  INTO
    v_actor_id,
    v_actor_empresa_id,
    v_actor_role,
    v_actor_is_admin_local,
    v_actor_ativo
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
  FOR SHARE;

  -- G1E0-A1 is tenant-control-plane only. ROOT has no positive team-creation authority.
  IF public.is_root() THEN
    RETURN jsonb_build_object('error', 'forbidden');
  END IF;

  IF v_actor_id IS NULL
     OR v_actor_empresa_id IS NULL
     OR v_actor_ativo IS DISTINCT FROM true THEN
    RETURN jsonb_build_object('error', 'actor_not_found');
  END IF;

  IF v_actor_role IS DISTINCT FROM 'admin_local'
     OR v_actor_is_admin_local IS DISTINCT FROM true THEN
    RETURN jsonb_build_object('error', 'forbidden');
  END IF;

  IF char_length(coalesce(p_nome, '')) > 120 THEN
    RETURN jsonb_build_object('error', 'nome_too_long');
  END IF;

  -- Deterministic, locale-independent edge trim for Unicode whitespace and
  -- defensive invisible separators that can make a hostile RPC name appear blank.
  v_nome := btrim(
    coalesce(p_nome, ''),
    chr(9) || chr(10) || chr(11) || chr(12) || chr(13) || chr(32) ||
    chr(133) || chr(160) || chr(5760) ||
    chr(8192) || chr(8193) || chr(8194) || chr(8195) || chr(8196) || chr(8197) ||
    chr(8198) || chr(8199) || chr(8200) || chr(8201) || chr(8202) ||
    chr(8203) || chr(8232) || chr(8233) || chr(8239) ||
    chr(8287) || chr(8288) || chr(12288) || chr(65279)
  );

  IF v_nome = '' THEN
    RETURN jsonb_build_object('error', 'nome_required');
  END IF;

  -- Reject C0/C1 control characters remaining inside the normalized name.
  IF EXISTS (
    SELECT 1
    FROM generate_series(1, char_length(v_nome)) AS g(i)
    WHERE ascii(substr(v_nome, g.i, 1)) BETWEEN 1 AND 31
       OR ascii(substr(v_nome, g.i, 1)) BETWEEN 127 AND 159
  ) THEN
    RETURN jsonb_build_object('error', 'nome_invalid_control_char');
  END IF;

  IF p_gestor_id IS NULL THEN
    RETURN jsonb_build_object('error', 'gestor_required');
  END IF;

  -- Creation-time eligibility only. Post-creation gestor/time lifecycle is G1E0-A2 (#135).
  -- Lock the exact gestor row through the INSERT so overlapping role/status changes serialize.
  SELECT c.id
  INTO v_gestor_id
  FROM public.corretores c
  WHERE c.id = p_gestor_id
    AND c.empresa_id = v_actor_empresa_id
    AND c.user_id IS NOT NULL
    AND c.role = 'gestor'
    AND c.is_gestor IS TRUE
    AND c.is_admin_local IS FALSE
    AND c.ativo IS TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM public.admins a
      WHERE a.user_id = c.user_id
        AND coalesce(a.ativo, true) = true
    )
  FOR SHARE;

  IF v_gestor_id IS NULL THEN
    -- Do not reveal whether a gestor exists in another tenant.
    RETURN jsonb_build_object('error', 'gestor_not_found');
  END IF;

  v_empresa_id := v_actor_empresa_id;

  IF EXISTS (
    SELECT 1
    FROM public.times t
    WHERE t.gestor_id = v_gestor_id
      AND coalesce(t.ativo, true) = true
  ) THEN
    RETURN jsonb_build_object('error', 'gestor_already_has_active_team');
  END IF;

  BEGIN
    INSERT INTO public.times (
      empresa_id,
      gestor_id,
      nome
    ) VALUES (
      v_empresa_id,
      v_gestor_id,
      v_nome
    )
    RETURNING id INTO v_time_id;
  EXCEPTION
    WHEN unique_violation THEN
      RETURN jsonb_build_object('error', 'gestor_already_has_active_team');
  END;

  INSERT INTO public.logs (
    acao,
    usuario_email,
    empresa_id,
    detalhes
  )
  VALUES (
    'criar_time',
    current_setting('request.jwt.claims', true)::jsonb->>'email',
    v_empresa_id,
    jsonb_build_object(
      'time_id', v_time_id,
      'nome', v_nome,
      'root_mode', false
    )
  );

  RETURN jsonb_build_object(
    'ok', true,
    'time_id', v_time_id,
    'nome', v_nome
  );
END;
$function$;

-- Team structure mutations are RPC-only for ordinary authenticated clients.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.times FROM PUBLIC, anon, authenticated;
REVOKE INSERT (id, empresa_id, gestor_id, nome, descricao, ativo, created_at),
       UPDATE (id, empresa_id, gestor_id, nome, descricao, ativo, created_at)
  ON public.times FROM PUBLIC, anon, authenticated;

-- Rebuild the function ACL from a closed set.
REVOKE ALL PRIVILEGES ON FUNCTION public.criar_time(text, uuid) FROM PUBLIC;

DO $function_acl$
DECLARE
  role_row record;
BEGIN
  FOR role_row IN
    SELECT DISTINCT r.rolname
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
    LEFT JOIN pg_roles r ON r.oid = e.grantee
    WHERE n.nspname = 'public'
      AND p.proname = 'criar_time'
      AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid'
      AND e.grantee <> 0
      AND e.grantee <> p.proowner
  LOOP
    IF role_row.rolname IS NULL THEN
      RAISE EXCEPTION 'G1E0A_FUNCTION_ACL_UNKNOWN_GRANTEE';
    END IF;

    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON FUNCTION public.criar_time(text, uuid) FROM %I',
      role_row.rolname
    );
  END LOOP;
END
$function_acl$;

GRANT EXECUTE ON FUNCTION public.criar_time(text, uuid) TO authenticated, service_role;

DO $postflight$
DECLARE
  v_hardened_prosrc_md5 text;
  v_function_aux_md5 text;
  v_owner text;
  v_security_definer boolean;
  v_search_path text;
  v_function_acl text;
  v_is_root_functiondef_md5 text;
  v_corretores_user_indexdef text;
  v_corretores_user_constraintdef text;
  v_corretores_user_constraint_deferrable boolean;
  v_corretores_user_constraint_deferred boolean;
  v_shape_md5 text;
  v_policy_md5 text;
  v_policy_helper_count bigint;
  v_policy_helper_md5 text;
  v_times_relhasrules boolean;
  v_rewrite_count bigint;
  v_index_md5 text;
  v_constraint_md5 text;
  v_trigger_md5 text;
  v_trigger_dependency_md5 text;
  v_table_acl_md5 text;
  v_times_owner text;
  v_times_rls boolean;
  v_times_force_rls boolean;
BEGIN
  SELECT md5(p.prosrc), pg_get_userbyid(p.proowner), p.prosecdef, array_to_string(p.proconfig, ',')
  INTO v_hardened_prosrc_md5, v_owner, v_security_definer, v_search_path
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT md5(
           l.lanname || ':' || p.prokind::text || ':' || p.provolatile::text || ':' ||
           p.proisstrict::text || ':' || p.proleakproof::text || ':' || p.proparallel::text || ':' ||
           p.procost::text || ':' || p.prorows::text || ':' || p.proretset::text || ':' ||
           coalesce(pg_get_expr(p.proargdefaults, 0), '<NULL>') || ':' ||
           p.prorettype::regtype::text
         )
  INTO v_function_aux_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_language l ON l.oid = p.prolang
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT string_agg(
           (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
             e.privilege_type,
             e.is_grantable::text
         )
  INTO v_function_acl
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
  LEFT JOIN pg_roles r ON r.oid = e.grantee
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  IF v_hardened_prosrc_md5 IS DISTINCT FROM 'b87facbab07aa43c6f5c07d861bf76df'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true
     OR v_search_path IS DISTINCT FROM 'search_path=pg_catalog, public'
     OR v_function_aux_md5 IS DISTINCT FROM 'd32663ba32c7e1fd71487034c4575b07'
     OR v_function_acl IS DISTINCT FROM 'authenticated:EXECUTE:false,postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_CRIAR_TIME_DEFINITION_OR_ACL_DRIFT';
  END IF;

  SELECT md5(pg_get_functiondef(p.oid))
  INTO v_is_root_functiondef_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'is_root'
    AND pg_get_function_identity_arguments(p.oid) = '';

  SELECT pg_get_indexdef(i.indexrelid)
  INTO v_corretores_user_indexdef
  FROM pg_index i
  JOIN pg_class ic ON ic.oid = i.indexrelid
  WHERE i.indrelid = 'public.corretores'::regclass
    AND ic.relname = 'corretores_user_id_key';

  SELECT pg_get_constraintdef(c.oid), c.condeferrable, c.condeferred
  INTO v_corretores_user_constraintdef,
       v_corretores_user_constraint_deferrable,
       v_corretores_user_constraint_deferred
  FROM pg_constraint c
  WHERE c.conrelid = 'public.corretores'::regclass
    AND c.conname = 'corretores_user_id_key'
    AND c.contype = 'u';

  IF v_is_root_functiondef_md5 IS DISTINCT FROM '465c04885d729e63f1a1d4458fc2a1b0'
     OR v_corretores_user_indexdef IS DISTINCT FROM
        'CREATE UNIQUE INDEX corretores_user_id_key ON public.corretores USING btree (user_id)'
     OR v_corretores_user_constraintdef IS DISTINCT FROM 'UNIQUE (user_id)'
     OR v_corretores_user_constraint_deferrable IS DISTINCT FROM false
     OR v_corretores_user_constraint_deferred IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_AUTHORITY_DEPENDENCY_DRIFT';
  END IF;

  SELECT md5(string_agg(
           a.attnum::text || ':' || a.attname || ':' ||
           pg_catalog.format_type(a.atttypid, a.atttypmod) || ':' ||
           a.attnotnull::text || ':' ||
           coalesce(pg_get_expr(ad.adbin, ad.adrelid), '<NULL>'),
           '|' ORDER BY a.attnum))
  INTO v_shape_md5
  FROM pg_attribute a
  LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
  WHERE a.attrelid = 'public.times'::regclass
    AND a.attnum > 0
    AND NOT a.attisdropped;

  SELECT md5(string_agg(
           policyname || ':' || permissive || ':' || array_to_string(roles, ',') || ':' ||
           cmd || ':' || coalesce(qual, '<NULL>') || ':' || coalesce(with_check, '<NULL>'),
           '|' ORDER BY policyname))
  INTO v_policy_md5
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'times';

  -- Closure set for every project-controlled helper that can change effective
  -- SELECT/UPDATE RLS semantics when authenticated UPDATE is restored.
  WITH helper_rows AS (
    SELECT n.nspname, p.proname,
      pg_get_function_identity_arguments(p.oid) AS args,
      pg_get_userbyid(p.proowner) AS owner_name,
      p.prosecdef,
      coalesce(array_to_string(p.proconfig, ','), '<NULL>') AS proconfig,
      p.provolatile::text AS provolatile, p.proisstrict, p.proleakproof,
      p.proparallel::text AS proparallel, p.procost, p.prorows, p.proretset,
      p.prokind::text AS prokind,
      coalesce(pg_get_expr(p.proargdefaults, 0), '<NULL>') AS argdefaults,
      p.prorettype::regtype::text AS rettype,
      l.lanname AS language_name,
      md5(pg_get_functiondef(p.oid)) AS functiondef_md5,
      (
        SELECT string_agg(
          (CASE WHEN e.grantee = 0 THEN 'PUBLIC'
                ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
          || ':' || e.privilege_type || ':' || e.is_grantable::text,
          ',' ORDER BY
            (CASE WHEN e.grantee = 0 THEN 'PUBLIC'
                  ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
            e.privilege_type, e.is_grantable::text
        )
        FROM aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) e
        LEFT JOIN pg_roles r ON r.oid = e.grantee
      ) AS acl
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_language l ON l.oid = p.prolang
    WHERE n.nspname = 'public'
      AND pg_get_function_identity_arguments(p.oid) = ''
      AND p.proname IN ('is_root','is_admin_local','my_empresa_id','my_corretor_id','my_time_id')
  )
  SELECT count(*),
         md5(string_agg(
           nspname || '.' || proname || '(' || args || '):' ||
           owner_name || ':' || prosecdef::text || ':' || proconfig || ':' ||
           provolatile || ':' || proisstrict::text || ':' || proleakproof::text || ':' ||
           proparallel || ':' || procost::text || ':' || prorows::text || ':' ||
           proretset::text || ':' || prokind || ':' || argdefaults || ':' || rettype || ':' ||
           language_name || ':' || functiondef_md5 || ':' || coalesce(acl, '<NULL>'),
           '|' ORDER BY proname
         ))
  INTO v_policy_helper_count, v_policy_helper_md5
  FROM helper_rows;

  -- Exact baseline has no table rewrite rules; direct UPDATE must never be
  -- restored over drifted ON UPDATE/INSTEAD semantics.
  SELECT c.relhasrules,
         (SELECT count(*) FROM pg_rewrite r WHERE r.ev_class = c.oid)
  INTO v_times_relhasrules, v_rewrite_count
  FROM pg_class c
  WHERE c.oid = 'public.times'::regclass;

  SELECT md5(string_agg(pg_get_indexdef(i.indexrelid), '|' ORDER BY pg_get_indexdef(i.indexrelid)))
  INTO v_index_md5
  FROM pg_index i
  WHERE i.indrelid = 'public.times'::regclass;

  SELECT md5(string_agg(c.conname || ':' || pg_get_constraintdef(c.oid), '|' ORDER BY c.conname))
  INTO v_constraint_md5
  FROM pg_constraint c
  WHERE c.conrelid = 'public.times'::regclass;

  SELECT md5(string_agg(
           t.tgname || ':' || t.tgisinternal::text || ':' ||
           t.tgenabled::text || ':' || pg_get_triggerdef(t.oid, true),
           '|' ORDER BY t.tgname))
  INTO v_trigger_md5
  FROM pg_trigger t
  WHERE t.tgrelid = 'public.times'::regclass;

  SELECT md5(string_agg(
           t.tgname || ':' ||
           t.tgisinternal::text || ':' ||
           t.tgenabled::text || ':' ||
           pg_get_triggerdef(t.oid, true) || ':' ||
           n.nspname || '.' || p.proname || '(' ||
           pg_get_function_identity_arguments(p.oid) || '):' ||
           pg_get_userbyid(p.proowner) || ':' ||
           p.prosecdef::text || ':' ||
           coalesce(array_to_string(p.proconfig, ','), '<NULL>') || ':' ||
           md5(pg_get_functiondef(p.oid)),
           '|' ORDER BY t.tgname))
  INTO v_trigger_dependency_md5
  FROM pg_trigger t
  JOIN pg_proc p ON p.oid = t.tgfoid
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE t.tgrelid = 'public.times'::regclass;

  SELECT md5(string_agg(
           (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE WHEN e.grantee = 0 THEN 'PUBLIC' ELSE coalesce(r.rolname, 'OID:' || e.grantee::text) END),
             e.privilege_type,
             e.is_grantable::text
         ))
  INTO v_table_acl_md5
  FROM pg_class c
  CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) e
  LEFT JOIN pg_roles r ON r.oid = e.grantee
  WHERE c.oid = 'public.times'::regclass;

  SELECT pg_get_userbyid(c.relowner), c.relrowsecurity, c.relforcerowsecurity
  INTO v_times_owner, v_times_rls, v_times_force_rls
  FROM pg_class c
  WHERE c.oid = 'public.times'::regclass;

  IF v_shape_md5 IS DISTINCT FROM '65a2ac1bd4dfe8641179c062545cd61e'
     OR v_policy_md5 IS DISTINCT FROM 'fb7c7a6249e330a0dcd504d77ac59242'
     OR v_policy_helper_count IS DISTINCT FROM 5
     OR v_policy_helper_md5 IS DISTINCT FROM '00084c2cbf8512632939f1bfaaf2ccc6'
     OR v_times_relhasrules IS DISTINCT FROM false
     OR v_rewrite_count IS DISTINCT FROM 0
     OR v_index_md5 IS DISTINCT FROM 'db8482cbabfdd2666bcef8a7ad00d401'
     OR v_constraint_md5 IS DISTINCT FROM 'c511b011399f721ea4d5fca492bc3112'
     OR v_trigger_md5 IS DISTINCT FROM 'e9632ab165c31ec53103730b12b971d1'
     OR v_trigger_dependency_md5 IS DISTINCT FROM '51885dbc71117560e94e452ac67a3dce'
     OR v_table_acl_md5 IS DISTINCT FROM '46f5fbdbf33d5175ba92320c78cce8cb'
     OR v_times_owner IS DISTINCT FROM 'postgres'
     OR v_times_rls IS DISTINCT FROM true
     OR v_times_force_rls IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_TIMES_CATALOG_DRIFT';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_attribute a
    WHERE a.attrelid = 'public.times'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attacl IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_COLUMN_ACL_PRESENT';
  END IF;

  IF NOT has_table_privilege('authenticated', 'public.times', 'SELECT')
     OR has_table_privilege('authenticated', 'public.times', 'INSERT')
     OR has_table_privilege('authenticated', 'public.times', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.times', 'DELETE')
     OR has_table_privilege('authenticated', 'public.times', 'TRUNCATE')
     OR has_table_privilege('anon', 'public.times', 'SELECT')
     OR has_table_privilege('anon', 'public.times', 'INSERT')
     OR has_table_privilege('anon', 'public.times', 'UPDATE')
     OR has_table_privilege('anon', 'public.times', 'DELETE')
     OR has_table_privilege('anon', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_EFFECTIVE_TABLE_PRIVILEGE_DRIFT';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_attribute a
    CROSS JOIN (VALUES ('authenticated'::text), ('anon'::text)) AS role_name(rolname)
    WHERE a.attrelid = 'public.times'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND (
        has_column_privilege(role_name.rolname, 'public.times', a.attname, 'INSERT')
        OR has_column_privilege(role_name.rolname, 'public.times', a.attname, 'UPDATE')
      )
  ) THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_EFFECTIVE_COLUMN_DML_PRESENT';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.times t
    WHERE coalesce(t.ativo, true) = true
    GROUP BY t.gestor_id
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_DUPLICATE_ACTIVE_GESTOR';
  END IF;
END
$postflight$;

COMMIT;
