# FECH.AI - Bootstrap Index

**Status:** BOOTSTRAP_INDEX / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE

This index lists bootstrap documents that must be used before starting sensitive FECH.AI conversations, PR validations, architecture decisions, security reviews, deploy decisions or handoffs.

---

## Mandatory bootstrap documents

### SaaS current state index

```text
docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md
```

Use for:

```text
- product identity;
- SaaS multi-tenant context;
- PR history;
- current architecture/security tracks;
- truth hierarchy;
- module/domain map.
```

### GPT specialists private index

```text
docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md
```

Use for:

```text
- specialist routing;
- GPT responsibility map;
- handoff between specialists;
- review role separation.
```

### Specialist modus operandi

```text
docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md
```

Use for:

```text
- mandatory bootstrap before acting;
- senior review posture;
- evidence vs inference vs missing evidence;
- finding classification;
- fail-closed security posture;
- scope and rollback discipline;
- documentation, index and handoff rules.
```

### Codex efficiency and GreenOps workflow

```text
docs/bootstrap/2026-06-12-fechai-codex-efficiency-greenops.md
```

Use for:

```text
- token and credit efficiency;
- Codex task envelope;
- ChatGPT / GitHub connector / Codex responsibility split;
- PR size discipline;
- GreenOps and reduced rework;
- avoiding broad repository scans when indexes or diffs are enough.
```

### Bootstrap governance cycle handoff

```text
docs/bootstrap/2026-06-12-fechai-bootstrap-governance-cycle-handoff.md
```

Use for:

```text
- handoff after PRs #85-#90;
- architecture / bootstrap / GreenOps / skills alignment chain;
- consolidated GPT0-GPT10 status;
- next-conversation startup context;
- rollback order for the documentation governance cycle.
```

---

## Active delivery governance baseline

### Project Governance Dashboard / Baseline B0

```text
docs/governance/INDEX.md
```

Use for:

```text
- current reading order for the immutable B0 execution baseline and its versioned schedule correction;
- MVP 1 Família, MVP 2 Tegra/cliente real and MVP 3 Mercado delivery structure;
- weighted delivery activities and acceptance criteria;
- baseline versus actual, capacity, forecast, Health Score and M1-M6 heatmap;
- blockers, risks, confidence and baseline-change control;
- PR/evidence traceability without PR-count-driven progress.
```

---

## Operational rule

Before sensitive work, specialists must not proceed directly to implementation, approval or merge/deploy recommendation.

Minimum required sequence:

```text
1. Read the relevant bootstrap documents.
2. Reconstruct context.
3. Identify evidence and missing evidence.
4. Classify risks.
5. Define the next safe action.
6. Leave handoff/index trail when needed.
```

Before expensive AI/Codex work, specialists must also ask:

```text
- Can README/index/bootstrap answer this first?
- Can GitHub connector validate this without Codex?
- Can Codex receive exact file scope instead of discovering it?
- Can this PR be smaller?
- Can rollback be one revert?
```
