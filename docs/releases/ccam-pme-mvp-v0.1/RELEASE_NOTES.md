# Release Notes — Discador Flow AI / PME Beta v0.2.5

**Status:** candidato a merge controlado  
**Branch:** `feature/ccam-pme-mvp-v0.1`  
**PR:** #20  
**Destino planejado:** `main` via squash merge, após validação final em preview

---

## Resumo executivo

Esta release evolui o discador do FECH.AI para um fluxo operacional assistido do corretor: lead → origem → canal → situação → mensagem/script → IA opcional → execução → feedback.

O objetivo é reduzir atrito no atendimento, padronizar abordagem comercial e permitir que o corretor use mensagens, scripts e argumentos de venda em tempo real, sem alterar o motor de feedback, RPCs, RLS, banco, auth ou regras centrais do sistema.

---

## Escopo funcional entregue

### Discador Flow AI / PME

- Header visual `Discador Flow AI` no topo do discador.
- Card `Fluxo de atendimento` posicionado antes da seção de feedback.
- Remoção visual dos botões redundantes do primeiro quadro do lead.
- Remoção visual do botão duplicado `Power Dial — OFF/ON` do canto superior direito.
- Fluxo por passos:
  1. origem do lead;
  2. canal de contato;
  3. situação do cliente;
  4. execução do contato.

### Origem do lead

Badges disponíveis:

- Carteira;
- Lista fria;
- Já visitou;
- Redes Sociais;
- Problemas;
- Argumentações.

### Canal

Canais disponíveis:

- Ligação;
- WhatsApp;
- E-mail.

Cada canal possui botão de apoio acima do badge:

- Power Dial;
- Power Zap;
- Power Mail.

### Tipo de abordagem

Situações disponíveis:

- Primeira abordagem;
- Retorno;
- Pós-ligação;
- Convite para visita;
- Objeção de preço;
- Objeção de entrada;
- Cliente sem resposta;
- Fim de contato.

### Execução dinâmica

O botão principal muda conforme o canal selecionado:

- Ligação → `Efetuar ligação`;
- WhatsApp → `Abrir WhatsApp`;
- E-mail → `Preparar e-mail`.

Comportamento:

- Ligação: copia a fala de apoio e tenta acionar `tel:`.
- WhatsApp: abre `wa.me` com mensagem pronta para revisão manual.
- E-mail: monta `mailto:` com assunto e corpo quando o e-mail do lead existe.

---

## IA no MVP

### Comportamento entregue

- Botão `Melhorar com IA` abre modal com o texto base.
- O modal respeita o canal já escolhido no fluxo.
- O botão principal do modal replica a ação dinâmica:
  - `Efetuar ligação`;
  - `Abrir WhatsApp`;
  - `Preparar e-mail`.
- A dica do corretor passou a ser tratada como diretriz principal do prompt.
- Foi criado patch de contexto para reduzir respostas repetitivas e forçar aderência à dica.
- O prompt agora diferencia formato de ligação, WhatsApp e e-mail.
- O prompt inclui regra anti-repetição e instrução explícita para não inventar preço, desconto, unidade, disponibilidade ou condição.

### Arquivos funcionais da IA

- `public/pme-call-assistant-beta.js`
- `public/pme-call-assistant-ai-context-patch.js`
- `src/main.jsx`

---

## Segurança e limites preservados

Esta release **não** altera:

- Supabase migrations;
- RPCs;
- RLS;
- grants;
- auth;
- feedback;
- motor de distribuição de lead;
- regras de tenant/empresa/perfil;
- Worker;
- Make/n8n;
- cobrança/billing real;
- envio automático de WhatsApp, e-mail ou ligação.

A IA é assistiva. O corretor sempre revisa antes de executar qualquer ação.

---

## Risco da release

**Classificação:** R2 controlado.

Motivo:

- Há alteração funcional no frontend e carregamento de scripts beta.
- Não há alteração em banco, RLS, RPC ou feedback.
- Existe plano de rollback simples: remover o carregamento dos scripts e/ou redeploy anterior na Vercel.

---

## Condição para merge em main

Antes do merge:

- Validar preview no desktop.
- Validar preview no celular.
- Confirmar clique único nos badges e botões.
- Confirmar combo de abordagem funcionando.
- Confirmar IA com dica contextualizada.
- Confirmar execução por ligação, WhatsApp e e-mail.
- Confirmar feedback sem regressão.
- Confirmar Vercel com status verde.

---

## Fora desta release

- WABA oficial.
- SMTP multiempresa definitivo.
- Billing definitivo do módulo IA.
- Banco de respostas utilizadas.
- Cache semântico para reuso de respostas.
- Score final persistido da utilidade do script.
- Tela administrativa definitiva da biblioteca de scripts.
- Migração modular completa para `src/features/discador-flow-ai`.
