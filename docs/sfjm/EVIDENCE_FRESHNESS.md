# FECH.AI — SFJM Evidence Freshness

**Status:** ACTIVE_FRESHNESS_RULES / FAIL_CLOSED  
**Observed on:** 2026-07-24

## 1. Purpose

This document defines when evidence may be treated as current and when it must be revalidated. Freshness does not prove correctness; it only determines whether a prior observation may still support a present decision.

## 2. Freshness classes

```text
CURRENT
STALE
SUPERSEDED
NOT_VERIFIED
NOT_APPLICABLE
```

- `CURRENT`: validated against the exact current target with no known invalidating event.
- `STALE`: previously useful, but no longer sufficient for the present decision.
- `SUPERSEDED`: explicitly replaced by newer canonical evidence.
- `NOT_VERIFIED`: reported or inferred but not independently validated.
- `NOT_APPLICABLE`: outside the current scope, module, environment or decision.

## 3. Rules by evidence type

| Evidence | CURRENT condition | Invalidating event |
|---|---|---|
| PR head | Exact head SHA validated | Commit, force-push, rebase or branch update |
| PR diff | Full diff validated at exact head | Head change |
| PR mergeability | Live state checked | Base/head/repository-state change |
| Reviews/threads | Read at exact head and current thread state | New review/comment/resolution or head change |
| Canonical `main` | Exact tip validated | New commit on `main` |
| GitHub checks | Exact commit and latest relevant run | New commit, rerun or workflow change |
| Source file | Blob or commit validated | File changes on relevant ref |
| Supabase grants/policies/RPC bodies | Read from exact live project/environment | Migration, manual change, environment ambiguity or absent reconciliation |
| Tenant-isolation test | Executed against current backend state | Backend/security/environment change |
| Runtime smoke | Exact build/configuration tested | Code, backend, env, deploy or config change |
| Vercel deployment | Exact deployment and alias validated | Promotion, rollback, alias or deployment change |
| Handoff | Matches live GitHub/environment evidence | PR/head/authorization/blocker/decision/next-action change |
| Authorization | Scope and expiration remain valid | Completion, revocation, target or scope change |
| B0 checkpoint | Recorded through authorized governance | Baseline change, rejected evidence or superseding decision |

## 4. Canonical main freshness record

Observed after squash merge of PR #94:

```text
Canonical main observed: 1caf90c60681771af6609b96ee840b190668fa0f
Commit: docs(m1): add F1-01 acceptance evidence map (#94)
PR #94 final head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
PR #94 state: CLOSED / MERGED
PR #94 reaudit result: PASS WITH RESIDUAL RISK
```

This observation is `CURRENT` only until a newer commit lands on `main`. It proves repository state only. It does not validate runtime, Supabase, tenant isolation, Security Go, F1-01 acceptance or production.

## 5. F1-01 evidence-map freshness

```text
Merged artifact: docs/audits/mvp/2026-07-05-f1-01-m1-acceptance-evidence-map.md
Corrected PR head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
Squash commit: 1caf90c60681771af6609b96ee840b190668fa0f
Classification for current source-path inventory: CURRENT at merge
Classification for live Supabase/runtime claims: NOT_VERIFIED
```

The source-path inventory remains current only while the referenced source blobs and relevant runtime paths are unchanged. Any source change affecting M1 calls invalidates the corresponding inventory rows.

## 6. F1-02 freshness requirements

Any future read-only security evidence must record:

- exact Supabase project and environment;
- observation date/time;
- evidence collection method;
- relevant schema, function, policy or grant identity;
- sanitized output or reproducible query;
- known limitations;
- invalidating events;
- expiration condition.

Historical Supabase records, even when versioned, remain `STALE` for current Security Go unless refreshed against the exact live target.

## 7. Fail-closed rule

When freshness cannot be established:

```text
classification = NOT_VERIFIED or STALE
security/merge/deploy conclusion = blocked
next action = refresh only the narrow evidence required
```

Do not replace missing freshness with memory, confidence, conversation continuity, preview success or repeated assertions.
