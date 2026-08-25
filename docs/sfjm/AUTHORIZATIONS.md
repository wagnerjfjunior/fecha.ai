# FECH.AI — SFJM Authorizations

**Status:** `AUTHORITY_PROVENANCE_LEDGER / PR128_AND_EDGE_V19_CONSUMED / MIGRATION_ATTEMPT_CONSUMED_FAIL_CLOSED / PLPGSQL_CORRECTIVE_GITHUB_AUTHORITY_ACTIVE / PRODUCTION_GATES_SEPARATE`
**Updated:** `2026-08-25`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, object, operation, scope, prohibitions and lifecycle transition granted by Product Authority.

```text
TOOL_CAPABILITY != AUTHORIZATION
ONE TRANSITION AUTHORITY != NEXT TRANSITION AUTHORITY
```

Use durable classes:

```text
ACTIVE_AUTHORITY
CONSUMED_AUTHORITY
AUTHORITY_PROVENANCE_NOT_RECORDED
```

## 2. Consumed T3A setup authorities

Product Authority separately authorized and those bounded actions were consumed:

```text
create T3A branch security/t3a-admin-password-reset-boundary from the authorized main anchor
version the live criar-usuario baseline and implement the initial T3A GitHub candidate
open the T3A Draft PR for review
perform read-only Backend/Data + AppSec-oriented review
```

Those consumed authorities do not authorize Ready, merge, Supabase application or Edge deployment.

## 3. ACTIVE_AUTHORITY — PL/pgSQL role-alias corrective Draft PR

PR #128 received the required exact-head reviews, merged as
`3c9daf6c49eb937824c2c2b40aba198e2727c4bb`, and its exact Edge was deployed
as production v19 under later separate authorities. One controlled call
returned the expected fail-closed 500, committed the audit row and produced no
Auth mutation.

Product Authority then separately authorized application of the exact reviewed
T3A migration. The application tool was invoked once. PostgreSQL aborted the
transaction in the first preflight with SQLSTATE 55000 because the declared
record `r` collided with the `pg_roles AS r` alias. No T3 object or migration
history record was created. That production-application authority is consumed.

On `2026-08-25`, after the failure, rollback confirmation and exact minimal
correction were stated, Product Authority authorized:

```text
Repository: wagnerjfjunior/fecha.ai
Base: live main 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
Branch: security/t3a-plpgsql-role-alias-collision
Authorized GitHub-side work only:
  rename conflicting pg_roles alias r -> role_row in forward pre/postflight
  apply the identical correction to rollback pre/postflight
  preserve the later loop record r and every catalog/security expectation
  update directly-related evidence and SFJM
  create one Draft PR
  perform read-only exact-head validation
  prepare manual Backend/Data and AppSec review material
Required sequence:
  Backend/Data exact-head review
  independent AppSec exact-head review only after Backend/Data closure
  stop in Draft before Ready
```

Not authorized:

```text
Ready
merge
another Supabase migration/application
Edge deployment
runtime/Auth call or smoke
rollback
Security Go
```

The former PR #128 audit-correction authority and its later Ready, merge, Edge
v19 deployment and single runtime-call authorities are consumed. They do not
carry into this corrective PR or a production retry.

## 4. CONSUMED_AUTHORITY — PR #127 correction, reviews and merge

On 2026-08-23 Product Authority directed that the identified T3A problems be corrected, with the stated final objective of a secure app/database implementation and a functional rollback, while explicitly requiring governance, DevSecOps, specialist validation, deep/red-team analysis, no workarounds and avoidance of PR loops.

Durable bounded interpretation:

```text
Repository: wagnerjfjunior/fecha.ai
Workstream: T3A administrative password-reset multi-tenant authority boundary
Existing change set at that time: continue the current T3A branch/PR; do not open another T3A PR merely for the same blocker set
Authorized GitHub-side work:
  correct Edge/migration/rollback/evidence artifacts required to resolve material T3A blockers
  update directly-related T3A/SFJM documentation needed for accurate continuity
  update the existing T3A PR description so it matches the final corrected scope
  perform read-only validation required to design/review the correction
Required safeguards:
  preserve multi-tenant isolation
  preserve T1/T2 security contracts
  fail closed
  no workaround/bypass
  exact rollback
  specialist validation on final exact head
```

Known required corrective domains at this transition:

```text
B1 safe rollout ordering
B2 trust-anchor preflight
B3 drift-safe rollback
B4 T1 guard interoperability
```

The manually relayed Backend/Data review of exact head `bf8fb1f...` returned
`REQUEST_CHANGES` for the DB-to-Auth authority race and non-transitive writer
detection. The v3 lease/fence correction was then reviewed at exact head
`4631325827a76152ba554bece2a59da9eb1bb662` / tree
`843bbc9c9f32f07e97713368e7e472fca9e650cd`; that second integral manual review
also returned `REQUEST_CHANGES`, closed HIGH-1, and left B2/B3 open for three
positive-closure defects:

```text
full bidirectional role-membership/options inventory
all routine kinds, including aggregates or a positive empty aggregate proof
complete public schema owner/ACL inventory
manual response SHA-256:
  1ab2b39d52536b0ba92cd25df4d91b808f25abd08be0c5de72146113c7cda544
```

Correcting all of these findings in the same PR was inside that bounded
authority. It covered publishing/reconciling the corrected artifacts,
updating the existing PR description/evidence and completing the required
exact-head validation record. It does not turn a candidate statement into
specialist PASS or authorize the next lifecycle transition.

The subsequent v3 candidate at exact head
`fcb7dfc2f5f2259926556652fa9cfd3443d0c214` / tree
`4dcaf2d4b6aa1248801e455def811e50ff04e414` received integral manual
Backend/Data `APPROVE` and independent AppSec `APPROVE`:

```text
Backend/Data response SHA-256:
  8b6bf96691b7337df95f0350ac5028a4aeb85e6cab917ec56383fc8e083ac0dc
AppSec response SHA-256:
  1df5df13786f7ba767340cca2ca546aeddbf92e81a307a48aef3107fc0cf64ca
```

Product Authority then separately authorized Ready, review and merge for that
reviewed candidate. Ready was performed, but the post-Ready GitHub Codex review
opened material P2 `DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`: the authenticated
preparation RPC could be called directly, creating durable fenced state without
the Edge Auth password mutation or a caller-accessible release. The PR was
returned to Draft and was not merged.

That material invalidation caused a same-PR v4 correction. Integral manual
Backend/Data and independent AppSec reviews both returned `APPROVE` with no
findings on exact head `a5c92617f372599a234c0147aad13a90649348d7` / tree
`87872aac22b36437b7fb66f3614905e8df94f5ee`. Product Authority then explicitly
authorized merge of PR #127, and that authority was consumed by merge commit
`610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87`.

No Supabase migration or Edge deployment was implied by that merge authority.

### Temporary specialist execution channel — manual while Router is frozen

On `2026-08-23`, Product Authority recorded that the SES Router/Action is not
available when specialist invocation originates inside the project, despite the
documented intended integration. Repeated live tests did not establish a usable
in-project Action path, so the Router is temporarily frozen for this workstream.

Until Product Authority restores that channel:

```text
do not invent or simulate a Gateway receipt
prepare an exact task/head-bound specialist prompt
Product Authority submits that prompt manually to the named specialist
Product Authority returns the specialist response integrally to this thread
validate that response against the same live exact head before recording it
run Backend/Data before the independent AppSec review
```

This is an execution-channel exception, not fuzzy role resolution and not
mutation authority. The adopted roles remain:

```text
backend_data -> backend-data-platform-specialist
application_security -> application-security-assurance-specialist
```

Manual specialist output must identify the repository, PR, exact head, material
files read and verdict. It cannot authorize Ready, merge or production.

### Consumed post-merge rollout authorities

Product Authority later authorized the Edge-first rollout separately from the
T3A migration and smoke. The exact reviewed Edge was deployed as v18; migration
remained unapplied. Product Authority then authorized temporary use of the
authenticated session for one fail-before-Auth call against a nonexistent or
dedicated safe target. Because the browser appeared frozen, three UI submissions
were emitted; all three failed closed and none reached an Auth update. This
bounded runtime authority is consumed and does not authorize another call.

The audit POST 400 observed in those calls is the material event supporting the
new active GitHub-only authority in §3. It is not authority to deploy its fix.

## 5. CONSUMED_AUTHORITY — SFJM new-conversation transition

On 2026-08-23 Product Authority explicitly requested use of SFJM to transition the work to a new conversation.

This authorizes the bounded documentation update necessary to preserve current T1/T2/T3A material meaning and next safe action on the existing T3A branch.

The transition documentation authority is consumed by publishing these SFJM updates. It does not create a new runtime/lifecycle permission.

## 6. Actions still requiring separate exact authority

```text
mark the alias-corrective PR Ready
merge the alias-corrective PR
apply/retry T3A migration in Supabase production
deploy another Edge version
execute runtime/Auth or adversarial smoke
execute rollback
alter unrelated frontend/runtime
Security Go
F1-02 final acceptance
WDP change
```

The single failed application does not authorize a retry.

## 7. Production-testing boundary

Read-only production evidence gathering remains permitted when required by the active review/correction and when it does not expose PII unnecessarily.

Active production mutation/testing is not inferred from this ledger. In particular:

```text
no SQL trial-and-error
no production-as-lab
no cross-tenant mutation test without explicit bounded authority
```

## 8. Historical authority provenance

Where later lifecycle is independently established but exact historical authority evidence was not canonically recovered, use:

```text
AUTHORITY_PROVENANCE_NOT_RECORDED
```

Do not rewrite that as `UNAUTHORIZED` without affirmative evidence, and do not replay historical gates unless current safety materially requires it.

## 9. Update rule

Update this ledger only when durable authority meaning changes.

Do not update merely because a SHA, Draft/Ready state, check or mergeability value changes.
