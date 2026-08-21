# FECH.AI — PR-03 Repository-Wide Direct-Write / Call-Site Inventory Closure

**Date:** 2026-08-21  
**Status:** `ARCHITECTURE_EVIDENCE / PREDICATE_3_STATIC_SOURCE_INVENTORY_ESTABLISHED / CONDITION_NOT_SATISFIED / DOCUMENTATION_ONLY`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Project:** `FECH.AI / fechai`  
**Evidence-producing role:** `architecture -> software-systems-architect`  
**Documentation reconciliation role:** `documentation_audit -> documentation-auditor`

## 1. Purpose

This record closes only the static/versioned repository-wide source-inventory evidence component of the F1-02 / PR-03 eligibility predicate.

It does not implement PR-03, remove any direct write, validate production RLS/grants, prove runtime behavior, grant Security Go, authorize Ready/merge/deploy, or select a target architecture.

The material question is split into two independent claims:

```text
A. Has the refreshed repository-wide direct-write/call-site inventory been established for a defined executable/versioned source universe?
B. Does that inventory confirm that no required direct update remains?
```

Result:

```text
A = ESTABLISHED
B = NOT SATISFIED
```

Two active administrative direct `PATCH` dependencies remain in `EditarCorretorModal`.

## 2. Canonical refs and preserved anchors

```text
FECH.AI base/main:
827f8591bfe4eee595a1aa22e169dcf6465f7fa3

FECH.AI root tree:
e641a2ab1222404aa3634c7513154ebb6e0539f8

SES main:
773fd94735b79df35e73e84de07fc2b67dd092e4

Protected App.jsx source:
path: src/App.jsx
blob: 2541813e6af44f4e8112296b7d9666df9320db5d
size: 327255 bytes
lines: 5902
coverage: preserved INTEGRAL_READ from the fresh 2026-08-21 range-based retrieval
```

The movement from FECH.AI main `51a15d5...` to `827f859...` was documentation-only through PR #123. The root/source subtree anchors used below show the executable source universe relevant to this claim remained unchanged.

## 3. Bounded source universe

The repository-wide inventory claim is intentionally scoped to versioned sources capable of originating or forwarding application mutations:

```text
src/
api/
public/
supabase/functions/
scripts/        -> test-only classification where applicable
root runtime/build configuration when material
```

Enumeration anchors:

```text
root tree:    e641a2ab1222404aa3634c7513154ebb6e0539f8 / truncated=false
src tree:     960b060d4950e737740eea1048d08412cbc8c462 / truncated=false
api tree:     81269ab5e79c1fcec7d421da74979f61208e0d8a / truncated=false
public tree:  cf3d9041c0bd07a970718ad8950d84f268a73ff9 / truncated=false
scripts tree: a2f9961a1d88a8dd9b493f71103dcecd4e0b3e65 / truncated=false
supabase/functions tree: 5cfe3c5f34d983f4567809d21f641c0733036d33 / truncated=false
```

Explicit exclusions from the *caller-source* universe:

```text
docs/       -> evidence/specification, not runtime caller source
Backlog/    -> planning/history, not runtime caller source
dist/       -> generated Vite build artifact, not source authority
supabase/migrations/ -> database implementation/authority source, not browser/application caller origin
```

Migrations remain material to backend authority questions, but they are not counted as frontend/application direct-write callers for this predicate.

## 4. Search and enumeration method

The inventory used repository enumeration plus adversarial code-search patterns for direct table-write mechanisms and wrappers, including:

```text
.patch(
sb.patch(
.update(
.insert(
.upsert(
.delete(
supabase.from(
/rest/v1/
Prefer: return=representation
HTTP POST/PATCH/DELETE call sites
createClient(...)
generic PostgREST helpers
RPC helpers
Edge Function callers
Vercel API proxies
Worker callers
```

Search results were treated only as candidate locators. Material candidates were then classified against their final source files and previously established exact source anchors.

The method distinguishes:

```text
RPC/Edge mutation
!= direct PostgREST table DML

cache DELETE
!= database DELETE

client construction
!= DML call site
```

## 5. Direct table-write inventory

The refreshed static source inventory confirms these active direct table writes:

### 5.1 Operational broker-state write

```text
src/App.jsx
EditarCorretorModal.salvar()
→ direct PATCH public.corretores
→ fields: ativo, apto_para_receber
```

The same flow also uses server-side RPC behavior for other profile-state work, so the administrative transition is split across authority mechanisms.

### 5.2 Administrative password-state write

```text
src/App.jsx
EditarCorretorModal.redefinirSenha()
→ criar-usuario Edge boundary / action=reset_password
→ direct PATCH public.corretores
→ field: must_change_password=false
```

This remains distinct from the self-service `public.marcar_senha_inicial_definida()` RPC, which is actor-derived through `auth.uid()` and is not an authorization contract for an administrator targeting another user.

## 6. Candidate classification outside App.jsx

The other material mutation-capable source paths inspected do not add a second confirmed direct PostgREST table-DML caller to this bounded inventory:

```text
TimesTab
→ atualizar_time_corretor RPC
→ atualizar_status_corretor RPC
→ criar_time RPC
→ criar-usuario Edge reset path

CriarUsuarioForm
→ get_meus_times RPC
→ criar-usuario Edge Function

RootPanel
→ listar_empresas_root RPC
→ atualizar_status_empresa_root RPC
→ simular_troca_plano_empresa_root RPC
→ alterar_plano_empresa_root RPC
→ GET-only planos query

TenantProvisioningRoot
→ criar_empresa_root RPC
→ /api/criar-usuario

Aceleracao Operacional service
→ proximo_lead RPC
→ registrar_feedback RPC

MesaCliente APIs
→ feature-specific RPC calls, including financial apply RPC

api/criar-usuario.js
→ transport proxy to Supabase Edge Function

api/mesa-worker-proxy.js
→ transport proxy to external Worker

public PME scripts
→ browser/DOM/external side effects and assistente-ai Edge calls; no confirmed direct table DML in the inspected paths

Supabase createClient files
→ client construction only; no DML call site in those files

public/sw.js
→ cache operations; HTTP/cache DELETE is not database DELETE

scripts/
→ test-only source set, not production caller origin

supabase/functions/gpt-especialista
→ narrow read-only metadata RPC gateway in the observed source
```

No additional direct table-write candidate was found in the bounded executable/versioned source universe by the enumerated mechanisms.

This is bounded negative evidence. It is not a claim about code outside the enumerated repository universe, unversioned runtime code, external Workers, missing Edge Function implementations, or dynamically changed production configuration.

## 7. Predicate #3 decision

The previous SFJM state correctly held the repository-wide inventory open because only the App.jsx component had been closed.

This evidence event changes the claim status to:

```text
repository-wide STATIC SOURCE direct-write/call-site inventory:
ESTABLISHED for the defined executable/versioned source universe

predicate terminal condition:
"confirming no required direct update remains"
NOT SATISFIED

reason:
2 active administrative direct PATCH dependencies remain

PR-03:
STILL NOT_YET_MATERIALLY_ELIGIBLE
```

The inventory evidence is therefore closed, while the product/security dependency exposed by the inventory remains open.

## 8. Limitations and non-claims

This record does not establish:

```text
production RLS/grants/policies PASS
runtime behavior PASS
cross-tenant isolation PASS
criar-usuario Edge authorization PASS
assistente-ai authorization PASS
external Worker security PASS
Security Go
PR-03 implementation eligibility
```

The authoritative versioned source for `criar-usuario` and `assistente-ai` Edge implementations is still absent from the observed repository source set. Their server-side authorization behavior therefore remains a separate evidence obligation.

An attempted independent local checkout/ripgrep pass of the same immutable commit failed because the execution environment could not resolve `github.com`; that failed transport attempt is not used as supporting evidence.

## 9. Coverage matrix

| Source / object | Anchor | Coverage for this claim | Limitation |
|---|---|---|---|
| root repository tree | `e641a2ab...` | `INTEGRAL_ENUMERATION` | paths/objects only, not all file bodies |
| `src/` tree | `960b060d...` | `INTEGRAL_ENUMERATION` | bodies read selectively by candidate |
| `api/` tree | `81269ab5...` | `INTEGRAL_ENUMERATION` | 2-file source set |
| `public/` tree | `cf3d9041...` | `INTEGRAL_ENUMERATION` | bodies read selectively by candidate |
| `scripts/` tree | `a2f9961a...` | `INTEGRAL_ENUMERATION` | classified test-only |
| `supabase/functions/` tree | `5cfe3c5f...` | `INTEGRAL_ENUMERATION` | only versioned function is gpt-especialista |
| `src/App.jsx` | blob `2541813e...` | `INTEGRAL_READ` preserved | unchanged source anchor |
| candidate source files | exact current blobs from A2/inventory closure | `INTEGRAL_READ` where material to classification | no runtime implication |
| code-search negative evidence | bounded repository searches | `BOUNDED_NEGATIVE_EVIDENCE` | GitHub search/index semantics; not universal absence proof |

## 10. Invalidation events

Revalidate the affected inventory claim after any material change to:

```text
src/ api/ public/ supabase/functions/ caller-source trees
App.jsx or EditarCorretorModal data-access behavior
shared PostgREST/Supabase transport helpers
new runtime source directory or entrypoint
new direct-DML mechanism
contradictory repository/runtime evidence
```

A documentation-only main movement that preserves these source anchors does not invalidate the inventory by itself.

## 11. Next safe action

The next material dependency is no longer another repository-wide direct-write search.

It is:

```text
B1 — Administrative Authority Contract Closure / READ_ONLY
ROLE=backend_data -> backend-data-platform-specialist
```

Objective:

```text
resolve a safe server-side disposition for the two remaining EditarCorretorModal administrative writes,
including actor/target/tenant authority, protected state, transaction/compensation, grants/RLS implications,
auditability, failure semantics and rollback proof obligations.
```

This evidence record authorizes no implementation or Supabase/runtime mutation.
