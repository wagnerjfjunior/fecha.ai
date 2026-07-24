# FECH.AI — SFJM Operational Continuity Index

**Status:** OPERATIONAL_CONTINUITY_V1 / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Purpose

SFJM is the transversal continuity and operational-state layer for FECH.AI.

It preserves, between conversations, agents, specialists, executors, auditors, pull requests and operational transitions:

- the current verified state;
- the next single safe action;
- blocked actions;
- active authorizations and their limits;
- evidence freshness;
- the current handoff.

SFJM is not a CRM module, product feature, business authority, security boundary or substitute for GitHub, Supabase, Vercel, the B0 governance baseline or FECH.AI specialists.

## 2. Responsibility boundaries

```text
Bootstrap = how context is reconstructed before acting.
B0 governance = what must be delivered, dependencies, acceptance and measurement.
SFJM = the current operational state and continuity between executions.
GitHub = versioned code, documentation, PRs, commits and history.
Supabase/Vercel = applied environment state and live operational evidence.
```

SFJM does not:

- grant Security Go;
- authorize implementation merely by recording an action;
- validate tenant, company, profile or permission;
- replace RLS, grants, policies, RPC validation or backend authorization;
- convert memory, chat text, screenshots or unverified summaries into canonical evidence;
- count PRs or documents as earned product value.

The FECH.AI architecture principle remains:

```text
Frontend requests and displays.
Backend/RPC/Supabase validates and decides.
AI assists, but is not authority.
```

## 3. Mandatory reading order

Before sensitive FECH.AI work, read in this order:

1. `docs/bootstrap/INDEX.md`
2. `docs/governance/INDEX.md`
3. `docs/sfjm/INDEX.md`
4. `docs/sfjm/CURRENT_STATE.md`
5. `docs/sfjm/NEXT_SAFE_ACTION.md`
6. `docs/sfjm/BLOCKED_ACTIONS.md`
7. `docs/sfjm/AUTHORIZATIONS.md`
8. `docs/sfjm/EVIDENCE_FRESHNESS.md`
9. `docs/sfjm/handoffs/CURRENT.md`

Then validate live GitHub state and any required external evidence before proposing implementation, approval, merge or deploy.

## 4. Operational states v1

The initial SFJM lifecycle uses the following states:

```text
CONTEXT_NOT_RECONSTRUCTED
CONTEXT_CONFIRMED
EVIDENCE_INCOMPLETE
AUTHORIZED_FOR_IMPLEMENTATION
READY_FOR_INDEPENDENT_AUDIT
AUDIT_FAILED
AUDIT_PASSED
RECONCILED
```

No agent may move directly from `CONTEXT_NOT_RECONSTRUCTED` to implementation. No merge or deployment conclusion may be inferred from implementation alone.

## 5. Evidence and authority rule

Operational records must distinguish:

- verified evidence;
- information supplied by Wagner;
- inference;
- missing evidence;
- out-of-scope items;
- the next single safe action.

When GitHub, live environment evidence and documentation disagree, use the FECH.AI truth hierarchy and declare the divergence explicitly.

## 6. Change discipline

Every relevant SFJM update must preserve:

```text
one PR = one primary risk = one simple rollback
```

An SFJM update must not silently expand into runtime, Supabase, Vercel, MesaCliente, PME, ADS/CAPI, Make/n8n, integration or production changes.

## 7. Current operational records

- Current state: `docs/sfjm/CURRENT_STATE.md`
- Next safe action: `docs/sfjm/NEXT_SAFE_ACTION.md`
- Blocked actions: `docs/sfjm/BLOCKED_ACTIONS.md`
- Authorizations: `docs/sfjm/AUTHORIZATIONS.md`
- Evidence freshness: `docs/sfjm/EVIDENCE_FRESHNESS.md`
- Current handoff: `docs/sfjm/handoffs/CURRENT.md`

## 8. Update rule

Update SFJM records when any of the following changes:

- canonical `main`;
- active PR or head SHA;
- authorization scope;
- evidence freshness;
- audit decision;
- active B0 activity;
- blocker;
- next safe action;
- handoff ownership or transition state.

A stale SFJM record must be treated as evidence requiring reconciliation, not as current truth.