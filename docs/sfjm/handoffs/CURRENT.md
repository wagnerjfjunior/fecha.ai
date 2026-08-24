# FECH.AI — SFJM Current Product/Security Handoff

**Status:** `THIN_HANDOFF_POINTER / T3A_V4_POST_READY_P2_CORRECTION / NEW_EXACT_HEAD_REVIEWS_PENDING / LIVE_LIFECYCLE_RESOLUTION`
**Updated:** `2026-08-24`
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

The current workstream is:

```text
T3A — Administrative Password Reset Multi-Tenant Authority Boundary
STATE: V4 POST-READY DIRECT-RPC CORRECTION / NEW EXACT-HEAD REVIEWS PENDING
```

The next conversation must continue the **existing** T3A change set rather than restart the design or open another PR for the same blocker set.

Corrected domains to reconcile on the final exact head:

```text
B1 safe rollout ordering
B2 trust-anchor preflight
B3 drift-safe rollback
B4 T1 guard interoperability
```

Backend/Data review of `bf8fb1f...` found the DB→Auth race and non-transitive
writer regex. The v3 head `46313258...` closed the race, and the subsequent
membership/options, aggregate and complete `public` ACL correction at
`fcb7dfc2...` received Backend/Data plus independent AppSec `APPROVE`.

After separately-authorized Ready, GitHub Codex opened material P2
`DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`: direct authenticated prepare access
could create a durable fence without an Edge Auth mutation or caller-accessible
release. PR #127 returned to Draft without merge. The same-PR v4 candidate now
adds a service-role-only opaque one-time Edge-proof issuer; the caller-JWT
prepare must consume the matching unexpired actor+target proof before locks,
lease creation or password-state mutation. It also makes rollback block live
proofs/leases and clean only expired inert proofs after complete exact
preflight. The material change invalidates the prior approvals as final-head
gates. New Backend/Data and then independent AppSec exact-head reviews are
required before any new Ready/merge transition.

## 4. New-conversation reconstruction order

```text
1. resolve FECH.AI main live
2. read docs/bootstrap/INDEX.md
3. resolve SES roles needed for Backend/Data and AppSec
4. read common Modus Operandi + governance/SFJM
5. resolve the active T3A PR live
6. because this 2026-08-23 SFJM transition is PR_HEAD_ONLY until merge, read the SFJM files from the active T3A head
7. confirm current Supabase/Edge read-only anchors material to B1-B4
8. resolve the v4 corrective PR head, reconcile evidence/coverage, repeat Backend/Data and only after closure run independent AppSec
9. stop in Draft before a new Ready/merge transition
```

The SES Router is temporarily frozen because the in-project Action path is not
reliably available. Use the manual exact-head prompt/response channel recorded
in `AUTHORIZATIONS.md`: Backend/Data first, independent AppSec second. Never
represent that manual channel as a Gateway invocation.

Do not use this handoff as a frozen source for current main/head/check/review/deployment state.

## 5. Anti-loop / anti-workaround handoff

The next conversation must not:

```text
restart T1/T2 without a material invalidation event
open another T3A PR merely because the head changes
weaken T1 triggers to make T3A pass
use broad grants/client authority as a shortcut
apply production changes before final exact-head gates and separate runtime authorization
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

A successful new conversation should be able to reconstruct:

```text
T1 applied and preserved
T2 positive status cutover proven in bounded production smoke
T3A not applied/deployed
existing T3A v4 candidate preserves B1-B4/HIGH-1 closure and adds the
post-Ready direct-RPC Edge-proof boundary
prior v3 Backend/Data/AppSec approvals are recorded but invalidated for the changed material head
current corrective GitHub authority exists, but new Ready/merge/production remain separate gates
next action is v4 exact-head reconciliation + Backend/Data + independent AppSec validation
```

If those facts cannot be reconstructed from live evidence + SFJM, stop and declare the specific continuity gap rather than guessing.
