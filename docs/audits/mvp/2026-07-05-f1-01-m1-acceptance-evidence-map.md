# FECH.AI — F1-01 M1 Acceptance Evidence Map

**Status:** `MERGED_EVIDENCE_CANDIDATE / REAUDIT_PASSED / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE`  
**B0 activity:** F1-01 — Final M1 evidence and acceptance map  
**Prepared on:** 2026-07-05  
**Corrected on:** 2026-07-24  
**Merged on:** 2026-07-24  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Decision and boundary

This document is the merged evidence map for **F1-01**. It maps every MVP1 acceptance item to a current path, evidence state, gap, owner role and next safe action.

It is deliberately fail-closed:

```text
- No MVP item is marked READY_FOR_MVP_VALIDATION in this document.
- No Security Go decision is made.
- No WDP is earned by creating, reviewing or merging this document alone.
- No runtime, frontend, Supabase, migration, RLS, grant, policy, RPC, Edge Function,
  Vercel, integration or production behavior is changed or authorized.
```

The corrected map passed independent reaudit with `PASS WITH RESIDUAL RISK` and was squash-merged through PR #94. That result confirms map completeness for its documentation purpose only. F1-01 checkpoint acceptance remains **NOT GRANTED**, Security Go remains **NOT GRANTED**, and accepted WDP remains **0**.

## 2. Operational bootstrap

| Bootstrap item | Record |
|---|---|
| Context understood | FECH.AI is Pilot Production, multi-tenant / multi-company, with real users and sensitive lead/client data. |
| Affected module / flow | MVP1 Família / M1 LeadOps, CRM, Discador, Power Mode and weekend operating visibility. |
| Environment | GitHub/versioned source is the evidence source for this documentation-only map. Runtime and live Supabase remain unverified. |
| Relevant decisions | B0 merged through PR #92; B0 operational register merged through PR #93; F1-01 precedes F1-02 Security Go. |
| PR/head/merge | PR #94 final head `a7e64c6ed817c03c4dbce7e1b9642e20360b3010`; squash commit `1caf90c60681771af6609b96ee840b190668fa0f`. |
| Files/areas inspected | `src/App.jsx`, `src/components/AceleracaoOperacional.jsx`, `src/services/aceleracaoOperacionalService.js`; product, M1 and security evidence documents listed below. |
| What must not change | Runtime, frontend, Supabase, migrations, RLS, grants, policies, RPC bodies, Edge Functions, Vercel, GitHub Actions, MesaCliente, ADS/CAPI, Make/n8n, integrations, production. |
| Available evidence | Current source blob `dc718403fe89c48143d68ac6b3b684b61330b078`; current Aceleração UI/service blobs; historical M1 runbooks; historical security inventories; PR #82 metadata; PR #94 audit and review evidence. |
| Missing evidence | Current live Supabase metadata/body/grant verification; authenticated runtime smoke tests; negative tenant-isolation tests; dedup semantics; persisted next-action behavior; weekend-visit semantics; import/error audit evidence. |
| Main risks | Treating code presence as product readiness; treating RPC invocation as authorization proof; omitting used paths from F1-02; treating local session metrics as persisted operational data; relying on stale live Supabase evidence. |
| Next safe action | Begin F1-02 only after separate read-only authorization identifies the exact Supabase project/environment and prohibits all mutations. |

## 3. Evidence source inventory

### 3.1 Current source evidence

| Source | Current blob / merge anchor | What it establishes | What it does not establish |
|---|---|---|---|
| `src/services/aceleracaoOperacionalService.js` | blob `37761cd05d93de6a9f7f3587a1ab481cb604b6a0` | The Aceleração bridge treats `proximo_lead` and `registrar_feedback` as sensitive and rejects an unusable/no-session token before `fetch`. | Backend authorization, tenant isolation, grant state, RPC body safety or live behavior. |
| `src/components/AceleracaoOperacional.jsx` | blob `7981ec2d9b79b7cf4e144da963fe0dbe05edd7d9` | UI uses the guarded bridge; call/WhatsApp/e-mail actions are opened client-side; session counters are local state. | Successful authenticated runtime, persisted metrics, audit/history integrity or backend access control. |
| `src/App.jsx` | blob `dc718403fe89c48143d68ac6b3b684b61330b078` | Current source contains import RPCs, direct Discador RPCs, messaging RPCs, funnel mutations, dashboard RPCs and direct `corretores` DML listed in section 5. | Live Supabase semantics, safe grants/RLS/RPC bodies, dedup result, tenant isolation, device smoke or operational correctness. |
| `docs/product/fechai-mvp-scope-v1.md` | blob `4fb642728e776aaaef14fecb08c92fdb95caa528` | `próxima ação` is a minimum MVP1 CRM field and quick action. | Implementation or persistence proof. |
| PR #82 | merge `0446cf4b5a6ae201adf44798a4aafc6e665429d9` | The fail-closed session guard was merged for the Aceleração service bridge. | That all M1 call paths share that containment or that current runtime tests passed. |
| PR #94 | squash `1caf90c60681771af6609b96ee840b190668fa0f` | The corrected map passed independent reaudit and merged with six review threads resolved. | F1-01 acceptance, Security Go, runtime or Supabase validation. |

### 3.2 Historical evidence — retained with freshness limits

| Source | Evidence value | Freshness / limitation |
|---|---|---|
| `docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-existing-evidence-map.md` | Consolidates source/RPC candidates and known gaps. | Historical documentation; not a current live-system assertion. |
| `docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-reconciliation-pass-2-ui-rpc-map.md` | Defines the map contract and allowed evidence statuses. | Runbook, not final evidence. |
| `docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md` | Identifies M1 RPC candidates and direct-DML risk. | Live grant status was pending reconciliation. |
| `docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md` | Historical sanitized live metadata/body indicators. | Evidence dated 2026-06-09; stale for current authorization. |

### 3.3 Evidence labels

| Label | Meaning |
|---|---|
| `CURRENT_SOURCE_CONFIRMED` | The exact versioned source blob was inspected and the narrow code fact is observable. |
| `HISTORICAL_DOCUMENTATION_ONLY` | A versioned record exists, but it does not prove current runtime or live Supabase state. |
| `STALE_LIVE_EVIDENCE` | Historical live metadata exists but is too old to authorize a current gate. |
| `NOT_CONFIRMED` | No sufficient source/runtime/live evidence was found for the claim. |

## 4. MVP acceptance map

The acceptance items derive from `docs/product/fechai-mvp-scope-v1.md`. No row is READY.

| MVP acceptance item | Current path / evidence | Evidence class | Current status | Gap or contradiction | Owner role | Next safe action |
|---|---|---|---|---|---|---|
| 1. Gestor/corretor imports simple list | `src/App.jsx` `handleImport` invokes `criar_lista`, optional `gerenciar_visibilidade_lista`, and batched `importar_leads_batch`; response accumulates valid, invalid and duplicate counts. | `CURRENT_SOURCE_CONFIRMED` | `SECURITY_REVIEW_REQUIRED` | Runtime result, server-side company derivation, dedup semantics, audit trail, retries and cross-tenant denial are unproven. | GPT7 + GPT1 + GPT3 | Validate exact RPC bodies/grants and one controlled non-PII import after separate authorization. |
| 2. System detects basic duplicates | Import response consumes `duplicados`/`skipped`, but no current dedup keys, rule, persistence behavior or reproducible result was confirmed. | `CURRENT_SOURCE_CONFIRMED` for response handling; `NOT_CONFIRMED` for decision semantics | `NOT_CONFIRMED` | Consuming a duplicate counter is not proof that duplicate detection is correct or tenant-safe. | GPT7 + GPT1 + GPT3 | Identify the server decision point, keys, outcome contract, persistence and audit evidence. |
| 3. Corretor opens call or WhatsApp in few clicks | Aceleração and `App.jsx` expose `tel:` and `wa.me` actions. | `CURRENT_SOURCE_CONFIRMED` | `NEEDS_CODE_VALIDATION` | Device behavior and CRM event registration are untested. | GPT7 + GPT2 | Run controlled mobile/desktop smoke under separate scope. |
| 4. Corretor registers status | Guarded Aceleração bridge and direct `DiscadorTab` call `registrar_feedback`; LeadModal also calls `atualizar_feedback`. | `CURRENT_SOURCE_CONFIRMED` | `SECURITY_REVIEW_REQUIRED` | Direct Discador does not inherit the bridge guard; backend ownership, allowlist, history and cross-company rejection remain unproven. | GPT3 + GPT7 + GPT1 | Test no-session, forged lead, invalid feedback and cross-tenant cases for each path. |
| 5. Funil shows leads by stage | Current source uses `listar_funil_estagios`, `mover_funil` and `mover_funil_lote`. | `CURRENT_SOURCE_CONFIRMED` | `SECURITY_REVIEW_REQUIRED` | Stage ownership, bulk validation, transition rules, history and cross-company rejection remain unproven. | GPT7 + GPT3 + GPT1 | Validate single and batch mutations with invalid stage, forged IDs and mixed-tenant sets. |
| 6. Dashboard shows scheduled weekend visits | Current dashboards invoke `get_dashboard_stats` and `minha_producao`; Aceleração separately maintains local counters. | `CURRENT_SOURCE_CONFIRMED` | `NOT_CONFIRMED` | Persisted paths exist, but weekend/scheduled-visit semantics, unknown-vs-zero handling, security and runtime result are not established. | GPT7 + GPT2 + GPT1 + GPT3 | Trace RPC fields to the product requirement and validate tenant-safe semantics. |
| 7. Data respects tenant/company/broker | Current source uses RPCs plus direct `sb.patch("corretores", ...)` at three call sites. | `CURRENT_SOURCE_CONFIRMED` + `STALE_LIVE_EVIDENCE` | `SECURITY_REVIEW_REQUIRED` | Frontend token use and call presence do not prove server-side tenant derivation, actor permission, RLS/grants or denial of manipulated targets. | GPT3 + GPT1 | Refresh live Supabase evidence and run the negative-test matrix over every used path. |
| 8. Minimum import and error logs exist | UI surfaces errors and import totals; client console/error handling exists. | `CURRENT_SOURCE_CONFIRMED` | `NOT_CONFIRMED` | Client display is not server-side auditing, correlation, retention or operational logging. | GPT5 + GPT7 + GPT3 | Identify audit tables/logs and define non-PII evidence. |
| 9. Flow works on mobile and desktop | Responsive CSS and M1 UI exist. | `CURRENT_SOURCE_CONFIRMED` | `NEEDS_CODE_VALIDATION` | No authenticated browser/device smoke, accessibility or failure-state validation is available. | GPT2 + GPT4 + GPT7 | Validate controlled desktop/mobile flows under separate scope. |
| 10. Rollback path exists | Git history supports reverts; historical records mention Vercel/revert behavior. | `HISTORICAL_DOCUMENTATION_ONLY` | `GPT4_VALIDATION_REQUIRED` | No current deployment linkage or rollback rehearsal is proven. | GPT4 + GPT5 | Confirm the current rollback procedure and safe non-production validation. |

### Supplemental MVP1 continuity items

| Item | Current evidence | Status | Required next action |
|---|---|---|---|
| Persistent next action / follow-up | `próxima ação` is required by the MVP1 contract. No persistent field/RPC/history/owner path was confirmed. | `NOT_CONFIRMED / REQUIRED IN MVP1` | Map or implement only through separately authorized scope; do not downgrade to M2 without a Baseline Change Record. |
| Power Mode execution loop | Aceleração uses a guarded bridge, while Discador invokes sensitive RPCs directly through `createSB.rpc`. | `SECURITY_REVIEW_REQUIRED` | Test each path independently; do not generalize bridge containment. |
| Direct DML on `corretores` | Current `src/App.jsx` contains three direct PostgREST patch call sites. | `SECURITY_REVIEW_REQUIRED` | Include all call sites in F1-02 grants/RLS/ownership review and negative tests. |

## 5. Used M1 path map

| Path | Current source observation | Security/readiness conclusion |
|---|---|---|
| `proximo_lead` via Aceleração bridge | Service rejects unusable/no-session token before invoking RPC. | Local containment applies only to this bridge; backend authorization and live state remain unproven. |
| `registrar_feedback` via Aceleração bridge | Guarded bridge passes lead ID and feedback. | Ownership, allowlist, history and isolation are unproven. |
| `proximo_lead` direct in `DiscadorTab` | Direct `createSB.rpc`; helper falls back to project key when token is absent. | Requires explicit no-session/backend-denial testing. |
| `registrar_feedback` direct in `DiscadorTab` | Same direct client path. | Requires no-session, forged-lead, invalid-feedback and cross-tenant tests. |
| `atualizar_feedback` | Sends lead ID, feedback and observation. | Requires body/grant/tenant and invalid-payload review. |
| `mover_funil` | Sends lead ID, stage ID and observation. | Requires lead/stage/company validation and transition/history proof. |
| `mover_funil_lote` | Sends selected lead IDs and destination stage. | Bulk mixed-tenant, forged-ID and invalid-stage behavior must be tested. |
| `registrar_mensagem` | Invoked from message/email flows. | Messaging-history authorization, ownership, channel/sequence validation and audit integrity are unproven. |
| `distribuir_lotes` | Invoked in M1 management flow. | Broker/list/company eligibility, allocation authority and cross-tenant denial require review. |
| `criar_lista` | Creates a list before lead batches. | Company derivation, creator permission, naming/audit and runtime result are unproven. |
| `gerenciar_visibilidade_lista` | Sends list visibility targets. | Target validation and unauthorized expansion require negative tests. |
| `importar_leads_batch` | Sends list ID, batch and session ID; consumes result totals. | Dedup rules, ownership, tenant derivation, idempotency, audit and error behavior are unproven. |
| `get_dashboard_stats` | Gestor dashboard reads backend statistics. | Does not prove weekend-visit semantics or tenant safety. |
| `minha_producao` | Corretor/dashboard flows read production data. | Field semantics, date filtering, zero/unknown behavior and isolation require validation. |
| Direct `PATCH corretores` | Three current call sites update broker records. | Must be included in RLS/grant/ownership and manipulated-ID testing. |
| Aceleração local weekend/session metrics | Local React state tracks visits and pressure indicators. | Not accepted as persisted weekend dashboard evidence. |

## 6. F1-01 checkpoint and credit decision

```text
F1-01 evidence map: MERGED
Corrected PR head: a7e64c6ed817c03c4dbce7e1b9642e20360b3010
Squash commit: 1caf90c60681771af6609b96ee840b190668fa0f
Independent reaudit: PASS WITH RESIDUAL RISK
Map documentation purpose: SATISFIED
F1-01 checkpoint acceptance: NOT GRANTED
Accepted WDP: 0
Portfolio EV impact: 0
Security Go: NOT GRANTED
```

The reaudit result closes the correction/completeness issue for this map. It does not satisfy the product or security evidence still listed as missing.

## 7. Blockers, risks and next safe actions

| ID | Classification | Risk / blocker | Affected scope | Next safe action |
|---|---|---|---|---|
| F1-01-R1 | BLOCKING for F1-02/Security Go | Current live Supabase grant/body/tenant evidence is absent. | F1-02 and dependent M1 credit. | Refresh live evidence under separate read-only authorization. |
| F1-01-R2 | RESOLVED FOR THIS MAP | Used-path inventory was corrected and independently reaudit-passed. | F1-01 map completeness. | Preserve anchors; revalidate only after relevant source changes. |
| F1-01-R3 | REQUIRED BEFORE F1-04 CREDIT | Persistent next action/follow-up is required by MVP1 but not confirmed. | CRM continuity. | Establish persistence/authority or record formal baseline change. |
| F1-01-R4 | REQUIRED BEFORE F1-06 CREDIT | Dashboard RPCs exist, but weekend/scheduled-visit semantics are unconfirmed. | Weekend dashboard. | Trace and validate persisted semantics, isolation and unknown-vs-zero behavior. |
| F1-01-R5 | ACCEPTABLE WITH RESIDUAL RISK | Guarded bridge and direct Discador paths have different containment properties. | Power Mode / Discador. | Keep both explicit and test independently. |
| F1-01-R6 | BLOCKING for Security Go | Direct `corretores` DML is current and must be included in security review. | Broker identity/eligibility. | Validate RLS/grants/ownership and negative tests; runtime patch requires separate scope. |

## 8. Explicit non-claims

This document does not claim:

```text
- MVP1 is ready.
- F1-01 is accepted or complete as a product checkpoint.
- any WDP was earned.
- F1-02 Security Go may pass.
- current live Supabase metadata, grants, RLS, policies or RPC bodies are safe.
- RPC-driven or token-bearing requests are authorized.
- all Discador calls are protected by the Aceleração bridge.
- Power Mode metrics or weekend dashboard data satisfy the persisted requirement.
- next action/follow-up persistence exists.
- list deduplication, import auditing, mobile/browser smoke or rollback rehearsal are complete.
```

## 9. Next safe action

Proceed to F1-02 only after a separate `ACTIVE_READ_ONLY` authorization defines:

- exact FECH.AI canonical commit;
- exact Supabase project and environment;
- allowed read-only grants, policies, RPC definitions and table metadata;
- prohibited mutations;
- evidence sanitization and provenance;
- negative-test design scope;
- acceptance and expiration criteria.

Until then, keep **0 WDP**, F1-01 unaccepted and Security Go ungranted.
