# FECH.AI - M1 LeadOps / CRM / Discador Existing Evidence Map

Date: 2026-06-10
Status: EXISTING_EVIDENCE_CONSOLIDATION / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE
Front: M1 - LeadOps / CRM / Discador
Risk: R3/R4 - personal data, leads, broker operations, Supabase RPCs, RLS and tenant/company isolation.
Base branch observed: main
Base commit observed: 0a5d5c70b9a7d6d50eeda8a8f6b81a1ba87e32a0

---

## 1. Objective

Consolidate existing documentation and evidence for M1 LeadOps / CRM / Discador before producing any new technical implementation.

This document exists because the project already has several relevant documents. The goal is not to redo the analysis from zero.

This PR consolidates what is already documented, identifies real gaps, and prepares the next safe step toward the first technical PR.

This document does not authorize code, SQL, migration, RPC, RLS, grant, Vercel, MesaCliente or production changes.

---

## 2. Protocol

This consolidation follows:

```text
docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md
docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md
docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-reconciliation-pass-1.md
docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-reconciliation-pass-2-ui-rpc-map.md
```

Operating rule:

```text
Reuse existing evidence first.
Only create new analysis where the existing documentation does not already answer the question.
```

---

## 3. Existing evidence sources

| Source | Existing value for M1 |
|---|---|
| `docs/product/fechai-mvp-scope-v1.md` | Defines MVP objective, import, CRM/funnel, discador, Power Mode, dashboard, tracking, non-functional requirements and acceptance criteria. |
| `docs/product/fechai-modules-map-v1.md` | Defines M1 as LeadOps, Lists, CRM and Dialer. |
| `docs/roadmap/fechai-roadmap-master-v1.md` | Defines Phase 1 as Operational MVP / LeadOps CRM Dialer and success criteria. |
| `docs/security/evidence/2026-06-09_frontend_direct_dml_p1_inventory.md` | Maps frontend direct DML and observed RPC-driven flows. |
| `docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md` | Maps P1 RPC/server-side paths, caller observations, business area and grant/body review status. |
| `docs/security/evidence/2026-06-09_rpc_body_review_p1.md` | Defines body-review checklist and body-review status matrix. |
| `docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md` | Provides sanitized live Supabase metadata, EXECUTE matrix and body indicators. |
| `docs/skills/fechai-gpt7-leadops-crm-discador.md` | Defines LeadOps/CRM/Discador specialist responsibilities. |

---

## 4. Reused M1 product scope

Already documented in `docs/product/fechai-mvp-scope-v1.md`:

```text
lead/list import via CSV, XLSX, pasted text and manual input
basic deduplication
phone validation
origin/list/responsible broker/tenant-company fields
minimum CRM/funnel
next action
quick call / WhatsApp / phone copy
quick status
quick note
return/scheduling
Power Mode
weekend dashboard
basic tracking origin fields
multi-tenant and RLS requirements
no trust in frontend tenant_id/empresa_id
rollback and preview requirements
LGPD/opt-out where applicable
```

Important note:

```text
The MVP scope already includes next action / follow-up as a product requirement.
What is not yet consolidated is the exact UI/service/RPC/table path that persists and validates this field.
```

---

## 5. Reused M1 RPC and direct DML evidence

The existing security inventory already identifies these M1 paths:

| Area | Existing evidence |
|---|---|
| CRM / Dialer | `proximo_lead`, `registrar_feedback`, `atualizar_feedback`, `mover_funil`, `mover_funil_lote`, `registrar_mensagem`, `solicitar_lote`, `avaliar_lista` |
| Lists / import / visibility | `criar_lista`, `gerenciar_lista`, `excluir_lista`, `gerenciar_visibilidade_lista`, `importar_leads_batch`, `distribuir_lotes` |
| Teams / brokers | `get_meus_times`, `get_corretores_time`, `atualizar_time_corretor`, `atualizar_status_corretor`, `criar_time`, `atualizar_perfil_corretor`, `alterar_role_corretor` |
| Identity/root support | `criar-usuario`, `reset_password`, root tenant functions when touched outside M1 |
| Direct DML | `src/App.jsx -> sb.patch("corretores", ...)` |

Reused conclusion:

```text
Most reviewed M1 lead/list/team mutations appear RPC-driven.
A known direct DML class remains in src/App.jsx for corretores.
RPC grant/body safety is not proven solely by being routed through RPC.
```

---

## 6. Consolidated UI/service/RPC evidence map

This matrix consolidates what is already documented. Fields marked NOT_CONFIRMED require source inspection or live/runtime validation before a technical PR.

| UI / component | User action | Service/wrapper | RPC/direct path | Expected table impact | Auth source | Tenant/company source | Risk | Test requirement | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| `src/components/AceleracaoOperacional.jsx` | Load next operational lead | `src/services/aceleracaoOperacionalService.js` / `buscarProximoLeadOperacional` | RPC `proximo_lead` | `leads`, `lotes` side effects possible | Session token, but bridge fallback risk exists | Must be derived server-side by RPC | P1 | anon/no-session, cross-tenant, unauthorized broker, no eligible lot | PARTIALLY_DOCUMENTED |
| `src/components/AceleracaoOperacional.jsx` | Register quick feedback | `src/services/aceleracaoOperacionalService.js` / `registrarFeedbackOperacional` | RPC `registrar_feedback` | `leads`, CRM lifecycle/history | Session token, but bridge fallback risk exists | Must be derived server-side by RPC | P1 | invalid feedback, forged lead id, cross-tenant, no ownership | PARTIALLY_DOCUMENTED |
| `src/App.jsx` | Next lead / dialer flow | custom `createSB.rpc` | RPC `proximo_lead` | `leads`, `lotes` side effects possible | Frontend token passed to RPC wrapper | Must be validated in RPC body | P1 | anon/no-session, cross-tenant, ineligible broker/list | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Feedback submission | custom `createSB.rpc` | RPC `registrar_feedback` / `atualizar_feedback` | `leads`, feedback/status/history | Frontend token passed to RPC wrapper | Must be validated in RPC body | P1 | forged lead id, invalid feedback, cross-tenant | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Funnel movement | custom `createSB.rpc` | RPC `mover_funil` | `leads`, funnel/stage/history | Frontend token passed to RPC wrapper | Must be validated in RPC body | P1 | invalid transition, forged lead id, cross-tenant | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Batch funnel movement | custom `createSB.rpc` | RPC `mover_funil_lote` | multiple `leads`, funnel/stage/history | Frontend token passed to RPC wrapper | Must validate every lead server-side | P1 high | mixed-company array, invalid stage, unauthorized broker | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Message/sequence registration | custom `createSB.rpc` | RPC `registrar_mensagem` | communication trail / sequence counters | Frontend token passed to RPC wrapper | Must be validated in RPC body | P1 | invalid channel, forged lead id, cross-tenant | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Request lot | custom `createSB.rpc` | RPC `solicitar_lote` | `lotes`, lead assignment/progression | Frontend token passed to RPC wrapper | Must validate broker/company/list server-side | P1 | ineligible broker, active lot conflict, cross-company list | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Rate list/lot | custom `createSB.rpc` | RPC `avaliar_lista` | list/lot quality feedback | Frontend token passed to RPC wrapper | Must validate list/lot company server-side | P1 | unauthorized list rating, cross-company list, invalid score | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/App.jsx` | Create/import list | custom `createSB.rpc` | RPC `criar_lista` / `importar_leads_batch` | `listas`, `leads`, import logs if present | Frontend token passed to RPC wrapper | Must derive company server-side | P1 high | payload allowlist, cross-company insert, duplicate handling, invalid phone | PARTIALLY_DOCUMENTED |
| `src/App.jsx` | Distribute lots | custom `createSB.rpc` | RPC `distribuir_lotes` | `lotes`, `leads`, broker assignments | Frontend token passed to RPC wrapper | Must validate manager/team/company server-side | P1 high | unauthorized manager, ineligible broker, mixed-company leads | PARTIALLY_DOCUMENTED |
| `src/components/TimesTab.jsx` | Move broker to team | Supabase/RPC path | RPC `atualizar_time_corretor` | `corretores`, `times` | Authenticated user | Must validate actor and target company/server-side | P1 | non-manager, cross-company broker/team, invalid team | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/components/TimesTab.jsx` | Toggle broker eligibility | Supabase/RPC path | RPC `atualizar_status_corretor` | `corretores.ativo`, `corretores.apto_para_receber` | Authenticated user | Must validate actor and target company/server-side | P1 | non-manager, cross-company broker, invalid status fields | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/components/TimesTab.jsx` | Create team | Supabase/RPC path | RPC `criar_time` | `times` | Authenticated user | Must derive company server-side | P1 | non-manager, invalid gestor, cross-company target | DOCUMENTED_FROM_SECURITY_INVENTORY |
| `src/components/CriarUsuarioForm.jsx` | Create user | Edge/API function | `criar-usuario` | auth/user/corretor records | Server-side function auth required | Must bind user to tenant/company server-side | P1 identity | unauthorized creator, wrong company binding, duplicate email | DOCUMENTED_AS_SUPPORT_PATH |
| `src/components/TimesTab.jsx` or admin flow | Reset password | Edge/API function action | `reset_password` | identity/password onboarding | Server-side function auth required | Must validate actor and target company | P1 identity | non-admin, cross-company target, token leakage | DOCUMENTED_AS_SUPPORT_PATH |
| `src/App.jsx` | Mandatory password-change completion / broker flags | generic REST wrapper `sb.patch` | direct DML `sb.patch("corretores", ...)` | `corretores.must_change_password`, `ativo`, `apto_para_receber` | Frontend token/RLS dependency | Frontend-supplied target risk; should be derived/validated server-side | P1 direct DML | forged corretor id, cross-company row, unauthenticated request | DOCUMENTED_DIRECT_DML |
| TBD | Persistent next action / follow-up | TBD | TBD | likely `leads` or CRM history/action table | TBD | Must validate lead/company/broker server-side | P1 / CRM continuity | lead id, responsible broker, next action type/date, cross-tenant negative test | PRODUCT_SCOPE_DOCUMENTED_BUT_PATH_NOT_CONFIRMED |

---

## 7. Consolidated security state

Existing evidence establishes:

```text
1. Reviewed lead/list/team operational mutations are mostly RPC-driven.
2. Direct DML remains known for corretores via src/App.jsx -> sb.patch("corretores", ...).
3. Live Supabase metadata found target function names in public pg_proc.
4. Reviewed functions are SECURITY DEFINER with search_path=public.
5. M1 RPCs generally have anon_execute=false and authenticated_execute=true, except some overloads/support paths with no client EXECUTE.
6. Body indicators are review signals, not proof of safety.
7. Any first technical PR must include negative tests and rollback.
```

Important non-conclusion:

```text
RPC-driven does not mean safe.
Authenticated EXECUTE does not mean authorized.
Body text mentioning auth.uid does not prove correct tenant isolation.
```

---

## 8. Real gaps after evidence reuse

| Gap | Description | Impact |
|---|---|---|
| G1 | No single filled UI/service/RPC/table/auth/tenant/test map existed before this consolidation. | This PR provides consolidation but still marks unconfirmed fields clearly. |
| G2 | Persistent next action/follow-up exists in product scope, but the exact UI/service/RPC/table persistence path is not confirmed. | Must be validated before claiming CRM continuity. |
| G3 | Service bridge fallback to anon/no-session remains a risk for sensitive RPC calls. | Candidate for first technical PR if scoped narrowly and tested. |
| G4 | Direct DML on `corretores` remains separate P1 direct DML backlog. | Important but not necessarily first M1 technical PR unless blocking onboarding or broker eligibility. |
| G5 | RPC bodies are not proven safe solely by current metadata/body indicators. | Technical hardening requires exact tests and rollback. |

---

## 9. First technical PR candidate recommendation

Recommended first technical PR candidate, based on existing evidence:

```text
Candidate: fail-closed authentication handling for M1 LeadOps service bridge calls.
```

Rationale:

```text
AceleracaoOperacional uses the service bridge for proximo_lead and registrar_feedback.
The service bridge may fall back to the anon key when no session token is found.
M1 sensitive RPCs should not be invoked from the frontend as anon/no-session calls.
This is narrower than replacing all corretores direct DML and safer than modifying RPC bodies before exact body review.
```

Proposed technical PR scope:

| Item | Proposed scope |
|---|---|
| Objective | Prevent M1 operational service bridge from calling sensitive RPCs without a real session token. |
| Files likely affected | `src/services/aceleracaoOperacionalService.js`; possibly caller error handling in `src/components/AceleracaoOperacional.jsx`. |
| RPCs involved | `proximo_lead`, `registrar_feedback` initially. |
| Tables involved | None directly from frontend; RPC backend may touch `leads`/`lotes`. |
| Security impact | Reduces accidental anon/no-session sensitive RPC invocation from M1 frontend service bridge. |
| Rollback | Revert service bridge change; no database rollback needed if no DB changes. |
| Preview/smoke | Vercel preview; authenticated broker opens Power Mode, loads next lead, registers feedback; logged-out/no-session state fails with friendly error. |
| Negative tests | no token, malformed token, expired token behavior if testable, anon key-only call path, cross-tenant remains RPC-level test requirement. |
| Required GPT validators | GPT 0, GPT 1, GPT 2 if UX error changes, GPT 3, GPT 4, GPT 7. |
| Bootstrap update | Not required unless runtime behavior or state index changes materially. |

Explicit exclusions for first technical PR:

```text
No database migration.
No RPC body change.
No grant/RLS/policy change.
No MesaCliente change.
No ADS/CAPI.
No Make/n8n.
No broad App.jsx refactor.
No direct corretores DML replacement in the same PR.
```

---

## 10. Alternative technical candidates deliberately deferred

| Candidate | Reason deferred |
|---|---|
| Replace `sb.patch("corretores", ...)` with narrow RPC(s) | Important P1 backlog, but broader because it touches identity/onboarding/broker eligibility and may require Supabase RPC/test design. |
| Harden M1 RPC bodies | Requires exact function body review and negative tests, not just metadata indicators. |
| Persist next action/follow-up | Product-critical, but the current UI/service/RPC/table path is not confirmed yet. Needs targeted source and schema/RPC validation. |
| Import/dedup implementation | Requires exact current import path review and may touch bulk lead write logic. |

---

## 11. Validators required for this consolidation

Minimum validators:

```text
GPT 0 - Documentation Auditor
GPT 1 - SaaS Architect
GPT 3 - Supabase Security
GPT 4 - Vercel/GitHub CI-CD
GPT 7 - LeadOps CRM Discador
```

Conditional validators:

```text
GPT 2 - UX/UI only if the first technical PR candidate changes user-facing error handling.
GPT 5 - SRE/Observability only if logs/metrics/rollback runbooks change.
```

---

## 12. Acceptance criteria

This consolidation is acceptable only if it remains:

```text
documentation-only
no code changes
no Supabase changes
no migrations
no RLS/grants/policies/RPC changes
no Vercel/GitHub Actions changes
no MesaCliente changes
no secrets or production payloads
no implementation authorization
clearly based on reused evidence
explicit about gaps and non-claims
```

---

## 13. Non-claims

This document does not claim:

```text
MVP is ready.
All UI paths are exhaustively traced.
All M1 RPC bodies are safe.
The first technical PR is already implemented.
Persistent next action/follow-up path is confirmed.
Direct corretores DML is fixed.
Supabase live state after 2026-06-09 has been revalidated.
```
