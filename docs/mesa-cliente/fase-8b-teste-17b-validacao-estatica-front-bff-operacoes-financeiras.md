# FECH.AI — MesaCliente
# Teste 17B — Validação Estática Front/BFF de Operações Financeiras

## 1. Identificação

**Teste:** `17B — Validação Estática Front/BFF`  
**Fase:** `8B — Adapter Front/BFF para Operações Financeiras`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Arquivo do teste:** `scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs`  
**Status:** `VALIDADO — PASS LOCAL E ARTIFACT 17B PASS`  
**Artifact final validado:** `17b_resultado 6.json`  
**Commit de correção final:** `0e7f7461ad4eea48353f8a5dbe92cc1974649be5`

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

| Bloco | Validação | Resultado final |
|---|---|---|
| `00_arquivos_fase_8b` | Confirma existência do adapter, hooks e documentação 8B. | `PASS` |
| `01_rpc_names_contrato` | Confirma nomes das RPCs financeiras esperadas. | `PASS` |
| `02_hooks_expostos` | Confirma hooks financeiros expostos no `useMesaData.js`. | `PASS` |
| `03_bloqueio_authority_frontend` | Confirma lista de campos soberanos bloqueados no adapter. | `PASS` |
| `04_payload_aplicacao_sanitizado` | Confirma que aplicação usa sanitizer e não payload cru. | `PASS` |
| `05_sem_service_role_front` | Varre `src` para bloquear referência administrativa privilegiada no frontend. | `PASS` |
| `06_sem_anon_key_nova_fase_8b` | Confirma que a Fase 8B não introduziu nova anon key/JWT hardcoded. | `PASS` |
| `07_status_aplicada_compat_5d` | Confirma compatibilidade do status `aplicada` com RPC 5D legada. | `PASS` |
| `08_cache_invalidation_aplicacao` | Confirma invalidação de caches após aplicação financeira. | `PASS` |
| `09_motor_preservado` | Confirma que não houve alteração em migrations/tests/worker/make/n8n. | `PASS` |
| `10_documentacao_8b_alinhada` | Confirma documentação mínima da Fase 8B. | `PASS` |
| `99_readiness_8c` | Libera ou bloqueia a Fase 8C. | `PASS` |

---

## 5. Critério de aprovação

```text
fail_count = 0
99_readiness_8c = PASS
```

Critério atendido no artifact final `17b_resultado 6.json`.

---

## 6. Observação sobre anon key

O teste 17B valida que a Fase 8B não introduziu nova `anon_key` ou JWT hardcoded nos arquivos do adapter/hook.

Ele não corrige achado legado de `src/lib/supabaseClient.js`, porque isso foi classificado no preflight 8A como hardening separado. A correção recomendada continua sendo migrar configuração Supabase para variáveis de ambiente Vite em uma fase própria ou subtarefa controlada.

---

## 7. Histórico de validação

### 7.1 Falha anterior em artifact antigo

Artifacts anteriores acusavam falha relacionada a `src/Appx.jsx`. A validação posterior confirmou que o arquivo já havia sido removido na branch e aparecia apenas como arquivo removido no diff.

### 7.2 Falha real antes do fechamento

O artifact `17b_resultado 5.json` apresentou uma falha real no bloco `05_sem_service_role_front`, com match em `src/App.jsx`.

A causa era um comentário contendo termo bloqueado pelo regex do teste, sem impacto funcional.

Correção aplicada no commit:

`0e7f7461ad4eea48353f8a5dbe92cc1974649be5`

Diff lógico:

```diff
- // Usa a mesma Edge Function de criação que tem service_role
+ // Usa a mesma Edge Function de criação administrativa
```

### 7.3 Evidência local

Após a correção, foram executados:

```bash
grep -nEi "service[_-]?role|serviceRole|SUPABASE_SERVICE_ROLE" src/App.jsx
```

```bash
grep -RInEi "service[_-]?role|serviceRole|SUPABASE_SERVICE_ROLE" src
```

Ambos sem retorno.

Também foi executado:

```bash
node scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs | grep '"status": "FAIL"'
```

Resultado: sem retorno.

---

## 8. Resultado final aprovado

Artifact final validado:

`17b_resultado 6.json`

Bloco crítico:

```json
{
  "bloco": "05_sem_service_role_front",
  "status": "PASS",
  "detalhe": {
    "arquivos_varridos": 65,
    "matches": []
  }
}
```

Preservação de motor:

```json
{
  "bloco": "09_motor_preservado",
  "status": "PASS",
  "detalhe": {
    "forbidden_engine_files": []
  }
}
```

Readiness final:

```json
{
  "bloco": "99_readiness_8c",
  "status": "PASS",
  "detalhe": {
    "fail_count": 0,
    "ddl": false,
    "dml": false,
    "banco_alterado": false,
    "motor_financeiro_preservado": true
  }
}
```

---

## 9. Resultado esperado aprovado

O resultado aprovado é:

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

## 10. Próximo passo após execução aprovada

Com `17B PASS`, seguir para:

```text
8C — OperacoesFinanceirasPanel.jsx
```

Objetivo da 8C: renderizar no frontend as operações de antecipação/amortização, resumo administrativo, prévia cliente-safe e ação de aplicar operação com confirmação.

Antes de implementar código da 8C, deve ser criado o contrato técnico da fase, com escopo visual, permissões, estados de UI, limites, riscos e critérios de aceite.
