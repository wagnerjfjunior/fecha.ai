# FECH.AI — 2026-09-09 Live DB Security Evidence

**Mode:** `STRICT READ_ONLY / NO PII / NO DATA MUTATION`  
**Project:** `uobxxgzshrmbtjfdolxd`  
**Audited main:** `ac20a30fea9095f036d8d466e83794432d58ca89`

## E00 — Catalog universe
```text
public tables = 44
public tables RLS enabled = 44
public views = 8
public functions = 160
SECURITY DEFINER = 137
anon executable public functions = 31
anon + SECURITY DEFINER = 22
anon mutation-hint functions = 9
public policies = 82
public non-internal triggers = 31
public constraints = 271
authenticated direct-write public tables = 7
anon direct public-table privileges = 0
```

## E01 — F-01
`aprovar_rejeitar_mesa`: SECURITY DEFINER; authenticated EXECUTE; `is_gestor()` guard; target simulation selected/updated by supplied UUID without tenant/time/ownership predicate.

## E02 — F-02
`relatorio_fornecedor`: SECURITY DEFINER; authenticated EXECUTE; gestor guard; reads listas/leads/lista_avaliacoes by supplied list UUID without caller tenant/list binding.

## E03 — F-03
`get_dashboard_master` and `get_stats_horario`: SECURITY DEFINER; gestor-accessible; global lead/list/broker aggregates lack empresa filter.

## E04 — F-04
`lista_avaliacoes`: authenticated SELECT/INSERT/UPDATE; RLS enabled; INSERT/UPDATE actor check uses `corretor_id = my_corretor_id()`; simple FKs for corretor/empresa/lista/lote; no composite tenant FK or relationship-integrity trigger.

## E05 — F-05
PME catalogs: authenticated INSERT/UPDATE; policies gate `pme_is_empresa_admin(empresa_id)`; cadence/empreendimento/created_by/updated_by use simple FKs; no composite empresa+related-object FK observed.

## E06 — F-06
`lead_tem_acao_real`: SECURITY DEFINER, authenticated EXECUTE, supplied lead UUID, no caller/tenant/ownership guard; returns boolean derived from lead state.

## E07 — F-07
`acquire_lote_lock`: SECURITY DEFINER, anon/authenticated EXECUTE, no auth.uid guard, target classified as internal helper.

## E08 — F-09
Default ACLs in public grant broad future-object authority to client roles. Current tables are mitigated by explicit RLS; future objects can fail open if hardening is omitted.

## E09 — Non-public schemas
auth/storage/realtime/extensions/vault/etc were enumerated for relation/function ACL/RLS posture. Vendor-managed ACL existence alone was not promoted to a FECH.AI vulnerability without applicable reachability proof.
