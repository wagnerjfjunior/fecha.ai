# FECH.AI — Camada Vertical de Aplicação

**Status:** v1.0 — visão inicial da camada vertical  
**Escopo:** módulos de aplicação do FECH.AI e relação com GPTs especialistas verticais.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Objetivo

Este documento organiza a camada vertical de aplicação do FECH.AI, separando os módulos de negócio que compõem o app completo.

A camada horizontal já cobre arquitetura, UX/UI, Supabase, CI/CD, observabilidade e ADS/tracking.

A camada vertical organiza os domínios de aplicação usados por corretores, gestores, admins, imobiliárias e incorporadoras.

---

## 2. Camada horizontal existente

```text
GPT 1: FECH.AI Arquiteto SaaS
GPT 2: FECH.AI — UX/UI APP Specialist
GPT 3: FECH.AI — Supabase Security Specialist
GPT 4: FECH.AI — Vercel/GitHub CI-CD Specialist
GPT 5: FECH.AI-SRE-DevSecOps Observ Specialist
GPT 6: FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta
```

---

## 3. Camada vertical proposta

```text
GPT 7: FECH.AI — LeadOps CRM Discador Specialist
GPT 8: FECH.AI — MesaCliente Tabelas Propostas Specialist
GPT 9: FECH.AI — Integrações Portais Mensageria Specialist
GPT 10: FECH.AI — Monetização Startup GTM Specialist
```

---

## 4. Módulo 1 — LeadOps, CRM e Discador

Cobre:

- carregamento de listas em múltiplos formatos;
- upload por gestor, corretor e admin;
- CSV, XLSX, PDF, texto, imagem e foto;
- OCR de lista de papel;
- importação de lista compartilhada pelo WhatsApp;
- experiência de compartilhamento iOS/Android quando viável;
- deduplicação;
- higienização de telefone;
- funil/CRM;
- discador;
- WhatsApp/manual;
- Power Mode;
- taxa de conversão;
- dashboard de agendamentos para o fim de semana;
- produtividade do corretor.

GPT principal: GPT 7.

---

## 5. Módulo 2 — MesaCliente, Tabelas e Propostas

Cobre:

- importação de tabelas de valores de imóveis;
- PDF, CSV, XLSX, imagem/OCR;
- parser de tabelas;
- cadastro de empreendimentos;
- fotos;
- plantas;
- unidades;
- preços;
- fluxo de pagamento;
- simulações;
- propostas;
- histórico e 2ª via;
- segurança contra proposta inválida.

GPT principal: GPT 8.

---

## 6. Módulo 3 — Integrações, Portais e Mensageria

Cobre:

- ZAP Imóveis;
- VivaReal;
- Imovelweb;
- outros portais imobiliários;
- Meta Leads;
- Google Leads;
- webhooks;
- Make/n8n;
- WhatsApp oficial;
- WhatsApp não oficial apenas como risco controlado/experimental;
- mensagens automáticas em fase futura;
- normalização de payloads;
- roteamento por corretor;
- logs e falhas de integração.

GPT principal: GPT 9.

---

## 7. Módulo 4 — Monetização, Startup e Go-to-Market

Cobre:

- planos SaaS;
- pricing;
- MRR/ARR;
- CAC;
- LTV;
- churn;
- payback;
- margem;
- módulos premium;
- validação de mercado;
- pilotos;
- ICP;
- posicionamento;
- pitch;
- investimento;
- venda para corretores, imobiliárias e incorporadoras.

GPT principal: GPT 10.

---

## 8. Relação entre camadas

A camada vertical não substitui os especialistas horizontais.

Exemplos:

- LeadOps precisa de UX, Supabase, observabilidade e ADS quando envolve CRM-to-Ads.
- MesaCliente precisa de arquitetura, UX, Supabase e observabilidade.
- Integrações precisam de CI/CD, Supabase, observabilidade e segurança.
- Monetização precisa de dados de uso, custos, margem e validação real.

---

## 9. Roadmap funcional sugerido

### Fase 1 — MVP operacional

- importar lista;
- ligar;
- chamar no WhatsApp;
- registrar status;
- funil básico;
- Power Mode simples;
- dashboard de visitas/agendamentos.

### Fase 2 — Tracking e campanhas

- Meta leads;
- Google leads;
- UTMs;
- Stape/GTM Server;
- Meta CAPI;
- Google Offline Conversions;
- CRM-to-Ads;
- dashboard de campanha.

### Fase 3 — MesaCliente

- importar tabela;
- cadastrar empreendimento;
- fotos/plantas;
- fluxo de pagamento;
- proposta;
- histórico.

### Fase 4 — Portais e mensageria

- ZAP/VivaReal/Imovelweb;
- WhatsApp oficial;
- webhooks;
- Make/n8n;
- normalização de payloads.

### Fase 5 — Automação inteligente

- mensagens automáticas;
- recomendação de campanha;
- alerta diário;
- sugestão de copy, público e criativo;
- orientação para pausar ou ajustar campanha.

### Fase 6 — Monetização e escala

- planos;
- pilotos pagos;
- cases;
- prova de tração;
- pitch investidor;
- expansão para imobiliárias e incorporadoras.

---

## 10. Regra de governança

Qualquer módulo vertical que impactar banco, autenticação, RLS, RPCs, produção, MesaCliente, parser, motor financeiro, integrações críticas, LGPD ou regra comercial deve acionar o GPT 1 e os especialistas horizontais correspondentes.

Produção não deve ser tratada como laboratório.
