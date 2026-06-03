# FECH.AI — Inventário Documental v1

**Data:** 2026-06-02  
**Status:** OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO  
**Base:** branch `main` após merge da PR #48 (`b6c9d46eedb27843c4fb37ddb51b912a4355d428`)  
**Escopo:** inventário inicial da documentação localizada em `docs/`, sem implementação e sem alteração de código/banco.

---

## 1. Objetivo

Registrar o primeiro inventário documental do FECH.AI para separar documentos oficiais, candidatos, rascunhos, evidências, checkpoints, propostas e pendências de reconciliação.

Este documento não valida o Supabase real, não valida código real linha a linha e não autoriza implementação. Ele organiza a documentação encontrada e define a próxima etapa de auditoria.

---

## 2. Critério de classificação

| Classificação | Uso |
|---|---|
| OFICIAL_VIGENTE | aprovado e aderente ao estado atual ou decisão oficial aplicada |
| OFICIAL_CANDIDATO | útil para decisão, mas pendente de validação contra código/Supabase |
| RASCUNHO | preliminar, não orienta implementação sozinho |
| PROPOSTA | plano ou ideia ainda não aprovado/aplicado |
| CHECKPOINT | marco, baseline ou referência de rollback |
| CHANGELOG | registro histórico de alteração |
| EVIDENCIA_VALIDACAO | prova de teste, auditoria ou aplicação real |
| OBSOLETO | substituído ou sem aderência à decisão atual |
| CONFLITANTE | contradiz documento, código, Supabase ou decisão atual |
| PENDENTE_RECONCILIACAO | precisa validar contra código, banco, PR, RLS, RPC ou Supabase real |
| DRIFT_A_VALIDAR | indício de divergência que exige evidência adicional |

---

## 3. Inventário por domínio

### M0 — Documentação e Governança

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/README.md` | RASCUNHO / OFICIAL_CANDIDATO | P2 | Entrada geral da documentação; precisa ser reconciliada com inventário real. |
| `docs/audits/documentation/2026-06-02-documentation-audit-v1.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Protocolo oficial candidato para auditoria documental. |
| `docs/branches/BRANCH_REGISTRY.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Registro de branches precisa ser validado contra GitHub real. |
| `docs/protocolos/protocolo-operacional-universal-fechai-v1.0.md` | OFICIAL_CANDIDATO | P1 | Protocolo operacional candidato. |
| `docs/protocolos/protocolo-universal-de-funcionamento-fechai-v1.1.md` | OFICIAL_CANDIDATO / POSSIVEL_DUPLICIDADE | P2 | Deve ser comparado com outros protocolos universais. |
| `docs/protocolos/protocolo_universal_de_funcionamento_fechai_v_1_1.md` | POSSIVEL_DUPLICIDADE / PENDENTE_RECONCILIACAO | P2 | Nome sugere duplicidade com versão hifenizada. |

### M1 — LeadOps, CRM, Listas, Discador e PME

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/product/fechai-mvp-scope-v1.md` | OFICIAL_CANDIDATO | P1 | Escopo MVP precisa ser comparado com código e PRs. |
| `docs/power-message-engine/README.md` | OFICIAL_CANDIDATO | P1 | Entrada PME. |
| `docs/power-message-engine/spec.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Especificação PME precisa validar schema/código. |
| `docs/power-message-engine/data-model.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Modelo de dados precisa validar Supabase real. |
| `docs/power-message-engine/schema-audit-pme.md` | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO | P1 | Auditoria de schema PME. |
| `docs/power-message-engine/supabase-rls-plan.md` | PROPOSTA / PENDENTE_RECONCILIACAO | P1 | Plano de RLS precisa validar aplicação real. |
| `docs/power-message-engine/supabase-migration-draft.sql` | RASCUNHO / PROPOSTA | P1 | Draft SQL não deve ser tratado como migration aplicada. |
| `docs/power-message-engine/implementation-checklist.md` | OFICIAL_CANDIDATO | P2 | Checklist útil, pendente de validação real. |
| `docs/power-message-engine/compliance-and-governance.md` | OFICIAL_CANDIDATO | P1 | Compliance PME precisa cruzar LGPD e segurança. |
| `docs/power-message-engine/pme-empreendimentos-implementation-contract-v1.md` | OFICIAL_CANDIDATO | P1 | Contrato de implementação candidato. |
| `docs/power-message-engine/pme-empreendimentos-chateau-jardin-launch-v1.md` | PROPOSTA / OFICIAL_CANDIDATO | P2 | Conteúdo operacional do lançamento. |
| `docs/power-message-engine/pme-empreendimentos-pr38-handoff.md` | CHECKPOINT / CHANGELOG | P2 | Handoff PR 38 precisa validar GitHub real. |

### M2 — ADS, Pixel, CAPI, Stape e CRM-to-Ads

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/skills/fechai-gpt6-ads-pixel-capi-seo.md` | OFICIAL_CANDIDATO | P1 | Define especialista ADS/CAPI; não prova implementação. |
| `docs/product/fechai-modules-map-v1.md` | OFICIAL_CANDIDATO | P1 | Mapa de módulos inclui M2; precisa validar código/app. |
| `docs/roadmap/fechai-roadmap-master-v1.md` | OFICIAL_CANDIDATO | P2 | Roadmap define fase futura; não é evidência de implementação. |
| `docs/changelog/2026-06-02-roadmap-master-v1.md` | CHANGELOG | P2 | Registro histórico de roadmap. |

### M3 — MesaCliente, Tabelas e Propostas

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.1.md` | CHECKPOINT / OFICIAL_CANDIDATO | P1 | Protocolo Mestre MesaCliente anterior. |
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md` | OFICIAL_CANDIDATO | P1 | Versão mais recente aparente; validar contra código. |
| `docs/mesa-cliente/engenharia-financeira-arquitetura.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Arquitetura financeira exige validação com motor real. |
| `docs/mesa-cliente/frontend-preview-rpc-integration.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Integração RPC precisa validar código/Supabase. |
| `docs/mesa-cliente/espelho-vendas-engine-v1.md` | OFICIAL_CANDIDATO | P1 | Engine de espelho de vendas. |
| `docs/mesa-cliente/espelho-intelligence-layer.md` | PROPOSTA / OFICIAL_CANDIDATO | P2 | Camada inteligente, validar estágio real. |
| `docs/mesa-cliente/fase-4a-rpc-gerar-agenda-financeira.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | RPC financeira: validar Supabase real. |
| `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md` | OFICIAL_CANDIDATO | P1 | Candidata a canônica. |
| `docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md` | OFICIAL_CANDIDATO | P1 | Contrato cliente-safe. |
| `docs/mesa-cliente/fase-5c-changelog.md` | CHANGELOG | P2 | Histórico de fase. |
| `docs/mesa-cliente/fase-5d-smoke-pos-producao.md` | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO | P1 | Smoke pós-produção precisa validar ambiente real. |
| `docs/mesa-cliente/fase-6-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_VALIDACAO | P1 | Fechamento técnico. |
| `docs/mesa-cliente/fase-7-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_VALIDACAO | P1 | Fechamento técnico posterior. |
| `docs/mesa-cliente/fase-8-20-pre-pr-main-handoff.md` | CHECKPOINT / CHANGELOG | P2 | Handoff pré-PR/main. |
| `docs/mesa-cliente/fase-20c0-overview-documental-e-reclassificacao-rastreabilidade.md` | OFICIAL_CANDIDATO | P1 | Reclassificação/rastreabilidade documental. |
| `docs/mesa-cliente/fase-20c1-checklist-preflight-estado-real.md` | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO | P1 | Checklist de estado real. |
| `docs/mesa-cliente/fase-20c2-plano-piloto-controlado-mesa.md` | PROPOSTA / OFICIAL_CANDIDATO | P1 | Plano piloto controlado. |
| `docs/mesa-cliente/fase-20c3-plano-execucao-controlada-modo-3.md` | PROPOSTA / OFICIAL_CANDIDATO | P1 | Plano execução controlada. |
| `docs/mesa-cliente/fase-20c3-encerramento-pass.md` | EVIDENCIA_VALIDACAO | P1 | Indício de encerramento/pass. |
| `docs/mesa-cliente/fase-20d4-contrato-canonico-fluxo-financeiro.md` | OFICIAL_CANDIDATO | P1 | Contrato canônico candidato. |
| `docs/mesa-cliente/fase-20d5-evidencia-http-bloqueio-shadow.md` | EVIDENCIA_VALIDACAO | P1 | Evidência de bloqueio HTTP/shadow. |

Observação M3: há volume alto de documentos MesaCliente e risco de duplicidade/versões paralelas. O próximo passo deve separar documentos canônicos, checkpoints, evidências e históricos antes de qualquer alteração no motor, parser, fluxo financeiro ou UI.

### M4 — Integrações, Portais e Mensageria

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/power-message-engine/automation-rules.md` | OFICIAL_CANDIDATO | P1 | Regras de automação, validar implementação. |
| `docs/power-message-engine/message-taxonomy.md` | OFICIAL_CANDIDATO | P2 | Taxonomia de mensagens. |
| `docs/power-message-engine/call-scripts.md` | OFICIAL_CANDIDATO | P2 | Scripts de ligação. |
| `docs/power-message-engine/prompt-for-implementer-ai.md` | PROPOSTA / HANDOFF | P2 | Prompt de implementação; não prova aplicação. |
| `docs/power-message-engine/pme-empreendimentos-inline-flow-r3.md` | OFICIAL_CANDIDATO | P1 | Fluxo inline candidato. |

### M5 — Dashboards, Observabilidade e Operação

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md` | OFICIAL_CANDIDATO | P1 | Define especialista SRE/Observabilidade. |
| `docs/power-message-engine/production-validation.md` | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO | P1 | Validação de produção precisa evidência de ambiente. |
| `docs/power-message-engine/persistence-roadmap.md` | PROPOSTA / OFICIAL_CANDIDATO | P2 | Roadmap de persistência. |

### M6 — Monetização, Planos e GTM

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/roadmap/fechai-roadmap-master-v1.md` | OFICIAL_CANDIDATO | P2 | Contém visão de fases e monetização; não prova produto aplicado. |
| `docs/product/fechai-modules-map-v1.md` | OFICIAL_CANDIDATO | P2 | Mapa de módulos suporta GTM. |

### M7 — Supabase, Banco, Auth, RLS e RPCs

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/04-banco-de-dados/mapa-tabelas.md` | PENDENTE_RECONCILIACAO | P1 | Declara necessidade de reconciliar com Supabase real. |
| `docs/04-banco-de-dados/rpcs-e-functions.md` | PENDENTE_RECONCILIACAO | P1 | Declara necessidade de reconciliar com Supabase real. |
| `docs/security/evidence/2026-05-29_supabase_security_snapshot.sql` | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO | P1 | Script/evidência de snapshot; validar execução e resultado. |
| `docs/security/evidence/2026-05-29_supabase_security_snapshot_results.md` | EVIDENCIA_VALIDACAO | P1 | Resultado de snapshot, validar ambiente e data. |
| `docs/security/evidence/2026-05-29_sensitive_rpc_execution_grants_review.md` | EVIDENCIA_VALIDACAO | P1 | Revisão de grants sensíveis. |
| `docs/security/evidence/2026-05-29_rpc_client_role_denied_test.md` | EVIDENCIA_VALIDACAO | P1 | Teste negativo de role client. |
| `docs/security/evidence/2026-05-29_rpc_functional_tests.md` | EVIDENCIA_VALIDACAO | P1 | Testes funcionais RPC. |
| `docs/security/evidence/2026-05-29_root_positive_rpc_tests.md` | EVIDENCIA_VALIDACAO | P1 | Testes positivos root. |
| `docs/security/evidence/2026-05-29_get_corretores_time_negative_test.md` | EVIDENCIA_VALIDACAO | P1 | Teste negativo por time. |

### M8 — Vercel, GitHub, CI/CD e Deploy

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md` | OFICIAL_CANDIDATO | P1 | Define especialista CI/CD. |
| `docs/changelog/2026-06-01-gpt-skills-governance.md` | CHANGELOG | P2 | Histórico da governança de GPTs. |
| `docs/changelog/2026-06-01-gpt56-observability-ads-specialists.md` | CHANGELOG | P2 | Histórico GPT 5/6. |
| `docs/changelog/2026-06-02-roadmap-master-v1.md` | CHANGELOG | P2 | Histórico roadmap. |
| `docs/branches/BRANCH_REGISTRY.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Precisa validar com branches GitHub reais. |

### M9 — Segurança, LGPD e DevSecOps

| Documento | Status preliminar | Risco | Observação |
|---|---:|---:|---|
| `docs/06-seguranca-compliance/lgpd.md` | RASCUNHO / PENDENTE_RECONCILIACAO | P1 | Precisa validação jurídica/técnica. |
| `docs/security/SECURITY_AUDIT_2026-05-29.md` | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO | P1 | Auditoria de segurança. |
| `docs/skills/fechai-gpt3-supabase-security-specialist.md` | OFICIAL_CANDIDATO | P1 | Define especialista Supabase Security. |
| `docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md` | OFICIAL_CANDIDATO | P1 | Define especialista SRE/DevSecOps. |
| `docs/power-message-engine/compliance-and-governance.md` | OFICIAL_CANDIDATO | P1 | Compliance PME. |

---

## 4. Inventário de skills/GPTs

| Documento | Status preliminar | Observação |
|---|---:|---|
| `docs/skills/fechai-gpt-registry.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | Registry precisa refletir GPTs criados e versões reais. |
| `docs/skills/fechai-gpt1-architect-saas.md` | OFICIAL_CANDIDATO | GPT 1 Arquitetura. |
| `docs/skills/fechai-gpt2-ux-ui-app-specialist.md` | OFICIAL_CANDIDATO | GPT 2 UX/UI. |
| `docs/skills/fechai-gpt3-supabase-security-specialist.md` | OFICIAL_CANDIDATO | GPT 3 Supabase Security. |
| `docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md` | OFICIAL_CANDIDATO | GPT 4 Vercel/GitHub CI-CD. |
| `docs/skills/fechai-gpt5-sre-devsecops-observability-specialist.md` | OFICIAL_CANDIDATO | GPT 5 SRE/Observability. |
| `docs/skills/fechai-gpt6-ads-pixel-capi-seo.md` | OFICIAL_CANDIDATO | GPT 6 ADS/CAPI/SEO. |

Pendência: GPT 0 e GPTs 7 a 10 precisam ser comparados com o registry vigente e documentados se ainda não estiverem versionados no repositório.

---

## 5. Gaps iniciais do inventário

| Gap | Risco | Ação recomendada |
|---|---:|---|
| Inventário ainda não exaustivo por limitação da busca paginada/truncada | P1 | Fazer varredura completa de árvore do repositório ou export `find docs -type f`. |
| Alto volume de docs MesaCliente com fases/checkpoints | P1 | Criar inventário específico MesaCliente com canônico vs histórico. |
| `fechai-gpt-registry.md` pode não refletir GPT 0 e GPTs 7-10 | P1 | Atualizar registry em PR separada após validação. |
| Mapa de tabelas e RPCs declaram pendência com Supabase real | P1 | Executar inventário Supabase read-only. |
| Documentos de segurança/evidência precisam vincular ambiente/data/commit | P1 | Criar matriz evidência x ambiente x commit. |
| Possíveis duplicidades em `docs/protocolos` | P2 | Comparar protocolos e marcar canônico. |
| Documentos de ADS/CAPI parecem mais arquiteturais que implementados | P1 | Validar código/app antes de afirmar implementação. |

---

## 6. Próxima etapa

Criar auditoria específica de documentação MesaCliente e documentação Supabase, porque são os domínios com maior risco técnico imediato:

1. `docs/audits/documentation/2026-06-02-mesacliente-docs-inventory-v1.md`
2. `docs/audits/documentation/2026-06-02-supabase-docs-inventory-v1.md`

Antes disso, validar este inventário v1 via PR documental.

---

## 7. Regra de bloqueio

Este inventário não autoriza implementação. Qualquer mudança em código, Supabase, RLS, RPC, MesaCliente, LeadOps, ADS/CAPI, Vercel ou GitHub Actions depende de auditoria específica e aprovação explícita.
