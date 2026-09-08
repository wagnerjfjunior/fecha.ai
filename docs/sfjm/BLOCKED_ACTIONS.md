# FECH.AI — SFJM Blocked Actions

## 0. CURRENT — STS-M3-02 ACCEPTED / STS-M3-03 EXECUTION BLOCKED PENDING AUTHORIZATION — 2026-09-08

~~~text
STS-M3 = ACTIVE
STS-M3-01 = COMPLETE / ACCEPTED / FROZEN
STS-M3-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M3-03 = NEXT_ELIGIBLE / NOT_AUTHORIZED
DATABASE STRATEGY = V2_STRANGLER / SAME_DATABASE_FIRST
Security Go = NOT_GRANTED
~~~

M3-02 analysis/publication is not a blocker. Its implementation/runtime/AppSec residuals are preserved for downstream bounded work.

Still blocked unless separately authorized:

~~~text
STS-M3-03 substantive execution
STS-M3-04 execution
STS-M3-05 execution
STS-M3-06 execution
M3-02 target implementation/remediation
support-mode implementation
legacy root / role-flag retirement
runtime/frontend/App.jsx mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grants / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
active hostile-client / cross-tenant production testing
deploy / production mutation
Security Go
commercialization authorization
~~~

Accepted M3-02 residuals are tracked as residual risks, not as blockers for the completed contract-freeze task.


## 0.1 HISTORICAL / SUPERSEDED — STS-M3-01 ACCEPTED / STS-M3-02 EXECUTION BLOCKED PENDING AUTHORIZATION — 2026-09-07

~~~text
STS-M3 = ACTIVE
STS-M3-01 = COMPLETE / ACCEPTED
STS-M3-02 = NEXT_ELIGIBLE / NOT_AUTHORIZED
DATABASE STRATEGY = V2_STRANGLER / SAME_DATABASE_FIRST
Security Go = NOT_GRANTED
~~~

M3-01 analysis/publication is not a blocker. Its implementation residuals are preserved for downstream bounded work.

Still blocked unless separately authorized:

~~~text
STS-M3-02 substantive execution
M3-01 target implementation/remediation
legacy root/role-flag retirement
runtime/frontend/App.jsx mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grants / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
active hostile-client/cross-tenant production testing
deploy / production mutation
Security Go
commercialization authorization
~~~

The proven M3-01 residuals are tracked as residual risks, not current task blockers.


## 0.1 HISTORICAL / SUPERSEDED — STS-M2-06 ACCEPTED / STS-M3 EXECUTION STILL BLOCKED — 2026-09-07

~~~text
STS-M2-06 = COMPLETE / ACCEPTED
DATABASE STRATEGY = V2_STRANGLER / SAME_DATABASE_FIRST
STS-M2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M3 = NEXT_ELIGIBLE / NOT_AUTHORIZED
Security Go = NOT_GRANTED
~~~

The architecture decision is no longer blocked or pending.

Still blocked unless separately authorized:

~~~text
V2 technical implementation
runtime/frontend mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grants / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
database cloning / second production database
data backfill
dual-write implementation
active hostile-client/cross-tenant production testing
STS-M3 execution
deploy / production mutation
Security Go
commercialization authorization
~~~

PR review/Draft/Ready/merge/base/head/check facts are lifecycle state and must be resolved live from GitHub; this material blocker view does not own or freeze them.

STS-M3-01 is structurally next eligible but has no execution authority. Any STS-M3-01 execution requires separate Product Authority authorization.


## 0.2 HISTORICAL / SUPERSEDED — STS-M2-06 READ_ONLY AUTHORIZED / CURRENT TASK BLOCKERS = 0 — 2026-09-07

Canonical typed issue view:

~~~text
docs/sfjm/CURRENT_ISSUES.md
~~~

Current task:

~~~text
STS-M2-06 =
AUTHORIZED_READ_ONLY / READY_TO_EXECUTE

CURRENT_TASK_BLOCKERS =
0
~~~

STS-M2-06 bounded READ_ONLY evidence/reasoning work is not blocked.

The following remain prohibited without separate authority, but are authorization boundaries rather than current blocker-count items:

~~~text
STS-M2-06 implementation
runtime/frontend mutation
Supabase/Auth/data mutation
SQL / DDL / DML mutation
migration execution
RLS / policy / grants / owner / search_path mutation
function / trigger / RPC / Edge Function mutation
active hostile-client/cross-tenant production testing
STS-M3 execution
deploy / production mutation
Security Go
commercialization authorization
~~~

Current non-blocking open facts are classified separately:

~~~text
RESIDUAL = 3
DEFERRED_EVIDENCE = 3
SECURITY_GATE = 3
FUTURE_GATE = 1
~~~

Do not count residuals, deferred evidence or future/security gates as current blockers unless their exact contract changes.

## 0.1 HISTORICAL / SUPERSEDED — STS-M2-05 accepted / M2-06 eligible but not authorized — 2026-09-07

~~~text
STS-M2-05 =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-CALLSITE-EVIDENCE-
RUNTIME-APPSEC RESIDUALS

M2-06 =
ELIGIBLE_NOT_AUTHORIZED

M2 =
ACTIVE

Security Go =
NOT_GRANTED
~~~

M2-05 execution itself is no longer a current blocker: the authorized READ_ONLY work is complete and Product Authority has accepted the result.

The M2-05 documentation publication is also no longer a current lifecycle blocker: PR #195 is merged and canonical on `d6953ea3071ada55fbcd97f21c848f5c6424ca3f`.

Blocked unless separately and explicitly authorized:

~~~text
implementation of M2-04/M2-05 target dispositions
implementation/lifecycle remediation
ALTER FUNCTION / SECURITY DEFINER-INVOKER change
owner/search_path mutation
GRANT / REVOKE / default privilege change
RLS/policy/direct-DML mutation
lifecycle retirement/deletion/replacement
hostile-client/cross-tenant runtime testing
exhaustive application callsite proof work if it requires scope beyond authorized READ_ONLY evidence
M2-06 execution
M3 execution
Ready / merge of the post-merge SFJM reconciliation publication
deploy / production mutation
Security Go
commercialization authorization
~~~

The next safe program gate is Product Authority authorization of bounded READ_ONLY STS-M2-06. Do not infer M2-06 execution authority from eligibility.


## 0.1 Historical / superseded STS-M2-04 closure boundary — 2026-09-07

~~~text
STS-M2-04 =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

M2-05 =
NEXT ELIGIBLE / EXECUTION NOT_AUTHORIZED
~~~

Blocked unless separately and explicitly authorized:

~~~text
implementation of any M2-04 target disposition
ALTER FUNCTION / SECURITY DEFINER-INVOKER change
owner/search_path mutation
GRANT / REVOKE / default privilege change
RLS/policy/direct-DML mutation
lifecycle retirement/deletion/replacement
hostile-client/cross-tenant runtime testing
M2-05 execution
M2-06 execution
Ready / merge of this documentation publication
deploy / production mutation
Security Go
~~~

M2-04 target-policy analysis must not be replayed without a material invalidator.

**Status:** HISTORICAL_STS_M2_04_ACCEPTED / HISTORICAL_M2_05_ELIGIBLE_NOT_AUTHORIZED / SUPERSEDED  
**Updated:** 2026-09-07  
**Repository:** wagnerjfjunior/fecha.ai

## 3. Historical / superseded B2-closure boundary — 2026-09-07

~~~text
B2 High-Risk Target-Contract Closure execution = COMPLETE READ_ONLY
Product Authority adjudication of result = ACCEPTED
STS-M2-04 final closure = NOT YET ADJUDICATED
~~~

Blocked unless separately and explicitly authorized:

~~~text
implementation of any B2 candidate disposition
ALTER FUNCTION / SECURITY DEFINER-INVOKER change
owner/search_path mutation
GRANT / REVOKE / default privilege change
RLS/policy/direct-DML mutation
retirement/deletion of redefinir_senha_corretor
retirement/replacement of registrar_audit_log
hostile-client/cross-tenant runtime testing
M2-05 execution
M2-06 execution
Ready / merge of the SFJM publication
deploy / production mutation
Security Go
~~~

A repeated B2 closure re-audit without a material invalidator is not the next safe action. The next safe action is final STS-M2-04 WBS closure adjudication.


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
004 implementation/security remediation
031 implementation/caller-ACL remediation
036 current-semantics retirement implementation
047 global-body/RLS remediation
119 current DEFINER -> target INVOKER implementation/runtime remediation
127 retirement/deprecation implementation
any next STS-M2-04 execution not separately selected/authorized
M2-04F execution
M2-05 execution
M2-06 execution
Supabase/Auth/business-data mutation
future Ready transitions not separately authorized
future merges not separately authorized
deploy
~~~

## 3. Closed architecture slices

~~~text
STS-M2-04C =
COMPLETE / ACCEPTED
historical projection = 68 DEFINER / 40 INVOKER / 5 NOT_DETERMINED / 113

STS-M2-04D =
COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT
8 DEFINER / 1 INVOKER / 0 NOT_DETERMINED
9 functions / 18 trigger instances

STS-M2-04E =
COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS
FIVE-RESIDUAL E AUTHORITY ADJUDICATION = COMPLETE
B3/C3 subset projection = 70 target DEFINER / 41 target INVOKER
B3/C3 semantic NOT_DETERMINED = 0
2 NON_MODE_LIFECYCLE / 113 B3/C3 routines
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED

B2 = separate accepted 15-routine slice with residuals
D = separate accepted 9-trigger-routine target classification
~~~

PR #189 lifecycle closure:

~~~text
PR #189 = MERGED / CLOSED
authorized head = b7baa29dbbfeeaee78e423f7950ba17390fac0e2
merge commit = 13eec5a6b720d67ed29a1837a01502123547ccb6
corrected E contract = VERSIONED + MERGED
~~~

The completed PR #189 merge is not a current blocker. It does not clear any implementation, lifecycle, runtime or Security Go residual listed below.

C/D/E analysis is not blocked and must not be replayed without material invalidation.

## 4. E residual implementation/lifecycle blocks

~~~text
004 aprovar_rejeitar_mesa
  target DEFINER resolved
  current implementation remediation remains blocked pending separate authority

031 gerenciar_lista
  target DEFINER resolved
  current implementation/caller-ACL remediation remains blocked pending separate authority

036 get_dashboard_master
  NON_MODE_LIFECYCLE
  RETIRE_CURRENT_SEMANTICS
  current-semantics retirement remains blocked pending separate authority
  possible future replacement is NOT DEFINED BY E and NOT AUTHORIZED by this PR

047 get_stats_horario
  target INVOKER / tenant-team scoped
  current global-body/RLS remediation remains blocked pending separate authority

127 solicitar_lote_forcado
  NON_MODE_LIFECYCLE
  RETIRE / DEPRECATE
  product lot request = SELF-ONLY
  implementation remains blocked pending separate authority
~~~

The five E rows above are no longer Product Authority semantic blockers.

Separate C3 implementation/runtime blocker retained:

~~~text
119 relatorio_fornecedor(uuid)
  target INVOKER = RESOLVED
  current implementation = postgres-owned SECURITY DEFINER
  implementation remediation = NOT_PERFORMED
  hostile/cross-tenant runtime assurance = NOT_PERFORMED
  blocker class = IMPLEMENTATION / RUNTIME RESIDUAL
  product semantic residual = NO
~~~


## 5. Historical / superseded M2-04 gate

~~~text
next bounded STS-M2-04 action = NOT_SELECTED
M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
Security Go = NOT_GRANTED
~~~

## 6. Evidence/lifecycle separation

~~~text
STATIC != LIVE != RUNTIME
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
TARGET CONTRACT RESOLVED != CURRENT IMPLEMENTATION COMPLIANT
RLS ENABLED != POLICY CORRECT
FORCE RLS != SECURITY DEFINER CONSTRAINED BY RLS
MERGEABLE != APPROVED
LIVE_DATABASE_VALIDATED != SECURITY_GO
~~~

## 7. Removal rule

Remove or narrow a blocker only when an exact Product Authority decision and sufficient material evidence change the current safe action.
