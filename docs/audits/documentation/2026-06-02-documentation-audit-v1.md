# FECH.AI — Documento de Auditoria Documental v1

**Classificação:** OFICIAL_CANDIDATO / PENDENTE_RECONCILIACAO  
**Data:** 2026-06-02  
**Finalidade:** preparar validação documental antes de qualquer implementação.  
**Regra central:** este documento não autoriza implementação, alteração de código, banco, Supabase, RPC, RLS, Vercel, GitHub, MesaCliente, LeadOps ou ADS/CAPI.

---

## 1. Objetivo da auditoria

Validar a documentação atual do FECH.AI antes de qualquer alteração estrutural, técnica ou operacional.

A auditoria deve responder, com evidência:

- o que existe apenas como documentação;
- o que existe no código real;
- o que existe no Supabase real;
- o que está em rascunho;
- o que está obsoleto;
- o que está conflitante;
- o que depende de reconciliação;
- o que pode orientar implementação futura;
- o que ainda não pode ser tratado como verdade aplicada.

Estado atual conhecido: há documentação inicial relevante sobre arquitetura, tabelas, RPCs/functions, LGPD, roadmap, módulos, skills e branches. Parte desses documentos declara explicitamente status de rascunho ou pendência de reconciliação com Supabase real.

Direção futura: usar esta auditoria como etapa anterior a qualquer plano de implementação, PR, migration, alteração de RLS, RPC, MesaCliente, LeadOps, ADS/CAPI, Vercel ou GitHub.

---

## 2. Escopo da auditoria

| Domínio | Escopo |
|---|---|
| M0 | Documentação, governança, status documental, rastreabilidade |
| M1 | LeadOps, CRM, Listas, Discador, PME |
| M2 | ADS, Pixel, CAPI, Stape, CRM-to-Ads |
| M3 | MesaCliente, Tabelas, Propostas, motor financeiro |
| M4 | Integrações, Portais, Mensageria |
| M5 | Dashboards, Observabilidade, Operação |
| M6 | Monetização, planos, GTM |
| M7 | Supabase, Auth, RLS, RPCs, grants, policies |
| M8 | Vercel, GitHub, CI/CD, branches, PRs |
| M9 | Segurança, LGPD, DevSecOps, segredos, logs |

Fora do escopo deste documento:

- implementação;
- criação de migrations;
- alteração de policies;
- alteração de RPCs;
- alteração de código;
- deploy;
- refatoração;
- mudança de arquitetura;
- decisão final de produção.

---

## 3. Documentos que precisam ser verificados

| Documento | Status declarado/conhecido | Classificação preliminar |
|---|---|---|
| `docs/README.md` | documentação de referência/rascunho profissional | RASCUNHO / OFICIAL_CANDIDATO |
| `docs/02-arquitetura-tecnica/arquitetura-atual.md` | arquitetura atual, pendente de validação aplicada | OFICIAL_CANDIDATO |
| `docs/04-banco-de-dados/mapa-tabelas.md` | rascunho / pendente de reconciliação com Supabase real | PENDENTE_RECONCILIACAO |
| `docs/04-banco-de-dados/rpcs-e-functions.md` | rascunho / pendente de reconciliação com Supabase real | PENDENTE_RECONCILIACAO |
| `docs/06-seguranca-compliance/lgpd.md` | rascunho / pendente de validação jurídica | RASCUNHO / PENDENTE_RECONCILIACAO |
| `docs/security/SECURITY_AUDIT_2026-05-29.md` | auditoria de segurança registrada | EVIDENCIA_VALIDACAO / PENDENTE_RECONCILIACAO |
| `docs/skills/fechai-gpt-registry.md` | versão vigente no repositório, a validar na branch `main` | OFICIAL_CANDIDATO |
| `docs/product/fechai-modules-map-v1.md` | mapa inicial dos módulos | OFICIAL_CANDIDATO |
| `docs/roadmap/fechai-roadmap-master-v1.md` | roadmap inicial de produto | OFICIAL_CANDIDATO |

Observação: documentos que declaram explicitamente pendência de reconciliação não podem ser usados como prova de estado aplicado. Eles orientam a auditoria, mas não substituem validação contra código real e Supabase real.

---

## 4. Arquivos de código que precisam ser verificados

Nenhum código real é alterado por este documento. Os arquivos abaixo devem ser verificados em etapa posterior de auditoria read-only.

| Arquivo/caminho | Motivo da verificação |
|---|---|
| `src/lib/supabaseClient.js` | verificar env vars, hardcoded keys e configuração do client Supabase |
| `src/App.jsx` | verificar chamadas diretas ao Supabase, responsabilidades acumuladas e fluxos sensíveis |
| `src/main.jsx` | verificar bootstrap, imports globais, scripts externos e patches |
| `src/**/*.js` / `src/**/*.jsx` | buscar `supabase.from`, `supabase.rpc`, `service_role`, anon keys, JWTs e secrets |
| `src/services/**/*` | verificar clients, integrações e operações sensíveis |
| `src/hooks/**/*` | verificar chamadas diretas ao banco e decisões de permissão no frontend |
| `src/components/**/*` | verificar exposição de dados sensíveis e payloads client-safe |
| `public/*.js` | verificar scripts globais, patches e risco de interceptação |
| `.env.example` | verificar padrão esperado de variáveis públicas e segredos |
| `vite.config.*` | verificar exposição indevida de envs |
| `supabase/migrations/*` | reconciliar schema documentado com migrations versionadas |
| `supabase/functions/*` | verificar Edge Functions, segredos, CORS, JWT e service role |
| `package.json` | verificar dependências e scripts de build/test/lint |
| `.github/workflows/*` | verificar CI/CD, checks e proteção de deploy |
| `vercel.json` | verificar roteamento, headers e build settings |

Buscas obrigatórias no código:

```text
SUPABASE_ANON_KEY
VITE_SUPABASE_ANON_KEY
service_role
supabase.from(
supabase.rpc(
auth.uid
tenant_id
empresa_id
perfil
permissao
window.fetch
```

---

## 5. Evidências necessárias no Supabase real

Nenhuma evidência do Supabase real é alterada por este documento. A etapa posterior deve coletar, de forma read-only:

| Categoria | Evidência exigida |
|---|---|
| Tabelas | lista real de tabelas por schema |
| Colunas | tipos, defaults, nullable, constraints |
| Chaves | PKs, FKs, unique constraints |
| Índices | índices existentes e finalidade |
| RLS | RLS ativo/inativo por tabela |
| Policies | policies reais por tabela, comando e role |
| Grants | permissões para `anon`, `authenticated` e roles internas |
| RPCs/functions | assinatura, retorno, owner, grants, security definer/invoker |
| Extensões | extensões habilitadas no banco |
| Auth | relação entre `auth.users` e tabelas de perfil/corretores |
| Storage | buckets, policies e acesso público/privado |
| Logs | logs de autenticação, banco, Edge Functions e API |
| Segredos | confirmar ausência de service role exposta fora de ambiente seguro |
| Backups | política real de backup/restore |
| Ambientes | separar produção, preview e desenvolvimento |

---

## 6. Queries Supabase read-only necessárias

As queries abaixo são apenas para inventário e reconciliação. Não devem alterar dados.

### 6.1 Schemas e tabelas

```sql
select table_schema, table_name, table_type
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name;
```

### 6.2 Colunas

```sql
select table_schema, table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name, ordinal_position;
```

### 6.3 RLS por tabela

```sql
select schemaname, tablename, rowsecurity, forcerowsecurity
from pg_tables
where schemaname not in ('pg_catalog', 'information_schema')
order by schemaname, tablename;
```

### 6.4 Policies

```sql
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
order by schemaname, tablename, policyname;
```

### 6.5 Grants de tabelas

```sql
select table_schema, table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name, grantee, privilege_type;
```

### 6.6 Functions/RPCs

```sql
select n.nspname as schema, p.proname as function_name,
       pg_get_function_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as result,
       p.prosecdef as security_definer,
       p.provolatile as volatility,
       r.rolname as owner
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where n.nspname not in ('pg_catalog', 'information_schema')
order by n.nspname, p.proname;
```

### 6.7 Grants de execução em functions

```sql
select n.nspname as schema, p.proname as function_name, r.rolname as grantee,
       has_function_privilege(r.rolname, p.oid, 'EXECUTE') as can_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
cross join pg_roles r
where n.nspname not in ('pg_catalog', 'information_schema')
  and r.rolname in ('anon', 'authenticated', 'service_role')
order by n.nspname, p.proname, r.rolname;
```

### 6.8 Definição de functions críticas

```sql
select n.nspname as schema, p.proname as function_name,
       pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
order by n.nspname, p.proname;
```

### 6.9 Constraints

```sql
select tc.table_schema, tc.table_name, tc.constraint_name, tc.constraint_type,
       kcu.column_name, ccu.table_schema as foreign_table_schema,
       ccu.table_name as foreign_table_name, ccu.column_name as foreign_column_name
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
left join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name and ccu.table_schema = tc.table_schema
where tc.table_schema not in ('pg_catalog', 'information_schema')
order by tc.table_schema, tc.table_name, tc.constraint_type, tc.constraint_name;
```

---

## 7. PRs e branches que precisam ser verificadas

Referências citadas em documentação/conversas devem ser tratadas como **REFERÊNCIA A VALIDAR NO GITHUB REAL** até inspeção direta.

Exemplos de validação necessária:

- branch `main` vigente;
- PRs abertas;
- PRs de documentação já mergeadas;
- branches de baseline, se existirem;
- histórico de commits relacionados a segurança, Supabase, MesaCliente, LeadOps e ADS/CAPI.

---

## 8. Matriz de risco P0/P1/P2/P3

| Risco | Classificação inicial | Critério |
|---|---|---|
| `service_role` exposta em frontend, logs ou repositório | P0 | vazamento crítico |
| RLS ausente em tabela multi-tenant sensível | P0 | risco cross-tenant |
| RPC sensível executável por `anon` sem validação interna | P0 | risco de acesso indevido |
| Frontend como autoridade de `tenant_id`, `empresa_id`, perfil ou permissão | P0/P1 | depende do fluxo |
| Anon key hardcoded no código | P1 | drift de governança; não equivale a service_role |
| App.jsx concentrando múltiplas responsabilidades | P1 | risco de manutenção |
| Docs de banco/RPC sem reconciliação com Supabase real | P1 | risco de implementação baseada em premissa |
| Ausência de pipeline global de lint/test/security | P1/P2 | risco operacional |
| Documentação obsoleta ou conflitante | P2 | risco de decisão errada |

---

## 9. Critérios para afirmar que anon keys hardcoded foram eliminadas

Só afirmar após verificar:

- `src/lib/supabaseClient.js`;
- `src/App.jsx`;
- `src/main.jsx`;
- `src/services/**/*`;
- `src/hooks/**/*`;
- `public/**/*`;
- `.env.example`;
- `vite.config.*`;
- buscas por `SUPABASE_ANON_KEY`, `VITE_SUPABASE_ANON_KEY`, `service_role` e padrões JWT.

Critério técnico:

- `service_role` nunca pode aparecer em frontend, logs, bundle, repositório público ou variável pública;
- anon key não é service_role e pode existir em app público com RLS correto, mas se a decisão do projeto exige configuração por ambiente, anon key hardcoded deve ser classificada como drift de governança/segurança.

---

## 10. Critérios para afirmar que operações críticas passam por RPC segura

Só afirmar após verificar:

- chamadas `supabase.from(...).insert/update/delete/select` em fluxos sensíveis;
- chamadas `supabase.rpc(...)`;
- definições reais das RPCs no Supabase;
- grants para `anon` e `authenticated`;
- RLS ativa;
- policies reais;
- validação de `auth.uid()`, `tenant_id`, `empresa_id`, perfil e permissão dentro do banco/RPC;
- inexistência de autoridade soberana vinda apenas do frontend.

Critério mínimo:

- frontend pode solicitar ação;
- banco/RPC deve validar autorização, vínculo multi-tenant e regra crítica;
- logs não devem expor PII ou segredos;
- operações sensíveis devem ser idempotentes ou auditáveis quando aplicável.

---

## 11. Classificação documental oficial

| Classificação | Uso |
|---|---|
| OFICIAL_VIGENTE | documento aprovado e aderente ao estado atual ou decisão oficial |
| OFICIAL_CANDIDATO | correto, mas pendente de validação contra código/Supabase |
| RASCUNHO | preliminar, não orienta implementação sozinho |
| PROPOSTA | plano ou ideia ainda não aprovado/aplicado |
| CHECKPOINT | versão ou marco usado como referência/rollback |
| CHANGELOG | registro histórico de alteração |
| EVIDENCIA_VALIDACAO | prova de teste, auditoria ou aplicação real |
| OBSOLETO | substituído ou sem aderência à decisão atual |
| CONFLITANTE | contradiz documento, código, Supabase ou decisão atual |
| PENDENTE_RECONCILIACAO | precisa validar contra código, banco, PR, RLS, RPC ou Supabase real |
| DRIFT_A_VALIDAR | indício de divergência que exige evidência |

---

## 12. Próximos passos sem implementação

1. Criar inventário documental completo.
2. Classificar todos os documentos por domínio e status.
3. Executar varredura read-only no código.
4. Executar inventário read-only no Supabase real.
5. Criar matriz docs x código x Supabase.
6. Listar conflitos e drifts.
7. Criar backlog P0/P1/P2/P3.
8. Só depois acionar GPT 1 e especialistas de domínio para decidir implementação.

---

## 13. O que não deve ser implementado ainda

Não implementar ainda:

- migration;
- alteração de RLS;
- grants;
- RPC;
- Supabase Functions;
- Vercel env;
- deploy;
- refatoração de `App.jsx`;
- correção de anon key;
- mudança no MesaCliente;
- mudança no LeadOps;
- mudança no ADS/CAPI.

Antes disso, concluir a auditoria documental e a reconciliação com código e Supabase real.
