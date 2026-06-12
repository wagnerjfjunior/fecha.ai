# FECH.AI — Bootstrap Governance Cycle Handoff

**Status:** HANDOFF / DOCUMENTATION_ONLY / NO_RUNTIME_CHANGE  
**Date:** 2026-06-12  
**Scope:** Registro operacional do ciclo documental #85–#90.  

---

## 1. Objetivo

Registrar a consolidação documental do ciclo de governança FECH.AI que estruturou:

```text
- arquitetura SaaS / Edge Functions;
- modus operandi obrigatório;
- README como entrada para índices canônicos;
- GreenOps / Codex Efficiency;
- alinhamento dos GPTs especialistas GPT0-GPT10.
```

Este documento é um handoff para novas conversas, validações de PR, decisões técnicas e uso dos GPTs especialistas.

---

## 2. PRs consolidadas

```text
#85 — docs(architecture): add Edge Functions context and index
#86 — docs(bootstrap): add FECH.AI specialist modus operandi
#87 — docs(readme): point to bootstrap and architecture indexes
#88 — docs(bootstrap): add Codex efficiency and GreenOps workflow
#89 — docs(skills): align GPT specialists with modus operandi
#90 — docs(skills): align remaining GPT specialists with modus operandi
```

---

## 3. Estado consolidado

### #85 — Arquitetura / Edge Functions / SaaS context

Estabeleceu contexto documental para Edge Functions, Vercel API/proxy, camada SaaS e segurança arquitetural.

### #86 — Modus Operandi dos especialistas

Estabeleceu o padrão obrigatório de operação antes de agir:

```text
- Contexto entendido;
- Módulo/fluxo afetado;
- Ambiente;
- PR/branch/head/commit;
- Arquivos/áreas envolvidas;
- Decisões anteriores relevantes;
- Riscos principais;
- O que NÃO deve ser alterado;
- Evidências disponíveis;
- Evidências ausentes;
- Próxima ação segura.
```

### #87 — README como ponto de entrada

Consolidou o README como entrada para os índices canônicos:

```text
- docs/bootstrap/INDEX.md
- docs/audits/architecture/INDEX.md
```

### #88 — Codex Efficiency / GreenOps

Definiu uso econômico, ecológico e operacionalmente eficiente de ChatGPT, GitHub connector e Codex.

### #89 — GPT1-GPT4 alinhados

Alinhou:

```text
GPT1 — FECH.AI Arquiteto SaaS
GPT2 — FECH.AI UX/UI APP Specialist
GPT3 — FECH.AI Supabase Security Specialist
GPT4 — FECH.AI Vercel/GitHub CI-CD Specialist
```

### #90 — GPT0 e GPT5-GPT10 alinhados

Alinhou:

```text
GPT0 — FECH.AI Documentation Auditor
GPT5 — FECH.AI SRE/DevSecOps Observability Specialist
GPT6 — FECH.AI ADS, Pixel, CAPI e SEO
GPT7 — FECH.AI LeadOps CRM Discador Specialist
GPT8 — FECH.AI MesaCliente Tabelas Propostas Specialist
GPT9 — FECH.AI Integrações Portais Mensageria Specialist
GPT10 — FECH.AI Monetização Startup GTM Specialist
```

---

## 4. Regras consolidadas

### Fonte central

O FECH.AI — Projeto Principal / Master Project continua sendo a fonte central de contexto, decisão, arquitetura, documentação e continuidade.

### Postura Pilot Production

O FECH.AI deve ser tratado como Pilot Production SaaS multi-tenant / multiempresa, com usuários reais, dados sensíveis e hardening em andamento.

### Princípio central

```text
Frontend solicita e exibe.
Backend/RPC/Supabase valida e decide.
IA auxilia, mas não é autoridade.
```

### Fail-closed

Sem sessão, token, permissão, tenant/empresa/perfil consistente ou evidência suficiente, não aprovar cegamente.

### Disciplina de PR

```text
Uma PR = um risco principal = um rollback simples.
```

### Classificação de achados

```text
BLOCKING
REQUIRED IN THIS PR
ACCEPTABLE WITH RESIDUAL RISK
PLANNED FUTURE PR
NOT RELEVANT TO THIS SCOPE
```

### GreenOps

Antes de gastar tokens, créditos ou acionar Codex:

```text
- verificar README/index/bootstrap;
- usar PR metadata, changed files e diff;
- usar GitHub connector antes de Codex quando suficiente;
- reduzir escopo;
- evitar varredura ampla sem necessidade;
- deixar handoff quando mudar contexto.
```

---

## 5. Próxima conversa deve começar por

```text
1. Ler docs/bootstrap/INDEX.md.
2. Identificar módulo/fluxo.
3. Confirmar PR/branch/head/diff, se houver.
4. Separar evidência, inferência e lacuna.
5. Classificar riscos.
6. Definir próxima ação segura.
```

---

## 6. Fora do escopo deste ciclo

Este ciclo não alterou:

```text
runtime;
frontend;
Supabase;
migrations;
RLS;
grants;
policies;
RPC bodies;
Edge Functions;
Vercel runtime;
GitHub Actions;
MesaCliente runtime;
ADS/CAPI runtime;
Make/n8n;
produção.
```

---

## 7. Rollback documental

Cada PR do ciclo pode ser revertida individualmente.

Para rollback conceitual completo do ciclo documental, reverter as PRs em ordem inversa:

```text
#90 -> #89 -> #88 -> #87 -> #86 -> #85
```

---

## 8. Próximo passo recomendado

Após este handoff, o próximo avanço técnico deve voltar ao fluxo normal:

```text
PR pequena;
um risco principal;
rollback simples;
evidência real;
sem overclaim;
sem mudança sensível sem Security Go.
```
