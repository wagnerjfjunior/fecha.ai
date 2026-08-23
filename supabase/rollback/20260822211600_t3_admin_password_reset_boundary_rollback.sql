-- FECH.AI — T3A-v1 rollback
-- This rollback restores the pre-T3A database compatibility surface.
-- Operational order if later authorized:
-- 1. Execute this SQL rollback. The still-hardened Edge then fails closed
--    because the T3A RPC is absent and therefore cannot change Auth.
-- 2. Re-deploy the versioned criar-usuario v17 baseline from commit
--    23ba5d03e146e50cb510c065e70e2c8e5ed9794a.
-- 3. Confirm the Edge runtime matches the v17 baseline.
--
-- This rollback intentionally does NOT rewrite business data or flip
-- must_change_password back to false. Such a data mutation could silently
-- weaken the mandatory-password contract for users already reset under T3A.

begin;

drop function if exists public.t3_prepare_admin_password_reset(uuid);
grant update (must_change_password) on table public.corretores to authenticated;

do $postrollback$
begin
  if to_regprocedure('public.t3_prepare_admin_password_reset(uuid)') is not null then
    raise exception 'T3A_ROLLBACK_FUNCTION_STILL_PRESENT';
  end if;

  if not has_column_privilege('authenticated', 'public.corretores', 'must_change_password', 'UPDATE') then
    raise exception 'T3A_ROLLBACK_COMPAT_GRANT_NOT_RESTORED';
  end if;
end
$postrollback$;

commit;
