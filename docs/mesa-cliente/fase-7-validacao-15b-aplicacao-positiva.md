# FECH.AI / MesaCliente — Fase 7

## 15B — Aplicação positiva de operação financeira admin

### Arquivo oficial

```text
supabase/tests/mesa-cliente/engenharia-financeira/15b_validacao_aplicacao_operacao_financeira_admin_rollback.sql
```

### Status

**APROVADO em execução ad hoc anterior e agora formalizado em arquivo oficial.**

Este documento corrige o drift documental identificado na Fase 7: o 15B havia sido validado tecnicamente, mas o arquivo oficial não constava na branch.

### Branch

```text
feature/mesa-cliente-pos-fase-6-proxima-fase
```

### Commit do arquivo oficial

```text
642dc31f13d063c778e505a3ba3766482cd60e16
```

### Objetivo

Validar a aplicação positiva da RPC administrativa:

```sql
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

sobre uma operação previamente:

1. criada pela 4B/5B;
2. confirmada pela 5C;
3. aplicada pela Fase 7;
4. revertida ao final por `ROLLBACK`.

### Resultado técnico registrado

| Bloco | Status | Leitura técnica |
|---|---:|---|
| 00_setup_admin_fixture | PASS | Admin/gestor elegível, simulação e política criadas em fixture. |
| 01_agenda_parcela_fixture | PASS | Agenda e parcela origem criadas corretamente pela 4B. |
| 02_operacao_confirmada_fixture | PASS | Operação criada pela 5B e confirmada pela 5C. |
| 03_rpc_aplicacao_basico | PASS | RPC da Fase 7 executou com `dml_financeiro=true`. |
| 04_operacao_aplicada_persistida_na_transacao | PASS | Operação virou `status_operacao='aplicada'` dentro da transação. |
| 05_parcela_origem_alterada_corretamente | PASS | Parcela origem foi reduzida de `3000.00` para `0.00`. |
| 06_agenda_metadata_totais_atualizados | PASS | Agenda recebeu metadata e totais da aplicação. |
| 99_rollback_notice | INFO | Teste encerrou com `ROLLBACK`; nada deve persistir. |

### Evidências críticas

```text
status_operacao_anterior = confirmada
status_operacao_final = aplicada
readonly = false
dml_financeiro = true
valor_parcela_antes = 3000.00
valor_movido = 3000.00
valor_parcela_depois = 0.00
delta agenda = -3000.00
```

### Interpretação

O 15B comprova o caminho feliz da Fase 7: uma operação financeira confirmada pode ser aplicada por admin elegível, gera DML financeiro controlado e altera a parcela origem conforme esperado.

A execução é transacional e termina em `ROLLBACK`, portanto não deve persistir fixture, operação aplicada ou mutação financeira em produção/teste.

### Relação com os demais testes da Fase 7

- 15A valida a constraint com status `aplicada`.
- 15B valida aplicação positiva.
- 15C valida segurança negativa, bloqueios e idempotência.
- 15D valida catálogo/contrato da RPC.
- 15E valida regressão final ponta a ponta.

### Decisão técnica

O drift documental do 15B foi corrigido com a criação do arquivo oficial e deste registro de execução. A documentação principal da Fase 7 pode manter o 15B como `PASS`, desde que o arquivo canônico acima permaneça na branch.
