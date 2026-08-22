# FECH.AI — F1-02 / T1 — Admin Local Live Compatibility Correction

**Status:** `CORRECTIVE_PR / GITHUB_ONLY / NOT_APPLIED / BOUNDED_RETEST_REQUIRED`  
**Date:** `2026-08-22`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Base main:** `0f8218eb5b93c4096bd540f6ebe525f4a0c258f3`  
**Branch:** `security/t1-admin-local-live-compat`

## 1. Triggering event

After PR #125 was approved, marked Ready and merged, Product Authority authorized production application of the T1 migration only after a fresh read-only preflight.

The fresh production preflight was executed against Supabase project `uobxxgzshrmbtjfdolxd` and stopped before any migration application because one invariant failed:

```text
role_flag_consistency = FAIL
```

No T1 DDL/DML was applied.

## 2. Live evidence — aggregate only / no PII

Read-only aggregate production evidence established:

```text
role=admin_local, is_admin_local=true, is_gestor=false, ativo=true -> 3 rows
role=admin_local, is_admin_local=true, is_gestor=true,  ativo=true -> 1 row
```

The failing T1 preflight had required:

```text
admin_local -> is_admin_local=true AND is_gestor=true
```

That assumption is not compatible with the current production data model.

## 3. Writer evidence

The live `criar-usuario` Edge Function v17 currently inserts `corretores` with independent flags:

```text
role = is_admin_local_novo ? 'admin_local' : (is_gestor_novo ? 'gestor' : 'corretor')
is_admin_local = is_admin_local_novo ?? false
is_gestor = is_gestor_novo ?? false
```

Therefore an `admin_local` with `is_gestor=false` is a state produced by the live writer and is not sufficient evidence of data corruption.

The live RPC `public.alterar_role_corretor(uuid,text)` uses a different transition convention and sets:

```text
is_gestor = (p_novo_role IN ('gestor','admin_local'))
is_admin_local = (p_novo_role = 'admin_local')
```

Production therefore has two currently observable writer conventions for `admin_local`.

## 4. Corrected T1 authority contract

T1 administrative authority must not depend on the manager flag.

```text
admin_local authority:
  role='admin_local'
  AND is_admin_local=true
  AND ativo=true
  AND same-company target
  is_gestor is NOT an administrative-authority prerequisite

gestor authority:
  role='gestor'
  AND is_gestor=true
  AND is_admin_local=false
  AND ativo=true
  AND ordinary broker in own active managed team
```

This does not convert an ordinary broker or gestor into admin authority and does not treat `is_gestor` alone as admin authority.

## 5. Required migration-only correction

The corrective PR may change only the already-merged-but-not-applied T1 migration predicates that incorrectly require `is_gestor=true` for `admin_local`, plus this evidence.

Required edits:

1. preflight role/flag consistency accepts both `is_gestor=false` and `is_gestor=true` for a valid `admin_local` while continuing to require:
   - `corretor`: `is_admin_local=false`, `is_gestor=false`;
   - `gestor`: `is_admin_local=false`, `is_gestor=true`;
   - `admin_local`: `is_admin_local=true`, independent of `is_gestor`.
2. strict RLS helper admin-local branch must not require `v_actor_gestor=true`.
3. authority-update guard admin-local branches must not require `v_actor_gestor=true`.
4. direct-compatibility guard admin-local branch must not require `v_gestor=true`.
5. hardened `atualizar_status_corretor` admin-local branch must not require `v_gestor=true`.
6. role-transition consistency must preserve strict `corretor` and `gestor` semantics while allowing either manager-flag value for `admin_local`.

## 6. Explicitly unchanged

This corrective scope does not change:

- trusted-root source;
- gestor target/team contract;
- cross-tenant denial;
- target-existence handling;
- ACL/grants;
- RLS object names;
- locking/concurrency strategy;
- T1 object set;
- rollback exact-set contract;
- critical audit surface;
- Edge Function;
- frontend;
- production data.

The canonical rollback remains structurally applicable because it fingerprints the applied function bodies dynamically and restores the exact pre-T1 baseline; no rollback object-set or restored baseline changes are required by this compatibility correction.

## 7. Bounded acceptance contract

The corrective retest is closed to the changed semantic surface:

```text
active admin_local + is_admin_local=true + is_gestor=false + same company -> ALLOW
active admin_local + is_admin_local=true + is_gestor=true  + same company -> ALLOW
admin_local + is_admin_local=false                                      -> DENY
inactive admin_local                                                    -> DENY
gestor + is_gestor=false                                                -> DENY
gestor + is_admin_local=true                                            -> DENY
admin_local cross-tenant                                                -> DENY
```

A new blocker requires a material defect introduced by the corrective diff or a new independent live fact. Unchanged T1 domains are not reopened merely by reinterpretation.

## 8. Environment / authority boundary

```text
Supabase production mutation after failed preflight: NONE
T1 migration applied: NO
production data changed: NO
Edge Function changed: NO
frontend changed: NO
Ready: NOT AUTHORIZED
merge: NOT AUTHORIZED
production application: NOT AUTHORIZED BY THIS PR CREATION
Security Go: DENIED / UNCHANGED
```

## 9. Rollback

Before production application, rollback for this corrective PR is a Git revert restoring the prior migration blob. No database rollback is necessary because T1 remains unapplied.

After eventual production application, the existing canonical T1 executable rollback remains the runtime rollback path, subject to its exact-state verifier.
