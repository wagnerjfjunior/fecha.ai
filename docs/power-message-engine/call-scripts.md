# Power Message Engine — Scripts de Ligação

## 1. Objetivo

Dar suporte ao corretor durante chamadas para que ele não se atrapalhe, não esqueça pontos importantes e consiga conduzir a conversa com naturalidade.

O script não deve ser um texto robótico. Deve ser um roteiro por blocos.

---

## 2. Estrutura padrão de script

### 2.1 Abertura

Objetivo: iniciar sem parecer telemarketing genérico.

Campos:

- saudação;
- nome do cliente;
- nome do corretor;
- empresa/incorporadora;
- motivo do contato.

### 2.2 Contexto

Objetivo: explicar por que está ligando.

Exemplos de contexto:

- cliente pediu informações;
- cliente veio de anúncio;
- cliente visitou plantão;
- cliente estava em uma lista de interessados;
- cliente já conversou antes;
- cliente pediu simulação.

### 2.3 Pergunta inicial

Objetivo: tirar o cliente do modo defensivo.

Exemplos:

- “Você consegue falar rapidinho agora?”
- “Faz sentido eu te explicar em 30 segundos?”
- “Você ainda está avaliando imóvel nessa região?”

### 2.4 Qualificação

Objetivo: entender perfil.

Perguntas:

- procura para morar ou investir?
- qual região faz mais sentido?
- qual metragem está avaliando?
- tem prazo para mudança?
- pretende financiar?
- já visitou algum projeto?
- quem decide junto com você?

### 2.5 Gancho comercial

Objetivo: conectar o produto ao perfil.

Deve variar conforme:

- empreendimento;
- perfil familiar;
- investidor;
- alto padrão;
- primeira compra;
- mudança de fase;
- proximidade com região desejada.

### 2.6 Fechamento da ligação

Objetivo: definir próximo passo claro.

Possibilidades:

- enviar material no WhatsApp;
- agendar visita;
- fazer simulação;
- retornar em outro horário;
- encerrar contato;
- classificar sem interesse.

### 2.7 Feedback obrigatório

Após a ligação, registrar:

- atendeu;
- não atendeu;
- caixa postal;
- número errado;
- pediu retorno;
- interessado;
- sem interesse;
- agendou visita;
- enviar informações;
- fazer simulação;
- proposta.

---

## 3. Tipos de script

### 3.1 Lead quente

Tom: rápido, contextual, objetivo.

Foco:

- responder interesse recente;
- não deixar esfriar;
- avançar para WhatsApp, simulação ou visita.

### 3.2 Lista fria

Tom: respeitoso, permission-based.

Foco:

- abrir conversa;
- validar se há interesse;
- não pressionar.

### 3.3 Lista quente

Tom: retomada com contexto.

Foco:

- lembrar contato anterior;
- atualizar oportunidade;
- propor próximo passo.

### 3.4 Pós-plantão

Tom: consultivo e mais próximo.

Foco:

- entender percepção da visita;
- objeções;
- comparação;
- proposta;
- retorno com decisores.

---

## 4. Script-base — Lead quente

```txt
Oi, {{nome_lead}}, tudo bem?
Aqui é {{nome_corretor}}, da {{empresa}}.

Estou te ligando porque você pediu informações sobre o {{empreendimento}}.

Você consegue falar rapidinho agora?

[Se sim]
Perfeito. Só para eu te orientar melhor: você está olhando mais para morar ou investir?

[Qualificar]
- região
- metragem
- prazo
- forma de pagamento
- visita

[Fechamento]
Posso te mandar agora no WhatsApp as informações mais objetivas e, se fizer sentido, já te passo uma simulação ou vejo um melhor horário para você conhecer o projeto.
```

---

## 5. Script-base — Lista fria

```txt
Oi, {{nome_lead}}, tudo bem?
Aqui é {{nome_corretor}}, trabalho com imóveis da {{empresa}}.

Prometo ser breve: estou entrando em contato porque temos algumas opções na região de {{bairro}} e queria entender se ainda faz sentido falar sobre imóvel com você neste momento.

Você está avaliando compra de imóvel hoje ou prefere que eu não siga com esse contato?
```

---

## 6. Script-base — Visitou plantão

```txt
Oi, {{nome_lead}}, tudo bem?
Aqui é {{nome_corretor}}, da {{empresa}}.

Estou te ligando para saber como ficou sua percepção depois da visita ao plantão do {{empreendimento}}.

Queria entender o que você achou melhor e se ficou algum ponto pendente: planta, valor, forma de pagamento ou comparação com outro projeto.

Dependendo do seu momento, eu posso te ajudar com uma simulação mais ajustada ou organizar uma nova conversa mais objetiva.
```

---

## 7. Regra de UX

O script deve aparecer lateralmente ou em card compacto, com botões rápidos para feedback.

Não deve ocupar a tela inteira nem bloquear o corretor.
