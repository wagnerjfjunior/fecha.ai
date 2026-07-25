# FECH.AI — F1-02 Controlled Beta Primary Strategy

**Status:** `APPROVED_STRATEGY_AMENDMENT / DOCUMENTATION_ONLY / SECURITY_GO_DENIED`  
**Date:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Canonical base:** `affbae1a598928010b0fa7db967734de522c13b4`  
**Product phase:** `MVP 1 — Família`  
**Supabase project:** `Discador-MesaCliente`  
**Project ref:** `uobxxgzshrmbtjfdolxd`

## 1. Decision

Wagner, as product authority, accepted a controlled-beta operating strategy for the current MVP Família.

The FECH.AI SaaS is not yet broadly commercialized or sold under a paid SLA. Current participants use the beta without charge, know that the product is under validation and have accepted the possibility of service interruption and data loss.

The primary Supabase project may therefore be used for **bounded, separately authorized remediation windows** under the classification:

```text
CONTROLLED BETA PRIMARY
```

This decision removes the isolated Supabase Branch as a mandatory prerequisite for every F1-02 technical step.

It does **not** turn the primary database into an unrestricted laboratory and does not authorize any technical change by itself.

## 2. Supersession boundary

This document supersedes only the following parts of `F1-02_REMEDIATION_MASTER_PLAN.md`:

- the requirement that one isolated Supabase Branch must exist before any remediation implementation;
- the rule that unavailability of that branch necessarily stops all technical remediation;
- the absolute prohibition on controlled remediation and synthetic validation in the primary beta environment.

The following master-plan controls remain fully effective:

- Security Go remains denied;
- one PR equals one primary risk and one simple rollback;
- frontend requests and displays; backend/RPC/Supabase validates and decides;
- no evidence means no approval;
- the executor does not approve its own work;
- exact environment, branch, head, files and operations must be identified;
- each migration requires preflight, rollback, smoke evidence and independent review;
- broad commercial release remains blocked until Security Go;
- real customer/lead data must not be used as test fixtures;
- cross-tenant isolation remains a mandatory security boundary.

## 3. Risk explicitly accepted for the beta

The following risks are accepted for current informed beta participants:

- planned or unplanned downtime;
- maintenance windows;
- temporary feature unavailability;
- manual support and manual recovery;
- loss of recent or non-critical beta data;
- rollback to an earlier schema/application state;
- absence of a paid availability or recovery SLA;
- iterative corrections during MVP validation.

This acceptance is an operating-risk decision. It is not a security waiver.

## 4. Risk not accepted

The following remain unacceptable and BLOCKING:

- a broker obtaining local or global administrative authority without authorization;
- one company reading or modifying another company's data;
- disclosure of leads, customer contact data, credentials or tokens;
- forged CRM or funnel history affecting real records;
- destructive or offensive tests against real users, companies, brokers, teams, leads or customers;
- intentional corruption of real records to validate rollback;
- broad migrations without bounded scope and rollback;
- silent changes to Supabase, Auth or production configuration;
- claiming Security Go without executed and current evidence.

A beta notice about possible data loss does not authorize privacy, tenant-isolation or privilege-boundary failures.

## 5. Environment classification

The primary project is classified as:

```text
Environment: CONTROLLED BETA PRIMARY
Commercial production: NO
Paid SLA: NO
Real users: YES
Real multi-company data: YES
Sensitive lead/customer data: YES
Security Go: DENIED
Broad commercialization: BLOCKED
```

Because real users and real data exist, every technical operation remains a live-environment change and requires explicit authorization.

## 6. Future changes permitted only under separate authority

A future bounded authorization may permit one exact remediation operation in the primary project when all of the following are declared:

- repository and exact base/head;
- one primary security risk;
- exact migration, RPC, policy, grant, Auth or frontend object;
- exact Supabase project ref;
- exact preflight queries;
- maintenance/communication requirement;
- backup or recovery preparation appropriate to the change;
- deterministic rollback;
- positive smoke checks;
- bounded negative checks using synthetic fixtures only;
- monitoring and stop conditions;
- independent audit and lifecycle gates;
- expiration of authority after completion.

No generic phrase such as "continue", "implement" or "use the main database" authorizes a mutation.

## 7. Synthetic validation in the primary project

Security validation in the primary project may use only clearly identified synthetic fixtures created under a separate authorization.

The minimum fixture model is:

- synthetic company A and company B;
- synthetic admin/local manager/broker actors;
- synthetic teams, lists, lots, leads and funnel states;
- identifiers that cannot be confused with real customer records;
- a manifest of created objects;
- deterministic cleanup or deactivation;
- pre-test and post-test counts;
- sanitized evidence without secrets or real payloads.

Permitted tests may include:

- positive authorized flows using synthetic records;
- denial of direct privilege changes by a synthetic broker;
- denial of synthetic cross-company access;
- denial of direct CRM/history writes after revocation;
- RPC success and rollback checks against synthetic records.

Prohibited tests include:

- targeting real company, broker, team, lead or customer identifiers;
- attempting privilege escalation with a real account;
- reading another real company's records;
- destructive volume/load testing;
- deliberate corruption of real data;
- uncontrolled mixed-tenant arrays;
- tests without cleanup, stop condition or evidence plan.

## 8. Change-window contract

Each remediation window in the primary project must be executed as follows:

```text
1. Validate live GitHub and Supabase state read-only.
2. Confirm exact authority and one-risk scope.
3. Prepare migration/change and rollback in the repository.
4. Obtain independent specialist review.
5. Authorize and merge the exact PR separately.
6. Authorize the exact primary-environment application separately.
7. Apply one bounded change.
8. Run positive smoke checks first.
9. Run only approved synthetic negative checks.
10. Stop fail-closed on any unexpected result.
11. Roll back when acceptance criteria fail.
12. Capture sanitized evidence and update the gate state.
```

## 9. Rollback and incident posture

Before each primary-environment change, the rollback must state:

- exact reverse SQL/configuration or revert mechanism;
- objects and grants restored;
- expected data impact;
- maximum tolerated maintenance window;
- validation after rollback;
- responsible operator;
- incident trigger and escalation path.

Possible beta data loss may be accepted, but an unknown or unbounded rollback is not accepted.

## 10. Security and commercialization gates

This strategy does not change the current decisions:

```text
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
Broad paid commercialization: BLOCKED
PR-01 implementation: REQUIRES SEPARATE AUTHORIZATION
Primary Supabase mutation: REQUIRES SEPARATE AUTHORIZATION
```

The MVP Família may continue as a controlled beta with informed participants, but no document may describe it as security-approved or generally production-ready.

## 11. Next safe action

1. Audit and merge this strategy amendment through a documentation-only PR.
2. After merge, define PR-01 as one bounded risk with exact files, migration/change objects, tests and rollback.
3. Do not mutate Supabase, Auth, runtime or data until PR-01 and the exact primary-environment operation receive separate authorizations.

## 12. Rollback of this decision

Rollback is one revert of the documentation-only strategy PR.

Reverting this decision restores the isolated-lab prerequisite from the original F1-02 master plan. It does not roll back or authorize any technical database change.