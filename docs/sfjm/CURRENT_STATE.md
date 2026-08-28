# FECH.AI — SFJM Current Material State

**Status:** `MATERIAL_RECORDED_STATE / PR130_MERGED / T3A_PRODUCTION_APPLIED / EDGE_V19_ACTIVE / BOUNDED_NEGATIVE_AND_POSITIVE_RUNTIME_PASS / T3B_FRONTEND_CUTOVER_REQUIRED / SECURITY_GO_DENIED`
**Updated:** `2026-08-26`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority rule

This file is the principal authority for durable product/security operational meaning.

It intentionally does not freeze volatile GitHub lifecycle facts. Resolve current `main`, PR state, head, checks, reviews, threads, mergeability and deployment state live before acting.

Current material transition:

```text
T3A administrative password-reset server/data boundary
-> PR #130 exact-head reviews closed
-> PR #130 merged
-> exact T3A migration applied successfully once to Supabase production
-> catalog postflight established
-> bounded negative runtime smoke PASS
-> bounded authorized positive runtime reset PASS
-> second clean positive target PASS
-> frontend still performs a stale post-success direct must_change_password write
-> T3B frontend cutover is now the next technical workstream
```

Security Go remains denied because T3B, cross-tenant runtime evidence and rollback/recovery proof remain incomplete.

## 2. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION
WDP: unchanged
```

Architecture rule:

```text
Frontend requests/displays.
Backend/RPC/Supabase validates and decides.
Client-provided tenant/company/role/flags/ownership are not authority.
Fail closed on missing or inconsistent identity/tenant/permission evidence.
```

## 3. Live GitHub anchor

Latest live `main` resolved for this transition:

```text
main: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
merge: PR #130 — fix(security): refresh T3A live routine inventory anchor
reviewed head: fd997b6fa552f9423f7a019af58483b2b1a837f1
reviewed / merge tree: b996a327f9d39968731bc0579f21924a525ef2df
```

PR #130 had independent exact-head Backend/Data and AppSec static approvals before merge. Those reviews prove the reviewed bytes only; runtime proof is recorded separately below.

## 4. T1 / T2 preserved state

T1 status authority remains applied and is not reopened.

Current production column authority revalidation establishes for `authenticated`:

```text
UPDATE apto_para_receber: YES
UPDATE ativo: YES
UPDATE must_change_password: NO
UPDATE role: NO
UPDATE empresa_id: NO
UPDATE time_id: NO
UPDATE user_id: NO
UPDATE is_admin_local: NO
UPDATE is_gestor: NO
```

Established T1 triggers remain enabled.

T2 status-edit frontend cutover remains established for `ativo/apto_para_receber` and is not reopened by T3A.

## 5. T3A — production application state

Supabase production project:

```text
uobxxgzshrmbtjfdolxd
```

Migration application:

```text
name: t3_admin_password_reset_boundary
history version: 20260826021346
application: SUCCESS / COMMITTED
```

Current catalog establishes:

```text
public.t3_admin_password_reset_edge_proofs: PRESENT
public.t3_admin_password_reset_leases: PRESENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): PRESENT
public.t3_prepare_admin_password_reset(uuid,uuid): PRESENT
public.t3_release_admin_password_reset_lease(uuid,uuid,uuid): PRESENT
proof rows at reconciliation: 0
lease rows at reconciliation: 0
```

The release function has three UUID arguments. A two-argument lookup is not the production signature and must not be used as absence evidence.

Production Edge:

```text
slug: criar-usuario
version: 19
status: ACTIVE
verify_jwt: false
ezbr_sha256: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
```

No Edge redeploy is required by this reconciliation.

## 6. Runtime evidence

### 6.1 Bounded negative target

Production evidence records one controlled nonexistent-target path:

```text
audit created_at: 2026-08-26T02:37:06.753706Z
status: denied
HTTP observed in the prior runtime receipt: 403
target Auth user: absent
target corretor profile: absent
residual lease: none
```

This proves a bounded fail-closed negative path. It is not cross-company adversarial coverage.

### 6.2 Authorized positive target lineage

Production audit/Auth reconciliation establishes successful administrative resets at:

```text
2026-08-26T02:42:09.814749Z -> success
2026-08-26T02:56:29.251336Z -> success on the same target lineage
```

The corresponding Auth user `updated_at` advanced immediately after the later successful event. No residual proof or lease remained at reconciliation.

### 6.3 Clean second positive target

The Product Authority supplied the terminal receipt for a separate clean same-company target. Sensitive values were not retained in SFJM.

Client receipt:

```text
CALL_COUNT=1
EDGE_HTTP_STATUS=200
EDGE_RESPONSE.ok=true
CLIENT_OBSERVATION=EXPECTED_AUTHORIZED_RESET_SUCCESS
RETRY_AUTOMATICO=DESABILITADO
TOKEN_OUTPUT=NAO
LOGIN_PASSWORD_OUTPUT=NAO
NEW_PASSWORD_OUTPUT=NAO
```

Independent production reconciliation establishes:

```text
audit created_at: 2026-08-26T03:00:25.365562Z
status: success
Auth updated_at: 2026-08-26T03:00:25.618661Z
corretor profile: present
residual proof rows: 0
residual lease rows: 0
```

Verdict for the bounded same-company authorized server path:

```text
PASS
```

This does not establish cross-company adversarial runtime coverage, rollback execution, recovery proof or Security Go.

## 7. T3B — current frontend blocker

Current `main` App anchor:

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
callsite: EditarCorretorModal.redefinirSenha()
```

The current flow is:

```text
POST criar-usuario action=reset_password
-> Edge returns success
-> frontend executes direct PATCH public.corretores must_change_password=false
-> authenticated no longer has UPDATE privilege on must_change_password
-> PATCH fails
-> catch displays an error even though Auth reset already succeeded
```

This is the observed explanation for the apparent UI error after a successful backend reset.

The stale direct write is not legitimate authority and must not be re-enabled. T3B must remove the direct patch and align UX/local state with the server-owned `must_change_password=true` contract for an administrator-issued temporary password.

## 8. Stale continuity — PR #124

PR #124 is live as:

```text
OPEN / DRAFT
base SHA: 827f8591bfe4eee595a1aa22e169dcf6465f7fa3
head: 5e5cc76dae2da93472643e585d3311c92e79e4e6
mergeable: false
```

It edits overlapping SFJM files for an earlier PR-03 inventory state and predates the T1/T2/T3A material transitions.

Classification:

```text
STALE_CONTINUITY / SUPERSEDED_FOR_CURRENT_SFJM
```

Do not merge, rebase or reuse PR #124 as the T3A/T3B continuity vehicle without a separate explicit decision. Its historical inventory evidence remains historical.

## 9. Material blockers

```text
T3A migration reapplication: BLOCKED / already applied
repeat password reset on already-proven test targets: BLOCKED / unnecessary
Edge v19 redeploy: BLOCKED / unnecessary absent material Edge change
T3B frontend cutover: NOT YET IMPLEMENTED
cross-company adversarial runtime proof: NOT ESTABLISHED
rollback execution/runtime proof: NOT ESTABLISHED
recovery-path proof: NOT ESTABLISHED
Security Go: DENIED
F1-02 final acceptance: BLOCKED
broad paid commercialization: BLOCKED
```

## 10. Current Product Authority and limits

The Product Authority re-supplied the prior authorization context in the current conversation:

```text
merge if all gates are satisfied
Supabase production if all gates are satisfied
Edge deploy if all gates are satisfied
runtime smoke if all gates are satisfied
rollback if all gates are satisfied
Security Go if all gates are satisfied
```

Durable interpretation is fail-closed and transition-specific:

- PR #130 merge: already consumed;
- successful T3A production migration application: already consumed;
- Edge redeploy after PR #130: not required and therefore not exercised;
- bounded runtime smoke: partially exercised and evidenced above; no automatic retry is authorized merely because prior smoke authority existed;
- rollback: not executed because the successful state did not require recovery; production rollback must not be run merely to demonstrate capability without a separately safe test plan;
- Security Go: not exercisable while recorded proof obligations remain incomplete.

## 11. Semantic next action

```text
T3B FRONTEND CUTOVER

Create one narrow frontend Draft PR from live main that changes only the
EditarCorretorModal administrative reset success path:

- keep the existing Edge reset call;
- require explicit HTTP/JSON success;
- remove the direct PATCH must_change_password=false;
- do not restore authenticated UPDATE(must_change_password);
- preserve server-side actor/tenant/role/team authority;
- make the UI report success when the Edge returned the reviewed success contract;
- refresh/local-update the broker state so the temporary-password state is represented correctly;
- no Supabase migration, Edge change or unrelated App.jsx refactor.
```

Before any T3B Ready/merge/deploy, re-resolve exact head and perform the required frontend/security/domain validation.

## 12. Do not reopen

Absent a new material invalidation event, do not reopen:

```text
T1 status authority design
T2 ativo/apto frontend cutover
PR #130 routine-anchor static review
successful T3A migration application
bounded successful T3A same-company runtime path
```

A repeated audit on unchanged evidence is `AUDIT_LOOP_BLOCKED`.
