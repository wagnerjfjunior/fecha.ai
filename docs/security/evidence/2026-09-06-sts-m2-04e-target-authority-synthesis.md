# FECH.AI — STS-M2-04E — Target Authority Synthesis Acceptance

**Status:** `COMPLETE / ACCEPTED WITH IMPLEMENTATION, LIFECYCLE AND RUNTIME-ASSURANCE RESIDUALS`  
**Date:** 2026-09-06  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Decision base main:** `aa266df3124f407a3f2c155c8f8ab5c193707783`  
**SES ref:** `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`  
**Environment:** Pilot Production / SaaS multi-tenant / multiempresa  
**Mode:** documentation-only / no runtime mutation

## 1. Purpose

Durably record the Product Authority acceptance of the STS-M2-04E cross-slice target-authority synthesis and the final adjudication of the five C3 routines that previously remained semantically NOT_DETERMINED.

This artifact does not implement the target, perform AppSec assurance, prove hostile/cross-tenant runtime behavior, grant Security Go, or define STS-M2-04F.

## 2. Historical provenance preserved

Historical C3 remains:

```text
68 DEFINER
40 INVOKER
5 NOT_DETERMINED
113 total
```

E does not rewrite that history. It resolves the five semantic residuals downstream.

## 3. E-level architecture projection

```text
TOTAL INVENTORIED ROUTINES = 113
TARGET DEFINER = 70
TARGET INVOKER = 41
SEMANTIC TARGET-AUTHORITY NOT_DETERMINED = 0
NON-MODE LIFECYCLE DISPOSITIONS = 2
- 036 get_dashboard_master()
- 127 solicitar_lote_forcado(uuid)
```

## 4. 004 — aprovar_rejeitar_mesa(uuid,text,text)

Target mode: **SECURITY DEFINER**.

Required authority chain:

```text
auth.uid()
→ active actor/profile
→ gestor eligibility
→ actor empresa
→ trusted mesa_simulacoes row
→ p_simulacao_id tenant/object binding
→ permitted state transition
→ privileged mutation
→ audit
```

`p_simulacao_id` is a locator, not authority.

Current implementation remediation, cross-tenant negatives, transition proof, audit atomicity and runtime/AppSec assurance remain open.

## 5. 031 — gerenciar_lista(uuid,text,text)

Target mode: **SECURITY DEFINER**.

Required authority chain:

```text
auth.uid()
→ active gestor
→ actor empresa
→ managed-team relation
→ list empresa binding
→ listas.time_id ∈ my_times_como_gestor()
→ permitted lifecycle action
→ coordinated privileged mutation
→ audit
```

Do not invent an independent `assigned_gestor_id` relation. `lista_visibilidade` expresses distribution/visibility authority and does not itself grant lifecycle-management sovereignty.

Current body remediation, caller×ACL reconciliation, cross-tenant/wrong-team proof and runtime/AppSec assurance remain open.

## 6. 036 — get_dashboard_master()

Canonical Product Authority rule:

```text
ROOT / ADMIN_GLOBAL = PLATFORM CONTROL PLANE
platform authority != automatic tenant business authority
```

The current global commercial-data semantics are not target-compliant.

Target lifecycle disposition:

```text
RETIRE_OR_REPLACE_CURRENT_SEMANTICS
```

This is a non-mode lifecycle disposition. Actual retirement/replacement is not authorized by this acceptance.

## 7. 047 — get_stats_horario()

Target mode: **SECURITY INVOKER**.

Target semantics:

```text
GESTOR = TEAM CONTROL PLANE
authenticated actor
→ actor empresa
→ managed teams
→ RLS-visible leads/events
→ bounded aggregation
```

Root does not gain ordinary global commercial-data access through this routine.

Current global-body remediation, RLS/team-scope proof, negative tests and runtime/AppSec assurance remain open.

## 8. 127 — solicitar_lote_forcado(uuid)

Product contract:

```text
broker requests next lot for self
```

There is no target product capability for gestor/admin/root to request a lot for another broker.

Target lifecycle disposition:

```text
RETIRE / DEPRECATE forced-user capability
```

This is a non-mode lifecycle disposition. Actual removal/deprecation implementation is not authorized here.

Preserve the self-only lot request, mandatory evaluation gate and allocation/concurrency integrity.

## 9. Final semantic closure

```text
PRODUCT-AUTHORITY SEMANTIC NOT_DETERMINED
among 004 / 031 / 036 / 047 / 127
=
0
```

Preserve:

```text
TARGET AUTHORITY RESOLVED != CURRENT IMPLEMENTATION CORRECT
TARGET AUTHORITY RESOLVED != APPSEC PASS
TARGET AUTHORITY RESOLVED != RUNTIME ASSURANCE
TARGET AUTHORITY RESOLVED != SECURITY GO
```

## 10. Residuals

```text
004 implementation remediation = OPEN
031 implementation/caller-ACL remediation = OPEN
036 lifecycle remediation = NOT IMPLEMENTED
047 implementation/RLS remediation = OPEN
127 lifecycle remediation = NOT IMPLEMENTED
AppSec = NOT PERFORMED
hostile/cross-tenant runtime assurance = NOT PERFORMED
Security Go = NOT_GRANTED
```

## 11. STS-M2-04F boundary

```text
STS-M2-04F =
NOT EXECUTED
NOT AUTHORIZED
SEMANTIC SCOPE NOT YET CANONICALLY FROZEN
```

No semantic meaning may be assigned to M2-04F from this artifact.

## 12. Rollback

Documentation-only rollback: revert the commit that introduces this acceptance artifact and the bounded SFJM reconciliation. No runtime/data rollback is involved.
