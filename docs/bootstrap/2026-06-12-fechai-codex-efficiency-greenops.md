# FECH.AI - Codex Efficiency and GreenOps Workflow

**Date:** 2026-06-12  
**Status:** BOOTSTRAP_OPERATIONAL / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Scope:** ChatGPT, GitHub connector, Codex, PR workflow, token efficiency and ecological responsibility

---

## 1. Purpose

This document defines the operational workflow for using ChatGPT, GitHub connector and Codex in FECH.AI with lower token usage, lower credit consumption, less rework and reduced environmental waste.

The goal is not to stop using Codex. The goal is to use Codex only where it adds value: small, scoped execution tasks after context, risk and acceptance criteria are already defined.

FECH.AI is Pilot Production multi-tenant / multi-company. It has real users, active modules and sensitive lead/client data. Token efficiency must not reduce security discipline. Efficiency and safety must work together.

---

## 2. Operating principle

```text
ChatGPT and GitHub connector decide, validate and reduce scope.
Codex executes small, bounded repository tasks.
```

Codex must not be used as the first tool to discover broad project context when the repository already has bootstrap, indexes and prior PR evidence.

Before Codex is used, the task must already define:

```text
- repository;
- base branch;
- objective;
- allowed files;
- forbidden areas;
- acceptance criteria;
- validation expected;
- rollback;
- whether PR must be draft or ready for review.
```

---

## 3. Cost and token control rules

Avoid prompts such as:

```text
Analyze the whole project and improve what you find.
Review all docs and fix anything necessary.
Inspect the repo and decide the next architecture.
```

Use bounded prompts such as:

```text
Update only README.md to point to docs/bootstrap/INDEX.md.
Do not alter runtime, frontend, Supabase, migrations, RLS, grants, policies or RPC bodies.
Open a draft PR.
```

Operational rule:

```text
Do not spend tokens rediscovering what is already documented.
Do not spend Codex cycles deciding what ChatGPT/GitHub connector can validate first.
Do not send large context when a short bootstrap and exact file list is enough.
```

---

## 4. Tool responsibility split

### 4.1 ChatGPT

Use ChatGPT for:

```text
- reasoning and planning;
- scope reduction;
- risk classification;
- acceptance criteria;
- PR review synthesis;
- handoff creation;
- deciding whether Codex is needed.
```

### 4.2 GitHub connector

Use GitHub connector for:

```text
- PR metadata;
- changed files;
- patches/diffs;
- comments/review threads;
- commit status/checks;
- creating small documentation PRs when safe;
- closing superseded PRs;
- validating head/base/mergeability.
```

### 4.3 Codex

Use Codex for:

```text
- implementation tasks with exact files;
- local validation requiring repo checkout;
- tests/build/lint when needed;
- multi-file code edits that are still scoped;
- mechanical refactors after scope approval.
```

Codex should not be the primary place for broad strategy, product architecture or security decision-making.

---

## 5. Mandatory Codex task envelope

Every FECH.AI Codex task should use this envelope:

```text
Repo:
wagnerjfjunior/fecha.ai

Base branch:
main

Task type:
documentation | bugfix | security | CI | refactor | test

Objective:
[one sentence]

Allowed files:
- [file 1]
- [file 2]

Do not alter:
- runtime unless explicitly in scope
- frontend unless explicitly in scope
- Supabase
- migrations
- RLS
- grants
- policies
- RPC bodies
- Edge Functions
- Vercel production config
- MesaCliente
- PME
- Discador
- ADS/CAPI
- Make/n8n
- unrelated files

Acceptance criteria:
- [criteria]

Validation:
- git diff --check
- npm test/build/lint only if relevant
- confirm changed files match scope

Rollback:
- revert PR

Delivery:
- branch codex/[short-name] or docs/[short-name]
- small commit
- draft PR unless requested otherwise
```

---

## 6. PR discipline

FECH.AI must preserve this rule:

```text
One PR = one main risk = one simple rollback.
```

Do not mix:

```text
- docs + runtime;
- refactor + security;
- frontend + Supabase;
- migrations + UI;
- tracking + LeadOps;
- MesaCliente + Discador;
- Codex workflow + product architecture.
```

A PR should be small enough that a reviewer can answer:

```text
What changed?
Why?
What is the risk?
How do we rollback?
What was intentionally not changed?
```

---

## 7. GreenOps rule

Token usage, credits, time and compute are operational resources.

Waste patterns:

```text
- repeated context reconstruction;
- large pasted histories;
- broad Codex tasks;
- asking multiple agents to re-read the same files without narrowing scope;
- validating unchanged areas;
- running long repo analysis when a diff is enough.
```

GreenOps behavior:

```text
- use indexes first;
- use PR/head/diff instead of whole-repo reading;
- validate only files in scope;
- prefer connector metadata before Codex execution;
- create handoff after significant decisions;
- close superseded PRs;
- keep Project Sources small and current.
```

---

## 8. Minimum bootstrap before expensive work

Before Codex or any broad AI task is used, reconstruct:

```text
- Context understood:
- Affected module/flow:
- Environment:
- PR/branch/head/commit, if any:
- Files/areas involved:
- Relevant prior decisions:
- Main risks:
- What must not be changed:
- Evidence available:
- Evidence missing:
- Next safe action:
```

If this bootstrap cannot be completed, the task must be narrowed before execution.

---

## 9. Relationship with existing FECH.AI rules

This workflow does not replace:

```text
docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md
docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md
docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md
```

It adds an operational layer focused on efficient and responsible AI-assisted execution.

Canonical FECH.AI principle remains:

```text
Frontend displays and requests.
Backend/RPC/Supabase validates and decides.
AI assists, but is not authority.
```

---

## 10. Practical next-step rule

Before creating any new technical PR, ask:

```text
Can this be answered by README/index/bootstrap first?
Can GitHub connector validate this without Codex?
Can Codex receive exact file scope instead of discovering it?
Can this PR be smaller?
Can rollback be one revert?
```

If the answer is no, do not start execution yet. Narrow the task first.
