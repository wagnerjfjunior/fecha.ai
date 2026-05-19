# FECH.AI / MesaCliente — Fase 5C

## Validação 12D — Idempotência da confirmação e do cancelamento

**Status:** APROVADO  
**Tipo:** teste transacional com rollback  
**Escopo:** RPC 5C — idempotência de transições finais  
**Branch:** `feature/mesa-cliente-5c-confirmacao-cancelamento`

---

## 1. Objetivo

Validar que a RPC:

```sql
public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  p_operacao_id uuid,
  p_acao text,
  p_motivo text default null,
  p_parametros jsonb default '{}'::jsonb
)
```

mantém comportamento idempotente quando a mesma transição finalizada é repetida:

- confirmar operação já confirmada retorna `idempotente=true`;
- cancelar operação já cancelada retorna `idempotente=true`;
- segunda chamada não altera agenda;
- segunda chamada não altera parcelas;
- segunda chamada não altera estado/auditoria já persistidos;
- segunda chamada não altera `updated_at` da operação;
- encerramento com `ROLLBACK`.

---

## 2. Arquivo executado

```text
supabase/tests/mesa-cliente/engenharia-financeira/12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql
```

---

## 3. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_primeiras_transicoes_preparadas` | PASS | Foram criadas duas operações e aplicadas as primeiras transições: uma confirmação e um cancelamento. |
| `02_confirmacao_idempotente` | PASS | Repetir `confirmar` em operação já confirmada retornou idempotência e preservou auditoria original. |
| `03_cancelamento_idempotente` | PASS | Repetir `cancelar` em operação já cancelada retornou idempotência e preservou motivo/auditoria original. |
| `04_segundas_chamadas_nao_mutaram_operacoes` | PASS | As segundas chamadas não alteraram quantidade, estados, visibilidade ou hash das operações. |
| `05_agenda_parcelas_nao_mutadas` | PASS | Agenda e parcelas permaneceram intactas. |
| `99_rollback_notice` | INFO | Teste encerrou com `ROLLBACK`; nada deve permanecer no banco. |

---

## 4. Evidências técnicas relevantes

### 4.1 Primeiras transições

A primeira confirmação retornou:

```json
{
  "acao": "confirmar",
  "status_operacao": "confirmada",
  "confirmado": true,
  "idempotente": false,
  "visivel_cliente": false,
  "altera_agenda": false,
  "altera_parcelas": false,
  "recalcula_operacao": false
}
```

O primeiro cancelamento retornou:

```json
{
  "acao": "cancelar",
  "status_operacao": "cancelada",
  "confirmado": false,
  "idempotente": false,
  "motivo_cancelamento": "Cancelamento inicial para idempotência 12D",
  "visivel_cliente": false,
  "altera_agenda": false,
  "altera_parcelas": false,
  "recalcula_operacao": false
}
```

### 4.2 Confirmação idempotente

A segunda confirmação preservou:

- `id`;
- `status_operacao=confirmada`;
- `confirmado=true`;
- `confirmado_por`;
- `confirmado_em`;
- `updated_at`;
- `checksum_operacao`;
- `visivel_cliente=false`.

A única diferença semântica esperada no retorno foi `status_operacao_anterior=confirmada`, indicando que a operação já estava no estado final.

### 4.3 Cancelamento idempotente

O segundo cancelamento preservou:

- `id`;
- `status_operacao=cancelada`;
- `confirmado=false`;
- `cancelado_por`;
- `cancelado_em`;
- `motivo_cancelamento` original;
- `updated_at`;
- `checksum_operacao`;
- `visivel_cliente=false`.

A única diferença semântica esperada no retorno foi `status_operacao_anterior=cancelada`, indicando que a operação já estava no estado final.

---

## 5. Integridade preservada

Foram preservados entre a primeira rodada e as chamadas idempotentes:

- quantidade de operações;
- quantidade de operações confirmadas;
- quantidade de operações canceladas;
- quantidade de operações visíveis ao cliente;
- `operacoes_full_hash`;
- `agenda_checksum`;
- `agenda_full_hash`;
- `parcelas_ids`;
- `parcelas_full_hash`;
- `valor_total_parcelas`.

---

## 6. Veredito

```text
12D = PASS
```

A idempotência da confirmação e do cancelamento da Fase 5C está validada.

---

## 7. Próximo passo

Avançar para:

```text
12E — zero mutação rígido da Fase 5C
```

Escopo esperado do 12E:

- confirmar e cancelar operações simuladas;
- validar que somente campos permitidos da operação são alterados;
- preservar campos financeiros e estruturais da operação;
- preservar `checksum_operacao`;
- preservar agenda;
- preservar parcelas;
- manter `visivel_cliente=false`;
- encerrar com `ROLLBACK`.
