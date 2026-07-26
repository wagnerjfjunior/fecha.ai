# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / PR104_AND_GATEWAY_AUTHORITIES_CONSUMED / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, environment, object, operation, prohibitions and expiration stated by the Product Authority. Recording a past authorization does not reactivate it.

## 2. Canonical anchors before this closure PR

```text
main: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
PR #104: CLOSED / MERGED
PR #104 squash commit: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
PR #103: OPEN / DRAFT
PR #103 head: abf6b4026343eae437283280269ed2997911dcec
Supabase project: uobxxgzshrmbtjfdolxd
```

## 3. Consumed PR #104 authorities

### Final corrective commit

Consumed by the localized Edge timestamp/contract correction ending at:

```text
dc75198dd8d14fc2856890964771f3434942dd7a
```

No additional commit authority remains from that instruction.

### TECHNICAL_PR_LIFECYCLE

Consumed by:

```text
Draft → Ready
exact-head revalidation
squash merge
```

Result:

```text
PR #104: CLOSED / MERGED
Squash commit: 6fcb42f7dcd876601d246215926fb0a6a3bf9d23
```

This authority expired immediately after the merge.

### CONTROLLED_BETA_PRIMARY_CHANGE

Consumed by the exact live sequence authorized for project `uobxxgzshrmbtjfdolxd`:

```text
apply gpt_security_metadata_snapshot migration
→ validate RPC contract and ACL
→ execute fixed catalog snapshot under service_role
→ deploy gpt-especialista from main@6fcb42f7...
→ confirm ACTIVE version 8
```

This authority did not authorize PR #103 application, other RPCs, other Edge Functions, Auth, RLS, policies, business data, secrets, Security Go, F1-02 acceptance or WDP.

### SFJM closure instruction

The Product Authority instructed SFJM to be updated and the PR #104/gateway subject to be closed. That instruction authorizes only this documentation-only closure workflow. It expires when the closure PR is merged or stopped.

## 4. Live changes completed under consumed authority

```text
Migration: 20260726224527 / gpt_security_metadata_snapshot
RPC: public.gpt_security_metadata_snapshot()
RPC ACL: service_role only, plus owner
Edge: gpt-especialista / ACTIVE / version 8
verify_jwt: false preserved
Custom authentication: x-gpt-action-key preserved
GPT Action configuration mutation: NONE
PR #103 mutation/application: NONE
```

## 5. Current non-authorizations

```text
Additional PR #104 commits: NOT AUTHORIZED
Gateway SQL/RPC alteration: NOT AUTHORIZED
Gateway Edge redeploy: NOT AUTHORIZED
Gateway rollback: NOT AUTHORIZED
Secret read/disclosure/rotation: NOT AUTHORIZED
GPT Action configuration change: NOT AUTHORIZED
PR #103 Ready/merge/application: NOT AUTHORIZED BY THIS RECORD
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

PR #103 may continue only under the authorities established in its separate active conversation and after fresh exact-state validation.

## 6. Incident containment authorization

During the live operation, two accidental migration-history-only markers were created and removed immediately:

```text
gpt_security_metadata_snapshot_marker_check
noop_should_not_exist
```

Their removal was limited to the unintended history records. Final verification showed zero residual marker records. This does not authorize broader migration-history editing.

## 7. Future authorities

A new explicit authority is required for any of the following:

- change or rollback of the live catalog RPC;
- redeploy or configuration change of `gpt-especialista`;
- secret rotation or Action configuration update;
- PR #103 Ready, merge or Supabase application;
- F1-02 acceptance;
- Security Go.

No authority should be inferred from the fact that the gateway is operational.
