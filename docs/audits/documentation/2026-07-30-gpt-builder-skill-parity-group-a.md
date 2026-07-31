# FECH.AI — Auditoria de Paridade Builder × Skill — Grupo A

**Data:** 2026-07-30  
**Atualizado:** 2026-07-31  
**Status:** `DOCUMENTATION_ONLY / PARITY_AUDIT / GROUP_A / COVERAGE_MATRIX / READY_REVIEW_CORRECTION / NO_RUNTIME_CHANGE`  
**Repositório:** `wagnerjfjunior/fecha.ai`  
**Base auditada:** `main@cec1b22430adf1a002b172992cf6c5ea5bb427de`  
**Head inicial da reconciliação:** `e5457d013688399a6160bb929a993dd138ec15ed`  
**Head anterior ao review Ready:** `915c3d175826c0e81cd52b30b377b71bec934eca`  
**Escopo:** GPT0, GPT1, GPT2, GPT3, GPT4, GPT7 e GPT8.

## 1. Risco principal

```text
Builders configurados operarem contra skills canônicos superficiais,
desatualizados, conflitantes ou sem evidência reproduzível de paridade.
```

## 2. Evidências e limites

Fontes materiais da comparação:

- snapshot de configuração dos Builders fornecido pela Product Authority em `Mapeamento GPT’s.md`;
- sete skills v1.1 na base exata;
- sete skills v2.0 no head inicial da reconciliação;
- `docs/bootstrap/INDEX.md` e `docs/skills/fechai-gpt-registry.md` nos refs auditados;
- metadata, commits, patches, árvores e blobs da PR #111;
- PR #110 somente como objeto separado de continuidade de Builders.

O snapshot de Builder é `INFORMATION_SUPPLIED`, não fonte GitHub canônica e não prova o estado live atual da interface do Builder. A paridade desta auditoria é documental contra o snapshot fornecido.

Evidências ausentes:

- leitura direta da interface live dos Builders;
- verificação independente do campo Knowledge aplicado;
- teste comportamental live de todos os especialistas após a mudança;
- check automatizado dedicado a Markdown, links ou consistência documental.

Essas ausências limitam o resultado. Elas não devem ser ocultadas nem convertidas em Builder PASS, Product PASS, Runtime PASS ou Security Go.

## 3. Matriz de cobertura da comparação

### 3.1 Método

A auditoria independente do head inicial recuperou cada arquivo GitHub pelo commit exato, com conteúdo completo em Base64, e cruzou:

- path;
- blob SHA;
- tamanho;
- quantidade de linhas;
- primeira e última linha;
- árvore do commit;
- patch final.

A classificação `INTEGRAL_READ` foi usada somente quando o corpo chegou ao EOF sem truncamento, paginação interna, omissão ou erro de blob individual.

O anexo `Mapeamento GPT’s.md` foi recuperado integralmente como artefato fornecido na conversa, com 60.188 bytes e 1.093 linhas. Por não pertencer ao Git, não possui blob SHA; essa limitação é registrada explicitamente.

### 3.2 Fontes materiais Builder × skill

| Fonte | Ref/objeto exato | Método | Bytes | Linhas | Cobertura | Evidência de EOF / limitação |
|---|---|---|---:|---:|---|---|
| Builder snapshot GPT0–GPT8 | `Mapeamento GPT’s.md`, anexo fornecido em 2026-07-30; sem Git blob | recuperação integral do anexo da conversa | 60.188 | 1.093 | `INTEGRAL_READ / INFORMATION_SUPPLIED` | primeira linha `# Mapeamento GPT’s`; término observado no fim do arquivo; não prova Builder live |
| GPT0 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `282182a54b88f2344ea56ef8225e2519a96493e2` | GitHub Contents API Base64 + tree/blob + patch | 14.684 | 370 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |
| GPT1 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `da9924cd3ed696fb88677ac831a1cb48b0dc741a` | GitHub Contents API Base64 + tree/blob + patch | 18.882 | 392 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |
| GPT2 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `60858240a2252df5d5292f26210654c0660295d7` | GitHub Contents API Base64 + tree/blob + patch | 19.036 | 417 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |
| GPT3 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `7c6be701cea7c38d8e62202dddce23cc2d436989` | GitHub Contents API Base64 + tree/blob + patch | 18.944 | 381 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |
| GPT4 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `daccf2293b1a73e4cbbda22185d29ae36dd4d477` | GitHub Contents API Base64 + tree/blob + patch | 18.855 | 388 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |
| GPT7 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `5312f61504834627f850182a4b22561b0e29c67f` | GitHub Contents API Base64 + tree/blob + patch | 19.162 | 410 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |
| GPT8 skill final | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `94df8d1aea1c90260868cd0ed625692c14a5f301` | GitHub Contents API Base64 + tree/blob + patch | 19.219 | 403 | `INTEGRAL_READ` | primeira linha e última linha conferidas; sem truncamento |

Os sete blobs de skill permaneceram inalterados nos quatro commits corretivos que levaram ao head `915c3d175826c0e81cd52b30b377b71bec934eca`. Logo, a matriz acima continua identificando os objetos materiais usados na paridade dos sete especialistas.

### 3.3 Fontes de governança utilizadas no head inicial

| Fonte | Ref/objeto exato | Método | Bytes | Linhas | Cobertura | Evidência de EOF |
|---|---|---|---:|---:|---|---|
| Bootstrap INDEX | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `9fc5cfe2d7766203dd5a2d3fe670a1f80e64bea0` | Contents API Base64 + tree/blob + patch | 7.065 | 214 | `INTEGRAL_READ` | primeira e última linha conferidas |
| Registry inicial v3.0 | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `0def1a5584038ebed1d6be74f2e65a0a4fc06d36` | Contents API Base64 + tree/blob + patch | 10.173 | 213 | `INTEGRAL_READ` | primeira e última linha conferidas |
| Relatório inicial desta auditoria | `e5457d013688399a6160bb929a993dd138ec15ed` / blob `9b39406ee8e833ac02a23388d929826dc21ffb75` | Contents API Base64 + tree/blob + patch | 5.006 | 78 | `INTEGRAL_READ` | primeira e última linha conferidas |

A existência dos objetos não foi usada isoladamente. A matriz registra o método, os identificadores e as limitações para permitir revalidação futura.

## 4. Matriz de paridade

| GPT | Skill canônico | Skill da base | Builder mapeado | Veredito anterior | Correção aplicada |
|---|---|---:|---|---|---|
| GPT0 | `docs/skills/fechai-gpt0-documentation-auditor.md` | v1.1 | configuração mapeada em 2026-07-30 | `BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |
| GPT1 | `docs/skills/fechai-gpt1-architect-saas.md` | v1.1 | v1.5 mapeado em 2026-07-30 | `BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |
| GPT2 | `docs/skills/fechai-gpt2-ux-ui-app-specialist.md` | v1.1 | v1.6 mapeado em 2026-07-30 | `BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |
| GPT3 | `docs/skills/fechai-gpt3-supabase-security-specialist.md` | v1.1 | v1.5 mapeado em 2026-07-30 | `BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |
| GPT4 | `docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md` | v1.1 | v1.5 mapeado em 2026-07-30 | `CONFLICTING / BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |
| GPT7 | `docs/skills/fechai-gpt7-leadops-crm-discador.md` | v1.1 | v1.6 mapeado em 2026-07-30 | `BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |
| GPT8 | `docs/skills/fechai-gpt8-mesacliente-tabelas-propostas.md` | v1.1 | configuração corrigida e retestada em 2026-07-30 | `BUILDER_AHEAD_OF_SKILL` | skill v2.0 integral |

A auditoria independente concluiu paridade documental contra o snapshot fornecido, com riscos residuais de ordem textual no bootstrap de GPT0/GPT8. Não houve inspeção live dos Builders.

## 5. Achados comuns da reconciliação inicial

### BLOCKING — resolvidos documentalmente no Grupo A

- regras relevantes existiam somente no Builder;
- os skills v1.1 eram materialmente menos completos que os Builders mapeados;
- seções de Knowledge estático conflitavam com bootstrap GitHub live;
- não havia regra inequívoca de canonicidade por `docs/skills/` + registry;
- GPT4 possuía linguagem incompatível com autorização explícita de escrita.

### REQUIRED IN THIS PR — executados

- substituir as sete skills por versões integrais v2.0;
- declarar relação skill completa → Instructions compactas;
- adicionar política de `SKILL_DRIFT`;
- padronizar evidência, AS-IS, read-only, escrita, ferramentas, validação e handoff;
- atualizar registry e bootstrap;
- centralizar salvaguardas transversais no Modus Operandi.

### ACCEPTABLE WITH RESIDUAL RISK

- o snapshot fornecido não prova a configuração live atual dos Builders;
- Knowledge vazio é regra normativa, mas não foi observado na interface;
- ausência de check documental automatizado;
- duplicação deliberada do contrato operacional do Builder dentro da skill exige reconciliação futura quando o Builder mudar.

## 6. Diferenças materiais por especialista

- **GPT0:** Builder continha bootstrap dinâmico, hierarquia, segurança de conteúdo e indisponibilidade; skill v1.1 não possuía paridade.
- **GPT1:** Builder v1.5 continha fail-closed, separação de autoridade, AS-IS, conflitos e handoff mais fortes; skill v1.1 recomendava Knowledge estático.
- **GPT2:** Builder v1.6 continha AS-IS FIRST, modos e contrato de evidência do APP; skill v1.1 não era equivalente.
- **GPT3:** Builder v1.5 continha distinção mergeado/aplicado/catálogo/testado, READ_ONLY e contrato de RPC/grants; skill v1.1 era insuficiente.
- **GPT4:** skill v1.1 autorizava linguagem de mutação sem exigir autorização exata.
- **GPT7:** skill v1.1 era superficial frente a lead, eventos, follow-up, deduplicação e métricas.
- **GPT8:** skill v1.1 era superficial frente a Native First, regras financeiras, proposta/histórico e cross-tenant.

## 7. Aprendizado transversal de integridade de leitura

Durante a auditoria independente no head inicial, a primeira resposta do GPT0 apresentou overclaim de cobertura e precisou de intervenção da Product Authority para exigir recuperação completa e prova de EOF.

Classificação:

```text
USER_CORRECTED
INITIAL_OVERCLAIM
NO_AUTONOMOUS_BEHAVIORAL_PASS
```

O parecer final corrigido foi documentalmente aceitável. O comportamento inicial não foi convertido em Builder PASS.

A correção foi centralizada em:

```text
docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md
```

Esse contrato comum exige:

- `NOT_READ`, `PARTIAL_READ` ou `INTEGRAL_READ`;
- detecção de truncamento;
- limite das conclusões à cobertura real;
- matriz de cobertura multiarquivo;
- distinção entre patch e arquivo final;
- bloqueio de PASS amplo com fonte material parcial;
- registro de `USER_CORRECTED / INITIAL_OVERCLAIM`.

## 8. Achados surgidos após Ready e resolução

Um review automatizado foi submetido no head `915c3d175826c0e81cd52b30b377b71bec934eca` depois da transição para Ready. O merge foi interrompido e a PR retornou a Draft.

### 8.1 Estado transitório no registry

**Achado:** os sete registros armazenavam `PR_HEAD_ONLY até merge`, o que se tornaria falso ao publicar o próprio registry na `main`.

**Resolução:** o registry passou a armazenar somente estado durável:

```text
v2.0 / GROUP_A_RECONCILED
```

A localização live da versão continua sendo resolvida no GitHub, sem gravar lifecycle transitório como estado permanente.

### 8.2 Matriz de cobertura ausente

**Achado:** o relatório não permitia reproduzir a cobertura material da comparação.

**Resolução:** as seções 3.1–3.3 registram ref, blob/objeto, método, bytes, linhas, cobertura, EOF e limitações.

### 8.3 Actions do GPT8 divergentes

**Achado:** o registry declarava somente GitHub, enquanto a skill habilitava Mermaid condicional após AS-IS.

**Resolução:** o registry passou a declarar:

```text
GitHub obrigatório; Mermaid somente após AS-IS confirmado
```

A mudança não habilita Supabase nem autoriza qualquer mutação.

### 8.4 Handoff do GPT8 não descobrível

**Achado:** `BUILDERS_CURRENT.md` era obrigatório, mas ainda não estava na `main` e a skill instruía uma busca não ancorada.

**Resolução:** o registry canônico passou a definir uma resolução explícita:

- caminho durável esperado: `docs/sfjm/handoffs/BUILDERS_CURRENT.md`, via `docs/sfjm/INDEX.md`;
- ponte transitória somente leitura: PR #110, head a revalidar `6a79b5ab597c7facc7b0d6eafdda36289b21c287`, mesmo caminho;
- classificação obrigatória: `PR_HEAD_ONLY / INFORMATION_SUPPLIED`;
- proibição de alterar ou operar a PR #110 para satisfazer o bootstrap;
- `STALE_CONTINUITY` se a âncora mudar sem publicar o arquivo na `main`.

A solução usa o registry como índice canônico e não duplica o contrato nos sete skills.

## 9. Não escopo

- nenhum runtime, frontend, Supabase, Vercel, GitHub Actions ou Builder foi alterado;
- a PR #110 foi somente lida como evidência e não foi modificada;
- nenhum Security Go, produto PASS, Ready, merge ou deploy é autorizado por este relatório;
- GPT5, GPT6, GPT9 e GPT10 permanecem no Grupo B;
- não foi criado novo diretório de skills;
- não foi duplicado o contrato transversal em cada skill.

## 10. Rollback

Um revert da PR documental restaura os arquivos anteriores. Não há rollback de runtime, dados ou ambiente.
