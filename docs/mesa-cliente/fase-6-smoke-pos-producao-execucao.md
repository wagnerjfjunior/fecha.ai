# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 6 — Smoke pós-produção

**Branch:** `feature/mesa-cliente-fase-6-smoke-pos-producao`

**Base:** `main` pós-merge da PR #12

**Tipo de validação:** smoke pós-produção read-only

**Script:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/14f_smoke_pos_producao_fase_6_readonly.sql
```

---

## 1. Objetivo

Validar, após merge da Fase 6 na `main`, que as RPCs read-only de resumo de operação financeira foram aplicadas corretamente no ambiente e que o catálogo das funções permanece aderente ao contrato técnico aprovado.

RPCs avaliadas:

```text
public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
```

---

## 2. Restrições do smoke

Este smoke foi executado com restrição explícita:

```sql
start transaction read only;
...
rollback;
```

Garantias do teste:

| Item | Situação |
|---|---:|
| DDL | Não executado |
| DML | Não executado |
| Fixture | Não criada |
| Inserção | Não executada |
| Update | Não executado |
| Delete | Não executado |
| Persistência de teste | Nenhuma |
| Encerramento | `ROLLBACK` |

---

## 3. Resultado executado

Resultado retornado pelo smoke:

```json
[
  {
    "bloco": "00_contrato_rpc_catalogo",
    "status": "PASS",
    "detalhe": {
      "funcoes": [
        {
          "proacl": "{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}",
          "proname": "mesa_cliente_obter_resumo_operacao_cliente_safe",
          "volatility": "s",
          "search_path": [
            "search_path=public, pg_temp"
          ],
          "anon_execute": false,
          "security_definer": true,
          "comentario_presente": true,
          "authenticated_execute": true
        },
        {
          "proacl": "{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}",
          "proname": "mesa_cliente_resumir_operacao_financeira_admin",
          "volatility": "s",
          "search_path": [
            "search_path=public, pg_temp"
          ],
          "anon_execute": false,
          "security_definer": true,
          "comentario_presente": true,
          "authenticated_execute": true
        }
      ]
    }
  },
  {
    "bloco": "01_operacao_real_visivel_disponivel",
    "status": "SKIP",
    "detalhe": {
      "mensagem": "Sem operacao real visivel_cliente=true. Smoke mantido valido para catalogo; execucao das RPCs deve ser repetida quando houver operacao real liberada ao cliente."
    }
  },
  {
    "bloco": "02_execucao_rpc_admin_readonly_real",
    "status": "SKIP",
    "detalhe": {
      "mensagem": "Execucao admin ignorada por ausencia de operacao real elegivel ou contexto auth elegivel."
    }
  },
  {
    "bloco": "03_execucao_rpc_cliente_safe_readonly_real",
    "status": "SKIP",
    "detalhe": {
      "mensagem": "Execucao cliente-safe ignorada por ausencia de operacao real elegivel ou contexto auth elegivel."
    }
  },
  {
    "bloco": "04_cliente_safe_sem_vazamento_real",
    "status": "SKIP",
    "detalhe": {
      "mensagem": "Inspecao de vazamento ignorada por ausencia de payload cliente-safe real."
    }
  },
  {
    "bloco": "99_interpretacao_operacional",
    "status": "INFO",
    "detalhe": {
      "ddl": false,
      "dml": false,
      "fase": "6_RESUMOS_OPERACAO_FINANCEIRA",
      "tipo": "smoke_pos_producao_readonly",
      "fixture": false,
      "observacao": "Smoke executado em transaction read only. SKIP por ausencia de operacao real elegivel nao reprova catalogo nem deployment."
    }
  }
]
```

---

## 4. Interpretação técnica

O bloco de catálogo passou com sucesso.

As duas RPCs da Fase 6 existem no schema `public` e preservam:

| Item | Resultado |
|---|---:|
| `SECURITY DEFINER` | PASS |
| `STABLE` | PASS |
| `search_path=public, pg_temp` | PASS |
| `EXECUTE` para `authenticated` | PASS |
| `EXECUTE` negado para `anon` | PASS |
| Comentário de catálogo | PASS |
| ACL sem grant público implícito | PASS |

A execução das RPCs sobre operação real foi classificada como `SKIP`, porque não havia operação real elegível com `visivel_cliente=true` no ambiente no momento do smoke.

Esse `SKIP` não reprova a Fase 6 nem o deployment, porque o smoke pós-produção foi desenhado para não criar fixture e não alterar dados em produção.

---

## 5. Conclusão

Status do smoke pós-produção da Fase 6:

```text
APROVADO COM RESSALVA OPERACIONAL CONTROLADA
```

A ressalva é objetiva e não indica falha técnica:

```text
Não havia operação real elegível com visivel_cliente=true para executar as RPCs sobre massa real.
```

O contrato de catálogo e segurança das RPCs foi validado em produção.

Quando houver operação real liberada ao cliente, o script `14F` deve ser reexecutado para validar também os blocos:

```text
02_execucao_rpc_admin_readonly_real
03_execucao_rpc_cliente_safe_readonly_real
04_cliente_safe_sem_vazamento_real
```

Até lá, a Fase 6 permanece válida pelo conjunto:

```text
14, 14A, 14B, 14C, 14D, 14E aprovados em fixture transacional
14F aprovado em catálogo pós-produção read-only
```
