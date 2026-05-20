# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 5D — Smoke pós-merge / pós-produção

**Status:** protocolo definido e ajustado para `READ ONLY` estrito.

**Script:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/13_smoke_pos_producao_leitura_operacoes_admin_readonly.sql
```

---

## 1. Objetivo

Validar, após merge/deploy, que as RPCs administrativas da Fase 5D estão disponíveis e operacionais no ambiente alvo sem executar DML financeiro e sem executar DDL temporário.

O smoke confirma:

- existência das RPCs 5D;
- execução autenticada com perfil administrativo real;
- listagem administrativa read-only;
- detalhe administrativo read-only;
- contrato mínimo de retorno;
- flags explícitas de não mutação;
- execução dentro de transação `READ ONLY` estrita.

---

## 2. Escopo permitido

O smoke pode executar somente operações de leitura e configuração local de sessão.

Permitido:

- `select` em tabelas de referência;
- chamada de RPCs 5D;
- `set_config` de sessão para simular `auth.uid()` no SQL Editor;
- validação de JSON retornado;
- acumulação de resultado via `set_config` local de transação.

Proibido:

- criar fixture em produção;
- criar função temporária;
- criar tabela temporária;
- usar `DO` block;
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

## 3. Sobre negativos/allowlist

A versão inicial do protocolo previa validar erro esperado de `order_by` inválido dentro do próprio smoke.

Isso foi removido por motivo técnico correto: capturar exception esperada em SQL puro normalmente exige PL/pgSQL via função temporária ou `DO` block. Ambos são DDL/execução procedimental incompatíveis com a proposta de transação `READ ONLY` estrita no SQL Editor.

Portanto:

- negativos e allowlists continuam cobertos pelos testes completos `13C` e `13E` em ambiente de teste/homologação;
- o smoke pós-produção fica limitado à sanidade operacional read-only, sem DDL e sem DML;
- o bloco `05_negativos_allowlist_nao_executados_no_smoke_readonly` retorna `INFO`, não `PASS`.

---

## 4. Pré-requisitos

Antes de executar o smoke:

1. A migration 5D deve estar aplicada no ambiente alvo.
2. Deve existir ao menos um usuário/corretor administrativo ativo.
3. Deve existir ao menos uma operação financeira persistida acessível por esse usuário.
4. O ambiente deve conter dados reais suficientes para listagem e detalhe.

Se não houver operação financeira real no ambiente, o smoke deve retornar `SKIP_DATA` no bloco de alvo, não forçar criação de massa.

---

## 5. Critérios de aprovação

O smoke é considerado aprovado quando:

| Bloco | Resultado esperado |
|---|---:|
| Existência das RPCs 5D | PASS |
| Seleção de alvo administrativo real | PASS ou SKIP_DATA justificado |
| Listagem 5D | PASS ou SKIP_DATA justificado |
| Detalhe 5D | PASS ou SKIP_DATA justificado |
| Contrato read-only mínimo | PASS ou SKIP_DATA justificado |
| Negativos/allowlist fora do smoke read-only | INFO |
| Encerramento read-only | INFO |

Se qualquer bloco retornar `FAIL`, o deploy da 5D deve ser investigado antes de seguir para próxima fase.

---

## 6. Critérios de reprovação

Reprovar o smoke se ocorrer qualquer uma das situações abaixo:

- função 5D ausente;
- permissão de execução ausente para `authenticated`;
- usuário administrativo ativo não encontrado quando deveria existir massa real;
- RPC retorna `ok != true`;
- RPC retorna `readonly != true`;
- RPC retorna `dml_financeiro != false`;
- RPC retorna `altera_agenda != false`;
- RPC retorna `altera_parcelas != false`;
- RPC retorna `recalcula_operacao != false`;
- erro inesperado fora dos cenários `SKIP_DATA` previstos.

---

## 7. Observações importantes

Este smoke não substitui os testes 13 a 13E.

Os testes 13 a 13E continuam sendo a bateria completa de validação funcional, segurança, negativos, filtros, paginação, ordenação e zero DML.

O smoke pós-produção é uma validação curta de sanidade operacional em ambiente real.

Ele não deve tentar reproduzir fixture em produção. Produção não é laboratório. Laboratório tem jaleco; produção tem boleto.

---

## 8. Resultado esperado no SQL Editor

A saída deve retornar linhas no padrão:

```text
bloco | status | detalhe
```

Exemplo esperado com massa real:

```text
00_funcoes_5d_existentes                                  PASS
01_alvo_admin_operacao_real                               PASS
02_listagem_admin_readonly_smoke                          PASS
03_detalhe_admin_readonly_smoke                           PASS
04_contrato_readonly_minimo                               PASS
05_negativos_allowlist_nao_executados_no_smoke_readonly   INFO
99_smoke_readonly_notice                                  INFO
```

Caso não exista operação financeira persistida acessível:

```text
00_funcoes_5d_existentes                                  PASS
01_alvo_admin_operacao_real                               SKIP_DATA
02_listagem_admin_readonly_smoke                          SKIP_DATA
03_detalhe_admin_readonly_smoke                           SKIP_DATA
04_contrato_readonly_minimo                               SKIP_DATA
05_negativos_allowlist_nao_executados_no_smoke_readonly   INFO
99_smoke_readonly_notice                                  INFO
```

Nesse caso, o ambiente precisa de dado real pré-existente para validar listagem/detalhe, mas o script não deve criar massa.
