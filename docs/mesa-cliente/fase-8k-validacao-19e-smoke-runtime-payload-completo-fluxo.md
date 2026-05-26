# FECH.AI / MesaCliente — Fase 8K
# Validação 19E — Smoke runtime de payload completo do Fluxo

## 1. Identificação

Projeto: FECH.AI / MesaCliente  
Fase: 8K  
Validação: 19E — Smoke runtime de payload completo do Fluxo  
Branch: feature/mesa-cliente-fase-8-front-operacoes-financeiras  
Evidência analisada: HAR runtime `fecha-39ftk0rgl-wagnerjfjunior-3025s-projects.vercel.app.har`  
Status: PASS

## 2. Objetivo

Validar em runtime real que a tela Fluxo envia múltiplos grupos financeiros para a RPC `public.criar_mesa_simulacao` e que o banco persiste os mesmos itens em `public.mesa_fluxo_pagamentos`.

O 19E complementa o 19D:

- 19D validou estaticamente que o frontend estava preparado para payload completo.
- 19E validou funcionalmente browser + RPC + Supabase.

## 3. Resultado do HAR

Foi encontrada a chamada:

```text
POST https://uobxxgzshrmbtjfdolxd.supabase.co/rest/v1/rpc/criar_mesa_simulacao
```

Resultado:

```text
HTTP 200
```

Resposta da RPC:

```text
363fb2fe-6ee8-4da6-9d25-4118dd56a069
```

## 4. Payload enviado para a RPC

Resumo do request body:

```json
{
  "p_empresa_id": "[REDACTED_EMPRESA_ID]",
  "p_empreendimento_id": "2c513495-daf2-465b-9bea-33faebb8323b",
  "p_unidade_id": "f90b7c04-58c9-4a34-be9f-f991d51fc235",
  "p_lead_id": null,
  "p_cliente_nome": null,
  "p_valor_total": 4776208,
  "p_meta_obra_pct": 30,
  "p_tabela_provisoria": true
}
```

O `p_fluxo_json` enviado continha 7 itens:

| Ordem | Grupo | ID | Label | Valor | Qtd | Total | Data | Periodicidade | Source |
|---:|---|---|---|---:|---:|---:|---|---|---|
| 0 | `e` | `ato` | Ato | 428000 | 1 | 428000 | 2026-05-25 | null | parser |
| 1 | `c` | `c1` | +30 dias | 95500 | 1 | 95500 | null | null | parser |
| 2 | `c` | `c2` | +60 dias | 95500 | 1 | 95500 | null | null | parser |
| 3 | `c` | `c3` | +90 dias | 95500 | 1 | 95500 | null | null | parser |
| 4 | `m` | `m1` | Mensais | 38700 | 21 | 812700 | 2026-10-05 | null | parser |
| 5 | `a` | `a1` | Anuais | 143300 | 2 | 286600 | 2027-05-05 | anual | parser |
| 6 | `u` | `u1` | Parcela única | 348000 | 1 | 348000 | 2028-07-05 | null | parser |

Grupos presentes:

```text
e, c, m, a, u
```

Conclusão do HAR: o frontend enviou payload completo, incluindo parcela única/chaves como grupo `u`.

## 5. Persistência em mesa_simulacoes

Consulta ao Supabase confirmou o registro:

```text
id: 363fb2fe-6ee8-4da6-9d25-4118dd56a069
empresa_id: [REDACTED_EMPRESA_ID]
corretor_id: 9be9dae0-1699-49a2-a7ab-beeef274f22b
corretor_user_id: 10b90f39-84a5-49a4-8ba6-165ef7178f11
empreendimento_id: 2c513495-daf2-465b-9bea-33faebb8323b
unidade_estoque_id: f90b7c04-58c9-4a34-be9f-f991d51fc235
status: rascunho
valor_total: 4776208.00
entrada: 2161800.00
financiamento: 0.00
created_at: 2026-05-26 02:54:47.744216+00
```

Snapshot relevante:

```json
{
  "criado_por": "9be9dae0-1699-49a2-a7ab-beeef274f22b",
  "criado_por_user_id": "10b90f39-84a5-49a4-8ba6-165ef7178f11",
  "valor_tabela": 4776208,
  "valor_negociado": 4776208,
  "desconto_valor": 0,
  "tabela_provisoria": true
}
```

## 6. Persistência em mesa_fluxo_pagamentos

O banco persistiu 7 itens, na mesma cardinalidade do payload enviado.

| Ordem | Tipo persistido | Descrição | Valor | Qtd | Periodicidade | Data |
|---:|---|---|---:|---:|---|---|
| 0 | entrada | Ato | 428000.00 | 1 | null | 2026-05-25 |
| 1 | curto_prazo | +30 dias | 95500.00 | 1 | null | null |
| 2 | curto_prazo | +60 dias | 95500.00 | 1 | null | null |
| 3 | curto_prazo | +90 dias | 95500.00 | 1 | null | null |
| 4 | periodica | Mensais | 38700.00 | 21 | null | 2026-10-05 |
| 5 | intermediaria | Anuais | 143300.00 | 2 | anual | 2027-05-05 |
| 6 | quitacao | Parcela única | 348000.00 | 1 | null | 2028-07-05 |

Mapeamento validado:

```text
e -> entrada
c -> curto_prazo
m -> periodica
a -> intermediaria
u -> quitacao
```

Ponto crítico: parcela única foi enviada como grupo `u` no frontend e persistida corretamente como tipo técnico `quitacao`, preservando a descrição comercial `Parcela única`.

## 7. Auditoria

Consulta ao Supabase confirmou registro em `public.audit_logs`:

```text
id: bbaed323-b0a7-48f7-825d-b5dc8768f1a7
empresa_id: [REDACTED_EMPRESA_ID]
action: criar_mesa_simulacao
actor_id: 10b90f39-84a5-49a4-8ba6-165ef7178f11
ator_user_id: 10b90f39-84a5-49a4-8ba6-165ef7178f11
ator_corretor_id: 9be9dae0-1699-49a2-a7ab-beeef274f22b
acao: criar_mesa_simulacao
entidade: mesa_simulacoes
entidade_id: 363fb2fe-6ee8-4da6-9d25-4118dd56a069
created_at: 2026-05-26 02:54:47.744216+00
```

Payload de auditoria relevante:

```json
{
  "auth_uid": "10b90f39-84a5-49a4-8ba6-165ef7178f11",
  "corretor_id": "9be9dae0-1699-49a2-a7ab-beeef274f22b",
  "valor_total": 4776208,
  "num_parcelas": 7,
  "simulacao_id": "363fb2fe-6ee8-4da6-9d25-4118dd56a069"
}
```

## 8. Erros anteriores não ocorreram

Não ocorreram os erros corrigidos nas fases anteriores:

```text
42804 — status enum/texto
23503 — FK corretor_id
22P02 — enum mesa_fluxo_tipo = unica
schema antigo de audit_logs
```

## 9. Conclusão técnica

O 19E está aprovado.

Conclusões:

1. A RPC retornou HTTP 200.
2. A RPC retornou UUID válido.
3. O frontend enviou `p_fluxo_json` completo com 7 itens.
4. O payload incluiu todos os grupos relevantes: `e`, `c`, `m`, `a`, `u`.
5. A simulação foi gravada em `mesa_simulacoes`.
6. Os 7 itens foram persistidos em `mesa_fluxo_pagamentos`.
7. O grupo `u` foi persistido como `quitacao`, preservando label `Parcela única`.
8. A auditoria foi gravada corretamente em `audit_logs`.
9. A separação entre `auth.uid()` e `corretores.id` foi preservada.
10. O smoke runtime fechou payload enviado = payload persistido.

## 10. Status final

```text
19E = PASS
HTTP 200 = sim
UUID retornado = sim
Payload completo enviado = sim
Payload persistido integralmente = sim
Parcela única preservada = sim
Audit log gravado = sim
Erros anteriores = não ocorreram
```
