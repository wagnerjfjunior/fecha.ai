-- FECH.AI — G1E0-A2.1 bounded DB acceptance test
-- Run only in an authorized non-production validation environment after the
-- forward migration. The entire fixture transaction is rolled back.
-- Edge/Auth compensation cases require the companion Edge runtime test matrix
-- and cannot be proven by this SQL-only artifact.

BEGIN;

DO $catalog$
DECLARE
  v_rpc oid := to_regprocedure('public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)');
  v_guard oid := to_regprocedure('public.a2_1_assert_corretor_creation_invariants()');
  v_security_definer boolean;
  v_config text[];
BEGIN
  IF v_rpc IS NULL OR v_guard IS NULL THEN
    RAISE EXCEPTION 'A2.1 test: expected functions missing';
  END IF;

  SELECT prosecdef, proconfig INTO v_security_definer, v_config
  FROM pg_proc
  WHERE oid = v_rpc;

  IF v_security_definer IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'A2.1 test: RPC is not SECURITY DEFINER';
  END IF;

  IF NOT ('search_path=pg_catalog, public' = ANY(coalesce(v_config, ARRAY[]::text[]))) THEN
    RAISE EXCEPTION 'A2.1 test: RPC search_path mismatch';
  END IF;

  IF (SELECT pg_get_userbyid(proowner) FROM pg_proc WHERE oid=v_rpc) IS DISTINCT FROM 'postgres' THEN
    RAISE EXCEPTION 'A2.1 test: RPC owner mismatch';
  END IF;

  IF (SELECT pg_get_userbyid(proowner) FROM pg_proc WHERE oid=v_guard) IS DISTINCT FROM 'postgres' THEN
    RAISE EXCEPTION 'A2.1 test: invariant owner mismatch';
  END IF;

  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid=v_guard) THEN
    RAISE EXCEPTION 'A2.1 test: invariant is not SECURITY DEFINER';
  END IF;

  IF NOT (
    'search_path=pg_catalog, public' = ANY(
      coalesce((SELECT proconfig FROM pg_proc WHERE oid=v_guard), ARRAY[]::text[])
    )
  ) THEN
    RAISE EXCEPTION 'A2.1 test: invariant search_path mismatch';
  END IF;

  IF has_function_privilege('anon', v_rpc, 'EXECUTE')
     OR has_function_privilege('service_role', v_rpc, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_rpc, 'EXECUTE') THEN
    RAISE EXCEPTION 'A2.1 test: RPC ACL mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.routine_privileges
    WHERE specific_schema='public'
      AND routine_name='a2_1_create_corretor_profile'
      AND grantee='PUBLIC'
      AND privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'A2.1 test: PUBLIC execute is open';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid='public.corretores'::regclass
      AND tgname='trg_a2_1_assert_corretor_creation_invariants'
      AND tgenabled='O'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'A2.1 test: invariant trigger missing/disabled';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid='public.corretores'::regclass
      AND tgname='trg_t3_fence_admin_password_reset_corretores'
      AND tgenabled='O'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'A2.1 test: T3 INSERT fence missing/disabled';
  END IF;
END
$catalog$;

-- Positive data-floor test: a canonical Corretor in an active same-tenant Time
-- must be accepted. user_id is nullable, so this does not create an Auth fixture.
DO $positive$
DECLARE
  v_time public.times%ROWTYPE;
  v_id uuid;
BEGIN
  SELECT * INTO v_time
  FROM public.times
  WHERE ativo IS TRUE
  ORDER BY id
  LIMIT 1;

  IF v_time.id IS NULL THEN
    RAISE EXCEPTION 'A2.1 test fixture unavailable: no active Time';
  END IF;

  INSERT INTO public.corretores(
    user_id, empresa_id, time_id, nome, email, role, ativo,
    apto_para_receber, is_admin_local, is_gestor, must_change_password
  )
  VALUES (
    NULL, v_time.empresa_id, v_time.id,
    'A2.1 fixture corretor',
    'a2-1-' || gen_random_uuid()::text || '@invalid.test',
    'corretor', true, true, false, false, true
  )
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'A2.1 test: canonical Corretor insert did not return id';
  END IF;
END
$positive$;

-- Negative: canonical-looking Corretor assigned to a Time from another tenant
-- must fail at the A2.1 invariant. Requires at least two tenants with Times.
DO $cross_tenant$
DECLARE
  v_time_a public.times%ROWTYPE;
  v_time_b public.times%ROWTYPE;
  v_failed boolean := false;
BEGIN
  SELECT * INTO v_time_a
  FROM public.times
  WHERE ativo IS TRUE
  ORDER BY id
  LIMIT 1;

  SELECT * INTO v_time_b
  FROM public.times
  WHERE ativo IS TRUE
    AND empresa_id <> v_time_a.empresa_id
  ORDER BY id
  LIMIT 1;

  IF v_time_a.id IS NULL OR v_time_b.id IS NULL THEN
    RAISE EXCEPTION 'A2.1 test fixture unavailable: two active tenant Times required';
  END IF;

  BEGIN
    INSERT INTO public.corretores(
      user_id, empresa_id, time_id, nome, email, role, ativo,
      apto_para_receber, is_admin_local, is_gestor, must_change_password
    )
    VALUES (
      NULL, v_time_a.empresa_id, v_time_b.id,
      'A2.1 cross tenant fixture',
      'a2-1-cross-' || gen_random_uuid()::text || '@invalid.test',
      'corretor', true, true, false, false, true
    );
  EXCEPTION WHEN others THEN
    IF SQLERRM IN ('A2_1_TARGET_NOT_AVAILABLE','A2_1_CREATION_INVARIANT_VIOLATION') THEN
      v_failed := true;
    ELSE
      RAISE;
    END IF;
  END;

  IF NOT v_failed THEN
    RAISE EXCEPTION 'A2.1 test: cross-tenant insert was accepted';
  END IF;
END
$cross_tenant$;

-- Negative role/time shape tests.
DO $role_shape$
DECLARE
  v_time public.times%ROWTYPE;
  v_failed boolean;
BEGIN
  SELECT * INTO v_time
  FROM public.times
  WHERE ativo IS TRUE
  ORDER BY id
  LIMIT 1;

  IF v_time.id IS NULL THEN
    RAISE EXCEPTION 'A2.1 test fixture unavailable: no active Time';
  END IF;

  v_failed := false;
  BEGIN
    INSERT INTO public.corretores(
      user_id, empresa_id, time_id, nome, email, role, ativo,
      apto_para_receber, is_admin_local, is_gestor, must_change_password
    )
    VALUES (
      NULL, v_time.empresa_id, v_time.id,
      'A2.1 invalid gestor fixture',
      'a2-1-gestor-' || gen_random_uuid()::text || '@invalid.test',
      'gestor', true, false, false, true, true
    );
  EXCEPTION WHEN others THEN
    IF SQLERRM = 'A2_1_CREATION_INVARIANT_VIOLATION' THEN
      v_failed := true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_failed THEN
    RAISE EXCEPTION 'A2.1 test: Gestor with member time_id was accepted';
  END IF;

  v_failed := false;
  BEGIN
    INSERT INTO public.corretores(
      user_id, empresa_id, time_id, nome, email, role, ativo,
      apto_para_receber, is_admin_local, is_gestor, must_change_password
    )
    VALUES (
      NULL, v_time.empresa_id, NULL,
      'A2.1 invalid corretor fixture',
      'a2-1-notime-' || gen_random_uuid()::text || '@invalid.test',
      'corretor', true, true, false, false, true
    );
  EXCEPTION WHEN others THEN
    IF SQLERRM = 'A2_1_CREATION_INVARIANT_VIOLATION' THEN
      v_failed := true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_failed THEN
    RAISE EXCEPTION 'A2.1 test: Corretor without Time was accepted';
  END IF;
END
$role_shape$;

-- Authoritative caller-JWT RPC matrix.
-- Positive authorization is proven by reaching the final INSERT with a
-- deliberately nonexistent Auth UUID and therefore raising FK violation.
-- Negative authorization cases must fail before that INSERT.
DO $rpc_boundary$
DECLARE
  v_actor_user_id uuid;
  v_actor_id uuid;
  v_empresa_id uuid;
  v_own_time_id uuid;
  v_other_gestor_id uuid;
  v_other_time_id uuid;
  v_inactive_time_id uuid;
  v_foreign_empresa_id uuid;
  v_foreign_gestor_id uuid;
  v_foreign_time_id uuid;
  v_probe_user_id uuid;
  v_probe_email text;
  v_reached_insert boolean := false;
  v_denied boolean := false;
BEGIN
  SELECT c.user_id, c.id, c.empresa_id, t.id
    INTO v_actor_user_id, v_actor_id, v_empresa_id, v_own_time_id
  FROM public.corretores c
  JOIN public.times t
    ON t.gestor_id = c.id
   AND t.empresa_id = c.empresa_id
   AND t.ativo IS TRUE
  WHERE c.user_id IS NOT NULL
    AND c.role = 'gestor'
    AND c.is_gestor IS TRUE
    AND coalesce(c.is_admin_local,false) IS FALSE
    AND c.ativo IS TRUE
  ORDER BY c.id
  LIMIT 1;

  IF v_actor_user_id IS NULL OR v_own_time_id IS NULL THEN
    RAISE EXCEPTION 'A2.1 test fixture unavailable: active Gestor with own active Time required';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_actor_user_id::text, true);

  -- Positive: own active Time passes authorization and reaches INSERT.
  v_probe_user_id := gen_random_uuid();
  v_probe_email := 'a2-1-rpc-own-' || v_probe_user_id::text || '@invalid.test';
  BEGIN
    PERFORM public.a2_1_create_corretor_profile(
      v_probe_user_id,
      'A2.1 RPC own Time probe',
      v_probe_email,
      'corretor',
      v_own_time_id,
      v_empresa_id
    );
  EXCEPTION
    WHEN foreign_key_violation THEN
      v_reached_insert := true;
  END;

  IF NOT v_reached_insert THEN
    RAISE EXCEPTION 'A2.1 test: Gestor own-Time RPC did not reach final INSERT';
  END IF;

  -- Same-tenant active Time owned by another Gestor must be denied.
  INSERT INTO public.corretores(
    user_id, empresa_id, time_id, nome, email, role, ativo,
    apto_para_receber, is_admin_local, is_gestor, must_change_password
  )
  VALUES (
    NULL, v_empresa_id, NULL,
    'A2.1 fixture other Gestor',
    'a2-1-other-gestor-' || gen_random_uuid()::text || '@invalid.test',
    'gestor', true, false, false, true, true
  )
  RETURNING id INTO v_other_gestor_id;

  INSERT INTO public.times(empresa_id, gestor_id, nome, ativo)
  VALUES (v_empresa_id, v_other_gestor_id, 'A2.1 fixture other Time', true)
  RETURNING id INTO v_other_time_id;

  v_denied := false;
  BEGIN
    PERFORM public.a2_1_create_corretor_profile(
      gen_random_uuid(),
      'A2.1 RPC other Time probe',
      'a2-1-rpc-other-' || gen_random_uuid()::text || '@invalid.test',
      'corretor',
      v_other_time_id,
      v_empresa_id
    );
  EXCEPTION WHEN others THEN
    IF SQLERRM = 'A2_1_TARGET_NOT_AVAILABLE' THEN
      v_denied := true;
    ELSE
      RAISE;
    END IF;
  END;

  IF NOT v_denied THEN
    RAISE EXCEPTION 'A2.1 test: Gestor other-Time RPC was not denied';
  END IF;

  -- Same-tenant inactive Time must be denied.
  INSERT INTO public.times(empresa_id, gestor_id, nome, ativo)
  VALUES (v_empresa_id, v_actor_id, 'A2.1 fixture inactive Time', false)
  RETURNING id INTO v_inactive_time_id;

  v_denied := false;
  BEGIN
    PERFORM public.a2_1_create_corretor_profile(
      gen_random_uuid(),
      'A2.1 RPC inactive Time probe',
      'a2-1-rpc-inactive-' || gen_random_uuid()::text || '@invalid.test',
      'corretor',
      v_inactive_time_id,
      v_empresa_id
    );
  EXCEPTION WHEN others THEN
    IF SQLERRM = 'A2_1_TARGET_NOT_AVAILABLE' THEN
      v_denied := true;
    ELSE
      RAISE;
    END IF;
  END;

  IF NOT v_denied THEN
    RAISE EXCEPTION 'A2.1 test: inactive-Time RPC was not denied';
  END IF;

  -- Foreign active Time must be denied when a second empresa is available.
  SELECT e.id INTO v_foreign_empresa_id
  FROM public.empresas e
  WHERE e.id <> v_empresa_id
  ORDER BY e.id
  LIMIT 1;

  IF v_foreign_empresa_id IS NOT NULL THEN
    INSERT INTO public.corretores(
      user_id, empresa_id, time_id, nome, email, role, ativo,
      apto_para_receber, is_admin_local, is_gestor, must_change_password
    )
    VALUES (
      NULL, v_foreign_empresa_id, NULL,
      'A2.1 fixture foreign Gestor',
      'a2-1-foreign-gestor-' || gen_random_uuid()::text || '@invalid.test',
      'gestor', true, false, false, true, true
    )
    RETURNING id INTO v_foreign_gestor_id;

    INSERT INTO public.times(empresa_id, gestor_id, nome, ativo)
    VALUES (v_foreign_empresa_id, v_foreign_gestor_id, 'A2.1 fixture foreign Time', true)
    RETURNING id INTO v_foreign_time_id;

    v_denied := false;
    BEGIN
      PERFORM public.a2_1_create_corretor_profile(
        gen_random_uuid(),
        'A2.1 RPC foreign Time probe',
        'a2-1-rpc-foreign-' || gen_random_uuid()::text || '@invalid.test',
        'corretor',
        v_foreign_time_id,
        v_empresa_id
      );
    EXCEPTION WHEN others THEN
      IF SQLERRM = 'A2_1_TARGET_NOT_AVAILABLE' THEN
        v_denied := true;
      ELSE
        RAISE;
      END IF;
    END;

    IF NOT v_denied THEN
      RAISE EXCEPTION 'A2.1 test: foreign-Time RPC was not denied';
    END IF;
  END IF;

  -- Schema + implementation proof for null-safe ownership. Live schema already
  -- requires times.gestor_id NOT NULL; the RPC must additionally remain
  -- null-safe if that contract ever changes.
  IF NOT EXISTS (
    SELECT 1
    FROM pg_attribute
    WHERE attrelid='public.times'::regclass
      AND attname='gestor_id'
      AND attnotnull
      AND NOT attisdropped
  ) THEN
    RAISE EXCEPTION 'A2.1 test: times.gestor_id nullability drift';
  END IF;

  IF position(
    'v_time_gestor_id IS DISTINCT FROM v_actor_id'
    IN pg_get_functiondef(
      'public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid)'::regprocedure
    )
  ) = 0 THEN
    RAISE EXCEPTION 'A2.1 test: Gestor ownership predicate is not null-safe';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', '', true);
END
$rpc_boundary$;

-- T1/T3 regression fingerprints from the exact A2.1 base anchor.
DO $regression$
DECLARE
  v_md5 text;
BEGIN
  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t3_fence_admin_password_reset_corretores'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'ea9fdc5ed6b1bf74bf0ff1d9bf27e7f6' THEN
    RAISE EXCEPTION 'A2.1 test: T3 trigger fingerprint changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_authority_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '68ec30b4d5014867c6db837d7d9db136' THEN
    RAISE EXCEPTION 'A2.1 test: T1 authority trigger fingerprint changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_direct_compat_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'faf7f23f5e7c246a4500a7db9e518bc5' THEN
    RAISE EXCEPTION 'A2.1 test: T1 compat trigger fingerprint changed';
  END IF;
END
$regression$;

ROLLBACK;

-- Companion Edge/runtime obligations (not executed by this SQL artifact):
-- 1. Admin Local + own active Time -> ALLOW.
-- 2. Admin Local + foreign/inactive/unknown Time -> generic DENY.
-- 3. Gestor + own active managed Time + Corretor -> ALLOW.
-- 4. Gestor -> Gestor/Admin Local -> DENY.
-- 5. Corretor actor -> DENY.
-- 6. Contradictory role booleans / malformed UUID -> DENY before Auth create.
-- 7. Stale Edge prevalidation with Time/ownership change -> RPC DENY.
-- 8. DB/RPC reject + Auth delete success -> COMPENSATION_CONFIRMED.
-- 9. DB/RPC reject + Auth delete failed/ambiguous ->
--    AUTH_COMPENSATION_UNRESOLVED, durable audit, no success, no blind retry.
-- 10. Supported ROOT provisioning regression remains valid.
