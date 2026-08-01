# FECH.AI — SFJM Evidence Freshness

**Status:** `EVIDENCE_FRESHNESS_REGISTER / PR02_STATIC_EVIDENCE_CURRENT / RUNTIME_CUTOVER_UNPROVEN / FAIL_CLOSED`  
**Observed on:** `2026-07-31`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Freshness rule

Evidence is valid only for the exact repository, environment, branch or commit, object set, configuration and lifecycle state observed. Versioned code, merged state, deployed state, live database state and executed runtime tests remain distinct.

A documentation-only head change does not invalidate a successful build of unchanged frontend code. A code, dependency, workflow, RPC contract or environment change does.

## 2. GitHub anchors

```text
Canonical main:
a909679143ec2e9a53f0a3108e5240a91a138fc1

PR #111:
CLOSED / MERGED
squash: d9c306b6278aba5f72a29892e98318ffb2d2405c
material effect: Group A canonical skills reconciled

PR #110:
CLOSED / MERGED
squash: a909679143ec2e9a53f0a3108e5240a91a138fc1
material effect: Builders continuity handoff canonical

PR #109:
CLOSED / NOT MERGED
head: 1a3c72e7b73a07ec7f6f30832c8d18e03c6b2827
disposition: SUPERSEDED_BY_PR_108

PR #108:
OPEN / DRAFT / NOT MERGED
recorded base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
live branch: security/f1-02-password-flow-cutover-1
implementation commit: c458461e810e24adb7d71f7d155be06e9cf54eac
prior documentation head: bec8b2531486e76c546ddee1d3e2d8b419e220be
current head: resolve live from PR metadata
```

The main drift from PR #111 and PR #110 is documentation-only and has no changed-path overlap with PR #108. It requires continuity reconciliation, not code revalidation or rebase by itself.

## 3. PR-01 evidence retained

The previously versioned PR-01 evidence remains applicable to the unchanged RPC and recorded catalog contract:

- RPC exists with no arguments;
- authenticated execution is allowed;
- anon, service_role and PUBLIC execution are denied as recorded;
- authenticated positive smoke passed;
- immediate repeated-call idempotency passed;
- synthetic cleanup completed.

PR #108 does not change the migration, RPC body, grants or Supabase state. This record does not independently refresh the live catalog.

## 4. PR-02 code evidence

Exact anchors preserved across this documentation-only reconciliation:

```text
Implementation commit:
c458461e810e24adb7d71f7d155be06e9cf54eac

src/App.jsx blob:
2541813e6af44f4e8112296b7d9666df9320db5d

PR-02 evidence document blob:
29c0c2a9a79aea71f543a0dd245244952dbe995d
```

Established by the Git diff:

- one functional file: `src/App.jsx`;
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

The build evidence remains fresh only while the code blob, dependencies and build workflow remain unchanged.

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

Repeat the search at the exact deployment candidate before PR-03.

## 6. Builder evidence boundary

PR #111 and PR #110 establish canonical documentation for Group A and Builder continuity. They do not prove:

- current external Builder configuration;
- product behavior;
- frontend deployment;
- Supabase catalog state;
- Security Go.

Builder evidence and product/security evidence remain separate classes.

## 7. Evidence boundary for PR #108

Established:

- bounded frontend diff;
- static fail-closed gate in code;
- successful frontend build at the implementation commit;
- Vercel Preview success;
- no secret or sensitive literal introduced by the diff;
- administrative direct-patch residual explicitly preserved;
- six-file SFJM reconciliation after PR #111, PR #110 and PR #109 disposition.

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

## 8. Lifecycle evidence

```text
PR-02 planned contract: canonical master plan
PR-02 implementation: PUBLISHED
PR-02 static validation: PASS
Post-#110 SFJM reconciliation: PUBLISHED THROUGH ONE SQUASH COMMIT
PR-02 domain security audit: PENDING
PR-02 operational validation: PENDING
PR-02 lifecycle validation: PENDING
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Deployment: NOT AUTHORIZED
Production smoke: NOT AUTHORIZED
PR-03: BLOCKED
```

## 9. Invalidation events

Revalidate the affected scope after:

- any PR #108 head change affecting `src/App.jsx` or the evidence document;
- dependency or lockfile change;
- build-workflow change;
- RPC signature, body, owner, search path or grant change;
- Auth/RLS/policy/role change affecting the call;
- deployment to a different code blob than the audited head;
- contradictory runtime evidence;
- a new material security finding.

Not invalidation events:

- opening a new conversation;
- changing specialist;
- a documentation-only update that preserves the two anchored blobs;
- the canonical documentation-only merges of PR #111 and PR #110;
- a generic request to repeat an exact-head gate without material change.

## 10. Anti-loop rule

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
