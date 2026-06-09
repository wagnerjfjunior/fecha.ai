# FECH.AI / Supabase - RPC Grants P1 Inventory

Date: 2026-06-09
Status: READ-ONLY INVENTORY / NO PRODUCTION CHANGE
Related checkpoints:
- PR #67 - authenticated write-surface P1 inventory
- PR #68 - frontend direct-DML P1 inventory
Current PR: PR #69 - RPC/grants P1 inventory
Recommended next phase: RPC/function body review for P1 write paths

---

## 1. Summary

This document maps RPC and server-side write paths identified after the frontend direct-DML inventory.

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

- Most reviewed P1 frontend write flows are routed through RPCs or Edge/API functions, not direct table DML.
- The confirmed direct frontend table write from PR #68 remains `src/App.jsx -> sb.patch("corretores", ...)` during mandatory password-change completion.
- RPC grant status and function body safety must still be verified before any technical hardening.

Important limitation:

This document is based on repository evidence and source inspection. It does not query the live Supabase catalog. Any grant status not explicitly proven in repository evidence must be treated as `PENDING_SUPABASE_REAL_RECONCILIATION`.

---

## 2. Scope

### 2.1 In scope

P1 write paths identified from PR #68 and adjacent server-side flows:

| Area | Path type | Objects |
|---|---|---|
| CRM / Discador | RPC | `proximo_lead`, `registrar_feedback`, `atualizar_feedback`, `mover_funil`, `registrar_mensagem`, `solicitar_lote`, `avaliar_lista` |
| Teams / brokers | RPC | `get_meus_times`, `get_corretores_time`, `atualizar_time_corretor`, `atualizar_status_corretor`, `criar_time` |
| MesaCliente | RPC | `salvar_mesa_cliente_enriquecimento`, plus MesaCliente RPCs referenced by the API wrapper |
| Root / tenancy | RPC / API / Edge | `criar_empresa_root`, `alterar_plano_empresa_root`, `atualizar_status_empresa_root`, `simular_troca_plano_empresa_root`, `criar-usuario`, `reset_password` |
| Confirmed direct DML | REST wrapper | `src/App.jsx -> sb.patch("corretores", ...)` |

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

Source files reviewed or referenced from PR #68:

| File | Evidence relevance |
|---|---|
| `src/App.jsx` | custom REST/RPC wrapper, CRM/Discador RPC calls, direct `corretores` patch |
| `src/components/TimesTab.jsx` | team and broker operational RPCs, reset password Edge Function call |
| `src/components/CriarUsuario.jsx` | compatibility adapter and profile query |
| `src/components/CriarUsuarioForm.jsx` | user creation through Edge Function |
| `src/components/RootPanel.jsx` | root control-plane RPCs |
| `src/components/TenantProvisioningRoot.jsx` | tenant provisioning RPC/API flow |
| `src/components/TenantProvisioningStandalone.jsx` | root validation and provisioning wrapper |
| `src/services/aceleracaoOperacionalService.js` | operational CRM/Discador RPC bridge |
| `src/features/mesaCliente/api/mesaClienteApi.js` | MesaCliente RPC wrapper |

---

## 4. Inventory matrix

| Object | Type | Frontend/server caller observed | Business area | Risk | Grant status in this PR | Body review status |
|---|---|---:|---|---:|---|---|
| `proximo_lead` | RPC | yes | CRM / Discador / lot progression | P1 | pending real Supabase verification | pending PR #70 |
| `registrar_feedback` | RPC | yes | CRM / Discador | P1 | pending real Supabase verification | pending PR #70 |
| `atualizar_feedback` | RPC | referenced as P1 candidate | CRM | P1 | pending real Supabase verification | pending PR #70 |
| `mover_funil` | RPC | yes | CRM funnel | P1 | pending real Supabase verification | pending PR #70 |
| `registrar_mensagem` | RPC | yes | CRM messaging sequence | P1 | pending real Supabase verification | pending PR #70 |
| `solicitar_lote` | RPC | yes | lot assignment | P1 | pending real Supabase verification | pending PR #70 |
| `avaliar_lista` | RPC | yes | list/lot rating | P1 | pending real Supabase verification | pending PR #70 |
| `get_meus_times` | RPC | yes | team read/supporting flow | P1 support | pending real Supabase verification | pending PR #70 if mutating dependencies exist |
| `get_corretores_time` | RPC | yes | team read/supporting flow | P1 support | pending real Supabase verification | pending PR #70 if sensitive read scope exists |
| `atualizar_time_corretor` | RPC | yes | broker/team assignment | P1 | pending real Supabase verification | pending PR #70 |
| `atualizar_status_corretor` | RPC | yes | broker operational eligibility | P1 | pending real Supabase verification | pending PR #70 |
| `criar_time` | RPC | yes | team governance | P1 | pending real Supabase verification | pending PR #70 |
| `salvar_mesa_cliente_enriquecimento` | RPC | yes | MesaCliente unit enrichment | P1 / MesaCliente-sensitive | pending real Supabase verification | pending PR #70 |
| `criar_empresa_root` | RPC | yes | root tenancy provisioning | P1 / root-only | pending real Supabase verification | pending PR #70 or root-control review |
| `atualizar_status_empresa_root` | RPC | yes | root tenant suspension/reactivation | P1 / root-only | pending real Supabase verification | pending PR #70 or root-control review |
| `simular_troca_plano_empresa_root` | RPC | yes | billing/root simulation | P1 / root-only | pending real Supabase verification | pending PR #70 or root-control review |
| `alterar_plano_empresa_root` | RPC | yes | billing/root plan mutation | P1 / root-only | pending real Supabase verification | pending PR #70 or root-control review |
| `criar-usuario` | Edge/API function | yes | user creation / reset | P1 / identity authority | pending function review | pending server-side review |
| `reset_password` action | Edge/API function action | yes | identity authority | P1 / identity authority | pending function review | pending server-side review |
| `sb.patch("corretores", ...)` | direct REST table DML | yes | password onboarding flag | P1 / direct DML | table grant known from PR #67 surface; actual RLS behavior pending | future technical fix candidate |

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

- EXECUTE grants to `anon`, `authenticated`, `public`;
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

### 5.3 `mover_funil`

Observed caller:

- `src/App.jsx` LeadModal funnel movement.

Risk:

Funnel movement affects commercial state, history and reporting.

Review required:

- validate lead access;
- validate stage belongs to same company/funnel;
- validate allowed transitions where applicable;
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

## 6. Teams / broker write paths

### 6.1 `atualizar_time_corretor`

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

### 6.2 `atualizar_status_corretor`

Observed caller:

- `src/components/TimesTab.jsx` pause/reactivate lead receiving eligibility.

Risk:

Changes operational eligibility to receive leads.

Review required:

- actor permission;
- target broker company;
- field allowlist;
- no ability to mutate privileged fields.

### 6.3 `criar_time`

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

## 7. MesaCliente write paths

### 7.1 `salvar_mesa_cliente_enriquecimento`

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

## 8. Root / tenancy / billing paths

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

## 9. Confirmed direct DML carried forward

From PR #68, the confirmed direct table DML is:

```text
src/App.jsx
sb.patch("corretores", "id=eq." + corretorId, { must_change_password: false }, token)
```

This path should not be fixed in PR #69.

Future fix candidate:

- add a narrow RPC for mandatory-password completion;
- derive actor from `auth.uid()`;
- avoid arbitrary `corretorId` from frontend;
- update only the allowed onboarding flag;
- add negative tests;
- only then consider reducing direct `authenticated UPDATE` on `public.corretores`.

---

## 10. Required Supabase real reconciliation query

Before PR #70 or any hardening, run a read-only Supabase catalog query to reconcile grants and function metadata.

Template:

```sql
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_args,
  pg_get_userbyid(p.proowner) as owner_name,
  case p.prosecdef when true then 'SECURITY DEFINER' else 'SECURITY INVOKER' end as security_mode,
  p.proconfig as function_config,
  has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
  has_function_privilege('public', p.oid, 'EXECUTE') as public_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'proximo_lead',
    'registrar_feedback',
    'atualizar_feedback',
    'mover_funil',
    'registrar_mensagem',
    'solicitar_lote',
    'avaliar_lista',
    'get_meus_times',
    'get_corretores_time',
    'atualizar_time_corretor',
    'atualizar_status_corretor',
    'criar_time',
    'salvar_mesa_cliente_enriquecimento',
    'criar_empresa_root',
    'atualizar_status_empresa_root',
    'simular_troca_plano_empresa_root',
    'alterar_plano_empresa_root'
  )
order by p.proname, identity_args;
```

The output must be sanitized before committing. Do not commit raw production identifiers or secrets.

---

## 11. Required PR #70 body-review questions

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

## 12. Risk ranking

| Rank | Path | Reason |
|---:|---|---|
| 1 | `src/App.jsx -> sb.patch("corretores", ...)` | confirmed direct P1 table DML |
| 2 | `atualizar_time_corretor` / `atualizar_status_corretor` | broker/team/lead eligibility authority |
| 3 | `criar_time` | team governance surface |
| 4 | `proximo_lead` / `solicitar_lote` | lead distribution and lot lifecycle |
| 5 | `registrar_feedback` / `mover_funil` | CRM state and funnel mutation |
| 6 | `salvar_mesa_cliente_enriquecimento` | MesaCliente-sensitive data path |
| 7 | root/tenant/billing RPCs | high power but expected to be root-restricted; must still be reviewed |
| 8 | `registrar_mensagem` / `avaliar_lista` | operational trail/rating, lower but still P1 |

---

## 13. Explicit non-claims

This document does not claim the platform is production-secure.

This document does not prove that all RPC grants are safe.

This document does not prove that all RPC bodies are safe.

This document does not prove that live Supabase matches repository evidence.

This document does not authorize revoking or granting EXECUTE.

This document does not authorize migration execution.

This document does not authorize frontend or MesaCliente changes.

This document is an inventory/planning checkpoint only.

---

## 14. Acceptance criteria for PR #69

This PR is acceptable only if:

- it is documentation-only;
- it creates one Markdown evidence file under `docs/security/evidence/`;
- it does not change application code;
- it does not change migrations;
- it does not change Supabase objects;
- it does not change RLS, grants, policies or RPC bodies;
- it does not change frontend behavior;
- it does not change MesaCliente parser or financial engine;
- it does not contain raw production data;
- it does not contain secrets or credentials;
- it marks live grant status as pending where not proven;
- it clearly defines PR #70 as body review.

---

## 15. Final conclusion

PR #69 records the RPC/server-side write paths that must be reviewed before any technical hardening.

The main sequence remains:

```text
#69 - RPC/grants inventory
#70 - RPC/function body review
#71 - technical hardening candidate, likely replacing the direct corretores patch first
```

No technical change should be merged before PR #70 answers the body-review questions for the relevant P1 write paths.
