# FECH.AI — F1-02 Controlled Beta Primary Strategy Amendment

**Status:** `PRODUCT_AUTHORITY_DECISION_RECORDED / PR_DRAFT / NOT_YET_CANONICAL / DOCUMENTATION_ONLY / SECURITY_GO_DENIED`  
**Date:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**PR:** `#102`  
**Base:** `affbae1a598928010b0fa7db967734de522c13b4`  
**Branch:** `docs/f1-02-controlled-beta-primary-strategy`  
**Pre-correction head:** `fc83ed752217bfc39810dfba38e93405bc7382b8`

## 1. Decision

The product authority decided that MVP 1 — Família will continue as a controlled free beta on the primary Supabase project.

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Broad paid commercialization: BLOCKED
Paid SLA: NO
Real users and data: YES
Security Go: DENIED
```

The decision accepts operating risk but does not reduce multi-company security requirements.

## 2. Accepted operating risk

- downtime and maintenance;
- temporary unavailability;
- manual support and recovery;
- possible loss of beta data;
- rollback to a previous application/schema state;
- no paid SLA.

## 3. Risk not accepted

- privilege escalation;
- cross-tenant access or mutation;
- disclosure of sensitive data, credentials or tokens;
- unauthorized change of authority, company, team or user linkage;
- forged real CRM history;
- offensive or destructive tests against real users/data;
- unbounded or silent database changes;
- broad paid commercialization before Security Go.

Possible data loss is not a security or privacy waiver.

## 4. Supersession and precedence

This amendment supersedes the original F1-02 master plan only where that plan makes an isolated Supabase environment a universal prerequisite.

After PR #102 is merged, this amendment prevails over conflicting lab-only clauses. The master plan is updated in the same PR to remove operational ambiguity.

### 4.1 Superseded rules

- mandatory isolated branch before every implementation;
- absolute stop of all remediation when a lab is unavailable;
- universal `LAB_VALIDATION_PASSED` state;
- mandatory live-equivalent rollback/reapply rehearsal in a lab for every migration;
- universal “apply only in lab” checklist language;
- lab-cost confirmation as the mandatory next action before PR-01.

### 4.2 Preserved rules

- Pilot Production / live classification;
- Security Go denied;
- one PR / one risk / one rollback;
- exact environment and GitHub authority;
- current evidence and fail-closed behavior;
- independent audit;
- synthetic-only fixtures;
- no real-data negative testing;
- rollback design;
- separate GitHub lifecycle and Supabase-operation authorities;
- final Security Go gate;
- broad commercialization blocked.

## 5. Controlled validation categories

Every future test must be assigned one category before authorization.

### `SAFE_LIVE`

A bounded check on the primary project where unexpected success or failure cannot escape the synthetic graph or grant real authority.

### `ISOLATED`

Required when unexpected success can create admin/root authority, expose real data, change global controls, require reset, fuzzing or destructive rollback/reapply.

### `DEFERRED`

Required evidence that cannot currently be executed safely. It remains `NOT_VERIFIED` and may block Security Go.

### `PROHIBITED`

Never execute with real actors/data, broad discovery, real credentials, untrusted `service_role`, deliberate corruption or control disabling.

The universal lifecycle gate becomes:

```text
CONTROLLED_VALIDATION_PASSED
```

The evidence record must list all tests by category.

## 6. B1 containment rule

The primary project must not be used to attempt actual self-promotion to `admin_global`, root or equivalent authority.

A synthetic account is not sufficient containment: if the control fails, that account gains real authority over a live project containing real companies and data.

Allowed on the primary project for B1:

- read-only proof of grants/policies/functions;
- proof that authority-bearing direct update exposure was removed;
- review of the narrow RPC contract;
- positive smoke of the controlled RPC with a synthetic actor;
- rejection tests that cannot create authority or access real data.

The actual adversarial self-promotion test remains:

```text
B1 GLOBAL SELF-ESCALATION NEGATIVE TEST: NOT_VERIFIED WITHOUT ISOLATION
```

## 7. Intentional `admin_global` assignment

An intentional decision to designate a named user as `admin_global` is not a negative test and does not prove that self-escalation is blocked.

It may occur only under a separate administrative-governance authorization containing:

- exact user identity;
- verified need;
- least-privilege rationale;
- server-side controlled operation;
- audit trail;
- effective date and owner;
- revocation/deactivation procedure;
- post-operation verification.

No such assignment is authorized by PR #102.

## 8. Synthetic graph contract

Safe-live fixtures must form a wholly synthetic graph.

Required invariants:

1. Synthetic companies, users, brokers, teams, lists, lots, leads and stages reference only synthetic objects.
2. No synthetic object references a real company, user, broker, team, list, lead or customer.
3. Real brokers never receive synthetic leads, tasks, lots or lists.
4. Synthetic users never receive global authority capable of reaching real data.
5. Tests use exact synthetic identifiers; no broad discovery query is allowed.
6. Unexpected success remains contained to the synthetic graph.
7. Cleanup failure blocks additional tests and starts containment.
8. Fixture cleanup is distinct from schema/configuration rollback.

Fixture creation requires separate `CONTROLLED_BETA_PRIMARY_CHANGE` authority.

## 9. Explicitly prohibited primary-project tests

- `role = admin_global` or equivalent self-elevation;
- modification of authority-bearing fields as an adversarial test;
- broad cross-company SELECTs;
- use of IDs belonging to real companies or records;
- fuzzing, load, volume or mixed-tenant offensive batches;
- disabling RLS, policies, grants or Auth;
- `service_role` in frontend/browser/untrusted clients;
- reuse of real JWTs, passwords, emails, phones or payloads;
- destructive data tests;
- experimental schema rollback/reapply.

## 10. Authorization separation

```text
WINDOW_IMPLEMENTATION
→ creates/updates one technical PR

TECHNICAL_PR_LIFECYCLE
→ authorizes Ready and exact-head merge

CONTROLLED_BETA_PRIMARY_CHANGE
→ authorizes one exact live Supabase operation

SECURITY_GATE
→ authorizes only the final security decision
```

A merged PR does not authorize SQL or configuration application.

## 11. Rollback distinction

```text
Synthetic fixture cleanup
!=
Schema/configuration rollback
```

Fixture cleanup affects only the authorized synthetic graph.

Schema/configuration rollback affects the live environment and requires exact operation identity, impact analysis, ordering, monitoring, stop conditions and separate authority.

## 12. Current lifecycle

```text
PR #102: OPEN / DRAFT
Strategy decision: RECORDED BY PRODUCT AUTHORITY
Repository acceptance: NOT YET GRANTED
Pre-correction head: fc83ed752217bfc39810dfba38e93405bc7382b8
Final corrective head: resolve live from PR metadata and updated PR description
Changed files after correction: 8 documentation files
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
PR-01: NOT AUTHORIZED
Supabase: NOT AUTHORIZED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

The final commit cannot embed its own SHA without changing that SHA. Live GitHub metadata and the PR description are authoritative for the final corrective head.

## 13. Rollback of this amendment

One revert of PR #102 restores the prior universal isolated-lab strategy.

That documentation revert does not revert any later migration or Supabase operation; technical rollbacks remain independent.

## 14. Next safe action

Validate the single corrective commit, the eight-file diff and the updated PR description. Then repeat independent GPT0/GPT1/GPT3 audits at the exact new head.

No technical or Supabase action is authorized.
