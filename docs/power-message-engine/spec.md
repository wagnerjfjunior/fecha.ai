# SPEC — Power Message Engine v1

## 1. Visão geral

O **Power Message Engine** será o motor de mensagens, scripts e cadências comerciais do FECH.AI.

Ele deve funcionar como uma camada operacional entre:

- lead;
- corretor;
- empreendimento;
- origem do lead;
- canal de contato;
- estágio de abordagem;
- histórico de interações;
- feedback comercial.

O objetivo é acelerar o trabalho do corretor com comunicação orientada, sem retirar controle humano nas etapas críticas.

---

## 2. Problema que resolve

Hoje, o corretor perde tempo e qualidade porque precisa decidir manualmente:

- qual mensagem enviar;
- quando insistir;
- quando parar;
- quando ligar;
- como se apresentar;
- como abordar lead frio, quente ou visitante de plantão;
- como registrar o resultado;
- como não se perder no follow-up.

O resultado comum é uma operação irregular: alguns leads recebem contato rápido, outros somem no limbo, mensagens ficam repetitivas e a gestão não sabe exatamente o que aconteceu.

O Power Message Engine resolve isso criando uma régua assistida, simples e rastreável.

---

## 3. Modos principais

### 3.1 Central de Mensagens

Biblioteca estruturada de mensagens e scripts.

Deve permitir filtrar por:

- empresa/tenant;
- empreendimento;
- canal;
- tipo de lead;
- fase;
- tom de abordagem;
- objetivo;
- status ativo/inativo.

### 3.2 Oferta Ativa / Acelerador

Modo operacional guiado para o corretor.

Fluxo esperado:

1. Corretor abre um lead.
2. Sistema identifica tipo do lead e contexto.
3. Corretor escolhe estratégia inicial: WhatsApp, ligação ou e-mail.
4. Sistema sugere a melhor mensagem ou script.
5. Corretor executa a ação.
6. Corretor registra o feedback.
7. Sistema sugere próximo passo.

Esse modo deve ser extremamente simples, inclusive para corretores com baixa familiaridade tecnológica.

### 3.3 Piloto Automático

Modo de cadência controlada.

Pode sugerir, agendar ou executar ações conforme política do tenant e consentimento do lead.

Na v1, o recomendado é começar com:

- lembretes automáticos;
- sugestão de próxima ação;
- mensagens pré-preenchidas;
- e-mail semi-automatizado;
- WhatsApp preferencialmente assistido, com clique humano.

Automação total deve ser tratada como fase posterior e com regras rígidas.

---

## 4. Tipos de lead

### 4.1 Lead quente

Lead gerado por campanha, landing page, Meta Ads, Google Ads, formulário, WhatsApp ou interação recente.

Abordagem:

- rápida;
- direta;
- contextualizada;
- com CTA claro;
- tom consultivo-comercial.

### 4.2 Lista fria

Lead vindo de base importada, base comprada, base antiga ou sem manifestação recente de interesse.

Abordagem:

- mais cuidadosa;
- menos invasiva;
- com pedido de permissão;
- sem pressupor interesse atual;
- foco em abertura de conversa.

### 4.3 Lista quente

Lead de lista própria, reativação, pessoas que já falaram com equipe, visitaram página, responderam campanha ou tiveram contato anterior.

Abordagem:

- retomar contexto;
- citar interação anterior quando existir;
- evitar parecer mensagem genérica;
- foco em avançar para conversa ou visita.

### 4.4 Visitou plantão

Lead que esteve presencialmente no stand/plantão.

Abordagem:

- mais personalizada;
- retomar visita;
- perguntar percepção;
- trabalhar objeções;
- estimular nova conversa, simulação ou proposta.

---

## 5. Fases comerciais

### 5.1 Primeira mensagem

Objetivo: abrir contato.

Características:

- apresentação clara;
- contexto do motivo do contato;
- CTA leve;
- sem pressão exagerada.

### 5.2 Segunda mensagem

Objetivo: retomar sem parecer insistência burra.

Características:

- lembrar o benefício;
- variar o ângulo;
- perguntar se faz sentido;
- oferecer ajuda objetiva.

### 5.3 Terceira mensagem

Objetivo: tentar conversão antes da finalização.

Características:

- mais direta;
- pode trazer oportunidade, condição, disponibilidade ou convite;
- pede uma resposta simples.

### 5.4 Mensagem final

Objetivo: encerrar a cadência de forma elegante e preservar relacionamento.

Características:

- educada;
- sem tom de cobrança;
- deixa canal aberto;
- pode pedir autorização para contato futuro.

---

## 6. Randomização controlada

O sistema deve selecionar mensagens de forma variada, mas governada.

### 6.1 O que pode randomizar

- variação textual;
- abertura da mensagem;
- CTA final;
- ordem dos argumentos;
- tom mais formal ou mais leve;
- mensagem por fase dentro do mesmo objetivo.

### 6.2 O que não pode randomizar sem regra

- dados de preço;
- nome do empreendimento;
- nome do corretor;
- telefone;
- empresa;
- condição comercial;
- promessa de desconto;
- afirmações regulatórias;
- informação jurídica ou financeira.

### 6.3 Regras mínimas

- Nunca repetir a mesma mensagem para o mesmo lead na mesma fase.
- Preferir mensagens menos usadas recentemente.
- Não enviar mensagem fora da fase correta.
- Não enviar mensagem sem registrar evento.
- Respeitar opt-out e bloqueios.
- Registrar qual template foi sugerido/enviado.

---

## 7. Canais

### 7.1 WhatsApp

Na v1, tratar como canal assistido.

O sistema deve:

- sugerir mensagem;
- preencher texto;
- abrir link ou deep link;
- registrar envio manual;
- orientar próximo passo.

### 7.2 Ligação

O sistema deve exibir script de ligação conforme contexto.

O script deve conter:

- abertura;
- identificação do corretor;
- motivo da ligação;
- pergunta de qualificação;
- caminho para objeções;
- CTA;
- campos de feedback rápido.

### 7.3 E-mail

O sistema deve sugerir assunto e corpo do e-mail.

Pode operar em modo:

- copiar texto;
- abrir cliente de e-mail;
- integração SMTP futura;
- automação futura por tenant.

---

## 8. Fluxo do Acelerador

### Entrada

O corretor clica em **Oferta Ativa / Acelerador**.

### Passo 1 — Seleção da estratégia

O corretor escolhe a ordem de canais:

- WhatsApp primeiro;
- ligação primeiro;
- e-mail primeiro;
- desativar algum canal;
- sequência sugerida pelo sistema.

### Passo 2 — Estado do relacionamento

O corretor informa:

- nunca falei com o cliente;
- já falei com o cliente;
- cliente visitou plantão;
- cliente pediu retorno;
- cliente não responde.

### Passo 3 — Execução

O sistema mostra:

- mensagem sugerida;
- botão copiar;
- botão abrir WhatsApp;
- botão ligar;
- botão gerar e-mail;
- script lateral para ligação.

### Passo 4 — Feedback obrigatório

Após a ação, corretor deve registrar:

- contato feito;
- não respondeu;
- chamou no WhatsApp;
- ligação realizada;
- caixa postal;
- número errado;
- pediu retorno;
- interessado;
- sem interesse;
- agendou visita;
- proposta/simulação;
- lead já atendido.

### Passo 5 — Próxima ação

Sistema sugere:

- próxima mensagem;
- próxima ligação;
- e-mail de reforço;
- pausa;
- encerramento da cadência;
- mover lead de estágio.

---

## 9. Piloto Automático

### 9.1 Função

Organizar a cadência sem depender da memória do corretor.

### 9.2 Ações permitidas na v1

- criar tarefa de retorno;
- sugerir próxima mensagem;
- avisar lead parado;
- recomendar troca de canal;
- alertar excesso de tentativas;
- pausar lead sem resposta.

### 9.3 Ações que exigem cuidado

- envio automático de WhatsApp;
- campanhas para listas frias;
- mensagens em lote;
- reativação de base antiga;
- múltiplos números por tenant.

Essas ações devem depender de política explícita, consentimento, logs e limites.

---

## 10. Critérios de aceite v1

A v1 será considerada pronta quando:

- existir cadastro de templates por canal, fase e tipo de lead;
- existir seleção automática de template elegível;
- existir histórico de templates usados por lead;
- o corretor conseguir executar WhatsApp assistido;
- o corretor visualizar script de ligação;
- o corretor registrar feedback obrigatório;
- o sistema sugerir próxima ação;
- gestores conseguirem ativar/inativar templates;
- templates respeitarem tenant/empresa;
- houver trilha de auditoria mínima.

---

## 11. Fora do escopo da v1

- disparador massivo de WhatsApp;
- chipeira;
- automação para burlar bloqueio;
- integração WABA multi-tenant completa;
- IA gerando mensagem sem aprovação humana;
- editor visual complexo de cadência;
- testes A/B estatísticos completos;
- envio por SMTP multi-tenant completo.

---

## 12. Observações arquiteturais

Este documento não autoriza alteração no motor atual do FECH.AI.

Qualquer implementação deve:

- preservar RPCs existentes;
- preservar RLS;
- respeitar tenant;
- não quebrar fluxo atual de leads;
- trabalhar por branches/PRs;
- aplicar mudanças incrementais;
- evitar refatoração grande sem aprovação.
