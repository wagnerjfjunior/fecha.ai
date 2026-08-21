# FECH.AI — SFJM Current Material State

**Status:** `MATERIAL_RECORDED_STATE / F1_02_ACTIVE_REMEDIATION / PR03_NOT_YET_ELIGIBLE / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-21`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority rule

This file is the principal authority for durable product/security operational meaning.

It intentionally does not define current GitHub lifecycle facts such as `main` SHA, PR Draft/Ready state, current head, checks, reviews, mergeability or current deployment status. Resolve those live before acting.

## 2. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Frontend requests and displays. Backend/RPC/Supabase validates and decides. AI assists but is not authority.

## 3. F1-02 material program state

### PR-01 — narrow password-state RPC

```text
State: COMPLETED WITH RESIDUAL RISK
RPC: public.marcar_senha_inicial_definida()
Actor derivation: auth.uid()
Target identifiers from client: none
Supabase project/environment: uobxxgzshrmbtjfdolxd / production
Migration anchor: 20260727080929 / f1_02_password_state_rpc / APPLIED
Authenticated positive smoke: ESTABLISHED
Immediate repeated-call idempotency: ESTABLISHED
```

Residual runtime/security limits from PR-01 remain recorded as residual risk; completed PR-01 work must not be reopened merely because later documentation or lifecycle moved.

### PR-02 / PR #108 — mandatory-password frontend cutover

```text
State: IMPLEMENTED / MERGED
Production deployment record: ESTABLISHED
Static fail-closed contract: PRESERVED
Post-deploy functional proof: INCOMPLETE
```

Material behavior:

```text
change password
→ authenticated public.marcar_senha_inicial_definida()
→ no caller-selected target user identifier
→ require strict boolean true
→ only then continue UI
```

The protected frontend code anchor remains:

```text
src/App.jsx blob:
2541813e6af44f4e8112296b7d9666df9320db5d
```

On 2026-08-21 this blob was freshly recovered from GitHub through continuous bounded line ranges `1–5902`, followed by an empty post-EOF probe beginning at line `5903`. The exact retrieval process and static architecture/call-site baseline are recorded in:

```text
docs/audits/architecture/2026-08-21-a1-a2-as-is-callsite-and-app-integral-read-baseline.md
```

The existence of a successful Production deployment record does not by itself establish functional user-flow smoke or runtime fail-closed behavior.

### PR-03 — direct UPDATE revocation

```text
State: NOT_YET_MATERIALLY_ELIGIBLE
```

PR-03 must not begin until the canonical eligibility contract establishes that broad direct-update revocation will not break required legitimate behavior.

The PR-01 production RPC prerequisite is anchored to `uobxxgzshrmbtjfdolxd / production` and migration `20260727080929 / f1_02_password_state_rpc / APPLIED`. PR-02 deployment is recorded, but the remaining runtime and continuity predicates below are not yet all established.

The refreshed 2026-08-21 source inventory changed one evidence state but did **not** make PR-03 eligible:

```text
repository-wide direct-write/call-site inventory: ESTABLISHED
eligibility result: CONDITION NOT SATISFIED
reason: two active direct PATCH paths remain in EditarCorretorModal
```

## 4. Active residual risk

### Administrative broker/profile writes

The refreshed integral App.jsx inventory establishes two active direct writes in `EditarCorretorModal`:

```text
1. operational broker state
   direct PATCH public.corretores
   fields: ativo, apto_para_receber

2. administrative password state
   reset_password through criar-usuario Edge boundary
   → direct PATCH public.corretores
   field: must_change_password=false
```

The password-state administrative path remains:

```text
ACTIVE_RESIDUAL_RISK
```

The administrative path is distinct from the self-service RPC. The self-service RPC derives the actor from `auth.uid()` and is not a valid server-side authorization contract for an administrator acting on another user.

No new administrative RPC, direct-write removal or runtime change is authorized by this SFJM state.

## 5. PR-03 eligibility predicates

### Established predicate with negative eligibility result

```text
3. refreshed repository-wide direct-write/call-site inventory:
   ESTABLISHED on 2026-08-21
   anchor: src/App.jsx blob 2541813e6af44f4e8112296b7d9666df9320db5d
   retrieval: fresh continuous GitHub ranges 1–5902 + empty 5903+ probe
   result: required/current administrative direct writes remain
   eligibility condition: NOT SATISFIED
```

This is not an evidence gap anymore. It is affirmative evidence that broad direct-UPDATE revocation would still intersect current administrative behavior.

### Remaining material evidence / disposition needs

```text
1. post-deploy functional smoke of the mandatory-password cutover;
2. post-deploy runtime fail-closed evidence;
4. safe server-side disposition for the EditarCorretorModal administrative paths;
5. cutover observation sufficient to confirm no legitimate flow depends on direct UPDATE;
6. controlled RPCs individually inventoried and tested for continuity under direct-UPDATE revocation.
```

The absence of legacy direct UPDATE denial is not a circular prerequisite for starting the PR that is intended to revoke that permission. Direct-update denial belongs to post-PR-03 acceptance evidence.

## 6. Historical provenance boundary

The following historical provenance gaps may exist without proving gate failure or unauthorized execution:

```text
GATE_PROVENANCE_NOT_RECORDED
AUTHORITY_PROVENANCE_NOT_RECORDED
```

Normative interpretation:

```text
UNKNOWN != REEXECUTE
GATE_PROVENANCE_NOT_RECORDED != GATE_FAILED
AUTHORITY_PROVENANCE_NOT_RECORDED != UNAUTHORIZED
```

Do not automatically replay historical GPT3, GPT7, GPT4, Ready, merge or deployment gates from PR #108.

Only recover the minimum present-time validation if a provenance gap is materially necessary for a current safety decision.

## 7. Current material blockers

```text
Security Go remains DENIED.
Broad paid commercialization remains BLOCKED.
F1-02 remains ACTIVE REMEDIATION / BLOCKED.
PR-03 remains NOT_YET_MATERIALLY_ELIGIBLE.
Administrative password-state residual remains ACTIVE_RESIDUAL_RISK.
Direct-write inventory now affirmatively confirms current administrative direct-PATCH dependencies.
```

These are semantic blockers. Their validity is not tied to a particular current `main` SHA or PR Draft/Ready snapshot.

## 8. Semantic next action

```text
Resolve the safe server-side disposition and authority contract for the remaining EditarCorretorModal administrative writes, without implementing until separately authorized.
```

This is the smallest newly clarified dependency after the direct-write inventory became established. It does not remove the other remaining runtime/continuity predicates in section 5.

Any runtime smoke, Supabase change, PR-03 implementation, administrative server-side replacement, Ready, merge or deploy requires its own exact authority when applicable.

## 9. Material update triggers

Update this file only when durable meaning changes, for example:

```text
one remaining evidence item becomes established or invalidated;
PR-03 eligibility changes;
a material blocker is added or removed;
Security Go changes;
F1-02 acceptance changes;
WDP changes through verified governance acceptance;
a new material product/security decision appears.
```

Do not update this file solely because `main` changed, a documentation-only PR merged, a PR moved Draft/Ready, or an unrelated Builder document changed.
