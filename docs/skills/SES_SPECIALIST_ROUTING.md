# FECH.AI — SES Specialist Routing

**Status:** `CANONICAL_V0_1 / SES_RUNTIME_GATEWAY_ROUTING`
**SES repository:** `wagnerjfjunior/Specialist-Engineering-System`

## Purpose

Define which FECH.AI project roles are currently routed through certified SES specialists. This file does not copy SES specialist instructions and does not replace FECH.AI project truth, authority, continuity or local rules.

For every mapped role, resolve SES `main` live before material work and use the SES Project Registry, FECH.AI Project Adapter, Runtime Enforcement Gateway contract, Archetype Registry and current certification ledger.

## Current adopted roles

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

application_security
→ application-security-assurance-specialist
→ local rules: resolve FECH.AI security/project rules through bootstrap; no dedicated project-local override is declared here
```

## Routing precedence

For the roles above, the SES `ARCHETYPE_ID` is the current reusable specialist identity. Historical FECH.AI labels such as `GPT0`, `GPT1`, `GPT1.5`, `GPT2` and `GPT3` remain continuity/project-local skill references only and must not override the adopted SES archetype.

```text
CURRENT ROLE ROUTING
> legacy GPT identity routing
```

Historical evidence remains historical; do not rewrite old records.

For FECH.AI specialist domains not mapped above, continue using `docs/skills/fechai-gpt-registry.md` and existing project-local routing until a certified SES archetype is explicitly adopted.

Do not infer a replacement for GPT4/GPT5 or any other local specialist merely because a related SES archetype may exist later.

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
→ ROUTABLE / fail closed
→ resolve FECH.AI main live
→ FECH.AI bootstrap
→ mapped local rules when applicable
→ continuity / authority / task evidence
→ Context Readiness
→ specialist work
```

`ROUTABLE` is not execution proof and does not grant mutation authority.

## Fail closed

Use bounded blockers when applicable:

```text
PROJECT_NOT_REGISTERED
SPECIALIST_ROLE_NOT_ADOPTED
ARCHETYPE_NOT_RESOLVED
ARCHETYPE_NOT_ACTIVE
SPECIALIST_NOT_CERTIFIED
RUNTIME_FINGERPRINT_STALE_OR_UNSUPPORTED
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
