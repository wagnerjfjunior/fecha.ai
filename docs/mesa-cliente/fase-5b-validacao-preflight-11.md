# FECH.AI / MesaCliente — Fase 5B — Validação do Preflight 11

**Status:** preflight 11 executado e analisado  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5B — registro administrativo de operação financeira  
**Arquivo executado:** `supabase/tests/mesa-cliente/engenharia-financeira/11_preflight_registro_operacao_financeira_readonly.sql`  
**Data:** 2026-05-19

---

## 1. Veredito executivo

O preflight 11 está **aprovado com WARN estrutural**.

Isso significa:

```text
Pode seguir para desenho da migration 5B.
Pode usar a tabela existente mesa_cliente_fluxo_operacoes como base.
Não pode pular migration estrutural.
Não pode criar RPC 5B ignorando idempotência, agenda_id e índices.
Não pode avançar para frontend antes dos testes 11A/11B/11C/11D/11E.
```

A tabela `public.mesa_cliente_fluxo_operacoes` existe, tem o núcleo financeiro necessário, RLS está ativo, DML direto está bloqueado para `authenticated`, `anon` não tem DML, os enums financeiros existem e a RPC candidata 5B ainda não existe, como esperado antes da migration.

Os WARNs não são impeditivos; eles são exatamente o motivo da migration 5B existir.

---

## 2. Resultado consolidado por bloco

| Bloco | Status | Interpretação |
|---|---:|---|
| 01_tabelas_obrigatorias | PASS | Base estrutural existe. |
| 02_colunas_mesa_cliente_fluxo_operacoes | PASS | Tabela de operações existe com 31 colunas. |
| 03_presenca_colunas_core_e_recomendadas_5b | WARN | Core ok, mas faltam colunas recomendadas para vínculo e idempotência. |
| 04_constraints_operacoes | PASS | Constraints principais existem, inclusive status e valores financeiros. |
| 05_indices_operacoes | WARN | Faltam índice de idempotência e índice empresa/simulação/agendada. |
| 06_rls_policies_operacoes | PASS | RLS ativo; SELECT tenant-safe; INSERT/UPDATE/DELETE direto bloqueados. |
| 07_grants_tabela_operacoes | PASS | `anon` sem DML; `authenticated` com SELECT direto, escrita só via RPC. |
| 08_enums_financeiros | PASS | Enums financeiros necessários existem. |
| 09_status_operacao_distribuicao_atual | INFO | Sem operações atuais confirmadas ou por flag. |
| 10_funcoes_dependencias_4b_5a_e_candidata_5b | PASS | 4B e 5A existem; 5B ainda ausente, esperado. |
| 11_readiness_para_contrato_5b | WARN | Schema usável, mas exige decisão de vínculo agenda/parcela e idempotência. |

---

## 3. Achados técnicos relevantes

### 3.1 Tabela base aprovada

A tabela oficial da 5B será:

```text
public.mesa_cliente_fluxo_operacoes
```

Ela já possui colunas essenciais:

```text
id
empresa_id
simulacao_id
empreendimento_id
politica_id
tipo_operacao
grupo_origem
grupo_destino
parcela_origem_id
parcela_destino_id
valor_movido
data_origem
data_destino
taxa_ano_pct
vpl_aplicado_pct
desconto_calculado
acrescimo_calculado
economia_liquida
premio_corretor_pct
visivel_cliente
confirmado
confirmado_por
confirmado_em
metadata
criado_por
created_at
valor_base
dias_calculo
status_premio
status_operacao
updated_at
```

### 3.2 Colunas faltantes para contrato forte da 5B

O preflight apontou ausência de:

```text
agenda_id
checksum_operacao
created_by
idempotency_key
parcela_id
```

Decisão técnica:

| Coluna ausente | Decisão 5B | Justificativa |
|---|---|---|
| `agenda_id` | adicionar | vínculo direto com a agenda persistida e filtro de lock/idempotência. |
| `checksum_operacao` | adicionar | idempotência canônica calculada no banco. |
| `created_by` | não adicionar | já existe `criado_por` com default `auth.uid()`. |
| `idempotency_key` | não adicionar | substituída por `checksum_operacao` soberano do banco. |
| `parcela_id` | não adicionar | já existem `parcela_origem_id` e `parcela_destino_id`; a 5B usará `parcela_origem_id` para a operação por parcela. |

---

## 4. Decisão oficial de schema para a migration 5B

A migration 5B deve alterar `public.mesa_cliente_fluxo_operacoes` adicionando:

```sql
agenda_id uuid null references public.mesa_cliente_agendas_financeiras(id) on delete set null;
checksum_operacao text null;
```

Também deve criar pelo menos estes índices:

```sql
create index if not exists idx_mcfo_empresa_simulacao_agenda_status
on public.mesa_cliente_fluxo_operacoes (empresa_id, simulacao_id, agenda_id, status_operacao, created_at desc);

create unique index if not exists uq_mcfo_checksum_operacao_ativo
on public.mesa_cliente_fluxo_operacoes (empresa_id, checksum_operacao)
where checksum_operacao is not null
  and status_operacao in ('simulada', 'confirmada');
```

Observação: se o banco exigir outra composição por performance real, a composição mínima não pode remover `empresa_id`, `checksum_operacao` e filtro de status ativo.

---

## 5. Status inicial oficial da operação 5B

O schema real permite:

```text
simulada
confirmada
cancelada
bloqueada
```

A 5B não deve inventar `pendente` ou `rascunho`, porque esses valores não existem na constraint atual.

Status inicial oficial:

```text
status_operacao = 'simulada'
confirmado = false
visivel_cliente = false
```

A confirmação/cancelamento fica para a Fase 5C.

---

## 6. Assinatura final aprovada da RPC 5B

A assinatura oficial da RPC 5B fica:

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
- a tabela real tem `parcela_origem_id` e `parcela_destino_id`;
- a primeira versão da 5B deve registrar **uma operação por parcela**;
- operação multi-parcela pode ser versão posterior, não precisa entrar agora;
- a assinatura é compatível com `antecipacao`, `postergacao` e `vpl`.

---

## 7. Autoridade dos dados

### Pode vir do frontend como intenção

```text
p_simulacao_id
p_agenda_id
p_tipo_operacao
p_parcela_id
p_data_referencia
p_data_destino
p_valor_operacao
observacao administrativa dentro de p_parametros
```

### Não pode vir do frontend como autoridade

A RPC deve bloquear `p_parametros` contendo chaves como:

```text
empresa_id
empreendimento_id
corretor_id
politica_id
taxa_ano_pct
taxa_antecipacao_ano_pct
taxa_postergacao_ano_pct
base_tempo
metodo_calculo
status_operacao
confirmado
confirmado_por
confirmado_em
visivel_cliente
checksum_operacao
idempotency_key
```

Esses dados devem ser derivados pelo banco.

---

## 8. Regras obrigatórias da RPC 5B

A RPC deve:

- exigir `auth.uid()`;
- localizar corretor ativo;
- validar tenant pelo banco;
- bloquear cross-tenant;
- validar simulação existente;
- validar agenda ativa vinculada à simulação;
- validar parcela pertencente à agenda;
- validar política financeira ativa/vigente;
- validar elegibilidade da parcela para `antecipacao`, `postergacao` ou `vpl`;
- recalcular valores no banco usando as funções financeiras já aprovadas;
- não confiar em taxa, política, valor-base ou tenant enviados pelo frontend;
- registrar operação com `status_operacao='simulada'`;
- gravar `visivel_cliente=false`;
- calcular `checksum_operacao` no banco;
- retornar idempotente sem duplicar quando a chamada for equivalente;
- bloquear nova operação conflitante quando já houver operação confirmada para a mesma simulação/agenda/parcela;
- não alterar agenda;
- não alterar parcelas.

---

## 9. Lock e idempotência

A RPC deve usar lock transacional. Estratégia mínima:

```text
SELECT ... FOR UPDATE na agenda ativa.
SELECT ... FOR UPDATE na parcela de origem.
Consulta por checksum_operacao antes do INSERT.
Índice único parcial em empresa_id + checksum_operacao para chamadas ativas.
```

A idempotência deve considerar, no mínimo:

```text
empresa_id
simulacao_id
agenda_id
parcela_id
tipo_operacao
valor_operacao validado
data_referencia
data_destino
politica_id
versao_motor = 5B.1
```

---

## 10. DML permitido e proibido

Permitido na 5B:

```text
INSERT em mesa_cliente_fluxo_operacoes.
SELECT FOR UPDATE em agenda/parcela/operação existente.
Retorno idempotente de operação já existente.
```

Proibido na 5B:

```text
UPDATE em mesa_cliente_agendas_financeiras.
UPDATE em mesa_cliente_fluxo_parcelas.
DELETE em qualquer tabela financeira.
INSERT em mesa_cliente_agendas_financeiras.
INSERT em mesa_cliente_fluxo_parcelas.
Confirmar operação.
Cancelar operação.
Expor payload cliente-safe.
```

---

## 11. Próximos arquivos oficiais

Após este documento, a sequência correta é:

```text
supabase/migrations/<timestamp>_mesa_cliente_fase_5b_registro_operacao_financeira.sql
supabase/tests/mesa-cliente/engenharia-financeira/11a_validacao_registro_operacao_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/11b_validacao_registro_operacao_financeira_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/11d_validacao_registro_operacao_financeira_confirmada_rollback.sql
supabase/tests/mesa-cliente/engenenharia-financeira/11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql
```

Atenção: o caminho correto dos testes é `engenharia-financeira`; qualquer variação de grafia deve ser corrigida antes do commit.

---

## 12. Conclusão

A 5B está liberada para migration e testes transacionais, mas com escopo limitado:

```text
registrar operação administrativa simulada;
criar vínculo forte com agenda;
criar checksum canônico;
garantir idempotência;
não alterar agenda;
não alterar parcelas;
não confirmar operação.
```

Essa é a divisão segura:

```text
5A = simula
5B = registra intenção administrativa
5C = confirma/cancela
```

Aqui o WARN virou direção, não bloqueio. O banco avisou: “dá para ir, mas coloca cinto, índice e checksum”.
