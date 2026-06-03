# FECH.AI — Auditoria Documental MesaCliente v1

**Data:** 2026-06-03  
**Status:** `OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO`  
**Responsável conceitual:** GPT 0 — FECH.AI Documentation Auditor  
**Branch documental sugerida:** `docs/mesacliente-docs-inventory-v1-20260603`  
**Arquivo alvo:** `docs/audits/documentation/2026-06-03-mesacliente-docs-inventory-v1.md`  
**Tipo:** documentação-only.  
**Escopo proibido:** não altera App, Supabase, RLS, RPCs, migrations, parser, motor financeiro, Worker, Make/n8n, frontend, MesaCliente, LeadOps, PME, Discador, ADS/CAPI, Vercel, GitHub Actions ou produção.

---

## 1. Objetivo da auditoria MesaCliente

Inventariar, classificar e reconciliar documentalmente os documentos relacionados ao MesaCliente antes de qualquer implementação.

Esta auditoria tem finalidade de governança documental. Ela deve permitir decidir, posteriormente, quais documentos do MesaCliente são oficiais, históricos, evidências, rascunhos, propostas, obsoletos, conflitantes ou pendentes de reconciliação com código e Supabase real.

Esta auditoria **não autoriza implementação**.

---

## 2. Escopo documental verificado

Escopo solicitado:

```text
docs/mesa-cliente/
docs/mesa-cliente/adr/
docs/mesa-cliente/importacoes/
docs/checkpoints/
docs/protocolo/mesa-cliente/
docs/protocolos/protocolo-mestre-fechai-mesacliente-*
documentos citados no inventário documental da PR #51 como relacionados ao MesaCliente
```

Fontes efetivamente consultadas nesta entrega:

```text
GitHub público: wagnerjfjunior/fecha.ai
PR #51: docs(audit): add complete documentation tree inventory
docs/audits/documentation/2026-06-03-documentation-tree-inventory-v1.md
Listagem pública de docs/mesa-cliente/
Listagem pública de docs/protocolos/
Listagem pública de docs/protocolo/mesa-cliente/
Documentos locais carregados no GPT 0:
- rpcs-e-functions.md
- mapa-tabelas.md
- arquitetura-atual.md
- lgpd.md
- fechai-modules-map-v1.md
- fechai-roadmap-master-v1.md
- fechai-gpt-registry.md
- BRANCH_REGISTRY.md
```

Limitações assumidas:

```text
- Não foi executado git ls-tree local do repositório.
- Não houve acesso autenticado ao GitHub.
- Não houve leitura completa de todos os arquivos MesaCliente linha a linha.
- Não houve consulta ao Supabase real.
- Não houve inspeção completa do código real.
- Não houve validação de migrations aplicadas.
- A listagem GitHub web pode truncar diretórios com muitos arquivos.
```

Conclusão de escopo:

```text
Inventário documental: amplo, útil para PR documental.
Exaustividade: PENDENTE_RECONCILIACAO até export completo da árvore Git.
Estado aplicado: não afirmável sem código + Supabase real.
```

### 2.1 Validação operacional no Projeto Principal

Esta versão incorpora revisão operacional conceitual registrada no Projeto Principal antes da PR #52.

A revisão aprovou o documento para PR documental com ressalva operacional: validar os caminhos contra a árvore real do GitHub antes do commit ou manter explicitamente o inventário como preliminar. Como o GPT 0 não teve acesso autenticado ao GitHub, Codex, terminal do repositório, `git ls-tree` local ou conector GitHub de escrita, esta auditoria não deve sugerir que houve validação exaustiva da árvore real.

Validação pública pontual realizada antes desta revisão:

```text
- Repositório público identificado: wagnerjfjunior/fecha.ai.
- PR #51 pública identificada como mergeada em main em 2026-06-03.
- Diretórios públicos observados: docs/mesa-cliente/, docs/protocolos/, docs/checkpoints/, docs/protocolo/mesa-cliente/ e docs/audits/documentation/.
- Caminho confirmado publicamente para o arquivo alvo da PR #52: docs/audits/documentation/.
- Nome confirmado publicamente: docs/mesa-cliente/fase-20d4-fonte-soberana-tabela-importada.md.
- Pendência Codex da PR #52 identificou arquivos adicionais da Fase 8 em `docs/mesa-cliente/`; esta revisão inclui os caminhos conhecidos de 8C, 8E, 8F, 8G, 8H, 8I, 8J e 8K sem declarar vigência oficial.
- Pendência posterior Codex da PR #52 identificou `docs/mesa-cliente/tabela-oficial-disponibilidade-v1.md` e `docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md`; esta revisão inclui ambos como pendentes de reconciliação, sem tratá-los como fonte final.
```

Limite desta validação:

```text
A validação pública por GitHub web reduz ambiguidade de nomes e caminhos visíveis,
mas não substitui `git ls-tree -r --name-only main docs/`, leitura integral dos arquivos,
consulta ao Supabase real, diff de PRs, branches e commits, nem inspeção do código.
```

---

## 3. Estado atual vs direção futura

### 3.1 Estado atual comprovado nesta auditoria

```text
- PR #51 foi mergeada e criou o inventário documental amplo.
- O inventário da PR #51 declara MesaCliente como próxima auditoria específica.
- O inventário da PR #51 declara que a auditoria documental não autoriza implementação.
- docs/mesa-cliente/ possui alto volume de documentos de contrato, preflight, validação, smoke, fechamento, evidência, handoff e planos.
- MesaCliente depende de parser, motor financeiro, proposta, histórico, cliente-safe, multi-tenant, RPCs, RLS e Supabase real.
```

### 3.2 Estado atual não comprovado

```text
- Não é possível afirmar qual documento MesaCliente é OFICIAL_VIGENTE.
- Não é possível afirmar quais RPCs MesaCliente existem hoje no Supabase real.
- Não é possível afirmar quais policies/RLS/grants estão aplicados.
- Não é possível afirmar que migrations documentadas foram aplicadas.
- Não é possível afirmar que front/BFF/serviços atuais seguem os contratos documentados.
- Não é possível afirmar que as evidências de smoke/preflight ainda representam produção.
```

### 3.3 Direção futura

```text
- Criar esta auditoria específica MesaCliente como PR #52 documental.
- Depois, reconciliar documentos candidatos com código, Supabase real, PRs e branches.
- Só após essa reconciliação decidir documentação oficial vigente.
```

---

## 4. Lista preliminar de documentos MesaCliente encontrados — a validar por árvore Git

Classificação inicial por nome, localização e relação documental. Esta tabela é um inventário preliminar e deve ser reconciliada contra `git ls-tree -r --name-only main docs/` antes de ser tratada como exaustiva. Ela não substitui leitura integral de cada arquivo.

| Documento | Classificação inicial | Risco | Uso permitido nesta auditoria |
|---|---|---:|---|
| `docs/mesa-cliente/adr/` | ADR / CHECKPOINT / PENDENTE_RECONCILIACAO | P1 | Diretório de decisões arquiteturais; usar somente após validar ADRs contra código/Supabase. |
| `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md` | ADR / CHECKPOINT / PENDENTE_RECONCILIACAO | P1 | Registra decisão JSON-first sem persistência; pode conflitar com fases posteriores de persistência. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/` | EVIDENCIA / OPERACIONAL / PENDENTE_RECONCILIACAO | P1 | Importação específica; não generalizar como contrato do MesaCliente. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/README.md` | EVIDENCIA / OPERACIONAL / PENDENTE_RECONCILIACAO | P1 | Evidência de importação; validar origem, payload, tabelas e ambiente. |
| `docs/mesa-cliente/importacoes/chateau-jardin/2026-05/MANIFEST.local-files.md` | MANIFEST / OPERACIONAL / PENDENTE_RECONCILIACAO | P1 | Manifest de arquivos locais da importação; validar presença, origem, payloads e vínculo com importação real. |
| `docs/mesa-cliente/rascunhos-sql/` | RASCUNHO / NAO_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Não usar para implementar ou aplicar SQL sem comparação com migrations e Supabase real. |
| `docs/mesa-cliente/engenharia-financeira-arquitetura.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Possível base arquitetural; depende de reconciliação com código, Supabase e decisões mais recentes. |
| `docs/mesa-cliente/engenharia-financeira-plano-implementacao.md` | PROPOSTA / PLANO / PENDENTE_RECONCILIACAO | P1 | Plano não prova implementação. |
| `docs/mesa-cliente/engenharia-financeira-producao-unica-backup-rollback.md` | CHECKPOINT / OPERACIONAL / EVIDENCIA_A_VALIDAR | P1 | Pode conter regra de produção/rollback; validar PR, commit, ambiente e data. |
| `docs/mesa-cliente/engenharia-financeira-roadmap-execucao-ate-mesa-cliente.md` | PROPOSTA / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Roadmap orienta, não prova estado aplicado. |
| `docs/mesa-cliente/espelho-intelligence-layer.md` | OFICIAL_CANDIDATO / PROPOSTA / PENDENTE_RECONCILIACAO | P1 | Camada de inteligência precisa validação de escopo, IA, payload e privacidade. |
| `docs/mesa-cliente/espelho-vendas-engine-v1.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Possível contrato de engine; validar contra motor financeiro real. |
| `docs/mesa-cliente/frontend-preview-rpc-integration.md` | OFICIAL_CANDIDATO / INTEGRACAO_FRONT_RPC / PENDENTE_RECONCILIACAO | P1 | Documento de integração Frontend RPC Preview; validar contra código real, Supabase, payload e ausência de autoridade do frontend. |
| `docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md` | PREFLIGHT / RECONCILIACAO_GITHUB_SUPABASE / EVIDENCIA_A_VALIDAR | P0/P1 | Reconciliação pré-20C entre GitHub e Supabase; validar leitura integral, PRs, commits e Supabase real antes de usar como fonte final. |
| `docs/mesa-cliente/tabela-oficial-disponibilidade-v1.md` | TABELA_DISPONIBILIDADE / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Tabela oficial de disponibilidade pode impactar oferta, proposta, estoque e simulação; validar fonte, freshness, importação e Supabase real. |
| `docs/mesa-cliente/fase-20a-contrato-reabrir-fluxo-historico.md` | CONTRATO / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Reabertura de fluxo/histórico é sensível; validar RPC/RLS/ownership. |
| `docs/mesa-cliente/fase-20a-validacao-rpc-reabrir-fluxo-historico.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Evidência precisa de ambiente, data, commit, usuário e resultados negativos. |
| `docs/mesa-cliente/fase-20a1-validacao-hardening-acesso-fluxo-historico.md` | VALIDACAO / SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Acesso a histórico pode causar vazamento; exigir testes cross-tenant. |
| `docs/mesa-cliente/fase-20c-contrato-rastreabilidade-valores.md` | CONTRATO / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Rastreabilidade de valores pode ser canônica; validar contra schema/RPC. |
| `docs/mesa-cliente/fase-20c-rastreabilidade-fluxo-historico.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Documento de rastreabilidade; precisa matriz com código e banco. |
| `docs/mesa-cliente/fase-20c0-overview-documental-e-reclassificacao-rastreabilidade.md` | OFICIAL_CANDIDATO / INVENTARIO_PARCIAL / PENDENTE_RECONCILIACAO | P1 | Pode orientar esta auditoria, mas não substitui inventário completo. |
| `docs/mesa-cliente/fase-20c1-checklist-preflight-estado-real.md` | PREFLIGHT / CHECKLIST / EVIDENCIA_A_VALIDAR | P1 | Checklist não é prova sem execução e logs. |
| `docs/mesa-cliente/fase-20c1-relatorio-preflight-estado-real.md` | EVIDENCIA / RELATORIO / PENDENTE_RECONCILIACAO | P1 | Relatório deve ser confrontado com estado real atual. |
| `docs/mesa-cliente/fase-20c2-gate-b-diagnostico-warns-seguranca.md` | VALIDACAO / SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Warnings de segurança podem bloquear implementação. |
| `docs/mesa-cliente/fase-20c2-plano-piloto-controlado-mesa.md` | PROPOSTA / PLANO / PENDENTE_RECONCILIACAO | P1 | Piloto controlado não é produção nem contrato final. |
| `docs/mesa-cliente/fase-20c2-revisao-rpc-gerar-agenda-financeira.md` | REVISAO_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Validar function, grants, security definer/invoker, RLS e testes. |
| `docs/mesa-cliente/fase-20c2-revisao-rpc-persistir-agenda-financeira.md` | REVISAO_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Persistência financeira exige validação de DML, RLS, rollback e idempotência. |
| `docs/mesa-cliente/fase-20c3-decisao-opcao-a-payload-adaptado-piloto.md` | DECISAO / PROPOSTA / PENDENTE_RECONCILIACAO | P1 | Decisão de piloto deve ser comparada com contrato canônico final. |
| `docs/mesa-cliente/fase-20c3-encerramento-pass.md` | EVIDENCIA_VALIDACAO / CHECKPOINT / A_VALIDAR | P1 | PASS precisa evidência reproduzível, ambiente e commit. |
| `docs/mesa-cliente/fase-20c3-evidencia-geracao-agenda-4a-json-first.md` | EVIDENCIA / VALIDACAO / A_VALIDAR | P1 | Evidência de geração JSON-first; pode ser histórica frente à persistência. |
| `docs/mesa-cliente/fase-20c3-plano-execucao-controlada-modo-3.md` | PROPOSTA / PLANO / PENDENTE_RECONCILIACAO | P1 | Plano de execução controlada não autoriza implementação. |
| `docs/mesa-cliente/fase-20c3-relatorio-execucao-controlada-modo-3.md` | EVIDENCIA / RELATORIO / A_VALIDAR | P1 | Relatório precisa reconciliação com logs, PR e Supabase. |
| `docs/mesa-cliente/fase-20c3-selecao-readonly-simulacao-candidata.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Seleção read-only não prova que operação de escrita é segura. |
| `docs/mesa-cliente/fase-20d-contrato-adaptador-historico-agenda-canonica.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato canônico para adaptador histórico/agenda; validar com código e Supabase. |
| `docs/mesa-cliente/fase-20d1-revisao-readonly-schema-real.md` | REVISAO_SCHEMA / EVIDENCIA_A_VALIDAR | P0/P1 | Alega schema real; precisa comprovar fonte, data e Supabase project. |
| `docs/mesa-cliente/fase-20d3-proposta-rpc-adaptadora-readonly.md` | PROPOSTA_RPC / PENDENTE_SUPABASE_REAL | P1 | Proposta não é RPC aplicada. |
| `docs/mesa-cliente/fase-20d4-ajuste-semantico-chaves-complemento-entrada.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Ajuste semântico de chaves deve casar com parser, payload e banco. |
| `docs/mesa-cliente/fase-20d4-contrato-canonico-fluxo-financeiro.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Forte candidato canônico do fluxo financeiro; bloquear uso até validação. |
| `docs/mesa-cliente/fase-20d4-fonte-soberana-tabela-importada.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Define soberania de tabela importada; validar parser/importação/Supabase. |
| `docs/mesa-cliente/fase-20d4-regra-mensais-intermediarias.md` | CONTRATO / OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P0/P1 | Regra financeira sensível; validar cálculo e regressão. |
| `docs/mesa-cliente/fase-20d4-status-migration-adaptador-readonly.md` | STATUS_MIGRATION / PENDENTE_SUPABASE_REAL | P0/P1 | Não aceitar status sem confirmar migration aplicada e efeitos. |
| `docs/mesa-cliente/fase-20d5-evidencia-http-bloqueio-shadow.md` | EVIDENCIA_SEGURANCA / A_VALIDAR | P0/P1 | Bloqueio HTTP/shadow precisa logs, ambiente, commit e testes negativos. |
| `docs/mesa-cliente/fase-20d5-evidencias-testes-shadow.md` | EVIDENCIA_VALIDACAO / A_VALIDAR | P1 | Evidências shadow podem ser ambiente específico. |
| `docs/mesa-cliente/fase-20d5-migration-fluxo-canonico-shadow.md` | MIGRATION_DOC / PENDENTE_SUPABASE_REAL / NAO_CANONICO_SOZINHO | P0/P1 | Documento com migration não prova aplicação; exigir Supabase real e migration hash. |
| `docs/mesa-cliente/fase-20d5-plano-correcao-origem-fluxo-financeiro.md` | PROPOSTA / PLANO / PENDENTE_RECONCILIACAO | P1 | Plano de correção deve ser validado antes de qualquer execução. |
| `docs/mesa-cliente/fase-4a-agenda-financeira-handoff.md` | HANDOFF / RASCUNHO_OPERACIONAL / PENDENTE_RECONCILIACAO | P1 | Handoff não é fonte final. |
| `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md` | CONTRATO / POSSIVEL_CANONICO_HISTORICO / PENDENTE_RECONCILIACAO | P1 | Pode estar superado por persistência e fase 20D. |
| `docs/mesa-cliente/fase-4a-rpc-gerar-agenda-financeira.md` | CONTRATO_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Validar função real, grants, RLS e payload. |
| `docs/mesa-cliente/fase-4a-validacao-final-json-first.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validação final de fase histórica, não prova versão atual. |
| `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md` | VALIDACAO / TRANSICAO / EVIDENCIA_A_VALIDAR | P1 | Documento de transição; checar se foi supersedido. |
| `docs/mesa-cliente/fase-4b-contrato-persistencia-agenda-financeira.md` | CONTRATO / PENDENTE_SUPABASE_REAL | P0/P1 | Persistência de agenda financeira é crítica. |
| `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar evidências contra Supabase/código atuais. |
| `docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md` | CONTRATO_CLIENTE_SAFE / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Cliente-safe exige allowlist e teste de vazamento. |
| `docs/mesa-cliente/fase-4c-cliente-safe-fechamento.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Fechamento não dispensa reconciliação. |
| `docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Simulação de impacto financeiro depende de cálculo real. |
| `docs/mesa-cliente/fase-5a-evidencia-10p-preparacao-base-minima.md` | EVIDENCIA / A_VALIDAR | P1 | Preparação de base mínima precisa dados/ambiente. |
| `docs/mesa-cliente/fase-5a-preflight-10-resultado-readonly.md` | PREFLIGHT / READONLY / EVIDENCIA_A_VALIDAR | P1 | Read-only não prova segurança de escrita. |
| `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar contra regressões. |
| `docs/mesa-cliente/fase-5a-validacao-parcial-10a-10b.md` | VALIDACAO_PARCIAL / EVIDENCIA_A_VALIDAR | P2/P1 | Parcial não pode orientar implementação final. |
| `docs/mesa-cliente/fase-5a1-contrato-simulacao-impacto-financeiro.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Contrato financeiro precisa reconciliação com motor atual. |
| `docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Registro de operação financeira é núcleo crítico. |
| `docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Fechamento deve ser cruzado com PR/Supabase. |
| `docs/mesa-cliente/fase-5b-validacao-11a-registro-operacao-financeira.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validar positivo e negativos. |
| `docs/mesa-cliente/fase-5b-validacao-11b-negativos-registro-operacao-financeira.md` | VALIDACAO_NEGATIVA / EVIDENCIA_A_VALIDAR | P0/P1 | Negativos são essenciais para acesso e payload. |
| `docs/mesa-cliente/fase-5b-validacao-11c-idempotencia-registro-operacao-financeira.md` | VALIDACAO_IDEMPOTENCIA / EVIDENCIA_A_VALIDAR | P1 | Idempotência financeira precisa teste atual. |
| `docs/mesa-cliente/fase-5b-validacao-11d-operacao-confirmada-conflito.md` | VALIDACAO_CONFLITO / EVIDENCIA_A_VALIDAR | P1 | Conflito confirmado afeta consistência financeira. |
| `docs/mesa-cliente/fase-5b-validacao-11e-zero-mutacao-agenda-parcelas.md` | VALIDACAO_ZERO_MUTACAO / EVIDENCIA_A_VALIDAR | P0/P1 | Zero mutação deve ser comprovado em banco. |
| `docs/mesa-cliente/fase-5b-validacao-preflight-11.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Preflight não é estado final. |
| `docs/mesa-cliente/fase-5c-ambiente-limpo-e-plano-execucao.md` | PREFLIGHT / PLANO / PENDENTE_RECONCILIACAO | P1 | Ambiente limpo declarado precisa evidência. |
| `docs/mesa-cliente/fase-5c-changelog.md` | CHANGELOG / HISTORICO | P2 | Histórico; não prova estado atual sem PR/commit. |
| `docs/mesa-cliente/fase-5c-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Fechamento técnico precisa reconciliação. |
| `docs/mesa-cliente/fase-5c-smoke-pos-producao.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Smoke pós-produção é sensível; validar ambiente e data. |
| `docs/mesa-cliente/fase-5c-validacao-12a-confirmacao-operacao-financeira.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Confirmação financeira precisa evidência atual. |
| `docs/mesa-cliente/fase-5c-validacao-12b-cancelamento-operacao-financeira.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Cancelamento precisa validar auditabilidade e rollback. |
| `docs/mesa-cliente/fase-5c-validacao-12c-negativos-seguranca.md` | VALIDACAO_NEGATIVA_SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Segurança negativa pode bloquear qualquer avanço. |
| `docs/mesa-cliente/fase-5c-validacao-12d-idempotencia.md` | VALIDACAO_IDEMPOTENCIA / EVIDENCIA_A_VALIDAR | P1 | Idempotência deve ser repetível. |
| `docs/mesa-cliente/fase-5c-validacao-12e-zero-mutacao-rigido.md` | VALIDACAO_ZERO_MUTACAO / EVIDENCIA_A_VALIDAR | P0/P1 | Zero mutação rígido precisa prova em logs/banco. |
| `docs/mesa-cliente/fase-5c-validacao-preflight-12.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Preflight não autoriza implementação. |
| `docs/mesa-cliente/fase-5c-validacao-smoke-pos-producao.md` | SMOKE_TEST / VALIDACAO / EVIDENCIA_A_VALIDAR | P0/P1 | Validar com ambiente/commit. |
| `docs/mesa-cliente/fase-5d-contrato-leitura-operacoes-admin.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Leitura admin deve validar perfil, tenant e client-safe. |
| `docs/mesa-cliente/fase-5d-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Consolidar com validações 13A-13E. |
| `docs/mesa-cliente/fase-5d-smoke-pos-producao-execucao.md` | SMOKE_TEST / EXECUCAO / EVIDENCIA_A_VALIDAR | P0/P1 | Smoke de produção exige rastreabilidade. |
| `docs/mesa-cliente/fase-5d-smoke-pos-producao.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Pode estar duplicado com execução. |
| `docs/mesa-cliente/fase-5d-validacao-13a-listar-operacoes-admin.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Listagem admin deve validar filtros/tenant. |
| `docs/mesa-cliente/fase-5d-validacao-13b-obter-operacao-admin.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Obter operação admin exige ownership. |
| `docs/mesa-cliente/fase-5d-validacao-13c-seguranca-leitura-operacoes-admin.md` | VALIDACAO_SEGURANCA / EVIDENCIA_A_VALIDAR | P0/P1 | Leitura admin insegura pode vazar dados. |
| `docs/mesa-cliente/fase-5d-validacao-13d-zero-dml-readonly-rigido.md` | VALIDACAO_ZERO_DML / EVIDENCIA_A_VALIDAR | P0/P1 | Read-only deve provar ausência de DML. |
| `docs/mesa-cliente/fase-5d-validacao-preflight-13.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR | P1 | Preflight não é aceitação final. |
| `docs/protocolo/mesa-cliente/engenharia-financeira/fase-5d/13e_validacao_filtros_paginacao_ordenacao.md` | VALIDACAO / PROTOCOLO_SINGULAR / POSSIVEL_DUPLICIDADE | P1 | Fica fora da árvore plural; reconciliar com Fase 5D principal. |
| `docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md` | CONTRATO / PENDENTE_RECONCILIACAO | P0/P1 | Resumos podem expor valores; validar cliente-safe/admin. |
| `docs/mesa-cliente/fase-6-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Fechamento precisa PR/Supabase. |
| `docs/mesa-cliente/fase-6-preflight-14-execucao.md` | PREFLIGHT / EXECUCAO / EVIDENCIA_A_VALIDAR | P1 | Preflight de execução não autoriza mudança futura. |
| `docs/mesa-cliente/fase-6-smoke-pos-producao-execucao.md` | SMOKE_TEST / EXECUCAO / EVIDENCIA_A_VALIDAR | P0/P1 | Validar ambiente produção e impacto. |
| `docs/mesa-cliente/fase-7-15a-status-operacao-aplicada-execucao.md` | EXECUCAO / EVIDENCIA_A_VALIDAR | P0/P1 | Status aplicada altera fluxo financeiro; validar constraint/RPC. |
| `docs/mesa-cliente/fase-7-aplicacao-operacao-financeira-execucao.md` | EXECUCAO / EVIDENCIA_A_VALIDAR | P0/P1 | Aplicação financeira é crítica; exigir logs, rollback, idempotência. |
| `docs/mesa-cliente/fase-7-contrato-aplicacao-operacao-financeira.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato canônico para aplicação financeira. |
| `docs/mesa-cliente/fase-7-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Confrontar com validações 15B/15E. |
| `docs/mesa-cliente/fase-7-preflight-15-execucao.md` | PREFLIGHT / EXECUCAO / EVIDENCIA_A_VALIDAR | P1 | Preflight não substitui testes finais. |
| `docs/mesa-cliente/fase-7-validacao-15b-aplicacao-positiva.md` | VALIDACAO_POSITIVA / EVIDENCIA_A_VALIDAR | P1 | Teste positivo precisa negativos correspondentes. |
| `docs/mesa-cliente/fase-7-validacao-15b-execucao-oficial.md` | VALIDACAO / EXECUCAO_OFICIAL / EVIDENCIA_A_VALIDAR | P0/P1 | Execução oficial precisa rastreio de PR/commit/ambiente. |
| `docs/mesa-cliente/fase-7-validacao-15e-execucao-oficial.md` | VALIDACAO / EXECUCAO_OFICIAL / EVIDENCIA_A_VALIDAR | P0/P1 | Validar regressões e cross-tenant. |
| `docs/mesa-cliente/fase-7-validacao-15e-regressao-final.md` | VALIDACAO_REGRESSAO / EVIDENCIA_A_VALIDAR | P1 | Regressão final precisa suíte reproduzível. |
| `docs/mesa-cliente/fase-8-20-pre-pr-main-handoff.md` | HANDOFF / PREFLIGHT_PR / PENDENTE_RECONCILIACAO | P1 | Handoff pré-PR não é autorização atual. |
| `docs/mesa-cliente/fase-8-chateau-jardin-fechamento-evidencias.md` | EVIDENCIA / IMPORTACAO / A_VALIDAR | P1 | Evidência específica Chateau Jardin. |
| `docs/mesa-cliente/fase-8-chateau-jardin-importacao-json-admin.md` | EVIDENCIA / IMPORTACAO / A_VALIDAR | P1 | Admin importação JSON exige validação de payload e acesso. |
| `docs/mesa-cliente/fase-8-contrato-integracao-front-bff-operacoes-financeiras.md` | CONTRATO / POSSIVEL_CANONICO_UI_BFF / PENDENTE_RECONCILIACAO | P0/P1 | Candidato canônico de integração front/BFF; validar código. |
| `docs/mesa-cliente/fase-8a-preflight-integracao-front-bff-operacoes-financeiras.md` | PREFLIGHT / EVIDENCIA_A_VALIDAR / NAO_AUTORIZA_IMPLEMENTACAO | P1 | Mapeia front e RPCs, mas nesta auditoria não autoriza 8B. |
| `docs/mesa-cliente/fase-8b-adapter-front-operacoes-financeiras.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P1 | Adapter/Front BFF de operações financeiras; validar contra service/hook real e PRs da fase. |
| `docs/mesa-cliente/fase-8b-teste-17b-validacao-estatica-front-bff-operacoes-financeiras.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validação estática 17B do Front/BFF; exige confirmação de commit, branch, logs e código atual. |
| `docs/mesa-cliente/fase-8b-fechamento-tecnico.md` | CHECKPOINT / EVIDENCIA_A_VALIDAR | P1 | Fechamento técnico da fase 8B; validar existência, PR, commit e aderência ao código atual. |
| `docs/mesa-cliente/fase-8c-contrato-operacoes-financeiras-panel.md` | CONTRATO / POSSIVEL_CANONICO_UI_PANEL / PENDENTE_RECONCILIACAO | P1 | Contrato do OperacoesFinanceirasPanel; validar contra componente real e fronteira admin/cliente-safe. |
| `docs/mesa-cliente/fase-8c-validacao-17c-operacoes-financeiras-panel.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validação estática 17C do painel; exige rastreabilidade de branch, commit e resultado. |
| `docs/mesa-cliente/fase-8c-validacao-17d-build-operacoes-financeiras-panel.md` | VALIDACAO_BUILD / EVIDENCIA_A_VALIDAR | P1 | Build validation 17D do painel; validar artifact, commit e escopo sem alteração financeira. |
| `docs/mesa-cliente/fase-8e-contrato-integracao-visual-operacoes-financeiras-panel.md` | CONTRATO / INTEGRACAO_VISUAL / PENDENTE_RECONCILIACAO | P1 | Contrato de integração visual do painel na navegação; não autoriza motor, parser, RPCs, migrations, agenda ou parcelas. |
| `docs/mesa-cliente/fase-8e-validacao-18a-integracao-visual-operacoes-financeiras-panel.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validação 18A da integração visual; validar PR, código e ausência de alterações proibidas. |
| `docs/mesa-cliente/fase-8e-validacao-18b-build-pos-integracao-visual.md` | VALIDACAO_BUILD / EVIDENCIA_A_VALIDAR | P1 | Build pós-integração visual 18B; comprova compilação, não comprova fluxo funcional com simulação real. |
| `docs/mesa-cliente/fase-8f-contrato-selecao-segura-simulacao-operacoes-financeiras.md` | CONTRATO / SELECAO_SEGURA / PENDENTE_RECONCILIACAO | P0/P1 | Seleção segura de simulação para operações financeiras; validar origem confiável de simulacaoId e proibição de derivação indevida. |
| `docs/mesa-cliente/fase-8f-validacao-18c-selecao-segura-simulacao-operacoes-financeiras.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validação 18C da seleção segura; exige PR/commit, testes e aderência ao contrato. |
| `docs/mesa-cliente/fase-8f-validacao-18d-build-pos-selecao-segura.md` | VALIDACAO_BUILD / EVIDENCIA_A_VALIDAR | P1 | Build 18D pós-seleção segura; validar artifact, branch e ausência de mutação financeira indevida. |
| `docs/mesa-cliente/fase-8g-contrato-fix-rpc-criar-mesa-simulacao-status-enum.md` | CONTRATO_FIX_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Fix relacionado a RPC/status enum; não comprova aplicação sem Supabase real, migration e grants. |
| `docs/mesa-cliente/fase-8h-contrato-fix-rpc-criar-mesa-corretor-audit.md` | CONTRATO_FIX_RPC / AUDIT / PENDENTE_SUPABASE_REAL | P0/P1 | Fix de RPC/auditoria de corretor; validar auth.uid(), tenant, empresa, perfil, logs e grants reais. |
| `docs/mesa-cliente/fase-8i-contrato-fix-rpc-criar-mesa-fluxo-tipo-enum.md` | CONTRATO_FIX_RPC / PENDENTE_SUPABASE_REAL | P0/P1 | Fix de RPC/enum de tipo de fluxo; validar schema real, constraints e testes negativos. |
| `docs/mesa-cliente/fase-8j-contrato-validacao-payload-completo-fluxo.md` | CONTRATO_VALIDACAO_PAYLOAD / PENDENTE_RECONCILIACAO | P0/P1 | Contrato de payload completo do fluxo; validar parser, motor financeiro, payload cliente-safe e Supabase. |
| `docs/mesa-cliente/fase-8j-validacao-19d-payload-completo-fluxo.md` | VALIDACAO / EVIDENCIA_A_VALIDAR | P1 | Validação 19D do payload completo; exige reprodução, commit, logs e comparação com payload real. |
| `docs/mesa-cliente/fase-8k-contrato-smoke-runtime-19e-payload-completo-fluxo.md` | CONTRATO_SMOKE_RUNTIME / PENDENTE_RECONCILIACAO | P0/P1 | Contrato de smoke runtime 19E; não substitui validação de produção/Supabase/código real. |
| `docs/mesa-cliente/fase-8k-validacao-19e-smoke-runtime-payload-completo-fluxo.md` | SMOKE_TEST / EVIDENCIA_A_VALIDAR | P0/P1 | Smoke runtime 19E do payload completo; validar ambiente, commit, logs e ausência de alteração proibida. |
| `docs/checkpoints/mesa-mirror-engine-garden-design-v1.0.0.md` | CHECKPOINT / HISTORICO / PENDENTE_RECONCILIACAO | P1 | Referência histórica/layout/engine; não fonte final sozinha. |
| `docs/checkpoints/mesa-layout-engine-v1.1.0.md` | CHECKPOINT / HISTORICO / PENDENTE_RECONCILIACAO | P1 | Referência histórica/layout/engine; reconciliar com MesaCliente atual. |
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.1.md` | CONTRATO / POSSIVEL_OBSOLETO_OU_CHECKPOINT / PENDENTE_RECONCILIACAO | P1 | Pode estar superado pela v1.2; não assumir sem diff. |
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md` | CONTRATO / POSSIVEL_CANONICO / PENDENTE_RECONCILIACAO | P0/P1 | Candidato a protocolo mestre vigente; precisa diff com v1.1 e código/Supabase. |
| `docs/04-banco-de-dados/mapa-tabelas.md` | RASCUNHO / PENDENTE_SUPABASE_REAL | P0/P1 | Documento transversal; contém MesaCliente, mas declara não ser verdade final. |
| `docs/04-banco-de-dados/rpcs-e-functions.md` | RASCUNHO / PENDENTE_SUPABASE_REAL | P0/P1 | Documento transversal; RPCs críticas a validar. |
| `docs/04-banco-de-dados/dicionario-de-dados.md` | PENDENTE_RECONCILIACAO | P1 | Identificado no inventário PR #51; precisa leitura e comparação com Supabase. |
| `docs/02-arquitetura-tecnica/arquitetura-atual.md` | RASCUNHO_PROFISSIONAL / OFICIAL_CANDIDATO | P1 | Define princípio de autoridade banco/RPC; não prova implementação. |
| `docs/06-seguranca-compliance/lgpd.md` | RASCUNHO / PENDENTE_VALIDACAO_JURIDICA | P1 | Transversal; MesaCliente trata simulações/propostas e dados pessoais. |
| `docs/product/fechai-modules-map-v1.md` | OFICIAL_CANDIDATO | P2/P1 | Classifica MesaCliente como M3; não prova implementação. |
| `docs/roadmap/fechai-roadmap-master-v1.md` | OFICIAL_CANDIDATO / DIRECAO_FUTURA | P2/P1 | Define Fase 3 MesaCliente; não prova estado aplicado. |
| `docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md` | OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO | P2 | Identificado no inventário PR #51; validar conteúdo e freshness do Knowledge. |

---

## 5. Matriz de risco P0/P1/P2/P3

| Risco | Classificação | Motivo | Bloqueio |
|---|---:|---|---|
| Documento canônico errado para motor financeiro | P0 | Pode gerar proposta, fluxo, desconto, acréscimo ou comissão incorreta. | Bloqueia implementação. |
| Vazamento cliente-safe | P0 | Payload pode expor VPL interno, comissão, prêmio, política, tenant, user_id ou metadata. | Bloqueia UI/preview/proposta. |
| Cross-tenant por RLS/RPC incompleta | P0 | MesaCliente contém dados financeiros e comerciais por empresa/tenant. | Bloqueia produção. |
| Aplicar migration documentada sem Supabase real | P0 | Pode alterar schema/constraint/RPC e perder dados. | Bloqueia qualquer SQL. |
| RPC financeira com grants/permissões incorretos | P0 | RPCs podem executar escrita, aplicação, cancelamento ou leitura admin. | Bloqueia chamada e deploy. |
| Frontend como autoridade de empresa/perfil/regra financeira | P0/P1 | Contraria princípio arquitetural de autoridade no banco/RPC. | Bloqueia implementação sensível. |
| Tabela de disponibilidade divergente da fonte importada ou Supabase | P0/P1 | Pode afetar estoque, oferta, proposta e simulação comercial. | Bloqueia uso como fonte final. |
| Duplicidade `docs/protocolo/` vs `docs/protocolos/` | P1 | Pode orientar por protocolo errado ou incompleto. | Exige diff documental. |
| Versões de protocolo MesaCliente v1.1 vs v1.2 | P1 | Pode haver contrato substituído ou conflito de escopo. | Exige comparação. |
| Fases históricas JSON-first vs fases persistidas/canônicas | P1 | Fase 4A pode estar superada por 4B/5/20D. | Exige linha do tempo. |
| Evidências/smokes sem ambiente/commit/data | P1 | PASS antigo pode não representar estado atual. | Exige rastreabilidade. |
| Arquivos de plano/handoff tratados como oficiais | P1 | Proposta não comprova aplicação. | Não usar como fonte final. |
| Documentos de rascunho SQL | P1/P0 | SQL solto pode divergir de migrations. | Bloqueia uso operacional. |
| Organização e taxonomia dispersas | P2 | Dificulta manutenção e onboarding. | Não bloqueia auditoria. |
| Caminho documental citado sem validação por árvore Git | P2/P1 | Pode induzir PR a referenciar arquivo inexistente ou nome antigo. | Validar com `git ls-tree` ou marcar como `NOME_A_VALIDAR`. |
| Nomenclatura inconsistente e histórico longo | P2 | Aumenta risco de erro humano. | Recomendar normalização posterior. |
| Melhorias editoriais | P3 | Formatação, sumário, links e metadados. | Não bloqueia estado atual. |

---

## 6. Documentos possivelmente canônicos

Nenhum documento foi marcado como `OFICIAL_VIGENTE` nesta auditoria. Os candidatos abaixo só podem virar oficiais após reconciliação.

| Candidato | Por que pode ser canônico | Reconciliação exigida |
|---|---|---|
| `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md` | Maior versão do protocolo mestre identificado. | Diff contra v1.1, validação com decisão do Wagner, código e Supabase. |
| `docs/mesa-cliente/engenharia-financeira-arquitetura.md` | Documento arquitetural de base. | Confirmar aderência a fases 20D/8 e código atual. |
| `docs/mesa-cliente/espelho-vendas-engine-v1.md` | Pode descrever engine comercial/financeira. | Validar motor real, testes de cálculo e payload. |
| `docs/mesa-cliente/tabela-oficial-disponibilidade-v1.md` | Pode orientar disponibilidade/estoque oficial. | Validar fonte, data, importação, Supabase real e aderência ao fluxo de proposta. |
| `docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md` | Pode conter reconciliação relevante entre documentação, GitHub e Supabase. | Validar leitura integral, data, commit, queries read-only e Supabase real. |
| `docs/mesa-cliente/fase-20d4-contrato-canonico-fluxo-financeiro.md` | Nomeia contrato canônico do fluxo financeiro. | Validar contra schema, RPCs, migrations e testes. |
| `docs/mesa-cliente/fase-20d4-fonte-soberana-tabela-importada.md` | Define soberania de tabela importada. | Nome confirmado publicamente no GitHub web; ainda requer parser, importação e Supabase real. |
| `docs/mesa-cliente/fase-20d-contrato-adaptador-historico-agenda-canonica.md` | Pode consolidar histórico + agenda canônica. | Validar com histórico/2ª via e RPCs read-only. |
| `docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md` | Contrato cliente-safe crítico. | Validar allowlist, payload real e UI. |
| `docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md` | Registro de operação financeira. | Validar idempotência, status, tabela e RLS. |
| `docs/mesa-cliente/fase-7-contrato-aplicacao-operacao-financeira.md` | Aplicação financeira. | Validar status `aplicada`, constraint, RPC e logs. |
| `docs/mesa-cliente/fase-8-contrato-integracao-front-bff-operacoes-financeiras.md` | Integração Front/BFF. | Validar service/hook/componentes reais e ausência de autoridade no frontend. |
| `docs/mesa-cliente/fase-8e-contrato-integracao-visual-operacoes-financeiras-panel.md` | Integração visual controlada do painel de operações. | Validar contra navegação real, gating visual e ausência de chamada financeira sem `simulacaoId`. |
| `docs/mesa-cliente/fase-8f-contrato-selecao-segura-simulacao-operacoes-financeiras.md` | Seleção segura de simulação para operações. | Validar origem confiável de `simulacaoId`, histórico e ausência de derivação indevida. |
| `docs/mesa-cliente/fase-8j-contrato-validacao-payload-completo-fluxo.md` | Payload completo do fluxo financeiro. | Validar parser, motor financeiro, cliente-safe, Supabase e testes de regressão. |
| `docs/mesa-cliente/fase-8k-contrato-smoke-runtime-19e-payload-completo-fluxo.md` | Smoke runtime de payload completo. | Validar ambiente, commit, artifact, logs e ausência de mutação indevida. |
| `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md` | Decisão arquitetural histórica. | Verificar se foi supersedida por persistência. |
| `docs/04-banco-de-dados/mapa-tabelas.md` | Mapa transversal de tabelas. | Só oficial após Supabase real. |
| `docs/04-banco-de-dados/rpcs-e-functions.md` | Mapa transversal de RPCs. | Só oficial após Supabase real. |

---

## 7. Documentos que não podem ser usados como fonte final ainda

Não usar como fonte final para implementação:

```text
- Qualquer documento com "plano", "proposta", "handoff", "preflight", "rascunho", "status migration", "migration" ou "smoke" sem evidência externa.
- docs/mesa-cliente/rascunhos-sql/*
- docs/mesa-cliente/fase-20d5-migration-fluxo-canonico-shadow.md
- docs/mesa-cliente/fase-20d4-status-migration-adaptador-readonly.md
- docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md sem reconciliação atual com Supabase real.
- docs/mesa-cliente/tabela-oficial-disponibilidade-v1.md sem validação de fonte, data e estado aplicado.
- docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.1.md sem diff contra v1.2.
- docs/protocolo/mesa-cliente/* sem reconciliação com docs/protocolos/ e docs/mesa-cliente/.
- docs/checkpoints/* como se fossem vigentes.
- evidências de produção sem commit, ambiente, data, autor, payload e resultado reproduzível.
```

Motivo:

```text
Documentação sem evidência não é verdade final.
Documento com "migration" não prova migration aplicada.
Documento com "PASS" não prova estado atual.
Documento de protocolo antigo pode ser histórico.
Documento de preflight não autoriza implementação.
Documento de disponibilidade não prova estoque atual sem fonte validada.
```

---

## 8. Conflitos e duplicidades possíveis

| Conflito/duplicidade | Risco | Evidência documental | Ação segura |
|---|---:|---|---|
| `docs/protocolos/` vs `docs/protocolo/` | P1 | Existem árvore plural e singular relacionadas ao MesaCliente. | Fazer diff e decidir trilha oficial. |
| `protocolo-mestre-fechai-mesacliente-v1.1.md` vs `v1.2.md` | P1 | Duas versões do protocolo mestre. | Comparar conteúdo e marcar v1.1 como checkpoint/obsoleto se aplicável. |
| Fase 4A JSON-first sem persistência vs Fase 4B persistência | P1 | ADR e documentos 4A/4B podem representar transição. | Criar linha do tempo canônica. |
| Fase 20D canônica vs contratos 4A/4B/5/7 | P0/P1 | Documentos de contrato podem sobrepor regras. | Consolidar contrato mestre de fluxo financeiro. |
| `migration` documental vs Supabase real | P0 | Arquivo de migration shadow e status migration. | Verificar migrations aplicadas e schema real. |
| Cliente-safe contrato vs preview/UI | P0 | Documentos 4C e 8E tratam cliente-safe. | Validar allowlist e bloqueio de campos sensíveis. |
| Smoke pós-produção duplicado | P1 | Há múltiplos smokes/execuções por fase. | Vincular cada smoke a ambiente, data e commit. |
| Admin read-only vs DML zero | P0/P1 | Fase 5D inclui leitura admin e zero DML rígido. | Validar function bodies e logs. |
| Front/BFF vs chamadas diretas Supabase no frontend | P0/P1 | Fase 8A cita API/hook/service e regra de não chamar direto do componente. | Verificar código AS-IS. |
| Tabela importada como fonte soberana vs tabela oficial de disponibilidade | P0/P1 | Fase 20D.4 e tabela oficial podem ser interpretadas como fontes de verdade distintas. | Definir fonte soberana por contexto: importação, estoque, disponibilidade e proposta. |
| Tabela importada como fonte soberana vs payload adaptado piloto | P0/P1 | Fases 20C/20D sugerem evolução de origem do fluxo. | Validar parser/importação/agenda real. |
| Integração visual do painel vs seleção segura de simulação | P0/P1 | Fases 8E e 8F se complementam, mas não provam fluxo real completo. | Validar sequência 18A/18B/18C/18D e origem de `simulacaoId`. |
| Fixes RPC 8G/8H/8I vs Supabase real | P0/P1 | Contratos de fix RPC/enum/audit não provam função aplicada. | Reconciliar com migrations, function body, grants e testes negativos. |
| Payload completo 8J/8K vs motor financeiro/parser | P0/P1 | Payload completo pode afetar fluxo, proposta e cliente-safe. | Validar contra parser, motor financeiro, Supabase e UI real. |
| PRE-20C reconciliação vs auditorias posteriores | P1 | PRE-20C pode conter evidências úteis, mas pode estar defasado. | Revalidar com queries read-only e PRs atuais. |

---

## 9. Dependências críticas com Supabase, RPC, RLS, banco, parser, motor financeiro e frontend

### 9.1 Supabase real

Verificar read-only antes de qualquer implementação:

```text
- Lista real de schemas/tabelas/colunas.
- RLS ativo/inativo por tabela.
- Policies reais.
- Grants reais para anon/authenticated/service_role.
- Functions/RPCs reais, assinaturas, owner, volatility, security definer/invoker.
- Constraints de status financeiro.
- Índices e FKs.
- Triggers.
- Tabelas de auditoria/log.
```

### 9.2 Tabelas MesaCliente a reconciliar

A partir de docs de banco carregados:

```text
mesa_simulacoes
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_fluxo_operacoes
mesa_cliente_politicas_financeiras
mesa_cliente_politica_premio_faixas
audit_logs / event_logs / message_logs, se existirem
```

Status:

```text
PENDENTE_SUPABASE_REAL
```

### 9.3 RPCs e functions a reconciliar

A partir dos docs auditados e do preflight 8A:

```text
criar_mesa_simulacao
RPCs de histórico/2ª via
gerar_agenda_financeira, se este for o nome real
persistir_agenda_financeira, se este for o nome real
reabrir_fluxo_historico, se este for o nome real
mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)
mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)
mesa_cliente_aplicar_operacao_financeira_admin(uuid, jsonb)
```

Status:

```text
Nomes extraídos de documentação.
Não confirmados no Supabase real.
```

### 9.4 Frontend/código a reconciliar

Arquivos citados documentalmente que exigem AS-IS real:

```text
src/features/mesaCliente/api/mesaClienteApi.js
src/components/MesaCliente/hooks/useMesaData.js
src/components/MesaCliente/FluxoBuilder.jsx
src/components/MesaCliente/TabHistorico.jsx
src/components/MesaCliente/OperacoesFinanceirasPanel.jsx, se existir
src/services/mesaClienteOperacoesFinanceirasService.js, se existir
src/lib/supabaseClient.js
src/App.jsx
src/main.jsx
```

Critérios mínimos:

```text
- Nenhuma operação financeira crítica deve depender de empresa_id/tenant_id/perfil vindos do frontend.
- Componentes React não devem chamar RPC financeira sensível diretamente se houver service/BFF definido.
- Payload cliente-safe deve ser allowlist, não denylist.
- Hooks/services devem sanitizar payload antes da RPC.
- Supabase/RPC deve ser autoridade final.
```

### 9.5 Parser e importação

Verificar:

```text
- Origem dos dados importados de tabela.
- Campos obrigatórios de unidade/preço/estoque/fluxo.
- Tratamento PDF/CSV/XLSX/OCR.
- Normalização de chaves, complemento, entrada, mensais e intermediárias.
- Fonte soberana da tabela importada.
- Histórico da importação Chateau Jardin.
- Relação entre tabela oficial de disponibilidade, importação e Supabase real.
```

### 9.6 Motor financeiro

Verificar:

```text
- Fórmulas de fluxo, VPL, desconto, acréscimo, prêmio, comissão e economia.
- Idempotência.
- Cancelamento.
- Confirmação.
- Aplicação.
- Zero mutação quando contrato declarar read-only.
- Bloqueio de alteração indevida de parcelas/agenda.
- Regressão de proposta gerada.
```

---

## 10. Evidências que ainda precisam ser verificadas no código

Checklist code AS-IS:

```text
- Buscar "MesaCliente", "mesa_cliente", "agenda_financeira", "operacao_financeira".
- Buscar supabase.from(...).insert/update/delete/select em fluxos MesaCliente.
- Buscar supabase.rpc(...) em MesaCliente.
- Verificar se há chamada direta a tabelas financeiras no frontend.
- Verificar se empresa_id, tenant_id, perfil ou permissão são aceitos do frontend.
- Verificar src/lib/supabaseClient.js para hardcoded anon key, service_role e variáveis.
- Verificar App.jsx, main.jsx, services, hooks e clients.
- Verificar se existe service de operações financeiras.
- Verificar se cliente-safe renderiza allowlist.
- Verificar FluxoBuilder, TabHistorico e eventuais painéis financeiros.
```

Resultado atual:

```text
Não é possível afirmar ainda.
Status: PENDENTE_RECONCILIACAO / DRIFT_A_VALIDAR.
```

---

## 11. Evidências que ainda precisam ser verificadas no Supabase real

Checklist Supabase read-only:

```sql
-- functions
select n.nspname as schema,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args,
       pg_get_function_result(p.oid) as result,
       p.prosecdef as security_definer,
       p.provolatile as volatility
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and (p.proname ilike '%mesa%' or p.proname ilike '%agenda%' or p.proname ilike '%operacao%');

-- grants
select routine_schema, routine_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_name ilike '%mesa%'
   or routine_name ilike '%agenda%'
   or routine_name ilike '%operacao%';

-- tables / RLS
select schemaname, tablename, rowsecurity
from pg_tables
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%';

-- policies
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%';
```

Também verificar:

```text
- migrations aplicadas.
- constraints de status.
- FKs e índices.
- triggers/auditoria.
- permissões anon/authenticated.
- ausência de service_role fora de backend seguro.
- testes negativos de anon, sem auth, sem permissão e cross-tenant.
```

Resultado atual:

```text
Não é possível afirmar ainda.
Status: PENDENTE_SUPABASE_REAL.
```

---

## 12. PRs e branches que precisam ser rastreadas depois

| Item | Status nesta auditoria | Próxima verificação |
|---|---|---|
| PR #51 — `docs(audit): add complete documentation tree inventory` | Verificada como merge documental. | Usar como antecedente da PR #52. |
| PR #52 — `docs(audit): add MesaCliente documentation inventory v1` | Planejada. | Abrir documentação-only com este arquivo. |
| `docs/documentation-tree-inventory-v1-20260603` | Branch de PR #51. | Histórico documental. |
| `docs/mesacliente-docs-inventory-v1-20260603` | Branch sugerida para PR #52. | Usar para documentação-only. |
| `feature/mesa-cliente-fase-8-front-operacoes-financeiras` | Citada no preflight 8A. | Rastrear PRs/commits relacionados. |
| Branches/PRs das fases 4A, 4B, 4C, 5A, 5B, 5C, 5D, 6, 7, 8, 20A, 20C, 20D | Não rastreadas nesta auditoria. | Mapear por git log, PRs fechadas e commits. |
| `main` após merge PR #51 | Base documental declarada. | Executar `git ls-tree` e comparar. |
| Vercel previews de PRs MesaCliente | Não verificados. | Usar apenas como evidência complementar. |

---

## 13. Critérios para afirmar qual é a documentação oficial vigente do MesaCliente

Um documento só pode ser marcado como `OFICIAL_VIGENTE` se cumprir todos os critérios aplicáveis:

```text
1. Existe na árvore Git atual da branch correta.
2. Tem status explícito ou decisão do Wagner que confirme vigência.
3. Não foi substituído por versão posterior.
4. Foi comparado com documentos similares/duplicados.
5. Foi reconciliado com código real.
6. Foi reconciliado com Supabase real quando envolve banco/RPC/RLS/migration/grants.
7. Tem PR/commit rastreável.
8. Não contradiz documentação transversal vigente.
9. Define escopo, fora de escopo, rollback e critérios de bloqueio.
10. Quando envolve financeiro/proposta/cliente-safe, possui testes positivos, negativos, regressão e cross-tenant.
```

Critérios adicionais para canônico MesaCliente:

```text
- Deve separar admin vs cliente-safe.
- Deve definir fonte soberana dos dados importados.
- Deve definir autoridade de cálculo e validação no banco/RPC.
- Deve bloquear soberania do frontend sobre tenant/empresa/perfil/regra financeira.
- Deve possuir matriz docs x código x Supabase.
```

---

## 14. Critérios de bloqueio para qualquer implementação futura

Bloqueios P0/P1:

```text
- Não existir documento canônico aprovado para o fluxo afetado.
- Não haver AS-IS de código para o fluxo afetado.
- Não haver AS-IS Supabase real para tabelas/RPCs/policies/grants afetados.
- Haver conflito não resolvido entre protocolo v1.1 e v1.2.
- Haver conflito não resolvido entre docs/protocolo e docs/protocolos.
- Haver dúvida sobre cliente-safe e campos internos.
- Haver dúvida sobre RLS, cross-tenant, auth.uid(), grants ou anon.
- Haver operação financeira direta no frontend sem validação segura no banco/RPC.
- Haver service_role exposta ou indício de segredo em frontend.
- Haver migration documentada mas não comprovada como aplicada.
- Haver smoke/preflight sem data, commit, ambiente e resultado.
- Haver parser/fonte de tabela importada não reconciliado.
- Haver dúvida sobre tabela oficial de disponibilidade, estoque ou fonte soberana.
```

Regra operacional:

```text
Qualquer implementação futura deve parar se a auditoria documental indicar CONFLITANTE,
PENDENTE_RECONCILIACAO ou DRIFT_A_VALIDAR em item P0/P1.
```

---

## 15. Próximos passos sem implementação

1. Gerar árvore completa e validar caminhos antes do commit da PR #52:

```bash
git ls-tree -r --name-only main docs/ > docs-audit-tree-main-2026-06-03.txt
grep -Fx "docs/audits/documentation/2026-06-03-mesacliente-docs-inventory-v1.md" docs-audit-tree-main-2026-06-03.txt || true
grep -Fx "docs/mesa-cliente/fase-20d4-fonte-soberana-tabela-importada.md" docs-audit-tree-main-2026-06-03.txt
grep -Fx "docs/mesa-cliente/tabela-oficial-disponibilidade-v1.md" docs-audit-tree-main-2026-06-03.txt
grep -Fx "docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md" docs-audit-tree-main-2026-06-03.txt
```

Observação: o primeiro `grep` deve retornar vazio antes do commit, porque o arquivo da PR #52 ainda não existe em `main`; depois do commit na branch, o caminho deve aparecer no `git status`/diff da PR.

2. Reconciliar a lista acima contra:

```text
docs/mesa-cliente/
docs/checkpoints/
docs/protocolo/
docs/protocolos/
docs/04-banco-de-dados/
docs/02-arquitetura-tecnica/
docs/06-seguranca-compliance/
docs/product/
docs/roadmap/
docs/skills/
```

3. Criar matriz:

```text
Documento → fase → contrato/evidência/proposta → PR → commit → código → Supabase → status final
```

4. Fazer leitura integral dos candidatos canônicos:

```text
protocolo-mestre-fechai-mesacliente-v1.2.md
fase-20d4-contrato-canonico-fluxo-financeiro.md
fase-20d-contrato-adaptador-historico-agenda-canonica.md
fase-4c-agenda-financeira-cliente-safe-contrato.md
fase-7-contrato-aplicacao-operacao-financeira.md
fase-8-contrato-integracao-front-bff-operacoes-financeiras.md
engenharia-financeira-arquitetura.md
espelho-vendas-engine-v1.md
tabela-oficial-disponibilidade-v1.md
pre-20c-reconciliacao-github-supabase.md
```

5. Abrir auditorias posteriores, sem implementação:

```text
- docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md
- docs/audits/supabase/2026-06-03-mesacliente-supabase-as-is-v1.md
- docs/audits/documentation/2026-06-03-mesacliente-canonical-decision-v1.md
```

---

## 16. O que não deve ser implementado ainda

Não implementar:

```text
- novo parser;
- motor financeiro;
- alteração de proposta;
- alteração de fluxo de pagamento;
- nova RPC;
- alteração de RPC existente;
- migration;
- policy/RLS/grant;
- cliente-safe preview;
- painel financeiro;
- alteração de App.jsx;
- alteração de hooks/services;
- alteração de Supabase client;
- mudança de produção/Vercel/GitHub Actions;
- automação Make/n8n/Worker;
- qualquer correção baseada apenas em nome de documento.
```

---

## 17. Parecer final do GPT 0

O conjunto documental MesaCliente é grande, sensível e parcialmente sobreposto por fases, contratos, evidências, smokes, checkpoints, protocolos e rascunhos.

Nenhum documento deve ser tratado como `OFICIAL_VIGENTE` nesta etapa.

Classificação geral:

```text
Status global MesaCliente docs: OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO
Risco global: P0/P1
Motivo: parser, motor financeiro, proposta, histórico, cliente-safe, multi-tenant, Supabase, RPC, RLS e segurança.
Autorização: documentação-only.
Próximo passo: PR #52 documental com este inventário, sem implementação.
```
