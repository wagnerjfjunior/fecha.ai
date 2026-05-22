# Caderno de testes — MVP Discador Flow AI / PME v0.1

## Objetivo

Validar que o MVP melhora o fluxo operacional do corretor sem quebrar o discador, feedback, dados, segurança ou experiência mobile.

---

## Testes visuais mobile

- [ ] Tela abre sem conteúdo encavalado.
- [ ] Script de ligação fica dentro do container correto.
- [ ] Badges são clicáveis em tela pequena.
- [ ] Modal abre e fecha corretamente.
- [ ] Botões têm nomes claros e função única.
- [ ] Conteúdo não exige zoom manual.

---

## Testes de badges

- [ ] Lista fria muda contexto para abordagem fria.
- [ ] Já visitou muda contexto para fundo de funil.
- [ ] Redes Sociais muda contexto para lead inbound/social.
- [ ] Problemas abre opções de objeção/dor.
- [ ] Argumentações abre biblioteca de argumentos.

---

## Testes de canal

- [ ] WhatsApp exibe texto compatível com mensagem curta.
- [ ] Ligações exibe fala/script e não mensagem longa demais.
- [ ] E-mail exibe assunto e corpo.
- [ ] Trocar canal não perde lead ativo.
- [ ] Trocar canal não salva feedback automaticamente.

---

## Testes de IA

- [ ] IA indisponível não quebra o fluxo manual.
- [ ] Botão de IA mostra carregamento.
- [ ] Erro de IA mostra mensagem clara.
- [ ] Sem permissão de IA mostra estado de módulo inativo.
- [ ] Resposta IA pode ser aceita, editada ou rejeitada.
- [ ] Nenhuma chave de IA aparece no frontend.

---

## Testes de ação

- [ ] Copiar texto copia exatamente o conteúdo do modal.
- [ ] Abrir WhatsApp não envia automaticamente.
- [ ] Copiar fala de ligação não abre WhatsApp.
- [ ] Preparar e-mail não envia automaticamente.
- [ ] Ações geram eventos somente quando previsto.

---

## Testes de score e feedback

- [ ] Score pode ser selecionado.
- [ ] Feedback pode ser registrado após uso do script.
- [ ] Score é associado ao feedback.
- [ ] Feedback continua dependendo do corretor.
- [ ] Fluxo atual de feedback não quebra.

---

## Testes de segurança

- [ ] Nenhum `service_role` no frontend.
- [ ] Nenhuma chave de IA no frontend.
- [ ] Nenhum envio automático sem confirmação humana.
- [ ] Nenhum `empresa_id` do frontend usado como autoridade soberana.
- [ ] Dados pessoais enviados para IA são mínimos e justificados.
- [ ] Recurso IA respeita permissão/plano quando backend existir.

---

## Critério de PASS

Todos os testes críticos de mobile, ação, feedback e segurança devem passar antes de PR para `main`.

## Critério de FAIL automático

- Quebrou feedback atual.
- Expôs segredo no frontend.
- Enviou mensagem automaticamente.
- IA falhou e travou o fluxo manual.
- Layout mobile ficou ilegível.
- Alterou banco/RPC/RLS sem contrato próprio.