# MesaCliente Engenharia Financeira — Índice operacional de testes

Este diretório contém os scripts de validação da Engenharia Financeira do MesaCliente.

## Contexto operacional

O projeto trabalha com banco Supabase de produção única. Regra permanente:

```text
Preflight read-only antes de migration.
Teste com BEGIN + ROLLBACK antes de considerar fase aprovada.
Nenhum frontend antes de RPC e segurança validadas.
Nenhuma premissa de schema sem consulta ao banco real.
Smoke pós-produção não cria fixture, não cria função temporária e não executa DDL/DML.
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
6. `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md`
7. `docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md`
8. `docs/mesa-cliente/fase-5c-fechamento-tecnico.md`
9. `docs/mesa-cliente/fase-5d-fechamento-tecnico.md`
10. `docs/mesa-cliente/fase-5d-smoke-pos-producao.md`
11. `docs/mesa-cliente/fase-5d-smoke-pos-producao-execucao.md`
12. `docs/mesa-cliente/engenharia-financeira-roadmap-execucao-ate-mesa-cliente.md`
13. Este README como índice operacional da pasta de testes.

---

## Sequência segura de execução

### Etapa 00/01 — Hardening inicial de produção única

#### `00_preflight_producao_readonly.sql`

Status: executado na trilha inicial.

Uso: antes da migration de hardening.

Características:

- somente `SELECT`;
- não cria dados;
- não altera schema;
- seguro para SQL Editor da produção.

Valida tabelas obrigatórias, funções obrigatórias, RLS, policies, grants, duplicidade de policies/índices e triggers/funções de integridade.

#### `01_postcheck_producao_readonly.sql`

Status: executado na trilha inicial.

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

Status: concluído.

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

**Status:** aprovada.

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

Status: aprovado após preparação transacional.

Resultado original teve `13_operational_interpretation = FAIL` por ausência de base mínima operacional permanente.

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

**Status:** aprovada em validação transacional.

Documento canônico:

```text
docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md
```

Fechamento técnico:

```text
docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md
```

### Preflight oficial 5B

#### `11_preflight_registro_operacao_financeira_readonly.sql`

Status: aprovado com WARN estrutural esperado.

Valida tabelas obrigatórias, schema real de `mesa_cliente_fluxo_operacoes`, colunas, constraints, índices, RLS, policies, grants, enums financeiros, dependências 4B/5A e ausência esperada da RPC 5B antes da migration.

Decisões fechadas após o preflight:

```text
Adicionar agenda_id.
Adicionar checksum_operacao.
Não adicionar created_by; usar criado_por existente.
Não adicionar idempotency_key; usar checksum_operacao calculado no banco.
Não adicionar parcela_id; usar parcela_origem_id/parcela_destino_id existentes.
Status inicial oficial: status_operacao='simulada', confirmado=false, visivel_cliente=false.
```

### Migration 5B

```text
supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
```

Status: executada com sucesso no Supabase.

### Testes oficiais 5B

#### `11a_validacao_registro_operacao_financeira_rollback.sql`

Status: aprovado.

Valida registro positivo de operação financeira simulada, `cliente_safe=false`, `persistencia=true`, `dml_financeiro=true`, operação `simulada`, `confirmado=false`, `visivel_cliente=false`, `agenda_id`, `parcela_origem_id`, `checksum_operacao`, cálculo composto/dias_365, agenda não mutada, parcelas não mutadas e rollback.

#### `11b_validacao_registro_operacao_financeira_negativos_rollback.sql`

Status: aprovado.

Valida `anon` sem execute, sem auth bloqueado, simulação inexistente, agenda inexistente, parcela inexistente, payload autoritativo bloqueado, valor negativo, tipo inválido, `p_parametros` não objeto, postergação sem `data_destino`, parcela simbólica, zero operações criadas pelos negativos e rollback.

#### `11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql`

Status: aprovado.

Valida primeira chamada criando operação, segunda chamada reutilizando a mesma operação, idempotência por `checksum_operacao` calculado no banco, ausência de duplicidade, agenda não mutada, parcelas não mutadas e rollback.

#### `11d_validacao_registro_operacao_financeira_confirmada_rollback.sql`

Status: aprovado.

Valida operação confirmada fixture, mesmo checksum reaproveita operação confirmada, operação conflitante bloqueia com `SQLSTATE 55000`, operação confirmada preservada, sem duplicidade, agenda não mutada, parcelas não mutadas e rollback.

#### `11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql`

Status: aprovado.

Valida que a RPC altera somente `mesa_cliente_fluxo_operacoes`, agenda e parcelas preservadas por hash completo, somente operações incrementa uma linha, operação nasce simulada, não confirmada e não cliente-safe, rollback.

---

## Fase 5C — Confirmar/cancelar operação financeira

**Status:** fechada tecnicamente.

Fechamento técnico:

```text
docs/mesa-cliente/fase-5c-fechamento-tecnico.md
```

Migration:

```text
supabase/migrations/20260519182000_mesa_cliente_fase_5c_confirmacao_cancelamento_operacao_financeira.sql
```

RPC validada:

```text
public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)
```

### Testes oficiais 5C

#### `12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql`

Status: aprovado.

#### `12a_validacao_confirmar_operacao_financeira_rollback.sql`

Status: aprovado.

Valida confirmação positiva de operação financeira simulada.

#### `12b_validacao_cancelar_operacao_financeira_simulada_rollback.sql`

Status: aprovado.

Valida cancelamento positivo de operação financeira simulada.

#### `12c_validacao_negativos_seguranca_confirmacao_cancelamento_rollback.sql`

Status: aprovado.

Valida negativos, segurança, grants, payload autoritativo e transições bloqueadas.

#### `12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql`

Status: aprovado.

Valida idempotência da confirmação e do cancelamento.

#### `12e_validacao_zero_mutacao_rigido_confirmacao_cancelamento_rollback.sql`

Status: aprovado.

Valida zero mutação rígido de operação, agenda e parcelas fora do escopo permitido.

---

## Fase 5D — Leitura administrativa de operações financeiras

**Status:** fechada tecnicamente, mergeada na `main` e com smoke estrutural pós-produção aprovado com `SKIP_DATA`.

Fechamento técnico:

```text
docs/mesa-cliente/fase-5d-fechamento-tecnico.md
```

Smoke pós-produção:

```text
docs/mesa-cliente/fase-5d-smoke-pos-producao.md
docs/mesa-cliente/fase-5d-smoke-pos-producao-execucao.md
```

Migration:

```text
supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
```

RPCs validadas:

```text
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb)
public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb)
```

### Testes oficiais 5D

#### `13_preflight_leitura_operacoes_financeiras_admin_readonly.sql`

Status: validado.

Valida preflight estrutural e contrato read-only.

#### `13a_validacao_listar_operacoes_financeiras_admin_rollback.sql`

Status: validado.

Valida listagem administrativa positiva.

#### `13b_validacao_obter_operacao_financeira_admin_rollback.sql`

Status: validado.

Valida detalhe administrativo positivo.

#### `13c_validacao_seguranca_leitura_operacoes_admin_rollback.sql`

Status: validado.

Valida segurança, negativos e isolamento. O arquivo original foi mantido e corrigido sem remoção de cobertura crítica.

#### `13cv2_validacao_seguranca_leitura_operacoes_admin_rollback.sql`

Status: validado.

Versão alternativa segura criada sem sobrescrever o 13C original.

#### `13d_validacao_zero_dml_readonly_rigido_leitura_operacoes_admin_rollback.sql`

Status: validado.

Valida zero DML/read-only rígido com checagem de `xmin`.

#### `13e_validacao_filtros_paginacao_ordenacao_leitura_operacoes_admin_rollback.sql`

Status: validado.

Valida filtros, paginação, ordenação e allowlists.

#### `13_smoke_pos_producao_leitura_operacoes_admin_readonly.sql`

Status: aprovado estruturalmente com `SKIP_DATA`.

Resultado:

```text
00_funcoes_5d_existentes = PASS
01_alvo_admin_operacao_real = SKIP_DATA
02_listagem_admin_readonly_smoke = SKIP_DATA
03_detalhe_admin_readonly_smoke = SKIP_DATA
04_contrato_readonly_minimo = SKIP_DATA
05_negativos_allowlist_nao_executados_no_smoke_readonly = INFO
99_smoke_readonly_notice = INFO
```

Interpretação:

```text
As RPCs existem no ambiente.
O smoke executa em READ ONLY estrito.
Não houve DDL, DML ou fixture.
A validação funcional com dado real ficou pendente por ausência de operação financeira real acessível.
```

---

## Fase 6 — Resumos administrativos e visão cliente-safe / handoff para integração

**Status:** próxima fase canônica.

Primeiros arquivos previstos:

```text
docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md
supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
```

Regras de entrada:

```text
Contrato antes de migration.
Preflight read-only antes de migration.
Nenhum frontend antes da validação cliente-safe.
Nenhuma regra financeira nova hardcoded no app.
Nenhuma alteração no parser, Worker, Make/n8n ou motor financeiro sem autorização explícita.
```

---

## Regra de ouro da pasta de testes

Não execute teste integrador em produção única sem verificar:

1. se ele começa com `BEGIN` quando houver fixture ou DML transacional;
2. se termina com `ROLLBACK` quando houver fixture ou DML transacional;
3. se teste read-only não contém DDL, `CREATE FUNCTION`, `CREATE TABLE`, `DO` block ou DML;
4. se fixtures são transacionais;
5. se não usa colunas presumidas sem preflight;
6. se não concede privilégio para `anon`;
7. se não mexe em frontend/parser/Worker/Make/n8n;
8. se o resultado esperado está documentado;
9. se negativos não foram removidos para fazer teste passar.

---

## Estado operacional atual

```text
4A aprovada.
4B aprovada.
4C aprovada.
5A.1 aprovada.
5B aprovada.
5C fechada tecnicamente.
5D fechada tecnicamente, mergeada na main e com smoke estrutural pós-produção aprovado com SKIP_DATA.
Próxima fase canônica: Fase 6 — resumos administrativos e visão cliente-safe de operação financeira.
```
