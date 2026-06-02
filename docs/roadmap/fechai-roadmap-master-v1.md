# FECH.AI — Roadmap Mestre v1

**Status:** v1.0 — roadmap inicial de produto  
**Data:** 2026-06-02  
**Escopo:** organização dos módulos, fases de MVP, ordem de execução e relação com GPTs especialistas.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Objetivo

Este roadmap organiza a evolução do FECH.AI como SaaS imobiliário completo, evitando dispersão entre CRM, Discador, MesaCliente, ADS/CAPI, integrações, dashboards, monetização e startup.

A meta é construir um produto vendável, seguro, multi-tenant, observável e com valor diário para corretores, imobiliárias e incorporadoras.

---

## 2. Princípio de execução

O FECH.AI deve nascer com foco operacional antes de sofisticar automações.

Ordem lógica:

```text
executar → medir → melhorar → automatizar → escalar
```

Não antecipar engenharia pesada antes de validar uso real e disposição a pagar.

---

## 3. Camadas de especialistas

### Camada horizontal

```text
GPT 1: FECH.AI Arquiteto SaaS
GPT 2: FECH.AI — UX/UI APP Specialist
GPT 3: FECH.AI — Supabase Security Specialist
GPT 4: FECH.AI — Vercel/GitHub CI-CD Specialist
GPT 5: FECH.AI-SRE-DevSecOps Observ Specialist
GPT 6: FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta
```

### Camada vertical

```text
GPT 7: FECH.AI — LeadOps CRM Discador Specialist
GPT 8: FECH.AI — MesaCliente Tabelas Propostas Specialist
GPT 9: FECH.AI — Integrações Portais Mensageria Specialist
GPT 10: FECH.AI — Monetização Startup GTM Specialist
```

---

## 4. Fase 1 — MVP Operacional / LeadOps CRM Discador

**Objetivo:** permitir que o corretor importe leads/listas e execute contato com poucos cliques.

Inclui:

- importação de listas por CSV/XLSX;
- importação por texto colado;
- importação por foto/OCR com revisão humana;
- deduplicação básica;
- validação de telefone;
- funil CRM mínimo;
- botão ligar;
- botão WhatsApp/manual;
- registro rápido de status;
- Power Mode simples;
- dashboard de agendamentos para o fim de semana;
- métricas de produtividade do corretor.

GPT principal: GPT 7.  
Apoio: GPT 1, GPT 2, GPT 3, GPT 5.

Critério de sucesso inicial:

```text
corretor consegue importar uma lista, ligar, enviar WhatsApp, registrar status e visualizar quantas visitas conseguiu agendar para o fim de semana.
```

---

## 5. Fase 2 — Tracking ADS/CAPI/Stape/CRM-to-Ads

**Objetivo:** conectar campanhas, landing pages e CRM para melhorar rastreabilidade e envio de sinais qualificados.

Inclui:

- padrão UTM oficial;
- captura de IDs de clique: fbclid, fbp, fbc, gclid, gbraid, wbraid;
- GTM Web;
- Stape/GTM Server como caminho inicial;
- Meta Pixel + Meta CAPI;
- Google Offline Conversions;
- Enhanced Conversions for Leads quando aplicável;
- CRM-to-Ads com eventos qualificados;
- dashboard de origem e conversão;
- observabilidade de eventos e falhas.

GPT principal: GPT 6.  
Apoio: GPT 1, GPT 3, GPT 5, GPT 7.

Critério de sucesso inicial:

```text
lead entra com origem rastreável, vira status qualificado no CRM e pode alimentar Meta/Google com evento qualificado de forma segura e mensurável.
```

---

## 6. Fase 3 — MesaCliente / Tabelas / Propostas

**Objetivo:** permitir que o corretor importe tabela de valores, cadastre empreendimento e monte fluxo de pagamento/proposta com segurança.

Inclui:

- importação de tabelas PDF/CSV/XLSX;
- leitura assistida/OCR quando necessário;
- validação de campos obrigatórios;
- cadastro de empreendimento;
- fotos e plantas;
- unidades, metragens, vagas, preços e estoque;
- fluxo de pagamento;
- simulação;
- proposta;
- histórico e 2ª via;
- testes de cálculo e segurança comercial.

GPT principal: GPT 8.  
Apoio: GPT 1, GPT 2, GPT 3, GPT 5.

Critério de sucesso inicial:

```text
corretor consegue importar tabela validada, escolher unidade, montar fluxo de pagamento e gerar proposta sem inconsistência financeira.
```

---

## 7. Fase 4 — Integrações / Portais / Mensageria

**Objetivo:** receber leads externos, normalizar payloads e estruturar mensageria de forma segura.

Inclui:

- Meta Leads;
- Google Leads;
- ZAP Imóveis;
- VivaReal;
- Imovelweb;
- outros portais;
- webhooks;
- Make/n8n;
- e-mail parser quando necessário;
- WhatsApp oficial;
- WhatsApp não oficial apenas como risco controlado/experimental;
- compartilhamento mobile via PWA/Web Share Target ou app futuro;
- normalização de payloads;
- logs e alertas de falha.

GPT principal: GPT 9.  
Apoio: GPT 1, GPT 3, GPT 4, GPT 5, GPT 7.

Critério de sucesso inicial:

```text
lead externo entra no FECH.AI com origem clara, sem duplicidade crítica, roteado corretamente e com log de integração.
```

---

## 8. Fase 5 — Automação Inteligente de Campanhas e Mensagens

**Objetivo:** evoluir de execução manual para orientação e automação assistida.

Inclui:

- envio automático de mensagem em fase controlada;
- templates e cadências;
- recomendações de campanha;
- alerta para pausar campanha;
- sugestão de troca de copy, público ou criativo;
- análise diária de logs de campanha;
- recomendações baseadas em CPL, lead qualificado, visitas e proposta.

GPT principal: GPT 6.  
Apoio: GPT 7, GPT 9, GPT 10, GPT 5.

Critério de sucesso inicial:

```text
o sistema identifica campanha com baixa qualidade ou baixo retorno e recomenda ação clara ao corretor/gestor.
```

---

## 9. Fase 6 — Monetização, Pilotos e Escala

**Objetivo:** transformar o produto em SaaS validado comercialmente.

Inclui:

- planos e pricing;
- piloto pago;
- onboarding assistido;
- proposta para corretor autônomo;
- proposta para imobiliária;
- proposta para incorporadora;
- métricas SaaS: MRR, CAC, LTV, churn, payback e margem;
- pitch deck;
- validação para investimento;
- cases de uso e tração.

GPT principal: GPT 10.  
Apoio: GPT 1, GPT 5, GPT 6, GPT 7, GPT 8.

Critério de sucesso inicial:

```text
primeiros usuários pagantes usando o FECH.AI semanalmente e gerando métricas suficientes para validar ICP, preço e retenção.
```

---

## 10. Não escopar agora

Não priorizar no MVP inicial:

- gateway próprio completo para substituir Stape;
- automação total de campanhas sem supervisão;
- WhatsApp não oficial como base crítica;
- múltiplos portais antes do funil básico funcionar;
- dashboards sofisticados antes de eventos confiáveis;
- app nativo antes de validar PWA/fluxo web;
- IA autônoma tomando decisão de campanha sem aprovação humana.

---

## 11. Governança

Toda implementação deve seguir:

```text
análise → plano → Codex → branch GitHub → PR → preview Vercel → validação → merge → deploy → smoke test → monitoramento → changelog → rollback documentado
```

Mudanças críticas em Supabase, RLS, RPCs, MesaCliente, parser, motor financeiro, tracking, integrações, autenticação ou produção exigem aprovação explícita do GPT 1 e especialistas envolvidos.
