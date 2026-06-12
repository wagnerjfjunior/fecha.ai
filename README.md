# FECH.AI

Sistema inteligente de distribuição e gestão de leads imobiliários.

## Comece aqui

Antes de iniciar qualquer conversa técnica, PR, tarefa Codex, auditoria ou alteração relevante, leia primeiro os índices canônicos do projeto:

- [`docs/bootstrap/INDEX.md`](docs/bootstrap/INDEX.md) — entrada operacional obrigatória, bootstrap, modus operandi e estado SaaS atual.
- [`docs/audits/architecture/INDEX.md`](docs/audits/architecture/INDEX.md) — índice de arquitetura para Edge Functions, camadas SaaS, Vercel API/proxy, service bridges e RPC/RLS.

Documentos de apoio ainda relevantes:

- [`docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md`](docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md)
- [`docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md`](docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md)

Esses documentos organizam a visão do FECH.AI como Pilot Production SaaS multi-tenant/multiempresa e indicam quais documentos, PRs e especialistas devem ser consultados por frente ativa.

## Stack

- React 18 + Vite
- Tailwind CSS
- Supabase (PostgreSQL + Auth + RLS)
- Recharts (gráficos)
- Deploy via Vercel

## Desenvolvimento local

```bash
npm install
npm run dev
```

## Funcionalidades atuais

- Gestora: upload de listas, distribuição automática, dashboard, gestão de listas.
- Corretor: discador, feedback estruturado, produção diária, carteira.
- WhatsApp inteligente com saudação automática.
- Avaliação de qualidade de lista por corretor.
- Relatório de fornecedor.
- Base para operação multi-tenant com governança por empresa/time.

## Módulos em documentação/evolução

### Power Message Engine — Central de Mensagens

Documentação inicial criada para o motor de mensagens, scripts de ligação, Oferta Ativa/Acelerador e Piloto Automático assistivo.

Arquivos principais:

- [`docs/power-message-engine/README.md`](docs/power-message-engine/README.md)
- [`docs/power-message-engine/spec.md`](docs/power-message-engine/spec.md)
- [`docs/power-message-engine/data-model.md`](docs/power-message-engine/data-model.md)
- [`docs/power-message-engine/message-taxonomy.md`](docs/power-message-engine/message-taxonomy.md)
- [`docs/power-message-engine/automation-rules.md`](docs/power-message-engine/automation-rules.md)
- [`docs/power-message-engine/call-scripts.md`](docs/power-message-engine/call-scripts.md)
- [`docs/power-message-engine/compliance-and-governance.md`](docs/power-message-engine/compliance-and-governance.md)
- [`docs/power-message-engine/implementation-checklist.md`](docs/power-message-engine/implementation-checklist.md)
- [`docs/power-message-engine/prompt-for-implementer-ai.md`](docs/power-message-engine/prompt-for-implementer-ai.md)

## Regras de evolução

- Não alterar o motor atual sem validação explícita.
- Não presumir schema de banco: auditar Supabase antes de migrations.
- Preservar RLS e isolamento multi-tenant.
- Trabalhar mudanças relevantes por branch/PR.
- Evitar refatorações grandes sem necessidade comprovada.

## Deploy

Este projeto roda no Vercel com integração via GitHub.
