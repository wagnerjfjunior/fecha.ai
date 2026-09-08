# FECH.AI — Security Go Program, Methodology & Proof Contract

**Status:** `CANONICAL_SECURITY_GO_METHOD_V1 / PR_HEAD_ONLY / NOT_SECURITY_GO`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Program:** `FECH.AI Security-to-Scale 2026`  
**Product Authority:** Wagner / FECH.AI  
**Current Security Go:** `NOT_GRANTED`

---

## 1. Why this document exists

This is the canonical entry point for answering five questions:

1. **What does FECH.AI mean by "secure enough for Security Go"?**
2. **What attack classes and product surfaces must be covered?**
3. **How are WBS tasks, STS tasks, PRs, tests and evidence related?**
4. **What constitutes proof, and what does not constitute proof?**
5. **What exact conditions must be true before Product Authority may grant Security Go?**

This document is deliberately broader than multi-tenancy.

Cross-tenant isolation is mandatory, but it is only one attack domain. FECH.AI Security Go requires a defensible security argument across the application's material attack surface.

---

## 2. The destination

The program target is not:

```text
"we fixed many security bugs"
```

and not:

```text
"CI is green"
```

and not:

```text
"no breach has happened yet"
```

The target is:

```text
FECH.AI SECURITY GO CANDIDATE
=
material attack surface identified
+ required controls implemented
+ structural invariants enforced
+ negative tests executed
+ hostile-client tests executed where safe/authorized
+ tenant/auth/role/storage regression passed
+ supply-chain/config/deploy gates passed
+ observability/incident controls verified
+ residual risk explicitly adjudicated
+ evidence exact-ref/fresh/current
+ zero open blocking security finding
```

Only after those conditions are satisfied may Product Authority make the separate decision:

```text
SECURITY GO = GRANTED
```

Security Go is an internal FECH.AI release/security decision. It is **not** a third-party certification and must not be represented as OWASP, NIST or external auditor certification unless such certification separately occurs.

---

## 3. Core security principles

### 3.1 Preventive, not reactive

```text
NO CURRENT CORRUPTION
!=
SAFE DESIGN
```

A structural path that permits an invalid or unauthorized operation is a security gap even if no invalid data currently exists.

### 3.2 Fail closed

For security-sensitive operations:

```text
missing identity
OR inconsistent tenant
OR missing permission
OR ambiguous ownership
OR stale/incomplete evidence
=
DENY / BLOCK / DO NOT CLAIM PASS
```

### 3.3 Server-side authority

Frontend input is never final authority for:

- tenant / empresa;
- user identity;
- role;
- team;
- ownership;
- permission;
- financial authority;
- distribution authority;
- privileged workflow state;
- security-sensitive lifecycle state.

### 3.4 Tenant relationship integrity

`empresa_id` on a row is not sufficient proof of multi-tenant safety.

All material referenced objects must also be tenant-consistent where required:

```text
row.empresa_id
=
referenced_object.empresa_id
=
authorized_actor.empresa_id
```

or the operation must be denied.

### 3.5 Least privilege

Direct grants, RPC EXECUTE, service roles, admin/root functions, storage permissions and deployment credentials must be restricted to the minimum authority required.

### 3.6 Evidence over assumption

```text
EXPECTED
!= OBSERVED

VERSIONED
!= APPLIED

APPLIED
!= TESTED

TESTED ON OLD REF
!= CURRENT PASS
```

---

## 4. Security Go methodology

FECH.AI uses a layered assurance method:

```text
THREAT MODEL
    ↓
ATTACK-SURFACE INVENTORY
    ↓
SECURITY REQUIREMENTS
    ↓
STRUCTURAL CONTROLS
    ↓
STATIC VERIFICATION
    ↓
LIVE CATALOG / CONFIG VERIFICATION
    ↓
NEGATIVE / HOSTILE RUNTIME TESTS
    ↓
REGRESSION
    ↓
RESIDUAL-RISK ADJUDICATION
    ↓
FINAL EVIDENCE PACKAGE
    ↓
BLOCKER CLOSEOUT
    ↓
PRODUCT AUTHORITY SECURITY GO DECISION
```

No individual layer substitutes for the next one.

---

## 5. External reference baselines

FECH.AI uses external security standards as coverage references, not as automatic certification claims.

### OWASP ASVS 5.0.0

Primary verification-requirements baseline for web application technical security controls.

Reference:

`https://owasp.org/www-project-application-security-verification-standard/`

FECH.AI should map material controls to version-qualified ASVS requirements where practical.

### OWASP Top 10:2025

Web application risk coverage baseline.

Reference:

`https://owasp.org/Top10/2025/`

### OWASP API Security Top 10:2023

API-specific threat coverage, including BOLA, broken authentication, object-property authorization, function authorization, resource consumption, sensitive business flow abuse, SSRF and unsafe API consumption.

Reference:

`https://owasp.org/API-Security/`

### NIST SP 800-218 SSDF 1.1

Secure software development lifecycle reference for integrating security practices into development and release processes.

Reference:

`https://csrc.nist.gov/pubs/sp/800/218/final`

These references complement FECH.AI-specific business, tenant, Supabase, runtime and operational requirements.

---

## 6. Attacker classes

Security assurance must evaluate at least these attacker perspectives.

### ATTACKER-A — Anonymous internet attacker

No valid FECH.AI account.

Targets include:

- public endpoints;
- anonymous RPCs;
- authentication endpoints;
- password/reset flows;
- exposed Edge Functions;
- unauthenticated storage;
- rate limits;
- injection;
- SSRF;
- file/parser abuse;
- information disclosure;
- denial of service.

### ATTACKER-B — Authenticated user in Tenant A

Valid low/normal privilege user.

Targets include:

- Tenant A → Tenant B object access;
- BOLA / IDOR;
- forged object UUIDs;
- ownership bypass;
- team bypass;
- property/mass-assignment attacks;
- direct DML;
- RPC misuse;
- storage cross-tenant access;
- privilege escalation.

### ATTACKER-C — Compromised tenant administrator

Valid administrator for Tenant A.

Must not be able to convert tenant-local authority into platform/global authority or control Tenant B.

Targets include:

- admin-to-root escalation;
- cross-company provisioning;
- tenant lifecycle abuse;
- permission forgery;
- root/admin contract ambiguities.

### ATTACKER-D — Compromised integration/service context

Targets include:

- service-role misuse;
- webhook replay;
- leaked integration credentials;
- unsafe third-party API trust;
- CI/CD credential abuse;
- cross-tenant payload confusion.

### ATTACKER-E — Malicious or compromised dependency/build path

Targets include:

- dependency CVEs;
- malicious package updates;
- workflow tampering;
- artifact integrity;
- deploy credential abuse;
- branch/deployment bypass.

---

## 7. The 22 mandatory security domains

The canonical machine-readable ownership mapping is in:

`docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json`

Security Go coverage must address all material domains below.

| ID | Security domain | Core question |
|---|---|---|
| SEC-01 | Tenant isolation / BOLA / IDOR | Can Tenant A access or affect Tenant B? |
| SEC-02 | Property-level authorization / mass assignment | Can a caller modify protected fields they do not own? |
| SEC-03 | Function-level authorization | Can a caller invoke privileged functions/RPCs? |
| SEC-04 | Privilege escalation | Can a user/admin gain a stronger role improperly? |
| SEC-05 | Authentication / account takeover | Can identities/sessions be stolen, forged or abused? |
| SEC-06 | Root / service-role / privileged-service boundaries | Can platform power escape its intended boundary? |
| SEC-07 | Database authorization | Are grants, RLS, policies, functions and owners least-privileged? |
| SEC-08 | Injection | Can attacker input become executable SQL/command/template/etc.? |
| SEC-09 | XSS / output injection | Can attacker-controlled data execute in the browser? |
| SEC-10 | Browser boundary | Are CSRF/CORS/CSP/clickjacking/redirect/token risks controlled? |
| SEC-11 | SSRF / outbound request abuse | Can attacker input force trusted servers to call unsafe targets? |
| SEC-12 | File upload / parser attacks | Can files trigger parser, resource or payload compromise? |
| SEC-13 | Storage isolation | Can one tenant enumerate/read/write another tenant's objects? |
| SEC-14 | Resource consumption / DoS | Can a caller exhaust compute, DB, API or parser resources? |
| SEC-15 | Business logic abuse | Can valid APIs be abused to violate business invariants? |
| SEC-16 | Race / replay / idempotency | Can concurrency or replay duplicate/alter sensitive actions? |
| SEC-17 | Secrets / configuration | Are keys, tokens, env and privileged config protected? |
| SEC-18 | Cryptography / transport / sensitive data | Are sensitive data and credentials protected in transit/at rest? |
| SEC-19 | Third-party / integrations | Are webhook/API/integration trust boundaries secure? |
| SEC-20 | Supply chain / CI-CD | Can code/build/deploy provenance be compromised? |
| SEC-21 | Logging / monitoring / incident detection | Can attacks be detected without leaking sensitive data? |
| SEC-22 | Errors / information disclosure / resilience | Do failures stay safe and avoid leaking internal details? |

A domain may be marked `NOT_APPLICABLE` only with explicit evidence and rationale.

---

## 8. WBS and STS security path

The canonical WBS is:

`docs/roadmap/fechai-security-to-scale-2026-wbs.md`

The canonical task graph is:

`docs/sfjm/PROGRAM_TASK_GRAPH.md`

### Current structural security stage

```text
STS-M3-04
Redução de DML sensível direto
+ Integridade Estrutural Multi-Tenant
```

Its children are:

```text
STS-M3-04-01 — PME message usage RPC-only write boundary
STS-M3-04-02 — PME lead message state direct-write reduction
STS-M3-04-03 — Global Tenant Surface & Relationship Inventory
STS-M3-04-04 — lista_avaliacoes Tenant-Relationship Hardening
STS-M3-04-05 — PME Catalog Tenant-Relationship Hardening
STS-M3-04-06 — Remaining Sensitive Direct-DML Adjudication & Remediation
STS-M3-04-07 — Tenant-Bound Database Invariant Verification
STS-M3-04-08 — Direct-Write / Bypass Call-Site Sweep
STS-M3-04-09 — Structural Cross-Tenant Negative Proofs
STS-M3-04-10 — Independent AppSec Closure Review
```

M3-04 cannot close while a material structural Tenant-A → Tenant-B path remains possible.

### Later security path

```text
STS-M3-05 — Auth / Admin closure
STS-M3-06 — Security staging / test plan

STS-M4-01..06 — product/runtime architectural slices and regression

STS-M5-00 — Global Security Assurance Coverage Reconciliation
STS-M5-01 — Isolated hostile-client suite
STS-M5-02 — Tenant / role / auth / storage regression
STS-M5-03 — Dependency / CVE gate
STS-M5-04 — Secrets / config / deploy gate
STS-M5-05 — Observability / rollback / incident readiness
STS-M5-06 — Residual-risk adjudication

STS-M6-01 — Final Security Evidence + AS-BUILT package
STS-M6-02 — Security blocker closeout
STS-M6-03 — Operational runbooks
STS-M6-04 — Controlled commercial decision
STS-M6-05 — Launch readiness + AS-BUILT acceptance review
```

Security Go is a separate Product Authority decision after the required evidence exists.

---

## 9. Canonical relationship model

The dashboard and audits must resolve the program through exact relationships, not filename guessing.

```text
WBS
  Qualified ID
      ↓
PROGRAM_TASK_GRAPH
  Qualified ID
      ↓
STS_WBS_PR_RELATIONSHIP_CATALOG.json
      ├── task_relations[].qualified_id
      ├── pull_request_relations[].primary_qualified_id
      └── pull_request_relations[].related_qualified_ids
      ↓
SECURITY_ASSURANCE_CATALOG.json
  entries[].parent_qualified_id
      ↓
test / runner / workflow / evidence
```

Canonical files:

- `docs/roadmap/fechai-security-to-scale-2026-wbs.md`
- `docs/sfjm/PROGRAM_TASK_GRAPH.md`
- `docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json`
- `docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json`

This yields:

```text
WBS → STS → PR → TEST → EVIDENCE → SECURITY DOMAIN
```

---

## 10. Evidence classes

Every material security conclusion must state which evidence class supports it.

### E0 — Definition / target only

Requirement or desired state exists.

Does not prove implementation.

### E1 — Static repository evidence

Code, migration, policy definition, test source, configuration-as-code.

Proves what is versioned at an exact ref.

### E2 — Live structural/catalog evidence

Current database/catalog/config/API metadata.

Examples:

- grants;
- RLS status;
- policy definitions;
- function metadata;
- deployed configuration metadata.

Proves observed live structure, not hostile runtime behavior.

### E3 — Positive functional runtime evidence

Authorized actor performs allowed action successfully.

Proves intended path works.

### E4 — Negative security runtime evidence

Unauthorized or forged operation is denied.

Examples:

- Tenant A → Tenant B;
- forged owner;
- forged role;
- forged related UUID;
- anonymous privileged call;
- unauthorized field update.

### E5 — Hostile-client / adversarial evidence

Controlled attacker-like behavior against an authorized safe environment.

Must never turn production into an offensive laboratory without exact authorization.

### E6 — Regression evidence

Previously proven controls are rerun on the release candidate/current relevant ref.

### E7 — Operational security evidence

Monitoring, alerting, rollback, incident handling, recovery and deployment controls are verified.

### E8 — Final acceptance evidence

Coverage matrix, residual adjudication, blocker closeout and exact AS-BUILT state.

---

## 11. Required evidence semantics

These statements are invariant:

```text
VERSIONED TEST != EXECUTED TEST

EVIDENCE FILE != CURRENT PASS

RLS ENABLED != RLS CORRECT

FOREIGN KEY VALID != SAME-TENANT RELATION VALID

NO CURRENT BAD DATA != BAD DATA IMPOSSIBLE

NO FRONTEND CALLER FOUND != NO CALLER EXISTS

RPC EXISTS != RPC AUTHORITY IS CORRECT

GRANT REMOVED != END-TO-END AUTHORITY PROVEN

BUILD GREEN != SECURITY PASS

MERGED != DEPLOYED

DEPLOYED != VALIDATED

STATIC != LIVE != RUNTIME

ACCEPTED WITH RESIDUALS != SECURITY GO
```

---

## 12. Security test identity and traceability

Every versioned security test/evidence artifact must have stable identity in:

`docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json`

Required relationship fields include:

- `catalog_id`;
- `display_name`;
- `parent_qualified_id`;
- original GitHub path;
- source blob SHA;
- artifact type;
- security domains;
- assurance state.

Dashboard naming convention:

```text
STS-MX[-YY] — <test / task / evidence name>
```

No material security artifact should remain permanently under an unmapped/quarantine owner.

---

## 13. PR traceability

All historical and current PRs are related through:

`docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json`

Each PR records:

- PR number;
- title;
- state;
- merge state;
- base/head;
- primary STS/WBS relationship;
- related STS/WBS relationships;
- mapping basis;
- mapping quality.

Historical mapping semantics:

```text
HISTORICAL_CONTRIBUTION_TO_CURRENT_WBS
!=
THE HISTORICAL PR ORIGINALLY EXECUTED UNDER THE LATER WBS ID
```

PR history is evidence/provenance, not automatic current security proof.

---

## 14. Coverage matrix required for Security Go

Before Security Go, a machine-readable or equivalently strict matrix must exist for every material domain/surface.

Minimum fields:

| Field | Required |
|---|---|
| Security domain | YES |
| Product/module surface | YES |
| Attacker class | YES |
| Threat/scenario | YES |
| Expected invariant | YES |
| Preventive control | YES |
| WBS/STS owner | YES |
| PR implementation/evidence refs | YES |
| Test catalog IDs | YES |
| Static evidence status | YES |
| Live evidence status | YES |
| Runtime negative evidence status | YES where applicable |
| Regression status | YES |
| Environment | YES |
| Tested commit/ref | YES |
| Evidence freshness | YES |
| Residual risk | YES |
| Final disposition | YES |

Allowed final dispositions:

```text
PASS
ACCEPTABLE_RESIDUAL
NOT_APPLICABLE_WITH_PROOF
BLOCKING
NOT_DETERMINED
```

For Security Go:

```text
BLOCKING = 0
NOT_DETERMINED on material security scope = 0
```

---

## 15. Multi-tenant proof contract

Because FECH.AI is a multiempresa SaaS, tenant isolation is a first-class invariant.

At minimum, material tenant-sensitive operations must prove:

### Read isolation

```text
Tenant A cannot read Tenant B row/object/document
```

### Write isolation

```text
Tenant A cannot INSERT/UPDATE/DELETE Tenant B state
```

### Relationship isolation

```text
Tenant A row cannot reference Tenant B protected object
```

### Ownership isolation

```text
Tenant A cannot forge owner/responsible/corretor/team from Tenant B
```

### Function isolation

```text
Tenant A cannot invoke privileged command for Tenant B
```

### Storage isolation

```text
Tenant A cannot enumerate/read/overwrite Tenant B storage objects
```

### Admin isolation

```text
Tenant A admin cannot become Tenant B admin or platform root
```

All must be enforced server-side/database-side or by an equivalent trusted fail-closed boundary.

---

## 16. External attack proof contract

Security Go must also address attacks that do not require a tenant account.

Minimum external attack classes:

- anonymous privileged API/RPC invocation;
- authentication abuse;
- credential/session attacks;
- injection;
- XSS;
- SSRF;
- unsafe file/parser inputs;
- resource exhaustion;
- security misconfiguration;
- secret exposure;
- unsafe CORS/browser boundaries;
- information disclosure;
- dependency/supply-chain compromise;
- CI/CD/deploy privilege abuse;
- third-party API/webhook abuse.

The exact test surface must be derived from the live architecture, not from a fixed checklist alone.

---

## 17. Business-logic security

Security is not limited to technical injection/access-control vulnerabilities.

Material FECH.AI business flows must resist abuse such as:

- improper lead acquisition or reassignment;
- distribution manipulation;
- ownership bypass;
- funnel manipulation;
- proposal/financial authority bypass;
- unauthorized discount/approval;
- duplicate/replayed financial operation;
- message/cadence abuse;
- admin lifecycle abuse;
- tenant provisioning abuse.

A request can be syntactically valid and still be malicious.

---

## 18. Regression policy

A control that once passed may become stale when any material invalidator occurs.

Examples:

- head/main changed;
- migration changed;
- policy/grant changed;
- caller changed;
- auth flow changed;
- storage policy changed;
- runtime environment changed;
- dependency changed;
- deploy/config changed;
- accepted threat model changed.

Security Go requires freshness sufficient for the release candidate/current material state.

---

## 19. Residual-risk policy

Residuals cannot be an unstructured escape hatch.

Every residual must be classified:

```text
ACCEPTABLE_AT_SECURITY_GO
or
MUST_CLOSE_BEFORE_SECURITY_GO
```

For an acceptable residual, record:

- exact risk;
- affected asset/surface;
- likelihood;
- impact;
- existing controls;
- why immediate remediation is not required;
- monitoring/detection;
- owner;
- expiration/revisit trigger;
- Product Authority acceptance.

A material cross-tenant bypass, privilege escalation, unauthenticated privileged execution, secret exposure, exploitable injection or equivalent critical control failure is not silently downgraded to a residual.

---

## 20. Security Go gates

A Security Go candidate must pass the following gates.

### GATE SG-01 — Canonical architecture and asset inventory

PASS requires material runtime/data/auth/storage/integration surfaces known.

### GATE SG-02 — Identity, authentication and authorization contract

PASS requires identity/role/team/admin/root authority unambiguous and enforced.

### GATE SG-03 — Structural multi-tenant safety

PASS requires no material Tenant-A → Tenant-B structural path.

### GATE SG-04 — Database and privileged execution safety

PASS requires grants/RLS/policies/RPCs/functions/triggers/owners/search_path/direct-DML boundaries adjudicated.

### GATE SG-05 — Web/API attack resistance

PASS requires material injection, XSS, SSRF, auth, browser and API access-control scenarios covered.

### GATE SG-06 — Business-logic abuse resistance

PASS requires sensitive business workflows to enforce server-side authority and invariants.

### GATE SG-07 — Storage and sensitive-data safety

PASS requires tenant-safe storage and sensitive-data exposure controls.

### GATE SG-08 — Resource-abuse and resilience controls

PASS requires rate/resource/error/failure controls appropriate to material surfaces.

### GATE SG-09 — Third-party / integration safety

PASS requires authenticated, tenant-bound, replay-aware and validated integrations where applicable.

### GATE SG-10 — Supply chain / secrets / CI-CD / deploy

PASS requires dependency/CVE, secrets and deployment controls.

### GATE SG-11 — Observability / rollback / incident readiness

PASS requires detection, rollback and incident handling for material security events.

### GATE SG-12 — Hostile-client and integrated regression

PASS requires authorized negative/adversarial tests and release-candidate regression.

### GATE SG-13 — Residual risk adjudication

PASS requires every material residual explicitly resolved or accepted.

### GATE SG-14 — Final exact-ref evidence package

PASS requires exact current evidence and zero material coverage holes.

### GATE SG-15 — Product Authority decision

Only Product Authority may grant Security Go.

---

## 21. What Security Go does and does not mean

If granted, Security Go means:

> FECH.AI has completed the defined internal security-assurance program for the approved scope/environment/release state, with current evidence sufficient for Product Authority to accept the remaining documented residual risk.

It does **not** mean:

- impossible to hack;
- zero future vulnerabilities;
- permanent certification;
- external regulator certification;
- OWASP certification;
- NIST certification;
- permission to ignore future changes.

Any material change may invalidate part of the evidence and require revalidation.

---

## 22. Security Go invalidation events

Security Go evidence must be reconsidered after material events such as:

- major auth/tenant model change;
- new privileged RPC/Edge Function;
- new storage model;
- new direct-DML path;
- new service-role use;
- new external integration;
- material dependency/security update;
- new product module;
- incident or vulnerability discovery;
- major infrastructure/deploy change;
- change to tenant isolation assumptions.

---

## 23. Current FECH.AI state

At the time this methodology was established:

```text
FECH.AI =
SECURITY HARDENING IN PROGRESS

STS-M3-04 =
ACTIVE / SCOPE_EXPANDED / REBASELINE_REQUIRED

MULTI-TENANT STRUCTURAL SAFETY =
NOT YET FULLY PROVEN

GLOBAL EXTERNAL ATTACK RESISTANCE =
NOT YET FULLY PROVEN

HOSTILE-CLIENT GLOBAL ASSURANCE =
NOT YET COMPLETE

SECURITY GO =
NOT_GRANTED
```

No statement in this document upgrades that current state.

---

## 24. Definition of done for the entire security program

The final security program DoD is:

```text
1. All material assets and attack surfaces inventoried.
2. All 22 security domains classified for material applicability.
3. Every applicable domain has a canonical STS/WBS owner.
4. Every material implemented control has exact PR/code provenance.
5. Every material security test has a stable catalog ID.
6. Structural database/auth/storage controls are live-verified.
7. Material negative tests pass.
8. Material hostile-client scenarios pass where authorized/safe.
9. Integrated tenant/role/auth/storage regression passes.
10. Dependency/CVE gate passes.
11. Secrets/config/deploy gate passes.
12. Observability/rollback/incident gate passes.
13. Business-logic abuse scenarios are covered.
14. No material BLOCKING finding remains.
15. No material NOT_DETERMINED coverage remains.
16. Every residual is adjudicated.
17. Final Security Evidence + AS-BUILT package is current.
18. Final blocker closeout passes.
19. Launch/release candidate exact refs are recorded.
20. Product Authority explicitly grants Security Go.
```

Until item 20 occurs:

```text
SECURITY GO = NOT_GRANTED
```

---

## 25. Canonical navigation

### Program methodology

`docs/security/assurance/SECURITY_GO_PROGRAM.md`

### WBS

`docs/roadmap/fechai-security-to-scale-2026-wbs.md`

### Program task graph

`docs/sfjm/PROGRAM_TASK_GRAPH.md`

### WBS / STS / PR relationship catalog

`docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json`

### Human WBS / STS / PR view

`docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.md`

### Security test/evidence catalog

`docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json`

### Human security test/evidence view

`docs/security/assurance/SECURITY_ASSURANCE_CATALOG.md`

---

## 26. Governing rule

The Security Go program is governed by this principle:

```text
DO NOT PROVE THAT NOTHING BAD HAS HAPPENED.

PROVE, TO THE REQUIRED LEVEL OF ASSURANCE,
THAT MATERIAL BAD PATHS ARE PREVENTED,
DETECTED, TESTED AND TRACEABLE.
```

And:

```text
NO SECURITY GO BY ASSUMPTION.
NO SECURITY GO BY PR COUNT.
NO SECURITY GO BY GREEN BUILD ALONE.
NO SECURITY GO WITH HIDDEN MATERIAL COVERAGE GAPS.
```
