# FECH.AI — STS-M2-02 Database Authority Map — Accepted Evidence

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Program:** Issue #141 — `FECH.AI Security-to-Scale 2026`  
**Task:** `STS-M2-02 — Mapa routines / policies / triggers / grants`  
**Decision date:** `2026-09-05`  
**Decision anchor main:** `afa92903bda1755241c1fea5d9fbb436f75231ca`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`

## 1. Product Authority decision

```text
STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-02 AS-IS DATABASE AUTHORITY MAP = SUFFICIENTLY UNDERSTOOD
Security Go = NOT_GRANTED
```

This acceptance closes the mapping/understanding task only. It does not assert hostile-client PASS, cross-tenant PASS, target architecture implementation, remediation completion or Security Go.

## 2. Exact anchors and provenance

```text
FECH.AI repository = wagnerjfjunior/fecha.ai
FECH.AI exact main = afa92903bda1755241c1fea5d9fbb436f75231ca
SES exact main = 285b08206d334971b182e2d46646ba0b6938bdfe
Supabase project = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
Issue #141 = OPEN
```

| Evidence | Final verdict | SHA-256 of supplied specialist evidence bundle |
|---|---|---|
| Backend/Data | `BACKEND_DATA_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS` | `cc671280dc044f4d330c131dc5854b5aec19ebaadf7a2ff64da43bb62a33cb6b` |
| Architecture | `ARCHITECTURE_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS` | `741014b5b75a8b1416b93c4e8af17d7024945a608f406cbe9428b6552e30a703` |
| AppSec | `APPSEC_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS` | `6a69557f53df293be1f6e7364b5a8a581cf67ec5a95f2cc6f53fc795eda96a52` |

Evidence boundary:

```text
Backend/Data = live-catalog READ_ONLY + canonical GitHub static/caller evidence
Architecture = independent READ_ONLY architecture adjudication
AppSec = independent READ_ONLY security adjudication; no active adversarial production test
Master Project = exact-main / Product Authority adjudication and durable record
```

## 3. Accepted database-authority inventory

```text
public tables = 44
RLS enabled = 44 / 44
FORCE RLS = 30
non-FORCE RLS = 14
RLS disabled = 0
table owners = postgres

RLS-enabled tables with zero policies = 5
anon direct table SELECT/INSERT/UPDATE/DELETE = 0
authenticated direct SELECT = 28 tables
authenticated direct table-write grants = 9 tables
authenticated MAINTAIN grants = 12 tables

policies total = 85
write policies = 46
authenticated-reachable write policies under current grants = 15
latent / grant-blocked write policies = 31

public routines = 160
SECURITY DEFINER = 137
non-DEFINER = 23
routine owner = postgres

PUBLIC EXECUTE = 2
anon EXECUTE = 31
authenticated EXECUTE = 134
service_role EXECUTE = 151

all 137 SECURITY DEFINER routines have explicit proconfig/search_path

lexical mutative-keyword matches = 59
actual SQL-DML routines = 57
SECURITY DEFINER + actual SQL-DML = 56
anon EXECUTE + actual SQL-DML = 8
METRIC_CONFLICT = RESOLVED

non-internal triggers = 31
trigger instances calling SECURITY DEFINER = 18
unique trigger functions = 16
unique SECURITY DEFINER trigger functions = 9

public views = 8
authenticated SELECT views = 2
anon view SELECT = 0
```

The `59 → 57` reconciliation excludes lexical-only matches in `gpt_security_metadata_snapshot` and `mesa_cliente_financeiro_assert_integridade`, while retaining the writable-CTE DML in `proximo_lead`.

Eight anon-executable actual-DML routines:

```text
alterar_plano_empresa_root
atualizar_status_empresa_root
importar_mesa_cliente_disponibilidade_oficial
mesa_cliente_upsert_faixas_premio
mesa_cliente_upsert_politica_financeira
registrar_upload_arquivo_mesa
salvar_mesa_cliente_desconto_politica
salvar_mesa_cliente_enriquecimento
```

Static DB-side auth/root/admin/tenant/object checks were observed in the applicable mutative paths. `ANON EXECUTE SURFACE = PROVEN`; `ANONYMOUS PRIVILEGE ESCALATION = NOT PROVEN`; hostile-client effectiveness remains `NOT_TESTED`.

## 4. SECURITY DEFINER static caller / authority map

Static caller provenance is closed for `137 / 137` SECURITY DEFINER routines. `NOT_DETERMINED = 0`.

```text
APP = APP_STATIC_CALLER_CONFIRMED
EDGE = EDGE_OR_SERVICE_CALLER_CONFIRMED
TRIGGER = TRIGGER_ONLY_CONFIRMED
DB_INTERNAL = DATABASE_INTERNAL_CALLER_CONFIRMED
EXT_NO_APP_CALLER = EXTERNALLY_CALLABLE_API_NO_CURRENT_APP_CALLER_FOUND
INTERNAL_HELPER = INTERNAL_HELPER_NO_EXTERNAL_CALLER_EXPECTED
NO_VERSIONED_CALLER = NO_VERSIONED_CALLER_FOUND_WITH_COVERAGE

ACL = PUBLIC / anon / authenticated / service_role
R/W = static reads / writes
```

Final distribution:

```text
APP = 64
EDGE = 3
TRIGGER = 9
DB_INTERNAL = 26
EXT_NO_APP_CALLER = 25
INTERNAL_HELPER = 4
NO_VERSIONED_CALLER = 6
TOTAL = 137
```

```text
001 acquire_lote_lock | 1/1/1/1 | -/- | NONE | DB_INTERNAL
002 alterar_plano_empresa_root | 0/1/1/1 | R/W | ROOT | APP
003 alterar_role_corretor | 0/0/1/1 | R/W | AUTH+ROOT | APP
004 aprovar_rejeitar_mesa | 0/0/1/1 | R/W | AUTH+ROOT | APP
005 atualizar_feedback | 0/0/1/1 | R/W | AUTH+OBJ | APP
006 atualizar_perfil_corretor | 0/0/1/1 | R/W | AUTH+OBJ | APP
007 atualizar_status_corretor | 0/0/1/0 | R/W | AUTH+ROOT | APP
008 atualizar_status_empresa_root | 0/1/1/1 | R/W | ROOT | APP
009 atualizar_time_corretor | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
010 audit_trail_actor_context | 0/0/1/1 | R/- | AUTH | DB_INTERNAL
011 audit_trail_log_corretores_critical_update | 0/0/1/1 | R/W | AUTH/trigger row | TRIGGER
012 audit_trail_log_empresas_governance | 0/0/1/1 | -/W | trigger row | TRIGGER
013 audit_trail_log_lista_visibilidade_acl | 0/0/1/1 | -/W | trigger row | TRIGGER
014 audit_trail_log_listas_governance | 0/0/1/1 | -/W | trigger row | TRIGGER
015 audit_trail_log_times_governance | 0/0/1/1 | -/W | trigger row | TRIGGER
016 avaliar_lista | 0/0/0/1 | R/W | AUTH+OBJ | APP
017 avaliar_lista | 0/0/1/1 | -/- | INT | DB_INTERNAL
018 avaliar_lote | 0/0/1/1 | R/W | AUTH+OBJ | DB_INTERNAL
019 corretor_tem_acesso_lista | 0/0/0/1 | R/- | supplied object + server relations | DB_INTERNAL
020 criar_empresa_root | 0/0/1/1 | R/W | AUTH+ROOT | APP
021 criar_lista | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
022 criar_mesa_simulacao | 0/0/1/1 | R/W | AUTH+OBJ+ROOT | APP
023 criar_time | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
024 debug_solicitar_lote | 0/0/0/1 | -/- | AUTH | NO_VERSIONED_CALLER
025 devolver_lote | 0/0/1/1 | R/W | AUTH+OBJ | EXT_NO_APP_CALLER
026 dispensar_lembrete | 0/0/0/1 | R/W | AUTH+OBJ | NO_VERSIONED_CALLER
027 distribuir_lotes | 0/0/1/1 | R/W | AUTH+ROOT | APP
028 encerrar_lote_parcial | 0/0/1/1 | R/W | AUTH+OBJ | EXT_NO_APP_CALLER
029 excluir_lista | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
030 f1_02_b4_validate_lista_visibilidade_target | 0/0/0/1 | R/- | trigger row + relational invariant | TRIGGER
031 gerenciar_lista | 0/0/0/1 | -/W | ROOT/gestor | APP
032 gerenciar_visibilidade_lista | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
033 get_contagens_corretor | 0/0/1/1 | R/- | AUTH | APP
034 get_corretores_time | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
035 get_dashboard_gestor | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
036 get_dashboard_master | 0/0/1/1 | R/- | ROOT/gestor | EXT_NO_APP_CALLER
037 get_dashboard_stats | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
038 get_empreendimentos_mesa | 0/1/1/1 | R/- | AUTH+TEN+ROOT | APP
039 get_empresa_mesa_config | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
040 get_funil_stats | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
041 get_funil_stats_corretor | 0/0/1/1 | R/- | AUTH | APP
042 get_historico_mesas | 0/0/1/1 | R/- | AUTH+OBJ | APP
043 get_kpi_operacional | 0/0/1/1 | R/- | AUTH+ROOT | EXT_NO_APP_CALLER
044 get_listas_ativas | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
045 get_mesa_cliente_desconto_politica | 0/1/1/1 | R/- | AUTH+OBJ+ROOT | DB_INTERNAL
046 get_meus_times | 0/0/1/1 | R/- | AUTH+TEN | APP
047 get_stats_horario | 0/0/1/1 | R/- | ROOT/gestor | APP
048 get_unidades_mesa | 0/1/1/1 | R/- | AUTH+OBJ+ROOT | APP
049 health_check_core | 0/0/1/1 | R/- | AUTH+TEN+ROOT | EXT_NO_APP_CALLER
050 importar_leads_batch | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
051 importar_mesa_cliente_disponibilidade_oficial | 0/1/1/1 | R/W | AUTH+OBJ+ROOT | APP
052 importar_mesa_cliente_json_admin | 0/0/1/1 | R/- | AUTH+TEN | APP
053 importar_mesa_cliente_parser_resultado | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
054 is_admin_global | 0/0/1/1 | R/- | ROOT | DB_INTERNAL
055 is_admin_local | 0/0/1/1 | R/- | AUTH+profile | DB_INTERNAL
056 is_gestor | 0/0/1/1 | R/- | AUTH+profile | DB_INTERNAL
057 is_root | 0/0/1/1 | R/- | AUTH+trusted profile | APP
058 lead_tem_acao_real | 0/0/1/1 | R/- | OBJ | DB_INTERNAL
059 leads_email_tab | 0/0/1/1 | R/- | AUTH | EXT_NO_APP_CALLER
060 listar_empresas_root | 0/0/1/1 | R/- | ROOT | APP
061 listar_funil_estagios | 0/0/1/1 | R/- | AUTH+ROOT | APP
062 listar_listas_corretor | 0/0/1/1 | R/- | AUTH+TEN | APP
063 listar_lotes_pendentes_avaliacao | 0/0/1/1 | R/- | AUTH | EXT_NO_APP_CALLER
064 listar_membros_visibilidade | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
065 lot_intelligence_engine_v1 | 0/0/1/1 | R/- | AUTH+TEN+ROOT | EXT_NO_APP_CALLER
066 lot_status_health_check | 0/0/1/1 | R/- | TEN+ROOT | DB_INTERNAL
067 marcar_senha_inicial_definida | 0/0/1/0 | R/W | AUTH/own row | APP
068 mesa_cliente_aplicar_operacao_financeira_admin | 0/0/1/1 | R/W | AUTH+OBJ/admin | APP
069 mesa_cliente_assert_auth | 0/1/1/1 | -/- | AUTH | DB_INTERNAL
070 mesa_cliente_assert_empreendimento_empresa | 0/1/1/1 | R/- | OBJ→TEN | DB_INTERNAL
071 mesa_cliente_atualizar_status_operacao_financeira_admin | 0/0/1/1 | R/W | AUTH+OBJ/admin | EXT_NO_APP_CALLER
072 mesa_cliente_can_access_empresa | 0/1/1/1 | R/- | AUTH+TEN+ROOT | DB_INTERNAL
073 mesa_cliente_can_admin_empresa | 0/1/1/1 | R/- | AUTH+TEN+ROOT | DB_INTERNAL
074 mesa_cliente_current_corretor_context | 0/1/1/1 | R/- | AUTH+profile | DB_INTERNAL
075 mesa_cliente_financeiro_assert_integridade | 0/1/1/1 | R/- | trigger-row OBJ→TEN | TRIGGER
076 mesa_cliente_gerar_agenda_financeira_admin | 0/0/1/1 | R/- | ROOT+Mesa helpers | DB_INTERNAL
077 mesa_cliente_listar_operacoes_financeiras_admin | 0/0/1/1 | R/- | AUTH+OBJ/admin | APP
078 mesa_cliente_listar_politicas_financeiras | 0/1/1/1 | R/- | Mesa auth/tenant helpers | EXT_NO_APP_CALLER
079 mesa_cliente_montar_payload_agenda_canonica | 0/0/1/1 | R/- | ROOT+Mesa context | EXT_NO_APP_CALLER
080 mesa_cliente_obter_agenda_financeira_cliente_safe | 0/0/1/1 | R/- | AUTH+OBJ+ROOT | EXT_NO_APP_CALLER
081 mesa_cliente_obter_operacao_financeira_admin | 0/0/1/1 | R/- | AUTH+OBJ/admin | APP
082 mesa_cliente_obter_politica_financeira | 0/1/1/1 | R/- | Mesa admin helper | DB_INTERNAL
083 mesa_cliente_obter_resumo_operacao_cliente_safe | 0/0/1/1 | R/- | AUTH+OBJ | APP
084 mesa_cliente_obter_simulacao_fluxo_historico | 0/0/1/1 | R/- | AUTH+OBJ | APP
085 mesa_cliente_persistir_agenda_financeira_admin | 0/0/1/1 | R/W | AUTH+Mesa helpers | EXT_NO_APP_CALLER
086 mesa_cliente_registrar_operacao_financeira_admin | 0/0/1/1 | R/W | AUTH+OBJ/Mesa helpers | EXT_NO_APP_CALLER
087 mesa_cliente_resumir_operacao_financeira_admin | 0/0/1/1 | R/- | AUTH+OBJ/admin | APP
088 mesa_cliente_simular_impacto_agenda_persistida_admin | 0/0/1/1 | R/- | AUTH+OBJ/admin | EXT_NO_APP_CALLER
089 mesa_cliente_simular_impacto_financeiro_admin | 0/0/1/1 | R/- | Mesa tenant helpers | EXT_NO_APP_CALLER
090 mesa_cliente_upsert_faixas_premio | 0/1/1/1 | R/W | Mesa auth/admin + OBJ→TEN | EXT_NO_APP_CALLER
091 mesa_cliente_upsert_politica_financeira | 0/1/1/1 | -/W | Mesa auth/admin + OBJ→TEN | EXT_NO_APP_CALLER
092 meu_funil | 0/0/1/1 | R/- | AUTH | APP
093 meu_historico | 0/0/1/1 | R/- | AUTH | EXT_NO_APP_CALLER
094 meus_leads_email | 0/0/1/1 | R/- | AUTH | APP
095 meus_lembretes | 0/0/1/1 | R/- | AUTH | EXT_NO_APP_CALLER
096 minha_carteira | 0/0/1/1 | R/- | AUTH | APP
097 minha_producao | 0/0/1/1 | R/- | AUTH | APP
098 mover_funil | 0/0/1/1 | R/W | AUTH+TEN+ROOT | APP
099 mover_funil_batch | 0/0/0/1 | R/W | AUTH+OBJ | NO_VERSIONED_CALLER
100 mover_funil_lote | 0/0/1/1 | R/W | AUTH+TEN+broker | APP
101 my_corretor_id | 0/0/1/1 | R/- | AUTH | DB_INTERNAL
102 my_empresa_id | 0/0/1/1 | R/- | AUTH | DB_INTERNAL
103 my_time_id | 0/0/1/1 | R/- | AUTH | INTERNAL_HELPER
104 my_times_como_gestor | 0/0/1/1 | R/- | TEN+broker | DB_INTERNAL
105 operations_health_engine_v1 | 0/0/1/1 | R/- | AUTH+TEN+ROOT | DB_INTERNAL
106 platform_health_center_v1 | 0/0/1/1 | -/- | ND | EXT_NO_APP_CALLER
107 pme_can_access_empresa | 0/0/1/1 | R/- | TEN+ROOT | INTERNAL_HELPER
108 pme_can_consume_empresa | 0/0/1/1 | R/- | AUTH+TEN+ROOT | DB_INTERNAL
109 pme_is_empresa_admin | 0/0/1/1 | R/- | AUTH+TEN+ROOT | INTERNAL_HELPER
110 pme_registrar_message_usage | 0/0/1/1 | R/W | AUTH+broker+TEN | EXT_NO_APP_CALLER
111 pme_set_updated_at | 0/0/0/0 | -/- | trigger row | TRIGGER
112 proximo_lead | 0/0/1/1 | R/W | AUTH+server-derived broker/TEN | APP
113 redefinir_senha_corretor | 0/0/0/1 | R/W | gestor | NO_VERSIONED_CALLER
114 registrar_audit_log | 0/0/0/1 | R/W | AUTH/TEN | NO_VERSIONED_CALLER
115 registrar_feedback | 0/0/1/1 | R/W | AUTH+OBJ+ROOT | APP
116 registrar_mensagem | 0/0/1/1 | R/W | AUTH+OBJ | APP
117 registrar_root_audit | 0/0/1/1 | R/W | AUTH+ROOT | DB_INTERNAL
118 registrar_upload_arquivo_mesa | 0/1/1/1 | R/W | AUTH+OBJ+ROOT | APP
119 relatorio_fornecedor | 0/0/1/1 | R/- | gestor/TEN | APP
120 relatorio_historico_corretor | 0/0/1/1 | R/- | AUTH | APP
121 salvar_mesa_cliente_desconto_politica | 0/1/1/1 | R/W | AUTH+TEN+ROOT | EXT_NO_APP_CALLER
122 salvar_mesa_cliente_enriquecimento | 0/1/1/1 | R/W | AUTH+OBJ+TEN+ROOT | APP
123 set_lembrete | 0/0/1/1 | R/W | AUTH+OBJ | EXT_NO_APP_CALLER
124 simular_troca_plano_empresa_root | 0/1/1/1 | R/- | ROOT | APP
125 solicitar_lote | 0/0/1/1 | R/W | AUTH+TEN+broker | APP
126 solicitar_lote_core | 0/0/0/1 | -/- | AUTH+ROOT | DB_INTERNAL
127 solicitar_lote_forcado | 0/0/1/1 | -/- | ND | EXT_NO_APP_CALLER
128 t1_can_update_corretor_row_strict | 0/0/1/0 | R/- | AUTH+trusted profile | INTERNAL_HELPER
129 t1_is_root_strict | 0/0/1/0 | R/- | AUTH+trusted profile | NO_VERSIONED_CALLER
130 t3_guard_admin_password_reset_lease | 0/0/0/0 | R/W | trigger context + reset lease | TRIGGER
131 t3_issue_admin_password_reset_edge_proof | 0/0/0/1 | -/W | Edge/service boundary | EDGE
132 t3_prepare_admin_password_reset | 0/0/1/0 | R/W | AUTH + Edge-issued proof | EDGE
133 t3_release_admin_password_reset_lease | 0/0/0/1 | -/W | Edge/service boundary | EDGE
134 trilha_lead | 0/0/0/1 | R/- | AUTH+OBJ | APP
135 trocar_lista | 0/0/1/1 | R/W | AUTH+TEN+broker | APP
136 usuario_pode_importar_mesa_json_admin | 0/0/1/1 | R/- | AUTH+TEN+ROOT | APP
137 validar_mesa_cliente_desconto | 0/1/1/1 | -/- | object-derived policy | DB_INTERNAL
```

The compact map is a static/catalog contract. Caller class, ACL and tenant/authority basis do not prove runtime invocation or hostile-client effectiveness.

## 5. Accepted residuals and downstream routing

| Residual | Accepted bounded statement | Downstream |
|---|---|---|
| broad/default privilege hazard | Future objects may inherit broader client privileges than target least-privilege posture. Current exploit is not proven. | `STS-M2-04` |
| anon EXECUTE surface | 31 anon-executable routines; 8 perform SQL DML. Static guards observed; hostile runtime not tested. | `STS-M2-04 / STS-M3 / STS-M5` |
| 3 anon Mesa mutators without current canonical app caller | `mesa_cliente_upsert_faixas_premio`, `mesa_cliente_upsert_politica_financeira`, `salvar_mesa_cliente_desconto_politica`; least-privilege debt; runtime non-use not proven. | `STS-M2-04 / STS-M3` |
| `acquire_lote_lock` PUBLIC/anon exposure | Low-level advisory-lock primitive is directly executable; data compromise/production DoS not proven. | `STS-M2-04 / STS-M3 / STS-M5` |
| latent grant/RLS/policy combinations | Current hidden write path not proven; one-sided future changes can reactivate authority and reduce legibility. | `STS-M2-03 → STS-M2-04` |
| `avaliar_lista(3)` caller × ACL contradiction | Canonical caller observed; authenticated EXECUTE observed false; runtime outcome not tested. | `STS-M2-04 / STS-M2-05 + runtime validation` |
| `trilha_lead` caller × ACL contradiction | Canonical caller observed; authenticated EXECUTE observed false; runtime outcome not tested. | `STS-M2-04 / STS-M2-05 + runtime validation` |
| service-only / no-versioned-caller privileged routines | Static provenance closed; no-versioned-caller does not prove runtime non-use or safe retirement. | `STS-M2-04 / STS-M3` |
| legacy `redefinir_senha_corretor` | Service-only legacy password mutation authority; current canonical app path uses Edge/T3; operational dependency before retirement is unproven. | `STS-M2-04 / STS-M3` |
| runtime hostile-client / cross-tenant assurance | Structural authority map is understood; adversarial effectiveness is not proven. | `STS-M5` |

Default privileges were classified by Architecture/AppSec as structural security debt / future regression hazard, not current exploit proof.

## 6. Runtime / assurance gaps preserved

```text
hostile anonymous execution = NOT_TESTED
cross-tenant hostile-client effectiveness = NOT_TESTED
RLS/policy adversarial effectiveness = NOT_TESTED
unauthorized object/ID substitution = NOT_TESTED
root/admin role-forgery = NOT_TESTED
Mesa hostile-client mutation = NOT_TESTED
PME hostile-tenant cases = NOT_TESTED
LeadOps/CRM/Funil cross-tenant cases = NOT_TESTED
acquire_lote_lock availability abuse = NOT_TESTED
avaliar_lista runtime behavior = NOT_TESTED
trilha_lead runtime behavior = NOT_TESTED
no-versioned-caller runtime non-use = NOT_PROVEN
legacy reset RPC runtime non-use = NOT_PROVEN
Security Go = NOT_GRANTED
```

Preserve: `STRUCTURALLY OBSERVED CONTROL != CONTROL PROVEN EFFECTIVE AT RUNTIME`.

## 7. Specialist convergence and Product Authority acceptance

```text
BACKEND_DATA_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS
ARCHITECTURE_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS
APPSEC_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS
```

AppSec identified no `BLOCKING` finding for the STS-M2-02 mapping decision and no material privileged business path whose tenant/role/ownership authority remained structurally unknown at the accepted static/catalog proof level.

Product Authority accepted the residuals without waiver and without Security Go.

## 8. Next safe action

After this bounded documentation reconciliation is merged:

```text
STS-M2-03 — ÍNDICES / ACL CONTRADITÓRIAS — READ_ONLY FIRST
```

No STS-M2-03 implementation is authorized by this decision.

Downstream:

```text
STS-M2-03 = indexes / contradictory or redundant ACL candidates
STS-M2-04 = target SECURITY DEFINER / RLS / DML / grants / default-privilege policy
STS-M2-05 = Database Contract Map
STS-M2-06 = database architectural decision
STS-M3 = privileged/shared backend authority contract
STS-M5 = controlled hostile-client / cross-tenant / reliability assurance
```

## 9. Invalidation and non-authorizations

Revalidate proportionally after material changes to routines, policies, triggers, grants, RLS, role/default privileges, callers, production catalog, runtime evidence or Product Authority scope.

Absent material contradiction, do not reopen STS-M2-01, the 160-routine universe, 137 SECURITY DEFINER inventory, resolved `59/57/56/8` metrics, or `137/137` static caller-provenance closure.

```text
NO DDL/DML
NO migration
NO Supabase/Auth mutation
NO RLS/policy/grant/revoke/default privilege change
NO function/RPC/trigger mutation
NO Edge Function mutation
NO production/runtime hostile testing
NO deploy
NO STS-M2-03 implementation
NO STS-M2-04 implementation
NO Security Go
```
