# MVP_SCOPE — PME Usage Tracking & Script Utility v0.2.7

## 1. Escopo do MVP

A v0.2.7 deve entregar o menor conjunto seguro para registrar uso de scripts/mensagens sem interferir na operação do corretor.

O MVP deve responder:

- qual evento ocorreu;
- em qual origem do lead;
- em qual canal;
- em qual situação comercial;
- se o texto veio de template ou IA;
- se o corretor executou o contato;
- qual versão do módulo gerou o evento.

---

## 2. Entregáveis obrigatórios

### 2.1 Frontend

- Criar função local de tracking no `pme-call-assistant-beta.js`.
- A função deve ser assíncrona e não bloqueante.
- O evento deve ser disparado em ações relevantes.
- Em caso de erro, o fluxo do corretor deve continuar.
- Não exibir erro técnico para o corretor, exceto em modo debug futuro.

Eventos iniciais:

- `script_executed`;
- `ai_requested`;
- `ai_succeeded`;
- `ai_failed`.

Eventos opcionais, se não criarem excesso:

- `script_viewed`;
- `script_variant_changed`;
- `script_copied_fallback`.

### 2.2 Backend/Banco

- Criar tabela de eventos ou preparar script SQL para aprovação.
- Criar RPC segura para inserir eventos.
- Aplicar RLS por tenant/empresa/usuário.
- Validar `auth.uid()`.
- Não aceitar `tenant_id` soberano vindo do frontend sem validação.

### 2.3 Documentação

- Contrato funcional.
- Modelo de dados.
- Plano de RLS.
- Plano de rollback.
- Checklist de validação.

---

## 3. Fora de escopo do MVP

Não implementar nesta etapa:

- dashboard visual;
- ranking de melhores scripts;
- ML/IA para recomendação automática;
- billing real;
- cache semântico;
- curadoria de scripts por gestor;
- armazenamento de texto completo;
- associação definitiva com feedback;
- alteração de feedback existente;
- alteração do motor de lead;
- envio automático de WhatsApp/e-mail.

---

## 4. Estratégia de implementação em fases

### Fase 1 — Documentação

Criar contrato, modelo de dados e plano de segurança.

Status: escopo desta etapa inicial.

### Fase 2 — Migration/RPC proposta

Criar migration ou script SQL em branch, mas revisar antes de aplicar em produção.

### Fase 3 — Frontend tracking não bloqueante

Adicionar função de tracking no `pme-call-assistant-beta.js`.

### Fase 4 — Preview e validação

Validar:

- login;
- snapshot;
- discador;
- IA;
- feedback;
- próximo lead;
- network;
- console;
- inserção de evento.

### Fase 5 — Merge controlado

Squash merge após validação.

---

## 5. Critérios de aceite

### Funcional

- O corretor consegue usar o fluxo normalmente.
- Clique em executar contato registra evento.
- Clique em IA registra evento.
- Sucesso/falha de IA registra evento.
- Falha no tracking não bloqueia atendimento.

### Segurança

- RPC valida usuário autenticado.
- RLS impede vazamento cross-tenant.
- Frontend não envia `service_role`.
- Frontend não decide tenant/empresa sozinho.
- Não há texto sensível persistido sem aprovação.

### Operacional

- Login continua funcionando.
- Snapshot continua funcionando.
- Discador abre.
- Feedback registra.
- Próximo lead funciona.
- Vercel preview verde.

---

## 6. Métrica de sucesso inicial

Após ativação, espera-se conseguir consultar:

- total de eventos por canal;
- total de eventos por origem;
- total de eventos por situação;
- uso de IA versus template;
- falhas de IA;
- ações executadas por dia;
- scripts mais acionados por hash.

---

## 7. Observação importante

Não confundir tracking com automação. A v0.2.7 registra uso; ela não decide pelo corretor, não envia mensagem sozinha e não altera feedback automaticamente.
