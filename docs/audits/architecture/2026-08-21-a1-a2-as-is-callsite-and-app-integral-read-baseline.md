# FECH.AI — A1/A2 AS-IS Architecture, Call-Site and App.jsx Integral-Read Baseline

**Date:** 2026-08-21  
**Status:** `ARCHITECTURE_EVIDENCE_BASELINE / DOCUMENTATION_ONLY / READ_ONLY_SOURCE_ANALYSIS`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Project:** `FECH.AI / fechai`  
**Specialist routing:** `ROLE=architecture -> software-systems-architect` for the architecture analysis; documentation closure performed under `ROLE=documentation_audit -> documentation-auditor`  

## 1. Purpose

This record preserves the evidence, method, corrections, bounded findings and remaining gaps from the FECH.AI A1/A2 architecture reconstruction performed before any target-architecture decision.

The work had two sequential objectives:

```text
A1 — Deep Architecture AS-IS Reconstruction
→ reconstruct current capabilities, entrypoints, dependencies, data access,
  trust boundaries and candidate domain ownership without selecting a target topology.

A2 — Authoritative Call-Site & Runtime-Boundary Closure
→ close caller/contract/authority/data paths, current direct writes,
  large-file coverage, legacy/duplicate classification and dependency-cut candidates.
```

This record is evidence and continuity. It does **not** select or approve a future architecture.

## 2. Canonical refs and immutable source anchor

The analysis was anchored to:

```text
FECH.AI repository:
wagnerjfjunior/fecha.ai

FECH.AI main/base:
51a15d5abdfb8ce62d5903272eb2855917a8d456

main commit message:
Merge PR #122: route FECH.AI roles through SES Gateway

SES repository:
wagnerjfjunior/Specialist-Engineering-System

SES main:
773fd94735b79df35e73e84de07fc2b67dd092e4
```

The critical large frontend object was:

```text
path: src/App.jsx
Git blob: 2541813e6af44f4e8112296b7d9666df9320db5d
size: 327255 bytes
line count: 5902
```

The SFJM already used the same App.jsx blob as the protected frontend anchor for F1-02 / PR-02 continuity.

## 3. Bootstrap and authority model

The analysis followed the live FECH.AI bootstrap and SES role routing.

For architecture work:

```text
PROJECT=fechai
ROLE=architecture
→ SES Project Adapter
→ software-systems-architect
→ ACTIVE
→ CERTIFIED_FOR_ANY_PROJECT=YES
→ FECH.AI local architecture rules
→ FECH.AI Modus Operandi
→ SFJM continuity when material
```

For this durable documentation closure:

```text
ROLE=documentation_audit
→ documentation-auditor
→ ACTIVE
→ CERTIFIED_FOR_ANY_PROJECT=YES
```

Preserved authority boundaries:

```text
ARCHITECTURE ANALYSIS != APPLICATION SECURITY PASS
DOCUMENTATION AUDIT != RUNTIME PASS
VERSIONED SOURCE != APPLIED PRODUCTION STATE
TOOL CAPABILITY != MUTATION AUTHORITY
ROUTABLE != EXECUTED
```

## 4. A1 result

A1 reconstructed the FECH.AI as more than a single React component tree.

The observed system includes, at minimum:

```text
React/Vite frontend
+ large App.jsx application/composition hotspot
+ parallel hash entrypoints in src/main.jsx
+ Supabase Auth/PostgREST/RPC
+ Vercel API functions
+ Supabase Edge Function boundaries
+ globally loaded PME scripts
+ DOM and localStorage coupling
+ MesaCliente parser/Worker paths
+ database-side domain/state transitions
```

A1 intentionally did not accept any target topology in advance. In particular, the following remained hypotheses only:

```text
modular monolith
microservices
BFF
strangler
selective extraction
event-driven topology
```

The initial A1 baseline was useful but bounded because `src/App.jsx` had not yet been freshly recovered start-to-EOF in that execution.

## 5. A2 scope

A2 was defined to close the material evidence gaps before target synthesis:

1. recover `src/App.jsx` from first line through EOF;
2. inventory REST/DML/RPC/Edge/API/Worker call sites;
3. map `caller -> contract -> authoritative implementation -> tables/state`;
4. resolve `criar-usuario`, `assistente-ai` and Mesa Worker boundaries when accessible;
5. identify ownership and cross-domain transaction boundaries;
6. classify ACTIVE / DUPLICATE / LEGACY / DEAD only with evidence;
7. refresh the direct-write inventory required by SFJM PR-03 eligibility;
8. identify candidate dependency cuts without selecting target architecture.

A2 materially closed the large-file/App.jsx portion of this scope and several explicit runtime/data boundaries. It did **not** establish an exhaustive repository-wide direct-write inventory; that broader predicate remains open until its source universe, enumeration method, coverage and limitations are explicitly recorded.

## 6. Large-file retrieval correction and historical integrity

### 6.1 Initial failure

A direct full-file GitHub retrieval of `src/App.jsx` exceeded the transport limit and produced a `ResponseTooLargeError`.

The initial A2 execution treated this too early as a persistent evidence limitation and retained `PARTIAL_READ`.

That was procedurally incorrect because the SES/FECH.AI evidence contract requires a large/truncated source to be recovered through pagination/ranges or another supported read method before accepting incomplete coverage.

Historical classification:

```text
INITIAL LARGE-FILE HANDLING:
USER_CORRECTED / PROCEDURAL OVERCLAIM

Incorrect promotion:
ResponseTooLargeError
→ no usable range mechanism
→ App.jsx remains PARTIAL_READ

Correct rule:
ResponseTooLargeError
→ trigger retrieval resilience
→ recover bounded continuous ranges
→ validate stable ref/blob
→ continue through EOF
```

The initial limitation is preserved here rather than retroactively erased.

### 6.2 Corrected fresh retrieval

After GitHub access was restored, the file was freshly read from the live immutable ref using bounded `start_line/end_line` retrieval.

The retrieval used contiguous line ranges, with 100-line windows after transport testing showed that larger ranges could approach the response budget.

Control conditions:

```text
repository: wagnerjfjunior/fecha.ai
ref: 51a15d5abdfb8ce62d5903272eb2855917a8d456
path: src/App.jsx
expected blob: 2541813e6af44f4e8112296b7d9666df9320db5d
```

For every accepted range:

```text
- returned SHA remained 2541813e6af44f4e8112296b7d9666df9320db5d;
- ranges were continuous;
- no unread gap was accepted;
- no truncated range was promoted to complete coverage.
```

The final request for lines `5901–6000` returned only the two existing lines `5901–5902`, ending with the final closing brace.

A subsequent probe beginning at line `5903` returned empty content on the same blob.

Therefore:

```text
src/App.jsx
coverage: INTEGRAL_READ
fresh retrieval: YES
coverage: 1–5902
EOF: CONFIRMED
post-EOF probe: EMPTY
ref drift during read: NONE
blob drift during read: NONE
```

This is a new direct GitHub range-based integral read. It is not merely reuse of historical conversation evidence.

## 7. What the integral App.jsx read establishes

The full file proves that `src/App.jsx` is an application/composition and data-access hotspot containing multiple responsibilities in one source object.

Material responsibilities include:

```text
authentication transport and login
session persistence and token refresh
profile loading
frontend role/admin projections
application composition
LeadOps / lote / feedback flows
Discador / Power Dial
messaging / WhatsApp / email
Power Zap / Power Email
CRM / funil
historical reporting
manager and broker dashboards
CSV/XLSX lead import
list management and visibility
team/user administration
administrative password reset
MesaCliente composition entry
AI assistant Edge Function caller
PostgREST query/patch/insert/rpc transport helpers
```

This establishes a concentration fact about the current source. It does not by itself prove the backend is insecure or dictate how the future system must be decomposed.

## 8. Runtime and entrypoint observations

`src/main.jsx` exposes multiple composition paths before the default App path:

```text
#tenant-provisioning
→ TenantProvisioningStandalone

#aceleracao-operacional
→ AceleracaoOperacional

#pme-admin
→ PowerMessageEngineAdmin

default
→ App.jsx
```

PME scripts are also loaded globally before normal React composition, which means the effective runtime dependency graph is broader than the React import graph.

Observed implicit coupling includes:

```text
DOM shape
localStorage shape
Supabase session/token shape
globally injected browser scripts
external tel:/mailto:/WhatsApp side effects
```

## 9. Current App.jsx data-access bridge

`App.jsx` contains its own Supabase transport bridge, with helpers conceptually covering:

```text
signIn
refreshToken
changePassword
query
patch
insert
rpc
```

Therefore the file is not only UI composition. It also participates directly in transport/data-access orchestration.

The existence of a generic helper does not prove a corresponding active call site. In particular, an `insert` capability exists, but no active `sb.insert(...)` invocation was established in the integral App.jsx call-site inventory.

## 10. Refreshed App.jsx direct-write inventory

The fresh integral read established two current direct `PATCH` call sites on `public.corretores`, both inside `EditarCorretorModal`.

### 10.1 Operational broker-state write

Flow:

```text
EditarCorretorModal.salvar()
→ RPC atualizar_perfil_corretor(...)
→ direct PATCH public.corretores
   fields:
   - ativo
   - apto_para_receber
```

The administrative transition is therefore split between an RPC and a direct table write.

### 10.2 Administrative password-state write

Flow:

```text
EditarCorretorModal.redefinirSenha()
→ POST Supabase Edge Function criar-usuario
   action=reset_password
   user_id=<target>
   password=<new password>
→ direct PATCH public.corretores
   must_change_password=false
```

This residual is distinct from the self-service mandatory-password cutover, which already uses the narrow server-side `public.marcar_senha_inicial_definida()` RPC.

The administrative flow spans Supabase Auth/Edge plus Postgres profile state and is not proven to be one atomic transaction.

## 11. SFJM PR-03 consequence and independent-audit correction

Before this evidence event, SFJM listed the refreshed repository-wide direct-write/call-site inventory as `NOT CURRENTLY ESTABLISHED`.

The fresh A2 retrieval establishes a strong bounded component of that predicate:

```text
APP.JSX DIRECT-WRITE/CALL-SITE INVENTORY:
ESTABLISHED

REPOSITORY-WIDE DIRECT-WRITE/CALL-SITE INVENTORY:
NOT YET ESTABLISHED
```

The App.jsx result itself is materially negative for future PR-03 eligibility because two current administrative direct writes are confirmed. However, it must not be promoted to an exhaustive repository-wide claim without a defined universe, enumeration/search method, coverage and limitations.

An independent audit of PR #123 detected an earlier documentation overclaim that promoted the bounded App.jsx result to `repository-wide ESTABLISHED`. The PR was corrected in place; the overclaim is preserved as historical correction rather than retroactively erased.

Therefore:

```text
PR-03 state:
STILL NOT_YET_MATERIALLY_ELIGIBLE

Administrative password-state residual:
STILL ACTIVE_RESIDUAL_RISK

App.jsx bounded inventory:
ESTABLISHED

Repository-wide predicate #3:
OPEN / NOT YET ESTABLISHED

Safe server-side disposition for EditarCorretorModal:
STILL NOT ESTABLISHED
```

The evidence improved materially; the product/security decision did not become PASS.

## 12. Authoritative boundary observations

### 12.1 MesaCliente financial operations

The versioned Mesa financial command path is structurally stronger than generic browser DML:

```text
UI/hook/API
→ mesa_cliente_aplicar_operacao_financeira_admin RPC
→ auth.uid() actor derivation
→ server-side profile/company checks
→ row locking
→ financial/state validation
→ multi-table DML
→ audit metadata
```

This is a versioned server/data authority boundary. It is not, by itself, proof that the exact migration is currently applied in production.

### 12.2 Mandatory-password self-service

The narrow self-service RPC:

```text
public.marcar_senha_inicial_definida()
```

accepts no caller-selected target ID, derives the actor from `auth.uid()`, and provides the current self-service password-state boundary recorded by SFJM.

### 12.3 criar-usuario

Observed callers include normal administrative creation, first-admin provisioning and administrative reset-password behavior.

The Vercel `/api/criar-usuario` path is a transport/proxy boundary; it does not itself prove target-user authorization.

The authoritative Supabase Edge Function source was not present in the observed canonical repository tree, so its internal actor/target/tenant authorization remains missing evidence in this static baseline.

### 12.4 assistente-ai

The browser calls `/functions/v1/assistente-ai` with the current bearer/session and conversation payload.

The authoritative Edge Function source was not present in the observed canonical repository tree, so the server-side contract remains missing evidence in this baseline.

### 12.5 Mesa Worker

The current Mesa parser flow contains a direct Worker path, while a separate Vercel Worker proxy also exists with a different default Worker URL.

The external Worker implementation/runtime is outside this repository evidence set.

## 13. Cross-domain transaction boundaries

Material multi-boundary workflows include:

```text
Tenant creation
→ create tenant/company authority
→ create first admin through separate user-provisioning boundary

Mandatory password completion
→ Supabase Auth password change
→ Postgres password-state command

Administrative password reset
→ Edge/Auth reset
→ direct Postgres profile-state PATCH

Mesa parse/import
→ local parser
→ optional external Worker
→ canonical payload/import RPC
```

The future architecture must preserve these state-transition semantics explicitly; changing file layout alone is insufficient.

## 14. Legacy and duplicate classification discipline

Only evidence-backed classifications were accepted.

Current high-level status:

```text
App.jsx: ACTIVE
pages/MesaCliente.jsx: ACTIVE current top-level Mesa route
legacyParser: REACHABLE fallback / NOT DEAD
MesaClienteNativeFirst.jsx: alternate/legacy candidate; not current top-level route
MesaClienteOld.jsx: legacy candidate; no deletion authorization inferred
PME global scripts: ACTIVE / statically loaded
multiple Supabase client constructions: physical duplication confirmed
/api/mesa-worker-proxy: route exists; current caller not established in the bounded evidence set
direct Mesa Worker path: established in parser source
```

Names such as `Old`, `Legacy` or `NativeFirst` were not treated as proof of liveness or death.

## 15. Candidate dependency cuts

These are investigation seams only, not approved target architecture:

```text
C1 — session/auth transport boundary
C2 — people/broker administration authority boundary
C3 — LeadOps command/query boundary
C4 — Mesa current composition/API/RPC boundary
C5 — Mesa parser/Worker/import boundary
C6 — root/tenant lifecycle boundary
C7 — PME DOM/storage/AI/contact adapters
C8 — direct-DML quarantine boundary
```

No target topology was selected.

## 16. Coverage matrix

| Source / object | Exact anchor | Coverage | Notes |
|---|---|---|---|
| `src/App.jsx` | blob `2541813e6af44f4e8112296b7d9666df9320db5d` | `INTEGRAL_READ` | fresh GitHub ranges `1–5902`; `5903+` empty |
| FECH.AI bootstrap index | main `51a15d5...` | `INTEGRAL_READ` for task | current routing/bootstrap contract |
| FECH.AI SES routing | main `51a15d5...` | `INTEGRAL_READ` for task | adopted role map |
| FECH.AI Modus Operandi | blob `e2deb1...` | `INTEGRAL_READ` | coverage and PR discipline |
| SFJM `CURRENT_STATE.md` | main baseline blob `6fce3a...` plus PR #123 corrected final state | `INTEGRAL_READ` in applicable audit gates | PR-03 state/predicates |
| SFJM `EVIDENCE_FRESHNESS.md` | main baseline blob `ef8620...` plus PR #123 corrected final state | `INTEGRAL_READ` in applicable audit gates | evidence-gap ledger |
| SES Project Adapter | SES main `773fd947...` | `INTEGRAL_READ` | FECH.AI adopted roles |
| SES architecture/documentation archetype contracts | SES main `773fd947...` | task-relevant canonical reads | reusable method only |
| repository-wide direct-write/call-site universe | repository source set | `PARTIAL / NOT YET ESTABLISHED` | requires explicit enumeration/search coverage before predicate #3 can close |
| Edge `criar-usuario` implementation | canonical repo tree | `NOT_READ / NOT_AVAILABLE_IN_TREE` | authority contract not established |
| Edge `assistente-ai` implementation | canonical repo tree | `NOT_READ / NOT_AVAILABLE_IN_TREE` | authority contract not established |
| external Mesa Worker runtime/source | external boundary | `NOT_READ / NOT_AVAILABLE` | outside current source universe |
| live Supabase catalog/RLS/grants | production | `NOT_READ / NOT_AVAILABLE_IN_THIS STATIC AUDIT` | no runtime/security PASS |

## 17. Findings classification

### BLOCKING for target architecture synthesis without further authority closure

- Authoritative server/data contracts for `criar-usuario` and other missing boundaries are not fully established in this static evidence set.
- Live Supabase catalog/RLS/grants and runtime behavior are separate evidence classes.

### ACCEPTABLE WITH RESIDUAL RISK for the static AS-IS baseline

- `App.jsx` is now fully read and can be used as a high-confidence static source anchor.
- Candidate cuts remain hypotheses until cross-boundary contracts are closed.

### PLANNED FUTURE WORK

- Complete the refreshed repository-wide direct-write/call-site inventory with an explicit source universe, enumeration/search method, coverage and limitations.
- Backend/Data authority-contract closure for the administrative `EditarCorretorModal` paths after the inventory predicate is closed.
- Independent AppSec validation of sensitive boundaries when the architecture/data evidence is sufficient.
- Architecture alternatives/target synthesis only after the remaining authority dependencies required by that decision are closed.

## 18. Explicit non-claims

This record does **not** establish:

```text
Security Go
production security PASS
runtime PASS
full tenant-isolation PASS
current applied RLS/grants/policy parity
Edge Function security PASS
Worker security PASS
repository-wide direct-write inventory completeness
PR-03 eligibility
approved target architecture
approved refactor
Ready
merge
deploy
```

## 19. Invalidation events

Revalidate only the affected claims after a material event such as:

```text
src/App.jsx blob change
a material caller/service/feature source change
relevant RPC/Edge/Worker contract change
relevant RLS/grant/policy change
new runtime evidence contradicting the static baseline
material SFJM/product/security decision change
```

An unrelated documentation-only merge or `main` SHA movement alone does not invalidate the immutable App.jsx evidence anchor.

## 20. Next safe action

The static architecture baseline is substantially stronger because the large source hotspot has a fresh integral read and a bounded current App.jsx direct-write inventory.

The next material evidence closure for PR-03 predicate #3 is:

```text
Complete the refreshed repository-wide direct-write/call-site inventory,
while preserving the two already-confirmed EditarCorretorModal writes
and without re-reading unchanged App.jsx.
```

That inventory must define its repository/source universe, search/enumeration method, coverage, checked write mechanisms and limitations. Only after that bounded repository-wide proof is closed should the workflow advance to the safe server-side disposition/authority contract for the remaining administrative writes.

For future target-architecture work, do not reopen already-closed A1/App.jsx evidence merely to recreate the same proof unless a relevant invalidation event occurs.

`NO MATERIAL EVENT -> NO AUTOMATIC RE-AUDIT`
