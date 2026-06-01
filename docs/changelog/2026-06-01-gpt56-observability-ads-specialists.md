# Changelog — GPT 5 e GPT 6 Specialists

**Data:** 2026-06-01  
**Tipo:** documentação e governança  
**Branch:** `docs/gpt56-observability-ads-specialists`

---

## Resumo

Criação documental dos especialistas GPT 5 e GPT 6 do FECH.AI:

```text
GPT 5: FECH.AI — SRE/DevSecOps Observability Specialist
GPT 6: FECH.AI — ADS, Pixel, CAPI e SEO
```

---

## Alterações

Arquivos criados:

```text
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md
```

---

## Justificativa

A arquitetura de especialistas foi separada para evitar um GPT operacional grande demais.

Separação definida:

- GPT 5 cuida de SRE, observabilidade, incidentes, SLA, SLI, SLO, logs, alertas, uptime, backup, restore, RTO, RPO, runbooks, custos e continuidade operacional.
- GPT 6 cuida de Meta Ads, Google Ads, Pixel, API de Conversões, UTMs, SEO, landing pages, atribuição, deduplicação por event_id e melhoria de campanhas imobiliárias.

O GPT 1 Arquiteto SaaS permanece como coordenador das decisões críticas e consolidador de conflitos entre especialistas.

---

## Impacto

Documentação apenas.

Não altera código, banco, Supabase, RLS, RPCs, migrations, Vercel, GitHub Actions, Make/n8n, MesaCliente, parser, motor financeiro, regras comerciais ou produção.

---

## Validação

Validar que:

- GPT 5 está focado em observabilidade, incidentes, SLA, backup, restore e continuidade;
- GPT 6 está focado em ADS, Pixel, CAPI, SEO, tracking, landing pages e atribuição;
- ambos acionam conceitualmente o GPT 1 quando houver impacto estrutural;
- GPT 5 respeita runbooks, N1/N2/N3 e severidade de incidentes;
- GPT 6 respeita LGPD, minimização de dados, consentimento, deduplicação e não promete resultado garantido;
- nenhum documento sugere alteração direta em produção sem aprovação.

---

## Rollback

Rollback documental:

1. Remover ou reverter os arquivos criados nesta alteração.
2. Restaurar modelo anterior, se necessário.
3. Atualizar `docs/skills/fechai-gpt-registry.md` após decisão.
