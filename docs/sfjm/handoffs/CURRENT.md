# FECH.AI — SFJM Current Product/Security Handoff


## 0.0000000000000000018 CURRENT HANDOFF — B2 HIGH-RISK TARGET-CONTRACT CLOSURE RESULT READY FOR PRODUCT AUTHORITY — 2026-09-07

~~~text
repository = wagnerjfjunior/fecha.ai
execution-base main = dd118baa89b68281bbd7c8df43c8e24c0e9b66bf
environment = Pilot Production / multi-tenant / multiempresa
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
Security Go = NOT_GRANTED
~~~

Authorized bounded work has been executed READ_ONLY.

~~~text
STS-M2-04 B2 HIGH-RISK TARGET-CONTRACT CLOSURE =
EXECUTED / RESULT READY FOR PRODUCT AUTHORITY ADJUDICATION

exact scope = 15 B2 routines
live fingerprint = 33aea33ec2039d91f417b3980ea8cf43
Supabase mutation = NONE
~~~

Candidate target projection:

~~~text
6 ACTIVE TARGET DEFINER
5 DEFINER_IF_RETAINED / DORMANT_NO_CLIENT_EXECUTE
2 TARGET INVOKER
2 NON_MODE_LIFECYCLE candidates
15 total
~~~

Key lifecycle candidates requiring Product Authority adjudication:

~~~text
redefinir_senha_corretor
-> RETIRE_LEGACY_SQL_RPC after dependency check

registrar_audit_log
-> RETIRE_OR_REPLACE_WITH_TRUSTED_INTERNAL_AUDIT_HELPER after dependency check
~~~

Callerless routines 4/5/7/12/13 are not declared unused. Their candidate target is fail-closed: no client EXECUTE until canonical caller/product semantics are proven.

Next receiver/action:

~~~text
PRODUCT AUTHORITY ADJUDICATION

accept the bounded result
OR
request one named delta

then, if accepted:
adjudicate final STS-M2-04 closure before any M2-05 authorization
~~~

No implementation, function/grant/RLS/owner/search_path mutation, lifecycle retirement, hostile testing, deploy, M2-05, M2-06 or Security Go is inherited from this handoff.

Do not create another SFJM-only reconciliation merely because the publication carrying this handoff later advances through Draft/Ready/merge lifecycle.

## 0.0000000000000000017 CURRENT HANDOFF — PR #189 merged; corrected E contract on main; next bounded M2-04 action unselected — 2026-09-07

~~~text
repository = wagnerjfjunior/fecha.ai
canonical main = 13eec5a6b720d67ed29a1837a01502123547ccb6
PR #189 = MERGED / CLOSED
merged head = b7baa29dbbfeeaee78e423f7950ba17390fac0e2
merge commit = 13eec5a6b720d67ed29a1837a01502123547ccb6
environment = Pilot Production / multi-tenant / multiempresa
Security Go = NOT_GRANTED
~~~

Canonical corrected E continuity now on main:

~~~text
STS-M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

FIVE-RESIDUAL E AUTHORITY ADJUDICATION = COMPLETE

historical C3 =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113 B3/C3 routines

B3/C3 subset projection after E =
70 DEFINER
41 INVOKER
0 semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 B3/C3 routines

B2 = separate accepted 15-routine slice with residuals
D = separate accepted 9-trigger-routine target classification
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED
~~~

Material corrected decisions remain:

~~~text
031 -> DEFINER
  ADMIN_LOCAL = tenant/company lifecycle authority
  GESTOR = tenant + managed-team lifecycle authority
  ROOT / ADMIN_GLOBAL != automatic tenant lifecycle authority

036 -> NON_MODE_LIFECYCLE / RETIRE_CURRENT_SEMANTICS
  future replacement = NOT DEFINED BY E
  future replacement = NOT AUTHORIZED

119 -> target INVOKER already resolved in C3
  current implementation remains postgres-owned SECURITY DEFINER
  implementation/runtime remediation remains open
~~~

Still open:

~~~text
004 implementation/security remediation
031 implementation/caller-ACL remediation
036 current-semantics retirement implementation
047 global-body/RLS remediation
119 current DEFINER -> target INVOKER remediation/runtime assurance
127 retirement/deprecation implementation
AppSec assurance
hostile/cross-tenant runtime assurance
Security Go
~~~

Next handoff:

~~~text
PRODUCT AUTHORITY SELECT / DEFINE
NEXT BOUNDED STS-M2-04 ACTION

next bounded STS-M2-04 action = NOT_SELECTED
M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
M2-05 = NOT_AUTHORIZED
M2-06 = NOT_AUTHORIZED
~~~

Do not create a follow-up SFJM-only reconciliation merely because this documentation reconciliation itself later changes Draft/Ready/merge state. Require a new material event.

## 0.0000000000000000016 HISTORICAL / SUPERSEDED HANDOFF — PRE-MERGE PR #189 corrected E contract; fresh exact-head review next — 2026-09-07

~~~text
repository = wagnerjfjunior/fecha.ai
branch = docs/sts-m2-04e-architecture-acceptance
pre-correction parent head = 8f660bfcc753bb0f8012a823d5942e4528f441bb
corrected head = RESOLVE LIVE
main at correction admission = aa266df3124f407a3f2c155c8f8ab5c193707783
environment = Pilot Production / multi-tenant / multiempresa
Security Go = NOT_GRANTED
~~~

Corrected E continuity:

~~~text
STS-M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

FIVE-RESIDUAL E AUTHORITY ADJUDICATION = COMPLETE

historical C3 =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113 B3/C3 routines

B3/C3 subset projection after E =
70 DEFINER
41 INVOKER
0 semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 B3/C3 routines

B2 = separate accepted 15-routine slice with residuals
D = separate accepted 9-trigger-routine target classification
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED
~~~

Material corrected decisions:

~~~text
031 -> DEFINER
  ADMIN_LOCAL = tenant/company lifecycle authority
  GESTOR = tenant + managed-team lifecycle authority
  ROOT / ADMIN_GLOBAL != automatic tenant lifecycle authority

036 -> NON_MODE_LIFECYCLE / RETIRE_CURRENT_SEMANTICS
  future replacement = NOT DEFINED BY E
  future replacement = NOT AUTHORIZED BY PR #189

119 -> target INVOKER already resolved in C3
  current implementation remains postgres-owned SECURITY DEFINER
  implementation/runtime remediation remains blocked
~~~

Immediate next gate:

~~~text
INDEPENDENT FRESH EXACT-HEAD REVIEW
OF THE CORRECTED PR #189 HEAD

PR #189 = OPEN
merge = NOT_AUTHORIZED
deploy = NOT_AUTHORIZED
~~~

After that lifecycle gate, the program-level semantic continuation remains Product Authority selection/definition of the next bounded M2-04 action. Do not infer M2-04F or any runtime implementation.

## 0.0000000000000000015 HISTORICAL / SUPERSEDED — PRE-CORRECTION E HANDOFF WORDING — 2026-09-06

~~~text
repository = wagnerjfjunior/fecha.ai
E acceptance base main = aa266df3124f407a3f2c155c8f8ab5c193707783
CURRENT FECH.AI main = RESOLVE LIVE
SES evidence base = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
environment = Pilot Production / multi-tenant / multiempresa
Security Go = NOT_GRANTED
~~~

Preserve:

~~~text
M2-04C historical projection =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113

M2-04D =
COMPLETE / ACCEPTED
8 DEFINER / 1 INVOKER / 0 NOT_DETERMINED
9 functions / 18 trigger instances

M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

E target =
70 DEFINER
41 INVOKER
0 semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 inventoried routines
~~~

Durable E evidence:

~~~text
docs/security/evidence/2026-09-06-sts-m2-04e-architecture-synthesis-acceptance.md
Git blob = 6f6a9bd1f181dfcf34ab979284338e497fb09f61
~~~

Five E dispositions:

~~~text
004 -> DEFINER / implementation-security residual
031 -> DEFINER / implementation-caller-ACL residual
036 -> NON_MODE_LIFECYCLE / RETIRE_OR_REPLACE_CURRENT_SEMANTICS
047 -> INVOKER / tenant-team scoped / current global-body-RLS residual
127 -> NON_MODE_LIFECYCLE / RETIRE_DEPRECATE / SELF-ONLY lot request
~~~

Receiving sessions must not ask Product Authority to re-decide the product semantics of these five absent material contradictory evidence.

Issue #133 remains binding: root/admin_global is platform control plane and does not inherit ordinary tenant/team commercial authority.

Next handoff:

~~~text
PRODUCT AUTHORITY SELECT / DEFINE
NEXT BOUNDED STS-M2-04 ACTION

M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
M2-05 = NOT_AUTHORIZED
M2-06 = NOT_AUTHORIZED
~~~

No implementation, Supabase/Auth mutation, SQL/DDL/DML, function/grant/RLS/policy change, lifecycle retirement, hostile runtime testing, Ready, merge, deploy or Security Go is carried by this handoff.

## 0.0000000000000000014 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04D complete / accepted; M2-04E not authorized — 2026-09-06

~~~text
repository = wagnerjfjunior/fecha.ai
M2-04D decision/evidence base = e380387fe341dcf42527ce70ded45fd894447aa5
CURRENT FECH.AI main = RESOLVE LIVE
SES evidence base = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment = Pilot Production / multi-tenant / multiempresa
Security Go = NOT_GRANTED
~~~

Preserve:

~~~text
M2-04C = CLOSED / PRESERVE
M2-04C projection = 68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113

M2-04D =
COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT

D FUNCTIONS = 9
D TRIGGER INSTANCES = 18

TARGET =
8 DEFINER
1 INVOKER
0 NOT_DETERMINED

DIRECT CLIENT EXECUTE =
0 required
9 not required
0 NOT_DETERMINED
~~~

Durable evidence:

~~~text
docs/security/evidence/2026-09-06-sts-m2-04d-trigger-authority-classification.md
Git blob = 7fdc63a95d81661598937aa0bdfa654bcb9db66a
source packet SHA-256 =
6927b61338555fef95cc25892bb6097e815839b53bc217e0229084c5e5220389
~~~

Future backlog only:

~~~text
D-01 111 DEFINER -> INVOKER
D-02 remove direct EXECUTE 011–015
D-03 remove service_role direct EXECUTE 030
D-04 remove anon/auth/service direct EXECUTE 075
D-05 optional search_path hardening
D-06 audit runtime assurance
D-07 030/075 hostile/cross-tenant assurance
D-08 130 concurrency assurance
~~~

Next candidate:

~~~text
STS-M2-04E — architecture synthesis
STATUS = NOT_AUTHORIZED
M2-04F = NOT_AUTHORIZED
~~~

No implementation, Supabase/Auth mutation, trigger/function/grant/RLS/policy change, hostile runtime testing, Ready, merge, deploy or Security Go is carried by this handoff.

## 0.0000000000000000013 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04C complete / accepted with bounded authority residuals — 2026-09-06

```text
repository = wagnerjfjunior/fecha.ai
M2-04C decision/evidence base = ca30c70e505a9dd8398cd7dace067c95397f96fe
CURRENT FECH.AI main = RESOLVE LIVE
SES evidence base = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment = Pilot Production / multi-tenant / multiempresa
Security Go = NOT_GRANTED
```

M2-04C final state:

```text
C1 = COMPLETE
C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
C3 = COMPLETE WITH RESIDUAL NOT_DETERMINED / ACCEPTED
C4 = COMPLETE / ACCEPTED

STS-M2-04C =
COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS
```

Durable C3 per-routine evidence:

```text
docs/security/evidence/2026-09-06-sts-m2-04c-c3-routine-mode-adjudication.csv
rows = 57
content SHA-256 = cdc028d5874d4e7f2c783e9380def40373ed525fec89514f1becd073f36027ab
Git blob = 716c23d5f549eb465f3393cdfc5989dda82b69a7
```

Receiving sessions must resolve current FECH.AI `main` live before lifecycle or implementation decisions; the SHA above is an M2-04C evidence base, not a perpetual current-main assertion.

Target projection:

```text
68 DEFINER
40 INVOKER
5 NOT_DETERMINED
113 total
```

Five bounded residual authority cases:

```text
004 aprovar_rejeitar_mesa(uuid,text,text)
031 gerenciar_lista(uuid,text,text)
036 get_dashboard_master()
047 get_stats_horario()
127 solicitar_lote_forcado(uuid)
```

119 `relatorio_fornecedor(uuid)` is resolved at target-authority level as INVOKER; live implementation remains SECURITY DEFINER and no runtime assurance is implied.

Do not replay C1/C2/C3/C4 absent material contradictory evidence.

Next program handoff requires Product Authority selection/authorization of the next bounded M2-04 slice. The natural sequential candidate is `STS-M2-04D` trigger provenance/classification. M2-04D/E/F remain NOT_AUTHORIZED.

No implementation, Supabase/Auth mutation, SQL/DDL/DML, policy/RLS/grant/function change, hostile runtime testing, Ready, merge, deploy or Security Go is carried by this handoff.

All lower-numbered handoff sections below are historical/superseded.


## 0.0000000000000000012 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04C/C3 accepted / C4 ready for bounded execution — 2026-09-06

```text
repository = wagnerjfjunior/fecha.ai
FECH.AI main = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment = Pilot Production / multi-tenant / multiempresa
Product Authority = M2-04C READ_ONLY EXECUTION AUTHORIZED
Security Go = NOT_GRANTED
```

Current decomposition:

```text
C1 = COMPLETE
C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
C3 = COMPLETE WITH RESIDUAL NOT_DETERMINED / ACCEPTED
C4 = NEXT / AUTHORIZED READ_ONLY
```

C3 result:

```text
57 / 57 rows adjudicated
16 target DEFINER
36 target INVOKER
5 remain NOT_DETERMINED

projected full B3 target distribution:
68 DEFINER
40 INVOKER
5 NOT_DETERMINED
113 total
```

Remaining authority blockers: `004`, `031`, `036`, `047`, `127`.

Blocker `119 relatorio_fornecedor(uuid)` is resolved at target-mode authority level as INVOKER. Current live implementation remains unchanged and still DEFINER; no runtime safety claim follows from the target decision.

C4 must consolidate the target RLS/direct-DML contract, residuals and handoff without forcing the five unresolved authority decisions.

No implementation, Supabase/Auth mutation, SQL/DDL/DML, policy/RLS/grant/function change, hostile runtime testing, M2-04D/E/F, Ready, merge, deploy or Security Go is carried by this handoff.

All lower-numbered handoff sections below are historical/superseded.


## 0.0000000000000000011 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04C/C2 accepted / C3 ready for bounded execution — 2026-09-06

```text
repository = wagnerjfjunior/fecha.ai
FECH.AI main = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment = Pilot Production / multi-tenant / multiempresa
Product Authority = M2-04C READ_ONLY EXECUTION AUTHORIZED
Security Go = NOT_GRANTED
```

Current decomposition:

```text
C1 = COMPLETE
C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
C3 = NEXT / AUTHORIZED READ_ONLY
C4 = PENDING
```

C2 specialist packet SHA-256:
`ccf108437f1d84ceac29095ecb1f86a3a63c64d5278d8eb17c02588d3a633afa`

Master Project independently revalidated the material live premises and accepted C2 for bounded C3. Preserve the residual gap around a fresh exhaustive application direct-DML callsite sweep.

C3 scope = exactly 57 previously unresolved B3 routine modes. Do not reopen B3 outside those 57 and do not replay C1/C2 absent material contradiction.

```text
004 DOES NOT RESOLVE
031 PARTIALLY RESOLVES
036 PARTIALLY RESOLVES
047 PARTIALLY RESOLVES
119 PARTIALLY RESOLVES
127 DOES NOT RESOLVE
```

No implementation, Supabase/Auth mutation, SQL/DDL/DML, policy/RLS/grant/function change, hostile runtime testing, M2-04D/E/F, Ready, merge, deploy or Security Go is carried by this handoff.

All lower-numbered handoff sections below are historical/superseded.


## 0.0000000000000000010 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04C started / C1 complete / C2 ready for specialist execution — 2026-09-06

```text
repository = wagnerjfjunior/fecha.ai
M2-04C start anchor = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES anchor observed = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment = Pilot Production / multi-tenant / multiempresa
Product Authority = M2-04C READ_ONLY EXECUTION AUTHORIZED
Security Go = NOT_GRANTED
```

Current internal decomposition:

```text
C1 live RLS/FORCE/ACL/policy inventory = COMPLETE
C2 policy-helper graph + USING/WITH CHECK + direct-DML authority = NEXT
C3 57-routine mode adjudication = PENDING
C4 target RLS/direct-DML contract consolidation = PENDING
```

C1 key observations:

```text
44 / 44 public tables RLS enabled
30 / 44 FORCE RLS
14 / 44 FORCE RLS false
0 tables with anon direct privilege
28 tables with authenticated SELECT
9 tables with authenticated direct write privilege
57 B3 routines remain TARGET_SECURITY_MODE NOT_DETERMINED
postgres.rolbypassrls = true
central policy helpers = SECURITY DEFINER / owner postgres as observed
```

Preserve B3 acceptance and blockers `004,031,036,047,119,127`; do not replay DEF55 absent material contradictory evidence.

Next handoff target: SES — Backend & Data Platform Specialist for C2. Return the complete C2 result to the FECH.AI Master Project for adjudication before C3.

No implementation, Supabase/Auth mutation, SQL/DDL/DML, policy/RLS/grant/function change, hostile runtime testing, M2-04D/E/F, Ready, merge, deploy or Security Go is carried by this handoff.

All lower-numbered handoff sections below are historical/superseded and do not override this current handoff.


## 0.0000000000000000009 HISTORICAL HANDOFF — PR #183 merged state ratified / provenance exception recorded — SUPERSEDED BY M2-04C HANDOFF — 2026-09-06

```text
repository = wagnerjfjunior/fecha.ai
accepted main = 53a70f814e8b695439358ebe609850f25bf636a9
PR #183 = CLOSED / MERGED
PR #183 final head = d805194c5f896766af24e4d4a56869c91d31a60c
Product Authority = RATIFIED MERGED STATE
exception = AUTHORITY/LIFECYCLE PROVENANCE EXCEPTION
historical exact-head merge authority = NOT_RECOVERED
revert = NOT_REQUIRED
```

Preserve the completed B3 state without replay:

```text
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
coverage = 113 / 113
target mode = 52 DEFINER / 4 INVOKER / 57 NOT_DETERMINED
blockers = 004,031,036,047,119,127
Security Go = NOT_GRANTED
```

The ratification corrects current authority meaning without rewriting history. It does not create standing merge authority and does not authorize M2-04C, M2-04D, implementation, Supabase/Auth mutation, active AppSec/runtime testing, deploy or Security Go.

Next handoff after bounded provenance reconciliation: Product Authority selection/authorization of the next bounded STS-M2-04 slice. Do not reconstruct or re-audit B3 absent material contradictory evidence.


## 0.0000000000000000008 HISTORICAL HANDOFF — STS-M2-04B3 / DEF55 revised acceptance / six authority blockers preserved — SUPERSEDED — 2026-09-05

This handoff becomes canonical after PR #183 merge. Resolve the live PR head before every lifecycle gate.

```text
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
coverage = 113 / 113
target mode = 52 DEFINER / 4 INVOKER / 57 NOT_DETERMINED
justification = 52 PROVEN_BY_BODY_CONTRACT / 6 NOT_PROVEN / 51 NOT_DETERMINED / 4 NOT_REQUIRED
blockers = 004,031,036,047,119,127
Security Go = NOT_GRANTED
```

Canonical revised CSV SHA-256: `e609f4fa3bc6d21b8c75d85bd2a4a3409e9ece8b3c4d66ffdb5e52055052a61d`.

Key delta: 52 DEFINER rows now carry routine-specific elevation reasons; `004` is NOT_DETERMINED/BLOCKING; `052` and `106` target INVOKER; `126` is TRANSITIVE_MUTATIVE with runtime assurance required; live identity signatures corrected for `021`, `022`, `028`, `032`.

PR #183 is authorized only through exact-head review, Ready revalidation and pre-merge. Merge/deploy/Supabase/M2-04C/M2-04D/AppSec-active execution remain unauthorized.

## 0.0000000000000000007 HISTORICAL — ORIGINAL STS-M2-04B3 HANDOFF / SUPERSEDED BY 0.0000000000000000008 — 2026-09-05

This handoff becomes current material continuity only after the B3 acceptance reconciliation is merged to canonical `main`.

Canonical durable B3 evidence after merge:

`docs/security/evidence/2026-09-05-sts-m2-04b3-remaining-routine-authority-classification.md`

State to preserve:

```text
STS-M2-04B1 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
B3 coverage = 113 / 113
target mode = 55 DEFINER / 2 INVOKER / 56 NOT_DETERMINED
Security Go = NOT_GRANTED
```

Five current authority findings remain `BLOCKING`: `031`, `036`, `047`, `119`, `127`. They are blockers in the current authority design, not evidence that B3 classification is incomplete.

M2-04C is the strongest next dependency because 56 B3 mode decisions remain unresolved pending RLS/direct-authority composition. M2-04D remains required for the 9 SECURITY DEFINER trigger-provenance routines outside B3.

No next slice, remediation, AppSec execution, Supabase mutation, Ready, merge, deploy or Security Go authority is carried by this handoff.

## 0.0000000000000000006 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04B2 accepted with residuals / next bounded-slice decision — 2026-09-05

This handoff becomes current material continuity only when the B2 reconciliation is merged to canonical `main`.

Canonical durable B2 evidence:

`docs/security/evidence/2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md`

State to preserve:

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

B2 classified exactly 15 high-risk routines. Preserve: `0/8` anonymous-command exceptions proven; `acquire_lote_lock` internal-helper contradiction; `avaliar_lista(3)` / `trilha_lead` caller×ACL contradictions without implied GRANT authority; no-versioned-caller/unused-candidate uncertainty; unresolved DEFINER justification where indicated; conditional owner posture; `search_path` target compliance not determined; runtime/AppSec assurance gaps.

The B1 durable reconciliation was merged via PR #181 and is canonical on main `0b4868ef80e69bab5f0397c29af4474fb097e739`. This B2 PR preserves that canonical B1 state and does not rewrite B1.

Next program decision:

```text
SELECT NEXT BOUNDED STS-M2-04 TARGET-POLICY SLICE
```

Candidate slices are B3, M2-04C and M2-04D, but none is authorized or started by this handoff. No technical remediation, Supabase/Auth mutation, runtime testing, AppSec testing, deploy or Security Go authority is carried forward.

## 0.0000000000000000005 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-04B1 accepted / B2 scope preparation next — 2026-09-05

Canonical durable B1 evidence once this reconciliation is merged:

`docs/security/evidence/2026-09-05-sts-m2-04b1-routine-authority-policy.md`

State to preserve:

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

B1 target contract to preserve:

```text
SECURITY DEFINER = PRIVILEGED EXCEPTION
SECURITY INVOKER = PREFERRED DEFAULT WHEN CALLER AUTHORITY IS DELIBERATELY SUFFICIENT
routine authority = caller + class + EXECUTE + security mode + owner
                    + actor/tenant/role derivation + side effects
                    + transitive authority + proof obligation
```

The next safe work is **B2 scope preparation only**: reconstruct the exact high-risk routine list and the per-object evidence/proof matrix before requesting separate execution authority.

The intended specialist destination for later B2 execution remains:

`SES — Backend & Data Platform Specialist`

Do not reopen B1 merely because B2 discovers current non-compliance.

No B2 substantive classification, remediation, SQL/Supabase/Auth mutation, runtime hostile testing, Ready, merge, deploy or Security Go authority is carried forward.


## 0.0000000000000000004 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-03 accepted with residuals / STS-M2-04 next — 2026-09-05

This handoff becomes current material continuity when the bounded STS-M2-03 documentation reconciliation is merged to canonical `main`.

Canonical durable evidence:

`docs/security/evidence/2026-09-05-sts-m2-03-index-acl-contradictions.md`

State to preserve:

```text
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED
STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-03 = COMPLETE / ACCEPTED WITH RESIDUALS
Security Go = NOT_GRANTED
```

Current M2-03 AS-IS anchors include 201 public indexes; one definition-equal duplicate group; 46 write policies; current live `14 structurally authenticated-reachable / 32 non-reachable` split; 13 latent/grant-blocked policies; 19 false-predicate policies; 9 authenticated direct-write grant tables; 12 authenticated MAINTAIN tables; default-privilege future provisioning hazard; and bounded caller/ACL contradictions.

Historical M2-02 `15/31` remains historical accepted evidence. The cause of the current `14/32` delta is `NOT DETERMINED`; do not globally reopen M2-02 without a material invalidation event.

Next safe gate after merge:

`STS-M2-04 — Política target de DEFINER / RLS / DML — READ_ONLY BOOTSTRAP FIRST`

No index change, Supabase/Auth mutation, RLS/policy/grant/default-privilege change, runtime hostile testing, deploy, STS-M2-04 implementation or Security Go authority is carried forward.


## 0.0000000000000000003 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-02 accepted with residuals / STS-M2-03 next — 2026-09-05

This handoff becomes current material continuity when the bounded STS-M2-02 documentation reconciliation is merged to canonical `main`.

Canonical durable evidence:

`docs/security/evidence/2026-09-05-sts-m2-02-database-authority-map.md`

State to preserve:

- `STS-M2-01 = COMPLETE / ACCEPTED`
- `STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS`
- public routines = 160;
- SECURITY DEFINER = 137;
- caller provenance = 137 / 137 CLOSED;
- actual SQL-DML = 57;
- SECURITY DEFINER + actual DML = 56;
- anon + actual DML = 8;
- Security Go = `NOT_GRANTED`.

Receiving conversations must preserve all accepted residuals and runtime gaps from the durable artifact. No hostile-client, cross-tenant, RLS adversarial, lock-abuse or caller×ACL runtime PASS is implied.

Next safe action after merge:

`STS-M2-03 — ÍNDICES / ACL CONTRADITÓRIAS — READ_ONLY FIRST`

No implementation, Supabase/Auth mutation, grant/RLS/policy change, deploy, STS-M2-04 implementation or Security Go authority is carried forward.


## 0.0000000000000000002 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-01 durable matrix/provenance anchor — 2026-09-04

For STS-M2-01, receiving conversations must use:

```text
docs/security/evidence/2026-09-04-sts-m2-01-database-canonicality-matrix.md
```

as the durable row-level accepted matrix/provenance artifact.

It contains all 44 final dispositions and the residual proof obligations. Aggregate SFJM counts are a summary only and must not replace that artifact.

Current semantic continuation remains:

```text
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED
STS-M2-02 = NEXT / READ_ONLY
Security Go = NOT_GRANTED
```

Do not reopen M2-01 absent material invalidation. Do not infer implementation authority from the accepted matrix.

## 0.0000000000000000001 HISTORICAL / SUPERSEDED HANDOFF — STS-M2-01 accepted / STS-M2-02 next — 2026-09-04

This handoff becomes current material continuity when merged to canonical `main`.

```text
program = Issue #141 — Security-to-Scale 2026

STS-M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
STS-M2 = STARTED
STS-M2-01 = COMPLETE / ACCEPTED

M2-01 current live universe = 44 public tables
M2-01 final matrix:
  KEEP 40
  INTERNAL 4
  CONSOLIDATE 0
  RETIRE 0
  REMODEL 0
  TOTAL 44

residual KEEP evidence obligations:
  logs
  mesa_fluxo_pagamentos_canonico
  templates_mensagens

Security Go = NOT_GRANTED
```

Receiving conversation contract:

1. resolve GitHub `main` live and bootstrap normally;
2. do not reopen STS-M2-01 without material invalidation;
3. preserve the historical WBS label 43 while using live universe 44;
4. next safe action is STS-M2-02 READ_ONLY routine/policy/trigger/grant mapping;
5. no implementation or database/runtime mutation is inherited from M2-01 acceptance;
6. keep M1 deferred-security evidence frozen unless its explicit reopen trigger is satisfied.

This reconciliation is self-closing after merge; do not create a lifecycle-only follow-up SFJM PR.

## 0.000000000000000000 HISTORICAL / SUPERSEDED HANDOFF — program hierarchy/Core DoD adjudicated / STS-M2 next — 2026-09-04

This handoff meaning becomes canonical only when the PR #170 adjudication is present on FECH.AI `main`.

```text
program hierarchy = docs/governance/2026-09-04-fechai-bcr-security-to-scale-program-hierarchy-core-dod.md
current execution program = Issue #141 — Security-to-Scale 2026
current execution WBS = docs/roadmap/fechai-security-to-scale-2026-wbs.md

B0 = immutable historical 300 WDP comparison baseline / not current execution baseline
product modules + Roadmap Mestre = product capability/vision references
sfjm-workspace = derived representation

STS-M1 = COMPLETE WITH DEFERRED SECURITY ASSURANCE
STS-M2 = Database Simplification & Optimization Plan / ELIGIBLE / NOT STARTED
STS-M2-01 = Matriz de 43 tabelas / 20h / READ_ONLY scope reconstruction next
STS-M2-01 implementation = NOT_AUTHORIZED
Security Go = NOT_GRANTED
```

Core finish line:

```text
CRM
Funil
Discador
Power Message Engine
MesaCliente

STS-M4 = core modularization + functional equivalence
STS-M5 = integrated security/reliability validation
STS-M6 = Security Go candidate + professional AS-BUILT + operational readiness
```

Receiving conversations must qualify ambiguous milestone references as `PRODUCT_MODULE_*`, `B0-*` or `STS-*` and reconstruct current live lifecycle from GitHub before action.

No authority is inherited for STS-M2 implementation, Supabase/Auth, runtime, production, deploy, Security Go, Ready or merge.

## 0.00000000000000000 HISTORICAL / SUPERSEDED HANDOFF — M1 closed / M2 bootstrap next — 2026-09-04

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

### Handoff contract

```text
M1 roadmap = CLOSED WITH DEFERRED SECURITY ASSURANCE
PR-09 = MERGED
M2 = ELIGIBLE / NOT STARTED
NEXT = M2 bootstrap + M2-01 bounded scope reconstruction
```

The receiving conversation must not reconstruct completed M1 phases absent a material invalidator.
It must preserve `SECURITY_GO = NOT_GRANTED` and the exact deferred-evidence reopen trigger.

No inherited authority exists for M2 implementation, Supabase/Auth, production, deploy, OC-01,
J4 execution or Security Go.

## 0.0000000000000000 Current handoff — M1 / F1-02 / PR-09 close-out — 2026-09-04

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

Continuity contract:

```text
M1 roadmap close = approved by Product Authority
PR-09 documentation lifecycle = DRAFT until separately advanced
Security Go = NOT_GRANTED
J4 deferred evidence = frozen, not waived
M2 = next eligible milestone only after PR-09 merge/reconciliation
```

Reopen deferred J4 evidence only after the exact Supabase Pro + isolated non-production environment
+ explicit Product Authority execution authorization trigger.

Next specialist/agent must first validate the exact PR-09 head and the six-file diff. It must not
start M2, execute OC-01/J4, grant Security Go, mark Ready or merge without fresh explicit authority.

## 0.000000000000000 HISTORICAL / SUPERSEDED HANDOFF — PR #166 merged and Vercel deployed — 2026-09-03

```text
repository: wagnerjfjunior/fecha.ai
main: 59262ef7cbbc3d29d6c4693c2b339964d6f806aa
PR #166: CLOSED / MERGED
pre-merge reviewed head: e92d97044ac753f9c71aad7fc37207fa355a2d1c
MERGED_TO_MAIN = CONFIRMED
VERCEL_PRODUCTION_DEPLOY = READY/SUCCESS
```

Closed PR-08 technical work:

```text
Phase 1 — execution authority / SQL safety: CLOSED STATICALLY
Phase 2 — topology / semantic truth: CLOSED STATICALLY
Phase 3 — FUN-006 applicability: CLOSED
Phase 4 — exact artifact provenance: CLOSED
```

Residual carried forward:

```text
PR08-RR-64M-CANONICAL-HASH
classification: ACCEPTABLE WITH RESIDUAL RISK
scope: isolated PR-08 evidence harness
failure model: fail-closed
reopen: ENOBUFS/maxBuffer, material fixture growth, large/uncontrolled dataset,
        or inability to complete rollback/cleanup evidence
future remediation: server-side ordered digest or streaming hash
```

Do not promote unresolved evidence:

```text
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
PR-08 runtime = NOT_EXECUTED
SECURITY_GO = NOT_GRANTED
```

Next handoff target: reconstruct the next J4/F1-02 gate in READ_ONLY mode from the merged
main, keeping merged harness, Vercel lifecycle, runtime evidence, rollback/reapply, OC-01,
PR-09 and Security Go as distinct states. No one state implies another.

No authority is carried forward for runtime, Supabase/Auth, OC-01, PR-09, Security Go,
Ready, merge or deploy.

## 0.00000 Current handoff override — J3 closed by bounded residual exception / J4 next — 2026-09-02

This section is the current handoff authority when older B2/B4-next sections
below conflict. Preserve older sections as lineage only.

```text
repository: wagnerjfjunior/fecha.ai
decision anchor main: 1449bee4b708a9211a099c52ff573cf52d44ef1c

PR #163:
  CLOSED / MERGED

PR-07 production migration:
  APPLIED
  Supabase project: uobxxgzshrmbtjfdolxd
  ledger version: 20260902225240

bounded runtime evidence:
  class: OPERATING_SESSION_RUNTIME_EVIDENCE
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

residual evidence:
  IMP-003 concurrent business-RPC runtime NOT_DETERMINED
  migration rollback/reapply NOT_DETERMINED

control failure observed:
  NO

CANONICAL_J3_EXIT_SATISFIED:
  NO

J3_GOVERNANCE_CLOSURE_BY_PRODUCT_AUTHORITY_EXCEPTION:
  YES

J3:
  CLOSED WITH BOUNDED RESIDUAL EVIDENCE

Security Go:
  DENIED / NOT_GRANTED
```

Standing Product Authority constraints remain:

```text
NO LAB
NO SECOND SUPABASE PROJECT
NO PREVIEW BRANCH
NO PRODUCTION MIGRATION ROLLBACK TEST
```

The exception does not claim either residual test passed. Both remain eligible
for future retest only if an executable and separately authorized path appears.

### Single next handoff

```text
J4 / PR-08 — REPEATABLE EXECUTABLE SECURITY MATRIX

next action:
  reconstruct exact scope/evidence matrix/prohibitions first
  then request separate Product Authority implementation authority

current authority:
  documentation reconciliation only
```

Do not infer PR-08 implementation, Ready, merge, deploy, Supabase mutation,
rollback/reapply, Security Go or commercialization authority from this handoff.

## 0.0000 Current handoff override — B2 closed / B4 next — 2026-09-01

This section is the current handoff authority when older B2-next sections below
conflict. Preserve older material as lineage only.

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

Current handoff:

```text
closed bounded slice:
  F1-02/B2 — EXCESSIVE DIRECT CRM WRITES
  REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN

next bounded risk:
  F1-02/B4 — LIST ACL CROSS-TENANT TARGET RISK / PR-06

next action:
  TARGET DESIGN + AUTHORIZATION MATRIX FIRST

required specialists before implementation:
  Architecture
  AppSec
  LeadOps
```

Do not infer B4 implementation authority, runtime-negative PASS or Security Go
from this handoff.


**Status:** `SECURITY_TO_SCALE_2026 / F1_02_B3_REMEDIATED / B2_NEXT / SECURITY_GO_DENIED`
**Updated:** `2026-09-01`
**Repository:** `wagnerjfjunior/fecha.ai`

## 0.000 Current handoff override — B3 closed / B2 next — 2026-09-01

This section is the current handoff authority when older sections below
conflict. Preserve older material as lineage; do not replay stale lifecycle or
authorization.

```text
Program #141: OPEN
M1 baseline #150: CLOSED / completed
F1-02: ACTIVE REMEDIATION
B3: REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN
post-application AppSec: PASS
RUNTIME_NEGATIVE_PASS: NOT ESTABLISHED
Security Go: DENIED
broad paid commercialization: BLOCKED
```

Current GitHub/database anchors:

```text
FECH.AI main at B3 closure:
  035f57e29d64c0cca26048a925a790459bd9976c
PR #157:
  CLOSED / MERGED
Supabase B3 ledger version:
  20260901074722
```

### Do not reopen

Do not reopen B3 design, PR #157 review, application or catalog proof merely
because runtime-negative testing was not authorized. A material contradictory
event is required to invalidate this closure.

### Single next handoff

```text
F1-02/B2 — EXCESSIVE DIRECT CRM WRITES
TARGET DESIGN / CALL-SITE + LIVE CONTRACT RECONSTRUCTION FIRST
```

Current bounded evidence:

```text
public.leads:
  authenticated INSERT=true
  authenticated UPDATE=true

public.lotes:
  authenticated UPDATE=true
```

The next specialist path is Backend/Data target-design reconstruction followed
by independent AppSec review. No implementation authority exists from this
handoff.

### Explicit boundaries

```text
NO Supabase mutation
NO runtime-negative production test
NO rollback
NO Ready/merge from this handoff
NO Security Go
NO broad paid commercialization
NO Issue #141 closure
```

For unrelated active workstreams and historical decisions, use
`docs/sfjm/CURRENT_STATE.md` plus live evidence; this override changes only
the B3 closure / #150 lifecycle / next-action meaning.


## 1. Purpose

This is the thin current handoff pointer. It does not replace live GitHub,
Supabase/runtime evidence, bootstrap, specialist routing, authority or the
evidence-freshness ledger.

Historical M1 and public.leads lineage remains preserved in
`docs/sfjm/CURRENT_STATE.md` and `docs/sfjm/EVIDENCE_FRESHNESS.md`.

## 2. Reconstruct in this order

```text
1. resolve wagnerjfjunior/fecha.ai main live
2. read docs/bootstrap/INDEX.md
3. read docs/skills/SES_SPECIALIST_ROUTING.md
4. resolve the adopted SES role/archetype/certification/local rule
5. read the common Modus Operandi
6. read governance when applicable
7. read docs/sfjm/INDEX.md and current SFJM views
8. resolve Issues #141 and #150 live
9. resolve any PR/branch/head involved in the next bounded lifecycle
10. do not reopen M1 technical acquisition without a material invalidation event
```

## 3. Current program state

```text
#141 Security-to-Scale 2026:
  OPEN

#150 M1 Security Truth Baseline:
  technical/evidence exit criteria SATISFIED
  OPEN pending separately authorized Issue closure

M1_SECURITY_TRUTH_BASELINE:
  COMPLETE

REMEDIATION_PROGRAM:
  ACTIVE

Security Go:
  DENIED / NOT_GRANTED

broad paid commercialization:
  BLOCKED
```

## 4. Final M1 gates

```text
Backend/Data:
  BACKEND_DATA_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

Application Security:
  APPSEC_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

Documentation Auditor:
  DOCUMENTATION_M1_CLOSURE_PASS_WITH_BOUNDED_RESIDUALS

blockers to M1 baseline closure:
  NONE

additional technical re-audit:
  NO / AUDIT_LOOP_BLOCKED
```

Preserve:

```text
M1_FINDING_DISCOVERED != M1_FINDING_REMEDIATED
M1_BASELINE_COMPLETE != SECURITY_GO
STATIC_IMPLEMENTATION_REVIEW != LIVE_DATABASE_VALIDATED
LIVE_DATABASE_VALIDATED != CONTROLLED_RUNTIME_PASS
```

## 5. Current finding set

```text
M1-B-F01  ANON_PRIVILEGED_RPC_EXECUTION_SURFACE
M1-C-F01  FUNIL_TENANT_RELATIONSHIP_INTEGRITY_GAP  [P0]
           no proven cross-tenant lead leakage claim
MIGRATION_PROVENANCE_GAP
M1-D-F01  DEPENDENCY_REPRODUCIBILITY_GAP
M1-D-F02  VITE_6_4_2_KNOWN_AFFECTED_VERSION
M1-E-F01  LIVE_EDGE_FUNCTION_NOT_VERSIONED
M1-E-F02  BROWSER_SESSION_REFRESH_TOKEN_EXPOSURE_SURFACE
M1-E-F03  EXTERNAL_WORKER_PROXY_AUTHORITY_GAP
M1-E-F04  LEAKED_PASSWORD_PROTECTION_DISABLED
```

All remain unresolved according to their classifications. M1 closure does not
remediate them.

## 6. Evidence limitations

```text
CONTROLLED_RUNTIME_NEGATIVE_PASS = NOT_ESTABLISHED
production negative/offensive testing = PROHIBITED
Vite production exploitability = NOT_ESTABLISHED
Worker runtime abuse / PII leak / tenant crossover = NOT_PROVEN
public.leads controlled runtime negative PASS = NOT_ESTABLISHED
```

## 7. Current lifecycle reconciliation

```text
#140:
  CLOSED / MERGED
  merge commit c0d993ebe574f644af4f83cc25630fb8c1bd41ad

#139:
  OPEN / READY
  head 32003e75a28e235fb454d39e3e4459d0f03acb2b
  STALE_REVALIDATION_REQUIRED
  M1 closure grants NO fresh approval

#131:
  STALE_CONTINUITY

#124:
  STALE_CONTINUITY

#120:
  SUPERSEDED
```

## 8. Single next safe action

```text
P0 — M1-C-F01 / FUNIL TENANT INTEGRITY

DESIGN / PROOF PLAN FIRST
NO IMPLEMENTATION UNDER THIS DOCUMENTATION AUTHORITY
```

The design/proof plan must define:

- the tenant-aware database invariant;
- correct `mover_funil` tenant attribution;
- explicit handling decision for existing anomalous rows without silent cleanup;
- preservation of RLS/FORCE RLS;
- rollback;
- static/live verification obligations;
- runtime-negative proof only if separately authorized and feasible without
  production negative testing.

## 9. Prohibited carry-over

Do not derive authorization from this handoff for:

```text
Ready / merge / deploy
Supabase / Auth / migration / data mutation
cleanup of anomalous funil rows
production negative testing
staging / LAB / second Supabase project / Preview Branch / local isolated env
Security Go
broad paid commercialization
Issue #141 closure
fresh #139 approval
reopening public.leads
```

Issue #150 closure requires a separate explicit Product Authority action after
the bounded M1 documentation reconciliation reaches its own authorized lifecycle
gate.

## 10. Handoff — PR #166 after Phases 1–4 and residual adjudication — 2026-09-03

Operational anchor before the authorized SFJM reconciliation commit:

```text
repository: wagnerjfjunior/fecha.ai
main: 9d05c64281c2aeeae9d67b139eab674720184fb1
PR: #166
branch: test/f1-02-negative-security-matrix
reviewed exact head: 2a0e6b8a2f964afe3c0c35c75190ae23344ed884
state: OPEN / READY
mergeable: TRUE
Vercel: SUCCESS
```

Closed technical work:

```text
Phase 1 — execution authority / SQL safety: CLOSED STATICALLY
Phase 2 — topology / semantic truth: CLOSED STATICALLY
Phase 3 — FUN-006 applicability: CLOSED
Phase 4 — exact artifact provenance: CLOSED
```

Carried residual:

```text
PR08-RR-64M-CANONICAL-HASH
classification: ACCEPTABLE WITH RESIDUAL RISK
thread: PRRT_kwDOSEToMc6fBXHM
scope: isolated PR-08 evidence harness
failure model: fail-closed; large relation materialization may abort evidence capture
production runtime impact: none established
reopen on: ENOBUFS/maxBuffer, material fixture growth, large/uncontrolled dataset,
           or inability to complete rollback/cleanup evidence
future remediation: server-side ordered digest or streaming hash
```

Do not convert residual acceptance into execution evidence:

```text
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
PR-08 runtime = NOT_EXECUTED
```

Lifecycle action already authorized after this documentation commit is published
and revalidated: resolve exactly these eight review threads:

```text
PRRT_kwDOSEToMc6fBXG5
PRRT_kwDOSEToMc6fBXHB
PRRT_kwDOSEToMc6fBXHU
PRRT_kwDOSEToMc6fBXHW
PRRT_kwDOSEToMc6fBXHY
PRRT_kwDOSEToMc6fBXHI
PRRT_kwDOSEToMc6fBXHF
PRRT_kwDOSEToMc6fBXHM
```

Then STOP.

Next specialist/gate: independent final exact-head pre-merge review of PR #166,
but only after a separate Product Authority authorization. That future review
must not reopen closed phases without a material invalidation event.

No authority is carried forward for runtime, Supabase/Auth, merge, deploy,
OC-01, PR-09 or Security Go.
