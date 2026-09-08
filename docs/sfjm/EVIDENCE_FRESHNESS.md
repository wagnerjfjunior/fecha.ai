# FECH.AI — SFJM Evidence Freshness

## 0.0000000000000000034 CURRENT EVIDENCE — STS-M3-04-01 APPLIED / VALIDATED / ACCEPTED — 2026-09-08

~~~text
source repository = wagnerjfjunior/fecha.ai
acceptance evidence base main = 1402395e708f69b0935ab2ba45489f717943b8b2
PR #205 = MERGED / CLOSED
final approved head = 07f5dad3f805e319a0303e664752a2da7d0e3dfe
merge commit = 1402395e708f69b0935ab2ba45489f717943b8b2
migration blob = 9e9e4aec6273624695638071f2d717f99d7a3586
Supabase project = uobxxgzshrmbtjfdolxd
apply result = SUCCESS
authenticated direct INSERT on pme_message_usage = FALSE
direct write policies on pme_message_usage = 0
authenticated SELECT = PRESERVED
authenticated RPC EXECUTE = PRESERVED
anon/public RPC EXECUTE = FALSE
post-apply smoke 16A blocks 00-06 = PASS
STS-M3-04-01 = COMPLETE / ACCEPTED WITH RESIDUALS
Security Go = NOT_GRANTED
~~~

Supabase migration history records the applied operation as:

~~~text
version = 20260908184747
name = sts_m3_04_01_pme_message_usage_rpc_only
~~~

The version differs from the canonical repository filename prefix `20260908233000`; this same apply-migration timestamp behavior exists on prior FECH.AI applied migrations and is retained as a provenance residual, not rewritten.

Freshness invalidators: material grant/policy/RPC/schema drift; rollback; conflicting migration-history evidence; new hostile-client/AppSec evidence; head/main provenance change; or a later authorized slice that changes the same boundary.

## 0.0000000000000000033 CURRENT EVIDENCE — STS-M3-03 ACCEPTED / M3-04 AUTHORIZED NOT INITIATED — 2026-09-08

~~~text
source repository = wagnerjfjunior/fecha.ai
decision/publication base main = ec42e7b087dd1bf9b7ddc0cf05316e9d3e7979be
STS-M3-03 = COMPLETE / ACCEPTED WITH RESIDUALS
privileged candidate universe = 49
candidate rows disposed = 49 / 49
SERVICE_ONLY_COMMAND = 2 / 2 mapped
STS-M3-04 = AUTHORIZED / NOT_INITIATED
Security Go = NOT_GRANTED
~~~

Decision-grade artifact:
`docs/security/evidence/2026-09-08-sts-m3-03-privileged-rpc-allowlist.md`
blob = `9b4c76648e34f324edfb2df205b2ba8691590817`

This publication records the Product Authority-accepted M3-03 READ_ONLY analysis and does not re-run the live database/runtime. Implementation target compliance, hostile runtime assurance and AppSec PASS remain unproven/not performed.

Invalidators: material authority/schema/routine/runtime drift, contradictory evidence, Product Authority decision change, or authorized remediation that changes relevant implementation state.


## 0.0000000000000000032 CURRENT EVIDENCE — PR #202 MERGED / STS-M3-02 CANONICAL ON MAIN — 2026-09-08

~~~text
source repository =
wagnerjfjunior/fecha.ai

canonical main =
665e3920b17849f45d8b3fcea015b1492219f115

PR #202 =
MERGED / CLOSED

final approved head =
c71a3e1a5f7c3d829b8379b085ba14f20b2f53cc

merge commit =
665e3920b17849f45d8b3fcea015b1492219f115

STS-M3-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-03 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

Canonical decision-grade artifact after merge:

~~~text
docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md
blob = 6cf20f5298e183c34d9b560740b3d19c621fb7bb
~~~

The final PR #202 artifact blob on canonical main matches the exact-head-reviewed blob. The merge is a lifecycle/provenance event only; it does not establish runtime target compliance, service-only runtime proof, support-mode implementation, hostile-client assurance, AppSec PASS or Security Go.

Current next material task remains:

~~~text
STS-M3-03 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

CURRENT_AUTHORIZED_EXECUTION =
NONE
~~~

Freshness is invalidated by a later material authority/schema/runtime change, contradictory evidence, Product Authority contract change, or a new canonical-main event that changes these claims.

## 0.0000000000000000031 HISTORICAL / SUPERSEDED PRE-MERGE EVIDENCE — STS-M3-02 ACCEPTANCE / PR #202 CORRECTION — 2026-09-08

~~~text
publication base main =
c075a751c70ae24b5db8fcfc924c46fba6b10e3e

Product Authority =
Wagner / FECH.AI

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

Current decision-grade authority anchor:

~~~text
docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md

end-user/session principal = auth.uid()
tenant identity = canonical active public.corretores
tenant membership = corretores.empresa_id
tenant role = corretores.role
team = public.times / corretores.time_id / times.gestor_id
platform root = active public.admins role='admin_global'
platform root pure platform operation does not require corretores tenant identity
service-only authority = explicit SERVICE_ONLY_COMMAND + canonical trusted runtime + service owner + trusted server-side business/tenant authorization + bounded side-effect/secret boundary + runtime proof + revoke/kill path
service_role alone = NOT BUSINESS AUTHORIZATION
exceptional root tenant support implementation owner = BG-06 / PARKED / NOT_AUTHORIZED
~~~

Current preserved gaps / invalidators:

~~~text
legacy root / tenant-role compatibility = NOT_REMEDIATED
support mode = NOT_IMPLEMENTED
service-only runtime proof / target compliance = NOT_PROVEN
exhaustive privileged RPC compliance = NOT_PROVEN
exhaustive direct-DML compliance = NOT_PROVEN
hostile-client / cross-tenant assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Freshness is invalidated by material authority/schema/runtime drift, contradictory evidence, a Product Authority contract change, or any new head/content that changes these claims. Lifecycle state must still be resolved live from GitHub.

## 0.0000000000000000028 HISTORICAL / SUPERSEDED EVIDENCE — STS-M3-01 PRODUCT AUTHORITY ACCEPTANCE — 2026-09-07

~~~text
publication base main =
661ef0014576d473088add0052d751e0a47d306e

Product Authority =
Wagner / FECH.AI

STS-M3-01 =
COMPLETE / ACCEPTED

STS-M3 =
ACTIVE

STS-M3-02 =
NEXT_ELIGIBLE / NOT_AUTHORIZED

Security Go =
NOT_GRANTED
~~~

Accepted decision-grade STS-M3-01 evidence from the bounded READ_ONLY analysis:

~~~text
canonical authenticated principal = auth.uid()
canonical tenant application identity = public.corretores
corretores.user_id = UNIQUE
corretores.empresa_id = NOT NULL
canonical membership = corretores.empresa_id
canonical tenant role target = corretores.role
canonical team entity = public.times
team membership = corretores.time_id
team manager responsibility = times.gestor_id
canonical platform root target = active public.admins role=admin_global
~~~

Accepted live residual evidence:

~~~text
ROOT DUAL AUTHORITY SOURCE = PROVEN LIVE
active public.admins rows = 1
active corretores.role='admin_global' rows = 2
identity represented in both sources = 1
root represented only by public.admins = 0
root represented only by corretores.role='admin_global' = 1

ONE ACTIVE TEAM WITH ADMIN_LOCAL-AS-GESTOR LEGACY RELATION = PROVEN LIVE

CRIA-USUARIO AUTHORITY DERIVATION DIFFERS FROM M3-01 TARGET = PROVEN
GitHub blob = 866257371dcc85d22ae54cae3593b3e49a132d8e
live Edge = criar-usuario version 19
GitHub/live content length = 19012 / 19012
exact string equality = TRUE
~~~

Preserved gaps:

~~~text
current implementation target-compliant = NOT_PROVEN
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
exhaustive direct-DML/application callsite proof = NOT_ESTABLISHED
hostile-client / cross-tenant assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

This publication does not re-run or mutate the live database/runtime. It records the Product Authority-accepted M3-01 evidence and contract. Freshness is invalidated by material authority/schema/runtime drift, contradictory evidence or a Product Authority contract change.


## 0.0000000000000000027 HISTORICAL / SUPERSEDED EVIDENCE — STS-M2-06 ACCEPTANCE / M2 CLOSURE PUBLICATION — 2026-09-07

~~~text
STS-M2-06 analysis base main =
f22b83bb7acec8692e0575185a88ca2755183b41

authorization publication merge =
PR #197
0cb993a1eb86433975429da4a07a13fd3f373e16

current publication base main =
83186f5775e563e150329fa0b95dd1d7f3f3a516

Product Authority =
Wagner / FECH.AI

STS-M2-06 =
COMPLETE / ACCEPTED

DATABASE STRATEGY =
V2_STRANGLER / SAME_DATABASE_FIRST

STS-M2 =
COMPLETE / ACCEPTED WITH RESIDUALS

Security Go =
NOT_GRANTED
~~~

Decision-grade M2-06 evidence preserved by Product Authority acceptance:

~~~text
public tables = 44
RLS enabled = 44 / 44
accepted bounded contexts = 10
M2-05 dispositions = KEEP 40 / INTERNAL 4 / CONSOLIDATE 0 / RETIRE 0 / REMODEL 0
public routines = 160
current SECURITY DEFINER routines = 137
non-DEFINER routines = 23
non-internal trigger instances = 31
live applied migration ledger observed during M2-06 = 149
physical database scale problem = NOT_PROVEN
primary current database complexity = authority / security boundary / legacy compatibility / application coupling
~~~

Preserved evidence gaps:

~~~text
current implementation target-compliant = NOT_PROVEN
exhaustive application direct-DML callsite proof = NOT_ESTABLISHED
lista_avaliacoes resulting-row relationship integrity = NOT INDEPENDENTLY PROVEN
leads resulting-row empresa relationship = NOT INDEPENDENTLY PROVEN
times resulting-row empresa relationship = NOT FULLY PROVEN
hostile-client / cross-tenant runtime assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
assistente-ai live Edge Function vs versioned source parity = NOT_ESTABLISHED
~~~

This publication produces no runtime, Supabase, Auth, data or production mutation.

Freshness is invalidated by material architecture/database/runtime drift, contradictory new evidence, or a Product Authority change to the selected strategy.


## 0.0000000000000000026 HISTORICAL / SUPERSEDED EVIDENCE — TYPED ISSUE / RISK / GATE CLASSIFICATION — 2026-09-07

Validation anchor:

~~~text
FECH.AI main =
0cb993a1eb86433975429da4a07a13fd3f373e16

CURRENT_STATE =
9cb81039a826d145fa9fdfad32278a0f06cd9d67
= INTEGRAL_READ

BLOCKED_ACTIONS =
fca4e6e8085e335d4de073d2dbcf052562f1c496
= INTEGRAL_READ

NEXT_SAFE_ACTION =
6cd13ba9f62a6d6645b1da471b3fb32075e5d80f
= INTEGRAL_READ

PROGRAM_TASK_GRAPH =
146333eb4cbe589663c43edb4098e90b7865cf93
= INTEGRAL_READ

F1-02 remediation master plan =
e7022ad4efdda4428e9d8261fdd666b47c914215
= INTEGRAL_READ
~~~

Adjudicated current classification:

~~~text
CURRENT_TASK = STS-M2-06
CURRENT_TASK_BLOCKERS = 0
RESIDUAL = 3
DEFERRED_EVIDENCE = 3
SECURITY_GATE = 3
FUTURE_GATE = 1
~~~

This evidence supports issue lifecycle classification only. It does not resolve the underlying residuals/deferred evidence/gates.

Invalidators:

- Product Authority changes STS-M2-06 or launch/security authority;
- a current blocker is discovered;
- a residual/deferred/gate changes state;
- canonical evidence contradicts a typed item;
- consumer source SHA no longer matches canonical state and freshness is claimed.


## 0.0000000000000000025 HISTORICAL / SUPERSEDED EVIDENCE — STS-M2-06 AUTHORIZATION / EXECUTION START BOUNDARY — 2026-09-07

Authorization anchor:

~~~text
canonical FECH.AI main at issuance =
f22b83bb7acec8692e0575185a88ca2755183b41

Product Authority =
Wagner / FECH.AI

STS-M2-06 =
AUTHORIZED_READ_ONLY / READY_TO_EXECUTE

canonical specialist =
GPT1.5 — FECH.AI Arquiteto SaaS

Security Go =
NOT_GRANTED
~~~

Material source state at authorization publication:

~~~text
WBS M2-06 task / exit contract = INTEGRAL_READ
FECH.AI bootstrap / routing / registry / Modus Operandi = INTEGRAL_READ
GPT1.5 canonical skill = INTEGRAL_READ
governance index = INTEGRAL_READ
current SFJM material views = INTEGRAL_READ
SES FECH.AI adapter / software-systems-architect archetype = INTEGRAL_READ
~~~

The authorization does not itself produce STS-M2-06 architecture evidence.

~~~text
STS-M2-06 current-state characterization = NOT_YET_PRODUCED
three-option decision matrix = NOT_YET_PRODUCED
architecture recommendation = NOT_YET_PRODUCED
Product Authority architecture adjudication = NOT_YET_GRANTED
implementation = NOT_AUTHORIZED
~~~

Accepted STS-M2-01..STS-M2-05 evidence remains upstream input and must be consumed without global replay unless a material invalidator is found.

Freshness is invalidated by material FECH.AI main drift affecting architecture evidence, material database/runtime changes, Product Authority scope change, or contradictory new evidence discovered during STS-M2-06. Ordinary time passage alone is not sufficient.

No runtime, Supabase, Auth, data or production mutation occurred in this authorization publication.

## 0.0000000000000000024 CURRENT EVIDENCE — STS-M2-05 ACCEPTANCE PUBLICATION — 2026-09-07

Acceptance/publication base:

~~~text
acceptance/publication base main =
e07254ef6b2d7184e749463727df2e6d404226a7

canonical main after PR #195 merge =
d6953ea3071ada55fbcd97f21c848f5c6424ca3f

environment =
Pilot Production / SaaS multi-tenant / multiempresa

Security Go =
NOT_GRANTED
~~~

Durable M2-05 evidence on canonical main:

~~~text
docs/security/evidence/2026-09-07-sts-m2-05-database-contract-map.md
blob 8b2875e1bc095329482de095028ed31b37091d63
coverage = contract-level accepted M2-05 result
lifecycle = MERGED_CANONICAL_MAIN via PR #195
reviewed head = 643fb532e2860bdc53cbbddef529e3b9ed4e8709
merge commit = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
~~~

Post-merge lifecycle evidence:

~~~text
PR #195 = MERGED / CLOSED
merge commit = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
canonical main = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
Vercel commit status observed during reconciliation = SUCCESS
GitHub Actions PR workflow runs on merge commit = 0
~~~

Preserve lifecycle separation:

~~~text
MERGED != RUNTIME VALIDATED
VERCEL SUCCESS != APPSEC PASS
VERCEL SUCCESS != SECURITY GO
M2-06 = ELIGIBLE_NOT_AUTHORIZED
~~~

Material accepted upstream evidence was re-read on the exact publication base without replaying closed analyses:

~~~text
M2-01 blob 281fe7372882310e186abfd068b4b4f1baab011d = INTEGRAL_READ
M2-02 blob ec723587ee003427e592873efcc2fe4ef5aae615 = INTEGRAL_READ
M2-03 blob 3d5cf2d890e4c5f7b37d9f01a926a8a50d0f8cc9 = INTEGRAL_READ
M2-04B1 blob 15e771e99ce3e424ba4a869a00d4965bed733fc3 = INTEGRAL_READ
M2-04B2 blob bfa43f6936b2a381552dbb95f5306f13069142af = INTEGRAL_READ
M2-04B3 narrative blob 96d31bb3c471ddbc606f391aff13cb7674358e8b = INTEGRAL_READ
M2-04B3 113x40 CSV blob cf3baa6e5a6ab6465688de8f6af43cba7c27d3bd = INTEGRAL_READ
M2-04C3 CSV blob 716c23d5f549eb465f3393cdfc5989dda82b69a7 = INTEGRAL_READ
M2-04C4 blob 01eefe744946a9f916ac0789780f77c5444aa799 = INTEGRAL_READ
M2-04D blob 7fdc63a95d81661598937aa0bdfa654bcb9db66a = INTEGRAL_READ
M2-04E blob 07365cae5a353bd2407512ddde0d3d4cf880352f = INTEGRAL_READ
M1/M2 provenance manifest blob 7b7c84e713319a3a3c3de457e6e16239f1b1fd06 = INTEGRAL_READ
current material SFJM views on publication base = INTEGRAL_READ
~~~

Accepted M2-05 coverage:

~~~text
tables = 44 / 44
public routines = 160 / 160
SECURITY DEFINER slice coverage = 137 / 137 through accepted non-homogeneous upstream slices
non-DEFINER delta = 23 / 23
trigger instances = 31 / 31
bounded contexts = 10 / 10
~~~

Known proof limitations remain fresh and intentionally open:

~~~text
lista_avaliacoes resulting-row protected relationship integrity = NOT INDEPENDENTLY PROVEN
leads resulting-row empresa_id relationship = NOT INDEPENDENTLY PROVEN
times resulting-row empresa relationship = NOT INDEPENDENTLY RESTATED / NOT FULLY PROVEN
exhaustive application direct-DML callsite proof = NOT_ESTABLISHED
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
runtime hostile/cross-tenant assurance = NOT_PROVEN
AppSec PASS = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

Invalidation events for this acceptance publication include material main drift affecting accepted evidence, candidate-head change after review, a new contradiction in the documented M2-05 contract, or a Product Authority decision changing scope/status. Ordinary time passage alone is not an invalidator.


## 0.0000000000000000023 HISTORICAL / SUPERSEDED EVIDENCE — PROGRAM TASK GRAPH PUBLICATION — 2026-09-07

Publication base:

~~~text
FECH.AI main =
f7a6c69b8440b60181c7a4a9956c0f3c4268e9f6
~~~

Material source coverage:

~~~text
docs/roadmap/fechai-security-to-scale-2026-wbs.md
blob c6fe2e339c4de33dfb8265912ba6b63380270c4e
= INTEGRAL_READ

docs/sfjm/CURRENT_STATE.md
blob 7a2c6f236f75993d0b02e27f6a0864ca15cb0c83
= INTEGRAL_READ

docs/sfjm/NEXT_SAFE_ACTION.md
blob f0217fdbdf6f9eff5243b3b60f9c87d35c269e1e
= INTEGRAL_READ

docs/sfjm/INDEX.md
blob 3f83b38d7c6f4fea9d7d02dee5b3798bdfe2baad
= INTEGRAL_READ

Documentation Auditor canonical skill
docs/skills/fechai-gpt0-documentation-auditor.md
blob 282182a54b88f2344ea56ef8225e2519a96493e2
= INTEGRAL_READ
~~~

The graph publishes WBS-derived future structure and accepted execution-discovered continuity. It does not prove implementation or runtime state and does not authorize future tasks.

Invalidators include:

- WBS structure/ID/order change;
- Product Authority changing milestone/task state;
- accepted task closure or reopening;
- adoption of a new execution decomposition;
- a material residual changing operational task state;
- contradiction between graph and principal CURRENT_STATE.

Ordinary PR lifecycle or main-SHA-only movement is not an invalidator by itself.

## 0.0000000000000000022 CURRENT EVIDENCE — FINAL STS-M2-04 WBS CLOSURE ACCEPTANCE — 2026-09-07

Final adjudication anchor:

~~~text
FECH.AI main =
6357c1b4df207683b60de26daa53248d44dce84a

SES main =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

STS-M2-04 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
~~~

WBS objective consumed:

~~~text
M2-04 — Política target de DEFINER / RLS / DML — 20h
~~~

Material durable evidence revalidated on the exact acceptance main:

~~~text
WBS
blob c6fe2e339c4de33dfb8265912ba6b63380270c4e
= INTEGRAL_READ

B1 routine authority policy
blob 15e771e99ce3e424ba4a869a00d4965bed733fc3
= INTEGRAL_READ

B2 high-risk classification
blob bfa43f6936b2a381552dbb95f5306f13069142af
= INTEGRAL_READ

B3 remaining routine classification
blob 96d31bb3c471ddbc606f391aff13cb7674358e8b
= INTEGRAL_READ

C4 target RLS / direct-DML contract
blob 01eefe744946a9f916ac0789780f77c5444aa799
= INTEGRAL_READ

D trigger authority
blob 7fdc63a95d81661598937aa0bdfa654bcb9db66a
= INTEGRAL_READ

E architecture synthesis
blob 07365cae5a353bd2407512ddde0d3d4cf880352f
= INTEGRAL_READ
~~~

Current SFJM material views were read on the same exact main. No global B1/B2/B3/C/D/E replay was performed.

Drift check from the accepted B2/E evidence anchors to the final acceptance main found documentation-only changes and no technical/runtime files.

Final evidence conclusion:

~~~text
TARGET DEFINER / INVOKER POLICY = COMPLETE
RLS TARGET CONTRACT = COMPLETE
DIRECT-DML TARGET CONTRACT = COMPLETE
TRIGGER TARGET AUTHORITY = COMPLETE
TARGET-AUTHORITY SEMANTIC BLOCKERS = 0

CURRENT IMPLEMENTATION TARGET-COMPLIANT = NOT_PROVEN
APPSEC PASS = NOT_PERFORMED
RUNTIME ASSURANCE = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
~~~

Freshness invalidators include material technical changes to routine definitions/modes/ACLs/owners/search_path, RLS/policies/direct-DML authority, trigger authority, canonical callers/lifecycle semantics, or contradictory runtime/AppSec evidence.

## 0.0000000000000000021 CURRENT EVIDENCE — PR #192 CONFLICT RECONCILIATION AGAINST PR #191 MAIN — 2026-09-07

Reconciliation anchors:

~~~text
canonical main before reconciliation =
ead9fe91d561145f883694452a54a6a289e42080

PR #192 pre-reconciliation head =
8f8c8dade4a495fe2b0edc48d11a08f5ccd3670f

main drift source =
PR #191 / docs: harden M1/M2 evidence provenance
~~~

Drift classification:

~~~text
technical/runtime/Supabase drift = NO
documentation/provenance drift = YES
overlapping SFJM files =
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/EVIDENCE_FRESHNESS.md
~~~

Reconciliation rule:

~~~text
PR #191 entries from canonical main = PRESERVED INTEGRALLY
accepted B2 target-contract decisions = PRESERVED WITHOUT SEMANTIC CHANGE
force push = NO
technical mutation = NO
~~~

The PR #191 provenance hardening does not invalidate the B2 target-contract result. Fresh exact-head review is required after this reconciliation before any Ready decision.

## 0.0000000000000000020 CURRENT ACCEPTANCE FRESHNESS — B2 TARGET-CONTRACT RESULT ACCEPTED — 2026-09-07

Product Authority acceptance is bound to the exact result recorded on PR #192 parent head:

~~~text
accepted parent head =
8e18c4abe4daca6e4e9240c567267fcfe774e5b9

execution-base main =
dd118baa89b68281bbd7c8df43c8e24c0e9b66bf

live B2 fingerprint =
33aea33ec2039d91f417b3980ea8cf43
~~~

The underlying READ_ONLY evidence remains fresh for this acceptance because no main drift or Supabase mutation was performed by the reconciliation.

Acceptance does not expand proof:

~~~text
TARGET CONTRACT ACCEPTED != CURRENT IMPLEMENTATION COMPLIANT
TARGET CONTRACT ACCEPTED != RUNTIME ASSURANCE
TARGET CONTRACT ACCEPTED != APPSEC PASS
TARGET CONTRACT ACCEPTED != SECURITY GO
~~~

Freshness invalidators remain the same as the underlying B2 closure evidence: material change to any of the 15 functions, their ACL/owner/search_path/security mode, relevant helper/RLS/direct-DML authority, canonical callers, lifecycle semantics, or contradictory runtime/AppSec evidence.


## 0.0000000000000000019 CURRENT EVIDENCE — B2 HIGH-RISK TARGET-CONTRACT CLOSURE READ_ONLY — 2026-09-07

Execution anchors:

~~~text
FECH.AI main = dd118baa89b68281bbd7c8df43c8e24c0e9b66bf
FECH.AI main tree = b5774a4ed12f179bebcb1058a3bcf49eeebc4cbe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase project = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
Supabase project status = ACTIVE_HEALTHY
live PostgreSQL = 17.6
~~~

Material source/read classification:

~~~text
docs/security/evidence/2026-09-05-sts-m2-04b1-routine-authority-policy.md
blob 15e771e99ce3e424ba4a869a00d4965bed733fc3
= INTEGRAL_READ

docs/security/evidence/2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md
blob bfa43f6936b2a381552dbb95f5306f13069142af
= INTEGRAL_READ

current SFJM / governance / WBS / routing / Backend-Data project rules
= PARTIAL_READ / MATERIAL-SECTIONS-ONLY

B3/C/D/E accepted downstream state
= CONSUMED AS ACCEPTED CONTINUITY / NO GLOBAL RE-RUN

repository callsite search
= BOUNDED SEARCH EVIDENCE / NOT INTEGRAL REPOSITORY READ
~~~

Live database evidence:

~~~text
exact B2 signatures resolved = 15 / 15
pg_get_functiondef inspected = 15 / 15
security mode / owner / proconfig / ACL inspected = 15 / 15
aggregate live B2 fingerprint =
33aea33ec2039d91f417b3980ea8cf43

15 / 15 SECURITY DEFINER
15 / 15 owner postgres
15 / 15 search_path=public
8 / 8 Group-A anon EXECUTE
~~~

Bounded supporting catalog evidence also inspected:

- material table RLS/FORCE-RLS state;
- material anon/authenticated table privileges;
- material policies for Mesa financial, inventory, leads/funnel, list/rating, audit and actor tables;
- public schema CREATE privilege for PUBLIC/anon/authenticated/service_role = false;
- relevant transitive helper bodies including is_root, is_gestor, Mesa auth/admin helpers, solicitar_lote, registrar_root_audit, simular_troca_plano_empresa_root and calcular_score_lista.

Runtime non-use proof remains unavailable:

~~~text
track_functions = none
Group-D actual runtime use/nonuse = NOT_PROVEN
NO_VERSIONED_CALLER != RUNTIME_UNUSED
~~~

Freshness / invalidation events for this result include:

- any change to one of the 15 routine definitions/signatures/security modes/owners/search_path/ACLs;
- material change to relevant RLS/policies/direct-DML grants or helper authority;
- a new canonical caller for 4/5/7/12/13/14/15;
- a new trusted service contract for 14/15;
- Product Authority changing lifecycle/role/team semantics;
- implementation of any candidate disposition;
- material runtime/AppSec evidence that contradicts the current target assumptions.

No database, Auth, RLS, policy, grant, routine, data, runtime or production mutation was executed.


## 0.0000000000000000018 M1/M2 PROVENANCE HARDENING — CURRENT EVIDENCE AVAILABILITY — 2026-09-07

Product Authority authorized a bounded documentation-only provenance hardening after the read-only M1/M2 completeness audit.

Hardening base:

~~~text
FECH.AI main =
dd118baa89b68281bbd7c8df43c8e24c0e9b66bf

SES documentation-audit evidence ref =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e
~~~

Audit verdict carried into this hardening:

~~~text
CRITICAL M1/M2 DECISION DURABILITY = PASS
CURRENT STATE RECONSTRUCTIBILITY FROM GITHUB = PASS
PRODUCT AUTHORITY TRACEABILITY = PASS
RAW SPECIALIST SOURCE FORENSICS = PARTIAL
ROADMAP BLOCKER = NO
~~~

Bounded evidence additions:

~~~text
docs/security/evidence/M1_M2_PROVENANCE_MANIFEST.md
  -> central decision/source/fingerprint/reconstructibility manifest
  -> anti-noise repository admission policy

docs/security/evidence/2026-09-06-sts-m2-04c-c4-target-rls-dml-contract.md
  -> candidate standalone durable C4 target RLS/direct-DML contract
  -> closes the prior C4 structural documentation gap only after merge
~~~

Raw source packets are intentionally NOT bulk-versioned by this hardening.

Admission rule:

~~~text
RAW PACKET MAY ENTER GITHUB ONLY IF:
decision-grade unique evidence
+ provenance-bound
+ sanitized
+ non-duplicative
+ bounded

CHAT TRANSCRIPT / PROMPT / SALUTATION / TOOL CHATTER =
DO_NOT_VERSION
~~~

M1 final specialist verdicts remain durable but their historical MANUAL_COPY_PASTE source texts are not exact-hash-bound in the current record. Do not fabricate retroactive exactness.

M2-01/02/03, B1/B2, C2/C3 and D source packets retain their recorded hashes where available, but the canonical durable artifacts remain the operational authority.

This hardening changes evidence availability/documentation structure only. It does not change the current M2 roadmap state, any technical decision, implementation state, Supabase/runtime state or Security Go.

## 0.0000000000000000017 PR #189 MERGE / POST-MERGE CONTINUITY ANCHOR — 2026-09-07

~~~text
pre-merge approved head =
b7baa29dbbfeeaee78e423f7950ba17390fac0e2

merge commit =
13eec5a6b720d67ed29a1837a01502123547ccb6

canonical main after merge =
13eec5a6b720d67ed29a1837a01502123547ccb6

PR #189 =
MERGED / CLOSED

merge authorization =
EXPLICIT PRODUCT AUTHORITY / EXACT HEAD

review threads before merge =
4 / 4 RESOLVED

Vercel commit status after merge =
SUCCESS

GitHub Actions workflow runs observed on merge commit =
0
~~~

Final corrected E artifact now on canonical main:

~~~text
docs/security/evidence/2026-09-06-sts-m2-04e-architecture-synthesis-acceptance.md
blob = 07365cae5a353bd2407512ddde0d3d4cf880352f
~~~

SFJM blobs merged by PR #189 before this post-merge reconciliation:

~~~text
CURRENT_STATE.md = 5a177c12b2b1c6b26f9e46d1e220511e8f21bbc7
NEXT_SAFE_ACTION.md = 085c4391c3f5433670d5a53ebb45f05f1b86002b
BLOCKED_ACTIONS.md = 532c004f26930ecdaf65a48f68a9a746129d01c3
EVIDENCE_FRESHNESS.md = 082b6e1a917536d7354fb4862ae5d781c0c0074b
AUTHORIZATIONS.md = 4de33a38dd6d42ee6bd70d8b77d5f780c0e53acb
handoffs/CURRENT.md = 53ba34cc5132b513100e09862365f075587fb7b7
~~~

Those blobs correctly described the pre-merge lifecycle at the time they were reviewed, but their current-view sections became stale when PR #189 merged. Product Authority explicitly authorized this bounded SFJM post-merge documentation-only reconciliation.

Preserve evidence separation:

~~~text
MERGED != SUPABASE APPLIED
MERGED != RUNTIME TESTED
VERCEL STATUS SUCCESS != APPSEC PASS
VERCEL STATUS SUCCESS != SECURITY GO

implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
hostile/cross-tenant runtime assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

The next material program decision remains selection/definition of the next bounded STS-M2-04 action. M2-04F semantics remain not canonically defined.

## 0.0000000000000000016 HISTORICAL / SUPERSEDED — PR #189 PRE-MERGE POST-REVIEW CORRECTION EVIDENCE BOUNDARY — 2026-09-07

~~~text
correction parent head =
8f660bfcc753bb0f8012a823d5942e4528f441bb

corrected head =
RESOLVE LIVE AFTER COMMIT

main at correction admission =
aa266df3124f407a3f2c155c8f8ab5c193707783

mutation class =
DOCUMENTATION_ONLY
~~~

Fresh corrected material meaning:

~~~text
113 = B3/C3 ROUTINE SUBSET
113 != COMPLETE 137-ROUTINE UNIVERSE

historical C3 =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113 B3/C3 routines

B3/C3 subset projection after E =
70 target DEFINER
41 target INVOKER
0 target-authority semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 B3/C3 routines

B2 = separate accepted 15-routine slice with residuals
D = separate accepted 9-trigger-routine target classification
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED

031 =
DEFINER with ADMIN_LOCAL tenant/company branch
and GESTOR tenant/managed-team branch
ROOT / ADMIN_GLOBAL != automatic tenant list lifecycle authority

036 =
NON_MODE_LIFECYCLE / RETIRE_CURRENT_SEMANTICS
future replacement = NOT DEFINED BY E / NOT AUTHORIZED BY THIS PR

119 =
target INVOKER resolved in C3
current implementation remains postgres-owned SECURITY DEFINER
implementation/runtime assurance = NOT_PERFORMED
~~~

Prior exact-head review/pre-merge gates on 8f660bfcc753bb0f8012a823d5942e4528f441bb are invalidated by the correction commit. Fresh independent exact-head review is required on the corrected head.

~~~text
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
hostile/cross-tenant runtime assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

## 0.0000000000000000015 HISTORICAL / SUPERSEDED — PRE-CORRECTION STS-M2-04E SYNTHESIS WORDING — 2026-09-06

~~~text
acceptance base main =
aa266df3124f407a3f2c155c8f8ab5c193707783

SES evidence ref =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

durable E evidence =
docs/security/evidence/2026-09-06-sts-m2-04e-architecture-synthesis-acceptance.md

durable E Git blob =
6f6a9bd1f181dfcf34ab979284338e497fb09f61

MUTATION CLASS =
documentation-only

Supabase/runtime mutation =
NO
~~~

Material accepted result:

~~~text
C3 historical =
68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113

E superseding five-row target adjudication =
004 DEFINER
031 DEFINER
036 NON_MODE_LIFECYCLE / RETIRE_OR_REPLACE_CURRENT_SEMANTICS
047 INVOKER / tenant-team scoped
127 NON_MODE_LIFECYCLE / RETIRE_DEPRECATE / SELF-ONLY lot request

E aggregate =
70 target DEFINER
41 target INVOKER
0 semantic target-authority NOT_DETERMINED
2 NON_MODE_LIFECYCLE
113 inventoried routines
~~~

Material evidence consumed includes accepted B1/B3/C3/D artifacts, live Issue #133, versioned B4 list/team binding evidence, MesaCliente approval call/workflow evidence and the explicit Product Authority E acceptance.

Freshness is invalidated by a material Product Authority reversal or material drift in the five routine identities/contracts, Issue #133 authority boundary, list/team authority model, Mesa approval authority model, accepted B1/C/D target policy inputs, or evidence that changes the E target disposition.

~~~text
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
hostile/cross-tenant runtime assurance = NOT_PERFORMED
Security Go = NOT_GRANTED
~~~

The publication of this evidence does not prove current runtime compliance.

## 0.0000000000000000014 STS-M2-04D SPECIALIST PACKET + DURABLE ACCEPTANCE EVIDENCE — 2026-09-06

~~~text
M2-04D decision/evidence base =
e380387fe341dcf42527ce70ded45fd894447aa5

CURRENT FECH.AI main =
RESOLVE LIVE

SES evidence ref =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

Supabase target =
uobxxgzshrmbtjfdolxd / Discador-MesaCliente

specialist source =
Markdown(20260906-200207).md colado

specialist source SHA-256 =
6927b61338555fef95cc25892bb6097e815839b53bc217e0229084c5e5220389

specialist source bytes = 44144
specialist source Python splitlines() = 1165
specialist source newline count = 1164

durable evidence path =
docs/security/evidence/2026-09-06-sts-m2-04d-trigger-authority-classification.md

durable evidence Git blob =
7fdc63a95d81661598937aa0bdfa654bcb9db66a

final durable evidence SHA-256 =
NOT_INDEPENDENTLY_RECOMPUTED_INSIDE_ATOMIC_GIT_COMMIT
~~~

Accepted evidence result:

~~~text
9 / 9 trigger functions classified
18 / 18 trigger instances covered
TARGET DEFINER = 8
TARGET INVOKER = 1
TARGET NOT_DETERMINED = 0
DIRECT CLIENT EXECUTE REQUIRED = 0
NOT REQUIRED = 9
NOT_DETERMINED = 0
MATERIAL_DRIFT = NO
~~~

Freshness invalidation events include material change to any of the nine trigger function bodies, attached trigger definitions/enabled state, relevant function EXECUTE ACLs, effective owner/search_path, protected authority objects, accepted C/B dependencies, or Product Authority scope.

The absence of a second SHA-256 field is not an evidence gap: the source packet SHA-256 is independently verified provenance, and the exact durable repository object is content-addressed by its Git blob. A later SHA-256 may be recorded only if independently recomputed without creating a lifecycle documentation loop.

## 0.0000000000000000013 STS-M2-04C/C4 CONSOLIDATION PACKET + MASTER-PROJECT FINAL DELTA REVALIDATION — 2026-09-06

```text
uploaded artifact = Markdown(20260906-180503).md colado
artifact SHA-256 = 8bec01816fe72c0b9bb6605435b3f5e3cd537572929753fd93ab5949dc113125
artifact lines = 1107
artifact bytes = 108298
C4 verdict = COMPLETE
M2-04C verdict = COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS
```

Master Project independently revalidated before closure:

```text
FECH.AI main = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
PR #186 prior head = 59f2ebad1551bb430569c346a4e53aa34a9028ac
material drift = NO

004 / 031 / 036 / 047 / 127 = live signatures present; current mode SECURITY DEFINER / owner postgres
119 relatorio_fornecedor(uuid) = live SECURITY DEFINER / owner postgres
119 target authority = INVOKER / accepted from C3
```

C4 preserves the accepted C3 projection:

```text
68 DEFINER
40 INVOKER
5 NOT_DETERMINED
TOTAL 113
```

Coverage discipline:

```text
C4 = consolidation against accepted C1/C2/C3 evidence
repository-wide reread = NOT_PERFORMED
full 113-routine live re-audit = NOT_PERFORMED
critical residual/live surface = PARTIAL_READ / proportional revalidation
```

The five unresolved modes are explicit bounded authority decisions, not missing C4 coverage. M2-04C closure is invalidated only by material drift in the accepted C1/C2/C3 contracts, the five residual routine bodies/authority requirements, 119 target-mode evidence, or Product Authority scope.


## 0.0000000000000000012 STS-M2-04C/C3 SPECIALIST PACKET + MASTER-PROJECT DELTA REVALIDATION — 2026-09-06

```text
source upload = Markdown(20260906-174939).md colado
source SHA-256 = 0e6c40a3cd515219fb6b24d5f0aaf10e63291d19da485d5e946c47fbb08d88d5
source lines = 761
source bytes = 150441
versioned C3 evidence = docs/security/evidence/2026-09-06-sts-m2-04c-c3-routine-mode-adjudication.csv
versioned rows = 57
versioned content SHA-256 = cdc028d5874d4e7f2c783e9380def40373ed525fec89514f1becd073f36027ab
versioned Git blob = 716c23d5f549eb465f3393cdfc5989dda82b69a7
C3 verdict = COMPLETE WITH RESIDUAL NOT_DETERMINED / READY FOR C4
```

The uploaded artifact contains the preceding C2 continuity plus the C3 result; C3 itself contains exactly 57 adjudication rows.

Master Project independently revalidated:

```text
FECH.AI main = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
PR #186 head before C3 reconciliation = be403e92b92e564ed970d9cb3aa0bff27322890b
material drift = NO

57 target signatures remain live
57/57 current mode = SECURITY DEFINER
57/57 current owner = postgres
one additional avaliar_lista(uuid,integer,text) overload exists outside the C3 set and does not invalidate the four-argument C3 identity
```

Discriminating live bodies were proportionally re-read for C3 mode decisions including 044, 054, 107–109, 119, 126, 127 and 137. Versioned B3 evidence independently confirms `solicitar_lote(uuid)` remains a separately accepted target DEFINER privileged allocation boundary; therefore adjudicating `solicitar_lote_core(uuid)` as INVOKER does not transfer allocation DML authority to the ordinary caller.

C3 aggregate integrity independently checked:

```text
DEFINER = 16
INVOKER = 36
NOT_DETERMINED = 5
16 + 36 + 5 = 57

projected B3:
68 DEFINER + 40 INVOKER + 5 NOT_DETERMINED = 113
```

All C3 INVOKER targets carry CALLER_AUTHORITY_SUFFICIENT = YES in the specialist matrix. All C3 DEFINER targets carry PRIVILEGED_BOUNDARY_REQUIRED = YES.

Residual invalidators include material drift in any of the 57 routine bodies/modes/owners, relevant caller ACLs/RLS/policies, lower privileged callees, B3 authority contracts, or Product Authority scope decisions for the five unresolved rows.


## 0.0000000000000000011 STS-M2-04C/C2 SPECIALIST PACKET + MASTER-PROJECT DELTA REVALIDATION — 2026-09-06

```text
specialist packet = Markdown(20260906-172407).md colado
SHA-256 = ccf108437f1d84ceac29095ecb1f86a3a63c64d5278d8eb17c02588d3a633afa
lines = 505
bytes = 78213
specialist verdict = COMPLETE WITH RESIDUAL EVIDENCE GAPS / READY FOR BOUNDED C3
```

Anchors independently revalidated:

```text
FECH.AI main = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase project = uobxxgzshrmbtjfdolxd
material drift = NO
```

Material live claims delta-revalidated by Master Project:

```text
postgres.rolbypassrls = true
service_role.rolbypassrls = true
authenticated.rolbypassrls = false
anon.rolbypassrls = false
12 named policy helpers = SECURITY DEFINER / owner postgres
9 authenticated direct-write tables = revalidated
blocker bodies 004/031/036/047/119/127 = proportionally re-read live
pme_message_usage RPC-centered append-only authority = versioned on current main
```

Coverage correction:

```text
BRANCH_OR_COMMIT_REF_RESOLUTION != INTEGRAL_READ_OF_REPOSITORY
```

The B3 CSV remains PARTIAL_READ for C2 because the 57-row unresolved dependency subset was consumed rather than the 113-row classification being replayed. This is acceptable for C2.

C2 evidence is invalidated by material changes to helper bodies/modes/owners/ACLs, table ACL/RLS/policies, relevant blocker bodies, the B3 unresolved set or Product Authority scope.


## 0.0000000000000000010 STS-M2-04C / C1 LIVE RLS-DML EVIDENCE — 2026-09-06

Evidence anchors at C1 execution:

```text
FECH.AI main = ca30c70e505a9dd8398cd7dace067c95397f96fe
SES main = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
Supabase project = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
B3 CSV blob = cf3baa6e5a6ab6465688de8f6af43cba7c27d3bd
B3 canonical matrix fingerprint = e609f4fa3bc6d21b8c75d85bd2a4a3409e9ece8b3c4d66ffdb5e52055052a61d
```

Live C1 observations:

```text
public tables = 44
RLS enabled = 44 / 44
FORCE RLS = 30 / 44
FORCE RLS false = 14 / 44
anon with any direct table privilege = 0
authenticated with SELECT = 28
authenticated with INSERT/UPDATE/DELETE on at least one operation = 9
```

Observed `FORCE RLS = false` tables:

```text
mesa_cliente_desconto_politicas
mesa_cliente_fluxo_operacoes
mesa_cliente_fluxo_parcelas
mesa_cliente_politica_premio_faixas
mesa_cliente_politicas_financeiras
mesa_cliente_unidade_enriquecimentos
mesa_fluxo_pagamentos_canonico
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_lead_message_state
pme_message_templates
pme_message_usage
root_audit_logs
```

Observed authenticated direct-write tables:

```text
lista_avaliacoes
logs
mesa_cliente_unidade_enriquecimentos
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_lead_message_state
pme_message_templates
pme_message_usage
```

Material helper/role observations:

```text
central policy helpers observed SECURITY DEFINER = YES
central helper owner = postgres
postgres.rolbypassrls = true
```

The canonical B3 matrix was parsed as 113 rows × 40 columns and contains exactly 57 `TARGET_SECURITY_MODE = NOT_DETERMINED` rows for C2/C3 dependency analysis.

C1 evidence is point-in-time live catalog evidence. It is invalidated proportionally by material changes to RLS/FORCE RLS, table ACLs, policy roles/USING/WITH CHECK, helper bodies/modes/owners/ACLs, relevant routine bodies/call graph, B3 matrix identity or Product Authority scope.

```text
RLS ENABLED != POLICY CORRECT
FORCE RLS != DEFINER BODY GOVERNED BY RLS
GRANT EXISTS != BUSINESS AUTHORITY PROVEN
C1 INVENTORY COMPLETE != M2-04C COMPLETE
STATIC/CATALOG COMPOSITION != RUNTIME ASSURANCE
```


## 0.0000000000000000009 PR #183 MERGE RATIFICATION / PROVENANCE EXCEPTION EVIDENCE — 2026-09-06

Current lifecycle anchors independently re-resolved before reconciliation:

```text
FECH.AI main = 53a70f814e8b695439358ebe609850f25bf636a9
PR #183 = CLOSED / MERGED
PR #183 base = 0333cea749dc33a6040955077afe67bd22c2fbe9
PR #183 final head = d805194c5f896766af24e4d4a56869c91d31a60c
merge commit = 53a70f814e8b695439358ebe609850f25bf636a9
merged by = wagnerjfjunior
three P2 review threads = RESOLVED
final head Vercel status = SUCCESS
```

Authority evidence at the merged final state explicitly permitted a new exact-head pre-merge while preserving `merge = NOT_AUTHORIZED`. No separate merge authorization was recovered before the merge event. Product Authority subsequently ratified the merged state on 2026-09-06.

Evidence interpretation:

```text
MERGE OCCURRED = PROVEN
PRE-MERGE LIFECYCLE AUTHORITY = AUTHORIZED
MERGED STATE NOW RATIFIED = PRODUCT_AUTHORITY_DECISION
RETROACTIVE MERGE-AUTHORIZATION CLAIM = PROHIBITED
AUTHORITY/LIFECYCLE PROVENANCE EXCEPTION = CURRENT
```

This provenance exception does not invalidate the canonical DEF55 matrix fingerprint `e609f4fa3bc6d21b8c75d85bd2a4a3409e9ece8b3c4d66ffdb5e52055052a61d` or the accepted 113/113 classification. Freshness of B3 technical evidence remains governed by the invalidators recorded in the preceding B3 evidence entry.


## 0.0000000000000000008 STS-M2-04B3 / DEF55 REVISED CANONICAL EVIDENCE — 2026-09-05

Current recoverable canonical matrix:

`docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv`

```text
rows = 113
columns = 40
SHA-256 = e609f4fa3bc6d21b8c75d85bd2a4a3409e9ece8b3c4d66ffdb5e52055052a61d

target mode = 52 DEFINER / 4 INVOKER / 57 NOT_DETERMINED
justification = 52 PROVEN_BY_BODY_CONTRACT / 6 NOT_PROVEN / 51 NOT_DETERMINED / 4 NOT_REQUIRED
blockers = 004,031,036,047,119,127
```

Historical fingerprints retained for provenance:

```text
original specialist baseline = 3abd2d09d4d17a0584a982c8fc6926a0266e4385883454a046f085f59f04a889
pre-DEF55 consolidated matrix = df2a76d34b07edc347f84acbb7c71bad71be61095a7e40919c869925cc0b31eb
five-row adjudication delta = 4695593f7e3c5e4e72ecf415d8b0cc19e6cb9c93583e89504e522ac9e6297c59
```

The previous `55/2/56` aggregate and df2a76d34b07edc347f84acbb7c71bad71be61095a7e40919c869925cc0b31eb fingerprint are historical and superseded by this revised canonical entry. Freshness is invalidated by any material change to B3 routine identity/body, authority mode, owner/search_path, EXECUTE ACL, caller/provenance, direct/transitive effects, relevant RLS/direct-DML composition or Product Authority scope.

## 0.0000000000000000007 HISTORICAL — ORIGINAL STS-M2-04B3 ACCEPTANCE EVIDENCE / SUPERSEDED BY 0.0000000000000000008 — 2026-09-05

Canonical durable artifact after merge:

`docs/security/evidence/2026-09-05-sts-m2-04b3-remaining-routine-authority-classification.md`

Decision/evidence anchors:

- FECH.AI Product Authority acceptance main = `0333cea749dc33a6040955077afe67bd22c2fbe9`;
- SES evidence ref = `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`;
- specialist report SHA-256 = `b74d0f2d8b3655e0d04860743fe45ee54ecf234b8778a6f573e39ae9a4b39320`;
- 113-row matrix CSV SHA-256 = `3abd2d09d4d17a0584a982c8fc6926a0266e4385883454a046f085f59f04a889`;
- final five-row adjudication-delta SHA-256 = `4695593f7e3c5e4e72ecf415d8b0cc19e6cb9c93583e89504e522ac9e6297c59`;
- final coverage = `113 / 113`;
- target mode = `55 DEFINER / 2 INVOKER / 56 NOT_DETERMINED`;
- Security Go = `NOT_GRANTED`.

The final delta supersedes only B3 rows `031`, `036`, `047`, `119`, `127` and the aggregates affected by those corrections. Other `108 / 108` B3 rows remain unchanged.

Freshness invalidators include material changes to any B3 routine body/signature, security mode, owner, search_path/proconfig, EXECUTE ACL, canonical caller/provenance, direct/transitive authority, relevant RLS/direct-DML composition, or Product Authority scope.

Preserve:

```text
CLASSIFICATION COMPLETE != CURRENT AUTHORITY SAFE
TARGET_MODE_NOT_DETERMINED != TARGET_INVOKER
OWNER postgres OBSERVED != TARGET OWNER ACCEPTED
search_path PRESENT != search_path SAFE
STRUCTURALLY OBSERVED CONTROL != CONTROL PROVEN EFFECTIVE AT RUNTIME
```

## 0.0000000000000000006 STS-M2-04B2 ACCEPTANCE EVIDENCE / DURABLE PROVENANCE — 2026-09-05

Canonical durable artifact once merged:

`docs/security/evidence/2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md`

Decision anchors:

- FECH.AI decision/base main = `ca77d81c3d2a6209536664128bda209996a7f423`;
- SES continuity ref = `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`;
- Backend/Data packet = `FECHAI-STS-M2-04B2-HIGH-RISK-ROUTINE-AUTHORITY-CLASSIFICATION`;
- user-supplied specialist-result SHA-256 = `36f90006d772404cd8d2fd297a2a70ab2ff452f8b1b17491a734f7cff68cb2ad`;
- exact B2 scope = 15 routines;
- Product Authority status = `COMPLETE / ACCEPTED WITH RESIDUALS`;
- Security Go = `NOT_GRANTED`.

Accepted live/catalog evidence is point-in-time and bounded to the exact B2 classification surface. It includes current SECURITY DEFINER/owner/search_path/EXECUTE facts used by the specialist result and Master Project adjudication. It does not establish runtime exploitability, hostile-client PASS, cross-tenant PASS, search-path semantic safety or current implementation compliance with the B1 target.

Freshness invalidators include material changes to any of the 15 routine bodies/signatures, security mode, owner, proconfig/search_path, EXECUTE ACL, canonical callers, direct dependencies, relevant RLS/direct-DML authority, trusted service-runtime evidence, runtime-negative evidence or Product Authority scope.

Preserve:

```text
NO_VERSIONED_CALLER != RUNTIME UNUSED
UNUSED_CANDIDATE != PROVEN UNUSED
CALLER FOUND != EXECUTE SHOULD BE ADDED
service_role EXECUTE != SERVICE_ONLY PROVEN
DEFINER JUSTIFICATION NOT_PROVEN != AUTHORIZED CHANGE TO INVOKER
STATIC/CATALOG CLASSIFICATION != RUNTIME ASSURANCE
```

## 0.0000000000000000005 STS-M2-04B1 ACCEPTANCE EVIDENCE / DURABLE PROVENANCE — 2026-09-05

Canonical durable artifact once merged:

`docs/security/evidence/2026-09-05-sts-m2-04b1-routine-authority-policy.md`

Decision/evidence anchors:

```text
FECH.AI decision-anchor main = ca77d81c3d2a6209536664128bda209996a7f423
SES specialist-result ref = a31e10cc3f0d1278c53c49e38151854d36ee9f3e
specialist packet = FECHAI-STS-M2-04B1-ROUTINE-AUTHORITY-POLICY-CORE
specialist result SHA-256 = 8171310f4101831ba34623dac9aff37b13e04aeb02f81808fc163d693cf801bf
Product Authority decision = COMPLETE / ACCEPTED WITH RESIDUALS
```

Accepted target semantics include `SECURITY DEFINER = PRIVILEGED EXCEPTION`, INVOKER as the preferred default when caller authority is deliberately sufficient, and the combined caller/class/EXECUTE/security-mode/owner/tenant-role/side-effect/transitive-authority contract.

Freshness invalidators are evidence-specific: material change to the accepted B1 target policy; routine signature/security-mode/owner/search_path/ACL drift relevant to downstream classification; caller/provenance drift; grants/default-principal semantics; Product Authority scope change; or new runtime evidence material to a claim.

Current per-routine compliance and hostile-client/cross-tenant runtime effectiveness remain `NOT_DETERMINED`. B1 acceptance is not a runtime or Security Go PASS.


## 0.0000000000000000004 STS-M2-03 ACCEPTANCE EVIDENCE / DURABLE PROVENANCE — 2026-09-05

Canonical durable artifact once merged:

`docs/security/evidence/2026-09-05-sts-m2-03-index-acl-contradictions.md`

Decision anchor:

- FECH.AI main = `682837dab2c719330c2e6e72e885ed6de5e2f171`
- SES main = `285b08206d334971b182e2d46646ba0b6938bdfe`
- Supabase project = `uobxxgzshrmbtjfdolxd`
- Backend/Data evidence SHA-256 = `b5a41bf04495ee9783cd70a1d08926611c8c78ecfb644f6178fba161207cb52f`

Final specialist results:

- `BACKEND_DATA_RECOMMENDS_STS_M2_03_ACCEPTANCE_WITH_RESIDUALS`
- `ARCHITECTURE_RECOMMENDS_STS_M2_03_ACCEPTANCE_WITH_RESIDUALS`
- `APPSEC_NOT_REQUIRED_FOR_STS_M2_03_ACCEPTANCE`

Fresh current live write-policy split is `14 / 32` with `13 latent/grant-blocked + 19 false-predicate`. Historical M2-02 `15 / 31` remains historical accepted evidence; cause of the difference is `NOT DETERMINED`.

Freshness invalidators include material index/catalog/statistics changes relevant to an index decision; grant/RLS/policy/MAINTAIN/default-privilege drift; relevant routine ACL/caller drift; new runtime evidence; or Product Authority scope changes.

`STRUCTURAL/CATALOG EVIDENCE != RUNTIME ASSURANCE`; Security Go remains `NOT_GRANTED`.


## 0.0000000000000000003 STS-M2-02 ACCEPTANCE EVIDENCE / DURABLE PROVENANCE — 2026-09-05

Canonical durable artifact once merged:

`docs/security/evidence/2026-09-05-sts-m2-02-database-authority-map.md`

Decision anchor:

- FECH.AI main = `afa92903bda1755241c1fea5d9fbb436f75231ca`
- SES main = `285b08206d334971b182e2d46646ba0b6938bdfe`
- Supabase project = `uobxxgzshrmbtjfdolxd`
- Issue #141 = OPEN

Supplied specialist evidence fingerprints:

- Backend/Data SHA-256 = `cc671280dc044f4d330c131dc5854b5aec19ebaadf7a2ff64da43bb62a33cb6b`
- Architecture SHA-256 = `741014b5b75a8b1416b93c4e8af17d7024945a608f406cbe9428b6552e30a703`
- AppSec SHA-256 = `6a69557f53df293be1f6e7364b5a8a581cf67ec5a95f2cc6f53fc795eda96a52`

Evidence layers remain distinct:

- Backend/Data = live-catalog READ_ONLY + canonical GitHub static/caller evidence;
- Architecture = independent READ_ONLY architecture adjudication;
- AppSec = independent READ_ONLY security adjudication, no active adversarial production testing;
- Product Authority = final STS-M2-02 acceptance with residuals.

Freshness invalidation events include material changes to routines, policies, triggers, grants, RLS, role/default privileges, callers, production catalog, runtime evidence, or Product Authority scope.

Absent material contradiction, do not reopen STS-M2-01, the 160-routine universe, the 137 SECURITY DEFINER inventory, resolved `59/57/56/8` metrics, or the `137/137` static caller-provenance closure.

`STRUCTURALLY OBSERVED CONTROL != CONTROL PROVEN EFFECTIVE AT RUNTIME`; Security Go remains `NOT_GRANTED`.


## 0.0000000000000000002 STS-M2-01 DURABLE PROVENANCE CORRECTION — 2026-09-04

Canonical accepted evidence artifact:

```text
docs/security/evidence/2026-09-04-sts-m2-01-database-canonicality-matrix.md
```

It preserves:

- the 44 row-level final canonicality assignments;
- exact FECH.AI/Supabase target identifiers;
- exact GitHub evidence blobs used for the planning label, PR-07 +1 table delta and MesaCliente shadow transition;
- SHA-256 fingerprints of the upstream Backend/Data and Architecture operating-session reports;
- independent Master Project live revalidation summary and capture window;
- residual evidence obligations for `logs`, `mesa_fluxo_pagamentos_canonico` and `templates_mensagens`.

This closes the post-PR-174 finding that generic evidence-class labels were insufficient durable provenance.

Freshness invalidation remains evidence-specific: material database/catalog drift, migration changes, changed callers/authority, or later accepted M2 evidence may require proportional revalidation.

## 0.0000000000000000001 STS-M2-01 ACCEPTANCE EVIDENCE — 2026-09-04

```text
decision anchor main = 252fb981bba4fb410136fd34cb29b9f2d0e057f8
Issue #141 = OPEN
live public-table universe independently revalidated = 44
three final delta tables present live:
  public.logs
  public.mesa_fluxo_pagamentos_canonico
  public.templates_mensagens

Phase A evidence class = UPSTREAM LIVE_DATABASE_AUDIT / READ_ONLY
Phase B evidence class = ARCHITECTURE_READ_ONLY + versioned GitHub evidence + upstream live DB evidence
final delta = ARCHITECTURE_RECOMMENDS_M2_01_FINAL_ACCEPTANCE
Product Authority acceptance = GRANTED
```

Final accepted matrix:

```text
KEEP 40
INTERNAL 4
CONSOLIDATE 0
RETIRE 0
REMODEL 0
TOTAL 44
NOT_DETERMINED 0
```

Important freshness boundaries:

- the WBS "43 tables" remains the historical/planning label; current live scope is 44;
- `public.importar_leads_batch_idempotency` explains the +1 table-count delta;
- current KEEP on `logs`, `mesa_fluxo_pagamentos_canonico` and `templates_mensagens` carries explicit residual proof obligations;
- future M2 evidence may support a different target disposition, but only through a separately evidenced and authorized gate;
- no M2-02 catalog map, implementation, runtime equivalence, Security Go or production readiness is established by M2-01 acceptance.

## 0.000000000000000000 PROGRAM HIERARCHY / CORE DoD ADJUDICATION EVIDENCE — 2026-09-04

```text
FECH.AI base main = 2bad8e9c3d6d6e091a6416c556e793eb1b24e0ec
PR #170 pre-correction head = 6df2fbef7425c0a6ebc105fbc910d8379bd6218a
Issue #141 = OPEN / Security-to-Scale 2026
B0 baseline = immutable historical comparison source
program hierarchy BCR = docs/governance/2026-09-04-fechai-bcr-security-to-scale-program-hierarchy-core-dod.md
current WBS target = docs/roadmap/fechai-security-to-scale-2026-wbs.md
```

Adjudicated conflict:

```text
UNQUALIFIED M1..M6 = AMBIGUOUS ACROSS PRODUCT MODULES / B0 / SECURITY-TO-SCALE
B0 governance index = STALE FOR CURRENT EXECUTION AUTHORITY
PR #170 previous LEGACY/HISTORICAL roadmap banner = TOO BROAD
WBS M4 Discador/PME representation = SEMANTICALLY UNDER-SPECIFIED
FINAL PROFESSIONAL AS-BUILT = REQUIRED BUT UNDER-SPECIFIED IN PRE-CORRECTION WBS
```

Coverage basis at the unchanged FECH.AI main/ref includes the integral reconstruction of:

- FECH.AI bootstrap, governance and SFJM authority model;
- B0 baseline/control model and its BCR requirement;
- Issue #141 program contract;
- product module map and Roadmap Mestre;
- A1/A2 AS-IS architecture baseline;
- LeadOps/CRM/Discador product evidence;
- Power Message Engine and Discador Flow specifications;
- MesaCliente project-local specialist/architecture evidence;
- SRE/observability/runbook requirements;
- SES Project Adapter/adoption/certification/current manual handoff semantics;
- StopJuniorMode/SFJM session-transition and canonicality protocol;
- sfjm-workspace main plus PR #27 candidate representation.

Resolution proposed by PR #170 correction:

```text
B0 = immutable historical comparison baseline
Issue #141 = current core-completion program contract
Security-to-Scale WBS = current granular execution baseline on main
qualified namespaces = PRODUCT_MODULE_* / B0-* / STS-*
M4 core slices = CRM/Funil + LeadOps Execution/Discador/PME + MesaCliente
M6 = Security evidence + professional AS-BUILT + operational readiness
```

Candidate PR evidence does not become canonical until merge. M1 deferred evidence remains frozen, not waived and not PASS.

## 0.00000000000000000 POST-PR-09 freshness / handoff anchor — 2026-09-04

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

Fresh lifecycle evidence:

- GitHub live resolved PR #168 as merged.
- merge/main commit: `4ede55dfe63b5da342e53b125e85068980090c82`.
- the five SFJM files in this reconciliation are continuity-only and do not alter product/runtime state.
- older `PR-09 = Draft / Not merged` text remains historical provenance below and is superseded by this top override.

Freshness rule for deferred J4 evidence remains unchanged: do not refresh or reinterpret it merely
because M2 starts.

## 0.0000000000000000 M1 close-out / deferred assurance evidence state — 2026-09-04

Decision anchor: `f4ff8e42f601a1e033ae6ceaf4c5ecd17b23f3a8`.

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

Evidence classification:

- PR-08 static harness and its merged lifecycle remain historical/versioned evidence.
- Canonical PR-08 runtime receipts remain unexecuted for the deferred environment-dependent set.
- `IMP-003 = NOT_DETERMINED`.
- `ROLLBACK_REAPPLY = NOT_DETERMINED`.
- operating-session evidence remains bounded continuity evidence only.
- no deferred result is promoted to `PASS`.
- `SECURITY_GO = NOT_GRANTED`.

Freshness rule: do not reopen the deferred evidence merely because M2 starts. Reopen only after the
three-part Supabase Pro / isolated non-production / explicit Product Authority execution trigger, or
on a material contradiction affecting the underlying security assumptions.

## 0.000000000000000 POST-MERGE / POST-DEPLOY FRESHNESS — PR #166 — 2026-09-03

```text
repository: wagnerjfjunior/fecha.ai
main: 59262ef7cbbc3d29d6c4693c2b339964d6f806aa
PR #166: CLOSED / MERGED
pre-merge reviewed head: e92d97044ac753f9c71aad7fc37207fa355a2d1c
merge commit: 59262ef7cbbc3d29d6c4693c2b339964d6f806aa
main compare against merge commit: IDENTICAL
Vercel UI supplied by Product Authority: Production / Ready / main / 59262ef
GitHub combined status for exact merge commit: Vercel = SUCCESS
VERCEL_PRODUCTION_DEPLOY = READY/SUCCESS
```

Deployment Ready/SUCCESS proves the Vercel deployment lifecycle event for the merge commit.
It does not prove PR-08 runtime execution, Supabase application, rollback/reapply, OC-01,
PR-09 or Security Go.

```text
Phase 1 = CLOSED STATICALLY
Phase 2 = CLOSED STATICALLY
Phase 3 = CLOSED
Phase 4 = CLOSED
PR08-RR-64M-CANONICAL-HASH = ACCEPTABLE WITH RESIDUAL RISK
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
PR-08 runtime = NOT_EXECUTED
SECURITY_GO = NOT_GRANTED
```

Residual freshness invalidators: ENOBUFS/maxBuffer or equivalent capture failure; fixture
growth toward the practical envelope; large/uncontrolled dataset use; inability to complete
rollback/cleanup evidence; or hashing implementation change.

Next refresh: the separately authorized READ_ONLY reconstruction of the next J4/F1-02 gate.

## 0.00000000000000 Phase 1 implementation evidence — SQL execution authority — 2026-09-03

Parent: `98da96da8d20964b9618c72407f34598116b4f46`.

Bounded static implementation target:

- dedicated SQL-runtime wrapper;
- exact affirmative runtime and production authorization;
- connection-derived project binding plus SQL-side psql `HOST` defense;
- claimant RPC exact success/count proof before rollback;
- positive synthetic lead, completed idempotency claimant and `import_batch` audit evidence before rollback;
- post-rollback scoped residue verification;
- validator anti-regression coverage.

Targeted threads remain OPEN / NOT_RESOLVED pending independent exact-head review:

`PRRT_kwDOSEToMc6fBXG5`
`PRRT_kwDOSEToMc6fBXG9`
`PRRT_kwDOSEToMc6fBXHB`

Execution evidence created by this event: NONE.

Preserved: `IMP-003 = NOT_DETERMINED`, `ROLLBACK_REAPPLY = NOT_DETERMINED`, `SECURITY_GO = NOT_GRANTED`, runtime results `NOT_EXECUTED`.

## 0.0000000000000 Current evidence — PR #166 Ready + pre-merge governance reconciliation — 2026-09-03

Exact reviewed PR state before this documentation-only correction:

```text
repository: wagnerjfjunior/fecha.ai
PR: #166
branch: test/f1-02-negative-security-matrix
base: 9d05c64281c2aeeae9d67b139eab674720184fb1
exact head: 0f3f266cb2ed103e6acda7bb03b9934cd30f1b41
state: OPEN / READY
draft: false
commits: 7
changed files: 9
mergeable: true
Vercel: SUCCESS
reviews: 0
review threads: 0
head changed during Ready transition: NO
```

Evidence classification:

- PR/GitHub lifecycle state above: LIVE_GITHUB_READ;
- exact-head PR-08 v7 implementation review: PASS;
- pre-merge technical/security finding at `0f3f266cb2ed103e6acda7bb03b9934cd30f1b41`: NO NEW BLOCKER;
- pre-merge governance finding: `PR166-PREMERGE-SFJM-001`;
- finding classification: REQUIRED IN THIS PR;
- finding type: GOVERNANCE / CONTINUITY ONLY;
- reason: stale SFJM lifecycle instructions remained after a later Product Authority Ready authorization.

No technical/security finding was reopened in matrix v7, HTTP harness, validator, rollback architecture or runtime SQL.

Historical closed findings remain AUDIT_LOOP_BLOCKED absent new exact-head contradiction:

- `PR166-J4-V5-OBSERVABILITY-ORACLE-001`: CLOSED STATICALLY;
- `PR166-J4-V5-CANONICAL-RESTORE-002`: CLOSED STATICALLY.

Execution/evidence states remain:

- PR-08 runtime matrix: NOT_EXECUTED;
- Auth matrix: NOT_EXECUTED;
- SQL runtime: NOT_EXECUTED;
- rollback/reapply: NOT_EXECUTED / `ROLLBACK_REAPPLY = NOT_DETERMINED`;
- production smoke: NOT_EXECUTED;
- Supabase/Auth mutation: NONE;
- `IMP-003 = NOT_DETERMINED`;
- `SECURITY_GO = NOT_GRANTED`.

Additional bounded evidence gaps / residual metadata:

- main branch-protection configuration: NOT_READ — GitHub integration returned `403 Resource not accessible by integration`; no inference is made about presence or absence of branch protection;
- PR body exact-anchor / Ready wording: STALE METADATA — ACCEPTABLE WITH RESIDUAL RISK; GitHub live state and exact refs remain authoritative.

This documentation reconciliation creates no runtime PASS and no merge authorization.

## 0.000000000000 PR-08 sixth bounded correction — observer completeness v7 — 2026-09-03

Parent: `c2922bc952741202b8f57505db755d112bd47d82`.

Static implementation contract:
- matrix `fechai.f1-02.pr08.matrix.v7`;
- 98 records / 56 topology checks / 72 server case plans;
- observer identity binding preserved;
- ZERO_ROWS absence remains owner-side;
- own/foreign funnel-stage complete sets use `SERVER_ROW_IDS_EQUAL_VAR_SET`;
- generic validator forbids observer REST `ZERO_ROWS` / `ROW_IDS_EQUAL_VAR_SET`;
- no runtime/Auth/SQL/rollback/smoke execution;
- no Supabase/Auth mutation;
- canonical restoration v6 remains unchanged and closed for this scope.

Residual states remain `IMP-003 = NOT_DETERMINED`, `ROLLBACK_REAPPLY = NOT_DETERMINED`, `SECURITY_GO = NOT_GRANTED`.

New exact head must be resolved after publication; no PASS/Ready is implied by this implementation event.

## 0.00000000000 PR-08 fifth bounded root-invariant correction — v6 static closure — 2026-09-03

Parent exact head:

    68481f1cfc900be8b2172871b60dd56a27f07c5f

Material findings being corrected:

    PR166-J4-V5-OBSERVABILITY-ORACLE-001
    PR166-J4-V5-CANONICAL-RESTORE-002

Static target contract:

    matrix schema: fechai.f1-02.pr08.matrix.v6
    records: 98
    topology checks: 56
    server case plans: 72

Observer closure:

    EVIDENCE_OBSERVER_TOKEN -> global /auth/v1/user identity binding
    valid-token bindings -> validator-enforced across request/probe/topology surfaces
    INVALID_TOKEN / EXPIRED_TOKEN -> explicit negative-token fixtures only
    no-profile / zero-stage-company absence -> owner-side SERVER_ZERO_ROWS_BY_UUID
    owner-side absence channel -> existing non-production postgres/BYPASSRLS preflight

Restoration closure:

    HTTP cleanup global fingerprint
      = canonical public ordinary/materialized relation multisets
      + public sequence last_value/is_called as text
      + stable SHA-256

    rollback/reapply state fingerprint
      = schema-only pg_dump SHA-256 with fixed restrict key
      + canonical public data/sequence SHA-256

No runtime evidence is created by this correction.

    runtime matrix: NONE
    Auth matrix: NONE
    rollback/reapply execution: NONE
    production smoke: NONE
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

Next evidence action after publication:

    resolve the new PR #166 exact head
    perform one independent exact-head implementation review
    stop before Ready

## 0.0000000000 PR-08 fourth bounded anti-loop closure correction — 2026-09-03

Implementation-only event on parent head `c18347701b52ec21a3758cfbfa512871e10998dc`.

    scope: same 9 authorized PR-08 files
    mode: FORENSIC / EVIDENCE-BOUND / CONTRADICTION-FIRST / ANTI-LOOP
    matrix schema: fechai.f1-02.pr08.matrix.v5
    test records: 98
    topology checks: 55
    server lifecycle plans: 72
    mutation-capable HTTP cases: 71
    mutation-capable HTTP cases without lifecycle: 0
    negative unexpected-mutation cleanup: COVERED BY SERVER LIFECYCLE
    cleanup verification: SCOPED RESTORE + GLOBAL PUBLIC DATA SHA-256
    sequence restoration: REQUIRED
    ACL restoration: LIST ROW + COMPLETE ACL SET + AUDIT
    broker audit restoration: INCLUDED
    COR-011: CANONICAL T3 FLOW
    STG-001: TRUE NO-SESSION REQUEST
    FUN-006: CONDITIONAL / NOT_APPLICABLE WHEN RULES ABSENT
    postgres.rolbypassrls preflight: REQUIRED
    protected idempotency REST/client access: NONE
    runtime execution: NONE
    Auth execution: NONE
    rollback/reapply execution: NONE
    production smoke: NONE
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

Reusable closure rule extracted: mutation-capable security tests must carry isolation, topology authority proof, deterministic observation, deterministic cleanup and a whole-surface restoration check before batch execution is considered repeatable.

### Current next evidence action

    resolve the new PR #166 exact head
    perform one exact-head implementation review against the v5 closure invariants
    do not execute any PR-08 runner
    do not reopen previous correction classes unless contradicted by exact-head evidence

## 0.000000000 PR-08 third bounded harness correction evidence — 2026-09-03

Implementation-only event on parent head `718bf5371cde7b1243a852c497721badf0b5bba4`.

    scope: same 9 authorized PR-08 files
    protected idempotency REST/client access: REMOVED
    server evidence channel: PSQL postgres OWNER / NON-PRODUCTION ONLY
    server evidence production project: HARD_DENY
    grants/RLS/policies widening: NONE
    topology execution: GLOBAL + SELECTED CASE DEPENDENCIES ONLY
    stateful cases with server lifecycle: 20
    mutating HTTP cases without lifecycle: 0
    deterministic replay/mismatch/incomplete setup: VERSIONED
    per-case cleanup restoration: ORIGINAL SHA-256 REQUIRED
    rollback pg_dump restrict key: FIXED
    runtime execution: NONE
    Auth execution: NONE
    rollback/reapply execution: NONE
    production smoke: NONE
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

No runtime PASS is created by this correction. The owner-side channel is code/evidence architecture only and remains unexecuted under the standing NO LAB / NO SECOND PROJECT decision.

### Current next evidence action

    resolve the new PR #166 exact head
    perform exact-head implementation review
    do not execute any PR-08 runner

## 0.00000000 PR-08 second bounded harness correction evidence — 2026-09-03

Implementation-only event on parent head `e0b17d8c4c3d3d9c35952e3c934e325f92c1a1f5`.

    scope: same 9 authorized PR-08 files
    fixture topology preflight: VERSIONED / MANDATORY
    denial semantics: EXACT STATUS + EXPECTED ERROR EVIDENCE
    mutation probes: BOUND TO ACTUAL AT-RISK TARGETS
    positive semantics: VERSIONED CONTENT / DELTA ASSERTIONS
    import idempotency: LEAD + MARKER + LOG DELTAS
    explicit runner selection: REQUIRED; --all explicit only
    runtime execution: NONE
    Auth execution: NONE
    rollback/reapply execution: NONE
    production smoke: NONE
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

No J4 runtime PASS is created by this correction. Prior operating-session evidence remains bounded continuity evidence only.

### Current next evidence action

    resolve the new PR #166 exact head
    perform exact-head implementation review
    do not execute any PR-08 runner

## 0.0000000 PR-08 bounded harness correction evidence — 2026-09-03

Implementation-only event on parent head `f69f0b5628894d3e74efefc16f02cdfa60877945`.

    scope: same 9 authorized PR-08 files
    request/probe specs: VERSIONED_IN_MATRIX
    fixture role: VALUES_AND_SECRETS_ONLY
    HTTP target binding: FAIL_CLOSED
    mutation evidence: BEFORE_AFTER_CANONICAL_SHA256
    migration provenance: EXACT_BLOB + TRUE_FINAL_GIT_COMMIT
    concurrency evidence: PER_REQUEST_TIMING + POSITIVE_OVERLAP_REQUIRED
    rollback evidence: ONE_CASE + INITIAL/ROLLBACK/REAPPLY STATE HASHES
    runtime execution: NONE
    Auth execution: NONE
    rollback/reapply execution: NONE
    production smoke: NONE
    IMP-003: NOT_DETERMINED
    ROLLBACK_REAPPLY: NOT_DETERMINED
    SECURITY_GO: NOT_GRANTED

No J4 runtime/ROL PASS is created by this correction. The prior 33 operating-session results remain bounded continuity evidence only.

### Current next evidence action

    resolve the new PR #166 exact head
    perform exact-head implementation review
    do not execute any PR-08 runner

## 0.000000 Current J4 / PR-08 implementation evidence override — 2026-09-03

This is a versioned-harness implementation event, not runtime evidence.

```text
repository: wagnerjfjunior/fecha.ai
implementation base: 9d05c64281c2aeeae9d67b139eab674720184fb1
branch: test/f1-02-negative-security-matrix
PR-08 harness records: 98
security/runtime records before ROL/PRD: 85
ROL records: 11
PRD records: 2

IMPLEMENTATION_STATUS:
  VERSIONED_HARNESS / NOT_EXECUTED

RUNTIME_MATRIX:
  NOT_EXECUTED

AUTH_MATRIX:
  NOT_EXECUTED

ROLLBACK_REAPPLY:
  NOT_DETERMINED / NOT_EXECUTED

IMP-003:
  NOT_DETERMINED / NOT_EXECUTED

PRODUCTION_SMOKE:
  NOT_EXECUTED BY PR-08 IMPLEMENTATION

SECURITY_GO:
  NOT_GRANTED
```

Prior 33 operating-session STG/IMP/FDB results remain bounded continuity
evidence only and are referenced from `matrix.json`; they are not promoted to
canonical PR-08 receipts.

The implementation reuses exact existing B2/B3/B4/PR07 proof blobs rather than
copying them. Rollback records bind eleven exact migration artifacts; ROL-001
uses the versioned embedded exact rollback block and ROL-002..011 bind separate
rollback artifacts.

No Supabase/Auth/Vercel/runtime/rollback call is authorized or evidenced by
this section.

### Current next evidence action

```text
OPEN PR-08 AS DRAFT
THEN STOP
NEXT GATE = EXACT-HEAD IMPLEMENTATION REVIEW
```

## 0.00000 Current J3/PR-07 operating-session runtime evidence override

This section is the current evidence-freshness authority for the J3/PR-07
runtime results accepted by the Product Authority bounded-residual exception.
It supersedes older B4/PR-06 next-evidence wording below where it conflicts,
while preserving that older material as lineage.

Decision/program anchor:

```text
repository: wagnerjfjunior/fecha.ai
decision anchor main: 1449bee4b708a9211a099c52ff573cf52d44ef1c
PR #163: CLOSED / MERGED
PR-07 migration ledger version: 20260902225240
PR #165: documentation reconciliation lifecycle
```

### Evidence class and provenance

```text
EVIDENCE_CLASS:
  OPERATING_SESSION_RUNTIME_EVIDENCE

RAW_PER_CASE_EXECUTION_RECEIPT:
  NOT_VERSIONED

CANONICAL_EXECUTABLE_PR08_RECEIPT:
  NOT_ESTABLISHED

SOURCE_RUNTIME_PLAN:
  supabase/tests/f1-02-pr07/funnel_reads_crm_payloads.sql

SOURCE_RUNTIME_PLAN_BLOB:
  55bef23b5a7103e9935ca6eb63a066d3db23dc6e

SOURCE_RUNTIME_PLAN_STATUS:
  runtime cases remain textually NOT_EXECUTED in that versioned proof file
  and the file is NOT retroactively treated as the execution receipt.
```

No raw test-run artifact, synthetic actor identifier, per-case timestamp or
transport transcript is invented or inferred by this reconciliation.

### Operating-session reported PASS coverage

The following cases were executed in the operating session and reported PASS.
This is bounded continuity evidence only; each line remains distinct from a
future canonical executable PR-08 receipt.

```text
STG-001
STG-002
STG-003
STG-004
STG-005
STG-006
STG-007

IMP-001
IMP-002
IMP-004
IMP-005
IMP-006
IMP-007
IMP-008
IMP-009
IMP-010
IMP-011
IMP-012
IMP-SESSION-LIST-MISMATCH
IMP-SESSION-PAYLOAD-MISMATCH
IMP-CLAIMANT-ROLLBACK
IMP-INCOMPLETE-STATE

FDB-001
FDB-002
FDB-003
FDB-004
FDB-005
FDB-006
FDB-007
FDB-008
FDB-009
FDB-010
FDB-011
```

Coverage count:

```text
STG operating-session reported PASS: 7
IMP operating-session reported PASS: 15
FDB operating-session reported PASS: 11
TOTAL operating-session reported PASS: 33
```

Additional bounded operating-session evidence:

```text
post-application catalog:
  OPERATING_SESSION_REPORTED_PASS

true-concurrency infrastructure capability:
  PROVEN

concurrency capability basis:
  distinct PostgreSQL backend_pid values + materially overlapping transaction
  windows observed in the operating-session capability probe

raw concurrency capability receipt:
  NOT_VERSIONED
```

### Explicitly unresolved proof obligations

```text
IMP-003 true-concurrency business-RPC runtime:
  NOT_DETERMINED

reason:
  concurrent PostgreSQL capability was demonstrated, but the concurrent
  importar_leads_batch submission was blocked by the OpenAI tool safety layer
  before SQL reached PostgreSQL.

ROL-PR07 / migration rollback and reapply:
  NOT_DETERMINED

reason:
  Product Authority decisions prohibit:
    NO LAB
    NO SECOND SUPABASE PROJECT
    NO PREVIEW BRANCH
    NO PRODUCTION MIGRATION ROLLBACK TEST
```

Therefore:

```text
OPERATING_SESSION_REPORTED_PASS != CANONICAL_EXECUTABLE_PR08_PASS
CONTROL_IMPLEMENTED != CONTROL_PROVEN_EFFECTIVE
NO_CONTROL_FAILURE_OBSERVED != MISSING_TEST_PASSED
```

### Current evidence target

```text
J3:
  CLOSED WITH BOUNDED RESIDUAL EVIDENCE
  — PRODUCT AUTHORITY EXCEPTION

CANONICAL_J3_EXIT_SATISFIED:
  NO

J3_GOVERNANCE_CLOSURE_BY_PRODUCT_AUTHORITY_EXCEPTION:
  YES

NEXT EVIDENCE TARGET:
  J4 / PR-08 — REPEATABLE EXECUTABLE SECURITY MATRIX
  SCOPE / EVIDENCE-COVERAGE / PROHIBITIONS RECONSTRUCTION FIRST

PR-08 IMPLEMENTATION AUTHORITY:
  NOT_GRANTED

SECURITY_GO:
  NOT_GRANTED
```

## 0.0000 F1-02/B2 post-application evidence override — 2026-09-01

This is the freshest bounded evidence record for F1-02/B2 and supersedes older
B2 freshness wording below when conflicting.

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

The post-application READ_ONLY catalog proof established the bounded direct
write state and preservation of the reviewed collateral invariants. It does not
establish runtime-negative denial, end-to-end product continuity or Security Go.

Next evidence target:

```text
F1-02/B4 / PR-06
TARGET DESIGN + AUTHORIZATION MATRIX FIRST
Architecture + AppSec + LeadOps
```


**Status:** `SECURITY_TO_SCALE_2026 / F1_02_B3_POST_APPLICATION_PROVEN / REMEDIATION_PROGRAM_ACTIVE / SECURITY_GO_DENIED`
**Updated:** `2026-09-01`
**Repository:** `wagnerjfjunior/fecha.ai`

## 0.000 F1-02/B3 post-application evidence override — 2026-09-01

This is the freshest bounded evidence record for F1-02/B3 and supersedes older
B3/M1-C-F01 freshness wording when conflicting.

### GitHub evidence

```text
repository: wagnerjfjunior/fecha.ai
PR #157: CLOSED / MERGED
reviewed head: 6f22afeb723414d87e5481d80196a2c99789e4b1
merge/main anchor: 035f57e29d64c0cca26048a925a790459bd9976c
forward blob: f18f6ae194c8810282345497ff4e637e3236c45a
rollback blob: cf9a0119d5b3ccd6e19daa28523fcca64b712b41
proof blob: e101b62c7638392be06090fdc81030bb01f9d7a6
```

Coverage for the three merged B3 artifacts at the application gate:
`INTEGRAL_READ`. PR lifecycle and final blob identities were independently
resolved live.

### Production application evidence

```text
Supabase project: uobxxgzshrmbtjfdolxd / Discador-MesaCliente
environment: Pilot Production
application count: 1
application result: success=true
ledger version: 20260901074722
ledger name: f1_02_b3_revoke_direct_funnel_history_insert
rollback: NOT EXECUTED
```

### Independent post-application live catalog evidence

```text
authenticated INSERT: false
authenticated effective column INSERT: false
authenticated SELECT: true
funil_mov_insert: absent
RLS: true
FORCE RLS: true
service_role expected table privileges: preserved
postgres expected table privileges: preserved
foreign keys: 9 / 9 validated
non-internal triggers: 0
rows: 610
empresa_id NULL: 0
lead mismatch: 0
corretor mismatch: 0
current-stage mismatch: 0
previous-stage mismatch: 0
four controlled-writer definition/ACL/EXECUTE fingerprints: preserved
```

No business-row payload or PII was captured.

### Read-only proof

The exact merged proof blob
`e101b62c7638392be06090fdc81030bb01f9d7a6` executed after application,
inside its versioned `BEGIN READ ONLY ... ROLLBACK` boundary, and completed
without exception.

```text
READ_ONLY_PROOF = PASS
RUNTIME_NEGATIVE_PASS = NOT ESTABLISHED
```

### Independent AppSec adjudication

The Application Security Assurance Specialist result was manually relayed after
the fresh post-application evidence:

```text
VERDICT = PASS
POST_APPLICATION_APPSEC_PASS = YES
B3_CATALOG_REMEDIATION = ESTABLISHED
EXACT_REVIEWED_ARTIFACT_APPLIED = YES
READ_ONLY_PROOF = PASS
BLOCKING = NONE
REQUIRED_CORRECTION = NONE
ROLLBACK_REQUIRED = NO
F1_02_B3_STATUS =
  REMEDIATED — MERGED + APPLIED + READ_ONLY_CATALOG_PROVEN
RUNTIME_NEGATIVE_PASS = NOT ESTABLISHED
SECURITY_GO = DENIED
```

This is specialist-result provenance relayed through the project conversation;
it is not relabeled as a Gateway runtime receipt.

### Invalidation

Revalidate B3 proportionally if any material event changes the relevant grant,
policy, table/RLS state, FKs, controlled writers, rollback state, applied
migration provenance or the exact production environment. A future
runtime-negative test adds evidence but does not retroactively invalidate this
bounded catalog PASS unless it discovers a material contradiction.

Issue #150 is live `CLOSED / completed`. Issue #141 remains live `OPEN`.



## 0.00 M1 final adjudication evidence override — 2026-08-31

This is the current evidence override for M1 final-baseline semantics. Older
evidence remains valid only for its capture time and bounded subject.

### Backend/Data final adjudication

```text
class: BOUNDED_INDEPENDENT_SPECIALIST_RESULT
transport: MANUAL_COPY_PASTE
specialist: backend-data-platform-specialist
project ref:
  a15dde5067c716b0ab3c9342855069c1fc00bcd0
SES ref:
  7da0dbe7ce5c3fb0d1ea63a7fb61d74ce77481f5
context: READY
live database capability: ACTUALLY_EXECUTED / READ_ONLY

verdict:
  BACKEND_DATA_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

blockers to M1 baseline closure:
  NONE_FROM_BACKEND_DATA

missing evidence required before M1 close:
  NONE_FROM_BACKEND_DATA
```

Current privileged-surface correction admitted from live read-only verification:

```text
SECURITY DEFINER total = 136
authenticated executable = 124
authenticated executable with bounded mutation keywords = 49
anon executable = 22
anon executable with bounded mutation keywords = 9
PUBLIC executable = 1
```

Obsolete `48 / 8` mutation-keyword counts must not be republished.

### Independent Application Security final adjudication

```text
class: BOUNDED_INDEPENDENT_SPECIALIST_RESULT
transport: MANUAL_COPY_PASTE
specialist: application-security-assurance-specialist
project ref:
  a15dde5067c716b0ab3c9342855069c1fc00bcd0
SES ref:
  7da0dbe7ce5c3fb0d1ea63a7fb61d74ce77481f5
scope: TARGETED_DELTA_VERIFICATION_ONLY / PASSIVE_READ_ONLY

verdict:
  APPSEC_M1_BASELINE_PASS_WITH_RESIDUAL_RISKS

blockers to M1 baseline closure:
  NONE_IDENTIFIED

missing evidence required before M1 close:
  NONE_IDENTIFIED

Security Go:
  DENIED
```

AppSec independently confirmed the final M1 finding set and rejected stronger
unsupported claims such as:

```text
22 anon RPCs = 22 exploitable vulnerabilities
M1-C-F01 = proven cross-tenant lead leakage
Vite advisory = proven FECH.AI production exploitation
localStorage alone = exploit
verify_jwt=false alone = unauthenticated Edge vulnerability
visible Supabase anon/publishable config = privileged secret leak
```

### Documentation Auditor final gate

```text
class: BOUNDED_INDEPENDENT_DOCUMENTATION_GATE
transport: MANUAL_COPY_PASTE
specialist: documentation-auditor
project ref:
  a15dde5067c716b0ab3c9342855069c1fc00bcd0
SES ref:
  7da0dbe7ce5c3fb0d1ea63a7fb61d74ce77481f5

verdict:
  DOCUMENTATION_M1_CLOSURE_PASS_WITH_BOUNDED_RESIDUALS

cross-specialist consistency:
  CONSISTENT

Issue #150 exit criteria:
  SATISFIED_FOR_BASELINE_CLOSURE

additional technical re-audit:
  NO / AUDIT_LOOP_BLOCKED

Issue #150 closure eligibility:
  ELIGIBLE_AFTER_BOUNDED_CANONICAL_RECONCILIATION
```

### Final evidence interpretation

```text
M1_SECURITY_TRUTH_BASELINE = COMPLETE
SECURITY_GO = DENIED
KNOWN_FINDINGS = OPEN / MOVE_TO_BOUNDED_REMEDIATION
REMEDIATION_PROGRAM = ACTIVE
```

The following are explicit limitations, not PASS claims:

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

### Current lifecycle freshness

```text
#141 = OPEN
#150 = OPEN pending separately authorized closure
#140 = CLOSED / MERGED
  merge commit c0d993ebe574f644af4f83cc25630fb8c1bd41ad
#139 = OPEN / READY / STALE_REVALIDATION_REQUIRED
  no fresh approval is derived from M1 closure
```

Invalidate this final M1 evidence only on a material event affecting the
relevant proof obligation: database/control drift, code/runtime change on a
confirmed finding, contradictory specialist/runtime evidence, changed
authorization model, or a new security finding. Mere conversation change or
documentation-only lifecycle movement does not reopen the technical M1 audit.

## 0.0 APPSEC-M1-003 / public.leads post-application evidence — 2026-08-30

Evidence classes below are bounded to this slice and capture only the
post-application transition.

### GitHub exact-object evidence

```text
class: MERGED_VERSIONED_EXACT_OBJECT
repository: wagnerjfjunior/fecha.ai
PR #152: CLOSED / MERGED
reviewed exact head: 6964ad993b0deddd85fcf4ff7711929b4d956285
merge commit: 30f4d40acbe0a1f026df9c29451607d6fa361d11

migration blob:
  9e3aec05d3f52987c391dd2a67f0acbb9879e7a8
rollback blob:
  862038db253206061666bf5f2b8a4b12011f1c41
test blob:
  a813274e9865cb4da9095fc69aadd55182664278

merged artifact parity: PASS
```

### Direct production database evidence

Captured read-only after the separately authorized production application:

```text
class: LIVE_DATABASE_VALIDATED
environment: Supabase production
project: uobxxgzshrmbtjfdolxd

apply result: success = true

validated UNIQUE constraints:
  uq_appsec_m1_003_corretores_id_empresa_id
  uq_appsec_m1_003_times_id_empresa_id
  uq_appsec_m1_003_listas_id_empresa_id
  uq_appsec_m1_003_lotes_id_empresa_id

validated composite foreign keys:
  fk_appsec_m1_003_leads_corretor_empresa
  fk_appsec_m1_003_leads_time_empresa
  fk_appsec_m1_003_leads_lista_empresa
  fk_appsec_m1_003_leads_lote_empresa

RLS / FORCE RLS preserved on:
  public.leads
  public.corretores
  public.times
  public.listas
  public.lotes

public.leads rows: 5691
four relationship tenant mismatches: 0 / 0 / 0 / 0
```

Migration ledger provenance:

```text
repository filename version: 20260830030000
applied ledger version: 20260830184834
ledger name:
  20260830030000_appsec_m1_003_leads_tenant_integrity

classification:
  NON_BLOCKING_PROVENANCE_RESIDUAL
```

The version-number divergence must not be rewritten into migration history.
Applied SQL identity is independently tied to the verified merged migration
blob above.

### Specialist evidence

Application Security Assurance Specialist post-application delta:

```text
LIVE_DATABASE_CONTROL_PRESENT = PROVEN
RLS_PRESERVATION_STATUS = PASS
DATA_COMPATIBILITY_STATUS = PASS
CONTROLLED_RUNTIME_NEGATIVE_TEST_STATUS =
  NOT_ESTABLISHED / ACCEPTED_EVIDENCE_LIMITATION_FOR_THIS_WORKSTREAM
BLOCKERS = NONE
PUBLIC_LEADS_SLICE_STATUS =
  IMPLEMENTATION_COMPLETE_WITH_EXPLICIT_RUNTIME_EVIDENCE_LIMITATION
FINAL_POST_APPLICATION_VERDICT =
  APPSEC_M1_003_PUBLIC_LEADS_POST_APPLICATION_PASS_WITH_RESIDUAL_RUNTIME_EVIDENCE_LIMITATION
```

Documentation Auditor supplemental gate:

```text
SUPPLEMENTAL_EVIDENCE_ADMISSION_STATUS = ADMITTED / BOUNDED_SPECIALIST_RESULT
POST_APPLICATION_APPSEC_VERDICT_STATUS = ESTABLISHED
PREVIOUS_DOCUMENTATION_BLOCKER_STATUS = CLOSED
PUBLIC_LEADS_CONTINUITY_STATUS =
  POST_APPLICATION_BOUNDED_RECONCILIATION_MAY_PROCEED
BLOCKERS = NONE
FINAL_DOCUMENTATION_GATE_VERDICT = PASS
```

### Explicit evidence limitations

```text
CONTROLLED_RUNTIME_NEGATIVE_PASS = NOT_ESTABLISHED
TEST_ARTIFACT_VERSIONED != TEST_EXECUTED
LIVE_DATABASE_VALIDATED != CONTROLLED_RUNTIME_PASS
SECURITY_GO = NOT_GRANTED
```

No production adversarial write was executed and no isolated staging/LAB/
Preview environment was created for this workstream.

## 0. Current M1 entry evidence — 2026-08-28

Current transition evidence:

```text
FECH.AI main:
  e1c9800c0cb4904d0950afb94766c6e840bf575e

Issue #141:
  OPEN / Security-to-Scale 2026

Issue #142:
  CLOSED / completed / M0

PR #149:
  MERGED
  final reviewed head:
    11041d8df99228b9fc119cbbb9e81c6d859a3fb6
  merge commit:
    e1c9800c0cb4904d0950afb94766c6e840bf575e
  merged final SFJM blob parity:
    6 / 6 PASS

Issue #150:
  OPEN / M1 Security Truth Baseline
```

Evidence effect:

```text
M0 analytical/documentation reconciliation = CLOSED historical milestone
M1 current live database truth = NOT YET ESTABLISHED
M1 current privileged-surface truth = NOT YET ESTABLISHED
M1 dependency/vulnerability truth = NOT YET ESTABLISHED
M1 infrastructure/secrets attack-surface truth = NOT YET ESTABLISHED
Security Go = NOT GRANTED
```

The M0 evidence map below is historical-at-capture. Do not present its dated PR heads, thread counts or database observations as current M1 truth without live re-resolution.

## 0. M0 current evidence map — 2026-08-28

This section is the current evidence-class reconciliation. The older sections below are preserved as historical claim/anchor lineage. They do not become current merely because they remain versioned.

Current GitHub anchors observed:

```text
main: 8ad6b7ec493b363922168e22afd188577bdfa5c9
Issue #141: OPEN
Issue #142: OPEN
#139: 32003e75a28e235fb454d39e3e4459d0f03acb2b / ACTIVE
#140: 3aed206883d7aa7ac76c8d48ffb09d677c848bba / ACTIVE
#149: resolve live / ACTIVE / DOCUMENTATION_ONLY_READY / self-referential publication PR; Ready authorized/executed, merge separate
#131: b9cb671e6fae8125a12b31454395b2a418e7cd17 / STALE_CONTINUITY
#124: 5e5cc76dae2da93472643e585d3311c92e79e4e6 / STALE_CONTINUITY
#120: 2b3ea57583f1fa54930191f02dc18c60997b9794 / SUPERSEDED
```

PR #139 review-thread evidence:

```text
source: live GitHub review-thread metadata
threads observed: 6
isResolved=false: 6
severity: 3 P1 + 3 P2
class: LIVE_GITHUB_METADATA
```

M0 specialist evidence — pre-publication analytical reconciliation:

```text
consultation channel: MANUAL_COPY_PASTE
specialist role: documentation_audit -> documentation-auditor
specialist response class: INFORMATION_SUPPLIED / MANUAL_SPECIALIST_OUTPUT
response artifact SHA-256:
  a866de230f09dd6c8ca90005f848d0febe40e0eb70fa8af0863902306512866c

reviewed project anchor:
  repository: wagnerjfjunior/fecha.ai
  main: 8ad6b7ec493b363922168e22afd188577bdfa5c9
  Issues: #141 / #142

reviewed open-PR universe at that time:
  #139 / #140 / #131 / #124 / #120

reviewed continuity scope:
  docs/sfjm/INDEX.md
  docs/sfjm/CURRENT_STATE.md
  docs/sfjm/NEXT_SAFE_ACTION.md
  docs/sfjm/AUTHORIZATIONS.md
  plus the material SFJM continuity evidence needed for the M0 reconciliation

specialist effective-scope result:
  M0 analytical reconciliation: SUFFICIENT
  Supabase: NOT_ACCESSED
  SQL: NOT_EXECUTED
  runtime: NOT_ACCESSED_OR_MUTATED

specialist limitation:
  its available GitHub REST evidence surface did not expose authoritative
  review-thread resolved/unresolved flags for PR #139

independent gap closure after the specialist response:
  live GitHub review-thread metadata on 2026-08-28 established
  #139 head 32003e75a28e235fb454d39e3e4459d0f03acb2b
  6 threads / 6 isResolved=false / 3 P1 + 3 P2
```

This manual specialist artifact validates the **M0 analytical reconciliation**, not the later exact-head contents of PR #149. PR #149 receives its own independent exact-head read/diff/review validation and must not inherit specialist PASS by implication.

Evidence semantics:

| Class | Required basis | Does not prove |
|---|---|---|
| `STATIC_IMPLEMENTATION_REVIEW` | exact-head source/diff/final-file review | applied DB, deployment or runtime |
| `LIVE_DATABASE_VALIDATED` | direct bounded live DB/catalog observation | runtime paths or future state |
| `CONTROLLED_RUNTIME_PASS` | actually executed bounded behavior | untested paths or Security Go |
| `NOT_EXECUTED` | planned/versioned without execution proof | behavioral PASS |
| `PR_HEAD_ONLY` | evidence only on an unmerged PR head | current canonical main/live truth |

```text
STATIC != LIVE
LIVE != RUNTIME
RUNTIME_BOUNDED != SECURITY_GO
PR_BODY_CLAIM != INDEPENDENT_PROOF
```

No Supabase or runtime operation was executed as part of M0. Historical production/catalog evidence below is therefore `LIVE_AT_CAPTURE`, not a fresh 2026-08-28 live-database validation.

## 1. Freshness model

Evaluate each material claim by:

```text
claim
object
anchor
environment
invalidation event
```

Do not infer freshness from `main` movement alone.

```text
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
```

## 2. T1 status-boundary production anchor

Claim:

```text
T1 corretor status authority boundary is applied in Supabase production and remains a material dependency for T3A.
```

Environment:

```text
Supabase project: uobxxgzshrmbtjfdolxd
Environment: production
Migration record:
  version: 20260822192552
  name: f1_02_harden_status_corretor_rpc
```

Fresh read-only production revalidation on 2026-08-23 established:

```text
public.t3_prepare_admin_password_reset(uuid): ABSENT
public.t3_prepare_admin_password_reset(uuid,uuid): ABSENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): ABSENT
public.t3_admin_password_reset_edge_proofs: ABSENT
public.marcar_senha_inicial_definida() md5:
  2a7b28d4bb6342a99d075c4d3c49af4d
authenticated UPDATE columns on public.corretores:
  apto_para_receber
  ativo
  must_change_password
T1 triggers:
  trg_t1_guard_corretores_authority_update: PRESENT / ENABLED
  trg_t1_guard_corretores_direct_compat_update: PRESENT / ENABLED
```

Additional live function anchors observed during T3A red-team:

```text
t1_guard_corretores_authority_update() md5:
  5e69ae5cb6717f634d758cfd5c1cd7a6

t1_guard_corretores_direct_compat_update() md5:
  99477024e337de5645dd042a30f8cf78

audit_trail_log_corretores_critical_update() md5:
  3fdaca39d55f348ca36f796023f3260b
```

Material T3A interaction:

```text
t1_guard_corretores_direct_compat_update()
currently denies gestor-originated must_change_password transitions.
```

Invalidate/revalidate the affected T3A compatibility claim if either T1 guard body, trigger binding/enabled state, corretores ACL/policy, relevant role contract or T3A design changes.

## 3. T2 frontend status-cutover anchor

Claim:

```text
the active App.jsx status-edit flow routes ativo/apto_para_receber through atualizar_status_corretor rather than the prior direct status PATCH.
```

GitHub code anchor at transition time:

```text
main commit: 037232fe3da37a749ab980f783af92ff15e2baf2
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

Controlled positive runtime smoke evidence from the current operating session established:

```text
apto isolated toggle + restoration: PASS
ativo isolated toggle + restoration: PASS
combined ativo/apto toggle + restoration: PASS
unchanged field represented as null in isolated RPC calls: PASS
RPC responses: ok=true
captured direct status PATCH: ZERO
```

Evidence limitation:

```text
HAR/runtime evidence was inspected in the operating conversation and is not yet a canonical repository artifact.
This proves the bounded positive flows observed, not an exhaustive role/cross-tenant adversarial matrix.
```

Invalidate/revalidate after material `src/App.jsx` blob change in the status flow, status RPC contract/ACL change, contradictory runtime evidence or relevant deployment replacement.

## 4. Administrative password residual anchor

Claim:

```text
the current App.jsx still contains a stale administrative post-reset direct write of must_change_password=false.
```

Anchor:

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
callsite: EditarCorretorModal.redefinirSenha()
```

This remains a T3A/T3B dependency. It must not be interpreted as legitimate authority merely because the code exists.

Invalidate after that callsite/blob changes.

## 5. T3A blocked-head lineage and corrective invalidation

Initial reviewed candidate object anchors:

```text
supabase/functions/criar-usuario/index.ts
  blob: 84c6f23d115cdae966b377f76289a03e5940b45c

supabase/migrations/20260822211600_t3_admin_password_reset_boundary.sql
  blob: 6ab6b94433032d594236257c456a196fd2935b44

supabase/rollback/20260822211600_t3_admin_password_reset_boundary_rollback.sql
  blob: 25723b9d13af9d9a0df82772ca2c8c9cd8ab771c

initial exact PR head reviewed:
  d51340766c3eb8bc3fa0977d327ce229218aaaa3

PR_HEAD_ONLY SFJM transition head before corrective implementation:
  45ad27668835b6458b52d2fb592cfa36b5589726
```

Review result on that initial candidate:

```text
REQUEST CHANGES

B1 safe rollout ordering: FAIL
B2 trust-anchor preflight: FAIL
B3 drift-safe rollback: FAIL
B4 T1 guard interoperability: newly discovered BLOCKING
```

Any corrective change to a material T3A artifact invalidates the prior exact-head gate by design. The next gate must resolve the new live head and read the final material files again.

Do not preserve a partial PASS across head movement.

The next corrected exact head reached
`bf8fb1f4ab043226de3c77763b9b425a13b0261e` (tree
`7f5ad06ed27ae1fb724175dd5f30af1e7135010b`). A manually relayed integral
Backend/Data review bound to that exact head read all ten files and returned:

```text
REQUEST_CHANGES
B1: PASS
B2: FAIL — direct prosrc writer regex is not transitive/authoritative
B3: FAIL — rollback repeats the non-transitive writer check
B4: PASS for the static DB transaction
HIGH-1: DB locks end before external Auth mutation
HIGH-2: positive exact routine/writer inventory required
```

This response is fresh evidence about `bf8fb1f...`, but every corrective code
change after it invalidates the response as a final-head gate. It is not an
AppSec result and authorizes no lifecycle transition.

The next v3 exact head reached
`4631325827a76152ba554bece2a59da9eb1bb662` (tree
`843bbc9c9f32f07e97713368e7e472fca9e650cd`). A second manually relayed integral
Backend/Data review read the exact ten blobs / 6744 lines to EOF and returned:

```text
REQUEST_CHANGES
B1: PASS
B2: FAIL — membership, aggregate and public-schema closure incomplete
B3: FAIL — rollback repeats those incomplete trust anchors
B4: PASS (static)
HIGH-1: CLOSED
HIGH-2: OPEN
manual response SHA-256:
  1ab2b39d52536b0ba92cd25df4d91b808f25abd08be0c5de72146113c7cda544
```

This is fresh evidence about `46313258...` and materially accepts the v3
lease/fence concurrency analysis. The membership/aggregate/schema correction
then reached exact head `fcb7dfc2f5f2259926556652fa9cfd3443d0c214` / tree
`4dcaf2d4b6aa1248801e455def811e50ff04e414`. Integral Backend/Data and
independent AppSec review both returned `APPROVE`:

```text
Backend/Data response SHA-256:
  8b6bf96691b7337df95f0350ac5028a4aeb85e6cab917ec56383fc8e083ac0dc
AppSec response SHA-256:
  1df5df13786f7ba767340cca2ca546aeddbf92e81a307a48aef3107fc0cf64ca
```

After separately-authorized Ready, the GitHub Codex review opened material P2
`DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`. Source validation confirmed that the
authenticated one-argument prepare RPC was directly callable through
PostgREST, could commit the durable lease and `must_change_password=true`
without an Auth mutation, and exposed no release path to that caller. The PR
was returned to Draft without merge. This finding invalidates both `fcb7dfc2...`
approvals as final-head gates in the affected domain.

T3A-v4 changes Edge, migration, rollback and evidence so the service-role-only
issuer mints an opaque actor+target Edge-presence proof and the caller-JWT
two-argument prepare consumes that exact unexpired proof before any locks,
lease or password-state write. The changed head requires a fresh Backend/Data
review and, only after closure, independent AppSec.

Corrected v4 candidate body/inventory anchors now recorded in this change set:

```text
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid):
  prosrc md5 87f8d7f0c96ce4ae52fed9e2bc4bdcdd

public.t3_prepare_admin_password_reset(uuid,uuid):
  prosrc md5 f9bd114c7eb77313e22861816b8a88f5

public.t3_release_admin_password_reset_lease(uuid,uuid,uuid):
  prosrc md5 a51c5b360c5d8a3684a97271460ec249

public.t3_guard_admin_password_reset_lease():
  prosrc md5 bd611e591aa2d951b178853f78caaa65

T3-aware t1_guard_corretores_direct_compat_update():
  prosrc md5 951da8a6ac6e934828f06ab1513778fa

exact pre-T3A guard restored by rollback:
  pg_get_functiondef md5 99477024e337de5645dd042a30f8cf78

historical reviewed non-system routine baseline excluding the direct guard:
  count 264 / inventory md5 b1f0919df8a0acaca7bbea2b928b0ffe

authenticated-effective SECURITY DEFINER subset:
  count 122 / inventory md5 7faa376a403c69239d9606559cf9c2db

non-system aggregates included by prokind='a':
  count 0

full pg_auth_members graph (role/member/grantor + admin/inherit/set options):
  count 21 / inventory md5 fb803a204209bc71074a1eee7b57944e

database/public schema:
  current database postgres / owner postgres
  public owner pg_database_owner
  complete effective ACL count 7 / md5 e2ad94b6bfb9b0cb8c4980459fd55a6e

lease-table constraint shape:
  unique lease_id, actor_user_id and target_user_id; authority_time_id unique when non-null
  fencing check uses transactional unique-index probes, not snapshot-only SELECT
  prepare probes actor/target/team and rejects cross-role subject overlap

Edge-proof boundary:
  issuer EXECUTE: service_role only
  trust claim: server-credential handshake, not exact Edge-binary attestation
  prepare EXECUTE: authenticated only
  proof table: postgres-owned / RLS + FORCE / no client table grants or policies
  unique proof + actor; exact target bound in row; no target-wide reservation
  prior same-actor proof rotated; PostgreSQL statement time; two-minute validity
  prepare atomically consumes exact proof before any durable state
  random/missing/expired/wrong-actor/wrong-target proof fails closed

rollback proof handling:
  SHARE-lock in fixed proof -> authority -> lease writer order
  any unexpired proof or any lease: STOP
  only after complete exact preflight: delete expired inert proofs
  prove locked proof table empty before exact object removal

authority-table ACL transition:
  complete ACL fingerprints pinned before/after
  service_role TRUNCATE removed only while T3A row fences are active
  33-column ACL md5 pre-T3A 3fa731261b3d39ca5d046fd548c1bf53
  33-column ACL md5 T3A d475edbb63410c2ab4b4c2be55ac270c

complete authority-table RLS policy inventory:
  count 7 / md5 1cb8f611f86778af0f60c78f2ffc70b0

authority-table non-internal trigger inventory:
  pre-T3A count 4 / T3A count 7
  includes corretores critical audit + both T1 guards + times governance audit
  authority-table rewrite rules count 0
```

Those were v4 candidate anchors. They were later resolved and reviewed as
recorded below.

### Post-merge v4 approval and runtime anchors

```text
repository: wagnerjfjunior/fecha.ai
PR: #127
final reviewed source head: a5c92617f372599a234c0147aad13a90649348d7
final reviewed source tree: 87872aac22b36437b7fb66f3614905e8df94f5ee
Backend/Data: APPROVE / findings none / static exact-head only
Backend/Data bundle: 95463 bytes / SHA-256 0b22d6e9f9f1f8e3d184254876a25ed985e8f054423a44acf3dd5b5f9f9570a6
AppSec: APPROVE / findings none / independent static exact-head only
AppSec bundle: 95986 bytes / SHA-256 7bde681c36639ee332e6e527c53c1b76fbfccaa7d74d090b2c64a64eea08da8f
merge commit / main: 610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87
```

The reviews authenticated byte-preserving exact-head bundles and read all 12
required PR/T1 payloads through EOF. They authorize no runtime by themselves.

Separate rollout evidence:

```text
criar-usuario production: v18 / ACTIVE / verify_jwt=false
Git blob: ec62997bc357b550feda5027051fe507fe9184fa
SHA-256: 11719575bce92c85422eb5d3a78ad26a5d683c47202e6db8032f3e13d5a254a7
T3A migration: NOT APPLIED
issuer/prepare/release/proof/lease objects: ABSENT
bounded fail-before-Auth calls: 3 UI submissions / each Edge 500
Auth admin update calls: 0
target password fingerprint / updated_at: unchanged
B1 fail-before-Auth: PASS
```

Each runtime submission showed `audit_logs POST 400` before the absent issuer
RPC 404. Live read-only catalog evidence established:

```text
audit_logs columns: 20
required no-default legacy columns: acao, entidade
ip_address: inet
owner: postgres
RLS / FORCE RLS: true / true
complete baseline relation fingerprint: 5d3b70257c57f5956032e83131effabb
hypothetical exact post-authenticated-INSERT-revoke fingerprint:
  1b1a381796f273b503cd4c41d34a3688
authenticated effective privileges: SELECT + INSERT baseline
service_role effective privileges: SELECT + INSERT + UPDATE
```

This is a material invalidation only for the Edge audit compatibility and the
new audit ACL/preflight/rollback domain. It does not reopen unchanged T1/T2 or
the approved v4 actor/tenant/proof/lease design. The v5 Edge, migration,
rollback and related evidence must receive new exact-head Backend/Data then
independent AppSec review. The v5 commit/head/blob anchors must be resolved live
after publication.

V5 relation-lock ordering follows established in-transaction writers:
`authority -> audit` for migration and
`proof -> authority -> lease -> audit` for rollback. Edge audit and proof calls
are separate committed HTTP transactions, so they do not introduce the reverse
held-lock pair.

### 5.1 PR #128 merge, Edge v19 proof and migration-abort anchor

```text
PR #128 reviewed head: b594218dabd9a7beaea3158bb143f5dd2fd71386
PR #128 reviewed tree: e36a00e671e8c8bce52b2e35f12beed165fad927
PR #128 merge commit / main: 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
criar-usuario production: v19 / ACTIVE / verify_jwt=false
deployment digest: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
single controlled POST: 2026-08-25T17:29:25.608Z / HTTP 500
audit committed: action=password_reset_attempt / status=edge_proof_unavailable
target UUID remained absent from auth.users and public.corretores
Auth logs in the window: caller login/getUser only; no admin password update
```

Exact SQL application anchor:

```text
main migration blob: f4413fddd145679077ae68b28b85c98ce439e74e
migration SHA-256: 9cef9dadae10b1262d78f01fbf30b490342b5cc228fc866c48ace5799777fced
migration bytes/lines: 134244 / 3550
main rollback blob: 36513bce970f66e023a50b16148a97bad76e17d7
rollback SHA-256: 7a8377f7ea4ecff5c36bb665a5e9bcb734b48015792310668d7ff328e81dbba4
rollback bytes/lines: 106631 / 2785
application invocations: 1
result: SQLSTATE 55000 / record "r" is not assigned yet
migration history entry after failure: ABSENT
T3 routines/relations after failure: ABSENT
Edge v19 after failure: ACTIVE
```

Invalidated claim:

```text
The reviewed forward/rollback SQL is executable on production PostgreSQL 17.
```

Bounded cause and correction:

```text
r record (later FOR-loop target)
+ pg_roles AS r (earlier catalog alias)
-> r.oid / r.rol* resolves to unassigned record
-> rename only catalog alias and role-field qualifiers to role_row
```

This finding does not invalidate B1 v19 runtime ordering, audit compatibility,
actor/tenant/proof/lease/T1 semantics, or the absence of partial production
state. It invalidates the final-head executability gate for B2/B3 and requires
fresh exact-head reviews of both SQL artifacts and related evidence.

### 5.2 PR #129 merge and live routine-inventory drift anchor

PR #129 closed the collision above and reached:

```text
final reviewed head: 6f6092aa66352cda3d617897895b0f09019adeea
final reviewed tree: bb13c051b57d1b04a1926cbe886b190cfa89ba37
Backend/Data: APPROVE / findings none / static exact-head only
Backend/Data response SHA-256:
  8d76512eadcaf54085e6109c83eb4a4e3b9499160537c85e741f7113d2b39b0f
AppSec: APPROVE / findings none / independent static exact-head only
AppSec response SHA-256:
  d096c474128e5099a16a90b5c4afc9922ffc4ff593b08680a8990b42177aa1ea
merge commit / main: 69f4cfa1bdee331826953b492f25c12b4defc030
```

Exact merged source anchors:

```text
migration blob: 6cc9a1f4419de5e0355954f2cbc6f503f5eb8157
migration SHA-256: f7d36c397decdc14675b29060f26ca462dae07c62576ab1ccb43c77e7e372181
migration lines / bytes: 3550 / 135000
rollback blob: afce77ab693a1fbbac10fdd70bd87032a7c8f0b2
rollback SHA-256: 4271782a67961705098cb1cb932799d5e7b19855678612ff2ac6845e8770164b
rollback lines / bytes: 2785 / 107387
Edge source blob: 866257371dcc85d22ae54cae3593b3e49a132d8e
```

The exact migration was applied once after that merge. It passed the corrected
role predicates and stopped before DDL:

```text
SQLSTATE P0001
T3A_PREFLIGHT_POSITIVE_ROUTINE_INVENTORY_DRIFT
PL/pgSQL function inline_code_block line 386 at RAISE
migration history entry after failure: ABSENT
T3 routines/relations after failure: ABSENT
Edge v19 after failure: ACTIVE
```

Fresh read-only recomputation on `2026-08-25`:

```text
complete non-system routine inventory excluding direct T1 guard:
  count 264 / md5 c299bf087df69f960dd0c611d1486675
authenticated-effective SECURITY DEFINER subset:
  count 122 / md5 7faa376a403c69239d9606559cf9c2db
non-system aggregate count: 0
```

The count, definer subset and aggregate count are unchanged. The only
non-system routine with tuple version newer than the established T1 anchor is:

```text
extensions.grant_pg_graphql_access()
owner: supabase_admin
security mode: SECURITY INVOKER
config: search_path=""
event trigger: issue_pg_graphql_access / ddl_command_end / enabled O
xmin: 7208
implementation md5: 2f3fa32125a4cd4e597bc8b3c7b55218
prosrc md5: e2ca36b1a39e090c101c6d0f009b5d20
normalized ACL:
  PUBLIC>supabase_admin:EXECUTE:f,
  supabase_admin>supabase_admin:EXECUTE:f,
  postgres>supabase_admin:EXECUTE:t
```

The anchor refresh includes this exact helper inside the complete inventory;
it does not add an exclusion. Change all four full-inventory digest literals
from historical `b1f0919d...` to current `c299bf08...`. Any later routine
body/owner/language/kind/config/comment/ACL drift still changes the digest and
stops migration or rollback.

Candidate SQL blob anchors after that four-literal substitution:

```text
migration: 1b938b95107bd4f6ab1d14d914438e654fcc1011
  SHA-256 b9f55d58ea73c723a04075ab639bf1f6910b07d77774dfd5b593010d8de56d77
rollback: a9457bc48724cc8406bcec9348a14cbc8b868be3
  SHA-256 bc8ea4aaca436aa78a25de29b8511d4d15b36a15ece32cc8a85b164153251ba7
```

## 6. Live trust-anchor observations used by T3A review

Read-only production evidence on 2026-08-23 established, without PII:

```text
admins authenticated SELECT/INSERT/UPDATE/DELETE: absent
corretores authenticated broad UPDATE: absent
corretores authority-bearing columns role/empresa_id/user_id/time_id/is_admin_local/is_gestor: not directly authenticated-updatable
times authenticated table UPDATE: present and therefore materially dependent on RLS/policy semantics
times_update policy: exactly one permissive UPDATE policy with the recorded expression
corretores_update policy: exactly one permissive UPDATE policy with identical strict USING/WITH CHECK helper
RLS/FORCE on admins/corretores/times: present / enabled
direct literal authenticated password writer besides self-service: absent
T3 context-key collision: absent
authenticator: NOINHERIT / LOGIN / no superuser-create-replication-bypass
pg_database_owner: INHERIT / NOLOGIN / no superuser-create-replication-bypass
full pg_auth_members graph: count 21 / md5 fb803a204209bc71074a1eee7b57944e
non-system aggregates: count 0
database owner: postgres
public schema owner: pg_database_owner
only public ACL CREATE grantee: pg_database_owner -> database owner postgres
complete public schema ACL: count 7 / md5 e2ad94b6bfb9b0cb8c4980459fd55a6e
```

Observed helper fingerprints relevant to the current `times` policy trust chain:

```text
auth.uid() md5: ea3b41bf29e2ad573067939329aa088e
is_root() md5: 465c04885d729e63f1a1d4458fc2a1b0
is_admin_local() md5: 64b982da412f62c324aa2dde210eea0c
my_corretor_id() md5: c8f243d33d42837c46236625a74c3fb7
my_empresa_id() md5: 7d7a73d22953d547a103f89c7b676906
```

The old direct-literal result is not proof against wrappers, dynamic SQL or
transitive callees. The v4 migration therefore pins the full positive routine
inventory and enforces the password-state transition at the enabled T1/T3
guards. These remain review anchors, not runtime proof.

## 7. Production Edge baseline

Current production Edge:

```text
slug: criar-usuario
version: 19
status: ACTIVE
verify_jwt: false
deployment digest: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
source merge commit: 3c9daf6c49eb937824c2c2b40aba198e2727c4bb
```

The controlled call established audit-first fail-before-Auth while the issuer
remains absent. Invalidate after any Edge version/runtime change.

## 8. Unestablished claims

```text
anchor-refresh final PR head: MUST BE RESOLVED AFTER COMMIT
Backend/Data exact-head PASS on refreshed anchor: NOT ESTABLISHED
independent AppSec exact-head PASS on refreshed anchor: NOT ESTABLISHED
T3A applied to Supabase production: NO
positive/negative/cross-tenant production smoke: NOT EXECUTED
rollback runtime-tested: NOT EXECUTED
T3B frontend password cutover: NOT IMPLEMENTED
Security Go: DENIED
```

Established:

```text
PR #128 merged
PR #129 merged
Edge v19 deployed and active
single v19 fail-before-Auth call PASS
audit row committed
no Auth mutation
first migration invocation aborted on alias collision before DDL
PR #129 exact-head Backend/Data + AppSec approvals
second migration invocation aborted on positive routine inventory drift before DDL
current live routine inventory 264 / c299bf087df69f960dd0c611d1486675
authenticated definer subset and aggregate count unchanged
no migration history entry or T3 objects after either abort
```

## 9. Invalidation rules

Material invalidation events include:

```text
material code/object change
RPC/ACL/policy/grant/trigger change
Edge runtime/version change
relevant App frontend change
contradictory runtime evidence
new security finding
change in product authority contract
```

Not invalidation events by themselves:

```text
main SHA movement only
documentation-only lifecycle movement
new conversation
specialist change
request to repeat an unchanged exact-head gate
```

## 10. AUDIT_LOOP_BLOCKED

A repeated audit must identify the prior anchor, exact changed evidence and affected proof obligation.

Without a material invalidation event:

```text
AUDIT_LOOP_BLOCKED
```

After a material T3A corrective commit, revalidate only the affected exact-head T3A gate and its dependencies; do not reopen unrelated completed work.

## 11. PR #166 / PR-08 — evidence freshness reconciliation — 2026-09-03

Fresh anchor used for this lifecycle reconciliation:

```text
main = 9d05c64281c2aeeae9d67b139eab674720184fb1
PR #166 reviewed head before documentation reconciliation = 2a0e6b8a2f964afe3c0c35c75190ae23344ed884
branch = test/f1-02-negative-security-matrix
PR = OPEN / READY
mergeable = TRUE
Vercel = SUCCESS
```

Material evidence at that anchor was re-resolved from GitHub live. The technical
closures currently carried forward are:

```text
Phase 1 — CLOSED STATICALLY
Phase 2 — CLOSED STATICALLY
Phase 3 — CLOSED
Phase 4 — CLOSED
```

Residual evidence record:

```text
PR08-RR-64M-CANONICAL-HASH
classification = ACCEPTABLE WITH RESIDUAL RISK
thread = PRRT_kwDOSEToMc6fBXHM
surface = PR-08 isolated evidence harness
cause = ordered canonical relation JSON materialization + Node spawnSync maxBuffer 64 MiB
failure semantics = FAIL-CLOSED / NO FALSE PASS
production runtime impact = NONE ESTABLISHED
future remediation = server-side digest or streaming
```

Residual revalidation is required if any of these occur:

```text
ENOBUFS / maxBuffer / equivalent capture failure
fixture relation approaches/exceeds the practical envelope
harness is used against a large or uncontrolled dataset
rollback/cleanup evidence cannot complete at required volume
hashing implementation changes
```

Execution evidence remains deliberately absent:

```text
IMP-003 = NOT_DETERMINED
ROLLBACK_REAPPLY = NOT_DETERMINED
SECURITY_GO = NOT_GRANTED
PR-08 runtime = NOT_EXECUTED
```

Authorized lifecycle completion after this documentation commit is published and
its new exact head is revalidated: resolve only the following eight threads and
then confirm their GitHub state:

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

A documentation-only SHA advance caused by this reconciliation does not reopen
Phases 1–4 by itself. Any unexpected implementation-file change, new technical
finding, failed check, thread contradiction or head drift is an invalidation
event and requires bounded re-adjudication before pre-merge.
