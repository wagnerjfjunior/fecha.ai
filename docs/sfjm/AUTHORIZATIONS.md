# FECH.AI — SFJM Authorizations

**Status:** `AUTHORIZATION_REGISTER / FINAL_RQ02_CORRECTION_CONSUMED / FAIL_CLOSED`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Interpretation rule

Authority is valid only for the exact repository, target, environment, files, operations, prohibitions and expiration stated by the Product Authority. General language never authorizes Ready, merge, production application, runtime changes, Security Go or F1-02 acceptance.

## 2. Canonical anchors

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #102: CLOSED / MERGED
PR #103: OPEN / DRAFT / FROZEN
PR #103 head: abf6b4026343eae437283280269ed2997911dcec
PR #104: OPEN / DRAFT
PR #104 branch: security/gpt3-supabase-catalog-gateway
```

## 3. PR #103 freeze

Authorized:

```text
read-only inspection: YES
exact-head audit after gateway availability: YES
```

Not authorized:

```text
commits: NO
metadata changes: NO
Ready: NO
merge: NO
Supabase application: NO
runtime tests: NO
```

## 4. Final PR #104 correction authority

The Product Authority authorized one final commit from parent:

```text
134e0a8717a5cbd67e490af4c1bcd2fd2e3c8cd6
```

Authorized paths, exactly:

```text
supabase/functions/gpt-especialista/index.ts
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

Authorized technical objective:

- resolve only GPT3 RQ-02;
- validate snapshot timestamp;
- validate `table` property types;
- validate complete structural column types;
- require JSON-object items in catalog metadata arrays.

Authorized documentary objective:

- reconcile SFJM and evidence with the actual audit sequence;
- record that GPT0 and GPT1 are not repeated;
- direct the next gate to a targeted GPT3 re-audit and final GPT4 gate.

Authorized PR metadata action:

- update only the PR #104 description with the new head and audit state.

## 5. Expiration and consumed state

This authority expires when the one seven-file commit is attached to the PR #104 branch and the PR description is reconciled.

After that:

```text
additional commits: NOT AUTHORIZED
GPT0 repeat: NOT AUTHORIZED
GPT1 repeat: NOT AUTHORIZED
GPT3 targeted read-only re-audit: AUTHORIZED
GPT4 final read-only gate: AUTHORIZED
```

## 6. Explicit non-authorizations

The final correction does not authorize:

- migration or other SQL application;
- live creation or replacement of the RPC;
- Edge deployment;
- GPT Action update;
- `verify_jwt` change;
- secret reading, disclosure or rotation;
- application-row or `auth.users` reads;
- Ready;
- merge;
- PR #103 change or application;
- Security Go;
- F1-02 acceptance;
- WDP.

## 7. Future authorities

`TECHNICAL_PR_LIFECYCLE` remains required for Draft → Ready and exact-head merge after the remaining gates.

`CONTROLLED_BETA_PRIMARY_CHANGE` remains required for any live migration, RPC verification, Edge deploy, Action update and runtime tests.

`SECURITY_GATE` remains required for Security Go or F1-02 acceptance.

## 8. Current authority state

```text
Final RQ-02 correction: CONSUMED BY THIS COMMIT
Further PR #104 commits: NOT AUTHORIZED
GPT3 targeted re-audit: AUTHORIZED
GPT4 final gate: AUTHORIZED
Ready: NOT AUTHORIZED
Merge: NOT AUTHORIZED
Live Supabase / Edge / Action: NOT AUTHORIZED
PR #103 change/application: NOT AUTHORIZED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```
