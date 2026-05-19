# FECH.AI / MesaCliente — Fase 5B — Validação 11B

**Status:** aprovado  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Fase:** 5B — registro administrativo de operação financeira  
**Teste executado:** `supabase/tests/mesa-cliente/engenharia-financeira/11b_validacao_registro_operacao_financeira_negativos_rollback.sql`  
**Data:** 2026-05-19

---

## 1. Veredito executivo

O teste 11B foi **aprovado**.

A RPC 5B bloqueou corretamente chamadas sem autorização, referências inexistentes, campos soberanos enviados pelo frontend, valores inválidos, tipo de operação inválido, parâmetros fora do contrato, postergação sem data de destino e operação em parcela simbólica.

Resultado oficial:

```text
11B = PASS
```

---

## 2. Contrato de segurança validado

A validação negativa confirmou que:

```text
anon não tem EXECUTE
usuário sem auth é bloqueado
simulação inexistente é bloqueada
agenda inexistente é bloqueada
parcela inexistente na agenda é bloqueada
campos soberanos do frontend são bloqueados
valor negativo é bloqueado
tipo de operação inválido é bloqueado
p_parametros não objeto é bloqueado
postergação sem data_destino é bloqueada
parcela simbólica é bloqueada
nenhuma operação financeira foi criada pelos negativos
```

---

## 3. Bloqueios de acesso

### 3.1 `anon` sem permissão de execução

Resultado:

```text
01_grant_anon_bloqueado = PASS
anon_can_execute = false
```

Interpretação:

```text
A RPC 5B não está exposta para anon.
```

### 3.2 chamada sem autenticação

Resultado:

```text
02_sem_auth_bloqueado = PASS
SQLSTATE = 28000
Mensagem = Acesso negado: usuário autenticado obrigatório para registrar operação financeira.
```

Interpretação:

```text
A RPC exige usuário autenticado antes de registrar qualquer operação financeira.
```

---

## 4. Bloqueios de referência soberana

A RPC bloqueou referências inexistentes:

```text
03_simulacao_inexistente_bloqueada = PASS | SQLSTATE P0002
04_agenda_inexistente_bloqueada = PASS | SQLSTATE P0002
05_parcela_inexistente_bloqueada = PASS | SQLSTATE P0002
```

Mensagens observadas:

```text
Simulação não encontrada.
Agenda financeira ativa não encontrada para a simulação.
Parcela financeira não encontrada na agenda informada.
```

Interpretação:

```text
A 5B valida simulação, agenda ativa e parcela pertencente à agenda antes de registrar a operação.
```

---

## 5. Campos soberanos bloqueados no payload

A RPC bloqueou campos que não podem ser enviados como autoridade pelo frontend:

```text
06_empresa_id_payload_bloqueado = PASS | SQLSTATE 42501
07_taxa_payload_bloqueada = PASS | SQLSTATE 42501
08_status_payload_bloqueado = PASS | SQLSTATE 42501
09_checksum_payload_bloqueado = PASS | SQLSTATE 42501
```

Mensagens observadas:

```text
empresa_id não pode ser enviado como autoridade pelo frontend.
taxa_ano_pct não pode ser enviado como autoridade pelo frontend.
status_operacao não pode ser enviado como autoridade pelo frontend.
checksum_operacao não pode ser enviado como autoridade pelo frontend.
```

Interpretação:

```text
Empresa, taxa, status e checksum continuam soberanos do banco/RPC. O frontend não define autoridade financeira.
```

---

## 6. Bloqueios de valores, modo e contrato de entrada

Resultado:

```text
10_valor_negativo_bloqueado = PASS | SQLSTATE 22023
11_tipo_operacao_invalido_bloqueado = PASS | SQLSTATE 22023
12_parametros_nao_objeto_bloqueado = PASS | SQLSTATE 22023
13_postergacao_sem_data_destino_bloqueada = PASS | SQLSTATE 22023
```

Mensagens observadas:

```text
Valor da operação financeira não pode ser negativo.
Tipo de operação inválido para registro financeiro 5B.
p_parametros deve ser um objeto JSON.
p_data_destino é obrigatório para postergação.
```

Interpretação:

```text
A RPC 5B aplica validação semântica antes do DML financeiro.
```

---

## 7. Parcela simbólica bloqueada

Resultado:

```text
14_parcela_simbolica_bloqueada = PASS | SQLSTATE 22023
```

Mensagem observada:

```text
Parcela de periodicidade simbólica não pode receber operação financeira.
```

Interpretação:

```text
Periodicidade simbólica continua sendo marcador de agenda, não parcela financeira negociável.
```

---

## 8. Zero DML nos cenários negativos

Resultado:

```text
15_zero_operacoes_criadas_pelos_negativos = PASS
total_operacoes = 0
```

Interpretação:

```text
Nenhum cenário negativo criou registro em public.mesa_cliente_fluxo_operacoes.
```

---

## 9. Rollback

O teste encerrou com:

```text
ROLLBACK
```

Mensagem registrada:

```text
Teste 11B encerra com ROLLBACK. Nada deve permanecer no banco.
```

---

## 10. Estado da Fase 5B após o 11B

```text
Preflight 11 = aprovado com WARN estrutural esperado
Migration 5B = executada com sucesso
11A positivo = aprovado
11B negativos/segurança = aprovado
11C idempotência = próximo teste
11D operação confirmada/conflito = pendente
11E zero mutação agenda/parcelas = pendente
```

---

## 11. Próximo passo

Criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql
```

Objetivo do 11C:

```text
chamar a RPC 5B duas vezes com os mesmos parâmetros canônicos
validar que checksum_operacao é calculado no banco
validar que não duplica operação financeira
validar retorno idempotente/reutilização segura
validar rollback final
```
