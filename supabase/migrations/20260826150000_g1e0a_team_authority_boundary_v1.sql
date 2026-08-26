-- FECH.AI — G1E0-A Team / Onboarding Authority Boundary v1
-- Scope: public.times + public.criar_time(text, uuid)
-- Primary risk: authenticated clients retain direct structural UPDATE on times while criar_time is not executable.
-- Business rule v1: one active gestor -> one active time; admin_local creates teams by selecting an active gestor from the same tenant.
-- Out of scope: Root/Admin Global contract, role transitions, tenant membership migration, frontend labels, production execution.

-- Fail closed on drift local to this boundary before locking mutable team state.
DO $preflight_static$
DECLARE
  v_functiondef_md5 text;
  v_owner text;
  v_security_definer boolean;
BEGIN
  SELECT md5(pg_get_functiondef(p.oid)), pg_get_userbyid(p.proowner), p.prosecdef
  INTO v_functiondef_md5, v_owner, v_security_definer
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'criar_time'
    AND pg_get_function_identity_arguments(p.oid) = 'p_nome text, p_gestor_id uuid';

  IF v_functiondef_md5 IS DISTINCT FROM 'a74a3f995af604cdf32571ff2fdb83ab'
     OR v_owner IS DISTINCT FROM 'postgres'
     OR v_security_definer IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_CRIAR_TIME_BASELINE_DRIFT';
  END IF;

  IF NOT has_table_privilege('authenticated', 'public.times', 'UPDATE') THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_TIMES_UPDATE_BASELINE_DRIFT';
  END IF;

  IF has_function_privilege('authenticated', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_CRIAR_TIME_EXECUTE_BASELINE_DRIFT';
  END IF;

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NOT NULL THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_INDEX_ALREADY_EXISTS';
  END IF;
END
$preflight_static$;

-- Close the preflight race: no structural writer may commit between integrity validation and hardening.
LOCK TABLE public.times IN SHARE ROW EXCLUSIVE MODE;

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

  IF EXISTS (
    SELECT 1
    FROM public.times t
    LEFT JOIN public.corretores c ON c.id = t.gestor_id
    WHERE coalesce(t.ativo, true) = true
      AND (
        c.id IS NULL
        OR c.empresa_id IS DISTINCT FROM t.empresa_id
        OR c.is_gestor IS DISTINCT FROM true
        OR c.ativo IS DISTINCT FROM true
      )
  ) THEN
    RAISE EXCEPTION 'G1E0A_PREFLIGHT_ACTIVE_TIME_INTEGRITY_MISMATCH';
  END IF;
END
$preflight_data$;

-- BUSINESS_RULE_V1: a gestor may own at most one active team.
-- NULL times.ativo is treated as active for compatibility with existing team semantics.
CREATE UNIQUE INDEX uq_times_one_active_team_per_gestor_v1
  ON public.times (gestor_id)
  WHERE coalesce(ativo, true) = true;

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
  v_gestor_id uuid;
  v_gestor_empresa_id uuid;
  v_empresa_id uuid;
  v_time_id uuid;
  v_nome text;
  v_root boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('error', 'auth_required');
  END IF;

  v_root := public.is_root();

  SELECT c.id, c.empresa_id
  INTO v_actor_id, v_actor_empresa_id
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
  LIMIT 1;

  IF NOT v_root AND (v_actor_id IS NULL OR v_actor_empresa_id IS NULL) THEN
    RETURN jsonb_build_object('error', 'actor_not_found');
  END IF;

  IF NOT (v_root OR public.is_admin_local()) THEN
    RETURN jsonb_build_object('error', 'forbidden');
  END IF;

  v_nome := nullif(btrim(p_nome), '');
  IF v_nome IS NULL THEN
    RETURN jsonb_build_object('error', 'nome_required');
  END IF;

  IF p_gestor_id IS NULL THEN
    RETURN jsonb_build_object('error', 'gestor_required');
  END IF;

  -- Lock the exact gestor row through the INSERT so role/status changes serialize with team creation.
  -- New team ownership is intentionally limited to a pure, explicitly active gestor profile.
  SELECT c.id, c.empresa_id
  INTO v_gestor_id, v_gestor_empresa_id
  FROM public.corretores c
  WHERE c.id = p_gestor_id
    AND c.role = 'gestor'
    AND c.is_gestor IS TRUE
    AND c.is_admin_local IS FALSE
    AND c.ativo IS TRUE
  LIMIT 1
  FOR SHARE;

  IF v_gestor_id IS NULL OR v_gestor_empresa_id IS NULL THEN
    RETURN jsonb_build_object('error', 'gestor_not_found');
  END IF;

  IF v_root THEN
    v_empresa_id := v_gestor_empresa_id;
  ELSE
    IF v_gestor_empresa_id IS DISTINCT FROM v_actor_empresa_id THEN
      -- Do not reveal whether a gestor exists in another tenant.
      RETURN jsonb_build_object('error', 'gestor_not_found');
    END IF;
    v_empresa_id := v_actor_empresa_id;
  END IF;

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
      'root_mode', v_root
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
REVOKE UPDATE (id, empresa_id, gestor_id, nome, descricao, ativo, created_at)
  ON public.times FROM PUBLIC, anon, authenticated;

-- Explicit function ACL: authenticated may invoke the guarded RPC; anon/PUBLIC may not.
REVOKE ALL PRIVILEGES ON FUNCTION public.criar_time(text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.criar_time(text, uuid) TO authenticated, service_role;

DO $postflight$
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
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_CRIAR_TIME_DEFINITION_DRIFT';
  END IF;

  IF NOT has_function_privilege('authenticated', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_AUTHENTICATED_EXECUTE_MISSING';
  END IF;

  IF has_function_privilege('anon', 'public.criar_time(text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_ANON_EXECUTE_PRESENT';
  END IF;

  IF has_table_privilege('authenticated', 'public.times', 'INSERT')
     OR has_table_privilege('authenticated', 'public.times', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.times', 'DELETE')
     OR has_table_privilege('authenticated', 'public.times', 'TRUNCATE') THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_DIRECT_TIMES_DML_PRESENT';
  END IF;

  IF to_regclass('public.uq_times_one_active_team_per_gestor_v1') IS NULL THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_CARDINALITY_INDEX_MISSING';
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

  IF EXISTS (
    SELECT 1
    FROM public.times t
    LEFT JOIN public.corretores c ON c.id = t.gestor_id
    WHERE coalesce(t.ativo, true) = true
      AND (
        c.id IS NULL
        OR c.empresa_id IS DISTINCT FROM t.empresa_id
        OR c.is_gestor IS DISTINCT FROM true
        OR c.ativo IS DISTINCT FROM true
      )
  ) THEN
    RAISE EXCEPTION 'G1E0A_POSTFLIGHT_ACTIVE_TIME_INTEGRITY_MISMATCH';
  END IF;
END
$postflight$;
