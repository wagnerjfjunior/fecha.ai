# FECH.AI — F1-02 / J4 / PR-08 executable security matrix

Status: VERSIONED_HARNESS / NOT_EXECUTED

Base application snapshot:

    9d05c64281c2aeeae9d67b139eab674720184fb1

## Execution/evidence contract

PR-08 versions the execution definition itself.

    REQUEST / RESPONSE / MUTATION-PROBE SPECS: VERSIONED IN matrix.json
    FIXTURE: VALUES + TOKENS/SECRETS ONLY
    ARBITRARY FIXTURE URL / METHOD / PROBE: FORBIDDEN
    TARGET ORIGIN: https://<target_project_ref>.supabase.co
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

The external HTTP fixture may contain only target_project_ref, environment, fixture_version and variables.
It cannot define cases, URLs, paths, methods, assertions or mutation probes.
All IDs, tokens, keys and synthetic values remain out of the repository.

## HTTP target binding

Every request and every before/after probe is built from a versioned relative path_template.
The runner derives the only permitted origin from target_project_ref and fails closed if the final origin/hostname differs.
Declaring a non-production project ref while pointing a request at production is therefore not a valid execution path.

## Mutation evidence

The fixture cannot assert mutation success.
The runner executes the versioned before and after probe plans, recursively canonicalizes returned JSON and records SHA-256 fingerprints.

actual_data_mutation contains:

    observed = UNCHANGED | CHANGED
    before_sha256
    after_sha256
    expected = MUST_EQUAL | MUST_CHANGE

No fixture-asserted mutation PASS mode exists.

## Concurrent evidence

Concurrent cases record started_at, finished_at and duration_ms per request.
The receipt records calculated overlap. PASS requires positive overlap at or above the versioned minimum.
Promise.all by itself is not treated as concurrency evidence.
This applies to IMP-003 and FUN-008.

## Coverage

    AUTH 5 | COR 13 | CRM 15 | FUN 8 | ACL 10
    STG 7 | IMP 16 | FDB 11 | ROL 11 | PRD 2
    TOTAL 98

The 33 earlier STG/IMP/FDB operating-session results remain bounded continuity evidence only.
They do not pre-populate a PR-08 PASS receipt.

## Migration provenance

exact_application_commit is the application snapshot and is not a migration commit.
Every migration artifact is bound to path, exact blob and final_commit.
final_commit is the Git commit that produced the exact artifact blob.
Each record's exact_migration_commits is derived from those artifact commits.
Rollback file artifacts also carry their exact final commit. ROL-001 uses the exact rollback block embedded in the password-state migration.

## SQL cases

runtime_security_matrix.sql versions two explicit cases:

- PRD-001: read-only aggregation of the existing B2/B3/B4/PR07 proofs.
- IMP-CLAIMANT-ROLLBACK: BEGIN -> importar_leads_batch -> ROLLBACK, followed by read-only assertions that no lead, idempotency marker or import log residue remains.

Neither case was executed while implementing this correction.

## Rollback/reapply runner

The rollback runner is for a future separately authorized isolated non-production environment only.
It fails closed unless the project ref is not production, the environment label is not production, the DB hostname exactly matches db.<target_project_ref>.supabase.co, exactly one ROL case is selected, and separate authorization flags are present.

For that one case it records SHA-256 over a full plain public pg_dump:

    initial
    after rollback
    after reapply

PASS requires after rollback != initial and after reapply == initial.
The runner records only hashes, not dump contents. Multi-case execution is rejected to prevent case-to-case contamination.

Production project ref remains hard-denied:

    uobxxgzshrmbtjfdolxd

## Static validator

validate_matrix.mjs checks exact 98-case coverage, unique IDs, required J4 fields, exact application snapshot, exact migration/rollback final commit provenance, no pre-populated PASS, versioned request/probe plans, relative-path-only HTTP specs, forbidden fixture request authority, target-origin binding, deterministic mutation fingerprints, concurrency timing/overlap, one-case rollback isolation/state restoration, claimant rollback SQL plan, obvious committed UUID/JWT leakage, and preservation of both residual NOT_DETERMINED states.

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
