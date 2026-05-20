# FECH.AI / MesaCliente — Fase 5D

## Validação 13A — Listagem administrativa de operações financeiras

**Status:** APROVADO  
**Tipo:** teste transacional com rollback  
**Escopo:** validação positiva da RPC de listagem administrativa da Fase 5D  
**Branch:** `feature/mesa-cliente-5d-leitura-operacoes-admin`

---

## 1. Objetivo

Validar a RPC:

```sql
public.mesa_cliente_listar_operacoes_financeiras_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid default null,
  p_filtros jsonb default '{}'::jsonb
)
```

A validação confirma que a RPC lista operações financeiras de forma administrativa, tenant-safe e read-only, sem recalcular operação e sem mutar agenda, parcelas ou operações.

---

## 2. Arquivo executado

```text
supabase/tests/mesa-cliente/engenharia-financeira/13a_validacao_listar_operacoes_financeiras_admin_rollback.sql
```

---

## 3. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_operacoes_fixture_5b_5c_preparadas` | PASS | Fixture criou 3 operações: 1 confirmada, 1 cancelada e 1 simulada. |
| `02_listagem_geral_retorno_canonico_5d` | PASS | Retorno canônico 5D validado com flags read-only e administrativas. |
| `03_listagem_por_agenda_retorna_mesmas_operacoes` | PASS | Listagem por agenda retornou as mesmas 3 operações esperadas. |
| `04_campos_minimos_administrativos_presentes` | PASS | Campos administrativos e financeiros mínimos estão presentes. |
| `05_filtro_status_confirmada` | PASS | Filtro por `confirmada` retornou somente a operação confirmada. |
| `06_filtro_status_cancelada` | PASS | Filtro por `cancelada` retornou somente a operação cancelada. |
| `07_filtro_status_simulada` | PASS | Filtro por `simulada` retornou somente a operação simulada. |
| `08_paginacao_limit_2_preserva_total` | PASS | Paginação com `limit=2` preservou `total=3` e retornou 2 itens. |
| `09_5d_readonly_nao_mutou_agenda_parcelas_operacoes` | PASS | Hashes antes/depois iguais para agenda, parcelas e operações. |
| `99_rollback_notice` | INFO | Teste encerra com rollback. |

---

## 4. Fixture validada

A fixture transacional criou:

```text
qtd_operacoes = 3
qtd_confirmada = 1
qtd_cancelada = 1
qtd_simulada = 1
qtd_visivel_cliente = 0
```

Operações geradas:

```text
op1 = confirmada
op2 = cancelada
op3 = simulada
```

A operação confirmada manteve:

```text
status_operacao = confirmada
confirmado = true
confirmado_por = usuário autenticado da fixture
confirmado_em preenchido
visivel_cliente = false
```

A operação cancelada manteve:

```text
status_operacao = cancelada
confirmado = false
cancelado_por = usuário autenticado da fixture
cancelado_em preenchido
motivo_cancelamento = Cancelamento fixture 13A para validar filtro 5D
visivel_cliente = false
```

A operação simulada manteve:

```text
status_operacao = simulada
confirmado = false
confirmado_por = null
cancelado_por = null
visivel_cliente = false
```

---

## 5. Retorno canônico validado

A listagem geral retornou:

```text
fase = 5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN
visao = administrativa
cliente_safe = false
readonly = true
persistencia = true
dml_financeiro = false
escopo_dml = nenhum
altera_agenda = false
altera_parcelas = false
recalcula_operacao = false
total = 3
qtd_operacoes_payload = 3
```

Esse resultado confirma que a 5D é uma camada administrativa de leitura e não uma camada operacional de mutação.

---

## 6. Listagem por agenda

A listagem por agenda retornou as mesmas 3 operações esperadas:

```text
1 operação confirmada
1 operação cancelada
1 operação simulada
```

A agenda usada na fixture foi corretamente refletida no payload:

```text
agenda_id = 48cf8523-9783-417e-8b2a-97e05db06e68
```

Como o teste encerra com rollback, esse identificador é apenas evidência transitória da execução.

---

## 7. Campos mínimos administrativos

O payload da RPC retornou os campos necessários para uso administrativo:

```text
id
empresa_id
simulacao_id
agenda_id
empreendimento_id
politica_id
tipo_operacao
status_operacao
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
visivel_cliente
checksum_operacao
grupo_origem
grupo_destino
parcela_origem_id
parcela_destino_id
valor_movido
valor_base
data_origem
data_destino
taxa_ano_pct
vpl_aplicado_pct
desconto_calculado
acrescimo_calculado
economia_liquida
dias_calculo
premio_corretor_pct
status_premio
criado_por
created_at
updated_at
resumo_financeiro
```

---

## 8. Filtros por status

Foram validados os filtros:

```text
status_operacao = confirmada => total 1
status_operacao = cancelada  => total 1
status_operacao = simulada   => total 1
```

Os filtros aplicados retornaram os objetos corretos e mantiveram as flags canônicas da 5D:

```text
cliente_safe = false
readonly = true
dml_financeiro = false
altera_agenda = false
altera_parcelas = false
recalcula_operacao = false
```

---

## 9. Paginação

A paginação foi validada com:

```text
limit = 2
offset = 0
total = 3
qtd_operacoes_payload = 2
```

Interpretação: a RPC respeita o limite solicitado sem perder a contagem total, comportamento correto para tela administrativa paginada.

---

## 10. Garantia read-only

O teste comparou hashes antes e depois das chamadas 5D.

Resultado:

```text
hash_agenda_igual = true
hash_parcelas_igual = true
hash_operacoes_igual = true
```

Snapshots:

```text
agenda_full_hash antes  = 7abf2d11b8568a2c0a38862e11f712b9
agenda_full_hash depois = 7abf2d11b8568a2c0a38862e11f712b9

parcelas_full_hash antes  = fd0bfcb8aade128ae055b965f4b05820
parcelas_full_hash depois = fd0bfcb8aade128ae055b965f4b05820

operacoes_full_hash antes  = bf32f4c26a3f7f98bd33ea1544779c3a
operacoes_full_hash depois = bf32f4c26a3f7f98bd33ea1544779c3a
```

Isso comprova que a RPC 5D de listagem não alterou agenda, parcelas nem operações.

---

## 11. Rollback

O teste encerra com:

```sql
rollback;
```

A fixture 4B/5B/5C usada para validar a 5D não deve permanecer no banco.

---

## 12. Veredito

```text
13A = PASS
```

A RPC de listagem administrativa da Fase 5D foi aprovada.

---

## 13. Próximo passo

Criar e executar o teste:

```text
supabase/tests/mesa-cliente/engenharia-financeira/13b_validacao_obter_operacao_financeira_admin_rollback.sql
```

Objetivo do 13B:

```text
validar a RPC public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
```

O 13B deve cobrir:

```text
retorno detalhado de uma operação confirmada
retorno detalhado de uma operação cancelada
retorno detalhado de uma operação simulada
flags canônicas read-only
campos financeiros completos
auditoria 5C
vínculos com simulação/agenda/parcela
bloqueio de mutação
hashes antes/depois iguais
rollback final
```
