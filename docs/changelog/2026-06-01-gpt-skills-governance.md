# Changelog — GPT Skills Governance

**Data:** 2026-06-01  
**Tipo:** documentação e governança  
**Branch:** `docs/gpt-skills-governance-update`

---

## Resumo

Formalização da governança dos GPTs especialistas do FECH.AI, com registro da ordem oficial dos GPTs e documentação dos GPTs 1 e 2.

---

## Alterações

Arquivos envolvidos:

```text
docs/skills/fechai-gpt-registry.md
docs/skills/fechai-gpt1-architect-saas.md
docs/skills/fechai-gpt2-ux-ui-app-specialist.md
```

---

## Ordem oficial registrada

```text
GPT 1: FECH.AI — Arquiteto SaaS
GPT 2: FECH.AI — UX/UI APP Specialist
GPT 3: FECH.AI — DevSecOps Stack Specialist
GPT 4: FECH.AI — ADS, Pixel, CAPI e SEO
```

---

## Justificativa

A governança dos GPTs precisa estar versionada no repositório para evitar divergência entre instruções do ChatGPT, documentação oficial e decisões futuras de produto.

A atualização corrige a ordem de especialistas, definindo o GPT 2 como especialista em UX/UI do APP, deixando DevSecOps como GPT 3 e ADS/CAPI/SEO como GPT 4.

---

## Impacto

Documentação apenas.

Não altera código, banco, Supabase, RLS, RPCs, migrations, Vercel, GitHub Actions, Make/n8n, MesaCliente, parser, motor financeiro, regras comerciais ou produção.

---

## Validação

Validar que:

- os documentos existem em `docs/skills/`;
- a ordem dos GPTs está consistente;
- o GPT 1 referencia corretamente o GPT 2 para demandas UX/UI;
- o GPT 2 preserva MesaCliente, parser, motor financeiro e regras comerciais.

---

## Rollback

Rollback documental:

1. Reverter os arquivos desta alteração.
2. Restaurar ordem anterior dos GPTs, se necessário.
3. Atualizar `docs/skills/fechai-gpt-registry.md`.
