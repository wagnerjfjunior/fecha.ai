# FECH.AI / MesaCliente — Fase 20D.5
# Evidência HTTP de bloqueio direto da tabela shadow

## 1. Objetivo

Registrar a evidência final de segurança HTTP da Fase 20D.5, comprovando que a tabela canônica shadow `public.mesa_fluxo_pagamentos_canonico` não é acessível diretamente por usuário autenticado via PostgREST.

Esse teste complementa as validações anteriores por SQL/role, grants e RLS.

---

## 2. Contexto

```text
Repositório: wagnerjfjunior/fecha.ai
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
PR: #29 — MesaCliente: preparar fluxo financeiro canônico shadow 20D
Ambiente Supabase: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Tabela testada: public.mesa_fluxo_pagamentos_canonico
Data do teste: 2026-05-29
```

A tabela shadow já havia sido validada com:

```text
RLS habilitado
anon sem privilégios diretos
authenticated sem privilégios diretos
service_role com DML
RPC criar_mesa_simulacao SECURITY DEFINER funcionando
```

---

## 3. Comando executado

Com `SUPABASE_ANON_KEY` válida e `USER_ACCESS_TOKEN` válido de usuário autenticado:

```bash
curl -i "$SUPABASE_URL/rest/v1/mesa_fluxo_pagamentos_canonico?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN"
```

---

## 4. Resultado real

```text
HTTP/2 403
date: Fri, 29 May 2026 15:39:12 GMT
content-type: application/json; charset=utf-8
proxy-status: PostgREST; error=42501
sb-project-ref: uobxxgzshrmbtjfdolxd
sb-request-id: 019e7463-b2e6-7dc1-9e27-39f75b3b3be8
```

Payload retornado:

```json
{
  "code": "42501",
  "details": null,
  "hint": null,
  "message": "permission denied for table mesa_fluxo_pagamentos_canonico"
}
```

---

## 5. Interpretação

```text
PASS: usuário authenticated não consegue executar SELECT direto na tabela shadow via PostgREST.
PASS: tabela shadow não está exposta como API pública de leitura.
PASS: o caminho operacional correto continua sendo RPC controlada, não CRUD direto.
PASS: a evidência HTTP confirma a proteção já observada em grants/RLS/role SQL.
```

---

## 6. Conclusão

A evidência HTTP negativa da tabela shadow está fechada.

Com isso, a bateria pré-merge da 20D.5 fica consolidada com:

```text
Migration aplicada: PASS
Tabela shadow criada: PASS
RLS habilitado: PASS
Grants corretos: PASS
RPC operacional via curl: PASS
Simulação E2E com unidade real 501: PASS
Escrita no legado: PASS
Escrita no canônico shadow: PASS
u -> parcela_unica_obra: PASS
f_residual -> financiamento_saldo: PASS
p -> periodicidade_obra: PASS
Bloqueio direto via SQL role: PASS
Bloqueio direto via HTTP/PostgREST: PASS
```

Nenhum token, API key, refresh token ou service role key foi registrado neste documento.
