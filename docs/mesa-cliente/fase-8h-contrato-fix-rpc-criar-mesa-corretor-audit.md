# FECH.AI — MesaCliente
# Fase 8H — Contrato de Correção da RPC criar_mesa_simulacao para corretor_id e audit_logs

## 1. Identificação

Projeto: FECH.AI / MesaCliente  
Fase: 8H — Correção cirúrgica da RPC criar_mesa_simulacao  
Branch: feature/mesa-cliente-fase-8-front-operacoes-financeiras  
Risco: R3/R4 — RPC em banco real de produção única  
Status: contrato criado e autorizado para implementação controlada.

## 2. Contexto verificado

Após a correção 8G do enum `mesa_simulacao_status`, o salvamento do Fluxo avançou e passou a falhar em outro ponto real da mesma RPC.

Erro observado no HAR:

```text
HTTP 409
code = 23503
foreign key constraint "mesa_simulacoes_corretor_id_fkey"
```

Diagnóstico confirmado no Supabase:

```text
mesa_simulacoes.corretor_id -> public.corretores.id
audit_logs.ator_corretor_id -> public.corretores.id
```

A RPC ainda usava:

```sql
v_corretor_id := v_auth_uid;
```

Isso é incorreto, pois `auth.uid()` representa o usuário autenticado, enquanto `mesa_simulacoes.corretor_id` exige o identificador comercial `public.corretores.id`.

Também foi confirmado que a tabela `audit_logs` real não usa o schema antigo esperado pela RPC:

Colunas antigas tentadas pela RPC:

```text
usuario_id
tabela_afetada
registro_id
detalhes
```

Colunas reais relevantes:

```text
action
actor_id
payload
ator_user_id
ator_corretor_id
acao
entidade
entidade_id
depois
```

Além disso, `action`, `acao` e `entidade` são NOT NULL.

## 3. Objetivo

Corrigir exclusivamente a RPC `public.criar_mesa_simulacao` para:

1. Resolver `v_corretor_id` a partir de `public.corretores.id`.
2. Manter `v_auth_uid` separado como usuário autenticado.
3. Inserir `mesa_simulacoes.corretor_id` com `corretores.id`.
4. Inserir `audit_logs` usando o schema real.
5. Preservar a correção 8G do enum status.

## 4. Correção autorizada

Substituir a resolução atual por:

```sql
select c.id, c.empresa_id
into v_corretor_id, v_user_empresa_id
from public.corretores c
where c.user_id = v_auth_uid
  and coalesce(c.ativo, true) = true
limit 1;
```

Ajustar auditoria para usar:

```sql
insert into public.audit_logs (
  empresa_id,
  action,
  actor_id,
  payload,
  ator_user_id,
  ator_corretor_id,
  acao,
  entidade,
  entidade_id,
  depois
) values (...)
```

## 5. Escopo permitido

Permitido:

1. Criar migration corretiva posterior à 8G.
2. Recriar `public.criar_mesa_simulacao` preservando assinatura, `security definer` e `search_path`.
3. Corrigir resolução de corretor.
4. Corrigir insert em audit_logs para schema real.
5. Criar teste estático 19B.
6. Aplicar e validar a função no Supabase após PASS do artefato.

## 6. Fora de escopo

Não alterar:

- frontend;
- parser;
- Worker;
- Make;
- n8n;
- motor financeiro 4A/4B/5A/5B/5C/5D;
- RPCs de operações financeiras;
- tabelas;
- enums;
- RLS;
- policies;
- grants;
- agenda;
- parcelas;
- UX de taxa/juros;
- cliente-safe.

## 7. Segurança

A função deve permanecer com:

```sql
language plpgsql
security definer
set search_path = public
```

Permissões existentes não devem ser ampliadas. `anon` não deve receber `EXECUTE`.

## 8. Critérios de aceite

Aceitar quando:

1. Migration corretiva criada.
2. Teste 19B retorna PASS.
3. Migration aplicada no Supabase sem erro.
4. Função real não contém `v_corretor_id := v_auth_uid`.
5. Função real contém `select c.id, c.empresa_id into v_corretor_id, v_user_empresa_id`.
6. Função real insere em `audit_logs` usando `action`, `actor_id`, `payload`, `ator_user_id`, `ator_corretor_id`, `acao`, `entidade`, `entidade_id`, `depois`.
7. Função real preserva casts enum para `em_analise` e `rascunho`.
8. Smoke de salvar fluxo deixa de retornar erro `23503`.

## 9. Decisão

A correção autorizada é cirúrgica: separar `auth.uid()` de `corretores.id` e alinhar o insert de auditoria ao schema real de `audit_logs`, sem mudar motor financeiro, parser, frontend ou estruturas de banco.

Status: APROVADO PARA IMPLEMENTAÇÃO CONTROLADA.
