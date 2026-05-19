# FECH.AI / MesaCliente — Fase 5B — Validação 11A

**Status:** aprovado  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Fase:** 5B — registro administrativo de operação financeira  
**Teste executado:** `supabase/tests/mesa-cliente/engenharia-financeira/11a_validacao_registro_operacao_financeira_rollback.sql`  
**Data:** 2026-05-19

---

## 1. Veredito executivo

O teste 11A foi **aprovado**.

A RPC 5B registrou uma operação financeira administrativa simulada, vinculada à simulação, agenda e parcela de origem, com checksum de idempotência e sem mutar agenda ou parcelas.

Resultado oficial:

```text
11A = PASS
```

---

## 2. Contrato validado

O retorno básico da RPC confirmou:

```text
fase = 5B_REGISTRO_OPERACAO_FINANCEIRA
visao = administrativa
escopo_dml = operacao_financeira
cliente_safe = false
persistencia = true
dml_financeiro = true
altera_agenda = false
altera_parcelas = false
```

Interpretação:

```text
A 5B grava operação financeira, mas não grava agenda, não recria parcelas e não expõe payload cliente-safe.
```

---

## 3. Operação registrada

A operação criada no teste foi registrada com:

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
checksum_operacao preenchido
agenda_id preenchido
parcela_origem_id preenchido
parcela_destino_id = null
```

Evidência do checksum:

```text
checksum_operacao = 22c5e9666e2316714d0f11259ad95421
```

O teste terminou com `ROLLBACK`, então o ID da operação é apenas evidência transacional, não registro permanente.

---

## 4. DML controlado

A contagem de operações saiu de:

```text
before.operacoes = 0
after.operacoes = 1
```

Isso confirma que o único DML esperado da 5B ocorreu em:

```text
public.mesa_cliente_fluxo_operacoes
```

---

## 5. Agenda e parcelas preservadas

A agenda permaneceu intacta:

```text
agenda_id_before = agenda_id_after
checksum_before = checksum_after
totais_iguais = true
parcelas_before = 6
parcelas_after = 6
```

Valores observados:

```text
agenda_id = afc95fdc-202d-45fa-ac04-6b51221e0670
agenda_checksum = fb583695805bb38bcf1467bf16e87fdc
valor_total = 29500.5
qtd_parcelas = 6
```

Conclusão:

```text
A RPC 5B não mutou agenda e não mutou parcelas.
```

---

## 6. Cálculo financeiro validado

O cálculo retornado pela operação foi coerente com a política financeira:

```text
metodo_calculo = composto
base_tempo = dias_365
taxa_antecipacao_ano_pct = 12
taxa_postergacao_ano_pct = 12
vpl_max_pct = 6
```

Resultado do motor:

```text
valor_original = 5000
valor_calculado = 4678.57
desconto_calculado = 321.43
economia_liquida = 321.43
impacto_pct = 6.4286
dias_calculo = 214
```

---

## 7. Correção aplicada antes da aprovação

Durante a primeira execução do 11A, o fixture tentava criar uma quarta faixa de prêmio:

```text
6.01 até 999
```

O banco bloqueou corretamente pela constraint:

```text
mesa_premio_faixas_intervalo_check
```

Correção aplicada no teste:

```text
remover a faixa acima do limite operacional
manter apenas 3 faixas válidas dentro de vpl_max_pct = 6
```

Faixas finais usadas:

```text
0.00 até 2.00
2.01 até 4.00
4.01 até 6.00
```

---

## 8. Estado da Fase 5B após o 11A

```text
Preflight 11 = aprovado com WARN estrutural esperado
Migration 5B = executada com sucesso
11A positivo = aprovado
11B negativos = próximo teste
11C idempotência = pendente
11D operação confirmada/conflito = pendente
11E zero mutação agenda/parcelas = pendente
```

---

## 9. Próximo passo

Executar o teste negativo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/11b_validacao_registro_operacao_financeira_negativos_rollback.sql
```

A 5B só deve ser considerada aprovada após validar também bloqueios, idempotência, conflito com operação confirmada e ausência de mutação indevida em agenda/parcelas.

