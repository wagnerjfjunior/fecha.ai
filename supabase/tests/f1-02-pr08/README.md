# FECH.AI — F1-02 / J4 / PR-08 executable security matrix

Status: VERSIONED_HARNESS / NOT_EXECUTED

Base application snapshot:

    9d05c64281c2aeeae9d67b139eab674720184fb1

## PR-08 v6 closure architecture

    MATRIX: 98 VERSIONED CASES
    TOPOLOGY CHECKS: 56
    SERVER CASE PLANS: 72
    MUTATION-CAPABLE HTTP CASES: 71
    MUTATION-CAPABLE WITHOUT LIFECYCLE: 0
    REQUEST/PROBE SPECS: VERSIONED
    RUNTIME RESULT FIELDS: NOT_EXECUTED
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

## Anti-loop closure rule

PR-08 v6 treats the test harness itself as a security-sensitive subsystem.
The harness is closed by invariant classes instead of repeated per-test patches:

1. every mutation-capable HTTP case, including DENY cases, has a server lifecycle;
2. every versioned request token has a topology identity binding;
3. privileged cases add role/scope topology, not only token identity;
4. every stateful lifecycle requires scoped restoration plus a global public-data hash;
5. cleanup mismatch is fail-stop and no next case may run;
6. conditional product rules become NOT_APPLICABLE when the prerequisite does not exist;
7. protected evidence tables remain inaccessible to client REST/JWT;
8. owner-side evidence is isolated non-production only and cannot widen grants/RLS/policies;
9. the evidence observer is globally identity-bound, while absence proofs use owner-side zero-row evidence under the BYPASSRLS preflight;
10. restoration fingerprints canonicalize logical public relation multisets plus sequence state rather than hashing raw data-dump row order.

These are reusable harness rules for future FECH.AI security matrices.

## Protected idempotency evidence

public.importar_leads_batch_idempotency remains protected by PR-07:

    owner = postgres
    RLS = ON
    FORCE RLS = ON
    client policies = 0
    anon/authenticated/service_role direct SELECT/INSERT/UPDATE/DELETE = none

No PR-08 REST/client request reads that table.
Marker evidence and deterministic precondition setup use the owner-side psql channel only in a separately authorized isolated non-production environment.

SERVER-EVIDENCE-PREFLIGHT now requires:

    current_user = postgres
    postgres.rolbypassrls = true
    PR-07 idempotency boundary remains exact
    production project ref is hard-denied

No grant, policy, RLS or schema widening is introduced.

## Topology closure

The runner executes only:

    global topology checks
    + dependencies of the selected case

Every valid identity-bearing token used by a versioned request/probe/topology surface must have a matching token-identity topology check. INVALID_TOKEN and EXPIRED_TOKEN are explicit negative-token fixtures, not identity-bearing exceptions.

EVIDENCE_OBSERVER_TOKEN is globally bound through /auth/v1/user to EVIDENCE_OBSERVER_USER_ID. Positive observer reads fail closed if visibility is insufficient. Absence claims such as no-profile and zero-stage-company are not inferred from observer REST invisibility; they use postgres-owner zero-row evidence after the existing non-production BYPASSRLS boundary preflight.
Actor/manager/admin/root/inactive/ineligible/no-profile/actor-A/actor-B cases add their required profile checks.

Manager ACL positive scope proves:

    manager identity/profile
    managed team
    list belongs to managed team
    target broker belongs to managed team

ROOT cases prove both:

    active broker profile
    public.admins role=admin_global and ativo=true through owner-side topology

## STG-001 and FUN-006 contract corrections

STG-001 now sends no Authorization/session. It no longer duplicates an authenticated request.

FUN-006 follows the Master Plan literally:

    transition rules exist -> execute invalid-transition denial test
    transition rules absent -> NOT_APPLICABLE

NOT_APPLICABLE is never converted into PASS.

## Failure isolation for negative cases

All 71 mutation-capable HTTP cases have a server lifecycle, including negative tests.
A DENY case that unexpectedly mutates state is therefore handled as:

    capture original
    execute case
    observe unexpected mutation
    FAIL
    cleanup scoped surfaces
    restore sequences
    compare global public-data SHA-256
    stop before the next case if restoration is not exact

This prevents a discovered security defect from contaminating later --all cases.

## Global restoration proof

For every stateful lifecycle the runner records a canonical logical public data-plane fingerprint:

    enumerate public ordinary/materialized relations deterministically
    -> convert each row to jsonb
    -> order the row multiset by jsonb text
    -> hash the exact canonical row text per relation
    -> include row counts and public sequence last_value/is_called state
    -> stable SHA-256

Sequence values are carried as text to avoid JavaScript bigint precision loss. This avoids treating heap/physical row-order changes from DELETE/INSERT/UPSERT cleanup as logical state drift. Public sequence state is restored before the final fingerprint.

PASS/FAIL of the business assertion is separate from cleanup integrity.
A cleanup mismatch raises PR08_CASE_CLEANUP_NOT_RESTORED and aborts further execution.

## ACL restoration

ACL lifecycle snapshots/restores:

    full target listas row, including escopo_distribuicao
    complete lista_visibilidade set for the list
    audit_logs side effects
    global public-data hash

Positive ACL cases first make the requested target absent deterministically, then restore the original ACL set after the case.

## Broker and T3 restoration

Broker lifecycles snapshot the complete corretores row and audit_logs side effects.

COR-011 does not bypass the password-state guard.
It versions the existing T3 flow:

    t3_issue_admin_password_reset_edge_proof
    -> t3_prepare_admin_password_reset using ADMIN_JWT_CLAIMS
    -> t3_release_admin_password_reset_lease
    -> actor HTTP marcar_senha_inicial_definida

If cleanup finds must_change_password still true, it uses the same self-service completion contract with ACTOR_JWT_CLAIMS.
Proof/lease state, broker row and audit state must return to the exact original state.

## Distribution fail-safe

solicitar_lote receives no LISTA_ID argument.
Therefore COR-008 cannot pretend that a single-list snapshot is sufficient.
Its isolated non-production lifecycle snapshots/restores the full distribution data surfaces:

    public.listas
    public.lotes
    public.leads
    ineligible broker row
    audit_logs

plus global public-data hash.

## Import/idempotency

Replay, list-mismatch, payload-mismatch and incomplete-state setup are deterministic and versioned.
Import namespaces are cleaned before seeded cases and cleaned after execution.
List counters, synthetic leads, marker rows, logs and sequence state participate in restoration.

IMP-001 and IMP-003 still require one logical import effect.
IMP-003 additionally requires true request-window overlap.
Neither case has been executed by this implementation.

## Rollback/reapply

The rollback runner remains non-production-only and one-case-per-invocation.
Rollback/reapply uses a composite state fingerprint:

    pg_dump --schema-only --schema=public --no-comments --format=plain
    --restrict-key=FECHAIPR08STATEHASH
    +
    canonical public relation-multiset + sequence-state SHA-256

The schema component preserves grants/policies/functions/DDL sensitivity while the data component is independent of physical heap row order.

ROLLBACK_REAPPLY remains NOT_DETERMINED because the runner has not been executed.

## Closure validator v6

validate_matrix.mjs rejects regressions in:

- 98-case coverage and exact application/migration provenance;
- mutation-capable cases without lifecycle;
- negative failure paths without cleanup contracts;
- token identity topology omissions across request/probe/topology surfaces;
- observer identity-binding regressions and client-visibility-based absence proofs;
- manager/root/actor-A/actor-B scope omissions;
- STG-001 authenticated regression;
- FUN-006 unconditional regression;
- ACL incomplete list/ACL/audit restoration;
- broker audit omission;
- COR-011 non-T3 lifecycle;
- COR-008 single-list false isolation;
- owner evidence without postgres BYPASSRLS proof;
- missing canonical logical global data fingerprint, sequence restoration or cleanup fail-stop;
- missing runner support for any lifecycle kind;
- protected idempotency REST access;
- rollback hashing without fixed restrict key;
- residual-status or execution-result overclaim.

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
    STATIC CLOSURE != RUNTIME PASS
    IMP-003 NOT_DETERMINED != PASS
    ROLLBACK_REAPPLY NOT_DETERMINED != PASS
    PR08_IMPLEMENTED != J4_EVIDENCE_GATE_PASSED
    J4_EVIDENCE_GATE_PASSED != SECURITY_GO
