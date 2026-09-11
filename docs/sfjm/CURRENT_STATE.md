# FECH.AI — SFJM Current Material State

**Status:** `CURRENT / MATERIAL_RECORDED_STATE / STS-M3-04-03_READ_ONLY_EXECUTED_ACCEPTANCE_PENDING`  
**Updated:** `2026-09-11`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Current material state

Product Authority authorized and FECH.AI executed `STS-M3-04-03 — Global Tenant Surface & Relationship Inventory` in bounded `READ_ONLY / evidence-first` mode against the live FECH.AI/Supabase catalog.

```text
execution base main =
b274adac84f2d4a27a7a5147c551dc23469a610c

publication =
PR #215 / PR_HEAD_ONLY until merged

STS-M3 =
ACTIVE

STS-M3-04 =
ACTIVE / SCOPE_EXPANDED / REBASELINE_REQUIRED

STS-M3-04-01 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-04-02 =
COMPLETE / ACCEPTED WITH RESIDUALS

STS-M3-04-03 =
READ_ONLY_EXECUTED / ACCEPTANCE_PENDING

STS-M3-04-04..10 =
DEFINED_NOT_AUTHORIZED

CURRENT_IMMEDIATE_AUTHORIZED_TECHNICAL_EXECUTION =
NONE

Security Go =
NOT_GRANTED
```

`READ_ONLY_EXECUTED` means the bounded evidence task ran. It does **not** mean `COMPLETE`, `ACCEPTED`, remediated, READY, merged, or authority to start the next child.

## 2. Current security findings carried by STS-M3-04-03

```text
F-04 = RECONFIRMED / OPEN
F-05 = RECONFIRMED / OPEN
GTI-01 = PROVEN_LIVE / OPEN / NOT_REMEDIATED
```

`GTI-01` evidence boundary:

```text
relationship = public.leads.funil_estagio_id -> public.funil_estagios.id
stored cross-tenant mismatch count = 1
row identifier / PII persisted in evidence = NO
structural child tenant invariant = MISSING / NOT OBSERVED
reviewed canonical authenticated funnel writers = TENANT-GUARDED
ordinary authenticated reproduction through those reviewed routines = NOT_PROVEN
severity = TO_BE_ADJUDICATED
canonical F-number = NOT_ASSIGNED
```

No data repair or database invariant remediation has been performed.

## 3. Evidence completeness boundary

Original READ_ONLY observations include:

```text
public base tables = 44
public views = 8
public policies = 82
user triggers = 31
public constraints = 271
public functions = 160
tables carrying empresa_id = 38
empresa_id tables with RLS = 38 / 38
empresa_id tables with FORCE RLS = 25 / 38
composite tenant-bound FKs = 10
simple tenant-bearing FKs without matching composite tenant pair = historical aggregate 75
```

Preserve the anti-overclaim boundary:

```text
historical aggregate 75 = OBSERVED DURING ORIGINAL READ_ONLY SESSION
full nominal 75-row resultset durably captured = NO
candidate reproduction manifest = VERSIONED
candidate reproduction manifest replayed by PR #215 correction = NO
exact rowset equivalence = NOT_PROVEN
```

The versioned SQL manifest is a candidate replay procedure for a separately authorized future READ_ONLY execution; it is not proof that the reconstructed query yields the identical historical rowset.

## 4. Mutation boundary

```text
Supabase mutation = NONE
Auth mutation = NONE
business-data mutation = NONE
runtime/frontend mutation = NONE
RLS / FORCE RLS mutation = NONE
grant / policy mutation = NONE
RPC / function / trigger mutation = NONE
hostile-client execution = NONE
GTI-01 repair = NONE
```

## 5. Current authorization/lifecycle boundary

The Product Authority authorization chain for this task is recorded in `docs/sfjm/AUTHORIZATIONS.md`.

Current prohibitions:

```text
READY = NOT_AUTHORIZED
MERGE = NOT_AUTHORIZED
DEPLOY = NOT_AUTHORIZED
STS-M3-04-04 EXECUTION = NOT_AUTHORIZED
SUPABASE / AUTH / DATA MUTATION = NOT_AUTHORIZED
HOSTILE-CLIENT ACTIVE EXECUTION NOW = NOT_AUTHORIZED
Security Go = NOT_GRANTED
```

The deferred synthetic offensive-lab authority from PR #213 remains valid for its later bounded window but is not the current action and creates no current cost or execution authority.

## 6. Current semantic next gate

The current semantic next action is owned by `docs/sfjm/NEXT_SAFE_ACTION.md`.

At this material state:

```text
finish bounded PR #215 documentary reconciliation
→ fresh exact-head documentation/evidence review when admitted by the applicable Product Authority authorization
→ Product Authority adjudicates STS-M3-04-03 result
→ only then may a separately authorized next M3-04 child begin
```

No task transition may be inferred solely from publication of this file.

## 7. Durable evidence package

```text
docs/security/evidence/2026-09-10-sts-m3-04-03-global-tenant-surface-relationship-inventory.md
docs/security/evidence/2026-09-10-sts-m3-04-03-global-tenant-surface-relationship-inventory.json
docs/security/evidence/2026-09-10-sts-m3-04-03-material-relationship-ledger.json
docs/security/evidence/2026-09-10-sts-m3-04-03-readonly-reproduction-manifest.sql
docs/security/evidence/2026-09-10-sts-m3-04-03-canonical-reconciliation-delta.json
docs/sfjm/CURRENT_ISSUES.md
docs/sfjm/NEXT_SAFE_ACTION.md
```

## 8. Historical continuity preservation

The exact pre-`STS-M3-04-03` `CURRENT_STATE.md` content is preserved inside this PR at:

```text
docs/sfjm/history/2026-09-11/CURRENT_STATE.pre-sts-m3-04-03.md
source blob = 6faddd04423ff0dbdff7f651f4e9b996b45ea797
```

This current file is the principal `MATERIAL_RECORDED_STATE` view defined by `docs/sfjm/INDEX.md`. The historical snapshot is provenance only and must not override this current state when the two conflict.

## 9. Invalidation events

Revalidate affected claims on any material change to:

- relevant schema/FK/constraint state;
- RLS, grants, policies, triggers or RPC/function definitions;
- canonical funnel writer definitions;
- GTI-01 stored-row disposition;
- Product Authority acceptance/rejection of STS-M3-04-03;
- PR #215 evidence semantics;
- next-child authorization;
- Security Go/commercialization decision.

Ordinary main movement or PR lifecycle alone does not resolve any material finding.
