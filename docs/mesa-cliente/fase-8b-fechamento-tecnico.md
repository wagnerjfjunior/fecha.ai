# FECH.AI — MesaCliente
# Fase 8B — Fechamento Técnico do Adapter Front/BFF de Operações Financeiras

## 1. Identificação

**Projeto:** `FECH.AI / MesaCliente`  
**Fase:** `8B — Adapter Front/BFF para Operações Financeiras`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Repositório:** `wagnerjfjunior/fecha.ai`  
**Status:** `VALIDADA — 17B PASS EM CI / PRONTA PARA CONTRATO 8C`  
**Data de fechamento:** `2026-05-25`

---

## 2. Objetivo da Fase 8B

A Fase 8B teve como objetivo criar a camada de integração Front/BFF para consumir, no frontend do MesaCliente, as RPCs financeiras já existentes das fases anteriores, sem alterar o motor financeiro, parser, Worker, Make, n8n, migrations ou regras centrais.

A fase entregou:

1. Adapter de operações financeiras.
2. Hooks React Query expostos ao frontend.
3. Sanitização de payload de aplicação financeira.
4. Bloqueio de campos soberanos vindos do frontend.
5. Invalidação de cache após aplicação financeira.
6. Validação estática automatizada pelo teste `17B`.

---

## 3. Arquivos principais da Fase 8B

### 3.1 Adapter criado

`src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js`

Funções previstas/validadas:

- `sanitizeParametrosAplicacaoFinanceira`
- `normalizeFiltrosOperacoesFinanceiras`
- `mapMesaClienteOperacaoFinanceiraError`
- `canAplicarOperacaoFinanceira`
- `listarOperacoesFinanceirasAdmin`
- `obterOperacaoFinanceiraAdmin`
- `resumirOperacaoFinanceiraAdmin`
- `obterResumoOperacaoClienteSafe`
- `aplicarOperacaoFinanceiraAdmin`

### 3.2 Hooks alterados/expostos

`src/components/MesaCliente/hooks/useMesaData.js`

Hooks previstos/validados:

- `useOperacoesFinanceirasAdmin`
- `useOperacaoFinanceiraAdmin`
- `useResumoOperacaoFinanceiraAdmin`
- `useResumoOperacaoClienteSafe`
- `useAplicarOperacaoFinanceiraAdmin`

### 3.3 Teste automatizado criado

`scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs`

### 3.4 Workflow criado

`.github/workflows/mesa-cliente-17b.yml`

---

## 4. RPCs integradas pelo adapter

### 4.1 Fase 5D — leitura administrativa

- `public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)`
- `public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)`

### 4.2 Fase 6 — resumos read-only

- `public.mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)`
- `public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)`

### 4.3 Fase 7 — aplicação administrativa

- `public.mesa_cliente_aplicar_operacao_financeira_admin(uuid, jsonb)`

---

## 5. Garantias preservadas

A Fase 8B preservou as seguintes garantias arquiteturais:

| Garantia | Resultado |
|---|---|
| Sem DDL | `PASS` |
| Sem DML direto pelo frontend | `PASS` |
| Banco não alterado | `PASS` |
| Motor financeiro preservado | `PASS` |
| Parser preservado | `PASS` |
| Worker/Make/n8n preservados | `PASS` |
| Sem migrations alteradas | `PASS` |
| Sem payload soberano vindo do frontend | `PASS` |
| Sem chave administrativa privilegiada no frontend | `PASS` |
| Sem nova anon key/JWT hardcoded introduzida pela Fase 8B | `PASS` |

---

## 6. Campos soberanos bloqueados pelo adapter

O adapter bloqueia/removerá campos que não podem ser aceitos como autoridade do frontend, incluindo, entre outros:

- `empresa_id`
- `tenant_id`
- `simulacao_id`
- `agenda_id`
- `empreendimento_id`
- `politica_id`
- `corretor_id`
- `user_id`
- `auth_uid`
- `role`
- `perfil`
- `is_admin`
- `is_gestor`
- `is_admin_local`
- `tipo_operacao`
- `valor_base`
- `valor_movido`
- `taxa_ano_pct`
- `vpl_aplicado_pct`
- `desconto_calculado`
- `acrescimo_calculado`
- `economia_liquida`
- `premio_corretor_pct`
- `status_premio`
- `status_operacao`
- `confirmado`
- `visivel_cliente`
- `checksum_operacao`
- `metadata`
- `created_at`
- `updated_at`
- `criado_por`

Autoridade final permanece no banco/RPC, com validação por `auth.uid()`, tenant, empresa e perfil.

---

## 7. Histórico de correções até fechamento

### 7.1 Remoção de backup residual

Foi identificado que artifacts antigos ainda acusavam `src/Appx.jsx`. A validação posterior confirmou que o arquivo já havia sido removido na branch e aparecia apenas como arquivo removido no diff.

Commits relacionados:

- `8473d5a` — neutralização inicial do backup legado residual.
- `438178f` — remoção do backup residual `Appx`.

### 7.2 Saneamento de constantes no App principal

Foi removido fallback hardcoded de configuração Supabase no `src/App.jsx`, mantendo uso por variáveis de ambiente.

Commit relacionado:

- `25c1c59` — remoção de chaves em constantes do App.

### 7.3 Ajuste de gatilho do workflow 17B

O workflow 17B passou a observar explicitamente alterações em:

- `src/App.jsx`
- `src/Appx.jsx`

Commit relacionado:

- `758c39e` — inclusão do App principal no gatilho 17B.

### 7.4 Atualização do runtime do workflow

O workflow foi atualizado de Node 20 para Node 24, eliminando warning de depreciação sem alterar o motor do MesaCliente.

Commit relacionado:

- `c033f24` — atualização do workflow 17B para Node 24.

### 7.5 Correção final do bloco 05

O artifact `17b_resultado 5.json` ainda falhava no bloco `05_sem_service_role_front`, apontando um match em `src/App.jsx`.

A causa era um comentário na linha aproximada `4606`, sem impacto de lógica, contendo termo bloqueado pelo regex do teste.

Correção aplicada:

```diff
- // Usa a mesma Edge Function de criação que tem service_role
+ // Usa a mesma Edge Function de criação administrativa
```

Commit de correção:

- `0e7f7461ad4eea48353f8a5dbe92cc1974649be5` — `fix(mesa-cliente): remover referência service role do App principal`

Escopo do commit:

- Apenas `src/App.jsx`.
- Apenas 1 linha alterada.
- Sem alteração funcional.
- Sem alteração de banco/RPC/motor financeiro.

---

## 8. Evidência local em Codespace

Antes do commit final, foi executado no Codespace:

```bash
grep -nEi "service[_-]?role|serviceRole|SUPABASE_SERVICE_ROLE" src/App.jsx
```

Resultado:

```text
sem retorno
```

Também foi executado:

```bash
grep -RInEi "service[_-]?role|serviceRole|SUPABASE_SERVICE_ROLE" src
```

Resultado:

```text
sem retorno
```

Execução local do teste:

```bash
node scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs
```

Resultado local:

- Todos os blocos `PASS`.
- `05_sem_service_role_front = PASS`.
- `99_readiness_8c = PASS`.
- `fail_count = 0`.

Validação adicional:

```bash
node scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs | grep '"status": "FAIL"'
```

Resultado:

```text
sem retorno
```

---

## 9. Evidência oficial do artifact 17B

Artifact validado:

`17b_resultado 6.json`

Resultado:

| Bloco | Status |
|---|---|
| `00_arquivos_fase_8b` | `PASS` |
| `01_rpc_names_contrato` | `PASS` |
| `02_hooks_expostos` | `PASS` |
| `03_bloqueio_authority_frontend` | `PASS` |
| `04_payload_aplicacao_sanitizado` | `PASS` |
| `05_sem_service_role_front` | `PASS` |
| `06_sem_anon_key_nova_fase_8b` | `PASS` |
| `07_status_aplicada_compat_5d` | `PASS` |
| `08_cache_invalidation_aplicacao` | `PASS` |
| `09_motor_preservado` | `PASS` |
| `10_documentacao_8b_alinhada` | `PASS` |
| `99_readiness_8c` | `PASS` |

Bloco crítico de segurança:

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

Bloco de preservação do motor:

```json
{
  "bloco": "09_motor_preservado",
  "status": "PASS",
  "detalhe": {
    "forbidden_engine_files": []
  }
}
```

Bloco final de readiness:

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

## 10. Interpretação técnica do resultado

O `17B PASS` prova estaticamente que:

1. O adapter financeiro existe.
2. Os hooks financeiros existem e estão expostos.
3. Os nomes das RPCs previstas estão presentes.
4. O payload de aplicação financeira passa por sanitização.
5. Chaves soberanas vindas do frontend são bloqueadas.
6. O frontend não contém referência proibida à chave administrativa privilegiada.
7. A Fase 8B não introduziu nova anon key/JWT hardcoded nos arquivos do adapter/hook.
8. A compatibilidade com status `aplicada` foi tratada sem quebrar a RPC 5D legada.
9. A mutation de aplicação invalida os caches esperados.
10. O motor financeiro foi preservado.
11. A documentação mínima está alinhada.
12. A Fase 8C pode ser iniciada do ponto de vista do gate estático 17B.

---

## 11. Limites da validação 17B

O teste 17B é estático. Ele não comprova:

1. Build final de produção.
2. Renderização visual da UI 8C.
3. Smoke funcional autenticado.
4. Execução real das RPCs em sessão autenticada.
5. Aplicação financeira real em ambiente controlado.
6. Ausência de regressão visual.

Esses itens devem ser cobertos nas próximas fases/checklists.

---

## 12. Pendências antes de merge final/produção

Antes de considerar a frente completa pronta para produção, ainda devem ser executados/documentados:

1. Build/lint do frontend, se aplicável.
2. Contrato técnico da Fase 8C.
3. Implementação visual da `OperacoesFinanceirasPanel.jsx`.
4. Smoke funcional autenticado.
5. Teste de leitura admin via UI.
6. Teste de resumo cliente-safe via UI.
7. Teste de gating visual de aplicação.
8. Teste controlado de aplicação financeira, quando expressamente autorizado.
9. Checklist pós-merge.

---

## 13. Decisão de fechamento

Com base no artifact `17b_resultado 6.json` e na correção final commitada em `0e7f7461ad4eea48353f8a5dbe92cc1974649be5`, a Fase 8B está tecnicamente validada pelo teste 17B.

**Decisão:** `APROVADA PARA AVANÇAR AO CONTRATO DA FASE 8C`.

A próxima fase recomendada é:

```text
8C — OperacoesFinanceirasPanel.jsx
```

Regra de continuidade:

Antes de código da 8C, criar contrato técnico específico definindo escopo visual, permissões, estados de UI, riscos, limites, critérios de aceite e smoke funcional.
