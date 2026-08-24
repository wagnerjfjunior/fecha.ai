# FECH.AI — SFJM Current Product/Security Handoff

**Status:** `THIN_HANDOFF_POINTER / PR127_MERGED / EDGE_V18_DEPLOYED / B1_RUNTIME_PASS / AUDIT_V5_CORRECTION / NEW_EXACT_HEAD_REVIEWS_PENDING`
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
STATE: V4 MERGED / EDGE-FIRST B1 PASS / POST-MERGE AUDIT V5 REVIEWS PENDING
```

The next conversation must continue the single post-merge v5 audit correction,
not restart B1-B4 or open duplicate PRs. PR #127 is already merged, so one new
Draft PR is required for the runtime-discovered audit incompatibility.

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
release. PR #127 returned to Draft at that point. The same-PR v4 candidate then
adds a service-role-only opaque one-time Edge-proof issuer; the caller-JWT
prepare must consume the matching unexpired actor+target proof before locks,
lease creation or password-state mutation. It also makes rollback block live
proofs/leases and clean only expired inert proofs after complete exact
preflight. Fresh Backend/Data and independent AppSec reviews approved exact
head `a5c92617...` / tree `87872aac...`; PR #127 merged as `610bdd3c...`.

The exact Edge was deployed as production v18 while T3A SQL remained absent.
Three UI submissions during the bounded fail-before-Auth exercise all returned
500 with no Auth update, proving B1. They also showed audit INSERT 400 because
live `audit_logs` requires `acao` and `entidade` and types `ip_address` as
`inet`. V5 supplies the dual audit schema, fails before proof/Auth on audit
failure, pins the complete audit relation, revokes authenticated audit INSERT,
and makes rollback restore it exactly. These changed bytes require new
Backend/Data then independent AppSec exact-head review.

## 4. New-conversation reconstruction order

```text
1. resolve FECH.AI main live
2. read docs/bootstrap/INDEX.md
3. resolve SES roles needed for Backend/Data and AppSec
4. read common Modus Operandi + governance/SFJM
5. resolve the active v5 corrective PR live
6. because this transition is PR_HEAD_ONLY until merge, read SFJM from its exact head
7. confirm current Supabase/Edge read-only anchors material to audit + B1-B4 dependencies
8. reconcile the v5 exact head/evidence/coverage, repeat Backend/Data and only after closure run independent AppSec
9. stop in Draft before Ready
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
open another duplicate T3A PR merely because the v5 head changes
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
PR #127 v4 merged at main 610bdd3c; T3A migration not applied
production Edge v18 deployed; B1 fail-before-Auth PASS; no target Auth mutation
audit POST 400 is the new blocker; live requires acao/entidade and inet
v5 candidate preserves approved B1-B4/HIGH-1 and corrects audit compatibility
current corrective GitHub authority exists; deploy/migration/Ready/merge remain separate
next action is v5 exact-head reconciliation + Backend/Data + independent AppSec
```

If those facts cannot be reconstructed from live evidence + SFJM, stop and declare the specific continuity gap rather than guessing.
