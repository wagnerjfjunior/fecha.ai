# FECH.AI - PR 63 - local grant-hardening evidence

Date: 2026-06-05
Status: HOLD / LOCAL_TESTS_PASS / NOT_APPLIED_TO_SUPABASE
Type: Classe A / grant-hardening / single-rpc
Target RPC: public.aprovar_rejeitar_mesa

## Scope

The migration removes EXECUTE from public and anon while preserving authenticated.
Supabase production was not changed.
There was no db push, real RPC call, production use, real data, credentials, or secrets.

## Local evidence

- LOCAL_TEST_EXISTING_FUNCTION: PASS
  - Before: anon=true, authenticated=true, public=true
  - After: anon=false, authenticated=true, public=false
- LOCAL_TEST_EMPTY_REPLAY: PASS
  - Result: RAISE NOTICE + no-op + COMMIT without error
- LOCAL_TEST_OVERLOAD_ABORT: PASS
  - Result: expected RAISE EXCEPTION when 2 overloads exist

## Remaining controls

Controlled production tests have not been executed.
Merge remains blocked until the production runbook, backup, post-check, and sanitized evidence are complete.
Documentary rollback and manual SQL rollback are already documented in the migration.
