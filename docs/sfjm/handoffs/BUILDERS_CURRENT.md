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

Repository metadata alone does not satisfy Builder readiness.

For Builder configuration and behavioral validation, the required live-source set is:

```text
COMMON BOOTSTRAP — always required
- docs/bootstrap/INDEX.md
- docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md
- docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md
- docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md
- docs/bootstrap/2026-06-12-fechai-codex-efficiency-greenops.md
- docs/bootstrap/2026-06-12-fechai-bootstrap-governance-cycle-handoff.md
- docs/skills/fechai-gpt-registry.md
- docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md

BUILDER CONTINUITY — required for this track
- docs/sfjm/INDEX.md
- docs/sfjm/CURRENT_STATE.md
- docs/sfjm/NEXT_SAFE_ACTION.md
- docs/sfjm/BLOCKED_ACTIONS.md
- docs/sfjm/AUTHORIZATIONS.md
- docs/sfjm/EVIDENCE_FRESHNESS.md
- docs/sfjm/handoffs/CURRENT.md
- docs/sfjm/handoffs/BUILDERS_CURRENT.md

CONDITIONAL GOVERNANCE — required when the request involves delivery,
acceptance, WDP, capacity, forecast, dependency, Health Score, risk or plan
- docs/governance/INDEX.md
- additional governance records resolved by that index and material to the request
```

Behavioral PASS requires evidence that the Action fetched every applicable source from the exact resolved `main`, recording path, ref, blob when available, coverage through EOF and limitations. Skipping a conditional source requires an explicit applicability decision; silence is not evidence that it was unnecessary.

If the Action cannot read any mandatory or applicable canonical file, the result is `BUILDER_READINESS_FAILED / GITHUB_BOOTSTRAP_UNAVAILABLE` or `EVIDENCE_INCOMPLETE`, not PASS. If it cannot read additional commits, PRs, checks, jobs or logs needed for a conclusion, GPT5 must declare `GITHUB_OBSERVABILITY_EVIDENCE_INCOMPLETE` and route lifecycle/CI evidence to GPT4.

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

The first corrective pair produced the first Draft review baseline:

```text
Draft review head:
5a4cfabece98d07d672d3b95e90113497c1fd509

Corrected GPT5 skill blob:
70e5b06dbb2be53fd2fee935b80a838b8d6486b2

Corrected Builders handoff blob:
dca44c7b111f6541cd151a31e457fd74f15589e6
```

The second corrective pair produced the next Draft review baseline:

```text
Draft review head:
ad673ce7853a77c55bac6377dd2ebe20c8b3ec15

Corrected GPT5 skill blob:
4629a8234c910bf4fe87139d90bf1184d3670fad

Corrected Builders handoff blob:
7264ed8d6a9cbf8276f142d272efc5dfa00e3d36
```

This section is an **invalidation anchor**, not a claim that a documentation file can embed its own resulting commit or blob SHA. The final corrected PR head and the resulting blob of this handoff must be resolved live and recorded in PR metadata/audit evidence after publication of later edits. Any head or blob different from a reviewed baseline invalidates only the gates bound to that baseline. For an **open PR**, a changed head remains in Branch A and requires fresh head-bound gates. Branch C is not selected merely because an authorized corrective commit changed an open PR head.

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

## 9. Next safe action — mutually exclusive branches

Before selecting a branch below, resolve GitHub live and determine whether the candidate GPT5 skill is still `PR_HEAD_ONLY` or is already present on the current `main`. Compare the live PR/head/blobs with the invalidation anchor in section 7. The branches below are mutually exclusive.

### Branch A — open PR; candidate not yet canonical on `main`

Use this branch whenever the publication PR is open and the candidate skill is absent from the resolved `main`, including when authorized corrective commits changed the head.

1. resolve the exact live PR, branch, head and both final blobs;
2. if they differ from any previously gated baseline, invalidate all prior head-bound gates;
3. audit the exact Draft head with GPT0;
4. independently confirm that Builder Instructions remain below 8,000 characters;
5. validate lifecycle, checks, reviews, threads and drift with GPT4;
6. before posting `@codex review`, requesting a reviewer or submitting any review/comment, obtain exact Product Authority authorization for that GitHub mutation;
7. the review-request authority must identify repository, PR, exact head, permitted comment/review operation, scope, prohibitions and whether thread replies/resolution are included;
8. only under that authority, request Codex review while the PR is still Draft;
9. correct material findings within the separately authorized file scope; before replying to or resolving threads, confirm that the authority covers those exact mutations;
10. repeat Draft review until the exact head has zero material thread open;
11. obtain separate Product Authority authorization for Ready only after the Draft review cycle is clean;
12. after Ready, revalidate only for new external events; do not use Ready as a discovery mechanism;
13. obtain separate and later Product Authority authorization for merge;
14. do not update the external Builder, run behavioral tests or promote the registry before publication on `main`.

### Branch B — candidate already canonical on `main`

Use this branch only after an authorized merge and after the resolved `main` contains the candidate skill.

1. resolve the new `main` and record the merge commit;
2. confirm the final GPT5 skill and this handoff on that exact `main`, including blobs and EOF;
3. confirm the registry still records GPT5 as `PENDING_PARITY_AUDIT`;
4. obtain separate, explicit and delimited Product Authority authorization for the external GPT5 Builder mutation;
5. the authorization must identify the GPT, permitted fields, canonical source, exact operation, prohibitions, validation gate and rollback; before mutation, preserve a safe last-known-good configuration snapshot or non-secret fingerprint sufficient for rollback;
6. only under that authorization, update the external GPT5 title, description, Instructions and starters from the canonical skill;
7. keep Knowledge empty and the GitHub Action read-only;
8. run bounded behavioral tests for AS-IS, incident response, evidence, privilege refusal, roadmap and real canonical-file retrieval from the exact resolved `main`;
9. apply the full source set and applicability rules from section 5; inability to fetch any mandatory or applicable source is `BUILDER_READINESS_FAILED`, even when prompt-only answers appear correct;

#### Branch B-PASS — all readiness gates pass

10. preserve a complete PASS evidence package containing:
    - exact resolved `main` and merge commit;
    - canonical GPT5 skill path and blob;
    - non-secret fingerprints of applied title, description, Instructions and starters;
    - Knowledge state and GitHub Action mode/schema evidence;
    - Product Authority Builder-mutation authorization and its exact scope;
    - coverage matrix for every mandatory and applicable canonical source;
    - behavioral tests, prompts, results, timestamps and limitations;
    - rollback snapshot/fingerprint and residual risks;
11. stop and obtain a new explicit, delimited Product Authority authorization for one bounded GPT5 closure PR;
12. that closure authorization must identify repository, base, permitted files, objective, prohibitions, rollback and validation gates;
13. the GPT5 closure PR must reconcile all durable markers together:
    - `docs/skills/fechai-gpt-registry.md`: publish the reconciled GPT5 registry state;
    - `docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md`: replace `v2.0-candidate / ...RECONCILIATION` with the approved reconciled status;
    - `docs/sfjm/handoffs/BUILDERS_CURRENT.md`: embed the non-secret PASS evidence package, mark GPT5 reconciled, close the active GPT5 track and record the next Group B specialist;
14. behavioral PASS, merge of this publication PR or tool capability does not authorize the closure PR;
15. only after the authorized closure PR passes its gates, merges, and the resulting `main` is confirmed may work advance to the next Group B specialist.

#### Branch B-FAIL — any readiness or canonical-file gate fails

10. classify `BUILDER_READINESS_FAILED` and preserve the exact failure evidence, failed source/test, current Builder fingerprint, resolved `main`, timestamps and limitations;
11. do not change registry status, do not open the closure PR and do not advance Group B;
12. if the original Builder-mutation authority explicitly included rollback, restore the last-known-good Builder configuration and verify the restored fingerprint;
13. if rollback was not included, stop and obtain separate exact Product Authority authorization before any rollback mutation;
14. if the failure is caused by missing GitHub file-read capability or Action configuration, obtain separate bounded Product Authority authorization for the exact Action/Builder remediation; do not change GitHub repository permissions, Supabase, runtime or production as an implied fix;
15. after authorized remediation or rollback, rerun the complete applicable source coverage and behavioral suite against the then-current canonical `main`;
16. keep GPT5 `RECONCILIATION_ACTIVE` and the registry `PENDING_PARITY_AUDIT` until Branch B-PASS and the later authorized closure PR both complete.

Merge authorization never includes Builder mutation. Builder authorization never includes registry/skill/handoff closure. Each lifecycle mutation requires its own exact authority.

### Branch C — PR closed without merge or materially ambiguous state

Use this branch only when the publication PR is closed without merge, missing, replaced without an anchored successor, or when live evidence cannot determine whether the candidate was published. Do not select Branch C for an open PR merely because its head changed; that case belongs to Branch A with fresh gates.

Stop and reconstruct the Builder track from GitHub live. Do not infer that the candidate was published, do not update the external Builder and do not promote or reconcile the registry.

A test executed against a `PR_HEAD_ONLY` skill does not replace the post-merge test against the canonical `main`. The default sequence is publication first, separately authorized Builder update second, separately authorized durable closure third.

A new conversation must resolve the live state, select exactly one applicable branch above, read the exact skill and this handoff, and continue without relying on pasted chat history.
