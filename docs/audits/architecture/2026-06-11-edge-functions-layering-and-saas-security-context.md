# FECH.AI - Edge Functions, SaaS Security Layers and LeadOps Bridge Context

**Date:** 2026-06-11  
**Status:** ARCHITECTURE_CONTEXT / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base:** after PR #82 merge (`0446cf4b5a6ae201adf44798a4aafc6e665429d9`)

---

## 1. Purpose

This document preserves the architectural discussion about FECH.AI Edge Functions, Vercel API proxy, frontend service bridges, Supabase RPC/RLS authority and future LeadOps migration decisions.

It exists because FECH.AI is no longer a blank prototype. It is a controlled multi-company pilot with real users, real data and active modules. Architecture decisions must preserve the current pilot operation while security is hardened incrementally.

This is documentation-only. It does not alter runtime, frontend, Supabase, Edge Functions, migrations, RLS, grants, policies, RPC bodies, Vercel, GitHub Actions, MesaCliente, ADS/CAPI, Make/n8n or production behavior.

---

## 2. Current confirmed Edge Functions

Current known Supabase Edge Functions in the project:

```text
assistente-ai
criar-usuario
```

Known public endpoints:

```text
https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/assistente-ai
https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario
```

These URLs are not secrets by themselves. Secrets, service role keys, JWTs, payloads and user logs must never be exposed in documentation, frontend bundles or browser logs.

### 2.1 `criar-usuario`

Observed/referenced files:

```text
src/components/INTEGRAR_NO_GITHUB.md
src/components/CriarUsuarioForm.jsx
api/criar-usuario.js
```

Current architectural reading:

```text
Frontend direct path:
CriarUsuarioForm.jsx
  -> Supabase Edge Function criar-usuario
  -> Authorization: Bearer session.access_token

Vercel proxy path:
Frontend
  -> /api/criar-usuario
  -> api/criar-usuario.js
  -> Supabase Edge Function criar-usuario
  -> Authorization forwarded from request
```

`criar-usuario` is identity-authority related. It is correctly treated as server-side/Edge/API concern, not as pure frontend authority.

### 2.2 `assistente-ai`

Observed/referenced files:

```text
docs/discador-flow-ai/contratos/contrato-mvp-discador-flow-ai-v0.1.md
public/pme-call-assistant-beta.js
public/pme-call-assistant-ai-context-patch.js
src/App.jsx
```

`assistente-ai` is AI/copilot infrastructure for Discador Flow AI / PME. It must not be authority for tenant, company, lead ownership, role, permission, feedback or commercial state.

Mandatory product rule:

```text
AI failure must never block manual PME operation.
```

---

## 3. Current layered architecture

FECH.AI currently uses a hybrid access model.

```text
Frontend React/Vite
  -> direct Supabase Auth / read paths where RLS is strong
  -> frontend service bridges for selected RPC paths
  -> Vercel API proxy for selected web/backend paths
  -> Supabase Edge Functions for selected server-side operations
  -> Supabase PostgreSQL/RPC/RLS as final authority
```

Canonical principle:

```text
Frontend displays and requests.
Edge/Vercel API orchestrates when needed.
Database/RPC validates and decides.
AI assists, but is not authority.
```

The frontend is not sovereign for:

```text
tenant
empresa
corretor
role/profile
permission
ownership
billing
financial rule
commercial eligibility
lead distribution
client-safe visibility
internal policy
sensitive data
```

---

## 4. M1 LeadOps current state after PR #82

Current path:

```text
AceleracaoOperacional.jsx
  -> src/services/aceleracaoOperacionalService.js
  -> Supabase REST /rest/v1/rpc/proximo_lead
  -> Supabase REST /rest/v1/rpc/registrar_feedback
```

PR #82 was merged as a small containment patch, not as a final architecture migration.

PR #82 changed only:

```text
src/services/aceleracaoOperacionalService.js
```

Security containment added by PR #82:

```text
- removed Authorization fallback to anon key;
- keeps Authorization: Bearer <token> only;
- protects proximo_lead and registrar_feedback as sensitive M1 RPCs;
- fails closed before fetch when token is absent, malformed, expired or missing authenticated claims;
- preserves the current Supabase RPC path;
- does not alter Supabase, RLS, grants, policies or RPC bodies.
```

Known real Supabase validation already performed during PR #82 review:

```text
public.proximo_lead exists
public.registrar_feedback exists
anon_execute=false for both
authenticated_execute=true for both
public_execute=false for both
both are SECURITY DEFINER
both use search_path=public
critical tables such as leads, corretores, lotes, listas, lista_visibilidade and times have RLS enabled
```

Important limitation:

```text
PR #82 is not final Supabase/RPC hardening evidence.
RPC bodies, full policies and cross-tenant negative tests remain a separate GPT 3/Supabase audit track.
```

---

## 5. Why not migrate all LeadOps to Edge now

A direct migration to Edge Function/BFF is not rejected. It is deferred.

Reason:

```text
The current app is in Pilot Production multi-tenant.
Real users are using Discador, PME, MesaCliente, enrichment, funil, dashboard and LeadOps.
Big-bang refactor creates operational risk.
```

Correct sequence:

```text
1. Contain the current bridge (#82).
2. Document real architecture and current Edge Functions.
3. Create Supabase access routing matrix.
4. Define LeadOps Edge/BFF contract.
5. Implement one narrow Edge/BFF migration at a time.
6. Canary with family first, then Laura, then Tegra/Helbor pilots.
```

---

## 6. Premium architecture target

The desired mature architecture is not "Edge Function for everything".

The desired mature architecture is:

```text
Frontend has no authority.
Edge/Vercel API is used where it adds security, orchestration, observability or rate limit.
RPC/DB remains final authority.
RLS/policies/grants remain mandatory safety layer.
Service role never reaches frontend.
```

Recommended target by operation type:

| Operation type | Recommended path |
|---|---|
| Auth/session | Frontend -> Supabase Auth |
| Low-risk read with strong RLS | Frontend -> Supabase direct/read RPC |
| Domain write with JWT and DB authority | Frontend -> RPC |
| Sensitive LeadOps write/distribution | Frontend -> Edge/BFF -> RPC |
| Root/admin/billing/identity | Frontend -> Vercel API or Edge -> root/admin RPC -> audit |
| External integrations / secrets | Vercel API or Edge server-side |
| MesaCliente/parser/financial engine | Separate contract; never frontend authority |
| AI/PME copilot | Edge Function with graceful degradation |

---

## 7. Future LeadOps Edge/BFF candidates

Candidate future contracts:

```text
leadops-proximo-lead
leadops-registrar-feedback
```

A future contract must define:

```text
payload schema
JWT/session validation
tenant/company/corretor source of truth
rate limit
correlation_id / trace_id
error envelope
logs without secrets
RPC called
negative tests
rollback plan
canary rollout
```

Do not implement this migration before the contract is approved.

---

## 8. Pilot Production and canary note

FECH.AI should currently be treated as:

```text
Pilot Production multi-tenant / multi-company
no paid customers yet
real users and real data
modules active
hardening in flight
commercialization blocked until Security Go
```

Recommended rollout cohorts:

```text
Canary Cohort 1: family
Pilot Cohort 2: Laura - laura@tegravendas.com.br
Pilot Cohort 3: Tegra / Helbor / remaining pilot users
Paid customers: only after Security Go / Commercial Readiness Gate
```

Operational rule:

```text
Do not replace the airplane in flight.
Replace one critical part at a time, with sensor, checklist, controlled pilot and rollback.
```

---

## 9. Required follow-up documents

Next recommended documentation PRs:

```text
docs(architecture): add Supabase access routing matrix
docs(release): add Pilot Production and canary rollout plan
docs(security): audit LeadOps RPC bodies, policies and cross-tenant negative tests
```

This document is the architecture context bridge for those follow-ups.
