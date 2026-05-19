# FECH.AI / MesaCliente — Fechamento Técnico da Fase 5C

## 1. Marco

**Fase:** 5C — Confirmação e cancelamento administrativo de operação financeira  
**Status:** FECHADA TECNICAMENTE  
**Branch:** `feature/mesa-cliente-5c-confirmacao-cancelamento`  
**Base:** `main` em `48e57def24aa398d1bd317f12e824b16eeee0618`  
**Escopo:** backend Supabase/PostgreSQL — migration, RPC administrativa, grants, validações SQL e documentação

---

## 2. Objetivo da Fase 5C

A Fase 5C implementa a camada administrativa para alterar o status de operações financeiras previamente registradas pela Fase 5B.

A RPC criada permite:

```text
confirmar operação financeira simulada
cancelar operação financeira simulada
responder de forma idempotente quando a operação já estiver no estado final solicitado
bloquear transições proibidas
preservar agenda, parcelas e cálculo financeiro
```

---

## 3. RPC validada

```sql
public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  p_operacao_id uuid,
  p_acao text,
  p_motivo text default null,
  p_parametros jsonb default '{}'::jsonb
)
```

### 3.1 Ações suportadas

```text
confirmar
cancelar
```

### 3.2 Estados envolvidos

```text
simulada -> confirmada
simulada -> cancelada
confirmada -> confirmada   -- idempotente
cancelada -> cancelada     -- idempotente
cancelada -> confirmada    -- bloqueado
confirmada -> cancelada    -- bloqueado nesta versão
```

---

## 4. Contrato técnico fechado

A 5C altera somente a tabela:

```text
public.mesa_cliente_fluxo_operacoes
```

A 5C não pode:

```text
alterar agenda financeira
alterar parcelas
recalcular operação
alterar parser
alterar Worker
alterar Make/n8n
expor operação ao cliente automaticamente
aceitar autoridade soberana do frontend via payload
liberar execução para anon
permitir operação sem auth.uid()
```

---

## 5. Campos que podem ser alterados pela 5C

```text
status_operacao
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
updated_at
metadata.fase_5c
```

---

## 6. Campos que devem permanecer preservados

```text
id
simulacao_id
agenda_id
empresa_id
tipo_operacao
parcela_origem_id
campos financeiros e estruturais da operação
resultado/cálculo
checksum_operacao
visivel_cliente
agenda financeira
parcelas da agenda
```

---

## 7. Arquivos principais da Fase 5C

### 7.1 Migration

```text
supabase/migrations/20260519182000_mesa_cliente_fase_5c_confirmacao_cancelamento_operacao_financeira.sql
```

A migration:

- adiciona colunas explícitas de cancelamento quando necessário;
- cria a RPC administrativa da 5C;
- revoga execução de `anon`;
- libera execução apenas para `authenticated`;
- mantém DML direto protegido por RLS;
- mantém a operação invisível ao cliente;
- não altera agenda;
- não altera parcelas.

### 7.2 Testes SQL

```text
supabase/tests/mesa-cliente/engenharia-financeira/12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql
supabase/tests/mesa-cliente/engenharia-financeira/12a_validacao_confirmar_operacao_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12b_validacao_cancelar_operacao_financeira_simulada_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12c_validacao_negativos_seguranca_confirmacao_cancelamento_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12e_validacao_zero_mutacao_rigido_confirmacao_cancelamento_rollback.sql
```

### 7.3 Documentação de evidência

```text
docs/mesa-cliente/fase-5c-validacao-preflight-12.md
docs/mesa-cliente/fase-5c-validacao-12a-confirmacao-operacao-financeira.md
docs/mesa-cliente/fase-5c-validacao-12b-cancelamento-operacao-financeira.md
docs/mesa-cliente/fase-5c-validacao-12c-negativos-seguranca.md
docs/mesa-cliente/fase-5c-validacao-12d-idempotencia.md
docs/mesa-cliente/fase-5c-validacao-12e-zero-mutacao-rigido.md
```

---

## 8. Matriz de validação

| Teste | Status | Escopo validado |
|---|---:|---|
| Preflight 12 | PASS | Base pronta para 5C, com ressalva esperada antes da migration: colunas de cancelamento ausentes. |
| 12A | PASS | Confirmação positiva de operação financeira simulada. |
| 12B | PASS | Cancelamento positivo de operação financeira simulada. |
| 12C | PASS | Negativos, segurança, grants, payload autoritativo e transições bloqueadas. |
| 12D | PASS | Idempotência da confirmação e do cancelamento. |
| 12E | PASS | Zero mutação rígido de operação, agenda e parcelas. |

---

## 9. Segurança validada

### 9.1 Grants

```text
anon_execute = false
authenticated_execute = true
```

### 9.2 Bloqueios validados

```text
sem auth.uid() bloqueado
operação inexistente bloqueada
ação inválida bloqueada
p_parametros não objeto bloqueado
payload com autoridade soberana do frontend bloqueado
cancelamento sem motivo bloqueado
confirmar operação cancelada bloqueado
cancelar operação confirmada bloqueado nesta versão
```

### 9.3 SQLSTATEs esperados nos negativos

```text
28000 — acesso negado sem usuário autenticado
P0002 — operação financeira não encontrada
22023 — parâmetro inválido / ação inválida / cancelamento sem motivo
42501 — payload autoritativo proibido
55000 — transição de estado bloqueada
```

---

## 10. Integridade validada

A Fase 5C foi validada contra mutação indevida usando snapshots e hashes completos.

Foram preservados:

```text
agenda_id
agenda_checksum
agenda_full_hash
agenda_tots
parcelas_ids
parcelas_full_hash
valor_total_parcelas
checksum_operacao
visivel_cliente=false
campos financeiros e estruturais da operação
```

---

## 11. Decisões importantes

### 11.1 Cancelamento de operação confirmada

Nesta versão, o cancelamento de operação já confirmada permanece bloqueado.

Racional:

```text
Uma operação confirmada pode ter efeitos comerciais/administrativos posteriores.
Cancelar operação confirmada exige fluxo próprio de estorno/reversão, não simples troca de status.
```

### 11.2 Operação não é cliente-safe

A 5C é administrativa.

```text
cliente_safe = false
visao = administrativa
visivel_cliente = false
```

A exposição ao cliente deverá ser tratada em fase própria, com RPC específica de leitura segura ou publicação controlada.

### 11.3 Frontend não é soberano

A RPC bloqueia payload com autoridade indevida, como:

```text
empresa_id
tenant_id
corretor_id
user_id
confirmado_por
cancelado_por
status_operacao
```

O banco continua sendo a fonte soberana de tenant, empresa, perfil e autorização.

---

## 12. Fora do escopo preservado

Nada foi alterado em:

```text
parser
motor financeiro da 5B
agenda 4B
parcelas
Worker/Cloudflare
Make/n8n
frontend
exposição ao cliente
regras comerciais de comissão além do status administrativo
```

---

## 13. Próximo passo recomendado

Após merge da 5C na `main`, a próxima fase recomendada é:

```text
Fase 5D — Leitura/consulta administrativa das operações financeiras
```

Escopo sugerido da 5D:

```text
mesa_cliente_listar_operacoes_financeiras_admin
mesa_cliente_obter_operacao_financeira_admin
somente leitura
sem DML
sem recalcular operação
sem alterar agenda
sem alterar parcelas
validar auth.uid()
validar tenant/empresa/perfil no banco
bloquear anon
bloquear cross-tenant
retornar status, auditoria e dados administrativos controlados
```

---

## 14. Veredito final

```text
FASE 5C = FECHADA TECNICAMENTE
```

A Fase 5C está pronta para PR/merge na `main`, desde que o diff do PR permaneça restrito aos arquivos documentados e a main receba smoke/preflight após o merge.
