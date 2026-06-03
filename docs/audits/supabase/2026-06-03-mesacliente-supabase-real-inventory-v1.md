# FECH.AI - Inventario read-only Supabase real MesaCliente v1

**Data:** 2026-06-03
**Status:** `SUPABASE_REAL_READONLY / PENDENTE_RECONCILIACAO_GITHUB`
**Projeto Supabase auditado:** `Discador-MesaCliente`
**Project ref:** `uobxxgzshrmbtjfdolxd`
**Tipo:** documentacao-only / read-only evidence.

---

## 1. Objetivo

Registrar evidencias read-only coletadas diretamente do Supabase real para reconciliar o estado aplicado com as auditorias documentais e de codigo das PRs #52, #53 e #54.

Esta PR nao altera banco, schema, RLS, FORCE RLS, policies, grants, functions, migrations, parser, motor financeiro, frontend, Vercel, GitHub Actions, Worker, Make/n8n, integracoes reais ou producao.

---

## 2. Escopo executado

Consultas read-only executadas no projeto `Discador-MesaCliente`:

```text
project discovery
RLS e FORCE RLS por tabela via pg_class
policies por tabela via pg_policies
grants de routines via information_schema.routine_privileges
grants de tabelas via information_schema.table_privileges
functions/RPCs via pg_proc
migrations aplicadas via Supabase API list_migrations
colunas de tabelas MesaCliente via information_schema.columns
```

Status:

```text
READ_ONLY_EXECUTADO
SEM_DDL
SEM_DML
SEM_MIGRATION
SEM_GRANT
SEM_POLICY_CHANGE
SEM_DEPLOY
```

---

## 3. Projeto Supabase identificado

| Campo | Valor |
|---|---|
| Nome | `Discador-MesaCliente` |
| Project ref | `uobxxgzshrmbtjfdolxd` |
| Regiao | `sa-east-1` |
| Status | `ACTIVE_HEALTHY` |
| Postgres | `17.6.1.104` |

---

## 4. Resultado - RLS e FORCE RLS

Todas as tabelas MesaCliente retornadas pela consulta possuem RLS habilitado. FORCE RLS esta habilitado somente em parte delas.

| Tabela | RLS | FORCE RLS | Observacao |
|---|---:|---:|---|
| `mesa_arquivos` | true | true | OK RLS forte |
| `mesa_cliente_agendas_financeiras` | true | true | OK RLS forte; esperado pela Fase 4B |
| `mesa_cliente_desconto_politicas` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_cliente_fluxo_operacoes` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_cliente_fluxo_parcelas` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_cliente_politica_premio_faixas` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_cliente_politicas_financeiras` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_cliente_unidade_enriquecimentos` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_eventos` | true | true | OK RLS forte |
| `mesa_fluxo_pagamentos` | true | true | OK RLS forte |
| `mesa_fluxo_pagamentos_canonico` | true | false | RLS ativo, FORCE RLS ausente |
| `mesa_simulacoes` | true | true | OK RLS forte |

Classificacao:

```text
POSITIVO: nenhuma tabela MesaCliente retornou RLS=false.
ATENCAO: FORCE RLS=false em varias tabelas financeiras criticas.
PENDENTE: comparar se FORCE RLS=false e intencional ou drift contra migrations.
```

---

## 5. Resultado - policies

Foram encontradas policies de SELECT para `authenticated` nas tabelas principais e policies de bloqueio de DML direto em tabelas financeiras.

Evidencias relevantes:

```text
mesa_cliente_fluxo_operacoes: SELECT tenant + INSERT/UPDATE/DELETE false
mesa_cliente_fluxo_parcelas: SELECT tenant + INSERT/UPDATE/DELETE false
mesa_cliente_politicas_financeiras: SELECT tenant + INSERT/UPDATE/DELETE false
mesa_cliente_politica_premio_faixas: SELECT tenant + INSERT/UPDATE/DELETE false
mesa_cliente_desconto_politicas: SELECT tenant + INSERT/UPDATE/DELETE false
mesa_cliente_agendas_financeiras: SELECT por empresa/root
mesa_simulacoes: SELECT por empresa/root
mesa_arquivos, mesa_eventos, mesa_fluxo_pagamentos: SELECT por empresa/root
```

Classificacao:

```text
POSITIVO: ha padrao claro de SELECT autenticado por tenant/empresa.
POSITIVO: tabelas financeiras sensiveis possuem policies de DML direto com false.
PENDENTE: conferir se todas as tabelas com grants DML para authenticated tambem tem policies adequadas.
```

---

## 6. Resultado - grants de routines

A consulta agregada de grants de routines revelou duas classes:

### 6.1 RPCs sem EXECUTE para anon

Exemplos relevantes:

```text
criar_mesa_simulacao
get_empresa_mesa_config
get_historico_mesas
importar_mesa_cliente_json_admin
importar_mesa_cliente_parser_resultado
mesa_cliente_aplicar_operacao_financeira_admin
mesa_cliente_atualizar_status_operacao_financeira_admin
mesa_cliente_gerar_agenda_financeira_admin
mesa_cliente_listar_operacoes_financeiras_admin
mesa_cliente_obter_agenda_financeira_cliente_safe
mesa_cliente_obter_operacao_financeira_admin
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_obter_simulacao_fluxo_historico
mesa_cliente_persistir_agenda_financeira_admin
mesa_cliente_registrar_operacao_financeira_admin
mesa_cliente_resumir_operacao_financeira_admin
mesa_cliente_simular_impacto_agenda_persistida_admin
mesa_cliente_simular_impacto_financeiro_admin
usuario_pode_importar_mesa_json_admin
```

Classificacao:

```text
POSITIVO: principais RPCs administrativas/financeiras criticas listadas acima nao possuem anon EXECUTE.
```

### 6.2 RPCs/functions com EXECUTE para anon

Foram encontradas functions/RPCs MesaCliente com `anon` EXECUTE, incluindo:

```text
aprovar_rejeitar_mesa
get_empreendimentos_mesa
get_mesa_cliente_desconto_politica
get_unidades_mesa
importar_mesa_cliente_disponibilidade_oficial
mesa_cliente_assert_auth
mesa_cliente_assert_empreendimento_empresa
mesa_cliente_can_access_empresa
mesa_cliente_can_admin_empresa
mesa_cliente_current_corretor_context
mesa_cliente_financeiro_assert_calculo_input
mesa_cliente_financeiro_assert_integridade
mesa_cliente_financeiro_calcular_antecipacao_composta
mesa_cliente_financeiro_calcular_postergacao_composta
mesa_cliente_financeiro_calcular_vpl_parcela
mesa_cliente_financeiro_dias_entre
mesa_cliente_financeiro_fator_composto
mesa_cliente_financeiro_valor_futuro_composto
mesa_cliente_financeiro_valor_presente_composto
mesa_cliente_listar_politicas_financeiras
mesa_cliente_obter_politica_financeira
mesa_cliente_upsert_faixas_premio
mesa_cliente_upsert_politica_financeira
registrar_upload_arquivo_mesa
salvar_mesa_cliente_desconto_politica
salvar_mesa_cliente_enriquecimento
validar_mesa_cliente_desconto
```

Classificacao inicial:

```text
P0/P1 A VALIDAR: functions com anon EXECUTE precisam ser classificadas individualmente.
P0: qualquer function de escrita, aprovacao, upload, importacao, upsert, salvar ou politica com anon EXECUTE deve ser tratada como possivel bloqueio ate leitura do body real e teste negativo.
P2/P1: functions puramente matematicas podem ser aceitaveis se nao acessarem dados sensiveis, mas isso ainda precisa ser confirmado.
```

---

## 7. Resultado - functions/RPCs

A consulta via `pg_proc` retornou functions com:

```text
schema
function_name
args
result
security_definer
volatility
owner
function_config
function_def_hash
```

Achados gerais:

```text
- Muitas RPCs criticas sao SECURITY DEFINER owner postgres.
- Varias possuem search_path=public ou search_path=public, pg_temp.
- Functions financeiras matematicas aparecem como security_definer=false e volatility immutable.
- RPCs administrativas e de DML financeiro aparecem como security_definer=true.
- Hashes md5 foram coletados para reconciliacao futura com pg_get_functiondef e migrations GitHub.
```

Classificacao:

```text
POSITIVO: inventario real permite reconciliar assinatura/hash com GitHub.
PENDENTE: body completo nao foi documentado nesta PR para evitar excesso e deve ser comparado em matriz dedicada.
```

---

## 8. Resultado - grants de tabelas

Achados relevantes:

```text
- Tabelas financeiras criticas como agendas, fluxo_operacoes, fluxo_parcelas, politicas_financeiras e faixas_premio apresentam SELECT para authenticated e DML amplo para postgres/service_role.
- `mesa_cliente_unidade_enriquecimentos` apresenta DELETE/INSERT/SELECT/UPDATE para authenticated.
- Demais resultados extensos foram coletados e devem ser reconciliados em matriz especifica.
```

Classificacao:

```text
POSITIVO: em tabelas financeiras criticas, authenticated aparece principalmente com SELECT.
ATENCAO: `mesa_cliente_unidade_enriquecimentos` possui DML direto para authenticated; precisa validar policies, intencao funcional e risco.
PENDENTE: consolidar tabela x grantee x privilege em planilha/matriz posterior.
```

---

## 9. Resultado - migrations aplicadas

A API Supabase listou migrations aplicadas. Migrations MesaCliente relevantes presentes incluem:

```text
20260514162510 mesa_cliente_rpcs_v1
20260514225108 mesa_cliente_parser_unidades_preview_v1
20260514225343 mesa_cliente_parser_unidades_preview_v1
20260515000809 fix_mesa_cliente_rpcs_sem_perfis
20260515005535 mesa_cliente_importar_parser_resultado_v1
20260516022927 fix_mesa_cliente_enviado_por_fk
20260517131835 mesa_cliente_desconto_politicas_seguras
20260517162055 mesa_cliente_engenharia_financeira_base
20260517162147 mesa_cliente_engenharia_financeira_hardening_grants
20260517172347 mesa_cliente_engenharia_financeira_base_compat
20260521022845 mesa_cliente_fase_7_aplicar_operacao_financeira_admin
20260521151003 mesa_cliente_import_json_admin_minimal
20260521151321 mesa_cliente_import_json_admin_wrapper
20260523151802 mesa_cliente_fase_8_hardening_revoke_anon_import_json_admin
20260526035159 mesa_cliente_20a_obter_simulacao_fluxo_historico
20260526043529 mesa_cliente_20a_revoke_anon_obter_simulacao_fluxo_historico
20260526043736 mesa_cliente_20a_revoke_public_exec_obter_simulacao_fluxo_historico
20260526100451 mesa_cliente_20a1_hardening_fluxo_historico_tenant_time_owner
20260526112959 mesa_cliente_20a2_precedencia_owner_fluxo_historico
20260526121235 mesa_cliente_20a3_hardening_historico_mesas_owner_time
20260526121601 mesa_cliente_20a4_bloquear_admin_hibrido_historico_nao_dono
20260526124502 mesa_cliente_20a5_visibilidade_comercial_final
20260527192255 mesa_cliente_20d4_adaptador_agenda_canonica
20260529131349 mesa_cliente_20d5_fluxo_canonico_shadow
```

Classificacao:

```text
POSITIVO: ha migrations MesaCliente aplicadas no Supabase real.
ATENCAO: nomes/versoes reais diferem de alguns nomes GitHub citados na PR #54, exigindo reconciliacao por conteudo/hash e nao apenas por nome.
```

---

## 10. Resultado - colunas reais criticas

Foram confirmadas colunas reais sensiveis em tabelas financeiras, incluindo:

```text
empresa_id
simulacao_id
empreendimento_id
unidade_estoque_id
agenda_id
payload_origem
metadata
totais
checksum
valor_original
valor_atual
valor_movido
valor_base
desconto_calculado
acrescimo_calculado
economia_liquida
premio_corretor_pct
vpl_aplicado_pct
politica_id
taxa_ano_pct
status_operacao
status_premio
confirmado_por
cancelado_por
```

Classificacao:

```text
SENSIVEL / CLIENTE_SAFE_RESTRITO / R4
```

---

## 11. Achados preliminares

### 11.1 Pontos positivos

```text
- Projeto correto identificado e saudavel.
- RLS habilitado em todas as tabelas retornadas pela consulta MesaCliente.
- FORCE RLS habilitado em mesa_simulacoes, mesa_arquivos, mesa_eventos, mesa_fluxo_pagamentos e mesa_cliente_agendas_financeiras.
- Tabelas financeiras criticas possuem policies de SELECT tenant e bloqueio de DML direto via policies false.
- Principais RPCs administrativas/financeiras criticas nao aparecem com anon EXECUTE.
- Migrations MesaCliente existem como aplicadas no Supabase real.
```

### 11.2 Pontos de atencao / possiveis bloqueios

```text
- Varias functions/RPCs MesaCliente possuem anon EXECUTE.
- `aprovar_rejeitar_mesa` aparece com EXECUTE para PUBLIC e anon; pelo nome e risco funcional, isso exige leitura imediata do body e teste negativo antes de qualquer implementacao.
- `importar_mesa_cliente_disponibilidade_oficial` aparece com anon EXECUTE; exige classificacao P0/P1.
- Functions de politica financeira/upsert/salvar aparecem com anon EXECUTE; exige leitura do body e grants detalhados.
- FORCE RLS esta false em tabelas financeiras como fluxo_operacoes, fluxo_parcelas e politicas financeiras; precisa comparar se isso e intencional ou drift.
- `mesa_cliente_unidade_enriquecimentos` tem DML direto para authenticated; precisa validacao de policies e escopo funcional.
```

---

## 12. O que nao foi feito nesta PR

```text
Nao foi executado DDL.
Nao foi executado DML.
Nao foi alterado grant.
Nao foi alterada policy.
Nao foi alterado RLS/FORCE RLS.
Nao foi alterada RPC.
Nao foi aplicada migration.
Nao foi gerado payload cliente-safe real.
Nao foi executado teste positivo/negativo.
Nao foi executado teste cross-tenant.
```

---

## 13. Proxima etapa recomendada

Antes de qualquer correcao, abrir etapa de reconciliacao fina:

```text
PR #56 - Matriz de risco Supabase real MesaCliente por RPC/tabela
```

Essa matriz deve classificar cada function com anon EXECUTE:

```text
nome
assinatura
security definer/invoker
search_path
grants
le tabelas?
escreve tabelas?
usa auth.uid()?
valida tenant/empresa?
pode expor cliente-safe?
risco P0/P1/P2
status: OK / DRIFT / BLOQUEADO / REQUER_BODY_REVIEW
```

---

## 14. Parecer final

```text
Status: SUPABASE_REAL_READONLY / PENDENTE_RECONCILIACAO_GITHUB
Tipo: documentacao-only / read-only evidence
Implementacao autorizada: NAO
Risco global: P0/P1
Resultado: evidencias reais foram coletadas; ha pontos positivos importantes, mas tambem achados que exigem triagem antes de qualquer implementacao.
Bloqueio principal: functions/RPCs com anon EXECUTE e tabelas financeiras com FORCE RLS=false precisam classificacao detalhada.
```
