# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / F1_02_REMEDIATION / FAIL_CLOSED`  
**Observed on:** `2026-07-25`

## 1. Product blocks

- declare MVP 1 — Família security-ready;
- grant Security Go or F1-02 acceptance;
- award WDP;
- broad paid commercialization;
- represent beta-risk acceptance as a privacy/security waiver;
- start PR-01 before PR #102 is independently accepted and merged.

## 2. PR #102 lifecycle blocks

```text
PR #102: OPEN / DRAFT
Pre-correction head: fc83ed752217bfc39810dfba38e93405bc7382b8
Final corrective head: resolve live from GitHub metadata/PR description
Ready: BLOCKED pending GPT0/GPT1/GPT3 re-audit
Merge: BLOCKED pending Ready, exact-head gate and separate authority
Additional commits: BLOCKED absent new bounded correction authority
```

## 3. Security blocks

- self-promotion to `admin_global`, root or equivalent authority in the primary project;
- testing authority-bearing `corretores` mutations when unexpected success creates real privilege;
- broad cross-tenant discovery queries;
- use of real company, user, broker, team, list, lead or customer IDs in security tests;
- use of real accounts or credentials as actors/fixtures;
- access or mutation of real data for testing;
- forged real funnel history;
- fuzzing, load, volume or mixed-tenant offensive batches;
- disabling RLS, grants, policies or Auth to test;
- `service_role` in frontend/browser/untrusted clients;
- reuse of real JWTs, passwords, emails, phone numbers or payloads;
- destructive or exploratory SQL;
- experimental rollback/reapply in the primary project.

## 4. Synthetic-fixture blocks

Until a separate live-operation authority and manifest exist, do not create fixtures.

Even after authorization, block any fixture set that:

- references real objects;
- can be distributed to real brokers;
- grants global authority to a synthetic actor;
- uses broad discovery instead of exact synthetic IDs;
- lacks pre/post counts, cleanup/deactivation and stop conditions;
- allows unexpected success to escape the synthetic graph.

Cleanup failure blocks further tests and starts containment.

## 5. Intentional administrator assignment

Naming a deliberate `admin_global` is blocked until a separate `ADMINISTRATIVE_ROLE_CHANGE` authority identifies the exact user, necessity, least-privilege rationale, controlled server-side operation, audit trail and revocation plan.

An intentional assignment is not a self-escalation test and cannot be used as B1 negative evidence.

## 6. Runtime and environment blocks

Without separate exact scope and authority, do not change:

- frontend or runtime;
- schema, data, migrations, RLS, grants, policies, functions/RPCs or Auth;
- Edge Functions;
- Vercel or GitHub Actions;
- MesaCliente, PME, ADS/CAPI, Make/n8n or integrations.

## 7. Rollback blocks

- do not treat fixture cleanup as schema rollback;
- do not execute schema/config rollback without exact live-operation authority;
- do not merge a technical PR without rollback design;
- do not rehearse destructive rollback/reapply on the primary project merely to prove reversibility;
- do not improvise follow-up SQL after an unexpected result.

## 8. Audit and evidence blocks

- no audit without exact PR/head/diff/final files;
- no Ready recommendation after head change without re-audit;
- no executor self-approval;
- no claim that a designed test was executed;
- no claim of tenant isolation, B1 closure or Security Go from static documentation alone;
- no replacement of missing evidence with participant acceptance or confidence.

## 9. Removal rule

A block is removed only when the record identifies:

- exact evidence;
- repository/commit/environment;
- responsible validator;
- exact authority;
- permitted scope;
- residual risk;
- rollback/containment;
- expiration;
- next safe action.
