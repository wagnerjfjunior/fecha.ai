# FECH.AI — SFJM Builders Current Handoff

**Status:** `CURRENT_BUILDERS_HANDOFF / GROUP_A_RECONCILED / POST_PR111 / DOCUMENTATION_ONLY`  
**Reconstructed on:** `2026-07-31`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Observed canonical main:** `main@d9c306b6278aba5f72a29892e98318ffb2d2405c`  
**Publication vehicle:** `PR #110 — docs/sfjm-builders-continuity-gpt7-gpt8`

## 1. Purpose and boundary

This record preserves continuity for FECH.AI specialist Builder configuration, canonical skills, behavioral validation and safe continuation between conversations.

It is separate from the product/security lifecycle recorded in:

```text
docs/sfjm/handoffs/CURRENT.md
```

This record does not:

- approve runtime, frontend, Supabase, Vercel, deploy or production;
- grant Security Go, F1-02 acceptance or WDP change;
- convert a canonical skill into proof of the live external Builder configuration;
- convert a Builder behavioral test into product/runtime/security evidence;
- authorize mutation of a Builder, repository, PR or environment;
- replace `docs/skills/` or `docs/skills/fechai-gpt-registry.md` as normative sources.

## 2. Source hierarchy and evidence classes

For specialist continuity, use this hierarchy:

```text
1. GitHub live state and the resolved main tip
2. docs/bootstrap/INDEX.md
3. docs/skills/fechai-gpt-registry.md
4. the specialist's canonical file in docs/skills/
5. common bootstrap/governance/SFJM contracts
6. this Builders handoff
7. external Builder screenshots, exports or Product Authority statements
8. historical prompts, uploads, comments or memory
```

Evidence classes used in this record:

```text
CANONICAL_MAIN
= versioned file confirmed on the resolved main.

PR_HEAD_ONLY
= versioned file present only on an open PR head; not canonical until merge.

PRODUCT_AUTHORITY_CONFIRMED
= external Builder configuration or decision explicitly confirmed by Wagner.

BEHAVIORAL_TEST_PASSED
= bounded specialist response passed the declared test; this does not prove live product behavior.

INFORMATION_SUPPLIED
= evidence supplied in conversation or an external snapshot and not independently resolved as live Builder configuration.

EXTERNAL_BUILDER_NOT_REVALIDATED
= the current live Builder interface/configuration was not independently inspected in this handoff reconstruction.
```

No specialist may infer `CANONICAL_MAIN`, `PRODUCT_AUTHORITY_CONFIRMED`, `BEHAVIORAL_TEST_PASSED` or product acceptance from another evidence class.

## 3. PR #111 closure and canonical Group A state

PR #111 closed the canonical skill/documentation reconciliation for Group A.

```text
PR: #111 — docs(skills): reconcile canonical Builder parity group A
State: CLOSED / MERGED
Final PR head: b8d04e0e5d65ab2ccbee569e234db4a11f63e6e4
Squash commit on main: d9c306b6278aba5f72a29892e98318ffb2d2405c
Changed files: 11, all documentation
Runtime/frontend/Supabase/Builder mutation: NONE
```

The merge published:

- the seven Group A canonical skills;
- `docs/skills/fechai-gpt-registry.md` with durable `GROUP_A_RECONCILED` entries;
- the shared bootstrap/evidence contract;
- the Group A Builder × skill parity audit;
- documentation safeguards for coverage, EOF, drift, overclaim and authorization.

The four review findings raised after the first Ready transition were corrected before merge:

1. transient `PR_HEAD_ONLY até merge` status removed from durable registry entries;
2. auditable coverage matrix added;
3. GPT8 Actions reconciled;
4. GPT8 Builders handoff discovery anchored.

This closure proves canonical documentation reconciliation. It does not prove the current external Builder UI/configuration, product behavior, Supabase state, production or Security Go.

## 4. Group A canonical registry

The following specialists are canonically reconciled on `main@d9c306b6278aba5f72a29892e98318ffb2d2405c`:

| Specialist | Canonical skill | Registry state | Canonical Actions contract |
|---|---|---|---|
| GPT0 — Documentation Auditor | `docs/skills/fechai-gpt0-documentation-auditor.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub |
| GPT1 — Arquiteto SaaS | `docs/skills/fechai-gpt1-architect-saas.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub / Supabase only according to configuration and authorization |
| GPT2 — UX/UI APP Specialist | `docs/skills/fechai-gpt2-ux-ui-app-specialist.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub |
| GPT3 — Supabase Security Specialist | `docs/skills/fechai-gpt3-supabase-security-specialist.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub / Supabase `READ_ONLY` by default |
| GPT4 — Vercel/GitHub CI-CD Specialist | `docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub |
| GPT7 — LeadOps CRM Discador Specialist | `docs/skills/fechai-gpt7-leadops-crm-discador.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub |
| GPT8 — MesaCliente Tabelas Propostas Specialist | `docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md` | `v2.0 / GROUP_A_RECONCILED` | GitHub mandatory; Mermaid only after AS-IS is confirmed |

`Skill-file reconciliation: SEPARATE DOCUMENTATION BACKLOG` is no longer a valid state for Group A.

GPT8 is no longer the next Builder construction objective. Its canonical skill and registry contract are part of the reconciled Group A state.

## 5. External Builder and behavioral evidence boundary

The current external Builder configuration was not independently inspected through GitHub during this handoff reconstruction.

Therefore:

```text
Canonical skill state: CONFIRMED ON MAIN
Registry state: CONFIRMED ON MAIN
Current external Builder configuration: EXTERNAL_BUILDER_NOT_REVALIDATED
Historical Builder snapshots/tests: INFORMATION_SUPPLIED unless separately anchored
Product/runtime/security acceptance: NOT IMPLIED
```

Prior operational validations and bounded tests remain useful historical evidence. They must not be reopened merely because a conversation changed.

Reopen a Group A specialist only after at least one of:

- material behavioral failure;
- canonical skill or registry change;
- Builder configuration/tool change;
- source conflict or `SKILL_DRIFT`;
- explicit Product Authority decision;
- new evidence showing the prior test was incomplete or overclaimed.

Do not use absence of live Builder UI access as a reason to discard the canonical Group A reconciliation.

## 6. Durable operating rules retained

The reconciled Group A retains these cross-specialist rules:

- AS-IS before proposal;
- GitHub live and the resolved ref prevail over memory;
- frontend requests/displays; backend/RPC/Supabase validates and decides;
- capability of an Action is not authorization to write;
- fail closed when session, token, permission, tenant, evidence or authority is insufficient;
- classify material source coverage as `NOT_READ`, `PARTIAL_READ` or `INTEGRAL_READ`;
- do not claim complete reading without exact ref/object, coverage and EOF evidence;
- Builder PASS is not Product PASS;
- document is not runtime evidence;
- code is not proof of Supabase-applied state;
- `mergeable=true` is not merge authorization;
- one PR = one principal risk = simple rollback.

## 7. Live product/security anchors revalidated for separation

The following PRs were revalidated only to preserve correct separation from the Builders track.

### PR #108

```text
Title: security: route password completion through RPC
State: OPEN / DRAFT / NOT MERGED
Base recorded: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
Head: bec8b2531486e76c546ddee1d3e2d8b419e220be
Commits: 15
Changed files: 8
Mergeable reported at reconstruction: false
```

PR #108 belongs to the F1-02 password-flow security/runtime track. It must not be operated from Builder continuity.

### PR #109

```text
Title: docs(sfjm): reconcile PR107 post-merge continuity
State: OPEN / DRAFT / NOT MERGED
Base recorded: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
Head: 1a3c72e7b73a07ec7f6f30832c8d18e03c6b2827
Commits: 6
Changed files: 6
Mergeable reported at reconstruction: false
```

PR #109 belongs to product/security SFJM reconciliation. It contains pre-PR #111 continuity statements and must not be merged or updated from this Builder-continuity track without a separate bootstrap, scope decision and authorization.

Both PRs remain anchored to the former main and require separate revalidation before any lifecycle action. Their presence does not block correcting or publishing this Builders handoff.

## 8. PR #110 publication state

This file is published through PR #110.

Until PR #110 merges:

```text
docs/sfjm/handoffs/BUILDERS_CURRENT.md = PR_HEAD_ONLY
```

After an authorized merge and confirmation on the new main:

```text
docs/sfjm/handoffs/BUILDERS_CURRENT.md = CANONICAL_MAIN continuity record
```

The head recorded previously in the GPT8 registry bridge was `6a79b5ab597c7facc7b0d6eafdda36289b21c287`. This corrective update necessarily advances PR #110 to a new head. Until merge, consumers must resolve PR #110 live and treat any old fixed-head bridge as `STALE_CONTINUITY`; they must not invent content or treat the previous head as current.

This transitional mismatch blocks only conclusions that depend on the unpublished handoff. It does not authorize modifying the registry inside PR #110's scope.

## 9. Group B remains separate

The next specialist reconciliation axis is Group B:

```text
GPT5 — SRE/DevSecOps Observability
GPT6 — ADS, Pixel, CAPI and SEO
GPT9 — Integrações, Portais e Mensageria
GPT10 — Monetização, Startup e GTM
```

Current state:

```text
PENDING_PARITY_AUDIT
NOT STARTED BY THIS HANDOFF
NO AUTOMATIC AUTHORIZATION
```

Group B must use separate, small, auditable work after PR #110 closes safely. It must not be added to PR #110.

## 10. What must not be redone or altered

- do not rebuild Group A from scratch solely because this handoff changed;
- do not restore `GPT8_NEXT`;
- do not restore Group A skill reconciliation as backlog;
- do not add repository documents to Builder Knowledge by default;
- do not add Supabase Actions to specialists whose canonical contract does not require them;
- do not infer current live Builder settings without direct evidence;
- do not treat MesaCliente as greenfield;
- do not operate PR #108 or PR #109 from this track;
- do not alter runtime, frontend, Supabase, migrations, RLS, grants, policies, RPCs, Edge Functions, Vercel, GitHub Actions or production;
- do not claim Security Go, product acceptance or deploy readiness.

## 11. Current single next safe action

For PR #110:

```text
1. audit the corrective delta and final PR description with GPT0 in DELTA_ONLY / READ_ONLY mode;
2. after GPT0 PASS, validate lifecycle/scope with GPT4 in READ_ONLY mode;
3. obtain separate explicit Product Authority authorization for Ready;
4. obtain a later, separate explicit authorization for merge;
5. after merge, resolve the new main and confirm this file plus docs/sfjm/INDEX.md are present and coherent.
```

No Group B implementation or Builder mutation belongs to the PR #110 closure step.

## 12. Continuity after PR #110

Once PR #110 is merged and this file is confirmed on main:

- new conversations must bootstrap through `docs/bootstrap/INDEX.md`, `docs/sfjm/INDEX.md`, the registry, the applicable canonical skill and this handoff;
- Group A remains canonically reconciled unless new material evidence requires reopening;
- Group B may be scoped in separate work;
- product/security PRs continue under their own SFJM lifecycle;
- this long-running conversation is not required as the sole continuity source.
