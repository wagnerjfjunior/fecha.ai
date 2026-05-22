# Post Merge Checklist — Discador Flow AI / PME Beta v0.2.5

Checklist obrigatório para depois do merge em `main`.

---

## Verificação imediata de deploy

- [ ] Deploy Vercel da `main` finalizado com sucesso.
- [ ] Página principal abre sem tela branca.
- [ ] Login funcionando.
- [ ] Console sem erro global bloqueante.
- [ ] Nenhum segredo sensível aparece no console.
- [ ] Network sem `service_role`.

---

## Discador — desktop

- [ ] Discador abre no desktop.
- [ ] Lead ativo carrega.
- [ ] Header `Discador Flow AI` aparece no topo.
- [ ] Card `Fluxo de atendimento` aparece antes do feedback.
- [ ] Card do lead não ficou poluído com botões redundantes.
- [ ] Botão duplicado `Power Dial — OFF/ON` não aparece no canto superior direito.
- [ ] Origem do lead responde com clique único.
- [ ] Canais respondem com clique único.
- [ ] Power Dial/Power Zap/Power Mail aparecem acima dos canais.
- [ ] Combo de situação abre e permite escolha.
- [ ] Mensagem sugerida muda conforme origem/canal/situação.
- [ ] Botão principal muda conforme canal.

---

## Discador — mobile

- [ ] Layout não encavala texto no canto esquerdo.
- [ ] Badges ficam responsivos.
- [ ] Combobox fica legível.
- [ ] Botões respondem com um toque.
- [ ] Texto da mensagem sugerida fica legível.
- [ ] Modal da IA cabe na tela.
- [ ] Botão principal do modal fica acessível.

---

## Execução dinâmica

### Ligação

- [ ] Selecionar canal Ligação.
- [ ] Botão mostra `Efetuar ligação`.
- [ ] Ao executar, copia a fala de apoio.
- [ ] Dispositivo tenta abrir `tel:` quando possível.

### WhatsApp

- [ ] Selecionar canal WhatsApp.
- [ ] Botão mostra `Abrir WhatsApp`.
- [ ] Ao executar, abre `wa.me` com mensagem pronta.
- [ ] Mensagem não é enviada automaticamente.

### E-mail

- [ ] Selecionar canal E-mail.
- [ ] Botão mostra `Preparar e-mail`.
- [ ] Ao executar, monta `mailto:` quando houver e-mail do lead.
- [ ] Quando não houver e-mail, mostra fallback/cópia manual.

---

## IA

- [ ] Botão `Melhorar com IA` abre o modal.
- [ ] Modal mostra o canal escolhido.
- [ ] Botão principal do modal replica o canal escolhido.
- [ ] Campo `Dica para IA` aceita texto.
- [ ] Ao preencher dica, botão muda para `Gerar com esta dica`.
- [ ] IA responde quando sessão válida.
- [ ] IA usa a dica como contexto principal.
- [ ] Resposta da IA respeita o canal escolhido.
- [ ] Resposta da IA não inventa preço, desconto, unidade, disponibilidade ou condição.
- [ ] `Gerar nova versão` não repete a mesma estrutura de forma excessiva.
- [ ] Sessão expirada mostra erro amigável.
- [ ] Texto base permanece utilizável sem IA.

---

## Feedback e fluxo original

- [ ] Feedback manual registra normalmente.
- [ ] Próximo lead funciona.
- [ ] Nenhum feedback foi alterado automaticamente pela IA.
- [ ] Nenhuma classificação foi alterada automaticamente.
- [ ] Fluxo original permanece recuperável sem IA.

---

## Segurança

- [ ] Console sem chave secreta.
- [ ] Network sem `service_role`.
- [ ] Nenhum envio automático disparado.
- [ ] Nenhuma decisão crítica depende de dado soberano vindo do frontend.
- [ ] Não houve alteração em RPC/RLS/auth/grants.

---

## Monitoramento

- [ ] Verificar console do navegador.
- [ ] Verificar logs da Edge Function `assistente-ai`, se aplicável.
- [ ] Verificar erro 401/JWT expired.
- [ ] Verificar CORS.
- [ ] Verificar feedback de pelo menos 1 lead real/controlado.

---

## Decisão pós-merge

Marcar uma das opções:

- [ ] Manter ativo.
- [ ] Manter visual ativo e desativar IA contextual.
- [ ] Desativar Discador Flow AI completo.
- [ ] Fazer rollback por Vercel.
- [ ] Fazer rollback por Git.

---

## Observação operacional

Durante as primeiras horas após merge, tratar a release como beta controlado. Qualquer falha em feedback, próximo lead, auth ou carregamento do lead tem prioridade sobre melhoria visual ou melhoria de IA.
