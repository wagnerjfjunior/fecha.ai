# FECH.AI - M1 LeadOps / CRM / Discador Reconciliation Pass 1

Date: 2026-06-10
Status: RECONCILIATION_PASS_1 / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE
Front: M1 - LeadOps / CRM / Discador
Risk: R3/R4 - personal data, leads, broker operations, Supabase RPCs, RLS and tenant/company isolation.
Base branch observed: main
Base commit observed: 6805910816dfe127bc4a166a50d1fa0b5eae84a8

---

## 1. Objective

Start the M1 MVP track with a documentation-only reconciliation pass before any implementation.

This file compares the documented M1 MVP scope with the current repository and existing security evidence.

This document does not authorize code, SQL, migration, RPC, RLS, grant, Vercel, MesaCliente or production changes.

---

## 2. Protocol

This pass follows:

```text
docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md
docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
```

Operating rule:

```text
First contract. Then evidence. Then dry-run. Then rollback test. Then controlled persistence.
```

---

## 3. Sources reviewed

```text
docs/product/fechai-mvp-scope-v1.md
src/App.jsx
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
docs/security/evidence/2026-06-09_frontend_direct_dml_p1_inventory.md
docs/security/evidence/2026-06-09_rpc_body_review_p1.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
```

---

## 4. Verified M1 scope

The M1 MVP scope includes:

```text
lead/list import
basic deduplication
phone validation
minimum CRM/funnel
call action
WhatsApp action
quick status
quick note
next action/follow-up
Power Mode
weekend dashboard
multi-tenant isolation
RLS where applicable
no trust in frontend tenant_id/empresa_id
rollback
Vercel preview
LGPD/opt-out where applicable
```

---

## 5. Current code evidence

### 5.1 src/components/AceleracaoOperacional.jsx

Observed:

```text
WhatsApp, call and email channels
first-contact and follow-up contexts
quick feedback buttons
load next lead flow
Power Mode toggle
session stats
weekend goal / missing visits cards
```

### 5.2 src/services/aceleracaoOperacionalService.js

Observed:

```text
buscarProximoLeadOperacional -> RPC proximo_lead
registrarFeedbackOperacional -> RPC registrar_feedback
calcularPressaoOperacional
```

Security note:

```text
The service sends Authorization with token fallback to anon key.
Future technical PRs must validate that sensitive RPCs fail closed for anon/no-session calls.
```

### 5.3 src/App.jsx

Observed from current code/security evidence:

```text
Main app contains CRM/funnel/dialer surfaces.
A known direct P1 DML candidate remains: sb.patch("corretores", ...).
Lead/lote operational writes appear RPC-driven in reviewed paths.
```

---

## 6. Security evidence summary

Existing security evidence says:

```text
- One confirmed direct frontend P1 write exists: src/App.jsx -> sb.patch("corretores", ...).
- No direct frontend table-level writes were found for leads/lotes/times/lista_visibilidade in reviewed patterns.
- Lead mutation paths appear RPC-driven.
- M1 RPCs such as proximo_lead, registrar_feedback, mover_funil, registrar_mensagem and solicitar_lote require body/security review.
- Authenticated EXECUTE does not prove authorization safety.
```

---

## 7. Divergences and gaps

| ID | Finding | Classification |
|---|---|---|
| D1 | Bootstrap references docs/product/leadops-crm-discador/leadops-mvp-functional-spec-v1.md, but this file was not found on main. | NEEDS_DOCUMENTATION_RECONCILIATION |
| D2 | aceleracaoOperacionalService.js falls back to Bearer anon key when no session token is found. | SECURITY_REVIEW_REQUIRED |
| D3 | Direct corretores DML remains known P1 candidate. | SECURITY_BACKLOG |
| D4 | AceleracaoOperacional metrics appear session-local. | NEEDS_PRODUCT_DECISION |
| D5 | Persistent next-action/follow-up was not confirmed in this pass. | NEEDS_VALIDATION |

---

## 8. Initial readiness matrix

| Area | Classification |
|---|---|
| Dialer actions | READY_FOR_MVP_VALIDATION |
| WhatsApp action | READY_FOR_MVP_VALIDATION |
| Email action | READY_FOR_MVP_VALIDATION |
| Power Mode | READY_FOR_MVP_VALIDATION |
| Feedback registration | SECURITY_REVIEW_REQUIRED |
| Weekend dashboard | NEEDS_PRODUCT_DECISION |
| CSV/XLSX import | NEEDS_DEEPER_VALIDATION |
| Manual import | NEEDS_CODE_VALIDATION |
| Deduplication | NEEDS_CODE_VALIDATION |
| Multi-tenant isolation | SECURITY_REVIEW_REQUIRED |
| RLS/RPC grants | SECURITY_REVIEW_REQUIRED |
| Rollback/preview | GPT4_VALIDATION_REQUIRED |

---

## 9. Required validators for future M1 technical PRs

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
GPT 2 - UX/UI if UI/flow changes
GPT 5 - SRE/observability if runtime ops changes
GPT 6 - ADS/CAPI if tracking changes
GPT 8 - MesaCliente if touched
GPT 9 - integrations/messaging if touched
GPT 10 - monetization/GTM if touched
```

---

## 10. Out of scope for first M1 technical PR

```text
MesaCliente parser
MesaCliente financial engine
ADS/CAPI
WhatsApp integration changes
Make/n8n
billing
root/billing/status hardening unless blocking MVP
direct corretores DML replacement unless onboarding blocks MVP
large App.jsx refactor
new database schema without live reconciliation
```

---

## 11. Next safe step

Next safe step:

```text
M1 Reconciliation Pass 2 - exact UI/RPC mapping
```

Pass 2 should inspect:

```text
src/App.jsx
src/components/TimesTab.jsx
src/components/CriarUsuarioForm.jsx
src/components/RootPanel.jsx
src/components/TenantProvisioningRoot.jsx
docs/04-banco-de-dados/rpcs-e-functions.md
docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md
```

Pass 2 must produce:

```text
exact M1 RPC list used by UI
exact direct DML candidates
MVP acceptance checklist mapped to current code/RPCs
first technical PR candidate
specialist validator list
bootstrap update requirement if state/path changes
```

---

## 12. Non-claims

This document does not claim:

```text
MVP is ready for production
all M1 RPCs are safe
frontend tracing is exhaustive
Supabase live state after 2026-06-09 is current
Vercel runtime is validated
action metrics are persisted
```

---

## 13. Acceptance criteria

This reconciliation is acceptable only if it remains:

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
```
