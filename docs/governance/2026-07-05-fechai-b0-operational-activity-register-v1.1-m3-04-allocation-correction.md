# FECH.AI — B0 Operational Activity Register v1.1

**Status:** REGISTER_CONSISTENCY_CORRECTION / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Baseline identity:** B0  
**Register corrected:** `2026-07-05-fechai-b0-operational-activity-register-v1.md`  
**Effective date:** 2026-07-05  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Purpose and precedence

This correction resolves an arithmetic defect found during self-validation of the B0 operational activity register.

It is authoritative only for the **M3-04 owner-allocation row**. It supersedes the M3-04 allocation shown in `2026-07-05-fechai-b0-operational-activity-register-v1.md`.

No B0 scope, WDP, activity date, dependency, acceptance criterion, calendar, risk, runtime, frontend, Supabase, Vercel, integration or production behavior changes through this correction.

---

## 2. Finding classification

| Classification | Finding | Resolution |
|---|---|---|
| REQUIRED IN THIS PR | The v1.0 M3-04 allocation listed `GPT6: 4`, `GPT3: 6`, `GPT5: 4`, totaling 14 WDP while M3-04 is a 20-WDP activity. | Replace the allocation with an exact 20-WDP distribution below. |

The original v1.0 M3-04 row must not be used for capacity, forecast, workload or evidence planning after this correction.

---

## 3. Authoritative M3-04 allocation

**Activity:** M3-04 — Google/Meta tracking event contracts and validation  
**Activity WDP:** 20  
**Dates:** 2026-11-18 to 2026-12-02  
**Dependencies:** M3-01, M3-02, T2-08  
**Owner roles:** GPT6, GPT3, GPT5

| Owner role | Allocated WDP | Planned eligible dates | Daily ceiling check |
|---|---:|---|---|
| GPT6 | 6 | `2026-11-25: 3`; `2026-11-27: 3` | Pass — no date exceeds 3 WDP. |
| GPT3 | 8 | `2026-11-18: 3`; `2026-11-19: 3`; `2026-11-27: 2` | Pass — no date exceeds 3 WDP. |
| GPT5 | 6 | `2026-12-01: 3`; `2026-12-02: 3` | Pass — no date exceeds 3 WDP. |
| **Total** | **20** | — | Exact match to M3-04 WDP. |

### Cross-activity allocation check

- GPT3 M3-03 allocations are on 2026-11-25 and 2026-11-26; they do not overlap the corrected GPT3 allocation dates for M3-04.
- GPT6 M3-03 allocations are on 2026-11-18 and 2026-11-19; they do not overlap the corrected GPT6 allocation dates for M3-04.
- GPT5 has no conflicting B0 allocation on the corrected M3-04 dates.
- The correction retains the 3-WDP-per-role-per-eligible-day control.

---

## 4. What remains unchanged

```text
Portfolio: 23 activities / 300 WDP
M3-04 acceptance condition: unchanged
M3-04 dates: 2026-11-18 to 2026-12-02
M3-04 dependencies: M3-01, M3-02, T2-08
Portfolio EV at register initialization: 0 WDP
No delivery credit is created by this correction.
```

---

## 5. Next safe action

Read the B0 v1.0 baseline, B0 v1.3 baseline correction, B0 activity register v1.0 and this v1.1 correction in that order. Use this corrected M3-04 allocation in every future daily capacity, workload, forecast and evidence record.