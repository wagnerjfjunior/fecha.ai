# FECH.AI — Registro Oficial de GPTs Especialistas

**Status:** v1.0 — registro operacional  
**Escopo:** organização dos GPTs auxiliares do FECH.AI.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Regra principal

O projeto principal do ChatGPT continua sendo a fonte central de contexto, decisão e continuidade do FECH.AI.

Os GPTs especialistas são auxiliares. Eles não substituem o Master Project, não decidem isoladamente alterações sensíveis e não devem contradizer a documentação oficial vigente, o banco real/Supabase aplicado ou decisões diretas do Wagner.

---

## 2. Ordem oficial dos GPTs

```text
GPT 1: FECH.AI — Arquiteto SaaS
GPT 2: FECH.AI — UX/UI APP Specialist
GPT 3: FECH.AI — DevSecOps Stack Specialist
GPT 4: FECH.AI — ADS, Pixel, CAPI e SEO
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

## 5. GPT 3 — FECH.AI DevSecOps Stack Specialist

Responsável por:

- Supabase;
- Vercel;
- GitHub;
- CI/CD;
- segurança;
- observabilidade;
- SLA, SLI e SLO;
- RTO e RPO;
- backup e restore;
- runbooks;
- incidentes;
- deploy seguro;
- rollback operacional.

Deve ser acionado quando houver alteração ou falha envolvendo infraestrutura, banco, autenticação, produção, deploy, logs, alertas, secrets ou continuidade de negócio.

---

## 6. GPT 4 — FECH.AI ADS, Pixel, CAPI e SEO

Responsável por:

- Meta Ads;
- Google Ads;
- Pixel;
- API de Conversões;
- UTMs;
- deduplicação com event_id;
- origem do lead;
- tracking server-side;
- SEO técnico;
- landing pages;
- atribuição;
- diagnóstico de maturidade digital do corretor;
- tradução de melhoria técnica em valor comercial.

Deve ser acionado quando a demanda envolver campanha, captação, conversão, atribuição, tráfego pago, SEO, Meta, Google ou landing page.

---

## 7. Relação com Codex, GitHub e deploy

A análise e decisão acontecem no projeto principal e nos GPTs especialistas.

A implementação real deve seguir:

```text
análise → plano → Codex → branch GitHub → Pull Request → preview Vercel → validação → merge → deploy → changelog
```

Produção não deve ser tratada como laboratório.

---

## 8. Regra de atualização

Sempre que a ordem, função ou escopo de um GPT mudar, atualizar este arquivo e, quando necessário, os documentos individuais em `docs/skills/`.
