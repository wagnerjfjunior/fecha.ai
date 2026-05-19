# FECH.AI / MesaCliente — Fase 5A.1 — Validação final

**Status:** aprovada  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Fase:** 5A.1 — simulação administrativa de impacto financeiro com agenda persistida  
**Data:** 2026-05-19

---

## 1. Veredito executivo

A Fase 5A.1 está **aprovada**.

Foram concluídos com sucesso:

```text
10P = PASS
10A = PASS
10B = PASS
10C = PASS
```

A RPC administrativa de simulação de impacto financeiro foi validada com agenda persistida como fonte soberana, sem exposição cliente-safe e sem DML financeiro permanente.

---

## 2. Contrato validado

RPC validada:

```text
public.mesa_cliente_simular_impacto_agenda_persistida_admin(
  p_simulacao_id uuid,
  p_data_referencia date default current_date,
  p_modo text default 'melhor_aplicacao',
  p_parametros jsonb default '{}'::jsonb
)
```

Contrato aprovado:

```text
visao = administrativa
agenda-first = true
cliente_safe = false
persistencia = false
dml_financeiro = false
anon = sem execute
authenticated = execute
empresa_id não pode vir como autoridade do frontend
política financeira vem do banco
agenda persistida é a fonte soberana
```

---

## 3. Migrations envolvidas

Migration principal:

```text
supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
```

Migration corretiva:

```text
supabase/migrations/20260518194500_fix_mesa_cliente_5a_remover_agenda_id_operacoes.sql
```

Motivo da corretiva:

```text
A primeira versão da RPC 5A.1 assumiu indevidamente a existência de agenda_id em mesa_cliente_fluxo_operacoes.
O schema real não possui essa coluna.
A correção removeu a dependência de o.agenda_id e consolidou o bloqueio por empresa_id + simulacao_id + status_operacao = 'confirmada'.
```

---

## 4. 10P — Preparação transacional

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql
```

Status:

```text
PASS
```

Evidências principais:

```text
politica_valida_5a = true
agenda_valida_5a = true
total_parcelas = 6
qtd_faixas_db = 3
total_operacoes = 0
```

Função do 10P:

```text
Criar base mínima transacional para provar que a 5A.1 poderia ser implementada sem seed permanente.
```

---

## 5. 10A — Validação positiva

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

Status:

```text
PASS
```

Blocos aprovados:

| Bloco | Status | Evidência |
|---|---|---|
| `01_retorno_basico_5a` | PASS | Fase correta, visão administrativa, `cliente_safe=false`, `persistencia=false`, `dml_financeiro=false`. |
| `02_alternativas_e_recomendacao` | PASS | 8 alternativas geradas; recomendação por antecipação. |
| `03_politica_usada` | PASS | Política `composto/dias_365`, VPL máximo 6%, taxas de 12% a.a. |
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

## 6. 10B — Validação negativa

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

Status:

```text
PASS
```

Blocos aprovados:

| Bloco | Status | Evidência |
|---|---|---|
| `01_grant_anon_bloqueado` | PASS | `anon_can_execute=false`. |
| `02_sem_auth_bloqueado` | PASS | Chamada sem auth bloqueada com SQLSTATE `28000`. |
| `03_simulacao_inexistente_bloqueada` | PASS | Simulação inexistente bloqueada com SQLSTATE `P0002`. |
| `04_empresa_id_payload_bloqueado` | PASS | `empresa_id` no payload bloqueado com SQLSTATE `42501`. |
| `05_valor_negativo_bloqueado` | PASS | Valor negativo bloqueado com SQLSTATE `22023`. |
| `06_modo_invalido_bloqueado` | PASS | Modo inválido bloqueado com SQLSTATE `22023`. |
| `07_agenda_inexistente_bloqueada` | PASS | Agenda ativa inexistente bloqueada com SQLSTATE `P0002`. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

---

## 7. 10C — Zero DML estrutural

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

Status:

```text
PASS
```

Resultado enviado:

| Bloco | Status | Evidência |
|---|---|---|
| `01_retorno_5a_zero_dml_flags` | PASS | Retorno confirmou `persistencia=false` e `dml_financeiro=false`. |
| `02_contagens_inalteradas` | PASS | Antes/depois: 1 agenda, 6 parcelas e 0 operações. |
| `03_agenda_checksum_totais_inalterados` | PASS | Mesmo `agenda_id`, mesmo checksum e mesmos totais antes/depois. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

Evidências relevantes:

```text
agendas_before = 1
agendas_after = 1
parcelas_before = 6
parcelas_after = 6
operacoes_before = 0
operacoes_after = 0
agenda_id_before = 92f1fcc0-e280-4211-8372-4ff4bdb95587
agenda_id_after = 92f1fcc0-e280-4211-8372-4ff4bdb95587
checksum_before = 3373755171d33c447fa959808f5b2f41
checksum_after = 3373755171d33c447fa959808f5b2f41
totais_iguais = true
valor_total = 29500.5
qtd_parcelas = 6
```

Interpretação:

```text
A RPC 5A.1 não alterou agenda, parcelas, operações, checksum ou totais.
```

---

## 8. Correções realizadas durante a validação

### 8.1. 10A — escopo de CTE

Erro inicial:

```text
relation "chamada_5a" does not exist
```

Correção:

```text
Gravar payload_4b e payload_5a no mesmo comando SQL em que as CTEs existem.
```

### 8.2. RPC 5A.1 — remoção de `o.agenda_id`

Erro inicial:

```text
column o.agenda_id does not exist
```

Correção:

```text
Removida dependência de agenda_id em mesa_cliente_fluxo_operacoes.
Bloqueio de operação confirmada passou a usar empresa_id + simulacao_id + status_operacao.
```

### 8.3. 10B — remoção de temp table

Erros iniciais:

```text
permission denied for table tmp_10b_results
relation "tmp_10b_results" does not exist
```

Correção:

```text
O 10B passou a acumular resultados em variável transacional via set_config, sem temp table.
```

---

## 9. Guardrails preservados

A Fase 5A.1 foi aprovada mantendo os seguintes guardrails:

- sem alteração de frontend;
- sem alteração de parser;
- sem alteração de Worker;
- sem alteração de Make/n8n;
- sem seed permanente;
- sem autoridade financeira vinda do frontend;
- sem `empresa_id` soberano no payload;
- sem DML financeiro pela RPC 5A.1;
- sem escrita em `mesa_cliente_fluxo_operacoes`;
- sem alteração em `mesa_cliente_fluxo_parcelas`;
- sem alteração em `mesa_cliente_agendas_financeiras`;
- sem exposição cliente-safe.

---

## 10. Estado final da Fase 5A.1

```text
4A aprovada.
4B aprovada em rollback transacional.
4C aprovada.
5A.1 aprovada.
```

Próximas fases naturais:

```text
5B — registrar operação financeira em tabela própria, com lock/idempotência/auditoria.
5C — confirmar/cancelar operação financeira.
Integração Front/BFF — somente após contrato administrativo e cliente-safe estarem fechados para leitura/escrita necessária.
```

---

## 11. Veredito final

A 5A.1 cumpriu seu papel: simular impacto financeiro sobre agenda persistida, entregar visão administrativa e provar que não altera o estado financeiro.

A parede passou no prumo. Agora a próxima etapa pode tratar de registro real de operação — aí já é outro bicho, com coleira curta: lock, idempotência e auditoria.
