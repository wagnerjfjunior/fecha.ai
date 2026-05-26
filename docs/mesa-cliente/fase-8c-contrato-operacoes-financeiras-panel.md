# FECH.AI — MesaCliente
# Fase 8C — Contrato Técnico do OperacoesFinanceirasPanel

## 1. Identificação

**Projeto:** `FECH.AI / MesaCliente`  
**Fase:** `8C — OperacoesFinanceirasPanel.jsx`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Status:** `CONTRATO CRIADO — AGUARDANDO APROVAÇÃO ANTES DE CÓDIGO`  
**Fase anterior:** `8B — Adapter Front/BFF para Operações Financeiras`  
**Gate anterior:** `17B PASS — artifact final 17b_resultado 6.json`

---

## 2. Objetivo da Fase 8C

Criar o painel visual administrativo de operações financeiras do MesaCliente, consumindo exclusivamente o adapter e os hooks aprovados na Fase 8B.

A Fase 8C deve transformar a camada técnica já validada em uma experiência operacional segura para o usuário autorizado visualizar, analisar e, quando permitido, acionar a aplicação de uma operação financeira confirmada.

---

## 3. Regra-mãe da fase

```text
UI renderiza e solicita.
Hooks/adapter orquestram chamadas.
RPC valida, decide, calcula, aplica e audita.
```

A UI da Fase 8C não pode assumir autoridade sobre tenant, empresa, perfil, status financeiro, cálculo, valor, permissão, visibilidade cliente ou regra de aplicação.

---

## 4. Escopo permitido

A Fase 8C pode criar ou alterar somente componentes visuais e integração de tela necessários para exibir operações financeiras já disponíveis pelos hooks da Fase 8B.

### 4.1 Dentro do escopo

1. Criar componente visual `OperacoesFinanceirasPanel.jsx`.
2. Criar subcomponentes visuais auxiliares se necessário.
3. Exibir listagem administrativa de operações financeiras.
4. Exibir detalhe administrativo de uma operação selecionada.
5. Exibir resumo administrativo.
6. Exibir prévia cliente-safe sem campos internos.
7. Exibir estados de loading, vazio, erro, bloqueado e sem permissão.
8. Exibir botão de aplicação somente quando o guard aprovado permitir.
9. Exigir modal de confirmação antes de chamar a mutation de aplicação.
10. Bloquear duplo clique durante aplicação.
11. Recarregar/invalidação pós-aplicação por hooks já existentes.
12. Documentar smoke funcional da UI.

### 4.2 Fora do escopo

1. Alterar motor financeiro.
2. Alterar parser.
3. Alterar Worker, Make ou n8n.
4. Criar ou alterar migrations.
5. Alterar RPCs financeiras.
6. Alterar regras de cálculo.
7. Alterar agenda ou parcelas diretamente no frontend.
8. Fazer update/delete/insert direto em tabela financeira.
9. Enviar campos soberanos pelo frontend.
10. Expor payload administrativo em visão cliente.
11. Implementar regra crítica em React.

---

## 5. Arquivos esperados

### 5.1 Arquivo principal recomendado

```text
src/components/MesaCliente/OperacoesFinanceirasPanel.jsx
```

### 5.2 Subcomponentes opcionais

Podem ser criados apenas se melhorarem legibilidade e mantiverem a mudança incremental:

```text
src/components/MesaCliente/operacoes-financeiras/OperacaoFinanceiraCard.jsx
src/components/MesaCliente/operacoes-financeiras/OperacaoFinanceiraDetalhe.jsx
src/components/MesaCliente/operacoes-financeiras/OperacaoFinanceiraResumoAdmin.jsx
src/components/MesaCliente/operacoes-financeiras/OperacaoFinanceiraClienteSafePreview.jsx
src/components/MesaCliente/operacoes-financeiras/AplicarOperacaoFinanceiraModal.jsx
```

A decisão final deve respeitar a estrutura real do repositório e evitar fragmentação desnecessária.

---

## 6. Hooks autorizados para uso

A Fase 8C deve consumir os hooks já aprovados na Fase 8B:

- `useOperacoesFinanceirasAdmin`
- `useOperacaoFinanceiraAdmin`
- `useResumoOperacaoFinanceiraAdmin`
- `useResumoOperacaoClienteSafe`
- `useAplicarOperacaoFinanceiraAdmin`

Também pode usar o helper de gating:

- `canAplicarOperacaoFinanceira`

Não é permitido chamar RPC financeira crítica diretamente a partir do componente React.

---

## 7. Contrato de props do componente

Assinatura recomendada:

```jsx
<OperacoesFinanceirasPanel
  sb={sb}
  token={token}
  simulacaoId={simulacaoId}
  agendaId={agendaId}
  usuarioPodeAplicar={usuarioPodeAplicar}
  modo="admin"
/>
```

### 7.1 Props mínimas

| Prop | Tipo | Obrigatória | Observação |
|---|---|---|---|
| `sb` | object | sim | client já existente no app |
| `token` | string | sim | sessão autenticada |
| `simulacaoId` | string | sim | escopo de consulta da listagem |
| `agendaId` | string/null | não | filtro opcional |
| `usuarioPodeAplicar` | boolean | não | guard visual; RPC continua soberana |
| `modo` | string | não | inicialmente apenas `admin` |

### 7.2 Campos que não devem ser props soberanas

A UI não deve receber como autoridade:

- `tenant_id`
- `empresa_id`
- `role`
- `perfil`
- `status_operacao`
- `valor_movido`
- `taxa_ano_pct`
- `vpl_aplicado_pct`
- `confirmado`
- `visivel_cliente`
- `metadata`

Se algum desses valores aparecer na UI, deve vir exclusivamente do retorno das RPCs/hook, não como comando soberano do frontend.

---

## 8. Estados visuais obrigatórios

O painel deve tratar explicitamente:

### 8.1 Estado sem contexto

Quando faltar `sb`, `token` ou `simulacaoId`, renderizar aviso operacional e não chamar hooks de dados.

### 8.2 Loading

Renderizar estado de carregamento durante listagem, detalhe, resumo admin, cliente-safe e aplicação.

### 8.3 Vazio

Quando não houver operações financeiras, exibir mensagem clara:

```text
Nenhuma operação financeira encontrada para esta simulação.
```

### 8.4 Erro

Exibir mensagem amigável baseada em `mappedError` ou erro normalizado, sem vazar stack trace ou payload bruto.

### 8.5 Sem permissão

Se o backend retornar bloqueio de perfil/escopo, exibir mensagem operacional sem expor detalhes técnicos internos.

### 8.6 Aplicação em andamento

Durante a mutation de aplicação:

- desabilitar botão;
- exibir loading;
- impedir duplo clique;
- não alterar estado local como se a operação já tivesse sido aplicada antes do retorno.

### 8.7 Pós-aplicação

Após sucesso:

- recarregar dados via invalidation já existente;
- esconder botão de aplicação;
- exibir status final retornado/recarregado;
- manter prévia cliente-safe protegida.

---

## 9. Estados de operação suportados

A UI deve reconhecer:

```text
simulada
confirmada
aplicada
cancelada
bloqueada
```

### 9.1 `simulada`

Exibir operação para análise. Não exibir ação de aplicação.

### 9.2 `confirmada`

Exibir possibilidade de aplicação apenas se `canAplicarOperacaoFinanceira` retornar `allowed = true`.

### 9.3 `aplicada`

Exibir selo de operação aplicada. Não permitir reaplicação.

### 9.4 `cancelada`

Exibir status cancelado e não permitir aplicação.

### 9.5 `bloqueada`

Exibir status bloqueado e orientação para revisão administrativa fora do fluxo direto.

---

## 10. Gating do botão Aplicar

O botão `Aplicar operação financeira` só pode aparecer quando todas as condições forem atendidas:

1. `modo = admin`.
2. Operação selecionada existe.
3. Operação está `confirmada`.
4. Operação está marcada como confirmada pelo backend.
5. Operação não está aplicada.
6. Operação não está cancelada.
7. Operação não está bloqueada.
8. `usuarioPodeAplicar` não bloqueia visualmente.
9. `canAplicarOperacaoFinanceira` retorna `allowed = true`.

Mesmo se a UI falhar, a RPC continua sendo a autoridade final.

---

## 11. Modal obrigatório de confirmação

Antes de chamar `useAplicarOperacaoFinanceiraAdmin`, a UI deve exibir modal com texto claro.

Texto recomendado:

```text
Você está prestes a aplicar esta operação financeira.
Essa ação altera o fluxo financeiro da proposta e não deve ser repetida.
Confirme somente se a operação já foi validada com o cliente e/ou gestor responsável.
```

Botões:

```text
Cancelar
Aplicar operação financeira
```

O modal não deve permitir confirmar se a mutation já estiver em andamento.

---

## 12. Payload permitido na aplicação

A UI pode enviar apenas campos informativos e não soberanos:

```json
{
  "motivo": "aplicacao_confirmada_na_interface",
  "observacao": "texto opcional do usuário",
  "metadata": {
    "origem_componente": "OperacoesFinanceirasPanel"
  }
}
```

O adapter da Fase 8B continuará gerando/normalizando:

- `origem_front`
- `correlation_id`
- `metadata_front`

---

## 13. Dados proibidos na prévia cliente-safe

A prévia cliente-safe não pode exibir:

- VPL interno.
- Percentuais internos de política financeira.
- Prêmio/comissão.
- Score ou regra interna de aprovação.
- Auditoria bruta.
- Metadata bruta.
- IDs técnicos de empresa/tenant/perfil.
- Dados de usuário administrativo.

Se o payload cliente-safe retornar algum campo sensível, a UI deve ocultar e a ocorrência deve ser tratada como falha crítica no smoke.

---

## 14. Layout funcional recomendado

Estrutura inicial recomendada:

```text
[Header do painel]
  - título
  - status geral
  - filtros simples

[Coluna/lista de operações]
  - tipo
  - status
  - valor resumido se disponível
  - data
  - selo cliente-safe quando aplicável

[Área de detalhe]
  - detalhe administrativo
  - resumo administrativo
  - prévia cliente-safe
  - auditoria resumida
  - ação Aplicar, quando permitida
```

A implementação deve priorizar clareza operacional e segurança antes de sofisticação visual.

---

## 15. Filtros permitidos na UI

Filtros visuais permitidos:

- `status_operacao`
- `tipo_operacao`
- `page/pageSize` ou `limit/offset`
- `order_by`
- `order_dir`
- `data_de`
- `data_ate`

A UI não deve permitir filtros por campos soberanos como empresa, tenant, perfil ou usuário.

---

## 16. Tratamento de erros

A UI deve usar o mapeamento do adapter/hook para mensagens operacionais.

Regras:

1. Não exibir stack trace.
2. Não exibir payload bruto da RPC.
3. Não exibir campos internos em mensagens para cliente-safe.
4. Erro de escopo/permissão deve ser tratado como bloqueio operacional.
5. Erro de status deve orientar o usuário sobre confirmação/aplicação.

---

## 17. Critérios de aceite da Fase 8C

A Fase 8C só pode ser considerada implementada se:

1. O painel renderizar sem quebrar o MesaCliente quando não houver operação financeira.
2. O painel consumir apenas hooks aprovados na Fase 8B.
3. Nenhum componente chamar RPC financeira diretamente.
4. O botão de aplicação respeitar `canAplicarOperacaoFinanceira`.
5. O modal de confirmação existir antes da mutation.
6. O botão bloquear duplo clique durante aplicação.
7. O payload enviado for mínimo e não soberano.
8. A prévia cliente-safe não exibir campos internos.
9. Estados loading/vazio/erro/sem permissão forem tratados.
10. O motor financeiro, parser, Worker, Make, n8n, migrations e RPCs permanecerem preservados.
11. Houver documentação de smoke funcional.
12. Houver validação estática específica da 8C antes de avançar.

---

## 18. Teste estático recomendado para próxima etapa

Criar teste:

```text
scripts/tests/mesa-cliente/17c_validacao_estatica_operacoes_financeiras_panel.mjs
```

Objetivo do 17C:

1. Confirmar existência do componente `OperacoesFinanceirasPanel.jsx`.
2. Confirmar uso dos hooks aprovados.
3. Confirmar ausência de chamada direta a RPC financeira no componente.
4. Confirmar presença de modal de confirmação.
5. Confirmar gating por `canAplicarOperacaoFinanceira`.
6. Confirmar tratamento de loading/vazio/erro.
7. Confirmar ausência de alteração em motor financeiro/migrations/worker/make/n8n.
8. Gerar artifact `17c_resultado.json`.

---

## 19. Build e smoke após implementação

Após implementar a UI:

```bash
npm install
npm run build
```

Se existir lint configurado:

```bash
npm run lint
```

Smoke funcional mínimo:

1. Abrir MesaCliente autenticado.
2. Acessar simulação com operação financeira.
3. Ver listagem de operações.
4. Selecionar operação.
5. Ver detalhe admin.
6. Ver resumo admin.
7. Ver prévia cliente-safe.
8. Confirmar que operação simulada/cancelada/bloqueada não permite aplicação.
9. Confirmar que operação confirmada habilita aplicação somente para perfil permitido.
10. Abrir modal de confirmação.
11. Aplicar somente em ambiente controlado e com autorização explícita.
12. Confirmar atualização para `aplicada`.
13. Confirmar que a ação não fica disponível novamente.

---

## 20. Riscos e mitigação

| Risco | Impacto | Mitigação |
|---|---|---|
| UI chamar RPC direta | perda de governança | usar apenas hooks 8B |
| Botão aplicar visível indevidamente | erro operacional | helper de gating + RPC soberana |
| Duplo clique | tentativa duplicada | loading + disable |
| Payload soberano | risco crítico multi-tenant | sanitização do adapter + teste 17C |
| Vazamento cliente-safe | risco comercial | componente separado e smoke específico |
| Alteração acidental de motor | regressão financeira | teste estático e revisão de diff |
| UI complexa demais | manutenção difícil | versão incremental primeiro |

---

## 21. Plano incremental proposto

### 21.1 Passo 1 — contrato

Este documento.

### 21.2 Passo 2 — teste 17C antes ou junto da UI

Criar validação estática para proteger o escopo.

### 21.3 Passo 3 — componente visual mínimo

Criar painel com listagem, detalhe, resumo e cliente-safe.

### 21.4 Passo 4 — ação de aplicação com modal

Adicionar botão e mutation com gating e loading.

### 21.5 Passo 5 — build/lint

Executar validação local e CI se aplicável.

### 21.6 Passo 6 — smoke funcional documentado

Registrar resultado em documento específico.

---

## 22. Decisão

Este contrato autoriza apenas a preparação e futura implementação visual da Fase 8C dentro dos limites descritos.

Não autoriza alteração do motor financeiro, parser, Worker/Make/n8n, migrations, RPCs, agenda ou parcelas.

**Status:** `AGUARDANDO APROVAÇÃO DO USUÁRIO PARA INICIAR CÓDIGO DA 8C`.
