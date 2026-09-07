# FECH.AI — STS-M2-04C4 Target RLS / Direct-DML Contract — Durable Accepted Evidence

**Status:** `COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS`  
**Evidence class:** `DURABLE_MATERIAL_DECISION_SURFACE / HISTORICAL_ACCEPTED_EVIDENCE / NO_IMPLEMENTATION`  
**Decision date:** 2026-09-06  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Publication status:** `CANDIDATE_UNTIL_MERGED_TO_CANONICAL_MAIN`

## 1. Purpose

This file is the candidate standalone durable publication of the already accepted STS-M2-04C4 material contract. It becomes canonical durable evidence only after merge to FECH.AI `main`.

It does **not** replay M2-04C, perform a fresh database audit, change any target decision or authorize implementation.

Before this file existed, the C4 source packet and accepted result were preserved principally through SFJM plus the versioned C3 matrix. This artifact is intended to close that documentation-structure gap when merged.

## 2. Provenance

Recorded C4 source provenance:

```text
source packet label =
Markdown(20260906-180503).md colado

source packet SHA-256 =
8bec01816fe72c0b9bb6605435b3f5e3cd537572929753fd93ab5949dc113125

source packet lines =
1107

source packet bytes =
108298

C4 verdict =
COMPLETE

M2-04C verdict =
COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS
```

Decision/evidence context recorded by SFJM:

```text
FECH.AI evidence main =
ca30c70e505a9dd8398cd7dace067c95397f96fe

SES evidence main =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

material drift at C4 closure =
NO
```

This provenance hardening does **not** independently recompute the historical source packet SHA-256. The digest above is the already-recorded historical fingerprint.

Canonical dependency objects include:

```text
B3 113×40 matrix blob =
cf3baa6e5a6ab6465688de8f6af43cba7c27d3bd

C3 57-row adjudication blob =
716c23d5f549eb465f3393cdfc5989dda82b69a7
```

## 3. Accepted C1 baseline carried into C4

```text
PUBLIC TABLES = 44
RLS ENABLED = 44 / 44
FORCE RLS = 30 / 44
FORCE RLS FALSE = 14 / 44

anon with any direct table privilege = 0
authenticated with SELECT = 28
authenticated with INSERT/UPDATE/DELETE on at least one operation = 9
```

These are accepted point-in-time evidence anchors, not current-live claims for all future refs.

## 4. Target RLS / FORCE RLS principles

The target rule is semantic, not a numerical mandate.

C4 does **not** prescribe:

```text
FORCE RLS = TRUE on all 44 tables
```

For an ordinary authenticated caller:

```text
effective table authority =
table privilege
+ RLS enabled
+ applicable policy role
+ USING / WITH CHECK semantics
+ policy-helper semantics
```

No applicable policy means default deny even when a table privilege exists.

A table owner without BYPASSRLS is normally exempt from RLS unless FORCE RLS applies.

A BYPASSRLS identity ignores ordinary and forced RLS for its own access.

A postgres-owned SECURITY DEFINER function executes with privileged owner authority; therefore function mode, caller EXECUTE surface and business authorization must be designed together.

Preserve:

```text
RLS != DIRECT TABLE PRIVILEGE
DIRECT TABLE PRIVILEGE != FUNCTION EXECUTE
FUNCTION EXECUTE != BUSINESS AUTHORIZATION
SECURITY DEFINER != AUTHORIZATION
SECURITY INVOKER != AUTOMATICALLY SAFE
```

## 5. USING / WITH CHECK target invariant

C4 does not classify `WITH CHECK = NULL` as an automatic vulnerability.

Where PostgreSQL derives resulting-row checks from `USING`, the relevant question is the predicate's actual semantic coverage.

Required invariant:

```text
OLD ROW AUTHORITY
+
RESULTING ROW AUTHORITY
+
PROTECTED RELATIONSHIP INVARIANTS
```

must remain true.

Known design residuals include:

- `lista_avaliacoes` — actor/corretor binding exists, but every tenant/object relationship on a resulting row is not independently proven;
- `leads` — actor/corretor predicates do not by themselves prove every resulting `empresa_id` relationship;
- `times` — gestor authority can prove manager relation without independently restating every empresa relation.

These remain design/evidence residuals, not automatic exploit declarations.

## 6. Direct-DML target contract

### 6.1 Direct DML intended / structurally supported

```text
lista_avaliacoes
logs
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_lead_message_state
pme_message_templates
```

Target invariants:

```text
authenticated privilege is intentional
+ RLS covers the operation
+ USING / WITH CHECK bind trusted actor and tenant
+ protected fields cannot escape intended scope
+ critical cross-row/business invariants are not delegated
  to race-prone client logic
```

For `logs`, direct INSERT authority does not make client-supplied identity authoritative audit truth.

For `lista_avaliacoes`, resulting-row protected-relationship integrity remains a residual.

### 6.2 RPC-only preferred

```text
mesa_cliente_unidade_enriquecimentos
pme_message_usage
```

For `mesa_cliente_unidade_enriquecimentos`, the accepted structural condition was:

```text
authenticated CRUD grant
+ RLS enabled
+ zero policies
= ordinary authenticated default-deny
```

The grant therefore does not prove intended direct client DML.

For `pme_message_usage`, target architecture favors a controlled append-only operation where trusted usage context is derived server-side.

Current authenticated INSERT authority does not prove arbitrary direct client insertion is part of the target architecture.

Residual:

```text
fresh exhaustive application direct-DML callsite sweep =
NOT PERFORMED
```

C4 classifies target architecture, not exhaustive frontend usage.

## 7. Function mode / EXECUTE ACL contract

```text
FUNCTION SECURITY MODE != EXECUTE ACL
```

A target INVOKER helper may still be internal-only and require no direct authenticated EXECUTE.

A target DEFINER helper does not imply that authenticated callers should invoke it directly.

An authenticated API entry point may legitimately permit authenticated EXECUTE, but its mode and internal privileged boundaries remain separate decisions.

Target ACL principle:

```text
minimum caller class
+ minimum callable entry points
+ no accidental exposure of privileged building blocks
```

C4 authorized no GRANT/REVOKE.

## 8. C3/C4 target-mode closure

Accepted historical C3 projection preserved at C4:

```text
DEFINER = 68
INVOKER = 40
NOT_DETERMINED = 5
TOTAL = 113
```

Unresolved target-authority rows at C4 closure:

```text
004
031
036
047
127
```

`119 relatorio_fornecedor(uuid)` is intentionally not in that five-row set:

```text
119 target authority = RESOLVED / INVOKER
119 current live implementation at C4 = SECURITY DEFINER
implementation/runtime remediation = NOT PERFORMED
```

The five unresolved rows represented bounded authority/product decisions, not missing C4 analytical coverage.

## 9. Final accepted C4 disposition

```text
STS-M2-04C/C4 = COMPLETE

STS-M2-04C =
COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS

MATERIAL_DRIFT =
NO OBSERVED MATERIAL INVALIDATOR AT C4 CLOSURE

IMPLEMENTATION = NOT PERFORMED
DATABASE MUTATION = NO
GRANT / REVOKE = NO
RLS / POLICY CHANGE = NO
FORCE RLS CHANGE = NO
ALTER FUNCTION = NO
APPSEC ASSURANCE = NOT PERFORMED

M2-04C ANALYSIS COMPLETE
!= IMPLEMENTATION COMPLETE
!= CONTROL PROVEN EFFECTIVE
!= SECURITY GO

SECURITY_GO = NOT_GRANTED
```

Later accepted D/E evidence supersedes C4 only where explicitly adjudicated. C4 remains the historical accepted RLS/direct-DML contract and must not be rewritten retroactively.
