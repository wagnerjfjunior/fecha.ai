# FECH.AI — STS-M3-02 — Authority Contract by Context — Product Authority Accepted

**Status:** COMPLETE / ACCEPTED WITH RESIDUALS / DURABLE_DECISION_ARTIFACT  
**Product Authority:** Wagner / FECH.AI  
**Repository:** wagnerjfjunior/fecha.ai  
**Publication base main:** c075a751c70ae24b5db8fcfc924c46fba6b10e3e  
**Environment:** Pilot Production / SaaS multi-tenant / multiempresa  
**Database strategy:** V2_STRANGLER / SAME_DATABASE_FIRST  
**Security Go:** NOT_GRANTED

## 1. Product Authority acceptance

Product Authority formally accepts the bounded READ_ONLY STS-M3-02 result as:

~~~text
STS-M3-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

AUTHORITY CONTRACT BY CONTEXT =
FROZEN
~~~

Preserve the upstream accepted state:

~~~text
STS-M2 =
COMPLETE / ACCEPTED WITH RESIDUALS

DATABASE STRATEGY =
V2_STRANGLER / SAME_DATABASE_FIRST

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED / FROZEN

STS-M3-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

Security Go =
NOT_GRANTED
~~~

Acceptance of the target contract does not establish implementation, runtime proof, AppSec PASS or Security Go.

## 2. Exact publication base and bounded invalidator check

Publication base:

~~~text
c075a751c70ae24b5db8fcfc924c46fba6b10e3e
~~~

The STS-M3-02 READ_ONLY analysis was issued against the same FECH.AI main SHA. Before this publication:

- FECH.AI main was resolved live and remained exactly c075a751c70ae24b5db8fcfc924c46fba6b10e3e;
- Supabase project Discador-MesaCliente / uobxxgzshrmbtjfdolxd was observed ACTIVE_HEALTHY;
- the live migration ledger contained no migration after 20260902225240 / f1_02_pr07_funnel_reads_crm_payloads;
- criar-usuario remained ACTIVE at version 19, matching the accepted M3-01 live anchor for that residual.

No material invalidator was found in this bounded check.

This does not claim proof of the absolute absence of every possible out-of-band database mutation. No such negative absolute is required or inferred here; any later evidence of a material authority/runtime/database change is an invalidation event and requires proportional revalidation.

## 3. Relationship to frozen STS-M3-01

STS-M3-02 consumes, and does not redesign, the accepted M3-01 identity/membership/team/role model.

Canonical upstream primitives:

~~~text
AUTHENTICATED PRINCIPAL =
auth.uid()

TENANT APPLICATION IDENTITY =
public.corretores

AUTH TO APPLICATION BINDING =
auth.uid() -> corretores.user_id

TENANT MEMBERSHIP SOURCE =
corretores.empresa_id

CANONICAL TENANT ROLE SOURCE =
corretores.role

TEAM ENTITY =
public.times

TEAM MEMBERSHIP =
corretores.time_id

TEAM MANAGER RESPONSIBILITY =
times.gestor_id

CANONICAL PLATFORM ROOT =
active public.admins
with role='admin_global'
~~~

Control-plane separation remains frozen:

~~~text
ROOT / ADMIN_GLOBAL =
PLATFORM CONTROL PLANE

ADMIN_LOCAL =
TENANT CONTROL PLANE

GESTOR =
TEAM CONTROL PLANE

CORRETOR =
INDIVIDUAL BUSINESS PLANE

ROOT != ADMIN_LOCAL
ROOT != GESTOR
ROOT != CORRETOR
~~~

## 4. Canonical authority primitives

### 4.1 Authenticated principal

~~~text
AUTHENTICATED PRINCIPAL =
auth.uid()
~~~

A client-provided user_id is not authority.

### 4.2 Tenant authority

~~~text
TENANT AUTHORITY =
canonical active corretores identity
+ active empresa
+ canonical tenant role
+ operation-specific permission
~~~

A client-provided empresa_id or role is not authority.

### 4.3 Team authority

~~~text
TEAM AUTHORITY =
same empresa
+ active team
+ times.gestor_id = canonical gestor
+ operation-specific permission
~~~

A client-provided time_id or manager claim is not authority.

### 4.4 Individual business authority

~~~text
INDIVIDUAL BUSINESS AUTHORITY =
same empresa
+ persisted ownership / assignment / responsibility relation
+ operation-specific permission
~~~

A client-provided ownership or assignment claim is not authority.

### 4.5 Platform root authority

~~~text
PLATFORM ROOT AUTHORITY =
active public.admins
+ role='admin_global'
+ explicit platform operation
~~~

Root authority is a platform control-plane authority, not an implicit tenant business role.

### 4.6 Trusted service-only authority

The accepted M2 routine authority taxonomy includes `SERVICE_ONLY_COMMAND` as a distinct non-end-user authority context.

~~~text
SERVICE-ONLY AUTHORITY =
explicit SERVICE_ONLY_COMMAND classification
+ canonical trusted runtime
+ service owner
+ business / tenant authorization derived from trusted server-side context
+ bounded side-effect scope
+ bounded credential / secret boundary
+ runtime proof
+ revoke / kill path
~~~

`service_role` capability by itself is never business authorization. A service-only operation is allowed only when the trusted-runtime contract proves the required actor/target/business binding and the bounded service controls for that operation.

`AUTHENTICATED PRINCIPAL = auth.uid()` remains the canonical principal for end-user/session authority. It is not a requirement that an explicitly classified service-only trusted-runtime operation fabricate an end-user session.

## 5. Canonical authorization decision model

Target server-side decision chain branches by operation context:

~~~text
classify the operation context server-side

IF explicit platform control-plane operation:
  derive auth.uid() server-side
  → resolve active public.admins root
  → require role='admin_global'
  → validate explicit platform operation
  → ALLOW

ELSE IF explicit SERVICE_ONLY_COMMAND:
  resolve canonical trusted runtime
  → resolve service owner
  → derive required business / tenant authorization from trusted server-side context
  → validate bounded side-effect scope
  → validate credential / secret boundary
  → require runtime proof and revoke / kill path
  → ALLOW

ELSE IF exceptional root tenant-support operation:
  derive auth.uid() server-side
  → resolve active public.admins root
  → validate explicit bounded audited support context
  → validate target empresa and permitted support operation
  → ALLOW

ELSE:
  derive authenticated principal server-side
  → resolve canonical active application identity
  → validate active empresa when tenant context is required
  → resolve canonical tenant role server-side
  → resolve target resource tenant server-side
  → validate same-tenant relation
  → validate active team and manager relation when required
  → validate persisted ownership / assignment / responsibility when required
  → validate operation-specific permission
  → ALLOW

any insufficient, missing, ambiguous, inconsistent, foreign or expired authority evidence
→ DENY
~~~

Client-provided tenant, role, team, owner, permission or administrative flags may be request inputs only. They are never sufficient authority evidence.

~~~text
INSUFFICIENT OR INCONSISTENT AUTHORITY EVIDENCE =
FAIL CLOSED / DENY
~~~

## 6. Authority-context matrix

| Context | Resource / operation family | Actor / canonical role | Tenant requirement | Team requirement | Ownership / relation requirement | Active-state requirement | Root applicability | Support-mode requirement | Target allow condition | Target deny condition | Current evidence / gap | Downstream owner |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Platform control plane | Operations explicitly classified as platform-level | canonical platform root | not a tenant-role inheritance | none unless the operation explicitly targets team metadata under a bounded tenant context | explicit platform-object relation where applicable | active public.admins row and admin_global role | direct, only for explicit platform operation | none for pure platform operation | canonical root + explicit platform operation | no canonical root, non-platform operation, or ambiguous scope | legacy dual-root authority still exists | M3-03 / M3-05 |
| Tenant organization control | Tenant-scoped organizational/admin operations | admin_local | actor and target resource must resolve to same active empresa | not automatically gestor; team relation required only for an operation that truly depends on a team | authoritative tenant/resource relation | active corretores identity + active empresa | no implicit root inheritance | required if platform root exceptionally enters tenant context | same tenant + canonical admin_local + operation permission | foreign tenant, inactive state, forged tenant/role, or missing permission | legacy admin_local compatibility and admin_local→gestor inheritance remain | M3-03 / M3-05 |
| Team control | Team-scoped operational/admin operations | gestor | actor, team and resource must resolve to same empresa | active team + times.gestor_id = canonical gestor | authoritative team/resource relation | active gestor + active empresa + active team | no implicit root or admin_local inheritance | required for exceptional platform support | same tenant + managed active team + operation permission | foreign/cross-company team, inactive team, wrong manager, or missing permission | legacy gestor compatibility and inherited authority remain | M3-03 / M3-05 |
| Individual business plane | Tenant business operations on assigned/owned/responsible records | corretor | actor and resource must resolve to same active empresa | same team only where the resource contract requires it | persisted ownership / assignment / responsibility relation | active corretores identity + active empresa | root does not inherit this plane | explicit support required for exceptional root access | same tenant + authoritative relation + operation permission | foreign tenant/owner, missing relation, forged ownership, or insufficient permission | exhaustive direct-DML compliance not proven | M3-04 / M3-06 |
| Trusted service runtime | Operations explicitly classified as SERVICE_ONLY_COMMAND | canonical trusted runtime + service owner | authoritative business/tenant context when the operation targets tenant/business data | only when required by the service operation contract | authoritative actor/target/business relation derived from trusted server-side context | trusted runtime/credential/service owner must be valid and bounded | none by implication; service_role is not root authority | none unless the operation is separately a root-support path | service-only classification + trusted runtime + service owner + business/tenant authorization + bounded side-effect/secret boundary + runtime proof + revoke/kill path | service_role alone, unproven runtime/owner/business binding, excessive scope, missing runtime proof, or missing revoke path | accepted M2 taxonomy includes two SERVICE_ONLY_COMMAND routines; runtime assurance remains residual | M3-03 / M3-06 |
| Exceptional platform support | Explicitly approved tenant support action | canonical platform root in bounded support context | explicit target empresa | explicit target team only when needed by support scope | explicit support scope and target relation | root active + support context active/unexpired | only through support context | mandatory | canonical root + explicit bounded audited support context + permitted support operation | absent/invalid/expired support context or action outside scope | support mode not implemented | BG-06 / M3-06 |

The exact privileged RPC/function allowlist is intentionally not enumerated here; that is STS-M3-03 scope. The exact sensitive direct-DML migration/reduction inventory is intentionally not executed here; that is STS-M3-04 scope.

## 7. Platform / root authority contract

Root is authorized by the canonical platform source only:

~~~text
auth.uid()
→ active public.admins.user_id
→ admins.role='admin_global'
→ explicit platform operation
→ ALLOW
~~~

Root does not automatically receive:

~~~text
admin_local tenant authority
gestor team authority
corretor individual business authority
ordinary tenant business-data access
persisted ownership / assignment relationships
~~~

A platform operation must be explicitly classified as such. Merely being powerful, administrative or implemented by a SECURITY DEFINER function does not make an operation platform-level.

Exceptional tenant support by root is governed only by the support-mode target contract in section 11.

## 8. Tenant admin contract

Canonical tenant-admin authority requires:

~~~text
auth.uid()
→ exactly one canonical active corretores identity
→ active empresa
→ corretores.role='admin_local'
→ target resource resolves to same empresa
→ operation-specific tenant-admin permission
→ ALLOW
~~~

Admin Local may govern the organizational structure of its own tenant where the specific operation allows it.

Admin Local does not automatically become gestor of every team and does not inherit team-operational authority merely from admin_local status.

## 9. Gestor / team contract

Canonical team authority requires:

~~~text
auth.uid()
→ canonical active corretores identity
→ active empresa
→ corretores.role='gestor'
→ active target team in same empresa
→ times.gestor_id = canonical gestor identity
→ operation-specific team permission
→ ALLOW
~~~

Cross-company manager relations fail closed.

A client-provided team identifier can identify the requested target but cannot establish that the actor manages it.

## 10. Corretor / ownership contract

Canonical individual business authority requires:

~~~text
auth.uid()
→ canonical active corretores identity
→ active empresa
→ corretores.role='corretor'
→ target resource resolves to same empresa
→ persisted ownership / assignment / responsibility relation
→ operation-specific permission
→ ALLOW
~~~

Where a resource contract uses team membership as an additional restriction, that relationship is resolved server-side.

Ownership, responsible broker, assigned team and equivalent business relations must come from authoritative persisted state, not from client claims.

## 11. Exceptional support-mode target contract

Root tenant support is non-default.

Target support context must be:

~~~text
explicit
bounded
auditable
fail-closed
non-default
~~~

A support context must identify, at minimum when applicable:

~~~text
canonical root actor
target empresa
reason / purpose
authorization source
explicit activation
start
expiry / end
permitted support scope / operation family
audit trail
explicit exit / closure
~~~

Target decision:

~~~text
canonical root
+ valid active support context
+ target empresa matches support context
+ requested action is inside bounded support scope
→ ALLOW

otherwise
→ DENY
~~~

No support-mode schema, table, RPC, UI, token or implementation mechanism is selected or implemented by this decision.

## 12. Fail-closed decision table

| Condition | Target decision | Rationale |
|---|---|---|
| no end-user session for an end-user/session authority operation | DENY | no authenticated principal |
| no end-user session for an explicitly classified SERVICE_ONLY_COMMAND | continue only through the trusted service-only decision path; otherwise DENY | service-only authority is non-end-user and must prove the trusted-runtime contract |
| unknown auth.uid() for a user/root authority operation | DENY | no canonical actor resolution |
| missing corretores profile for tenant operation | DENY | tenant application identity absent |
| duplicate / ambiguous active identity | DENY | authority cannot be resolved uniquely |
| inactive profile | DENY | inactive actor has no tenant authority |
| missing empresa | DENY | tenant context incomplete |
| inactive empresa | DENY | tenant authority inactive |
| role / legacy-flag mismatch | DENY for target authority | canonical role must resolve consistently; legacy mismatch is not positive authority |
| invalid canonical tenant role | DENY | unknown role is not authority |
| foreign empresa | DENY | cross-tenant request |
| foreign team | DENY | team outside tenant/actor context |
| cross-company manager relation | DENY | invalid manager boundary |
| inactive team | DENY for team-dependent operation | team authority requires active team |
| missing ownership / assignment relation | DENY for relation-dependent operation | no authoritative business relation |
| foreign ownership / assignment | DENY | relation belongs outside authorized context |
| forged tenant id | DENY | client tenant claim is not authority |
| forged team id | DENY | client team claim is not authority |
| forged role / admin flags | DENY | client role/flags are not authority |
| legacy admin_global identity without canonical active public.admins root | DENY for target root authority | legacy root remains compatibility debt, not target root authority |
| canonical root performing ordinary tenant business operation without support context | DENY | root has no implicit tenant-business authority |
| partial provisioning / inconsistent identity state | DENY | authority evidence incomplete |
| invalid support context | DENY | support must be explicit and valid |
| expired support context | DENY | support authority is time-bounded |

These are target decisions. They do not claim exhaustive current runtime compliance.

## 13. Current implementation gaps versus frozen target

The Product Authority acceptance preserves the following current-state gaps/residuals without treating them as target rules:

~~~text
legacy is_root() dual authority

legacy admin_global authority through corretores.role

legacy is_admin_local compatibility authority

legacy is_gestor compatibility authority

admin_global → tenant authority inheritance in existing helpers

admin_local → gestor inheritance in existing helpers

root implicit tenant-business access in existing policies/RPCs

legacy role/flag mixed authority surfaces

support mode not implemented

service-only trusted-runtime runtime proof / compliance = NOT_PROVEN

current implementation target-compliant = NOT_PROVEN

exhaustive privileged RPC compliance = NOT_PROVEN

exhaustive direct-DML compliance = NOT_PROVEN

hostile-client / cross-tenant assurance = NOT_PROVEN

AppSec PASS = NOT_PERFORMED

Security Go = NOT_GRANTED
~~~

These gaps are downstream work. They are not silently upgraded to implementation defects already remediated, runtime failures already demonstrated, or security-test results already executed.

## 14. Legacy compatibility surfaces

Preserve during bounded migration:

~~~text
corretores.role='admin_global'
= LEGACY / TRANSITIONAL ROOT AUTHORITY

is_admin_local
= LEGACY / DERIVED COMPATIBILITY SURFACE

is_gestor
= LEGACY / DERIVED COMPATIBILITY SURFACE
~~~

The accepted M3-01 live residuals remain:

~~~text
ROOT DUAL AUTHORITY SOURCE =
PROVEN LIVE

ONE ACTIVE TEAM WITH ADMIN_LOCAL-AS-GESTOR LEGACY RELATION =
PROVEN LIVE

CRIA-USUARIO AUTHORITY DERIVATION DIFFERS FROM M3-01 TARGET =
PROVEN
~~~

Retirement requires separately authorized bounded migration, caller convergence, evidence and rollback.

## 15. Downstream ownership

~~~text
STS-M3-03 =
Privileged RPC Allowlist
→ map each privileged RPC/function to the frozen authority contract

STS-M3-04 =
Sensitive Direct-DML Reduction
→ reconcile direct DML, RLS, grants and RPC-only boundaries

STS-M3-05 =
Auth / Admin Flows
→ lifecycle / provisioning / deprovisioning / role-team transitions /
  criar-usuario / legacy compatibility convergence

BG-06 =
Explicit audited Root support mode by tenant
→ separate pre-Security-Go backlog owner for support-mode design / implementation
→ PARKED / NOT_AUTHORIZED unless Product Authority separately authorizes BG-06

STS-M3-06 =
Staging / Security Test Plan
→ negative tenant/role/team/ownership/inactive/root/support/service-only/
  hostile-client validation
~~~

STS-M3-03 is structurally next eligible after this accepted decision but remains NOT_AUTHORIZED.

## 16. Preserved residuals

Residuals are intentionally retained as downstream assurance/remediation work.

They do not reopen STS-M3-01 or STS-M2 absent a material invalidator.

They also do not make STS-M3-02 incomplete: STS-M3-02 freezes the target authorization contract; it does not claim runtime convergence.

## 17. Explicit non-claims

Preserve the following separation:

~~~text
TARGET CONTRACT ACCEPTED
!= TARGET IMPLEMENTED

TARGET IMPLEMENTED
!= RUNTIME PROVEN

RUNTIME PROVEN
!= APPSEC PASS

APPSEC PASS
!= SECURITY GO
~~~

This artifact does not claim:

- exhaustive privileged RPC compliance;
- exhaustive direct-DML compliance;
- runtime target compliance;
- support-mode implementation;
- hostile-client or cross-tenant test PASS;
- AppSec PASS;
- Security Go;
- commercialization authorization;
- Ready, merge or deploy authorization;
- STS-M3-03 execution authorization.

## 18. Implementation / non-authorization boundary

This publication is documentation-only.

It does not authorize or perform:

~~~text
runtime/frontend/App.jsx mutation
Supabase/Auth/data mutation
SQL / DDL / DML
migration execution
RLS / policy mutation
GRANT / REVOKE
owner / search_path mutation
RPC/function body mutation
trigger mutation
Edge Function mutation
support-mode implementation
legacy authority retirement
role/flag migration
Vercel mutation
GitHub Actions mutation
production mutation
hostile-client testing
cross-tenant active testing
STS-M3-03 substantive execution
STS-M3-04 execution
STS-M3-05 execution
STS-M3-06 execution
Ready
merge
deploy
Security Go
commercialization authorization
SES mutation
sfjm-workspace mutation
~~~

## 19. Invalidation conditions

Revalidate this decision proportionally if any material event changes:

- the frozen STS-M3-01 identity/membership/team/role/root contract;
- Product Authority authorization semantics;
- canonical tenant-role source;
- platform-root source;
- team manager or membership model;
- ownership/assignment semantics;
- support-mode contract;
- privileged authority helpers/policies/RPCs in a way that invalidates the accepted gap characterization;
- Auth/Admin provisioning lifecycle in a way that invalidates the accepted gap characterization;
- database/runtime evidence material to the contract;
- canonical FECH.AI source precedence.

A PR head change invalidates any prior exact-head publication review.

Absent a material invalidator, do not replay STS-M2 or STS-M3-01.

## 20. Rollback

Principal publication risk:

~~~text
incorrect publication of the accepted STS-M3-02 authority contract
~~~

Rollback:

~~~text
simple revert of the single documentation commit
~~~

No runtime, database, Auth, production or deploy rollback is required because this publication performs no such mutation.

## 21. Evidence and coverage boundary

| Source | Exact ref / environment | Coverage used for publication | Status |
|---|---|---|---|
| FECH.AI main | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | live branch/commit resolution | GITHUB_VERSIONED / LIVE_RESOLVED |
| docs/security/evidence/2026-09-07-sts-m3-01-identity-membership-team-role-model.md | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | complete content through EOF | INTEGRAL_READ |
| docs/bootstrap/INDEX.md | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | bootstrap contract | INTEGRAL_READ |
| docs/skills/SES_SPECIALIST_ROUTING.md | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | adopted documentation_audit routing | INTEGRAL_READ |
| docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | evidence/read/anti-overclaim contract | INTEGRAL_READ |
| docs/governance/INDEX.md | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | current program governance entrypoint | INTEGRAL_READ |
| current SFJM material views | c075a751c70ae24b5db8fcfc924c46fba6b10e3e | current sections and exact full-file contents used for bounded transformation | MATERIAL_READ; final candidate must be reread through EOF before self-check |
| Supabase migration ledger | live project uobxxgzshrmbtjfdolxd | list_migrations READ_ONLY | RUNTIME_OBSERVED / BOUNDED |
| Supabase Edge Function inventory | live project uobxxgzshrmbtjfdolxd | list_edge_functions READ_ONLY | RUNTIME_OBSERVED / BOUNDED |
| Product Authority STS-M3-02 acceptance | 2026-09-08 decision | accepted target contract, residuals, downstream routing and non-authorizations | INFORMATION_SUPPLIED / AUTHORITY_DECISION |

The publication does not fabricate missing implementation or test evidence.
