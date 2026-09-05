# FECH.AI — STS-M2-04B3 — Remaining SECURITY DEFINER Routine Authority Classification

**Status:** `COMPLETE / ACCEPTED` — classification only  
**Decision date:** `2026-09-05`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Product Authority acceptance main:** `0333cea749dc33a6040955077afe67bd22c2fbe9`  
**SES evidence ref:** `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`

## 1. Product Authority decision

Product Authority accepted `STS-M2-04B3 CLASSIFICATION` as:

```text
COMPLETE / ACCEPTED
COVERAGE = 113 / 113
```

The accepted object is the completeness and correctness of the B3 classification record. This decision does not declare the current database-authority implementation target-compliant or safe.

Five current authority findings remain `BLOCKING`:

```text
031 gerenciar_lista(uuid,text,text)
036 get_dashboard_master()
047 get_stats_horario()
119 relatorio_fornecedor(uuid)
127 solicitar_lote_forcado(uuid)
```

Preserve:

```text
B3 CLASSIFICATION COMPLETE
!=
CURRENT DATABASE AUTHORITY SAFE

BLOCKING CURRENT AUTHORITY FINDING
!=
B3 CLASSIFICATION INCOMPLETE
```

## 2. Specialist provenance

Canonical specialist:

```text
SES — Backend & Data Platform Specialist
ARCHETYPE_ID = backend-data-platform-specialist
PROJECT_ROLE = backend_data
```

Canonical consolidated detailed matrix:

`docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv`

```text
canonical consolidated 113-row × 40-column matrix SHA-256 =
df2a76d34b07edc347f84acbb7c71bad71be61095a7e40919c869925cc0b31eb
```

The canonical CSV above is the recoverable final B3 classification surface. It is derived from the original specialist 113-row baseline plus the bounded final adjudication delta.

Historical external specialist provenance remains fingerprint-bound:

```text
initial specialist report SHA-256 =
b74d0f2d8b3655e0d04860743fe45ee54ecf234b8778a6f573e39ae9a4b39320

113-row × 40-column matrix CSV SHA-256 =
3abd2d09d4d17a0584a982c8fc6926a0266e4385883454a046f085f59f04a889

final five-row Master-Project adjudication delta SHA-256 =
4695593f7e3c5e4e72ecf415d8b0cc19e6cb9c93583e89504e522ac9e6297c59
```

The original specialist matrix is historical baseline evidence. The final adjudication delta supersedes only the five rows `031`, `036`, `047`, `119`, `127`, plus the aggregate totals affected by those corrections. The versioned canonical CSV above consolidates those two evidence layers into the final detailed `113 × 40` classification and is the current recoverable matrix for B3.

Final specialist verdict after the bounded delta:

```text
BACKEND_DATA_M2_04B3_REMAINING_ROUTINE_CLASSIFICATION =
READY_FOR_MASTER_PROJECT_ADJUDICATION
```

## 3. Exact B3 scope

The accepted M2-02 map contains `137 / 137` SECURITY DEFINER caller-provenance closure.

```text
137 SECURITY DEFINER
- 15 already classified in B2
- 9 SECURITY DEFINER trigger-provenance routines reserved for M2-04D
= 113 B3 routines
```

B2 excluded ordinals:

```text
001,002,008,016,026,051,090,091,099,113,114,118,121,122,134
```

M2-04D trigger-provenance excluded ordinals:

```text
011,012,013,014,015,030,075,111,130
```

Overload boundary:

```text
016 avaliar_lista(uuid,integer,text) = B2 / excluded
017 avaliar_lista(uuid,integer,text,uuid) = B3 / included
```

Live scope reconciliation reported:

```text
B3_SCOPE_DRIFT = NO
LIVE_RESOLVED = 113 / 113
BODY_REVIEWED = 113 / 113
ACL_REVIEWED = 113 / 113
CALLER_PROVENANCE_CONSUMED = 113 / 113
TARGET_CLASS_ASSIGNED = 113 / 113
MODE_DECISION_ASSIGNED = 113 / 113
PROOF_OBLIGATION_ASSIGNED = 113 / 113
```

## 4. Accepted aggregate classification

Authority classes:

```text
AUTHENTICATED_QUERY = 29
AUTHENTICATED_COMMAND = 15
PRIVILEGED_OPERATION = 41
SERVICE_ONLY_COMMAND = 2
DB_INTERNAL_HELPER = 26
ANONYMOUS_READ_API = 0
ANON_COMMAND_EXCEPTION = 0
TRIGGER_ONLY = 0
TOTAL = 113
```

Target security mode:

```text
TARGET DEFINER = 55
TARGET INVOKER = 2
TARGET MODE NOT_DETERMINED = 56
TOTAL = 113
```

DEFINER justification:

```text
PROVEN = 55
NOT_PROVEN = 5
NOT_DETERMINED = 51
NOT_REQUIRED = 2
TOTAL = 113
```

Other accepted aggregates:

```text
ACL CONTRADICTIONS = 29
OWNER RESIDUALS = 113
SEARCH_PATH SEMANTIC REVIEW = 113

APPSEC YES = 45
APPSEC CONDITIONAL = 39
APPSEC NOT_REQUIRED_FOR_THIS_CLASSIFICATION = 29

RUNTIME PROOF REQUIRED = 19
RUNTIME PROOF CONDITIONAL = 20
RUNTIME PROOF NO = 74
```

Current owner `postgres` and the presence of a search_path are observed AS-IS facts only. They are not target acceptance.

## 5. Final five-row adjudication

All five blocking objects remain `PRIVILEGED_OPERATION`, but their required privilege elevation is not proven. Therefore B1 does not permit a target `SECURITY DEFINER` decision for them.

Final target-mode decision:

```text
031 gerenciar_lista = NOT_DETERMINED
036 get_dashboard_master = NOT_DETERMINED
047 get_stats_horario = NOT_DETERMINED
119 relatorio_fornecedor = NOT_DETERMINED
127 solicitar_lote_forcado = NOT_DETERMINED

DEFINER_JUSTIFICATION_STATUS = NOT_PROVEN for all five
```

Exact reporting correction for ordinal `031`:

```text
live signature = public.gerenciar_lista(
  p_lista_id uuid,
  p_acao text,
  p_motivo text
)

PostgreSQL callable type identity remains (uuid,text,text).
```

Ordinal `127` side-effect correction:

```text
STATIC_WRITES = NO
SIDE_EFFECT_CLASS = TRANSITIVE_MUTATIVE

solicitar_lote_forcado(p_user_id)
→ solicitar_lote_core(p_user_id)
→ solicitar_lote(NULL)
```

The transitive path can mutate allocation state; calling ordinal 127 `READ_ONLY` is not accepted.

## 6. Blocking current authority findings

These findings remain blocking for target-compliant authority and downstream remediation/proof. They are not waived by B3 acceptance.

- `031 gerenciar_lista(uuid,text,text)`: APP caller/ACL contradiction plus tenant/object binding not proven on the privileged mutation path.
- `036 get_dashboard_master()`: gestor/root gate precedes global DEFINER reads; intended global versus tenant scope is not proven.
- `047 get_stats_horario()`: gestor/root gate precedes global lead-stat reads; tenant-gestor cross-tenant authority is not proven.
- `119 relatorio_fornecedor(uuid)`: supplied `p_lista_id` is not proven bound to the gestor tenant/list scope before privileged reads.
- `127 solicitar_lote_forcado(uuid)`: intended forced-user actor semantics are not proven by the transitive body contract.

## 7. Downstream dependencies

`56` target security-mode decisions remain deliberately `NOT_DETERMINED`. They depend on M2-04C evidence where caller sufficiency, direct table authority, RLS, FORCE RLS, USING/WITH CHECK or policy composition determines whether INVOKER authority is intentionally sufficient.

The 9 SECURITY DEFINER trigger-provenance routines excluded from B3 remain owned by M2-04D.

```text
B3 ACCEPTED != M2-04C AUTHORIZED
B3 ACCEPTED != M2-04D AUTHORIZED
CURRENT CONTRADICTION != AUTHORIZED REMEDIATION
```

## 8. Evidence and assurance boundary

```text
STATIC / LIVE CATALOG CLASSIFICATION != RUNTIME ASSURANCE
STRUCTURALLY OBSERVED CONTROL != CONTROL PROVEN EFFECTIVE AT RUNTIME

AppSec execution = NOT_PERFORMED
hostile-client runtime testing = NOT_PERFORMED
cross-tenant runtime assurance = NOT_PROVEN where identified
Security Go = NOT_GRANTED
```

## 9. Authority boundary

This acceptance authorizes no technical change.

```text
implementation = NOT_AUTHORIZED
SQL / DDL / DML = NOT_AUTHORIZED
migration = NOT_AUTHORIZED
GRANT / REVOKE / ALTER DEFAULT PRIVILEGES = NOT_AUTHORIZED
SECURITY DEFINER / INVOKER change = NOT_AUTHORIZED
owner / search_path change = NOT_AUTHORIZED
RLS / policy change = NOT_AUTHORIZED
Supabase / Auth mutation = NOT_AUTHORIZED
AppSec execution = NOT_AUTHORIZED
runtime hostile testing = NOT_AUTHORIZED
M2-04C execution = NOT_AUTHORIZED
M2-04D execution = NOT_AUTHORIZED
deploy = NOT_AUTHORIZED
Ready = NOT_AUTHORIZED
merge = NOT_AUTHORIZED
Security Go = NOT_GRANTED
```
