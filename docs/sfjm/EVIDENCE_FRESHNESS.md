# FECH.AI — SFJM Evidence Freshness

**Status:** `CURRENT / ACTIVE_EVIDENCE_CLAIMS / STS-M3-04-03`  
**Updated:** `2026-09-11`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Purpose

This ledger records the evidence claims currently material to the FECH.AI Security-to-Scale continuation. It distinguishes execution evidence, versioned evidence, missing evidence and invalidation events.

Historical evidence-freshness lineage preceding `STS-M3-04-03` is preserved exactly at:

```text
docs/sfjm/history/2026-09-11/EVIDENCE_FRESHNESS.pre-sts-m3-04-03.md
source blob = 9a344952d2a001796123f17402667c92ea45217c
```

That snapshot is historical provenance. Current claims below control when they conflict with stale historical wording.

## 2. Claim — STS-M3-04-03 Global Tenant Surface & Relationship Inventory

```text
claim_id = STS-M3-04-03-LIVE-INVENTORY
state = LIVE_OBSERVED / READ_ONLY_EXECUTED / ACCEPTANCE_PENDING
execution_base_main = b274adac84f2d4a27a7a5147c551dc23469a610c
environment = FECH.AI Pilot Production / Supabase live catalog
publication = PR #215 / PR_HEAD_ONLY until merged
Supabase mutation = NONE
runtime mutation = NONE
```

Source coverage from the original operating session:

```text
public tables/views/policies/functions/triggers/constraints = LIVE_ENUMERATED
selected compensating-control definitions = TARGETED LIVE READ
selected canonical funnel writer definitions = TARGETED LIVE READ
relationship consistency checks = LIVE AGGREGATE COUNTS ONLY
row-level customer/lead payload persistence = NONE
```

Observed current-surface cardinalities:

```text
public base tables = 44
public views = 8
public policies = 82
public user triggers = 31
public constraints = 271
public functions = 160
tables with empresa_id = 38
empresa_id tables with RLS = 38 / 38
empresa_id tables with FORCE RLS = 25 / 38
composite tenant-bound FKs = 10
simple object FKs between tenant-bearing tables = 83
simple tenant-bearing FKs without matching composite tenant pair = historical aggregate 75
```

The `44 / 8 / 82 / 31 / 271 / 160` cardinalities matched the prior 2026-09-09 live audit at count level only. This is not byte-for-byte definition equivalence.

## 3. Claim — F-04

```text
finding = F-04
surface = public.lista_avaliacoes
state = RECONFIRMED_OPEN
prior severity = HIGH
downstream = STS-M3-04-04 / STS-M3-04-07 / STS-M3-04-09
stored cross-tenant mismatches in tested F-04 relationships = 0
```

Evidence boundary:

```text
authenticated direct INSERT/UPDATE exposure = OBSERVED
RLS/FORCE RLS = OBSERVED
policy actor boundary = OBSERVED
missing resulting-row tenant relationship invariant = RECONFIRMED
zero stored mismatch = DOES NOT CLOSE PREVENTIVE STRUCTURAL GAP
```

Invalidators/revalidation triggers:

- `lista_avaliacoes` schema/FK/constraint change;
- RLS/policy/grant/trigger change on the affected path;
- authenticated writer change;
- separately accepted remediation/refutation evidence.

## 4. Claim — F-05

```text
finding = F-05
surface = PME catalog relationships
state = RECONFIRMED_OPEN
prior severity = HIGH
downstream = STS-M3-04-05 / STS-M3-04-07 / STS-M3-04-09
stored cross-tenant mismatches in tested PME relationships = 0
```

Evidence boundary:

```text
authenticated tenant-admin write surface = OBSERVED
actor/company authority = OBSERVED
universal object-id + empresa-id resulting-row invariant = NOT ESTABLISHED
zero stored mismatch = DOES NOT CLOSE PREVENTIVE STRUCTURAL GAP
```

Invalidators/revalidation triggers:

- PME catalog schema/FK/constraint change;
- policy/grant/trigger/writer changes;
- accepted remediation/refutation evidence.

## 5. Claim — GTI-01

```text
finding = GTI-01
namespace = STS-M3-04-03 local finding
canonical F-number = NOT_ASSIGNED
severity = TO_BE_ADJUDICATED
state = PROVEN_LIVE / OPEN / NOT_REMEDIATED
relationship = public.leads.funil_estagio_id -> public.funil_estagios.id
stored cross-tenant mismatch count = 1
row identifier / PII persisted = NO
```

Structural evidence:

```text
simple child FK to funil_estagios.id = OBSERVED
child composite (funil_estagio_id, empresa_id) tenant invariant = NOT OBSERVED
parent candidate-key shape suitable for future composite design = OBSERVED
```

Canonical write-path evidence reviewed in the original session:

```text
mover_funil = TARGETED LIVE DEFINITION READ
mover_funil_batch = TARGETED LIVE DEFINITION READ
mover_funil_lote = TARGETED LIVE DEFINITION READ
registrar_feedback = TARGETED LIVE DEFINITION READ
reviewed routines tenant-guard destination stage = OBSERVED
ordinary authenticated reproduction through those routines = NOT_PROVEN
```

This proves active inconsistent stored state plus a missing database structural invariant. It does not prove that an ordinary authenticated user can currently recreate the state through the four reviewed canonical routines.

Invalidators/revalidation triggers:

- disposition/repair/removal of the one inconsistent row;
- change to `leads` or `funil_estagios` schema/FKs/constraints;
- change to the reviewed funnel writer definitions;
- a new direct writer/reachability finding;
- accepted remediation/refutation evidence.

## 6. Claim — nominal 75-row relationship universe

```text
historical aggregate observed in original READ_ONLY session = 75
full nominal 75-row resultset durably captured during original session = NO
nominal row identities inferred from count = FORBIDDEN
```

Versioned procedure:

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-readonly-reproduction-manifest.sql
classification = CANDIDATE REPLAY / REPRODUCTION PROCEDURE
executed by PR #215 documentation correction = NO
exact rowset equivalence to original historical observation = NOT_PROVEN
```

A future exact-current nominal rowset requires a separately admitted READ_ONLY replay. No Supabase replay is authorized or implied by the documentation publication itself.

## 7. Durable evidence package

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-global-tenant-surface-relationship-inventory.md
docs/security/evidence/2026-09-10-sts-m3-04-03-global-tenant-surface-relationship-inventory.json
docs/security/evidence/2026-09-10-sts-m3-04-03-material-relationship-ledger.json
docs/security/evidence/2026-09-10-sts-m3-04-03-readonly-reproduction-manifest.sql
docs/security/evidence/2026-09-10-sts-m3-04-03-canonical-reconciliation-delta.json
docs/security/audits/2026-09-09-live-db-evidence.md
docs/security/assurance/2026-09-09-audit-to-wbs-zero-residual-plan.md
```

Evidence classification must remain explicit:

```text
PR_HEAD_ONLY != MERGED_TO_MAIN
VERSIONED_QUERY != EXECUTED_QUERY
LIVE_AGGREGATE_COUNT != ROWSET_PERSISTED
DATABASE_CATALOG_OBSERVED != RUNTIME_HOSTILE_CLIENT_PASS
READ_ONLY_EXECUTED != PRODUCT_AUTHORITY_ACCEPTED
```

## 8. Current lifecycle/freshness state

```text
STS-M3-04-03 execution = READ_ONLY_EXECUTED
Product Authority acceptance = PENDING
PR #215 publication = PR_HEAD_ONLY
READY = NOT_AUTHORIZED
MERGE = NOT_AUTHORIZED
CURRENT_IMMEDIATE_AUTHORIZED_TECHNICAL_EXECUTION = NONE
Security Go = NOT_GRANTED
```

Ordinary PR lifecycle movement does not itself invalidate the underlying original live observations. Material changes to affected database definitions, grants/policies, relevant writer definitions or GTI-01 data state do.

## 9. Deferred final offensive-lab evidence boundary

The future `STS-M3-06 + STS-M5-01 + STS-M5-02` synthetic offensive path remains `AUTHORIZED_DEFERRED` / `AUTHORIZED_DEFERRED_FINAL_TEST` under the Product Authority decision recorded in `AUTHORIZATIONS.md`.

```text
execution now = NO
cost-bearing environment creation now = NOT_AUTHORIZED
real customer/lead/business data = FORBIDDEN
destructive production attack = FORBIDDEN
```

No current STS-M3-04-03 evidence claim converts that future lab evidence into PASS.

## 10. Update rule

Update this ledger on a material evidence event, including:

- live schema/FK/constraint change affecting current claims;
- RLS/grant/policy/trigger/RPC/writer change affecting current claims;
- GTI-01 data disposition;
- new accepted/refuting evidence for F-04/F-05/GTI-01;
- Product Authority acceptance/rejection materially changing the task evidence state;
- superseding audit or independent assurance result.

Do not update solely because a SHA advances or a documentation-only lifecycle transition occurs with no evidence effect.
