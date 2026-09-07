# FECH.AI — STS-M2-06 — Database Architecture Decision — Product Authority Accepted

**Status:** `COMPLETE / ACCEPTED / DURABLE_DECISION_ARTIFACT`  
**Product Authority:** Wagner / FECH.AI  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Analysis base main:** `f22b83bb7acec8692e0575185a88ca2755183b41`  
**Authorization publication merge:** PR #197 / `0cb993a1eb86433975429da4a07a13fd3f373e16`  
**Acceptance publication base main:** `83186f5775e563e150329fa0b95dd1d7f3f3a516`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`

## 1. Product Authority decision

~~~text
STS-M2-06 =
COMPLETE / ACCEPTED

DATABASE ARCHITECTURE STRATEGY =
V2_STRANGLER / SAME_DATABASE_FIRST
~~~

Canonical interpretation:

~~~text
STRATEGY =
V2_STRANGLER

INITIAL PHYSICAL PERSISTENCE =
CURRENT SUPABASE / POSTGRESQL DATABASE

IMPLEMENTATION MODEL =
VERSIONED BOUNDED-CONTEXT CONTRACTS
+ FEATURE-SPECIFIC GATEWAYS
+ SERVER-SIDE AUTHORITY
+ INCREMENTAL CONSUMER CUTOVER
+ EXPLICIT LEGACY RETIREMENT

NEW PRODUCTION DATABASE =
NOT SELECTED AT THIS STAGE
~~~

Preserve:

~~~text
V2_STRANGLER != SECOND DATABASE NOW
V2_STRANGLER != BIG-BANG REWRITE
V2_STRANGLER != MICROSERVICES REQUIREMENT
SAME_DATABASE_FIRST != PURE UNBOUNDED EVOLVE_IN_PLACE
~~~

## 2. Decision space

The authoritative STS-M2-06 decision compared:

~~~text
EVOLVE_IN_PLACE
vs
V2_STRANGLER
vs
NEW_DATABASE
~~~

Final disposition:

~~~text
EVOLVE_IN_PLACE =
VIABLE
BUT NOT SELECTED AS PROGRAM-LEVEL STRATEGY

V2_STRANGLER / SAME_DATABASE_FIRST =
SELECTED

NEW_DATABASE =
REJECTED FOR CURRENT M2 TARGET
DUE TO INSUFFICIENT EVIDENCE OF PHYSICAL NEED
+ HIGHER SEMANTIC MIGRATION BLAST RADIUS
~~~

A future separate database is not permanently prohibited. It requires a new evidence-backed architecture gate.

## 3. Accepted AS-IS characterization

Decision-grade facts accepted from the bounded M2-06 READ_ONLY analysis:

~~~text
public tables = 44
RLS enabled = 44 / 44

accepted bounded contexts = 10

M2-05 dispositions:
KEEP = 40
INTERNAL = 4
CONSOLIDATE = 0
RETIRE = 0
REMODEL = 0

public routines = 160
current SECURITY DEFINER routines = 137
non-DEFINER routines = 23
non-internal trigger instances = 31

live applied migration ledger observed during M2-06 =
149 migrations

physical database scale problem =
NOT PROVEN
~~~

Current architecture problem was characterized primarily as:

~~~text
authority complexity
+ security-boundary complexity
+ legacy/compatibility complexity
+ application/database coupling
~~~

not as an evidenced physical database capacity problem.

## 4. Decision drivers

The selected strategy optimizes for:

~~~text
tenant/security correctness
incremental reversibility
reuse of accepted M2-01..M2-05 contracts
bounded consumer/callsite migration
explicit legacy retirement
proofability
low blast radius
compatibility with STS-M3 and STS-M4 sequencing
~~~

Physical storage scale was not a material evidenced driver for database replacement.

## 5. Three-option trade-off summary

| Dimension | EVOLVE_IN_PLACE | V2_STRANGLER | NEW_DATABASE |
|---|---|---|---|
| Existing contract compatibility | HIGH | HIGH | LOW/MED |
| Migration complexity | LOW | MED | HIGH |
| Blast radius | MED | LOW per slice | HIGH |
| Rollback | MED/HIGH | HIGH per slice | LOW/MED after cutover |
| Explicit legacy retirement | MED | HIGH | HIGH but disruptive |
| Tenant/authority hardening boundary | MED | HIGH | HIGH but must be rebuilt |
| Fit with STS-M3/M4 | MED | VERY HIGH | LOW |
| Need for physical data migration | NONE | NONE initially | YES |
| Evidence of current physical need | N/A | N/A | NOT PROVEN |

## 6. Target principles

~~~text
1. One bounded context / migration slice at a time.

2. Existing Supabase/PostgreSQL remains the initial physical system of record.

3. V2 contracts derive or verify actor, empresa/tenant, role, team,
   ownership and authoritative object relation server-side.

4. Frontend remains request/display boundary, not business authority.

5. One authoritative writer is preferred.

6. Dual-write/shadow state is exceptional and temporary.

7. Legacy retirement requires caller migration, equivalence evidence,
   observability and rollback.

8. There is no blanket rule that all writes must become RPC.

9. Preserve the accepted direct-DML vs RPC-only target contract.

10. A future physical database split requires material evidence such as
    independent scaling, regulatory isolation, workload contention,
    failure-domain requirements or another explicit driver.
~~~

## 7. Existing shadow migration constraint

Preserve the current MesaCliente compatibility pair:

~~~text
public.mesa_fluxo_pagamentos
+
public.mesa_fluxo_pagamentos_canonico
~~~

Current accepted state:

~~~text
CANONICAL SHADOW
DUAL-WRITE / COMPATIBILITY STATE
NOT CANONICAL READ AUTHORITY YET
~~~

Before proliferating further shadow/dual-write patterns, this path must eventually resolve:

~~~text
authoritative writer
backfill/equivalence
read cutover
consumer compatibility
reconciliation
rollback
legacy disposition
~~~

This decision does not execute that work.

## 8. Migration and rollback model

Preferred migration shape:

~~~text
BASELINE
→ CHARACTERIZATION
→ V2 CONTRACT BOUNDARY
→ READ CUTOVER
→ EQUIVALENCE / OBSERVATION
→ WRITE CUTOVER WHEN REQUIRED
→ LEGACY CALLER RETIREMENT
→ LEGACY CONTRACT RETIREMENT
~~~

Default rule:

~~~text
ONE AUTHORITATIVE WRITER PREFERRED
~~~

Rollback before legacy retirement should remain bounded to the affected context/consumer route rather than requiring whole-database reversal.

Stop conditions include:

~~~text
tenant mismatch
cross-tenant authorization anomaly
equivalence failure
unknown material legacy caller
unexpected duplicate mutation
insufficient observability
rollback cannot be demonstrated
blocking AppSec finding
material ref/runtime drift
~~~

## 9. Multi-tenancy and trust boundary

V2 contracts must preserve the project invariant:

~~~text
auth.uid()
→ active profile
→ authoritative empresa
→ role / team / ownership
→ authoritative object relation
→ allowed operation
~~~

Client-supplied tenant/company/role/ownership identifiers are not authority by themselves.

## 10. Proof obligations before implementation/retirement

~~~text
M3 identity/membership/team/role authority freeze
exhaustive sensitive callsite inventory where required
tenant/resulting-row relationship proof
contract/equivalence tests
negative tenant/role/ownership tests in an authorized isolated environment
runtime concurrency/idempotency proof where material
legacy/v2 observability
rollback proof
AppSec review
legacy caller zero-use evidence before retirement
~~~

## 11. Preserved residuals

~~~text
current implementation target-compliant =
NOT_PROVEN

implementation remediation =
NOT_PERFORMED

lifecycle remediation =
NOT_PERFORMED

exhaustive application direct-DML callsite proof =
NOT_ESTABLISHED

lista_avaliacoes resulting-row relationship integrity =
NOT INDEPENDENTLY PROVEN

leads resulting-row empresa relationship =
NOT INDEPENDENTLY PROVEN

times resulting-row empresa relationship =
NOT FULLY PROVEN

hostile-client / cross-tenant runtime assurance =
NOT_PROVEN

AppSec PASS =
NOT_PERFORMED

live assistente-ai Edge Function
vs versioned repository source parity =
NOT_ESTABLISHED

Security Go =
NOT_GRANTED
~~~

These residuals do not reopen the accepted architecture decision absent a material invalidator.

## 12. STS-M2 closure

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

Preserve:

~~~text
STS-M2 COMPLETE != DATABASE REMEDIATION COMPLETE
STS-M2 COMPLETE != V2 IMPLEMENTED
STS-M2 COMPLETE != STS-M3 STARTED
STS-M2 COMPLETE != APPSEC PASS
STS-M2 COMPLETE != SECURITY GO
~~~

## 13. Continuation boundary

~~~text
STS-M3 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

STS-M3-01 =
Identity / membership / team / role model
24h
NEXT_ELIGIBLE / NOT_AUTHORIZED
~~~

STS-M3 requires separate Product Authority authorization after the STS-M2 acceptance publication completes its own documentation lifecycle.

## 14. Non-authorizations

This decision does not authorize:

~~~text
runtime/frontend implementation
V2 runtime gateways
Supabase/Auth/data mutation
DDL / DML
migration execution
RLS / policy / grant / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
database cloning
new Supabase project
new production database
data backfill
dual-write implementation
STS-M3 execution
deploy
Security Go
commercialization authorization
~~~

Rollback for this publication is a simple revert of the documentation commit/PR.
