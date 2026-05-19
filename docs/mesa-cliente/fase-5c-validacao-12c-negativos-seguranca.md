# FECH.AI / MesaCliente — Fase 5C

## Validação 12C — Negativos e segurança da confirmação/cancelamento

**Status:** APROVADO  
**Tipo:** teste transacional com rollback  
**Escopo:** RPC 5C — validações negativas, bloqueios de segurança e integridade  
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

bloqueia corretamente cenários inválidos ou inseguros, sem mutar indevidamente operações, agenda ou parcelas.

---

## 2. Arquivo executado

```text
supabase/tests/mesa-cliente/engenharia-financeira/12c_validacao_negativos_seguranca_confirmacao_cancelamento_rollback.sql
```

---

## 3. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_operacoes_base_preparadas` | PASS | Fixture montada com 3 operações: uma cancelada, uma confirmada e uma simulada. |
| `02_anon_sem_execute` | PASS | `anon_execute=false` e `authenticated_execute=true`. |
| `03_sem_auth_bloqueado` | PASS | Chamada sem `auth.uid()` bloqueada com SQLSTATE `28000`. |
| `04_operacao_inexistente_bloqueada` | PASS | Operação inexistente bloqueada com SQLSTATE `P0002`. |
| `05_acao_invalida_bloqueada` | PASS | Ação fora de `confirmar/cancelar` bloqueada com SQLSTATE `22023`. |
| `06_parametros_nao_objeto_bloqueado` | PASS | `p_parametros` não objeto bloqueado com SQLSTATE `22023`. |
| `07_payload_autoritativo_bloqueado` | PASS | Payload com autoridade soberana do frontend bloqueado com SQLSTATE `42501`. |
| `08_cancelamento_sem_motivo_bloqueado` | PASS | Cancelamento sem motivo bloqueado com SQLSTATE `22023`. |
| `09_confirmar_cancelada_bloqueado` | PASS | Confirmação de operação cancelada bloqueada com SQLSTATE `55000`. |
| `10_cancelar_confirmada_bloqueado` | PASS | Cancelamento de operação confirmada bloqueado com SQLSTATE `55000`. |
| `11_negativos_nao_mutaram_operacoes` | PASS | As tentativas negativas não alteraram as operações. |
| `12_agenda_parcelas_nao_mutadas` | PASS | Agenda e parcelas permaneceram intactas. |
| `99_rollback_notice` | INFO | Teste encerrou com `ROLLBACK`; nada deve permanecer no banco. |

---

## 4. Evidências técnicas relevantes

### 4.1 Grants e superfície de execução

```json
{
  "anon_execute": false,
  "authenticated_execute": true
}
```

### 4.2 Bloqueios esperados

Foram validados os seguintes SQLSTATEs:

```text
28000 — acesso negado sem usuário autenticado
P0002 — operação financeira não encontrada
22023 — ação inválida / parâmetro inválido / cancelamento sem motivo
42501 — payload autoritativo vindo do frontend
55000 — transição de estado bloqueada
```

### 4.3 Estados protegidos

Foram bloqueadas as transições:

```text
cancelada -> confirmada
confirmada -> cancelada
```

A regra vigente da Fase 5C permanece:

```text
cancelamento de operação confirmada está bloqueado nesta versão
```

---

## 5. Integridade preservada

Após todos os negativos, permaneceram iguais:

- quantidade de operações;
- quantidade de operações confirmadas;
- quantidade de operações canceladas;
- quantidade de operações simuladas;
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
12C = PASS
```

Os negativos e bloqueios de segurança da Fase 5C estão validados.

---

## 7. Próximo passo

Avançar para:

```text
12D — idempotência da confirmação e do cancelamento
```

Escopo esperado do 12D:

- confirmar operação já confirmada;
- validar retorno `idempotente=true`;
- cancelar operação já cancelada;
- validar retorno `idempotente=true`;
- garantir que a segunda chamada não altera agenda;
- garantir que a segunda chamada não altera parcelas;
- garantir que a segunda chamada não altera indevidamente auditoria já existente;
- encerrar com `ROLLBACK`.
