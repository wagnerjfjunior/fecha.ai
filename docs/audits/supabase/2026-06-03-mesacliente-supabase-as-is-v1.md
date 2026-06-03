# FECH.AI - Auditoria Supabase/RPC/RLS AS-IS MesaCliente v1

**Data:** 2026-06-03
**Status:** `AS_IS_SUPABASE_GITHUB / PENDENTE_RECONCILIACAO_SUPABASE_REAL`
**Responsavel conceitual:** GPT 3 - FECH.AI Supabase Security Specialist
**Apoio recomendado:** GPT 0, GPT 8 e GPT 1
**Executor operacional:** Projeto Principal FECH.AI com conector GitHub
**Arquivo:** `docs/audits/supabase/2026-06-03-mesacliente-supabase-as-is-v1.md`
**Tipo:** documentacao-only / read-only.
**Escopo proibido:** nao altera Supabase real, RLS, RPCs, migrations, grants, policies, parser, motor financeiro, frontend, Vercel, GitHub Actions, Worker, Make/n8n, integracoes reais ou producao.

---

## 1. Objetivo

Auditar os artefatos Supabase/RPC/RLS do MesaCliente existentes no repositorio, em modo AS-IS, sem execucao no banco e sem implementacao.

Esta PR documenta o que o GitHub declara sobre Supabase, migrations, RPCs, RLS, grants, policies, cliente-safe e operacoes financeiras, mas **nao prova estado aplicado no Supabase real**.

Conclusao inicial:

```text
Repositorio contem artefatos relevantes e maduros de hardening, RPCs e testes.
Estado aplicado no Supabase real: NAO COMPROVADO.
Implementacao autorizada: NAO.
```

---

## 2. Relação com PRs anteriores

| PR | Status | Papel nesta auditoria |
|---|---|---|
| PR #52 | Mergeada | Inventario documental MesaCliente. Marcou documentos como candidatos/pendentes, sem OFICIAL_VIGENTE. |
| PR #53 | Mergeada | Auditoria AS-IS de codigo MesaCliente. Confirmou uso de RPCs no frontend e apontou que Supabase real continua pendente. |
| PR #54 | Atual | Auditoria AS-IS dos artefatos Supabase/RPC/RLS no GitHub, ainda sem consultar banco real. |

---

## 3. Fontes verificadas no GitHub

Buscas e leituras feitas no repositorio:

```text
mesa_cliente
create policy mesa_cliente
grant execute mesa_cliente
docs/04-banco-de-dados/rpcs-e-functions.md
docs/04-banco-de-dados/mapa-tabelas.md
supabase/migrations/*mesa_cliente*.sql
supabase/rollback/*mesa_cliente*.sql
supabase/tests/mesa-cliente/*
scripts/tests/mesa-cliente/*
```

Arquivos lidos diretamente com maior detalhe:

```text
docs/04-banco-de-dados/rpcs-e-functions.md
docs/04-banco-de-dados/mapa-tabelas.md
supabase/migrations/20260517162000_mesa_cliente_engenharia_financeira_hardening.sql
supabase/migrations/20260518170000_mesa_cliente_fase_4b_persistir_agenda_financeira.sql
supabase/migrations/20260518162000_mesa_cliente_fase_4c_agenda_cliente_safe.sql
supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
supabase/migrations/20260521104000_mesa_cliente_fase_7_rpc_aplicar_operacao_financeira_admin.sql
```

Arquivos identificados por busca e ainda nao lidos integralmente nesta PR:

```text
supabase/migrations/20260516022500_fix_mesa_cliente_enviado_por_fk.sql
supabase/migrations/20260516093000_mesa_cliente_enriquecimento_unidades_v1.sql
supabase/migrations/20260516161000_mesa_cliente_disponibilidade_oficial_v1.sql
supabase/migrations/20260517193000_mesa_cliente_engenharia_financeira_rpcs_admin.sql
supabase/migrations/20260517203000_mesa_cliente_engenharia_financeira_calculo_base.sql
supabase/migrations/20260517210000_mesa_cliente_engenharia_financeira_rpc_simulacao_admin.sql
supabase/migrations/20260517211500_mesa_cliente_engenharia_financeira_revoke_anon_rpc_simulacao_admin.sql
supabase/migrations/20260518120000_mesa_cliente_fase_4a_agenda_financeira_json_first.sql
supabase/migrations/20260518194500_fix_mesa_cliente_5a_remover_agenda_id_operacoes.sql
supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
supabase/migrations/20260519182000_mesa_cliente_fase_5c_confirmacao_cancelamento_operacao_financeira.sql
supabase/migrations/20260521153000_mesa_cliente_import_json_admin.sql
supabase/migrations/20260525161000_mesa_cliente_fase_8i_fix_criar_mesa_fluxo_tipo_enum.sql
supabase/migrations/20260525180000_mesa_cliente_20a_obter_simulacao_fluxo_historico.sql
supabase/migrations/20260525181000_mesa_cliente_20a_revoke_public_obter_simulacao_fluxo_historico.sql
supabase/migrations/20260525182500_mesa_cliente_20a2_precedencia_owner_fluxo_historico.sql
supabase/migrations/20260526120000_mesa_cliente_fase_20a_obter_simulacao_fluxo_historico.sql
supabase/migrations/20260526133500_mesa_cliente_20a5_visibilidade_comercial_final.sql
supabase/migrations/20260526162000_mesa_cliente_20c2_hardening_agendas_grants.sql
supabase/migrations/20260528013000_mesa_cliente_20d5_fluxo_canonico_shadow.sql
supabase/rollback/*mesa_cliente*.sql
supabase/tests/mesa-cliente/*
scripts/tests/mesa-cliente/*
```

---

## 4. Limites desta auditoria

Esta auditoria **nao** executou queries no Supabase real.

Nao foi validado ainda:

```text
schema real aplicado
migrations realmente aplicadas
tabelas existentes no banco real
colunas reais
constraints reais
indices reais
RLS real ativo/inativo
policies reais
function bodies reais
grants reais
owners reais
volatility real
security definer/invoker real
role anon/authenticated/service_role no estado aplicado
se as functions do GitHub batem byte a byte com o banco
```

Portanto:

```text
GitHub mostra intencao/versionamento.
Supabase real continua fonte soberana pendente.
```

---

## 5. Regras obrigatorias extraidas dos docs transversais

O documento `docs/04-banco-de-dados/rpcs-e-functions.md` define que RPCs sensiveis devem bloquear anon, validar auth.uid, usuario ativo, tenant/empresa/time, perfil/permissao, nao confiar em empresa_id do frontend, nao expor dado sensivel sem allowlist, e registrar testes positivos/negativos.

O documento `docs/04-banco-de-dados/mapa-tabelas.md` declara explicitamente que o mapa nao e verdade final sem reconciliacao com Supabase real e lista as tabelas criticas MesaCliente:

```text
mesa_simulacoes
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_fluxo_operacoes
mesa_cliente_politicas_financeiras
mesa_cliente_politica_premio_faixas
```

Status:

```text
REGRA_DOCUMENTAL_CONFIRMADA / PENDENTE_SUPABASE_REAL
```

---

## 6. Mapa AS-IS de tabelas MesaCliente citadas

| Tabela | Origem observada | Sensibilidade | Status |
|---|---|---:|---|
| `mesa_simulacoes` | Docs transversais, codigo PR #53, migrations | Alta | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_agendas_financeiras` | Fase 4B cria cabecalho versionado | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_fluxo_parcelas` | Hardening + Fase 4B altera agenda_id | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_fluxo_operacoes` | Hardening + Fases 5B/5C/5D/7 | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_politicas_financeiras` | Hardening financeiro | Critica | PENDENTE_SUPABASE_REAL |
| `mesa_cliente_politica_premio_faixas` | Hardening financeiro | Critica | PENDENTE_SUPABASE_REAL |
| `empresas` | dependencia multiempresa | Critica | PENDENTE_SUPABASE_REAL |
| `empreendimentos` | dependencia comercial/tenant | Alta | PENDENTE_SUPABASE_REAL |
| `corretores` | auth.uid/perfil/empresa | Critica | PENDENTE_SUPABASE_REAL |

---

## 7. Evidencias de hardening no GitHub

A migration `20260517162000_mesa_cliente_engenharia_financeira_hardening.sql` declara como objetivo consolidar RLS/policies, bloquear escrita direta pelo frontend/authenticated, validar integridade multiempresa/multitenant no banco e preparar RPCs soberanas.

Evidencias observadas no arquivo:

```text
- Habilita RLS em tabelas financeiras MesaCliente.
- Remove policies duplicadas/legadas.
- Cria policies canonicas de SELECT por tenant/empresa/corretor ativo.
- Cria policies de insert/update/delete com check false/using false.
- Revoga acesso de anon.
- Revoga insert/update/delete de authenticated.
- Concede somente select a authenticated nas tabelas financeiras.
- Cria trigger/function de integridade multiempresa.
```

Classificacao:

```text
POSITIVO_GITHUB: hardening esta versionado.
PENDENTE_SUPABASE_REAL: nao comprova que foi aplicado no banco real.
RISCO: P0/P1 se o banco real divergir do GitHub.
```

---

## 8. RPCs e functions MesaCliente observadas no GitHub

### 8.1 RPCs citadas pelo codigo frontend na PR #53

```text
get_empreendimentos_mesa
get_empresa_mesa_config
get_historico_mesas
get_unidades_mesa
registrar_upload_arquivo_mesa
criar_mesa_simulacao
aprovar_rejeitar_mesa
importar_mesa_cliente_parser_resultado
usuario_pode_importar_mesa_json_admin
importar_mesa_cliente_json_admin
importar_mesa_cliente_disponibilidade_oficial
salvar_mesa_cliente_enriquecimento
mesa_cliente_obter_simulacao_fluxo_historico
mesa_cliente_listar_operacoes_financeiras_admin
mesa_cliente_obter_operacao_financeira_admin
mesa_cliente_resumir_operacao_financeira_admin
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_aplicar_operacao_financeira_admin
```

Status:

```text
CONFIRMADO_NO_CODIGO_FRONTEND
NAO_COMPROVADO_NO_SUPABASE_REAL
```

### 8.2 RPCs/functions lidas diretamente em migrations

| RPC/function | Arquivo | Tipo | Risco | Status |
|---|---|---|---:|---|
| `mesa_cliente_financeiro_assert_integridade` | hardening | trigger/function integridade | P0/P1 | GitHub apenas |
| `mesa_cliente_persistir_agenda_financeira_admin` | Fase 4B | escrita controlada/admin | P0/P1 | GitHub apenas |
| `mesa_cliente_obter_agenda_financeira_cliente_safe` | Fase 4C | leitura cliente-safe | P0/P1 | GitHub apenas |
| `mesa_cliente_listar_operacoes_financeiras_admin` | Fase 5D | read-only admin | P1/P0 | GitHub apenas |
| `mesa_cliente_aplicar_operacao_financeira_admin` | Fase 7 | escrita/aplicacao financeira | P0 | GitHub apenas |

---

## 9. Evidencias por fluxo critico

### 9.1 Persistencia de agenda financeira - Fase 4B

A migration 4B cria `mesa_cliente_agendas_financeiras`, habilita e forca RLS, revoga anon, revoga insert/update/delete de authenticated, concede select para authenticated e cria a RPC `mesa_cliente_persistir_agenda_financeira_admin` como `security definer`.

A RPC valida auth.uid, corretor ativo, simulacao, empreendimento, empresa, perfil e bloqueia divergencia de `empresa_id` enviada em payload de tabela. Tambem usa lock transacional, checksum de idempotencia e bloqueio de substituicao quando existe operacao confirmada.

Classificacao:

```text
POSITIVO_GITHUB / PENDENTE_SUPABASE_REAL / P0_P1
```

### 9.2 Cliente-safe - Fase 4C

A migration 4C cria RPC read-only cliente-safe para agenda financeira persistida. O comentario declara que a RPC nao aceita empresa_id do frontend como autoridade, resolve tenant pelo banco, exige auth.uid, usuario/corretor ativo, valida simulacao/empreendimento/agenda ativa, bloqueia anon e nao deve expor checksum, metadata bruta, payload_origem, VPL, premio, comissao, politica, taxas internas ou campos de auditoria.

Classificacao:

```text
POSITIVO_GITHUB / DEPENDENTE_PAYLOAD_REAL / P0_P1
```

Pendencia critica:

```text
Validar no Supabase real a assinatura, body, grants e payload retornado pela RPC cliente-safe.
```

### 9.3 Operacoes financeiras admin - Fase 5D

A migration 5D cria RPCs administrativas read-only para listar/obter operacoes financeiras. O arquivo declara explicitamente read-only absoluto, sem alterar agenda, parcelas, recalculo, confirmacao/cancelamento ou exposicao automatica ao cliente.

Tambem define chaves proibidas vindas do frontend, incluindo empresa_id, tenant_id, corretor_id, user_id, auth_uid, role, perfil, flags admin, metadata, status_forcado e cliente_safe.

Classificacao:

```text
POSITIVO_GITHUB / DEPENDENTE_SUPABASE_REAL / P1_P0
```

### 9.4 Aplicacao de operacao financeira - Fase 7

A migration Fase 7 versiona `mesa_cliente_aplicar_operacao_financeira_admin`. O comentario declara `SECURITY DEFINER`, search_path controlado, bloqueio de autoridade do frontend, exigencia de auth.uid, perfil administrativo, tenant/empresa e status confirmada, e DML financeiro controlado.

O body observado rejeita parametros proibidos, valida corretor ativo, perfil admin, cross-tenant, status da operacao, agenda ativa, simulacao, parcela origem e estado financeiro antes de aplicar DML.

Classificacao:

```text
POSITIVO_GITHUB / P0 / PENDENTE_SUPABASE_REAL
```

---

## 10. Grants e anon

Evidencia positiva em migrations:

```text
- hardening revoga acesso de anon nas tabelas financeiras.
- hardening revoga insert/update/delete de authenticated nas tabelas financeiras.
- Fase 4B revoga all de public/anon na agenda financeira e revoga insert/update/delete de authenticated.
- docs transversais exigem bloquear anon em RPC sensivel.
```

Pendencia:

```text
Nao foi consultado information_schema.routine_privileges no Supabase real.
Nao foi confirmado EXECUTE real das RPCs para anon/authenticated/service_role.
Nao foi confirmado se alguma migration posterior reabriu permissao indevida.
```

Status:

```text
PENDENTE_GRANTS_REAIS
```

---

## 11. RLS e policies

Evidencia positiva em migrations:

```text
- hardening habilita RLS nas tabelas financeiras.
- Fase 4B habilita e forca RLS em `mesa_cliente_agendas_financeiras`.
- policies usam auth.uid(), public.is_root(), public.my_empresa_id() ou corretor ativo/empresa.
- policies de DML direto usam false para insert/update/delete em tabelas financeiras.
```

Pendencia:

```text
Nao foi consultado pg_tables.rowsecurity no Supabase real.
Nao foi consultado pg_policies no Supabase real.
Nao foi confirmado FORCE RLS real por tabela.
Nao foi confirmado se policies no banco real batem com GitHub.
```

Status:

```text
PENDENTE_RLS_REAL
```

---

## 12. Drifts e riscos identificados

| Risco | Severidade | Evidencia | Bloqueio |
|---|---:|---|---|
| Supabase real divergir das migrations do GitHub | P0 | Estado aplicado nao consultado. | Bloqueia implementacao. |
| RPC sensivel com EXECUTE para anon | P0 | Docs exigem bloqueio; grants reais nao consultados. | Bloqueia producao. |
| Frontend enviar empresa_id/tenant_id e RPC aceitar como autoridade | P0 | Codigo PR #53 envia IDs; migrations tentam bloquear. | Exige validacao real. |
| Cliente-safe vazar campos internos | P0 | Fase 4C declara bloqueios, payload real nao testado. | Bloqueia exposicao cliente. |
| RLS/policies nao aplicadas ou driftadas | P0 | Migrations positivas, banco real nao consultado. | Bloqueia escrita/leitura sensivel. |
| RPC de aplicacao financeira com DML real divergente | P0 | Fase 7 e critica financeira. | Bloqueia operacao financeira. |
| Migrations duplicadas/cronologia confusa | P1 | Muitas fases 4A-20D, fixes e hardening. | Exige matriz migration -> funcao -> estado real. |
| Testes existentes nao executados nesta auditoria | P1 | Tests encontrados em `supabase/tests` e `scripts/tests`. | Exige proxima validacao. |

---

## 13. Queries read-only obrigatorias para Supabase real

Estas queries devem ser executadas em etapa segura/read-only antes de qualquer correcao.

### 13.1 Functions/RPCs

```sql
select n.nspname as schema,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args,
       pg_get_function_result(p.oid) as result,
       p.prosecdef as security_definer,
       p.provolatile as volatility,
       pg_get_userbyid(p.proowner) as owner
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and (
    p.proname ilike '%mesa%'
    or p.proname ilike '%agenda%'
    or p.proname ilike '%operacao%'
    or p.proname ilike '%fluxo%'
  )
order by n.nspname, p.proname;
```

### 13.2 Grants de routines

```sql
select routine_schema, routine_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_name ilike '%mesa%'
   or routine_name ilike '%agenda%'
   or routine_name ilike '%operacao%'
   or routine_name ilike '%fluxo%'
order by routine_schema, routine_name, grantee;
```

### 13.3 Tabelas e RLS

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%'
   or tablename ilike '%fluxo%'
order by schemaname, tablename;
```

### 13.4 Policies

```sql
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%'
   or tablename ilike '%fluxo%'
order by schemaname, tablename, policyname;
```

### 13.5 Grants de tabelas

```sql
select table_schema, table_name, grantee, privilege_type
from information_schema.table_privileges
where table_name ilike '%mesa%'
   or table_name ilike '%agenda%'
   or table_name ilike '%operacao%'
   or table_name ilike '%fluxo%'
order by table_schema, table_name, grantee, privilege_type;
```

### 13.6 Migrations aplicadas

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

## 14. Matriz minima de reconciliacao futura

A proxima etapa deve gerar a matriz:

```text
Migration GitHub
-> function/tabela/policy/grant declarada
-> existe no Supabase real?
-> assinatura real bate?
-> body real bate?
-> grants reais batem?
-> RLS real bate?
-> policies reais batem?
-> testes positivos/negativos existem?
-> status final: OK / DRIFT / AUSENTE / OBSOLETO / BLOQUEADO
```

---

## 15. Bloqueios antes de implementacao

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

Qualquer correcao futura deve ser PR separada, com autorizacao explicita, rollback e teste negativo.

---

## 16. Parecer final

```text
Status PR #54: AS_IS_SUPABASE_GITHUB / PENDENTE_RECONCILIACAO_SUPABASE_REAL
Tipo: documentacao-only / read-only
Implementacao autorizada: nao
Risco global: P0/P1
Evidencia positiva: migrations e docs indicam hardening, RLS, grants restritivos, security definer e bloqueio de autoridade frontend.
Bloqueio principal: Supabase real nao foi consultado.
Proxima etapa: validar PR #54 com GPT 3, GPT 0 e GPT 8; depois executar inventario read-only no Supabase real, se autorizado.
```
