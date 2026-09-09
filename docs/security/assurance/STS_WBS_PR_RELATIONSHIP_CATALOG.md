# FECH.AI — STS / WBS / PR Relationship Catalog

**Status:** `HUMAN_VIEW / JSON_IS_CANONICAL / DASHBOARD_JOIN_READY`  
**Canonical source:** `docs/security/assurance/STS_WBS_PR_RELATIONSHIP_CATALOG.json`  
**Source main:** `ea46d3d2dc39fc7f700c1d9ad9d747905c317c85`  

## Join contract

```text
WBS Qualified ID
  <-> PROGRAM_TASK_GRAPH Qualified ID
  <-> task_relations[].qualified_id
  <-> pull_request_relations[].primary_qualified_id / related_qualified_ids
  <-> SECURITY_ASSURANCE_CATALOG.entries[].parent_qualified_id
```

## System relationship

| Layer | Canonical source | Role | Must not be treated as |
|---|---|---|---|
| SFJM protocol | `wagnerjfjunior/StopJuniorMode` | continuity research/protocol/governance | FECH.AI product authority |
| FECH.AI SFJM | `docs/sfjm/*` | durable material continuity/state/evidence/authorization ledger | live GitHub/Supabase/runtime proof |
| WBS | `docs/roadmap/fechai-security-to-scale-2026-wbs.md` | structural task/program authority | runtime state |
| Task Graph | `docs/sfjm/PROGRAM_TASK_GRAPH.md` | WBS-derived operational/decomposition overlay | independent WBS replacement |
| SFJM Workspace | `wagnerjfjunior/sfjm-workspace` | derived operational visualization product | FECH.AI security/product authority |
| Dashboard | Workspace projection | WBS/state/PR/test/evidence navigation | authorization or Security Go |
| SES | `wagnerjfjunior/Specialist-Engineering-System` | specialist identity/archetype/certification | Product Authority |
| Product Authority | FECH.AI | material decisions, lifecycle authorization, risk acceptance, Security Go | automatic specialist inference |

Dashboard reconstruction order:

```text
FECH.AI live main
→ WBS
→ PROGRAM_TASK_GRAPH
→ CURRENT_STATE / CURRENT_ISSUES
→ NEXT_SAFE_ACTION / AUTHORIZATIONS / EVIDENCE_FRESHNESS
→ PR relationships
→ test/evidence relationships
→ live lifecycle/runtime overlay
```

Current SES mappings material to this program:

| FECH.AI role | Canonical SES specialist |
|---|---|
| `documentation_audit` | SES — Documentation Auditor |
| `architecture` | SES — Software Systems Architect |
| `ux_ui` | SES — UX/UI APP Specialist |
| `backend_data` | SES — Backend & Data Platform Specialist |
| `lead_operations` | SES — Lead Operations & CRM Specialist |
| `application_security` | SES — Application Security Assurance Specialist |

WBS owner domains with no adopted SES mapping must remain project-local/unresolved until routing is explicitly defined. Do not infer a nearby SES specialist.

## Coverage

```text
WBS/STS task records = 46
GitHub pull requests cataloged = 197
PRs without WBS relation = 0
PRs needing manual reconciliation = 0
GitHub issue namespace entries = 12
Security attack domains = 22
```

## Future / active task chain

| Qualified ID | Task | State | Related PR count |
|---|---|---|---:|
| `STS-M3-04` | Redução de DML sensível direto + Integridade Estrutural Multi-Tenant | `ACTIVE_REBASELINE_REQUIRED` | 5 |
| `STS-M3-04-03` | Global Tenant Surface & Relationship Inventory | `DEFINED_NOT_AUTHORIZED` | 1 |
| `STS-M3-04-04` | lista_avaliacoes Tenant-Relationship Hardening | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-04-05` | PME Catalog Tenant-Relationship Hardening | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-04-06` | Remaining Sensitive Direct-DML Adjudication & Remediation | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-04-07` | Tenant-Bound Database Invariant Verification | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-04-08` | Direct-Write / Bypass Call-Site Sweep | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-04-09` | Structural Cross-Tenant Negative Proofs | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-04-10` | Independent AppSec Closure Review | `DEFINED_NOT_AUTHORIZED` | 0 |
| `STS-M3-05` | Fechamento Auth / Admin flows | `PLANNED_NOT_AUTHORIZED` | 3 |
| `STS-M3-06` | Staging / test plan de segurança | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M4-01` | AppShell / Shared Frontend Boundary | `PLANNED_NOT_AUTHORIZED` | 1 |
| `STS-M4-02` | CRM + Funil Core Slice | `PLANNED_NOT_AUTHORIZED` | 1 |
| `STS-M4-03` | LeadOps Execution Slice — Leads / Listas / Distribuição / Discador / Power Message Engine | `PLANNED_NOT_AUTHORIZED` | 20 |
| `STS-M4-04` | MesaCliente Core Slice | `PLANNED_NOT_AUTHORIZED` | 31 |
| `STS-M4-05` | Feature Gateways / API Boundaries | `PLANNED_NOT_AUTHORIZED` | 5 |
| `STS-M4-06` | Core Functional Equivalence & Regression | `PLANNED_NOT_AUTHORIZED` | 54 |
| `STS-M5-00` | Global Security Assurance Coverage Reconciliation | `PLANNED_NOT_AUTHORIZED_EARLY_CATALOG_FOUNDATION` | 1 |
| `STS-M5-01` | Hostile-client suite isolada | `PLANNED_NOT_AUTHORIZED` | 55 |
| `STS-M5-02` | Regressão tenant / role / auth / storage | `PLANNED_NOT_AUTHORIZED` | 58 |
| `STS-M5-03` | Dependency / CVE gate | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M5-04` | Secrets / config / deploy gate | `PLANNED_NOT_AUTHORIZED` | 2 |
| `STS-M5-05` | Observabilidade / rollback / incidente | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M5-06` | Adjudicação de residual risk | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M6-01` | Security Evidence + Final AS-BUILT Package | `PLANNED_NOT_AUTHORIZED` | 34 |
| `STS-M6-02` | Blocker closeout | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M6-03` | Onboarding / support / operational runbooks | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M6-04` | Decisão comercial controlada | `PLANNED_NOT_AUTHORIZED` | 0 |
| `STS-M6-05` | Launch readiness + AS-BUILT acceptance review | `PLANNED_NOT_AUTHORIZED` | 0 |

## Pull requests

| PR | Title | Primary STS/WBS relation | Related STS | Mapping quality |
|---:|---|---|---|---|
| #2 | Release: Root Control Plane e Tenant Provisioning | `STS-M3-05` | `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #3 | feat(mesa): foundation do layout engine documental | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #4 | Mesa Cliente — Native First Production Release | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #5 | feat: iniciar PME admin shell | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #6 | docs: planejar integração Mesa Cliente com unidades do parser | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #7 | feat: ativar PME Call Assistant Beta no discador | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #8 | feat(mesa-cliente): consolidar engenharia financeira até fase 5B | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #9 | feat(mesa-cliente): fase 5C confirmação e cancelamento de operação financeira | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #10 | test(mesa-cliente): smoke pós-produção da fase 5C | `STS-M4-04` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #11 | feat(mesa-cliente): fase 5D leitura admin de operações financeiras | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #12 | Fase 6 — Resumos read-only de operação financeira MesaCliente | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #13 | Fase 6 — Smoke pós-produção read-only MesaCliente | `STS-M4-04` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #14 | MesaCliente: Fase 7 aplicação de operação financeira | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #15 | feat(mesa-cliente): importação JSON restrita a admin | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #16 | fix(mesa-cliente): aceitar campos camelCase no JSON admin | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #17 | chore(mesa-cliente): estruturar importação Chateau Jardin fase 8 | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #18 | fix(mesa-cliente): preservar fluxo financeiro do JSON admin | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #19 | fix(mesa-cliente): isolar ajuste financeiro ao JSON admin | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #20 | feat: Discador Flow AI / PME Beta v0.2.5 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #21 | feat: PME AI prompt inline v0.2.6 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #22 | docs: contrato PME Usage Tracking v0.2.7 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #23 | sync: atualizar feature PME v0.2.8 com main atual | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #24 | PME Usage Tracking DB/RLS/RPC v0.2.8 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #25 | MesaCliente: integrar operações financeiras, histórico e 2ª via read-only | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #26 | docs: adicionar dossiê profissional do FECH.AI | `STS-M6-01` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #27 | chore: atualizar branch 20C com main após PR #26 | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #28 | MesaCliente: fechar fase 20C com piloto de agenda canônica | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #29 | MesaCliente: preparar fluxo financeiro canônico shadow 20D | `STS-M4-04` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #30 | security: consolidate Supabase RLS/grants hardening evidence | `STS-M1` | `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #31 | docs(pme): adicionar módulo Empreendimentos Château Jardin lançamento v1 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #32 | docs(pme): contrato técnico do módulo Empreendimentos v1 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #33 | feat(pme): add Empreendimentos flow to call assistant | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #34 | feat(pme): add Empreendimentos addon clean | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #35 | feat(pme): add Empreendimentos inside atendimento flow | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #36 | fix(pme): improve empreendimento message variables and readability | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #37 | CLOSED - invalid hotfix attempt: pme broker profile bind | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #38 | fix(pme): bind corretor profile and force Gmail compose | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #39 | fix(pme): stop empreendimentos DOM loop and restore mobile touch | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #40 | fix(pme): stabilize mobile touch without recreating empreendimento DOM | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #41 | Revert "fix(pme): stabilize mobile touch without recreating empreendimento DOM" | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #42 | docs(skills): formalize GPT skills governance | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #43 | docs(skills): add GPT3 Supabase and GPT4 CI/CD specialists | `STS-M0-02` | `STS-M5-04` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #44 | docs(skills): add GPT5 observability and GPT6 ADS specialists | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #45 | docs(application): add vertical application layer specialists | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #46 | docs(roadmap): add FECH.AI roadmap master v1 | `STS-M0-04` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #47 | docs(product): add LeadOps MVP functional spec v1 | `STS-M4-03` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #48 | docs(audit): add FECH.AI documentation audit v1 | `STS-M0-01` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #49 | docs(audit): add FECH.AI documentation inventory v1 | `STS-M0-01` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #50 | docs(skills): update GPT registry with GPT0-GPT10 | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #51 | docs(audit): add complete documentation tree inventory | `STS-M0-01` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #52 | docs(audit): add MesaCliente documentation inventory v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #53 | docs(audit): add MesaCliente code AS-IS inventory v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #54 | docs(audit): add MesaCliente Supabase AS-IS inventory v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #55 | docs(audit): add MesaCliente Supabase real read-only inventory v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #56 | docs(audit): add MesaCliente Supabase risk matrix v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #57 | docs(audit): add MesaCliente RPC P0 body review v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #58 | docs(audit): add MesaCliente negative tests plan v1 | `STS-M4-04` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #59 | docs(audit): add MesaCliente negative tests harness spec v1 | `STS-M4-04` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #60 | docs(audit): add MesaCliente negative tests execution evidence template v1 | `STS-M4-04` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #61 | docs(audit): clean PR 60 evidence template metadata | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #62 | docs(audit): add MesaCliente RPC grant review proposal v1 | `STS-M4-04` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #63 | fix(supabase): harden aprovar_rejeitar_mesa execute grants | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #64 | security(supabase): document and version RLS grants hardening phase 1 | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #65 | security(supabase): document and version RLS grants hardening phase 1 | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #66 | docs(security): record phase 1 post-merge checkpoint | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #67 | docs: add P1 inventory checkpoint | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #68 | docs(security): map frontend direct DML P1 | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #69 | docs(security): map P1 RPC grants inventory | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #70 | docs(security): review P1 RPC function bodies | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #71 | docs(security): add P1 Supabase reconciliation runbook | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #72 | docs(security): record P1 Supabase live reconciliation results | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #73 | docs(security): plan criar_empresa_root P0 hardening | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #74 | docs(security): add criar_empresa_root body review | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #75 | fix(supabase): harden criar_empresa_root execute grants | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #76 | docs(security): record criar_empresa_root live hardening apply | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #77 | docs(bootstrap): add FECH.AI SaaS current state index | `STS-M0-01` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #78 | docs(mvp): add M1 LeadOps reconciliation pass 1 | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #79 | docs(mvp): add M1 LeadOps UI RPC mapping runbook | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #80 | docs(mvp): add M1 LeadOps reconciliation pass 1 | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #81 | docs(mvp): consolidate M1 LeadOps UI RPC evidence map | `STS-M1` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #82 | fix(m1): fail closed LeadOps service bridge without session | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #83 | docs(architecture): map Edge Functions and SaaS security layers | `STS-M4-05` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #84 | docs(architecture): map Edge Functions and SaaS security layering | `STS-M4-05` | `STS-M4-06`, `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #85 | docs(architecture): add Edge Functions context and index | `STS-M4-05` | `STS-M4-06` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #86 | docs(bootstrap): add FECH.AI specialist modus operandi | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #87 | docs(readme): point to bootstrap and architecture indexes | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #88 | docs(bootstrap): add Codex efficiency and GreenOps workflow | `STS-M0-02` | `STS-M5-04` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #89 | docs(skills): align GPT specialists with modus operandi | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #90 | docs(skills): align remaining GPT specialists with modus operandi | `STS-M0-02` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #91 | docs(bootstrap): register governance cycle handoff | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #92 | docs(governance): add project governance dashboard baseline v1 | `STS-M0-04` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #93 | docs(governance): add B0 operational activity register | `STS-M0-01` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #94 | docs(m1): add F1-01 acceptance evidence map | `STS-M1` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #95 | docs(sfjm): add FECH.AI operational continuity layer v1 | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #96 | docs(sfjm): reconcile state after PR 95 merge | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #97 | docs(sfjm): close PR 96 continuity cycle | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #98 | docs(sfjm): reconcile F1-01 state after PR 94 merge | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #99 | docs(sfjm): reconcile state after PR 98 merge | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #100 | docs(sfjm): close PR99 cycle and prevent recursive reconciliation | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #101 | docs(security): establish F1-02 remediation program | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #102 | docs(security): adopt controlled beta primary remediation strategy | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #103 | security: add narrow password-state RPC | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #104 | security: add bounded GPT3 Supabase catalog gateway | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #105 | docs(sfjm): close PR104 live gateway cycle | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #106 | docs(sfjm): close PR103 operational cycle | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #107 | docs(security): record PR103 authenticated smoke | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #108 | security: route password completion through RPC | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #109 | docs(sfjm): reconcile PR107 post-merge continuity | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #110 | docs(sfjm): add builders continuity handoff | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #111 | docs(skills): reconcile canonical Builder parity group A | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #112 | docs(sfjm): reconcile PR108 after builders closure | `STS-M0-03` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #113 | docs(skills): reconcile GPT5 SRE operating contract | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #114 | docs(gpt5): close Builder reconciliation | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #115 | docs(gpt6): publish Builder reconciliation contract | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #116 | docs(gpt6): close Builder reconciliation | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #117 | docs(sfjm): separate live lifecycle from material continuity | `STS-M0-03` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #118 | docs(gpt1.5): reconcile deep architecture specialist | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #119 | docs(gpt1.5): remediate post-merge review findings | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #120 | chore(security): version criar-usuario production v16 | `STS-M3-05` | `STS-M5-02`, `STS-M5-01` | `DOMAIN_SEMANTIC` |
| #121 | fix(gpt0): reconcile FECH.AI response ordering with readiness gates | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #122 | Route adopted FECH.AI specialist roles through SES Gateway | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #123 | docs: record A1/A2 architecture evidence baseline | `STS-M4-05` | `STS-M4-06`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #124 | docs: close PR-03 predicate #3 inventory evidence | `STS-M1` | `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #125 | security: harden corretor status command | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #126 | fix(security): align T1 admin_local authority with live state | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #127 | security: require Edge proof for administrative password reset | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #128 | fix(security): align T3A audit boundary with live schema | `STS-M1` | `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #129 | fix(security): remove T3A PL/pgSQL role alias collision | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #130 | fix(security): refresh T3A live routine inventory anchor | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #131 | docs(sfjm): reconcile T3A production runtime state | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #132 | docs(architecture): preserve transition Mermaid diagrams | `STS-M1` |  | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #134 | fix(security): harden G1E0-A1 team creation authority boundary | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #136 | fix(security): correct G1E0-A1 catalog-derived postflight fingerprints | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #137 | docs: align FECH.AI specialist routing with current SES portfolio | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #138 | fix(security): restore proven G1E0-A1 index catalog fingerprint | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #139 | fix(security): G1E0-A2.1 user creation membership boundary | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `HISTORICAL_PRE_WBS_DOMAIN_MAPPING` |
| #140 | docs: add read-only Supabase Action for SES Backend audits | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #149 | docs(sfjm): reconcile Security-to-Scale M0 continuity | `STS-M0-03` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #151 | docs(sfjm): transition Security-to-Scale from M0 to M1 | `STS-M0-04` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #152 | fix(security): enforce same-tenant relationship integrity | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #153 | docs(sfjm): close APPSEC-M1-003 public.leads continuity | `STS-M1` |  | `EXACT_PROGRAM_CONTEXT` |
| #154 | docs(sfjm): close M1 security truth baseline | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #155 | fix(security): enforce funil tenant relationship integrity | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #156 | fix(security): preserve B1 evidence and retire exact invalid movement | `STS-M1` | `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `EXACT_PROGRAM_CONTEXT` |
| #157 | security: revoke direct funnel history insert | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #158 | docs(sfjm): record F1-02 B3 remediation closure | `STS-M1` | `STS-M6-01` | `EXACT_PROGRAM_CONTEXT` |
| #159 | docs(security): add F1-02 B2 PR-04 call-site contract map | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #160 | docs(sfjm): reconcile F1-02 B2 post-application state | `STS-M1` |  | `EXACT_PROGRAM_CONTEXT` |
| #161 | docs: adopt SES Lead Operations specialist in FECH.AI | `STS-M1` |  | `EXACT_PROGRAM_CONTEXT` |
| #162 | security: enforce tenant-safe list visibility | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #163 | security: harden funnel reads and CRM payloads | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #164 | docs(sfjm): reconcile PR-07 execution state | `STS-M1` |  | `EXACT_PROGRAM_CONTEXT` |
| #165 | docs(security): record J3 bounded residual exception | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #166 | test(security): add F1-02 negative test matrix | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #167 | docs(sfjm): reconcile PR-166 post-merge deployment | `STS-M1` |  | `EXACT_PROGRAM_CONTEXT` |
| #168 | docs(security): record F1-02 gate decision | `STS-M1` | `STS-M5-01`, `STS-M5-02` | `EXACT_PROGRAM_CONTEXT` |
| #169 | docs(sfjm): reconcile M1 close-out handoff | `STS-M1` | `STS-M6-01` | `EXACT_PROGRAM_CONTEXT` |
| #170 | docs(governance): adjudicate Security-to-Scale execution baseline | `STS-M2-01` | `STS-M4-01`, `STS-M4-02`, `STS-M4-03`, `STS-M4-04`, `STS-M4-05`, `STS-M4-06`, `STS-M5-01`, `STS-M5-02` | `EXACT_EXPLICIT` |
| #171 | docs(sfjm): reconcile PR #170 post-merge state | `STS-M2-01` |  | `EXACT_EXPLICIT` |
| #172 | docs(sfjm): record STS-M2-01 acceptance | `STS-M2-01` | `STS-M2-02` | `EXACT_EXPLICIT` |
| #173 | docs(sfjm): record STS-M2-01 acceptance | `STS-M2-01` | `STS-M2-02` | `EXACT_EXPLICIT` |
| #174 | docs(sfjm): record STS-M2-01 acceptance | `STS-M2-01` | `STS-M2-02` | `EXACT_EXPLICIT` |
| #175 | docs(m2): anchor STS-M2-01 matrix and evidence provenance | `STS-M2-01` | `STS-M2-02`, `STS-M6-01` | `EXACT_EXPLICIT` |
| #176 | docs(m2): record STS-M2-02 acceptance with residuals | `STS-M2-02` | `STS-M2-03`, `STS-M2-04` | `EXACT_EXPLICIT` |
| #177 | docs(m2): record STS-M2-02 authority map acceptance | `STS-M2-02` | `STS-M2-03`, `STS-M2-04` | `EXACT_EXPLICIT` |
| #178 | docs(m2): record STS-M2-03 acceptance | `STS-M2-03` | `STS-M2-04` | `EXACT_EXPLICIT` |
| #179 | fix: use canonical SES specialist names in manual handoffs | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #180 | fix: prevent SES recertification detour from blocking FECH.AI | `STS-M0-02` |  | `DOMAIN_SEMANTIC` |
| #181 | docs: record STS-M2-04B1 target-policy acceptance | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #182 | docs: record STS-M2-04B2 high-risk routine classification acceptance | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #183 | docs: record STS-M2-04B3 classification acceptance | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #184 | docs: reconcile STS-M2-04B3 post-merge continuity | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #185 | docs: record PR 183 merge ratification exception | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #186 | docs: start STS-M2-04C continuity | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #187 | docs: reconcile STS-M2-04D trigger authority acceptance | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #188 | docs: accept STS-M2-04E target authority synthesis | `STS-M2-04` | `STS-M6-01` | `EXACT_EXPLICIT` |
| #189 | docs: reconcile STS-M2-04E architecture acceptance | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #190 | docs: reconcile PR #189 post-merge SFJM state | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #191 | docs: harden M1/M2 evidence provenance | `STS-M2-04` | `STS-M6-01` | `EXACT_PROGRAM_CONTEXT` |
| #192 | docs: record B2 target-contract closure result | `STS-M2-04` | `STS-M6-01` | `EXACT_EXPLICIT` |
| #193 | docs: accept final STS-M2-04 closure | `STS-M2-04` | `STS-M6-01` | `EXACT_EXPLICIT` |
| #194 | docs: publish SFJM program task graph | `STS-M2-04` |  | `EXACT_EXPLICIT` |
| #195 | docs: publish accepted STS-M2-05 database contract map | `STS-M2-05` |  | `EXACT_EXPLICIT` |
| #196 | docs: reconcile M2-05 post-merge SFJM state | `STS-M2-05` |  | `EXACT_PROGRAM_CONTEXT` |
| #197 | docs: authorize STS-M2-06 and normalize STS task identities | `STS-M2-06` | `STS-M2-05` | `EXACT_EXPLICIT` |
| #198 | docs: classify current blockers risks and gates | `STS-M2-06` | `STS-M2-05`, `STS-M2-04` | `EXACT_EXPLICIT` |
| #199 | docs: reconcile STS-M2-06 task graph state | `STS-M2-06` | `STS-M2-05` | `EXACT_EXPLICIT` |
| #200 | docs: publish accepted STS-M2-06 architecture decision | `STS-M2-06` |  | `EXACT_EXPLICIT` |
| #201 | docs: publish accepted STS-M3-01 authority contract | `STS-M3-01` | `STS-M3-02` | `EXACT_EXPLICIT` |
| #202 | docs: publish accepted STS-M3-02 authority contract by context | `STS-M3-02` | `STS-M3-01`, `STS-M3-03` | `EXACT_EXPLICIT` |
| #203 | docs: reconcile PR #202 post-merge SFJM state | `STS-M3-03` | `STS-M5-01`, `STS-M5-02` | `EXACT_EXPLICIT` |
| #204 | docs: accept STS-M3-03 and authorize STS-M3-04 | `STS-M3-03` | `STS-M3-04`, `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `EXACT_EXPLICIT` |
| #205 | security: STS-M3-04-01 make PME usage writes RPC-only | `STS-M3-04-01` | `STS-M3-04`, `STS-M5-02`, `STS-M5-01` | `EXACT_EXPLICIT` |
| #206 | docs: accept STS-M3-04-01 with residuals | `STS-M3-04-01` | `STS-M3-04`, `STS-M5-02`, `STS-M6-01` | `EXACT_EXPLICIT` |
| #207 | security: reduce PME lead message state direct writes | `STS-M3-04-02` | `STS-M3-04`, `STS-M5-02`, `STS-M5-01` | `EXACT_EXPLICIT` |
| #208 | docs: accept STS-M3-04-02 with residuals | `STS-M3-04-02` | `STS-M3-04`, `STS-M3-04-03`, `STS-M3-05`, `STS-M5-02`, `STS-M6-01` | `EXACT_EXPLICIT` |
| #209 | docs: catalog STS security assurance artifacts | `STS-M5-00` | `STS-M5-01`, `STS-M5-02`, `STS-M6-01` | `EXPLICIT_CURRENT_SCOPE` |

## Shared Issue / PR number namespace

The following numbers are Issues, not missing PRs:

| Number | Issue | Primary STS relation | State |
|---:|---|---|---|
| #1 | Hardening Edge Function criar-usuario: migrar para verify_jwt=true | `STS-M3-05` | `open` |
| #133 | Root/Admin Global Authority Contract — eliminate role overlaps | `STS-M3-05` | `open` |
| #135 | G1E0-A2 — Team Lifecycle Authority | `STS-M3-05` | `open` |
| #141 | PROGRAM: FECH.AI Security-to-Scale 2026 | `PROGRAM` | `open` |
| #142 | M0: Reconcile FECH.AI truth, open PRs and evidence classes | `STS-M0-01` | `closed` |
| #143 | M1-BD: LIVE database baseline + privileged surface + GitHub parity | `STS-M1` | `open` |
| #144 | M1-AS: Application Security baseline and Security Go proof obligations | `STS-M1` | `open` |
| #145 | M2-ARCH: Database simplification target + modular backend decision | `STS-M2-06` | `open` |
| #146 | M3-PLATFORM: Staging, CI/CD and production safety gates | `STS-M3-06` | `open` |
| #147 | M4-FRONT: App.jsx decomposition and frontend modularization plan | `STS-M4-01` | `open` |
| #148 | M5-SRE: Observability, incident readiness and Security Go operations | `STS-M5-05` | `open` |
| #150 | M1: Security Truth Baseline | `STS-M1` | `closed` |

## Semantics

```text
HISTORICAL_CONTRIBUTION_TO_CURRENT_WBS
!= historical PR originally executed under the later WBS identity

PR MERGED != TASK COMPLETE
TASK COMPLETE != SECURITY PASS
TEST VERSIONED != TEST EXECUTED
CATALOGED != SECURITY GO
```


## 2026-09-09 WBS security-audit amendment

New structural nodes:
- `STS-M3-04-11` — Default Privilege Fail-Closed Hardening
- `STS-M3-04-12` — M3-04 Zero-Residual Closure Gate
- `STS-M3-06-01..04` — staging / proxy / service-boundary / negative-test decomposition
- `STS-M3-07` with `STS-M3-07-01..06` — privileged RPC/object-authority remediation
- `STS-M5-07` — Independent Re-Audit Against All Canonical Security Findings
- `STS-M6-06` — Independent Final Security Go Candidate Review

Final-security contract: actionable findings cannot terminate as `ACCEPTED_WITH_RESIDUALS` at M3, M5, M6 or Security Go candidacy.

Machine authority remains the JSON relationship catalog. PR #210 is explicitly related to `STS-M3-04-03` and the downstream M3/M5/M6 closure nodes. Because the catalog lives inside the same open PR, its `head_sha` is deliberately `RESOLVE_LIVE`; exact-head lifecycle evidence must be resolved from GitHub rather than self-embedded recursively.
