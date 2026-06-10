# FECH.AI - Edge Functions, Layering and SaaS Security Context

Date: 2026-06-10
Status: ARCHITECTURE_CONTEXT / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE
Scope: current Edge Functions inventory, current layering evidence, relation with Supabase Auth/RLS/RPC hardening, and guidance for future LeadOps architecture decisions.

---

## 1. Purpose

This document records the architecture discussion around Edge Functions, service bridges, RPCs, tenant isolation and the current FECH.AI SaaS security track.

It exists to avoid losing the following context:

```text
FECH.AI already has real Supabase Edge Functions.
FECH.AI already has an advanced Supabase/RLS/RPC hardening evidence track.
LeadOps currently does not have its own Edge Function.
The current LeadOps path is still frontend service bridge -> Supabase REST/RPC.
The immediate PR #82 fix is fail-closed session handling in the existing bridge, not an Edge migration.
A future Edge migration should be designed by contract before implementation.
```

This file is documentation-only. It does not alter code, Supabase, migrations, RLS, grants, policies, RPC bodies, Edge Functions, Vercel, production or runtime behavior.

---

## 2. Source hierarchy used

Use the FECH.AI truth hierarchy:

```text
1. Real applied Supabase state
2. GitHub on the correct branch
3. Official documentation
4. Wagner direct information
5. Declared technical inference
6. Memory / previous conversation
```

Current confirmed context is based on:

```text
- Wagner direct information: two Edge Functions exist in Supabase:
  - assistente-ai
  - criar-usuario

- GitHub evidence:
  - src/components/INTEGRAR_NO_GITHUB.md
  - src/components/CriarUsuarioForm.jsx
  - api/criar-usuario.js
  - docs/discador-flow-ai/contratos/contrato-mvp-discador-flow-ai-v0.1.md
  - docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md
  - docs/security/evidence/2026-06-09_rpc_body_review_p1.md
  - docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
  - docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-existing-evidence-map.md
```

Open reservation:

```text
This document does not query the Supabase dashboard or live Edge Function source code.
It records repository evidence plus Wagner-provided live function names/URLs.
```

---

## 3. Current real Edge Functions

### 3.1 `criar-usuario`

Known URL:

```text
https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario
```

Repository evidence:

```text
src/components/INTEGRAR_NO_GITHUB.md
src/components/CriarUsuarioForm.jsx
api/criar-usuario.js
```

Observed purpose:

```text
Admin/gestor user creation flow.
```

Documented behavior in repository:

```text
- receives user creation payload;
- validates caller as gestor via JWT;
- creates Supabase Auth user using service role inside the server-side function;
- inserts the linked record in corretores;
- rolls back auth user if insert fails;
- records log.
```

Observed frontend direct call pattern:

```text
Frontend component -> Supabase Edge Function
Authorization: Bearer <session.access_token>
```

Observed Vercel API proxy pattern:

```text
Frontend/client -> /api/criar-usuario -> Supabase Edge Function criar-usuario
```

`api/criar-usuario.js` requires an Authorization header beginning with `Bearer ` and forwards that header to the Supabase Edge Function.

Architectural interpretation:

```text
criar-usuario is an identity/admin-sensitive operation.
It is correctly positioned outside the browser-only execution path because service_role must never exist in frontend code.
```

### 3.2 `assistente-ai`

Known URL:

```text
https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/assistente-ai
```

Repository evidence:

```text
docs/discador-flow-ai/contratos/contrato-mvp-discador-flow-ai-v0.1.md
public/pme-call-assistant-beta.js
public/pme-call-assistant-ai-context-patch.js
src/App.jsx
```

Observed purpose:

```text
Discador Flow AI / PME assistant; AI as commercial text copilot.
```

Relevant documented observations:

```text
- get_contagens_corretor returned 401 JWT expired;
- OPTIONS to assistente-ai returned 200;
- POST to assistente-ai appeared as status 0 in browser;
- initial hypothesis: expired session + unclear frontend error handling + possible CORS/runtime/response issue in the Edge Function.
```

Architectural interpretation:

```text
assistente-ai is not the authority for tenant, permission, feedback or lead ownership.
It is an AI/copilot layer and must degrade gracefully.
Failure of IA must not block manual PME/discador operation.
```

---

## 4. Current layering model observed

The current FECH.AI architecture is not a single homogeneous backend model. It is a hybrid cloud SaaS structure.

### 4.1 Presentation layer

Examples:

```text
src/App.jsx
src/components/AceleracaoOperacional.jsx
src/components/CriarUsuarioForm.jsx
public/pme-call-assistant-beta.js
```

Responsibilities:

```text
- UI;
- navigation;
- local state;
- error/loading/empty states;
- channel actions;
- user experience.
```

Critical rule:

```text
Frontend displays and requests.
Frontend is not authority for tenant, empresa, role, permission, ownership, billing or sensitive state.
```

### 4.2 Frontend service bridge layer

Examples:

```text
src/services/aceleracaoOperacionalService.js
custom RPC wrapper patterns in src/App.jsx
```

Responsibilities:

```text
- client-side orchestration;
- session-aware calls;
- payload normalization;
- calling Supabase REST/RPC or API endpoints.
```

Current LeadOps state:

```text
AceleracaoOperacional currently uses a frontend service bridge for:
- proximo_lead
- registrar_feedback
```

Immediate risk addressed by PR #82:

```text
Do not allow anon-key fallback or no-session execution attempt for sensitive M1 RPCs.
```

### 4.3 Vercel API / proxy layer

Confirmed example:

```text
api/criar-usuario.js
```

Observed behavior:

```text
- handles OPTIONS;
- rejects non-POST;
- requires Authorization: Bearer ...;
- forwards payload and Authorization to Supabase Edge Function criar-usuario;
- normalizes upstream response.
```

Architectural value:

```text
- can centralize CORS/proxy behavior;
- can hide direct Supabase function URL from app code;
- can add rate limiting / request shaping later;
- can normalize errors;
- can provide a stable FECH.AI API surface.
```

Reservation:

```text
This layer does not replace Supabase Edge Function validation or database/RPC authority.
```

### 4.4 Supabase Edge Function layer

Current confirmed functions:

```text
- criar-usuario
- assistente-ai
```

Responsibilities when used correctly:

```text
- server-side validation;
- safe use of secrets/service role;
- integration with external APIs;
- orchestration before RPC/DB;
- structured error handling;
- logging/auditing opportunities.
```

Critical rule:

```text
A service role may exist in an Edge Function, but only with strict server-side validation.
It must never exist in frontend code, public bundle, browser logs or client payloads.
```

### 4.5 Supabase RPC / PostgreSQL / RLS layer

Responsibilities:

```text
- final business authority;
- tenant/company isolation;
- auth.uid() validation;
- active user validation;
- role/profile checks;
- ownership/team checks;
- sensitive writes;
- RLS/policies/grants;
- auditability.
```

Core rule:

```text
Database/RPC validates and decides.
```

Even with Edge Functions, do not move all authority away from the database.

---

## 5. Security and multi-tenant context already achieved / in progress

Do not treat FECH.AI as starting from zero.

The project has recent evidence and hardening work around:

```text
- authenticated write surfaces;
- frontend direct DML inventory;
- RPC grants inventory;
- RPC body review;
- Supabase live reconciliation;
- RLS/FORCE RLS metadata;
- anon/PUBLIC EXECUTE exposure;
- P1/P0 hardening track;
- root control-plane hardening for criar_empresa_root;
- M1 LeadOps evidence consolidation.
```

Important live reconciliation facts from recent evidence:

```text
- All target PostgreSQL RPC/function names from the PR #71 target list were found in live public.pg_proc.
- Reviewed live function rows follow a material pattern: public schema, postgres owner, SECURITY DEFINER, volatile, search_path=public.
- SECURITY DEFINER by itself is not proof of vulnerability, but it requires strict body validation.
- Known P1 tables such as corretores, leads, lista_visibilidade, listas, lotes and times have RLS enabled; many have FORCE RLS enabled.
```

Important minimum requirements already documented for SaaS operation:

```text
- multi-tenant isolation;
- multi-company governance;
- RLS enabled on multi-tenant tables;
- RPCs for sensitive write paths;
- auth.uid() / active user / tenant-company / role validation;
- no service_role in frontend;
- no anon EXECUTE on sensitive RPCs;
- observability and rollback awareness.
```

Correct claim:

```text
FECH.AI has a mature security evidence and hardening track that must be used as baseline for future SaaS work.
```

Incorrect claim:

```text
The entire platform is fully production-secure without further evidence.
```

---

## 6. LeadOps current gap

LeadOps does not currently have a dedicated Edge Function documented or implemented in the repository evidence reviewed here.

Current path:

```text
AceleracaoOperacional.jsx
  -> aceleracaoOperacionalService.js
    -> Supabase REST/RPC
      -> proximo_lead / registrar_feedback
```

This is why PR #82 is still valid as a small immediate technical containment:

```text
Fail closed in the current bridge before attempting sensitive RPCs without a usable session token.
```

PR #82 should not be converted into an Edge migration.

Reason:

```text
An Edge migration changes architecture, deployment, CORS, auth verification, logging, payload contracts, tests and rollback.
It should be preceded by a contract and implementation plan.
```

---

## 7. Recommended future premium architecture for sensitive LeadOps operations

Potential target model:

```text
AceleracaoOperacional.jsx
  -> aceleracaoOperacionalService.js
    -> /api/leadops/proximo-lead or Supabase Edge Function
      -> validate Authorization Bearer token
      -> rate limit / request shaping
      -> validate user context server-side
      -> call controlled RPC
        -> RPC validates auth.uid(), tenant, empresa, corretor, role, team/ownership
          -> PostgreSQL/RLS/policies remain authority
```

Two viable patterns:

### Pattern A - Direct Supabase Edge Function

```text
Frontend -> Supabase Edge Function -> RPC/DB
```

Pros:

```text
- fewer FECH.AI-managed layers;
- close to Supabase Auth/RPC;
- natural place for secrets and external integrations.
```

Cons:

```text
- function URL remains public;
- CORS and response behavior must be handled carefully;
- needs Supabase function deployment and logging discipline.
```

### Pattern B - Vercel API proxy + Supabase Edge Function

```text
Frontend -> Vercel API Route -> Supabase Edge Function -> RPC/DB
```

Pros:

```text
- stable FECH.AI API surface;
- can centralize rate limiting, CORS, request size, error normalization;
- matches existing api/criar-usuario.js precedent.
```

Cons:

```text
- adds another layer to test and observe;
- does not remove the need for Edge/DB validation;
- more moving parts for rollback and incident response.
```

Architectural recommendation:

```text
For admin/identity, external AI and future high-risk operations, Edge Functions are a strong/premium architecture layer.
For LeadOps, adopt only after a contract defines exact payload, auth, tenant validation, observability, tests and rollback.
```

---

## 8. Tunnel / extra perimeter discussion

A network tunnel does not usually hide Supabase-managed Edge Function URLs, because those endpoints are intentionally public HTTP endpoints behind Supabase infrastructure.

More realistic perimeter options:

```text
- Vercel API proxy as application gateway;
- WAF / Cloudflare in front of the FECH.AI domain;
- rate limiting by IP/user/empresa;
- Turnstile or bot control for public-facing paths when appropriate;
- request signing for server-to-server paths if later introduced;
- structured logs and anomaly detection.
```

Do not treat a tunnel as a replacement for:

```text
- JWT/session validation;
- RLS;
- RPC body checks;
- tenant/company isolation;
- least privilege;
- secret management.
```

---

## 9. Suggested message for GPT 1 Architect

```text
GPT 1 - FECH.AI Arquiteto SaaS

Contexto:
Estamos discutindo a arquitetura de camadas do FECH.AI no ponto em que a PR #82 corrige o service bridge do M1 LeadOps para falhar fechado sem token/sessao utilizavel. Surgiu a duvida se deveriamos migrar LeadOps para Edge Function, considerando que o projeto ja possui duas Edge Functions reais no Supabase: criar-usuario e assistente-ai.

Achados confirmados:
1. criar-usuario existe como Supabase Edge Function e tambem possui proxy Vercel em api/criar-usuario.js. O fluxo usa Authorization: Bearer <session.access_token> e a documentacao informa validacao JWT, uso interno de service role, criacao no Supabase Auth, insert em corretores e rollback se falhar.
2. assistente-ai existe como Edge Function ligada ao Discador Flow AI / PME. A documentacao registra problemas de JWT expirado, CORS/runtime/resposta e define que a IA deve degradar graciosamente, sem travar a operacao manual.
3. LeadOps nao possui Edge Function dedicada hoje. O caminho atual ainda e AceleracaoOperacional.jsx -> aceleracaoOperacionalService.js -> Supabase REST/RPC -> proximo_lead / registrar_feedback.
4. A #82 nao deve virar migracao Edge. Ela e contencao pequena: remover fallback anon/no-session e falhar antes do fetch quando o token estiver ausente, malformado ou expirado.
5. O projeto ja tem forte trilha de hardening Supabase/RLS/RPC: P1 inventories, direct DML inventory, RPC grants, RPC body review, live reconciliation, RLS/FORCE RLS and P0/P1 hardening. Nao estamos comecando seguranca do zero.
6. O principio continua: Frontend solicita/exibe; Banco/RPC valida/decide; IA auxilia; Edge Function orquestra, mas nao substitui validacao final de tenant/empresa/corretor/RLS/RPC.

Pedido ao GPT 1:
Avalie qual deve ser a decisao arquitetural para LeadOps sensivel no roadmap:
- manter curto prazo com service bridge frontend fail-closed + RPCs/RLS fortes;
- criar contrato documental para Edge Function LeadOps;
- migrar proximo_lead e registrar_feedback para Edge Function direta;
- ou usar Vercel API proxy + Edge Function como gateway premium.

Avalie tambem:
- impacto multi-tenant;
- relacao com tenant_id/empresa_id ja inseridos nas tabelas;
- trabalho ja feito de RLS/RPC/grants;
- risco de usar service_role em Edge Function sem validacao forte;
- observabilidade, rate limit, logs, rollback, CORS e testes negativos;
- se essa migracao deve ser antes ou depois da estabilizacao da #82.

Entregavel esperado:
Veredito arquitetural, recomendacao de fases, criterios de aceite e criterios de bloqueio.
```

---

## 10. Recommended next documentation steps

Suggested follow-up PRs:

```text
1. docs(architecture): add LeadOps Edge Function contract candidate
2. docs(security): map Edge Function auth/session patterns
3. docs(observability): define logs/rate-limit/trace requirements for Edge/API paths
4. docs(leadops): define migration plan for proximo_lead and registrar_feedback only after #82 stabilizes
```

Do not implement Edge migration before the contract is approved.
