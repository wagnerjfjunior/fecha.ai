# FECH.AI / MesaCliente — Fase 20A
# Validação — RPC Reabrir Fluxo pelo Histórico

## 1. Identificação

Projeto: FECH.AI / MesaCliente  
Fase: 20A  
Validação: RPC read-only para reabrir/visualizar fluxo salvo pelo Histórico  
RPC: `public.mesa_cliente_obter_simulacao_fluxo_historico(uuid, jsonb)`  
Simulação de referência: `363fb2fe-6ee8-4da6-9d25-4118dd56a069`  
Status: PASS estrutural + PASS positivo + PASS negativo de segurança

## 2. Objetivo

Validar que a RPC 20A consegue reconstruir uma simulação histórica com seu fluxo salvo, sem alterar dados, respeitando autenticação, tenant e permissões.

## 3. Validação estrutural

A RPC foi validada no Supabase com os seguintes pontos:

```text
security_definer = true
search_path = public
auth.uid() = presente
payload_soberano_frontend = false
insert/update/delete = false
grant anon = removido
grant public = removido
grant authenticated = presente
```

ACL validada:

```text
{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

Conclusão: a RPC não está exposta para `anon`/`public` e só pode ser executada por sessão autenticada, service_role ou postgres.

## 4. Teste positivo

Usuário autenticado usado no teste:

```text
10b90f39-84a5-49a4-8ba6-165ef7178f11
```

Simulação usada:

```text
363fb2fe-6ee8-4da6-9d25-4118dd56a069
```

Resultado:

```json
{
  "ok": true,
  "readonly": true,
  "cliente_safe": false,
  "source": "historico",
  "fluxo_count": 7,
  "grupos": ["a", "c", "e", "m", "u"],
  "simulacao_id": "363fb2fe-6ee8-4da6-9d25-4118dd56a069",
  "auth_uid": "10b90f39-84a5-49a4-8ba6-165ef7178f11",
  "pode_editar_original": "false"
}
```

Conclusões do teste positivo:

- a RPC retornou `ok=true`;
- retornou `readonly=true`;
- retornou `cliente_safe=false`;
- reconstruiu 7 itens do fluxo salvo;
- preservou todos os grupos do smoke 19E: `e`, `c`, `m`, `a`, `u`;
- bloqueou edição direta do original com `pode_editar_original=false`.

## 5. Teste negativo cross-tenant

Usuário autenticado de outra empresa usado no teste:

```text
a263f320-b61a-4866-80bc-d4882b3723c9
```

Empresa desse usuário:

```text
1ed25526-7924-40e2-8a20-44dc4b9a25c0
```

Tentativa de acessar a simulação da empresa:

```text
[REDACTED_EMPRESA_ID]
```

Resultado real:

```text
ERROR: P0001: Acesso negado à simulação informada
```

Conclusão: acesso cross-tenant bloqueado corretamente.

## 6. Teste negativo sem autenticação

Execução sem `auth.uid()` válido.

Resultado real:

```text
ERROR: P0001: Usuário não autenticado
```

Conclusão: a RPC bloqueia leitura sem autenticação.

## 7. Escopo preservado

Durante a validação:

```text
DML financeiro: não
Alteração de mesa_simulacoes: não
Alteração de mesa_fluxo_pagamentos: não
Alteração de audit_logs: não
Alteração de parser: não
Alteração de Worker/Make: não
Alteração de motor financeiro: não
```

## 8. Conclusão técnica

A RPC 20A está aprovada para uso pela camada frontend.

Ela permite:

```text
Histórico -> obter detalhe completo da simulação -> reconstruir fluxo salvo -> abrir em modo seguro
```

Sem permitir edição direta do histórico original.

## 9. Próximo passo

Implementar o front da 20B:

- adicionar helper API para chamar a RPC 20A;
- adicionar hook no `useMesaData`;
- adicionar botão no `TabHistorico` para reabrir/visualizar fluxo;
- fazer `MesaCliente/index.jsx` carregar o fluxo histórico em `TabFluxo`;
- manter edição direta bloqueada nesta primeira versão.

## 10. Status

```text
20A contrato = PASS
20A RPC = PASS
20A grant hardening = PASS
20A positivo = PASS
20A negativo cross-tenant = PASS
20A negativo sem auth = PASS
pronto para 20B front = sim
```
