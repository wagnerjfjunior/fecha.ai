# FECH.AI — Governance Documentation Index

**Status:** DOCUMENTATION_INDEX / NO_RUNTIME_CHANGE  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## Current execution baseline

Read in this order:

1. `2026-07-04-fechai-project-governance-dashboard-baseline-v1.md`  
   Full B0 governance model: scope, weights, acceptance, capacity, forecast, Health Score, confidence, heatmap, risks and update controls.

2. `2026-07-04-fechai-project-governance-dashboard-baseline-v1.3-consistency-correction.md`  
   Authoritative pre-execution correction for activity count, dates, dependencies, federal-holiday capacity, forecast fallback, Health Score, owner allocation and transversal heatmap.

3. `2026-07-05-fechai-b0-operational-activity-register-v1.md`  
   Initial B0 operating ledger: exactly 23 activities / 300 WDP, v1.3 dates, explicit dependencies, owner-allocation plan, zero-credit initialization, risk register and the 2026-07-06 daily plan.

4. `2026-07-05-fechai-b0-operational-activity-register-v1.1-m3-04-allocation-correction.md`  
   Authoritative correction for the M3-04 owner-allocation row. It replaces the v1.0 14-WDP arithmetic defect with the exact 20-WDP allocation; all other register content remains unchanged.

The v1.1 and v1.2 **baseline** files remain traceability records. Where they conflict with baseline v1.3, v1.3 is authoritative. The B0 activity-register v1.1 correction is authoritative only for M3-04 allocation.

The activity register may add evidence, actual status and daily execution records, but it may not rewrite B0 scope, weights, baseline dates, dependencies or acceptance criteria without a separate Baseline Change Record.

The B0 baseline and operating register are documentation-only. They do not authorize runtime, frontend, Supabase, migration, RLS, RPC, Vercel, integration or production changes.

## Core rule

Progress is earned by weighted delivery activities with verified acceptance criteria. PRs are traceability/evidence; a PR is not a unit of value.
