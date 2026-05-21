# FECH.AI / MesaCliente — Fase 7

## 15E — Execução oficial aprovada

### Arquivo oficial

```text
supabase/tests/mesa-cliente/engenharia-financeira/15e_regressao_final_aplicacao_operacao_financeira_admin_rollback.sql
```

### Status

**APROVADO.**

Este é o 15E canônico da Fase 7.

### Resultado informado da execução

| Bloco | Status | Leitura técnica |
|---|---:|---|
| 00_setup_admin_fixture | PASS | Fixture transacional criada com admin, política e faixas. |
| 01_agenda_parcela_4b_fixture | PASS | Agenda/parcela criadas pela 4B. |
| 02_operacao_5b_5c_confirmada_liberada | PASS | Operação registrada pela 5B, confirmada pela 5C e liberada para cliente-safe na fixture. |
| 03_resumos_fase_6_pre_aplicacao | PASS | Resumo admin e cliente-safe funcionando antes da aplicação. |
| 04_cliente_safe_pre_aplicacao_sem_vazamento | PASS | Payload cliente-safe sem campos internos/sensíveis. |
| 05_rpc_7_aplicacao_final | PASS | RPC da Fase 7 aplicou operação confirmada e mudou status para aplicada. |
| 06_mutacao_financeira_controlada | PASS | Mutação controlada validada: parcela de 3000.00 para 0.00, sem criar/remover parcelas/operações. |
| 07_resumo_admin_pos_aplicacao | PASS | Resumo admin pós-aplicação funcionando e read-only. |
| 08_cliente_safe_pos_aplicacao_gate_ou_sem_vazamento | PASS | Cliente-safe pós-aplicação bloqueado corretamente por cliente_safe_not_released. |
| 09_readiness_fechamento_fase_7 | PASS | Fase 7 tecnicamente pronta para fechamento. |
| 99_rollback_notice | INFO | Teste encerra com ROLLBACK; fixture não persiste. |

### Evidências críticas

```text
status_operacao_anterior = confirmada
status_operacao_final = aplicada
readonly = false
dml_financeiro = true
valor_parcela_antes = 3000.00
valor_movido = 3000.00
valor_parcela_depois = 0.00
operacoes_antes = 1
operacoes_depois = 1
parcelas_antes = 8
parcelas_depois = 8
visivel_cliente_pos_aplicacao = false
cliente_safe_pos_aplicacao = cliente_safe_not_released
```

### Interpretação

A Fase 7 validou o fluxo completo:

```text
4B -> 5B -> 5C -> release fixture -> 6 admin/cliente-safe -> 7 aplicar -> 6 pós-aplicação
```

A aplicação financeira foi validada dentro de transação com ROLLBACK, com DML controlado, sem vazamento cliente-safe e sem duplicidade de parcelas/operações.

### Arquivo duplicado identificado

Foi identificado um segundo arquivo com nome semelhante:

```text
supabase/tests/mesa-cliente/engenharia-financeira/15e_regressao_final_aplicacao_operacao_fase_7_rollback.sql
```

Esse arquivo **não é o canônico** e apresentou FAIL por validações estruturais incompatíveis com o contrato real:

- bloco `00_contrato_rpc_catalogo` retornou vazio/FAIL;
- bloco `02_schema_minimo_aplicacao` exigiu coluna `payload_resultado`, inexistente e fora do contrato validado;
- bloco `05_readiness_fase_7` falhou como consequência dos FAILs anteriores.

### Decisão técnica

Para continuidade da Fase 7, considerar como válido somente:

```text
15e_regressao_final_aplicacao_operacao_financeira_admin_rollback.sql
```

O arquivo duplicado estrutural deve ser removido ou neutralizado antes da PR para evitar execução acidental e falso negativo.
