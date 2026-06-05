# FECH.AI - Template de evidencias para execucao futura dos testes negativos Supabase MesaCliente v1

Data: 2026-06-05
Status: CONTROLLED_EXECUTION_READINESS / TESTS_NOT_RUN
Tipo: documentation-only / execution-readiness / evidence-template / tests-not-run
Base documental: PR #58 - plano de testes negativos Supabase MesaCliente; PR #59A - especificacao do harness/ambiente controlado
Branch documental: docs/mesacliente-negative-tests-execution-evidence-v1-20260605

Nota editorial: documento preparado como template de evidencia e prontidao operacional. Ele nao contem SQL de correcao, credenciais, dados reais, chamadas RPC, prints de producao, headers, cookies, JWT ou qualquer instrucao para modificar Supabase.

---

## 1. Objetivo da PR #60

Criar um documento de prontidao de execucao controlada e um template padronizado de evidencias para a futura execucao dos testes negativos Supabase MesaCliente.

Esta PR #60 e exclusivamente documental e tem os seguintes objetivos permitidos:

```text
documentar prontidao de execucao
criar checklist GO/NO-GO
criar template de evidencia
criar matriz de execucao N01-N15 por RPC
registrar criterios de PASS/FAIL/BLOCKED/NOT_RUN
registrar STOP conditions
registrar rollback/limpeza futura
registrar proxima sequencia segura
```

Esta PR #60 nao valida seguranca final, nao prova que o ambiente esta protegido e nao substitui a aprovacao formal para execucao futura.

---

## 2. Relacao com PR #58 e PR #59A

| Referencia | Papel na sequencia | Relacao com este documento |
|---|---|---|
| PR #58 | Plano de testes negativos Supabase MesaCliente | Define as 7 RPCs R4 no escopo e a matriz N01-N15 de cenarios negativos. |
| PR #59A | Especificacao do harness/ambiente controlado | Define laboratorio, dataset TEST_PR59_, observabilidade, rollback, limpeza e criterios de seguranca para execucao futura. |
| PR #60 | Readiness/template de evidencia | Consolida checklist GO/NO-GO, matriz de execucao por RPC/cenario e modelo de evidencia, mantendo TESTS_NOT_RUN. |

Principio de continuidade:

```text
PR #58 planejou o que testar.
PR #59A especificou onde e sob quais controles testar.
PR #60 documenta como registrar evidencias quando, e somente quando, houver GO formal futuro.
```

---

## 3. Status formal

```text
Status: CONTROLLED_EXECUTION_READINESS / TESTS_NOT_RUN
Tipo: documentation-only
Execucao de testes: NAO EXECUTADA
Chamada RPC real: NAO EXECUTADA
Alteracao Supabase: NAO EXECUTADA
Correcao tecnica: NAO AUTORIZADA
Uso de producao: NAO AUTORIZADO
Uso de dados reais: NAO AUTORIZADO
Resultado final esperado desta PR: TESTS_NOT_RUN / EXECUTION_BLOCKED_UNTIL_FORMAL_GO
```

---

## 4. Declaracao explicita de nao execucao

Nenhum teste foi executado nesta PR.

Nao houve chamada real, simulada contra ambiente real ou manual contra nenhuma das RPCs abaixo:

```text
aprovar_rejeitar_mesa
importar_mesa_cliente_disponibilidade_oficial
mesa_cliente_upsert_faixas_premio
mesa_cliente_upsert_politica_financeira
registrar_upload_arquivo_mesa
salvar_mesa_cliente_desconto_politica
salvar_mesa_cliente_enriquecimento
```

Tambem nao houve:

```text
consulta operacional contra Supabase
execucao de SQL
criacao de fixture em banco
criacao de usuario Supabase
criacao de tenant ou empresa
alteracao de schema
alteracao de RLS/FORCE RLS
grant/revoke
alteracao de policies
alteracao de RPC/function
migration
deploy
acao em producao
```

---

## 5. Declaracao explicita de correcao tecnica nao autorizada

Nenhuma correcao tecnica esta autorizada por esta PR #60.

Esta PR nao autoriza:

```text
alterar Supabase
alterar schema
alterar RLS
alterar FORCE RLS
alterar grants
alterar policies
alterar RPCs/functions
criar migrations
alterar parser
alterar motor financeiro
alterar frontend
alterar Vercel
alterar GitHub Actions
alterar Worker
alterar Make/n8n
usar producao
usar dados reais
incluir SQL de correcao
aplicar correcao tecnica
```

Qualquer proposta de correcao deve ser tratada em PR futura separada, pequena, revisavel e vinculada a uma classe de risco especifica.

---

## 6. Escopo proibido desta PR

Este documento nao deve conter e esta PR nao deve executar:

```text
testes
chamadas RPC reais
alteracoes Supabase
schema changes
RLS/FORCE RLS changes
grants/revokes
policies changes
RPC/function changes
migrations
alteracoes no parser
alteracoes no motor financeiro
alteracoes no frontend
alteracoes em Vercel
alteracoes em GitHub Actions
alteracoes em Worker
alteracoes em Make/n8n
uso de producao
uso de dados reais
credenciais
tokens
JWT
cookies
headers
service_role
prints de producao
PII
SQL de correcao
autorizacao de correcao tecnica
```

---

## 7. Checklist GO/NO-GO antes de qualquer execucao futura

### 7.1 GO minimo para uma futura etapa #60-Execution

Todos os itens abaixo devem estar marcados antes de qualquer execucao futura:

```text
[ ] Aprovacao explicita e formal para execucao futura registrada fora desta PR documental
[ ] Ambiente staging/clone/snapshot identificado e isolado
[ ] Producao explicitamente excluida da execucao
[ ] Snapshot restauravel criado antes de qualquer escrita futura autorizada
[ ] Data/hora do snapshot registrada
[ ] Branch e commit de execucao registrados
[ ] Executor identificado
[ ] Janela de execucao aprovada
[ ] Responsavel pelo rollback identificado
[ ] Plano de rollback aprovado
[ ] Plano de limpeza TEST_PR59_ aprovado
[ ] Dataset sintetico TEST_PR59_ criado ou confirmado
[ ] Tenant A sintetico confirmado
[ ] Tenant B sintetico confirmado
[ ] Empresa A sintetica confirmada
[ ] Empresa B sintetica confirmada
[ ] Usuarios sinteticos por papel confirmados
[ ] Recursos sinteticos por tenant confirmados
[ ] Nenhum dado real presente no dataset
[ ] Nenhum CPF, telefone, e-mail, lead, cliente, proposta, documento ou storage path real presente
[ ] Observabilidade por test_run_id e request_id/correlation_id disponivel
[ ] Forma de provar snapshot antes/depois definida
[ ] Criterios PASS/FAIL/BLOCKED/NOT_RUN aceitos
[ ] STOP conditions aceitas por executor e responsavel de rollback
```

### 7.2 NO-GO absoluto

Qualquer item abaixo bloqueia a execucao futura:

```text
[ ] Ambiente e producao ou replica nao isolada de producao
[ ] Snapshot restauravel ausente
[ ] Data do snapshot desconhecida
[ ] Dataset sintetico incompleto
[ ] Tenant B ausente
[ ] Usuario cross-tenant ausente
[ ] Usuario inativo ausente
[ ] Usuario sem empresa ausente
[ ] Payload nao sanitizado
[ ] Evidencia exigiria JWT, cookie, header, token, service_role ou segredo
[ ] Evidencia conteria PII ou dado comercial real
[ ] Observabilidade insuficiente para provar diff zero
[ ] Rollback sem responsavel
[ ] Janela de execucao nao aprovada
[ ] Ambiguidade sobre executor
[ ] Qualquer necessidade de correcao tecnica antes/durante o teste
```

---

## 8. Registro do ambiente futuro

Preencher somente em uma futura etapa autorizada. Nesta PR documental, todos os campos permanecem `NOT_RUN` ou `A_DEFINIR`.

| Campo | Valor esperado na futura execucao | Valor nesta PR |
|---|---|---|
| Ambiente | staging / clone / snapshot isolado | NOT_RUN |
| Tipo de ambiente | staging dedicado, clone Supabase ou snapshot restauravel | A_DEFINIR |
| Producao excluida? | Sim | Sim, por regra documental |
| Data do snapshot | ISO-8601, com timezone | NOT_RUN |
| Identificador do snapshot | ID interno sanitizado ou referencia nao sensivel | NOT_RUN |
| Branch | Branch usada na execucao futura | docs/mesacliente-negative-tests-execution-evidence-v1-20260605 |
| Commit | SHA do commit usado na execucao futura | NOT_RUN |
| Executor | Nome/handle autorizado, sem credenciais | A_DEFINIR |
| Janela de execucao | Inicio/fim aprovados | A_DEFINIR |
| Responsavel pelo rollback | Nome/handle autorizado | A_DEFINIR |
| Plano de rollback | Documento ou procedimento aprovado, sem SQL de correcao nesta PR | A_DEFINIR |
| Plano de limpeza | Remocao/validacao de dados TEST_PR59_ | A_DEFINIR |
| Observabilidade | Logs/eventos/correlation id sem segredos | A_DEFINIR |

---

## 9. Dataset sintetico TEST_PR59_

Prefixo obrigatorio para qualquer fixture futura:

```text
TEST_PR59_
```

### 9.1 Tenants e empresas sinteticas

| Entidade | Tenant A | Tenant B | Regra |
|---|---|---|---|
| Tenant | TEST_PR59_TENANT_A | TEST_PR59_TENANT_B | Isolados; nenhum vinculo com tenant real. |
| Empresa | TEST_PR59_EMPRESA_A | TEST_PR59_EMPRESA_B | Isoladas; nenhuma empresa comercial real. |

### 9.2 Usuarios sinteticos por papel

| Papel sintetico | Tenant esperado | Objetivo |
|---|---|---|
| TEST_PR59_ANON_SEM_SESSAO | nenhum | Validar bloqueio sem autenticacao. |
| TEST_PR59_AUTH_SEM_CORRETOR | nenhum ou tenant neutro | Validar que autenticacao nao basta. |
| TEST_PR59_AUTH_SEM_EMPRESA | sem empresa valida | Validar bloqueio sem tenant/empresa. |
| TEST_PR59_CORRETOR_ATIVO_A | Tenant A | Controle autorizado quando aplicavel. |
| TEST_PR59_CORRETOR_INATIVO_A | Tenant A | Validar bloqueio por status inativo. |
| TEST_PR59_CORRETOR_SEM_PERMISSAO_A | Tenant A | Validar permissao insuficiente. |
| TEST_PR59_GESTOR_ADMIN_LOCAL_A | Tenant A | Controle positivo local quando aplicavel. |
| TEST_PR59_CORRETOR_ATIVO_B | Tenant B | Validar cross-tenant contra recursos A. |
| TEST_PR59_ROOT_ADMIN_GLOBAL | global, se existir regra formal | Usar somente se papel global estiver formalmente definido no banco. |

Regras obrigatorias:

```text
Usuarios sinteticos devem existir somente no ambiente isolado futuro.
Papeis devem derivar de registros do banco, nao de payload confiado.
Root/admin global nao pode ser inferido por frontend.
Nenhum usuario real pode ser usado como fixture.
```

### 9.3 Recursos sinteticos por tenant

| Recurso | Tenant A | Tenant B | Proibicao associada |
|---|---|---|---|
| Empreendimento | TEST_PR59_EMPREENDIMENTO_A | TEST_PR59_EMPREENDIMENTO_B | Nenhum empreendimento real. |
| Unidade | TEST_PR59_UNIDADE_A | TEST_PR59_UNIDADE_B | Nenhum estoque real. |
| Simulacao/proposta | TEST_PR59_SIMULACAO_A | TEST_PR59_SIMULACAO_B | Nenhuma proposta comercial real. |
| Politica financeira | TEST_PR59_POLITICA_FIN_A | TEST_PR59_POLITICA_FIN_B | Nenhuma politica ativa real. |
| Desconto | TEST_PR59_DESCONTO_A | TEST_PR59_DESCONTO_B | Nenhuma regra comercial real. |
| Faixas de premio | TEST_PR59_PREMIO_A | TEST_PR59_PREMIO_B | Nenhuma comissao/premio real. |
| Disponibilidade oficial | TEST_PR59_DISPONIBILIDADE_A | TEST_PR59_DISPONIBILIDADE_B | Nenhum estoque real. |
| Upload | TEST_PR59_UPLOAD_A | TEST_PR59_UPLOAD_B | Nenhum documento real de cliente. |
| Enriquecimento | TEST_PR59_ENRIQUECIMENTO_A | TEST_PR59_ENRIQUECIMENTO_B | Nenhuma ficha/unidade real. |

### 9.4 Dados proibidos em fixtures e evidencias

```text
CPF real
telefone real
e-mail real
lead real
cliente real
proposta real
estoque real
politica financeira real
desconto comercial real
faixa de premio real
documento real de cliente
storage path real
credencial
token
JWT
cookie
header
service_role
print de producao
PII
```

---

## 10. Matriz das 7 RPCs R4

| RPC | Risco | Dominio | Escrita esperada somente em positivo controlado futuro | Evidencia minima futura |
|---|---:|---|---|---|
| aprovar_rejeitar_mesa | R4 critico | Aprovacao/rejeicao de proposta/simulacao | Apenas recurso TEST_PR59_ do tenant autorizado | status antes/depois, diff esperado/obtido, auditoria, rollback. |
| importar_mesa_cliente_disponibilidade_oficial | R4 | Disponibilidade oficial, unidades, estoque sintetico | Apenas disponibilidade TEST_PR59_ | contagem/checksum antes/depois, diff por tenant, auditoria, rollback. |
| mesa_cliente_upsert_faixas_premio | R4 | Premio/faixas comerciais internas | Apenas faixas TEST_PR59_ | faixas antes/depois, diff por tenant, auditoria, rollback. |
| mesa_cliente_upsert_politica_financeira | R4 | Politica financeira, VPL, taxas e vigencia | Apenas politica TEST_PR59_ | politica antes/depois, diff por tenant, auditoria, rollback. |
| registrar_upload_arquivo_mesa | R4 | Upload/importacao e trilha de arquivo | Apenas upload TEST_PR59_ sem documento real | metadados antes/depois, path sintetico, auditoria, rollback. |
| salvar_mesa_cliente_desconto_politica | R4 | Desconto/regra comercial | Apenas desconto TEST_PR59_ | regra antes/depois, diff por tenant, auditoria, rollback. |
| salvar_mesa_cliente_enriquecimento | R4 | Enriquecimento de unidade/proposta | Apenas enriquecimento TEST_PR59_ | campos antes/depois, diff por tenant, auditoria, rollback. |

---

## 11. Matriz N01-N15 herdada da PR #58

Esta matriz deve ser aplicada a cada uma das 7 RPCs R4, ajustando payloads somente conforme assinatura real em ambiente futuro autorizado e sempre com payload sanitizado.

| ID | Cenario | Papel usado | Pre-condicao | Resultado esperado | Evidencia esperada | Status nesta PR |
|---|---|---|---|---|---|---|
| N01 | anon sem sessao valida | Sem sessao / anon key | Chamada sem credencial de usuario autenticado | RPC deve falhar por ausencia de autenticacao/autorizacao | Erro esperado; diff zero | NOT_RUN |
| N02 | authenticated sem corretor | Usuario Auth valido sem vinculo operacional | Sessao valida sem linha em corretores/equivalente | RPC deve falhar | Erro esperado; diff zero | NOT_RUN |
| N03 | corretor inativo | Usuario com vinculo inativo | Registro existe com ativo=false/status equivalente | RPC deve falhar | Erro esperado; diff zero | NOT_RUN |
| N04 | authenticated sem empresa | Usuario ativo sem empresa/tenant valido | Sem vinculo empresarial valido | RPC deve falhar | Erro esperado; diff zero | NOT_RUN |
| N05 | outra empresa/tenant | Usuario Empresa B operando recurso da Empresa A | IDs sinteticos de tenants distintos | RPC deve falhar | Nenhuma alteracao na Empresa A | NOT_RUN |
| N06 | corretor sem perfil/permissao | Corretor ativo sem permissao especifica | Empresa correta, perfil insuficiente | RPC deve falhar | Erro esperado; diff zero | NOT_RUN |
| N07 | gestor/admin da empresa correta | Gestor/admin local autorizado | Recurso pertence ao mesmo tenant | Controle positivo futuro, quando aplicavel | Sucesso restrito e auditado | NOT_RUN |
| N08 | root/admin global | Admin global/suporte interno, se formal | Papel global validado no banco | Deve passar apenas se regra permitir | Sucesso ou bloqueio documentado e auditavel | NOT_RUN |
| N09 | payload invalido | Papel autorizado ou nao | Campos ausentes, tipos errados, enum invalido, valores negativos/extremos | Falha antes de escrever | Erro de validacao; diff zero | NOT_RUN |
| N10 | payload cross-tenant | Usuario Empresa A enviando resource_id da Empresa B | Payload tenta forcar tenant/empresa | RPC deve falhar | Diff zero na Empresa B | NOT_RUN |
| N11 | IDs inexistentes | Papel autenticado | IDs sintaticamente validos, mas inexistentes | Falha segura | Erro sem vazamento sensivel | NOT_RUN |
| N12 | escrita fora do escopo | Papel com permissao parcial | Tenta alterar recurso de outro empreendimento/proposta/politica/mesa | RPC deve falhar | Diff zero fora do escopo | NOT_RUN |
| N13 | no-write-on-failure | Qualquer cenario negativo | Snapshot antes/depois planejado | Nenhuma tabela de negocio deve mudar | Hash/contagem/read-only antes/depois | NOT_RUN |
| N14 | erro esperado | Qualquer cenario negativo | Contrato de erro definido | Erro previsivel, sem stack trace sensivel | Codigo/mensagem sanitizada | NOT_RUN |
| N15 | audit log para R4 | Tentativa sensivel | Audit/event log existe ou teste deve ficar BLOCKED | Escrita autorizada futura deve ter evidencia/auditoria; sem auditoria, teste R4 fica BLOCKED | Actor, acao, recurso, tenant, resultado | NOT_RUN |

---

## 12. Matriz de execucao N01-N15 por RPC

Usar a classificacao inicial `NOT_RUN` nesta PR. Em futura execucao autorizada, cada celula deve ser preenchida com `PASS`, `FAIL`, `BLOCKED` ou `NOT_RUN`, acompanhada de evidencia individual.

| RPC | N01 | N02 | N03 | N04 | N05 | N06 | N07 | N08 | N09 | N10 | N11 | N12 | N13 | N14 | N15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| aprovar_rejeitar_mesa | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| importar_mesa_cliente_disponibilidade_oficial | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| mesa_cliente_upsert_faixas_premio | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| mesa_cliente_upsert_politica_financeira | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| registrar_upload_arquivo_mesa | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| salvar_mesa_cliente_desconto_politica | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| salvar_mesa_cliente_enriquecimento | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |

---

## 13. Criterios de classificacao PASS/FAIL/BLOCKED/NOT_RUN

| Classificacao | Criterio | Acao |
|---|---|---|
| PASS | Resultado esperado ocorreu, evidencia esta completa, payload esta sanitizado, diff esperado bate com diff obtido e nao houve violacao de STOP condition. | Registrar evidencia e seguir para o proximo cenario se a janela continuar GO. |
| FAIL | Resultado inseguro/divergente ocorreu, houve escrita inesperada, cross-tenant indevido, vazamento sensivel, erro nao previsto ou diff obtido diferente do esperado. | Parar conforme STOP condition aplicavel, preservar evidencias sanitizadas e acionar rollback se necessario. |
| BLOCKED | Pre-condicao ausente, ambiente inseguro, snapshot ausente, usuario sintetico ausente, observabilidade insuficiente ou teste exigiria producao/dado real/segredo. | Nao executar o cenario; documentar bloqueio e resolver em etapa futura sem correcao tecnica nesta PR. |
| NOT_RUN | Cenario nao foi executado. | Estado padrao desta PR documental e de qualquer cenario sem GO formal. |

Criterio minimo para negativos:

```text
erro esperado + diff zero + nenhum cross-tenant write + evidencia sanitizada + rollback nao requerido ou claramente disponivel
```

Criterio minimo para positivos controlados futuros, quando aplicavel:

```text
sucesso restrito ao tenant correto + diff esperado + auditoria + rollback/limpeza aprovados + ausencia de dados reais
```

---

## 14. Template de evidencia por cenario

Copiar um bloco por combinacao `RPC x Nxx` somente em futura execucao autorizada. Nao preencher com dados reais, credenciais ou conteudo sensivel.

```text
[EVIDENCIA]
test_run_id: TEST_PR59_RUN_<YYYYMMDD>_<NNN>
request_id/correlation_id: <id sanitizado ou NOT_AVAILABLE>
ambiente: <staging|clone|snapshot> - nunca producao
data/hora: <ISO-8601 com timezone>
executor: <nome/handle autorizado, sem credenciais>
branch: <branch de execucao>
commit: <SHA de execucao>
RPC testada: <uma das 7 RPCs R4>
cenario N01-N15: <Nxx - nome do cenario>
papel usado: <papel sintetico TEST_PR59_>
tenant do actor: <TEST_PR59_TENANT_A|TEST_PR59_TENANT_B|nenhum|global formal>
tenant do recurso: <TEST_PR59_TENANT_A|TEST_PR59_TENANT_B|nenhum>
payload sanitizado: <payload mascarado, sem PII, sem token, sem header, sem segredo>
snapshot antes: <referencia sanitizada para contagem/hash/estado antes>
resultado esperado: <erro esperado, sucesso restrito ou BLOCKED esperado>
resultado obtido: <erro/codigo sanitizado ou sucesso restrito; sem stack sensivel>
snapshot depois: <referencia sanitizada para contagem/hash/estado depois>
diff esperado: <diff zero ou diff controlado em TEST_PR59_>
diff obtido: <diff zero, diff controlado ou divergencia>
classificacao: <PASS|FAIL|BLOCKED|NOT_RUN>
observabilidade: <logs/eventos sanitizados, audit log se aplicavel>
rollback/limpeza: <nao requerido|executado|pendente|blocked, sem SQL de correcao>
observacoes: <somente informacao sanitizada>
[/EVIDENCIA]
```

Campos obrigatorios por cenario:

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
classificacao PASS/FAIL/BLOCKED/NOT_RUN
```

---

## 15. STOP conditions

A execucao futura deve parar imediatamente se qualquer condicao abaixo ocorrer:

```text
producao detectada
dado real detectado
escrita fora de TEST_PR59_
credencial em evidencia
JWT/cookie/header exposto
service_role usado indevidamente
cross-tenant indevido
proposta real gerada
estoque real alterado
politica financeira real alterada
erro sem rollback claro
```

Tambem devem ser tratados como STOP imediato:

```text
print de producao incluido em evidencia
PII detectada em payload, log ou snapshot
stack trace sensivel exposto
documento real de cliente usado
storage path real usado
alteracao de desconto comercial real
alteracao de faixa de premio real
qualquer necessidade de usar chave privilegiada fora do procedimento aprovado
incidente operacional sem owner definido
```

Apos STOP:

```text
1. Encerrar novas chamadas imediatamente.
2. Preservar somente evidencias sanitizadas.
3. Acionar responsavel pelo rollback, se houver escrita.
4. Classificar cenarios pendentes como BLOCKED ou NOT_RUN.
5. Registrar causa do STOP sem credenciais, sem PII e sem dado real.
6. Nao aplicar correcao tecnica no mesmo fluxo.
```

---

## 16. Rollback e limpeza futura

Antes de qualquer escrita futura autorizada, deve existir plano aprovado para:

```text
restaurar snapshot quando necessario
remover ou invalidar dados TEST_PR59_
confirmar diff zero para negativos
confirmar ausencia de escrita fora de TEST_PR59_
confirmar ausencia de proposta real
confirmar ausencia de estoque real alterado
confirmar ausencia de politica financeira real alterada
preservar evidencias sanitizadas
registrar responsavel e horario de conclusao da limpeza
```

Template de registro de rollback/limpeza:

```text
[ROLLBACK_LIMPEZA]
test_run_id: TEST_PR59_RUN_<YYYYMMDD>_<NNN>
ambiente: <staging|clone|snapshot>
responsavel: <nome/handle autorizado>
acionamento: <nao requerido|por STOP|por fim de janela|por divergencia>
objetos TEST_PR59_ afetados: <lista sanitizada>
objetos fora de TEST_PR59_ afetados: <deve ser zero; se nao for zero, FAIL/STOP>
acao de rollback: <referencia operacional aprovada, sem SQL de correcao nesta evidencia>
validacao pos-limpeza: <contagem/hash/status sanitizado>
status final: <concluido|pendente|blocked>
[/ROLLBACK_LIMPEZA]
```

---

## 17. Resultado final da PR #60

```text
TESTS_NOT_RUN
EXECUTION_BLOCKED_UNTIL_FORMAL_GO
```

Declaracao final:

```text
Esta PR cria somente o template de evidencia e prontidao para execucao futura.
Nenhum teste foi executado.
Nenhuma RPC foi chamada.
Nenhuma correcao tecnica esta autorizada.
Nenhum ambiente Supabase foi alterado.
A execucao futura permanece bloqueada ate GO formal explicito.
```

---

## 18. Proxima sequencia segura

| Proxima etapa | Condicao | Escopo permitido |
|---|---|---|
| #60-Execution | Somente apos aprovacao explicita e GO formal | Executar testes controlados em staging/clone/snapshot, registrar evidencias sanitizadas, parar em STOP condition. |
| #61 | Apos evidencias ou bloqueios suficientes | Grant review e proposta de correcao, ainda sem aplicar. |
| PRs futuras de correcao | Apos review e aprovacao | Correcoes pequenas por classe de risco, revisaveis e reversiveis. |
| Reexecucao/validacao pos-correcao | Apos correcao aprovada e aplicada | Reexecutar matriz relevante, validar diff, auditabilidade e regressao. |

Ordem segura:

```text
1. Merge documental da PR #60 se criterios forem atendidos.
2. Aguardar aprovacao explicita para #60-Execution.
3. Executar somente em staging/clone/snapshot com TEST_PR59_ e evidencia sanitizada.
4. Produzir #61 com grant review e proposta de correcao, ainda sem aplicar.
5. Abrir PRs futuras pequenas por classe de risco para correcoes aprovadas.
6. Reexecutar/validar pos-correcao em ambiente controlado.
```

---

## 19. Criterios de aceite desta PR documental

```text
[ ] apenas 1 arquivo Markdown criado
[ ] nenhum codigo alterado
[ ] nenhuma migration criada
[ ] nenhum SQL executavel de correcao
[ ] nenhuma credencial ou dado real
[ ] documento coerente com PR #58 e PR #59A
[ ] PR segura para merge documental
[ ] status TESTS_NOT_RUN mantido
[ ] execucao bloqueada ate GO formal
```
