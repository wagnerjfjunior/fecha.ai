# FECH.AI — Bootstrap Index

**Status:** `BOOTSTRAP_INDEX_V4 / SES_SPECIALIST_ROUTING / CANONICAL_SKILL_RESOLUTION`  
**Atualizado em:** `2026-08-20`  
**Repositório:** `wagnerjfjunior/fecha.ai`

Este índice define a ordem mínima de reconstrução de contexto antes de conversas sensíveis, validações de PR, arquitetura, segurança, deploy, Supabase, produto, handoffs ou trabalho dos especialistas.

## 1. Resolução obrigatória da main

Antes de ler documentação operacional:

1. resolver o SHA live da branch `main` no GitHub;
2. informar o repositório, a branch e o SHA resolvido;
3. ler os arquivos canônicos no ref exato;
4. não substituir falha de acesso por memória, print ou conversa;
5. quando a demanda envolver PR, manter `main`, base, branch e head separados.

Se a main não puder ser resolvida, declarar `GITHUB_BOOTSTRAP_UNAVAILABLE` e operar fail-closed.

## 2. Resolução do especialista

Primeiro ler:

```text
docs/skills/SES_SPECIALIST_ROUTING.md
```

Se a tarefa corresponder a um `ROLE` explicitamente adotado nesse documento:

1. resolver `wagnerjfjunior/Specialist-Engineering-System` / `main` live;
2. resolver o projeto `fechai` pelo SES Project Registry e Project Adapter;
3. resolver o `ROLE -> ARCHETYPE_ID` exato;
4. confirmar o arquétipo `ACTIVE` no SES Archetype Registry;
5. confirmar a elegibilidade atual no ledger de certificação SES;
6. carregar o contrato do arquétipo SES;
7. carregar a skill/regra local FECH.AI apontada para o role, quando aplicável;
8. continuar o bootstrap FECH.AI e emitir Context Readiness antes de trabalho substantivo quando exigido.

Para qualquer role SES adotado, a identidade operacional do especialista deve ser resolvida pelo `ARCHETYPE_ID` no SES `archetypes/REGISTRY.md`. O destino humano de handoff manual deve usar o `CANONICAL_NAME` do arquétipo, conforme `core/protocols/MANUAL_SPECIALIST_HANDOFF_CONTRACT.md`.

Nomes históricos/legacy (incluindo labels `GPT<number>`, títulos antigos de Builder ou títulos de skills project-local) permanecem apenas como continuidade/project-local rules e não podem substituir o destino SES canônico.

```text
SPECIALIST_TARGET_NAME = ARCHETYPE_REGISTRY.CANONICAL_NAME
LEGACY_ALIAS != SPECIALIST_TARGET_NAME
PROJECT_LOCAL_SKILL_TITLE != SPECIALIST_TARGET_NAME
```

Se o domínio **não** possuir role SES adotado, usar o routing project-local existente:

1. ler `docs/skills/fechai-gpt-registry.md`;
2. localizar o caminho exato do especialista local;
3. confirmar que o caminho está em `docs/skills/`;
4. ler a skill canônica no SHA live de `main`;
5. somente depois complementar o bootstrap com documentos do domínio e evidências do caso.

Não inferir nem auto-adotar um arquétipo SES ausente do role map.

Canonicidade de skill project-local exige simultaneamente:

```text
arquivo dentro de docs/skills/
+
entrada correspondente no registry ou referência explícita no SES specialist routing
```

Regras:

- `docs/skills/` é o único diretório normativo de skills FECH.AI;
- arquétipos SES são resolvidos no repositório SES, não copiados para FECH.AI;
- o limite de 8.000 caracteres aplica-se apenas às Instructions do GPT Builder;
- a skill GitHub não possui esse limite artificial;
- Instructions do Builder são um núcleo operacional derivado, não a fonte normativa completa;
- `Knowledge` do Builder não é fonte canônica e deve permanecer vazio quando o especialista usa bootstrap GitHub live;
- backup de Instructions é somente recuperação, não skill e não contexto operacional;
- não buscar nem ler backups durante o bootstrap normal;
- entrada apontando para caminho inexistente é `BLOCKING`;
- `SPECIALIST_AVAILABLE != EXECUTED`, `ADOPTED != EXECUTED` e `PROJECT_CONTEXT_READY != AUTHORIZED_TO_MUTATE`.

Quando SES routing, Builder, skill, registry ou handoff divergirem:

```text
declarar SPECIALIST_ROUTING_DRIFT, SKILL_DRIFT ou STALE_CONTINUITY
preservar temporariamente a regra mais restritiva
não reduzir salvaguarda já aplicada
bloquear encerramento oficial afetado
propor reconciliação documental
```

Conteúdo presente somente em PR head é `PR_HEAD_ONLY`; não substitui `main` enquanto não for mergeado.

## 3. Documentos obrigatórios de bootstrap

### 3.1 SaaS current state index

```text
docs/bootstrap/2026-06-10-fechai-saas-current-state-index.md
```

Usar para:

- identidade do produto;
- contexto SaaS multi-tenant;
- histórico de PRs;
- trilhas atuais de arquitetura e segurança;
- hierarquia de verdade;
- mapa de módulos e domínios.

### 3.2 GPT specialists private index

```text
docs/bootstrap/2026-06-10-fechai-gpt-specialists-private-index.md
```

Usar como continuidade histórica/project-local para:

- responsabilidades locais ainda não migradas para roles SES;
- handoff entre especialistas;
- separação de papéis e gates.

Para roles explicitamente adotados em `docs/skills/SES_SPECIALIST_ROUTING.md`, o routing SES atual prevalece sobre identidade GPT legada. O índice privado não pode substituir o `ROLE -> ARCHETYPE_ID` vigente.

### 3.3 Specialist modus operandi

```text
docs/bootstrap/2026-06-11-fechai-specialists-modus-operandi.md
```

Usar para:

- bootstrap obrigatório;
- postura de revisão sênior;
- evidência, inferência e evidência ausente;
- cobertura de leitura `NOT_READ`, `PARTIAL_READ` e `INTEGRAL_READ`;
- tratamento de truncamento e comprovação de EOF;
- matriz de cobertura em auditorias multiarquivo;
- gate anti-overclaim antes de PASS;
- classificação de achados;
- fail-closed;
- escopo e rollback;
- documentação, índice e handoff.

A leitura desse documento é obrigatória para todos os especialistas. As salvaguardas transversais não devem ser duplicadas nem enfraquecidas em skills individuais.

### 3.4 Codex efficiency and GreenOps workflow

```text
docs/bootstrap/2026-06-12-fechai-codex-efficiency-greenops.md
```

Usar para:

- eficiência de tokens e créditos;
- envelope de tarefa Codex;
- separação ChatGPT/GitHub/Codex;
- disciplina de tamanho de PR;
- redução de retrabalho;
- evitar varredura ampla quando índice, diff ou metadata bastarem.

### 3.5 Bootstrap governance cycle handoff

```text
docs/bootstrap/2026-06-12-fechai-bootstrap-governance-cycle-handoff.md
```

Usar para:

- handoff posterior às PRs #85–#90;
- cadeia de arquitetura, bootstrap, GreenOps e alinhamento de skills;
- estado consolidado GPT0–GPT10 naquele ciclo;
- contexto inicial de nova conversa;
- ordem de rollback documental.

Esse handoff é histórico/continuity e não substitui o SES specialist routing atual para roles adotados.

## 4. Baseline ativo de governança de entrega

```text
docs/governance/INDEX.md
```

Ler quando a demanda envolver entrega, baseline, aceite, WDP, capacidade, forecast, dependência, Health Score, riscos ou mudança de plano.

A governança de entrega não substitui o bootstrap nem prova implementação.

## 5. Continuidade operacional SFJM

```text
docs/sfjm/INDEX.md
```

Ler após o bootstrap e a governança aplicável para determinar:

- estado operacional verificado;
- PR/head ativos e frescor da evidência;
- próxima ação segura única;
- ações bloqueadas;
- limites de autorização;
- handoff corrente;
- o que não alterar ou inferir.

SFJM não substitui bootstrap, routing SES, registry ou evidência live.

## 6. Ordem mínima de execução

```text
1. Resolver FECH.AI main live.
2. Ler este INDEX.
3. Ler SES_SPECIALIST_ROUTING.md.
4. Para role SES adotado: resolver SES main + current adoption pointer quando material + Project Adapter + archetype + certificação + `core/protocols/MANUAL_SPECIALIST_HANDOFF_CONTRACT.md` + regra local aplicável; renderizar o destino manual usando o `CANONICAL_NAME` do arquétipo.
5. Para domínio não adotado: resolver a skill project-local pelo registry FECH.AI.
6. Ler os documentos comuns de bootstrap, incluindo o Modus Operandi.
7. Ler governança quando entrega/aceite estiverem envolvidos.
8. Ler SFJM quando houver continuidade operacional.
9. Localizar somente os documentos e arquivos necessários ao módulo/risco.
10. Classificar a cobertura de cada fonte material.
11. Reconstruir contexto, evidências, lacunas e conflitos.
12. Validar GitHub live e ambiente necessário.
13. Classificar riscos.
14. Definir a próxima ação segura.
15. Registrar handoff/index quando necessário.
```

## 7. Contrato de cobertura comum

O contrato completo de cobertura e integridade de leitura fica exclusivamente no Modus Operandi comum.

Todos os especialistas devem:

- distinguir existência/localização de conteúdo efetivamente lido;
- detectar resposta truncada;
- não declarar `INTEGRAL_READ` sem cobertura até EOF;
- limitar conclusões de `PARTIAL_READ` às partes efetivamente consultadas;
- usar matriz de cobertura quando a conclusão envolver vários arquivos;
- não emitir PASS amplo com fonte material parcial ou não classificada.

O INDEX somente aponta e obriga essa leitura. O contrato detalhado não deve ser copiado para cada skill.

## 8. GreenOps

Antes de trabalho caro ou Codex:

- README/índice/bootstrap respondem primeiro?
- SFJM identifica estado e próxima ação?
- GitHub connector valida sem Codex?
- diff/metadata/arquivo específico bastam?
- a PR pode ser menor?
- o rollback pode ser um revert?

Eficiência nunca autoriza leitura insuficiente ou overclaim. A economia correta reduz busca irrelevante, não a cobertura material exigida pela conclusão.

## 9. Mutação e autoridade

Capacidade técnica da ferramenta não é autoridade operacional.

Nenhuma mutação em GitHub, Supabase, Vercel, produção, Builders ou dados pode ocorrer sem autorização explícita e delimitada da Product Authority para a ação exata.
