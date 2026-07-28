# FECH.AI — PR #103 Authenticated Smoke and Immediate Idempotency

**Status:** `DOCUMENTATION_ONLY / CONTROLLED_PRODUCTION_SMOKE_PASSED / SANITIZED_EVIDENCE`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Canonical main before this documentation PR:** `9624900ada5d29e24476ab6a0a0907cb4854e509`  
**Supabase project:** `uobxxgzshrmbtjfdolxd`  
**RPC:** `public.marcar_senha_inicial_definida()`

## 1. Purpose

Record the bounded authenticated production smoke executed after PR #103 had been merged and its exact migration applied.

This evidence is limited to:

```text
authenticated positive execution
immediate repeated-call idempotency
field-invariance observation
synthetic-fixture cleanup
```

It does not alter runtime, frontend, Supabase, Auth, RLS, policies, grants, migrations, RPC bodies, Edge Functions, Vercel or production configuration.

## 2. Controlled fixture boundary

The smoke used only a synthetic tenant, synthetic local admin, synthetic manager, synthetic team and one ordinary synthetic broker.

Sanitized identities:

```text
tenant: 917c1b85…1c9e
team: 83d70472…81ea
authenticated user: 4a9d568d…2f45
broker profile: dbfc45a1…536a
```

The ordinary broker state immediately before the RPC was:

```text
role: corretor
ativo: true
is_gestor: false
is_admin_local: false
apto_para_receber: false
lista_preferencial_id: null
must_change_password: true
xmin: 6997
```

No real lead, client, list, lot, team, broker, company or commercial row was used as the smoke actor or target.

## 3. First authenticated call

Execution completed at:

```text
2026-07-28T13:55:25.433Z
```

Observed result:

```text
RPC return: true
must_change_password: true → false
xmin: 6997 → 6999
unexpected changed fields: none
```

The `xmin` transition proves that the first call produced a new row version.

The following observed fields remained invariant:

```text
id
user_id
nome
email
empresa_id
time_id
role
ativo
apto_para_receber
is_gestor
is_admin_local
lista_preferencial_id
```

## 4. Immediate repeated call

Execution completed at:

```text
2026-07-28T13:59:00.144Z
```

Observed result:

```text
RPC return: true
must_change_password: false → false
xmin: 6999 → 6999
unexpected changed fields: none
```

The unchanged `xmin` proves that the immediate repeated call did not emit a second row update.

## 5. Runtime conclusion

```text
Authenticated positive smoke: PASS
Immediate repeated-call idempotency: PASS
Target-field transition: PASS
Observed unrelated-field invariance: PASS
False-success response: NOT OBSERVED
```

This result applies only to the exact RPC and exact controlled execution described here.

## 6. Cleanup result

Final read-only cleanup verification returned:

```text
remaining Auth users: 0
remaining synthetic broker profiles: 0
remaining synthetic teams: 0
synthetic company row preserved: 1
synthetic company active: false
team audit-trail rows preserved: 2
```

The synthetic company record was deactivated rather than deleted so that linked audit evidence could remain preserved.

## 7. Evidence established

This smoke establishes:

- one authenticated active ordinary broker can execute the RPC successfully;
- the RPC completes `must_change_password = true → false`;
- the RPC returns boolean `true`;
- the immediate repeated call returns `true`;
- the immediate repeated call performs no second row update;
- no unexpected change was observed in the captured profile fields;
- the synthetic Auth users, broker profiles and team were removed;
- the preserved synthetic company is inactive.

## 8. Evidence not established

This smoke does not establish:

- controlled concurrency behavior;
- execution with an authenticated user lacking a broker/profile row;
- execution with an inactive broker/profile;
- rollback execution;
- reapply after rollback;
- frontend cutover;
- deployed frontend proof;
- denial of the legacy direct table update;
- Security Go;
- F1-02 acceptance;
- WDP.

## 9. Program implication

The mandatory F1-02 sequence remains:

```text
PR-01 RPC and controlled positive smoke
→ PR-02 frontend cutover
→ deployed cutover proof and repository-wide call-site rescan
→ PR-03 direct UPDATE revoke
```

PR-02 remains a separate workstream. Its implementation, branch and pull request require a new exact Product Authority instruction after this documentation PR is closed.

PR-03 remains blocked until PR-02 is deployed and proven.

## 10. Rollback and anti-loop

Rollback for this documentation-only record is one revert of the documentation PR that introduces it.

The smoke result does not reopen the completed PR #103 implementation, merge or migration-application lifecycle. Revalidation is limited to evidence materially affected by this new runtime result.
