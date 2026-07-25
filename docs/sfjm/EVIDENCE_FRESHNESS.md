# FECH.AI — SFJM Evidence Freshness

**Status:** `ACTIVE_FRESHNESS_RULES / CONTROLLED_BETA_PRIMARY_STRATEGY_DRAFT / FAIL_CLOSED`  
**Observed on:** `2026-07-25`

## 1. Purpose

Freshness determines whether an observation may support a current decision. Fresh evidence is not automatically correct or sufficient.

## 2. Classes

```text
CURRENT
STALE
SUPERSEDED
NOT_VERIFIED
NOT_APPLICABLE
```

## 3. General invalidation rules

| Evidence | CURRENT condition | Invalidating event |
|---|---|---|
| PR head/diff | exact head validated | commit, rebase, force-push or branch change |
| Mergeability/reviews/checks | live state at exact head | base/head/review/check change |
| Canonical `main` | exact current tip | new commit on `main` |
| Source file | exact blob/commit | relevant file change |
| Supabase project identity | exact live project/ref | environment ambiguity or replacement |
| Grants/RLS/policies/functions | read from exact project | migration, manual change or drift |
| Auth configuration | exact live configuration | configuration change |
| Synthetic fixture manifest | exact fixture version | create/update/delete or cleanup failure |
| Negative tests | exact backend state and fixture version | relevant code/security/environment change |
| Runtime smoke | exact build/config/backend | deploy, config or backend change |
| Authorization | exact scope still active | completion, revocation, expiration or scope change |
| Handoff | agrees with live evidence | material PR, authority, blocker, decision or next-action change |

## 4. Canonical GitHub record

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
Commit: docs(security): establish F1-02 remediation program (#101)
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
Classification: CURRENT at strategy branch creation
```

A newer `main` commit invalidates this exact base for any later sensitive lifecycle or environment decision.

## 5. Canonical F1-02 evidence

```text
docs/security/evidence/2026-07-24-f1-02-live-readonly-findings.md
docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

These files became canonical through PR #101.

Current classifications:

| Evidence | Classification |
|---|---|
| live project provenance at 2026-07-24 | CURRENT until environment change |
| grants/RLS/policies/functions at capture | CURRENT until relevant mutation/drift |
| confirmed security findings | CURRENT until remediated and revalidated |
| exploit execution against real data | NOT_VERIFIED and prohibited |
| post-remediation state | NOT_VERIFIED |
| Security Go | DENIED |

## 6. Strategy-amendment evidence

```text
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Artifact: docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
Classification before merge: DRAFT / NOT YET CANONICAL
```

The product-risk decision is recorded from explicit user authority, but the repository strategy becomes canonical only after exact-head audit and merge.

Any head change invalidates previous audit conclusions for this PR.

## 7. Controlled Beta Primary evidence rules

The environment classification does not make old database evidence permanently current.

Before every technical PR and every primary-environment operation, refresh only the affected evidence:

- current `main` and implementation head;
- exact Supabase project ref/status;
- current definitions/grants/policies for affected objects;
- current frontend/backend call-site dependencies;
- current actor/tenant derivation;
- current rollback prerequisites.

After any primary-environment mutation, previous evidence for affected objects becomes `STALE` until post-change verification is captured.

## 8. Synthetic fixture freshness

A synthetic fixture record is current only when it includes:

- exact project ref;
- fixture manifest version;
- clearly synthetic company/actor/object identities;
- creation timestamp;
- expected relationships;
- pre-test counts;
- cleanup/deactivation procedure;
- post-test counts;
- confirmation that no real identifier, credential or payload was used.

A cleanup failure invalidates the test cycle and requires containment before further testing.

## 9. Negative-test freshness

A negative-test record is current only when it includes:

- exact repository commit;
- exact project ref and environment classification;
- exact affected database/Auth state;
- synthetic fixture version;
- test ID and actor role;
- expected and actual result;
- timestamp;
- sanitized evidence;
- no intervening relevant change.

Tests must not target real records. A test against real data is not acceptable evidence; it is a governance/security incident.

## 10. Availability and data-loss acceptance evidence

The beta risk decision is current only while:

- participation remains controlled and informed;
- the service is not broadly sold with a paid SLA;
- the participant notice remains applicable;
- the environment remains MVP Família beta;
- no legal/commercial commitment supersedes it.

This evidence does not support any conclusion about tenant isolation, privacy or authorization safety.

## 11. Invalidating events

Refresh relevant evidence after:

- any migration or manual database change;
- grant, RLS, policy, trigger, constraint or function change;
- Auth configuration change;
- source call-site change;
- environment/project replacement;
- fixture creation/change/cleanup failure;
- rollback or incident;
- transition from free controlled beta to broader paid use;
- new user/data sensitivity not covered by the current decision.

## 12. Fail-closed rule

When freshness cannot be established:

```text
classification = NOT_VERIFIED or STALE
security/merge/environment conclusion = BLOCKED
next action = refresh only the narrow evidence required
```

Do not replace missing freshness with memory, beta consent, preview success or confidence.