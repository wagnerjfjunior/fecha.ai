# FECH.AI — B0 Operational Activity Register v1.2

**Status:** REGISTER_CONSISTENCY_CORRECTION / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Baseline identity:** B0  
**Register corrected:** `2026-07-05-fechai-b0-operational-activity-register-v1.md`  
**Effective date:** 2026-07-05  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Purpose and precedence

This correction restores the authoritative B0 v1.3 planned window for F1-07.

It is authoritative only for the **F1-07 planned-date field** in the B0 operational activity register. It supersedes the `2026-09-08 to 2026-09-11` notation in register v1.0.

No B0 scope, WDP, activity dependency, acceptance criterion, capacity rule, runtime, frontend, Supabase, Vercel, integration or production behavior changes through this correction.

---

## 2. Finding classification

| Classification | Finding | Resolution |
|---|---|---|
| REQUIRED IN THIS PR | Register v1.0 starts F1-07 on 2026-09-08, while authoritative B0 v1.3 sets the activity window to 2026-09-07 through 2026-09-11. | Restore the exact v1.3 activity window below. |

---

## 3. Authoritative F1-07 schedule record

**Activity:** F1-07 — Family pilot execution  
**WDP:** 10  
**Dependencies:** F1-03, F1-04, F1-05, F1-06  
**Authoritative planned window:** `2026-09-07 to 2026-09-11`

### Calendar and allocation interpretation

- `2026-09-07` is a Brazil federal holiday and therefore has **0 WDP planned capacity** under B0 v1.3.
- The F1-07 owner-allocation plan begins on `2026-09-08`; that allocation remains valid and unchanged.
- PV and daily-capacity calculations must use the eligible dates inside the authoritative window: `2026-09-08`, `2026-09-09`, `2026-09-10`, `2026-09-11`.
- The correction restores date traceability; it does not add delivery credit or change the 10-WDP activity weight.

---

## 4. What remains unchanged

```text
F1-07 WDP: 10
F1-07 dependencies: F1-03, F1-04, F1-05, F1-06
F1-07 acceptance criterion: unchanged
F1-07 owner allocations: unchanged
Portfolio: 23 activities / 300 WDP
Portfolio EV at register initialization: 0 WDP
```

---

## 5. Next safe action

Read the B0 v1.0 baseline, B0 v1.3 baseline correction, B0 activity register v1.0, the M3-04 v1.1 correction, and this F1-07 v1.2 correction in that order. Use the restored F1-07 date range in all future PV, capacity, workload and evidence records.