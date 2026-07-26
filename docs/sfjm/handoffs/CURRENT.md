# FECH.AI — SFJM Current Handoff

**Status:** `CURRENT_HANDOFF / PR104_GATEWAY_DRAFT / PR103_FROZEN`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision

The Product Authority authorized the start of a parallel, bounded GPT3 Supabase catalog-gateway plan.

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
MVP: MVP 1 — Família
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

PR #103 is frozen. PR #104 exists only to provide the missing read-only catalog evidence path required for a renewed GPT3 audit.

## 2. Canonical anchors

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
PR #101: CLOSED / MERGED
PR #101 final head: 003850d012a299a947452fa5a8135cd454998f15
PR #101 squash: affbae1a598928010b0fa7db967734de522c13b4
PR #102: CLOSED / MERGED
PR #102 final head: 26395a5751ded7f3bc6908f36615f761d709199c
PR #102 squash: b685b360404bbfd0a84a4b755b3092ee35a20e5e
Master-plan blob: ea161050c535b848ff927133830984f543c1104d
```

## 3. Frozen PR #103

```text
PR: #103
Title: security: add narrow password-state RPC
State: OPEN / DRAFT
Base: b685b360404bbfd0a84a4b755b3092ee35a20e5e
Branch: security/f1-02-password-state-rpc
Head: abf6b4026343eae437283280269ed2997911dcec
Commits: 5
Changed files: 1
```

Do not change the branch, head, migration, PR description or metadata.

GPT3 result at this head:

```text
Static contract: ACCEPTABLE
Concrete new code defect: NONE
Catalog evidence: INCONCLUSIVE
Ready recommendation: NO
```

The blocker is evidence availability.

## 4. Active PR #104

```text
PR: #104
Title: security: add bounded GPT3 Supabase catalog gateway
State: OPEN / DRAFT
Base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
Branch: security/gpt3-supabase-catalog-gateway
Final head: resolve live
Expected changed files: 10
```

Primary risk:

```text
Bounded exposure of only the PostgreSQL security metadata required
for PR #103 revalidation, without row data, auth.users, secrets,
arbitrary SQL or caller-selected objects.
```

Versioned implementation:

```text
supabase/migrations/20260726180000_gpt_security_metadata_snapshot.sql
supabase/functions/gpt-especialista/index.ts
docs/integrations/gpt3-supabase-action.openapi.yaml
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
six SFJM continuity documents
```

## 5. Live Supabase state

```text
Project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Region: sa-east-1
Status: ACTIVE_HEALTHY
PostgreSQL: 17.6.1
Edge Function: gpt-especialista
Edge version: 7
Edge status: ACTIVE
verify_jwt: false
health_check: WORKING
security_metadata_snapshot operation: PRESENT IN EDGE/ACTION
public.gpt_security_metadata_snapshot(): ABSENT
```

The user declared the integration secret rotated. Never retrieve or record its value.

## 6. Read-only validation completed

The fixed SELECT body was executed under `service_role` inside a rolled-back transaction.

```text
Query parsed: YES
service_role catalog access: YES
Persistent mutation: ZERO
Business-row reads: ZERO
auth.users reads: ZERO
Secrets returned: ZERO
```

Returned evidence covered the PR #103 table, columns, UNIQUE index, constraints, RLS, policies, trigger/function, roles, memberships, privileges, default ACL, `auth.uid()` and `plpgsql`.

This proves only the query contract and catalog visibility. It does not prove migration application, final RPC ACL, Edge deployment or Action success.

## 7. Gateway architecture

```text
GPT3 Action
→ custom x-gpt-action-key authentication
→ versioned Edge handler
→ exact operation allowlist
→ fixed no-argument SECURITY INVOKER RPC
→ service_role EXECUTE only
→ fixed pr103_preflight_v1 snapshot
```

The Edge rejects extra request fields, wrong content type and oversized bodies. It validates the returned snapshot scope before responding.

## 8. Current prohibitions

```text
PR #103 commits/metadata: PROHIBITED
PR #103 Ready/merge/application: PROHIBITED
PR #104 additional files: PROHIBITED
PR #104 Ready/merge: NOT AUTHORIZED
Live migration/RPC creation: NOT AUTHORIZED
Live Edge deploy: NOT AUTHORIZED
Live Action update: NOT AUTHORIZED
Secret access/disclosure: PROHIBITED
Application-row/auth.users reads: PROHIBITED
Security Go: DENIED
F1-02 acceptance: NOT AUTHORIZED
WDP: 0
```

## 9. Evidence missing

- final PR #104 head validation;
- GPT0/GPT1/GPT3/GPT4 exact-head audits;
- Ready/merge authority and squash commit;
- live migration application;
- final live RPC owner/search_path/ACL evidence;
- versioned Edge deployment;
- Action reconciliation;
- positive and negative gateway tests;
- renewed GPT3 audit of PR #103;
- PR #103 lifecycle/application gates.

## 10. Single next safe action

Run GPT0 against the exact final PR #104 head and exact ten-file diff.

Only after GPT0 recommends Ready may GPT1, GPT3 and GPT4 audit the same head. Any new commit invalidates that chain.

## 11. What must not be redone

- do not reconstruct F1-02 from zero;
- do not modify PR #103 to solve an evidence-access problem;
- do not create another broad SQL gateway;
- do not add arbitrary SQL, table names or filters;
- do not expose all database function source;
- do not treat the read-only SELECT as migration/deploy evidence;
- do not apply live changes before separate authority;
- do not create a documentation-only reconciliation PR solely to record a later merge.

## 12. Future sequence

```text
PR #104 exact-head audits
→ separate lifecycle authority
→ Ready/revalidation/squash merge
→ separate CONTROLLED_BETA_PRIMARY_CHANGE
→ migration/ACL verification
→ Edge deploy
→ Action update
→ gateway tests/evidence
→ GPT3 PR #103 re-audit at abf6b402...
```
