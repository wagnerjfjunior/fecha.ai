# FECH.AI — Registro Oficial de GPTs Especialistas

**Status:** v1.1 — registro operacional atualizado  
**Escopo:** organização dos GPTs auxiliares do FECH.AI.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Regra principal

O projeto principal do ChatGPT continua sendo a fonte central de contexto, decisão e continuidade do FECH.AI.

Os GPTs especialistas são auxiliares. Eles não substituem o Master Project, não decidem isoladamente alterações sensíveis e não devem contradizer a documentação oficial vigente, o banco real/Supabase aplicado ou decisões diretas do Wagner.

O GPT 1 — Arquiteto SaaS coordena as decisões críticas e consolida conflitos entre especialistas.

---

## 2. Ordem oficial dos GPTs

```text
GPT 1: FECH.AI — Arquiteto SaaS
GPT 2: FECH.AI — UX/UI APP Specialist
GPT 3: FECH.AI — Supabase Security Specialist
GPT 4: FECH.AI — Vercel/GitHub CI-CD Specialist
GPT 5: FECH.AI — SRE/DevSecOps Observability Specialist
GPT 6: FECH.AI — ADS, Pixel, CAPI e SEO
```

---

## 3. GPT 1 — FECH.AI Arquiteto SaaS

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

## 4. GPT 2 — FECH.AI UX/UI APP Specialist

Responsável por:

- UX/UI do APP FECH.AI;
- jornada do corretor;
- jornada do gestor;
- jornada do admin;
- jornada do suporte;
- experiência do cliente final via MesaCliente/proposta;
- design system;
- fluxos;
- responsividade;
- acessibilidade;
- microcopy;
- estados de erro/loading/vazio/sucesso;
- critérios de aceite UX.

Deve respeitar integralmente:

- regras multi-tenant;
- permissões;
- segurança;
- LGPD;
- motor do app;
- MesaCliente;
- parser;
- motor financeiro;
- regras comerciais;
- rollback visual;
- validação pelo GPT 1 quando houver impacto estrutural.

Documento base:

```text
docs/skills/fechai-gpt2-ux-ui-app-specialist.md
```

---

## 5. GPT 3 — FECH.AI Supabase Security Specialist

Responsável por:

- Supabase;
- PostgreSQL;
- Auth;
- RLS;
- policies;
- RPCs/functions;
- migrations;
- grants;
- storage;
- Edge Functions;
- performance;
- auditoria;
- LGPD;
- segurança multi-tenant.

Deve ser acionado quando houver alteração ou falha envolvendo banco, Auth, RLS, policies, RPCs, migrations, grants, dados sensíveis, isolamento por tenant/empresa/perfil ou segurança Supabase.

Documento base:

```text
docs/skills/fechai-gpt3-supabase-security-specialist.md
```

---

## 6. GPT 4 — FECH.AI Vercel/GitHub CI-CD Specialist

Responsável por:

- Vercel;
- GitHub;
- branches;
- Pull Requests;
- Actions;
- CI/CD;
- preview;
- production;
- env vars;
- secrets;
- deploy;
- rollback;
- releases;
- changelog;
- governança de release.

Deve ser acionado quando houver alteração ou falha envolvendo branch, PR, merge, preview Vercel, deploy, build, env vars, secrets, production, releases, rollback ou changelog operacional.

Documento base:

```text
docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md
```

---

## 7. GPT 5 — FECH.AI SRE/DevSecOps Observability Specialist

Responsável por:

- SRE;
- observabilidade;
- SLA, SLI e SLO;
- error budget;
- incidentes;
- logs;
- métricas;
- alertas;
- uptime;
- backup;
- restore;
- RTO e RPO;
- runbooks;
- suporte N1/N2/N3;
- custos;
- continuidade operacional.

Deve ser acionado quando houver erro, incidente, indisponibilidade, lentidão, alerta, falha recorrente, necessidade de monitoramento, definição de SLA/SLO/SLI, backup, restore, RTO/RPO, runbook ou continuidade de negócio.

Documento base:

```text
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md
```

---

## 8. GPT 6 — FECH.AI ADS, Pixel, CAPI e SEO

Responsável por:

- Meta Ads;
- Google Ads;
- Pixel;
- Meta Conversions API;
- Stape/GTM Server como caminho inicial;
- CRM-to-Ads;
- Google Offline Conversions;
- Enhanced Conversions for Leads;
- UTMs;
- deduplicação com event_id;
- origem do lead;
- tracking server-side;
- SEO técnico;
- landing pages;
- atribuição;
- diagnóstico de maturidade digital do corretor;
- tradução de melhoria técnica em valor comercial.

Deve ser acionado quando a demanda envolver campanha, captação, conversão, atribuição, tráfego pago, SEO, Meta, Google, Pixel, CAPI, Stape/GTM Server, Google Offline Conversions, Enhanced Conversions, CRM-to-Ads, UTMs ou landing page.

Documento base:

```text
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md
```

---

## 9. Relação com Codex, GitHub e deploy

A análise e decisão acontecem no projeto principal e nos GPTs especialistas.

A implementação real deve seguir:

```text
análise → plano → Codex → branch GitHub → Pull Request → preview Vercel → validação → merge → deploy → smoke test → monitoramento → changelog → rollback documentado
```

Produção não deve ser tratada como laboratório.

---

## 10. Regra de atualização

Sempre que a ordem, função ou escopo de um GPT mudar, atualizar este arquivo e, quando necessário, os documentos individuais em `docs/skills/`.

Alterações de documentação oficial, skills, arquitetura, Supabase, Vercel, GitHub, MesaCliente, engine ou regras centrais devem seguir branch, PR, revisão e changelog.
