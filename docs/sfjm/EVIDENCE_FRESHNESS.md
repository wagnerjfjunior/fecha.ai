# FECH.AI — SFJM Evidence Freshness

**Status:** `CLAIM_ANCHOR_INVALIDATION_LEDGER / PR130_MERGED / T3A_APPLIED / EDGE_V19_ACTIVE / BOUNDED_RUNTIME_PASS / T3B_APP_ANCHOR_ACTIVE / SECURITY_GO_DENIED`
**Updated:** `2026-08-26`
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness model

Evaluate each material claim by:

```text
claim
object
anchor
environment
invalidation event
```

Preserve:

```text
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
```

Historical failed/corrected T3A heads remain in Git history and PR/evidence lineage. This file records the current anchors required for continuation; it does not erase historical failures.

## 2. Current GitHub anchor

```text
repository: wagnerjfjunior/fecha.ai
main: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
PR #130 reviewed head: fd997b6fa552f9423f7a019af58483b2b1a837f1
PR #130 reviewed / merge tree: b996a327f9d39968731bc0579f21924a525ef2df
PR #130 merged: true
merge commit: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
```

Invalidate only if a later code/material change affects the claimed object. Ordinary unrelated `main` movement does not retroactively invalidate the exact-head review.

## 3. T1 status-boundary production anchor

Environment:

```text
Supabase project: uobxxgzshrmbtjfdolxd
Environment: production
```

Current authenticated UPDATE authority on protected `corretores` columns:

```text
apto_para_receber: true
ativo: true
must_change_password: false
role: false
empresa_id: false
time_id: false
user_id: false
is_admin_local: false
is_gestor: false
```

Established T1 authority/direct-compat triggers remain enabled.

Invalidate after relevant `corretores` ACL/policy/grant/trigger/function changes.

## 4. T2 status-cutover frontend anchor

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

The established `ativo/apto_para_receber` status path remains outside the current T3B change and must not be reopened absent contradictory evidence.

Invalidate only if the relevant status callsite/blob changes.

## 5. T3A production application anchor

Supabase migration history:

```text
version: 20260826021346
name: t3_admin_password_reset_boundary
state: PRESENT / COMMITTED
```

Current catalog existence:

```text
public.t3_admin_password_reset_edge_proofs: PRESENT
public.t3_admin_password_reset_leases: PRESENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): PRESENT
public.t3_prepare_admin_password_reset(uuid,uuid): PRESENT
public.t3_release_admin_password_reset_lease(uuid,uuid,uuid): PRESENT
```

Residual state at reconciliation:

```text
proof rows: 0
lease rows: 0
```

Important signature correction:

```text
release RPC identity args = p_lease_id uuid, p_actor_user_id uuid, p_target_user_id uuid
```

A two-argument `to_regprocedure` check is not evidence that the release routine is absent.

Invalidate after any migration rollback/reapply, relevant function/table/trigger/ACL change or contradictory catalog observation.

## 6. Production Edge anchor

```text
slug: criar-usuario
version: 19
status: ACTIVE
verify_jwt: false
ezbr_sha256: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
```

Live source inspection confirms the reviewed T3A-v5 reset sequence:

```text
audit insert
-> service-role-only proof issuer
-> caller-JWT prepare RPC / auth.uid authority
-> durable lease + must_change_password=true
-> Auth admin password update
-> service-role exact lease release
-> audit success
-> HTTP 200 { ok: true, user_id }
```

Invalidate after any Edge version/digest/source change.

## 7. Bounded runtime evidence anchors

### 7.1 Negative nonexistent target

```text
audit created_at: 2026-08-26T02:37:06.753706Z
status: denied
target Auth user: absent
target corretor profile: absent
```

Prior runtime receipt records HTTP 403 and generic non-leaking denial.

Claim supported:

```text
bounded nonexistent-target negative path = PASS
```

Not supported:

```text
cross-company adversarial runtime matrix = PASS
```

### 7.2 Positive target lineage A

```text
audit success: 2026-08-26T02:42:09.814749Z
audit success: 2026-08-26T02:56:29.251336Z
Auth updated_at after later event: 2026-08-26T02:56:29.701873Z
corretor profile: present
```

Claim supported:

```text
bounded same-company administrative reset can complete server-side
```

### 7.3 Clean positive target B

Product Authority supplied a sanitized terminal receipt:

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

Independent live reconciliation:

```text
audit success: 2026-08-26T03:00:25.365562Z
Auth updated_at: 2026-08-26T03:00:25.618661Z
corretor profile: present
proof rows at later reconciliation: 0
lease rows at later reconciliation: 0
```

Claim supported:

```text
second clean same-company positive server path = PASS
```

Do not store target email, password, token or UUID in SFJM.

## 8. T3B frontend residual anchor

Current App anchor:

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
callsite: EditarCorretorModal.redefinirSenha()
```

Observed code contract:

```text
fetch criar-usuario reset_password
-> parse response
-> if data.error then throw
-> direct PATCH corretores must_change_password=false
-> set success message
```

Live production privilege contract:

```text
authenticated UPDATE(must_change_password) = false
```

Therefore the direct post-success PATCH is expected to fail after the Edge has already completed the Auth reset, causing a false client error.

This is the current material T3B reason. Invalidate after the App callsite/blob changes.

## 9. Stale continuity anchor — PR #124

```text
PR: #124
state: OPEN / DRAFT
base SHA: 827f8591bfe4eee595a1aa22e169dcf6465f7fa3
head: 5e5cc76dae2da93472643e585d3311c92e79e4e6
mergeable: false
changed files overlap current SFJM
```

Classification:

```text
STALE_CONTINUITY / SUPERSEDED_FOR_CURRENT_SFJM
```

Its historical inventory evidence is not erased, but its current-state claims must not override the newer T1/T2/T3A evidence.

## 10. Unestablished claims

```text
T3B frontend cutover implemented: NO
T3B deployed/runtime-proven: NO
cross-company adversarial production smoke: NOT ESTABLISHED
rollback runtime-tested: NOT EXECUTED
recovery path runtime-tested: NOT EXECUTED
F1-02 final acceptance: NO
Security Go: DENIED
broad paid commercialization: BLOCKED
```

## 11. Invalidation rules

Material invalidation events include:

```text
material code/object change
RPC/ACL/policy/grant/trigger change
Edge runtime/version change
relevant App frontend change
contradictory runtime evidence
new security finding
change in Product Authority contract
rollback/reapply
```

Not invalidation events by themselves:

```text
main SHA movement only
documentation-only lifecycle movement
new conversation
specialist change
request to repeat an unchanged exact-head gate
```

## 12. AUDIT_LOOP_BLOCKED

A repeated audit must identify the prior anchor, exact changed evidence and affected proof obligation.

Without a material invalidation event:

```text
AUDIT_LOOP_BLOCKED
```
