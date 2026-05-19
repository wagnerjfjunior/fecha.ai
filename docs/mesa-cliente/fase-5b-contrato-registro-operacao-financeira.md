# FECH.AI / MesaCliente — Fase 5B — Contrato de registro de operação financeira

**Status:** contrato fechado após preflight 11; liberado para migration e testes transacionais  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5B — registrar operação financeira administrativa  
**Pré-requisito:** Fase 5A.1 aprovada  
**Documento de validação:** `docs/mesa-cliente/fase-5b-validacao-preflight-11.md`  
**Data:** 2026-05-19

---

## 1. Objetivo da Fase 5B

A Fase 5B registra uma operação financeira administrativa derivada de uma agenda persistida e de uma simulação de impacto previamente validada.

A 5B é a primeira etapa da trilha que grava operação financeira. Por isso, ela muda o nível de risco em relação à 5A.1:

```text
5A.1 = simula impacto, não grava operação.
5B   = registra operação financeira administrativa simulada.
5C   = confirma/cancela operação e aplica regras finais de estado.
```

A 5B não deve ser tratada como simples continuação da 5A.1. Ela tem contrato, preflight, migration e testes próprios.

---

## 2. Veredito do preflight 11

O preflight 11 foi executado e retornou:

```text
PASS estrutural com WARNs esperados.
```

Interpretação oficial:

```text
A tabela public.mesa_cliente_fluxo_operacoes pode ser usada como base da 5B.
A migration 5B precisa adicionar vínculo forte com agenda e idempotência canônica.
Os WARNs não bloqueiam a fase; eles definem o escopo da migration.
```

Achados relevantes:

- tabelas obrigatórias existem;
- `mesa_cliente_fluxo_operacoes` existe e possui 31 colunas;
- colunas core estão presentes;
- RLS está ativo;
- DML direto para `authenticated` está bloqueado por policies `false`;
- `anon` não possui DML;
- enums financeiros existem;
- status permitidos em `status_operacao`: `simulada`, `confirmada`, `cancelada`, `bloqueada`;
- faltam `agenda_id` e `checksum_operacao`;
- não existe índice de idempotência;
- a RPC 5B ainda não existe, como esperado antes da migration.

---

## 3. Princípio central

A operação financeira registrada pela 5B deve nascer de dados soberanos do banco:

- `mesa_simulacoes`;
- `mesa_cliente_agendas_financeiras`;
- `mesa_cliente_fluxo_parcelas`;
- `mesa_cliente_politicas_financeiras`;
- usuário autenticado via `auth.uid()`;
- tenant/empresa derivado do banco;
- regras de elegibilidade já validadas no backend.

O frontend pode solicitar intenção de operação, mas não pode ser autoridade para empresa, taxa, política, valor-base da parcela, tenant, permissões, status ou checksum.

---

## 4. Escopo funcional

A 5B deve registrar uma operação administrativa com status inicial real permitido pelo schema:

```text
status_operacao = 'simulada'
confirmado = false
visivel_cliente = false
```

Operações permitidas:

```text
antecipacao
postergacao
vpl
```

A primeira versão da 5B registra **uma operação por parcela**. Operação multi-parcela fica fora desta fase.

---

## 5. Não escopo da 5B

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
- aceitar `status_operacao` do frontend;
- aceitar `checksum_operacao` ou `idempotency_key` do frontend;
- gravar seed permanente;
- criar operação confirmada diretamente.

---

## 6. Diferença entre 5B e 5C

### 5B — registrar operação simulada

Contrato lógico:

```text
persistencia = true
dml_financeiro = true
escopo_dml = operação financeira
altera_agenda = false
altera_parcelas = false
cliente_safe = false
status_operacao = simulada
confirmado = false
```

### 5C — confirmar/cancelar operação

Contrato lógico futuro:

```text
confirmar operação
cancelar operação
aplicar transição de status
preencher confirmado_por/confirmado_em quando confirmar
preservar histórico/auditoria
bloquear conflito com operação confirmada
```

---

## 7. Assinatura final da RPC 5B

Assinatura oficial:

```sql
public.mesa_cliente_registrar_operacao_financeira_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid,
  p_tipo_operacao text,
  p_parcela_id uuid,
  p_data_referencia date default current_date,
  p_data_destino date default null,
  p_valor_operacao numeric default null,
  p_parametros jsonb default '{}'::jsonb
)
```

Racional:

- a 5A retorna alternativas por `parcela_id`;
- a tabela real possui `parcela_origem_id` e `parcela_destino_id`;
- a 5B deve registrar uma operação por parcela;
- `p_valor_operacao` é intenção e deve ser limitado/recalculado pelo banco;
- `p_data_destino` só é obrigatório para postergação quando aplicável;
- `p_parametros` serve apenas para observação administrativa e metadados não soberanos.

---

## 8. Alteração estrutural aprovada para a migration 5B

A migration 5B deve adicionar em `public.mesa_cliente_fluxo_operacoes`:

```sql
alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists agenda_id uuid null references public.mesa_cliente_agendas_financeiras(id) on delete set null;

alter table public.mesa_cliente_fluxo_operacoes
  add column if not exists checksum_operacao text null;
```

Índices mínimos:

```sql
create index if not exists idx_mcfo_empresa_simulacao_agenda_status
on public.mesa_cliente_fluxo_operacoes (empresa_id, simulacao_id, agenda_id, status_operacao, created_at desc);

create unique index if not exists uq_mcfo_checksum_operacao_ativo
on public.mesa_cliente_fluxo_operacoes (empresa_id, checksum_operacao)
where checksum_operacao is not null
  and status_operacao in ('simulada', 'confirmada');
```

Decisões sobre colunas ausentes apontadas no preflight:

| Coluna | Decisão |
|---|---|
| `agenda_id` | adicionar |
| `checksum_operacao` | adicionar |
| `created_by` | não adicionar; usar `criado_por` existente |
| `idempotency_key` | não adicionar; usar `checksum_operacao` calculado no banco |
| `parcela_id` | não adicionar; usar `parcela_origem_id` e `parcela_destino_id` existentes |

---

## 9. Autoridade de dados

### Pode vir do frontend como intenção

- `p_simulacao_id`;
- `p_agenda_id`, validado contra simulação e agenda ativa;
- `p_tipo_operacao`;
- `p_parcela_id`, validado contra agenda;
- `p_data_referencia`;
- `p_data_destino`, quando aplicável;
- `p_valor_operacao`, limitado e recalculado contra a parcela real;
- observação administrativa não soberana.

### Não pode vir do frontend como autoridade

A RPC deve bloquear em `p_parametros`:

- `empresa_id`;
- `empreendimento_id`;
- `corretor_id`;
- `politica_id`;
- `taxa_ano_pct`;
- `taxa_antecipacao_ano_pct`;
- `taxa_postergacao_ano_pct`;
- `base_tempo`;
- `metodo_calculo`;
- `status_operacao`;
- `confirmado`;
- `confirmado_por`;
- `confirmado_em`;
- `visivel_cliente`;
- `checksum_operacao`;
- `idempotency_key`.

---

## 10. Regras de segurança

A RPC 5B deve ser `SECURITY DEFINER`, com `search_path` explícito:

```sql
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
- parcela vinculada à agenda;
- política financeira ativa/vigente;
- tipo de operação válido;
- operação compatível com flags de elegibilidade da parcela;
- valor financeiro não negativo;
- data destino válida para postergação;
- operação não pode ser registrada se já houver operação confirmada conflitante;
- operação duplicada deve ser idempotente, não duplicar linha.

---

## 11. Idempotência

A idempotência da 5B deve ser calculada no banco, por `checksum_operacao` canônico.

O frontend não deve ser autoridade do checksum.

Campos mínimos do checksum:

```text
empresa_id
simulacao_id
agenda_id
parcela_id
tipo_operacao
valor_operacao_validado
data_referencia
data_destino
politica_id
versao_motor = 5B.1
```

Comportamento esperado:

```text
Primeira chamada = cria operação simulada.
Segunda chamada equivalente = retorna a mesma operação com idempotente=true.
Chamada conflitante = bloqueia com erro claro.
```

---

## 12. Lock transacional

A 5B deve usar lock transacional para impedir corrida entre dois registros concorrentes da mesma simulação/agenda/parcela.

Estratégia mínima:

```text
SELECT ... FOR UPDATE na agenda ativa.
SELECT ... FOR UPDATE na parcela de origem.
Consulta por checksum_operacao antes do INSERT.
Índice único parcial em empresa_id + checksum_operacao para operações ativas.
```

---

## 13. Auditoria mínima

A operação registrada deve permitir rastrear:

- quem registrou: `criado_por`;
- quando registrou: `created_at`;
- empresa/tenant: `empresa_id`;
- simulação: `simulacao_id`;
- agenda: `agenda_id`;
- parcela de origem: `parcela_origem_id`;
- tipo de operação: `tipo_operacao`;
- cálculo financeiro usado;
- política financeira usada: `politica_id`;
- checksum/idempotência: `checksum_operacao`;
- status inicial: `status_operacao`;
- payload normalizado/calculado pelo banco em `metadata`.

---

## 14. Regras de DML permitidas

Permitido:

```text
INSERT em mesa_cliente_fluxo_operacoes.
SELECT FOR UPDATE em agenda/parcela/operação existente.
Retorno idempotente de operação já existente.
```

Proibido na 5B:

```text
UPDATE em mesa_cliente_agendas_financeiras.
UPDATE em mesa_cliente_fluxo_parcelas.
DELETE em agenda, parcelas ou operações.
INSERT de nova agenda.
INSERT de novas parcelas.
Confirmar operação.
Cancelar operação.
```

---

## 15. Testes oficiais esperados

### 11A — Positivo transacional

Deve validar:

- fixture transacional;
- persistência de agenda via 4B;
- simulação de impacto via 5A;
- registro de operação via 5B;
- criação de uma operação `simulada`;
- operação vinculada a empresa/simulação/agenda/parcela;
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
- status no payload bloqueado;
- checksum/idempotency no payload bloqueado;
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

## 16. Estado atual

```text
4A = aprovada
4B = aprovada
4C = aprovada
5A.1 = aprovada
5B = contrato fechado; liberada para migration e testes 11A-11E
```

---

## 17. Veredito

A 5B está liberada para implementação controlada.

O próximo passo correto é criar:

```text
supabase/migrations/<timestamp>_mesa_cliente_fase_5b_registro_operacao_financeira.sql
```

Depois, criar e executar os testes:

```text
11A positivo
11B negativos
11C idempotência
11D operação confirmada
11E zero mutação agenda/parcelas
```

Nada de frontend ainda. Primeiro a escrita financeira precisa provar que sabe escrever sem bagunçar a agenda — caneta boa escreve, caneta ruim apaga o contrato inteiro.
