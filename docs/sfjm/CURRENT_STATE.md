# FECH.AI — SFJM Current State

**Lifecycle state:** `F1_02_CONTROLLED_BETA_PRIMARY_STRATEGY_IN_DRAFT / SECURITY_GO_DENIED`  
**Record type:** `OPERATIONAL_STATE / DOCUMENTATION_ONLY`  
**Observed on:** `2026-07-25`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Context understood

FECH.AI is an MVP Família in controlled beta. It is not yet broadly commercialized or sold under a paid SLA.

```text
Real users: YES
Multiple companies: YES
Sensitive lead/customer data: YES
Participants informed of beta/data-loss risk: YES
Paid SLA: NO
Security Go: DENIED
```

Frontend requests and displays. Backend/RPC/Supabase validates and decides. AI assists, but is not authority.

## 2. Canonical GitHub state

```text
Canonical main: affbae1a598928010b0fa7db967734de522c13b4
Commit: docs(security): establish F1-02 remediation program (#101)
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
```

PR #101 established the F1-02 evidence and remediation baseline. It did not grant Security Go or authorize technical implementation.

## 3. Material product-risk decision

Wagner accepted the following operating risks for informed MVP Família participants:

- service interruption and maintenance;
- temporary unavailability;
- manual recovery/support;
- possible loss of beta data;
- absence of a paid SLA.

This does not accept:

- privilege escalation;
- cross-tenant access;
- disclosure of sensitive data;
- destructive testing against real records;
- unbounded database changes;
- false Security Go claims.

## 4. Controlled Beta Primary strategy

The authorized documentation branch is:

```text
Branch: docs/f1-02-controlled-beta-primary-strategy
Base: affbae1a598928010b0fa7db967734de522c13b4
Title: docs(security): adopt controlled beta primary remediation strategy
Type: documentation-only Draft PR
```

The strategy amendment permits the primary Supabase project to be used for future bounded remediation windows only after separate GitHub and environment authorizations.

It supersedes only the isolated-lab prerequisite. All security, rollback, evidence and separation-of-duty controls remain active.

Canonical strategy artifact in this branch:

```text
docs/security/evidence/2026-07-25-f1-02-controlled-beta-primary-strategy.md
```

## 5. Security state

```text
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
MVP Família security readiness: NOT CONFIRMED
Broad paid commercialization: BLOCKED
WDP: 0
```

Confirmed blockers remain:

1. direct broker self-update can alter authority-bearing fields;
2. direct structural CRM writes remain exposed;
3. direct funnel-history insertion can bypass controlled transitions;
4. list ACL targets are not fully proven same-company;
5. funnel-stage, import-session, feedback and Auth controls require remediation/evidence.

## 6. Environment classification

```text
Supabase project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Classification: CONTROLLED BETA PRIMARY
Commercial production: NO
Real users/data: YES
```

The project is not an unrestricted laboratory. Real identifiers and records must not be used as negative-test fixtures.

## 7. Current authority

The user authorized only:

- creation of the exact documentation branch from `affbae1a...`;
- documentation of the Controlled Beta Primary decision;
- SFJM reconciliation;
- one Draft documentation PR.

The authority does not permit:

- runtime/frontend changes;
- migrations or SQL;
- RLS, grants, policies, RPCs or Auth changes;
- Supabase access or mutation;
- negative tests;
- Ready or merge;
- PR-01 implementation;
- Security Go or WDP.

## 8. Evidence available

- PR #101 exact lifecycle and squash commit;
- canonical F1-02 findings and master plan;
- user decision accepting beta availability/data-loss risk;
- exact Controlled Beta Primary strategy contract;
- current known security blockers;
- exact documentation branch and base.

## 9. Evidence missing

- independent audit of the strategy PR final head;
- Ready and merge authorization for the strategy PR;
- exact PR-01 implementation envelope;
- current Supabase preflight at PR-01 execution time;
- approved synthetic fixture manifest;
- executed migration/rollback/smoke evidence;
- post-remediation security evidence;
- final Security Go decision.

## 10. Main risks

- confusing accepted availability/data-loss risk with accepted security failure;
- using real users or data in security tests;
- applying several security changes in one window;
- treating the strategy document as Supabase mutation authority;
- implementing PR-01 before this amendment is canonical;
- broad commercialization before Security Go.

## 11. Areas not to alter without separate authorization

- runtime and frontend;
- Supabase schema/data/migrations/RLS/grants/policies/RPCs/Auth;
- Edge Functions, Vercel and GitHub Actions;
- real users, companies, brokers, teams, leads or customers;
- Security Go, F1-02 acceptance or WDP.

## 12. Next safe action

Complete the bounded documentation commit set, open one Draft PR, validate its exact head/files/diff and route it to independent GPT0/GPT1/GPT3 review.

Do not begin PR-01 or mutate the primary Supabase project until this strategy amendment is merged and a separate bounded implementation/environment authorization is granted.