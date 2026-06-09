# FECH.AI / Supabase - RPC Grants P1 Inventory

Date: 2026-06-09
Status: READ-ONLY INVENTORY / NO PRODUCTION CHANGE
Related checkpoints:
- PR #67 - authenticated write-surface P1 inventory
- PR #68 - frontend direct-DML P1 inventory
Current PR: PR #69 - RPC/grants P1 inventory
Recommended next phase: PR #70 - RPC/function body review for P1 write paths

---

## 1. Summary

This document maps RPC, Edge/API and server-side write paths identified after the frontend direct-DML inventory.

This is a read-only documentation artifact.

This PR does not change:

- database grants;
- RLS policies;
- FORCE RLS state;
- RPC/function definitions;
- migrations;
- frontend code;
- MesaCliente parser;
- MesaCliente financial engine;
- Worker;
- Make;
- n8n;
- Vercel;
- production infrastructure;
- business rules.

Primary finding:

- Most reviewed P1 frontend write flows are routed through RPCs or Edge/API functions.
- PR #68 found direct frontend DML against `public.corretores`; this revision records all currently identified `sb.patch("corretores", ...)` P1 paths, not only the mandatory password-change completion.
- Additional P1 RPCs around lists, visibility, import and lot/funnel movement must be included in PR #70.
- RPC grant status and function body safety must still be verified before any technical hardening.

Important limitation:

This document is based on repository evidence and source inspection. It does not query the live Supabase catalog. Any grant status not explicitly proven in repository evidence must be treated as `PENDING_SUPABASE_REAL_RECONCILIATION`.

Architectural authority rule:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists analysis, classification and productivity, but is not authority for tenant, permission, ownership, role, eligibility, distribution, billing or commercial state.
```

---

## 2. Scope

### 2.1 In scope

P1 write paths identified from PR #68, review feedback and adjacent server-side flows:

| Area | Path type | Objects |
|---|---|---|
| CRM / Discador | RPC | `proximo_lead`, `registrar_feedback`, `atualizar_feedback`, `mover_funil`, `mover_funil_lote`, `registrar_mensagem`, `solicitar_lote`, `avaliar_lista` |
| Lists / visibility / import | RPC | `criar_lista`, `gerenciar_lista`, `excluir_lista`, `gerenciar_visibilidade_lista`, `importar_leads_batch`, `distribuir_lotes` |
| Teams / brokers | RPC | `get_meus_times`, `get_corretores_time`, `atualizar_time_corretor`, `atualizar_status_corretor`, `criar_time`, `atualizar_perfil_corretor`, `alterar_role_corretor` |
| MesaCliente | RPC | `salvar_mesa_cliente_enriquecimento`, plus MesaCliente RPCs referenced by the API wrapper |
| Root / tenancy | RPC / API / Edge | `criar_empresa_root`, `alterar_plano_empresa_root`, `atualizar_status_empresa_root`, `simular_troca_plano_empresa_root`, `criar-usuario`, `reset_password` |
| Confirmed direct DML | REST wrapper | `src/App.jsx -> sb.patch("corretores", ...)` paths listed in section 9 |

### 2.2 Out of scope

This PR does not:

- revoke or grant EXECUTE;
- alter RPC bodies;
- alter RPC owners;
- alter SECURITY DEFINER / SECURITY INVOKER;
- alter search_path;
- alter RLS policies;
- alter tables;
- alter frontend calls;
- replace direct DML;
- run tests against Supabase;
- execute migrations;
- change production.

---

## 3. Evidence sources

Source files reviewed or referenced:

| File | Evidence relevance |
|---|---|
| `src/App.jsx` | custom REST/RPC wrapper, CRM/Discador RPC calls, list/import RPCs, direct `corretores` patches |
| `src/components/TimesTab.jsx` | team and broker operational RPCs, reset password Edge/API path |
| `src/components/CriarUsuario.jsx` | compatibility adapter and profile query |
| `src/components/CriarUsuarioForm.jsx` | user creation through Edge/API function |
| `src/components/RootPanel.jsx` | root control-plane RPCs |
| `src/components/TenantProvisioningRoot.jsx` | tenant provisioning RPC/API flow |
| `src/components/TenantProvisioningStandalone.jsx` | root validation and provisioning wrapper |
| `src/services/aceleracaoOperacionalService.js` | operational CRM/Discador RPC bridge |
| `src/features/mesaCliente/api/mesaClienteApi.js` | MesaCliente RPC wrapper |

---

## 4. Inventory matrix

All live grant values in this table remain `PENDING_SUPABASE_REAL_RECONCILIATION` unless later reconciled with the Supabase real catalog.

| Object | Type | Caller observed | Business area | Risk | Grant status in this PR | Body review status |
|---|---|---:|---|---:|---|---|
| `proximo_lead` | RPC | yes | CRM / Discador / lot progression | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `registrar_feedback` | RPC | yes | CRM / Discador | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `atualizar_feedback` | RPC | candidate | CRM | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `mover_funil` | RPC | yes | CRM funnel | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `mover_funil_lote` | RPC | yes | CRM funnel batch movement | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `registrar_mensagem` | RPC | yes | CRM messaging sequence | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `solicitar_lote` | RPC | yes | lot assignment | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `avaliar_lista` | RPC | yes | list/lot rating | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `criar_lista` | RPC | yes | list creation/import staging | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `gerenciar_lista` | RPC | yes | list metadata/governance | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `excluir_lista` | RPC | yes | list deletion/deactivation | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `gerenciar_visibilidade_lista` | RPC | yes | ACL-like list visibility | P1 high | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `importar_leads_batch` | RPC | yes | lead import / batch creation | P1 high | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `distribuir_lotes` | RPC | yes | lot distribution | P1 high | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `get_meus_times` | RPC | yes | team read/supporting flow | P1 support | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 if mutating dependencies exist |
| `get_corretores_time` | RPC | yes | team read/supporting flow | P1 support | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 if sensitive read scope exists |
| `atualizar_time_corretor` | RPC | yes | broker/team assignment | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `atualizar_status_corretor` | RPC | yes | broker operational eligibility | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `atualizar_perfil_corretor` | RPC | yes | broker profile update | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `alterar_role_corretor` | RPC | yes | broker role authority | P1 high | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `criar_time` | RPC | yes | team governance | P1 | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `salvar_mesa_cliente_enriquecimento` | RPC | yes | MesaCliente unit enrichment | P1 / MesaCliente-sensitive | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 |
| `criar_empresa_root` | RPC | yes | root tenancy provisioning | P1 / root-only | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 or root-control review |
| `atualizar_status_empresa_root` | RPC | yes | root tenant suspension/reactivation | P1 / root-only | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 or root-control review |
| `simular_troca_plano_empresa_root` | RPC | yes | billing/root simulation | P1 / root-only | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 or root-control review |
| `alterar_plano_empresa_root` | RPC | yes | billing/root plan mutation | P1 / root-only | `PENDING_SUPABASE_REAL_RECONCILIATION` | pending PR #70 or root-control review |
| `criar-usuario` | Edge/API function | yes | user creation / reset | P1 / identity authority | pending function review | pending server-side review |
| `reset_password` action | Edge/API function action | yes | identity authority | P1 / identity authority | pending function review | pending server-side review |
| `sb.patch("corretores", ...)` | direct REST table DML | yes | broker identity/status/onboarding flags | P1 / direct DML | table grant known from PR #67 surface; RLS behavior pending | future technical fix candidate |

---

## 5. CRM / Discador write paths

### 5.1 `proximo_lead`

Observed caller:

- `src/App.jsx` in Discador flow;
- `src/services/aceleracaoOperacionalService.js` in operational service bridge.

Expected authority:

- assign or return next lead;
- enforce broker/company scope;
- enforce lot/list lifecycle;
- avoid cross-company exposure;
- avoid trusting frontend-provided tenant/company values.

Review required:

- EXECUTE grants to `anon`, `authenticated`, pseudo-role `PUBLIC`;
- SECURITY DEFINER/INVOKER;
- owner;
- search_path;
- body validation of `auth.uid()`;
- company/team/ownership rules;
- mutation side effects on `leads` and `lotes`.

### 5.2 `registrar_feedback` / `atualizar_feedback`

Observed caller:

- `src/App.jsx` feedback submission;
- `src/services/aceleracaoOperacionalService.js` feedback bridge.

Risk:

Feedback changes lead lifecycle, reporting, funnel status and possibly lot completion.

Review required:

- ensure actor owns or is allowed to update the lead;
- ensure cross-company updates fail;
- validate allowed feedback values;
- validate observation payload size/content;
- ensure lead status cannot be arbitrarily escalated.

### 5.3 `mover_funil` / `mover_funil_lote`

Observed caller:

- `src/App.jsx` LeadModal funnel movement;
- `src/App.jsx` batch funnel movement.

Risk:

Funnel movement affects commercial state, history and reporting. Batch movement increases blast radius.

Review required:

- validate lead access for every lead;
- validate stage belongs to same company/funnel;
- validate allowed transitions where applicable;
- prevent mixed-company lead arrays;
- log transition history.

### 5.4 `registrar_mensagem`

Observed caller:

- `src/App.jsx` Central de Mensagens;
- Power WhatsApp/E-mail flows.

Risk:

Updates sequence counters and communication history. Lower than lead ownership mutation, but still P1 because it affects CRM trail.

Review required:

- validate lead access;
- validate channel allowlist;
- validate sequence bounds;
- avoid cross-company sequence updates.

### 5.5 `solicitar_lote` / `avaliar_lista`

Observed caller:

- `src/App.jsx` lot request and rating flows.

Risk:

Controls lot assignment, productivity and list quality feedback.

Review required:

- broker eligibility;
- active user status;
- company/team list visibility;
- lot capacity and current open lot checks;
- rating only for lists/lots the actor touched.

---

## 6. Lists / visibility / import write paths

### 6.1 `criar_lista`

Observed caller:

- `src/App.jsx` list creation/import flow.

Risk:

Creates list/import container and may bind provider/source/company metadata.

Review required:

- actor permission;
- company binding derived server-side;
- allowed source/provider fields;
- no frontend authority over tenant/company;
- audit event for import/list creation.

### 6.2 `gerenciar_lista` / `excluir_lista`

Observed caller:

- `src/App.jsx` list management flow.

Risk:

Controls list metadata, visibility and lifecycle. Deletion/deactivation may affect active CRM/Discador flows.

Review required:

- actor role/profile;
- company/list ownership;
- active lot dependencies;
- soft-delete vs hard-delete behavior;
- audit trail.

### 6.3 `gerenciar_visibilidade_lista`

Observed caller:

- `src/App.jsx` list visibility selection flow.

Risk:

ACL-like table/function path. This is high priority because list visibility controls who can see or operate leads.

Review required:

- actor role/profile;
- target list company;
- target user/team company;
- allowed target types;
- no ability to grant cross-company visibility;
- audit trail;
- negative tests for unauthorized visibility expansion.

### 6.4 `importar_leads_batch`

Observed caller:

- `src/App.jsx` import flow.

Risk:

Batch import creates or updates many lead records and may bind them to list/company/source metadata.

Review required:

- actor permission;
- list/company binding;
- payload size and field allowlist;
- phone/email normalization boundaries;
- duplicate handling;
- no cross-company insert;
- audit/import result accounting.

### 6.5 `distribuir_lotes`

Observed caller:

- `src/App.jsx` list/lot distribution flow.

Risk:

Controls lead distribution and broker workload. High operational impact.

Review required:

- manager/admin permission;
- list company;
- eligible brokers only;
- lot size limits;
- no distribution to broker outside company/team scope;
- rollback or compensating action for partial distribution.

---

## 7. Teams / broker write paths

### 7.1 `atualizar_time_corretor`

Observed caller:

- `src/components/TimesTab.jsx` broker movement between teams.

Risk:

Changes team assignment and can affect visibility, distribution and managerial scope.

Review required:

- actor must be admin/manager with scope;
- target broker must belong to same company;
- target team must belong to same company;
- root/admin exceptions must be explicit;
- audit trail recommended.

### 7.2 `atualizar_status_corretor`

Observed caller:

- `src/components/TimesTab.jsx` pause/reactivate lead receiving eligibility.

Risk:

Changes operational eligibility to receive leads.

Review required:

- actor permission;
- target broker company;
- field allowlist;
- no ability to mutate privileged fields.

### 7.3 `atualizar_perfil_corretor` / `alterar_role_corretor`

Observed caller:

- `src/App.jsx` EditarCorretorModal profile and role sections.

Risk:

Profile updates are moderate risk, but role changes are high risk because they affect authority and visibility.

Review required:

- role change only by authorized actor;
- actor and target must be in allowed scope;
- no privilege escalation;
- no role/profile derived solely from frontend;
- audit trail.

### 7.4 `criar_time`

Observed caller:

- `src/components/TimesTab.jsx` create team modal.

Risk:

Creates operational segmentation object.

Review required:

- admin/manager scope;
- company binding derived server-side;
- gestor target validation;
- duplicate/name rules if applicable.

---

## 8. MesaCliente write paths

### 8.1 `salvar_mesa_cliente_enriquecimento`

Observed caller:

- `src/features/mesaCliente/api/mesaClienteApi.js`.

Risk:

MesaCliente-sensitive. May affect unit enrichment and potentially client-facing commercial presentation.

Review required:

- actor authentication;
- company/tenant/project binding;
- empreendimento/unit/final scope;
- field allowlist;
- client-safe boundaries;
- no impact to parser or financial engine in this PR;
- audit and regression requirements before any hardening.

Related MesaCliente RPCs observed in API wrapper and to remain outside direct change in this PR:

- `get_empreendimentos_mesa`;
- `get_empresa_mesa_config`;
- `get_historico_mesas`;
- `get_unidades_mesa`;
- `registrar_upload_arquivo_mesa`;
- `criar_mesa_simulacao`;
- `aprovar_rejeitar_mesa`;
- `importar_mesa_cliente_parser_resultado`;
- `importar_mesa_cliente_json_admin`;
- `importar_mesa_cliente_disponibilidade_oficial`;
- `mesa_cliente_obter_simulacao_fluxo_historico`.

These should not be altered in PR #69.

---

## 9. Root / tenancy / billing paths

Observed root-control paths:

- `criar_empresa_root`;
- `atualizar_status_empresa_root`;
- `simular_troca_plano_empresa_root`;
- `alterar_plano_empresa_root`;
- `/api/criar-usuario` / Edge Function user creation.

Risk:

Root and tenancy functions affect company provisioning, status, billing plan, admin creation and operational enablement.

Review required:

- strict root validation;
- no reliance on frontend-provided root claim;
- explicit company/tenant target validation;
- audit trail;
- safe failure behavior;
- no client-side service-role exposure.

---

## 10. Confirmed direct DML carried forward from PR #68

The direct table DML class is:

```text
src/App.jsx
sb.patch("corretores", ...)
```

Currently identified P1 direct write paths:

| Flow | Operation | Fields | Risk |
|---|---|---|---|
| Mandatory password-change completion | `sb.patch("corretores", "id=eq." + corretorId, ...)` | `must_change_password: false` | P1 onboarding/identity state |
| Edit broker modal save | `sb.patch("corretores", "id=eq." + corretor.id, ...)` | `ativo`, `apto_para_receber` | P1 operational authority / lead eligibility |
| Admin password reset completion | `sb.patch("corretores", "id=eq." + corretor.id, ...)` | `must_change_password: false` | P1 identity/onboarding state |

These paths should not be fixed in PR #69.

Future fix candidate:

- add narrow RPCs for onboarding/status changes;
- derive actor from `auth.uid()`;
- avoid arbitrary `corretorId` from frontend;
- update only allowlisted fields;
- add negative tests;
- only then consider reducing direct `authenticated UPDATE` on `public.corretores`.

---

## 11. Required Supabase real reconciliation query

Before PR #70 or any hardening, run a read-only Supabase catalog query to reconcile grants and function metadata.

Important note about `PUBLIC`:

`PUBLIC` is a PostgreSQL pseudo-role. Boolean privilege checks may be useful, but PR #70 should also inspect expanded ACL/default ACL entries to distinguish direct/default grants from effective privilege inheritance.

Template:

```sql
with target_functions as (
  select unnest(array[
    'proximo_lead',
    'registrar_feedback',
    'atualizar_feedback',
    'mover_funil',
    'mover_funil_lote',
    'registrar_mensagem',
    'solicitar_lote',
    'avaliar_lista',
    'criar_lista',
    'gerenciar_lista',
    'excluir_lista',
    'gerenciar_visibilidade_lista',
    'importar_leads_batch',
    'distribuir_lotes',
    'get_meus_times',
    'get_corretores_time',
    'atualizar_time_corretor',
    'atualizar_status_corretor',
    'atualizar_perfil_corretor',
    'alterar_role_corretor',
    'criar_time',
    'salvar_mesa_cliente_enriquecimento',
    'criar_empresa_root',
    'atualizar_status_empresa_root',
    'simular_troca_plano_empresa_root',
    'alterar_plano_empresa_root'
  ]) as proname
), function_base as (
  select
    n.nspname as schema_name,
    p.oid,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as identity_args,
    pg_get_userbyid(p.proowner) as owner_name,
    case p.prosecdef when true then 'SECURITY DEFINER' else 'SECURITY INVOKER' end as security_mode,
    p.proconfig as function_config,
    p.proowner,
    coalesce(p.proacl, acldefault('f', p.proowner)) as effective_acl
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join target_functions tf on tf.proname = p.proname
  where n.nspname = 'public'
), acl_expanded as (
  select
    fb.oid,
    array_agg(distinct coalesce(nullif(a.grantee::regrole::text, '-'), 'PUBLIC')) filter (where a.privilege_type = 'EXECUTE') as execute_grantees
  from function_base fb
  left join lateral aclexplode(fb.effective_acl) a on true
  group by fb.oid
)
select
  fb.schema_name,
  fb.function_name,
  fb.identity_args,
  fb.owner_name,
  fb.security_mode,
  fb.function_config,
  has_function_privilege('anon', fb.oid, 'EXECUTE') as anon_execute,
  has_function_privilege('authenticated', fb.oid, 'EXECUTE') as authenticated_execute,
  has_function_privilege('public', fb.oid, 'EXECUTE') as public_effective_execute,
  ae.execute_grantees
from function_base fb
left join acl_expanded ae on ae.oid = fb.oid
order by fb.function_name, fb.identity_args;
```

The output must be sanitized before committing. Do not commit raw production identifiers or secrets.

---

## 12. Required PR #70 body-review questions

For each P1 RPC/function, answer:

1. Does it validate `auth.uid()`?
2. Does it validate active user status?
3. Does it derive company/tenant from trusted backend state?
4. Does it avoid trusting frontend-provided `empresa_id`, `tenant_id`, `corretor_id`, `time_id`, role/profile or ownership?
5. Does it validate actor role/profile?
6. Does it validate target object belongs to the same company/tenant?
7. Does it use a safe `search_path`?
8. Does it use dynamic SQL? If yes, is it safe?
9. What tables can it write?
10. What fields can it modify?
11. Are payload fields allowlisted?
12. Is audit logging present or required?
13. What are the positive and negative tests?
14. What is the rollback plan if grants are changed later?

---

## 13. Risk ranking

| Rank | Path | Reason |
|---:|---|---|
| 1 | `src/App.jsx -> sb.patch("corretores", ...)` paths | confirmed direct P1 table DML against identity/status/onboarding fields |
| 2 | `gerenciar_visibilidade_lista` | ACL-like visibility authority |
| 3 | `importar_leads_batch` / `distribuir_lotes` | bulk lead/list/lot mutation blast radius |
| 4 | `atualizar_time_corretor` / `atualizar_status_corretor` | broker/team/lead eligibility authority |
| 5 | `alterar_role_corretor` | role/authority mutation |
| 6 | `criar_lista` / `gerenciar_lista` / `excluir_lista` | list lifecycle and CRM/Discador availability |
| 7 | `proximo_lead` / `solicitar_lote` | lead distribution and lot lifecycle |
| 8 | `registrar_feedback` / `mover_funil` / `mover_funil_lote` | CRM state and funnel mutation |
| 9 | `salvar_mesa_cliente_enriquecimento` | MesaCliente-sensitive data path |
| 10 | root/tenant/billing RPCs | high power but expected to be root-restricted; must still be reviewed |
| 11 | `registrar_mensagem` / `avaliar_lista` | operational trail/rating, lower but still P1 |

---

## 14. Explicit non-claims

This document does not claim the platform is production-secure.

This document does not prove that all RPC grants are safe.

This document does not prove that all RPC bodies are safe.

This document does not prove that live Supabase matches repository evidence.

This document does not authorize revoking or granting EXECUTE.

This document does not authorize migration execution.

This document does not authorize frontend or MesaCliente changes.

This document is an inventory/planning checkpoint only.

---

## 15. Acceptance criteria for PR #69

This PR is acceptable only if:

- it is documentation-only;
- it changes only Markdown evidence under `docs/security/evidence/`;
- it does not change application code;
- it does not change migrations;
- it does not change Supabase objects;
- it does not change RLS, grants, policies or RPC bodies;
- it does not change frontend behavior;
- it does not change MesaCliente parser or financial engine;
- it does not contain raw production data;
- it does not contain secrets or credentials;
- it marks live grant status as `PENDING_SUPABASE_REAL_RECONCILIATION` where not proven;
- it clearly defines PR #70 as body review.

---

## 16. Final conclusion

PR #69 records the RPC/server-side write paths that must be reviewed before any technical hardening.

The main sequence remains:

```text
#69 - RPC/grants inventory
#70 - RPC/function body review
#71 - technical hardening candidate, likely replacing direct corretores patches first
```

No technical change should be merged before PR #70 answers the body-review questions for the relevant P1 write paths.
