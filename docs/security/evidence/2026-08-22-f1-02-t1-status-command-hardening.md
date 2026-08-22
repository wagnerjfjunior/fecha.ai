# FECH.AI — F1-02 T1 Status Command Hardening

**Status:** `DRAFT_REVISED_AFTER_APPSEC_GATE_3_REQUEST_CHANGES / GITHUB_ONLY / NOT_APPLIED / REAUDIT_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  

> **Current evidence pointer:** Gate 3 accepted the T1 authorization, multi-tenant, ACL and concurrency domains and returned `REQUEST CHANGES` only for rollback assurance. The canonical current rollback remediation/evidence is now recorded in:
>
> `docs/security/evidence/2026-08-22-f1-02-t1-appsec-gate3-rollback-remediation.md`
>
> Canonical executable rollback artifact:
>
> `supabase/rollback/20260822121500_f1_02_harden_status_corretor_rpc_rollback.sql`
>
> The rollback runbook comments embedded in the forward migration are **superseded for operational rollback** by the executable rollback artifact above. Historical Gate 1/Gate 2 material below remains evidence of chronology and is not rewritten into PASS.

## Current material state

```text
T1 forward migration:
PR_HEAD_ONLY / NOT APPLIED

Application Security Gate 1:
REQUEST CHANGES / HISTORICAL

Application Security Gate 2:
REQUEST CHANGES / HISTORICAL

Application Security Gate 3:
REQUEST CHANGES / HISTORICAL

Gate 3 accepted:
MULTI-TENANT = PASS
AUTHORIZATION = PASS
ACL = PASS
CONCURRENCY = PASS

Gate 3 remaining blocker:
ROLLBACK = FAIL

Gate 3 rollback remediation:
IMPLEMENTED IN PR HEAD / REAUDIT REQUIRED

Ready:
NO

Merge:
NO

Production application:
NOT AUTHORIZED

Security Go:
DENIED / UNCHANGED
```

## Canonical current artifacts

```text
Forward migration:
supabase/migrations/20260822121500_f1_02_harden_status_corretor_rpc.sql

Canonical executable rollback:
supabase/rollback/20260822121500_f1_02_harden_status_corretor_rpc_rollback.sql

Gate 3 remediation evidence:
docs/security/evidence/2026-08-22-f1-02-t1-appsec-gate3-rollback-remediation.md
```

## Evidence boundary

```text
VERSIONED != APPLIED
APPSEC HISTORICAL PASS/FAIL != CURRENT-HEAD VERDICT
ROLLBACK CODE WRITTEN != ROLLBACK EXECUTED
MERGED != SUPABASE APPLIED
SUPABASE APPLIED != RUNTIME VALIDATED
```

No Supabase write, migration apply, Ready, merge, deploy, offensive production test or real-data mutation is authorized by this evidence record.

## Next gate

Resolve PR #125 live and run independent Application Security Assurance against the exact current head, reading the complete forward migration, canonical executable rollback and both evidence records. Any head movement invalidates the gate.
