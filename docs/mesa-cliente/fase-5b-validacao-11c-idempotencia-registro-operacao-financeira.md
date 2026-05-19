# FECH.AI / MesaCliente — Fase 5B — Validação 11C

**Status:** aprovado  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Fase:** 5B — registro administrativo de operação financeira  
**Teste executado:** `supabase/tests/mesa-cliente/engenharia-financeira/11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql`  
**Data:** 2026-05-19

---

## 1. Veredito executivo

O teste 11C foi **aprovado**.

A RPC 5B demonstrou idempotência correta por `checksum_operacao` calculado no banco: a primeira chamada criou uma operação financeira simulada e a segunda chamada, com os mesmos parâmetros canônicos, reaproveitou exatamente a mesma operação.

Resultado oficial:

```text
11C = PASS
```

---

## 2. Contrato validado

O teste validou os seguintes pontos:

```text
primeira chamada cria operação simulada
segunda chamada reaproveita a mesma operação
checksum_operacao é canônico e calculado no banco
não há duplicidade em mesa_cliente_fluxo_operacoes
agenda não é mutada
parcelas não são mutadas
flags do contrato 5B são preservadas
rollback final executado
```

---

## 3. Primeira chamada

Resultado:

```text
01_primeira_chamada_criou_operacao = PASS
idempotente = false
fase = 5B_REGISTRO_OPERACAO_FINANCEIRA
persistencia = true
dml_financeiro = true
```

A operação criada apresentou:

```text
status_operacao = simulada
confirmado = false
visivel_cliente = false
tipo_operacao = antecipacao
grupo_origem = anual
grupo_destino = entrada
valor_movido = 5000
valor_base = 5000
data_origem = 2099-12-31
data_destino = 2099-05-31
dias_calculo = 214
taxa_ano_pct = 12
desconto_calculado = 321.43
acrescimo_calculado = 0
economia_liquida = 321.43
```

Evidência transacional:

```text
operacao_id = 35f02fa3-ccc1-4142-8c6d-4f9ec9623b5e
agenda_id = 0eeea89d-ee54-423f-a50f-2143a5e406b6
parcela_origem_id = f103c4ab-590e-49c8-9f0a-a12af7e4b542
checksum_operacao = 80d56e05782aa107472bcf346f03c387
```

Os IDs acima são evidências do teste transacional; nada permanece após `ROLLBACK`.

---

## 4. Segunda chamada idempotente

Resultado:

```text
02_segunda_chamada_reaproveitou_operacao = PASS
idempotente_primeira = false
idempotente_segunda = true
operacao_id_primeira = operacao_id_segunda
checksum_primeira = checksum_segunda
```

Valores observados:

```text
operacao_id_primeira = 35f02fa3-ccc1-4142-8c6d-4f9ec9623b5e
operacao_id_segunda = 35f02fa3-ccc1-4142-8c6d-4f9ec9623b5e
checksum_primeira = 80d56e05782aa107472bcf346f03c387
checksum_segunda = 80d56e05782aa107472bcf346f03c387
```

Conclusão:

```text
A segunda chamada não criou nova operação; reutilizou a operação existente pelo checksum canônico.
```

---

## 5. Contagem de operações

Resultado:

```text
03_contagem_operacoes_nao_duplicou = PASS
```

Contagens observadas:

```text
before.operacoes = 0
mid_apos_primeira.operacoes = 1
after_apos_segunda.operacoes = 1
```

Interpretação:

```text
A primeira chamada incrementou 1 operação; a segunda não duplicou.
```

---

## 6. Checksum canônico do banco

Resultado:

```text
04_checksum_operacao_canonico_banco = PASS
```

Evidência:

```text
checksum_primeira = 80d56e05782aa107472bcf346f03c387
checksum_segunda = 80d56e05782aa107472bcf346f03c387
checksums_no_banco = [80d56e05782aa107472bcf346f03c387]
```

Interpretação:

```text
O checksum da operação é soberano do banco/RPC, não do frontend.
```

---

## 7. Agenda e parcelas preservadas

Resultado:

```text
05_agenda_parcelas_nao_mutadas = PASS
```

Evidências:

```text
agenda_id_before = agenda_id_after
checksum_before = checksum_after
parcelas_before = parcelas_after = 6
valor_total_parcelas_before = valor_total_parcelas_after = 29500.50
totais_iguais = true
```

Valores observados:

```text
agenda_id = 0eeea89d-ee54-423f-a50f-2143a5e406b6
agenda_checksum = 31537678c3f8c8390f7f12dcd4118fd6
valor_total = 29500.5
qtd_parcelas = 6
```

Conclusão:

```text
A idempotência da operação financeira não altera a agenda nem recria parcelas.
```

---

## 8. Flags do contrato 5B preservadas

Resultado:

```text
06_flags_contrato_5b_preservadas = PASS
```

Flags observadas na primeira e segunda chamadas:

```text
escopo_dml = operacao_financeira
cliente_safe = false
persistencia = true
altera_agenda = false
dml_financeiro = true
altera_parcelas = false
```

Interpretação:

```text
A RPC permanece administrativa, persistente apenas no escopo de operação financeira e sem mutação de agenda/parcelas.
```

---

## 9. Rollback

O teste encerrou com:

```text
ROLLBACK
```

Mensagem registrada:

```text
Teste 11C encerra com ROLLBACK. Nada deve permanecer no banco.
```

---

## 10. Estado da Fase 5B após o 11C

```text
Preflight 11 = aprovado com WARN estrutural esperado
Migration 5B = executada com sucesso
11A positivo = aprovado
11B negativos/segurança = aprovado
11C idempotência = aprovado
11D operação confirmada/conflito = próximo teste
11E zero mutação agenda/parcelas = pendente
```

---

## 11. Próximo passo

Criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/11d_validacao_registro_operacao_financeira_confirmada_rollback.sql
```

Objetivo do 11D:

```text
validar comportamento da 5B quando já existe operação financeira confirmada
bloquear duplicidade/conflito indevido
preservar operação confirmada
não alterar agenda
não alterar parcelas
encerrar com rollback
```
