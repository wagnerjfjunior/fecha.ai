# FECH.AI — SFJM Current Product/Security Handoff

**Status:** `THIN_HANDOFF_POINTER / PR129_MERGED / EDGE_V19_B1_PASS / T3A_LIVE_ROUTINE_ANCHOR_DRIFT / ANCHOR_REFRESH_EXACT_HEAD_REVIEWS_PENDING`
**Updated:** `2026-08-25`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Purpose

This is the thin product/security handoff pointer. It does not replace the material state, authority ledger, evidence-freshness ledger or live GitHub/Supabase evidence.

## 2. Read these authorities

```text
docs/sfjm/CURRENT_STATE.md
→ durable material product/security state

docs/sfjm/NEXT_SAFE_ACTION.md
→ current semantic continuation

docs/sfjm/BLOCKED_ACTIONS.md
→ material blockers/prohibitions

docs/sfjm/AUTHORIZATIONS.md
→ active/consumed authority boundaries

docs/sfjm/EVIDENCE_FRESHNESS.md
→ evidence anchors and invalidation

docs/sfjm/INDEX.md
→ SFJM protocol
```

## 3. Current semantic handoff

```text
T3A — Administrative Password Reset Multi-Tenant Authority Boundary
STATE: PR129 MERGED / EDGE v19 ACTIVE / B1 RUNTIME PASS /
       SECOND MIGRATION ATTEMPT ABORTED FAIL-CLOSED /
       LIVE ROUTINE ANCHOR REFRESH PENDING REVIEWS
```

PR #128 merged as `3c9daf6c...`. Production Edge v19 successfully committed
the audit anchor and failed before Auth on the absent issuer during one
controlled call. The exact reviewed migration was then invoked once under
separate authority and aborted in its first preflight with SQLSTATE 55000.

Cause: `r record` used by later loops collided with `pg_roles AS r` in
forward and rollback pre/postflight. No T3 object, migration-history record,
business-data mutation or Auth mutation survived. Production remains safely
fail-closed.

PR #129 renamed only those catalog aliases/references, received fresh
Backend/Data and independent AppSec approval, and merged as `69f4cfa1...`.
The exact merged migration was then invoked once. It advanced past the alias
defect and stopped at `T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT` before
DDL. Again, no T3 object or migration-history record survived.

Fresh live catalog evidence retained count 264, authenticated-effective
SECURITY DEFINER subset `122 / 7faa376a...` and aggregate count 0, while the
complete routine digest moved from `b1f0919d...` to `c299bf08...`. The only
newer non-system routine is Supabase-owned SECURITY INVOKER event-trigger
helper `extensions.grant_pg_graphql_access()`.

The current workstream is one narrow Draft PR that updates only the four
complete routine-inventory digest literals in forward and rollback and records
the new evidence. T1/T2, B1, B4, Edge code, App.jsx, the PR #129 alias fix and
authority predicates are not reopened.

## 4. New-conversation reconstruction order

```text
1. resolve FECH.AI main live
2. read canonical bootstrap, Modus Operandi and SFJM
3. confirm PR #129 merged and resolve the routine-anchor Draft PR live
4. read SFJM from its exact head while PR_HEAD_ONLY
5. authenticate forward/rollback base blobs and inspect the four-literal diff
6. recompute current full routine digest and confirm definer subset/counts unchanged
7. confirm production still has no T3 migration record/objects and Edge v19 is active
8. read every changed final file to EOF
9. obtain Backend/Data exact-head review
10. only after closure, obtain independent AppSec exact-head review
11. stop in Draft before Ready
```

Use the manual specialist channel while the Router remains frozen. Never claim
a Gateway receipt.

## 5. Anti-loop / anti-workaround handoff

The next conversation must not:

```text
restart T1/T2 without a material invalidation event
open another duplicate T3A PR merely because the current head changes
weaken T1 triggers to make T3A pass
use broad grants/client authority as a shortcut
apply production changes before final exact-head gates and separate runtime authorization
exclude the changed helper from the positive inventory to force a pass
leave the PR description materially stale after corrective implementation
```

The objective is one corrected T3A change set, one independently validated final head, one explicit rollout plan and one executable drift-safe rollback.

## 6. Builder separation

Specialist Builder continuity remains separate:

```text
docs/sfjm/handoffs/BUILDERS_CURRENT.md
```

No Builder mutation is implied by this handoff.

## 7. Handoff acceptance

A successful continuation must reconstruct:

```text
T1/T2 remain established and are not reopened
PR #128 merged as main 3c9daf6c...
production Edge v19 is active
one v19 call committed audit and failed before Auth
the first exact migration invocation aborted on the role-alias collision
PR #129 corrected the alias, passed both exact-head reviews and merged as 69f4cfa1...
the second exact migration invocation aborted on positive routine inventory drift
no T3 object or migration record exists
the current full live routine anchor is 264 / c299bf087df69f960dd0c611d1486675
the only current GitHub mutation is one Draft PR with the four-literal refresh
Backend/Data then independent AppSec remain required
Ready and merge remain blocked; one later migration retry is bounded but not
  exercisable before reviews/final-byte authentication/lifecycle resolution;
  smoke, rollback and Security Go remain blocked
```

If any of these facts cannot be resolved live, stop and identify the specific
continuity gap.
