# Power Message Engine — FECH.AI

## Status

**Versão:** v1.0 — especificação funcional inicial  
**Módulo:** Central de Mensagens / Aceleração Operacional / Oferta Ativa  
**Projeto:** FECH.AI  
**Tipo:** Documento de produto + regra operacional + base para implementação  
**Escopo desta versão:** documentação, arquitetura funcional, taxonomia de mensagens, regras de uso e critérios de aceite.

---

## 1. Objetivo do módulo

O **Power Message Engine** é o motor de mensagens do FECH.AI responsável por orientar, acelerar e padronizar a abordagem comercial dos corretores sem transformar a operação em um labirinto operacional.

A ideia central é simples:

> O corretor não deve precisar pensar em qual mensagem enviar, em qual ordem abordar, o que falar na ligação ou como retomar um lead. O sistema deve sugerir, organizar e registrar tudo com governança.

Este módulo deve atender três necessidades principais:

1. **Acelerar a operação ativa** de WhatsApp, ligação e e-mail.
2. **Padronizar a comunicação comercial** sem deixar as mensagens robóticas.
3. **Evitar bagunça operacional**, duplicidade, excesso de telas, dispersão de templates e perda de histórico.

---

## 2. Princípios obrigatórios

### 2.1 Simplicidade operacional

A interface deve ser fácil para corretores com pouca familiaridade tecnológica.

O fluxo ideal precisa funcionar assim:

1. O corretor entra na tela do lead.
2. Clica em **Aceleração Operacional** ou **Oferta Ativa Acelerada**.
3. Escolhe a sequência de canais: WhatsApp, ligação e/ou e-mail.
4. Informa se já falou ou não com o cliente.
5. O sistema sugere a próxima ação.
6. O corretor envia, liga, registra feedback e avança.

Nada de menu com 14 ramificações, 27 botões e um Minotauro no corredor.

### 2.2 Governança de mensagens

A randomização de mensagens deve ser usada para:

- reduzir repetição visual;
- humanizar comunicação;
- adaptar tom por origem e temperatura do lead;
- evitar que todos os corretores pareçam o mesmo robô de terno.

A randomização **não deve** ser tratada como mecanismo para burlar políticas de canal, limites de envio ou bloqueios. O produto deve operar com consentimento, opt-out, limites, rastreabilidade e higiene de base.

### 2.3 Multicanal sem bagunça

O motor deve suportar:

- WhatsApp;
- ligação;
- e-mail;
- histórico de tentativas;
- scripts de ligação;
- sugestão da próxima melhor ação;
- templates por contexto.

Mas a tela do corretor deve continuar simples.

### 2.4 Multitenancy obrigatório

Todas as mensagens, templates, configurações e históricos devem respeitar o tenant.

Nenhuma empresa deve enxergar templates, campanhas, corretores, leads ou histórico de outra empresa.

---

## 3. Nomes funcionais do módulo

O módulo pode aparecer no produto com um destes nomes:

- **Aceleração Operacional** — nome mais corporativo.
- **Oferta Ativa Acelerada** — nome mais comercial.
- **Power Message Engine** — nome técnico interno.
- **Central de Mensagens** — área administrativa e de configuração.

Recomendação:

- Para o corretor: **Oferta Ativa Acelerada**.
- Para gestor/admin: **Central de Mensagens**.
- Para documentação técnica: **Power Message Engine**.

---

## 4. Tipos de lead suportados na v1

O motor deve tratar mensagens de forma diferente conforme a origem e temperatura do lead.

### 4.1 Lead quente

Lead que demonstrou intenção recente.

Exemplos:

- veio de Meta Ads;
- veio de Google Ads;
- preencheu formulário;
- chamou no WhatsApp;
- pediu valores;
- pediu simulação;
- interagiu recentemente.

Tom recomendado:

- direto;
- consultivo;
- rápido;
- com CTA claro;
- sem excesso de explicação.

### 4.2 Lista fria

Lead vindo de base fria, lista comprada, mailing antigo ou contato ainda não qualificado.

Tom recomendado:

- mais cuidadoso;
- menos invasivo;
- com abertura educada;
- sem pressupor interesse imediato;
- com opção clara de não continuidade.

### 4.3 Lista quente / visitou plantão

Lead que já teve algum contato presencial ou demonstrou interesse forte.

Exemplos:

- visitou plantão;
- falou com corretor;
- recebeu tabela;
- pediu proposta;
- comparou unidades;
- está em negociação.

Tom recomendado:

- mais objetivo;
- com retomada de contexto;
- com senso de continuidade;
- com foco em próxima decisão.

---

## 5. Fases de abordagem

A v1 deve suportar no mínimo quatro fases por tipo de lead.

### 5.1 Primeira mensagem

Objetivo:

- abrir contato;
- se apresentar;
- contextualizar o motivo do contato;
- gerar resposta.

### 5.2 Segunda mensagem

Objetivo:

- retomar sem parecer insistente;
- reforçar benefício;
- oferecer caminho simples.

### 5.3 Terceira mensagem

Objetivo:

- criar avanço;
- tentar ligação, visita, simulação ou envio de material;
- identificar se ainda existe interesse.

### 5.4 Mensagem final

Objetivo:

- encerrar o ciclo com elegância;
- deixar porta aberta;
- reduzir ruído na operação;
- evitar perseguição comercial.

---

## 6. Quantidade mínima de mensagens

Para WhatsApp, o motor deve possuir pelo menos:

| Tipo de lead | Fase | Quantidade mínima |
|---|---:|---:|
| Lead quente | Primeira mensagem | 10 |
| Lead quente | Segunda mensagem | 10 |
| Lead quente | Terceira mensagem | 10 |
| Lead quente | Mensagem final | 10 |
| Lista fria | Primeira mensagem | 10 |
| Lista fria | Segunda mensagem | 10 |
| Lista fria | Terceira mensagem | 10 |
| Lista fria | Mensagem final | 10 |
| Lista quente / visitou plantão | Primeira mensagem | 10 |
| Lista quente / visitou plantão | Segunda mensagem | 10 |
| Lista quente / visitou plantão | Terceira mensagem | 10 |
| Lista quente / visitou plantão | Mensagem final | 10 |

Total mínimo para WhatsApp na v1:

> **120 mensagens base**.

Essas mensagens devem usar variáveis dinâmicas e não devem ser simplesmente cópias com pequenas trocas de palavra.

---

## 7. Variáveis dinâmicas obrigatórias

O sistema deve suportar variáveis no template.

### 7.1 Variáveis de lead

- `{{nome_lead}}`
- `{{telefone_lead}}`
- `{{origem_lead}}`
- `{{temperatura_lead}}`
- `{{ultimo_interesse}}`
- `{{data_ultimo_contato}}`

### 7.2 Variáveis de corretor

- `{{nome_corretor}}`
- `{{telefone_corretor}}`
- `{{empresa_corretor}}`
- `{{apelido_corretor}}`

### 7.3 Variáveis de empreendimento

- `{{nome_empreendimento}}`
- `{{bairro_empreendimento}}`
- `{{cidade_empreendimento}}`
- `{{tipo_unidade}}`
- `{{metragem}}`
- `{{dormitorios}}`
- `{{vagas}}`
- `{{link_material}}`
- `{{link_whatsapp}}`
- `{{link_agendamento}}`

### 7.4 Variáveis comerciais

- `{{condicao_comercial}}`
- `{{prazo_condicao}}`
- `{{chamada_principal}}`
- `{{cta_principal}}`

---

## 8. Regras de randomização controlada

A escolha de template deve seguir regras claras.

### 8.1 Entrada mínima para seleção

O motor deve receber:

- `tenant_id`
- `lead_id`
- `corretor_id`
- `canal`
- `tipo_lead`
- `fase`
- `status_relacionamento`
- `empreendimento_id`, quando houver

### 8.2 Filtros antes de sortear

Antes de selecionar uma mensagem, o motor deve filtrar por:

1. tenant correto;
2. canal correto;
3. tipo de lead correto;
4. fase correta;
5. template ativo;
6. template compatível com origem;
7. template compatível com o empreendimento, se houver;
8. template ainda não usado recentemente para o mesmo lead.

### 8.3 Pesos de uso

Cada template pode ter peso.

Exemplo:

- peso 1: pouco usado;
- peso 3: uso normal;
- peso 5: template prioritário.

O sorteio deve considerar peso, mas também evitar repetição excessiva.

### 8.4 Bloqueio de repetição

O mesmo template não deve ser enviado repetidamente para o mesmo lead dentro do mesmo ciclo.

Regra mínima:

> Não repetir o mesmo `template_id` para o mesmo `lead_id` dentro da mesma campanha e fase.

---

## 9. Piloto automático

O **Piloto Automático** é o modo em que o sistema sugere ou prepara a próxima melhor ação automaticamente, com base no estado do lead.

### 9.1 O que ele faz na v1

- identifica a próxima fase da abordagem;
- sugere mensagem de WhatsApp;
- sugere roteiro de ligação;
- sugere e-mail quando aplicável;
- registra tentativa;
- espera feedback do corretor;
- não avança sem registro mínimo.

### 9.2 O que ele não deve fazer na v1

- disparar mensagens em massa sem controle;
- ignorar opt-out;
- insistir indefinidamente;
- misturar leads de campanhas diferentes;
- enviar mensagem sem rastreabilidade;
- alterar feedback comercial sem ação humana.

---

## 10. Oferta Ativa Acelerada

A **Oferta Ativa Acelerada** é o modo lúdico e simplificado para o corretor trabalhar um lead com poucos cliques.

### 10.1 Fluxo esperado

1. Corretor abre o lead.
2. Clica em **Oferta Ativa Acelerada**.
3. Escolhe sequência de canais:
   - WhatsApp primeiro;
   - ligação primeiro;
   - e-mail primeiro;
   - ou combinação personalizada.
4. Informa se já falou com o cliente:
   - ainda não falei;
   - já falei;
   - cliente visitou plantão;
   - cliente pediu proposta;
   - cliente sumiu.
5. Sistema escolhe template adequado.
6. Corretor envia ou copia a mensagem.
7. Sistema registra tentativa.
8. Corretor informa resultado.
9. Sistema sugere próxima etapa.

### 10.2 Botões mínimos

- **Enviar WhatsApp**
- **Copiar mensagem**
- **Ligar agora**
- **Gerar e-mail**
- **Cliente respondeu**
- **Não respondeu**
- **Agendar retorno**
- **Encerrar ciclo**

---

## 11. Scripts de ligação

O motor deve entregar scripts de ligação para o corretor não se perder durante a conversa.

Cada script deve ter:

- abertura;
- validação de contexto;
- pergunta de qualificação;
- oferta de próximo passo;
- tratamento de objeção;
- fechamento;
- instrução de feedback.

Exemplo de estrutura:

```text
Abertura:
Olá, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}} da {{empresa_corretor}}.
Estou te ligando porque vi seu interesse no {{nome_empreendimento}}.

Contexto:
Queria entender rapidamente se você busca moradia, investimento ou está comparando opções na região.

Avanço:
Com base nisso, eu consigo te passar uma opção mais precisa e evitar te mandar informação solta.

Fechamento:
Posso te encaminhar agora uma simulação ou prefere que eu te mostre as melhores unidades disponíveis?
```

---

## 12. Estados operacionais do lead

O motor deve considerar pelo menos estes estados:

- `novo`
- `primeira_mensagem_enviada`
- `segunda_mensagem_enviada`
- `terceira_mensagem_enviada`
- `mensagem_final_enviada`
- `respondeu`
- `ligacao_realizada`
- `nao_atendeu`
- `agendou_visita`
- `pediu_simulacao`
- `sem_interesse`
- `opt_out`
- `encerrado`

---

## 13. Integração com feedback existente

O Power Message Engine não deve substituir o feedback comercial do FECH.AI.

Ele deve complementar o funil existente.

Exemplos:

- se o corretor enviar mensagem, registrar tentativa;
- se o cliente responder, atualizar estado operacional;
- se agendar visita, acionar feedback comercial correspondente;
- se pedir para parar, marcar opt-out;
- se telefone for inválido, marcar problema cadastral.

---

## 14. Modelo de dados sugerido

A modelagem detalhada está no arquivo:

- [`data-model.md`](./data-model.md)

Tabelas sugeridas:

- `message_templates`
- `message_template_versions`
- `message_sequences`
- `message_sequence_steps`
- `message_attempts`
- `lead_message_state`
- `call_scripts`
- `channel_preferences`
- `message_opt_outs`

---

## 15. Arquivos deste módulo

- [`README.md`](./README.md) — visão geral e especificação funcional.
- [`message-taxonomy.md`](./message-taxonomy.md) — taxonomia de canais, tipos de lead, fases e estados.
- [`whatsapp-message-pools.md`](./whatsapp-message-pools.md) — estrutura dos pools de WhatsApp e exemplos iniciais.
- [`call-scripts.md`](./call-scripts.md) — estrutura dos scripts de ligação.
- [`data-model.md`](./data-model.md) — modelo de dados sugerido.
- [`implementation-checklist.md`](./implementation-checklist.md) — checklist de implementação e aceite.

---

## 16. Critérios de aceite da v1

A v1 só deve ser considerada pronta quando:

1. existir tela de Central de Mensagens para gestor/admin;
2. existir botão de Oferta Ativa Acelerada na tela do lead;
3. existir seleção de canal e sequência;
4. existir pelo menos 120 templates base de WhatsApp cadastráveis;
5. existir seleção randomizada controlada;
6. existir histórico de mensagens/tentativas por lead;
7. existir opt-out funcional;
8. existir script de ligação associado ao contexto;
9. existir vínculo com `tenant_id` em todas as tabelas;
10. existir regra impedindo acesso cross-tenant;
11. existir log de quem enviou, quando enviou e qual template foi usado;
12. existir feedback obrigatório para avançar ciclo.

---

## 17. Fora de escopo da v1

Não implementar na v1:

- disparador massivo irrestrito;
- automação sem controle humano;
- integração profunda com WABA sem desenho específico;
- IA escrevendo mensagens livres sem aprovação;
- mudança automática de funil sem regra;
- reestruturação do motor atual do FECH.AI;
- alteração de RPCs comerciais existentes sem aprovação.

---

## 18. Diretriz para IA implementadora

Ao implementar este módulo:

1. Não recriar arquitetura existente.
2. Não mexer no motor principal sem autorização explícita.
3. Não usar placeholders de banco, rotas ou tabelas inexistentes como se fossem reais.
4. Antes de alterar código, mapear estrutura atual do repositório.
5. Preservar multitenancy.
6. Implementar primeiro documentação, depois schema, depois UI, depois automação.
7. Criar PRs pequenos e auditáveis.
8. Priorizar fluxo simples para corretor.
9. Toda mensagem deve ser rastreável.
10. Toda automação deve ter limite, opt-out e histórico.

---

## 19. Roadmap pós-v1

### v1.1

- biblioteca completa de 120 mensagens;
- editor visual de templates;
- preview com variáveis preenchidas;
- tags por empreendimento.

### v1.2

- recomendação de próxima melhor ação;
- ranking de mensagens por resposta;
- métricas por template.

### v1.3

- integração com e-mail;
- múltiplas cadências por origem;
- jornada por campanha.

### v1.4

- integração WABA planejada;
- templates aprovados;
- camada de compliance por canal.

### v2.0

- IA assistida para sugestão de abordagem;
- aprendizado com performance real;
- motor de jornada omnichannel.
