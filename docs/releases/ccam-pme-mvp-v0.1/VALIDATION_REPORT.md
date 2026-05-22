# Validation Report — Discador Flow AI / PME Beta v0.2.5

**Status:** validação controlada pré-merge  
**Branch:** `feature/ccam-pme-mvp-v0.1`  
**PR:** #20  
**Última versão funcional:** v0.2.5

---

## Evidência analisada

HAR enviado: `chateau IA json tela anonima console root login fecha-ai.vercel.app.har`

### Achados iniciais

- RPC `get_contagens_corretor` retornando `401 JWT expired`.
- Edge Function `functions/v1/assistente-ai` com `OPTIONS 200`.
- POST para `assistente-ai` aparecia com status `0`, típico de bloqueio/falha de rede/CORS/runtime sem resposta visível ao navegador.
- No POST da IA no HAR, não havia header `Authorization` com Bearer token visível.
- O preflight `OPTIONS` permitia `authorization` e `content-type`; por isso o frontend v0.2.1 removeu `apikey` da chamada da Edge Function e passou a usar somente `Authorization` + `Content-Type`.

---

## Hipótese técnica inicial

A IA não funcionava por combinação provável de:

1. sessão/JWT expirada;
2. POST da Edge Function sem `Authorization` válido;
3. possível bloqueio de CORS quando headers fora da allowlist eram enviados;
4. ausência de fallback claro no frontend.

---

## Correções aplicadas no frontend v0.2.1

- Header visual com título `Discador Flow AI`.
- Bloco de informações do lead.
- Badges centralizados no mobile e desktop.
- Canais centralizados no mobile e desktop.
- Power Dial, Power Zap e Power Mail posicionados acima dos badges Ligação, WhatsApp e E-mail.
- Removidos da tela principal os botões redundantes:
  - Abrir/editar;
  - Trocar opção;
  - Copiar texto;
  - Copiar e-mail;
  - Score de utilidade do script.
- Tela principal passou a usar apenas 4 ações:
  - Utilizar;
  - Voltar;
  - Próximo;
  - Melhorar com IA.
- Evento de clique passou a usar delegação única para reduzir falha de clique duplo causada por re-render.
- Chamada da IA passou a validar token ausente/expirado antes do POST.
- Chamada da IA removeu `apikey` para evitar conflito com CORS da Edge Function atual.

---

## Correções adicionais aplicadas no frontend v0.2.2

- Título `Discador Flow AI` movido para o topo da página do discador.
- O frame do assistente deixou de repetir o título principal e passou a exibir `Fluxo de atendimento`.
- Botão duplicado `Power Dial — OFF/ON` do canto superior direito passou a ser ocultado visualmente.
- O `Power Dial` do próprio Discador Flow AI passou a sincronizar com o botão real do app quando possível.
- Botões originais `Ligar` e `Mensagens` do primeiro quadro foram ocultados para reduzir redundância.
- A seção de execução foi criada entre o quadro do assistente e o feedback.
- O botão principal passou a ser dinâmico conforme o canal:
  - Ligação: `Efetuar ligação`;
  - WhatsApp: `Abrir WhatsApp`;
  - E-mail: `Preparar e-mail`.
- Para ligação, a ação copia a fala de apoio e tenta iniciar `tel:`.
- Para WhatsApp, a ação abre `wa.me` com a mensagem pronta.
- Para e-mail, a ação monta `mailto:` com assunto e corpo quando o e-mail do lead é encontrado.
- Corrigido problema provável do combo `Tipo de abordagem` fechar imediatamente: o MutationObserver pausa o re-render enquanto o select está focado/aberto.

---

## Correções adicionais aplicadas no frontend v0.2.3

- Removidas informações repetidas do segundo card:
  - nome do lead;
  - e-mail;
  - contexto atual.
- Instruções simplificadas para usuário não técnico:
  - `1. Escolha a origem do lead`;
  - `2. Escolha o canal para contato com o cliente`;
  - `3. Escolha em qual situação o cliente está`;
  - `4. Executar contato`.
- Adicionado badge `Carteira`.
- Aumentadas fontes de títulos, badges, canais, combobox, mensagens e botões.
- Melhorado layout desktop com grid responsivo.
- Melhorado mobile com combobox maior e melhor legibilidade.

---

## Correções adicionais aplicadas no frontend v0.2.4

- Melhorada sensibilidade de clique usando `pointerup` além de `click`.
- Incluída proteção contra duplo disparo.
- Modal da IA passou a respeitar o canal escolhido no fluxo.
- Removido botão `Copiar` do modal.
- Botão principal do modal passou a executar a ação correta:
  - ligação;
  - WhatsApp;
  - e-mail.

---

## Correções adicionais aplicadas no frontend v0.2.5

- Criado `public/pme-call-assistant-ai-context-patch.js`.
- Atualizado `src/main.jsx` para carregar o patch após o assistente beta.
- A dica do corretor no modal passou a ser tratada como diretriz principal do prompt.
- Adicionadas regras anti-repetição.
- Adicionado comportamento por canal:
  - WhatsApp: mensagem curta e natural;
  - E-mail: assunto + corpo objetivo;
  - Ligação: fala natural em voz alta.
- Botão do modal muda entre:
  - `Gerar nova versão`;
  - `Gerar com esta dica`.
- A IA continua sem envio automático.

---

## Validações já confirmadas pelo usuário

- Layout do fluxo ficou adequado.
- Segundo card ficou mais limpo após remover dados repetidos do lead.
- Fluxo com origem, canal, situação e execução ficou coerente.
- IA passou a funcionar.
- Problema restante identificado: dica precisava influenciar mais o contexto e respostas estavam repetitivas.
- Correção de prompt/contexto aplicada em v0.2.5 para atacar esse ponto.

---

## Checklist obrigatório antes do merge em main

### Funcional desktop

- [ ] Login normal.
- [ ] Discador abre com lead ativo.
- [ ] Header `Discador Flow AI` aparece no topo.
- [ ] Card `Fluxo de atendimento` aparece antes do feedback.
- [ ] Badges de origem respondem com um clique.
- [ ] Badges de canal respondem com um clique.
- [ ] Combo de situação abre e permite escolha sem fechar imediatamente.
- [ ] Botão principal muda conforme canal.
- [ ] Feedback permanece funcionando.
- [ ] Próximo lead permanece funcionando.

### Funcional mobile

- [ ] Layout não encavala texto no canto esquerdo.
- [ ] Badges ficam responsivos.
- [ ] Combobox fica legível.
- [ ] Botões respondem com um toque.
- [ ] WhatsApp abre corretamente.
- [ ] Ligação tenta acionar `tel:`.
- [ ] E-mail tenta acionar `mailto:` quando houver e-mail.

### IA

- [ ] Modal abre corretamente.
- [ ] IA responde com sessão válida.
- [ ] Campo `Dica para IA` influencia a resposta.
- [ ] `Gerar com esta dica` gera resposta contextualizada.
- [ ] `Gerar nova versão` reduz repetição.
- [ ] Sessão expirada mostra erro amigável.
- [ ] Texto base permanece utilizável se a IA falhar.

### Segurança

- [ ] Console sem segredo sensível.
- [ ] Network sem `service_role`.
- [ ] Sem alteração em RPC/RLS/auth.
- [ ] Nenhum envio automático é disparado.
- [ ] Corretor revisa antes de executar.

---

## Status de CI/deploy

- Último status conhecido do commit anterior: Vercel `success`.
- Após as atualizações documentais e carregamento do patch, validar novo status da Vercel antes do merge.

---

## Resultado final

**Pendente de checklist final em preview.**

Decisão recomendada: manter PR em validação controlada, atualizar metadados, remover estado de draft somente após o checklist final, e fazer squash merge na `main` quando o preview estiver validado.
