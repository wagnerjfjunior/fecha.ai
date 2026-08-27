-- FECH.AI — G1E0-A2.1
-- User creation / organizational membership authority boundary.
-- VERSIONED ONLY. This file is not applied by creating the PR.
-- Primary risk: service-role-backed creation could pair a local empresa_id
-- with a foreign/inactive Time or persist contradictory role/flag/time state.

BEGIN;

DO $preflight$
DECLARE
  v_bad integer;
  v_md5 text;
BEGIN
  IF to_regprocedure('public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)') IS NOT NULL
     OR to_regprocedure('public.a2_1_assert_corretor_creation_invariants()') IS NOT NULL THEN
    RAISE EXCEPTION 'A2.1 preflight: target objects already exist';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid = 'public.corretores'::regclass
      AND tgname = 'trg_a2_1_assert_corretor_creation_invariants'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'A2.1 preflight: target trigger already exists';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t3_fence_admin_password_reset_corretores'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'ea9fdc5ed6b1bf74bf0ff1d9bf27e7f6' THEN
    RAISE EXCEPTION 'A2.1 preflight: T3 trigger fingerprint drift';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_authority_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '68ec30b4d5014867c6db837d7d9db136' THEN
    RAISE EXCEPTION 'A2.1 preflight: T1 authority trigger fingerprint drift';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_direct_compat_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'faf7f23f5e7c246a4500a7db9e518bc5' THEN
    RAISE EXCEPTION 'A2.1 preflight: T1 compat trigger fingerprint drift';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_audit_trail_corretores_critical_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '60e6c615f59d9196e0979d6e93d2ad94' THEN
    RAISE EXCEPTION 'A2.1 preflight: audit trigger fingerprint drift';
  END IF;

  -- Existing cross-tenant membership would make a safe creation boundary
  -- rollout ambiguous. Legacy role/time exceptions are intentionally not
  -- blocked here because A2.1 is INSERT-only and does not repair them.
  SELECT count(*) INTO v_bad
  FROM public.corretores c
  JOIN public.times t ON t.id = c.time_id
  WHERE c.empresa_id IS DISTINCT FROM t.empresa_id;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'A2.1 preflight: existing cross-tenant membership detected';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION public.a2_1_assert_corretor_creation_invariants()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
BEGIN
  IF NEW.role = 'corretor' THEN
    IF coalesce(NEW.is_gestor, false)
       OR coalesce(NEW.is_admin_local, false)
       OR NEW.ativo IS DISTINCT FROM true
       OR NEW.apto_para_receber IS DISTINCT FROM true
       OR NEW.time_id IS NULL THEN
      RAISE EXCEPTION 'A2_1_CREATION_INVARIANT_VIOLATION';
    END IF;

    PERFORM 1
    FROM public.times t
    WHERE t.id = NEW.time_id
      AND t.empresa_id = NEW.empresa_id
      AND t.ativo IS TRUE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'A2_1_TARGET_NOT_AVAILABLE';
    END IF;

  ELSIF NEW.role = 'gestor' THEN
    IF NEW.is_gestor IS DISTINCT FROM true
       OR coalesce(NEW.is_admin_local, false)
       OR NEW.ativo IS DISTINCT FROM true
       OR NEW.apto_para_receber IS DISTINCT FROM false
       OR NEW.time_id IS NOT NULL THEN
      RAISE EXCEPTION 'A2_1_CREATION_INVARIANT_VIOLATION';
    END IF;

  ELSIF NEW.role = 'admin_local' THEN
    IF NEW.is_admin_local IS DISTINCT FROM true
       OR coalesce(NEW.is_gestor, false)
       OR NEW.ativo IS DISTINCT FROM true
       OR NEW.apto_para_receber IS DISTINCT FROM false
       OR NEW.time_id IS NOT NULL THEN
      RAISE EXCEPTION 'A2_1_CREATION_INVARIANT_VIOLATION';
    END IF;

  ELSIF NEW.role = 'admin_global' THEN
    -- Broader ROOT/Admin Global lifecycle is explicitly out of A2.1 scope.
    RETURN NEW;

  ELSE
    RAISE EXCEPTION 'A2_1_CREATION_INVARIANT_VIOLATION';
  END IF;

  RETURN NEW;
END
$function$;

REVOKE ALL ON FUNCTION public.a2_1_assert_corretor_creation_invariants() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.a2_1_assert_corretor_creation_invariants() FROM anon;
REVOKE ALL ON FUNCTION public.a2_1_assert_corretor_creation_invariants() FROM authenticated;
REVOKE ALL ON FUNCTION public.a2_1_assert_corretor_creation_invariants() FROM service_role;

CREATE TRIGGER trg_a2_1_assert_corretor_creation_invariants
AFTER INSERT ON public.corretores
FOR EACH ROW
EXECUTE FUNCTION public.a2_1_assert_corretor_creation_invariants();

CREATE OR REPLACE FUNCTION public.a2_1_create_corretor_profile(
  p_new_user_id uuid,
  p_nome text,
  p_email text,
  p_target_role text,
  p_time_id uuid DEFAULT NULL,
  p_empresa_id_intent uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
DECLARE
  v_actor_uid uuid := auth.uid();
  v_actor_id uuid;
  v_actor_empresa_id uuid;
  v_actor_role text;
  v_actor_ativo boolean;
  v_actor_is_admin_local boolean;
  v_actor_is_gestor boolean;
  v_root_admin_id uuid;
  v_root_role text;
  v_root_ativo boolean;
  v_is_root boolean := false;
  v_target_empresa_id uuid;
  v_time_id uuid;
  v_time_empresa_id uuid;
  v_time_gestor_id uuid;
  v_time_ativo boolean;
  v_created_id uuid;
  v_actor_count integer;
BEGIN
  IF v_actor_uid IS NULL THEN
    RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
  END IF;

  IF p_new_user_id IS NULL
     OR nullif(btrim(p_nome), '') IS NULL
     OR nullif(btrim(p_email), '') IS NULL
     OR p_target_role NOT IN ('corretor', 'gestor', 'admin_local') THEN
    RAISE EXCEPTION 'A2_1_INVALID_REQUEST';
  END IF;

  -- ROOT authority remains the existing active admins/admin_global contract.
  SELECT a.id, a.role, a.ativo
    INTO v_root_admin_id, v_root_role, v_root_ativo
  FROM public.admins a
  WHERE a.user_id = v_actor_uid
  FOR SHARE;

  v_is_root :=
    v_root_admin_id IS NOT NULL
    AND v_root_ativo IS TRUE
    AND v_root_role = 'admin_global';

  IF v_is_root THEN
    IF p_empresa_id_intent IS NULL THEN
      RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
    END IF;
    v_target_empresa_id := p_empresa_id_intent;
  ELSE
    SELECT count(*) INTO v_actor_count
    FROM public.corretores c
    WHERE c.user_id = v_actor_uid;

    IF v_actor_count <> 1 THEN
      RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
    END IF;

    SELECT
      c.id,
      c.empresa_id,
      c.role,
      c.ativo,
      coalesce(c.is_admin_local, false),
      coalesce(c.is_gestor, false)
    INTO
      v_actor_id,
      v_actor_empresa_id,
      v_actor_role,
      v_actor_ativo,
      v_actor_is_admin_local,
      v_actor_is_gestor
    FROM public.corretores c
    WHERE c.user_id = v_actor_uid
    FOR SHARE;

    IF v_actor_ativo IS DISTINCT FROM true
       OR v_actor_empresa_id IS NULL THEN
      RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
    END IF;

    -- admin_local role has precedence over the legacy extra is_gestor flag.
    IF v_actor_role = 'admin_local' AND v_actor_is_admin_local IS TRUE THEN
      NULL;
    ELSIF v_actor_role = 'gestor'
          AND v_actor_is_gestor IS TRUE
          AND v_actor_is_admin_local IS FALSE THEN
      IF p_target_role <> 'corretor' THEN
        RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
      END IF;
    ELSE
      RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
    END IF;

    IF p_empresa_id_intent IS NOT NULL
       AND p_empresa_id_intent <> v_actor_empresa_id THEN
      RAISE EXCEPTION 'A2_1_NOT_AUTHORIZED';
    END IF;

    v_target_empresa_id := v_actor_empresa_id;
  END IF;

  IF p_target_role = 'corretor' THEN
    IF p_time_id IS NULL THEN
      RAISE EXCEPTION 'A2_1_TARGET_NOT_AVAILABLE';
    END IF;

    SELECT t.id, t.empresa_id, t.gestor_id, t.ativo
      INTO v_time_id, v_time_empresa_id, v_time_gestor_id, v_time_ativo
    FROM public.times t
    WHERE t.id = p_time_id
    FOR SHARE;

    IF v_time_id IS NULL
       OR v_time_ativo IS DISTINCT FROM true
       OR v_time_empresa_id <> v_target_empresa_id THEN
      RAISE EXCEPTION 'A2_1_TARGET_NOT_AVAILABLE';
    END IF;

    IF NOT v_is_root
       AND v_actor_role = 'gestor'
       AND v_time_gestor_id <> v_actor_id THEN
      RAISE EXCEPTION 'A2_1_TARGET_NOT_AVAILABLE';
    END IF;
  ELSE
    IF p_time_id IS NOT NULL THEN
      RAISE EXCEPTION 'A2_1_INVALID_REQUEST';
    END IF;
  END IF;

  INSERT INTO public.corretores (
    user_id,
    empresa_id,
    time_id,
    nome,
    email,
    role,
    ativo,
    apto_para_receber,
    is_admin_local,
    is_gestor,
    must_change_password,
    created_by
  )
  VALUES (
    p_new_user_id,
    v_target_empresa_id,
    CASE WHEN p_target_role = 'corretor' THEN p_time_id ELSE NULL END,
    btrim(p_nome),
    btrim(p_email),
    p_target_role,
    true,
    (p_target_role = 'corretor'),
    (p_target_role = 'admin_local'),
    (p_target_role = 'gestor'),
    true,
    CASE WHEN v_is_root THEN NULL ELSE v_actor_id END
  )
  RETURNING id INTO v_created_id;

  RETURN jsonb_build_object('ok', true, 'corretor_id', v_created_id);
END
$function$;

REVOKE ALL ON FUNCTION public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid) FROM anon;
REVOKE ALL ON FUNCTION public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid) FROM service_role;
GRANT EXECUTE ON FUNCTION public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid) TO authenticated;

COMMENT ON FUNCTION public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)
IS 'G1E0-A2.1 caller-JWT creation boundary. Actor authority derives from auth.uid() and locked database state.';

COMMENT ON FUNCTION public.a2_1_assert_corretor_creation_invariants()
IS 'G1E0-A2.1 INSERT-only organizational invariant. Does not repair or govern existing-row lifecycle transitions.';

DO $postflight$
DECLARE
  v_md5 text;
BEGIN
  IF to_regprocedure('public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)') IS NULL
     OR to_regprocedure('public.a2_1_assert_corretor_creation_invariants()') IS NULL THEN
    RAISE EXCEPTION 'A2.1 postflight: expected functions missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid='public.corretores'::regclass
      AND tgname='trg_a2_1_assert_corretor_creation_invariants'
      AND tgenabled='O'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'A2.1 postflight: invariant trigger missing or disabled';
  END IF;

  IF has_function_privilege('anon', 'public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)', 'EXECUTE')
     OR has_function_privilege('public', 'public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'A2.1 postflight: RPC ACL mismatch';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t3_fence_admin_password_reset_corretores'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'ea9fdc5ed6b1bf74bf0ff1d9bf27e7f6' THEN
    RAISE EXCEPTION 'A2.1 postflight: T3 trigger changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_authority_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '68ec30b4d5014867c6db837d7d9db136' THEN
    RAISE EXCEPTION 'A2.1 postflight: T1 authority trigger changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_direct_compat_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'faf7f23f5e7c246a4500a7db9e518bc5' THEN
    RAISE EXCEPTION 'A2.1 postflight: T1 compat trigger changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_audit_trail_corretores_critical_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '60e6c615f59d9196e0979d6e93d2ad94' THEN
    RAISE EXCEPTION 'A2.1 postflight: audit trigger changed';
  END IF;
END
$postflight$;

COMMIT;
