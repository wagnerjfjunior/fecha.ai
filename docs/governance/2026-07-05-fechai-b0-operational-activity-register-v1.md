# FECH.AI — B0 Operational Activity Register v1

**Status:** B0_REGISTER_INITIALIZED / PLANNED / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Baseline identity:** B0  
**Register version:** R1 / v1.0  
**Register frozen on:** 2026-07-05  
**Measurement starts:** 2026-07-06  
**Baseline target finish:** 2026-12-23  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Purpose and authority

This register operationalizes the merged B0 governance baseline into an auditable delivery ledger. It records the **exact 23 activities / 300 WDP**, authoritative v1.3 dates, explicit dependency IDs, acceptance checkpoints, owner-allocation plan, current evidence state, blockers and the first daily plan.

It is a governance artifact only. It does **not** authorize or change runtime, frontend, Supabase, migrations, RLS, grants, policies, RPCs, Edge Functions, Vercel, GitHub Actions, MesaCliente, ADS/CAPI, Make/n8n, integrations or production behavior.

### Authoritative reading order

1. `docs/governance/2026-07-04-fechai-project-governance-dashboard-baseline-v1.md` — full B0 model and activity acceptance criteria.
2. `docs/governance/2026-07-04-fechai-project-governance-dashboard-baseline-v1.3-consistency-correction.md` — authoritative corrections for calendar, dates, dependencies, forecast, Health Score, owner allocation and heatmap.
3. This register — B0 operating record, initially at zero earned value.
4. `docs/governance/INDEX.md` — governance entry point.

Where this register conflicts with v1.3, v1.3 prevails. This register may not rewrite scope, WDP, baseline dates, acceptance criteria or dependencies; those changes require a separate Baseline Change Record.

---

## 2. Operational bootstrap

| Bootstrap item | Current record |
|---|---|
| Context understood | FECH.AI is Pilot Production, multi-tenant / multi-company, with real users and sensitive lead/client data. |
| Affected module / flow | Delivery-governance record for MVP1 Família → MVP2 Tegra / cliente real → MVP3 Mercado. |
| Environment | GitHub `main` is the versioned source. This PR is documentation-only. |
| Relevant prior decision | PR #92 merged B0 baseline and its v1.3 pre-execution correction. |
| Files in scope | This register and governance/bootstrap indexes only. |
| What must not change | Runtime, frontend, Supabase, migrations, RLS, grants, policies, RPCs, Edge Functions, Vercel, GitHub Actions, MesaCliente, ADS/CAPI, Make/n8n, integrations and production behavior. |
| Available evidence | Merged B0 baseline, B0 v1.3 correction, bootstrap index and governance index. |
| Missing evidence | Current final M1 UI→service→RPC map, complete Security Go evidence for used M1 paths, measured delivery throughput, accepted pilot calendars and named-accountable-person acceptance. |
| Main risks | Counting PRs as value; silently crediting historical work; treating a planned role allocation as confirmed staffing; operating a pilot before security/tenant/LGPD evidence; calendar or capacity drift. |
| Next safe action | Execute the 2026-07-06 daily plan, retain checkpoint evidence, and publish no WDP until a validator records accepted evidence. |

### Finding classification at register creation

| Classification | Finding | Required handling |
|---|---|---|
| REQUIRED IN THIS PR | Exact 23-activity register, explicit v1.3 dates/dependencies and owner allocations are needed before measurement. | Delivered by this register; validate by PR diff. |
| ACCEPTABLE WITH RESIDUAL RISK | Capacity is an initial planning seed, not measured throughput. | Keep forecast confidence LOW until evidence maturity conditions are met. |
| PLANNED FUTURE PR | Runtime dashboard implementation or any product work. | Keep out of this PR; each change needs narrow technical scope and Security Go. |
| NOT RELEVANT TO THIS SCOPE | Runtime, database, deployment and external-integration modifications. | Do not alter. |

---

## 3. Measurement lock at initialization

At the time this register was created:

```text
Portfolio EV: 0 / 300 WDP
Portfolio completion: 0%
Accepted checkpoints: 0
Actual delivery capacity: unmeasured
Forecast confidence: LOW
Health Score: NOT_STARTED until 2026-07-06
All activities: PLANNED
```

Historical PRs, runbooks, evidence maps and the fail-closed LeadOps service-bridge change remain **evidence candidates only**. They earn no WDP unless independently mapped to the checkpoint below and accepted against the final evidence.

### Non-negotiable credit rule

No WDP may be recorded from a PR, commit, meeting, issue, screenshot, verbal confirmation or elapsed time alone. An accepted checkpoint must have all of:

1. `activity_id` and checkpoint identifier;
2. criterion that is being tested;
3. final evidence URL/reference and immutable identifier where applicable;
4. evidence date and eligible-business-day date;
5. validator role;
6. result: accepted, rejected or blocked;
7. open contradiction, residual risk or containment, if any.

The initial default checkpoint split is `0% / 25% / 50% / 75% / 100%` of each activity WDP. A different split is allowed only when recorded before crediting the activity and when every increment remains tied to a verifiable acceptance condition.

### Status vocabulary

| Status | Meaning | WDP effect |
|---|---|---|
| PLANNED | Scheduled but not started with evidence. | 0 |
| ACTIVE | Work is underway; evidence is expected. | 0 unless a checkpoint is accepted. |
| BLOCKED | A registered blocker prevents safe continuation. | 0; risk/forecast must be reviewed. |
| EVIDENCE_READY | Evidence exists but has not been independently accepted. | 0 |
| ACCEPTED_PARTIAL | One or more checkpoints are accepted. | Only accepted checkpoint WDP. |
| ACCEPTED | All acceptance criteria are independently accepted. | Full activity WDP. |
| DEFERRED_BY_DECISION | Explicit governance decision pauses or moves the activity. | No automatic credit; BCR/recovery rule may apply. |

---

## 4. Calendar, capacity and allocation controls

### 4.1 Calendar

B0 uses the Brazil federal business calendar. The following dates have `0 WDP` planned capacity unless an updated legal calendar changes the source of truth:

```text
2026-09-07
2026-10-12
2026-11-02
2026-11-20
```

A state or municipal holiday, planned absence or operational block changes capacity only after it is registered as a local availability exception with owner, evidence and impact.

### 4.2 Capacity rule

```text
Baseline capacity = 3 WDP per eligible business day
Portfolio scope = 300 WDP
Calendar capacity = 357 WDP
Portfolio reserve = 57 WDP / 19%
```

### 4.3 Owner-allocation rule

The `owner_allocation` entries below are a **planning ledger**, not a staffing acceptance or progress claim.

```text
activity_id
owner_role
allocated_wdp
planned eligible dates
```

Controls:

1. Allocations across owner roles sum exactly to each activity WDP.
2. A co-owner or validator receives only its stated allocation; activity WDP is never multiplied by the number of roles.
3. No owner role exceeds 3 allocated WDP on one eligible business day without a documented exception.
4. Named pilot participants are not automatically accountable owners. Their participation, scope, consent and support arrangements must be accepted in the relevant pilot-entry activity.
5. The daily plan may sequence or move planned allocations inside an activity window, but it may not change WDP, dependencies or end-gate conditions without a documented governance decision.

---

## 5. Portfolio register — all 23 activities

### MVP1 — Família (100 WDP)

| ID | Activity and module | Dates / milestone | WDP | Dependencies | Primary owner roles | Acceptance condition | Initial state |
|---|---|---|---:|---|---|---|---|
| F1-01 | Final M1 evidence and acceptance map — Governance / LeadOps | 2026-07-06 to 2026-07-10 / M1 | 10 | B0 | GPT0, GPT1, GPT7 | Every MVP1 acceptance item is mapped to a current path, evidence state, gap, owner role and next safe action; no unknown is labeled ready. | PLANNED / 0 WDP |
| F1-02 | Security Go for used M1 paths — Security / LeadOps | 2026-07-13 to 2026-07-24 / M1 | 15 | F1-01 | GPT3, GPT1 | Used paths have auth, tenant/company, permission, grant/RLS/RPC and negative-test decision evidence; exposure and gate decision are recorded. | PLANNED / 0 WDP |
| F1-03 | Lead/list intake and basic duplicate handling — LeadOps | 2026-07-27 to 2026-08-14 / M2 | 20 | F1-02 | GPT7 | Approved input path imports a simple list, shows basic duplicate outcome, preserves source/responsible context and produces accepted non-PII operational evidence. | PLANNED / 0 WDP |
| F1-04 | CRM funnel, responsible owner and next action — CRM | 2026-08-03 to 2026-08-14 / M2 | 20 | F1-02 | GPT7 | Approved flow persists status, responsible broker, next action/follow-up and history; tenant-isolation negative evidence exists for the used flow. | PLANNED / 0 WDP |
| F1-05 | Broker execution loop / Power Mode — Discador / UX | 2026-08-17 to 2026-08-21 / M2 | 10 | F1-03, F1-04 | GPT7, GPT2 | User progresses through the controlled loop, executes allowed call/WhatsApp actions and registers outcome without claiming automated integrations. | PLANNED / 0 WDP |
| F1-06 | Weekend operating dashboard — CRM dashboard | 2026-08-24 to 2026-09-04 / M3 | 10 | F1-04, F1-05 | GPT7, GPT2 | Dashboard uses accepted persisted operational data, shows weekend-relevant visits/next actions and distinguishes unknown from zero. | PLANNED / 0 WDP |
| F1-07 | Family pilot execution — MVP1 pilot | 2026-09-08 to 2026-09-11 / M3 | 10 | F1-03, F1-04, F1-05, F1-06 | Product / Operation, GPT7 | Wagner, Sabrina, Helena and Laura complete agreed scenarios; defects, friction, adoption and permission evidence are recorded without exposing lead data in documentation. | PLANNED / 0 WDP |
| F1-08 | MVP1 closeout and gate decision — Governance | 2026-09-14 to 2026-09-15 / M3 | 5 | F1-07 | GPT0, GPT1 | Go/no-go records accepted criteria, blockers, residual risks, rollback/containment and handoff to MVP2. | PLANNED / 0 WDP |

### MVP2 — Tegra / cliente real (100 WDP)

| ID | Activity and module | Dates / milestone | WDP | Dependencies | Primary owner roles | Acceptance condition | Initial state |
|---|---|---|---:|---|---|---|---|
| T2-01 | Tegra pilot entry contract — Pilot governance | 2026-09-16 to 2026-09-18 / M3 | 10 | F1-08 | GPT0, GPT1, GPT7 | Controlled-pilot scope, users, data owner, permitted data, support path, success evidence and stop condition are recorded. | PLANNED / 0 WDP |
| T2-02 | Wislane controlled-pilot readiness — Tenant / operation | 2026-09-21 to 2026-10-02 / M4 | 15 | T2-01 | GPT7, GPT3, GPT4 | Access, intended workflow, support contact, tenant/company evidence, onboarding and rollback/containment are accepted before real use. | PLANNED / 0 WDP |
| T2-03 | Wislane controlled operation and evidence — CRM / operation | 2026-10-05 to 2026-10-14 / M4 | 20 | T2-02 | Product / Operation, GPT7 | Real controlled scenarios complete; usage, failures, feedback, latency/availability observations and data-handling evidence are recorded. | PLANNED / 0 WDP |
| T2-04 | Wislane gate and Caminhos admission decision — Governance | 2026-10-15 to 2026-10-16 / M4 | 10 | T2-03 | GPT0, GPT1 | Decision confirms whether the next controlled audience may enter; blockers and residual risks are explicit. | PLANNED / 0 WDP |
| T2-05 | Caminhos da Lapa operating setup — CRM / operation | 2026-10-19 to 2026-10-30 / M5 | 15 | T2-04 | GPT7, GPT1 | Approved workflow, user scope, source/list model, support process, evidence plan and rollback/containment are accepted. | PLANNED / 0 WDP |
| T2-06 | Caminhos controlled execution and adoption — CRM / operation | 2026-11-03 to 2026-11-09 / M5 | 15 | T2-05 | Product / Operation, GPT7 | Controlled users execute the agreed loop with measurable use, friction, follow-up and outcome-registration evidence. | PLANNED / 0 WDP |
| T2-07 | Stability, metrics and defect disposition — Operations | 2026-11-10 to 2026-11-13 / M5 | 10 | T2-06 | GPT5, GPT7, GPT4 | Priority defects are resolved or explicitly accepted; operational metrics and unresolved limits are recorded. | PLANNED / 0 WDP |
| T2-08 | MVP2 closeout and market handoff — Governance | 2026-11-16 to 2026-11-17 / M5 | 5 | T2-07 | GPT0, GPT1, GPT10 | Go/no-go for controlled market readiness, restrictions and required market gates are recorded. | PLANNED / 0 WDP |

### MVP3 — Mercado (100 WDP)

| ID | Activity and module | Dates / milestone | WDP | Dependencies | Primary owner roles | Acceptance condition | Initial state |
|---|---|---|---:|---|---|---|---|
| M3-01 | Market governance, offer and LGPD entry contract — GTM / governance | 2026-10-05 to 2026-10-16 / M4 | 10 | F1-08 | GPT10, GPT6, GPT0 | ICP/offer boundary, approved channels, consent/data-minimization rules, ownership, prohibited claims and stop conditions are documented. | PLANNED / 0 WDP |
| M3-02 | Landing-page readiness and consent journey — Acquisition | 2026-10-19 to 2026-11-17 / M5 | 15 | M3-01 | GPT6, GPT2, GPT7 | Landing-page content/CTA/data-capture specification, consent path, mobile acceptance and lead-routing contract are accepted; no live paid activation is implied. | PLANNED / 0 WDP |
| M3-03 | Capture, origin and CRM handoff — Tracking / LeadOps | 2026-11-18 to 2026-11-27 / M6 | 15 | M3-02, T2-08 | GPT6, GPT7, GPT3 | Approved capture carries origin and permitted identifiers into the controlled CRM path with duplicate/error behavior and evidence. | PLANNED / 0 WDP |
| M3-04 | Google/Meta tracking event contracts and validation — Tracking | 2026-11-18 to 2026-12-02 / M6 | 20 | M3-01, M3-02, T2-08 | GPT6, GPT3, GPT5 | Event dictionary, consent/PII rules, server/client boundaries, validation evidence and failure observability are accepted. | PLANNED / 0 WDP |
| M3-05 | Controlled source/channel activation — Acquisition operations | 2026-12-03 to 2026-12-09 / M6 | 15 | M3-03, M3-04 | GPT6, GPT7, GPT4 | A controlled acquisition source activates only after relevant gates; capture, attribution and stop/rollback evidence are verified. | PLANNED / 0 WDP |
| M3-06 | Commercial response and lead-quality loop — LeadOps / commercial operation | 2026-12-10 to 2026-12-16 / M6 | 15 | M3-05 | GPT7, GPT6, GPT10 | Response ownership, follow-up state, qualified/unqualified feedback and source-quality observation are evidenced. | PLANNED / 0 WDP |
| M3-07 | Market readiness gate and closing handoff — Governance / GTM | 2026-12-17 to 2026-12-23 / M6 | 10 | M3-03, M3-04, M3-05, M3-06 | GPT0, GPT1, GPT10 | Decision records scope proven, unresolved risk, confidence, next safe scale step and items explicitly not authorized. | PLANNED / 0 WDP |

### Weight control

```text
MVP1: 8 activities / 100 WDP
MVP2: 8 activities / 100 WDP
MVP3: 7 activities / 100 WDP
Portfolio: 23 activities / 300 WDP
```

Transversal tags are analytical slices only. They must not be summed as portfolio WDP.

---

## 6. Owner-allocation ledger

The entries below sum exactly to each activity WDP and keep each role at or below 3 allocated WDP per stated eligible date. Dates are planned contribution dates, not proof of execution or credit.

| Activity | Owner allocation and planned eligible dates | Total |
|---|---|---:|
| F1-01 | GPT0: 4 WDP (`07-06:2.5`, `07-07:1.5`); GPT1: 3 WDP (`07-07:1`, `07-08:2`); GPT7: 3 WDP (`07-08:0.5`, `07-09:2.5`). `07-10` is reserved for acceptance review with no additional allocation. | 10 |
| F1-02 | GPT3: 8 WDP (`07-13:2`, `07-14:2`, `07-15:2`, `07-16:2`); GPT1: 7 WDP (`07-17:2`, `07-20:2`, `07-21:3`). | 15 |
| F1-03 | GPT7: 20 WDP (`07-27:3`, `07-28:3`, `07-29:3`, `07-30:3`, `07-31:3`, `08-03:3`, `08-04:2`). | 20 |
| F1-04 | GPT7: 20 WDP (`08-04:1`, `08-05:3`, `08-06:3`, `08-07:3`, `08-10:3`, `08-11:3`, `08-12:2`, `08-13:1`, `08-14:1`). | 20 |
| F1-05 | GPT7: 6 WDP (`08-17:3`, `08-18:3`); GPT2: 4 WDP (`08-19:2`, `08-20:2`). | 10 |
| F1-06 | GPT7: 6 WDP (`08-24:3`, `08-25:3`); GPT2: 4 WDP (`08-26:2`, `08-27:2`). | 10 |
| F1-07 | Product / Operation: 6 WDP (`09-08:2`, `09-09:2`, `09-10:2`); GPT7: 4 WDP (`09-10:1`, `09-11:3`). | 10 |
| F1-08 | GPT0: 3 WDP (`09-14:3`); GPT1: 2 WDP (`09-15:2`). | 5 |
| T2-01 | GPT0: 3 WDP (`09-16:3`); GPT1: 3 WDP (`09-17:3`); GPT7: 4 WDP (`09-16:1`, `09-18:3`). | 10 |
| T2-02 | GPT7: 6 WDP (`09-21:3`, `09-22:3`); GPT3: 5 WDP (`09-23:2`, `09-24:3`); GPT4: 4 WDP (`09-25:2`, `09-28:2`). | 15 |
| T2-03 | Product / Operation: 12 WDP (`10-05:3`, `10-06:3`, `10-07:3`, `10-08:3`); GPT7: 8 WDP (`10-09:3`, `10-13:3`, `10-14:2`). | 20 |
| T2-04 | GPT0: 4 WDP (`10-15:2`, `10-16:2`); GPT1: 6 WDP (`10-15:3`, `10-16:3`). | 10 |
| T2-05 | GPT7: 9 WDP (`10-19:3`, `10-20:3`, `10-21:3`); GPT1: 6 WDP (`10-22:3`, `10-23:3`). | 15 |
| T2-06 | Product / Operation: 9 WDP (`11-03:3`, `11-04:3`, `11-05:3`); GPT7: 6 WDP (`11-06:3`, `11-09:3`). | 15 |
| T2-07 | GPT5: 4 WDP (`11-10:2`, `11-11:2`); GPT7: 3 WDP (`11-12:3`); GPT4: 3 WDP (`11-13:3`). | 10 |
| T2-08 | GPT0: 2 WDP (`11-16:2`); GPT1: 1 WDP (`11-17:1`); GPT10: 2 WDP (`11-17:2`). | 5 |
| M3-01 | GPT10: 4 WDP (`10-05:2`, `10-06:2`); GPT6: 3 WDP (`10-07:3`); GPT0: 3 WDP (`10-08:3`). | 10 |
| M3-02 | GPT6: 5 WDP (`10-19:2`, `10-20:3`); GPT2: 5 WDP (`10-21:2`, `10-22:3`); GPT7: 5 WDP (`10-26:2`, `10-27:3`). | 15 |
| M3-03 | GPT6: 5 WDP (`11-18:2`, `11-19:3`); GPT7: 5 WDP (`11-23:2`, `11-24:3`); GPT3: 5 WDP (`11-25:2`, `11-26:3`). | 15 |
| M3-04 | GPT6: 4 WDP (`11-25:2`, `11-27:2`); GPT3: 6 WDP (`11-18:3`, `11-19:3`); GPT5: 4 WDP (`12-01:2`, `12-02:2`). | 20 |
| M3-05 | GPT6: 6 WDP (`12-03:3`, `12-04:3`); GPT7: 6 WDP (`12-07:3`, `12-08:3`); GPT4: 3 WDP (`12-09:3`). | 15 |
| M3-06 | GPT7: 6 WDP (`12-10:3`, `12-11:3`); GPT6: 5 WDP (`12-14:3`, `12-15:2`); GPT10: 4 WDP (`12-15:1`, `12-16:3`). | 15 |
| M3-07 | GPT0: 4 WDP (`12-17:2`, `12-18:2`); GPT1: 3 WDP (`12-21:2`, `12-23:1`); GPT10: 3 WDP (`12-22:3`). | 10 |

`MM-DD` dates in this table are within calendar year 2026. Federal holidays are excluded. Any change to this ledger must preserve the 3-WDP-per-role-per-day ceiling or carry a documented exception and recovery rationale.

---

## 7. First daily execution plan — M1 / F1-01

### 7.1 M1 execution posture

M1 starts on **2026-07-06**. The only active candidate activity is F1-01. F1-02 is not eligible to start until F1-01 is accepted. This plan creates no delivery credit by itself.

### 7.2 Planned week

| Date | Eligible capacity | Planned F1-01 checkpoint candidate | Planned owner allocation | Expected evidence output | Actual WDP at publication |
|---|---:|---|---|---|---:|
| 2026-07-06 | 3 | CP1 — freeze source list and evidence inventory (`2.5 WDP` candidate) | GPT0 `2.5 WDP` | Canonical source list; final refs/SHAs where available; evidence-state inventory. | 0 |
| 2026-07-07 | 3 | CP2 — map MVP1 paths to evidence state and gap (`2.5 WDP` candidate) | GPT0 `1.5 WDP`; GPT1 `1 WDP`; `0.5 WDP` reserve | Path-to-evidence matrix with current / absent / contradictory flags. | 0 |
| 2026-07-08 | 3 | CP3 — assign gaps, owner roles and next safe actions (`2.5 WDP` candidate) | GPT1 `2 WDP`; GPT7 `0.5 WDP`; `0.5 WDP` reserve | Gap register with named owner roles, required evidence and containment. | 0 |
| 2026-07-09 | 3 | CP4 — independent coherence review (`2.5 WDP` candidate) | GPT7 `2.5 WDP`; `0.5 WDP` reserve | Review notes; contradictions; explicit ready/not-ready decisions. | 0 |
| 2026-07-10 | 3 | Acceptance decision or rejection/containment for F1-01 | No new WDP allocation; capacity remains reserve | Validator record; accepted/rejected checkpoint outcomes; handoff to F1-02 only if all relevant criteria are accepted. | 0 |

### 7.3 Daily update contract

At the end of each eligible day, publish one dated register entry containing:

```text
Date
Activity ID / checkpoint
Planned WDP
Actual accepted WDP
Evidence reference
Validator role
Status
Blocker or residual risk
Next safe action
```

A missing daily entry is not assumed to mean zero activity; it is an evidence-freshness gap and must be handled as such.

---

## 8. Baseline-versus-actual and forecast initialization

Until enough accepted-data history exists:

```text
EV = 0
PV = calculated only from eligible planned dates
SPI = EV / PV when PV > 0
ForecastCapacity = 3 WDP/day before 10 eligible days of accepted-data history
Forecast confidence = LOW
```

After measurement history exists, use the authoritative v1.3 fallback:

```text
ActualCapacity3W / 5
  only when >= 15 eligible business days and 3 complete eligible weeks exist;

ActualCapacity10
  when >= 10 eligible business days exist but the 3-week sample does not;

3 WDP/day
  before 10 eligible business days of accepted-data history.
```

Portfolio completion remains `100 × EV / 300`. Health Score remains `NOT_STARTED` before 2026-07-06 and must use the v1.3 composition after that date; it may not double-count portfolio completion.

---

## 9. Initial risk and blocker register

| ID | Type | Description | Affected activity IDs | Initial level | Containment / decision rule | Owner role |
|---|---|---|---|---|---|---|
| R-B0-01 | Evidence gap | Final M1 UI→service→RPC map is not confirmed by this register. | F1-01, F1-02 | High | Do not label a path ready; map gap and require final source/PR/live evidence before Security Go. | GPT0, GPT1, GPT7 |
| R-B0-02 | Security gap | Complete used-path auth/tenant/permission/grant/RLS/RPC negative-test evidence is not confirmed. | F1-02 and all dependents | Blocking until resolved or explicitly contained | Fail closed; do not advance F1-03 or pilot scope without gate decision. | GPT3, GPT1 |
| R-B0-03 | Capacity uncertainty | No accepted-delivery throughput exists for this stream. | Portfolio | Medium | Use baseline seed only; maintain LOW confidence; do not promise earlier finish. | Governance |
| R-B0-04 | Pilot governance | Named pilot participants and data-operation conditions are not accepted merely by being listed in scope. | F1-07, T2-01, T2-02, T2-03 | High | Require explicit entry contract, permitted-data boundary, support path and stop condition. | Product / Operation, GPT7 |
| R-B0-05 | Scope creep | Governance work could drift into runtime/dashboard/product change. | This PR / all activities | Medium | One PR = one risk; separate technical PRs; reject undocumented runtime change. | GPT0, GPT1, GPT4 |

No external blocker is declared as resolved by this register.

---

## 10. Update, handoff and rollback

### Update controls

- A daily execution log may add accepted evidence, status and risk updates but may not alter B0 scope, WDP, dependencies, baseline dates or acceptance criteria.
- A changed owner allocation inside an approved activity window must preserve its total WDP and daily ceiling; otherwise record an exception and recovery action.
- A change to scope, baseline dates, weights, dependencies, acceptance criteria or capacity assumptions requires a separate Baseline Change Record.
- A blocker open for more than two eligible business days, a milestone with less than 10% local capacity remaining, or `SPI < 0.90` requires a recovery plan.

### Handoff state

```text
Baseline B0: merged to main through PR #92.
This register: planned only; no WDP earned.
Current active candidate on 2026-07-06: F1-01.
Do not start F1-02 before F1-01 acceptance.
Do not use named pilot participants as evidence of consent, staffing, authorization or delivery.
```

### Rollback

Revert the documentation-only PR that introduces this register. No runtime, data, deployment or integration rollback is required.

---

## 11. Next safe action

On 2026-07-06, execute F1-01 CP1 only as planned, preserve the canonical evidence inventory, and record the result as accepted, rejected or blocked. Publish **0 WDP** unless a validator has accepted the checkpoint against its explicit criterion.
