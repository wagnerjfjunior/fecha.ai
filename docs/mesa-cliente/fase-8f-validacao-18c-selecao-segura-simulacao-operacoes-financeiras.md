# FECH.AI — MesaCliente
# Fase 8F — Validação 18C de Seleção Segura de Simulação para Operações Financeiras

## 1. Identificação

**Projeto:** `FECH.AI / MesaCliente`  
**Fase:** `8F — Seleção segura de simulação para Operações Financeiras`  
**Teste:** `18C — Validação Estática de Seleção Segura de Simulação para Operações`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Artifact validado:** `18c_resultado.json`  
**Status:** `VALIDADO — 18C PASS / SELEÇÃO SEGURA APROVADA`

---

## 2. Objetivo do 18C

Validar estaticamente que a aba `Operações` pode ser aberta a partir de uma proposta/simulação real do `Histórico`, usando exclusivamente `item.id` como origem do `simulacaoId` enviado ao `OperacoesFinanceirasPanel`.

O teste também valida que não houve derivação soberana de `simulacaoId` por empresa, corretor, empreendimento, unidade, localStorage ou sessionStorage.

O teste não acessa banco, não executa RPC, não faz DDL e não faz DML.

---

## 3. Arquivos envolvidos

Arquivos de UI validados:

```text
src/components/MesaCliente/index.jsx
src/components/MesaCliente/TabHistorico.jsx
src/components/MesaCliente/OperacoesFinanceirasPanel.jsx
```

Contrato da fase:

```text
docs/mesa-cliente/fase-8f-contrato-selecao-segura-simulacao-operacoes-financeiras.md
```

Teste estático:

```text
scripts/tests/mesa-cliente/18c_validacao_selecao_segura_simulacao_operacoes_financeiras.mjs
```

Workflow:

```text
.github/workflows/mesa-cliente-18c.yml
```

---

## 4. Resultado final do artifact

O artifact `18c_resultado.json` retornou todos os blocos como `PASS`.

| Bloco | Resultado |
|---|---|
| `00_arquivos_base_18c` | `PASS` |
| `01_contrato_8f` | `PASS` |
| `02_historico_callback_operacoes` | `PASS` |
| `03_histcard_recebe_callback` | `PASS` |
| `04_botao_operacoes_financeiras` | `PASS` |
| `05_botao_exige_item_id` | `PASS` |
| `06_callback_chamado_com_item` | `PASS` |
| `07_callback_repassado_para_cards` | `PASS` |
| `08_index_estado_selecao_simulacao` | `PASS` |
| `09_index_builder_valida_item_id` | `PASS` |
| `10_contexto_visual_minimo` | `PASS` |
| `11_handler_abre_aba_ops_com_item_id` | `PASS` |
| `12_index_repassa_handler_ao_historico` | `PASS` |
| `13_panel_recebe_simulacao_selecionada` | `PASS` |
| `14_fallback_bloqueado_sem_selecao_preservado` | `PASS` |
| `15_sem_derivacao_soberana_simulacao_id` | `PASS` |
| `16_motor_preservado` | `PASS` |
| `99_readiness_18c_selecao_segura` | `PASS` |

Critério final:

```text
fail_count = 0
99_readiness_18c_selecao_segura = PASS
```

---

## 5. Evidências críticas

### 5.1 Histórico recebe callback de operações

O bloco `02_historico_callback_operacoes` retornou `PASS`, confirmando que `TabHistorico` recebe `onAbrirOperacoesFinanceiras`.

### 5.2 HistCard recebe callback

O bloco `03_histcard_recebe_callback` retornou `PASS`, confirmando que `HistCard` recebe o callback.

### 5.3 Botão de operações financeiras existe

O bloco `04_botao_operacoes_financeiras` retornou `PASS`, confirmando a existência do botão:

```text
Operações financeiras
```

### 5.4 Botão exige `item.id`

O bloco `05_botao_exige_item_id` retornou `PASS`, confirmando validação por:

```text
item?.id && onAbrirOperacoesFinanceiras
```

### 5.5 Callback chamado com item

O bloco `06_callback_chamado_com_item` retornou `PASS`, confirmando:

```text
onAbrirOperacoesFinanceiras(item)
```

### 5.6 Estado local de seleção

O bloco `08_index_estado_selecao_simulacao` retornou `PASS`, confirmando o estado:

```text
simulacaoOperacoesSelecionada
setSimulacaoOperacoesSelecionada
```

### 5.7 Builder valida item.id

O bloco `09_index_builder_valida_item_id` retornou `PASS`, confirmando validação defensiva:

```text
if (!item?.id) return null;
```

### 5.8 Contexto visual mínimo

O bloco `10_contexto_visual_minimo` retornou `PASS`, com `missing_tokens = []`.

Contexto visual permitido:

- `id: item.id`
- `cliente_nome`
- `empreendimento`
- `unidade`
- `status`
- `valor_total`

### 5.9 Painel recebe simulação selecionada

O bloco `13_panel_recebe_simulacao_selecionada` retornou `PASS`, confirmando:

```text
simulacaoId={simulacaoOperacoesSelecionada?.id || null}
```

### 5.10 Fallback sem seleção preservado

O bloco `14_fallback_bloqueado_sem_selecao_preservado` retornou `PASS`, preservando o comportamento seguro quando a aba `Operações` é aberta sem simulação selecionada.

### 5.11 Sem derivação soberana de simulacaoId

O bloco `15_sem_derivacao_soberana_simulacao_id` retornou:

```text
matches = []
```

Isso confirma ausência de derivação indevida de `simulacaoId` por:

- `ctx.empresaId`
- `ctx.corretorId`
- `empresaId`
- `empSelecionado`
- `localStorage`
- `sessionStorage`

---

## 6. Preservação de motor

O bloco `16_motor_preservado` retornou:

```text
status = PASS
diff_range = origin/main...HEAD
diff_warning = null
forbidden_engine_files = []
ddl = false
dml = false
banco_alterado = false
```

Portanto, não houve alteração proibida em motor financeiro, migrations, Supabase tests, Worker, Make, n8n ou parser.

---

## 7. Limites da validação 18C

O `18C PASS` comprova seleção segura e transporte visual de `item.id`, mas ainda não comprova:

1. Build final após as alterações em `index.jsx` e `TabHistorico.jsx`.
2. Smoke visual manual com clique real no botão `Operações financeiras`.
3. Existência de operações financeiras para a simulação selecionada.
4. Listagem real via RPC no painel.
5. Detalhe/resumo real por operação.
6. Prévia cliente-safe real por operação.
7. Aplicação real de operação financeira em ambiente controlado.

Esses itens devem ser tratados nos próximos gates.

---

## 8. Decisão

Com base no artifact `18c_resultado.json`, a seleção segura de simulação para operações financeiras está aprovada.

**Decisão:** `18C PASS — liberar build pós-seleção segura`.

Próximo passo recomendado:

```text
18D — Build pós-seleção segura de simulação
```

Depois do build, a próxima validação deve ser um smoke visual manual/controlado abrindo o painel a partir de um item real do histórico.
