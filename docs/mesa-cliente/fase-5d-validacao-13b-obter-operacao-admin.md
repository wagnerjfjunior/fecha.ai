# FECH.AI / MesaCliente — Fase 5D

## Validação 13B — Detalhe administrativo de operação financeira

**Status:** APROVADO  
**Tipo:** teste transacional com rollback  
**Escopo:** validação positiva da RPC de obtenção detalhada administrativa da Fase 5D  
**Branch:** `feature/mesa-cliente-5d-leitura-operacoes-admin`

---

## 1. Objetivo

Validar a RPC:

```sql
public.mesa_cliente_obter_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
```

A validação confirma que a RPC retorna o detalhe administrativo de uma operação financeira persistida pela Fase 5B e eventualmente confirmada/cancelada pela Fase 5C, mantendo comportamento estritamente read-only na Fase 5D.

---

## 2. Arquivo executado

```text
supabase/tests/mesa-cliente/engenharia-financeira/13b_validacao_obter_operacao_financeira_admin_rollback.sql
```

---

## 3. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_operacoes_fixture_5b_5c_preparadas` | PASS | Fixture criou 3 operações: 1 confirmada, 1 cancelada e 1 simulada. |
| `02_detalhe_confirmada_retorno_canonico_5d` | PASS | Detalhe de operação confirmada retornou payload canônico administrativo 5D. |
| `03_detalhe_cancelada_retorno_canonico_5d` | PASS | Detalhe de operação cancelada retornou payload canônico administrativo 5D. |
| `04_detalhe_simulada_retorno_canonico_5d` | PASS | Detalhe de operação simulada retornou payload canônico administrativo 5D. |
| `05_campos_financeiros_completos_5b_presentes` | PASS | Campos financeiros persistidos pela 5B estão disponíveis no detalhe. |
| `06_auditoria_5c_completa_no_detalhe` | PASS | Auditoria de confirmação/cancelamento da 5C está exposta no detalhe administrativo. |
| `07_vinculos_simulacao_agenda_parcela_preservados` | PASS | Vínculos com simulação, agenda e parcela de origem foram preservados. |
| `08_metadata_e_checksum_disponiveis_no_detalhe` | PASS | Metadata e checksum das operações estão presentes e consistentes. |
| `09_5d_obter_readonly_nao_mutou_agenda_parcelas_operacoes` | PASS | Hashes antes/depois iguais para agenda, parcelas e operações. |
| `99_rollback_notice` | INFO | Teste encerra com rollback. |

---

## 4. Fixture validada

A fixture transacional preparou:

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
confirmado_por preenchido
confirmado_em preenchido
cancelado_por = null
cancelado_em = null
motivo_cancelamento = null
visivel_cliente = false
```

A operação cancelada manteve:

```text
status_operacao = cancelada
confirmado = false
confirmado_por = null
confirmado_em = null
cancelado_por preenchido
cancelado_em preenchido
motivo_cancelamento = Cancelamento fixture 13B para validar detalhe 5D
visivel_cliente = false
```

A operação simulada manteve:

```text
status_operacao = simulada
confirmado = false
confirmado_por = null
confirmado_em = null
cancelado_por = null
cancelado_em = null
motivo_cancelamento = null
visivel_cliente = false
```

---

## 5. Retorno canônico validado

As três chamadas de detalhe retornaram:

```text
ok = true
fase = 5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN
visao = administrativa
cliente_safe = false
readonly = true
persistencia = true
dml_financeiro = false
escopo_dml = nenhum
altera_agenda = false
altera_parcelas = false
recalcula_operacao = false
```

Interpretação: a RPC 5D de detalhe é uma camada administrativa de leitura, sem executar mutações financeiras.

---

## 6. Campos financeiros 5B presentes

Foram validados campos financeiros e resumo financeiro para os três estados de operação.

Operação confirmada:

```text
valor_base = 1100
valor_movido = 1100
economia_liquida = 61.08
desconto_calculado = 61.08
acrescimo_calculado = 0
status_premio = sem_premio
premio_corretor_pct = 0
```

Operação cancelada:

```text
valor_base = 1300
valor_movido = 1300
economia_liquida = 60.31
desconto_calculado = 60.31
acrescimo_calculado = 0
status_premio = sem_premio
premio_corretor_pct = 0
```

Operação simulada:

```text
valor_base = 950
valor_movido = 950
economia_liquida = 35.31
desconto_calculado = 35.31
acrescimo_calculado = 0
status_premio = premio_parcial
premio_corretor_pct = 70
```

---

## 7. Auditoria 5C exposta corretamente

A operação confirmada retornou em `auditoria_5c`:

```text
confirmado = true
confirmado_por preenchido
confirmado_em preenchido
cancelado_por = null
cancelado_em = null
motivo_cancelamento = null
```

A operação cancelada retornou em `auditoria_5c`:

```text
confirmado = false
confirmado_por = null
confirmado_em = null
cancelado_por preenchido
cancelado_em preenchido
motivo_cancelamento = Cancelamento fixture 13B para validar detalhe 5D
```

A operação simulada retornou em `auditoria_5c`:

```text
confirmado = false
confirmado_por = null
confirmado_em = null
cancelado_por = null
cancelado_em = null
motivo_cancelamento = null
```

---

## 8. Vínculos preservados

Foram validados os vínculos:

```text
simulacao_id
agenda_id
parcela_origem_id
parcela_destino_id
```

Cada operação retornou exatamente a parcela de origem usada na fixture.

---

## 9. Metadata e checksum

Foram validados checksums individuais:

```text
confirmada_checksum = 3260c85b534339472e7b7310c58ad655
cancelada_checksum = cf091aaa654f2e70ee7d48127a97b0b4
simulada_checksum = fe0ad3c5d7d0f5d28e0c78cec0c30c06
```

Também foi validado que `metadata.parametros_nao_soberanos.origem_teste = 13b` nas três operações.

Para operações confirmada e cancelada, também foi validado:

```text
metadata.fase_5c.parametros_nao_soberanos.origem_teste = 13b
```

Isso confirma que a RPC preserva tanto a metadata de origem da 5B quanto a metadata administrativa da 5C.

---

## 10. Garantia read-only

O teste comparou snapshots antes e depois das chamadas 5D.

Resultado:

```text
hash_agenda_igual = true
hash_parcelas_igual = true
hash_operacoes_igual = true
```

Snapshots:

```text
agenda_full_hash antes  = bae02ed54e8734e3079782ef31fbd274
agenda_full_hash depois = bae02ed54e8734e3079782ef31fbd274

parcelas_full_hash antes  = 773db7daeecf0d23d54f82bc6b354bff
parcelas_full_hash depois = 773db7daeecf0d23d54f82bc6b354bff

operacoes_full_hash antes  = 8db33a0945c7e345c7dfe06375c19c7e
operacoes_full_hash depois = 8db33a0945c7e345c7dfe06375c19c7e
```

Isso comprova que a RPC 5D de detalhe não alterou agenda, parcelas nem operações.

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
13B = PASS
```

A RPC de detalhe administrativo da Fase 5D foi aprovada.

---

## 13. Próximo passo

Criar e executar o teste:

```text
supabase/tests/mesa-cliente/engenharia-financeira/13c_validacao_seguranca_leitura_operacoes_admin_rollback.sql
```

Objetivo do 13C:

```text
validar segurança negativa, tenant-safe e bloqueios de acesso indevido das RPCs 5D de leitura administrativa
```

O 13C deve cobrir:

```text
anon não executa RPCs 5D
usuário não autenticado não acessa
usuário de outra empresa não acessa operação/simulação de tenant diferente
p_simulacao_id soberano do banco, não do frontend
p_agenda_id incompatível não vaza dados
operação inexistente retorna erro controlado
filtros inválidos não causam vazamento
read-only preservado mesmo em cenários negativos
rollback final
```
