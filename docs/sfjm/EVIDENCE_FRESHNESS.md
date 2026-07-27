# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR103_CATALOG_VALIDATED / FAIL_CLOSED`  
**Observed on:** `2026-07-27`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch or commit, object set, configuration and lifecycle state observed. Versioned code, merged state, deployed state, live catalog state and executed runtime tests must remain distinct.

A change in `main` does not invalidate all evidence automatically. Revalidate only the material scope affected by a defined invalidation event.

## 2. GitHub evidence

```text
main observed: 276a3e55155cd0e57b6155dc13b998704bdfd654
PR #103: CLOSED / MERGED
PR #103 final head: abf6b4026343eae437283280269ed2997911dcec
PR #103 squash: 276a3e55155cd0e57b6155dc13b998704bdfd654
PR #103 changed files: 1
```

The closure PR may advance `main`. That documentation-only change does not invalidate the PR #103 migration or catalog evidence unless it changes a material object or claim.

## 3. Live Supabase evidence — PR #103

Project:

```text
uobxxgzshrmbtjfdolxd / production
```

Verified read-only:

```text
Migration version: 20260727080929
Migration name: f1_02_password_state_rpc
Migration status: APPLIED
RPC: public.marcar_senha_inicial_definida()
Arguments: none
Owner: postgres
SECURITY DEFINER: true
search_path: pg_catalog
provolatile: VOLATILE
authenticated EXECUTE: true
anon EXECUTE: false
service_role EXECUTE: false
PUBLIC EXECUTE: false
Direct ACL: postgres, authenticated
```

## 4. Evidence not established

The closure evidence does not establish:

- authenticated positive smoke;
- repeated-call idempotency at runtime;
- controlled concurrency behavior;
- missing-profile execution;
- inactive-profile execution;
- rollback execution;
- reapply after rollback.

Test design is not execution evidence.

## 5. Program and lifecycle evidence

```text
F1-02 PR-01: COMPLETED WITH RESIDUAL RISK
PR-02: next separate workstream / not authorized / no independent PR located
PR-03: blocked until PR-02 is deployed and proven
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

## 6. Closed gates and unknowns

Final gate records may be reused only when their canonical anchor, verdict and material scope are identifiable. Where a precise final gate cannot be reconstructed from canonical records, record:

```text
UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

Do not request a new audit solely to fill a documentation gap.

## 7. Invalidation events

Revalidate only the narrow affected evidence after:

- change to PR #103 integrated migration content;
- change to `public.marcar_senha_inicial_definida()` signature, owner, security mode or search path;
- ACL or role-membership change affecting execution;
- contradictory live catalog evidence;
- frontend cutover or security-boundary change;
- environment change;
- new material security finding;
- explicit expiration condition recorded by the original gate.

Not invalidation events:

- opening a new conversation;
- changing specialist;
- generic revalidation request;
- documentation-only main change with no demonstrated material impact;
- an accepted residual risk without new evidence.

## 8. Anti-loop rule

```text
NO INVALIDATION EVENT
→ NO REAUDIT
```

A re-audit request must identify the prior gate, prior anchor, exact changed evidence, triggered invalidation rule and exact revalidation scope. Otherwise:

```text
AUDIT_LOOP_BLOCKED
```
