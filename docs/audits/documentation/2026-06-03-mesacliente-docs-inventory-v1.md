# FECH.AI — Auditoria Documental MesaCliente v1

**Data:** 2026-06-03  
**Status:** `OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO`  
**Responsável conceitual:** GPT 0 — FECH.AI Documentation Auditor  
**Executor operacional:** Projeto Principal FECH.AI com conector GitHub  
**Arquivo:** `docs/audits/documentation/2026-06-03-mesacliente-docs-inventory-v1.md`  
**Tipo:** documentação-only.  
**Escopo proibido:** não altera App, Supabase, RLS, RPCs, migrations, parser, motor financeiro, Worker, Make/n8n, frontend, MesaCliente, LeadOps, PME, Discador, ADS/CAPI, Vercel, GitHub Actions ou produção.

---

## 1. Objetivo

Inventariar e classificar documentalmente os artefatos relacionados ao MesaCliente antes de qualquer implementação.

Esta auditoria **não declara nenhum documento como `OFICIAL_VIGENTE`** e **não autoriza implementação**. O objetivo é criar uma base documental para futura reconciliação com código, Supabase real, PRs, commits, branches e decisões do Wagner.

---

## 2. Escopo verificado

Escopo principal:

```text
docs/mesa-cliente/
docs/mesa-cliente/adr/
docs/mesa-cliente/importacoes/
docs/mesa-cliente/rascunhos-sql/
docs/checkpoints/
docs/protocolo/mesa-cliente/
docs/protocolos/protocolo-mestre-fechai-mesacliente-*
documentos transversais citados como relacionados ao MesaCliente
```

Após feedbacks do Codex, esta versão passa a representar explicitamente todos os caminhos conhecidos de `docs/mesa-cliente/` retornados na validação operacional da PR #52, incluindo `.md`, `.json`, `.patch` e `.sql`.

Limitação importante: apesar da cobertura operacional do inventário, todo item permanece `PENDENTE_RECONCILIACAO` até conferência com árvore Git definitiva, código real e Supabase real.

---

## 3. Inventário completo de `docs/mesa-cliente/`

Classificação inicial por caminho. Esta tabela não substitui leitura integral nem validação técnica.

| Documento | Classificação inicial | Risco | Uso permitido nesta auditoria |
|---|---|---:|---|
| `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md` | ADR / CHECKPOINT / PENDENTE_RECONCILIACAO | P1 | Decisão histórica JSON-first; verificar se foi supersedida por persistência. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/README.md` | IMPORTACAO / EVIDENCIA_A_VALIDAR / PENDENTE_RECONCILIACAO | P1 | Evidência operacional; validar origem, payload e ambiente. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/MANIFEST.local-files.md` | MANIFEST / EVIDENCIA_A_VALIDAR / PENDENTE_RECONCILIACAO | P1 | Manifest local; não generalizar como contrato. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/payload_schema.example.json` | PAYLOAD_SCHEMA / EVIDENCIA_A_VALIDAR / PENDENTE_RECONCILIACAO | P1 | Schema exemplo; validar contra parser, payload real e importação. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/patches/fluxobuilder_meta_e_financiamento_oficial_payload.patch` | PATCH / EVIDENCIA_A_VALIDAR / NAO_CANONICO_SOZINHO | P1 | Patch documental; não aplicar sem PR/código real. |
| `docs/mesa-cliente/rascunhos-sql/obsoletos-fase-4a-persistente/README.md` | RASCUNHO_SQL / NAO_CANONICO / PENDENTE_SUPABASE_REAL | P0/P1 | Rascunho/obsoleto; não usar para SQL aplicado. |
| `docs/mesa-cliente/rascunhos-sql/preflights-exploratorios/10_preflight_impacto_financeiro_readonly.sql` | RASCUNHO_SQL / NAO_CANONICO / PENDENTE_SUPABASE_REAL | P0/P1 | SQL exploratório; não executar sem validação. |
| `docs/mesa-cliente/engenharia-financeira-arquitetura.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Arquitetura financeira candidata; reconciliar com código/Supabase. |
| `docs/mesa-cliente/engenharia-financeira-plano-implementacao.md` | PROPOSTA / PLANO / PENDENTE_RECONCILIACAO | P1 | Plano não prova implementação. |
| `docs/mesa-cliente/engenharia-financeira-producao-unica-backup-rollback.md` | CHECKPOINT / OPERACIONAL / EVIDENCIA_A_VALIDAR | P1 | Validar PR, commit, ambiente e rollback. |
| `docs/mesa-cliente/engenharia-financeira-roadmap-execucao-ate-mesa-cliente.md` | ROADMAP / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Direção futura; não prova estado aplicado. |
| `docs/mesa-cliente/espelho-intelligence-layer.md` | OFICIAL_CANDIDATO / PROPOSTA / PENDENTE_RECONCILIACAO | P1 | Validar escopo de IA, payload e privacidade. |
| `docs/mesa-cliente/espelho-vendas-engine-v1.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato de engine comercial/financeira. |
| `docs/mesa-cliente/frontend-preview-rpc-integration.md` | INTEGRACAO_FRONT_RPC / PENDENTE_RECONCILIACAO | P1 | Validar contra código real e RPCs reais. |
| `docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md` | PREFLIGHT / RECONCILIACAO_GITHUB_SUPABASE / EVIDENCIA_A_VALIDAR | P0/P1 | Revalidar contra GitHub e Supabase atuais. |
| `docs/mesa-cliente/tabela-oficial-disponibilidade-v1.md` | TABELA_DISPONIBILIDADE / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Pode impactar estoque/proposta; validar fonte e freshness. |
| `docs/mesa-cliente/fase-20a-contrato-reabrir-fluxo-historico.md` | CONTRATO / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Reabertura de histórico é sensível. |
| `docs/mesa-cliente/fase-20a-validacao-rpc-reabrir-fluxo-historico.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar ambiente, data e testes negativos. |
| `docs/mesa-cliente/fase-20a1-validacao-hardening-acesso-fluxo-historico.md` | VALIDACAO_SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Validar hardening e cross-tenant. |
| `docs/mesa-cliente/fase-20c-contrato-rastreabilidade-valores.md` | CONTRATO / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Rastreabilidade financeira candidata. |
| `docs/mesa-cliente/fase-20c-rastreabilidade-fluxo-historico.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Reconciliar com histórico e banco. |
| `docs/mesa-cliente/fase-20c0-overview-documental-e-reclassificacao-rastreabilidade.md` | INVENTARIO_PARCIAL / PENDENTE_RECONCILIACAO | P1 | Não substitui inventário completo. |
| `docs/mesa-cliente/fase-20c1-checklist-preflight-estado-real.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Checklist não é prova sem execução. |
| `docs/mesa-cliente/fase-20c1-relatorio-preflight-estado-real.md` | RELATORIO / EVIDENCIA_A_VALIDAR | P1 | Confrontar com estado real atual. |
| `docs/mesa-cliente/fase-20c2-gate-b-diagnostico-warns-seguranca.md` | VALIDACAO_SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Warnings podem bloquear avanço. |
| `docs/mesa-cliente/fase-20c2-plano-piloto-controlado-mesa.md` | PROPOSTA / PLANO / PENDENTE_RECONCILIACAO | P1 | Piloto não é produção. |
| `docs/mesa-cliente/fase-20c2-revisao-rpc-gerar-agenda-financeira.md` | REVISAO_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Validar função, grants e RLS. |
| `docs/mesa-cliente/fase-20c2-revisao-rpc-persistir-agenda-financeira.md` | REVISAO_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Persistência financeira crítica. |
| `docs/mesa-cliente/fase-20c3-decisao-opcao-a-payload-adaptado-piloto.md` | DECISAO / PROPOSTA / PENDENTE_RECONCILIACAO | P1 | Comparar com contrato final. |
| `docs/mesa-cliente/fase-20c3-encerramento-pass.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | PASS precisa evidência reproduzível. |
| `docs/mesa-cliente/fase-20c3-evidencia-geracao-agenda-4a-json-first.md` | EVIDENCIA / VALIDACAO / A_VALIDAR | P1 | Pode ser histórica. |
| `docs/mesa-cliente/fase-20c3-plano-execucao-controlada-modo-3.md` | PLANO / PENDENTE_RECONCILIACAO | P1 | Não autoriza execução. |
| `docs/mesa-cliente/fase-20c3-relatorio-execucao-controlada-modo-3.md` | RELATORIO / EVIDENCIA_A_VALIDAR | P1 | Reconciliar com logs/PR/Supabase. |
| `docs/mesa-cliente/fase-20c3-selecao-readonly-simulacao-candidata.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Read-only não prova escrita segura. |
| `docs/mesa-cliente/fase-20d-contrato-adaptador-historico-agenda-canonica.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato canônico histórico/agenda. |
| `docs/mesa-cliente/fase-20d1-revisao-readonly-schema-real.md` | REVISAO_SCHEMA / EVIDENCIA_A_VALIDAR | P0/P1 | Validar Supabase real. |
| `docs/mesa-cliente/fase-20d3-proposta-rpc-adaptadora-readonly.md` | PROPOSTA_RPC / PENDENTE_SUPABASE_REAL | P1 | Proposta não é RPC aplicada. |
| `docs/mesa-cliente/fase-20d4-ajuste-semantico-chaves-complemento-entrada.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Validar parser e payload. |
| `docs/mesa-cliente/fase-20d4-contrato-canonico-fluxo-financeiro.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Forte candidato canônico. |
| `docs/mesa-cliente/fase-20d4-fonte-soberana-tabela-importada.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Fonte soberana de tabela importada. |
| `docs/mesa-cliente/fase-20d4-regra-mensais-intermediarias.md` | CONTRATO / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Regra financeira sensível. |
| `docs/mesa-cliente/fase-20d4-status-migration-adaptador-readonly.md` | STATUS_MIGRATION / PENDENTE_SUPABASE_REAL | P0/P1 | Não prova migration aplicada. |
| `docs/mesa-cliente/fase-20d5-evidencia-http-bloqueio-shadow.md` | EVIDENCIA_SEGURANCA / A_VALIDAR | P0/P1 | Validar logs e ambiente. |
| `docs/mesa-cliente/fase-20d5-evidencias-testes-shadow.md` | EVIDENCIA_VALIDACAO / A_VALIDAR | P1 | Evidência shadow pode ser específica. |
| `docs/mesa-cliente/fase-20d5-migration-fluxo-canonico-shadow.md` | MIGRATION_DOC / PENDENTE_SUPABASE_REAL / NAO_CANONICO_SOZINHO | P0/P1 | Documento não prova aplicação. |
| `docs/mesa-cliente/fase-20d5-plano-correcao-origem-fluxo-financeiro.md` | PLANO / PENDENTE_RECONCILIACAO | P1 | Não executar sem validação. |
| `docs/mesa-cliente/fase-4a-agenda-financeira-handoff.md` | HANDOFF / PENDENTE_RECONCILIACAO | P1 | Handoff não é fonte final. |
| `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md` | CONTRATO_HISTORICO / PENDENTE_RECONCILIACAO | P1 | Pode estar superado. |
| `docs/mesa-cliente/fase-4a-rpc-gerar-agenda-financeira.md` | CONTRATO_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Validar função real. |
| `docs/mesa-cliente/fase-4a-validacao-final-json-first.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Histórico, não prova atual. |
| `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md` | VALIDACAO_TRANSICAO / EVIDENCIA_A_VALIDAR | P1 | Validar se supersedida. |
| `docs/mesa-cliente/fase-4b-contrato-persistencia-agenda-financeira.md` | CONTRATO / PENDENTE_SUPABASE_REAL | P0/P1 | Persistência crítica. |
| `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar estado atual. |
| `docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md` | CONTRATO_CLIENTE_SAFE / PENDENTE_RECONCILIACAO | P0/P1 | Cliente-safe crítico. |
| `docs/mesa-cliente/fase-4c-cliente-safe-fechamento.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Fechamento não basta. |
| `docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Simulação financeira sensível. |
| `docs/mesa-cliente/fase-5a-evidencia-10p-preparacao-base-minima.md` | EVIDENCIA / A_VALIDAR | P1 | Validar dados/ambiente. |
| `docs/mesa-cliente/fase-5a-preflight-10-resultado-readonly.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Read-only não prova escrita. |
| `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar regressão. |
| `docs/mesa-cliente/fase-5a-validacao-parcial-10a-10b.md` | VALIDACAO_PARCIAL / EVIDENCIA_A_VALIDAR | P1 | Parcial não é final. |
| `docs/mesa-cliente/fase-5a1-contrato-simulacao-impacto-financeiro.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Reconciliar motor financeiro. |
| `docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Registro financeiro crítico. |
| `docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Cruzar com PR/Supabase. |
| `docs/mesa-cliente/fase-5b-validacao-11a-registro-operacao-financeira.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar positivos/negativos. |
| `docs/mesa-cliente/fase-5b-validacao-11b-negativos-registro-operacao-financeira.md` | VALIDACAO_NEGATIVA / EVIDENCIA_A_VALIDAR | P0/P1 | Negativos críticos. |
| `docs/mesa-cliente/fase-5b-validacao-11c-idempotencia-registro-operacao-financeira.md` | VALIDACAO_IDEMPOTENCIA / EVIDENCIA_A_VALIDAR | P1 | Idempotência crítica. |
| `docs/mesa-cliente/fase-5b-validacao-11d-operacao-confirmada-conflito.md` | VALIDACAO_CONFLITO / EVIDENCIA_A_VALIDAR | P1 | Consistência financeira. |
| `docs/mesa-cliente/fase-5b-validacao-11e-zero-mutacao-agenda-parcelas.md` | VALIDACAO_ZERO_MUTACAO / EVIDENCIA_A_VALIDAR | P0/P1 | Validar banco. |
| `docs/mesa-cliente/fase-5b-validacao-preflight-11.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Não é estado final. |
| `docs/mesa-cliente/fase-5c-ambiente-limpo-e-plano-execucao.md` | PREFLIGHT / PLANO / PENDENTE_RECONCILIACAO | P1 | Validar ambiente. |
| `docs/mesa-cliente/fase-5c-changelog.md` | CHANGELOG / HISTORICO | P2 | Histórico, não prova atual. |
| `docs/mesa-cliente/fase-5c-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Validar PR/Supabase. |
| `docs/mesa-cliente/fase-5c-smoke-pos-producao.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Validar ambiente e data. |
| `docs/mesa-cliente/fase-5c-validacao-12a-confirmacao-operacao-financeira.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Confirmar atualidade. |
| `docs/mesa-cliente/fase-5c-validacao-12b-cancelamento-operacao-financeira.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar rollback/auditoria. |
| `docs/mesa-cliente/fase-5c-validacao-12c-negativos-seguranca.md` | VALIDACAO_NEGATIVA_SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Segurança crítica. |
| `docs/mesa-cliente/fase-5c-validacao-12d-idempotencia.md` | VALIDACAO_IDEMPOTENCIA / EVIDENCIA_A_VALIDAR | P1 | Validar repetibilidade. |
| `docs/mesa-cliente/fase-5c-validacao-12e-zero-mutacao-rigido.md` | VALIDACAO_ZERO_MUTACAO / EVIDENCIA_A_VALIDAR | P0/P1 | Validar em banco/logs. |
| `docs/mesa-cliente/fase-5c-validacao-preflight-12.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Não autoriza implementação. |
| `docs/mesa-cliente/fase-5c-validacao-smoke-pos-producao.md` | SMOKE_TEST / VALIDACAO / EVIDENCIA_A_VALIDAR | P0/P1 | Validar commit/ambiente. |
| `docs/mesa-cliente/fase-5d-contrato-leitura-operacoes-admin.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Admin/tenant/client-safe. |
| `docs/mesa-cliente/fase-5d-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Consolidar validações. |
| `docs/mesa-cliente/fase-5d-smoke-pos-producao-execucao.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Produção exige rastreabilidade. |
| `docs/mesa-cliente/fase-5d-smoke-pos-producao.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Possível duplicidade. |
| `docs/mesa-cliente/fase-5d-validacao-13a-listar-operacoes-admin.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar filtros/tenant. |
| `docs/mesa-cliente/fase-5d-validacao-13b-obter-operacao-admin.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar ownership. |
| `docs/mesa-cliente/fase-5d-validacao-13c-seguranca-leitura-operacoes-admin.md` | VALIDACAO_SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Vazamento possível. |
| `docs/mesa-cliente/fase-5d-validacao-13d-zero-dml-readonly-rigido.md` | VALIDACAO_ZERO_DML / EVIDENCIA_A_VALIDAR | P0/P1 | Provar ausência de DML. |
| `docs/mesa-cliente/fase-5d-validacao-preflight-13.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Não é aceitação final. |
| `docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Resumos podem expor valores. |
| `docs/mesa-cliente/fase-6-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Validar PR/Supabase. |
| `docs/mesa-cliente/fase-6-preflight-14-execucao.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Não autoriza mudança. |
| `docs/mesa-cliente/fase-6-smoke-pos-producao-execucao.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Validar produção. |
| `docs/mesa-cliente/fase-7-15a-status-operacao-aplicada-execucao.md` | EXECUCAO / EVIDENCIA_A_VALIDAR | P0/P1 | Status financeiro crítico. |
| `docs/mesa-cliente/fase-7-aplicacao-operacao-financeira-execucao.md` | EXECUCAO / EVIDENCIA_A_VALIDAR | P0/P1 | Aplicação financeira crítica. |
| `docs/mesa-cliente/fase-7-contrato-aplicacao-operacao-financeira.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato canônico. |
| `docs/mesa-cliente/fase-7-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Reconciliar validações. |
| `docs/mesa-cliente/fase-7-preflight-15-execucao.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Não substitui testes finais. |
| `docs/mesa-cliente/fase-7-validacao-15b-aplicacao-positiva.md` | VALIDACAO_POSITIVA / EVIDENCIA_A_VALIDAR | P1 | Precisa negativos. |
| `docs/mesa-cliente/fase-7-validacao-15b-execucao-oficial.md` | VALIDACAO / EXECUCAO_OFICIAL / EVIDENCIA_A_VALIDAR | P0/P1 | Rastrear PR/commit. |
| `docs/mesa-cliente/fase-7-validacao-15e-execucao-oficial.md` | VALIDACAO / EXECUCAO_OFICIAL / EVIDENCIA_A_VALIDAR | P0/P1 | Validar regressão. |
| `docs/mesa-cliente/fase-7-validacao-15e-regressao-final.md` | VALIDACAO_REGRESSAO / EVIDENCIA_A_VALIDAR | P1 | Suíte reproduzível. |
| `docs/mesa-cliente/fase-8-20-pre-pr-main-handoff.md` | HANDOFF / PREFLIGHT_PR / PENDENTE_RECONCILIACAO | P1 | Não é autorização atual. |
| `docs/mesa-cliente/fase-8-chateau-jardin-fechamento-evidencias.md` | EVIDENCIA / IMPORTACAO / A_VALIDAR | P1 | Específico Chateau Jardin. |
| `docs/mesa-cliente/fase-8-chateau-jardin-importacao-json-admin.md` | EVIDENCIA / IMPORTACAO / A_VALIDAR | P1 | Validar payload/acesso admin. |
| `docs/mesa-cliente/fase-8-contrato-integracao-front-bff-operacoes-financeiras.md` | CONTRATO / POSSIVEL_CANONICO_UI_BFF / PENDENTE_RECONCILIACAO | P0/P1 | Candidato Front/BFF. |
| `docs/mesa-cliente/fase-8a-preflight-integracao-front-bff-operacoes-financeiras.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Não autoriza 8B. |
| `docs/mesa-cliente/fase-8b-adapter-front-operacoes-financeiras.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Validar service/hook real. |
| `docs/mesa-cliente/fase-8b-teste-17b-validacao-estatica-front-bff-operacoes-financeiras.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar branch/commit. |
| `docs/mesa-cliente/fase-8b-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Validar PR/código. |
| `docs/mesa-cliente/fase-8c-contrato-operacoes-financeiras-panel.md` | CONTRATO / POSSIVEL_CANONICO_UI_PANEL / PENDENTE_RECONCILIACAO | P1 | Validar componente real. |
| `docs/mesa-cliente/fase-8c-validacao-17c-operacoes-financeiras-panel.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar resultado. |
| `docs/mesa-cliente/fase-8c-validacao-17d-build-operacoes-financeiras-panel.md` | VALIDACAO_BUILD / EVIDENCIA_A_VALIDAR | P1 | Validar artifact. |
| `docs/mesa-cliente/fase-8e-contrato-integracao-visual-operacoes-financeiras-panel.md` | CONTRATO / INTEGRACAO_VISUAL / PENDENTE_RECONCILIACAO | P1 | Não autoriza motor/RPC/migration. |
| `docs/mesa-cliente/fase-8e-validacao-18a-integracao-visual-operacoes-financeiras-panel.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar integração visual. |
| `docs/mesa-cliente/fase-8e-validacao-18b-build-pos-integracao-visual.md` | VALIDACAO_BUILD / EVIDENCIA_A_VALIDAR | P1 | Build não prova fluxo real. |
| `docs/mesa-cliente/fase-8f-contrato-selecao-segura-simulacao-operacoes-financeiras.md` | CONTRATO / SELECAO_SEGURA / PENDENTE_RECONCILIACAO | P0/P1 | Validar origem de simulacaoId. |
| `docs/mesa-cliente/fase-8f-validacao-18c-selecao-segura-simulacao-operacoes-financeiras.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar aderência. |
| `docs/mesa-cliente/fase-8f-validacao-18d-build-pos-selecao-segura.md` | VALIDACAO_BUILD / EVIDENCIA_A_VALIDAR | P1 | Validar build. |
| `docs/mesa-cliente/fase-8g-contrato-fix-rpc-criar-mesa-simulacao-status-enum.md` | CONTRATO_FIX_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Fix RPC/enum precisa Supabase real. |
| `docs/mesa-cliente/fase-8h-contrato-fix-rpc-criar-mesa-corretor-audit.md` | CONTRATO_FIX_RPC / AUDIT / PENDENTE_SUPABASE_REAL | P0/P1 | Validar auth.uid(), tenant, grants. |
| `docs/mesa-cliente/fase-8i-contrato-fix-rpc-criar-mesa-fluxo-tipo-enum.md` | CONTRATO_FIX_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Validar schema/constraints. |
| `docs/mesa-cliente/fase-8j-contrato-validacao-payload-completo-fluxo.md` | CONTRATO_VALIDACAO_PAYLOAD / PENDENTE_RECONCILIACAO | P0/P1 | Validar parser/motor/Supabase. |
| `docs/mesa-cliente/fase-8j-validacao-19d-payload-completo-fluxo.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar reprodução/logs. |
| `docs/mesa-cliente/fase-8k-contrato-smoke-runtime-19e-payload-completo-fluxo.md` | CONTRATO_SMOKE_RUNTIME / PENDENTE_RECONCILIACAO | P0/P1 | Smoke não substitui validação real. |
| `docs/mesa-cliente/fase-8k-validacao-19e-smoke-runtime-payload-completo-fluxo.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Validar ambiente, commit e logs. |

---

## 4. Documentos relacionados fora de `docs/mesa-cliente/`

| Documento | Classificação inicial | Risco | Observação |
|---|---|---:|---|
| `docs/checkpoints/mesa-mirror-engine-garden-design-v1.0.0.md` | CHECKPOINT / HISTORICO / PENDENTE_RECONCILIACAO | P1 | Não é fonte final sozinha. |
| `docs/checkpoints/mesa-layout-engine-v1.1.0.md` | CHECKPOINT / HISTORICO / PENDENTE_RECONCILIACAO | P1 | Reconciliar com MesaCliente atual. |
| `docs/protocolo/mesa-cliente/engenharia-financeira/fase-5d/13e_validacao_filtros_paginacao_ordenacao.md` | VALIDACAO / PROTOCOLO_SINGULAR / POSSIVEL_DUPLICIDADE | P1 | Reconciliar com árvore plural. |
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.1.md` | CONTRATO / POSSIVEL_OBSOLETO / PENDENTE_RECONCILIACAO | P1 | Comparar com v1.2. |
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato forte, mas não oficial vigente ainda. |
| `docs/04-banco-de-dados/mapa-tabelas.md` | RASCUNHO / PENDENTE_SUPABASE_REAL | P0/P1 | Validar com Supabase real. |
| `docs/04-banco-de-dados/rpcs-e-functions.md` | RASCUNHO / PENDENTE_SUPABASE_REAL | P0/P1 | Validar RPCs reais. |
| `docs/04-banco-de-dados/dicionario-de-dados.md` | PENDENTE_RECONCILIACAO | P1 | Comparar com schema real. |
| `docs/02-arquitetura-tecnica/arquitetura-atual.md` | RASCUNHO_PROFISSIONAL / OFICIAL_CANDIDATO | P1 | Define princípio de autoridade em banco/RPC. |
| `docs/06-seguranca-compliance/lgpd.md` | RASCUNHO / PENDENTE_VALIDACAO_JURIDICA | P1 | Aplicável a dados pessoais/simulações/propostas. |
| `docs/product/fechai-modules-map-v1.md` | OFICIAL_CANDIDATO | P2/P1 | Classifica MesaCliente como módulo. |
| `docs/roadmap/fechai-roadmap-master-v1.md` | OFICIAL_CANDIDATO / DIRECAO_FUTURA | P2/P1 | Roadmap não prova estado aplicado. |
| `docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P2 | Knowledge do especialista MesaCliente. |

---

## 5. Matriz de risco

| Risco | Classificação | Bloqueio |
|---|---:|---|
| Documento canônico errado para motor financeiro | P0 | Bloqueia implementação. |
| Vazamento cliente-safe | P0 | Bloqueia UI/preview/proposta. |
| Cross-tenant por RLS/RPC incompleta | P0 | Bloqueia produção. |
| Migration ou SQL documental sem Supabase real | P0 | Bloqueia qualquer SQL. |
| RPC financeira com grants/permissões incorretos | P0 | Bloqueia chamada/deploy. |
| Frontend como autoridade de tenant/empresa/perfil/regra financeira | P0/P1 | Bloqueia implementação sensível. |
| Tabela de disponibilidade divergente da fonte real | P0/P1 | Bloqueia uso como fonte final. |
| Fases históricas conflitantes | P1 | Exige linha do tempo canônica. |
| Smokes/preflights sem ambiente, commit e data | P1 | Não aceitar como prova final. |
| Organização/taxonomia dispersa | P2 | Risco editorial/operacional. |

---

## 6. Critérios para tornar um documento `OFICIAL_VIGENTE`

Um documento só poderá ser marcado como `OFICIAL_VIGENTE` se:

1. existir na árvore Git da branch correta;
2. não tiver versão posterior conflitante;
3. tiver decisão explícita do Wagner ou PR/commit rastreável;
4. for reconciliado com código real;
5. for reconciliado com Supabase real quando envolver banco/RPC/RLS/migrations/grants;
6. não contradizer documentação transversal vigente;
7. possuir validações positivas, negativas, regressão e cross-tenant quando envolver financeiro, proposta ou cliente-safe.

---

## 7. Bloqueios para implementação futura

Não implementar enquanto houver `PENDENTE_RECONCILIACAO`, `PENDENTE_SUPABASE_REAL`, `CONFLITANTE` ou `DRIFT_A_VALIDAR` em item P0/P1.

Bloqueado por enquanto:

```text
novo parser
motor financeiro
alteração de proposta
alteração de fluxo de pagamento
nova RPC ou alteração de RPC existente
migration
policy/RLS/grant
cliente-safe preview
painel financeiro
alteração de hooks/services/componentes
mudança de Vercel/GitHub Actions/produção
automação Make/n8n/Worker
```

---

## 8. Próximos passos sem implementação

1. Validar a árvore completa com `git ls-tree -r --name-only main docs/`.
2. Reconciliar `Documento → fase → PR → commit → código → Supabase → status final`.
3. Abrir auditoria AS-IS de código MesaCliente.
4. Abrir auditoria Supabase/RPC/RLS MesaCliente.
5. Só depois decidir documento canônico vigente.

---

## 9. Parecer final

```text
Status global MesaCliente docs: OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO
Risco global: P0/P1
Tipo da PR: documentação-only
Implementação autorizada: não
Próxima etapa: auditoria AS-IS de código MesaCliente
```
