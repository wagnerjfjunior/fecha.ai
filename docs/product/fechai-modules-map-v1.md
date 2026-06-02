# FECH.AI — Mapa de Módulos v1

**Status:** v1.0 — mapa inicial dos módulos de produto  
**Data:** 2026-06-02  
**Escopo:** organização funcional do app FECH.AI por módulos, responsabilidades e especialistas.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Objetivo

Este documento define os módulos principais do FECH.AI como aplicação SaaS imobiliária.

A finalidade é evitar escopo solto e permitir que cada nova feature seja classificada no módulo correto antes de virar implementação.

---

## 2. Módulos principais

```text
M1 — LeadOps, Listas, CRM e Discador
M2 — ADS, Tracking, CAPI, Stape e CRM-to-Ads
M3 — MesaCliente, Tabelas e Propostas
M4 — Integrações, Portais e Mensageria
M5 — Dashboards, Observabilidade e Operação
M6 — Monetização, Planos e Go-to-Market
```

---

## 3. M1 — LeadOps, Listas, CRM e Discador

Responsável por transformar leads e listas em ação comercial.

Inclui:

- upload de listas;
- CSV/XLSX/PDF/texto/imagem;
- OCR de lista de papel;
- compartilhamento mobile/WhatsApp;
- deduplicação;
- validação de telefone;
- CRM/funil;
- Discador;
- Power Mode;
- WhatsApp manual;
- agendamentos;
- taxa de conversão;
- produtividade do corretor;
- dashboard de fim de semana.

Especialista principal: GPT 7.

---

## 4. M2 — ADS, Tracking, CAPI, Stape e CRM-to-Ads

Responsável por rastrear origem, eventos e qualidade dos leads, conectando CRM às plataformas de mídia.

Inclui:

- Meta Ads;
- Google Ads;
- Pixel;
- Meta CAPI;
- GTM Web;
- Stape/GTM Server;
- Google Offline Conversions;
- Enhanced Conversions for Leads;
- UTMs;
- fbclid/fbp/fbc;
- gclid/gbraid/wbraid;
- deduplicação por event_id;
- CRM-to-Ads;
- SEO técnico;
- landing pages;
- maturidade digital do corretor.

Especialista principal: GPT 6.

---

## 5. M3 — MesaCliente, Tabelas e Propostas

Responsável pela simulação comercial imobiliária e geração de proposta.

Inclui:

- importação de tabelas de valores;
- parser PDF/CSV/XLSX;
- OCR assistido;
- cadastro de empreendimento;
- fotos;
- plantas;
- unidades;
- estoque;
- preço;
- fluxo de pagamento;
- simulação;
- proposta;
- histórico;
- 2ª via;
- validação financeira;
- segurança contra proposta inválida.

Especialista principal: GPT 8.

---

## 6. M4 — Integrações, Portais e Mensageria

Responsável por entrada e saída de dados por canais externos.

Inclui:

- ZAP Imóveis;
- VivaReal;
- Imovelweb;
- outros portais imobiliários;
- Meta Leads;
- Google Leads;
- webhooks;
- Make/n8n;
- e-mail parser;
- WhatsApp oficial;
- WhatsApp não oficial como risco controlado;
- compartilhamento mobile;
- normalização de payloads;
- roteamento por corretor;
- logs de integração.

Especialista principal: GPT 9.

---

## 7. M5 — Dashboards, Observabilidade e Operação

Responsável por visibilidade operacional, suporte e saúde do SaaS.

Inclui:

- dashboard do corretor;
- dashboard do gestor;
- dashboard do admin;
- dashboard de campanha;
- dashboard de infraestrutura;
- logs;
- alertas;
- incidentes;
- métricas de uso;
- métricas de erro;
- SLA/SLI/SLO;
- RTO/RPO;
- suporte N1/N2/N3.

Especialista principal: GPT 5.

Apoio por contexto:

- campanhas: GPT 6;
- CRM/discador: GPT 7;
- MesaCliente: GPT 8;
- integrações: GPT 9;
- monetização: GPT 10;
- UX: GPT 2.

---

## 8. M6 — Monetização, Planos e Go-to-Market

Responsável por transformar o produto em negócio SaaS vendável.

Inclui:

- planos;
- pricing;
- MRR/ARR;
- CAC;
- LTV;
- churn;
- payback;
- margem;
- módulos premium;
- ICP;
- proposta comercial;
- piloto pago;
- onboarding;
- pitch;
- investimento;
- expansão para corretor, imobiliária e incorporadora.

Especialista principal: GPT 10.

---

## 9. Regra de classificação de demanda

Toda nova demanda deve ser classificada antes da execução:

```text
1. Qual módulo é afetado?
2. Qual especialista principal deve analisar?
3. Quais especialistas horizontais devem apoiar?
4. Há impacto em banco, RLS, MesaCliente, tracking, produção ou LGPD?
5. Precisa de PR, preview, testes e rollback?
```

---

## 10. Regra de prioridade

Prioridade deve considerar:

- valor comercial imediato;
- redução de atrito do corretor;
- risco técnico;
- dependência de terceiros;
- impacto multi-tenant;
- capacidade de monetização;
- evidência de uso real;
- custo operacional;
- observabilidade disponível.
