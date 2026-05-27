# FECH.AI / MesaCliente — Fase 20C.1
# Relatório — Preflight de Estado Real e Reconciliação GitHub x Supabase

## 1. Status

```text
Status: PARCIAL / READ-ONLY
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Banco: PostgreSQL 17.6.1.104
Região: sa-east-1
Branch GitHub: feature/mesa-cliente-20c-rastreabilidade-valores
DDL executado: NÃO
DML executado: NÃO
Migration criada: NÃO
RPC alterada: NÃO
Frontend alterado: NÃO
```

Este relatório consolida o primeiro inventário read-only da Fase 20C.1.

## 2. Escopo executado

Foram executadas consultas read-only de catálogo e contagem para:

```text
- existência de tabelas críticas;
- RLS enabled/forced;
- contagem estimada de linhas;
- colunas reais de tabelas financeiras/históricas;
- existência e assinatura de RPCs críticas;
- grants EXECUTE de RPCs críticas;
- policies das tabelas críticas;
- grants diretos de tabelas críticas;
- migrations aplicadas no Supabase;
- contagem real de massa nas tabelas de simulação/fluxo/agendas/operações.
```

## 3. Projeto Supabase identificado

```text
Nome: Discador-MesaCliente
Ref: uobxxgzshrmbtjfdolxd
Status: ACTIVE_HEALTHY
Banco: PostgreSQL 17.6.1.104
```

## 4. Tabelas críticas encontradas

Todas as tabelas consultadas abaixo existem no schema `public`.

| Tabela | Existe | RLS | Forced RLS | Linhas estimadas | Colunas | Constraints |
|---|---:|---:|---:|---:|---:|---:|
| `audit_logs` | Sim | Sim | Sim | 51 | 20 | 2 |
| `corretores` | Sim | Sim | Sim | 19 | 18 | 8 |
| `empreendimentos` | Sim | Sim | Sim | -1 | 12 | 3 |
| `empresas` | Sim | Sim | Sim | -1 | 9 | 3 |
| `mesa_cliente_agendas_financeiras` | Sim | Sim | Sim | 0 | 17 | 10 |
| `mesa_cliente_fluxo_operacoes` | Sim | Sim | Não | 0 | 36 | 14 |
| `mesa_cliente_fluxo_parcelas` | Sim | Sim | Não | 0 | 24 | 8 |
| `mesa_cliente_politica_premio_faixas` | Sim | Sim | Não | 0 | 14 | 5 |
| `mesa_cliente_politicas_financeiras` | Sim | Sim | Não | 0 | 29 | 7 |
| `mesa_fluxo_pagamentos` | Sim | Sim | Sim | 53 | 11 | 3 |
| `mesa_simulacoes` | Sim | Sim | Sim | 11 | 29 | 9 |
| `unidades_estoque` | Sim | Sim | Sim | 3972 | 25 | 4 |

Observação técnica:

```text
As tabelas canônicas de engenharia financeira existem, mas aparecem sem massa estimada.
```

## 5. Colunas relevantes confirmadas

### 5.1 `mesa_simulacoes`

Colunas financeiras/históricas confirmadas:

```text
id uuid not null
empresa_id uuid not null
corretor_id uuid
lead_id uuid
empreendimento_id uuid
unidade_estoque_id uuid
cliente_nome text
status mesa_simulacao_status not null
oficial boolean not null
valor_total numeric(14,2)
entrada numeric(14,2)
financiamento numeric(14,2)
valor_final numeric(14,2)
versao integer not null
snapshot_payload jsonb not null
observacoes text
created_at timestamptz not null
updated_at timestamptz not null
```

### 5.2 `mesa_fluxo_pagamentos`

```text
id uuid not null
empresa_id uuid not null
simulacao_id uuid not null
tipo mesa_fluxo_tipo not null
descricao text
valor numeric(14,2)
quantidade integer
periodicidade text
data_prevista date
ordem integer not null
created_at timestamptz not null
```

Fato relevante:

```text
Não existem colunas de valor_original, valor_atual, diferenca_valor ou diferenca_percentual em mesa_fluxo_pagamentos.
```

### 5.3 `mesa_cliente_fluxo_parcelas`

```text
id uuid not null
empresa_id uuid not null
simulacao_id uuid not null
empreendimento_id uuid not null
unidade_estoque_id uuid
grupo text not null
descricao text not null
valor_original numeric(14,2) not null
valor_atual numeric(14,2) not null
data_original date
data_atual date
origem_data mesa_financeira_origem_data not null
regra_data text
ordem integer not null
eh_periodicidade_simbolica boolean not null
pode_receber_vpl boolean not null
pode_receber_antecipacao boolean not null
pode_receber_postergacao boolean not null
metadata jsonb not null
criado_por uuid
atualizado_por uuid
created_at timestamptz not null
updated_at timestamptz not null
agenda_id uuid
```

Fato relevante:

```text
A tabela canônica já contém valor_original e valor_atual.
```

## 6. Massa real encontrada

Contagem real executada:

| Objeto | Total |
|---|---:|
| `mesa_simulacoes` | 14 |
| `mesa_fluxo_pagamentos` | 73 |
| `mesa_cliente_agendas_financeiras` | 0 |
| `mesa_cliente_fluxo_parcelas` | 0 |
| `mesa_cliente_fluxo_operacoes` | 0 |
| `mesa_cliente_politicas_financeiras` | 0 |
| `mesa_cliente_politica_premio_faixas` | 0 |

Classificação:

```text
PASS_DATA_HISTORICO: existe massa para histórico/2ª via.
WARN_DATA_FINANCEIRO_CANONICO: não existe massa nas tabelas canônicas de agenda/parcelas/operações/políticas.
```

Consequência:

```text
Não é possível considerar PASS funcional de engenharia financeira canônica sobre massa real neste momento.
```

## 7. RPCs críticas encontradas

Foram encontradas as seguintes RPCs/funções no schema `public`:

| Função | Assinatura | Retorno | Segurança | Search path |
|---|---|---|---|---|
| `criar_mesa_simulacao` | `p_empresa_id uuid, p_empreendimento_id uuid, p_unidade_id uuid, p_lead_id uuid, p_cliente_nome text, p_valor_total numeric, p_meta_obra_pct integer, p_tabela_provisoria boolean, p_fluxo_json jsonb` | `uuid` | SECURITY DEFINER | `public` |
| `mesa_cliente_aplicar_operacao_financeira_admin` | `p_operacao_id uuid, p_parametros jsonb` | `jsonb` | SECURITY DEFINER | `public, pg_temp` |
| `mesa_cliente_gerar_agenda_financeira_admin` | `p_simulacao_id uuid, p_data_ato date, p_fluxo_json jsonb, p_payload_tabela jsonb` | `jsonb` | SECURITY DEFINER | `public` |
| `mesa_cliente_obter_agenda_financeira_cliente_safe` | `p_simulacao_id uuid` | `jsonb` | SECURITY DEFINER | `public` |
| `mesa_cliente_obter_resumo_operacao_cliente_safe` | `p_operacao_id uuid, p_parametros jsonb` | `jsonb` | SECURITY DEFINER | `public, pg_temp` |
| `mesa_cliente_obter_simulacao_fluxo_historico` | `p_simulacao_id uuid, p_parametros jsonb` | `jsonb` | SECURITY DEFINER | `public` |
| `mesa_cliente_persistir_agenda_financeira_admin` | `p_simulacao_id uuid, p_data_ato date, p_fluxo_json jsonb, p_payload_tabela jsonb` | `jsonb` | SECURITY DEFINER | `public` |
| `mesa_cliente_registrar_operacao_financeira_admin` | `p_simulacao_id uuid, p_agenda_id uuid, p_tipo_operacao text, p_parcela_id uuid, p_data_referencia date, p_data_destino date, p_valor_operacao numeric, p_parametros jsonb` | `jsonb` | SECURITY DEFINER | `public, pg_temp` |
| `mesa_cliente_resumir_operacao_financeira_admin` | `p_operacao_id uuid, p_parametros jsonb` | `jsonb` | SECURITY DEFINER | `public, pg_temp` |

Classificação:

```text
PASS_RPC_EXISTENCE: RPCs críticas existem no banco real.
```

## 8. Grants EXECUTE das RPCs

Todas as RPCs críticas inventariadas possuem `EXECUTE` para:

```text
authenticated
postgres
service_role
```

Não apareceu `anon` na consulta de grants das RPCs críticas.

Classificação:

```text
PASS_RPC_ANON: anon não apareceu com EXECUTE nas RPCs críticas consultadas.
WARN_RPC_ADMIN: RPCs administrativas financeiras estão liberadas para authenticated, dependendo de validação interna forte por auth.uid()/perfil/empresa.
```

Observação:

```text
Como as funções são SECURITY DEFINER, a segurança real depende do corpo da função, validações internas, grants e RLS. Este relatório ainda não validou integralmente o corpo de todas as funções.
```

## 9. Policies/RLS observadas

### 9.1 Histórico atual

`mesa_simulacoes`:

```text
policy: mesa_simulacoes_select
roles: authenticated
cmd: SELECT
qual: is_root() OR empresa_id = my_empresa_id()
```

`mesa_fluxo_pagamentos`:

```text
policy: mesa_fluxo_select
roles: authenticated
cmd: SELECT
qual: is_root() OR empresa_id = my_empresa_id()
```

Observação:

```text
A visibilidade refinada de dono/time/gestor da 2ª via é aplicada pela RPC de histórico, não apenas por policy simples da tabela.
```

### 9.2 Engenharia financeira canônica

`mesa_cliente_fluxo_parcelas`, `mesa_cliente_fluxo_operacoes`, `mesa_cliente_politicas_financeiras` e `mesa_cliente_politica_premio_faixas` possuem:

```text
SELECT por tenant/authenticated;
INSERT/UPDATE/DELETE diretos bloqueados por policies com false.
```

Classificação:

```text
PASS_RLS_CANONICO_DML: tabelas canônicas bloqueiam escrita direta via policies.
WARN_RLS_FORCE: algumas tabelas canônicas têm RLS enabled, mas forced RLS = false.
```

## 10. Grants diretos de tabelas

Achados relevantes:

```text
audit_logs: authenticated INSERT/SELECT
corretores: anon SELECT; authenticated SELECT/UPDATE
empresas: authenticated SELECT
mesa_cliente_agendas_financeiras: authenticated SELECT, REFERENCES, TRIGGER, TRUNCATE
mesa_cliente_fluxo_operacoes: authenticated SELECT
mesa_cliente_fluxo_parcelas: authenticated SELECT
mesa_cliente_politica_premio_faixas: authenticated SELECT
mesa_cliente_politicas_financeiras: authenticated SELECT
```

Classificação preliminar:

```text
PASS_FINANCE_DML_DIRECT: não apareceu INSERT/UPDATE/DELETE direto para authenticated nas tabelas canônicas de parcelas/operações/políticas.
WARN_GRANT_AGENDAS: mesa_cliente_agendas_financeiras possui TRUNCATE para authenticated. Precisa validação adicional; pode ser grant excessivo mesmo com RLS.
WARN_GRANT_CORRETORES_ANON_SELECT: corretores possui anon SELECT. Precisa validar se RLS/claims impedem vazamento efetivo.
```

## 11. Migrations aplicadas

As migrations aplicadas no Supabase incluem a cadeia MesaCliente relevante:

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
```

Classificação:

```text
PASS_MIGRATIONS_KEY_CHAIN: a cadeia principal de MesaCliente/engenharia financeira/20A aparece aplicada no Supabase.
WARN_MIGRATIONS_FULL_DIFF: ainda falta comparar a lista completa de arquivos em supabase/migrations no GitHub contra supabase_migrations.schema_migrations.
```

## 12. Achados centrais

### 12.1 Achado 1 — Estrutura canônica existe

A estrutura canônica de engenharia financeira está criada no banco:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_fluxo_operacoes
mesa_cliente_politicas_financeiras
mesa_cliente_politica_premio_faixas
```

### 12.2 Achado 2 — Estrutura canônica está sem massa real

Todas as tabelas canônicas consultadas retornaram total 0.

```text
WARN_DATA_FINANCEIRO_CANONICO
```

### 12.3 Achado 3 — Histórico/2ª via possui massa real

Existem:

```text
14 registros em mesa_simulacoes
73 registros em mesa_fluxo_pagamentos
```

```text
PASS_DATA_HISTORICO
```

### 12.4 Achado 4 — O local canônico de valor_original/valor_atual já existe

`mesa_cliente_fluxo_parcelas` possui:

```text
valor_original numeric(14,2)
valor_atual numeric(14,2)
```

Isto reforça que a rastreabilidade financeira canônica deve preferir essa tabela, salvo decisão explícita de criar camada histórica separada.

### 12.5 Achado 5 — `mesa_fluxo_pagamentos` não carrega rastreabilidade

`mesa_fluxo_pagamentos` possui apenas valor final/quantidade/período/data/ordem.

Isto confirma a limitação da 2ª via atual.

## 13. Classificação de risco atual

```text
Preflight read-only: R1/R2
Qualquer correção de grant/RLS/RPC/migration: R3/R4
Qualquer implementação de rastreabilidade em banco: R3/R4
```

## 14. Bloqueios e WARNs

### BLOCKER atual

```text
Nenhum DDL/DML foi tentado. Nenhum blocker operacional de execução foi produzido nesta etapa parcial.
```

### WARNs atuais

```text
WARN_DATA_FINANCEIRO_CANONICO:
Tabelas canônicas existem, mas estão sem massa real.

WARN_GRANT_AGENDAS:
mesa_cliente_agendas_financeiras possui TRUNCATE para authenticated. Precisa análise antes de qualquer avanço.

WARN_GRANT_CORRETORES_ANON_SELECT:
corretores possui anon SELECT. Precisa confirmar se RLS bloqueia efetivamente anon sem auth.uid().

WARN_RLS_FORCE:
Algumas tabelas financeiras canônicas têm RLS enabled, mas forced RLS = false.

WARN_MIGRATIONS_FULL_DIFF:
Ainda falta comparar lista completa GitHub x migrations aplicadas.

WARN_FUNCTION_BODY_NOT_FULLY_REVIEWED:
Existência, assinatura e grants foram validados, mas o corpo de todas as funções críticas ainda não foi integralmente revisado neste relatório parcial.
```

## 15. Recomendação preliminar

Com base nos dados reais:

```text
A estrutura canônica financeira existe, mas ainda não tem massa.
O histórico/2ª via tem massa real.
A rastreabilidade não deve ser implementada agora sem decidir se será histórica ou canônica.
```

Recomendação de próxima trilha:

```text
C — Piloto controlado de mesa / validação operacional mínima
```

Justificativa:

```text
Antes de criar nova tabela ou evoluir operação financeira, faz mais sentido executar um piloto controlado que gere massa real nas trilhas necessárias e evidencie o próximo gargalo real.
```

Alternativa técnica:

```text
B — Engenharia financeira canônica
```

Somente se a próxima prioridade for popular e validar agenda/parcelas/operações/políticas com massa real controlada.

Não recomendado agora:

```text
A — Implementar rastreabilidade isolada da 2ª via
```

Motivo:

```text
Pode duplicar o papel de valor_original/valor_atual já previsto em mesa_cliente_fluxo_parcelas.
```

## 16. Próximas ações recomendadas

1. Completar full diff GitHub migrations x Supabase migrations.
2. Revisar especificamente grants suspeitos:
   - `mesa_cliente_agendas_financeiras` com `TRUNCATE` para authenticated;
   - `corretores` com `anon SELECT`.
3. Revisar corpo das RPCs financeiras administrativas antes de qualquer uso real.
4. Decidir se vamos preparar piloto controlado para gerar massa canônica.
5. Manter rastreabilidade como pendência mapeada até decisão explícita.

## 17. Status final desta versão

```text
20C.1: PARCIAL
Read-only: SIM
Evidência real: SIM
PASS total: NÃO
Motivo: ainda falta full diff de migrations e revisão de grants/funções suspeitas.
```
