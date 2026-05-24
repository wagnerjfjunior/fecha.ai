# FECH.AI — PME Usage Tracking v0.2.8

## Evidência 16C — Segurança negativa da RPC `pme_registrar_message_usage` com rollback

**Branch:** `feature/pme-usage-tracking-db-v0.2.8`  
**Teste:** `16C`  
**Arquivo executado:** `supabase/tests/pme/usage-tracking/16c_rpc_registrar_message_usage_security_negative_rollback.sql`  
**Tipo:** fixture transacional com `ROLLBACK`  
**DDL persistente:** não  
**DML:** sim, apenas fixture transacional  
**Persistência esperada:** nenhuma, por rollback  
**Status final:** `PASS`

---

## Objetivo

Validar os bloqueios negativos e de segurança da RPC:

```sql
public.pme_registrar_message_usage(uuid, jsonb)
```

Garantias avaliadas:

1. bloqueio sem autenticação;
2. bloqueio de autoridade soberana enviada pelo frontend;
3. bloqueio de payload `jsonb` que não seja objeto;
4. bloqueio de uso sem referência (`template_id`, `call_script_id` ou `cadence_step_id`);
5. bloqueio de canal inválido;
6. bloqueio de `lead_type` inválido;
7. bloqueio de `status` inválido;
8. garantia de ausência de mutação indevida em `public.pme_message_usage`.

---

## Resultado objetivo

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_setup_fixture_negativa` | PASS | Fixture mínima criada com usuário, empresa, corretor, lead e template. |
| `01_bloqueio_sem_auth` | PASS | RPC bloqueou chamada sem autenticação com `auth_required / 28000`. |
| `02_bloqueio_parametros_soberanos_frontend` | PASS | RPC bloqueou todos os campos soberanos enviados pelo frontend. |
| `03_bloqueio_payload_nao_objeto` | PASS | RPC bloqueou payload array com `p_payload_must_be_object / 22023`. |
| `04_bloqueio_referencia_ausente` | PASS | RPC bloqueou uso sem referência com `usage_reference_required / 22023`. |
| `05_bloqueio_channel_invalido` | PASS | RPC bloqueou canal inválido com `invalid_channel / 22023`. |
| `06_bloqueio_lead_type_invalido` | PASS | RPC bloqueou tipo de lead inválido com `invalid_lead_type / 22023`. |
| `07_bloqueio_status_invalido` | PASS | RPC bloqueou status inválido com `invalid_status / 22023`. |
| `08_sem_mutacao_usage_tentativas_negativas` | PASS | Nenhuma tentativa negativa gerou linha em `pme_message_usage`. |
| `99_rollback_notice` | INFO | Fixture encerrada com rollback. |

---

## Fixture utilizada

```json
{
  "lead_id": "598039ea-7e40-441d-a09c-58740a524675",
  "user_id": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
  "template_id": "d1d71ea0-ce85-4f6d-9d5c-315cfbcc1301",
  "usage_count_before": 0
}
```

---

## Bloqueios validados

### 1. Sem autenticação

```json
{
  "message": "auth_required",
  "sqlstate": "28000"
}
```

### 2. Autoridade soberana enviada pelo frontend

Todos os campos abaixo foram bloqueados com `frontend_authority_forbidden / 42501`:

```text
empresa_id
tenant_id
corretor_id
user_id
created_by
updated_by
```

Resultado consolidado:

```json
{
  "pass_count": 6,
  "fail_count": 0
}
```

### 3. Payload não objeto

```json
{
  "message": "p_payload_must_be_object",
  "sqlstate": "22023"
}
```

### 4. Referência ausente

```json
{
  "message": "usage_reference_required",
  "sqlstate": "22023"
}
```

### 5. Canal inválido

```json
{
  "message": "invalid_channel",
  "sqlstate": "22023"
}
```

### 6. Tipo de lead inválido

```json
{
  "message": "invalid_lead_type",
  "sqlstate": "22023"
}
```

### 7. Status inválido

```json
{
  "message": "invalid_status",
  "sqlstate": "22023"
}
```

---

## Ausência de mutação indevida

O teste confirmou que nenhuma tentativa negativa criou registro em `public.pme_message_usage`:

```json
{
  "lead_id": "598039ea-7e40-441d-a09c-58740a524675",
  "usage_count_before": 0,
  "usage_count_after": 0
}
```

---

## Saída executada

```json
[
  {
    "bloco": "00_setup_fixture_negativa",
    "status": "PASS",
    "detalhe": {
      "lead_id": "598039ea-7e40-441d-a09c-58740a524675",
      "user_id": "0d7c3db5-aa5e-4980-87ef-c577b039a3bd",
      "empresa_id": "[REDACTED_EMPRESA_ID]",
      "corretor_id": "e566f8c4-2c32-419a-bfe3-7491488edfed",
      "template_id": "d1d71ea0-ce85-4f6d-9d5c-315cfbcc1301",
      "usage_count_before": 0
    }
  },
  {
    "bloco": "01_bloqueio_sem_auth",
    "status": "PASS",
    "detalhe": {
      "message": "auth_required",
      "sqlstate": "28000"
    }
  },
  {
    "bloco": "02_bloqueio_parametros_soberanos_frontend",
    "status": "PASS",
    "detalhe": {
      "detalhes": [
        {
          "key": "empresa_id",
          "status": "PASS",
          "message": "frontend_authority_forbidden",
          "sqlstate": "42501"
        },
        {
          "key": "tenant_id",
          "status": "PASS",
          "message": "frontend_authority_forbidden",
          "sqlstate": "42501"
        },
        {
          "key": "corretor_id",
          "status": "PASS",
          "message": "frontend_authority_forbidden",
          "sqlstate": "42501"
        },
        {
          "key": "user_id",
          "status": "PASS",
          "message": "frontend_authority_forbidden",
          "sqlstate": "42501"
        },
        {
          "key": "created_by",
          "status": "PASS",
          "message": "frontend_authority_forbidden",
          "sqlstate": "42501"
        },
        {
          "key": "updated_by",
          "status": "PASS",
          "message": "frontend_authority_forbidden",
          "sqlstate": "42501"
        }
      ],
      "fail_count": 0,
      "pass_count": 6
    }
  },
  {
    "bloco": "03_bloqueio_payload_nao_objeto",
    "status": "PASS",
    "detalhe": {
      "message": "p_payload_must_be_object",
      "sqlstate": "22023"
    }
  },
  {
    "bloco": "04_bloqueio_referencia_ausente",
    "status": "PASS",
    "detalhe": {
      "message": "usage_reference_required",
      "sqlstate": "22023"
    }
  },
  {
    "bloco": "05_bloqueio_channel_invalido",
    "status": "PASS",
    "detalhe": {
      "message": "invalid_channel",
      "sqlstate": "22023"
    }
  },
  {
    "bloco": "06_bloqueio_lead_type_invalido",
    "status": "PASS",
    "detalhe": {
      "message": "invalid_lead_type",
      "sqlstate": "22023"
    }
  },
  {
    "bloco": "07_bloqueio_status_invalido",
    "status": "PASS",
    "detalhe": {
      "message": "invalid_status",
      "sqlstate": "22023"
    }
  },
  {
    "bloco": "08_sem_mutacao_usage_tentativas_negativas",
    "status": "PASS",
    "detalhe": {
      "lead_id": "598039ea-7e40-441d-a09c-58740a524675",
      "usage_count_after": 0,
      "usage_count_before": 0
    }
  },
  {
    "bloco": "99_rollback_notice",
    "status": "INFO",
    "detalhe": {
      "fase": "v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC",
      "teste": "16C",
      "mensagem": "Teste 16C encerra com ROLLBACK. Fixture e tentativas negativas não devem permanecer no banco.",
      "rollback": true,
      "validacao": "seguranca negativa da RPC pme_registrar_message_usage",
      "dml_fixture": true,
      "ddl_persistente": false
    }
  }
]
```

---

## Conclusão

O **16C está aprovado**.

A RPC `public.pme_registrar_message_usage(uuid,jsonb)` demonstrou comportamento seguro para os cenários negativos testados:

- não executa sem autenticação;
- não aceita soberania frontend para campos críticos;
- valida formato do payload;
- exige referência de uso;
- valida enums operacionais;
- não gera mutação indevida em `pme_message_usage`.

---

## Próximo passo

Criar e executar o **16D — Escopo/RLS/cross-tenant do PME Usage Tracking**, validando:

1. usuário/corretor da mesma empresa acessa o que deve acessar;
2. usuário de outra empresa é bloqueado;
3. referência PME de outra empresa é bloqueada;
4. RLS não expõe dados cross-tenant;
5. RPC mantém `empresa_id` derivado do lead;
6. tentativas cross-tenant não geram mutação indevida.
