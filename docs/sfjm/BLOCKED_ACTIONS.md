# FECH.AI — SFJM Blocked Actions

**Status:** STS-M2-04D_COMPLETE_ACCEPTED / M2-04E_NOT_AUTHORIZED / FAIL_CLOSED  
**Updated:** 2026-09-06  
**Repository:** wagnerjfjunior/fecha.ai

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
