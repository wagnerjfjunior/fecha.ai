# FECH.AI — STS-M2-04B2 — High-Risk Routine Authority Classification — Durable Accepted Evidence

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Decision date:** `2026-09-05`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Decision/base FECH.AI main:** `ca77d81c3d2a6209536664128bda209996a7f423`  
**SES continuity ref:** `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`  
**Security Go:** `NOT_GRANTED`

## 1. Decision and provenance

Product Authority accepted `STS-M2-04B2 — High-Risk Routine Authority Classification` as:

```text
COMPLETE / ACCEPTED WITH RESIDUALS
```

The acceptance is bounded to exactly 15 high-risk routines and preserves:

```text
SPECIALIST RESULT != PRODUCT AUTHORITY DECISION
STATIC/CATALOG CLASSIFICATION != RUNTIME ASSURANCE
CURRENT CONTRADICTION != AUTHORIZED REMEDIATION
```

Backend/Data evidence:

```text
PACKET_VERSION:
manual-specialist-handoff-v0.3

PACKET_ID:
FECHAI-STS-M2-04B2-HIGH-RISK-ROUTINE-AUTHORITY-CLASSIFICATION

SPECIALIST:
SES — Backend & Data Platform Specialist

SPECIALIST VERDICT:
BACKEND_DATA_M2_04B2_HIGH_RISK_CLASSIFICATION =
READY_FOR_MASTER_PROJECT_ADJUDICATION

USER-SUPPLIED SPECIALIST RESULT SHA-256:
36f90006d772404cd8d2fd297a2a70ab2ff452f8b1b17491a734f7cff68cb2ad
```

The B1 durable reconciliation was merged via PR #181 and is canonical on main `0b4868ef80e69bab5f0397c29af4474fb097e739`. This B2 reconciliation preserves that canonical B1 state and does not rewrite B1.

## 2. Accepted B1 policy inherited

```text
SECURITY DEFINER =
PRIVILEGED EXCEPTION

SECURITY INVOKER =
PREFERRED DEFAULT WHEN CALLER AUTHORITY
IS DELIBERATELY SUFFICIENT
```

Routine authority is one coherent contract:

```text
ROUTINE CLASS
+ CANONICAL CALLER
+ EXECUTE ACL
+ SECURITY MODE
+ OWNER AUTHORITY
+ ACTOR / TENANT / ROLE DERIVATION
+ SIDE EFFECTS
+ TRANSITIVE AUTHORITY
+ PROOF OBLIGATION
```

## 3. Exact 15-routine scope

### Group A — anon EXECUTE + actual DML
1. `alterar_plano_empresa_root(uuid,uuid,text,timestamp with time zone)`
2. `atualizar_status_empresa_root(uuid,boolean,text)`
3. `importar_mesa_cliente_disponibilidade_oficial(uuid,text,text,jsonb)`
4. `mesa_cliente_upsert_faixas_premio(uuid,uuid,jsonb)`
5. `mesa_cliente_upsert_politica_financeira(uuid,uuid,date,date,date,numeric,numeric,numeric,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,text)`
6. `registrar_upload_arquivo_mesa(uuid,uuid,text,text,text,text)`
7. `salvar_mesa_cliente_desconto_politica(uuid,uuid,numeric,numeric,numeric,numeric,text,boolean)`
8. `salvar_mesa_cliente_enriquecimento(uuid,text,integer,integer,integer,text,text,text,text)`

### Group B — DB internal authority
9. `acquire_lote_lock(uuid,uuid)`

### Group C — caller × ACL contradictions
10. `avaliar_lista(uuid,integer,text)`
11. `trilha_lead(uuid)`

### Group D — mutative + no-versioned-caller / lifecycle ambiguity
12. `dispensar_lembrete(uuid)`
13. `mover_funil_batch(uuid[],uuid,text)`
14. `redefinir_senha_corretor(uuid,text)`
15. `registrar_audit_log(uuid,text,text,uuid,jsonb,jsonb)`

## 4. Accepted classification results

### Group A
```text
ANON_COMMAND_EXCEPTION proven = 0 / 8
current anon EXECUTE = 8 / 8
target justification for anon EXECUTE = NOT_PROVEN for 8 / 8
```

Accepted target classes include:
- root plan/status operations and official Mesa availability import → `PRIVILEGED_OPERATION`;
- upload registration and unit enrichment → `AUTHENTICATED_COMMAND`;
- A4/A5/A7 remain privileged-operation candidates if retained, with lifecycle/caller evidence required.

### Group B
`acquire_lote_lock(uuid,uuid)`:

```text
TARGET CLASS = DB_INTERNAL_HELPER
canonical parent = solicitar_lote(uuid)
current direct reachability = PUBLIC + anon + authenticated + service_role
target direct client reachability = not supported
```

Current reachability is target-contradictory. No REVOKE or ALTER FUNCTION is authorized.

### Group C
`avaliar_lista(uuid,integer,text)`:

```text
canonical authenticated app caller = YES
authenticated EXECUTE = NO
service_role EXECUTE = YES
target class = AUTHENTICATED_COMMAND
caller × ACL = CONTRADICTORY
```

`trilha_lead(uuid)`:

```text
canonical authenticated app caller = YES
authenticated EXECUTE = NO
service_role EXECUTE = YES
target class = AUTHENTICATED_QUERY
tenant/object authority = NOT SUFFICIENTLY PROVEN
caller × ACL = CONTRADICTORY
```

```text
CALLER FOUND != EXECUTE SHOULD BE ADDED
```

### Group D
- `dispensar_lembrete` → `UNUSED_CANDIDATE`; retained semantics `AUTHENTICATED_COMMAND`;
- `mover_funil_batch` → `UNUSED_CANDIDATE`; retained semantics `AUTHENTICATED_COMMAND`;
- `redefinir_senha_corretor` → `LEGACY_SUPPORTED`; `PRIVILEGED_OPERATION` if retained;
- `registrar_audit_log` → `UNUSED_CANDIDATE`; `SERVICE_ONLY_COMMAND` candidate only if a trusted service contract is proven.

Preserve:

```text
NO_VERSIONED_CALLER != RUNTIME UNUSED
UNUSED_CANDIDATE != PROVEN UNUSED
UNUSED_CANDIDATE != AUTHORIZED TO REVOKE
service_role EXECUTE != SERVICE_ONLY PROVEN
```

## 5. Accepted bounded live/catalog anchors

```text
15 / 15 = SECURITY DEFINER
15 / 15 owner = postgres
15 / 15 proconfig includes search_path=public
8 / 8 Group A anon EXECUTE = YES
```

Specific accepted ACL facts:

```text
acquire_lote_lock(uuid,uuid):
PUBLIC = YES
anon = YES
authenticated = YES
service_role = YES

avaliar_lista(uuid,integer,text):
authenticated = NO
service_role = YES

trilha_lead(uuid):
authenticated = NO
service_role = YES
```

These facts do not prove runtime exploitability or effective security.

## 6. Residuals and downstream boundaries

Open residuals, not waived:

```text
hostile-client runtime assurance = NOT_PROVEN
cross-tenant runtime negatives = NOT_PROVEN where applicable
Group-D actual runtime use/nonuse = NOT_PROVEN
A4/A5/A7 canonical caller = NOT_PROVEN
majority DEFINER justification = NOT_PROVEN / NOT_DETERMINED where classified
search_path target compliance = NOT_DETERMINED
owner target compliance = CONDITIONAL
M2-04C RLS/direct-DML authority composition = NOT YET DECIDED
M2-04D trigger authority = NOT DECIDED BY B2
independent AppSec assurance = NOT PERFORMED
```

M2-04C owns detailed RLS/direct-DML/USING/WITH CHECK/policy composition.  
M2-04D owns trigger/trigger-helper authority.  
B2 produced contract-map inputs for M2-05 but does not complete M2-05.

## 7. Authority boundary

```text
NO implementation
NO SQL / DDL / DML
NO migration
NO GRANT / REVOKE / ALTER DEFAULT PRIVILEGES
NO ALTER FUNCTION
NO SECURITY DEFINER/INVOKER change
NO owner change
NO search_path change
NO RLS/policy change
NO Supabase/Auth mutation
NO runtime hostile testing
NO AppSec testing
NO B3 execution
NO M2-04C execution
NO M2-04D execution
NO deploy
NO Security Go
```

```text
STS-M2-04B2 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-04 = IN PROGRESS / TARGET-POLICY DESIGN
Security Go = NOT_GRANTED
```
