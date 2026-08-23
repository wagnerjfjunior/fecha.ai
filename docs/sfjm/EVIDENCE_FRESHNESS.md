# FECH.AI — SFJM Evidence Freshness

**Status:** `CLAIM_ANCHOR_INVALIDATION_LEDGER / T3A_CORRECTED_CANDIDATE / EXACT_HEAD_REVIEWS_PENDING / DOCUMENTATION_ONLY`
**Updated:** `2026-08-23`
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

Do not infer freshness from `main` movement alone.

```text
VERSIONED != MERGED != APPLIED != DEPLOYED != RUNTIME_TESTED
```

## 2. T1 status-boundary production anchor

Claim:

```text
T1 corretor status authority boundary is applied in Supabase production and remains a material dependency for T3A.
```

Environment:

```text
Supabase project: uobxxgzshrmbtjfdolxd
Environment: production
Migration record:
  version: 20260822192552
  name: f1_02_harden_status_corretor_rpc
```

Fresh read-only production revalidation on 2026-08-23 established:

```text
public.t3_prepare_admin_password_reset(uuid): ABSENT
public.marcar_senha_inicial_definida() md5:
  2a7b28d4bb6342a99d075c4d3c49af4d
authenticated UPDATE columns on public.corretores:
  apto_para_receber
  ativo
  must_change_password
T1 triggers:
  trg_t1_guard_corretores_authority_update: PRESENT / ENABLED
  trg_t1_guard_corretores_direct_compat_update: PRESENT / ENABLED
```

Additional live function anchors observed during T3A red-team:

```text
t1_guard_corretores_authority_update() md5:
  5e69ae5cb6717f634d758cfd5c1cd7a6

t1_guard_corretores_direct_compat_update() md5:
  99477024e337de5645dd042a30f8cf78

audit_trail_log_corretores_critical_update() md5:
  3fdaca39d55f348ca36f796023f3260b
```

Material T3A interaction:

```text
t1_guard_corretores_direct_compat_update()
currently denies gestor-originated must_change_password transitions.
```

Invalidate/revalidate the affected T3A compatibility claim if either T1 guard body, trigger binding/enabled state, corretores ACL/policy, relevant role contract or T3A design changes.

## 3. T2 frontend status-cutover anchor

Claim:

```text
the active App.jsx status-edit flow routes ativo/apto_para_receber through atualizar_status_corretor rather than the prior direct status PATCH.
```

GitHub code anchor at transition time:

```text
main commit: 037232fe3da37a749ab980f783af92ff15e2baf2
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
```

Controlled positive runtime smoke evidence from the current operating session established:

```text
apto isolated toggle + restoration: PASS
ativo isolated toggle + restoration: PASS
combined ativo/apto toggle + restoration: PASS
unchanged field represented as null in isolated RPC calls: PASS
RPC responses: ok=true
captured direct status PATCH: ZERO
```

Evidence limitation:

```text
HAR/runtime evidence was inspected in the operating conversation and is not yet a canonical repository artifact.
This proves the bounded positive flows observed, not an exhaustive role/cross-tenant adversarial matrix.
```

Invalidate/revalidate after material `src/App.jsx` blob change in the status flow, status RPC contract/ACL change, contradictory runtime evidence or relevant deployment replacement.

## 4. Administrative password residual anchor

Claim:

```text
the current App.jsx still contains a stale administrative post-reset direct write of must_change_password=false.
```

Anchor:

```text
src/App.jsx blob: de7cf84f416409624533e3002c54d8432b35be61
callsite: EditarCorretorModal.redefinirSenha()
```

This remains a T3A/T3B dependency. It must not be interpreted as legitimate authority merely because the code exists.

Invalidate after that callsite/blob changes.

## 5. T3A blocked-head lineage and corrective invalidation

Initial reviewed candidate object anchors:

```text
supabase/functions/criar-usuario/index.ts
  blob: 84c6f23d115cdae966b377f76289a03e5940b45c

supabase/migrations/20260822211600_t3_admin_password_reset_boundary.sql
  blob: 6ab6b94433032d594236257c456a196fd2935b44

supabase/rollback/20260822211600_t3_admin_password_reset_boundary_rollback.sql
  blob: 25723b9d13af9d9a0df82772ca2c8c9cd8ab771c

initial exact PR head reviewed:
  d51340766c3eb8bc3fa0977d327ce229218aaaa3

PR_HEAD_ONLY SFJM transition head before corrective implementation:
  45ad27668835b6458b52d2fb592cfa36b5589726
```

Review result on that initial candidate:

```text
REQUEST CHANGES

B1 safe rollout ordering: FAIL
B2 trust-anchor preflight: FAIL
B3 drift-safe rollback: FAIL
B4 T1 guard interoperability: newly discovered BLOCKING
```

Any corrective change to a material T3A artifact invalidates the prior exact-head gate by design. The next gate must resolve the new live head and read the final material files again.

Do not preserve a partial PASS across head movement.

Corrected v2 candidate body anchors now recorded in this change set:

```text
public.t3_prepare_admin_password_reset(uuid):
  md5 90c537dd4c2c7ae6fb7ae93373c4cc77

T3-aware t1_guard_corretores_direct_compat_update():
  md5 f2cbf4762b5f5b2d6c6eb56fcf0edc2b

exact pre-T3A guard restored by rollback:
  md5 99477024e337de5645dd042a30f8cf78
```

The final corrective commit/head and Git blob anchors must be resolved live;
the hashes above do not establish either specialist review.

## 6. Live trust-anchor observations used by T3A review

Read-only production evidence on 2026-08-23 established, without PII:

```text
admins authenticated SELECT/INSERT/UPDATE/DELETE: absent
corretores authenticated broad UPDATE: absent
corretores authority-bearing columns role/empresa_id/user_id/time_id/is_admin_local/is_gestor: not directly authenticated-updatable
times authenticated table UPDATE: present and therefore materially dependent on RLS/policy semantics
times_update policy: exactly one permissive UPDATE policy with the recorded expression
corretores_update policy: exactly one permissive UPDATE policy with identical strict USING/WITH CHECK helper
RLS/FORCE on admins/corretores/times: present / enabled
unexpected authenticated password writer besides self-service: absent
T3 context-key collision: absent
```

Observed helper fingerprints relevant to the current `times` policy trust chain:

```text
auth.uid() md5: ea3b41bf29e2ad573067939329aa088e
is_root() md5: 465c04885d729e63f1a1d4458fc2a1b0
is_admin_local() md5: 64b982da412f62c324aa2dde210eea0c
my_corretor_id() md5: c8f243d33d42837c46236625a74c3fb7
my_empresa_id() md5: 7d7a73d22953d547a103f89c7b676906
```

These are review anchors, not a permanent guarantee. The corrected migration must fail closed against material drift in the authority chain it relies upon.

## 7. Production Edge baseline

At transition time:

```text
slug: criar-usuario
version: 17
status: ACTIVE
verify_jwt: false
ezbr_sha256: 679643d42dc944cc810580807f4b1a2f5a78ff30a0ce0d67f0713817b2eeb47f
```

The live v17 code validates the Bearer manually, but its administrative reset path changes the Auth password without setting `must_change_password=true` server-side.

This fact is the reason rollout order is security-sensitive.

Invalidate after any Edge version/runtime change.

## 8. Unestablished claims

At this transition, claim only the corrected candidate state and do not claim:

```text
corrected T3A v2 candidate artifacts: RECORDED IN CHANGE SET
corrected final live PR head: MUST BE RESOLVED AFTER COMMIT
T3A Backend/Data exact-head PASS: NOT ESTABLISHED
T3A independent AppSec exact-head PASS: NOT ESTABLISHED
T3A applied to Supabase production: NO
hardened T3A Edge deployed: NO
T3A positive/negative/cross-tenant production smoke: NOT EXECUTED
T3A rollback runtime-tested: NOT EXECUTED
T3B frontend password cutover: NOT IMPLEMENTED
Security Go: DENIED
```

While the SES Router is temporarily frozen, a manual specialist result is fresh
only if the returned response explicitly binds itself to the live repository,
PR and exact head, identifies the material files read, and contains the complete
specialist verdict. A prompt alone is not review evidence. Do not fabricate a
Gateway receipt.

## 9. Invalidation rules

Material invalidation events include:

```text
material code/object change
RPC/ACL/policy/grant/trigger change
Edge runtime/version change
relevant App frontend change
contradictory runtime evidence
new security finding
change in product authority contract
```

Not invalidation events by themselves:

```text
main SHA movement only
documentation-only lifecycle movement
new conversation
specialist change
request to repeat an unchanged exact-head gate
```

## 10. AUDIT_LOOP_BLOCKED

A repeated audit must identify the prior anchor, exact changed evidence and affected proof obligation.

Without a material invalidation event:

```text
AUDIT_LOOP_BLOCKED
```

After a material T3A corrective commit, revalidate only the affected exact-head T3A gate and its dependencies; do not reopen unrelated completed work.
