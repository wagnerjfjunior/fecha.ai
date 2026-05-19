# MesaCliente Engenharia Financeira — Índice operacional de testes

Este diretório contém os scripts de validação da Engenharia Financeira do MesaCliente.

## Contexto operacional

O projeto trabalha com banco Supabase de produção única. Regra permanente:

```text
Preflight read-only antes de migration.
Teste com BEGIN + ROLLBACK antes de considerar fase aprovada.
Nenhum frontend antes de RPC e segurança validadas.
Nenhuma premissa de schema sem consulta ao banco real.
```

Produção não é laboratório. Teste que grava sem rollback é quase churrasco dentro do datacenter: até pode esquentar, mas ninguém vai aplaudir.

---

## Fontes normativas

Ordem de referência:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-validacao-final-json-first.md`
4. `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md`
5. `docs/mesa-cliente/fase-4c-cliente-safe-fechamento.md`
6. `docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md`
7. `docs/mesa-cliente/fase-5a-preflight-10-resultado-readonly.md`
8. `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md`
9. `docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md`
10. `docs/mesa-cliente/fase-5b-validacao-preflight-11.md`
11. `docs/mesa-cliente/fase-5b-validacao-11a-registro-operacao-financeira.md`
12. `docs/mesa-cliente/fase-5b-validacao-11b-negativos-registro-operacao-financeira.md`
13. `docs/mesa-cliente/fase-5b-validacao-11c-idempotencia-registro-operacao-financeira.md`
14. Este README como índice operacional da pasta de testes.

---

## Sequência segura de execução

### Etapa 00/01 — Hardening inicial de produção única

#### `00_preflight_producao_readonly.sql`

Uso: antes da migration de hardening.

Características:

- somente `SELECT`;
- não cria dados;
- não altera schema;
- seguro para SQL Editor da produção.

Valida tabelas obrigatórias, funções obrigatórias, RLS, policies, grants, duplicidade de policies/índices e triggers/funções de integridade.

#### `01_postcheck_producao_readonly.sql`

Uso: depois da migration de hardening.

Características:

- somente `SELECT`;
- não cria dados;
- não altera schema;
- seguro para SQL Editor da produção.

Resultado esperado: blocos críticos em `PASS`.

---

## Fase 4A — Agenda financeira JSON-first sem persistência

**Status:** aprovada.

### Preflight legado/transição

#### `07_preflight_agenda_legada_readonly.sql`

Objetivo:

- verificar se migrations legadas persistentes da antiga 4A foram aplicadas;
- verificar se função legada existia no banco;
- verificar grants;
- contar registros financeiros antes da transição;
- orientar se o caminho era arquivar migrations antigas ou criar correção.

Conclusão operacional registrada:

- migrations legadas não estavam aplicadas;
- função legada não existia;
- tabelas financeiras estavam sem registros permanentes;
- caminho seguro era seguir para JSON-first.

### Testes oficiais 4A

#### `07a_validacao_agenda_financeira_json_first_rollback.sql`

Status: aprovado.

Valida geração positiva da agenda em JSON, `cliente_safe=false`, `persistencia=false`, `dml_financeiro=false`, datas, periodicidade simbólica, totalização e zero DML em `mesa_cliente_fluxo_parcelas` e `mesa_cliente_fluxo_operacoes`.

#### `07b_validacao_agenda_financeira_json_first_negativos_rollback.sql`

Status: aprovado.

Valida bloqueios de `anon`, simulação inexistente, `empresa_id` fake no payload, item com `empresa_id` fake, valor negativo, grupo desconhecido, periodicidade fraudada, periodicidade simbólica marcada como negociável e zero DML financeiro.

---

## Fase 4B — Persistência segura da agenda financeira

**Status:** aprovada em rollback transacional.

### Preflight 4B

#### `08_preflight_persistencia_agenda_readonly.sql`

Status: aprovado.

Valida schema real antes de criar persistência: tabelas, colunas, constraints, indexes, grants e policies.

Achado importante:

```text
mesa_cliente_fluxo_operacoes usa status_operacao, não coluna genérica status.
```

### Testes oficiais 4B

#### `08a_validacao_persistencia_agenda_financeira_rollback.sql`

Status: aprovado.

Valida fixture transacional, RPC 4B, persistência em `mesa_cliente_agendas_financeiras`, persistência em `mesa_cliente_fluxo_parcelas`, totais, periodicidade bloqueada, datas resolvidas, zero operação financeira e rollback.

#### `08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql`

Status: aprovado.

Valida duas chamadas com a mesma entrada, sem duplicar agenda/parcelas, `idempotente=true` na segunda chamada, checksum consistente e rollback.

#### `08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql`

Status: aprovado.

Valida grants da RPC, simulação inexistente, `empresa_id` fake no payload, item com `empresa_id` fake, valor negativo, grupo desconhecido, periodicidade fraudada, periodicidade simbólica marcada como negociável, zero DML permanente e rollback.

#### `08d_validacao_persistencia_agenda_financeira_operacao_confirmada_rollback.sql`

Status: aprovado.

Valida agenda transacional, operação confirmada fixture, bloqueio de substituição de agenda com `SQLSTATE 55000`, preservação da agenda original, parcelas originais não recriadas indevidamente, zero operação extra e rollback.

Erros corrigidos durante o 08D:

- uso de colunas inexistentes como `cliente_email`;
- uso de coluna inexistente `inserted_at`;
- suposição de `a.ativa`;
- tabela temporária inacessível sob troca de role;
- constraint real aceitava `mensal`, não `mensais`.

---

## Fase 4C — Agenda financeira cliente-safe

**Status:** aprovada.

### Preflight 4C

#### `09_preflight_agenda_financeira_cliente_safe_readonly.sql`

Status: executado e fase concluída por documentação de fechamento.

Valida tabelas reais envolvidas na leitura cliente-safe, colunas de `mesa_cliente_agendas_financeiras`, `mesa_cliente_fluxo_parcelas`, `mesa_simulacoes`, grants, policies, existência das RPCs 4A/4B, campos sensíveis e base técnica para RPC 4C.

### Critérios 4C aprovados

```text
cliente_safe=true
anon bloqueado
authenticated executa
cross-tenant bloqueado
simulação inexistente bloqueada
agenda inexistente tratada
retorno sem VPL, prêmio, comissão, política, metadata bruta, checksum e payload bruto
sem DML
```

---

## Fase 5A.1 — Simular impacto financeiro com agenda persistida

**Status:** aprovada.

Documento canônico:

```text
docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md
```

Resultado final:

```text
docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md
```

Migrations:

```text
supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
supabase/migrations/20260518194500_fix_mesa_cliente_5a_remover_agenda_id_operacoes.sql
```

RPC validada:

```text
public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)
```

Contrato validado:

```text
agenda-first
administrativa
cliente_safe=false
persistencia=false
dml_financeiro=false
anon bloqueado
authenticated executa
sem seed permanente
sem DML financeiro
sem alterar agenda, parcelas ou operações
```

### Preflight oficial/canônico 5A.1

#### `10_preflight_simulacao_impacto_agenda_persistida_readonly.sql`

Resultado original:

```text
13_operational_interpretation = FAIL
```

Motivo:

```text
Ausência de base mínima operacional permanente.
```

Resolução:

```text
Criado e executado 10P transacional, sem seed permanente.
```

### Preparação transacional da base mínima 5A.1

#### `10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql`

Status: aprovado.

### Testes oficiais 5A.1

#### `10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql`

Status: aprovado.

Valida fixture transacional, persistência da agenda via RPC 4B, chamada positiva da RPC 5A.1, flags administrativas, alternativas, recomendação, política `composto/dias_365`, zero operação financeira e rollback.

#### `10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql`

Status: aprovado.

Valida `anon` sem execute, sem auth bloqueado, simulação inexistente, `empresa_id` no payload bloqueado, valor negativo, modo inválido, agenda inexistente e rollback.

#### `10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql`

Status: aprovado.

Valida flags `persistencia=false` e `dml_financeiro=false`, contagens de agendas/parcelas/operações inalteradas, checksum/totais da agenda inalterados e rollback.

Resultado crítico do 10C:

```text
agendas_before = agendas_after = 1
parcelas_before = parcelas_after = 6
operacoes_before = operacoes_after = 0
checksum_before = checksum_after
valor_total = 29500.5
qtd_parcelas = 6
```

### Correções registradas na validação 5A.1

- 10A: correção de escopo CTE;
- RPC 5A.1: removida dependência indevida de `o.agenda_id`;
- 10B: removida temp table por fragilidade com `SET LOCAL ROLE authenticated`.

### Preflight exploratório arquivado

O arquivo abaixo não é oficial nesta pasta:

```text
10_preflight_impacto_financeiro_readonly.sql
```

Ele foi movido para:

```text
docs/mesa-cliente/rascunhos-sql/preflights-exploratorios/10_preflight_impacto_financeiro_readonly.sql
```

---

## Fase 5B — Registrar operação financeira administrativa

**Status:** em validação transacional. 11A, 11B e 11C aprovados; 11D/11E pendentes.

Documento canônico:

```text
docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md
```

Validação do preflight:

```text
docs/mesa-cliente/fase-5b-validacao-preflight-11.md
```

Validação 11A:

```text
docs/mesa-cliente/fase-5b-validacao-11a-registro-operacao-financeira.md
```

Validação 11B:

```text
docs/mesa-cliente/fase-5b-validacao-11b-negativos-registro-operacao-financeira.md
```

Validação 11C:

```text
docs/mesa-cliente/fase-5b-validacao-11c-idempotencia-registro-operacao-financeira.md
```

### Preflight oficial 5B

#### `11_preflight_registro_operacao_financeira_readonly.sql`

Status: aprovado com WARN estrutural esperado.

Valida tabelas obrigatórias, schema real de `mesa_cliente_fluxo_operacoes`, colunas, constraints, índices, RLS, policies, grants, enums financeiros, dependências 4B/5A e ausência esperada da RPC 5B antes da migration.

Resultado consolidado:

```text
Tabela base aprovada: public.mesa_cliente_fluxo_operacoes
Core estrutural: PASS
RLS/policies/grants: PASS
Enums financeiros: PASS
Índices/idempotência: WARN esperado
Colunas recomendadas 5B: WARN esperado
Readiness 5B: WARN que define migration, não bloqueio
```

Decisões fechadas após o preflight:

```text
Adicionar agenda_id.
Adicionar checksum_operacao.
Não adicionar created_by; usar criado_por existente.
Não adicionar idempotency_key; usar checksum_operacao calculado no banco.
Não adicionar parcela_id; usar parcela_origem_id/parcela_destino_id existentes.
Status inicial oficial: status_operacao='simulada', confirmado=false, visivel_cliente=false.
```

Assinatura oficial da RPC 5B:

```text
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

### Migration 5B

```text
supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
```

Status: executada com sucesso no Supabase.

### Testes oficiais 5B

#### `11a_validacao_registro_operacao_financeira_rollback.sql`

Status: aprovado.

Valida fixture transacional, persistência de agenda via 4B, registro positivo via RPC 5B, `fase=5B_REGISTRO_OPERACAO_FINANCEIRA`, `cliente_safe=false`, `persistencia=true`, `dml_financeiro=true`, `escopo_dml=operacao_financeira`, operação `simulada`, `confirmado=false`, `visivel_cliente=false`, `agenda_id`, `parcela_origem_id`, `checksum_operacao`, cálculo composto/dias_365, agenda não mutada, parcelas não mutadas e rollback.

Correção aplicada antes da aprovação:

```text
Removida a faixa fixture 6.01 até 999 porque a constraint real mesa_premio_faixas_intervalo_check não aceita faixa acima do vpl_max_pct=6.
```

#### `11b_validacao_registro_operacao_financeira_negativos_rollback.sql`

Status: aprovado.

Valida `anon` sem execute, sem auth bloqueado, simulação inexistente, agenda inexistente, parcela inexistente, `empresa_id` no payload bloqueado, `taxa_ano_pct` bloqueada, `status_operacao` bloqueado, `checksum_operacao`/`idempotency_key` bloqueados, valor negativo, tipo inválido, `p_parametros` não objeto, postergação sem `data_destino`, parcela simbólica, zero operações criadas pelos negativos e rollback.

#### `11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql`

Status: aprovado.

Valida primeira chamada criando operação, segunda chamada reutilizando a mesma operação, idempotência por `checksum_operacao` calculado no banco, ausência de duplicidade em `mesa_cliente_fluxo_operacoes`, agenda não mutada, parcelas não mutadas, flags do contrato 5B preservadas e rollback.

Resultado crítico do 11C:

```text
primeira chamada: idempotente=false
segunda chamada: idempotente=true
operacao_id_primeira = operacao_id_segunda
checksum_primeira = checksum_segunda
before.operacoes = 0
mid_apos_primeira.operacoes = 1
after_apos_segunda.operacoes = 1
agenda_checksum_before = agenda_checksum_after
parcelas_before = parcelas_after = 6
valor_total_parcelas_before = valor_total_parcelas_after = 29500.50
```

#### `11d_validacao_registro_operacao_financeira_confirmada_rollback.sql`

Status: pendente.

#### `11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql`

Status: pendente.

---

## Fases futuras

### Fase 5C — Confirmar/cancelar operação financeira

Pendente.

Escopo provável:

- confirmar operação;
- cancelar operação;
- histórico/auditoria;
- bloqueio de alteração indevida em agenda já confirmada.

### Integração Front/BFF

Pendente. Ainda proibida antes do contrato da escrita financeira estar fechado e validado por testes.

---

## Regra de ouro da pasta de testes

Não execute teste integrador em produção única sem verificar:

1. se ele começa com `BEGIN`;
2. se termina com `ROLLBACK`;
3. se não contém DDL destrutivo inesperado;
4. se fixtures são transacionais;
5. se não usa colunas presumidas sem preflight;
6. se não concede privilégio para `anon`;
7. se não mexe em frontend/parser/Worker/Make/n8n;
8. se o resultado esperado está documentado.

---

## Estado operacional atual

```text
4A aprovada.
4B aprovada em rollback transacional.
4C aprovada.
5A.1 aprovada.
5B em validação transacional: migration executada, 11A, 11B e 11C aprovados, 11D/11E pendentes.
```
