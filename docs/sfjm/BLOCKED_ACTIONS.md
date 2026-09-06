# FECH.AI — SFJM Blocked Actions

**Status:** `STS-M2-04C_COMPLETE_WITH_BOUNDED_RESIDUALS / NEXT_SLICE_NOT_AUTHORIZED / FAIL_CLOSED`  
**Updated:** `2026-09-06`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin material-blocker view. Principal state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve volatile GitHub/environment facts live before acting.

## 2. Current program/security blocks

The following remain blocked unless separately and explicitly authorized:

```text
Security Go
broad paid commercialization dependent on Security Go
unbounded production/security testing
active hostile-client or cross-tenant runtime testing
production mutation or remediation derived from M2-04C without separate authorization
```

## 3. STS-M2-04C mutation blocks

M2-04C read-only analysis/adjudication is authorized. The following are not:

```text
SQL / DDL / DML mutation
migration creation/application as implementation
Supabase/Auth/business-data mutation
RLS enable/disable or FORCE RLS change
policy create/alter/drop
GRANT / REVOKE / default-privilege change
SECURITY DEFINER / INVOKER runtime change
function owner / search_path change
runtime/frontend implementation
Edge Function / Vercel deployment
Ready
merge
deploy
M2-04D execution
M2-04E execution
M2-04F execution
Security Go
```

## 4. Current M2-04C gate

```text
C1 = COMPLETE
C2 = COMPLETE WITH RESIDUAL EVIDENCE GAPS / ACCEPTED
C3 = COMPLETE WITH RESIDUAL NOT_DETERMINED / ACCEPTED
C4 = COMPLETE / ACCEPTED

M2-04C = COMPLETE / ACCEPTED WITH BOUNDED AUTHORITY RESIDUALS
```

M2-04C analysis is closed. The five residual authority cases remain bounded downstream decision/remediation inputs. M2-04D/E/F are not authorized and must not begin without a new Product Authority decision.

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
