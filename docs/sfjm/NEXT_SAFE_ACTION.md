# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / T3A_APPLIED_AND_BOUNDED_RUNTIME_PASS / T3B_FRONTEND_CUTOVER_NEXT / SECURITY_GO_DENIED`
**Updated:** `2026-08-26`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin semantic view. Principal material state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve GitHub/Supabase lifecycle live before acting.

## 2. Single current semantic next action

```text
T3B FRONTEND CUTOVER
```

Create one narrow frontend Draft PR from the current live `main` that corrects only `EditarCorretorModal.redefinirSenha()`.

Current observed contract:

```text
Edge reset_password returns HTTP 200 / { ok: true, user_id }
-> T3A server-side flow has already set must_change_password=true
-> Auth password mutation succeeds
-> lease is released
-> frontend then attempts direct PATCH must_change_password=false
-> authenticated lacks UPDATE privilege on must_change_password
-> frontend catch reports an error after a successful reset
```

Required T3B delta:

```text
preserve existing criar-usuario Edge call
require explicit response.ok / HTTP success contract
remove direct PATCH public.corretores must_change_password=false
do not broaden authenticated grants
do not add client-supplied authority fields
do not change Edge, migration, rollback, T1 or T2
represent successful administrator-issued reset as temporary-password state
refresh or locally reconcile UI state without a direct protected-field write
```

## 3. Exact current anchors

```text
main: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
Edge criar-usuario: v19 / ACTIVE
ezbr_sha256: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
T3A migration history: 20260826021346_t3_admin_password_reset_boundary
```

These anchors must be re-resolved before T3B branch creation.

## 4. T3B proof obligations

Before Ready:

```text
1. exact App.jsx callsite/diff validated
2. no direct must_change_password PATCH remains in the administrative reset success path
3. Edge success is not converted into a false client error
4. Edge failure/403/500 still reports failure
5. no frontend change can declare tenant/company/role/team authority
6. no Supabase/Edge/runtime file outside the bounded frontend scope changes
7. build/checks pass
8. rollback is a simple revert of the frontend PR
9. independent security/domain review is bound to the final exact head
```

After a separately authorized deploy, run only the minimum positive/negative UI smoke necessary to prove the corrected presentation path. Do not reset already-proven test accounts merely for repetition.

## 5. Remaining Security Go proof obligations

T3A same-company positive and nonexistent-target negative runtime evidence is established, but Security Go remains denied until the applicable F1-02/M1 proof boundary is complete.

Still not established:

```text
T3B deployed/runtime-proven
cross-company adversarial runtime denial
rollback runtime proof or an approved equivalent isolated proof
recovery behavior for unresolved Auth/release outcomes
final F1-02 acceptance decision
```

Do not relabel static assurance or bounded same-company smoke as full Security Go.

## 6. Stale PR handling

PR #124 is an older Draft that edits overlapping SFJM files from a superseded state and is currently mergeable=false.

```text
PR #124 -> STALE_CONTINUITY / DO NOT USE FOR T3B
```

Do not rebase or merge it into the current T3A/T3B track without a separate explicit decision.

## 7. No audit loop

Do not repeat:

```text
PR #130 exact-head static reviews
T3A migration application
same successful target reset merely for reassurance
T1/T2 audits without a material invalidation event
```

Without new material evidence, repeated work is:

```text
AUDIT_LOOP_BLOCKED
```
