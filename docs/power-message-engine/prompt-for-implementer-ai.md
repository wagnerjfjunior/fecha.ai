# Prompt para IA Implementadora — Power Message Engine

Use este prompt quando for passar a execução para outra IA/dev.

---

## CONTEXTO

Você está trabalhando no projeto **FECH.AI**, uma plataforma SaaS multi-tenant para operação comercial imobiliária, distribuição de leads, discador operacional, funil e gestão de corretores.

O módulo a ser planejado/implementado é o **Power Message Engine**, composto por:

1. Central de Mensagens;
2. Oferta Ativa / Acelerador;
3. Piloto Automático assistivo;
4. Scripts de ligação;
5. Templates de WhatsApp/e-mail por tipo de lead e fase.

---

## REGRAS OBRIGATÓRIAS

1. Não usar placeholders.
2. Não inventar schema.
3. Não recriar arquitetura existente.
4. Não alterar o motor atual do app sem autorização explícita.
5. Não quebrar RPCs existentes.
6. Não ignorar RLS/multi-tenancy.
7. Não criar disparador massivo de WhatsApp na v1.
8. Trabalhar por branch/PR.
9. Antes de migration, auditar schema real.
10. Preservar compatibilidade com fluxo atual de leads e feedbacks.

---

## DOCUMENTOS BASE

Leia antes de propor implementação:

- `docs/power-message-engine/README.md`
- `docs/power-message-engine/spec.md`
- `docs/power-message-engine/data-model.md`
- `docs/power-message-engine/message-taxonomy.md`
- `docs/power-message-engine/automation-rules.md`
- `docs/power-message-engine/call-scripts.md`
- `docs/power-message-engine/compliance-and-governance.md`
- `docs/power-message-engine/implementation-checklist.md`

---

## OBJETIVO DA IMPLEMENTAÇÃO V1

Criar uma primeira versão funcional e segura do Power Message Engine com:

- cadastro/listagem de templates;
- classificação por canal, tipo de lead e fase;
- seleção automática de template elegível;
- registro de uso do template;
- WhatsApp assistido;
- script de ligação exibido na tela;
- feedback obrigatório;
- sugestão de próxima ação;
- isolamento por tenant.

---

## NÃO IMPLEMENTAR NA V1

- disparo massivo de WhatsApp;
- automação para burlar bloqueio;
- chipeira;
- integração WABA completa;
- SMTP multi-tenant completo;
- IA autônoma enviando mensagem sem aprovação humana;
- refatoração grande do app.

---

## SAÍDA ESPERADA

A IA/dev deve entregar:

1. Diagnóstico do estado atual do repo.
2. Lista dos arquivos que pretende alterar.
3. Diff proposto antes de aplicar mudanças sensíveis.
4. Migrations somente após validação do schema real.
5. Componentes frontend pequenos e isolados.
6. Funções/RPCs com tenant isolation.
7. Testes ou checklist de validação.
8. Registro claro do que foi feito e do que ficou pendente.

---

## ORIENTAÇÃO DE PRODUTO

O corretor deve ter uma experiência simples:

- abrir lead;
- clicar em Oferta Ativa/Acelerador;
- ver a melhor próxima ação;
- copiar/abrir mensagem;
- ligar com script;
- registrar feedback;
- seguir para o próximo lead.

A complexidade deve ficar no motor, não na tela do corretor.
