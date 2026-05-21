# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 7 — Execução do Preflight 15

**Branch:** `feature/mesa-cliente-pos-fase-6-proxima-fase`

**Script:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/15_preflight_aplicacao_operacao_financeira.sql
```

**Tipo:** preflight estrutural read-only.

---

## 1. Objetivo

Validar se o banco está tecnicamente pronto para iniciar a Fase 7, cujo objetivo é criar uma RPC administrativa para aplicação controlada de operação financeira na agenda.

RPC esperada para a próxima migration:

```text
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

---

## 2. Garantias da execução

O preflight foi executado com:

```sql
start transaction read only;
...
rollback;
```

Garantias:

| Item | Resultado |
|---|---:|
| DDL | Não executado |
| DML | Não executado |
| Fixture | Não criada |
| Alteração em agenda | Não executada |
| Alteração em parcelas | Não executada |
| Alteração em operações | Não executada |
| Persistência de teste | Nenhuma |
| Encerramento | `ROLLBACK` |

---

## 3. Resultado retornado

```json
[
  {
    "bloco": "01_tabelas_obrigatorias",
    "status": "PASS",
    "detalhe": [
      { "existe": true, "tabela": "corretores" },
      { "existe": true, "tabela": "mesa_cliente_agendas_financeiras" },
      { "existe": true, "tabela": "mesa_cliente_fluxo_operacoes" },
      { "existe": true, "tabela": "mesa_cliente_fluxo_parcelas" },
      { "existe": true, "tabela": "mesa_simulacoes" }
    ]
  },
  {
    "bloco": "02_colunas_obrigatorias_fase_7",
    "status": "PASS",
    "detalhe": {
      "qtd_ok": 76,
      "faltantes": [],
      "qtd_total": 76
    }
  },
  {
    "bloco": "03_funcoes_dependencia",
    "status": "PASS",
    "detalhe": [
      {
        "nome": "mesa_cliente_obter_resumo_operacao_cliente_safe",
        "existe": true,
        "proacl": "{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}",
        "volatility": "s",
        "search_path": ["search_path=public, pg_temp"],
        "anon_execute": false,
        "security_definer": true,
        "comentario_presente": true,
        "authenticated_execute": true
      },
      {
        "nome": "mesa_cliente_persistir_agenda_financeira_admin",
        "existe": true,
        "proacl": "{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}",
        "volatility": "v",
        "search_path": ["search_path=public"],
        "anon_execute": false,
        "security_definer": true,
        "comentario_presente": true,
        "authenticated_execute": true
      },
      {
        "nome": "mesa_cliente_registrar_operacao_financeira_admin",
        "existe": true,
        "proacl": "{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}",
        "volatility": "v",
        "search_path": ["search_path=public, pg_temp"],
        "anon_execute": false,
        "security_definer": true,
        "comentario_presente": true,
        "authenticated_execute": true
      },
      {
        "nome": "mesa_cliente_resumir_operacao_financeira_admin",
        "existe": true,
        "proacl": "{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}",
        "volatility": "s",
        "search_path": ["search_path=public, pg_temp"],
        "anon_execute": false,
        "security_definer": true,
        "comentario_presente": true,
        "authenticated_execute": true
      }
    ]
  },
  {
    "bloco": "04_rls_ativo_tabelas_alvo",
    "status": "PASS",
    "detalhe": [
      { "tablename": "corretores", "schemaname": "public", "rowsecurity": true },
      { "tablename": "mesa_cliente_agendas_financeiras", "schemaname": "public", "rowsecurity": true },
      { "tablename": "mesa_cliente_fluxo_operacoes", "schemaname": "public", "rowsecurity": true },
      { "tablename": "mesa_cliente_fluxo_parcelas", "schemaname": "public", "rowsecurity": true },
      { "tablename": "mesa_simulacoes", "schemaname": "public", "rowsecurity": true }
    ]
  },
  {
    "bloco": "05_bloqueios_dml_direto_financeiro",
    "status": "PASS",
    "detalhe": {
      "mcfo_delete_block": true,
      "mcfo_insert_block": true,
      "mcfo_update_block": true,
      "mcfp_delete_block": true,
      "mcfp_insert_block": true,
      "mcfp_update_block": true
    }
  },
  {
    "bloco": "06_status_operacao_existentes",
    "status": "INFO",
    "detalhe": []
  },
  {
    "bloco": "07_tipos_operacao_existentes",
    "status": "INFO",
    "detalhe": []
  },
  {
    "bloco": "08_probe_operacao_candidata_fase_7",
    "status": "SKIP",
    "detalhe": {
      "mensagem": "Sem operacao candidata real com agenda_id para probe. Isto nao bloqueia preflight; testes positivos devem usar fixture transacional."
    }
  },
  {
    "bloco": "09_readiness_fase_7",
    "status": "PASS",
    "detalhe": {
      "fase": "7_APLICACAO_OPERACAO_FINANCEIRA",
      "observacao": "Preflight read-only. Nenhuma aplicacao financeira foi executada.",
      "readiness_tecnico": true,
      "proxima_rpc_esperada": "public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)"
    }
  },
  {
    "bloco": "99_interpretacao_operacional",
    "status": "INFO",
    "detalhe": {
      "ddl": false,
      "dml": false,
      "tipo": "preflight_fase_7_readonly",
      "fixture": false,
      "mensagem": "Se 09_readiness_fase_7=PASS, a migration da RPC de aplicacao pode ser desenhada. Se FAIL, corrigir contrato/schema antes de qualquer DML financeiro.",
      "rollback": true
    }
  }
]
```

---

## 4. Interpretação técnica

O preflight 15 foi aprovado.

Pontos validados:

| Bloco | Status | Leitura |
|---|---:|---|
| Tabelas obrigatórias | PASS | Todas as tabelas críticas existem. |
| Colunas obrigatórias | PASS | 76/76 colunas encontradas. |
| Funções dependentes | PASS | RPCs das fases 4B, 5B e 6 existem. |
| RLS | PASS | RLS ativo nas 5 tabelas avaliadas. |
| Bloqueio DML direto | PASS | Inserts, updates e deletes diretos continuam bloqueados em operações e parcelas. |
| Status/tipos existentes | INFO | Não há massa real atual em operações. |
| Operação candidata | SKIP | Sem operação real com `agenda_id`; não bloqueia a fase. |
| Readiness Fase 7 | PASS | Banco pronto para desenhar migration da RPC de aplicação. |

---

## 5. Conclusão

Status do preflight:

```text
15_preflight_aplicacao_operacao_financeira.sql = APROVADO
```

A Fase 7 está liberada tecnicamente para a próxima etapa:

```text
Migration da RPC public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

A ausência de operação real não bloqueia a fase, porque os testes positivos e negativos da Fase 7 devem usar fixture transacional controlada com `BEGIN` + `ROLLBACK`.

---

## 6. Próximo passo

Criar a migration da Fase 7 com a RPC administrativa de aplicação controlada.

A RPC deve ser `SECURITY DEFINER`, com `search_path=public, pg_temp`, acesso apenas para `authenticated` e bloqueio explícito para `anon`.

A implementação deve respeitar as travas do contrato da Fase 7:

- banco como autoridade;
- sem parâmetros soberanos vindos do frontend;
- validação de auth;
- validação de perfil administrativo;
- validação de tenant;
- lock transacional;
- idempotência;
- atualização rastreável de operação e parcelas;
- retorno administrativo;
- sem exposição cliente-safe.
