# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR107_MERGED / PR103_RUNTIME_SMOKE_VALIDATED / PR02_NOT_AUTHORIZED / FAIL_CLOSED`  
**Observed on:** `2026-07-29`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch or commit, object set, configuration and lifecycle state observed. Versioned code, merged state, deployed state, live catalog state and executed runtime tests remain distinct.

A change in `main` does not invalidate all evidence automatically. Revalidate only the material scope affected by a defined invalidation event.

## 2. Current GitHub anchors

```text
main: cec1b22430adf1a002b172992cf6c5ea5bb427de
main commit: docs(security): record PR103 authenticated smoke (#107)

PR #107: CLOSED / MERGED
base: main@9624900ada5d29e24476ab6a0a0907cb4854e509
original audited head: 51105692b0957454bd3d83f70e6591472fcf10dc
final corrective head: 62346a8976d3489dff9b84dcf7bab40a2b43e685
squash: cec1b22430adf1a002b172992cf6c5ea5bb427de
changed files: exactly 7 documentation files
```

The old `OPEN / READY`, `corrective head: resolve live`, `merge not authorized` and `pending audit` statements are stale after the verified merge.

## 3. Catalog evidence — PR #103 / PR-01

Last versioned catalog evidence records:

```text
Project: uobxxgzshrmbtjfdolxd / production
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
```

Canonical catalog evidence source:

```text
docs/security/evidence/2026-07-27-pr103-operational-closure-with-residual-risk.md
```

This record is not a substitute for a new live catalog check after a material change to the migration, RPC, owner, security mode, search path, ACLs, role memberships or environment.

## 4. Controlled runtime evidence

Observed on `2026-07-28`:

```text
First authenticated call:
must_change_password true → false
xmin 6997 → 6999
RPC return true
unexpected changed fields none

Immediate repeated call:
must_change_password false → false
xmin 6999 → 6999
RPC return true
unexpected changed fields none

Cleanup:
remaining Auth users 0
remaining synthetic broker profiles 0
remaining synthetic teams 0
synthetic company preserved inactive
```

Runtime evidence source:

```text
docs/security/evidence/2026-07-28-pr103-authenticated-smoke-and-idempotency.md
```

## 5. Evidence boundary

Established:

- authenticated positive execution;
- `must_change_password = true → false`;
- immediate repeated-call idempotency;
- no second row version on the repeated call;
- no unexpected change in the captured profile fields;
- synthetic-fixture cleanup.

Not established:

- controlled concurrency;
- missing-profile execution;
- inactive-profile execution;
- rollback execution;
- reapply after rollback;
- frontend cutover;
- deployed frontend proof;
- denial of legacy direct table update;
- Security Go;
- F1-02 acceptance;
- WDP.

Test design is not execution evidence.

## 6. PR #107 gate inventory

Verified in the PR review timeline:

```text
GPT0 original documentation audit:
PASS at 51105692b0957454bd3d83f70e6591472fcf10dc

GPT4 original lifecycle/scope validation:
PASS at 51105692b0957454bd3d83f70e6591472fcf10dc

GPT0 delta-only documentation re-audit:
PASS for 51105692b0957454bd3d83f70e6591472fcf10dc
→ 62346a8976d3489dff9b84dcf7bab40a2b43e685
```

Verified in live GitHub metadata:

```text
PR #107: CLOSED / MERGED
final head: 62346a8976d3489dff9b84dcf7bab40a2b43e685
squash: cec1b22430adf1a002b172992cf6c5ea5bb427de
```

Not independently reconstructed in this SFJM update:

```text
exact GPT4 corrective-head review artifact
exact separate merge-authority artifact
```

Do not infer those artifacts merely from merge metadata. Their absence from this reconstruction does not reactivate or reopen the closed PR lifecycle; it remains an evidence gap for historical traceability only.

## 7. Program state

```text
F1-02 PR-00: completed
F1-02 PR-01: completed with residual risk
Authenticated positive smoke: PASS
Immediate runtime idempotency: PASS
PR-02: next technical workstream / implementation not authorized
PR-03: blocked until PR-02 is deployed and proven
PR-04 through PR-09: planned unless newer canonical evidence proves otherwise
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

## 8. Current exact next action

```text
GPT1 READ_ONLY architectural scope reconstruction for PR-02
against the current live main
→ bounded implementation proposal only
→ separate Product Authority before any execution
```

## 9. Invalidation events

Revalidate only the narrow affected evidence after:

- change to the PR-01 migration or RPC body;
- change to RPC signature, owner, security mode or search path;
- ACL or role-membership change affecting execution;
- contradictory live catalog or authenticated runtime evidence;
- frontend cutover or another security-boundary change;
- environment change;
- new material security finding;
- explicit expiration condition recorded by the original gate;
- head or changed-file change for a head-bound PR gate.

Not invalidation events:

- opening a new conversation;
- changing specialist;
- a generic revalidation request;
- a documentation-only main change without demonstrated material impact;
- an accepted residual risk without new evidence;
- recording the future squash SHA of this reconciliation alone.

## 10. Anti-loop rule

A re-audit request must identify the nominal gate, owner, prior anchor, exact changed evidence, triggered invalidation rule and exact revalidation scope.

Without all six:

```text
AUDIT_LOOP_BLOCKED
```