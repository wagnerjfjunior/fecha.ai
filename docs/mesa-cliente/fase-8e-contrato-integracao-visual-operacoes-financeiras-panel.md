# FECH.AI — MesaCliente
# Fase 8E — Contrato de Integração Visual do OperacoesFinanceirasPanel

## 1. Identificação

**Projeto:** `FECH.AI / MesaCliente`  
**Fase:** `8E — Integração visual controlada do OperacoesFinanceirasPanel`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Status:** `CONTRATO CRIADO — AGUARDANDO IMPLEMENTAÇÃO CONTROLADA`  
**Pré-requisitos concluídos:**

- `8B — Adapter/Front BFF`: validado com `17B PASS`.
- `8C — OperacoesFinanceirasPanel.jsx`: validado com `17C PASS`.
- `17D — Build Validation`: validado com `17D PASS`.

---

## 2. Objetivo

Integrar visualmente o `OperacoesFinanceirasPanel.jsx` na navegação real do MesaCliente sem alterar motor financeiro, parser, Worker/Make/n8n, migrations, RPCs, agenda ou parcelas.

A Fase 8E deve apenas tornar o painel acessível na interface principal, mantendo a aplicação financeira sob controle dos hooks/adapter/RPC já aprovados nas fases anteriores.

---

## 3. Estado atual da navegação

O componente principal do MesaCliente atualmente possui três abas:

```text
Empreendimentos
Fluxo
Histórico
```

Arquivo envolvido:

```text
src/components/MesaCliente/index.jsx
```

A Fase 8E deve adicionar uma nova aba visual para operações financeiras, sem remover ou alterar o comportamento das abas existentes.

---

## 4. Nova aba proposta

Adicionar aba:

```text
Operações
```

Identificador interno recomendado:

```text
ops
```

Ícone sugerido:

```text
💳
```

Posição recomendada:

```text
Empreendimentos | Fluxo | Histórico | Operações
```

Justificativa:

- `Histórico` continua sendo histórico de propostas/simulações.
- `Operações` fica como camada administrativa financeira separada.
- Evita poluir `TabHistorico` com responsabilidade financeira.

---

## 5. Arquivos permitidos na Fase 8E

### 5.1 Alteração permitida

```text
src/components/MesaCliente/index.jsx
```

Finalidade:

- importar `OperacoesFinanceirasPanel`;
- adicionar aba `ops`;
- renderizar o painel quando `tab === 'ops'`.

### 5.2 Arquivos que não devem ser alterados na 8E

- `supabase/migrations/**`
- `supabase/tests/**`
- `workers/**`
- `worker/**`
- `make/**`
- `n8n/**`
- parser
- motor financeiro
- RPCs
- agenda/parcelas

---

## 6. Contexto obrigatório para renderização

O painel exige:

- `sb`
- `token`
- `simulacaoId`
- `agendaId` opcional
- `usuarioPodeAplicar`
- `modo`

A integração visual não deve inventar `simulacaoId`.

---

## 7. Decisão sobre `simulacaoId`

Como a navegação principal ainda não mantém uma simulação selecionada globalmente, a Fase 8E deve renderizar o painel com modo protegido quando não houver `simulacaoId` disponível.

Regra:

```text
Sem simulacaoId explícito, o painel deve abrir em estado operacional bloqueado, sem chamada de dados financeiros.
```

A prop `simulacaoId` deve ser alimentada somente quando existir origem confiável no fluxo do MesaCliente, por exemplo:

- simulação/proposta selecionada no histórico;
- simulação recém-salva no fluxo;
- rota futura com ID controlado;
- estado global definido após ação do usuário.

Não é permitido derivar `simulacaoId` de empreendimento, unidade, empresa, corretor ou qualquer campo que não represente uma simulação financeira persistida.

---

## 8. Integração inicial permitida

A primeira integração visual pode renderizar:

```jsx
<OperacoesFinanceirasPanel
  sb={sb}
  token={token}
  simulacaoId={null}
  agendaId={null}
  usuarioPodeAplicar={ctx.isGestor}
  modo="admin"
/>
```

Resultado esperado:

- aba aparece;
- componente renderiza estado bloqueado por falta de simulação;
- nenhuma chamada financeira é executada;
- fluxo principal continua estável.

Esse passo é intencionalmente conservador. Ele testa integração visual sem risco operacional.

---

## 9. Próxima evolução após integração inicial

Após a aba existir e compilar, a evolução correta é criar seleção segura de simulação, provavelmente a partir do `Histórico`.

Possível evolução futura:

1. Adicionar callback em `TabHistorico` para abrir operações de uma proposta.
2. Salvar `simulacaoSelecionadaParaOperacoes` no `MesaClienteInner`.
3. Ao clicar em uma proposta, definir o ID real da simulação persistida.
4. Abrir aba `Operações` com `simulacaoId = item.id`.

Essa evolução deve ser fase própria ou subfase controlada, porque altera interação entre histórico e operações.

---

## 10. Gating visual por perfil

Na integração inicial:

```text
usuarioPodeAplicar = ctx.isGestor
```

Observações:

- Esse é apenas guard visual.
- A RPC continua soberana.
- Se o usuário não for gestor, o botão de aplicação não deve aparecer ou deve permanecer bloqueado.
- O backend continua validando perfil, tenant, empresa e status.

---

## 11. Critérios de aceite da Fase 8E

A Fase 8E será aceita quando:

1. O `index.jsx` importar `OperacoesFinanceirasPanel`.
2. A aba `Operações` existir na navegação principal.
3. As três abas existentes continuarem preservadas.
4. O painel renderizar sem quebrar a MesaCliente.
5. Sem `simulacaoId`, o painel exibir estado bloqueado e não consultar dados financeiros.
6. O build continuar passando.
7. O gate estático da integração confirmar ausência de alterações proibidas.
8. Motor financeiro, parser, Worker/Make/n8n, migrations, RPCs, agenda e parcelas permanecerem intactos.

---

## 12. Teste recomendado

Criar gate estático:

```text
18A — Validação Estática da Integração Visual do Painel Financeiro
```

Arquivo sugerido:

```text
scripts/tests/mesa-cliente/18a_validacao_integracao_visual_operacoes_financeiras_panel.mjs
```

O teste deve validar:

1. `index.jsx` importa `OperacoesFinanceirasPanel`.
2. `TABS` contém aba `ops`/`Operações`.
3. `index.jsx` renderiza `OperacoesFinanceirasPanel` quando `tab === 'ops'`.
4. `simulacaoId` não é derivado de empresa/corretor/empreendimento.
5. `usuarioPodeAplicar` usa `ctx.isGestor` ou equivalente não soberano final.
6. Nenhuma alteração proibida em motor/migrations/worker/make/n8n/parser.
7. Build 17D continua válido após integração.

---

## 13. Riscos e mitigação

| Risco | Impacto | Mitigação |
|---|---|---|
| Ligar painel sem simulação válida | chamadas inválidas ou erro visual | renderizar bloqueado com `simulacaoId={null}` |
| Inventar `simulacaoId` | risco crítico de escopo | proibir derivação de empresa/empreendimento/unidade |
| Expor ação para usuário incorreto | risco operacional | `usuarioPodeAplicar={ctx.isGestor}` + RPC soberana |
| Quebrar navegação existente | regressão de UX | alteração mínima em `index.jsx` |
| Misturar histórico com financeiro | acoplamento indevido | aba própria `Operações` |

---

## 14. Decisão

A Fase 8E autoriza apenas a integração visual conservadora do painel em uma nova aba `Operações`, inicialmente sem `simulacaoId` até existir seleção segura de simulação.

Não autoriza alteração de motor financeiro, parser, Worker/Make/n8n, migrations, RPCs, agenda ou parcelas.

**Status:** `APROVADO PARA IMPLEMENTAÇÃO CONTROLADA DA ABA OPERAÇÕES`.
