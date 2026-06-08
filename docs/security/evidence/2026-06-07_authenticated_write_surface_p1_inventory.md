# FECH.AI / Supabase - Authenticated Write Surface P1 Inventory

Date: 2026-06-07
Status: READ-ONLY INVENTORY / NO PRODUCTION CHANGE
Related checkpoint: PR #66 - Phase 1 post-merge checkpoint
Current PR: PR #67 - Authenticated write-surface P1 inventory
Recommended next phase: Frontend direct-DML inventory and RPC/grants review

---

## 1. Summary

This document maps the remaining P1 write surface currently associated with the `authenticated` application role on selected FECH.AI Supabase/PostgreSQL tables.

This is a read-only security inventory.

This document does not change database grants, RLS policies, functions, migrations, frontend code, MesaCliente parser, MesaCliente financial engine, Worker, Make, n8n, Vercel, production infrastructure or business rules.

The purpose is to identify where `authenticated` still has direct table-level write privileges and to prepare safe follow-up hardening without breaking existing CRM, Discador, Dashboard or MesaCliente flows.

This PR must not be interpreted as a production security approval. It only records the next risk area to be reviewed.

---

## 2. Scope

Tables in scope:

| Table                                         |  Authenticated write surface |                   Priority |
| --------------------------------------------- | ---------------------------: | -------------------------: |
| `public.corretores`                           |                     `UPDATE` | P1 / possible P0 candidate |
| `public.leads`                                |           `INSERT`, `UPDATE` |                         P1 |
| `public.lotes`                                |                     `UPDATE` |                         P1 |
| `public.times`                                |                     `UPDATE` |                         P1 |
| `public.lista_visibilidade`                   | `INSERT`, `UPDATE`, `DELETE` |                         P1 |
| `public.mesa_cliente_unidade_enriquecimentos` | `INSERT`, `UPDATE`, `DELETE` | P1 / MesaCliente-sensitive |

Out of scope for this PR:

* No `REVOKE`.
* No `GRANT`.
* No RLS policy change.
* No FORCE RLS change.
* No RPC/function change.
* No migration execution.
* No Supabase `db push`.
* No frontend change.
* No MesaCliente parser change.
* No MesaCliente financial engine change.
* No Worker/Make/n8n change.
* No Vercel/production change.
* No data mutation.
* No customer-visible behavior change.

---

## 3. Security principle

Authenticated user is not automatically authorized user.

Any sensitive write path must validate:

* `auth.uid()`;
* active user status;
* tenant/company binding;
* team/ownership when applicable;
* role/profile/permission;
* payload allowlist;
* business rule scope;
* auditability.

Frontend-provided `tenant_id`, `empresa_id`, `perfil`, `role`, `time_id`, ownership or business status must not be treated as sovereign authority.

The FECH.AI architecture principle remains:

```text
Frontend displays and requests.
Database/RPC validates and decides.
AI assists, but is never permission authority.
```

---

## 4. Method

This inventory is based on the post-Phase-1 security review track and focuses on the remaining P1 direct write surface for the `authenticated` role.

The review classifies risk by considering:

* table purpose;
* likely business impact;
* multi-tenant exposure risk;
* whether the table behaves like identity, ACL, CRM, operational or MesaCliente data;
* whether direct DML may conflict with the target architecture;
* whether future hardening may break existing frontend or RPC flows if done blindly.

This document intentionally avoids raw production evidence, real user identifiers, real company identifiers, real lead data, real e-mails, real UUIDs, tokens, credentials or sensitive payloads.

---

## 5. Findings by table

### 5.1 `public.corretores`

Observed write surface:

| Control                            | Observed value |
| ---------------------------------- | -------------- |
| RLS expected                       | enabled        |
| FORCE RLS expected                 | enabled        |
| Authenticated direct write surface | `UPDATE`       |

Risk classification:

```text
P1 / possible P0 candidate
```

Reason:

`public.corretores` appears to be an identity, authorization and operational governance table. This type of table may contain fields related to:

* user binding;
* e-mail/contact identity;
* active/inactive status;
* ability to receive leads;
* manager/admin flags;
* password-change status or onboarding state;
* company binding;
* team binding;
* local admin flag;
* role/profile;
* operational permissions.

Security concern:

If a normal authenticated user can update their own row through direct table DML and a permissive policy, there may be risk of unauthorized changes to role, company, team, active status, receiving status or operational permissions.

The actual exploitability is not asserted in this document. It depends on the real RLS policy body, helper function behavior, frontend usage and RPC coverage.

Recommended next validation:

* Search frontend for direct updates to `corretores`.
* Identify whether profile/self-service updates use direct DML or RPC.
* Identify which fields are allowed for normal users.
* Review helper functions used by RLS policies.
* Confirm whether admin/manager updates are already behind controlled RPCs.
* Prepare negative tests before any grant change.

Do not revoke direct `UPDATE` yet without confirming frontend and RPC dependencies.

---

### 5.2 `public.leads`

Observed write surface:

| Control                            | Observed value     |
| ---------------------------------- | ------------------ |
| RLS expected                       | enabled            |
| FORCE RLS expected                 | enabled            |
| Authenticated direct write surface | `INSERT`, `UPDATE` |

Risk classification:

```text
P1
```

Reason:

`public.leads` affects CRM, Discador, personal data, ownership, funnel movement, feedback, list/lote relationship and commercial history.

Potential sensitive areas:

* personal data;
* phone/e-mail/contact data;
* source/campaign data;
* assignment to broker;
* company/list/lote relationship;
* funnel/status;
* feedback;
* contact history;
* operational notes.

Security concern:

Direct `INSERT` and `UPDATE` on `leads` can be acceptable only if RLS policies strictly enforce company/tenant scope, ownership and role rules.

If a policy allows updates based only on broker ownership without explicit company/tenant validation, it may still be safe if the helper function is proven to be company-scoped and immutable from the user's perspective. That proof must come from function body review and negative tests, not from assumption.

Recommended next validation:

* Search frontend for direct `.from('leads').insert(...)`.
* Search frontend for direct `.from('leads').update(...)`.
* Identify all RPCs that mutate leads.
* Confirm whether imports, feedback, status updates and assignment flows are direct DML or RPC-based.
* Test cross-company and cross-tenant update attempts.
* Test authenticated user without ownership.
* Test invalid payloads attempting to change ownership/company fields.

Do not remove direct writes before confirming CRM and Discador operational paths.

---

### 5.3 `public.lotes`

Observed write surface:

| Control                            | Observed value |
| ---------------------------------- | -------------- |
| RLS expected                       | enabled        |
| FORCE RLS expected                 | enabled        |
| Authenticated direct write surface | `UPDATE`       |

Risk classification:

```text
P1
```

Reason:

`public.lotes` affects lot lifecycle, lead distribution, broker workload, CRM/Discador operation, productivity control and potentially manager dashboards.

Potential sensitive areas:

* lot status;
* responsible broker/team;
* active/inactive flow;
* distribution state;
* partial closing/devolution;
* productivity and reporting metrics.

Candidate write-paths to validate:

* lot distribution;
* lot return/devolution;
* partial closing;
* lot evaluation;
* lot status update;
* reassignment.

Security concern:

If direct `UPDATE` is still required by frontend, revoking it without preparation may break CRM/Discador flows. If RPCs already cover the write paths, direct update privilege may be reducible in a later hardening PR.

Recommended next validation:

* Search frontend for direct updates to `lotes`.
* Review RPCs related to lot distribution, devolution, partial closing and evaluation.
* Confirm whether updates validate company/team/manager/broker authority.
* Prepare positive and negative tests before any change.

---

### 5.4 `public.times`

Observed write surface:

| Control                            | Observed value |
| ---------------------------------- | -------------- |
| RLS expected                       | enabled        |
| FORCE RLS expected                 | enabled        |
| Authenticated direct write surface | `UPDATE`       |

Risk classification:

```text
P1
```

Reason:

`public.times` affects team governance, manager scope, company boundaries and operational segmentation.

Potential sensitive areas:

* team name/status;
* company binding;
* manager scope;
* active/inactive status;
* dashboard segmentation;
* access grouping.

Security concern:

A team table is part of the authorization and operational segmentation model. Direct update must be restricted to authorized roles and must not allow cross-company modification.

Recommended next validation:

* Search frontend for direct updates to `times`.
* Review admin/manager flows touching teams.
* Confirm whether team updates are already protected by RPCs.
* Validate cross-company update attempts.
* Validate non-manager update attempts.

---

### 5.5 `public.lista_visibilidade`

Observed write surface:

| Control                            | Observed value               |
| ---------------------------------- | ---------------------------- |
| RLS expected                       | enabled                      |
| FORCE RLS expected                 | enabled                      |
| Authenticated direct write surface | `INSERT`, `UPDATE`, `DELETE` |

Risk classification:

```text
P1 / high-priority hardening candidate
```

Reason:

`public.lista_visibilidade` appears to control list visibility and operational access. Functionally, this behaves like an ACL surface.

Potential sensitive areas:

* who can see a list;
* which team/company can access a list;
* visibility expansion;
* visibility removal;
* operational lead access;
* manager/broker scope.

Security concern:

Direct DML on ACL-like tables is dangerous in a multi-tenant SaaS if policies are incomplete. Unauthorized visibility changes may expose leads, lists or operational data to users who should not access them.

Candidate RPC to validate:

```text
gerenciar_visibilidade_lista
```

Recommended next validation:

* Confirm whether all list visibility changes can be performed through a strict RPC.
* Review the RPC body and grants.
* Confirm actor role validation.
* Confirm target company/list scope validation.
* Confirm target team/user scope validation.
* Search frontend for direct insert/update/delete on `lista_visibilidade`.
* Prepare negative tests for unauthorized visibility expansion and deletion.

Do not apply broad revocation before confirming whether frontend still uses direct DML.

---

### 5.6 `public.mesa_cliente_unidade_enriquecimentos`

Observed write surface:

| Control                            | Observed value               |
| ---------------------------------- | ---------------------------- |
| RLS expected                       | enabled                      |
| FORCE RLS expected                 | requires validation          |
| Authenticated direct write surface | `INSERT`, `UPDATE`, `DELETE` |

Risk classification:

```text
P1 / MesaCliente-sensitive
```

Reason:

This table may affect MesaCliente unit enrichment data and potentially commercial information shown to brokers or used in client-facing proposal context.

Potential sensitive areas:

* unit notes;
* enrichment attributes;
* commercial presentation data;
* project/unit metadata;
* client-safe or internal-only distinction;
* proposal context;
* MesaCliente display behavior.

Security concern:

MesaCliente is a critical commercial module. Any table that can affect unit enrichment or proposal presentation must be treated carefully. Direct DML may be acceptable only if policies strictly validate company/tenant scope and allowed fields.

Important nuance:

If RLS is enabled and no applicable policy exists, direct writes may already be blocked in practice despite open grants. However, open grants still represent unnecessary attack surface and should be reviewed carefully in a future controlled PR.

Recommended next validation:

* Search frontend for direct insert/update/delete on this table.
* Confirm whether MesaCliente currently uses this table in production flows.
* Confirm whether data is broker-only, internal-only or client-visible.
* Review whether FORCE RLS should be enabled in a later migration.
* Do not alter MesaCliente parser, engine, proposal flow or financial rules in this PR.
* Prepare MesaCliente regression tests before any hardening.

---

## 6. Risk ranking

| Rank | Object                                        | Reason                                                        |
| ---: | --------------------------------------------- | ------------------------------------------------------------- |
|    1 | `public.corretores`                           | identity, role, company, team and operational permission risk |
|    2 | `public.lista_visibilidade`                   | ACL-like visibility control                                   |
|    3 | `public.mesa_cliente_unidade_enriquecimentos` | MesaCliente/client-facing commercial data surface             |
|    4 | `public.leads`                                | CRM/Discador, personal data and ownership/funnel risk         |
|    5 | `public.lotes`                                | lead distribution and lot lifecycle risk                      |
|    6 | `public.times`                                | team governance and company/team segmentation risk            |

This ranking is directional and must be confirmed after frontend direct-DML mapping, RPC body review and negative tests.

---

## 7. Recommended hardening order

Recommended next PRs:

1. Frontend direct-DML inventory for P1 tables.
2. RPC/grants inventory for P1 tables.
3. Body review of P1 RPCs and helper functions.
4. Hardening plan for `public.corretores` direct `UPDATE`.
5. Hardening plan for `public.lista_visibilidade`.
6. Hardening plan for `public.mesa_cliente_unidade_enriquecimentos`.
7. CRM/Discador negative tests.
8. Dashboard aggregation leakage tests.
9. MVP internal security checkpoint.

---

## 8. Required tests before future hardening

Before any future migration, grant change, policy change or RPC change, collect evidence for:

### 8.1 Positive authorized test

Expected result:

```text
Authorized user can perform the intended business operation.
```

### 8.2 Unauthenticated negative test

Expected result:

```text
Unauthenticated request is blocked.
```

### 8.3 Authenticated without permission negative test

Expected result:

```text
Authenticated user without the required role/profile/ownership is blocked.
```

### 8.4 Cross-tenant / cross-company negative test

Expected result:

```text
User from Company A cannot read or mutate Company B data.
```

### 8.5 Invalid payload test

Expected result:

```text
Payload attempting to change protected fields is rejected or ignored.
```

Examples of protected fields to validate where applicable:

* company identifier;
* tenant identifier;
* role/profile;
* admin/manager flag;
* active/inactive status;
* team binding;
* broker ownership;
* visibility scope;
* commercial rule fields.

### 8.6 Frontend regression test

Expected result:

```text
Existing CRM, Discador, Dashboard and MesaCliente flows continue working after the future hardening change.
```

### 8.7 RPC regression test

Expected result:

```text
RPC-based write paths remain operational and enforce server-side authorization.
```

### 8.8 Rollback validation

Expected result:

```text
Rollback path is clear before applying any production-sensitive change.
```

---

## 9. Frontend inventory targets for next PR

The next frontend inventory should search for direct Supabase DML touching:

```text
.from('corretores').update
.from("corretores").update

.from('leads').insert
.from("leads").insert
.from('leads').update
.from("leads").update

.from('lotes').update
.from("lotes").update

.from('times').update
.from("times").update

.from('lista_visibilidade').insert
.from("lista_visibilidade").insert
.from('lista_visibilidade').update
.from("lista_visibilidade").update
.from('lista_visibilidade').delete
.from("lista_visibilidade").delete

.from('mesa_cliente_unidade_enriquecimentos').insert
.from("mesa_cliente_unidade_enriquecimentos").insert
.from('mesa_cliente_unidade_enriquecimentos').update
.from("mesa_cliente_unidade_enriquecimentos").update
.from('mesa_cliente_unidade_enriquecimentos').delete
.from("mesa_cliente_unidade_enriquecimentos").delete
```

Also search for dynamic wrappers or abstraction layers that may hide table names.

Examples:

```text
supabase.from(tableName)
supabase.from(resource)
db.from(...)
client.from(...)
```

The next PR should map:

* file path;
* component/function;
* operation type;
* table name;
* business flow;
* whether it can be replaced by existing RPC;
* whether it needs new RPC;
* whether it is safe read/write;
* whether it is P0/P1/P2.

---

## 10. RPC/grants inventory targets for later PR

The later RPC/grants inventory should map:

* functions touching P1 tables;
* grants for `anon`, `authenticated` and `public`;
* SECURITY DEFINER vs SECURITY INVOKER;
* function owner;
* search_path;
* validation of `auth.uid()`;
* validation of active user;
* validation of company/tenant;
* validation of role/profile;
* touched tables;
* DML operations;
* whether the function can replace direct frontend DML.

Candidate areas:

```text
corretores profile/admin updates
lead insert/update/assignment/status/feedback
lot distribution/devolution/closing/evaluation
team update/admin management
list visibility management
MesaCliente unit enrichment
```

---

## 11. Rollback principle for future hardening

This PR has no rollback requirement beyond reverting the documentation commit.

For future technical PRs, rollback must be defined before merge.

Possible rollback options may include:

* revert PR;
* restore previous grant;
* restore previous policy;
* restore previous function definition;
* re-enable previous RPC behavior;
* feature flag;
* frontend rollback;
* Vercel rollback;
* database migration rollback script.

If a future migration changes production authorization behavior, rollback cannot be treated as a simple frontend revert.

---

## 12. Explicit non-claims

This document does not claim the platform is production-secure.

This document does not prove that direct writes are currently exploitable.

This document does not prove that RLS policies are unsafe.

This document does not prove that RLS policies are safe.

This document does not authorize broad revocation of grants.

This document does not authorize Supabase migration execution.

This document does not replace body review of policies, RPCs, helper functions or frontend usage.

This document does not alter MesaCliente parser, financial engine, proposal flow, client-safe rules or commercial policy.

This document only records the current P1 authenticated write-surface that requires controlled follow-up.

---

## 13. Acceptance criteria for this PR

This PR is acceptable only if:

* it is documentation-only;
* it creates or updates only Markdown evidence under `docs/security/evidence/`;
* it contains no migration;
* it contains no executable SQL;
* it contains no secrets;
* it contains no real e-mail address;
* it contains no real UUID or user/company/broker identifiers;
* it contains no token, credential or private key;
* it does not modify frontend;
* it does not modify parser;
* it does not modify MesaCliente engine;
* it does not modify Worker, Make or n8n;
* it does not modify Vercel settings;
* it does not modify Supabase;
* it does not assert full production readiness;
* it clearly defines next steps and limits.

---

## 14. Final conclusion

The P1 authenticated write surface remains a relevant security hardening area for FECH.AI.

The highest-risk objects to review next are:

1. `public.corretores`;
2. `public.lista_visibilidade`;
3. `public.mesa_cliente_unidade_enriquecimentos`;
4. `public.leads`;
5. `public.lotes`;
6. `public.times`.

The next safe action is not to revoke privileges immediately.

The next safe action is to map frontend direct-DML usage and RPC write-path coverage first, then apply small, controlled hardening PRs with positive tests, negative tests, cross-tenant tests, rollback and changelog.
