# MesaCliente Engenharia Financeira — Índice operacional de testes

Este diretório contém os scripts de validação da Engenharia Financeira do MesaCliente.

## Contexto operacional

O projeto trabalha com banco Supabase de produção única. Por isso, a regra permanente é:

```text
Preflight read-only antes de migration.
Teste com BEGIN + ROLLBACK antes de considerar fase aprovada.
Nenhum frontend antes de RPC e segurança validadas.
Nenhuma premissa de schema sem consulta ao banco real.
```

Produção não é laboratório. Aqui teste que grava sem rollback é quase churrasco dentro do datacenter: até pode esquentar, mas ninguém vai aplaudir.

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
8. Este README como índice operacional da pasta de testes.

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

Valida:

- tabelas obrigatórias;
- funções obrigatórias;
- RLS;
- policies;
- grants para `anon` e `authenticated`;
- sinais de duplicidade de policies/índices;
- triggers/funções de integridade.

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

Objetivo:

- validar geração positiva da agenda em JSON;
- provar `cliente_safe=false`;
- provar `persistencia=false`;
- provar `dml_financeiro=false`;
- validar datas, periodicidade simbólica e totalização;
- provar zero DML em `mesa_cliente_fluxo_parcelas`;
- provar zero DML em `mesa_cliente_fluxo_operacoes`.

Status: aprovado.

#### `07b_validacao_agenda_financeira_json_first_negativos_rollback.sql`

Objetivo:

- validar bloqueio de `anon`;
- validar simulação inexistente;
- validar `empresa_id` fake no payload;
- validar item com `empresa_id` fake;
- validar valor negativo;
- validar grupo desconhecido;
- validar periodicidade fraudada;
- validar periodicidade simbólica marcada como negociável;
- provar zero DML financeiro.

Status: aprovado.

---

## Fase 4B — Persistência segura da agenda financeira

**Status:** aprovada em rollback transacional.

### Preflight 4B

#### `08_preflight_persistencia_agenda_readonly.sql`

Objetivo:

- validar schema real antes de criar persistência;
- mapear tabelas, colunas, constraints, indexes, grants e policies;
- identificar riscos antes da migration 4B.

Achado importante:

- `mesa_cliente_fluxo_operacoes` usa `status_operacao`, não coluna genérica `status`.

### Testes oficiais 4B

#### `08a_validacao_persistencia_agenda_financeira_rollback.sql`

Objetivo:

- criar fixture transacional;
- chamar RPC 4B;
- persistir cabeçalho em `mesa_cliente_agendas_financeiras`;
- persistir parcelas em `mesa_cliente_fluxo_parcelas`;
- validar total de parcelas e valor total;
- validar periodicidade bloqueada;
- validar datas resolvidas;
- provar que não cria operação financeira;
- encerrar com rollback.

Status: aprovado.

#### `08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql`

Objetivo:

- chamar a persistência duas vezes com a mesma entrada;
- provar que não duplica agenda;
- provar que não duplica parcelas;
- validar `idempotente=true` na segunda chamada;
- validar checksum consistente;
- encerrar com rollback.

Status: aprovado.

#### `08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql`

Objetivo:

- validar grants da RPC;
- bloquear simulação inexistente;
- bloquear `empresa_id` fake no payload;
- bloquear item com `empresa_id` fake;
- bloquear valor negativo;
- bloquear grupo desconhecido;
- bloquear periodicidade fraudada;
- bloquear periodicidade simbólica marcada como negociável;
- provar zero DML permanente;
- encerrar com rollback.

Status: aprovado.

#### `08d_validacao_persistencia_agenda_financeira_operacao_confirmada_rollback.sql`

Objetivo:

- criar agenda transacional;
- criar operação confirmada fixture dentro da transação;
- tentar substituir agenda;
- validar bloqueio com `SQLSTATE 55000`;
- provar que a agenda original permanece intacta;
- provar que parcelas originais não foram recriadas indevidamente;
- provar que não foi criada operação extra;
- encerrar com rollback.

Status: aprovado.

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

Objetivo:

- validar tabelas reais envolvidas na leitura cliente-safe;
- validar colunas de `mesa_cliente_agendas_financeiras`;
- validar colunas de `mesa_cliente_fluxo_parcelas`;
- validar colunas de `mesa_simulacoes`;
- validar grants e policies;
- validar existência das RPCs 4A/4B;
- mapear campos sensíveis que não podem sair no cliente-safe;
- validar se há base técnica para criar a RPC 4C.

Status: executado e fase concluída por documentação de fechamento.

### Testes 4C

Critérios aprovados:

- `cliente_safe=true`;
- `anon` bloqueado;
- `authenticated` executa;
- cross-tenant bloqueado;
- simulação inexistente bloqueada;
- agenda inexistente tratada;
- retorno sem VPL, prêmio, comissão, política, metadata bruta, checksum e payload bruto;
- sem DML.

---

## Fase 5A.1 — Simular impacto financeiro com agenda persistida

**Status:** migration/RPC criada; testes 10A/10B/10C criados; aguardando execução.

Documento canônico:

```text
docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md
```

Resultado do preflight/10P:

```text
docs/mesa-cliente/fase-5a-preflight-10-resultado-readonly.md
```

Migration criada:

```text
supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
```

RPC criada:

```text
public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)
```

### Preflight oficial/canônico 5A.1

#### `10_preflight_simulacao_impacto_agenda_persistida_readonly.sql`

Este é o único preflight 10 oficial da Fase 5A.1 neste diretório.

Resultado original:

```text
13_operational_interpretation = FAIL
```

Motivos principais:

```text
politicas_ativas_compostas_dias_365 = 0
agendas_ativas_com_parcelas = 0
total_fixture_candidates_5a = 0
```

Interpretação:

```text
Schema e funções mínimas estavam presentes, mas o ambiente não possuía base operacional permanente para liberar a migration/RPC 5A.1.
```

### Preparação transacional da base mínima 5A.1

#### `10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql`

Status: aprovado.

Resultado comprovado:

```text
politica_valida_5a = true
agenda_valida_5a = true
total_parcelas = 6
parcelas_podem_vpl = 5
parcelas_podem_antecipacao = 5
parcelas_podem_postergacao = 5
total_operacoes = 0
```

Decisão após 10P:

```text
Liberado criar migration/RPC 5A.1 e testes 10A/10B/10C.
```

### Testes oficiais 5A.1

#### `10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql`

Objetivo:

- criar fixture transacional;
- criar política ativa fixture;
- persistir agenda via RPC 4B;
- chamar RPC 5A.1;
- validar `cliente_safe=false`;
- validar `persistencia=false`;
- validar `dml_financeiro=false`;
- validar geração de alternativas e recomendação;
- validar uso de política `composto/dias_365`;
- provar zero operação financeira criada;
- encerrar com rollback.

Status: criado; aguardando execução.

#### `10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql`

Objetivo:

- validar `anon` sem execute;
- bloquear chamada sem auth;
- bloquear simulação inexistente;
- bloquear `empresa_id` no payload;
- bloquear valor negativo;
- bloquear modo inválido;
- bloquear agenda inexistente;
- encerrar com rollback.

Status: criado; aguardando execução.

#### `10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql`

Objetivo:

- capturar contagens/checksum/totais antes da 5A;
- chamar RPC 5A.1;
- validar `persistencia=false`;
- validar `dml_financeiro=false`;
- provar contagens de agendas inalteradas;
- provar contagens de parcelas inalteradas;
- provar contagens de operações inalteradas;
- provar checksum/totais da agenda inalterados;
- encerrar com rollback.

Status: criado; aguardando execução.

### Preflight exploratório arquivado

O arquivo abaixo não é mais oficial nesta pasta:

```text
10_preflight_impacto_financeiro_readonly.sql
```

Ele foi movido para:

```text
docs/mesa-cliente/rascunhos-sql/preflights-exploratorios/10_preflight_impacto_financeiro_readonly.sql
```

---

## Próxima execução obrigatória

1. Aplicar a migration:

```text
supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
```

2. Executar 10A:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

3. Executar 10B:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

4. Executar 10C:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

5. Enviar os três resultsets completos.

---

## Fases futuras

### Fase 5B — Registrar operação financeira

Pendente.

### Fase 5C — Confirmar/cancelar operação financeira

Pendente.

### Integração Front/BFF

Pendente. Proibida antes da leitura cliente-safe validada e antes da RPC administrativa 5A.1 passar nos testes.

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
5A.1 contrato final fechado.
10 preflight canônico executado.
10P aprovado.
Migration/RPC 5A.1 criada.
Testes 10A/10B/10C criados.
Próxima ação: aplicar migration e executar 10A/10B/10C.
Fase 5A.1 ainda não aprovada até os testes passarem.
```
