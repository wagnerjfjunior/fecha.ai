# FECH.AI / MesaCliente — Fase 6

## Registro de execução — Preflight 14 read-only

**Arquivo executado:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
```

**Status da execução:** APROVADO

**Classificação técnica:** readiness técnico aprovado para criação controlada da migration/RPCs da Fase 6.

---

## 1. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_tabelas_obrigatorias` | PASS | Todas as tabelas obrigatórias existem |
| `02_funcoes_dependencia` | PASS | Todas as RPCs dependentes existem |
| `03_colunas_operacoes` | PASS | Schema real de operações está compatível com o contrato pós-5D |
| `04_colunas_parcelas` | PASS | Schema real de parcelas está compatível com o contrato pós-4B/5D |
| `05_rls_financeiro` | INFO | RLS ativo nas tabelas avaliadas |
| `06_policies_existentes` | INFO | Policies existentes inventariadas |
| `07_grants_funcoes_dependencia` | INFO | Grants das funções dependentes inventariados |
| `08_campos_sensiveis_para_cliente_safe` | INFO | Campos sensíveis mapeados para bloqueio na visão cliente-safe |
| `09_readiness_fase_6` | PASS | Readiness técnico aprovado |
| `10_probe_operacao_real_mais_recente` | INFO | Sem operação financeira real no ambiente |
| `99_interpretacao_operacional` | INFO | Preflight read-only executado sem DDL/DML/fixture |

---

## 2. Evidências principais

### 2.1 Tabelas obrigatórias

Todas as tabelas exigidas pelo preflight existem:

```text
corretores
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_operacoes
mesa_cliente_fluxo_parcelas
mesa_simulacoes
```

### 2.2 RPCs dependentes

Todas as dependências funcionais existem:

```text
mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)
mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)
mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)
mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)
```

### 2.3 Schema real de operações

O schema real de `mesa_cliente_fluxo_operacoes` está alinhado ao contrato pós-5D.

Campos relevantes confirmados:

```text
valor_movido
valor_base
desconto_calculado
acrescimo_calculado
economia_liquida
dias_calculo
taxa_ano_pct
vpl_aplicado_pct
premio_corretor_pct
status_premio
metadata
checksum_operacao
visivel_cliente
confirmado
status_operacao
agenda_id
parcela_origem_id
parcela_destino_id
```

### 2.4 Schema real de parcelas

O schema real de `mesa_cliente_fluxo_parcelas` está alinhado ao contrato pós-4B/5D.

Campos relevantes confirmados:

```text
valor_original
valor_atual
data_original
data_atual
ordem
eh_periodicidade_simbolica
pode_receber_vpl
pode_receber_antecipacao
pode_receber_postergacao
metadata
agenda_id
```

---

## 3. Segurança e cliente-safe

Campos sensíveis identificados e que não devem vazar em payload cliente-safe:

```text
mesa_cliente_agendas_financeiras.checksum
mesa_cliente_agendas_financeiras.metadata
mesa_cliente_agendas_financeiras.payload_origem
mesa_cliente_fluxo_operacoes.checksum_operacao
mesa_cliente_fluxo_operacoes.metadata
mesa_cliente_fluxo_operacoes.politica_id
mesa_cliente_fluxo_operacoes.premio_corretor_pct
mesa_cliente_fluxo_operacoes.status_premio
mesa_cliente_fluxo_operacoes.taxa_ano_pct
mesa_cliente_fluxo_operacoes.vpl_aplicado_pct
mesa_cliente_fluxo_parcelas.metadata
mesa_cliente_fluxo_parcelas.pode_receber_vpl
```

A Fase 6 deve tratar esses campos como bloqueados na visão cliente-safe.

---

## 4. Readiness técnico

O bloco `09_readiness_fase_6` retornou:

```json
{
  "readiness_tecnico": true,
  "tabelas_ok": true,
  "funcoes_dependencia_ok": true,
  "operacoes_cols_ok": true,
  "parcelas_cols_ok": true,
  "rls_financeiro_ok": true,
  "existe_operacao_real_para_probe": false
}
```

A ausência de operação financeira real não bloqueia a criação da migration/RPCs da Fase 6, pois os testes funcionais 14A+ devem usar fixtures transacionais controladas.

---

## 5. Conclusão

O preflight 14 foi aprovado.

A Fase 6 está liberada para criação controlada da migration e das RPCs de resumo, respeitando o contrato:

```text
read-only
sem alterar agenda
sem alterar parcelas
sem alterar operação
sem recalcular operação
sem registrar operação
sem confirmar/cancelar operação
sem expor campos internos na visão cliente-safe
```

---

## 6. Próxima ação autorizável

Criar a migration da Fase 6 com RPCs read-only separadas:

```text
public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
```

A recomendação é manter RPCs separadas para reduzir risco de vazamento cliente-safe.

Depois da migration, criar e executar:

```text
14a_validacao_resumo_operacao_admin_rollback.sql
14b_validacao_resumo_operacao_cliente_safe_rollback.sql
14c_validacao_negativos_seguranca_resumos_operacao_rollback.sql
14d_validacao_sem_vazamento_cliente_safe_rollback.sql
14e_validacao_zero_dml_readonly_resumos_operacao_rollback.sql
```
