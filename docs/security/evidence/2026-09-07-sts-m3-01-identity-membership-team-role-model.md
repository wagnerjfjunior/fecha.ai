# FECH.AI — STS-M3-01 — Identity / Membership / Team / Role Model — Product Authority Accepted

**Status:** `COMPLETE / ACCEPTED / DURABLE_DECISION_ARTIFACT`  
**Product Authority:** Wagner / FECH.AI  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Publication base main:** `661ef0014576d473088add0052d751e0a47d306e`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Database strategy:** `V2_STRANGLER / SAME_DATABASE_FIRST`  
**Security Go:** `NOT_GRANTED`

## 1. Product Authority decision

~~~text
STS-M3-01 =
COMPLETE / ACCEPTED

IDENTITY CONTRACT =
FROZEN

MEMBERSHIP CONTRACT =
FROZEN

TENANT ROLE CONTRACT =
FROZEN

TEAM CONTRACT =
FROZEN

PLATFORM ROOT CONTRACT =
FROZEN
~~~

This acceptance freezes the backend-authority model for downstream STS-M3 work.

It does not mean:

~~~text
IMPLEMENTATION COMPLETE
RUNTIME TARGET-COMPLIANT
LIFECYCLE REMEDIATED
APPSEC PASS
HOSTILE-CLIENT PASS
SECURITY GO
~~~

## 2. Canonical authenticated principal

~~~text
CANONICAL AUTHENTICATED PRINCIPAL =
auth.uid()
~~~

The frontend may request or display context but does not define identity, tenant, role, team or ownership authority.

## 3. Canonical tenant application identity

~~~text
CANONICAL TENANT APPLICATION IDENTITY =
public.corretores
~~~

Binding:

~~~text
auth.uid()
→ corretores.user_id
~~~

Accepted structural facts:

~~~text
corretores.user_id = UNIQUE
corretores.empresa_id = NOT NULL
~~~

## 4. Membership model v1

~~~text
ONE AUTH IDENTITY
→ ZERO OR ONE ACTIVE CORRETORES PROFILE
→ ONE EMPRESA
~~~

Canonical membership source:

~~~text
corretores.empresa_id
~~~

Current M3 v1 does not introduce simultaneous N:N multi-company membership or a new structural membership table merely for abstraction.

~~~text
MULTI-COMPANY SIMULTANEOUS MEMBERSHIP =
NOT PART OF CURRENT M3 V1 CONTRACT
~~~

Tenant-sensitive authority must also consider valid/active company state.

## 5. Tenant role source of truth

~~~text
CANONICAL TENANT ROLE SOURCE =
corretores.role
~~~

Canonical tenant roles:

~~~text
admin_local
gestor
corretor
~~~

Legacy compatibility fields:

~~~text
is_admin_local
is_gestor

=
LEGACY / DERIVED COMPATIBILITY
NOT INDEPENDENT AUTHORITY SOURCES
~~~

They are not removed by this decision. Retirement requires caller migration, equivalence, observability, rollback and proof that authority no longer depends on them.

## 6. Canonical platform root

~~~text
CANONICAL PLATFORM ROOT SOURCE =
public.admins
~~~

Target contract:

~~~text
auth.uid()
→ public.admins.user_id
→ admins.ativo = TRUE
→ admins.role = 'admin_global'
→ PLATFORM ROOT
~~~

Control-plane separation:

~~~text
ROOT / ADMIN_GLOBAL = PLATFORM CONTROL PLANE
ADMIN_LOCAL = TENANT CONTROL PLANE
GESTOR = TEAM CONTROL PLANE
CORRETOR = INDIVIDUAL BUSINESS PLANE

ROOT != ADMIN_LOCAL
ROOT != GESTOR
ROOT != CORRETOR
~~~

## 7. Legacy root authority

The accepted AS-IS evidence proves a dual source:

~~~text
public.admins
OR
corretores.role='admin_global'
~~~

Accepted live evidence from the bounded STS-M3-01 analysis:

~~~text
active public.admins rows = 1
active corretores.role='admin_global' rows = 2
identity represented in both sources = 1
root represented only by public.admins = 0
root represented only by corretores.role='admin_global' = 1
~~~

Target disposition:

~~~text
corretores.role='admin_global'
=
LEGACY / TRANSITIONAL ROOT AUTHORITY
TO BE MIGRATED / RETIRED LATER

IMMEDIATE LEGACY REMOVAL =
NOT AUTHORIZED
~~~

## 8. Root versus tenant business authority

~~~text
PLATFORM ROOT
!=
AUTOMATIC TENANT BUSINESS AUTHORITY
~~~

Root does not implicitly inherit ordinary admin_local, gestor or corretor authority.

Exceptional tenant support access must later use an explicit, auditable support context, including when applicable:

~~~text
target empresa
reason
authorization source
start
expiry/end
audit trail
explicit exit
~~~

The operational support-mode contract belongs to STS-M3-02.

## 9. Team model

~~~text
TEAM ENTITY =
public.times

TEAM MEMBERSHIP =
corretores.time_id

TEAM MANAGER RESPONSIBILITY =
times.gestor_id
~~~

Accepted invariants:

~~~text
corretor.empresa_id = time.empresa_id
gestor.empresa_id = time.empresa_id
gestor.role = 'gestor'
gestor active where operational authority depends on it
team active where operational authority depends on it
one active gestor → maximum one active team
one corretor → zero or one team
team movement → same empresa only
~~~

Admin Local manages tenant organizational structure but is not automatically the operational gestor of a team.

Accepted live residual:

~~~text
ONE ACTIVE TEAM WITH
ADMIN_LOCAL-AS-GESTOR LEGACY RELATION =
PROVEN LIVE
~~~

No automatic data correction is authorized by this publication.

## 10. Server-side authority chain

Tenant-sensitive operation target:

~~~text
auth.uid()
→ exactly one active corretores identity
→ valid active empresa
→ canonical tenant role
→ valid same-empresa team relation where required
→ authoritative object relation
→ ownership/responsibility where required
→ operation-specific permission
→ ALLOW
~~~

Any material ambiguity or failed invariant must fail closed.

Platform operation target:

~~~text
auth.uid()
→ active public.admins
→ role='admin_global'
→ platform operation specifically authorized
→ ALLOW
~~~

Platform root must not impersonate tenant roles as an authorization shortcut.

## 11. criar-usuario evidence and downstream gap

Accepted parity evidence:

~~~text
supabase/functions/criar-usuario/index.ts

GitHub blob =
866257371dcc85d22ae54cae3593b3e49a132d8e

Live Edge =
criar-usuario version 19

GitHub content length =
19012

Live content length =
19012

exact string equality =
TRUE
~~~

Current user creation derives root/admin/gestor authority in a way that does not fully implement the frozen M3-01 target.

~~~text
CRIA-USUARIO AUTHORITY DERIVATION
DIFFERS FROM M3-01 TARGET =
PROVEN

classification =
PLANNED DOWNSTREAM REMEDIATION

primary owner =
STS-M3-05
~~~

No Edge Function change is authorized by this publication.

## 12. Preserved residuals

~~~text
current implementation target-compliant =
NOT_PROVEN

implementation remediation =
NOT_PERFORMED

lifecycle remediation =
NOT_PERFORMED

exhaustive direct-DML/application callsite proof =
NOT_ESTABLISHED

hostile-client / cross-tenant assurance =
NOT_PROVEN

AppSec PASS =
NOT_PERFORMED

Security Go =
NOT_GRANTED
~~~

Material M3-01 findings retained for downstream work:

~~~text
ROOT DUAL AUTHORITY SOURCE =
PROVEN LIVE

ONE ACTIVE TEAM WITH
ADMIN_LOCAL-AS-GESTOR LEGACY RELATION =
PROVEN LIVE

CRIA-USUARIO AUTHORITY DERIVATION
DIFFERS FROM M3-01 TARGET =
PROVEN
~~~

These are not converted into implementation work by this artifact.

## 13. Downstream routing

~~~text
STS-M3-02 =
Authority contract by context

STS-M3-03 =
Privileged RPC allowlist

STS-M3-04 =
Sensitive direct-DML reduction

STS-M3-05 =
Auth/Admin flows

STS-M3-06 =
Staging / security test plan
~~~

M3-02 consumes the frozen identity, membership, role, team, root/platform and active-state model.

M3-05 owns Auth/application lifecycle, create-user/deprovisioning/admin flows and the observed criar-usuario authority gap.

M3-06 owns negative tenant/role/team/ownership/inactive/partial-identity/root-legacy/hostile-client proof in an explicitly authorized isolated environment.

## 14. Program continuation

~~~text
STS-M3 =
ACTIVE

STS-M3-01 =
COMPLETE / ACCEPTED

STS-M3-02 =
NEXT_ELIGIBLE / NOT_AUTHORIZED
~~~

No STS-M3-02 execution authority is implied.

## 15. Implementation and lifecycle strategy

Preserve the accepted M2 architecture:

~~~text
V2_STRANGLER / SAME_DATABASE_FIRST
~~~

Authority migration should be incremental:

~~~text
introduce canonical resolver
→ migrate bounded callers
→ observe/equivalence
→ migrate remaining callers
→ prove zero legacy dependency
→ retire legacy authority
~~~

One PR should continue to represent one principal risk with a simple rollback.

## 16. Non-authorizations

This decision/publication does not authorize:

~~~text
runtime/frontend/App.jsx mutation
Supabase/Auth/data mutation
DDL / DML
migration execution
RLS / policy / grant / owner / search_path mutation
RPC/function/trigger mutation
Edge Function mutation
Vercel / GitHub Actions mutation
production mutation
SES mutation
sfjm-workspace mutation
STS-M3-02 execution
Ready
merge
deploy
Security Go
commercialization authorization
~~~

Rollback for this publication is a simple documentation revert.

## 17. Invalidation

Revalidate proportionally if any material authority source, identity schema, role model, team relationship, root/admin model, Auth/Admin flow, accepted Product Authority rule, runtime evidence or canonical source changes.

Absent a material invalidator, do not reopen STS-M2 or replay STS-M3-01 from zero.
