# FECH.AI / MesaCliente — Fase 5A.1 — Validação parcial 10A/10B

**Status:** validação parcial aprovada  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Fase:** 5A.1 — simulação administrativa de impacto financeiro com agenda persistida  
**Data:** 2026-05-19

---

## 1. Resumo executivo

A Fase 5A.1 possui, neste momento, dois testes oficiais aprovados:

```text
10A = PASS
10B = PASS
10C = pendente
```

A fase ainda não deve ser marcada como concluída, porque falta o teste 10C, responsável por provar zero DML estrutural antes/depois da chamada da RPC 5A.1.

---

## 2. 10A — Validação positiva

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

Resultado:

```text
10A = PASS
```

Blocos aprovados:

| Bloco | Status | Evidência |
|---|---|---|
| `01_retorno_basico_5a` | PASS | Fase correta, visão administrativa, `cliente_safe=false`, `persistencia=false`, `dml_financeiro=false`. |
| `02_alternativas_e_recomendacao` | PASS | 8 alternativas geradas; melhor operação por antecipação. |
| `03_politica_usada` | PASS | Política composta com base `dias_365`, VPL máximo 6%, taxas de 12% a.a. |
| `04_zero_operacoes_financeiras` | PASS | Nenhuma operação financeira criada. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

Evidências relevantes:

```text
fase = 5A_SIMULACAO_IMPACTO_AGENDA_PERSISTIDA
visao = administrativa
cliente_safe = false
persistencia = false
dml_financeiro = false
qtd_alternativas = 8
melhor_tipo_operacao = antecipacao
total_operacoes = 0
total_parcelas_fixture = 6
```

---

## 3. 10B — Validação negativa

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

Resultado:

```text
10B = PASS
```

Blocos aprovados:

| Bloco | Status | Evidência |
|---|---|---|
| `01_grant_anon_bloqueado` | PASS | `anon` sem execute. |
| `02_sem_auth_bloqueado` | PASS | Chamada sem auth bloqueada. |
| `03_simulacao_inexistente_bloqueada` | PASS | Simulação inexistente bloqueada. |
| `04_empresa_id_payload_bloqueado` | PASS | `empresa_id` no payload bloqueado. |
| `05_valor_negativo_bloqueado` | PASS | Valor negativo bloqueado. |
| `06_modo_invalido_bloqueado` | PASS | Modo inválido bloqueado. |
| `07_agenda_inexistente_bloqueada` | PASS | Agenda ativa inexistente bloqueada. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

SQLSTATEs validados:

```text
sem auth = 28000
simulação inexistente = P0002
empresa_id no payload = 42501
valor negativo = 22023
modo inválido = 22023
agenda inexistente = P0002
```

---

## 4. Correções registradas durante a validação

### 4.1. 10A — escopo de CTE

O 10A foi corrigido para não acessar CTE fora do comando SQL em que ela foi definida.

### 4.2. RPC 5A.1 — coluna inexistente em operações

Foi criada migration corretiva para remover a dependência indevida de `agenda_id` em `mesa_cliente_fluxo_operacoes`.

Arquivo:

```text
supabase/migrations/20260518194500_fix_mesa_cliente_5a_remover_agenda_id_operacoes.sql
```

Regra aprovada:

```text
Bloqueio por operação confirmada usando empresa_id + simulacao_id + status_operacao.
```

### 4.3. 10B — temp table removida

O 10B foi corrigido para não depender de tabela temporária com troca de role. O script passou a acumular resultados em variável transacional via `set_config`.

---

## 5. Próxima ação

Executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

Objetivo do 10C:

- validar `persistencia=false`;
- validar `dml_financeiro=false`;
- provar contagens de agendas inalteradas;
- provar contagens de parcelas inalteradas;
- provar contagens de operações inalteradas;
- provar checksum e totais da agenda inalterados;
- encerrar com ROLLBACK.

---

## 6. Estado atual

```text
4A aprovada.
4B aprovada em rollback transacional.
4C aprovada.
5A.1 contrato fechado.
10P aprovado.
10A aprovado.
10B aprovado.
10C pendente.
Fase 5A.1 ainda não concluída.
```
