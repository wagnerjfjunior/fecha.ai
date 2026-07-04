# FECH.AI — Project Governance Dashboard / Baseline v1

**Status:** PROPOSED_BASELINE / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Baseline version:** B0 / v1.0  
**Baseline frozen on:** 2026-07-04  
**Measurement starts:** 2026-07-06  
**Planned baseline finish:** 2026-12-18  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Primary scope:** MVP 1 Família → MVP 2 Tegra / cliente real → MVP 3 Mercado  

---

## 1. Purpose and decision

This document creates the versioned governance baseline for real FECH.AI execution. It is the source of truth for measuring progress, capacity, milestones, risks, blockers, forecast and delivery confidence until a later approved baseline supersedes it.

It does **not** implement a dashboard, runtime, frontend, Supabase object, migration, RLS policy, RPC, Edge Function, Vercel configuration, CI workflow or integration.

The visual reference to the SFJM dashboard is directional only. No SFJM design file, information model, asset or source-of-truth visual specification was provided or validated in this cycle. Therefore, this document defines the required information hierarchy and governance semantics; it does not reproduce or claim a validated SFJM visual implementation.

### Decision

The unit of value is a **weighted delivery activity with explicit, verifiable acceptance criteria**.

A pull request is evidence and traceability. A pull request is **not** a unit of delivered value by itself.

No percentage, milestone completion or forecast improvement may be credited solely because a PR was opened, merged, a commit exists, a meeting occurred, or a task was discussed.

---

## 2. Operational bootstrap record

| Bootstrap item | Current record |
|---|---|
| Context understood | FECH.AI remains a Pilot Production multi-tenant / multi-company platform with real users, real lead/client data, active modules and ongoing hardening. |
| Affected module / flow | Delivery governance across LeadOps / CRM / Discador, controlled pilots, market acquisition readiness and the transversal tracks. |
| Environment | GitHub `main` is the versioned source for this documentation baseline. This cycle is documentation-only. |
| PR / branch / head | No implementation PR is evaluated or authorized by this document. The documentation PR that introduces this file is its own narrow governance change. |
| Relevant prior decisions | Bootstrap governance cycle #85–#91; M1 LeadOps reconciliation and fail-closed service-bridge work; existing MVP scope and roadmap. |
| Main risks | Counting PRs rather than accepted outcomes; silently crediting pre-baseline work; forecasting from assumed capacity; advancing a pilot without tenant/security/operational evidence; blending MVPs without a gate. |
| What must not change | Runtime, frontend, Supabase, migrations, RLS, grants, policies, RPC bodies, Edge Functions, Vercel, GitHub Actions, MesaCliente runtime, ADS/CAPI runtime, Make/n8n and production behavior. |
| Evidence available | Official bootstrap/index documents, roadmap/MVP scope, M1 runbook, merged governance PR history and declared delivery structure from Wagner. |
| Evidence absent | Measured delivery capacity; final filled M1 UI→service→RPC map; current live security-go evidence for every used M1 path; pilot calendars and explicit accountable owners; SFJM visual source material. |
| Next safe action | Merge this documentation-only baseline, create the activity register from Section 14, and begin daily evidence logging on 2026-07-06 before claiming new execution progress. |

### Historical pre-baseline evidence rule

The following may be recorded in the evidence register as historical inputs: the M1 runbook and evidence documentation, and the merged fail-closed LeadOps service-bridge change. They are not automatically converted into MVP delivery percentage.

A historical item earns credit only when it is mapped to an activity checkpoint in this baseline and its acceptance criterion is independently verified against the relevant final evidence.

---

## 3. Scope

### 3.1 Included governance scope

This baseline governs:

- three progressive MVPs;
- delivery activities, acceptance criteria, weights, dependencies and planned dates;
- actual progress versus baseline;
- work-delivery capacity and daily plan;
- milestones, recovery and forecast;
- risks, blockers, pending decisions and evidence confidence;
- Health Score and M1–M6 heatmap;
- transversal tracks: security, architecture, CI/CD, documentation, LGPD and observability;
- PR/evidence linkage without PR-count-driven progress.

### 3.2 Explicitly out of scope

This baseline does not authorize or implement:

- product runtime changes;
- frontend/dashboard code or visual design implementation;
- any Supabase schema, data, RLS, grant, policy or RPC change;
- Vercel, GitHub Actions, Edge Functions or production deployment changes;
- ADS, Pixel, CAPI, Google, WhatsApp, Make/n8n or portal integrations;
- launch, billing, pricing or broad commercial rollout.

---

## 4. Delivery structure

| MVP | Controlled audience / operating target | Objective | Exit condition |
|---|---|---|---|
| **MVP 1 — Família** | Wagner, Sabrina, Helena and Laura | Validate the minimum LeadOps / CRM operating loop with controlled internal users. | Family pilot scenarios are evidenced; critical defects are resolved or explicitly accepted; gate decision is recorded. |
| **MVP 2 — Tegra / cliente real** | Wislane first, then Caminhos da Lapa | Validate controlled real-operation use before broader market exposure. | Wislane pilot is accepted before Caminhos da Lapa entry; real-operation evidence, stability and handoff gate are recorded. |
| **MVP 3 — Mercado** | Landing pages, capture, Google/Meta, tracking and commercial operation | Validate a controlled acquisition-to-commercial-operation loop, not broad autonomous scale. | Source, consent, capture, tracking, commercial response and quality-feedback evidence pass the market readiness gate. |

### Progressive-release rule

MVP 2 cannot receive real-client operational credit before MVP 1 gate acceptance. MVP 3 may perform non-live governance/design preparation earlier, but it cannot activate market capture or paid-source operations before the relevant MVP 2 exit and the security/LGPD/tracking gates are accepted.

---

## 5. Baseline parameters

| Parameter | Baseline value | Rule |
|---|---:|---|
| Delivery scope | **300 weighted delivery points (WDP)** | Sum of the 24 activities in Section 10. |
| Planning capacity | **15 WDP / week** | 3 WDP per eligible delivery day × 5 days. This is an initial planning assumption, not measured capacity. |
| Calendar capacity | **360 WDP** | 24 planned weeks × 15 WDP. |
| Portfolio schedule reserve | **60 WDP (20% of delivery scope)** | Reserve is portfolio-level; it is not silently spent or converted into scope. |
| Measurement start | **2026-07-06** | First eligible daily register date. |
| Baseline target finish | **2026-12-18** | Forecast changes dynamically; this original comparison date remains immutable. |
| Working calendar | Brazil business calendar adjusted by approved holidays and declared unavailable days. | A blocked/holiday/unavailable day has planned capacity of zero only when registered. |
| Pre-baseline delivered value | **0 WDP by default** | Historical PRs are evidence candidates, not automatic value. |

### Important capacity constraint

There is no verified historical throughput for this delivery stream. The 15 WDP/week capacity is a planning seed only. Forecast confidence starts **LOW** and must not be represented as a commitment until real accepted-delivery data exists.

---

## 6. Milestones and timeline

| Milestone | Dates | Planned capacity | Planned scoped WDP | Primary result |
|---|---|---:|---:|---|
| **B0** | 2026-07-04 to merge date | n/a | n/a | This baseline is versioned, indexed and reviewable. |
| **M1 — Truth and Security Gate** | 2026-07-06 to 2026-07-24 | 45 | 25 | Final M1 evidence/acceptance map and Security Go decision for used paths. |
| **M2 — Family Core Build** | 2026-07-27 to 2026-08-21 | 60 | 50 | Leads/lists, CRM/funnel, next action and broker action flow ready for controlled validation. |
| **M3 — Family Validation and MVP2 Admission** | 2026-08-24 to 2026-09-18 | 60 | 35 | Family pilot gate plus documented Tegra pilot entry contract. |
| **M4 — Wislane Controlled Pilot** | 2026-09-21 to 2026-10-16 | 60 | 55 | Wislane pilot evidence and initial market governance contract. |
| **M5 — Caminhos da Lapa and Market Preparation** | 2026-10-19 to 2026-11-13 | 60 | 60 | Controlled Caminhos operation, stability evidence and landing-page preparation. |
| **M6 — Controlled Market Readiness** | 2026-11-16 to 2026-12-18 | 75 | 75 | Capture, tracking, controlled activation, commercial loop and market gate. |

### Baseline versus forecast

- **Baseline** is the immutable B0 plan above.
- **Actual** is earned only from accepted activity checkpoints.
- **Forecast** is recalculated weekly from accepted throughput, remaining scope, active risk exposure and confidence.
- A forecast change does not rewrite the baseline.
- A scope/date/weight change requires a Baseline Change Record under Section 15.

---

## 7. Measurement model

### 7.1 Activity completion

Each activity has weighted acceptance checkpoints. Let:

- `w_i` = activity weight in WDP;
- `a_i` = accepted completion ratio of activity `i`, from 0 to 1;
- `EV` = earned value;
- `PV` = planned value on the observation date.

```text
EV = Σ(w_i × a_i)

Activity % = 100 × a_i
MVP % = 100 × Σ(w_i × a_i for MVP) / Σ(w_i for MVP)
Module % = 100 × Σ(w_i × a_i for module) / Σ(w_i for module)
Milestone % = 100 × Σ(w_i × a_i for milestone) / Σ(w_i for milestone)
Portfolio % = 100 × EV / 300
```

`a_i` may be earned only from checklist checkpoints that have evidence. A recommended internal checkpoint split is 0% / 25% / 50% / 75% / 100%, but every credited increment must map to a stated acceptance criterion and evidence link.

### 7.2 Planned value and schedule index

For each activity, planned completion ramps only across its eligible business days:

```text
p_i(d) = 0                         before planned start
p_i(d) = elapsed eligible days / planned eligible days  during activity window
p_i(d) = 1                         after planned finish

PV(d) = Σ(w_i × p_i(d))
SPI(d) = EV(d) / PV(d), when PV(d) > 0
```

Schedule interpretation:

| SPI | Interpretation |
|---:|---|
| `>= 1.00` | on or ahead of baseline plan |
| `0.90–0.99` | minor recovery required |
| `0.75–0.89` | material delay; recovery plan required |
| `< 0.75` | critical delay; milestone/go-no-go review required |

### 7.3 What does not count as progress

The following do not by themselves earn WDP:

- PR opened, merged or closed;
- code written without accepted criterion evidence;
- meeting, chat discussion or verbal report;
- issue created or task moved;
- elapsed calendar time;
- planned work marked as in progress;
- unverified screenshot, demo or claim.

A documentation activity can earn WDP only when its own acceptance is a completed, versioned and reviewable documentation outcome.

---

## 8. Capacity, daily planning and dynamic forecast

### 8.1 Daily capacity

```text
PlannedCapacity(d) = 3 WDP × Availability(d)
```

Where `Availability(d)` is `1.0`, `0.5` or `0.0`, recorded before or during the day. It must be `0.0` only for an approved non-working day, holiday, declared absence or an accepted operational block.

Daily dashboard fields:

| Field | Meaning |
|---|---|
| Planned WDP | accepted-value capacity planned for the date |
| Planned activities | activity checkpoints planned for the date, not raw task count |
| Actual WDP | accepted checkpoint value recorded that date |
| Active activities | activities with current work and evidence expectation |
| Blocked activities | activities blocked by a registered blocker |
| Evidence freshness | age of the latest accepted evidence |
| Remaining capacity | `Planned WDP - planned checkpoint WDP` |

No owner should be assigned more than 3 WDP per eligible delivery day or more than 2 concurrent critical activities without an explicit exception recorded in the daily plan.

### 8.2 Actual capacity

```text
ActualCapacity10 = accepted WDP in the last 10 eligible business days / eligible days
ActualCapacity3W = median accepted WDP per week in the last 3 completed eligible weeks
```

The median is used to reduce distortion from one exceptional week.

### 8.3 Dynamic forecast formula

```text
RemainingWDP = 300 - EV

ForecastCapacity =
  ActualCapacity3W / 5, if at least 10 eligible days of accepted data exist;
  otherwise 3 WDP/day (baseline seed).

RiskBufferWDP = Σ(remaining activity weight × active risk factor)

Risk factor:
  none = 0.00
  low = 0.05
  medium = 0.10
  high = 0.20
  blocking = 0.35

ForecastDays = ceil((RemainingWDP + RiskBufferWDP) / ForecastCapacity)
ForecastFinish = next eligible business date after ForecastDays
```

Forecast capacity is capped for presentation at 125% of baseline capacity until four completed weeks of reliable data exist. A higher observed throughput may be displayed, but must not be used to promise an earlier finish without a confidence review.

### 8.4 Recovery rule

A recovery plan is required when `SPI < 0.90`, when a milestone has less than 10% local schedule capacity remaining, or when a blocking issue exists for more than 2 eligible business days.

A recovery plan must specify:

- affected activity IDs;
- evidence for the delay;
- work that is removed, sequenced later or explicitly added through a change record;
- owner role;
- revised forecast;
- residual risk;
- rollback/containment where applicable.

No recovery plan may silently reduce acceptance criteria merely to restore a percentage.

---

## 9. Health Score

The Health Score is a decision-support metric, not an approval substitute.

```text
HealthScore =
  0.30 × DeliveryIndex +
  0.25 × ScheduleIndex +
  0.15 × CadenceIndex +
  0.15 × RiskIndex +
  0.15 × ConfidenceIndex
```

All component values are 0–100.

| Component | Formula / decision rule |
|---|---|
| DeliveryIndex | `min(100, 100 × EV / PV)` when PV exists; 0 before first planned delivery day. |
| ScheduleIndex | `min(100, 100 × SPI)`; 100 maximum to avoid masking other risk with ahead-of-plan status. |
| CadenceIndex | `max(0, 100 - 12 × max(0, DaysWithoutExecution - 1))`. |
| RiskIndex | Starts at 100; subtract 35 per open blocker, 15 per high risk, 7 per medium risk and 3 per low risk; floor 0. |
| ConfidenceIndex | Weighted evidence coverage, freshness and capacity-history maturity under Section 11. |

| Health Score | Status | Required posture |
|---:|---|---|
| `85–100` | GREEN | Continue; monitor accepted risks. |
| `70–84` | AMBER | Weekly recovery/clarification required. |
| `50–69` | RED | Gate review; do not expand dependent pilot scope. |
| `< 50` | CRITICAL | Stop progression to the next MVP until a documented decision resolves the condition. |

---

## 10. Weighted activity baseline

### MVP 1 — Família (100 WDP)

| ID | Activity | Primary module | Milestone / dates | WDP | Dependencies | Acceptance criterion | Primary owner role | Transversal tags |
|---|---|---|---|---:|---|---|---|---|
| F1-01 | Final M1 evidence and acceptance map | Governance / LeadOps | M1 · 2026-07-06 to 2026-07-10 | 10 | B0 | Every MVP1 acceptance item is mapped to a current path, evidence state, gap, owner role and next safe action. No unknown is labeled ready. | GPT0 + GPT1 + GPT7 | Architecture, Documentation, Security |
| F1-02 | Security Go for used M1 paths | Security / LeadOps | M1 · 2026-07-13 to 2026-07-24 | 15 | F1-01 | Each used path has auth, tenant/company, permission, grant/RLS/RPC and negative-test decision evidence; unresolved exposure is classified and gate decision recorded. | GPT3 + GPT1 | Security, Architecture, CI/CD, Documentation |
| F1-03 | Lead/list intake and basic duplicate handling | LeadOps | M2 · 2026-07-27 to 2026-08-14 | 20 | F1-02 | Approved input path imports a simple list, shows basic duplicate outcome, preserves source/responsible context and produces accepted non-PII operational evidence. | GPT7 | Security, Architecture, CI/CD, Documentation, Observability |
| F1-04 | CRM funnel, responsible owner and next action | CRM | M2 · 2026-08-03 to 2026-08-21 | 20 | F1-02 | Approved user flow persists status, responsible broker, next action/follow-up and history; tenant-isolation negative evidence exists for the used flow. | GPT7 | Security, Architecture, Documentation, Observability |
| F1-05 | Broker execution loop / Power Mode | Discador / UX | M2 · 2026-08-17 to 2026-08-21 | 10 | F1-03, F1-04 | User can progress through the controlled operational loop, execute allowed call/WhatsApp actions and register outcome without claiming automated integrations. | GPT7 + GPT2 | Documentation, Observability |
| F1-06 | Weekend operating dashboard | CRM dashboard | M3 · 2026-08-24 to 2026-09-04 | 10 | F1-04, F1-05 | Dashboard is based on accepted persisted operational data, exposes visits/next actions relevant to the weekend and distinguishes unknown data from zero. | GPT7 + GPT2 | Architecture, Documentation, Observability |
| F1-07 | Family pilot execution | MVP1 pilot | M3 · 2026-09-07 to 2026-09-11 | 10 | F1-03 to F1-06 | Wagner, Sabrina, Helena and Laura complete agreed scenarios; defects, friction, adoption evidence and permissions are recorded without exposing lead data in documentation. | Product / Operation + GPT7 | LGPD, Documentation, Observability |
| F1-08 | MVP1 closeout and gate decision | Governance | M3 · 2026-09-14 to 2026-09-18 | 5 | F1-07 | Go/no-go is recorded with accepted criteria, open blockers, residual risks, rollback/containment and handoff to MVP2. | GPT0 + GPT1 | Security, CI/CD, Documentation, LGPD |

### MVP 2 — Tegra / cliente real (100 WDP)

| ID | Activity | Primary module | Milestone / dates | WDP | Dependencies | Acceptance criterion | Primary owner role | Transversal tags |
|---|---|---|---|---:|---|---|---|---|
| T2-01 | Tegra pilot entry contract | Pilot governance | M3 · 2026-09-07 to 2026-09-18 | 10 | F1-08 | Controlled-pilot scope, users, data owner, permitted data, support path, success evidence and stop condition are recorded. | GPT0 + GPT1 + GPT7 | Security, Documentation, LGPD, Observability |
| T2-02 | Wislane controlled-pilot readiness | Tenant / operation | M4 · 2026-09-21 to 2026-10-02 | 15 | T2-01 | Access, intended workflow, support contact, tenant/company evidence, onboarding and rollback/containment are accepted before real use. | GPT7 + GPT3 + GPT4 | Security, Architecture, CI/CD, Documentation, LGPD |
| T2-03 | Wislane controlled operation and evidence | CRM / operation | M4 · 2026-10-05 to 2026-10-16 | 20 | T2-02 | Real controlled scenarios are completed; usage, failures, operator feedback, latency/availability observations and data-handling evidence are recorded. | Product / Operation + GPT7 | Security, Documentation, LGPD, Observability |
| T2-04 | Wislane gate and Caminhos admission decision | Governance | M4 · 2026-10-12 to 2026-10-16 | 10 | T2-03 | A documented decision confirms whether the next controlled audience may enter; blockers and residual risks are explicit. | GPT0 + GPT1 | Security, Architecture, CI/CD, Documentation |
| T2-05 | Caminhos da Lapa operating setup | CRM / operation | M5 · 2026-10-19 to 2026-10-30 | 15 | T2-04 | Approved workflow, user scope, source/list model, support process, evidence plan and safe rollback/containment are accepted. | GPT7 + GPT1 | Security, Documentation, LGPD, Observability |
| T2-06 | Caminhos controlled execution and adoption | CRM / operation | M5 · 2026-11-02 to 2026-11-06 | 15 | T2-05 | Controlled users execute the agreed operational loop with measurable evidence of use, friction, follow-up and outcome registration. | Product / Operation + GPT7 | Documentation, LGPD, Observability |
| T2-07 | Stability, metrics and defect disposition | Operations | M5 · 2026-11-02 to 2026-11-13 | 10 | T2-06 | Priority defects are resolved or explicitly accepted; operational metrics and unresolved limits are recorded. | GPT5 + GPT7 + GPT4 | Security, CI/CD, Documentation, Observability |
| T2-08 | MVP2 closeout and market handoff | Governance | M5 · 2026-11-09 to 2026-11-13 | 5 | T2-07 | Go/no-go for controlled market readiness, outstanding restrictions and required market gates are recorded. | GPT0 + GPT1 + GPT10 | Security, Documentation, LGPD, Observability |

### MVP 3 — Mercado (100 WDP)

| ID | Activity | Primary module | Milestone / dates | WDP | Dependencies | Acceptance criterion | Primary owner role | Transversal tags |
|---|---|---|---|---:|---|---|---|---|
| M3-01 | Market governance, offer and LGPD entry contract | GTM / governance | M4 · 2026-10-05 to 2026-10-16 | 10 | F1-08 | ICP/offer boundary, approved channels, consent/data-minimization rules, ownership, prohibited claims and stop conditions are documented. | GPT10 + GPT6 + GPT0 | Documentation, LGPD, Architecture |
| M3-02 | Landing-page readiness and consent journey | Acquisition | M5 · 2026-10-19 to 2026-11-13 | 15 | M3-01 | Landing-page content/CTA/data capture specification, consent path, mobile acceptance and lead-routing contract are accepted. No live paid activation is implied. | GPT6 + GPT2 + GPT7 | Documentation, LGPD, Architecture, Observability |
| M3-03 | Capture, origin and CRM handoff | Tracking / LeadOps | M6 · 2026-11-16 to 2026-11-27 | 15 | M3-02, T2-08 | Approved lead capture carries origin and permitted identifiers into the controlled CRM path with duplicate/error behavior and evidence. | GPT6 + GPT7 + GPT3 | Security, Architecture, Documentation, LGPD, Observability |
| M3-04 | Google/Meta tracking event contracts and validation | Tracking | M6 · 2026-11-16 to 2026-12-04 | 20 | M3-01, M3-02, T2-08 | Event dictionary, consent/PII rules, server/client responsibility boundaries, validation evidence and failure observability are accepted. | GPT6 + GPT3 + GPT5 | Security, Architecture, CI/CD, Documentation, LGPD, Observability |
| M3-05 | Controlled source/channel activation | Acquisition operations | M6 · 2026-12-07 to 2026-12-11 | 15 | M3-03, M3-04 | A controlled acquisition source is activated only after relevant gates; lead capture, attribution and stop/rollback evidence are verified. | GPT6 + GPT7 + GPT4 | Security, CI/CD, Documentation, LGPD, Observability |
| M3-06 | Commercial response and lead-quality loop | LeadOps / commercial operation | M6 · 2026-12-07 to 2026-12-18 | 15 | M3-05 | Response ownership, follow-up state, qualified/unqualified feedback and source-quality observation are evidenced. | GPT7 + GPT6 + GPT10 | Documentation, LGPD, Observability |
| M3-07 | Market readiness gate and closing handoff | Governance / GTM | M6 · 2026-12-14 to 2026-12-18 | 10 | M3-03 to M3-06 | Decision records scope proven, unresolved risk, confidence, next safe scale step and items explicitly not authorized. | GPT0 + GPT1 + GPT10 | Security, Architecture, CI/CD, Documentation, LGPD, Observability |

### Weight control

```text
MVP 1 total = 100 WDP
MVP 2 total = 100 WDP
MVP 3 total = 100 WDP
Portfolio total = 300 WDP
```

Activities may carry several transversal tags, but they have only one primary module and are counted once in portfolio EV. Track percentages are independent slices; they must not be added together to represent portfolio progress.

---

## 11. Confidence model

### 11.1 Evidence confidence

For every active activity, record:

- acceptance-checkpoint coverage;
- evidence URL/reference;
- evidence age in eligible business days;
- reviewer/validator role;
- unresolved contradiction or missing evidence;
- capacity sample maturity.

```text
ConfidenceIndex =
  0.45 × EvidenceCoverage +
  0.35 × EvidenceFreshness +
  0.20 × CapacityMaturity
```

All components are scored 0–100.

| Confidence | Minimum conditions |
|---|---|
| **HIGH** | At least 20 eligible days of accepted delivery data; >= 80% of active WDP has evidence no older than 7 eligible days; no open blocker; no material acceptance ambiguity. |
| **MEDIUM** | At least 10 eligible days of accepted delivery data; >= 60% of active WDP has recent evidence; any open issue has explicit containment. |
| **LOW** | Fewer than 10 eligible days of accepted data, missing acceptance/evidence, stale key evidence, or any open blocker affecting the forecast. |
| **UNRELIABLE** | Contradictory evidence, no owner, missing source of truth or unreviewed change that materially affects the metric. |

No forecast marked HIGH may rely only on planned capacity or PR count.

### 11.2 Days without execution

```text
DaysWithoutExecution = eligible business days since the last accepted execution event
```

An accepted execution event must have an activity ID, a checkpoint, dated evidence and validator/owner record. A commit, issue update or generic status message is not automatically an execution event.

---

## 12. M1–M6 heatmap baseline

### 12.1 MVP load heatmap (WDP)

| Delivery line | M1 | M2 | M3 | M4 | M5 | M6 | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| MVP 1 — Família | 25 | 50 | 25 | 0 | 0 | 0 | 100 |
| MVP 2 — Tegra / cliente real | 0 | 0 | 10 | 45 | 45 | 0 | 100 |
| MVP 3 — Mercado | 0 | 0 | 0 | 10 | 15 | 75 | 100 |
| **Portfolio scope** | **25** | **50** | **35** | **55** | **60** | **75** | **300** |
| Baseline capacity | 45 | 60 | 60 | 60 | 60 | 75 | 360 |
| Unallocated reserve | 20 | 10 | 25 | 5 | 0 | 0 | 60 |

### 12.2 Transversal intensity heatmap

Legend: `H` = high planned attention (>=15 tagged WDP), `M` = medium (5–14), `L` = low (1–4), `—` = no tagged scope. These are delivery-intensity cells, not current health colors.

| Track | M1 | M2 | M3 | M4 | M5 | M6 |
|---|---|---|---|---|---|---|
| Security | H | H | H | H | M | H |
| Architecture | H | H | M | H | M | H |
| CI/CD | M | H | M | H | H | H |
| Documentation | H | H | H | H | H | H |
| LGPD | L | M | H | H | H | H |
| Observability | L | M | H | H | H | H |

### 12.3 Actual heatmap state rule

The operational dashboard overlays each heatmap cell with status:

| State | Rule |
|---|---|
| GREEN | accepted EV is on/above PV and no blocker affects the cell |
| AMBER | EV is 90–99% of PV, evidence is aging, or a recoverable risk exists |
| RED | EV is below 90% of PV, a high risk exists, or recovery is overdue |
| BLOCKED | a blocker prevents the next acceptance checkpoint |
| GRAY | future work / no planned activity in the observed period |

---

## 13. Dashboard information architecture (specification only)

### Executive band

1. Portfolio Earned % / EV versus 300 WDP.
2. MVP 1, MVP 2 and MVP 3 weighted completion.
3. Health Score and confidence label.
4. Baseline target finish versus dynamic forecast finish.
5. Days Without Execution.
6. Open blockers, high risks and decisions due.

### Delivery band

1. M1–M6 load/health heatmap.
2. Baseline versus actual cumulative delivery curve.
3. Milestone timeline with current delay/recovery state.
4. Capacity plan versus actual weekly accepted WDP.
5. Forecast range and confidence.

### Control band

1. Activity register with acceptance, weight, dependency, owner role and evidence freshness.
2. Blocker/risk/pendency queue classified as BLOCKING, REQUIRED IN THIS PR, ACCEPTABLE WITH RESIDUAL RISK, PLANNED FUTURE PR or NOT RELEVANT TO THIS SCOPE.
3. PR/evidence traceability panel.
4. Transversal-track slices.
5. Baseline Change Record history and immutable B0 comparison.

### Privacy rule

The governance dashboard must show aggregate delivery evidence. It must not expose lead/customer PII, token, credential, raw production payload or sensitive operational content.

---

## 14. Minimum activity-register schema

The execution register may initially exist as a versioned Markdown/CSV/Sheet artifact. It is not a runtime data-model authorization.

| Field | Required | Rule |
|---|---|---|
| `activity_id` | yes | Must match Section 10. |
| `mvp`, `primary_module`, `milestone` | yes | One primary module; multiple transversal tags allowed. |
| `title`, `acceptance_criteria` | yes | Acceptance must be testable and non-circular. |
| `weight_wdp` | yes | Baseline weight; cannot be silently changed. |
| `planned_start`, `planned_finish` | yes | Eligible business-day calendar. |
| `status` | yes | NOT_STARTED / IN_PROGRESS / IN_VALIDATION / BLOCKED / ACCEPTED / DEFERRED. |
| `accepted_completion_ratio` | yes | 0–1 and tied to checkpoint evidence. |
| `evidence_ref` | yes for credit | GitHub URL, test record, reviewed runbook, controlled observation reference or equivalent. |
| `evidence_date`, `validator_role` | yes for credit | Supports freshness and confidence. |
| `dependency_ids` | yes | Must reference valid activity IDs or B0. |
| `owner_role` | yes | Named human owner may be added later; do not infer one. |
| `risk_level`, `blocker_id` | yes | none / low / medium / high / blocking. |
| `next_safe_action` | yes while active | One clear action, not a vague intention. |
| `pr_refs` | optional | Evidence only; no direct progress credit. |
| `baseline_version` | yes | Starts as B0 / v1.0. |

### Daily execution-event minimum record

```text
Date:
Activity ID:
Checkpoint / accepted ratio change:
Actual WDP earned:
Evidence reference:
Validator / owner role:
Blocker or risk change:
Next safe action:
```

---

## 15. Update cadence and baseline-change control

### Daily

- register planned capacity, actual accepted WDP and evidence events;
- update active blockers and next safe action;
- calculate days without execution;
- do not update percentage without criterion/evidence linkage.

### Weekly

- close actual capacity for the week;
- recalculate EV, PV, SPI, forecast, Health Score and confidence;
- review high risks, blockers, late dependencies and recovery need;
- publish a compact evidence-based status note.

### At every milestone gate

- validate each exit condition;
- record go/no-go explicitly;
- record residual risks, prohibited expansion and rollback/containment;
- create a handoff for the next MVP or planned future PR.

### Baseline Change Record (BCR)

A BCR is mandatory before changing scope, weight, target date, dependency, acceptance criterion or capacity assumption in the active plan.

```text
BCR ID:
Date:
Baseline version affected:
Change type: scope / weight / date / dependency / acceptance / capacity
Reason and evidence:
Activities affected:
Impact on EV/PV and forecast:
Impact on security / LGPD / architecture / CI-CD / observability:
Approver roles:
Decision: approved / rejected / deferred
New comparison baseline version:
```

Rules:

1. B0 remains immutable and visible after any BCR.
2. Forecast movement does not require a BCR.
3. A BCR cannot erase delay, convert unaccepted work into earned value or weaken acceptance merely to improve status.
4. A BCR that expands live pilot scope requires the relevant gate validators.

---

## 16. Initial risk register

| ID | Classification | Risk / pending item | Impact | Required response |
|---|---|---|---|---|
| R-B0-01 | REQUIRED IN THIS PR | Baseline capacity is assumed, not measured. | Forecast may be unreliable in early weeks. | Start capacity observation on 2026-07-06; retain LOW forecast confidence until evidence maturity. |
| R-B0-02 | REQUIRED IN THIS PR | M1 final UI→service→RPC map and full acceptance mapping are not confirmed by this baseline. | MVP1 cannot claim readiness. | Execute F1-01 before technical/activity credit beyond historical evidence review. |
| R-B0-03 | BLOCKING for real-user expansion | Security Go is not presumed for all M1 used paths. | Tenant/data exposure risk. | Execute F1-02 and preserve fail-closed posture before family/real-client operational expansion. |
| R-B0-04 | ACCEPTABLE WITH RESIDUAL RISK | SFJM visual source is unavailable. | Visual parity cannot be specified. | Use this semantic/dashboard hierarchy; refine visual system only when source material is supplied. |
| R-B0-05 | PLANNED FUTURE PR | No runtime dashboard is implemented in this cycle. | Manual/Sheet-based register may be needed initially. | Implement only after baseline data/use is stable and a separately scoped PR is approved. |
| R-B0-06 | BLOCKING for MVP3 activation | Market capture/tracking requires consent, data-boundary and operational evidence. | LGPD, tracking integrity and commercial-risk exposure. | Enforce M3-01 through M3-05 gates before controlled activation. |

---

## 17. Acceptance criteria for this baseline document

This documentation baseline is acceptable only when:

- it defines the three MVPs and their progressive gates;
- it contains weighted activities totaling exactly 300 WDP;
- every weighted activity has dates, dependencies, acceptance criteria and owner role;
- it defines baseline versus actual, capacity, forecast, confidence, health, risks and update rules;
- it explicitly treats PRs as traceability rather than delivery value;
- it includes the M1–M6 heatmap and transversal tracks;
- it preserves B0 immutability and BCR control;
- it remains documentation-only with no sensitive runtime/infrastructure changes;
- it is linked from the bootstrap/index trail.

---

## 18. Next safe action after merge

Create the B0 activity register using the schema in Section 14 and enter only:

1. the 24 baseline activities;
2. the B0 milestone acceptance record;
3. historical evidence candidates for review without automatic credit;
4. the first daily plan for 2026-07-06;
5. the F1-01 evidence and acceptance-map work package.

No MVP completion percentage should be published until the register contains checkpoint-level evidence.
