# FECH.AI — STS-M2-04B3 — Remaining SECURITY DEFINER Routine Authority Classification

**Status:** `COMPLETE / ACCEPTED` — revised DEF55 adjudication / classification only  
**Decision date:** `2026-09-05`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Product Authority acceptance main:** `0333cea749dc33a6040955077afe67bd22c2fbe9`  
**SES evidence ref:** `a31e10cc3f0d1278c53c49e38151854d36ee9f3e`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`


## 1. Product Authority decision

Product Authority accepted the revised `STS-M2-04B3 / DEF55` adjudication after the 55/55 GitHub-provenance and live-body reconstruction.

```text
STS-M2-04B3 CLASSIFICATION = COMPLETE / ACCEPTED
COVERAGE = 113 / 113

TARGET DEFINER = 52
TARGET INVOKER = 4
TARGET MODE NOT_DETERMINED = 57

PROVEN_BY_BODY_CONTRACT = 52
NOT_PROVEN = 6
NOT_DETERMINED = 51
NOT_REQUIRED = 4
```

The accepted object remains classification and target-policy evidence. It does not declare the current database implementation target-compliant or grant Security Go.

Exactly six current authority findings remain `BLOCKING`:

```text
004 aprovar_rejeitar_mesa(uuid,text,text)
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

Canonical specialist lineage remains:

```text
SES — Backend & Data Platform Specialist
ARCHETYPE_ID = backend-data-platform-specialist
PROJECT_ROLE = backend_data
```

The revised DEF55 adjudication additionally consumed the 55/55 provenance reconstruction across current GitHub code, PR/commit history, migrations, rollbacks, tests, security evidence, callers and live-body evidence already captured by STS-M2-02.

Canonical consolidated detailed matrix:

`docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv`

```text
current canonical 113-row × 40-column matrix SHA-256 =
e609f4fa3bc6d21b8c75d85bd2a4a3409e9ece8b3c4d66ffdb5e52055052a61d
```

Historical provenance remains retained:

```text
initial specialist report SHA-256 =
b74d0f2d8b3655e0d04860743fe45ee54ecf234b8778a6f573e39ae9a4b39320

original specialist 113-row × 40-column baseline SHA-256 =
3abd2d09d4d17a0584a982c8fc6926a0266e4385883454a046f085f59f04a889

first consolidated post-five-row-adjudication CSV SHA-256 =
df2a76d34b07edc347f84acbb7c71bad71be61095a7e40919c869925cc0b31eb

final five-row Master-Project adjudication delta SHA-256 =
4695593f7e3c5e4e72ecf415d8b0cc19e6cb9c93583e89504e522ac9e6297c59
```

The current canonical CSV supersedes the earlier consolidated matrix for the revised DEF55 decision. Material revised rows are the 52 routine-specific DEFINER justifications plus ordinals `004`, `052`, `106`, `126` and identity-signature corrections for `021`, `022`, `028`, `032`.

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

Authority classes remain:

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

Revised target security mode:

```text
TARGET DEFINER = 52
TARGET INVOKER = 4
TARGET MODE NOT_DETERMINED = 57
TOTAL = 113
```

Revised DEFINER justification:

```text
PROVEN_BY_BODY_CONTRACT = 52
NOT_PROVEN = 6
NOT_DETERMINED = 51
NOT_REQUIRED = 4
TOTAL = 113
```

Other reconciled aggregates:

```text
ACL CONTRADICTIONS = 29
OWNER RESIDUALS = 113
SEARCH_PATH SEMANTIC REVIEW = 113

APPSEC YES = 45
APPSEC CONDITIONAL = 39
APPSEC NOT_REQUIRED_FOR_THIS_CLASSIFICATION = 29

RUNTIME PROOF REQUIRED = 20
RUNTIME PROOF CONDITIONAL = 20
RUNTIME PROOF NO = 73
```

Current owner `postgres` and the presence of a search_path are observed AS-IS facts only. They are not target acceptance.


## 5. Revised DEF55 adjudication

The 55/55 reconstruction replaced the generic elevation sentence previously copied across the target-DEFINER rows. Each of the 52 accepted target-DEFINER rows now states the protected object/operation, the exact elevated authority required, and why direct caller authority is deliberately insufficient.

Specific accepted corrections:

```text
004 aprovar_rejeitar_mesa
  TARGET_SECURITY_MODE = NOT_DETERMINED
  DEFINER_JUSTIFICATION_STATUS = NOT_PROVEN
  FINDING_CLASS = BLOCKING

052 importar_mesa_cliente_json_admin
  TARGET_SECURITY_MODE = INVOKER
  STATIC_WRITES = NO
  SIDE_EFFECT_CLASS = TRANSITIVE_MUTATIVE
  privileged persistence remains in importar_mesa_cliente_parser_resultado

106 platform_health_center_v1
  TARGET_SECURITY_MODE = INVOKER
  no local privilege elevation
  authority remains in health callees

126 solicitar_lote_core
  SIDE_EFFECT_CLASS = TRANSITIVE_MUTATIVE
  RUNTIME_ASSURANCE_REQUIRED = YES
```

Accepted live identity-signature corrections:

```text
021 public.criar_lista(p_nome_fornecedor text, p_nome_arquivo text, p_escopo text)

022 public.criar_mesa_simulacao(
      p_empresa_id uuid,
      p_empreendimento_id uuid,
      p_unidade_id uuid,
      p_lead_id uuid,
      p_cliente_nome text,
      p_valor_total numeric,
      p_meta_obra_pct integer,
      p_tabela_provisoria boolean,
      p_fluxo_json jsonb
    )

028 public.encerrar_lote_parcial(
      p_lote_id uuid,
      p_nota integer,
      p_comentario text,
      p_motivo text
    )

032 public.gerenciar_visibilidade_lista(p_lista_id uuid, p_targets jsonb)
```

The previously accepted corrections for `031`, `036`, `047`, `119` and `127` remain unchanged.


## 6. Blocking current authority findings

These findings remain blocking for target-compliant authority and downstream remediation/proof. They are not waived by B3 acceptance.

- `004 aprovar_rejeitar_mesa(uuid,text,text)`: gestor-gated privileged UPDATE is not proven tenant/ownership-bound for `p_simulacao_id`.
- `031 gerenciar_lista(uuid,text,text)`: APP caller/ACL contradiction plus tenant/object binding not proven on the privileged mutation path.
- `036 get_dashboard_master()`: gestor/root gate precedes global DEFINER reads; intended global versus tenant scope is not proven.
- `047 get_stats_horario()`: gestor/root gate precedes global lead-stat reads; tenant-gestor cross-tenant authority is not proven.
- `119 relatorio_fornecedor(uuid)`: supplied `p_lista_id` is not proven bound to the gestor tenant/list scope before privileged reads.
- `127 solicitar_lote_forcado(uuid)`: intended forced-user actor semantics are not proven by the transitive body contract.


## 7. Downstream dependencies

`57` target security-mode decisions remain deliberately `NOT_DETERMINED`. They depend on M2-04C evidence where caller sufficiency, direct table authority, RLS, FORCE RLS, USING/WITH CHECK or policy composition determines whether INVOKER authority is intentionally sufficient.

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

This revised acceptance authorizes only the documentation reconciliation and PR lifecycle explicitly granted by Product Authority for PR #183.

```text
documentation reconciliation within the same 7 PR files = AUTHORIZED
new exact-head review = AUTHORIZED
Ready lifecycle revalidation = AUTHORIZED
new exact-head pre-merge = AUTHORIZED

implementation = NOT_AUTHORIZED
SQL / DDL / DML = NOT_AUTHORIZED
migration = NOT_AUTHORIZED
GRANT / REVOKE / ALTER DEFAULT PRIVILEGES = NOT_AUTHORIZED
SECURITY DEFINER / INVOKER runtime change = NOT_AUTHORIZED
owner / search_path change = NOT_AUTHORIZED
RLS / policy change = NOT_AUTHORIZED
Supabase / Auth mutation = NOT_AUTHORIZED
AppSec execution = NOT_AUTHORIZED
runtime hostile testing = NOT_AUTHORIZED
M2-04C execution = NOT_AUTHORIZED
M2-04D execution = NOT_AUTHORIZED
deploy = NOT_AUTHORIZED
merge = NOT_AUTHORIZED
Security Go = NOT_GRANTED
```
