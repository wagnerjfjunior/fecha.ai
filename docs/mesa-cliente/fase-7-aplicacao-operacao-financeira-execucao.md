# FECH.AI — MesaCliente

## Fase 7 — Aplicação de Operação Financeira

Documento de execução e rastreabilidade técnica da Fase 7.

Branch de trabalho:

```text
feature/mesa-cliente-pos-fase-6-proxima-fase
```

## Objetivo da fase

Implementar e validar a aplicação efetiva de uma operação financeira previamente simulada, registrada e confirmada, alterando a agenda financeira de forma controlada e auditável.

RPC principal da fase:

```sql
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

## Escopo implementado

- Inclusão do status `aplicada` na constraint `mesa_cliente_fluxo_operacoes_status_operacao_check`.
- Criação/validação da RPC de aplicação financeira administrativa.
- Aplicação permitida somente para operação `confirmada`.
- Bloqueio para operação `simulada`, `cancelada` ou já `aplicada`.
- Proteção contra chamada sem autenticação.
- Proteção contra perfil sem autorização.
- Proteção cross-tenant.
- Bloqueio de parâmetros soberanos vindos do frontend.
- Mutação controlada em parcela, operação e agenda.
- Pós-aplicação com `visivel_cliente=false`, exigindo novo release comercial antes de exposição cliente-safe.
- Preservação do modelo tenant-safe e multiempresa.

## Testes executados

| Teste | Arquivo | Status | Finalidade |
|---|---|---:|---|
| 15A | `15a_validacao_constraint_status_operacao_aplicada_readonly.sql` | PASS | Validar constraint com status `aplicada` |
| 15B | `15b_validacao_aplicacao_operacao_financeira_admin_rollback.sql` | PASS | Validar aplicação positiva com fixture transacional |
| 15C | `15c_validacao_seguranca_aplicacao_operacao_admin_rollback.sql` | PASS | Validar segurança negativa, idempotência e bloqueios |
| 15D | `15d_validacao_catalogo_aplicacao_operacao_admin_readonly.sql` | PASS | Validar catálogo, grants, assinatura e dependências |
| 15E | `15e_regressao_final_aplicacao_operacao_financeira_admin_rollback.sql` | PASS | Regressão final 4B → 5B → 5C → 6 → 7 → 6 pós-aplicação |

## Resultado do 15E

O 15E validou o fluxo completo em fixture transacional:

```text
4B -> 5B -> 5C -> release fixture -> 6 admin/cliente-safe -> 7 aplicar -> 6 pós-aplicação
```

Blocos aprovados:

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_setup_admin_fixture` | PASS | Fixture transacional criada com admin, política e faixas |
| `01_agenda_parcela_4b_fixture` | PASS | Agenda/parcela criadas pela 4B |
| `02_operacao_5b_5c_confirmada_liberada` | PASS | Operação registrada, confirmada e liberada para cliente-safe na fixture |
| `03_resumos_fase_6_pre_aplicacao` | PASS | Resumo admin e cliente-safe funcionando antes da aplicação |
| `04_cliente_safe_pre_aplicacao_sem_vazamento` | PASS | Payload cliente-safe sem campos internos/sensíveis |
| `05_rpc_7_aplicacao_final` | PASS | RPC da Fase 7 aplicou operação confirmada e mudou status para `aplicada` |
| `06_mutacao_financeira_controlada` | PASS | Mutação controlada validada sem criar/remover parcelas/operações |
| `07_resumo_admin_pos_aplicacao` | PASS | Resumo admin pós-aplicação funcionando e read-only |
| `08_cliente_safe_pos_aplicacao_gate_ou_sem_vazamento` | PASS | Cliente-safe pós-aplicação bloqueado corretamente por release gate |
| `09_readiness_fechamento_fase_7` | PASS | Fase 7 tecnicamente pronta para fechamento |
| `99_rollback_notice` | INFO | Teste encerrado com `ROLLBACK`; fixture não persiste |

## Observação técnica sobre o release transacional no 15E

O primeiro desenho do 15E tentou chamar a RPC cliente-safe antes da aplicação sem liberar a operação. O comportamento retornado foi:

```text
cliente_safe_not_released
```

Isso confirmou que o release gate da Fase 6 estava funcionando corretamente.

Para validar o resumo cliente-safe pré-aplicação dentro da regressão final, o teste oficial passou a fazer um release exclusivamente transacional:

```sql
update public.mesa_cliente_fluxo_operacoes
set visivel_cliente = true
where id = <operacao_id>;
```

Esse release não persiste, pois o teste roda em `BEGIN + ROLLBACK`.

Após a aplicação pela RPC da Fase 7, a operação voltou corretamente para:

```text
visivel_cliente = false
```

E a chamada cliente-safe pós-aplicação bloqueou por release gate, comportamento esperado para evitar exposição comercial automática após mutação financeira.

## Garantias confirmadas

- A aplicação financeira é DML controlado e restrito.
- A RPC é administrativa, tenant-safe e protegida por perfil.
- Frontend não possui autoridade para enviar campos soberanos.
- Operações não confirmadas não podem ser aplicadas.
- Operações canceladas não podem ser aplicadas.
- Operações já aplicadas não podem ser reaplicadas.
- Tentativas negativas não causam mutação.
- Reaplicação não causa segunda mutação.
- Cliente-safe não recebe campos internos/sensíveis.
- Pós-aplicação não expõe automaticamente a condição ao cliente.

## Commits relevantes

- `010feb2a0df021f651b92a3cbe43325fe3eed4df` — adiciona o teste oficial 15E.

## Status final

```text
FASE 7 = VALIDADA TECNICAMENTE
TESTES 15A, 15B, 15C, 15D, 15E = PASS
PRÓXIMO PASSO = fechamento técnico / PR / merge / smoke pós-produção
```
