# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR02_STATIC_EVIDENCE_CURRENT / RUNTIME_CUTOVER_UNPROVEN / FAIL_CLOSED`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch or commit, object set, configuration and lifecycle state observed. Versioned code, merged state, deployed state, live database state and executed runtime tests remain distinct.

A documentation-only head change does not invalidate a successful build of unchanged frontend code. A code, dependency, workflow or environment change does.

## 2. GitHub anchors

```text
Canonical main:
cec1b22430adf1a002b172992cf6c5ea5bb427de

PR #107:
CLOSED / MERGED
squash: cec1b22430adf1a002b172992cf6c5ea5bb427de

PR #108:
OPEN / DRAFT / NOT MERGED
base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
live branch: security/f1-02-password-flow-cutover-1
implementation commit: c458461e810e24adb7d71f7d155be06e9cf54eac
documentation head: resolve live
```

## 3. PR-01 evidence retained

The previously versioned PR-01 evidence remains applicable to the unchanged RPC and catalog contract:

- RPC exists with no arguments;
- authenticated execution is allowed;
- anon, service_role and PUBLIC execution are denied as recorded;
- authenticated positive smoke passed;
- immediate repeated-call idempotency passed;
- synthetic cleanup completed.

PR #108 does not change the migration, RPC body, grants or Supabase state.

## 4. PR-02 code evidence

Exact implementation anchor:

```text
c458461e810e24adb7d71f7d155be06e9cf54eac
```

Established by the Git diff:

- one changed file: `src/App.jsx`;
- intended mandatory-password direct patch removed;
- one frontend RPC call added without user identifiers;
- strict boolean `true` required before UI completion;
- `corretorId` removed only from the intended component and call;
- no database or infrastructure file changed.

Established by GitHub Actions:

```text
Workflow run: 30411229438
Job: 90447536855
Command: npm run build
Exit code: 0
Conclusion: success
```

The build evidence remains fresh for the unchanged `src/App.jsx` blob after a documentation-only commit. It must be refreshed after any code, dependency or build-workflow change.

## 5. Search evidence

Repository-wide GitHub searches were executed for:

```text
marcar_senha_inicial_definida
must_change_password:false
sb.patch("corretores"
```

Current interpretation:

- PR #108 adds the intended frontend RPC call;
- the targeted mandatory-password direct patch is removed;
- a separate administrative direct patch remains in `EditarCorretorModal`;
- broad removal of direct `corretores` writes is not established.

Search indexing, branch head and repository content are freshness dimensions. Repeat the search at the exact deployment candidate before PR-03.

## 6. Evidence boundary

Established:

- bounded frontend diff;
- static fail-closed gate in code;
- successful frontend build at the implementation commit;
- Vercel Preview status success;
- no secret or sensitive literal introduced by the diff;
- administrative direct-patch residual explicitly preserved.

Not established:

- interactive success UI behavior;
- interactive RPC failure/unavailable behavior;
- deployed frontend proof;
- production frontend smoke;
- rollback execution;
- complete absence of required direct password-state updates;
- direct UPDATE denial;
- F1-02 acceptance;
- Security Go;
- WDP.

A Preview or build is not production evidence.

## 7. Lifecycle evidence

```text
PR-02 planned contract: canonical master plan
PR-02 implementation: PUBLISHED
PR-02 static validation: PASS
PR-02 domain security audit: PENDING
PR-02 operational validation: PENDING
PR-02 lifecycle validation: PENDING
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Deployment: NOT AUTHORIZED
Production smoke: NOT AUTHORIZED
PR-03: BLOCKED
```

## 8. Invalidation events

Revalidate the affected scope after:

- any PR #108 head change affecting `src/App.jsx`;
- dependency or lockfile change;
- build-workflow change;
- RPC signature, body, owner, search path or grant change;
- Auth/RLS/policy/role change affecting the call;
- deployment to a different build than the audited head;
- contradictory runtime evidence;
- a new material security finding.

Not invalidation events:

- opening a new conversation;
- changing specialist;
- a documentation-only update that leaves the code blob unchanged;
- a generic request to repeat an already exact-head audit without material change.

## 9. Anti-loop rule

A re-audit request must identify:

```text
1. nominal gate;
2. owner;
3. prior anchor;
4. exact changed evidence;
5. triggered invalidation rule;
6. exact revalidation scope.
```

Otherwise:

```text
AUDIT_LOOP_BLOCKED
```
