# FECH.AI — Project Governance Dashboard / Baseline v1.1

**Status:** BASELINE_SCHEDULE_CORRECTION / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Supersedes:** the schedule and dependency-date portions of `docs/governance/2026-07-04-fechai-project-governance-dashboard-baseline-v1.md`  
**Baseline identity retained:** B0  
**Effective date:** 2026-07-04  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Purpose

This versioned correction resolves dependency-date overlaps found during validation of Baseline v1.0.

All unchanged sections of v1.0 remain in force, including:

- the three-MVP structure;
- 300 WDP total scope and 100 WDP per MVP;
- acceptance criteria, activity weights, transversal tags and gate rules;
- capacity assumption, Health Score, forecast, confidence model, risk register and BCR rules;
- the rule that PRs are evidence and traceability, not delivery value.

This document changes only the planned windows below so that a dependent activity does not start before the predecessor's planned completion. It does not create earned progress and does not alter scope or acceptance.

---

## 2. Corrected dependency scheduling rule

For every activity dependency:

```text
Dependent activity starts on the first eligible business day after
all blocking predecessor acceptance checkpoints are planned to finish.
```

A same-day handoff is allowed only where the activity explicitly contains a completed decision checkpoint and the schedule records the order. No such exception is used in the corrected plan below.

---

## 3. Corrected MVP 1 schedule — Família (100 WDP)

| ID | Milestone | Corrected planned dates | WDP | Dependencies |
|---|---|---|---:|---|
| F1-01 | M1 | 2026-07-06 to 2026-07-10 | 10 | B0 |
| F1-02 | M1 | 2026-07-13 to 2026-07-24 | 15 | F1-01 |
| F1-03 | M2 | 2026-07-27 to 2026-08-14 | 20 | F1-02 |
| F1-04 | M2 | 2026-08-03 to 2026-08-14 | 20 | F1-02 |
| F1-05 | M2 | 2026-08-17 to 2026-08-21 | 10 | F1-03, F1-04 |
| F1-06 | M3 | 2026-08-24 to 2026-09-04 | 10 | F1-04, F1-05 |
| F1-07 | M3 | 2026-09-07 to 2026-09-11 | 10 | F1-03 to F1-06 |
| F1-08 | M3 | 2026-09-14 to 2026-09-15 | 5 | F1-07 |

---

## 4. Corrected MVP 2 schedule — Tegra / cliente real (100 WDP)

| ID | Milestone | Corrected planned dates | WDP | Dependencies |
|---|---|---|---:|---|
| T2-01 | M3 | 2026-09-16 to 2026-09-18 | 10 | F1-08 |
| T2-02 | M4 | 2026-09-21 to 2026-10-02 | 15 | T2-01 |
| T2-03 | M4 | 2026-10-05 to 2026-10-14 | 20 | T2-02 |
| T2-04 | M4 | 2026-10-15 to 2026-10-16 | 10 | T2-03 |
| T2-05 | M5 | 2026-10-19 to 2026-10-30 | 15 | T2-04 |
| T2-06 | M5 | 2026-11-02 to 2026-11-06 | 15 | T2-05 |
| T2-07 | M5 | 2026-11-09 to 2026-11-12 | 10 | T2-06 |
| T2-08 | M5 | 2026-11-13 | 5 | T2-07 |

---

## 5. Corrected MVP 3 schedule — Mercado (100 WDP)

| ID | Milestone | Corrected planned dates | WDP | Dependencies |
|---|---|---|---:|---|
| M3-01 | M4 | 2026-10-05 to 2026-10-16 | 10 | F1-08 |
| M3-02 | M5 | 2026-10-19 to 2026-11-13 | 15 | M3-01 |
| M3-03 | M6 | 2026-11-16 to 2026-11-27 | 15 | M3-02, T2-08 |
| M3-04 | M6 | 2026-11-16 to 2026-12-02 | 20 | M3-01, M3-02, T2-08 |
| M3-05 | M6 | 2026-12-03 to 2026-12-09 | 15 | M3-03, M3-04 |
| M3-06 | M6 | 2026-12-10 to 2026-12-16 | 15 | M3-05 |
| M3-07 | M6 | 2026-12-17 to 2026-12-18 | 10 | M3-03 to M3-06 |

---

## 6. Validation result

| Validation | Result |
|---|---|
| Scope weights | Unchanged: MVP1 = 100 WDP, MVP2 = 100 WDP, MVP3 = 100 WDP, portfolio = 300 WDP. |
| Milestone allocation | Unchanged: M1 25, M2 50, M3 35, M4 55, M5 60, M6 75 WDP. |
| Dependency ordering | Corrected: every listed dependency now finishes before its dependent activity begins. |
| Baseline target finish | Unchanged: 2026-12-18. |
| Runtime / infrastructure | Unchanged: no runtime, frontend, Supabase, Vercel, integration or production change. |

---

## 7. Current-document reading order

1. Read Baseline v1.0 for full governance model, acceptance criteria, formulas and controls.
2. Read this v1.1 correction for the authoritative schedule/dependency dates.
3. Use `docs/governance/INDEX.md` as the current governance entry point.

---

## 8. Next safe action

Review the corrected schedule with the documentation PR diff. Once merged, create the B0 activity register using the v1.1 dates and retain B0 as the immutable comparison baseline.
