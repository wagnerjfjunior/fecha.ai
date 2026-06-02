# FECH.AI — Registro Oficial de GPTs Especialistas

**Status:** v1.3 — registro operacional com camada horizontal e vertical  
**Escopo:** organização dos GPTs auxiliares do FECH.AI.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Regra principal

O projeto principal do ChatGPT continua sendo a fonte central de contexto, decisão e continuidade do FECH.AI.

Os GPTs especialistas são auxiliares. Eles não substituem o Master Project, não decidem isoladamente alterações sensíveis e não devem contradizer a documentação oficial vigente, o banco real/Supabase aplicado ou decisões diretas do Wagner.

O GPT 1 — Arquiteto SaaS coordena as decisões críticas e consolida conflitos entre especialistas.

---

## 2. Ordem oficial dos GPTs

Os nomes abaixo devem refletir exatamente os nomes criados ou propostos para criação no Builder do ChatGPT.

### Camada horizontal — governança, tecnologia e tracking

```text
GPT 1: FECH.AI Arquiteto SaaS
GPT 2: FECH.AI — UX/UI APP Specialist
GPT 3: FECH.AI — Supabase Security Specialist
GPT 4: FECH.AI — Vercel/GitHub CI-CD Specialist
GPT 5: FECH.AI-SRE-DevSecOps Observ Specialist
GPT 6: FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta
```

### Camada vertical — aplicação e negócio

```text
GPT 7: FECH.AI — LeadOps CRM Discador Specialist
GPT 8: FECH.AI — MesaCliente Tabelas Propostas Specialist
GPT 9: FECH.AI — Integrações Portais Mensageria Specialist
GPT 10: FECH.AI — Monetização Startup GTM Specialist
```

---

## 3. GPT 1 — FECH.AI Arquiteto SaaS

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

Deve ser acionado quando houver impacto em:

- engine central;
- Supabase;
- RLS;
- RPCs;
- migrations;
- autenticação;
- MesaCliente;
- parser;
- motor financeiro;
- regras comerciais;
- produção;
- arquitetura multi-tenant;
- fluxo crítico do SaaS.

Documento base:

```text
docs/skills/fechai-gpt1-architect-saas.md
```

---

## 4. GPT 2 — FECH.AI — UX/UI APP Specialist

**Nome criado no Builder:** `FECH.AI — UX/UI APP Specialist`

Responsável por UX/UI do APP FECH.AI, jornadas do corretor/gestor/admin/suporte, design system, responsividade, acessibilidade, microcopy, estados de erro/loading/vazio/sucesso e critérios de aceite UX.

Documento base:

```text
docs/skills/fechai-gpt2-ux-ui-app-specialist.md
```

---

## 5. GPT 3 — FECH.AI — Supabase Security Specialist

**Nome criado no Builder:** `FECH.AI — Supabase Security Specialist`

Responsável por Supabase, PostgreSQL, Auth, RLS, policies, RPCs/functions, migrations, grants, storage, Edge Functions, performance, auditoria, LGPD e segurança multi-tenant.

Documento base:

```text
docs/skills/fechai-gpt3-supabase-security-specialist.md
```

---

## 6. GPT 4 — FECH.AI — Vercel/GitHub CI-CD Specialist

**Nome criado no Builder:** `FECH.AI — Vercel/GitHub CI-CD Specialist`

Responsável por Vercel, GitHub, branches, PRs, Actions, CI/CD, preview, production, env vars, secrets, deploy, rollback, releases, changelog e governança de release.

Documento base:

```text
docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md
```

---

## 7. GPT 5 — FECH.AI-SRE-DevSecOps Observ Specialist

**Nome criado no Builder:** `FECH.AI-SRE-DevSecOps Observ Specialist`

Responsável por SRE, observabilidade, SLA/SLI/SLO, error budget, incidentes, logs, métricas, alertas, uptime, backup, restore, RTO/RPO, runbooks, suporte N1/N2/N3, custos e continuidade operacional.

Documento base:

```text
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md
```

---

## 8. GPT 6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta

**Nome criado no Builder:** `FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta`

Responsável por Meta Ads, Google Ads, Pixel, Meta CAPI, Stape/GTM Server como caminho inicial, CRM-to-Ads, CRM-to-Meta, Google Offline Conversions, Enhanced Conversions for Leads, UTMs, deduplicação, SEO, landing pages, atribuição e maturidade digital do corretor.

Documento base:

```text
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md
```

---

## 9. GPT 7 — FECH.AI — LeadOps CRM Discador Specialist

**Nome proposto para o Builder:** `FECH.AI — LeadOps CRM Discador Specialist`

Responsável por carregamento de listas/leads, importação CSV/XLSX/PDF/texto/imagem, OCR de lista de papel, compartilhamento mobile/WhatsApp, deduplicação, higienização de telefone, funil CRM, Discador, WhatsApp/manual, Power Mode, produtividade, taxa de conversão e dashboard de agendamentos para o fim de semana.

Documento base:

```text
docs/skills/fechai-gpt7-leadops-crm-discador-specialist.md
```

---

## 10. GPT 8 — FECH.AI — MesaCliente Tabelas Propostas Specialist

**Nome proposto para o Builder:** `FECH.AI — MesaCliente Tabelas Propostas Specialist`

Responsável por MesaCliente, importação de tabelas de valores, parser/OCR/PDF/CSV/XLSX, cadastro de empreendimentos, unidades, fotos, plantas, preços, fluxo de pagamento, simulações, propostas, histórico, 2ª via e segurança comercial contra proposta inválida.

Documento base:

```text
docs/skills/fechai-gpt8-mesacliente-tabelas-propostas-specialist.md
```

---

## 11. GPT 9 — FECH.AI — Integrações Portais Mensageria Specialist

**Nome proposto para o Builder:** `FECH.AI — Integrações Portais Mensageria Specialist`

Responsável por ZAP Imóveis, VivaReal, Imovelweb, outros portais imobiliários, Meta Leads, Google Leads, webhooks, Make/n8n, WhatsApp oficial, WhatsApp não oficial como risco controlado, mensagens automáticas futuras, compartilhamento mobile, normalização de payloads, roteamento por corretor e logs de integração.

Documento base:

```text
docs/skills/fechai-gpt9-integracoes-portais-mensageria-specialist.md
```

---

## 12. GPT 10 — FECH.AI — Monetização Startup GTM Specialist

**Nome proposto para o Builder:** `FECH.AI — Monetização Startup GTM Specialist`

Responsável por monetização SaaS, planos, pricing, MRR, ARR, CAC, LTV, churn, payback, margem, módulos premium, validação de mercado, pilotos, ICP, posicionamento, pitch, investimento e venda para corretores, imobiliárias e incorporadoras.

Documento base:

```text
docs/skills/fechai-gpt10-monetizacao-startup-gtm-specialist.md
```

---

## 13. Relação com Codex, GitHub e deploy

A análise e decisão acontecem no projeto principal e nos GPTs especialistas.

A implementação real deve seguir:

```text
análise → plano → Codex → branch GitHub → Pull Request → preview Vercel → validação → merge → deploy → smoke test → monitoramento → changelog → rollback documentado
```

Produção não deve ser tratada como laboratório.

---

## 14. Regra de atualização

Sempre que a ordem, função ou escopo de um GPT mudar, atualizar este arquivo e, quando necessário, os documentos individuais em `docs/skills/`.

Alterações de documentação oficial, skills, arquitetura, Supabase, Vercel, GitHub, MesaCliente, engine ou regras centrais devem seguir branch, PR, revisão e changelog.
