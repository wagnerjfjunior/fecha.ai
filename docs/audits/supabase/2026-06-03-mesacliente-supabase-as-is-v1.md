# FECH.AI - Auditoria Supabase/RPC/RLS AS-IS MesaCliente v1

**Data:** 2026-06-03
**Status:** `AS_IS_SUPABASE_GITHUB / PENDENTE_RECONCILIACAO_SUPABASE_REAL`
**Tipo:** documentacao-only / read-only.

Nota editorial: arquivo normalizado em ASCII para evitar alerta de caracteres ocultos ou bidirecionais.

---

## 1. Objetivo

Auditar os artefatos Supabase/RPC/RLS do MesaCliente existentes no repositorio, sem executar SQL no banco e sem implementar correcao.

Esta PR documenta evidencias de GitHub. Ela nao prova o estado aplicado no Supabase real.

```text
Implementacao autorizada: NAO
Supabase real: PENDENTE_RECONCILIACAO_SUPABASE_REAL
```

---

## 2. Escopo proibido

Esta PR nao altera:

```text
Supabase real
RLS
FORCE RLS
RPCs
migrations
grants
policies
parser
motor financeiro
frontend
Vercel
GitHub Actions
Worker
Make/n8n
integracoes reais
producao
```

---

## 3. Relacao com PRs anteriores

| PR | Papel |
|---|---|
| PR #52 | Inventario documental MesaCliente; nenhum documento virou OFICIAL_VIGENTE. |
| PR #53 | Auditoria AS-IS de codigo; confirmou uso de RPCs no frontend e Supabase real pendente. |
| PR #54 | Auditoria dos artefatos Supabase/RPC/RLS versionados no GitHub. |

---

## 4. Fontes verificadas no GitHub

Foram verificados artefatos documentais e migrations relacionados a:

```text
docs/04-banco-de-dados/rpcs-e-functions.md
docs/04-banco-de-dados/mapa-tabelas.md
supabase/migrations/*mesa_cliente*.sql
supabase/rollback/*mesa_cliente*.sql
supabase/tests/mesa-cliente/*
scripts/tests/mesa-cliente/*
```

Arquivos lidos com maior detalhe:

```text
supabase/migrations/20260517162000_mesa_cliente_engenharia_financeira_hardening.sql
supabase/migrations/20260518170000_mesa_cliente_fase_4b_persistir_agenda_financeira.sql
supabase/migrations/20260518162000_mesa_cliente_fase_4c_agenda_cliente_safe.sql
supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
supabase/migrations/20260521104000_mesa_cliente_fase_7_rpc_aplicar_operacao_financeira_admin.sql
```

---

## 5. Limites da auditoria

Nao foi validado no Supabase real:

```text
schema aplicado
migrations aplicadas
tabelas reais
colunas reais
constraints reais
indices reais
RLS real
FORCE RLS real
policies reais
bodies reais das functions
grants reais
owners reais
security definer/invoker real
search_path real
permissoes de anon/authenticated/service_role
```

---

## 6. Tabelas criticas MesaCliente

| Tabela | Sensibilidade | Status |
|---|---:|---|
| `mesa_simulacoes` | Alta | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_agendas_financeiras` | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_fluxo_parcelas` | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_fluxo_operacoes` | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_politicas_financeiras` | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_politica_premio_faixas` | Critica | PENDENTE_SUPABASE_REAL |
| `empresas` | Critica | PENDENTE_SUPABASE_REAL |
| `empreendimentos` | Alta | PENDENTE_SUPABASE_REAL |
| `corretores` | Critica | PENDENTE_SUPABASE_REAL |

---

## 7. Evidencias GitHub

Evidencias positivas versionadas:

```text
migrations indicam hardening de RLS e policies
migrations indicam revogacao de acesso anon em tabelas sensiveis
migrations indicam bloqueio de DML direto por authenticated em tabelas financeiras
migrations indicam uso de security definer em RPCs criticas
migrations indicam validacao de auth.uid, corretor ativo, empresa, perfil e cross-tenant
migrations indicam cliente-safe como leitura controlada
```

Status:

```text
POSITIVO_GITHUB
PENDENTE_SUPABASE_REAL
```

---

## 8. RPCs criticas observadas

| RPC/function | Tipo | Risco | Status |
|---|---|---:|---|
| `mesa_cliente_financeiro_assert_integridade` | integridade/trigger | R4 | GitHub apenas |
| `mesa_cliente_persistir_agenda_financeira_admin` | escrita controlada | R4 | GitHub apenas |
| `mesa_cliente_obter_agenda_financeira_cliente_safe` | leitura cliente-safe | R4 | GitHub apenas |
| `mesa_cliente_listar_operacoes_financeiras_admin` | leitura admin | R3/R4 | GitHub apenas |
| `mesa_cliente_aplicar_operacao_financeira_admin` | DML financeiro | R4 | GitHub apenas |

---

## 9. Riscos P0/P1

| Risco | Severidade | Status |
|---|---:|---|
| Supabase real divergir das migrations | P0/R4 | Bloqueia implementacao |
| RPC sensivel executavel por anon | P0/R4 | Bloqueia producao |
| Frontend authority aceita no banco | P0/R4 | Exige validacao real |
| Cliente-safe vazar campo interno | P0/R4 | Bloqueia exposicao cliente |
| RLS/policies driftadas | P0/R4 | Bloqueia leitura/escrita sensivel |
| FORCE RLS esperado mas ausente | P0/R4 | Bloqueia conclusao de RLS forte |
| DML financeiro divergente | P0/R4 | Bloqueia operacao financeira |
| Testes nao executados nesta auditoria | P1/R3 | Exige proxima etapa |

---

## 10. Cliente-safe

Cliente-safe deve ser allowlist. Nao pode depender de convencao informal nem filtragem somente no frontend.

Campos/grupos bloqueados ate validacao de payload real:

```text
tenant_id
empresa_id quando nao indispensavel ao escopo permitido
corretor_id interno
perfil/permissao
payload bruto
metadata bruta
checksum
politica financeira interna
VPL interno
premio
comissao
faixas de remuneracao
taxas internas
campos de auditoria
service/debug payload
```

---

## 11. Queries read-only obrigatorias para Supabase real

### 11.1 Functions/RPCs

```sql
select n.nspname as schema_name,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args,
       pg_get_function_result(p.oid) as result,
       p.prosecdef as security_definer,
       p.provolatile as volatility,
       pg_get_userbyid(p.proowner) as owner
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and (p.proname ilike '%mesa%'
    or p.proname ilike '%agenda%'
    or p.proname ilike '%operacao%'
    or p.proname ilike '%fluxo%')
order by n.nspname, p.proname;
```

### 11.2 Grants de routines

```sql
select routine_schema, routine_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_name ilike '%mesa%'
   or routine_name ilike '%agenda%'
   or routine_name ilike '%operacao%'
   or routine_name ilike '%fluxo%'
order by routine_schema, routine_name, grantee;
```

### 11.3 Tabelas, RLS e FORCE RLS

Esta query resolve o feedback P2: `pg_tables.rowsecurity` confirma RLS habilitado, mas nao confirma FORCE RLS. A reconciliacao deve consultar tambem `pg_class.relforcerowsecurity`.

```sql
select n.nspname as schema_name,
       c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls_enabled,
       c.relkind as relkind
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('r', 'p')
  and n.nspname not in ('pg_catalog', 'information_schema')
  and (c.relname ilike '%mesa%'
    or c.relname ilike '%agenda%'
    or c.relname ilike '%operacao%'
    or c.relname ilike '%fluxo%')
order by n.nspname, c.relname;
```

### 11.4 Policies

```sql
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%'
   or tablename ilike '%fluxo%'
order by schemaname, tablename, policyname;
```

### 11.5 Grants de tabelas

```sql
select table_schema, table_name, grantee, privilege_type
from information_schema.table_privileges
where table_name ilike '%mesa%'
   or table_name ilike '%agenda%'
   or table_name ilike '%operacao%'
   or table_name ilike '%fluxo%'
order by table_schema, table_name, grantee, privilege_type;
```

### 11.6 Migrations aplicadas

```sql
select *
from supabase_migrations.schema_migrations
where name ilike '%mesa%'
   or name ilike '%agenda%'
   or name ilike '%operacao%'
   or name ilike '%fluxo%'
order by version;
```

---

## 12. Matriz minima de reconciliacao futura

```text
Migration GitHub
-> objeto declarado
-> existe no Supabase real?
-> assinatura real bate?
-> body real bate?
-> grants reais batem?
-> RLS real bate?
-> FORCE RLS real bate?
-> policies reais batem?
-> testes positivos/negativos existem?
-> status final: OK / DRIFT / AUSENTE / OBSOLETO / BLOQUEADO
```

---

## 13. Criterios de aceite desta PR documental

A PR #54 so deve ser aceita como auditoria documental se:

```text
altera somente este arquivo .md
mantem documentacao-only / read-only
nao altera banco, migrations, RPCs, RLS, grants, policies ou codigo
mantem Supabase real como pendente
lista RLS e FORCE RLS como verificacoes futuras
registra grants de anon/authenticated como pendencia obrigatoria
classifica financeiro/tenant/RLS/grant como R4
trata cliente-safe por allowlist
separa evidencia GitHub de estado Supabase real
nao autoriza implementacao futura automatica
```

---

## 14. Bloqueios antes de implementacao

Continuam bloqueados:

```text
alterar RPC
criar migration
corrigir RLS
alterar grant
alterar policy
mexer em parser
mexer em motor financeiro
mexer em frontend
publicar deploy
rodar SQL de escrita
aplicar rollback
expor cliente-safe
usar proposta real baseada em inferencia
```

---

## 15. Rollback desta PR

Como esta PR e documentation-only:

```text
Rollback: revert da PR #54 ou remocao deste arquivo.
Impacto em Supabase: nenhum.
Impacto em Vercel/producao: nenhum.
Impacto em MesaCliente runtime: nenhum.
```

---

## 16. Parecer final

```text
Status PR #54: AS_IS_SUPABASE_GITHUB / PENDENTE_RECONCILIACAO_SUPABASE_REAL
Tipo: documentacao-only / read-only
Implementacao autorizada: NAO
Risco global: R4/P0-P1
Ajuste incorporado: query read-only agora verifica RLS e FORCE RLS via pg_class.relrowsecurity e pg_class.relforcerowsecurity.
Bloqueio principal: Supabase real nao foi consultado.
Proxima etapa: validar PR #54 operacionalmente; depois executar inventario read-only no Supabase real, se autorizado.
```
