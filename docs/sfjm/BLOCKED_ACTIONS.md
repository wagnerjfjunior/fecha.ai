# FECH.AI — SFJM Blocked Actions

## 0.00000 Current blocker/authority override — PR-07 bounded implementation — 2026-09-02

Older sections that broadly block all M1 GitHub implementation are superseded for
the exact PR-07 grant below.

Currently ALLOWED:

\`\`\`text
on branch security/f1-02-input-and-read-integrity:

create/update ONLY:
  supabase/migrations/20260902091600_f1_02_pr07_funnel_reads_crm_payloads.sql
  supabase/rollback/20260902091600_f1_02_pr07_funnel_reads_crm_payloads_rollback.sql
  supabase/tests/f1-02-pr07/funnel_reads_crm_payloads.sql

perform read-only/static validation
open one Draft PR
\`\`\`

Separately ALLOWED under continuity authority:

\`\`\`text
bounded docs/sfjm reconciliation only
one documentation branch
one Draft documentation PR
read-only validation
\`\`\`

Still BLOCKED:

\`\`\`text
any fourth technical PR-07 file
src/App.jsx modification
technical scope expansion
Supabase live mutation/application
Auth mutation
production data mutation
Edge Function change/deploy
Vercel change/deploy
Issue #133 implementation
Issue #135 implementation
PR-07 Ready
PR-07 merge
documentation PR Ready
documentation PR merge
production migration application
rollback execution
hostile/adversarial production testing
Security Go
broad paid commercialization
\`\`\`

Program-level blocks remain:

\`\`\`text
F1-02 final acceptance until PR-07/PR-08/PR-09 gates close
Security Go until its evidence gate
claim that static/catalog proof equals runtime-negative proof
unbounded production/security testing
\`\`\`

Residuals that do NOT automatically block current PR-07 implementation:

\`\`\`text
service_role EXECUTE temporary preservation
cross-session duplicate-lead race outside PR-07 guarantee
Issue #133 broader Root/Admin Global rollout
Issue #135 Team Lifecycle Authority
support-mode design
other bounded pre-Security-Go backlog items
\`\`\`

A residual becomes a current-task blocker only after new evidence proves it is
class A / BLOCKS CURRENT TASK.


**Status:** `SECURITY_TO_SCALE_2026 / M1_ACTIVE / READ_ONLY_BASELINE / FAIL_CLOSED`
**Updated:** `2026-08-28`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin blocker view. Principal state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve volatile GitHub/environment facts live before acting.

## 2. Product/security blocks

The following remain blocked:

```text
Security Go
broad paid commercialization
F1-02 final acceptance
WDP increase without governance acceptance
any claim that M1 static evidence equals current live DB/runtime proof
any unbounded production/security testing
```

## 3. M1 mutation blocks

M1 evidence acquisition is READ_ONLY FIRST. Until a later explicitly authorized implementation wave:

```text
DDL / DML
migration application
Supabase mutation
Auth/user/business-data mutation
Edge/Vercel deploy
production offensive/adversarial mutation tests
database simplification implementation
privilege/RLS/policy/grant changes
secret/config mutation
Security Go
```

## 4. Active PR workstreams

```text
#139 ACTIVE
  resolve current head/reviews/threads/checks live
  material findings affecting the current head must be closed/revalidated
  M1 does not authorize #139 lifecycle advancement

#140 ACTIVE
  static versioned config does not prove runtime Action/Builder state
  M1 may use independently proven read-only capability evidence
  M1 does not authorize #140 lifecycle advancement
```

Legacy continuity classification remains:

```text
#131 STALE_CONTINUITY
#124 STALE_CONTINUITY
#120 SUPERSEDED
```

Their classification does not authorize closure, merge, rebase or deletion.

## 5. Evidence/lifecycle separation

```text
STATIC != LIVE != RUNTIME
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
MERGEABLE != APPROVED
LIVE_DATABASE_VALIDATED != SECURITY_GO
```

## 6. Removal rule

Remove a blocker only when the record identifies the exact object/ref, material evidence, validator/gate, residual risk, rollback/containment where relevant and the new semantic next action.
