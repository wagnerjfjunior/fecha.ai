# FECH.AI / MesaCliente — Fase 5B — Contrato de registro de operação financeira

**Status:** contrato inicial aberto; preflight obrigatório antes de qualquer migration  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5B — registrar operação financeira administrativa  
**Pré-requisito:** Fase 5A.1 aprovada  
**Data:** 2026-05-19

---

## 1. Objetivo da Fase 5B

A Fase 5B deve registrar uma operação financeira administrativa derivada de uma agenda persistida e de uma simulação de impacto previamente validada.

A 5B é a primeira etapa da trilha que grava operação financeira. Por isso, ela muda o nível de risco em relação à 5A.1:

```text
5A.1 = simula impacto, não grava operação.
5B   = registra operação financeira administrativa, ainda sem confirmar execução final.
5C   = confirma/cancela operação e aplica regras finais de estado.
```

A 5B não deve ser tratada como simples continuação da 5A.1. Ela precisa de contrato, preflight, migration e testes próprios.

---

## 2. Princípio central

A operação financeira registrada pela 5B deve nascer de dados soberanos do banco:

- `mesa_simulacoes`;
- `mesa_cliente_agendas_financeiras`;
- `mesa_cliente_fluxo_parcelas`;
- política financeira ativa/vigente;
- usuário autenticado via `auth.uid()`;
- tenant/empresa do corretor no banco;
- regras de elegibilidade já validadas no backend.

O frontend pode solicitar uma intenção de operação, mas não pode ser autoridade para empresa, taxa, política, valor-base da parcela, tenant ou permissões.

---

## 3. Escopo funcional

A 5B deve permitir registrar uma operação administrativa como intenção/rascunho/pendência de efetivação, conforme o vocabulário real permitido pelo schema.

Operações candidatas:

```text
antecipacao
postergacao
vpl
```

A fase deve aceitar apenas operações compatíveis com a agenda persistida e com as parcelas elegíveis.

A 5B deve persistir a operação em tabela financeira apropriada, preferencialmente a tabela já existente:

```text
public.mesa_cliente_fluxo_operacoes
```

Se o preflight provar que o schema atual não suporta o contrato com segurança, a migration da 5B deverá criar colunas/constraints ou tabela auxiliar, sem improviso.

---

## 4. Não escopo da 5B

A 5B não deve:

- alterar frontend;
- alterar parser;
- alterar Worker;
- alterar Make/n8n;
- confirmar operação final;
- cancelar operação final;
- aplicar alteração definitiva em agenda ou parcelas;
- recalcular tabela de venda;
- expor payload cliente-safe;
- aceitar `empresa_id` soberano do frontend;
- aceitar taxa financeira soberana do frontend;
- aceitar `politica_id` soberano do frontend;
- gravar seed permanente;
- criar operação confirmada diretamente, salvo decisão explícita posterior.

---

## 5. Diferença entre 5B e 5C

### 5B — registrar operação

A 5B registra a intenção/rascunho/pendência administrativa da operação.

Contrato lógico:

```text
persistencia = true
dml_financeiro = true
escopo_dml = operação financeira
altera_agenda = false
altera_parcelas = false
cliente_safe = false
status inicial = pendente/rascunho/equivalente real do schema
```

### 5C — confirmar/cancelar operação

A 5C será responsável por confirmar ou cancelar a operação registrada, com regras finais de auditoria, imutabilidade, lock e bloqueio de nova agenda quando houver operação confirmada.

Contrato lógico futuro:

```text
confirmar operação
cancelar operação
aplicar transição de status
preservar histórico/auditoria
bloquear conflito com operação confirmada
```

---

## 6. Assinatura candidata da RPC 5B

A assinatura final só deve ser fechada após o preflight 11 revelar o schema real de `mesa_cliente_fluxo_operacoes`, constraints, colunas, índices, policies e grants.

Assinatura candidata:

```text
public.mesa_cliente_registrar_operacao_financeira_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid,
  p_tipo_operacao text,
  p_parcelas jsonb,
  p_parametros jsonb default '{}'::jsonb
)
```

Possível alternativa se o schema favorecer operação por parcela:

```text
public.mesa_cliente_registrar_operacao_financeira_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid,
  p_parcela_id uuid,
  p_tipo_operacao text,
  p_valor_operacao numeric,
  p_data_destino date default null,
  p_parametros jsonb default '{}'::jsonb
)
```

Decisão pendente:

```text
A forma final depende do preflight 11.
```

---

## 7. Autoridade de dados

### Pode vir do frontend como intenção

- `p_simulacao_id`;
- `p_agenda_id`, se validado contra a simulação e a agenda ativa;
- `p_tipo_operacao`;
- `p_parcela_id` ou lista de parcelas;
- `valor_operacao` como intenção, limitado e recalculado/validado contra a parcela real;
- `data_destino` para postergação, validada;
- observação administrativa não soberana.

### Não pode vir do frontend como autoridade

- `empresa_id`;
- `corretor_id`;
- `empreendimento_id`;
- `politica_id`;
- taxa de antecipação;
- taxa de postergação;
- base de tempo;
- método de cálculo;
- valor atual da parcela;
- status final da operação;
- flags de permissão;
- checksum final;
- qualquer campo de tenant/autorização.

---

## 8. Regras de segurança

A RPC 5B deve ser `SECURITY DEFINER`, com `search_path` explícito:

```text
set search_path = public, pg_temp
```

Permissões esperadas:

```text
anon = sem EXECUTE
authenticated = EXECUTE
```

Validações obrigatórias:

- `auth.uid()` obrigatório;
- corretor ativo obrigatório;
- tenant derivado do banco;
- cross-tenant bloqueado;
- simulação existente;
- agenda ativa vinculada à simulação;
- parcelas vinculadas à agenda;
- política financeira ativa/vigente;
- operação compatível com flags de elegibilidade da parcela;
- operação não pode ser registrada se já houver operação confirmada conflitante;
- operação duplicada deve ser idempotente, não duplicar linha.

---

## 9. Idempotência

A idempotência da 5B deve ser calculada no banco, por checksum canônico.

O frontend não deve ser autoridade do checksum.

Campos candidatos para checksum canônico:

```text
empresa_id
simulacao_id
agenda_id
tipo_operacao
parcelas envolvidas
valor_operacao validado
p_data_referencia ou data_operacao
data_destino, quando aplicável
política financeira usada
versão do motor financeiro
```

Comportamento esperado:

```text
Primeira chamada = cria operação pendente/rascunho.
Segunda chamada equivalente = retorna a mesma operação com idempotente=true.
Chamada conflitante = bloqueia com erro claro.
```

---

## 10. Lock transacional

A 5B deve usar lock transacional para impedir corrida entre dois registros concorrentes da mesma simulação/agenda/operação.

Candidatos:

```text
SELECT ... FOR UPDATE na agenda ativa;
SELECT ... FOR UPDATE em operação existente equivalente;
pg_advisory_xact_lock com chave derivada de empresa_id + simulacao_id + agenda_id;
```

A escolha final depende do preflight 11 e da estrutura real de índices/constraints.

---

## 11. Auditoria mínima

A operação registrada deve permitir rastrear:

- quem registrou;
- quando registrou;
- empresa/tenant;
- simulação;
- agenda;
- parcelas envolvidas;
- tipo de operação;
- cálculo financeiro usado;
- política financeira usada;
- checksum/idempotência;
- status inicial;
- origem administrativa;
- payload normalizado de entrada;
- payload calculado pelo banco.

Se a tabela existente não possuir colunas suficientes, a migration da 5B deve criar estrutura adequada ou usar coluna JSONB auditável, com constraints mínimas.

---

## 12. Regras de DML permitidas

A 5B pode gravar operação financeira.

Permitido:

```text
INSERT/UPDATE idempotente em tabela de operações financeiras.
```

Proibido na 5B:

```text
UPDATE em mesa_cliente_agendas_financeiras para alterar valores/totais.
UPDATE em mesa_cliente_fluxo_parcelas para alterar valores/datas.
DELETE em agenda, parcelas ou operações.
INSERT de nova agenda.
INSERT de novas parcelas.
```

Observação:

```text
Se for necessário marcar uma operação anterior como substituída/cancelada, isso deve ser avaliado como regra da 5C, não assumido automaticamente na 5B.
```

---

## 13. Testes oficiais esperados

### 11 — Preflight read-only

Arquivo esperado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/11_preflight_registro_operacao_financeira_readonly.sql
```

Objetivo:

- mapear schema real de operações;
- mapear colunas, constraints, índices, policies e grants;
- validar suporte para lock/idempotência/auditoria;
- identificar status reais permitidos;
- decidir se a migration deve usar tabela existente ou criar complemento.

### 11A — Positivo transacional

Deve validar:

- fixture transacional;
- persistência de agenda via 4B;
- simulação de impacto via 5A;
- registro de operação via 5B;
- criação de uma operação pendente/rascunho;
- operação vinculada à empresa/simulação/agenda/parcela;
- cálculo/auditoria presentes;
- sem alteração de agenda/parcelas;
- rollback.

### 11B — Negativos transacionais

Deve validar:

- `anon` bloqueado;
- sem auth bloqueado;
- simulação inexistente bloqueada;
- agenda inexistente bloqueada;
- agenda de outro tenant bloqueada;
- parcela de outra agenda bloqueada;
- `empresa_id` no payload bloqueado;
- taxa financeira no payload bloqueada;
- política no payload bloqueada;
- valor negativo bloqueado;
- tipo de operação inválido bloqueado;
- operação sem elegibilidade bloqueada.

### 11C — Idempotência

Deve validar:

- duas chamadas equivalentes não duplicam operação;
- segunda chamada retorna `idempotente=true`;
- checksum canônico igual;
- count de operações permanece 1.

### 11D — Bloqueio por operação confirmada

Deve validar:

- se já houver operação confirmada conflitante, a 5B bloqueia novo registro incompatível;
- erro esperado deve ser explícito, preferencialmente `SQLSTATE 55000`.

### 11E — Zero mutação em agenda/parcelas

Deve validar:

- operação criada;
- agenda não alterada;
- parcelas não alteradas;
- checksum/totais da agenda permanecem iguais;
- somente a tabela de operações sofre DML permitido.

---

## 14. Preflight obrigatório antes da migration

Antes de criar qualquer migration da 5B, deve ser executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/11_preflight_registro_operacao_financeira_readonly.sql
```

Somente após o resultset completo do preflight será permitido decidir:

```text
1. usar mesa_cliente_fluxo_operacoes como tabela principal;
2. adaptar mesa_cliente_fluxo_operacoes com colunas/índices/constraints;
3. criar tabela auxiliar de operação/itens/auditoria;
4. fechar a assinatura real da RPC 5B;
5. criar migration e testes 11A/11B/11C/11D/11E.
```

---

## 15. Estado atual

```text
4A = aprovada
4B = aprovada
4C = aprovada
5A.1 = aprovada
5B = contrato aberto; preflight 11 pendente
```

---

## 16. Veredito

A 5B está aberta, mas ainda não está liberada para migration.

O próximo passo correto é executar o preflight 11 read-only e usar o schema real como fonte de decisão.

Aqui a regra é simples: antes de gravar dinheiro no banco, a gente mede a fundação. SQL financeiro sem preflight é tipo assinar contrato com caneta invisível: até parece bonito, mas na hora da auditoria vira assombração.
