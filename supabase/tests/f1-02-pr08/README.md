# FECH.AI — F1-02 / J4 / PR-08 executable security matrix

Status: VERSIONED_HARNESS / NOT_EXECUTED

Base application snapshot:

    9d05c64281c2aeeae9d67b139eab674720184fb1

## PR-08 v3 evidence contract

    REQUEST / PROBE SPECS: VERSIONED IN matrix.json
    FIXTURE: VALUES + TOKENS/SECRETS ONLY
    TOPOLOGY PREFLIGHT: MANDATORY / VERSIONED
    ARBITRARY FIXTURE URL / METHOD / ASSERTION: FORBIDDEN
    DENY: EXACT STATUS + EXPECTED ERROR EVIDENCE
    POSITIVE SEMANTICS: VERSIONED ASSERTIONS
    EXPLICIT CASE SELECTION: REQUIRED
    FULL HTTP MATRIX: ONLY WITH EXPLICIT --all
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

## Fixture topology preflight

The HTTP fixture carries only target_project_ref, environment, fixture_version and variables.
Before any selected test executes, the runner evaluates the versioned topology contract.
The preflight proves the relationships used by the matrix, including:

- actor token -> actor user/profile/company;
- manager token/profile and managed team;
- admin token/profile;
- local vs foreign companies, lists, brokers and teams;
- target lead ownership;
- wrong-owner lead in the same tenant;
- foreign lead in another tenant;
- valid, inactive and foreign stages;
- own-company and foreign-company stage sets;
- a zero-stage tenant;
- same-session idempotency preconditions for replay/mismatch/incomplete cases.

If a topology relation is absent, ambiguous or inconsistent, execution fails before the business test.

## Denial semantics

A DENY case no longer passes because of any generic 4xx.
Each DENY record versions exact allowed HTTP status values and at least one expected error signal:

- exact RPC error text;
- exact function error code; or
- a bounded semantic regex where the historical contract does not expose a stable code.

The runtime receipt records the actual sanitized error code/evidence even when the denial is a PASS.

## Mutation-target evidence

Before/after probes are bound to the object actually exposed to mutation risk.
Cross-tenant, wrong-owner and mismatch cases probe the foreign/wrong-owner/mismatch target where applicable instead of proving only that an unrelated local row stayed unchanged.

## Positive semantic assertions

HTTP 2xx plus CHANGED is not enough for nontrivial positive cases.
The v3 matrix versions content assertions such as:

- STG own-stage set equality, foreign-stage exclusion, deterministic ordering and zero-stage empty result;
- ACL returned list/selected target plus persisted visibility target;
- FUN final lead stage plus new history row tenant/stage consistency;
- FDB expected feedback/status state;
- COR expected profile/status/team state;
- CRM positive import shape and expected row delta.

## Import/idempotency evidence

IMP-001 and IMP-003 now probe three independent artifacts:

    lead with the synthetic phone
    importar_leads_batch_idempotency marker
    import log for the session

A PASS requires one new logical lead, one new marker, one new log, unique phone cardinality and canonical response agreement.
IMP-003 additionally retains the existing positive-overlap requirement.

IMP-002 independently proves one logical mutation in each tenant for the same textual session.
IMP-010 proves the expected bounded multi-lead delta.
IMP-011 proves zero additional mutation for an already completed replay.

## Explicit selection

The HTTP runner fails with no case IDs.
Examples of the only valid selection models are conceptually:

    <one or more explicit HTTP test IDs>
    --all

The --all flag must be exclusive. Technical ability to execute the runner is not execution authority.

## Rollback/reapply

The previous v2 rollback hardening is preserved unchanged:

- production project/host hard deny;
- one ROL case per invocation;
- exact artifact provenance;
- initial / post-rollback / post-reapply public-state SHA-256;
- PASS only when rollback changes state and reapply restores the exact initial hash.

No rollback/reapply was executed by this correction.

## Coverage

    AUTH 5 | COR 13 | CRM 15 | FUN 8 | ACL 10
    STG 7 | IMP 16 | FDB 11 | ROL 11 | PRD 2
    TOTAL 98

All PR-08 execution-result fields remain NOT_EXECUTED.
The 33 earlier operating-session results remain bounded continuity evidence only and are not canonical PR-08 receipts.

## Current authority

    runtime matrix: NOT AUTHORIZED
    Auth matrix: NOT AUTHORIZED
    rollback/reapply execution: NOT AUTHORIZED
    production smoke: NOT AUTHORIZED
    Supabase/Auth mutation: NOT AUTHORIZED
    LAB / second project / Preview Branch: NOT AUTHORIZED
    Vercel/deploy: NOT AUTHORIZED
    Ready: NOT AUTHORIZED
    merge: NOT AUTHORIZED
    OC-01: NOT AUTHORIZED
    PR-09: NOT AUTHORIZED
    Security Go: NOT_GRANTED

Only local/static validation is authorized at this implementation stage.

    VERSIONED != EXECUTED
    PR08_IMPLEMENTED != J4_EVIDENCE_GATE_PASSED
    J4_EVIDENCE_GATE_PASSED != SECURITY_GO
