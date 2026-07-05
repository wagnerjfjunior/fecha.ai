# FECH.AI — Project Governance Dashboard / Baseline v1.3

**Status:** BASELINE_CONSISTENCY_CORRECTION / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Baseline identity retained:** B0  
**Effective date:** 2026-07-04  
**Applies before execution measurement begins:** yes  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Purpose

This correction closes the remaining governance-consistency findings identified during PR review.

It consolidates the authoritative operational corrections for:

- dependency ordering and explicit dependency IDs;
- activity record count;
- Brazil federal-holiday calendar capacity;
- milestone dates and target finish;
- forecast fallback logic;
- Health Score composition;
- owner-capacity allocation rule;
- transversal-track heatmap derivation.

Baseline v1.0 remains the full specification. Where this document conflicts with v1.0, v1.1 or v1.2, this v1.3 document is authoritative.

This correction does not authorize or change runtime, frontend, Supabase, migrations, RLS, grants, policies, RPCs, Edge Functions, Vercel configuration, GitHub Actions, integrations or production behavior.

---

## 2. Corrected B0 calendar and capacity

B0 uses the Brazil **federal** business calendar for planned-value and capacity calculations. State or municipal holidays are not presumed inside B0; they must be registered as a local availability exception before they affect PV, capacity or forecast.

Federal holidays inside the B0 delivery window are excluded:

```text
2026-09-07
2026-10-12
2026-11-02
2026-11-20
```

| Milestone | Corrected period | Eligible business days | Planning capacity | Scoped WDP | Reserve |
|---|---|---:|---:|---:|---:|
| M1 | 2026-07-06 to 2026-07-24 | 15 | 45 | 25 | 20 |
| M2 | 2026-07-27 to 2026-08-21 | 20 | 60 | 50 | 10 |
| M3 | 2026-08-24 to 2026-09-18 | 19 | 57 | 35 | 22 |
| M4 | 2026-09-21 to 2026-10-16 | 19 | 57 | 55 | 2 |
| M5 | 2026-10-19 to 2026-11-17 | 21 | 63 | 60 | 3 |
| M6 | 2026-11-18 to 2026-12-23 | 25 | 75 | 75 | 0 |
| **Portfolio** | 2026-07-06 to 2026-12-23 | **119** | **357** | **300** | **57** |

Therefore:

```text
Baseline planning capacity remains 3 WDP per eligible business day.
Baseline calendar capacity is corrected from 360 WDP to 357 WDP.
Portfolio schedule reserve is corrected from 60 WDP / 20% to 57 WDP / 19%.
Baseline target finish is corrected from 2026-12-18 to 2026-12-23.
```

This is a pre-execution baseline correction. It does not alter the 300 WDP scope or earn progress.

---

## 3. Corrected dependency and activity-count rules

### 3.1 Activity count

```text
MVP 1 — Família: 8 activities / 100 WDP
MVP 2 — Tegra / cliente real: 8 activities / 100 WDP
MVP 3 — Mercado: 7 activities / 100 WDP
Portfolio: 23 activities / 300 WDP
```

### 3.2 Explicit dependency IDs

Register dependencies must use explicit IDs. Range notation is not valid in the execution register.

| Activity | Authoritative dependency IDs |
|---|---|
| F1-07 | F1-03, F1-04, F1-05, F1-06 |
| M3-07 | M3-03, M3-04, M3-05, M3-06 |

All other dependency IDs remain as written in v1.0 unless superseded by the dates below.

### 3.3 Corrected schedule

| ID | Corrected planned dates | Dependencies |
|---|---|---|
| F1-01 | 2026-07-06 to 2026-07-10 | B0 |
| F1-02 | 2026-07-13 to 2026-07-24 | F1-01 |
| F1-03 | 2026-07-27 to 2026-08-14 | F1-02 |
| F1-04 | 2026-08-03 to 2026-08-14 | F1-02 |
| F1-05 | 2026-08-17 to 2026-08-21 | F1-03, F1-04 |
| F1-06 | 2026-08-24 to 2026-09-04 | F1-04, F1-05 |
| F1-07 | 2026-09-07 to 2026-09-11 | F1-03, F1-04, F1-05, F1-06 |
| F1-08 | 2026-09-14 to 2026-09-15 | F1-07 |
| T2-01 | 2026-09-16 to 2026-09-18 | F1-08 |
| T2-02 | 2026-09-21 to 2026-10-02 | T2-01 |
| T2-03 | 2026-10-05 to 2026-10-14 | T2-02 |
| T2-04 | 2026-10-15 to 2026-10-16 | T2-03 |
| T2-05 | 2026-10-19 to 2026-10-30 | T2-04 |
| T2-06 | 2026-11-03 to 2026-11-09 | T2-05 |
| T2-07 | 2026-11-10 to 2026-11-13 | T2-06 |
| T2-08 | 2026-11-16 to 2026-11-17 | T2-07 |
| M3-01 | 2026-10-05 to 2026-10-16 | F1-08 |
| M3-02 | 2026-10-19 to 2026-11-17 | M3-01 |
| M3-03 | 2026-11-18 to 2026-11-27 | M3-02, T2-08 |
| M3-04 | 2026-11-18 to 2026-12-02 | M3-01, M3-02, T2-08 |
| M3-05 | 2026-12-03 to 2026-12-09 | M3-03, M3-04 |
| M3-06 | 2026-12-10 to 2026-12-16 | M3-05 |
| M3-07 | 2026-12-17 to 2026-12-23 | M3-03, M3-04, M3-05, M3-06 |

No dependent activity begins before all listed predecessor activities are planned to complete.

---

## 4. Corrected forecast fallback

The forecast must not call `ActualCapacity3W` before three completed eligible weeks exist.

```text
RemainingWDP = 300 - EV

ForecastCapacity =
  ActualCapacity3W / 5,
    when at least 15 eligible business days and 3 completed eligible weeks exist;

  ActualCapacity10,
    when at least 10 eligible business days exist but the 3-week sample does not;

  3 WDP/day,
    before 10 eligible business days of accepted-data history exist.

RiskBufferWDP = Σ(remaining activity weight × active risk factor)
ForecastDays = ceil((RemainingWDP + RiskBufferWDP) / ForecastCapacity)
ForecastFinish = next eligible business date after ForecastDays
```

`ActualCapacity10` is the accepted WDP in the last 10 eligible business days divided by the number of eligible days in that sample.

Forecast confidence remains LOW until the evidence-confidence criteria in v1.0 are met.

---

## 5. Corrected Health Score composition

Portfolio completion remains a primary dashboard metric:

```text
PortfolioCompletion = 100 × EV / 300
```

It is not a Health Score factor because schedule performance is already represented by `SPI = EV / PV`.

```text
HealthScore =
  0.40 × ScheduleIndex +
  0.15 × CadenceIndex +
  0.20 × RiskIndex +
  0.25 × ConfidenceIndex
```

```text
ScheduleIndex = min(100, 100 × SPI)
CadenceIndex = max(0, 100 - 12 × max(0, DaysWithoutExecution - 1))
```

Before the first planned delivery day, Health Score is `NOT_STARTED`, not a numerical status. This removes the duplicated use of `EV / PV` while retaining portfolio completion as a separate executive measure.

---

## 6. Corrected owner-capacity rule

WDP is portfolio delivery value. An activity with multiple owners must not be assumed to consume its full WDP weight independently from every listed role.

Before daily capacity is assessed, every active activity must have an `owner_allocation` record:

```text
activity_id
owner_role
allocated_wdp
planned eligible dates
```

Rules:

1. Allocated WDP across owner roles must sum exactly to the activity WDP.
2. A co-owner or validator receives only the WDP explicitly allocated to that role.
3. No owner role may carry more than 3 allocated WDP per eligible business day without a recorded exception.
4. M3-05 ends on 2026-12-09 and M3-06 starts on 2026-12-10; the prior concurrent-overload condition is removed.

---

## 7. Corrected transversal intensity heatmap

Heatmap intensity is derived from activity tags and WDP in the milestone. It is not a subjective staffing signal.

Legend:

```text
H = >= 15 tagged WDP
M = 5 to 14 tagged WDP
L = 1 to 4 tagged WDP
— = 0 tagged WDP
```

| Track | M1 | M2 | M3 | M4 | M5 | M6 |
|---|---|---|---|---|---|---|
| Security | H | H | H | H | H | H |
| Architecture | H | H | M | H | H | H |
| CI/CD | H | H | M | H | M | H |
| Documentation | H | H | H | H | H | H |
| LGPD | — | — | H | H | H | H |
| Observability | — | H | H | H | H | H |

The portfolio total remains 300 WDP. Tagged-track WDP are cross-cutting analytical slices and must not be summed as portfolio delivery value.

---

## 8. Reading order and next safe action

Current reading order:

1. `2026-07-04-fechai-project-governance-dashboard-baseline-v1.md` — full B0 governance model.
2. This v1.3 document — authoritative pre-execution consistency corrections.
3. `docs/governance/INDEX.md` — governance entry point.

The earlier v1.1 and v1.2 correction files remain traceability records but are superseded by v1.3 where an operational rule conflicts.

After this PR is merged, create the B0 activity register with exactly 23 activities, the v1.3 dates, explicit dependencies and owner-allocation records. No delivery percentage may be published until checkpoint-level evidence exists.
