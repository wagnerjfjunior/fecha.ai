# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / PR108_DRAFT / PR02_IMPLEMENTATION_CONSUMED / FAIL_CLOSED`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, object, operation, scope, prohibitions and expiration stated by Product Authority. Recording a consumed authority does not reactivate it.

## 2. Relevant consumed authorities

```text
PR #103 implementation, merge, production application and smoke: CONSUMED
PR #107 audit, Ready and squash-merge authorities: CONSUMED
PR #107 squash merge: EXECUTED
PR-02 branch and bounded implementation authority: CONSUMED
PR-02 Draft PR creation authority: CONSUMED
PR-02 seven-document reconciliation authority: CONSUMED ON PUBLICATION
PR #108 body correction authority: CONSUMED ON UPDATE
```

## 3. PR-02 authorized object

```text
Repository: wagnerjfjunior/fecha.ai
Canonical base: main@cec1b22430adf1a002b172992cf6c5ea5bb427de
PR: #108 — security: route password completion through RPC
Planned branch: security/f1-02-password-flow-cutover
Live branch: security/f1-02-password-flow-cutover-1
Initial implementation commit: c458461e810e24adb7d71f7d155be06e9cf54eac
State: OPEN / DRAFT / NOT MERGED
```

The branch suffix divergence is non-material. PR #108 and its exact live head are the operational anchors.

Authorized paths for the bounded PR-02 publication:

```text
src/App.jsx
docs/security/evidence/2026-07-28-pr02-password-flow-cutover.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

Authorized implementation effect:

- replace only the mandatory-password direct patch with `marcar_senha_inicial_definida()`;
- remove `corretorId` only from `TrocarSenhaObrigatoria` and its call;
- require strict `true` before `onConcluido()`;
- preserve the separate administrative direct patch;
- execute static validation and repository-wide searches;
- keep the PR Draft.

## 4. Current non-authorizations

```text
additional frontend or runtime code change
change to the preserved EditarCorretorModal administrative patch
new administrative RPC
Supabase or database mutation
migration or RPC-body change
Auth, RLS, policy, grant or role change
Edge Function or GitHub Actions change
manual Vercel deployment
production deployment or production smoke
Ready for review
approval
merge
auto-merge
PR-03
Security Go
F1-02 acceptance
WDP change
```

No audit result automatically authorizes the next lifecycle transition.

## 5. Read-only work allowed by current routing

The next action is an independent GPT3 security/code-contract audit at the exact PR #108 head. Read-only inspection does not authorize comment, review submission, metadata change, Ready, merge, deployment or production access.

## 6. Future authorities required

New explicit Product Authority is required for:

- any code or documentary commit after the current bounded publication;
- any review submission or PR comment;
- Ready transition;
- merge;
- deployment or production smoke;
- modification or replacement of the administrative direct patch;
- PR-03;
- F1-02 acceptance or Security Go.
