# FECH.AI — Project Governance Dashboard / Baseline v1.2

**Status:** BASELINE_RECORD_COUNT_CORRECTION / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Supersedes:** only the activity-count references in Baseline v1.0  
**Baseline identity retained:** B0  
**Effective date:** 2026-07-04  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## Purpose

Validation of the weighted activity register identified a documentation count error in Baseline v1.0.

The baseline contains **23 activities**, not 24:

```text
MVP 1 — Família: 8 activities / 100 WDP
MVP 2 — Tegra / cliente real: 8 activities / 100 WDP
MVP 3 — Mercado: 7 activities / 100 WDP
Portfolio: 23 activities / 300 WDP
```

This correction changes only the two references that said "24 activities":

1. Baseline v1.0, Section 5 — Delivery scope is the sum of **23** weighted activities.
2. Baseline v1.0, Section 18 — the initial B0 register contains **23** baseline activities.

No activity, weight, dependency, acceptance criterion, milestone allocation, forecast formula, capacity assumption, target finish or runtime scope changes.

---

## Validation

| Check | Result |
|---|---|
| MVP1 weights | 100 WDP across 8 activities |
| MVP2 weights | 100 WDP across 8 activities |
| MVP3 weights | 100 WDP across 7 activities |
| Portfolio weight | 300 WDP across 23 activities |
| Baseline target finish | unchanged: 2026-12-18 |
| Runtime / infrastructure | unchanged: no runtime, frontend, Supabase, Vercel, integration or production change |

---

## Current-document reading order

1. Baseline v1.0 — full governance model.
2. Baseline v1.1 — authoritative schedule/dependency correction.
3. This v1.2 — authoritative activity-count correction.
4. `docs/governance/INDEX.md` — current governance entry point.

---

## Next safe action

Create the B0 activity register with exactly the 23 activity IDs defined by Baseline v1.0, using the corrected v1.1 dates and retaining total baseline scope of 300 WDP.
