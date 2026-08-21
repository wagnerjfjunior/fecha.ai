# FECH.AI - Architecture Audit Index

**Status:** ARCHITECTURE_INDEX / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE

This index lists architecture audit records that must be read before changing SaaS layering, Supabase access paths, Edge Functions, Vercel API proxy, LeadOps service bridges or sensitive multi-tenant flows.

---

## Current mandatory architecture records

### A1/A2 AS-IS architecture, call-site and App.jsx integral-read baseline

```text
docs/audits/architecture/2026-08-21-a1-a2-as-is-callsite-and-app-integral-read-baseline.md
```

Purpose:

```text
Preserves the A1/A2 static architecture reconstruction, the fresh integral GitHub range read of src/App.jsx, current direct-write inventory, authority-boundary gaps, candidate dependency cuts and anti-loop invalidation rules before any target-architecture synthesis.
```

Read before:

```text
- decomposing or materially refactoring src/App.jsx;
- selecting a target architecture for the FECH.AI monolith/decomposition front;
- changing administrative direct-write paths in EditarCorretorModal;
- changing MesaCliente composition/parser/Worker boundaries;
- changing LeadOps application/data-access boundaries;
- claiming that the A1/A2 baseline must be repeated without a material invalidation event.
```

### Edge Functions, SaaS security layers and LeadOps bridge context

```text
docs/audits/architecture/2026-06-11-edge-functions-layering-and-saas-security-context.md
```

Purpose:

```text
Records current Edge Functions, Vercel API proxy, frontend service bridges, Supabase RPC/RLS authority, PR #82 containment and future LeadOps Edge/BFF decision path.
```

Read before:

```text
- changing AceleracaoOperacional service bridge;
- creating LeadOps Edge Functions;
- changing criar-usuario or assistente-ai paths;
- introducing Vercel API proxy for sensitive operations;
- changing frontend/Supabase direct access patterns;
- discussing Edge/BFF as final architecture.
```

---

## Current architectural rules

```text
Frontend displays and requests.
Edge/Vercel API orchestrates when justified.
Database/RPC validates and decides.
RLS/policies/grants remain mandatory.
AI assists, but is not authority.
```

Do not treat Edge Functions as a shortcut around tenant/company/corretor validation.

Do not use service_role in frontend.

Do not migrate LeadOps to Edge/BFF before a narrow contract is approved.

---

## Related follow-ups

Recommended next documents:

```text
docs/architecture/supabase-access-routing-matrix.md
docs/releases/pilot-production/2026-06-11-pilot-production-and-canary-rollout-plan.md
docs/security/evidence/2026-06-11_leadops_rpc_body_policy_real_validation.md
```

These are future documents and must not be assumed complete until created and reviewed.