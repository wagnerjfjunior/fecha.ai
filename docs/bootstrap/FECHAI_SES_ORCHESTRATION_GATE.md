# FECH.AI — Mandatory SES Specialist Orchestration Gate

**Status:** `CANONICAL_V0_1 / MANDATORY_PRE_WORK_GATE / SES_DUAL_TRANSPORT / FAIL_CLOSED`
**Scope:** FECH.AI Project / Master Project and all project-local specialist turns.

## 1. Problem this contract closes

FECH.AI historically exposed legacy specialist identities such as `GPT0`, `GPT1.5`, `GPT2`, `GPT3` and `GPT7`. SES now owns the current adopted specialist identities for mapped roles. The existence of a local skill or Builder does not authorize that legacy specialist to bypass SES routing.

This contract closes the behavioral gap where a legacy FECH.AI specialist can begin substantive work from its own local skill without first resolving the current SES archetype, certification state and consultation transport.

## 2. Mandatory gate

Before any substantive specialist work, the turn MUST determine whether the task maps to an adopted SES role.

```text
TASK
→ ROLE RESOLUTION
→ SES ROLE MAP
→ ARCHETYPE_ID
→ ACTIVE + CERTIFIED
→ CONSULTATION TRANSPORT
→ SPECIALIST TURN
```

No mapped-role specialist may silently execute as a legacy `GPT<number>` identity.

For an adopted SES role:

```text
ROLE ADOPTED
+ ARCHETYPE ACTIVE
+ CURRENT SES CERTIFICATION = YES
→ CONSULTATION REQUIRED BEFORE SUBSTANTIVE WORK
```

`CONSULTATION_REQUIRED` means the specialist cognition must be obtained through the current supported SES transport. It does not mean that a legacy GPT may simulate having consulted another specialist.

## 3. GPT0-specific rule

`GPT0` is a historical/project-local alias for the documentation-audit role. It is NOT the current SES specialist identity.

Current route:

```text
ROLE: documentation_audit
→ ARCHETYPE_ID: documentation-auditor
→ CANONICAL SES TARGET: resolve from SES archetypes/REGISTRY.md
```

Therefore, a GPT0 turn MUST NOT present itself as the final operational authority for a mapped SES consultation when the task requires documentation auditing plus another adopted domain specialist.

GPT0 may perform the project bootstrap and prepare/coordinate the evidence packet, but must route the material domain work through the applicable adopted SES specialist.

## 4. Cross-specialist consultation rule

When a request spans multiple adopted SES roles, the Project must identify every material role before substantive conclusions are emitted.

Example:

```text
security + backend/data + architecture
→ application_security
→ backend_data
→ architecture
```

The order is risk-dependent, but omission is not allowed merely because one legacy GPT can answer the question itself.

At minimum:

```text
Documentation / evidence questions
→ documentation_audit

Architecture questions
→ architecture

Supabase / Auth / RLS / RPC / database questions
→ backend_data

Application security questions
→ application_security

Ads / tracking / analytics / consent / attribution
→ seo_analytics_growth and/or paid_search_sem as applicable

LeadOps / CRM / Discador
→ lead_operations
```

Use `docs/skills/SES_SPECIALIST_ROUTING.md` as the authoritative role map. Do not invent additional roles or infer fuzzy substitutions.

## 5. Transport rule

Current SES consultation transport is dual:

```text
PREFERRED:
PROJECT_LEVEL_@

SUPPORTED FALLBACK:
MANUAL_COPY_PASTE
```

The current SES Router/Gateway is NOT an accepted operational shortcut unless SES later re-adopts it with fresh operational proof.

A Custom GPT must not claim another specialist was called when the runtime did not actually perform that consultation.

If `@` is visibly available in the current ChatGPT Project, use the exact SES `CANONICAL_NAME` for the selected archetype.

If `@` is unavailable, unstable or not usable, generate a manual consultation packet using the current SES Manual Specialist Handoff Contract.

## 6. Blocking behavior

The following are hard stops for mapped-role work:

```text
PROJECT_NOT_REGISTERED
SPECIALIST_ROLE_NOT_ADOPTED
ARCHETYPE_NOT_RESOLVED
ARCHETYPE_NOT_ACTIVE
SPECIALIST_NOT_CERTIFIED
SPECIALIST_RUNTIME_OR_TRANSPORT_UNAVAILABLE
PROJECT_BOOTSTRAP_UNRESOLVED
```

Do not replace these conditions with:

```text
legacy GPT answer
memory
historical specialist label
invented specialist execution
unsupported runtime assumption
```

## 7. No self-approval

Specialist consultation does not authorize the project to mutate anything.

```text
CONSULTED != ADOPTED
ADOPTED != EXECUTED
EXECUTED != AUTHORIZED_TO_MUTATE
SPECIALIST_RESULT != PROJECT_APPROVAL
```

Product Authority remains the project authority for changes, Ready, merge, deploy, production and risk acceptance.

## 8. Required response metadata

For a turn that uses or requires an adopted SES role, report:

```text
PROJECT: FECH.AI
FECH.AI MAIN SHA: <resolved live SHA>
SES ROLE(S): <roles>
ARCHETYPE_ID(S): <ids>
SES CERTIFICATION: <current status>
TRANSPORT: @ | MANUAL_COPY_PASTE | BLOCKED
SPECIALIST CONSULTATION: EXECUTED | NOT_EXECUTED | BLOCKED
EVIDENCE BOUNDARY: <bounded statement>
```

Never report `EXECUTED` for an `@` or manual consultation that did not actually occur.

## 9. Result handling

A specialist result is evidence for the Project/SES layer. The receiving project must preserve the specialist's evidence boundary, distinguish facts from recommendations and independently validate material claims when required.

The project must not silently turn a specialist recommendation into:

```text
PASS
READY
MERGE
DEPLOY
SECURITY GO
PRODUCTION VALIDATED
```

## 10. Implementation consequence

This contract is a behavioral gate, not merely a documentation convention.

The FECH.AI Builder kernel for GPT0 and the Master Project must reference this gate and must not contain an alternative path in which GPT0 becomes the default executor for all domains.

If Builder configuration still causes a GPT0 turn to bypass this gate, classify the Builder as:

```text
SPECIALIST_ROUTING_DRIFT
```

and block claims of orchestration correctness until the Builder is corrected.

## 11. Acceptance criteria

The gate is satisfied only when behavioral tests demonstrate:

1. a documentation-only task routes to `documentation-auditor` rather than relying on the legacy GPT0 label as operational identity;
2. a cross-domain security/database/architecture task identifies all applicable adopted SES roles before substantive work;
3. an unavailable SES transport does not produce simulated specialist execution;
4. `@` uses the selected SES `CANONICAL_NAME` when visibly available;
5. manual fallback produces an explicit bounded handoff when `@` is unavailable;
6. a noncurrent SES candidate does not become an unsolicited project blocker;
7. specialist output remains distinct from project authority and mutation authorization.

## 12. Canonical precedence

When this gate conflicts with a legacy FECH.AI GPT routing instruction:

```text
MANDATORY SES ORCHESTRATION GATE
>
LEGACY GPT ROUTING
```

Historical labels remain valid only for continuity and provenance.
