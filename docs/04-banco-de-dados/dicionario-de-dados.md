# FECH.AI — Dicionário de Dados

**Status:** rascunho / pendente de inventário real do Supabase  
**Área:** banco de dados  
**Finalidade:** padronizar a documentação das tabelas, colunas, relacionamentos, regras de acesso e exposição segura de dados.  
**Escopo:** documentação. Este arquivo não altera banco, migration, RPC ou policy.

---

## 1. Objetivo

Este documento define o padrão para documentar o banco de dados do FECH.AI.

Ele deve permitir que uma pessoa técnica consiga entender:

```text
qual tabela existe
qual módulo usa a tabela
qual é a finalidade da tabela
quais colunas existem
quais campos são sensíveis
quais relações existem
quais policies protegem a tabela
quais RPCs leem ou escrevem
se o dado pode aparecer para usuário final ou cliente-safe
```

---

## 2. Regra de preenchimento

Não preencher este dicionário por suposição.

A versão oficial deve ser preenchida somente após inventário read-only do Supabase real e reconciliação com migrations versionadas no GitHub.

Fonte da verdade:

```text
1. Supabase aplicado
2. migrations do GitHub
3. documentação oficial vigente
4. evidência de teste
5. informação operacional declarada
```

---

## 3. Classificação de sensibilidade

Usar a classificação abaixo:

| Classe | Significado | Exposição |
|---|---|---|
| Pública | dado que pode aparecer na interface sem risco relevante | permitida conforme tela |
| Interna | dado operacional da empresa | apenas usuários autorizados |
| Sensível | dado que exige controle de acesso rigoroso | somente com RLS/RPC validada |
| Crítica | dado financeiro, regra interna, autorização ou governança | nunca expor sem contrato explícito |

---

## 4. Modelo de ficha por tabela

Copiar este modelo para cada tabela validada.

```markdown
## Tabela: nome_da_tabela

### 1. Finalidade

Descrever em linguagem simples para que a tabela existe.

### 2. Módulo

CRM / Discador / MesaCliente / Power Message Engine / Core / Auditoria / Outro.

### 3. Classificação

Pública / Interna / Sensível / Crítica.

### 4. Colunas

| Coluna | Tipo | Obrigatória | Default | Classificação | Observação |
|---|---|---:|---|---|---|
| `id` | uuid | sim | gerado | interna | chave primária |

### 5. Relacionamentos

| Coluna | Referencia | Tipo | Observação |
|---|---|---|---|

### 6. Índices

| Índice | Colunas | Finalidade |
|---|---|---|

### 7. RLS e policies

| Policy | Operação | Perfis | Regra resumida |
|---|---|---|---|

### 8. RPCs que leem

| RPC | Finalidade | Observação |
|---|---|---|

### 9. RPCs que escrevem

| RPC | Tipo de escrita | Observação |
|---|---|---|

### 10. Exposição permitida

| Contexto | Pode expor? | Observação |
|---|---:|---|
| Frontend autenticado | a definir | depende da policy |
| Cliente-safe | a definir | deve usar allowlist |
| Relatório gestor | a definir | depende do perfil |
| IA | a definir | depende de mascaramento e finalidade |

### 11. Riscos

- Listar riscos de vazamento, alteração indevida, inconsistência ou impacto financeiro.

### 12. Evidência

- Query, migration, PR ou teste que comprova a estrutura.
```

---

## 5. Campos de auditoria recomendados

Quando aplicável, documentar campos de auditoria:

```text
created_at
updated_at
created_by
updated_by
empresa_id
tenant_id
status
metadata
```

A existência real desses campos deve ser confirmada no Supabase.

---

## 6. Exposição cliente-safe

Para qualquer payload voltado ao cliente, usar allowlist.

Regra:

```text
Não expor campo porque ele existe.
Expor apenas campo aprovado para aquela visão.
```

---

## 7. Critério para tornar oficial

Este dicionário será considerado oficial quando:

```text
tabelas reais forem listadas
colunas reais forem conferidas
RLS e policies forem documentadas
RPCs forem vinculadas
campos sensíveis forem classificados
exposição cliente-safe for definida
pendências forem registradas
```
