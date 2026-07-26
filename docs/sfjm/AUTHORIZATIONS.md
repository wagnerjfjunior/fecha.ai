# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

An authority is valid only for its exact repository, target, environment, files or objects, operations, acceptance criteria, prohibitions and expiration condition.

General language such as `continue`, `implement`, `approve`, `go ahead` or `use the primary database` never silently authorizes Ready, merge, live Supabase application, runtime/frontend changes, fixtures, administrative role assignment, Security Go, F1-02 acceptance or WDP.

When scope, head, evidence or terminology is inconsistent, stop fail-closed.

## 2. Canonical baseline

```text
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4

PR #102: CLOSED / MERGED
PR #102 final head: 26395a5751ded7f3bc6908f36615f761d709199c
PR #102 squash / current main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
```

These authorities are consumed. They made the F1-02 program and controlled-beta strategy canonical but did not grant Security Go or unrestricted technical authority.

## 3. PR #103 freeze authority

The Product Authority directed that PR #103 remain frozen while the GPT3 evidence gateway is implemented in parallel.

```text
PR: #103
Base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
Head: abf6b4026343eae437283280269ed2997911dcec
State: OPEN / DRAFT
```

Authorized for PR #103:

```text
Read-only inspection: YES
Exact-head audit after gateway availability: YES
```

Not authorized for PR #103:

```text
Additional commits: NO
Metadata changes: NO
Ready: NO
Merge: NO
Supabase application: NO
Runtime tests: NO
```

## 4. PR #104 WINDOW_IMPLEMENTATION

**Source:** explicit Product Authority instruction on `2026-07-26` to start the approved parallel plan.  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** `main@b685b360404bbfd0a84a4b755b3092ee35a20e5e`  
**Branch:** `security/gpt3-supabase-catalog-gateway`  
**PR:** `#104`  
**Environment:** GitHub Draft implementation plus bounded read-only catalog validation.

Primary risk:

```text
Expose only the fixed PostgreSQL security metadata required by GPT3,
without exposing business rows, auth.users, secrets, arbitrary SQL or
caller-selected objects.
```

Authorized GitHub actions:

- create the branch from the exact base;
- add and update only the declared files;
- commit and push to the branch;
- create and update Draft PR #104;
- perform read-only GitHub validation;
- document evidence, rollback and SFJM state.

Authorized read-only Supabase action:

```text
Run the fixed catalog SELECT under SET LOCAL ROLE service_role
inside a transaction that ends in ROLLBACK.
```

Observed result:

```text
Query contract: EXECUTED
Persistent mutation: ZERO
Business-row reads: ZERO
auth.users reads: ZERO
Secret reads: ZERO
```

Authorized paths, exactly:

```text
supabase/migrations/20260726180000_gpt_security_metadata_snapshot.sql
supabase/functions/gpt-especialista/index.ts
docs/integrations/gpt3-supabase-action.openapi.yaml
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

The implementation window expires when the declared Draft scope is complete and the final Draft head is established. The final head is resolved from live PR metadata and the final PR description.

## 5. Explicit non-authorizations for PR #104

This implementation authority does not authorize:

- marking PR #104 Ready;
- merging PR #104;
- applying the migration to Supabase;
- creating `public.gpt_security_metadata_snapshot()` live;
- deploying the versioned Edge Function;
- changing the GPT Action live;
- changing `verify_jwt` live;
- rotating or reading secret values;
- accessing application rows or `auth.users`;
- executing arbitrary SQL;
- modifying PR #103;
- applying the PR #103 migration;
- granting Security Go, accepting F1-02 or awarding WDP.

## 6. Secret rotation record

The user declared that the previously exposed integration secret was rotated before this implementation continued.

```text
Secret name: GPT3_FECHAI_ESPECIALISTA
Secret value in GitHub/docs: PROHIBITED
Independent value verification: NOT PERFORMED
```

The declaration is recorded as Product Authority input, not as disclosure of the secret value.

## 7. Future authorities required

### `TECHNICAL_PR_LIFECYCLE`

Required separately for Draft → Ready and/or exact-head merge after independent audits.

### `CONTROLLED_BETA_PRIMARY_CHANGE`

Required separately for one exact live sequence identifying:

- project ref `uobxxgzshrmbtjfdolxd`;
- exact squash commit;
- exact migration;
- exact Edge Function source;
- exact OpenAPI version;
- operator and order;
- preflight, smoke, monitoring and stop conditions;
- rollback and expiration.

### `SECURITY_GATE`

Required for any later Security Go or F1-02 acceptance decision. It cannot retroactively authorize missing evidence.

## 8. Current authority state

```text
PR #104 implementation window:
ACTIVE ONLY UNTIL DECLARED DRAFT SCOPE IS COMPLETE

Further commits after final Draft head:
NOT AUTHORIZED

PR #104 Ready:
NOT AUTHORIZED

PR #104 merge:
NOT AUTHORIZED

Live Supabase / Edge / Action application:
NOT AUTHORIZED

PR #103 change/application:
NOT AUTHORIZED

Security Go:
DENIED

F1-02:
ACTIVE REMEDIATION / BLOCKED

WDP:
0
```
