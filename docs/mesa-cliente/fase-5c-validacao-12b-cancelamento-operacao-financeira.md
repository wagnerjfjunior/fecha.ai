# FECH.AI / MesaCliente — Fase 5C

## Validação 12B — Cancelamento positivo de operação financeira simulada

**Status:** APROVADO  
**Tipo:** teste transacional com rollback  
**Escopo:** RPC 5C — cancelamento administrativo de operação financeira simulada  
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

consegue cancelar uma operação financeira previamente registrada pela Fase 5B como `simulada`, respeitando o contrato da Fase 5C:

- cancelar operação `simulada`;
- alterar somente `public.mesa_cliente_fluxo_operacoes`;
- não alterar agenda;
- não alterar parcelas;
- não recalcular operação;
- manter `visivel_cliente=false`;
- manter `confirmado=false`;
- preencher auditoria de cancelamento;
- manter campos de confirmação nulos;
- encerrar com `ROLLBACK`.

---

## 2. Arquivo executado

```text
supabase/tests/mesa-cliente/engenharia-financeira/12b_validacao_cancelar_operacao_financeira_simulada_rollback.sql
```

---

## 3. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_operacao_5b_criada_simulada` | PASS | A operação financeira foi criada pela 5B como `simulada`, não confirmada e invisível ao cliente. |
| `02_cancelamento_5c_retorno_canonico` | PASS | A RPC 5C retornou contrato canônico administrativo, persistente, sem cliente-safe e sem mutar agenda/parcelas. |
| `03_operacao_cancelada_campos_auditoria` | PASS | A operação mudou de `simulada` para `cancelada`, mantendo `confirmado=false` e preenchendo auditoria de cancelamento. |
| `04_estado_banco_cancelado_sem_exposicao_cliente` | PASS | O estado persistido ficou `cancelada`, sem exposição ao cliente e com metadata 5C correta. |
| `05_agenda_parcelas_nao_mutadas` | PASS | Agenda e parcelas mantiveram checksum, hash, ids, totais e valores. |
| `06_updated_at_operacao_setado_explicitamente` | PASS | `updated_at` da operação foi setado explicitamente e retornado de forma consistente. |
| `99_rollback_notice` | INFO | Teste encerrou com `ROLLBACK`; nada deve permanecer no banco. |

---

## 4. Evidências técnicas relevantes

### 4.1 Operação criada pela 5B

A operação nasceu com:

```json
{
  "fase": "5B_REGISTRO_OPERACAO_FINANCEIRA",
  "status_operacao": "simulada",
  "confirmado": false,
  "visivel_cliente": false,
  "altera_agenda": false,
  "altera_parcelas": false,
  "escopo_dml": "operacao_financeira"
}
```

### 4.2 Cancelamento pela 5C

A RPC 5C retornou:

```json
{
  "fase": "5C_CONFIRMACAO_CANCELAMENTO_OPERACAO_FINANCEIRA",
  "acao": "cancelar",
  "escopo_dml": "status_operacao_financeira",
  "idempotente": false,
  "cliente_safe": false,
  "persistencia": true,
  "dml_financeiro": true,
  "altera_agenda": false,
  "altera_parcelas": false,
  "recalcula_operacao": false
}
```

### 4.3 Estado final da operação

A operação ficou com:

```json
{
  "status_operacao": "cancelada",
  "status_operacao_anterior": "simulada",
  "confirmado": false,
  "confirmado_por": null,
  "confirmado_em": null,
  "cancelado_por": "auth.uid()",
  "cancelado_em": "preenchido",
  "motivo_cancelamento": "Cancelamento transacional positivo do teste 12B",
  "visivel_cliente": false
}
```

### 4.4 Zero mutação de agenda e parcelas

Foram preservados:

- `agenda_id`;
- `agenda_checksum`;
- `agenda_tots`;
- `agenda_full_hash`;
- quantidade de parcelas;
- ids das parcelas;
- `parcelas_full_hash`;
- valor total das parcelas.

---

## 5. Veredito

```text
12B = PASS
```

O cancelamento positivo da Fase 5C está validado.

---

## 6. Próximo passo

Avançar para:

```text
12C — negativos e segurança da confirmação/cancelamento
```

Escopo esperado do 12C:

- `anon` bloqueado;
- sem `auth.uid()` bloqueado;
- operação inexistente bloqueada;
- ação inválida bloqueada;
- `p_parametros` não objeto bloqueado;
- payload com autoridade proibida bloqueado;
- cancelamento sem motivo bloqueado;
- confirmar operação cancelada bloqueado;
- cancelar operação confirmada bloqueado;
- tentativas negativas sem mutação indevida em agenda/parcelas;
- encerramento com `ROLLBACK`.
