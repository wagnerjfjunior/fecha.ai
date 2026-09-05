# FECH.AI — STS-M2-02 Database Authority Map — Accepted Evidence

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Program:** Issue #141 — `FECH.AI Security-to-Scale 2026`  
**Decision date:** `2026-09-05`  
**Decision anchor main:** `afa92903bda1755241c1fea5d9fbb436f75231ca`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`

## 1. Decision boundary

```text
STS-M2-02 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-02 AS-IS DATABASE AUTHORITY MAP = SUFFICIENTLY UNDERSTOOD
Security Go = NOT_GRANTED
```

This closes the mapping/understanding task only. It does not assert hostile-client PASS, cross-tenant PASS, target architecture implementation, remediation completion or Security Go.

## 2. Exact anchors and specialist evidence

```text
FECH.AI exact main = afa92903bda1755241c1fea5d9fbb436f75231ca
SES exact main = 285b08206d334971b182e2d46646ba0b6938bdfe
Supabase project = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
```

| Specialist | Verdict | SHA-256 of supplied evidence bundle |
|---|---|---|
| Backend/Data | `BACKEND_DATA_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS` | `cc671280dc044f4d330c131dc5854b5aec19ebaadf7a2ff64da43bb62a33cb6b` |
| Architecture | `ARCHITECTURE_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS` | `741014b5b75a8b1416b93c4e8af17d7024945a608f406cbe9428b6552e30a703` |
| AppSec | `APPSEC_RECOMMENDS_STS_M2_02_ACCEPTANCE_WITH_RESIDUALS` | `6a69557f53df293be1f6e7364b5a8a581cf67ec5a95f2cc6f53fc795eda96a52` |

Live-catalog facts are preserved as accepted upstream Backend/Data READ_ONLY evidence. This documentation commit does not re-execute production SQL and does not convert static/catalog evidence into runtime PASS.

## 3. Canonical inventory summary

```text
public tables = 44
RLS enabled = 44/44
FORCE RLS = 30
non-FORCE RLS = 14

policies total = 85
write policies = 46
authenticated-reachable write policies = 15
latent / grant-blocked write policies = 31

public routines = 160
SECURITY DEFINER = 137
PUBLIC EXECUTE = 2
anon EXECUTE = 31
authenticated EXECUTE = 134
service_role EXECUTE = 151

lexical mutative matches = 59
actual SQL-DML = 57
SECURITY DEFINER + actual SQL-DML = 56
anon EXECUTE + actual SQL-DML = 8
METRIC_CONFLICT = RESOLVED

non-internal triggers = 31
public views = 8
```

Eight anon-executable actual-DML routines: `alterar_plano_empresa_root`, `atualizar_status_empresa_root`, `importar_mesa_cliente_disponibilidade_oficial`, `mesa_cliente_upsert_faixas_premio`, `mesa_cliente_upsert_politica_financeira`, `registrar_upload_arquivo_mesa`, `salvar_mesa_cliente_desconto_politica`, `salvar_mesa_cliente_enriquecimento`. Static auth/root/admin/tenant/object checks were observed; anonymous privilege escalation is not proven; hostile-client effectiveness remains NOT_TESTED.

## 4. SECURITY DEFINER caller provenance closure

```text
STATIC_CALLER_PROVENANCE = 137 / 137 CLOSED
NOT_DETERMINED = 0

APP_STATIC_CALLER_CONFIRMED = 64
EDGE_OR_SERVICE_CALLER_CONFIRMED = 3
TRIGGER_ONLY_CONFIRMED = 9
DATABASE_INTERNAL_CALLER_CONFIRMED = 26
EXTERNALLY_CALLABLE_API_NO_CURRENT_APP_CALLER_FOUND = 25
INTERNAL_HELPER_NO_EXTERNAL_CALLER_EXPECTED = 4
NO_VERSIONED_CALLER_FOUND_WITH_COVERAGE = 6
```

### APP_STATIC_CALLER_CONFIRMED (64)

alterar_plano_empresa_root, alterar_role_corretor, aprovar_rejeitar_mesa, atualizar_feedback, atualizar_perfil_corretor, atualizar_status_corretor, atualizar_status_empresa_root, atualizar_time_corretor, avaliar_lista, criar_empresa_root, criar_lista, criar_mesa_simulacao, criar_time, distribuir_lotes, excluir_lista, gerenciar_lista, gerenciar_visibilidade_lista, get_contagens_corretor, get_corretores_time, get_dashboard_gestor, get_dashboard_stats, get_empreendimentos_mesa, get_empresa_mesa_config, get_funil_stats, get_funil_stats_corretor, get_historico_mesas, get_listas_ativas, get_meus_times, get_stats_horario, get_unidades_mesa, importar_leads_batch, importar_mesa_cliente_disponibilidade_oficial, importar_mesa_cliente_json_admin, importar_mesa_cliente_parser_resultado, is_root, listar_empresas_root, listar_funil_estagios, listar_listas_corretor, listar_membros_visibilidade, marcar_senha_inicial_definida, mesa_cliente_aplicar_operacao_financeira_admin, mesa_cliente_listar_operacoes_financeiras_admin, mesa_cliente_obter_operacao_financeira_admin, mesa_cliente_obter_resumo_operacao_cliente_safe, mesa_cliente_obter_simulacao_fluxo_historico, mesa_cliente_resumir_operacao_financeira_admin, meu_funil, meus_leads_email, minha_carteira, minha_producao, mover_funil, mover_funil_lote, proximo_lead, registrar_feedback, registrar_mensagem, registrar_upload_arquivo_mesa, relatorio_fornecedor, relatorio_historico_corretor, salvar_mesa_cliente_enriquecimento, simular_troca_plano_empresa_root, solicitar_lote, trilha_lead, trocar_lista, usuario_pode_importar_mesa_json_admin.

### EDGE_OR_SERVICE_CALLER_CONFIRMED (3)

t3_issue_admin_password_reset_edge_proof, t3_prepare_admin_password_reset, t3_release_admin_password_reset_lease.

### TRIGGER_ONLY_CONFIRMED (9)

audit_trail_log_corretores_critical_update, audit_trail_log_empresas_governance, audit_trail_log_lista_visibilidade_acl, audit_trail_log_listas_governance, audit_trail_log_times_governance, f1_02_b4_validate_lista_visibilidade_target, mesa_cliente_financeiro_assert_integridade, pme_set_updated_at, t3_guard_admin_password_reset_lease.

### DATABASE_INTERNAL_CALLER_CONFIRMED (26)

acquire_lote_lock, audit_trail_actor_context, avaliar_lista, avaliar_lote, corretor_tem_acesso_lista, get_mesa_cliente_desconto_politica, is_admin_global, is_admin_local, is_gestor, lead_tem_acao_real, lot_status_health_check, mesa_cliente_assert_auth, mesa_cliente_assert_empreendimento_empresa, mesa_cliente_can_access_empresa, mesa_cliente_can_admin_empresa, mesa_cliente_current_corretor_context, mesa_cliente_gerar_agenda_financeira_admin, mesa_cliente_obter_politica_financeira, my_corretor_id, my_empresa_id, my_times_como_gestor, operations_health_engine_v1, pme_can_consume_empresa, registrar_root_audit, solicitar_lote_core, validar_mesa_cliente_desconto.

### EXTERNALLY_CALLABLE_API_NO_CURRENT_APP_CALLER_FOUND (25)

devolver_lote, encerrar_lote_parcial, get_dashboard_master, get_kpi_operacional, health_check_core, leads_email_tab, listar_lotes_pendentes_avaliacao, lot_intelligence_engine_v1, mesa_cliente_atualizar_status_operacao_financeira_admin, mesa_cliente_listar_politicas_financeiras, mesa_cliente_montar_payload_agenda_canonica, mesa_cliente_obter_agenda_financeira_cliente_safe, mesa_cliente_persistir_agenda_financeira_admin, mesa_cliente_registrar_operacao_financeira_admin, mesa_cliente_simular_impacto_agenda_persistida_admin, mesa_cliente_simular_impacto_financeiro_admin, mesa_cliente_upsert_faixas_premio, mesa_cliente_upsert_politica_financeira, meu_historico, meus_lembretes, platform_health_center_v1, pme_registrar_message_usage, salvar_mesa_cliente_desconto_politica, set_lembrete, solicitar_lote_forcado.

### INTERNAL_HELPER_NO_EXTERNAL_CALLER_EXPECTED (4)

my_time_id, pme_can_access_empresa, pme_is_empresa_admin, t1_can_update_corretor_row_strict.

### NO_VERSIONED_CALLER_FOUND_WITH_COVERAGE (6)

debug_solicitar_lote, dispensar_lembrete, mover_funil_batch, redefinir_senha_corretor, registrar_audit_log, t1_is_root_strict.

`NO_VERSIONED_CALLER_FOUND_WITH_COVERAGE` does not mean unused, dead or safe to delete. Runtime invocation remains a separate evidence layer.

## 5. Accepted residuals and routing

- broad/default privilege hazard → `STS-M2-04`
- anon EXECUTE surface / 8 anon actual-DML routines → `STS-M2-04 / STS-M3 / STS-M5`
- three anon Mesa mutators without current canonical app caller → `STS-M2-04 / STS-M3`
- `acquire_lote_lock` PUBLIC/anon exposure → `STS-M2-04 / STS-M3 / STS-M5`
- latent grant/RLS/policy combinations → `STS-M2-03 → STS-M2-04`
- `avaliar_lista(3)` caller×ACL contradiction → `STS-M2-04 / STS-M2-05 + runtime validation`
- `trilha_lead` caller×ACL contradiction → `STS-M2-04 / STS-M2-05 + runtime validation`
- service-only / no-versioned-caller privileged routines → `STS-M2-04 / STS-M3`
- legacy `redefinir_senha_corretor` → `STS-M2-04 / STS-M3`
- runtime hostile-client / cross-tenant assurance → `STS-M5`

## 6. Runtime and assurance gaps

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

## 7. Next safe action and non-authorizations

After this reconciliation is merged: `STS-M2-03 — ÍNDICES / ACL CONTRADITÓRIAS — READ_ONLY FIRST`.

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