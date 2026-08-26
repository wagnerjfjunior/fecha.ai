# FECH.AI — Diagramas de Arquitetura em Transição

**Status:** `DOCUMENTATION_ONLY / INFORMATION_SUPPLIED / TRANSITION_SNAPSHOT / NO_RUNTIME_CHANGE`  
**Data de preservação:** `2026-08-26`  
**Repositório:** `wagnerjfjunior/fecha.ai`  
**Base de criação:** `main@03fe960f4ef5715bbe50b6e3d5ec9c0b10167073`

## 1. Objetivo

Preservar no repositório canônico os diagramas Mermaid usados para explicar a evolução arquitetural do FECH.AI, evitando dependência do Mermaid.ai como única cópia e mantendo uma trilha explícita de:

```text
arquitetura em transição / riscos observados
→ hardening T1/T2 e deslocamento de autoridade para o servidor
→ arquitetura-alvo segmentada com guardrails transversais
```

Este pacote é documentação de continuidade arquitetural. Ele não altera frontend, Supabase, Auth, RLS, policies, grants, RPCs, Edge Functions, Vercel, GitHub Actions, produção ou dados.

## 2. Proveniência da fonte

Fonte fornecida diretamente pela Product Authority em `2026-08-26`:

```text
AGORA T1T2.md
bytes: 8484
SHA-256: a985654a374b9cb61d4eee05ab3aa0f98e78e77d728679ffbec3f74b7bb5be92
coverage: INTEGRAL_READ / EOF_CONFIRMED
```

Normalização aplicada ao versionar os `.mmd`:

- remoção dos fences Markdown ``` usados apenas para apresentação;
- remoção dos títulos externos aos blocos Mermaid;
- preservação da semântica, nós, relações, labels e estilos dos diagramas fornecidos;
- nenhum runtime ou contrato técnico foi alterado pela normalização.

Os links de convite/edit do Mermaid.ai **não são versionados**, pois incorporam tokens de compartilhamento. Para rastreabilidade, apenas os `documentID`s são registrados abaixo.

## 3. Inventário dos diagramas

| Ordem | Arquivo canônico | Mermaid documentID | Classe documental | Interpretação permitida |
|---|---|---|---|---|
| 1 | `2026-08-26-appjsx-arquitetura-em-transicao.mmd` | `8db8f94c-915e-44cd-8e1c-c0ed86e15827` | `AS_IS_TRANSITION_SNAPSHOT / HISTORICAL_EVIDENCE` | Registra a arquitetura e riscos representados no momento em que o diagrama foi produzido. Não prova o estado live atual sozinho. |
| 2 | `2026-08-26-t1-t2-autorizacao-antes-depois.mmd` | `eb1e21df-a635-4f18-a562-f58246106d40` | `SECURITY_EVOLUTION_SNAPSHOT / T1_T2` | Registra a mudança conceitual do PATCH direto para autoridade server-side e os controles T1/T2 representados no diagrama. |
| 3 | `2026-08-26-arquitetura-alvo-guardrails.mmd` | `46a29f74-5191-4732-a94a-fb1cb31abc70` | `TARGET_ARCHITECTURE / CONCEPTUAL` | Define direção arquitetural desejada. Não deve ser interpretado como implementação concluída. |

## 4. Relação entre os três diagramas

### 4.1 Arquitetura em transição

O snapshot de `App.jsx` registra o período em que o frontend ainda concentrava grande parte da orquestração e coexistiam RPCs, Edge Functions e escritas diretas sensíveis.

A presença de um nó, RPC, PATCH ou fluxo nesse desenho significa apenas que o artefato fornecido o representava naquele momento. Para afirmar estado atual, deve-se resolver GitHub/live runtime novamente no ref e ambiente aplicáveis.

### 4.2 T1/T2 — mudança da autoridade

O diagrama T1/T2 registra a direção de hardening:

```text
frontend solicita
→ RPC valida actor/tenant/role/time
→ guards server-side
→ UPDATE condicionado e revalidado
```

O bloco `Próximos passos` existente no diagrama é preservado **como parte do snapshot original**. Ele não é a autoridade vigente de `NEXT_SAFE_ACTION` e pode estar superado por eventos materiais posteriores.

### 4.3 Arquitetura-alvo

O diagrama de guardrails representa uma arquitetura-alvo incremental:

```text
AppShell fino
→ features verticais
→ camada de aplicação
→ gateway de dados tipado
→ fronteira server-side
→ Supabase
```

Com guardrails transversais de CI, observabilidade, release e gates independentes, além de migração progressiva do legado.

Esse desenho é `TARGET_ARCHITECTURE / CONCEPTUAL`: serve para orientar decomposição e decisões futuras, mas cada transição continua exigindo análise live, escopo fechado, especialista aplicável, rollback e autorização própria.

## 5. Regra de uso em auditorias e SFJM

Estes diagramas podem ser referenciados como evidência arquitetural/versionada, mas não substituem:

- GitHub live no ref exato;
- catálogo/runtime Supabase quando a afirmação depender do ambiente;
- SFJM para continuidade operacional;
- decisões de Product Authority;
- validação independente dos especialistas.

Quando houver autorização específica para publicar esta trilha no SFJM, o SFJM deve **referenciar este índice e os arquivos canônicos**, evitando copiar integralmente os diagramas e criar uma segunda fonte de verdade.

## 6. Não-claims

Este pacote não declara:

```text
Security Go
F1-02 PASS
arquitetura-alvo implementada
App.jsx já decomposto
microservices aprovados
Vercel/CI/CD validados
Supabase globalmente seguro
zero risco cross-tenant
Ready
merge
deploy
```

## 7. Rollback

Rollback documental simples:

```text
reverter a PR/commit que introduzir este diretório
```

Nenhum rollback de runtime é necessário porque este pacote não altera comportamento do produto.
