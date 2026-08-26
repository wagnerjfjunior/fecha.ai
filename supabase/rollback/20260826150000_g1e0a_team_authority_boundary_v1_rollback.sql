-- FECH.AI — rollback G1E0-A1 Team Creation Authority Boundary v1
-- Restores the exact pre-G1E0-A criar_time behavior and authenticated direct UPDATE on public.times.
-- Production execution requires separate explicit rollback authority.
-- Post-creation lifecycle remains tracked separately in G1E0-A2 / Issue #135.

BEGIN;

SELECT pg_advisory_xact_lock(134, 20260826);

-- Freeze every relation that participates in the rollback authority/catalog proof.
LOCK TABLE public.admins, public.corretores, public.times
  IN SHARE ROW EXCLUSIVE MODE;

DO $preflight$
DECLARE
  v_hardened_prosrc_md5 text;
  v_owner text;
  v_security_definer boolean;
  v_search_path text;
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
  v_index_md5 text;
  v_constraint_md5 text;
  v_trigger_md5 text;
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

  IF v_hardened_prosrc_md5 IS DISTINCT FROM 'cfdbd891104652b0ac850e1c8db05adc'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true
     OR v_search_path IS DISTINCT FROM 'search_path=pg_catalog, public'
     OR v_function_acl IS DISTINCT FROM 'authenticated:EXECUTE:false,postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_CRIAR_TIME_HARDENED_OR_ACL_DRIFT';
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
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_IS_ROOT_DEPENDENCY_DRIFT';
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
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_CORRETORES_USER_ID_KEY_DRIFT';
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
     OR v_index_md5 IS DISTINCT FROM 'db8482cbabfdd2666bcef8a7ad00d401'
     OR v_constraint_md5 IS DISTINCT FROM 'c511b011399f721ea4d5fca492bc3112'
     OR v_trigger_md5 IS DISTINCT FROM 'e9632ab165c31ec53103730b12b971d1'
     OR v_table_acl_md5 IS DISTINCT FROM '46f5fbdbf33d5175ba92320c78cce8cb'
     OR v_times_owner IS DISTINCT FROM 'postgres'
     OR v_times_rls IS DISTINCT FROM true
     OR v_times_force_rls IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_TIMES_CATALOG_DRIFT';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_attribute a
    WHERE a.attrelid = 'public.times'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attacl IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_COLUMN_ACL_DRIFT';
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
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_EFFECTIVE_TABLE_PRIVILEGE_DRIFT';
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
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_EFFECTIVE_COLUMN_DML_PRESENT';
  END IF;
END
$preflight$;

DROP INDEX public.uq_times_one_active_team_per_gestor_v1;

CREATE OR REPLACE FUNCTION public.criar_time(p_nome text, p_gestor_id uuid DEFAULT NULL::uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_corretor_id uuid;
  v_empresa_id uuid;
  v_gestor_id uuid;
  v_time_id uuid;
  v_root boolean := false;
BEGIN
  v_root := public.is_root();

  SELECT id, empresa_id
  INTO v_corretor_id, v_empresa_id
  FROM public.corretores
  WHERE user_id = auth.uid()
  LIMIT 1;

  IF NOT (public.is_admin_local() OR v_root) THEN
    RETURN jsonb_build_object('error', 'forbidden');
  END IF;

  v_gestor_id := COALESCE(p_gestor_id, v_corretor_id);

  IF v_root THEN
    SELECT empresa_id
    INTO v_empresa_id
    FROM public.corretores
    WHERE id = v_gestor_id
    LIMIT 1;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.corretores
    WHERE id = v_gestor_id
      AND (v_root OR empresa_id = v_empresa_id)
      AND is_gestor = true
  ) THEN
    RETURN jsonb_build_object('error', 'gestor_not_found');
  END IF;

  INSERT INTO public.times (
    empresa_id,
    gestor_id,
    nome
  ) VALUES (
    v_empresa_id,
    v_gestor_id,
    p_nome
  )
  RETURNING id INTO v_time_id;

  INSERT INTO public.logs (
    acao,
    usuario_email,
    empresa_id,
    detalhes
  )
  VALUES (
    'criar_time',
    current_setting('request.jwt.claims',true)::jsonb->>'email',
    v_empresa_id,
    jsonb_build_object(
      'time_id', v_time_id,
      'nome', p_nome,
      'root_mode', v_root
    )
  );

  RETURN jsonb_build_object(
    'ok', true,
    'time_id', v_time_id,
    'nome', p_nome
  );
END;
$function$;

-- Restore the function ACL from a closed set.
REVOKE ALL PRIVILEGES ON FUNCTION public.criar_time(text, uuid) FROM PUBLIC;

DO $restore_function_acl$
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
      RAISE EXCEPTION 'G1E0A_ROLLBACK_FUNCTION_ACL_UNKNOWN_GRANTEE';
    END IF;

    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON FUNCTION public.criar_time(text, uuid) FROM %I',
      role_row.rolname
    );
  END LOOP;
END
$restore_function_acl$;

GRANT EXECUTE ON FUNCTION public.criar_time(text, uuid) TO service_role;

-- Restore direct UPDATE only after the exact baseline RLS/policy/schema/ACL state
-- was proven under relation locks in the preflight above.
GRANT UPDATE ON TABLE public.times TO authenticated;

DO $postflight$
DECLARE
  v_functiondef_md5 text;
  v_function_acl text;
  v_is_root_functiondef_md5 text;
  v_corretores_user_indexdef text;
  v_corretores_user_constraintdef text;
  v_corretores_user_constraint_deferrable boolean;
  v_corretores_user_constraint_deferred boolean;
  v_shape_md5 text;
  v_policy_md5 text;
  v_index_md5 text;
  v_constraint_md5 text;
  v_trigger_md5 text;
  v_table_acl_md5 text;
  v_times_owner text;
  v_times_rls boolean;
  v_times_force_rls boolean;
BEGIN
  SELECT md5(pg_get_functiondef(p.oid))
  INTO v_functiondef_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
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
     OR v_function_acl IS DISTINCT FROM 'postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_CRIAR_TIME_OR_ACL_NOT_RESTORED';
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
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_AUTHORITY_DEPENDENCY_DRIFT';
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
     OR v_index_md5 IS DISTINCT FROM '8e278c0766eeb17730b02ec43284651a'
     OR v_constraint_md5 IS DISTINCT FROM 'c511b011399f721ea4d5fca492bc3112'
     OR v_trigger_md5 IS DISTINCT FROM 'e9632ab165c31ec53103730b12b971d1'
     OR v_table_acl_md5 IS DISTINCT FROM 'f8ee719b593f56889e2d3728c4527d27'
     OR v_times_owner IS DISTINCT FROM 'postgres'
     OR v_times_rls IS DISTINCT FROM true
     OR v_times_force_rls IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_TIMES_BASELINE_NOT_RESTORED';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_attribute a
    WHERE a.attrelid = 'public.times'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attacl IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_COLUMN_ACL_NOT_BASELINE';
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
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_EFFECTIVE_TABLE_PRIVILEGE_DRIFT';
  END IF;

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NOT NULL THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_INDEX_STILL_PRESENT';
  END IF;
END
$postflight$;

COMMIT;
