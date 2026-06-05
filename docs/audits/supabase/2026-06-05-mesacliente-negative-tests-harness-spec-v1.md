# FECH.AI - Especificacao de harness para testes negativos Supabase MesaCliente v1

Data: 2026-06-05
Status: HARNESS_SPEC_ONLY / EXECUCAO_NAO_AUTORIZADA
Base: PR #58 - plano de testes negativos Supabase MesaCliente
Tipo: documentation-only / harness-spec-only

Nota editorial: arquivo regravado em texto simples para reduzir risco de caracteres ocultos ou bidirecionais no Markdown.

---

## 1. Objetivo

Especificar o ambiente, o dataset sintetico, os papeis, as evidencias, a observabilidade, o rollback, a limpeza e os criterios GO/NO-GO para uma futura execucao controlada dos testes negativos planejados na PR #58.

Esta PR nao executa testes, nao valida seguranca final e nao prova que o ambiente esta protegido. Ela apenas especifica o laboratorio controlado para uma futura PR ou etapa de execucao.

Status da PR:

```text
HARNESS_SPEC_ONLY / EXECUCAO_NAO_AUTORIZADA
Implementacao autorizada: NAO
Correcao autorizada: NAO
Execucao de testes autorizada: NAO
Alteracao Supabase autorizada: NAO
Uso de producao como laboratorio: NAO
```

---

## 2. Escopo proibido

Esta PR nao altera e nao deve conter:

```text
Supabase real
schema
RLS
FORCE RLS
grants
revoke
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
SQL de correcao
comandos executaveis contra banco
payload real de cliente
credenciais
segredos
chaves privilegiadas
prints de producao
```

---

## 3. RPCs futuras no escopo

As RPCs abaixo sao apenas alvos de teste futuro. Esta PR nao executa chamadas contra elas.

| RPC | Risco | Dominio MesaCliente |
|---|---:|---|
| aprovar_rejeitar_mesa | R4 critico | aprovacao/rejeicao de proposta/simulacao |
| importar_mesa_cliente_disponibilidade_oficial | R4 | disponibilidade oficial, unidades e estoque sintetico |
| mesa_cliente_upsert_faixas_premio | R4 | premio/faixas comerciais internas |
| mesa_cliente_upsert_politica_financeira | R4 | politica financeira, VPL, taxas e vigencia |
| registrar_upload_arquivo_mesa | R4 | upload/importacao e trilha de arquivo |
| salvar_mesa_cliente_desconto_politica | R4 | desconto/regra comercial |
| salvar_mesa_cliente_enriquecimento | R4 | enriquecimento de unidade/proposta |

---

## 4. Principios do harness

```text
1. Banco/RPC continuam sendo fonte da verdade.
2. Frontend/payload nunca e soberano para tenant, empresa, perfil, permissao, regra financeira, proposta ou cliente-safe.
3. Usuario autenticado nao e automaticamente usuario autorizado.
4. Nenhum teste destrutivo deve rodar em producao.
5. Todos os dados devem ser sinteticos, isolados e prefixados.
6. Todo teste negativo precisa provar erro esperado e diff zero.
7. Toda escrita R4 futura precisa ter evidencia/auditoria; sem auditoria, o teste fica BLOCKED.
8. Toda evidencia deve ser sanitizada.
9. Todo teste futuro precisa de rollback e limpeza documentados.
10. A execucao futura depende de aprovacao explicita em PR ou etapa separada.
```

---

## 5. Ambiente recomendado

| Ambiente | Uso permitido | Status |
|---|---|---|
| Staging dedicado | Preferencial para execucao futura dos testes. | GO se isolado e com dataset sintetico. |
| Clone Supabase isolado | Recomendado quando houver risco de escrita. | GO se restauravel. |
| Snapshot restauravel | Obrigatorio antes de qualquer escrita futura autorizada. | GO se validado. |
| Producao | Somente metadata read-only, sem acionar logica de negocio ou RPC de escrita. | NO-GO para teste destrutivo. |

Declaracoes obrigatorias:

```text
E proibido executar teste destrutivo em producao.
E proibido usar producao como laboratorio.
E proibido acionar RPC de escrita em producao durante esta fase.
E proibido usar dado comercial real como fixture.
E proibido usar chave privilegiada em teste manual.
```

---

## 6. Dataset sintetico minimo

Prefixo obrigatorio:

```text
TEST_PR59_
```

Entidades minimas:

| Entidade | Exigencia |
|---|---|
| Tenant/empresa A | TEST_PR59_TENANT_A / TEST_PR59_EMPRESA_A |
| Tenant/empresa B | TEST_PR59_TENANT_B / TEST_PR59_EMPRESA_B |
| Empreendimento A/B | sintetico e isolado por tenant |
| Unidade A/B | sintetica, sem estoque real |
| Simulacao/proposta A/B | sintetica, sem proposta comercial real |
| Politica financeira A/B | sintetica, sem politica ativa real |
| Desconto A/B | sintetico, sem regra comercial ativa real |
| Faixas de premio A/B | sinteticas, sem premio/comissao real |
| Disponibilidade oficial A/B | sintetica, sem alterar estoque real |
| Upload A/B | arquivo falso/controlado, sem documento real de cliente |
| Enriquecimento A/B | dados sinteticos, sem ficha real de unidade |

Proibicoes:

```text
nenhum CPF real
nenhum telefone real
nenhum e-mail real de cliente
nenhum lead real
nenhum cliente real
nenhum estoque real
nenhuma proposta real
nenhuma politica financeira comercial ativa
nenhum desconto comercial real
nenhuma faixa de premio real
nenhum documento real de cliente
nenhum storage path real de tenant produtivo
```

---

## 7. Usuarios e papeis sinteticos

| Papel | Objetivo do teste futuro |
|---|---|
| anon_sem_sessao | validar bloqueio sem autenticacao |
| authenticated_sem_corretor | validar que autenticacao nao basta |
| corretor_ativo_tenant_A | validar autorizado no proprio tenant quando aplicavel |
| corretor_inativo_tenant_A | validar bloqueio por status |
| corretor_ativo_tenant_B | validar cross-tenant |
| authenticated_sem_empresa | validar bloqueio sem empresa/tenant valido |
| corretor_sem_permissao | validar permissao insuficiente |
| gestor_admin_local_tenant_A | validar permissao administrativa local |
| root_admin_global | somente se existir regra formal documentada no banco |

Regras:

```text
Cada papel deve corresponder a usuario sintetico real no ambiente futuro.
Root/admin global nao pode ser inferido pelo frontend.
Papeis devem ser derivados de vinculo real no banco.
Tenant/empresa/perfil/permissao nao podem ser aceitos como verdade apenas pelo payload.
```

---

## 8. Matriz tenant A/B e recursos

A futura execucao deve possuir recursos equivalentes em A e B:

| Recurso | Tenant A | Tenant B |
|---|---|---|
| Empresa | TEST_PR59_EMPRESA_A | TEST_PR59_EMPRESA_B |
| Empreendimento | TEST_PR59_EMPREENDIMENTO_A | TEST_PR59_EMPREENDIMENTO_B |
| Unidade | TEST_PR59_UNIDADE_A | TEST_PR59_UNIDADE_B |
| Simulacao/proposta | TEST_PR59_SIMULACAO_A | TEST_PR59_SIMULACAO_B |
| Politica financeira | TEST_PR59_POLITICA_FIN_A | TEST_PR59_POLITICA_FIN_B |
| Desconto | TEST_PR59_DESCONTO_A | TEST_PR59_DESCONTO_B |
| Faixas de premio | TEST_PR59_PREMIO_A | TEST_PR59_PREMIO_B |
| Upload | TEST_PR59_UPLOAD_A | TEST_PR59_UPLOAD_B |
| Enriquecimento | TEST_PR59_ENRIQUECIMENTO_A | TEST_PR59_ENRIQUECIMENTO_B |

Criterio cross-tenant:

```text
Usuario/recurso A tentando operar B deve falhar.
Usuario/recurso B tentando operar A deve falhar.
Payload com empresa_id/tenant_id falso deve ser ignorado ou bloqueado pelo backend/RPC.
Todo teste cross-tenant negativo exige diff zero no tenant alvo indevido.
```

---

## 9. Tabelas e dominios para snapshot futuro

As tabelas abaixo devem ser tratadas como alvos de snapshot quando existirem no schema real. Antes da execucao, seus nomes reais devem ser confirmados contra o inventario PR #55/#56.

| Dominio | Tabelas/estruturas esperadas | Evidencia futura |
|---|---|---|
| Proposta/aprovacao | mesa_simulacoes | status antes/depois, diff zero nos negativos |
| Disponibilidade | tabelas de estoque, unidades e snapshots comerciais | contagem/checksum antes/depois |
| Politica financeira | mesa_cliente_politicas_financeiras | diff por politica/tenant |
| Premio | mesa_cliente_politica_premio_faixas | diff por faixas/tenant |
| Desconto | mesa_cliente_desconto_politicas | diff por regra/tenant |
| Upload | mesa_arquivos ou registro equivalente | diff por arquivo/path/tenant |
| Enriquecimento | mesa_cliente_unidade_enriquecimentos | diff por unidade/campo/tenant |
| Auditoria | audit_logs, event_logs ou equivalente | actor, acao, recurso, tenant, resultado |

Nota:

```text
mesa_cliente_desconto_politicas, mesa_cliente_unidade_enriquecimentos, mesa_arquivos e tabelas de estoque/disponibilidade devem ter nomes reais confirmados antes da execucao futura.
```

---

## 10. Evidencias obrigatorias por cenario futuro

Cada cenario N01-N15 da PR #58 deve gerar evidencia com:

```text
test_run_id
request_id/correlation_id
ambiente
data/hora
executor
branch
commit
RPC testada
cenario N01-N15
papel usado
tenant do actor
tenant do recurso
payload sanitizado
snapshot antes
resultado esperado
resultado obtido
snapshot depois
diff esperado
diff obtido
prova cross-tenant quando aplicavel
audit log/event log quando aplicavel
Supabase Logs quando disponiveis
latencia
erro/codigo de erro
classificacao PASS/FAIL/BLOCKED
observacao de rollback/limpeza
```

Classificacao:

| Resultado | Significado |
|---|---|
| PASS | Bloqueio/resultado esperado ocorreu e evidencia esta completa. |
| FAIL | Comportamento inseguro ou divergente ocorreu. |
| BLOCKED | Teste nao pode ser executado com seguranca ou pre-condicao faltou. |

Criterios para negativos:

```text
erro esperado + diff zero + nenhum cross-tenant write + evidencia sanitizada
```

Criterios para positivos controlados futuros:

```text
sucesso restrito ao tenant correto + diff esperado + auditabilidade + rollback/limpeza
```

---

## 11. Observabilidade obrigatoria

A execucao futura deve observar:

```text
Supabase Logs
audit_logs/event_logs quando existirem
latencia por RPC
erro por RPC
correlacao por test_run_id
request_id/correlation_id
alerta para escrita inesperada
alerta para cross-tenant inesperado
payload mascarado
ausencia de credenciais, cookies, headers sensiveis, chaves privilegiadas e PII em logs
```

Proibido registrar em evidencia:

```text
JWT
cookie
Authorization header
refresh token
chave privilegiada
CPF
telefone
e-mail real
payload com PII
documento real de cliente
```

---

## 12. Cliente-safe e MesaCliente

O harness deve garantir que nenhum teste futuro gere proposta real, PDF real, segunda via real, envio ao cliente ou dado visual confundivel com atendimento real.

Cliente-safe deve ser validado por allowlist:

```text
campo novo nasce privado por padrao
metadata nao deve vazar
payload bruto nao deve vazar
checksum nao deve vazar
VPL interno nao deve vazar
comissao/premio nao deve vazar
politica financeira interna nao deve vazar
regra de desconto interna nao deve vazar
storage path interno nao deve vazar
logs tecnicos e SQL/error stack nao devem vazar
campos de auditoria internos nao devem vazar
```

Criterios de parada MesaCliente:

```text
qualquer proposta real gerada
qualquer proposta enviada a cliente
qualquer estoque real alterado
qualquer politica financeira real usada como fixture
qualquer desconto real aplicado
qualquer faixa de premio real usada
qualquer storage path real usado
qualquer ficha/unidade real sobrescrita
qualquer exposicao cliente-safe
```

---

## 13. Rollback e limpeza futura

Antes de qualquer escrita futura autorizada:

```text
snapshot/backup confirmado
responsavel pelo rollback definido
criterio de acionamento de rollback definido
plano de limpeza dos registros TEST_PR59_ definido
validacao pos-limpeza definida
evidencia de diff zero quando o teste esperado nao deve escrever
evidencia de remocao quando o teste autorizado criar dado sintetico
```

STOP imediato se ocorrer:

```text
escrita em producao
escrita fora de TEST_PR59_
vazamento de credencial, cookie, header sensivel ou chave privilegiada
uso de dado real
cross-tenant indevido
proposta real gerada
estoque real alterado
politica financeira real alterada
erro generalizado em RPC critica
incidente operacional SEV1/SEV2
```

---

## 14. Checklist de ambiente antes da futura PR #59B

```text
[ ] Ambiente staging/clone identificado
[ ] Producao explicitamente proibida para teste destrutivo
[ ] Snapshot criado antes de qualquer escrita futura autorizada
[ ] Plano de restauracao documentado
[ ] Dataset TEST_PR59_ criado ou especificado
[ ] Tenant A e Tenant B sinteticos definidos
[ ] Usuarios sinteticos por papel definidos
[ ] Nenhum dado real de cliente
[ ] Nenhum CPF/e-mail/telefone real
[ ] Nenhuma proposta real
[ ] Nenhum estoque real
[ ] Nenhuma politica financeira real
[ ] Responsavel tecnico definido
[ ] Janela de execucao futura definida
[ ] Criterio de interrupcao imediata definido
[ ] Observabilidade habilitada
[ ] Rollback/limpeza aprovado
```

---

## 15. GO/NO-GO

### 15.1 GO para criar/mergear a PR #59A

```text
[ ] documentation-only
[ ] harness-spec-only
[ ] sem SQL
[ ] sem migration
[ ] sem alteracao Supabase
[ ] sem grants/RLS/policies/RPCs
[ ] sem frontend/parser/motor financeiro
[ ] sem CI/CD
[ ] sem execucao de testes
[ ] define staging/clone/snapshot
[ ] proibe producao destrutiva
[ ] exige dataset TEST_PR59_
[ ] exige tenant A/B
[ ] exige usuarios sinteticos por papel
[ ] exige evidencia completa
[ ] exige observabilidade por test_run_id
[ ] exige rollback/limpeza
[ ] exige aprovacao explicita para futura #59B
```

### 15.2 GO para futura PR #59B executar

```text
[ ] #59A mergeada
[ ] ambiente isolado pronto
[ ] snapshot criado
[ ] dataset TEST_PR59_ validado
[ ] usuarios sinteticos ativos
[ ] credenciais de teste controladas
[ ] observabilidade habilitada
[ ] rollback aprovado
[ ] responsavel definido
[ ] janela de execucao aprovada
[ ] execucao com aprovacao explicita
```

### 15.3 NO-GO para futura PR #59B

```text
[ ] ambiente for producao
[ ] staging/clone nao estiver pronto
[ ] snapshot nao existir
[ ] houver dado real
[ ] faltar tenant B
[ ] faltar usuario anon/sem sessao
[ ] faltar usuario cross-tenant
[ ] faltar corretor inativo
[ ] faltar payload sanitizado
[ ] faltar plano de rollback
[ ] faltar Supabase Logs ou alternativa documentada
[ ] houver risco de expor credencial, cookie, header sensivel ou chave privilegiada
[ ] houver ambiguidade sobre quem executa
```

### 15.4 BLOCKED por cenario

```text
pre-condicao nao existe
payload nao esta sanitizado
usuario sintetico nao esta validado
tenant A/B nao esta isolado
snapshot nao foi confirmado
observabilidade nao esta disponivel
nao ha como provar antes/depois
execucao exigiria producao
execucao exigiria dado real
```

---

## 16. Criterios de bloqueio da PR #59A

Bloquear a PR #59A se houver:

```text
SQL de correcao
GRANT / REVOKE
ALTER FUNCTION / CREATE FUNCTION / DROP FUNCTION
ALTER POLICY / CREATE POLICY
ENABLE RLS / FORCE RLS
migration
alteracao de frontend
execucao real de teste
deploy
uso de producao como ambiente de teste
uso de chave privilegiada em teste manual
credencial, cookie, header sensivel ou chave privilegiada em evidencia
dados reais ou pessoais
ausencia de tenant A/B
ausencia de usuarios por papel
ausencia de snapshot
ausencia de rollback
ausencia de diff zero
ausencia de auditabilidade para escrita R4
```

---

## 17. Ordem segura das proximas PRs

```text
PR #59A - especificacao final de harness/ambiente, apenas documentacao
PR #59B - execucao controlada com evidencias, se autorizada
PR #60 - grant review e proposta de correcao, ainda sem aplicar
PRs futuras - correcoes pequenas por classe de risco
PR posterior - reexecucao/validacao pos-correcao
```

---

## 18. Parecer final

```text
Status: HARNESS_SPEC_ONLY / EXECUCAO_NAO_AUTORIZADA
Tipo: documentation-only
Implementacao autorizada: NAO
Correcao autorizada: NAO
Execucao autorizada: NAO
Risco preparado: R4
Conclusao: este documento especifica o laboratorio seguro para futura execucao controlada dos testes negativos MesaCliente. Ele nao executa testes e nao autoriza correcao.
```
