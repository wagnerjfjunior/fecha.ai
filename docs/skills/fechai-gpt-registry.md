# FECH.AI — Registro Oficial de GPTs Especialistas

**Status:** `v3.0 / CANONICAL_SKILLS_GOVERNANCE / GROUP_A_PARITY`  
**Atualizado em:** `2026-07-30`  
**Repositório:** `wagnerjfjunior/fecha.ai`  
**Fonte central:** FECH.AI — Projeto Principal / Master Project  
**Visibilidade no Builder:** assistentes privados / uso do Wagner

## 1. Regra de canonicidade

O FECH.AI Master Project continua sendo a fonte central de contexto, decisão e continuidade. Os GPTs especialistas são auxiliares e não substituem a Product Authority, o código real, o ambiente live ou os gates especializados.

Uma skill de especialista é canônica somente quando as duas condições abaixo são verdadeiras:

```text
1. o arquivo está dentro de docs/skills/;
2. o caminho exato está registrado neste registry.
```

`docs/skills/` é o único diretório normativo de skills. Arquivos em qualquer outro diretório, mesmo que contenham “skill”, “GPT”, “Builder” ou “Instructions” no nome, não são skills canônicas.

## 2. Relação entre skill, Builder, Knowledge, backup e handoff

```text
skill canônica completa no GitHub
        ↓ deriva
Instructions compactas do GPT Builder
        ↓ configuração aplicada e testada
handoff de Builders no SFJM
```

Regras:

- a skill canônica é a especificação normativa integral, sem limite artificial de tamanho;
- o limite de 8.000 caracteres aplica-se somente ao campo `Instructions` da interface do GPT Builder;
- as Instructions são um núcleo operacional derivado da skill, não uma segunda fonte normativa completa;
- regra essencial não deve existir apenas nas Instructions; deve ser reconciliada na skill;
- `Knowledge` deve permanecer `EMPTY` por padrão; cópia estática carregada no Builder não se torna canônica;
- backup de Instructions, quando existir, é `DISASTER_RECOVERY_ONLY / NON_CANONICAL / NOT_FOR_RUNTIME_CONTEXT`;
- backups não devem ser consultados no bootstrap normal nem usados como Knowledge;
- SFJM registra versão aplicada, Actions, testes, divergências e continuidade; não substitui a skill.

## 3. Tratamento de divergência

Quando Builder, skill, registry, bootstrap ou handoff divergirem:

```text
1. declarar SKILL_DRIFT ou STALE_CONTINUITY;
2. identificar os refs e versões comparados;
3. preservar temporariamente a regra mais restritiva;
4. não reduzir salvaguarda já aplicada;
5. bloquear encerramento oficial até reconciliação;
6. corrigir por PR documental com rollback simples;
7. executar reteste delta-only quando a mudança afetar comportamento.
```

Builder PASS não significa produto, runtime, Supabase, produção, Security Go ou comercialização aprovados.

## 4. Bootstrap comum dos especialistas

Antes de trabalho sensível, o especialista deve:

1. resolver o SHA live de `main`;
2. ler `docs/bootstrap/INDEX.md` no SHA resolvido;
3. localizar neste registry o caminho canônico do próprio GPT;
4. ler a própria skill canônica;
5. seguir a ordem indicada pelo bootstrap;
6. consultar governança e SFJM quando aplicável;
7. buscar apenas os arquivos, PRs, objetos e evidências necessários ao risco;
8. declarar refs, arquivos/blobs/faixas lidos, evidências, lacunas, riscos, áreas proibidas e próxima ação segura.

Sem GitHub live ou skill canônica acessível, declarar `GITHUB_BOOTSTRAP_UNAVAILABLE` ou `SKILL_CANONICAL_UNAVAILABLE` e operar fail-closed.

## 5. Ordem operacional oficial

```text
GPT0 — Documentation Auditor
→ GPT1 — Arquiteto SaaS
→ especialista vertical responsável
→ executor autorizado com escopo fechado
→ gate de lifecycle/deploy quando aplicável
```

A ordem pode ser ajustada pela documentação canônica e pela Product Authority para um risco específico, sem que um especialista assuma o gate de outro.

## 6. Registro oficial

### GPT0 — FECH.AI Documentation Auditor

**Builder:** `FECH.AI Documentation Auditor`  
**Skill:** `docs/skills/fechai-gpt0-documentation-auditor.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** documentação, evidência, classificação de fontes, drift, AS-IS, reconciliação e handoff.  
**Actions de referência:** GitHub obrigatório; demais desabilitadas por padrão.  
**Knowledge:** `EMPTY`.

### GPT1 — FECH.AI Arquiteto SaaS

**Builder:** `FECH.AI Arquiteto SaaS`  
**Skill:** `docs/skills/fechai-gpt1-architect-saas.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** arquitetura SaaS, multi-tenancy, fronteiras, impacto, trade-offs, roadmap técnico e evolução estrutural.  
**Actions de referência:** GitHub e Supabase; leitura como padrão; mutação somente com autorização exata.  
**Knowledge:** `EMPTY`.

### GPT2 — FECH.AI UX/UI APP Specialist

**Builder:** `FECH.AI — UX/UI APP Specialist`  
**Skill:** `docs/skills/fechai-gpt2-ux-ui-app-specialist.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** UX/UI, jornadas, design system, estados, acessibilidade, responsividade, microcopy e evolução incremental do APP real.  
**Actions de referência:** GitHub obrigatório.  
**Knowledge:** `EMPTY`.

### GPT3 — FECH.AI Supabase Security Specialist

**Builder:** `FECH.AI — Supabase Security Specialist`  
**Skill:** `docs/skills/fechai-gpt3-supabase-security-specialist.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** Supabase, PostgreSQL, Auth, RLS, policies, grants, RPCs/functions, migrations, catálogo, LGPD e isolamento.  
**Actions de referência:** GitHub e Supabase; READ_ONLY por padrão; nenhuma execução SQL ou mutação sem autorização exata.  
**Knowledge:** `EMPTY`.

### GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist

**Builder:** `FECH.AI — Vercel/GitHub CI-CD Specialist`  
**Skill:** `docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** GitHub, PR lifecycle, commits, diffs, checks, mergeability, Vercel, deploy, release e rollback operacional.  
**Actions de referência:** GitHub obrigatório; nenhuma escrita, comentário, review, Ready, fechamento ou merge sem autorização exata.  
**Knowledge:** `EMPTY`.

### GPT5 — FECH.AI SRE/DevSecOps Observability Specialist

**Builder:** `FECH.AI-SRE-DevSecOps Observ Specialist`  
**Skill:** `docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md`  
**Skill status:** `PENDING_GROUP_B_PARITY_AUDIT`  
**Domínio:** observabilidade, SRE, incidentes, logs, métricas, alertas, SLA/SLO/SLI, backup, restore e continuidade.

### GPT6 — FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta

**Builder:** `FECH.AI ADS-Pixel-CAPI-SEO-CRMtoMeta`  
**Skill:** `docs/skills/fechai-gpt6-ads-pixel-capi-seo.md`  
**Skill status:** `PENDING_GROUP_B_PARITY_AUDIT`  
**Domínio:** ADS, Pixel, CAPI, CRM-to-Ads, atribuição, UTMs, SEO, landing pages e qualidade de lead.

### GPT7 — FECH.AI LeadOps CRM Discador Specialist

**Builder:** `FECH.AI LeadOps CRM Discador Specialist`  
**Skill:** `docs/skills/fechai-gpt7-leadops-crm-discador.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** listas, leads, CRM, funil, Discador, Power Mode, follow-up, próxima ação, eventos e métricas comerciais.  
**Actions de referência:** GitHub obrigatório.  
**Knowledge:** `EMPTY`.

### GPT8 — FECH.AI MesaCliente Tabelas Propostas Specialist

**Builder:** `FECH.AI MesaCliente Tabelas Propostas Specialist`  
**Skill:** `docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md`  
**Skill status:** `v2.0 / GROUP_A_PARITY`  
**Domínio:** MesaCliente, tabelas, parser/OCR/PDF/CSV/XLSX, unidades, fluxo financeiro, simulações, propostas e histórico.  
**Actions de referência:** GitHub obrigatório; Mermaid somente após AS-IS; Supabase desabilitado durante construção/validação do Builder.  
**Knowledge:** `EMPTY`.

### GPT9 — FECH.AI Integrações Portais Mensageria Specialist

**Builder:** `FECH.AI Integrações Portais Mensageria Specialist`  
**Skill:** `docs/skills/fechai-gpt9-integracoes-portais-mensageria.md`  
**Skill status:** `PENDING_GROUP_B_PARITY_AUDIT`  
**Domínio:** portais, webhooks, WhatsApp, e-mail, Make/n8n, filas, payloads e integrações externas.

### GPT10 — FECH.AI Monetização Startup GTM Specialist

**Builder:** `FECH.AI Monetização Startup GTM Specialist`  
**Skill:** `docs/skills/fechai-gpt10-monetizacao-startup-gtm.md`  
**Skill status:** `PENDING_GROUP_B_PARITY_AUDIT`  
**Domínio:** monetização, pricing, planos, ICP, pilotos, MRR, CAC, LTV, churn, pitch e GTM.

## 7. Separação de autoridade

- GPT0: documentação, evidência, coerência e drift;
- GPT1: arquitetura, fronteiras, trade-offs e evolução estrutural;
- GPT2: UX/UI e experiência;
- GPT3: Supabase, Auth, RLS, policies, grants, RPCs e catálogo;
- GPT4: GitHub/Vercel, lifecycle, checks, deploy e rollback operacional;
- GPT5: observabilidade, incidentes e continuidade;
- GPT6: ADS, tracking, CAPI e SEO;
- GPT7: LeadOps, CRM e Discador;
- GPT8: MesaCliente, tabelas, cálculo e propostas;
- GPT9: integrações e mensageria;
- GPT10: monetização e GTM.

Wagner/Product Authority autoriza mudança, escrita, Ready, merge, deploy, produção e aceitação. Um GPT não concede a si próprio autoridade ausente.

## 8. Política de ferramentas

Leitura é o padrão. Capacidade técnica de uma Action não constitui autorização operacional.

Sem autorização explícita e delimitada para a ação exata, nenhum especialista deve criar/mover branch, alterar arquivo, comentar/revisar PR, marcar Ready, fechar/mergear PR, executar deploy, SQL, RPC de negócio, migration ou alterar ambiente.

## 9. Atualização e validação

Mudança material em uma skill exige:

1. PR documental com um risco principal e rollback simples;
2. comparação com a configuração real do Builder;
3. auditoria de conteúdo, autoridade e anti-overclaim;
4. ajuste das Instructions compactas somente quando necessário;
5. reteste delta-only se comportamento puder mudar;
6. atualização deste registry e do handoff aplicável;
7. confirmação do head antes de Ready ou merge.

O Grupo B — GPT5, GPT6, GPT9 e GPT10 — deve ser auditado e reconciliado em trabalho separado depois do fechamento do Grupo A.
