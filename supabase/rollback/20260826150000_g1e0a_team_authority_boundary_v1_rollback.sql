-- FECH.AI — rollback G1E0-A1 Team Creation Authority Boundary v1
-- Restores the exact pre-G1E0-A criar_time behavior and authenticated direct UPDATE on public.times.
-- Production execution requires separate explicit rollback authority.
-- Post-creation lifecycle remains tracked separately in G1E0-A2 / Issue #135.

BEGIN;

-- Serialize rollback against FECH.AI DDL for this exact criar_time boundary.
SELECT pg_advisory_xact_lock(134, 20260826);

DO $preflight$
DECLARE
  v_hardened_prosrc_md5 text;
  v_owner text;
  v_security_definer boolean;
  v_search_path text;
  v_indexdef text;
  v_function_acl text;
BEGIN
  SELECT md5(p.prosrc), pg_get_userbyid(p.proowner), p.prosecdef, array_to_string(p.proconfig, ',')
  INTO v_hardened_prosrc_md5, v_owner, v_security_definer, v_search_path
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT string_agg(
           (CASE
              WHEN e.grantee = 0 THEN 'PUBLIC'
              ELSE coalesce(r.rolname, 'OID:' || e.grantee::text)
            END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE
                WHEN e.grantee = 0 THEN 'PUBLIC'
                ELSE coalesce(r.rolname, 'OID:' || e.grantee::text)
              END),
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

  IF v_hardened_prosrc_md5 IS DISTINCT FROM 'b61d2abdc52c250315b08002cc0aae06'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true
     OR v_search_path IS DISTINCT FROM 'search_path=pg_catalog, public'
     OR v_function_acl IS DISTINCT FROM 'authenticated:EXECUTE:false,postgres:EXECUTE:false,service_role:EXECUTE:false' THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_CRIAR_TIME_HARDENED_OR_ACL_DRIFT';
  END IF;

  SELECT pg_get_indexdef(i.indexrelid)
  INTO v_indexdef
  FROM pg_index i
  WHERE i.indexrelid = to_regclass('public.uq_times_one_active_team_per_gestor_v1');

  IF v_indexdef IS DISTINCT FROM 'CREATE UNIQUE INDEX uq_times_one_active_team_per_gestor_v1 ON public.times USING btree (gestor_id) WHERE (COALESCE(ativo, true) = true)' THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_CARDINALITY_INDEX_DRIFT';
  END IF;

  IF has_table_privilege('authenticated', 'public.times', 'INSERT')
     OR has_table_privilege('authenticated', 'public.times', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.times', 'DELETE')
     OR has_table_privilege('authenticated', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_AUTHENTICATED_DML_DRIFT';
  END IF;

  IF has_table_privilege('anon', 'public.times', 'INSERT')
     OR has_table_privilege('anon', 'public.times', 'UPDATE')
     OR has_table_privilege('anon', 'public.times', 'DELETE')
     OR has_table_privilege('anon', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_ANON_DML_DRIFT';
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

-- Restore the function ACL from a closed set, removing every non-owner grantee
-- before granting only the exact pre-G1E0-A caller role.
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

-- Restore the pre-G1E0-A authenticated table UPDATE privilege only.
GRANT UPDATE ON TABLE public.times TO authenticated;

DO $postflight$
DECLARE
  v_functiondef_md5 text;
  v_function_acl text;
BEGIN
  SELECT md5(pg_get_functiondef(p.oid))
  INTO v_functiondef_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  SELECT string_agg(
           (CASE
              WHEN e.grantee = 0 THEN 'PUBLIC'
              ELSE coalesce(r.rolname, 'OID:' || e.grantee::text)
            END)
           || ':' || e.privilege_type || ':' || e.is_grantable::text,
           ',' ORDER BY
             (CASE
                WHEN e.grantee = 0 THEN 'PUBLIC'
                ELSE coalesce(r.rolname, 'OID:' || e.grantee::text)
              END),
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

  IF NOT has_table_privilege('authenticated', 'public.times', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.times', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.times', 'INSERT')
     OR has_table_privilege('authenticated', 'public.times', 'DELETE')
     OR has_table_privilege('authenticated', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_AUTHENTICATED_ACL_NOT_RESTORED';
  END IF;

  IF has_table_privilege('anon', 'public.times', 'INSERT')
     OR has_table_privilege('anon', 'public.times', 'UPDATE')
     OR has_table_privilege('anon', 'public.times', 'DELETE')
     OR has_table_privilege('anon', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_ANON_DML_PRESENT';
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

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NOT NULL THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_INDEX_STILL_PRESENT';
  END IF;
END
$postflight$;

COMMIT;
