# FECH.AI — F1-02 / T1 — AppSec Gate 3 Rollback Remediation

**Status:** `PR_HEAD_ONLY / GATE_3_REQUEST_CHANGES_REMEDIATED / APPSEC_RETEST_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**PR:** `#125 — security: harden corretor status command`  
**Environment:** `Pilot Production / Supabase production is the only adopted DB environment`  
**Execution:** `NO SUPABASE WRITE / NO MIGRATION APPLY / NO READY / NO MERGE / NO DEPLOY`

## 1. Purpose

Record the third independent Application Security Assurance gate and the bounded remediation performed after its `REQUEST CHANGES` verdict.

This addendum preserves chronology. It does not rewrite the earlier evidence file or retroactively convert prior gates into PASS.

## 2. Gate 3 anchor and verdict

Gate 3 audited exact head:

```text
fd8a621c938c311ba8e83950e484e36a73868d9d
```

Base/main observed by the gate:

```text
827f8591bfe4eee595a1aa22e169dcf6465f7fa3
```

Gate 3 returned:

```text
VERDICT: REQUEST CHANGES
T1 TARGET CONTRACT: FAIL
MULTI-TENANT: PASS
AUTHORIZATION: PASS
ACL: PASS
CONCURRENCY: PASS
ROLLBACK: FAIL
READY: NO
PRODUCTION APPLICATION: NOT AUTHORIZED
SECURITY GO: DENIED / UNCHANGED
```

The material conclusion is narrow: authorization, tenant isolation, ACL and concurrency were accepted statically; the remaining blocking domain was rollback assurance.

## 3. Gate 3 blocking findings

### G3-F1 — exact trigger-set proof before mutation

The embedded rollback verifier iterated over T1 triggers that existed but did not first prove cardinality exactly `2`. A missing T1 trigger could therefore be discovered only after an earlier rollback mutation.

Classification: `REQUIRED IN THIS PR`.

### G3-F2 — function fingerprint did not bind owner/security/ACL

The apply-time function marker stored only the function-definition MD5. Rollback verification did not independently bind owner, `SECURITY DEFINER/INVOKER`, exact `search_path` and ACL for all five T1 functions.

Classification: `REQUIRED IN THIS PR`.

### G3-F3 — rollback audit-surface proof was incomplete

The forward apply preflight bound the critical audit trigger/function comprehensively, but the embedded rollback preflight did not revalidate all security metadata: function owner, security mode, search path and ACL.

Classification: `REQUIRED IN THIS PR`.

### G3-F4 — rollback postflight did not prove exact baseline restoration

The embedded postflight did not prove all baseline properties: exact function ACL, original table ACL, absence of temporary column ACLs, policy metadata, critical audit surface and absence of unexpected grants.

Classification: `REQUIRED IN THIS PR`.

## 4. Remediation strategy

The forward migration had already passed the Gate 3 authorization, multi-tenant, ACL and concurrency review. Rewriting the 1,500+ line migration only to change rollback mechanics would increase regression risk in already-accepted controls.

The repository already has a canonical rollback directory:

```text
supabase/rollback/
```

Therefore T1 now uses a separate executable canonical rollback artifact:

```text
supabase/rollback/20260822121500_f1_02_harden_status_corretor_rpc_rollback.sql
```

The commented rollback runbook embedded in the forward migration is superseded for operational use by this executable rollback artifact.

## 5. Canonical rollback properties

The new rollback artifact is not a forward migration and is not automatically executed.

It uses one transaction:

```text
BEGIN
→ fail-closed pre-rollback verifier
→ rollback mutations
→ exact post-rollback verifier
→ COMMIT
```

Any exception before `COMMIT` aborts the transaction.

### G3-F1 remediation

Before any rollback mutation, the verifier requires:

- all five expected T1 functions to exist;
- exactly two expected T1 triggers to exist;
- both triggers enabled;
- each trigger marker to match its current definition hash;
- each trigger to point to the expected trigger function.

A missing T1 trigger now fails before the first `DROP`.

### G3-F2 remediation

For each of the five T1 functions, preflight separately validates:

- owner = `postgres`;
- exact `SECURITY DEFINER/INVOKER` mode;
- exact `search_path=pg_catalog`;
- exact ACL;
- apply-time marker present;
- current function-definition MD5 equals the marker MD5.

Expected callable T1 functions have exact ACL:

```text
{postgres=X/postgres,authenticated=X/postgres}
```

Expected trigger functions have exact ACL:

```text
{postgres=X/postgres}
```

### G3-F3 remediation

The rollback preflight and postflight both validate the complete critical audit surface:

- trigger exists exactly by table/name;
- `tgenabled='O'`;
- exact `pg_get_triggerdef`;
- audit function owner = `postgres`;
- `SECURITY DEFINER=true`;
- exact `search_path=public`;
- exact function ACL;
- exact function body MD5 `3fdaca39d55f348ca36f796023f3260b`.

### G3-F4 remediation

Pre-rollback T1 state is bound by:

- exact table ACL target after T1;
- exactly three non-null column ACLs;
- only `ativo`, `apto_para_receber`, `must_change_password` may have temporary column ACL;
- each column ACL entry must be `authenticated / UPDATE / grantor postgres / not grantable`;
- T1 policy marker must match current expression hash;
- policy command, permissive mode and `polroles={0}` are independently checked.

Post-rollback exact baseline verifies:

- status RPC body MD5 `ef89d686ebb3230ae4bef1b71d4860fd`;
- status RPC owner/security/search_path/exact ACL and null comment;
- `corretores` table ACL MD5 `afa3a93809a23f744356971cbc461855`;
- no column-level ACL remains on `corretores`;
- original `corretores_update` expression MD5 `a3b9b4a44e859728ca9c69f6e6b2a842`;
- policy command/permissive/roles and null policy comment;
- no T1 trigger remains;
- no T1 helper/guard function remains;
- complete critical audit surface remains at the exact baseline.

## 6. Live READ_ONLY anchors used

No production mutation was executed.

READ_ONLY catalog evidence reconfirmed:

```text
corretores_update:
  polcmd = w
  polpermissive = true
  polroles = {0}
  expression MD5 = a3b9b4a44e859728ca9c69f6e6b2a842
  policy comment = NULL

corretores pre-T1 table ACL:
  {postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres,authenticated=rw/postgres}
  MD5 = afa3a93809a23f744356971cbc461855

corretores pre-T1 column attacl rows:
  0

critical audit function:
  owner = postgres
  SECURITY DEFINER = true
  search_path = public
  MD5 = 3fdaca39d55f348ca36f796023f3260b
  ACL = {postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

The expected T1 table ACL after revoking table-level authenticated `UPDATE` while retaining `SELECT` is versioned in the rollback preflight as:

```text
{postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres,authenticated=r/postgres}
```

The temporary column grants are independently proven rather than inferred from table ACL.

## 7. Evidence boundary

```text
ROLLBACK CODE WRITTEN != ROLLBACK EXECUTED
STATIC APPSEC REMEDIATION != APPSEC PASS
PR HEAD != MERGED
MERGED != SUPABASE APPLIED
SUPABASE APPLIED != RUNTIME VALIDATED
```

No lab database is adopted. Production must not be used as an offensive test environment.

## 8. Next gate

Resolve PR #125 live and audit the new exact head.

The next independent Application Security Assurance retest must include the new canonical rollback artifact and verify G3-F1 through G3-F4 against it.

No Ready, merge, Supabase application, deploy or Security Go is authorized by this evidence record.
