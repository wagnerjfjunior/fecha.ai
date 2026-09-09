# FECH.AI — SFJM Current Material State

## 0.0000000000000000037 CURRENT — FINAL OFFENSIVE LAB PRE-AUTHORIZED BUT DEFERRED — 2026-09-09

Product Authority has authorized the bounded future STS-M3-06 + STS-M5-01 + STS-M5-02 offensive-security path, while explicitly ordering that it must not execute now.

~~~text
decision anchor main =
157f0f6f1f9bd4e80cf909e95cc48aa76ebe97d5

STS-M3-06 =
AUTHORIZED_DEFERRED / NOT_STARTED / NOT_CURRENT_ACTION

STS-M5-01 =
AUTHORIZED_DEFERRED_FINAL_TEST / NOT_STARTED / NOT_CURRENT_ACTION

STS-M5-02 =
AUTHORIZED_DEFERRED_FINAL_TEST / NOT_STARTED / NOT_CURRENT_ACTION

CURRENT_IMMEDIATE_AUTHORIZED_TECHNICAL_EXECUTION =
NONE

Security Go =
NOT_GRANTED
~~~

Sequencing is material:

~~~text
continue FECH.AI WBS task-by-task
→ complete applicable implementation + non-offensive test obligations
→ reach final offensive-test window
→ explicitly confirm cost
→ provision/duplicate isolated Supabase security environment
→ synthetic fixtures only
→ execute STS-M5-01 + STS-M5-02 adversarial suites
→ eliminate/adjudicate findings under STS-M5-06
→ independent STS-M5-07 AppSec final review
→ M6
~~~

Hard prohibitions remain:

~~~text
NO offensive execution now
NO paid environment creation now
NO real customer/lead/business data in the lab
NO destructive attack in production
NO Security Go by implication
~~~

The authorization is durable for the same bounded future scope. Execution admission later still requires fresh bootstrap, exact live refs, isolated-environment readiness, rollback/teardown and explicit cost confirmation when cost will be incurred.


## 0.0000000000000000036 HISTORICAL / SUPERSEDED — PR #211 MERGED / ZERO-MATERIAL-RESIDUAL WBS CANONICAL — 2026-09-09

Product Authority completed the documentation/governance publication that binds the 2026-09-09 live security audit into the canonical Security-to-Scale WBS.

~~~text
canonical main =
719f0e98b58c7bf4d39485020d4389f8654da659

PR #211 =
MERGED / CLOSED

approved exact head =
64db0b4bbb374991505af4f8be5c0722a6b11be7

merge commit =
719f0e98b58c7bf4d39485020d4389f8654da659

change class =
DOCUMENTATION / WBS / SFJM / ASSURANCE RELATIONSHIP ONLY

runtime mutation =
NONE

Supabase/Auth/data mutation =
NONE

STS-M3 =
ACTIVE

STS-M3-03 final implementation closure =
PENDING UNDER NEW ZERO-MATERIAL-RESIDUAL CONTRACT

STS-M3-04 =
ACTIVE / REBASELINE_REQUIRED

STS-M4 =
PLANNED / SECURITY NON-REGRESSION MAPPED FOR ALL SIX SUBTASKS

STS-M5 =
PLANNED / STS-M5-00..07 MAPPED / ZERO MATERIAL OPEN REQUIRED

STS-M6 =
PLANNED / STS-M6-01..05 MAPPED / INELIGIBLE WHILE MATERIAL FINDING OPEN

CURRENT_AUTHORIZED_TECHNICAL_EXECUTION =
NONE

Security Go =
NOT_GRANTED
~~~

Canonical structural sources:

~~~text
docs/roadmap/fechai-security-to-scale-2026-wbs.md
docs/sfjm/PROGRAM_TASK_GRAPH.md
docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json
docs/roadmap/2026-09-09-security-to-scale-wbs-zero-residual-amendment.md
docs/security/assurance/2026-09-09-audit-to-wbs-zero-residual-plan.md
~~~

Final security closure invariant now canonical:

~~~text
MATERIAL SECURITY FINDING OPEN
=> OWNING TASK NOT FINAL-CLOSED
=> M5 NOT PASS
=> M6 NOT SECURITY-GO ELIGIBLE
~~~

This publication does not authorize any implementation slice, SQL/DDL/DML, migration, RLS/policy/grant/RPC mutation, deploy, hostile-client production test or Security Go.


## 0.0000000000000000035 CURRENT — STS-M3-04-02 COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-08

Product Authority formally accepts the second bounded STS-M3-04 direct-write reduction slice.

~~~text
acceptance evidence main =
50777e6b28c172efc97dd0b4ea1dcb7ec8b52367

environment =
Pilot Production / SaaS multi-tenant / multiempresa

STS-M3 =
ACTIVE

STS-M3-04 =
ACTIVE

STS-M3-04-01 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-04-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

PR #207 =
MERGED / CLOSED

reviewed head =
3f52a93080bef5e251abad75f6726241799a0928

merge commit =
50777e6b28c172efc97dd0b4ea1dcb7ec8b52367

Supabase project =
uobxxgzshrmbtjfdolxd / Discador-MesaCliente / sa-east-1

migration application =
SUCCESS

post-application read-only catalog validation =
PASS

runtime assurance =
SEPARATE / NOT_PERFORMED

Security Go =
SEPARATE / NOT_GRANTED

CURRENT_AUTHORIZED_TECHNICAL_EXECUTION =
NONE
~~~

Accepted implementation result for `public.pme_lead_message_state`:

~~~text
authenticated SELECT = PRESERVED
authenticated INSERT = REMOVED
authenticated UPDATE = REMOVED
authenticated DELETE = ABSENT
anon direct privileges = ABSENT
PUBLIC direct table grants = ABSENT
RLS = PRESERVED
pme_lead_message_state_select = PRESERVED
INSERT policy = REMOVED
UPDATE policy = REMOVED
service_role privilege vector = PRESERVED
~~~

Canonical repository artifacts at the acceptance evidence main:

~~~text
supabase/migrations/20260908234500_sts_m3_04_02_pme_lead_message_state_direct_write_reduction.sql
blob = 7c734f4b51ad57b8df25c63393085093fbb0edbb

supabase/tests/pme/usage-tracking/16a_smoke_pme_usage_tracking_catalogo_rls_grants_readonly.sql
blob = bf7a15001a510e3e6ce59e5208017fee57d48b27
~~~

Supabase migration ledger provenance remains explicitly distinct from the repository filename prefix:

~~~text
GitHub migration filename prefix =
20260908234500

Supabase migration ledger version =
20260908200621

Supabase migration ledger name =
sts_m3_04_02_pme_lead_message_state_direct_write_reduction
~~~

This distinction is accepted as provenance metadata and is not classified as a blocker for STS-M3-04-02 closure.

Residual boundary remains explicit and separate:

~~~text
runtime assurance = NOT_PERFORMED
hostile-client active runtime validation = NOT_PERFORMED
cross-tenant active runtime validation = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

STS-M3-04-02 closure does not convert these residuals into PASS and does not grant Security Go. The absence of runtime assurance does not automatically reopen this accepted slice. Reopening requires a material invalidator or a new explicit Product Authority decision.

No further STS-M3 technical execution is authorized by this acceptance. The next material STS-M3 gate requires separate Product Authority selection and authorization.

## 0.0000000000000000034 CURRENT — STS-M3-04-01 COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-08

Product Authority formally accepts the first bounded STS-M3-04 implementation slice.

~~~text
acceptance evidence base main = 1402395e708f69b0935ab2ba45489f717943b8b2
environment = Pilot Production / SaaS multi-tenant / multiempresa
STS-M3 = ACTIVE
STS-M3-01 = COMPLETE / ACCEPTED / FROZEN
STS-M3-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M3-03 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M3-04 = ACTIVE
STS-M3-04-01 = COMPLETE / ACCEPTED WITH RESIDUALS
PR #205 = MERGED / CLOSED
approved head = 07f5dad3f805e319a0303e664752a2da7d0e3dfe
PR #205 merge commit / acceptance base main = 1402395e708f69b0935ab2ba45489f717943b8b2
Supabase project = uobxxgzshrmbtjfdolxd
migration apply = SUCCESS
post-apply catalog validation = PASS
post-apply smoke 16A = PASS
Security Go = NOT_GRANTED
~~~

The accepted control removes authenticated direct INSERT on `public.pme_message_usage`, removes its INSERT policy, preserves authenticated SELECT, and preserves authenticated EXECUTE on `public.pme_registrar_message_usage(uuid,jsonb)`.

Residuals remain explicit: hostile-client / independent AppSec effectiveness retest was not performed; individual lead ownership/assignment hardening inside the RPC remains outside this slice; the Supabase migration ledger recorded version `20260908184747` while the canonical repository filename prefix is `20260908233000` (existing apply-migration provenance convention); Security Go remains NOT_GRANTED.

No next M3-04 implementation slice is authorized by this acceptance. The next material slice candidate remains separate and requires Product Authority authorization.

## 0.0000000000000000033 CURRENT — STS-M3-03 ACCEPTED / STS-M3-04 AUTHORIZED NOT INITIATED — 2026-09-08

Product Authority materially advances the current program state:

~~~text
decision base main = ec42e7b087dd1bf9b7ddc0cf05316e9d3e7979be
environment = Pilot Production / SaaS multi-tenant / multiempresa
STS-M2 = COMPLETE / ACCEPTED WITH RESIDUALS
DATABASE STRATEGY = V2_STRANGLER / SAME_DATABASE_FIRST
STS-M3 = ACTIVE
STS-M3-01 = COMPLETE / ACCEPTED / FROZEN
STS-M3-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M3-03 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M3-04 = AUTHORIZED / NOT_INITIATED
Security Go = NOT_GRANTED
~~~

Accepted M3-03 result:

~~~text
public routine universe = 160
privileged candidate universe = 49
candidate rows disposed = 49 / 49
service-only commands = 2 / 2 mapped
allowlist completeness = PROVEN TO ACCEPTED BOUNDED STANDARD
current implementation target-compliant as a whole = NO / NOT_PROVEN
runtime hostile assurance = NOT_PERFORMED
AppSec PASS = NOT_PERFORMED
~~~

Canonical artifact:
`docs/security/evidence/2026-09-08-sts-m3-03-privileged-rpc-allowlist.md`
blob = `9b4c76648e34f324edfb2df205b2ba8691590817`

M3-04 is authorized but has not started. Fresh live bootstrap is required before initiation. This documentation publication performs no runtime/Supabase mutation.


## 0.0000000000000000032 CURRENT POST-MERGE — PR #202 MERGED / STS-M3-03 NEXT ELIGIBLE — 2026-09-08

Product Authority authorized this bounded post-merge SFJM reconciliation after PR #202 merged on the exact approved head.

~~~text
canonical main =
665e3920b17849f45d8b3fcea015b1492219f115

PR #202 =
MERGED / CLOSED

merged head =
c71a3e1a5f7c3d829b8379b085ba14f20b2f53cc

merge commit =
665e3920b17849f45d8b3fcea015b1492219f115

environment =
Pilot Production / SaaS multi-tenant / multiempresa

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

STS-M3-03 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

CURRENT_AUTHORIZED_EXECUTION =
NONE

Security Go =
NOT_GRANTED
~~~

The merge changes lifecycle/provenance only. It does not change the frozen STS-M3-02 authority contract:

~~~text
end-user/session principal = auth.uid()
tenant authority = canonical active corretores identity + active empresa + canonical tenant role + operation-specific permission
team authority = same empresa + active team + times.gestor_id = canonical gestor + operation-specific permission
individual business authority = same empresa + persisted ownership/assignment/responsibility + operation-specific permission
platform root = active public.admins + role='admin_global' + explicit platform operation
service-only authority = explicit SERVICE_ONLY_COMMAND + canonical trusted runtime + service owner + trusted server-side business/tenant authorization + bounded side-effect/secret boundary + runtime proof + revoke/kill path
root tenant business access = NO IMPLICIT AUTHORITY
exceptional root tenant support = explicit bounded audited support context only
support-mode implementation owner = BG-06 / PARKED / NOT_AUTHORIZED
insufficient or inconsistent authority evidence = FAIL CLOSED / DENY
~~~

Durable decision artifact now canonical on main:

~~~text
docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md
blob = 6cf20f5298e183c34d9b560740b3d19c621fb7bb
~~~

Single next material program gate:

~~~text
PRODUCT AUTHORITY MAY SEPARATELY AUTHORIZE
STS-M3-03 — PRIVILEGED RPC ALLOWLIST

STS-M3-03 =
NEXT_ELIGIBLE / NOT_AUTHORIZED
~~~

No STS-M3-03 execution, runtime/frontend mutation, Supabase/Auth/data mutation, BG-06 implementation, deploy, production mutation or Security Go is authorized by this reconciliation.

## 0.0000000000000000030 HISTORICAL / SUPERSEDED PRE-MERGE PUBLICATION STATE — STS-M3-02 ACCEPTED WITH RESIDUALS — 2026-09-08

Product Authority explicitly accepted the STS-M3-02 authority contract by context and authorized this bounded documentation/SFJM publication.

~~~text
publication base main =
c075a751c70ae24b5db8fcfc924c46fba6b10e3e

environment =
Pilot Production / SaaS multi-tenant / multiempresa

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

STS-M3-03 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

Frozen STS-M3-02 authority contract:

~~~text
authenticated principal = auth.uid()

tenant authority =
canonical active corretores identity
+ active empresa
+ canonical tenant role
+ operation-specific permission

team authority =
same empresa
+ active team
+ times.gestor_id = canonical gestor
+ operation-specific permission

individual business authority =
same empresa
+ persisted ownership / assignment / responsibility relation
+ operation-specific permission

platform root =
active public.admins
+ role='admin_global'
+ explicit platform operation

service-only trusted runtime authority =
explicit SERVICE_ONLY_COMMAND
+ canonical trusted runtime
+ service owner
+ trusted server-side business / tenant authorization
+ bounded side-effect / secret boundary
+ runtime proof
+ revoke / kill path

root tenant business access =
NO IMPLICIT AUTHORITY

exceptional root tenant support =
explicit bounded audited support context only

client-provided tenant / role / team / owner / permission =
NOT AUTHORITY

insufficient or inconsistent authority evidence =
FAIL CLOSED / DENY
~~~

Preserved downstream residual boundary:

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
support-mode implementation owner = BG-06 / PARKED / NOT_AUTHORIZED
service-only trusted-runtime runtime proof / compliance = NOT_PROVEN
current implementation target-compliant = NOT_PROVEN
exhaustive privileged RPC compliance = NOT_PROVEN
exhaustive direct-DML compliance = NOT_PROVEN
hostile-client / cross-tenant assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Durable decision artifact:

~~~text
docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md
~~~

Current next material program gate:

~~~text
PRODUCT AUTHORITY MAY SEPARATELY AUTHORIZE
STS-M3-03 — PRIVILEGED RPC ALLOWLIST

STS-M3-03 =
NEXT_ELIGIBLE / NOT_AUTHORIZED
~~~

No STS-M3-03 execution authority, runtime/Supabase mutation, Ready, merge, deploy or Security Go follows from this publication.


## 0.0000000000000000024 HISTORICAL / SUPERSEDED — STS-M3-01 ACCEPTED / STS-M3 ACTIVE — 2026-09-07

Product Authority explicitly accepted the STS-M3-01 identity/membership/team/role model and authorized this bounded documentation/SFJM publication.

~~~text
publication base main =
661ef0014576d473088add0052d751e0a47d306e

environment =
Pilot Production / SaaS multi-tenant / multiempresa

STS-M2 =
COMPLETE / ACCEPTED WITH RESIDUALS

DATABASE STRATEGY =
V2_STRANGLER / SAME_DATABASE_FIRST

STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED

STS-M3-02 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

Frozen authority contract:

~~~text
authenticated principal = auth.uid()
tenant application identity = public.corretores
membership = corretores.empresa_id
tenant role source = corretores.role
team entity = public.times
team membership = corretores.time_id
team manager responsibility = times.gestor_id
platform root source = active public.admins role=admin_global
~~~

Legacy authority remains explicitly transitional:

~~~text
corretores.role='admin_global' = LEGACY ROOT AUTHORITY / NOT REMOVED
is_admin_local = LEGACY / DERIVED COMPATIBILITY
is_gestor = LEGACY / DERIVED COMPATIBILITY
~~~

Preserved M3-01 residuals:

~~~text
ROOT DUAL AUTHORITY SOURCE = PROVEN LIVE
ONE ACTIVE TEAM WITH ADMIN_LOCAL-AS-GESTOR LEGACY RELATION = PROVEN LIVE
CRIA-USUARIO AUTHORITY DERIVATION DIFFERS FROM M3-01 TARGET = PROVEN
current implementation target-compliant = NOT_PROVEN
lifecycle remediation = NOT_PERFORMED
hostile-client / cross-tenant assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Durable decision artifact:

~~~text
docs/security/evidence/2026-09-07-sts-m3-01-identity-membership-team-role-model.md
~~~

Current next material program gate is separate Product Authority authorization for bounded STS-M3-02 READ_ONLY-first work. No M3-02 execution authority follows from M3-01 acceptance.


## 0.0000000000000000023 HISTORICAL / SUPERSEDED — STS-M2-06 ACCEPTED / STS-M2 COMPLETE WITH RESIDUALS — 2026-09-07

Product Authority explicitly accepted the STS-M2-06 architecture decision produced from the bounded READ_ONLY analysis.

~~~text
analysis base main =
f22b83bb7acec8692e0575185a88ca2755183b41

authorization publication =
PR #197 / MERGED
merge commit =
0cb993a1eb86433975429da4a07a13fd3f373e16

current publication base main =
83186f5775e563e150329fa0b95dd1d7f3f3a516

environment =
Pilot Production / SaaS multi-tenant / multiempresa
~~~

Accepted architecture decision:

~~~text
STS-M2-06 =
COMPLETE / ACCEPTED

DATABASE STRATEGY =
V2_STRANGLER / SAME_DATABASE_FIRST

INITIAL PHYSICAL PERSISTENCE =
CURRENT SUPABASE / POSTGRESQL DATABASE

NEW PRODUCTION DATABASE =
NOT SELECTED AT THIS STAGE
~~~

Canonical interpretation:

~~~text
V2_STRANGLER
!= SECOND DATABASE NOW
!= BIG-BANG REWRITE
!= MICROSERVICES REQUIREMENT

SAME_DATABASE_FIRST
!= PURE UNBOUNDED EVOLVE_IN_PLACE
~~~

Accepted M2 closure:

~~~text
STS-M2-01 = COMPLETE
STS-M2-02 = COMPLETE WITH RESIDUALS
STS-M2-03 = COMPLETE WITH RESIDUALS
STS-M2-04 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-05 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-06 = COMPLETE / ACCEPTED

STS-M2 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-CALLSITE-
RUNTIME-APPSEC RESIDUALS
~~~

Preserved residual boundary:

~~~text
current implementation target-compliant = NOT_PROVEN
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
exhaustive application direct-DML callsite proof = NOT_ESTABLISHED
lista_avaliacoes resulting-row relationship integrity = NOT INDEPENDENTLY PROVEN
leads resulting-row empresa relationship = NOT INDEPENDENTLY PROVEN
times resulting-row empresa relationship = NOT FULLY PROVEN
hostile-client / cross-tenant runtime assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
assistente-ai live Edge Function vs versioned source parity = NOT_ESTABLISHED
Security Go = NOT_GRANTED
~~~

Program continuation:

~~~text
STS-M3 = NEXT_ELIGIBLE / NOT_AUTHORIZED
STS-M3-01 = NEXT_ELIGIBLE / NOT_AUTHORIZED
STS-M3 execution = NOT_AUTHORIZED
~~~

M2 completion does not authorize implementation, V2 runtime work, Supabase/Auth/data mutation, STS-M3 execution, deploy, Security Go or commercialization.

Current issue/risk lifecycle view remains typed through:

~~~text
docs/sfjm/CURRENT_ISSUES.md
CURRENT_BLOCKER_COUNT = 0
~~~

Publication lifecycle facts such as review state, Draft/Ready, merge state, base/head and checks must be resolved live from GitHub and are not owned by this MATERIAL_RECORDED_STATE. The next material program gate is separate Product Authority authorization for bounded STS-M3-01; no STS-M3 execution authority exists here.


## 0.0000000000000000022 HISTORICAL / SUPERSEDED — STS-M2-06 DATABASE ARCHITECTURE DECISION AUTHORIZED READ_ONLY — 2026-09-07

Product Authority explicitly authorized initiation of STS-M2-06 from current canonical FECH.AI main:

~~~text
canonical main =
f22b83bb7acec8692e0575185a88ca2755183b41

environment =
Pilot Production / SaaS multi-tenant / multiempresa

STS-M2-06 =
AUTHORIZED_READ_ONLY / READY_TO_EXECUTE

STS-M2 =
ACTIVE

Security Go =
NOT_GRANTED
~~~

WBS task and exit contract:

~~~text
M2-06 — Decisão arquitetural do banco — 16h

decision =
EVOLVE_IN_PLACE
vs
V2_STRANGLER
vs
NEW_DATABASE

evidence required = YES
~~~

Canonical specialist:

~~~text
GPT1.5 — FECH.AI Arquiteto SaaS
docs/skills/fechai-gpt1-architect-saas.md
~~~

STS-M2-06 must reconstruct enough current evidence to characterize the existing database architecture and compare the three allowed target directions. Material dimensions include multi-tenancy, trust boundaries, database contracts, coupling, callers/consumers, migration complexity, operational blast radius, rollback, observability/proof obligations and preserved STS-M2-01..STS-M2-05 residuals.

Authorized:

~~~text
GitHub READ_ONLY
bounded repository discovery / dependency tracing READ_ONLY
bounded Supabase catalog / metadata / statistics READ_ONLY when materially necessary
architecture synthesis and option comparison
recommendation for Product Authority adjudication
~~~

Not authorized:

~~~text
implementation
runtime/frontend mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grants / function / trigger mutation
STS-M3 execution
deploy
Security Go
~~~

The STS-M2-06 result is not self-accepting. A recommendation or decision packet must return to Product Authority for explicit adjudication before implementation or STS-M2 closure.

Current next safe action:

~~~text
EXECUTE BOUNDED STS-M2-06 READ_ONLY
IN A NEW CONVERSATION
AGAINST LIVE CANONICAL MAIN
~~~

This authorization publication is documentation-only and remains PR_HEAD_ONLY until separately reviewed/merged. The execution authority itself comes from Product Authority and is exact-scope bounded; repository publication does not widen it.

Current issue/risk lifecycle view:

~~~text
docs/sfjm/CURRENT_ISSUES.md

CURRENT_TASK_BLOCKERS = 0
RESIDUAL = 3
DEFERRED_EVIDENCE = 3
SECURITY_GATE = 3
FUTURE_GATE = 1
~~~

This classification prevents residuals/deferred/future gates from being counted as current blockers. It does not waive or resolve them.

## 0.0000000000000000021 HISTORICAL / SUPERSEDED — STS-M2-05 DATABASE CONTRACT MAP COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-07

Product Authority explicitly accepted STS-M2-05 and authorized this bounded documentation-only publication from exact FECH.AI main:

~~~text
acceptance/publication base main =
e07254ef6b2d7184e749463727df2e6d404226a7

canonical main after PR #195 merge =
d6953ea3071ada55fbcd97f21c848f5c6424ca3f

STS-M2-05 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-CALLSITE-EVIDENCE-
RUNTIME-APPSEC RESIDUALS
~~~

Accepted completion basis:

~~~text
44 / 44 canonical tables mapped
160 / 160 public routine universe represented
137 SECURITY DEFINER routines consumed through accepted B2 + B3/C3/E + D evidence
23 / 23 non-DEFINER routines mapped by M2-05
31 / 31 non-internal trigger instances represented
10 / 10 bounded database contexts represented
new M2-05 semantic blockers = 0
~~~

Durable evidence on canonical main:

~~~text
docs/security/evidence/2026-09-07-sts-m2-05-database-contract-map.md
blob 8b2875e1bc095329482de095028ed31b37091d63
~~~

Preserve:

~~~text
TARGET CONTRACT ACCEPTED != TARGET IMPLEMENTED
DATABASE CONTRACT MAP COMPLETE != SECURITY ASSURANCE COMPLETE
BOUNDED STATIC CALLSITE SEARCH != EXHAUSTIVE APPLICATION CALLSITE PROOF
~~~

Current residual boundary remains open:

~~~text
current implementation target-compliant = NOT_PROVEN
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
exhaustive application direct-DML callsite proof = NOT_ESTABLISHED
AppSec PASS = NOT_PERFORMED
hostile-client assurance = NOT_PROVEN
cross-tenant runtime assurance = NOT_PROVEN
Security Go = NOT_GRANTED
~~~

Program state:

~~~text
M2-01 = COMPLETE
M2-02 = COMPLETE WITH RESIDUALS
M2-03 = COMPLETE WITH RESIDUALS
M2-04 = COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
M2-05 = COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-CALLSITE-EVIDENCE-RUNTIME-APPSEC RESIDUALS
M2-06 = ELIGIBLE_NOT_AUTHORIZED
M2 = ACTIVE
~~~

M2 is not closed. M2-06 remains a separate Product Authority gate.

Single next program gate:

~~~text
PRODUCT AUTHORITY:
AUTHORIZE BOUNDED STS-M2-06
DATABASE ARCHITECTURE DECISION
READ_ONLY SCOPE / EVIDENCE RECONSTRUCTION
~~~

M2-06 owns the future EVOLVE_IN_PLACE vs V2_STRANGLER vs NEW_DATABASE decision. No M2-06 execution, Ready, merge, deploy, Supabase/runtime mutation or Security Go is authorized by this state.

Publication lifecycle:

~~~text
Product Authority acceptance = RECORDED
PR #195 = MERGED / CLOSED
reviewed candidate head = 643fb532e2860bdc53cbbddef529e3b9ed4e8709
merge commit = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
main canonical publication = MERGED_CANONICAL
~~~


## 0.0000000000000000020 HISTORICAL / SUPERSEDED — STS-M2-04 COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS — 2026-09-07

Product Authority explicitly accepted the final STS-M2-04 WBS closure against exact canonical main:

~~~text
FECH.AI main =
6357c1b4df207683b60de26daa53248d44dce84a

STS-M2-04 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

WBS objective closed =
TARGET POLICY FOR DEFINER / RLS / DML
~~~

Accepted evidence stack:

~~~text
B1 routine-authority policy = COMPLETE / ACCEPTED WITH RESIDUALS
B2 original 15-routine classification = COMPLETE / ACCEPTED WITH RESIDUALS
B2 target-contract closure = COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
B3 classification = COMPLETE / ACCEPTED
C = COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS
D = COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT
E = COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
~~~

Closure meaning:

~~~text
TARGET DEFINER / INVOKER POLICY = COMPLETE
HIGH-RISK B2 TARGET CONTRACT = COMPLETE
REMAINING ROUTINE TARGET AUTHORITY = COMPLETE
RLS TARGET CONTRACT = COMPLETE
DIRECT-DML TARGET CONTRACT = COMPLETE
TRIGGER TARGET AUTHORITY = COMPLETE
TARGET-AUTHORITY SEMANTIC BLOCKERS = 0
~~~

Preserved residual boundary:

~~~text
CURRENT IMPLEMENTATION TARGET-COMPLIANT = NOT_PROVEN
IMPLEMENTATION REMEDIATION = NOT_PERFORMED
LIFECYCLE REMEDIATION = NOT_PERFORMED
APPSEC PASS = NOT_PERFORMED
RUNTIME ASSURANCE = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
~~~

C4 design/evidence residuals remain explicitly open and are not waived by the STS-M2-04 closure:

~~~text
lista_avaliacoes resulting-row protected relationship integrity =
NOT INDEPENDENTLY PROVEN

leads resulting-row empresa_id relationship =
NOT INDEPENDENTLY PROVEN

times resulting-row empresa relationship =
NOT INDEPENDENTLY RESTATED / NOT FULLY PROVEN

fresh exhaustive application direct-DML callsite sweep =
NOT PERFORMED
~~~

These are preserved evidence/implementation-assurance inputs for downstream work. They do not reopen the accepted target-policy decision and do not change:

~~~text
STS-M2-04 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
~~~

No homogeneous 137-routine mode synthesis is created by this closure. B2, B3/C3/E and D retain their accepted slice boundaries.

Program continuation:

~~~text
M2-04F semantics = NOT CANONICALLY CREATED
M2-05 = NEXT ELIGIBLE WBS MILESTONE
M2-05 execution = NOT_AUTHORIZED
M2-06 execution = NOT_AUTHORIZED
~~~

Program task/decomposition continuity is now published through:

~~~text
docs/sfjm/PROGRAM_TASK_GRAPH.md

structural source =
docs/roadmap/fechai-security-to-scale-2026-wbs.md

current task graph position =
M2-05 ELIGIBLE_NOT_AUTHORIZED
→ M2-06 PLANNED_NOT_AUTHORIZED
→ M3..M6 PLANNED_NOT_AUTHORIZED
~~~

The task graph also preserves the execution-discovered M2-04B/C/D/E hierarchy without creating M2-04F or reopening the accepted M2-04 closure.

This acceptance authorizes only bounded SFJM documentation reconciliation. It does not authorize implementation, Supabase/Auth/data mutation, Ready, merge, deploy, M2-05, M2-06 or Security Go.

## 0.0000000000000000019 HISTORICAL / SUPERSEDED — B2 HIGH-RISK TARGET-CONTRACT CLOSURE ACCEPTED BY PRODUCT AUTHORITY — 2026-09-07

Product Authority explicitly accepted the exact READ_ONLY B2 closure result produced from:

~~~text
accepted result parent head =
8e18c4abe4daca6e4e9240c567267fcfe774e5b9

execution-base main =
dd118baa89b68281bbd7c8df43c8e24c0e9b66bf

Supabase =
uobxxgzshrmbtjfdolxd / Discador-MesaCliente

live B2 fingerprint =
33aea33ec2039d91f417b3980ea8cf43
~~~

Accepted bounded target/lifecycle projection:

~~~text
ACTIVE TARGET DEFINER = 6
DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE = 5
TARGET INVOKER = 2
NON_MODE_LIFECYCLE CANDIDATE = 2
TOTAL = 15
~~~

Accepted exact dispositions:

~~~text
01 alterar_plano_empresa_root
   -> PRIVILEGED_OPERATION / TARGET DEFINER / authenticated root entrypoint

02 atualizar_status_empresa_root
   -> PRIVILEGED_OPERATION / TARGET DEFINER / authenticated root entrypoint

03 importar_mesa_cliente_disponibilidade_oficial
   -> PRIVILEGED_OPERATION / TARGET DEFINER / authenticated tenant-admin/root entrypoint

04 mesa_cliente_upsert_faixas_premio
   -> PRIVILEGED_OPERATION / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until canonical caller is proven

05 mesa_cliente_upsert_politica_financeira
   -> PRIVILEGED_OPERATION / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until canonical caller is proven

06 registrar_upload_arquivo_mesa
   -> AUTHENTICATED_COMMAND / TARGET DEFINER / authenticated entrypoint

07 salvar_mesa_cliente_desconto_politica
   -> PRIVILEGED_OPERATION / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until canonical caller is proven

08 salvar_mesa_cliente_enriquecimento
   -> AUTHENTICATED_COMMAND / TARGET DEFINER / authenticated RPC command boundary

09 acquire_lote_lock
   -> DB_INTERNAL_HELPER / TARGET INVOKER / NO DIRECT CLIENT EXECUTE

10 avaliar_lista(uuid,integer,text)
   -> AUTHENTICATED_COMMAND / TARGET DEFINER / authenticated entrypoint

11 trilha_lead
   -> AUTHENTICATED_QUERY / TARGET INVOKER / authenticated caller-visible lead scope

12 dispensar_lembrete
   -> AUTHENTICATED_COMMAND / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until caller is proven

13 mover_funil_batch
   -> AUTHENTICATED_COMMAND / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until caller + role/team scope are proven

14 redefinir_senha_corretor
   -> NON_MODE_LIFECYCLE candidate / RETIRE_LEGACY_SQL_RPC after dependency check

15 registrar_audit_log
   -> NON_MODE_LIFECYCLE candidate / RETIRE_OR_REPLACE_WITH_TRUSTED_INTERNAL_AUDIT_HELPER after dependency check
~~~

Accepted shared B2 target rules:

~~~text
PUBLIC EXECUTE target = 0 / 15
anon EXECUTE target = 0 / 15
service_role direct EXECUTE required by proven canonical caller = 0 / 15

callerless retained routines =
NO CLIENT EXECUTE until canonical caller/product contract is proven

DEFINER owner target =
controlled least-privilege owner boundary

retained routine search_path target =
deterministic safe object resolution with pg_catalog first
and schema-qualified application objects
~~~

This acceptance closes the bounded B2 target-contract residual semantics. It does not implement them and does not convert current AS-IS into target compliance.

Preserve:

~~~text
current 15/15 SECURITY DEFINER = AS-IS
current 15/15 owner postgres = AS-IS
current 15/15 search_path=public = AS-IS
current 8/8 Group-A anon EXECUTE = AS-IS

implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
hostile-client runtime assurance = NOT_PROVEN
cross-tenant runtime negatives = NOT_PROVEN where applicable
Group-D runtime use/nonuse = NOT_PROVEN
independent AppSec assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Program boundary after this acceptance:

~~~text
B2 HIGH-RISK TARGET-CONTRACT CLOSURE =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

STS-M2-04 final WBS closure =
NOT YET ADJUDICATED

M2-04F semantics =
NOT CANONICALLY CREATED

M2-05 execution =
NOT_AUTHORIZED

M2-06 execution =
NOT_AUTHORIZED
~~~

Next safe action is a bounded final STS-M2-04 closure adjudication against the already accepted B1/B2/B3/C/D/E target-policy evidence. No global replay is required absent a material invalidator.


## 0.0000000000000000018 HISTORICAL / SUPERSEDED — STS-M2-04 B2 HIGH-RISK TARGET-CONTRACT CLOSURE EXECUTED / RESULT AWAITING PRODUCT AUTHORITY ADJUDICATION — 2026-09-07

Current live execution anchor:

~~~text
repository = wagnerjfjunior/fecha.ai
execution-base main = dd118baa89b68281bbd7c8df43c8e24c0e9b66bf
environment = Pilot Production / SaaS multi-tenant / multiempresa
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
Security Go = NOT_GRANTED
~~~

Product Authority authorized exactly the bounded READ_ONLY closure of the 15 routines already classified in STS-M2-04B2, with GitHub READ_ONLY and Supabase live READ_ONLY when necessary. No implementation, migration, function change, GRANT/REVOKE, RLS/policy mutation, production mutation, deploy or Security Go was authorized.

Live database capability preflight:

~~~text
REQUESTED_PROOF_LEVEL = LIVE_DATABASE_AUDIT
REQUIRED_CAPABILITY = FECHAI_SUPABASE_LIVE_READ
CAPABILITY_STATUS = AVAILABLE
TARGET = uobxxgzshrmbtjfdolxd
TASK_ADMISSION = ADMITTED
~~~

Execution result:

~~~text
B2 HIGH-RISK TARGET-CONTRACT CLOSURE =
EXECUTED READ_ONLY / RESULT READY FOR PRODUCT AUTHORITY ADJUDICATION

exact routines resolved live = 15 / 15
live B2 function/metadata fingerprint =
33aea33ec2039d91f417b3980ea8cf43

15 / 15 current SECURITY DEFINER = YES
15 / 15 current owner = postgres
15 / 15 current proconfig includes search_path=public
8 / 8 Group-A current anon EXECUTE = YES

Supabase mutation = NONE
runtime hostile testing = NONE
AppSec assurance = NOT_PERFORMED
~~~

Versioned caller/provenance delta:

~~~text
ACTIVE VERSIONED APPLICATION CALLER:
1 alterar_plano_empresa_root
2 atualizar_status_empresa_root
3 importar_mesa_cliente_disponibilidade_oficial
6 registrar_upload_arquivo_mesa
8 salvar_mesa_cliente_enriquecimento
10 avaliar_lista(uuid,integer,text)
11 trilha_lead

DB_INTERNAL PARENT:
9 acquire_lote_lock <- solicitar_lote(uuid)

NO VERSIONED APPLICATION CALLER FOUND IN BOUNDED CURRENT-MAIN SEARCH:
4 mesa_cliente_upsert_faixas_premio
5 mesa_cliente_upsert_politica_financeira
7 salvar_mesa_cliente_desconto_politica
12 dispensar_lembrete
13 mover_funil_batch
14 redefinir_senha_corretor
15 registrar_audit_log

NO_VERSIONED_CALLER != RUNTIME_UNUSED
~~~

Candidate target-contract disposition returned for Product Authority adjudication:

~~~text
01 alterar_plano_empresa_root
   -> PRIVILEGED_OPERATION / TARGET DEFINER / authenticated root entrypoint
02 atualizar_status_empresa_root
   -> PRIVILEGED_OPERATION / TARGET DEFINER / authenticated root entrypoint
03 importar_mesa_cliente_disponibilidade_oficial
   -> PRIVILEGED_OPERATION / TARGET DEFINER / authenticated tenant-admin/root entrypoint
04 mesa_cliente_upsert_faixas_premio
   -> PRIVILEGED_OPERATION / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until canonical caller is proven
05 mesa_cliente_upsert_politica_financeira
   -> PRIVILEGED_OPERATION / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until canonical caller is proven
06 registrar_upload_arquivo_mesa
   -> AUTHENTICATED_COMMAND / TARGET DEFINER / authenticated entrypoint
07 salvar_mesa_cliente_desconto_politica
   -> PRIVILEGED_OPERATION / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until canonical caller is proven
08 salvar_mesa_cliente_enriquecimento
   -> AUTHENTICATED_COMMAND / TARGET DEFINER / authenticated RPC command boundary
09 acquire_lote_lock
   -> DB_INTERNAL_HELPER / TARGET INVOKER / NO DIRECT CLIENT EXECUTE
10 avaliar_lista(uuid,integer,text)
   -> AUTHENTICATED_COMMAND / TARGET DEFINER / authenticated entrypoint
11 trilha_lead
   -> AUTHENTICATED_QUERY / TARGET INVOKER / authenticated caller-visible lead scope
12 dispensar_lembrete
   -> AUTHENTICATED_COMMAND / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until caller is proven
13 mover_funil_batch
   -> AUTHENTICATED_COMMAND / DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE until caller + role/team scope are proven
14 redefinir_senha_corretor
   -> NON_MODE_LIFECYCLE candidate / RETIRE_LEGACY_SQL_RPC after dependency check
15 registrar_audit_log
   -> NON_MODE_LIFECYCLE candidate / RETIRE_OR_REPLACE_WITH_TRUSTED_INTERNAL_AUDIT_HELPER after dependency check
~~~

Candidate mode/lifecycle projection, not yet Product-Authority accepted:

~~~text
ACTIVE TARGET DEFINER = 6
DEFINER_IF_RETAINED / DORMANT = 5
TARGET INVOKER = 2
NON_MODE_LIFECYCLE CANDIDATE = 2
TOTAL = 15
~~~

Shared target contract proposed by the READ_ONLY closure:

~~~text
PUBLIC EXECUTE target = 0 / 15
anon EXECUTE target = 0 / 15
service_role direct EXECUTE required by proven canonical caller = 0 / 15

active direct authenticated entrypoints proposed =
1,2,3,6,8,10,11

callerless retained routines =
NO CLIENT EXECUTE until canonical caller/product contract is proven

DEFINER owner target =
controlled least-privilege owner boundary;
current postgres ownership is not accepted as target-compliance proof

retained routine search_path target =
deterministic safe object resolution with pg_catalog first and
schema-qualified application objects;
current search_path=public is AS-IS evidence, not target-compliance proof
~~~

Material live RLS/DML composition supporting the candidate:

- all material touched tables inspected in this closure have RLS enabled;
- authenticated direct writes are absent on the privileged stock, company, financial-policy, lead/funnel and audit write surfaces material to the retained DEFINER decisions;
- Mesa financial-policy tables explicitly deny authenticated direct INSERT/UPDATE/DELETE while allowing tenant-scoped reads;
- mesa_cliente_unidade_enriquecimentos has authenticated DML grants but no live policy rows were returned by the bounded policy query, so direct-DML authority is not a substitute for the current RPC command boundary;
- acquire_lote_lock performs only advisory locking and is called from solicitar_lote, so current DEFINER/client reachability is not justified by the body;
- trilha_lead is read-only, has an active authenticated application caller, and its current body incorrectly treats lead-id specificity/GRANT as sufficient authority while the live function ACL state lacks authenticated EXECUTE.

The candidate dispositions do not authorize implementation and do not prove runtime safety.

Preserved assurance residuals:

~~~text
hostile-client runtime assurance = NOT_PROVEN
cross-tenant runtime negatives = NOT_PROVEN where applicable
Group-D actual runtime use/nonuse = NOT_PROVEN
track_functions = none; database call statistics cannot prove non-use
independent AppSec assurance = NOT_PERFORMED
implementation remediation = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Decision boundary:

~~~text
RESULT PACKET != PRODUCT AUTHORITY ACCEPTANCE
STS-M2-04 final closure = NOT YET ADJUDICATED
M2-04F semantics = NOT CANONICALLY CREATED
M2-05 execution = NOT_AUTHORIZED
M2-06 execution = NOT_AUTHORIZED
~~~

Next safe action is Product Authority adjudication of this bounded 15-routine result. No global B1/B2/B3/C/D/E replay is required absent a material invalidator.

## 0.0000000000000000017 HISTORICAL / SUPERSEDED — PR #189 MERGED / STS-M2-04E CORRECTED CONTRACT ON MAIN — 2026-09-07

Canonical post-merge state:

~~~text
PR #189 = MERGED / CLOSED
authorized exact head = b7baa29dbbfeeaee78e423f7950ba17390fac0e2
merge commit = 13eec5a6b720d67ed29a1837a01502123547ccb6
current canonical main = 13eec5a6b720d67ed29a1837a01502123547ccb6

corrected E evidence blob =
07365cae5a353bd2407512ddde0d3d4cf880352f

STS-M2-04E corrected contract =
VERSIONED + MERGED
~~~

The merge closes the PR #189 documentation lifecycle. It does not prove implementation, Supabase application, runtime behavior, AppSec assurance, hostile/cross-tenant assurance or Security Go.

Preserve:

~~~text
STS-M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

FIVE-RESIDUAL E AUTHORITY ADJUDICATION = COMPLETE
B3/C3 TARGET-AUTHORITY SEMANTIC RESIDUALS = ZERO
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED

historical C3 =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113 B3/C3 routines

B3/C3 subset projection after E =
70 target DEFINER
41 target INVOKER
0 target-authority semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 B3/C3 routines

B2 = separate accepted 15-routine slice with residuals
M2-04D = separate accepted 9-trigger-routine target classification
~~~

Material residuals remain open and unchanged:

~~~text
004 implementation/security remediation = NOT_PERFORMED
031 implementation/caller-ACL remediation = NOT_PERFORMED
036 RETIRE_CURRENT_SEMANTICS lifecycle implementation = NOT_PERFORMED
047 global-body/RLS remediation = NOT_PERFORMED
119 current DEFINER -> target INVOKER remediation/runtime assurance = NOT_PERFORMED
127 retirement/deprecation implementation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
hostile/cross-tenant runtime assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Vercel reported a successful integration status on the merge commit. This record does not independently classify that status as production runtime validation, smoke testing or Security Go.

Next durable program action:

~~~text
PRODUCT AUTHORITY SELECT / DEFINE
THE NEXT BOUNDED STS-M2-04 ACTION

next bounded STS-M2-04 action = NOT_SELECTED
M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
M2-05 execution = NOT_AUTHORIZED
M2-06 execution = NOT_AUTHORIZED
~~~

Absent a new material event, do not create another SFJM-only reconciliation merely because this reconciliation itself advances through GitHub lifecycle.

## 0.0000000000000000016 HISTORICAL / SUPERSEDED — PRE-MERGE STS-M2-04E CORRECTED BOUNDED AUTHORITY STATE — 2026-09-07

Product Authority authorized the bounded PR #189 post-review correction without reopening B/C/D globally.

~~~text
STS-M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

FIVE-RESIDUAL E AUTHORITY ADJUDICATION = COMPLETE
B3/C3 TARGET-AUTHORITY SEMANTIC RESIDUALS = ZERO
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED

historical C3 =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113 B3/C3 routines

B3/C3 subset target projection after E =
70 target DEFINER
41 target INVOKER
0 target-authority semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 B3/C3 routines

B2 = separate accepted 15-routine slice with residuals
M2-04D = separate accepted 9-trigger-routine target classification
~~~

Corrected target decisions material to continuity:

~~~text
031 gerenciar_lista(uuid,text,text)
  -> TARGET DEFINER
  -> ADMIN_LOCAL branch = tenant/company scoped
  -> GESTOR branch = tenant + managed-team scoped
  -> ROOT / ADMIN_GLOBAL is not an automatic tenant lifecycle shortcut
  -> implementation/caller-ACL remediation REQUIRED

036 get_dashboard_master()
  -> NON_MODE_LIFECYCLE / RETIRE_CURRENT_SEMANTICS
  -> current global commercial semantics NOT TARGET-COMPLIANT
  -> possible future replacement NOT DEFINED BY E
  -> possible future replacement NOT AUTHORIZED BY PR #189

119 relatorio_fornecedor(uuid)
  -> TARGET INVOKER already RESOLVED in C3
  -> current implementation remains postgres-owned SECURITY DEFINER
  -> implementation/runtime remediation REQUIRED
  -> implementation residual, not product semantic residual
~~~

Preserve:

~~~text
ROOT / ADMIN_GLOBAL = PLATFORM CONTROL PLANE
ADMIN_LOCAL = TENANT CONTROL PLANE
GESTOR = TEAM CONTROL PLANE
CORRETOR = INDIVIDUAL BUSINESS PLANE
platform authority != automatic tenant business authority

TARGET CONTRACT != CURRENT IMPLEMENTATION
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
hostile/cross-tenant runtime assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
~~~

Immediate lifecycle gate after the authorized correction commit:

~~~text
PR #189 = OPEN
fresh independent exact-head review of the corrected head = REQUIRED
merge = NOT_AUTHORIZED
deploy = NOT_AUTHORIZED
~~~

After that exact-head gate, the program-level semantic continuation remains Product Authority selection/definition of the next bounded M2-04 action; no lettered slice is inferred.

## 0.0000000000000000015 HISTORICAL / SUPERSEDED — PRE-CORRECTION STS-M2-04E TARGET AUTHORITY SYNTHESIS WORDING — 2026-09-06

Product Authority accepted the bounded STS-M2-04E synthesis and five-residual delta.

~~~text
decision base main =
aa266df3124f407a3f2c155c8f8ab5c193707783

durable E evidence =
docs/security/evidence/2026-09-06-sts-m2-04e-architecture-synthesis-acceptance.md

durable E Git blob =
6f6a9bd1f181dfcf34ab979284338e497fb09f61

STS-M2-04C historical projection =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113

STS-M2-04D =
COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT
8 DEFINER / 1 INVOKER / 0 NOT_DETERMINED
9 trigger functions / 18 trigger instances

STS-M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
~~~

E supersedes only the five C3 residual target-authority decisions; C3 history remains unchanged.

~~~text
004 aprovar_rejeitar_mesa(uuid,text,text)
  -> TARGET DEFINER
  -> product semantics RESOLVED
  -> implementation/security remediation REQUIRED

031 gerenciar_lista(uuid,text,text)
  -> TARGET DEFINER
  -> product semantics RESOLVED
  -> implementation/caller-ACL remediation REQUIRED

036 get_dashboard_master()
  -> NON_MODE_LIFECYCLE
  -> RETIRE_OR_REPLACE_CURRENT_SEMANTICS
  -> current global commercial semantics NOT TARGET-COMPLIANT

047 get_stats_horario()
  -> TARGET INVOKER
  -> tenant/team-scoped
  -> current global-body/RLS remediation REQUIRED

127 solicitar_lote_forcado(uuid)
  -> NON_MODE_LIFECYCLE
  -> RETIRE / DEPRECATE
  -> lot request product semantics = SELF-ONLY
~~~

E-level target-authority projection:

~~~text
70 target DEFINER
41 target INVOKER
0 target-authority semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 inventoried routines
~~~

The two lifecycle dispositions remain in the 113 inventory; do not misstate 70+41 as the complete routine count.

Issue #133 authority remains binding:

~~~text
ROOT / ADMIN_GLOBAL = PLATFORM CONTROL PLANE
ADMIN_LOCAL = TENANT CONTROL PLANE
GESTOR = TEAM CONTROL PLANE
CORRETOR = INDIVIDUAL BUSINESS PLANE
platform authority != automatic tenant business authority
~~~

Preserve:

~~~text
TARGET CONTRACT RESOLVED != CURRENT IMPLEMENTATION COMPLIANT
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
runtime hostile/cross-tenant assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
~~~

Next semantic gate: Product Authority selects/defines the next bounded M2-04 action from the accepted C/D/E state. No implementation authority is inherited.

## 0.0000000000000000014 HISTORICAL / SUPERSEDED — STS-M2-04D COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT — 2026-09-06

Master Project accepted the bounded trigger-authority classification after independent live reconciliation.

~~~text
STS-M2-04C =
COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS

M2-04C projection =
68 DEFINER
40 INVOKER
5 NOT_DETERMINED
113 total

STS-M2-04D =
COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT

M2-04D trigger functions =
8 DEFINER
1 INVOKER
0 NOT_DETERMINED
9 total

D trigger instances =
18 / 18 covered
~~~

Durable D evidence:

~~~text
path = docs/security/evidence/2026-09-06-sts-m2-04d-trigger-authority-classification.md
source packet SHA-256 =
6927b61338555fef95cc25892bb6097e815839b53bc217e0229084c5e5220389
Git blob = 7fdc63a95d81661598937aa0bdfa654bcb9db66a
~~~

Target D modes:

~~~text
DEFINER = 011,012,013,014,015,030,075,130
INVOKER = 111
~~~

Direct client EXECUTE target:

~~~text
required = 0
not required = 9
not determined = 0
~~~

Do not combine the C 113-routine distribution with the D nine-trigger-function distribution into a new global authority projection inside D. Cross-slice synthesis belongs to STS-M2-04E.

M2-04D establishes target trigger authority architecture only.

~~~text
D-01 through D-08 remediation = NOT_IMPLEMENTED
runtime hostile/concurrency assurance = NOT_PERFORMED
M2-04E = NOT_AUTHORIZED
M2-04F = NOT_AUTHORIZED
Security Go = NOT_GRANTED
~~~

Next semantic gate is Product Authority selection/authorization of STS-M2-04E — architecture synthesis.

## 0.0000000000000000013 HISTORICAL / SUPERSEDED — STS-M2-04C COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS — 2026-09-06

Master Project adjudicated the C4 consolidation packet and closes the M2-04C analysis/design slice.

```text
STS-M2-04C1 = COMPLETE
STS-M2-04C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
STS-M2-04C3 = COMPLETE WITH RESIDUAL NOT_DETERMINED / ACCEPTED
STS-M2-04C4 = COMPLETE / ACCEPTED

STS-M2-04C =
COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS

Security Go = NOT_GRANTED
```

Durable per-routine C3 adjudication evidence:

```text
path = docs/security/evidence/2026-09-06-sts-m2-04c-c3-routine-mode-adjudication.csv
rows = 57
content SHA-256 = cdc028d5874d4e7f2c783e9380def40373ed525fec89514f1becd073f36027ab
Git blob = 716c23d5f549eb465f3393cdfc5989dda82b69a7
```

Final target-mode projection preserved:

```text
DEFINER = 68
INVOKER = 40
NOT_DETERMINED = 5
TOTAL = 113
```

The five remaining target-authority residuals are bounded and explicitly handed off rather than forcing false closure:

```text
004 aprovar_rejeitar_mesa(uuid,text,text)
031 gerenciar_lista(uuid,text,text)
036 get_dashboard_master()
047 get_stats_horario()
127 solicitar_lote_forcado(uuid)
```

Blocker 119 `relatorio_fornecedor(uuid)` remains resolved at target-authority level as INVOKER. Its live implementation remains postgres-owned SECURITY DEFINER; implementation/runtime assurance has not occurred.

M2-04C establishes target authority architecture only. It does not prove implementation, runtime effectiveness, AppSec assurance, deploy or Security Go.

M2-04D/E/F remain not executed and not authorized by the M2-04C authority. The next program action is to select/authorize the next bounded M2-04 slice; M2-04D trigger classification is the natural sequential candidate.


## 0.0000000000000000012 HISTORICAL / SUPERSEDED — STS-M2-04C/C3 COMPLETE WITH RESIDUAL NOT_DETERMINED — 2026-09-06

Master Project adjudicated the complete Backend/Data C3 packet against live FECH.AI/Supabase evidence.

```text
STS-M2-04C1 = COMPLETE
STS-M2-04C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
STS-M2-04C3 = COMPLETE WITH RESIDUAL NOT_DETERMINED / ACCEPTED
STS-M2-04C4 = NEXT / AUTHORIZED READ_ONLY
Security Go = NOT_GRANTED
```

C3 adjudicated exactly the 57 routines that entered from B3 as TARGET_SECURITY_MODE = NOT_DETERMINED:

```text
NEW TARGET DEFINER = 16
NEW TARGET INVOKER = 36
REMAIN NOT_DETERMINED = 5
TOTAL = 57
```

Projected complete B3 target distribution for C4 consolidation:

```text
DEFINER = 68
INVOKER = 40
NOT_DETERMINED = 5
TOTAL = 113
```

The five bounded unresolved authority cases are:

```text
004 aprovar_rejeitar_mesa = NOT_DETERMINED / BLOCKER REMAINS
031 gerenciar_lista = NOT_DETERMINED / BLOCKER REMAINS
036 get_dashboard_master = NOT_DETERMINED / BLOCKER REMAINS
047 get_stats_horario = NOT_DETERMINED / BLOCKER REMAINS
127 solicitar_lote_forcado = NOT_DETERMINED / BLOCKER REMAINS
```

Blocker 119 `relatorio_fornecedor(uuid)` is resolved at target-mode authority level as INVOKER because caller/RLS composition supplies the list/tenant boundary that current postgres-owned DEFINER bypasses. This is a target-contract decision, not a claim that the current live implementation has changed or is runtime-proven safe.

C3 also confirms that privileged authority can be localized in lower callees for wrappers such as 054, 107–109, 126 and 137, while core policy-recursive helpers retain routine-specific DEFINER justification.

No canonical B3 CSV modification, function-mode change, Supabase/Auth mutation, SQL/DDL/DML, RLS/policy/grant change, hostile runtime testing, Ready, merge, deploy or Security Go occurred.


## 0.0000000000000000011 HISTORICAL / SUPERSEDED — STS-M2-04C/C2 COMPLETE WITH RESIDUAL EVIDENCE GAPS — 2026-09-06

Master Project adjudicated the complete Backend/Data C2 packet against live FECH.AI/Supabase evidence.

```text
STS-M2-04C1 = COMPLETE
STS-M2-04C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
STS-M2-04C3 = NEXT / AUTHORIZED READ_ONLY
STS-M2-04C4 = PENDING
Security Go = NOT_GRANTED
```

Accepted C2 conclusions: policy-helper graph materially complete; material RLS/policy surface covered live; 57/57 unresolved B3 routines received C2 dependency input; core policy-helper recursion materially proven; six B3 blockers received C2 impact classification.

```text
004 = DOES NOT RESOLVE
031 = PARTIALLY RESOLVES
036 = PARTIALLY RESOLVES
047 = PARTIALLY RESOLVES
119 = PARTIALLY RESOLVES
127 = DOES NOT RESOLVE
```

Residual evidence gap: no fresh exhaustive current application direct-DML callsite sweep. This does not block bounded C3 where live caller/table/policy composition is already sufficient.

Evidence-discipline correction: branch/commit ref resolution is not INTEGRAL_READ of a repository. This corrects the specialist packet wording only and does not invalidate C2 technical conclusions.

No implementation, Supabase/Auth mutation, SQL/DDL/DML, RLS/policy/grant/function change, hostile runtime testing, Ready, merge, deploy or Security Go is authorized.


## 0.0000000000000000010 HISTORICAL / SUPERSEDED — STS-M2-04C STARTED — C1 COMPLETE / C2 NEXT — 2026-09-06

Product Authority authorized `STS-M2-04C` as a bounded read-only RLS/direct-authority analysis slice.

```text
FECH.AI main at M2-04C start = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main observed = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment = Pilot Production / SaaS multi-tenant / multiempresa
Security Go = NOT_GRANTED
```

Operational decomposition:

```text
M2-04C1 = COMPLETE / MASTER-PROJECT LIVE READ-ONLY INVENTORY
M2-04C2 = NEXT
M2-04C3 = PENDING
M2-04C4 = PENDING
```

C1 live observations material to C2/C3:

```text
public tables = 44
RLS enabled = 44 / 44
FORCE RLS = 30 / 44
FORCE RLS false = 14 / 44
anon direct table privilege = 0 tables
authenticated direct SELECT = 28 tables
authenticated direct write privilege = 9 tables
B3 target mode NOT_DETERMINED = 57 routines
```

C1 is inventory/evidence, not a vulnerability verdict and not a blanket argument for INVOKER or FORCE RLS. Central RLS policy helpers are currently SECURITY DEFINER/owner `postgres`; live role evidence shows `postgres.rolbypassrls = true`, so C2 must analyze helper/body/policy composition rather than assume RLS governs DEFINER execution.

Preserve B3 without replay:

```text
STS-M2-04B3 = COMPLETE / ACCEPTED
coverage = 113 / 113
target mode = 52 DEFINER / 4 INVOKER / 57 NOT_DETERMINED
blockers = 004,031,036,047,119,127
```

Next semantic action is M2-04C2: policy-helper graph, USING/WITH CHECK semantics, direct-DML authority and C2 dependency inputs for exactly the 57 unresolved B3 routines. No implementation or security mutation is authorized.

All lower-numbered sections below are historical continuity and do not override this current M2-04C state.


## 0.0000000000000000009 HISTORICAL — STS-M2-04B3 / PR #183 MERGED STATE RATIFIED — SUPERSEDED BY M2-04C CURRENT STATE — 2026-09-06

Product Authority ratified `main` commit `53a70f814e8b695439358ebe609850f25bf636a9`, produced by merge of PR #183 final head `d805194c5f896766af24e4d4a56869c91d31a60c`.

```text
PR #183 = CLOSED / MERGED
merged state = ACCEPTED BY PRODUCT AUTHORITY
authority/lifecycle provenance exception = RECORDED
historical exact-head merge authorization = NOT_RECOVERED
retroactive authorization fabrication = NO
revert = NOT_REQUIRED
```

The exception affects lifecycle provenance only. It does not reopen or modify the completed B3 adjudication:

```text
STS-M2-04B1 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
B3 coverage = 113 / 113
target mode = 52 DEFINER / 4 INVOKER / 57 NOT_DETERMINED
blockers = 004,031,036,047,119,127
Security Go = NOT_GRANTED
```

No B3 technical re-audit, DEF55 replay or PR #183 lifecycle replay is required absent a new material contradiction. M2-04C and M2-04D remain not authorized.


## 0.0000000000000000008 HISTORICAL — STS-M2-04B3 / DEF55 REVISED CLASSIFICATION COMPLETE / ACCEPTED — SUPERSEDED BY CURRENT M2-04C STATE — 2026-09-05

This section becomes canonical continuity only after PR #183 is merged. Within the open PR it records the accepted revised decision.

```text
STS-M2-04B1 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
B3 coverage = 113 / 113
target mode = 52 DEFINER / 4 INVOKER / 57 NOT_DETERMINED
justification = 52 PROVEN_BY_BODY_CONTRACT / 6 NOT_PROVEN / 51 NOT_DETERMINED / 4 NOT_REQUIRED
Security Go = NOT_GRANTED
```

The revised DEF55 reconstruction replaces the generic DEFINER rationale with routine-specific body/provenance evidence. Specific corrections include ordinals `004`, `052`, `106`, `126` and live identity signatures `021`, `022`, `028`, `032`.

Exactly six current authority blockers remain: `004`, `031`, `036`, `047`, `119`, `127`.

M2-04C and M2-04D remain NOT authorized. PR #183 lifecycle is authorized through new exact-head review, Ready revalidation and pre-merge only; merge remains separately prohibited.

## 0.0000000000000000007 HISTORICAL — STS-M2-04B3 CLASSIFICATION COMPLETE / ACCEPTED — SUPERSEDED BY LATER B3/M2-04C STATE — 2026-09-05

This section becomes current material continuity only after the B3 reconciliation is merged to canonical `main`.

Product Authority accepted `STS-M2-04B3 CLASSIFICATION` as `COMPLETE / ACCEPTED` with coverage `113 / 113`.

```text
STS-M2-04B1 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
STS-M2-04 = IN PROGRESS / TARGET-POLICY DESIGN
Security Go = NOT_GRANTED
```

Durable B3 evidence after merge:

`docs/security/evidence/2026-09-05-sts-m2-04b3-remaining-routine-authority-classification.md`

B3 closes classification for the 113 remaining non-trigger SECURITY DEFINER routines. Accepted target-mode distribution is `55 DEFINER / 2 INVOKER / 56 NOT_DETERMINED`.

The following remain `BLOCKING CURRENT AUTHORITY FINDINGS` and are not waived: `031 gerenciar_lista`, `036 get_dashboard_master`, `047 get_stats_horario`, `119 relatorio_fornecedor`, `127 solicitar_lote_forcado`.

`56 TARGET_SECURITY_MODE = NOT_DETERMINED` remain dependent on M2-04C where caller sufficiency depends on RLS/direct-table authority. The 9 SECURITY DEFINER trigger-provenance routines remain reserved for M2-04D.

No implementation, Supabase/Auth mutation, AppSec execution, M2-04C, M2-04D, Ready, merge, deploy or Security Go is authorized.

## 0.0000000000000000006 STS-M2-04B2 COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-05

Product Authority accepted `STS-M2-04B2 — High-Risk Routine Authority Classification` on decision/base main `ca77d81c3d2a6209536664128bda209996a7f423`.

```text
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED
STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-03 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B1 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04 = IN PROGRESS / TARGET-POLICY DESIGN
Security Go = NOT_GRANTED
```

Durable B2 evidence once this reconciliation is merged:

`docs/security/evidence/2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md`

B2 is limited to exactly 15 high-risk routines. Accepted anchors include: `0/8` Group-A `ANON_COMMAND_EXCEPTION` proven; `acquire_lote_lock(uuid,uuid)` classified as `DB_INTERNAL_HELPER` with contradictory direct reachability; `avaliar_lista(uuid,integer,text)` and `trilha_lead(uuid)` with canonical authenticated application callers but caller×ACL contradictions; `trilha_lead` tenant/object authority not sufficiently proven; service-role reachability not treated as service-use proof; no-versioned-caller and unused-candidate states not treated as runtime non-use.

Current `SECURITY DEFINER` justification remains `NOT_PROVEN / NOT_DETERMINED` where classified; owner `postgres` compatibility remains conditional; `search_path=public` does not prove target-safe search-path semantics; hostile/cross-tenant runtime assurance and independent AppSec assurance remain open.

The B1 Product Authority decision and durable documentation were merged via PR #181 and are canonical on main `0b4868ef80e69bab5f0397c29af4474fb097e739`. This B2 reconciliation preserves that canonical B1 state and does not rewrite B1.

No implementation, SQL, GRANT/REVOKE, ALTER FUNCTION, owner/search_path change, Supabase/Auth mutation, runtime testing, AppSec testing, B3, M2-04C, M2-04D, deploy or Security Go is authorized.

## 0.0000000000000000005 STS-M2-04B1 COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-05

Product Authority accepted the bounded target-policy package `STS-M2-04B1 — Routine Authority Policy Core` on decision-anchor main `ca77d81c3d2a6209536664128bda209996a7f423`.

Canonical durable evidence:

`docs/security/evidence/2026-09-05-sts-m2-04b1-routine-authority-policy.md`

```text
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED
STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-03 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04 = IN PROGRESS / TARGET-POLICY DESIGN
STS-M2-04B1 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B2 = NOT STARTED / EXECUTION NOT AUTHORIZED
Security Go = NOT_GRANTED
```

Accepted B1 target rules:

```text
SECURITY DEFINER = PRIVILEGED EXCEPTION
SECURITY INVOKER = PREFERRED DEFAULT WHEN CALLER AUTHORITY IS DELIBERATELY SUFFICIENT

routine authority =
caller + routine class + EXECUTE ACL + security mode + owner authority
+ actor/tenant/role derivation + side effects + transitive authority + proof obligation
```

The current 160-routine surface is not declared compliant with B1. Per-routine classification, current owner/search_path semantic compliance, caller×ACL residuals and hostile-client/cross-tenant runtime assurance remain unresolved.

Product Authority authorized B2 **scope preparation only**. B2 substantive classification, implementation, SQL/Supabase mutation, runtime testing, Ready, merge, deploy and Security Go remain unauthorized.


## 0.0000000000000000004 STS-M2-03 COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-05

Product Authority accepted STS-M2-03 on exact main `682837dab2c719330c2e6e72e885ed6de5e2f171`.

```text
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED
STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-03 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04 = NEXT GATE / NOT STARTED
Security Go = NOT_GRANTED
```

Durable accepted evidence:

`docs/security/evidence/2026-09-05-sts-m2-03-index-acl-contradictions.md`

Independent specialist convergence:

- `BACKEND_DATA_RECOMMENDS_STS_M2_03_ACCEPTANCE_WITH_RESIDUALS`
- `ARCHITECTURE_RECOMMENDS_STS_M2_03_ACCEPTANCE_WITH_RESIDUALS`
- `APPSEC_NOT_REQUIRED_FOR_STS_M2_03_ACCEPTANCE`

Current authoritative write-policy AS-IS is `14 structurally authenticated-reachable / 32 non-reachable`, decomposed into `13 latent/grant-blocked + 19 false-predicate`. The historical STS-M2-02 `15/31` split remains accepted historical evidence; its delta cause is `NOT DETERMINED`, without global M2-02 reopening.

No remediation, runtime mutation, STS-M2-04 implementation, deploy or Security Go is authorized.


## 0.0000000000000000003 STS-M2-02 COMPLETE / ACCEPTED WITH RESIDUALS — 2026-09-05

Product Authority accepted STS-M2-02 on the exact decision anchor:

- FECH.AI main: `afa92903bda1755241c1fea5d9fbb436f75231ca`
- status: `COMPLETE / ACCEPTED WITH RESIDUALS`
- semantic boundary: `STS-M2-02 AS-IS DATABASE AUTHORITY MAP = SUFFICIENTLY UNDERSTOOD`
- Security Go: `NOT_GRANTED`

Durable accepted evidence:

`docs/security/evidence/2026-09-05-sts-m2-02-database-authority-map.md`

Independent specialist convergence:

- `BACKEND_DATA_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS`
- `ARCHITECTURE_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS`
- `APPSEC_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS`

Accepted canonical mapping anchors:

- public routines = 160
- SECURITY DEFINER = 137
- static caller provenance = 137 / 137 CLOSED
- actual SQL-DML routines = 57
- SECURITY DEFINER + actual SQL-DML = 56
- anon EXECUTE + actual SQL-DML = 8
- metric conflict = RESOLVED

Accepted residuals remain explicit and are not waived: broad/default privilege hazard; anon EXECUTE surface; eight anon actual-DML routines; three anon Mesa mutators without a current canonical app caller; `acquire_lote_lock` PUBLIC/anon exposure; latent grant/RLS/policy combinations; `avaliar_lista(3)` and `trilha_lead` caller×ACL contradictions; service-only/no-versioned-caller privileged routines; legacy `redefinir_senha_corretor`; and runtime hostile-client/cross-tenant assurance gaps.

Runtime hostile-client, cross-tenant, RLS/policy adversarial effectiveness, lock-abuse, caller×ACL runtime behavior and no-caller runtime non-use remain `NOT_TESTED`, `NOT_DETERMINED` or `NOT_PROVEN` where applicable.

This acceptance does not authorize remediation or implementation. Once this bounded reconciliation is merged to canonical main, the next safe action is `STS-M2-03 — ÍNDICES / ACL CONTRADITÓRIAS — READ_ONLY FIRST`.


## 0.0000000000000000002 STS-M2-01 AUDITABILITY CORRECTION — 2026-09-04

The accepted STS-M2-01 result is now backed by a durable row-level evidence artifact:

```text
docs/security/evidence/2026-09-04-sts-m2-01-database-canonicality-matrix.md

matrix rows = 44
KEEP = 40
INTERNAL = 4
CONSOLIDATE = 0
RETIRE = 0
REMODEL = 0
NOT_DETERMINED = 0
```

This reference closes the post-PR-174 documentation finding that aggregate totals alone were insufficient for future consumers to reconstruct the accepted per-table disposition.

The semantic state remains unchanged:

```text
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED
STS-M2-02 = NEXT / READ_ONLY
```

No implementation authority is introduced.

## 0.0000000000000000001 STS-M2 STARTED / STS-M2-01 ACCEPTED — 2026-09-04

This section records a material program transition. While present only on a PR head it is candidate continuity; once merged to canonical `main`, it is the current SFJM semantic authority for STS-M2 / STS-M2-01.

```text
program = Issue #141 — FECH.AI Security-to-Scale 2026
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED BY PRODUCT AUTHORITY

planning WBS label = Matriz de 43 tabelas / 20h
current live public-table universe = 44
43→44 delta = explained by public.importar_leads_batch_idempotency
unresolved numerical table-count drift = 0

FINAL CANONICALITY MATRIX
KEEP = 40
INTERNAL = 4
CONSOLIDATE = 0
RETIRE = 0
REMODEL = 0
TOTAL = 44
NOT_DETERMINED = 0
```

Accepted evidence chain:

```text
Backend/Data Phase A = PASS
Architecture Phase B = PASS WITH RESIDUAL EVIDENCE OBLIGATIONS
final three-table delta = PASS
Master Project adjudication = READY FOR / ACCEPTED BY PRODUCT AUTHORITY
```

Residual evidence obligations remain attached to current KEEP dispositions and do not become silent PASS:

- `public.logs` — producer/consumer taxonomy, retention, data sensitivity, relationship to audit facilities;
- `public.mesa_fluxo_pagamentos_canonico` — canonical read cutover, backfill/equivalence, authoritative writer/read contract, rollback;
- `public.templates_mensagens` — complete readers/writers, compatibility, data relevance, migration/equivalence/rollback.

```text
KEEP_NOW != PERMANENT_ARCHITECTURAL_END_STATE
M2-01_ACCEPTED != DATABASE_IMPLEMENTATION_AUTHORIZED
M2-01_ACCEPTED != SECURITY_GO
```

No database, Auth, RLS, policy, grant, routine, trigger, index, runtime or production mutation is authorized by this state transition.

## 0.000000000000000000 PROGRAM HIERARCHY / CORE DoD ADJUDICATION — 2026-09-04

This section is candidate documentation while it exists only on PR #170 and becomes durable material meaning only when present on canonical `main`.

```text
repository = wagnerjfjunior/fecha.ai
decision/base main = 2bad8e9c3d6d6e091a6416c556e793eb1b24e0ec
program hierarchy decision = docs/governance/2026-09-04-fechai-bcr-security-to-scale-program-hierarchy-core-dod.md
current execution program = Issue #141 — FECH.AI Security-to-Scale 2026
current granular execution baseline = docs/roadmap/fechai-security-to-scale-2026-wbs.md

PRODUCT_MODULE_M1..M6 = product capability taxonomy / not execution milestone authority
B0-M1..M6 = immutable historical 300 WDP delivery baseline / not current execution baseline
STS-M0..M6 = current Security-to-Scale milestones
sfjm-workspace = derived representation / not FECH.AI authority

STS-M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
J4 environment-dependent evidence = DEFERRED
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
OC-01 = REQUIRED BEFORE EXTERNAL USERS

STS-M2 = Database Simplification & Optimization Plan / ELIGIBLE / NOT STARTED
STS-M2-01 = Matriz de 43 tabelas / 20h / SCOPE RECONSTRUCTION ONLY
STS-M2-01 implementation = NOT_AUTHORIZED
```

Current program finish-line clarification:

```text
CORE = CRM + Funil + Discador + Power Message Engine + MesaCliente
STS-M4 = core vertical-slice modularization + functional equivalence
STS-M5 = integrated security / reliability validation
STS-M6 = Security Go candidate + professional AS-BUILT + operational readiness

CORE_COMPLETE != EVERY_FUTURE_FEATURE_COMPLETE
```

B0 history is preserved; uncompleted B0 requirements are not silently waived. Requirements still material to launch/core must be mapped into current WBS/backlog or a separately governed future program.

Preserve all prior M1/F1-02 lineage below. This adjudication does not start STS-M2 and grants no runtime/Supabase/Auth/Ready/merge/deploy/Security Go authority.

## 0.00000000000000000 POST-MERGE HANDOFF OVERRIDE — M1 closed / M2 next eligible — 2026-09-04

```text
repository = wagnerjfjunior/fecha.ai
live main = 4ede55dfe63b5da342e53b125e85068980090c82
PR #168 = CLOSED / MERGED
PR #168 pre-merge head = 82dafd4fe47ded3a4037668aa1200b518fd9fe07
PR #168 merge method = SQUASH
PR #168 merge commit = 4ede55dfe63b5da342e53b125e85068980090c82

M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
M1_MAIN_RECONCILED = YES
F1-02 operational remediation = CLOSED FOR CURRENT M1 ROADMAP
J4 environment-dependent evidence = DEFERRED
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY GO FOR TESTED M1 PATHS = DENIED / NOT_GRANTED
OC-01 = REQUIRED BEFORE EXTERNAL USERS / NOT BLOCKING FOR M1 ROADMAP CLOSE
M2 = NEXT ELIGIBLE MILESTONE
```

Deferred evidence remains frozen, not waived and not PASS.

Reopen trigger:

```text
Supabase Pro
AND isolated non-production environment available
AND explicit Product Authority execution authorization
```

This reconciliation does not start M2 and does not authorize runtime, Supabase/Auth, J4,
IMP-003, rollback/reapply, production smoke, OC-01, Security Go, deploy or production/data changes.

This section is the current semantic authority for M1/F1-02 lifecycle after PR #168.
Older PR-09 Draft/Ready/pre-merge wording below is historical lineage only and must not be
used as the current next action.

```text
PR-09_DOCUMENTATION = MERGED
M1_MAIN_RECONCILED = YES
M2_STARTED = NO
```

The next conversation must bootstrap from live `main`, preserve the deferred-security trigger,
and reconstruct M2/M2-01 scope before any implementation.

## 0.0000000000000000 Product Authority M1 close-out decision — 2026-09-04

```text
PRODUCT_AUTHORITY_DECISION = 2026-09-04
DECISION_BASE_MAIN = f4ff8e42f601a1e033ae6ceaf4c5ecd17b23f3a8
M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
F1-02 operational remediation = CLOSED FOR CURRENT M1 ROADMAP
J4 environment-dependent evidence = DEFERRED
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY GO FOR TESTED M1 PATHS = DENIED / NOT_GRANTED
OC-01 = REQUIRED BEFORE EXTERNAL USERS / NOT BLOCKING FOR M1 ROADMAP CLOSE
M2 = NEXT ELIGIBLE MILESTONE
```

Deferred evidence remains evidence debt, not PASS. The reopen trigger is:

```text
Supabase Pro
AND isolated non-production environment available
AND explicit Product Authority execution authorization
```

This decision does not authorize PR-08 runtime, J4 execution, IMP-003, rollback/reapply,
production smoke, OC-01 execution, Security Go, Supabase/Auth changes or production changes.

Lifecycle distinction:

```text
PRODUCT_DECISION_RECORDED = YES
PR-09_DOCUMENTATION = VERSIONED ON THIS BRANCH
PR-09_MERGED = NOT_YET_ESTABLISHED
M1_MAIN_RECONCILED = NOT_YET_ESTABLISHED
```

The intended post-merge roadmap state is `M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE`.
No J4 deferred result becomes PASS. No Security Go is granted.

OC-01 is dispositioned by Product Authority as required before external users and not blocking the
M1 roadmap close. GPT3 concurrence remains a separate evidence requirement before external-user
admission relies on that control classification.

Reopen the deferred J4 evidence only when the exact three-part trigger is satisfied.

## 0.000000000000000 HISTORICAL / SUPERSEDED SEMANTIC OVERRIDE — PR #166 post-merge/post-deploy — 2026-09-03

This section is the current lifecycle truth for PR #166. Older pre-merge/merge next-action
wording remains historical evidence and is no longer the current action.

```text
repository: wagnerjfjunior/fecha.ai
PR #166: CLOSED / MERGED
reviewed pre-merge head: e92d97044ac753f9c71aad7fc37207fa355a2d1c
MERGED_TO_MAIN = CONFIRMED
merge commit / current main: 59262ef7cbbc3d29d6c4693c2b339964d6f806aa
Vercel Production deployment for same commit: READY/SUCCESS
```

Deployment evidence is bounded: Product Authority supplied Vercel UI evidence showing
Production / Ready / main / commit 59262ef, and GitHub commit status for the exact merge
commit reports Vercel SUCCESS.

```text
Phase 1: CLOSED STATICALLY
Phase 2: CLOSED STATICALLY
Phase 3: CLOSED
Phase 4: CLOSED
PR08-RR-64M-CANONICAL-HASH = ACCEPTABLE WITH RESIDUAL RISK
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
PR-08 runtime = NOT_EXECUTED
SECURITY_GO = NOT_GRANTED
```

Residual reopen triggers remain: ENOBUFS/maxBuffer or equivalent capture failure; fixture
relation approaching/exceeding the practical envelope; large/uncontrolled dataset use;
or inability to complete rollback/cleanup evidence. Planned remediation remains server-side
ordered digest or streaming hash.

Next safe action: separately authorized READ_ONLY reconstruction of the next J4/F1-02 gate
from the merged main, without assuming runtime PASS, OC-01, PR-09 or Security Go.

No authority is created here for runtime, Supabase/Auth, OC-01, PR-09, Security Go,
Ready, merge or deploy of this reconciliation PR.

## 0.00000 Current semantic override — J3 bounded-residual closure — 2026-09-02

This section is the current semantic authority for F1-02/J3 and supersedes
older B2/B4-next wording below when it conflicts. Historical sections remain
lineage only.

```text
repository: wagnerjfjunior/fecha.ai
decision anchor main: 1449bee4b708a9211a099c52ff573cf52d44ef1c
PR #163: CLOSED / MERGED
PR-07 migration: APPLIED
Supabase ledger version: 20260902225240

evidence class: OPERATING_SESSION_RUNTIME_EVIDENCE
evidence reference: docs/sfjm/EVIDENCE_FRESHNESS.md
raw per-case execution receipt: NOT_VERSIONED
canonical executable PR-08 receipt: NOT_ESTABLISHED

post-application catalog: OPERATING_SESSION_REPORTED_PASS
runtime-negative cases: OPERATING_SESSION_REPORTED_PASS
sequential idempotency/replay: OPERATING_SESSION_REPORTED_PASS
claimant rollback: OPERATING_SESSION_REPORTED_PASS
cross-tenant runtime negatives: OPERATING_SESSION_REPORTED_PASS
feedback runtime: OPERATING_SESSION_REPORTED_PASS
true-concurrency infrastructure capability: PROVEN

IMP-003 concurrent business-RPC runtime: NOT_DETERMINED
migration rollback/reapply: NOT_DETERMINED
control failure observed: NO

CANONICAL_J3_EXIT_SATISFIED: NO
J3_GOVERNANCE_CLOSURE_BY_PRODUCT_AUTHORITY_EXCEPTION: YES
J3: CLOSED WITH BOUNDED RESIDUAL EVIDENCE
SECURITY_GO: DENIED / NOT_GRANTED
```

The Product Authority exception does not convert either missing proof
obligation to PASS or PROVEN. IMP-003 was blocked before SQL reached
PostgreSQL by the OpenAI tool safety layer. Migration rollback/reapply remains
unexecuted because the standing Product Authority rules are:

```text
NO LAB
NO SECOND SUPABASE PROJECT
NO PREVIEW BRANCH
NO PRODUCTION MIGRATION ROLLBACK TEST
```

Both obligations remain residual evidence items and must be retested if a
future executable and explicitly authorized path becomes available.

### Current single next phase gate

```text
J4 / PR-08 — REPEATABLE EXECUTABLE SECURITY MATRIX

NEXT SAFE ACTION:
reconstruct exact J4/PR-08 scope, current evidence coverage and prohibited
areas, then obtain a separate Product Authority implementation authorization.

NO PR-08 implementation authority is inherited from the J3 exception.
```

## 0.0000 Current semantic override — F1-02/B2 post-application closure — 2026-09-01

This section is the current semantic authority for the bounded F1-02/B2
finding and supersedes older B2-next wording below when it conflicts.
Historical sections remain lineage only and must not be replayed as current
authority.

```text
repository: wagnerjfjunior/fecha.ai
post-merge main: fe83383971fe852e1fc91eada824253c818ef3e7
PR #159: CLOSED / MERGED
F1-02/B2: REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN

Supabase project:
  uobxxgzshrmbtjfdolxd / Discador-MesaCliente

migration:
  f1_02_b2_revoke_direct_crm_writes
  applied exactly once
  artifact blob: 1feea4ae8c2d368092331f217f8a8ba10d82cbcc

rollback:
  NOT EXECUTED
  artifact blob: 7ae92125c780276933a0bc091a6982c95c21b9ee

read-only proof:
  PASS
  artifact blob: 0f7e94ca9cde77868197c23950cc3f5c85fcbea9

post-application direct-write boundary:
  leads authenticated INSERT=false
  leads authenticated UPDATE=false
  lotes authenticated UPDATE=false
  times direct authenticated write remains absent

compatibility writers:
  11 reviewed writers preserved

gerenciar_lista:
  remains unavailable to authenticated / anon / PUBLIC

RUNTIME_NEGATIVE_PASS:
  NOT ESTABLISHED

SECURITY_GO:
  DENIED
```

### Current single next remediation action

```text
F1-02/B4 — LIST ACL CROSS-TENANT TARGET RISK / PR-06

TARGET DESIGN + AUTHORIZATION MATRIX FIRST

required specialist participation before implementation:
  Architecture
  AppSec
  LeadOps
```

No B4 implementation authority is established by this documentation update.


**Status:** `SECURITY_TO_SCALE_2026 / M1_SECURITY_TRUTH_BASELINE_COMPLETE / F1_02_B3_REMEDIATED / REMEDIATION_PROGRAM_ACTIVE / SECURITY_GO_DENIED`
**Updated:** `2026-09-01`
**Repository:** `wagnerjfjunior/fecha.ai`

## 0.000 Current semantic override — F1-02/B3 catalog remediation closed — 2026-09-01

This section is the current semantic authority for the bounded F1-02/B3 finding
and supersedes older current-state wording below when it conflicts. Historical
sections remain lineage only.

```text
Program: Issue #141 — Security-to-Scale 2026 / OPEN
M1 baseline: Issue #150 — Security Truth Baseline / CLOSED / completed
F1-02: ACTIVE REMEDIATION
F1-02/B3: REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN
RUNTIME_NEGATIVE_PASS: NOT ESTABLISHED
SECURITY_GO: DENIED
BROAD_PAID_COMMERCIALIZATION: BLOCKED
```

Canonical GitHub anchors:

```text
repository: wagnerjfjunior/fecha.ai
PR #157: CLOSED / MERGED
reviewed head: 6f22afeb723414d87e5481d80196a2c99789e4b1
merge commit / main at B3 application:
  035f57e29d64c0cca26048a925a790459bd9976c
forward blob:
  f18f6ae194c8810282345497ff4e637e3236c45a
rollback blob:
  cf9a0119d5b3ccd6e19daa28523fcca64b712b41
read-only proof blob:
  e101b62c7638392be06090fdc81030bb01f9d7a6
```

Production/catalog closure:

```text
Supabase project: uobxxgzshrmbtjfdolxd / Discador-MesaCliente
migration ledger version: 20260901074722
migration name: f1_02_b3_revoke_direct_funnel_history_insert
application: SUCCESS / ONE AUTHORIZED INVOCATION
authenticated direct INSERT on public.funil_movimentacoes: REVOKED
authenticated effective column INSERT: ABSENT
funil_mov_insert: ABSENT
authenticated SELECT: PRESERVED
RLS / FORCE RLS: PRESERVED
validated FKs: 9 / 9
tenant rows observed: 610
tenant mismatches: 0
controlled-writer fingerprints / ACL / EXECUTE boundary: PRESERVED
post-application merged read-only proof: PASS
independent post-application AppSec verdict: PASS
rollback required: NO
```

The bounded AppSec verdict establishes only the catalog/static remediation.
No runtime-negative production test was authorized or executed. It does not
grant Security Go, broader application security, commercial readiness or final
F1-02 acceptance.

### Current single next remediation action

```text
F1-02/B2 — EXCESSIVE DIRECT CRM WRITES
TARGET DESIGN / CALL-SITE + LIVE CONTRACT RECONSTRUCTION FIRST
```

Fresh bounded read-only catalog evidence immediately preceding this
reconciliation established:

```text
public.leads:
  RLS=true / FORCE RLS=true
  authenticated INSERT=true
  authenticated UPDATE=true
  authenticated DELETE=false

public.lotes:
  RLS=true / FORCE RLS=true
  authenticated INSERT=false
  authenticated UPDATE=true
  authenticated DELETE=false
```

This B2 observation proves that direct CRM write exposure remains material. It
does not authorize REVOKE, migration design, implementation, Supabase mutation
or runtime-negative testing.



## 0.00 Current semantic override — M1 Security Truth Baseline complete — 2026-08-31

This section supersedes older `M1_ACTIVE`, acquisition-oriented and
pre-final-adjudication wording for **current continuity only**. Historical
sections below remain lineage and are not rewritten as if they had always known
the final M1 outcome.

Canonical lifecycle anchors at this reconciliation:

```text
repository: wagnerjfjunior/fecha.ai
main before this documentation lifecycle:
  a15dde5067c716b0ab3c9342855069c1fc00bcd0

#141 Security-to-Scale 2026:
  OPEN

#150 M1 Security Truth Baseline:
  OPEN at documentation-PR authorization
  ELIGIBLE_FOR_SEPARATELY_AUTHORIZED_CLOSURE

#140:
  CLOSED / MERGED
  merge commit: c0d993ebe574f644af4f83cc25630fb8c1bd41ad

#139:
  OPEN / READY
  head: 32003e75a28e235fb454d39e3e4459d0f03acb2b
  STALE_REVALIDATION_REQUIRED
  NO_FRESH_APPROVAL_FROM_M1_CLOSURE
```

Final independent specialist adjudication:

```text
Backend/Data:
  BACKEND_DATA_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

Application Security:
  APPSEC_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

Documentation Auditor:
  DOCUMENTATION_M1_CLOSURE_PASS_WITH_BOUNDED_RESIDUALS

BLOCKERS_TO_M1_BASELINE_CLOSURE:
  NONE

ADDITIONAL_TECHNICAL_REAUDIT_REQUIRED:
  NO / AUDIT_LOOP_BLOCKED
```

Current semantic state:

```text
M1_SECURITY_TRUTH_BASELINE = COMPLETE
SECURITY_GO = DENIED / NOT_GRANTED
REMEDIATION_PROGRAM = ACTIVE
BROAD_PAID_COMMERCIALIZATION = BLOCKED

M1_FINDING_DISCOVERED != M1_FINDING_REMEDIATED
M1_BASELINE_COMPLETE != SECURITY_GO
```

Final confirmed M1 finding set:

```text
M1-B-F01
  ANON_PRIVILEGED_RPC_EXECUTION_SURFACE
  CONFIRMED attack-surface / least-privilege gap
  current live counts:
    SECURITY DEFINER total = 136
    authenticated executable = 124
    authenticated executable with bounded mutation keywords = 49
    anon executable = 22
    anon executable with bounded mutation keywords = 9
    PUBLIC executable = 1
  ANON_EXECUTABLE != ANONYMOUSLY_EXPLOITABLE

M1-C-F01
  FUNIL_TENANT_RELATIONSHIP_INTEGRITY_GAP
  CONFIRMED / HIGH / P0
  BLOCKING_FOR_SECURITY_GO
  NOT_BLOCKING_FOR_M1_BASELINE_CLOSURE
  no proven cross-tenant lead leakage claim

MIGRATION_PROVENANCE_GAP
  live ledger rows = 143
  versioned GitHub migration files = 56
  ACCEPTABLE_WITH_RESIDUAL_RISK_FOR_M1_BASELINE
  NOT "87 missing controls"
  no silent migration-history rewrite

M1-D-F01
  DEPENDENCY_REPRODUCIBILITY_GAP
  CONFIRMED supply-chain / reproducibility debt

M1-D-F02
  VITE_6_4_2_KNOWN_AFFECTED_VERSION
  GHSA-fx2h-pf6j-xcff
  upgrade required
  production exploitability / compromise = NOT_ESTABLISHED

M1-E-F01
  LIVE_EDGE_FUNCTION_NOT_VERSIONED
  assistente-ai v10 live; source absent from current main
  assurance / traceability gap

M1-E-F02
  BROWSER_SESSION_REFRESH_TOKEN_EXPOSURE_SURFACE
  CONFIRMED material current finding
  localStorage itself != exploit

M1-E-F03
  EXTERNAL_WORKER_PROXY_AUTHORITY_GAP
  CONFIRMED material static finding
  runtime abuse / PII leak / tenant crossover / exploitation = NOT_PROVEN

M1-E-F04
  LEAKED_PASSWORD_PROTECTION_DISABLED
  CONFIRMED Auth hardening gap
```

Evidence limitations intentionally preserved:

```text
CONTROLLED_RUNTIME_NEGATIVE_PASS = NOT_ESTABLISHED
no active cross-tenant production negative testing
no proxy production POST
no token manipulation
no credential attack testing
no production offensive testing
Vite production exploitability prerequisites = NOT_ESTABLISHED
Worker upstream runtime behavior = NOT_ACTIVELY_TESTED
public.leads controlled runtime negative PASS = NOT_ESTABLISHED

STATIC_IMPLEMENTATION_REVIEW
!= LIVE_DATABASE_VALIDATED
!= CONTROLLED_RUNTIME_PASS
```

The bounded `APPSEC-M1-003 / public.leads` implementation/catalog closure
remains valid with its explicit runtime-evidence limitation and must not be
reopened without a material invalidation event.

The single next remediation action is defined in
`docs/sfjm/NEXT_SAFE_ACTION.md`:

```text
P0 — M1-C-F01 / FUNIL TENANT INTEGRITY
DESIGN / PROOF PLAN FIRST
```

No implementation, cleanup, Supabase mutation, production negative test,
Security Go, #139 approval or Issue #150 closure is authorized by this
documentation state alone.

## 0.0 Current material override — APPSEC-M1-003 / public.leads closure — 2026-08-30

This section supersedes older continuity wording only for the bounded
`APPSEC-M1-003 / public.leads` slice. Historical M1 entry authority remains
historical and is not rewritten.

Canonical GitHub anchors:

```text
repository: wagnerjfjunior/fecha.ai
PR #152: CLOSED / MERGED
reviewed exact head: 6964ad993b0deddd85fcf4ff7711929b4d956285
merge commit / current main at closure:
  30f4d40acbe0a1f026df9c29451607d6fa361d11

merged migration:
  supabase/migrations/20260830030000_appsec_m1_003_leads_tenant_integrity.sql
  blob: 9e3aec05d3f52987c391dd2a67f0acbb9879e7a8

merged rollback:
  supabase/rollback/20260830030000_appsec_m1_003_leads_tenant_integrity_rollback.sql
  blob: 862038db253206061666bf5f2b8a4b12011f1c41

merged test:
  supabase/tests/appsec-m1-003/leads_tenant_integrity.sql
  blob: a813274e9865cb4da9095fc69aadd55182664278

PR-head -> merged-main artifact parity: PASS
```

Production application evidence:

```text
Supabase project: uobxxgzshrmbtjfdolxd
migration application: SUCCESS
repository migration version: 20260830030000
applied ledger version: 20260830184834
ledger name:
  20260830030000_appsec_m1_003_leads_tenant_integrity

4 parent UNIQUE (id, empresa_id): PRESENT / VALIDATED
4 public.leads composite tenant-aware FKs: PRESENT / VALIDATED

RLS / FORCE RLS:
  public.leads: true / true
  public.corretores: true / true
  public.times: true / true
  public.listas: true / true
  public.lotes: true / true

public.leads rows: 5691
corretor/empresa mismatch: 0
time/empresa mismatch: 0
lista/empresa mismatch: 0
lote/empresa mismatch: 0
```

Independent post-application AppSec result:

```text
PUBLIC_LEADS_SLICE_STATUS =
  IMPLEMENTATION_COMPLETE_WITH_EXPLICIT_RUNTIME_EVIDENCE_LIMITATION

FINAL_POST_APPLICATION_VERDICT =
  APPSEC_M1_003_PUBLIC_LEADS_POST_APPLICATION_PASS_WITH_RESIDUAL_RUNTIME_EVIDENCE_LIMITATION

NEW_FINDINGS = NONE
BLOCKERS = NONE
```

Documentation Auditor supplemental gate:

```text
SUPPLEMENTAL_EVIDENCE_ADMISSION_STATUS = ADMITTED / BOUNDED_SPECIALIST_RESULT
POST_APPLICATION_APPSEC_VERDICT_STATUS = ESTABLISHED
PREVIOUS_DOCUMENTATION_BLOCKER_STATUS = CLOSED
FINAL_DOCUMENTATION_GATE_VERDICT = PASS
```

Residuals that remain intentionally open:

```text
CONTROLLED_RUNTIME_NEGATIVE_PASS = NOT_ESTABLISHED
MIGRATION_LEDGER_PROVENANCE = NON_BLOCKING_PROVENANCE_RESIDUAL
SECURITY_GO = NOT_GRANTED
```

No production adversarial test was executed. No migration-ledger history was
rewritten. This bounded closure does not close M1, does not grant Security Go,
and does not authorize or start another APPSEC-M1-003 slice.

## 0. Current Security-to-Scale transition — M0 closed / M1 active — 2026-08-28

This section is the current semantic override for continuity. Older sections below remain historical lineage only when they conflict with this section.

Canonical program transition:

```text
Program: Issue #141 — Security-to-Scale 2026 / OPEN
M0: Issue #142 — CLOSED / completed
M0 publication PR #149: MERGED
PR #149 final reviewed head: 11041d8df99228b9fc119cbbb9e81c6d859a3fb6
PR #149 merge commit / main at transition:
  e1c9800c0cb4904d0950afb94766c6e840bf575e

M1: Issue #150 — Security Truth Baseline / OPEN
Environment classification: Pilot Production multi-tenant / multi-company
Security Go: NOT GRANTED
Broad paid commercialization: BLOCKED
```

M0 exit is established for its documentation/read-only purpose. It did not prove current live-database truth, broad runtime security, Security Go or commercial readiness.

Current durable workstream classifications carried into M1:

| Object | Classification | Durable meaning |
|---|---|---|
| #139 | `ACTIVE` | user-creation membership-boundary implementation; current lifecycle/findings must be resolved live |
| #140 | `ACTIVE` | read-only Supabase Action/config evidence workstream; versioned config does not itself prove runtime Action/Builder state |
| #131 | `STALE_CONTINUITY` | historical T3A PR-head-only continuity/evidence |
| #124 | `STALE_CONTINUITY` | older continuity artifact |
| #120 | `SUPERSEDED` | historical criar-usuario v16 baseline |
| #149 | `MERGED / M0_PUBLICATION` | closed documentation lifecycle; not an active implementation workstream |
| #150 | `ACTIVE / M1` | Security Truth Baseline work item |

M1 evidence contract:

```text
STATIC_IMPLEMENTATION_REVIEW != LIVE_DATABASE_VALIDATED
LIVE_DATABASE_VALIDATED != CONTROLLED_RUNTIME_PASS
CONTROLLED_RUNTIME_PASS != SECURITY_GO
PR_HEAD_ONLY != CURRENT_LIVE_DATABASE_TRUTH
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
```

M1 is **READ_ONLY FIRST**. Its immediate purpose is to establish current truth across GitHub, applied migration state, live privileged surfaces, tenant-isolation proof requirements, dependencies/vulnerabilities and secret/infrastructure attack surfaces. No simplification implementation, production offensive testing, deploy, Supabase mutation or Security Go is implied.

The single current semantic next action is defined in `docs/sfjm/NEXT_SAFE_ACTION.md`.

## 1. Authority rule

This file is the principal authority for durable product/security operational meaning.

It intentionally does not freeze volatile GitHub lifecycle facts such as current `main`, PR Draft/Ready, current head, checks, reviews, threads, mergeability or deployment state. Resolve those live before acting.

This transition records the second distinct production preflight event. PR #129
corrected the prior PL/pgSQL alias collision, passed fresh exact-head reviews and
merged. The next exact migration invocation advanced beyond that defect and the
positive routine inventory detected a new live catalog digest. PostgreSQL again
aborted before any T3 object was created. The routine-anchor refresh is
`PR_HEAD_ONLY` until merged; resolve its live PR/head and read these files from
that exact head before continuing.

### 1.1 Latest production transition — 2026-08-25

```text
PR #128: MERGED
PR #128 reviewed head: b594218dabd9a7beaea3158bb143f5dd2fd71386
PR #128 merge commit / main: 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
criar-usuario production: v19 / ACTIVE / verify_jwt=false
Edge deployment digest: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
single controlled v19 fail-before-Auth call: HTTP 500 / EXPECTED_FAIL_CLOSED
audit row: COMMITTED / status=edge_proof_unavailable
target Auth mutation: NONE
first T3A migration application: ABORTED / PLPGSQL ROLE-ALIAS COLLISION
PR #129: MERGED
PR #129 reviewed head: 6f6092aa66352cda3d617897895b0f09019adeea
PR #129 merge commit / main: 69f4cfa1bdee331826953b492f25c12b4defc030
second T3A migration application: ABORTED / POSITIVE ROUTINE INVENTORY DRIFT
T3A migration history entry: ABSENT
T3A routines/relations after abort: ABSENT
```

The first application error was:

```text
SQLSTATE 55000
record "r" is not assigned yet
```

PR #129 renamed only those aliases/references to `role_row` in forward and
rollback pre/postflight. The second application then stopped at:

```text
SQLSTATE P0001
T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT
PL/pgSQL function inline_code_block line 386 at RAISE
```

Fresh live recomputation established:

```text
complete non-system routine inventory excluding the separately-pinned T1 guard:
  reviewed baseline: count 264 / md5 b1f0919df8a0acaca7bbea2b928b0ffe
  current live:      count 264 / md5 c299bf087df69f960dd0c611d1486675
authenticated-effective SECURITY DEFINER subset:
  count 122 / md5 7faa376a403c69239d9606559cf9c2db / UNCHANGED
non-system aggregates: count 0 / UNCHANGED
```

The only non-system routine newer than the established T1 anchor is
`extensions.grant_pg_graphql_access()`, owned by `supabase_admin`,
`SECURITY INVOKER`, bound to enabled event trigger `issue_pg_graphql_access`,
with implementation MD5 `2f3fa32125a4cd4e597bc8b3c7b55218`. The narrow
correction changes only the four complete routine-inventory digest literals in
forward and rollback. It does not exclude the helper or relax the inventory,
and it does not change counts, the authenticated definer subset, grants,
authority predicates, T1/T2, Edge code, App.jsx, business data or Auth state.

## 2. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION
WDP: unchanged
```

Architecture rule:

```text
Frontend requests/displays.
Backend/RPC/Supabase validates and decides.
Client-provided tenant/company/role/flags/ownership are not authority.
Fail closed on missing or inconsistent identity/tenant/permission evidence.
```

No Supabase test database/branch is part of the current operating model. Production remains the only database environment; this increases rollout discipline requirements and does not relax authorization, isolation, rollback or evidence gates.

## 3. T1 — corretor status authority boundary

Material state:

```text
GitHub: MERGED
Supabase production: APPLIED
Production migration record:
  version: 20260822192552
  name: f1_02_harden_status_corretor_rpc
Post-application catalog validation: ESTABLISHED
```

Current production read-only revalidation on 2026-08-23 established:

```text
public.t3_prepare_admin_password_reset(uuid): ABSENT
public.t3_prepare_admin_password_reset(uuid,uuid): ABSENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): ABSENT
public.t3_admin_password_reset_edge_proofs: ABSENT
T1 triggers on public.corretores: PRESENT / ENABLED
authenticated UPDATE columns on public.corretores exactly:
  apto_para_receber
  ativo
  must_change_password
public.marcar_senha_inicial_definida() md5:
  2a7b28d4bb6342a99d075c4d3c49af4d
```

The T1 strict authority model remains material and must not be weakened by T3A.

Important T1 interaction discovered during T3A red-team review:

```text
trg_t1_guard_corretores_direct_compat_update
→ protects ativo / apto_para_receber / must_change_password
→ currently denies gestor-originated must_change_password changes
```

Therefore the first T3A candidate cannot simply execute `UPDATE must_change_password=true` and expect strict gestor resets to work. T3A must interoperate with the existing T1 guard without disabling it, bypassing tenant checks, granting broad UPDATE, trusting the client or weakening existing status protections.

Any T1 guard correction inside T3A must be narrowly bound to the server-authorized T3 password-reset transition, permit only the intended protected transition, and have an exact rollback to the pre-T3A T1 guard contract.

## 4. T2 — frontend status cutover

Material code state:

```text
main code anchor at transition time:
  commit: 037232fe3da37a749ab980f783af92ff15e2baf2
  src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

The frontend status path was cut over from direct `PATCH public.corretores` for `ativo/apto_para_receber` to `public.atualizar_status_corretor(...)`.

Controlled positive production smoke was executed in the app and captured through HAR evidence in the operating session for:

```text
apto isolated true -> false -> true: PASS
ativo isolated true -> false -> true: PASS
ativo + apto combined false -> true restoration: PASS
unchanged field sent as null in isolated calls: PASS
status RPC returned ok=true: PASS
direct status PATCH observed in the captured flows: ZERO
```

This is bounded positive-flow evidence. It is not a broad adversarial certification of every role/tenant combination and does not grant Security Go.

The administrative password flow remains separate. The current App.jsx still contains the stale post-reset direct write:

```text
must_change_password=false
```

That path is intentionally not T2 and remains part of T3A/T3B closure.

## 5. T3A — Administrative Password Reset Multi-Tenant Authority Boundary

### Objective

Establish a non-bypassable server-side administrative password-reset boundary with:

```text
actor derived from auth.uid()
company/tenant derived server-side
strict root/admin_local/gestor authority
cross-company denial
gestor limited to ordinary broker in own ACTIVE managed team
target-existence leakage resistance
must_change_password=true before Auth password mutation
no authority from client-provided empresa/role/flags/team/ownership
rollback that restores the exact prior boundary
```

### Current implementation lineage

The initial candidate at PR head `45ad2766...` received material B1-B4
findings. Backend/Data review of `bf8fb1f...` then identified the
DB-commit-to-Auth authority race and rejected the non-transitive writer regex.
The v3 lease/fence head `46313258...` closed that race and passed B1/B4
statically, but still lacked complete membership/options, aggregate and
`public` ACL closure. The corrected exact head
`fcb7dfc2f5f2259926556652fa9cfd3443d0c214` / tree
`4dcaf2d4b6aa1248801e455def811e50ff04e414` received integral manual
Backend/Data `APPROVE` and independent AppSec `APPROVE`.

After Product Authority separately authorized Ready, the GitHub Codex review
opened material P2 `DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`. An authorized
authenticated user could call the preparation RPC directly through PostgREST,
commit a non-expiring lease and `must_change_password=true`, skip the Edge Auth
password mutation, and lack access to the service-role-only release. The T1/T3
fence would then also block ordinary self-service completion. The PR was
returned to Draft at that point, and the same T3A change set added the v4
correction:

```text
versioned criar-usuario Edge baseline + hardened leased reset path
service-role-only public.t3_issue_admin_password_reset_edge_proof(uuid,uuid)
caller-bound public.t3_prepare_admin_password_reset(uuid,uuid)
opaque one-time actor+target proof consumed before locks/lease/password state
PostgreSQL-only two-minute proof freshness; no frontend time or authority input
durable reset lease + snapshot-independent unique-index probes + three authority-table fencing triggers
service-role-only exact lease release after proven Auth success
exact authority-table ACL pinning + service_role TRUNCATE revocation
positive full non-system routine inventory instead of writer regex
full role-membership graph/options + authenticator role anchor
database/public-schema owner + complete public ACL anchor
all pg_proc routine kinds + explicit zero non-system aggregate assertion
exact fail-closed trust-anchor preflight/postflight
lease-bound T1 direct-guard interoperability
revocation of authenticated UPDATE(must_change_password)
exact drift-aware rollback blocking live proofs/leases and cleaning only expired inert proofs after full preflight
B1-B4 evidence and coverage matrix
```

Fresh integral Backend/Data and independent AppSec reviews approved exact head
`a5c92617f372599a234c0147aad13a90649348d7` / tree
`87872aac22b36437b7fb66f3614905e8df94f5ee` with no findings. PR #127 then
merged as main commit `610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87`.

Merged v4 fingerprints:

```text
T3 proof issuer prosrc: 87f8d7f0c96ce4ae52fed9e2bc4bdcdd
T3 prepare prosrc: f9bd114c7eb77313e22861816b8a88f5
T3 release prosrc: a51c5b360c5d8a3684a97271460ec249
T3 fence guard prosrc: bd611e591aa2d951b178853f78caaa65
T3-aware direct guard prosrc: 951da8a6ac6e934828f06ab1513778fa
rollback-restored pre-T3A pg_get_functiondef: 99477024e337de5645dd042a30f8cf78
```

These are approved static v4 facts, not proof that the migration is applied.

The separately-authorized Edge-first rollout deployed the exact merged source
as production `criar-usuario` v18 (`verify_jwt=false`, Git blob
`ec62997bc357b550feda5027051fe507fe9184fa`, SHA-256
`11719575bce92c85422eb5d3a78ad26a5d683c47202e6db8032f3e13d5a254a7`).
T3A issuer/prepare/release/proof/lease objects remain absent and the migration
has not been applied.

The bounded fail-before-Auth UI exercise emitted three submissions while the
browser appeared frozen. All three followed the same platform sequence:

```text
caller Auth GET 200
caller profile GET 200
audit_logs INSERT 400
proof issuer RPC 404
audit_logs PATCH 204 with no matching row
Edge response 500
no admin Auth update; target password fingerprint and updated_at unchanged
```

B1 is runtime PASS. The audit INSERT 400 is a new material blocker: live
`audit_logs` requires `acao` and `entidade`, and `ip_address` is `inet`.
T3A-v5 corrects only that audit-compatibility/integrity domain while preserving
the approved v4 authority boundary:

```text
Edge supplies modern + legacy audit columns in reset and creation paths
Edge requires the audit insert before proof/prepare/Auth
client IP is conservative for inet; raw value is stored only in legacy text ip
migration pins complete audit metadata/ACL/columns/constraints/indexes/policies
baseline audit fingerprint 5d3b70257c57f5956032e83131effabb
post-revoke fingerprint 1b1a381796f273b503cd4c41d34a3688
authenticated audit INSERT revoked; authenticated SELECT preserved
rollback locks audit after proof/authority/lease and restores/verifies the exact legacy INSERT grant
```

The v5 audit correction received Backend/Data and independent AppSec exact-head
approval at `b594218dabd9a7beaea3158bb143f5dd2fd71386`, merged through PR #128 as
`3c9daf6c49eb937824c2c2b40aba198e2727c4bb`, and its exact Edge was deployed
as production v19. One controlled call proved the corrected audit-first
fail-before-Auth path. The later separately-authorized migration invocation
then exposed the PL/pgSQL alias collision recorded in §1.1; it aborted before
DDL and created no migration-history entry.

PR #129 corrected only that collision, received both exact-head approvals and
merged as `69f4cfa1bdee331826953b492f25c12b4defc030`. The exact merged migration
was then invoked once and advanced to the positive routine inventory, which
detected live digest `c299bf087df69f960dd0c611d1486675` instead of the
historical reviewed `b1f0919df8a0acaca7bbea2b928b0ffe`. It again aborted
before DDL with no history entry or T3 object. The current digest-only refresh
is the new bounded review domain.

### Static authority contract preserved

```text
ROOT
  public.admins
  role='admin_global'
  ativo=true

ADMIN_LOCAL
  corretores.role='admin_local'
  is_admin_local=true
  ativo=true
  target same empresa
  target not protected root/admin identity
  is_gestor is not an admin-local authority prerequisite

GESTOR
  corretores.role='gestor'
  is_gestor=true
  is_admin_local=false
  ativo=true
  target same empresa
  target role='corretor'
  target not admin/gestor
  target has no public.admins identity
  target ACTIVE managed team
  team.empresa_id = actor.empresa_id
  team.gestor_id = actor.id
```

Same-company membership alone is insufficient for gestor authority.

## 6. T3A B1-B4 state after the live routine-anchor finding

The alias defect is closed by PR #129. The new finding is a genuine positive
inventory mismatch in the exact trust-anchor preflight. It does not reopen the
already established actor, tenant, proof, lease, audit or T1 logic.

| Domain | Current result | Effect of anchor refresh |
|---|---|---|
| B1 safe rollout ordering | v19 runtime PASS: one POST 500, audit committed, no Auth mutation | unchanged |
| B2 trust-anchor preflight | alias correction passed; the positive routine inventory then detected current live drift and stopped before DDL | refresh the exact full-inventory digest in forward pre/postflight; preserve count, definer subset and aggregate anchors |
| B3 drift-safe rollback | not executed; rollback must recognize the same exact live baseline before and after reversal | apply the identical full-inventory digest refresh in rollback pre/postflight |
| B4 T1 interoperability | approved static contract; migration never reached DDL | unchanged |
| Multi-tenant / actor boundary | server-derived company/role/team and `auth.uid()` actor | unchanged |
| Edge / frontend | production Edge v19; no App.jsx change | unchanged |

The second failed application is evidence that B2 failed closed on a new live
event, not an authority bypass, not a repeat of the alias defect and not a
partial deployment. Exact-head Backend/Data review must precede independent
AppSec review on the corrected Draft PR.

## 7. Material blockers

Until the digest-only correction receives Backend/Data and independent AppSec
approval on one exact head and later lifecycle/runtime authorities are granted:

```text
corrective PR Ready: BLOCKED
corrective PR merge: BLOCKED
new T3A Supabase application: AUTHORIZED ONCE AFTER REVIEWS / CURRENTLY BLOCKED BY PRECONDITIONS
T3A runtime smoke: BLOCKED
rollback execution: BLOCKED
T3B frontend password cutover: BLOCKED
Security Go: DENIED
Broad paid commercialization: BLOCKED
```

Production remains in the intended Edge-first fail-closed state: v19 can record
the attempt and fails before Auth while the issuer/prepare RPCs are absent.

## 8. Current Product Authority and limits

Product Authority separately authorized the first production migration
application after the v19 fail-before-Auth proof. That authority was consumed
by the alias-collision abort. After PR #129 review/merge, the later conditional
production authority was consumed by the second fail-closed invocation. No
automatic retry occurred after either event.

After the routine inventory mismatch and intact-production verification were
reported, Product Authority authorized:

```text
create one narrow corrective Draft PR from live main 69f4cfa1...
refresh only the four complete non-system routine inventory digest literals
  from b1f0919d... to current live c299bf08...
update directly-related evidence/SFJM
perform read-only validation
prepare exact-head specialist review material
obtain Backend/Data exact-head review, then independent AppSec exact-head review
after those reviews and resolution of the separate GitHub lifecycle
  prerequisites, apply the authenticated final migration exactly once
```

The one production retry is not exercisable during this Draft/review action.
Ready and merge remain separate unresolved lifecycle gates. Edge deploy,
runtime/Auth smoke, rollback and Security Go are not included.

## 9. Semantic next action

```text
Publish the four-literal forward/rollback routine-anchor refresh in one Draft
PR from live main, resolve its exact head, read all changed material through
EOF, obtain Backend/Data exact-head review and then independent AppSec
exact-head review. Stop in Draft before Ready.
```

No T1/T2 review is reopened. The one later production retry is already bounded
by Product Authority but may use only the authenticated final reviewed/merged
SQL after the separate GitHub lifecycle gates are resolved.

## 10. Handoff prohibitions

Do not:

```text
create a workaround that weakens T1
create another duplicate PR to relitigate B1-B4; this one post-PR129 anchor
  refresh is justified only by the newly observed live routine digest
apply SQL merely to see whether it works
use production as an offensive laboratory
normalize real users/data as part of T3A
alter App.jsx in T3A
change criar-usuario user-creation semantics outside what is strictly necessary for reset boundary compatibility
claim production PASS from static code
mark Security Go
```

## 11. Material update triggers

Update this file when durable meaning changes, including:

```text
B1-B4 corrected or materially changed
new exact-head specialist gate outcome
T3A application/deployment/runtime validation
T3B eligibility change
rollback evidence materially changes
Security Go/F1-02 acceptance changes
```

Do not update solely because a SHA advanced, a Draft became Ready, or a documentation-only lifecycle event occurred without semantic effect.

## 12. PR #166 / F1-02 PR-08 — lifecycle reconciliation — 2026-09-03

Canonical repository state for this reconciliation:

```text
repository: wagnerjfjunior/fecha.ai
main: 9d05c64281c2aeeae9d67b139eab674720184fb1
PR: #166
branch: test/f1-02-negative-security-matrix
exact reviewed head before this documentation commit: 2a0e6b8a2f964afe3c0c35c75190ae23344ed884
PR state: OPEN / READY
mergeability at reviewed head: TRUE
Vercel status at reviewed head: SUCCESS
```

Technical phase status:

```text
PHASE 1 — execution authority / SQL safety: CLOSED STATICALLY
PHASE 2 — topology / semantic truth: CLOSED STATICALLY
PHASE 3 — FUN-006 version-bound applicability: CLOSED
PHASE 4 — exact artifact provenance: CLOSED
```

Formal residual:

```text
ID: PR08-RR-64M-CANONICAL-HASH
source thread: PRRT_kwDOSEToMc6fBXHM
classification: ACCEPTABLE WITH RESIDUAL RISK
scope: PR-08 isolated test/evidence harness only; not FECH.AI production runtime
cause: canonical relation hashing materializes ordered relation JSON through psql while Node spawnSync uses maxBuffer=64 MiB
safety property: fail-closed; buffer/materialization failure prevents PASS/restored-state evidence rather than manufacturing a false PASS
direct production runtime impact: NONE ESTABLISHED
future remediation: server-side ordered digest or streaming hash
reopen triggers:
- ENOBUFS / maxBuffer / equivalent evidence-capture failure
- a fixture relation approaching or exceeding the practical envelope
- use of this harness against a large or uncontrolled dataset
- rollback/cleanup proof required at a volume the current harness cannot complete
```

Residual status does not waive execution evidence.

```text
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
PR-08 runtime execution = NOT_EXECUTED
```

Lifecycle transaction authorized by Product Authority:

```text
After publication and exact-head revalidation of this documentation commit,
resolve only these eight already-adjudicated review threads:
PRRT_kwDOSEToMc6fBXG5
PRRT_kwDOSEToMc6fBXHB
PRRT_kwDOSEToMc6fBXHU
PRRT_kwDOSEToMc6fBXHW
PRRT_kwDOSEToMc6fBXHY
PRRT_kwDOSEToMc6fBXHI
PRRT_kwDOSEToMc6fBXHF
PRRT_kwDOSEToMc6fBXHM

No other thread resolution is authorized by this entry.
```

After GitHub confirms those eight threads resolved, the next safe action is a
**separately authorized final independent exact-head pre-merge review of PR #166**.
This entry does not authorize that review, merge, deploy, runtime, Supabase/Auth,
OC-01, PR-09 or Security Go.
