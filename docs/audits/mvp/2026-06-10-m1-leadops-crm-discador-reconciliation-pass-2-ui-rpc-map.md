# FECH.AI - M1 LeadOps / CRM / Discador Reconciliation Pass 2

Date: 2026-06-10
Status: RECONCILIATION_PASS_2 / UI_RPC_MAPPING / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE
Front: M1 - LeadOps / CRM / Discador
Risk: R3/R4 - personal data, leads, broker operations, Supabase RPCs, RLS and tenant/company isolation.
Base branch observed: main
Base commit observed: d422cee092a3ce5c8fe0cc472c4298ca0f1abf64

---

## 1. Objective

Map the M1 UI/service/RPC surface before any implementation.

This document is the next step after:

```text
docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-reconciliation-pass-1.md
```

This pass prepares the exact technical map required before a first M1 runtime patch.

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

## 3. Sources to inspect in this pass

Minimum source set:

```text
src/App.jsx
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
src/components/TimesTab.jsx
src/components/CriarUsuarioForm.jsx
src/components/RootPanel.jsx
src/components/TenantProvisioningRoot.jsx
docs/04-banco-de-dados/rpcs-e-functions.md
docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md
docs/security/evidence/2026-06-09_rpc_body_review_p1.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
```

---

## 4. Required UI to RPC map

Pass 2 must produce an exact map in this format:

| UI / component | User action | Service/wrapper | RPC/direct path | Expected table impact | Auth source | Tenant/company source | Risk | Test requirement |
|---|---|---|---|---|---|---|---|---|
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

Mandatory M1 RPC candidates to map:

```text
proximo_lead
registrar_feedback
atualizar_feedback
mover_funil
mover_funil_lote
registrar_mensagem
solicitar_lote
avaliar_lista
criar_lista
importar_leads_batch
distribuir_lotes
```

Support/governance paths to map if used by M1 screens:

```text
get_meus_times
get_corretores_time
atualizar_time_corretor
atualizar_status_corretor
criar_time
criar-usuario
reset_password
```

Known direct DML candidate to keep visible:

```text
src/App.jsx -> sb.patch("corretores", ...)
```

---

## 5. Current known starting point

From Pass 1 and existing security evidence:

```text
AceleracaoOperacional uses proximo_lead through buscarProximoLeadOperacional.
AceleracaoOperacional uses registrar_feedback through registrarFeedbackOperacional.
Call, WhatsApp and email actions are opened client-side.
Session metrics appear local until persistence is proven.
The service bridge may fall back to Bearer anon key when no session token is found.
Lead writes appear RPC-driven in reviewed paths.
Direct corretores DML remains a separate P1 security backlog item.
```

---

## 6. Required security questions per M1 RPC

For every RPC mapped in this pass, answer:

```text
1. Is anon EXECUTE false in current evidence?
2. Is authenticated EXECUTE true or false?
3. Is the function SECURITY DEFINER or INVOKER?
4. Does evidence show search_path=public?
5. Does the body mention auth.uid()?
6. Does the body derive empresa/tenant server-side?
7. Does the body avoid trusting frontend empresa_id/tenant_id/corretor_id as authority?
8. Does it validate target lead/list/lot/team belongs to same empresa/tenant?
9. Does it allowlist payload/status/feedback/stage fields?
10. What negative tests are required before a technical patch?
```

---

## 7. Required MVP acceptance mapping

Map each MVP acceptance item to current implementation status:

| MVP item | Current evidence | Status |
|---|---|---|
| Import simple list | TBD | TBD |
| Detect basic duplicates | TBD | TBD |
| Call/open WhatsApp in few clicks | TBD | TBD |
| Register status/feedback | TBD | TBD |
| Funnel shows leads by stage | TBD | TBD |
| Weekend dashboard shows scheduled visits | TBD | TBD |
| Data respects tenant/company/broker | TBD | SECURITY_REVIEW_REQUIRED |
| Minimum import/error logs | TBD | TBD |
| Mobile and desktop flow | TBD | TBD |
| Rollback path | TBD | GPT4_VALIDATION_REQUIRED |

Allowed status values:

```text
READY_FOR_MVP_VALIDATION
NEEDS_CODE_VALIDATION
NEEDS_PRODUCT_DECISION
SECURITY_REVIEW_REQUIRED
GPT4_VALIDATION_REQUIRED
OUT_OF_SCOPE
NOT_CONFIRMED
```

---

## 8. Required direct DML review

Pass 2 must list all direct DML candidates found in reviewed M1 paths.

Minimum known candidate:

```text
src/App.jsx -> sb.patch("corretores", ...)
```

The output must classify whether each candidate is:

```text
M1_BLOCKER
SECURITY_BACKLOG
OUT_OF_SCOPE_FOR_FIRST_M1_PATCH
REPLACEMENT_RPC_REQUIRED
```

---

## 9. Required first technical PR candidate

Pass 2 must end with exactly one recommended first technical PR candidate.

The candidate must include:

```text
objective
files to change
tables/RPCs involved
DML matrix
security impact
rollback plan
preview/smoke plan
negative tests
required GPT validators
bootstrap update requirement
```

No candidate may include MesaCliente, ADS/CAPI, billing, Make/n8n or broad App.jsx refactor unless explicitly justified as a blocker.

---

## 10. Required validators for Pass 2

Minimum validators before merge:

```text
GPT 0 - Documentation Auditor
GPT 1 - SaaS Architect
GPT 3 - Supabase Security
GPT 4 - Vercel/GitHub CI-CD
GPT 7 - LeadOps CRM Discador
```

Conditional validators:

```text
GPT 2 - UX/UI if UI flow or responsive behavior is classified
GPT 5 - SRE/observability if logs, monitoring, rollback or runbooks are changed
GPT 6 - ADS/CAPI if tracking/UTM/ads feedback is touched
GPT 8 - MesaCliente if any MesaCliente path appears
GPT 9 - integrations/messaging if WhatsApp official, webhooks or Make/n8n appear
GPT 10 - monetization/GTM if pricing or packaging appears
```

---

## 11. Out of scope for Pass 2

```text
runtime code changes
SQL/migration changes
RPC/grant/RLS/policy changes
Vercel/GitHub Actions changes
MesaCliente parser/financial engine changes
ADS/CAPI changes
WhatsApp official/non-official integration changes
Make/n8n changes
billing/pricing changes
production changes
```

---

## 12. Non-claims

This document does not claim:

```text
MVP is ready
all M1 RPCs are safe
all UI paths have already been mapped
Supabase live is current after 2026-06-09
Vercel runtime has been validated
first technical PR is already authorized
```

---

## 13. Acceptance criteria

This PR is acceptable only if it remains:

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
