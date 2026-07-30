# FECH.AI — Auditoria de Paridade Builder × Skill — Grupo A

**Data:** 2026-07-30  
**Status:** `DOCUMENTATION_ONLY / PARITY_AUDIT / GROUP_A / NO_RUNTIME_CHANGE`  
**Repositório:** `wagnerjfjunior/fecha.ai`  
**Base auditada:** `main@cec1b22430adf1a002b172992cf6c5ea5bb427de`  
**Escopo:** GPT0, GPT1, GPT2, GPT3, GPT4, GPT7 e GPT8.

## 1. Risco principal

```text
Builders configurados operarem contra skills canônicos superficiais,
desatualizados ou conflitantes.
```

## 2. Evidências

- snapshot de configuração dos Builders fornecido pela Product Authority em `Mapeamento GPT’s.md`;
- `docs/bootstrap/INDEX.md` na base auditada;
- `docs/skills/fechai-gpt-registry.md` v2.0;
- sete skills v1.1 e seus blobs na base auditada;
- PR #110 Draft como continuidade de Builders, sem alterar as skills.

O arquivo enviado pelo usuário é `INFORMATION_SUPPLIED`, não fonte GitHub canônica. Foi usado para comparar a configuração aplicada dos Builders com os arquivos versionados.

## 3. Matriz

| GPT | Skill canônico | Skill live | Builder mapeado | Veredito | Correção |
|---|---|---:|---|---|---|
| GPT0 | `docs/skills/fechai-gpt0-documentation-auditor.md` | v1.1 | configuração mapeada em 2026-07-30 | BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |
| GPT1 | `docs/skills/fechai-gpt1-architect-saas.md` | v1.1 | v1.5 mapeado em 2026-07-30 | BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |
| GPT2 | `docs/skills/fechai-gpt2-ux-ui-app-specialist.md` | v1.1 | v1.6 mapeado em 2026-07-30 | BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |
| GPT3 | `docs/skills/fechai-gpt3-supabase-security-specialist.md` | v1.1 | v1.5 mapeado em 2026-07-30 | BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |
| GPT4 | `docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md` | v1.1 | v1.5 mapeado em 2026-07-30 | CONFLICTING / BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |
| GPT7 | `docs/skills/fechai-gpt7-leadops-crm-discador.md` | v1.1 | v1.6 mapeado em 2026-07-30 | BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |
| GPT8 | `docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md` | v1.1 | configuração corrigida e retestada em 2026-07-30 | BUILDER_AHEAD_OF_SKILL | atualizar para skill v2.0 integral |

## 4. Achados comuns

### BLOCKING

- skills não podem ser consideradas configuração completa enquanto regras relevantes existirem somente no Builder;
- não há evidência de que o limite de 8.000 caracteres tenha sido deliberadamente aplicado aos arquivos GitHub; porém, os skills atuais são materialmente menos completos que os Builders mapeados e a governança não proíbe explicitamente essa compressão indevida;
- seções de “arquivos de conhecimento recomendados” conflitam com a política de Knowledge vazio e bootstrap GitHub live;
- não havia regra inequívoca de que `docs/skills/` + registry define a única fonte normativa.

### REQUIRED IN THIS PR

- substituir as sete skills por versões integrais v2.0;
- declarar relação skill completo → Instructions compactas;
- adicionar política de `SKILL_DRIFT`;
- padronizar evidência, AS-IS, read-only, escrita, ferramentas, validação e handoff;
- atualizar registry e bootstrap para a regra canônica única.

### ACCEPTABLE WITH RESIDUAL RISK

- os Builders permanecem utilizáveis durante a PR porque suas Instructions já possuem salvaguardas mais fortes;
- PR #110 permanece separada e deverá ser reconciliada somente após esta PR fechar.

## 5. Diferenças materiais por especialista

- **GPT0:** Builder contém bootstrap dinâmico, hierarquia, segurança de conteúdo e indisponibilidade; skill v1.1 não possui paridade.
- **GPT1:** Builder v1.5 contém fail-closed, separação de autoridade, AS-IS, conflitos e handoff mais fortes; skill v1.1 ainda recomenda Knowledge estático.
- **GPT2:** Builder v1.6 contém AS-IS FIRST, modos e contrato de evidência do APP; skill v1.1 é ampla, mas não equivalente.
- **GPT3:** Builder v1.5 contém distinção mergeado/aplicado/catálogo/testado, READ_ONLY e contrato detalhado de RPC/grants; skill v1.1 é insuficiente.
- **GPT4:** skill v1.1 autoriza linguagem como criar PR pequena ou fechar PR superseded “quando seguro”, conflitante com a regra atual de autorização explícita.
- **GPT7:** skill v1.1 é superficial frente ao contrato de lead, eventos, follow-up, deduplicação e métricas do Builder v1.6.
- **GPT8:** skill v1.1 é superficial frente ao bloqueio greenfield, Native First, regras financeiras, proposta/histórico e cross-tenant do Builder corrigido.

## 6. Não escopo

- nenhum runtime, frontend, Supabase, Vercel, GitHub Actions ou Builder é alterado;
- nenhum Security Go, produto PASS, Ready, merge ou deploy é autorizado;
- GPT5, GPT6, GPT9 e GPT10 ficam para o Grupo B após fechamento e aprendizado desta PR.

## 7. Rollback

Um revert da PR documental restaura os arquivos anteriores. Não há rollback de runtime, dados ou ambiente.
