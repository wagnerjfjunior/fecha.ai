# FECH.AI — SFJM Builders Current Handoff

**Status:** `CURRENT_BUILDERS_HANDOFF / GPT7_VALIDATED / GPT8_NEXT / DOCUMENTATION_ONLY`  
**Observed on:** `2026-07-29`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base used for this handoff:** `main@cec1b22430adf1a002b172992cf6c5ea5bb427de`

## 1. Purpose and boundary

This record preserves continuity for the construction and behavioral validation of FECH.AI specialist GPT Builders between conversations.

It is separate from the product/security lifecycle recorded in `docs/sfjm/handoffs/CURRENT.md`.

This record does not:

- approve runtime, frontend, Supabase, Vercel, merge, deploy or production;
- grant Security Go or F1-02 acceptance;
- convert a Builder test into product/runtime evidence;
- replace the official skill files in `docs/skills/`;
- authorize edits to any specialist Builder or repository file without a separately delimited action.

## 2. Evidence classes

```text
GITHUB_VERSIONED
= repository files, blobs, commits and PR lifecycle inspected through GitHub.

PRODUCT_AUTHORITY_CONFIRMED
= Builder configuration or change explicitly confirmed by Wagner.

BEHAVIORAL_TEST_PASSED
= the specialist responded correctly to bounded adversarial tests using the required evidence sources.

NOT_YET_RECONCILED_TO_SKILL_FILE
= the Builder kernel has been validated but its complete dynamic configuration has not yet been reconciled into docs/skills/.
```

Builder validation does not prove product acceptance, runtime correctness, security, tenant isolation or live environment state.

## 3. Specialist Builders validated in the current cycle

```text
GPT0 — FECH.AI Documentation Auditor
GPT1 — FECH.AI Arquiteto SaaS
GPT2 — FECH.AI UX/UI APP Specialist
GPT3 — FECH.AI Supabase Security Specialist
GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist
GPT7 — FECH.AI LeadOps CRM Discador Specialist
```

Current treatment:

```text
Operational Builder validation: PASSED
Product/runtime acceptance: NOT IMPLIED
Skill-file reconciliation: SEPARATE DOCUMENTATION BACKLOG
```

Do not reopen a validated Builder merely because a new conversation started. Reopen only after a material behavioral failure, source conflict, tool change, official skill change or explicit Product Authority decision.

## 4. GPT2 frozen configuration

```text
Role: UX/UI APP Specialist
Status: OPERATIONALLY VALIDATED
Knowledge: EMPTY
GitHub Action: REQUIRED
Supabase Action: NOT REQUIRED / DO NOT ADD
Operating posture: AS-IS FIRST
```

Validated capabilities include:

- reconstruction of the existing APP before proposing UX changes;
- separation between `main`, historical anchors, uploaded full files and PR heads;
- correct handling of large `src/App.jsx` evidence;
- recognition of Home, Oferta Ativa, Aceleração Operacional and MesaCliente as existing product surfaces;
- separation between static source, preview, runtime and backend evidence;
- correct routing to GPT1, GPT3, GPT7 and GPT8.

## 5. GPT7 frozen configuration

```text
Builder name: GPT7 — FECH.AI LeadOps CRM Discador Specialist
Description: VALIDATED
Instructions: v1.7
Instructions application: PRODUCT_AUTHORITY_CONFIRMED
Knowledge: EMPTY
GitHub Action: REQUIRED
Supabase Action: NOT REQUIRED / DO NOT ADD
Status: OPERATIONALLY VALIDATED
```

The v1.7 kernel includes:

- dynamic GitHub bootstrap;
- AS-IS FIRST;
- evidence discipline for large files;
- separation of Discador, Power Dial, Aceleração, Power Mode, Central de Mensagens, Power Zap and Power E-mail;
- import/deduplication contract discipline;
- CRM/funnel/next-action continuity rules;
- contact-event taxonomy;
- metric-source classification;
- LGPD and multi-company guardrails;
- specialist routing;
- fail-closed behavior;
- `STALE_CONTINUITY` handling.

### 5.1 GPT7 behavioral tests passed

```text
LeadOps AS-IS reconstruction: PASS
Large App.jsx evidence handling: PASS
Discador versus Power surfaces: PASS
WhatsApp metric semantics: PASS
Next-action/follow-up contract: PASS
GitHub/SFJM/source hierarchy: PASS
STALE_CONTINUITY declaration: PASS
Mutation during tests: NONE
```

Important validated semantic rule:

```text
wa.me opened != WhatsApp sent
user marked sent != provider-confirmed sent
local session counter != official persisted KPI
```

Important validated product-state rule:

```text
Persistent next action/follow-up: REQUIRED IN MVP / NOT CONFIRMED
```

Important validated continuity rule:

```text
GitHub live and materially relevant PRs prevail for lifecycle.
Historical maps and stale SFJM records cannot reopen completed work.
A Draft PR proves versioned work only; it does not prove merge, deploy, production or acceptance.
```

## 6. Historical live anchors at handoff

These anchors were live-validated during the Builder cycle but must be resolved again in the next conversation:

```text
main observed:
cec1b22430adf1a002b172992cf6c5ea5bb427de

PR #108 observed:
OPEN / DRAFT
base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
head: bec8b2531486e76c546ddee1d3e2d8b419e220be

PR #109 observed:
OPEN / DRAFT
base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
head: 1a3c72e7b73a07ec7f6f30832c8d18e03c6b2827
```

These PRs belong to the F1-02/SFJM product-security lifecycle. They must not be operated merely to continue Builder construction.

## 7. Known continuity divergence

At this handoff:

- `docs/sfjm/handoffs/CURRENT.md` on `main` still described PR #107 as open;
- PR #109 proposed reconciliation after PR #107 merged;
- PR #108 already contained versioned PR-02 implementation work and therefore made part of the PR #109 narrative stale;
- the Builder-validation track must not be mixed into PR #109.

Classification:

```text
STALE_CONTINUITY exists in the product/security SFJM records.
Builder continuity is recorded separately to avoid expanding PR #109's primary risk.
```

## 8. Next Builder objective

```text
GPT8 — FECH.AI MesaCliente Tabelas Propostas Specialist
```

The next conversation must not treat MesaCliente as greenfield.

Before proposing GPT8 configuration, it must resolve live GitHub and read at minimum:

```text
docs/bootstrap/INDEX.md
docs/sfjm/INDEX.md
docs/sfjm/handoffs/BUILDERS_CURRENT.md
docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md
docs/skills/fechai-gpt-registry.md
README.md
docs/product/fechai-modules-map-v1.md
docs/product/fechai-mvp-scope-v1.md
docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md
src/pages/MesaCliente.jsx
src/components/MesaCliente/index.jsx
```

It must then locate and inspect the current implementations of:

- Empreendimentos;
- Fluxo;
- Histórico;
- Operações Financeiras;
- parser/import paths;
- units and availability;
- proposals/simulations;
- legacy or parallel MesaCliente surfaces;
- relevant RPC call sites and unresolved evidence gaps.

## 9. GPT8 Builder constraints

```text
Initial mode: READ_ONLY
Knowledge: EMPTY
GitHub Action: REQUIRED
Supabase Action: DO NOT ADD
No schema, migration, RPC or SQL
No GitHub mutation during initial construction/tests
No MesaCliente redesign from zero
No parser or financial-rule assumption
No Security Go
No merge/deploy recommendation
```

GPT8 may define product rules and functional contracts for MesaCliente, tables, units, simulations and proposals. It must route architecture to GPT1, UX to GPT2, Supabase/security to GPT3, lifecycle to GPT4 and domain-specific commercial/parser decisions according to the official specialist boundaries.

## 10. What must not be redone

- do not rebuild GPT0, GPT1, GPT2, GPT3, GPT4 or GPT7 from scratch;
- do not add Supabase Actions to GPT2, GPT7 or GPT8;
- do not repopulate Builder Knowledge with duplicated repository documents;
- do not treat the uploaded historical `App.jsx` as current live source without anchor validation;
- do not collapse existing product modules into conceptual replacements;
- do not operate PR #108 or PR #109 merely because they are mentioned here;
- do not treat Builder PASS as product, security, merge or deploy approval.

## 11. Single next safe action

```text
Open a new FECH.AI project conversation.
Reconstruct context through bootstrap + SFJM + live GitHub.
Read this Builders handoff.
Receive the current GPT8 Builder configuration from Product Authority.
Audit that configuration in READ_ONLY before proposing the complete GPT8 kernel and behavioral tests.
```

No implementation or product-environment mutation belongs to that step.

## 12. Conversation retirement

After this handoff is versioned and discoverable through `docs/sfjm/INDEX.md`, the current long-running conversation may be retired.

The new conversation must continue from this record without requiring a manually pasted reconstruction of the validated Builder sequence.
