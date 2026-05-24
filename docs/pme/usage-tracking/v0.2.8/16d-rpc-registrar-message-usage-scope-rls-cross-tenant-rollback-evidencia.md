# FECH.AI — PME Usage Tracking v0.2.8

## Evidência 16D — Escopo/RLS/cross-tenant da RPC `pme_registrar_message_usage` com rollback

**Branch:** `feature/pme-usage-tracking-db-v0.2.8`  
**Teste:** `16D`  
**Arquivo executado:** `supabase/tests/pme/usage-tracking/16d_rpc_registrar_message_usage_scope_rls_cross_tenant_rollback.sql`  
**Tipo:** fixture transacional com `ROLLBACK`  
**DDL persistente:** não  
**DML:** sim, apenas fixture transacional  
**Persistência esperada:** nenhuma, por rollback  
**Status final:** `PASS`

---

## Objetivo

Validar o isolamento operacional por empresa da RPC:

```sql
public.pme_registrar_message_usage(uuid, jsonb)
```

Garantias avaliadas:

1. corretor owner da empresa do lead registra uso positivo;
2. outro corretor da mesma empresa registra uso positivo conforme regra atual de escopo por empresa;
3. corretor de outra empresa é bloqueado ao tentar usar lead de empresa alheia;
4. template de outra empresa é bloqueado mesmo com lead válido da empresa atual;
5. lead inexistente é bloqueado;
6. RLS permanece ativo nas tabelas PME envolvidas;
7. tentativas cross-tenant não geram mutação indevida.

---

## Resultado objetivo

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_setup_atores_escopo` | PASS | Selecionou empresa A, dois corretores da empresa A e corretor de empresa B. |
| `01_fixture_cross_tenant` | PASS | Criou lead/template da empresa A e template da empresa B dentro da transação. |
| `02_owner_mesma_empresa_registra` | PASS | Owner da empresa A registrou uso positivo. |
| `03_outro_corretor_mesma_empresa_registra` | PASS | Outro corretor da mesma empresa registrou uso positivo conforme regra atual por empresa. |
| `04_cross_tenant_user_bloqueado` | PASS | Usuário de outra empresa foi bloqueado com `pme_scope_denied / 42501`. |
| `05_template_cross_tenant_bloqueado` | PASS | Template de outra empresa foi bloqueado com `template_scope_denied_or_not_found / 42501`. |
| `06_lead_inexistente_bloqueado` | PASS | Lead inexistente foi bloqueado com `lead_not_found / P0002`. |
| `07_rls_tabelas_pme_ativo` | PASS | RLS ativo em `pme_message_templates` e `pme_message_usage`. |
| `08_cardinalidade_sem_mutacao_cross_tenant` | PASS | Apenas os 2 fluxos positivos geraram usage; 3 negativos foram bloqueados. |
| `99_rollback_notice` | INFO | Fixture encerrada com rollback. |

---

## Atores de escopo usados

```json
{
  "empresa_a": "[REDACTED_EMPRESA_ID]",
  "empresa_b": "1ed25526-7924-40e2-8a20-44dc4b9a25c0",
  "owner_user": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
  "owner_corretor": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "outro_mesma_empresa_user": "44c11521-4d07-45fe-a0c7-1859b2529732",
  "outro_mesma_empresa_corretor": "47485708-8fa0-4668-9c0a-212ed7137085",
  "cross_user": "a263f320-b61a-4866-80bc-d4882b3723c9",
  "cross_corretor": "84dfdc4c-9d5e-4658-9e8e-447b21b86762"
}
```

---

## Fixture criada

```json
{
  "lead_a": "9ca0c4f0-dc94-479b-8f8a-e396754c49dc",
  "empresa_a": "[REDACTED_EMPRESA_ID]",
  "empresa_b": "1ed25526-7924-40e2-8a20-44dc4b9a25c0",
  "template_a": "bc2edb85-0025-4310-85ca-3f698f314e35",
  "template_b": "88eed5d9-e511-491b-928a-22f88bca8e70",
  "usage_count_before": 0
}
```

---

## Positivos validados

### 1. Owner da empresa A

```json
{
  "ok": true,
  "dml": true,
  "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
  "visao": "operacional",
  "channel": "whatsapp",
  "lead_type": "lista_fria",
  "phase": "primeira_mensagem",
  "status": "copied",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "append_only": true
}
```

### 2. Outro corretor da mesma empresa

```json
{
  "ok": true,
  "dml": true,
  "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
  "visao": "operacional",
  "channel": "whatsapp",
  "lead_type": "lista_fria",
  "phase": "primeira_mensagem",
  "status": "copied",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "47485708-8fa0-4668-9c0a-212ed7137085",
  "append_only": true,
  "interpretacao": "escopo_atual_por_empresa_nao_por_owner_exclusivo_do_lead"
}
```

Leitura técnica: o escopo atual da RPC é por empresa, não por ownership exclusivo do lead.

---

## Negativos cross-tenant validados

### 1. Usuário de outra empresa tentando usar lead da empresa A

```json
{
  "message": "pme_scope_denied",
  "sqlstate": "42501"
}
```

### 2. Template de outra empresa com lead válido da empresa A

```json
{
  "message": "template_scope_denied_or_not_found",
  "sqlstate": "42501"
}
```

### 3. Lead inexistente

```json
{
  "message": "lead_not_found",
  "sqlstate": "P0002"
}
```

---

## RLS validado

```json
[
  {
    "relname": "pme_message_templates",
    "rls_ativo": true
  },
  {
    "relname": "pme_message_usage",
    "rls_ativo": true
  }
]
```

---

## Cardinalidade e ausência de mutação indevida

```json
{
  "lead_a": "9ca0c4f0-dc94-479b-8f8a-e396754c49dc",
  "usage_count_before": 0,
  "usage_count_after": 2,
  "positivos_esperados": 2,
  "negativos_bloqueados_esperados": 3
}
```

Interpretação:

- 2 registros foram gerados pelos fluxos positivos esperados;
- 3 tentativas negativas foram bloqueadas;
- não houve mutação indevida decorrente de cross-tenant/template inválido/lead inexistente.

---

## Saída executada

```json
[
  {
    "bloco": "00_setup_atores_escopo",
    "status": "PASS",
    "detalhe": {
      "empresa_a": "[REDACTED_EMPRESA_ID]",
      "empresa_b": "1ed25526-7924-40e2-8a20-44dc4b9a25c0",
      "cross_user": "a263f320-b61a-4866-80bc-d4882b3723c9",
      "owner_user": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
      "cross_corretor": "84dfdc4c-9d5e-4658-9e8e-447b21b86762",
      "owner_corretor": "e566f8c4-2c32-419a-bfe3-7491488edfed",
      "outro_mesma_empresa_user": "44c11521-4d07-45fe-a0c7-1859b2529732",
      "outro_mesma_empresa_corretor": "47485708-8fa0-4668-9c0a-212ed7137085"
    }
  },
  {
    "bloco": "01_fixture_cross_tenant",
    "status": "PASS",
    "detalhe": {
      "lead_a": "9ca0c4f0-dc94-479b-8f8a-e396754c49dc",
      "empresa_a": "[REDACTED_EMPRESA_ID]",
      "empresa_b": "1ed25526-7924-40e2-8a20-44dc4b9a25c0",
      "template_a": "bc2edb85-0025-4310-85ca-3f698f314e35",
      "template_b": "88eed5d9-e511-491b-928a-22f88bca8e70",
      "usage_count_before": 0
    }
  },
  {
    "bloco": "02_owner_mesma_empresa_registra",
    "status": "PASS",
    "detalhe": {
      "ok": true,
      "dml": true,
      "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
      "phase": "primeira_mensagem",
      "visao": "operacional",
      "status": "copied",
      "channel": "whatsapp",
      "lead_id": "9ca0c4f0-dc94-479b-8f8a-e396754c49dc",
      "usage_id": "5e445def-c2bd-418f-903f-3b9e31a1de7b",
      "lead_type": "lista_fria",
      "empresa_id": "[REDACTED_EMPRESA_ID]",
      "append_only": true,
      "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed"
    }
  },
  {
    "bloco": "03_outro_corretor_mesma_empresa_registra",
    "status": "PASS",
    "detalhe": {
      "ok": true,
      "dml": true,
      "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
      "phase": "primeira_mensagem",
      "visao": "operacional",
      "status": "copied",
      "channel": "whatsapp",
      "lead_id": "9ca0c4f0-dc94-479b-8f8a-e396754c49dc",
      "usage_id": "84274dbd-63c3-43a8-92f3-9633d1e6325d",
      "lead_type": "lista_fria",
      "empresa_id": "[REDACTED_EMPRESA_ID]",
      "append_only": true,
      "corretor_id": "47485708-8fa0-4668-9c0a-212ed7137085",
      "interpretacao": "escopo_atual_por_empresa_nao_por_owner_exclusivo_do_lead"
    }
  },
  {
    "bloco": "04_cross_tenant_user_bloqueado",
    "status": "PASS",
    "detalhe": {
      "message": "pme_scope_denied",
      "sqlstate": "42501"
    }
  },
  {
    "bloco": "05_template_cross_tenant_bloqueado",
    "status": "PASS",
    "detalhe": {
      "message": "template_scope_denied_or_not_found",
      "sqlstate": "42501"
    }
  },
  {
    "bloco": "06_lead_inexistente_bloqueado",
    "status": "PASS",
    "detalhe": {
      "message": "lead_not_found",
      "sqlstate": "P0002"
    }
  },
  {
    "bloco": "07_rls_tabelas_pme_ativo",
    "status": "PASS",
    "detalhe": [
      {
        "relname": "pme_message_templates",
        "rls_ativo": true
      },
      {
        "relname": "pme_message_usage",
        "rls_ativo": true
      }
    ]
  },
  {
    "bloco": "08_cardinalidade_sem_mutacao_cross_tenant",
    "status": "PASS",
    "detalhe": {
      "lead_a": "9ca0c4f0-dc94-479b-8f8a-e396754c49dc",
      "usage_count_after": 2,
      "usage_count_before": 0,
      "positivos_esperados": 2,
      "negativos_bloqueados_esperados": 3
    }
  },
  {
    "bloco": "99_rollback_notice",
    "status": "INFO",
    "detalhe": {
      "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
      "teste": "16D",
      "mensagem": "Teste 16D encerra com ROLLBACK. Fixtures e usos PME da transação não devem permanecer no banco.",
      "rollback": true,
      "validacao": "escopo/RLS/cross-tenant da RPC pme_registrar_message_usage",
      "dml_fixture": true,
      "ddl_persistente": false
    }
  }
]
```

---

## Conclusão

O **16D está aprovado**.

A RPC `public.pme_registrar_message_usage(uuid,jsonb)` demonstrou:

- escopo operacional correto por empresa;
- bloqueio cross-tenant efetivo;
- bloqueio de template fora da empresa do lead;
- bloqueio de lead inexistente;
- RLS ativo nas tabelas PME;
- ausência de mutação indevida nas tentativas negativas.

---

## Próximo passo

Criar e executar o **16E — Regressão final da v0.2.8**, validando em um único teste consolidado:

1. contrato/catálogo da RPC;
2. RLS/grants/hardening;
3. execução positiva da RPC;
4. segurança negativa essencial;
5. escopo cross-tenant essencial;
6. append-only;
7. rollback;
8. readiness para PR/merge.
