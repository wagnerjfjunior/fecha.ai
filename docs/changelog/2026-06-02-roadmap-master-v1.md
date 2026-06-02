# Changelog — Roadmap Mestre FECH.AI v1

**Data:** 2026-06-02  
**Tipo:** documentação, produto e governança  
**Branch:** `docs/roadmap-master-v1`

---

## Resumo

Criação do Roadmap Mestre v1 do FECH.AI, consolidando módulos, fases de MVP e critérios de priorização.

---

## Arquivos criados

```text
docs/roadmap/fechai-roadmap-master-v1.md
docs/product/fechai-modules-map-v1.md
docs/product/fechai-mvp-scope-v1.md
docs/changelog/2026-06-02-roadmap-master-v1.md
```

---

## Justificativa

Após a criação dos GPTs especialistas horizontais e verticais, o FECH.AI precisa de um roadmap mestre para evitar dispersão de escopo.

O roadmap define a ordem recomendada:

```text
Fase 1 — MVP Operacional / LeadOps CRM Discador
Fase 2 — Tracking ADS/CAPI/Stape/CRM-to-Ads
Fase 3 — MesaCliente / Tabelas / Propostas
Fase 4 — Integrações / Portais / Mensageria
Fase 5 — Automação Inteligente de Campanhas e Mensagens
Fase 6 — Monetização, Pilotos e Escala
```

---

## Impacto

Documentação apenas.

Não altera código, banco, Supabase, RLS, RPCs, migrations, Vercel, GitHub Actions, Make/n8n, MesaCliente, parser, motor financeiro, regras comerciais, produção, ADS, CAPI, integrações reais ou automações.

---

## Validação

Validar que:

- a Fase 1 prioriza uso diário do corretor;
- o MVP v1 é pequeno o bastante para execução real;
- o roadmap preserva Stape como caminho inicial para tracking;
- MesaCliente continua protegido como módulo crítico;
- monetização e pilotos aparecem como fase explícita;
- todas as fases seguem governança com PR, preview, testes, changelog e rollback.

---

## Rollback

Rollback documental:

1. Remover os documentos criados nesta PR.
2. Restaurar o estado anterior da documentação de roadmap/produto.
