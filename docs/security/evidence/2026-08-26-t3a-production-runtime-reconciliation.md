# FECH.AI — T3A Production Runtime Reconciliation

**Date:** `2026-08-26`
**Status:** `PRODUCTION_APPLIED / BOUNDED_RUNTIME_PASS / T3B_FRONTEND_CUTOVER_REQUIRED / SECURITY_GO_DENIED`
**Repository:** `wagnerjfjunior/fecha.ai`
**Workstream:** `F1-02 / T3A Administrative Password Reset Multi-Tenant Authority Boundary`

## 1. Purpose

Record the material transition after PR #130, the successful production migration application, bounded runtime verification and the remaining frontend inconsistency.

This document does not contain passwords, tokens, session material, target emails or target UUIDs.

## 2. Evidence classification

```text
GitHub PR/main anchors: LIVE_RESOLVED
Supabase migration/catalog: LIVE_READ_ONLY_OBSERVED
Supabase Edge version/digest/source: LIVE_READ_ONLY_OBSERVED
Supabase audit/Auth timestamps: LIVE_READ_ONLY_OBSERVED
clean second-target client receipt: INFORMATION_SUPPLIED_BY_PRODUCT_AUTHORITY
client receipt result: independently corroborated by live audit/Auth state
frontend callsite: GITHUB_STATIC_OBSERVED
Security Go: NOT GRANTED
```

## 3. GitHub anchors

```text
main: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
PR: #130
PR title: fix(security): refresh T3A live routine inventory anchor
reviewed head: fd997b6fa552f9423f7a019af58483b2b1a837f1
reviewed / merge tree: b996a327f9d39968731bc0579f21924a525ef2df
merged: true
merge commit: 03fe960f4ef5715bbe50b6e3d5ec9c0b10167073
```

PR #130 contains the exact-head Backend/Data and independent AppSec review receipts. Static approval is not treated as runtime proof.

## 4. Production migration reconciliation

Supabase project:

```text
uobxxgzshrmbtjfdolxd
```

Migration history:

```text
version: 20260826021346
name: t3_admin_password_reset_boundary
```

Current catalog existence:

```text
public.t3_admin_password_reset_edge_proofs: PRESENT
public.t3_admin_password_reset_leases: PRESENT
public.t3_issue_admin_password_reset_edge_proof(uuid,uuid): PRESENT
public.t3_prepare_admin_password_reset(uuid,uuid): PRESENT
public.t3_release_admin_password_reset_lease(uuid,uuid,uuid): PRESENT
```

Current residual state:

```text
proof rows: 0
lease rows: 0
```

The release function has three UUID arguments. A two-argument lookup is not the correct production signature.

## 5. Production Edge reconciliation

```text
slug: criar-usuario
version: 19
status: ACTIVE
verify_jwt: false
ezbr_sha256: bafdd8e9c4cbf679d877b526703bc1ab791153a14fa1cbeddf69be4726f4c9d0
```

Live source inspection establishes the reset sequence:

```text
audit anchor
-> service-role-only one-time proof issue
-> caller-JWT prepare RPC
-> server-side auth.uid()/tenant/role/team authorization
-> durable lease + must_change_password=true
-> Auth admin password update
-> exact lease release
-> audit success
-> HTTP 200 / ok=true
```

`service_role` is operational inside the trusted Edge runtime; it is not client actor authority and is not exposed in the supplied client receipt.

## 6. Protected-field authority after T3A

Live production privilege reconciliation for `authenticated` establishes:

```text
UPDATE apto_para_receber: true
UPDATE ativo: true
UPDATE must_change_password: false
UPDATE role: false
UPDATE empresa_id: false
UPDATE time_id: false
UPDATE user_id: false
UPDATE is_admin_local: false
UPDATE is_gestor: false
```

This is a required part of the T3A boundary. The frontend must not receive direct authority over `must_change_password` again.

## 7. Bounded runtime evidence

### 7.1 Nonexistent-target negative path

Live audit evidence:

```text
created_at: 2026-08-26T02:37:06.753706Z
status: denied
target Auth user: absent
target corretor profile: absent
```

Prior runtime receipt records one controlled HTTP 403 denial and zero lease residue.

Verdict:

```text
PASS — bounded nonexistent-target negative path
```

Limitation: this is not a cross-company adversarial test.

### 7.2 Positive target lineage A

Live evidence records successful server events at:

```text
2026-08-26T02:42:09.814749Z
2026-08-26T02:56:29.251336Z
```

The later event is followed immediately by the Auth user's `updated_at` at:

```text
2026-08-26T02:56:29.701873Z
```

This proves that the apparent client error did not mean that the server-side password mutation failed.

### 7.3 Clean positive target B

Product Authority supplied the sanitized terminal receipt for a separate target:

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
audit created_at: 2026-08-26T03:00:25.365562Z
audit status: success
Auth updated_at: 2026-08-26T03:00:25.618661Z
corretor profile: present
later proof rows: 0
later lease rows: 0
```

Verdict:

```text
PASS — second clean bounded same-company positive reset
```

## 8. Root cause of the apparent frontend error

Current GitHub anchor:

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
callsite: EditarCorretorModal.redefinirSenha()
```

The callsite performs:

```text
POST criar-usuario action=reset_password
-> parse JSON
-> if data.error then throw
-> PATCH public.corretores { must_change_password: false }
-> success message
```

T3A production intentionally removes authenticated direct UPDATE privilege for `must_change_password`.

Therefore:

```text
Edge/Auth reset may succeed
AND
post-success frontend PATCH may fail
AND
UI may display an error from the catch block
```

This is a frontend consistency/cutover defect, not evidence that T3A failed.

## 9. T3B required correction

The next technical change must be frontend-only unless new evidence proves otherwise:

```text
keep reviewed Edge reset call
require explicit HTTP/JSON success
remove direct must_change_password=false PATCH
preserve server-owned must_change_password=true temporary-password semantics
refresh/local-reconcile UI state without protected-field DML
do not broaden grants
do not change T3A database authority
do not mix unrelated App.jsx refactor
```

## 10. Security Go boundary

Established:

```text
T3A static exact-head reviews
T3A migration committed
T3A catalog objects present
Edge v19 active at reviewed digest
bounded nonexistent-target denial
bounded same-company positive server path
second clean same-company positive server path
zero residual proof/lease rows at later reconciliation
```

Not established:

```text
T3B deployed/runtime-proven
cross-company adversarial runtime denial
rollback runtime proof
recovery runtime proof for unresolved Auth/release outcomes
F1-02 final acceptance
```

Therefore:

```text
Security Go: DENIED
Broad paid commercialization: BLOCKED
```

## 11. Stale continuity note

PR #124 remains an older Draft based on `827f8591...`, is currently mergeable=false and edits overlapping SFJM files for a superseded state.

It must not override this transition or be reused for T3B without a separate lifecycle decision.

## 12. Rollback

No rollback was executed during this reconciliation.

Reason:

```text
production application succeeded
bounded runtime path succeeded
proof rows = 0
lease rows = 0
no incident requiring rollback was established
```

Running production rollback merely as a demonstration would introduce avoidable availability/security transition risk. A rollback proof, if required for the final gate, needs a separately bounded rollback/reapply plan or an appropriate isolated environment.
