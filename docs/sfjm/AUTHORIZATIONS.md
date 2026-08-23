# FECH.AI — SFJM Authorizations

**Status:** `AUTHORITY_PROVENANCE_LEDGER / T3A_CORRECTIVE_GITHUB_AUTHORITY_ACTIVE / FAIL_CLOSED / DOCUMENTATION_ONLY`
**Updated:** `2026-08-23`
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

## 3. ACTIVE_AUTHORITY — T3A corrective GitHub work

On 2026-08-23 Product Authority directed that the identified T3A problems be corrected, with the stated final objective of a secure app/database implementation and a functional rollback, while explicitly requiring governance, DevSecOps, specialist validation, deep/red-team analysis, no workarounds and avoidance of PR loops.

Durable bounded interpretation:

```text
Repository: wagnerjfjunior/fecha.ai
Workstream: T3A administrative password-reset multi-tenant authority boundary
Existing change set: continue the current T3A branch/PR; do not open another T3A PR merely for the same blocker set
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

The v2 candidate records corrective implementations for B1-B4. This authority
remains active only for publishing/reconciling those bounded artifacts in the
existing PR, updating its description/evidence and completing the required
read-only exact-head validation record. It does not turn a candidate statement
into a specialist PASS or authorize the next lifecycle transition.

This `ACTIVE_AUTHORITY` is for producing a corrected reviewable GitHub candidate in the existing T3A change set. It is not production mutation authority.

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

## 4. CONSUMED_AUTHORITY — SFJM new-conversation transition

On 2026-08-23 Product Authority explicitly requested use of SFJM to transition the work to a new conversation.

This authorizes the bounded documentation update necessary to preserve current T1/T2/T3A material meaning and next safe action on the existing T3A branch.

The transition documentation authority is consumed by publishing these SFJM updates. It does not create a new runtime/lifecycle permission.

## 5. Actions still requiring separate exact authority

The current corrective authority does **not** authorize these transitions by implication:

```text
mark PR Ready
merge PR
apply T3A migration to Supabase production
deploy criar-usuario Edge to production
execute production data normalization
execute destructive/adversarial production testing
execute rollback
alter unrelated frontend/runtime
Security Go
F1-02 final acceptance
WDP change
```

When applicable, each must be separately authorized after its prerequisite evidence/gate is established.

## 6. Production-testing boundary

Read-only production evidence gathering remains permitted when required by the active review/correction and when it does not expose PII unnecessarily.

Active production mutation/testing is not inferred from this ledger. In particular:

```text
no SQL trial-and-error
no production-as-lab
no cross-tenant mutation test without explicit bounded authority
```

## 7. Historical authority provenance

Where later lifecycle is independently established but exact historical authority evidence was not canonically recovered, use:

```text
AUTHORITY_PROVENANCE_NOT_RECORDED
```

Do not rewrite that as `UNAUTHORIZED` without affirmative evidence, and do not replay historical gates unless current safety materially requires it.

## 8. Update rule

Update this ledger only when durable authority meaning changes.

Do not update merely because a SHA, Draft/Ready state, check or mergeability value changes.
