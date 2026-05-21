# FECH.AI / MesaCliente — Fase 7

## 15B — Execução oficial aprovada

### Arquivo oficial

```text
supabase/tests/mesa-cliente/engenharia-financeira/15b_validacao_aplicacao_operacao_financeira_admin_rollback.sql
```

### Status

**APROVADO.**

O resultado apareceu encapsulado em uma única coluna `resultado_15b`. Isso não reprova o teste: o conteúdo interno retornou todos os blocos esperados com `PASS` e o aviso final de `ROLLBACK`.

### Observação sobre formato de saída

O arquivo atual encerra com:

```sql
select current_setting('app.mc15b.results', true)::jsonb as resultado_15b;
```

Por isso o Supabase SQL Editor exibiu um único objeto contendo o array completo. Funcionalmente está correto, mas o formato é menos amigável do que o padrão linha a linha usado em outros testes.

### Resultado informado da execução

| Bloco | Status | Leitura técnica |
|---|---:|---|
| 00_setup_admin_fixture | PASS | Fixture administrativa criada com user, política, simulação e 3 faixas. |
| 01_agenda_parcela_fixture | PASS | Agenda e parcela origem criadas pela 4B. |
| 02_operacao_confirmada_fixture | PASS | Operação criada pela 5B e confirmada pela 5C. |
| 03_rpc_aplicacao_basico | PASS | RPC da Fase 7 executou com `readonly=false` e `dml_financeiro=true`. |
| 04_operacao_aplicada_persistida_na_transacao | PASS | Operação ficou `aplicada`, confirmada, invisível para cliente e com metadata da Fase 7. |
| 05_parcela_origem_alterada_corretamente | PASS | Parcela origem foi reduzida corretamente. |
| 06_agenda_metadata_totais_atualizados | PASS | Agenda recebeu delta, operação vinculada e metadata da aplicação. |
| 99_rollback_notice | INFO | Teste encerra com `ROLLBACK`; fixture e aplicação não devem persistir. |

### Evidências da execução

```text
user_id = 82373656-1f76-4411-a78a-3588531163e7
simulacao_id = 7110ead0-903e-4d43-b101-576c79980527
politica_id = be2f0db4-2422-4e94-9d3f-c016c57c9f73
agenda_id = ea6c966b-d643-4faa-b6bf-59edd0d303c4
parcela_id = 59aff2ea-56a0-43cf-94f4-05c6ddc27362
operacao_id = 1c868ea6-c3c0-4856-af8a-56b014a57f9a
```

### Evidências financeiras críticas

```text
status_operacao_anterior = confirmada
status_operacao_final = aplicada
readonly = false
dml_financeiro = true
valor_parcela_antes = 3000.00
valor_movido = 3000.00
valor_parcela_depois = 0.00
data_antes = 2028-06-20
data_depois = 2028-06-20
agenda_delta = -3000.00
operacoes_antes = 1
operacoes_depois = 1
parcelas_antes = 8
parcelas_depois = 8
visivel_cliente = false
metadata_fase_7_aplicacao = true
agenda_metadata_fase_7 = true
```

### Interpretação técnica

O 15B validou o caminho positivo da Fase 7:

```text
fixture admin -> 4B agenda/parcela -> 5B operação -> 5C confirmação -> 7 aplicação -> rollback
```

A aplicação financeira ocorreu somente dentro da transação do teste. A operação foi marcada como `aplicada`, a parcela origem foi reduzida de `3000.00` para `0.00`, a agenda recebeu metadata/totais da aplicação, e não houve criação/remoção indevida de parcelas ou operações.

### Decisão

O 15B está oficialmente aprovado e documentado.

O formato de saída em `resultado_15b` é aceitável para validação, mas pode ser ajustado depois para retorno linha a linha caso seja desejável padronizar a leitura no Supabase SQL Editor.
