# Changelog — Camada Vertical de Aplicação / GPT 7 a GPT 10

**Data:** 2026-06-01  
**Tipo:** documentação, produto e governança  
**Branch:** `docs/application-layer-vertical-specialists`

---

## Resumo

Criação documental da camada vertical de aplicação do FECH.AI, complementando a camada horizontal já definida.

A camada horizontal cobre arquitetura, UX/UI, Supabase, CI/CD, observabilidade e ADS/tracking.

A camada vertical passa a organizar os domínios de negócio do app FECH.AI:

```text
GPT 7: FECH.AI — LeadOps CRM Discador Specialist
GPT 8: FECH.AI — MesaCliente Tabelas Propostas Specialist
GPT 9: FECH.AI — Integrações Portais Mensageria Specialist
GPT 10: FECH.AI — Monetização Startup GTM Specialist
```

---

## Alterações

Arquivos criados:

```text
docs/skills/fechai-gpt7-leadops-crm-discador-specialist.md
docs/skills/fechai-gpt8-mesacliente-tabelas-propostas-specialist.md
docs/skills/fechai-gpt9-integracoes-portais-mensageria-specialist.md
docs/skills/fechai-gpt10-monetizacao-startup-gtm-specialist.md
docs/application-layer/fechai-application-layer-overview.md
```

Arquivo atualizado:

```text
docs/skills/fechai-gpt-registry.md
```

---

## Justificativa

O FECH.AI precisa separar a governança técnica horizontal dos domínios verticais de aplicação.

A verticalização evita que um único GPT tente cobrir listas, CRM, discador, MesaCliente, integrações, portais, mensageria, monetização e go-to-market ao mesmo tempo.

A separação proposta preserva especialização, clareza de responsabilidade e rastreabilidade de decisões.

---

## Escopo funcional coberto

- carregamento de listas em múltiplos formatos;
- OCR de lista de papel;
- compartilhamento via WhatsApp/iOS/Android;
- funil CRM;
- Discador;
- Power Mode;
- dashboards de agendamento e produtividade;
- importação de tabelas de imóveis;
- MesaCliente;
- fluxo de pagamento;
- propostas;
- integração com portais imobiliários;
- WhatsApp oficial e experimental;
- Meta/Google leads;
- Make/n8n;
- monetização SaaS;
- planos, pricing, MRR, CAC, LTV, churn;
- validação de mercado;
- pitch e investimento.

---

## Impacto

Documentação apenas.

Não altera código, banco, Supabase, RLS, RPCs, migrations, Vercel, GitHub Actions, Make/n8n, MesaCliente, parser, motor financeiro, regras comerciais, produção, ADS, CAPI, integrações reais ou automações.

---

## Validação

Validar que:

- GPT 7 cobre LeadOps, CRM, Discador, listas, OCR e produtividade;
- GPT 8 cobre MesaCliente, tabelas, propostas e segurança comercial;
- GPT 9 cobre portais, mensageria, webhooks e integrações externas;
- GPT 10 cobre monetização, startup, pricing, GTM e investimento;
- todos acionam GPT 1 quando houver impacto estrutural;
- todos respeitam multi-tenancy, LGPD, rollback, segurança e produção.

---

## Rollback

Rollback documental:

1. Remover ou reverter os documentos criados nesta alteração.
2. Restaurar `docs/skills/fechai-gpt-registry.md` para versão anterior.
3. Remover `docs/application-layer/fechai-application-layer-overview.md`, se necessário.
