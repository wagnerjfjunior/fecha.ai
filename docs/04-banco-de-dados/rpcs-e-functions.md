# FECH.AI — RPCs e Functions

**Status:** rascunho / pendente de reconciliação com Supabase real  
**Área:** banco de dados, segurança e regras de negócio  
**Finalidade:** documentar o padrão de inventário de RPCs/functions usadas pelo FECH.AI.  
**Escopo:** documentação. Este arquivo não altera functions, grants, policies ou migrations.

---

## 1. Objetivo

RPCs e functions são pontos críticos do FECH.AI porque concentram regras de negócio, permissões, escrita controlada e isolamento multiempresa.

Este documento deve permitir responder:

```text
qual RPC existe
qual módulo usa
quem pode executar
se anon está bloqueado
se valida auth.uid()
se faz leitura ou escrita
quais tabelas toca
qual risco
como testar
como fazer rollback
```

---

## 2. Regras obrigatórias

Para RPC sensível:

```text
não conceder EXECUTE para anon
validar auth.uid()
validar usuário ativo
validar tenant/empresa/time quando aplicável
validar perfil/permissão
não confiar em empresa_id vindo do frontend
não expor dado sensível sem allowlist
registrar evidência de teste positivo e negativo
```

---

## 3. Classificação de risco

| Risco | Tipo de RPC | Regra |
|---|---|---|
| R1 | leitura simples não sensível | revisão simples |
| R2 | leitura autenticada com regra de perfil | testar permissão |
| R3 | escrita ou regra de negócio sensível | contrato + rollback + teste negativo |
| R4 | financeiro, tenant, RLS, grant ou produção | aprovação explícita e evidência |

---

## 4. Modelo de inventário

| RPC/Function | Módulo | Tipo | Risco | anon bloqueado | Valida auth.uid | DML | Status |
|---|---|---|---|---:|---:|---:|---|
| `criar_mesa_simulacao` | MesaCliente | escrita | R3/R4 | a validar | a validar | sim | validar no Supabase |
| `proximo_lead` | CRM/Discador | leitura/escrita | R3 | a validar | a validar | sim | confirmar existência |
| `registrar_feedback` | CRM/Discador | escrita | R3 | a validar | a validar | sim | confirmar existência |
| `solicitar_lote` | CRM/Discador | escrita controlada | R3 | a validar | a validar | sim | confirmar existência |
| RPCs de histórico/2ª via | MesaCliente | leitura controlada | R3/R4 | a validar | a validar | não/parcial | mapear nome real |

---

## 5. Modelo de ficha por RPC

```markdown
## RPC: nome_da_rpc

### 1. Finalidade

### 2. Módulo

### 3. Assinatura

```sql
-- preencher após validar no Supabase
```

### 4. Tipo

Leitura / Escrita / Dry-run / Admin / Cliente-safe.

### 5. Risco

R1 / R2 / R3 / R4.

### 6. Quem pode executar

| Perfil | Pode executar? | Observação |
|---|---:|---|

### 7. Validações obrigatórias

- auth.uid()
- usuário ativo
- tenant/empresa
- time/ownership, se aplicável
- perfil/permissão
- payload mínimo

### 8. Tabelas lidas

### 9. Tabelas alteradas

### 10. Grants

### 11. Dados sensíveis

### 12. Testes obrigatórios

- positivo autorizado
- negativo sem auth
- negativo sem permissão
- cross-tenant
- payload inválido
- rollback quando houver escrita

### 13. Critério de aceite

### 14. Critério de bloqueio
```

---

## 6. Testes mínimos

Toda RPC crítica precisa ter:

```text
teste positivo
teste negativo
teste de permissão
teste cross-tenant quando aplicável
teste de anon bloqueado quando aplicável
teste de rollback quando houver escrita
evidência da saída esperada e obtida
```

---

## 7. Próximo passo

Executar inventário read-only no Supabase para listar functions reais e comparar com migrations.

Saída esperada:

```text
nome da function
schema
argumentos
retorno
grants
owner
volatilidade
security definer/invoker
tabelas tocadas quando possível
```
