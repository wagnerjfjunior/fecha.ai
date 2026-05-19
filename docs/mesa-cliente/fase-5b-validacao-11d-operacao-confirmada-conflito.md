# FECH.AI / MesaCliente — Fase 5B — Validação 11D

**Status:** aprovado  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Fase:** 5B — registro administrativo de operação financeira  
**Teste executado:** `supabase/tests/mesa-cliente/engenharia-financeira/11d_validacao_registro_operacao_financeira_confirmada_rollback.sql`  
**Data:** 2026-05-19

---

## 1. Veredito executivo

O teste 11D foi **aprovado**.

A RPC 5B respeitou uma operação financeira já confirmada: reaproveitou a mesma operação quando a chamada repetiu o mesmo checksum canônico e bloqueou uma tentativa conflitante para a mesma parcela/simulação com `SQLSTATE 55000`.

Resultado oficial:

```text
11D = PASS
```

---

## 2. Contrato validado

O 11D validou:

```text
operação simulada criada pela RPC 5B
operação marcada como confirmada por fixture transacional controlada
mesma chamada canônica reaproveita operação confirmada
chamada conflitante contra operação confirmada é bloqueada
operação confirmada permanece preservada
não há duplicidade em mesa_cliente_fluxo_operacoes
agenda não é mutada
parcelas não são mutadas
flags do contrato 5B são preservadas
rollback final executado
```

---

## 3. Operação confirmada por fixture transacional

Resultado:

```text
01_operacao_confirmada_fixture = PASS
```

A RPC 5B criou primeiro uma operação simulada:

```text
operacao_id = 5ce9f0c8-157d-4696-93ac-66cd2db57a0d
agenda_id = ecfc3a1e-bebd-4ef8-ac88-401bc7cd6b4d
parcela_origem_id = 64ca59c5-849e-4277-9ccf-1a861109e4fd
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
checksum_operacao = 13210baf4f0b357577b8910b087e62d2
```

Depois, dentro do próprio teste e ainda sob transação, a operação foi marcada como confirmada:

```text
status_operacao = confirmada
confirmado = true
confirmado_por = 82373656-1f76-4411-a78a-3588531163e7
visivel_cliente = false
checksum_operacao = 13210baf4f0b357577b8910b087e62d2
```

Importante:

```text
Esta confirmação é fixture transacional de teste.
Não implementa a Fase 5C.
```

---

## 4. Reaproveitamento da confirmada pelo mesmo checksum

Resultado:

```text
02_mesmo_checksum_reaproveitou_confirmada = PASS
```

Evidências:

```text
idempotente_mesmo_checksum = true
operacao_id_criacao = 5ce9f0c8-157d-4696-93ac-66cd2db57a0d
operacao_id_reaproveitada = 5ce9f0c8-157d-4696-93ac-66cd2db57a0d
checksum_criacao = 13210baf4f0b357577b8910b087e62d2
checksum_reaproveitado = 13210baf4f0b357577b8910b087e62d2
status_reaproveitado = confirmada
confirmado_reaproveitado = true
```

Interpretação:

```text
A RPC não criou nova operação. Ela reconheceu a operação confirmada existente pelo checksum canônico.
```

---

## 5. Conflito contra operação confirmada bloqueado

Resultado:

```text
03_conflito_confirmada_bloqueado = PASS
```

Evidência:

```text
SQLSTATE = 55000
Mensagem = Operação financeira bloqueada: já existe operação confirmada conflitante para esta parcela/simulação.
```

Interpretação:

```text
A RPC impede registrar outra operação conflitante para a mesma parcela/simulação quando já existe operação confirmada.
```

Este é o ponto mais importante do 11D: a operação confirmada vira uma trava de integridade financeira.

---

## 6. Operação confirmada preservada sem duplicidade

Resultado:

```text
04_operacao_confirmada_preservada_sem_duplicidade = PASS
```

Evidências:

```text
operacoes = 1
operacoes_confirmadas = 1
operacao_id_original = 5ce9f0c8-157d-4696-93ac-66cd2db57a0d
checksum_original = 13210baf4f0b357577b8910b087e62d2
status_operacao = confirmada
confirmado = true
valor_movido = 5000
```

Interpretação:

```text
A tentativa conflitante não criou duplicidade e não alterou a operação confirmada já existente.
```

---

## 7. Agenda e parcelas preservadas

Resultado:

```text
05_agenda_parcelas_nao_mutadas = PASS
```

Evidências:

```text
agenda_id_before = agenda_id_after = ecfc3a1e-bebd-4ef8-ac88-401bc7cd6b4d
checksum_before = checksum_after = 73dab70eba94f402122a58f62361713e
parcelas_before = parcelas_after = 6
valor_total_parcelas_before = valor_total_parcelas_after = 29500.50
totais_iguais = true
```

Interpretação:

```text
A validação de conflito não altera agenda, não recria parcelas e não muda totais.
```

---

## 8. Flags do contrato 5B preservadas

Resultado:

```text
06_flags_contrato_5b_preservadas_no_reaproveitamento = PASS
```

Flags observadas:

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
A 5B continua sendo administrativa e persistente apenas no escopo de operação financeira, sem mutar agenda ou parcelas.
```

---

## 9. Rollback

O teste encerrou com:

```text
ROLLBACK
```

Mensagem registrada:

```text
Teste 11D encerra com ROLLBACK. Nada deve permanecer no banco.
```

---

## 10. Estado da Fase 5B após o 11D

```text
Preflight 11 = aprovado com WARN estrutural esperado
Migration 5B = executada com sucesso
11A positivo = aprovado
11B negativos/segurança = aprovado
11C idempotência = aprovado
11D operação confirmada/conflito = aprovado
11E zero mutação agenda/parcelas = próximo teste
```

---

## 11. Próximo passo

Criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql
```

Objetivo do 11E:

```text
validar zero mutação rígido em agenda e parcelas
comparar snapshots antes/depois de operações 5B
provar que somente mesa_cliente_fluxo_operacoes recebe DML financeiro
provar que agenda_id, checksum, totais, parcelas e valores permanecem intactos
encerrar com rollback
```
