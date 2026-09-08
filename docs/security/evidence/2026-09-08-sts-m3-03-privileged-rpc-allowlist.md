# FECH.AI — STS-M3-03 — Privileged RPC Allowlist — Product Authority Accepted Decision

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Decision date:** `2026-09-08`  
**Product Authority:** Wagner / FECH.AI  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Decision/publication base main:** `ec42e7b087dd1bf9b7ddc0cf05316e9d3e7979be`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Mutation class:** `DOCUMENTATION_ONLY`

## 1. Product Authority decision

~~~text
STS-M3-03 =
COMPLETE / ACCEPTED WITH RESIDUALS

PUBLIC ROUTINE UNIVERSE = 160
PRIVILEGED CANDIDATE UNIVERSE = 49
CANDIDATE ROWS EXPLICITLY DISPOSED = 49 / 49
SERVICE_ONLY_COMMAND = 2 / 2 mapped
ALLOWLIST COMPLETENESS = PROVEN TO ACCEPTED BOUNDED EVIDENCE STANDARD

CURRENT IMPLEMENTATION TARGET-COMPLIANT = NO / NOT_PROVEN AS A WHOLE
RUNTIME HOSTILE ASSURANCE = NOT_PERFORMED
APPSEC PASS = NOT_PERFORMED
SECURITY GO = NOT_GRANTED
~~~

This publication records the already accepted READ_ONLY analysis. It does not re-run the live database/runtime and does not promote documentation acceptance to implementation/runtime/security PASS.

## 2. Frozen authority contract consumed

~~~text
AUTHENTICATED PRINCIPAL = auth.uid()

TENANT AUTHORITY =
canonical active corretores identity
+ active empresa
+ canonical tenant role
+ operation-specific permission

TEAM AUTHORITY =
same empresa
+ active team
+ times.gestor_id = canonical gestor
+ operation-specific permission

INDIVIDUAL BUSINESS AUTHORITY =
same empresa
+ persisted ownership / assignment / responsibility relation
+ operation-specific permission

PLATFORM ROOT =
active public.admins
+ role='admin_global'
+ explicit platform operation

ROOT TENANT BUSINESS ACCESS = NO IMPLICIT AUTHORITY

SERVICE_ONLY AUTHORITY =
explicit SERVICE_ONLY_COMMAND
+ canonical trusted runtime
+ service owner
+ trusted server-side business / tenant authorization
+ bounded side effects
+ bounded credential / secret boundary
+ runtime proof
+ revoke / kill path

service_role capability alone = NOT BUSINESS AUTHORIZATION
INSUFFICIENT / INCONSISTENT AUTHORITY = DENY
~~~

BG-06 exceptional root tenant support remains `PARKED / NOT_AUTHORIZED`.

## 3. Candidate-universe provenance

~~~text
M2-04B3:
41 PRIVILEGED_OPERATION
+ 2 SERVICE_ONLY_COMMAND
= 43

M2-04B2 accepted privileged-operation candidates:
6

TOTAL = 49
~~~

Versioned anchors on the decision base:
- `docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv` — blob `cf3baa6e5a6ab6465688de8f6af43cba7c27d3bd`;
- `docs/security/evidence/2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md` — blob `bfa43f6936b2a381552dbb95f5306f13069142af`;
- `docs/security/evidence/2026-09-08-sts-m3-02-authority-contract-by-context.md` — blob `6cf20f5298e183c34d9b560740b3d19c621fb7bb`.

## 4. Exact accepted 49-row disposition

| # | Exact routine/signature | Target authority plane | Accepted disposition |
|---:|---|---|---|
| 1 | `public.alterar_role_corretor(p_corretor_id uuid, p_novo_role text)` | `TENANT_ADMIN` | `ALLOWLIST / BRANCH_GUARDED` |
| 2 | `public.aprovar_rejeitar_mesa(p_simulacao_id uuid, p_acao text, p_justificativa text)` | `TEAM_GESTOR` | `ALLOWLIST / RESOURCE_BOUND` |
| 3 | `public.atualizar_status_corretor(p_corretor_id uuid, p_ativo boolean, p_apto_para_receber boolean)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / BRANCH_GUARDED` |
| 4 | `public.atualizar_time_corretor(p_corretor_id uuid, p_time_id uuid)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / BRANCH_GUARDED` |
| 5 | `public.criar_empresa_root(p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer)` | `PLATFORM_ROOT` | `ALLOWLIST` |
| 6 | `public.criar_lista(p_nome_fornecedor text, p_nome_arquivo text, p_escopo text)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / BRANCH_GUARDED` |
| 7 | `public.criar_mesa_simulacao(p_empresa_id uuid, p_empreendimento_id uuid, p_unidade_id uuid, p_lead_id uuid, p_cliente_nome text, p_valor_total numeric, p_meta_obra_pct integer, p_tabela_provisoria boolean, p_fluxo_json jsonb)` | `INDIVIDUAL_BUSINESS` | `ALLOWLIST / OWNERSHIP_REQUIRED` |
| 8 | `public.criar_time(p_nome text, p_gestor_id uuid)` | `TENANT_ADMIN` | `ALLOWLIST` |
| 9 | `public.distribuir_lotes()` | `TENANT_ADMIN` | `ALLOWLIST` |
| 10 | `public.excluir_lista(p_lista_id uuid)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / BRANCH_GUARDED` |
| 11 | `public.gerenciar_lista(p_lista_id uuid, p_acao text, p_motivo text)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / ACL_CONTRADICTION_RESIDUAL` |
| 12 | `public.gerenciar_visibilidade_lista(p_lista_id uuid, p_targets jsonb)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / BRANCH_GUARDED` |
| 13 | `public.get_dashboard_master()` | `NONE` | `RETIRE / LEGACY_TARGET` |
| 14 | `public.get_stats_horario()` | `TEAM_GESTOR` | `ALLOWLIST / TENANT_TEAM_SCOPE_REQUIRED` |
| 15 | `public.health_check_core()` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 16 | `public.importar_mesa_cliente_json_admin(p_empresa_id uuid, p_empreendimento_nome text, p_incorporadora text, p_bairro text, p_cidade text, p_nome_arquivo text, p_parser_nome text, p_unidades jsonb)` | `TENANT_ADMIN` | `ALLOWLIST` |
| 17 | `public.importar_mesa_cliente_parser_resultado(p_empresa_id uuid, p_empreendimento_nome text, p_incorporadora text, p_bairro text, p_cidade text, p_nome_arquivo text, p_parser_nome text, p_unidades jsonb)` | `TENANT_ADMIN` | `ALLOWLIST` |
| 18 | `public.listar_empresas_root()` | `PLATFORM_ROOT` | `ALLOWLIST` |
| 19 | `public.lot_intelligence_engine_v1(p_lote_id uuid, p_lista_id uuid, p_corretor_id uuid)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 20 | `public.mesa_cliente_aplicar_operacao_financeira_admin(p_operacao_id uuid, p_parametros jsonb)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / RESOURCE_BOUND` |
| 21 | `public.mesa_cliente_atualizar_status_operacao_financeira_admin(p_operacao_id uuid, p_acao text, p_motivo text, p_parametros jsonb)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 22 | `public.mesa_cliente_gerar_agenda_financeira_admin(p_simulacao_id uuid, p_data_ato date, p_fluxo_json jsonb, p_payload_tabela jsonb)` | `DB_INTERNAL` | `INTERNAL_ONLY / NOT_CLIENT_CALLABLE` |
| 23 | `public.mesa_cliente_listar_operacoes_financeiras_admin(p_simulacao_id uuid, p_agenda_id uuid, p_filtros jsonb)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / RESOURCE_BOUND` |
| 24 | `public.mesa_cliente_listar_politicas_financeiras(p_empresa_id uuid, p_empreendimento_id uuid, p_ativas_only boolean, p_limit integer, p_offset integer)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 25 | `public.mesa_cliente_montar_payload_agenda_canonica(p_simulacao_id uuid)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 26 | `public.mesa_cliente_obter_operacao_financeira_admin(p_operacao_id uuid, p_parametros jsonb)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / RESOURCE_BOUND` |
| 27 | `public.mesa_cliente_obter_politica_financeira(p_politica_id uuid, p_empresa_id uuid)` | `DB_INTERNAL` | `INTERNAL_ONLY / NOT_CLIENT_CALLABLE` |
| 28 | `public.mesa_cliente_persistir_agenda_financeira_admin(p_simulacao_id uuid, p_data_ato date, p_fluxo_json jsonb, p_payload_tabela jsonb)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 29 | `public.mesa_cliente_registrar_operacao_financeira_admin(p_simulacao_id uuid, p_agenda_id uuid, p_tipo_operacao text, p_parcela_id uuid, p_data_referencia date, p_data_destino date, p_valor_operacao numeric, p_parametros jsonb)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 30 | `public.mesa_cliente_resumir_operacao_financeira_admin(p_operacao_id uuid, p_parametros jsonb)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / RESOURCE_BOUND` |
| 31 | `public.mesa_cliente_simular_impacto_agenda_persistida_admin(p_simulacao_id uuid, p_data_referencia date, p_modo text, p_parametros jsonb)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 32 | `public.mesa_cliente_simular_impacto_financeiro_admin(p_empresa_id uuid, p_empreendimento_id uuid, p_data_ato date, p_operacoes jsonb, p_politica_id uuid)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 33 | `public.operations_health_engine_v1()` | `DB_INTERNAL` | `INTERNAL_ONLY / NOT_CLIENT_CALLABLE` |
| 34 | `public.platform_health_center_v1()` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 35 | `public.registrar_root_audit(p_action text, p_target_empresa_id uuid, p_payload jsonb)` | `DB_INTERNAL` | `INTERNAL_ONLY / NOT_CLIENT_CALLABLE` |
| 36 | `public.relatorio_fornecedor(p_lista_id uuid)` | `TEAM_GESTOR` | `ALLOWLIST / TENANT_RESOURCE_SCOPE_REQUIRED` |
| 37 | `public.simular_troca_plano_empresa_root(p_empresa_id uuid, p_novo_plano_id uuid, p_data_efetiva timestamp with time zone)` | `PLATFORM_ROOT` | `ALLOWLIST` |
| 38 | `public.solicitar_lote_forcado(p_user_id uuid)` | `NONE` | `RETIRE / LEGACY_TARGET` |
| 39 | `public.t3_issue_admin_password_reset_edge_proof(p_actor_user_id uuid, p_target_user_id uuid)` | `SERVICE_ONLY` | `ALLOWLIST / SERVICE_ONLY_COMMAND` |
| 40 | `public.t3_prepare_admin_password_reset(p_target_user_id uuid, p_edge_proof_id uuid)` | `TENANT_ADMIN + TEAM_GESTOR` | `ALLOWLIST / EDGE_HUMAN_AUTHORITY` |
| 41 | `public.t3_release_admin_password_reset_lease(p_lease_id uuid, p_actor_user_id uuid, p_target_user_id uuid)` | `SERVICE_ONLY` | `ALLOWLIST / SERVICE_ONLY_COMMAND` |
| 42 | `public.trocar_lista(p_lista_nova_id uuid, p_nota integer)` | `INDIVIDUAL_BUSINESS` | `ALLOWLIST / OWNERSHIP_REQUIRED` |
| 43 | `public.usuario_pode_importar_mesa_json_admin(p_empresa_id uuid)` | `TENANT_ADMIN` | `ALLOWLIST` |
| 44 | `public.alterar_plano_empresa_root(uuid,uuid,text,timestamp with time zone)` | `PLATFORM_ROOT` | `ALLOWLIST` |
| 45 | `public.atualizar_status_empresa_root(uuid,boolean,text)` | `PLATFORM_ROOT` | `ALLOWLIST` |
| 46 | `public.importar_mesa_cliente_disponibilidade_oficial(uuid,text,text,jsonb)` | `TENANT_ADMIN` | `ALLOWLIST` |
| 47 | `public.mesa_cliente_upsert_faixas_premio(uuid,uuid,jsonb)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 48 | `public.mesa_cliente_upsert_politica_financeira(uuid,uuid,date,date,date,numeric,numeric,numeric,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,text)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |
| 49 | `public.salvar_mesa_cliente_desconto_politica(uuid,uuid,numeric,numeric,numeric,numeric,text,boolean)` | `NONE` | `BLOCKED_PENDING_EVIDENCE` |

## 5. Disposition totals and residuals

~~~text
PLATFORM_ROOT allowlist = 5
SERVICE_ONLY allowlist = 2
INTERNAL_ONLY / NOT_CLIENT_CALLABLE = 4
RETIRE / LEGACY_TARGET = 2
BLOCKED_PENDING_EVIDENCE = 13
remaining callable privileged routines = 23
~~~

Accepted residual register:

- `RR-01`: 9 privileged candidates with effective anon EXECUTE in accepted evidence:
  `alterar_plano_empresa_root`, `atualizar_status_empresa_root`, `simular_troca_plano_empresa_root`,
  `importar_mesa_cliente_disponibilidade_oficial`, `mesa_cliente_upsert_faixas_premio`,
  `mesa_cliente_upsert_politica_financeira`, `salvar_mesa_cliente_desconto_politica`,
  `mesa_cliente_listar_politicas_financeiras`, `mesa_cliente_obter_politica_financeira`.
- `RR-02`: legacy root inheritance remains.
- `RR-03`: broad gestor/admin compatibility helpers remain.
- `RR-04`: 13 callerless privileged candidates remain `BLOCKED_PENDING_EVIDENCE`.
- `RR-05`: 4 DB-internal privileged routines require direct-role reachability convergence.
- `RR-06`: T3 service owner/current E2E/revoke-kill assurance remains incomplete.
- `RR-07`: `gerenciar_lista` APP provenance versus authenticated EXECUTE contradiction remains.

No residual above authorizes a GRANT, REVOKE, function-body change or runtime test.

## 6. Downstream ownership

~~~text
M3-03 downstream remediation:
RPC EXECUTE convergence
per-RPC frozen authority guards
internal-only reachability
callerless lifecycle
root grant convergence
caller/ACL contradictions

M3-04:
sensitive direct table DML
RLS / table grants / policies
RPC-only replacement boundaries for direct DML

M3-05:
Auth/Admin lifecycle
legacy root source
corretores role/flags
role/team transitions
criar-usuario
T3 admin reset compatibility

BG-06:
exceptional root tenant support
PARKED / NOT_AUTHORIZED

M3-06:
hostile-client / cross-tenant / team / ownership
inactive principal
root-without-support
service-only
concurrency/runtime assurance
~~~

## 7. Next Product Authority state

Product Authority also decides:

~~~text
STS-M3-04 — Redução de DML sensível direto
= AUTHORIZED / NOT_INITIATED
~~~

Task authorization does not mean execution started. The executing conversation must resolve live main/bootstrap before initiation. Concrete runtime, Supabase, SQL, DDL/DML, migration, RLS, policy, grant, RPC/function or data mutation remains subject to exact scoped authorization and rollback.

## 8. Non-claims

~~~text
M3-03 ACCEPTED != IMPLEMENTATION COMPLETE
ALLOWLIST COMPLETE != ACL/GRANTS COMPLIANT
DOCUMENTED != APPLIED
MERGED != DEPLOYED
READ_ONLY ANALYSIS != HOSTILE RUNTIME PASS
M3-04 AUTHORIZED != M3-04 INITIATED
M3-04 AUTHORIZED != BLANKET MUTATION AUTHORITY
SECURITY GO = NOT_GRANTED
COMMERCIALIZATION AUTHORIZATION = NOT_GRANTED
~~~

Rollback for this publication is a revert of its single documentation commit.
