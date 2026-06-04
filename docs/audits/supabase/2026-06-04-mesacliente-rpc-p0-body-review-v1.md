# FECH.AI - Body review das RPCs P0 MesaCliente v1

**Data:** 2026-06-04
**Status:** `BODY_REVIEW_READONLY / PENDENTE_TESTES_NEGATIVOS`
**Base:** PR #56 - matriz de risco Supabase real MesaCliente por RPC/tabela
**Projeto Supabase:** `Discador-MesaCliente`
**Project ref:** `uobxxgzshrmbtjfdolxd`
**Tipo:** documentacao-only / read-only evidence.

Nota editorial: arquivo normalizado em ASCII para remover risco de caracteres ocultos ou bidirecionais no Markdown.

---

## 1. Objetivo

Revisar, em modo read-only, os bodies reais das RPCs classificadas como P0/P1 na PR #56 por combinarem anon/PUBLIC EXECUTE, SECURITY DEFINER, indicio de escrita e impacto em proposta, disponibilidade, politica financeira, desconto, premio, upload ou enriquecimento de unidade.

Esta PR nao corrige nada. Ela nao altera banco, schema, RLS, FORCE RLS, policies, grants, functions, migrations, parser, motor financeiro, frontend, Vercel, GitHub Actions, Worker, Make/n8n, integracoes reais ou producao.

---

## 2. Escopo executado

Consulta read-only no Supabase real para as RPCs:

```text
aprovar_rejeitar_mesa
importar_mesa_cliente_disponibilidade_oficial
mesa_cliente_upsert_faixas_premio
mesa_cliente_upsert_politica_financeira
registrar_upload_arquivo_mesa
salvar_mesa_cliente_desconto_politica
salvar_mesa_cliente_enriquecimento
```

Foram coletados:

```text
assinatura
security_definer
owner
search_path/function_config
grantees
anon/PUBLIC/authenticated execute
uso textual de auth.uid()
uso de is_gestor()
uso de mesa_cliente_assert_auth()
uso de mesa_cliente_can_admin_empresa()
uso de is_root()
indicio de insert/update/delete
tabelas tocadas por indicio textual
hash md5 do body
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

## 3. Limites desta auditoria

Esta PR registra body review por blocos e flags. Ela nao publica dump completo dos bodies no Markdown, para reduzir ruido e evitar transformar a auditoria em arquivo de codigo operacional.

Nao foi feito:

```text
correcao de grants
correcao de RLS/FORCE RLS
correcao de policies
alteracao de function body
migration
teste anon real
teste authenticated sem permissao
teste cross-tenant
teste payload cliente-safe
teste de rollback
```

---

## 4. Rastreabilidade dos bodies revisados

Hashes md5 coletados via `md5(pg_get_functiondef(oid))` no Supabase real, apenas para rastreabilidade documental da versao do body revisada.

| RPC | Hash md5 do body |
|---|---|
| `aprovar_rejeitar_mesa` | `286f9e6aea5ec792eb45a337db742bd1` |
| `importar_mesa_cliente_disponibilidade_oficial` | `292d981623bb6e63c7d0dc954fa282bb` |
| `mesa_cliente_upsert_faixas_premio` | `8251e49fad7d4dc960f33dce255886e8` |
| `mesa_cliente_upsert_politica_financeira` | `acbe4ee582decc5837743e3e6db78bd0` |
| `registrar_upload_arquivo_mesa` | `525ac1f3013e5f6b5d7abc53261d1a13` |
| `salvar_mesa_cliente_desconto_politica` | `6f05f717e8fa7002c3dbe960d8d347fe` |
| `salvar_mesa_cliente_enriquecimento` | `b79e891045c4c0718f949b2ddecfab15` |

Observacao:

```text
Se qualquer hash mudar antes dos testes negativos, os resultados dos testes devem ser vinculados ao novo body/hash e esta auditoria deve ser revalidada.
```

---

## 5. Sumario executivo

| RPC | Exposicao | Guarda observada | Escrita | Impacto | Decisao |
|---|---|---|---:|---|---|
| `aprovar_rejeitar_mesa` | PUBLIC, anon, authenticated | `is_gestor()`, `auth.uid()` | sim | proposta/aprovacao | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |
| `importar_mesa_cliente_disponibilidade_oficial` | anon, authenticated | `auth.uid()`, `is_root()`, corretor/empresa/perfil | sim | disponibilidade oficial | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |
| `mesa_cliente_upsert_faixas_premio` | anon, authenticated | `mesa_cliente_assert_auth()`, `mesa_cliente_can_admin_empresa()` | sim | premio/regra financeira | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |
| `mesa_cliente_upsert_politica_financeira` | anon, authenticated | `mesa_cliente_assert_auth()`, `mesa_cliente_can_admin_empresa()` | sim | VPL/taxas/regra financeira | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |
| `registrar_upload_arquivo_mesa` | anon, authenticated | `auth.uid()`, `is_root()`, corretor/empresa | sim | upload/importacao | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |
| `salvar_mesa_cliente_desconto_politica` | anon, authenticated | `auth.uid()`, `is_root()`, corretor/empresa/tenant | sim | desconto/regra comercial | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |
| `salvar_mesa_cliente_enriquecimento` | anon, authenticated | `auth.uid()`, `is_root()`, corretor/empresa | sim | ficha unidade/proposta | `BLOQUEADO_GRANT_REVIEW_E_TESTES` |

Conclusao:

```text
Os bodies apresentam guardas relevantes em varias RPCs, mas a combinacao de anon/PUBLIC EXECUTE + SECURITY DEFINER + escrita/impacto comercial continua bloqueante ate testes negativos e revisao de grants.
```

---

## 6. Body review por RPC

### 6.1 `aprovar_rejeitar_mesa`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: PUBLIC, anon, authenticated, postgres, service_role
usa auth.uid(): sim
usa is_gestor(): sim
escreve: sim, UPDATE em mesa_simulacoes e INSERT em audit_logs
impacto: proposta/aprovacao/rejeicao
hash md5: 286f9e6aea5ec792eb45a337db742bd1
```

Guarda observada:

```text
- Bloqueia se `is_gestor()` for false.
- Registra auth.uid() no snapshot_payload e audit_logs.
- Valida p_acao somente para aprovar/rejeitar.
```

Lacunas/riscos:

```text
- EXECUTE para PUBLIC e anon continua inadequado para RPC de aprovacao/rejeicao.
- A verificacao de gestor parece delegada a `is_gestor()`, que precisa revisao propria na PR #58/#59.
- Nao foi observado nesta revisao um check explicito de ownership/empresa da simulacao antes do UPDATE, alem da guarda is_gestor().
- UPDATE usa apenas `WHERE id = p_simulacao_id`; precisa teste cross-tenant e role/perfil.
```

Decisao:

```text
P0/R4 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

Testes obrigatorios:

```text
anon deve falhar
authenticated nao gestor deve falhar
gestor de outra empresa deve falhar
gestor da empresa correta deve funcionar somente no escopo permitido
acao invalida deve falhar
simulacao inexistente deve nao alterar nada
```

---

### 6.2 `importar_mesa_cliente_disponibilidade_oficial`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: anon, authenticated, postgres, service_role
usa auth.uid(): sim
usa is_root(): sim
toca corretores/empresa/empreendimento: sim
escreve: sim, INSERT em estoque_arquivos, UPDATE em unidades_estoque e estoque_snapshots
impacto: disponibilidade oficial, tabela de unidades, proposta
hash md5: 292d981623bb6e63c7d0dc954fa282bb
```

Guardas observadas:

```text
- Exige auth.uid() nao nulo.
- Valida empreendimento ativo.
- Resolve empresa do empreendimento no banco.
- Busca corretor ativo por user_id.
- Bloqueia cross-tenant quando nao root.
- Exige perfil/flag de importacao quando nao root.
- Bloqueia tabela vazia e match zero contra snapshot comercial.
```

Lacunas/riscos:

```text
- anon EXECUTE permanece inadequado para RPC de importacao oficial com escrita.
- SECURITY DEFINER grava em estoque e altera disponibilidade oficial.
- Precisa teste negativo anon, cross-tenant, corretor sem perfil e payload com unidades divergentes.
- Precisa validar se root sem corretor e audit_actor cobrem auditoria suficiente.
```

Decisao:

```text
P0/R4 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

Testes obrigatorios:

```text
anon deve falhar por AUTH_REQUIRED
authenticated sem corretor deve falhar
corretor de outra empresa deve falhar
corretor sem permissao deve falhar
payload vazio deve falhar
payload sem match deve falhar sem alterar estoque
usuario autorizado deve alterar somente empreendimento/empresa correta
```

---

### 6.3 `mesa_cliente_upsert_faixas_premio`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: anon, authenticated, postgres, service_role
usa auth.uid() diretamente: nao
usa mesa_cliente_assert_auth(): sim
usa mesa_cliente_can_admin_empresa(): sim
escreve: sim, DELETE/INSERT em mesa_cliente_politica_premio_faixas
impacto: premio/regra financeira
hash md5: 8251e49fad7d4dc960f33dce255886e8
```

Guardas observadas:

```text
- Usa `mesa_cliente_assert_auth()` para exigir autenticacao.
- Usa `mesa_cliente_can_admin_empresa(p_empresa_id)` para autorizacao administrativa.
- Valida politica por empresa.
- Limita quantidade de faixas.
```

Lacunas/riscos:

```text
- anon EXECUTE permanece inadequado em RPC de upsert financeiro, ainda que assert_auth bloqueie na pratica.
- Depende da seguranca de helpers `mesa_cliente_assert_auth` e `mesa_cliente_can_admin_empresa`.
- DELETE seguido de INSERT em faixas de premio exige transacao/teste de integridade.
- Precisa validar ranges, sobreposicao de faixas, valores negativos e payload malformado.
```

Decisao:

```text
P0/R4 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

---

### 6.4 `mesa_cliente_upsert_politica_financeira`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: anon, authenticated, postgres, service_role
usa auth.uid() diretamente: nao
usa mesa_cliente_assert_auth(): sim
usa mesa_cliente_can_admin_empresa(): sim
escreve: sim, INSERT/UPDATE em mesa_cliente_politicas_financeiras
impacto: VPL, taxas, politica financeira, regra comercial
hash md5: acbe4ee582decc5837743e3e6db78bd0
```

Guardas observadas:

```text
- Usa assert_auth e can_admin_empresa.
- Recebe empresa_id e empreendimento_id como parametros, mas deve validar autorizacao pelo helper.
- Persiste politica financeira e flags de permissao por tipo de parcela.
```

Lacunas/riscos:

```text
- anon EXECUTE permanece inadequado para upsert financeiro.
- Depende de helpers de autorizacao.
- Parametros financeiros sensiveis chegam do cliente da RPC e precisam validacao estrita.
- Precisa testes de limites: VPL maximo, taxas negativas, vigencia invalida, empreendimento de outra empresa.
```

Decisao:

```text
P0/R4 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

---

### 6.5 `registrar_upload_arquivo_mesa`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: anon, authenticated, postgres, service_role
usa auth.uid(): sim
usa is_root(): sim
toca corretores: sim
escreve: sim, INSERT de registro de arquivo/upload
impacto: importacao, trilha de arquivo, MesaCliente
hash md5: 525ac1f3013e5f6b5d7abc53261d1a13
```

Guardas observadas:

```text
- Usa auth.uid() e contexto de corretor/empresa.
- Menciona empresa_id recebido por parametro.
- Tem caminho root e nao-root.
```

Lacunas/riscos:

```text
- anon EXECUTE inadequado para registro de upload.
- Precisa validar se empresa_id de parametro e sempre confrontado com empresa do corretor.
- Precisa validar storage_path/nome/tipo para evitar trilha inconsistente.
```

Decisao:

```text
P0/P1 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

---

### 6.6 `salvar_mesa_cliente_desconto_politica`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: anon, authenticated, postgres, service_role
usa auth.uid(): sim
usa is_root(): sim
toca corretores/empresa/tenant: sim
escreve: sim, INSERT/UPDATE em mesa_cliente_desconto_politicas
impacto: desconto, regra comercial, proposta
hash md5: 6f05f717e8fa7002c3dbe960d8d347fe
```

Guardas observadas:

```text
- Usa auth.uid().
- Resolve contexto de corretor/empresa e menciona tenant.
- Deve validar permissao antes de salvar politica de desconto.
```

Lacunas/riscos:

```text
- anon EXECUTE inadequado para politica de desconto.
- Precisa validar regra de maxima permissao, faixas, ativo, vigencia e empreendimento.
- Precisa teste de tentativa cross-tenant e usuario sem perfil.
```

Decisao:

```text
P0/R4 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

---

### 6.7 `salvar_mesa_cliente_enriquecimento`

Metadados:

```text
SECURITY DEFINER: true
owner: postgres
search_path: public
grantees: anon, authenticated, postgres, service_role
usa auth.uid(): sim
usa is_root(): sim
toca corretores/empresa: sim
escreve: sim, INSERT/UPDATE em mesa_cliente_unidade_enriquecimentos
impacto: ficha de unidade, apresentacao, proposta
hash md5: b79e891045c4c0718f949b2ddecfab15
```

Guardas observadas:

```text
- Usa auth.uid().
- Resolve contexto de corretor/empresa.
- Escreve enriquecimento por empreendimento/final.
```

Lacunas/riscos:

```text
- anon EXECUTE inadequado para escrita de enriquecimento de unidade.
- Tabela relacionada ja foi marcada como BLOQUEADO_POLICY_REVIEW por authenticated DML e policy_count=0 no levantamento.
- Precisa validar uniqueness, overwrite, empresa/empreendimento e permissao.
```

Decisao:

```text
P1/R3-R4 - BLOQUEADO_GRANT_REVIEW_E_TESTES
```

---

## 7. Achados transversais

### 7.1 anon/PUBLIC EXECUTE

```text
Todas as RPCs revisadas possuem anon EXECUTE; aprovar_rejeitar_mesa tambem possui PUBLIC EXECUTE.
Mesmo quando o body possui guardas, a exposicao externa continua pendente de grant review e testes negativos.
```

### 7.2 SECURITY DEFINER

```text
Todas as RPCs revisadas sao SECURITY DEFINER com owner postgres e search_path=public.
Isso exige revisao de search_path, chamadas auxiliares e parametros para reduzir risco de bypass.
```

### 7.3 Helpers de autorizacao

```text
Algumas RPCs dependem de helpers como is_gestor(), is_root(), mesa_cliente_assert_auth() e mesa_cliente_can_admin_empresa().
Esses helpers precisam entrar na reconciliacao de PR futura, porque a seguranca efetiva depende deles.
```

### 7.4 Escrita e impacto comercial

```text
As 7 RPCs revisadas apresentam indicio de escrita.
Os impactos cobrem aprovacao/rejeicao de proposta, disponibilidade oficial, upload/importacao, politica financeira, premio, desconto e enriquecimento de unidade.
```

---

## 8. Bloqueios antes de qualquer correcao/implementacao

```text
1. Teste anon para cada RPC revisada.
2. Teste authenticated sem corretor/empresa.
3. Teste cross-tenant.
4. Teste perfil insuficiente.
5. Teste admin/gestor empresa correta.
6. Revisao dos helpers de autorizacao.
7. Validacao de search_path/SECURITY DEFINER.
8. Decisao de grants: anon/PUBLIC deve permanecer ou ser revogado em PR futura.
9. Rollback SQL planejado antes de qualquer alteracao.
10. Evidencia de que cliente-safe nao vaza dados internos.
```

---

## 9. Proxima etapa recomendada

```text
PR #58 - Plano de testes negativos Supabase MesaCliente
```

A PR #58 deve especificar os testes sem necessariamente executa-los em producao:

```text
anon
authenticated sem empresa
authenticated de outra empresa/tenant
corretor sem perfil
admin empresa correta
root/admin global
payload invalido
payload cross-tenant
cliente-safe payload
```

---

## 10. Parecer final

```text
Status: BODY_REVIEW_READONLY / PENDENTE_TESTES_NEGATIVOS
Tipo: documentacao-only / read-only evidence
Implementacao autorizada: NAO
Correcao autorizada: NAO
Risco global: P0/P1
Conclusao: os bodies indicam guardas relevantes, mas a exposicao anon/PUBLIC + SECURITY DEFINER + escrita/impacto comercial continua bloqueante ate grant review e testes negativos.
Proxima etapa: plano de testes negativos antes de qualquer PR de correcao.
```
