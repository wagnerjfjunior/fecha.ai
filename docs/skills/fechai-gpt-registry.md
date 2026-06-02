# FECH.AI — Registro Oficial de GPTs Especialistas

**Status:** v2.0 — registro operacional GPT 0 a GPT 10  
**Escopo:** organização oficial dos GPTs auxiliares do FECH.AI.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.  
**Visibilidade no Builder:** assistentes privados / apenas para uso do Wagner.

---

## 1. Regra principal

O FECH.AI — Projeto Principal / Master Project continua sendo a fonte central de contexto, decisão e continuidade do produto.

Os GPTs especialistas são auxiliares. Eles não substituem o projeto principal, não decidem isoladamente alterações sensíveis e não devem contradizer documentação oficial vigente, código real, Supabase aplicado, PRs aprovadas ou decisão direta do Wagner.

O GPT 0 deve ser acionado antes de qualquer mudança relevante quando houver dúvida documental, conflito de fonte, necessidade de AS-IS, reconciliação, auditoria, drift ou validação de evidência.

O GPT 1 coordena arquitetura, impacto e priorização depois da auditoria documental.

---

## 2. Ordem operacional oficial

```text
GPT 0 — FECH.AI Documentation Auditor
GPT 1 — FECH.AI Arquiteto SaaS
GPT 2 — FECH.AI UX/UI APP Specialist
GPT 3 — FECH.AI Supabase Security Specialist
GPT 4 — FECH.AI Vercel/GitHub CI-CD Specialist
GPT 5 — FECH.AI SRE/DevSecOps Observ Specialist
GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta
GPT 7 — FECH.AI LeadOps CRM Discador Specialist
GPT 8 — FECH.AI MesaCliente Tabelas Propostas Specialist
GPT 9 — FECH.AI Integrações Portais Mensageria Specialist
GPT 10 — FECH.AI Monetização Startup GTM Specialist
```

Fluxo operacional padrão:

```text
GPT 0 audita documentação/evidências
→ GPT 1 consolida arquitetura e impacto
→ GPT especialista aprofunda domínio
→ Codex/GitHub/Supabase/Vercel executam apenas com escopo aprovado
```

---

## 3. GPT 0 — FECH.AI Documentation Auditor

**Nome criado no Builder:** `FECH.AI Documentation Auditor`

Responsável por:

- auditoria documental;
- classificação de documentos;
- reconciliação docs x código x Supabase;
- identificação de drift;
- matriz AS-IS/GAP;
- separação entre estado atual e direção futura;
- validação de evidências antes de implementação;
- bloqueio documental quando faltar prova.

Deve ser acionado antes de alterações envolvendo Supabase, RLS, RPCs, MesaCliente, LeadOps, ADS/CAPI, Vercel, GitHub, segurança, App.jsx grande, documentação conflitante ou decisão antiga vs decisão atual.

Documento base:

```text
docs/skills/fechai-gpt0-documentation-auditor.md
```

---

## 4. GPT 1 — FECH.AI Arquiteto SaaS

**Nome criado no Builder:** `FECH.AI Arquiteto SaaS`

Responsável por:

- arquitetura geral;
- roadmap técnico;
- decisões críticas;
- impacto multi-tenant;
- segurança por desenho;
- governança técnica;
- aprovação antes de alteração sensível;
- rollback;
- changelog;
- critérios de aceite;
- coordenação dos demais GPTs.

Deve ser acionado quando houver impacto em engine central, Supabase, RLS, RPCs, migrations, autenticação, MesaCliente, parser, motor financeiro, regras comerciais, produção, arquitetura multi-tenant ou fluxo crítico do SaaS.

Documento base:

```text
docs/skills/fechai-gpt1-architect-saas.md
```

---

## 5. GPT 2 — FECH.AI UX/UI APP Specialist

**Nome criado no Builder:** `FECH.AI — UX/UI APP Specialist`

Responsável por UX/UI do APP FECH.AI, jornada do corretor, gestor, admin e suporte, design system, fluxos, responsividade, acessibilidade, microcopy, estados de erro/loading/vazio/sucesso e critérios de aceite UX.

Deve respeitar multi-tenancy, permissões, segurança, LGPD, motor do app, MesaCliente, parser, motor financeiro, regras comerciais e rollback visual.

Documento base:

```text
docs/skills/fechai-gpt2-ux-ui-app-specialist.md
```

---

## 6. GPT 3 — FECH.AI Supabase Security Specialist

**Nome criado no Builder:** `FECH.AI — Supabase Security Specialist`

Responsável por Supabase, PostgreSQL, Auth, RLS, policies, RPCs/functions, migrations, grants, storage, Edge Functions, performance, auditoria, LGPD e segurança multi-tenant.

Deve ser acionado quando houver alteração ou falha envolvendo banco, Auth, RLS, policies, RPCs, migrations, grants, dados sensíveis, isolamento por tenant/empresa/perfil ou segurança Supabase.

Documento base:

```text
docs/skills/fechai-gpt3-supabase-security-specialist.md
```

---

## 7. GPT 4 — FECH.AI Vercel/GitHub CI-CD Specialist

**Nome criado no Builder:** `FECH.AI — Vercel/GitHub CI-CD Specialist`

Responsável por Vercel, GitHub, branches, PRs, Actions, CI/CD, preview, production, env vars, secrets, deploy, rollback, releases, changelog e governança de release.

Deve ser acionado quando houver alteração ou falha envolvendo branch, PR, merge, preview Vercel, deploy, build, env vars, secrets, production, releases, rollback ou changelog operacional.

Documento base:

```text
docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md
```

---

## 8. GPT 5 — FECH.AI SRE/DevSecOps Observ Specialist

**Nome criado no Builder:** `FECH.AI-SRE-DevSecOps Observ Specialist`

Responsável por SRE, observabilidade, SLA, SLI, SLO, error budget, incidentes, logs, métricas, alertas, uptime, backup, restore, RTO/RPO, runbooks, suporte N1/N2/N3, custos e continuidade operacional.

Deve ser acionado quando houver erro, incidente, indisponibilidade, lentidão, alerta, falha recorrente, monitoramento, SLA/SLO/SLI, backup, restore, RTO/RPO, runbook ou continuidade de negócio.

Documento base:

```text
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md
```

---

## 9. GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta

**Nome criado no Builder:** `FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta`

Responsável por Meta Ads, Google Ads, Pixel, Meta CAPI, Stape/GTM Server, CRM-to-Ads, CRM-to-Meta, Google Offline Conversions, Enhanced Conversions for Leads, UTMs, event_id, deduplicação, origem do lead, tracking server-side, SEO, landing pages, atribuição e melhoria de campanhas imobiliárias.

Deve ser acionado quando a demanda envolver campanha, captação, conversão, atribuição, tráfego pago, SEO, Meta, Google, Pixel, CAPI, Stape/GTM Server, Google Offline Conversions, Enhanced Conversions, CRM-to-Ads, CRM-to-Meta, UTMs ou landing page.

Documento base:

```text
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md
```

---

## 10. GPT 7 — FECH.AI LeadOps CRM Discador Specialist

**Nome criado no Builder:** `FECH.AI LeadOps CRM Discador Specialist`

Responsável por captação/importação de listas e leads, OCR, CRM, funil, Discador, Power Mode, agendamentos, produtividade do corretor, conversão operacional e rotina comercial do FECH.AI.

Deve ser acionado quando a demanda envolver listas, importação CSV/XLSX/texto, foto/OCR, leads, funil comercial, status, ligação, WhatsApp, produtividade, agendamentos de fim de semana, Power Mode ou disciplina operacional do corretor.

Documento base:

```text
docs/skills/fechai-gpt7-leadops-crm-discador.md
```

---

## 11. GPT 8 — FECH.AI MesaCliente Tabelas Propostas Specialist

**Nome criado no Builder:** `FECH.AI MesaCliente Tabelas Propostas Specialist`

Responsável por MesaCliente, importação de tabelas de imóveis, parser/OCR/PDF, empreendimentos, unidades, fotos, plantas, fluxo de pagamento, simulações, propostas e segurança comercial.

Deve ser acionado quando a demanda envolver tabela de valores, leitura de PDF/CSV, parser, OCR de tabela, empreendimento, unidade, fluxo financeiro, proposta, simulação, motor financeiro, regra comercial ou apresentação ao cliente.

Documento base:

```text
docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md
```

---

## 12. GPT 9 — FECH.AI Integrações Portais Mensageria Specialist

**Nome criado no Builder:** `FECH.AI Integrações Portais Mensageria Specialist`

Responsável por integrações externas, portais imobiliários, ZAP, VivaReal, Imovelweb, Meta/Google Leads, webhooks, WhatsApp oficial/não oficial, Make/n8n, compartilhamento mobile e normalização de payloads.

Deve ser acionado quando a demanda envolver portais, webhooks, leads externos, integração com Meta/Google Lead Ads, WhatsApp API oficial/não oficial, Make, n8n, payloads, filas, normalização ou compartilhamento iOS/Android.

Documento base:

```text
docs/skills/fechai-gpt9-integracoes-portais-mensageria.md
```

---

## 13. GPT 10 — FECH.AI Monetização Startup GTM Specialist

**Nome criado no Builder:** `FECH.AI Monetização Startup GTM Specialist`

Responsável por monetização SaaS, planos, pricing, MRR, CAC, LTV, churn, validação de mercado, ICP, posicionamento, pilotos, vendas, pitch, investidores e go-to-market imobiliário do FECH.AI.

Deve ser acionado quando a demanda envolver plano comercial, precificação, modelo de assinatura, tier de produto, piloto, pitch, ICP, validação com corretores/incorporadoras/imobiliárias, GTM, CAC, LTV, churn, MRR, funding ou estratégia de startup.

Documento base:

```text
docs/skills/fechai-gpt10-monetizacao-startup-gtm.md
```

---

## 14. Relação com Codex, GitHub e deploy

A análise e decisão acontecem no projeto principal e nos GPTs especialistas.

A implementação real deve seguir:

```text
análise → auditoria documental → plano → Codex → branch GitHub → Pull Request → preview Vercel → validação → merge → deploy → smoke test → monitoramento → changelog → rollback documentado
```

Produção não deve ser tratada como laboratório.

---

## 15. Regra de atualização

Sempre que a ordem, função, nome ou escopo de um GPT mudar, atualizar este arquivo e, quando necessário, os documentos individuais em `docs/skills/`.

Alterações de documentação oficial, skills, arquitetura, Supabase, Vercel, GitHub, MesaCliente, engine ou regras centrais devem seguir branch, PR, revisão e changelog.
