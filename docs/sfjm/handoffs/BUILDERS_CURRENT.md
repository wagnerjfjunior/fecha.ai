# FECH.AI — SFJM Builders Current Handoff

**Status:** `CURRENT_BUILDERS_HANDOFF / GROUP_A_RECONCILED / GROUP_B_GPT5_RECONCILIATION_ACTIVE / DOCUMENTATION_ONLY`  
**Reconstructed on:** `2026-08-03`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Observed canonical main:** `main@f4f77e2a159ec190173dc771b189909f589e9f91`  
**Active Builder track:** `GPT5 — SRE/DevSecOps Observability`

## 1. Purpose and boundary

This record preserves continuity for specialist Builder configuration, canonical skills, behavioral validation and safe transition between conversations.

It is separate from the product/security lifecycle in:

```text
docs/sfjm/handoffs/CURRENT.md
```

This Builder track does not approve runtime, Supabase, Vercel, production, Security Go, F1-02 acceptance or WDP. It does not operate product/security PRs.

## 2. Source hierarchy

```text
1. GitHub live and resolved main/ref
2. docs/bootstrap/INDEX.md
3. docs/skills/fechai-gpt-registry.md
4. specialist canonical skill
5. Modus Operandi and applicable governance/SFJM
6. this handoff
7. Product Authority-confirmed Builder state
8. historical uploads, prompts and memory
```

Evidence classes:

```text
CANONICAL_MAIN
PR_HEAD_ONLY
PRODUCT_AUTHORITY_CONFIRMED
BEHAVIORAL_TEST_PASSED
INFORMATION_SUPPLIED
EXTERNAL_BUILDER_NOT_REVALIDATED
```

No evidence class may be silently promoted into another.

## 3. Group A

GPT0, GPT1, GPT2, GPT3, GPT4, GPT7 and GPT8 remain canonically reconciled under the Group A closure. Do not rebuild them merely because Group B started.

Reopen only after material behavioral failure, canonical change, tool/configuration change, drift, explicit Product Authority decision or new evidence invalidating prior validation.

## 4. Group B current state

```text
GPT5 — RECONCILIATION_ACTIVE
GPT6 — PENDING_PARITY_AUDIT
GPT9 — PENDING_PARITY_AUDIT
GPT10 — PENDING_PARITY_AUDIT
```

Group B is handled as separate, bounded specialist work. Starting GPT5 does not authorize mutation of GPT6, GPT9 or GPT10.

## 5. GPT5 evidence reconstructed

### Canonical main

```text
Skill path:
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md

Main skill before this track:
v1.1 / blob d6bf7a043ecd8d74f9259d89bbae9c9cb06f89c7

Registry state:
Grupo B / PENDING_PARITY_AUDIT
```

### Product Authority-confirmed external Builder state

```text
Old GPT5 Knowledge files: DELETED
Configuration snapshot: title + description + Instructions + starters supplied
Knowledge target: EMPTY
```

The deletion of static files is intentional. GitHub live must supply current context.

### GitHub Action evidence

```text
Operation executed:
getFechaiRepository

Result:
SUCCESS

Repository:
wagnerjfjunior/fecha.ai

Default branch:
main
```

The response also exposed repository permissions equivalent to `admin`, `maintain`, `push`, `triage` and `pull`. This proves broad identity capability, not authorization to mutate.

Current contract:

```text
GitHub Action: REQUIRED
Default mode: READ_ONLY
Mutation authority: NONE unless separately explicit and exact
Minimum proven coverage: repository metadata only
```

Repository metadata alone does not satisfy Builder readiness. Behavioral PASS requires evidence that the Action fetched, from the exact resolved `main`, the bootstrap index, registry, canonical GPT5 skill, Modus Operandi, SFJM index and this handoff, recording path, ref, blob when available, coverage through EOF and limitations.

If the Action cannot read any mandatory canonical file, the result is `BUILDER_READINESS_FAILED / GITHUB_BOOTSTRAP_UNAVAILABLE` or `EVIDENCE_INCOMPLETE`, not PASS. If it cannot read additional commits, PRs, checks, jobs or logs needed for a conclusion, GPT5 must declare `GITHUB_OBSERVABILITY_EVIDENCE_INCOMPLETE` and route lifecycle/CI evidence to GPT4.

## 6. Direction approved by Product Authority

GPT5 must not be bound to a specific PR number.

Its operating objective is:

```text
reconstruct the broad AS-IS
identify operational risks and missing evidence
propose improvements for a robust, secure, recoverable and high-value SaaS
connect reliability to conversion, productivity, support, churn, margin and MRR
```

PRs, commits, workflows and deploys remain evidence and execution vehicles. They are not the specialist's permanent scope.

## 7. Active Git work and invalidation anchor

```text
Base:
main@f4f77e2a159ec190173dc771b189909f589e9f91

Active PR:
#113 — docs(skills): reconcile GPT5 SRE operating contract

Branch:
docs/group-b-gpt5-sre-reconciliation

Allowed files:
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md
docs/sfjm/handoffs/BUILDERS_CURRENT.md
```

### Non-self-referential lifecycle anchor

The exact baseline reviewed at the second Ready transition was:

```text
Reviewed head:
aec87b384d1744f02a3ede064e30310029353bb6

GPT5 skill blob at that head:
969abb867b78b622c62d92ef6de53f8c0599dda5

Builders handoff blob at that head:
b5c64c73a633c74f73add47f1b20481a8072b5c9
```

The first corrective commit after that review changed the GPT5 skill:

```text
Corrective parent head before this handoff update:
f3ae55306605b17158b977a3e8f6134b823b1726

Corrected GPT5 skill blob:
70e5b06dbb2be53fd2fee935b80a838b8d6486b2
```

This section is an **invalidation anchor**, not a claim that a documentation file can embed its own resulting commit or blob SHA. The final corrected PR head and the resulting blob of this handoff must be resolved live and recorded in PR metadata/audit evidence after publication of this edit. Any head or blob different from the reviewed baseline invalidates the prior GPT0, size, GPT4 and Ready gates. Branch A may continue only after fresh gates bind to the exact live corrected head.

The prohibition on permanent PR numbers applies to the specialist's durable operating contract. It does not prevent this SFJM lifecycle handoff from recording the active PR, branch, reviewed head and evidence blobs needed to detect drift.

Primary risk:

```text
GPT5 operating from a narrow, static or stale SRE contract that cannot
reconstruct the real SaaS AS-IS or propose evidence-based reliability evolution.
```

Rollback: one documentation revert. No runtime, data, Supabase or deployment rollback.

## 8. Explicit non-actions

```text
No runtime/frontend change
No Supabase/SQL/migration/RPC/RLS/policy/grant change
No Vercel or GitHub Actions change
No external Builder mutation through Git
No external Builder mutation without separate exact Product Authority authorization
No Ready
No merge
No deploy
No Security Go
No Product PASS
No changes to GPT6/GPT9/GPT10
```

## 9. Next safe action — state-dependent

Before selecting a branch below, resolve GitHub live and determine whether the candidate GPT5 skill is still `PR_HEAD_ONLY` or is already present on the current `main`. Compare the live PR/head/blobs with the invalidation anchor in section 7. Never replay completed lifecycle steps solely because this handoff was merged.

### Branch A — candidate not yet canonical on `main`

Use this branch only when the PR is still open and the candidate skill is absent from the resolved `main`.

1. resolve the exact live PR, branch, head and both final blobs;
2. if they differ from any previously gated baseline, invalidate all prior head-bound gates;
3. audit the exact Draft head with GPT0;
4. independently confirm that Builder Instructions remain below 8,000 characters;
5. validate lifecycle, checks, reviews, threads and drift with GPT4;
6. request Codex review while the PR is still Draft and close all material findings before lifecycle transition;
7. obtain separate Product Authority authorization for Ready only after zero material thread remains open;
8. after Ready, revalidate only for new external events; do not use Ready as a discovery mechanism;
9. obtain separate and later Product Authority authorization for merge;
10. do not update the external Builder, run behavioral tests or promote the registry before publication on `main`.

### Branch B — candidate already canonical on `main`

Use this branch only after an authorized merge and after the resolved `main` contains the candidate skill.

1. resolve the new `main` and record the merge commit;
2. confirm the final GPT5 skill and this handoff on that exact `main`, including blobs and EOF;
3. confirm the registry still records GPT5 as `PENDING_PARITY_AUDIT`;
4. obtain separate, explicit and delimited Product Authority authorization for the external GPT5 Builder mutation;
5. the authorization must identify the GPT, permitted fields, canonical source, exact operation, prohibitions, rollback and validation gate;
6. only under that authorization, update the external GPT5 title, description, Instructions and starters from the canonical skill;
7. keep Knowledge empty and the GitHub Action read-only;
8. run bounded behavioral tests for AS-IS, incident response, evidence, privilege refusal, roadmap and real canonical-file retrieval from the exact resolved `main`;
9. inability to fetch any mandatory canonical file is `BUILDER_READINESS_FAILED`, even when prompt-only answers appear correct;
10. if behavioral PASS is achieved, authorize a separate PR to reconcile the durable registry state;
11. only after registry reconciliation, continue to the next Group B specialist.

Merge authorization never includes Builder mutation. Builder capability, prior Builder state or a merged skill never substitutes for the separate authority required in steps 4–6.

### Branch C — PR closed without merge, head changed or state ambiguous

Stop and reconstruct the Builder track from GitHub live. Do not infer that the candidate was published, do not update the external Builder and do not promote the registry.

A test executed against a `PR_HEAD_ONLY` skill does not replace the post-merge test against the canonical `main`. The default sequence is publication first, separately authorized Builder update second.

A new conversation must resolve the live state, select the applicable branch above, read the exact skill and this handoff, and continue without relying on pasted chat history.
