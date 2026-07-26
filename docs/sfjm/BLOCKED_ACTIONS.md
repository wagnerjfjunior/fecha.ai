# FECH.AI — SFJM Blocked Actions

**Status:** `ACTIVE_BLOCKS / PR104_GATEWAY / PR103_FROZEN / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product blocks

- declare MVP 1 — Família security-ready;
- grant Security Go or F1-02 acceptance;
- award WDP from PR count or documentation alone;
- broad paid commercialization;
- represent controlled-beta risk acceptance as a privacy/security waiver.

## 2. PR #103 freeze blocks

```text
PR #103: OPEN / DRAFT
Head: abf6b4026343eae437283280269ed2997911dcec
Additional commits: BLOCKED
Metadata changes: BLOCKED
Ready: BLOCKED
Merge: BLOCKED
Supabase application: BLOCKED
```

The freeze remains until the bounded GPT3 catalog gateway is available and GPT3 repeats the exact-head audit.

Do not create a PR #103 correction merely to compensate for missing evidence. The current GPT3 finding is an evidence blocker, not a demonstrated migration defect.

## 3. PR #104 lifecycle blocks

```text
PR #104: OPEN / DRAFT
Final head: resolve live
Ready: BLOCKED pending exact-head GPT0/GPT1/GPT3/GPT4 audits
Merge: BLOCKED pending Ready, fresh checks and separate authority
Additional commits after final Draft head: BLOCKED
```

Any file outside the declared ten-path scope is scope creep and blocks Ready.

## 4. Live Supabase / Edge / Action blocks

Until separate `CONTROLLED_BETA_PRIMARY_CHANGE` authority exists, do not:

- apply `20260726180000_gpt_security_metadata_snapshot.sql`;
- create, replace, alter, grant, revoke or drop `public.gpt_security_metadata_snapshot()`;
- deploy the versioned `gpt-especialista` Edge Function;
- change `verify_jwt`;
- update the GPT Action from the versioned OpenAPI;
- run post-deploy smoke or negative gateway tests;
- reload PostgREST schema as part of an application sequence;
- improvise SQL after an unexpected result.

The already active Edge Function version 7 and Action configuration are observed live state, not authorization for further change.

## 5. Data and discovery blocks

The gateway must never allow:

- arbitrary SQL;
- caller-supplied schema, table, function, role or ID;
- application row reads;
- `auth.users` row reads;
- lead, customer, message or payload access;
- secrets, tokens or credentials;
- broad catalog discovery outside the fixed PR103 snapshot;
- fuzzing, load or volume testing;
- use of real JWTs, passwords, emails or phone numbers in evidence.

Function source is limited to trigger functions directly attached to `public.corretores` for the PR #103 evidence question.

## 6. Authentication blocks

- do not record `GPT3_FECHAI_ESPECIALISTA` values;
- do not expose the secret in screenshots, logs, PR bodies or comments;
- do not treat user-declared rotation as permission to read or display the value;
- do not enable unauthenticated arbitrary operations because `verify_jwt` is off;
- do not move `service_role` into frontend, browser or an untrusted client.

Custom server-to-server authentication must remain enforced by the Edge handler.

## 7. Security-test blocks

On the primary project, block:

- actual self-promotion to `admin_global`, root or equivalent;
- adversarial authority-field mutation;
- cross-tenant discovery;
- real-data fixtures;
- deliberate duplicate/corrupt states;
- disabling RLS, policies, grants or Auth;
- destructive rollback/reapply experiments.

The gateway is for catalog evidence only. It does not authorize runtime negative tests for PR #103.

## 8. Rollback blocks

- do not execute gateway rollback without exact live-operation authority;
- do not treat Git revert as database rollback;
- do not drop or redeploy live objects to prove reversibility;
- do not let rollback of PR #104 alter PR #103 or `public.corretores`;
- do not continue after rollback, ACL or contract validation fails.

## 9. Audit and evidence blocks

- no audit without exact PR/head/diff/final files;
- no Ready recommendation after a head change without re-audit;
- no executor self-approval;
- no claim that the migration or Edge version was deployed when it was only versioned;
- no claim that Action success occurred before live application;
- no claim of PR #103 acceptance from the gateway PR;
- no replacement of missing evidence with confidence or user acceptance.

## 10. Removal rule

A block is removed only when the record identifies:

- exact evidence;
- repository, commit and environment;
- responsible validator;
- exact authority;
- permitted scope;
- residual risk;
- rollback/containment;
- expiration;
- next safe action.
