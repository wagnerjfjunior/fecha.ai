# FECH.AI — PME Usage Tracking v0.2.8

## Evidência 16B — RPC positiva `pme_registrar_message_usage` com rollback

**Branch:** `feature/pme-usage-tracking-db-v0.2.8`  
**Teste:** `16B`  
**Arquivo executado:** `supabase/tests/pme/usage-tracking/16b_rpc_registrar_message_usage_positive_rollback.sql`  
**Tipo:** fixture transacional com `ROLLBACK`  
**DDL:** não  
**DML:** sim, apenas fixture transacional  
**Persistência esperada:** nenhuma, por rollback  
**Status final:** `PASS`

---

## Objetivo

Validar funcionalmente a RPC:

```sql
public.pme_registrar_message_usage(uuid, jsonb)
```

com cenário positivo, garantindo:

1. contexto autenticado elegível via `request.jwt.claim.sub`;
2. lead válido com `status = 'distribuido'`, compatível com `public.leads.leads_status_check`;
3. template PME válido na mesma empresa;
4. `empresa_id` derivado do banco, não do frontend;
5. `corretor_id` derivado do contexto autenticado;
6. inserção controlada em `public.pme_message_usage`;
7. retorno `ok=true`, `append_only=true`, `dml=true`;
8. cardinalidade exata de 1 uso para a fixture;
9. encerramento com `ROLLBACK`.

---

## Resultado objetivo

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_contexto_auth_fixture` | PASS | Usuário/corretor/empresa elegíveis identificados para simulação autenticada. |
| `01_fixture_lead_template` | PASS | Lead e template PME criados dentro da transação. |
| `02_rpc_registrar_usage_basico` | PASS | RPC executou com `ok=true`, `append_only=true` e `dml=true`. |
| `03_soberania_empresa_corretor_derivados` | PASS | `empresa_id` e `corretor_id` foram derivados corretamente do banco/contexto. |
| `04_usage_persistido_na_transacao` | PASS | Linha append-only apareceu em `pme_message_usage` durante a transação. |
| `05_cardinalidade_usage_fixture` | PASS | Exatamente 1 registro de uso para a fixture. |
| `99_rollback_notice` | INFO | Teste encerra com rollback; lead/template/usage não devem persistir. |

---

## Pontos técnicos validados

### 1. Contexto autenticado

O teste simulou `auth.uid()` via `request.jwt.claim.sub` usando usuário elegível do banco real:

```json
{
  "user_id": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed"
}
```

### 2. Fixture compatível com schema real de leads

A primeira tentativa do 16B falhou corretamente por violação de `leads_status_check`, porque `em_atendimento` não era status válido em `public.leads`.

O teste foi corrigido para usar:

```sql
status = 'distribuido'
```

Status válidos da constraint real:

```text
disponivel
distribuido
finalizado
invalido
```

### 3. Soberania de tenant operacional

A RPC retornou `empresa_id` igual ao `empresa_id` da fixture e não aceitou `empresa_id` vindo do payload frontend. A origem da autoridade permaneceu no banco.

Resultado validado:

```json
{
  "empresa_id_rpc": "[REDACTED_EMPRESA_ID]",
  "corretor_id_rpc": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "empresa_id_esperado": "[REDACTED_EMPRESA_ID]",
  "corretor_id_esperado": "e566f8c4-2c32-419a-bfe3-7491488edfed"
}
```

### 4. Append-only positivo

A RPC criou exatamente 1 linha em `public.pme_message_usage` dentro da transação:

```json
{
  "usage_id": "eeacc442-c05a-4af9-8355-5abdb0ee88ac",
  "channel": "whatsapp",
  "lead_type": "lista_fria",
  "phase": "primeira_mensagem",
  "selection_mode": "suggested",
  "status": "copied",
  "feedback_key": "teste_16b_positive",
  "metadata": {
    "origem": "teste_16b_pme_usage_tracking",
    "fixture_transacional": true,
    "frontend_sem_autoridade_soberana": true
  },
  "created_at_presente": true
}
```

### 5. Rollback

O teste encerrou com:

```text
ROLLBACK
```

Portanto, os registros de fixture abaixo não devem permanecer no banco:

- lead de teste;
- template de teste;
- uso PME de teste.

---

## Saída executada

```json
[
  {
    "bloco": "00_contexto_auth_fixture",
    "status": "PASS",
    "detalhe": {
      "user_id": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
      "empresa_id": "[REDACTED_EMPRESA_ID]",
      "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed"
    }
  },
  {
    "bloco": "01_fixture_lead_template",
    "status": "PASS",
    "detalhe": {
      "lead_id": "701b657a-ee8e-4cbd-91f3-497e69abce9c",
      "empresa_id": "[REDACTED_EMPRESA_ID]",
      "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
      "template_id": "3236427d-a7d7-4fd4-be85-0525fd521d0f",
      "lead_status_fixture": "distribuido"
    }
  },
  {
    "bloco": "02_rpc_registrar_usage_basico",
    "status": "PASS",
    "detalhe": {
      "ok": true,
      "dml": true,
      "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
      "phase": "primeira_mensagem",
      "visao": "operacional",
      "status": "copied",
      "channel": "whatsapp",
      "lead_id": "701b657a-ee8e-4cbd-91f3-497e69abce9c",
      "usage_id": "eeacc442-c05a-4af9-8355-5abdb0ee88ac",
      "lead_type": "lista_fria",
      "empresa_id": "[REDACTED_EMPRESA_ID]",
      "append_only": true,
      "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed"
    }
  },
  {
    "bloco": "03_soberania_empresa_corretor_derivados",
    "status": "PASS",
    "detalhe": {
      "empresa_id_rpc": "[REDACTED_EMPRESA_ID]",
      "corretor_id_rpc": "e566f8c4-2c32-419a-bfe3-7491488edfed",
      "empresa_id_esperado": "[REDACTED_EMPRESA_ID]",
      "corretor_id_esperado": "e566f8c4-2c32-419a-bfe3-7491488edfed"
    }
  },
  {
    "bloco": "04_usage_persistido_na_transacao",
    "status": "PASS",
    "detalhe": [
      {
        "phase": "primeira_mensagem",
        "status": "copied",
        "channel": "whatsapp",
        "lead_id": "701b657a-ee8e-4cbd-91f3-497e69abce9c",
        "metadata": {
          "origem": "teste_16b_pme_usage_tracking",
          "fixture_transacional": true,
          "frontend_sem_autoridade_soberana": true
        },
        "usage_id": "eeacc442-c05a-4af9-8355-5abdb0ee88ac",
        "lead_type": "lista_fria",
        "empresa_id": "[REDACTED_EMPRESA_ID]",
        "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
        "template_id": "3236427d-a7d7-4fd4-be85-0525fd521d0f",
        "feedback_key": "teste_16b_positive",
        "selection_mode": "suggested",
        "created_at_presente": true
      }
    ]
  },
  {
    "bloco": "05_cardinalidade_usage_fixture",
    "status": "PASS",
    "detalhe": {
      "lead_id": "701b657a-ee8e-4cbd-91f3-497e69abce9c",
      "template_id": "3236427d-a7d7-4fd4-be85-0525fd521d0f",
      "usage_count_fixture": 1
    }
  },
  {
    "bloco": "99_rollback_notice",
    "status": "INFO",
    "detalhe": {
      "ddl": false,
      "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
      "teste": "16B",
      "mensagem": "Teste 16B encerra com ROLLBACK. Lead, template e uso PME não devem permanecer no banco.",
      "rollback": true,
      "validacao": "RPC positiva pme_registrar_message_usage com append-only transacional",
      "dml_fixture": true
    }
  }
]
```

---

## Conclusão

O **16B está aprovado**.

A RPC `public.pme_registrar_message_usage(uuid,jsonb)` passou no fluxo positivo e demonstrou:

- execução autenticada;
- escopo por empresa correto;
- derivação de `empresa_id` e `corretor_id` no backend;
- escrita append-only em `pme_message_usage`;
- retorno operacional consistente;
- rollback seguro.

---

## Próximo passo

Criar e executar o **16C — segurança negativa da RPC PME**, validando:

1. bloqueio sem autenticação;
2. bloqueio de `empresa_id`, `tenant_id`, `corretor_id`, `user_id` vindos do frontend;
3. bloqueio de payload não objeto;
4. bloqueio de referência ausente;
5. bloqueio de canal inválido;
6. bloqueio de `lead_type` inválido;
7. bloqueio de `status` inválido;
8. ausência de mutação indevida em `pme_message_usage`.
