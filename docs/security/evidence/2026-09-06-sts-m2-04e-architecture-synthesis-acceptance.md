# FECH.AI — STS-M2-04E — Architecture Synthesis Acceptance

**Status:** `COMPLETE / ACCEPTED WITH IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS`  
**Evidence class:** `TARGET_ARCHITECTURE / PRODUCT_AUTHORITY_ACCEPTED / DOCUMENTATION_ONLY / NO_IMPLEMENTATION`  
**Decision date:** 2026-09-06  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Acceptance base main:** `aa266df3124f407a3f2c155c8f8ab5c193707783`  
**SES evidence ref:** `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`

## 1. Decision

Product Authority accepts STS-M2-04E as:

```text
STS-M2-04E =
COMPLETE WITH IMPLEMENTATION / LIFECYCLE /
RUNTIME-ASSURANCE RESIDUALS

FIVE-RESIDUAL E AUTHORITY ADJUDICATION =
COMPLETE

B3/C3 TARGET-AUTHORITY SEMANTIC RESIDUALS =
ZERO

PRODUCT-AUTHORITY SEMANTIC RESIDUALS
FOR 004 / 031 / 036 / 047 / 127 =
ZERO

CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS =
NOT CLAIMED

Security Go =
NOT_GRANTED
```

Preserve:

```text
TARGET CONTRACT RESOLVED != CURRENT IMPLEMENTATION COMPLIANT
ARCHITECTURE COMPLETE != APPSEC PASS
ARCHITECTURE COMPLETE != RUNTIME ASSURANCE
ARCHITECTURE COMPLETE != SECURITY GO
```

## 2. Provenance and evidence coverage

| Source | Exact ref/object | Coverage | Material use |
|---|---|---|---|
| `docs/bootstrap/INDEX.md` | blob `6040b7e15b480181b8198e058084be0d2cd53d24` | INTEGRAL_READ | bootstrap |
| `docs/skills/SES_SPECIALIST_ROUTING.md` | blob `10cb3d7b3de48c1ce6e47f3d549ad46fa17c1ae6` | INTEGRAL_READ | architecture -> software-systems-architect |
| `docs/skills/fechai-gpt1-architect-saas.md` | blob `ac37cd53e6f777ca4b117d9ce32afe5c90d2b232` | INTEGRAL_READ | architecture/evidence/authority rules; paginated through EOF |
| common Specialist Modus Operandi | blob `e2deb1e80d6666390f222781655200c240fc6bac` | INTEGRAL_READ | evidence and fail-closed contract |
| `docs/sfjm/INDEX.md` | blob `3f83b38d7c6f4fea9d7d02dee5b3798bdfe2baad` | INTEGRAL_READ | continuity authority model |
| STS-M2-04B1 authority policy | blob `15e771e99ce3e424ba4a869a00d4965bed733fc3` | INTEGRAL_READ | DEFINER/INVOKER target policy |
| STS-M2-04B3 accepted classification | blob `96d31bb3c471ddbc606f391aff13cb7674358e8b` | INTEGRAL_READ | five original residuals + 119 history |
| STS-M2-04C/C3 adjudication CSV | blob `716c23d5f549eb465f3393cdfc5989dda82b69a7` | INTEGRAL_READ | historical 68/40/5 projection |
| STS-M2-04D trigger authority evidence | blob `7fdc63a95d81661598937aa0bdfa654bcb9db66a` | INTEGRAL_READ | D 8/1/0 + 18 trigger instances |
| Issue #133 | live issue #133 | INTEGRAL_READ | root/admin_global platform-control-plane contract |
| B4 list ACL migration | blob `ccb3b406e848e13edb7ac123691f812ec00f5fe7` | INTEGRAL_READ | gestor list/team binding model |
| `src/components/MesaCliente/TabHistorico.jsx` | blob `c41f6bc1ee6e61b990e79cd74b4d7a24fac1cedd` | INTEGRAL_READ | gestor approval workflow |
| `src/features/mesaCliente/api/mesaClienteApi.js` | blob `0b21ef59ebce773673424d10b2e37e255e9b9db4` | INTEGRAL_READ | exact approval RPC call shape |
| Mesa frontend/RPC integration | blob `ddd281100f036734a66b303fa18fd9f517305f35` | INTEGRAL_READ | server-side auth/empresa contract |
| current SFJM thin/material views | `aa266df3124f407a3f2c155c8f8ab5c193707783` | PARTIAL_READ / CURRENT SECTIONS | reconciliation target; historical remainder preserved byte-for-byte |

No repository-wide re-audit and no Supabase runtime mutation/testing were performed for E.

## 3. Historical C3 state preserved

C3 remains historical evidence exactly as accepted:

```text
C3 historical projection =
68 DEFINER
40 INVOKER
5 NOT_DETERMINED
113 B3/C3 routines
```

The five historical C3 NOT_DETERMINED rows were:

```text
004 aprovar_rejeitar_mesa(uuid,text,text)
031 gerenciar_lista(uuid,text,text)
036 get_dashboard_master()
047 get_stats_horario()
127 solicitar_lote_forcado(uuid)
```

E supersedes only their target-authority disposition. It does not rewrite C3 history.

Scope identity remains:

```text
137 SECURITY DEFINER routines
- 15 B2 routines
- 9 M2-04D trigger-provenance routines
= 113 B3/C3 routines
```

Therefore the 113-row result is the B3/C3 subset, not the complete 137-routine universe. B2 remains a separate accepted 15-routine slice with residuals, and M2-04D remains a separate accepted 9-trigger-routine target classification. E does not collapse B2 + B3/C3 + D into one homogeneous mode distribution.

## 4. E superseding five-row adjudication

| Ord | Routine | E target disposition | Product semantics | Remaining class |
|---|---|---|---|---|
| 004 | `aprovar_rejeitar_mesa(uuid,text,text)` | `DEFINER` | RESOLVED | implementation + AppSec/runtime proof |
| 031 | `gerenciar_lista(uuid,text,text)` | `DEFINER` | RESOLVED | implementation/caller-ACL + proof |
| 036 | `get_dashboard_master()` | `NON_MODE_LIFECYCLE / RETIRE_CURRENT_SEMANTICS` | RESOLVED | current-routine retirement/remediation |
| 047 | `get_stats_horario()` | `INVOKER` | TENANT/TEAM-SCOPED / RESOLVED | global-body/RLS remediation + proof |
| 127 | `solicitar_lote_forcado(uuid)` | `NON_MODE_LIFECYCLE / RETIRE_DEPRECATE` | SELF-ONLY LOT REQUEST / RESOLVED | lifecycle/remediation |

B3/C3 subset target projection after E:

```text
70 target DEFINER
41 target INVOKER
0 target-authority semantic NOT_DETERMINED
2 NON_MODE_LIFECYCLE dispositions
113 B3/C3 routines
```

Do not report `70 + 41 = 111 total routines`. The two lifecycle rows remain in the 113-routine B3/C3 subset. Do not promote this subset projection to a 137-routine cross-slice aggregate; B2 and D retain their own accepted classifications and residual boundaries.

## 5. 004 authority contract

```text
actor
-> auth.uid()
-> active gestor
-> actor empresa
-> trusted mesa_simulacoes row
-> simulation empresa/object binding
-> allowed approval/rejection transition
-> privileged mutation
-> audit
```

`p_simulacao_id` is a locator, not authority.

Target mode is `DEFINER` because approval/rejection is a protected business transition and the caller must not receive unrestricted direct mutation/audit authority. The current body remains non-compliant until server-side actor -> empresa -> simulation binding and transition guards are proven before privileged effect.

## 6. 031 authority contract

`p_lista_id` is an object locator, not authority. The target contract preserves two tenant-side authority branches.

ADMIN_LOCAL branch:

```text
auth.uid()
-> active admin_local
-> actor empresa
-> p_lista_id
-> authoritative listas row
-> listas.empresa_id = actor empresa
-> permitted lifecycle action
-> privileged coordinated mutation
-> audit
```

ADMIN_LOCAL is the tenant control plane and does not require:

```text
listas.time_id in my_times_como_gestor()
```

GESTOR branch:

```text
auth.uid()
-> active gestor
-> actor empresa
-> p_lista_id
-> authoritative listas row
-> listas.empresa_id = actor empresa
-> listas.time_id in my_times_como_gestor()
-> permitted lifecycle action
-> privileged coordinated mutation
-> audit
```

GESTOR remains team-scoped.

Preserve:

```text
ROOT / ADMIN_GLOBAL != ordinary ADMIN_LOCAL
ROOT / ADMIN_GLOBAL != ordinary GESTOR
platform authority != automatic tenant list lifecycle authority
assigned_gestor_id = NOT_INVENTED
lista_visibilidade = distribution / visibility authority
lista_visibilidade != independent list lifecycle authority
```

Target mode remains `DEFINER` because list lifecycle actions coordinate protected changes across list/lead/audit state and must be authorized by trusted tenant/object binding before privileged effect. The current caller/ACL contradiction and object binding remain implementation residuals.

## 7. 036 / 047 root and gestor authority

Issue #133 remains authoritative:

```text
ROOT / ADMIN_GLOBAL = PLATFORM CONTROL PLANE
ADMIN_LOCAL = TENANT CONTROL PLANE
GESTOR = TEAM CONTROL PLANE
CORRETOR = INDIVIDUAL BUSINESS PLANE

platform authority != automatic tenant business authority
```

Root must not gain unconditional ordinary tenant commercial-data visibility.

Therefore:

```text
036 =
current global commercial semantics NOT TARGET-COMPLIANT
NON_MODE_LIFECYCLE
RETIRE_CURRENT_SEMANTICS

possible future platform-safe dashboard/replacement =
NOT DEFINED BY E
NOT AUTHORIZED BY THIS PR

047 =
tenant/team-scoped commercial statistics
TARGET INVOKER
root is not an ordinary cross-tenant commercial caller
```

047 still requires proof that effective RLS/hierarchy composition enforces actor empresa + managed-team scope. Insufficient current RLS is remediation input, not justification for preserving global owner-elevated reads.

## 8. 127 lot-request contract

```text
lot request = SELF-ONLY

gestor/admin/root requesting a lot on behalf of another broker =
NOT TARGET PRODUCT CAPABILITY
```

The forced-user surface is therefore a lifecycle retirement/deprecation problem, not a remaining product-authority ambiguity.

This decision does not remove the routine. Exact retirement mechanics require a separately authorized bounded change.

## 9. Findings after E

```text
004:
E architecture blocker = NO
current implementation/security blocker = YES

031:
E architecture blocker = NO
current implementation/security blocker = YES

036:
E architecture blocker = NO
current global commercial semantics = NOT TARGET-COMPLIANT
current routine semantics = RETIRE_CURRENT_SEMANTICS
possible future replacement = NOT DEFINED BY E / NOT AUTHORIZED BY THIS PR
lifecycle retirement remediation = REQUIRED

047:
E architecture blocker = NO
current implementation/security blocker = YES

127:
E architecture blocker = NO
forced-user target capability = NOT REQUIRED
lifecycle remediation = REQUIRED
```

## 10. Assurance and implementation boundary

```text
implementation remediation = NOT_PERFORMED
lifecycle remediation = NOT_PERFORMED
AppSec assurance = NOT_PERFORMED
hostile/cross-tenant runtime assurance = NOT_PERFORMED
database mutation = NO
Security Go = NOT_GRANTED
```

No SECURITY DEFINER/INVOKER mode, ACL, owner, search_path, RLS, policy, trigger, function body or production data was changed by this reconciliation.

## 11. M2-04 continuation boundary

STS-M2-04E does not define a future lettered slice.

```text
M2-04F semantics = NOT_CANONICALLY_DEFINED
M2-04F execution = NOT_AUTHORIZED
M2-05 execution = NOT_AUTHORIZED
M2-06 execution = NOT_AUTHORIZED
```

Next safe action after publication is Product Authority selection/definition of the next bounded M2-04 action from the accepted C/D/E state.

## 12. Final verdict

```text
STS-M2-04E =
COMPLETE / ACCEPTED WITH
IMPLEMENTATION-LIFECYCLE-RUNTIME RESIDUALS

FIVE-RESIDUAL E AUTHORITY ADJUDICATION = COMPLETE
B3/C3 TARGET-AUTHORITY SEMANTIC RESIDUALS = 0
CROSS-SLICE 137-ROUTINE HOMOGENEOUS MODE SYNTHESIS = NOT CLAIMED

CURRENT IMPLEMENTATION TARGET-COMPLIANT = NOT_PROVEN
APPSEC PASS = NOT_PERFORMED
RUNTIME ASSURANCE = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
```
