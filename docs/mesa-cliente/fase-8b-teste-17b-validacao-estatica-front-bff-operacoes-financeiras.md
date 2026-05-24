# FECH.AI — MesaCliente
# Teste 17B — Validação Estática Front/BFF de Operações Financeiras

## 1. Identificação

**Teste:** `17B — Validação Estática Front/BFF`  
**Fase:** `8B — Adapter Front/BFF para Operações Financeiras`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Arquivo do teste:** `scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs`  
**Status:** `CRIADO — AGUARDANDO EXECUÇÃO LOCAL/CI`

---

## 2. Objetivo

Validar estaticamente a integração Front/BFF criada na Fase 8B antes de plugar o painel visual da Fase 8C.

O teste não acessa banco, não executa RPC, não faz DDL e não faz DML. Ele apenas inspeciona arquivos do repositório.

---

## 3. Como executar

Na raiz do repositório:

```bash
node scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs
```

Saída esperada: JSON com blocos `PASS` e `INFO`, sem bloco `FAIL`.

---

## 4. Blocos validados

| Bloco | Validação |
|---|---|
| `00_arquivos_fase_8b` | Confirma existência do adapter, hooks e documentação 8B. |
| `01_rpc_names_contrato` | Confirma nomes das RPCs financeiras esperadas. |
| `02_hooks_expostos` | Confirma hooks financeiros expostos no `useMesaData.js`. |
| `03_bloqueio_authority_frontend` | Confirma lista de campos soberanos bloqueados no adapter. |
| `04_payload_aplicacao_sanitizado` | Confirma que aplicação usa sanitizer e não payload cru. |
| `05_sem_service_role_front` | Varre `src` para bloquear Service Role no frontend. |
| `06_sem_anon_key_nova_fase_8b` | Confirma que a Fase 8B não introduziu nova anon key/JWT hardcoded. |
| `07_status_aplicada_compat_5d` | Confirma compatibilidade do status `aplicada` com RPC 5D legada. |
| `08_cache_invalidation_aplicacao` | Confirma invalidação de caches após aplicação financeira. |
| `09_motor_preservado` | Confirma que não houve alteração em migrations/tests/worker/make/n8n. |
| `10_documentacao_8b_alinhada` | Confirma documentação mínima da Fase 8B. |
| `99_readiness_8c` | Libera ou bloqueia a Fase 8C. |

---

## 5. Critério de aprovação

```text
fail_count = 0
99_readiness_8c = PASS
```

Se houver qualquer `FAIL`, a Fase 8C não deve iniciar.

---

## 6. Observação sobre anon key

O teste 17B valida que a Fase 8B não introduziu nova `anon_key` ou JWT hardcoded nos arquivos do adapter/hook.

Ele não corrige achado legado de `src/lib/supabaseClient.js`, porque isso foi classificado no preflight 8A como hardening separado. A correção recomendada continua sendo migrar configuração Supabase para variáveis de ambiente Vite em uma fase própria ou subtarefa controlada.

---

## 7. Resultado esperado

Exemplo de resultado aprovado:

```json
[
  { "bloco": "00_arquivos_fase_8b", "status": "PASS" },
  { "bloco": "01_rpc_names_contrato", "status": "PASS" },
  { "bloco": "02_hooks_expostos", "status": "PASS" },
  { "bloco": "03_bloqueio_authority_frontend", "status": "PASS" },
  { "bloco": "04_payload_aplicacao_sanitizado", "status": "PASS" },
  { "bloco": "05_sem_service_role_front", "status": "PASS" },
  { "bloco": "06_sem_anon_key_nova_fase_8b", "status": "PASS" },
  { "bloco": "07_status_aplicada_compat_5d", "status": "PASS" },
  { "bloco": "08_cache_invalidation_aplicacao", "status": "PASS" },
  { "bloco": "09_motor_preservado", "status": "PASS" },
  { "bloco": "10_documentacao_8b_alinhada", "status": "PASS" },
  { "bloco": "99_readiness_8c", "status": "PASS" }
]
```

---

## 8. Próximo passo após execução aprovada

Com `17B PASS`, seguir para:

```text
8C — OperacoesFinanceirasPanel.jsx
```

Objetivo da 8C: renderizar no frontend as operações de antecipação/amortização, resumo administrativo, prévia cliente-safe e ação de aplicar operação com confirmação.
