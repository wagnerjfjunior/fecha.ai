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
8. `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md`
9. `docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md`
10. `docs/mesa-cliente/fase-5b-validacao-preflight-11.md`
11. Este README como índice operacional da pasta de testes.

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

Valida:

- fixture transacional;
- persistência da agenda via RPC 4B;
- chamada positiva da RPC 5A.1;
- `cliente_safe=false`;
- `persistencia=false`;
- `dml_financeiro=false`;
- alternativas e recomendação;
- política `composto/dias_365`;
- zero operação financeira;
- rollback.

#### `10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql`

Status: aprovado.

Valida:

- `anon` sem execute;
- chamada sem auth bloqueada;
- simulação inexistente bloqueada;
- `empresa_id` no payload bloqueado;
- valor negativo bloqueado;
- modo inválido bloqueado;
- agenda inexistente bloqueada;
- rollback.

#### `10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql`

Status: aprovado.

Valida:

- flags `persistencia=false` e `dml_financeiro=false`;
- contagens de agendas inalteradas;
- contagens de parcelas inalteradas;
- contagens de operações inalteradas;
- checksum/totais da agenda inalterados;
- rollback.

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

**Status:** contrato fechado após preflight 11; liberada para migration e testes transacionais.

Documento canônico:

```text
docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md
```

Validação do preflight:

```text
docs/mesa-cliente/fase-5b-validacao-preflight-11.md
```

### Preflight oficial 5B

#### `11_preflight_registro_operacao_financeira_readonly.sql`

Status: aprovado com WARN estrutural esperado.

Valida:

- tabelas obrigatórias;
- schema real de `mesa_cliente_fluxo_operacoes`;
- colunas, constraints, índices, RLS, policies e grants;
- enums financeiros;
- presença das dependências 4B e 5A;
- ausência esperada da RPC 5B antes da migration.

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

### Próximos testes oficiais 5B

Arquivos esperados:

```text
11a_validacao_registro_operacao_financeira_rollback.sql
11b_validacao_registro_operacao_financeira_negativos_rollback.sql
11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql
11d_validacao_registro_operacao_financeira_confirmada_rollback.sql
11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql
```

Ainda pendentes até a migration 5B ser criada.

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
5B preflight aprovado com WARN estrutural; contrato fechado; próxima etapa: migration 5B e testes 11A-11E.
```