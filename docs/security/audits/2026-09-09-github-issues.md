# FECH.AI — GitHub Issue Drafts from 2026-09-09 Security Audit

Creating issues is a separate lifecycle action. This file stores implementation-ready drafts.

## A — HIGH — Bind Mesa approval and supplier report RPCs to authorized tenant/resource
Findings: F-01, F-02. WBS: `STS-M3-07-01`.
Acceptance: server-derived actor/empresa/time; target UUID bound to authorized scope; explicit audited root branch; tenant/resource predicate; cross-tenant negative proof; independent AppSec PASS.

## B — HIGH — Scope global dashboard/statistics RPCs to tenant
Finding: F-03. WBS: `STS-M3-07-02`.
Acceptance: gestor only own empresa/time; global analytics root-only; every subquery tenant-bound; cross-tenant regression PASS.

## C — HIGH — Harden lista_avaliacoes tenant relationship integrity
Finding: F-04. WBS: `STS-M3-04-04`.
Acceptance: database-enforced same-tenant empresa/lista/lote/corretor; mixed-tenant INSERT/UPDATE fail closed; legitimate flow green.

## D — HIGH — Harden PME catalog tenant relationship integrity
Finding: F-05. WBS: `STS-M3-04-05`.
Acceptance: cadence/empreendimento/created_by/updated_by same-tenant enforced; mixed-tenant writes fail closed.

## E — MEDIUM/LOW — Remove direct client reachability from internal helpers and converge anon EXECUTE allowlist
Findings: F-06, F-07, F-10. WBS: `STS-M3-07-03`, `STS-M3-07-04`.
Acceptance: internal helpers not client executable; every anon RPC explicitly justified; no blind bulk revoke; negative proof PASS.

## F — MEDIUM — Authenticate or retire mesa-worker-proxy
Finding: F-08. WBS: `STS-M3-06-02`.
Acceptance: resolve live deployment/caller; retained route requires JWT/authorization/tenant/resource limits; orphan route removed only after caller-absence proof.

## G — MEDIUM — Make public default privileges fail closed
Finding: F-09. WBS: `STS-M3-04-11`.
Acceptance: future relations/functions do not inherit broad client authority; explicit grants only; migration fitness test; current legitimate grants preserved.

## H — PROGRAM GATE — Zero-open-finding Security Go closure
WBS: `STS-M5-06`, `STS-M5-07`, `STS-M6-02`, `STS-M6-06`.
Acceptance: every actionable canonical-audit finding terminally closed; 22 Security Go domains covered or NOT_APPLICABLE_PROVEN; hostile-client/regression/config/dependency/observability gates pass; independent final review returns READY_FOR_PRODUCT_AUTHORITY_DECISION.
