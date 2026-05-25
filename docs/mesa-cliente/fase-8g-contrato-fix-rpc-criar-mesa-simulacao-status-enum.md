# FECH.AI — MesaCliente
# Fase 8G — Contrato de Correção da RPC criar_mesa_simulacao para status enum

## 1. Identificação

Projeto: FECH.AI / MesaCliente  
Fase: 8G — Correção cirúrgica da RPC criar_mesa_simulacao  
Branch: feature/mesa-cliente-fase-8-front-operacoes-financeiras  
Risco: R3/R4 — RPC em banco real de produção única  
Status: contrato criado e autorizado para implementação controlada.

## 2. Contexto verificado

Durante o smoke manual da tela Fluxo, o salvamento da mesa falhou. O HAR enviado indicou chamada para a RPC criar_mesa_simulacao com falha HTTP 400.

Erro PostgreSQL observado:

```json
{
  "code": "42804",
  "message": "column \"status\" is of type mesa_simulacao_status but expression is of type text",
  "hint": "You will need to rewrite or cast the expression."
}
```

Consulta direta ao Supabase confirmou que a função aplicada no banco usa status textual inválido no bloco CASE. A coluna public.mesa_simulacoes.status é do tipo enum public.mesa_simulacao_status.

Valores verificados no enum:

```text
rascunho, em_analise, proposta_gerada, proposta_enviada, em_followup, aprovada, recusada, cancelada, expirada, prorrogada, revalidada
```

Valor inexistente no enum:

```text
aguardando_aprovacao
```

## 3. Objetivo

Corrigir exclusivamente a atribuição de status na RPC public.criar_mesa_simulacao, trocando o status inválido/textual por enum explícito válido.

Correção autorizada:

```sql
case
  when coalesce((v_desconto_validacao->>'requer_aprovacao')::boolean, false)
    then 'em_analise'::public.mesa_simulacao_status
  else 'rascunho'::public.mesa_simulacao_status
end
```

## 4. Escopo permitido

Permitido:

1. Criar migration corretiva posterior.
2. Recriar public.criar_mesa_simulacao preservando assinatura, security definer e search_path.
3. Corrigir somente o bloco de status.
4. Criar teste de validação estática da migration.
5. Criar documentação de validação posterior.

## 5. Fora de escopo

Não alterar frontend, parser, Worker, Make, n8n, motor financeiro 4A/4B/5A/5B/5C/5D, RPCs de operações financeiras, tabelas, enums, RLS, policies, agenda, parcelas, UX de taxa/juros ou cliente-safe.

Não criar novo valor no enum mesa_simulacao_status nesta fase.

## 6. Matriz de alteração

A migration altera apenas a definição da função public.criar_mesa_simulacao.

Não deve executar INSERT, UPDATE ou DELETE em mesa_simulacoes, mesa_fluxo_pagamentos ou audit_logs.

Não deve alterar o enum public.mesa_simulacao_status.

## 7. Segurança

A função deve permanecer com:

```sql
language plpgsql
security definer
set search_path = public
```

Permissões existentes não devem ser ampliadas. anon não deve receber EXECUTE.

## 8. Testes planejados

Criar teste 19A em:

```text
scripts/tests/mesa-cliente/19a_validacao_estatica_fix_criar_mesa_simulacao_status_enum.mjs
```

Validar:

- migration existe;
- contém create or replace function public.criar_mesa_simulacao;
- mantém assinatura da função;
- contém security definer;
- contém search_path public;
- não contém aguardando_aprovacao;
- contém em_analise com cast para public.mesa_simulacao_status;
- contém rascunho com cast para public.mesa_simulacao_status;
- não altera enum;
- não concede permissão nova para anon;
- não toca frontend/parser/Worker/Make/n8n.

## 9. Validação banco pós-aplicação

Após aplicar a migration no Supabase, validar a definição real da função com pg_get_functiondef e confirmar:

- função aplicada contém em_analise com cast enum;
- função aplicada contém rascunho com cast enum;
- função aplicada não contém aguardando_aprovacao;
- anon sem EXECUTE;
- authenticated com EXECUTE.

## 10. Critério de aceite

Aceitar quando:

1. Migration corretiva criada.
2. Teste 19A retorna PASS.
3. Workflow 19A retorna artifact sem FAIL.
4. Migration aplicada no Supabase sem erro.
5. Função real do banco não contém mais aguardando_aprovacao.
6. Função real contém casts para public.mesa_simulacao_status.
7. Smoke de salvar fluxo deixa de retornar erro 42804.

## 11. Critério de bloqueio

Bloquear se a migration alterar enum, tabela, permissões para anon, motor financeiro, frontend, ou se o teste 19A encontrar aguardando_aprovacao.

## 12. Decisão

A correção autorizada é cirúrgica: substituir o status inválido/textual usado na RPC criar_mesa_simulacao por valores válidos do enum public.mesa_simulacao_status com cast explícito.

Status: APROVADO PARA IMPLEMENTAÇÃO CONTROLADA.
