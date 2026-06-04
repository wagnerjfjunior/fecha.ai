# FECH.AI - Plano de testes negativos Supabase MesaCliente v1

**Data:** 2026-06-04
**Status:** `PLANO_NAO_EXECUTADO / TEST_PLAN_ONLY`
**Base:** PR #57 - body review das RPCs P0 MesaCliente
**Projeto Supabase de referencia:** `Discador-MesaCliente`
**Project ref:** `uobxxgzshrmbtjfdolxd`
**Tipo:** documentacao-only / test-plan-only.

Nota editorial: arquivo em ASCII para evitar caracteres ocultos ou bidirecionais.

---

## 1. Objetivo

Documentar o plano de testes negativos das RPCs P0/P1 do MesaCliente antes de qualquer correcao real.

Esta PR cria um plano. Ela nao executa testes, nao valida seguranca final e nao prova que o ambiente esta protegido.

```text
Status: PLANO - NAO EXECUTADO
Implementacao autorizada: NAO
Correcao autorizada: NAO
Execucao de testes autorizada: NAO
```

---

## 2. Escopo proibido

Esta PR nao altera:

```text
Supabase real
schema
RLS
FORCE RLS
grants
policies
RPCs/functions
migrations
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

Tambem nao contem:

```text
SQL de correcao
REVOKE
GRANT
ALTER FUNCTION
ALTER POLICY
ALTER TABLE
migration
payload real de cliente
token
JWT
service_role key
prints de producao
```

---

## 3. RPCs no escopo

As 7 RPCs abaixo foram herdadas da PR #57 e continuam classificadas como R4, por combinarem SECURITY DEFINER, escrita, impacto MesaCliente/comercial/financeiro e exposicao por anon EXECUTE. `aprovar_rejeitar_mesa` e R4 critico por tambem possuir PUBLIC EXECUTE.

| RPC | Classificacao | Motivo |
|---|---:|---|
| `aprovar_rejeitar_mesa` | R4 critico | Escrita/decisao comercial, anon EXECUTE, PUBLIC EXECUTE, SECURITY DEFINER, impacto em aprovacao/rejeicao. |
| `importar_mesa_cliente_disponibilidade_oficial` | R4 | Escrita/importacao de disponibilidade oficial e risco cross-tenant. |
| `mesa_cliente_upsert_faixas_premio` | R4 | Escrita de remuneracao/faixas de premio e dado comercial interno. |
| `mesa_cliente_upsert_politica_financeira` | R4 | Escrita de politica financeira, VPL/taxas e impacto direto em proposta. |
| `registrar_upload_arquivo_mesa` | R4 | Escrita de metadados/payload de arquivo e risco de arquivo cross-tenant. |
| `salvar_mesa_cliente_desconto_politica` | R4 | Escrita de politica de desconto e impacto comercial/financeiro. |
| `salvar_mesa_cliente_enriquecimento` | R4 | Escrita/enriquecimento de dados de unidade/proposta. |

---

## 4. Ambiente e seguranca operacional para execucao futura

A execucao futura dos testes deve ocorrer preferencialmente em staging, clone ou snapshot, com dataset sintetico. Producao nao deve ser laboratorio.

### 4.1 Go/No-Go de ambiente

| Item | Criterio |
|---|---|
| Producao | NO-GO para teste destrutivo ou escrita. Permitido somente inventario read-only de metadata. |
| Staging/clone | GO se possuir snapshot, dataset sintetico e tenant A/B. |
| Dataset | Deve usar prefixos como `TEST_PR58_*`. |
| Dados reais | Proibido usar CPF, telefone, e-mail, lead, cliente ou proposta real. |
| Service role | Proibido em teste manual. |
| Evidencia | Sem JWT, token, cookie, Authorization header, PII ou segredo. |
| Rollback | Snapshot/backup e plano de limpeza obrigatorios antes de qualquer teste com escrita autorizada futura. |

### 4.2 Massa minima de teste futura

```text
Tenant/Empresa A de teste
Tenant/Empresa B de teste
usuario anon/sem sessao
usuario autenticado sem corretor
corretor ativo Tenant A
corretor inativo Tenant A
corretor ativo Tenant B
gestor/admin local Tenant A
root/admin global, se existir regra formal
empreendimento TEST_PR58_A
empreendimento TEST_PR58_B
unidade TEST_PR58_A
unidade TEST_PR58_B
simulacao/proposta TEST_PR58_A
simulacao/proposta TEST_PR58_B
politica financeira TEST_PR58_A
politica financeira TEST_PR58_B
disponibilidade oficial TEST_PR58_A
disponibilidade oficial TEST_PR58_B
arquivo/upload sintetico TEST_PR58_A
```

---

## 5. Matriz base de cenarios negativos

Esta matriz deve ser aplicada a cada uma das 7 RPCs, ajustando o payload conforme assinatura real levantada na PR #57.

| ID | Cenario | Papel usado | Pre-condicao | Resultado esperado | Evidencia esperada | Bloqueante |
|---|---|---|---|---|---|---|
| N01 | anon sem JWT | Sem sessao / anon key | Chamada sem `Authorization: Bearer <jwt>` | RPC deve falhar por ausencia de autenticacao/autorizacao | Erro esperado; diff zero | Sim |
| N02 | authenticated sem corretor | Usuario Auth valido sem vinculo operacional | JWT valido sem linha em corretores/equivalente | RPC deve falhar | Erro esperado; diff zero | Sim |
| N03 | corretor inativo | Usuario com vinculo inativo | Registro existe com ativo=false/status equivalente | RPC deve falhar | Erro esperado; diff zero | Sim |
| N04 | authenticated sem empresa | Usuario ativo sem empresa/tenant valido | Sem vinculo empresarial valido | RPC deve falhar | Erro esperado; diff zero | Sim |
| N05 | outra empresa/tenant | Usuario Empresa B operando recurso da Empresa A | IDs reais sinteticos de tenants distintos | RPC deve falhar | Nenhuma alteracao na Empresa A | Sim |
| N06 | corretor sem perfil/permissao | Corretor ativo sem permissao especifica | Empresa correta, perfil insuficiente | RPC deve falhar | Erro esperado; diff zero | Sim |
| N07 | gestor/admin da empresa correta | Gestor/admin local autorizado | Recurso pertence ao mesmo tenant | Controle positivo futuro, quando aplicavel | Sucesso restrito e auditado | Sim |
| N08 | root/admin global | Admin global/suporte interno, se formal | Papel global validado no banco | Deve passar apenas se regra permitir | Sucesso ou bloqueio documentado e auditavel | Sim |
| N09 | payload invalido | Papel autorizado ou nao | Campos ausentes, tipos errados, enum invalido, valores negativos/extremos | Falha antes de escrever | Erro de validacao; diff zero | Sim |
| N10 | payload cross-tenant | Usuario Empresa A enviando resource_id da Empresa B | Payload tenta forcar tenant/empresa | RPC deve falhar | Diff zero na Empresa B | Sim |
| N11 | IDs inexistentes | Papel autenticado | IDs sintaticamente validos, mas inexistentes | Falha segura | Erro sem vazamento sensivel | Sim |
| N12 | escrita fora do escopo | Papel com permissao parcial | Tenta alterar recurso de outro empreendimento/proposta/politica/mesa | RPC deve falhar | Diff zero fora do escopo | Sim |
| N13 | no-write-on-failure | Qualquer cenario negativo | Snapshot antes/depois planejado | Nenhuma tabela de negocio deve mudar | Hash/contagem/read-only antes/depois | Sim |
| N14 | erro esperado | Qualquer cenario negativo | Contrato de erro definido | Erro previsivel, sem stack trace sensivel | Codigo/mensagem sanitizada | Sim |
| N15 | audit log quando aplicavel | Tentativa sensivel | Audit/event log existe | Sucesso deve auditar; falha sensivel pode auditar sem payload sensivel | Actor, acao, recurso, tenant, resultado | Sim |

---

## 6. Plano por RPC

### 6.1 `aprovar_rejeitar_mesa`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que aprovacao/rejeicao so ocorra por papel autorizado da empresa/tenant correto. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N01, N05, N06, N10, N12, N13. |
| Papeis | anon, authenticated sem corretor, corretor inativo, sem empresa, outro tenant, sem permissao, gestor/admin correto, root se formal. |
| Pre-condicao | Mesa/proposta sintetica com status conhecido; usuarios A/B; snapshot antes/depois. |
| Payload minimo | `{ mesa_id, acao: "aprovar" }` ou `{ mesa_id, acao: "rejeitar" }` conforme assinatura real. |
| Resultado esperado | Negativos falham sem alteracao; positivo autorizado altera apenas mesa da empresa correta. |
| Evidencia | Status/erro, status antes/depois, diff zero cross-tenant, audit log de decisao quando permitido. |
| Risco se falhar | Aprovacao/rejeicao indevida, fraude comercial, alteracao cross-tenant, dano financeiro. |
| Severidade | R4 critico. |
| Bloqueante | Sim. |

Testes especificos:

```text
anon tenta aprovar -> falha; status igual; nenhum audit log de sucesso
authenticated comum tenta aprovar -> falha; status igual
gestor de outra empresa -> falha cross-tenant
gestor correto -> sucesso controlado no proprio tenant
acao invalida -> falha sem write
simulacao inexistente -> falha segura
simulacao de outra empresa com ID valido -> falha sem revelar existencia sensivel
payload com empresa_id falso -> servidor ignora/bloqueia
proposta ja aprovada/rejeitada -> falha ou idempotencia documentada; sem duplicar log
```

### 6.2 `importar_mesa_cliente_disponibilidade_oficial`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que importacao oficial so altere empresa/empreendimento autorizados. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N05, N09, N10, N11, N12, N13. |
| Papeis | anon, sem corretor, inativo, sem empresa, outro tenant, sem permissao, admin correto, root se formal. |
| Pre-condicao | Empreendimentos TEST_PR58_A/B; payloads validos/invalidos; snapshot de disponibilidade. |
| Payload minimo | `{ empreendimento_id, origem, unidades: [] }` ou equivalente conforme assinatura real. |
| Resultado esperado | Negativos falham; payload invalido nao cria disponibilidade parcial; cross-tenant nao altera oficial. |
| Evidencia | Contagem/checksum antes/depois; erro esperado; log de importacao quando aplicavel. |
| Risco se falhar | Estoque/disponibilidade adulterado, proposta em unidade errada, vazamento comercial. |
| Severidade | R4. |
| Bloqueante | Sim. |

Testes especificos:

```text
payload vazio -> falha sem write
payload sem match -> falha sem alterar estoque
empreendimento de outra empresa -> falha
unidades duplicadas -> falha ou rejeicao documentada sem contaminar oficial
status/preco/area divergente fora do contrato -> falha ou exige revisao manual
usuario autorizado -> altera apenas empresa/empreendimento correto
```

### 6.3 `mesa_cliente_upsert_faixas_premio`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que faixas de premio so sejam criadas/alteradas por perfil autorizado no tenant correto. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N05, N06, N09, N10, N12, N13. |
| Payload minimo | `{ politica_id, faixas: [{ de, ate, percentual }] }` conforme assinatura real. |
| Resultado esperado | Negativos falham; payload invalido nao grava parcialmente; positivo autorizado restringe empresa correta. |
| Evidencia | Snapshot de faixas; erro de validacao; ausencia de upsert cross-tenant; audit log quando aplicavel. |
| Risco se falhar | Manipulacao de remuneracao interna, premio indevido, vazamento de regra comercial. |
| Severidade | R4. |
| Bloqueante | Sim. |

Testes especificos:

```text
faixas negativas -> falha
minimo maior que maximo -> falha
faixas sobrepostas -> falha
quantidade excessiva -> falha por limite documentado
payload tenta sobrescrever created_by/empresa_id/metadata -> falha
```

### 6.4 `mesa_cliente_upsert_politica_financeira`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que politica financeira so seja alterada por papel autorizado da empresa correta. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N05, N06, N09, N10, N12, N13, N15. |
| Payload minimo | `{ empresa_id?, empreendimento_id?, politica_id?, regras_financeiras, vigencia?, status? }` conforme assinatura real. |
| Resultado esperado | Negativos falham sem escrita; payload invalido nao grava politica parcial; positivo autorizado grava no escopo correto. |
| Evidencia | Diff antes/depois da politica; erro esperado; audit log quando existir. |
| Risco se falhar | VPL/taxa/vigencia indevidos, proposta financeira incorreta, cross-tenant. |
| Severidade | R4. |
| Bloqueante | Sim. |

Testes especificos:

```text
VPL null/texto/negativo/infinito/NaN/extremo -> falha
taxa negativa ou acima do teto -> falha
vigencia inicio apos fim -> falha
vigencia sobreposta, se regra exigir exclusividade -> falha
empreendimento de outra empresa -> falha
```

### 6.5 `registrar_upload_arquivo_mesa`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que upload/metadado seja registrado somente no escopo autorizado. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N01, N05, N09, N10, N11, N12, N15. |
| Payload minimo | `{ empresa_id?, empreendimento_id?, arquivo_path, tipo, origem }` conforme assinatura real. |
| Resultado esperado | Negativos falham; path cross-tenant nao registra; metadado invalido nao persiste. |
| Evidencia | Registro antes/depois; ausencia de path de outro tenant; erro sanitizado; audit/event log. |
| Risco se falhar | Vazamento de documento, associacao indevida de arquivo, trilha falsa. |
| Severidade | R4. |
| Bloqueante | Sim. |

Testes especificos:

```text
empresa_id divergente -> falha
storage_path invalido -> falha
path com ../, %2e%2e ou bucket de outro tenant -> falha
tipo/extensao/MIME invalido -> falha
arquivo sem contexto minimo -> falha ou pendente de revisao, nunca oficial automatico
```

### 6.6 `salvar_mesa_cliente_desconto_politica`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que descontos/politicas comerciais so sejam salvos por perfil autorizado no tenant correto. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N05, N06, N09, N10, N12, N13. |
| Payload minimo | `{ empresa_id?, empreendimento_id?, politica_id?, desconto_tipo, desconto_valor, limite?, vigencia? }` conforme assinatura real. |
| Resultado esperado | Negativos falham sem escrita; desconto fora da regra falha; positivo autorizado altera empresa correta. |
| Evidencia | Snapshot antes/depois; erro esperado; ausencia de escrita parcial; audit log. |
| Risco se falhar | Desconto indevido, perda financeira, regra comercial exposta/manipulada. |
| Severidade | R4. |
| Bloqueante | Sim. |

Testes especificos:

```text
desconto acima do permitido -> falha
desconto negativo -> falha
tipo percentual/valor malformado -> falha
vigencia invalida -> falha
desconto retroativo em proposta aprovada -> falha ou nova versao rastreavel, conforme regra
unidade indisponivel -> falha
```

### 6.7 `salvar_mesa_cliente_enriquecimento`

| Campo | Plano |
|---|---|
| Objetivo | Garantir que enriquecimento grave somente campos permitidos no recurso/tenant correto. |
| Cenarios | N01 a N15 obrigatorios. Prioridade maxima: N05, N09, N10, N12, N13, N15. |
| Payload minimo | `{ empresa_id?, mesa_id?, empreendimento_id?, unidade_id?, campos }` conforme assinatura real. |
| Resultado esperado | Negativos falham; campos fora de allowlist nao persistem; cross-tenant nao altera. |
| Evidencia | Diff por campo; erro esperado; nenhum campo sensivel indevido; audit log. |
| Risco se falhar | Ficha/proposta contaminada, exposicao de payload sensivel, alteracao cross-tenant. |
| Severidade | R4. |
| Bloqueante | Sim. |

Testes especificos:

```text
empreendimento/unidade de outra empresa -> falha
overwrite indevido de ficha existente -> falha ou cria versao conforme regra
alteracao tenta impactar proposta emitida -> falha ou gera nova versao rastreavel
payload com HTML/script -> sanitizacao ou falha
payload com campos internos cliente-safe -> falha/removido
```

---

## 7. Cliente-safe obrigatorio

O plano de execucao futura deve provar que resposta/preview/proposta cliente-safe nao expoe:

```text
metadata
payload bruto
checksum
VPL interno
comissao
premio
politica financeira interna
regra de desconto interna
IDs internos de tenant quando nao necessarios
created_by
approved_by
role/permissao
logs tecnicos
SQL/error stack
storage path interno
campos de auditoria nao destinados ao cliente
```

Criterio de aceite:

```text
Cliente-safe deve ser montado por allowlist explicita. Qualquer campo novo nasce privado por padrao.
```

---

## 8. Evidencias obrigatorias para execucao futura

| Evidencia | Conteudo minimo |
|---|---|
| Identificacao | RPC, cenario Nxx, data, ambiente, executor, branch/commit. |
| Papel usado | anon, sem corretor, inativo, sem empresa, cross-tenant, sem permissao, gestor/admin, root/global. |
| Payload sanitizado | Sem tokens, sem PII, sem secrets, sem dado real. |
| Snapshot antes | Contagem/hash/consulta read-only das tabelas afetaveis. |
| Resultado | Status, erro esperado ou sucesso controlado. |
| Snapshot depois | Prova de diff zero nos negativos. |
| Cross-tenant | Prova de que tenant/empresa nao autorizado nao foi alterado. |
| Audit log | Registro criado ou justificativa se ainda nao existir. |
| Classificacao | PASS / FAIL / BLOCKED. |
| Observacao | Risco residual e link para issue/PR futura. |

### 8.1 Observabilidade

Execucao futura deve usar:

```text
test_run_id
request_id/correlation_id
Supabase Logs
audit_logs/event_logs quando existirem
mascaramento de payload sensivel
registro de erro por RPC critica
alerta se houver escrita inesperada
latencia/erro para RPC critica
```

---

## 9. Rollback e limpeza futura

Como esta PR e apenas documental, rollback da PR #58 e reverter/remover este arquivo.

Para execucao futura, exigir:

```text
snapshot/backup antes de teste com escrita autorizada
restauracao testavel ou plano documentado
identificacao das tabelas potencialmente afetadas
criterio de limpeza de registros TEST_PR58_*
responsavel por rollback
evidencia de contagem pos-rollback
proibicao de teste destrutivo em producao
```

---

## 10. Criterios de aceite da PR #58

A PR #58 pode ser aceita se contiver:

```text
1. Status PLANO - NAO EXECUTADO.
2. Escopo documentation-only / test-plan-only.
3. Lista das 7 RPCs da PR #57.
4. Classificacao R4 para todas e R4 critico para aprovar_rejeitar_mesa.
5. Matriz N01-N15 aplicavel a cada RPC.
6. Plano por RPC com objetivo, cenarios, payload minimo, resultado esperado, evidencia e risco.
7. No-write-on-failure obrigatorio.
8. Erro esperado/sanitizado.
9. Audit log quando aplicavel.
10. Secao cliente-safe por allowlist.
11. Dataset sintetico e tenant A/B.
12. Evidencias antes/depois.
13. Rollback/observabilidade para execucao futura.
14. Declaracao explicita de que nenhuma correcao ou execucao e feita nesta PR.
```

---

## 11. Criterios de bloqueio

Bloquear merge da PR #58 se:

```text
houver SQL de correcao
houver REVOKE/GRANT/ALTER/POLICY/RLS/MIGRATION
houver execucao real de teste contra Supabase
faltar uma das 7 RPCs
faltar cenario anon
faltar cenario cross-tenant
faltar no-write-on-failure
faltar distincao entre authenticated e autorizado
confiar em empresa_id/tenant_id vindo do frontend
nao classificar risco como R4
nao tratar aprovar_rejeitar_mesa como R4 critico
expor dado real, token, JWT, service_role, payload sensivel ou print de producao
passar falsa impressao de seguranca ja validada
```

---

## 12. Proxima sequencia recomendada

```text
PR #59A - especificacao final de harness/ambiente de execucao controlada
PR #59B - execucao controlada com evidencias em staging/clone/dataset sintetico, se autorizada
PR #60 - grant review e proposta de correcao, ainda sem aplicar
PRs futuras - correcoes pequenas por classe de risco, com rollback e testes antes/depois
```

---

## 13. Parecer final

```text
Status: PLANO_NAO_EXECUTADO / TEST_PLAN_ONLY
Tipo: documentacao-only
Implementacao autorizada: NAO
Correcao autorizada: NAO
Execucao autorizada: NAO
Risco global: R4
Conclusao: este documento define o plano minimo de testes negativos, evidencias, ambiente, rollback e observabilidade antes de qualquer correcao em RPC/grants/RLS/policies/migrations.
```
