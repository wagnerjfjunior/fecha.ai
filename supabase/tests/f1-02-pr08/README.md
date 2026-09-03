# FECH.AI — F1-02 / J4 / PR-08 executable security matrix

Status: `VERSIONED_HARNESS / NOT_EXECUTED`

This directory implements the J4/PR-08 matrix contract without claiming that
runtime, Auth, rollback/reapply or production smoke was executed.

## Authority boundary

Implementation base:

```text
9d05c64281c2aeeae9d67b139eab674720184fb1
```

Standing constraints:

```text
NO LAB
NO SECOND SUPABASE PROJECT
NO PREVIEW BRANCH
NO PRODUCTION MIGRATION ROLLBACK TEST
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
```

The current Product Authority grant covers only versioning this harness and
local/static validation. It does not authorize any runner execution.

## Files

- `matrix.json` — machine-readable source of truth for all PR-08 records.
- `runtime_security_matrix.sql` — read-only aggregator for the four existing
  F1-02 catalog/static proofs.
- `scripts/tests/f1-02-pr08/run_auth_http_matrix.mjs` — generic HTTP runtime
  executor. Synthetic fixture details and all credentials/tokens remain outside
  the repository.
- `scripts/tests/f1-02-pr08/run_rollback_reapply.mjs` — isolated-environment
  rollback/reapply executor with a hard deny for production project
  `uobxxgzshrmbtjfdolxd` and its database host.
- `scripts/tests/f1-02-pr08/validate_matrix.mjs` — local/static contract
  validator.

## Coverage

```text
AUTH  5
COR  13
CRM  15
FUN   8
ACL  10
STG   7
IMP  16
FDB  11
ROL  11
PRD   2
TOTAL 98
```

The 33 earlier STG/IMP/FDB operating-session results are preserved only as
`OPERATING_SESSION_RUNTIME_EVIDENCE`. They do not set any PR-08
`pass_fail` field to PASS and do not create a canonical executable receipt.

## Required execution record fields

Every matrix record contains the mandatory J4 fields:

```text
test_id
requirement_id
exact application commit
exact migration commit(s)
Supabase project ref
environment
fixture version
synthetic actor
actor role
actor company/team
preconditions
action/request
sanitized payload description
expected authorization result
expected data mutation
actual authorization result
actual data mutation
sanitized error code
pass/fail
timestamp
evidence reference
```

Unexecuted runtime-specific fields are explicitly `REQUIRED_AT_EXECUTION`,
`NOT_EXECUTED` or `NOT_ESTABLISHED`; they are never guessed.

## HTTP fixture contract

The HTTP runner requires an out-of-repo JSON fixture named by
`FECHAI_PR08_HTTP_FIXTURE_FILE`. It must identify the target project,
environment and fixture version, then provide one entry per selected test ID.

Each case supplies:

- sanitized actor role/company-team labels;
- one request, or at least two `concurrent_requests` for concurrent cases;
- expected HTTP statuses;
- a before/after mutation probe;
- mutation probe mode: `MUST_EQUAL`, `MUST_CHANGE`, or
  `CUSTOM_ASSERTED_BY_FIXTURE`;
- optional sanitized body regex.

The runner will not start unless `FECHAI_PR08_EXECUTION_AUTHORIZED=YES`.
Production additionally requires both
`FECHAI_PR08_ALLOW_PRODUCTION=YES` and
`FECHAI_PR08_PRODUCTION_EXECUTION_AUTHORIZED=YES`.

Those switches are technical guards, not authority by themselves.

## Rollback/reapply runner

The rollback runner is designed only for a future separately authorized
isolated non-production environment. It refuses:

- project ref `uobxxgzshrmbtjfdolxd`;
- database hostname `db.uobxxgzshrmbtjfdolxd.supabase.co`;
- any run without `FECHAI_PR08_ROLLBACK_REAPPLY_AUTHORIZED=YES`;
- any run without `FECHAI_PR08_ISOLATED_ENVIRONMENT=YES`.

`ROL-001` uses the exact rollback block embedded in
`20260726023000_f1_02_password_state_rpc.sql`. The other ten ROL cases point
to exact versioned rollback files.

No rollback/reapply was executed while creating this PR.

## Static validation

The only validation permitted during implementation is the local/static
validator. It checks counts, unique IDs, mandatory fields, exact base binding,
absence of execution overclaim, residual statuses, rollback production guard,
and obvious committed JWT/UUID leakage.

The SQL preflight and both runtime runners remain unexecuted until separately
authorized.

## Evidence semantics

```text
VERSIONED != EXECUTED
OPERATING_SESSION_REPORTED_PASS != CANONICAL_EXECUTABLE_PR08_PASS
PR08_IMPLEMENTED != J4_EVIDENCE_GATE_PASSED
J4_EVIDENCE_GATE_PASSED != SECURITY_GO
```
