# FECH.AI / MesaCliente — Fase 5C — Validação do Preflight 12

**Status:** aprovado com ressalva esperada  
**Branch:** `feature/mesa-cliente-5c-confirmacao-cancelamento`  
**Arquivo executado:** `supabase/tests/mesa-cliente/engenharia-financeira/12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql`  
**Fase:** 5C — confirmação/cancelamento de operação financeira  
**Data:** 2026-05-19

---

## 1. Veredito

O preflight 12 foi executado com sucesso e confirmou que a base está pronta para iniciar a migration/RPC da Fase 5C, com uma ressalva estrutural esperada:

```text
A base já suporta confirmação.
A base já aceita status cancelada.
A base ainda não possui colunas explícitas de auditoria de cancelamento.
```

Portanto, a migration 5C deve adicionar suporte explícito a cancelamento antes de criar a RPC final.

---

## 2. Resultado por bloco

| Bloco | Status | Interpretação |
|---|---:|---|
| 01_tabelas_obrigatorias | PASS | Todas as tabelas obrigatórias existem. |
| 02_colunas_operacoes_confirmacao_cancelamento | WARN | Core 5B e confirmação OK; faltam colunas de cancelamento. |
| 03_status_operacao_suporte | PASS | Constraint já aceita `simulada`, `confirmada`, `cancelada` e `bloqueada`. |
| 04_status_operacao_distribuicao_atual | INFO | Não há operações existentes no momento da leitura. |
| 05_indices_operacoes_para_5c | PASS | Índices necessários de checksum, agenda/parcela/status presentes. |
| 06_triggers_operacoes_updated_at | WARN | Não há trigger específico de `updated_at`; RPC deve setar `updated_at = now()` explicitamente. |
| 07_rls_policies_operacoes | PASS | RLS ativo; DML direto bloqueado para authenticated. |
| 08_grants_tabela_operacoes | PASS | `anon` sem DML; `authenticated` com SELECT apenas. |
| 09_funcoes_dependencias_e_ausencia_5c | PASS | RPC 5B existe; RPC 5C ainda não existe, como esperado. |
| 10_readiness_para_migration_5c | WARN | Base pronta para confirmação; cancelamento exige migration/decisão explícita. |
| 99_readonly_notice | INFO | Preflight foi somente leitura. |

---

## 3. Evidências principais

### 3.1 Tabelas obrigatórias

Todas existem:

```text
public.corretores
public.mesa_cliente_agendas_financeiras
public.mesa_cliente_fluxo_operacoes
public.mesa_cliente_fluxo_parcelas
public.mesa_simulacoes
```

### 3.2 Colunas de confirmação

Já existem:

```text
confirmado boolean not null default false
confirmado_por uuid null
confirmado_em timestamptz null
updated_at timestamptz not null default now()
```

Conclusão: confirmação pode ser implementada sem adicionar colunas novas.

### 3.3 Colunas de cancelamento ausentes

Ainda não existem:

```text
cancelado_por
cancelado_em
motivo_cancelamento
```

Conclusão: a migration 5C deve adicionar essas colunas para auditoria explícita do cancelamento.

Recomendação aprovada:

```sql
alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists cancelado_por uuid null,
  add column if not exists cancelado_em timestamptz null,
  add column if not exists motivo_cancelamento text null;
```

Se possível, adicionar FK de `cancelado_por` para `auth.users(id)` ou para a mesma referência já usada por `confirmado_por`, conforme padrão existente no projeto.

---

## 4. Status aceitos

A constraint atual já aceita:

```text
simulada
confirmada
cancelada
bloqueada
```

Constraint detectada:

```text
CHECK (status_operacao = ANY (ARRAY['simulada'::text, 'confirmada'::text, 'cancelada'::text, 'bloqueada'::text]))
```

Conclusão: não é necessário alterar constraint de status para suportar cancelamento.

---

## 5. Índices

Índices relevantes detectados:

```text
idx_mcfo_agenda_parcela_status
idx_mcfo_empresa_simulacao_agenda_status
idx_mcfo_simulacao_confirmado
idx_mcfo_simulacao_status
uq_mcfo_checksum_operacao_ativo
```

Conclusão: a base possui índices suficientes para consulta por agenda/parcela/status e para idempotência por checksum.

---

## 6. Triggers

Não há trigger de `updated_at` específico na tabela `mesa_cliente_fluxo_operacoes`.

Existe trigger de integridade:

```text
trg_mcfo_assert_integridade
```

Conclusão prática:

```text
A RPC 5C deve setar updated_at = now() explicitamente ao confirmar/cancelar.
```

Isso não é bloqueio. É apenas uma regra de implementação.

---

## 7. Segurança, RLS e grants

RLS está ativo em `mesa_cliente_fluxo_operacoes`.

Políticas relevantes:

```text
mcfo_no_direct_insert = INSERT bloqueado
mcfo_no_direct_update = UPDATE bloqueado
mcfo_no_direct_delete = DELETE bloqueado
mcfo_select_tenant = SELECT tenant-safe
```

Grants:

```text
anon_tem_dml = false
authenticated_tem_algum_grant = true
authenticated possui SELECT
```

Conclusão: a 5C deve continuar usando RPC `SECURITY DEFINER`. O frontend não deve receber permissão direta de UPDATE.

---

## 8. Dependência da 5B e ausência da 5C

Detectado:

```text
RPC 5B existe: true
RPC 5C candidata já existe: false
```

Conclusão: cenário ideal antes da migration 5C.

---

## 9. Decisões fechadas para a migration 5C

Com base no preflight, ficam aprovadas as seguintes decisões:

```text
1. Criar colunas explícitas de cancelamento.
2. Não alterar constraint de status_operacao.
3. Não alterar agenda.
4. Não alterar parcelas.
5. Criar RPC única com p_acao = confirmar | cancelar.
6. Manter visivel_cliente=false na 5C.
7. Confirmar operação já confirmada deve ser idempotente.
8. Cancelar operação já cancelada deve ser idempotente.
9. Confirmar operação cancelada deve bloquear.
10. Cancelar operação confirmada deve bloquear nesta versão.
11. RPC deve setar updated_at explicitamente.
```

---

## 10. Próximos arquivos oficiais

Criar em seguida:

```text
supabase/migrations/<timestamp>_mesa_cliente_fase_5c_confirmacao_cancelamento_operacao_financeira.sql
supabase/tests/mesa-cliente/engenharia-financeira/12a_validacao_confirmar_operacao_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12b_validacao_cancelar_operacao_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12c_validacao_confirmacao_cancelamento_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12e_validacao_zero_mutacao_agenda_parcelas_confirmacao_cancelamento_rollback.sql
```

---

## 11. Conclusão

O preflight 12 não encontrou bloqueio crítico.

A única pendência é estrutural e esperada: adicionar colunas explícitas de cancelamento. A base já está alinhada para confirmação, já suporta status `cancelada`, possui RLS correto, bloqueia DML direto e ainda não tem RPC 5C criada.

Próxima ação segura: criar migration/RPC da Fase 5C com foco exclusivo em transição de status da operação financeira.
