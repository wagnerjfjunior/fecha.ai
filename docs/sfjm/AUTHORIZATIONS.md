# FECH.AI — SFJM Authorizations

**Status:** `AUTHORITY_PROVENANCE_LEDGER / PR149_READY_AUTHORIZED / BOUNDED_DOC_COMMITS_TO_READY / MERGE_NOT_AUTHORIZED / PRIOR_ROUTINE_ANCHOR_AUTHORITY_NOT_REUSABLE`
**Updated:** `2026-08-28`
**Repository:** `wagnerjfjunior/fecha.ai`

## 0. Current authority reconciliation — 2026-08-28

Product Authority explicitly authorized one bounded documentation-only transition. Its **write authority is consumed** by publication of Draft PR #149; read-only exact-head validation does not grant any new mutation authority:

```text
Repository: wagnerjfjunior/fecha.ai
Purpose: reconcile M0 / Issue #142 into canonical SFJM continuity
Branch/PR: one Draft PR only
Allowed:
  update only necessary SFJM continuity documentation
  create the branch and Draft PR
  perform read-only exact-head validation
Not authorized:
  Ready
  merge
  deploy
  Supabase
  runtime
  SQL
  closing/rebasing/merging legacy PRs
  unrelated implementation
```

The August 25 §3 record labeled `ACTIVE_AUTHORITY — live routine inventory anchor refresh` is preserved below as historical authority provenance but is **not reusable as current operational authority**. Subsequent material lifecycle transitions, including PR #130 and later program changes, invalidate its use as the present next-action grant. Any future runtime, Supabase, Ready, merge or implementation action requires fresh exact Product Authority authorization.

This section does not retroactively relabel historical execution as unauthorized. It only prevents stale continuity from being replayed as current authority.

## 0.1. PR #149 Ready and bounded correction authority — 2026-08-28

After Draft PR #149 was published and exact-head documentation validation passed, Product Authority separately authorized:

```text
1. transition PR #149 from Draft to Ready;
2. after that transition exposed stale continuity wording, make new documentation
   commits as necessary until the same PR is coherent and remains Ready.
```

Bounded scope of the current grant:

```text
Repository: wagnerjfjunior/fecha.ai
PR: #149
Branch: docs/sfjm-m0-security-to-scale-reconciliation
Allowed:
  modify only the same necessary SFJM continuity files already in PR #149
  record the authorized/executed Ready lifecycle transition
  perform read-only exact-head validation after the corrections
  mark Ready again only if the corrective commits cause the PR to become Draft
Stop condition:
  PR #149 OPEN / READY on the validated final head
Not authorized:
  merge
  deploy
  Supabase
  SQL
  runtime/Auth testing
  closing/rebasing/merging legacy PRs
  unrelated implementation
```

The Draft -> Ready authority was consumed by the successful transition. The bounded documentation-correction authority is consumed when final exact-head validation confirms PR #149 is coherent and Ready. It grants no merge authority.

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

## 3. HISTORICAL_AUTHORITY_RECORD — live routine inventory anchor refresh

PR #129 closed the PL/pgSQL role-alias collision, received fresh exact-head
Backend/Data and independent AppSec approval, and merged as
`69f4cfa1bdee331826953b492f25c12b4defc030`. The exact merged migration was
then invoked once under the applicable production authority. It advanced past
the alias correction and aborted fail-closed at
`T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT` before DDL. No migration
history entry or T3 object exists. That second application authority is
consumed; no automatic retry occurred.

Fresh read-only production evidence isolated the current full-inventory anchor:

```text
historical reviewed full routine digest: b1f0919df8a0acaca7bbea2b928b0ffe
current live full routine digest:       c299bf087df69f960dd0c611d1486675
routine count: 264 -> 264
authenticated SECURITY DEFINER subset:
  122 / 7faa376a403c69239d9606559cf9c2db -> UNCHANGED
aggregate count: 0 -> 0
changed live helper: extensions.grant_pg_graphql_access()
```

On `2026-08-25`, Product Authority authorized:

```text
Repository: wagnerjfjunior/fecha.ai
Base: live main 69f4cfa1bdee331826953b492f25c12b4defc030
Branch: security/t3a-live-routine-anchor-refresh
Authorized GitHub-side work:
  update the complete live routine inventory anchor in forward migration
    preflight and postflight
  apply the identical anchor refresh to rollback preflight and postrollback
  preserve the routine count, authenticated-effective SECURITY DEFINER
    count/digest, aggregate count and every other SQL/security expectation
  update directly-related evidence and SFJM
  create one Draft PR
  perform read-only exact-head validation
  prepare manual Backend/Data and AppSec review material
Required sequence:
  Backend/Data exact-head review
  independent AppSec exact-head review only after Backend/Data closure
  stop in Draft before Ready
```

At that historical transition, Product Authority also bounded exactly one later production migration
application after the two exact-head reviews. That historical statement is not current operational authority and is not reusable without a fresh explicit grant. At the time it was recorded it was not yet
exercisable: it requires authentication of the final reviewed/merged SQL bytes
and resolution of the separate Ready/merge lifecycle gates. It does not permit
trial-and-error, a different head, automatic retry or more than one invocation.

Not included in this current action:

```text
Ready
merge
Edge deployment
runtime/Auth call or smoke
rollback
Security Go
```

The former PR #128 and PR #129 GitHub/production authorities are consumed.

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

The audit POST 400 observed in those calls was the material event supporting
the now-consumed PR #128 GitHub correction. It was not authority to deploy its
fix.

## 5. CONSUMED_AUTHORITY — SFJM new-conversation transition

On 2026-08-23 Product Authority explicitly requested use of SFJM to transition the work to a new conversation.

This authorizes the bounded documentation update necessary to preserve current T1/T2/T3A material meaning and next safe action on the existing T3A branch.

The transition documentation authority is consumed by publishing these SFJM updates. It does not create a new runtime/lifecycle permission.

## 6. Actions still requiring separate exact authority or open preconditions

```text
mark the anchor-refresh PR Ready
merge the anchor-refresh PR
any future T3A production migration invocation without a fresh explicit
  Product Authority authorization bound to the then-current exact objects,
  environment, rollback and validation plan
deploy another Edge version
execute runtime/Auth or adversarial smoke
execute rollback
alter unrelated frontend/runtime
Security Go
F1-02 final acceptance
WDP change
```

Neither failed application created an automatic retry. No future production
invocation exists under current authority. The historical §3 grant is provenance
only and is not reusable; any later T3A production migration invocation requires
a fresh explicit Product Authority authorization for the then-current exact
objects and environment.

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
