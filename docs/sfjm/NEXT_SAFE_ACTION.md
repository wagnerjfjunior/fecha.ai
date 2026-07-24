# FECH.AI — SFJM Next Safe Action

**Status:** `F1_02_READ_ONLY_WORKSTREAM_SELECTED / EXECUTION_NOT_AUTHORIZED`  
**Observed on:** 2026-07-24

## Current safe state

PR #94 is closed and squash-merged into canonical `main` at:

```text
1caf90c60681771af6609b96ee840b190668fa0f
```

The corrected F1-01 evidence map passed independent reaudit with residual risk and is now canonical documentation. This does not accept F1-01, grant Security Go, award WDP or validate runtime/Supabase.

The present authorization covers only this post-merge documentation reconciliation branch and Draft PR. It does not authorize F1-02 execution or merge.

## Next single safe workstream

```text
F1-02 — read-only Supabase security evidence refresh and negative-test design
```

The workstream must remain fail-closed and must begin with a separate explicit authorization.

## Required F1-02 bootstrap

Before any Supabase read:

- confirm repository and canonical `main`;
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
- WDP assignment;
- merge of this reconciliation PR.

## Required authorization record

Before F1-02 begins, the authorization must state:

- source and date;
- repository and canonical commit;
- exact Supabase project/environment;
- read-only scope;
- allowed metadata, policies, grants, RPCs and tables;
- prohibited mutations;
- acceptance criteria;
- evidence sanitization rules;
- rollback expectation (`no mutation`; stop and revoke access if scope is uncertain);
- expiration condition.

Until that separate authorization exists, preserve the current state without mutation.
