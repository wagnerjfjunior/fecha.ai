# FECH.AI / MesaCliente — PRE-20C Reconciliação GitHub x Supabase

**Status:** rascunho / fase preparatória read-only  
**Área:** MesaCliente, banco de dados, histórico e rastreabilidade  
**Finalidade:** validar o estado real do GitHub e do Supabase antes de iniciar a Fase 20C.  
**Escopo:** documentação, inventário e evidência. Não altera código, banco, RPC, migration, frontend ou produção.

---

## 1. Objetivo

Preparar a Fase 20C com segurança.

A 20C tem como objetivo funcional futuro rastrear, no fluxo histórico/proposta/2ª via:

```text
valor original
valor final salvo
diferença absoluta
diferença percentual
```

Antes disso, este PRE-20C deve reconciliar o estado real entre GitHub e Supabase.

---

## 2. Por que existe

A Fase 20C toca uma área sensível: histórico de proposta e diferença entre valor original e valor final.

Sem reconciliação prévia, há risco de:

```text
usar documentação antiga
assumir RPC que não existe
assumir migration não aplicada
alterar frontend sem contrato
misturar rastreabilidade com regra financeira
contaminar operações financeiras
criar drift entre GitHub e Supabase
```

---

## 3. Escopo permitido

Permitido:

```text
ler documentação
listar arquivos relevantes
comparar PRs e branches
inventariar migrations versionadas
solicitar evidência read-only do Supabase
mapear RPCs esperadas
mapear tabelas esperadas
identificar drift
produzir relatório de rota
```

---

## 4. Fora do escopo

Proibido nesta fase:

```text
criar migration
alterar RPC
alterar tabela
alterar policy/RLS/grant
alterar frontend
alterar parser
alterar motor financeiro
alterar Supabase
fazer merge
criar regra definitiva sem evidência
```

---

## 5. Fonte da verdade

Ordem obrigatória:

```text
1. Supabase real aplicado
2. GitHub na branch correta
3. documentação oficial vigente
4. evidência de PR/teste
5. informação operacional
6. inferência técnica declarada
```

Se GitHub e Supabase divergirem, declarar drift e parar a implementação até decisão.

---

## 6. Estado conhecido pelo GitHub

Até o PR #25, foram consolidadas:

```text
Fase 8B — adapter Front/BFF para operações financeiras
Fase 8C/8D — painel administrativo de operações financeiras e build
Fases 18A-18D — contexto, sessão, token e integração visual
Fases 19A-19E — gravação de fluxo e payload completo
Fase 20A — RPC read-only para reabrir fluxo histórico
Fases 20A.1/20A.2/20A.5 — hardening de visibilidade comercial
Fase 20B — 2ª via read-only pelo Histórico
```

Pendência funcional registrada:

```text
20C — rastreabilidade valor original x valor final
```

---

## 7. O que validar no GitHub

Validar:

```text
branch main atual
PR #25 mergeado
arquivos de documentação de handoff
migrations relacionadas a 20A/20A.5/20B
componentes de histórico e 2ª via
serviços/API de MesaCliente
workflows de validação existentes
```

Arquivos/pastas sensíveis:

```text
supabase/migrations/*
src/components/MesaCliente/*
src/features/mesaCliente/*
docs/mesa-cliente/*
docs/protocolos/*
```

---

## 8. O que validar no Supabase

Validar de forma read-only:

```text
tabelas de simulação/histórico/fluxo
functions/RPCs relacionadas ao MesaCliente
RLS ativa nas tabelas sensíveis
grants das RPCs críticas
policies por tenant/empresa/time/ownership
colunas necessárias para valor original e valor final
logs ou evidências de uso, se disponíveis
```

Não executar escrita durante este preflight.

---

## 9. Critérios de bloqueio

Bloquear início da 20C se:

```text
RPC documentada não existir no Supabase
migration existir no GitHub mas não estar aplicada
Supabase tiver function não versionada no GitHub
RLS estiver divergente do contrato
não houver campo/payload suficiente para valor original
não houver forma segura de obter valor final salvo
houver risco de expor dado financeiro interno
houver dúvida sobre ownership/time/tenant
```

---

## 10. Saída esperada do PRE-20C

Gerar relatório com:

```text
1. Estado verificado no GitHub
2. Estado verificado no Supabase
3. Migrations relevantes
4. RPCs relevantes
5. Tabelas e colunas relevantes
6. Componentes frontend envolvidos
7. Drifts encontrados
8. Riscos
9. Bloqueios
10. Rota recomendada para implementar 20C
```

---

## 11. Rota de decisão

Após o relatório, escolher uma das rotas:

| Rota | Quando usar |
|---|---|
| A — seguir para 20C | GitHub e Supabase estão coerentes |
| B — corrigir documentação | implementação está correta, mas docs estão defasadas |
| C — reconciliar banco/código | há drift técnico que impede implementação segura |

---

## 12. Próximo passo único

Executar inventário read-only do GitHub e do Supabase, depois preencher o relatório PRE-20C antes de qualquer implementação.
