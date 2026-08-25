# FECH.AI — SFJM Blocked Actions

**Status:** `MATERIAL_BLOCKER_VIEW / PR128_MERGED / EDGE_V19_B1_PASS / T3A_SQL_ALIAS_COLLISION / CORRECTIVE_REVIEWS_PENDING / FAIL_CLOSED`
**Updated:** `2026-08-25`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin blocker view. Principal durable operational state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve live lifecycle before acting.

## 2. Product/security blocks

```text
Security Go
broad paid commercialization
F1-02 final acceptance
alias-corrective PR Ready
alias-corrective PR merge
new T3A Supabase production application
T3A runtime/adversarial/cross-tenant smoke
rollback execution
T3B frontend password cutover
WDP increase without governance acceptance
```

## 3. Closed lineage and current runtime executability gate

PR #127 closed the B1-B4 authority-design blockers and merged. PR #128 closed
the post-merge audit-schema incompatibility, received Backend/Data and
independent AppSec approval on head
`b594218dabd9a7beaea3158bb143f5dd2fd71386`, and merged as
`3c9daf6c49eb937824c2c2b40aba198e2727c4bb`.

Production Edge v19 then proved:

```text
single POST
audit row committed with status=edge_proof_unavailable
Edge HTTP 500
no Auth mutation
B1 runtime PASS
```

The separately-authorized exact migration invocation failed in the first
preflight with SQLSTATE 55000 because PL/pgSQL record variable `r` collided
with `pg_roles AS r`. The transaction aborted before DDL; no T3 objects or
migration record exist. The rollback source contains the same collision.

Current blocking gate:

```text
one alias-only corrective Draft PR
-> integral final-file read and exact diff
-> Backend/Data exact-head PASS
-> independent AppSec exact-head PASS
-> STOP before Ready
```

This is a new runtime executability finding. It does not reopen T1/T2, the
multi-tenant actor contract, proof/lease design or audit compatibility.

## 4. Explicitly prohibited workaround classes

Do not resolve T3A by:

```text
disabling or bypassing T1 triggers
broadening authenticated UPDATE on public.corretores
restoring client authority over must_change_password
trusting client-provided empresa_id/role/flags/time/ownership
using service_role identity as a substitute for auth.uid() authorization
exposing the authenticated prepare RPC to anon/PUBLIC/service_role
letting a direct authenticated prepare call create durable state without an
  Edge-presence proof
normalizing production users to fit the code
trial-and-error SQL in production
mixing unrelated user-creation redesign into password-reset hardening
ignoring an audit INSERT failure and continuing to proof/Auth
dropping/relaxing legacy audit NOT NULL columns to fit the Edge
leaving authenticated direct audit INSERT as a forgeable server-audit surface
using a frontend/server timeout as lease authority or automatic expiry
releasing an unresolved lease after an ambiguous Auth result
```

Any correction that makes the immediate test pass while weakening tenant isolation, authority derivation or rollback is `BLOCKING`, not an acceptable shortcut.

## 5. T1/T2 closed-cycle protection

Do not reopen T1/T2 as independent programs without a new material invalidation event.

Current T3A work may inspect/revalidate the minimum T1/T2 objects necessary for compatibility, including the live T1 guards and the current App password-reset callsite.

Do not:

```text
redo T2 status smoke merely for repetition
rewrite T1 status authority rules to make T3 easier
change App.jsx inside T3A
```

## 6. Lifecycle separation

The following remain distinct decisions:

```text
corrective GitHub commit
exact-head specialist PASS
Ready
merge
Supabase migration application
Edge deployment
runtime smoke
rollback execution
Security Go
```

One does not imply the next.

## 7. Removal rule

Remove a blocker only when the record identifies:

```text
exact corrected object/ref
material evidence
validator/gate
residual risk
rollback/containment
new semantic next action
```

A green build or mergeability result alone does not remove a security blocker.
