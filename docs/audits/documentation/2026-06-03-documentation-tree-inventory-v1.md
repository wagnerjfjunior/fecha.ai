# FECH.AI — Inventário da Árvore Documental v1

**Data:** 2026-06-03  
**Status:** OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO  
**Base:** `main` após merge das PRs #48, #49 e #50 (`be943b1b3202943fdca03c6741e67018bae57a3c`)  
**Escopo:** varredura documental ampliada de `docs/`, com reconciliação do comentário Codex da PR #51.  
**Tipo:** documentação apenas; não altera código, banco, Supabase, Vercel, GitHub Actions ou produção.

---

## 1. Objetivo

Ampliar o inventário documental do FECH.AI para aproximar a visão da árvore real de `docs/`, identificando arquivos, diretórios, domínios e gaps que não apareceram ou não foram detalhados no Inventário Documental v1.

Este documento prepara as próximas auditorias específicas:

1. MesaCliente;
2. Supabase/RPC/RLS;
3. PME/Discador Flow AI;
4. código AS-IS;
5. matriz docs x código x Supabase.

---

## 2. Método de varredura

A varredura foi feita usando buscas no repositório GitHub por caminhos e domínios documentais.

Consultas aplicadas:

```text
path:docs .md
path:docs/skills .md
path:docs/mesa-cliente fase
path:docs/power-message-engine .md
path:docs/pme .md
path:docs/releases .md
path:docs/security
path:docs/product OR path:docs/roadmap OR path:docs/changelog OR path:docs/branches OR path:docs/protocolos
path:docs/04-banco-de-dados OR path:docs/02-arquitetura-tecnica OR path:docs/06-seguranca-compliance OR path:docs/modules OR path:docs/discador-flow-ai
path:docs/00-visao-executiva OR path:docs/01-produto OR path:docs/03-infraestrutura-cloud OR path:docs/05-observabilidade-ha
path:docs/07-operacao-suporte OR path:docs/08-comercial-monetizacao OR path:docs/09-financeiro-juridico-fiscal OR path:docs/10-roadmap-e-governanca
path:docs/checkpoints OR path:docs/main OR path:docs/protocolo
```

Limitação importante: esta varredura depende da busca/indexação do GitHub e não substitui um `git ls-tree -r --name-only main docs/` ou export local completo do repositório. Portanto, ela é ampliada e reconciliada com os diretórios apontados pelo Codex, mas continua marcada como `PENDENTE_RECONCILIACAO` até uma árvore Git completa ser gerada.

---

## 3. Correção aplicada após comentário Codex

O review automatizado do Codex apontou que a versão inicial deste inventário omitida diretórios inteiros existentes em `docs/`, incluindo:

```text
docs/00-visao-executiva/
docs/01-produto/
docs/03-infraestrutura-cloud/
docs/05-observabilidade-ha/
docs/07-operacao-suporte/
docs/08-comercial-monetizacao/
docs/09-financeiro-juridico-fiscal/
docs/10-roadmap-e-governanca/
docs/checkpoints/
docs/main/
docs/protocolo/
```

Correção nesta versão:

- os diretórios omitidos foram adicionados ao inventário;
- arquivos encontrados nesses diretórios foram listados quando identificados pela busca;
- o risco de inventário incompleto foi mantido como gap P2/P1 conforme impacto;
- o documento segue como `OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO` até export completo da árvore Git.

---

## 4. Diretórios documentais identificados

| Diretório | Domínio principal | Status | Observação |
|---|---|---:|---|
| `docs/` | M0 | OFICIAL_CANDIDATO | Entrada geral da documentação. |
| `docs/00-visao-executiva/` | M6/M0 | OFICIAL_CANDIDATO | Visão executiva, proposta de valor e pitch. |
| `docs/01-produto/` | M1/M2/M3 | OFICIAL_CANDIDATO | Jornada e produto. |
| `docs/02-arquitetura-tecnica/` | M0/M7 | OFICIAL_CANDIDATO | Arquitetura geral. |
| `docs/03-infraestrutura-cloud/` | M5/M8 | OFICIAL_CANDIDATO | Topologia cloud. |
| `docs/04-banco-de-dados/` | M7 | PENDENTE_RECONCILIACAO | Banco/RPCs dependem do Supabase real. |
| `docs/05-observabilidade-ha/` | M5 | OFICIAL_CANDIDATO | Observabilidade, HA e incidentes. |
| `docs/06-seguranca-compliance/` | M9 | PENDENTE_RECONCILIACAO | Segurança/LGPD precisam validação técnica/jurídica. |
| `docs/07-operacao-suporte/` | M5/M1 | OFICIAL_CANDIDATO | Operação, suporte e demonstração. |
| `docs/08-comercial-monetizacao/` | M6 | OFICIAL_CANDIDATO | Monetização, planos e proposta comercial. |
| `docs/09-financeiro-juridico-fiscal/` | M6/M9 | OFICIAL_CANDIDATO | Financeiro, jurídico, fiscal e tributário. |
| `docs/10-roadmap-e-governanca/` | M0/M6/M8 | OFICIAL_CANDIDATO | Backlog, dependências e due diligence. |
| `docs/audits/documentation/` | M0 | OFICIAL_CANDIDATO | Auditorias documentais. |
| `docs/branches/` | M8 | PENDENTE_RECONCILIACAO | Registro de branches precisa validar GitHub real. |
| `docs/changelog/` | M8/M0 | CHANGELOG | Histórico documental. |
| `docs/checkpoints/` | M3/M0 | CHECKPOINT | Checkpoints de MesaCliente/layout/engine. |
| `docs/main/` | M8/M0 | CHECKPOINT / OPERACIONAL | Logs, checklist e registry de main. |
| `docs/product/` | M1/M2/M6 | OFICIAL_CANDIDATO | Escopo e módulos de produto. |
| `docs/roadmap/` | M6 | OFICIAL_CANDIDATO | Roadmap, não prova implementação. |
| `docs/skills/` | M0 | OFICIAL_CANDIDATO | Registry e documentos dos GPTs especialistas. |
| `docs/protocolo/` | M3 | PENDENTE_RECONCILIACAO | Singular; possível trilha legada/protocolo específico MesaCliente. |
| `docs/protocolos/` | M0/M3 | POSSIVEL_DUPLICIDADE | Protocolos universais e MesaCliente. |
| `docs/security/` | M7/M9 | EVIDENCIA_VALIDACAO | Evidências e auditorias de segurança. |
| `docs/mesa-cliente/` | M3 | ALTO_VOLUME / P1 | Maior concentração documental; exige auditoria própria. |
| `docs/mesa-cliente/adr/` | M3 | CHECKPOINT/ADR | Decisões arquiteturais MesaCliente. |
| `docs/mesa-cliente/importacoes/` | M3 | EVIDENCIA/OPERACIONAL | Importações específicas de empreendimento. |
| `docs/power-message-engine/` | M1/M4 | OFICIAL_CANDIDATO | PME clássico. |
| `docs/modules/power-message-engine/` | M1/M4 | POSSIVEL_DUPLICIDADE | Possível duplicidade/versão modular do PME. |
| `docs/pme/` | M1/M5 | RELEASE/CHECKPOINT | PME usage tracking v0.2.8. |
| `docs/releases/` | M5/M8 | RELEASE/CHECKPOINT | Pacotes/release notes. |
| `docs/discador-flow-ai/` | M1 | OFICIAL_CANDIDATO | Documentação do Discador Flow AI. |

---

## 5. Arquivos identificados por diretório

### 5.1 Visão executiva

```text
docs/00-visao-executiva/resumo-executivo.md
docs/00-visao-executiva/canvas-proposta-de-valor.md
docs/00-visao-executiva/diferenciais-competitivos.md
docs/00-visao-executiva/landing-page-comercial.md
docs/00-visao-executiva/pitch-para-socio-ou-investidor.md
```

Classificação inicial:

- visão executiva/pitch/canvas: OFICIAL_CANDIDATO;
- precisa validação com GPT 10 Monetização/GTM antes de uso comercial externo.

### 5.2 Produto, arquitetura, banco, infraestrutura, observabilidade e segurança

```text
docs/README.md
docs/01-produto/jornada-do-usuario.md
docs/02-arquitetura-tecnica/arquitetura-atual.md
docs/03-infraestrutura-cloud/topologia-cloud.md
docs/04-banco-de-dados/mapa-tabelas.md
docs/04-banco-de-dados/rpcs-e-functions.md
docs/04-banco-de-dados/dicionario-de-dados.md
docs/05-observabilidade-ha/observabilidade-non-stop.md
docs/05-observabilidade-ha/runbook-incidentes.md
docs/06-seguranca-compliance/lgpd.md
docs/06-seguranca-compliance/seguranca-multitenant.md
docs/07-operacao-suporte/guia-suporte-n1-n2-n3.md
docs/07-operacao-suporte/roteiro-demonstracao-produto.md
docs/08-comercial-monetizacao/modelo-saas.md
docs/08-comercial-monetizacao/planos-e-precos.md
docs/08-comercial-monetizacao/proposta-comercial.md
docs/09-financeiro-juridico-fiscal/estrutura-financeira.md
docs/09-financeiro-juridico-fiscal/impostos-e-regime-tributario.md
docs/10-roadmap-e-governanca/backlog-priorizado.md
docs/10-roadmap-e-governanca/due-diligence.md
docs/10-roadmap-e-governanca/matriz-dependencias.md
```

Classificação inicial:

- arquitetura/topologia/observabilidade: OFICIAL_CANDIDATO;
- banco/RPC/dicionário: PENDENTE_RECONCILIACAO com Supabase real;
- LGPD/tributário/jurídico: PENDENTE_RECONCILIACAO com validação técnica/jurídica;
- monetização/preços/proposta: OFICIAL_CANDIDATO, validar contra estratégia comercial vigente.

### 5.3 Auditoria documental

```text
docs/audits/documentation/2026-06-02-documentation-audit-v1.md
docs/audits/documentation/2026-06-02-documentation-inventory-v1.md
docs/audits/documentation/2026-06-03-documentation-tree-inventory-v1.md
```

Classificação inicial:

- todos: OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO.

### 5.4 Branches, changelog, produto, roadmap e protocolos

```text
docs/branches/BRANCH_REGISTRY.md
docs/changelog/2026-06-01-gpt-skills-governance.md
docs/changelog/2026-06-01-gpt34-stack-specialists.md
docs/changelog/2026-06-01-gpt56-observability-ads-specialists.md
docs/changelog/2026-06-02-roadmap-master-v1.md
docs/product/fechai-mvp-scope-v1.md
docs/product/fechai-modules-map-v1.md
docs/roadmap/fechai-roadmap-master-v1.md
docs/protocolos/protocolo-operacional-universal-fechai-v1.0.md
docs/protocolos/protocolo-universal-de-funcionamento-fechai-v1.1.md
docs/protocolos/protocolo_universal_de_funcionamento_fechai_v_1_1.md
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.1.md
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/protocolo/mesa-cliente/engenharia-financeira/fase-5d/13e_validacao_filtros_paginacao_ordenacao.md
```

Gaps:

- possível duplicidade entre `docs/protocolos/` e `docs/protocolo/`;
- possível duplicidade entre protocolos universais hifenizados e underscored;
- `BRANCH_REGISTRY.md` precisa validar branches reais;
- roadmap e módulos são orientação, não prova de implementação.

### 5.5 Skills/GPTs

```text
docs/skills/fechai-gpt-registry.md
docs/skills/fechai-gpt0-documentation-auditor.md
docs/skills/fechai-gpt1-architect-saas.md
docs/skills/fechai-gpt2-ux-ui-app-specialist.md
docs/skills/fechai-gpt3-supabase-security-specialist.md
docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md
docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md
docs/skills/fechai-gpt6-ads-pixel-capi-seo.md
docs/skills/fechai-gpt7-leadops-crm-discador.md
docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md
docs/skills/fechai-gpt9-integracoes-portais-mensageria.md
docs/skills/fechai-gpt10-monetizacao-startup-gtm.md
```

Classificação inicial:

- registry: OFICIAL_CANDIDATO;
- documentos individuais: OFICIAL_CANDIDATO;
- todos dependem de sincronização manual se usados como Knowledge nos GPTs.

### 5.6 Segurança e Supabase

```text
docs/security/SECURITY_AUDIT_2026-05-29.md
docs/security/evidence/2026-05-29_supabase_security_snapshot.sql
docs/security/evidence/2026-05-29_supabase_security_snapshot_results.md
docs/security/evidence/2026-05-29_sensitive_rpc_execution_grants_review.md
docs/security/evidence/2026-05-29_rpc_client_role_denied_test.md
docs/security/evidence/2026-05-29_rpc_functional_tests.md
docs/security/evidence/2026-05-29_root_positive_rpc_tests.md
docs/security/evidence/2026-05-29_get_corretores_time_negative_test.md
docs/security/evidence/2026-05-29_root_identity_candidate.md
docs/security/evidence/2026-05-29_root_candidate_tegra_admin_test.md
```

Gaps:

- vincular cada evidência a ambiente, data, commit e Supabase project real;
- validar se os resultados ainda representam o estado atual;
- confirmar que grants, RLS e RPCs reais seguem a documentação.

### 5.7 Discador Flow AI

```text
docs/discador-flow-ai/README.md
docs/discador-flow-ai/backlog/backlog-mvp-discador-flow-ai-v0.1.md
docs/discador-flow-ai/fluxos/fluxo-13-niveis-discador-flow-ai-v0.1.md
docs/discador-flow-ai/contratos/contrato-mvp-discador-flow-ai-v0.1.md
docs/discador-flow-ai/testes/caderno-testes-mvp-discador-flow-ai-v0.1.md
docs/discador-flow-ai/adr/ADR-0001-ia-modulo-pago-cache-respostas.md
```

Classificação inicial:

- README/contrato/fluxos: OFICIAL_CANDIDATO;
- backlog: PROPOSTA;
- caderno de testes: OFICIAL_CANDIDATO / EVIDENCIA_A_VALIDAR;
- ADR: CHECKPOINT / DECISAO_ARQUITETURAL.

### 5.8 Power Message Engine, PME e releases

```text
docs/power-message-engine/README.md
docs/power-message-engine/prompt-for-implementer-ai.md
docs/power-message-engine/pme-empreendimentos-inline-flow-r3.md
docs/power-message-engine/persistence-roadmap.md
docs/power-message-engine/pme-empreendimentos-implementation-contract-v1.md
docs/modules/power-message-engine/README.md
docs/modules/power-message-engine/message-taxonomy.md
docs/pme/usage-tracking/v0.2.8/FECHAMENTO_TECNICO.md
docs/releases/pme-usage-tracking-v0.2.7/README.md
docs/releases/pme-usage-tracking-v0.2.7/VALIDATION_CHECKLIST.md
docs/releases/ccam-pme-mvp-v0.1/MERGE_PLAN.md
```

Gaps:

- há documentação PME em pelo menos três locais (`power-message-engine`, `modules/power-message-engine`, `pme`/`releases`);
- precisa separar PME canônico, release histórica, módulo novo e handoff;
- `prompt-for-implementer-ai.md` é handoff/proposta, não evidência de aplicação.

### 5.9 Checkpoints e main

```text
docs/checkpoints/mesa-mirror-engine-garden-design-v1.0.0.md
docs/checkpoints/mesa-layout-engine-v1.1.0.md
docs/main/MAIN_ROLLBACK_LOG.md
docs/main/MAIN_UPDATE_REGISTRY.md
docs/main/MAIN_MERGE_CHECKLIST.md
```

Classificação inicial:

- checkpoints: CHECKPOINT / referência histórica;
- main logs/checklists: OPERACIONAL / EVIDENCIA_A_VALIDAR;
- precisam ser reconciliados com PRs e estado real da branch `main`.

### 5.10 MesaCliente — núcleo identificado

```text
docs/mesa-cliente/engenharia-financeira-arquitetura.md
docs/mesa-cliente/engenharia-financeira-roadmap-execucao-ate-mesa-cliente.md
docs/mesa-cliente/frontend-preview-rpc-integration.md
docs/mesa-cliente/espelho-vendas-engine-v1.md
docs/mesa-cliente/espelho-intelligence-layer.md
docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md
```

Classificação inicial:

- arquitetura/engine: OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO;
- roadmap: PROPOSTA / OFICIAL_CANDIDATO;
- ADR: CHECKPOINT / DECISAO_ARQUITETURAL.

### 5.11 MesaCliente — fases e evidências identificadas

```text
docs/mesa-cliente/fase-4a-rpc-gerar-agenda-financeira.md
docs/mesa-cliente/fase-4a-agenda-financeira-handoff.md
docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md
docs/mesa-cliente/fase-4a-validacao-final-json-first.md
docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md
docs/mesa-cliente/fase-4b-validacao-final-evidencias.md
docs/mesa-cliente/fase-4c-cliente-safe-fechamento.md
docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md
docs/mesa-cliente/fase-5a-evidencia-10p-preparacao-base-minima.md
docs/mesa-cliente/fase-5a-preflight-10-resultado-readonly.md
docs/mesa-cliente/fase-5a-validacao-parcial-10a-10b.md
docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md
docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md
docs/mesa-cliente/fase-5b-validacao-preflight-11.md
docs/mesa-cliente/fase-5c-ambiente-limpo-e-plano-execucao.md
docs/mesa-cliente/fase-5c-changelog.md
docs/mesa-cliente/fase-5c-fechamento-tecnico.md
docs/mesa-cliente/fase-5c-smoke-pos-producao.md
docs/mesa-cliente/fase-5c-validacao-12c-negativos-seguranca.md
docs/mesa-cliente/fase-5c-validacao-12d-idempotencia.md
docs/mesa-cliente/fase-5c-validacao-12e-zero-mutacao-rigido.md
docs/mesa-cliente/fase-5c-validacao-smoke-pos-producao.md
docs/mesa-cliente/fase-5d-fechamento-tecnico.md
docs/mesa-cliente/fase-5d-smoke-pos-producao.md
docs/mesa-cliente/fase-5d-smoke-pos-producao-execucao.md
docs/mesa-cliente/fase-5d-validacao-13b-obter-operacao-admin.md
docs/mesa-cliente/fase-5d-validacao-preflight-13.md
docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md
docs/mesa-cliente/fase-6-fechamento-tecnico.md
docs/mesa-cliente/fase-6-preflight-14-execucao.md
docs/mesa-cliente/fase-7-fechamento-tecnico.md
docs/mesa-cliente/fase-7-preflight-15-execucao.md
docs/mesa-cliente/fase-7-validacao-15b-aplicacao-positiva.md
docs/mesa-cliente/fase-7-validacao-15b-execucao-oficial.md
docs/mesa-cliente/fase-7-validacao-15e-execucao-oficial.md
docs/mesa-cliente/fase-7-validacao-15e-regressao-final.md
docs/mesa-cliente/fase-8-20-pre-pr-main-handoff.md
docs/mesa-cliente/fase-8-chateau-jardin-fechamento-evidencias.md
docs/mesa-cliente/fase-8-chateau-jardin-importacao-json-admin.md
docs/mesa-cliente/fase-8a-preflight-integracao-front-bff-operacoes-financeiras.md
docs/mesa-cliente/fase-8b-adapter-front-operacoes-financeiras.md
docs/mesa-cliente/fase-8b-fechamento-tecnico.md
docs/mesa-cliente/fase-8e-validacao-18a-integracao-visual-operacoes-financeiras-panel.md
docs/mesa-cliente/fase-20a-contrato-reabrir-fluxo-historico.md
docs/mesa-cliente/fase-20c-rastreabilidade-fluxo-historico.md
docs/mesa-cliente/fase-20c-contrato-rastreabilidade-valores.md
docs/mesa-cliente/fase-20c0-overview-documental-e-reclassificacao-rastreabilidade.md
docs/mesa-cliente/fase-20c1-checklist-preflight-estado-real.md
docs/mesa-cliente/fase-20c2-plano-piloto-controlado-mesa.md
docs/mesa-cliente/fase-20c3-plano-execucao-controlada-modo-3.md
docs/mesa-cliente/fase-20c3-encerramento-pass.md
docs/mesa-cliente/fase-20d4-contrato-canonico-fluxo-financeiro.md
docs/mesa-cliente/fase-20d5-evidencia-http-bloqueio-shadow.md
docs/mesa-cliente/fase-20d5-migration-fluxo-canonico-shadow.md
docs/mesa-cliente/importacoes/chateau-jardin/2026-05/README.md
```

Classificação inicial agregada:

- `contrato`, `canonico`, `cliente-safe`, `fechamento-tecnico`: candidatos a documento canônico/checkpoint;
- `validacao`, `evidencia`, `smoke`, `preflight`, `pass`: evidência/checklist a validar;
- `migration`: draft/aplicação a validar contra Supabase real;
- documentos de importação: evidência operacional específica.

---

## 6. Deltas relevantes contra o Inventário Documental v1

| Delta | Impacto | Risco |
|---|---|---:|
| Diretórios executivos e comerciais (`00`, `08`, `09`, `10`) estavam ausentes | Monetização/GTM e due diligence poderiam ficar fora da auditoria | P1/P2 |
| Diretórios de produto/infra/observabilidade/operação estavam ausentes | Auditorias de SRE, suporte e cloud ficariam incompletas | P1/P2 |
| `docs/checkpoints/`, `docs/main/` e `docs/protocolo/` estavam ausentes | Checkpoints e logs operacionais poderiam ser ignorados | P1 |
| Documentos Discador Flow AI não estavam detalhados | M1 precisa de auditoria própria além de LeadOps genérico | P1 |
| Pasta `docs/modules/power-message-engine/` sugere duplicidade com `docs/power-message-engine/` | Pode haver PME canônico vs modular divergente | P1 |
| `docs/pme/usage-tracking/v0.2.8/` e `docs/releases/pme-usage-tracking-v0.2.7/` adicionam trilha de release | Precisa separar release histórica de versão vigente | P2 |
| MesaCliente tem volume maior do que o inventário inicial | Exige auditoria própria antes de qualquer alteração | P0/P1 |
| Banco tem `dicionario-de-dados.md` além de mapa/RPCs | Deve entrar na reconciliação Supabase | P1 |
| Segurança tem evidências adicionais de root candidate/admin test | Deve vincular ambiente, data e validade atual | P1 |
| Skills GPT 0 e GPTs 7-10 agora existem no registry, mas Knowledge pode ficar defasado | GitHub deve vencer Knowledge | P2 |

---

## 7. Riscos principais identificados

| Risco | Prioridade | Motivo |
|---|---:|---|
| Auditar MesaCliente superficialmente | P0/P1 | Há muitos documentos de fase, validação, contrato e evidência. Um canônico errado pode afetar parser/motor financeiro. |
| Tratar PME antigo, modular e release como a mesma coisa | P1 | Pode gerar implementação com base em documento errado. |
| Ignorar docs executivos/comerciais/financeiros | P1/P2 | Afeta monetização, due diligence e posicionamento SaaS. |
| Ignorar checkpoints/main/protocolo singular | P1 | Pode perder rollback, registros de main e trilhas legadas. |
| Tratar roadmap/skill como implementação | P1 | Roadmap e skill definem intenção, não estado aplicado. |
| Não reconciliar banco/RPCs com Supabase real | P1 | Documentação de banco continua pendente de validação aplicada. |
| Usar Knowledge dos GPTs como fonte viva | P2 | Arquivos carregados manualmente ficam defasados; GitHub deve vencer. |

---

## 8. Próxima sequência recomendada

1. Criar auditoria específica MesaCliente:

```text
docs/audits/documentation/2026-06-03-mesacliente-docs-inventory-v1.md
```

2. Criar auditoria específica Supabase:

```text
docs/audits/documentation/2026-06-03-supabase-docs-inventory-v1.md
```

3. Criar auditoria específica PME/Discador Flow AI:

```text
docs/audits/documentation/2026-06-03-pme-discador-docs-inventory-v1.md
```

4. Criar auditoria de monetização/GTM/due diligence:

```text
docs/audits/documentation/2026-06-03-gtm-monetizacao-docs-inventory-v1.md
```

5. Criar auditoria de código AS-IS:

```text
docs/audits/code/2026-06-03-code-as-is-inventory-v1.md
```

---

## 9. Regra de bloqueio

Este documento não autoriza implementação.

Não alterar:

- App.jsx;
- Supabase;
- RLS;
- RPCs;
- grants;
- migrations;
- MesaCliente;
- LeadOps;
- PME;
- Discador;
- ADS/CAPI;
- Vercel;
- GitHub Actions;
- produção.

Qualquer alteração depende da auditoria específica do domínio e aprovação explícita.
