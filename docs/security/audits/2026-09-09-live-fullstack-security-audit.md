# FECH.AI — Live Full-Stack Security Audit — 2026-09-09

**Status:** `LIVE_READ_ONLY_AUDIT / CANONICAL_CANDIDATE_EVIDENCE / NOT_SECURITY_GO`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Audited main:** `ac20a30fea9095f036d8d466e83794432d58ca89`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Supabase:** `uobxxgzshrmbtjfdolxd / Discador-MesaCliente / PostgreSQL 17.6`

## Coverage
- public tables: 44/44; RLS enabled: 44/44
- public views: 8/8
- public functions: 160/160
- SECURITY DEFINER: 137/137 universe reconciled
- anon-executable public functions: 31; 22 SECURITY DEFINER; 9 mutation-hint
- public policies: 82/82
- public non-internal triggers: 31/31
- public constraints: 271/271
- authenticated direct-write public tables: 7
- anon direct public-table privileges: 0

No SQL/DDL/DML mutation, migration, RLS/policy/grant mutation, data mutation, deploy, hostile-client production test or Security Go decision was executed.

## Confirmed actionable findings

| Finding | Severity | Live conclusion | Mandatory remediation owner |
|---|---|---|---|
| F-01 | HIGH | `aprovar_rejeitar_mesa(uuid,...)` updates by supplied simulation UUID after `is_gestor()`, without tenant/resource binding | `STS-M3-07-01` |
| F-02 | HIGH | `relatorio_fornecedor(uuid)` reads supplied list/leads/evaluations without tenant/list binding | `STS-M3-07-01` |
| F-03 | HIGH | `get_dashboard_master()` and `get_stats_horario()` aggregate global data for gestor without tenant scope | `STS-M3-07-02` |
| F-04 | HIGH | `lista_avaliacoes` direct writes do not structurally bind empresa/lista/lote/corretor to one tenant | `STS-M3-04-04` |
| F-05 | HIGH | PME catalog related IDs use non-tenant-bound FKs, permitting mixed-tenant relationships structurally | `STS-M3-04-05` |
| F-06 | MEDIUM | `lead_tem_acao_real(uuid)` is client-executable SECURITY DEFINER without actor/tenant/ownership binding | `STS-M3-07-03` |
| F-07 | LOW | `acquire_lote_lock(uuid,uuid)` remains anon/client executable despite internal-helper target | `STS-M3-07-03` |
| F-08 | MEDIUM | `api/mesa-worker-proxy.js` proxies POST body without JWT/role/tenant guard; impact depends on deployment | `STS-M3-06-02` |
| F-09 | MEDIUM | default privileges in `public` are fail-open for future relations/functions | `STS-M3-04-11` |
| F-10 | LOW | 31 public functions remain anon-executable; ACL surface exceeds target allowlist | `STS-M3-07-04` |

## Refuted / bounded non-findings
- RLS is not globally absent: 44/44 public tables have RLS.
- No verified XSS exploit was established in inspected innerHTML sinks; dynamic PME values are escaped and URL components encoded.
- Supabase anon/publishable JWT in client source is not classified as a secret leak by itself.
- `criar-usuario`, `mover_funil`, `get_dashboard_gestor`, `get_dashboard_stats`, `get_funil_stats`, `get_corretores_time`, `atualizar_time_corretor` showed server-side checks in reviewed contracts.

## Product Authority zero-residual directive

```text
INTERMEDIATE TASK MAY PRESERVE HISTORICAL ACCEPTED_WITH_RESIDUALS
BUT
STS-M3 FINAL != ACCEPTED_WITH_RESIDUALS
STS-M5 FINAL != ACCEPTED_WITH_RESIDUALS
STS-M6 FINAL != ACCEPTED_WITH_RESIDUALS
SECURITY_GO_CANDIDATE != ACCEPTED_WITH_RESIDUALS

EVERY ACTIONABLE SECURITY FINDING
MUST END AS
REMEDIATED + VERIFIED
OR
NOT_APPLICABLE_PROVEN / FALSE_POSITIVE_PROVEN

OPEN / ACCEPTED MATERIAL RESIDUAL
= FINAL GATE BLOCKED
```

## WBS integration
```text
F-04 -> STS-M3-04-04
F-05 -> STS-M3-04-05
F-09 -> STS-M3-04-11
F-01/F-02 -> STS-M3-07-01
F-03 -> STS-M3-07-02
F-06/F-07 -> STS-M3-07-03
F-10 -> STS-M3-07-04
F-08 -> STS-M3-06-02
```

Verification path:
M3 implementation -> M3 negative proof/AppSec -> M4 integration -> M5 hostile-client/regression/config/dependency/observability + independent re-audit -> M5 zero-open-finding gate -> M6 evidence/blocker closeout -> independent final review -> Product Authority Security Go decision.

## Limits
Still required before Security Go: hostile-client tests in isolated authorized environment, launch-scope regression, secret/config/deploy proof, dependency/CVE gate, storage/auth/browser/integration/resource-abuse coverage, observability/incident/rollback proof, independent AppSec closure, and zero open actionable findings across canonical audits.
