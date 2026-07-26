# FECH.AI — SFJM Next Safe Action

**Status:** `NEXT_SAFE_ACTION / PR104_FINAL_HEAD_GPT0_AUDIT`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Current safe state

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #102: CLOSED / MERGED
PR #103: OPEN / DRAFT / FROZEN
PR #103 head: abf6b4026343eae437283280269ed2997911dcec
PR #104: OPEN / DRAFT
PR #104 base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
```

PR #104 versions a bounded GPT3 catalog gateway. It does not apply the migration, deploy the Edge Function or alter the GPT Action live.

## 2. Exact next action

After the declared ten-path Draft scope is complete, run GPT0 against the exact live PR #104 head.

Do not reuse a prior documentation verdict. Resolve the head, commits and changed files directly from GitHub.

## 3. Required target

```text
Repository: wagnerjfjunior/fecha.ai
PR: #104
Title: security: add bounded GPT3 Supabase catalog gateway
Expected state: OPEN / DRAFT
Base: main
Base SHA: b685b360404bbfd0a84a4b755b3092ee35a20e5e
Branch: security/gpt3-supabase-catalog-gateway
Final head: resolve live
Expected changed files: 10
```

Expected paths:

```text
supabase/migrations/20260726180000_gpt_security_metadata_snapshot.sql
supabase/functions/gpt-especialista/index.ts
docs/integrations/gpt3-supabase-action.openapi.yaml
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

Stop if any additional path exists.

## 4. GPT0 audit questions

GPT0 must verify:

1. PR #102 is recorded as merged at squash `b685b360...`;
2. PR #103 remains frozen at `abf6b402...`;
3. the GPT3 blocker is described as missing live catalog evidence, not a proven migration defect;
4. PR #104 contains exactly one primary risk;
5. implementation, lifecycle and live application authorities remain separate;
6. no secret value, PII or business-row output appears;
7. read-only SELECT evidence is not overstated as migration/deploy evidence;
8. the live Edge/RPC drift is recorded accurately;
9. rollback is complete and does not touch PR #103;
10. Security Go remains denied and WDP remains zero.

## 5. Sequencing after GPT0

Only if GPT0 returns `PASS` or `PASS WITH RESIDUAL RISK` with `READY RECOMMENDATION: YES`:

```text
GPT1 exact-head architecture audit
→ GPT3 exact-head Supabase security audit
→ GPT4 exact-head GitHub/release gate
```

All specialists must use the same final PR #104 head. A new commit invalidates the audit chain.

## 6. Gate after specialist audits

If GPT0, GPT1, GPT3 and GPT4 all have no BLOCKING finding:

1. request separate `TECHNICAL_PR_LIFECYCLE` authority;
2. validate live head, base, mergeability, checks and threads;
3. mark Ready only under that authority;
4. revalidate before exact-head squash merge.

Do not merge automatically.

## 7. Gate after merge

Merge does not authorize production application.

Request a separate `CONTROLLED_BETA_PRIMARY_CHANGE` for this exact sequence:

```text
apply versioned migration
→ verify RPC contract and ACL
→ reload PostgREST schema only if required
→ deploy versioned Edge Function
→ update GPT Action from versioned OpenAPI
→ health_check
→ security_metadata_snapshot
→ negative gateway tests
→ sanitized evidence
```

The authority must identify the exact squash commit, project ref `uobxxgzshrmbtjfdolxd`, operator, rollback, stop conditions and expiration.

## 8. PR #103 after gateway availability

Only after the live gateway returns a valid `pr103_preflight_v1` snapshot:

- repeat GPT3 audit of PR #103 at exact head `abf6b402...`;
- do not apply the PR #103 migration;
- do not query application rows or `auth.users`;
- resolve only the catalog evidence blocker.

If GPT3 finds live catalog drift or a concrete code defect, keep PR #103 frozen and classify the finding before any correction.

## 9. Explicitly prohibited now

- further PR #103 commits or metadata changes;
- Ready or merge for PR #103 or PR #104;
- SQL application or RPC creation in production;
- Edge Function deployment;
- GPT Action update;
- secret disclosure or retrieval;
- application-row or `auth.users` reads;
- runtime negative tests;
- Security Go, F1-02 acceptance or WDP.

## 10. Stop conditions

Stop fail-closed if:

- PR #104 base/head/scope differs;
- PR #103 head changes;
- a secret or PII appears;
- arbitrary SQL/object selection enters the gateway;
- the RPC becomes `SECURITY DEFINER`;
- `anon`, `authenticated` or `PUBLIC` can execute the snapshot RPC;
- the Edge accepts additional request fields;
- live configuration changes before authority;
- audit evidence is incomplete.
