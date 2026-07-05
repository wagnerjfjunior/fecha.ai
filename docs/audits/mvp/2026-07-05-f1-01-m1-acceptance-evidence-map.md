# FECH.AI — F1-01 M1 Acceptance Evidence Map

**Status:** PRE_EXECUTION_EVIDENCE_INVENTORY / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**B0 activity:** F1-01 — Final M1 evidence and acceptance map  
**Prepared on:** 2026-07-05  
**Eligible measurement start:** 2026-07-06  
**Repository:** `wagnerjfjunior/fecha.ai`

---

## 1. Decision and boundary

This document is the candidate evidence map for **F1-01**. It maps every MVP1 acceptance item to a current path, evidence state, gap, owner role and next safe action.

It is deliberately fail-closed:

```text
- No MVP item is marked READY_FOR_MVP_VALIDATION in this document.
- No Security Go decision is made.
- No WDP is earned by creating, reviewing or merging this document alone.
- No runtime, frontend, Supabase, migration, RLS, grant, policy, RPC, Edge Function,
  Vercel, integration or production behavior is changed or authorized.
```

The source inventory is prepared before the first eligible B0 delivery day. It is an evidence candidate for F1-01 CP1; it is **not** an accepted checkpoint and records **0 WDP** until independent validation is recorded.

---

## 2. Operational bootstrap

| Bootstrap item | Record |
|---|---|
| Context understood | FECH.AI is Pilot Production, multi-tenant / multi-company, with real users and sensitive lead/client data. |
| Affected module / flow | MVP1 Família / M1 LeadOps, CRM, Discador, Power Mode and weekend operating visibility. |
| Environment | GitHub `main` is the source of truth. This evidence map is documentation-only. |
| Relevant decisions | B0 merged through PR #92; B0 operational register merged through PR #93; F1-01 precedes F1-02 Security Go. |
| Branch/head for this artifact | `docs/f1-01-m1-evidence-map-20260705`; this document must be reviewed against its final PR head. |
| Files/areas inspected | Current `src/App.jsx`, `src/components/AceleracaoOperacional.jsx`, `src/services/aceleracaoOperacionalService.js`; product, M1 and security evidence documents listed below. |
| What must not change | Runtime, frontend, Supabase, migrations, RLS, grants, policies, RPC bodies, Edge Functions, Vercel, GitHub Actions, MesaCliente, ADS/CAPI, Make/n8n, integrations, production. |
| Available evidence | Current source blobs for the inspected UI/service paths; historical M1 runbooks; historical security inventories; PR #82 metadata. |
| Missing evidence | Current live Supabase metadata/body/grant verification; current runtime smoke tests; negative tenant-isolation tests; confirmed import persistence/dedup path; persisted next-action path; persisted weekend-dashboard data path; import/error audit evidence. |
| Main risks | Treating code presence as product readiness; treating RPC use as authorization proof; counting PRs as delivery; treating local session metrics as persisted operational data; relying on stale live Supabase evidence. |
| Next safe action | Review the map, preserve current-source anchors, record accepted/rejected/blocked checkpoint evidence, then decide whether F1-01 CP1 may receive any WDP. |

---

## 3. Evidence source inventory

### 3.1 Current source evidence fetched from `main`

| Source | Current blob / merge anchor | What it establishes | What it does not establish |
|---|---|---|---|
| `src/services/aceleracaoOperacionalService.js` | blob `37761cd05d93de6a9f7f3587a1ab481cb604b6a0` | `proximo_lead` and `registrar_feedback` are explicitly treated as sensitive; unusable/no session token raises `SESSION_REQUIRED` before `fetch`; authenticated token format is locally checked. | Backend authorization, tenant isolation, grant state, RPC body safety, live behavior. |
| `src/components/AceleracaoOperacional.jsx` | blob `7981ec2d9b79b7cf4e144da963fe0dbe05edd7d9` | UI calls the service bridge to load the next lead and register feedback; call/WhatsApp/e-mail actions are opened client-side; session counters are state-local. | A successful authenticated runtime flow, persistence of session metrics, audit/history integrity, backend access control. |
| `src/App.jsx` | blob `dc718403fe89c48143d68ac6b3b684b61330b078` | Current source includes CSV/XLSX parsing helpers; LeadModal calls `atualizar_feedback` and `mover_funil`; Discador calls `proximo_lead`, `registrar_feedback`, `avaliar_lista` and `solicitar_lote`; responsive CSS exists. | Current live Supabase/RPC semantics, dedup/persistence result, tenant isolation, browser/device smoke results. |
| PR #82 | merge `0446cf4b5a6ae201adf44798a4aafc6e665429d9` | The fail-closed session guard was merged for the Aceleração Operacional service bridge. | That all required negative and authenticated runtime tests were executed in the current environment. |

### 3.2 Historical evidence — retained with freshness limits

| Source | Evidence value | Freshness / limitation |
|---|---|---|
| `docs/product/fechai-mvp-scope-v1.md` | Defines MVP acceptance criteria, including import, duplicates, quick actions, status, funnel, weekend dashboard, tenant/company/broker protection, logs, responsive flow and rollback. | Product contract, not implementation proof. |
| `docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-existing-evidence-map.md` | Consolidates source/RPC candidates and documents known gaps. | Documentation from 2026-06-10; not a current live-system assertion. |
| `docs/audits/mvp/2026-06-10-m1-leadops-crm-discador-reconciliation-pass-2-ui-rpc-map.md` | Defines the exact map contract and allowed evidence statuses. | Explicitly says it is a runbook, not the filled final map. |
| `docs/security/evidence/2026-06-09_rpc_grants_p1_inventory.md` | Identifies M1 RPC candidates and P1 direct-DML risk. | It states live grant status was pending reconciliation at that point; no current grant/body safety conclusion is allowed. |
| `docs/security/evidence/2026-06-09_supabase_live_reconciliation_p1_results.md` | Historical sanitized live metadata/body indicators. | Last known live evidence is dated 2026-06-09 and requires renewed validation before F1-02. |

### 3.3 Evidence labels used in this map

| Label | Meaning |
|---|---|
| `CURRENT_SOURCE_CONFIRMED` | Current `main` source was inspected and the narrow code fact is observable. |
| `HISTORICAL_DOCUMENTATION_ONLY` | A versioned record exists, but it does not prove the present runtime or live Supabase state. |
| `STALE_LIVE_EVIDENCE` | Historical live metadata exists but is too old to authorize a current gate. |
| `NOT_CONFIRMED` | No sufficient source/runtime/live evidence was found for the claim. |

---

## 4. MVP acceptance map

The acceptance items below derive from `docs/product/fechai-mvp-scope-v1.md`. Status values follow the Pass 2 map contract. No row is READY.

| MVP acceptance item | Current path / evidence | Evidence class | Current status | Gap or contradiction | Owner role | Next safe action |
|---|---|---|---|---|---|---|
| 1. Gestor/corretor imports simple list | `src/App.jsx` contains CSV/XLSX parsing helpers and lead normalization. Historical inventory identifies `criar_lista` and `importar_leads_batch` as intended RPC paths. | `CURRENT_SOURCE_CONFIRMED` for parsing; `HISTORICAL_DOCUMENTATION_ONLY` for persistence route. | `NEEDS_CODE_VALIDATION` | Current list-creation/import RPC invocation, authenticated result, company derivation and import audit record were not proven in this map. | GPT7 + GPT1 + GPT3 | Inspect the final current import call path and validate one controlled non-PII import with server-side tenant/company checks. |
| 2. System detects basic duplicates | Product requirement exists; no current dedup algorithm, RPC response contract or controlled result was confirmed. | `NOT_CONFIRMED` | `NOT_CONFIRMED` | Parser presence is not duplicate detection. | GPT7 + GPT1 | Identify the exact dedup decision point, input keys, outcome UI and persistence/audit behavior. |
| 3. Corretor opens call or WhatsApp in few clicks | `AceleracaoOperacional.jsx` opens `tel:` and `wa.me`; `App.jsx` LeadModal also exposes call/WhatsApp actions. | `CURRENT_SOURCE_CONFIRMED` | `NEEDS_CODE_VALIDATION` | Browser/device behavior and the precise operational path in authenticated pilot use are untested. Opening a channel is not proof of a registered CRM event. | GPT7 + GPT2 | Run mobile and desktop smoke on a controlled test lead; retain non-PII evidence and failure behavior. |
| 4. Corretor registers status | `AceleracaoOperacional.jsx` calls `registrar_feedback`; `App.jsx` calls `registrar_feedback` and `atualizar_feedback`. | `CURRENT_SOURCE_CONFIRMED` | `SECURITY_REVIEW_REQUIRED` | Current source proves request initiation, not backend authorization, allowed feedback validation, history integrity or cross-company rejection. | GPT3 + GPT7 + GPT1 | Revalidate RPC body/grant/live behavior and execute negative tests for forged lead ID, invalid feedback and cross-tenant access. |
| 5. Funil shows leads by stage | `App.jsx` LeadModal loads stages via `listar_funil_estagios` and calls `mover_funil`; historical sources identify the Kanban/funnel flow. | `CURRENT_SOURCE_CONFIRMED` + `HISTORICAL_DOCUMENTATION_ONLY` | `SECURITY_REVIEW_REQUIRED` | Current source does not prove stage ownership, transition rules, tenant enforcement, history persistence or browser smoke. | GPT7 + GPT3 + GPT1 | Trace current funnel read/write route and test invalid stage, forged lead ID and cross-company attempts. |
| 6. Dashboard shows scheduled weekend visits | Aceleração UI displays `visitas`, `faltam` and pressure metrics, but those values are initialized and updated in local React state. | `CURRENT_SOURCE_CONFIRMED` | `NOT_CONFIRMED` | Local session counters do not prove persisted operational data, scheduled visits, unknown-vs-zero handling or weekend dashboard acceptance. | GPT7 + GPT2 + GPT1 | Identify a persisted dashboard query/data source or classify a targeted product decision and technical gap. |
| 7. Data respects tenant/company/broker | Historical inventories identify RPC-driven paths and P1 direct-DML risk; current UI/service sends a token to RPC paths. | `STALE_LIVE_EVIDENCE` + `CURRENT_SOURCE_CONFIRMED` | `SECURITY_REVIEW_REQUIRED` | Frontend token use does not prove server-side tenant/company derivation, actor permission or denial of cross-tenant targets. | GPT3 + GPT1 | Refresh live Supabase evidence and run the required negative-test matrix before F1-02. |
| 8. Minimum import and error logs exist | Aceleração service logs client-side errors and surfaces controlled UI errors. | `CURRENT_SOURCE_CONFIRMED` | `NOT_CONFIRMED` | Client console/error display is not import auditing or server-side operational logging; no current import/error audit record was confirmed. | GPT5 + GPT7 + GPT3 | Identify import audit tables/logs and error observation path; define non-PII evidence standard. |
| 9. Flow works on mobile and desktop | `App.jsx` contains responsive CSS; M1 UI exists in source. | `CURRENT_SOURCE_CONFIRMED` | `NEEDS_CODE_VALIDATION` | No actual browser/device smoke, accessibility check or failure-state validation was available. | GPT2 + GPT4 + GPT7 | Validate the controlled flow on desktop and mobile preview, including session/error states. |
| 10. Rollback path exists | Historical documents and `App.jsx` commentary reference prior Vercel deployment/revert behavior; Git history supports documentation/code reverts. | `HISTORICAL_DOCUMENTATION_ONLY` | `GPT4_VALIDATION_REQUIRED` | No current deployment rollback rehearsal, release runbook confirmation or current deployment linkage was shown. | GPT4 + GPT5 | Confirm current Vercel/GitHub rollback procedure and record a safe non-production validation approach. |

### Supplemental MVP1 continuity items

| Item | Current evidence | Status | Required next action |
|---|---|---|---|
| Persistent next action / follow-up | The Aceleração UI phrase “Próxima ação” denotes the next client-side channel in its session flow. No exact persistent CRM field, RPC, table/history, responsible broker or cross-tenant negative test was confirmed. | `NOT_CONFIRMED` | Map the current persistence path or treat it as a required M2 implementation gap; do not call the local channel sequence CRM continuity. |
| Power Mode execution loop | Current Aceleração source loads a lead, opens client-side channels, calls feedback registration and may auto-run the first channel. | `SECURITY_REVIEW_REQUIRED` | Separate code-path confirmation from backend authorization, runtime smoke, persistent metrics and opt-out/LGPD behavior. |
| Direct DML on `corretores` | Historical P1 inventory identifies `src/App.jsx -> sb.patch("corretores", ...)`. It was not revalidated in the current source pass. | `SECURITY_REVIEW_REQUIRED` | Reconfirm the current exact call sites and classify M1 blocker vs separate P1 backlog before any related technical patch. |

---

## 5. Used M1 path map

| Path | Current source observation | Security/readiness conclusion |
|---|---|---|
| `proximo_lead` via Aceleração bridge | Current service gate checks for a usable authenticated token before invoking sensitive RPC. | Local fail-closed containment is confirmed; RPC authorization, tenant isolation and live grant/body state are not proven. |
| `registrar_feedback` via Aceleração bridge | Current service gate applies; component passes `p_lead_id` and selected feedback. | Source confirms request shape, not server-side ownership/allowlist/history guarantees. |
| `atualizar_feedback` via LeadModal | Current App source calls it with lead ID, feedback and observation. | Requires body/grant/tenant and invalid-payload review. |
| `mover_funil` via LeadModal | Current App source calls it with lead ID, stage ID and observation. | Requires target-lead/stage/company validation and history/transition proof. |
| List creation/import paths | Historical inventory identifies `criar_lista` and `importar_leads_batch`; parsing source is current. | Final current invocation and server-side behavior are unconfirmed. |
| Weekend metrics | Aceleração source maintains local session state. | Not accepted as persisted operational dashboard evidence. |

---

## 6. F1-01 checkpoint and credit decision

### Current checkpoint state

```text
F1-01 CP1 candidate: source list and evidence inventory
Evidence date: 2026-07-05
Eligible B0 measurement date: 2026-07-06
Status: EVIDENCE_READY only after this document is reviewed against its final branch head
Accepted WDP: 0
Portfolio EV impact: 0
```

### Why no WDP is recorded

This map exists to make gaps explicit. It has not yet received an independent validator decision, and it does not establish that any MVP acceptance item is complete or safe. Under B0, a PR, a document or a source-inspection claim alone does not earn delivery credit.

### Required validator decision for CP1

| Validator role | Must confirm |
|---|---|
| GPT0 — Documentation | Every MVP item has a path/evidence state/gap/owner/next action; no overclaim or missing source classification. |
| GPT1 — SaaS architecture | Frontend/request versus backend/RPC authority boundaries are not inverted; dependencies and no-change areas are preserved. |
| GPT3 — Supabase security | Security gaps are not converted into readiness; current live and negative-test evidence needed for F1-02 is explicit. |
| GPT7 — LeadOps/CRM/Discador | The operational acceptance map covers import, funnel, execution, feedback, next action and dashboard semantics. |
| GPT2 / GPT4 — conditional | Required for responsive UX or deployment/rollback claims; they do not grant Security Go. |

---

## 7. Blockers, risks and next safe actions

| ID | Classification | Risk / blocker | Affected scope | Next safe action |
|---|---|---|---|---|
| F1-01-R1 | BLOCKING for F1-02 | Current live Supabase grant/body/tenant evidence for used paths is absent. | F1-02 and all dependent M1 product credit. | Refresh live read-only evidence and complete negative-test design before Security Go. |
| F1-01-R2 | REQUIRED IN THIS PR | MVP acceptance map needed to distinguish actual code evidence from assumption. | F1-01. | Review this document against final branch head; preserve unresolved status. |
| F1-01-R3 | REQUIRED BEFORE F1-04 CREDIT | Persistent next action/follow-up path is not confirmed. | CRM continuity. | Inspect current path and establish backend authority, persistence and negative-test requirements. |
| F1-01-R4 | REQUIRED BEFORE F1-06 CREDIT | Weekend metrics currently observed in Aceleração are local state, not accepted persisted dashboard data. | Weekend dashboard. | Define/verify persisted query and unknown-vs-zero behavior. |
| F1-01-R5 | ACCEPTABLE WITH RESIDUAL RISK | Current service bridge contains local no-session containment, but authenticated smoke/runtime evidence is absent. | Power Mode. | Keep contained; run controlled non-production smoke before any operational claim. |
| F1-01-R6 | PLANNED FUTURE PR | Direct `corretores` DML hardening is separate P1 risk unless it blocks the selected M1 path. | Identity/broker eligibility. | Revalidate exact call sites; scope separately if required. |

---

## 8. Explicit non-claims

This document does not claim:

```text
- MVP1 is ready.
- F1-01 is accepted or complete.
- any WDP was earned.
- F1-02 Security Go may begin or pass.
- current live Supabase metadata or grants are safe.
- RPC-driven means authorized.
- Power Mode metrics or weekend dashboard data are persisted.
- next action/follow-up persistence exists.
- list deduplication, import auditing, mobile/browser smoke or rollback rehearsal are complete.
```

---

## 9. Next safe action

Validate this map as an F1-01 CP1 evidence candidate against its final PR head. Then record one of:

```text
ACCEPTED — only if every required map field and evidence classification is complete;
REJECTED — if a source anchor, MVP item, gap, owner role or next action is missing;
BLOCKED — if current-source or live evidence cannot be obtained safely.
```

Regardless of outcome, publish **0 WDP** until the validator decision and checkpoint evidence are recorded in the B0 operating ledger.