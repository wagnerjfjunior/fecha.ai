# FECH.AI — SES Specialist Routing

**Status:** `CANONICAL_V0_2 / SES_SPECIALIST_ROUTING / CURRENT_MANUAL_HANDOFF_COMPATIBLE`
**SES repository:** `wagnerjfjunior/Specialist-Engineering-System`

## Purpose

Define which FECH.AI project roles are currently routed through certified SES specialists. This file does not copy SES specialist instructions and does not replace FECH.AI project truth, authority, continuity or local rules.

For every mapped role, resolve SES `main` live before material work and use the SES Project Registry, FECH.AI Project Adapter, Archetype Registry, current certification ledger and the current SES specialist-handoff contract when consultation transport is material. Do not infer current Gateway/Router operational acceptance from historical evidence.

## Current adopted roles

The current SES adoption matrix and FECH.AI Project Adapter record these eleven adopted roles:

```text
documentation_audit
→ documentation-auditor
→ local rules: docs/skills/fechai-gpt0-documentation-auditor.md

architecture
→ software-systems-architect
→ local rules: docs/skills/fechai-gpt1-architect-saas.md

ux_ui
→ ux-ui-app-specialist
→ local rules: docs/skills/fechai-gpt2-ux-ui-app-specialist.md

backend_data
→ backend-data-platform-specialist
→ local rules: docs/skills/fechai-gpt3-supabase-security-specialist.md
→ live database audit tool binding: docs/integrations/ses-backend-supabase-readonly-action.openapi.yaml
→ setup/credential contract: docs/integrations/SES_BACKEND_SUPABASE_ACTION_SETUP.md

lead_operations
→ lead-operations-crm-specialist
→ local rules: docs/skills/fechai-gpt7-leadops-crm-discador.md
→ legacy continuity: GPT7 / FECH.AI LeadOps CRM Discador Specialist

application_security
→ application-security-assurance-specialist
→ local rules: resolve FECH.AI security/project rules through bootstrap; no dedicated project-local override is declared here

seo_strategy
→ seo-strategy-governance-specialist
→ local rules: resolve FECH.AI search/product/commercial rules through bootstrap and current project sources

technical_seo
→ technical-seo-specialist
→ local rules: resolve FECH.AI technical/search implementation truth through bootstrap and current project sources

content_semantic_seo
→ content-semantic-seo-specialist
→ local rules: resolve FECH.AI content, brand, product, commercial, legal and factual truth through bootstrap and current project sources

seo_analytics_growth
→ seo-analytics-growth-specialist
→ local rules: resolve FECH.AI KPIs, conversion definitions, analytics properties, consent/privacy/legal rules and business-value truth through bootstrap and current project sources

paid_search_sem
→ paid-search-sem-specialist
→ local rules: resolve FECH.AI ad accounts, budgets, billing, conversion definitions, tracking/consent/privacy/legal rules, campaign targets and spend/publication authority through bootstrap and current project sources
```

`backend_data` remains adopted in FECH.AI. Local SEO and Authority & Digital PR are not added here while they remain SES TARGET / certification pending and not yet eligible for explicit adoption.

## Routing precedence

For the roles above, the SES `ARCHETYPE_ID` is the current reusable specialist identity. Historical FECH.AI labels such as `GPT0`, `GPT1`, `GPT1.5`, `GPT2`, `GPT3` and `GPT7` remain continuity/project-local skill references only and must not override the adopted SES archetype.

```text
CURRENT ROLE ROUTING
> legacy GPT identity routing
```

Historical evidence remains historical; do not rewrite old records.

For FECH.AI specialist domains not mapped above, continue using `docs/skills/fechai-gpt-registry.md` and existing project-local routing until a certified SES archetype is explicitly adopted. The legacy registry is not the routing authority for any role listed above.

Do not infer a replacement for GPT4/GPT5 or any other local specialist merely because a related SES archetype may exist later.

## Backend live-database admission rule

For `backend_data`, a request that requires current Supabase/database state must not silently degrade into repository-only analysis.

```text
LIVE_DATABASE_AUDIT
→ require FECH.AI project-local Supabase live-read Action
→ run capability preflight
→ if usable: execute live audit
→ if unavailable/error: BLOCK live audit and offer STATIC_REPOSITORY_DATABASE_AUDIT only as an explicit fallback
```

`STATIC_REPOSITORY_DATABASE_AUDIT != LIVE_DATABASE_AUDIT`.

The bearer token/PAT is Builder-secret configuration and must never be committed to this repository.

## Runtime flow

```text
explicit project = FECH.AI
+ explicit mapped role
→ resolve SES main live
→ SES projects/REGISTRY.md
→ projects/fechai/PROJECT_ADAPTER.md
→ exact ROLE -> ARCHETYPE_ID
→ SES archetypes/REGISTRY.md
→ current certification eligibility
→ resolve current SES handoff/transport semantics when consultation is required
→ resolve FECH.AI main live
→ FECH.AI bootstrap
→ mapped local rules when applicable
→ continuity / authority / task evidence
→ Context Readiness
→ specialist work
```

`SPECIALIST_AVAILABLE`, `ADOPTED` and a prepared handoff are not execution proof and do not grant mutation authority.

## Fail closed

Use bounded blockers when applicable:

```text
PROJECT_NOT_REGISTERED
SPECIALIST_ROLE_NOT_ADOPTED
ARCHETYPE_NOT_RESOLVED
ARCHETYPE_NOT_ACTIVE
SPECIALIST_NOT_CERTIFIED
SPECIALIST_RUNTIME_OR_TRANSPORT_UNAVAILABLE
PROJECT_BOOTSTRAP_UNRESOLVED
```

No fuzzy specialist selection. No automatic project adoption. No automatic specialist upgrade that changes the adopted archetype identity.

## Authority

```text
SES SPECIALIST METHOD != FECH.AI PROJECT TRUTH
ADOPTED != PROJECT_CONTEXT_READY
PROJECT_CONTEXT_READY != AUTHORIZED_TO_MUTATE
```

FECH.AI remains authoritative for its product state, business rules, environments, project-local skills, continuity, release decisions and risk acceptance.
