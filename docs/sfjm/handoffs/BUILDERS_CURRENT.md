# FECH.AI — SFJM Builders Current Handoff

**Status:** `CURRENT_BUILDERS_HANDOFF / GROUP_A_RECONCILED / GROUP_B_GPT5_RECONCILED / GPT6_RECONCILIATION_ACTIVE / DOCUMENTATION_ONLY`  
**Reconstructed on:** `2026-08-07`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Observed canonical main:** `main@f710254a03511e4a4b5d65fee62a905a32d1cd82`  
**Active Builder track:** `GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta`

## 1. Purpose and boundary

This record preserves specialist Builder continuity after the authorized GPT5 closure and opens the separate, bounded GPT6 reconciliation track.

It is separate from the product/security lifecycle in:

```text
docs/sfjm/handoffs/CURRENT.md
```

This record does not grant Product PASS, Runtime PASS, Security Go, SLA, deploy authority, production readiness or permission to mutate runtime, Supabase, Vercel, GitHub Actions, external Builders, campaigns, tracking or real data.

## 2. Source hierarchy

```text
1. GitHub live and resolved main/ref
2. docs/bootstrap/INDEX.md
3. docs/skills/fechai-gpt-registry.md
4. specialist canonical skill
5. Modus Operandi and applicable governance/SFJM
6. Product Authority decisions
7. this handoff
8. screenshots, uploaded configuration evidence and historical prompts
```

Evidence classes used here:

```text
CANONICAL_MAIN
PR_HEAD_ONLY
PRODUCT_AUTHORITY_CONFIRMED
BEHAVIORAL_TEST_PASSED
INFORMATION_SUPPLIED
PARTIAL_VISUAL_EVIDENCE
LEGACY_CONTEXT
NOT_EVIDENCED
ACCEPTABLE_WITH_RESIDUAL_RISK
```

No evidence class may be silently promoted into another.

## 3. Group state

```text
Group A:
GPT0, GPT1, GPT2, GPT3, GPT4, GPT7 and GPT8 — RECONCILED

Group B:
GPT5 — GROUP_B_GPT5_RECONCILED
GPT6 — RECONCILIATION_ACTIVE / PENDING_PARITY_AUDIT
GPT9 — PENDING_PARITY_AUDIT
GPT10 — PENDING_PARITY_AUDIT
```

Starting the GPT6 documentation track does not authorize mutation of the external GPT6 Builder, GPT9, GPT10 or any product/runtime surface.

## 4. GPT5 closure — completed canonical state

GPT5 publication and closure are complete:

```text
Publication PR:
#113 — docs(skills): reconcile GPT5 SRE operating contract

Publication squash / prior main:
75eebf7978513eec825ba4b019a4395823ea82a0

Closure PR:
#114 — docs(gpt5): close Builder reconciliation

Closure final head:
aeb9c338a71ef3c4ab555cd07696949147e4828d

Closure squash / current main:
f710254a03511e4a4b5d65fee62a905a32d1cd82

Canonical GPT5 state:
GROUP_B_GPT5_RECONCILED / BUILDER_BEHAVIORAL_PASS
```

The GPT5 closure remains limited to Builder reconciliation. It did not establish Product PASS, Runtime PASS, Security Go, SLA, backup recoverability or broad production readiness.

Do not reopen GPT5 merely because GPT6 reconciliation started. Reopen only after material drift, behavioral failure, canonical change, tool/configuration change or explicit Product Authority decision.

## 5. GPT6 Product Authority naming decision

The Product Authority explicitly decided that numbering is part of the official Builder name:

```text
GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta
```

The prefix and numbering `GPT 6 —` are intentional and do not constitute drift.

## 6. GPT6 canonical pre-reconciliation state

Before this bounded documentation PR, canonical `main@f710254a03511e4a4b5d65fee62a905a32d1cd82` contained:

```text
Skill:
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md

Skill blob:
c17eb59a851865c1c1be9a87c4ea2684d4c21ec2

Skill version:
v1.4

Registry state:
Grupo B / PENDING_PARITY_AUDIT

Registry blob:
e147e187da771ad3be6ac95b990bf9a5539560db

Builders handoff blob:
35866e3e1b1ca6277860acf4833d67ecd766d02d
```

The v1.4 skill preserved valid domain knowledge but still used the older Builder model, including static Knowledge recommendations and an operational kernel that did not fully express the current shared bootstrap/evidence/authority contract.

## 7. GPT6 external Builder AS-IS observed

Screenshots supplied by the Product Authority on `2026-08-07` are classified `PARTIAL_VISUAL_EVIDENCE`.

Observed Builder state:

```text
Builder name:
GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta

Description:
present and domain-aligned in visible evidence

Instructions:
DRIFT_CONFIRMED relative to canonical v1.4 skill

Conversation starters:
DRIFT_CONFIRMED
one duplicate starter observed

Knowledge:
5 static files loaded / LEGACY_CONTEXT

GitHub Action:
NOT_EVIDENCED in the observed Builder configuration

Web search:
ON

Canvas/Lousa:
ON

Image generation:
ON

Code interpreter / data analysis:
ON

Recommended model:
none selected
```

The screenshots do not prove complete character-by-character Instructions contents, every capability setting beyond what was visible, hidden Action configuration, credentials, or a complete export of the Builder.

## 8. Legacy Knowledge observed

Five static Knowledge files were visible in the Builder:

```text
README.md
fechai-gpt3-supabase-security-specialist.md
fechai-gpt2-ux-ui-app-specialist.md
fechai-gpt1-architect-saas.md
lgpd.md
```

The uploaded copies supplied in the same evidence cycle show that these are legacy/static context rather than the current canonical runtime source. Examples include older v1.0 specialist contracts and draft documentation.

Classification:

```text
LEGACY_CONTEXT
NOT_CANONICAL_FOR_RUNTIME_BOOTSTRAP
TARGET_STATE: Knowledge EMPTY
```

The files must not be removed from the external Builder during this documentation PR. Removal is a future Builder mutation requiring separate exact Product Authority authorization and a restorable pre-mutation snapshot/export.

## 9. GPT6 canonical target published by this documentation track

The intended canonical contract is:

```text
Name:
GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta

Skill:
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md

Skill version:
v2.0 / GROUP_B_GPT6_RECONCILIATION_CANDIDATE

State:
PENDING_PARITY_AUDIT

Knowledge target:
EMPTY

GitHub Action target:
REQUIRED / READ_ONLY
```

The skill v2 must preserve the GPT6 domain:

```text
Meta Ads
Google Ads
Pixel / Meta CAPI
Google Offline Conversions
Enhanced Conversions for Leads
CRM-to-Ads
GTM Web / server-side
Stape when justified
UTMs and click IDs
event_id / deduplication / retries
attribution
SEO technical
landing pages
LGPD / minimization
campaign and lead-quality metrics
```

It must also inherit and explicitly preserve the shared operating safeguards required for Builder readiness: live main resolution, registry/skill bootstrap, Modus Operandi, SFJM, coverage classes, EOF, truncation handling, fail-closed, authority boundaries and anti-overclaim.

## 10. What this documentation PR may establish

```text
canonical GPT6 v2 contract
Product Authority naming decision
Knowledge EMPTY target
GitHub READ_ONLY target
canonical conversation starters
Builder AS-IS evidence record
registry alignment
continuity for the next authorized step
```

It does not establish:

```text
external Builder mutation
Knowledge removal applied
GitHub Action configured externally
Builder parity PASS
behavioral test PASS
tracking/CAPI runtime
campaign correctness
Meta/Google platform state
Product PASS
Runtime PASS
Security Go
SLA
production readiness
```

Therefore GPT6 must remain:

```text
PENDING_PARITY_AUDIT
```

## 11. Future external Builder mutation gate

After this publication is independently audited, receives separate Ready and merge authorizations, merges, and the resulting `main` is confirmed, a new exact Product Authority authorization is required before any external Builder mutation.

Required sequence:

1. resolve new `main` live;
2. read final GPT6 skill and registry;
3. preserve a restorable export/snapshot of the current Builder;
4. record non-secret AS-IS evidence;
5. receive exact Builder mutation authorization;
6. apply name, description, Instructions and canonical starters;
7. remove the five legacy Knowledge files so `Knowledge: EMPTY`;
8. configure GitHub Action under the `REQUIRED / READ_ONLY` contract;
9. preserve non-secret evidence of the applied state;
10. execute bounded behavioral tests;
11. only after PASS, consider a separate closure PR.

A Builder mutation does not authorize tests that modify product/runtime state. Tests remain read-only unless a later scenario has its own exact authority.

## 12. Future behavioral suite

Minimum bounded suite after authorized Builder configuration:

```text
A — bootstrap real and evidence integrity
B — Ads/tracking diagnosis with fact/hypothesis/gap separation
C — privilege refusal and fail-closed
D — Meta Pixel/CAPI with event_id/deduplication reasoning
E — Google Offline/Enhanced and CRM-to-Ads reasoning
F — SEO/landing page without unsupported claims
G — real canonical-file retrieval from GitHub
```

Inability to fetch a mandatory/applicable canonical source when live state is material must result in `BUILDER_READINESS_FAILED`, not substitution by memory or static Knowledge.

## 13. Current documentation PR lifecycle contract

Authorized branch:

```text
docs/gpt6-builder-reconciliation
```

Authorized base:

```text
main@f710254a03511e4a4b5d65fee62a905a32d1cd82
```

Exactly three authorized files:

```text
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md
docs/skills/fechai-gpt-registry.md
docs/sfjm/handoffs/BUILDERS_CURRENT.md
```

Lifecycle:

```text
Create as Draft
Documentation mutation only in the three authorized files
Post-creation validation READ_ONLY
No external Builder mutation
No behavioral tests
No comment/review/thread mutation
No Ready
No merge
No deploy
```

Any new corrective commit changes the PR head and invalidates gates bound to the previous head.

## 14. Explicit non-actions

```text
No external GPT6 Builder mutation
No Knowledge removal in Builder
No GitHub Action creation/configuration in Builder
No behavioral tests external to this documentation gate
No runtime/frontend change
No tracking/CAPI/Meta/Google/GTM/Stape mutation
No Supabase/Auth/SQL/migration/RPC/RLS/policy/grant/data change
No Vercel or GitHub Actions change
No production mutation
No GPT5/GPT9/GPT10 mutation
No comment/review/thread mutation
No Ready
No merge
No deploy
No Product PASS
No Runtime PASS
No Security Go
No SLA
```

## 15. Rollback

Rollback of this reconciliation publication is one documentation-only revert of the PR after any later authorized merge.

External Builder rollback is separate and depends on the restorable pre-mutation snapshot/export preserved before the future Builder change. A hash or screenshot alone is not a rollback artifact.

## 16. Single next safe action

After creation of the Draft PR, run only independent READ_ONLY gates on its exact head:

1. GPT0 documentation/evidence audit of the three final files and diff;
2. independent deterministic count of the compact Builder Instructions block against the 8,000-character limit;
3. GPT4 lifecycle, scope, checks, reviews, threads, drift and mergeability validation.

Do not configure the external GPT6 Builder, remove Knowledge, add an Action, execute behavioral tests, mark Ready, merge or deploy in the same step.
