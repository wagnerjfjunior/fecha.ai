# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR103_RUNTIME_SMOKE_VALIDATED / PR107_PM107_CORRECTION_PENDING / FAIL_CLOSED`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch or commit, object set, configuration and lifecycle state observed. Versioned code, merged state, deployed state, live catalog state and executed runtime tests remain distinct.

A change in `main` does not invalidate all evidence automatically. Revalidate only the material scope affected by a defined invalidation event.

## 2. GitHub anchors

```text
main observed before PR #107:
9624900ada5d29e24476ab6a0a0907cb4854e509

PR #103:
CLOSED / MERGED
final head: abf6b4026343eae437283280269ed2997911dcec
squash: 276a3e55155cd0e57b6155dc13b998704bdfd654

PR #106:
CLOSED / MERGED
final head: 3b0d28406e15e9da979673eed1c7fdf81c609f76
squash / observed main: 9624900ada5d29e24476ab6a0a0907cb4854e509

PR #107:
OPEN / READY FOR REVIEW
base: main@9624900ada5d29e24476ab6a0a0907cb4854e509
original audited head: 51105692b0957454bd3d83f70e6591472fcf10dc
corrective head: resolve live
```

PR #107 remains proposed documentation state until separately authorized and merged.

## 3. Live Supabase evidence — PR #103

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
Direct ACL: postgres, authenticated
```

Controlled runtime evidence observed on `2026-07-28`:

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

Evidence source:

```text
docs/security/evidence/2026-07-28-pr103-authenticated-smoke-and-idempotency.md
```

## 4. Evidence boundary

Established:

- authenticated positive execution;
- `must_change_password = true → false`;
- immediate repeated-call idempotency;
- no second row version on the repeated call;
- no unexpected change in captured profile fields;
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

## 5. Program state

```text
F1-02 PR-00: completed
F1-02 PR-01: COMPLETED WITH RESIDUAL RISK
Authenticated positive smoke: PASS
Immediate runtime idempotency: PASS
PR-02: next technical workstream / implementation not authorized
PR-03: blocked until PR-02 is deployed and proven
PR-04 through PR-09: planned unless newer canonical evidence proves otherwise
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

## 6. Historical gate inventory

Historical verdicts remain unchanged unless newer canonical evidence explicitly supersedes them.

### 6.1 PR #101 program baseline — GPT0

```text
Owner: GPT0
Anchor: PR #101 head 003850d012a299a947452fa5a8135cd454998f15
        squash affbae1a598928010b0fa7db967734de522c13b4
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.2 PR #101 program baseline — GPT1

```text
Owner: GPT1
Anchor: PR #101 head 003850d012a299a947452fa5a8135cd454998f15
        squash affbae1a598928010b0fa7db967734de522c13b4
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.3 PR #101 Supabase security plan — GPT3

```text
Owner: GPT3
Anchor: PR #101 head 003850d012a299a947452fa5a8135cd454998f15
        squash affbae1a598928010b0fa7db967734de522c13b4
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.4 PR #103 final documentation gate — GPT0

```text
Owner: GPT0
Anchor: PR #103 head abf6b4026343eae437283280269ed2997911dcec
        squash 276a3e55155cd0e57b6155dc13b998704bdfd654
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.5 PR #103 final architectural gate — GPT1

```text
Owner: GPT1
Anchor: PR #103 head abf6b4026343eae437283280269ed2997911dcec
        squash 276a3e55155cd0e57b6155dc13b998704bdfd654
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.6 PR #103 final security/catalog gate — GPT3

```text
Owner: GPT3
Anchor: PR #103 head abf6b4026343eae437283280269ed2997911dcec
Final verdict: PASS — CODE AND CATALOG PREFLIGHT VALIDATED
Residual boundary: application and authenticated runtime were deferred at this gate
```

### 6.7 PR #103 final lifecycle/merge gate — GPT4

```text
Owner: GPT4
Anchor: PR #103 head abf6b4026343eae437283280269ed2997911dcec
        squash 276a3e55155cd0e57b6155dc13b998704bdfd654
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.8 PR #103 controlled production application and smoke

```text
Owner: Product Authority-authorized controlled validation
Anchor: main@9624900ada5d29e24476ab6a0a0907cb4854e509
        project uobxxgzshrmbtjfdolxd
Final verdict: PASS — AUTHENTICATED POSITIVE SMOKE AND IMMEDIATE IDEMPOTENCY
Residual risks: concurrency, missing-profile, inactive-profile,
rollback, reapply and frontend cutover remain unestablished
```

### 6.9 PR #104 gateway security gate — GPT3

```text
Owner: GPT3
Anchor: PR #104 head dc75198dd8d14fc2856890964771f3434942dd7a
        squash 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
Final verdict: PASS
```

### 6.10 PR #104 lifecycle gate — GPT4

```text
Owner: GPT4
Anchor: PR #104 head dc75198dd8d14fc2856890964771f3434942dd7a
        squash 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
Final verdict: PASS WITH RESIDUAL RISK
Residual risk: GitHub Actions absent; Vercel status did not prove SQL or Edge runtime
```

### 6.11 PR #105 SFJM closure gate

```text
Owner: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Anchor: PR #105 head d6cb8cf06abb1ad75e1712139c48ed14713170f3
        squash abae11749b7c591dd6a98b1bb7932edd46114de3
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.12 PR #106 documentation gate — GPT0

```text
Owner: GPT0
Anchor: PR #106 head 3b0d28406e15e9da979673eed1c7fdf81c609f76
        squash 9624900ada5d29e24476ab6a0a0907cb4854e509
Lifecycle result: CLOSED / MERGED
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

### 6.13 PR #106 lifecycle/scope gate — GPT4

```text
Owner: GPT4
Anchor: PR #106 head 3b0d28406e15e9da979673eed1c7fdf81c609f76
        squash 9624900ada5d29e24476ab6a0a0907cb4854e509
Lifecycle result: CLOSED / MERGED
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
```

## 7. PR #107 gate inventory

### 7.1 Original documentation gate — GPT0

```text
Owner: GPT0 — FECH.AI Documentation Auditor
Anchor: 51105692b0957454bd3d83f70e6591472fcf10dc
Final verdict: PASS
Changed-file contract: exactly seven documentation files
Canonical source: PR #107 review submission
Invalidated only for: later six-file PM-107-GATE-01 corrective delta
```

### 7.2 Original lifecycle/scope gate — GPT4

```text
Owner: GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist
Anchor: 51105692b0957454bd3d83f70e6591472fcf10dc
Final verdict: PASS
Canonical source: PR #107 review submission
Invalidated only for: later six-file PM-107-GATE-01 corrective delta
```

### 7.3 Ready transition

```text
Product Authority: EXPLICIT
Result: AUTHORIZED / EXECUTED
PR state after transition: OPEN / READY FOR REVIEW
Head preserved: 51105692b0957454bd3d83f70e6591472fcf10dc
```

### 7.4 Pre-merge validation

```text
Anchor: 51105692b0957454bd3d83f70e6591472fcf10dc
Final verdict: FAIL — PM-107-GATE-01
Reason: versioned SFJM lifecycle records remained stale after GPT0,
GPT4 and Ready had completed
Runtime/Supabase finding: none
```

### 7.5 PM-107-GATE-01 corrective gate

```text
Parent: 51105692b0957454bd3d83f70e6591472fcf10dc
Corrective head: resolve live
Commit count: exactly one corrective commit
Scope:
- docs/sfjm/AUTHORIZATIONS.md
- docs/sfjm/BLOCKED_ACTIONS.md
- docs/sfjm/CURRENT_STATE.md
- docs/sfjm/EVIDENCE_FRESHNESS.md
- docs/sfjm/NEXT_SAFE_ACTION.md
- docs/sfjm/handoffs/CURRENT.md
Final verdict: PENDING GPT0 DELTA-ONLY AUDIT
```

The corrective commit does not invalidate the smoke evidence, cleanup evidence, catalog evidence or historical gates outside the six-file delta.

## 8. Invalidation events

Revalidate only the narrow affected evidence after:

- change to PR #103 integrated migration content;
- change to RPC signature, owner, security mode or search path;
- ACL or role-membership change affecting execution;
- contradictory live catalog or authenticated runtime evidence;
- frontend cutover or security-boundary change;
- environment change;
- new material security finding;
- explicit expiration condition recorded by the original gate;
- head or changed-file change for a head-bound PR gate.

Current exact invalidation event:

```text
PM-107-GATE-01 corrective commit
→ GPT0/GPT4/pre-merge revalidation only for the six-file documentary delta
```

Not invalidation events:

- opening a new conversation;
- changing specialist;
- generic revalidation request;
- documentation-only main change with no demonstrated material impact;
- an accepted residual risk without new evidence;
- the accepted non-material `noop` issue comment.

## 9. Anti-loop rule

A re-audit request must identify:

```text
1. nominal gate;
2. owner;
3. prior anchor;
4. exact changed evidence;
5. triggered invalidation rule;
6. exact revalidation scope.
```

Otherwise:

```text
AUDIT_LOOP_BLOCKED
```
