# FECH.AI — SFJM Next Safe Action

**Status:** `NEXT_SAFE_ACTION / TARGETED_GPT3_THEN_GPT4`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Current safe state

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #103: OPEN / DRAFT / FROZEN
PR #103 head: abf6b4026343eae437283280269ed2997911dcec
PR #104: OPEN / DRAFT
PR #104 base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #104 final head: resolve live after this commit
```

The final correction is versioned only. No Supabase, Edge or GPT Action live change occurred.

## 2. Exact next action

Run a targeted GPT3 re-audit limited to:

```text
parent: 134e0a8717a5cbd67e490af4c1bcd2fd2e3c8cd6
head: resolve live
technical file: supabase/functions/gpt-especialista/index.ts
finding: RQ-02 only
```

GPT3 must verify that invalid timestamp, table types, column structural types and non-object metadata-array items are rejected with the existing `502 security_metadata_contract_invalid` path.

GPT3 must also confirm that migration and OpenAPI did not change.

## 3. After targeted GPT3

Only if GPT3 returns no `BLOCKING` and no `REQUIRED IN THIS PR`:

```text
GPT4 final gate on the complete final head
```

GPT4 validates:

- exact head and parent;
- one final commit;
- exactly seven paths in the final commit;
- ten net PR paths;
- unchanged migration, OpenAPI and `BLOCKED_ACTIONS.md`;
- PR #103 frozen;
- checks, mergeability, reviews and threads;
- PR description reconciled;
- no Ready or merge already performed.

## 4. Explicitly do not repeat

```text
GPT0: DO NOT REPEAT
GPT1: DO NOT REPEAT
```

The Product Authority explicitly prohibited both repetitions. Their conclusions remain usable for unchanged scope and architecture.

## 5. Gate after GPT4

If targeted GPT3 and GPT4 pass, request a separate `TECHNICAL_PR_LIFECYCLE` authority. Do not mark Ready or merge automatically.

## 6. Gate after merge

Merge does not authorize production application.

A separate `CONTROLLED_BETA_PRIMARY_CHANGE` must identify the exact squash commit and authorize:

```text
migration
→ RPC owner/search_path/ACL verification
→ Edge deploy
→ GPT Action update
→ positive and negative tests
→ sanitized evidence
```

## 7. Stop conditions

Stop if:

- final head is not a direct one-commit descendant of `134e0a...`;
- final delta contains a path outside the seven authorized files;
- migration or OpenAPI changed;
- PR #103 changed;
- GPT3 still finds RQ-02 incomplete;
- a secret or PII appears;
- Ready, merge or live changes occurred without authority.
