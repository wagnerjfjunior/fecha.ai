# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR103_CATALOG_VALIDATED / FINAL_GATE_INVENTORY / FAIL_CLOSED`  
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

## 6. FINAL GATE INVENTORY

A gate may be reused only from this nominal inventory or from newer canonical evidence that explicitly supersedes it. Each record must keep owner, anchor, final verdict, residual risk and invalidation events separate.

### 6.1 PR #101 / F1-02 program baseline — GPT0

```text
Gate: PR #101 / F1-02 program baseline — documentation
Owner: GPT0 — FECH.AI Documentation Auditor
Canonical anchor: PR #101 head 003850d012a299a947452fa5a8135cd454998f15 / squash affbae1a598928010b0fa7db967734de522c13b4
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: final GPT0 report is not reconstructible from the current canonical record; merge state is not a substitute for the missing verdict
Explicit invalidation events: material change to the eight baseline documents; contradiction with the F1-02 master plan; newer canonical gate record
Canonical evidence source: PR #101 metadata and docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

### 6.2 PR #101 / F1-02 program baseline — GPT1

```text
Gate: PR #101 / F1-02 program baseline — architecture
Owner: GPT1 — FECH.AI Arquiteto SaaS
Canonical anchor: PR #101 head 003850d012a299a947452fa5a8135cd454998f15 / squash affbae1a598928010b0fa7db967734de522c13b4
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: final GPT1 report is not reconstructible from the current canonical record; the merged plan does not prove the missing architectural verdict
Explicit invalidation events: material change to program sequencing, dependencies, rollback model or environment strategy; newer canonical gate record
Canonical evidence source: PR #101 metadata and docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

### 6.3 PR #101 / F1-02 program baseline — GPT3

```text
Gate: PR #101 / F1-02 program baseline — Supabase security plan
Owner: GPT3 — FECH.AI Supabase Security Specialist
Canonical anchor: PR #101 head 003850d012a299a947452fa5a8135cd454998f15 / squash affbae1a598928010b0fa7db967734de522c13b4
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: final GPT3 report is not reconstructible from the current canonical record; no exploit or runtime test may be inferred from the merged plan
Explicit invalidation events: material change to the documented findings, Supabase contract, PR sequence or security boundary; newer canonical gate record
Canonical evidence source: PR #101 metadata and docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

### 6.4 PR #103 final documentation gate — GPT0

```text
Gate: PR #103 final documentation gate
Owner: GPT0 — FECH.AI Documentation Auditor
Canonical anchor: PR #103 final head abf6b4026343eae437283280269ed2997911dcec / squash 276a3e55155cd0e57b6155dc13b998704bdfd654
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: exact final GPT0 report is not present in the current canonical record; closure state does not supply the missing verdict
Explicit invalidation events: change to the PR #103 migration text, declared scope, rollback text or closure claims; newer canonical gate record
Canonical evidence source: PR #103 metadata/body and the integrated migration
```

### 6.5 PR #103 final architectural gate — GPT1

```text
Gate: PR #103 final architectural gate
Owner: GPT1 — FECH.AI Arquiteto SaaS
Canonical anchor: PR #103 final head abf6b4026343eae437283280269ed2997911dcec / squash 276a3e55155cd0e57b6155dc13b998704bdfd654
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: exact final GPT1 report is not present in the current canonical record
Explicit invalidation events: change to frontend/backend authority boundaries, compatibility sequence, migration scope or dependency on PR-02/PR-03; newer canonical gate record
Canonical evidence source: PR #103 metadata/body and docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md
```

### 6.6 PR #103 final security/catalog gate — GPT3

```text
Gate: PR #103 final security and catalog preflight gate
Owner: GPT3 — FECH.AI Supabase Security Specialist
Canonical anchor: PR #103 final head abf6b4026343eae437283280269ed2997911dcec
Final verdict: PASS — CODE AND CATALOG PREFLIGHT VALIDATED
Residual risks: application and authenticated runtime remained deferred at this gate; preflight did not establish positive smoke, idempotency, concurrency, rollback or reapply
Explicit invalidation events: migration-content change; contradictory catalog premises; function owner/search_path/ACL/uniqueness premise change; new material security finding
Canonical evidence source: PR #103 body, integrated migration and bounded catalog evidence described by that PR
```

### 6.7 PR #103 final lifecycle/merge gate — GPT4

```text
Gate: PR #103 final lifecycle and merge gate
Owner: GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist
Canonical anchor: PR #103 final head abf6b4026343eae437283280269ed2997911dcec / squash 276a3e55155cd0e57b6155dc13b998704bdfd654
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: the exact final GPT4 report is not present in the current canonical record; the successful merge proves lifecycle result, not the missing specialist verdict
Explicit invalidation events: head, base, changed-file set, checks, mergeability or merge-result contradiction; newer canonical gate record
Canonical evidence source: PR #103 live metadata
```

### 6.8 PR #103 controlled production application validation — GPT3

```text
Gate: PR #103 controlled production application validation
Owner: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Canonical anchor: main@276a3e55155cd0e57b6155dc13b998704bdfd654 / project uobxxgzshrmbtjfdolxd / migration 20260727080929_f1_02_password_state_rpc
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Migration: APPLIED
RPC: EXISTS
Catalog properties: OBSERVED
Operational closure: CLOSED WITH RESIDUAL RISK
Residual risks: authenticated positive smoke: not established; runtime idempotency: not established; runtime concurrency: not established; missing-profile execution: not established; inactive-profile execution: not established; rollback execution: not established; reapply after rollback: not established
Explicit invalidation events: function signature, owner, security mode, search_path or ACL change; migration-history contradiction; contradictory live catalog evidence; new authenticated runtime evidence
Canonical evidence source: docs/security/evidence/2026-07-27-pr103-operational-closure-with-residual-risk.md
```

### 6.9 PR #104 gateway final security gate — GPT3

```text
Gate: PR #104 bounded catalog gateway final security gate
Owner: GPT3 — FECH.AI Supabase Security Specialist
Canonical anchor: PR #104 head dc75198dd8d14fc2856890964771f3434942dd7a / squash 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
Final verdict: PASS
Residual risks: validation was limited to the bounded catalog gateway and did not approve PR #103 runtime or broader database access
Explicit invalidation events: change to gateway migration, RPC contract/ACL, Edge source, OpenAPI allowlist, authentication boundary or exposed catalog scope
Canonical evidence source: main@276a3e55155cd0e57b6155dc13b998704bdfd654:docs/sfjm/CURRENT_STATE.md and PR #104 metadata
```

### 6.10 PR #104 gateway lifecycle gate — GPT4

```text
Gate: PR #104 gateway lifecycle gate
Owner: GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist
Canonical anchor: PR #104 head dc75198dd8d14fc2856890964771f3434942dd7a / squash 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
Final verdict: PASS WITH RESIDUAL RISK
Residual risks: GitHub Actions were absent for the audited head and Vercel status alone did not prove SQL or Edge runtime
Explicit invalidation events: head, changed-file set, checks, deployment artifact, Edge version or merge-result change
Canonical evidence source: main@276a3e55155cd0e57b6155dc13b998704bdfd654:docs/sfjm/CURRENT_STATE.md and PR #104 metadata
```

### 6.11 PR #105 SFJM closure gate

```text
Gate: PR #105 SFJM closure gate
Owner: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Canonical anchor: PR #105 head d6cb8cf06abb1ad75e1712139c48ed14713170f3 / squash abae11749b7c591dd6a98b1bb7932edd46114de3
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: exact gate owner and final specialist verdict are not reconstructible from the current canonical record
Explicit invalidation events: contradiction in PR #105 scope, merge result or recorded PR #104 handoff; newer canonical gate record
Canonical evidence source: PR #105 metadata/body
```

### 6.12 PR #106 current documentation gate — GPT0

```text
Gate: PR #106 current documentation gate
Owner: GPT0 — FECH.AI Documentation Auditor
Prior attempt target: b9aa83a50f34c7cfbbd8158aeae01df39b787e50
Live head observed during that attempt: 94b2174339b870331d62aca5c6d9d9cf1149ce3e
Prior result: FAIL — HEAD CHANGED
Prior substantive documentary verdict: NONE
Current corrected-head documentary verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Corrective commit: 94b2174339b870331d62aca5c6d9d9cf1149ce3e — docs(sfjm): fix PR106 authority and gate inventory
Corrective commit scope: new content that required an independent audit of the complete current head; no prior substantive finding is attributed to this commit
Residual risks: the final GPT0 verdict for the authorized one-file documentary correction remains pending
Explicit invalidation events: any later head change, additional commit or changed file outside docs/sfjm/EVIDENCE_FRESHNESS.md invalidates the pending one-file delta validation
Canonical evidence source: PR #106 live metadata and the authorized corrective audit cycle
```

### 6.13 PR #106 current lifecycle/scope gate — GPT4

```text
Gate: PR #106 current lifecycle and scope gate
Owner: GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist
Canonical anchor: corrective head produced by the single commit containing this inventory; exact SHA must be captured by post-commit validation
Final verdict: UNKNOWN — CANONICAL EVIDENCE REQUIRED
Residual risks: final GPT4 lifecycle/scope validation has not yet been completed
Explicit invalidation events: later head change, extra commit, changed-file set outside the seven-document PR scope, base drift, mergeability/check contradiction or PR-state change
Canonical evidence source: PR #106 live metadata and the authorized corrective audit cycle
```

The `UNKNOWN` state does not authorize an invented verdict. Do not request a new audit merely to replace an historical documentation gap.

The one GPT0 and one GPT4 validations already authorized for the exact PR #106 corrective head remain required for the current closure lifecycle. After they complete, do not repeat them without a new material invalidation event and new authority.

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
