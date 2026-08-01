# FECH.AI — PR-02 Password Flow Cutover Evidence

**Status:** `DRAFT_IMPLEMENTED / STATIC_VALIDATION_PASSED / NOT_DEPLOYED / NOT_ACCEPTED`  
**Observed on:** `2026-07-28`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Program:** `F1-02 / J1 / PR-02`

## 1. Canonical anchors

```text
Canonical main at branch creation:
cec1b22430adf1a002b172992cf6c5ea5bb427de

PR:
#108 — security: route password completion through RPC

Live branch:
security/f1-02-password-flow-cutover-1

Initial implementation commit:
c458461e810e24adb7d71f7d155be06e9cf54eac

Documentation reconciliation commit:
resolve live from PR #108 head
```

The live branch name contains the suffix `-1`. This is a nominal divergence from the planned branch name and does not change the code contract.

## 2. Authorized objective

Replace only the confirmed mandatory-password completion path in `src/App.jsx`:

```text
change password
→ direct PATCH corretores.must_change_password = false
→ continue UI
```

with:

```text
change password
→ authenticated public.marcar_senha_inicial_definida()
→ require strict boolean true
→ continue UI
```

No broad `App.jsx` refactor, database change or production mutation belongs to PR #108.

## 3. Exact implementation delta

The implementation commit changes only `src/App.jsx`:

- removes `corretorId` from `TrocarSenhaObrigatoria`;
- removes `corretorId` from the component call;
- removes the intended direct `PATCH` to `corretores.must_change_password`;
- calls `sb.rpc("marcar_senha_inicial_definida", {}, token)`;
- requires `concluido === true`;
- throws an error before `onConcluido()` when the RPC does not return `true`;
- preserves the existing password change through Supabase Auth.

Implementation statistics:

```text
1 file changed
6 additions
3 deletions
```

## 4. Static validation

GitHub Actions validated the implementation commit:

```text
Workflow run: 30411229438
Workflow: MesaCliente 17D - Build Validation
Job: 90447536855 / Run 17D build validation
Command: npm run build
Exit code: 0
Conclusion: success
```

The workflow checked out PR #108, installed dependencies, ran the frontend build and failed closed if install or build returned a nonzero exit code.

Other pull-request workflows on the implementation head also completed successfully. Vercel reported a successful Preview status. These signals do not prove production runtime behavior or Security Go.

## 5. Call-site searches

Repository-wide GitHub searches were performed for:

```text
marcar_senha_inicial_definida
must_change_password:false
sb.patch("corretores"
```

Results and exact-head reconciliation:

- the canonical `main` contains the RPC migration and documentary references;
- PR #108 adds exactly one frontend call to `marcar_senha_inicial_definida` in `TrocarSenhaObrigatoria`;
- the intended mandatory-password direct patch is removed by the PR patch;
- one administrative direct patch remains in `EditarCorretorModal` for a manager/admin password-reset path;
- PR #108 does not claim that all direct `corretores` writes have been removed.

The preserved administrative path cannot use the self-service RPC because `marcar_senha_inicial_definida()` derives the target from `auth.uid()` and accepts no target user identifier.

## 6. Sensitive-data review

The PR diff introduces no:

- password value;
- JWT value;
- access token value;
- Supabase key;
- secret;
- customer, lead or commercial payload;
- logging of token or sensitive payload.

The existing `session.access_token` variable remains passed as an in-memory authentication value; no literal token is versioned.

## 7. Evidence boundary

Established by versioned diff and CI:

- intended call site routes through the narrow RPC;
- RPC is called without user or broker identifiers;
- the UI completion callback is gated on strict `true`;
- the intended direct password-state patch is absent from that path;
- frontend build succeeds at the implementation commit;
- no out-of-scope file is changed by the implementation commit.

Not established:

- interactive success UI execution;
- interactive RPC-unavailable/failure execution;
- deployed frontend proof;
- production frontend smoke;
- rollback execution;
- denial of the legacy direct table update;
- resolution of the administrative direct patch;
- F1-02 acceptance;
- Security Go;
- WDP.

Static fail-closed control is present in code. Runtime fail-closed behavior remains to be demonstrated after separately authorized deployment.

## 8. Residual risk and PR-03 dependency

```text
Administrative EditarCorretorModal direct PATCH: PRESERVED
PR-03: BLOCKED
Reason: PR-02 must be merged, deployed and proven, and no required direct
        password-state update may remain before broad direct UPDATE revocation.
```

PR #108 must not silently introduce a new administrative RPC. That would be a separate server-side authorization contract requiring independent design and audit.

## 9. Rollback

Repository rollback is a revert of PR #108 or its eventual squash commit. No database rollback is required by this PR because it changes no migration, RPC body, grant, policy, RLS rule or data.

## 10. Current lifecycle

```text
PR #108: OPEN / DRAFT / NOT MERGED
Implementation: PUBLISHED
Static build: PASS
Documentation: PUBLISHED IN SAME DRAFT PR
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Deployment: NOT AUTHORIZED
Production smoke: NOT AUTHORIZED
PR-03: BLOCKED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 11. Next safe action

Run one independent GPT3 security/code-contract audit of PR #108 at the exact live head. The audit must remain read-only and must not mark Ready, merge, deploy or alter Supabase.
