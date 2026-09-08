# FECH.AI — Security Assurance Catalog

**Status:** `CANONICAL_CATALOG_V1 / DOCUMENTATION_ONLY / DASHBOARD_JOIN_READY`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Generated from main:** `ea46d3d2dc39fc7f700c1d9ad9d747905c317c85`  
**Canonical machine-readable catalog:** `docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json`

## 1. Purpose

This directory is the canonical discovery and relationship layer for FECH.AI security/test assurance artifacts.

It does **not** replace the executable artifacts, evidence files, WBS, SFJM or runtime proof.

The join contract is:

```text
docs/sfjm/PROGRAM_TASK_GRAPH.md
Qualified ID = STS-MX / STS-MX-YY
        |
        | parent_qualified_id
        v
docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json
        |
        +-- executable test
        +-- test runner
        +-- CI workflow
        +-- test plan / harness
        +-- evidence
```

## 1.1 Full program relationship layer

The assurance catalog is one half of the dashboard relationship model.

Canonical WBS / task / PR relationship:

```text
docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json
```

Human view:

```text
docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.md
```

Full join:

```text
docs/roadmap/fechai-security-to-scale-2026-wbs.md
        |
        | Qualified ID
        v
docs/sfjm/PROGRAM_TASK_GRAPH.md
        |
        v
STS_WBS_PR_RELATIONSHIP_CATALOG.json
        |                         \
        | PR relation              \ test/evidence relation
        v                           v
GitHub PRs                 SECURITY_ASSURANCE_CATALOG.json
```

The relationship catalog also includes future STS tasks through M6, the expanded M3-04 multi-tenant graph, 22 security attack domains and the GitHub Issue/PR shared-number namespace.

## 2. Naming

Every catalog entry has:

```text
catalog_id =
<parent_qualified_id>-<kind><NNN>

display_name =
<parent_qualified_id> — <test/artifact name>
```

Examples:

```text
STS-M1-T001 — executable test
STS-M3-04-T001 — M3-04 direct-DML / tenant-integrity test
STS-M4-04-R001 — MesaCliente runner
STS-M4-04-CI001 — MesaCliente CI workflow
STS-M2-04-E001 — M2-04 evidence
```

The dashboard must join through `parent_qualified_id`.
Historical/local labels may remain in filenames, but the dashboard-facing relationship is always the STS qualified ID.

## 3. Current catalog size

```text
TOTAL CATALOGED ARTIFACTS = 177
```

By artifact type:

- `ASSURANCE_DOCUMENT`: 4
- `CI_WORKFLOW`: 11
- `EXECUTABLE_SQL_TEST`: 79
- `SECURITY_EVIDENCE`: 52
- `TEST_EVIDENCE`: 14
- `TEST_HARNESS_SPEC`: 1
- `TEST_MATRIX`: 1
- `TEST_METADATA`: 2
- `TEST_PLAN`: 1
- `TEST_RUNNER`: 12

By STS parent:

- `STS-M1`: 48
- `STS-M2`: 1
- `STS-M2-01`: 1
- `STS-M2-02`: 1
- `STS-M2-03`: 1
- `STS-M2-04`: 8
- `STS-M2-05`: 1
- `STS-M2-06`: 1
- `STS-M3-01`: 1
- `STS-M3-02`: 1
- `STS-M3-03`: 1
- `STS-M3-04`: 10
- `STS-M4-03`: 4
- `STS-M4-04`: 97
- `STS-M4-05`: 1

## 4. Evidence semantics

The catalog deliberately does **not** convert historical artifacts into current PASS.

```text
VERSIONED TEST != EXECUTED TEST
EVIDENCE FILE != CURRENT PASS
STATIC != LIVE != RUNTIME
CATALOGED != SECURITY GO
```

Existing executable tests are initially marked `CATALOGED_NOT_EXECUTION_PROOF`.
Existing evidence documents are initially marked `HISTORICAL_EVIDENCE_INDEXED_NOT_REEVALUATED`.
A later assurance-reconciliation task can attach exact execution result, environment, tested commit, evidence ref, freshness and invalidation state without changing the stable `catalog_id`.

## 5. Ownership / source of truth

```text
Task/WBS identity:
docs/sfjm/PROGRAM_TASK_GRAPH.md
+ docs/roadmap/fechai-security-to-scale-2026-wbs.md

Assurance artifact relationship:
docs/security/assurance/SECURITY_ASSURANCE_CATALOG.json

Executable tests:
supabase/tests/
scripts/tests/

CI:
.github/workflows/

Evidence:
docs/security/evidence/
domain evidence under docs/*
```

No dashboard or conversation should invent a task/test relationship that is absent from this catalog.

## 6. Unmapped policy

`STS-SEC-UNMAPPED` is a quarantine parent, not a valid Security Go end state.
Any material entry under it must be assigned to a canonical STS owner before Security Go.

## 7. Scope boundary

This catalog is documentation/indexing only. It performs no test execution, Supabase mutation, deploy, runtime mutation or Security Go decision.
