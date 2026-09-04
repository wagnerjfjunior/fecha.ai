# FECH.AI — STS-M2-01 Database Canonicality Matrix — Accepted Evidence Artifact

**Date:** 2026-09-04  
**Program:** Issue #141 — FECH.AI Security-to-Scale 2026  
**Task:** STS-M2-01  
**Environment:** Pilot Production / multi-tenant / multiempresa  
**Supabase project:** `uobxxgzshrmbtjfdolxd` / `Discador-MesaCliente`  
**Decision anchor FECH.AI main:** `252fb981bba4fb410136fd34cb29b9f2d0e057f8`  
**Acceptance reconciliation main before this artifact:** `b6fdf75adcb199213b461e07374d77e03b877301`

## 1. Purpose

This artifact makes the Product Authority-accepted STS-M2-01 result durable and auditable at row level.

It closes the two documentation evidence gaps identified after PR #174:

- row-level canonicality assignments were not versioned;
- Phase A / Phase B provenance was not durably anchored.

This artifact records accepted evidence and disposition. It does not authorize database implementation.

## 2. Authority and evidence classes

```text
Issue #141 canonical disposition vocabulary:
KEEP / CONSOLIDATE / RETIRE / REMODEL / INTERNAL

Product Authority acceptance:
GRANTED on 2026-09-04

STS-M2-01:
COMPLETE / ACCEPTED

IMPLEMENTATION AUTHORITY:
NONE
```

### 2.1 Upstream Backend/Data Phase A report

```text
source label:
Markdown(20260904-181123).md colado

SHA-256:
c08cff0ff22e4d172fd80a061131a49a8299645ec91819e8cdbd69613f82e7ab

evidence class:
UPSTREAM SPECIALIST LIVE_DATABASE_AUDIT / READ_ONLY

reported target:
wagnerjfjunior/fecha.ai@252fb981bba4fb410136fd34cb29b9f2d0e057f8
Supabase uobxxgzshrmbtjfdolxd / Discador-MesaCliente

reported live universe:
44 public tables

reported numerical drift:
43 planning label → 44 live
+1 = public.importar_leads_batch_idempotency
unresolved count drift = 0
```

The original operating-session attachment is not a GitHub object. Its SHA-256 is preserved here as provenance. The accepted row-level outcome is versioned in this artifact.

### 2.2 Architecture Phase B + final delta report

```text
source label:
Markdown(20260904-192216).md colado

SHA-256:
6f9b6ec784ebef206c399cea630ab9ea55f87137697c224e1682ef242cf6ba11

evidence class:
ARCHITECTURE_READ_ONLY
+ VERSIONED_GITHUB_EVIDENCE
+ UPSTREAM_LIVE_DATABASE_EVIDENCE

final architecture recommendation:
ARCHITECTURE_RECOMMENDS_M2_01_FINAL_ACCEPTANCE
```

The original operating-session attachment is not a GitHub object. Its SHA-256 is preserved here as provenance. Product Authority accepted the final delta.

## 3. Independent Master Project revalidation

Capture window: `2026-09-04T19:26-03:00` operating session.

Observed/revalidated:

```text
FECH.AI main at acceptance evidence review:
252fb981bba4fb410136fd34cb29b9f2d0e057f8

Issue #141:
OPEN

Supabase project:
uobxxgzshrmbtjfdolxd
Discador-MesaCliente
ACTIVE_HEALTHY
PostgreSQL 17.6

public table count:
44

required delta tables present:
public.logs
public.mesa_fluxo_pagamentos_canonico
public.templates_mensagens

applied migration ledger includes:
20260902225240 / f1_02_pr07_funnel_reads_crm_payloads
```

The live table-universe revalidation used the bounded Supabase project read channel. No DDL/DML/business RPC or mutation was executed.

A bounded live `pg_proc` definition scan also observed:

```text
public.logs referenced by current routines including:
- atualizar_feedback(...)
- criar_time(...)
- distribuir_lotes()
- importar_leads_batch(...)
- registrar_feedback(...)
- registrar_mensagem(...)

public.criar_mesa_simulacao(...)
→ references mesa_fluxo_pagamentos
→ references mesa_fluxo_pagamentos_canonico

public.mesa_cliente_montar_payload_agenda_canonica(...)
→ references mesa_fluxo_pagamentos
→ no observed reference to mesa_fluxo_pagamentos_canonico

public.mesa_cliente_obter_simulacao_fluxo_historico(...)
→ references mesa_fluxo_pagamentos
→ no observed reference to mesa_fluxo_pagamentos_canonico

public.pme_registrar_message_usage(...)
→ references pme_message_templates
```

Function-definition reference is structural database evidence, not proof of runtime invocation frequency.

## 4. Versioned GitHub evidence anchors

| Evidence | Exact ref/blob | Coverage used |
|---|---|---|
| Security-to-Scale WBS | `docs/roadmap/fechai-security-to-scale-2026-wbs.md` blob `c6fe2e339c4de33dfb8265912ba6b63380270c4e` | M2-01 contract / 43-table planning label |
| PR-07 migration | `supabase/migrations/20260902091600_f1_02_pr07_funnel_reads_crm_payloads.sql` blob `66bf5949dc73befeb64b88388887483501ccb268` | Creates `importar_leads_batch_idempotency` |
| MesaCliente 20D.5 migration | `supabase/migrations/20260528013000_mesa_cliente_20d5_fluxo_canonico_shadow.sql` blob `37ab7d00e66e50766c3f967a0999af3bed5a1bb8` | Dual-write/shadow transition evidence |
| SFJM acceptance commit | `b6fdf75adcb199213b461e07374d77e03b877301` | Product-state reconciliation merged by PR #174 |

## 5. Final accepted 44-table canonicality matrix

| # | Table | Owning context | Final disposition | Accepted rationale |
|---:|---|---|---|---|
| 1 | `public.admins` | Tenant / Identity | **KEEP** | Admin authority/membership state; security primitive. |
| 2 | `public.audit_logs` | Audit / Operations | **KEEP** | Operational/commercial audit remains distinct from forensic/root/deployment trails. |
| 3 | `public.audit_trail` | Audit / Governance | **KEEP** | Forensic critical-change trail; retain with tenant-topology residual. |
| 4 | `public.corretores` | Tenant / Identity | **KEEP** | Central operational identity/ownership node. |
| 5 | `public.deployment_control_log` | Internal Control | **INTERNAL** | Platform deployment/control history; non-product internal state. |
| 6 | `public.empreendimentos` | MesaCliente / Product | **KEEP** | Core property/project reference. |
| 7 | `public.empresas` | Tenant / Identity | **KEEP** | Canonical tenant/company root. |
| 8 | `public.empresas_configuracoes` | Tenant / Identity | **KEEP** | Tenant configuration state. |
| 9 | `public.estoque_arquivos` | MesaCliente / Inventory | **KEEP** | Inventory ingestion artifact lineage. |
| 10 | `public.estoque_snapshots` | MesaCliente / Inventory | **KEEP** | Temporal inventory snapshot state. |
| 11 | `public.funil_estagios` | CRM / Funil | **KEEP** | Funnel stage definition. |
| 12 | `public.funil_movimentacoes` | CRM / Funil | **KEEP** | Funnel transition/history authority. |
| 13 | `public.importar_leads_batch_idempotency` | Internal LeadOps Control | **INTERNAL** | Importer idempotency state; introduced after 43-table planning label. |
| 14 | `public.leads` | LeadOps | **KEEP** | Canonical lead aggregate across launch-scope flows. |
| 15 | `public.lista_avaliacoes` | LeadOps | **KEEP** | List evaluation operational state. |
| 16 | `public.lista_visibilidade` | LeadOps | **KEEP** | List ACL/visibility state. |
| 17 | `public.listas` | LeadOps | **KEEP** | Canonical list/distribution aggregate. |
| 18 | `public.logs` | Audit / Operations | **KEEP** | Multiple current DB routine references; retention/taxonomy remains residual. |
| 19 | `public.lotes` | LeadOps | **KEEP** | Assignment/batch lifecycle state. |
| 20 | `public.mesa_arquivos` | MesaCliente | **KEEP** | Mesa artifact/file state. |
| 21 | `public.mesa_cliente_agendas_financeiras` | MesaCliente / Finance | **KEEP** | Financial schedule/header state. |
| 22 | `public.mesa_cliente_desconto_politicas` | MesaCliente / Finance | **KEEP** | Discount policy state. |
| 23 | `public.mesa_cliente_fluxo_operacoes` | MesaCliente / Finance | **KEEP** | Financial operation state. |
| 24 | `public.mesa_cliente_fluxo_parcelas` | MesaCliente / Finance | **KEEP** | Installment flow state. |
| 25 | `public.mesa_cliente_politica_premio_faixas` | MesaCliente / Finance | **KEEP** | Prize-band policy state. |
| 26 | `public.mesa_cliente_politicas_financeiras` | MesaCliente / Finance | **KEEP** | Financial policy aggregate. |
| 27 | `public.mesa_cliente_unidade_enriquecimentos` | MesaCliente / Inventory | **KEEP** | Unit enrichment state; tenant-topology residual remains. |
| 28 | `public.mesa_eventos` | MesaCliente | **KEEP** | Simulation/event history. |
| 29 | `public.mesa_fluxo_pagamentos` | MesaCliente / Finance | **KEEP** | Current compatibility/read path remains material. |
| 30 | `public.mesa_fluxo_pagamentos_canonico` | MesaCliente / Finance | **KEEP** | Dual-written canonical shadow; promotion/read cutover not yet proven. |
| 31 | `public.mesa_simulacoes` | MesaCliente | **KEEP** | Central simulation/proposal aggregate. |
| 32 | `public.planos` | Monetization | **KEEP** | Global plan/catalog concept. |
| 33 | `public.pme_cadence_steps` | PME | **KEEP** | Cadence step configuration. |
| 34 | `public.pme_cadences` | PME | **KEEP** | Cadence aggregate. |
| 35 | `public.pme_call_scripts` | PME | **KEEP** | Call-script configuration. |
| 36 | `public.pme_lead_message_state` | PME | **KEEP** | Current per-lead messaging state. |
| 37 | `public.pme_message_templates` | PME | **KEEP** | PME-native template authority. |
| 38 | `public.pme_message_usage` | PME | **KEEP** | Append-only PME usage/history. |
| 39 | `public.root_audit_logs` | Audit / Privileged | **KEEP** | Privileged/root audit trail. |
| 40 | `public.t3_admin_password_reset_edge_proofs` | Internal Security | **INTERNAL** | Ephemeral reset-edge proof state. |
| 41 | `public.t3_admin_password_reset_leases` | Internal Security | **INTERNAL** | Password-reset authority/concurrency lease state. |
| 42 | `public.templates_mensagens` | Legacy Messaging | **KEEP** | Legacy/generic template contract not proven retired. |
| 43 | `public.times` | Tenant / Identity | **KEEP** | Team/ownership hierarchy. |
| 44 | `public.unidades_estoque` | MesaCliente / Inventory | **KEEP** | Core unit inventory authority. |

## 6. Final distribution

```text
KEEP = 40
INTERNAL = 4
CONSOLIDATE = 0
RETIRE = 0
REMODEL = 0
TOTAL = 44
NOT_DETERMINED = 0
```

The four `INTERNAL` tables are:

```text
public.deployment_control_log
public.importar_leads_batch_idempotency
public.t3_admin_password_reset_edge_proofs
public.t3_admin_password_reset_leases
```

## 7. Residual evidence obligations attached to KEEP

### public.logs

```text
producer/consumer taxonomy
retention requirements
observability consumers
data sensitivity
relationship to audit_logs / other audit facilities
```

### public.mesa_fluxo_pagamentos_canonico

```text
canonical read cutover
historical/backfill equivalence
reconciliation
consumer compatibility
authoritative read/write contract
rollback before transition changes
```

### public.templates_mensagens

```text
complete readers/writers
row/data relevance
non-PME consumers
tenant/global semantics
migration coverage
compatibility/equivalence/rollback
```

## 8. Interpretation boundaries

```text
KEEP_NOW != PERMANENT_ARCHITECTURAL_END_STATE
INTERNAL != UNUSED
ZERO_ROWS != RETIRE
LOW_USAGE != RETIRE
NAME_OVERLAP != CONSOLIDATE

M2-01_ACCEPTED != DATABASE_IMPLEMENTATION_AUTHORIZED
M2-01_ACCEPTED != M2_COMPLETE
M2-01_ACCEPTED != SECURITY_GO
```

Later M2 evidence may change a target disposition through a separately evidenced and authorized gate.

## 9. Next gate

```text
STS-M2-02
READ_ONLY routine / policy / trigger / grant map
owner / caller / tenant authority / write authority
```

No M2-02 implementation is authorized by this artifact.
