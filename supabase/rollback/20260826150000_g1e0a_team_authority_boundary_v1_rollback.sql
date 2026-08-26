-- FECH.AI — rollback G1E0-A Team / Onboarding Authority Boundary v1
-- Restores the exact pre-G1E0-A criar_time behavior and authenticated direct UPDATE on public.times.
-- Production execution requires separate explicit rollback authority.

DO $preflight$
DECLARE
  v_hardened_prosrc_md5 text;
  v_owner text;
  v_security_definer boolean;
BEGIN
  SELECT md5(p.prosrc), pg_get_userbyid(p.proowner), p.prosecdef
  INTO v_hardened_prosrc_md5, v_owner, v_security_definer
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  IF v_hardened_prosrc_md5 IS DISTINCT FROM '5e0a3f880ba7a1bc795687642a3554cc'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_CRIAR_TIME_HARDENED_DRIFT';
  END IF;

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NULL THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_CARDINALITY_INDEX_MISSING';
  END IF;

  IF NOT has_function_privilege('authenticated', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_AUTHENTICATED_EXECUTE_MISSING';
  END IF;

  IF has_table_privilege('authenticated', 'public.times', 'UPDATE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_PREFLIGHT_DIRECT_UPDATE_ALREADY_PRESENT';
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

-- Restore exact pre-G1E0-A ACL shape for criar_time.
REVOKE ALL PRIVILEGES ON FUNCTION public.criar_time(text, uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.criar_time(text, uuid) TO service_role;

-- Restore the pre-G1E0-A authenticated table UPDATE privilege.
GRANT UPDATE ON TABLE public.times TO authenticated;

DO $postflight$
DECLARE
  v_functiondef_md5 text;
BEGIN
  SELECT md5(pg_get_functiondef(p.oid))
  INTO v_functiondef_md5
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  IF v_functiondef_md5 IS DISTINCT FROM 'a74a3f995af604cdf32571ff2fdb83ab' THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_CRIAR_TIME_NOT_RESTORED';
  END IF;

  IF has_function_privilege('authenticated', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_AUTHENTICATED_EXECUTE_PRESENT';
  END IF;

  IF NOT has_function_privilege('service_role', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_SERVICE_ROLE_EXECUTE_MISSING';
  END IF;

  IF NOT has_table_privilege('authenticated', 'public.times', 'UPDATE') THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_TIMES_UPDATE_NOT_RESTORED';
  END IF;

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NOT NULL THEN
    RAISE EXCEPTION 'G1E0A_ROLLBACK_POSTFLIGHT_INDEX_STILL_PRESENT';
  END IF;
END
$postflight$;
