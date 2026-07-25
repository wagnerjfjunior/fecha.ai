# FECH.AI — F1-02 Live Supabase Read-Only Findings

**Status:** `LIVE_READ_ONLY_EVIDENCE / SECURITY_GO_DENIED / NO_MUTATION`  
**Observed on:** 2026-07-24  
**Repository commit used for source correlation:** `0555bad889c6ab85970ee242a0e35ac6873508e8`  
**Supabase project:** `Discador-MesaCliente`  
**Project ref:** `uobxxgzshrmbtjfdolxd`  
**Region:** `sa-east-1`  
**Project status:** `ACTIVE_HEALTHY`

## 1. Scope and method

The inspection was limited to read-only database metadata and definitions:

- project identity and status;
- table RLS/force-RLS state;
- table and column grants;
- RLS policy expressions;
- function signatures and definitions;
- function execution exposure;
- constraints and triggers;
- Supabase security advisors;
- current source call-site evidence already versioned in GitHub.

No lead/customer row, password, JWT, token, credential, real e-mail, phone number, name or raw production payload was read or stored. No `INSERT`, `UPDATE`, `DELETE`, DDL, migration, Auth change, test user creation or negative test was executed.

## 2. Verdict

```text
F1-02 READ-ONLY DISCOVERY: COMPLETED
SECURITY GO: DENIED
MUTATIONS: ZERO
NEGATIVE TESTS IN PRODUCTION: NOT EXECUTED
```

## 3. BLOCKING findings

### B1 — self privilege escalation through `public.corretores`

Observed controls:

- RLS enabled and forced;
- `authenticated` has table update ability;
- the self-row update policy allows the authenticated user's own broker row;
- column-level update exposure covers authority-bearing columns;
- `is_root()` recognizes an active `admin_global` broker row.

Authority-bearing fields exposed to direct update include:

```text
role
is_admin_local
is_gestor
empresa_id
time_id
user_id
ativo
apto_para_receber
must_change_password
```

The critical-update trigger records changes but its own definition states that it is initial monitoring without enforcement. Detection does not prevent escalation.

Potential chain:

```text
authenticated broker
→ direct self-row update
→ role = admin_global or equivalent authority-field change
→ is_root() may return true
→ global administrative authority
```

This finding alone prevents Security Go.

### B2 — excessive direct write surface on `public.leads` and `public.lotes`

`authenticated` retains direct CRM write capabilities while the reviewed application paths are primarily RPC-driven.

The current policies do not provide a complete column-level boundary for structural fields such as company, broker, list, lot, team, status and funnel references. Direct table writes can therefore attempt to bypass the server-side business and tenant checks implemented in RPCs.

No exploit attempt was executed in production. The finding is based on current grants, policy expressions, columns and function/source review.

### B3 — forgeable `funil_movimentacoes` history

`authenticated` can insert directly into `funil_movimentacoes`. The observed policy centers on the broker identity but does not independently prove that the lead, stage, company and movement correspond to one authorized state transition.

This can compromise CRM integrity, auditability and tenant boundaries.

### B4 — list ACL targets are not fully tenant-validated

`gerenciar_visibilidade_lista` validates target types but does not fully establish that every target broker, team or company belongs to the list's company before writing ACL entries.

`corretor_tem_acesso_lista` also requires hardening so that company consistency is derived and verified server-side rather than accepted through caller-supplied context.

A cross-company ACL target may therefore be recognized as authorized if its identifier is known.

## 4. REQUIRED findings

### R1 — `listar_funil_estagios` tenant visibility

The function returns funnel stages without explicit authentication and company filtering in its body. It must return only approved global stages and stages belonging to the authenticated user's company.

### R2 — import session deduplication lacks company scope

`importar_leads_batch` checks session duplication by session identifier but the observed duplicate-session lookup does not include the actor company. Equal session identifiers in two companies may interfere.

### R3 — feedback allowlist is not strictly enforced

The reviewed feedback path can preserve a textual feedback value even when the typed conversion is not valid. Unknown feedback values must be rejected before any write or derived status/funnel change.

### R4 — leaked-password protection disabled

The Supabase security advisor reported leaked-password protection disabled. This is not the primary database authorization blocker, but it requires an explicit operational decision before broader user exposure.

## 5. Controls with useful containment

The reviewed used-path RPCs commonly derive actor context through `auth.uid()` and validate company, broker, ownership, list, lot or stage relationships. Examples include:

```text
proximo_lead
registrar_feedback
atualizar_feedback
mover_funil
mover_funil_lote
registrar_mensagem
criar_lista
distribuir_lotes
get_dashboard_stats
minha_producao
```

Existing profile/team/status RPCs also provide a safer direction for broker changes:

```text
atualizar_perfil_corretor
atualizar_status_corretor
atualizar_time_corretor
```

These controls are not sufficient while direct table writes can alter authority or CRM structure outside the RPC boundary.

## 6. Source dependency confirmed

The current frontend contains one confirmed direct `corretores` mutation in the mandatory password-change completion flow. It updates `must_change_password` through the generic REST patch helper.

Therefore, direct update cannot be revoked safely until a narrow backend RPC replaces this flow.

## 7. Test status

Designed but not executed in production:

- no session;
- invalid or expired token;
- no profile and inactive profile;
- self role/admin/manager escalation;
- company/team/user-ID changes;
- forged broker/lead/list/lot/stage IDs;
- cross-company and mixed-tenant arrays;
- direct CRM/history writes;
- unauthorized ACL targets;
- invalid feedback/channel/sequence payloads;
- rollback and reapply.

The complete executable matrix belongs to the isolated security lab defined in `F1-02_REMEDIATION_MASTER_PLAN.md`.

## 8. Classification

### BLOCKING

- direct self-escalation through `corretores`;
- direct structural CRM write exposure;
- direct funnel-history insertion;
- incomplete tenant validation for list ACL targets.

### REQUIRED IN REMEDIATION PROGRAM

- narrow password-state RPC and frontend cutover;
- revoke direct broker authority updates;
- restrict CRM/history direct writes;
- harden ACL, funnel stages, import sessions and feedback;
- isolated negative tests;
- rollback evidence;
- final independent Security Go decision.

### ACCEPTABLE WITH RESIDUAL RISK

None for the current Security Go decision. The blockers are material.

### PLANNED FUTURE PR

- full triage of non-M1 `SECURITY DEFINER` functions;
- broader security coverage outside tested M1 paths;
- unrelated performance/index warnings.

### NOT RELEVANT TO THIS SCOPE

- MesaCliente runtime and financial engine;
- PME;
- ADS/CAPI/SEO;
- Make/n8n;
- unrelated integrations;
- broad product UX or architecture refactors.

## 9. Invalidating events

This evidence must be refreshed after any change to:

- the exact Supabase project/environment;
- relevant grants, RLS policies, functions, triggers or Auth configuration;
- used M1 source call sites;
- the canonical repository commit used for a gate decision;
- production deployment/configuration affecting the tested paths.

## 10. Next safe action

Audit and accept the versioned remediation program. Then create one isolated Supabase Branch after explicit cost confirmation. Do not execute security mutations or negative tests against production before the relevant technical PR, lab evidence and separate production authorization exist.
