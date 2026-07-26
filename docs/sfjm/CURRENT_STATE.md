# FECH.AI — SFJM Current State

**Lifecycle state:** `GPT3_CATALOG_GATEWAY_DRAFT / PR103_FROZEN / SECURITY_GO_DENIED`  
**Record type:** `OPERATIONAL_STATE / PARALLEL_SECURITY_ENABLEMENT`  
**Observed on:** `2026-07-26`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Product context

```text
Operational status: PILOT PRODUCTION / LIVE
Commercial model: CONTROLLED FREE BETA
Product phase: MVP 1 — Família
Real users/data: YES
Multiple companies: YES
Broad paid commercialization: BLOCKED
Security Go: DENIED
F1-02: ACTIVE REMEDIATION / BLOCKED
WDP: 0
```

Accepted beta risk remains limited to downtime, maintenance, manual recovery and possible beta-data loss. It is not a waiver for privilege escalation, cross-tenant access, disclosure, unauthorized mutation or weak evidence.

Frontend/Action requests. Edge/RPC/Supabase validates and decides. AI assists but is not authority.

## 2. Canonical main

```text
main: b685b360404bbfd0a84a4b755b3092ee35a20e5e
Source PR: #102
PR #102: CLOSED / MERGED
PR #102 final head: 26395a5751ded7f3bc6908f36615f761d709199c
PR #102 squash: b685b360404bbfd0a84a4b755b3092ee35a20e5e
```

The F1-02 controlled-beta strategy is canonical on `main`.

## 3. PR #103 — frozen remediation PR

```text
PR: #103
Title: security: add narrow password-state RPC
State: OPEN / DRAFT
Base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
Branch: security/f1-02-password-state-rpc
Head: abf6b4026343eae437283280269ed2997911dcec
Commits: 5
Changed files: 1
```

Freeze contract:

```text
Additional commits: PROHIBITED
Metadata changes: PROHIBITED
Ready: PROHIBITED
Merge: PROHIBITED
Supabase application: PROHIBITED
```

GPT3 found no new concrete migration defect. Its verdict remained `INCONCLUSIVE` only because the available GPT gateway exposed `health_check` with `database_access: false` and could not independently reproduce the required live catalog evidence.

## 4. PR #104 — parallel catalog gateway

```text
PR: #104
Title: security: add bounded GPT3 Supabase catalog gateway
State: OPEN / DRAFT
Base: main@b685b360404bbfd0a84a4b755b3092ee35a20e5e
Branch: security/gpt3-supabase-catalog-gateway
Final head: resolve from live PR metadata
Primary risk: bounded exposure of security catalog metadata
```

Expected net scope:

```text
supabase/migrations/20260726180000_gpt_security_metadata_snapshot.sql
supabase/functions/gpt-especialista/index.ts
docs/integrations/gpt3-supabase-action.openapi.yaml
docs/security/evidence/2026-07-26-gpt3-supabase-catalog-gateway.md
docs/sfjm/AUTHORIZATIONS.md
docs/sfjm/BLOCKED_ACTIONS.md
docs/sfjm/CURRENT_STATE.md
docs/sfjm/EVIDENCE_FRESHNESS.md
docs/sfjm/NEXT_SAFE_ACTION.md
docs/sfjm/handoffs/CURRENT.md
```

PR #104 does not modify PR #103.

## 5. Live Supabase state

```text
Project: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Environment: production
Edge Function: gpt-especialista
Edge version observed: 7
Edge status: ACTIVE
verify_jwt: false
Custom authentication: x-gpt-action-key
health_check: WORKING
security_metadata_snapshot operation: PRESENT IN EDGE/ACTION
public.gpt_security_metadata_snapshot(): ABSENT
```

The secret previously visible in a capture was rotated by the user. The value is not recorded.

The active live configuration is partial: the Edge operation exists but the RPC does not. PR #104 versions the intended final contract; it does not apply it.

## 6. Read-only evidence executed

A fixed catalog SELECT equivalent to the proposed RPC body was executed under:

```text
BEGIN
SET LOCAL ROLE service_role
SELECT fixed PR103 catalog snapshot
ROLLBACK
```

Result:

```text
Query parsed: YES
Execution as service_role: YES
Persistent writes: ZERO
Business-row reads: ZERO
auth.users reads: ZERO
Secrets returned: ZERO
```

The result included the table/columns, UNIQUE index, constraints, RLS, policies, triggers, trigger-function definition, roles, memberships, effective privileges, default function ACL, `auth.uid()` and `plpgsql`.

This is query-contract evidence. It is not migration-application evidence.

## 7. Current authority state

```text
PR #104 WINDOW_IMPLEMENTATION:
CONSUMED BY THE FINAL DRAFT IMPLEMENTATION COMMIT

Further PR #104 commits after final head:
NOT AUTHORIZED without bounded correction authority

PR #104 Ready:
NOT AUTHORIZED

PR #104 merge:
NOT AUTHORIZED

Live Supabase migration/deploy/Action change:
NOT AUTHORIZED

PR #103 change or application:
NOT AUTHORIZED

Security Go:
DENIED

F1-02 acceptance:
NOT AUTHORIZED

WDP:
0
```

The final Draft commit cannot contain its own SHA. Live PR metadata and the final PR description are authoritative for the head.

## 8. Evidence available

- live `main` and PR #102 merge anchors;
- live PR #103 metadata and exact frozen head;
- GPT3 PR #103 audit identifying an evidence-only blocker;
- active Edge Function version 7 source;
- absence of `public.gpt_security_metadata_snapshot()`;
- successful fixed catalog query under `service_role` with rollback;
- PR #104 versioned migration, Edge source, OpenAPI, evidence and SFJM.

## 9. Evidence absent

- independent exact-head GPT0/GPT1/GPT3/GPT4 audits of PR #104;
- PR #104 Ready and merge authority;
- PR #104 merge;
- live application of the PR #104 migration;
- live deploy of the versioned Edge Function;
- live Action reconciliation to the versioned OpenAPI;
- successful GPT Action `security_metadata_snapshot`;
- negative gateway tests after deployment;
- renewed GPT3 audit of PR #103;
- PR #103 lifecycle and application gates.

## 10. Next safe action

Complete PR #104 at one final Draft head, then run GPT0 against that exact head.

Do not alter PR #103, mark either PR Ready, merge, deploy the Edge Function, apply SQL, update the GPT Action or claim Security Go.
