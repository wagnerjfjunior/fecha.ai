-- FECH.AI — G1E0-A2.1 rollback
-- SAFE-ROLLBACK CONTRACT:
-- This rollback MUST NOT reopen the known vulnerable creation path.
-- It refuses to remove the DB safety floor unless an operator has already
-- disabled user creation or established another reviewed authority boundary.
--
-- Before executing this rollback in an authorized maintenance transaction:
--   SET LOCAL fechai.a2_1_safe_boundary_confirmed = 'on';
--
-- That setting is an explicit operator assertion, not an automatic safety proof.

BEGIN;

DO $gate$
DECLARE
  v_gate text := current_setting('fechai.a2_1_safe_boundary_confirmed', true);
  v_md5 text;
BEGIN
  IF v_gate IS DISTINCT FROM 'on' THEN
    RAISE EXCEPTION
      'A2.1 rollback blocked: safe alternate boundary or fail-closed creation not confirmed';
  END IF;

  IF to_regprocedure('public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid,uuid,text)') IS NULL
     OR to_regprocedure('public.a2_1_assert_corretor_creation_invariants()') IS NULL
     OR to_regprocedure('public.a2_1_issue_user_creation_edge_proof(uuid,uuid,text)') IS NULL
     OR to_regclass('public.a2_1_user_creation_edge_proofs') IS NULL THEN
    RAISE EXCEPTION 'A2.1 rollback preflight: expected forward objects missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid='public.corretores'::regclass
      AND tgname='trg_a2_1_assert_corretor_creation_invariants'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'A2.1 rollback preflight: invariant trigger missing';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t3_fence_admin_password_reset_corretores'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'ea9fdc5ed6b1bf74bf0ff1d9bf27e7f6' THEN
    RAISE EXCEPTION 'A2.1 rollback preflight: T3 trigger fingerprint drift';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_authority_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '68ec30b4d5014867c6db837d7d9db136' THEN
    RAISE EXCEPTION 'A2.1 rollback preflight: T1 authority trigger fingerprint drift';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_direct_compat_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'faf7f23f5e7c246a4500a7db9e518bc5' THEN
    RAISE EXCEPTION 'A2.1 rollback preflight: T1 compat trigger fingerprint drift';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_audit_trail_corretores_critical_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '60e6c615f59d9196e0979d6e93d2ad94' THEN
    RAISE EXCEPTION 'A2.1 rollback preflight: audit trigger fingerprint drift';
  END IF;
END
$gate$;

DROP TRIGGER trg_a2_1_assert_corretor_creation_invariants ON public.corretores;
DROP FUNCTION public.a2_1_assert_corretor_creation_invariants();
DROP FUNCTION public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid,uuid,text);
DROP FUNCTION public.a2_1_issue_user_creation_edge_proof(uuid,uuid,text);
DROP TABLE public.a2_1_user_creation_edge_proofs;

DO $postflight$
DECLARE
  v_md5 text;
BEGIN
  IF to_regprocedure('public.a2_1_create_corretor_profile(uuid,text,text,text,uuid,uuid,uuid,text)') IS NOT NULL
     OR to_regprocedure('public.a2_1_assert_corretor_creation_invariants()') IS NOT NULL
     OR to_regprocedure('public.a2_1_issue_user_creation_edge_proof(uuid,uuid,text)') IS NOT NULL
     OR to_regclass('public.a2_1_user_creation_edge_proofs') IS NOT NULL THEN
    RAISE EXCEPTION 'A2.1 rollback postflight: target functions still exist';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid='public.corretores'::regclass
      AND tgname='trg_a2_1_assert_corretor_creation_invariants'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'A2.1 rollback postflight: target trigger still exists';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t3_fence_admin_password_reset_corretores'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'ea9fdc5ed6b1bf74bf0ff1d9bf27e7f6' THEN
    RAISE EXCEPTION 'A2.1 rollback postflight: T3 trigger changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_authority_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM '68ec30b4d5014867c6db837d7d9db136' THEN
    RAISE EXCEPTION 'A2.1 rollback postflight: T1 authority trigger changed';
  END IF;

  SELECT md5(pg_get_triggerdef(t.oid, true)) INTO v_md5
  FROM pg_trigger t
  WHERE t.tgrelid='public.corretores'::regclass
    AND t.tgname='trg_t1_guard_corretores_direct_compat_update'
    AND NOT t.tgisinternal;
  IF v_md5 IS DISTINCT FROM 'faf7f23f5e7c246a4500a7db9e518bc5' THEN
    RAISE EXCEPTION 'A2.1 rollback postflight: T1 compat trigger changed';
  END IF;
END
$postflight$;

COMMIT;
