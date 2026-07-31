# FECH.AI — Bootstrap Index

**Status:** `BOOTSTRAP_INDEX_V2 / CANONICAL_SKILL_RESOLUTION / DOCUMENTATION_ONLY`  
**Atualizado em:** `2026-07-31`  
**Repositório:** `wagnerjfjunior/fecha.ai`

Este índice define a ordem mínima de reconstrução de contexto antes de conversas sensíveis, validações de PR, arquitetura, segurança, deploy, Supabase, produto, handoffs ou trabalho dos GPTs especialistas.

## 1. Resolução obrigatória da main

Antes de ler documentação operacional:

1. resolver o SHA live da branch `main` no GitHub;
2. informar o repositório, a branch e o SHA resolvido;
3. ler os arquivos canônicos no ref exato;
4. não substituir falha de acesso por memória, print ou conversa;
5. quando a demanda envolver PR, manter `main`, base, branch e head separados.

Se a main não puder ser resolvida, declarar `GITHUB_BOOTSTRAP_UNAVAILABLE` e operar fail-closed.

## 2. Resolução da skill canônica do especialista

Para qualquer GPT especialista:

1. ler `docs/skills/fechai-gpt-registry.md`;
2. localizar o caminho exato do próprio especialista;
3. confirmar que o caminho está em `docs/skills/`;
4. ler a skill canônica no SHA live de `main`;
5. somente depois complementar o bootstrap com documentos do domínio e evidências do caso.

Canonicidade exige simultaneamente:

```text
arquivo dentro de docs/skills/
+
entrada correspondente no registry
```

Regras:

- `docs/skills/` é o único diretório normativo de skills;
- o limite de 8.000 caracteres aplica-se apenas às Instructions do GPT Builder;
- a skill GitHub não possui esse limite artificial;
- Instructions do Builder são um núcleo operacional derivado, não a fonte normativa completa;
- `Knowledge` do Builder não é fonte canônica e deve permanecer vazio quando o GPT usa bootstrap GitHub live;
- backup de Instructions é somente recuperação, não skill e não contexto operacional;
- não buscar nem ler backups durante o bootstrap normal;
- arquivo de skill existente, mas ausente do registry, é `NON_CANONICAL / PENDING_RECONCILIATION`;
- entrada no registry apontando para caminho inexistente é `BLOCKING`.

Quando Builder, skill, registry ou handoff divergirem:

```text
declarar SKILL_DRIFT ou STALE_CONTINUITY
preservar temporariamente a regra mais restritiva
não reduzir salvaguarda já aplicada
bloquear encerramento oficial
propor reconciliação documental
```

Skill presente somente em PR head é `PR_HEAD_ONLY`; não substitui a skill da main enquanto não for mergeada.

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

Usar para:

- roteamento entre especialistas;
- mapa de responsabilidades;
- handoff entre GPTs;
- separação de papéis e gates.

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

SFJM não substitui bootstrap, registry ou evidência live.

## 6. Ordem mínima de execução

```text
1. Resolver main live.
2. Ler este INDEX.
3. Resolver e ler a skill canônica pelo registry.
4. Ler os documentos comuns de bootstrap, incluindo o Modus Operandi.
5. Ler governança quando entrega/aceite estiverem envolvidos.
6. Ler SFJM quando houver continuidade operacional.
7. Localizar somente os documentos e arquivos necessários ao módulo/risco.
8. Classificar a cobertura de cada fonte material.
9. Reconstruir contexto, evidências, lacunas e conflitos.
10. Validar GitHub live e ambiente necessário.
11. Classificar riscos.
12. Definir a próxima ação segura.
13. Registrar handoff/index quando necessário.
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
