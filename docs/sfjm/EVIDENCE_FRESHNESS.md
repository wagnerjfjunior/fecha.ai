# FECH.AI — SFJM Evidence Freshness

**Status:** ACTIVE_FRESHNESS_RULES / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Purpose

This document defines when evidence may be treated as current and when it must be revalidated.

Evidence freshness does not prove correctness by itself. It only determines whether a previous observation may still support a current decision.

## 2. Freshness classes

```text
CURRENT
STALE
SUPERSEDED
NOT_VERIFIED
NOT_APPLICABLE
```

### CURRENT

The evidence was validated against the exact current target and no known invalidating event occurred.

### STALE

The evidence was once valid or useful, but a change or elapsed context makes it insufficient for the present decision.

### SUPERSEDED

A newer canonical record or applied state explicitly replaces the evidence.

### NOT_VERIFIED

The evidence was reported, inferred or referenced but not independently validated against the required source.

### NOT_APPLICABLE

The evidence does not apply to the current scope, module, environment or decision.

## 3. Freshness rules by evidence type

| Evidence | CURRENT condition | Invalidating event |
|---|---|---|
| PR head | Exact head SHA validated | Any new commit, force-push, rebase or branch update |
| PR diff | Full diff validated at exact head | Head SHA changes |
| PR mergeability | Live state checked | Base/head change, conflict change or repository state change |
| PR reviews/threads | Read at exact head and current thread state | New review, comment, resolution or head change |
| Canonical `main` | Exact tip validated | New commit on `main` |
| GitHub checks | Associated with exact commit and latest relevant run | New commit, rerun or workflow/configuration change |
| Source file | Blob or commit validated | File changes on the relevant ref |
| Supabase grants/policies/RPC bodies | Read from the correct live project and environment | Database migration, manual change, project/environment ambiguity or absent current reconciliation |
| Tenant-isolation test | Executed against the current relevant backend state | Security/backend change or environment change |
| Runtime smoke test | Executed against the exact build/configuration | Code, environment variable, backend, deployment or configuration change |
| Vercel deployment | Exact deployment and alias validated | New deployment, promotion, rollback or alias change |
| Screenshot | Source, timestamp and target state established | Target changes or provenance is incomplete |
| Handoff | Matches current GitHub and environment evidence | Active PR/head, authorization, blocker, decision or next action changes |
| Authorization | Scope and expiration remain valid | Expiration condition, revocation, target change or scope completion |
| B0 checkpoint decision | Recorded through the authorized governance process | Baseline change, rejected evidence or superseding checkpoint decision |

## 4. PR #94 freshness record

Observed on 2026-07-24:

```text
PR #94 head: 140e92dd12c72eae5f90fa55b5b125bbedf6fbaa
PR #94 base SHA: e7584b6ce2a53a88fca9974bcc448ebe9aea83ab
Canonical main observed: e7584b6ce2a53a88fca9974bcc448ebe9aea83ab
```

These observations are `CURRENT` only until an invalidating event occurs.

The PR #94 head is evidence about PR #94. It is not a canonical `main` commit and is `NOT_APPLICABLE` as the base for the independent SFJM documentation branch.

## 5. Historical live evidence

Historical Supabase, runtime or deployment evidence must not be promoted to current authorization proof merely because it is versioned in GitHub.

A versioned historical result can establish:

- what was tested;
- when it was tested;
- the observed result at that time;
- the known method and limitations.

It cannot establish the present live state after potentially invalidating changes.

## 6. Fail-closed rule

When freshness cannot be established:

```text
classification = NOT_VERIFIED or STALE
security/merge/deploy conclusion = blocked
next action = refresh the narrow evidence required
```

Do not replace missing freshness with memory, confidence, conversation continuity or repeated assertions.