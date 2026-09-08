# FECH.AI — STS-M3-04-01 — PME Message Usage RPC-Only Acceptance

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Date:** 2026-09-08  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`

## 1. Product Authority decision

Product Authority formally accepts:

~~~text
STS-M3-04-01 =
COMPLETE / ACCEPTED WITH RESIDUALS
~~~

This acceptance closes only the bounded first implementation slice of STS-M3-04. STS-M3-04 remains active; no next slice is authorized by this decision.

## 2. Canonical GitHub provenance

~~~text
PR = #205
final approved head = 07f5dad3f805e319a0303e664752a2da7d0e3dfe
PR state = MERGED / CLOSED
merge commit = 1402395e708f69b0935ab2ba45489f717943b8b2
canonical main at acceptance = 1402395e708f69b0935ab2ba45489f717943b8b2

migration =
supabase/migrations/20260908233000_sts_m3_04_01_pme_message_usage_rpc_only.sql

migration blob =
9e9e4aec6273624695638071f2d717f99d7a3586

catalog smoke =
supabase/tests/pme/usage-tracking/16a_smoke_pme_usage_tracking_catalogo_rls_grants_readonly.sql

smoke blob =
b8a0f75cc60a17e048d19b37de45ce4a29bdfba5
~~~

## 3. Applied Supabase evidence

~~~text
project = uobxxgzshrmbtjfdolxd
project name = Discador-MesaCliente
apply result = SUCCESS
~~~

Post-apply catalog evidence:

~~~text
authenticated SELECT on public.pme_message_usage = TRUE
authenticated INSERT = FALSE
authenticated UPDATE = FALSE
authenticated DELETE = FALSE

anon INSERT/UPDATE/DELETE = FALSE
PUBLIC INSERT/UPDATE/DELETE = FALSE

direct write policy count on pme_message_usage = 0
remaining pme_message_usage policy = SELECT only

authenticated EXECUTE on pme_registrar_message_usage(uuid,jsonb) = TRUE
anon EXECUTE = FALSE
PUBLIC EXECUTE = FALSE
service_role EXECUTE = TRUE

RPC SECURITY DEFINER = TRUE
RPC search_path = public, pg_temp
~~~

## 4. Post-apply smoke

The canonical read-only 16A smoke returned:

~~~text
00_tabelas_pme_catalogo_rls = PASS
01_funcoes_pme_catalogo_grants = PASS
02_policies_pme_catalogo = PASS
03_grants_tabelas_sem_anon_public = PASS
04_grants_authenticated_exatos = PASS
05_rpc_only_pme_message_usage = PASS
06_constraints_minimas = PASS
99_interpretacao_operacional = INFO
~~~

The same test had correctly failed blocks 02/04/05 before application, providing a negative control for the old direct-write contract.

## 5. Applied contract

Accepted result:

~~~text
authenticated direct write on pme_message_usage = REMOVED
authenticated direct read = PRESERVED
authenticated write boundary = pme_registrar_message_usage(uuid,jsonb)
anon/public direct write = DENIED
anon/public RPC execute = DENIED
~~~

No RPC body change, frontend change, service-role change or production data mutation was part of this slice.

## 6. Accepted residuals

### RR-01 — Independent runtime assurance

~~~text
hostile-client / cross-tenant active effectiveness retest = NOT_PERFORMED
independent AppSec effectiveness PASS = NOT_PERFORMED
~~~

Catalog and smoke evidence prove the bounded database authorization state; they do not replace independent hostile-client assurance.

### RR-02 — RPC individual lead authority

The existing `pme_registrar_message_usage(uuid,jsonb)` boundary validates company/consumption eligibility and server-derived authority, but individual lead ownership/assignment hardening remains outside this slice.

### RR-03 — Migration ledger provenance

Supabase recorded:

~~~text
version = 20260908184747
name = sts_m3_04_01_pme_message_usage_rpc_only
~~~

The canonical GitHub filename prefix is:

~~~text
20260908233000
~~~

This difference is preserved as an accepted provenance residual. The same apply-migration timestamp behavior exists on previously applied FECH.AI migrations; no ledger rewrite is authorized or required by this acceptance.

### RR-04 — Remaining STS-M3-04 surface

This slice does not close the broader direct-DML reduction task. Other previously inventoried direct-write surfaces remain for later bounded slices.

### RR-05 — Security Go

~~~text
Security Go = NOT_GRANTED
broad paid commercialization = not authorized by this acceptance
~~~

## 7. Rollback

The versioned migration contains the bounded manual rollback:

~~~text
recreate pme_message_usage_insert
restore authenticated INSERT grant
~~~

Rollback execution remains a separate Product Authority authorization.

## 8. Next gate

~~~text
STS-M3-04 = ACTIVE
STS-M3-04-01 = COMPLETE / ACCEPTED WITH RESIDUALS

next material slice candidate =
pme_lead_message_state authenticated direct INSERT/UPDATE reduction

next slice authorization =
NOT_GRANTED
~~~

Any next implementation slice requires fresh live bootstrap, exact scope, rollback, tests, evidence and separate Product Authority authorization.
