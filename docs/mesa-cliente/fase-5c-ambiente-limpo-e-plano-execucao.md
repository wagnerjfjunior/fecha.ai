# FECH.AI / MesaCliente — Fase 5C — Ambiente limpo e plano de execução

**Status:** ambiente preparado para início controlado da Fase 5C  
**Branch:** `feature/mesa-cliente-5c-confirmacao-cancelamento`  
**Base:** `main` após consolidação até a Fase 5B  
**Commit-base da main:** `48e57def24aa398d1bd317f12e824b16eeee0618`  
**Área:** Engenharia Financeira / MesaCliente  
**Data:** 2026-05-19

---

## 1. Veredito de preparação

A `main` foi atualizada com segurança até a Fase 5B por PR de consolidação.

A Fase 5C passa a seguir em branch limpa, criada a partir da `main`, sem carregar diretamente a branch longa `feature/mesa-cliente-engenharia-financeira`.

Esta decisão evita trazer commits posteriores, experimentos ou rascunhos de 5C/5D para a linha principal sem revisão.

---

## 2. Estado oficial herdado

A branch limpa parte do seguinte estado aprovado:

```text
4A = agenda financeira JSON-first, sem persistência
4B = persistência segura da agenda financeira
4C = leitura cliente-safe da agenda
5A = simulação administrativa de impacto, sem DML financeiro
5B = registro administrativo de operação financeira simulada
```

A partir daqui, a próxima etapa é:

```text
5C = confirmar/cancelar operação financeira registrada pela 5B
```

---

## 3. Regra de ouro da 5C

A 5C é uma transição de estado de uma operação já registrada.

Ela não deve recalcular a operação, não deve alterar agenda e não deve alterar parcelas.

```text
5B cria a operação simulada.
5C decide o estado da operação.
5C não muda a matemática da operação.
```

---

## 4. Escopo permitido da 5C

A Fase 5C pode:

```text
confirmar operação financeira simulada
cancelar operação financeira simulada
registrar usuário responsável pela transição
registrar timestamp da transição
registrar motivo administrativo no cancelamento
preservar cálculo original
preservar checksum_operacao
manter visivel_cliente=false
bloquear autoridade financeira vinda do frontend
```

---

## 5. Fora de escopo da 5C

A Fase 5C não pode:

```text
alterar parser
alterar Worker
alterar Make/n8n
alterar motor financeiro da agenda
alterar agenda financeira
alterar parcelas
alterar valor_movido
alterar valor_base
alterar desconto_calculado
alterar acrescimo_calculado
alterar economia_liquida
alterar checksum_operacao
aplicar efeito definitivo no fluxo da mesa
expor operação ao cliente automaticamente
aceitar empresa_id, taxa, status ou checksum como autoridade do frontend
```

Aplicação definitiva da operação no fluxo final, se necessária, deve ser fase própria posterior.

---

## 6. Decisões iniciais recomendadas

As decisões abaixo ficam como linha inicial até o preflight 12 confirmar o schema real:

```text
RPC única com p_acao: confirmar | cancelar
cancelar operação confirmada: bloqueado nesta primeira versão
confirmar operação já confirmada: idempotente=true, sem alterar confirmado_em
cancelar operação já cancelada: idempotente=true, sem alterar cancelado_em/motivo original
confirmar operação cancelada: bloqueado
visivel_cliente: sempre false na 5C
cancelamento: preferir colunas próprias se o schema ainda não tiver suporte explícito
```

---

## 7. RPC candidata

Assinatura candidata para análise após preflight:

```sql
public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  p_operacao_id uuid,
  p_acao text,
  p_motivo text default null,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
```

A RPC deve ser `SECURITY DEFINER`, com `search_path = public, pg_temp`, sem `EXECUTE` para `anon` e com `EXECUTE` apenas para `authenticated`.

---

## 8. Preflight oficial antes da migration

Antes de qualquer migration da 5C, deve ser executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql
```

Este preflight deve validar:

```text
schema real da tabela mesa_cliente_fluxo_operacoes
colunas de confirmação existentes
colunas de cancelamento existentes ou ausentes
constraints/status permitidos
índices relevantes
triggers de updated_at
RLS e policies
permissões de tabela
existência da RPC 5B
ausência da RPC 5C antes da migration
readiness para migration/RPC 5C
```

---

## 9. Arquivos esperados após preflight aprovado

Se o preflight 12 indicar prontidão, os próximos arquivos esperados são:

```text
supabase/migrations/<timestamp>_mesa_cliente_fase_5c_confirmacao_cancelamento_operacao_financeira.sql
supabase/tests/mesa-cliente/engenharia-financeira/12a_validacao_confirmar_operacao_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12b_validacao_cancelar_operacao_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12c_validacao_confirmacao_cancelamento_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/12e_validacao_zero_mutacao_agenda_parcelas_confirmacao_cancelamento_rollback.sql
```

---

## 10. Critério de fechamento da 5C

A Fase 5C só pode ser considerada fechada quando:

```text
contrato 5C validado
preflight 12 aprovado
migration 5C executada
12A aprovado
12B aprovado
12C aprovado
12D aprovado
12E aprovado
documentação de fechamento criada
índice operacional de testes atualizado
PR específico da 5C revisado e com deploy verde
```

---

## 11. Próxima ação

Executar o preflight 12 no Supabase SQL Editor e colar o resultset completo para análise.

Nada de migration antes disso.

Aqui a regra é simples: primeiro raio-X, depois bisturi. O banco agradece.
