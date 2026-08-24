# FECH.AI — SFJM Blocked Actions

**Status:** `MATERIAL_BLOCKER_VIEW / PR127_MERGED / B1_RUNTIME_PASS / AUDIT_SCHEMA_DRIFT_OPEN / V5_EXACT_HEAD_REVIEWS_PENDING / FAIL_CLOSED`
**Updated:** `2026-08-24`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This is a thin blocker view. Principal durable operational state:

```text
docs/sfjm/CURRENT_STATE.md
```

Resolve live lifecycle before acting.

## 2. Product/security blocks

The following remain blocked unless material evidence and applicable Product Authority change their state:

```text
Security Go
broad paid commercialization
F1-02 final acceptance
new T3A-v5 corrective PR Ready
new T3A-v5 corrective PR merge
T3A Supabase production application
further T3A Edge production deployment
T3A production adversarial/cross-tenant execution without exact runtime authority
T3B frontend password cutover before T3A backend is safely applied/deployed/validated
WDP increase without governance acceptance
```

## 3. Closed B1-B4 lineage and current audit gate

Do not reopen B1-B4 or create another PR merely to relitigate them.

```text
B1 — unsafe rollout order in the initial candidate
B2 — incomplete trust-anchor preflight
B3 — rollback not sufficiently drift-safe
B4 — incompatibility with the live T1 direct-compatibility guard for gestor password-state transition
```

The Backend/Data exact-head review of `bf8fb1f...` returned `REQUEST_CHANGES`:
the DB lock did not span the later Auth side effect and the writer regex was not
transitive. The v3 candidate at `46313258...` introduced the durable
lease/fence and positive inventory, then a same-PR correction closed its
membership/options, aggregate and complete `public` ACL findings. Exact head
`fcb7dfc2...` subsequently received Backend/Data and independent AppSec
`APPROVE`.

After separately-authorized Ready, the GitHub Codex review opened material P2
`DIRECT_RPC_CAN_MINT_UNRELEASABLE_LEASE`. Direct authenticated PostgREST access
to the prepare RPC could commit a durable lease and `must_change_password=true`
without the Edge Auth mutation; only service_role could release that lease, and
the T1/T3 guards would then prevent ordinary completion. The PR was returned to
Draft at that point. T3A-v4 then required a service-role-only, opaque, one-time
Edge-presence proof that the caller-JWT prepare RPC must consume before locks,
lease creation or password-state mutation.

Integral Backend/Data and independent AppSec reviews subsequently approved
exact head `a5c92617f372599a234c0147aad13a90649348d7` / tree
`87872aac22b36437b7fb66f3614905e8df94f5ee` with no findings. PR #127 merged as
`610bdd3c4b5ab208f7ffe177d9d32a2184aa9d87`. The exact Edge was deployed as
production v18, and the bounded fail-before-Auth calls all returned 500 without
any Auth update. B1 is runtime PASS; B2-B4 remain approved static contracts and
are not reopened absent a material change in their domains.

The same runtime evidence opened one new blocker:

```text
AUDIT_SCHEMA_COMPATIBILITY
v18 POST /rest/v1/audit_logs -> 400
live required fields omitted by v18: acao, entidade
ip_address live type: inet
audit anchor not created, although issuer 404 still prevented Auth
```

Current blocking gate:

```text
publish/resolve one v5 audit-compatibility Draft PR from merged main
-> integral material-file read + coverage reconciliation
-> repeat Backend/Data exact-head review and obtain PASS
-> independent AppSec exact-head PASS
-> STOP in Draft before Ready
```

Any material correction after either review invalidates both head-bound results
as applicable. The new PR is justified only by the post-merge runtime finding;
it is not a duplicate vehicle for the old B1-B4 blockers.

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
