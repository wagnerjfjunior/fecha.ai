# FECH.AI — STS-M3-04-03 — Global Tenant Surface & Relationship Inventory

**Date:** 2026-09-10  
**Task:** `STS-M3-04-03 — Global Tenant Surface & Relationship Inventory`  
**Mode:** `READ_ONLY / EVIDENCE_FIRST / NO_SUPABASE_MUTATION`  
**Environment:** FECH.AI Pilot Production / Supabase live catalog  
**Repository:** `wagnerjfjunior/fecha.ai`  
**FECH.AI main observed during execution:** `b274adac84f2d4a27a7a5147c551dc23469a610c`  
**SES main observed during publication bootstrap:** `d9a148d8500b5b2790d295eea80d08dc99c58b42`  
**Publication state:** `PR_HEAD_ONLY / CANDIDATE_EVIDENCE`  
**Product Authority acceptance of task result:** `NOT_IMPLIED_BY_PUBLICATION`

---

## 1. Purpose

This artifact records the bounded READ_ONLY execution of `STS-M3-04-03` and closes the inventory evidence needed before structural hardening slices such as `STS-M3-04-04` and `STS-M3-04-05` are implemented.

The task goal is inventory and evidence classification, not remediation.

This document does **not** authorize or claim:

```text
Supabase mutation
DDL / DML
RLS change
FORCE RLS change
grant / revoke
policy change
RPC body change
trigger change
data repair
hostile-client execution
Security Go
Product Authority acceptance of STS-M3-04-03
start of STS-M3-04-04
```

---

## 2. Authority and bootstrap

The READ_ONLY task was explicitly authorized by Product Authority with the boundary:

```text
STS-M3-04-03
READ_ONLY / evidence-first
no mutation of Supabase, runtime, RLS, grants, policies, RPCs or data
```

After the inventory result was reported, Product Authority separately authorized GitHub documentation publication and PR creation. That second authorization does not authorize READY, MERGE, Supabase mutation or remediation.

Specialist routing used for the work/publication:

```text
backend_data
→ backend-data-platform-specialist
→ FECH.AI local rules: docs/skills/fechai-gpt3-supabase-security-specialist.md

publication/evidence discipline
→ documentation_audit
→ documentation-auditor
→ FECH.AI local rules: docs/skills/fechai-gpt0-documentation-auditor.md

application_security
→ application-security-assurance-specialist
→ review domain for downstream security closure, not Product Authority
```

---

## 3. Evidence coverage matrix

| Source / surface | Exact ref / environment | Coverage | Evidence use | Limitation |
|---|---|---|---|---|
| FECH.AI `main` | `b274adac84f2d4a27a7a5147c551dc23469a610c` | LIVE_RESOLVED | canonical project ref during execution/publication | does not itself prove Supabase applied state |
| SES `main` | `d9a148d8500b5b2790d295eea80d08dc99c58b42` | LIVE_RESOLVED | specialist routing/certification bootstrap | SES does not own FECH.AI project truth |
| `docs/bootstrap/INDEX.md` | blob `6040b7e15b480181b8198e058084be0d2cd53d24` | INTEGRAL_READ | bootstrap contract | none material |
| `docs/skills/SES_SPECIALIST_ROUTING.md` | blob `10cb3d7b3de48c1ce6e47f3d549ad46fa17c1ae6` | INTEGRAL_READ | adopted specialist routing | none material |
| `docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md` | blob `e2deb1e80d6666390f222781655200c240fc6bac` | INTEGRAL_READ | evidence/coverage/fail-closed rules | none material |
| `docs/sfjm/INDEX.md` | blob `33edf172a8405ab9c08eeb4ceb3034215ec109f6` | INTEGRAL_READ | continuity and anti-loop rules | none material |
| current WBS section for `STS-M3-04` | FECH.AI main above | PARTIAL_READ / TARGETED | task identity, state and exit rule | full WBS not required for this bounded inventory claim |
| `2026-09-09-full-stack-security-audit.md` | blob `c41ffa9e14a5e8027be21bf2ed61575d078787d4` | INTEGRAL_READ | prior F-04/F-05 and prior global surface cardinalities | historical snapshot; revalidated live where material |
| Supabase live public tables/views/policies/functions/triggers/constraints | FECH.AI production Supabase catalog, 2026-09-10 | ENUMERATED / LIVE_OBSERVED | current structural inventory | no hostile-client mutation/test executed |
| Supabase live selected function definitions | same environment | TARGETED_DEFINITION_READ | compensating controls and canonical funnel write paths | not every function body was reread in this task |
| Aggregate relationship consistency scans | same environment | LIVE_OBSERVED / AGGREGATE_ONLY | detect stored tenant mismatches without exposing row data | no PII or row payload returned |

No customer name, telephone, email, lead payload or row-level PII is stored in this artifact.

---

## 4. Global live surface inventory

The live public-schema cardinalities observed during `STS-M3-04-03` were:

| Surface | Live count |
|---|---:|
| `public` base tables | **44** |
| `public` views | **8** |
| `public` policies | **82** |
| user triggers | **31** |
| `public` constraints | **271** |
| `public` functions | **160** |
| base tables carrying `empresa_id` | **38** |
| `empresa_id` tables with RLS enabled | **38 / 38** |
| `empresa_id` tables with FORCE RLS | **25 / 38** |
| composite tenant-bound foreign keys | **10** |
| single object FKs between tenant-bearing tables | **83** |
| single object FKs without a matching composite tenant pair | **75** |

The global counts `44 / 8 / 82 / 31 / 271 / 160` match the 2026-09-09 full-stack audit snapshot. This is evidence of **no cardinality drift** in those object classes between the two observations. It is **not** a byte-for-byte equivalence claim for every definition.

`75 single object FKs without a matching composite tenant pair` does **not** mean 75 vulnerabilities. That set includes relationships protected by other mechanisms, references not directly client-writable, audit/actor references and relationships that still require downstream adjudication.

---

## 5. Relationship classification

### 5.1 Structurally tenant-bound examples

The live catalog includes composite tenant-bound foreign keys in critical areas, including relationships in:

```text
funil_movimentacoes
leads
importar_leads_batch_idempotency
lista_visibilidade
```

The observed pattern is equivalent to:

```text
(object_id, empresa_id)
→
(parent.id, parent.empresa_id)
```

where implemented.

Existing simple legacy FKs that coexist with a corresponding composite tenant FK were not counted as independent unresolved gaps for the same relationship.

### 5.2 Compensating integrity controls observed

`lista_visibilidade` has a tenant-aware trigger validator that checks the referenced list and polymorphic target against the same `empresa_id`.

The MesaCliente financial subset uses `mesa_cliente_financeiro_assert_integridade()` for selected tables. The function explicitly checks tenant consistency among policy, simulation, development and installment relationships for the branches reviewed.

These controls reduce false-positive classification from a foreign-key-only scan. They do not establish universal MesaCliente tenant integrity outside the relationships actually guarded by those controls.

### 5.3 Views

The two views observed as directly readable by `authenticated` in this surface use `security_invoker=true`:

```text
vw_lotes_estado_oficial
vw_lotes_pendentes_avaliacao
```

This preserves caller-side RLS semantics for those views. Other observed legacy views without that option were not directly granted to ordinary authenticated clients in the ACL set inspected.

---

## 6. Revalidation of canonical audit findings

### F-04 — `lista_avaliacoes` tenant relationship integrity

**State:** `RECONFIRMED / OPEN`  
**Prior severity:** `HIGH`  
**Downstream ownership:** `STS-M3-04-04`, verification in `STS-M3-04-07 / 09`

Live observations remain consistent with the canonical finding:

```text
authenticated has INSERT / UPDATE on lista_avaliacoes
write policy binds primarily to corretor_id = my_corretor_id()
lista_id / lote_id / empresa_id relationships are not enforced as one tenant-composite invariant
no dedicated tenant-integrity trigger was observed for these relationships
```

Aggregate consistency scan during this inventory found:

```text
stored cross-tenant mismatch in tested lista_avaliacoes relationships = 0
```

Zero stored mismatch does not close F-04 because the structural write path remains insufficiently constrained.

### F-05 — PME catalog tenant relationship integrity

**State:** `RECONFIRMED / OPEN`  
**Prior severity:** `HIGH`  
**Downstream ownership:** `STS-M3-04-05`, verification in `STS-M3-04-07 / 09`

Live observations remain consistent with the canonical finding for PME catalogs such as:

```text
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_message_templates
```

Their authenticated write policies establish actor/company authority, but the reviewed object references are not universally bound with `(object_id, empresa_id)` constraints or an equivalent tenant-integrity trigger.

Aggregate consistency scan during this inventory found:

```text
stored cross-tenant mismatch in tested PME relationships = 0
```

Again, absence of current dirty rows does not close the preventive structural gap.

---

## 7. New material inventory finding — GTI-01

### `GTI-01 — leads.funil_estagio_id current-stage tenant invariant`

**State:** `PROVEN_LIVE / OPEN / NOT_REMEDIATED`  
**Finding namespace:** local to `STS-M3-04-03`; this artifact does **not** unilaterally promote it to canonical `F-11`  
**Stored mismatch count:** **1**

The live operational dataset contains one row satisfying the aggregate condition:

```text
leads.funil_estagio_id references funil_estagios.id
AND leads.empresa_id IS DISTINCT FROM funil_estagios.empresa_id
```

No row identifier or PII was retrieved into the durable evidence artifact.

The active structural relationship is a simple FK:

```text
leads.funil_estagio_id
→ funil_estagios.id
```

The parent table already has a candidate key equivalent to:

```text
UNIQUE (id, empresa_id)
```

but the live inventory did not observe an equivalent child invariant:

```text
(leads.funil_estagio_id, leads.empresa_id)
→
(funil_estagios.id, funil_estagios.empresa_id)
```

### 7.1 Current canonical write-path review

The following live routine definitions were inspected because they assign `leads.funil_estagio_id`:

```text
mover_funil
mover_funil_batch
mover_funil_lote
registrar_feedback
```

For the definitions reviewed, stage selection/validation is scoped to the relevant company before `funil_estagio_id` is assigned.

Therefore the evidence supports the bounded conclusion:

```text
ACTIVE STORED TENANT MISMATCH = PROVEN
DATABASE STRUCTURAL INVARIANT = MISSING
CANONICAL AUTHENTICATED FUNNEL WRITE ROUTINES REVIEWED = TENANT-GUARDED
CURRENT ORDINARY AUTHENTICATED REPRODUCTION THROUGH THOSE ROUTINES = NOT_PROVEN
```

This finding still requires disposition before final `STS-M3-04` closure because the database itself does not universally prevent reintroduction through privileged/service/future migration or future routine paths.

### 7.2 Required downstream disposition

Do not repair the row or add DDL under this inventory task.

Required downstream proof obligations are:

```text
1. determine authorized disposition of the one active mismatch without exposing PII;
2. preserve historical/business truth where required;
3. define the durable tenant invariant for lead current stage;
4. apply only under explicit Supabase mutation authorization;
5. prove migration preflight fails closed if incompatible data remains;
6. prove normal funnel workflows continue to operate;
7. execute structural cross-tenant negative proof in the authorized non-production security test phase;
8. obtain independent AppSec closure before M3-04 final acceptance.
```

Suggested WBS ownership for adjudication is `STS-M3-04-06 / 07 / 09`, unless Product Authority or architecture review assigns a narrower implementation slice.

---

## 8. Additional inventory candidates — not promoted to vulnerabilities by this task

The global scan identified relationships that remain structurally simple or otherwise require explicit review, including clusters in:

```text
MesaCliente core relationships
inventory / estoque relationships
listas / lotes / teams actor references
PME usage/state references
selected audit/actor references
UUID relationship fields without declared FK
```

Aggregate checks performed on the tested MesaCliente, PME, estoque and LeadOps relationships returned zero cross-tenant mismatches except `GTI-01`.

These items are classified as:

```text
STRUCTURAL_INVARIANT_REVIEW_REQUIRED
```

unless already covered by a known compensating control or existing finding.

They are **not** automatically classified as exploitable security findings merely because the FK is simple.

---

## 9. Non-`empresa_id` public tables

Six public tables do not use a direct `empresa_id` column in the same pattern:

```text
deployment_control_log
empresas
planos
root_audit_logs
t3_admin_password_reset_edge_proofs
t3_admin_password_reset_leases
```

The bounded classification observed is not “missing tenant column = vulnerability”. These tables represent platform/global catalog, root/audit or internal admin/reset boundaries and are governed by their own RLS/policy/grant contracts.

The inventory also observed that the only current `admins` row with `empresa_id IS NULL` is a global-admin case in aggregate classification; no non-global-role null-company admin was counted.

---

## 10. Evidence-based task conclusion

```text
STS-M3-04-03 READ_ONLY INVENTORY EXECUTION = COMPLETE

GLOBAL DECLARED RELATIONAL SURFACE = INVENTORIED FOR THIS GATE
F-04 = RECONFIRMED / OPEN
F-05 = RECONFIRMED / OPEN
GTI-01 = NEW MATERIAL LIVE FINDING / OPEN
SUPABASE MUTATION = NONE
RUNTIME MUTATION = NONE
RLS / FORCE RLS MUTATION = NONE
GRANT / POLICY / RPC / TRIGGER MUTATION = NONE
DATA REPAIR = NONE
HOSTILE-CLIENT TEST = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
PRODUCT AUTHORITY ACCEPTANCE OF RESULT = PENDING
```

`READ_ONLY INVENTORY EXECUTION = COMPLETE` means the authorized evidence-gathering activity completed. It does not mean the risks identified by the inventory are remediated.

---

## 11. Invalidation events

Revalidate the affected claims if any of the following occurs before downstream use:

```text
Supabase schema or policy/grant/trigger/RPC mutation
new migration applied to the relevant relations
change to authenticated table privileges
change to canonical funnel write routines
new tenant-integrity constraint or trigger
repair/deletion/update of the GTI-01 active row
FECH.AI WBS task scope change
new audit finding that supersedes the mapping
```

Ordinary passage of time alone does not convert this artifact into remediation evidence.

---

## 12. Next gate

The safe next decision is:

```text
Product Authority reviews/accepts the STS-M3-04-03 inventory result
→ canonical state/WBS relationship may then be reconciled
→ STS-M3-04-04 may be separately authorized
```

No automatic transition to `STS-M3-04-04` is created by this artifact or by the documentation PR that publishes it.
