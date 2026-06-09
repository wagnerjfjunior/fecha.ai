# FECH.AI — SaaS Multi-Tenant Current State Index

**Date:** 2026-06-10  
**Status:** BOOTSTRAP_INDEX / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Scope:** canonical onboarding index for FECH.AI technical conversations, reviews, PRs, Codex tasks and handoffs.  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base branch observed:** `main`  
**Base commit observed:** `2728b58174eeb6843454a18f3057fa6a15b3be11`  

---

## 1. Purpose

This document is the canonical bootstrap index for understanding FECH.AI as a SaaS platform.

It exists to prevent every new conversation, AI session, Codex task or technical review from restarting as if the project were new.

FECH.AI must be treated as:

```text
SaaS multi-tenant / multi-company in advanced construction,
with existing PR history, documented security tracks,
AS-IS inventories, Supabase/RLS/RPC evidence,
MesaCliente, LeadOps/CRM/Discador, PME and governance documentation.
```

This file is documentation-only. It does not change application code, Supabase, migrations, RLS, RPCs, grants, policies, Vercel, GitHub Actions, MesaCliente runtime, parser, financial engine, Worker, Make/n8n, tracking, integrations or production behavior.

---

## 2. Mandatory bootstrap rule

Before proposing code, SQL, migration, RPC, frontend patch, Supabase change, hardening, MesaCliente change, LeadOps change, CI/CD change or production action, read this index and then follow the official protocol.

Mandatory first references:

```text
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/02-arquitetura-tecnica/arquitetura-atual.md
docs/03-infraestrutura-cloud/topologia-cloud.md
docs/05-observabilidade-ha/observabilidade-non-stop.md
docs/product/fechai-mvp-scope-v1.md
docs/product/fechai-modules-map-v1.md
docs/roadmap/fechai-roadmap-master-v1.md
```

Mandatory recent evidence references:

```text
docs/security/evidence/2026-06-07_authenticated_write_surface_p1_inventory.md
docs/security/evidence/2026-06-09_frontend_direct_dml_p1_inventory.md
docs/security/evidence/2026-06-09_rpc_grants_inventory_p1.md
docs/security/evidence/2026-06-09_rpc_body_review_p1.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_runbook.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
docs/security/evidence/2026-06-09_criar_empresa_root_execute_hardening_live_apply.md
```

Mandatory AS-IS references:

```text
docs/audits/documentation/2026-06-03-documentation-tree-inventory-v1.md
docs/audits/documentation/2026-06-03-mesacliente-docs-inventory-v1.md
docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md
docs/audits/supabase/2026-06-03-mesacliente-supabase-as-is-v1.md
docs/audits/supabase/2026-06-03-mesacliente-supabase-real-inventory-v1.md
docs/audits/supabase/2026-06-04-mesacliente-supabase-risk-matrix-v1.md
docs/audits/supabase/2026-06-04-mesacliente-rpc-p0-body-review-v1.md
docs/audits/supabase/2026-06-04-mesacliente-negative-tests-plan-v1.md
docs/audits/supabase/2026-06-05-mesacliente-negative-tests-harness-spec-v1.md
docs/audits/supabase/2026-06-05-mesacliente-negative-tests-execution-evidence-v1.md
docs/audits/supabase/2026-06-05-mesacliente-rpc-grant-review-proposal-v1.md
```

---

## 3. Official protocol summary

Official protocol:

```text
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
```

Core rule:

```text
First contract. Then evidence. Then dry-run. Then rollback test. Then controlled persistence.
```

Operational lock phrase:

```text
NOT CONFIRMED. Do not turn this into definitive code without validation.
```

Truth hierarchy:

```text
1. Real applied Supabase database
2. GitHub on the correct branch
3. Official versioned documentation
4. Direct information from Wagner
5. Declared technical inference
6. Memory / previous conversation
```

Mandatory separation in technical answers:

```text
Verified with evidence
Informed by Wagner
Inferred
Not confirmed
Out of scope
Next single safe step
```

---

## 4. Product identity

FECH.AI is not a simple CRM prototype.

It is a SaaS platform for real-estate operations, with the following major domains:

```text
Root Control Plane / Tenant Provisioning
LeadOps / CRM / Discador
Power Message Engine / Discador Flow AI
MesaCliente / Tabelas / Propostas
Supabase Security / RLS / RPCs / Grants
Integrations / Messaging / Tracking / ADS-CAPI
Observability / HA / Operations
Monetization / GTM / Startup Governance
```

The active architecture principle is:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists, but is not authority.
```

The frontend is not sovereign for:

```text
tenant
company
profile
permission
financial rule
proposal access
commercial ownership
client-safe visibility
internal policy
sensitive data
```

---

## 5. Major PR history by domain

This is a navigational summary, not a substitute for reading the PR and files.

### 5.1 SaaS foundation / Root / Tenant Provisioning

```text
PR #2 — Release: Root Control Plane e Tenant Provisioning
```

Purpose:

```text
Root panel
companies / tenants
local admins
billing readiness
tenant provisioning engine
tenant lifecycle actions
plan/trial readiness
```

### 5.2 MesaCliente / Parser / Financial Engineering

```text
PR #3  — feat(mesa): foundation do layout engine documental
PR #4  — Mesa Cliente — Native First Production Release
PR #6  — docs: planejar integração Mesa Cliente com unidades do parser
PR #8  — feat(mesa-cliente): consolidar engenharia financeira até fase 5B
PR #9  — feat(mesa-cliente): fase 5C confirmação e cancelamento de operação financeira
PR #10 — test(mesa-cliente): smoke pós-produção da fase 5C
PR #11 — feat(mesa-cliente): fase 5D leitura admin de operações financeiras
PR #12 — Fase 6 — Resumos read-only de operação financeira MesaCliente
PR #13 — Fase 6 — Smoke pós-produção read-only MesaCliente
PR #14 — MesaCliente: Fase 7 aplicação de operação financeira
PR #15 — feat(mesa-cliente): importação JSON restrita a admin
PR #16 — fix(mesa-cliente): aceitar campos camelCase no JSON admin
PR #17 — chore(mesa-cliente): estruturar importação Chateau Jardin fase 8
PR #18 — fix(mesa-cliente): preservar fluxo financeiro do JSON admin
PR #19 — fix(mesa-cliente): isolar ajuste financeiro ao JSON admin
PR #25 — MesaCliente: integrar operações financeiras, histórico e 2ª via read-only
PR #28 — MesaCliente: fechar fase 20C com piloto de agenda canônica
PR #29 — MesaCliente: preparar fluxo financeiro canônico shadow 20D
```

Interpretation:

```text
MesaCliente is a critical R4/R5 domain involving parser, imported commercial tables, financial flow, operations, client-safe read models, history, canonical agenda and shadow canonical flow.
Do not modify MesaCliente casually or mix it with LeadOps/CRM work unless the scope explicitly requires it.
```

### 5.3 PME / Discador / Power Message Engine

```text
PR #5  — feat: iniciar PME admin shell
PR #7  — feat: ativar PME Call Assistant Beta no discador
PR #20 — feat: Discador Flow AI / PME Beta v0.2.5
PR #21 — feat: PME AI prompt inline v0.2.6
PR #22 — docs: contrato PME Usage Tracking v0.2.7
PR #23 — sync: atualizar feature PME v0.2.8 com main atual
PR #24 — PME Usage Tracking DB/RLS/RPC v0.2.8
PR #31 — docs(pme): adicionar módulo Empreendimentos Château Jardin lançamento v1
PR #32 — docs(pme): contrato técnico do módulo Empreendimentos v1
PR #33 — feat(pme): add Empreendimentos flow to call assistant
PR #34 — feat(pme): add Empreendimentos addon clean
PR #35 — feat(pme): add Empreendimentos inside atendimento flow
PR #36 — fix(pme): improve empreendimento message variables and readability
PR #37 — CLOSED - invalid hotfix attempt: pme broker profile bind
PR #38 — fix(pme): bind corretor profile and force Gmail compose
PR #39 — fix(pme): stop empreendimentos DOM loop and restore mobile touch
PR #40 — fix(pme): stabilize mobile touch without recreating empreendimento DOM
PR #41 — Revert "fix(pme): stabilize mobile touch without recreating empreendimento DOM"
```

Interpretation:

```text
PME/Discador has real operational code, documented regressions, clean patch attempts and reverts.
Do not alter App/main or global fetch behavior without explicit scope and regression validation.
```

### 5.4 Documentation / Governance / GPT specialists

```text
PR #26 — docs: adicionar dossiê profissional do FECH.AI
PR #42 — docs(skills): formalize GPT skills governance
PR #43 — docs(skills): add GPT3 Supabase and GPT4 CI/CD specialists
PR #44 — docs(skills): add GPT5 observability and GPT6 ADS specialists
PR #45 — docs(application): add vertical application layer specialists
PR #46 — docs(roadmap): add FECH.AI roadmap master v1
PR #47 — docs(product): add LeadOps MVP functional spec v1
PR #48 — docs(audit): add FECH.AI documentation audit v1
PR #49 — docs(audit): add FECH.AI documentation inventory v1
PR #50 — docs(skills): update GPT registry with GPT0-GPT10
PR #51 — docs(audit): add complete documentation tree inventory
PR #52 — docs(audit): add MesaCliente documentation inventory v1
```

Interpretation:

```text
Documentation is part of the operating system of FECH.AI.
Do not treat docs as optional background.
They define protocol, governance, scope, specialist responsibilities and handoff continuity.
```

### 5.5 AS-IS / Supabase / MesaCliente security discovery

```text
PR #53 — docs(audit): add MesaCliente code AS-IS inventory v1
PR #54 — docs(audit): add MesaCliente Supabase AS-IS inventory v1
PR #55 — docs(audit): add MesaCliente Supabase real read-only inventory v1
PR #56 — docs(audit): add MesaCliente Supabase risk matrix v1
PR #57 — docs(audit): add MesaCliente RPC P0 body review v1
PR #58 — docs(audit): add MesaCliente negative tests plan v1
PR #59 — docs(audit): add MesaCliente negative tests harness spec v1
PR #60 — docs(audit): add MesaCliente negative tests execution evidence template v1
PR #61 — docs(audit): clean PR 60 evidence template metadata
PR #62 — docs(audit): add MesaCliente RPC grant review proposal v1
PR #63 — fix(supabase): harden aprovar_rejeitar_mesa execute grants
```

Interpretation:

```text
The AS-IS and security discovery tracks are mandatory context.
They distinguish repository evidence, live Supabase evidence, body review, grants, anon/PUBLIC exposure, negative test readiness and execution status.
```

### 5.6 Supabase/RLS/RPC/grants hardening phase 1 and P1/P0 track

```text
PR #64 — security(supabase): document and version RLS grants hardening phase 1 — closed without merge
PR #65 — security(supabase): document and version RLS grants hardening phase 1 — merged clean replacement
PR #66 — docs(security): record phase 1 post-merge checkpoint
PR #67 — docs: add P1 inventory checkpoint
PR #68 — docs(security): map frontend direct DML P1
PR #69 — docs(security): map P1 RPC grants inventory
PR #70 — docs(security): review P1 RPC function bodies
PR #71 — docs(security): add P1 Supabase reconciliation runbook
PR #72 — docs(security): record P1 Supabase live reconciliation results
PR #73 — docs(security): plan criar_empresa_root P0 hardening
PR #74 — docs(security): add criar_empresa_root body review
PR #75 — fix(supabase): harden criar_empresa_root execute grants
PR #76 — docs(security): record criar_empresa_root live hardening apply
```

Interpretation:

```text
The security track is advanced and recent.
Do not restart security mapping from zero.
Use these PRs and evidence files as the guardrail for future SaaS work.
```

---

## 6. Key current security facts from recent evidence

Use the evidence files for exact details. Summary:

```text
P1 surfaces were inventoried.
Frontend direct DML was mapped.
Most LeadOps/CRM writes appear RPC-driven.
A direct App.jsx -> sb.patch("corretores", ...) path was identified and should remain a review item.
P1 RPC/function paths were inventoried and reconciled live.
criar_empresa_root was narrowed through PR #75 and live evidence was recorded in PR #76.
```

Do not claim the entire platform is production-secure based only on these facts.

Correct claim:

```text
FECH.AI has a mature security evidence and hardening track that must be used as the baseline for future work.
```

Incorrect claim:

```text
The whole platform is fully secure and production-approved.
```

---

## 7. Current SaaS operating model

FECH.AI should be understood as:

```text
Managed cloud SaaS
GitHub for source, PRs, governance and evidence
Vercel for frontend deploy, preview and rollback
Supabase for Auth, PostgreSQL, RLS, RPCs and logs
OpenAI/ChatGPT for assistive intelligence, not authority
Future integrations for WhatsApp/WABA, e-mail, Meta, Google and portals
```

Minimum operational requirements:

```text
multi-tenant isolation
multi-company governance
RLS enabled on multi-tenant tables
RPCs for sensitive write paths
auth.uid() / active user / tenant-company / role validation
no service_role in frontend
no anon EXECUTE on sensitive RPCs
observability for uptime, frontend errors, Supabase/RPC errors, deploy failures and costs
rollback for Vercel/frontend changes
migration rollback/corrective plan for Supabase changes
incident runbook
backup/restore plan and RTO/RPO awareness
```

---

## 8. What not to do in new conversations

```text
Do not treat FECH.AI as a blank project.
Do not propose a generic MVP before reading AS-IS and protocol.
Do not ignore PR history.
Do not modify MesaCliente unless explicitly in scope.
Do not modify parser, financial engine, Worker, Make/n8n or frontend critical paths casually.
Do not create migrations without checking GitHub x Supabase drift.
Do not assume a table, column, RPC, grant, policy or function exists.
Do not rely on memory as primary truth.
Do not mix M1 LeadOps, M2 ADS/CAPI, M3 MesaCliente and security hardening in one uncontrolled PR.
Do not claim production safety without live evidence and tests.
```

---

## 9. Suggested answer format for future technical sessions

Any technical answer should start with:

```text
Resumo objetivo
O que esta verificado com evidencia
O que foi informado pelo Wagner
O que e inferencia
O que nao esta confirmado
Fase/frente ativa
Escopo permitido
Fora de escopo
Risco e classificacao
Arquivos/tabelas/RPCs afetados
Matriz DML, se aplicavel
Plano de teste
Criterio de aceite
Criterio de bloqueio
Proximo passo unico
```

---

## 10. Bootstrap by active front

### If the front is SaaS foundation / tenant provisioning

Read first:

```text
PR #2
docs/02-arquitetura-tecnica/arquitetura-atual.md
docs/03-infraestrutura-cloud/topologia-cloud.md
docs/security/evidence/2026-06-09_criar_empresa_root_execute_hardening_live_apply.md
```

### If the front is LeadOps / CRM / Discador

Read first:

```text
docs/product/fechai-mvp-scope-v1.md
docs/product/fechai-modules-map-v1.md
docs/roadmap/fechai-roadmap-master-v1.md
docs/product/leadops-crm-discador/leadops-mvp-functional-spec-v1.md
docs/security/evidence/2026-06-09_frontend_direct_dml_p1_inventory.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
src/App.jsx
src/services/aceleracaoOperacionalService.js
```

### If the front is MesaCliente

Read first:

```text
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md
docs/audits/supabase/2026-06-03-mesacliente-supabase-as-is-v1.md
docs/audits/supabase/2026-06-03-mesacliente-supabase-real-inventory-v1.md
docs/audits/supabase/2026-06-04-mesacliente-supabase-risk-matrix-v1.md
docs/audits/supabase/2026-06-05-mesacliente-rpc-grant-review-proposal-v1.md
```

### If the front is PME / Discador Flow AI

Read first:

```text
PR #20
PR #21
PR #22
PR #24
PR #35
PR #38
PR #41
public/pme-call-assistant-beta.js
public/pme-empreendimentos-inline-flow.js
```

### If the front is Security / Supabase / RLS / RPCs

Read first:

```text
PR #65
PR #66
PR #67
PR #68
PR #69
PR #70
PR #71
PR #72
PR #73
PR #74
PR #75
PR #76
docs/security/SECURITY_AUDIT_2026-05-29.md
docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md
```

### If the front is Observability / HA

Read first:

```text
docs/03-infraestrutura-cloud/topologia-cloud.md
docs/05-observabilidade-ha/observabilidade-non-stop.md
docs/05-observabilidade-ha/runbook-incidentes.md
```

---

## 11. Open reservations

This index is based on repository PR history and known documentation paths.

It does not prove:

```text
latest Supabase live state after this commit
runtime behavior in Vercel preview/production
all GitHub branch statuses
all closed PR review discussions
all tests were executed successfully
complete production readiness
commercial SLA readiness
```

Those must be validated per active front before execution.

---

## 12. Next recommended documentation follow-up

Create or update a shorter root-level pointer so that users and AI sessions discover this file quickly.

Candidate options:

```text
docs/README.md — add "Start here / Bootstrap FECH.AI"
README.md — add short pointer to this bootstrap index
```

Keep this follow-up as a separate documentation-only PR if preferred.
