# PME — Empreendimentos — Château Jardin — Lançamento v1

**Projeto:** FECH.AI  
**Módulo:** PME — Power Message Engine  
**Área:** Central de Mensagens / Oferta Ativa / Acelerador / Discador  
**Grupo de mensagens:** Empreendimentos  
**Empreendimento:** Château Jardin  
**Evento:** Lançamento — 30/05/2026  
**Endereço do evento:** Rua Ministro Nelson Hungria, 400  
**Canais:** WhatsApp, Ligação e E-mail  
**Modo operacional da V1:** assistido pelo corretor  
**Risco desta entrega:** R0 — Documental  
**Status:** documento inicial para validação e futura implementação controlada  
**Branch:** `feature/pme-empreendimentos-chateau-jardin-launch-v1`

---

## 1. Objetivo

Este documento define a primeira versão do upgrade da PME para suportar o novo módulo contextual **Empreendimentos**, usando o **Château Jardin** como primeiro empreendimento operacional.

O objetivo é permitir que o corretor escolha primeiro o contexto comercial do atendimento, antes de escolher a situação do lead e o canal de comunicação.

A V1 documentada aqui deve permitir, em futura implementação, que o corretor:

- escolha o grupo de mensagens **Empreendimentos**;
- escolha o empreendimento **Château Jardin**;
- escolha o evento/campanha **Lançamento 30/05/2026**;
- escolha o canal: WhatsApp, Ligação ou E-mail;
- escolha a situação do lead;
- receba mensagens/scripts prontos, com variação controlada;
- revise antes de enviar/falar;
- registre feedback após a ação.

Esta entrega **não substitui a PME existente**. Ela acrescenta uma camada contextual.

---

## 2. Decisão canônica

A PME existente será preservada.

Esta V1 adiciona o módulo contextual **Empreendimentos** à Central de Mensagens, à Oferta Ativa/Acelerador e ao Discador, permitindo que o corretor selecione primeiro o contexto comercial do empreendimento antes de escolher situação do lead, canal, fase e objetivo da abordagem.

### 2.1 O que continua sendo reutilizado

Continuam válidos todos os conceitos atuais da PME:

- canais;
- tipos de lead;
- fases da cadência;
- objetivos comerciais;
- tons de comunicação;
- intensidade da abordagem;
- pools de mensagens;
- randomização controlada;
- feedback obrigatório;
- compliance comercial;
- regras anti-spam;
- tracking de uso de mensagens;
- isolamento multiempresa/multitenant.

### 2.2 O que está sendo acrescentado

A camada nova é:

```text
PME
└── Grupo de mensagens
    └── Empreendimentos
        └── Empreendimento
            └── Evento/Campanha
                └── Canal
                    └── Situação do lead
                        └── Fase da cadência
                            └── Objetivo da abordagem
```

---

## 3. Nova ordem de escolha na PME

A ordem recomendada para o corretor configurar a PME passa a ser:

```text
1. Empresa / tenant
   - Resolvido pelo sistema/banco, não tratado como verdade soberana vinda do frontend.

2. Grupo de mensagens
   - Empreendimentos

3. Empreendimento
   - Château Jardin

4. Evento / campanha
   - Lançamento 30/05/2026

5. Canal
   - WhatsApp
   - Ligação
   - E-mail

6. Situação do lead
   - Primeiro contato
   - Convite para lançamento
   - Pediu plantas
   - Pediu valores
   - Pediu material
   - Já conhece o projeto
   - Visitou plantão
   - Pós-visita
   - Quer levar família
   - Está comparando
   - Sem resposta

7. Fase da cadência
   - Primeira mensagem
   - Segunda mensagem
   - Terceira mensagem
   - Mensagem final

8. Objetivo da abordagem
   - Abertura
   - Envio de informação
   - Convite para visita
   - Qualificação
   - Retorno
   - Objeção
   - Encerramento
```

### 3.1 Por que empreendimento não deve ficar dentro da situação do lead

Empreendimento e situação do lead são dimensões diferentes.

A situação descreve o estado comercial do cliente. O empreendimento descreve o contexto/produto da abordagem.

Misturar os dois em uma única combobox geraria confusão operacional, dificultaria filtros, relatórios, randomização e governança futura.

---

## 4. Escopo desta entrega

### 4.1 Dentro do escopo

- Documentar o módulo contextual **Empreendimentos**.
- Documentar o Château Jardin como primeiro empreendimento do grupo.
- Documentar o evento **Lançamento 30/05/2026**.
- Definir a nova ordem de escolha da PME.
- Definir mensagens para WhatsApp, ligação e e-mail.
- Definir assinatura dinâmica obrigatória.
- Definir termos bloqueados.
- Definir regras de emoji.
- Definir randomização controlada.
- Definir feedback obrigatório pós-ação.
- Definir critérios para futura implementação.

### 4.2 Fora do escopo

- Não alterar frontend.
- Não alterar Discador.
- Não alterar Central atual.
- Não alterar Supabase.
- Não criar migration.
- Não criar seed.
- Não criar RPC.
- Não alterar RLS.
- Não alterar grants.
- Não alterar auth.
- Não iniciar disparo automático.
- Não trabalhar em `main`.

---

## 5. Matriz de DML desta entrega documental

| Operação | Aplicável nesta entrega? |
|---|---:|
| SELECT | Não |
| INSERT | Não |
| UPDATE | Não |
| DELETE | Não |
| RPC | Não |
| Migration | Não |
| RLS/Policy/Grant | Não |
| Frontend | Não |
| Seed | Não |

---

## 6. Dados comerciais permitidos — Château Jardin

As mensagens podem usar os seguintes elementos comerciais:

- nome **Château Jardin**;
- lançamento em **30/05/2026**;
- evento na **Rua Ministro Nelson Hungria, 400**;
- novo eixo Cidade Jardim;
- realização Tegra + Exto;
- projeto internacional EDSA;
- arquitetura clássica com leitura contemporânea;
- inspiração no *l’art de vivre*;
- linguagem de inspiração na elegância dos jardins franceses;
- conceito de refúgio urbano;
- alto padrão;
- metragens de **185 m², 215 m², 248 m² e 355 m²**;
- quadra de tênis de saibro;
- quadra de padel;
- piscina coberta;
- wellness;
- lazer de perfil private club;
- concierge;
- courrier;
- delivery room;
- segurança e portaria;
- plantas amplas;
- atendimento por horário.

---

## 7. Termos e gatilhos bloqueados

As mensagens do Château Jardin **não devem usar**:

```text
últimas unidades
condição exclusiva
desconto de lançamento
tabela especial garantida
diretoria liberou
reserva garantida
preço fechado
melhor condição só amanhã
```

Também evitar:

```text
imperdível
só hoje
corra
não perca
oportunidade única
tenho acesso especial
consigo algo por fora
garantido
```

### 7.1 Linguagem permitida para senso de oportunidade

Usar urgência elegante, baseada em evento e organização de agenda:

```text
lançamento amanhã
evento de lançamento
atendimentos por horário
apresentação das plantas
conhecer o projeto desde o início
avaliar as opções iniciais
organizar uma visita
apresentar com calma
verificar melhor horário
```

---

## 8. Variáveis obrigatórias

### 8.1 Variáveis PME base

```text
{{nome_lead}}
{{nome_corretor}}
{{empresa}}
{{empreendimento}}
{{bairro}}
{{telefone_corretor}}
{{link_whatsapp}}
{{link_material}}
{{data_retorno}}
{{perfil_imovel}}
{{valor_referencia}}
```

### 8.2 Variável operacional para WhatsApp do corretor

Para este módulo, a assinatura exige link direto de WhatsApp do corretor.

Variável operacional recomendada:

```text
{{link_whatsapp_corretor}}
```

Compatibilidade:

```text
{{link_whatsapp_corretor}} pode mapear para a variável oficial {{link_whatsapp}} quando o link representar o WhatsApp do corretor responsável.
```

### 8.3 Variáveis fixas do evento

```text
{{empreendimento}} = Château Jardin
{{data_evento}} = 30/05/2026
{{endereco_evento}} = Rua Ministro Nelson Hungria, 400
```

---

## 9. Assinatura dinâmica obrigatória

Todas as mensagens de WhatsApp e e-mail devem terminar com:

```text
{{nome_corretor}}
{{telefone_corretor}}
WhatsApp: {{link_whatsapp_corretor}}

Ao chegar, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente.
```

Nos scripts de ligação, a assinatura deve virar fechamento verbal:

```text
O evento será na Rua Ministro Nelson Hungria, 400. Quando chegar, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente e apresentar o projeto com calma.
```

---

## 10. Regras de emoji

### 10.1 WhatsApp

Permitido usar emoji de forma discreta:

- máximo 2 emojis por mensagem;
- uso apenas para organizar leitura;
- evitar tom popular, urgente ou promocional.

Emojis permitidos:

```text
📍 localização / endereço
📐 plantas / metragens
🌿 jardins / paisagismo
🏛️ arquitetura
🗓️ evento / agenda
```

Emojis bloqueados:

```text
🔥 🚨 💥 😍 🤩 🤑 💰 ⚡ 🎯
```

### 10.2 E-mail

Não usar emoji no assunto nem no corpo.

### 10.3 Ligação

Não aplicável.

### 10.4 Distribuição recomendada

```text
70% das mensagens WhatsApp sem emoji
30% das mensagens WhatsApp com emoji discreto
```

---

## 11. Regras de randomização

A randomização deve humanizar a comunicação e evitar repetição artificial.

Ela **não deve ser usada como tentativa de burlar bloqueio**.

Regras:

- não repetir a mesma variação para o mesmo lead na mesma fase;
- evitar enviar mensagens muito parecidas em sequência;
- priorizar mensagens menos usadas recentemente;
- respeitar opt-out;
- parar se o cliente demonstrar rejeição clara;
- registrar qual variação foi utilizada;
- registrar feedback pós-ação;
- não enviar automaticamente sem etapa assistida nesta V1.

---

## 12. WhatsApp — 20 variações para lançamento

**Contexto:** uso preferencial em 29/05/2026, véspera do lançamento.  
**Canal:** WhatsApp  
**Modo:** assistido pelo corretor  
**CTA padrão:** pedir permissão para enviar material, plantas ou organizar horário.  
**Assinatura:** aplicar a assinatura dinâmica obrigatória ao final.

### WA-01 — sem emoji

```text
Olá, {{nome_lead}}, tudo bem?

Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado na elegância dos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².

Posso te enviar o material com plantas e detalhes do evento?
```

### WA-02 — sem emoji

```text
{{nome_lead}}, tudo bem?

Amanhã acontece o lançamento do Château Jardin, um projeto de alto padrão no novo eixo Cidade Jardim.

O empreendimento une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e metragens amplas de 185 m² a 355 m².

Quer que eu te envie as plantas para avaliar com calma?
```

### WA-03 — com emoji discreto

```text
Olá, {{nome_lead}}.

Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400. 📍

É um projeto Tegra e Exto, com inspiração nos jardins franceses, lazer de alto padrão e opções de 185 m², 215 m², 248 m² e 355 m². 📐

Posso te mandar um resumo com as plantas?
```

### WA-04 — sem emoji

```text
{{nome_lead}}, amanhã teremos o lançamento do Château Jardin.

É um projeto inspirado no clássico, nos jardins franceses e em uma forma mais elegante de viver, no novo eixo Cidade Jardim.

As opções contemplam 185 m², 215 m², 248 m² e 355 m².

Faz sentido eu te enviar o material agora?
```

### WA-05 — sem emoji

```text
Olá, {{nome_lead}}, tudo bem?

Amanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.

O projeto reúne arquitetura clássica, paisagismo internacional EDSA, lazer de perfil private club e plantas generosas de 185 m² a 355 m².

Quer receber as informações iniciais?
```

### WA-06 — com emoji discreto

```text
{{nome_lead}}, estou organizando os atendimentos do lançamento do Château Jardin, que acontece amanhã na Rua Ministro Nelson Hungria, 400. 🗓️

O empreendimento tem inspiração na elegância dos jardins franceses e plantas de 185 m², 215 m², 248 m² e 355 m². 🌿

Posso te mandar as opções?
```

### WA-07 — sem emoji

```text
Olá, {{nome_lead}}.

Amanhã é o lançamento do Château Jardin, projeto Tegra e Exto no novo eixo Cidade Jardim.

Um refúgio urbano com arquitetura clássica, paisagismo internacional EDSA, quadra de tênis de saibro, padel, piscina coberta e metragens de 185 m² a 355 m².

Posso te enviar o material?
```

### WA-08 — sem emoji

```text
{{nome_lead}}, tudo bem?

Amanhã teremos o evento de lançamento do Château Jardin.

O projeto foi pensado para quem busca alto padrão, elegância atemporal e plantas amplas, com opções de 185 m², 215 m², 248 m² e 355 m².

O evento será na Rua Ministro Nelson Hungria, 400.

Quer que eu te envie os detalhes?
```

### WA-09 — com emoji discreto

```text
Olá, {{nome_lead}}.

O Château Jardin será lançado amanhã no novo eixo Cidade Jardim.

É um projeto com inspiração clássica, atmosfera de jardins franceses, lazer sofisticado e assinatura Tegra e Exto. 🏛️

As plantas contemplam 185 m², 215 m², 248 m² e 355 m². 📐

Posso te mandar o material?
```

### WA-10 — sem emoji

```text
{{nome_lead}}, passando rapidamente para te apresentar o Château Jardin, que terá evento de lançamento amanhã.

É um projeto de alto padrão na Rua Ministro Nelson Hungria, 400, com arquitetura clássica, paisagismo internacional e metragens amplas de 185 m² a 355 m².

Posso te enviar as plantas?
```

### WA-11 — sem emoji

```text
Olá, {{nome_lead}}, tudo bem?

Amanhã será o lançamento do Château Jardin, um projeto que une o clássico e o contemporâneo no novo eixo Cidade Jardim.

Inspirado na elegância dos jardins franceses, traz plantas de 185 m², 215 m², 248 m² e 355 m².

Quer conhecer o material?
```

### WA-12 — com emoji discreto

```text
{{nome_lead}}, amanhã teremos a apresentação do Château Jardin, empreendimento Tegra e Exto com projeto internacional EDSA.

A proposta combina jardins, lazer de alto padrão, arquitetura clássica e unidades amplas de 185 m² a 355 m². 🌿

Posso te enviar as informações pelo WhatsApp?
```

### WA-13 — sem emoji

```text
Olá, {{nome_lead}}.

O lançamento do Château Jardin será amanhã, na Rua Ministro Nelson Hungria, 400.

É um projeto no novo eixo Cidade Jardim, com inspiração clássica, paisagismo sofisticado e opções de 185 m², 215 m², 248 m² e 355 m².

Posso te mandar as plantas e diferenciais?
```

### WA-14 — sem emoji

```text
{{nome_lead}}, tudo bem?

Estou te chamando porque amanhã será o lançamento do Château Jardin.

O projeto tem uma proposta elegante, inspirada no clássico e nos jardins franceses, com lazer completo e metragens de 185 m² a 355 m².

Faz sentido eu te enviar o material?
```

### WA-15 — sem emoji

```text
Olá, {{nome_lead}}.

Amanhã acontece o evento de lançamento do Château Jardin, realização Tegra e Exto.

O empreendimento fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².

Quer que eu te envie os detalhes?
```

### WA-16 — com emoji discreto

```text
{{nome_lead}}, amanhã será o lançamento do Château Jardin, um projeto residencial de alto padrão na Rua Ministro Nelson Hungria, 400. 📍

Ele combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e lazer com tênis, padel, piscina coberta e wellness.

Posso te mandar o material?
```

### WA-17 — sem emoji

```text
Olá, {{nome_lead}}, tudo bem?

O Château Jardin será lançado amanhã e estou organizando os atendimentos por horário.

O projeto tem plantas de 185 m², 215 m², 248 m² e 355 m², com lazer sofisticado e proposta de refúgio urbano no novo eixo Cidade Jardim.

Posso te enviar as plantas?
```

### WA-18 — com emoji discreto

```text
{{nome_lead}}, passando para te avisar sobre o lançamento do Château Jardin amanhã.

É um projeto Tegra e Exto, com paisagismo internacional EDSA, inspiração nos jardins franceses e uma estrutura de lazer diferenciada: tênis de saibro, padel, piscina coberta e wellness. 🌿

Posso te enviar um resumo?
```

### WA-19 — sem emoji

```text
Olá, {{nome_lead}}.

Amanhã teremos o lançamento do Château Jardin, um projeto que nasce como um novo marco residencial no eixo Cidade Jardim.

São plantas amplas de 185 m², 215 m², 248 m² e 355 m², com arquitetura clássica e lazer de alto padrão.

Quer receber o material?
```

### WA-20 — sem emoji

```text
{{nome_lead}}, tudo bem?

Amanhã será o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

Um projeto de alto padrão inspirado no clássico, nos jardins franceses e em uma experiência residencial mais reservada.

Temos opções de 185 m² a 355 m².

Posso te mandar as informações?
```

---

## 13. Ligação — 10 scripts para Discador

**Canal:** Ligação  
**Modo:** script orientativo, não leitura robótica.  
**Fechamento obrigatório:** endereço + solicitação do corretor na recepção.

### CALL-01

```text
Oi, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}.

Estou te ligando rapidamente porque amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

É um projeto Tegra e Exto no novo eixo Cidade Jardim, inspirado no clássico e nos jardins franceses, com plantas de 185 m², 215 m², 248 m² e 355 m².

Faz sentido eu te enviar o material e verificar um horário para você conhecer?

Se for ao evento, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente.
```

### CALL-02

```text
{{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}.

Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão no novo eixo Cidade Jardim.

O projeto une arquitetura clássica com olhar contemporâneo, paisagismo internacional EDSA e lazer com tênis de saibro, padel, piscina coberta e wellness.

Posso te mandar as plantas e entender se alguma metragem faz sentido para você?

O evento será na Rua Ministro Nelson Hungria, 400. Ao chegar, solicite por {{nome_corretor}} na recepção.
```

### CALL-03

```text
Oi, {{nome_lead}}, aqui é {{nome_corretor}}.

Vou ser breve: amanhã acontece o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

É um projeto sofisticado, com inspiração nos jardins franceses, plantas amplas de 185 m² a 355 m² e uma proposta residencial reservada.

Você busca algo nesse perfil ou prefere apenas receber o material para avaliar?

Se decidir conhecer, solicite por {{nome_corretor}} na recepção.
```

### CALL-04

```text
{{nome_lead}}, tudo bem?

Estou entrando em contato porque amanhã será o evento de lançamento do Château Jardin.

O projeto tem realização Tegra e Exto, fica no novo eixo Cidade Jardim e traz opções de 185 m², 215 m², 248 m² e 355 m².

Posso te enviar um resumo com plantas e principais diferenciais?

O endereço do evento é Rua Ministro Nelson Hungria, 400. Ao chegar, é importante solicitar por {{nome_corretor}} na recepção.
```

### CALL-05

```text
Oi, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}.

Amanhã vamos apresentar o Château Jardin, um projeto com arquitetura clássica, inspiração nos jardins franceses e paisagismo internacional.

É um produto para quem busca alto padrão, conforto e plantas generosas.

Você gostaria de conhecer as opções ou prefere que eu envie primeiro pelo WhatsApp?

Se for ao lançamento, o evento será na Rua Ministro Nelson Hungria, 400. Solicite por {{nome_corretor}} na recepção.
```

### CALL-06

```text
{{nome_lead}}, tudo bem?

Estou te ligando porque amanhã teremos o lançamento do Château Jardin, um projeto no novo eixo Cidade Jardim com lazer de perfil private club: tênis de saibro, padel, piscina coberta, wellness e áreas sociais completas.

As metragens vão de 185 m² a 355 m².

Posso te passar o material?

Ao chegar ao evento na Rua Ministro Nelson Hungria, 400, solicite por {{nome_corretor}} na recepção.
```

### CALL-07

```text
Oi, {{nome_lead}}, aqui é {{nome_corretor}}.

Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

O projeto tem uma proposta elegante: arquitetura clássica, jardins, serviços de alto padrão e plantas amplas.

Queria entender se você está buscando imóvel para morar, investir ou apenas avaliando oportunidades nesse perfil.

Se fizer sentido visitar, peça por {{nome_corretor}} na recepção para que eu possa te receber.
```

### CALL-08

```text
{{nome_lead}}, tudo bem? Vou falar rapidinho.

Amanhã teremos o lançamento do Château Jardin, realização Tegra e Exto.

O empreendimento foi pensado como um refúgio urbano no novo eixo Cidade Jardim, com metragens de 185 m², 215 m², 248 m² e 355 m².

Posso te enviar as plantas para você avaliar com calma?

O evento será na Rua Ministro Nelson Hungria, 400. Ao chegar, solicite por {{nome_corretor}} na recepção.
```

### CALL-09

```text
Oi, {{nome_lead}}, aqui é {{nome_corretor}}.

Amanhã acontece o evento de lançamento do Château Jardin.

É um projeto com inspiração clássica, atmosfera de jardins franceses, paisagismo EDSA e uma estrutura de lazer diferenciada.

Se fizer sentido para você, posso te mandar o material e verificar um horário de apresentação.

No evento, por gentileza, solicite por {{nome_corretor}} na recepção.
```

### CALL-10

```text
{{nome_lead}}, tudo bem?

Estou te ligando sobre o Château Jardin, que será lançado amanhã na Rua Ministro Nelson Hungria, 400.

É um projeto de alto padrão com opções de 185 m² a 355 m², lazer completo e proposta residencial sofisticada.

Você teria interesse em receber as informações iniciais ou prefere agendar para conhecer presencialmente?

Se for ao evento, solicite por {{nome_corretor}} na recepção.
```

---

## 14. E-mail — 10 variações

**Canal:** E-mail  
**Modo:** executivo, sem emoji.  
**Assinatura:** aplicar assinatura dinâmica obrigatória ao final.

### EMAIL-01

**Assunto:** Château Jardin | Lançamento amanhã

```text
Olá, {{nome_lead}}, tudo bem?

Amanhã será o lançamento do Château Jardin, projeto de alto padrão no novo eixo Cidade Jardim, com realização Tegra e Exto.

Inspirado na arquitetura clássica e na elegância dos jardins franceses, o empreendimento reúne paisagismo internacional EDSA, lazer sofisticado e plantas amplas de 185 m², 215 m², 248 m² e 355 m².

O evento será na Rua Ministro Nelson Hungria, 400.

Posso te enviar as plantas e verificar um melhor horário para apresentação?
```

### EMAIL-02

**Assunto:** Château Jardin | Novo marco no eixo Cidade Jardim

```text
Olá, {{nome_lead}}.

Estou compartilhando o Château Jardin, lançamento que será apresentado amanhã na Rua Ministro Nelson Hungria, 400.

O projeto une arquitetura clássica, olhar contemporâneo, inspiração nos jardins franceses e paisagismo internacional assinado pela EDSA.

As opções contemplam plantas de 185 m², 215 m², 248 m² e 355 m².

Caso faça sentido para você, posso encaminhar o material completo e organizar uma visita.
```

### EMAIL-03

**Assunto:** Amanhã | Evento de lançamento Château Jardin

```text
Olá, {{nome_lead}}, tudo bem?

Amanhã acontece o evento de lançamento do Château Jardin, empreendimento Tegra e Exto no novo eixo Cidade Jardim.

O projeto foi pensado como um refúgio urbano sofisticado, com inspiração clássica, atmosfera de jardins franceses, lazer de alto padrão, quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.

Há opções de 185 m², 215 m², 248 m² e 355 m².

Posso te enviar plantas e detalhes para avaliação?
```

### EMAIL-04

**Assunto:** Château Jardin | Plantas de 185 m² a 355 m²

```text
Olá, {{nome_lead}}.

Amanhã será o lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

O empreendimento traz uma proposta residencial elegante, com arquitetura clássica, paisagismo internacional EDSA e inspiração nos jardins franceses.

As plantas incluem opções de 185 m², 215 m², 248 m² e 355 m², voltadas a quem busca alto padrão, conforto e localização estratégica no eixo Cidade Jardim.

Posso te enviar o material completo?
```

### EMAIL-05

**Assunto:** Convite | Château Jardin

```text
Olá, {{nome_lead}}, tudo bem?

Gostaria de te apresentar o Château Jardin, lançamento de alto padrão que será apresentado amanhã no novo eixo Cidade Jardim.

Com realização Tegra e Exto, o projeto combina arquitetura clássica, inspiração nos jardins franceses, paisagismo internacional e uma estrutura de lazer com perfil de private club.

O evento será na Rua Ministro Nelson Hungria, 400.

Se fizer sentido, posso te enviar as plantas e detalhes das metragens disponíveis.
```

### EMAIL-06

**Assunto:** Château Jardin | Evento na Rua Ministro Nelson Hungria, 400

```text
Olá, {{nome_lead}}.

Amanhã teremos o lançamento do Château Jardin, um empreendimento de alto padrão na Rua Ministro Nelson Hungria, 400.

O projeto reúne a assinatura Tegra e Exto, paisagismo internacional EDSA, inspiração clássica e metragens amplas de 185 m² a 355 m².

A proposta é oferecer uma experiência residencial sofisticada, com lazer completo e serviços pensados para o dia a dia.

Posso te enviar o material e verificar um horário de apresentação?
```

### EMAIL-07

**Assunto:** Château Jardin | Alto padrão no novo eixo Cidade Jardim

```text
Olá, {{nome_lead}}, tudo bem?

O Château Jardin será lançado amanhã e nasce como uma proposta residencial sofisticada no novo eixo Cidade Jardim.

Inspirado no clássico e na elegância dos jardins franceses, o projeto conta com paisagismo internacional, quadra de tênis de saibro, padel, piscina coberta, wellness e plantas de 185 m², 215 m², 248 m² e 355 m².

Caso queira, posso encaminhar as plantas e principais diferenciais.
```

### EMAIL-08

**Assunto:** Conheça o Château Jardin

```text
Olá, {{nome_lead}}.

Amanhã será apresentado o Château Jardin, realização Tegra e Exto no novo eixo Cidade Jardim.

O empreendimento foi concebido com arquitetura clássica, leitura contemporânea e inspiração nos jardins franceses, trazendo metragens amplas e lazer completo para uma experiência residencial reservada.

O evento ocorrerá na Rua Ministro Nelson Hungria, 400.

Posso te enviar o material completo com plantas e diferenciais?
```

### EMAIL-09

**Assunto:** Château Jardin | Lançamento de alto padrão

```text
Olá, {{nome_lead}}, tudo bem?

Estou te enviando o Château Jardin, lançamento que será apresentado amanhã.

O projeto une sofisticação, inspiração clássica, paisagismo internacional EDSA e lazer de alto padrão, com quadra de tênis de saibro, quadra de padel, piscina coberta e wellness.

As plantas contemplam metragens de 185 m², 215 m², 248 m² e 355 m².

Fico à disposição para te enviar o material e organizar uma apresentação.
```

### EMAIL-10

**Assunto:** Château Jardin | Apresentação amanhã

```text
Olá, {{nome_lead}}.

Amanhã teremos o evento de lançamento do Château Jardin, na Rua Ministro Nelson Hungria, 400.

É um projeto Tegra e Exto, no novo eixo Cidade Jardim, inspirado na elegância clássica e nos jardins franceses, com paisagismo internacional e plantas amplas de 185 m² a 355 m².

Se fizer sentido para você, posso enviar o material com plantas, metragens e detalhes do empreendimento.
```

---

## 15. Situações do lead previstas para expansão

A V1 de conteúdo acima cobre principalmente o contexto:

```text
situação = convite_lancamento
fase = primeira_mensagem
objetivo = abertura/envio_info/visita
```

Situações futuras a documentar em fases posteriores:

- pediu plantas;
- pediu valores;
- pediu material;
- não respondeu;
- respondeu com interesse;
- quer levar família;
- está comparando outro projeto;
- visitou plantão;
- pós-visita;
- pediu retorno em outra data;
- objeção de preço;
- objeção de fluxo;
- fechamento elegante.

---

## 16. Feedback obrigatório pós-ação

Após usar uma mensagem/script, a PME deve permitir registrar feedback.

Feedbacks mínimos sugeridos:

```text
enviado_whatsapp
ligacao_atendida
ligacao_nao_atendida
email_enviado
cliente_respondeu
cliente_pediu_material
cliente_pediu_plantas
cliente_pediu_valores
cliente_quer_visitar
cliente_sem_interesse
cliente_pediu_retorno
cliente_bloqueou
numero_sem_whatsapp
```

Objetivo do feedback:

- evitar repetição indevida;
- orientar próxima mensagem;
- medir performance das variações;
- alimentar relatórios;
- alimentar futura IA de recomendação;
- respeitar rejeição/opt-out.

---

## 17. Critérios para futura implementação

Antes de transformar este documento em seed, frontend, banco ou RPC, a próxima fase deve validar:

```text
1. Branch de trabalho correta.
2. Estado atual do schema Supabase.
3. Tabelas PME existentes.
4. Estrutura atual de templates/mensagens.
5. Estrutura atual de usage tracking.
6. Regras RLS existentes.
7. Permissões atuais por tenant/empresa/corretor.
8. Como o Discador/Acelerador carrega mensagens hoje.
9. Se o canal WhatsApp será deep link, WABA template ou envio assistido.
10. Como registrar feedback pós-ação.
```

Sem essa validação, não criar migration, seed, RPC ou alteração de frontend.

---

## 18. Critério de aceite desta fase R0

Esta fase documental é aceita se:

- o arquivo documentar o módulo Empreendimentos;
- a PME atual for preservada;
- a nova ordem de escolha estiver clara;
- o Château Jardin estiver documentado como primeiro empreendimento;
- o evento 30/05/2026 estiver documentado;
- o endereço estiver presente;
- os termos bloqueados estiverem explícitos;
- a assinatura dinâmica estiver definida;
- houver 20 variações de WhatsApp;
- houver 10 scripts de ligação;
- houver 10 variações de e-mail;
- não houver alteração de banco, seed, RLS, frontend, Discador ou RPC.

---

## 19. Critério de bloqueio

Bloquear a fase se houver:

- uso de termo proibido;
- promessa de desconto;
- promessa de condição garantida;
- promessa de disponibilidade;
- preço fechado sem validação;
- exposição de bastidor comercial;
- tentativa de automatizar disparo sem validação;
- alteração técnica fora deste arquivo;
- mistura de documentação com migration/seed/frontend.

---

## 20. Handoff

### O que mudou

Foi documentada a primeira versão do módulo contextual **Empreendimentos** da PME, usando o Château Jardin como primeiro caso.

### O que não mudou

Não houve alteração em:

- Supabase;
- migrations;
- RLS;
- grants;
- RPCs;
- seed;
- frontend;
- Discador;
- Central atual;
- motor da PME.

### Próximo passo recomendado

Após aprovação deste documento:

```text
Gate 1 técnico — validar estrutura real da PME existente antes de qualquer implementação.
```

Depois, em fase separada:

```text
Criar contrato de implementação do módulo Empreendimentos no Acelerador/Discador, com diff proposto antes de qualquer alteração.
```

---

## 21. Status final

```text
PME — Empreendimentos — Château Jardin — Lançamento v1
Status: documentado para validação.
Risco: R0 documental.
Sem alteração operacional aplicada.
```
