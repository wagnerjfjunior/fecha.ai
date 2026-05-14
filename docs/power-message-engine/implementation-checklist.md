# Power Message Engine — Checklist de Implementação

## Fase 0 — Validação do estado atual

- [ ] Confirmar branch de trabalho.
- [ ] Confirmar schema real do Supabase.
- [ ] Confirmar tabelas existentes de leads, corretores, admins, logs e feedbacks.
- [ ] Confirmar regras RLS atuais.
- [ ] Confirmar fluxo atual do lead/discador.
- [ ] Não alterar motor atual sem aprovação.

---

## Fase 1 — Documentação e modelagem

- [x] Criar pasta `docs/power-message-engine`.
- [x] Criar README do módulo.
- [x] Criar especificação funcional.
- [x] Criar modelo de dados sugerido.
- [x] Criar taxonomia de mensagens.
- [x] Criar regras de automação.
- [x] Criar estrutura de scripts de ligação.
- [x] Criar compliance/governança.

---

## Fase 2 — Banco de dados

- [ ] Validar nomes reais das tabelas.
- [ ] Criar migration para `message_templates`.
- [ ] Criar migration para `message_template_usage`.
- [ ] Criar migration para `message_sequences`.
- [ ] Criar migration para `message_sequence_steps`.
- [ ] Criar migration para `lead_message_state`.
- [ ] Criar índices.
- [ ] Criar RLS.
- [ ] Criar seeds iniciais de templates.

---

## Fase 3 — Serviços/RPCs

- [ ] Criar função para listar templates elegíveis.
- [ ] Criar função para selecionar próximo template.
- [ ] Criar função para renderizar variáveis.
- [ ] Criar função para registrar uso de template.
- [ ] Criar função para sugerir próxima ação.
- [ ] Garantir isolamento por tenant.

---

## Fase 4 — Frontend

- [ ] Criar tela/área da Central de Mensagens.
- [ ] Criar tela do Acelerador / Oferta Ativa.
- [ ] Criar card de mensagem sugerida.
- [ ] Criar botão copiar mensagem.
- [ ] Criar botão abrir WhatsApp.
- [ ] Criar painel lateral de script de ligação.
- [ ] Criar feedback obrigatório pós-ação.
- [ ] Criar histórico de contatos do lead.

---

## Fase 5 — Admin/Gestor

- [ ] Gestor cria template.
- [ ] Gestor edita template.
- [ ] Gestor ativa/inativa template.
- [ ] Gestor filtra por canal/tipo/fase.
- [ ] Gestor visualiza uso/performance.
- [ ] Admin global/root audita configurações se aplicável.

---

## Fase 6 — Seeds de mensagens

WhatsApp mínimo:

- [ ] 10 mensagens para `lead_quente + primeira_mensagem`.
- [ ] 10 mensagens para `lead_quente + segunda_mensagem`.
- [ ] 10 mensagens para `lead_quente + terceira_mensagem`.
- [ ] 10 mensagens para `lead_quente + mensagem_final`.
- [ ] 10 mensagens para `lista_fria + primeira_mensagem`.
- [ ] 10 mensagens para `lista_fria + segunda_mensagem`.
- [ ] 10 mensagens para `lista_fria + terceira_mensagem`.
- [ ] 10 mensagens para `lista_fria + mensagem_final`.
- [ ] 10 mensagens para `lista_quente + primeira_mensagem`.
- [ ] 10 mensagens para `lista_quente + segunda_mensagem`.
- [ ] 10 mensagens para `lista_quente + terceira_mensagem`.
- [ ] 10 mensagens para `lista_quente + mensagem_final`.
- [ ] 10 mensagens para `visitou_plantao + primeira_mensagem`.
- [ ] 10 mensagens para `visitou_plantao + segunda_mensagem`.
- [ ] 10 mensagens para `visitou_plantao + terceira_mensagem`.
- [ ] 10 mensagens para `visitou_plantao + mensagem_final`.

Total mínimo recomendado: **160 templates de WhatsApp**.

---

## Fase 7 — Testes

- [ ] Testar seleção sem repetição para o mesmo lead.
- [ ] Testar fallback quando variável está ausente.
- [ ] Testar tenant isolation.
- [ ] Testar corretor sem permissão administrativa.
- [ ] Testar gestor ativando/inativando template.
- [ ] Testar lead com opt-out.
- [ ] Testar feedback obrigatório.
- [ ] Testar histórico de uso.
- [ ] Testar UX em celular.

---

## Fase 8 — Rollout

- [ ] Ativar primeiro em tenant controlado.
- [ ] Monitorar taxa de resposta.
- [ ] Monitorar templates mais usados.
- [ ] Monitorar problemas de UX.
- [ ] Ajustar mensagens.
- [ ] Só depois ampliar para demais tenants.
