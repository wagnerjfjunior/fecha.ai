# FECH.AI - Matriz de risco Supabase real MesaCliente por RPC/tabela v1

**Data:** 2026-06-04
**Status:** `RISK_MATRIX_READONLY / PENDENTE_BODY_REVIEW`
**Base:** PR #55 - inventario read-only do Supabase real
**Projeto Supabase:** `Discador-MesaCliente`
**Project ref:** `uobxxgzshrmbtjfdolxd`
**Tipo:** documentacao-only / read-only evidence.

Nota editorial: arquivo normalizado em ASCII para remover risco de caracteres ocultos ou bidirecionais no Markdown.

---

## 1. Objetivo

Classificar os achados da PR #55 em uma matriz de risco por RPC/function e tabela, sem corrigir nada.

Esta PR nao altera banco, schema, RLS, FORCE RLS, policies, grants, functions, migrations, parser, motor financeiro, frontend, Vercel, GitHub Actions, Worker, Make/n8n, integracoes reais ou producao.

---

## 2. Escopo executado

Foram executadas consultas read-only no Supabase real para levantar:

```text
functions/RPCs com anon/PUBLIC EXECUTE
security definer/invoker
search_path/function_config
owner
volatility
grantees
uso textual de auth.uid()
presenca textual de raise/guards
indicio textual de escrita
indicio textual de tabelas tocadas
RLS/FORCE RLS por tabela
grants de tabela
policies de tabela
```

Status:

```text
READ_ONLY_EXECUTADO
SEM_DDL
SEM_DML
SEM_MIGRATION
SEM_GRANT
SEM_POLICY_CHANGE
SEM_DEPLOY
```

---

## 3. Limites da matriz

Esta matriz usa metadados reais e heuristicas de texto sobre `pg_get_functiondef`, mas **nao substitui body review linha a linha**.

Nao foi feito nesta PR:

```text
alteracao de grants
alteracao de RLS/FORCE RLS
alteracao de policy
alteracao de RPC/function
migration
DDL/DML
teste positivo
teste negativo
teste cross-tenant
execucao como anon
geracao de payload cliente-safe
revisao linha a linha completa de todos os function bodies
```

---

## 4. Matriz de risco - RPCs/functions com anon ou PUBLIC EXECUTE

### 4.1 Criterios de classificacao

| Status | Significado |
|---|---|
| `BLOQUEADO_P0_BODY_REVIEW` | Nome/grant/indicio sugerem escrita, aprovacao, importacao, politica financeira ou impacto comercial. Nao implementar antes de body review e teste negativo. |
| `REQUER_BODY_REVIEW_P1` | Pode ser leitura ou helper, mas tem anon/PUBLIC EXECUTE e precisa provar guard/tenant/escopo. |
| `POSSIVEL_OK_HELPER_P2` | Function parece matematica/helper sem acesso a dados sensiveis, mas ainda precisa confirmacao formal. |
| `OK_PARCIAL_COM_GUARD` | Tem auth.uid/guards por indicio textual, mas ainda depende de teste negativo. |

### 4.2 Tabela de RPCs/functions criticas

| Function | Grants externos | SecDef | auth.uid | Escreve? | Toca dados | Impacto | Risco | Status |
|---|---|---:|---:|---:|---|---|---:|---|
| `aprovar_rejeitar_mesa` | PUBLIC, anon, authenticated | true | true | true | `mesa_simulacoes` | proposta/aprovacao | P0/R4 | `BLOQUEADO_P0_BODY_REVIEW` |
| `importar_mesa_cliente_disponibilidade_oficial` | anon, authenticated | true | true | true | disponibilidade/unidades | disponibilidade oficial/proposta | P0/R4 | `BLOQUEADO_P0_BODY_REVIEW` |
| `mesa_cliente_upsert_faixas_premio` | anon, authenticated | true | false | true | politicas/faixas | premio/regra financeira | P0/R4 | `BLOQUEADO_P0_BODY_REVIEW` |
| `mesa_cliente_upsert_politica_financeira` | anon, authenticated | true | false | true | politicas financeiras | VPL/taxas/regra financeira | P0/R4 | `BLOQUEADO_P0_BODY_REVIEW` |
| `registrar_upload_arquivo_mesa` | anon, authenticated | true | true | true | disponibilidade/importacao | arquivo/importacao | P0/P1 | `BLOQUEADO_P0_BODY_REVIEW` |
| `salvar_mesa_cliente_desconto_politica` | anon, authenticated | true | true | true | politicas/desconto | desconto/regra comercial | P0/R4 | `BLOQUEADO_P0_BODY_REVIEW` |
| `salvar_mesa_cliente_enriquecimento` | anon, authenticated | true | true | true | disponibilidade/enriquecimento | ficha unidade/proposta | P1/R3-R4 | `BLOQUEADO_BODY_REVIEW` |
| `get_empreendimentos_mesa` | anon, authenticated | true | true | false | disponibilidade | leitura comercial | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `get_unidades_mesa` | anon, authenticated | true | true | false | disponibilidade | leitura unidade/estoque | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `get_mesa_cliente_desconto_politica` | anon, authenticated | true | true | false | politicas/desconto | regra comercial interna | P1/R3-R4 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_listar_politicas_financeiras` | anon, authenticated | true | a validar | false | politicas financeiras | regra financeira interna | P1/R3-R4 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_obter_politica_financeira` | anon, authenticated | true | a validar | false | politicas financeiras | regra financeira interna | P1/R3-R4 | `REQUER_BODY_REVIEW_P1` |
| `validar_mesa_cliente_desconto` | anon, authenticated | true | a validar | a validar | desconto/politica | desconto/proposta | P1/R3-R4 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_assert_auth` | anon, authenticated | true | true | false | helper auth | controle interno | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_assert_empreendimento_empresa` | anon, authenticated | true | false | false | empreendimento/empresa | tenant helper | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_can_access_empresa` | anon, authenticated | true | false | false | helper permissao | tenant helper | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_can_admin_empresa` | anon, authenticated | true | false | false | helper permissao | admin helper | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_current_corretor_context` | anon, authenticated | true | true | false | contexto corretor | tenant/perfil | P1/R3 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_financeiro_assert_integridade` | anon, authenticated | true | true | false | simulacoes/parcelas/operacoes/politicas | integridade financeira | P1/R3-R4 | `REQUER_BODY_REVIEW_P1` |
| `mesa_cliente_financeiro_assert_calculo_input` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_calcular_antecipacao_composta` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_calcular_postergacao_composta` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_calcular_vpl_parcela` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_dias_entre` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_fator_composto` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_valor_futuro_composto` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |
| `mesa_cliente_financeiro_valor_presente_composto` | anon, authenticated | false | false | false | helper calculo | calculo puro | P2 | `POSSIVEL_OK_HELPER_P2` |

---

## 5. Matriz de risco - tabelas

| Tabela | RLS | FORCE RLS | anon priv | authenticated DML | Policies | Impacto | Risco | Status |
|---|---:|---:|---:|---:|---:|---|---:|---|
| `mesa_cliente_unidade_enriquecimentos` | true | false | false | true | 0 | ficha unidade/proposta | P0/P1 | `BLOQUEADO_POLICY_REVIEW` |
| `mesa_cliente_desconto_politicas` | true | false | false | false | 4 | desconto/regra comercial | P1/R4 | `FORCE_RLS_REVIEW` |
| `mesa_cliente_fluxo_operacoes` | true | false | false | false | 4 | operacoes financeiras | P1/R4 | `FORCE_RLS_REVIEW` |
| `mesa_cliente_fluxo_parcelas` | true | false | false | false | 4 | fluxo financeiro | P1/R4 | `FORCE_RLS_REVIEW` |
| `mesa_cliente_politica_premio_faixas` | true | false | false | false | 4 | premio/regra financeira | P1/R4 | `FORCE_RLS_REVIEW` |
| `mesa_cliente_politicas_financeiras` | true | false | false | false | 4 | VPL/taxas/regra financeira | P1/R4 | `FORCE_RLS_REVIEW` |
| `mesa_fluxo_pagamentos_canonico` | true | false | false | false | 0 | fluxo canonico | P1/R3-R4 | `POLICY_AND_FORCE_RLS_REVIEW` |
| `mesa_cliente_agendas_financeiras` | true | true | false | false | 1 | agenda financeira | P1 | `OK_PARCIAL` |
| `mesa_simulacoes` | true | true | false | false | 1 | simulacao/proposta | P1 | `OK_PARCIAL` |
| `mesa_arquivos` | true | true | false | false | 1 | arquivos/importacao | P2/P1 | `OK_PARCIAL` |
| `mesa_eventos` | true | true | false | false | 1 | eventos/auditoria | P2/P1 | `OK_PARCIAL` |
| `mesa_fluxo_pagamentos` | true | true | false | false | 1 | fluxo pagamento legado | P2/P1 | `OK_PARCIAL` |

---

## 6. Bloqueios por impacto MesaCliente

### 6.1 Proposta/aprovacao

```text
BLOQUEADO: aprovar_rejeitar_mesa tem PUBLIC/anon EXECUTE, SECURITY DEFINER, indicio de escrita e toca mesa_simulacoes.
Exigir: body review linha a linha, teste anon, teste authenticated sem permissao, teste cross-tenant, teste role/perfil.
```

### 6.2 Disponibilidade oficial/tabela de unidades

```text
BLOQUEADO: importar_mesa_cliente_disponibilidade_oficial e registrar_upload_arquivo_mesa possuem anon EXECUTE e indicio de escrita/importacao.
Exigir: body review, escopo de empresa/empreendimento, teste anon, teste tenant, rollback funcional.
```

### 6.3 Politicas financeiras, desconto, premio, VPL

```text
BLOQUEADO: upsert/salvar/listar/obter politicas financeiras e desconto aparecem com anon EXECUTE.
Exigir: distinguir leitura x escrita, validar se dados internos podem vazar, testar anon/authenticated/cross-tenant.
```

### 6.4 Cliente-safe

```text
BLOQUEADO: qualquer payload cliente-safe continua pendente ate revisar functions que tocam politicas, descontos, fluxo, operacoes, parcelas e agendas.
Exigir: allowlist explicita, teste de ausencia de metadata/payload bruto/checksum/comissao/premio/VPL interno.
```

### 6.5 Enriquecimento de unidade

```text
BLOQUEADO: mesa_cliente_unidade_enriquecimentos tem DML direto para authenticated e policy_count=0 no levantamento.
Exigir: confirmar se RLS sem policy bloqueia acesso direto ou se grants/policies divergem; validar intencao funcional e escrever teste negativo.
```

---

## 7. Ordem segura das proximas PRs

1. **PR #57 - Body review de RPCs P0 com anon/PUBLIC EXECUTE**
   - `aprovar_rejeitar_mesa`
   - `importar_mesa_cliente_disponibilidade_oficial`
   - `mesa_cliente_upsert_faixas_premio`
   - `mesa_cliente_upsert_politica_financeira`
   - `salvar_mesa_cliente_desconto_politica`
   - `registrar_upload_arquivo_mesa`
   - `salvar_mesa_cliente_enriquecimento`

2. **PR #58 - Plano de testes negativos Supabase MesaCliente**
   - anon
   - authenticated sem empresa
   - authenticated de outra empresa/tenant
   - corretor sem perfil
   - admin empresa
   - root/admin
   - cliente-safe payload

3. **PR #59 - Reconciliacao GitHub migrations x Supabase real por hash/body**
   - migrations aplicadas
   - hash de functions
   - grants reais
   - policies reais
   - divergencias por nome/versao

4. **PRs de correcao futura - somente apos autorizacao explicita**
   - uma classe de risco por PR
   - rollback SQL
   - testes negativos
   - validacao cross-tenant

---

## 8. Criterios de aceite desta PR documental

A PR #56 pode ser aceita se:

```text
altera somente documento .md
mantem read-only/documentacao-only
nao corrige grants/RLS/RPC/policy
classifica P0/P1 claramente
nao afirma seguranca final
mantem implementacao bloqueada
prepara body review e testes negativos
```

---

## 9. Parecer final

```text
Status: RISK_MATRIX_READONLY / PENDENTE_BODY_REVIEW
Tipo: documentacao-only / read-only evidence
Implementacao autorizada: NAO
Correcao autorizada: NAO
Risco global: P0/P1
Principal bloqueio: RPCs/functions com anon/PUBLIC EXECUTE e indicio de escrita ou impacto comercial/financeiro.
Segundo bloqueio: tabelas financeiras com FORCE RLS=false e mesa_cliente_unidade_enriquecimentos com authenticated DML sem policy levantada.
Proxima etapa: body review das RPCs P0 e plano de testes negativos.
```
