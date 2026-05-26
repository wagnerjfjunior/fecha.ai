# FECH.AI — MesaCliente
# Fase 8F — Contrato de Seleção Segura de Simulação para Operações Financeiras

## 1. Identificação

**Projeto:** `FECH.AI / MesaCliente`  
**Fase:** `8F — Seleção segura de simulação para Operações Financeiras`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Status:** `CONTRATO CRIADO — AGUARDANDO IMPLEMENTAÇÃO CONTROLADA`  
**Pré-requisitos concluídos:**

- `17C — OperacoesFinanceirasPanel estático`: `PASS`.
- `17D — Build painel`: `PASS`.
- `18A — Integração visual segura`: `PASS`.
- `18B — Build pós-integração visual`: `PASS`.

---

## 2. Objetivo

Permitir que o usuário abra a aba `Operações` a partir de uma proposta/simulação real exibida no `Histórico`, passando ao `OperacoesFinanceirasPanel` um `simulacaoId` persistido e confiável.

Essa fase deve transformar o estado atual:

```text
Operações → simulacaoId={null} → painel bloqueado
```

em um fluxo controlado:

```text
Histórico → botão Operações → seleciona item.id → abre aba Operações → painel recebe simulacaoId real
```

---

## 3. Princípio de segurança

O frontend não é autoridade sobre tenant, empresa, perfil, status financeiro, valores ou permissões administrativas.

A Fase 8F autoriza apenas o transporte visual do identificador já retornado pelo histórico:

```text
item.id
```

O backend/RPC continua sendo soberano para validar:

- `auth.uid()`;
- tenant;
- empresa;
- perfil;
- escopo de acesso;
- existência da simulação;
- vínculo com operações financeiras;
- autorização de leitura/aplicação.

---

## 4. Fonte autorizada do `simulacaoId`

A única fonte autorizada nesta fase é:

```text
TabHistorico → historico.map(item) → item.id
```

Justificativa:

- `TabHistorico` já consome `useHistoricoMesas`;
- o histórico já é filtrado por `empresaId` e, para corretor comum, por `corretorId`;
- gestor visualiza todos, corretor visualiza apenas os seus;
- `item.id` representa a proposta/simulação persistida.

---

## 5. Fontes proibidas para `simulacaoId`

Não é permitido derivar `simulacaoId` de:

- `empresaId`;
- `ctx.empresaId`;
- `corretorId`;
- `ctx.corretorId`;
- empreendimento;
- unidade;
- cliente_nome;
- status;
- posição no array;
- índice visual;
- metadata textual;
- localStorage/sessionStorage;
- query string sem validação posterior.

---

## 6. Arquivos permitidos na implementação

### 6.1 `src/components/MesaCliente/index.jsx`

Alterações permitidas:

- criar estado local `simulacaoOperacoesSelecionada`;
- criar handler `abrirOperacoesFinanceiras(item)`;
- definir `simulacaoOperacoesSelecionada` a partir de `item.id`;
- mudar `tab` para `ops`;
- passar `simulacaoId={simulacaoOperacoesSelecionada?.id || null}` ao painel;
- exibir contexto mínimo da simulação selecionada acima do painel.

### 6.2 `src/components/MesaCliente/TabHistorico.jsx`

Alterações permitidas:

- receber prop opcional `onAbrirOperacoesFinanceiras`;
- passar essa prop para `HistCard`;
- exibir botão `Operações financeiras` em cada card com `item.id` válido;
- chamar `onAbrirOperacoesFinanceiras(item)`.

---

## 7. Arquivos proibidos nesta fase

Não alterar:

- `supabase/migrations/**`;
- `supabase/tests/**`;
- `workers/**`;
- `worker/**`;
- `make/**`;
- `n8n/**`;
- parser;
- motor financeiro;
- RPCs;
- agenda;
- parcelas.

---

## 8. Comportamento esperado

### 8.1 Sem simulação selecionada

Ao abrir a aba `Operações` diretamente, sem seleção prévia:

```text
Operações financeiras indisponíveis
Não foi possível identificar sessão, token ou simulação. A consulta foi bloqueada antes de chamar os hooks de dados.
```

Essa condição deve permanecer válida.

### 8.2 Com simulação selecionada no Histórico

Ao clicar em `Operações financeiras` em um card do histórico:

1. `index.jsx` recebe o item completo.
2. O handler valida se `item.id` existe.
3. O estado local guarda contexto mínimo:

```js
{
  id: item.id,
  cliente_nome: item.cliente_nome,
  empreendimento: item.empreendimento,
  unidade: item.unidade,
  status: item.status,
  valor_total: item.valor_total
}
```

4. A aba muda para `ops`.
5. O painel recebe:

```jsx
simulacaoId={simulacaoOperacoesSelecionada?.id || null}
```

6. O painel passa a consultar operações financeiras via hooks/adapter já aprovados.

---

## 9. Dados permitidos no contexto visual

A interface pode mostrar apenas dados comerciais já exibidos no histórico:

- cliente_nome;
- empreendimento;
- unidade;
- status;
- valor_total.

Esses dados são contexto visual, não autoridade financeira.

---

## 10. Dados proibidos no contexto visual

Não incluir no estado visual como fonte de autoridade:

- tenant_id;
- empresa_id como simulacaoId;
- corretor_id como simulacaoId;
- role/perfil;
- status_operacao financeiro;
- valores de operação financeira;
- flags de confirmação/aplicação;
- metadata financeira;
- checksum;
- payload bruto de RPC.

---

## 11. Gating de aplicação

O botão de aplicação continua dependendo de duas camadas:

1. Guard visual:

```jsx
usuarioPodeAplicar={ctx.isGestor}
```

2. RPC soberana no backend.

A Fase 8F não altera regras de aplicação financeira.

---

## 12. Critérios de aceite

A fase será aceita quando:

1. `TabHistorico` tiver botão `Operações financeiras` por card.
2. O botão só chamar handler quando `item.id` existir.
3. `index.jsx` mantiver estado `simulacaoOperacoesSelecionada`.
4. `index.jsx` passar `simulacaoId={simulacaoOperacoesSelecionada?.id || null}` ao painel.
5. A aba `Operações` abrir após clique no Histórico.
6. O estado bloqueado sem simulação continuar preservado.
7. Nenhum arquivo proibido for alterado.
8. Build continuar aprovado.
9. Não houver derivação de `simulacaoId` por empresa/corretor/empreendimento/unidade.

---

## 13. Teste recomendado

Criar gate estático:

```text
18C — Validação Estática de Seleção Segura de Simulação para Operações
```

Arquivo sugerido:

```text
scripts/tests/mesa-cliente/18c_validacao_selecao_segura_simulacao_operacoes_financeiras.mjs
```

Validar:

- `TabHistorico` recebe `onAbrirOperacoesFinanceiras`;
- `HistCard` recebe o callback;
- botão `Operações financeiras` existe;
- callback é acionado com `item`;
- `index.jsx` cria estado `simulacaoOperacoesSelecionada`;
- handler usa `item.id`;
- `simulacaoId` do painel vem de `simulacaoOperacoesSelecionada?.id || null`;
- sem derivação indevida de `simulacaoId`;
- arquivos de motor preservados.

---

## 14. Limites

A Fase 8F não valida ainda:

- existência real de operações financeiras para a simulação;
- resposta real das RPCs do painel;
- aplicação real de operação;
- smoke E2E completo;
- regressão visual avançada.

Esses itens devem ser validados em gates posteriores.

---

## 15. Decisão

A Fase 8F autoriza a seleção controlada de simulação a partir do `Histórico`, usando exclusivamente `item.id` como `simulacaoId` para o painel de operações financeiras.

Não autoriza alteração de motor financeiro, parser, Worker/Make/n8n, migrations, RPCs, agenda ou parcelas.

**Status:** `APROVADO PARA IMPLEMENTAÇÃO CONTROLADA`.
