# FECH.AI — SFJM Current Product/Security Handoff

**Status:** `THIN_HANDOFF_POINTER / T3A_CORRECTED_CANDIDATE / EXACT_HEAD_REVIEWS_PENDING / LIVE_LIFECYCLE_RESOLUTION`
**Updated:** `2026-08-23`
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
STATE: CORRECTED B1-B4 CANDIDATE / EXACT-HEAD REVIEWS PENDING
```

The next conversation must continue the **existing** T3A change set rather than restart the design or open another PR for the same blocker set.

Corrected domains to reconcile on the final exact head:

```text
B1 safe rollout ordering
B2 trust-anchor preflight
B3 drift-safe rollback
B4 T1 guard interoperability
```

The v2 candidate records corrections for all four domains in the existing PR.
It is not eligible for Ready/merge/deploy/application until Backend/Data and an
independent AppSec reviewer validate the same resolved final head. Candidate
closure is not specialist PASS.

## 4. New-conversation reconstruction order

```text
1. resolve FECH.AI main live
2. read docs/bootstrap/INDEX.md
3. resolve SES roles needed for Backend/Data and AppSec
4. read common Modus Operandi + governance/SFJM
5. resolve the active T3A PR live
6. because this 2026-08-23 SFJM transition is PR_HEAD_ONLY until merge, read the SFJM files from the active T3A head
7. confirm current Supabase/Edge read-only anchors material to B1-B4
8. resolve the corrective PR head, reconcile evidence/coverage and perform the two exact-head reviews
9. stop before Ready without a new Product Authority
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
existing T3A v2 candidate records B1-B4 correction
current corrective GitHub authority exists, but Ready/merge/production remain separate gates
next action is final-head reconciliation + Backend/Data + independent AppSec validation
```

If those facts cannot be reconstructed from live evidence + SFJM, stop and declare the specific continuity gap rather than guessing.
