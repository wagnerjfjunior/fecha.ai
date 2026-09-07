# FECH.AI — STS-M2-05 — Database Contract Map — Accepted Durable Evidence

**Status:** `COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-CALLSITE-EVIDENCE-RUNTIME-APPSEC RESIDUALS`  
**Product Authority:** Wagner / FECH.AI  
**Acceptance/publication base main:** `e07254ef6b2d7184e749463727df2e6d404226a7`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Publication lifecycle:** Product Authority decision is accepted; this artifact is `PR_HEAD_ONLY` until its documentation PR is separately reviewed and merged.  
**Security Go:** `NOT_GRANTED`

## 1. Decision boundary

Product Authority accepts STS-M2-05 as:

~~~text
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
target direct-DML vs RPC-only contract explicit
transitive authority contract explicit
current / target / implementation / proof states separated
M2-01 canonicality residuals preserved
M2-04 implementation/lifecycle/runtime residuals preserved
new M2-05 semantic blockers = 0
~~~

This acceptance does **not** mean:

~~~text
current implementation target-compliant
implementation remediation complete
lifecycle remediation complete
exhaustive application callsite proof complete
AppSec PASS
hostile-client assurance
cross-tenant runtime assurance
Security Go
~~~

Preserve:

~~~text
TARGET CONTRACT ACCEPTED
!=
TARGET IMPLEMENTED

DATABASE CONTRACT MAP COMPLETE
!=
SECURITY ASSURANCE COMPLETE
~~~

## 2. Evidence coverage matrix

The accepted M2-01..M2-04 evidence was consumed without replay. Material GitHub sources were recovered on exact FECH.AI main `e07254ef6b2d7184e749463727df2e6d404226a7`.

| Source | Exact object | Coverage | Use |
|---|---|---|---|
| `docs/bootstrap/INDEX.md` | blob `6040b7e15b480181b8198e058084be0d2cd53d24` | INTEGRAL_READ | bootstrap / evidence contract |
| `docs/skills/SES_SPECIALIST_ROUTING.md` | blob `10cb3d7b3de48c1ce6e47f3d549ad46fa17c1ae6` | INTEGRAL_READ | specialist routing |
| `docs/skills/fechai-gpt-registry.md` | blob `c0035ec21e613d8360b217a30885a3acf32c4110` | INTEGRAL_READ | project-local specialist registry |
| `docs/skills/fechai-gpt0-documentation-auditor.md` | blob `282182a54b88f2344ea56ef8225e2519a96493e2` | INTEGRAL_READ | documentation/evidence rules |
| `docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md` | blob `e2deb1e80d6666390f222781655200c240fc6bac` | INTEGRAL_READ | common operating rules |
| `docs/governance/2026-09-04-fechai-bcr-security-to-scale-program-hierarchy-core-dod.md` | blob `d10bf9ff99aa93649f4cb875c7d27d05eb4200c8` | INTEGRAL_READ | program hierarchy / authority |
| `docs/roadmap/fechai-security-to-scale-2026-wbs.md` | blob `c6fe2e339c4de33dfb8265912ba6b63380270c4e` | INTEGRAL_READ | WBS structure / historical labels |
| `docs/sfjm/INDEX.md` | blob `490fbcadfed61ea36f8fcfcc539a3ebc9fd1cac6` | INTEGRAL_READ | continuity contract |
| `docs/security/evidence/M1_M2_PROVENANCE_MANIFEST.md` | blob `7b7c84e713319a3a3c3de457e6e16239f1b1fd06` | INTEGRAL_READ | accepted M1/M2 provenance |
| M2-01 canonicality matrix | blob `281fe7372882310e186abfd068b4b4f1baab011d` | INTEGRAL_READ | 44-table universe / disposition |
| M2-02 database authority map | blob `ec723587ee003427e592873efcc2fe4ef5aae615` | INTEGRAL_READ | 160-routine / 31-trigger universe |
| M2-03 index/ACL contradictions | blob `3d5cf2d890e4c5f7b37d9f01a926a8a50d0f8cc9` | INTEGRAL_READ | accepted residuals |
| M2-04B1 routine policy | blob `15e771e99ce3e424ba4a869a00d4965bed733fc3` | INTEGRAL_READ | routine authority contract |
| M2-04B2 high-risk slice | blob `bfa43f6936b2a381552dbb95f5306f13069142af` | INTEGRAL_READ | separate 15-routine slice |
| M2-04B3 narrative | blob `96d31bb3c471ddbc606f391aff13cb7674358e8b` | INTEGRAL_READ | 113-routine slice boundary |
| M2-04B3 113×40 CSV | blob `cf3baa6e5a6ab6465688de8f6af43cba7c27d3bd` | INTEGRAL_READ | complete structured B3 matrix |
| M2-04C3 adjudication CSV | blob `716c23d5f549eb465f3393cdfc5989dda82b69a7` | INTEGRAL_READ | target mode adjudication |
| M2-04C4 target RLS/direct-DML contract | blob `01eefe744946a9f916ac0789780f77c5444aa799` | INTEGRAL_READ | direct-DML/RPC target contract |
| M2-04D trigger authority evidence | blob `7fdc63a95d81661598937aa0bdfa654bcb9db66a` | INTEGRAL_READ | 18 instances / 9 DEFINER trigger functions |
| M2-04E architecture synthesis | blob `07365cae5a353bd2407512ddde0d3d4cf880352f` | INTEGRAL_READ | accepted cross-slice boundary |
| Product Authority M2-05 acceptance/publication instruction | current decision packet | INTEGRAL_READ / INFORMATION_SUPPLIED | accepted M2-05 completion facts and publication authority |

No Supabase query, runtime test, hostile-client test or mutation was executed by this publication.

## 3. Database universe and WBS label boundary

~~~text
WBS planning label = "Matriz de 43 tabelas"
accepted/live canonical universe = 44 public tables
~~~

The WBS historical label is preserved. It is not rewritten by M2-05.

~~~text
public tables = 44
KEEP = 40
INTERNAL = 4
bounded contexts = 10
assigned = 44 / 44
unassigned = 0
~~~

A bounded context is a logical ownership/contract boundary. It does not imply a microservice or separate physical database.

## 4. Accepted 44-table / 10-context map

| # | Table | M2-01 disposition | M2-05 bounded context |
|---:|---|---|---|
| 1 | `public.admins` | KEEP | Tenant / Identity / Authority |
| 2 | `public.audit_logs` | KEEP | Audit / Governance / Operations |
| 3 | `public.audit_trail` | KEEP | Audit / Governance / Operations |
| 4 | `public.corretores` | KEEP | Tenant / Identity / Authority |
| 5 | `public.deployment_control_log` | INTERNAL | Internal Platform / Security Control |
| 6 | `public.empreendimentos` | KEEP | MesaCliente / Product & Inventory |
| 7 | `public.empresas` | KEEP | Tenant / Identity / Authority |
| 8 | `public.empresas_configuracoes` | KEEP | Tenant / Identity / Authority |
| 9 | `public.estoque_arquivos` | KEEP | MesaCliente / Product & Inventory |
| 10 | `public.estoque_snapshots` | KEEP | MesaCliente / Product & Inventory |
| 11 | `public.funil_estagios` | KEEP | CRM / Funil |
| 12 | `public.funil_movimentacoes` | KEEP | CRM / Funil |
| 13 | `public.importar_leads_batch_idempotency` | INTERNAL | LeadOps / Lists / Distribution |
| 14 | `public.leads` | KEEP | LeadOps / Lists / Distribution |
| 15 | `public.lista_avaliacoes` | KEEP | LeadOps / Lists / Distribution |
| 16 | `public.lista_visibilidade` | KEEP | LeadOps / Lists / Distribution |
| 17 | `public.listas` | KEEP | LeadOps / Lists / Distribution |
| 18 | `public.logs` | KEEP | Audit / Governance / Operations |
| 19 | `public.lotes` | KEEP | LeadOps / Lists / Distribution |
| 20 | `public.mesa_arquivos` | KEEP | MesaCliente / Product & Inventory |
| 21 | `public.mesa_cliente_agendas_financeiras` | KEEP | MesaCliente / Finance & Simulation |
| 22 | `public.mesa_cliente_desconto_politicas` | KEEP | MesaCliente / Finance & Simulation |
| 23 | `public.mesa_cliente_fluxo_operacoes` | KEEP | MesaCliente / Finance & Simulation |
| 24 | `public.mesa_cliente_fluxo_parcelas` | KEEP | MesaCliente / Finance & Simulation |
| 25 | `public.mesa_cliente_politica_premio_faixas` | KEEP | MesaCliente / Finance & Simulation |
| 26 | `public.mesa_cliente_politicas_financeiras` | KEEP | MesaCliente / Finance & Simulation |
| 27 | `public.mesa_cliente_unidade_enriquecimentos` | KEEP | MesaCliente / Product & Inventory |
| 28 | `public.mesa_eventos` | KEEP | MesaCliente / Finance & Simulation |
| 29 | `public.mesa_fluxo_pagamentos` | KEEP | MesaCliente / Finance & Simulation |
| 30 | `public.mesa_fluxo_pagamentos_canonico` | KEEP | MesaCliente / Finance & Simulation |
| 31 | `public.mesa_simulacoes` | KEEP | MesaCliente / Finance & Simulation |
| 32 | `public.planos` | KEEP | Monetization |
| 33 | `public.pme_cadence_steps` | KEEP | PME / Messaging |
| 34 | `public.pme_cadences` | KEEP | PME / Messaging |
| 35 | `public.pme_call_scripts` | KEEP | PME / Messaging |
| 36 | `public.pme_lead_message_state` | KEEP | PME / Messaging |
| 37 | `public.pme_message_templates` | KEEP | PME / Messaging |
| 38 | `public.pme_message_usage` | KEEP | PME / Messaging |
| 39 | `public.root_audit_logs` | KEEP | Audit / Governance / Operations |
| 40 | `public.t3_admin_password_reset_edge_proofs` | INTERNAL | Internal Platform / Security Control |
| 41 | `public.t3_admin_password_reset_leases` | INTERNAL | Internal Platform / Security Control |
| 42 | `public.templates_mensagens` | KEEP | Legacy Messaging Compatibility |
| 43 | `public.times` | KEEP | Tenant / Identity / Authority |
| 44 | `public.unidades_estoque` | KEEP | MesaCliente / Product & Inventory |

Context totals:

~~~text
Tenant / Identity / Authority = 5
LeadOps / Lists / Distribution = 6
CRM / Funil = 2
PME / Messaging = 6
Legacy Messaging Compatibility = 1
MesaCliente / Product & Inventory = 6
MesaCliente / Finance & Simulation = 10
Audit / Governance / Operations = 4
Internal Platform / Security Control = 3
Monetization = 1
TOTAL = 44
~~~

## 5. Routine universe composition

The accepted routine universe is intentionally non-homogeneous:

~~~text
B2 high-risk slice = 15
B3/C3/E slice = 113
M2-04D trigger-function slice = 9
M2-05 non-DEFINER delta = 23
TOTAL PUBLIC FUNCTIONS = 160
~~~

Preserve:

~~~text
15 + 113 + 9 = 137 current SECURITY DEFINER routines
137 + 23 = 160 public routines
~~~

Do **not** synthesize one homogeneous target-mode distribution for the 137 SECURITY DEFINER routines. B2, B3/C3/E and D retain their accepted slice semantics.

Canonical references rather than duplicated matrices:

- B2: `docs/security/evidence/2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md`
- B3 narrative: `docs/security/evidence/2026-09-05-sts-m2-04b3-remaining-routine-authority-classification.md`
- B3 113×40 matrix: `docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv`
- C3: `docs/security/evidence/2026-09-06-sts-m2-04c-c3-routine-mode-adjudication.csv`
- C4: `docs/security/evidence/2026-09-06-sts-m2-04c-c4-target-rls-dml-contract.md`
- D: `docs/security/evidence/2026-09-06-sts-m2-04d-trigger-authority-classification.md`
- E: `docs/security/evidence/2026-09-06-sts-m2-04e-architecture-synthesis-acceptance.md`

## 6. M2-05 non-DEFINER delta

Accepted closure:

~~~text
23 / 23 non-DEFINER routines mapped
~~~

Material categories:

~~~text
trigger functions = 7
MesaCliente internal/pure helpers = 13
service-only query = 1
callerless/lifecycle candidates = 2
TOTAL = 23
~~~

This publication preserves the accepted M2-05 category-level closure and material findings; it does not fabricate a new 23-row raw transcript that is not independently versioned.

Retained findings:

### `grant_app_permissions()`

~~~text
current body = no-op
authenticated/service EXECUTE = observed in accepted M2-05 evidence
canonical caller = NOT_PROVEN
classification = unexplained reachability / unused candidate
exploit = NOT_PROVEN
~~~

### `set_updated_at_lista_avaliacoes()`

~~~text
class = trigger helper
direct PUBLIC/anon/authenticated/service execution = observed in accepted M2-05 evidence
direct client execution = NOT_TARGET_REQUIRED
~~~

### `sync_status_comercial()`

~~~text
class = trigger helper
current semantics = no-op compatibility
residual = lifecycle / ACL
~~~

### `gpt_security_metadata_snapshot()`

~~~text
class = service-only query
versioned Edge caller = observed
current service-only contract = coherent
~~~

Preserve:

~~~text
NO VERSIONED CALLER != UNUSED
UNUSED CANDIDATE != PROVEN UNUSED
LIFECYCLE CANDIDATE != AUTHORIZED RETIREMENT
~~~

## 7. Trigger coverage and authority

~~~text
total non-internal trigger instances = 31 / 31

M2-04D =
18 instances
9 SECURITY DEFINER trigger functions

M2-05 delta =
13 additional instances
7 non-DEFINER trigger functions
~~~

Special accepted contract:

~~~text
set_mesa_simulacao_oficial()

=
TRIGGER_ONLY
+ INVOKER
+ TRANSITIVE MUTATIVE BUSINESS INVARIANT
+ CONCURRENCY/RUNTIME PROOF REQUIRED
~~~

Preserve:

~~~text
TRIGGER FIRING AUTHORITY
!=
DIRECT FUNCTION EXECUTE
!=
TABLE DML AUTHORITY
~~~

The M2-04D 9-function / 18-instance accepted matrix remains canonical for that slice and is not duplicated here.

## 8. Direct-DML versus RPC-only target contract

Direct-DML intended / structurally supported:

~~~text
lista_avaliacoes
logs
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_lead_message_state
pme_message_templates
~~~

RPC-only preferred:

~~~text
mesa_cliente_unidade_enriquecimentos
pme_message_usage
~~~

Do not generalize this into:

~~~text
ALL WRITES MUST BE RPC
~~~

That is not the accepted FECH.AI target architecture.

The direct-DML contract remains subject to RLS/policy/relationship integrity and runtime proof obligations. Direct table privilege is not business authorization.

## 9. Cross-context dependency model

Material accepted dependency directions:

~~~text
Tenant / Identity / Authority
→ tenant-bound LeadOps, CRM, PME and MesaCliente authority

LeadOps / Lists / Distribution
→ CRM / Funil
→ messaging/contact execution where applicable

MesaCliente / Product & Inventory
→ MesaCliente / Finance & Simulation

business mutations
→ Audit / Governance / Operations side effects

Internal Platform / Security Control
→ protected administrative/security workflows

Legacy Messaging Compatibility
↔ PME / Messaging only through explicit compatibility/migration contracts

Monetization
→ tenant/company plan state without becoming tenant authority by itself
~~~

These are logical contract dependencies, not a microservice topology.

## 10. Transitive authority invariants

~~~text
authenticated caller
→ INVOKER outer routine
→ DEFINER inner helper

outer authorization
!=
inner authority automatically safe

service_role EXECUTE
!=
canonical service use

trigger fires automatically
!=
client should EXECUTE trigger function

table privilege
!=
business authorization

function EXECUTE
!=
tenant/object authority
~~~

For any mutative or privileged path, actor, tenant/empresa, role/permission, ownership/object binding and transitive privileged helpers remain server-side proof obligations.

## 11. Current vs target vs implementation vs proof

Every material contract must keep these states separate:

~~~text
AS_IS
TARGET_CONTRACT
IMPLEMENTATION_STATUS
LIFECYCLE_STATUS
RUNTIME_ASSURANCE_STATUS
APPSEC_STATUS
~~~

Current accepted program meaning:

~~~text
TARGET CONTRACT = ACCEPTED
CURRENT IMPLEMENTATION TARGET-COMPLIANT = NOT_PROVEN
IMPLEMENTATION REMEDIATION = NOT_PERFORMED
LIFECYCLE REMEDIATION = NOT_PERFORMED
EXHAUSTIVE APPLICATION CALLSITE PROOF = NOT_ESTABLISHED
RUNTIME ASSURANCE = NOT_PERFORMED / NOT_PROVEN
APPSEC PASS = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
~~~

## 12. Open residuals / proof obligations

### 12.1 C4 / direct-DML evidence

~~~text
lista_avaliacoes resulting-row protected relationship integrity
= NOT INDEPENDENTLY PROVEN

leads resulting-row empresa_id relationship
= NOT INDEPENDENTLY PROVEN

times resulting-row empresa relationship
= NOT INDEPENDENTLY RESTATED / NOT FULLY PROVEN

exhaustive application direct-DML callsite proof
= NOT ESTABLISHED
~~~

M2-05 performed a bounded static search.

~~~text
BOUNDED STATIC CALLSITE SEARCH
!=
EXHAUSTIVE APPLICATION CALLSITE PROOF
~~~

### 12.2 `public.logs`

~~~text
canonical disposition = KEEP
residuals:
- producer/consumer taxonomy
- retention
- data sensitivity
- relationship to audit_logs / audit_trail / root_audit_logs
~~~

### 12.3 `public.mesa_fluxo_pagamentos_canonico`

~~~text
CANONICAL SHADOW
DUAL-WRITE / COMPATIBILITY STATE
NOT CANONICAL READ AUTHORITY YET
~~~

Residuals:

~~~text
read cutover
backfill/equivalence
consumer compatibility
reconciliation
rollback
~~~

### 12.4 `public.templates_mensagens`

~~~text
LEGACY_SUPPORTED
USAGE NOT PROVEN
~~~

Do not publish `UNUSED`, `RETIRE` or `CONSOLIDATE` without future lifecycle evidence and authority.

## 13. Program state and continuation boundary

After Product Authority acceptance:

~~~text
M2-01 = COMPLETE
M2-02 = COMPLETE WITH RESIDUALS
M2-03 = COMPLETE WITH RESIDUALS
M2-04 = COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

M2-05 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-CALLSITE-EVIDENCE-
RUNTIME-APPSEC RESIDUALS

M2-06 = ELIGIBLE_NOT_AUTHORIZED
M2 = ACTIVE
~~~

M2 is not closed. It closes only after M2-06 is separately completed/accepted.

The single next program gate is:

~~~text
PRODUCT AUTHORITY:

AUTHORIZE BOUNDED STS-M2-06
DATABASE ARCHITECTURE DECISION
READ_ONLY SCOPE / EVIDENCE RECONSTRUCTION
~~~

M2-06 owns the future decision among:

~~~text
EVOLVE_IN_PLACE
vs
V2_STRANGLER
vs
NEW_DATABASE
~~~

This artifact does not make that decision and does not execute M2-06.

## 14. Authorization and lifecycle boundary

This publication authorizes no runtime, frontend, App.jsx, Supabase, Auth, RLS, policy, grant, function, trigger, migration, Edge Function, Vercel, Actions, Builder, production or data mutation.

~~~text
READY = NOT_AUTHORIZED
MERGE = NOT_AUTHORIZED
DEPLOY = NOT_AUTHORIZED
M2-06 EXECUTION = NOT_AUTHORIZED
M3 EXECUTION = NOT_AUTHORIZED
SECURITY GO = NOT_GRANTED
COMMERCIALIZATION AUTHORIZATION = NOT_GRANTED
~~~

Rollback for this publication is a simple revert of the documentation PR.
