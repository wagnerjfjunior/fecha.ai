# FECH.AI — SFJM Next Safe Action

**Status:** `F1_02_ACTIVE_READ_ONLY_AUTHORIZATION_REQUIRED / EXECUTION_NOT_AUTHORIZED`  
**Observed on:** 2026-07-24

## Current safe state

PR #99 is closed and squash-merged into canonical `main` at:

```text
573ecebbafc2fb0ea4a065905e0f592b9db2a308
```

Its final head was:

```text
754e35406971e72ce29763bf145060868914b4d7
```

PR #99 passed independent audit and pre-merge verification with `PASS WITH RESIDUAL RISK`. Two post-Ready review threads were answered and resolved without changing the audited head. The PR reconciled the post-PR #98 documentation state only. It did not accept F1-01, grant Security Go, award WDP or validate runtime/Supabase.

All PR #99 creation, Ready, thread-resolution, verification and merge authorities are `CONSUMED`.

The bounded documentation-only closure PR containing this record is self-closing. Its own merge does not create another reconciliation requirement unless a material operational-state change occurs.

```text
NO ACTIVE WRITE AUTHORIZATION
NO ACTIVE READ-ONLY F1-02 AUTHORIZATION
NO AUTHORITY FOR ADDITIONAL COMMITS
NO AUTHORITY FOR READY
NO AUTHORITY FOR MERGE
F1-02: PLANNED / NOT_AUTHORIZED
```

## Next single safe action

Request a separate, narrowly scoped `ACTIVE_READ_ONLY` authorization for:

```text
F1-02 — read-only Supabase security evidence refresh and negative-test design
```

The authorization must identify the exact Supabase project and environment and must remain fail-closed. No Supabase read may begin before that authorization exists.

## Required F1-02 bootstrap

Before any Supabase read:

- confirm repository and live canonical `main`;
- identify the exact Supabase project and environment;
- confirm access is read-only;
- map every current M1 RPC and direct-DML path from the merged F1-01 inventory;
- declare evidence available and missing;
- prohibit all mutations;
- define evidence capture, sanitization and expiration.

## Authorized read-only targets when separately approved

The first F1-02 phase may inspect only the current state of:

- grants for used M1 RPCs and relevant tables;
- RLS enablement and policies for affected tables;
- bodies/signatures of used M1 RPCs;
- direct PostgREST `PATCH corretores` exposure;
- server-side tenant/company/user derivation;
- actor, lead, list, stage and broker ownership checks;
- current project/environment identifiers needed to establish provenance.

## Required negative-test design

The read-only phase must produce, but not execute against production without separate approval, a matrix covering:

- no session;
- invalid or expired token;
- wrong company/tenant;
- forged lead ID;
- forged list ID;
- forged stage ID;
- forged broker/corretor ID;
- mixed-tenant batch IDs;
- unauthorized visibility targets;
- invalid feedback/channel/sequence payloads.

## Paths that must not be omitted

At minimum:

- `proximo_lead` via guarded Aceleração bridge;
- direct `proximo_lead` in Discador;
- `registrar_feedback` via guarded bridge;
- direct `registrar_feedback` in Discador;
- `atualizar_feedback`;
- `mover_funil`;
- `mover_funil_lote`;
- `registrar_mensagem`;
- `distribuir_lotes`;
- `criar_lista`;
- `gerenciar_visibilidade_lista`;
- `importar_leads_batch`;
- `get_dashboard_stats`;
- `minha_producao`;
- direct `PATCH corretores` call sites.

## Explicitly prohibited

This record does not authorize:

- Supabase reads without a separate F1-02 authorization;
- Supabase writes;
- migrations;
- RLS, grants, policies or RPC changes;
- negative tests against production;
- runtime or frontend changes;
- Edge Functions;
- Vercel or GitHub Actions changes;
- production changes;
- Security Go;
- F1-01 acceptance;
- F1-02 execution;
- WDP assignment;
- another documentation-only reconciliation solely to record the closure PR's own merge.

## Required authorization record

Before F1-02 begins, the authorization must state:

- source and date;
- repository and live canonical commit;
- exact Supabase project/environment;
- read-only scope;
- allowed metadata, policies, grants, RPCs and tables;
- prohibited mutations;
- acceptance criteria;
- evidence sanitization rules;
- rollback expectation (`no mutation`; stop and revoke access if scope is uncertain);
- expiration condition.

Until that separate authorization exists, preserve the current state without mutation.