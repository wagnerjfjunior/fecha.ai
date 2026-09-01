# FECH.AI — F1-02 / B2 / PR-04 — Exact-Ref Call-Site & RPC Contract Map

**Status:** `EVIDENCE_ONLY / READ_ONLY_RECONSTRUCTION / NO_IMPLEMENTATION_AUTHORITY`  
**Date:** `2026-09-01`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Exact implementation-design base:** `41d8aadff51ad30b700cf3b88879550cfc7a118e`  
**Supabase project:** `uobxxgzshrmbtjfdolxd / Discador-MesaCliente`  
**Environment:** `Pilot Production`  
**Security Go:** `DENIED`

## 1. Purpose and authority boundary

This artifact closes the evidence gap required by the canonical F1-02 PR-04
contract before implementation can be requested.

It records:

- the exact-ref operation/call-site map for `public.leads`,
  `public.lotes` and `public.times`;
- the direct table-grant target currently justified by live evidence;
- the RPC compatibility-preservation set proven by current application
  call-sites;
- non-required/unproven live writers;
- the `gerenciar_lista` UI/database incompatibility;
- the current `times` disposition;
- RPC contract cards reconstructed from the live catalog;
- proposed positive/negative proof IDs for a later authorized implementation.

This document does **not** authorize or contain implementation SQL.

```text
NO migration
NO REVOKE / GRANT
NO RLS or policy mutation
NO RPC/function mutation
NO frontend/runtime mutation
NO Supabase mutation
NO Auth/data mutation
NO deploy
NO Ready
NO merge
NO runtime-negative production test
NO Security Go
```

## 2. Evidence classification

### 2.1 Exact-ref repository tree coverage

The following repository subtrees were enumerated recursively at exact ref
`41d8aadff51ad30b700cf3b88879550cfc7a118e`; each tree response reported `truncated=false`.

| Surface | Enumerated state | Material runtime/source files inspected |
|---|---:|---:|
| `.github` | complete | 11 workflows |
| `api` | complete | 2/2 |
| `scripts` | complete | 8/8 |
| `src` | complete | all source files identified by table/wrapper/RPC scans |
| `supabase/functions` | complete within `supabase` tree | 2/2 |
| `dist` | complete | compiled JS bundle + service worker |
| `public` | complete | all text JS/service-worker assets |

Migrations, rollback artifacts and SQL tests are versioned historical/verification
sources, not active application call-sites. Current database function bodies,
ACLs, grants, policies and table state were resolved independently from the live
Supabase catalog.

### 2.2 Integral-read material files

At minimum, the following material files were retrieved in full from the exact
ref and classified `INTEGRAL_READ`:

```text
src/App.jsx
src/components/TimesTab.jsx
src/components/CriarUsuario.jsx
src/components/CriarUsuarioForm.jsx
src/components/TenantProvisioningStandalone.jsx
src/components/TenantProvisioningRoot.jsx
src/components/PowerMessageEngineAdmin.jsx
src/components/RootPanel.jsx
src/components/HomeActions.jsx
src/components/AceleracaoOperacional.jsx
src/components/pme/PMECallScriptsPanel.jsx
src/services/aceleracaoOperacionalService.js
src/pages/MesaClienteOld.jsx
src/lib/supabaseClient.js
src/components/MesaCliente/supabaseClient.js
src/components/INTEGRAR_NO_GITHUB.md
src/components/MesaCliente/INTEGRACAO.md
api/criar-usuario.js
api/mesa-worker-proxy.js
supabase/functions/criar-usuario/index.ts
supabase/functions/gpt-especialista/index.ts
11 GitHub workflow files under .github/workflows/
8 repository scripts under scripts/tests/mesa-cliente/
dist/assets/index-BzY82WCC.js
dist/sw.js
public/sw.js
public/pme-call-assistant-ai-context-patch.js
public/pme-call-assistant-beta.js
public/pme-empreendimentos-inline-flow.js
```

Repository searches were used as a locator only. Conclusions below are based on
the exact-ref files plus live catalog evidence, not search snippets alone.

## 3. Current live direct-write surface

### 3.1 `public.leads`

```text
RLS = true
FORCE RLS = true

authenticated SELECT = true
authenticated INSERT = true
authenticated UPDATE = true
authenticated DELETE = false

effective authenticated column INSERT = true
effective authenticated column UPDATE = true

anon INSERT/UPDATE/DELETE = false
explicit column ACL entries = 0
```

Current policies include:

```text
leads_insert
leads_select
leads_update
```

The table also retains the APPSEC-M1-003 tenant-aware composite constraints.

### 3.2 `public.lotes`

```text
RLS = true
FORCE RLS = true

authenticated SELECT = true
authenticated INSERT = false
authenticated UPDATE = true
authenticated DELETE = false

effective authenticated column INSERT = false
effective authenticated column UPDATE = true

anon INSERT/UPDATE/DELETE = false
explicit column ACL entries = 0
```

Current policies include:

```text
lotes_select
lotes_update
```

### 3.3 `public.times`

```text
RLS = true
FORCE RLS = true

authenticated SELECT = true
authenticated INSERT = false
authenticated UPDATE = false
authenticated DELETE = false

effective authenticated column INSERT = false
effective authenticated column UPDATE = false

anon INSERT/UPDATE/DELETE = false
explicit column ACL entries = 0
```

Current policies:

```text
times_insert
times_select
times_update
```

Current non-internal governance triggers:

```text
trg_audit_trail_times_governance
trg_t3_fence_admin_password_reset_times
```

Disposition:

```text
TIMES_DIRECT_WRITE_DISPOSITION =
  ALREADY_HARDENED / PRESERVE AS INVARIANT
```

PR-04 must not restore or broaden direct `authenticated` write grants on
`public.times`.

## 4. Exact frontend data-client boundary

`src/App.jsx` exact blob:

```text
731b416307baac0e4e01a1e2277a1f2b0050e0e0
5930 lines
```

Generic client capabilities remain defined:

| Line | Capability |
|---:|---|
| 252 | `query(table,...)` |
| 253 | `patch(table,...)` |
| 254 | `insert(table,...)` |
| 255 | `rpc(function,...)` |

The generic capability is not itself product authorization.

Exact-ref source and compiled-bundle inspection established:

```text
active sb.patch(...) call-sites for leads/lotes/times = 0
active sb.insert(...) call-sites for leads/lotes/times = 0

literal /rest/v1/leads = 0
literal /rest/v1/lotes = 0
literal /rest/v1/times = 0

direct .from('leads').insert/update/delete = 0
direct .from('lotes').insert/update/delete = 0
direct .from('times').insert/update/delete = 0
```

The compiled `dist/assets/index-BzY82WCC.js` contains the same generic PATCH
capability and the expected RPC names, but no literal direct REST endpoint or
Supabase `.from(...)` DML path for these three tables.

## 5. Operation / call-site map

### 5.1 CRM / lead / lot mutation paths

| Product operation | Exact call-site | Current mutation boundary | Direct table DML |
|---|---|---|---|
| Update lead feedback | `src/App.jsx:408` | `atualizar_feedback` | none found |
| Move individual funnel | `src/App.jsx:419,3128` | `mover_funil` | none found |
| Register outbound message state | `src/App.jsx:689,2617,2774` | `registrar_mensagem` | none found |
| Acquire next lead | `src/App.jsx:862`; service line 108 | `proximo_lead` | none found |
| Register feedback | `src/App.jsx:886,3089`; service line 119 | `registrar_feedback` | none found |
| Request lot | `src/App.jsx:901` | `solicitar_lote` | none found |
| Move batch of selected leads in funnel | `src/App.jsx:3332` | `mover_funil_lote` | none found |
| Import lead batch | `src/App.jsx:3642` | `importar_leads_batch` | none found |
| Read available lead/open-lot counters | `src/App.jsx:4157` | direct SELECT | read only |
| Distribute lots | `src/App.jsx:4159` | `distribuir_lotes` | none found |
| Manage list pause/reactivate/close | `src/App.jsx:4356,4500+` | `gerenciar_lista` | RPC currently unusable by authenticated |
| Delete list / invalidate eligible leads | `src/App.jsx:4381` | `excluir_lista` | none found |
| Switch list | `src/App.jsx:5471` | `trocar_lista` | none found |

The Aceleração service uses only:

```text
proximo_lead
registrar_feedback
```

through `/rest/v1/rpc/<function>`.

### 5.2 Team/governance paths

`TimesTab` is reachable from `src/App.jsx:4914`.

| Product operation | Exact call-site | Current boundary |
|---|---|---|
| Read own teams | `TimesTab.jsx:241` | `get_meus_times` RPC |
| Read brokers/team | `TimesTab.jsx:242` | `get_corretores_time` RPC |
| Move broker to team | `TimesTab.jsx:262` | `atualizar_time_corretor` RPC |
| Toggle broker eligibility | `TimesTab.jsx:267` | `atualizar_status_corretor` RPC |
| Create team | `TimesTab.jsx:272` | `criar_time` RPC |
| Reset password | `TimesTab.jsx:253` | `criar-usuario` Edge Function |

`CriarUsuarioForm.jsx:105` also reads teams through `get_meus_times`.

The `criar-usuario` Edge Function reads `times` at line 411 through its admin
client only to verify a gestor's target-team scope. It does not establish a
client-role direct write dependency on `public.times`.

The `gpt-especialista` Edge Function contains no `leads`, `lotes` or
`times` table operation.

### 5.3 API / jobs / workflows / scripts

No active direct `leads/lotes/times` DML dependency was identified in:

```text
api/criar-usuario.js
api/mesa-worker-proxy.js
supabase/functions/gpt-especialista/index.ts
11 GitHub workflows
8 repository scripts
public PME assets
service workers
```

No scheduled job/cron declaration touching these tables was found in the
versioned runtime/deployment surfaces.

## 6. Direct DML target contract

The exact direct-grant hardening target supported by current live + repository
evidence is:

```text
public.leads:
  remove authenticated INSERT
  remove authenticated UPDATE

public.lotes:
  remove authenticated UPDATE

public.times:
  NO CHANGE — already hardened
```

No evidence supports adding the following to the PR-04 revoke delta because
`authenticated` does not currently possess them:

```text
leads DELETE
lotes INSERT
lotes DELETE
times INSERT
times UPDATE
times DELETE
```

Current write policies should remain dormant in the initial bounded direct-grant
PR unless a later specialist gate establishes a specific need to alter them.
That preserves one-risk/one-rollback semantics.

## 7. Required compatibility-writer set proven by current call-sites

These writers are required by current exact-ref M1 call-sites and must preserve
their approved EXECUTE/function contracts if PR-04 later removes direct table
grants.

| Writer | Writes | authenticated EXECUTE | Definition MD5 | ACL MD5 |
|---|---|---:|---|---|
| `atualizar_feedback(uuid,text,text)` | leads | yes | `57ba2f5d9cbc65cbbd9ed213265b184c` | `06c8bd810f2d9a52a993cd903c13793a` |
| `distribuir_lotes()` | leads+lotes | yes | `0132905fc1942b219b0e96d82e6407d6` | `06c8bd810f2d9a52a993cd903c13793a` |
| `excluir_lista(uuid)` | leads+listas | yes | `80ef746e48f99479367049e687e78119` | `d1707186c8e5f1577bde2338d7541aec` |
| `importar_leads_batch(uuid,jsonb,text)` | leads+listas | yes | `8f8f2c8b8593a54068783c7ddd4a84ee` | `06c8bd810f2d9a52a993cd903c13793a` |
| `mover_funil(uuid,uuid,text)` | leads+funil_movimentacoes | yes | `dab988abbd2d50ae57159cc4110051d8` | `06c8bd810f2d9a52a993cd903c13793a` |
| `mover_funil_lote(uuid[],uuid,text)` | leads+funil_movimentacoes | yes | `0d91aba2b42839a6f970a6b00da260d7` | `06c8bd810f2d9a52a993cd903c13793a` |
| `proximo_lead()` | leads | yes | `d0d185f14f3be1ee7d550bff5991613f` | `06c8bd810f2d9a52a993cd903c13793a` |
| `registrar_feedback(uuid,text,text)` | leads+lotes | yes | `3a6282c898199abc6c497a8cdfb5d16f` | `06c8bd810f2d9a52a993cd903c13793a` |
| `registrar_mensagem(uuid,text,integer)` | leads | yes | `6649911ef54c546dab9207206a650c31` | `06c8bd810f2d9a52a993cd903c13793a` |
| `solicitar_lote(uuid)` | leads+lotes | yes | `f0adebaa3878c7f4c841c19ca5bd4743` | `d1707186c8e5f1577bde2338d7541aec` |
| `trocar_lista(uuid,integer)` | leads+lotes | yes | `715dc6724fd73e94e7414cb67707c80c` | `d1707186c8e5f1577bde2338d7541aec` |

All listed objects were observed live as owner `postgres`,
`SECURITY DEFINER=true`, with no anon/PUBLIC EXECUTE.

Because SECURITY DEFINER executes with the function owner's privileges,
removing caller table DML grants does not by itself prevent these functions from
writing. Function authorization safety remains an independent contract.

## 8. Live writers not proven necessary by current versioned call-sites

No runtime call-site in `src/api/supabase functions` was found for:

```text
devolver_lote(uuid)
encerrar_lote_parcial(uuid,integer,text,text)
set_lembrete(uuid,timestamptz)
dispensar_lembrete(uuid)
mover_funil_batch(uuid[],uuid,text)
```

Disposition:

```text
DO NOT classify as required compatibility writers merely because they exist.
DO NOT change their ACL/function bodies inside the primary PR-04 revoke unless
a separately adjudicated risk requires it.
```

Additional live facts:

- `devolver_lote`, `encerrar_lote_parcial`, `set_lembrete` currently have
  authenticated EXECUTE;
- `dispensar_lembrete` and `mover_funil_batch` do not.

## 9. B2-BD-OBS-01 — gerenciar_lista

### 9.1 Reachability

The current UI calls:

```text
src/App.jsx:4356
sb.rpc("gerenciar_lista", ...)
```

The same component renders reachable Pausar/Reativar/Encerrar actions that call
this path.

### 9.2 Live database contract

```text
identity:
  public.gerenciar_lista(uuid,text,text)

SECURITY DEFINER:
  true

owner:
  postgres

authenticated EXECUTE:
  false

anon EXECUTE:
  false

PUBLIC EXECUTE:
  false

definition MD5:
  831308e58497d8b9149a1edc593c6640

ACL MD5:
  db23e67d6fad77fdfa003856d807d6af
```

The function body:

- checks `is_gestor()`;
- does not derive the actor with `auth.uid()`;
- does not derive/bind `empresa_id`;
- updates `listas` by caller-supplied `p_lista_id`;
- updates `leads` by `lista_id`;
- lacks an explicit same-tenant predicate in those writes.

Classification:

```text
B2-BD-OBS-01 =
  CONFIRMED UI↔DB COMPATIBILITY CONTRACT MISMATCH

DO NOT GRANT EXECUTE AS PART OF B2
DO NOT RETAIN DIRECT TABLE DML TO COMPENSATE
```

If the product action remains required, it needs a separately authorized,
tenant-safe RPC redesign. If obsolete, removal/retirement is a separate bounded
change.

## 10. Critical RPC contract cards

### 10.1 importar_leads_batch

```text
identity:
  public.importar_leads_batch(uuid,jsonb,text)

SECURITY DEFINER / owner:
  true / postgres

authenticated EXECUTE:
  true

definition MD5:
  8f8f2c8b8593a54068783c7ddd4a84ee

actor:
  auth.uid() required
  active caller profile required

tenant:
  empresa_id derived from caller profile
  target lista validated with lista.id + empresa_id
  inserted lead empresa_id is server-derived

writes:
  leads
  listas
  logs
```

Residual contract question:

The function establishes caller/company binding, but the minimum product role
allowed to import remains a Product/AppSec authorization question. PR-04 must
not silently broaden or tighten that role contract without separate review.

### 10.2 encerrar_lote_parcial

```text
identity:
  public.encerrar_lote_parcial(uuid,integer,text,text)

SECURITY DEFINER / owner:
  true / postgres

authenticated EXECUTE:
  true

definition MD5:
  f569795fdfbc249b5981d60454375072

current versioned app call-site:
  NOT FOUND

actor:
  auth.uid() -> broker

ownership:
  lot ownership checked by corretor_id

tenant:
  explicit empresa_id binding was not observed in the critical lot lookup/update

writes:
  leads
  lotes
```

Disposition:

```text
NOT REQUIRED BY CURRENT PR-04 COMPATIBILITY MAP.
KEEP OUT OF PRIMARY CHANGE.
Independent RPC hardening review remains warranted if this function is
reintroduced into an active product path.
```

### 10.3 set_lembrete

```text
identity:
  public.set_lembrete(uuid,timestamptz)

SECURITY DEFINER / owner:
  true / postgres

authenticated EXECUTE:
  true

definition MD5:
  03f69048d36608d73c6c7fd14e230cbc

current versioned app call-site:
  NOT FOUND

actor:
  auth.uid() -> corretor_id

ownership:
  UPDATE scoped by lead.id + corretor_id

explicit empresa binding:
  NOT OBSERVED

explicit active-profile check:
  NOT OBSERVED

writes:
  leads
```

Disposition:

```text
NOT REQUIRED BY CURRENT PR-04 COMPATIBILITY MAP.
KEEP OUT OF PRIMARY CHANGE.
```

### 10.4 gerenciar_lista

See section 9.

Disposition:

```text
UNAVAILABLE TO authenticated
UNSAFE TO ENABLE CASUALLY
SEPARATE REMEDIATION/RETIREMENT DECISION REQUIRED
```

## 11. Team/governance RPC invariant cards

These are not B2 direct-grant targets, but their current RPC boundary explains
why `times` direct UPDATE must remain absent.

```text
get_meus_times()
  authenticated EXECUTE=true
  SECURITY DEFINER=true
  no writes

get_corretores_time(uuid)
  authenticated EXECUTE=true
  SECURITY DEFINER=true
  no writes

atualizar_time_corretor(uuid,uuid)
  authenticated EXECUTE=true
  SECURITY DEFINER=true
  writes corretores
  actor/role + empresa/team checks observed

atualizar_status_corretor(uuid,boolean,boolean)
  authenticated EXECUTE=true
  SECURITY DEFINER=true
  writes corretores
  active actor + role/company/team checks observed

criar_time(text,uuid)
  authenticated EXECUTE=true
  SECURITY DEFINER=true
  writes times
  active actor + admin/root/company binding observed
```

PR-04 must preserve this already-hardened direct-table boundary.

## 12. Proposed proof matrix for a later authorized implementation

These are evidence IDs only. They do not authorize execution.

### 12.1 Positive proof IDs

```text
B2-POS-01 import leads via importar_leads_batch
B2-POS-02 request/allocate lot via solicitar_lote
B2-POS-03 administrative lot distribution via distribuir_lotes
B2-POS-04 acquire next lead via proximo_lead
B2-POS-05 update feedback via atualizar_feedback
B2-POS-06 register feedback via registrar_feedback
B2-POS-07 move individual funnel via mover_funil
B2-POS-08 move selected batch via mover_funil_lote
B2-POS-09 register message state via registrar_mensagem
B2-POS-10 switch list via trocar_lista
B2-POS-11 delete-list behavior via excluir_lista
B2-POS-12 authenticated direct SELECT remains for required lead/lot reads
B2-POS-13 TimesTab RPC flows remain functional with times direct DML absent
```

`gerenciar_lista` is excluded from positive B2 continuity proof until its
separate contract mismatch is resolved.

### 12.2 Negative proof IDs

For isolated/lab execution only unless separately authorized otherwise:

```text
B2-NEG-01 authenticated direct leads INSERT denied
B2-NEG-02 authenticated direct leads UPDATE denied
B2-NEG-03 authenticated direct leads DELETE denied
B2-NEG-04 authenticated direct lotes INSERT denied
B2-NEG-05 authenticated direct lotes UPDATE denied
B2-NEG-06 authenticated direct lotes DELETE denied
B2-NEG-07 anon direct writes denied
B2-NEG-08 forged empresa_id rejected through approved mutation boundaries
B2-NEG-09 forged corretor_id rejected
B2-NEG-10 forged lista_id rejected
B2-NEG-11 forged lote_id rejected
B2-NEG-12 forged time_id rejected
B2-NEG-13 wrong-owner mutation rejected
B2-NEG-14 cross-tenant lead/lot mutation rejected
B2-NEG-15 mixed-tenant batch rejected atomically
B2-NEG-16 unauthenticated RPC invocation rejected where required
B2-NEG-17 gerenciar_lista remains unavailable; no privilege broadening
B2-NEG-18 rollback restores exact old grants
B2-NEG-19 reapply restores hardened grants
```

Pilot Production is not authorized for this offensive negative suite.

## 13. Candidate preflight/postflight contract — no SQL

Before a later authorized migration, re-resolve at the exact implementation
head:

```text
project ref
main/head/forward blob
authenticated and anon table/column grants
RLS/FORCE RLS
leads_insert / leads_update / lotes_update / SELECT policies
times no-direct-write invariant
required RPC signatures
owners
SECURITY DEFINER/INVOKER
search_path
definition fingerprints
ACL/EXECUTE fingerprints
call-site map parity
absence of undocumented direct DML
rollback artifact
lab proof state
concurrent migration/drift state
```

Postflight catalog proof must establish:

```text
leads SELECT=true
leads INSERT=false
leads UPDATE=false
leads DELETE=false

lotes SELECT=true
lotes INSERT=false
lotes UPDATE=false
lotes DELETE=false

times direct write grants remain false
anon direct writes remain false
RLS/FORCE RLS preserved
approved policies unchanged
required RPC definitions/ACLs/EXECUTE unchanged
no PUBLIC/anon writer grant introduced
expected constraints/triggers preserved
```

## 14. Rollback contract

If a future bounded PR changes only the direct table privileges, the technical
rollback is exactly:

```text
restore authenticated leads INSERT
restore authenticated leads UPDATE
restore authenticated lotes UPDATE
```

No data/function/policy rollback should be needed if those surfaces remain
untouched.

A successful rollback reopens B2:

```text
B2 = OPEN / BLOCKING
Security Go = DENIED
```

## 15. One-PR boundary

The primary B2 direct-write exposure can remain one bounded PR **only if** the
implementation delta is limited to the approved direct-grant restriction plus
its proof/rollback artifacts.

Do not mix into that primary-risk change:

```text
gerenciar_lista redesign
encerrar_lote_parcial redesign
set_lembrete redesign
broad lotes tenant-FK redesign
unrelated RPC ACL cleanup
broad RLS policy cleanup
times grant changes
```

Those are separately adjudicated risks.

## 16. Current evidence conclusion

```text
B2_FINDING = CONFIRMED

EXHAUSTIVE_VERSIONED_CALLSITE_MAP =
  ESTABLISHED FOR THE DEFINED EXACT-REF APPLICATION/INTEGRATION SURFACES

DIRECT_DML_TARGET =
  leads INSERT
  leads UPDATE
  lotes UPDATE

TIMES_DISPOSITION =
  ALREADY HARDENED / PRESERVE

GERENCIAR_LISTA =
  REACHABLE UI + AUTHENTICATED EXECUTE FALSE
  CONTRACT MISMATCH CONFIRMED
  DO NOT GRANT EXECUTE IN B2

IMPLEMENTATION_AUTHORITY =
  NOT GRANTED

SECURITY_GO =
  DENIED

NEXT GATE =
  independent Backend/Data re-adjudication of this exact versioned artifact,
  followed by independent AppSec target-contract review
```
