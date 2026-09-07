# FECH.AI — SFJM Blocked Actions

**Status:** STS-M2-04E_COMPLETE_ACCEPTED / IMPLEMENTATION_RESIDUALS_BLOCKED / M2-04F_UNFROZEN / FAIL_CLOSED  
**Updated:** 2026-09-06  
**Repository:** wagnerjfjunior/fecha.ai

## 0. Current STS-M2-04E blocker interpretation

STS-M2-04E semantic target-authority analysis is closed and accepted.

The five former semantic blockers are no longer Product-Authority NOT_DETERMINED:

~~~text
004 = DEFINER target
031 = DEFINER target
036 = lifecycle RETIRE_OR_REPLACE_CURRENT_SEMANTICS
047 = INVOKER target / tenant-team scoped
127 = lifecycle RETIRE / DEPRECATE
~~~

What remains blocked is implementation/lifecycle remediation and assurance, not E target-authority semantics.

Blocked without separate authorization:

~~~text
004 technical remediation
031 technical remediation / caller×ACL reconciliation
036 retirement/replacement implementation
047 global-body/RLS remediation
127 retirement/deprecation implementation
AppSec execution
hostile/cross-tenant runtime assurance
M2-04F definition/execution
Ready
merge
deploy
Security Go
~~~


## 1. Authority

This is a thin material-blocker view. Principal state:

~~~text
docs/sfjm/CURRENT_STATE.md
~~~

Resolve volatile GitHub/environment facts live before acting.

## 2. Current program/security blocks

The following remain blocked unless separately and explicitly authorized:

~~~text
Security Go
broad paid commercialization dependent on Security Go
unbounded production/security testing
active hostile-client or cross-tenant runtime testing
D-01 through D-08 technical remediation
M2-04E execution
M2-04F execution
Supabase/Auth/business-data mutation
Ready
merge
deploy
~~~

## 3. M2-04D closure and mutation blocks

~~~text
STS-M2-04D =
COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT

analysis/design = CLOSED
technical remediation = NOT_AUTHORIZED
~~~

Blocked technical actions include:

~~~text
ALTER FUNCTION
SECURITY DEFINER / INVOKER runtime change
CREATE / DROP / ALTER TRIGGER
GRANT / REVOKE
owner / search_path runtime mutation
migration creation/application
SQL / DDL / DML mutation
RLS / policy mutation
runtime/frontend implementation
Edge Function / Vercel deployment
runtime hostile/concurrency assurance
~~~

M2-04D is no longer blocked as an analysis slice. Only its technical remediation and assurance backlog remain blocked.

## 4. Current M2-04 gate

~~~text
M2-04C = COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS
M2-04D = COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT
M2-04E = NOT_AUTHORIZED
M2-04F = NOT_AUTHORIZED
Security Go = NOT_GRANTED
~~~

## 5. Current unresolved M2-04C authority blockers

```text
004 aprovar_rejeitar_mesa
031 gerenciar_lista
036 get_dashboard_master
047 get_stats_horario
127 solicitar_lote_forcado
```

Blocker 119 `relatorio_fornecedor(uuid)` is resolved at target-mode authority level as INVOKER, but implementation/runtime assurance remains separately blocked.

## 5. Evidence/lifecycle separation

```text
STATIC != LIVE != RUNTIME
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
RLS ENABLED != POLICY CORRECT
FORCE RLS != SECURITY DEFINER CONSTRAINED BY RLS
MERGEABLE != APPROVED
LIVE_DATABASE_VALIDATED != SECURITY_GO
```

## 6. Removal rule

Remove or narrow a blocker only when an exact Product Authority decision and sufficient material evidence change the current safe action.
