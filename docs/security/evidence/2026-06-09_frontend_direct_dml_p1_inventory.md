# FECH.AI / Frontend Direct-DML P1 Inventory

Date: 2026-06-09
Status: READ-ONLY INVENTORY / NO PRODUCTION CHANGE
Related checkpoint: PR #67 - authenticated write-surface P1 inventory
Current PR: PR #68 - frontend direct-DML P1 inventory
Recommended next phase: RPC/grants inventory and body review for P1 write paths

---

## 1. Summary

This document maps frontend direct data-mutation usage for the P1 tables identified in PR #67.

This is a read-only documentation inventory. It does not change application code, database grants, RLS policies, migrations, RPCs/functions, MesaCliente parser, MesaCliente financial engine, Worker, Make, n8n, Vercel or production behavior.

Primary finding:

- One direct frontend P1 write was identified: `src/App.jsx` uses the generic REST wrapper `sb.patch(...)` to update `public.corretores` during the mandatory password-change flow.
- No direct frontend insert/update/delete calls were found for `public.leads`, `public.lotes`, `public.times`, `public.lista_visibilidade` or `public.mesa_cliente_unidade_enriquecimentos` using the searched exact table patterns.
- Several P1-related mutations are routed through RPCs or Edge Functions instead of direct table DML.

Important limitation:

This inventory is based on repository code search and targeted source inspection. It does not execute runtime tracing and does not prove that dynamic table-name wrappers cannot exist elsewhere. Future review should still validate build output and runtime paths if needed.

---

## 2. P1 tables reviewed

| Table | Direct write surface from PR #67 | Frontend direct DML observed in this inventory |
|---|---:|---:|
| `public.corretores` | `UPDATE` | Yes - one `PATCH` wrapper call |
| `public.leads` | `INSERT`, `UPDATE` | No direct table DML found; RPC write paths observed |
| `public.lotes` | `UPDATE` | No direct table DML found; RPC write paths observed |
| `public.times` | `UPDATE` | No direct table DML found; RPC write paths observed |
| `public.lista_visibilidade` | `INSERT`, `UPDATE`, `DELETE` | No direct table DML found |
| `public.mesa_cliente_unidade_enriquecimentos` | `INSERT`, `UPDATE`, `DELETE` | No direct table DML found; RPC write path observed |

---

## 3. Method

Repository search covered exact frontend table-call patterns from PR #67:

```text
.from('corretores')
.from("corretores")
.from('leads')
.from("leads")
.from('lotes')
.from("lotes")
.from('times')
.from("times")
.from('lista_visibilidade')
.from("lista_visibilidade")
.from('mesa_cliente_unidade_enriquecimentos')
.from("mesa_cliente_unidade_enriquecimentos")
```

The search also reviewed broader table-name hits and source files where P1 names or Supabase REST/RPC wrappers appear.

Main files reviewed:

| File | Reason |
|---|---|
| `src/App.jsx` | Main FECH.AI frontend and custom REST/RPC wrapper |
| `src/components/TimesTab.jsx` | Team/user operational mutations |
| `src/components/CriarUsuario.jsx` | User creation compatibility adapter |
| `src/components/CriarUsuarioForm.jsx` | User creation flow through Edge Function |
| `src/components/RootPanel.jsx` | Root control plane / tenant operations |
| `src/components/TenantProvisioningRoot.jsx` | Tenant provisioning flow |
| `src/components/TenantProvisioningStandalone.jsx` | Root standalone provisioning wrapper |
| `src/services/aceleracaoOperacionalService.js` | CRM/Discador service bridge |
| `src/features/mesaCliente/api/mesaClienteApi.js` | MesaCliente RPC API wrapper |
| `src/lib/supabaseClient.js` | Shared Supabase client |
| `src/components/MesaCliente/supabaseClient.js` | MesaCliente Supabase client |

---

## 4. Generic REST wrapper found

`src/App.jsx` defines a custom Supabase REST wrapper named `createSB`.

The wrapper exposes:

```text
query(table, params, token)
patch(table, query, data, token)
insert(table, data, token)
rpc(functionName, args, token)
```

Security interpretation:

- `patch(...)` and `insert(...)` are generic table-DML helpers.
- Even if only one P1 write usage was found, this wrapper can perform direct REST writes if future code calls it with a sensitive table name.
- Future hardening should not only search `.from(...)`; it should also search `sb.patch(...)`, `sb.insert(...)` and wrapper aliases.

Risk classification:

```text
P1 architectural review item
```

This PR does not change the wrapper.

---

## 5. Findings by table

### 5.1 `public.corretores`

Frontend direct DML observed:

| File | Flow | Operation | Table | Fields observed | Classification |
|---|---|---:|---|---|---|
| `src/App.jsx` | Mandatory password-change completion | `PATCH` via `sb.patch` | `corretores` | `must_change_password` | P1 / controlled candidate |

Observed flow:

```text
TrocarSenhaObrigatoria
  -> sb.changePassword(token, nova)
  -> sb.patch("corretores", "id=eq." + corretorId, { must_change_password: false }, token)
```

Security concern:

This is a direct table update to `public.corretores` from frontend. Although the field appears narrow, the query uses a frontend-provided `corretorId` value and relies on RLS/policy correctness to prevent unauthorized update.

Recommended future treatment:

- Replace direct `sb.patch("corretores", ...)` with a narrow RPC such as `marcar_senha_inicial_definida` or equivalent.
- RPC should derive the current actor from `auth.uid()` and avoid accepting arbitrary broker/user row identifiers from frontend when possible.
- RPC should update only the authenticated user's own password-onboarding state or an explicitly authorized target.
- Add negative tests for forged `corretorId`, cross-company row and unauthenticated request.

Do not revoke `authenticated UPDATE` on `public.corretores` until this flow is replaced or proven safe.

---

### 5.2 `public.leads`

Frontend direct DML observed:

```text
No direct table-level INSERT or UPDATE was found for public.leads in the searched exact patterns.
```

Observed frontend write-related flows use RPCs, including examples:

| File | Flow | RPC |
|---|---|---|
| `src/App.jsx` | next lead / dialer | `proximo_lead` |
| `src/App.jsx` | feedback registration | `registrar_feedback` |
| `src/App.jsx` | funnel movement | `mover_funil` |
| `src/App.jsx` | message sequence registration | `registrar_mensagem` |
| `src/services/aceleracaoOperacionalService.js` | operational next lead | `proximo_lead` |
| `src/services/aceleracaoOperacionalService.js` | operational feedback | `registrar_feedback` |

Security interpretation:

The frontend appears to route lead mutations through RPCs rather than direct table DML in the reviewed paths.

Recommended next validation:

- PR #69 should inventory the above RPCs and their grants.
- PR #70 should review RPC bodies for `auth.uid()`, company/tenant isolation, ownership and payload validation.
- Do not remove table-level grants solely from this finding; confirm all operational write paths first.

---

### 5.3 `public.lotes`

Frontend direct DML observed:

```text
No direct table-level UPDATE was found for public.lotes in the searched exact patterns.
```

Observed write-related frontend flows use RPCs, including examples:

| File | Flow | RPC |
|---|---|---|
| `src/App.jsx` | request a new lot | `solicitar_lote` |
| `src/App.jsx` | list/lot rating | `avaliar_lista` |
| `src/App.jsx` | next lead / lot progress | `proximo_lead` |

Security interpretation:

Lot lifecycle appears RPC-driven in the reviewed frontend paths.

Recommended next validation:

- Review `solicitar_lote`, `avaliar_lista` and related lot RPCs in PR #69/#70.
- Confirm no hidden direct REST wrapper call writes to `lotes` in less-used views.

---

### 5.4 `public.times`

Frontend direct DML observed:

```text
No direct table-level UPDATE was found for public.times in the searched exact patterns.
```

Observed team-related write flows use RPCs:

| File | Flow | RPC |
|---|---|---|
| `src/components/TimesTab.jsx` | move broker to team | `atualizar_time_corretor` |
| `src/components/TimesTab.jsx` | toggle broker eligibility | `atualizar_status_corretor` |
| `src/components/TimesTab.jsx` | create team | `criar_time` |

Security interpretation:

Team and broker/team operations appear RPC-driven in the reviewed frontend paths. These RPCs still need grant and body review because they affect `corretores` and `times` operational authority.

Recommended next validation:

- PR #69 should inventory grants for `atualizar_time_corretor`, `atualizar_status_corretor` and `criar_time`.
- PR #70 should review actor-role validation and company/team scope validation.

---

### 5.5 `public.lista_visibilidade`

Frontend direct DML observed:

```text
No direct table-level INSERT, UPDATE or DELETE was found for public.lista_visibilidade in the searched exact patterns.
```

No active frontend file was identified using the exact table name in reviewed search results.

Security interpretation:

This lowers immediate frontend-breakage risk for future grant hardening, but does not eliminate database/RPC review needs. `lista_visibilidade` remains ACL-like and high-risk from the database perspective.

Recommended next validation:

- PR #69 should verify whether an RPC such as `gerenciar_visibilidade_lista` exists, what grants it has and whether it is used.
- PR #70 should review function body and policy behavior before any revocation.

---

### 5.6 `public.mesa_cliente_unidade_enriquecimentos`

Frontend direct DML observed:

```text
No direct table-level INSERT, UPDATE or DELETE was found for public.mesa_cliente_unidade_enriquecimentos in the searched exact patterns.
```

Observed MesaCliente enrichment write path uses RPC:

| File | Flow | RPC |
|---|---|---|
| `src/features/mesaCliente/api/mesaClienteApi.js` | save MesaCliente unit enrichment | `salvar_mesa_cliente_enriquecimento` |

Security interpretation:

MesaCliente enrichment appears RPC-driven in the reviewed frontend API wrapper. This is the preferred architectural direction, but the RPC remains sensitive and needs body/grant review.

Recommended next validation:

- PR #69 should inventory grants for `salvar_mesa_cliente_enriquecimento`.
- PR #70 should review body validation for company/tenant, project/unit scope and client-safe field boundaries.
- Do not alter MesaCliente parser, financial engine, proposal flow or commercial policy in this inventory PR.

---

## 6. Edge Function write paths observed

Some user/tenant creation flows do not write P1 tables directly from frontend but call server-side endpoints/Edge Functions.

Examples:

| File | Flow | Endpoint / RPC | Notes |
|---|---|---|---|
| `src/components/CriarUsuarioForm.jsx` | create user | Edge Function `criar-usuario` | Creates user through controlled backend path |
| `src/components/TimesTab.jsx` | reset user password | Edge Function `criar-usuario` action `reset_password` | Sensitive; should be reviewed as server-side authority |
| `src/components/TenantProvisioningRoot.jsx` | create company | RPC `criar_empresa_root` | Root control-plane operation |
| `src/components/TenantProvisioningRoot.jsx` | create initial admin | local API/Edge path `/api/criar-usuario` | Sensitive tenant provisioning flow |

These are not direct frontend table DML, but they are sensitive write paths and should be included in the RPC/Edge review track.

---

## 7. Risk ranking after frontend inventory

| Rank | Object / path | Reason |
|---:|---|---|
| 1 | `src/App.jsx` -> `sb.patch("corretores", ...)` | confirmed direct P1 table update from frontend |
| 2 | `src/App.jsx` generic `patch/insert` wrapper | can be reused for future direct writes if not governed |
| 3 | `salvar_mesa_cliente_enriquecimento` RPC path | MesaCliente-sensitive write path |
| 4 | lead mutation RPC paths | CRM/Discador-sensitive, but not direct table DML in reviewed frontend |
| 5 | team/broker mutation RPC paths | auth/governance-sensitive, but RPC-driven |
| 6 | `lista_visibilidade` | no frontend direct DML found, but database ACL-like surface remains sensitive |

---

## 8. Recommended next actions

### 8.1 Immediate next PR

Proceed with PR #69:

```text
RPC/grants inventory for P1 tables and P1 write paths
```

Include at minimum:

- `atualizar_feedback`
- `registrar_feedback`
- `mover_funil`
- `registrar_mensagem`
- `proximo_lead`
- `solicitar_lote`
- `avaliar_lista`
- `atualizar_time_corretor`
- `atualizar_status_corretor`
- `criar_time`
- `salvar_mesa_cliente_enriquecimento`
- `criar_empresa_root`
- user creation / reset Edge Function paths

### 8.2 First likely technical hardening candidate

After PR #69/#70, the first likely technical fix is the confirmed direct `public.corretores` update in mandatory password-change flow.

Possible future approach:

```text
Replace frontend sb.patch("corretores", ...) with narrow RPC.
Then reduce or constrain direct authenticated UPDATE on public.corretores if tests pass.
```

### 8.3 Required tests before hardening

- authorized password-change completion;
- unauthenticated request blocked;
- authenticated user cannot update another broker row;
- cross-company/cross-tenant update blocked;
- privileged fields cannot be modified through the onboarding flow;
- login/onboarding regression;
- admin/team management regression;
- CRM/Discador regression;
- MesaCliente regression if any shared auth profile field changes.

---

## 9. Explicit non-claims

This document does not claim that the platform is production-secure.

This document does not prove that every runtime write path was exhaustively traced.

This document does not prove that all RPCs are safe.

This document does not prove that all RLS policies are safe.

This document does not authorize grant revocation.

This document does not authorize Supabase migration execution.

This document does not change code or production behavior.

This document only records frontend direct-DML findings and prepares the next controlled review step.

---

## 10. Acceptance criteria for PR #68

This PR is acceptable only if:

- it is documentation-only;
- it creates one Markdown evidence file under `docs/security/evidence/`;
- it does not change application code;
- it does not change migrations;
- it does not change Supabase, RLS, grants, policies or RPCs;
- it does not change frontend behavior;
- it does not change MesaCliente parser or financial engine;
- it contains no raw production data;
- it contains no secrets or credentials;
- it does not claim production security approval;
- it clearly identifies the confirmed direct frontend P1 write and the RPC-driven alternatives.

---

## 11. Final conclusion

The frontend inventory found one confirmed direct P1 table mutation: `public.corretores` is updated from `src/App.jsx` through the generic `sb.patch(...)` wrapper during mandatory password-change completion.

No direct frontend table-level writes were found for the other reviewed P1 tables using the searched exact patterns. Most P1-related operational writes appear to be routed through RPCs or Edge Functions.

The next safe step is PR #69: inventory RPC grants and sensitive server-side write paths before proposing any technical hardening.
