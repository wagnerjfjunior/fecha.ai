# FECH.AI — SFJM Material Event — 2026-09-09 Live Security Audit / Zero-Residual WBS Direction

## Material event

Product Authority directs that the 2026-09-09 live security audit findings are durable program inputs and that final FECH.AI security completion must not use material `ACCEPTED_WITH_RESIDUALS` as a launch-closing state.

## Evidence base

- FECH.AI main at audit start: `ac20a30fea9095f036d8d466e83794432d58ca89`
- Supabase project: `uobxxgzshrmbtjfdolxd / Discador-MesaCliente`
- Audit mode: READ_ONLY
- Database mutation: NONE
- GitHub runtime mutation before this documentation PR: NONE
- Active hostile production test: NONE

## Material findings to preserve

```text
F-01 HIGH   aprovar_rejeitar_mesa cross-tenant mutation path
F-02 HIGH   relatorio_fornecedor cross-tenant read path
F-03 HIGH   manager analytics global tenant scope
F-04 HIGH   lista_avaliacoes mixed-tenant relational integrity
F-05 HIGH   PME catalog mixed-tenant relational integrity
F-06 MEDIUM lead_tem_acao_real cross-tenant oracle / reachability
F-07 LOW    acquire_lote_lock anonymous internal-helper reachability
F-08 MEDIUM mesa-worker-proxy unauthenticated service boundary, deployment-conditioned
F-09 MEDIUM public default privileges fail-open future-object posture
F-10 LOW    broad anon-executable RPC surface
```

## Route

```text
M3 = remediate causes and close implementation authority/tenant/service boundaries
M4 = modularize without moving authority client-side; prove gateway non-regression
M5 = integrated current hostile-client / regression / secret-config / operational assurance
M6 = candidate only after zero material open security finding + independent PASS
```

## Continuity invariant

No material finding may disappear silently. Historical bounded slice acceptances remain provenance; they do not waive final closure requirements.

## Authorization boundary

This event records planning/governance direction. It does not authorize SQL, migration, RLS/policy/grant changes, Supabase/Auth mutation, deploy, hostile-client production test, Ready, merge, or Security Go by itself.
