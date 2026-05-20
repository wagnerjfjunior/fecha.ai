# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 5D — Smoke pós-merge / pós-produção

**Status:** protocolo definido.

**Script:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/13_smoke_pos_producao_leitura_operacoes_admin_readonly.sql
```

---

## 1. Objetivo

Validar, após merge/deploy, que as RPCs administrativas da Fase 5D estão disponíveis e operacionais no ambiente alvo sem executar DML financeiro.

O smoke deve confirmar:

- existência das RPCs 5D;
- execução autenticada com perfil administrativo real;
- listagem administrativa read-only;
- detalhe administrativo read-only;
- contrato mínimo de retorno;
- flags explícitas de não mutação;
- bloqueio de parâmetro inválido em allowlist;
- execução dentro de transação `READ ONLY`.

---

## 2. Escopo permitido

O smoke pode executar somente operações de leitura.

Permitido:

- `select` em tabelas de referência;
- chamada de RPCs 5D;
- `set_config` de sessão para simular `auth.uid()` no SQL Editor;
- validação de JSON retornado;
- validação de erro esperado para parâmetro inválido.

Proibido:

- criar fixture em produção;
- inserir simulação;
- criar agenda;
- criar operação financeira;
- confirmar operação;
- cancelar operação;
- atualizar qualquer registro;
- deletar qualquer registro;
- alterar política financeira;
- alterar permissões;
- alterar RPC;
- rodar migration dentro do smoke.

---

## 3. Pré-requisitos

Antes de executar o smoke:

1. A migration 5D deve estar aplicada no ambiente alvo.
2. Deve existir ao menos um usuário/corretor administrativo ativo.
3. Deve existir ao menos uma operação financeira persistida acessível por esse usuário.
4. O ambiente deve conter dados reais suficientes para listagem e detalhe.

Se não houver operação financeira real no ambiente, o smoke deve retornar `SKIP_DATA` no bloco de alvo, não forçar criação de massa.

---

## 4. Critérios de aprovação

O smoke é considerado aprovado quando:

| Bloco | Resultado esperado |
|---|---:|
| Existência das RPCs 5D | PASS |
| Seleção de alvo administrativo real | PASS ou SKIP_DATA justificado |
| Listagem 5D | PASS |
| Detalhe 5D | PASS |
| Contrato read-only | PASS |
| Bloqueio de `order_by` inválido | PASS |
| Encerramento read-only | INFO |

Se qualquer bloco retornar `FAIL`, o deploy da 5D deve ser investigado antes de seguir para próxima fase.

---

## 5. Critérios de reprovação

Reprovar o smoke se ocorrer qualquer uma das situações abaixo:

- função 5D ausente;
- permissão de execução ausente para `authenticated`;
- usuário administrativo ativo não encontrado;
- RPC retorna `ok != true`;
- RPC retorna `readonly != true`;
- RPC retorna `dml_financeiro != false`;
- RPC retorna `altera_agenda != false`;
- RPC retorna `altera_parcelas != false`;
- RPC retorna `recalcula_operacao != false`;
- `order_by` inválido é aceito;
- erro inesperado fora dos negativos previstos.

---

## 6. Observações importantes

Este smoke não substitui os testes 13 a 13E.

Os testes 13 a 13E continuam sendo a bateria completa de validação funcional, segurança, negativos, filtros, paginação, ordenação e zero DML.

O smoke pós-produção é uma validação curta de sanidade operacional em ambiente real.

Ele não deve tentar reproduzir fixture em produção. Produção não é laboratório. Laboratório tem jaleco; produção tem boleto.

---

## 7. Resultado esperado no SQL Editor

A saída deve retornar linhas no padrão:

```text
bloco | status | detalhe
```

Exemplo esperado:

```text
00_funcoes_5d_existentes                      PASS
01_alvo_admin_operacao_real                   PASS
02_listagem_admin_readonly_smoke              PASS
03_detalhe_admin_readonly_smoke               PASS
04_contrato_readonly_minimo                   PASS
05_order_by_invalido_bloqueado                PASS
99_smoke_readonly_notice                      INFO
```

Caso não exista operação financeira persistida acessível:

```text
01_alvo_admin_operacao_real                   SKIP_DATA
99_smoke_readonly_notice                      INFO
```

Nesse caso, o ambiente precisa de dado real pré-existente para validar listagem/detalhe, mas o script não deve criar massa.
