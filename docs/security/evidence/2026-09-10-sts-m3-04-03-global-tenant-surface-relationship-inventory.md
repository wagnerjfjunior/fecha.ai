# FECH.AI — STS-M3-04-03 — Global Tenant Surface & Relationship Inventory

**Date:** 2026-09-10  
**Task:** `STS-M3-04-03 — Global Tenant Surface & Relationship Inventory`  
**Mode:** `READ_ONLY / EVIDENCE_FIRST / NO_SUPABASE_MUTATION`  
**Environment observed during execution:** FECH.AI Pilot Production / Supabase live catalog  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Execution-base main:** `b274adac84f2d4a27a7a5147c551dc23469a610c`  
**Publication state:** `PR_HEAD_ONLY / CANDIDATE_EVIDENCE`  
**Task result acceptance:** `PRODUCT_AUTHORITY_ACCEPTANCE_PENDING`

---

## 1. Purpose and exact claim boundary

This artifact records the bounded READ_ONLY execution of `STS-M3-04-03`.

The inventory established the live object-class cardinalities and materially inspected tenant-relationship classes needed to drive downstream hardening. It **does not claim that the nominal rowset of all 75 simple tenant-bearing FK relationships was durably captured during the original operating session**.

Preserve:

```text
READ_ONLY EXECUTION COMPLETE
!= FULL NOMINAL ROWSET DURABLY PERSISTED
!= PRODUCT AUTHORITY ACCEPTANCE
!= REMEDIATION COMPLETE
!= STS-M3-04 COMPLETE
```

The correction of PR #215 is GitHub documentation-only and explicitly does not re-query Supabase. Therefore missing live row identities are not invented from aggregate counts.

No Supabase/runtime/Auth/RLS/grant/policy/RPC/trigger/data mutation is performed by this publication.

---

## 2. Durable evidence package

Human-readable result:

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-global-tenant-surface-relationship-inventory.md
```

Machine-readable summary:

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-global-tenant-surface-relationship-inventory.json
```

Material relationship ledger:

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-material-relationship-ledger.json
```

READ_ONLY reproduction/query manifest:

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-readonly-reproduction-manifest.sql
```

The reproduction manifest is **versioned query text only** in this correction. It is not executed by PR #215.

---

## 3. Evidence coverage

| Source / surface | Coverage | Use | Limitation |
|---|---|---|---|
| FECH.AI `main` `b274adac…` | LIVE_RESOLVED during execution/publication | project provenance | GitHub does not prove applied Supabase state |
| `docs/bootstrap/INDEX.md` | INTEGRAL_READ | bootstrap | none material |
| `docs/skills/SES_SPECIALIST_ROUTING.md` | INTEGRAL_READ | specialist routing | none material |
| common Modus Operandi | INTEGRAL_READ | evidence/fail-closed discipline | none material |
| `docs/sfjm/INDEX.md` | INTEGRAL_READ | continuity rules | none material |
| `docs/security/audits/2026-09-09-live-db-evidence.md` | INTEGRAL_READ | prior F-04/F-05 live evidence and prior counts | historical live snapshot; not substitute for 2026-09-10 execution |
| Supabase public tables/views/policies/functions/triggers/constraints | ENUMERATED / LIVE_OBSERVED during original execution | global structural counts | no hostile-client execution |
| selected routine definitions | TARGETED LIVE DEFINITION READ | compensating controls + funnel write paths | not every function body reread |
| aggregate relationship consistency queries | LIVE_OBSERVED / AGGREGATE_ONLY | stored-mismatch detection | no row identifiers/PII persisted |
| nominal 75 simple-FK rowset | NOT_DURABLY_CAPTURED | aggregate count only | requires future separately authorized READ_ONLY replay for exact live row list |

No customer/lead UUID, name, telephone, e-mail or commercial payload is persisted in the package.

---

## 4. Live surface counts observed

| Surface | Count |
|---|---:|
| public base tables | **44** |
| public views | **8** |
| public policies | **82** |
| user triggers | **31** |
| public constraints | **271** |
| public functions | **160** |
| base tables carrying `empresa_id` | **38** |
| `empresa_id` tables with RLS | **38 / 38** |
| `empresa_id` tables with FORCE RLS | **25 / 38** |
| composite tenant-bound foreign keys | **10** |
| simple object FKs between tenant-bearing tables | **83** |
| simple object FKs without matching composite tenant pair | **75** |

The `44 / 8 / 82 / 31 / 271 / 160` counts matched the 2026-09-09 audit snapshot. This establishes **count-level no-drift only**, not byte-for-byte equivalence.

`75` does not mean 75 vulnerabilities. It is a discovery universe containing true structural gaps, references protected by compensating controls, internal/audit references and relationships requiring downstream adjudication.

---

## 5. Material relationship ledger

The durable ledger records only relationships for which the operating session or existing canonical/versioned evidence supports a material disposition.

Important boundary:

```text
MATERIAL LEDGER COMPLETE FOR ADJUDICATED RELATIONSHIPS
!= ALL 75 NOMINAL SIMPLE-FK ROWS DURABLY CAPTURED
```

Known structurally tenant-bound areas include existing composite controls for material `leads` ownership/membership references, `funil_movimentacoes` tenant relationships and `lista_visibilidade` list binding, subject to the evidence class recorded in the ledger.

Observed compensating controls include:

- tenant-aware target validation for `lista_visibilidade`;
- `mesa_cliente_financeiro_assert_integridade()` for the reviewed MesaCliente financial subset;
- `security_invoker=true` for the two authenticated-readable lot views reviewed.

These controls must not be generalized beyond the relationships actually covered.

---

## 6. F-04 — `lista_avaliacoes`

**State:** `RECONFIRMED / OPEN`  
**Prior severity:** `HIGH`  
**Downstream:** `STS-M3-04-04`, verification in `STS-M3-04-07 / 09`

Observed/current evidence remains consistent with the canonical audit:

```text
authenticated = SELECT + INSERT + UPDATE
RLS = enabled
FORCE RLS = enabled
INSERT/UPDATE policy binds primarily to corretor_id = my_corretor_id()
lista_id / lote_id / corretor_id are simple object relationships
no composite resulting-row tenant invariant observed for those relations
no dedicated tenant-integrity trigger observed; updated_at only
```

Original aggregate consistency scan:

```text
stored cross-tenant mismatches in tested F-04 relationships = 0
```

Zero dirty rows does not close the preventive structural gap.

---

## 7. F-05 — PME catalog relationships

**State:** `RECONFIRMED / OPEN`  
**Prior severity:** `HIGH`  
**Downstream:** `STS-M3-04-05`, verification in `STS-M3-04-07 / 09`

Material tables include:

```text
pme_cadences
pme_cadence_steps
pme_call_scripts
pme_message_templates
```

Authenticated write policies establish actor/company authority but do not universally bind all referenced IDs by `(object_id, empresa_id)` or an equivalent resulting-row invariant.

Original aggregate consistency scan:

```text
stored cross-tenant mismatches in tested PME relationships = 0
```

F-05 remains open because preventive integrity is not established by current clean data.

---

## 8. GTI-01 — `leads.funil_estagio_id` current-stage tenant invariant

**State:** `PROVEN_LIVE / OPEN / NOT_REMEDIATED`  
**Namespace:** local `STS-M3-04-03` finding; **not** automatically canonical `F-11`  
**Severity:** `TO_BE_ADJUDICATED`  
**Stored mismatch count:** **1**

The original READ_ONLY aggregate observation established one active row where:

```text
leads.funil_estagio_id references funil_estagios.id
AND leads.empresa_id IS DISTINCT FROM funil_estagios.empresa_id
```

No row identifier or PII is stored in this evidence package.

The material structural condition observed is:

```text
leads.funil_estagio_id -> funil_estagios.id
= simple relationship

(funil_estagio_id, empresa_id)
-> (funil_estagios.id, funil_estagios.empresa_id)
= durable child invariant not observed
```

The parent already exposes the candidate-key shape needed for a future tenant-composite design, but this task does not authorize DDL or row repair.

### 8.1 Canonical write-path review

The following live routines that assign `leads.funil_estagio_id` were reviewed:

```text
mover_funil
mover_funil_batch
mover_funil_lote
registrar_feedback
```

Their reviewed definitions scope/validate the destination stage against the applicable company before assignment.

Bounded conclusion:

```text
ACTIVE STORED TENANT MISMATCH = PROVEN
DATABASE STRUCTURAL INVARIANT = MISSING
REVIEWED CANONICAL AUTHENTICATED WRITE ROUTINES = TENANT-GUARDED
ORDINARY AUTHENTICATED REPRODUCTION THROUGH THOSE ROUTINES = NOT_PROVEN
```

Therefore GTI-01 is a real active consistency/invariant finding, but this evidence does not claim a current ordinary-client exploit path through those reviewed routines.

### 8.2 Required downstream disposition

Before final `STS-M3-04` closure:

1. adjudicate the one active mismatch without exposing PII;
2. define authorized data disposition/repair semantics;
3. define a durable tenant-bound current-stage invariant;
4. apply only under explicit Supabase mutation authorization;
5. fail closed if incompatible data remains;
6. regression-prove normal funnel workflows;
7. run structural negative proofs in the authorized test phase;
8. obtain independent AppSec closure.

Suggested ownership: `STS-M3-04-06 / 07 / 09`, subject to Product Authority adjudication.

---

## 9. Other structural-review candidates

The original inventory also identified material candidates that were **not promoted to vulnerabilities solely because a FK is simple or absent**, including MesaCliente, estoque, list/lot/team actor references, PME usage/state references and selected UUID relationship fields without FK.

Operational no-FK examples preserved in the ledger include:

```text
listas.time_origem_id
mesa_cliente_unidade_enriquecimentos.empresa_id
mesa_fluxo_pagamentos_canonico.empresa_id / created_by_*
pme_message_usage.feedback_id
```

Classification unless separately adjudicated:

```text
STRUCTURAL_INVARIANT_REVIEW_REQUIRED
```

Original aggregate checks found zero cross-tenant mismatch in the tested MesaCliente/PME/estoque sets, with GTI-01 as the only mismatch found in the tested relationship groups.

---

## 10. Reproducibility status

The query manifest now makes the following reproducible under a future authorized READ_ONLY replay:

```text
public object-class counts
all public FK rows + child/parent column arrays
composite tenant-bound FK list
simple tenant-bearing FK rows without matching composite tenant pair
UUID relation-like columns without FK
policies
triggers
authenticated/anon table privileges
F-04 aggregate mismatch counts
F-05 aggregate mismatch counts
GTI-01 aggregate count
funil_estagios candidate keys
leads current FK definitions
```

Current durable status:

```text
QUERY LOGIC = VERSIONED
ORIGINAL AGGREGATE RESULTS = RECORDED
MATERIAL RELATIONSHIP DISPOSITIONS = LEDGERED
FULL LIVE NOMINAL 75-ROW RESULTSET = NOT_DURABLY_CAPTURED
REPLAY DURING PR #215 CORRECTION = NOT_PERFORMED / OUTSIDE AUTHORIZED BOUNDARY
```

This limitation is explicit and must be considered by Product Authority/exact-head review before accepting `STS-M3-04-03` as fully closed.

---

## 11. Task state

```text
STS-M3-04-03 READ_ONLY EXECUTION = EXECUTED
PRODUCT AUTHORITY ACCEPTANCE = PENDING
F-04 = RECONFIRMED / OPEN
F-05 = RECONFIRMED / OPEN
GTI-01 = PROVEN_LIVE / OPEN / NOT_REMEDIATED
SUPABASE MUTATION = NONE
RUNTIME MUTATION = NONE
DATA REPAIR = NONE
HOSTILE-CLIENT TEST = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
```

No automatic transition to `STS-M3-04-04` follows.

---

## 12. Invalidation events

Revalidate affected claims on:

- relevant schema/FK/constraint mutation;
- RLS/grant/policy/trigger/RPC changes;
- change to canonical funnel write routines;
- GTI-01 row repair/removal;
- new audit adjudication that supersedes F-04/F-05/GTI-01 mapping;
- WBS scope change materially affecting STS-M3-04-03.

---

## 13. Next gate

```text
Fresh exact-head documentation/evidence review of PR #215
→ Product Authority may accept / reject / request additional evidence
→ READY remains a separate gate
→ MERGE remains a separate gate
→ STS-M3-04-04 remains separately authorized work
```
