# FECH.AI — 2026-09-09 Live Security Audit to WBS Closure Plan

**Status:** `AUDIT_INTEGRATION_PLAN / DOCUMENTATION_ONLY / CANDIDATE`  
**Decision base main:** `ac20a30fea9095f036d8d466e83794432d58ca89`

## Purpose

Bind every material finding from the 2026-09-09 GitHub + Supabase live READ_ONLY audit to a concrete implementation phase and a downstream proof gate so that no finding can disappear into generic residual-risk language.

## Finding closure matrix

| Finding | Cause | Remediation owner/task | Verification owner/task | Final closure evidence |
|---|---|---|---|---|
| F-01 `aprovar_rejeitar_mesa` | object UUID not tenant-bound under DEFINER | STS-M3-03-02 | STS-M5-01/02 | cross-tenant mutation denied + AppSec review |
| F-02 `relatorio_fornecedor` | list UUID not tenant-bound under DEFINER | STS-M3-03-02 | STS-M5-01/02 | cross-tenant read denied |
| F-03 master/stats analytics | manager gate without tenant predicate | STS-M3-03-03 | STS-M5-02 | tenant-scoped analytics regression |
| F-04 `lista_avaliacoes` | simple FK/policy relation can mix tenants | STS-M3-04-04 | STS-M3-04-07/09 + M5-02 | invariant + negative proof |
| F-05 PME catalogs | related IDs not tenant-composite | STS-M3-04-05 | STS-M3-04-07/09 + M5-02 | invariant + negative proof |
| F-06 `lead_tem_acao_real` | internal helper directly authenticated | STS-M3-03-04 | STS-M5-01 | direct client call denied or resource-bound |
| F-07 `acquire_lote_lock` | internal helper anon reachable | STS-M3-03-04 | STS-M5-01/05 | client reachability removed; availability proof |
| F-08 `mesa-worker-proxy` | server proxy lacks auth boundary | STS-M3-06-02/03 | STS-M5-01/04 | unauthenticated 401/removed/unreachable + bounded payload/rate |
| F-09 default privileges | future objects may be born fail-open | STS-M3-04-06/07 | STS-M5-04 | migration/default ACL fail-closed proof |
| F-10 anon RPC surface | ACL exceeds accepted target | STS-M3-03-05 | STS-M5-00/01 | exact allowlist convergence |

## Gate semantics

```text
DISCOVERED != FIXED
DOCUMENTED != FIXED
MIGRATION_MERGED != APPLIED
APPLIED != VERIFIED
VERIFIED_STATICALLY != HOSTILE_CLIENT_PASS
HOSTILE_CLIENT_PASS != SECURITY_GO
```

Every finding must progress through:

```text
OPEN
-> REMEDIATION_AUTHORIZED
-> IMPLEMENTED
-> APPLIED where applicable
-> LIVE_STATIC_VERIFIED
-> NEGATIVE_RUNTIME_VERIFIED where applicable
-> INDEPENDENT_REVIEW_PASS
-> CLOSED
```

A finding may move directly from OPEN to REFUTED only with fresh evidence that disproves the original exploit condition.

## No-residual finish line

The final security program cannot close with a material residual simply because an earlier bounded slice was accepted with residuals.

```text
MATERIAL RESIDUAL OPEN
=> owning task NOT FINAL-CLOSED
=> M5 NOT PASS
=> M6 NOT SECURITY-GO ELIGIBLE
```

## Current audit evidence package

The branch/PR carrying this plan should include:

- `docs/security/audits/2026-09-09-full-stack-security-audit.md`
- `docs/security/audits/2026-09-09-live-db-evidence.md`
- `docs/security/audits/2026-09-09-github-issues.md`
- `docs/roadmap/2026-09-09-security-to-scale-wbs-zero-residual-amendment.md`

The PDF is a presentation artifact. The Markdown + live evidence are the line-readable canonical review inputs.
