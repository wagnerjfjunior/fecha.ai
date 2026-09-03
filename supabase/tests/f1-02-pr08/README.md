# FECH.AI — F1-02 / J4 / PR-08 executable security matrix

Status: VERSIONED_HARNESS / NOT_EXECUTED

Base application snapshot:

    9d05c64281c2aeeae9d67b139eab674720184fb1

## PR-08 v4 evidence contract

    MATRIX: 98 VERSIONED CASES
    REQUEST SPECS: VERSIONED
    FIXTURE: VALUES + TOKENS/SECRETS ONLY
    TOPOLOGY: GLOBAL + SELECTED CASE DEPENDENCIES ONLY
    SERVER EVIDENCE: PSQL / postgres OWNER / NON-PRODUCTION ONLY
    IDEMPOTENCY TABLE REST/CLIENT ACCESS: FORBIDDEN
    CASE ISOLATION: CAPTURE -> PREPARE -> CASE -> EVIDENCE -> CLEANUP -> RESTORE
    CLEANUP PASS: FINAL SHA-256 == ORIGINAL SHA-256
    FULL HTTP MATRIX: EXPLICIT --all ONLY
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

## Protected idempotency evidence

public.importar_leads_batch_idempotency remains intentionally unavailable to PUBLIC, anon, authenticated and service_role direct DML/SELECT under the PR-07 boundary.
PR-08 v4 therefore contains no REST/client-JWT request to that table.

When a stateful import case requires marker evidence, the future separately authorized harness uses an owner-side psql connection in an isolated non-production project.
The runner hard-denies the production project ref and requires the database hostname to bind exactly to the selected project.

Before owner-side evidence can run, runtime_security_matrix.sql case SERVER-EVIDENCE-PREFLIGHT verifies:

- current_user is postgres;
- idempotency table owner is postgres;
- RLS and FORCE RLS remain enabled;
- zero client policies remain;
- anon/authenticated/service_role have no direct SELECT/INSERT/UPDATE/DELETE.

No grant, policy or RLS widening is part of this harness.

## Per-case topology

The runner no longer executes every topology check for every selected test.
For each test it executes only:

    topology_contract.global_check_ids
    + record.topology_dependencies

Variable-relation checks are themselves versioned topology checks.
Unrelated manager/root/tenant/idempotency fixture variables are therefore not required by an unrelated STG, CRM or other case.

## Deterministic stateful lifecycle

Twenty stateful cases have a versioned server_case_plan.
All sixteen HTTP cases that expect business mutation are included.

The lifecycle is:

    capture original server state
    deterministic prepare
    capture test-before state
    execute selected HTTP request(s)
    capture test-after state
    evaluate semantic/delta assertions
    cleanup in finally
    capture cleanup-final state
    require cleanup-final == original

This isolation also applies when --all is explicitly selected, eliminating cross-case residue from successful runs.

## Deterministic idempotency setup

The following cases no longer depend on manually pre-created state:

- IMP-011: owner-side seed performs one canonical completed import, then HTTP replay proves zero additional mutation;
- IMP-SESSION-LIST-MISMATCH: seed establishes the canonical session/list state before testing a different list;
- IMP-SESSION-PAYLOAD-MISMATCH: seed establishes the canonical session/payload before testing a changed payload;
- IMP-INCOMPLETE-STATE: owner-side seed creates the exact incomplete marker with the same PR-07 request fingerprint algorithm.

Each seeded namespace is cleaned and the original list counters/state are restored after the case.

## Import namespaces and logical-mutation evidence

Stateful import cases use test-specific phone/session variables.
Owner-side snapshots observe, by synthetic namespace:

    list counters
    matching leads
    idempotency marker
    import logs

IMP-001 and IMP-003 require one lead + one marker + one log, exact positive counters, unique phone cardinality and canonical response agreement.
IMP-003 additionally retains the positive-overlap timing requirement.
IMP-002 proves independent tenant-scoped effects for the same textual session.
IMP-010 proves two bounded new leads with one marker and one log.
IMP-011 proves the entire server state remains unchanged during replay.

## Positive semantic evidence

COR-012 now proves ativo=false in both response and server state, then requires cleanup restoration to the original broker state.
COR-013 proves the target time after the RPC and restores the original broker state.
CRM-015 requires exact counters validos=1, invalidos=0, duplicados=0 plus lead/marker/log deltas.
FUN-007 and FUN-008 use server-side lead/history state and restore the original lead/history state after the case.
FDB-008 and FDB-009 observe status_comercial directly through the server evidence channel, prove feedback/stage/history semantics, prevent the synthetic lot from approaching auto-close, and restore the original lead/lot/history state.
ACL positive cases require a clean target row, prove the new target, then remove it and verify original-state restoration.

## Rollback/reapply state hashing

The rollback runner retains one-case isolation and production hard-deny.
Plain pg_dump state hashing now fixes:

    --restrict-key=FECHAIPR08STATEHASH

so random restrict-key output cannot invalidate the comparison.
PASS still requires post-rollback state to differ from initial and post-reapply state to equal initial.

## Static validator

validate_matrix.mjs now rejects:

- REST/client access to importar_leads_batch_idempotency;
- missing server lifecycle for a mutating or required stateful case;
- implicit replay/mismatch/incomplete preconditions;
- execution of all topology checks instead of selected-case dependencies;
- assertions against fields not selected by remaining HTTP probes;
- missing COR-012 active-state proof;
- missing strong server assertions for import/funnel/ACL/feedback positives;
- missing cleanup-restoration contract;
- rollback pg_dump without the fixed restrict key;
- runtime-result overclaim or residual-status drift.

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

Only repository/static validation is authorized at this implementation stage.

    VERSIONED != EXECUTED
    OWNER-SIDE EVIDENCE CHANNEL VERSIONED != CURRENTLY AUTHORIZED TO RUN
    PR08_IMPLEMENTED != J4_EVIDENCE_GATE_PASSED
    J4_EVIDENCE_GATE_PASSED != SECURITY_GO
