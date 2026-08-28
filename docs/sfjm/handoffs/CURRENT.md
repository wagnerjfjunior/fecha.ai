# FECH.AI — SFJM Current Product/Security Handoff

**Status:** `THIN_HANDOFF_POINTER / T3A_APPLIED / EDGE_V19_ACTIVE / BOUNDED_RUNTIME_PASS / T3B_NEXT / SECURITY_GO_DENIED`
**Updated:** `2026-08-26`
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
STATE: MERGED / APPLIED / BOUNDED RUNTIME PASS

NEXT:
T3B — Frontend administrative reset cutover
```

Live anchors at this transition:

```text
main: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
PR #130 reviewed head: fd997b6fa552f9423f7a019af58483b2b1a837f1
T3A migration history: 20260826021346_t3_admin_password_reset_boundary
Edge criar-usuario: v19 / ACTIVE
ezbr_sha256: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

Production reconciliation establishes T3 proof/lease objects and the issuer/prepare/release routines. Current proof and lease row counts are zero.

## 4. Runtime state to preserve

Established bounded evidence:

```text
nonexistent target: denied / fail-closed
same-company positive target lineage: success
separate clean same-company positive target: one POST / HTTP 200 / success
no residual proof rows at later reconciliation
no residual lease rows at later reconciliation
```

Do not expose or store test passwords, tokens, target UUIDs or target emails in handoff documentation.

This is not full adversarial/cross-tenant certification.

## 5. Why the interface appeared to fail

Current `EditarCorretorModal.redefinirSenha()` performs:

```text
successful Edge reset
-> direct PATCH corretores.must_change_password=false
```

But production now correctly has:

```text
authenticated UPDATE(must_change_password) = false
```

Therefore the backend reset can succeed while the stale frontend PATCH fails and the UI falls into its catch/error state.

Do not solve this by restoring the grant.

## 6. T3B bounded objective

Create one frontend-only change that:

```text
keeps the reviewed Edge reset call
requires explicit success response
removes the direct must_change_password=false PATCH
preserves server-owned must_change_password=true temporary-password semantics
reconciles local/UI state without protected-field DML
does not modify T1/T2/T3A database authority
```

Rollback must be a simple frontend revert.

## 7. New-conversation reconstruction order

```text
1. resolve FECH.AI main live
2. read canonical bootstrap, specialist routing and Modus Operandi
3. read SFJM current state / next action / blockers / authority / freshness
4. confirm T3A migration history and Edge v19 only if material to the T3B decision
5. resolve current App.jsx blob and EditarCorretorModal.redefinirSenha()
6. confirm authenticated cannot update must_change_password directly
7. create/review one narrow T3B frontend change only under applicable authority
8. exact-head review before Ready/merge/deploy
9. bounded UI smoke after separately authorized deploy
10. keep Security Go denied until remaining proof obligations close
```

## 8. Stale PR warning

PR #124 remains open/draft on a superseded base and overlaps SFJM.

```text
PR #124 = STALE_CONTINUITY
```

Do not use it as the T3B implementation vehicle and do not merge it into current state without a separate lifecycle decision.

## 9. Anti-loop / anti-workaround handoff

Do not:

```text
repeat PR #130 reviews without a new material invalidation
reapply the already-applied T3A migration
redeploy unchanged Edge v19
repeat resets on already-proven targets merely for reassurance
restore authenticated UPDATE(must_change_password)
weaken T1/T3 guards
mix T3B with broad App.jsx refactor
claim Security Go from same-company positive smoke
```

The objective is now a small frontend consistency/cutover correction over an established server-side T3A boundary.

## 10. Builder separation

Specialist Builder continuity remains separate:

```text
docs/sfjm/handoffs/BUILDERS_CURRENT.md
```

No Builder mutation is implied by this handoff.
