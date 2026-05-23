# VALIDATION_CHECKLIST — PME Usage Tracking & Script Utility v0.2.7

## 1. Objetivo

Validar a release v0.2.7 antes de qualquer merge para `main`, garantindo que o tracking de uso dos scripts do Discador Flow AI / PME funcione sem quebrar operação, login, snapshot, feedback, IA ou isolamento multi-tenant.

---

## 2. Pré-condições

Antes de iniciar a validação:

- [ ] Branch correta: `feature/pme-usage-tracking-v0.2.7`.
- [ ] Base estável conhecida: `baseline/discador-flow-ai-pme-v0.2.6-stable`.
- [ ] Vercel preview gerada e acessível.
- [ ] Usuário de teste autenticável.
- [ ] Lead de teste disponível no discador.
- [ ] Console do navegador aberto.
- [ ] Aba Network aberta.
- [ ] Nenhum teste deve usar `service_role` no navegador.

---

## 3. Validação de documentação

- [ ] `README.md` existe.
- [ ] `CONTRACT.md` existe.
- [ ] `MVP_SCOPE.md` existe.
- [ ] `DATA_MODEL.md` existe.
- [ ] `SECURITY_RLS_PLAN.md` existe.
- [ ] `ROLLBACK_PLAN.md` existe.
- [ ] `VALIDATION_CHECKLIST.md` existe.
- [ ] Os documentos deixam claro que o tracking não pode bloquear atendimento.
- [ ] Os documentos deixam claro que o frontend não é fonte soberana de tenant/empresa/permissão.
- [ ] Os documentos deixam claro que texto completo não deve ser persistido no MVP sem aprovação específica.

---

## 4. Validação funcional base

### Login e app

- [ ] Login funciona normalmente.
- [ ] Snapshot continua funcionando, quando aplicável.
- [ ] App não fica em tela branca.
- [ ] Console não mostra erro global bloqueante.
- [ ] Não há erro de autenticação novo causado pela v0.2.7.

### Discador

- [ ] Discador abre normalmente.
- [ ] Lead ativo carrega.
- [ ] Header `Discador Flow AI` aparece.
- [ ] Card `Fluxo de atendimento` aparece.
- [ ] Badges de origem funcionam com clique único.
- [ ] Canais funcionam com clique único.
- [ ] Combo de situação abre e seleciona sem fechar sozinho.
- [ ] Mensagem sugerida muda conforme origem/canal/situação.

### IA

- [ ] Modal `Melhorar com IA` abre.
- [ ] Dica para IA influencia resposta.
- [ ] IA não trava o fluxo se falhar.
- [ ] Erro de IA exibe fallback amigável.
- [ ] Não há envio automático de mensagem.

### Feedback e próximo lead

- [ ] Feedback registra normalmente.
- [ ] Próximo lead funciona.
- [ ] Nenhum feedback é alterado automaticamente pelo tracking.
- [ ] Nenhuma classificação é alterada automaticamente pelo tracking.

---

## 5. Validação de eventos esperados

### Eventos obrigatórios do MVP

- [ ] `script_executed` é registrado ao executar contato.
- [ ] `ai_requested` é registrado ao solicitar IA.
- [ ] `ai_succeeded` é registrado quando IA retorna texto utilizável.
- [ ] `ai_failed` é registrado quando IA falha.

### Eventos opcionais

- [ ] `script_viewed`, se implementado, possui debounce e não gera flood.
- [ ] `script_variant_changed`, se implementado, registra Próximo/Voltar sem excesso.
- [ ] `script_copied_fallback`, se implementado, registra fallback sem bloquear canal.

---

## 6. Validação por canal

### Ligação

- [ ] Selecionar canal Ligação.
- [ ] Botão mostra `Efetuar ligação`.
- [ ] Ao executar, tenta acionar `tel:` quando há telefone.
- [ ] Evento registra `channel = ligacao`.
- [ ] Evento registra `execution_target = tel` ou `manual_copy`, conforme caso.
- [ ] Falha no tracking não impede ligação.

### WhatsApp

- [ ] Selecionar canal WhatsApp.
- [ ] Botão mostra `Abrir WhatsApp`.
- [ ] Ao executar, abre `wa.me` com mensagem pronta.
- [ ] Mensagem não é enviada automaticamente.
- [ ] Evento registra `channel = whatsapp`.
- [ ] Evento registra `execution_target = whatsapp`.
- [ ] Falha no tracking não impede abertura do WhatsApp.

### E-mail

- [ ] Selecionar canal E-mail.
- [ ] Botão mostra `Preparar e-mail`.
- [ ] Ao executar, monta `mailto:` quando há e-mail.
- [ ] Evento registra `channel = email`.
- [ ] Evento registra `execution_target = mailto` ou `manual_copy`, conforme caso.
- [ ] Falha no tracking não impede uso do texto.

---

## 7. Validação de payload

O payload enviado pelo frontend deve conter, no máximo, dados operacionais permitidos.

- [ ] `event_type` enviado.
- [ ] `module = discador_flow_ai` enviado.
- [ ] `module_version` enviado.
- [ ] `context` enviado.
- [ ] `channel` enviado.
- [ ] `approach` enviado.
- [ ] `script_source` enviado.
- [ ] `script_variant` enviado quando aplicável.
- [ ] `script_text_hash` enviado quando aplicável.
- [ ] `ai_attempt` enviado quando aplicável.
- [ ] `ai_tip_hash` enviado quando aplicável.
- [ ] `execution_target` enviado quando aplicável.
- [ ] `client_timestamp` enviado.

Campos que não devem ir como soberanos:

- [ ] Não enviar `tenant_id` como verdade absoluta.
- [ ] Não enviar `empresa_id` como verdade absoluta.
- [ ] Não enviar `user_id` como verdade absoluta.
- [ ] Não enviar `service_role`.
- [ ] Não enviar token em payload.
- [ ] Não enviar headers sensíveis em metadata.

Campos sensíveis proibidos no MVP:

- [ ] Não enviar texto completo do script para persistência.
- [ ] Não enviar dica completa da IA para persistência.
- [ ] Não enviar telefone puro.
- [ ] Não enviar e-mail puro.
- [ ] Não enviar nome completo do lead.
- [ ] Não enviar documentos ou dados financeiros pessoais.

---

## 8. Validação de banco/RPC/RLS

Quando a parte de banco for implementada:

- [ ] Tabela `pme_script_usage_events` criada com RLS ativa.
- [ ] RPC `registrar_pme_script_usage` criada.
- [ ] RPC exige usuário autenticado.
- [ ] RPC usa `auth.uid()`.
- [ ] RPC resolve tenant/empresa no backend.
- [ ] RPC ignora/sobrescreve tenant/empresa/user vindos do frontend.
- [ ] RPC valida enums.
- [ ] RPC valida lead_id quando enviado.
- [ ] RPC filtra metadata por allowlist.
- [ ] Insert direto na tabela está bloqueado ou estritamente controlado.
- [ ] Select está restrito por tenant/empresa/perfil.
- [ ] Usuário de uma empresa não lê evento de outra empresa.
- [ ] Usuário de um tenant não lê evento de outro tenant.

---

## 9. Validação de resiliência

- [ ] Simular RPC indisponível.
- [ ] Confirmar que o corretor ainda consegue ligar.
- [ ] Confirmar que o corretor ainda consegue abrir WhatsApp.
- [ ] Confirmar que o corretor ainda consegue preparar e-mail.
- [ ] Confirmar que a IA continua funcionando quando o tracking falha.
- [ ] Confirmar que feedback continua funcionando quando o tracking falha.
- [ ] Confirmar que próximo lead continua funcionando quando o tracking falha.
- [ ] Console não deve virar festival de erro vermelho. Um aviso controlado em debug futuro é aceitável.

---

## 10. Validação de segurança no navegador

- [ ] Network sem `service_role`.
- [ ] Network sem segredo sensível.
- [ ] Console sem tokens.
- [ ] Console sem payload sensível.
- [ ] LocalStorage não recebe novo dado sensível por causa do tracking.
- [ ] Não há `window.fetch` monkey patch global.
- [ ] Não há interceptação global de rede.
- [ ] Não há envio automático de WhatsApp/e-mail.

---

## 11. Critérios de PASS

A release pode avançar quando:

- [ ] Login PASS.
- [ ] Snapshot PASS ou não bloqueante, com app funcional validado.
- [ ] Discador PASS.
- [ ] IA PASS.
- [ ] Execução por canal PASS.
- [ ] Feedback PASS.
- [ ] Próximo lead PASS.
- [ ] Tracking não bloqueante PASS.
- [ ] Segurança frontend PASS.
- [ ] RLS/RPC PASS, quando banco estiver incluído no escopo da PR.

---

## 12. Critérios de FAIL / bloqueio de merge

Bloquear merge se ocorrer qualquer item:

- [ ] Login quebra.
- [ ] Snapshot quebra e app também apresenta falha real.
- [ ] Discador não abre.
- [ ] Lead não carrega.
- [ ] Feedback não registra.
- [ ] Próximo lead falha.
- [ ] IA trava por causa do tracking.
- [ ] Tracking bloqueia a execução do contato.
- [ ] Texto completo é persistido sem aprovação.
- [ ] Token/segredo aparece no console/network.
- [ ] `service_role` aparece no navegador.
- [ ] RLS permite acesso cruzado.
- [ ] Evento é gravado no tenant/empresa errada.

---

## 13. Decisão final

Marcar uma opção antes de PR/merge:

- [ ] Aprovado para implementar banco/RPC.
- [ ] Aprovado para implementar somente frontend com feature flag.
- [ ] Aprovado para PR de documentação apenas.
- [ ] Bloqueado por risco de segurança.
- [ ] Bloqueado por regressão funcional.
