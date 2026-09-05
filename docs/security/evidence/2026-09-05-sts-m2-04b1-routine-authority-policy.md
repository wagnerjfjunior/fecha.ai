# FECH.AI — STS-M2-04B1 — Routine Authority Policy Core

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Evidence class:** `TARGET_POLICY / PRODUCT_AUTHORITY_ACCEPTED / NO_IMPLEMENTATION`  
**Decision date:** 2026-09-05  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision anchors

```text
FECH.AI decision-anchor main =
ca77d81c3d2a6209536664128bda209996a7f423

SES ref used by the accepted specialist result =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

specialist result packet =
FECHAI-STS-M2-04B1-ROUTINE-AUTHORITY-POLICY-CORE

specialist result SHA-256 =
8171310f4101831ba34623dac9aff37b13e04aeb02f81808fc163d693cf801bf

specialist verdict =
BACKEND_DATA_M2_04B1_ROUTINE_POLICY =
READY_FOR_MASTER_PROJECT_ADJUDICATION
```

The Product Authority accepted STS-M2-04B1 as `COMPLETE / ACCEPTED WITH RESIDUALS`, limited to the target routine-authority policy.

## 2. Accepted target rules

```text
SECURITY DEFINER =
PRIVILEGED EXCEPTION

SECURITY INVOKER =
PREFERRED DEFAULT
WHEN CALLER AUTHORITY IS DELIBERATELY SUFFICIENT
```

Routine authority is not determined by security mode alone.

```text
ROUTINE AUTHORITY
=
ROUTINE CLASS
+ CANONICAL CALLER
+ EXECUTE ACL
+ SECURITY MODE
+ EFFECTIVE OWNER AUTHORITY
+ TRUSTED ACTOR / TENANT / ROLE DERIVATION
+ SIDE-EFFECT / TRANSACTION CONTRACT
+ TRANSITIVE AUTHORITY
+ PROOF OBLIGATION
```

Preserve:

```text
SECURITY DEFINER != AUTHORIZATION
SECURITY INVOKER != AUTOMATICALLY SAFE
EXECUTE != BUSINESS AUTHORIZATION
service_role EXECUTE != SERVICE USE PROVEN
NO VERSIONED CALLER != UNUSED
CALLER FOUND != EXECUTE ACL CORRECT
OUTER ROUTINE AUTHORIZED != INNER ROUTINE MAY EXPAND AUTHORITY
```

## 3. Accepted routine authority taxonomy

The accepted authority classes are:

```text
ANONYMOUS_READ_API
ANON_COMMAND_EXCEPTION
AUTHENTICATED_QUERY
AUTHENTICATED_COMMAND
PRIVILEGED_OPERATION
SERVICE_ONLY_COMMAND
DB_INTERNAL_HELPER
TRIGGER_ONLY
```

Caller provenance and lifecycle are separate axes, not authority classes.

Representative provenance states:

```text
VERSIONED_APPLICATION
DB_INTERNAL
TRIGGER
TRUSTED_SERVICE_RUNTIME
EXTERNAL_INTEGRATION
LEGACY_RUNTIME
NO_VERSIONED_CALLER
NOT_DETERMINED
```

Representative lifecycle states:

```text
ACTIVE_CONTRACT
LEGACY_SUPPORTED
UNUSED_CANDIDATE
NOT_DETERMINED
```

Do not collapse:

```text
NO_VERSIONED_CALLER
→ UNUSED
→ SAFE TO REVOKE
```

without separate evidence.

## 4. SECURITY DEFINER target contract

A `SECURITY DEFINER` routine is allowed only as a justified privilege-elevation boundary. The contract must identify at minimum:

- exact elevation required and why caller authority is deliberately insufficient;
- authoritative business actor identity;
- tenant/company derivation from trusted data-side state;
- role/permission/ownership derivation from trusted state rather than client claims;
- declared DML/side effects and transaction/concurrency/invariant obligations;
- authorization before privileged effect;
- controlled owner authority;
- deterministic safe `search_path`;
- canonical caller and explicit EXECUTE allowlist;
- transitive/nested authority contract;
- auditability;
- bounded revoke/kill/rollback path.

Current ownership by a broad role is not automatically target-approved.

```text
search_path PRESENT
!=
search_path SAFE
```

The accepted M2-02 fact that 137/137 current SECURITY DEFINER routines have explicit `proconfig/search_path` is AS-IS evidence only.

## 5. SECURITY INVOKER target contract

`SECURITY INVOKER` is the preferred default when the caller's database authority is intentionally the authority that should govern the operation.

This preference is conditional on correct grants, RLS/policies, tenant/business authorization, inputs, invariants and output boundaries.

Detailed RLS/direct-DML semantics remain owned by STS-M2-04C.

## 6. Accepted EXECUTE / caller rules

```text
canonical caller exists + required principal lacks EXECUTE
→ CONTRADICTORY / NOT TARGET-COMPLIANT until reconciled

EXECUTE exists + no canonical caller proven
→ UNEXPLAINED REACHABILITY / NOT A STABLE TARGET STATE

DB_INTERNAL_HELPER + client EXECUTE
→ FORBIDDEN BY DEFAULT

SERVICE_ONLY + authenticated EXECUTE
→ CLASS × ACL CONTRADICTION

external caller → outer routine → internal helper
→ client normally receives EXECUTE only on outer routine

broad/default PUBLIC/anon/authenticated EXECUTE
→ NOT TARGET AUTHORITY without explicit class/caller/principal contract
```

## 7. Accepted internal/service/transitive rules

A `DB_INTERNAL_HELPER` is not a product/API entrypoint and has no direct client EXECUTE by default.

A nested internal helper may itself be SECURITY DEFINER only when it has a separate narrow elevation requirement, no direct client exposure, bounded owner/search_path, and cannot widen trusted parent authority.

`SERVICE_ONLY_COMMAND` requires evidence of the canonical trusted runtime, service owner, business/tenant authorization, side-effect scope, secret boundary, runtime proof and revoke/kill path.

```text
PROJECT_LOCAL_TOOL_PROOF
!=
UNIVERSAL SES RUNTIME CERTIFICATION
```

## 8. Target-prohibited states

The target policy prohibits, among other states:

- SECURITY DEFINER without an explicit elevation reason;
- privileged routine exposed through inherited/default client EXECUTE;
- direct client EXECUTE on DB_INTERNAL_HELPER without reclassification;
- client-supplied tenant/company/role/ownership treated as authorization;
- service_role capability treated as business authorization;
- canonical caller with incompatible EXECUTE ACL accepted as steady state;
- privileged routine with neither canonical external caller nor evidenced internal/service/external-integration contract;
- nested privileged chain that expands authority without independent justification;
- anonymous mutation treated as ordinary API rather than extraordinary exception;
- privileged object resolution through an untrusted writable schema/search_path;
- critical race-sensitive invariant protected only by non-atomic check-then-act application logic.

## 9. Accepted residuals

The following remain unresolved and are not waived:

```text
160 routines individually target-classified = NO
current 137 SECURITY DEFINER routines compliant with B1 = NOT_DETERMINED
current search_path semantic safety = NOT_DETERMINED
current owner suitability = NOT_DETERMINED
31 anon EXECUTE routines = AS-IS residual surface
8 anon EXECUTE + actual DML routines = AS-IS residual surface
134 authenticated EXECUTE routines = AS-IS residual surface
151 service_role EXECUTE routines = AS-IS residual surface
2 PUBLIC EXECUTE routines = AS-IS residual surface
caller × ACL contradictions = unresolved per-object
service-only / no-versioned-caller classifications = unresolved per-object
runtime hostile-client / cross-tenant assurance = NOT_DETERMINED
```

`ACCEPTED WITH RESIDUALS` does not convert any current routine into target-compliant authority.

## 10. Downstream B2 preparation boundary

Product Authority authorized preparation of the STS-M2-04B2 scope, but not B2 execution.

B2 should be a bounded high-risk classification slice, applying this B1 policy first to externally reachable or authority-sensitive cases.

Candidate categories for scope preparation include:

- PUBLIC EXECUTE routines;
- anon EXECUTE + actual-DML routines;
- externally reachable lock/concurrency routine `acquire_lote_lock(uuid,uuid)`;
- caller×ACL contradictions including `avaliar_lista(uuid, integer, text)` and `trilha_lead(uuid)`;
- service-only privileged routines with broader client ACL;
- privileged no-versioned-caller routines;
- legacy `redefinir_senha_corretor`.

The exact B2 object list must be reconstructed from accepted M2-02/M2-03 evidence and current live GitHub/catalog evidence as material before B2 substantive classification.

```text
B2 SCOPE PREPARATION = AUTHORIZED
B2 SUBSTANTIVE CLASSIFICATION = NOT_AUTHORIZED
B2 REMEDIATION = NOT_AUTHORIZED
```

## 11. Evidence and assurance boundaries

This B1 acceptance is target-policy evidence. It does not prove current implementation compliance or runtime effectiveness.

```text
TARGET POLICY != CURRENT DATABASE COMPLIANT
TARGET POLICY != RUNTIME ASSURANCE
TARGET POLICY != APPSEC PASS
TARGET POLICY != SECURITY GO
```

No live database query was required for B1 target-policy design because accepted M2-02/M2-03 evidence supplied the necessary AS-IS anchors.

## 12. Freshness / invalidation

Proportional revalidation is required if a material event changes:

- the accepted target routine-authority policy;
- current routine universe/signatures/security modes/owners/search_path/ACLs material to a downstream classification;
- canonical caller/provenance evidence;
- grants/default privileges or service/client principal semantics;
- Product Authority scope;
- material runtime evidence relevant to a claim being consumed.

Do not reopen B1 merely because downstream routine classification discovers non-compliance. Non-compliance is expected input to B2/B3/remediation planning.

## 13. Authority boundary

This acceptance and reconciliation authorize no implementation.

```text
B2 EXECUTION = NOT_AUTHORIZED
SQL / DDL / DML = NOT_AUTHORIZED
Supabase / Auth / data mutation = NOT_AUTHORIZED
GRANT / REVOKE / default-privilege change = NOT_AUTHORIZED
routine / owner / search_path mutation = NOT_AUTHORIZED
runtime hostile testing = NOT_AUTHORIZED
deploy = NOT_AUTHORIZED
Ready = NOT_AUTHORIZED
merge = NOT_AUTHORIZED
Security Go = NOT_GRANTED
```
