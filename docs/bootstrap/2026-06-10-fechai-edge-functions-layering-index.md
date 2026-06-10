# FECH.AI — Edge Functions, Layered SaaS Security and Multi-Tenant Authority Index

**Date:** 2026-06-10  
**Status:** ARCHITECTURE_INDEX / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Scope:** preserve the current evidence and discussion about Supabase Edge Functions, Vercel API proxy, frontend service bridges, RPC authority, RLS, tenant/company isolation and the future LeadOps migration path.  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Purpose

This document prevents the Edge Functions and layered-security architecture discussion from being lost.

It records the current evidence that FECH.AI already has real Supabase Edge Functions and a broader SaaS hardening track, but that M1 LeadOps / CRM / Discador currently still uses a frontend service bridge to call Supabase REST/RPC directly.

This file is documentation-only. It does not change application code, Supabase, migrations, RLS, grants, policies, RPC bodies, Edge Functions, Vercel, GitHub Actions, MesaCliente, ADS/CAPI, Make/n8n or production behavior.

---

## 2. Current confirmed Edge Functions

According to Wagner's live Supabase view and repository evidence, the project currently has at least two Supabase Edge Functions:

```text
assistente-ai
criar-usuario
```

Known live URLs:

```text
https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/assistente-ai
https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario
```

### 2.1 `criar-usuario`

Repository evidence:

```text
src/components/INTEGRAR_NO_GITHUB.md
src/components/CriarUsuarioForm.jsx
api/criar-usuario.js
```

Observed architecture:

```text
Frontend direct path:
CriarUsuarioForm.jsx
  -> https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario
  -> Authorization: Bearer session.access_token

Vercel proxy path:
Frontend
  -> /api/criar-usuario
  -> api/criar-usuario.js
  -> ${SUPABASE_URL}/functions/v1/criar-usuario
  -> Authorization forwarded from request
```

Documented function responsibility:

```text
- receives user creation payload;
- validates that caller is gestor/admin through JWT;
- creates Supabase Auth user with server-side privilege;
- inserts linked row in corretores;
- rolls back Auth user if insert fails;
- logs the action.
```

Architectural interpretation:

```text
criar-usuario is an identity-authority operation.
It is correctly treated as a server-side/Edge/API concern, not a pure frontend action.
It is also already tracked as P1 / identity authority in security evidence.
```

### 2.2 `assistente-ai`

Repository evidence:

```text
docs/discador-flow-ai/contratos/contrato-mvp-discador-flow-ai-v0.1.md
public/pme-call-assistant-beta.js
public/pme-call-assistant-ai-context-patch.js
src/App.jsx
```

Observed/documented role:

```text
assistente-ai is the AI/copilot Edge Function used by Discador Flow AI / PME.
It is not the authority for feedback, lead ownership, tenant, company, role, permission or commercial state.
```

Documented risk context:

```text
- HAR analysis showed get_contagens_corretor returning 401 JWT expired.
- OPTIONS to assistente-ai returned 200.
- POST to assistente-ai appeared as browser status 0.
- Hypothesis: combination of expired session, unclear frontend error handling and possible CORS/runtime/response issue.
```

Mandatory MVP rule already documented:

```text
AI failure must never block the manual PME operation.
```

---

## 3. Current layered architecture as observed

FECH.AI currently uses more than one backend access pattern. The architecture is transitional/hybrid, not blank.

### 3.1 Frontend React/Vite layer

Examples:

```text
src/App.jsx
src/components/CriarUsuarioForm.jsx
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
```

Responsibilities currently observed:

```text
- UI and local interaction state;
- some Supabase REST/RPC calls;
- some Supabase Edge Function calls;
- some Vercel API proxy calls;
- operational orchestration for CRM/Discador/PME.
```

Rule:

```text
Frontend displays and requests.
Frontend is not authority for tenant, company, role, permission, ownership, billing, commercial eligibility or sensitive state.
```

### 3.2 Frontend service bridge layer

Example:

```text
src/services/aceleracaoOperacionalService.js
```

Current M1 LeadOps path:

```text
AceleracaoOperacional.jsx
  -> aceleracaoOperacionalService.js
  -> Supabase REST /rest/v1/rpc/proximo_lead
  -> Supabase REST /rest/v1/rpc/registrar_feedback
```

Current hardening action:

```text
PR #82 is a containment/fail-closed patch for this existing frontend bridge.
It should not be treated as the final architecture for sensitive LeadOps operations.
```

### 3.3 Vercel API/proxy layer

Example:

```text
api/criar-usuario.js
```

Observed behavior:

```text
- handles OPTIONS;
- accepts only POST;
- requires Authorization: Bearer;
- forwards request to Supabase Edge Function criar-usuario;
- returns upstream status and payload;
- normalizes network failure as 502.
```

Architectural value:

```text
- centralized CORS/proxy handling;
- possible place for rate limiting, WAF integration and request normalization;
- hides direct Supabase function URL from frontend call sites where desired;
- does not replace Edge Function or DB/RPC authority.
```

### 3.4 Supabase Edge Function layer

Current confirmed functions:

```text
criar-usuario
assistente-ai
```

Expected role for future sensitive operations:

```text
- validate JWT/session server-side;
- derive trusted actor context;
- fetch user/corretor/company/team/role server-side;
- normalize errors;
- avoid service_role exposure in frontend;
- call RPCs or database operations with a closed contract;
- emit logs/audit events.
```

### 3.5 Supabase PostgreSQL / RPC / RLS authority layer

This remains the final authority layer.

Mandatory rule:

```text
Database/RPC validates and decides.
```

The database/RPC layer must continue to validate:

```text
auth.uid()
active user status
tenant/company derived from trusted backend state
actor role/profile
target object company/tenant ownership
payload allowlist
safe search_path for SECURITY DEFINER functions
audit logging where required
negative tests for cross-tenant access
```

---

## 4. Current SaaS security evidence that must not be lost

The project already has a major SaaS hardening track. Do not restart from zero.

Relevant evidence already exists for:

```text
- P1 write surface inventory;
- frontend direct DML mapping;
- RPC grants inventory;
- RPC body review checklist;
- live Supabase reconciliation;
- RLS/FORCE RLS table summary;
- function SECURITY DEFINER / search_path metadata;
- anon/authenticated/PUBLIC execute exposure;
- direct DML candidate for corretores;
- M1 LeadOps existing evidence map.
```

Primary files:

```text
docs/security/evidence/2026-06-07_authenticated_write_surface_p1_inventory.md
docs/security/evidence/2026-06-09_frontend_direct_dml_p1_inventory.md
docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md
docs/security/evidence/2026-06-09_rpc_body_review_p1.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-existing-evidence-map.md
```

High-value verified themes from those documents:

```text
- Most reviewed P1 frontend write flows are routed through RPCs or Edge/API functions.
- Direct frontend DML against public.corretores exists and remains a separate candidate.
- P1 functions include CRM/Discador, lists/import, teams/brokers, root/tenancy and MesaCliente-sensitive paths.
- RPC body review must prove auth.uid(), active user, tenant/company derivation, role/profile, ownership and payload allowlist.
- Live Supabase reconciliation found target functions in public.pg_proc.
- Reviewed live RPC rows showed SECURITY DEFINER with search_path=public, requiring strict validation.
- Several P1 tables already have RLS enabled and many have FORCE RLS enabled.
- This is evidence of mature hardening work, not proof that everything is production-approved.
```

Correct claim:

```text
FECH.AI has a mature SaaS/multi-tenant security evidence and hardening track that should be treated as baseline architecture context.
```

Incorrect claim:

```text
The entire platform is already fully secure and production-approved.
```

---

## 5. LeadOps-specific gap

Current state:

```text
LeadOps / CRM / Discador does not currently have a dedicated Edge Function for proximo_lead or registrar_feedback.
```

Current path:

```text
Frontend service bridge
  -> Supabase REST/RPC
  -> proximo_lead / registrar_feedback
```

Immediate containment:

```text
PR #82 blocks absent/malformed/expired session tokens before the frontend bridge attempts sensitive RPC calls.
```

Architectural gap:

```text
The final target architecture for sensitive LeadOps operations should be assessed by the SaaS architect before implementation.
```

Potential future target:

```text
AceleracaoOperacional.jsx
  -> aceleracaoOperacionalService.js
  -> Vercel API proxy or Supabase Edge Function
  -> validate JWT/session server-side
  -> derive user/corretor/company/team server-side
  -> call proximo_lead / registrar_feedback with minimal contract
  -> DB/RPC remains final authority for tenant/company/ownership
```

---

## 6. Edge Functions as premium architecture, with caution

Edge Functions can be a premium production architecture for sensitive SaaS operations when combined with:

```text
- server-side JWT/session validation;
- tenant/company derivation from trusted state;
- no service_role in frontend;
- RPC/DB authority retained;
- RLS/grants/policies retained;
- audit logs;
- rate limiting;
- CORS/WAF/proxy design;
- negative tests;
- rollback plan.
```

But Edge Functions are not security magic.

Blocking rule:

```text
Do not use service_role or privileged Edge context to bypass tenant/company validation.
```

Correct architectural phrase:

```text
Edge Function orchestrates; DB/RPC still validates and decides.
```

---

## 7. Tunnel / proxy / WAF discussion

A classic private network tunnel is not the default model for Supabase-hosted Edge Functions, because `/functions/v1/<name>` is a managed public endpoint.

However, FECH.AI can add application-layer protection in front of sensitive flows:

```text
Frontend
  -> Cloudflare/WAF or Vercel protection
  -> Vercel API Route / proxy
  -> Supabase Edge Function
  -> Supabase RPC/DB
```

Possible benefits:

```text
- rate limiting;
- bot/WAF controls;
- CORS normalization;
- endpoint abstraction;
- consistent error envelope;
- request logging before Supabase;
- safer transition away from direct frontend REST/RPC calls.
```

Caution:

```text
A proxy/WAF/tunnel adds a layer, but does not replace JWT validation, tenant/company validation, RLS, grants, RPC body safety or audit logs.
```

---

## 8. Recommended next architectural review for GPT 1

Ask GPT 1 to decide the safe migration sequence, not to implement immediately.

Questions for GPT 1:

```text
1. Should LeadOps sensitive operations remain frontend REST/RPC with fail-closed containment for the short term?
2. Should the final LeadOps architecture use Vercel API proxy, Supabase Edge Function, or both?
3. Should proximo_lead and registrar_feedback be migrated separately or as one bridge?
4. What must be validated server-side before calling each RPC?
5. What remains the responsibility of PostgreSQL/RPC/RLS even after Edge migration?
6. Should service_role ever be used, and if so under what strict tenant/company validation guardrails?
7. What logs/rate limits/negative tests are mandatory before production use?
8. How does this fit the existing tenant_id/empresa_id/RLS/RPC hardening track?
```

---

## 9. Suggested migration phases

Do not jump directly from #82 into a broad Edge migration.

Suggested sequence:

```text
Phase 1 — finish PR #82 fail-closed containment.
Phase 2 — GPT 1 architecture review using this document.
Phase 3 — create a LeadOps Edge/API contract document.
Phase 4 — implement one pilot path, preferably proximo_lead.
Phase 5 — add negative tests: no token, malformed token, expired token, cross-tenant, wrong broker/company, invalid payload.
Phase 6 — migrate registrar_feedback only after proximo_lead is stable.
Phase 7 — add rate limit/log/audit/WAF strategy.
```

---

## 10. Out of scope for this index

This document does not:

```text
- create any Edge Function;
- alter any Edge Function;
- deploy Supabase;
- alter RPCs;
- alter migrations;
- alter RLS/grants/policies;
- alter frontend runtime;
- alter Vercel API routes;
- prove the live body of criar-usuario or assistente-ai;
- prove production readiness.
```

Any implementation must follow the master protocol:

```text
First contract. Then evidence. Then dry-run. Then rollback test. Then controlled persistence.
```
